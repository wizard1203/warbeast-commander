extends RefCounted
## One final M58 numeric projection over the retained authored identities.
## Baseline rows are M56 values, not another live multiplier chain. Rank zero
## previews rank one, while learned flags and hero-level gates remain upstream.
const Progress = preload("res://src/simulation/strategic_hero_progression.gd")
const VERSION := "m58-hero-authority-v1"
const PURE_CONTROL := ["FROST_BIND","MOURN_BIND","RUNE_BIND","SIGNAL_LOCK","WHIRLWIND","SPORE_SEAL","STORM_HAMMER","QUAKE_SNARE","BULWARK_RECOVER","COIL_REPAIR","VINE_MEND","BLOOD_PACT","GRAVE_TOLL","SIGNAL_BLACKOUT","THORN_MAZE","LEAF_OATH"]
const WEAK_MIXED := ["ARCANE_BURST","VOLT_NETWORK","LEAF_FLARE","GEAR_SHOT","GEAR_REPAIR"]
const MELEE_DAMAGE := ["EMBER_SEAL","EMBER_SWEEP","EMBER_MEND","SPORE_SWEEP","SPORE_MEND"]
const EXTRA_KITS := {
	"ARCANIST":["STARFIRE","FROST_BIND","ARCANE_BURST"],"RANGER":["PIERCING_SHOT","ARROW_RAIN","QUICKDRAW"],
	"MOURN_ORACLE":["MOURN_BIND","MOURN_FLARE","MOURN_OATH"],"CINDER_STALKER":["CINDER_SHOT","CINDER_FERVOR","CINDER_MEND"],
	"VOLT_WEAVER":["VOLT_BIND","VOLT_ARC","VOLT_NETWORK"],"GEAR_HUNTER":["GEAR_SHOT","GEAR_FERVOR","GEAR_REPAIR"],
	"LEAF_SEER":["LEAF_BIND","LEAF_FLARE","LEAF_OATH"],"WIND_COURIER":["WIND_SHOT","WIND_FERVOR","WIND_MEND"],
	"RUNE_ORACLE":["RUNE_BIND","RUNE_FLARE","RUNE_OATH"],"EMBER_CAVALIER":["EMBER_SEAL","EMBER_SWEEP","EMBER_MEND"],
	"ECHO_BINDER":["ECHO_BIND","ECHO_FLARE","ECHO_OATH"],"SPORE_STALKER":["SPORE_SEAL","SPORE_SWEEP","SPORE_MEND"]}
const TANK_GUARDS := {"COIL_WARDEN":"COIL_WARD","VINE_WARDEN":"VINE_WARD","TUNNEL_SENTINEL":"TUNNEL_WARD"}
const AURA_PATCHES := {
	"CLEAVE":{"aura_armor":[1,2,3]},"COIL_BATTERY":{"aura_armor":[1,2,3]},"HEARTH_WARMTH":{"aura_armor":[1,2,3]},
	"SEAL_STRIKE":{"aura_speed":0,"aura_move_speed_percent":[6,9,12]},"SIGNAL_MARCH":{"aura_speed":0,"aura_move_speed_percent":[5,8,11]},
	"THORN_BREEZE":{"aura_speed":0,"aura_move_speed_percent":[7,10,13]},"QUAKE_RHYTHM":{"aura_speed":0,"aura_move_speed_percent":[6,10,14]}}
const BUFFS := ["CINDER_FERVOR","GEAR_FERVOR","WIND_FERVOR","QUICKDRAW","WIND_MEND","SPORE_MEND"]
static var _owners: Dictionary = {}

static func owner(id: String) -> String:
	if _owners.is_empty():
		for kits: Dictionary in [Progress.SUPPORT_KITS,Progress.TANK_KITS,EXTRA_KITS]:
			for hero: String in kits:
				for skill: String in kits[hero]: _owners[skill]=hero
	return str(_owners.get(id,""))

static func kit(hero: String) -> Array:
	return Progress.SUPPORT_KITS.get(hero,Progress.TANK_KITS.get(hero,EXTRA_KITS.get(hero,[])))

static func _at(value: Variant, rank: int) -> Variant:
	return value[clampi(rank-1,0,value.size()-1)] if value is Array else value

