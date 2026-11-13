class_name GameSimulation
extends RefCounted

const FormationLibrary = preload("res://src/simulation/formation_library.gd")
const WorkerEconomy = preload("res://src/simulation/worker_economy.gd")
const UnitBodyResolver = preload("res://src/simulation/unit_body_resolver.gd")
const WarbandCatalog = preload("res://src/simulation/warband_catalog.gd")
const BaseObjectives = preload("res://src/simulation/base_objectives.gd")
const NeutralSpring = preload("res://src/simulation/neutral_spring.gd")
const BattleScenarioCatalog = preload("res://src/simulation/battle_scenario_catalog.gd")
const HeroOfficers = preload("res://src/simulation/hero_officers.gd")

const TICK_HZ := 20
const TICK_MS := 50
const DEFAULT_SEED := 1701

const ARENA_MIN_X := 80
const ARENA_MAX_X := 1200
const ARENA_MIN_Y := 80
const ARENA_MAX_Y := 640

const SIDE_PLAYER := "PLAYER"
const SIDE_AI := "AI"

const OUTCOME_ONGOING := "ONGOING"
const OUTCOME_PLAYER_VICTORY := "PLAYER_VICTORY"
const OUTCOME_PLAYER_DEFEAT := "PLAYER_DEFEAT"
const OUTCOME_DRAW := "DRAW"

const PHASE_PREPARATION := "PREPARATION"
const PHASE_BATTLE := "BATTLE"

const COMMAND_MOVE := "MOVE"
const COMMAND_FOCUS := "FOCUS"
const COMMAND_ATTACK_BASE := "ATTACK_BASE"
const COMMAND_RETREAT := "RETREAT"
const COMMAND_SET_FORMATION := "SET_FORMATION"
const COMMAND_SET_ECONOMY_TARGETS := "SET_ECONOMY_TARGETS"
const COMMAND_PRODUCTION_QUEUE_CHANGE := "PRODUCTION_QUEUE_CHANGE"
const COMMAND_START_BATTLE := "START_BATTLE"
const COMMAND_FORTIFY_BASE := "FORTIFY_BASE"

const INTENT_HOLD := "HOLD"
const INTENT_MOVE := "MOVE"
const INTENT_FOCUS := "FOCUS"
const INTENT_ATTACK_BASE := "ATTACK_BASE"
const INTENT_RETREAT := "RETREAT"

const SOLDIER_MAX_HP := 100
const SOLDIER_DAMAGE := 20
const SOLDIER_ATTACK_RANGE := 38
const SOLDIER_ATTACK_COOLDOWN_TICKS := 12
const SOLDIER_MOVE_STEP := 8
const SOLDIER_BODY_RADIUS := 10
const WARBAND_ANCHOR_STEP := 5
const AI_DECISION_INTERVAL_TICKS := 20
const FOCUS_ANCHOR_DISTANCE := 112
const MAX_PLAYER_WARBANDS := 6
const DEPLOYMENT_ANCHORS := [
	Vector2i(390, 360),
	Vector2i(420, 160),
	Vector2i(420, 560),
	Vector2i(540, 360),
]

var _seed: int = DEFAULT_SEED
var _tick: int = 0
var _outcome: String = OUTCOME_ONGOING
var _command_serial: int = 0
var _warbands: Dictionary = {}
var _soldiers: Dictionary = {}
var _economy: RefCounted
var _objectives: RefCounted
var _spring: RefCounted
var _heroes: RefCounted
var _scenario: Dictionary = {}
var _preparation_mode := false
var _phase := PHASE_BATTLE
var _battle_start_tick := 0
var _next_player_warband_serial := 1


func _init(scenario_seed: int = DEFAULT_SEED, preparation_mode: bool = false, scenario_id: String = BattleScenarioCatalog.TRAINING_ID) -> void:
	_preparation_mode = preparation_mode
	_scenario = BattleScenarioCatalog.get_scenario(scenario_id)
	assert(not _scenario.is_empty(), "Unsupported battle scenario: " + scenario_id)
	reset(scenario_seed)


func reset(scenario_seed: int = DEFAULT_SEED) -> void:
	_seed = scenario_seed
	_tick = 0
	_outcome = OUTCOME_ONGOING
	_command_serial = 0
	_warbands = {}
	_soldiers = {}
	_phase = PHASE_PREPARATION if _preparation_mode else PHASE_BATTLE
	_battle_start_tick = 0
	_next_player_warband_serial = 1
	_economy = WorkerEconomy.new(_scenario["local_offset"])
	_objectives = BaseObjectives.new(_scenario["base_positions"][SIDE_PLAYER], _scenario["base_positions"][SIDE_AI])
	_spring = NeutralSpring.new(_scenario["spring_position"])
	_heroes = HeroOfficers.new(bool(_scenario["heroes_enabled"]))

	_create_warband("player_alpha", SIDE_PLAYER, _scenario["spawn_anchors"]["player_alpha"], FormationLibrary.FACING_EAST)
	_create_warband("player_bravo", SIDE_PLAYER, _scenario["spawn_anchors"]["player_bravo"], FormationLibrary.FACING_EAST)
	_create_warband("ai_alpha", SIDE_AI, _scenario["spawn_anchors"]["ai_alpha"], FormationLibrary.FACING_WEST)
	_create_warband("ai_bravo", SIDE_AI, _scenario["spawn_anchors"]["ai_bravo"], FormationLibrary.FACING_WEST)


