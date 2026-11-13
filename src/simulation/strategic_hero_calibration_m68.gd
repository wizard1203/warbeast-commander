extends RefCounted
## Measured M68 cadence correction, applied after historical skill overlays.
## Preserve opening damage, target geometry/falloff and actual MP prices.
const VERSION:="m68-trio-cadence-calibration-v1"
static func apply(skill:Dictionary,id:String)->Dictionary:
	if id!="VOLT_ARC" or skill.is_empty():return skill
	var result:=skill.duplicate(true)
	result["max_cooldown_ticks"]=240
	result["balance_version"]=VERSION
	result["calibration_reason"]="Preserve 65% secondary damage and opening budget; increase repeat interval from9 to12 seconds. Qualified paired long-fight probe, not a faction win-rate fix."
	return result
