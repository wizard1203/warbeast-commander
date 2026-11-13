extends RefCounted
## Identity growth and finite learning rules. Integer tables are shared by
## authority and detached handbook observations; no match authority lives here.
const VERSION := "m75-current-level-growth-xp90-victim-level-rewards-v1"
const ExpansionM66=preload("res://src/simulation/strategic_hero_expansion_m66.gd")
const GrowthM67=preload("res://src/simulation/strategic_hero_growth_m67.gd")
const MagesM68=preload("res://src/simulation/strategic_hero_mages_m68.gd")
const MAX_LEVEL := 8
# Round each cumulative M71 threshold * 0.9 once, not each per-level segment.
# Earned XP is not multiplied. Victim-level hero rewards are a separate rule.
const XP_THRESHOLDS := [0, 33, 83, 149, 231, 330, 446, 579]
const SHARED_XP_RADIUS := 900
const ROLES := {
	"COMMANDER":"HEAL_SUPPORT", "DUELIST":"CONTROL_SUPPORT", "BULWARK":"TANK", "RANGER":"PHYSICAL", "ARCANIST":"MAGE",
	"ASH_CHANTER":"HEAL_SUPPORT", "GRAVE_BELL":"CONTROL_SUPPORT", "ASH_MARSHAL":"TANK", "CINDER_STALKER":"PHYSICAL", "MOURN_ORACLE":"MAGE",
	"COIL_MEDIC":"HEAL_SUPPORT", "SIGNAL_KEEPER":"CONTROL_SUPPORT", "COIL_WARDEN":"TANK", "GEAR_HUNTER":"PHYSICAL", "VOLT_WEAVER":"MAGE",
	"BLOOM_GUIDE":"HEAL_SUPPORT", "THORN_CHANTER":"CONTROL_SUPPORT", "VINE_WARDEN":"TANK", "WIND_COURIER":"PHYSICAL", "LEAF_SEER":"MAGE",
	"HEARTH_KEEPER":"HEAL_SUPPORT", "STORM_HERALD":"CONTROL_SUPPORT", "RIDGE_JARL":"TANK", "EMBER_CAVALIER":"PHYSICAL", "RUNE_ORACLE":"MAGE",
	"SPORE_GUIDE":"HEAL_SUPPORT", "QUAKE_PRIEST":"CONTROL_SUPPORT", "TUNNEL_SENTINEL":"TANK", "SPORE_STALKER":"PHYSICAL", "ECHO_BINDER":"MAGE",
}
const ROLE_LABELS := {"HEAL_SUPPORT":"辅助·光环回复", "CONTROL_SUPPORT":"辅助·光环控制", "PHYSICAL":"物理输出", "MAGE":"法师·控制输出", "TANK":"坦克·回复守护", "MELEE_CASTER":"近战·技能输出", "WARRIOR":"战士·攻守均衡"}
const GROWTH := {
	"HEAL_SUPPORT":{"max_hp":24,"damage_numerator":1,"damage_denominator":1,"armor_every":3,"max_mana":6},
	"CONTROL_SUPPORT":{"max_hp":24,"damage_numerator":1,"damage_denominator":1,"armor_every":3,"max_mana":6},
	"PHYSICAL":{"max_hp":28,"damage_numerator":2,"damage_denominator":1,"armor_every":3,"max_mana":4},
	"MAGE":{"max_hp":20,"damage_numerator":1,"damage_denominator":1,"armor_every":4,"max_mana":9},
	"TANK":{"max_hp":44,"damage_numerator":1,"damage_denominator":2,"armor_every":2,"max_mana":4},
}
const TANK_KITS := {
	"BULWARK":["SHIELD_SHOCK","BULWARK_WARD","BULWARK_RECOVER"],
	"ASH_MARSHAL":["ASH_SHOCK","ASH_WARD","ASH_MEND"],
	"COIL_WARDEN":["COIL_SHOCK","COIL_WARD","COIL_REPAIR"],
	"VINE_WARDEN":["VINE_SHOCK","VINE_WARD","VINE_MEND"],
	"RIDGE_JARL":["RIDGE_SHOCK","RIDGE_WARD","RIDGE_MEND"],
	"TUNNEL_SENTINEL":["TUNNEL_SHOCK","TUNNEL_WARD","TUNNEL_MEND"],
}
const SUPPORT_KITS := {
	"COMMANDER":["CLEAVE","RECOVER","RALLY"], "DUELIST":["SEAL_STRIKE","WHIRLWIND","BLOOD_PACT"],
	"ASH_CHANTER":["ASH_LANTERN","ASH_STITCH","ASH_REQUIEM"], "GRAVE_BELL":["GRAVE_CADENCE","GRAVE_CHAIN","GRAVE_TOLL"],
	"COIL_MEDIC":["COIL_BATTERY","COIL_MEND","COIL_OVERHAUL"], "SIGNAL_KEEPER":["SIGNAL_MARCH","SIGNAL_LOCK","SIGNAL_BLACKOUT"],
	"BLOOM_GUIDE":["BLOOM_SPRING","BLOOM_TOUCH","BLOOM_SANCTUARY"], "THORN_CHANTER":["THORN_BREEZE","THORN_LASH","THORN_MAZE"],
	"HEARTH_KEEPER":["HEARTH_WARMTH","HEARTH_MEND","HEARTH_REFUGE"], "STORM_HERALD":["STORM_CHANT","STORM_HAMMER","STORM_VERDICT"],
	"SPORE_GUIDE":["SPORE_GLOW","SPORE_REMEDY","SPORE_HAVEN"], "QUAKE_PRIEST":["QUAKE_RHYTHM","QUAKE_SNARE","QUAKE_SEAL"],
}
const SUPPORT_NAMES := {
	"COMMANDER":["协战光环","誓图重整","守望盟誓"], "DUELIST":["行阵光环","封刃震","止戈令"],
	"ASH_CHANTER":["哀灯光环","灰线缝合","归名安魂"], "GRAVE_BELL":["暮钟光环","锁魂链","寂静晚钟"],
	"COIL_MEDIC":["稳压光环","线圈检修","全域检修"], "SIGNAL_KEEPER":["信标光环","断路脉冲","静电封锁"],
	"BLOOM_GUIDE":["花泉光环","新芽抚触","长春庇护"], "THORN_CHANTER":["林风光环","缠枝","荆棘迷庭"],
	"HEARTH_KEEPER":["暖炉光环","炉火重整","不熄营火"], "STORM_HERALD":["战歌光环","落雷锤","山巅裁决"],
	"SPORE_GUIDE":["菌光光环","孢疗","菌丝庇所"], "QUAKE_PRIEST":["穴音光环","地鸣缚","断层封印"],
}
const TANK_NAMES := {
	"BULWARK":["盾心恢复","不屈甲胄","垒盾震慑"], "ASH_MARSHAL":["余烬回生","缝骨护甲","灰誓镇魂"],
	"COIL_WARDEN":["应急检修","铆甲核心","电磁壁垒"], "VINE_WARDEN":["根心复苏","老树皮","古根囚牢"],
	"RIDGE_JARL":["炉血重整","山誓重铠","崩岩号令"], "TUNNEL_SENTINEL":["孢壳重整","穴甲外壳","穴鸣禁足"],
}
const ULTIMATES := ["RALLY","BLOOD_PACT","BULWARK_RECOVER","ARCANE_BURST","QUICKDRAW","ASH_MEND","MOURN_OATH","CINDER_MEND","COIL_REPAIR","VOLT_NETWORK","GEAR_REPAIR","VINE_MEND","LEAF_OATH","WIND_MEND","RIDGE_MEND","RUNE_OATH","EMBER_MEND","TUNNEL_MEND","ECHO_OATH","SPORE_MEND","ASH_REQUIEM","GRAVE_TOLL","COIL_OVERHAUL","SIGNAL_BLACKOUT","BLOOM_SANCTUARY","THORN_MAZE","HEARTH_REFUGE","STORM_VERDICT","SPORE_HAVEN","QUAKE_SEAL"] + ExpansionM66.ULTIMATES + MagesM68.ULTIMATES
static var _patch_cache: Dictionary = {} # Hard cap: 90 derived content entries.

