extends RefCounted
## Exact synchronous preparation broad phase, not a cross-tick body cache.
## Full rows stay in Combat authority. This table owns only an ordered row
## view and center-cell membership while positions/liveness cannot change.
const CELL := 192
var _ordered: Array[Dictionary] = []
var _military: Array[Dictionary] = []
var _buckets: Dictionary = {}
var _grid_valid := true
var queries := 0
var candidates := 0

func _init(ordered: Array[Dictionary]) -> void:
	_ordered = ordered.duplicate()
	for index: int in range(_ordered.size()):
		var body: Dictionary = _ordered[index]
		if _is_military(body): _military.append(body)
		if typeof(body.get("position")) != TYPE_VECTOR2I:
			_grid_valid = false
			continue
		var point: Vector2i = body.position
		if absi(point.x)>32768 or absi(point.y)>32768:
			_grid_valid = false
			continue
		var key := Vector2i(floori(float(point.x)/CELL),floori(float(point.y)/CELL))
		if not _buckets.has(key): _buckets[key] = []
		_buckets[key].append(index)

func military_all() -> Array[Dictionary]:
	return _military.duplicate()

func radius_pool(point: Vector2i, radius: int, military_only: bool = false) -> Array[Dictionary]:
	queries += 1
	if not _grid_valid or radius<0 or radius>8192 or absi(point.x)>32768 or absi(point.y)>32768 or _ordered.size()<32:
		return _fallback(military_only)
	var low := Vector2i(floori(float(point.x-radius)/CELL),floori(float(point.y-radius)/CELL))
	var high := Vector2i(floori(float(point.x+radius)/CELL),floori(float(point.y+radius)/CELL))
	if (high.x-low.x+1)*(high.y-low.y+1)>=_ordered.size(): return _fallback(military_only)
	var indices: Array[int] = []
	for y: int in range(low.y,high.y+1):
		for x: int in range(low.x,high.x+1):
			for index: int in _buckets.get(Vector2i(x,y),[]): indices.append(index)
	# Query order must remain the exact authoritative ID order, not hash-cell
	# enumeration order. The callers retain their old exact radius predicate.
	indices.sort()
	var result: Array[Dictionary] = []
	for index: int in indices:
		var body: Dictionary = _ordered[index]
		if not military_only or _is_military(body): result.append(body)
	candidates += result.size()
	return result

func _fallback(military_only: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = _military.duplicate() if military_only else _ordered.duplicate()
	candidates += result.size()
	return result

static func _is_military(body: Dictionary) -> bool:
	return not body.is_empty() and int(body.get("hp",0))>0 and str(body.get("unit_type",""))!="worker" and not body.has("building_type") and "WORKER" not in body.get("tags",[]) and not str(body.get("id","")).is_empty()
