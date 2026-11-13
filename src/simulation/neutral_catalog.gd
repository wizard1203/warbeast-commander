extends RefCounted
## Neutral strength is a role budget, not the paid player's technology tree.
## The same finite camp slots can wear a faction deserter or wilderness guise.
const VERSION := "outposts-v4-neutral-final-budget-r6"
const PREVIOUS_VERSION := "outposts-v4-neutral-final-budget-v1"
const BASELINE_VERSION := "outposts-v3-final-neutral-budget"
const STRENGTH_MULTIPLIERS := {"STRAGGLER":4,"RAIDER":4,"HUNTER":3,"BRUTE":3,"TRIAL_GUARD":2,"TRIAL_SENTINEL":2}
# This is the complete V3 visual identity read-set, not a dependency on the
# evolving paid roster. Retiring iron_lancer or reworking a caster cannot
# silently alter the historical neutral weapon/armor/body contract.
const BASELINE_VISUAL_METADATA := {
	"hinge_guard":{"attack_type":"EDGE","armor_type":"MAIL","body_kind":"HUMANOID"},
	"bright_crossbow":{"attack_type":"PIERCE","armor_type":"LIGHT","body_kind":"HUMANOID"},
	"iron_lancer":{"attack_type":"EDGE","armor_type":"PLATE","body_kind":"HUMANOID"},
	"grove_mender":{"attack_type":"ARCANE","armor_type":"CLOAK","body_kind":"HUMANOID"},
	"ash_guard":{"attack_type":"EDGE","armor_type":"MAIL","body_kind":"BONE"},
	"bone_archer":{"attack_type":"ARCANE","armor_type":"CLOAK","body_kind":"BONE"},
	"stitched_guard":{"attack_type":"IMPACT","armor_type":"PLATE","body_kind":"HEAVY_BONE"},
	"ember_mender":{"attack_type":"ARCANE","armor_type":"CLOAK","body_kind":"BONE"},
	"rivet_guard":{"attack_type":"IMPACT","armor_type":"PLATE","body_kind":"MACHINE"},
	"shard_gunner":{"attack_type":"GUNPOWDER","armor_type":"MAIL","body_kind":"MACHINE"},
	"gear_engine":{"attack_type":"GUNPOWDER","armor_type":"PLATE","body_kind":"VEHICLE"},
	"repair_drone":{"attack_type":"ARCANE","armor_type":"MAIL","body_kind":"MACHINE"},
	"vine_guard":{"attack_type":"EDGE","armor_type":"MAIL","body_kind":"HUMANOID"},
	"leaf_archer":{"attack_type":"PIERCE","armor_type":"LIGHT","body_kind":"HUMANOID"},
	"stag_rider":{"attack_type":"EDGE","armor_type":"MAIL","body_kind":"STAG"},
	"root_mender":{"attack_type":"ARCANE","armor_type":"CLOAK","body_kind":"HUMANOID"},
	"ridge_guard":{"attack_type":"IMPACT","armor_type":"PLATE","body_kind":"HUMANOID"},
	"stone_slinger":{"attack_type":"IMPACT","armor_type":"MAIL","body_kind":"HUMANOID"},
	"rune_keeper":{"attack_type":"ARCANE","armor_type":"CLOAK","body_kind":"HUMANOID"},
	"chitin_guard":{"attack_type":"EDGE","armor_type":"MAIL","body_kind":"MULTILEG"},
	"echo_shooter":{"attack_type":"PIERCE","armor_type":"LIGHT","body_kind":"MULTILEG"},
	"tunnel_rider":{"attack_type":"EDGE","armor_type":"MAIL","body_kind":"LIZARD"},
	"spore_mender":{"attack_type":"ARCANE","armor_type":"CLOAK","body_kind":"MULTILEG"},
}
const TEMPLATE_IDS := ["RAIDER","HUNTER","BRUTE","TRIAL_GUARD","TRIAL_SENTINEL","STRAGGLER"]
const TEMPLATES := {
	"STRAGGLER":{"label":"荒径游兵","level":1,"max_hp":100,"damage":5,"armor":0,"attack_range":38,"attack_cooldown_ticks":28,"speed":4,"radius":11,"attack_type":"EDGE","armor_type":"UNARMORED","xp_reward":6,"body_kind":"HUMANOID","visual_height":28},
	"RAIDER":{"label":"荒野斥候","level":1,"max_hp":195,"damage":9,"armor":0,"attack_range":38,"attack_cooldown_ticks":22,"speed":5,"radius":12,"attack_type":"EDGE","armor_type":"UNARMORED","xp_reward":12,"body_kind":"HUMANOID","visual_height":30},
	"HUNTER":{"label":"荒野猎手","level":2,"max_hp":285,"damage":12,"armor":1,"attack_range":145,"attack_cooldown_ticks":26,"speed":5,"radius":12,"attack_type":"PIERCE","armor_type":"LIGHT","xp_reward":24,"body_kind":"HUMANOID","visual_height":32},
	"BRUTE":{"label":"岩壳守卫","level":3,"max_hp":495,"damage":17,"armor":2,"attack_range":44,"attack_cooldown_ticks":24,"speed":4,"radius":17,"attack_type":"IMPACT","armor_type":"PLATE","xp_reward":24,"body_kind":"MACHINE","visual_height":40},
	"TRIAL_GUARD":{"label":"试境护卫","level":4,"max_hp":795,"damage":22,"armor":3,"attack_range":48,"attack_cooldown_ticks":24,"speed":5,"radius":18,"attack_type":"IMPACT","armor_type":"PLATE","xp_reward":36,"body_kind":"MACHINE","visual_height":42},
	"TRIAL_SENTINEL":{"label":"试境主将","level":6,"max_hp":1920,"damage":31,"armor":5,"attack_range":160,"attack_cooldown_ticks":28,"speed":4,"radius":22,"attack_type":"ARCANE","armor_type":"CLOAK","xp_reward":96,"body_kind":"MACHINE","visual_height":48},
}
const SERIES_IDS := ["OATH_EXILE","ASH_EXILE","COIL_EXILE","LEAF_EXILE","RIDGE_EXILE","TUNNEL_EXILE","ROCKKIN","SPOREBROOD","ROAD_BAND","THORN_WATCH","GRAVEBOUND","RUNE_WILD"]
const SERIES := {
	"OATH_EXILE":{"label":"失旗誓图军","faction":"HUMAN","hp_percent":100,"damage_percent":100,"armor_add":0,"speed_add":0,"skill":"NEUTRAL_SMITE","visuals":["hinge_guard","bright_crossbow","iron_lancer","iron_lancer","grove_mender"]},
	"ASH_EXILE":{"label":"离契灰骨军","faction":"UNDEAD","hp_percent":108,"damage_percent":95,"armor_add":-1,"speed_add":-1,"skill":"NEUTRAL_DRAIN","visuals":["ash_guard","bone_archer","stitched_guard","stitched_guard","ember_mender"]},
	"COIL_EXILE":{"label":"失控铆炉军","faction":"MACHINE","hp_percent":104,"damage_percent":96,"armor_add":1,"speed_add":-1,"skill":"NEUTRAL_SHARD","visuals":["rivet_guard","shard_gunner","gear_engine","gear_engine","repair_drone"]},
	"LEAF_EXILE":{"label":"断枝织叶军","faction":"FOREST","hp_percent":94,"damage_percent":103,"armor_add":-1,"speed_add":1,"skill":"NEUTRAL_ROOT","visuals":["vine_guard","leaf_archer","stag_rider","stag_rider","root_mender"]},
	"RIDGE_EXILE":{"label":"离垒烬脊军","faction":"HIGHLAND","hp_percent":110,"damage_percent":94,"armor_add":1,"speed_add":-1,"skill":"NEUTRAL_WARD","visuals":["ridge_guard","stone_slinger","ridge_guard","ridge_guard","rune_keeper"]},
	"TUNNEL_EXILE":{"label":"迷途穴鸣军","faction":"UNDERGROUND","hp_percent":92,"damage_percent":106,"armor_add":0,"speed_add":1,"skill":"NEUTRAL_VENOM","visuals":["chitin_guard","echo_shooter","tunnel_rider","tunnel_rider","spore_mender"]},
	"ROCKKIN":{"label":"古岩眷族","faction":"","hp_percent":110,"damage_percent":94,"armor_add":1,"speed_add":-1,"skill":"NEUTRAL_WARD","attack_type":"IMPACT","armor_type":"PLATE","visuals":["neutral_brute","neutral_brute","neutral_brute","neutral_trial_guard","neutral_trial_sentinel"],"body_kind":"MACHINE"},
	"SPOREBROOD":{"label":"菌光蛛群","faction":"","hp_percent":96,"damage_percent":103,"armor_add":-1,"speed_add":1,"skill":"NEUTRAL_VENOM","attack_type":"ARCANE","armor_type":"CLOAK","visuals":["chitin_guard","echo_shooter","chitin_guard","tunnel_rider","spore_mender"],"body_kind":"MULTILEG"},
	"ROAD_BAND":{"label":"荒路掠团","faction":"","hp_percent":92,"damage_percent":106,"armor_add":0,"speed_add":1,"skill":"NEUTRAL_SHARD","attack_type":"PIERCE","armor_type":"LIGHT","visuals":["neutral_raider","neutral_hunter","neutral_raider","neutral_hunter","neutral_raider"],"body_kind":"HUMANOID"},
	"THORN_WATCH":{"label":"荆棘守望","faction":"","hp_percent":100,"damage_percent":100,"armor_add":0,"speed_add":0,"skill":"NEUTRAL_ROOT","attack_type":"PIERCE","armor_type":"MAIL","visuals":["vine_guard","leaf_archer","vine_guard","stag_rider","root_mender"],"body_kind":"HUMANOID"},
	"GRAVEBOUND":{"label":"无名墓卫","faction":"","hp_percent":108,"damage_percent":96,"armor_add":-1,"speed_add":-1,"skill":"NEUTRAL_DRAIN","attack_type":"EDGE","armor_type":"MAIL","visuals":["ash_guard","bone_archer","stitched_guard","stitched_guard","ember_mender"],"body_kind":"BONE"},
	"RUNE_WILD":{"label":"荒炉符灵","faction":"","hp_percent":96,"damage_percent":105,"armor_add":0,"speed_add":0,"skill":"NEUTRAL_SMITE","attack_type":"ARCANE","armor_type":"CLOAK","visuals":["rune_keeper","rune_keeper","rune_keeper","rune_keeper","rune_keeper"],"body_kind":"HUMANOID"},
}
const SKILLS := {
	"NEUTRAL_SMITE":{"id":"NEUTRAL_SMITE","label":"碎地震击","description":"对一名军人造成28点撞击基础伤害，短暂眩晕0.5秒；神圣护甲使控制时长减半。冷却6秒。","damage":28,"attack_type":"IMPACT","control":"STUN","control_ticks":10,"range":180,"max_targets":1,"cooldown_ticks":120},
	"NEUTRAL_DRAIN":{"id":"NEUTRAL_DRAIN","label":"归灰汲取","description":"对一名军人造成26点斩击基础伤害，自己恢复最多12生命；不会超过缺失生命。冷却7秒。","damage":26,"attack_type":"EDGE","self_heal":12,"range":180,"max_targets":1,"cooldown_ticks":140},
	"NEUTRAL_SHARD":{"id":"NEUTRAL_SHARD","label":"裂晶弹","description":"对一名军人造成26点火药基础伤害，降低1点护甲2秒；刷新而不叠层。冷却7秒。","damage":26,"attack_type":"GUNPOWDER","status_kind":"ARMOR_BREAK","status_power":1,"status_duration_ticks":40,"range":190,"max_targets":1,"cooldown_ticks":140},
	"NEUTRAL_ROOT":{"id":"NEUTRAL_ROOT","label":"缠根脉冲","description":"对最多两名军人各造成20点奥术基础伤害，定身0.6秒；神圣护甲使控制时长减半。冷却8秒。","damage":20,"attack_type":"ARCANE","control":"ROOT","control_ticks":12,"range":170,"max_targets":2,"cooldown_ticks":160},
	"NEUTRAL_VENOM":{"id":"NEUTRAL_VENOM","label":"孢毒喷吐","description":"对一名军人造成20点奥术基础伤害并中毒3秒，每秒2点奥术基础伤害；刷新不叠层。冷却7秒。","damage":20,"attack_type":"ARCANE","status_kind":"POISON","status_power":2,"status_duration_ticks":60,"range":180,"max_targets":1,"cooldown_ticks":140},
	"NEUTRAL_WARD":{"id":"NEUTRAL_WARD","label":"符壳反击","description":"对一名军人造成22点奥术基础伤害，自己获得2点护甲2秒；不会永久叠加。冷却7秒。","damage":22,"attack_type":"ARCANE","self_armor":2,"self_armor_ticks":40,"range":180,"max_targets":1,"cooldown_ticks":140},
}

