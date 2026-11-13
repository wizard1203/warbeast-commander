class_name BaseObjectives
extends RefCounted
## Fixed M5 command beasts. Soldiers and rendering remain outside this module.

const SIDE_PLAYER := "PLAYER"
const SIDE_AI := "AI"
const PLAYER_BASE_ID := "base:player:v1"
const AI_BASE_ID := "base:ai:v1"
const PLAYER_POSITION := Vector2i(330, 360)
const AI_POSITION := Vector2i(950, 360)
const BODY_RADIUS := 32
const MAX_HP := 1600
const CONTROL_RADIUS := 150
const SUPPRESSION_TICKS := 600
const RESCUE_TICKS := 160
const RESCUE_HP := 320
const STATE_ACTIVE := "ACTIVE"
const STATE_SUPPRESSED := "SUPPRESSED"
const STATE_EVACUATED := "EVACUATED"
const OUTCOME_ONGOING := "ONGOING"
const OUTCOME_PLAYER_VICTORY := "PLAYER_VICTORY"
const OUTCOME_PLAYER_DEFEAT := "PLAYER_DEFEAT"
const OUTCOME_DRAW := "DRAW"

var _bases: Dictionary = {}
var _player_position: Vector2i = PLAYER_POSITION
var _ai_position: Vector2i = AI_POSITION


func _init(player_position: Vector2i = PLAYER_POSITION, ai_position: Vector2i = AI_POSITION) -> void:
	_player_position = player_position
	_ai_position = ai_position
	reset()


func reset() -> void:
	_bases = {
		PLAYER_BASE_ID: _initial_base(PLAYER_BASE_ID, SIDE_PLAYER, _player_position),
		AI_BASE_ID: _initial_base(AI_BASE_ID, SIDE_AI, _ai_position),
	}


func get_base_id_for_side(side: String) -> String:
	match side:
		SIDE_PLAYER:
			return PLAYER_BASE_ID
		SIDE_AI:
			return AI_BASE_ID
		_:
			return ""


func get_base(base_id: String) -> Dictionary:
	return (_bases[base_id] as Dictionary).duplicate(true) if _bases.has(base_id) else {}


func get_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for base_id: String in _sorted_base_ids():
		result.append(get_base(base_id))
	return result


func get_static_bodies() -> Array[Dictionary]:
	var bodies: Array[Dictionary] = []
	for base_id: String in _sorted_base_ids():
		var base: Dictionary = _bases[base_id]
		bodies.append({
			"id": base_id,
			"position": base["position"],
			"desired": base["position"],
			"radius": base["radius"],
			"max_step": 0,
			"active": true,
		})
	return bodies


func can_deploy(side: String) -> bool:
	var base_id := get_base_id_for_side(side)
	return not base_id.is_empty() and _get_outcome() == OUTCOME_ONGOING and _bases[base_id]["state"] == STATE_ACTIVE


func apply_damage(base_id: String, amount: int, tick: int) -> bool:
	if not _bases.has(base_id) or amount <= 0 or tick < 0 or _get_outcome() != OUTCOME_ONGOING:
		return false
	var base: Dictionary = _bases[base_id]
	if base["state"] != STATE_ACTIVE:
		return false
	base["hp"] = maxi(0, int(base["hp"]) - amount)
	if int(base["hp"]) == 0:
		base["state"] = STATE_SUPPRESSED
		base["suppressed_tick"] = tick
		base["evacuation_deadline_tick"] = tick + SUPPRESSION_TICKS
		base["rescue_progress_ticks"] = 0
		base["rescue_eligible_warbands"] = 0
		base["rescue_contested"] = false
	return true


func restore_active(base_id: String, amount: int) -> int:
	# Resonance is owned by the host's separate ledger. This method only
	# restores existing ACTIVE HP, and never changes M5 rescue availability,
	# suppression state or any evacuation/rescue timing fields.
	if not _bases.has(base_id) or amount <= 0 or _get_outcome() != OUTCOME_ONGOING:
		return 0
	var base: Dictionary = _bases[base_id]
	if base["state"] != STATE_ACTIVE or int(base["hp"]) <= 0:
		return 0
	var restored := mini(amount, maxi(0, int(base["max_hp"]) - int(base["hp"])))
	base["hp"] = int(base["hp"]) + restored
	return restored


