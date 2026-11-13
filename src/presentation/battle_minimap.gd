class_name BattleMinimap
extends Control
## A snapshot-only navigation surface. It has no session or command reference.

signal location_requested(world_position: Vector2)
signal expansion_requested

const PLAYER_COLOR := Color("59b3dc")
const AI_COLOR := Color("e47757")
const SITE_COLOR := Color("b5b786")

var _camera: RefCounted
var _snapshot: Dictionary = {}
var show_caption := true
var show_expansion := false
var _expand_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events = false
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "全场公开，无战争迷雾。蓝为我方，红为敌方，菱形为响泉，金圈为实际存活英雄。\n点击只定位镜头，不移动或选择单位；英雄倒地后不冒充活兵标记。"
	if show_expansion:
		_expand_button = Button.new()
		_expand_button.name = "ExpandTacticalMapButton"
		_expand_button.text = "+"
		_expand_button.custom_minimum_size = Vector2(24, 20)
		_expand_button.size = Vector2(24, 20)
		_expand_button.focus_mode = Control.FOCUS_NONE
		_expand_button.mouse_filter = Control.MOUSE_FILTER_STOP
		_expand_button.mouse_force_pass_scroll_events = false
		_expand_button.tooltip_text = "展开战术地图：全场公开，点击只定位镜头"
		_expand_button.pressed.connect(func() -> void: expansion_requested.emit())
		add_child(_expand_button)
		_expand_button.position = Vector2(size.x - 30, 2)
	resized.connect(_layout_expand_button)


func _layout_expand_button() -> void:
	if is_instance_valid(_expand_button):
		_expand_button.position = Vector2(size.x - 30, 2)


func set_view(snapshot: Dictionary, camera: RefCounted) -> void:
	_snapshot = snapshot.duplicate(true)
	_camera = camera
	queue_redraw()


func get_map_rect() -> Rect2:
	var width := maxf(2.0, size.x - 12.0)
	return Rect2(Vector2(6, 20 if show_caption else 6), Vector2(width, width * 0.5))


func request_location(local_position: Vector2) -> void:
	if _camera == null or not get_map_rect().has_point(local_position):
		return
	location_requested.emit(_camera.minimap_screen_to_world(local_position, get_map_rect()))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			request_location(mouse_event.position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			request_location(touch_event.position)
	# Even unused wheel/right/middle input belongs to this overlay, never ground.
	accept_event()


func _draw() -> void:
	draw_style_box(_panel_style(), Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	if show_caption:
		draw_string(font, Vector2(7, 15), "战术小地图", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("edda83"))
	if _camera == null:
		return
	var map_rect := get_map_rect()
	draw_rect(map_rect, Color("263d34"))
	draw_line(map_rect.position + Vector2(0, map_rect.size.y * 0.5), map_rect.end - Vector2(0, map_rect.size.y * 0.5), Color("535a3e"), 4)
	var economy: Dictionary = _snapshot.get("economy", {})
	for site: Variant in economy.get("sites", {}).values():
		var point: Vector2 = _camera.minimap_world_to_screen(Vector2(site), map_rect)
		draw_rect(Rect2(point - Vector2.ONE * 1.5, Vector2.ONE * 3), SITE_COLOR)
	var spring: Dictionary = (_snapshot.get("strategic", {}) as Dictionary).get("spring", {})
	if spring.has("position"):
		var point: Vector2 = _camera.minimap_world_to_screen(Vector2(spring["position"]), map_rect)
		var owner := str(spring.get("owner", "NEUTRAL"))
		var color := PLAYER_COLOR if owner == "PLAYER" else AI_COLOR if owner == "AI" else Color("edda83")
		draw_colored_polygon(PackedVector2Array([point + Vector2(0, -4), point + Vector2(4, 0), point + Vector2(0, 4), point + Vector2(-4, 0)]), color)
		if bool(spring.get("contested", false)) or bool(spring.get("income_blocked", false)):
			draw_arc(point, 6.0, 0, TAU, 12, Color("eadac1"), 1.0)
	for base: Dictionary in _snapshot.get("bases", []):
		var point: Vector2 = _camera.minimap_world_to_screen(Vector2(base["position"]), map_rect)
		var color := PLAYER_COLOR if base["side"] == "PLAYER" else AI_COLOR
		if str(base.get("state", "")) == "EVACUATED":
			color = Color("707969")
		draw_arc(point, 4.0, 0, TAU, 12, color, 1.5)
	for soldier: Dictionary in _snapshot.get("soldiers", []):
		if int(soldier.get("hp", 0)) <= 0:
			continue
		var point: Vector2 = _camera.minimap_world_to_screen(Vector2(soldier["position"]), map_rect)
		draw_rect(Rect2(point - Vector2.ONE, Vector2.ONE * 2), PLAYER_COLOR if soldier["side"] == "PLAYER" else AI_COLOR)
	for worker: Dictionary in economy.get("workers", []):
		var point: Vector2 = _camera.minimap_world_to_screen(Vector2(worker["position"]), map_rect)
		draw_rect(Rect2(point - Vector2.ONE * 0.75, Vector2.ONE * 1.5), Color("cbbf81"))
	for officer: Dictionary in get_hero_markers():
		var point: Vector2 = _camera.minimap_world_to_screen(Vector2(officer["position"]), map_rect)
		draw_arc(point, 3.5, 0, TAU, 8, Color("f3d479"), 1.4)
	var view: Rect2 = _camera.get_minimap_view_rect(map_rect)
	draw_rect(view, Color(0.9, 0.88, 0.65, 0.08))
	draw_rect(view, Color("edda83"), false, 1.0)
	draw_rect(map_rect, Color("627469"), false, 1.0)
	if show_caption and size.y >= 128:
		draw_rect(Rect2(7, size.y - 14, 5, 5), PLAYER_COLOR)
		draw_string(font, Vector2(15, size.y - 8), "我方", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("c7cfbb"))
		draw_rect(Rect2(51, size.y - 14, 5, 5), AI_COLOR)
		draw_string(font, Vector2(59, size.y - 8), "敌方", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("c7cfbb"))
		draw_string(font, Vector2(99, size.y - 8), "全场公开", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9ca88e"))


func get_hero_markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var heroes: Dictionary = _snapshot.get("heroes", {})
	if not bool(heroes.get("enabled", false)):
		return result
	for officer: Dictionary in heroes.get("officers", []):
		if str(officer.get("state", "")) == "ACTIVE" and int(officer.get("hp", 0)) > 0 and officer.has("position"):
			result.append(officer.duplicate(true))
	return result


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.075, 0.97)
	style.border_color = Color("69765e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style
