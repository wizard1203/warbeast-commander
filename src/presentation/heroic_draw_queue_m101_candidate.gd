extends RefCounted
## Explicit M101 experiment, not used by the default Canvas. Own only wrapper
## dictionaries and scalar scratch. Every prepare reads the full live input;
## there is no visible-object, tick, observation or previous-order cache.
const MAX_RETAINED_ROWS := 4096

var _pool: Array[Dictionary] = []
var _rows: Array[Dictionary] = []
var _ordered: Array[Dictionary] = []
var _indices: Array[int] = []
var _ys := PackedFloat64Array()
var _ids := PackedStringArray()
var _active := false
var _fast_keys := true
var _work := {"scopes":0,"objects":0,"wrappers_created":0,"wrappers_reused":0,"key_reads":0,"sort_comparisons":0,"fallbacks":0,"nested_fallbacks":0}


func prepare(snapshot: Dictionary, decorations: Array) -> Array[Dictionary]:
	# A nested consumer must not rewrite the outer scope's borrowed rows.
	if _active:
		_work.nested_fallbacks += 1
		return _original(snapshot, decorations)
	_active = true
	_fast_keys = true
	_rows.clear()
	_ordered.clear()
	_indices.clear()
	_ys.clear()
	_ids.clear()
	_work.scopes += 1
	for terrain: Dictionary in snapshot.get("terrain", []):
		if terrain.get("kind") not in ["LAKE", "RIVER"]: _append("terrain", terrain)
	for site: Dictionary in snapshot.get("sites", []):
		if site.get("kind") == "VILLAGE": _append("site", site)
	for value: Dictionary in snapshot.get("resource_sources", []): _append("resource", value)
	for value: Dictionary in snapshot.get("buildings", []): _append("building", value)
	for value: Dictionary in snapshot.get("neutral_camps", []): _append("camp", value)
	for value: Dictionary in snapshot.get("neutral_loot", []): _append("loot", value)
	for decoration: Dictionary in decorations:
		if str(decoration.get("layer", "")) == "prop": _append("decoration", decoration)
	for collection: String in ["workers", "soldiers"]:
		for value: Dictionary in snapshot.get(collection, []): _append("unit", value)
	if _fast_keys:
		# Sort the COMPLETE original flattening, with the same engine algorithm
		# and comparator relation. Do not impose stability or add an index tie.
		_indices.sort_custom(_less)
		for index: int in _indices: _ordered.append(_rows[index])
	else:
		_work.fallbacks += 1
		_rows.sort_custom(_original_less)
		_ordered.assign(_rows)
	_work.objects += _rows.size()
	return _ordered


func release(rows: Array[Dictionary]) -> void:
	# Nested fallback rows belong to that caller, not this scope. Clearing the
	# real borrowed array also makes accidental post-scope use visibly invalid.
	if not _active or not is_same(rows, _ordered): return
	for row: Dictionary in _rows: row["value"] = null
	_rows.clear()
	_ordered.clear()
	_indices.clear()
	_ys.clear()
	_ids.clear()
	_active = false


func diagnostics() -> Dictionary:
	var result := _work.duplicate(true)
	result["active"] = _active
	result["retained_rows"] = _pool.size()
	result["retained_values"] = 0
	for row: Dictionary in _pool:
		if row.value != null: result.retained_values += 1
	return result


func _append(kind: String, value: Dictionary) -> void:
	var index := _rows.size()
	var row: Dictionary
	if index < _pool.size():
		row = _pool[index]
		row["kind"] = kind
		row["value"] = value
		_work.wrappers_reused += 1
	else:
		# Original public wrapper shape and key insertion order, not a new
		# metadata-rich replacement object. Never alter the observed value.
		row = {"kind":kind, "value":value}
		if index < MAX_RETAINED_ROWS: _pool.append(row)
		_work.wrappers_created += 1
	_rows.append(row)
	_indices.append(index)
	# Unknown converters can have side effects. Only precompute canonical
	# scalar keys; defer every unsupported observation to the original sort.
	var position: Variant = value.get("position", Vector2.ZERO)
	var id: Variant = value.get("id", "")
	var supported_position := typeof(position) in [TYPE_VECTOR2, TYPE_VECTOR2I]
	var supported_id := typeof(id) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME]
	if not supported_position or not supported_id:
		_fast_keys = false
		_ys.append(0.0)
		_ids.append("")
		return
	var y := Vector2(position).y
	if is_nan(y):
		# NaN is not a strict weak ordering. Run the exact original comparison
		# and sort on original rows instead of manufacturing a total order.
		_fast_keys = false
	_ys.append(y)
	_ids.append(str(id))
	_work.key_reads += 1


func _less(a: int, b: int) -> bool:
	_work.sort_comparisons += 1
	return _ids[a] < _ids[b] if _ys[a] == _ys[b] else _ys[a] < _ys[b]


static func _original_less(a: Dictionary, b: Dictionary) -> bool:
	var ap := Vector2(a.value.get("position", Vector2.ZERO))
	var bp := Vector2(b.value.get("position", Vector2.ZERO))
	return str(a.value.get("id", "")) < str(b.value.get("id", "")) if ap.y == bp.y else ap.y < bp.y


static func _original(snapshot: Dictionary, decorations: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for terrain: Dictionary in snapshot.get("terrain", []):
		if terrain.get("kind") not in ["LAKE", "RIVER"]: rows.append({"kind":"terrain", "value":terrain})
	for site: Dictionary in snapshot.get("sites", []):
		if site.get("kind") == "VILLAGE": rows.append({"kind":"site", "value":site})
	for value: Dictionary in snapshot.get("resource_sources", []): rows.append({"kind":"resource", "value":value})
	for value: Dictionary in snapshot.get("buildings", []): rows.append({"kind":"building", "value":value})
	for value: Dictionary in snapshot.get("neutral_camps", []): rows.append({"kind":"camp", "value":value})
	for value: Dictionary in snapshot.get("neutral_loot", []): rows.append({"kind":"loot", "value":value})
	for decoration: Dictionary in decorations:
		if str(decoration.get("layer", "")) == "prop": rows.append({"kind":"decoration", "value":decoration})
	for collection: String in ["workers", "soldiers"]:
		for value: Dictionary in snapshot.get(collection, []): rows.append({"kind":"unit", "value":value})
	rows.sort_custom(_original_less)
	return rows