func advance_tick() -> bool:
	if _outcome != OUTCOME_ONGOING:
		return false
	_tick += 1
	if _phase == PHASE_BATTLE and (_tick - _battle_start_tick - 1) % AI_DECISION_INTERVAL_TICKS == 0:
		_run_ai_decisions()
	_update_warband_anchors()
	_update_member_movement()
	_maybe_complete_warband_deployment()
	if _phase == PHASE_BATTLE:
		_resolve_attacks()
		_update_outcome()
		if _outcome == OUTCOME_ONGOING:
			# Actual post-combat living members control the spring. Preparation
			# and the tick that ends an encounter cannot grant strategic credit.
			var settled := get_snapshot()
			_spring.advance_tick(_tick, settled["warbands"], settled["soldiers"])
	return true


func advance_ticks(count: int) -> int:
	var advanced := 0
	for _index: int in range(maxi(0, count)):
		if not advance_tick():
			break
		advanced += 1
	return advanced


func submit_command(command: Dictionary) -> Dictionary:
	return _apply_command(command, SIDE_PLAYER)


func get_arena_bounds() -> Rect2i:
	return _scenario["bounds"]


func get_outcome() -> String:
	return _outcome


func get_snapshot() -> Dictionary:
	var warband_snapshots: Array[Dictionary] = []
	for warband_id: String in _sorted_keys(_warbands):
		var warband: Dictionary = _warbands[warband_id]
		warband_snapshots.append({
			"id": warband["id"],
			"side": warband["side"],
			"owner": warband["side"],
			"anchor": warband["anchor"],
			"destination": warband["destination"],
			"home_anchor": warband["home_anchor"],
			"facing": warband["facing"],
			"formation": warband["formation"],
			"unit_type": warband["unit_type"],
			"focus_target_id": warband["focus_target_id"],
			"focus_base_id": warband["focus_base_id"],
			"intent": warband["intent"],
			"member_ids": (warband["member_ids"] as Array).duplicate(),
			"living_count": _living_count(warband_id),
		})

	var soldier_snapshots: Array[Dictionary] = []
	for soldier_id: String in _sorted_keys(_soldiers):
		var soldier: Dictionary = _soldiers[soldier_id]
		var is_alive: bool = soldier["hp"] > 0
		soldier_snapshots.append({
			"id": soldier["id"],
			"warband_id": soldier["warband_id"],
			"side": soldier["side"],
			"member_index": soldier["member_index"],
			"position": soldier["position"],
			"hp": soldier["hp"],
			"max_hp": soldier["max_hp"],
			"unit_type": soldier["unit_type"],
			"damage": soldier["damage"],
			"attack_range": soldier["attack_range"],
			"attack_cooldown_ticks": soldier["attack_cooldown_ticks"],
			"cooldown_ticks": soldier["cooldown_ticks"],
			"target_id": soldier["target_id"],
			"target_base_id": soldier["target_base_id"],
			"alive": is_alive,
			"incapacitated": not is_alive,
		})

	var heroes: Dictionary = _heroes.get_snapshot(soldier_snapshots)
	var bonuses := _observed_hero_bonuses(heroes)
	for soldier: Dictionary in soldier_snapshots:
		soldier["effective_damage"] = int(soldier["damage"]) + int(bonuses.get(soldier["warband_id"], 0)) if bool(soldier["alive"]) else 0
	var bounds := get_arena_bounds()
	return {
		"seed": _seed,
		"tick": _tick,
		"tick_ms": TICK_MS,
		"phase": _phase,
		"outcome": _outcome,
		"command_serial": _command_serial,
		"next_player_warband_serial": _next_player_warband_serial,
		"scenario": _scenario.duplicate(true),
		"heroes": heroes,
		"arena_bounds": {
			"min_x": bounds.position.x,
			"max_x": bounds.end.x,
			"min_y": bounds.position.y,
			"max_y": bounds.end.y,
		},
		"warbands": warband_snapshots,
		"soldiers": soldier_snapshots,
		"bases": _objectives.get_snapshot(),
		"economy": _economy.get_snapshot(),
		"strategic": _spring.get_snapshot(),
	}


func get_state_hash() -> String:
	var lines := PackedStringArray()
	lines.append("S|%d|%d|%s|%s|%d|%d|%d" % [_seed, _tick, _phase, _outcome, _command_serial, _battle_start_tick, _next_player_warband_serial])
	lines.append_array(_scenario_state_lines())
	for warband_id: String in _sorted_keys(_warbands):
		var warband: Dictionary = _warbands[warband_id]
		var anchor: Vector2i = warband["anchor"]
		var destination: Vector2i = warband["destination"]
		var home_anchor: Vector2i = warband["home_anchor"]
		lines.append("W|%s|%s|%d|%d|%d|%d|%d|%d|%s|%s|%s|%s|%s|%s|%d" % [
			warband["id"], warband["side"],
			anchor.x, anchor.y, destination.x, destination.y, home_anchor.x, home_anchor.y,
			warband["facing"], warband["formation"], warband["unit_type"], warband["focus_target_id"], warband["focus_base_id"], warband["intent"],
			warband["last_command_serial"],
		])
		for member_id: String in warband["member_ids"]:
			lines.append("M|%s|%s" % [warband_id, member_id])
	for soldier_id: String in _sorted_keys(_soldiers):
		var soldier: Dictionary = _soldiers[soldier_id]
		var position: Vector2i = soldier["position"]
		lines.append("U|%s|%s|%s|%d|%d|%d|%d|%d|%s|%d|%d|%d|%d|%s|%s" % [
			soldier["id"], soldier["warband_id"], soldier["side"], soldier["member_index"],
			position.x, position.y, soldier["hp"], soldier["max_hp"], soldier["unit_type"],
			soldier["damage"], soldier["attack_range"], soldier["attack_cooldown_ticks"], soldier["cooldown_ticks"], soldier["target_id"], soldier["target_base_id"],
		])
	for objective_line: String in _objectives.get_state_lines():
		lines.append(objective_line)
	for economy_line: String in _economy.get_state_lines():
		lines.append(economy_line)
	for strategic_line: String in _spring.get_state_lines():
		lines.append(strategic_line)
	lines.append_array(_heroes.get_state_lines())

	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update("\n".join(lines).to_utf8_buffer())
	return hashing.finish().hex_encode()


