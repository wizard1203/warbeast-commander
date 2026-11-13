class_name GameSession
extends RefCounted

## Fixed-tick bridge between Godot's variable render loop and the authoritative
## simulation. Presentation code can submit semantic warband commands and read
## snapshots, but never receives a mutable simulation object.

const GameSimulation = preload("res://src/simulation/game_simulation.gd")
const CampCatalog = preload("res://src/simulation/camp_catalog.gd")
const BattleScenarioCatalog = preload("res://src/simulation/battle_scenario_catalog.gd")
const StrategicSimulation = preload("res://src/simulation/strategic_simulation.gd")
const AIDifficulty = preload("res://src/simulation/strategic_ai_difficulty.gd")

const DEFAULT_SEED := GameSimulation.DEFAULT_SEED
const FALLBACK_TICK_MS := 50
const FALLBACK_ARENA_BOUNDS := Rect2i(80, 80, 1120, 560)
## M6's published local macro layout. These are destinations, not rescue credit:
## members must physically arrive under the normal MOVE and occupancy rules.
const HOME_DEFENSE_LAYOUT_VERSION := "home-defense-v1"
const HOME_DEFENSE_ANCHORS: Array[Vector2i] = [
	Vector2i(330, 250),
	Vector2i(330, 470),
	Vector2i(426, 290),
	Vector2i(426, 410),
	Vector2i(214, 354),
	Vector2i(246, 276),
]

var _simulation: RefCounted
var _snapshot: Dictionary = {}
var _accumulator_microseconds := 0
var _preparation_mode := false
var _ai_difficulty := "STANDARD"
var _live_ticks_advanced := 0


func _init(seed: int = DEFAULT_SEED, preparation_mode: bool = false, scenario_id: String = BattleScenarioCatalog.TRAINING_ID, ai_difficulty: String = "STANDARD") -> void:
	_preparation_mode = preparation_mode
	_ai_difficulty = ai_difficulty if AIDifficulty.is_valid(ai_difficulty) else AIDifficulty.DEFAULT_SIM_ID
	_simulation = _create_simulation(seed, _preparation_mode, scenario_id, _ai_difficulty)
	_refresh_snapshot()


func update(render_delta_seconds: float) -> Dictionary:
	_advance_elapsed(render_delta_seconds)
	return get_snapshot()


func update_live(elapsed_seconds: float) -> Dictionary:
	# Retain debt instead of dropping active time; bound work so input gets
	# another frame even on overloaded hardware. Explicit update stays unbounded
	# for deterministic headless simulation and existing replay tools.
	advance_live(elapsed_seconds)
	return get_snapshot()


func advance_live(elapsed_seconds: float) -> bool:
	# Main already owns its last detached observation. A zero-tick render frame
	# need not allocate another complete copy of an unchanged large snapshot.
	# A 100ms batch monopolized multiple presentation frames. A short slice
	# yields after the current indivisible tick; debt remains authoritative and
	# explicit offline update() still processes every requested step unbounded.
	return _advance_elapsed(elapsed_seconds,2,25_000)>0


func live_timing() -> Dictionary:
	var tick_usec := int(_snapshot.get("tick_ms",FALLBACK_TICK_MS))*1000
	return {"backlog_ms":float(_accumulator_microseconds)/1000.0,"ticks_advanced":_live_ticks_advanced,"overloaded":_accumulator_microseconds>=tick_usec}


func _advance_elapsed(render_delta_seconds: float, max_ticks: int = -1, budget_usec: int = 0) -> int:
	# Lobby wall time must never become delayed economic/combat ticks after
	# Start. The authority also rejects advance_tick; discard the bridge's debt.
	if get_scenario_id() == BattleScenarioCatalog.STRATEGIC_ID and str(_snapshot.get("phase", "")) == "LOBBY":
		_accumulator_microseconds = 0
		_live_ticks_advanced = 0
		return 0
	if get_outcome() != "ONGOING":
		_live_ticks_advanced = 0
		return 0

	var tick_microseconds := int(_snapshot.get("tick_ms", FALLBACK_TICK_MS)) * 1000
	var elapsed_microseconds := maxi(roundi(maxf(render_delta_seconds, 0.0) * 1_000_000.0), 0)
	_accumulator_microseconds += elapsed_microseconds
	var ticks_advanced := 0
	var started_usec := Time.get_ticks_usec()
	while _accumulator_microseconds >= tick_microseconds:
		if max_ticks>0 and ticks_advanced>=max_ticks: break
		if ticks_advanced>0 and budget_usec>0 and Time.get_ticks_usec()-started_usec>=budget_usec: break
		if not _simulation.advance_tick():
			_accumulator_microseconds = 0
			break
		_accumulator_microseconds -= tick_microseconds
		ticks_advanced += 1
		if _simulation.get_outcome() != "ONGOING":
			_accumulator_microseconds = 0
			break

	if ticks_advanced > 0:
		_refresh_snapshot()
	_live_ticks_advanced = ticks_advanced
	return ticks_advanced


