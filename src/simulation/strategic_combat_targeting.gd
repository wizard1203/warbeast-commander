extends RefCounted
## Read-only automatic acquisition shared by human and AI troops. Commands,
## damage settlement and movement remain owned by Combat. The spatial index is
## rebuilt once per tick; no new vision, resource, attack-rate or damage rules.
const Damage=preload("res://src/simulation/strategic_damage_rules.gd")
const VisibilityR9=preload("res://src/simulation/strategic_visibility_r9.gd")
const CELL:=160
const DISCOVERY:=230
var _grid:Dictionary={}
var _tower_grid:Dictionary={}
var _armies:Dictionary={}
var _reserved:Dictionary={}
var _shields:Dictionary={}
var _current:Dictionary={}
# Only scalar ownership/event receipts cross a tick. Bodies, positions and
# eligibility remain live in this prepare's authoritative projection.
var _leases:Dictionary={}
## A shared local focus identity belongs to a formation, not to whichever
## soldier happened to acquire first. Numeric summaries/rankings are owned by
## one prepare; only scalar order/target IDs may survive to the next tick.
const FOCUS_CANDIDATES_R9:=8
var _formation_facts_r9:Dictionary={}
var _focus_rankings_r9:Dictionary={}
var _formation_leases_r9:Dictionary={}
var _retaliation_rankings_r9:Dictionary={}
# Current-batch, same-effective-formation contacts only. A rear soldier may
# close on a front rank's locally observed fight without becoming another
# source of remote discovery. No assisted target or body reference survives
# prepare(), and the bounded second pass never scans the hostile army.
# Bound departure from the member's real, cached range-formation slot, not
# distance from a frozen nominal anchor. Front contact can legally occur past
# that anchor's420px circle in a deep layout; using it lost rear targets and
# pulled archers back to their slots on every change of the front target.
const GROUP_SLOT_RADIUS_R13:=420.0
const GROUP_CLOSE_RADIUS_R13:=900.0
var _group_contacts_r13:Dictionary={}
var group_contact_candidates_r13:=0
var group_contact_joins_r13:=0
var formation_reaction_prepares_r9:=0
var formation_reaction_candidates_r9:=0
var _tick:=-1
var candidate_visits:=0
var retained_targets:=0
var acquisition_searches:=0
var deferred_siege_checks:=0
const SIEGE_DISCOVERY_TICKS:=4

func prepare(units:Array[Dictionary],buildings:Array[Dictionary],tick:int,heroes:Dictionary={})->void:
	if tick<_tick:_leases.clear();_formation_leases_r9.clear()
	_grid.clear();_tower_grid.clear();_armies.clear();_reserved.clear();_shields.clear();_current.clear();_tick=tick;candidate_visits=0
	_formation_facts_r9.clear();_focus_rankings_r9.clear();_retaliation_rankings_r9.clear()
	_group_contacts_r13.clear();group_contact_candidates_r13=0;group_contact_joins_r13=0
	formation_reaction_prepares_r9=0;formation_reaction_candidates_r9=0
	retained_targets=0;acquisition_searches=0;deferred_siege_checks=0
	for body:Dictionary in units:
		if int(body.hp)<=0:
			# A recent lethal hit can alert surviving companions without making
			# the corpse a target, collision body or source of living combat power.
			_r9_record_recent_hit(body,tick)
			continue
		_current[str(body.id)]=body
		_insert(body,_grid)
		var shield_capacity:=0.0
		for shield:Dictionary in body.get("innate_shield",{}).values():
			if int(shield.get("expires_tick",-1))>tick:shield_capacity=maxf(shield_capacity,float(shield.get("amount",shield.get("cap",0))))
		for effect:Dictionary in heroes.get(str(body.id),{}).get("item_effects",{}).values():
			if int(effect.get("expires_tick",-1))>tick:shield_capacity=maxf(shield_capacity,float(effect.get("shield_remaining",0)))
		if shield_capacity>0:_shields[str(body.id)]=shield_capacity
		var army:=str(body.get("warband_id",""))
		if not _armies.has(army):_armies[army]=[]
		_armies[army].append(body)
		army=str(body.get("command_army_id_r12",army))
		var formation:Dictionary=_formation_facts_r9.get(army,{})
		if formation.is_empty():formation={"position":Vector2.ZERO,"count":0,"max_range":0,"attackers":{}}
		formation.position=Vector2(formation.position)+Vector2(body.position);formation.count=int(formation.count)+1
		formation.max_range=maxi(int(formation.max_range),int(body.get("attack_range",0)))
		_formation_facts_r9[army]=formation
		_r9_record_recent_hit(body,tick)
	for body:Dictionary in buildings:
		if int(body.get("hp",0))<=0:continue
		_current[str(body.id)]=body
		_insert(body,_grid)
		if not _worker(body) and bool(body.get("complete",false)) and bool(body.get("defense_active",false)) and int(body.get("damage",0))>0:_insert(body,_tower_grid)
	for id:Variant in _leases.keys():
		if not _current.has(id):_leases.erase(id)
	for id:Variant in _formation_leases_r9.keys():
		var lease:Dictionary=_formation_leases_r9[id]
		var target:Dictionary=_current.get(str(lease.get("target","")),{})
		if not _formation_facts_r9.has(id) or target.is_empty() or not VisibilityR9.can_observe(target,str(lease.get("side",""))):_formation_leases_r9.erase(id)

