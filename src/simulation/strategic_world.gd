class_name StrategicWorld
extends RefCounted
const DamageRules = preload("res://src/simulation/strategic_damage_rules.gd")
## M11 deterministic territory, labour, construction and per-building production.
## Rendering receives deep copies; military input is derived from combat authority.

const BOUNDS := Rect2i(80, 80, 3200, 2000)
const UnitBodyResolver = preload("res://src/simulation/unit_body_resolver.gd")
const WorkerBodyMotion = preload("res://src/simulation/worker_body_motion.gd")
const HeroCatalog = preload("res://src/simulation/strategic_hero_catalog.gd")
const HeroEconomy = preload("res://src/simulation/strategic_hero_economy.gd")
const HeroItems = preload("res://src/simulation/strategic_hero_items.gd")
const Progression = preload("res://src/simulation/strategic_progression_catalog.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const FootprintR10 = preload("res://src/simulation/strategic_body_footprint_r10.gd")
const Economy = preload("res://src/simulation/strategic_economy_catalog.gd")
const Balance = preload("res://src/simulation/strategic_balance_catalog.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Matches = preload("res://src/simulation/strategic_match_catalog.gd")
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const FieldObjectives = preload("res://src/simulation/strategic_field_objectives.gd")
const NeutralEncounters = preload("res://src/simulation/strategic_neutral_encounters.gd")
const FactionTowers = preload("res://src/simulation/strategic_faction_towers.gd")
const MilitaryFactsM93 = preload("res://src/simulation/strategic_military_facts_m93.gd")
const Outposts = preload("res://src/simulation/strategic_outpost_rules.gd")
const Currency = preload("res://src/simulation/strategic_currency.gd")
const SIDES := ["PLAYER", "AI"]
const ROLES := ["FOOD", "MATERIAL", "ESSENCE", "CONSTRUCTION_REPAIR", "RESERVE"]
const CAPTURE_RADIUS := 180
const CAPTURE_THRESHOLD := 200
const WORKER_RADIUS := 12
const WORKER_HP := 260
const WORKER_STEP := 10
const GATHER_TICKS := 30
const BASE_SITE_RADIUS := 250
const TOWER_RANGE := 240
const TOWER_DAMAGE := 5
const TOWER_COOLDOWN := 20
const MAX_QUEUE := 6
const MAX_ROUTE_OBSTACLES := 32
const DEPLOYMENT_RINGS := [32,64,96,128]
const DEPLOYMENT_DIRECTIONS := [Vector2i(1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(-1,0),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]
const BUILDING_CATALOG = Balance.WORLD_BUILDINGS
const SHOP_DEFINITION := {"label":"英雄商店","radius":30,"hp":1000,"cost":{"FOOD":0,"MATERIAL":0},"work":0}
const UNIT_CATALOG = Units.UNITS
const TechnologiesV4 = preload("res://src/simulation/strategic_faction_technologies_v4.gd")
const MAGIC_CAMP_NAMES := Factions.MAGIC_PRODUCER_NAMES
const TECHNOLOGY_CATALOG := {
	"ATTACK": {"label": "锻刃", "max_level": 3, "cost_per_level": Economy.TECH_COSTS.ATTACK, "rank_quotes":Balance.TECH_RANKS.ATTACK,"effect_per_level": 2},
	"ARMOR": {"label": "铸甲", "max_level": 3, "cost_per_level": Economy.TECH_COSTS.ARMOR,"rank_quotes":Balance.TECH_RANKS.ARMOR, "effect_per_level": 1},
}

# Derived observations live only during one synchronous worker phase.
# Not economy authority; cleared before returning.
var m84_worker_phase := false
var m84_worker_geometry: Variant = null
var m84_worker_static_bodies: Array[Dictionary] = []
var m84_worker_point_results: Dictionary = {}
var m84_worker_soldier_grid: Dictionary = {}
var m84_worker_soldier_grid_valid := false
var _m95_worker_motion: RefCounted = null
const WORKER_GRID_CELL_M84 := 128

var _seed := 1701
var _tick := 0
var _sites: Array[Dictionary] = []
var _buildings: Array[Dictionary] = []
var _workers: Array[Dictionary] = []
var _economy: Dictionary = {}
var _technology: Dictionary = {}
var _military_population: Dictionary = {"PLAYER": 17, "AI": 17}
var _last_soldiers: Array = []
var _neutral_dead_ids_r9: Dictionary = {}
var _hero_roster: Array = []
var _has_hero_roster := false
var _next_building := 1
var _next_entry := 1
var _next_worker := 6
var _next_recruit := 1
var _next_purchase := 1
var _match_config: Dictionary={}
var _sides: Array[String]=[]
var _bounds := BOUNDS
var _terrain: Array=[]
var _sources: Array[Dictionary]=[]
var _technology_queues: Dictionary={}
var _field_reward_receipts: Dictionary = {}
var _neutral_reward_receipts: Dictionary = {}
var _neutral_bounty_receipts: Dictionary = {}
var _statistics_receipt_serial := 0
var _outpost_slots: Array[Dictionary]=[]
var _auto_remainders: Dictionary={}
var _technology_compiled_v4: Dictionary={}

func is_outpost_mode() -> bool: return bool(_match_config.get("outpost_mode",false))


func _init(seed: int = 1701, canonical_match: Dictionary={}) -> void:
	reset(seed,canonical_match)


func reset(seed: int = 1701, canonical_match: Dictionary={}) -> void:
	if not canonical_match.is_empty(): _match_config=canonical_match.duplicate(true)
	elif _match_config.is_empty(): _match_config=Matches.resolve(Matches.default_request()).match_config
	_bounds=_match_config.bounds
	_sides.clear()
	for slot: Dictionary in _match_config.sides: _sides.append(str(slot.side_id))
	_terrain=_match_config.terrain.duplicate(true)
	_sources.clear()
	for source: Dictionary in _match_config.sources:
		if str(source.get("kind", source.get("resource", ""))) != Currency.KEY: continue
		var record:=source.duplicate(true)
		record["remaining"]=int(record.initial)
		_sources.append(record)
	_seed = seed
	_tick = 0
	_statistics_receipt_serial = 0
	_auto_remainders.clear()
	_technology_compiled_v4.clear()
	_outpost_slots.clear()
	_sites.clear()
	_buildings.clear()
	_workers.clear()
	_last_soldiers.clear()
	_neutral_dead_ids_r9.clear()
	_hero_roster.clear()
	_has_hero_roster = false
	_next_building = 1
	_next_entry = 1
	_next_worker = 6
	_next_recruit = 1
	_next_purchase = 1
	_military_population = {}
	_economy = {}
	_technology = {}
	_technology_queues={}
	_field_reward_receipts.clear()
	_neutral_reward_receipts.clear()
	_neutral_bounty_receipts.clear()
	for site: Dictionary in _match_config.sites:
		var record:=_new_site(site.id,site.kind,site.position,site.owner)
		if site.has("resource"):record.resource=site.resource
		if site.has("capacity"):record.capacity=site.capacity
		if site.has("label"):record.label=site.label
		if site.has("guardian_tier"):record.guardian_tier=int(site.guardian_tier)
		if site.has("rich_gold"):record.rich_gold=bool(site.rich_gold)
		_sites.append(record)
	if is_outpost_mode(): _outpost_slots=Outposts.slot_definitions(_sites)
	var offsets={"BASE":Vector2i.ZERO,"BARRACKS":Vector2i(160,100),"RANGE":Vector2i(160,-180),"TOWER":Vector2i(300,20),"FOUNDRY":Vector2i(-200,180),"ALTAR":Vector2i(-180,-180),"WORKSHOP":Vector2i(300,220),"DRAGON_ROOST":Vector2i(300,-250)}
	for slot: Dictionary in _match_config.sides:
		var side: String=slot.side_id
		var home: Vector2i=slot.home
		var mirror: int=slot.spawn_direction.x
		var prefix: String=slot.prefix
		_military_population[side]=5
		for group: Dictionary in Factions.opening_recipe(slot.faction_id):
			_military_population[side]+=int(group.count)*int(UNIT_CATALOG[group.unit_type].population)
		_economy[side] = {"stock": Currency.cost(_match_config.initial_state.stock), "targets": {"FOOD": 0, "MATERIAL": 0, "ESSENCE":0, "CONSTRUCTION_REPAIR": 0, "RESERVE": 0}, "work_site_id": slot.home_site_id,"essence_site_id":"","faction_id":slot.faction_id,"delivered":Currency.zero(),"delivered_gross":Currency.zero(),"taxed":{"MATERIAL":0},"tax_remainder_percent":{"MATERIAL":0}}
		_economy[side].stock["ESSENCE"]=int(_economy[side].stock.get("ESSENCE",0))
		if is_outpost_mode():
			for role: String in ROLES: _economy[side].targets[role]=0
		_technology[side] = {"ATTACK": 0, "ARMOR": 0}
		for definition: Dictionary in TechnologiesV4.list_for(str(slot.faction_id)):_technology[side][definition.id]=0
		_technology_queues[side]=[]
		for type: String in _match_config.initial_state.buildings:
			var point: Vector2i=home+(offsets[type] as Vector2i)*mirror
			if is_outpost_mode():
				for pad: Dictionary in _outpost_slots:
					if pad.site_id==slot.home_site_id and pad.building_type==type:point=pad.position;break
			var building:=_new_building(prefix+"_"+type.to_lower()+"_01",side,type,point,true)
			if is_outpost_mode(): _bind_outpost(building,str(slot.home_site_id))
			if type=="BASE":
				building.base_tier=int(_match_config.initial_state.base_tier)
				var stats:=Economy.building_stats("BASE",int(building.base_tier))
				building.max_hp=int(stats.hp)
				building.hp=int(stats.hp)
				building.armor=int(stats.armor)
				building["base_max_hp_v4"]=int(stats.hp)
				building["base_armor_v4"]=int(stats.armor)
				building.site_id=slot.home_site_id
				building.initial_home=true
			_buildings.append(building)
		for index: int in range(6):
			if is_outpost_mode(): break
			var position := home + Vector2i(-80 + (index % 3) * 24, 54 + int(index / 3) * 24) * mirror
			_workers.append(_new_worker(prefix + "_worker_%03d" % index, side, position, index))
		var shop_position := home if is_outpost_mode() else _initial_shop_position(home, mirror, side)
		if is_outpost_mode():
			# Initial grants obey the same authored pad as later construction.
			# A historical home+(0,-120) left SHOP unbound after layout updates,
			# overlapping BASE visually and allowing a second paid home SHOP.
			for pad: Dictionary in _outpost_slots:
				if pad.site_id==slot.home_site_id and pad.building_type=="SHOP":
					shop_position=pad.position
					break
		var shop := _new_building(prefix + "_shop_01", side, "SHOP", shop_position, true)
		if is_outpost_mode(): _bind_outpost(shop,str(slot.home_site_id))
		else: shop.merge({"fixed":true,"non_constructible":true,"attackable":false,"service_range":HeroItems.SHOP_RANGE,"original_base_id":prefix + "_base_01"})
		_buildings.append(shop)
		_reconcile_roles(side)
	_refresh_defenses()

func _initial_shop_position(home: Vector2i, mirror: int, side: String) -> Vector2i:
	for offset: Vector2i in [Vector2i(120,-260),Vector2i(-130,0),Vector2i(0,-260),Vector2i(-160,-260),Vector2i(-180,0)]:
		var position := home + offset * mirror
		if _shop_position_clear(position, home, mirror, side): return position
	# Canonical homes reserve broad clear land; this bounded search also keeps
	# edited/debug maps from overlapping an initial outlet or terrain obstacle.
	for radius: int in [160,200,240,280,320]:
		for direction: Vector2i in DEPLOYMENT_DIRECTIONS:
			var position := home + Vector2i(direction.x * mirror, direction.y) * radius
			if _shop_position_clear(position, home, mirror, side): return position
	assert(false, "Canonical initial home must admit a fixed shop")
	return home + Vector2i(160 * mirror, -80)

func _shop_position_clear(point: Vector2i, home: Vector2i, mirror: int, side: String) -> bool:
	if not _position_clear(point, 30, ""): return false
	for source: Dictionary in _sources:
		if Vector2(point).distance_to(Vector2(source.position)) < 30 + int(source.get("radius", 50)) + 12: return false
	# World is constructed before Combat. Explicitly reserve its canonical
	# initial military formation, rather than depending on an empty body cache.
	var first_type: String = Factions.units_for(get_faction(side), "FRONTLINE")[0]
	var ranged_type: String = Factions.units_for(get_faction(side), "RANGED")[0]
	var first_radius := FootprintR10.physical_radius(UNIT_CATALOG[first_type])
	var spacing := maxi(32, first_radius * 2 + 4)
	for index: int in range(6):
		var body := home + Vector2i((110 + (index % 3) * spacing) * mirror, (-100 + (index / 3) * spacing) * mirror)
		if Vector2(point).distance_to(Vector2(body)) < 30 + first_radius + 4: return false
	for index: int in range(3):
		var body := home + Vector2i((110 + index * 32) * mirror, 150 * mirror)
		if Vector2(point).distance_to(Vector2(body)) < 30 + FootprintR10.physical_radius(UNIT_CATALOG[ranged_type]) + 4: return false
	var hero := home + Vector2i(142 * mirror, -32 * mirror)
	return Vector2(point).distance_to(Vector2(hero)) >= 48 and Vector2(point).distance_to(Vector2(hero)) <= HeroItems.SHOP_RANGE

func get_match_config() -> Dictionary:
	return _match_config.duplicate(true)
func get_arena_bounds() -> Rect2i:
	return _bounds
func get_faction(side: String) -> String:
	return str(_side_config(side).get("faction_id",""))
func get_defense_muster(side: String) -> Dictionary:
	var slot:=_side_config(side)
	if slot.is_empty():return {}
	var home: Vector2i=slot.home
	for ring: int in [200,280,360]:
		for direction: Vector2i in DEPLOYMENT_DIRECTIONS:
			var point:=home+Vector2i(direction.x*int(slot.spawn_direction.x),direction.y)*ring
			if _position_clear(point,14,""):return {"position":point}
	return {}
func _side_config(side: String) -> Dictionary:
	for slot: Dictionary in _match_config.sides:
		if slot.side_id==side: return slot
	return {}
static func get_progression_catalog() -> Dictionary:
	var result: Dictionary=Progression.get_catalog()
	for id: String in UNIT_CATALOG:
		result.population[id]=UNIT_CATALOG[id].population
		result.unit_tiers[id]=UNIT_CATALOG[id].required_base_tier
	return result


func sync_military(soldiers: Array, population: Dictionary) -> void:
	# Derived observation only: no fixed tick or economic ledger changes.
	sync_owned_military_m79(soldiers.duplicate(true), population)


func sync_owned_military_m79(detached_soldiers: Array, population: Dictionary) -> void:
	# Host-only handoff: rows MUST be a fresh Combat.get_units_snapshot(),
	# never live Combat bodies or a public observation reused by its caller.
	# Keep a cheap separate container because production appends admissions and
	# reset clears this array. No nested data is copied a second time.
	_last_soldiers = detached_soldiers.duplicate()
	# Finite canonical member IDs, not entities retained for routing or capture.
	# The final current corpse must still prove the real camp-clear winner.
	for body: Dictionary in detached_soldiers:
		if bool(body.get("neutral",false)) and int(body.get("hp",1))<=0:
			if _neutral_reward_receipts.has(str(body.get("camp_id",""))+":once") or _neutral_bounty_receipts.has("bounty:"+str(body.id)):continue
			_neutral_dead_ids_r9[str(body.id)]=str(body.get("camp_id",""))
	for side: String in _sides: _military_population[side]=maxi(0,int(population.get(side,0)))


func sync_hero_roster(roster: Array) -> void:
	# Lightweight derived input. Combat remains the sole level/identity owner.
	_hero_roster = roster.duplicate(true)
	_has_hero_roster = true


func _observed_hero_roster() -> Array:
	if _has_hero_roster: return _hero_roster
	# Standalone World callers historically supply only bodies. Runtime host
	# always supplies Combat's canonical roster, including level and fixed slot.
	var result: Array = []
	for unit: Dictionary in _last_soldiers:
		if unit.get("unit_type", "") != "hero": continue
		var hero := unit.duplicate(true)
		hero["unit_id"] = str(unit.get("id", ""))
		hero["alive"] = int(unit.get("hp",0)) > 0 and bool(unit.get("alive",true))
		result.append(hero)
	for side: String in _sides:
		var observed := false
		for hero: Dictionary in result:
			if hero.get("side", "") == side: observed = true
		if not observed:
			# World-only tools still model a match that starts with one free hero.
			# Never offer another free altar recruit merely because bodies were
			# not supplied by that standalone caller yet.
			var archetype := str(_side_config(side).get("starting_hero",Factions.default_hero(get_faction(side))))
			result.append({"id":"initial_"+side,"unit_id":"initial_"+side,"side":side,"hero_archetype":archetype,"hero_slot":1,"level":1,"alive":true,"life_generation":1})
	return result


func get_hero_quote(side: String, archetype: String) -> Dictionary:
	if side not in _sides: return _reject("INVALID_ACTOR_SIDE")
	if archetype not in Factions.heroes_for(get_faction(side)): return _reject("FOREIGN_FACTION_HERO")
	return HeroEconomy.quote(archetype,side,_observed_hero_roster(),_buildings,get_base_tier(side))


func _hero_quotes() -> Dictionary:
	var result := {}
	for side: String in _sides:
		result[side] = {}
		for archetype: String in Factions.heroes_for(get_faction(side)):
			result[side][archetype] = get_hero_quote(side,archetype)
	return result


func apply_command(command: Dictionary, side: String, military_population: Dictionary, warband_ids: Array) -> Dictionary:
	if side not in _sides or typeof(command.get("type")) != TYPE_STRING:
		return _reject("INVALID_COMMAND")
	if is_outpost_mode():
		if str(command.type) in ["SET_ECONOMY_TARGETS","SET_WORK_SITE","SET_ESSENCE_SITE","REBUILD_SITE_DEFENSE"]:return _reject("AUTOMATIC_OUTPOST_ECONOMY")
		if str(command.type) in ["ENQUEUE_UNIT","UPGRADE","UPGRADE_BASE","UPGRADE_TOWER"]:
			var producer:=_find_building(str(command.get("building_id","")))
			if not producer.is_empty() and not _outpost_operational(producer):return _reject("SITE_NOT_FULLY_CONTROLLED")
	match str(command["type"]):
		"SET_ECONOMY_TARGETS":
			return _set_targets(command, side)
		"SET_WORK_SITE":
			var site := _find_site(str(command.get("site_id", "")))
			if not _fields(command, ["type", "site_id"]) or site.is_empty() or site["kind"] != "RESOURCE" or site["owner"] != side:
				return _reject("INVALID_WORK_SITE")
			if _source_for_site(str(site.id),"MATERIAL").get("remaining",0)<=0: return _reject("SOURCE_EXHAUSTED")
			_economy[side]["work_site_id"] = site["id"]
			return _accept()
		"SET_ESSENCE_SITE":
			var site:=_find_site(str(command.get("site_id","")))
			if not _fields(command,["type","site_id"]) or site.get("owner","")!=side or site.get("resource","")!="ESSENCE":return _reject("INVALID_ESSENCE_SITE")
			if int(_source_for_site(str(site.id),"ESSENCE").get("remaining",0))<=0:return _reject("SOURCE_EXHAUSTED")
			_economy[side].essence_site_id=site.id
			return _accept()
		"PLACE_BUILDING":
			return _place_building(command, side)
		"ENQUEUE_UNIT":
			return _enqueue(command, side, military_population, warband_ids)
		"CANCEL_PRODUCTION":
			return _cancel(command, side)
		"CANCEL_CONSTRUCTION":
			return _cancel_construction(command, side)
		"UPGRADE":
			return _upgrade(command, side)
		"UPGRADE_BASE":
			return _upgrade_base(command, side)
		"UPGRADE_TOWER":
			return _upgrade_tower(command,side)
		"REBUILD_SITE_DEFENSE":
			return _rebuild_site_defense(command,side)
		"BUY_ITEM":
			return _buy_item(command, side)
		"SELL_ITEM":
			return _sell_item(command, side)
	return _reject("UNKNOWN_COMMAND")


func advance_tick(tick: int, soldiers: Array, military_population: Dictionary, phase: String) -> Array:
	sync_military(soldiers, military_population)
	return _settle_current_military_m79(tick, phase)


func advance_tick_owned_m79(tick: int, detached_soldiers: Array, military_population: Dictionary, phase: String) -> Array:
	# Same settlement and sync-before-rejection semantics as the public route.
	sync_owned_military_m79(detached_soldiers, military_population)
	return _settle_current_military_m79(tick, phase)


func _settle_current_military_m79(tick: int, phase: String) -> Array:
	var events: Array[Dictionary] = []
	if tick <= _tick or phase not in ["PREPARATION", "BATTLE"]:
		return events
	_tick = tick
	if phase == "BATTLE":
		_advance_capture()
	_refresh_defenses()
	if is_outpost_mode():
		if phase=="BATTLE": _advance_outpost_income()
	else:
		for side: String in _sides:
			_recover_mining(side)
			_recover_essence(side)
		if phase=="BATTLE":_advance_worker_defense(events)
		_advance_workers()
	_advance_construction()
	_advance_base_upgrades()
	_advance_tower_upgrades()
	_advance_research()
	_advance_production(events)
	if phase == "BATTLE":
		_advance_towers(events)
	return events


func damage_buildings(hits: Array) -> Array:
	var receipts: Array[Dictionary] = []
	for value: Variant in hits:
		if not value is Dictionary:
			continue
		var hit: Dictionary = value
		var building := _find_building(str(hit.get("building_id", "")))
		if building.get("fixed", false): continue
		if building.is_empty() or (str(hit.get("side", "")) not in _sides and hit.get("side") != "NEUTRAL") or hit["side"] == building["side"] or typeof(hit.get("damage")) != TYPE_INT or int(hit["damage"]) <= 0 or int(building["hp"]) <= 0:
			continue
		var before_hp := int(building.hp)
		building["hp"] = maxi(0, int(building["hp"]) - int(hit["damage"]))
		receipts.append(_statistics_damage_receipt(hit,building,before_hp-int(building.hp)))
		building["last_damage_tick"]=_tick
		building["last_damage_source_id"]=str(hit.get("unit_id",hit.get("source_id","")))
		building["last_damage_amount"]=int(hit.damage)
		if int(building["hp"]) == 0:
			# Upgrade payments are committed infrastructure loss, not unfinished
			# unit reservations. Destruction never earns the incomplete tier.
			building["base_upgrade"] = {}
			building["tower_upgrade"] = {}
			building["complete"] = false
			building["state"] = "DESTROYED"
			for entry: Dictionary in building["queue"]:
				_refund(str(building["side"]), entry["cost"])
			building["queue"].clear()
	return receipts


func damage_workers(hits: Array, settlement_tick: int = -1) -> Array:
	# Trusted host combat events, never player/model command payloads. Workers
	# remain in World authority and are not duplicate military/capture bodies.
	var changed_sides := {}
	var receipts: Array[Dictionary] = []
	var evidence_tick := _tick if settlement_tick < 0 else maxi(_tick, settlement_tick)
	for value: Variant in hits:
		if not value is Dictionary: continue
		var hit: Dictionary = value
		if typeof(hit.get("worker_id")) != TYPE_STRING or typeof(hit.get("damage")) != TYPE_INT or int(hit["damage"]) <= 0 or (hit.get("side") not in _sides and hit.get("side")!="NEUTRAL"):
			continue
		var worker := _find_worker(str(hit["worker_id"]))
		if worker.is_empty() or worker["side"] == hit["side"] or int(worker["hp"]) <= 0: continue
		var before_hp := int(worker.hp)
		worker["hp"] = maxi(0, int(worker["hp"]) - int(hit["damage"]))
		receipts.append(_statistics_damage_receipt(hit,worker,before_hp-int(worker.hp)))
		worker["last_damage_tick"] = evidence_tick
		worker["last_damage_source_id"] = str(hit.get("unit_id", hit.get("source_id", "")))
		worker["last_damage_amount"] = int(hit["damage"])
		if int(worker["hp"]) > 0: continue
		var side := str(worker["side"])
		var role := str(worker["desired_role"])
		_economy[side]["targets"][role] = maxi(0, int(_economy[side]["targets"].get(role, 0)) - 1)
		worker["death_tick"] = evidence_tick
		worker["state"] = "DEAD"
		worker["role"] = "RESERVE"
		worker["desired_role"] = "RESERVE"
		worker["cargo_type"] = ""
		worker["cargo_amount"] = 0
		worker["gather_progress"] = 0
		worker["building_id"] = ""
		worker["site_id"] = ""
		worker["route"].clear()
		worker["route_target"] = worker["position"]
		worker["route_geometry"] = ""
		worker["station_targets"].clear()
		changed_sides[side] = true
	for side: String in changed_sides: _reconcile_roles(side)
	return receipts


func _statistics_damage_receipt(hit: Dictionary, victim: Dictionary, actual: int) -> Dictionary:
	_statistics_receipt_serial += 1
	var body := {"id":victim.id,"side":victim.side,"hp":victim.hp,"position":victim.position,"unit_type":"worker" if victim.has("desired_role") else "building","life_generation":victim.get("life_generation",1)}
	if body.unit_type == "building": body["building_type"] = victim.get("building_type","BUILDING")
	return {"receipt_id":"%d:world-damage:%d" % [_seed,_statistics_receipt_serial],"unit_id":hit.get("unit_id",hit.get("source_id","")),"source_side":hit.get("side",""),"victim":body,"actual_damage":actual,"stats_cause":hit.get("stats_cause",{"id":"BASIC","category":"BASIC"}).duplicate(true)}


func get_snapshot() -> Dictionary:
	var population := {}
	var population_upkeep := {}
	for side: String in _sides:
		population[side] = _population(side, _military_population)
		population_upkeep[side] = Economy.M71.upkeep(int(population[side].used))
	var sites: Array[Dictionary] = get_sites_snapshot_m79()
	if is_outpost_mode():
		for site: Dictionary in sites: site.merge(_outpost_income_readout(site),true)
	return {"outpost_mode":is_outpost_mode(),"ruleset":Outposts.VERSION if is_outpost_mode() else "LEGACY","currency_version":Currency.VERSION,"resource_keys":Currency.ACTIVE_KEYS.duplicate(),"resource_labels":{"MATERIAL":Currency.LABEL},"building_slots":get_building_slots(),"sites": sites, "buildings": _building_observations_m75(), "workers": _worker_observations_m75(), "resource_sources": _resource_sources(), "economy": _economy.duplicate(true), "population": population,"population_upkeep":population_upkeep, "progression":get_progression(),"hero_quotes":_hero_quotes(),"technology_queues":_technology_queues.duplicate(true),"terrain":_terrain.duplicate(true),"sides":_match_config.sides.duplicate(true),"arena_bounds":{"min_x":_bounds.position.x,"min_y":_bounds.position.y,"max_x":_bounds.end.x,"max_y":_bounds.end.y}}


func get_sites_snapshot_m79() -> Array[Dictionary]:
	# Command validation needs sites, not worker animations/quotes/resources.
	# Rebuild current guard counts; do not cache across commands or deaths.
	var sites: Array[Dictionary] = _sites.duplicate(true)
	var counts: Variant = MilitaryFactsM93.guards(_last_soldiers)
	for site: Dictionary in sites:
		site["neutral_guard_count"] = int(counts.get(str(site.id), 0)) if counts != null else _neutral_guard_count(str(site.id))
	return sites


func get_ai_receipt_snapshot_m79(side: String) -> Dictionary:
	# record_result consumes only these two branches. The authoritative stock
	# and queue reservation are sampled immediately before/after real admission.
	if side not in _sides: return {"economy": {}, "population": {}}
	return {"economy": {side: {"stock": _economy[side].stock.duplicate(true)}}, "population": {side: _population(side, _military_population)}}


func get_environment_snapshot() -> Dictionary:
	# Same detached physical observations as the full readout, without pricing,
	# resource/source/progression projections that collision never consumes.
	return {"buildings":_building_observations_m75(),"workers":_worker_observations_m75(),"terrain":_terrain.duplicate(true)}


func get_outcome_snapshot() -> Dictionary:
	var population := {}
	for side:String in _sides:population[side]=_population(side,_military_population)
	return {"buildings":_building_observations_m75(),"population":population}


func _worker_observations_m75() -> Array[Dictionary]:
	var workers: Array[Dictionary] = []
	var worker_base:Dictionary=worker_stats()
	for worker: Dictionary in _workers:
		var observation := worker.duplicate(true)
		observation["attribute_base"] = worker_base.duplicate(true)
		var movement: Vector2i = worker["position"] - worker["previous_position"]
		var action := "IDLE"
		var action_position: Vector2i = worker["route_target"]
		var building := _find_building(str(worker["building_id"]))
		if int(worker["hp"]) > 0:
			if int(worker.get("last_action_tick",-100))>=0 and _tick-int(worker.last_action_tick)<8:
				action="ATTACK"
				action_position=worker.last_action_target_position
			elif worker["state"] == "GATHERING" and worker["role"] in Economy.RESOURCE_KEYS:
				action = "HARVEST" if worker["role"] == "FOOD" else "MINE"
			elif worker["state"] == "CONSTRUCTING" and not building.is_empty() and int(building["hp"]) > 0 and not bool(building["complete"]):
				action = "BUILD"
				action_position = building["position"]
			elif movement != Vector2i.ZERO:
				action = "CARRY" if int(worker["cargo_amount"]) > 0 else "WALK"
		observation.merge({"movement_delta": movement, "action_kind": action, "action_position": action_position, "action_tick": _tick})
		workers.append(observation)
	return workers


func _building_observations_m75() -> Array[Dictionary]:
	var buildings: Array[Dictionary] = []
	for building: Dictionary in _buildings:
		var observation := building.duplicate(true)
		if building["building_type"] in ["TOWER","SITE_TOWER","BASE"]:
			observation["action_kind"] = "ATTACK" if building.get("defense_active",false) and int(building["last_action_tick"]) >= 0 and _tick - int(building["last_action_tick"]) <= 8 else "IDLE"
			observation["action_tick"] = int(building["last_action_tick"])
			observation["action_target_id"] = str(building["last_action_target_id"])
			observation["action_target_position"] = building["last_action_target_position"]
			observation["cooldown_ticks"] = maxi(0, int(building["tower_ready_tick"]) - _tick)
		buildings.append(observation)
	return buildings


func get_base_tier(side: String) -> int:
	var tier := 1
	for building: Dictionary in _buildings:
		if building["side"]==side and building["building_type"]=="BASE" and bool(building["complete"]) and int(building["hp"])>0:
			tier=maxi(tier,int(building.get("base_tier",1)))
	return mini(3,tier)


func get_hero_limit(side: String) -> int:
	return get_base_tier(side)


func get_progression() -> Dictionary:
	var facts := {}
	for side: String in _sides:
		var upgrades: Array[Dictionary] = []
		for building: Dictionary in _buildings:
			if building["side"]!=side or building["building_type"]!="BASE" or not bool(building["complete"]) or int(building["hp"])<=0: continue
			var target := int(building.get("base_tier",1))+1
			if not Progression.BASE_UPGRADES.has(target): continue
			var recipe: Dictionary = Progression.BASE_UPGRADES[target].duplicate(true)
			var reason := "" if building.get("base_upgrade",{}).is_empty() else "BASE_ALREADY_UPGRADING"
			if reason.is_empty() and not _can_pay(side,recipe["cost"]): reason="INSUFFICIENT_STOCK"
			recipe.merge({"building_id":building["id"],"available":reason.is_empty(),"reason":reason})
			upgrades.append(recipe)
		facts[side]={"base_tier":get_base_tier(side),"hero_limit":get_hero_limit(side),"hero_slots_used":_hero_slots(side),"next_upgrades":upgrades}
	return facts.duplicate(true)


func get_technology() -> Dictionary:
	return _technology.duplicate(true)


func get_state() -> Dictionary:
	# Include every mutable ledger/counter; military caches are derived input.
	return {"neutral_dead_ids_r9":_neutral_dead_ids_r9.duplicate(),"auto_income_remainders":_auto_remainders.duplicate(true),"seed": _seed, "tick": _tick,"match_config":_match_config.duplicate(true),"sources":_sources.duplicate(true),"technology_queues":_technology_queues.duplicate(true), "sites": _sites.duplicate(true), "buildings": _buildings.duplicate(true), "workers": _workers.duplicate(true), "economy": _economy.duplicate(true), "technology": _technology.duplicate(true), "next_building": _next_building, "next_entry": _next_entry, "next_worker": _next_worker, "next_recruit": _next_recruit, "next_purchase": _next_purchase, "field_reward_receipts":_field_reward_receipts.duplicate(true),"neutral_reward_receipts":_neutral_reward_receipts.duplicate(true),"neutral_bounty_receipts":_neutral_bounty_receipts.duplicate(true)}


func _grant_neutral_stock(receipt: Dictionary) -> Dictionary:
	# Host-only closed receipt; no public command accepts reward quantities.
	if not _fields(receipt,["receipt_id","camp_id","side","tick"]): return _reject("INVALID_NEUTRAL_RECEIPT")
	for key: String in ["receipt_id","camp_id","side"]:
		if typeof(receipt.get(key))!=TYPE_STRING: return _reject("INVALID_NEUTRAL_RECEIPT")
	if typeof(receipt.get("tick"))!=TYPE_INT or int(receipt.tick)!=_tick or _tick<=0 or receipt.side not in _sides: return _reject("INVALID_NEUTRAL_RECEIPT")
	var camp := NeutralEncounters.definition(_match_config,str(receipt.camp_id),_seed)
	if camp.is_empty() or receipt.receipt_id!=camp.receipt_id: return _reject("INVALID_NEUTRAL_RECEIPT")
	if _neutral_reward_receipts.has(receipt.receipt_id): return _reject("NEUTRAL_ALREADY_CLAIMED")
	var bodies := {}
	for body: Dictionary in _last_soldiers: bodies[str(body.id)]=body
	var winner_proved := false
	for id: String in camp.member_ids:
		if bodies.has(id):
			if not bool(bodies[id].get("neutral",false)) or int(bodies[id].get("hp",0))>0:return _reject("NEUTRAL_NOT_CLEARED")
			if bodies[id].get("camp_clear_winner","")!=receipt.side:return _reject("FOREIGN_NEUTRAL_REWARD")
			winner_proved=true
		elif str(_neutral_dead_ids_r9.get(id,""))!=str(camp.id):return _reject("NEUTRAL_NOT_CLEARED")
	if not winner_proved:return _reject("NEUTRAL_NOT_CLEARED")
	var grant: Dictionary = Currency.reward(camp.reward)
	_economy[receipt.side].stock.MATERIAL=int(_economy[receipt.side].stock.MATERIAL)+int(grant.MATERIAL)
	_neutral_reward_receipts[receipt.receipt_id]={"side":receipt.side,"camp_id":camp.id,"tick":_tick,"actual_grant":grant.duplicate(true)}
	for id: String in camp.member_ids:_neutral_dead_ids_r9.erase(id)
	return _accept({"receipt_id":receipt.receipt_id,"actual_grant":grant})


func _grant_neutral_bounty(receipt: Dictionary)->Dictionary:
	# Closed death receipt, not a player command. Derive both amount and
	# ownership from a canonical finite member and Combat's death evidence.
	if not _fields(receipt,["receipt_id","camp_id","victim_id","side","tick"]):return _reject("INVALID_NEUTRAL_BOUNTY")
	for key: String in ["receipt_id","camp_id","victim_id","side"]:
		if typeof(receipt.get(key))!=TYPE_STRING:return _reject("INVALID_NEUTRAL_BOUNTY")
	if typeof(receipt.get("tick"))!=TYPE_INT or receipt.tick!=_tick or _tick<=0 or receipt.side not in _sides:return _reject("INVALID_NEUTRAL_BOUNTY")
	var camp:=NeutralEncounters.definition(_match_config,receipt.camp_id,_seed)
	if camp.is_empty() or camp.kind!="SCATTERED" or receipt.victim_id not in camp.member_ids or receipt.receipt_id!="bounty:"+str(receipt.victim_id):return _reject("INVALID_NEUTRAL_BOUNTY")
	if _neutral_bounty_receipts.has(receipt.receipt_id):return _reject("NEUTRAL_BOUNTY_ALREADY_CLAIMED")
	var victim:={}
	for body: Dictionary in _last_soldiers:
		if body.id==receipt.victim_id:victim=body;break
	if victim.is_empty() or not victim.get("neutral",false) or int(victim.get("hp",1))>0 or victim.get("camp_id","")!=camp.id:return _reject("NEUTRAL_NOT_DEAD")
	if victim.get("neutral_bounty_winner","")!=receipt.side:return _reject("FOREIGN_NEUTRAL_BOUNTY")
	var member_reward:Dictionary=camp.get("member_bounties",{}).get(str(receipt.victim_id),{})
	if member_reward.is_empty():return _reject("INVALID_NEUTRAL_BOUNTY")
	var grant: Dictionary=Currency.reward(member_reward)
	_economy[receipt.side].stock.MATERIAL=int(_economy[receipt.side].stock.MATERIAL)+int(grant.MATERIAL)
	_neutral_bounty_receipts[receipt.receipt_id]={"side":receipt.side,"camp_id":camp.id,"victim_id":receipt.victim_id,"tick":_tick,"actual_grant":grant}
	return _accept({"receipt_id":receipt.receipt_id,"actual_grant":grant.duplicate(true)})


func _neutral_guard_count(site_id: String) -> int:
	var count := 0
	for body: Dictionary in _last_soldiers:
		if bool(body.get("neutral",false)) and body.get("guarding_site_id","")==site_id and int(body.get("hp",0))>0: count+=1
	return count


func _grant_field_stock(receipt: Dictionary) -> Dictionary:
	# Internal host adapter, never routed from apply_command. Quantities come
	# exclusively from the canonical neutral-village recipe, not this payload.
	if not _fields(receipt, ["receipt_id", "site_id", "kind", "side", "tick"]): return _reject("INVALID_FIELD_RECEIPT")
	for key: String in ["receipt_id", "site_id", "kind", "side"]:
		if typeof(receipt.get(key)) != TYPE_STRING: return _reject("INVALID_FIELD_RECEIPT")
	if typeof(receipt.get("tick")) != TYPE_INT or int(receipt.tick) != _tick or _tick <= 0: return _reject("INVALID_FIELD_RECEIPT")
	var record := FieldObjectives.definition(_match_config, receipt.site_id)
	if record.is_empty() or record.kind not in ["SUPPLY", "ARMORY"] or receipt.kind != record.kind or receipt.receipt_id != record.receipt_id or receipt.side not in _sides: return _reject("INVALID_FIELD_RECEIPT")
	if _field_reward_receipts.has(receipt.receipt_id): return _reject("FIELD_ALREADY_CLAIMED")
	var site := _find_site(receipt.site_id)
	if site.get("owner") != receipt.side or site.get("capture_side") != receipt.side or int(site.get("progress", 0)) != CAPTURE_THRESHOLD: return _reject("FIELD_NOT_OWNED")
	var grant := Currency.reward({"FOOD":int(record.reward.FOOD), "MATERIAL":int(record.reward.MATERIAL), "XP":0, "POTION":0, "skill_points":0, "capped":[]})
	_economy[receipt.side].stock.MATERIAL = int(_economy[receipt.side].stock.MATERIAL) + int(grant.MATERIAL)
	_field_reward_receipts[receipt.receipt_id] = {"side":receipt.side, "site_id":receipt.site_id, "tick":_tick, "actual_grant":grant.duplicate(true)}
	return _accept({"receipt_id":receipt.receipt_id, "actual_grant":grant})


func _field_site_observations() -> Array[Dictionary]:
	# Narrow detached authority seam, avoiding a whole-world copy each tick.
	var result: Array[Dictionary] = []
	for site: Dictionary in _sites:
		if site.kind != "VILLAGE": continue
		var record := {}
		for key: String in ["id", "kind", "position", "owner", "capture_side", "progress", "threshold"]: record[key] = site[key]
		result.append(record)
	return result


func _new_site(id: String, kind: String, position: Vector2i, owner: String) -> Dictionary:
	var presence:={}
	for side: String in _sides: presence[side]=0
	return {"id": id, "kind": kind, "position": position, "owner": owner, "capture_side": owner, "progress": CAPTURE_THRESHOLD if not owner.is_empty() else 0, "max_progress": CAPTURE_THRESHOLD, "threshold": CAPTURE_THRESHOLD, "radius": CAPTURE_RADIUS, "capacity": 30 if kind == "RESOURCE" else 10, "presence": presence}


func _new_building(id: String, side: String, type: String, position: Vector2i, complete: bool) -> Dictionary:
	var catalog: Dictionary = (SHOP_DEFINITION if type == "SHOP" and not is_outpost_mode() else BUILDING_CATALOG[type]).duplicate(true)
	if type not in ["SHOP","SITE_TOWER"]:catalog.merge(Economy.building_stats(type),true)
	if type=="TOWER":catalog.merge(FactionTowers.construction_quote(get_faction(side)),true)
	if type=="RANGE":catalog.label=MAGIC_CAMP_NAMES.get(get_faction(side),"魔法营")
	elif type=="BARRACKS":catalog.label="物理营"
	elif type=="DRAGON_ROOST":catalog.label=Factions.producer_name(get_faction(side),type)
	var direction: Vector2i=_side_config(side).get("spawn_direction",Vector2i.RIGHT)
	var building := {"id": id, "side": side,"faction_id":get_faction(side), "building_type": type, "label": catalog["label"], "position": position, "radius": catalog["radius"], "hp": catalog["hp"], "max_hp": catalog["hp"], "complete": complete, "state": "COMPLETE" if complete else "BLUEPRINT", "progress": catalog["work"] if complete else 0, "max_progress": catalog["work"], "queue": [], "outlet": position + direction*(int(catalog["radius"]) + 36), "tower_ready_tick": 0, "cost": catalog["cost"].duplicate(true), "base_tier":1, "base_upgrade":{}}
	building.merge({"armor_type":"FORTIFIED","attack_type":"PIERCE" if type in ["TOWER","SITE_TOWER","BASE"] else "EDGE"})
	building.merge({"tower_level":1,"tower_upgrade":{},"site_id":"","initial_home":false,"defense_active":false,"paid_rebuild_pending":false})
	building.merge({"armor":int(catalog.get("armor",0)),"last_damage_tick":-1000000,"last_damage_source_id":"","last_damage_amount":0})
	if not complete:
		building["construction_base_hp"]=maxi(1,int(catalog.hp)/10)
		building.hp=int(building.construction_base_hp)
		building["reconstructing"]=true
	if type in ["TOWER","SITE_TOWER","BASE"]:
		building.merge({"attack_range": TOWER_RANGE, "damage": TOWER_DAMAGE, "armor": int(catalog.get("armor",3)), "attack_type":"PIERCE", "attack_cooldown_ticks": TOWER_COOLDOWN, "last_action_tick": -1, "last_action_kind": "", "last_action_target_id": "", "last_action_target_position": position})
		building["last_action_targets"]=[]
	if type=="TOWER":
		# Planned weapons are inspectable while the command desk is paused;
		# advertising the old generic piercing weapon until the next tick is
		# misleading. Stats alone never activate an unfinished structure.
		var ranged_types: Array=Factions.units_for(get_faction(side),"RANGED")
		if not ranged_types.is_empty():building.merge(FactionTowers.defense_stats(get_faction(side),type,1,Units.stats_for(str(ranged_types[0])),2.5),true)
	_apply_building_technology_v4(building)
	return building


static func building_catalog_for_faction(faction: String) -> Dictionary:
	var catalog: Dictionary=BUILDING_CATALOG.duplicate(true)
	catalog.erase("WORKSHOP")
	catalog.BARRACKS.label="物理营"
	catalog.RANGE.label=MAGIC_CAMP_NAMES.get(faction,"魔法营")
	catalog.DRAGON_ROOST.label=Factions.producer_name(faction,"DRAGON_ROOST")
	var tower: Dictionary=catalog.TOWER
	tower.merge(FactionTowers.construction_quote(faction),true)
	var ranged_types: Array=Factions.units_for(faction,"RANGED")
	if not ranged_types.is_empty():
		tower.merge(FactionTowers.defense_stats(faction,"TOWER",1,Units.stats_for(str(ranged_types[0])),2.5),true)
	tower["upgrade_quote"]=FactionTowers.upgrade_quote(faction)
	tower["counterplay"]=FactionTowers.profile(faction).counterplay
	return catalog


func get_building_catalog(side: String) -> Dictionary:
	return building_catalog_for_faction(get_faction(side))


func get_building_catalogs() -> Dictionary:
	var catalogs: Dictionary={}
	for side: String in _sides:catalogs[side]=get_building_catalog(side)
	return catalogs


func _new_worker(id: String, side: String, position: Vector2i, index: int) -> Dictionary:
	var worker: Dictionary={"id": id, "side": side,"faction_id":get_faction(side),"movement_layer":"GROUND", "position": position, "previous_position": position, "index": index, "unit_type": "worker", "hp": WORKER_HP, "max_hp": WORKER_HP, "radius": WORKER_RADIUS, "role": "RESERVE", "desired_role": "RESERVE", "state": "RESERVE", "cargo_type": "", "cargo_amount": 0, "site_id": "", "source_id":"", "gather_progress": 0, "building_id": "", "route_target": position, "route_geometry": "", "route": [], "route_stall_ticks": 0, "route_best_distance": INF, "station_targets": {}, "station_current_key": "", "station_blocked_ticks": 0, "last_damage_tick": -1, "last_damage_source_id": "", "last_damage_amount": 0, "death_tick": -1,"attack_ready_tick":0,"last_action_tick":-1,"last_action_target_id":"","last_action_target_position":position}
	var stats:=worker_stats()
	for key: String in ["role","faction_id"]:stats.erase(key)
	worker.merge(stats,true)
	return worker


static func worker_stats() -> Dictionary:
	var result: Dictionary=Units.stats_for("worker")
	result.merge({"unit_type":"worker","label":"工人","radius":WORKER_RADIUS,"population":1})
	return result


func _set_targets(command: Dictionary, side: String) -> Dictionary:
	if not _fields(command, ["type", "changes"]) or not command["changes"] is Array or command["changes"].is_empty() or command["changes"].size() > 2:
		return _reject("INVALID_TARGETS")
	var next: Dictionary = _economy[side]["targets"].duplicate()
	var seen := {}
	var sum := 0
	for item: Variant in command["changes"]:
		if not item is Dictionary or not _fields(item, ["role", "delta"]) or typeof(item.get("role")) != TYPE_STRING or typeof(item.get("delta")) != TYPE_INT:
			return _reject("INVALID_TARGETS")
		var role := str(item["role"])
		var delta := int(item["delta"])
		if role not in ["FOOD", "MATERIAL", "ESSENCE", "CONSTRUCTION_REPAIR"] or delta not in [-1, 1] or seen.has(role):
			return _reject("INVALID_TARGETS")
		seen[role] = true
		next[role] = int(next[role]) + delta
		sum += delta
	if command["changes"].size() == 2 and sum != 0:
		return _reject("INVALID_TRANSFER")
	var assigned := int(next["FOOD"]) + int(next["MATERIAL"]) + int(next["ESSENCE"]) + int(next["CONSTRUCTION_REPAIR"])
	if int(next["FOOD"]) < 0 or int(next["MATERIAL"]) < 0 or int(next["ESSENCE"])<0 or int(next["CONSTRUCTION_REPAIR"]) < 0 or assigned > _worker_count(side):
		return _reject("NO_RESERVE_WORKER")
	if int(next["MATERIAL"]) > 0 and _mineable_site(side).is_empty():
		return _reject("NO_OWNED_MINE")
	if int(next.ESSENCE)>_essence_capacity(side):return _reject("ESSENCE_MINE_OR_CAP_REQUIRED")
	next["RESERVE"] = _worker_count(side) - assigned
	_economy[side]["targets"] = next
	_reconcile_roles(side)
	return _accept()


func _place_building(command: Dictionary, side: String) -> Dictionary:
	if is_outpost_mode(): return _place_outpost_building(command,side)
	if not _fields(command, ["type", "building_type", "position"]) or typeof(command["building_type"]) != TYPE_STRING or typeof(command["position"]) != TYPE_VECTOR2I:
		return _reject("INVALID_PLACEMENT")
	var type := str(command["building_type"])
	if not BUILDING_CATALOG.has(type) or type=="SITE_TOWER":
		return _reject("INVALID_BUILDING_TYPE")
	if get_base_tier(side)<int(Progression.BUILDING_TIERS[type]):
		return _reject("BASE_TIER_REQUIRED")
	var position: Vector2i = command["position"]
	var radius := int(BUILDING_CATALOG[type]["radius"])
	if not _position_clear(position, radius, ""):
		return _reject("PLACEMENT_OCCUPIED_OR_OUTSIDE")
	if type == "BASE" and _owned_resource_near(position, side).is_empty():
		return _reject("BASE_REQUIRES_OWNED_RESOURCE")
	var site:=_owned_resource_near(position,side,type=="ESSENCE_MINE")
	if type=="ESSENCE_MINE":
		if site.is_empty() or site.get("resource","")!="ESSENCE":return _reject("ESSENCE_MINE_REQUIRES_OWNED_DEPOSIT")
		for existing: Dictionary in _buildings:
			if existing.building_type=="ESSENCE_MINE" and existing.get("site_id","")==site.id and int(existing.hp)>0:return _reject("ESSENCE_MINE_EXISTS")
	var cost: Dictionary = FactionTowers.construction_quote(get_faction(side)).cost if type=="TOWER" else BUILDING_CATALOG[type]["cost"]
	if not _can_pay(side, cost):
		return _reject("INSUFFICIENT_STOCK")
	_pay(side, cost)
	var id := "%s_%s_%04d" % [side.to_lower(), type.to_lower(), _next_building]
	_next_building += 1
	var building:=_new_building(id, side, type, position, false)
	if type in ["BASE","ESSENCE_MINE"]:building.site_id=site.get("id","")
	_buildings.append(building)
	return _accept({"building_id": id})


func _enqueue(command: Dictionary, side: String, military_population: Dictionary, warband_ids: Array) -> Dictionary:
	var fields := ["type", "building_id", "unit_type", "warband_id"]
	if command.has("hero_archetype"): fields.append("hero_archetype")
	if not _fields(command, fields) or typeof(command["building_id"]) != TYPE_STRING or typeof(command["unit_type"]) != TYPE_STRING or typeof(command["warband_id"]) != TYPE_STRING:
		return _reject("INVALID_RECRUITMENT")
	var building := _find_building(str(command["building_id"]))
	var type := str(command["unit_type"])
	if is_outpost_mode() and type=="worker": return _reject("WORKERS_DISABLED")
	var destination := str(command["warband_id"])
	var archetype: Variant = command.get("hero_archetype", Factions.default_hero(get_faction(side)))
	if command.has("hero_archetype") and (type != "hero" or typeof(archetype) != TYPE_STRING or archetype not in HeroCatalog.ARCHETYPES):
		return _reject("INVALID_HERO_ARCHETYPE")
	if building.is_empty() or building["side"] != side or not bool(building["complete"]) or int(building["hp"]) <= 0:
		return _reject("BUILDING_UNAVAILABLE")
	if not UNIT_CATALOG.has(type) or not Units.is_recruitable(type) or UNIT_CATALOG[type]["building_type"] != building["building_type"]:
		return _reject("INCOMPATIBLE_UNIT")
	if type not in ["worker","hero"] and UNIT_CATALOG[type].faction_id!=get_faction(side): return _reject("FOREIGN_FACTION_UNIT")
	if type=="hero" and archetype not in Factions.heroes_for(get_faction(side)): return _reject("FOREIGN_FACTION_HERO")
	if get_base_tier(side)<int(UNIT_CATALOG[type].required_base_tier):
		return _reject("BASE_TIER_REQUIRED")
	for prerequisite: String in UNIT_CATALOG[type].get("required_buildings",[]):
		var ready:=false
		for candidate: Dictionary in _buildings:
			if candidate.side==side and candidate.building_type==prerequisite and candidate.complete and int(candidate.hp)>0 and (not is_outpost_mode() or _outpost_operational(candidate)):ready=true;break
		if not ready:return _reject("PRODUCTION_PREREQUISITE_REQUIRED")
	if (type == "worker" and not destination.is_empty()) or (type != "worker" and not destination.is_empty() and destination not in warband_ids):
		return _reject("FOREIGN_ARMY")
	var hero_quote := {}
	if type == "hero":
		hero_quote = get_hero_quote(side,archetype)
		if not hero_quote.accepted: return _reject(str(hero_quote.error))
	if building["queue"].size() >= MAX_QUEUE:
		return _reject("QUEUE_FULL")
	var recipe: Dictionary = UNIT_CATALOG[type].duplicate(true)
	if type == "hero":
		recipe["cost"] = hero_quote.cost.duplicate(true)
		recipe["duration"] = int(hero_quote.duration_ticks)
	var population := _population(side, military_population)
	if int(population["used"]) + int(population["reserved"]) + int(recipe["population"]) > int(population["maximum"]):
		return _reject("POPULATION_CAP")
	if not _can_pay(side, recipe["cost"]):
		return _reject("INSUFFICIENT_STOCK")
	_pay(side, recipe["cost"])
	var id := "production_%04d" % _next_entry
	_next_entry += 1
	var entry := {"id": id, "entry_id": id, "unit_type": type, "warband_id": destination, "progress": 0, "max_progress": recipe["duration"], "duration_ticks": recipe["duration"], "state": "WAITING", "population": recipe["population"], "cost": recipe["cost"].duplicate(true)}
	if type == "hero":
		entry.merge({"hero_archetype":archetype,"hero_mode":hero_quote.mode,"hero_id":hero_quote.hero_id,"hero_slot":hero_quote.hero_slot,"hero_level":hero_quote.level,"hero_life_generation":hero_quote.life_generation})
	building["queue"].append(entry)
	var receipt := {"entry_id":id,"cost":recipe.cost.duplicate(true),"duration_ticks":int(recipe.duration)}
	if type == "hero":
		for key: String in ["hero_mode","hero_id","hero_slot","hero_level"]: receipt[key] = entry[key]
	return _accept(receipt)


func _buy_item(command: Dictionary, side: String) -> Dictionary:
	# The host first checks Combat's actual inventory limits. This domain owns
	# the legal service/stock debit and produces a unique trusted payment receipt.
	if not _fields(command, ["type", "unit_id", "item_id", "building_id"]): return _reject("INVALID_PURCHASE")
	for key: String in ["unit_id", "item_id", "building_id"]:
		if typeof(command[key]) != TYPE_STRING or str(command[key]).is_empty(): return _reject("INVALID_PURCHASE")
	if not HeroCatalog.ITEMS.has(command["item_id"]): return _reject("INVALID_ITEM")
	var service := _validate_item_service(command, side)
	if not service.accepted: return service
	var buyer:Dictionary={}
	for hero:Dictionary in _observed_hero_roster():
		if hero.get("id")==command.unit_id and hero.get("side")==side:buyer=hero;break
	if buyer.is_empty():return _reject("INVALID_UNIT")
	var quote:=HeroItems.purchase_quote(buyer,str(command.item_id))
	if not quote.accepted:return quote
	var cost:Dictionary=quote.cost
	if not _can_pay(side, cost): return _reject("INSUFFICIENT_STOCK")
	_pay(side, cost)
	var receipt := "item_%s_%04d" % [side.to_lower(), _next_purchase]
	_next_purchase += 1
	return _accept({"purchase_id":receipt, "unit_id":command["unit_id"], "item_id":command["item_id"], "side":side, "cost":cost.duplicate(true),"quote_version":quote.version,"consumed_components":quote.consumed_components.duplicate()})

func _validate_item_service(command: Dictionary, side: String) -> Dictionary:
	var building := _find_building(str(command.get("building_id", "")))
	if building.is_empty() or building.get("side") != side or building.get("building_type") != "SHOP": return _reject("ITEM_SERVICE_UNAVAILABLE")
	if is_outpost_mode():
		if not _outpost_operational(building) or not building.complete or int(building.hp)<=0:return _reject("ITEM_SERVICE_UNAVAILABLE")
	else:
		if not building.get("fixed",false):return _reject("ITEM_SERVICE_UNAVAILABLE")
		var base := _find_building(str(building.get("original_base_id", "")))
		if base.is_empty() or int(base.hp) <= 0 or not bool(base.complete): return _reject("ITEM_SERVICE_UNAVAILABLE")
	for unit: Dictionary in _last_soldiers:
		if unit.get("id") != command.get("unit_id") or unit.get("side") != side or unit.get("unit_type") != "hero" or int(unit.get("hp", 0)) <= 0 or not bool(unit.get("alive", true)): continue
		if Vector2(unit.position).distance_squared_to(Vector2(building.position)) > HeroItems.SHOP_RANGE * HeroItems.SHOP_RANGE: return _reject("SHOP_OUT_OF_RANGE")
		return _accept()
	return _reject("INVALID_UNIT")

func _sell_item(command: Dictionary, side: String) -> Dictionary:
	# As with purchase, Combat validates ownership before this exact refund.
	if not _fields(command, ["type", "unit_id", "item_id", "building_id"]): return _reject("INVALID_SALE")
	for key: String in ["unit_id", "item_id", "building_id"]:
		if typeof(command[key]) != TYPE_STRING or str(command[key]).is_empty(): return _reject("INVALID_SALE")
	if not HeroItems.ITEMS.has(command.item_id): return _reject("INVALID_ITEM")
	var service := _validate_item_service(command, side)
	if not service.accepted: return service
	var refund := HeroItems.sell_refund(command.item_id)
	_refund(side, refund)
	var sale := "sale_%s_%04d" % [side.to_lower(), _next_purchase]
	_next_purchase += 1
	return _accept({"sale_id":sale,"unit_id":command.unit_id,"item_id":command.item_id,"side":side,"refund":refund})


func _cancel(command: Dictionary, side: String) -> Dictionary:
	if not _fields(command, ["type", "entry_id"]) or typeof(command["entry_id"]) != TYPE_STRING:
		return _reject("INVALID_CANCELLATION")
	for building: Dictionary in _buildings:
		if building["side"] != side:
			continue
		for index: int in range(building["queue"].size()):
			var entry: Dictionary = building["queue"][index]
			if entry["id"] == command["entry_id"]:
				_refund(side, entry["cost"])
				building["queue"].remove_at(index)
				return _accept()
	return _reject("UNKNOWN_ENTRY")


func _cancel_construction(command: Dictionary, side: String) -> Dictionary:
	if not _fields(command, ["type", "building_id"]) or typeof(command["building_id"]) != TYPE_STRING:
		return _reject("INVALID_CONSTRUCTION_CANCELLATION")
	for index: int in range(_buildings.size()):
		var building: Dictionary = _buildings[index]
		if building["id"] != command["building_id"]:
			continue
		if building["side"] != side or bool(building["complete"]) or int(building["hp"]) <= 0:
			return _reject("CONSTRUCTION_NOT_CANCELLABLE")
		if building.building_type=="SITE_TOWER":
			if not building.get("paid_rebuild_pending",false):return _reject("INTEGRATED_DEFENSE_NOT_CANCELLABLE")
			_refund(side,building.cost)
			building.merge({"hp":0,"progress":0,"complete":false,"state":"DESTROYED","reconstructing":false,"paid_rebuild_pending":false,"cost":{"FOOD":0,"MATERIAL":0}},true)
			return _accept({"building_id":building.id})
		# Paid blueprints are the construction queue. Remove exactly this entry,
		# freeing its physical footprint without creating a second refund target.
		_refund(side, building["cost"])
		_buildings.remove_at(index)
		return _accept({"building_id": command["building_id"]})
	return _reject("UNKNOWN_BUILDING")


func _upgrade_base(command: Dictionary, side: String) -> Dictionary:
	if not _fields(command,["type","building_id"]) or typeof(command["building_id"])!=TYPE_STRING:
		return _reject("INVALID_BASE_UPGRADE")
	var building := _find_building(command["building_id"])
	if building.is_empty() or building["side"]!=side or building["building_type"]!="BASE" or not bool(building["complete"]) or int(building["hp"])<=0: return _reject("BASE_UNAVAILABLE")
	if not building["base_upgrade"].is_empty(): return _reject("BASE_ALREADY_UPGRADING")
	var target := int(building["base_tier"])+1
	if not Progression.BASE_UPGRADES.has(target): return _reject("MAX_BASE_TIER")
	var recipe: Dictionary = Progression.BASE_UPGRADES[target]
	if not _can_pay(side,recipe["cost"]): return _reject("INSUFFICIENT_STOCK")
	_pay(side,recipe["cost"])
	building["base_upgrade"]={"target_tier":target,"progress":0,"max_progress":recipe["duration_ticks"],"cost":recipe["cost"].duplicate(true)}
	return _accept({"building_id":building["id"],"target_tier":target,"cost":recipe["cost"].duplicate(true),"duration_ticks":recipe["duration_ticks"]})


func _advance_base_upgrades() -> void:
	for building: Dictionary in _buildings:
		if is_outpost_mode() and not _outpost_operational(building):continue
		var upgrade: Dictionary = building["base_upgrade"]
		if upgrade.is_empty() or int(building["hp"])<=0 or not bool(building["complete"]): continue
		upgrade["progress"]=mini(int(upgrade["max_progress"]),int(upgrade["progress"])+1)
		if int(upgrade["progress"])>=int(upgrade["max_progress"]):
			building["base_tier"]=upgrade["target_tier"]
			var stats:=Economy.building_stats("BASE",int(building.base_tier))
			building.max_hp=int(stats.hp)
			building.armor=int(stats.armor)
			building["base_max_hp_v4"]=int(stats.hp)
			building["base_armor_v4"]=int(stats.armor)
			_apply_building_technology_v4(building,false)
			building["base_upgrade"]={}

func _upgrade_tower(command: Dictionary,side: String) -> Dictionary:
	if not _fields(command,["type","building_id"]) or typeof(command.building_id)!=TYPE_STRING:return _reject("INVALID_TOWER_UPGRADE")
	var building:=_find_building(command.building_id)
	if building.is_empty() or building.side!=side or building.building_type!="TOWER" or not building.complete or int(building.hp)<=0:return _reject("TOWER_UNAVAILABLE")
	if get_base_tier(side)<2:return _reject("BASE_TIER_REQUIRED")
	if int(building.tower_level)>=2:return _reject("MAX_TOWER_TIER")
	if not building.tower_upgrade.is_empty():return _reject("TOWER_ALREADY_UPGRADING")
	var recipe: Dictionary=FactionTowers.upgrade_quote(get_faction(side))
	if not _can_pay(side,recipe.cost):return _reject("INSUFFICIENT_STOCK")
	_pay(side,recipe.cost)
	building.tower_upgrade={"progress":0,"duration_ticks":recipe.duration_ticks,"target_tier":2,"cost":recipe.cost.duplicate()}
	return _accept({"building_id":building.id,"cost":recipe.cost.duplicate(),"duration_ticks":recipe.duration_ticks})

func _rebuild_site_defense(command: Dictionary,side: String) -> Dictionary:
	if not _fields(command,["type","site_id"]) or typeof(command.site_id)!=TYPE_STRING:return _reject("INVALID_SITE_DEFENSE")
	var site:=_find_site(command.site_id)
	var tower:=_find_building("defense:"+str(command.site_id))
	if site.is_empty() or site.owner!=side or int(site.progress)!=CAPTURE_THRESHOLD or tower.is_empty() or int(tower.hp)>0:return _reject("DESTROYED_OWNED_DEFENSE_REQUIRED")
	var cost: Dictionary=Economy.SITE_DEFENSE_REBUILD.cost
	if not _can_pay(side,cost):return _reject("INSUFFICIENT_STOCK")
	_pay(side,cost)
	tower.merge({"side":side,"faction_id":get_faction(side),"hp":1,"construction_base_hp":1,"progress":0,"complete":false,"state":"WAITING_BUILDERS","reconstructing":true,"paid_rebuild_pending":true,"cost":cost},true)
	return _accept({"building_id":tower.id,"cost":cost.duplicate(),"work":int(tower.max_progress)})

func _advance_tower_upgrades() -> void:
	for building: Dictionary in _buildings:
		if is_outpost_mode() and not _outpost_operational(building):continue
		var upgrade: Dictionary=building.get("tower_upgrade",{})
		if upgrade.is_empty() or int(building.hp)<=0 or not building.complete:continue
		upgrade.progress=int(upgrade.progress)+1
		if int(upgrade.progress)>=int(upgrade.duration_ticks):
			building.tower_level=2
			var quote: Dictionary=FactionTowers.upgrade_quote(str(building.faction_id))
			building.max_hp=int(quote.max_hp)
			building.armor=int(quote.armor)
			building["base_max_hp_v4"]=int(quote.max_hp)
			building["base_armor_v4"]=int(quote.armor)
			_apply_building_technology_v4(building,false)
			building.tower_upgrade={}
	_refresh_defenses()

func _refresh_defenses() -> void:
	if is_outpost_mode():
		_refresh_outpost_defenses()
		return
	# A site owns one integrated gun, never both its base gun and tower gun.
	for site: Dictionary in _sites:
		var owner:=str(site.owner)
		if owner not in _sides or int(site.progress)<CAPTURE_THRESHOLD:continue
		var tower:=_find_building("defense:"+str(site.id))
		if tower.is_empty():
			var original_home:=false
			for slot: Dictionary in _match_config.sides:
				if slot.home_site_id==site.id and slot.side_id==owner:original_home=true;break
			# The original home weapon is the base itself. Losing that base must
			# not mint a free replacement gun or block emergency depot rebuilding.
			if original_home:continue
			if site.kind=="RESOURCE" and not _source_base(site,owner).is_empty() and site.get("resource","")!="ESSENCE":continue
			var point: Vector2i=site.position+Vector2i(0,84)
			for offset: Vector2i in [Vector2i(0,84),Vector2i(84,0),Vector2i(-84,0),Vector2i(0,-84),Vector2i(120,80),Vector2i(-120,80)]:
				var candidate: Vector2i=site.position+offset
				if _position_clear(candidate,24,""):point=candidate;break
			if not _position_clear(point,24,""):continue
			tower=_new_building("defense:"+str(site.id),owner,"SITE_TOWER",point,false)
			tower.site_id=site.id
			tower.capturable=true
			_buildings.append(tower)
		elif tower.side!=owner:
			tower.side=owner
			tower.faction_id=get_faction(owner)
			tower.paid_rebuild_pending=false
			tower.cost={"FOOD":0,"MATERIAL":0}
			# Allegiance is earned by capture; recommissioning still needs builders.
			tower.complete=false
			tower.progress=0
			tower.state="WAITING_BUILDERS" if int(tower.hp)>0 else "DESTROYED"
			tower.tower_ready_tick=_tick
	for building: Dictionary in _buildings:
		var type:=str(building.building_type)
		if type not in ["BASE","TOWER","SITE_TOWER"]:continue
		var site:=_find_site(str(building.get("site_id","")))
		var equivalent:=2.5
		var active: bool=building.complete and int(building.hp)>0
		if type=="TOWER":equivalent=4.0 if int(building.tower_level)>=2 else 2.5
		else:
			active=active and not site.is_empty() and site.owner==building.side and int(site.progress)>0
			if type=="SITE_TOWER":
				equivalent=3.0 if site.get("kind","")=="RESOURCE" else 2.0
				for base: Dictionary in _buildings:
					if base.building_type=="BASE" and base.side==building.side and base.get("site_id","")==site.get("id","") and base.complete and int(base.hp)>0:active=false;break
			else:
				var tier:=int(building.base_tier)
				equivalent=6.0 if tier>=3 else 4.5 if tier>=2 else 2.5 if building.initial_home else 3.0
				# Additional depots/producers do not mint additional free site guns.
				# Keep the highest completed tier, with a stable ID tie break.
				for base: Dictionary in _buildings:
					if base.building_type!="BASE" or base.side!=building.side or base.get("site_id","")!=building.get("site_id","") or not base.complete or int(base.hp)<=0:continue
					if int(base.base_tier)>tier or (int(base.base_tier)==tier and str(base.id)<str(building.id)):active=false;break
		var types: Array=Factions.units_for(str(building.faction_id),"RANGED")
		if types.is_empty():active=false;continue
		var ranged: Dictionary=Units.stats_for(str(types[0]))
		building.ranged_equivalent=equivalent
		building.merge(FactionTowers.defense_stats(str(building.faction_id),type,int(building.tower_level),ranged,equivalent),true)
		building.defense_active=active

func _worker_defense_grid_m81(enemies: Array) -> Dictionary:
	var ready:=0
	for worker: Dictionary in _workers:
		if int(worker.hp)>0 and int(worker.attack_ready_tick)<=_tick:ready+=1
	if enemies.size()<32 or ready<2:return {}
	var buckets:Dictionary={}
	var allowed: Array=_sides+["NEUTRAL"]
	for index: int in range(enemies.size()):
		var enemy:Dictionary=enemies[index]
		if enemy.get("side","") not in allowed or int(enemy.get("hp",0))<=0 or not enemy.get("alive",true) or enemy.get("movement_layer","GROUND")=="AIR":continue
		if typeof(enemy.get("position"))!=TYPE_VECTOR2I:return {}
		var p:Vector2i=enemy.position
		if absi(p.x)>32768 or absi(p.y)>32768:return {}
		var key:=Vector2i(floori(float(p.x)/64.0),floori(float(p.y)/64.0))
		if not buckets.has(key):buckets[key]=[]
		buckets[key].append(index)
	return {"buckets":buckets}

func _worker_defense_indices_m81(worker: Dictionary,enemies: Array,grid: Dictionary) -> Array:
	var reach:=int(worker.attack_range)
	if grid.is_empty() or reach<0 or reach>512 or typeof(worker.get("position"))!=TYPE_VECTOR2I:return range(enemies.size())
	var p:Vector2i=worker.position
	if absi(p.x)>32768 or absi(p.y)>32768:return range(enemies.size())
	var min_x:=floori(float(p.x-reach)/64.0)
	var max_x:=floori(float(p.x+reach)/64.0)
	var min_y:=floori(float(p.y-reach)/64.0)
	var max_y:=floori(float(p.y+reach)/64.0)
	if (max_x-min_x+1)*(max_y-min_y+1)>=enemies.size():return range(enemies.size())
	var indices:Array=[]
	for y:int in range(min_y,max_y+1):
		for x:int in range(min_x,max_x+1):indices.append_array(grid.buckets.get(Vector2i(x,y),[]))
	indices.sort()
	return indices

func _advance_worker_defense(events: Array[Dictionary]) -> void:
	var enemies:Array=_last_soldiers+_workers
	var grid:=_worker_defense_grid_m81(enemies)
	for worker: Dictionary in _workers:
		if int(worker.hp)<=0 or int(worker.attack_ready_tick)>_tick:continue
		var target:={}
		var best:=INF
		for index: int in _worker_defense_indices_m81(worker,enemies,grid):
			var enemy:Dictionary=enemies[index]
			if enemy.get("side","")==worker.side or enemy.get("side","") not in _sides+["NEUTRAL"] or int(enemy.get("hp",0))<=0 or not enemy.get("alive",true) or enemy.get("movement_layer","GROUND")=="AIR":continue
			var distance:=Vector2(worker.position).distance_squared_to(Vector2(enemy.position))
			if distance<=int(worker.attack_range)*int(worker.attack_range) and distance<best:target=enemy;best=distance
		if target.is_empty():continue
		worker.attack_ready_tick=_tick+int(worker.attack_cooldown_ticks)
		worker.last_action_tick=_tick
		worker.last_action_target_id=target.id
		worker.last_action_target_position=target.position
		if target.get("unit_type","")=="worker":damage_workers([{"worker_id":target.id,"side":worker.side,"source_id":worker.id,"damage":DamageRules.resolve(int(worker.damage),str(worker.attack_type),target)}])
		else:events.append({"type":"DAMAGE","target_id":target.id,"damage":int(worker.damage),"side":worker.side,"source_id":worker.id,"attack_type":worker.attack_type})


func _upgrade(command: Dictionary, side: String) -> Dictionary:
	if not _fields(command, ["type", "technology", "building_id"]) or typeof(command["technology"]) != TYPE_STRING or typeof(command["building_id"]) != TYPE_STRING:
		return _reject("INVALID_UPGRADE")
	var technology := str(command["technology"])
	var building := _find_building(str(command["building_id"]))
	var unique:Dictionary=TechnologiesV4.lookup(technology,get_faction(side))
	if (technology not in ["ATTACK","ARMOR"] and unique.is_empty()) or building.is_empty() or building["side"] != side or building["building_type"] != "FOUNDRY" or not bool(building["complete"]) or int(building["hp"]) <= 0:
		return _reject("FOUNDRY_REQUIRED")
	if is_outpost_mode() and not _outpost_operational(building):return _reject("SITE_CONTESTED")
	if not unique.is_empty():
		var specialty: Dictionary=unique
		if int(_technology[side].get(technology,0))>0: return _reject("MAX_TECHNOLOGY")
		if not _technology_queues[side].is_empty(): return _reject("RESEARCH_IN_PROGRESS")
		if get_base_tier(side)<int(specialty.required_base_tier): return _reject("BASE_TIER_REQUIRED")
		if not _can_pay(side,specialty.cost): return _reject("INSUFFICIENT_STOCK")
		_pay(side,specialty.cost)
		_technology_queues[side].append({"technology":technology,"building_id":building.id,"progress":0,"max_progress":int(specialty.duration_ticks),"state":"RUNNING","cost":specialty.cost.duplicate(true)})
		return _accept({"technology":technology,"duration_ticks":specialty.duration_ticks,"cost":specialty.cost.duplicate(true)})
	var level := int(_technology[side][technology])
	var recipe: Dictionary = TECHNOLOGY_CATALOG[technology]
	if level >= int(recipe["max_level"]):
		return _reject("MAX_TECHNOLOGY")
	if get_base_tier(side)<level+1:
		return _reject("BASE_TIER_REQUIRED")
	if not _technology_queues[side].is_empty():return _reject("RESEARCH_IN_PROGRESS")
	var quote:=Economy.tech_quote(technology,level+1)
	var cost:Dictionary=quote.cost
	if not _can_pay(side, cost):
		return _reject("INSUFFICIENT_STOCK")
	_pay(side, cost)
	_technology_queues[side].append({"technology":technology,"rank":level+1,"building_id":building.id,"progress":0,"max_progress":int(quote.duration_ticks),"state":"RUNNING","cost":cost.duplicate(true)})
	return _accept({"level":level+1,"cost":cost,"duration_ticks":int(quote.duration_ticks)})

func _advance_research() -> void:
	for side: String in _sides:
		if _technology_queues[side].is_empty(): continue
		var entry: Dictionary=_technology_queues[side][0]
		var producer:=_find_building(str(entry.building_id))
		if is_outpost_mode() and not producer.is_empty() and int(producer.hp)>0 and bool(producer.complete) and not _outpost_operational(producer):entry.state="SITE_CONTESTED";continue
		if producer.is_empty() or int(producer.hp)<=0 or not producer.complete:
			# A destroyed paid research site must not permanently lock the side's
			# unique research slot. Retain earned work and committed cost; resume
			# only at a real surviving, completed friendly foundry in stable order.
			producer = {}
			for candidate: Dictionary in _buildings:
				if candidate.side == side and candidate.building_type == "FOUNDRY" and bool(candidate.complete) and int(candidate.hp) > 0:
					if is_outpost_mode() and not _outpost_operational(candidate):continue
					producer = candidate
					break
			if producer.is_empty():
				entry.state="BLOCKED_FOUNDRY"
				continue
			entry.building_id = producer.id
		entry.state="RUNNING"
		entry.progress=mini(int(entry.max_progress),int(entry.progress)+1)
		if entry.progress==entry.max_progress:
			_technology[side][entry.technology]=int(entry.get("rank",1))
			_technology_queues[side].pop_front()
			for structure:Dictionary in _buildings:
				if structure.side==side:_apply_building_technology_v4(structure)


func _advance_capture() -> void:
	var frame := MilitaryFactsM93.capture(_last_soldiers, _sites, _sides, CAPTURE_RADIUS)
	var site_index := 0
	for site: Dictionary in _sites:
		var presence: Dictionary = frame.presence[site_index]
		site_index += 1
		site["presence"] = presence
		if int(frame.guards.get(str(site.id), 0) if frame.guards != null else _neutral_guard_count(str(site.id)))>0: continue
		var leader:=""
		var highest:=0
		var tied:=false
		for side: String in _sides:
			if int(presence[side])>highest:
				highest=int(presence[side]); leader=side; tied=false
			elif int(presence[side])==highest: tied=true
		if highest<=0 or tied: continue
		if not str(site["capture_side"]).is_empty() and site["capture_side"] != leader and int(site["progress"]) > 0:
			site["progress"] = int(site["progress"]) - 1
			if int(site["progress"]) == 0:
				site["owner"] = ""
				site["capture_side"] = ""
			continue
		site["capture_side"] = leader
		site["progress"] = mini(CAPTURE_THRESHOLD, int(site["progress"]) + 1)
		if int(site["progress"]) == CAPTURE_THRESHOLD:
			site["owner"] = leader


func _recover_mining(side: String) -> void:
	var site := _mineable_site(side)
	if not site.is_empty():
		_economy[side]["work_site_id"] = site["id"]
		return
	_economy[side]["work_site_id"] = ""
	if int(_economy[side]["targets"]["MATERIAL"]) > 0:
		_economy[side]["targets"]["RESERVE"] = int(_economy[side]["targets"]["RESERVE"]) + int(_economy[side]["targets"]["MATERIAL"])
		_economy[side]["targets"]["MATERIAL"] = 0
		_reconcile_roles(side)

func _essence_capacity(side: String) -> int:
	var count:=0
	for site: Dictionary in _sites:
		if site.get("resource","")=="ESSENCE" and site.owner==side and int(_source_for_site(str(site.id),"ESSENCE").get("remaining",0))>0 and not _source_base(site,side).is_empty():count+=1
	return count*Economy.ESSENCE_WORKER_CAP

func _recover_essence(side: String) -> void:
	var source:=_usable_source(side,"ESSENCE")
	_economy[side].essence_site_id=str(source.get("site_id",""))
	var cap:=_essence_capacity(side)
	var assigned:=int(_economy[side].targets.ESSENCE)
	if assigned>cap:
		_economy[side].targets.ESSENCE=cap
		_economy[side].targets.RESERVE=int(_economy[side].targets.RESERVE)+assigned-cap
		_reconcile_roles(side)


func _reconcile_roles(side: String) -> void:
	var remaining: Dictionary = _economy[side]["targets"].duplicate()
	var assigned := {}
	# Keep current desired assignments whenever possible, then fill stable ID order.
	for worker: Dictionary in _workers:
		if worker["side"] != side or int(worker["hp"]) <= 0:
			continue
		var role := str(worker["desired_role"])
		if int(remaining.get(role, 0)) > 0:
			remaining[role] = int(remaining[role]) - 1
			assigned[worker["id"]] = role
	for worker: Dictionary in _workers:
		if worker["side"] != side or int(worker["hp"]) <= 0 or assigned.has(worker["id"]):
			continue
		for role: String in ROLES:
			if int(remaining.get(role, 0)) > 0:
				remaining[role] = int(remaining[role]) - 1
				assigned[worker["id"]] = role
				break
	for worker: Dictionary in _workers:
		if worker["side"] != side or not assigned.has(worker["id"]):
			continue
		var desired := str(assigned[worker["id"]])
		worker["desired_role"] = desired
		if int(worker["cargo_amount"]) == 0 and worker["role"] != desired:
			worker["role"] = desired
			worker["state"] = "RESERVE" if desired == "RESERVE" else "TRAVEL_TO_SOURCE"
			worker["gather_progress"] = 0
			worker["building_id"] = ""


func _advance_workers() -> void:
	assert(not m84_worker_phase)
	m84_worker_phase = true
	_m95_worker_motion = null
	m84_worker_geometry = null
	m84_worker_static_bodies.clear()
	m84_worker_point_results.clear()
	for building: Dictionary in _buildings:
		if int(building.hp)>0: m84_worker_static_bodies.append(building)
	m84_worker_static_bodies.append_array(_terrain)
	_prepare_worker_soldier_grid_m84()
	_advance_workers_prepared_m84()
	_m95_worker_motion = null
	m84_worker_phase = false
	m84_worker_geometry = null
	m84_worker_static_bodies.clear()
	m84_worker_point_results.clear()
	m84_worker_soldier_grid.clear()
	m84_worker_soldier_grid_valid = false

func _advance_workers_prepared_m84() -> void:
	# Gathering, defending and waiting workers do not need a whole-scene motion
	# index. The first actual stride prepares it from this phase's live facts;
	# later strides keep the original immediate sequential occupancy updates.
	var motion: RefCounted = null
	var assignments := _gather_assignments()
	for worker: Dictionary in _workers:
		worker["previous_position"] = worker["position"]
		if int(worker["hp"]) <= 0:
			continue
		if int(worker.get("last_action_tick",-100))>=0 and _tick-int(worker.last_action_tick)<8:
			worker.state="DEFENDING"
			continue
		var side := str(worker["side"])
		var base := _nearest_base(worker["position"], side)
		if worker.get("cargo_type","")=="ESSENCE":
			var mine:=_nearest_essence_mine(worker.position,side)
			if not mine.is_empty():base=mine
		var carrying := int(worker["cargo_amount"]) > 0
		# A loaded survivor must be able to rebuild the last lost depot. Keep
		# the real cargo on its body; once a depot exists it still delivers
		# before any further work. Other roles continue waiting for a depot.
		var recovery_builder: bool = carrying and base.is_empty() and worker["desired_role"] == "CONSTRUCTION_REPAIR"
		if recovery_builder: worker["role"] = "CONSTRUCTION_REPAIR"
		if carrying and not recovery_builder:
			worker["state"] = "TRAVEL_TO_DEPOT"
			if base.is_empty():
				worker["state"] = "WAITING_DEPOT"
				continue
			var depot := _station_target(worker, _depot_station(base, worker), "DEPOT:" + str(base["id"]))
			if _move_worker(worker, depot, motion):
				var cargo := str(worker["cargo_type"])
				var upkeep:=Economy.M71.upkeep(int(_population(side,_military_population).used))
				var delivery:=Economy.M71.delivery(cargo,int(worker.cargo_amount),int(upkeep.material_efficiency_percent),int(_economy[side].tax_remainder_percent.get(cargo,0)))
				_economy[side]["stock"][cargo] = int(_economy[side]["stock"][cargo]) + int(delivery.net)
				_economy[side]["delivered"][cargo] = int(_economy[side]["delivered"][cargo]) + int(delivery.net)
				_economy[side].delivered_gross[cargo]=int(_economy[side].delivered_gross[cargo])+int(delivery.gross)
				if cargo=="MATERIAL":
					_economy[side].taxed.MATERIAL=int(_economy[side].taxed.MATERIAL)+int(delivery.tax)
					_economy[side].tax_remainder_percent.MATERIAL=int(delivery.remainder_percent)
				worker["cargo_type"] = ""
				worker["cargo_amount"] = 0
				worker["role"] = worker["desired_role"]
				worker["gather_progress"] = 0
			continue
		var role := str(worker["role"])
		if role == "CONSTRUCTION_REPAIR":
			var blueprint := _first_blueprint(side)
			if blueprint.is_empty():
				worker["state"] = "WAITING_BUILDING"
				worker["building_id"] = ""
				continue
			worker["building_id"] = blueprint["id"]
			worker["state"] = "CONSTRUCTING" if _move_worker(worker, _build_station(blueprint, worker), motion) else "TRAVEL_TO_CONSTRUCTION"
			continue
		if role == "RESERVE" or base.is_empty():
			worker["state"] = "RESERVE" if role == "RESERVE" else "WAITING_DEPOT"
			continue
		var source:=_worker_source(worker,role,assignments)
		if source.is_empty():
			worker["state"]="WAITING_SOURCE_SLOT" if not _usable_source(side,role).is_empty() else "WAITING_MINE" if role=="MATERIAL" else "WAITING_FOOD"
			worker["source_id"]=""
			worker["site_id"]=""
			worker["gather_progress"]=0
			continue
		if str(worker.get("source_id",""))!=str(source.id): worker["gather_progress"]=0
		worker["source_id"]=source.id
		worker["site_id"]=source.site_id
		var source_position: Vector2i=source.position+Vector2i((int(worker.index)%3-1)*20,0)
		source_position = _station_target(worker, source_position, "SOURCE:" + role + ":" + str(worker["site_id"]))
		if not _move_worker(worker, source_position, motion):
			worker["state"] = "TRAVEL_TO_SOURCE"
			continue
		worker["state"] = "GATHERING"
		worker["gather_progress"] = int(worker["gather_progress"]) + 1
		if int(worker["gather_progress"]) >= Economy.gather_ticks(role):
			worker["cargo_type"] = role
			var loaded:=mini(Economy.cargo(role),int(source.remaining))
			source.remaining=int(source.remaining)-loaded
			worker["cargo_amount"] = loaded
			worker["gather_progress"] = 0
			worker["state"] = "TRAVEL_TO_DEPOT"


func _advance_construction() -> void:
	if is_outpost_mode():
		for building: Dictionary in _buildings:
			if int(building.hp)<=0 or building.complete:continue
			if not _outpost_operational(building):building.state="SITE_CONTESTED";continue
			var previous:=int(building.progress)
			building.progress=mini(int(building.max_progress),previous+1)
			var total:=int(building.max_hp)-int(building.get("construction_base_hp",1))
			var duration:=maxi(1,int(building.max_progress))
			building.hp=mini(int(building.max_hp),int(building.hp)+int(total*int(building.progress)/duration)-int(total*previous/duration))
			building.state="CONSTRUCTING"
			if int(building.progress)>=int(building.max_progress):building.complete=true;building.state="COMPLETE";building.reconstructing=false
		return
	for side: String in _sides:
		var building := _first_blueprint(side)
		if building.is_empty():
			continue
		var labour := 0
		for worker: Dictionary in _workers:
			if worker["side"] == side and int(worker["hp"]) > 0 and worker["role"] == "CONSTRUCTION_REPAIR" and worker["state"] == "CONSTRUCTING" and worker["building_id"] == building["id"] and Vector2(worker["position"]).distance_to(Vector2(building["position"])) <= float(building["radius"]) + 36:
				labour += 1
		var previous_progress:=int(building.progress)
		building["progress"] = mini(int(building["max_progress"]), previous_progress + labour)
		if building.get("reconstructing",false) and labour>0:
			var total:=int(building.max_hp)-int(building.get("construction_base_hp",1))
			var work:=maxi(1,int(building.max_progress))
			var earned:=int(total*int(building.progress)/work)-int(total*previous_progress/work)
			building.hp=mini(int(building.max_hp),int(building.hp)+earned)
		building["state"] = "CONSTRUCTING" if labour > 0 else "WAITING_BUILDERS"
		if int(building["progress"]) == int(building["max_progress"]):
			building["complete"] = true
			building["state"] = "COMPLETE"
			building["reconstructing"]=false
			building["paid_rebuild_pending"]=false


func _advance_production(events: Array[Dictionary]) -> void:
	# Spendable stock was debited on enqueue. Reservations only become entities
	# once a clear physical outlet and retained total capacity permit admission.
	var admitted := {}
	for side: String in _sides: admitted[side]=0
	for building: Dictionary in _buildings:
		if not bool(building["complete"]) or int(building["hp"]) <= 0 or building["queue"].is_empty():
			continue
		if is_outpost_mode() and not _outpost_operational(building):building.queue[0].state="SITE_CONTESTED";continue
		var entry: Dictionary = building["queue"][0]
		if not building["base_upgrade"].is_empty():
			entry["state"]="BASE_UPGRADING"
			continue
		var side := str(building["side"])
		var population := _population(side, _military_population)
		if int(population["used"]) + int(population["reserved"]) + int(admitted[side]) > int(population["maximum"]):
			entry["state"] = "BLOCKED_CAPACITY"
			continue
		entry["progress"] = mini(int(entry["max_progress"]), int(entry["progress"]) + 1)
		entry["state"] = "RUNNING"
		if int(entry["progress"]) < int(entry["max_progress"]):
			continue
		var type := str(entry["unit_type"])
		# Previously legal paid queues retain their earned tier rights, but
		# actual physical admission still cannot duplicate a living archetype
		# or exceed Combat's global body limit (including this tick's births).
		if type=="hero" and _hero_admission_blocked(side,str(entry.get("hero_archetype",HeroCatalog.DEFAULT_ARCHETYPE)),entry):
			entry["state"]="BLOCKED_HERO"
			continue
		var spawn_radius:=FootprintR10.physical_radius(UNIT_CATALOG[type]) if type!="worker" else int(UNIT_CATALOG[type].radius)
		var candidate: Dictionary = _deployment_position(building,spawn_radius,str(UNIT_CATALOG[type].movement_layer))
		if candidate.is_empty():
			entry["state"] = "BLOCKED_OUTLET"
			continue
		var position: Vector2i = candidate["position"]
		if type == "worker":
			var worker := _new_worker("%s_worker_%03d" % [side.to_lower(), _next_worker], side, position, _next_worker)
			_next_worker += 1
			_workers.append(worker)
			_economy[side]["targets"]["RESERVE"] = int(_economy[side]["targets"]["RESERVE"]) + 1
		else:
			var id := "recruit_%s_%04d" % [side.to_lower(), _next_recruit]
			_next_recruit += 1
			var spawn := {"type": "SPAWN", "id": id, "unit_type": type, "side": side, "position": position, "warband_id": entry["warband_id"]}
			if type == "hero":
				spawn["hero_archetype"] = entry.get("hero_archetype", HeroCatalog.DEFAULT_ARCHETYPE)
				for key: String in ["hero_mode","hero_id","hero_slot","hero_level","hero_life_generation"]:
					spawn[key] = entry[key]
			events.append(spawn)
			# Include earlier same-tick admissions in collision and capacity checks.
			var admitted_body := {"id": id, "side": side, "position": position, "hp": 1, "alive": true, "radius": spawn_radius, "unit_type": type,"movement_layer":UNIT_CATALOG[type].movement_layer,"faction_id":get_faction(side)}
			if type == "hero": admitted_body["hero_archetype"] = spawn["hero_archetype"]
			_last_soldiers.append(admitted_body)
			admitted[side] = int(admitted[side]) + int(entry["population"])
		building["queue"].pop_front()
	for side: String in _sides:
		_military_population[side] = int(_military_population[side]) + int(admitted[side])


func _deployment_position(building: Dictionary, radius: int, layer: String="GROUND") -> Dictionary:
	var outlet: Vector2i = building["outlet"]
	# No producer exclusion: a neighbour behind the outlet is only legal if it
	# clears the producer footprint too. World margins are stricter than Combat.
	if _position_clear(outlet,radius,"",layer): return {"position":outlet}
	var mirror: int=_side_config(str(building.side)).get("spawn_direction",Vector2i.RIGHT).x
	for ring: int in DEPLOYMENT_RINGS:
		for direction: Vector2i in DEPLOYMENT_DIRECTIONS:
			var point := outlet+Vector2i(direction.x*mirror,direction.y)*ring
			if _position_clear(point,radius,"",layer): return {"position":point}
	return {}


func _advance_towers(events: Array[Dictionary]) -> void:
	for building: Dictionary in _buildings:
		if not building.get("defense_active",false) or int(building["tower_ready_tick"]) > _tick:
			continue
		var target := {}
		var distance := INF
		for soldier: Dictionary in _last_soldiers + _workers:
			if (str(soldier.get("side", "")) not in _sides and soldier.get("side")!="NEUTRAL") or soldier["side"] == building["side"] or int(soldier.get("hp", 0)) <= 0 or not bool(soldier.get("alive", true)):
				continue
			var next_distance := Vector2(building["position"]).distance_to(Vector2(soldier["position"]))
			if next_distance <= int(building.attack_range) and (next_distance < distance or (is_equal_approx(next_distance, distance) and str(soldier["id"]) < str(target.get("id", "~")))):
				target = soldier
				distance = next_distance
		if not target.is_empty():
			_tower_hit(building,target,int(building.damage),events)
			var observed_targets: Array=[{"id":target.id,"position":target.position,"primary":true}]
			var radius:=int(building.get("splash_radius",0))
			var cap:=int(building.get("splash_max_targets",0))
			var splash:=int(building.get("splash_damage",0))
			if radius>0 and cap>0 and splash>0:
				var nearby: Array[Dictionary]=[]
				for enemy: Dictionary in _last_soldiers+_workers:
					if enemy.get("id")==target.id or enemy.get("side")==building.side or (enemy.get("side") not in _sides and enemy.get("side")!="NEUTRAL") or int(enemy.get("hp",0))<=0 or not bool(enemy.get("alive",true)):continue
					if enemy.get("movement_layer","GROUND") not in building.get("splash_layers",[]):continue
					if Vector2(enemy.position).distance_squared_to(Vector2(target.position))<=radius*radius:nearby.append(enemy)
				nearby.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
					var da:=Vector2(a.position).distance_squared_to(Vector2(target.position))
					var db:=Vector2(b.position).distance_squared_to(Vector2(target.position))
					return str(a.id)<str(b.id) if is_equal_approx(da,db) else da<db)
				for index: int in range(mini(cap,nearby.size())):
					var enemy: Dictionary=nearby[index]
					_tower_hit(building,enemy,splash,events)
					observed_targets.append({"id":enemy.id,"position":enemy.position,"primary":false})
			building["last_action_targets"]=observed_targets
			building["tower_ready_tick"] = _tick + int(building.attack_cooldown_ticks)
			building["last_action_tick"] = _tick
			building["last_action_kind"] = "ATTACK"
			building["last_action_target_id"] = str(target["id"])
			building["last_action_target_position"] = target["position"]


func _tower_hit(building:Dictionary,target:Dictionary,raw:int,events:Array[Dictionary])->void:
	var attack_type:=str(building.get("attack_type","PIERCE"))
	if target.get("unit_type")=="worker":
		damage_workers([{"worker_id":target.id,"damage":DamageRules.resolve(raw,attack_type,target),"side":building.side,"source_id":building.id}])
	else:
		events.append({"type":"DAMAGE","target_id":target.id,"damage":raw,"attack_type":attack_type,"side":building.side,"source_id":building.id})


func _population(side: String, military_population: Dictionary) -> Dictionary:
	var maximum := 0
	var reserved := 0
	for site: Dictionary in _sites:
		if site["owner"] == side:
			maximum += int(site["capacity"])
	for building: Dictionary in _buildings:
		if building["side"] == side:
			for entry: Dictionary in building["queue"]:
				reserved += int(entry["population"])
	return {"used": _worker_count(side) + maxi(0, int(military_population.get(side, 0))), "reserved": reserved, "maximum": maximum, "max": maximum}


func _position_clear(position: Vector2i, radius: int, excluded_building: String, layer: String="GROUND") -> bool:
	if position.x - radius < _bounds.position.x or position.y - radius < _bounds.position.y or position.x + radius >= _bounds.end.x or position.y + radius >= _bounds.end.y:
		return false
	if layer=="GROUND" and not Navigation.point_clear(position,radius,_bounds,_terrain): return false
	for building: Dictionary in _buildings:
		if layer=="GROUND" and building["id"] != excluded_building and int(building["hp"]) > 0 and Vector2(position).distance_to(Vector2(building["position"])) < radius + int(building["radius"]) + 4:
			return false
	for worker: Dictionary in _workers:
		if layer=="GROUND" and int(worker["hp"]) > 0 and Vector2(position).distance_to(Vector2(worker["position"])) < radius + WORKER_RADIUS + 2:
			return false
	for soldier: Dictionary in _last_soldiers:
		if soldier.get("movement_layer","GROUND")==layer and int(soldier.get("hp", 0)) > 0 and bool(soldier.get("alive", true)) and Vector2(position).distance_to(Vector2(soldier["position"])) < radius + int(soldier.get("radius", 12)) + 2:
			return false
	return true


func _move_worker(worker: Dictionary, target: Vector2i, motion: RefCounted = null) -> bool:
	if worker["position"] == target:
		return true
	var geometry := _route_geometry()
	if worker["route_target"] != target or worker["route_geometry"] != geometry:
		worker["route_target"] = target
		worker["route_geometry"] = geometry
		worker["route"] = _route(worker["position"], target, str(worker["id"]))
		worker["route_stall_ticks"] = 0
		worker["route_best_distance"] = INF
	var route: Array = worker["route"]
	while not route.is_empty() and worker["position"] == route[0]:
		route.pop_front()
		worker["route_best_distance"] = INF
		worker["route_stall_ticks"] = 0
	if route.is_empty():
		worker["route_stall_ticks"] = int(worker["route_stall_ticks"]) + 1
		if int(worker["route_stall_ticks"]) >= 12:
			worker["route_geometry"] = ""
		return false
	var waypoint: Vector2i = route[0]
	var difference := Vector2(waypoint - (worker["position"] as Vector2i))
	# The visibility route describes straight segments. Request a true bounded
	# directional step rather than an L-shaped independent-axis clamp.
	var desired: Vector2i = waypoint if difference.length() <= WORKER_STEP else (worker["position"] as Vector2i) + Vector2i((difference.normalized() * WORKER_STEP).round())
	if motion == null:
		if m84_worker_phase:
			if _m95_worker_motion == null:
				_m95_worker_motion = WorkerBodyMotion.new(_worker_collision_bodies(),_bounds,WORKER_STEP)
			motion = _m95_worker_motion
		else:
			motion = WorkerBodyMotion.new(_worker_collision_bodies(),_bounds,WORKER_STEP)
	worker["position"] = motion.resolve_move(str(worker["id"]),desired)
	var remaining := Vector2(worker["position"]).distance_to(Vector2(waypoint))
	if remaining + 0.5 < float(worker["route_best_distance"]):
		worker["route_best_distance"] = remaining
		worker["route_stall_ticks"] = 0
	else:
		worker["route_stall_ticks"] = int(worker["route_stall_ticks"]) + 1
		if int(worker["route_stall_ticks"]) >= 12:
			worker["route_geometry"] = ""
	return worker["position"] == target


func _worker_collision_bodies() -> Array[Dictionary]:
	var bodies: Array[Dictionary] = []
	for other: Dictionary in _workers:
		bodies.append({"id": other["id"], "position": other["position"], "desired": other["position"], "radius": WORKER_RADIUS, "active": int(other["hp"]) > 0, "max_step": 0})
	for building: Dictionary in _buildings:
		bodies.append({"id": "body:" + str(building["id"]), "position": building["position"], "desired": building["position"], "radius": building["radius"], "active": int(building["hp"]) > 0, "max_step": 0,"static":true})
	for soldier: Dictionary in _last_soldiers:
		if soldier.get("movement_layer","GROUND")!="GROUND": continue
		bodies.append({"id": "body:" + str(soldier["id"]), "position": soldier["position"], "desired": soldier["position"], "radius": soldier.get("radius", 12), "active": int(soldier.get("hp", 0)) > 0 and bool(soldier.get("alive", true)), "max_step": 0})
	for terrain: Dictionary in _terrain:
		if bool(terrain.blocks_ground): bodies.append({"id":terrain.id,"position":terrain.position,"desired":terrain.position,"radius":terrain.radius,"active":true,"max_step":0,"static":true})
	return bodies


func _route_geometry() -> String:
	if not m84_worker_phase: return _route_geometry_uncached_m84()
	if m84_worker_geometry == null: m84_worker_geometry = _route_geometry_uncached_m84()
	return m84_worker_geometry

func _route_geometry_uncached_m84() -> String:
	var entries: Array[String] = []
	for terrain: Dictionary in _terrain:
		if bool(terrain.blocks_ground): entries.append("%s:%s:%d"%[terrain.id,terrain.position,terrain.radius])
	for building: Dictionary in _buildings:
		if int(building["hp"]) > 0:
			entries.append("%s:%s:%d" % [building["id"], building["position"], building["radius"]])
	return "|".join(entries)


func _route(start: Vector2i, target: Vector2i, worker_id: String) -> Array:
	return Navigation.find_path(start,target,WORKER_RADIUS,_bounds,_routing_bodies(worker_id))


func _routing_bodies(worker_id: String) -> Array[Dictionary]:
	var obstacles: Array[Dictionary] = []
	for terrain: Dictionary in _terrain:
		if bool(terrain.blocks_ground): obstacles.append(terrain)
	for building: Dictionary in _buildings:
		if int(building["hp"]) > 0:
			obstacles.append({"id": "building:" + str(building["id"]), "position": building["position"], "radius": building["radius"]})
	for soldier: Dictionary in _last_soldiers:
		if soldier.get("movement_layer","GROUND")=="GROUND" and int(soldier.get("hp", 0)) > 0 and bool(soldier.get("alive", true)):
			obstacles.append({"id": "soldier:" + str(soldier["id"]), "position": soldier["position"], "radius": soldier.get("radius", 12)})
	for worker: Dictionary in _workers:
		if worker["id"] != worker_id and int(worker["hp"]) > 0:
			obstacles.append({"id": "worker:" + str(worker["id"]), "position": worker["position"], "radius": WORKER_RADIUS})
	return obstacles


func _route_point_clear(point: Vector2i, obstacles: Array = []) -> bool:
	if m84_worker_phase and obstacles.is_empty():
		if not m84_worker_point_results.has(point):
			m84_worker_point_results[point] = Navigation.point_clear(point,WORKER_RADIUS,_bounds,m84_worker_static_bodies)
		return bool(m84_worker_point_results[point])
	var bodies: Array = _buildings.filter(func(building: Dictionary) -> bool: return int(building["hp"]) > 0) if obstacles.is_empty() else obstacles
	if obstacles.is_empty(): bodies.append_array(_terrain)
	return Navigation.point_clear(point,WORKER_RADIUS,_bounds,bodies)


func _route_segment_clear(start: Vector2i, target: Vector2i, obstacles: Array) -> bool:
	if not _route_point_clear(target, obstacles):
		return false
	for obstacle: Dictionary in obstacles:
		var radius := int(obstacle["radius"]) + WORKER_RADIUS
		if _point_segment_distance_sq(obstacle["position"], start, target) < float(radius * radius):
			return false
	return true


func _point_segment_distance_sq(point: Vector2i, start: Vector2i, target: Vector2i) -> float:
	var segment := Vector2(target - start)
	if segment.is_zero_approx():
		return Vector2(point - start).length_squared()
	var progress := clampf(Vector2(point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return Vector2(point).distance_squared_to(Vector2(start) + segment * progress)


func _hero_admission_blocked(side: String, archetype: String, entry: Dictionary = {}) -> bool:
	var living := 0
	for soldier: Dictionary in _last_soldiers:
		if soldier.get("side")==side and soldier.get("unit_type")=="hero" and int(soldier.get("hp",0))>0 and bool(soldier.get("alive",true)):
			living+=1
			if soldier.get("hero_archetype",HeroCatalog.DEFAULT_ARCHETYPE)==archetype: return true
	if living>=HeroCatalog.MAX_ACTIVE_HEROES: return true
	if entry.is_empty(): return false
	for hero: Dictionary in _observed_hero_roster():
		if hero.get("side", "") != side: continue
		var hero_id := str(hero.get("unit_id",hero.get("id","")))
		if entry.get("hero_mode", "") == "REVIVE" and hero_id == entry.get("hero_id", ""):
			return bool(hero.get("alive",false)) or int(hero.get("life_generation",1)) != int(entry.get("hero_life_generation",1))
		if entry.get("hero_mode", "") == "RECRUIT" and int(hero.get("hero_slot",0)) == int(entry.get("hero_slot",0)): return true
	return entry.get("hero_mode", "") == "REVIVE"


func _hero_unavailable(side: String, archetype: String = HeroCatalog.DEFAULT_ARCHETYPE) -> bool:
	for soldier: Dictionary in _last_soldiers:
		if soldier.get("side", "") == side and soldier.get("unit_type", "") == "hero" and soldier.get("hero_archetype", HeroCatalog.DEFAULT_ARCHETYPE) == archetype and int(soldier.get("hp", 0)) > 0 and bool(soldier.get("alive", true)):
			return true
	for building: Dictionary in _buildings:
		if building["side"] == side:
			for entry: Dictionary in building["queue"]:
				if entry["unit_type"] == "hero" and entry.get("hero_archetype", HeroCatalog.DEFAULT_ARCHETYPE) == archetype:
					return true
	return false


func _hero_slots(side: String) -> int:
	var count := 0
	for hero: Dictionary in _observed_hero_roster():
		if hero.get("side") == side: count += 1
	for building: Dictionary in _buildings:
		if building["side"] == side:
			for entry: Dictionary in building["queue"]:
				if entry["unit_type"] == "hero" and entry.get("hero_mode","RECRUIT") == "RECRUIT": count += 1
	return count


func _food_source_position(base: Dictionary, index: int) -> Vector2i:
	return base["position"] + Vector2i(-120 + (index % 3) * 20, -120)


func _mine_source_position(site: Dictionary, index: int) -> Vector2i:
	return site["position"] + Vector2i(96 + (index % 3) * 20, -150)


func _resource_sources() -> Array[Dictionary]:
	if is_outpost_mode(): return _outpost_source_observations()
	var sources: Array[Dictionary] = []
	var assignments:=_gather_assignments()
	var efficiency:={}
	for side: String in _sides:efficiency[side]=int(Economy.M71.upkeep(int(_population(side,_military_population).used)).material_efficiency_percent)
	for source: Dictionary in _sources:
		var observation:=source.duplicate(true)
		var site:=_find_site(str(source.site_id))
		var owner:=str(site.get("owner",""))
		var base:=_source_base(site,owner)
		observation.merge({"initial_amount":int(source.initial),"remaining_amount":int(source.remaining),"owner":owner,"active":owner in _sides and not base.is_empty() and int(source.remaining)>0,"state":"DEPLETED" if int(source.remaining)<=0 else "ACTIVE" if owner in _sides and not base.is_empty() else "UNSERVED","base_id":str(base.get("id",""))})
		var assigned: Array[String]=[]
		for id: String in assignments:
			if assignments[id]==source.id:assigned.append(id)
		var capacity:=Economy.worker_capacity(str(source.kind))
		var percentages:={}
		for side: String in _sides:percentages[side]=int(efficiency[side]) if source.kind=="MATERIAL" else 100
		observation.merge({"worker_capacity":capacity,"assigned_worker_ids":assigned,"assigned_workers":assigned.size(),"free_slots":maxi(0,capacity-assigned.size()) if observation.active else 0,"efficiency_percent_by_side":percentages,"owner_efficiency_percent":int(percentages.get(owner,100))})
		sources.append(observation)
	return sources


func _bind_outpost(building: Dictionary, site_id: String) -> void:
	building.site_id=site_id
	building["fixed_pad"]=true
	building["fixed"]=false
	building["attackable"]=true
	for pad: Dictionary in _outpost_slots:
		if pad.site_id==site_id and building.building_type in pad.get("allowed_building_types",[pad.building_type]) and pad.position==building.position:
			building["slot_id"]=pad.id;break
	if building.building_type=="SHOP": building["service_range"]=HeroItems.SHOP_RANGE

func _outpost_operational(building: Dictionary) -> bool:
	return Outposts.fully_owned(_find_site(str(building.get("site_id",""))),str(building.get("side","")))

func get_building_slots() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not is_outpost_mode():return result
	var occupied: Dictionary={}
	for building: Dictionary in _buildings:
		if int(building.hp)<=0:continue
		if building.has("slot_id"):occupied[str(building.slot_id)]=building
		else:
			for pad: Dictionary in _outpost_slots:
				if building.building_type in pad.get("allowed_building_types",[pad.building_type]) and pad.position==building.position:occupied[str(pad.id)]=building;break
	var recipes: Dictionary={}
	for pad: Dictionary in _outpost_slots:
		var site:=_find_site(str(pad.site_id))
		var owner:=str(site.get("owner",""))
		var quote_side:=owner if owner in _sides else _sides[0]
		if not recipes.has(quote_side):recipes[quote_side]=get_building_catalog(quote_side)
		var recipe: Dictionary=recipes[quote_side].get(str(pad.building_type),{})
		var reason:=""
		if occupied.has(str(pad.id)):reason="SLOT_OCCUPIED"
		elif not Outposts.fully_owned(site,owner):reason="NEEDS_COMPLETE_CAPTURE"
		elif get_base_tier(owner)<int(Progression.BUILDING_TIERS.get(str(pad.building_type),1)):reason="BASE_TIER_REQUIRED"
		elif not _position_clear(pad.position,int(recipe.get("radius",32)),""):reason="PLACEMENT_BLOCKED"
		var observation:=pad.duplicate(true)
		observation.merge({"side":owner,"occupied":occupied.has(str(pad.id)),"building_id":str(occupied.get(str(pad.id),{}).get("id","")),"available":reason.is_empty(),"reason":reason,"cost":recipe.get("cost",{}).duplicate(true),"duration_ticks":int(recipe.get("work",0)),"required_base_tier":int(Progression.BUILDING_TIERS.get(str(pad.building_type),1))})
		observation["faction_id"]=get_faction(quote_side)
		if pad.get("allowed_building_types",[pad.building_type]).size()==1:observation["label"]=str(recipe.get("label",pad.building_type))
		var choices: Dictionary={}
		for allowed: String in pad.get("allowed_building_types",[pad.building_type]):
			var option: Dictionary=recipes[quote_side].get(allowed,{})
			choices[allowed]={"cost":option.get("cost",{}).duplicate(true),"duration_ticks":int(option.get("work",0)),"required_base_tier":int(Progression.BUILDING_TIERS.get(allowed,1))}
		observation["building_choices"]=choices
		result.append(observation)
	return result

func _place_outpost_building(command: Dictionary, side: String) -> Dictionary:
	if not _fields(command,["type","building_type","position"]) or not command.building_type is String or not command.position is Vector2i:return _reject("INVALID_PLACEMENT")
	var selected: Dictionary={}
	for pad: Dictionary in get_building_slots():
		if command.building_type in pad.get("allowed_building_types",[pad.building_type]) and pad.position==command.position:selected=pad;break
	if selected.is_empty():return _reject("FIXED_BUILDING_SLOT_REQUIRED")
	if str(selected.side)!=side:return _reject("SITE_NOT_OWNED")
	if not bool(selected.available):return _reject(str(selected.reason))
	var choice: Dictionary=selected.building_choices.get(str(command.building_type),{})
	if choice.is_empty():return _reject("INCOMPATIBLE_BUILDING_SLOT")
	if get_base_tier(side)<int(choice.required_base_tier):return _reject("BASE_TIER_REQUIRED")
	var recipe: Dictionary=get_building_catalog(side).get(str(command.building_type),{})
	if not _position_clear(command.position,int(recipe.get("radius",32)),""):return _reject("PLACEMENT_BLOCKED")
	var cost: Dictionary=choice.cost
	if not _can_pay(side,cost):return _reject("INSUFFICIENT_STOCK")
	# Validated exact pad first; the paid blueprint immediately owns its slot.
	_pay(side,cost)
	var id:="%s_%s_%04d"%[side.to_lower(),str(command.building_type).to_lower(),_next_building]
	_next_building+=1
	var building:=_new_building(id,side,str(command.building_type),command.position,false)
	building.cost=cost.duplicate(true)
	_bind_outpost(building,str(selected.site_id))
	_buildings.append(building)
	return _accept({"building_id":id,"slot_id":selected.id,"cost":cost.duplicate(true),"duration_ticks":choice.duration_ticks})

func _outpost_income_base(site: Dictionary) -> Dictionary:
	var owner:=str(site.get("owner",""))
	if owner not in _sides or not Outposts.fully_owned(site,owner):return {}
	var required:="ESSENCE_MINE" if Outposts.site_kind(site)=="SATELLITE" else "BASE"
	if Outposts.site_kind(site) not in ["RESOURCE","SATELLITE"]:return {}
	for building: Dictionary in _buildings:
		if building.get("site_id","")==site.get("id","") and building.side==owner and building.building_type==required and building.complete and int(building.hp)>0:return building
	return {}

func _advance_outpost_income() -> void:
	for source: Dictionary in _sources:
		if str(source.kind) != Currency.KEY: continue
		var site:=_find_site(str(source.site_id))
		var base:=_outpost_income_base(site)
		if base.is_empty() or int(source.remaining)<=0:continue
		var side:=str(site.owner)
		var key:=side+":"+str(source.id)
		# Fixed-point gross first, maintenance second. One source-owned carry;
		# changing ownership cannot transfer another player's fractional income.
		var income_percent:=int(_technology_modifiers_v4(side).income_percent)
		var numerator:=int(_auto_remainders.get(key,0))+Outposts.rate_numerator(site,str(source.kind))*(100+income_percent)
		var gross:=mini(int(source.remaining),int(numerator/10000))
		_auto_remainders[key]=numerator%10000
		if gross<=0:continue
		var upkeep:=Economy.M71.upkeep(int(_population(side,_military_population).used))
		var kind:=str(source.kind)
		var delivery:=Economy.M71.delivery(kind,gross,int(upkeep.material_efficiency_percent),int(_economy[side].tax_remainder_percent.get(kind,0)))
		source.remaining=int(source.remaining)-gross
		_economy[side].stock[kind]=int(_economy[side].stock.get(kind,0))+int(delivery.net)
		_economy[side].delivered[kind]=int(_economy[side].delivered.get(kind,0))+int(delivery.net)
		_economy[side].delivered_gross[kind]=int(_economy[side].delivered_gross.get(kind,0))+gross
		if kind=="MATERIAL":
			_economy[side].taxed.MATERIAL=int(_economy[side].taxed.MATERIAL)+int(delivery.tax)
			_economy[side].tax_remainder_percent.MATERIAL=int(delivery.remainder_percent)

func _outpost_income_readout(site: Dictionary) -> Dictionary:
	var rates: Dictionary={"FOOD":0.0,"MATERIAL":0.0,"ESSENCE":0.0}
	var remaining: Dictionary={}
	var base:=_outpost_income_base(site)
	var owner:=str(site.get("owner",""))
	var efficiency:=100
	if owner in _sides:efficiency=int(Economy.M71.upkeep(int(_population(owner,_military_population).used)).material_efficiency_percent)
	for source: Dictionary in _sources:
		if source.site_id!=site.id:continue
		var kind:=str(source.kind)
		remaining[kind]=int(source.remaining)
		if not base.is_empty() and int(source.remaining)>0:rates[kind]=float(Outposts.rate_numerator(site,kind))*0.2*(1.0+float(_technology_modifiers_v4(owner).income_percent)/100.0)*(float(efficiency)/100.0 if kind=="MATERIAL" else 1.0)
	var active:=false
	for rate: float in rates.values():active=active or rate>0.0
	return {"income_active":active,"net_rates":rates,"income_per_second":rates,"remaining":remaining,"production_mode":"AUTO","income_reason":"ACTIVE" if active else "NEEDS_COMPLETE_CAPTURE" if not Outposts.fully_owned(site,owner) else "ECONOMIC_BUILDING_REQUIRED" if base.is_empty() else "DEPLETED"}

func _outpost_source_observations() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for source: Dictionary in _sources:
		var site:=_find_site(str(source.site_id))
		var info:=_outpost_income_readout(site)
		var item:=source.duplicate(true)
		var base:=_outpost_income_base(site)
		var kind:=str(source.kind)
		item.merge({"owner":str(site.get("owner","")),"active":float(info.net_rates.get(kind,0))>0.0,"income_active":float(info.net_rates.get(kind,0))>0.0,"initial_amount":int(source.initial),"remaining_amount":int(source.remaining),"production_mode":"AUTO","worker_capacity":0,"assigned_workers":0,"assigned_worker_ids":[],"free_slots":0,"base_id":str(base.get("id","")),"income_per_second":float(info.net_rates.get(kind,0)),"net_rates":info.net_rates.duplicate(true),"state":"DEPLETED" if int(source.remaining)<=0 else "ACTIVE" if not base.is_empty() else "UNSERVED"})
		item["gross_rates"]={kind:float(Outposts.rate_twentieths(site,kind))*(1.0+float(_technology_modifiers_v4(str(item.owner)).income_percent)/100.0) if bool(item.income_active) else 0.0}
		result.append(item)
	return result

func _refresh_outpost_defenses() -> void:
	# No additional free SITE_TOWER: exactly the authored five/two paid pads.
	for building: Dictionary in _buildings:
		if building.building_type not in ["BASE","TOWER"]:continue
		var site:=_find_site(str(building.get("site_id","")))
		var active: bool=building.complete and int(building.hp)>0 and site.get("owner","")==building.side and int(site.get("progress",0))>0
		var equivalent:=4.0 if int(building.tower_level)>=2 else 2.5
		if building.building_type=="BASE":equivalent=6.0 if int(building.base_tier)>=3 else 4.5 if int(building.base_tier)>=2 else 3.0
		var types: Array=Factions.units_for(str(building.faction_id),"RANGED")
		if types.is_empty():building.defense_active=false;continue
		building.merge(FactionTowers.defense_stats(str(building.faction_id),str(building.building_type),int(building.tower_level),Units.stats_for(str(types[0])),equivalent),true)
		building.defense_active=active

func _source_for_site(site_id: String,resource: String) -> Dictionary:
	for source: Dictionary in _sources:
		if source.site_id==site_id and source.kind==resource: return source
	return {}


func _technology_modifiers_v4(side:String)->Dictionary:
	var levels:Dictionary=_technology.get(side,{})
	var faction:=get_faction(side) if side in _sides else ""
	var cached:Dictionary=_technology_compiled_v4.get(side,{})
	if cached.is_empty() or cached.levels!=levels or cached.faction!=faction:
		cached={"levels":levels.duplicate(),"faction":faction,"modifiers":TechnologiesV4.resolve(faction,levels)}
		_technology_compiled_v4[side]=cached
	return cached.modifiers


func _apply_building_technology_v4(building:Dictionary,preserve_percentage:bool=true)->void:
	# Keep an unmodified base across research, repairs and repeated reads. Base
	# or tower upgrades explicitly replace this baseline before calling us.
	if not building.has("base_max_hp_v4"):building["base_max_hp_v4"]=int(building.max_hp)
	if not building.has("base_armor_v4"):building["base_armor_v4"]=int(building.get("armor",0))
	var mods:=_technology_modifiers_v4(str(building.side))
	var desired:=roundi(float(building.base_max_hp_v4)*(1.0+float(mods.building_max_hp_percent)/100.0))
	if desired!=int(building.max_hp):
		var before:=int(building.max_hp)
		building.hp=0 if int(building.hp)<=0 else clampi(roundi(float(building.hp)*desired/maxi(1,before)) if preserve_percentage else int(building.hp),1,desired)
		if building.has("construction_base_hp"):building.construction_base_hp=roundi(float(building.construction_base_hp)*desired/maxi(1,before))
		building.max_hp=desired
	building.armor=int(building.base_armor_v4)+int(mods.building_armor_bonus)
	building["technology_modifiers_v4"]={"max_hp_percent":mods.building_max_hp_percent,"armor_bonus":mods.building_armor_bonus}
func _source_base(site: Dictionary,side: String) -> Dictionary:
	if site.is_empty() or site.get("owner","")!=side or side not in _sides: return {}
	var required:="ESSENCE_MINE" if site.get("resource","")=="ESSENCE" else "BASE"
	for building: Dictionary in _buildings:
		if building.side==side and building.building_type==required and building.complete and int(building.hp)>0 and Vector2(site.position).distance_to(Vector2(building.position))<=BASE_SITE_RADIUS: return building
	return {}
func _usable_source(side: String,resource: String) -> Dictionary:
	var preferred:=str(_economy[side].get("essence_site_id","") if resource=="ESSENCE" else _economy[side].work_site_id)
	var selected:=_source_for_site(preferred,resource)
	if not selected.is_empty() and int(selected.remaining)>0 and not _source_base(_find_site(preferred),side).is_empty(): return selected
	for source: Dictionary in _sources:
		if source.kind==resource and int(source.remaining)>0 and not _source_base(_find_site(str(source.site_id)),side).is_empty(): return source
	return {}

func _gather_assignments() -> Dictionary:
	# Eligibility is immutable within this query; capacities and worker distance
	# remain evaluated in the exact same stable worker order as production.
	var result: Dictionary = {}
	var counts: Dictionary = {}
	var eligible: Dictionary = {}
	var ordered: Array = _workers.filter(func(worker: Dictionary)->bool:return int(worker.hp)>0 and worker.desired_role in Economy.RESOURCE_KEYS)
	ordered.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return str(a.id)<str(b.id))
	for worker: Dictionary in ordered:
		var resource := str(worker.desired_role)
		var side := str(worker.side)
		var key := side+":"+resource
		if not eligible.has(key):
			var available: Array[Dictionary] = []
			for source: Dictionary in _sources:
				if source.kind==resource and int(source.remaining)>0 and not _source_base(_find_site(str(source.site_id)),side).is_empty(): available.append(source)
			eligible[key] = available
		var preferred := str(_economy[side].get("essence_site_id","") if resource=="ESSENCE" else _economy[side].work_site_id)
		var candidates: Array[Dictionary] = []
		for source: Dictionary in eligible[key]:
			if int(counts.get(source.id,0))<Economy.worker_capacity(resource): candidates.append(source)
		candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
			var pa: int=0 if str(a.site_id)==preferred else 1
			var pb: int=0 if str(b.site_id)==preferred else 1
			if pa!=pb:return pa<pb
			var da:=Vector2(worker.position).distance_squared_to(Vector2(a.position))
			var db:=Vector2(worker.position).distance_squared_to(Vector2(b.position))
			return str(a.id)<str(b.id) if is_equal_approx(da,db) else da<db)
		if candidates.is_empty(): continue
		result[worker.id] = candidates[0].id
		counts[candidates[0].id] = int(counts.get(candidates[0].id,0))+1
	return result

func _worker_source(worker: Dictionary,resource: String,assignments: Dictionary={})->Dictionary:
	# A prepared empty table cannot gain valid sources during this phase.
	if m84_worker_phase and assignments.is_empty(): return {}
	var slots:=_gather_assignments() if assignments.is_empty() else assignments
	var id:=str(slots.get(worker.id,""))
	for source: Dictionary in _sources:
		if source.id==id and source.kind==resource and int(source.remaining)>0:return source
	return {}

func _nearest_essence_mine(position: Vector2i,side: String) -> Dictionary:
	var result:={}
	var best:=INF
	for site: Dictionary in _sites:
		if site.get("resource","")!="ESSENCE":continue
		var mine:=_source_base(site,side)
		if mine.is_empty():continue
		var distance:=Vector2(position).distance_squared_to(Vector2(mine.position))
		if distance<best:best=distance;result=mine
	return result


func _depot_station(base: Dictionary, worker: Dictionary) -> Vector2i:
	return base["position"] + Vector2i(-60 + (int(worker["index"]) % 6) * 20, 72)


func _station_target(worker: Dictionary, origin: Vector2i, kind: String) -> Vector2i:
	# A free blueprint may cover a future source/depot goal without covering a
	# current body. Keep worker-local stable goals across hauling cycles; reroute
	# only a statically illegal station or twelve ticks of real dynamic blockage.
	var key := kind + ":" + str(origin)
	var targets: Dictionary = worker["station_targets"]
	if worker["station_current_key"] != key:
		worker["station_current_key"] = key
		worker["station_blocked_ticks"] = 0
	var current: Vector2i = targets.get(key, origin)
	var has_current := targets.has(key)
	var statically_clear := _route_point_clear(current)
	if has_current and statically_clear:
		if _station_dynamic_clear(current, str(worker["id"]), false):
			worker["station_blocked_ticks"] = 0
			return current
		worker["station_blocked_ticks"] = int(worker["station_blocked_ticks"]) + 1
		if int(worker["station_blocked_ticks"]) < 12:
			return current
	var candidates: Array[Vector2i] = [origin]
	var directions := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]
	for distance: int in [36, 56, 80, 104]:
		for index: int in range(directions.size()):
			candidates.append(origin + directions[(index + int(worker["index"])) % directions.size()] * distance)
	for candidate: Vector2i in candidates:
		if _route_point_clear(candidate) and _station_dynamic_clear(candidate, str(worker["id"]), true):
			targets[key] = candidate
			worker["station_blocked_ticks"] = 0
			return candidate
	# A temporary fully occupied neighbourhood waits; do not teleport, synthesize
	# stock, or delete the legal building. Retry is bounded rather than per-frame.
	if has_current and statically_clear:
		worker["station_blocked_ticks"] = 0
		return current
	for candidate: Vector2i in candidates:
		if _route_point_clear(candidate):
			targets[key] = candidate
			worker["station_blocked_ticks"] = 0
			return candidate
	return origin


func _prepare_worker_soldier_grid_m84() -> void:
	m84_worker_soldier_grid.clear()
	m84_worker_soldier_grid_valid = false
	if _last_soldiers.size()<32: return
	for index: int in range(_last_soldiers.size()):
		var soldier: Dictionary = _last_soldiers[index]
		if soldier.get("movement_layer","GROUND")!="GROUND" or int(soldier.get("hp",0))<=0 or not bool(soldier.get("alive",true)): continue
		if typeof(soldier.get("position"))!=TYPE_VECTOR2I: m84_worker_soldier_grid.clear(); return
		var position: Vector2i = soldier.position
		var radius := int(soldier.get("radius",12))
		if radius<0 or radius>1024 or absi(position.x)>32768 or absi(position.y)>32768: m84_worker_soldier_grid.clear(); return
		var minimum := Vector2i(floori(float(position.x-radius)/WORKER_GRID_CELL_M84),floori(float(position.y-radius)/WORKER_GRID_CELL_M84))
		var maximum := Vector2i(floori(float(position.x+radius)/WORKER_GRID_CELL_M84),floori(float(position.y+radius)/WORKER_GRID_CELL_M84))
		for y: int in range(minimum.y,maximum.y+1):
			for x: int in range(minimum.x,maximum.x+1):
				var key := Vector2i(x,y)
				if not m84_worker_soldier_grid.has(key): m84_worker_soldier_grid[key] = []
				m84_worker_soldier_grid[key].append(index)
	m84_worker_soldier_grid_valid = true

func _station_dynamic_clear(point: Vector2i, worker_id: String, check_reservations: bool) -> bool:
	if not m84_worker_phase or not m84_worker_soldier_grid_valid or absi(point.x)>32768 or absi(point.y)>32768:
		return _station_dynamic_clear_uncached_m84(point,worker_id,check_reservations)
	var minimum := Vector2i(floori(float(point.x-WORKER_RADIUS)/WORKER_GRID_CELL_M84),floori(float(point.y-WORKER_RADIUS)/WORKER_GRID_CELL_M84))
	var maximum := Vector2i(floori(float(point.x+WORKER_RADIUS)/WORKER_GRID_CELL_M84),floori(float(point.y+WORKER_RADIUS)/WORKER_GRID_CELL_M84))
	var seen: Dictionary = {}
	for y: int in range(minimum.y,maximum.y+1):
		for x: int in range(minimum.x,maximum.x+1):
			for index: int in m84_worker_soldier_grid.get(Vector2i(x,y),[]):
				if seen.has(index): continue
				seen[index] = true
				var soldier: Dictionary = _last_soldiers[index]
				var separation := WORKER_RADIUS+int(soldier.get("radius",12))
				if Vector2(point).distance_squared_to(Vector2(soldier.position))<float(separation*separation): return false
	# These observations DO move/change reservation within the worker phase.
	# Keep their live sequential reads, not the phase-start worker positions.
	for other: Dictionary in _workers:
		if other.id==worker_id or int(other.hp)<=0: continue
		if Vector2(point).distance_squared_to(Vector2(other.position))<float(4*WORKER_RADIUS*WORKER_RADIUS): return false
		var key := str(other.get("station_current_key",""))
		var targets: Dictionary = other.get("station_targets",{})
		if check_reservations and targets.has(key) and Vector2(point).distance_squared_to(Vector2(targets[key]))<float(4*WORKER_RADIUS*WORKER_RADIUS): return false
	return true

func _station_dynamic_clear_uncached_m84(point: Vector2i, worker_id: String, check_reservations: bool) -> bool:
	for soldier: Dictionary in _last_soldiers:
		if soldier.get("movement_layer", "GROUND") != "GROUND": continue
		var separation := WORKER_RADIUS + int(soldier.get("radius", 12))
		if int(soldier.get("hp", 0)) > 0 and bool(soldier.get("alive", true)) and Vector2(point).distance_squared_to(Vector2(soldier["position"])) < float(separation * separation):
			return false
	for other: Dictionary in _workers:
		if other["id"] == worker_id or int(other["hp"]) <= 0:
			continue
		if Vector2(point).distance_squared_to(Vector2(other["position"])) < float(4 * WORKER_RADIUS * WORKER_RADIUS):
			return false
		var key := str(other.get("station_current_key", ""))
		var targets: Dictionary = other.get("station_targets", {})
		if check_reservations and targets.has(key) and Vector2(point).distance_squared_to(Vector2(targets[key])) < float(4 * WORKER_RADIUS * WORKER_RADIUS):
			return false
	return true


func _build_station(building: Dictionary, worker: Dictionary) -> Vector2i:
	var offset := int(building["radius"]) + 18
	var stations := [Vector2i(-offset, 0), Vector2i(0, -offset), Vector2i(0, offset), Vector2i(offset, 0), Vector2i(-offset, -20), Vector2i(-offset, 20)]
	var fallback: Vector2i = building["position"]
	var has_fallback := false
	for attempt: int in range(stations.size()):
		var candidate: Vector2i = building["position"] + stations[(int(worker["index"]) + attempt) % stations.size()]
		if _route_point_clear(candidate):
			if not has_fallback:
				fallback = candidate
				has_fallback = true
			if _station_dynamic_clear(candidate, str(worker["id"]), false): return candidate
	# Adjacent legal footprints may cover every cardinal station while leaving
	# diagonal access. Keep the original first choices, then search the same
	# bounded work ring rather than routing a worker inside the building body.
	var diagonal := floori(float(offset) / sqrt(2.0))
	var diagonal_stations := [Vector2i(-diagonal,-diagonal),Vector2i(diagonal,-diagonal),Vector2i(-diagonal,diagonal),Vector2i(diagonal,diagonal)]
	for attempt: int in range(diagonal_stations.size()):
		var candidate: Vector2i = building["position"] + diagonal_stations[(int(worker["index"]) + attempt) % diagonal_stations.size()]
		if _route_point_clear(candidate):
			if not has_fallback:
				fallback = candidate
				has_fallback = true
			if _station_dynamic_clear(candidate, str(worker["id"]), false): return candidate
	# If every legal station is temporarily occupied, collision movement waits
	# at a real work-ring goal. Never grant labour from inside the footprint.
	return fallback


func _first_blueprint(side: String) -> Dictionary:
	# Explicit paid orders outrank free integrated scaffolds. In particular a
	# destroyed last depot must be recoverable before a cosmetic/default tower.
	for building: Dictionary in _buildings:
		if building.side==side and int(building.hp)>0 and not building.complete and (building.building_type!="SITE_TOWER" or building.get("paid_rebuild_pending",false)) and _site_build_allowed(building):return building
	for building: Dictionary in _buildings:
		if building["side"] == side and int(building["hp"]) > 0 and not bool(building["complete"]) and _site_build_allowed(building):
			return building
	return {}

func _site_build_allowed(building: Dictionary) -> bool:
	if building.building_type!="SITE_TOWER":return true
	var site:=_find_site(str(building.get("site_id","")))
	return not site.is_empty() and site.owner==building.side and int(site.progress)>0


func _mineable_site(side: String) -> Dictionary:
	var source:=_usable_source(side,"MATERIAL")
	return {} if source.is_empty() else _find_site(str(source.site_id))


func _site_has_base(site: Dictionary, side: String) -> bool:
	if site["kind"] != "RESOURCE" or site["owner"] != side:
		return false
	for building: Dictionary in _buildings:
		if building["side"] == side and building["building_type"] == "BASE" and bool(building["complete"]) and int(building["hp"]) > 0 and Vector2(site["position"]).distance_to(Vector2(building["position"])) <= BASE_SITE_RADIUS:
			return true
	return false


func _owned_resource_near(position: Vector2i, side: String,essence: bool=false) -> Dictionary:
	for site: Dictionary in _sites:
		if site["kind"] == "RESOURCE" and (site.get("resource","")=="ESSENCE")==essence and site["owner"] == side and Vector2(position).distance_to(Vector2(site["position"])) <= BASE_SITE_RADIUS:
			return site
	return {}


func _nearest_base(position: Vector2i, side: String) -> Dictionary:
	var result := {}
	var distance := INF
	for building: Dictionary in _buildings:
		if building["side"] == side and building["building_type"] == "BASE" and bool(building["complete"]) and int(building["hp"]) > 0:
			var next_distance := Vector2(position).distance_to(Vector2(building["position"]))
			if next_distance < distance:
				distance = next_distance
				result = building
	return result


func _worker_count(side: String) -> int:
	var count := 0
	for worker: Dictionary in _workers:
		if worker["side"] == side and int(worker["hp"]) > 0:
			count += 1
	return count


func _find_site(id: String) -> Dictionary:
	for site: Dictionary in _sites:
		if site["id"] == id:
			return site
	return {}


func _find_building(id: String) -> Dictionary:
	for building: Dictionary in _buildings:
		if building["id"] == id:
			return building
	return {}


func _find_worker(id: String) -> Dictionary:
	for worker: Dictionary in _workers:
		if worker["id"] == id: return worker
	return {}


func _can_pay(side: String, cost: Dictionary) -> bool:
	return side in _economy and Currency.valid_gold_cost(cost) and int(_economy[side].stock.get(Currency.KEY,0)) >= int(cost.get(Currency.KEY,0))


func _pay(side: String, cost: Dictionary) -> void:
	assert(Currency.valid_gold_cost(cost), "Only canonical gold quotes may be paid")
	_economy[side].stock.MATERIAL = int(_economy[side].stock.MATERIAL) - int(cost.get(Currency.KEY,0))


func _refund(side: String, cost: Dictionary) -> void:
	# Paid tickets contain the exact gold amount, not today's catalog price.
	assert(Currency.valid_gold_cost(cost), "Only canonical paid gold may be refunded")
	_economy[side].stock.MATERIAL = int(_economy[side].stock.MATERIAL) + int(cost.get(Currency.KEY,0))


func _fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size():
		return false
	for field: String in fields:
		if not value.has(field):
			return false
	return true


func _reject(error: String) -> Dictionary:
	return {"accepted": false, "error": error, "reason": error}


func _accept(extra: Dictionary = {}) -> Dictionary:
	var result := {"accepted": true, "error": "", "reason": ""}
	result.merge(extra)
	return result

func advance_tick_internal_borrowed_m88(tick: int, borrowed_soldiers: Array, military_population: Dictionary, phase: String) -> Array:
	# INTERNAL synchronous Host-only contract. Body Dictionaries are read-only
	# only for this one _settle_current_military call. A distinct top container
	# permits real production APPEND without modifying caller membership.
	var prior_detached_soldiers: Array = _last_soldiers
	_last_soldiers = borrowed_soldiers.duplicate()
	for side: String in _sides:
		_military_population[side] = maxi(0,int(military_population.get(side,0)))
	var events: Array = _settle_current_military_m79(tick,phase)
	# No live references survive this API return or reach Combat admission.
	# The unchanged Host's final _sync_world publishes post-event deep facts.
	_last_soldiers = prior_detached_soldiers
	return events
