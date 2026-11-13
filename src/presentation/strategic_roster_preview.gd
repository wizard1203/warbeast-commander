extends RefCounted
## All roster surfaces use the exact warband actor fitting/pixel path.
## This read-only helper creates no textures, nodes, commands or actor state.
const Warband = preload("res://src/presentation/strategic_warband_button.gd")
const MAX_PREVIEWS := 4

static func visuals_for(type: String, samples: Array, fallback: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	for sample: Dictionary in samples:
		if str(sample.get("unit_type", "worker" if type == "worker" else "")) != type: continue
		var identity := str(sample.get("hero_archetype", "COMMANDER")) if type == "hero" else type
		if seen.has(identity): continue
		seen[identity] = true
		# Retain visual identity only; animation/HP changes do not rebuild rows.
		var visual := {"unit_type":type, "side":str(sample.get("side", "PLAYER"))}
		for key: String in ["hero_archetype", "faction_id", "body_kind", "role"]:
			if sample.has(key): visual[key] = str(sample[key])
		result.append(visual)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("hero_archetype", "")) < str(b.get("hero_archetype", "")))
	if result.is_empty() and not fallback.is_empty():
		var visual := fallback.duplicate(true)
		visual["unit_type"] = type
		result.append(visual)
	return result

static func draw_group(canvas: Object, rect: Rect2, visuals: Array, heroic_2d: bool = true) -> Array[Dictionary]:
	var receipts: Array[Dictionary] = []
	var count := mini(visuals.size(), MAX_PREVIEWS)
	if count <= 0 or rect.size.x <= 0 or rect.size.y <= 0: return receipts
	var width := rect.size.x / count
	for index: int in range(count):
		var cell := Rect2(rect.position + Vector2(index * width, 0), Vector2(width, rect.size.y)).grow(-1)
		receipts.append(Warband.draw_portrait(canvas, cell, visuals[index], heroic_2d))
	return receipts