func _r9_record_recent_hit(body:Dictionary,tick:int)->void:
	var at:=int(body.get("last_damage_tick",-1000000))
	if at<0 or at>tick or tick-at>60 or int(body.get("last_damage_amount",0))<=0:return
	var army:=str(body.get("command_army_id_r12",body.get("warband_id","")));var source:=str(body.get("last_damage_source_id",""))
	if army.is_empty() or source.is_empty():return
	var formation:Dictionary=_formation_facts_r9.get(army,{})
	if formation.is_empty():formation={"position":Vector2.ZERO,"count":0,"max_range":0,"attackers":{}}
	formation.attackers[source]=true
	_formation_facts_r9[army]=formation

func _r9_retaliation_ranking(unit:Dictionary,army:Dictionary)->Array:
	var id:=str(army.get("id",unit.get("warband_id","")))
	var key:=str(unit.side)+":"+id
	if _retaliation_rankings_r9.has(key):return _retaliation_rankings_r9[key]
	formation_reaction_prepares_r9+=1
	var formation:Dictionary=_formation_facts_r9.get(id,{})
	var center:=Vector2(army.get("anchor",unit.position))
	if int(formation.get("count",0))>0:center=Vector2(formation.position)/float(formation.count)
	var ids:Array=formation.get("attackers",{}).keys();ids.sort()
	if ids.size()>FOCUS_CANDIDATES_R9:ids.resize(FOCUS_CANDIDATES_R9)
	var rows:Array[Dictionary]=[]
	# Already verified recent actual hit IDs only. No whole-world hostile scan,
	# projected future fight, new command or extra target discovery is performed.
	for source:String in ids:
		formation_reaction_candidates_r9+=1
		var enemy:Dictionary=_current.get(source,{})
		if enemy.is_empty() or int(enemy.get("hp",0))<=0 or enemy.get("side")==unit.side or not VisibilityR9.can_observe(enemy,str(unit.side)):continue
		var distance:=center.distance_to(Vector2(enemy.position))
		if distance>420.0:continue
		if enemy.has("building_type") and not _worker(enemy) and (bool(enemy.get("fixed",false)) or not bool(enemy.get("attackable",true)) or not bool(enemy.get("complete",false)) or not bool(enemy.get("defense_active",false))):continue
		var wounded:=clampf(1.0-float(enemy.hp)/maxf(1,float(enemy.get("max_hp",enemy.hp))),0.0,1.0)
		rows.append({"id":source,"score":wounded*220.0-distance*.22})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a.id)<str(b.id) if is_equal_approx(float(a.score),float(b.score)) else float(a.score)>float(b.score))
	var ranked:Array=[]
	for row:Dictionary in rows:ranked.append(str(row.id))
	_retaliation_rankings_r9[key]=ranked
	return ranked