func _create_warband(warband_id: String, side: String, home_anchor: Vector2i, facing: String, unit_type: String = WarbandCatalog.HINGE_GUARD_TYPE) -> void:
	var member_ids: Array[String] = []
	var slots := FormationLibrary.get_world_slots(FormationLibrary.STEADY, home_anchor, facing)
	var stats: Dictionary = WarbandCatalog.stats_for_type(unit_type)
	for member_index: int in range(FormationLibrary.MEMBER_COUNT):
		var soldier_id := "%s_s%02d" % [warband_id, member_index]
		member_ids.append(soldier_id)
		_soldiers[soldier_id] = {
			"id": soldier_id,
			"warband_id": warband_id,
			"side": side,
			"member_index": member_index,
			"position": slots[member_index],
			"hp": int(stats["max_hp"]),
			"max_hp": int(stats["max_hp"]),
			"unit_type": unit_type,
			"damage": int(stats["damage"]),
			"attack_range": int(stats["attack_range"]),
			"attack_cooldown_ticks": int(stats["attack_cooldown_ticks"]),
			"cooldown_ticks": 0,
			"target_id": "",
			"target_base_id": "",
		}
	_warbands[warband_id] = {
		"id": warband_id,
		"side": side,
		"anchor": home_anchor,
		"destination": home_anchor,
		"home_anchor": home_anchor,
		"facing": facing,
		"formation": FormationLibrary.STEADY,
		"unit_type": unit_type,
		"focus_target_id": "",
		"focus_base_id": "",
		"intent": INTENT_HOLD,
		"member_ids": member_ids,
		"last_command_serial": 0,
	}


