extends RefCounted
## Actual Magic Book strips, driven only by an observed action phase.
## No animation clock, idle replay, simulation writes or authored damage.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const ROOT := "HAS Magic Book 1.1/"
const SPELLS := {"FireBall":12, "FrostRing":4, "Cure":4, "Shield":4, "EnergyBlast":4, "Contusion":4, "Bless":4, "Bloodlust":4, "MagicArrow":4}
const MAGIC_HEROES := ["ARCANIST", "MOURN_ORACLE", "VOLT_WEAVER", "LEAF_SEER", "RUNE_ORACLE", "ECHO_BINDER"]


static func required_files() -> Dictionary:
	var files: Array[String] = []
	for spell: String in SPELLS:
		files.append(ROOT + spell + "/" + spell + "AllFrames.png")
		files.append(ROOT + spell + "/Icon" + spell + ".png")
	files.sort()
	return {"magic":files}


static func inspect(unit: Dictionary, pose: Dictionary) -> Dictionary:
	if not Collection.active() or int(unit.get("hp", 1)) <= 0 or not bool(unit.get("alive", true)): return {"supported":false}
	var action := str(pose.get("action", "IDLE"))
	var skill: Dictionary = pose.get("skill", {})
	var spell := ""
	if action == "ATTACK" and unit.get("unit_type") == "hero" and str(unit.get("hero_archetype", "")) in MAGIC_HEROES: spell = "MagicArrow"
	elif action in ["HEAL", "POTION"]: spell = "Cure"
	elif action.begins_with("SKILL_"):
		var id := action.trim_prefix("SKILL_")
		if id == "STARFIRE": spell = "FireBall"
		elif id == "FROST_BIND": spell = "FrostRing"
		elif id == "ARCANE_BURST": spell = "EnergyBlast"
		else:
			match str(skill.get("effect", "")):
				"HEAL": spell = "Cure"
				"ARMOR_BUFF": spell = "Shield"
				"DAMAGE_BUFF": spell = "Bloodlust"
				"RALLY": spell = "Bless"
				"ROOT": spell = "FrostRing"
				"STUN": spell = "Contusion"
				"DAMAGE":
					# Archer/melee weapon attacks retain their own original trails.
					if id not in ["CLEAVE", "PIERCING_SHOT", "ARROW_RAIN", "WHIRLWIND", "CINDER_SHOT", "GEAR_SHOT", "WIND_SHOT", "EMBER_SWEEP", "SPORE_SWEEP"]: spell = "EnergyBlast"
	if spell.is_empty(): return {"supported":false}
	var phase := float(pose.get("phase", 0.0))
	if not is_finite(phase) or phase < 0 or phase >= 1: return {"supported":false}
	var count := int(SPELLS[spell])
	var frame := clampi(int(phase * count), 0, count - 1)
	var file := ROOT + spell + "/" + spell + "AllFrames.png"
	var pixels: Image = Collection.image("magic", file)
	if pixels == null: return {"supported":false}
	var rect := Rect2i(frame * 24, 0, 24, 24)
	if not Rect2i(Vector2i.ZERO, pixels.get_size()).encloses(rect): return {"supported":false}
	var at_self := action in ["POTION"] or (action.begins_with("SKILL_") and str(skill.get("target_mode", "")) == "SELF")
	return {"supported":true, "provenance":"licensed", "pack":"magic", "file":file, "spell":spell, "frame":frame, "frames":count, "rect":rect, "anchor":Vector2(12, 16), "phase":phase, "at_self":at_self, "projectile":spell == "MagicArrow", "rank":clampi(int(skill.get("level", 1)), 1, 3), "action":action}


static func draw(canvas: Object, point: Vector2, target: Vector2, unit: Dictionary, pose: Dictionary, factor: float = 1.0) -> bool:
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor <= 0: return false
	var entry := inspect(unit, pose)
	if not bool(entry.get("supported", false)): return false
	var center := point if bool(entry.at_self) else target
	if bool(entry.projectile): center = (point + Vector2(0, -16) * factor).lerp(target, float(entry.phase))
	# This is a local impact sprite, not an assertion of the skill's range.
	var scale_factor := (2.1 + 0.22 * (int(entry.rank) - 1)) * factor
	return Collection.draw_region(canvas, "magic", str(entry.file), entry.rect, center, entry.anchor, scale_factor, Color.WHITE)


static func debug_stats() -> Dictionary:
	return {"active":Collection.active(), "spell_strips":SPELLS.size(), "frame_cell":Vector2i(24, 24), "texture_bytes":0, "cpu_pixel_bytes":0, "owner_atlas_copies":0, "animation_clock":"observed_phase_only", "shared_collection_textures":true}