func advance_tick(tick: int, warband_snapshots: Array, soldier_snapshots: Array) -> String:
	var previous_outcome := _get_outcome()
	if previous_outcome != OUTCOME_ONGOING or tick < 0:
		return previous_outcome
	var soldiers_by_id := {}
	for soldier: Dictionary in soldier_snapshots:
		soldiers_by_id[str(soldier["id"])] = soldier
	# Advance every rescue before evaluating either deadline. This keeps a last-
	# tick rescue legal and gives simultaneous expiries a symmetric DRAW result.
	for base_id: String in _sorted_base_ids():
		var base: Dictionary = _bases[base_id]
		if base["state"] != STATE_SUPPRESSED:
			continue
		var contested := _is_contested(base, soldier_snapshots)
		var eligible := _eligible_warband_count(base, warband_snapshots, soldiers_by_id)
		base["rescue_contested"] = contested
		base["rescue_eligible_warbands"] = eligible
		if bool(base["rescue_used"]) or contested or eligible < 2:
			base["rescue_progress_ticks"] = 0
		elif tick > int(base["suppressed_tick"]):
			base["rescue_progress_ticks"] = int(base["rescue_progress_ticks"]) + 1
			if int(base["rescue_progress_ticks"]) >= RESCUE_TICKS:
				_restore_base(base)
	for base_id: String in _sorted_base_ids():
		var base: Dictionary = _bases[base_id]
		if base["state"] == STATE_SUPPRESSED and tick >= int(base["evacuation_deadline_tick"]):
			base["state"] = STATE_EVACUATED
	return _get_outcome()


func get_state_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for base_id: String in _sorted_base_ids():
		var base: Dictionary = _bases[base_id]
		var position: Vector2i = base["position"]
		lines.append("B|%s|%s|%d|%d|%d|%d|%d|%s|%d|%d|%d|%d|%d|%d" % [
			base["id"], base["side"], position.x, position.y, base["radius"],
			base["hp"], base["max_hp"], base["state"], base["suppressed_tick"],
			base["evacuation_deadline_tick"], base["rescue_progress_ticks"],
			base["rescue_eligible_warbands"], int(base["rescue_contested"]), int(base["rescue_used"]),
		])
	return lines


func _initial_base(base_id: String, side: String, position: Vector2i) -> Dictionary:
	return {
		"id": base_id,
		"side": side,
		"position": position,
		"radius": BODY_RADIUS,
		"hp": MAX_HP,
		"max_hp": MAX_HP,
		"state": STATE_ACTIVE,
		"suppressed_tick": -1,
		"evacuation_deadline_tick": -1,
		"rescue_progress_ticks": 0,
		"rescue_eligible_warbands": 0,
		"rescue_contested": false,
		"rescue_used": false,
	}


func _restore_base(base: Dictionary) -> void:
	base["hp"] = RESCUE_HP
	base["state"] = STATE_ACTIVE
	base["suppressed_tick"] = -1
	base["evacuation_deadline_tick"] = -1
	base["rescue_progress_ticks"] = 0
	base["rescue_eligible_warbands"] = 0
	base["rescue_contested"] = false
	base["rescue_used"] = true


func _eligible_warband_count(base: Dictionary, warbands: Array, soldiers_by_id: Dictionary) -> int:
	var eligible := 0
	var seen_warbands := {}
	for warband: Dictionary in warbands:
		var warband_id := str(warband["id"])
		if warband.get("side") != base["side"] or seen_warbands.has(warband_id):
			continue
		seen_warbands[warband_id] = true
		var living := 0
		var in_circle := 0
		var seen_members := {}
		for member_id: String in warband.get("member_ids", []):
			if not soldiers_by_id.has(member_id) or seen_members.has(member_id):
				continue
			seen_members[member_id] = true
			var soldier: Dictionary = soldiers_by_id[member_id]
			if soldier.get("side") != base["side"] or soldier.get("warband_id") != warband_id or int(soldier.get("hp", 0)) <= 0:
				continue
			living += 1
			if _is_in_circle(base, soldier["position"]):
				in_circle += 1
		if living > 0 and in_circle * 2 >= living:
			eligible += 1
	return eligible


func _is_contested(base: Dictionary, soldiers: Array) -> bool:
	var enemy_side := SIDE_AI if base["side"] == SIDE_PLAYER else SIDE_PLAYER
	for soldier: Dictionary in soldiers:
		if soldier.get("side") == enemy_side and int(soldier.get("hp", 0)) > 0 and _is_in_circle(base, soldier["position"]):
			return true
	return false


func _is_in_circle(base: Dictionary, position: Vector2i) -> bool:
	var offset: Vector2i = position - Vector2i(base["position"])
	return offset.x * offset.x + offset.y * offset.y <= CONTROL_RADIUS * CONTROL_RADIUS


func _get_outcome() -> String:
	var player_evacuated: bool = _bases[PLAYER_BASE_ID]["state"] == STATE_EVACUATED
	var ai_evacuated: bool = _bases[AI_BASE_ID]["state"] == STATE_EVACUATED
	if player_evacuated and ai_evacuated:
		return OUTCOME_DRAW
	if player_evacuated:
		return OUTCOME_PLAYER_DEFEAT
	if ai_evacuated:
		return OUTCOME_PLAYER_VICTORY
	return OUTCOME_ONGOING


func _sorted_base_ids() -> Array[String]:
	return [AI_BASE_ID, PLAYER_BASE_ID]
