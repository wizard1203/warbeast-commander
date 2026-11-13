class_name StrategicContextHelp
extends Control
## Read-only, host-driven inspection. The arena calls handle_event before its
## camera routing and advance once per frame. This node never receives _input
## itself, calls a command, or emits a control's semantic pressed signal.

signal replay_requested(events: Array)
signal world_hold_started(index: int)

const ReadableFont = preload("res://src/presentation/strategic_font.gd")
var resolver: Callable
## Optional host lookup by stable subject ID, never by a stale screen position.
var target_validity: Callable
## Optional identity-based refresh of a retained subject, never a new hit-test
## at the current pointer. Standalone hosts may retain snapshot descriptions.
var target_refresher: Callable
var replaying := false
var hover_delay := 0.45
var hold_delay := 0.55
var drag_slop := 12.0
var displayed_text := ""

var _contacts: Dictionary = {}
var _multiple := false
var _mouse_down := false
var _last_input_touch := false
var _hover_target: Dictionary = {}
var _hover_elapsed := 0.0
var _shown_target: Dictionary = {}
var _shown_contact := -1
var _shown_pointer := Vector2.ZERO
var _panel_rect := Rect2()
var _lines: Array[String] = []
var _font_size := 16
var _wrap_signature := ""
var _consumed_mouse_buttons: Dictionary = {}
var _consume_emulated_release := false
var _hover_blocked_until_motion := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 4090
	hide()

func handle_event(event: InputEvent) -> bool:
	if replaying: return false
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			if event is InputEventMouseButton and not event.pressed and _consume_emulated_release:
				_consume_emulated_release = false
				return true
			# A displayed popup owns its interior and dismissal. Physical touch
			# supplies the decision, including when emulation arrives first.
			if visible and not _original_action_at(event.position): return true
			# An engine-generated mouse DOWN can precede its physical touch.
			# Resolve it independently so it cannot activate an owned control.
			for contact: Dictionary in _contacts.values():
				if bool(contact.get("ui_origin", false)): return true
			var emulated_target := _resolve(event.position)
			return not emulated_target.is_empty() and emulated_target.get("kind", "ui") == "ui" and not bool(emulated_target.get("immediate", false))
		_last_input_touch = false
		if event is InputEventMouseMotion:
			if not _mouse_down: _hover_blocked_until_motion = false
			return false
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT: _mouse_down = event.pressed
			if not event.pressed and _consumed_mouse_buttons.has(event.button_index):
				_consumed_mouse_buttons.erase(event.button_index)
				return true
			if event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
				_consumed_mouse_buttons.erase(event.button_index)
				_hover_blocked_until_motion = true
				if _inspect_click(event.position):
					_consumed_mouse_buttons[event.button_index] = true
					_reset_hover()
					return true
			_reset_hover()
		return false
	if event is InputEventScreenTouch:
		_last_input_touch = true
		if event.pressed: return _touch_down(event)
		return _touch_up(event)
	if event is InputEventScreenDrag:
		_last_input_touch = true
		return _touch_drag(event)
	if event is InputEventKey and event.pressed and (not visible or event.keycode==KEY_ESCAPE): dismiss()
	if event is InputEventMagnifyGesture or event is InputEventPanGesture:
		if not visible: dismiss()
	return false

func advance(delta: float, pointer: Vector2) -> void:
	var step := maxf(delta, 0.0) if is_finite(delta) else 0.0
	if visible and not _shown_target_valid(): dismiss()
	if visible: _refresh_shown_content()
	if not _contacts.is_empty():
		_reset_hover()
		if _multiple: return
		for index: int in _contacts:
			var contact: Dictionary = _contacts[index]
			if contact.mode not in ["ui_pending", "world"] or bool(contact.canceled): continue
			if bool(contact.held) and visible: continue
			var current := _current_target(contact.target, contact.point)
			if current.is_empty():
				contact.canceled = true
				if contact.mode == "ui_pending": contact.mode = "suppressed"
				elif contact.mode == "world": world_hold_started.emit(index)
				_hide_hint()
				continue
			contact.target = current
			contact.elapsed += step
			if bool(contact.held):
				if not visible: _show_hint(current, contact.point, index)
			elif float(contact.elapsed) >= hold_delay:
				contact.held = true
				_show_hint(current, contact.point, index)
				if contact.mode == "world": world_hold_started.emit(index)
		return
	# Once latched, neither pointer movement nor elapsed time changes the
	# inspected subject. A deliberate click is the only ordinary dismissal.
	if visible: return
	if _mouse_down or _last_input_touch or _hover_blocked_until_motion:
		_reset_hover()
		return
	var target := _resolve(pointer)
	if target.is_empty():
		_reset_hover()
		return
	if not _same_target(target, _hover_target):
		_hover_target = target
		_hover_elapsed = 0.0
		return
	_hover_target = target
	_hover_elapsed += step
	if _hover_elapsed >= hover_delay: _show_hint(target, pointer)

