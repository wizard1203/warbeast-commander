extends RefCounted
## Detached public-arena projection. Never calls the live Combat, forecasts a
## fight, charges resources, or uses the editor's next-match roster as history.
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const LocalBattle = preload("res://src/simulation/strategic_ai_local_battle_m70.gd")
const VERSION := "outposts-arena-force-readout-r19/v1"
const SIDES := ["PLAYER","AI"]

static func capture(observation: Dictionary) -> Dictionary:
	var initial := {"version":VERSION,"bodies":{},"factions":{}}
	for body: Dictionary in observation.get("soldiers",[]):
		var side := str(body.get("side",""))
		var id := str(body.get("id",""))
		if side not in SIDES or id.is_empty() or initial.bodies.has(id): continue
		var kind := str(body.get("unit_type",""))
		var hero := kind=="hero"
		var recipe: Dictionary = Units.profile(kind) if not hero else {}
		initial.bodies[id]={"id":id,"side":side,"unit_type":kind,"hero":hero,"key":"hero" if hero else kind,"population":int(body.get("population",5 if hero else recipe.get("population",1))),"label":"英雄" if hero else str(recipe.get("label",kind)),"gold_each":-1 if hero else int(recipe.get("cost",{}).get("MATERIAL",0))}
		if not initial.factions.has(side): initial.factions[side]=str(body.get("faction_id",recipe.get("faction_id","")))
	return initial

static func build(observation: Dictionary, initial: Dictionary) -> Dictionary:
	var tick := int(observation.get("tick",0))
	# Combat's trusted setup is tick -1 before its first fixed step. Retain
	# that source time for provenance/cache identity, display the ready state
	# as time zero rather than rejecting a perfectly valid deployed roster.
	var result := {"version":VERSION,"tick":maxi(0,tick),"observation_tick":tick,"sides":{},"read_only":true,"strength_scope":"现存军队8秒有限预算估计，含当前生命、护甲、MP、技能就绪度；不是胜率或完整战斗模拟，不含经济／历史成绩。","population_scope":"本类开战人口／本方全部开战人口（含英雄）；价格为当前目录单价，训练赠予不实际扣费。"}
	var alive := {}
	for body: Dictionary in observation.get("soldiers",[]):
		var id := str(body.get("id",""))
		if initial.get("bodies",{}).has(id) and int(body.get("hp",0))>0 and bool(body.get("alive",true)): alive[id]=body
	# Reuse the existing compiled force scalar. Arena is a public two-sided
	# laboratory, not an AI player's fog-of-war query. The small visibility copy
	# is detached and does not change the observation or live visibility masks.
	var soldiers: Array[Dictionary] = []
	for id: String in alive:
		var copy: Dictionary = alive[id].duplicate(false)
		copy["visible"]=true
		soldiers.append(copy)
	var frame: Dictionary = LocalBattle.prepare({"tick":tick,"soldiers":soldiers,"heroes":observation.get("heroes",{})})
	var strength := {"PLAYER":0.0,"AI":0.0}
	for body: Dictionary in frame.rows:
		var side := str(body.get("side",""))
		if side not in SIDES: continue
		var profile: Dictionary = body._m95_force_profile
		for field: String in ["basic_score","skill_score","heal_score","control_score"]: strength[side]+=maxf(0,float(profile.get(field,0)))
	for side: String in SIDES:
		var faction := str(initial.get("factions",{}).get(side,""))
		var team := {"label":"左方" if side=="PLAYER" else "右方","faction_label":str(Factions.FACTIONS.get(faction,{}).get("label","")),"alive":0,"total":0,"alive_population":0,"initial_population":0,"strength":float(strength[side]),"rows":[]}
		var groups := {}
		for id: String in initial.get("bodies",{}):
			var entry: Dictionary = initial.bodies[id]
			if str(entry.side)!=side: continue
			var key := str(entry.key)
			if not groups.has(key): groups[key]={"key":key,"unit_type":str(entry.unit_type),"label":str(entry.label),"hero":bool(entry.hero),"alive":0,"total":0,"gold_each":int(entry.gold_each),"population_each":int(entry.population),"initial_population":0,"population_share":0.0}
			var row: Dictionary = groups[key]
			row.total+=1;row.initial_population+=int(entry.population)
			team.total+=1;team.initial_population+=int(entry.population)
			if alive.has(id):
				row.alive+=1;team.alive+=1;team.alive_population+=int(entry.population)
		var keys: Array = groups.keys();keys.sort()
		for key: String in keys:
			var row: Dictionary = groups[key]
			row.population_share=float(row.initial_population)/maxi(1,int(team.initial_population))
			team.rows.append(row)
		result.sides[side]=team
	return result

static func configuration(data: Dictionary) -> Dictionary:
	## Next-match investment only. Never used as a live battle denominator.
	var result := {"population":data.get("heroes",[]).size()*5,"gold":0,"rows":{}}
	for group: Dictionary in data.get("troops",[]):
		var kind := str(group.get("unit_type",""))
		var recipe: Dictionary = Units.profile(kind)
		if recipe.is_empty() or int(group.get("count",0))<=0: continue
		var count := int(group.count)
		if not result.rows.has(kind): result.rows[kind]={"count":0,"population":0,"gold":0,"population_each":int(recipe.population),"gold_each":int(recipe.cost.get("MATERIAL",0)),"population_share":0.0}
		var row: Dictionary = result.rows[kind]
		row.count+=count;row.population+=int(recipe.population)*count;row.gold+=int(recipe.cost.get("MATERIAL",0))*count
		result.population+=int(recipe.population)*count;result.gold+=int(recipe.cost.get("MATERIAL",0))*count
	for row: Dictionary in result.rows.values(): row.population_share=float(row.population)/maxi(1,int(result.population))
	return result