static func role(archetype: String) -> String: return "MAGE" if MagesM68.has_hero(archetype) else str(ExpansionM66.ROWS[archetype][3]) if ExpansionM66.has_hero(archetype) else str(ROLES.get(archetype,"PHYSICAL"))
static func level_for_xp(xp: int) -> int:
	var result := 1
	for index: int in range(XP_THRESHOLDS.size()):
		if xp >= int(XP_THRESHOLDS[index]): result = index + 1
	return result

static func next_level_xp(level: int) -> int:
	return int(XP_THRESHOLDS[level]) if level >= 1 and level < MAX_LEVEL else -1

static func kill_reward(victim: Dictionary, victim_level: int = 1) -> int:
	# Victim level affects hero bounty, not the receiving hero's strength.
	# Neutral templates already carry their level/encounter budget: never
	# multiply that pool twice, nor convert scattered six-XP camps to regulars.
	if str(victim.get("unit_type",""))=="hero":return 48+8*(clampi(victim_level,1,MAX_LEVEL)-1)
	if str(victim.get("unit_type",""))=="worker":return 0
	if victim.has("xp_reward"):return maxi(0,int(victim.xp_reward))
	return 24 if "HEAVY" in victim.get("tags",[]) else 12

static func growth(archetype: String) -> Dictionary:
	if MagesM68.has_hero(archetype):return MagesM68.growth(archetype)
	# The identity catalog is already final army-scale. Keep legacy role data
	# only for the historical unknown-ID fallback, never re-scale these rows.
	if GrowthM67.has_hero(archetype):return GrowthM67.growth(archetype)
	var result:Dictionary=GROWTH[role(archetype)].duplicate(true)
	result.max_hp=roundi(float(result.max_hp)*1.5)
	result.max_mana=roundi(float(result.max_mana)*1.5)
	result.damage_numerator=int(result.damage_numerator)*3
	result.damage_denominator=int(result.damage_denominator)*2
	return result
