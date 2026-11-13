extends RefCounted
## M99 isolated experiment. Production StrategicNavigation remains unchanged.
const NativeM99 = preload("res://src/simulation/strategic_native_navigation_m99.gd")
static var native_enabled := true
## Deterministic bounded visibility routes for circular physical ground props.
## Dynamic body separation stays in UnitBodyResolver, never in this planner.
const MAX_OBSTACLES := 32
const MAX_NODES := 258
static func escape_step(start:Vector2i,goal:Vector2i,radius:int,bounds:Rect2i,obstacles:Array,max_step:int=4)->Vector2i:
	# For a virtual formation anchor initially inside an inflated planning
	# halo. This does NOT relax point_clear/segment_clear for physical bodies.
	# Every overlapping circle must get no closer throughout the segment; no
	# new circle may be crossed. Genuine closed traps remain unreachable.
	if radius<0 or max_step<=0 or point_clear(start,radius,bounds,obstacles):return start
	var best:=start
	var best_cost:=_escape_cost(start,radius,bounds,obstacles)
	var best_goal:=Vector2(start).distance_squared_to(Vector2(goal))
	var seen:Dictionary={}
	for distance:int in [max_step,maxi(1,max_step/2),1]:
		for index:int in range(32):
			var angle:=float(index)*TAU/32.0
			var delta:=Vector2i((Vector2(cos(angle),sin(angle))*distance).round())
			var candidate:=start+delta
			if delta==Vector2i.ZERO or seen.has(candidate):continue
			seen[candidate]=true
			if Vector2(delta).length()>float(max_step)+0.001:continue
			if not _escape_edge(start,candidate,radius,bounds,obstacles):continue
			var cost:=_escape_cost(candidate,radius,bounds,obstacles)
			var remaining:=Vector2(candidate).distance_squared_to(Vector2(goal))
			if cost<best_cost-0.0001 or is_equal_approx(cost,best_cost) and cost<_escape_cost(start,radius,bounds,obstacles) and remaining<best_goal:
				best=candidate;best_cost=cost;best_goal=remaining
	return best

static func _escape_cost(point:Vector2i,radius:int,bounds:Rect2i,obstacles:Array)->float:
	var cost:=float(maxi(0,bounds.position.x+radius-point.x)+maxi(0,point.x+radius-bounds.end.x)+maxi(0,bounds.position.y+radius-point.y)+maxi(0,point.y+radius-bounds.end.y))
	for obstacle:Dictionary in obstacles:
		if bool(obstacle.get("blocks_ground",true)):cost+=maxf(0.0,float(radius+int(obstacle.radius))-Vector2(point).distance_to(Vector2(obstacle.position)))
	return cost

static func _escape_edge(start:Vector2i,target:Vector2i,radius:int,bounds:Rect2i,obstacles:Array)->bool:
	var delta:=target-start
	for pair:Array in [[start.x-radius-bounds.position.x,target.x-radius-bounds.position.x],[bounds.end.x-start.x-radius,bounds.end.x-target.x-radius],[start.y-radius-bounds.position.y,target.y-radius-bounds.position.y],[bounds.end.y-start.y-radius,bounds.end.y-target.y-radius]]:
		if int(pair[1])<mini(0,int(pair[0])):return false
	for obstacle:Dictionary in obstacles:
		if not bool(obstacle.get("blocks_ground",true)):continue
		var reach:=radius+int(obstacle.radius)
		var offset:=start-Vector2i(obstacle.position)
		if Vector2(offset).length_squared()<float(reach*reach):
			# Nonnegative initial derivative makes squared distance monotone
			# along the entire straight escape segment, not just its endpoint.
			if Vector2(offset).dot(Vector2(delta))<0.0:return false
		elif _segment_distance_sq(obstacle.position,start,target)<float(reach*reach):return false
	return true

