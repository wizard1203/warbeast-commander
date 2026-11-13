extends Button
## A small read-only consumer, not a second score/economy model. Main owns dock
## placement, shared help, modal precedence and the detailed-table navigation.
signal details_requested

const MatchScores = preload("res://src/simulation/strategic_match_scores_m72.gd")
const UITheme = preload("res://src/presentation/strategic_ui_theme.gd")
const Fonts = preload("res://src/presentation/strategic_font.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const TooltipGate = preload("res://src/presentation/strategic_native_tooltip_gate.gd")
const SIDE_ORDER := ["PLAYER","AI","AI_2","AI_3"]
const FULL_SIZE := Vector2(228,74)
const COMPACT_SIZE := Vector2(208,74)

var _rows: Array[Dictionary] = []
var _available := false
var _tick := -1
var _tick_ms := 50
var _view_side := "PLAYER"
var _compact_requested := false
var _fingerprint := ""

func _ready() -> void:
	name = "StrengthScoreHUD"
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for state: String in ["normal","hover","pressed","disabled"]:
		add_theme_stylebox_override(state,UITheme.style(state,"strip"))
	pressed.connect(func(): details_requested.emit())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	custom_minimum_size = minimum_panel_size()
	_update_explanation()

func refresh(snapshot: Dictionary, context: Dictionary = {}) -> void:
	# Validate against this observation, never a live Host or a later replay
	# frame. Copy only the few consumed values, not the large battlefield.
	_view_side = str(context.get("view_side",_view_side))
	var frame_tick: Variant = snapshot.get("tick",null)
	var scores: Variant = snapshot.get("match_scores",{})
	_rows.clear()
	_available = false
	_tick = -1
	_tick_ms = 50
	var tick_length: Variant = snapshot.get("tick_ms",50)
	if typeof(tick_length) == TYPE_INT and int(tick_length) > 0 and int(tick_length) <= 1000:
		_tick_ms = int(tick_length)
	if typeof(frame_tick) == TYPE_INT and int(frame_tick) >= 0 and scores is Dictionary and not scores.is_empty() and MatchScores.validate_snapshot(scores,int(frame_tick)):
		_tick = int(scores.tick)
		var participants: Dictionary = _participant_labels(snapshot)
		for side_id: String in SIDE_ORDER:
			if not scores.sides.has(side_id): continue
			var source: Dictionary = scores.sides[side_id]
			var slot: Dictionary = participants.get(side_id,{})
			var faction_id := str(slot.get("faction_id",""))
			var faction: Dictionary = Factions.FACTIONS.get(faction_id,{})
			_rows.append({"side_id":side_id,"label":Palette.side_label(side_id),"faction_id":faction_id,"faction_label":str(faction.get("label","")),"current_total":float(source.current.total),"accumulated_total":float(source.accumulated.total),"viewed":side_id == _view_side,"color":Palette.side_color(side_id)})
		_available = not _rows.is_empty()
	var current := str([_rows,_tick,_tick_ms,_compact_requested])
	if current == _fingerprint: return
	_fingerprint = current
	custom_minimum_size = minimum_panel_size()
	_update_explanation()
	queue_redraw()

func set_compact(value: bool) -> void:
	if value == _compact_requested: return
	_compact_requested = value
	custom_minimum_size = minimum_panel_size()
	queue_redraw()

func minimum_panel_size() -> Vector2:
	return COMPACT_SIZE if _compact_requested or _rows.size() > 2 else FULL_SIZE

func inspect() -> Dictionary:
	return {"available":_available,"tick":_tick,"compact":_compact_requested or _rows.size()>2,"preferred_size":minimum_panel_size(),"rows":_rows.duplicate(true)}

func _participant_labels(snapshot: Dictionary) -> Dictionary:
	var participants: Variant = snapshot.get("sides",[])
	var config: Variant = snapshot.get("match_config",{})
	if config is Dictionary: participants = config.get("sides",participants)
	var result := {}
	if participants is Array:
		for slot: Variant in participants:
			if not slot is Dictionary: continue
			var side_id := str(slot.get("side_id",""))
			if side_id in SIDE_ORDER:
				result[side_id] = {"faction_id":str(slot.get("faction_id",""))}
	return result

func _update_explanation() -> void:
	var lines: Array[String] = ["当前全军实力 · 资产／就绪度指数，并非胜率。"]
	if _available:
		lines.append("计分时刻 %.1f 秒，约每逻辑秒更新。" % (float(_tick)*float(_tick_ms)/1000.0))
		for row: Dictionary in _rows:
			var identity := str(row.label) + (" · " + str(row.faction_label) if not str(row.faction_label).is_empty() else "")
			lines.append("%s：当前 %.1f；累计表现 %.1f。" % [identity,float(row.current_total),float(row.accumulated_total)])
	else:
		lines.append("当前观察暂无有效评分；旧录像缺失时不会补造，也不沿用上一局数值。")
	lines.append("当前由军队、建筑、经济、在场英雄、装备和已完成科技相加；经济含库存，不等于已转化战力。")
	lines.append("累计表现与历史峰值单列，不混入当前总分；这不是局部交战胜率。")
	lines.append("单击查看全军实力评分细目；查看、悬浮或长按不下达军令。")
	tooltip_text = "\n".join(lines)

func _draw() -> void:
	var state := "pressed" if is_pressed() else "hover" if is_hovered() else "normal"
	UITheme.draw_surface(self,Rect2(Vector2.ZERO,size),"strip",state)
	_caption(Vector2(10,16),"全军实力 · 估算",13,Color("daca9e"),size.x-70)
	_caption(Vector2(size.x-65,16),"%.0fs" % (float(_tick)*float(_tick_ms)/1000.0) if _available else "—",11,Color("a9ad95"),54,HORIZONTAL_ALIGNMENT_RIGHT)
	if not _available:
		_caption(Vector2(10,46),"暂无评分 · 点开详情",13,Color("b5b6a3"),size.x-20)
		return
	var compact := _compact_requested or _rows.size()>2
	for index: int in range(_rows.size()):
		var row: Dictionary = _rows[index]
		var column := index % 2 if compact else 0
		var line := index / 2 if compact else index
		var width := (size.x-20)*0.5 if compact else size.x-16
		var box := Rect2(Vector2(8+column*width,21+line*23),Vector2(width-2 if compact else width,23))
		if bool(row.viewed):
			draw_rect(box,Color(row.color,0.09))
			draw_line(box.position+Vector2(6,22),box.end-Vector2(3,1),Color(row.color,0.38),1)
		draw_rect(Rect2(box.position+Vector2(1,6),Vector2(3,12)),Color("121a19"))
		draw_rect(Rect2(box.position+Vector2(2,6),Vector2(2,10)),row.color)
		var number := _score_text(float(row.current_total),compact)
		if compact:
			var identity := str(SIDE_ORDER.find(row.side_id)+1)+(" "+str(row.faction_label) if not str(row.faction_label).is_empty() else "")
			_caption(box.position+Vector2(8,16),identity,11,Color("cfc8af"),44)
			_caption(box.position+Vector2(48,16),number,14,Color("f0e2b7"),box.size.x-51,HORIZONTAL_ALIGNMENT_RIGHT)
		else:
			var identity := str(row.label)+(" · "+str(row.faction_label) if not str(row.faction_label).is_empty() else "")
			_caption(box.position+Vector2(10,17),identity,12,Color("d6ccb1"),box.size.x-89)
			_caption(box.position+Vector2(box.size.x-77,18),number,18,Color("f0e2b7"),70,HORIZONTAL_ALIGNMENT_RIGHT)
	if compact and _rows.size()<=2:
		_caption(Vector2(10,62),"点开查看六项实力与累计表现",11,Color("a9ad95"),size.x-20)

func _score_text(value: float, compact: bool) -> String:
	if value >= 100000000: return "%.1f亿" % (value/100000000.0)
	if value >= 10000: return "%.1f万" % (value/10000.0)
	return "%.0f" % value if compact else "%.1f" % value

func _caption(point: Vector2, caption: String, font_size: int, ink: Color, width: float, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(Fonts.readable(),point+Vector2(0,1),caption,alignment,width,font_size,Color("0d1516"))
	draw_string(Fonts.readable(),point,caption,alignment,width,font_size,ink)

func _get_tooltip(_at_position: Vector2) -> String:
	return TooltipGate.native_text(self)
