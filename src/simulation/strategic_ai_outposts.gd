extends RefCounted
## Read-only adapter for the fixed-slot/no-worker variant. Ownership, prices,
## completion, resource depletion and payment remain World/Host authority.
const Opportunities = preload("res://src/simulation/strategic_ai_opportunities.gd")
const OutpostRulesR9 = preload("res://src/simulation/strategic_outpost_rules.gd")
const ECONOMIC_TARGET_LINES_R9 := 2
const ECONOMIC_TARGET_GROSS_R9 := 24.0
const ECONOMIC_COMMITTED_CAP_R9 := 3

static func enabled(world: Dictionary) -> bool:
	return bool(world.get("outpost_mode", false))


static func building_operational(world: Dictionary, building: Dictionary) -> bool:
	# A surviving body is not a usable factory/service after its point loses
	# complete control. Mirror World authority from read-only published facts;
	# never invent ownership from the building's unchanged side alone.
	if not enabled(world):return true
	var site_id:=str(building.get("site_id",""))
	var side:=str(building.get("side",""))
	if site_id.is_empty() or side.is_empty():return false
	for site:Dictionary in world.get("sites",[]):
		if str(site.get("id",""))==site_id:
			return site.get("owner","")==side and site.get("capture_side","")==side and int(site.get("progress",0))>=int(site.get("threshold",200))
	return false


static func is_resource_site(site: Dictionary) -> bool:
	return str(site.get("kind", "")) in ["RESOURCE", "SATELLITE"]


static func income_building(site: Dictionary) -> String:
	if not is_resource_site(site): return ""
	return "ESSENCE_MINE" if site.get("kind") == "SATELLITE" or site.get("resource") == "ESSENCE" else "BASE"


static func slot_for_order(world: Dictionary, order: Dictionary) -> Dictionary:
	if order.get("type") != "PLACE_BUILDING" or not order.has("position"): return {}
	for slot: Dictionary in world.get("building_slots", []):
		if order.get("building_type") in slot.get("allowed_building_types",[slot.get("building_type")]) and Vector2i(slot.get("position", Vector2i.ZERO)) == Vector2i(order.position):
			if slot.get("side") == "AI" and bool(slot.get("available", false)) and not bool(slot.get("occupied", false)):
				return slot
	return {}


static func placement(world: Dictionary, kind: String, origin: Vector2i) -> Dictionary:
	var wanted_site := ""
	# A request to service a captured resource must not quietly pick a slot at
	# a different holding and label that other payment as expansion progress.
	if kind in ["BASE", "ESSENCE_MINE"]:
		var nearest := 9223372036854775807
		for site: Dictionary in world.get("sites", []):
			if income_building(site) != kind or site.get("owner") != "AI": continue
			var distance: int = (Vector2i(site.get("position", Vector2i.ZERO)) - origin).length_squared()
			if distance < nearest:
				nearest = distance
				wanted_site = str(site.get("id", ""))
		if wanted_site.is_empty(): return {}
	var best: Dictionary = {}
	var best_distance := 9223372036854775807
	for slot: Dictionary in world.get("building_slots", []):
		if slot.get("side") != "AI" or kind not in slot.get("allowed_building_types",[slot.get("building_type")]) or bool(slot.get("occupied", false)) or not bool(slot.get("available", false)): continue
		if not wanted_site.is_empty() and str(slot.get("site_id", "")) != wanted_site: continue
		var distance: int = (Vector2i(slot.get("position", Vector2i.ZERO)) - origin).length_squared()
		if distance < best_distance or distance == best_distance and str(slot.get("id", "")) < str(best.get("id", "")):
			best = slot
			best_distance = distance
	if best.is_empty(): return {}
	# Host's existing command schema intentionally stays unchanged. The exact
	# position/type resolves the authoritative slot; clients supply no quote,
	# ownership, construction duration or worker-free bypass flag.
	return {"type":"PLACE_BUILDING", "building_type":kind, "position":Vector2i(best.position)}


static func source_remaining(world: Dictionary, site_id: String, resource: String = "") -> int:
	var remaining := 0
	for source: Dictionary in world.get("resource_sources", []):
		if str(source.get("site_id", "")) != site_id: continue
		if not resource.is_empty() and str(source.get("resource", source.get("kind", ""))) != resource: continue
		remaining += maxi(0, int(source.get("remaining", source.get("remaining_amount", 0))))
	return remaining