static func _rank_damage(row: Dictionary, id: String, rank: int) -> float:
	var amount: float = float(_at(row.get("damage",0),1))*1.2*[1.0,1.4,1.8][clampi(rank-1,0,2)]
	return amount*1.15 if id in MELEE_DAMAGE else amount

static func _falloff(row: Dictionary) -> float:
	return 1.0+float(maxi(0,int(row.get("max_targets",1))-1))*float(row.get("secondary_damage_percent",100))/100.0

static func _normal_reference(id: String, entries: Dictionary, field: String) -> Dictionary:
	var best := {"id":"","value":0.0,"row":{}}
	for other: String in kit(owner(id)):
		if other in Progress.ULTIMATES or other in PURE_CONTROL or not entries.has(other): continue
		var row: Dictionary=entries[other]
		var value := _rank_damage(row,other,3) if field=="damage" else float(_at(row.get(field,0),1))*1.2*1.8
		if value>float(best.value): best={"id":other,"value":value,"row":row}
	return best

static func tank_aura(hero: String, rank: int) -> Dictionary:
	if not TANK_GUARDS.has(hero) or rank<1: return {}
	return {"attribute":{"COIL_WARDEN":"attack_speed_percent","VINE_WARDEN":"healing_received_percent","TUNNEL_SENTINEL":"control_resist_percent"}[hero],"amount":[8,12,16][clampi(rank-1,0,2)],"radius":150,"max_targets":4,"condition":{"COIL_WARDEN":"STATIONARY_2S","VINE_WARDEN":"ROOTED_HEAL_WINDOW","TUNNEL_SENTINEL":"FORMATION_2_ALLIES"}[hero]}