func _apply_command(command: Dictionary, issuer_side: String) -> Dictionary:
	if _outcome != OUTCOME_ONGOING:
		return _rejection("BATTLE_IS_TERMINAL")
	if typeof(command.get("type")) != TYPE_STRING:
		return _rejection("MISSING_COMMAND_TYPE")
	var command_type: String = command["type"]
	if command_type == COMMAND_FORTIFY_BASE:
		if command.size() != 1:
			return _rejection("INVALID_FORTIFY_COMMAND")
		if _phase != PHASE_BATTLE:
			return _rejection("FORTIFY_REQUIRES_BATTLE")
		var own_base_id: String = _objectives.get_base_id_for_side(issuer_side)
		var own_base: Dictionary = _objectives.get_base(own_base_id)
		if own_base.is_empty() or own_base["state"] != BaseObjectives.STATE_ACTIVE or int(own_base["hp"]) <= 0 or not _objectives.can_deploy(issuer_side):
			return _rejection("BASE_NOT_ACTIVE")
		if int(own_base["hp"]) >= int(own_base["max_hp"]):
			return _rejection("BASE_FULL_HP")
		if _spring.get_resonance(issuer_side) < NeutralSpring.FORTIFY_COST:
			return _rejection("INSUFFICIENT_RESONANCE")
		# All validation is complete before either authority changes. This is
		# synchronous: no tick or other command can intervene between the
		# stock preflight, fixed spend and bounded ACTIVE-only restoration.
		if not _spring.spend(issuer_side, NeutralSpring.FORTIFY_COST, _tick):
			return _rejection("INSUFFICIENT_RESONANCE")
		var restored_hp: int = _objectives.restore_active(own_base_id, NeutralSpring.FORTIFY_HP)
		_command_serial += 1
		return {"accepted": true, "error": "", "command_serial": _command_serial, "restored_hp": restored_hp, "cost": NeutralSpring.FORTIFY_COST}
	if command_type == COMMAND_SET_ECONOMY_TARGETS:
		if issuer_side != SIDE_PLAYER:
			return _rejection("ECONOMY_NOT_OWNED")
		if command.size() != 2 or typeof(command.get("changes")) != TYPE_ARRAY:
			return _rejection("INVALID_ECONOMY_CHANGES")
		var result: Dictionary = _economy.apply_target_deltas(command["changes"])
		if not bool(result.get("accepted", false)):
			return _rejection(str(result.get("reason", "INVALID_ECONOMY_CHANGES")))
		_command_serial += 1
		return {"accepted": true, "error": "", "command_serial": _command_serial}
	if command_type == COMMAND_PRODUCTION_QUEUE_CHANGE:
		if issuer_side != SIDE_PLAYER:
			return _rejection("PRODUCTION_NOT_OWNED")
		if command.size() != 2 or typeof(command.get("change")) != TYPE_DICTIONARY:
			return _rejection("INVALID_PRODUCTION_CHANGE")
		var production_change: Dictionary = command["change"]
		if (
			production_change.get("operation") == "ENQUEUE"
			and typeof(production_change.get("recipe_id")) == TYPE_STRING
			and not WarbandCatalog.recipe_for_id(str(production_change["recipe_id"])).is_empty()
			and not _objectives.can_deploy(SIDE_PLAYER)
		):
			return _rejection("BASE_SUPPRESSED")
		if (
			production_change.get("operation") == "ENQUEUE"
			and typeof(production_change.get("recipe_id")) == TYPE_STRING
			and not WarbandCatalog.recipe_for_id(str(production_change["recipe_id"])).is_empty()
			and _active_player_warband_count() + _queued_player_warband_count() >= MAX_PLAYER_WARBANDS
		):
			return _rejection("WARBAND_CAP")
		var production_result: Dictionary = _economy.apply_production_change(production_change)
		if not bool(production_result.get("accepted", false)):
			return _rejection(str(production_result.get("reason", "INVALID_PRODUCTION_CHANGE")))
		_command_serial += 1
		return {
			"accepted": true,
			"error": "",
			"command_serial": _command_serial,
			"queue_entry_id": str(production_result.get("queue_entry_id", "")),
		}
	if command_type == COMMAND_START_BATTLE:
		if issuer_side != SIDE_PLAYER:
			return _rejection("BATTLE_NOT_OWNED")
		if command.size() != 1:
			return _rejection("INVALID_START_BATTLE_COMMAND")
		if _phase != PHASE_PREPARATION:
			return _rejection("BATTLE_ALREADY_STARTED")
		_phase = PHASE_BATTLE
		_battle_start_tick = _tick
		_command_serial += 1
		return {"accepted": true, "error": "", "command_serial": _command_serial}
	if typeof(command.get("subject_id")) != TYPE_STRING:
		return _rejection("MISSING_WARBAND_SUBJECT")

	var subject_id: String = command["subject_id"]
	if command_type not in [COMMAND_MOVE, COMMAND_FOCUS, COMMAND_ATTACK_BASE, COMMAND_RETREAT, COMMAND_SET_FORMATION]:
		return _rejection("UNKNOWN_COMMAND")
	if not _warbands.has(subject_id):
		return _rejection("UNKNOWN_WARBAND_SUBJECT")

	var subject: Dictionary = _warbands[subject_id]
	if subject["side"] != issuer_side:
		return _rejection("SUBJECT_NOT_OWNED")
	if _living_count(subject_id) == 0:
		return _rejection("SUBJECT_INCAPACITATED")

	var validated_value: Variant = null
	match command_type:
		COMMAND_MOVE:
			if typeof(command.get("target_position")) != TYPE_VECTOR2I:
				return _rejection("INVALID_MOVE_TARGET")
			var target_position: Vector2i = command["target_position"]
			if not _is_in_arena(target_position):
				return _rejection("MOVE_TARGET_OUT_OF_BOUNDS")
			validated_value = target_position
		COMMAND_FOCUS:
			if typeof(command.get("target_warband_id")) != TYPE_STRING:
				return _rejection("INVALID_FOCUS_TARGET")
			var target_id: String = command["target_warband_id"]
			if not _warbands.has(target_id):
				return _rejection("UNKNOWN_FOCUS_TARGET")
			var target: Dictionary = _warbands[target_id]
			if target["side"] == subject["side"]:
				return _rejection("FOCUS_TARGET_NOT_ENEMY")
			if _living_count(target_id) == 0:
				return _rejection("FOCUS_TARGET_INCAPACITATED")
			validated_value = target_id
		COMMAND_ATTACK_BASE:
			if command.size() != 3 or typeof(command.get("target_base_id")) != TYPE_STRING:
				return _rejection("INVALID_BASE_TARGET")
			var target_base_id: String = command["target_base_id"]
			var target_base: Dictionary = _objectives.get_base(target_base_id)
			if target_base.is_empty():
				return _rejection("UNKNOWN_BASE_TARGET")
			if target_base["side"] == subject["side"]:
				return _rejection("BASE_TARGET_NOT_ENEMY")
			if target_base["state"] not in ["ACTIVE", "SUPPRESSED"]:
				return _rejection("BASE_TARGET_EVACUATED")
			validated_value = target_base_id
		COMMAND_SET_FORMATION:
			if typeof(command.get("formation")) != TYPE_STRING:
				return _rejection("INVALID_FORMATION")
			var formation: String = command["formation"]
			if not FormationLibrary.is_valid(formation):
				return _rejection("INVALID_FORMATION")
			validated_value = formation
		COMMAND_RETREAT:
			pass

	_command_serial += 1
	subject["last_command_serial"] = _command_serial
	if command_type != COMMAND_SET_FORMATION:
		_clear_member_targets(subject)
	match command_type:
		COMMAND_MOVE:
			subject["destination"] = validated_value
			subject["focus_target_id"] = ""
			subject["focus_base_id"] = ""
			subject["intent"] = INTENT_MOVE
		COMMAND_FOCUS:
			subject["focus_target_id"] = validated_value
			subject["focus_base_id"] = ""
			subject["intent"] = INTENT_FOCUS
		COMMAND_ATTACK_BASE:
			_set_siege_intent(subject, str(validated_value))
		COMMAND_RETREAT:
			subject["destination"] = subject["home_anchor"]
			subject["focus_target_id"] = ""
			subject["focus_base_id"] = ""
			subject["intent"] = INTENT_RETREAT
		COMMAND_SET_FORMATION:
			subject["formation"] = validated_value
	return {"accepted": true, "error": "", "command_serial": _command_serial}


