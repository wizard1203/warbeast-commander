extends RefCounted
## Closed, deterministic hero inventory rules. World owns payment; this helper
## owns capacity and atomic item transformations. No player payload is a grant.
const EQUIPMENT_SLOTS := 4
const CONSUMABLE_SLOTS := 2
const STACK_LIMIT := 2
const SHARED_COOLDOWN_TICKS := 400
const SHOP_RANGE := 280
const VERSION := "outposts-gold-items-v2"
const TechnologiesV4 = preload("res://src/simulation/strategic_faction_technologies_v4.gd")
const ITEMS := {
	"IRON_BLADE":{"id":"IRON_BLADE","name":"铁刃","icon":"sword","tier":"BASIC","damage_bonus":8,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":110,"ESSENCE":0},"description":"普攻+8。\n占一个装备栏。"},
	"WARD_MAIL":{"id":"WARD_MAIL","name":"护铠","icon":"armor","tier":"BASIC","armor_bonus":2,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":110,"ESSENCE":0},"description":"护甲+2。\n占一个装备栏。"},
	"FIELD_BOOTS":{"id":"FIELD_BOOTS","name":"行军靴","icon":"move","tier":"BASIC","move_speed_percent":8,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":105,"ESSENCE":0},"description":"移动速度+8%。\n占一个装备栏。"},
	"LONGSIGHT":{"id":"LONGSIGHT","name":"远望镜","icon":"bow","tier":"BASIC","range_bonus":20,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":115,"ESSENCE":0},"description":"普攻射程+20。\n占一个装备栏。"},
	"VITAL_CHARM":{"id":"VITAL_CHARM","name":"生命契石","icon":"health","tier":"BASIC","max_hp_bonus":100,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":120,"ESSENCE":0},"description":"最大生命+100。\n占一个装备栏，提高生命上限时不回复当前生命。"},
	"SPELL_LENS":{"id":"SPELL_LENS","name":"星契透镜","icon":"hero","tier":"BASIC","skill_damage_percent":8,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":130,"ESSENCE":0},"description":"技能伤害+8%。\n占一个装备栏。"},
	"SWIFT_GLOVES":{"id":"SWIFT_GLOVES","name":"疾锋手套","icon":"sword","tier":"BASIC","attack_speed_percent":10,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":120,"ESSENCE":0},"description":"攻击速度+10%。\n占一个装备栏。"},
	"NULL_CLOAK":{"id":"NULL_CLOAK","name":"静魔斗篷","icon":"armor","tier":"BASIC","magic_resist_percent":10,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":120,"ESSENCE":0},"description":"奥术抗性+10%。\n占一个装备栏。"},
	"MANA_CRYSTAL":{"id":"MANA_CRYSTAL","name":"蓄魔晶","icon":"mana","tier":"BASIC","max_mana_bonus":80,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":115,"ESSENCE":0},"description":"最大蓝量+80。\n占一个装备栏，提高蓝量上限时不回复当前蓝量。"},
	"REGEN_RING":{"id":"REGEN_RING","name":"复苏指环","icon":"health","tier":"BASIC","hp_regen_per_second":1.5,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":110,"ESSENCE":0},"description":"每秒生命回复+1.5。\n占一个装备栏。"},
	"MANA_BEAD":{"id":"MANA_BEAD","name":"潮息珠","icon":"mana","tier":"BASIC","mana_regen_per_second":0.75,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":115,"ESSENCE":0},"description":"每秒蓝量回复+0.75。\n占一个装备栏。"},
	"HEALERS_SEAL":{"id":"HEALERS_SEAL","name":"抚生印","icon":"health","tier":"BASIC","healing_percent":12,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":125,"ESSENCE":0},"description":"治疗效果+12%。\n占一个装备栏。"},
	"VANGUARD_BLADE":{"id":"VANGUARD_BLADE","name":"征锋契刃","icon":"sword","tier":"ADVANCED","damage_bonus":10,"max_hp_bonus":125,"drain_percent":6,"drain_cap":8,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":210,"ESSENCE":0},"components":["IRON_BLADE","VITAL_CHARM"],"description":"铁刃＋生命契石合成，可补购缺少的组件。\n普攻+10；最大生命+125；普攻吸血6%；单次吸血上限8。\n占一个装备栏，提高生命上限时不回复当前生命；死亡掉落。"},
	"WARDEN_CREST":{"id":"WARDEN_CREST","name":"守垒徽印","icon":"armor","tier":"ADVANCED","armor_bonus":3,"max_hp_bonus":125,"rest_regen":2,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":210,"ESSENCE":0},"components":["WARD_MAIL","VITAL_CHARM"],"description":"护铠＋生命契石合成，可补购缺少的组件。\n护甲+3；最大生命+125；脱战每2秒回血+2。\n占一个装备栏，提高生命上限时不回复当前生命；死亡掉落。"},
	"PATHFINDER_COMPASS":{"id":"PATHFINDER_COMPASS","name":"踏风罗盘","icon":"move","tier":"ADVANCED","move_speed_percent":10,"range_bonus":25,"march_regen":2,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":210,"ESSENCE":0},"components":["FIELD_BOOTS","LONGSIGHT"],"description":"行军靴＋远望镜合成，可补购缺少的组件。\n移动速度+10%；普攻射程+25；脱战行军每2秒回血+2。\n占一个装备栏；死亡掉落。"},
	"ARCANE_SIGIL":{"id":"ARCANE_SIGIL","name":"澄星秘印","icon":"hero","tier":"ADVANCED","skill_damage_percent":10,"max_hp_bonus":125,"mana_regen_per_second":0.3,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":225,"ESSENCE":0},"components":["SPELL_LENS","VITAL_CHARM"],"description":"星契透镜＋生命契石合成，可补购缺少的组件。\n最大生命+125；技能伤害+10%；每秒蓝量回复+0.3。\n占一个装备栏，提高生命上限时不回复当前生命；死亡掉落。"},
	"SWIFT_BLADE":{"id":"SWIFT_BLADE","name":"疾锋战刃","icon":"sword","tier":"ADVANCED","damage_bonus":10,"attack_speed_percent":12,"range_bonus":8,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":220,"ESSENCE":0},"components":["IRON_BLADE","SWIFT_GLOVES"],"description":"铁刃＋疾锋手套合成，可补购缺少的组件。\n普攻+10；普攻射程+8；攻击速度+12%。\n占一个装备栏；死亡掉落。"},
	"SPELLWEAVE":{"id":"SPELLWEAVE","name":"织星法器","icon":"hero","tier":"ADVANCED","skill_damage_percent":10,"max_mana_bonus":100,"mana_regen_per_second":0.4,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":225,"ESSENCE":0},"components":["SPELL_LENS","MANA_CRYSTAL"],"description":"星契透镜＋蓄魔晶合成，可补购缺少的组件。\n技能伤害+10%；最大蓝量+100；每秒蓝量回复+0.4。\n占一个装备栏，提高蓝量上限时不回复当前蓝量；死亡掉落。"},
	"NULL_AEGIS":{"id":"NULL_AEGIS","name":"静魔壁垒","icon":"armor","tier":"ADVANCED","magic_resist_percent":12,"armor_bonus":3,"control_resist_percent":8,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":220,"ESSENCE":0},"components":["NULL_CLOAK","WARD_MAIL"],"description":"静魔斗篷＋护铠合成，可补购缺少的组件。\n护甲+3；奥术抗性+12%；控制时长减少8%。\n占一个装备栏；死亡掉落。"},
	"EVERGREEN_CHARM":{"id":"EVERGREEN_CHARM","name":"长春契石","icon":"health","tier":"ADVANCED","max_hp_bonus":125,"hp_regen_per_second":1.9,"rest_regen":2,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":215,"ESSENCE":0},"components":["VITAL_CHARM","REGEN_RING"],"description":"生命契石＋复苏指环合成，可补购缺少的组件。\n最大生命+125；每秒生命回复+1.9；脱战每2秒回血+2。\n占一个装备栏，提高生命上限时不回复当前生命；死亡掉落。"},
	"DEEP_CURRENT":{"id":"DEEP_CURRENT","name":"深潮容器","icon":"mana","tier":"ADVANCED","max_mana_bonus":100,"mana_regen_per_second":0.95,"mana_on_kill":3,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":220,"ESSENCE":0},"components":["MANA_CRYSTAL","MANA_BEAD"],"description":"蓄魔晶＋潮息珠合成，可补购缺少的组件。\n最大蓝量+100；每秒蓝量回复+0.95；击杀回蓝+3。\n占一个装备栏，提高蓝量上限时不回复当前蓝量；死亡掉落。"},
	"MERCY_STAFF":{"id":"MERCY_STAFF","name":"抚生权杖","icon":"health","tier":"ADVANCED","healing_percent":15,"mana_regen_per_second":0.95,"hp_regen_per_second":0.75,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":220,"ESSENCE":0},"components":["HEALERS_SEAL","MANA_BEAD"],"description":"抚生印＋潮息珠合成，可补购缺少的组件。\n每秒生命回复+0.75；每秒蓝量回复+0.95；治疗效果+15%。\n占一个装备栏；死亡掉落。"},
	"HUNTERS_SCOPE":{"id":"HUNTERS_SCOPE","name":"猎阵长镜","icon":"bow","tier":"ADVANCED","range_bonus":25,"attack_speed_percent":12,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":225,"ESSENCE":0},"components":["LONGSIGHT","SWIFT_GLOVES"],"description":"远望镜＋疾锋手套合成，可补购缺少的组件。\n普攻射程+25；移动速度+2%；攻击速度+12%。\n占一个装备栏；死亡掉落。","move_speed_percent":2},
	"MARCHWARD":{"id":"MARCHWARD","name":"行阵护胫","icon":"move","tier":"ADVANCED","move_speed_percent":10,"armor_bonus":3,"control_resist_percent":8,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":215,"ESSENCE":0},"components":["FIELD_BOOTS","WARD_MAIL"],"description":"行军靴＋护铠合成，可补购缺少的组件。\n护甲+3；移动速度+10%；控制时长减少8%。\n占一个装备栏；死亡掉落。"},
	"WAR_STANDARD":{"id":"WAR_STANDARD","name":"远征军旗","icon":"rally","tier":"AURA","damage_bonus":10,"armor_bonus":3,"aura_damage":3,"aura_radius":200,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":850,"ESSENCE":0},"components":["IRON_BLADE","WARD_MAIL"],"description":"铁刃＋护铠合成，可补购缺少的组件。\n普攻+10；护甲+3；光环友军普攻+3；影响200范围内最多6名友军，同属性光环只取最高值。\n占一个装备栏；死亡掉落。"},
	"AEGIS_STANDARD":{"id":"AEGIS_STANDARD","name":"守誓军旗","icon":"armor","tier":"AURA","armor_bonus":3,"max_hp_bonus":125,"aura_armor":1,"aura_radius":200,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":850,"ESSENCE":0},"components":["WARD_MAIL","VITAL_CHARM"],"description":"护铠＋生命契石合成，可补购缺少的组件。\n护甲+3；最大生命+125；光环友军护甲+1；影响200范围内最多6名友军，同属性光环只取最高值。\n占一个装备栏，提高生命上限时不回复当前生命；死亡掉落。"},
	"SPRING_STANDARD":{"id":"SPRING_STANDARD","name":"长春战旗","icon":"health","tier":"AURA","max_hp_bonus":125,"hp_regen_per_second":1.9,"aura_heal":1,"aura_radius":200,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":850,"ESSENCE":0},"components":["VITAL_CHARM","REGEN_RING"],"description":"生命契石＋复苏指环合成，可补购缺少的组件。\n最大生命+125；每秒生命回复+1.9；光环每秒回血+1；影响200范围内最多6名友军，同属性光环只取最高值。\n占一个装备栏，提高生命上限时不回复当前生命；死亡掉落。"},
	"MANA_STANDARD":{"id":"MANA_STANDARD","name":"潮息战旗","icon":"mana","tier":"AURA","max_mana_bonus":100,"mana_regen_per_second":0.95,"aura_mana_regen":0.25,"aura_radius":200,"max_owned":1,"cost":{"FOOD":0,"MATERIAL":850,"ESSENCE":0},"components":["MANA_CRYSTAL","MANA_BEAD"],"description":"蓄魔晶＋潮息珠合成，可补购缺少的组件。\n最大蓝量+100；每秒蓝量回复+0.95；光环每秒回蓝+0.25；影响200范围内最多6名友军，同属性光环只取最高值。\n占一个装备栏，提高蓝量上限时不回复当前蓝量；死亡掉落。"},
	"POTION":{"id":"POTION","name":"生命药水","icon":"potion","tier":"CONSUMABLE","heal":200,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":50,"ESSENCE":0},"consumable":true,"description":"恢复200生命。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"MANA_POTION":{"id":"MANA_POTION","name":"魔力药水","icon":"mana","tier":"CONSUMABLE","mana":100,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":65,"ESSENCE":0},"consumable":true,"description":"恢复100蓝量。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"RESTORATION_DRAUGHT":{"id":"RESTORATION_DRAUGHT","name":"复苏合剂","icon":"health","tier":"CONSUMABLE","hp_regen_per_second":10,"mana_regen_per_second":5,"duration_ticks":200,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":80,"ESSENCE":0},"consumable":true,"description":"每秒生命回复+10；每秒蓝量回复+5；持续10秒。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"CLEANSE_DRAUGHT":{"id":"CLEANSE_DRAUGHT","name":"净化露","icon":"hero","tier":"CONSUMABLE","cleanse":true,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":65,"ESSENCE":0},"consumable":true,"description":"清除灼烧／中毒／减速。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"GUARD_DRAUGHT":{"id":"GUARD_DRAUGHT","name":"铁肤饮剂","icon":"armor","tier":"CONSUMABLE","armor_bonus":3,"duration_ticks":160,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":60,"ESSENCE":0},"consumable":true,"description":"护甲+3；持续8秒。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"HASTE_DRAUGHT":{"id":"HASTE_DRAUGHT","name":"轻步饮剂","icon":"move","tier":"CONSUMABLE","move_speed_percent":20,"duration_ticks":120,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":55,"ESSENCE":0},"consumable":true,"description":"移动速度+20%；持续6秒。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"ASSAULT_DRAUGHT":{"id":"ASSAULT_DRAUGHT","name":"急袭饮剂","icon":"sword","tier":"CONSUMABLE","attack_speed_percent":20,"duration_ticks":120,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":70,"ESSENCE":0},"consumable":true,"description":"攻击速度+20%；持续6秒。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"NULL_DRAUGHT":{"id":"NULL_DRAUGHT","name":"抗魔饮剂","icon":"armor","tier":"CONSUMABLE","magic_resist_percent":25,"duration_ticks":160,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":70,"ESSENCE":0},"consumable":true,"description":"奥术抗性+25%；持续8秒。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"SHIELD_DRAUGHT":{"id":"SHIELD_DRAUGHT","name":"护心饮剂","icon":"health","tier":"CONSUMABLE","shield_hp":120,"duration_ticks":160,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":75,"ESSENCE":0},"consumable":true,"description":"临时护盾120；持续8秒。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"GROUP_HEAL_DRAUGHT":{"id":"GROUP_HEAL_DRAUGHT","name":"军阵疗剂","icon":"health","tier":"CONSUMABLE","heal":100,"ally_heal":100,"ally_radius":180,"max_targets":4,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":120,"ESSENCE":0},"consumable":true,"description":"自身恢复100生命；180范围内最多4名其他存活友军各恢复100生命。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"ESSENCE_RESTORATION":{"id":"ESSENCE_RESTORATION","name":"灵髓复苏剂","icon":"health","tier":"CONSUMABLE","heal":350,"mana":160,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":200,"ESSENCE":0},"consumable":true,"description":"恢复350生命；恢复160蓝量。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
	"ESSENCE_BULWARK":{"id":"ESSENCE_BULWARK","name":"灵髓护阵剂","icon":"armor","tier":"CONSUMABLE","armor_bonus":5,"shield_hp":100,"duration_ticks":200,"max_owned":2,"cost":{"FOOD":0,"MATERIAL":200,"ESSENCE":0},"consumable":true,"description":"护甲+5；临时护盾100；持续10秒。\n所有消耗品共享20秒冷却。每种最多携带2份，可携带两种消耗品。"},
}

static func initial_inventory() -> Dictionary:
	var result := {}
	for id: String in ITEMS: result[id] = 2 if id == "POTION" else 0
	return result

static func drop_advanced(hero: Dictionary) -> Array[String]:
	# Trusted death settlement only. Unequipped owned gear is held inventory,
	# not a safe bank. Basic gear and every consumable survive paid recall.
	var dropped: Array[String] = []
	var inventory: Dictionary = hero.get("inventory", {})
	for item_id: String in ITEMS:
		if ITEMS[item_id].get("tier", "") not in ["ADVANCED", "AURA"]: continue
		var count := maxi(0, int(inventory.get(item_id, 0)))
		if count == 0: continue
		inventory[item_id] = 0
		hero.get("equipment", []).erase(item_id)
		for _index: int in range(count): dropped.append(item_id)
	return dropped

static func total_cost(item_id: String) -> Dictionary:
	if not ITEMS.has(item_id): return {}
	var result: Dictionary = ITEMS[item_id].cost.duplicate(true)
	for component: String in ITEMS[item_id].get("components", []):
		for resource: String in ITEMS[component].cost: result[resource] = int(result.get(resource, 0)) + int(ITEMS[component].cost[resource])
	return result

static func purchase_quote(hero: Dictionary, item_id: String) -> Dictionary:
	# Quotes are derived, never accepted from player payloads. World revalidates
	# immediately before charging and uses the returned authoritative cost.
	var valid := validate_gain(hero, item_id, true)
	if not valid.accepted: return valid
	var item: Dictionary = ITEMS[item_id]
	var cost: Dictionary = item.cost.duplicate(true)
	var consumed: Array[String] = []
	var inventory: Dictionary = hero.get("inventory", {})
	for component: String in item.get("components", []):
		if int(inventory.get(component, 0)) > 0:
			consumed.append(component)
		else:
			for resource: String in ITEMS[component].cost:
				cost[resource] = int(cost.get(resource, 0)) + int(ITEMS[component].cost[resource])
	return _accept({"item_id":item_id,"version":VERSION,"cost":cost,"consumed_components":consumed,"final_equipment_count":_held(hero, false).size() - consumed.size() + (0 if item.get("consumable", false) else 1)})

static func sell_refund(item_id: String) -> Dictionary:
	var result := total_cost(item_id)
	for resource: String in result: result[resource] = int(result[resource]) * 40 / 100
	return result

static func validate_sell(hero: Dictionary, item_id: String) -> Dictionary:
	if not ITEMS.has(item_id) or int(hero.get("inventory", {}).get(item_id, 0)) < 1: return _reject("ITEM_NOT_OWNED")
	return _accept()

static func sell_item(hero: Dictionary, item_id: String) -> Dictionary:
	var valid := validate_sell(hero, item_id)
	if not valid.accepted: return valid
	hero.inventory[item_id] = int(hero.inventory[item_id]) - 1
	if not ITEMS[item_id].get("consumable", false): hero.equipment.erase(item_id)
	return _accept({"item_id":item_id,"refund":sell_refund(item_id)})

static func validate_gain(hero: Dictionary, item_id: String, combine: bool = false) -> Dictionary:
	if not ITEMS.has(item_id): return _reject("INVALID_ITEM")
	var inventory: Dictionary = hero.get("inventory", {})
	var item: Dictionary = ITEMS[item_id]
	if int(inventory.get(item_id, 0)) >= int(item.max_owned): return _reject("ITEM_OWNERSHIP_LIMIT")
	if item.get("consumable", false):
		if int(inventory.get(item_id, 0)) == 0 and _held(hero, true).size() >= CONSUMABLE_SLOTS: return _reject("CONSUMABLE_SLOTS_FULL")
		return _accept()
	var removed := 0
	if combine and item.has("components"):
		for component: String in item.components:
			if int(inventory.get(component, 0)) > 0: removed += 1
	if _held(hero, false).size() - removed >= EQUIPMENT_SLOTS: return _reject("EQUIPMENT_SLOTS_FULL")
	return _accept()

static func grant_purchase(hero: Dictionary, item_id: String) -> Dictionary:
	return _grant(hero, item_id, true)

static func grant_loot(hero: Dictionary, item_id: String) -> Dictionary:
	return _grant(hero, item_id, false)

static func _grant(hero: Dictionary, item_id: String, combine: bool) -> Dictionary:
	var valid := validate_gain(hero, item_id, combine)
	if not valid.accepted: return valid
	var inventory: Dictionary = hero.inventory
	var equipment: Array = hero.equipment
	var components: Array = []
	if combine:
		for component: String in ITEMS[item_id].get("components", []):
			if int(inventory.get(component, 0)) > 0: components.append(component)
	for component: String in components:
		inventory[component] = int(inventory[component]) - 1
		equipment.erase(component)
	inventory[item_id] = int(inventory.get(item_id, 0)) + 1
	if not ITEMS[item_id].get("consumable", false): equipment.append(item_id)
	return _accept({"item_id":item_id,"consumed_components":components.duplicate()})

static func validate_equip(hero: Dictionary, item_id: String) -> Dictionary:
	if not ITEMS.has(item_id) or ITEMS[item_id].get("consumable", false) or int(hero.get("inventory", {}).get(item_id, 0)) < 1: return _reject("INVALID_ITEM")
	if item_id in hero.get("equipment", []): return _reject("ITEM_ALREADY_EQUIPPED")
	if _held(hero, false).size() > EQUIPMENT_SLOTS or hero.get("equipment", []).size() >= EQUIPMENT_SLOTS: return _reject("EQUIPMENT_SLOTS_FULL")
	return _accept()

static func secondary_status_kind(effect: Dictionary) -> String:
	# The status visible to players is also the status used by cleanse and
	# conditional passives. Retain the underlying event kind for settlement.
	return str(effect.get("status_kind", "BURN")) if str(effect.get("kind", "")) == "DAMAGE" else str(effect.get("kind", ""))

static func _status_active(status: Dictionary, tick: int) -> bool:
	return int(status.expires_tick) > tick if status.has("expires_tick") else int(status.get("remaining_ticks", 0)) > 0

static func has_cleansable_status(unit: Dictionary, kinds: Array, tick: int) -> bool:
	for status: Dictionary in unit.get("r7_statuses",{}).values():
		if str(status.get("kind","")) in kinds and _status_active(status,tick): return true
	# Authoritative bodies have keyed records, while detached observations
	# may deliberately expose only a status array. Never let a stale copied
	# array override present authority records.
	if unit.has("combat_statuses") or unit.has("secondary_effects"):
		for status: Dictionary in unit.get("combat_statuses", {}).values():
			if str(status.get("kind", "")) in kinds and _status_active(status, tick): return true
		for effect: Dictionary in unit.get("secondary_effects", {}).values():
			if secondary_status_kind(effect) in kinds and _status_active(effect, tick): return true
		return false
	for status: Dictionary in unit.get("status_effects", []):
		if str(status.get("kind", "")) in kinds and _status_active(status, tick): return true
	return false

static func cleanse_statuses(unit: Dictionary, kinds: Array, _tick: int) -> Dictionary:
	var removed:={"combat_status_ids":[], "secondary_effect_ids":[]}
	for key: String in unit.get("r7_statuses",{}).keys():
		if str(unit.r7_statuses[key].get("kind","")) in kinds:
			unit.r7_statuses.erase(key)
			removed.combat_status_ids.append(key)
	for key: String in unit.get("combat_statuses", {}).keys():
		if str(unit.combat_statuses[key].get("kind", "")) in kinds:
			unit.erase("status_damage_carry:"+str(unit.combat_statuses[key].get("kind","")))
			unit.combat_statuses.erase(key)
			removed.combat_status_ids.append(key)
	for key: String in unit.get("secondary_effects", {}).keys():
		var effect: Dictionary = unit.secondary_effects[key]
		if secondary_status_kind(effect) not in kinds: continue
		# Drop source-specific post-mitigation fractions with the cleansed DOT;
		# a later fresh application must not inherit its residual damage.
		if unit.has("secondary_damage_carry"): unit.secondary_damage_carry.erase(str(effect.get("id", key)))
		unit.secondary_effects.erase(key)
		removed.secondary_effect_ids.append(key)
	return removed

static func validate_use(hero: Dictionary, unit: Dictionary, item_id: String, tick: int, eligible_allies: Array = []) -> Dictionary:
	tick = maxi(0, tick)
	if not ITEMS.has(item_id) or not ITEMS[item_id].get("consumable", false): return _reject("INVALID_CONSUMABLE")
	if int(unit.get("hp", 0)) <= 0: return _reject("INVALID_UNIT")
	if int(unit.get("stun_until_tick", -1)) > tick: return _reject("UNIT_STUNNED")
	if int(hero.get("inventory", {}).get(item_id, 0)) <= 0: return _reject("NO_ITEM_CHARGES")
	if tick < int(hero.get("item_ready_tick", 0)): return _reject("ITEM_COOLDOWN")
	var item: Dictionary = ITEMS[item_id]
	var useful := int(item.get("heal", 0)) > 0 and int(unit.hp) < int(unit.max_hp)
	useful = useful or (int(item.get("mana", 0)) > 0 and int(hero.get("mana", 0)) < int(hero.get("max_mana", 0)))
	if int(item.get("ally_heal", 0)) > 0:
		# Host supplies already range/team/target-validated living allies; never
		# accept a client-provided boolean claiming the group would benefit.
		for ally: Dictionary in eligible_allies:
			if int(ally.get("hp", 0)) > 0 and int(ally.get("hp", 0)) < int(ally.get("max_hp", 0)): useful = true
	if item.get("cleanse", false):
		useful = useful or has_cleansable_status(unit, ["BURN", "POISON", "SLOW"], tick)
	if item.has("duration_ticks"):
		useful = int(hero.get("item_effects", {}).get(item_id, {}).get("expires_tick", -1)) <= tick
	if not useful: return _reject("FULL_HEALTH" if item_id == "POTION" else "NO_ITEM_BENEFIT")
	return _accept()

static func use_item(hero: Dictionary, unit: Dictionary, item_id: String, tick: int, eligible_allies: Array = [], technology_context:Dictionary={}) -> Dictionary:
	tick = maxi(0, tick)
	var valid := validate_use(hero, unit, item_id, tick, eligible_allies)
	if not valid.accepted: return valid
	var context:=TechnologiesV4.context_for(hero,technology_context)
	var item:Dictionary=TechnologiesV4.consumable_effect(ITEMS[item_id],str(context.get("faction","")),context.get("levels",{}))
	hero.inventory[item_id] = int(hero.inventory[item_id]) - 1
	hero["item_ready_tick"] = tick + SHARED_COOLDOWN_TICKS
	hero["last_item_id"] = item_id
	hero["last_item_tick"] = tick
	unit.hp = mini(int(unit.max_hp), int(unit.hp) + int(item.get("heal", 0)))
	hero.mana = mini(int(hero.max_mana), int(hero.mana) + int(item.get("mana", 0)))
	if item.get("cleanse", false):
		cleanse_statuses(unit, ["BURN", "POISON", "SLOW"], tick)
	if item.has("duration_ticks"):
		if not hero.has("item_effects"): hero["item_effects"] = {}
		var effect: Dictionary = item.duplicate(true)
		effect["expires_tick"] = tick + int(item.duration_ticks)
		effect["shield_remaining"] = int(item.get("shield_hp", 0))
		hero.item_effects[item_id] = effect
	return _accept({"item_id":item_id,"ready_tick":int(hero.item_ready_tick),"ally_heal":int(item.get("ally_heal", 0)),"ally_radius":int(item.get("ally_radius", 0)),"max_targets":int(item.get("max_targets", 0))})

static func active_bonus(hero: Dictionary, tick: int) -> Dictionary:
	var result := {"damage_bonus":0,"armor_bonus":0,"speed_bonus":0,"range_bonus":0,"max_hp_bonus":0,"attack_speed_percent":0,"move_speed_percent":0,"magic_resist_percent":0,"max_mana_bonus":0,"hp_regen_per_second":0.0,"mana_regen_per_second":0.0,"skill_damage_percent":0,"healing_percent":0,"control_resist_percent":0}
	for effect: Dictionary in hero.get("item_effects", {}).values():
		if int(effect.expires_tick) <= tick: continue
		for key: String in result: result[key] = maxf(float(result[key]), float(effect.get(key, 0)))
	return result

static func equipment_stats(hero: Dictionary, technology_context:Dictionary={}) -> Dictionary:
	# Percent fields are ordinary integer percentages (10 == +10%), not basis
	# points. Regeneration fields are floating HP/MP per second with carry.
	var result := {"damage_bonus":0,"armor_bonus":0,"speed_bonus":0,"range_bonus":0,"max_hp_bonus":0,"attack_speed_percent":0,"move_speed_percent":0,"magic_resist_percent":0,"max_mana_bonus":0,"hp_regen_per_second":0.0,"mana_regen_per_second":0.0,"skill_damage_percent":0,"healing_percent":0,"control_resist_percent":0,"mana_on_kill":0}
	for item_id: String in hero.get("equipment", []):
		var item: Dictionary = ITEMS.get(item_id, {})
		for key: String in result: result[key] += item.get(key, 0)
	var context:=TechnologiesV4.context_for(hero,technology_context)
	return TechnologiesV4.equipment_stats(result,str(context.get("faction","")),context.get("levels",{}))

static func equipment_skill_damage_percent(hero: Dictionary) -> int:
	return int(equipment_stats(hero).skill_damage_percent)

static func absorb_shield(hero: Dictionary, damage: int, tick: int) -> int:
	# One strongest surviving shield absorbs each hit, never stacks all shields.
	var chosen := ""
	var strength := 0
	for key: String in hero.get("item_effects", {}):
		var effect: Dictionary = hero.item_effects[key]
		if int(effect.get("expires_tick", -1)) > tick and int(effect.get("shield_remaining", 0)) > strength:
			chosen = key
			strength = int(effect.shield_remaining)
	if chosen.is_empty(): return maxi(0, damage)
	var absorbed := mini(strength, maxi(0, damage))
	hero.item_effects[chosen].shield_remaining -= absorbed
	return maxi(0, damage - absorbed)

static func equipment_aura(hero: Dictionary) -> Dictionary:
	var result := {"damage":0,"armor":0,"heal_per_second":0.0,"mana_per_second":0.0,"radius":0,"max_targets":6}
	for item_id: String in hero.get("equipment", []):
		var item: Dictionary = ITEMS.get(item_id, {})
		result.damage = maxi(int(result.damage), int(item.get("aura_damage", 0)))
		result.armor = maxi(int(result.armor), int(item.get("aura_armor", 0)))
		result.heal_per_second = maxf(float(result.heal_per_second), float(item.get("aura_heal", 0)))
		result.mana_per_second = maxf(float(result.mana_per_second), float(item.get("aura_mana_regen", 0)))
		result.radius = maxi(int(result.radius), int(item.get("aura_radius", 0)))
	return result

static func equipment_spell_bonus(hero: Dictionary, skill: Dictionary) -> int:
	# Legacy direct-damage adapter. New settlement uses the percentage function
	# once, also for physical skill damage and skill-owned periodic damage.
	return int(skill.get("damage", 0)) * equipment_skill_damage_percent(hero) / 100

static func equipment_drain(hero: Dictionary, actual_damage: int) -> int:
	var result := 0
	for item_id: String in hero.get("equipment", []):
		var item: Dictionary = ITEMS.get(item_id, {})
		result = maxi(result, mini(int(item.get("drain_cap", 0)), actual_damage * int(item.get("drain_percent", 0)) / 100))
	return result

static func tick_passives(hero: Dictionary, unit: Dictionary, tick: int, technology_context:Dictionary={}) -> void:
	if tick <= 0 or tick % 20 != 0 or int(unit.get("hp", 0)) <= 0: return
	var stats := equipment_stats(hero,technology_context)
	var active := active_bonus(hero, tick)
	var hp := float(stats.hp_regen_per_second) + float(active.hp_regen_per_second)
	var mana := float(stats.mana_regen_per_second) + float(active.mana_regen_per_second)
	var rest := 0
	var march := 0
	for item_id: String in hero.get("equipment", []):
		var item: Dictionary = ITEMS.get(item_id, {})
		if tick - int(unit.get("last_damage_tick", -1000000)) >= 100:
			rest = maxi(rest, int(item.get("rest_regen", 0)))
			if tick - int(unit.get("last_move_tick", -1000000)) <= 20: march = maxi(march, int(item.get("march_regen", 0)))
	hp += float(rest + march) / 2.0
	var hp_progress := float(hero.get("item_hp_regen_carry", 0.0)) + hp
	var mana_progress := float(hero.get("item_mana_regen_carry", 0.0)) + mana
	hero["item_hp_regen_carry"] = hp_progress - floorf(hp_progress)
	hero["item_mana_regen_carry"] = mana_progress - floorf(mana_progress)
	unit.hp = mini(int(unit.max_hp), int(unit.hp) + int(hp_progress))
	hero.mana = mini(int(hero.get("max_mana", 0)), int(hero.get("mana", 0)) + int(mana_progress))

static func slot_snapshot(hero: Dictionary, tick: int = 0, eligible_allies:Array=[]) -> Dictionary:
	tick = maxi(0, tick)
	var equipment: Array = _held(hero, false)
	var consumables: Array = []
	for item_id: String in _held(hero, true):
		var valid := validate_use(hero, hero, item_id, tick,eligible_allies)
		consumables.append({"item_id":item_id,"count":int(hero.inventory[item_id]),"can_use":valid.accepted,"error":valid.error})
	while equipment.size() < EQUIPMENT_SLOTS: equipment.append("")
	while consumables.size() < CONSUMABLE_SLOTS: consumables.append({"item_id":"","count":0,"can_use":false,"error":"EMPTY_SLOT"})
	return {"equipment_slots":equipment,"consumable_slots":consumables,"equipment_slot_limit":EQUIPMENT_SLOTS,"consumable_slot_limit":CONSUMABLE_SLOTS,"item_cooldown_ticks":maxi(0, int(hero.get("item_ready_tick", 0)) - tick)}

static func _held(hero: Dictionary, consumable: bool) -> Array:
	var result: Array = []
	var inventory: Dictionary = hero.get("inventory", {})
	for item_id: String in ITEMS:
		if bool(ITEMS[item_id].get("consumable", false)) == consumable and int(inventory.get(item_id, 0)) > 0: result.append(item_id)
	return result

static func _accept(extra: Dictionary = {}) -> Dictionary:
	var result := {"accepted":true,"error":""}
	result.merge(extra)
	return result

static func _reject(reason: String) -> Dictionary:
	return {"accepted":false,"error":reason}
