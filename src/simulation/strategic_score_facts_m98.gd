extends RefCounted
## Host-internal, detached input for the unchanged MatchScores observer.
## Never a second economy or combat authority; rebuilt only at the existing
## score refresh boundary. Public snapshot ownership/format stays unchanged.
const Heroes=preload("res://src/simulation/strategic_hero_catalog.gd")
const Buffs=preload("res://src/simulation/strategic_combat_buffs.gd")
const BUILDING_FIELDS:=["side","hp","max_hp","complete","fixed","building_type","cost","base_tier","tower_level","faction_id","defense_active","damage","attack_cooldown_ticks"]

static func _fields(row:Dictionary,keys:Array)->Dictionary:
	var result:Dictionary={}
	for key:String in keys:
		if not row.has(key):continue
		var value:Variant=row[key]
		result[key]=value.duplicate(true) if value is Dictionary or value is Array else value
	return result

static func world(owner:RefCounted)->Dictionary:
	var workers:Array=[];var buildings:Array=[];var economy:Dictionary={}
	for body:Dictionary in owner._workers:workers.append(_fields(body,["side","hp","max_hp"]))
	for building:Dictionary in owner._buildings:buildings.append(_fields(building,BUILDING_FIELDS))
	for side:String in owner._economy:economy[side]=_fields(owner._economy[side],["stock","delivered"])
	return {"workers":workers,"buildings":buildings,"economy":economy,"technology":owner.get_technology()}

static func combat(owner:RefCounted)->Dictionary:
	var soldiers:Array=[];var officers:Array=[];var statistics:Array=[]
	for body:Dictionary in owner._ordered_units():soldiers.append(_fields(body,["side","unit_type","hp","max_hp"]))
	for id:String in owner._sorted_keys(owner._hero_data):
		var hero:Dictionary=owner._hero_data[id];var body:Dictionary=owner._soldiers[id]
		var row:Dictionary=_fields(hero,["id","unit_id","level","mana","max_mana","equipment"])
		row.merge(_fields(body,["side","hp","max_hp"]))
		var skills:Array=[]
		for skill_id:String in Heroes.profile(hero.archetype).skill_ids:
			# Resolve through the existing content interface, including rank zero
			# and expansion catalogs, instead of inventing a second rank rule.
			var skill:Dictionary=Heroes.skill_at_level(skill_id,int(hero.skill_levels.get(skill_id,0)))
			skills.append(_fields(skill,["level"]))
		row["skills"]=skills;officers.append(row)
		# Legacy full publication calls Buffs.values while publishing each skill.
		# Its expired/exhausted/dead-source cleanup is observable authority. One
		# call has the same final cleanup as the three old calls, no action occurs
		# between them. Do not silently drop this side effect with display work.
		Buffs.values(body,owner._tick,owner._soldiers)
	# Preserve the registration boundary from get_hero_statistics, but do not
	# format/copy its unrelated per-skill history just to sum four kill counts.
	for id:String in owner._sorted_keys(owner._hero_data):owner._hero_statistics.register(owner._soldiers[id],owner._hero_data[id])
	for id:String in owner._sorted_keys(owner._hero_statistics._heroes):statistics.append(_fields(owner._hero_statistics._heroes[id],["side","hero_kills","unit_kills","neutral_kills","building_kills"]))
	return {"soldiers":soldiers,"heroes":{"officers":officers},"hero_statistics":{"heroes":statistics}}
