extends Control
## A detached, read-only projection of the arena's current force model. The
## owner supplies counts, canonical prices and the existing strength estimate;
## this widget never queries a Host, catalog, forecast or battle simulator.
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const Fonts = preload("res://src/presentation/strategic_font.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const TooltipGate = preload("res://src/presentation/strategic_native_tooltip_gate.gd")
const SIDE_ORDER := ["PLAYER", "AI"]
const MIN_WIDTH := 430.0
const GRID_WIDTH := 760.0
const PADDING := 7.0
const SIDE_GAP := 12.0
const CHIP_GAP := 6.0
const HEADER_HEIGHT := 29.0
const FOOTER_HEIGHT := 11.0

var _model: Dictionary = {}
var _available := false

func _ready() -> void:
	name = "ArenaForceOverlayR19"
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	resized.connect(_on_resized)
	_on_resized()
	tooltip_text = _summary_help()

func refresh(model: Dictionary) -> void:
	# Copy the small display model, not the battlefield. Invalid or legacy
	# observations clear stale rows instead of manufacturing a zero score.
	var next: Dictionary = _project(model)
	if next == _model: return
	_model = next
	_available = not _model.is_empty()
	custom_minimum_size = minimum_panel_size()
	tooltip_text = _summary_help()
	queue_redraw()

func minimum_panel_size(width: float = -1.0) -> Vector2:
	var actual_width: float = maxf(MIN_WIDTH, size.x if width < 0.0 else width)
	var columns: int = 2 if actual_width >= GRID_WIDTH else 1
	var max_rows: int = 0
	for side: String in SIDE_ORDER:
		max_rows = maxi(max_rows, _model.get("sides", {}).get(side, {}).get("rows", []).size())
	var row_count: int = maxi(1, ceili(float(max_rows) / float(columns)))
	var row_height: float = 17.0 if columns == 2 else 16.0
	return Vector2(MIN_WIDTH, PADDING * 2.0 + HEADER_HEIGHT + row_height * row_count + FOOTER_HEIGHT)

func inspect() -> Dictionary:
	var layout: Dictionary = _layout()
	return {
		"available": _available,
		"tick": int(_model.get("tick", -1)),
		"sides": _model.get("sides", {}).duplicate(true),
		"preferred_size": minimum_panel_size(),
		"columns_per_side": int(layout.columns),
		"row_rects": layout.rows.duplicate(true),
		"mouse_filter": mouse_filter,
		"score_label": "战力估算",
		"count_label": "存活 / 开战总数",
	}

func _on_resized() -> void:
	custom_minimum_size = minimum_panel_size()
	queue_redraw()

func _project(model: Dictionary) -> Dictionary:
	var tick: Variant = model.get("tick", null)
	var sides: Variant = model.get("sides", null)
	if typeof(tick) != TYPE_INT or int(tick) < 0 or not sides is Dictionary: return {}
	var result: Dictionary = {"tick": int(tick), "sides": {}}
	for side: String in SIDE_ORDER:
		var source: Variant = sides.get(side, null)
		if not source is Dictionary: return {}
		var strength: Variant = source.get("strength", null)
		if not _number(strength) or float(strength) < 0.0: return {}
		for field: String in ["alive", "total", "alive_population", "initial_population"]:
			if typeof(source.get(field, null)) != TYPE_INT or int(source[field]) < 0: return {}
		if int(source.alive) > int(source.total): return {}
		var source_rows: Variant = source.get("rows", null)
		if not source_rows is Array: return {}
		var projected: Dictionary = {
			"label": str(source.get("label", "左方" if side == "PLAYER" else "右方")),
			"faction_label": str(source.get("faction_label", "")),
			"alive": int(source.alive), "total": int(source.total),
			"alive_population": int(source.alive_population),
			"initial_population": int(source.initial_population),
			"strength": float(strength), "rows": [],
		}
		var seen: Dictionary = {}
		for row: Variant in source_rows:
			if not row is Dictionary: return {}
			var key: String = str(row.get("key", ""))
			if key.is_empty() or seen.has(key): return {}
			seen[key] = true
			for field: String in ["alive", "total", "population_each", "initial_population"]:
				if typeof(row.get(field, null)) != TYPE_INT or int(row[field]) < 0: return {}
			var hero: bool = bool(row.get("hero", false))
			var gold: Variant = row.get("gold_each", null)
			if typeof(gold) != TYPE_INT or int(gold) < (-1 if hero else 0): return {}
			if int(row.alive) > int(row.total): return {}
			var share: Variant = row.get("population_share", null)
			if not _number(share) or float(share) < 0.0 or float(share) > 1.0: return {}
			projected.rows.append({
				"key": key, "unit_type": str(row.get("unit_type", "")),
				"label": str(row.get("label", key)), "hero": hero,
				"alive": int(row.alive), "total": int(row.total),
				"gold_each": int(row.gold_each), "population_each": int(row.population_each),
				"initial_population": int(row.initial_population), "population_share": float(share),
			})
		result.sides[side] = projected
	return result

func _number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

func _layout() -> Dictionary:
	var actual_width: float = maxf(MIN_WIDTH, size.x)
	var columns: int = 2 if actual_width >= GRID_WIDTH else 1
	var row_height: float = 17.0 if columns == 2 else 16.0
	var side_width: float = floorf((actual_width - PADDING * 2.0 - SIDE_GAP) / 2.0)
	var chip_width: float = floorf((side_width - CHIP_GAP * float(columns - 1)) / float(columns))
	var rows: Array[Dictionary] = []
	for side_index: int in range(SIDE_ORDER.size()):
		var side: String = str(SIDE_ORDER[side_index])
		var left: float = PADDING + float(side_index) * (side_width + SIDE_GAP)
		var source_rows: Array = _model.get("sides", {}).get(side, {}).get("rows", [])
		for index: int in range(source_rows.size()):
			var row: Dictionary = source_rows[index]
			var box := Rect2(
				Vector2(left + float(index % columns) * (chip_width + CHIP_GAP), PADDING + HEADER_HEIGHT + floorf(float(index) / float(columns)) * row_height),
				Vector2(chip_width, row_height)
			)
			rows.append({"side": side, "key": str(row.key), "rect": box, "row_index": index})
	return {"columns": columns, "side_width": side_width, "rows": rows}

func _draw() -> void:
	Chrome.draw_material(self, Rect2(Vector2.ZERO, size), "strip")
	if not _available:
		_caption(Vector2(PADDING + 3.0, 23.0), "兵力统计待开战 · 战力为估算，并非胜率", 12, Color("bdbea6"), size.x - 24.0)
		return
	var layout: Dictionary = _layout()
	var side_width: float = float(layout.side_width)
	var divider_x: float = floorf(size.x / 2.0)
	draw_rect(Rect2(divider_x, PADDING, 1.0, size.y - PADDING * 2.0), Color("665b41"))
	for side_index: int in range(SIDE_ORDER.size()):
		var side: String = str(SIDE_ORDER[side_index])
		var source: Dictionary = _model.sides[side]
		var left: float = PADDING + float(side_index) * (side_width + SIDE_GAP)
		var tint: Color = Palette.side_color(side)
		draw_rect(Rect2(left, PADDING + 2.0, 3.0, 10.0), tint)
		var identity: String = str(source.label) + (" · " + str(source.faction_label) if not str(source.faction_label).is_empty() else "")
		var score_width: float = minf(125.0, side_width * 0.54)
		_caption(Vector2(left + 7.0, PADDING + 12.0), identity, 12, tint.lightened(0.25), side_width - score_width - 10.0)
		_caption(Vector2(left + side_width - score_width, PADDING + 12.0), "战力估算 %s" % _score_text(float(source.strength)), 11, Color("f0ddab"), score_width, HORIZONTAL_ALIGNMENT_RIGHT)
		_caption(Vector2(left + 1.0, PADDING + 26.0), "兵力 %d/%d  ·  人口 %d/%d" % [int(source.alive), int(source.total), int(source.alive_population), int(source.initial_population)], 11, Color("b7bba4"), side_width - 2.0)
	for entry: Dictionary in layout.rows:
		var row: Dictionary = _model.sides[entry.side].rows[int(entry.row_index)]
		var box: Rect2 = entry.rect
		var tint: Color = Palette.side_color(str(entry.side))
		var dead: bool = int(row.alive) == 0
		if bool(row.hero):
			draw_rect(box.grow(-1.0), Color(tint, 0.08))
			draw_rect(Rect2(box.position + Vector2(1.0, 5.0), Vector2(3.0, 6.0)), Color("e3c575") if not dead else Color("696b5a"))
		else:
			draw_rect(Rect2(box.position + Vector2(1.0, 5.0), Vector2(2.0, 5.0)), tint.darkened(0.6) if dead else tint)
		var count_width: float = minf(52.0, box.size.x * 0.32)
		_caption(box.position + Vector2(7.0, 12.0), str(row.label), 11, Color("777e70") if dead else Color("d3d3b8"), box.size.x - count_width - 10.0)
		_caption(box.position + Vector2(box.size.x - count_width, 12.0), "%d/%d" % [int(row.alive), int(row.total)], 12, Color("8c8e79") if dead else Color("f0e1b8"), count_width - 2.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_caption(Vector2(PADDING + 2.0, size.y - PADDING + 2.0), "各兵种：存活/开战总数 · 估算非胜率 · 悬浮/长按查看单价、人口及占比", 10, Color("a9ae97"), size.x - PADDING * 2.0 - 4.0)

func _caption(point: Vector2, text: String, font_size: int, ink: Color, width: float, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if width <= 0.0: return
	var fitted: String = _fit(text, font_size, width)
	draw_string(Fonts.readable(), point + Vector2(0.0, 1.0), fitted, alignment, width, font_size, Color("0c1515"))
	draw_string(Fonts.readable(), point, fitted, alignment, width, font_size, ink)

func _fit(text: String, font_size: int, width: float) -> String:
	var font: Font = Fonts.readable()
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x <= width: return text
	var shortened: String = text
	while not shortened.is_empty():
		shortened = shortened.left(shortened.length() - 1)
		if font.get_string_size(shortened + "…", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x <= width: return shortened + "…"
	return ""

func _score_text(value: float) -> String:
	if value >= 100000000.0: return "%.1f亿" % (value / 100000000.0)
	if value >= 10000.0: return "%.1f万" % (value / 10000.0)
	return "%.0f" % value

func _summary_help() -> String:
	if not _available: return "等待当前竞技场兵力观察；没有有效数据时不沿用上一局。"
	var lines: Array[String] = ["竞技场兵力 · 只读", "数量为当前存活 / 本次开战总数；阵亡清理不会减少总数。", "人口为当前存活人口 / 开战人口；兵种占比使用开战人口。", "战力为当前在场战斗实力估算，并非胜率，不含库存或累计成绩。"]
	for side: String in SIDE_ORDER:
		var source: Dictionary = _model.sides[side]
		lines.append("%s · %s：兵力 %d/%d，人口 %d/%d，战力估算 %.1f。" % [str(source.label), str(source.faction_label), int(source.alive), int(source.total), int(source.alive_population), int(source.initial_population), float(source.strength)])
	lines.append("悬浮或长按兵种，查看单价、人口及队内占比。")
	return "\n".join(lines)

func _help_at(point: Vector2) -> String:
	if not _available: return _summary_help()
	for entry: Dictionary in _layout().rows:
		var box: Rect2 = entry.rect
		if not box.has_point(point): continue
		var source: Dictionary = _model.sides[entry.side]
		var row: Dictionary = source.rows[int(entry.row_index)]
		var price: String = "单价 %d 金币" % int(row.gold_each)
		if bool(row.hero) and int(row.gold_each) < 0:
			price = "英雄费用随初始获得、招募或复活而变化，请在对应面板查看"
		return "%s · %s\n存活 %d / 开战总数 %d\n%s · 每名 %d 人口\n开战共 %d 人口，占本方 %.1f%%\n战力为估算值，不代表胜率。" % [str(source.label), str(row.label), int(row.alive), int(row.total), price, int(row.population_each), int(row.initial_population), float(row.population_share) * 100.0]
	return _summary_help()

func _get_tooltip(at_position: Vector2) -> String:
	tooltip_text = _help_at(at_position)
	return TooltipGate.native_text(self)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		tooltip_text = _help_at(event.position)
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		tooltip_text = _help_at(event.position)
	# Both native GUI propagation and the stage's unhandled selection path
	# stop here. Long-press help can still inspect tooltip_text from this node.
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		accept_event()