func _r9_retaliation_target(unit:Dictionary,army:Dictionary)->Dictionary:
	if army.get("intent")!="ATTACK_MOVE" or not str(unit.get("direct_intent","")).is_empty():return {}
	for id:String in _r9_retaliation_ranking(unit,army):
		var enemy:Dictionary=_current.get(id,{})
		if recovery_excludes_r11(unit,id):continue
		if enemy.is_empty() or int(enemy.get("hp",0))<=0 or not VisibilityR9.can_observe(enemy,str(unit.side)) or not _can_attack(unit,enemy):continue
		if int(enemy.hp)+ceili(float(_shields.get(id,0)))-int(_reserved.get(str(unit.side)+":"+id,0))<=0:continue
		# A bounded same-formation call for help can close a short gap beyond
		# an individual's230px discovery ring; it never becomes cross-map focus.
		if _distance(unit,enemy)>maxf(420.0,float(_range(unit,enemy))):continue
		if _worker(enemy) and _protected_worker(enemy,unit):continue
		return enemy
	return {}

func _r9_focus_ranking(unit:Dictionary,army:Dictionary)->Array:
	var id:=str(army.get("id",unit.get("warband_id","")))
	var key:=str(unit.side)+":"+id+":"+str(army.get("target_warband_id",""))
	if _focus_rankings_r9.has(key):return _focus_rankings_r9[key]
	var formation:Dictionary=_formation_facts_r9.get(id,{})
	var center:=Vector2(army.get("anchor",unit.position))
	if int(formation.get("count",0))>0:center=Vector2(formation.position)/float(formation.count)
	var old:Dictionary=_formation_leases_r9.get(id,{})
	var old_same:bool=old.get("side")==unit.side and old.get("focus")==army.get("target_warband_id")
	if not old_same:_formation_leases_r9.erase(id)
	var rows:Array[Dictionary]=[]
	# One scan of the observed enemy formation per own formation/prepare, not
	# a fresh whole-army scan for every archer. Outskirts still have a spatial
	# local fallback below; a focus lease cannot authorise cross-map point chase.
	for enemy:Dictionary in _armies.get(str(army.get("target_warband_id","")),[]):
		if enemy.side==unit.side or int(enemy.get("hp",0))<=0 or not VisibilityR9.can_observe(enemy,str(unit.side)):continue
		var distance:=center.distance_to(Vector2(enemy.position))
		if distance>420.0:continue
		var wounded:=clampf(1.0-float(enemy.hp)/maxf(1,float(enemy.get("max_hp",enemy.hp))),0.0,1.0)
		var score:=wounded*220.0-distance*.22
		if formation.get("attackers",{}).has(str(enemy.id)):score+=70.0
		if enemy.get("unit_type","")=="hero" and wounded>=.30:score+=30.0
		if old_same and old.get("target")==str(enemy.id):score+=8.0
		rows.append({"id":str(enemy.id),"score":score})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a.id)<str(b.id) if is_equal_approx(float(a.score),float(b.score)) else float(a.score)>float(b.score))
	if rows.size()>FOCUS_CANDIDATES_R9:rows.resize(FOCUS_CANDIDATES_R9)
	var ranked:Array=[]
	for row:Dictionary in rows:ranked.append(str(row.id))
	_focus_rankings_r9[key]=ranked
	return ranked

