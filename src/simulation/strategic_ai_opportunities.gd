extends RefCounted
## Read-only opportunity/risk estimates, never combat or economy authority.
## Inputs are the controller's current detached observations. No resources,
## damage, visibility or unit commands are manufactured here.
const LOCAL_RADIUS := 420
const RAID_OBSERVATION_RADIUS := 900

static func body_power(body: Dictionary) -> int:
	if not bool(body.get("alive", true)) or int(body.get("hp", body.get("max_hp", 0))) <= 0: return 0
	var hp := int(body.get("hp", body.get("max_hp", 0)))
	var offense := int(body.get("damage", 0)) * 160 / maxi(1, int(body.get("attack_cooldown_ticks", 20)))
	return hp + offense + int(body.get("armor", 0)) * 12 + mini(80, int(body.get("attack_range", 0)) / 2)

static func army_power(world: Dictionary, id: String) -> int:
	var result := 0
	for body: Dictionary in world.get("soldiers", []):
		if body.get("side") == "AI" and body.get("warband_id") == id: result += body_power(body)
	return result

static func local_enemy_power(world: Dictionary, position: Vector2i, radius: int = LOCAL_RADIUS) -> int:
	var result := 0
	for body: Dictionary in world.get("soldiers", []):
		if body.get("side") != "PLAYER" or not bool(body.get("visible", true)): continue
		if (Vector2i(body.position) - position).length_squared() <= radius * radius: result += body_power(body)
	return result

static func fortification_pressure(world: Dictionary, position: Vector2i, extra_radius: int = 100) -> int:
	var result := 0
	for building: Dictionary in world.get("buildings", []):
		if building.get("side") != "PLAYER" or int(building.get("hp", 0)) <= 0 or not bool(building.get("complete", false)): continue
		if not bool(building.get("defense_active", false)): continue
		var reach := int(building.get("attack_range", 0)) + extra_radius
		if reach <= extra_radius or (Vector2i(building.position) - position).length_squared() > reach * reach: continue
		# Eight seconds of real weapon exposure plus a small durability/repair
		# budget. This discourages equal-force tower dives without treating an
		# entire high-HP building as a mobile army that can never be attacked.
		result += int(building.get("damage", 0)) * 160 / maxi(1, int(building.get("attack_cooldown_ticks", 20))) + int(building.hp) / 12
	return result

static func camp_power(world: Dictionary, site_id: String) -> int:
	for camp: Dictionary in world.get("neutral_camps", []):
		if camp.get("site_id") != site_id or camp.get("state") == "CLEARED": continue
		# The immutable recipe is not the live roster. Actual observations are
		# authoritative for wounds/deaths; do not resurrect the strongest recipe
		# role when remaining_count drops. Legacy detached fixtures without any
		# body ledger retain the explicit conservative recipe fallback below.
		if world.has("micro_neutral_targets") and camp.has("member_ids"):
			var total := 0
			for body: Dictionary in world.micro_neutral_targets:
				if body.get("id") in camp.get("member_ids",[]) and bool(body.get("visible",true)): total += body_power(body)
			return total
		var powers: Array[int] = []
		for member: Dictionary in camp.get("members", []): powers.append(body_power(member.get("profile", {})))
		powers.sort()
		powers.reverse()
		# Public encounter profiles may retain defeated members. Budget only
		# remaining_count, conservatively keeping the strongest remaining roles.
		var total := 0
		for index: int in range(mini(powers.size(), int(camp.get("remaining_count", powers.size())))): total += powers[index]
		return total
	return 0

static func capture_safe(world: Dictionary, army: Dictionary, site: Dictionary) -> bool:
	var own := army_power(world, str(army.id))
	var guards := camp_power(world, str(site.id))
	var defenders := local_enemy_power(world, site.position)
	var towers := fortification_pressure(world, site.position)
	return own > 0 and own * 5 >= (guards + defenders + towers) * 6

static func raid_safe(world: Dictionary, army: Dictionary, worker: Dictionary) -> bool:
	if worker.get("side") != "PLAYER" or int(worker.get("hp", 0)) <= 0 or not bool(worker.get("visible", true)): return false
	if (Vector2i(worker.position) - Vector2i(army.anchor)).length_squared() > RAID_OBSERVATION_RADIUS * RAID_OBSERVATION_RADIUS: return false
	# A raider must not take a tower-assisted even fight or borrow the main
	# army's power from across the map to justify its own isolated dive.
	var risk := local_enemy_power(world, worker.position, 340) + fortification_pressure(world, worker.position, 70)
	return army_power(world, str(army.id)) * 5 >= risk * 7

static func siege_safe(world: Dictionary, army: Dictionary, building: Dictionary) -> bool:
	var own := army_power(world, str(army.id))
	var defenders := local_enemy_power(world, building.position, 500)
	var weapons := fortification_pressure(world, building.position, 180)
	var siege := false
	for body: Dictionary in world.get("soldiers", []):
		if body.get("side") == "AI" and body.get("warband_id") == army.id and bool(body.get("alive", false)) and (body.get("role") == "SIEGE" or int(body.get("attack_range", 0)) > 240): siege = true
	# Siege brings an actual range advantage, not a free damage multiplier.
	var risk := defenders + weapons * (3 if siege else 5) / 5
	return own > 0 and own * 5 >= risk * 6

static func available_source(world: Dictionary, resource: String, served_only: bool = true) -> int:
	# Legacy planner fixtures omitted the finite source ledger; preserve that
	# explicit observation seam without injecting resources into the authority.
	if not world.has("resource_sources"): return 1
	var total := 0
	for source: Dictionary in world.get("resource_sources", []):
		if source.get("owner") != "AI" or str(source.get("resource", source.get("kind", ""))) != resource: continue
		if served_only and not bool(source.get("active", false)): continue
		total += int(source.get("remaining", source.get("remaining_amount", 0)))
	return total
