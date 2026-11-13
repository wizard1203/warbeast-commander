class_name HeroOfficers
extends RefCounted
## Frontier exercise heroes reuse existing physical members. This module owns
## only bounded experience/history; all observed HP/position comes from roster
## values and every kill input is an authoritative host lethal transition.

const MAX_XP := 8
const LEVEL_TWO_XP := 3
const MAX_LEVEL := 3
const EVENT_LIMIT := 32
const STATE_ACTIVE := "ACTIVE"
const STATE_INCAPACITATED := "INCAPACITATED"
const SIDE_PLAYER := "PLAYER"
const SIDE_AI := "AI"
const PLAYER_HERO_ID := "hero:jiangqi:v1"
const AI_HERO_ID := "hero:muqiao:v1"

var _enabled := false
var _officers: Dictionary = {}
var _events: Array[Dictionary] = []
var _event_serial := 0
var _last_tick := -1


func _init(enabled: bool = false) -> void:
	reset(enabled)


func reset(enabled: bool) -> void:
	_enabled = enabled
	_officers = {}
	_events = []
	_event_serial = 0
	_last_tick = -1
	if enabled:
		_officers[PLAYER_HERO_ID] = _initial_officer(PLAYER_HERO_ID, SIDE_PLAYER, "player_alpha", "绛栖", "誓图师")
		_officers[AI_HERO_ID] = _initial_officer(AI_HERO_ID, SIDE_AI, "ai_alpha", "穆桥", "桥铸师")


func settle_tick(tick: int, soldiers: Array, kills: Array) -> bool:
	if not _enabled or tick < 0 or tick <= _last_tick:
		return false
	_last_tick = tick
	var roster := _soldiers_by_id(soldiers)
	# A captain lost anywhere in this simultaneous volley cannot earn the
	# volley's XP. Incapacitation is irreversible until whole-match reset.
	for hero_id: String in _hero_ids():
		var officer: Dictionary = _officers[hero_id]
		if officer["state"] == STATE_ACTIVE and not _representative_alive(officer, roster):
			officer["state"] = STATE_INCAPACITATED
			_record_event(tick, "INCAPACITATED", officer, "", 0)
	var ordered := _sorted_kills(kills)
	for kill: Dictionary in ordered:
		var officer := _officer_for_warband(str(kill["warband_id"]))
		if officer.is_empty() or officer["state"] != STATE_ACTIVE or int(officer["xp"]) >= MAX_XP:
			continue
		var victim_id := str(kill["victim_id"])
		if victim_id in officer["credited_victim_ids"] or not roster.has(victim_id):
			continue
		var victim: Dictionary = roster[victim_id]
		if victim["side"] == officer["side"] or victim["side"] != kill["victim_side"] or int(victim.get("hp", 0)) > 0:
			continue
		(officer["credited_victim_ids"] as Array).append(victim_id)
		officer["xp"] = int(officer["xp"]) + 1
		officer["level"] = _level_for_xp(int(officer["xp"]))
		_record_event(tick, "XP_GAINED", officer, victim_id, 1)
	return true


func get_damage_bonus(warband_id: String) -> int:
	var officer := _officer_for_warband(warband_id)
	return _unlocked_bonus(int(officer["level"])) if not officer.is_empty() and officer["state"] == STATE_ACTIVE else 0


func get_snapshot(soldiers: Array) -> Dictionary:
	var roster := _soldiers_by_id(soldiers)
	var observed: Array[Dictionary] = []
	for hero_id: String in _hero_ids():
		var officer: Dictionary = (_officers[hero_id] as Dictionary).duplicate(true)
		var representative := _representative(officer, roster)
		var active: bool = officer["state"] == STATE_ACTIVE and int(representative.get("hp", 0)) > 0
		officer["state"] = STATE_ACTIVE if active else STATE_INCAPACITATED
		officer["damage_bonus"] = _unlocked_bonus(int(officer["level"])) if active else 0
		officer["next_level_xp"] = LEVEL_TWO_XP if int(officer["level"]) == 1 else MAX_XP if int(officer["level"]) == 2 else -1
		officer["hp"] = int(representative.get("hp", 0))
		officer["max_hp"] = int(representative.get("max_hp", 0))
		officer["position"] = representative.get("position", Vector2i.ZERO)
		observed.append(officer)
	return {"enabled": _enabled, "officers": observed, "events": _events.duplicate(true), "event_serial": _event_serial, "last_tick": _last_tick}


