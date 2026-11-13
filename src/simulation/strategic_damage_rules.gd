extends RefCounted
## M50 two-stage settlement shared by every real damage route.
## Sacred is finite hero resistance in this game, never invulnerability.
const VERSION := "m58-proportional-armor-v1"
const ATTACKS := ["GUNPOWDER", "IMPACT", "EDGE", "PIERCE", "ARCANE", "CHAOS"]
const ARMORS := ["UNARMORED", "CLOAK", "LIGHT", "MAIL", "PLATE", "FORTIFIED", "SACRED"]
const ATTACK_LABELS := {"GUNPOWDER":"火药", "IMPACT":"撞击", "EDGE":"斩击", "PIERCE":"穿刺", "ARCANE":"奥术", "CHAOS":"混乱"}
const ARMOR_LABELS := {"UNARMORED":"无甲", "CLOAK":"斗篷", "LIGHT":"轻甲", "MAIL":"链甲", "PLATE":"重甲", "FORTIFIED":"建筑", "SACRED":"神圣护甲"}
const PERCENT := {
	"GUNPOWDER":{"UNARMORED":110,"CLOAK":110,"LIGHT":80,"MAIL":95,"PLATE":95,"FORTIFIED":120,"SACRED":70},
	"IMPACT":{"UNARMORED":110,"CLOAK":90,"LIGHT":80,"MAIL":110,"PLATE":110,"FORTIFIED":90,"SACRED":75},
	"EDGE":{"UNARMORED":110,"CLOAK":115,"LIGHT":115,"MAIL":85,"PLATE":70,"FORTIFIED":65,"SACRED":70},
	"PIERCE":{"UNARMORED":110,"CLOAK":125,"LIGHT":125,"MAIL":100,"PLATE":65,"FORTIFIED":55,"SACRED":65},
	"ARCANE":{"UNARMORED":110,"CLOAK":50,"LIGHT":115,"MAIL":130,"PLATE":160,"FORTIFIED":80,"SACRED":80},
	"CHAOS":{"UNARMORED":105,"CLOAK":105,"LIGHT":105,"MAIL":105,"PLATE":105,"FORTIFIED":105,"SACRED":80},
}

static func armor_for(target: Dictionary) -> String:
	if target.get("unit_type", "") == "hero": return "SACRED"
	if target.get("building_type", "") == "WORKER_OBSTACLE" or target.get("unit_type", "") == "worker": return "UNARMORED"
	if target.has("building_type"): return "FORTIFIED"
	return str(target.get("armor_type", "MAIL"))

static func multiplier(attack_type: String, armor_type: String) -> int:
	return int(PERCENT.get(attack_type, PERCENT.EDGE).get(armor_type, 100))

static func resolve(raw_damage: float, attack_type: String, target: Dictionary) -> int:
	if raw_damage <= 0: return 0
	return maxi(1,roundi(mitigate(raw_damage,attack_type,target)))

static func mitigate(raw_damage:float,attack_type:String,target:Dictionary)->float:
	if raw_damage<=0:return 0.0
	var scaled := float(raw_damage) * float(multiplier(attack_type, armor_for(target))) / 100.0
	# The ordinary oath guard's shield is directional in fiction but uses a
	# bounded always-on piercing resistance, avoiding hidden facing heuristics.
	if str(target.get("trait_id", "")) == "OATH_SHIELD" and attack_type == "PIERCE": scaled *= 0.9
	scaled*=armor_factor(float(target.get("armor",0)))
	if attack_type=="ARCANE":scaled*=1.0-clampf(float(target.get("magic_resist_percent",0)),0,60)/100.0
	return maxf(0.0,scaled)

static func armor_factor(armor: float) -> float:
	# Warcraft III-style numerical armor, independent of the original type table.
	return 1.0 / (1.0 + 0.06 * float(armor)) if armor >= 0 else 2.0 - pow(0.94, -float(armor))

static func formula_summary() -> String:
	return "百分比均为伤害剩余：100%=原伤害，200%=双倍，40%=仅剩四成。\n最终伤害=基础伤害×攻防类型倍率×特性倍率×数值护甲系数×适用魔抗／其他减伤，最后四舍五入；合法正伤害至少1。\n护甲A≥0：系数=1/(1+0.06×A)；A<0：系数=2−0.94^(−A)。魔抗仅作用于奥术伤害，不替代护甲。"

static func numeric_armor_summary(armor: float) -> String:
	var percent := armor_factor(armor) * 100.0
	return "护甲%.2f：经过类型倍率后，承受%.1f%%伤害（%s%.1f%%）。" % [armor,percent,"减伤" if armor >= 0 else "增伤",absf(100.0-percent)]

static func control_ticks(duration: int, target: Dictionary) -> int:
	if duration<=0:return 0
	var factor:=0.7 if armor_for(target)=="SACRED" else 1.0
	return maxi(1,roundi(float(duration)*factor*(1.0-clampf(float(target.get("control_resist_percent",0)),0,50)/100.0)))

static func attack_label(id: String) -> String: return str(ATTACK_LABELS.get(id, id))
static func armor_label(id: String) -> String: return str(ARMOR_LABELS.get(id, id))
static func attack_kind(id: String) -> String:
	return "MAGICAL" if id=="ARCANE" else "CHAOS" if id=="CHAOS" else "PHYSICAL"

static func row_for(id: String) -> Dictionary:
	return PERCENT[id].duplicate(true) if id in PERCENT else {}

static func column_for(id: String) -> Dictionary:
	var result := {}
	if id not in ARMORS: return result
	for attack: String in ATTACKS: result[attack]=PERCENT[attack][id]
	return result

static func attack_summary(attack_type: String) -> String:
	var kind_label: String = {"PHYSICAL":"物理","MAGICAL":"魔法","CHAOS":"特殊"}[attack_kind(attack_type)]
	var parts: Array[String] = ["%s攻击（%s）" % [attack_label(attack_type),kind_label]]
	for target: String in ARMORS: parts.append("对%s：伤害剩余%d%%" % [armor_label(target),multiplier(attack_type,target)])
	if attack_type=="CHAOS": parts.append("混乱：神圣剩余80%，其余剩余105%（覆盖无甲110%）。")
	parts.append("先类型倍率，再乘数值护甲系数；正伤害至少1。")
	return "\n".join(parts)

static func armor_summary(armor_type: String) -> String:
	var parts: Array[String] = [armor_label(armor_type)]
	for attack: String in ATTACKS: parts.append("受到%s：伤害剩余%d%%" % [attack_label(attack),multiplier(attack,armor_type)])
	if armor_type=="SACRED": parts.append("眩晕、定身与减速的基础持续时间为70%，再计算控制抗性。持续伤害时长不变。")
	if armor_type=="UNARMORED": parts.append("通常承受110%；混乱例外105%。")
	parts.append("先类型倍率，再乘数值护甲系数；正伤害至少1。")
	return "\n".join(parts)

static func type_summary(stats: Dictionary) -> String:
	return attack_summary(str(stats.get("attack_type","EDGE"))) + "\n\n" + armor_summary(armor_for(stats))
