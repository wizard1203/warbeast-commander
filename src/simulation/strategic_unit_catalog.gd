class_name StrategicUnitCatalog
extends RefCounted
const Traits = preload("res://src/simulation/strategic_combat_traits.gd")
## Single paid/physical troop directory. Recipes and observations are detached.
const Heroes=preload("res://src/simulation/strategic_hero_catalog.gd")
const Balance = preload("res://src/simulation/strategic_balance_catalog.gd")
const ArmySupport = preload("res://src/simulation/strategic_army_support.gd")
const TroopSkillsV4 = preload("res://src/simulation/strategic_troop_skills_v4.gd")
const UNITS := Balance.UNITS
const RETIRED_MILITARY := ["iron_lancer"]
const PRODUCTION_FAMILIES := {"PHYSICAL":"BARRACKS","MAGIC":"RANGE","SPECIAL":"DRAGON_ROOST"}
static var _stats_cache_m76: Dictionary = {}

static func is_recruitable(id: String) -> bool:
	return UNITS.has(id) and id not in RETIRED_MILITARY and id != "worker"

static func recruitable_recipes() -> Dictionary:
	var result := {}
	for id: String in UNITS:
		if is_recruitable(id): result[id] = UNITS[id].duplicate(true)
	return result

static func production_family_for(id: String) -> String:
	if id == "hero": return "HERO"
	if id == "worker": return "ECONOMY"
	return str(UNITS.get(id, {}).get("production_family", ""))

static func producer_for(id: String) -> String:
	return str(UNITS.get(id, {}).get("building_type", ""))

static func required_buildings_for(id: String) -> Array[String]:
	var result: Array[String] = []
	for type: String in UNITS.get(id, {}).get("required_buildings", []): result.append(type)
	return result

static func stats_for(id: String, archetype: String=Heroes.DEFAULT_ARCHETYPE)->Dictionary:
	# Finite immutable recipes only; invalid IDs/archetypes never grow the
	# cache, and callers still receive independently mutable observations.
	if id not in UNITS:return {}
	var key := id+":"+archetype if id=="hero" else id
	if _stats_cache_m76.has(key):return _stats_cache_m76[key].duplicate(true)
	var result := _uncached_stats_m76(id,archetype)
	if id!="hero" or archetype in Heroes.ARCHETYPES:_stats_cache_m76[key]=result.duplicate(true)
	return result

static func _uncached_stats_m76(id: String, archetype: String=Heroes.DEFAULT_ARCHETYPE)->Dictionary:
	if id not in UNITS:return {}
	var recipe: Dictionary=UNITS[id]
	var result: Dictionary=Heroes.profile(archetype).get("stats",{}).duplicate(true) if id=="hero" else recipe.stats.duplicate(true)
	if result.is_empty():return {}
	for key: String in ["label","population","radius","movement_layer","attack_layers","body_kind","visual_height","tags","faction_id","role"]:
		result[key]=recipe[key].duplicate(true) if recipe[key] is Array or recipe[key] is Dictionary else recipe[key]
	for key:String in ["combat_role","combat_role_label","role_capabilities","role_brief","strengths","weaknesses"]:
		if recipe.has(key):result[key]=recipe[key].duplicate(true) if recipe[key] is Array else recipe[key]
	if id=="hero":
		var hero: Dictionary=Heroes.profile(archetype)
		result["label"]=hero.stats.label
		result["faction_id"]=hero.faction_id
		result["body_kind"]=hero.get("body_kind","HUMANOID")
		result["attack_layers"]=hero.get("attack_layers",["GROUND"]).duplicate()
		if hero.faction_id=="MACHINE":result["tags"].append("MACHINE")
	result["unit_type"]=id
	result["production_family"] = production_family_for(id)
	result["required_base_tier"] = int(recipe.required_base_tier)
	result["required_buildings"] = required_buildings_for(id)
	if recipe.has("visual_unit_type"): result["visual_unit_type"] = recipe.visual_unit_type
	if id == "hero":
		result["armor_type"] = "SACRED"
		result["trait_id"] = "SACRED_OFFICER"
		result["trait_name"] = "神圣长官"
		result["trait_description"] = "神圣护甲按攻击类型承受65%至80%的伤害，再计算数值护甲；普攻为混乱类型。眩晕、定身与减速时长先乘70%，再计算控制抗性。占5人口。"
	elif id == "worker":
		result.merge({"attack_type":"EDGE","armor_type":"UNARMORED","trait_id":"CIVILIAN","trait_name":"自卫工人","trait_description":"260生命、6点近战攻击、1点数值护甲，优先从事经济工作，附近受威胁时会自卫。无甲承受110%类型伤害，混乱为105%，之后再计算数值护甲。阵亡不提供经验。"})
	else: result.merge(Traits.troop(id), true)
	var troop_ability := TroopSkillsV4.ability_for(id)
	if not troop_ability.is_empty():
		result["troop_ability"] = troop_ability
		result["trait_description"] = str(result.get("trait_description","")) + "\n" + str(troop_ability.description)
	var basic_proc := TroopSkillsV4.proc_for(id)
	if not basic_proc.is_empty(): result["basic_proc_v4"] = basic_proc
	if ArmySupport.CATALOG.has(id):
		result["support_ability"]=ArmySupport.CATALOG[id].duplicate(true)
		result["trait_description"]=str(result.get("trait_description",""))+"\n"+str(result.support_ability.description)
	return result

static func profile(id: String, archetype: String=Heroes.DEFAULT_ARCHETYPE)->Dictionary:
	if id not in UNITS:return {}
	var result: Dictionary=UNITS[id].duplicate(true)
	result["production_family"] = production_family_for(id)
	result["recruitable"] = is_recruitable(id)
	result["required_buildings"] = required_buildings_for(id)
	result["stats"]=stats_for(id,archetype)
	return result

static func get_units_for_faction(faction_id: String)->Dictionary:
	var result: Dictionary={}
	var heroes:=Heroes.available_for_faction(faction_id)
	if heroes.is_empty():return result
	for id: String in UNITS:
		if is_recruitable(id) and (UNITS[id].faction_id=="" or UNITS[id].faction_id==faction_id):result[id]=profile(id,heroes[0])
	return result

static func get_catalog()->Dictionary:
	var result: Dictionary={}
	for id: String in UNITS:
		if is_recruitable(id): result[id]=profile(id)
	return result