func _clear_member_targets(warband: Dictionary) -> void:
	for soldier_id: String in warband["member_ids"]:
		var soldier: Dictionary = _soldiers[soldier_id]
		soldier["target_id"] = ""
		soldier["target_base_id"] = ""


func _set_siege_intent(warband: Dictionary, base_id: String) -> void:
	warband["focus_target_id"] = ""
	warband["focus_base_id"] = base_id
	warband["intent"] = INTENT_ATTACK_BASE


func _run_ai_decisions() -> void:
	var ai_base: Dictionary = _objectives.get_base(BaseObjectives.AI_BASE_ID)
	if (
		ai_base.get("state") == BaseObjectives.STATE_ACTIVE
		and int(ai_base.get("hp", 0)) > 0
		and int(ai_base.get("max_hp", 0)) - int(ai_base.get("hp", 0)) >= NeutralSpring.FORTIFY_HP
		and _spring.get_resonance(SIDE_AI) >= NeutralSpring.FORTIFY_COST
	):
		_apply_command({"type": COMMAND_FORTIFY_BASE}, SIDE_AI)
	var player_warband_ids: Array[String] = []
	for warband_id: String in _sorted_keys(_warbands):
		var warband: Dictionary = _warbands[warband_id]
		if warband["side"] == SIDE_PLAYER and _living_count(warband_id) > 0:
			player_warband_ids.append(warband_id)
	for ai_warband_id: String in _sorted_keys(_warbands):
		var ai_warband: Dictionary = _warbands[ai_warband_id]
		if ai_warband["side"] != SIDE_AI or _living_count(ai_warband_id) == 0:
			continue
		if player_warband_ids.is_empty():
			_apply_command({
				"type": COMMAND_ATTACK_BASE,
				"subject_id": ai_warband_id,
				"target_base_id": BaseObjectives.PLAYER_BASE_ID,
			}, SIDE_AI)
			continue
		var nearest_id := ""
		var nearest_distance := 0
		for player_warband_id: String in player_warband_ids:
			var player_warband: Dictionary = _warbands[player_warband_id]
			var distance := _distance_squared(ai_warband["anchor"], player_warband["anchor"])
			if nearest_id.is_empty() or distance < nearest_distance or (distance == nearest_distance and player_warband_id < nearest_id):
				nearest_id = player_warband_id
				nearest_distance = distance
		_apply_command({
			"type": COMMAND_FOCUS,
			"subject_id": ai_warband_id,
			"target_warband_id": nearest_id,
		}, SIDE_AI)


func _update_warband_anchors() -> void:
	for warband_id: String in _sorted_keys(_warbands):
		var warband: Dictionary = _warbands[warband_id]
		if _living_count(warband_id) == 0:
			continue
		var movement_target: Vector2i = warband["destination"]
		var should_move := false
		if warband["intent"] == INTENT_FOCUS:
			var focus_target_id: String = warband["focus_target_id"]
			if not _warbands.has(focus_target_id) or _living_count(focus_target_id) == 0:
				focus_target_id = _nearest_living_enemy_warband_id(warband) if _phase == PHASE_BATTLE and warband["side"] == SIDE_PLAYER else ""
				warband["focus_target_id"] = focus_target_id
				if focus_target_id.is_empty():
					if _phase == PHASE_BATTLE and warband["side"] == SIDE_PLAYER:
						_set_siege_intent(warband, BaseObjectives.AI_BASE_ID)
					else:
						warband["intent"] = INTENT_HOLD
						continue
		if warband["intent"] == INTENT_FOCUS:
			# A preparation focus is a future battle order, not a free march
			# toward an opponent that cannot yet fight back.
			if _phase == PHASE_PREPARATION:
				continue
			var focused_warband: Dictionary = _warbands[warband["focus_target_id"]]
			movement_target = focused_warband["anchor"]
			warband["destination"] = movement_target
			should_move = _chebyshev_distance(warband["anchor"], movement_target) > FOCUS_ANCHOR_DISTANCE
		elif warband["intent"] == INTENT_ATTACK_BASE:
			if _phase == PHASE_PREPARATION:
				continue
			var objective: Dictionary = _objectives.get_base(str(warband["focus_base_id"]))
			if objective.is_empty() or objective["state"] == "EVACUATED":
				warband["focus_base_id"] = ""
				warband["intent"] = INTENT_HOLD
				continue
			movement_target = objective["position"]
			warband["destination"] = movement_target
			should_move = _chebyshev_distance(warband["anchor"], movement_target) > FOCUS_ANCHOR_DISTANCE
		elif warband["intent"] in [INTENT_MOVE, INTENT_RETREAT]:
			should_move = warband["anchor"] != movement_target

		if should_move:
			var old_anchor: Vector2i = warband["anchor"]
			var new_anchor := _move_point_toward(old_anchor, movement_target, WARBAND_ANCHOR_STEP)
			warband["anchor"] = new_anchor
			warband["facing"] = _cardinal_facing(movement_target - old_anchor, warband["facing"])
			if new_anchor == movement_target and warband["intent"] in [INTENT_MOVE, INTENT_RETREAT]:
				warband["intent"] = INTENT_HOLD
		elif warband["intent"] in [INTENT_MOVE, INTENT_RETREAT]:
			warband["intent"] = INTENT_HOLD