static func needs_income_building(world: Dictionary, site: Dictionary) -> bool:
	var kind := income_building(site)
	if kind.is_empty() or site.get("owner") != "AI" or bool(site.get("income_active", false)): return false
	if site.get("capture_side", "") != "AI": return false
	if int(site.get("progress", 0)) < int(site.get("threshold", 100)): return false
	if int(site.get("neutral_guard_count", 0)) > 0: return false
	if source_remaining(world, str(site.get("id", ""))) <= 0: return false
	for slot: Dictionary in world.get("building_slots", []):
		if slot.get("site_id") == site.get("id") and slot.get("building_type") == kind and slot.get("side") == "AI" and bool(slot.get("available", false)) and not bool(slot.get("occupied", false)): return true
	return false


static func income_action(world: Dictionary) -> Dictionary:
	# A captured source is not productive until its own paid economic body is
	# finished. Make that handoff an ordinary economic task; the caller still
	# shares its original command and money budgets with combat and recruitment.
	# Existing blueprints occupy their exact pad, so repeated decisions never
	# request a second mine or restart already progressing construction.
	var best: Dictionary = {}
	var best_score := -INF
	for site: Dictionary in world.get("sites", []):
		if not needs_income_building(world, site): continue
		if Opportunities.local_enemy_power(world, site.position) > 0 or Opportunities.fortification_pressure(world, site.position) > 0: continue
		var order := placement(world, income_building(site), Vector2i(site.position))
		if order.is_empty(): continue
		var quote := slot_for_order(world, order)
		var price := maxi(1, int(quote.get("cost", {}).get("MATERIAL", 0)))
		var rate := float(OutpostRulesR9.rate_twentieths(site, "MATERIAL"))
		var score := rate / float(price)
		if score > best_score or is_equal_approx(score, best_score) and str(site.get("id", "")) < str(best.get("site_id", "")):
			best_score = score
			best = {"site_id":site.id, "order":order}
	return best.get("order", {}).duplicate(true)


static func income_summary(world: Dictionary) -> Dictionary:
	var rates := {"FOOD":0.0, "MATERIAL":0.0, "ESSENCE":0.0}
	var active_sites: Array[String] = []
	var pending_sites: Array[String] = []
	for site: Dictionary in world.get("sites", []):
		if site.get("owner") != "AI" or not is_resource_site(site): continue
		if needs_income_building(world, site): pending_sites.append(str(site.get("id", "")))
		if not bool(site.get("income_active", false)): continue
		active_sites.append(str(site.get("id", "")))
		# Prefer site's complete net projection, never sum it with its sources.
		# These values are diagnostic priorities, not payable or reserved money.
		if site.has("net_rates"):
			for resource: String in rates: rates[resource] += float(site.net_rates.get(resource, 0.0))
		else:
			for source: Dictionary in world.get("resource_sources", []):
				if source.get("site_id") != site.get("id") or not bool(source.get("income_active", false)): continue
				var resource := str(source.get("resource", source.get("kind", "")))
				if rates.has(resource): rates[resource] += float(source.get("net_rates", {}).get(resource, 0.0))
	return {"mode":"AUTOMATIC_SITE_INCOME", "net_rates":rates, "active_site_ids":active_sites, "awaiting_income_building_ids":pending_sites, "worker_goal":0, "worker_commands":false, "read_only":true}


static func resource_urgent(world: Dictionary) -> bool:
	var income := income_summary(world)
	if float(income.net_rates.MATERIAL) <= 0.0: return true
	var remaining := 0
	var gross_rate:=0.0
	for source: Dictionary in world.get("resource_sources", []):
		if source.get("owner") != "AI" or not bool(source.get("income_active", false)): continue
		var resource := str(source.get("resource", source.get("kind", "")))
		if resource == "MATERIAL":
			remaining += maxi(0, int(source.get("remaining", source.get("remaining_amount", 0))))
			gross_rate+=float(source.get("gross_rates",{}).get("MATERIAL",source.get("net_rates",{}).get("MATERIAL",0)))
	# Remaining productive time is scale-independent; a larger V3 deposit
	# must not look urgent merely because an old absolute threshold was used.
	return float(remaining)/maxf(.001,gross_rate) < 60.0


