class_name StrategicCatalogGrid
extends Control
## Recruit/build share this presentation-only module. Entries retain node
## identity when categories change; more entries add scroll depth, not tiny cards.

signal item_chosen(item_id: String)

const Card = preload("res://src/presentation/strategic_catalog_card.gd")
const CatalogFont = preload("res://src/presentation/strategic_font.gd")
const CARD_SIZE := Vector2(174, 148)
const CATEGORY_HEIGHT := 44.0
const GAP := 8
var _items: Array[Dictionary] = []
var _categories: Array[Dictionary] = []
var _prefix := "CatalogItem_"
var _category := "ALL"
var _selected := ""
var _cards: Dictionary = {}
var _tabs: Dictionary = {}
var _tab_scroll: ScrollContainer
var _tab_row: HBoxContainer
var _scroll: ScrollContainer
var _grid: GridContainer
var _empty: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_ensure_nodes()
	resized.connect(_layout)
	_layout()

func configure(items: Array, categories: Array, node_prefix: String = "CatalogItem_") -> void:
	_ensure_nodes()
	_prefix = node_prefix
	for id: String in _cards: _cards[id].name = _prefix + id
	_categories.clear()
	for category: Dictionary in categories: _categories.append(category.duplicate(true))
	if _categories.is_empty(): _categories.append({"id":"ALL", "label":"全部"})
	_build_tabs()
	refresh_items(items)
	var known := false
	for category: Dictionary in _categories:
		if str(category.get("id", "")) == _category: known = true
	if not known: _category = str(_categories[0].get("id", "ALL"))
	_apply_filter()

func refresh_items(items: Array) -> void:
	_ensure_nodes()
	if items == _items: return
	var normalized: Array[Dictionary] = []
	var seen: Dictionary = {}
	for value: Dictionary in items:
		var id := str(value.get("id", ""))
		if id.is_empty() or seen.has(id): continue
		seen[id] = true
		normalized.append(value.duplicate(true))
	# Arena observations refresh every rendered frame. Unchanged catalog facts
	# must not queue sorts/redraws or disturb the player's scroll session.
	if normalized == _items: return
	_items = normalized
	var retained: Dictionary = {}
	var index := 0
	for item: Dictionary in _items:
		var id := str(item["id"])
		retained[id] = true
		var card: Button = _cards.get(id)
		if card == null:
			card = Card.new()
			card.custom_minimum_size = CARD_SIZE
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.pressed.connect(_choose.bind(id))
			_cards[id] = card
			_grid.add_child(card)
		card.name = _prefix + id
		card.refresh(item)
		_grid.move_child(card, index)
		index += 1
	for id: String in _cards.keys():
		if retained.has(id): continue
		var obsolete: Button = _cards[id]
		_grid.remove_child(obsolete)
		obsolete.queue_free()
		_cards.erase(id)
	select_item(_selected)
	_apply_filter()
	_layout()

func select_item(id: String) -> void:
	_selected = id
	for key: String in _cards:
		var card: Button = _cards[key]
		var chosen := key == id
		if card.selected == chosen and bool(card.get_meta("selected", false)) == chosen: continue
		card.selected = chosen
		card.set_meta("selected", chosen)
		card.queue_redraw()

func set_category(id: String) -> void:
	for category: Dictionary in _categories:
		if str(category.get("id", "")) != id: continue
		_category = id
		_scroll.scroll_vertical = 0
		_apply_filter()
		return

func visible_item_ids() -> Array[String]:
	var result: Array[String] = []
	for item: Dictionary in _items:
		var id := str(item.get("id", ""))
		if _cards[id].visible: result.append(id)
	return result

func item_button(id: String) -> Button:
	return _cards.get(id)

func _ensure_nodes() -> void:
	if _grid != null: return
	_tab_scroll = ScrollContainer.new()
	_tab_scroll.name = "CatalogCategoryScroll"
	_tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_tab_scroll)
	_tab_row = HBoxContainer.new()
	_tab_row.name = "CatalogCategoryRow"
	_tab_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_tab_row.add_theme_constant_override("separation", GAP)
	_tab_scroll.add_child(_tab_row)
	_scroll = ScrollContainer.new()
	_scroll.name = "CatalogScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll.follow_focus = false
	_scroll.scroll_deadzone = 12
	add_child(_scroll)
	_scroll.get_v_scroll_bar().custom_minimum_size.x = 20
	_grid = GridContainer.new()
	_grid.name = "CatalogCards"
	_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", GAP)
	_grid.add_theme_constant_override("v_separation", GAP)
	_scroll.add_child(_grid)
	_empty = Label.new()
	_empty.name = "CatalogEmptyReason"
	_empty.text = "此分类暂无条目"
	_empty.add_theme_font_override("font", CatalogFont.readable())
	_empty.add_theme_font_size_override("font_size", 18)
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_empty)

func _build_tabs() -> void:
	for child: Node in _tab_row.get_children():
		_tab_row.remove_child(child)
		child.queue_free()
	_tabs.clear()
	for category: Dictionary in _categories:
		var id := str(category.get("id", "ALL"))
		var tab := Button.new()
		tab.name = "CatalogCategory_" + id
		tab.text = str(category.get("label", id))
		tab.custom_minimum_size = Vector2(96, CATEGORY_HEIGHT)
		tab.focus_mode = Control.FOCUS_NONE
		tab.mouse_filter = Control.MOUSE_FILTER_PASS
		tab.toggle_mode = true
		tab.add_theme_font_override("font", CatalogFont.readable())
		tab.add_theme_font_size_override("font_size", 16)
		for state: String in ["normal", "hover", "pressed"]:
			tab.add_theme_stylebox_override(state, Card._surface(Color("2c4547") if state == "pressed" else Color("1a2a2e"), state == "pressed"))
		tab.pressed.connect(set_category.bind(id))
		_tab_row.add_child(tab)
		_tabs[id] = tab

func _apply_filter() -> void:
	if _grid == null: return
	var count := 0
	for item: Dictionary in _items:
		var categories: Array = item.get("categories", [str(item.get("category", ""))])
		var shown := _category == "ALL" or _category in categories
		_cards[str(item["id"])].visible = shown
		if shown: count += 1
	for id: String in _tabs: _tabs[id].set_pressed_no_signal(id == _category)
	_empty.visible = count == 0
	set_meta("category", _category)
	set_meta("visible_item_count", count)
	_grid.queue_sort()

func _layout() -> void:
	if _grid == null: return
	_tab_scroll.position = Vector2.ZERO
	_tab_scroll.size = Vector2(size.x, CATEGORY_HEIGHT)
	# Drop old column minimums before sizing the scroll surface. Otherwise a
	# wide-to-narrow resize can retain the previous wider ScrollContainer size.
	_grid.columns = maxi(1, floori((maxf(size.x - 20, CARD_SIZE.x) + GAP) / (CARD_SIZE.x + GAP)))
	_scroll.position = Vector2(0, CATEGORY_HEIGHT + GAP)
	_scroll.size = Vector2(size.x, maxf(size.y - CATEGORY_HEIGHT - GAP, 1))
	_empty.position = Vector2(12, CATEGORY_HEIGHT + 26)
	_empty.size = Vector2(maxf(size.x - 24, 1), 40)
	_grid.queue_sort()

func _choose(id: String) -> void:
	select_item(id)
	item_chosen.emit(id)
