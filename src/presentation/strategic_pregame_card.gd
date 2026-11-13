extends Button
## Pixel identities use the exact battlefield renderer; other entries use the
## established licensed/fallback command icons. Selection is inspection only.
const CatalogCard = preload("res://src/presentation/strategic_catalog_card.gd")
const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const Cost = preload("res://src/presentation/strategic_cost_readout.gd")
var facts: Dictionary = {}
var selected := false
var _cost: Control

func _ready() -> void:
	custom_minimum_size = Vector2(210,154)
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	for state: String in ["normal","hover","pressed","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	_cost = Cost.new()
	_cost.name = "PregameCardCosts"
	_cost.font_size = 15
	add_child(_cost)
	resized.connect(_layout)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	_layout()
	_refresh_cost()

func refresh(record: Dictionary) -> void:
	facts = record.duplicate(true)
	tooltip_text = str(facts.get("label","")) + " · 单击查看完整资料"
	set_meta("entry_id",str(facts.get("id","")))
	_refresh_cost()
	queue_redraw()

func _layout() -> void:
	if _cost == null: return
	_cost.position = Vector2(9,size.y-30)
	_cost.size = Vector2(size.x-18,24)

func _refresh_cost() -> void:
	if _cost == null: return
	_cost.visible = not facts.get("cost",{}).is_empty() or int(facts.get("population",-1)) >= 0
	_cost.show_resources = not bool(facts.get("contextual_hero_cost",false))
	_cost.refresh(facts.get("cost",{}),{},int(facts.get("population",-1)))

func _draw() -> void:
	var fill := Color("26383c") if selected else Color("1d2c30")
	if is_hovered(): fill = fill.lightened(0.07)
	if is_pressed(): fill = fill.darkened(0.13)
	draw_style_box(CatalogCard._surface(fill,selected),Rect2(Vector2.ZERO,size))
	draw_string(ReadableFont.readable(),Vector2(10,24),str(facts.get("label","")),HORIZONTAL_ALIGNMENT_LEFT,size.x-20,18,Color("eee0bf"))
	var art := Rect2(10,36,82,78)
	draw_preview(self,art,facts)
	draw_string(ReadableFont.readable(),Vector2(100,62),str(facts.get("role","")),HORIZONTAL_ALIGNMENT_LEFT,size.x-108,15,Color("b8c9b3"))
	var tier := int(facts.get("required_tier",0))
	var prerequisite := "首发择一免费" if bool(facts.get("contextual_hero_cost",false)) else "需%d级基地" % tier if tier > 0 else "单击查看"
	draw_string(ReadableFont.readable(),Vector2(100,88),prerequisite,HORIZONTAL_ALIGNMENT_LEFT,size.x-108,14,Color("d1b786"))
	if selected: draw_rect(Rect2(size.x-17,9,7,7),Color("e4c477"))
	if _cost != null and _cost.visible: draw_line(Vector2(10,size.y-34),Vector2(size.x-10,size.y-34),Color("5e6456"),1)
	set_meta("painted_preview_kind",str(facts.get("kind","ICON")))

static func draw_preview(canvas: Object, rect: Rect2, record: Dictionary) -> void:
	if record.get("kind") in ["UNIT","BUILDING"]: CatalogCard.draw_visual(canvas,rect,record)
	else: Icons.draw_symbol(canvas,str(record.get("icon","army")),rect.get_center(),Color("e0c991"),minf(rect.size.x,rect.size.y)/48.0)

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
