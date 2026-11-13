class_name StrategicCommandFeedback
extends RefCounted
## Local, bounded acknowledgement state. A receipt is not arrival, a hit or a
## build completion. This module never retains authority or dispatches commands.

const MAX_MARKS := 16
const ACK_SECONDS := 0.85
const REJECT_SECONDS := 1.15
const SELECT_SECONDS := 0.48
const KINDS := {
	"MOVE": "MOVE", "UNIT_MOVE": "MOVE", "RETREAT": "MOVE",
	"ATTACK_MOVE": "ATTACK_MOVE", "FOCUS": "ATTACK", "UNIT_ATTACK": "ATTACK", "ATTACK_BASE": "ATTACK",
	"HERO_SKILL": "CAST", "PLACE_BUILDING": "BUILD",
	"USE_POTION": "SUPPORT", "EQUIP_ITEM": "SUPPORT", "BUY_ITEM": "SUPPORT",
}
const CAPTIONS := {"MOVE": "移动指令", "ATTACK_MOVE": "进攻式移动", "ATTACK": "锁定指令", "CAST": "技能指令", "BUILD": "施工入队", "SUPPORT": "已执行", "REJECT": "未执行", "SELECT": "已选择"}
var _marks: Array[Dictionary] = []


func reset() -> void:
	_marks.clear()


func record(command: Dictionary, result: Dictionary, snapshot: Dictionary, point: Variant = null) -> void:
	var type := str(command.get("type", ""))
	var subject := str(command.get("unit_id", command.get("subject_id", "")))
	if type in ["STOP", "UNIT_STOP"] and bool(result.get("accepted", false)):
		for index: int in range(_marks.size() - 1, -1, -1):
			if _marks[index].get("subject_id", "") == subject and _marks[index].get("kind", "") != "SELECT": _marks.remove_at(index)
		return
	if not KINDS.has(type): return
	var location: Variant = _command_point(command, snapshot, point)
	if not _valid_point(location): return
	var accepted := bool(result.get("accepted", false))
	var kind := str(KINDS[type]) if accepted else "REJECT"
	_append({"kind": kind, "caption": CAPTIONS[kind], "position": Vector2(location), "subject_id": subject, "accepted": accepted, "command_type": type, "age": 0.0, "lifetime": ACK_SECONDS if accepted else REJECT_SECONDS})


func select(kind: String, id: String, snapshot: Dictionary) -> void:
	# Selection replacement clears only old pulses, not independent receipts.
	for index: int in range(_marks.size() - 1, -1, -1):
		if _marks[index].get("kind", "") == "SELECT": _marks.remove_at(index)
	if id.is_empty() or kind not in ["UNIT", "ARMY", "WORKER"]: return
	var entity := _entity(snapshot, id, ["warbands"] if kind == "ARMY" else ["workers"] if kind == "WORKER" else ["soldiers"])
	if entity.is_empty(): return
	if kind == "ARMY":
		# Empty regular armies remain selectable/commandable: their published
		# anchor is real even before recruitment or after transfer/casualties.
		# A selection acknowledgement is not a claim that troops are alive.
		if entity.get("side") != "PLAYER" or bool(entity.get("reserve", false)): return
	elif not _alive(entity): return
	var point: Variant = entity.get("anchor" if kind == "ARMY" else "position")
	if not _valid_point(point): return
	_append({"kind": "SELECT", "caption": CAPTIONS["SELECT"], "position": Vector2(point), "subject_id": id, "selection_kind": kind, "accepted": true, "age": 0.0, "lifetime": SELECT_SECONDS})


func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0: return
	for index: int in range(_marks.size() - 1, -1, -1):
		_marks[index]["age"] = float(_marks[index]["age"]) + delta
		if float(_marks[index]["age"]) >= float(_marks[index]["lifetime"]): _marks.remove_at(index)


func get_marks() -> Array[Dictionary]:
	return _marks.duplicate(true)


func _append(mark: Dictionary) -> void:
	_marks.append(mark.duplicate(true))
	if _marks.size() > MAX_MARKS: _marks.pop_front()


static func _command_point(command: Dictionary, snapshot: Dictionary, explicit: Variant) -> Variant:
	if _valid_point(explicit): return explicit
	for field: String in ["target_position", "position"]:
		if _valid_point(command.get(field)): return command[field]
	for field: String in ["target_id", "target_base_id", "target_warband_id"]:
		var target := _entity(snapshot, str(command.get(field, "")), ["soldiers", "buildings", "warbands"])
		if not target.is_empty(): return target.get("position", target.get("anchor"))
	var source := _entity(snapshot, str(command.get("unit_id", command.get("subject_id", ""))), ["soldiers", "warbands"])
	if source.is_empty(): return null
	return source.get("position", source.get("anchor"))


static func _entity(snapshot: Dictionary, id: String, lists: Array) -> Dictionary:
	if id.is_empty(): return {}
	for list: String in lists:
		for entity: Dictionary in snapshot.get(list, []):
			if str(entity.get("id", "")) == id: return entity
	return {}


static func _alive(entity: Dictionary) -> bool:
	return int(entity.get("living_count", 0)) > 0 if entity.has("living_count") else bool(entity.get("alive", int(entity.get("hp", 0)) > 0)) and int(entity.get("hp", 0)) > 0


static func _valid_point(point: Variant) -> bool:
	return (point is Vector2 or point is Vector2i) and is_finite(float(point.x)) and is_finite(float(point.y))
