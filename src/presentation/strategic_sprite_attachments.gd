extends RefCounted
## Weapon/work sockets in the original M24 source-pixel coordinate system.
## Input is the SAME normalized unit and quantized pose sent to the painters.
## Output is foot-relative and right-facing; the caller alone mirrors/scales.
## No painter/cache import: attachments cannot create a presentation cycle.
## Points sit on visible equipment pixels, slightly inside sharp polygon tips.
const ORDINARY_IDS := ["worker", "hinge_guard", "bright_crossbow", "iron_lancer", "grove_mender", "oath_cavalry", "ash_guard", "bone_archer", "stitched_guard", "ember_mender", "rivet_guard", "shard_gunner", "gear_engine", "repair_drone", "vine_guard", "leaf_archer", "stag_rider", "root_mender", "ridge_guard", "stone_slinger", "fire_dragon", "rune_keeper", "chitin_guard", "echo_shooter", "tunnel_rider", "spore_mender"]
const HERO_IDS := ["COMMANDER", "BULWARK", "ARCANIST", "RANGER", "DUELIST", "ASH_MARSHAL", "MOURN_ORACLE", "CINDER_STALKER", "COIL_WARDEN", "VOLT_WEAVER", "GEAR_HUNTER", "VINE_WARDEN", "LEAF_SEER", "WIND_COURIER", "RIDGE_JARL", "RUNE_ORACLE", "EMBER_CAVALIER", "TUNNEL_SENTINEL", "ECHO_BINDER", "SPORE_STALKER"]


static func ordinary_ids() -> PackedStringArray:
	return PackedStringArray(ORDINARY_IDS)


static func hero_ids() -> PackedStringArray:
	return PackedStringArray(HERO_IDS)


static func offset(unit: Dictionary, pose: Dictionary) -> Vector2:
	var action := str(pose.get("action", "IDLE"))
	# Fallen bodies have no active firing/work socket. The zero point is only
	# a safe geometry result; action admission must suppress effects as before.
	if action == "FALLEN": return Vector2.ZERO
	var phase := float(pose.get("phase", 0.0))
	if not is_finite(phase): phase = 0.0
	phase = clampf(phase, 0.0, 1.0)
	var pulse := sin(phase * PI)
	if str(unit.get("unit_type", "hinge_guard")) == "hero":
		var id := str(unit.get("hero_archetype", "COMMANDER"))
		if id not in HERO_IDS: id = "COMMANDER"
		var strike := roundi(pulse * 5.0) if action == "ATTACK" else 0
		var lift := roundi(pulse * 4.0) if action.begins_with("SKILL_") or action == "HEAL" else 0
		return _hero(id, strike, lift)
	var type := str(unit.get("unit_type", "hinge_guard"))
	var exert := roundi(pulse * 6.0) if action in ["ATTACK", "HEAL", "HARVEST", "MINE", "BUILD"] else 0
	var large_strike := roundi(pulse * 7.0) if action == "ATTACK" else 0
	var swing := int(exert / 2)
	var recoil := -int(exert / 2)
	match type:
		"worker": return _worker(unit, action, exert)
		# strategic_troop_sprite_art: the visible steel tip ends at (15+e,-34+e).
		"hinge_guard": return Vector2(15 + exert, -34 + exert)
		# Crossbow's forward bolt rail, not its rear trigger hand.
		"bright_crossbow": return Vector2(22 + recoil, -21)
		# Interior of the tall steel pike, following its half-exert horizontal shift.
		"iron_lancer": return Vector2(16 + swing, -50)
		"grove_mender": return Vector2(20, -35 - exert) # Crook's glass lantern.
		# strategic_creature_sprite_art: moving lance shaft immediately at its head.
		"oath_cavalry": return Vector2(40 + large_strike, -56 + large_strike)
		"ash_guard": return Vector2(16 + exert, -32 + exert) # Hooked bone blade.
		"bone_archer": return Vector2(23 + recoil, -20) # Drawn arrow's forward end.
		"stitched_guard": return Vector2(36 + large_strike, -40 - large_strike) # Skull hammer's edge.
		"ember_mender": return Vector2(24, -39 - exert) # Needle-staff's hook end.
		"rivet_guard": return Vector2(21 + swing, -30 + exert) # Piston hammer face.
		"shard_gunner": return Vector2(25 + recoil, -20) # Black barrel mouth.
		"gear_engine": return Vector2(45 - large_strike, -33) # Recoiling cannon mouth.
		"repair_drone": return Vector2(11, -36 - exert) # Raised repair claw, not ground leg.
		"vine_guard": return Vector2(20 + swing, -29 + exert) # Leafwood axe head.
		"leaf_archer": return Vector2(25 + recoil, -22) # Longbow's steel arrow end.
		"stag_rider": return Vector2(35 + large_strike, -47) # Thrusting leaf spear's metal head.
		"root_mender": return Vector2(18, -34 - exert) # Suspended bud lantern.
		"ridge_guard": return Vector2(20 + swing, -32 + exert) # Broad stone hammer face.
		# The stone pouch in this recipe stays fixed as the observed sling arm rises.
		"stone_slinger": return Vector2(24, -32)
		"fire_dragon": return Vector2(38 + large_strike, -40 + int(large_strike / 2)) # Opening mouth.
		"rune_keeper": return Vector2(16, -43 - exert) # Brazier's pale core.
		"chitin_guard": return Vector2(24, -28 - exert) # Extended right foreclaw.
		"echo_shooter": return Vector2(22 + recoil, -20) # Resonator's front, still ARROW rules.
		"tunnel_rider": return Vector2(34 + large_strike, -57 + int(large_strike / 2)) # Crystal lance head.
		"spore_mender": return Vector2(17, -37 - exert) # Raised spore-staff core.
	return Vector2.ZERO


