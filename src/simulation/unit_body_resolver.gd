extends RefCounted
## Deterministic, discrete body-volume resolution for all visible living units.
##
## Input bodies contain `id`, `position`, `desired`, `radius`, and `active`.
## Optional `movement_layer` (default GROUND) separates actual AIR bodies;
## optional `max_step` limits a specific unit below the global maximum.
## Optional `steering_goal` retains the full visible route waypoint when the
## requested `desired` stride is normalized; absent goals preserve legacy
## desired-goal ranking exactly. It never expands a body's bounded step.
## With a goal, recent `previous_position` only deprioritizes undoing the last
## physical stride; a reverse candidate remains legal if no other path is safe.
## Authored fixed obstacles set `static: true`: their overlapping circles form
## one solid union, while stopped units remain ordinary colliding bodies.
## The returned Dictionary maps every ID to its resolved Vector2i position.
## Inactive bodies retain their position but do not reserve space.


## M79 incremental conflict frontier. Query-local; malformed/dense cases keep
## the exact reference scan. This cap bounds only the additional pair records.
const MAX_CONFLICT_PAIRS_M79 := 8192
const NativeBackendM94 = preload("res://src/simulation/strategic_native_body_backend_m94.gd")

static func resolve(bodies: Array[Dictionary], bounds: Rect2i, max_step: int = 8) -> Dictionary:
	# One optional whole-array math call, not one callback per unit. Unsupported
	# platforms, packages and inputs retain the complete existing script path.
	var native: Dictionary = NativeBackendM94.try_resolve(bodies, bounds, max_step)
	if bool(native.get("accepted", false)):
		return native.positions
	return _resolve_script_m94(bodies, bounds, max_step)

static func _resolve_script_m94(bodies: Array[Dictionary], bounds: Rect2i, max_step: int = 8) -> Dictionary:
	# Keep all small/malformed paths on the exact existing implementation.
	# Equal textual IDs also include distinct Variant keys such as 1 and "1";
	# a changed resolved key could otherwise affect more than one pair owner.
	if bodies.size() < 48:
		return _resolve_reference_m79(bodies, bounds, max_step)
	var seen_ids := {}
	for body: Dictionary in bodies:
		var key := str(body["id"])
		if seen_ids.has(key) or int(body["radius"]) < 0:
			return _resolve_reference_m79(bodies, bounds, max_step)
		seen_ids[key] = true
	var ordered := bodies.duplicate()
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left["id"]) < str(right["id"])
	)
	var resolved := {}
	var step := maxi(0, max_step)
	for body: Dictionary in ordered:
		var old_position: Vector2i = body["position"]
		var wanted: Vector2i = body["desired"]
		var body_step := mini(step, maxi(0, int(body.get("max_step", step))))
		var target := old_position + Vector2i(
			clampi(wanted.x - old_position.x, -body_step, body_step),
			clampi(wanted.y - old_position.y, -body_step, body_step)
		)
		resolved[body["id"]] = _clamp_to_arena(target, bounds, body["radius"]) if body["active"] and not bool(body.get("static", false)) else old_position
	var neighbors := _candidate_neighbors(ordered, resolved, step)
	if neighbors.is_empty():
		return _resolve_reference_m79(bodies, bounds, max_step)
	# Sparse/no-contact calls already have a complete valid answer. Preserve
	# their single existing scan instead of allocating the incremental graph.
	if _first_conflict(ordered, resolved, neighbors).is_empty():
		return resolved
	# Rank is exactly the former nested _first_conflict iteration order.
	# The pair graph is immutable within this resolver invocation.
	var pairs: Array[Dictionary] = []
	var incident := {}
	for body: Dictionary in ordered:
		if not body["active"]:
			continue
		for other: Dictionary in neighbors.get(body["id"], []):
			if str(other["id"]) <= str(body["id"]) or not _shares_layer(body, other):
				continue
			var rank := pairs.size()
			# Broad-phase neighbors already exist in the unchanged resolver. Cap
			# this optimization's additional records, incident lists and heap.
			# The exact original remains authoritative for pathological density.
			if rank >= MAX_CONFLICT_PAIRS_M79:
				pairs.clear()
				incident.clear()
				neighbors.clear()
				ordered.clear()
				resolved.clear()
				return _resolve_reference_m79(bodies, bounds, max_step)
			pairs.append({"left": body, "right": other})
			if not incident.has(body["id"]): incident[body["id"]] = []
			if not incident.has(other["id"]): incident[other["id"]] = []
			(incident[body["id"]] as Array).append(rank)
			(incident[other["id"]] as Array).append(rank)
	var heap: Array[int] = []
	var locations: Array[int] = []
	locations.resize(pairs.size())
	locations.fill(-1)
	for rank: int in range(pairs.size()):
		if _pair_overlaps(pairs[rank], resolved): _heap_add(rank, heap, locations)
	var frozen := {}
	for _attempt: int in range(maxi(1, ordered.size() * ordered.size() * 2)):
		if heap.is_empty():
			return resolved
		var pair: Dictionary = pairs[heap[0]]
		var earlier: Dictionary = pair.left
		var later: Dictionary = pair.right
		if not frozen.has(later["id"]):
			if _try_safe_alternative(later, ordered, resolved, bounds, mini(step, maxi(0, int(later.get("max_step", step)))), neighbors):
				_update_incident(later["id"], pairs, incident, resolved, heap, locations)
				continue
			resolved[later["id"]] = later["position"]
			frozen[later["id"]] = true
			_update_incident(later["id"], pairs, incident, resolved, heap, locations)
			continue
		if not frozen.has(earlier["id"]):
			if _try_safe_alternative(earlier, ordered, resolved, bounds, mini(step, maxi(0, int(earlier.get("max_step", step)))), neighbors):
				_update_incident(earlier["id"], pairs, incident, resolved, heap, locations)
				continue
			resolved[earlier["id"]] = earlier["position"]
			frozen[earlier["id"]] = true
			_update_incident(earlier["id"], pairs, incident, resolved, heap, locations)
			continue
		break
	# Retain the original final verification, including the malformed initial
	# overlap all-wait behavior. A heap invariant cannot waive a physical check.
	if not _all_paths_safe(ordered, resolved, neighbors):
		for body: Dictionary in ordered:
			resolved[body["id"]] = body["position"]
	return resolved

