class_name StrategicHeroEconomy
extends RefCounted
## Pure semantic quote. Stock, population and producer checks belong to World.
## A paid queue stores this decision; later roster changes never reprice it.

const RECRUIT_TICKS := 550
const POPULATION := 5
const MAX_HEROES := 3
const MAX_LEVEL := 8
const Currency = preload("res://src/simulation/strategic_currency.gd")
const RECRUIT_COSTS := {
	1: {"FOOD":0,"MATERIAL":0,"ESSENCE":0},
	2: {"FOOD":0,"MATERIAL":500,"ESSENCE":0},
	3: {"FOOD":0,"MATERIAL":625,"ESSENCE":0},
}

static func quote(archetype: String, side: String, roster: Array, buildings: Array, base_tier: int) -> Dictionary:
	var occupied := {}
	var owned: Dictionary = {}
	for hero: Dictionary in roster:
		if hero.get("side", "") != side: continue
		var slot := int(hero.get("hero_slot", 0))
		if slot < 1 or slot > MAX_HEROES: slot = _empty_slot(occupied)
		if slot > 0: occupied[slot] = true
		if str(hero.get("hero_archetype", hero.get("archetype", ""))) == archetype:
			owned = hero.duplicate(true)
			owned["hero_slot"] = slot
	var pending := false
	for building: Dictionary in buildings:
		if building.get("side", "") != side: continue
		for entry: Dictionary in building.get("queue", []):
			if entry.get("unit_type", "") != "hero": continue
			if entry.get("hero_archetype", "") == archetype: pending = true
			if entry.get("hero_mode", "RECRUIT") == "REVIVE": continue
			var slot := int(entry.get("hero_slot", 0))
			if slot < 1 or slot > MAX_HEROES: slot = _empty_slot(occupied)
			if slot > 0: occupied[slot] = true
	var slot := int(owned.hero_slot) if not owned.is_empty() else _empty_slot(occupied)
	var level := clampi(int(owned.get("level", 1)), 1, MAX_LEVEL)
	var mode := "REVIVE" if not owned.is_empty() else "RECRUIT"
	var cost: Dictionary = {"FOOD":0,"MATERIAL":160+40*(level-1),"ESSENCE":0} if mode == "REVIVE" else RECRUIT_COSTS.get(slot, RECRUIT_COSTS[3]).duplicate(true)
	var result := {
		"accepted":true,"error":"","currency_version":Currency.VERSION,"mode":mode,"hero_id":str(owned.get("unit_id", owned.get("id", ""))),
		"hero_slot":slot,"level":level,"cost":cost,"duration_ticks":mini(330*level,1100) if mode == "REVIVE" else RECRUIT_TICKS,
		"population":POPULATION,"required_base_tier":1 if mode == "REVIVE" else maxi(1,slot),
		"life_generation":int(owned.get("life_generation",1)),
	}
	if pending: result.error = "HERO_ALREADY_QUEUED"
	elif not owned.is_empty() and bool(owned.get("alive", owned.get("state", "") == "ACTIVE")): result.error = "HERO_ALREADY_ALIVE"
	elif slot == 0: result.error = "HERO_ROSTER_FULL"
	elif mode == "RECRUIT" and base_tier < slot: result.error = "BASE_TIER_REQUIRED"
	result.accepted = str(result.error).is_empty()
	return result

static func _empty_slot(occupied: Dictionary) -> int:
	for slot: int in range(1,MAX_HEROES+1):
		if not occupied.has(slot): return slot
	return 0