func reset(seed: int = DEFAULT_SEED) -> Dictionary:
	_accumulator_microseconds = 0
	_live_ticks_advanced = 0
	_simulation.reset(seed)
	_refresh_snapshot()
	return get_snapshot()


func get_scenario_id() -> String:
	return str(_snapshot.get("scenario", {}).get("id", BattleScenarioCatalog.TRAINING_ID))


func switch_scenario(scenario_id: String) -> Dictionary:
	# Explicit local new-match action. Validate before touching either the
	# authoritative host or the sub-tick accumulator; not a military/LLM command.
	if BattleScenarioCatalog.get_scenario(scenario_id).is_empty():
		return {"accepted": false, "error": "UNKNOWN_SCENARIO"}
	var seed := int(_snapshot.get("seed", DEFAULT_SEED))
	_preparation_mode = true
	_simulation = _create_simulation(seed, true, scenario_id, _ai_difficulty)
	_accumulator_microseconds = 0
	_live_ticks_advanced = 0
	_refresh_snapshot()
	return {"accepted": true, "error": "", "scenario_id": get_scenario_id()}


func submit_move(warband_id: String, target_position: Vector2i) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_MOVE,
		"subject_id": warband_id,
		"target_position": target_position,
	})


func submit_focus(warband_id: String, target_warband_id: String) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_FOCUS,
		"subject_id": warband_id,
		"target_warband_id": target_warband_id,
	})


func submit_attack_base(warband_id: String, target_base_id: String) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_ATTACK_BASE,
		"subject_id": warband_id,
		"target_base_id": target_base_id,
	})


func submit_auto_engage() -> Dictionary:
	if get_scenario_id() == BattleScenarioCatalog.STRATEGIC_ID:
		return submit_strategic({"type": "AUTO_ENGAGE"})
	# This is a local UI macro over warband-level FOCUS or ATTACK_BASE.
	# It does not introduce an LLM tool or issue commands to individual soldiers.
	if get_outcome() != "ONGOING":
		return {"accepted": false, "error": "BATTLE_IS_TERMINAL"}
	var warbands: Array = _snapshot.get("warbands", [])
	var player_warbands: Array[Dictionary] = []
	var enemy_warbands: Array[Dictionary] = []
	for value: Variant in warbands:
		var warband: Dictionary = value
		if int(warband.get("living_count", 0)) <= 0:
			continue
		if str(warband.get("side", "")) == GameSimulation.SIDE_PLAYER:
			player_warbands.append(warband)
		elif str(warband.get("side", "")) == GameSimulation.SIDE_AI:
			enemy_warbands.append(warband)
	var enemy_base_id := ""
	for base: Dictionary in _snapshot.get("bases", []):
		if base["side"] == GameSimulation.SIDE_AI and base["state"] in ["ACTIVE", "SUPPRESSED"]:
			enemy_base_id = str(base["id"])
	if player_warbands.is_empty() or (enemy_warbands.is_empty() and enemy_base_id.is_empty()):
		return {"accepted": false, "error": "NO_ENGAGEMENT_TARGET"}

	var commanded := 0
	for warband: Dictionary in player_warbands:
		var anchor: Vector2i = warband["anchor"]
		var nearest_id := ""
		var nearest_distance := 9223372036854775807
		for enemy: Dictionary in enemy_warbands:
			var enemy_anchor: Vector2i = enemy["anchor"]
			var dx := anchor.x - enemy_anchor.x
			var dy := anchor.y - enemy_anchor.y
			var distance := dx * dx + dy * dy
			var enemy_id := str(enemy["id"])
			if distance < nearest_distance or (distance == nearest_distance and enemy_id < nearest_id):
				nearest_distance = distance
				nearest_id = enemy_id
		var command := {
			"type": GameSimulation.COMMAND_FOCUS,
			"subject_id": str(warband["id"]),
			"target_warband_id": nearest_id,
		}
		if enemy_warbands.is_empty():
			command = {
				"type": GameSimulation.COMMAND_ATTACK_BASE,
				"subject_id": str(warband["id"]),
				"target_base_id": enemy_base_id,
			}
		var result: Dictionary = _simulation.submit_command(command)
		if not bool(result.get("accepted", false)):
			_refresh_snapshot()
			return result.duplicate(true)
		commanded += 1
	_refresh_snapshot()
	return {"accepted": true, "error": "", "warbands_commanded": commanded}


func submit_retreat(warband_id: String) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_RETREAT,
		"subject_id": warband_id,
	})