static func economic_expansion_status(world: Dictionary) -> Dictionary:
	# Development demand is NOT a depletion alarm. A45k deposit can last half
	# an hour while its single20/s line still limits replenishment. Count only
	# actual earning holdings or already-paid matching economic blueprints,
	# never cash/claimed empty land/history as current military/economic power.
	var active := 0
	var paid := 0
	var active_gross := 0.0
	var future_gross := 0.0
	var awaiting: Array[String] = []
	var sources_by_site: Dictionary = {}
	for source: Dictionary in world.get("resource_sources", []):
		if str(source.get("resource", source.get("kind", ""))) != "MATERIAL": continue
		var id := str(source.get("site_id", ""))
		if not sources_by_site.has(id): sources_by_site[id] = {"remaining":0, "gross":0.0}
		sources_by_site[id].remaining += maxi(0, int(source.get("remaining", source.get("remaining_amount", 0))))
		if source.get("owner") == "AI" and bool(source.get("income_active", false)):
			sources_by_site[id].gross += maxf(0.0, float(source.get("gross_rates", {}).get("MATERIAL", 0.0)))
	var paid_sites: Dictionary = {}
	for building: Dictionary in world.get("buildings", []):
		if building.get("side") != "AI" or int(building.get("hp", 0)) <= 0 or bool(building.get("complete", false)): continue
		if building.get("building_type") not in ["BASE", "ESSENCE_MINE"] or int(building.get("cost", {}).get("MATERIAL", 0)) <= 0: continue
		paid_sites[str(building.get("site_id", ""))] = str(building.building_type)
	for site: Dictionary in world.get("sites", []):
		if not is_resource_site(site) or site.get("owner") != "AI" or site.get("capture_side") != "AI" or int(site.get("progress", 0)) < int(site.get("threshold", 200)): continue
		var id := str(site.get("id", ""))
		if int(sources_by_site.get(id, {}).get("remaining", 0)) <= 0: continue
		var nominal := float(OutpostRulesR9.rate_twentieths(site, "MATERIAL"))
		if bool(site.get("income_active", false)):
			active += 1
			# Gross, not maintenance-taxed net, prevents a large existing army
			# from creating a permanently unsatisfiable development target.
			active_gross += maxf(nominal, float(sources_by_site.get(id, {}).get("gross", 0.0)))
		elif str(paid_sites.get(id, "")) == income_building(site):
			paid += 1
			future_gross += nominal
		elif needs_income_building(world, site):
			awaiting.append(id)
	var lines := active + paid
	var gross := active_gross + future_gross
	var reason := "MORE_PRODUCTIVE_INCOME_REQUIRED"
	var needed := enabled(world) and (lines < ECONOMIC_TARGET_LINES_R9 or gross < ECONOMIC_TARGET_GROSS_R9)
	if not enabled(world): needed = false; reason = "NOT_OUTPOST_MODE"
	elif not awaiting.is_empty(): needed = false; reason = "BUILD_CAPTURED_LINE_FIRST"
	elif lines >= ECONOMIC_COMMITTED_CAP_R9: needed = false; reason = "FINITE_COMMITTED_LINE_CAP"
	elif not needed: reason = "INITIAL_ECONOMIC_TARGET_MET"
	return {"needed":needed, "reason":reason, "active_lines":active, "paid_unfinished_lines":paid, "committed_lines":lines, "active_gross_per_second":active_gross, "paid_future_gross_per_second":future_gross, "committed_gross_per_second":gross, "awaiting_income_building_ids":awaiting, "target_lines":ECONOMIC_TARGET_LINES_R9, "target_gross_per_second":ECONOMIC_TARGET_GROSS_R9, "committed_line_cap":ECONOMIC_COMMITTED_CAP_R9, "read_only":true}


static func economic_expansion_needed(world: Dictionary) -> bool:
	return bool(economic_expansion_status(world).needed)


