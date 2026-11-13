class_name BattleCameraProjection
extends RefCounted
## Pure M7 world/view geometry. Camera and minimap operations know no session,
## snapshots, selection, commands or timers. Forward/inverse mappings are not
## clipped: the caller clips drawing and gates taps to visible world coverage.

const MIN_ZOOM := 1.0
const MAX_ZOOM := 2.0

var _bounds := Rect2(Vector2.ZERO, Vector2.ONE)
var _viewport := Rect2(Vector2.ZERO, Vector2.ONE)
var _center := Vector2(0.5, 0.5)
var _fit_scale := 1.0
var _zoom := MIN_ZOOM
var _max_zoom := MAX_ZOOM
var _configured := false


func configure(bounds: Rect2i, viewport: Rect2, max_zoom: float = MAX_ZOOM) -> void:
	# Valid product geometry is positive-sized. A one-pixel fallback prevents an
	# intermediate zero-sized Control layout from producing a divide by zero.
	_bounds = Rect2(Vector2(bounds.position), Vector2(maxi(bounds.size.x, 1), maxi(bounds.size.y, 1)))
	_viewport = Rect2(viewport.position, Vector2(maxf(viewport.size.x, 1.0), maxf(viewport.size.y, 1.0)))
	_fit_scale = minf(_viewport.size.x / _bounds.size.x, _viewport.size.y / _bounds.size.y)
	_max_zoom = maxf(MIN_ZOOM, max_zoom)
	_zoom = clampf(_zoom, MIN_ZOOM, _max_zoom)
	if not _configured:
		_center = _bounds.get_center()
		_configured = true
	_clamp_center()


func world_to_screen(world_position: Vector2) -> Vector2:
	return _viewport.get_center() + (world_position - _center) * get_scale()


func screen_to_world(screen_position: Vector2) -> Vector2:
	return _center + (screen_position - _viewport.get_center()) / get_scale()


func pan_screen(drag_delta: Vector2) -> void:
	# Dragging right/down moves the visible world right/down, hence the camera
	# center moves left/up in world space. This never changes any entity.
	_center -= drag_delta / get_scale()
	_clamp_center()


func zoom_at(screen_position: Vector2, multiplier: float) -> void:
	if multiplier <= 0.0:
		return
	var anchored_world := screen_to_world(screen_position)
	_zoom = clampf(_zoom * multiplier, MIN_ZOOM, _max_zoom)
	_center = anchored_world - (screen_position - _viewport.get_center()) / get_scale()
	# At an arena edge, a legal view takes precedence over cursor anchoring.
	_clamp_center()


func center_on(world_position: Vector2) -> void:
	_center = world_position
	_clamp_center()


func fit_all() -> void:
	_zoom = MIN_ZOOM
	_center = _bounds.get_center()
	_clamp_center()


func get_visible_world_rect() -> Rect2:
	var world_view_size := _viewport.size / get_scale()
	var world_view := Rect2(_center - world_view_size * 0.5, world_view_size)
	return world_view.intersection(_bounds)


func get_projected_world_rect() -> Rect2:
	return Rect2(world_to_screen(_bounds.position), _bounds.size * get_scale())


func get_scale() -> float:
	return _fit_scale * _zoom


func get_zoom() -> float:
	return _zoom


func get_center() -> Vector2:
	return _center


func minimap_world_to_screen(world_position: Vector2, minimap_rect: Rect2) -> Vector2:
	return minimap_rect.position + (world_position - _bounds.position) / _bounds.size * minimap_rect.size


func minimap_screen_to_world(screen_position: Vector2, minimap_rect: Rect2) -> Vector2:
	var safe_size := Vector2(maxf(minimap_rect.size.x, 1.0), maxf(minimap_rect.size.y, 1.0))
	var normalized := (screen_position - minimap_rect.position) / safe_size
	return _bounds.position + Vector2(clampf(normalized.x, 0.0, 1.0), clampf(normalized.y, 0.0, 1.0)) * _bounds.size


func get_minimap_view_rect(minimap_rect: Rect2) -> Rect2:
	var visible := get_visible_world_rect()
	return Rect2(minimap_world_to_screen(visible.position, minimap_rect), visible.size / _bounds.size * minimap_rect.size)


func _clamp_center() -> void:
	var half_view := _viewport.size / get_scale() * 0.5
	var bounds_center := _bounds.get_center()
	# Fit-all can letterbox along either axis. Do not form a reversed clamp
	# interval when that axis's view is larger than the actual world.
	_center.x = bounds_center.x if half_view.x * 2.0 >= _bounds.size.x else clampf(_center.x, _bounds.position.x + half_view.x, _bounds.end.x - half_view.x)
	_center.y = bounds_center.y if half_view.y * 2.0 >= _bounds.size.y else clampf(_center.y, _bounds.position.y + half_view.y, _bounds.end.y - half_view.y)