static func point_clear(point: Vector2i,radius: int,bounds: Rect2i,obstacles: Array) -> bool:
	if point.x-radius<bounds.position.x or point.y-radius<bounds.position.y or point.x+radius>bounds.end.x or point.y+radius>bounds.end.y: return false
	for obstacle: Dictionary in obstacles:
		if not bool(obstacle.get("blocks_ground",true)): continue
		var distance:=radius+int(obstacle.radius)
		if Vector2(point).distance_squared_to(Vector2(obstacle.position))<float(distance*distance): return false
	return true
static func segment_clear(start: Vector2i,target: Vector2i,radius: int,bounds: Rect2i,obstacles: Array) -> bool:
	if not point_clear(target,radius,bounds,obstacles): return false
	return _segment_obstacles_clear(start,target,radius,obstacles)
static func _segment_obstacles_clear(start: Vector2i,target: Vector2i,radius: int,obstacles: Array) -> bool:
	for obstacle: Dictionary in obstacles:
		if not bool(obstacle.get("blocks_ground",true)): continue
		var reach:=radius+int(obstacle.radius)
		if _segment_distance_sq(obstacle.position,start,target)<float(reach*reach): return false
	return true
static func _prepare_visibility(start: Vector2i,target: Vector2i,radius: int,obstacles: Array) -> Dictionary:
	# Query-local only: dynamic bodies must be read anew by the next route.
	# Outside this small integer domain retain the complete original predicate.
	if radius>32768 or obstacles.size()>1024 or absi(start.x)>32768 or absi(start.y)>32768 or absi(target.x)>32768 or absi(target.y)>32768: return {}
	var positions: Array[Vector2i]=[]
	var reaches: Array[int]=[]
	for obstacle: Dictionary in obstacles:
		if not bool(obstacle.get("blocks_ground",true)): continue
		if typeof(obstacle.get("position"))!=TYPE_VECTOR2I or typeof(obstacle.get("radius"))!=TYPE_INT: return {}
		var point: Vector2i=obstacle.position
		var obstacle_radius: int=obstacle.radius
		if obstacle_radius<0 or obstacle_radius>32768 or absi(point.x)>32768 or absi(point.y)>32768: return {}
		positions.append(point)
		reaches.append(radius+obstacle_radius)
	return {"positions":positions,"reaches":reaches}
static func _prepared_visibility_rectangles(positions: Array,reaches: Array) -> Array[Rect2i]:
	var rectangles: Array[Rect2i]=[]
	for index: int in range(positions.size()):
		var point: Vector2i=positions[index]
		var extent: int=int(reaches[index])+16
		# Closed integer intervals represented as half-open Rect2i cells. The
		# final +1 keeps tangent AABBs included, exactly as the old inequalities.
		rectangles.append(Rect2i(point-Vector2i(extent,extent),Vector2i(extent*2+1,extent*2+1)))
	return rectangles
static func _prepared_edge_clear(start: Vector2i,target: Vector2i,positions: Array,reaches: Array,rectangles: Array=[]) -> bool:
	var min_x:=mini(start.x,target.x)
	var max_x:=maxi(start.x,target.x)
	var min_y:=mini(start.y,target.y)
	var max_y:=maxi(start.y,target.y)
	# These are the identical operands used by _segment_distance_sq, invariant
	# across all circles on this edge. Keep division/order, not a reciprocal.
	var segment:=Vector2(target-start)
	var stationary:=segment.is_zero_approx()
	var segment_length_sq:=segment.length_squared()
	var segment_start:=Vector2(start)
	var use_rectangles:=not rectangles.is_empty() and rectangles.size()==positions.size()
	var edge_rectangle:=Rect2i(Vector2i(min_x,min_y),Vector2i(max_x-min_x+1,max_y-min_y+1))
	for index: int in range(positions.size()):
		if use_rectangles:
			var broad: Rect2i=rectangles[index]
			if not broad.intersects(edge_rectangle): continue
		var point: Vector2i=positions[index]
		var reach: int=reaches[index]
		# Conservative integer AABB, not a new distance rule. In the supported
		# <=32768 domain, 16px padding comfortably encloses Vector2 projection
		# rounding (well below1px); exact/tangent/nearby cases keep the OLD math.
		if not use_rectangles and (point.x+reach+16<min_x or point.x-reach-16>max_x or point.y+reach+16<min_y or point.y-reach-16>max_y): continue
		var distance_sq: float
		if stationary:distance_sq=Vector2(point-start).length_squared()
		else:
			var progress:=clampf(Vector2(point-start).dot(segment)/segment_length_sq,0,1)
			distance_sq=Vector2(point).distance_squared_to(segment_start+segment*progress)
		if distance_sq<float(reach*reach): return false
	return true