static func _pair_overlaps(pair: Dictionary, resolved: Dictionary) -> bool:
	var first: Dictionary = pair.left
	var second: Dictionary = pair.right
	return _segments_overlap(first["position"], resolved[first["id"]], second["position"], resolved[second["id"]], first["radius"] + second["radius"])

static func _update_incident(id: Variant, pairs: Array[Dictionary], incident: Dictionary, resolved: Dictionary, heap: Array[int], locations: Array[int]) -> void:
	for rank: int in incident.get(id, []):
		if _pair_overlaps(pairs[rank], resolved): _heap_add(rank, heap, locations)
		else: _heap_remove(rank, heap, locations)

static func _heap_add(rank: int, heap: Array[int], locations: Array[int]) -> void:
	if locations[rank] >= 0: return
	var index := heap.size()
	heap.append(rank)
	locations[rank] = index
	while index > 0:
		var parent := (index - 1) / 2
		if heap[parent] <= rank: break
		var parent_rank: int = heap[parent]
		heap[index] = parent_rank
		locations[parent_rank] = index
		index = parent
	heap[index] = rank
	locations[rank] = index

static func _heap_remove(rank: int, heap: Array[int], locations: Array[int]) -> void:
	var index: int = locations[rank]
	if index < 0: return
	var last: int = heap.pop_back()
	locations[rank] = -1
	if index == heap.size(): return
	heap[index] = last
	locations[last] = index
	if index > 0 and last < heap[(index - 1) / 2]:
		while index > 0:
			var parent := (index - 1) / 2
			if heap[parent] <= last: break
			var parent_rank: int = heap[parent]
			heap[index] = parent_rank
			locations[parent_rank] = index
			index = parent
	else:
		while index * 2 + 1 < heap.size():
			var child := index * 2 + 1
			if child + 1 < heap.size() and heap[child + 1] < heap[child]: child += 1
			if last <= heap[child]: break
			var child_rank: int = heap[child]
			heap[index] = child_rank
			locations[child_rank] = index
			index = child
	heap[index] = last
	locations[last] = index