func submit_auto_defend() -> Dictionary:
	if get_scenario_id() == BattleScenarioCatalog.STRATEGIC_ID:
		return submit_strategic({"type": "AUTO_DEFEND"})
	# A local macro over the existing warband commands, not a new model tool.
	# Read one snapshot and preflight the complete roster before changing intent.
	if get_outcome() != "ONGOING":
		return {"accepted": false, "error": "BATTLE_IS_TERMINAL"}
	var own_base_available := false
	for base: Dictionary in _snapshot.get("bases", []):
		if base.get("side") == GameSimulation.SIDE_PLAYER and base.get("state") in ["ACTIVE", "SUPPRESSED"]:
			own_base_available = true
			break
	if not own_base_available:
		return {"accepted": false, "error": "NO_DEFENSE_OBJECTIVE"}
	var defenders: Array[String] = []
	for warband: Dictionary in _snapshot.get("warbands", []):
		if warband.get("side") == GameSimulation.SIDE_PLAYER and int(warband.get("living_count", 0)) > 0:
			defenders.append(str(warband["id"]))
	defenders.sort()
	if defenders.is_empty():
		return {"accepted": false, "error": "NO_DEFENDERS"}
	var defense_anchors: Array = _snapshot.get("scenario", {}).get("defense_anchors", HOME_DEFENSE_ANCHORS)
	if defenders.size() > defense_anchors.size():
		return {"accepted": false, "error": "DEFENSE_CAPACITY_EXCEEDED"}

	var commanded := 0
	for index: int in range(defenders.size()):
		var formation_result: Dictionary = _simulation.submit_command({
			"type": GameSimulation.COMMAND_SET_FORMATION,
			"subject_id": defenders[index],
			"formation": "STEADY",
		})
		if not bool(formation_result.get("accepted", false)):
			_refresh_snapshot()
			return formation_result.duplicate(true)
		var move_result: Dictionary = _simulation.submit_command({
			"type": GameSimulation.COMMAND_MOVE,
			"subject_id": defenders[index],
			"target_position": defense_anchors[index],
		})
		if not bool(move_result.get("accepted", false)):
			_refresh_snapshot()
			return move_result.duplicate(true)
		commanded += 1
	# No tick runs between submissions; only intent and command serials change.
	_refresh_snapshot()
	var layout_version := HOME_DEFENSE_LAYOUT_VERSION if get_scenario_id() == BattleScenarioCatalog.TRAINING_ID else "home-defense-frontier-v1"
	return {"accepted": true, "error": "", "warbands_commanded": commanded, "layout_version": layout_version}


func submit_formation(warband_id: String, formation: String) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_SET_FORMATION,
		"subject_id": warband_id,
		"formation": formation,
	})


func submit_economy_change(role: String, delta: int) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_SET_ECONOMY_TARGETS,
		"changes": [{"role": role, "delta": delta}],
	})


func submit_economy_transfer(from_role: String, to_role: String) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_SET_ECONOMY_TARGETS,
		"changes": [
			{"role": from_role, "delta": -1},
			{"role": to_role, "delta": 1},
		],
	})


func submit_enqueue_worker() -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_PRODUCTION_QUEUE_CHANGE,
		"change": {
			"operation": "ENQUEUE",
			"recipe_id": "recipe:worker:v1",
			"quantity": 1,
		},
	})


func submit_enqueue_warband(recipe_id: String) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_PRODUCTION_QUEUE_CHANGE,
		"change": {
			"operation": "ENQUEUE",
			"recipe_id": recipe_id,
			"quantity": 1,
		},
	})


func submit_enqueue_workshop() -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_PRODUCTION_QUEUE_CHANGE,
		"change": {
			"operation": "ENQUEUE",
			"recipe_id": CampCatalog.WORKSHOP_RECIPE_ID,
			"quantity": 1,
			"slot_id": CampCatalog.WORKSHOP_SLOT_ID,
		},
	})


func submit_cancel_worker_entry(queue_entry_id: String) -> Dictionary:
	return submit_cancel_production_entry(queue_entry_id)


func submit_cancel_production_entry(queue_entry_id: String) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_PRODUCTION_QUEUE_CHANGE,
		"change": {
			"operation": "CANCEL",
			"queue_entry_id": queue_entry_id,
		},
	})


func submit_reorder_worker_entry(queue_entry_id: String, target_index: int) -> Dictionary:
	return submit_reorder_production_entry(queue_entry_id, target_index)


func submit_reorder_production_entry(queue_entry_id: String, target_index: int) -> Dictionary:
	return _submit({
		"type": GameSimulation.COMMAND_PRODUCTION_QUEUE_CHANGE,
		"change": {
			"operation": "REORDER",
			"queue_entry_id": queue_entry_id,
			"target_index": target_index,
		},
	})


func submit_start_battle() -> Dictionary:
	return _submit({"type": GameSimulation.COMMAND_START_BATTLE})


