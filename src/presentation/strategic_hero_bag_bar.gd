extends Control
## A selected hero's real six-slot projection. This view never grants or uses
## items itself; every action returns to the ordinary authoritative command.
signal use_requested(item_id: String)
signal inspect_requested(item_id: String)
signal shop_requested
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Icon = preload("res://src/presentation/strategic_icon_button.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const SHORT := {"POTION":"红药","MANA_POTION":"蓝药","RESTORATION_DRAUGHT":"复苏","CLEANSE_DRAUGHT":"净化","GUARD_DRAUGHT":"铁肤","HASTE_DRAUGHT":"轻步"}
const REASONS := {"FULL_HEALTH":"生命已满", "NO_ITEM_BENEFIT":"当前无需使用", "ITEM_COOLDOWN":"消耗品共用冷却中", "UNIT_STUNNED":"眩晕中无法使用", "NO_ITEM_CHARGES":"没有剩余份数", "INVALID_UNIT":"英雄已经失能", "EMPTY_SLOT":"空槽位"}
var _title: Label
var _consumables: Array[Button] = []
var _equipment: Array[Button] = []
var _slots: Dictionary = {}
var _hero_id := ""
var _action_block_reason := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(218, 160)
	_title = Label.new()
	_title.name = "BagHeroName"
	_title.add_theme_font_override("font", ReadableFont.readable())
	_title.add_theme_font_size_override("font_size", 14)
	_title.size = Vector2(218, 20)
	_title.clip_text = true
	add_child(_title)
	for index: int in range(2):
		var button := Icon.new()
		button.name = "ConsumableSlot%d" % index
		button.position = Vector2(index * 73, 22)
		button.custom_minimum_size = Vector2(68, 66)
		button.size = button.custom_minimum_size
		button.pressed.connect(_use_slot.bind(index))
		add_child(button)
		_consumables.append(button)
	var shop := Icon.new()
	shop.name = "BagShopButton"
	shop.symbol = "SHOP"
	shop.caption = "商店"
	shop.position = Vector2(146, 22)
	shop.custom_minimum_size = Vector2(68, 66)
	shop.size = shop.custom_minimum_size
	shop.tooltip_text = "打开该英雄的独立行囊与商店；购买/出售需英雄靠近己方固定商店。"
	shop.pressed.connect(func(): shop_requested.emit())
	add_child(shop)
	for index: int in range(4):
		var button := Icon.new()
		button.name = "EquipmentSlot%d" % index
		button.position = Vector2(index * 55, 94)
		button.custom_minimum_size = Vector2(50, 64)
		button.size = button.custom_minimum_size
		button.pressed.connect(_inspect_slot.bind(index))
		add_child(button)
		_equipment.append(button)

func refresh(hero: Dictionary, tick: int, action_block_reason: String = "") -> void:
	if _title == null: return
	# Item validity and match-level action permission are distinct projections.
	# Default preserves standalone callers; hosts may block terminal interaction.
	_action_block_reason = action_block_reason
	_hero_id = str(hero.get("unit_id", hero.get("member_id", "")))
	_slots = Items.slot_snapshot(hero, tick)
	# Combat already validated nearby ally benefit. Recalculating from this
	# detached hero alone would incorrectly disable full-health group healers.
	for field:String in ["equipment_slots","consumable_slots","equipment_slot_limit","consumable_slot_limit","item_cooldown_ticks"]:
		if hero.has(field):_slots[field]=hero[field].duplicate(true) if hero[field] is Array else hero[field]
	_title.text = "%s · 独立行囊" % str(hero.get("name", "英雄"))
	set_meta("unit_id", _hero_id)
	var remaining := float(_slots.item_cooldown_ticks) / 20.0
	for index: int in range(2):
		var slot: Dictionary = _slots.consumable_slots[index]
		var id := str(slot.item_id)
		var item: Dictionary = Items.ITEMS.get(id, {})
		var button: Button = _consumables[index]
		button.symbol = id
		button.caption = "%s×%d" % [SHORT.get(id, "药剂"), int(slot.count)] if not id.is_empty() else "空"
		button.disabled = not _action_block_reason.is_empty() or not bool(hero.get("alive", false)) or not bool(slot.can_use)
		button.cooldown = remaining if not id.is_empty() else 0.0
		button.tooltip_text = str(item.get("name", "空消耗品槽")) + "\n" + str(item.get("description", "最多2种消耗品，每种最多2份；在固定商店购买。"))
		if not _action_block_reason.is_empty(): button.tooltip_text += "\n当前：" + _action_block_reason
		elif not id.is_empty() and not bool(slot.can_use): button.tooltip_text += "\n当前：" + str(REASONS.get(str(slot.error), "暂时不能使用"))
		button.set_meta("item_id", id)
		button.set_meta("unit_id", _hero_id)
		button.queue_redraw()
	for index: int in range(4):
		var id := str(_slots.equipment_slots[index])
		var item: Dictionary = Items.ITEMS.get(id, {})
		var button: Button = _equipment[index]
		button.symbol = id
		button.caption = str(item.get("name", "空")).left(3)
		button.selected = not id.is_empty()
		button.tooltip_text = str(item.get("name", "空装备槽")) + "\n" + str(item.get("description", "初级、高级装备共用4格；空格可在商店填入。"))
		button.set_meta("item_id", id)
		button.set_meta("unit_id", _hero_id)
		button.queue_redraw()

func detached_slots() -> Dictionary:
	return {"unit_id":_hero_id, "slots":_slots.duplicate(true)}

func _use_slot(index: int) -> void:
	if _slots.is_empty() or not _action_block_reason.is_empty(): return
	var slot: Dictionary = _slots.consumable_slots[index]
	if bool(slot.can_use): use_requested.emit(str(slot.item_id))

func _inspect_slot(index: int) -> void:
	if _slots.is_empty(): return
	var id := str(_slots.equipment_slots[index])
	if id.is_empty(): shop_requested.emit()
	else: inspect_requested.emit(id)
