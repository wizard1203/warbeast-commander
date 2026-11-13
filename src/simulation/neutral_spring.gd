class_name NeutralSpring
extends RefCounted
## A public, passable M8 objective. It reads physical roster values; it does not
## own soldiers, move units, collect worker resources, or restore a command beast.
## The host invokes this only during an ongoing BATTLE, after casualties settle.

const SPRING_ID := "spring:central:v1"
const POSITION := Vector2i(640, 360)
const CONTROL_RADIUS := 90
const CAPTURE_TICKS := 80
const INCOME_TICKS := 20
const FORTIFY_COST := 20
const FORTIFY_HP := 200
const EVENT_LIMIT := 32
const SIDE_PLAYER := "PLAYER"
const SIDE_AI := "AI"
const OWNER_NEUTRAL := "NEUTRAL"
const SIDES: Array[String] = [SIDE_PLAYER, SIDE_AI]

var _spring: Dictionary = {}
var _resonance: Dictionary = {}
var _events: Array[Dictionary] = []
var _event_serial := 0
var _last_tick := -1
var _position: Vector2i = POSITION


func _init(position: Vector2i = POSITION) -> void:
	_position = position
	reset()


func reset() -> void:
	_spring = {
		"id": SPRING_ID,
		"position": _position,
		"control_radius": CONTROL_RADIUS,
		"owner": OWNER_NEUTRAL,
		"capturing_side": "",
		"capture_ticks": 0,
		"capture_required_ticks": CAPTURE_TICKS,
		"contested": false,
		"income_blocked": false,
		"inside_counts": _empty_side_counts(),
		"eligible_warbands": _empty_side_counts(),
		"income_ticks": 0,
		"income_period_ticks": INCOME_TICKS,
		"income_amount": 1,
	}
	_resonance = _empty_side_counts()
	_events = []
	_event_serial = 0
	_last_tick = -1


func advance_tick(tick: int, warbands: Array, soldiers: Array) -> bool:
	if tick < 0 or tick <= _last_tick:
		return false
	# A caller cannot skip an unknown interval and call the result continuous.
	# The first BATTLE tick may follow an arbitrarily long frozen preparation.
	if _last_tick >= 0 and tick != _last_tick + 1:
		_clear_capture()
		_spring["income_ticks"] = 0
	_last_tick = tick

	var soldiers_by_id := _canonical_soldiers(soldiers)
	var inside := _empty_side_counts()
	for soldier_id: String in _sorted_keys(soldiers_by_id):
		var soldier: Dictionary = soldiers_by_id[soldier_id]
		if int(soldier.get("hp", 0)) > 0 and _is_inside(soldier["position"]):
			inside[str(soldier["side"])] += 1
	var eligible := _eligible_counts(warbands, soldiers_by_id)
	_spring["inside_counts"] = inside
	_spring["eligible_warbands"] = eligible
	_spring["contested"] = int(inside[SIDE_PLAYER]) > 0 and int(inside[SIDE_AI]) > 0

	var candidate := ""
	if not bool(_spring["contested"]):
		for side: String in SIDES:
			if int(eligible[side]) > 0 and int(inside[_enemy_side(side)]) == 0:
				candidate = side
				break
	var just_captured := false
	if candidate.is_empty() or candidate == _spring["owner"]:
		_clear_capture()
	else:
		if candidate != _spring["capturing_side"]:
			_spring["capturing_side"] = candidate
			_spring["capture_ticks"] = 0
		_spring["capture_ticks"] = int(_spring["capture_ticks"]) + 1
		if int(_spring["capture_ticks"]) >= CAPTURE_TICKS:
			_spring["owner"] = candidate
			_clear_capture()
			_spring["income_ticks"] = 0
			_record_event(tick, "CAPTURE", candidate, 0)
			just_captured = true

	var owner := str(_spring["owner"])
	_spring["income_blocked"] = owner in SIDES and int(inside[_enemy_side(owner)]) > 0
	if owner not in SIDES or bool(_spring["income_blocked"]):
		_spring["income_ticks"] = 0
	elif not just_captured:
		_spring["income_ticks"] = int(_spring["income_ticks"]) + 1
		if int(_spring["income_ticks"]) >= INCOME_TICKS:
			_spring["income_ticks"] = 0
			_resonance[owner] = int(_resonance[owner]) + 1
			_record_event(tick, "GENERATE", owner, 1)
	return true


func get_snapshot() -> Dictionary:
	return {
		"spring": _spring.duplicate(true),
		"resonance": _resonance.duplicate(true),
		"events": _events.duplicate(true),
		"event_serial": _event_serial,
		"last_tick": _last_tick,
	}


func get_resonance(side: String) -> int:
	return int(_resonance.get(side, 0))


func spend(side: String, amount: int, tick: int) -> bool:
	if side not in SIDES or amount <= 0 or tick < 0 or tick < _last_tick:
		return false
	if int(_resonance[side]) < amount:
		return false
	_resonance[side] = int(_resonance[side]) - amount
	_record_event(tick, "SPEND", side, amount)
	return true


