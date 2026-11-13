extends RefCounted
## Pure, query-local geometry for a Combat-owned finite recovery route.
## The caller owns stall detection, scheduling, command semantics, expiry,
## target exclusions and actual motion. This helper does not discover bodies.
const Navigation=preload("res://src/simulation/strategic_navigation.gd")
const Visibility=preload("res://src/simulation/strategic_visibility_r9.gd")
const VERSION:="movement-recovery-r14-v1"
const LOCAL_RANGE:=480
const CORRIDOR_RADIUS:=192
const MAX_DYNAMIC_OBSTACLES:=24
const QUERY_MARGIN:=3
const MAX_WAYPOINTS:=32

static func plan(unit:Dictionary,goal:Vector2i,target_id:String,local_candidates:Array,bounds:Rect2i,static_obstacles:Array,attack_target:Dictionary={})->Dictionary:
	if typeof(unit.get("position"))!=TYPE_VECTOR2I or int(unit.get("radius",0))<=0 or int(unit.get("hp",0))<=0:return _reject("INVALID_SOURCE")
	var origin:Vector2i=unit.position
	var radius:=int(unit.radius)
	var layer:=str(unit.get("movement_layer","GROUND"))
	var actor_id:=str(unit.get("id",""))
	var side:=str(unit.get("side",""))
	if actor_id.is_empty() or origin==goal:return _reject("NO_TRAVEL")
	var rows:Array[Dictionary]=[]
	var seen:Dictionary={}
	# local_candidates is the caller's existing current spatial projection.
	# No global roster, target chooser, command owner or hidden enemy is read.
	for value:Variant in local_candidates:
		if not value is Dictionary:continue
		var body:Dictionary=value
		var id:=str(body.get("id",""))
		if id.is_empty() or id==actor_id or id==target_id or seen.has(id):continue
		if int(body.get("hp",0))<=0 or str(body.get("movement_layer","GROUND"))!=layer or not Visibility.can_observe(body,side):continue
		# Fixed buildings already belong to static_obstacles. Living workers
		# remain dynamic bodies and must not become permanent route geometry.
		if body.has("building_type") and str(body.building_type)!="WORKER_OBSTACLE":continue
		if typeof(body.get("position"))!=TYPE_VECTOR2I or int(body.get("radius",0))<=0:continue
		var position:Vector2i=body.position
		var distance:=Vector2(origin).distance_squared_to(Vector2(position))
		if distance>float(LOCAL_RANGE*LOCAL_RANGE):continue
		var corridor_distance:=_segment_distance_sq(position,origin,goal)
		var corridor:=CORRIDOR_RADIUS+int(body.radius)+radius
		if corridor_distance>float(corridor*corridor):continue
		seen[id]=true
		rows.append({"id":id,"position":position,"radius":int(body.radius),"movement_layer":layer,"corridor_distance":corridor_distance,"origin_distance":distance})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if not is_equal_approx(float(a.corridor_distance),float(b.corridor_distance)):return float(a.corridor_distance)<float(b.corridor_distance)
		if not is_equal_approx(float(a.origin_distance),float(b.origin_distance)):return float(a.origin_distance)<float(b.origin_distance)
		return str(a.id)<str(b.id))
	if rows.is_empty():return _reject("NO_LOCAL_DYNAMIC_BLOCKERS")
	var blockers:Array[Dictionary]=[]
	var obstacles:Array[Dictionary]=[]
	# Keep all static circles for exact edge legality. Navigation bounds its
	# existing visibility-node generation independently; no static geometry is
	# dropped here merely to fit the dynamic-body selection budget.
	if layer!="AIR":
		for value:Variant in static_obstacles:
			if not value is Dictionary:continue
			var obstacle:Dictionary=value
			if not bool(obstacle.get("blocks_ground",true)):continue
			if typeof(obstacle.get("position"))!=TYPE_VECTOR2I or int(obstacle.get("radius",-1))<0:return _reject("INVALID_STATIC_GEOMETRY")
			obstacles.append({"id":str(obstacle.get("id","")),"position":Vector2i(obstacle.position),"radius":int(obstacle.radius),"blocks_ground":true})
	for index:int in range(mini(MAX_DYNAMIC_OBSTACLES,rows.size())):
		var row:Dictionary=rows[index]
		# Only detached authored scalar facts survive for the caller to compare
		# against future current bodies. Query inflation is not a stat write.
		blockers.append({"id":str(row.id),"position":Vector2i(row.position),"radius":int(row.radius),"movement_layer":str(row.movement_layer)})
		# Contact must remain a legal origin. Add at most3 planning pixels,
		# restricted by the actual available clearance at this current source;
		# never shrink an authored physical blocker to create a false passage.
		var clearance:=floori(sqrt(float(row.origin_distance)))-radius-int(row.radius)
		var padding:=mini(QUERY_MARGIN,maxi(0,clearance))
		obstacles.append({"id":"recovery-body:"+str(row.id),"position":Vector2i(row.position),"radius":int(row.radius)+padding,"blocks_ground":true})
	# Physically invalid current geometry cannot authorize a recovery escape.
	if not Navigation.point_clear(origin,radius,bounds,obstacles):return _reject("SOURCE_WITHIN_QUERY_MARGIN",blockers)
	if not attack_target.is_empty() and not Navigation.point_clear(goal,radius,bounds,obstacles):
		# A route to an enemy's far edge must not cut through that enemy.
		# This is query geometry only; the real body resolver remains final.
		if str(attack_target.get("movement_layer","GROUND"))==layer:
			obstacles.append({"id":"attack-target:"+target_id,"position":Vector2i(attack_target.position),"radius":int(attack_target.radius),"blocks_ground":true})
		var positions:=_attack_positions(unit,attack_target,bounds,obstacles)
		if positions.is_empty():return _reject("NO_CLEAR_ATTACK_POSITION",blockers)
		goal=positions[0]
	var route:Array[Vector2i]=Navigation.find_path(origin,goal,radius,bounds,obstacles)
	if route.is_empty():return _reject("NO_LOCAL_ROUTE",blockers)
	if route.size()>MAX_WAYPOINTS:return _reject("WAYPOINT_CAP",blockers)
	var previous:=origin
	for waypoint:Vector2i in route:
		if not Navigation.segment_clear(previous,waypoint,radius,bounds,obstacles):return _reject("UNSAFE_ROUTE",blockers)
		previous=waypoint
	if previous!=goal:return _reject("INCOMPLETE_ROUTE",blockers)
	return {"accepted":true,"reason":"LOCAL_DYNAMIC_ROUTE","route":route,"blockers":blockers,"version":VERSION}

