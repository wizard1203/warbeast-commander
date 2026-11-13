extends RefCounted
## Original editable pixel-world assets, distinct from tiny HUD symbols.
## All routines use supplied values and bounded primitives/cached sprites. They never
## mutate observations, settle damage, create obstacles or query game authority.
## Object rather than Node2D permits a texture-aware Recorder in deterministic tests.

const INK := Color("18252a")
const SHADOW := Color(0.025, 0.04, 0.045, 0.46)
const STONE := Color("899e9d")
const STONE_LIGHT := Color("c4cec0")
const STONE_DARK := Color("4f686b")
const WOOD := Color("ab8059")
const WOOD_DARK := Color("64503d")
const SKIN := Color("dfba87")
const GOLD := Color("dfc577")
const LEAF := Color("8db970")
const TEAL := Color("68c9c0")
const BUILDING_DRAW_SCALE := 1.12
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const UnitSprites = preload("res://src/presentation/strategic_unit_sprites.gd")
const GroundMaterial = preload("res://src/presentation/strategic_ground_material.gd")
const EnvironmentMaterial = preload("res://src/presentation/strategic_environment_material.gd")
const BuildingMaterial = preload("res://src/presentation/strategic_building_material.gd")
const BuildingArt = preload("res://src/presentation/strategic_faction_building_art.gd")
const MaterialEffects = preload("res://src/presentation/strategic_material_effects.gd")
const PrerenderedArt = preload("res://src/presentation/strategic_prerendered_art.gd")
const FrontierArt = preload("res://src/presentation/strategic_frontier_art.gd")
const FrontierCollection = preload("res://src/presentation/strategic_frontier_collection.gd")
const HeroicUnits = preload("res://src/presentation/heroic_pixel_units.gd")
const HeroicCanvas = preload("res://src/presentation/heroic_2d_world_canvas.gd")


static func heroic_route() -> bool:
	# HUD cards use the same original pixel bodies as the new battlefield.
	# Explicit old launch flags retain their original artwork for comparison.
	var args := OS.get_cmdline_user_args()
	return not ("--legacy-2d" in args or "--frontier-art" in args or "--classic-art" in args or "--frontier-3d" in args)


static func unit_visual_bounds(unit: Dictionary, screen_radius: float) -> Rect2:
	if heroic_route(): return HeroicUnits.visual_bounds(unit, screen_radius)
	return UnitSprites.visual_bounds(unit,screen_radius)


