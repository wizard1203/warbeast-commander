extends "res://src/simulation/strategic_action_context_m94.gd"
## M99 fixed-position action scope; released by the existing M94 owner.
## Cache only exact geometry; live HP and side remain per-query predicates.
const MAX_ENTRIES_M99 := 256
const MAX_REFS_M99 := 16384
var _neighbors_m99: Dictionary = {}
var _retained_refs_m99 := 0

func _init(bodies: Array[Dictionary]) -> void:
	super(bodies)

func engaged_m99(body: Dictionary) -> bool:
	var reach := maxi(180, int(body.attack_range) + 30)
	if not _valid or reach > 4096 or typeof(body.get("position")) != TYPE_VECTOR2I:
		return _fallback_engaged_m99(body, reach)
	var point: Vector2i = body.position
	if absi(point.x) > 32768 or absi(point.y) > 32768:
		return _fallback_engaged_m99(body, reach)
	var low := Vector2i(floori(float(point.x - reach) / CELL), floori(float(point.y - reach) / CELL))
	var high := Vector2i(floori(float(point.x + reach) / CELL), floori(float(point.y + reach) / CELL))
	if (high.x - low.x + 1) * (high.y - low.y + 1) >= _ordered.size():
		return _fallback_engaged_m99(body, reach)
	var key := Vector3i(point.x, point.y, reach)
	var neighbors: Array[Dictionary] = []
	if _neighbors_m99.has(key):
		neighbors = _neighbors_m99[key]
	else:
		if _neighbors_m99.size() >= MAX_ENTRIES_M99 or _retained_refs_m99 >= MAX_REFS_M99:
			return _uncached_grid_engaged_m99(body, reach, low, high)
		# Exactly the original M84 y/x/bucket order, including same-side and
		# currently dead bodies. No mutable eligibility enters the cache.
		for y: int in range(low.y, high.y + 1):
			for x: int in range(low.x, high.x + 1):
				for other: Dictionary in _buckets.get(Vector2i(x, y), []):
					if (body.position as Vector2i).distance_squared_to(other.position) <= reach * reach:
						neighbors.append(other)
		if _neighbors_m99.size() < MAX_ENTRIES_M99 and _retained_refs_m99 + neighbors.size() <= MAX_REFS_M99:
			_neighbors_m99[key] = neighbors
			_retained_refs_m99 += neighbors.size()
	for enemy: Dictionary in neighbors:
		if enemy.side != body.side and int(enemy.hp) > 0:
			return true
	return false

func _uncached_grid_engaged_m99(body: Dictionary, reach: int, low: Vector2i, high: Vector2i) -> bool:
	for y: int in range(low.y, high.y + 1):
		for x: int in range(low.x, high.x + 1):
			for enemy: Dictionary in _buckets.get(Vector2i(x, y), []):
				if enemy.side != body.side and int(enemy.hp) > 0 and (body.position as Vector2i).distance_squared_to(enemy.position) <= reach * reach:
					return true
	return false

func _fallback_engaged_m99(body: Dictionary, reach: int) -> bool:
	for enemy: Dictionary in _ordered:
		if enemy.side != body.side and int(enemy.hp) > 0:
			if (body.position as Vector2i).distance_squared_to(enemy.position) <= reach * reach:
				return true
	return false

func diagnostics_m99() -> Dictionary:
	return {"entries": _neighbors_m99.size(), "retained_refs": _retained_refs_m99}
