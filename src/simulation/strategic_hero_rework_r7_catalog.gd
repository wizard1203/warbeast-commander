extends RefCounted
## Opt-in R7 wave-one data authority. No combat settlement lives here.
## Runtime reads only the minimal exported asset, never design-research.
const VERSION := "hero-rework-r7-wave1-20261102-v1"
const DATA_PATH := "res://assets/data/hero-rework-r7-wave1.json"
const ENABLED_HEROES := ["CINDER_TESTATOR", "MYCELIAL_CATALYST"]
static var _runtime_data: Dictionary = {}
static var _load_attempted := false

static func _catalog() -> Dictionary:
	if not _load_attempted:
		_load_attempted = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary and str(parsed.get("rework_version", "")) == VERSION:
			_runtime_data = parsed
		else:
			push_error("R7 runtime catalog missing or invalid: " + DATA_PATH)
	return _runtime_data

static func has_hero(id: String) -> bool:
	return id in ENABLED_HEROES and _catalog().get("heroes", {}).has(id)

static func has_skill(id: String) -> bool:
	var row: Dictionary = _catalog().get("skills", {}).get(id, {})
	return not row.is_empty() and has_hero(str(row.get("hero_id", "")))

static func skill(id: String, rank: int = 1) -> Dictionary:
	if not has_skill(id): return {}
	var ranks: Array = _catalog().skills[id].ranks
	if rank < 0 or rank > ranks.size(): return {}
	var result: Dictionary = ranks[maxi(1, rank) - 1].duplicate(true)
	result["level"] = rank
	result["learned"] = rank > 0
	result["description"] = _describe_skill(result)
	return result

static func _describe_skill(skill: Dictionary) -> String:
	var parts: Array[String] = ["未学习，预览1级效果" if int(skill.level) == 0 else "%d级" % int(skill.level)]
	parts.append("终极技能，英雄5/8级可学，最高2级" if bool(skill.ultimate) else "普通技能，消耗技能点升级，最高3级")
	parts.append("施放距离%d" % int(skill.range))
	if skill.delivery == "CONE":
		parts.append("向选定方向掀开炭页，形成长%d、末端宽%d的扇形，最多命中%d名敌人" % [int(skill.range), int(skill.cone_width), int(skill.max_targets)])
	elif skill.delivery == "CHAIN":
		parts.append("酸脉击中落点%d范围内的首名敌人，再向%d距离内的敌人分流，合计最多命中%d名不同敌人" % [int(skill.radius), int(skill.chain_range), int(skill.max_targets)])
	elif skill.delivery == "AREA":
		parts.append("向选定地点倾洒孢滴，影响半径%d内最多%d名敌人" % [int(skill.radius), int(skill.max_targets)])
	else:
		parts.append("命中落点%d范围内最近的1名敌人，无溅射" % int(skill.radius))
	if bool(skill.r7_marker_dispellable):
		parts.append("先施加持续%.2f秒的末章标记，随后落印。标记可净化，净化后取消尚未发生的伤害" % (float(skill.r7_delay_ticks) / 20.0))
	else:
		parts.append("施放后%.2f秒命中" % (float(skill.r7_delay_ticks) / 20.0))
	if float(skill.r7_initial_damage) > 0:
		parts.append("命中时造成%.2f点奥术基础伤害" % float(skill.r7_initial_damage))
	if skill.has("status_kind"):
		var status_name := "灼烧" if skill.status_kind == "BURN" else "中毒"
		parts.append("施加%s，在%.1f秒内共造成%.2f点奥术基础伤害" % [status_name, float(skill.status_duration_ticks) / 20.0, float(skill.status_total_damage)])
		var stages: Array[String] = []
		for segment: Dictionary in skill.r7_segments:
			stages.append("%s%.1f秒造成%.2f点" % ["前" if int(segment.start_tick) == 0 else "随后", float(int(segment.end_tick) - int(segment.start_tick)) / 20.0, float(segment.total)])
		if stages.size() > 1: parts.append("，".join(stages))
		parts.append("%s可净化；同名效果刷新不叠加，只保留较强的剩余伤害。已施加的持续伤害不会因英雄倒下而中止" % status_name)
	if skill.r7_target_weights.size() > 1:
		var weights: Array[String] = []
		for weight: float in skill.r7_target_weights: weights.append("%.0f%%" % (weight * 100.0))
		parts.append("各目标依次承受%s基础伤害，每个目标只命中一次" % "／".join(weights))
	if skill.r7_source_death_policy == "CANCEL_IF_DEAD_OR_STUNNED_BEFORE_RELEASE":
		parts.append("出手前被眩晕或倒下会中断施放")
	parts.append("可命中地面与空中敌军，不影响工人、建筑和召唤物")
	parts.append("消耗%d蓝量，冷却%.1f秒" % [int(skill.mana_cost), float(skill.max_cooldown_ticks) / 20.0])
	return "。\n".join(parts) + "。"

static func profile_patch(hero: String) -> Dictionary:
	if not has_hero(hero): return {}
	var result: Dictionary = _catalog().heroes[hero].profile_patch.duplicate(true)
	result["innate"] = innate_profile(hero, 1)
	result["description"] = ("遗嘱可以撤回，遗火终将熄灭。灰牒用长燃火页与近前散页逼出净化时机，再将末章寄给单个敌人。\n末章标记和尾火都可净化，及时治疗能削弱他的收尾威胁。" if hero == "CINDER_TESTATOR" else "沫蚀用菌酸清理弃矿中的毒盐，也用浓酸核珠对付孤立的敌人，以分岔酸脉和孢雨压制聚集的队伍。\n擅长延时伤害，缺少控制与自保手段；分散、净化和快速切入都能威胁她。") + "\n天赋·%s：%s" % [result.innate.name, result.innate.description]
	return result

static func innate_profile(archetype: String, level: int = 1) -> Dictionary:
	if not has_hero(archetype): return {}
	var result: Dictionary = _catalog().heroes[archetype].innate.duplicate(true)
	var effective := clampi(level, 1, 8)
	var knots: Array = result.level_knots
	var amounts: Array = result.amount_knots
	var index := 0 if effective <= int(knots[1]) else 1
	var fraction := float(effective - int(knots[index])) / float(int(knots[index + 1]) - int(knots[index]))
	var amount := roundi(lerpf(float(amounts[index]), float(amounts[index + 1]), fraction))
	result.merge({"level":effective,"max_level":8,"automatic_level":true,"learnable":false,
		"passive":true,"mana_cost":0,"amount":amount,"mana_refund":amount,"values":{"amount":amount},
		"r7_handler_required":true}, true)
	if archetype == "CINDER_TESTATOR":
		result["description"] = "英雄存活时，自己消耗蓝量施加的灼烧自然结束，且曾对目标造成生命伤害，便恢复%d蓝量。每次施法最多触发一次，冷却%.1f秒；灼烧被净化、目标死亡或伤害全被护盾吸收时不触发。" % [amount, float(result.internal_cooldown_ticks) / 20.0]
	else:
		result["description"] = "英雄存活时，同一次消耗蓝量的技能对%d名不同敌人造成生命伤害后，恢复%d蓝量。每次施法最多触发一次，同一敌人多次受伤只计一次；持续伤害也可计入。" % [int(result.distinct_target_threshold), amount]
	result["description"] += "\n随英雄升级增强，无需学习或消耗蓝量，最多恢复至蓝量上限。"
	return result