static func profile(id: String) -> Dictionary:
	for template_id: String in TEMPLATE_IDS:
		for series_id: String in SERIES_IDS:
			if id == _id(series_id,template_id): return _profile(series_id,template_id)
	return {}

static func get_catalog() -> Dictionary:
	var result := {}
	for template_id: String in TEMPLATE_IDS:
		for series_id: String in SERIES_IDS:
			var entry := _profile(series_id,template_id)
			result[entry.id] = entry
	return result

static func profiles_for_template(template_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if template_id not in TEMPLATES: return result
	for series_id: String in SERIES_IDS: result.append(_profile(series_id,template_id))
	return result

static func baseline_profile(id: String) -> Dictionary:
	for template_id: String in TEMPLATE_IDS:
		for series_id: String in SERIES_IDS:
			if id == _id(series_id,template_id): return _baseline_profile(series_id,template_id)
	return {}

static func pre_reduction_profile(id: String) -> Dictionary:
	# Read-only comparison against the immediately previous final catalog.
	for template_id: String in TEMPLATE_IDS:
		for series_id: String in SERIES_IDS:
			if id == _id(series_id,template_id): return _profile_before_reduction(series_id,template_id)
	return {}

static func baseline_profiles_for_template(template_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if template_id not in TEMPLATES: return result
	for series_id: String in SERIES_IDS: result.append(_baseline_profile(series_id,template_id))
	return result

static func select_profile(template_id: String, seed: int, camp_id: String, slot: int) -> Dictionary:
	if template_id not in TEMPLATES or camp_id.is_empty() or slot < 0: return {}
	# A local integer fold, never global random state or a per-tick reroll.
	var value := posmod(seed,2147483647)
	var key := "%s:%s:%d" % [camp_id,template_id,slot]
	for index: int in range(key.length()): value = posmod(value * 31 + key.unicode_at(index),2147483647)
	return _profile(SERIES_IDS[posmod(value,SERIES_IDS.size())],template_id)

static func _id(series_id: String, template_id: String) -> String:
	return series_id.to_lower()+"_"+template_id.to_lower()

static func _baseline_profile(series_id: String, template_id: String) -> Dictionary:
	var series: Dictionary = SERIES[series_id]
	var result: Dictionary = TEMPLATES[template_id].duplicate(true)
	var visual: String = series.visuals[0 if template_id=="STRAGGLER" else TEMPLATE_IDS.find(template_id)]
	var source: Dictionary = BASELINE_VISUAL_METADATA.get(visual,{})
	result.merge({"id":_id(series_id,template_id),"template_id":template_id,"series_id":series_id,"series_label":series.label,"origin_faction_id":series.faction,"origin_unit_type":visual if not str(series.faction).is_empty() else "","unit_type":visual,"skill":SKILLS[series.skill].duplicate(true) if template_id=="TRIAL_SENTINEL" else {}})
	result.label = "%s·%s" % [series.label,result.label]
	result.max_hp = (int(result.max_hp)*int(series.hp_percent)+50)/100
	result.damage = maxi(1,(int(result.damage)*int(series.damage_percent)+50)/100)
	result.armor = maxi(0,int(result.armor)+int(series.armor_add))
	result.speed = maxi(2,int(result.speed)+int(series.speed_add))
	result.attack_type = str(series.get("attack_type",source.get("attack_type",result.attack_type)))
	result.armor_type = str(series.get("armor_type",source.get("armor_type",result.armor_type)))
	result.body_kind = str(series.get("body_kind",source.get("body_kind",result.body_kind)))
	result["attack_layers"] = ["GROUND","AIR"] if template_id in ["HUNTER","TRIAL_SENTINEL"] else ["GROUND"]
	result.max_hp=roundi(float(result.max_hp)*1.5)
	result.damage=roundi(float(result.damage)*1.5)
	if not result.skill.is_empty():
		result["max_mana"]=180
		result["mana_regen_per_second"]=1.0
		result.skill["mana_cost"]=25
		result.skill.damage=roundi(float(result.skill.damage)*1.5)
		if result.skill.has("self_heal"):result.skill.self_heal=roundi(float(result.skill.self_heal)*1.5)
		result.skill.description="%s；直接基础伤害%d，消耗25蓝量，冷却%.1f秒；其余控制、持续伤害与防护规则不变。"%[str(result.skill.label),int(result.skill.damage),float(result.skill.cooldown_ticks)/20.0]
	result["description"]="等级%d；%s。按营地同级预算调整生命、攻击与护甲，不继承玩家科技或完整兵种特性。警戒外返巢恢复；整营只掉一份战利品、只发一次资源奖励。"%[result.level,"跨族流亡守军" if not str(series.faction).is_empty() else "荒野原生支系"]
	if template_id=="STRAGGLER":result["description"]="等级1荒径弱营；不继承玩家科技。每只6经验（附近己方英雄平摊）、实际击杀方5矿材赏金。无整营奖金、不掉装备、不加人口、不复活；警戒外返巢恢复。"
	result["catalog_version"]=BASELINE_VERSION
	return result

static func _profile(series_id: String, template_id: String) -> Dictionary:
	# Project once from a fresh previous-final profile, never from runtime HP.
	# Only basic weapon damage and maximum HP change; skills/rewards stay exact.
	var result:=_profile_before_reduction(series_id,template_id)
	result["previous_catalog_version"]=PREVIOUS_VERSION
	result["previous_max_hp"]=int(result.max_hp)
	result["previous_damage"]=int(result.damage)
	result["baseline_strength_multiplier"]=int(result.strength_multiplier)
	result.erase("strength_multiplier")
	result.max_hp=maxi(1,(int(result.max_hp)*70+50)/100)
	result.damage=maxi(1,(int(result.damage)*80+50)/100)
	result["catalog_version"]=VERSION
	result["adjustment"]={"max_hp_percent":70,"basic_damage_percent":80,"rounding":"nearest-positive-integer"}
	result["description"]="等级%d · %s。守卫野外营地，离巢过远时返回并恢复生命。清除营地可获得金币；有宝物的营地至少掉落1件，50%%概率额外掉落1件。"%[result.level,"流亡守军" if not str(result.origin_faction_id).is_empty() else "荒野生物"]
	if template_id=="STRAGGLER":result["description"]="等级1荒径游兵。每只提供%d经验，由附近己方英雄平分；2只营总赏金15金币，3只营23金币，逐只击杀领取。不掉落装备，清除后不再刷新；离巢过远会返回并恢复生命。"%int(result.xp_reward)
	return result

static func _profile_before_reduction(series_id: String, template_id: String) -> Dictionary:
	# Exactly one projection from the preserved *final* V3 result. This is not
	# a runtime buff and querying repeatedly can never compound the factor.
	var result:=_baseline_profile(series_id,template_id)
	var factor:int=STRENGTH_MULTIPLIERS[template_id]
	result.max_hp=int(result.max_hp)*factor
	result.damage=int(result.damage)*factor
	result.xp_reward=roundi(float(result.xp_reward)*1.5)
	result["catalog_version"]=PREVIOUS_VERSION
	result["baseline_version"]=BASELINE_VERSION
	result["strength_multiplier"]=factor
	if not result.skill.is_empty():
		result.skill.damage=int(result.skill.damage)*factor
		if result.skill.has("self_heal"):result.skill.self_heal=int(result.skill.self_heal)*factor
		if str(result.skill.get("status_kind","")) in ["POISON","BURN"]:
			result.skill.status_power=float(result.skill.status_power)*float(factor)
		result.skill["description"]=_skill_description(result.skill)
	result["description"]="等级%d；%s。V4相对V3最终战力预算×%d，经验%d。护甲、移速、射程与控制时长不额外放大，不继承玩家科技。警戒外返巢恢复；整营金币仅结算一次，原有掉落营地保底一件、固定种子50%%额外一件，同质量表。"%[result.level,"跨族流亡守军" if not str(result.origin_faction_id).is_empty() else "荒野原生支系",factor,int(result.xp_reward)]
	if template_id=="STRAGGLER":result["description"]="等级1荒径游兵；V4相对V3最终生命与普攻×4。每只9经验，由附近己方英雄平摊；两只营合计15金币、三只营23金币，按固定成员顺序分为7或8金币。没有整营奖金、装备、人口或复活；警戒外返巢恢复。"
	return result

static func _skill_description(skill:Dictionary)->String:
	var parts:Array[String]=["%s：对最多%d名军人造成%d点%s基础伤害"%[str(skill.label),int(skill.get("max_targets",1)),int(skill.damage),{"IMPACT":"撞击","EDGE":"斩击","ARCANE":"奥术","GUNPOWDER":"火药"}.get(str(skill.attack_type),str(skill.attack_type))]]
	var control:=str(skill.get("control",""))
	if control in ["ROOT","STUN"]:parts.append("%s%.2f秒；英雄先保留70%%时长，再乘控制抗性"%["定身" if control=="ROOT" else "眩晕",float(skill.control_ticks)/20.0])
	var status:=str(skill.get("status_kind",""))
	if status in ["POISON","BURN"]:
		var duration:=float(skill.status_duration_ticks)/20.0
		parts.append("%s%.1f秒，每秒%.1f点基础伤害（完整总量%.1f）；同类取强、刷新"%["中毒" if status=="POISON" else "灼烧",duration,float(skill.status_power),float(skill.status_power)*duration])
	elif status=="ARMOR_BREAK":parts.append("降低%d点护甲%.1f秒，刷新不叠层"%[int(skill.status_power),float(skill.status_duration_ticks)/20.0])
	if int(skill.get("self_heal",0))>0:parts.append("自己最多恢复%d生命，不超过缺血"%int(skill.self_heal))
	if int(skill.get("self_armor",0))>0:parts.append("自己获得%d护甲%.1f秒，不永久叠加"%[int(skill.self_armor),float(skill.self_armor_ticks)/20.0])
	parts.append("消耗%dMP，冷却%.1f秒"%[int(skill.get("mana_cost",25)),float(skill.cooldown_ticks)/20.0])
	return "；".join(parts)+"。"
