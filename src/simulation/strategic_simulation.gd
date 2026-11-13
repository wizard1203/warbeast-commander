class_name StrategicSimulation
extends RefCounted
## Fixed-tick authority for the additive strategic scenario. No node/input/LLM
## references: world and combat exchange only detached facts and ordered events.

const World = preload("res://src/simulation/strategic_world.gd")
const Combat = preload("res://src/simulation/strategic_combat.gd")
const Computer = preload("res://src/simulation/strategic_ai.gd")
const Scenarios = preload("res://src/simulation/battle_scenario_catalog.gd")
const HeroCatalog = preload("res://src/simulation/strategic_hero_catalog.gd")
const Difficulty = preload("res://src/simulation/strategic_ai_difficulty.gd")
const Matches = preload("res://src/simulation/strategic_match_catalog.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const FieldObjectives = preload("res://src/simulation/strategic_field_objectives.gd")
const MatchScores = preload("res://src/simulation/strategic_match_scores_m72.gd")
const TICK_MS := 50
const TICK_HZ := 20
const DEFAULT_SEED := 1701
const WORLD_COMMANDS := ["SET_ECONOMY_TARGETS", "SET_WORK_SITE", "SET_ESSENCE_SITE", "PLACE_BUILDING", "ENQUEUE_UNIT", "CANCEL_PRODUCTION", "CANCEL_CONSTRUCTION", "UPGRADE", "UPGRADE_BASE", "UPGRADE_TOWER", "REBUILD_SITE_DEFENSE"]
# Explicitly audited read-only subset: adding a World command must not silently
# certify that Combat's military rows and canonical hero roster remain fresh.
const M93_MILITARY_READONLY_ORDERS := ["SET_ECONOMY_TARGETS", "SET_WORK_SITE", "SET_ESSENCE_SITE", "PLACE_BUILDING", "ENQUEUE_UNIT", "CANCEL_PRODUCTION", "CANCEL_CONSTRUCTION", "UPGRADE", "UPGRADE_BASE", "UPGRADE_TOWER", "REBUILD_SITE_DEFENSE"]
const COMMAND_FIELDS := {
	"START_BATTLE": ["type"],
	"SET_MATCH_CONFIG": ["type", "config"],
	"SET_AI_DIFFICULTY": ["type", "difficulty_id"],
	"MOVE": ["type", "subject_id", "target_position"],
	"ATTACK_MOVE": ["type", "subject_id", "target_position"],
	"TYPE_ORDER": ["type", "subject_id", "unit_type", "order", "target_position"],
	"FOCUS": ["type", "subject_id", "target_warband_id"],
	"ATTACK_BASE": ["type", "subject_id", "target_base_id"],
	"RETREAT": ["type", "subject_id"],
	"STOP": ["type", "subject_id"],
	"SET_FORMATION": ["type", "subject_id", "formation"],
	"CREATE_WARBAND": ["type"],
	"MERGE_WARBANDS": ["type", "source_id", "target_id"],
	"DELETE_WARBAND": ["type", "subject_id"],
	"TRANSFER_UNITS": ["type", "unit_ids", "target_warband_id"],
	"UNIT_MOVE": ["type", "unit_id", "target_position"],
	"UNIT_STOP": ["type", "unit_id"],
	"UNIT_ATTACK": ["type", "unit_id", "target_id"],
	"HERO_SKILL": ["type", "unit_id", "skill_id", "target_position"],
	"SET_HERO_AUTOMATION": ["type", "unit_id", "auto_attack", "auto_skills"],
	"UPGRADE_HERO_SKILL": ["type", "unit_id", "skill_id"],
	"EQUIP_ITEM": ["type", "unit_id", "item_id"],
	"USE_POTION": ["type", "unit_id"],
	"USE_ITEM": ["type", "unit_id", "item_id"],
	"PICKUP_LOOT": ["type", "unit_id", "loot_id"],
	"SET_ECONOMY_TARGETS": ["type", "changes"],
	"SET_WORK_SITE": ["type", "site_id"],
	"SET_ESSENCE_SITE": ["type", "site_id"],
	"REBUILD_SITE_DEFENSE": ["type", "site_id"],
	"PLACE_BUILDING": ["type", "building_type", "position"],
	"ENQUEUE_UNIT": ["type", "building_id", "unit_type", "warband_id", "hero_archetype"],
	"BUY_ITEM": ["type", "unit_id", "item_id", "building_id"],
	"SELL_ITEM": ["type", "unit_id", "item_id", "building_id"],
	"CANCEL_PRODUCTION": ["type", "entry_id"],
	"CANCEL_CONSTRUCTION": ["type", "building_id"],
	"UPGRADE": ["type", "technology", "building_id"],
	"UPGRADE_BASE": ["type", "building_id"],
	"UPGRADE_TOWER": ["type", "building_id"],
	"AUTO_ENGAGE": ["type", "subject_id"],
	"AUTO_DEFEND": ["type", "subject_id"],
}

var _world: RefCounted
var _combat: RefCounted
var _computer: RefCounted
var _computers: Dictionary = {}
var _match_config: Dictionary = {}
var _match_result: Dictionary = {}
var _seed := DEFAULT_SEED
var _tick := 0
var _phase := "LOBBY"
var _outcome := "ONGOING"
var _command_serial := 0
var _ai_command_serial := 0
var _preparation := true
var _ai_difficulty := "STANDARD"
var _commands: Array[Dictionary] = []
var _field_objectives: RefCounted
var _match_scores: RefCounted
var _catalog_snapshot_m75: Dictionary = {}
var _m93_command_scope := false
var _m93_military_fresh := false
var _m93_avoided_syncs := 0


func _init(seed: int = DEFAULT_SEED, preparation_mode: bool = true, difficulty_id: String = "STANDARD") -> void:
	_preparation = preparation_mode
	_ai_difficulty = difficulty_id if Difficulty.is_valid(difficulty_id) else Difficulty.DEFAULT_SIM_ID
	reset(seed)
	# An explicitly non-preparing programmatic constructor is a START request,
	# using precisely the public admission path. Reset and UI defaults stay lobby.
	if not preparation_mode: submit_command({"type":"START_BATTLE"})


func reset(seed: int = DEFAULT_SEED) -> void:
	_m93_command_scope = false
	_m93_military_fresh = false
	_m93_avoided_syncs = 0
	_catalog_snapshot_m75.clear()
	if _match_config.is_empty():
		var request := Matches.default_request()
		request.participants[1].difficulty_id = _ai_difficulty
		_match_config = Matches.resolve(request).match_config
	_seed = seed
	_tick = 0
	_phase = "LOBBY"
	_outcome = "ONGOING"
	_command_serial = 0
	_ai_command_serial = 0
	_commands.clear()
	_world = World.new(seed, _match_config)
	_combat = Combat.new(seed, _match_config)
	_field_objectives = FieldObjectives.new(_match_config)
	_computers.clear()
	_computer = null
	for slot: Dictionary in _match_config.sides:
		if slot.controller != "AI": continue
		var controller: RefCounted = Computer.new(seed + int(slot.color_id) * 1009, slot.difficulty_id, slot.side_id, slot.faction_id)
		_computers[slot.side_id] = controller
		if _computer == null: _computer = controller
	_match_result = {"state":"ONGOING", "winner_side_id":"", "eliminated":[], "viable_sides":_side_ids(), "local_defeated":false}
	_sync_world()
	_sync_environment()
	_match_scores = MatchScores.new()
	_refresh_match_scores()


func get_match_catalog() -> Dictionary:
	return Matches.get_catalog().duplicate(true)


func get_hero_statistics() -> Dictionary:
	return _combat.get_hero_statistics()


func configure_lobby(request: Dictionary) -> Dictionary:
	if _phase != "LOBBY": return _reject("MATCH_CONFIG_LOCKED")
	var resolved: Dictionary = Matches.resolve(request)
	if not resolved.accepted: return resolved.duplicate(true)
	_match_config = resolved.match_config.duplicate(true)
	for slot: Dictionary in _match_config.sides:
		if slot.controller == "AI":
			_ai_difficulty = str(slot.difficulty_id)
			break
	reset(_seed)
	return {"accepted":true, "error":"", "match_config":_match_config.duplicate(true)}


func get_arena_bounds() -> Rect2i:
	return _world.get_arena_bounds()


func get_outcome() -> String:
	return _outcome


func advance_ticks(count: int) -> int:
	var advanced := 0
	for _index in range(maxi(0, count)):
		if not advance_tick():
			break
		advanced += 1
	return advanced


func advance_tick() -> bool:
	if _phase != "BATTLE" or _outcome != "ONGOING":
		return false
	_tick += 1
	_run_ai()
	var world_facts: Dictionary = _world.get_environment_snapshot()
	var obstacles := _obstacles_owned_m93(world_facts)
	# advance_tick immediately caches these same obstacles. Refresh terrain
	# without building that derived cache twice before any work can intervene.
	_combat.sync_terrain_m76(world_facts.get("terrain", []))
	var hits: Array = _combat.advance_owned_m93(_tick, _phase, obstacles, _world.get_technology())
	_combat.record_external_settlements(_world.damage_buildings(hits))
	_combat.record_external_settlements(_world.damage_workers(hits, _tick))
	_combat.record_external_settlements(_world.damage_workers(_combat.take_external_hits(), _tick))
	var military_bodies: Array = _combat._ordered_units()
	_world.sync_hero_roster(_combat.get_hero_roster())
	var events: Array = _world.advance_tick_internal_borrowed_m88(_tick, military_bodies, _combat.get_population(), _phase)
	# Construction/workers have moved during world settlement. The outlet check
	# and actual admission must use the same fresh environment, not last frame's
	# workers, or a paid queue entry could disappear without a soldier.
	_sync_environment()
	_combat.apply_settled_world_events_m93(events)
	_sync_world()
	_field_objectives.advance_tick(_tick, _phase, _outcome, _world, _combat)
	_combat._neutrals.settle(_world, _combat, _tick)
	if _phase == "BATTLE":
		_settle_outcome()
	if _tick % TICK_HZ == 0: _refresh_match_scores()
	return true


func _refresh_match_scores() -> void:
	var world: Dictionary = _world.get_snapshot()
	world["technology"] = _world.get_technology()
	_match_scores.observe(world,_combat.get_snapshot(),_tick,_match_config.sides)


func submit_command(command: Dictionary) -> Dictionary:
	if _outcome != "ONGOING":
		return _reject("BATTLE_IS_TERMINAL")
	var kind := str(command.get("type", ""))
	# Lobby rejection precedes all owning-domain validation, and cannot mutate
	# economic targets or replay state through a malformed gameplay payload.
	if _phase == "LOBBY" and kind not in ["START_BATTLE", "SET_MATCH_CONFIG", "SET_AI_DIFFICULTY"]:
		return _reject("MATCH_NOT_STARTED")
	if not COMMAND_FIELDS.has(kind):
		return _reject("UNKNOWN_COMMAND")
	for field: Variant in command.keys():
		if field not in COMMAND_FIELDS[kind]:
			return _reject("UNEXPECTED_FIELD")
	# Optional auto target and directional hero skill keys are allowed; all other
	# required data are checked by the owning domain before any side effects.
	if _phase == "BATTLE" and _slot("PLAYER").get("controller", "HUMAN") == "AI" and kind not in ["START_BATTLE", "SET_MATCH_CONFIG", "SET_AI_DIFFICULTY"]:
		return _reject("OBSERVER_ONLY")
	var result: Dictionary
	if kind == "START_BATTLE":
		if _phase != "LOBBY":
			return _reject("ALREADY_STARTED")
		_phase = "BATTLE"
		for controller: RefCounted in _computers.values(): controller.start_battle(_tick)
		result = {"accepted": true, "error": ""}
	elif kind == "SET_MATCH_CONFIG":
		if not command.get("config") is Dictionary: return _reject("INVALID_MATCH_CONFIG")
		return configure_lobby(command.config)
	elif kind == "SET_AI_DIFFICULTY":
		if _phase != "LOBBY":
			return _reject("AI_DIFFICULTY_LOCKED")
		var requested: Variant = command.get("difficulty_id")
		if not Difficulty.is_valid(requested):
			return _reject("INVALID_AI_DIFFICULTY")
		var setup: Dictionary = _match_config.request.duplicate(true)
		for participant: Dictionary in setup.participants:
			if participant.controller == "AI": participant.difficulty_id = requested
		var configured := configure_lobby(setup)
		if not configured.accepted: return configured
		_ai_difficulty = str(requested)
		result = {"accepted": true, "error": "", "difficulty_id": _ai_difficulty}
	elif kind in ["AUTO_ENGAGE", "AUTO_DEFEND"]:
		result = _macro(command)
	elif kind == "BUY_ITEM":
		result = _buy_item(command, "PLAYER")
	elif kind == "SELL_ITEM":
		result = _sell_item(command, "PLAYER")
	elif kind in WORLD_COMMANDS:
		if kind == "ENQUEUE_UNIT":
			var guard := _hero_queue_guard(command, "PLAYER")
			if not guard.accepted: return guard
		_sync_world()
		result = _world.apply_command(command, "PLAYER", _combat.get_population(), _combat.get_warband_ids("PLAYER"))
	else:
		result = _combat.apply_command(command, "PLAYER", _world.get_sites_snapshot_m79())
	result = _normalise(result)
	if bool(result.get("accepted", false)):
		_settle_external_worker_hits()
		_command_serial += 1
		_commands.append({"tick": _tick, "command": command.duplicate(true)})
		_sync_world()
	return result.duplicate(true)


func get_snapshot() -> Dictionary:
	var world_facts: Dictionary = _world.get_snapshot()
	var combat_facts: Dictionary = _combat.get_snapshot()
	# Combat's officer projection borrows these two body containers; all other
	# combat/world observations below are already newly detached allocations.
	for officer: Dictionary in combat_facts.get("heroes",{}).get("officers",[]):
		for field: String in ["attack_layers","last_skill_targets"]:
			if officer.has(field): officer[field] = officer[field].duplicate(true)
	var field_facts: Dictionary = _field_objectives.get_snapshot()
	var bounds := get_arena_bounds()
	if _catalog_snapshot_m75.is_empty():
		var base_stats: Dictionary = {}
		var release_units: Dictionary = {}
		var release_heroes: Array[String] = []
		for faction: String in Factions.IDS:
			for type: String in Factions.units_for(faction):
				if type in ["worker", "hero"]: continue
				release_units[type] = World.UNIT_CATALOG[type]
				base_stats[type] = Combat.stats_for_type(type)
			for archetype: String in Factions.heroes_for(faction):
				release_heroes.append(archetype)
		_catalog_snapshot_m75 = {"buildings": _world.get_building_catalog("PLAYER"), "buildings_by_side":_world.get_building_catalogs(), "tower_profiles":World.FactionTowers.catalog(), "units": release_units, "unit_base_stats":base_stats, "technologies": World.TECHNOLOGY_CATALOG, "hero_archetypes":release_heroes, "items":HeroCatalog.item_catalog(), "progression":World.get_progression_catalog(), "factions":Factions.get_catalog(), "field_objectives":FieldObjectives.CATALOG, "production_queue_limit":World.MAX_QUEUE}
		_catalog_snapshot_m75["economy"] = World.Economy.get_catalog()
	var result := {
		"outpost_mode":world_facts.get("outpost_mode",false),"building_slots":world_facts.get("building_slots",[]),"ruleset":world_facts.get("ruleset","LEGACY"),"currency_version":World.Currency.VERSION,"resource_keys":World.Currency.ACTIVE_KEYS.duplicate(),"resource_labels":{"MATERIAL":World.Currency.LABEL},
		"balance_version":World.Economy.VERSION,
		"seed": _seed, "tick": _tick, "tick_ms": TICK_MS,
		"phase": _phase, "outcome": _outcome, "command_serial": _command_serial,
		"scenario": Scenarios.get_scenario(Scenarios.STRATEGIC_ID),
		"match_settings": {"ai_difficulty": _ai_difficulty, "ai_policy_version": "difficulty-policy-v1", "map_id":_match_config.map_id, "participants":_match_config.request.participants.duplicate(true)},
		"match_config":_match_config.duplicate(true), "match_result":_match_result.duplicate(true), "sides":_match_config.sides.duplicate(true),
		"arena_bounds": {"min_x": bounds.position.x, "min_y": bounds.position.y, "max_x": bounds.end.x, "max_y": bounds.end.y},
		"warbands": combat_facts["warbands"], "soldiers": combat_facts["soldiers"],
		"type_cohorts_r12":combat_facts.get("type_cohorts_r12",{}),
		"combat_feedback_events":combat_facts.get("combat_feedback_events",[]),"hero_statistics":combat_facts.get("hero_statistics",{}),
		"hero_rework_r7":combat_facts.get("hero_rework_r7",{}),
		"match_scores":_match_scores.snapshot(),
		"heroes": combat_facts["heroes"], "sites": world_facts["sites"],
		"hero_quotes":world_facts["hero_quotes"],
		"neutral_camps":combat_facts.get("neutral_camps",[]), "neutral_loot":combat_facts.get("neutral_loot",[]), "neutral_events":combat_facts.get("neutral_events",[]),
		"field_objectives":field_facts.field_objectives, "field_objective_events":field_facts.field_objective_events,
		"buildings": world_facts["buildings"], "economy": world_facts["economy"],
		"workers": world_facts["workers"], "population": world_facts["population"],
		"population_upkeep":world_facts.get("population_upkeep",{}),
		"progression":world_facts["progression"],
		"resource_sources": world_facts.get("resource_sources", []),
		"terrain":world_facts.get("terrain", []), "technology_queues":world_facts.get("technology_queues", {}),
		"technology": _world.get_technology(), "bases": [],
		"catalog": _catalog_snapshot_m75.duplicate(true),
		"strategic": {"sites": world_facts["sites"].duplicate(true), "fog_of_war": false},
		"computer": _computer.get_snapshot(_tick) if _computer != null else {}, "computers":_controller_snapshots(),
	}
	for building: Dictionary in world_facts["buildings"]:
		if str(building.get("building_type", building.get("type", ""))) == "BASE":
			var base := building.duplicate(true)
			base["anchor"] = building["position"]
			base["state"] = "ACTIVE" if int(building.get("hp", 0)) > 0 else "EVACUATED"
			result["bases"].append(base)
	# Do not deep-copy the entire already-detached observation tree again.
	# Retained host/catalog inputs above are explicitly detached at their seam.
	return result


func get_state_hash() -> String:
	var state := {
		"version": "strategic-authority-v10", "seed": _seed, "tick": _tick,
		"ai_difficulty": _ai_difficulty, "ai_policy_version": "difficulty-policy-v1",
		"phase": _phase, "outcome": _outcome, "serial": _command_serial,
		"ai_serial": _ai_command_serial, "commands": _commands,
		"world": _world.get_state(), "combat": _combat.get_state(), "computers":_controller_states(), "match_config":_match_config, "match_result":_match_result,
		"field_objectives":_field_objectives.get_state(),
	}
	return var_to_bytes(state).hex_encode().sha256_text()


func _sync_world() -> void:
	if _m93_command_scope and _m93_military_fresh:
		_m93_avoided_syncs += 1
		return
	_m93_military_fresh = true
	_world.sync_hero_roster(_combat.get_hero_roster())
	if _combat.has_method("world_military_facts_m93"):
		_world.sync_owned_military_m79(_combat.world_military_facts_m93(), _combat.get_population())
	else:
		_world.sync_owned_military_m79(_combat.get_units_snapshot(), _combat.get_population())


func _sync_environment() -> void:
	var facts: Dictionary = _world.get_environment_snapshot()
	_combat.sync_environment_owned_m93(_obstacles_owned_m93(facts), facts.get("terrain", []))


func _side_ids() -> Array:
	var result: Array = []
	for slot: Dictionary in _match_config.sides: result.append(slot.side_id)
	return result


func _slot(side_id: String) -> Dictionary:
	for slot: Dictionary in _match_config.sides:
		if slot.side_id == side_id: return slot
	return {}


func _controller_snapshots() -> Dictionary:
	var result := {}
	for side: String in _computers: result[side] = _computers[side].get_snapshot(_tick)
	return result


func _controller_states() -> Dictionary:
	var result := {}
	for side: String in _computers: result[side] = _computers[side].get_state()
	return result


static func _obstacles(facts: Dictionary) -> Array:
	var result: Array = facts.get("buildings", []).duplicate(true)
	# Workers collide but are not structures or targets for ATTACK_BASE.
	for worker: Dictionary in facts.get("workers", []):
		if int(worker.get("hp", 0)) <= 0:
			continue
		var body := worker.duplicate(true)
		body["type"] = "WORKER_OBSTACLE"
		body["building_type"] = "WORKER_OBSTACLE"
		result.append(body)
	return result


static func _obstacles_owned_m93(facts: Dictionary) -> Array:
	# Host-only transfer of a fresh, already detached environment snapshot.
	# Public _obstacles/sync_environment retain their defensive-copy contracts.
	var result: Array = facts.get("buildings", [])
	for worker: Dictionary in facts.get("workers", []):
		if int(worker.get("hp", 0)) <= 0: continue
		worker["type"] = "WORKER_OBSTACLE"
		worker["building_type"] = "WORKER_OBSTACLE"
		result.append(worker)
	return result


func _macro(command: Dictionary) -> Dictionary:
	var selected := str(command.get("subject_id", ""))
	var own: Array = _combat.get_warband_ids("PLAYER")
	if not selected.is_empty() and selected not in own:
		return _reject("UNKNOWN_OR_FOREIGN_WARBAND")
	var defense: Dictionary = _world.get_defense_muster("PLAYER") if command["type"] == "AUTO_DEFEND" else {}
	if command["type"] == "AUTO_DEFEND" and defense.is_empty(): return _reject("NO_LEGAL_DEFENSE_MUSTER")
	var count := 0
	for warband: Dictionary in _combat.get_snapshot()["warbands"]:
		if warband.get("side") != "PLAYER" or bool(warband.get("reserve", false)) or int(warband.get("living_count", 0)) <= 0:
			continue
		if not selected.is_empty() and str(warband["id"]) != selected:
			continue
		var destination: Vector2i = defense.get("position", _slot("PLAYER").home)
		if command["type"] == "AUTO_ENGAGE":
			var distance := 9223372036854775807
			for site: Dictionary in _world.get_sites_snapshot_m79():
				if site.get("owner") == "PLAYER":
					continue
				var point: Vector2i = site["position"]
				var candidate: int = (point - Vector2i(warband["anchor"])).length_squared()
				if candidate < distance:
					distance = candidate
					destination = point
		var kind := "ATTACK_MOVE" if command["type"] == "AUTO_ENGAGE" else "MOVE"
		var result: Dictionary = _combat.apply_command({"type": kind, "subject_id": warband["id"], "target_position": destination}, "PLAYER", _world.get_sites_snapshot_m79())
		if not bool(result.get("accepted", false)):
			return _normalise(result)
		count += 1
	return {"accepted": count > 0, "error": "" if count > 0 else "NO_LIVING_ARMY", "warbands_commanded": count}


func _run_ai() -> void:
	var due:=false
	for controller:RefCounted in _computers.values():
		if controller.is_due(_tick,_phase):due=true;break
	if not due:return
	_m93_command_scope = true
	_m93_military_fresh = false
	var facts: Dictionary = _world.get_snapshot()
	var military: Dictionary = _combat.get_snapshot()
	# Public world is intentionally not fogged in this prototype. Include actual
	# physical troops in legal placement search, never hidden mutable references.
	facts["soldiers"] = military["soldiers"]
	facts["technology"] = _world.get_technology()
	facts["match_config"] = _match_config.duplicate(true)
	facts["field_objectives"] = _field_objectives.get_snapshot().field_objectives
	facts["catalog"] = {"units":World.UNIT_CATALOG, "buildings":_world.get_building_catalog("PLAYER"), "buildings_by_side":_world.get_building_catalogs(), "progression":World.get_progression_catalog()}
	for side: String in _computers:
		var controller: RefCounted = _computers[side]
		if not controller.is_due(_tick,_phase):continue
		facts["catalog"]["buildings"]=_world.get_building_catalog(side)
		var commands: Array = controller.plan(_tick, _phase, facts, military, _world.get_technology())
		# Preservation is trusted controller state, never a client command flag.
		# Revalidate the actual participant and living hero before allowing its
		# finite individual withdrawal to survive a simultaneous army order.
		_combat.configure_ai_hero_withdrawals(side, controller.get_hero_withdrawals(_tick))
		for command: Dictionary in commands.slice(0, Computer.MAX_COMMANDS):
			var before: Dictionary = _world.get_ai_receipt_snapshot_m79(side)
			var result := _apply_ai_command(command, side)
			controller.record_result(_tick, command, result, before, _world.get_ai_receipt_snapshot_m79(side))
			# Successful MOVE receipts can now establish protection before the
			# next army order. Failed/pending moves never establish a lease.
			_combat.configure_ai_hero_withdrawals(side, controller.get_hero_withdrawals(_tick))
	_m93_command_scope = false
	_m93_military_fresh = false


func _apply_ai_command(command: Dictionary, actor_side: String = "AI") -> Dictionary:
	# Side/provenance never come from the planner payload. The same host shape
	# whitelist and side-aware domain validators own every paid or combat effect.
	if _phase != "BATTLE" or _outcome != "ONGOING":
		return _reject("BATTLE_NOT_ACTIVE")
	if actor_side not in _side_ids(): return _reject("INVALID_ACTOR_SIDE")
	var kind := str(command.get("type", ""))
	if not COMMAND_FIELDS.has(kind) or kind in ["START_BATTLE", "SET_MATCH_CONFIG", "SET_AI_DIFFICULTY", "AUTO_ENGAGE", "AUTO_DEFEND"]:
		return _reject("UNKNOWN_COMMAND")
	for field: Variant in command.keys():
		if field not in COMMAND_FIELDS[kind]:
			return _reject("UNEXPECTED_FIELD")
	_sync_world()
	if kind not in M93_MILITARY_READONLY_ORDERS: _m93_military_fresh = false
	var result: Dictionary
	if kind == "BUY_ITEM":
		result = _buy_item(command, actor_side)
	elif kind == "SELL_ITEM":
		result = _sell_item(command, actor_side)
	elif kind in WORLD_COMMANDS:
		if kind == "ENQUEUE_UNIT":
			var guard := _hero_queue_guard(command, actor_side)
			if not guard.accepted: return guard
		result = _world.apply_command(command, actor_side, _combat.get_population(), _combat.get_warband_ids(actor_side))
	else:
		result = _combat.apply_command(command, actor_side, _world.get_sites_snapshot_m79())
	result = _normalise(result)
	# BUY/SELL may sync internally before granting/refunding an item. Their
	# pre-transaction read is not proof that the post-transaction roster is fresh.
	if kind not in M93_MILITARY_READONLY_ORDERS: _m93_military_fresh = false
	if bool(result.get("accepted", false)):
		_settle_external_worker_hits()
		_ai_command_serial += 1
		_sync_world()
	return result


func _settle_external_worker_hits() -> void:
	var hits: Array = _combat.take_external_hits()
	if hits.is_empty(): return
	_combat.record_external_settlements(_world.damage_workers(hits, _tick))
	# A subsequent command in the same tick must reject a just-killed worker;
	# the detached combat environment is not perpetual target authorization.
	_sync_environment()

func _hero_queue_guard(command: Dictionary, side: String) -> Dictionary:
	if command.has("hero_archetype") and (not command.hero_archetype is String or command.get("unit_type") != "hero"):
		return _reject("INVALID_HERO_ARCHETYPE")
	if command.get("unit_type") != "hero": return {"accepted":true}
	var archetype := str(command.get("hero_archetype", Factions.default_hero(_world.get_faction(side))))
	if archetype not in HeroCatalog.ARCHETYPES: return _reject("INVALID_HERO_ARCHETYPE")
	var quote: Dictionary = _world.get_hero_quote(side,archetype)
	return {"accepted":true} if quote.accepted else _reject(str(quote.error))

func _buy_item(command: Dictionary, side: String) -> Dictionary:
	var check: Dictionary = _combat.validate_item_purchase(command, side)
	if not check.get("accepted", false): return check
	_sync_world()
	var receipt: Dictionary = _world.apply_command(command, side, _combat.get_population(), _combat.get_warband_ids(side))
	if not receipt.get("accepted", false): return receipt
	# Synchronous validated domain receipt: no tick or competing command can
	# invalidate this admission between payment and the exactly-once grant.
	var granted: Dictionary = _combat.grant_paid_item(receipt)
	assert(granted.get("accepted", false), "Validated paid item receipt must be admitted")
	return receipt

func _sell_item(command: Dictionary, side: String) -> Dictionary:
	var check: Dictionary = _combat.validate_item_sale(command, side)
	if not check.get("accepted", false): return check
	_sync_world()
	var receipt: Dictionary = _world.apply_command(command, side, _combat.get_population(), _combat.get_warband_ids(side))
	if not receipt.get("accepted", false): return receipt
	var settled: Dictionary = _combat.settle_item_sale(receipt)
	assert(settled.get("accepted", false), "Validated item sale must settle exactly once")
	return receipt


func _settle_outcome() -> void:
	var viable := {}
	for side: String in _side_ids(): viable[side] = false
	# Query current living sides without copying full nested body snapshots.
	for side: String in _combat.get_living_body_sides_m87():
		if viable.has(side): viable[side] = true
	var world: Dictionary = _world.get_outcome_snapshot()
	for building: Dictionary in world["buildings"]:
		if str(building.get("building_type", building.get("type", ""))) == "BASE" and int(building.get("hp", 0)) > 0 and str(building.get("state", "")) == "COMPLETE":
			viable[str(building["side"])] = true
		# A surviving paid producer can still return a military body after its
		# owner's base/army dies. Do not freeze a retained normal deployment or
		# hero recall between payment and its lawful physical admission.
		if int(building.get("hp", 0)) <= 0 or not bool(building.get("complete", false)): continue
		var side: String = building.side
		var capacity: Dictionary = world.population[side]
		if int(capacity.used) + int(capacity.reserved) > int(capacity.maximum): continue
		for entry: Dictionary in building.get("queue", []):
			if entry.get("unit_type", "worker") != "worker" and World.UNIT_CATALOG.has(entry.get("unit_type", "")):
				viable[side] = true
				break
	var living: Array = []
	var eliminated: Array = []
	for side: String in _side_ids():
		if viable[side]: living.append(side)
		else: eliminated.append(side)
	_match_result = {"state":"ONGOING", "winner_side_id":"", "eliminated":eliminated, "viable_sides":living, "local_defeated":not viable.get("PLAYER", false)}
	if living.is_empty():
		_outcome = "DRAW"
		_match_result.state = "DRAW"
	elif living.size() == 1:
		_match_result.state = "VICTORY"
		_match_result.winner_side_id = living[0]
		_outcome = "PLAYER_VICTORY" if living[0] == "PLAYER" else "PLAYER_DEFEAT"


static func _normalise(result: Dictionary) -> Dictionary:
	var detached := result.duplicate(true)
	detached["accepted"] = bool(detached.get("accepted", detached.get("ok", false)))
	detached["error"] = "" if detached["accepted"] else str(detached.get("error", detached.get("reason", detached.get("code", "REJECTED"))))
	return detached


static func _reject(error: String) -> Dictionary:
	return {"accepted": false, "error": error}