static func _resolve_reference_m79(bodies: Array[Dictionary], bounds: Rect2i, max_step: int = 8) -> Dictionary:
	var ordered := bodies.duplicate()
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return str(left["id"]) < str(right["id"])
	)
	var resolved := {}
	var step := maxi(0, max_step)
	for body: Dictionary in ordered:
		var old_position: Vector2i = body["position"]
		var wanted: Vector2i = body["desired"]
		var body_step := mini(step, maxi(0, int(body.get("max_step", step))))
		var target := old_position + Vector2i(
			clampi(wanted.x - old_position.x, -body_step, body_step),
			clampi(wanted.y - old_position.y, -body_step, body_step)
		)
		resolved[body["id"]] = _clamp_to_arena(target, bounds, body["radius"]) if body["active"] and not bool(body.get("static",false)) else old_position
	# Candidate neighborhoods cover every bounded alternative, not only the
	# current intent. They can therefore be reused after a conflicting body
	# sidesteps or waits without changing the lexically first conflict.
	var neighbors := _candidate_neighbors(ordered, resolved, step) if ordered.size() >= 48 else {}
	var frozen := {}
	# Starting with all intended paths preserves safe coordinated movement.
	# Resolve only actual swept-path conflicts, giving the lexically earlier ID
	# priority. A forced wait is permanent for this tick, ensuring termination.
	for _attempt: int in range(maxi(1, ordered.size() * ordered.size() * 2)):
		var conflicting_pair := _first_conflict(ordered, resolved, neighbors)
		if conflicting_pair.is_empty():
			return resolved
		var earlier: Dictionary = conflicting_pair[0]
		var later: Dictionary = conflicting_pair[1]
		if not frozen.has(later["id"]):
			if _try_safe_alternative(later, ordered, resolved, bounds, mini(step, maxi(0, int(later.get("max_step", step)))), neighbors):
				continue
			resolved[later["id"]] = later["position"]
			frozen[later["id"]] = true
			continue
		if not frozen.has(earlier["id"]):
			if _try_safe_alternative(earlier, ordered, resolved, bounds, mini(step, maxi(0, int(earlier.get("max_step", step)))), neighbors):
				continue
			resolved[earlier["id"]] = earlier["position"]
			frozen[earlier["id"]] = true
			continue
		break
	# A malformed initially overlapping input has no collision-free solution;
	# otherwise a bounded all-wait fallback maintains the swept-space invariant.
	if not _all_paths_safe(ordered, resolved, neighbors):
		for body: Dictionary in ordered:
			resolved[body["id"]] = body["position"]
	return resolved


static func _candidate_neighbors(ordered: Array[Dictionary], resolved: Dictionary, step: int) -> Dictionary:
	const CELL := 64
	var bins := {}
	var cells_by_id := {}
	var duplicate_ids := false
	for index: int in range(ordered.size()):
		var body: Dictionary = ordered[index]
		if not body["active"]:
			continue
		# Preserve the reference behavior for unusual negative radius fixtures.
		if int(body["radius"]) < 0:
			return {}
		var origin: Vector2i = body["position"]
		var initial: Vector2i = resolved[body["id"]]
		var movement := mini(step, maxi(0, int(body.get("max_step", step))))
		var radius := int(body["radius"])
		# Initial boundary clamping may be farther than a step for malformed
		# out-of-arena input. Include that full path as well as every sidestep.
		var x_min := floori(float(mini(origin.x - movement, initial.x) - radius) / CELL)
		var x_max := floori(float(maxi(origin.x + movement, initial.x) + radius) / CELL)
		var y_min := floori(float(mini(origin.y - movement, initial.y) - radius) / CELL)
		var y_max := floori(float(maxi(origin.y + movement, initial.y) + radius) / CELL)
		# Very large malformed envelopes use the original bounded resolver;
		# broad-phase memory cannot grow with arbitrary coordinate magnitudes.
		if (x_max - x_min + 1) * (y_max - y_min + 1) > 256:
			return {}
		var cells: Array[Vector2i] = []
		for x: int in range(x_min, x_max + 1):
			for y: int in range(y_min, y_max + 1):
				var key := Vector2i(x, y)
				cells.append(key)
				if not bins.has(key): bins[key] = []
				(bins[key] as Array).append(index)
		if cells_by_id.has(body["id"]): duplicate_ids = true
		cells_by_id[body["id"]] = cells
	var result := {}
	if not duplicate_ids:
		# Static circles form one union: they never share a collision layer
		# with each other. Query each dynamic envelope only, then register
		# every eligible pair in both directions. This preserves the exact
		# original candidate set for static-first lexical conflict ordering.
		var seen_by_index := {}
		for index: int in range(ordered.size()):
			var body: Dictionary = ordered[index]
			if not body["active"] or bool(body.get("static",false)):
				continue
			var seen: Dictionary = seen_by_index.get(index,{})
			for key: Vector2i in cells_by_id[body["id"]]:
				for other_index: int in bins[key]:
					if other_index == index or seen.has(other_index): continue
					var other: Dictionary = ordered[other_index]
					if not _shares_layer(body,other): continue
					seen[other_index] = true
					if not seen_by_index.has(other_index): seen_by_index[other_index] = {}
					(seen_by_index[other_index] as Dictionary)[index] = true
			seen_by_index[index] = seen
		for index: int in range(ordered.size()):
			var body: Dictionary = ordered[index]
			if not body["active"]: continue
			var indices: Array = (seen_by_index.get(index,{}) as Dictionary).keys()
			indices.sort()
			var nearby: Array[Dictionary] = []
			for other_index: int in indices: nearby.append(ordered[other_index])
			result[body["id"]] = nearby
		return result
	# Duplicate IDs are malformed, but historically cells_by_id and the final
	# result used last-writer semantics. Keep that exact reference path rather
	# than inventing an index-based interpretation for unusual input fixtures.
	for body: Dictionary in ordered:
		if not body["active"]:
			continue
		var seen := {}
		for key: Vector2i in cells_by_id[body["id"]]:
			for index: int in bins[key]:
				if ordered[index]["id"] != body["id"] and _shares_layer(body,ordered[index]): seen[index] = true
		var indices: Array = seen.keys()
		indices.sort()
		var nearby: Array[Dictionary] = []
		for index: int in indices: nearby.append(ordered[index])
		result[body["id"]] = nearby
	return result