func get_state_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var position: Vector2i = _spring["position"]
	lines.append("NS|%s|%d|%d|%d|%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [
		_spring["id"], position.x, position.y, _spring["control_radius"],
		_spring["owner"], _spring["capturing_side"], _spring["capture_ticks"],
		_spring["capture_required_ticks"], int(_spring["contested"]), int(_spring["income_blocked"]),
		_spring["income_ticks"], _spring["income_period_ticks"], _spring["income_amount"],
		_event_serial, _last_tick,
	])
	for side: String in SIDES:
		lines.append("NS_SIDE|%s|%d|%d|%d" % [
			side, _spring["inside_counts"][side], _spring["eligible_warbands"][side], _resonance[side],
		])
	for event: Dictionary in _events:
		lines.append("NS_EVENT|%d|%d|%s|%s|%s|%d" % [
			event["serial"], event["tick"], event["type"], event["side"], event["spring_id"], event["amount"],
		])
	return lines


func _eligible_counts(warbands: Array, soldiers_by_id: Dictionary) -> Dictionary:
	var eligible := _empty_side_counts()
	var canonical := _canonical_warbands(warbands)
	for warband_id: String in _sorted_keys(canonical):
		var warband: Dictionary = canonical[warband_id]
		var side := str(warband["side"])
		var living := 0
		var inside := 0
		var seen_members := {}
		for member_value: Variant in warband.get("member_ids", []):
			if typeof(member_value) != TYPE_STRING:
				continue
			var member_id: String = member_value
			if seen_members.has(member_id) or not soldiers_by_id.has(member_id):
				continue
			seen_members[member_id] = true
			var soldier: Dictionary = soldiers_by_id[member_id]
			if soldier["side"] != side or soldier.get("warband_id") != warband_id or int(soldier.get("hp", 0)) <= 0:
				continue
			living += 1
			if _is_inside(soldier["position"]):
				inside += 1
		if living > 0 and inside * 2 > living:
			eligible[side] += 1
	return eligible


func _canonical_soldiers(soldiers: Array) -> Dictionary:
	var ordered: Array[Dictionary] = []
	for value: Variant in soldiers:
		if not value is Dictionary:
			continue
		var soldier: Dictionary = value
		if (
			typeof(soldier.get("id")) != TYPE_STRING or str(soldier["id"]).is_empty()
			or typeof(soldier.get("warband_id")) != TYPE_STRING or str(soldier["warband_id"]).is_empty()
			or soldier.get("side") not in SIDES or typeof(soldier.get("position")) != TYPE_VECTOR2I
		):
			continue
		ordered.append(soldier)
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return _soldier_order_key(left) < _soldier_order_key(right)
	)
	var result := {}
	for soldier: Dictionary in ordered:
		var soldier_id := str(soldier["id"])
		if not result.has(soldier_id):
			result[soldier_id] = soldier
	return result


func _canonical_warbands(warbands: Array) -> Dictionary:
	var ordered: Array[Dictionary] = []
	for value: Variant in warbands:
		if not value is Dictionary:
			continue
		var warband: Dictionary = value
		if (
			typeof(warband.get("id")) != TYPE_STRING or str(warband["id"]).is_empty()
			or warband.get("side") not in SIDES or not warband.get("member_ids") is Array
		):
			continue
		ordered.append(warband)
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return _warband_order_key(left) < _warband_order_key(right)
	)
	var result := {}
	for warband: Dictionary in ordered:
		var warband_id := str(warband["id"])
		if not result.has(warband_id):
			result[warband_id] = warband
	return result


func _soldier_order_key(soldier: Dictionary) -> String:
	var position: Vector2i = soldier["position"]
	return "%s|%s|%s|%d|%d|%d" % [
		soldier["id"], soldier["side"], soldier.get("warband_id", ""),
		position.x, position.y, int(soldier.get("hp", 0)),
	]


func _warband_order_key(warband: Dictionary) -> String:
	var member_ids := PackedStringArray()
	for member: Variant in warband["member_ids"]:
		if typeof(member) == TYPE_STRING:
			member_ids.append(member)
	member_ids.sort()
	return "%s|%s|%s" % [warband["id"], warband["side"], ",".join(member_ids)]


func _clear_capture() -> void:
	_spring["capturing_side"] = ""
	_spring["capture_ticks"] = 0


func _record_event(tick: int, event_type: String, side: String, amount: int) -> void:
	_event_serial += 1
	_events.append({
		"serial": _event_serial,
		"tick": tick,
		"type": event_type,
		"side": side,
		"spring_id": SPRING_ID,
		"amount": amount,
	})
	if _events.size() > EVENT_LIMIT:
		_events.pop_front()


func _is_inside(position: Vector2i) -> bool:
	var offset := position - _position
	return offset.x * offset.x + offset.y * offset.y <= CONTROL_RADIUS * CONTROL_RADIUS


func _enemy_side(side: String) -> String:
	return SIDE_AI if side == SIDE_PLAYER else SIDE_PLAYER


func _empty_side_counts() -> Dictionary:
	return {SIDE_PLAYER: 0, SIDE_AI: 0}


func _sorted_keys(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key: Variant in source.keys():
		result.append(str(key))
	result.sort()
	return result