static func draw_unit(canvas: Object, center: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> void:
	if not center.is_finite() or not is_finite(radius) or radius<=0: return
	if heroic_route():
		HeroicUnits.draw(canvas, center, unit, radius, pose)
		return
	if FrontierArt.draw_unit(canvas,center,unit,radius,pose): return
	if PrerenderedArt.draw_unit(canvas,center,unit,radius,pose): return
	# Ground shadow remains anchored to the real foot. The detailed body uses
	# one cached texture; no legacy body is hidden behind recorder detection.
	canvas.draw_rect(Rect2(center.round()+Vector2(-radius*1.1,radius*0.3),Vector2(radius*2.2,radius*0.42)),SHADOW)
	UnitSprites.draw(canvas,center,unit,radius,pose)


static func draw_action_effect(canvas: Object, center: Vector2, target: Vector2, unit: Dictionary, pose: Dictionary, world_scale: float) -> void:
	var action := str(pose.get("action", "IDLE"))
	var phase := float(pose.get("phase", 0))
	var color := _faction(str(unit.get("side", "")))
	var fade := clampf(1.0 - phase, 0.0, 1.0)
	var type := str(unit.get("unit_type", ""))
	if action.begins_with("SKILL_"):
		_draw_ranked_skill(canvas, center, target, pose, world_scale)
		return
	if action == "ATTACK":
		MaterialEffects.draw_attack(canvas,center,unit,pose,target,world_scale)
		# Ordinary attacks reset last_action_radius to zero. Only a real splash
		# recipe and a published eligible primary target may show this effect;
		# hero skill radii remain in their separate ranked-skill branch above.
		var splash_radius := float(unit.get("last_action_radius", 0))
		if splash_radius <= 0: splash_radius = float(unit.get("splash_radius", 0))
		var splash_layers: Array = unit.get("splash_layers", [])
		if splash_radius > 0 and int(unit.get("splash_damage", 0)) > 0 and str(unit.get("last_action_target_layer", "")) in splash_layers:
			canvas.draw_arc(target, splash_radius * world_scale * (0.35 + phase * 0.65), 0, TAU, 24, Color(0.95, 0.71, 0.32, fade), maxf(world_scale, 1))
	elif action == "HEAL":
		canvas.draw_line(MaterialEffects.weapon_source(center,unit,pose,target,world_scale), target, Color(0.4, 0.8, 0.61, fade * 0.5), maxf(world_scale * 2, 1))
		_cross(canvas, target + Vector2(0, -20 - phase * 16) * world_scale, 6 * world_scale, Color(0.55, 0.95, 0.68, fade))
	elif action == "POTION":
		canvas.draw_arc(center, (12 + 24 * phase) * world_scale, 0, TAU, 16, Color(TEAL if action == "POTION" else LEAF, fade), maxf(world_scale * 2, 1))
		_cross(canvas, center + Vector2(0, -22 - phase * 18) * world_scale, 6 * world_scale, Color(TEAL if action == "POTION" else LEAF, fade))


static func _draw_ranked_skill(canvas: Object, center: Vector2, target: Vector2, pose: Dictionary, scale_factor: float) -> void:
	var skill: Dictionary = pose.get("skill", {})
	if skill.is_empty(): return
	var phase := clampf(float(pose.get("phase", 0)), 0, 1)
	var fade := 1.0 - phase
	var rank := clampi(int(skill.get("level", 1)), 1, 3)
	var effect := str(skill.get("effect", "DAMAGE"))
	var id := str(skill.get("id", ""))
	var radius := maxf(float(skill.get("radius", 0)), 0) * scale_factor
	var origin := center if skill.get("target_mode") == "SELF" else target
	var hue := Color("94d8ef") if effect == "ROOT" else GOLD if effect == "STUN" else LEAF if effect == "HEAL" else TEAL if effect in ["ARMOR_BUFF", "DAMAGE_BUFF", "RALLY"] else Color("b5a0ee") if id in ["STARFIRE", "ARCANE_BURST"] else Color("efbb78")
	var ring := radius * (0.3 + phase * 0.7) if radius > 0 else (12 + 15 * phase) * scale_factor
	var width := maxf((1.5 + rank * 0.6) * scale_factor, 1)
	canvas.draw_arc(origin, ring, 0, TAU, 32, Color(hue, fade * 0.8), width)
	# Extra concentric traces and particles encode rank, never a larger damage
	# area: every area trace and particle remains inside the published radius.
	for layer: int in range(rank):
		canvas.draw_arc(origin, ring * (1.0 - layer * 0.14), 0, TAU, 24, Color(hue, fade * 0.35), maxf(scale_factor, 1))
		for ray: int in range(2):
			var angle := ray * PI + phase * 1.4 + layer * 0.25
			var radial := Vector2.from_angle(angle)
			var point := origin + radial * ring * 0.75
			canvas.draw_line(point - radial * minf(8 * scale_factor, ring * 0.15), point, Color(hue, fade), width)
	if effect == "HEAL":
		_cross(canvas, center + Vector2(0, -22 - phase * 18) * scale_factor, (5 + rank) * scale_factor, Color(hue, fade))
	elif effect == "ROOT":
		for n: int in range(4):
			var offset := Vector2.from_angle(n * PI * 0.5) * radius * 0.3
			canvas.draw_line(origin + offset + Vector2(-5, -7) * scale_factor, origin + offset + Vector2(5, 7) * scale_factor, Color(hue, fade), width)
	elif effect == "STUN":
		for n: int in range(4):
			var radial := Vector2.from_angle(n * PI * 0.5 + phase)
			canvas.draw_line(origin + radial * ring * 0.4, origin + radial.rotated(0.4) * ring * 0.8, Color(hue, fade), width)
	elif effect in ["ARMOR_BUFF", "DAMAGE_BUFF", "RALLY"]:
		_cross(canvas, origin, (6 + rank) * scale_factor, Color(hue, fade))
	elif id in ["PIERCING_SHOT", "ARROW_RAIN"]:
		for n: int in range(1 + rank):
			var point := origin + Vector2.from_angle(n * 2.4) * radius * 0.35
			canvas.draw_line(point + Vector2(0, -minf(radius * 0.3, 24 * scale_factor)), point, Color(hue, fade), width)
	else:
		canvas.draw_line(center, target, Color(hue, fade * 0.45), width)
		canvas.draw_arc(origin, ring * 0.8, -PI * 0.9 + phase, PI * 0.9 + phase, 20, Color(hue, fade), width + scale_factor)


static func draw_hero_portrait(canvas: Object, rect: Rect2, archetype: String, alive: bool = true) -> void:
	if heroic_route():
		var unit := {"unit_type":"hero", "hero_archetype":archetype, "side":"PLAYER", "alive":alive, "hp":1 if alive else 0}
		# M40: use the canonical pixel identity in every in-game portrait too.
		# M38's separately illustrated headshots remain preserved, not selected.
		var pose := {"action":"IDLE", "direction":Vector2.RIGHT, "phase":0.0, "animation_tick":0}
		var bounds := HeroicUnits.visual_bounds(unit, 12, pose)
		var fit := minf(rect.size.x / maxf(bounds.size.x, 1), rect.size.y / maxf(bounds.size.y, 1))
		HeroicUnits.draw(canvas, rect.get_center() - bounds.get_center() * fit, unit, 12 * fit, pose)
		return
	UnitSprites.draw_portrait(canvas,rect,archetype,alive)


static func draw_control_status(canvas: Object, center: Vector2, unit: Dictionary, world_scale: float) -> void:
	if int(unit.get("hp", 0)) <= 0: return
	var statuses: Array = unit.get("status_effects", [])
	for value: Variant in statuses.slice(0, 2):
		if not value is Dictionary or int(value.get("remaining_ticks", 0)) <= 0: continue
		var kind := str(value.get("id", value.get("kind", "")))
		if kind == "STUN":
			var top := center + Vector2(0, -32) * world_scale
			for index: int in range(3):
				_cross(canvas, top + Vector2((index - 1) * 8, abs(index - 1) * 3) * world_scale, 2.5 * world_scale, GOLD)
		elif kind == "ROOT":
			canvas.draw_arc(center, 16 * world_scale, 0, TAU, 16, Color("b99de4"), maxf(world_scale, 1))
			for index: int in [-1, 1]:
				canvas.draw_line(center + Vector2(index * 8, 7) * world_scale, center + Vector2(index * 5, -8) * world_scale, Color("b99de4"), maxf(world_scale * 2, 1))


static func draw_feedback_mark(canvas: Object, center: Vector2, mark: Dictionary, scale_factor: float = 1) -> void:
	var life := maxf(float(mark.get("lifetime", 1)), 0.01)
	var progress := clampf(float(mark.get("age", 0)) / life, 0, 1)
	if progress >= 1: return
	var kind := str(mark.get("kind", ""))
	var color := Color("e99b80") if kind == "REJECT" else Color("edc477") if kind in ["ATTACK_MOVE", "ATTACK", "BUILD"] else Color("9ed6c7") if kind == "MOVE" else Color("c3abe9") if kind == "CAST" else GOLD
	color.a = 1 - progress
	var radius := (12 + 7 * progress) * scale_factor
	match kind:
		"MOVE":
			canvas.draw_arc(center, radius, 0, TAU, 20, color, 2)
			canvas.draw_line(center + Vector2(-4, -4) * scale_factor, center + Vector2(0, -8) * scale_factor, color, 2)
			canvas.draw_line(center + Vector2(0, -8) * scale_factor, center + Vector2(4, -4) * scale_factor, color, 2)
		"ATTACK_MOVE":
			var points := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
			for index: int in range(4): canvas.draw_line(points[index], points[(index + 1) % 4], color, 2)
			canvas.draw_line(center + Vector2(-5, -5) * scale_factor, center + Vector2(5, 5) * scale_factor, color, 2)
			canvas.draw_line(center + Vector2(5, -5) * scale_factor, center + Vector2(-5, 5) * scale_factor, color, 2)
		"ATTACK":
			canvas.draw_arc(center, radius, 0, TAU, 20, color, 2)
			for index: int in range(4):
				var direction := Vector2.from_angle(index * PI * 0.5)
				canvas.draw_line(center + direction * radius * 0.65, center + direction * radius * 1.3, color, 2)
		"CAST":
			for index: int in range(4):
				var direction := Vector2.from_angle(index * PI * 0.5 + PI * 0.25)
				canvas.draw_line(center + direction * radius * 0.3, center + direction * radius, color, 2)
			canvas.draw_arc(center, radius * 0.5, 0, TAU, 16, color, 2)
		"BUILD":
			canvas.draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2), Color(color, color.a * 0.12))
			for index: int in [-1, 1]:
				canvas.draw_line(center + Vector2(index * radius, -radius), center + Vector2(index * radius, radius), color, 2)
			canvas.draw_line(center + Vector2(-radius, radius), center + Vector2(radius, radius), color, 2)
		"REJECT":
			canvas.draw_line(center + Vector2(-radius, -radius), center + Vector2(radius, radius), color, 3)
			canvas.draw_line(center + Vector2(radius, -radius), center + Vector2(-radius, radius), color, 3)
		"SELECT":
			canvas.draw_arc(center, (20 + 25 * progress) * scale_factor, 0, TAU, 28, color, 2)
		"SUPPORT": _cross(canvas, center, 8 * scale_factor, color)