func _r9_focus_target(unit:Dictionary,army:Dictionary)->Dictionary:
	if not str(unit.get("direct_intent","")).is_empty() or army.get("intent")!="FOCUS":return {}
	for id:String in _r9_focus_ranking(unit,army):
		var enemy:Dictionary=_current.get(id,{})
		if recovery_excludes_r11(unit,id):continue
		if enemy.is_empty() or int(enemy.get("hp",0))<=0 or not VisibilityR9.can_observe(enemy,str(unit.side)) or not _can_attack(unit,enemy):continue
		var committed:=int(_reserved.get(str(unit.side)+":"+id,0))
		if int(enemy.hp)+ceili(float(_shields.get(id,0)))-committed<=0:continue
		var distance:=_distance(unit,enemy)
		# Share an attackable current shot or a small legal closing step, not a
		# demand that a melee soldier ignore a nearby fight to cross the map.
		var reach:=float(_range(unit,enemy))
		if distance>maxf(reach,minf(float(DISCOVERY),reach+80.0)):continue
		var group_id:=str(army.get("id",unit.get("warband_id","")))
		var existing:Dictionary=_formation_leases_r9.get(group_id,{})
		if existing.get("side")!=unit.side or existing.get("focus")!=str(army.get("target_warband_id","")) or existing.get("target")!=id:
			_formation_leases_r9[group_id]={"side":unit.side,"focus":str(army.get("target_warband_id","")),"target":id}
		return enemy
	return {}