func get_state_lines() -> PackedStringArray:
	var lines := PackedStringArray(["HERO_STATE|%d|%d|%d" % [int(_enabled), _event_serial, _last_tick]])
	for hero_id: String in _hero_ids():
		var officer: Dictionary = _officers[hero_id]
		lines.append("HERO|%s|%s|%s|%s|%s|%s|%s|%d|%d" % [
			officer["id"], officer["side"], officer["warband_id"], officer["member_id"], officer["name"], officer["title"], officer["state"], officer["level"], officer["xp"],
		])
		for victim_id: String in officer["credited_victim_ids"]:
			lines.append("HERO_VICTIM|%s|%s" % [hero_id, victim_id])
	for event: Dictionary in _events:
		lines.append("HERO_EVENT|%d|%d|%s|%s|%s|%s|%d|%d|%d" % [
			event["serial"], event["tick"], event["type"], event["hero_id"], event["warband_id"], event["victim_id"], event["amount"], event["level"], event["xp"],
		])
	return lines


func _initial_officer(hero_id: String, side: String, warband_id: String, officer_name: String, title: String) -> Dictionary:
	return {"id": hero_id, "side": side, "warband_id": warband_id, "member_id": warband_id + "_s00", "name": officer_name, "title": title, "state": STATE_ACTIVE, "level": 1, "xp": 0, "credited_victim_ids": []}


func _officer_for_warband(warband_id: String) -> Dictionary:
	for hero_id: String in _hero_ids():
		if _officers[hero_id]["warband_id"] == warband_id:
			return _officers[hero_id]
	return {}


func _hero_ids() -> Array[String]:
	return [AI_HERO_ID, PLAYER_HERO_ID] if _enabled else []


func _level_for_xp(xp: int) -> int:
	return 3 if xp >= MAX_XP else 2 if xp >= LEVEL_TWO_XP else 1


func _unlocked_bonus(level: int) -> int:
	return clampi(level - 1, 0, MAX_LEVEL - 1) * 2


func _representative(officer: Dictionary, roster: Dictionary) -> Dictionary:
	var member_id := str(officer["member_id"])
	if not roster.has(member_id):
		return {}
	var soldier: Dictionary = roster[member_id]
	return soldier if soldier.get("side") == officer["side"] and soldier.get("warband_id") == officer["warband_id"] else {}


func _representative_alive(officer: Dictionary, roster: Dictionary) -> bool:
	return int(_representative(officer, roster).get("hp", 0)) > 0


func _soldiers_by_id(soldiers: Array) -> Dictionary:
	var ordered: Array[Dictionary] = []
	for value: Variant in soldiers:
		if not value is Dictionary:
			continue
		var soldier: Dictionary = value
		if typeof(soldier.get("id")) != TYPE_STRING or str(soldier["id"]).is_empty() or soldier.get("side") not in [SIDE_PLAYER, SIDE_AI] or typeof(soldier.get("warband_id")) != TYPE_STRING:
			continue
		ordered.append(soldier)
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return _soldier_key(left) < _soldier_key(right)
	)
	var result := {}
	for soldier: Dictionary in ordered:
		if not result.has(soldier["id"]):
			result[soldier["id"]] = soldier
	return result


func _soldier_key(soldier: Dictionary) -> String:
	return "%s|%s|%s|%d|%s" % [soldier["id"], soldier["side"], soldier["warband_id"], int(soldier.get("hp", 0)), str(soldier.get("position", Vector2i.ZERO))]


func _sorted_kills(kills: Array) -> Array[Dictionary]:
	var ordered: Array[Dictionary] = []
	for value: Variant in kills:
		if not value is Dictionary:
			continue
		var kill: Dictionary = value
		if typeof(kill.get("warband_id")) != TYPE_STRING or typeof(kill.get("victim_id")) != TYPE_STRING or str(kill["victim_id"]).is_empty() or kill.get("victim_side") not in [SIDE_PLAYER, SIDE_AI]:
			continue
		ordered.append(kill)
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return _kill_key(left) < _kill_key(right)
	)
	return ordered


func _kill_key(kill: Dictionary) -> String:
	return "%s|%s|%s" % [kill["warband_id"], kill["victim_id"], kill["victim_side"]]


func _record_event(tick: int, event_type: String, officer: Dictionary, victim_id: String, amount: int) -> void:
	_event_serial += 1
	_events.append({"serial": _event_serial, "tick": tick, "type": event_type, "hero_id": officer["id"], "warband_id": officer["warband_id"], "victim_id": victim_id, "amount": amount, "level": officer["level"], "xp": officer["xp"]})
	if _events.size() > EVENT_LIMIT:
		_events.pop_front()