static func _candidates(old_position: Vector2i, preferred: Vector2i, bounds: Rect2i, radius: int, step: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var seen := {}
	_append_candidate(positions, seen, preferred, old_position, bounds, radius, step)
	var delta := preferred - old_position
	_append_candidate(positions, seen, old_position + Vector2i(delta.x, 0), old_position, bounds, radius, step)
	_append_candidate(positions, seen, old_position + Vector2i(0, delta.y), old_position, bounds, radius, step)
	_append_candidate(positions, seen, old_position + Vector2i(delta.x / 2, delta.y / 2), old_position, bounds, radius, step)

	# Fixed compass order gives replayable sidesteps without a physics scheduler.
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(1, 1),
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(-1, 1),
	]
	directions.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		var left_progress := delta.x * left.x + delta.y * left.y
		var right_progress := delta.x * right.x + delta.y * right.y
		if left_progress != right_progress:
			return left_progress > right_progress
		return left.y < right.y if left.x == right.x else left.x < right.x
	)
	for distance: int in [step, maxi(1, step / 2), 1]:
		for direction: Vector2i in directions:
			_append_candidate(positions, seen, old_position + direction * distance, old_position, bounds, radius, step)
	_append_candidate(positions, seen, old_position, old_position, bounds, radius, step, true)
	return positions


static func _append_candidate(positions: Array[Vector2i], seen: Dictionary, candidate: Vector2i, old_position: Vector2i, bounds: Rect2i, radius: int, step: int, allow_wait: bool = false) -> void:
	# A zero axis (or rounded half-step) is not an alternative movement. Keep
	# waiting last so a genuine safe sidestep can get around a settled ally.
	if seen.has(candidate) or (candidate == old_position and not allow_wait):
		return
	var delta := candidate - old_position
	if absi(delta.x) > step or absi(delta.y) > step:
		return
	if not _is_inside(candidate, bounds, radius):
		return
	seen[candidate] = true
	positions.append(candidate)


static func _try_safe_alternative(body: Dictionary, ordered: Array[Dictionary], resolved: Dictionary, bounds: Rect2i, step: int, neighbors: Dictionary = {}) -> bool:
	var old_position: Vector2i = body["position"]
	var preferred: Vector2i = resolved[body["id"]]
	var goal: Vector2i = body.get("steering_goal",body["desired"])
	var candidates := _candidates(old_position, preferred, bounds, body["radius"], step)
	# Fixed axis order can undo the previous sidestep forever. Rank real
	# alternatives in full/partial-step bands against the full destination,
	# not just this tick's clamped step. Tiny contact-edge shuffles otherwise
	# oscillate without clearing the blocker. Waiting stays last even when a
	# necessary first lateral step temporarily increases goal distance.
	candidates.sort_custom(func(left: Vector2i, right: Vector2i) -> bool:
		if left == old_position or right == old_position:
			return right == old_position and left != old_position
		var previous: Vector2i=body.get("previous_position",old_position)
		if body.has("steering_goal") and previous!=old_position and (left==previous)!=(right==previous):return right==previous
		var left_step := maxi(absi(left.x - old_position.x), absi(left.y - old_position.y))
		var right_step := maxi(absi(right.x - old_position.x), absi(right.y - old_position.y))
		if left_step != right_step:
			return left_step > right_step
		var left_remaining := _length_squared(goal - left)
		var right_remaining := _length_squared(goal - right)
		if left_remaining != right_remaining:
			return left_remaining < right_remaining
		return left.y < right.y if left.x == right.x else left.x < right.x
	)
	var candidates_to_check: Array[Dictionary] = neighbors.get(body["id"], ordered)
	for candidate: Vector2i in candidates:
		if _is_safe(body, old_position, candidate, candidates_to_check, resolved):
			resolved[body["id"]] = candidate
			return true
	return false