static func capture_kind_penalty(site: Dictionary, preferred: String) -> int:
	if site.get("kind") == preferred: return 0
	# A small mine is a real economic expansion, not the legacy scarce-essence
	# detour. Risk/guards remain a separate prerequisite in the owning planner.
	if site.get("kind") == "SATELLITE": return 250000 if preferred == "RESOURCE" else 1200000
	return 1800000


static func growth_value(world: Dictionary, camp: Dictionary, forecast: Dictionary, original: Dictionary, tactic: String) -> Dictionary:
	# Reuse XP sharing, bounty and loot calculations, replacing only the old
	# territory/worker-slot opportunity term. This never adds future income to
	# the forecast's current weapons, HP, ratio or damage.
	var result := original.duplicate(false)
	var unlock := 0.0
	var economic_unlock := 0.0
	var population: Dictionary = world.get("population", {}).get("AI", {})
	for site: Dictionary in world.get("sites", []):
		if site.get("id") != camp.get("site_id") or site.get("owner") == "AI": continue
		var capacity := int(site.get("capacity", 30 if site.get("kind") == "RESOURCE" and site.get("resource") != "ESSENCE" else (10 if site.get("kind") == "VILLAGE" else 0)))
		if capacity > 0: unlock = 22.0
		if is_resource_site(site) and source_remaining(world, str(site.get("id", ""))) > 0:
			unlock = 36.0 if site.get("kind") == "RESOURCE" else 24.0
			if resource_urgent(world) and site.get("resource") != "ESSENCE": unlock += 12.0
			if economic_expansion_needed(world): economic_unlock = 30.0
		if capacity > 0 and int(population.get("maximum", 30)) - int(population.get("used", 0)) - int(population.get("reserved", 0)) < 4: unlock += 20.0
	var old_unlock := float(original.get("territory_unlock_value", 0.0))
	# The original growth module scales the complete reward by doctrine. Undo
	# that scale before replacing its territory term, then apply this variant's
	# corresponding doctrine once (including previously-zero unlock cases).
	var old_scale := 1.25 if tactic == "CREEP_ESSENCE_CONTROL" else (1.20 if tactic == "EXPANSION_BOOM" and old_unlock > 0.0 else (0.85 if tactic == "VANGUARD_RUSH" else 1.0))
	var new_scale := 1.25 if tactic == "CREEP_ESSENCE_CONTROL" else (1.20 if tactic == "EXPANSION_BOOM" and unlock > 0.0 else (0.85 if tactic == "VANGUARD_RUSH" else 1.0))
	var strategic := maxf(0.0, float(original.get("strategic_value", 0.0)) / old_scale - old_unlock + unlock) * new_scale
	var non_neutral := false
	for body: Dictionary in world.get("soldiers", []) + world.get("buildings", []):
		if body.get("id") in forecast.get("enemy_ids", []) and body.get("side") == "PLAYER": non_neutral = true; break
	var floor := 1.0 if strategic >= 45.0 and not non_neutral else 1.08
	# Economic opportunity improves ordering only AFTER the old risk floor is
	# fixed. Never let a lucrative mine lower the required force ratio, losses,
	# observed weapon coverage or maximum clear time.
	strategic += economic_unlock * new_scale
	var dps := float(forecast.get("friendly_damage", 0.0)) / maxf(0.1, float(forecast.get("window_seconds", 8.0)))
	var clear_seconds := float(original.get("clear_seconds_estimate", 9999.0))
	var travel_seconds := float(original.get("travel_seconds_estimate", 9999.0))
	result["territory_unlock_value"] = unlock + economic_unlock
	result["economic_expansion_value"] = economic_unlock
	result["strategic_value"] = strategic
	result["risk_floor"] = floor
	result["utility"] = (strategic + float(original.get("maintenance_pressure_value", 0.0))) / maxf(0.1, 8.0 + travel_seconds + clear_seconds) - float(forecast.get("friendly_loss_fraction", 1.0)) * 1.5
	result["safe"] = not bool(forecast.get("truncated", false)) and int(forecast.get("friendly_count", 0)) > 0 and dps > 0.0 and float(forecast.get("ratio", 0.0)) >= floor and float(forecast.get("friendly_loss_fraction", 1.0)) <= 0.50 and clear_seconds <= 35.0
	result["opportunity_mode"] = "AUTOMATIC_SITE_INCOME_NOT_WORKER_SLOTS"
	return result