func dismiss(cancel_contacts: bool = true) -> void:
	# Focus/modal cancellation must not restart inspection from the unchanged
	# stored pointer. A subsequent real mouse motion explicitly rearms hover.
	_hover_blocked_until_motion = true
	_hide_hint()
	_reset_hover()
	_mouse_down = false
	if cancel_contacts:
		for index: int in _contacts:
			var contact: Dictionary = _contacts[index]
			contact.canceled = true
			# Keep ownership until release: a modal/focus change must not let a
			# deferred UI touch become a command in a new context.
			if contact.mode == "ui_pending": contact.mode = "suppressed"
			elif contact.mode == "world": world_hold_started.emit(index)

func diagnostic() -> Dictionary:
	return {"visible":visible, "key":str(_shown_target.get("key", "")), "text":displayed_text, "kind":str(_shown_target.get("kind", "")), "panel_rect":_panel_rect, "contacts":_contacts.size(), "multiple":_multiple, "lines":_lines.duplicate(), "mouse_filter":mouse_filter, "consumed_mouse_pairs":_consumed_mouse_buttons.size(), "latched":visible and not _shown_target.is_empty()}

func inspect() -> Dictionary:
	return diagnostic()

func _touch_down(event: InputEventScreenTouch) -> bool:
	_reset_hover()
	if _contacts.has(event.index): return bool(_contacts[event.index].get("ui_origin", false))
	if not _contacts.is_empty():
		_multiple = true
		for contact: Dictionary in _contacts.values():
			contact.canceled = true
			if contact.mode == "latched_pending":
				# A two-finger gesture is not the promised dismissal tap. Replay
				# its reserved first ground contact, but never a covered UI action.
				if contact.target.get("kind", "") == "ui": contact.mode = "suppressed"
				else:
					contact.mode = "native"
					_replay([contact.down.duplicate()])
			if contact.mode == "ui_pending":
				if bool(contact.held): contact.mode = "suppressed"
				else:
					contact.mode = "native"
					_replay([contact.down.duplicate()])
	if visible and not _multiple and not _original_action_at(event.position):
		_consume_emulated_release = true
		var inside := _panel_rect.has_point(event.position)
		_contacts[event.index] = {"mode":"suppressed" if inside else "latched_pending", "ui_origin":true, "mouse_handoff":false, "target":_resolve(event.position), "origin":event.position, "point":event.position, "down":event.duplicate(), "elapsed":0.0, "held":false, "canceled":inside}
		return true
	if visible and not _multiple: _hide_hint()
	var target := _resolve(event.position)
	var discrete_ui: bool = not target.is_empty() and target.get("kind", "ui") == "ui" and not bool(target.get("immediate", false))
	var mode := "native"
	if not _multiple and not target.is_empty():
		mode = "ui_pending" if discrete_ui else "world" if target.get("kind") == "world" else "native"
	_contacts[event.index] = {"mode":mode, "ui_origin":discrete_ui and not _multiple, "mouse_handoff":false, "target":target, "origin":event.position, "point":event.position, "down":event.duplicate(), "elapsed":0.0, "held":false, "canceled":_multiple}
	return mode == "ui_pending"

