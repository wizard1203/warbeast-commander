extends RefCounted
## Owned, short-lived static-circle LOS adapter. Construct for one synchronous
## movement batch only; never retain this across environment/body mutation.
## Prepared math retains Navigation's target test, then original segment math.
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const DOMAIN := 32768
const MAX_PREPARED_OBSTACLES := 1024
var _obstacles: Array = []
var _centers := PackedVector2Array()
var _radii: Array[int] = []
var _by_radius: Dictionary = {}
var _valid := true
var _exact_circle_tests := 0
var _fallback_calls := 0
var _queries := 0

func _init(obstacles: Array) -> void:
	# The caller may release or mutate its observations after this scope. The
	# fallback must own them too, not just the normal prepared scalar projection.
	_obstacles=obstacles.duplicate(true)
	if obstacles.size()>MAX_PREPARED_OBSTACLES:_valid=false;return
	for value: Variant in _obstacles:
		if not value is Dictionary:_valid=false;return
		var obstacle: Dictionary=value
		if not bool(obstacle.get("blocks_ground",true)):continue
		if typeof(obstacle.get("position"))!=TYPE_VECTOR2I or typeof(obstacle.get("radius"))!=TYPE_INT:_valid=false;return
		var point: Vector2i=obstacle.position
		var radius: int=obstacle.radius
		if radius<0 or radius>DOMAIN or absi(point.x)>DOMAIN or absi(point.y)>DOMAIN:_valid=false;return
		_centers.append(Vector2(point))
		_radii.append(radius)

func segment_clear(start: Vector2i, target: Vector2i, radius: int, bounds: Rect2i) -> bool:
	_queries+=1
	if not _valid or radius<0 or radius>DOMAIN or absi(start.x)>DOMAIN or absi(start.y)>DOMAIN or absi(target.x)>DOMAIN or absi(target.y)>DOMAIN:
		_fallback_calls+=1
		return Navigation.segment_clear(start,target,radius,bounds,_obstacles)
	# Same bounds comparisons, before circles, as original point_clear(target).
	if target.x-radius<bounds.position.x or target.y-radius<bounds.position.y or target.x+radius>bounds.end.x or target.y+radius>bounds.end.y:return false
	if not _by_radius.has(radius):_by_radius[radius]=_compile(radius)
	var prepared: Dictionary=_by_radius[radius]
	var reach_squares: PackedFloat64Array=prepared.squares
	var rectangles: Array[Rect2i]=prepared.rectangles
	var precise_target := Vector2(target)
	for index: int in range(_centers.size()):
		# Padding encloses all original float arithmetic in the documented exact
		# integer domain. AABB only discards impossible circles, never changes a
		# near/tangent predicate or its original strict less-than comparison.
		var broad: Rect2i=rectangles[index]
		if not broad.has_point(target):continue
		_exact_circle_tests+=1
		if precise_target.distance_squared_to(_centers[index])<reach_squares[index]:return false
	var segment := Vector2(target-start)
	var stationary := segment.is_zero_approx()
	var segment_length_sq := segment.length_squared()
	var segment_start := Vector2(start)
	var min_x := mini(start.x,target.x)
	var max_x := maxi(start.x,target.x)
	var min_y := mini(start.y,target.y)
	var max_y := maxi(start.y,target.y)
	var edge_rectangle := Rect2i(Vector2i(min_x,min_y),Vector2i(max_x-min_x+1,max_y-min_y+1))
	for index: int in range(_centers.size()):
		var broad: Rect2i=rectangles[index]
		if not broad.intersects(edge_rectangle):continue
		var point: Vector2=_centers[index]
		var distance_sq: float
		_exact_circle_tests+=1
		# Small-domain integer subtraction converts to the same exact Vector2
		# operands as the old Vector2(point_i-start_i). No reciprocal, distance
		# approximation, changed operation order or float32 reach² is introduced.
		if stationary:distance_sq=(point-segment_start).length_squared()
		else:
			var progress := clampf((point-segment_start).dot(segment)/segment_length_sq,0,1)
			distance_sq=point.distance_squared_to(segment_start+segment*progress)
		if distance_sq<reach_squares[index]:return false
	return true

func _compile(radius: int) -> Dictionary:
	var squares := PackedFloat64Array()
	var rectangles: Array[Rect2i]=[]
	for index: int in range(_centers.size()):
		var reach := radius+_radii[index]
		squares.append(float(reach*reach))
		var extent := reach+16
		var point := Vector2i(_centers[index])
		rectangles.append(Rect2i(point-Vector2i(extent,extent),Vector2i(extent*2+1,extent*2+1)))
	return {"squares":squares,"rectangles":rectangles}

func diagnostics() -> Dictionary:
	return {"queries":_queries,"compiled_radii":_by_radius.size(),"prepared_obstacles":_centers.size(),"exact_circle_tests":_exact_circle_tests,"fallback_calls":_fallback_calls,"valid_geometry":_valid}

func clear() -> void:
	_obstacles.clear()
	_centers.clear()
	_radii.clear()
	_by_radius.clear()
	_valid=false