static func _prepared_point_clear(point: Vector2i,radius: int,bounds: Rect2i,positions: Array,reaches: Array,rectangles: Array=[]) -> bool:
	if point.x-radius<bounds.position.x or point.y-radius<bounds.position.y or point.x+radius>bounds.end.x or point.y+radius>bounds.end.y: return false
	var precise_point:=Vector2(point)
	var use_rectangles:=not rectangles.is_empty() and rectangles.size()==positions.size()
	for index: int in range(positions.size()):
		if use_rectangles:
			var broad: Rect2i=rectangles[index]
			if not broad.has_point(point): continue
		var center: Vector2i=positions[index]
		var reach: int=reaches[index]
		# Only used in the same small-integer domain as prepared edges. The
		# generous16px margin rejects far circles, never a tangent/near boundary.
		# Any actual circle test retains the public predicate's exact Vector2 math.
		if not use_rectangles and (point.x<center.x-reach-16 or point.x>center.x+reach+16 or point.y<center.y-reach-16 or point.y>center.y+reach+16): continue
		if precise_point.distance_squared_to(Vector2(center))<float(reach*reach): return false
	return true
static func find_path(start: Vector2i,target: Vector2i,radius: int,bounds: Rect2i,obstacles: Array) -> Array[Vector2i]:
	var result: Array[Vector2i]=[]
	if radius<0 or not point_clear(target,radius,bounds,obstacles): return result
	if segment_clear(start,target,radius,bounds,obstacles): return [target]
	var relevant: Array[Dictionary]=[]
	var corridor:=Rect2(Vector2(mini(start.x,target.x),mini(start.y,target.y)),Vector2(absi(start.x-target.x),absi(start.y-target.y))).grow(512)
	for obstacle: Dictionary in obstacles:
		if bool(obstacle.get("blocks_ground",true)) and corridor.grow(float(obstacle.radius)).has_point(Vector2(obstacle.position)): relevant.append(obstacle)
	relevant.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var first:=_segment_distance_sq(a.position,start,target)
		var second:=_segment_distance_sq(b.position,start,target)
		return str(a.id)<str(b.id) if is_equal_approx(first,second) else first<second)
	var visibility:=_prepare_visibility(start,target,radius,obstacles)
	var use_prepared:=not visibility.is_empty()
	var visibility_positions: Array=visibility.get("positions",[])
	var visibility_reaches: Array=visibility.get("reaches",[])
	var visibility_rectangles: Array[Rect2i]=[]
	if use_prepared:visibility_rectangles=_prepared_visibility_rectangles(visibility_positions,visibility_reaches)
	var nodes: Array[Vector2i]=[start,target]
	var seen={start:true,target:true}
	for obstacle: Dictionary in relevant.slice(0,MAX_OBSTACLES):
		# Circumscribe the inflated circle: the chord between adjacent octagon
		# vertices remains outside the actual radius, not only its endpoints.
		var distance:=ceili(float(int(obstacle.radius)+radius+6)*1.09)
		for index: int in range(8):
			var angle:=float(index)*PI/4.0
			var point: Vector2i=obstacle.position+Vector2i(roundi(cos(angle)*distance),roundi(sin(angle)*distance))
			if nodes.size()<MAX_NODES and not seen.has(point):
				var clear:=_prepared_point_clear(point,radius,bounds,visibility_positions,visibility_reaches,visibility_rectangles) if use_prepared and absi(point.x)<=32768 and absi(point.y)<=32768 else point_clear(point,radius,bounds,obstacles)
				if not clear: continue
				nodes.append(point)
				seen[point]=true
	# Inflated obstacle vertices may be outside the query's small domain.
	# Such edges retain the original full predicate, not the AABB shortcut.
	var prepared_nodes: Array[bool]=[]
	var node_vectors: Array[Vector2]=[]
	for point: Vector2i in nodes:
		prepared_nodes.append(absi(point.x)<=32768 and absi(point.y)<=32768)
		# Exact same integer-to-Vector2 conversion, once per immutable node.
		node_vectors.append(Vector2(point))
	# M81 query-local compaction only after every original vertex was built.
	# Every edge AABB is contained in this whole-node AABB. A prepared circle
	# rectangle disjoint from the latter would be skipped by the original
	# rectangle intersection on EVERY edge; no distance/float math changes.
	# Small graphs retain the original path to avoid paying setup overhead.
	if use_prepared and visibility_positions.size()>=16 and nodes.size()>=8:
		var graph_min: Vector2i=nodes[0]
		var graph_max: Vector2i=nodes[0]
		for point: Vector2i in nodes:
			graph_min.x=mini(graph_min.x,point.x);graph_min.y=mini(graph_min.y,point.y)
			graph_max.x=maxi(graph_max.x,point.x);graph_max.y=maxi(graph_max.y,point.y)
		# Identical closed-integer-to-half-open convention to each edge.
		var graph_rectangle:=Rect2i(graph_min,graph_max-graph_min+Vector2i.ONE)
		var edge_count_m81:=0
		for index: int in range(visibility_positions.size()):
			var broad: Rect2i=visibility_rectangles[index]
			if not broad.intersects(graph_rectangle):continue
			if edge_count_m81!=index:
				visibility_positions[edge_count_m81]=visibility_positions[index]
				visibility_reaches[edge_count_m81]=visibility_reaches[index]
				visibility_rectangles[edge_count_m81]=visibility_rectangles[index]
			edge_count_m81+=1
		visibility_positions.resize(edge_count_m81)
		visibility_reaches.resize(edge_count_m81)
		visibility_rectangles.resize(edge_count_m81)
	# Only the existing validated <=32768 integer prepared domain.
	var edge_centers_m90: PackedVector2Array=PackedVector2Array()
	var edge_reach_squares_m90: PackedFloat64Array=PackedFloat64Array()
	var use_linear_m90: bool=use_prepared and visibility_positions.size()>=16
	if use_linear_m90:
		edge_centers_m90.resize(visibility_positions.size())
		edge_reach_squares_m90.resize(visibility_reaches.size())
		for index_m90: int in range(visibility_positions.size()):
			edge_centers_m90[index_m90]=Vector2(visibility_positions[index_m90])
			var reach_m90: int=visibility_reaches[index_m90]
			edge_reach_squares_m90[index_m90]=float(reach_m90*reach_m90)
	# Original graph prefix above remains byte-for-byte: node order/legality,
	# relevant sorting, compaction and typed geometric operands are not replaced.
	if native_enabled and use_linear_m90 and not prepared_nodes.has(false):
		var answer := NativeM99.try_solve_graph(nodes,edge_centers_m90,edge_reach_squares_m90,visibility_rectangles)
		if bool(answer.get("accepted",false)):
			result.assign(answer.path)
			return result
	var distances: Array[float]=[]
	var previous: Array[int]=[]
	var visited: Array[bool]=[]
	distances.resize(nodes.size()); distances.fill(INF)
	previous.resize(nodes.size()); previous.fill(-1)
	visited.resize(nodes.size()); visited.fill(false)
	distances[0]=0
	for _iteration: int in range(nodes.size()):
		var current:=-1
		var best:=INF
		for index: int in range(nodes.size()):
			if not visited[index] and distances[index]<best:
				best=distances[index]
				current=index
		if current<0 or current==1: break
		visited[current]=true
		var current_vector: Vector2=node_vectors[current]
		var current_distance: float=distances[current]
		for next: int in range(1,nodes.size()):
			if visited[next] or next==current: continue
			var candidate:=current_distance+current_vector.distance_to(node_vectors[next])
			# Every possible next node (including target) already passed
			# point_clear in this immutable query. Start is never a next node.
			if candidate<distances[next]:
				var clear:=(_linear_edge_clear_m90(nodes[current],nodes[next],edge_centers_m90,edge_reach_squares_m90,visibility_rectangles) if use_linear_m90 else _prepared_edge_clear(nodes[current],nodes[next],visibility_positions,visibility_reaches,visibility_rectangles)) if use_prepared and prepared_nodes[current] and prepared_nodes[next] else _segment_obstacles_clear(nodes[current],nodes[next],radius,obstacles)
				if clear:
					distances[next]=candidate
					previous[next]=current
	if previous[1]<0: return result
	var cursor:=1
	for _step: int in range(nodes.size()):
		if cursor<=0: break
		result.push_front(nodes[cursor])
		cursor=previous[cursor]
	return result
