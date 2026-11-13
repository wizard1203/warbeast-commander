extends RefCounted
## Read-only, bounded macro detours. These are ordinary command destinations,
## NOT physical routes injected into Combat and never authority to cross props.
const Navigation=preload("res://src/simulation/strategic_navigation.gd")
const Neutrals=preload("res://src/simulation/strategic_neutral_encounters.gd")
const Targeting=preload("res://src/simulation/strategic_combat_targeting.gd")
const VERSION:="m73-observed-safe-route-v2-physical-member-routing"
const MAX_THREATS:=8
const MAX_MEMBERS:=64
const MAX_WAYPOINTS:=12
const MAX_SEARCHES:=2
const SAFETY_MARGIN:=28

static func propose(world:Dictionary,army:Dictionary,goal:Vector2i,tick:int,avoid_ids:Array=[])->Dictionary:
	var start:=Vector2i(army.get("anchor",goal))
	var result:={"version":VERSION,"blocked":true,"waypoints":[],"next_point":start,"reason":"NO_AVAILABLE_MEMBERS","goal_guarded":false,"goal":goal,"tick":tick,"avoid_ids":avoid_ids.duplicate(),"threat_ids":[],"member_ids":[],"envelope_radius":0,"work":{"searches":0,"max_searches":MAX_SEARCHES,"threats":0,"max_threats":MAX_THREATS,"members":0,"max_members":MAX_MEMBERS,"waypoints":0,"max_waypoints":MAX_WAYPOINTS},"authority":"ordinary macro commands only; Combat keeps navigation, collision and attacks"}
	var members:Array[Dictionary]=[]
	var own_side:=str(army.get("side","AI"))
	var physical_radius:=0
	var envelope:=0
	for body:Dictionary in world.get("soldiers",[]):
		if str(body.get("warband_id",""))!=str(army.get("id","")) or str(body.get("side",""))!=own_side or int(body.get("hp",0))<=0 or body.get("direct_intent","")=="MOVE":continue
		members.append(body)
		if body.get("movement_layer","GROUND")=="GROUND":physical_radius=maxi(physical_radius,int(body.get("radius",14)))
		envelope=maxi(envelope,ceili(Vector2(body.position).distance_to(Vector2(start)))+int(body.get("radius",14)))
		if members.size()>MAX_MEMBERS:return _blocked(result,"MEMBER_BUDGET_EXCEEDED")
	if members.is_empty():return result
	members.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a.id)<str(b.id))
	result.member_ids=members.map(func(body:Dictionary)->String:return str(body.id))
	result.work.members=members.size()
	# Existing formation can rotate at a waypoint. Reserve a stable radial
	# envelope rather than only the currently short axis of a column.
	var pitch:=32
	for body:Dictionary in members:pitch=maxi(pitch,int(body.get("radius",14))*2+4)
	var rows:=ceili(float(members.size())/2.0) if army.get("formation")=="COLUMN" else ceili(float(members.size())/3.0)
	envelope=maxi(envelope,ceili(sqrt(pow(float(rows*pitch)/2.0,2.0)+pow(float(maxi(pitch,48)),2.0)))+physical_radius)
	result.envelope_radius=envelope
	var wanted:={}
	for id:Variant in avoid_ids:wanted[str(id)]=true
	var threats:Array[Dictionary]=[]
	var seen:={}
	for body:Dictionary in world.get("micro_neutral_targets",[])+world.get("soldiers",[])+world.get("buildings",[]):
		var id:=str(body.get("id",""))
		if id.is_empty() or seen.has(id) or int(body.get("hp",0))<=0 or not bool(body.get("visible",true)) or str(body.get("side",""))==own_side:continue
		if not wanted.has(id) and not wanted.has(str(body.get("camp_id",""))):continue
		seen[id]=true
		if threats.size()>=MAX_THREATS:return _blocked(result,"THREAT_BUDGET_EXCEEDED")
		var neutral:bool=bool(body.get("neutral",false)) or body.get("side")=="NEUTRAL"
		var radius:=maxi(Targeting.DISCOVERY,int(body.get("attack_range",0)))+SAFETY_MARGIN
		if neutral:radius=maxi(radius,Neutrals.AGGRO_RADIUS+SAFETY_MARGIN)
		var circles:Array[Dictionary]=[{"position":Vector2i(body.position),"radius":radius}]
		if neutral and body.has("home_position") and Vector2(body.position).distance_to(Vector2(body.home_position))>16.0:
			# A returning guard cannot attack now, but home is a real future
			# re-aggro zone, and our ATTACK_MOVE can still acquire its current body.
			circles.append({"position":Vector2i(body.home_position),"radius":maxi(Neutrals.AGGRO_RADIUS,Targeting.DISCOVERY)+SAFETY_MARGIN})
		threats.append({"id":id,"camp_id":body.get("camp_id",""),"circles":circles,"returning":bool(body.get("leashing",false))})
	result.threat_ids=threats.map(func(body:Dictionary)->String:return str(body.id))
	result.work.threats=threats.size()
	var bounds:=_bounds(world)
	var physical:Array[Dictionary]=[]
	for building:Dictionary in world.get("buildings",[]):
		if int(building.get("hp",0))>0 and bool(building.get("visible",true)):physical.append({"id":"structure:"+str(building.get("id","")),"position":Vector2i(building.position),"radius":int(building.get("radius",32)),"blocks_ground":true})
	for prop:Dictionary in world.get("terrain",[]):
		if bool(prop.get("blocks_ground",false)):physical.append({"id":"terrain:"+str(prop.get("id","")),"position":Vector2i(prop.position),"radius":int(prop.get("radius",0)),"blocks_ground":true})
	var obstacles:Array=physical.duplicate(true)
	for threat:Dictionary in threats:
		for index:int in range(threat.circles.size()):
			var circle:Dictionary=threat.circles[index]
			for body:Dictionary in members:
				if Vector2(body.position).distance_to(Vector2(circle.position))<=float(int(circle.radius)+int(body.get("radius",14))):return _blocked(result,"CURRENTLY_EXPOSED")
			if Vector2(goal).distance_to(Vector2(circle.position))<=float(int(circle.radius)+physical_radius):
				result.goal_guarded=true
				return _blocked(result,"TARGET_GUARDED")
			obstacles.append({"id":"observed-threat:"+str(threat.id)+":"+str(index),"position":circle.position,"radius":int(circle.radius)+envelope,"blocks_ground":true})
	if not Navigation.point_clear(goal,physical_radius,bounds,physical):return _blocked(result,"PHYSICAL_GOAL_BLOCKED")
	var path:Array[Vector2i]=Navigation.find_path(start,goal,physical_radius,bounds,obstacles)
	result.work.searches=1
	if path.is_empty():return _blocked(result,"NO_SAFE_ROUTE")
	# Combat rotates formation offsets and independently routes every actual
	# body around physical props. A rigid translation of the current offsets
	# across ALL future legs is not its movement contract: that false model
	# rejected a compact five-member natural army at the real river crossing.
	# Keep real body radii in Navigation, full member envelope around dangerous
	# weapons/discovery zones, and current exposure checks above. The actual
	# per-body resolver still decides physical travel; dynamic facts and genuine
	# lack of displacement are rechecked by the finite journey lease.
	if path.size()>MAX_WAYPOINTS:return _blocked(result,"WAYPOINT_BUDGET_EXCEEDED")
	result.blocked=false;result.waypoints=path;result.next_point=path[0];result.reason="SAFE_DETOUR" if path.size()>1 else "DIRECT_CLEAR";result.work.waypoints=path.size()
	return result

static func _blocked(result:Dictionary,reason:String)->Dictionary:
	result.reason=reason
	return result

static func _bounds(world:Dictionary)->Rect2i:
	var configured:Variant=world.get("match_config",{}).get("bounds",world.get("match_setup",{}).get("bounds"))
	if configured is Rect2i:return configured
	var value:Dictionary=world.get("arena_bounds",{"min_x":80,"min_y":80,"max_x":3280,"max_y":2080})
	return Rect2i(Vector2i(int(value.get("min_x",80)),int(value.get("min_y",80))),Vector2i(int(value.get("max_x",3280))-int(value.get("min_x",80)),int(value.get("max_y",2080))-int(value.get("min_y",80))))

