extends RefCounted
## Local presentation history. Only observed real HP differences start injury;
## first sightings and new matches are baselines, never damage events. No host,
## mutable snapshot reference, authoritative clock or randomness is retained.
const LIFETIME_TICKS := 6
const MAX_TRACKED := 512
const MAX_ACTIVE := 64
var _previous_hp: Dictionary = {}
var _hits: Dictionary = {}
var _signature := ""
var _last_tick := -1
var _last_phase := ""
var _primed := false

func observe(snapshot: Dictionary) -> void:
	# The final host tick does not advance after an outcome. Never retain or
	# re-prime a transient injury on that frozen tick; the next ongoing match
	# must establish its own first-seen HP baseline. Legacy observations that
	# omit outcome preserve the existing ongoing-fixture contract.
	if str(snapshot.get("outcome","ONGOING"))!="ONGOING":
		reset()
		return
	var tick := int(snapshot.get("tick", -1))
	if tick < 0: return
	var signature := _match_signature(snapshot)
	var phase := str(snapshot.get("phase", ""))
	if _primed and (tick < _last_tick or signature != _signature or (phase == "LOBBY" and _last_phase != "LOBBY")): reset()
	var current: Dictionary = {}
	for key: String in ["soldiers", "workers"]:
		for value: Variant in snapshot.get(key, []):
			if not value is Dictionary or not value.get("id") is String or not value.get("hp") is int: continue
			var id: String = value.id
			if id.is_empty(): continue
			var hp := maxi(0, int(value.hp))
			current[id] = hp
	# The cap is deterministic under reversed observation arrays. New bodies
	# beyond the retained set remain first sightings, not fabricated injuries.
	var ids: Array = current.keys()
	ids.sort()
	for index: int in range(MAX_TRACKED, ids.size()): current.erase(ids[index])
	for id: String in current:
		var hp: int = current[id]
		if _primed and _previous_hp.has(id) and hp < int(_previous_hp[id]): _hits[id] = {"amount":int(_previous_hp[id]) - hp,"tick":tick}
	for id: String in _hits.keys():
		if not current.has(id) or tick - int(_hits[id].tick) >= LIFETIME_TICKS: _hits.erase(id)
	var active: Array = _hits.keys()
	active.sort_custom(func(left: String, right: String) -> bool:
		return int(_hits[left].tick) > int(_hits[right].tick) if _hits[left].tick != _hits[right].tick else left < right
	)
	for index: int in range(MAX_ACTIVE, active.size()): _hits.erase(active[index])
	_previous_hp = current
	_signature = signature
	_last_tick = tick
	_last_phase = phase
	_primed = true

func read(id: String, tick: int) -> Dictionary:
	if not _hits.has(id): return {}
	var age := tick - int(_hits[id].tick)
	if age < 0 or age >= LIFETIME_TICKS: return {}
	var phase := float(age) / LIFETIME_TICKS
	return {"amount":int(_hits[id].amount),"age":age,"phase":phase,"fade":1.0 - phase}

func reset() -> void:
	_previous_hp.clear()
	_hits.clear()
	_signature = ""
	_last_tick = -1
	_last_phase = ""
	_primed = false

static func _match_signature(snapshot: Dictionary) -> String:
	var match_config: Dictionary = snapshot.get("match_config", {})
	var slots: Array = []
	for side: Dictionary in match_config.get("sides", []): slots.append([side.get("side_id"),side.get("faction_id"),side.get("home")])
	return "%s:%s:%s:%s" % [str(snapshot.get("seed", 0)),str(match_config.get("map_id", "")),str(match_config.get("map_version", 0)),JSON.stringify(slots)]