func _touch_up(event: InputEventScreenTouch) -> bool:
	if not _contacts.has(event.index): return false
	var contact: Dictionary = _contacts[event.index]
	var owned: bool = contact.mode in ["ui_pending", "suppressed", "latched_pending"]
	if contact.mode == "latched_pending":
		if not event.canceled and not bool(contact.canceled): _hide_hint()
	elif contact.mode == "ui_pending" and not event.canceled and not bool(contact.canceled) and not bool(contact.held):
		var current := _current_target(contact.target, event.position)
		if not current.is_empty() and not bool(current.get("passive", false)) and event.position.distance_to(contact.origin) <= drag_slop:
			# Replay into the native viewport, never bypass disabled, toggled or
			# OptionButton behavior by emitting semantic signals ourselves.
			# Explanatory IGNORE labels are passive: replay there would fall
			# through the GUI and accidentally become a battlefield command.
			var down := InputEventMouseButton.new()
			down.button_index = MOUSE_BUTTON_LEFT
			down.button_mask = MOUSE_BUTTON_MASK_LEFT
			down.position = event.position
			down.global_position = event.position
			down.pressed = true
			var up := down.duplicate() as InputEventMouseButton
			up.pressed = false
			up.button_mask = 0
			_replay([down, up])
	elif contact.mode == "native" and bool(contact.get("mouse_handoff", false)):
		var release := _mouse_button(event.position, false)
		_replay([release])
	_contacts.erase(event.index)
	if _contacts.is_empty(): _multiple = false
	if _shown_contact == event.index:
		_shown_contact = -1
		if event.canceled: _hide_hint()
	return owned

func _touch_drag(event: InputEventScreenDrag) -> bool:
	if not _contacts.has(event.index): return false
	var contact: Dictionary = _contacts[event.index]
	contact.point = event.position
	if contact.mode == "suppressed": return true
	if contact.mode == "latched_pending":
		if event.position.distance_to(contact.origin)>drag_slop: contact.canceled=true
		return true
	if contact.mode == "native":
		if bool(contact.get("mouse_handoff", false)): _replay([_mouse_motion(event)])
		return false
	if event.position.distance_to(contact.origin) <= drag_slop: return contact.mode == "ui_pending"
	contact.canceled = true
	if not bool(contact.held): _hide_hint()
	if contact.mode == "ui_pending":
		if bool(contact.held):
			contact.mode = "suppressed"
		else:
			contact.mode = "native"
			contact.mouse_handoff = true
			# ScrollContainer uses the mouse representation of a physical touch.
			# push_input does not synthesize it. Supply both representations once;
			# physical emulation remains suppressed for this owned contact.
			_replay([contact.down.duplicate(), _mouse_button(contact.origin, true), event.duplicate(), _mouse_motion(event)])
		return true
	return false

func _resolve(point: Vector2) -> Dictionary:
	if not resolver.is_valid(): return {}
	var resolved: Variant = resolver.call(point)
	if not resolved is Dictionary or str(resolved.get("key", "")).is_empty() or str(resolved.get("text", "")).strip_edges().is_empty(): return {}
	var control: Variant = resolved.get("control")
	if resolved.has("control") and (not is_instance_valid(control) or not control is Control or not control.is_inside_tree() or not control.is_visible_in_tree()): return {}
	return resolved.duplicate()

func _current_target(previous: Dictionary, point: Vector2) -> Dictionary:
	var current := _resolve(point)
	return current if _same_target(previous, current) else {}

func _same_target(first: Dictionary, second: Dictionary) -> bool:
	return not first.is_empty() and not second.is_empty() and first.get("key") == second.get("key") and first.get("control") == second.get("control")

func _original_action_at(point: Vector2) -> bool:
	if not visible or _panel_rect.has_point(point) or _shown_target.get("kind", "") != "ui": return false
	if bool(_shown_target.get("passive", false)) and not bool(_shown_target.get("immediate", false)): return false
	return _same_target(_shown_target, _resolve(point))

func _inspect_click(point: Vector2) -> bool:
	if not visible: return false
	if _panel_rect.has_point(point): return true
	var original_action := _original_action_at(point)
	_hide_hint()
	return not original_action

func _shown_target_valid() -> bool:
	var control: Variant = _shown_target.get("control")
	if _shown_target.has("control") and (not is_instance_valid(control) or not control is Control or control.is_queued_for_deletion() or not control.is_inside_tree() or not control.is_visible_in_tree()): return false
	return target_validity.call(_shown_target.duplicate()) == true if target_validity.is_valid() else true

func _refresh_shown_content() -> void:
	if not target_refresher.is_valid(): return
	var current: Variant = target_refresher.call(_shown_target.duplicate())
	if not current is Dictionary or not _same_target(_shown_target, current) or current.get("kind") != _shown_target.get("kind") or str(current.get("text", "")).strip_edges().is_empty():
		dismiss()
		return
	if current.get("text") != displayed_text or current.get("rect") != _shown_target.get("rect"):
		# Preserve subject, original touch placement and contact ownership while
		# recomputing the same wrapped panel from its live read-only source.
		_show_hint(current, _shown_pointer, _shown_contact)