static func draw_building(canvas: Object, center: Vector2, building: Dictionary, scale_factor: float) -> void:
	var radius := float(building.get("radius", 32))
	if not center.is_finite() or not is_finite(scale_factor) or scale_factor<=0 or not is_finite(radius) or radius<=0: return
	if heroic_route():
		HeroicCanvas.draw_building_sprite(canvas, center, building, scale_factor)
		return
	if FrontierArt.draw_building(canvas,center,building,scale_factor): return
	if PrerenderedArt.draw_building(canvas,center,building,scale_factor): return
	var pixel := maxf(radius * scale_factor / 24.0, 0.1)*BUILDING_DRAW_SCALE
	var origin := center
	var type := str(building.get("building_type", "BASE"))
	var cloth := _faction(str(building.get("side", "")))
	if int(building.get("hp", 0)) <= 0:
		for n: int in range(7):
			_rect(canvas, origin, pixel, Rect2(-22 + n * 6, n % 2 * 3 - 1, 5, 5), STONE_DARK if n % 2 == 0 else WOOD_DARK)
		_rect(canvas, origin, pixel, Rect2(-18, 5, 38, 3), SHADOW)
		return
	if not bool(building.get("complete", false)):
		var progress := clampf(float(building.get("progress",0))/maxf(float(building.get("max_progress",100)),1),0,1)
		if progress<=0: BuildingArt.draw_preview(canvas,center,building,scale_factor)
		else: BuildingArt.draw_progress(canvas,center,building,scale_factor,progress)
		_rect(canvas, origin, pixel, Rect2(-24, 7, 48, 8), SHADOW)
		_draw_scaffold(canvas, origin, pixel, building, cloth)
		BuildingMaterial.draw(canvas,origin,pixel,type,str(building.get("faction_id","HUMAN")))
		return
	BuildingArt.draw(canvas,center,building,scale_factor)


static func building_visual_bounds(building: Dictionary, scale_factor: float) -> Rect2:
	if heroic_route(): return HeroicCanvas.building_visual_bounds(building, scale_factor)
	var frontier := FrontierArt.building_bounds(building,scale_factor)
	if frontier.size != Vector2.ZERO: return frontier
	var preview := PrerenderedArt.building_bounds(building,scale_factor)
	if preview.size != Vector2.ZERO: return preview
	var bounds := BuildingArt.visual_bounds(building,scale_factor)
	if bounds.size==Vector2.ZERO:return bounds
	var pixel := maxf(float(building.get("radius",32))*scale_factor/24.0,0.1)*BUILDING_DRAW_SCALE
	if int(building.get("hp",0))<=0:return Rect2(Vector2(-22,-1)*pixel,Vector2(42,10)*pixel)
	if not bool(building.get("complete",false)):
		bounds=bounds.merge(Rect2(Vector2(-24,-40)*pixel,Vector2(48,60)*pixel))
	return bounds


