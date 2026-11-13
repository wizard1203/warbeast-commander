extends RefCounted
## One worker settlement owns this context. Every stride is still resolved
## sequentially against the immediately updated living body positions.
## No context survives a world tick or command boundary.
const Resolver = preload("res://src/simulation/unit_body_resolver.gd")
const CELL := 64
var _ordered: Array[Dictionary] = []
var _by_id := {}
var _positions := {}
var _bins := {}
var _cells_by_id := {}
var _bounds: Rect2i
var _step: int
var _usable := true
# Kept for old diagnostic readers; a remote other/other overlap is no longer
# a global worker stop condition. Actual worker sweeps still test t=0 locally.
var _overlapping_start := false

func _init(bodies: Array[Dictionary], bounds: Rect2i, step: int) -> void:
	_bounds = bounds
	_step = maxi(0,step)
	_ordered = bodies
	_ordered.sort_custom(func(a: Dictionary,b: Dictionary)->bool: return str(a.id)<str(b.id))
	for body: Dictionary in _ordered:
		if _by_id.has(body.id): _usable = false
		_by_id[body.id] = body
		_positions[body.id] = body.position
		body.desired = body.position
		body.max_step = 0
		if not body.active: continue
		# Stationary non-static bodies are clamped by the general resolver even
		# with max_step=0. Preserve that unusual input through the old path.
		if int(body.radius)<0 or (not bool(body.get("static",false)) and not Resolver._is_inside(body.position,_bounds,int(body.radius))):
			_usable = false
	if not _usable: return
	for body: Dictionary in _ordered:
		if not body.active: continue
		var cells := _envelope_cells(body.position,int(body.radius),0)
		if cells.is_empty():
			_usable = false
			_bins.clear()
			return
		_cells_by_id[body.id] = cells
		for cell: Vector2i in cells:
			if not _bins.has(cell): _bins[cell] = {}
			_bins[cell][body.id] = body
	# Do not scan soldier/soldier or other remote pairs here. Worker movement
	# only needs its own current swept neighborhood, checked by resolve_move.
	# An overlap in a distant military fight must not freeze unrelated hauling.

func resolve_move(id: String, desired: Vector2i) -> Vector2i:
	var body: Dictionary = _by_id[id]
	var origin: Vector2i = body.position
	if not body.active or bool(body.get("static",false)): return origin
	body.desired = desired
	body.max_step = _step
	if not _usable:
		var resolved: Dictionary = Resolver.resolve(_ordered,_bounds,_step)
		var result: Vector2i = resolved[id]
		body.desired = origin
		body.max_step = 0
		_commit(body,result)
		return result
	var target := Resolver._clamp_to_arena(origin+Vector2i(
		clampi(desired.x-origin.x,-_step,_step),
		clampi(desired.y-origin.y,-_step,_step)),_bounds,int(body.radius))
	var nearby := _nearby(body)
	# Swept safety includes t=0: this worker still waits if its own origin is
	# overlapping a live neighbor. Unrelated neighbor/neighbor pairs are not
	# movement constraints on this worker. Keep exact original narrow phase.
	_positions[id] = target
	if not Resolver._is_safe(body,origin,target,nearby,_positions):
		# With only this body moving, every conflict ultimately tests this
		# identical ordered candidate set. Lexical priority only freezes the
		# immovable neighbor first; it cannot change the accepted worker stride.
		if not Resolver._try_safe_alternative(body,_ordered,_positions,_bounds,_step,{id:nearby}):
			_positions[id] = origin
	var result: Vector2i = _positions[id]
	body.desired = origin
	body.max_step = 0
	_commit(body,result)
	return result

func _nearby(body: Dictionary) -> Array[Dictionary]:
	var seen := {}
	var cells := _envelope_cells(body.position,int(body.radius),_step)
	# Radius-only preparation can fit while a wider movement envelope exceeds
	# the index budget. Keep every candidate instead of dropping collisions.
	if cells.is_empty(): return _ordered
	for cell: Vector2i in cells:
		for id: String in _bins.get(cell,{}):
			if id != body.id and Resolver._shares_layer(body,_by_id[id]): seen[id] = true
	var ids: Array = seen.keys()
	ids.sort()
	var result: Array[Dictionary] = []
	for id: String in ids: result.append(_by_id[id])
	return result

func _commit(body: Dictionary, position: Vector2i) -> void:
	if _usable and body.active:
		for cell: Vector2i in _cells_by_id[body.id]:
			_bins[cell].erase(body.id)
			if _bins[cell].is_empty(): _bins.erase(cell)
	body.position = position
	body.desired = position
	_positions[body.id] = position
	if _usable and body.active:
		var cells := _envelope_cells(position,int(body.radius),0)
		if cells.is_empty():
			# A large body can cross a cell boundary after a legal stride and
			# exceed the preparation budget. Future moves use the full scene.
			_usable = false
			_bins.clear()
			_cells_by_id.clear()
			return
		_cells_by_id[body.id] = cells
		for cell: Vector2i in cells:
			if not _bins.has(cell): _bins[cell] = {}
			_bins[cell][body.id] = body

func _envelope_cells(position: Vector2i, radius: int, movement: int) -> Array[Vector2i]:
	var x_min := floori(float(position.x-radius-movement)/CELL)
	var x_max := floori(float(position.x+radius+movement)/CELL)
	var y_min := floori(float(position.y-radius-movement)/CELL)
	var y_max := floori(float(position.y+radius+movement)/CELL)
	var cells: Array[Vector2i] = []
	if (x_max-x_min+1)*(y_max-y_min+1)>256: return cells
	for x: int in range(x_min,x_max+1):
		for y: int in range(y_min,y_max+1): cells.append(Vector2i(x,y))
	return cells