func _update_member_movement() -> void:
	var bodies: Array[Dictionary] = []
	for warband_id: String in _sorted_keys(_warbands):
		var warband: Dictionary = _warbands[warband_id]
		var slots := FormationLibrary.get_world_slots(
			warband["formation"],
			warband["anchor"],
			warband["facing"]
		)
		for soldier_id: String in warband["member_ids"]:
			var soldier: Dictionary = _soldiers[soldier_id]
			if soldier["hp"] <= 0:
				soldier["target_id"] = ""
				soldier["target_base_id"] = ""
				continue
			soldier["cooldown_ticks"] = maxi(0, soldier["cooldown_ticks"] - 1)
			var member_index: int = soldier["member_index"]
			var movement_target: Vector2i = slots[member_index]
			var target_id := ""
			var target_base_id := ""
			if _phase == PHASE_BATTLE:
				if warband["intent"] == INTENT_ATTACK_BASE and not str(warband["focus_base_id"]).is_empty():
					# Siege is a warband order. Each actual member defends against
					# enemies in its own range before approaching the objective.
					target_id = _select_local_defense_target(soldier)
					if target_id.is_empty():
						var objective: Dictionary = _objectives.get_base(str(warband["focus_base_id"]))
						if not objective.is_empty() and objective["side"] != soldier["side"] and objective["state"] in ["ACTIVE", "SUPPRESSED"]:
							target_base_id = str(objective["id"])
				elif not str(warband["focus_target_id"]).is_empty():
					target_id = _select_soldier_target(soldier, warband["focus_target_id"])
				elif warband["side"] == SIDE_PLAYER and warband["intent"] in [INTENT_HOLD, INTENT_MOVE]:
					target_id = _select_local_defense_target(soldier)
			soldier["target_id"] = target_id
			soldier["target_base_id"] = target_base_id
			if not target_id.is_empty():
				var target: Dictionary = _soldiers[target_id]
				var attack_range := int(soldier["attack_range"])
				if _distance_squared(soldier["position"], target["position"]) > attack_range * attack_range:
					movement_target = target["position"]
				else:
					movement_target = soldier["position"]
			elif not target_base_id.is_empty():
				var objective: Dictionary = _objectives.get_base(target_base_id)
				var surface_range := int(soldier["attack_range"]) + int(objective["radius"])
				movement_target = objective["position"] if _distance_squared(soldier["position"], objective["position"]) > surface_range * surface_range else soldier["position"]
			bodies.append({
				"id": soldier_id,
				"position": soldier["position"],
				"desired": movement_target,
				"radius": SOLDIER_BODY_RADIUS,
				"active": true,
			})
	var worker_intents: Dictionary = _economy.get_movement_intents()
	var worker_snapshot: Dictionary = _economy.get_snapshot()
	for worker_value: Dictionary in worker_snapshot.get("workers", []):
		var worker_id: String = worker_value["id"]
		bodies.append({
			"id": worker_id,
			"position": worker_value["position"],
			"desired": worker_intents.get(worker_id, worker_value["position"]),
			"radius": WorkerEconomy.WORKER_RADIUS,
			"max_step": WorkerEconomy.WORKER_MOVE_STEP,
			"active": true,
		})
	bodies.append_array(_get_static_bodies())
	var resolved_positions: Dictionary = UnitBodyResolver.resolve(bodies, get_arena_bounds(), SOLDIER_MOVE_STEP)
	for body: Dictionary in bodies:
		var body_id: String = body["id"]
		if _soldiers.has(body_id):
			var moving_soldier: Dictionary = _soldiers[body_id]
			moving_soldier["position"] = resolved_positions[body_id]
	var resolved_workers: Dictionary = {}
	for worker_value: Dictionary in worker_snapshot.get("workers", []):
		var worker_id: String = worker_value["id"]
		resolved_workers[worker_id] = resolved_positions[worker_id]
	var soldier_bodies: Array[Dictionary] = []
	for soldier_id: String in _sorted_keys(_soldiers):
		var current_soldier: Dictionary = _soldiers[soldier_id]
		if int(current_soldier["hp"]) > 0:
			soldier_bodies.append({
				"position": current_soldier["position"],
				"radius": SOLDIER_BODY_RADIUS,
			})
	soldier_bodies.append_array(_get_static_bodies())
	_economy.advance_tick(resolved_workers, soldier_bodies)


func _maybe_complete_warband_deployment() -> void:
	if not _objectives.can_deploy(SIDE_PLAYER):
		return
	var ready: Dictionary = _economy.get_ready_warband_entry()
	if ready.is_empty() or _active_player_warband_count() >= MAX_PLAYER_WARBANDS:
		return
	var unit_type := str(ready.get("unit_type", ""))
	if int(ready.get("member_count", 0)) != FormationLibrary.MEMBER_COUNT or WarbandCatalog.stats_for_type(unit_type).is_empty():
		return
	var anchor := _find_legal_deployment_anchor()
	if anchor.x < 0:
		return
	var completion: Dictionary = _economy.complete_warband_deployment(str(ready["queue_entry_id"]))
	if not bool(completion.get("accepted", false)):
		return
	var warband_id := "player_recruit_%02d" % _next_player_warband_serial
	_next_player_warband_serial += 1
	_create_warband(warband_id, SIDE_PLAYER, anchor, FormationLibrary.FACING_EAST, unit_type)


