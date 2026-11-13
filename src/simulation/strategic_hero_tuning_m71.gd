extends RefCounted
## Final M71 projection AFTER the immutable M69/M70 historical layers.
## No prices, RNG, combat state or alternate settlement lives in this file.
const VERSION:="m71-hero-damage130-integer-bonuses-xp85-v1"
const DAMAGE_FACTOR:=1.3
## Reviewed M70 fixed bonuses rounded upward. Growing fixed fields retain an
## integer step; a previously constant incidental hit remains constant.
## Percentage buffs are NOT fixed points and are deliberately not rounded here.
const INTEGER_ROWS:={
	"ASH_WARD":{"passive_armor":[1,2,3]},
	"BASALT_LOAD_TEST":{"passive_armor":[1,2,3]},
	"BASALT_FAULT_STANCE":{"armor_bonus":[1,2]},
	"BRIDGE_LOCK_BRACE":{"ally_guard":[1,2,3]},
	"BRIDGE_LOAD_BEARER":{"armor_bonus":[2,3]},
	"BULWARK_WARD":{"passive_armor":[1,2,3]},
	"CARAPACE_LAYERED_MOLT":{"ally_guard":[2,3]},
	"CINDER_FERVOR":{"damage_bonus":[2,2,2]},
	"COIL_BATTERY":{"aura_damage":[2,3,4],"aura_armor":[1,2,3]},
	"COIL_WARD":{"passive_armor":[1,2,3]},
	"CLEAVE":{"aura_armor":[1,2,3]},
	"RECOVER":{"ally_guard":[1,2,3]},
	"GEAR_FERVOR":{"damage_bonus":[2,2,2]},
	"GRAVE_CADENCE":{"aura_damage":[2,3,4]},
	"HEARTH_WARMTH":{"aura_armor":[1,2,3]},
	"HEARTH_MEND":{"ally_guard":[1,2,3]},
	"HEARTH_REFUGE":{"ally_guard":[2,3]},
	"RIDGE_WARD":{"passive_armor":[1,2,3]},
	"RIVET_LOAD_PLATE":{"armor_bonus":[1,2,3]},
	"RIVET_WORKING_PRESSURE":{"ally_guard":[1,2]},
	"SPORE_GLOW":{"aura_damage":[2,3,4]},
	"STORM_CHANT":{"aura_damage":[2,3,4]},
	"THORN_BREEZE":{"aura_armor":[1,2,3]},
	"TUNNEL_WARD":{"passive_armor":[1,2,3]},
	"VINE_WARD":{"passive_armor":[1,2,3]},
	"WIND_FERVOR":{"damage_bonus":[2,2,2]},
}
const SCOPE:="M71：在当前M70上仅学习技能直伤与完整DoT提高30%一次；固定普攻至少2并上整，固定护甲上整，原本按该固定值升阶的技能保留整数阶梯。治疗、控制、百分比强化、MP/CD、人数、几何、身体、装备及天生被动不变。旧M69/M70元数据仅为历史层，不再声称最终幅度固定50%或所有旧大招比值保持。"
static func apply(skill:Dictionary)->Dictionary:
	if skill.is_empty():return {}
	var out:=skill.duplicate(true)
	if out.get("tuning_version","")==VERSION:return out
	if out.has("damage"):out.damage=float(out.damage)*DAMAGE_FACTOR
	if str(out.get("status_kind","")) in ["BURN","POISON"]:
		var seconds:=float(out.get("status_duration_ticks",0))/20.0
		var total:=float(out.get("status_total_damage",float(out.get("status_power",0))*seconds))*DAMAGE_FACTOR
		if seconds>0:
			out["status_total_damage"]=total
			out["status_power"]=total/seconds
	var rows:Dictionary=INTEGER_ROWS.get(str(out.get("id","")),{})
	var rank:=maxi(1,int(out.get("level",1)))
	for field:String in rows:out[field]=rows[field][mini(rank-1,rows[field].size()-1)]
	if out.has("budget_primary_raw"):out.budget_primary_raw=float(out.get("damage",out.get("heal",out.get("damage_percent",0))))
	if out.has("budget_per_cast_raw"):
		var count:=int(out.get("max_targets",1))
		out.budget_per_cast_raw=float(out.get("damage",0))*(1.0+float(maxi(0,count-1))*float(out.get("secondary_damage_percent",100))/100.0)+float(out.get("status_total_damage",0))*count if out.has("damage") else float(out.get("heal",0))+float(out.get("ally_heal",0))*count
	out["tuning_version"]=VERSION
	out["tuning_scope"]=SCOPE
	out["tuning_damage_factor"]=DAMAGE_FACTOR
	out["m70_calibration_reason"]=out.get("calibration_reason","")
	out["calibration_reason"]=SCOPE
	return out
