extends RefCounted
## Computer-only, bounded officer preservation. It reads detached real facts;
## every move/potion/rejoin still needs the host's ordinary command receipt.
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const World = preload("res://src/simulation/strategic_world.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const EXIT_HEALTH_PERCENT := 32
const REJOIN_HEALTH_PERCENT := 65
const CLEAR_TICKS := 60
const MOVE_REFRESH_TICKS := 80
const LEASE_TICKS := 100
var states: Dictionary = {}
var diagnostics: Dictionary = {}
var _pending: Dictionary = {}
var _pending_selected := false

func reset() -> void:
	states.clear()
	diagnostics.clear()
	_pending.clear()
	_pending_selected=false

func plan(tick: int, world: Dictionary, military: Dictionary) -> Dictionary:
	_pending.clear()
	_pending_selected=false
	var bodies := {}
	for body: Dictionary in military.get("soldiers",[]):bodies[str(body.id)]=body
	var heroes: Array[Dictionary]=[]
	for hero: Dictionary in military.get("heroes",{}).get("officers",[]):
		if hero.get("side")!="AI" or hero.get("state")!="ACTIVE" or int(hero.get("hp",0))<=0:continue
		if not bodies.has(str(hero.id)):continue
		heroes.append(hero)
	for id: String in states.keys():
		if not bodies.has(id) or int(bodies[id].get("hp",0))<=0 or not bool(bodies[id].get("alive",false)):states.erase(id)
	heroes.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var left:=int(a.hp)*int(b.max_hp)
		var right:=int(b.hp)*int(a.max_hp)
		return str(a.id)<str(b.id) if left==right else left<right)
	var hostiles:=_hostiles(world,military)
	for hero: Dictionary in heroes:
		var id:=str(hero.id)
		var body: Dictionary=bodies[id]
		var risk:=_risk(body.position,body,hostiles)
		var recently_hit:=int(body.get("last_damage_tick",-1000000))>=0 and tick-int(body.last_damage_tick)<=60
		var health_percent:=int(hero.hp)*100/maxi(1,int(hero.max_hp))
		var state: Dictionary=states.get(id,{})
		# Transfers/merges are ordinary admitted army ownership changes. Keep an
		# already fleeing officer safe, but never return it to a stale old group.
		if not state.is_empty() and state.get("warband_id")!=body.get("warband_id"):
			state.warband_id=body.warband_id
		if state.is_empty():
			# Critical health without actual local danger is not permission to
			# drag a healthy hero away from its army's ordinary work.
			var critical:=health_percent<=EXIT_HEALTH_PERCENT
			var projected_lethal:=health_percent<=50 and float(hero.hp)<=float(risk)*1.8
			if not (critical or projected_lethal) or (risk<=0 and not recently_hit):continue
			var escape:=_escape_point(body,world,military,hostiles)
			if escape.is_empty():
				diagnostics[id]={"phase":"NO_SAFE_ROUTE","tick":tick,"health_percent":health_percent,"incoming_raw_dps":risk}
				continue
			state={"phase":"WITHDRAW","point":escape.position,"started_tick":tick,"last_move_tick":-1000000,"clear_since":-1,"warband_id":body.warband_id,"route_length":escape.length,"reason":"CRITICAL_HEALTH" if critical else "LETHAL_WEAPON_PRESSURE","observed_direct_destination":body.get("direct_destination",body.position),"admitted_destination":Vector2i(-1000000,-1000000),"valid_saved_move":false}
			states[id]=state
		state.observed_direct_destination=body.get("direct_destination",body.position)
		state.valid_saved_move=body.get("direct_intent","")=="MOVE" and state.observed_direct_destination==state.admitted_destination
		if risk>0 or recently_hit:state.clear_since=-1
		elif int(state.clear_since)<0:state.clear_since=tick
		var clear:=int(state.clear_since)>=0 and tick-int(state.clear_since)>=CLEAR_TICKS
		var arrived:=Vector2(body.position).distance_to(Vector2(state.point))<=48.0
		if arrived:state.phase="RECOVER"
		# Recovery is actual HP, never a timer-based grant. The high threshold
		# and three quiet seconds stop wounded officers oscillating in and out.
		if health_percent>=REJOIN_HEALTH_PERCENT and clear:
			state.phase="REJOIN"
			# Transfer-to-current-army is an existing legal, single-body rejoin:
			# it clears only this hero's direct order and restores real formation
			# following/autoattack. Chasing a moving ally or issuing ATTACK ""
			# would leave a healthy hero stuck in another permanent direct order.
			return _offer(id,{"type":"TRANSFER_UNITS","unit_ids":[id],"target_warband_id":body.warband_id},tick)
		if state.phase=="REJOIN":state.phase="WITHDRAW"
		# Spend owned healing only when it is useful. This is the same paid,
		# shared-cooldown item authority as the human command, not free HP.
		if risk<=0 and int(hero.get("item_cooldown_ticks",0))<=0 and int(hero.max_hp)-int(hero.hp)>=120 and int(hero.get("inventory",{}).get("POTION",0))>0:
			return _offer(id,{"type":"USE_POTION","unit_id":id},tick)
		if arrived and clear:
			var purchase:=_recovery_purchase(hero,world)
			if not purchase.is_empty():return _offer(id,purchase,tick)
			# A shop is not a passive fountain. If no real healing is available,
			# approach a reachable actual shop and pay its ordinary potion price.
			if int(hero.get("inventory",{}).get("POTION",0))<=0 and not _has_local_healing(hero,military) and not _affordable_potion(hero,world).is_empty():
				var shop:=_escape_point(body,world,military,hostiles,true)
				if not shop.is_empty() and Vector2(body.position).distance_to(Vector2(shop.position))>48.0:
					state.point=shop.position
					state.phase="WITHDRAW"
					return _offer(id,{"type":"UNIT_MOVE","unit_id":id,"target_position":state.point},tick)
			# Stationary recovery is intentionally quiet. Its already accepted
			# real safe MOVE may keep a finite host lease without wasting another
			# command; no money/medical source means waiting, never free healing.
			diagnostics[id]={"phase":"RECOVER_NEEDS_HEAL","tick":tick,"health_percent":health_percent,"safe_point":state.point,"has_real_healing":_has_local_healing(hero,military),"potion_affordable":not _affordable_potion(hero,world).is_empty(),"owned_potions":int(hero.get("inventory",{}).get("POTION",0))}
			continue
		if not arrived and (tick-int(state.last_move_tick)>=MOVE_REFRESH_TICKS or body.get("direct_intent","")!="MOVE"):
			# A changing battlefield may invalidate the old refuge. Never renew
			# a known lethal destination just because it used to be home.
			if _risk(state.point,body,hostiles)>0:
				var revised:=_escape_point(body,world,military,hostiles)
				if not revised.is_empty():state.point=revised.position
				else:
					diagnostics[id]={"phase":"NO_SAFE_ROUTE","tick":tick,"health_percent":health_percent,"incoming_raw_dps":risk}
					continue
			return _offer(id,{"type":"UNIT_MOVE","unit_id":id,"target_position":state.point},tick)
		diagnostics[id]={"phase":state.phase,"tick":tick,"health_percent":health_percent,"incoming_raw_dps":risk,"safe_point":state.point,"clear_since":state.clear_since}
	return {}