static func _is_safe(body: Dictionary, old_position: Vector2i, candidate: Vector2i, ordered: Array[Dictionary], resolved: Dictionary) -> bool:
	for other: Dictionary in ordered:
		if other["id"] == body["id"] or not other["active"] or not _shares_layer(body,other):
			continue
		var other_old: Vector2i = other["position"]
		var other_new: Vector2i = resolved[other["id"]]
		var separation: int = body["radius"] + other["radius"]
		if _segments_overlap(old_position, candidate, other_old, other_new, separation):
			return false
	return true


static func _first_conflict(ordered: Array[Dictionary], resolved: Dictionary, neighbors: Dictionary = {}) -> Array[Dictionary]:
	if not neighbors.is_empty():
		for body: Dictionary in ordered:
			if not body["active"]: continue
			for other: Dictionary in neighbors.get(body["id"], []):
				if str(other["id"]) <= str(body["id"]) or not _shares_layer(body,other): continue
				if _segments_overlap(body["position"], resolved[body["id"]], other["position"], resolved[other["id"]], body["radius"] + other["radius"]):
					return [body, other]
		return []
	for index: int in range(ordered.size()):
		var body: Dictionary = ordered[index]
		if not body["active"]:
			continue
		for other_index: int in range(index + 1, ordered.size()):
			var other: Dictionary = ordered[other_index]
			if not other["active"] or not _shares_layer(body,other):
				continue
			if _segments_overlap(body["position"], resolved[body["id"]], other["position"], resolved[other["id"]], body["radius"] + other["radius"]):
				return [body, other]
	return []


static func _all_paths_safe(ordered: Array[Dictionary], resolved: Dictionary, neighbors: Dictionary = {}) -> bool:
	return _first_conflict(ordered, resolved, neighbors).is_empty()


static func _shares_layer(first: Dictionary, second: Dictionary) -> bool:
	# Authored obstacle circles may overlap to form one river/tree/rock union.
	# They never move or collide with each other, but still block real bodies.
	if bool(first.get("static",false)) and bool(second.get("static",false)):return false
	return first.get("movement_layer","GROUND")==second.get("movement_layer","GROUND")


static func _segments_overlap(first_old: Vector2i, first_new: Vector2i, second_old: Vector2i, second_new: Vector2i, separation: int) -> bool:
	# A conservative swept AABB test: every point on either linear path is
	# inside its endpoint bounds. A full-radius axis gap cannot intersect.
	# Touching at exactly the required separation is legal in the narrow phase.
	if separation >= 0 and (maxi(first_old.x, first_new.x) + separation <= mini(second_old.x, second_new.x) or maxi(second_old.x, second_new.x) + separation <= mini(first_old.x, first_new.x)):
		return false
	if separation >= 0 and (maxi(first_old.y, first_new.y) + separation <= mini(second_old.y, second_new.y) or maxi(second_old.y, second_new.y) + separation <= mini(first_old.y, first_new.y)):
		return false
	# Minimize |relative_start + t * relative_velocity|^2 over t in [0, 1].
	# Integer comparisons avoid floating-point replay drift.
	var relative_start := first_old - second_old
	var relative_velocity := (first_new - first_old) - (second_new - second_old)
	var velocity_squared := _length_squared(relative_velocity)
	var radius_squared := separation * separation
	if velocity_squared == 0:
		return _length_squared(relative_start) < radius_squared
	var start_dot_velocity: int = relative_start.x * relative_velocity.x + relative_start.y * relative_velocity.y
	if start_dot_velocity >= 0:
		return _length_squared(relative_start) < radius_squared
	if -start_dot_velocity >= velocity_squared:
		return _length_squared(relative_start + relative_velocity) < radius_squared
	return _length_squared(relative_start) * velocity_squared - start_dot_velocity * start_dot_velocity < radius_squared * velocity_squared


static func _length_squared(value: Vector2i) -> int:
	return value.x * value.x + value.y * value.y


static func _clamp_to_arena(position: Vector2i, bounds: Rect2i, radius: int) -> Vector2i:
	return Vector2i(
		clampi(position.x, bounds.position.x + radius, bounds.end.x - radius),
		clampi(position.y, bounds.position.y + radius, bounds.end.y - radius)
	)


static func _is_inside(position: Vector2i, bounds: Rect2i, radius: int) -> bool:
	return (
		position.x >= bounds.position.x + radius
		and position.x <= bounds.end.x - radius
		and position.y >= bounds.position.y + radius
		and position.y <= bounds.end.y - radius
	)