static func bonuses(archetype: String, level: int) -> Dictionary:
	var steps := clampi(level,1,MAX_LEVEL)-1
	var values := growth(archetype)
	return {"max_hp":steps*int(values.max_hp),"damage":steps*int(values.damage_numerator)/int(values.damage_denominator),"armor":steps/int(values.armor_every),"max_mana":steps*int(values.max_mana)}

static func growth_description(archetype: String) -> String:
	var values := growth(archetype)
	return "每级最大生命+%d、最大法力+%d，平均攻击+%.2f。每升%d级，护甲+1。升级不补满生命或法力。" % [values.max_hp,values.max_mana,float(values.damage_numerator)/float(values.damage_denominator),values.armor_every]

static func max_skill_rank(id: String) -> int: return 2 if id in ULTIMATES or id in ExpansionM66.ULTIMATES else 3
static func required_level(id: String, rank: int) -> int:
	if rank < 1 or rank > max_skill_rank(id): return 99
	return [5,8][rank-1] if id in ULTIMATES or id in ExpansionM66.ULTIMATES else 1

static func skill_patch(id: String) -> Dictionary:
	if _patch_cache.has(id): return _patch_cache[id].duplicate(true)
	for archetype: String in SUPPORT_KITS:
		var index: int = SUPPORT_KITS[archetype].find(id)
		if index >= 0:
			_patch_cache[id]=_support(archetype,index)
			return _patch_cache[id].duplicate(true)
	for archetype: String in TANK_KITS:
		var index: int = TANK_KITS[archetype].find(id)
		if index >= 0:
			_patch_cache[id]=_tank(archetype,index)
			return _patch_cache[id].duplicate(true)
	var patches := {
		"MOURN_BIND":{"effect":"ROOT","control_duration_ticks":30,"damage":10},
		"RUNE_BIND":{"effect":"STUN","control_duration_ticks":14,"damage":12},
		"ARCANE_BURST":{"name":"星界崩落","effect":"DAMAGE","damage":46,"radius":125,"max_targets":5,"mana_cost":45,"max_cooldown_ticks":440,"status_kind":"SLOW","status_power":20,"status_duration_ticks":40},
		"MOURN_OATH":{"name":"归烬洪流","effect":"DAMAGE","damage":38,"radius":130,"max_targets":5,"drain_percent":20,"mana_cost":45,"max_cooldown_ticks":440},
		"VOLT_NETWORK":{"name":"风暴回路","effect":"DAMAGE","delivery":"CHAIN","chain_range":110,"damage":36,"radius":110,"max_targets":5,"status_kind":"SLOW","status_power":25,"status_duration_ticks":40,"mana_cost":45,"max_cooldown_ticks":440},
		"LEAF_OATH":{"name":"千叶封庭","effect":"ROOT","damage":30,"control_duration_ticks":35,"radius":125,"max_targets":5,"mana_cost":45,"max_cooldown_ticks":440},
		"RUNE_OATH":{"name":"深炉喷涌","effect":"DAMAGE","damage":36,"radius":125,"max_targets":5,"status_kind":"BURN","status_power":3,"status_duration_ticks":60,"mana_cost":45,"max_cooldown_ticks":440},
		"ECHO_OATH":{"name":"回声坍缩","effect":"DAMAGE","delivery":"LINE","line_width":60,"damage":40,"radius":100,"max_targets":5,"status_kind":"SLOW","status_power":35,"status_duration_ticks":40,"mana_cost":45,"max_cooldown_ticks":440},
		"QUICKDRAW":{"name":"追风齐射","effect":"DAMAGE_BUFF","damage_bonus":6,"duration_ticks":120,"range_bonus":24,"mana_cost":40,"max_cooldown_ticks":420},
		"CINDER_MEND":{"name":"灰烬猎宴","effect":"DAMAGE","target_mode":"POINT","range":290,"radius":90,"delivery":"LINE","line_width":34,"damage":40,"attack_type":"PIERCE","max_targets":3,"drain_percent":25,"mana_cost":40,"max_cooldown_ticks":420},
		"GEAR_REPAIR":{"name":"破甲过载","effect":"DAMAGE","target_mode":"POINT","range":290,"radius":95,"damage":36,"attack_type":"GUNPOWDER","max_targets":5,"status_kind":"ARMOR_BREAK","status_power":2,"status_duration_ticks":60,"mana_cost":40,"max_cooldown_ticks":420},
		"WIND_MEND":{"name":"逐风猎阵","effect":"DAMAGE_BUFF","damage_bonus":6,"duration_ticks":120,"speed_bonus":2,"mana_cost":40,"max_cooldown_ticks":420},
		"EMBER_MEND":{"name":"烬脊战意","effect":"DAMAGE_BUFF","damage_bonus":6,"duration_ticks":120,"drain_percent_buff":10,"mana_cost":40,"max_cooldown_ticks":420},
		"SPORE_MEND":{"name":"裂隙追猎","effect":"DAMAGE_BUFF","damage_bonus":5,"duration_ticks":120,"speed_bonus":1,"mana_cost":40,"max_cooldown_ticks":420},
	}
	var result: Dictionary=patches.get(id,{}).duplicate(true)
	if _patch_cache.size()<90: _patch_cache[id]=result.duplicate(true)
	return result

