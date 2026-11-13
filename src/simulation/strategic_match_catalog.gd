class_name StrategicMatchCatalog
extends RefCounted
const Economy = preload("res://src/simulation/strategic_economy_catalog.gd")
const Maps=preload("res://src/simulation/strategic_map_catalog.gd")
const Difficulty=preload("res://src/simulation/strategic_ai_difficulty.gd")
const Factions=preload("res://src/simulation/strategic_faction_catalog.gd")
const Outposts=preload("res://src/simulation/strategic_outpost_rules.gd")
const Currency=preload("res://src/simulation/strategic_currency.gd")
const FirstRelease=preload("res://src/simulation/first_release_catalog.gd")
const SIDE_IDS := ["PLAYER","AI","AI_2","AI_3"]
const FACTIONS := FirstRelease.FACTION_IDS
const CONTROLLERS := ["HUMAN","AI"]
static func default_request() -> Dictionary:
	return {"map_id":"borderlands","participants":[{"faction_id":FirstRelease.DEFAULT_PLAYER_FACTION,"controller":"HUMAN","difficulty_id":"EASY"},{"faction_id":FirstRelease.DEFAULT_OPPONENT_FACTION,"controller":"AI","difficulty_id":"EASY"}]}
static func get_catalog() -> Dictionary:
	return {"maps":Maps.get_catalog(),"factions":FACTIONS.duplicate(),"controllers":CONTROLLERS.duplicate(),"difficulties":["EASY","STANDARD","HARD"],"side_ids":SIDE_IDS.duplicate()}
static func resolve(request: Dictionary) -> Dictionary:
	for field: Variant in request:
		if field not in ["map_id","participants"]: return _reject("INVALID_MATCH_CONFIG")
	var map_id: Variant=request.get("map_id","borderlands")
	if not map_id is String: return _reject("INVALID_MAP")
	var map: Dictionary=Maps.get_map(map_id)
	if map.is_empty(): return _reject("INVALID_MAP")
	var participants: Variant=request.get("participants",default_request().participants)
	if not participants is Array or participants.size()<2 or participants.size()>int(map.max_players): return _reject("INVALID_PARTICIPANT_COUNT")
	var sides: Array[Dictionary]=[]
	for index: int in range(participants.size()):
		var slot: Variant=participants[index]
		if not slot is Dictionary or slot.size()<3 or slot.size()>4: return _reject("INVALID_PARTICIPANT")
		for field: Variant in slot:
			if field not in ["faction_id","controller","difficulty_id","starting_hero"]: return _reject("INVALID_PARTICIPANT")
		if not slot.get("faction_id") is String or slot.faction_id not in FACTIONS: return _reject("INVALID_FACTION")
		if not slot.get("controller") is String or slot.controller not in CONTROLLERS: return _reject("INVALID_CONTROLLER")
		if not Difficulty.is_valid(slot.get("difficulty_id")): return _reject("INVALID_AI_DIFFICULTY")
		var starting_hero: Variant = slot.get("starting_hero",Factions.default_hero(slot.faction_id))
		if not starting_hero is String or starting_hero not in Factions.heroes_for(slot.faction_id): return _reject("INVALID_STARTING_HERO")
		var side: String=SIDE_IDS[index]
		var home: Vector2i=map.homes[index]
		sides.append({"side_id":side,"faction_id":slot.faction_id,"controller":slot.controller,"difficulty_id":slot.difficulty_id,"starting_hero":starting_hero,"color_id":index,"prefix":side.to_lower(),"home":home,"home_site_id":"resource_%02d"%(index+1),"spawn_direction":Vector2i(1 if home.x<map.bounds.get_center().x else -1,0)})
	var sites: Array=map.sites.duplicate(true)
	for index: int in range(sides.size()):
		sites[index].owner=sides[index].side_id
		if map.debug and not Outposts.enabled():
			sites[4+index].owner=sides[index].side_id
			for offset: int in range(2): sites[int(map.resource_count)+index*2+offset].owner=sides[index].side_id
	var initial={"stock":{"FOOD":0,"MATERIAL":650,"ESSENCE":0},"base_tier":1,"buildings":["BASE","BARRACKS","RANGE"]}
	var config={"version":"strategic-match-v1","map_id":map.id,"map_version":map.version,"name":map.name,"debug":map.debug,"bounds":map.bounds,"sides":sides,"sites":sites,"sources":map.sources,"terrain":map.terrain,"initial_state":initial,"request":{"map_id":map.id,"participants":participants.duplicate(true)},"initial_zoom":map.initial_zoom,"camera_max_zoom":map.camera_max_zoom}
	config["ruleset"]=Outposts.VERSION
	config["outpost_mode"]=true
	config["currency_version"]=Currency.VERSION
	config["currency_key"]=Currency.KEY
	for key: String in ["authored_layout_version","expected_site_counts","expected_slot_count","physical_biomes","reserved_routes","route_layout_version"]:
		if map.has(key):config[key]=map[key].duplicate(true) if map[key] is Dictionary or map[key] is Array else map[key]
	return {"accepted":true,"error":"","match_config":config.duplicate(true)}
static func _reject(reason: String) -> Dictionary:
	return {"accepted":false,"error":reason}
