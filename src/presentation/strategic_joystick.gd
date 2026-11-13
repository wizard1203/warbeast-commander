class_name StrategicJoystick
extends Control
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
## Pointer and screen-touch share one captured gesture. This control emits only
## input vectors; the arena submits bounded local commands to the host.

signal vector_changed(value: Vector2)
signal gesture_finished(value: Vector2)

const IconClass = preload("res://src/presentation/strategic_icon_button.gd")

var caption := "移动"
var icon := "move"
var vector := Vector2.ZERO
var active := false
var cooldown := 0.0
var max_cooldown := 0.0
var available := true
var mana_cost := -1
var _touch_index := -1
var _mouse_active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Respect compact skill dimensions supplied by the arena; movement sticks
	# without an explicit size still receive the large touch-friendly default.
	if custom_minimum_size == Vector2.ZERO: custom_minimum_size = Vector2(108, 108)

func clear() -> void:
	active = false
	_mouse_active = false
	_touch_index = -1
	vector = Vector2.ZERO
	vector_changed.emit(vector)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	# Touch has its own captured contact. Godot may additionally synthesize a
	# mouse release before a canceled touch; it must not finish that gesture.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		accept_event()
		return
	if not available:
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active = true
			_mouse_active = true
			_update_vector(event.position)
		else:
			_finish()
		accept_event()
	elif event is InputEventMouseMotion and _mouse_active:
		_update_vector(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_index < 0:
			active = true
			_touch_index = event.index
			_update_vector(event.position)
		elif not event.pressed and event.index == _touch_index:
			if event.canceled:
				clear()
			else:
				_finish()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_vector(event.position)
		accept_event()

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# A captured mouse gesture can end outside the circle or after a modal has
	# appeared. Never require a release to land over this control.
	if _mouse_active and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish()
		get_viewport().set_input_as_handled()
	elif _touch_index >= 0 and event is InputEventScreenTouch and event.index == _touch_index and not event.pressed:
		if event.canceled: clear()
		else: _finish()
		# The arena must observe every physical release to retire camera contact
		# ownership. Its tracked GUI-origin contact cannot become a terrain tap;
		# _gui_input still consumes the release, including outside-stick endings.
	elif _mouse_active and event is InputEventMouseMotion:
		_update_vector(get_global_transform().affine_inverse() * event.global_position)
	elif _touch_index >= 0 and event is InputEventScreenDrag and event.index == _touch_index:
		_update_vector(get_global_transform().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()

func _update_vector(point: Vector2) -> void:
	var radius := minf(size.x, size.y) * 0.32
	vector = ((point - size * 0.5) / radius).limit_length(1.0)
	if vector.length() < 0.15: vector = Vector2.ZERO
	vector_changed.emit(vector)
	queue_redraw()

func _finish() -> void:
	if not active: return
	var final_vector := vector
	clear()
	if available: gesture_finished.emit(final_vector)

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.45
	var ready := available and cooldown <= 0
	var outer_ink := Color("edc67e") if ready else Color("687675")
	draw_circle(center + Vector2(0, 3), radius, Color(0.01, 0.03, 0.04, 0.5))
	draw_circle(center, radius, Color("142b30") if ready else Color("202b2d"))
	draw_arc(center, radius, 0, TAU, 48, outer_ink, 2)
	# A thick outside ring remains visible beyond the pressing finger. The
	# larger glyph uses the existing original symbols; input radii stay intact.
	if active:
		draw_arc(center, radius + 1, 0, TAU, 48, Color("fff1bb"), 4)
	var thumb := center + vector * radius * 0.32 + (Vector2(0, 1) if active else Vector2.ZERO)
	draw_circle(thumb, radius * 0.55, Color("496e65") if active else Color("2c494b") if ready else Color("2d393a"))
	draw_arc(thumb, radius * 0.55, 0, TAU, 36, Color("98b2a0") if active else Color("58776c"), 1)
	var glyph_scale := clampf(minf(size.x, size.y) / 80.0, 0.85, 1.3)
	var glyph_center := thumb + Vector2(0, -4)
	IconClass.draw_symbol(self, icon, glyph_center + Vector2(0, 1), Color("112629"), glyph_scale)
	IconClass.draw_symbol(self, icon, glyph_center, Color("f1d59c") if ready else Color("8a9b92"), glyph_scale)
	if cooldown > 0:
		draw_circle(center, radius - 2, Color(0.02, 0.08, 0.08, 0.76))
		var ratio := clampf(cooldown / maxf(max_cooldown, cooldown), 0, 1)
		draw_arc(center, radius - 3, -PI * 0.5, -PI * 0.5 + TAU * ratio, 48, Color("d6a76b"), 4)
		draw_string(ReadableFont.readable(), Vector2(0, center.y + 7), str(ceili(cooldown)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 25, Color.WHITE)
	elif not available:
		draw_arc(center, radius - 6, PI * 0.12, PI * 0.88, 24, Color("788482"), 2)
	# Caption is drawn after the cooldown mask, never dimmed beneath it.
	draw_string(ReadableFont.readable(), Vector2(0, size.y - 1), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color("102326"))
	draw_string(ReadableFont.readable(), Vector2(0, size.y - 2), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color("e7eadb") if ready or active else Color("a5b2ab"))
	if mana_cost >= 0:
		var badge := Rect2(size.x - 39, 0, 39, 19)
		draw_rect(badge, Color("18364e"))
		draw_rect(badge, Color("6ba8d9"), false, 1)
		draw_string(ReadableFont.readable(), badge.position + Vector2(2, 14), "蓝%d" % mana_cost, HORIZONTAL_ALIGNMENT_CENTER, 35, 12, Color("b0dcff"))

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