func _offer(id: String, command: Dictionary, tick: int) -> Dictionary:
	_pending={"id":id,"command":command.duplicate(true),"tick":tick}
	diagnostics[id]={"phase":states[id].phase,"tick":tick,"safe_point":states[id].point,"order":command.duplicate(true)}
	return command

func record_result(tick: int, command: Dictionary, result: Dictionary) -> void:
	if _pending.get("command",{})!=command:return
	var id:=str(_pending.id)
	if bool(result.get("accepted",false)) and states.has(id):
		if command.type=="UNIT_MOVE":
			states[id].last_move_tick=tick
			states[id].admitted_destination=command.target_position
			states[id].valid_saved_move=true
		elif command.type=="TRANSFER_UNITS":states.erase(id)
	_pending.clear()
	_pending_selected=false

func selected_commands(commands: Array[Dictionary]) -> void:
	_pending_selected=not _pending.is_empty() and _pending.get("command",{}) in commands

func withdrawal_leases(tick: int) -> Dictionary:
	var leases: Dictionary={}
	for id: String in states:
		if states[id].phase not in ["WITHDRAW","RECOVER"]:continue
		var until:=tick+LEASE_TICKS if bool(states[id].get("valid_saved_move",false)) else -1
		if until>tick:leases[id]=until
	return leases

func get_state() -> Dictionary:
	return {"states":states.duplicate(true),"diagnostics":diagnostics.duplicate(true),"pending_selected":_pending_selected}