func _exit_tree() -> void:
	_hide_hint()
	_reset_hover()
	_contacts.clear()
	_consumed_mouse_buttons.clear()
	_multiple = false
	_mouse_down = false
	_consume_emulated_release = false
	_last_input_touch = false
	_hover_blocked_until_motion = false

func _replay(events: Array) -> void:
	for event: InputEvent in events: event.set_meta("strategic_context_help_replay", true)
	replay_requested.emit(events)

func _mouse_button(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	return event

func _mouse_motion(drag: InputEventScreenDrag) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = drag.position
	event.global_position = drag.position
	event.relative = drag.relative
	event.velocity = drag.velocity
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	return event

func _reset_hover() -> void:
	_hover_target.clear()
	_hover_elapsed = 0.0

func _hide_hint() -> void:
	hide()
	_shown_target.clear()
	_shown_contact = -1
	_shown_pointer = Vector2.ZERO
	displayed_text = ""
	_lines.clear()
	_wrap_signature = ""

func _show_hint(target: Dictionary, pointer: Vector2, contact: int = -1) -> void:
	_shown_target = target.duplicate()
	_shown_contact = contact
	_shown_pointer = pointer
	displayed_text = str(target.get("text", ""))
	var viewport := get_viewport_rect()
	var width := minf(364.0, maxf(viewport.size.x - 24, 24))
	var signature := displayed_text + ":" + str(width) + ":" + str(viewport.size.y)
	if signature != _wrap_signature:
		_wrap_signature = signature
		_font_size = 16
		_lines = _wrap_text(displayed_text, width - 24, _font_size)
		if _lines.size() * 21 + 24 > viewport.size.y - 24:
			_font_size = 14
			_lines = _wrap_text(displayed_text, width - 24, _font_size)
		var budget := maxi(int((viewport.size.y - 48) / float(_font_size + 5)), 1)
		if _lines.size() > budget:
			_lines.resize(budget)
			_lines[budget - 1] = "更多属性 / 技能：单击查看手册"
	var height := minf(_lines.size() * (_font_size + 5) + 24, maxf(viewport.size.y - 24, 24))
	var anchor: Rect2 = target.get("rect", Rect2(pointer, Vector2.ZERO))
	var origin := Vector2(anchor.end.x + 12, anchor.position.y)
	if contact >= 0:
		origin = Vector2(pointer.x - width * 0.5, pointer.y - height - 28)
		# At the top edge, prefer below the inspected control rather than
		# clamping the popup over the very button whose normal click is kept.
		if origin.y < viewport.position.y+12: origin.y = maxf(pointer.y+28,anchor.end.y+12)
	elif origin.x + width > viewport.end.x - 12: origin.x = anchor.position.x - width - 12
	origin.x = clampf(origin.x, viewport.position.x + 12, maxf(viewport.end.x - width - 12, viewport.position.x + 12))
	origin.y = clampf(origin.y, viewport.position.y + 12, maxf(viewport.end.y - height - 12, viewport.position.y + 12))
	_panel_rect = Rect2(origin.round(), Vector2(width, height).round())
	show()
	queue_redraw()

func _wrap_text(text: String, width: float, font_size: int) -> Array[String]:
	var result: Array[String] = []
	var font := ReadableFont.readable()
	for paragraph: String in text.split("\n", true):
		var line := ""
		for character: String in paragraph:
			if not line.is_empty() and font.get_string_size(line + character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
				result.append(line)
				line = ""
			line += character
		result.append(line)
	return result

func _draw() -> void:
	if _shown_target.is_empty(): return
	# Square, hard-edged layers rather than glossy bevels or rounded cards.
	draw_rect(Rect2(_panel_rect.position + Vector2(3, 3), _panel_rect.size), Color("101617", 0.8))
	draw_rect(_panel_rect, Color("1a2528"))
	draw_rect(_panel_rect, Color("9a8b68"), false, 2)
	draw_rect(_panel_rect.grow(-3), Color("3d4944"), false, 1)
	var baseline := _panel_rect.position + Vector2(12, 12 + _font_size)
	var font := ReadableFont.readable()
	for index: int in range(_lines.size()):
		if baseline.y > _panel_rect.end.y - 9: break
		draw_string(font, baseline, _lines[index], HORIZONTAL_ALIGNMENT_LEFT, _panel_rect.size.x - 24, _font_size, Color("f1dfb4") if index == 0 else Color("d2d7c9"))
		baseline.y += _font_size + 5