static func _worker(unit: Dictionary, action: String, exert: int) -> Vector2:
	var working := action in ["HARVEST", "MINE", "BUILD"]
	var role := str(unit.get("role", "RESERVE"))
	# This branch order mirrors the worker painter: an observed work action
	# chooses its true tool even when the assignment field has not yet changed.
	if action == "HARVEST" or (not working and role == "FOOD"):
		return Vector2(22 - exert, -14 - exert) # Curved sickle's inner blade.
	if action == "BUILD" or (not working and role == "CONSTRUCTION_REPAIR"):
		return Vector2(22 - exert, -32 - exert) # Broad hammer's metal face.
	return Vector2(23 - exert, -32 - exert) # Default/material pick's bright tip.


static func _hero(id: String, strike: int, lift: int) -> Vector2:
	# All twenty real masters are named explicitly. Faction/role never selects
	# a generic humanoid socket that would miss their different weapons.
	match id:
		"COMMANDER": return Vector2(19, -42 - strike) # Long map-commander sword's steel edge.
		"BULWARK": return Vector2(19, -33 - strike) # Shorter guard sword.
		"ARCANIST": return Vector2(20, -55 - lift) # Violet staff crystal; shaft's attack shift is separate.
		"RANGER": return Vector2(23 - strike, -20) # Bow(14,-43,2): arrowhead, midpoint truncates -20.
		"DUELIST": return Vector2(18, -36 - strike) # Forward sword, not trailing offhand blade.
		"ASH_MARSHAL": return Vector2(23, -35 - strike) # Tall cleaver's bright outer edge.
		"MOURN_ORACLE": return Vector2(20, -50 - lift) # Curved bone staff's teal core.
		"CINDER_STALKER": return Vector2(23 - strike, -22) # Bow(14,-48,4): bone arrowhead.
		"COIL_WARDEN": return Vector2(25, -39 - strike) # Copper hammer's steel face.
		"VOLT_WEAVER": return Vector2(26, -59 - lift) # Right fork's bright coil tip.
		"GEAR_HUNTER": return Vector2(26 - strike, -26) # Recoiling long rifle's visible muzzle.
		"VINE_WARDEN": return Vector2(22, -38 - strike) # Living axe's pale edge.
		"LEAF_SEER": return Vector2(19, -52 - lift) # Branch staff's bud crystal.
		"WIND_COURIER": return Vector2(24 - strike, -22) # Bow(15,-47,2): moving arrowhead.
		"RIDGE_JARL": return Vector2(25, -40 - strike) # Forged warhammer's front face.
		"RUNE_ORACLE": return Vector2(22, -51 - lift) # Raised runestone's luminous carved line.
		"EMBER_CAVALIER": return Vector2(23, -44 - strike) # Curved greatblade's highlighted edge.
		"TUNNEL_SENTINEL": return Vector2(20 + strike, -47) # Pale pike tip shifts horizontally.
		"ECHO_BINDER": return Vector2(26, -59 - lift) # Right tuning prong.
		"SPORE_STALKER": return Vector2(24, -40 - strike) # Raised right sickle-claw.
	return Vector2.ZERO