func _find_legal_deployment_anchor() -> Vector2i:
	var occupied: Array[Dictionary] = []
	for soldier_id: String in _sorted_keys(_soldiers):
		var soldier: Dictionary = _soldiers[soldier_id]
		if int(soldier["hp"]) > 0:
			occupied.append({"position": soldier["position"], "radius": SOLDIER_BODY_RADIUS})
	var economy_snapshot: Dictionary = _economy.get_snapshot()
	for worker_value in economy_snapshot.get("workers", []):
		var worker: Dictionary = worker_value
		occupied.append({"position": worker["position"], "radius": WorkerEconomy.WORKER_RADIUS})
	occupied.append_array(_get_static_bodies())
	for anchor_value in _scenario["deployment_anchors"]:
		var anchor: Vector2i = anchor_value
		if _deployment_slots_are_clear(anchor, occupied):
			return anchor
	return Vector2i(-1, -1)


func _get_static_bodies() -> Array[Dictionary]:
	var bodies: Array[Dictionary] = _economy.get_static_bodies()
	bodies.append_array(_objectives.get_static_bodies())
	return bodies


func _deployment_slots_are_clear(anchor: Vector2i, occupied: Array[Dictionary]) -> bool:
	var slots := FormationLibrary.get_world_slots(FormationLibrary.STEADY, anchor, FormationLibrary.FACING_EAST)
	var bounds := get_arena_bounds()
	for slot: Vector2i in slots:
		if (
			slot.x - SOLDIER_BODY_RADIUS < bounds.position.x
			or slot.x + SOLDIER_BODY_RADIUS > bounds.end.x
			or slot.y - SOLDIER_BODY_RADIUS < bounds.position.y
			or slot.y + SOLDIER_BODY_RADIUS > bounds.end.y
		):
			return false
		for body: Dictionary in occupied:
			var combined_radius := SOLDIER_BODY_RADIUS + int(body["radius"])
			if _distance_squared(slot, body["position"]) < combined_radius * combined_radius:
				return false
	return true


func _active_player_warband_count() -> int:
	var count := 0
	for warband_id: String in _sorted_keys(_warbands):
		var warband: Dictionary = _warbands[warband_id]
		if warband["side"] == SIDE_PLAYER and _living_count(warband_id) > 0:
			count += 1
	return count


func _queued_player_warband_count() -> int:
	var count := 0
	var production: Dictionary = _economy.get_snapshot()["production"]
	for entry_value in production["entries"]:
		var entry: Dictionary = entry_value
		if not WarbandCatalog.recipe_for_id(str(entry["recipe_id"])).is_empty():
			count += 1
	return count


func _select_soldier_target(attacker: Dictionary, target_warband_id: String) -> String:
	if target_warband_id.is_empty() or not _warbands.has(target_warband_id):
		return ""
	var target_warband: Dictionary = _warbands[target_warband_id]
	if target_warband["side"] == attacker["side"]:
		return ""
	var nearest_id := ""
	var nearest_distance := 0
	for candidate_id: String in target_warband["member_ids"]:
		var candidate: Dictionary = _soldiers[candidate_id]
		if candidate["hp"] <= 0:
			continue
		var distance := _distance_squared(attacker["position"], candidate["position"])
		if (
			nearest_id.is_empty()
			or distance < nearest_distance
			or (distance == nearest_distance and candidate_id < nearest_id)
		):
			nearest_id = candidate_id
			nearest_distance = distance
	return nearest_id


func _select_local_defense_target(attacker: Dictionary) -> String:
	var nearest_id := ""
	var nearest_distance := 0
	var attack_range := int(attacker.get("attack_range", SOLDIER_ATTACK_RANGE))
	var range_squared := attack_range * attack_range
	for candidate_id: String in _sorted_keys(_soldiers):
		var candidate: Dictionary = _soldiers[candidate_id]
		if candidate["side"] == attacker["side"] or candidate["hp"] <= 0:
			continue
		var distance := _distance_squared(attacker["position"], candidate["position"])
		if distance > range_squared:
			continue
		if (
			nearest_id.is_empty()
			or distance < nearest_distance
			or (distance == nearest_distance and candidate_id < nearest_id)
		):
			nearest_id = candidate_id
			nearest_distance = distance
	return nearest_id


func _nearest_living_enemy_warband_id(subject: Dictionary) -> String:
	var nearest_id := ""
	var nearest_distance := 0
	for candidate_id: String in _sorted_keys(_warbands):
		var candidate: Dictionary = _warbands[candidate_id]
		if candidate["side"] == subject["side"] or _living_count(candidate_id) == 0:
			continue
		var distance := _distance_squared(subject["anchor"], candidate["anchor"])
		if (
			nearest_id.is_empty()
			or distance < nearest_distance
			or (distance == nearest_distance and candidate_id < nearest_id)
		):
			nearest_id = candidate_id
			nearest_distance = distance
	return nearest_id


