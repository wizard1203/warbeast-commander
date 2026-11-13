extends RefCounted
## V4 permanent research authority. No dependency on World, Items or Combat:
## those owners validate payment and consume these detached pure projections.
const VERSION := "outposts-v4-faction-technologies-r5"
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const ROWS := {
	"HUMAN":[
		["OATH_DRILL","协战刻印","己方正规兵与英雄数值护甲+1，主动治疗量+12%。治疗加成不影响吸血、自动回复或护盾。"],
		["OATH_MILITARY_ACADEMY","誓图军学","英雄共享经验池+5%，英雄所穿装备的基础属性合计提高15%。装备的独特被动、光环和技能加成不受影响。"],
		["OATH_BRIDGE_VOLLEY","桥阵协战","己方正规兵与英雄普攻攻速+10%，近战和远程均生效。"],
		["OATH_FIRST_CONTRACT","契刃先声","己方正规兵与英雄的直接普攻，对命中前生命高于70%的敌人伤害+10%。溅射和持续伤害不受影响。"]],
	"UNDEAD":[
		["ASH_REBIND","余烬缝合","己方正规兵与英雄的身体生命上限+12%，包括英雄等级成长。装备生命不受影响，当前生命不会补充。"],
		["ASH_NAME_PACT","归名血契","己方正规兵与英雄普攻吸血5%，按目标实际失去的生命计算。攻击建筑和过量伤害不提供吸血。"],
		["ASH_LANTERN_WARMTH","守灯余温","己方正规兵与英雄每秒回复3生命。只在存活且受伤时回复，满血时不储存恢复量。"],
		["ASH_CARBON_CONTRACT","炭墨秘契","己方正规兵与英雄消耗法力的主动技能伤害+8%，包括持续伤害；整段持续伤害只加成一次。有蓝单位法力上限+50，当前法力不会补充。"]],
	"MACHINE":[
		["PRESSURE_COILS","稳压线圈","己方正规兵与英雄普攻攻速+10%。"],
		["COIL_RETURN_RAIL","回流矿轨","采金毛收入+5%，增加后再计算维护费。己方建筑数值护甲+1。"],
		["COIL_SHARED_CONDENSER","共用冷凝","己方有蓝正规兵与英雄每秒法力回复+0.5，法力上限+50。当前法力不会补充。"],
		["COIL_LONG_RAIL","远轨校准","己方正规兵与英雄普攻接敌距离+20，近战和远程均生效。建筑、技能范围和可攻击的地面或空中目标种类不变。"]],
	"FOREST":[
		["LIVING_RHYTHM","织叶契约","己方正规兵与英雄普攻接敌距离+15，主动治疗量+12%。治疗加成不影响吸血、自动回复或护盾。"],
		["LEAF_MIGRATION_PATH","迁林步道","己方正规兵与英雄移速+8%。"],
		["LEAF_ROOT_MEMORY","活根记忆","英雄共享经验池+5%。己方有蓝正规兵与英雄每秒法力回复+0.3。"],
		["LEAF_FOUR_SEASONS","四季共生","己方正规兵与英雄每秒回复3生命，使用的瞬时回血、回蓝和群疗药剂效果+15%。药剂的持续恢复、护盾和增益时长不受影响。"]],
	"HIGHLAND":[
		["RIDGE_FORGING","深炉淬铠","己方正规兵与英雄数值护甲+2。"],
		["RIDGE_HEARTH_VEINS","共炉暖脉","己方正规兵与英雄每秒回复3生命。只在存活且受伤时回复，满血时不储存恢复量。"],
		["RIDGE_RIFT_EDGE","裂印锻刃","己方正规兵与英雄直接普攻伤害+10%，近战和远程均生效。溅射和持续伤害不受影响。"],
		["RIDGE_BASALT_BASTION","玄武封垒","己方建筑生命上限+50%。现有建筑保持当前生命比例，受损建筑仍需修理，已毁建筑无法恢复。"]],
	"UNDERGROUND":[
		["VEIN_STRIDE","隧道轻装","己方正规兵与英雄移速+8%。"],
		["VEIN_MYCELIAL_RETURN","菌丝转流","己方有蓝正规兵与英雄每秒法力回复+0.4，法力上限+40。当前法力不会补充。"],
		["VEIN_POISON_EDGE","毒脉淬刃","己方正规兵与英雄直接普攻附加每秒1点、持续6秒的毒伤，命中后自身移速+5%、持续2秒。同类毒取强并刷新时长，加速不叠层；与隧道轻装合计提高13%移速。"],
		["VEIN_HUNT_ECHO","追猎回响","己方正规兵与英雄的直接普攻，对命中前生命低于35%的敌人伤害+10%。溅射和持续伤害不受影响。"]],
}
const GOLD := [600,650,800,900]
const SECONDS := [30,35,40,45]
const EQUIPMENT_BASIC_PERCENT := 15
const CONSUMABLE_INSTANT_PERCENT := 15
const EQUIPMENT_INTEGER_FIELDS := ["damage_bonus","armor_bonus","max_hp_bonus","max_mana_bonus","speed_bonus","move_speed_percent","attack_speed_percent","range_bonus","magic_resist_percent"]
const EQUIPMENT_FLOAT_FIELDS := ["hp_regen_per_second","mana_regen_per_second"]

