extends RefCounted
## Read-only macro composition/development. No unit orders, resource mutation,
## combat simulation, independent timers or unbounded persistent caches.
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Progression = preload("res://src/simulation/strategic_progression_catalog.gd")
const Outposts = preload("res://src/simulation/strategic_ai_outposts.gd")
const VisibilityR9=preload("res://src/simulation/strategic_visibility_r9.gd")
const VERSION := "outposts-ai-income-veteran-population-r9"

static func profile(world: Dictionary, military: Dictionary) -> Dictionary:
	var result := {"live_population":0, "effective_live_population":0.0, "queued_population":0, "special_population":0, "advanced_population":0, "frontline_population":0, "damage_population":0, "support_population":0, "anti_air_population":0, "enemy_air":false, "counts":{}, "queued_counts":{}}
	for body: Dictionary in military.get("soldiers", []):
		if not bool(body.get("alive", int(body.get("hp", 0)) > 0)) or int(body.get("hp", 0)) <= 0: continue
		if body.get("side") != "AI":
			if body.get("side") == "PLAYER" and VisibilityR9.can_observe(body,str(world.get("planning_view_side_r9","AI"))) and body.get("movement_layer", "GROUND") == "AIR": result.enemy_air = true
			continue
		var id := str(body.get("unit_type", ""))
		if id in ["hero", "worker"] or not Units.UNITS.has(id): continue
		var recipe: Dictionary = Units.UNITS[id]
		var pop := int(recipe.get("population", 1))
		result.live_population += pop
		result.effective_live_population += float(pop) * clampf(float(body.get("hp", 0)) / maxf(1.0, float(body.get("max_hp", 1))), 0.0, 1.0)
		result.counts[id] = int(result.counts.get(id, 0)) + 1
		_accumulate(result, recipe, body, pop)
	for building: Dictionary in world.get("buildings", []):
		if building.get("side") != "AI" or int(building.get("hp", 0)) <= 0: continue
		for entry: Dictionary in building.get("queue", []):
			var id := str(entry.get("unit_type", ""))
			if id in ["hero", "worker"] or not Units.UNITS.has(id): continue
			var recipe: Dictionary = Units.UNITS[id]
			var pop := int(recipe.get("population", 1))
			result.queued_population += pop
			result.queued_counts[id] = int(result.queued_counts.get(id, 0)) + 1
			_accumulate(result, recipe, recipe.get("stats", {}), pop)
	return result


static func _accumulate(result: Dictionary, recipe: Dictionary, stats: Dictionary, pop: int) -> void:
	if recipe.get("production_family") == "SPECIAL": result.special_population += pop
	if int(recipe.get("required_base_tier", 1)) >= 2: result.advanced_population += pop
	var caps: Array = stats.get("role_capabilities", recipe.get("role_capabilities", []))
	if "ANCHOR" in caps: result.frontline_population += pop
	if "DAMAGE" in caps: result.damage_population += pop
	if int(stats.get("heal", recipe.get("stats", {}).get("heal", 0))) > 0: result.support_population += pop
	if "AIR" in stats.get("attack_layers", recipe.get("attack_layers", [])): result.anti_air_population += pop


static func emergency_rebuild(state: Dictionary) -> bool:
	# High-tier armies do not become an emergency merely because their opening
	# basic soldiers died. Wounded/depleted forces still regain cheap bodies.
	return float(state.get("effective_live_population", 0.0)) < 8.0


static func procurement_bonus(state: Dictionary, recipe: Dictionary, stats: Dictionary, elapsed: int, gold: int) -> float:
	var own := maxi(1, int(state.get("live_population", 0)) + int(state.get("queued_population", 0)))
	if elapsed < 800 or own < 12: return 0.0
	var caps: Array = stats.get("role_capabilities", recipe.get("role_capabilities", []))
	# Capability repair remains ahead of upgrading for its own sake. These are
	# population deficits, not a new per-unit tactical planner.
	if bool(state.get("enemy_air", false)) and int(state.get("anti_air_population", 0)) < maxi(4, own / 4) and "AIR" not in stats.get("attack_layers", []): return 0.0
	if int(state.get("frontline_population", 0)) < 4 and "ANCHOR" not in caps: return 0.0
	if int(state.get("support_population", 0)) == 0 and own >= 16 and int(stats.get("heal", 0)) <= 0: return 0.0
	var family := str(recipe.get("production_family", ""))
	if family == "SPECIAL":
		# A finite share, not an unlimited preference for expensive bodies.
		# Queue reservations count immediately, preventing three previews from
		# all seeing the same missing flagship and overbuying its population.
		var target := 0.40 if elapsed >= 1600 or gold >= 1200 else 0.25
		var present := float(state.get("special_population", 0)) / float(own)
		if present < target: return minf(1.6, 0.5 + (target - present) * 3.0)
		return -0.45 if present >= target + 0.15 else 0.0
	if int(recipe.get("required_base_tier", 1)) >= 2 and int(state.get("advanced_population", 0)) * 2 < own: return 0.35
	return 0.0


static func infrastructure_action(world: Dictionary, elapsed: int, state: Dictionary) -> Dictionary:
	if not Outposts.enabled(world): return {}
	var base: Dictionary = {}
	var present := {}
	for building: Dictionary in world.get("buildings", []):
		if building.get("side") != "AI" or int(building.get("hp", 0)) <= 0: continue
		if not Outposts.building_operational(world, building): continue
		# An uncompleted paid producer is already an investment, never a reason
		# to order a duplicate or reserve its price a second time.
		present[str(building.get("building_type", ""))] = true
		if building.get("building_type") != "BASE" or not bool(building.get("complete", false)) or not Outposts.building_operational(world, building): continue
		if base.is_empty() or int(building.get("base_tier", 1)) > int(base.get("base_tier", 1)): base = building
	if base.is_empty(): return {}
	var tier := int(base.get("base_tier", 1))
	var gold := int(world.get("economy", {}).get("AI", {}).get("stock", {}).get("MATERIAL", 0))
	var live := float(state.get("effective_live_population", 0.0))
	for kind: String in ["BARRACKS", "RANGE"]:
		if not present.has(kind):
			var replacement := Outposts.placement(world, kind, Vector2i(base.position))
			if not replacement.is_empty(): return replacement
	if tier >= 3 and live >= 8.0 and not present.has("DRAGON_ROOST"):
		return Outposts.placement(world, "DRAGON_ROOST", Vector2i(base.position))
	if tier >= 2 and live >= 8.0 and not present.has("FOUNDRY"):
		return Outposts.placement(world, "FOUNDRY", Vector2i(base.position))
	if not base.get("base_upgrade", {}).is_empty(): return {}
	# Funding and surviving troops, not a wall-clock-only rush, trigger tiers.
	# Retain one basic reinforcement budget; expensive upgrades cannot consume
	# a depleted army's last cash. The normal caller/Host revalidates the quote.
	var next_tier := tier + 1
	if next_tier > 3: return {}
	var due := elapsed >= 600 and live >= 8.0 if next_tier == 2 else elapsed >= 1600 and live >= 14.0
	if not due: return {}
	var cost := int(Progression.BASE_UPGRADES.get(next_tier, {}).get("cost", {}).get("MATERIAL", 0))
	if cost <= 0 or gold < cost + 150: return {}
	for building: Dictionary in world.get("buildings", []):
		if building.get("side") == "AI" and building.get("building_type") == "BASE" and int(building.get("hp", 0)) > 0 and not building.get("base_upgrade", {}).is_empty(): return {}
	return {"type":"UPGRADE_BASE", "building_id":base.id}