func _resolve_attacks() -> void:
	var damage_events: Array[Dictionary] = []
	var bonuses := _observed_hero_bonuses(_heroes.get_snapshot(_soldiers.values()))
	for attacker_id: String in _sorted_keys(_soldiers):
		var attacker: Dictionary = _soldiers[attacker_id]
		if attacker["hp"] <= 0 or attacker["cooldown_ticks"] > 0:
			continue
		var target_id: String = attacker["target_id"]
		if not target_id.is_empty():
			if not _soldiers.has(target_id):
				continue
			var target: Dictionary = _soldiers[target_id]
			if target["hp"] <= 0 or target["side"] == attacker["side"]:
				continue
			var attack_range := int(attacker["attack_range"])
			if _distance_squared(attacker["position"], target["position"]) > attack_range * attack_range:
				continue
			damage_events.append({"attacker_id": attacker_id, "target_id": target_id, "target_kind": "SOLDIER", "damage": int(attacker["damage"]) + int(bonuses.get(attacker["warband_id"], 0))})
		else:
			var target_base_id: String = attacker["target_base_id"]
			var objective: Dictionary = _objectives.get_base(target_base_id)
			if objective.is_empty() or objective["state"] != "ACTIVE" or objective["side"] == attacker["side"]:
				continue
			var surface_range := int(attacker["attack_range"]) + int(objective["radius"])
			if _distance_squared(attacker["position"], objective["position"]) > surface_range * surface_range:
				continue
			damage_events.append({"attacker_id": attacker_id, "target_id": target_base_id, "target_kind": "BASE", "damage": int(attacker["damage"]) + int(bonuses.get(attacker["warband_id"], 0))})
		attacker["cooldown_ticks"] = int(attacker["attack_cooldown_ticks"])

	var lethal_transitions: Array[Dictionary] = []
	for event: Dictionary in damage_events:
		var attacker: Dictionary = _soldiers[event["attacker_id"]]
		if event["target_kind"] == "BASE":
			_objectives.apply_damage(str(event["target_id"]), int(event["damage"]), _tick)
		else:
			var target: Dictionary = _soldiers[event["target_id"]]
			var old_hp := int(target["hp"])
			target["hp"] = maxi(0, old_hp - int(event["damage"]))
			if old_hp > 0 and int(target["hp"]) == 0:
				lethal_transitions.append({"warband_id": attacker["warband_id"], "victim_id": target["id"], "victim_side": target["side"]})
	if _phase == PHASE_BATTLE and _outcome == OUTCOME_ONGOING:
		_heroes.settle_tick(_tick, _soldiers.values(), lethal_transitions)

	for soldier_id: String in _sorted_keys(_soldiers):
		var soldier: Dictionary = _soldiers[soldier_id]
		if soldier["hp"] <= 0:
			soldier["target_id"] = ""
			soldier["target_base_id"] = ""


func _update_outcome() -> void:
	# Army losses leave logistics running. Only the objective module can end
	# an encounter, after all simultaneous individual damage has settled.
	var snapshot := get_snapshot()
	_outcome = _objectives.advance_tick(_tick, snapshot["warbands"], snapshot["soldiers"])


func _living_count(warband_id: String) -> int:
	var living := 0
	var warband: Dictionary = _warbands[warband_id]
	for soldier_id: String in warband["member_ids"]:
		if (_soldiers[soldier_id] as Dictionary)["hp"] > 0:
			living += 1
	return living


func _is_in_arena(position: Vector2i) -> bool:
	var bounds := get_arena_bounds()
	return (
		position.x >= bounds.position.x
		and position.x <= bounds.end.x
		and position.y >= bounds.position.y
		and position.y <= bounds.end.y
	)


func _observed_hero_bonuses(heroes: Dictionary) -> Dictionary:
	var bonuses := {}
	for officer: Dictionary in heroes.get("officers", []):
		bonuses[officer["warband_id"]] = int(officer["damage_bonus"])
	return bonuses


func _scenario_state_lines() -> PackedStringArray:
	var bounds: Rect2i = _scenario["bounds"]
	var offset: Vector2i = _scenario["local_offset"]
	var spring: Vector2i = _scenario["spring_position"]
	var lines := PackedStringArray(["SCENARIO|%s|%d|%s|%d|%d|%d|%d|%d|%d|%d|%d|%s|%s|%d" % [
		_scenario["id"], _scenario["version"], _scenario["display_name"], bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y, offset.x, offset.y, spring.x, spring.y, str(_scenario["camera_max_zoom"]), str(_scenario["initial_zoom"]), int(_scenario["heroes_enabled"]),
	]])
	for side: String in [SIDE_AI, SIDE_PLAYER]:
		var position: Vector2i = _scenario["base_positions"][side]
		lines.append("SC_BASE|%s|%d|%d" % [side, position.x, position.y])
	for warband_id: String in _sorted_keys(_scenario["spawn_anchors"]):
		var position: Vector2i = _scenario["spawn_anchors"][warband_id]
		lines.append("SC_SPAWN|%s|%d|%d" % [warband_id, position.x, position.y])
	for field: String in ["deployment_anchors", "defense_anchors"]:
		var anchors: Array = _scenario[field]
		for index: int in range(anchors.size()):
			var position: Vector2i = anchors[index]
			lines.append("SC_ANCHOR|%s|%d|%d|%d" % [field, index, position.x, position.y])
	return lines


func _distance_squared(first: Vector2i, second: Vector2i) -> int:
	var delta := second - first
	return delta.x * delta.x + delta.y * delta.y


func _chebyshev_distance(first: Vector2i, second: Vector2i) -> int:
	var delta := second - first
	return maxi(absi(delta.x), absi(delta.y))


func _move_point_toward(current: Vector2i, target: Vector2i, step: int) -> Vector2i:
	var delta := target - current
	return current + Vector2i(
		clampi(delta.x, -step, step),
		clampi(delta.y, -step, step)
	)


func _cardinal_facing(delta: Vector2i, fallback: String) -> String:
	if delta == Vector2i.ZERO:
		return fallback
	if absi(delta.x) >= absi(delta.y):
		return FormationLibrary.FACING_EAST if delta.x >= 0 else FormationLibrary.FACING_WEST
	return FormationLibrary.FACING_SOUTH if delta.y >= 0 else FormationLibrary.FACING_NORTH


func _sorted_keys(source: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key: Variant in source.keys():
		keys.append(str(key))
	keys.sort()
	return keys


func _rejection(error: String) -> Dictionary:
	return {"accepted": false, "error": error}
