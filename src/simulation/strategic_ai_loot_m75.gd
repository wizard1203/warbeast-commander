extends RefCounted
## Finite computer-only item errands. Commands still use normal Host admission;
## native NeutralEncounters owns all capacity checks and actual item grants.
const Items=preload("res://src/simulation/strategic_hero_items.gd")
const Navigation=preload("res://src/simulation/strategic_navigation.gd")
const World=preload("res://src/simulation/strategic_world.gd")
const MAX_DISTANCE:=900.0
const MAX_CANDIDATES:=4
const STALE_TICKS:=240
const COOLDOWN_TICKS:=200
var states:Dictionary={}
var cooldowns:Dictionary={}
var diagnostics:Dictionary={}
var _pending:Dictionary={}

func reset()->void:
	states.clear();cooldowns.clear();diagnostics.clear();_pending.clear()

func plan(tick:int,world:Dictionary,military:Dictionary,preserved:Dictionary={})->Dictionary:
	_pending.clear()
	for key:String in cooldowns.keys():
		if int(cooldowns[key])<=tick:cooldowns.erase(key)
	var heroes:Dictionary={};var bodies:Dictionary={};var groups:Dictionary={};var drops:Dictionary={}
	for hero:Dictionary in military.get("heroes",{}).get("officers",[]):
		if hero.get("side")=="AI" and hero.get("state")=="ACTIVE" and int(hero.get("hp",0))>0:heroes[str(hero.id)]=hero
	for body:Dictionary in military.get("soldiers",[]):bodies[str(body.id)]=body
	for group:Dictionary in military.get("warbands",[]):groups[str(group.id)]=group
	for drop:Dictionary in world.get("neutral_loot",[]):drops[str(drop.id)]=drop
	for id:String in states.keys():
		if not heroes.has(id) or not bodies.has(id):states.erase(id);continue
		var state:Dictionary=states[id];var body:Dictionary=bodies[id];var hero:Dictionary=heroes[id]
		var owns_move:bool=body.get("direct_intent")=="MOVE" and body.get("direct_destination")==state.point
		if int(state.get("accepted_tick",-1))>=0 and not owns_move:
			# Another ordinary army/preservation order already took ownership.
			# Never restore the old errand over that newer command.
			states.erase(id);continue
		if preserved.has(id):
			# Preservation is the newer owner in this very decision batch. A
			# trailing TRANSFER would clear its just-admitted escape MOVE when
			# both fit the shared budget. Release only our obsolete task; the
			# ordinary higher-priority preservation command owns physical action.
			diagnostics[id]={"phase":"YIELD_TO_PRESERVATION","tick":tick,"loot_id":state.loot_id}
			cooldowns[str(state.loot_id)]=tick+COOLDOWN_TICKS
			states.erase(id);continue
		var drop:Dictionary=drops.get(str(state.loot_id),{})
		var reason:=""
		if drop.get("state")!="AVAILABLE":reason="COLLECTED" if drop.get("recipient_id")==id and int(hero.get("inventory",{}).get(str(state.item_id),0))>int(state.inventory_before) else "DROP_INVALIDATED"
		elif drop.has("expires_tick") and tick>=int(drop.expires_tick):reason="DROP_EXPIRED"
		elif not Items.validate_gain(hero,str(state.item_id)).get("accepted",false):reason="CAPACITY_CHANGED"
		elif groups.get(str(body.get("warband_id","")),{}).get("intent")=="RETREAT":reason="ARMY_RETREAT"
		elif not _quiet(body,tick) or not _safe_corridor(body,Vector2i(state.point),world,military):reason="CORRIDOR_DANGEROUS"
		else:
			var distance:=Vector2(body.position).distance_to(Vector2(state.point))
			if distance<float(state.best_distance)-8.0:state.best_distance=distance;state.last_progress_tick=tick
			elif int(state.get("accepted_tick",-1))>=0 and tick-int(state.last_progress_tick)>=STALE_TICKS:reason="NO_PHYSICAL_PROGRESS"
		if not reason.is_empty():
			diagnostics[id]={"phase":reason,"tick":tick,"loot_id":state.loot_id}
			if reason!="COLLECTED":cooldowns[str(state.loot_id)]=tick+COOLDOWN_TICKS
			if owns_move:return _offer(id,{"type":"TRANSFER_UNITS","unit_ids":[id],"target_warband_id":body.warband_id},tick)
			states.erase(id);continue
		if int(state.get("accepted_tick",-1))<0:return _offer(id,{"type":"UNIT_MOVE","unit_id":id,"target_position":state.point},tick)
		diagnostics[id]={"phase":"APPROACH","tick":tick,"loot_id":state.loot_id,"distance":Vector2(body.position).distance_to(Vector2(state.point)),"last_progress_tick":state.last_progress_tick}
	var candidates:Array[Dictionary]=[]
	for id:String in heroes:
		if states.has(id) or preserved.has(id) or not bodies.has(id):continue
		var hero:Dictionary=heroes[id];var body:Dictionary=bodies[id]
		if int(hero.hp)*100<55*maxi(1,int(hero.max_hp)) or body.get("direct_intent","") not in ["","HOLD","AUTO_HOLD"] or groups.get(str(body.get("warband_id","")),{}).get("intent")=="RETREAT" or not _quiet(body,tick) or _recent_fighting(body,tick):continue
		for drop:Dictionary in drops.values():
			if drop.get("state")!="AVAILABLE" or not bool(drop.get("visible",true)) or cooldowns.has(str(drop.id)):continue
			if not bool(drop.get("hero_drop",false)) and drop.get("owner")!="AI":continue
			if drop.has("expires_tick") and tick>=int(drop.expires_tick):continue
			if not Items.validate_gain(hero,str(drop.get("item_id",""))).get("accepted",false):continue
			var distance:=Vector2(body.position).distance_to(Vector2(drop.position))
			if distance>MAX_DISTANCE or distance<=float(drop.get("pickup_radius",160)):continue # Already handled by native auto pickup.
			var reserved:=false
			for state:Dictionary in states.values():
				if state.loot_id==drop.id:reserved=true;break
			if reserved:continue
			var item:Dictionary=Items.ITEMS.get(str(drop.item_id),{})
			var score:=distance-(120.0 if item.get("tier") in ["ADVANCED","AURA"] else 0.0)
			candidates.append({"hero_id":id,"drop":drop,"score":score,"distance":distance})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a.hero_id)+str(a.drop.id)<str(b.hero_id)+str(b.drop.id) if is_equal_approx(float(a.score),float(b.score)) else float(a.score)<float(b.score))
	for candidate:Dictionary in candidates.slice(0,MAX_CANDIDATES):
		var id:=str(candidate.hero_id);var body:Dictionary=bodies[id];var drop:Dictionary=candidate.drop
		if not _safe_corridor(body,Vector2i(drop.position),world,military):continue
		states[id]={"loot_id":drop.id,"item_id":drop.item_id,"point":drop.position,"origin":body.position,"warband_id":body.warband_id,"inventory_before":int(heroes[id].get("inventory",{}).get(str(drop.item_id),0)),"accepted_tick":-1,"last_progress_tick":tick,"best_distance":candidate.distance}
		return _offer(id,{"type":"UNIT_MOVE","unit_id":id,"target_position":drop.position},tick)
	return {}

