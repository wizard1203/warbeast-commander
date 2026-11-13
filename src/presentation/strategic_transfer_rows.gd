extends ScrollContainer
## Presentation-only quantities. The arena resolves current, living unit IDs
## and submits the one authoritative transfer; this widget never owns soldiers.

const TextButton = preload("res://src/presentation/strategic_text_button.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const RosterPreview = preload("res://src/presentation/strategic_roster_preview.gd")
const ROW_HEIGHT := 74.0
const ROW_MINIMUM_WIDTH := 600.0

signal selection_changed

var _context := ""
var _route_enabled := true
var _rows: Array[Dictionary] = []
var _selected := {}
var _list: VBoxContainer
var _row_nodes := {}
var heroic_2d := true


class UnitPortrait extends Control:

	const Preview = preload("res://src/presentation/strategic_roster_preview.gd")

	var sample := {}
	var visuals: Array = []
	var heroic_2d := true

	func _get_tooltip(_at_position: Vector2) -> String:
		return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)


	func _draw() -> void:
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color("192c32"))
		var receipts := Preview.draw_group(self, Rect2(Vector2(6, 6), size - Vector2(12, 12)), visuals if not visuals.is_empty() else [sample], heroic_2d)
		set_meta("painted_portraits", receipts)


class TransferRow extends HBoxContainer:

	var selected_count := 0


	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("263b3d") if selected_count > 0 else Color("202f34"))
		if selected_count > 0:
			draw_rect(Rect2(0, 0, 3, size.y), Color("e1bb72"))


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	mouse_filter = Control.MOUSE_FILTER_STOP
	scroll_deadzone = 12
	follow_focus = true


func configure_context(route_key: String, route_enabled: bool = true) -> void:
	var before := selected_counts()
	if _context != route_key:
		_context = route_key
		_selected.clear()
	_route_enabled = route_enabled
	_sync_rows()
	if before != selected_counts(): selection_changed.emit()


func refresh(rows: Array[Dictionary]) -> void:
	var before := selected_counts()
	var normalized: Array[Dictionary] = []
	var seen := {}
	for entry: Dictionary in rows:
		var type := str(entry.get("unit_type", ""))
		var available := maxi(int(entry.get("available", 0)), 0)
		if type.is_empty() or available <= 0 or seen.has(type): continue
		seen[type] = true
		var sample := {"unit_type":type, "side":"PLAYER"}
		var supplied: Dictionary = entry.get("sample", {})
		for key: String in ["side", "faction_id", "role", "body_kind", "hero_archetype"]:
			if supplied.has(key): sample[key] = str(supplied[key])
		var visuals := RosterPreview.visuals_for(type, entry.get("visuals", [supplied]), sample)
		normalized.append({"unit_type":type, "caption":str(entry.get("caption", type)), "icon":str(entry.get("icon", type)), "available":available, "sample":sample, "visuals":visuals})
	var rebuild := _list == null or _type_order(_rows) != _type_order(normalized)
	_rows = normalized
	for type: String in _selected.keys():
		if not seen.has(type): _selected.erase(type)
	for row: Dictionary in _rows:
		var type := str(row.unit_type)
		_selected[type] = clampi(int(_selected.get(type, 0)), 0, int(row.available))
	if rebuild: _rebuild_rows()
	_sync_rows()
	if before != selected_counts(): selection_changed.emit()


func selected_counts() -> Dictionary:
	var result := {}
	for row: Dictionary in _rows:
		var type := str(row.unit_type)
		var count := clampi(int(_selected.get(type, 0)), 0, int(row.available))
		if count > 0: result[type] = count
	return result


func total_selected() -> int:
	var result := 0
	for count: int in selected_counts().values(): result += count
	return result


func rows_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in _rows:
		var detached: Dictionary = row.duplicate(true)
		detached["selected"] = int(_selected.get(str(row.unit_type), 0))
		result.append(detached)
	return result


func set_selected(unit_type: String, count: int) -> void:
	if not _route_enabled: return
	for row: Dictionary in _rows:
		if str(row.unit_type) != unit_type: continue
		var bounded := clampi(count, 0, int(row.available))
		if int(_selected.get(unit_type, 0)) == bounded: return
		_selected[unit_type] = bounded
		_sync_rows()
		selection_changed.emit()
		return


func select_amount(unit_type: String, all_units: bool) -> void:
	for row: Dictionary in _rows:
		if str(row.unit_type) == unit_type:
			var available := int(row.available)
			set_selected(unit_type, available if all_units else ceili(float(available) / 2.0))
			return


func _change_amount(unit_type: String, delta: int) -> void:
	set_selected(unit_type, int(_selected.get(unit_type, 0)) + delta)


