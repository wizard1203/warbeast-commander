class_name Frontier3DCameraProjection
extends "res://src/presentation/battle_camera_projection.gd"
## Presentation-only fixed-oblique adapter. Authority remains on the existing
## 2D ground plane: (x, y) maps to 3D (x, height, z), at 24 world units/metre.
## The analytical projection is usable without a renderer. bind_camera() makes
## a real orthographic Camera3D match it, rather than making physics/raycasting
## a second source of movement, selection, or combat truth.

const WORLD_SCALE := 1.0 / 24.0
const ELEVATION := 0.960070362405688
const GROUND_Y_COMPRESSION := 0.8192319205190405
const HEIGHT_Y_COMPRESSION := 0.5734623443633283
const CAMERA_DISTANCE := 60.0

var _render_camera: Camera3D


func bind_camera(render_camera: Camera3D) -> void:
	_render_camera = render_camera
	_sync_camera()


func configure(bounds: Rect2i, viewport: Rect2, max_zoom: float = MAX_ZOOM) -> void:
	_bounds = Rect2(Vector2(bounds.position), Vector2(maxi(bounds.size.x, 1), maxi(bounds.size.y, 1)))
	_viewport = Rect2(viewport.position, Vector2(maxf(viewport.size.x, 1.0), maxf(viewport.size.y, 1.0)))
	_fit_scale = minf(_viewport.size.x / _bounds.size.x, _viewport.size.y / (_bounds.size.y * GROUND_Y_COMPRESSION))
	_max_zoom = maxf(MIN_ZOOM, max_zoom) if is_finite(max_zoom) else MAX_ZOOM
	_zoom = clampf(_zoom, MIN_ZOOM, _max_zoom)
	if not _configured:
		_center = _bounds.get_center()
		_configured = true
	_clamp_center()
	_sync_camera()


func world_to_screen(world_position: Vector2) -> Vector2:
	var offset := world_position - _center
	return _viewport.get_center() + Vector2(offset.x, offset.y * GROUND_Y_COMPRESSION) * get_scale()


func world_to_screen_height(world_position: Vector2, height_metres: float) -> Vector2:
	return world_to_screen(world_position) - Vector2(0.0, height_metres / WORLD_SCALE * HEIGHT_Y_COMPRESSION * get_scale())


func screen_to_world(screen_position: Vector2) -> Vector2:
	var offset := (screen_position - _viewport.get_center()) / get_scale()
	return _center + Vector2(offset.x, offset.y / GROUND_Y_COMPRESSION)


func pan_screen(drag_delta: Vector2) -> void:
	if not drag_delta.is_finite():
		return
	_center -= Vector2(drag_delta.x, drag_delta.y / GROUND_Y_COMPRESSION) / get_scale()
	_clamp_center()
	_sync_camera()


func zoom_at(screen_position: Vector2, multiplier: float) -> void:
	if not screen_position.is_finite() or not is_finite(multiplier) or multiplier <= 0.0:
		return
	var anchored_world := screen_to_world(screen_position)
	_zoom = clampf(_zoom * multiplier, MIN_ZOOM, _max_zoom)
	var offset := (screen_position - _viewport.get_center()) / get_scale()
	_center = anchored_world - Vector2(offset.x, offset.y / GROUND_Y_COMPRESSION)
	_clamp_center()
	_sync_camera()


func center_on(world_position: Vector2) -> void:
	if not world_position.is_finite():
		return
	_center = world_position
	_clamp_center()
	_sync_camera()


func fit_all() -> void:
	_zoom = MIN_ZOOM
	_center = _bounds.get_center()
	_clamp_center()
	_sync_camera()


func get_visible_world_rect() -> Rect2:
	var world_view_size := _world_view_size()
	return Rect2(_center - world_view_size * 0.5, world_view_size).intersection(_bounds)


func get_projected_world_rect() -> Rect2:
	return Rect2(world_to_screen(_bounds.position), Vector2(_bounds.size.x, _bounds.size.y * GROUND_Y_COMPRESSION) * get_scale())


static func to_visual(world_position: Vector2, height_metres: float = 0.0) -> Vector3:
	return Vector3(world_position.x * WORLD_SCALE, height_metres, world_position.y * WORLD_SCALE)


func _world_view_size() -> Vector2:
	return Vector2(_viewport.size.x, _viewport.size.y / GROUND_Y_COMPRESSION) / get_scale()


func _clamp_center() -> void:
	var half_view := _world_view_size() * 0.5
	var bounds_center := _bounds.get_center()
	_center.x = bounds_center.x if half_view.x * 2.0 >= _bounds.size.x else clampf(_center.x, _bounds.position.x + half_view.x, _bounds.end.x - half_view.x)
	_center.y = bounds_center.y if half_view.y * 2.0 >= _bounds.size.y else clampf(_center.y, _bounds.position.y + half_view.y, _bounds.end.y - half_view.y)


func _sync_camera() -> void:
	if not is_instance_valid(_render_camera):
		return
	_render_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_render_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_render_camera.size = _viewport.size.y * WORLD_SCALE / get_scale()
	_render_camera.near = 0.1
	_render_camera.far = 400.0
	var offset := Vector3(0.0, GROUND_Y_COMPRESSION, HEIGHT_Y_COMPRESSION) * CAMERA_DISTANCE
	var camera_transform := Transform3D(Basis(Vector3.RIGHT, -ELEVATION), to_visual(_center) + offset)
	if _render_camera.is_inside_tree():
		_render_camera.global_transform = camera_transform
		_render_camera.force_update_transform()
	else:
		_render_camera.transform = camera_transform
