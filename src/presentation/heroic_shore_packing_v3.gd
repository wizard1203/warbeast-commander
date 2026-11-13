extends RefCounted
## Presentation-only packing over already-safe shoreline candidates. Never
## relaxes terrain/road/pad clearance, changes a lake, or becomes authority.
## The caller owns _clear, existing-entry separation and the final 8 quota.
const VERSION := "outposts-v3-shore-min-conflict/r1"
const MAX_CANDIDATES := 512
const MAX_TARGET := 16
const ANGLE_SAMPLES := 128
const ROTATIONS := 32
const ROTATION_STRIDE := 7

static func select(candidates: Array[Dictionary], target: int, separation: float = 96.0) -> Array[Dictionary]:
	var empty: Array[Dictionary] = []
	if target <= 0: return empty
	# Refuse invalid/unbounded requests rather than silently shrinking their
	# goal or truncating away the only usable shore. The caller reports a gap.
	if candidates.size() > MAX_CANDIDATES or target > MAX_TARGET or not is_finite(separation) or separation <= 0.0:
		push_warning("V3 shore packing request outside finite presentation budget")
		return empty
	if candidates.is_empty(): return empty
	var rows: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		var raw: Variant = candidate.get("position")
		if typeof(raw) not in [TYPE_VECTOR2, TYPE_VECTOR2I] or not Vector2(raw).is_finite():
			push_warning("V3 shore packing requires finite candidate positions")
			return empty
		var id: String = str(candidate.get("id", ""))
		var parts: PackedStringArray = id.split(":")
		var fallback_angle: int = 0
		var fallback_ring: int = 0
		if parts.size() >= 2 and parts[-1].is_valid_int() and parts[-2].is_valid_int():
			fallback_angle = int(parts[-1])
			fallback_ring = int(parts[-2])
		rows.append({"candidate":candidate, "position":Vector2(raw), "id":id,
			"angle":posmod(int(candidate.get("shore_angle_index", fallback_angle)), ANGLE_SAMPLES),
			"ring":int(candidate.get("shore_ring", fallback_ring)), "degree":0})
	var count: int = rows.size()
	# Dense byte adjacency has an explicit 512^2 = 262144-byte ceiling.
	# Static conflict degrees are calculated once, NOT dynamically rescored
	# after every accepted point and NOT based on random/global RNG state.
	var conflicts: PackedByteArray = PackedByteArray()
	conflicts.resize(count * count)
	conflicts.fill(0)
	var distance_squared: float = separation * separation
	for first: int in range(count):
		for second: int in range(first + 1, count):
			if (rows[first].position as Vector2).distance_squared_to(rows[second].position) >= distance_squared: continue
			conflicts[first * count + second] = 1
			conflicts[second * count + first] = 1
			rows[first].degree = int(rows[first].degree) + 1
			rows[second].degree = int(rows[second].degree) + 1
	var best: Array[int] = []
	for rotation: int in range(ROTATIONS):
		var order: Array[int] = []
		for index: int in range(count): order.append(index)
		order.sort_custom(func(first: int, second: int) -> bool:
			var a: Dictionary = rows[first]
			var b: Dictionary = rows[second]
			if int(a.degree) != int(b.degree): return int(a.degree) < int(b.degree)
			var angle_a: int = posmod(int(a.angle) + ROTATION_STRIDE * rotation, ANGLE_SAMPLES)
			var angle_b: int = posmod(int(b.angle) + ROTATION_STRIDE * rotation, ANGLE_SAMPLES)
			if angle_a != angle_b: return angle_a < angle_b
			if int(a.ring) != int(b.ring): return int(a.ring) < int(b.ring)
			if str(a.id) != str(b.id): return str(a.id) < str(b.id)
			if a.position.y != b.position.y: return a.position.y < b.position.y
			return a.position.x < b.position.x)
		var chosen: Array[int] = []
		for index: int in order:
			var free: bool = true
			for accepted: int in chosen:
				if conflicts[index * count + accepted] != 0:
					free = false
					break
			if not free: continue
			chosen.append(index)
			if chosen.size() >= target: break
		if chosen.size() > best.size(): best = chosen
		if best.size() >= target: break
	var result: Array[Dictionary] = []
	for index: int in best: result.append((rows[index].candidate as Dictionary).duplicate(true))
	return result
