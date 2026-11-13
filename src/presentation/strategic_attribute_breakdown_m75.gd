extends RefCounted
## Read-only units/formatting only. Baselines are published by settlement, never
## rebuilt here from today's catalog (which would corrupt historical replays).
const VERSION := "m75-authoritative-base-net-attributes-v1"
const FIELDS := {"damage":"damage","armor":"armor","attack_speed":"attack_cooldown_ticks","move_speed":"speed","range":"attack_range","magic_resist":"magic_resist_percent","hp_regen":"hp_regen_per_second","mana_regen":"mana_regen_per_second"}

static func value(body: Dictionary,id: String,effective: float,suffix: String = "") -> Dictionary:
	var total := effective if is_finite(effective) else 0.0
	var result := {"breakdown_available":false,"base":null,"bonus":null,"total":total,"value":number(total)+suffix,"compact_value":number(total),"description":"当前总值；此记录没有基础与加成明细。"}
	if not is_finite(effective):
		result.merge({"total":null,"value":"—","compact_value":"—","description":"该属性暂时不可用。"},true)
		return result
	if id not in FIELDS:return result
	var baseline: Variant=body.get("attribute_base",body.get("neutral_base_stats",null))
	if not baseline is Dictionary or baseline.is_empty():return result
	var field: String=FIELDS[id]
	var fallback := 0.0
	if not baseline.has(field) and id in ["damage","armor","attack_speed","move_speed","range"]:return result
	var raw: Variant=baseline.get(field,fallback)
	if typeof(raw) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(raw)):return result
	var intrinsic := float(raw)
	if id=="attack_speed":intrinsic=20.0/intrinsic if intrinsic>0 else 0.0
	elif id=="move_speed":intrinsic*=20.0
	var bonus := total-intrinsic
	if absf(bonus)<0.000001:bonus=0.0
	# Quantize only the displayed pair, so rounded labels still sum to the
	# displayed total (e.g. 1.67 + .18 = 1.85, not a misleading 1.86).
	var shown_base:=snappedf(intrinsic,0.01)
	var shown_bonus:=snappedf(total,0.01)-shown_base
	var operator := " − " if shown_bonus < -0.000001 else " + "
	result.merge({"breakdown_available":true,"base":intrinsic,"bonus":bonus,"value":number(shown_base)+operator+number(absf(shown_bonus))+suffix,"compact_value":number(shown_base)+operator.strip_edges()+number(absf(shown_bonus)),"description":"基础%s%s%s = 当前%s。\n基础包含等级成长；额外值合计科技、装备、技能、光环与减益。"%[number(shown_base)+suffix,operator,number(absf(shown_bonus))+suffix,number(total)+suffix]},true)
	return result

static func number(amount: float) -> String:
	if is_zero_approx(amount):return "0"
	var text := "%.2f"%amount
	while text.ends_with("0"):text=text.trim_suffix("0")
	return text.trim_suffix(".")

static func apply(row: Dictionary,body: Dictionary,effective: float,suffix: String = "") -> Dictionary:
	var result:=row.duplicate(true)
	var breakdown:=value(body,str(row.get("id","")),effective,suffix)
	result.merge(breakdown,true)
	result["description"]=str(row.get("description",""))+"\n"+str(breakdown.description)
	return result
