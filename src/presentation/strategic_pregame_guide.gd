extends Control
## A detached field guide over the frozen lobby. No Session reference, start
## button, or gameplay signal: faction browsing cannot change match setup.
const Catalog = preload("res://src/presentation/strategic_pregame_catalog.gd")
const Card = preload("res://src/presentation/strategic_pregame_card.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const TextButton = preload("res://src/presentation/strategic_text_button.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const Cost = preload("res://src/presentation/strategic_cost_readout.gd")
var _panel: Panel
var _faction_option: OptionButton
var _title: Label
var _subtitle: Label
var _close: Button
var _tabs_scroll: ScrollContainer
var _tabs_row: HBoxContainer
var _tabs: Dictionary = {}
var _cards_scroll: ScrollContainer
var _cards_grid: GridContainer
var _details: Panel
var _detail_title: Label
var _preview: Control
var _cost: Control
var _description: RichTextLabel
var _faction_id := "HUMAN"
var _category := "IDENTITY"
var _selected := ""
var _entries: Array[Dictionary] = []
var _cards: Dictionary = {}

class Preview extends Control:
	var record: Dictionary = {}
	func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if not record.is_empty(): Card.draw_preview(self,Rect2(Vector2(8,8),size-Vector2(16,16)),record)

func _ready() -> void:
	name = "PregameFieldGuide"
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events = false
	visible = false
	var shade := ColorRect.new()
	shade.name = "PregameGuideBackdrop"
	shade.color = Color(0.01,0.018,0.02,0.96)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_panel = Panel.new()
	_panel.name = "PregameGuidePanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel",Chrome.style("normal","lobby"))
	add_child(_panel)
	_title = _label("战前图鉴",26)
	_title.name = "PregameGuideTitle"
	_subtitle = _label("三族 · 21种兵 · 24名英雄",15)
	_close = TextButton.new()
	_close.name = "PregameGuideClose"
	_close.text = "返回大厅"
	_close.custom_minimum_size = Vector2(136,48)
	_close.pressed.connect(close_guide)
	_panel.add_child(_close)
	_faction_option = OptionButton.new()
	_faction_option.name = "PregameGuideFaction"
	_faction_option.add_theme_font_override("font",ReadableFont.readable())
	_faction_option.add_theme_font_size_override("font_size",20)
	for state: String in ["normal","hover","pressed"]: _faction_option.add_theme_stylebox_override(state,Chrome.style(state,"stone"))
	for id: String in Factions.IDS:
		_faction_option.add_item(str(Factions.profile(id).label))
		_faction_option.set_item_metadata(_faction_option.item_count-1,id)
	_faction_option.item_selected.connect(func(index: int): set_faction(str(_faction_option.get_item_metadata(index))))
	_panel.add_child(_faction_option)
	_tabs_scroll = _scroll("PregameGuideCategoryScroll",true)
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation",8)
	_tabs_scroll.add_child(_tabs_row)
	for category: Dictionary in Catalog.CATEGORIES:
		var tab := TextButton.new()
		tab.name = "PregameCategory_" + str(category.id)
		tab.text = str(category.label)
		tab.custom_minimum_size = Vector2(148 if category.id=="ECONOMY" else 124 if category.id=="ITEMS" else 108,48)
		tab.mouse_filter = Control.MOUSE_FILTER_PASS
		tab.toggle_mode = true
		tab.pressed.connect(set_category.bind(str(category.id)))
		_tabs_row.add_child(tab)
		_tabs[str(category.id)] = tab
	_cards_scroll = _scroll("PregameGuideCards",false)
	_cards_grid = GridContainer.new()
	_cards_grid.name = "PregameGuideCardGrid"
	_cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_grid.add_theme_constant_override("h_separation",10)
	_cards_grid.add_theme_constant_override("v_separation",10)
	_cards_scroll.add_child(_cards_grid)
	_details = Panel.new()
	_details.name = "PregameGuideDetailPanel"
	_details.mouse_filter = Control.MOUSE_FILTER_STOP
	_details.add_theme_stylebox_override("panel",Chrome.style("normal","stone"))
	_panel.add_child(_details)
	_detail_title = _label("",23,_details)
	_detail_title.name = "PregameGuideDetailTitle"
	_preview = Preview.new()
	_preview.name = "PregameGuideDetailPreview"
	_details.add_child(_preview)
	_cost = Cost.new()
	_cost.name = "PregameGuideDetailCosts"
	_cost.font_size = 21
	_details.add_child(_cost)
	_description = RichTextLabel.new()
	_description.name = "PregameGuideDescription"
	_description.bbcode_enabled = true
	_description.scroll_active = true
	_description.scroll_following = false
	_description.selection_enabled = true
	_description.mouse_filter = Control.MOUSE_FILTER_STOP
	_description.add_theme_font_override("normal_font",ReadableFont.readable())
	_description.add_theme_font_override("bold_font",ReadableFont.readable())
	_description.add_theme_font_size_override("normal_font_size",19)
	_description.add_theme_font_size_override("bold_font_size",20)
	_description.add_theme_color_override("default_color",Color("dddcc6"))
	_details.add_child(_description)
	resized.connect(_layout)
	_layout()
	_refresh_entries()

func open_for_faction(faction_id: String, category: String = "IDENTITY") -> void:
	_faction_id = faction_id if Factions.is_valid(faction_id) else "HUMAN"
	_category = category
	visible = true
	set_faction(_faction_id)
	set_category(_category)
	move_to_front()

func close_guide() -> void:
	visible = false
	_faction_option.get_popup().hide()
	release_focus()

