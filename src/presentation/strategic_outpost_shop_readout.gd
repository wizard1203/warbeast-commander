extends RefCounted
## One pure service projection for the Arena command and shop permission UI.
## This grants nothing: World still validates ownership, range and payment at
## submission time. No source dictionary/array is modified or cached here.
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Outposts = preload("res://src/simulation/strategic_outpost_rules.gd")

static func read(snapshot: Dictionary, unit_id: String, side: String) -> Dictionary:
	var hero: Dictionary = {}
	for candidate: Dictionary in snapshot.get("heroes", {}).get("officers", []):
		if str(candidate.get("unit_id", candidate.get("id", ""))) == unit_id and str(candidate.get("side", "")) == side:
			hero = candidate
			break
	if hero.is_empty() or not bool(hero.get("alive", false)) or int(hero.get("hp", 1)) <= 0:
		return {"building_id":"", "reason":"INVALID_HERO"}
	var sites: Dictionary = {}
	for site: Dictionary in snapshot.get("sites", []): sites[str(site.get("id", ""))] = site
	var selected := ""
	var distance := INF
	var operational := false
	var origin := Vector2(hero.get("position", Vector2.ZERO))
	for building: Dictionary in snapshot.get("buildings", []):
		if building.get("side") != side or building.get("building_type") != "SHOP": continue
		if int(building.get("hp", 0)) <= 0 or not bool(building.get("complete", false)): continue
		var site: Dictionary = sites.get(str(building.get("site_id", "")), {})
		if not Outposts.fully_owned(site, side): continue
		operational = true
		var id := str(building.get("id", ""))
		if id.is_empty(): continue
		var delta := origin.distance_squared_to(Vector2(building.get("position", Vector2.ZERO)))
		if delta > Items.SHOP_RANGE * Items.SHOP_RANGE: continue
		if delta < distance or (delta == distance and (selected.is_empty() or id < selected)):
			selected = id
			distance = delta
	if selected.is_empty(): return {"building_id":"", "reason":"SHOP_TOO_FAR" if operational else "SHOP_INACTIVE"}
	return {"building_id":selected, "reason":"", "distance_squared":distance, "range":Items.SHOP_RANGE}