static func _hostiles(world: Dictionary,military: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for body: Dictionary in military.get("soldiers",[])+military.get("micro_neutral_targets",[])+world.get("buildings",[])+world.get("workers",[]):
		if body.get("side")=="AI" or int(body.get("hp",0))<=0 or not bool(body.get("alive",true)):continue
		if body.has("building_type") and (not bool(body.get("complete",false)) or not bool(body.get("defense_active",false))):continue
		if int(body.get("damage",0))>0:result.append(body)
	return result

static func _risk(point: Vector2i, hero: Dictionary,hostiles: Array[Dictionary]) -> float:
	var risk:=0.0
	for enemy: Dictionary in hostiles:
		var layers: Array=["GROUND","AIR"] if enemy.has("building_type") else enemy.get("attack_layers",["GROUND"])
		if hero.get("movement_layer","GROUND") not in layers:continue
		var range:=int(enemy.get("attack_range",0))+int(hero.get("radius",14))+50
		if Vector2(point).distance_squared_to(Vector2(enemy.position))>range*range:continue
		risk+=float(enemy.damage)*20.0/maxi(1,int(enemy.get("attack_cooldown_ticks",30)))
	return risk

static func _escape_point(hero: Dictionary,world: Dictionary,military: Dictionary,hostiles: Array[Dictionary],shops_only: bool=false) -> Dictionary:
	var bounds: Rect2i=world.get("match_config",world.get("match_setup",{})).get("bounds",World.BOUNDS)
	var obstacles: Array=[]
	if hero.get("movement_layer","GROUND")=="GROUND":
		for prop: Dictionary in world.get("terrain",[]):
			if bool(prop.get("blocks_ground",false)):obstacles.append(prop)
		for building: Dictionary in world.get("buildings",[]):
			if int(building.get("hp",0))>0:obstacles.append(building)
	var candidates: Array[Dictionary]=[]
	for building: Dictionary in world.get("buildings",[]):
		if building.get("side")!="AI" or not bool(building.get("complete",false)) or int(building.get("hp",0))<=0:continue
		if building.get("building_type") not in ["BASE","SHOP","TOWER"]:continue
		if shops_only and building.get("building_type")!="SHOP":continue
		var offset:=Vector2(hero.position)-Vector2(building.position)
		if offset.length_squared()<1.0:offset=Vector2.RIGHT
		var distance:=int(building.get("radius",40))+int(hero.get("radius",14))+48
		for angle: float in [0.0,0.8,-0.8,1.6,-1.6]:
			candidates.append({"position":Vector2i((Vector2(building.position)+offset.normalized().rotated(angle)*distance).round()),"healing":building.get("building_type")=="SHOP"})
	for army: Dictionary in [] if shops_only else military.get("warbands",[]):
		if army.get("id")==hero.get("warband_id"):candidates.append({"position":army.get("home_anchor",hero.position),"healing":false})
	# A real healer is often a better refuge than a long run all the way home.
	for ally: Dictionary in [] if shops_only else military.get("soldiers",[]):
		if ally.get("side")=="AI" and int(ally.get("hp",0))>0 and int(ally.get("heal",0))>0:
			candidates.append({"position":Vector2i(ally.position)+Vector2i(64,0),"healing":true})
	var safe: Array[Dictionary]=[]
	for candidate: Dictionary in candidates:
		if _risk(candidate.position,hero,hostiles)>0:continue
		if not Navigation.point_clear(candidate.position,int(hero.get("radius",14)),bounds,obstacles):continue
		candidate["score"]=Vector2(hero.position).distance_to(Vector2(candidate.position))-(160.0 if candidate.healing else 0.0)
		safe.append(candidate)
	safe.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return float(a.score)<float(b.score))
	# Bounded true routes: only the six best refuges; no straight-line forcing
	# through an enclosed wall, enemy gunline or an impassable lake.
	for candidate: Dictionary in safe.slice(0,6):
		var route:=Navigation.find_path(hero.position,candidate.position,int(hero.get("radius",14)),bounds,obstacles)
		if route.is_empty():continue
		var previous: Vector2i=hero.position
		var distance:=0.0
		var safe_route:=true
		var start_risk:=_risk(hero.position,hero,hostiles)
		for point: Vector2i in route:
			var steps:=maxi(1,ceili(Vector2(previous).distance_to(Vector2(point))/64.0))
			for index: int in range(1,steps+1):
				var sample:=Vector2i(Vector2(previous).lerp(Vector2(point),float(index)/float(steps)).round())
				if _risk(sample,hero,hostiles)>maxf(start_risk,0.01)*1.25:safe_route=false
			distance+=Vector2(previous).distance_to(Vector2(point))
			previous=point
		if safe_route:return {"position":candidate.position,"length":distance}
	return {}

static func _recovery_purchase(hero: Dictionary,world: Dictionary) -> Dictionary:
	if int(hero.get("inventory",{}).get("POTION",0))>0:return {}
	if _affordable_potion(hero,world).is_empty():return {}
	for shop: Dictionary in world.get("buildings",[]):
		if shop.get("side")!="AI" or shop.get("building_type")!="SHOP" or not bool(shop.get("complete",false)) or int(shop.get("hp",0))<=0:continue
		if Vector2(hero.position).distance_to(Vector2(shop.position))<=Items.SHOP_RANGE:return {"type":"BUY_ITEM","unit_id":hero.id,"item_id":"POTION","building_id":shop.id}
	return {}

static func _affordable_potion(hero: Dictionary,world: Dictionary) -> Dictionary:
	var quote:=Items.purchase_quote(hero,"POTION")
	if not bool(quote.get("accepted",false)):return {}
	var stock: Dictionary=world.get("economy",{}).get("AI",{}).get("stock",{})
	for resource: String in quote.cost:
		if int(stock.get(resource,0))<int(quote.cost[resource]):return {}
	return quote

static func _has_local_healing(hero: Dictionary,military: Dictionary) -> bool:
	for skill: Dictionary in hero.get("skills",[]):
		if bool(skill.get("learned",false)) and skill.get("effect")=="HEAL":return true
	for ally: Dictionary in military.get("soldiers",[]):
		if ally.get("side")=="AI" and int(ally.get("hp",0))>0 and int(ally.get("heal",0))>0 and Vector2(hero.position).distance_to(Vector2(ally.position))<=int(ally.get("heal_range",150)):return true
	return false