func _offer(id:String,command:Dictionary,tick:int)->Dictionary:
	_pending={"id":id,"order":command.duplicate(true),"tick":tick}
	return command

func record_result(tick:int,command:Dictionary,result:Dictionary)->void:
	if _pending.get("order",{})!=command:return
	var id:=str(_pending.id)
	if states.has(id) and bool(result.get("accepted",false)):
		if command.type=="UNIT_MOVE":states[id].accepted_tick=tick;states[id].last_progress_tick=tick
		elif command.type=="TRANSFER_UNITS":states.erase(id)
	elif states.has(id):
		cooldowns[str(states[id].loot_id)]=tick+COOLDOWN_TICKS;states.erase(id)
	_pending.clear()

func get_state()->Dictionary:
	return {"states":states.duplicate(true),"cooldowns":cooldowns.duplicate(true),"diagnostics":diagnostics.duplicate(true)}

static func _quiet(body:Dictionary,tick:int)->bool:
	var damage_tick:=int(body.get("last_damage_tick",-1))
	return damage_tick<0 or tick-damage_tick>60

static func _recent_fighting(body:Dictionary,tick:int)->bool:
	var action_tick:=int(body.get("last_action_tick",-1000000))
	var kind:=str(body.get("last_action_kind",""))
	return tick-action_tick<=40 and (kind in ["ATTACK","HEAL"] or kind.begins_with("SKILL_"))

static func _safe_corridor(body:Dictionary,point:Vector2i,world:Dictionary,military:Dictionary)->bool:
	var start:=Vector2(body.position)
	for enemy:Dictionary in military.get("soldiers",[])+military.get("micro_neutral_targets",[])+world.get("buildings",[])+world.get("workers",[]):
		if enemy.get("side")=="AI" or int(enemy.get("hp",0))<=0 or not bool(enemy.get("alive",true)) or not bool(enemy.get("visible",true)):continue
		if enemy.has("building_type") and (not bool(enemy.get("complete",false)) or not bool(enemy.get("defense_active",false))):continue
		if int(enemy.get("damage",0))<=0:continue
		if body.get("movement_layer","GROUND") not in enemy.get("attack_layers",["GROUND","AIR"] if enemy.has("building_type") else ["GROUND"]):continue
		var reach:=maxi(240,int(enemy.get("attack_range",0))+int(body.get("radius",14))+80)
		var closest:=Geometry2D.get_closest_point_to_segment(Vector2(enemy.position),start,Vector2(point))
		if closest.distance_to(Vector2(enemy.position))<=float(reach):return false
	var bounds:Rect2i=world.get("match_config",{}).get("bounds",World.BOUNDS)
	if body.get("movement_layer","GROUND")!="GROUND":return bounds.has_point(point)
	var obstacles:Array=[]
	for prop:Dictionary in world.get("terrain",[]):
		if bool(prop.get("blocks_ground",false)):obstacles.append(prop)
	for building:Dictionary in world.get("buildings",[]):
		if int(building.get("hp",0))>0:obstacles.append(building)
	# Deliberately conservative: short direct errands only. An obstacle detour
	# is deferred instead of asking a solo hero to traverse an untested path.
	return Navigation.segment_clear(body.position,point,int(body.get("radius",14)),bounds,obstacles)