static func building_body_contains(building: Dictionary, offset: Vector2, scale_factor: float) -> bool:
	# New upper-body inspection is for standing complete art only. Scaffolds
	# keep their existing ground-circle tap, never an invisible future roof.
	if not bool(building.get("complete",false)) or int(building.get("hp",0))<=0:return false
	if bool(FrontierArt.inspect("building",building).get("supported",false)):
		return FrontierArt.building_body_contains(building,offset,scale_factor)
	if bool(PrerenderedArt.inspect("building",building).get("supported",false)):
		return PrerenderedArt.building_body_contains(building,offset,scale_factor)
	return BuildingArt.contains_point(building,offset,scale_factor)


static func draw_resource_source(canvas: Object, center: Vector2, source: Dictionary, scale_factor: float) -> void:
	var frontier_entry := frontier_resource_entry(source)
	if not frontier_entry.is_empty():
		# Owner is supplied by the real site observation, not guessed from the
		# nearest army. Inactive sources stay visible but do not appear serviced.
		var owner := str(source.get("owner", source.get("side", "")))
		var modulate := Color.WHITE if bool(source.get("active", false)) else Color("b8b9b3")
		if FrontierArt.draw_prop(canvas,center,frontier_entry,scale_factor,owner,modulate): return
	var origin := center.round()
	var pixel := maxf(scale_factor, 0.1)
	var active := bool(source.get("active", false))
	var available := int(source.get("remaining", source.get("remaining_amount", source.get("initial", 1)))) > 0
	if source.get("kind") == "FOOD":
		_rect(canvas, origin, pixel, Rect2(-48, -34, 96, 69), Color("49503b"))
		for row: int in range(4):
			var y := -29 + row * 16
			_rect(canvas, origin, pixel, Rect2(-45, y, 90, 12), WOOD_DARK.darkened(0.2))
			for column: int in range(7):
				var x := -40 + column * 13
				if not available: continue
				_rect(canvas, origin, pixel, Rect2(x, y + 2, 2, 10), LEAF.darkened(0.25 if active else 0.55))
				_rect(canvas, origin, pixel, Rect2(x - 3, y + 2, 3, 4), GOLD.darkened(0.15 if active else 0.5))
				_rect(canvas, origin, pixel, Rect2(x + 1, y + 4, 3, 3), LEAF)
		_rect(canvas, origin, pixel, Rect2(32, 28, 20, 10), WOOD_DARK)
		if available: _rect(canvas, origin, pixel, Rect2(34, 29, 16, 7), GOLD.darkened(0.25))
	else:
		# Exposed ore strata and dark shaft mouth read as a mine, not timber.
		_poly(canvas, origin, pixel, [Vector2(-49, 21), Vector2(-43, -16), Vector2(-22, -38), Vector2(16, -40), Vector2(47, -10), Vector2(49, 24)], STONE_DARK)
		_poly(canvas, origin, pixel, [Vector2(-42, 15), Vector2(-34, -18), Vector2(-12, -31), Vector2(19, -29), Vector2(36, -8), Vector2(43, 18)], STONE)
		_poly(canvas, origin, pixel, [Vector2(-34, -16), Vector2(-12, -31), Vector2(-3, -14), Vector2(-19, -5)], STONE_LIGHT)
		_rect(canvas, origin, pixel, Rect2(-14, -8, 29, 29), INK)
		_rect(canvas, origin, pixel, Rect2(-18, -9, 5, 32), WOOD_DARK)
		_rect(canvas, origin, pixel, Rect2(14, -9, 5, 32), WOOD_DARK)
		_rect(canvas, origin, pixel, Rect2(-19, -12, 39, 6), WOOD)
		for n: int in range(5):
			if available: _rect(canvas, origin, pixel, Rect2(-36 + n * 16, -18 + n % 2 * 14, 6, 5), GOLD if active else Color("868579"))
		_rect(canvas, origin, pixel, Rect2(25, 20, 22, 13), WOOD_DARK)
		if available: _rect(canvas, origin, pixel, Rect2(28, 20, 16, 9), STONE_LIGHT)
	if not available:
		_line(canvas, origin, pixel, Vector2(-7, 4), Vector2(7, 18), Color("b7aa8b"), 2)
		_line(canvas, origin, pixel, Vector2(7, 4), Vector2(-7, 18), Color("b7aa8b"), 2)
		_rect(canvas, origin, pixel, Rect2(27, 33, 4, 4), INK)
		_rect(canvas, origin, pixel, Rect2(40, 33, 4, 4), INK)


static func draw_site(canvas: Object, center: Vector2, site: Dictionary, scale_factor: float) -> void:
	var frontier_entry := frontier_site_entry(site)
	if not frontier_entry.is_empty() and FrontierArt.draw_prop(canvas,center,frontier_entry,scale_factor,str(site.get("owner", ""))): return
	var origin := center.round()
	var pixel := maxf(scale_factor, 0.1)
	var cloth := _faction(str(site.get("owner", "")))
	if site.get("kind") == "VILLAGE":
		# Three low dwellings form the actual capturable, non-resource village.
		_draw_hut(canvas, origin + Vector2(-33, -9) * pixel, pixel, cloth)
		_draw_hut(canvas, origin + Vector2(28, -16) * pixel, pixel * 0.9, cloth)
		_draw_hut(canvas, origin + Vector2(4, 24) * pixel, pixel * 0.85, cloth)
	else:
		_rect(canvas, origin, pixel, Rect2(-24, 10, 48, 10), SHADOW)
		_rect(canvas, origin, pixel, Rect2(-23, 6, 46, 6), STONE_DARK)
		_rect(canvas, origin, pixel, Rect2(-17, 2, 34, 6), STONE)
		for x: int in [-26, 23]:
			_rect(canvas, origin, pixel, Rect2(x, -12, 4, 20), WOOD_DARK)
			_rect(canvas, origin, pixel, Rect2(x - 1, -15, 6, 5), STONE)
		_rect(canvas, origin, pixel, Rect2(-5, -4, 10, 7), GOLD.darkened(0.25))
	_flag(canvas, origin, pixel, Vector2(0, -31), cloth)