static func _attack_positions(unit:Dictionary,target:Dictionary,bounds:Rect2i,obstacles:Array)->Array[Vector2i]:
	# At most eight endpoint/segment predicates on the already admitted due
	# query. Exactly one visibility search follows, not eight path searches.
	var result:Array[Vector2i]=[]
	var origin:Vector2i=unit.position
	var center:Vector2i=target.position
	var reach:=int(unit.attack_range)+int(target.radius)
	var distance:=maxi(int(unit.radius)+int(target.radius)+2,reach-2)
	var base:=Vector2(origin-center).angle()
	var rows:Array[Dictionary]=[]
	for offset:int in [0,1,-1,2,-2,3,-3,4]:
		var angle:=base+float(offset)*PI/4.0
		var point:=center+Vector2i((Vector2(cos(angle),sin(angle))*distance).round())
		if Vector2(point-center).length_squared()>float(reach*reach) or not Navigation.point_clear(point,int(unit.radius),bounds,obstacles):continue
		rows.append({"point":point,"direct":Navigation.segment_clear(origin,point,int(unit.radius),bounds,obstacles),"distance":Vector2(origin-point).length_squared(),"offset":absi(offset)})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if a.direct!=b.direct:return bool(a.direct)
		if a.distance!=b.distance:return float(a.distance)<float(b.distance)
		if a.offset!=b.offset:return int(a.offset)<int(b.offset)
		return a.point.x<b.point.x if a.point.x!=b.point.x else a.point.y<b.point.y)
	for row:Dictionary in rows:result.append(row.point)
	return result

static func _reject(reason:String,blockers:Array[Dictionary]=[])->Dictionary:
	return {"accepted":false,"reason":reason,"route":[],"blockers":blockers,"version":VERSION}

static func _segment_distance_sq(point:Vector2i,start:Vector2i,target:Vector2i)->float:
	var segment:=Vector2(target-start)
	if segment.is_zero_approx():return Vector2(point-start).length_squared()
	var progress:=clampf(Vector2(point-start).dot(segment)/segment.length_squared(),0.0,1.0)
	return Vector2(point).distance_squared_to(Vector2(start)+segment*progress)