static func _segment_distance_sq(point: Vector2i,start: Vector2i,target: Vector2i) -> float:
	var segment:=Vector2(target-start)
	if segment.is_zero_approx(): return Vector2(point-start).length_squared()
	var progress:=clampf(Vector2(point-start).dot(segment)/segment.length_squared(),0,1)
	return Vector2(point).distance_squared_to(Vector2(start)+segment*progress)

static func _linear_edge_clear_m90(start: Vector2i,target: Vector2i,centers: PackedVector2Array,reach_squares: PackedFloat64Array,rectangles: Array) -> bool:
	var min_x:=mini(start.x,target.x)
	var max_x:=maxi(start.x,target.x)
	var min_y:=mini(start.y,target.y)
	var max_y:=maxi(start.y,target.y)
	# The original sequence and float operation order, NOT reciprocals or
	# analytically simplified distance. No cache outlives find_path.
	var segment:=Vector2(target-start)
	var stationary:=segment.is_zero_approx()
	var segment_length_sq:=segment.length_squared()
	var segment_start:=Vector2(start)
	var edge_rectangle:=Rect2i(Vector2i(min_x,min_y),Vector2i(max_x-min_x+1,max_y-min_y+1))
	for index: int in range(centers.size()):
		# Existing prepared graph ALWAYS has one rectangle per center.
		var broad: Rect2i=rectangles[index]
		if not broad.intersects(edge_rectangle):continue
		var point: Vector2=centers[index]
		var distance_sq: float
		# Integers in [-32768,32768], and their differences in [-65536,65536],
		# are exactly representable as Vector2 real_t. This subtraction has the
		# same bits as the original Vector2(point_i-start_i); all later math is
		# unchanged. Unvalidated inputs never enter this helper.
		if stationary:distance_sq=(point-segment_start).length_squared()
		else:
			var progress:=clampf((point-segment_start).dot(segment)/segment_length_sq,0,1)
			distance_sq=point.distance_squared_to(segment_start+segment*progress)
		# PackedFloat64Array retains the original GDScript float(reach*reach),
		# unlike PackedFloat32Array which would change some strict boundaries.
		if distance_sq<reach_squares[index]:return false
	return true

static func diagnostics() -> Dictionary:
	return NativeM99.diagnostics()

static func reset_diagnostics() -> void:
	NativeM99.reset_diagnostics()
