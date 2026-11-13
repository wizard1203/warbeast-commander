extends RefCounted
## One synchronous post-movement action batch. Only centers and their original
## order are indexed; every qualification still reads the current live body.
## Never retains injured/engaged/MP/buff/DPS answers or survives a body write.
const CELL := 192
var _ordered: Array[Dictionary] = []
var _buckets: Dictionary = {}
var _indices: Dictionary = {}
var _valid := true

func _init(bodies: Array[Dictionary]) -> void:
	_ordered = bodies.duplicate(false)
	# Exactly the existing Support grid's supported domain and size threshold.
	if bodies.size()<64:
		_valid=false
		return
	for index: int in range(bodies.size()):
		var body: Dictionary=bodies[index]
		if typeof(body.get("position"))!=TYPE_VECTOR2I:
			_valid=false
			break
		var point: Vector2i=body.position
		if absi(point.x)>32768 or absi(point.y)>32768:
			_valid=false
			break
		var key:=Vector2i(floori(float(point.x)/CELL),floori(float(point.y)/CELL))
		if not _buckets.has(key):
			_buckets[key]=[]
			_indices[key]=[]
		_buckets[key].append(body)
		_indices[key].append(index)
	if not _valid:
		_buckets.clear()
		_indices.clear()

func engagement_grid() -> Dictionary:
	# Internal Support's unchanged _engaged_m84 reads these body references.
	# Its current-HP/range predicates and wide/unsupported query fallbacks stay.
	return {"buckets":_buckets} if _valid else {}

func radius_pool(point: Vector2i, radius: int) -> Array[Dictionary]:
	if not _valid or radius<0 or radius>4096 or absi(point.x)>32768 or absi(point.y)>32768:
		return _ordered.duplicate(false)
	var low:=Vector2i(floori(float(point.x-radius)/CELL),floori(float(point.y-radius)/CELL))
	var high:=Vector2i(floori(float(point.x+radius)/CELL),floori(float(point.y+radius)/CELL))
	if (high.x-low.x+1)*(high.y-low.y+1)>=_ordered.size():
		return _ordered.duplicate(false)
	var indices: Array[int]=[]
	for y: int in range(low.y,high.y+1):
		for x: int in range(low.x,high.x+1):
			for index: int in _indices.get(Vector2i(x,y),[]):indices.append(index)
	# Radius is only a conservative broad phase. Caller retains its original
	# exact predicate (including the original Vector2i distance arithmetic).
	indices.sort()
	var result: Array[Dictionary]=[]
	for index: int in indices:result.append(_ordered[index])
	return result
