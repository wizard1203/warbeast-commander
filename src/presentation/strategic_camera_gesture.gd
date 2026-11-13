class_name StrategicCameraGesture
extends RefCounted
## Presentation-only contact ownership. A ground tap commits on release; a
## multi-contact session stays non-commanding until every contact is released.
var _contacts: Dictionary = {}
var _multi := false
var _suppressed := false
var _distance := 0.0
var _midpoint := Vector2.ZERO

func touch(index: int, position: Vector2, pressed: bool, canceled: bool, eligible: bool) -> Dictionary:
	if pressed:
		_contacts[index] = {"position":position, "origin":position, "ground":eligible, "moved":false}
		if _contacts.size() > 1:
			_multi = true
			_seed_pair()
		if _contacts.size() > 2: _suppressed = true
		return {}
	if not _contacts.has(index): return {}
	var contact: Dictionary = _contacts[index]
	var tap := not canceled and not _multi and not _suppressed and bool(contact.ground) and not bool(contact.moved) and eligible
	_contacts.erase(index)
	if _contacts.is_empty():
		_multi = false
		_suppressed = false
		_distance = 0
	return {"tap":position} if tap else {}

func drag(index: int, position: Vector2) -> Dictionary:
	if not _contacts.has(index): return {}
	_contacts[index]["position"] = position
	if position.distance_to(_contacts[index]["origin"]) > 12: _contacts[index]["moved"] = true
	if _suppressed or not _multi or _contacts.size() != 2: return {}
	for contact: Dictionary in _contacts.values():
		if not contact.ground: return {}
	var pair := _pair()
	var distance: float = pair.distance
	var midpoint: Vector2 = pair.midpoint
	var previous := _distance
	var previous_mid := _midpoint
	_distance = distance
	_midpoint = midpoint
	if previous < 8 or distance < 8: return {}
	var factor := distance / previous
	if not is_finite(factor) or factor <= 0: return {}
	return {"factor":factor, "midpoint":midpoint, "previous_midpoint":previous_mid}

func suppress() -> void:
	if not _contacts.is_empty(): _suppressed = true

func active() -> bool:
	return not _contacts.is_empty()

func _seed_pair() -> void:
	if _contacts.size() != 2: return
	var pair := _pair()
	_distance = pair.distance
	_midpoint = pair.midpoint

func _pair() -> Dictionary:
	var values := _contacts.values()
	var a: Vector2 = values[0].position
	var b: Vector2 = values[1].position
	return {"distance":a.distance_to(b), "midpoint":(a + b) * 0.5}