static func frontier_resource_entry(source: Dictionary) -> String:
	if not FrontierArt.enabled(): return ""
	var available := int(source.get("remaining", source.get("remaining_amount", source.get("initial", 0)))) > 0
	if not available or source.get("kind") not in ["FOOD", "MATERIAL"]: return ""
	var entry_id := "food" if source.get("kind") == "FOOD" else "mine"
	return entry_id if bool(FrontierArt.inspect("prop",entry_id).get("supported",false)) else ""


static func frontier_site_entry(site: Dictionary) -> String:
	if not FrontierArt.enabled() or site.get("kind") != "VILLAGE": return ""
	return "village" if bool(FrontierArt.inspect("prop","village").get("supported",false)) else ""


static func frontier_terrain_entry(terrain: Dictionary) -> String:
	var variant := str(terrain.get("frontier_entry",""))
	if not variant.is_empty() and FrontierCollection.get_entry(variant).get("supported",false): return variant
	if terrain.get("kind") == "MOUNTAIN": return "rock"
	if terrain.get("kind") == "TREE": return "pine" if terrain.get("faction_id") == "HIGHLAND" else "tree_oak"
	return ""


static func draw_ground_theme(canvas: Object, projected: Rect2, viewport: Rect2, map_id: String, scale_factor: float, landscape: Dictionary = {}) -> void:
	GroundMaterial.draw(canvas,projected,viewport,map_id,scale_factor,landscape)

static func homeland_faction_at(world: Vector2,landscape: Dictionary) -> String:
	return GroundMaterial.home_faction_at(world,landscape.get("home_zones",[]))

static func draw_water_union(canvas: Object, projected: Rect2, viewport: Rect2, terrain: Array, scale_factor: float, bounds: Rect2) -> void:
	EnvironmentMaterial.draw_water(canvas,projected,viewport,terrain,scale_factor,bounds)

static func draw_home_material(canvas: Object, center: Vector2, faction: String, scale_factor: float) -> void:
	var hue: Color = {"HUMAN":Color("79705a"), "UNDEAD":Color("685867"), "MACHINE":Color("827461"), "FOREST":Color("467349"), "HIGHLAND":Color("817f76"), "UNDERGROUND":Color("686783")}.get(faction, Color("79705a"))
	var pixel := maxf(scale_factor, 0.1)
	# A low-contrast courtyard/path connects the existing local material
	# clusters; this is decoration, never a navigation graph or new road bonus.
	_poly(canvas,center,pixel,[Vector2(-158,-16),Vector2(-72,-38),Vector2(56,-31),Vector2(151,-3),Vector2(141,22),Vector2(41,12),Vector2(-68,7),Vector2(-145,19)],Color(hue,0.25))
	for index: int in range(12):
		var x := -130+index*23
		var y := -3+(index%3-1)*7
		_rect(canvas,center,pixel,Rect2(x,y,13+index%2*4,4),Color(hue.lightened(0.14),0.38))
	for index: int in range(7):
		var x := -140 + index * 42
		var y := -70 + (index % 3) * 45
		_rect(canvas, center, pixel, Rect2(x, y, 35 + index % 2 * 12, 17), Color(hue, 0.3))
		if faction == "MACHINE":
			_rect(canvas, center, pixel, Rect2(x, y, 30, 14), Color("8c775b", 0.65))
			_line(canvas, center, pixel, Vector2(x, y), Vector2(x + 30, y), Color("b18d65"), 1)
			for rivet: int in [2, 26]: _rect(canvas, center, pixel, Rect2(x + rivet, y + 3, 2, 2), GOLD.darkened(0.25))
			_rect(canvas, center, pixel, Rect2(x + 7, y + 9, 10, 1), Color("b09b78"))
		elif faction == "FOREST":
			for leaf: int in range(3):
				var point := Vector2(x + leaf * 8, y + 3 + leaf % 2 * 8)
				_poly(canvas, center, pixel, [point, point + Vector2(-6,-5), point + Vector2(-2,-9), point + Vector2(4,-3)], Color("80a06a",0.75))
				_line(canvas, center, pixel, point, point + Vector2(1,5), Color("668054"), 1)
		elif faction == "UNDERGROUND":
			_rect(canvas, center, pixel, Rect2(x + 4, y + 5, 3, 9), Color("aaa1b5"))
			_rect(canvas, center, pixel, Rect2(x, y + 3, 11, 4), Color("918aaa"))
			_rect(canvas, center, pixel, Rect2(x + 2, y + 1, 7, 3), Color("b3a4c6"))
			_rect(canvas, center, pixel, Rect2(x + 4, y + 4, 2, 2), TEAL.darkened(0.25))
			_poly(canvas, center, pixel, [Vector2(x+17,y+15),Vector2(x+21,y+5),Vector2(x+28,y+12)], hue.lightened(0.15))
		elif faction == "HIGHLAND":
			_poly(canvas, center, pixel, [Vector2(x,y+15),Vector2(x+16,y-5),Vector2(x+25,y+15)], hue.lightened(0.15))
			_poly(canvas, center, pixel, [Vector2(x+10,y+3),Vector2(x+16,y-5),Vector2(x+20,y+5)], Color("c0c4b4"))
			_line(canvas, center, pixel, Vector2(x+16,y+4), Vector2(x+21,y+13), hue.darkened(0.25), 1)
		elif faction == "UNDEAD":
			_rect(canvas, center, pixel, Rect2(x+2,y+2,18,5), Color("423d43",0.7))
			_line(canvas, center, pixel, Vector2(x+7,y+3), Vector2(x+19,y+11), Color("a2a28d"), 1.5)
			for rib: int in range(3): _line(canvas,center,pixel,Vector2(x+9+rib*3,y+rib*2),Vector2(x+6+rib*3,y+6+rib*2),Color("9c9d8c"),1)
		else:
			_poly(canvas,center,pixel,[Vector2(x,y+12),Vector2(x+3,y+3),Vector2(x+19,y+1),Vector2(x+23,y+11)],Color("8e8970",0.7))
			_line(canvas,center,pixel,Vector2(x+4,y+4),Vector2(x+19,y+3),Color("b0a58b"),1)