func _ensure_list() -> void:
	if _list != null: return
	_list = VBoxContainer.new()
	_list.name = "TransferRowsContent"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size.x = ROW_MINIMUM_WIDTH
	_list.add_theme_constant_override("separation", 8)
	add_child(_list)


func _rebuild_rows() -> void:
	_ensure_list()
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.free()
	_row_nodes.clear()
	if _rows.is_empty():
		var empty := _label("来源部队暂无可调配单位", 19)
		empty.name = "TransferRowsEmpty"
		empty.custom_minimum_size.y = ROW_HEIGHT
		_list.add_child(empty)
		return
	for row: Dictionary in _rows:
		var type := str(row.unit_type)
		var line := TransferRow.new()
		line.name = "TransferRow_" + type
		line.custom_minimum_size.y = ROW_HEIGHT
		line.add_theme_constant_override("separation", 6)
		line.mouse_filter = Control.MOUSE_FILTER_PASS
		line.set_meta("unit_type", type)
		_list.add_child(line)
		var portrait := UnitPortrait.new()
		portrait.name = "TransferPortrait_" + type
		portrait.custom_minimum_size = Vector2(64, 64)
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(portrait)
		var caption := _label("", 19)
		caption.name = "TransferCaption_" + type
		caption.custom_minimum_size.x = 124
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(caption)
		var minus := _amount_button("−", "TransferMinus_" + type, 48)
		minus.pressed.connect(_change_amount.bind(type, -1))
		line.add_child(minus)
		var count := _label("", 22)
		count.name = "TransferCount_" + type
		count.custom_minimum_size.x = 76
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.tooltip_text = "所选人数 / 来源部队当前存活的该兵种人数。"
		line.add_child(count)
		var plus := _amount_button("+", "TransferPlus_" + type, 48)
		plus.pressed.connect(_change_amount.bind(type, 1))
		line.add_child(plus)
		var half := _amount_button("半数", "TransferHalf_" + type, 64)
		half.pressed.connect(select_amount.bind(type, false))
		line.add_child(half)
		var all_units := _amount_button("全选", "TransferAll_" + type, 64)
		all_units.pressed.connect(select_amount.bind(type, true))
		line.add_child(all_units)
		_row_nodes[type] = {"row":line, "portrait":portrait, "caption":caption, "minus":minus, "count":count, "plus":plus, "half":half, "all":all_units}


func _sync_rows() -> void:
	for row: Dictionary in _rows:
		var type := str(row.unit_type)
		if not _row_nodes.has(type): continue
		var nodes: Dictionary = _row_nodes[type]
		var selected := int(_selected.get(type, 0))
		var available := int(row.available)
		nodes.row.selected_count = selected
		nodes.row.set_meta("available", available)
		nodes.row.set_meta("selected", selected)
		nodes.row.queue_redraw()
		nodes.portrait.sample = row.sample.duplicate(true)
		nodes.portrait.visuals = row.visuals.duplicate(true)
		nodes.portrait.heroic_2d = heroic_2d
		nodes.portrait.custom_minimum_size.x = 112 if row.visuals.size() > 1 else 64
		nodes.portrait.set_meta("sample", row.sample.duplicate(true))
		nodes.portrait.tooltip_text = str(row.caption)
		nodes.portrait.queue_redraw()
		nodes.caption.text = str(row.caption)
		nodes.caption.tooltip_text = str(row.caption) + " · 来源现有%d名" % available
		nodes.count.text = "%d/%d" % [selected, available]
		nodes.minus.disabled = not _route_enabled or selected <= 0
		nodes.plus.disabled = not _route_enabled or selected >= available
		nodes.half.disabled = not _route_enabled
		nodes.all.disabled = not _route_enabled
		nodes.minus.tooltip_text = "减少1名" + str(row.caption)
		nodes.plus.tooltip_text = "增加1名" + str(row.caption)
		nodes.half.tooltip_text = "选择该兵种半数（向上取整）"
		nodes.all.tooltip_text = "选择该兵种当前全部存活成员"
	set_meta("rows", rows_snapshot())
	set_meta("total_selected", total_selected())
	set_meta("route_enabled", _route_enabled)


func _amount_button(caption: String, node_name: String, width: float) -> Button:
	var button := TextButton.new()
	button.name = node_name
	button.text = caption
	button.custom_minimum_size = Vector2(width, 48)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	# Let a drag starting over the quantity controls reach the owning scroll
	# surface, which cancels the button press and stops the whole touch session.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	return button


func _label(caption: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_override("font", ReadableFont.readable())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("e0e4d5"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _type_order(rows: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for row: Dictionary in rows: result.append(str(row.unit_type))
	return result
