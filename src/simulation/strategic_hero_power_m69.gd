extends RefCounted
## The single final hero-power projection. Authored M58–M68 rows stay historical;
## every public learned row passes here exactly once, including early branches.
## This is an amplitude pass, not a second damage engine or an economy rule.
const VERSION:="m69-all-hero-skill-half-power-v1"
const FACTOR:=0.5
const AMPLITUDES:=["damage","heal","ally_heal","damage_bonus","armor_bonus","passive_armor","speed_bonus","range_bonus","damage_percent","attack_speed_percent","move_speed_percent","drain_percent","drain_percent_buff","execute_percent","aura_damage","aura_armor","aura_heal","aura_speed","aura_move_speed_percent","ally_guard","ally_speed","skill_damage_percent","healing_percent","mana_per_second","status_power","status_total_damage"]
const INNATE_AMPLITUDES:=["percent","amount","amount_cap","max_hp_percent","mana_per_second","hp_per_second"]

static func apply(skill:Dictionary)->Dictionary:
	if skill.is_empty():return {}
	var result:=skill.duplicate(true)
	if result.get("power_version","")==VERSION:return result
	for field:String in AMPLITUDES:
		if result.has(field):result[field]=float(result[field])*FACTOR
	# Hard-control has no amplitude: halve its duration. Weak-control power and
	# periodic damage have already halved, so retain their finite original time.
	if result.has("control_duration_ticks"):result.control_duration_ticks=roundi(float(result.control_duration_ticks)*FACTOR)
	if result.has("conditional_aura"):result.conditional_aura=conditional_aura(result.conditional_aura)
	for field:String in ["budget_primary_raw","budget_per_cast_raw","reference_primary_rank3"]:
		if result.has(field):result[field]=float(result[field])*FACTOR
	result["power_version"]=VERSION
	result["power_factor"]=FACTOR
	result["power_scope"]="M69：技能数值幅度50%；硬控时长50%；DoT总量和速率50%但时长不变；有限增益/弱控时长、人数、几何、MP/CD/次数及净化等二元身份不变。基础属性、普攻、装备和兵种不在此投影。"
	if result.has("calibration_reason"):
		result["authored_calibration_reason"]=result.calibration_reason
	result["calibration_reason"]="当前数值采用M69最终50%幅度投影；authored_calibration_reason仅为缩放前历史设计说明。"+str(result.power_scope)
	return result

static func conditional_aura(aura:Dictionary)->Dictionary:
	if aura.is_empty():return {}
	var result:=aura.duplicate(true)
	if result.get("power_version","")==VERSION:return result
	if result.has("amount"):result.amount=float(result.amount)*FACTOR
	result["power_version"]=VERSION
	return result

static func innate_growth(raw:Dictionary)->Dictionary:
	var result:=raw.duplicate(true)
	for field:String in INNATE_AMPLITUDES:
		if not result.has(field):continue
		for axis:String in ["base","per_level"]:result[field][axis]=float(result[field][axis])*FACTOR
	return result