static func draw_terrain_ground(canvas: Object, center: Vector2, terrain: Dictionary, scale_factor: float) -> void:
	var kind := str(terrain.get("kind", ""))
	var radius := float(terrain.get("radius", 1)) * scale_factor
	if FrontierArt.enabled() and FrontierCollection.enabled() and kind in ["TREE","MOUNTAIN"]:
		var entry := FrontierCollection.get_entry(str(terrain.get("frontier_entry","")))
		if entry.get("supported",false) and entry.get("kind","") == "obstacle":
			# Painted obstacles already have an authored root/stone silhouette.
			# A single quiet contact shadow replaces the old rectangular plate;
			# its complete outline stays inside the actual circular footprint.
			var shadow := PackedVector2Array()
			for index: int in range(16):
				var angle := float(index)*TAU/16
				shadow.append(center+Vector2(cos(angle)*radius*0.58,sin(angle)*radius*0.18+radius*0.05))
			canvas.draw_colored_polygon(shadow,Color(0.04,0.06,0.04,0.12))
			return
	if kind == "RIVER":
		# Connected physical river circles share a downstream visual direction.
		# Shelves and flow stay INSIDE the actual radius, not a new water wall.
		var shore := PackedVector2Array()
		var water := PackedVector2Array()
		for index: int in range(20):
			var radial := Vector2.from_angle(index * TAU / 20)
			shore.append((center + radial * (radius + 4 * scale_factor)).round())
			water.append((center + radial * radius).round())
		canvas.draw_colored_polygon(shore, Color("827f67"))
		canvas.draw_colored_polygon(water, Color("36667b"))
		var step := maxf(10 * scale_factor, 3)
		for index: int in range(int(radius * 2 / step)):
			var y := -radius + (index + 0.5) * step
			var half_width := sqrt(maxf(radius * radius - y * y, 0))
			var bank := minf(13 * scale_factor, half_width * 0.4)
			if half_width <= 2 * scale_factor: continue
			canvas.draw_rect(Rect2(center + Vector2(-half_width, y), Vector2(bank, step)), Color("658182"))
			canvas.draw_rect(Rect2(center + Vector2(half_width - bank, y), Vector2(bank, step)), Color("4b797b"))
			if index % 3 == 1:
				var x := float(index % 5 - 2) * half_width * 0.19
				var flow := center + Vector2(x, y)
				canvas.draw_line(flow, flow + Vector2(0, minf(step * 1.2, radius - y)), Color("83b1ba"), maxf(scale_factor, 1))
				canvas.draw_line(flow + Vector2(-3, 4) * scale_factor, flow + Vector2(0, 7) * scale_factor, Color("83b1ba"), maxf(scale_factor, 1))
				canvas.draw_line(flow + Vector2(3, 4) * scale_factor, flow + Vector2(0, 7) * scale_factor, Color("83b1ba"), maxf(scale_factor, 1))
		for direction: int in [-1, 1]:
			for index: int in range(3):
				var y := (index - 1) * radius * 0.38
				var half_width := sqrt(maxf(radius * radius - y * y, 0))
				var point := center + Vector2(direction * (half_width - 5 * scale_factor), y)
				canvas.draw_rect(Rect2(point, Vector2(3, 6) * scale_factor), Color("b3a17d"))
	elif kind == "LAKE":
		var shore := PackedVector2Array()
		var water := PackedVector2Array()
		for index: int in range(16):
			var radial := Vector2.from_angle(index * TAU / 16)
			shore.append((center + radial * (radius + 6 * scale_factor)).round())
			water.append((center + radial * radius).round())
		canvas.draw_colored_polygon(shore, Color("8b8972"))
		canvas.draw_colored_polygon(water, Color("3a687d"))
		# Coarse shelves are material inside the true circular shore, not a
		# new movement obstacle or an invented passable bridge.
		var step := maxf(12 * scale_factor, 3)
		for index: int in range(int(radius * 2 / step)):
			var y := -radius + index * step + step * 0.5
			var edge := sqrt(maxf(radius * radius - y * y, 0))
			if edge <= 4 * scale_factor: continue
			var width := minf(18 * scale_factor, edge * 0.45)
			canvas.draw_rect(Rect2(center + Vector2(-edge, y), Vector2(width, step + 1)), Color("557f85"))
			canvas.draw_rect(Rect2(center + Vector2(edge - width, y), Vector2(width, step + 1)), Color("466d72"))
			if index % 2 == 0:
				var x := -edge * 0.5 + float(index % 3) * edge * 0.22
				canvas.draw_rect(Rect2(center + Vector2(x, y), Vector2(minf(22 * scale_factor, edge * 0.55), maxf(scale_factor, 1))), Color("7aa4aa"))
		for index: int in range(5):
			var angle := 0.4 + index * 1.05
			var bank := center + Vector2.from_angle(angle) * (radius + 2 * scale_factor)
			for reed: int in range(3):
				canvas.draw_rect(Rect2(bank + Vector2(reed * 4, -8 - reed % 2 * 4) * scale_factor, Vector2(2, 9 + reed % 2 * 4) * scale_factor), Color("769269"))
			canvas.draw_rect(Rect2(bank + Vector2(-2, 2) * scale_factor, Vector2(13, 3) * scale_factor), Color("b1a282"))
	else:
		canvas.draw_rect(Rect2(center - Vector2(radius, radius * 0.3), Vector2(radius * 2, radius * 0.8)), Color("343e36", 0.35))

