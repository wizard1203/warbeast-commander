extends Control
## Read-only shop projection. All purchases, sales and uses are host signals.
signal purchase_requested(item_id: String)
signal sell_requested(item_id: String)
signal use_requested(item_id: String)
signal hero_selected(unit_id: String)
signal item_selected(item_id: String)
signal category_changed(category: String)
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Bag = preload("res://src/presentation/strategic_hero_bag_bar.gd")
const Icon = preload("res://src/presentation/strategic_icon_button.gd")
const TextButton = preload("res://src/presentation/strategic_text_button.gd")
const Costs = preload("res://src/presentation/strategic_cost_readout.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const UITheme = preload("res://src/presentation/strategic_ui_theme.gd")
const OutpostShopReadout = preload("res://src/presentation/strategic_outpost_shop_readout.gd")
const CATEGORIES := {"BASIC":"初级装备", "ADVANCED":"合成装备", "AURA":"团队光环", "CONSUMABLE":"消耗品"}
const ERRORS := {"BATTLE_IS_TERMINAL":"战斗已结束", "INVALID_HERO":"选择存活英雄", "SHOP_INACTIVE":"主基地已失守", "SHOP_TOO_FAR":"靠近己方商店", "ITEM_OWNERSHIP_LIMIT":"持有已达上限", "CONSUMABLE_SLOTS_FULL":"仅容纳2种药剂", "EQUIPMENT_SLOTS_FULL":"4个装备槽已满", "COMPONENTS_REQUIRED":"缺少两件组件", "INSUFFICIENT_RESOURCES":"资源不足", "ITEM_COOLDOWN":"消耗品冷却中", "UNIT_STUNNED":"眩晕中无法使用", "FULL_HEALTH":"生命已满", "NO_ITEM_BENEFIT":"当前无需使用", "NO_ITEM_CHARGES":"没有剩余药剂"}
var _snapshot: Dictionary = {}
var _hero: Dictionary = {}
var _unit_id := ""
var _category := "BASIC"
var _item_id := "POTION"
var _bag: Control
var _status: Label
var _detail: Label
var _use: Button
var _sell: Button
var _scroll: ScrollContainer
var _grid: Control
var _hero_choice: OptionButton
var _choices_signature := ""
var view_side := "PLAYER"
var read_only := false

func configure(facts: Dictionary, unit_id: String, category: String, item_id: String, side_id: String = "PLAYER", readonly: bool = false) -> void:
	view_side = side_id
	read_only = readonly
	size = Vector2(780, 426)
	_unit_id = unit_id
	_category = category if CATEGORIES.has(category) else "BASIC"
	_item_id = item_id
	_hero_choice = OptionButton.new()
	_hero_choice.name = "ShopHeroChoice"
	_hero_choice.position = Vector2.ZERO
	_hero_choice.size = Vector2(236, 44)
	_hero_choice.add_theme_font_override("font",ReadableFont.readable())
	_hero_choice.add_theme_font_size_override("font_size",18)
	for state: String in ["normal","hover","pressed","disabled","focus"]:
		_hero_choice.add_theme_stylebox_override(state,UITheme.style(state,"hero"))
	_hero_choice.add_theme_color_override("font_color",Color("e6ddc7"))
	_hero_choice.add_theme_color_override("font_hover_color",Color("f0dfb3"))
	_hero_choice.add_theme_color_override("font_pressed_color",Color("f0dfb3"))
	_hero_choice.add_theme_color_override("font_disabled_color",Color("8f9a8c"))
	# The native popup keeps its normal keyboard/touch selection behavior while
	# sharing the same crisp panel and focus ramp as the selected hero field.
	var hero_menu := _hero_choice.get_popup()
	hero_menu.add_theme_stylebox_override("panel",UITheme.style("normal","panel"))
	hero_menu.add_theme_stylebox_override("hover",UITheme.style("selected","hero"))
	hero_menu.add_theme_font_override("font",ReadableFont.readable())
	hero_menu.add_theme_font_size_override("font_size",18)
	hero_menu.add_theme_color_override("font_color",Color("e6ddc7"))
	hero_menu.add_theme_color_override("font_hover_color",Color("f0dfb3"))
	hero_menu.add_theme_color_override("font_disabled_color",Color("8f9a8c"))
	_hero_choice.item_selected.connect(func(index: int): hero_selected.emit(str(_hero_choice.get_item_metadata(index))))
	add_child(_hero_choice)
	_status = _label("", Vector2(260, 0), Vector2(510, 48), 16)
	_status.name = "HeroShopServiceFacts"
	_bag = Bag.new()
	_bag.name = "ShopHeroBag"
	_bag.position = Vector2(0, 54)
	_bag.use_requested.connect(func(id: String): _request_action("use", id))
	_bag.inspect_requested.connect(_choose)
	_bag.shop_requested.connect(func(): _set_category("CONSUMABLE"))
	add_child(_bag)
	_detail = _label("", Vector2(0, 220), Vector2(238, 140), 14)
	_detail.name = "ShopItemDescription"
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.clip_text = true
	_use = _button("使用1份", "UseSelectedItem", Vector2(0, 368), Vector2(112, 48))
	_use.pressed.connect(func(): _request_action("use", _item_id))
	_sell = _button("出售1件", "SellSelectedItem", Vector2(122, 368), Vector2(112, 48))
	_sell.pressed.connect(func(): _request_action("sell", _item_id))
	var index := 0
	for category_id: String in CATEGORIES:
		var button := _button(str(CATEGORIES[category_id]), "ShopCategory" + category_id, Vector2(260 + index * 127, 54), Vector2(120, 44))
		button.pressed.connect(_set_category.bind(category_id))
		index += 1
	_scroll = ScrollContainer.new()
	_scroll.name = "InventoryItemsScroll"
	_scroll.position = Vector2(260, 108)
	_scroll.size = Vector2(514, 308)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(_grid)
	_build_cards()
	refresh(facts, unit_id, view_side, read_only)

func refresh(facts: Dictionary, unit_id: String, side_id: String = "PLAYER", readonly: bool = false) -> void:
	view_side = side_id
	read_only = readonly
	_snapshot = facts
	_unit_id = unit_id
	_hero = {}
	var choices: Array[Dictionary] = []
	for hero: Dictionary in facts.get("heroes", {}).get("officers", []):
		if hero.get("side") != view_side: continue
		choices.append(hero)
		if str(hero.get("unit_id", "")) == unit_id: _hero = hero
	var signature := str(choices.map(func(h: Dictionary): return [h.get("unit_id", ""), h.get("alive", false)]))
	if signature != _choices_signature:
		_choices_signature = signature
		_hero_choice.clear()
		for hero: Dictionary in choices:
			_hero_choice.add_item(str(hero.get("name", "英雄")) + (" · 失能" if not hero.get("alive", false) else ""))
			_hero_choice.set_item_metadata(_hero_choice.item_count - 1, str(hero.get("unit_id", "")))
	for index: int in range(_hero_choice.item_count):
		if str(_hero_choice.get_item_metadata(index)) == unit_id: _hero_choice.select(index)
	_bag.refresh(_hero, int(facts.get("tick", 0)), _reason(_interaction_reason()))
	var service := _service_reason()
	_status.text = "己方固定英雄商店 · 近距交易" if service.is_empty() else _reason(service)
	_status.tooltip_text = "原主基地旁固定商店；不可新建、不占人口。英雄需在280距离内；装备共4格，消耗品2种各2份，合成费另收。"
	if bool(facts.get("outpost_mode", false)):
		_status.text = "己方据点商店 · 近距交易" if service.is_empty() else _reason(service)
		_status.tooltip_text = "资源根据地或人口据点的英雄商店空位可确认建造。商店需存活、完工，所属据点完全由己方控制；不要求其他基地存活。自动选择英雄280距离内最近的合法商店。装备共4格，消耗品2种各2份，合成费另收。"
	for item_id: String in Items.ITEMS:
		var buy := _grid.find_child("BuyItem" + item_id, true, false) as Button
		if buy == null: continue
		var reason := _purchase_reason(item_id)
		buy.disabled = not reason.is_empty()
		buy.text = _reason(reason) if not reason.is_empty() else "合成" if Items.ITEMS[item_id].has("components") else "购买 +1"
		buy.tooltip_text = str(Items.ITEMS[item_id].description) + "\n" + ("可交易" if reason.is_empty() else _reason(reason))
		var costs := _grid.find_child("ItemCost" + item_id, true, false) as Control
		if costs != null:
			var quote:=Items.purchase_quote(_hero,item_id)
			costs.refresh(quote.get("cost",Items.total_cost(item_id)), facts.get("economy", {}).get(view_side, {}).get("stock", {}))
			if Items.ITEMS[item_id].has("components"): costs.tooltip_text += "\n本次费用为缺失组件价＋合成费；已持有组件抵扣价格并用于合成。合成后最多携带4件装备。"
	for category_id: String in CATEGORIES:
		var button := find_child("ShopCategory" + category_id, true, false) as Button
		button.set_meta("selected", _category == category_id)
		button.queue_redraw()
	_refresh_detail()

func _build_cards() -> void:
	for child: Node in _grid.get_children(): _grid.remove_child(child); child.queue_free()
	var index := 0
	for id: String in Items.ITEMS:
		var item: Dictionary = Items.ITEMS[id]
		if item.tier != _category: continue
		var origin := Vector2((index % 2) * 250, (index / 2) * 124)
		var icon := Icon.new()
		icon.name = "Item" + id
		icon.symbol = id
		icon.caption = ""
		icon.position = origin
		icon.custom_minimum_size = Vector2(58, 68)
		icon.tooltip_text = str(item.name) + "\n" + str(item.description)
		icon.pressed.connect(_choose.bind(id))
		_grid.add_child(icon)
		var label := _label(str(item.name), Vector2.ZERO, Vector2(180, 25), 16)
		remove_child(label)
		_grid.add_child(label)
		label.position = origin + Vector2(64, 0)
		var cost := Costs.new()
		cost.name = "ItemCost" + id
		cost.position = origin + Vector2(64, 28)
		cost.size = Vector2(176, 30)
		cost.cost = Items.total_cost(id)
		cost.tooltip_text = "缺失组件可直接补购；卡片按所选英雄背包显示本次实付" if item.has("components") else "单件价格"
		_grid.add_child(cost)
		var buy := TextButton.new()
		buy.name = "BuyItem" + id
		buy.position = origin + Vector2(64, 64)
		buy.custom_minimum_size = Vector2(176, 48)
		buy.pressed.connect(func(): _request_action("buy", id))
		_grid.add_child(buy)
		index += 1
	_grid.custom_minimum_size = Vector2(500, ceili(float(index) / 2.0) * 124)

func _choose(id: String) -> void:
	_item_id = id
	item_selected.emit(id)
	_refresh_detail()

func _request_action(kind: String, item_id: String) -> void:
	if read_only: return
	match kind:
		"buy": purchase_requested.emit(item_id)
		"sell": sell_requested.emit(item_id)
		"use": use_requested.emit(item_id)

func _set_category(category: String) -> void:
	_category = category
	category_changed.emit(category)
	_scroll.scroll_vertical = 0
	_build_cards()
	refresh(_snapshot, _unit_id, view_side, read_only)

func _refresh_detail() -> void:
	var item: Dictionary = Items.ITEMS.get(_item_id, {})
	var description := str(item.get("name", "选择图标查看装备")) + "\n" + str(item.get("description", "初级与高级装备共用4格；购买后立即生效。"))
	if item.has("components"):
		var names: Array[String] = []
		for component: String in item.components: names.append(str(Items.ITEMS[component].name))
		description += "\n组件：" + " + ".join(names)
	_detail.text = description
	_detail.tooltip_text = description
	var usable := Items.validate_use(_hero, _hero, _item_id, int(_snapshot.get("tick", 0))) if not _hero.is_empty() else {"accepted":false,"error":"INVALID_HERO"}
	for slot:Dictionary in _hero.get("consumable_slots",[]):
		if slot.item_id==_item_id:usable={"accepted":bool(slot.can_use),"error":str(slot.error)}
	var interaction := _interaction_reason()
	if not interaction.is_empty(): usable = {"accepted":false,"error":interaction}
	_use.disabled = not bool(_hero.get("alive", false)) or not bool(usable.accepted)
	_use.tooltip_text = "单击消耗1份；" + ("可使用" if usable.accepted else _reason(str(usable.error)))
	var service := _service_reason()
	_sell.disabled = not service.is_empty() or int(_hero.get("inventory", {}).get(_item_id, 0)) < 1
	var refund := Items.sell_refund(_item_id)
	_sell.tooltip_text = "仅近距商店出售一份；按金币总投入40%%向下取整，返还%d金币，不扣人口维护费。" % int(refund.get("MATERIAL", 0))
	if not service.is_empty(): _sell.tooltip_text = _reason(service) + "\n" + _sell.tooltip_text

func _interaction_reason() -> String:
	# Inspecting a retained shop after the final tick is still useful, but
	# no item action can settle after the authority has frozen the match.
	return "OBSERVER_ONLY" if read_only else "BATTLE_IS_TERMINAL" if _snapshot.get("outcome", "ONGOING") != "ONGOING" else ""

func _service_reason() -> String:
	var interaction := _interaction_reason()
	if not interaction.is_empty(): return interaction
	if bool(_snapshot.get("outpost_mode", false)):
		return str(OutpostShopReadout.read(_snapshot, _unit_id, view_side).get("reason", "SHOP_INACTIVE"))
	if _hero.is_empty() or not _hero.get("alive", false): return "INVALID_HERO"
	var base_alive := false
	var shop: Dictionary = {}
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") != view_side: continue
		if building.get("building_type") == "BASE" and str(building.get("id", "")) == view_side.to_lower() + "_base_01" and int(building.get("hp", 0)) > 0: base_alive = true
		if building.get("building_type") == "SHOP": shop = building
	if shop.is_empty() or not base_alive: return "SHOP_INACTIVE"
	if Vector2(_hero.get("position", Vector2.ZERO)).distance_squared_to(Vector2(shop.position)) > Items.SHOP_RANGE * Items.SHOP_RANGE: return "SHOP_TOO_FAR"
	return ""

func _purchase_reason(id: String) -> String:
	var reason := _service_reason()
	if not reason.is_empty(): return reason
	var quote:=Items.purchase_quote(_hero,id)
	if not quote.accepted: return str(quote.error)
	var stock: Dictionary = _snapshot.get("economy", {}).get(view_side, {}).get("stock", {})
	for resource:String in quote.cost:
		if int(stock.get(resource,0))<int(quote.cost[resource]):return "INSUFFICIENT_RESOURCES"
	return ""

func _reason(id: String) -> String:
	if id == "OBSERVER_ONLY": return "观战只读"
	if id == "SHOP_INACTIVE" and bool(_snapshot.get("outpost_mode", false)): return "没有可交易的己方完工商店；请完整控制其据点"
	return str(ERRORS.get(id, id))

func _label(text: String, point: Vector2, extent: Vector2, pixels: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = point
	label.size = extent
	label.clip_text = true
	label.add_theme_font_override("font", ReadableFont.readable())
	label.add_theme_font_size_override("font_size", pixels)
	add_child(label)
	return label

func _button(text: String, id: String, point: Vector2, extent: Vector2) -> Button:
	var button := TextButton.new()
	button.name = id
	button.text = text
	button.position = point
	button.custom_minimum_size = extent
	add_child(button)
	return button