static func apply(skill: Dictionary, id: String, rank: int, entries: Dictionary) -> Dictionary:
	var result := skill.duplicate(true)
	var r := maxi(1,rank)
	result["balance_version"]=VERSION
	result["calibration_reason"]="M58 first-iteration values; compare actual one/three/six recipients, not an assertion of competitive balance."
	if not entries.has(id):
		if AURA_PATCHES.has(id):
			for field: String in AURA_PATCHES[id]: result[field]=_at(AURA_PATCHES[id][field],r)
		var aura := tank_aura(owner(id),r)
		if id==str(TANK_GUARDS.get(owner(id),"")) and not aura.is_empty(): result["conditional_aura"]=aura
		result["power_class"]="LEARNED_PASSIVE"
		return result
	var row: Dictionary=entries[id]
	var ultimate := id in Progress.ULTIMATES
	var factor: float=[1.0,1.35][clampi(r-1,0,1)] if ultimate else [1.0,1.4,1.8][clampi(r-1,0,2)]
	var reasons: Array[String]=[]
	if id in BUFFS:
		result.damage_percent=([75,95] if ultimate else [35,45,55])[r-1]
		result.attack_speed_percent=([30,40] if ultimate else [15,20,25])[r-1]
		result.duration_ticks=([240,280] if ultimate else [160,180,200])[r-1]
		if ultimate and id=="WIND_MEND":
			result.damage_percent=[85,105][r-1]
			result.attack_speed_percent=[35,40][r-1]
			reasons.append("WIND has a same-kit ordinary enhancer: authored85/35->105/40 respects20Hz attack-interval quantization and targets about35% extra attack-window growth, not only continuous-formula DPS.")
		if not ultimate:
			result.max_cooldown_ticks=360
			reasons.append("Ordinary enhancer CD18s prevents old rank3 ten-second buff with nine-second CD from permanent coverage; retains a meaningful ultimate burst window.")
		result["power_class"]="ATTACK_ENHANCEMENT"
	elif str(result.effect)=="HEAL":
		for field: String in ["heal","ally_heal"]:
			if not row.has(field): continue
			var base := float(_at(row[field],1))*1.2
			if ultimate:
				var reference := _normal_reference(id,entries,field)
				if float(reference.value)>0:
					base=float(reference.value)*1.7
					if field=="ally_heal":
						var coverage := float(reference.row.get("max_targets",1))/float(row.get("max_targets",1))
						base=maxf(float(reference.value),base*minf(1.0,coverage))
						reasons.append("Ally-heal coverage %d->%d is budgeted; per-ally healing never below own ordinary rank3."%[int(reference.row.get("max_targets",1)),int(row.get("max_targets",1))])
			result[field]=roundi(base*factor)
		result["power_class"]="HEALING"
	else:
		var pure := id in PURE_CONTROL
		var hard := str(result.effect) in ["STUN","ROOT"]
		var mixed := not pure and (hard or id in WEAK_MIXED)
		result["power_class"]="PURE_CONTROL" if pure else "MIXED" if mixed else "PURE_DAMAGE"
		if pure:
			result["damage"]=0
			for field: String in ["status_kind","status_power","status_duration_ticks","status_total_damage","drain_percent","execute_percent"]: result.erase(field)
		else:
			var damage := _rank_damage(row,id,r)
			if ultimate:
				var reference := _normal_reference(id,entries,"damage")
				# Tanks have no normal damaging skill: use a documented role-scale
				# ordinary army hit, not their self-heal as enemy damage.
				if float(reference.value)<=0: reference={"id":"TANK_ROLE_MIXED_REFERENCE","value":145.0,"row":{"max_targets":4,"secondary_damage_percent":75}}
				damage=float(reference.value)*1.7
				var reference_group := int(reference.row.get("max_targets",1))>1
				if int(row.get("max_targets",1))>1 and reference_group:
					var coverage := minf(1.0,_falloff(reference.row)/_falloff(row))
					damage=maxf(float(reference.value),damage*coverage)
					if coverage<1.0: reasons.append("Ultimate direct budget includes expanded coverage; primary stays >= own ordinary rank3.")
				damage*=factor
				result["reference_skill_id"]=reference.id
				result["reference_primary_rank3"]=reference.value
			result["damage"]=roundi(damage)
		if hard:
			var single := int(row.get("max_targets",1))==1
			var seconds: float
			if ultimate: seconds=([9.0,11.0] if single and pure else [6.0,7.5] if pure else [4.0,5.0] if single else [3.5,4.5])[r-1]
			else: seconds=([4.0,5.0,6.0] if single and pure else [3.0,4.0,5.0] if pure else [2.0,2.75,3.5] if single else [1.5,2.25,3.0])[r-1]
			result["control_duration_ticks"]=roundi(seconds*20.0)
			if not ultimate:
				result.max_cooldown_ticks=maxi(int(result.max_cooldown_ticks),480 if pure else 320)
				reasons.append("Paid three-hero relay calibration: pure ordinary CD24s / mixed hard-control CD16s; preserve requested control durations and hero70%, break repeated ordinary recasts rather than introduce immunity. Extreme machine opening can still lock one target27s (hero18.9s).")
		if not pure and row.has("status_kind"):
			var duration: int = ([160,240] if ultimate else [120,160,200])[r-1]
			result["status_duration_ticks"]=duration
			if str(row.status_kind) in ["BURN","POISON"]:
				var old_total := float(_at(row.get("status_power",0),1))*float(_at(row.get("status_duration_ticks",0),1))/20.0
				var total := old_total*1.2*factor
				if ultimate:
					var reference := _normal_reference(id,entries,"damage")
					var other: Dictionary=reference.row
					var source_total := float(_at(other.get("status_power",0),1))*float(_at(other.get("status_duration_ticks",0),1))/20.0*1.2*1.8
					total=maxf(old_total*1.2,source_total*1.7)*factor
				result["status_total_damage"]=total
				result["status_power"]=total*20.0/float(duration)
			else:
				result["status_power"]=float(_at(row.get("status_power",0),1))+(r-1)*(1.0 if str(row.status_kind)=="ARMOR_BREAK" else 5.0)
	if ultimate:
		result["mana_cost"]=[70,85][r-1]
		result["max_cooldown_ticks"]=700 if result.effect=="HEAL" else 900 if result.power_class=="PURE_CONTROL" or (int(result.max_targets)>1 and result.power_class=="PURE_DAMAGE") else 800
	if not reasons.is_empty(): result.calibration_reason=" ".join(reasons)
	result["budget_primary_raw"]=float(result.get("damage",result.get("heal",result.get("damage_percent",0))))
	result["budget_per_cast_raw"]=float(result.get("damage",0))*_falloff(result)+float(result.get("status_total_damage",0))*float(result.max_targets) if result.has("damage") else float(result.get("heal",0))+float(result.get("ally_heal",0))*float(result.max_targets)
	return result