static func draw_terrain_prop(canvas: Object, center: Vector2, terrain: Dictionary, scale_factor: float) -> void:
	if FrontierCollection.enabled() and terrain.get("kind") in ["TREE","MOUNTAIN"]:
		var collection_scale := float(terrain.get("radius",40)) / 40.0 * scale_factor
		if FrontierCollection.draw(canvas,center,str(terrain.get("frontier_entry","")),collection_scale): return
	if FrontierArt.enabled() and terrain.get("kind") in ["TREE","MOUNTAIN"]:
		var frontier_id := frontier_terrain_entry(terrain)
		var frontier_scale := float(terrain.get("radius",40)) / 40.0 * scale_factor
		if FrontierArt.draw_prop(canvas,center,frontier_id,frontier_scale): return
	if PrerenderedArt.enabled() and terrain.get("kind") in ["TREE","MOUNTAIN"]:
		var prop_id := "tree_oak" if terrain.get("kind") == "TREE" else "rock"
		var prop_scale := float(terrain.get("radius",40)) / 40.0 * scale_factor
		if PrerenderedArt.draw_prop(canvas,center,prop_id,prop_scale): return
	if terrain.get("kind") in ["TREE","MOUNTAIN"]:
		EnvironmentMaterial.draw_prop(canvas,center,terrain,scale_factor)
		return
	var radius := float(terrain.get("radius", 40))
	var pixel := maxf(radius * scale_factor / 24, 0.1)
	var kind := str(terrain.get("kind", ""))
	if kind == "MOUNTAIN":
		_poly(canvas, center, pixel, [Vector2(-25, 8), Vector2(-16, -18), Vector2(-3, -44), Vector2(8, -25), Vector2(25, 9)], STONE_DARK)
		_poly(canvas, center, pixel, [Vector2(-3, -44), Vector2(8, -25), Vector2(25, 9), Vector2(-2, 5)], STONE)
		_poly(canvas, center, pixel, [Vector2(-10, -30), Vector2(-3, -44), Vector2(4, -33), Vector2(9, -25), Vector2(-1, -30)], STONE_LIGHT)
		_line(canvas, center, pixel, Vector2(5, -13), Vector2(15, 6), STONE_DARK, 2)
		for index: int in range(4): _rect(canvas, center, pixel, Rect2(-16 + index * 8, index % 2 * 4, 5, 3), STONE_LIGHT.darkened(0.2))
	elif kind == "TREE":
		_rect(canvas, center, pixel, Rect2(-3, -30, 6, 38), WOOD_DARK)
		_rect(canvas, center, pixel, Rect2(-1, -27, 2, 32), WOOD)
		for index: int in range(3):
			var y := -49 + index * 12
			var extent := 13 + index * 5
			_poly(canvas, center, pixel, [Vector2(-extent, y + 17), Vector2(-extent, y + 8), Vector2(0, y - 3), Vector2(extent, y + 8), Vector2(extent, y + 17)], Color("354f3b"))
			_rect(canvas, center, pixel, Rect2(-extent + 3, y + 9, extent + 4, 5), Color("67855a"))
			for chip: int in range(3): _rect(canvas, center, pixel, Rect2(-extent + 5 + chip * 8, y + 7 + chip % 2 * 3, 4, 2), Color("8a9f68"))
		for root: int in [-1, 1]: _line(canvas, center, pixel, Vector2(root, 3), Vector2(root * 11, 7), WOOD_DARK, 2)
	elif kind == "RUIN":
		for x: int in [-19, 11]:
			_rect(canvas, center, pixel, Rect2(x, -26, 8, 35), STONE_DARK)
			_rect(canvas, center, pixel, Rect2(x + 1, -25, 4, 31), STONE)
		_rect(canvas, center, pixel, Rect2(-21, -30, 18, 6), STONE_LIGHT)
		_rect(canvas, center, pixel, Rect2(3, -28, 18, 6), STONE)
		for index: int in range(4): _rect(canvas, center, pixel, Rect2(-20 + index * 11, 6 + index % 2 * 4, 8, 5), STONE_DARK)
		for x: int in [-19, 11]:
			for y: int in [-18, -8, 2]: _rect(canvas, center, pixel, Rect2(x + 1, y, 7, 1), STONE_DARK)
		_rect(canvas, center, pixel, Rect2(-17, -13, 3, 9), Color("647956"))
		_rect(canvas, center, pixel, Rect2(12, 0, 4, 9), Color("647956"))
	elif kind == "MONUMENT":
		_rect(canvas, center, pixel, Rect2(-15, 3, 30, 6), STONE_DARK)
		_poly(canvas, center, pixel, [Vector2(-7, 3), Vector2(-5, -35), Vector2(1, -46), Vector2(7, -35), Vector2(8, 3)], STONE)
		_rect(canvas, center, pixel, Rect2(-2, -30, 3, 21), GOLD.darkened(0.3))
		for y: int in [-24, -16, -8]: _rect(canvas, center, pixel, Rect2(1, y, 3, 1), GOLD)
		_rect(canvas, center, pixel, Rect2(-11, 0, 22, 3), STONE_LIGHT)
		_rect(canvas, center, pixel, Rect2(-16, 7, 32, 2), STONE)