static func _base(name: String, effect: String) -> Dictionary:
	return {"name":name,"effect":effect,"target_mode":"SELF","range":0,"radius":0,"delivery":"AREA","target_layers":["GROUND","AIR"],"max_targets":6,"mana_cost":25,"max_cooldown_ticks":160}

static func _support(archetype: String, index: int) -> Dictionary:
	var healer := role(archetype)=="HEAL_SUPPORT"
	var result := _base(SUPPORT_NAMES[archetype][index],"AURA" if index==0 else "HEAL" if healer else "STUN")
	if index==0:
		result.merge({"passive":true,"mana_cost":0,"max_cooldown_ticks":0,"radius":165,"aura_radius":165,"max_targets":6,"aura_damage":0,"aura_armor":0,"aura_speed":0,"aura_heal":0},true)
		if healer:
			result["aura_armor" if archetype in ["COMMANDER","COIL_MEDIC","HEARTH_KEEPER"] else "aura_heal"]=1
		else: result["aura_damage" if archetype in ["GRAVE_BELL","STORM_HERALD"] else "aura_speed"]=1
		return result
	if healer:
		result.merge({"heal":42 if index==1 else 58,"ally_heal":12 if index==1 else 26,"ally_radius":145 if index==1 else 185,"radius":145 if index==1 else 185,"max_targets":4 if index==1 else 6,"cleanse_dot":archetype in ["ASH_CHANTER","BLOOM_GUIDE","SPORE_GUIDE"]},true)
		if archetype=="COIL_MEDIC": result["ally_required_tag"]="MACHINE"
		if archetype in ["COMMANDER","HEARTH_KEEPER"]: result["ally_guard"]=1 if index==1 else 2; result["duration_ticks"]=60
		if archetype=="SPORE_GUIDE" and index==2: result["speed_bonus"]=1; result["duration_ticks"]=60
	else:
		result.merge({"target_mode":"POINT","range":220,"radius":75 if index==1 else 120,"max_targets":3 if index==1 else 5,"damage":10 if index==1 else 18,"control_duration_ticks":15 if index==1 else 25},true)
		if archetype in ["GRAVE_BELL","THORN_CHANTER","QUAKE_PRIEST"]: result.effect="ROOT"; result.control_duration_ticks=25 if index==1 else 40
		if archetype=="SIGNAL_KEEPER": result.merge({"delivery":"CHAIN","chain_range":90},true)
		if archetype=="STORM_HERALD": result.merge({"delivery":"LINE","line_width":46,"status_kind":"BURN","status_power":1,"status_duration_ticks":40},true)
		if archetype=="QUAKE_PRIEST": result.merge({"status_kind":"POISON","status_power":1,"status_duration_ticks":40},true)
		if archetype=="GRAVE_BELL": result["drain_percent"]=20
		if archetype=="DUELIST" and index==2: result.effect="ROOT"; result.control_duration_ticks=35
	if index==2: result.merge({"mana_cost":45,"max_cooldown_ticks":440},true)
	return result

static func _tank(archetype: String,index: int) -> Dictionary:
	var result := _base(TANK_NAMES[archetype][index],"HEAL" if index==0 else "PASSIVE_GUARD" if index==1 else "STUN")
	if index==0:
		result.merge({"heal":46,"max_cooldown_ticks":180},true)
		if archetype in ["ASH_MARSHAL","COIL_WARDEN","TUNNEL_SENTINEL"]: result["cleanse_dot"]=true
	elif index==1: result.merge({"passive":true,"mana_cost":0,"max_cooldown_ticks":0,"passive_armor":1},true)
	else:
		result.merge({"target_mode":"POINT","range":145,"radius":100,"damage":14,"control_duration_ticks":25,"max_targets":4,"mana_cost":45,"max_cooldown_ticks":440},true)
		if archetype in ["VINE_WARDEN","TUNNEL_SENTINEL"]: result.effect="ROOT"; result.control_duration_ticks=40
		if archetype=="COIL_WARDEN": result.merge({"delivery":"CHAIN","chain_range":90},true)
		if archetype=="RIDGE_JARL": result.merge({"delivery":"LINE","line_width":65},true)
	return result