func set_faction(id: String) -> void:
	if not Factions.is_valid(id): return
	_faction_id = id
	for index: int in range(_faction_option.item_count):
		if _faction_option.get_item_metadata(index) == id: _faction_option.select(index)
	_title.text = "%s · 战前图鉴" % Factions.profile(id).label
	_selected = ""
	_refresh_entries()

func set_category(id: String) -> void:
	if not _tabs.has(id): return
	_category = id
	_selected = ""
	_refresh_entries()

func select_entry(id: String) -> void:
	for record: Dictionary in _entries:
		if str(record.id) != id: continue
		_selected = id
		for key: String in _cards:
			_cards[key].selected = key==id
			_cards[key].queue_redraw()
		_detail_title.text = str(record.label)
		_preview.record = record.duplicate(true)
		_preview.queue_redraw()
		_cost.visible = not record.cost.is_empty() or int(record.population)>=0
		_cost.show_resources = not bool(record.get("contextual_hero_cost",false))
		_cost.refresh(record.cost,{},int(record.population))
		_description.text = str(record.description)
		_description.scroll_to_line(0)
		set_meta("selected_entry",record.duplicate(true))
		set_meta("selected_entry_id",id)
		call_deferred("_scroll_to_selected")
		return

func _scroll_to_selected() -> void:
	if _cards.has(_selected): _cards_scroll.ensure_control_visible(_cards[_selected])

func visible_entry_ids() -> Array[String]:
	var result: Array[String] = []
	for record: Dictionary in _entries: result.append(str(record.id))
	return result

func _label(text: String, font_size: int, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",ReadableFont.readable())
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("eee1bf"))
	label.clip_text = true
	(parent if parent != null else _panel).add_child(label)
	return label

func _scroll(node_name: String, horizontal: bool) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = node_name
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.mouse_force_pass_scroll_events = false
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER if horizontal else ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if horizontal else ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 12
	_panel.add_child(scroll)
	if not horizontal: scroll.get_v_scroll_bar().custom_minimum_size.x = 20
	return scroll

func _refresh_entries() -> void:
	if _cards_grid == null: return
	for child: Node in _cards_grid.get_children():
		_cards_grid.remove_child(child)
		child.queue_free()
	_cards.clear()
	_entries = Catalog.entries(_faction_id,_category)
	for record: Dictionary in _entries:
		var card := Card.new()
		card.name = "PregameEntry_" + str(record.id)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.refresh(record)
		card.pressed.connect(select_entry.bind(str(record.id)))
		_cards_grid.add_child(card)
		_cards[str(record.id)] = card
	for id: String in _tabs: _tabs[id].set_pressed_no_signal(id==_category)
	_cards_scroll.scroll_vertical = 0
	set_meta("faction_id",_faction_id)
	set_meta("category",_category)
	set_meta("entry_count",_entries.size())
	if not _entries.is_empty(): select_entry(str(_entries[0].id))
	_layout()

func _layout() -> void:
	if _panel == null: return
	_panel.size = Vector2(minf(1220,maxf(size.x-24,320)),minf(840,maxf(size.y-24,320)))
	_panel.position = (size-_panel.size)*0.5
	var width := _panel.size.x-32
	var height := _panel.size.y
	_title.position = Vector2(18,12)
	_title.size = Vector2(width-152,36)
	_close.position = Vector2(_panel.size.x-154,12)
	_close.size = Vector2(136,48)
	_subtitle.position = Vector2(18,54)
	_subtitle.size = Vector2(width,26)
	_faction_option.position = Vector2(18,87)
	_faction_option.size = Vector2(minf(width,290),48)
	_tabs_scroll.position = Vector2(18,145)
	_tabs_scroll.size = Vector2(width,50)
	var content_top := 208.0
	var available := height-content_top-18
	var stacked := _panel.size.x<890
	if stacked:
		var cards_height := maxf(155,available*0.42)
		_cards_scroll.position = Vector2(18,content_top)
		_cards_scroll.size = Vector2(width,cards_height)
		_details.position = Vector2(18,content_top+cards_height+10)
		_details.size = Vector2(width,maxf(available-cards_height-10,80))
	else:
		var left_width := floorf(width*0.47)
		_cards_scroll.position = Vector2(18,content_top)
		_cards_scroll.size = Vector2(left_width,available)
		_details.position = Vector2(28+left_width,content_top)
		_details.size = Vector2(width-left_width-10,available)
	_cards_grid.columns = maxi(1,floori((_cards_scroll.size.x-20+10)/220.0))
	var detail_width := _details.size.x
	_detail_title.position = Vector2(14,9)
	_detail_title.size = Vector2(detail_width-28,34)
	var compact := stacked
	_preview.position = Vector2(detail_width-105,46) if compact else Vector2(detail_width-166,42)
	_preview.size = Vector2(92,80) if compact else Vector2(150,118)
	_cost.position = Vector2(14,60)
	_cost.size = Vector2(maxf(detail_width-_preview.size.x-40,130),40)
	var body_top := 131.0 if compact else 166.0
	_description.position = Vector2(14,body_top)
	_description.size = Vector2(detail_width-28,maxf(_details.size.y-body_top-12,1))
	set_meta("layout_mode","stacked" if stacked else "side_by_side")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not _panel.get_global_rect().has_point(get_global_mouse_position()): close_guide()
	if event is InputEventScreenTouch and event.pressed and not _panel.get_global_rect().has_point(event.position): close_guide()
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag: accept_event()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_guide()
		get_viewport().set_input_as_handled()