static func _draw_scaffold(canvas: Object, origin: Vector2, pixel: float, building: Dictionary, cloth: Color) -> void:
	var faction := str(building.get("faction_id","HUMAN"))
	var frame: Color = {"UNDEAD":Color("79716e"),"MACHINE":Color("8b7655"),"FOREST":Color("72804c"),"HIGHLAND":Color("8a9085"),"UNDERGROUND":Color("827793")}.get(faction,WOOD_DARK)
	var rail := frame.lightened(0.22)
	_rect(canvas, origin, pixel, Rect2(-23, 5, 46, 8), STONE_DARK)
	_rect(canvas, origin, pixel, Rect2(-21, 5, 42, 3), STONE)
	for x: int in [-22, 0, 20]:
		_rect(canvas, origin, pixel, Rect2(x, -32, 3, 45), frame)
		_rect(canvas, origin, pixel, Rect2(x, -30, 1, 41), rail)
	for y: int in [-27, -8]: _rect(canvas, origin, pixel, Rect2(-22, y, 44, 2), rail)
	_line(canvas, origin, pixel, Vector2(-21, 8), Vector2(0, -27), frame, 2)
	_line(canvas, origin, pixel, Vector2(0, 8), Vector2(21, -27), frame, 2)
	_rect(canvas, origin, pixel, Rect2(-21,-26,9,5),cloth)
	for n: int in range(3): _rect(canvas, origin, pixel, Rect2(-19 + n * 8, 14, 7, 4), rail)


static func _draw_hut(canvas: Object, origin: Vector2, pixel: float, cloth: Color) -> void:
	_rect(canvas, origin, pixel, Rect2(-17, 3, 34, 8), SHADOW)
	_rect(canvas, origin, pixel, Rect2(-15, -13, 30, 22), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(-13, -11, 26, 19), WOOD)
	_roof(canvas, origin, pixel, Vector2(0, -15), 18, Color("939063"))
	_rect(canvas, origin, pixel, Rect2(-4, -2, 8, 10), INK)
	_rect(canvas, origin, pixel, Rect2(7, -7, 4, 4), GOLD.darkened(0.35))
	_rect(canvas, origin, pixel, Rect2(-13, -11, 5, 2), cloth)


static func _roof(canvas: Object, origin: Vector2, pixel: float, center: Vector2, half_width: float, color: Color) -> void:
	_poly(canvas, origin, pixel, [center + Vector2(-half_width, 3), center + Vector2(-half_width, -1), center + Vector2(0, -12), center + Vector2(half_width, -1), center + Vector2(half_width, 3)], INK)
	_poly(canvas, origin, pixel, [center + Vector2(-half_width + 2, 0), center + Vector2(0, -10), center + Vector2(half_width - 2, 0)], color)
	_rect(canvas, origin, pixel, Rect2(center + Vector2(-half_width + 2, 0), Vector2(half_width * 2 - 4, 2)), color.lightened(0.1))


static func _flag(canvas: Object, origin: Vector2, pixel: float, point: Vector2, color: Color) -> void:
	_rect(canvas, origin, pixel, Rect2(point, Vector2(2, 32)), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(point + Vector2(2, 1), Vector2(12, 8)), color)
	_rect(canvas, origin, pixel, Rect2(point + Vector2(3, 2), Vector2(3, 5)), GOLD)


static func _cross(canvas: Object, center: Vector2, radius: float, color: Color) -> void:
	canvas.draw_rect(Rect2(center - Vector2(radius * 0.3, radius), Vector2(radius * 0.6, radius * 2)), color)
	canvas.draw_rect(Rect2(center - Vector2(radius, radius * 0.3), Vector2(radius * 2, radius * 0.6)), color)


static func _faction(side: String) -> Color:
	return Palette.side_color(side)

static func _rect(canvas: Object, origin: Vector2, pixel: float, rect: Rect2, color: Color, mirror: bool = false) -> void:
	var point := rect.position
	if mirror: point.x = -point.x - rect.size.x
	canvas.draw_rect(Rect2((origin + point * pixel).round(), (rect.size * pixel).abs()), color)


static func _poly(canvas: Object, origin: Vector2, pixel: float, points: Array, color: Color, mirror: bool = false) -> void:
	var projected := PackedVector2Array()
	for point: Vector2 in points:
		projected.append((origin + Vector2(-point.x if mirror else point.x, point.y) * pixel).round())
	canvas.draw_colored_polygon(projected, color)


static func _line(canvas: Object, origin: Vector2, pixel: float, from: Vector2, to: Vector2, color: Color, width: float = 1, mirror: bool = false) -> void:
	var a := Vector2(-from.x if mirror else from.x, from.y)
	var b := Vector2(-to.x if mirror else to.x, to.y)
	canvas.draw_line((origin + a * pixel).round(), (origin + b * pixel).round(), color, maxf(width * pixel, 1))