func get_match_catalog() -> Dictionary:
	if get_scenario_id() != BattleScenarioCatalog.STRATEGIC_ID:
		return {}
	return _simulation.get_match_catalog().duplicate(true)


func configure_lobby(settings: Dictionary) -> Dictionary:
	if get_scenario_id() != BattleScenarioCatalog.STRATEGIC_ID:
		return {"accepted": false, "error": "NOT_STRATEGIC_SCENARIO"}
	var result: Dictionary = _simulation.configure_lobby(settings.duplicate(true))
	if bool(result.get("accepted", false)):
		_accumulator_microseconds = 0
		_live_ticks_advanced = 0
		_refresh_snapshot()
		_ai_difficulty = str(_snapshot.get("match_settings", {}).get("ai_difficulty", _ai_difficulty))
	return result.duplicate(true)


func start_match() -> Dictionary:
	if get_scenario_id() != BattleScenarioCatalog.STRATEGIC_ID:
		return {"accepted": false, "error": "NOT_STRATEGIC_SCENARIO"}
	return submit_start_battle()


func submit_fortify_base() -> Dictionary:
	return _submit({"type": GameSimulation.COMMAND_FORTIFY_BASE})


func get_snapshot() -> Dictionary:
	# A deep copy prevents an accidental UI mutation from crossing the seam even
	# if a later simulation optimization begins caching its snapshot dictionary.
	return _snapshot.duplicate(true)


func get_state_hash() -> String:
	# An on-demand diagnostic read, not an expensive per-frame HUD field.
	return str(_simulation.get_state_hash())


func get_outcome() -> String:
	return str(_snapshot.get("outcome", "ONGOING"))


func get_arena_bounds() -> Rect2i:
	var value: Variant = _snapshot.get("arena_bounds", {})
	if value is Dictionary:
		var bounds := value as Dictionary
		var min_x := int(bounds.get("min_x", FALLBACK_ARENA_BOUNDS.position.x))
		var min_y := int(bounds.get("min_y", FALLBACK_ARENA_BOUNDS.position.y))
		var max_x := int(bounds.get("max_x", FALLBACK_ARENA_BOUNDS.end.x))
		var max_y := int(bounds.get("max_y", FALLBACK_ARENA_BOUNDS.end.y))
		if max_x > min_x and max_y > min_y:
			return Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)
	return FALLBACK_ARENA_BOUNDS


func get_interpolation_alpha() -> float:
	var tick_microseconds := int(_snapshot.get("tick_ms", FALLBACK_TICK_MS)) * 1000
	if tick_microseconds <= 0 or get_outcome() != "ONGOING" or str(_snapshot.get("phase", "")) == "LOBBY":
		return 1.0
	return clampf(float(_accumulator_microseconds) / float(tick_microseconds), 0.0, 1.0)


func _submit(command: Dictionary) -> Dictionary:
	# This session is the local human seam, not the host's trusted AI seam.
	# All-AI demos/observer matches may inspect and navigate but cannot send
	# accidental human orders as the PLAYER computer's identity.
	if get_scenario_id() == BattleScenarioCatalog.STRATEGIC_ID and command.get("type") not in ["START_BATTLE", "SET_MATCH_CONFIG", "SET_AI_DIFFICULTY"]:
		for side: Dictionary in _snapshot.get("match_config", {}).get("sides", []):
			if side.get("side_id") == "PLAYER" and side.get("controller") == "AI":
				return {"accepted": false, "error": "OBSERVER_ONLY"}
	var result: Dictionary = _simulation.submit_command(command)
	if bool(result.get("accepted", false)) and command.get("type") in ["START_BATTLE", "SET_MATCH_CONFIG"]:
		_accumulator_microseconds = 0
		_live_ticks_advanced = 0
	_refresh_snapshot()
	return result.duplicate(true)


func _refresh_snapshot() -> void:
	# Both simulation authorities already return detached observations. Retain
	# one internal copy, while get_snapshot still detaches every external read.
	_snapshot = _simulation.get_snapshot()


func submit_strategic(command: Dictionary) -> Dictionary:
	if get_scenario_id() != BattleScenarioCatalog.STRATEGIC_ID:
		return {"accepted": false, "error": "NOT_STRATEGIC_SCENARIO"}
	var result := _submit(command.duplicate(true))
	if result.get("accepted", false) and command.get("type") == "SET_AI_DIFFICULTY":
		_ai_difficulty = str(_snapshot.get("match_settings", {}).get("ai_difficulty", _ai_difficulty))
	return result


static func _create_simulation(seed: int, preparation_mode: bool, scenario_id: String, ai_difficulty: String = "STANDARD") -> RefCounted:
	if scenario_id == BattleScenarioCatalog.STRATEGIC_ID:
		return StrategicSimulation.new(seed, preparation_mode, ai_difficulty)
	return GameSimulation.new(seed, preparation_mode, scenario_id)