func _r9_focus_candidates(unit:Dictionary,army:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[];var seen:Dictionary={}
	for id:String in _r9_focus_ranking(unit,army):
		var enemy:Dictionary=_current.get(id,{})
		if not enemy.is_empty():result.append(enemy);seen[id]=true
	# Dense/heterogeneous groups need local legal alternatives after overkill
	# reservations or an incompatible preferred attack layer. Query spatial
	# neighbours; do not rescan every member of the focused enemy formation.
	for enemy:Dictionary in _near(unit.position,maxi(DISCOVERY,int(unit.get("attack_range",0))+64),_grid):
		if enemy.get("warband_id")!=army.get("target_warband_id") or seen.has(str(enemy.id)):continue
		result.append(enemy);seen[str(enemy.id)]=true
	return result

func record_group_contact_r13(unit:Dictionary,army:Dictionary,target:Dictionary,formation_slot:Vector2i)->void:
	# Combat admits only living, automated offensive followers. Even a valid
	# explicit siege/FOCUS target cannot seed this pool from across the map.
	if target.is_empty() or int(target.get("hp",0))<=0 or target.side==unit.side or not VisibilityR9.can_observe(target,str(unit.side)) or not _can_attack(unit,target):return
	if Vector2(unit.position).distance_to(Vector2(formation_slot))>GROUP_SLOT_RADIUS_R13:return
	if _distance(unit,target)>maxf(float(DISCOVERY),float(_range(unit,target))):return
	if target.has("building_type") and not _worker(target) and (bool(target.get("fixed",false)) or not bool(target.get("attackable",true)) or not _threat(target,unit)):return
	var key:=str(unit.side)+":"+str(army.id)
	var contacts:Dictionary=_group_contacts_r13.get(key,{})
	var id:=str(target.id)
	if contacts.has(id) or contacts.size()>=FOCUS_CANDIDATES_R9:return
	contacts[id]=true
	_group_contacts_r13[key]=contacts

func join_group_contact_r13(unit:Dictionary,army:Dictionary,formation_slot:Vector2i)->Dictionary:
	var contacts:Dictionary=_group_contacts_r13.get(str(unit.side)+":"+str(army.id),{})
	if contacts.is_empty() or Vector2(unit.position).distance_to(Vector2(formation_slot))>GROUP_SLOT_RADIUS_R13:return {}
	var chosen:Dictionary={};var best:=-INF
	for id:String in contacts:
		group_contact_candidates_r13+=1
		var enemy:Dictionary=_current.get(id,{})
		if enemy.is_empty() or int(enemy.get("hp",0))<=0 or enemy.side==unit.side or not VisibilityR9.can_observe(enemy,str(unit.side)) or not _can_attack(unit,enemy) or recovery_excludes_r11(unit,id):continue
		# Recheck each recipient's sight, attack layer, recovery and current HP
		# reservations. Independent contacts, not joined recipients, renew the
		# pool next tick. HOLD/MOVE/retreat never enter this API from Combat.
		if _distance(unit,enemy)>GROUP_CLOSE_RADIUS_R13:continue
		if enemy.has("building_type") and not _worker(enemy) and (bool(enemy.get("fixed",false)) or not bool(enemy.get("attackable",true)) or not bool(enemy.get("defense_active",false))):continue
		if _worker(enemy) and _protected_worker(enemy,unit):continue
		var hp:=int(enemy.hp)+ceili(float(_shields.get(id,0)))-int(_reserved.get(str(unit.side)+":"+id,0))
		if hp<=0:continue
		var distance:=_distance(unit,enemy)
		var score:=-distance*.35+45.0*(1.0-float(enemy.hp)/maxf(1,float(enemy.get("max_hp",enemy.hp))))
		if distance<=_range(unit,enemy):score+=1000.0
		if str(unit.get("target_id",""))==id:score+=8.0
		if score>best or is_equal_approx(score,best) and id<str(chosen.get("id","~")):chosen=enemy;best=score
	if not chosen.is_empty():group_contact_joins_r13+=1
	return chosen

func _insert(body:Dictionary,index:Dictionary)->void:
	var cell:=Vector2i(floori(float(body.position.x)/CELL),floori(float(body.position.y)/CELL))
	if not index.has(cell):index[cell]=[]
	index[cell].append(body)

func _near(position:Vector2i,radius:int,index:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for y:int in range(floori(float(position.y-radius)/CELL),floori(float(position.y+radius)/CELL)+1):
		for x:int in range(floori(float(position.x-radius)/CELL),floori(float(position.x+radius)/CELL)+1):
			result.append_array(index.get(Vector2i(x,y),[]))
	return result

static func _can_attack(source:Dictionary,target:Dictionary)->bool:
	return target.get("movement_layer","GROUND") in source.get("attack_layers",["GROUND"])

static func _range(source:Dictionary,target:Dictionary)->int:
	return int(source.get("attack_range",0))+int(target.get("radius",12))

static func _distance(a:Dictionary,b:Dictionary)->float:
	return Vector2(a.position).distance_to(Vector2(b.position))

static func _worker(body:Dictionary)->bool:
	return body.get("building_type","")=="WORKER_OBSTACLE"

func _threat(source:Dictionary,victim:Dictionary)->bool:
	if not _can_attack(source,victim) or int(source.get("damage",0))<=0:return false
	if source.has("building_type") and not _worker(source) and not bool(source.get("defense_active",false)):return false
	var recent:=_tick-int(victim.get("last_damage_tick",-1000000))<=60 and str(victim.get("last_damage_source_id",""))==str(source.id)
	return recent or _distance(source,victim)<=_range(source,victim)

func _protected_worker(worker:Dictionary,attacker:Dictionary)->bool:
	for tower:Dictionary in _near(worker.position,400,_tower_grid):
		if tower.side!=worker.side:continue
		if _can_attack(tower,attacker) and (_distance(tower,worker)<=_range(tower,worker) or _distance(tower,attacker)<=_range(tower,attacker)):return true
	return false

static func attack_quote(unit:Dictionary,target:Dictionary)->int:
	# Read-only baseline estimate, not a second damage settlement. It excludes
	# procs/crit/execute and never consumes shields or triggers damage feedback.
	var raw:=float(unit.get("damage",0))
	if str(unit.get("bonus_vs_tag","")) in target.get("tags",[]):raw+=int(unit.get("bonus_damage",0))
	return Damage.resolve(raw,str(unit.get("attack_type","EDGE")),target)

func reserve(unit:Dictionary,target:Dictionary)->void:
	if target.is_empty() or int(unit.get("cooldown_ticks",0))>0 or _distance(unit,target)>_range(unit,target):return
	# Pre-movement quotes cannot promise a shot at the edge of reach, or claim
	# a shielded enemy dead. Skip uncertain reservations rather than suppress a
	# legal later shot. Settlement remains authoritative after movement.
	if _shields.has(str(target.id)) or unit.get("direct_intent","")=="MOVE":return
	var source_stride:=0.0 if unit.get("direct_intent","") in ["HOLD","AUTO_HOLD"] else float(unit.get("speed_exact",unit.get("speed",0)))
	var target_stride:=0.0 if target.get("direct_intent","") in ["HOLD","AUTO_HOLD"] else float(target.get("speed_exact",target.get("speed",0)))
	if _distance(unit,target)+(ceilf(source_stride)+ceilf(target_stride))*sqrt(2.0)>_range(unit,target):return
	var key:=str(unit.side)+":"+str(target.id)
	_reserved[key]=int(_reserved.get(key,0))+attack_quote(unit,target)

func _same_order(receipt:Dictionary,unit:Dictionary,army:Dictionary,siege:bool)->bool:
	return receipt.get("side") == unit.side and receipt.get("army") == str(army.id) and receipt.get("direct") == str(unit.get("direct_intent","")) and receipt.get("intent") == str(army.intent) and receipt.get("focus") == str(army.get("target_warband_id","")) and receipt.get("base") == str(army.get("target_base_id","")) and receipt.get("siege") == siege

func _new_damage(receipt:Dictionary,unit:Dictionary)->bool:
	var at:=int(unit.get("last_damage_tick",-1000000))
	return at>=0 and at<=_tick and _tick-at<=60 and int(unit.get("last_damage_amount",0))>0 and (at!=int(receipt.get("damage_tick",-1000000)) or str(unit.get("last_damage_source_id",""))!=str(receipt.get("damage_source","")))

func _remember(unit:Dictionary,army:Dictionary,siege:bool,target:Dictionary)->void:
	# Ordinary idle discovery is intentionally not delayed. It needs neither
	# an empty receipt allocation nor a useless order comparison next tick.
	if target.is_empty() and not siege:
		_leases.erase(str(unit.id))
		return
	_leases[str(unit.id)]={"target":str(target.get("id","")),"side":unit.side,"army":str(army.id),"direct":str(unit.get("direct_intent","")),"intent":str(army.intent),"focus":str(army.get("target_warband_id","")),"base":str(army.get("target_base_id","")),"siege":siege,"damage_tick":int(unit.get("last_damage_tick",-1000000)),"damage_source":str(unit.get("last_damage_source_id","")),"position":unit.position,"until":_tick+SIEGE_DISCOVERY_TICKS}

func _valid_held(unit:Dictionary,army:Dictionary,enemy:Dictionary,siege:bool)->bool:
	if enemy.is_empty() or int(enemy.get("hp",0))<=0 or enemy.side==unit.side or not VisibilityR9.can_observe(enemy,str(unit.side)) or not _can_attack(unit,enemy):return false
	if recovery_excludes_r11(unit,str(enemy.id)):return false
	var direct:=str(unit.get("direct_intent",""))
	var focus:bool=direct.is_empty() and army.intent=="FOCUS"
	var chase:bool=direct=="ATTACK" or direct.is_empty() and army.intent in ["ATTACK_MOVE","FOCUS"]
	if focus and str(enemy.get("warband_id",""))!=str(army.get("target_warband_id","")):return false
	var worker:=_worker(enemy)
	var threat:=_threat(enemy,unit)
	if enemy.has("building_type") and not worker and (bool(enemy.get("fixed",false)) or not bool(enemy.get("attackable",true)) or not threat):return false
	if siege and (worker or not threat):return false
	var distance:=_distance(unit,enemy)
	var reach:=_range(unit,enemy)
	# Discovery cannot invalidate a shot that is already inside the unchanged
	# actual weapon reach. Longer bows/guns must not wait to enter230px first.
	var allowed:=4000 if focus else maxi(DISCOVERY,reach) if chase else reach
	# A currently observed held enemy must survive a bounded legal detour
	# around friendly bodies. Otherwise crossing the ordinary discovery ring
	# drops the target and pulls the unit back into its paused formation.
	# This is retention only, never a new search or a vision exception.
	var recovery: Dictionary=unit.get("recovery_r11",{})
	if chase and not focus and not recovery.get("route",[]).is_empty() and recovery.get("target_id")==str(enemy.id) and int(recovery.get("expires_tick",-1))>_tick and recovery.get("army")==str(army.id) and recovery.get("intent")==army.intent and recovery.get("destination")==army.destination:
		allowed=maxi(allowed,420)
	if siege:allowed=maxi(reach,DISCOVERY)
	if distance>allowed:return false
	if chase and not focus and distance>reach and Vector2(enemy.position).distance_to(Vector2(army.anchor))>420:return false
	if worker and _protected_worker(enemy,unit):return false
	return int(enemy.hp)+ceili(float(_shields.get(str(enemy.id),0)))-int(_reserved.get(str(unit.side)+":"+str(enemy.id),0))>0

func choose(unit:Dictionary,army:Dictionary,siege_response:bool=false)->Dictionary:
	var receipt:Dictionary=_leases.get(str(unit.id),{})
	var deferred_response:Dictionary={}
	var chase_fallback:Dictionary={}
	if not siege_response:
		var shared:=_r9_retaliation_target(unit,army) if army.get("intent")=="ATTACK_MOVE" else _r9_focus_target(unit,army)
		if not shared.is_empty():
			# A formation's call for help must not make a soldier ignore an
			# enemy already inside its own weapon reach to push through allies
			# toward a remote attacker. Keep the shared fallback if no legal
			# current shot exists. Explicit FOCUS keeps its prior priority.
			if army.get("intent")=="ATTACK_MOVE" and _distance(unit,shared)>_range(unit,shared):
				deferred_response=shared
			else:
				if receipt.get("target")==str(shared.id) and _same_order(receipt,unit,army,false):
					retained_targets+=1
					if not _new_damage(receipt,unit):return shared
				else:acquisition_searches+=1
				_remember(unit,army,false,shared)
				return shared
	if not receipt.is_empty() and _same_order(receipt,unit,army,siege_response):
		var held_id:=str(unit.get("target_id",""))
		var new_damage:=_new_damage(receipt,unit)
		if not held_id.is_empty() and held_id==str(receipt.target):
			var held:Dictionary=_current.get(held_id,{})
			# A newly damaging different attacker merits one fresh priority
			# evaluation. Re-reading the same hit is not another damage event.
			if (not new_damage or str(unit.get("last_damage_source_id",""))==held_id) and _valid_held(unit,army,held,siege_response) and (deferred_response.is_empty() or _distance(unit,held)<=_range(unit,held)):
				# Retain a pursuit, but not at the cost of an available local hit.
				# Only ordinary attack-move checks its weapon neighbourhood; a
				# named attack/focus and an already firing lease stay unchanged.
				if not siege_response and str(unit.get("direct_intent","")).is_empty() and army.intent=="ATTACK_MOVE" and _distance(unit,held)>_range(unit,held):
					chase_fallback=held
				else:
					retained_targets+=1
					if new_damage:_remember(unit,army,siege_response,held)
					return held
		elif siege_response and str(receipt.target).is_empty() and held_id==str(army.get("target_base_id","")) and not new_damage and receipt.position==unit.position and _tick<int(receipt.until):
			var base:Dictionary=_current.get(held_id,{})
			if not base.is_empty() and base.side!=unit.side and _can_attack(unit,base) and not bool(base.get("fixed",false)) and bool(base.get("attackable",true)) and not _threat(base,unit):
				# A clear response search lasts at most 200 ms, only while the
				# same unit is stationary at the same siege. Damage wakes now;
				# newly entering weapon coverage is discovered by the next due
				# check. The macro planner and explicit commands are untouched.
				deferred_siege_checks+=1
				return {}
	acquisition_searches+=1
	var direct:=str(unit.get("direct_intent",""))
	var focus:bool=direct.is_empty() and army.intent=="FOCUS"
	var chase:bool=direct=="ATTACK" or direct.is_empty() and army.intent in ["ATTACK_MOVE","FOCUS"]
	var candidates:Array[Dictionary]=[]
	if focus:candidates=_r9_focus_candidates(unit,army)
	else:candidates=_near(unit.position,int(unit.get("attack_range",0))+64 if not chase_fallback.is_empty() else maxi(DISCOVERY,int(unit.get("attack_range",0))+64),_grid)
	var chosen:Dictionary={}
	var best:=-INF
	for enemy:Dictionary in candidates:
		candidate_visits+=1
		if recovery_excludes_r11(unit,str(enemy.id)):continue
		if int(enemy.get("hp",0))<=0 or enemy.side==unit.side or not VisibilityR9.can_observe(enemy,str(unit.side)) or not _can_attack(unit,enemy):continue
		var worker:=_worker(enemy)
		var structure:=enemy.has("building_type") and not worker
		var threat:=_threat(enemy,unit)
		if structure and (bool(enemy.get("fixed",false)) or not bool(enemy.get("attackable",true)) or not threat):continue
		if siege_response and (worker or not threat):continue
		var distance:=_distance(unit,enemy)
		var reach:=_range(unit,enemy)
		var in_reach:=distance<=reach
		if not chase_fallback.is_empty() and not in_reach:continue
		var allowed:=4000 if focus else maxi(DISCOVERY,reach) if chase else reach
		if siege_response:allowed=maxi(reach,DISCOVERY)
		if distance>allowed:continue
		if chase and not focus and not in_reach and Vector2(enemy.position).distance_to(Vector2(army.anchor))>420:continue
		if worker and _protected_worker(enemy,unit):continue
		var committed:=int(_reserved.get(str(unit.side)+":"+str(enemy.id),0))
		var hp:=int(enemy.hp)+ceili(float(_shields.get(str(enemy.id),0)))-committed
		# Already sufficient ready, in-range fire is assigned. Automatic troops
		# try another target; explicit named attacks never enter this chooser.
		if hp<=0:continue
		var quote:=maxi(1,attack_quote(unit,enemy))
		var wounded:=1.0-float(enemy.hp)/maxf(1,float(enemy.get("max_hp",enemy.hp)))
		var score:=(1000.0 if in_reach else 0.0)-distance*0.35+45.0*wounded
		if hp<=quote:score+=140.0
		elif hp<=quote*2:score+=65.0
		if threat:score+=70.0
		if enemy.get("unit_type","")=="hero" and (threat or wounded>=0.6):score+=28.0
		if worker:score+=32.0
		if str(unit.get("target_id",""))==str(enemy.id):score+=8.0
		if score>best or is_equal_approx(score,best) and str(enemy.id)<str(chosen.get("id","~")):
			chosen=enemy;best=score
	if not deferred_response.is_empty() and (chosen.is_empty() or _distance(unit,chosen)>_range(unit,chosen)):
		chosen=deferred_response
	elif chosen.is_empty() and not chase_fallback.is_empty():
		chosen=chase_fallback
	_remember(unit,army,siege_response,chosen)
	return chosen

func recovery_excludes_r11(unit:Dictionary,target_id:String)->bool:
	# Bounded scalar per-body cooldowns, set only after actual failed progress.
	# This gates held/shared/fresh automatic selection equally; an explicit named
	# attack bypasses choose() and therefore remains the player's choice.
	return int(unit.get("recovery_avoid_r11",{}).get(target_id,-1))>_tick

func recovery_neighbours_r11(unit:Dictionary)->Array[Dictionary]:
	# Reuse this tick's existing spatial index only on a due recovery attempt.
	# Never scan or clone the entire army for every blocked soldier every tick.
	return _near(unit.position,480,_grid)

func forget_recovery_target_r11(unit_id:String)->void:
	_leases.erase(unit_id)
