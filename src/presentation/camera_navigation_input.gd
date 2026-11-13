class_name CameraNavigationInput
extends RefCounted
## Presentation-only held-key/edge policy. The caller supplies current physical
## input and GUI/window guards every frame; this module never retains a key,
## queries a window, advances time, selects an entity or submits a command.

const SPEED_PIXELS_PER_SECOND := 560.0
const EDGE_BAND_PIXELS := 12.0


func get_direction(keys: Vector2, pointer: Vector2, screen_rect: Rect2, battle_rect: Rect2, context: Dictionary = {}) -> Vector2:
	# Missing integration guards must not make a newly constructed view scroll.
	if not bool(context.get("window_focused", false)) or bool(context.get("blocked", true)) or bool(context.get("dragging", true)):
		return Vector2.ZERO
	# Arrow input has priority over hover. This both avoids double speed and
	# allows arrows to work while the pointer rests on an ordinary HUD button.
	if not bool(context.get("keyboard_blocked", true)) and keys.is_finite() and not keys.is_zero_approx():
		return keys.normalized()
	if not bool(context.get("pointer_inside_window", false)) or bool(context.get("pointer_blocked", true)):
		return Vector2.ZERO
	if not pointer.is_finite() or not _valid_rect(screen_rect) or not _valid_rect(battle_rect):
		return Vector2.ZERO
	var effective_rect := battle_rect.intersection(screen_rect)
	if not _valid_rect(effective_rect) or not _contains_inclusive(effective_rect, pointer):
		return Vector2.ZERO
	var direction := Vector2(
		_edge_axis(pointer.x, effective_rect.position.x, effective_rect.end.x),
		_edge_axis(pointer.y, effective_rect.position.y, effective_rect.end.y)
	)
	return direction.normalized() if not direction.is_zero_approx() else Vector2.ZERO


func advance(camera: RefCounted, delta: float, keys: Vector2, pointer: Vector2, screen_rect: Rect2, battle_rect: Rect2, context: Dictionary = {}) -> bool:
	if camera == null or not is_finite(delta) or delta <= 0.0:
		return false
	var direction := get_direction(keys, pointer, screen_rect, battle_rect, context)
	if direction.is_zero_approx():
		return false
	var pixel_distance := SPEED_PIXELS_PER_SECOND * delta
	if not is_finite(pixel_distance):
		return false
	# GDScript floats are double precision, but Vector2 stores float32. A huge
	# finite delta can otherwise become infinity (and 0 * infinity becomes NaN)
	# when converted into a vector. Travel beyond the whole projected world is
	# already clamped by geometry, so saturate it before that conversion.
	var projected_size: Vector2 = camera.get_projected_world_rect().size
	var maximum_useful_distance := maxf(projected_size.x + projected_size.y, 1.0) * 2.0
	pixel_distance = minf(pixel_distance, maximum_useful_distance)
	var before: Vector2 = camera.get_center()
	# pan_screen is drag-oriented; a rightward camera moves the world left.
	# Projection converts these screen pixels at the current zoom and clamps
	# even a finite, unusually large frame delta to the legal arena view.
	camera.pan_screen(-direction * pixel_distance)
	return camera.get_center() != before


func _edge_axis(value: float, lower: float, upper: float) -> float:
	var near_lower := value - lower <= EDGE_BAND_PIXELS
	var near_upper := upper - value <= EDGE_BAND_PIXELS
	# Intermediate tiny layouts can have overlapping bands. Pick the nearest
	# edge, with no arbitrary movement at the exact center of that axis.
	if near_lower and near_upper:
		return signf(value - (lower + upper) * 0.5)
	if near_lower:
		return -1.0
	if near_upper:
		return 1.0
	return 0.0


func _valid_rect(rect: Rect2) -> bool:
	return rect.position.is_finite() and rect.size.is_finite() and rect.size.x > 0.0 and rect.size.y > 0.0


func _contains_inclusive(rect: Rect2, point: Vector2) -> bool:
	# A pointer exactly on a viewport border is still a valid edge. The live
	# caller separately tracks window exit, so border inclusion cannot turn an
	# outside-window stale pointer into navigation.
	return point.x >= rect.position.x and point.y >= rect.position.y and point.x <= rect.end.x and point.y <= rect.end.y
