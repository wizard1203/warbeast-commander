class_name StrategicFieldObjectives
extends RefCounted
## Finite exploration authority. No renderer, RNG or public command surface.
## World owns capture/stock and Combat owns bodies/progression; this ledger only
## settles their closed recipes after the host has completed both domains.

const VERSION := "field-objectives-v1"
const KINDS := ["SUPPLY", "ARMORY", "RELIC"]
const CATALOG := {
	"SUPPLY":{"label":"远征补给站", "icon":"food", "reward":{"FOOD":0,"MATERIAL":24,"XP":0,"POTION":0,"ESSENCE":0}},
	"ARMORY":{"label":"遗落军械库", "icon":"tech", "reward":{"FOOD":0,"MATERIAL":24,"XP":0,"POTION":0,"ESSENCE":0}},
	"RELIC":{"label":"誓约档案", "icon":"hero", "reward":{"FOOD":0,"MATERIAL":0,"XP":2,"POTION":1,"ESSENCE":0}},
}
const RADIUS := 180
const MAX_EVENTS := 24

var _records: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _sides: Array[String] = []
var _last_tick := -1


func _init(canonical_match: Dictionary = {}) -> void:
	reset(canonical_match)


func reset(canonical_match: Dictionary) -> void:
	_records = definitions(canonical_match)
	_events.clear()
	_sides.clear()
	for slot: Dictionary in canonical_match.get("sides", []): _sides.append(str(slot.side_id))
	_sides.sort()
	_last_tick = -1


static func definitions(canonical_match: Dictionary) -> Array[Dictionary]:
	var buckets := {}
	var homes: Array[Dictionary] = []
	for slot: Dictionary in canonical_match.get("sides", []):
		if typeof(slot.get("home")) != TYPE_VECTOR2I or str(slot.get("side_id", "")).is_empty(): continue
		homes.append({"side":str(slot.side_id), "position":slot.home})
		buckets[str(slot.side_id)] = []
	homes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.side < b.side)
	for site: Dictionary in canonical_match.get("sites", []):
		if site.get("kind") != "VILLAGE" or not str(site.get("owner", "")).is_empty() or typeof(site.get("position")) != TYPE_VECTOR2I: continue
		var nearest := ""
		var best := -1
		for home: Dictionary in homes:
			var origin: Vector2i = site.position
			var destination: Vector2i = home.position
			var distance := origin.distance_squared_to(destination)
			if best < 0 or distance < best:
				best = distance
				nearest = home.side
		if nearest.is_empty(): continue
		buckets[nearest].append({"site":site, "distance":best})
	var result: Array[Dictionary] = []
	for home: Dictionary in homes:
		var ordered: Array = buckets[home.side]
		ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.site.id < b.site.id if a.distance == b.distance else a.distance < b.distance)
		for index: int in range(ordered.size()):
			var site: Dictionary = ordered[index].site
			var kind: String = KINDS[index % KINDS.size()]
			var recipe: Dictionary = CATALOG[kind]
			result.append({"id":"field:" + str(site.id), "site_id":str(site.id), "kind":kind, "label":recipe.label, "icon":recipe.icon, "position":site.position, "radius":RADIUS, "reward":recipe.reward.duplicate(true), "state":"AVAILABLE", "first_owner":"", "captured_tick":-1, "claimed_tick":-1, "recipient_id":"", "actual_grant":{}, "receipt_id":"field:%s:once" % str(site.id)})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.site_id < b.site_id)
	return result


static func definition(canonical_match: Dictionary, site_id: String) -> Dictionary:
	for record: Dictionary in definitions(canonical_match):
		if record.site_id == site_id: return record
	return {}


func advance_tick(tick: int, phase: String, outcome: String, world: RefCounted, combat: RefCounted) -> void:
	if phase != "BATTLE" or outcome != "ONGOING" or tick <= _last_tick: return
	_last_tick = tick
	var has_open := false
	for record: Dictionary in _records:
		if record.state != "CLAIMED": has_open = true; break
	if not has_open: return
	# Fixed-tick exploration never copies soldiers, workers, production or skill
	# catalogs. Archive body observations are lazy and shared within this tick.
	var sites: Array = world._field_site_observations()
	var heroes: Array = []
	var observed_heroes := false
	var by_id := {}
	for site: Dictionary in sites: by_id[str(site.id)] = site
	for record: Dictionary in _records:
		if record.state == "CLAIMED" or not by_id.has(record.site_id): continue
		var site: Dictionary = by_id[record.site_id]
		var owner := str(site.get("owner", ""))
		if owner not in _sides: continue
		if str(record.first_owner).is_empty():
			if site.get("capture_side") != owner or int(site.get("progress", 0)) < int(site.get("threshold", 200)): continue
			record.first_owner = owner
			record.captured_tick = tick
			if record.kind == "RELIC": record.state = "PENDING_HERO"
		if owner != record.first_owner: continue
		var receipt := {"receipt_id":record.receipt_id, "site_id":record.site_id, "kind":record.kind, "side":record.first_owner, "tick":tick}
		var result: Dictionary
		if record.kind == "RELIC":
			if not observed_heroes:
				heroes = combat._field_hero_observations()
				observed_heroes = true
			var recipient := nearest_hero(heroes, owner, record.position, int(record.radius))
			if recipient.is_empty(): continue
			receipt["unit_id"] = recipient
			receipt["captured_tick"] = int(record.captured_tick)
			result = combat._grant_field_relic(receipt, sites)
		else:
			result = world._grant_field_stock(receipt)
		if not result.get("accepted", false): continue
		record.state = "CLAIMED"
		record.claimed_tick = tick
		record.recipient_id = str(receipt.get("unit_id", ""))
		record.actual_grant = result.actual_grant.duplicate(true)
		var event := record.duplicate(true)
		event["tick"] = tick
		event["side"] = record.first_owner
		_events.append(event)
		if _events.size() > MAX_EVENTS: _events.pop_front()


static func nearest_hero(heroes: Array, side: String, position: Vector2i, radius: int) -> String:
	var best_id := ""
	var best := radius * radius + 1
	for hero: Dictionary in heroes:
		if hero.get("side") != side or int(hero.get("hp", 0)) <= 0 or not bool(hero.get("alive", false)) or hero.get("movement_layer") != "GROUND" or typeof(hero.get("position")) != TYPE_VECTOR2I: continue
		var hero_position: Vector2i = hero.position
		var distance := hero_position.distance_squared_to(position)
		if distance > radius * radius: continue
		var id := str(hero.get("id", ""))
		if id.is_empty(): continue
		if distance < best or (distance == best and (best_id.is_empty() or id < best_id)):
			best = distance
			best_id = id
	return best_id


func get_snapshot() -> Dictionary:
	return {"field_objectives":_records.duplicate(true), "field_objective_events":_events.duplicate(true)}


func get_state() -> Dictionary:
	return {"version":VERSION, "last_tick":_last_tick, "sides":_sides.duplicate(), "records":_records.duplicate(true), "events":_events.duplicate(true)}