static func list_for(faction:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for index:int in range(ROWS.get(faction,[]).size()):
		var row:Array=ROWS[faction][index]
		result.append({"id":str(row[0]),"faction_id":faction,"label":str(row[1]),"name":str(row[1]),"description":str(row[2]),"max_level":1,"required_base_tier":2 if index<2 else 3,"cost":{"FOOD":0,"MATERIAL":int(GOLD[index]),"ESSENCE":0},"duration_ticks":int(SECONDS[index])*20,"research_building":"FOUNDRY","version":VERSION})
	return result

static func lookup(id:String,faction:String="")->Dictionary:
	var candidates:Array=[faction] if not faction.is_empty() else FACTIONS
	for own:String in candidates:
		for definition:Dictionary in list_for(own):
			if str(definition.id)==id:return definition
	return {}

static func research_quote(faction:String,id:String,level:int=1)->Dictionary:
	var definition:=lookup(id,faction)
	if definition.is_empty():return {"accepted":false,"error":"INVALID_FACTION_TECHNOLOGY"}
	if level!=1:return {"accepted":false,"error":"MAX_TECHNOLOGY"}
	definition.merge({"accepted":true,"error":"","technology":id,"level":1},true)
	return definition

static func context_for(subject:Dictionary,explicit:Dictionary={})->Dictionary:
	# An explicit host-owned context wins. An observation may publish a detached
	# copy for Items/readout; no command handler should accept this as authority.
	return explicit if not explicit.is_empty() else subject.get("technology_context_v4",{})

static func resolve(faction:String,levels:Dictionary)->Dictionary:
	# Old scope-specific keys remain zero for read compatibility, not as another
	# modifier path. The R5 fields below are shared by every regular/hero body.
	var result:Dictionary={"version":VERSION,"faction":faction,"active_ids":[],"revision_key":"","armor_bonus":0,"range_bonus":0,"basic_damage_percent":0,"skill_damage_percent":0,"healing_percent":0,"attack_speed_percent":0,"move_speed_percent":0,"hp_regen_per_second":0.0,"mana_regen_per_second":0.0,"max_mana_bonus":0,"max_hp_percent":0,"lifesteal_percent":0,"hero_skill_damage_percent":0,"hero_xp_percent":0,"income_percent":0,"building_armor_bonus":0,"building_max_hp_percent":0,"equipment_basic_percent":0,"consumable_instant_percent":0,"ranged_attack_speed_percent":0,"ranged_range_bonus":0,"melee_basic_damage_percent":0,"high_hp_basic_damage_percent":0,"low_hp_basic_damage_percent":0,"poison_damage_per_second":0,"poison_duration_ticks":0,"on_hit_move_speed_percent":0,"on_hit_move_duration_ticks":0,"hero_armor_bonus":0}
	for definition:Dictionary in list_for(faction):
		var id:=str(definition.id)
		if int(levels.get(id,0))<=0:continue
		result.active_ids.append(id)
		match id:
			"OATH_DRILL":result.armor_bonus=1;result.healing_percent=12
			"OATH_MILITARY_ACADEMY":result.hero_xp_percent=5;result.equipment_basic_percent=EQUIPMENT_BASIC_PERCENT
			"OATH_BRIDGE_VOLLEY":result.attack_speed_percent=10
			"OATH_FIRST_CONTRACT":result.high_hp_basic_damage_percent=10
			"ASH_REBIND":result.max_hp_percent=12
			"ASH_NAME_PACT":result.lifesteal_percent=5
			"ASH_LANTERN_WARMTH","RIDGE_HEARTH_VEINS":result.hp_regen_per_second=3.0
			"ASH_CARBON_CONTRACT":result.skill_damage_percent=8;result.max_mana_bonus=50
			"PRESSURE_COILS":result.attack_speed_percent=10
			"COIL_RETURN_RAIL":result.income_percent=5;result.building_armor_bonus=1
			"COIL_SHARED_CONDENSER":result.mana_regen_per_second=0.5;result.max_mana_bonus=50
			"COIL_LONG_RAIL":result.range_bonus=20
			"LIVING_RHYTHM":result.range_bonus=15;result.healing_percent=12
			"LEAF_MIGRATION_PATH","VEIN_STRIDE":result.move_speed_percent=8
			"LEAF_ROOT_MEMORY":result.hero_xp_percent=5;result.mana_regen_per_second=0.3
			"LEAF_FOUR_SEASONS":result.hp_regen_per_second=3.0;result.consumable_instant_percent=CONSUMABLE_INSTANT_PERCENT
			"RIDGE_FORGING":result.armor_bonus=2
			"RIDGE_RIFT_EDGE":result.basic_damage_percent=10
			"RIDGE_BASALT_BASTION":result.building_max_hp_percent=50
			"VEIN_MYCELIAL_RETURN":result.mana_regen_per_second=0.4;result.max_mana_bonus=40
			"VEIN_POISON_EDGE":result.poison_damage_per_second=1;result.poison_duration_ticks=120;result.on_hit_move_speed_percent=5;result.on_hit_move_duration_ticks=40
			"VEIN_HUNT_ECHO":result.low_hp_basic_damage_percent=10
	result.revision_key="%s:%s:%d:%d:%s"%[VERSION,faction,int(levels.get("ATTACK",0)),int(levels.get("ARMOR",0)),",".join(result.active_ids)]
	return result

static func ranged(stats:Dictionary)->bool:
	return float(stats.get("attack_range",0))>=100.0

static func unit_modifiers(faction:String,levels:Dictionary,stats:Dictionary,is_hero:bool=false)->Dictionary:
	var result:Dictionary={"armor_bonus":0,"heal_bonus":0,"healing_percent":0,"skill_damage_percent":0,"basic_damage_percent":0,"max_hp_percent":0,"max_mana_bonus":0,"attack_speed_percent":0,"move_speed_percent":0,"range_bonus":0,"hp_regen_per_second":0.0,"mana_regen_per_second":0.0,"magic_resist_percent":0}
	var type:=str(stats.get("unit_type",stats.get("id","")))
	if type=="hero":is_hero=true
	if type=="worker" or stats.has("building_type") or bool(stats.get("summoned",false)) or str(stats.get("side",""))=="NEUTRAL" or bool(stats.get("is_neutral",false)) or bool(stats.get("neutral",false)):return result
	var mods:=resolve(faction,levels)
	result.armor_bonus=int(mods.armor_bonus)
	result.healing_percent=int(mods.healing_percent)
	result.skill_damage_percent=int(mods.skill_damage_percent)
	result.basic_damage_percent=int(mods.basic_damage_percent)
	result.max_hp_percent=int(mods.max_hp_percent)
	result.attack_speed_percent=int(mods.attack_speed_percent)
	result.move_speed_percent=int(mods.move_speed_percent)
	result.hp_regen_per_second=float(mods.hp_regen_per_second)
	if int(stats.get("max_mana",0))>0:
		result.max_mana_bonus=int(mods.max_mana_bonus)
		result.mana_regen_per_second=float(mods.mana_regen_per_second)
	result.range_bonus=int(mods.range_bonus)
	return result

static func equipment_stats(raw:Dictionary,faction:String,levels:Dictionary)->Dictionary:
	var result:=raw.duplicate(true)
	if faction!="HUMAN" or int(levels.get("OATH_MILITARY_ACADEMY",0))<=0:return result
	var percent:=EQUIPMENT_BASIC_PERCENT
	for field:String in EQUIPMENT_INTEGER_FIELDS:
		if result.has(field):result[field]=(int(result[field])*(100+percent)+50)/100
	for field:String in EQUIPMENT_FLOAT_FIELDS:
		if result.has(field):result[field]=float(result[field])*(100+percent)/100.0
	return result

static func consumable_effect(raw:Dictionary,faction:String,levels:Dictionary)->Dictionary:
	var result:=raw.duplicate(true)
	if faction!="FOREST" or int(levels.get("LEAF_FOUR_SEASONS",0))<=0:return result
	var percent:=CONSUMABLE_INSTANT_PERCENT
	for field:String in ["heal","mana","ally_heal"]:
		if result.has(field):result[field]=(int(result[field])*(100+percent)+50)/100
	return result

static func building_health(old_hp:int,old_max:int,new_max:int)->int:
	# One transition, never a periodic heal. Construction and resurrection are
	# separate owners. A dead building cannot be revived by researching this.
	if old_hp<=0:return 0
	return clampi(roundi(float(old_hp)*new_max/maxi(1,old_max)),1,maxi(1,new_max))

static func percentage_reward(base:int,percent:int,carry:int=0)->Dictionary:
	var total:=maxi(0,base)*(100+maxi(0,percent))+clampi(carry,0,99)
	return {"amount":total/100,"carry":total%100}

static func basic_damage_percent(modifiers:Dictionary,attacker:Dictionary,target:Dictionary)->int:
	var result:=int(modifiers.get("basic_damage_percent",0))
	var ratio:=float(target.get("hp",0))/maxi(1,int(target.get("max_hp",1)))
	if ratio>0.70:result+=int(modifiers.get("high_hp_basic_damage_percent",0))
	if ratio<0.35:result+=int(modifiers.get("low_hp_basic_damage_percent",0))
	return result

static func preview_unit_stats(faction:String,levels:Dictionary,base:Dictionary)->Dictionary:
	# Detached reference projection of the same selected permanent modifiers.
	# It excludes equipment, live buffs, target-conditional procs and hero growth.
	var result:=base.duplicate(true)
	var mods:=unit_modifiers(faction,levels,base,str(base.get("unit_type",""))=="hero")
	result.damage=int(base.get("damage",0))+clampi(int(levels.get("ATTACK",0)),0,3)*2
	result.armor=float(base.get("armor",0))+clampi(int(levels.get("ARMOR",0)),0,3)+float(mods.armor_bonus)
	result.max_hp=roundi(float(base.get("max_hp",0))*(100+float(mods.max_hp_percent))/100.0)
	result.max_mana=int(base.get("max_mana",0))+int(mods.max_mana_bonus)
	result.attack_range=int(base.get("attack_range",0))+int(mods.range_bonus)
	result.speed_exact=float(base.get("speed",0))*(100+float(mods.move_speed_percent))/100.0
	result.attack_cooldown_ticks=maxi(4,roundi(float(base.get("attack_cooldown_ticks",20))*100.0/(100.0+clampf(float(mods.attack_speed_percent),0,100))))
	result.hp_regen_per_second=float(base.get("hp_regen_per_second",0))+float(mods.hp_regen_per_second)
	result.mana_regen_per_second=float(base.get("mana_regen_per_second",0))+float(mods.mana_regen_per_second)
	if base.has("heal"):result.heal=roundi(float(base.heal)*(1.0+float(mods.healing_percent)/100.0))+int(mods.heal_bonus)
	result["healing_percent"]=int(mods.healing_percent)
	result["skill_damage_percent"]=int(mods.skill_damage_percent)
	result["dps"]=float(result.damage)*20.0/maxi(1,int(result.attack_cooldown_ticks))
	result["attack_interval_seconds"]=float(result.attack_cooldown_ticks)/20.0
	result["movement_per_second"]=float(result.speed_exact)*20.0
	result["permanent_modifiers"]=mods
	return result
