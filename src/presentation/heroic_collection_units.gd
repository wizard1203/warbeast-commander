extends RefCounted
## Actual locally licensed Creature v1.4 frames. Shared cropped frame textures
## are keyed by source/pose only, never by unit identity or player ownership.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const Catalog = preload("res://src/simulation/strategic_unit_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
const MAX_FRAMES := 96
const FRAME_SIZE := Vector2i(16,16)
const FOOT := Vector2(8,15)
const PACK := "creatures"
const PROVENANCE := "licensed-heroic-creature-v1.4"
const UNIT_SPRITES := {
	"worker":"castle/peasant/sprite_sheet_peasant_0_16x16.png",
	"hinge_guard":"castle/swordsman/sprite_sheet_swordsman_0_16x16.png",
	"bright_crossbow":"castle/archer/sprite_sheet_archer_0_16x16.png",
	"iron_lancer":"castle/pikeman/sprite_sheet_pikeman_1_16x16.png",
	"grove_mender":"castle/monk/sprite_sheet_monk_0_16x16.png",
	"oath_cavalry":"castle/cavalier/sprite_sheet_cavalier_0_16x16.png",
	"ash_guard":"necropolis/skeleton/sprite_sheet_skeleton_0_16x16.png",
	"stitched_guard":"necropolis/zombie/sprite_sheet_zombie_1_16x16.png",
	"ember_mender":"necropolis/lich/sprite_sheet_lich_0_16x16.png",
	"rivet_guard":"wizards/golem/sprite_sheet_golem_0_16x16.png",
	"shard_gunner":"wizards/gremlin/sprite_sheet_gremlin_1_16x16.png",
	"vine_guard":"great elf/satyr/sprite_sheet_satyr_0_16x16.png",
	"leaf_archer":"great elf/hunter/sprite_sheet_hunter_0_16x16.png",
	"root_mender":"great elf/druid/sprite_sheet_druid_0_16x16.png",
	"ridge_guard":"great elf/dwarf/sprite_sheet_dwarf_0_16x16.png",
	"rune_keeper":"stronghold/shaman/sprite_sheet_shaman_0_16x16.png",
	"chitin_guard":"necropolis/spider/sprite_sheet_spider_0_16x16.png",
	"neutral_raider":"stronghold/goblin/sprite_sheet_goblin_0_16x16.png",
	"neutral_hunter":"great elf/hunter/sprite_sheet_hunter_0_16x16.png",
	"neutral_brute":"wizards/golem/sprite_sheet_golem_0_16x16.png",
	"neutral_trial_guard":"wizards/golem/sprite_sheet_golem_0_16x16.png",
	"neutral_trial_sentinel":"wizards/golem/sprite_sheet_golem_1_16x16.png",
}
const WORKER_SPRITES := {
	"HUMAN":"castle/peasant/sprite_sheet_peasant_0_16x16.png",
	"FOREST":"castle/peasant/sprite_sheet_peasant_0_16x16.png",
	"UNDEAD":"necropolis/zombie/sprite_sheet_zombie_0_16x16.png",
	"MACHINE":"wizards/gremlin/sprite_sheet_gremlin_0_16x16.png",
	"HIGHLAND":"great elf/dwarf/sprite_sheet_dwarf_0_16x16.png",
	"UNDERGROUND":"stronghold/goblin/sprite_sheet_goblin_0_16x16.png",
}
const HERO_SPRITES := {
	"COMMANDER":"castle/paladin/sprite_sheet_paladin_0_16x16.png",
	"BULWARK":"castle/paladin/sprite_sheet_paladin_1_16x16.png",
	"ARCANIST":"wizards/mage/sprite_sheet_djinn_0_16x16.png",
	"RANGER":"castle/archer/sprite_sheet_archer_1_16x16.png",
	"DUELIST":"castle/swordsman/sprite_sheet_swordsman_1_16x16.png",
	"ASH_MARSHAL":"necropolis/death knight/sprite_sheet_death_knight_1_16x16.png",
	"MOURN_ORACLE":"necropolis/lich/sprite_sheet_lich_1_16x16.png",
	"COIL_WARDEN":"wizards/golem/sprite_sheet_golem_1_16x16.png",
	"VOLT_WEAVER":"elementals/storm elemental/sprite_sheet_storm_elemental_0_16x16.png",
	"GEAR_HUNTER":"wizards/gremlin/sprite_sheet_gremlin_1_16x16.png",
	"VINE_WARDEN":"great elf/treant/sprite_sheet_treant_1_16x16.png",
	"LEAF_SEER":"great elf/druid/sprite_sheet_druid_1_16x16.png",
	"WIND_COURIER":"great elf/hunter/sprite_sheet_hunter_1_16x16.png",
	"RIDGE_JARL":"great elf/dwarf/sprite_sheet_dwarf_1_16x16.png",
	"RUNE_ORACLE":"stronghold/shaman/sprite_sheet_shaman_1_16x16.png",
	"EMBER_CAVALIER":"castle/paladin/sprite_sheet_paladin_1_16x16.png",
	"TUNNEL_SENTINEL":"necropolis/spider/sprite_sheet_spider_1_16x16.png",
	"SPORE_STALKER":"necropolis/spider/sprite_sheet_spider_0_16x16.png",
}
const ORIGINAL_FALLBACKS := {
	"bone_archer":"No bow-bearing skeleton animation is supplied.",
	"gear_engine":"No wheeled military vehicle animation is supplied.",
	"repair_drone":"No mechanical repair-drone animation is supplied.",
	"stag_rider":"The supplied deer is not mounted by a rider.",
	"stone_slinger":"The supplied cyclops is not this humanoid stone slinger.",
	"fire_dragon":"No dragon animation is supplied.",
	"echo_shooter":"No ranged multi-legged creature animation is supplied.",
	"tunnel_rider":"No mounted lizard animation is supplied.",
	"spore_mender":"No multi-legged healer animation is supplied.",
	"hero:CINDER_STALKER":"No bow-bearing skeleton hero animation is supplied.",
	"hero:ECHO_BINDER":"No multi-legged casting hero animation is supplied.",
}
static var _frames: Dictionary = {}
static var _order: Array[String] = []
static var _bakes := 0
static var _badge: ImageTexture
static var _failures: Array[String] = []
static var _native_scales: Dictionary = {}


static func reset_cache() -> void:
	_frames.clear()
	_order.clear()
	_native_scales.clear()
	_badge = null
	_failures.clear()
	_bakes = 0


static func required_files() -> Array[String]:
	var result: Array[String] = []
	for mapping: Dictionary in [UNIT_SPRITES,WORKER_SPRITES,HERO_SPRITES]:
		for file: String in mapping.values():
			if file not in result: result.append(file)
	result.sort()
	return result


static func source_for(unit: Dictionary) -> String:
	var type := str(unit.get("unit_type","worker"))
	if type == "hero":
		var archetype := str(unit.get("hero_archetype", "COMMANDER"))
		var visual := str(Heroes.PROFILES.get(archetype, {}).get("visual_archetype", archetype))
		return str(HERO_SPRITES.get(visual, ""))
	if type == "worker": return str(WORKER_SPRITES.get(str(unit.get("faction_id","HUMAN")),UNIT_SPRITES.worker))
	return str(UNIT_SPRITES.get(type,""))


static func fallback_reason(unit: Dictionary) -> String:
	if not Collection.active(): return "Optional licensed collection is not active."
	var type := str(unit.get("unit_type","worker"))
	var id := "hero:"+str(unit.get("hero_archetype","COMMANDER")) if type == "hero" else type
	return str(ORIGINAL_FALLBACKS.get(id,"No semantically matched licensed creature mapping."))


static func supported(unit: Dictionary, pose: Dictionary = {}) -> bool:
	return Collection.active() and not source_for(unit).is_empty() and not _frame(unit,pose).is_empty()


static func _category(unit: Dictionary) -> String:
	var type := str(unit.get("unit_type","worker"))
	if type == "hero":
		var role := str(Heroes.PROFILES.get(str(unit.get("hero_archetype","COMMANDER")),Heroes.PROFILES.COMMANDER).get("role",""))
		return "mage_hero" if "法师" in role else "ranger_hero" if "射手" in role else "tank_hero" if "坦克" in role else "blade_hero"
	var recipe: Dictionary = Catalog.UNITS.get(type,{})
	if recipe.get("body_kind") == "DRAGON": return "dragon"
	if recipe.get("body_kind") == "VEHICLE": return "engine"
	if recipe.get("role") == "CAVALRY": return "rider"
	return str({"WORKER":"worker","FRONTLINE":"guard","HEAVY":"lancer","RANGED":"ranger","SUPPORT":"mage"}.get(str(recipe.get("role","WORKER")),"guard"))


static func _frame(unit: Dictionary, pose: Dictionary) -> Dictionary:
	var file := source_for(unit)
	if file.is_empty() or not Collection.active(): return {}
	var sheet: Image = Collection.image(PACK,file)
	if sheet == null or sheet.get_width() != 64 or sheet.get_height() not in [80,96]: return {}
	var action := str(pose.get("action","IDLE"))
	var row := 0
	var column := clampi(int(pose.get("body_idle_frame_m76",0)),0,3) if action=="IDLE" else 0
	var phase := clampf(float(pose.get("body_phase_m76",pose.get("phase",0))),0,0.9999)
	if action in ["WALK","CARRY"]:
		row = 1
		column = posmod(floori(float(pose.get("body_animation_tick_m76",pose.get("animation_tick",0)))/3.0),4) if pose.has("body_animation_tick_m76") or pose.has("animation_tick") else 0 if float(pose.get("step",0)) < -0.2 else 2 if float(pose.get("step",0)) > 0.2 else 1
	elif action in ["ATTACK","HARVEST","MINE","BUILD"]:
		row = 2
		column = mini(floori(phase*4),3)
	elif action in ["DAMAGE","HURT","HIT"]:
		row = 3
		column = mini(floori(phase*4),3)
	elif action == "FALLEN":
		row = 4
		column = 3
	elif action.begins_with("SKILL_") or action in ["HEAL","POTION"]:
		row = 5 if sheet.get_height() == 96 else 2
		column = mini(floori(phase*4),3)
	var mirror := Vector2(pose.get("direction",Vector2.RIGHT)).x < 0
	var key := "%s:%d:%d:%s" % [file,row,column,str(mirror)]
	if _frames.has(key):
		_order.erase(key)
		_order.append(key)
		return _frames[key]
	var source_rect := Rect2i(column*16,row*16,16,16)
	var image: Image = sheet.get_region(source_rect)
	var source_transform := "crop"
	if str(unit.get("hero_archetype",""))=="VINE_WARDEN" and (action.begins_with("SKILL_") or action in ["HEAL","POTION"]) and sheet.get_height()==96:
		# This author's final strip grows from roots into a partial trunk:
		# heights3/5/8/10, versus the real body's11–16. It is not a complete
		# avatar cast strip. Keep every cast cell on the SAME hero's real
		# attack body; actual world spell VFX remain a separate observation.
		source_rect=Rect2i(column*16,2*16,16,16)
		image=sheet.get_region(source_rect)
		source_transform="treant-cast-particle-cell-same-body-attack"
	if action=="FALLEN":
		var idle := sheet.get_region(Rect2i(0,0,16,16))
		# Some96px author casters supply another upright cast where ordinary
		# creatures have a death strip. Never show a standing dead caster. A
		# cached quarter-turn collapse projects that SAME identity at its foot;
		# original files remain byte-identical and the transform is disclosed.
		if image.get_used_rect().size.y>float(idle.get_used_rect().size.y)*0.72:
			var fallen := idle.get_region(idle.get_used_rect())
			fallen.rotate_90(CLOCKWISE)
			fallen.resize(fallen.get_width(),maxi(1,ceili(fallen.get_height()*0.65)),Image.INTERPOLATE_NEAREST)
			image=Image.create(16,16,false,Image.FORMAT_RGBA8)
			image.fill(Color.TRANSPARENT)
			image.blit_rect(fallen,Rect2i(Vector2i.ZERO,fallen.get_size()),Vector2i(8-fallen.get_width()/2,16-fallen.get_height()))
			source_rect=Rect2i(0,0,16,16)
			source_transform="fallen-quarter-turn-y65"
	if mirror: image.flip_x()
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		var reason := "Empty mapped Creature frame: "+key
		if reason not in _failures: _failures.append(reason)
		return {}
	var cropped := image.get_region(used)
	var anchor := Vector2(15-FOOT.x,FOOT.y) if mirror else FOOT
	if not _native_scales.has(file):
		# Goblins/gremlins have shorter native bodies. A fixed per-source scale
		# derived from idle height keeps workers readable without action pulsing.
		var idle_height := sheet.get_region(Rect2i(0,0,16,16)).get_used_rect().size.y
		_native_scales[file] = maxf(1.0,34.0/maxf(float(idle_height)*3.0,1.0))
	var frame := {"key":key,"image":cropped,"texture":ImageTexture.create_from_image(cropped),"rect":Rect2(Vector2(used.position)-anchor,Vector2(used.size)),"pixel_hash":cropped.get_data().hex_encode().sha256_text(),"mirror":mirror,"row":row,"column":column,"source_file":file,"source_rect":source_rect,"source_transform":source_transform,"native_scale":float(_native_scales[file])}
	while _order.size() >= MAX_FRAMES: _frames.erase(_order.pop_front())
	_frames[key] = frame
	_order.append(key)
	_bakes += 1
	return frame


static func pixel_scale(radius: float) -> float:
	# Native 16px author art gets nearest enlargement, not reduced actor size.
	return maxf(radius/12.0*3.0,0.22) if is_finite(radius) and radius > 0 else 0


static func visual_bounds(unit: Dictionary, radius: float, pose: Dictionary = {}) -> Rect2:
	var frame := _frame(unit,pose)
	var factor := pixel_scale(radius)*float(frame.get("native_scale",1))
	return Rect2(Vector2(frame.rect.position)*factor,Vector2(frame.rect.size)*factor) if not frame.is_empty() else Rect2()


static func _badge_texture() -> ImageTexture:
	if _badge == null:
		# Original neutral cloth clasp. One tiny shared texture; only this accent
		# receives team modulation, never the author's clothing, metal or skin.
		var image := Image.create(5,3,false,Image.FORMAT_RGBA8)
		image.fill(Color("202634"))
		image.fill_rect(Rect2i(1,1,3,1),Color.WHITE)
		_badge = ImageTexture.create_from_image(image)
	return _badge


static func draw(canvas: Object, foot: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> bool:
	var factor := pixel_scale(radius)
	if not foot.is_finite() or factor <= 0: return false
	var frame := _frame(unit,pose)
	if frame.is_empty(): return false
	factor *= float(frame.native_scale)
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The resolved frame and scale already define these exact local bounds.
	var bounds := Rect2(Vector2(frame.rect.position)*factor,Vector2(frame.rect.size)*factor)
	canvas.draw_texture_rect(frame.texture,Rect2((foot+bounds.position).round(),bounds.size),false)
	TeamMaterial.draw_actor(canvas,foot,unit,pose,frame,factor,16)
	return true


static func body_contains(unit: Dictionary, radius: float, pose: Dictionary, offset: Vector2) -> bool:
	var factor := pixel_scale(radius)
	if factor <= 0 or not offset.is_finite(): return false
	var frame := _frame(unit,pose)
	if frame.is_empty(): return false
	factor *= float(frame.native_scale)
	var point := Vector2i((offset/factor-Vector2(frame.rect.position)).floor())
	var image: Image = frame.image
	return Rect2i(Vector2i.ZERO,image.get_size()).has_point(point) and image.get_pixelv(point).a > 0.1


static func inspect(unit: Dictionary, pose: Dictionary = {}) -> Dictionary:
	var frame := _frame(unit,pose)
	if frame.is_empty(): return {"supported":false,"fallback_reason":fallback_reason(unit)}
	return {"supported":true,"key":frame.key,"category":_category(unit),"action":str(pose.get("action","IDLE")),"frame":frame.column,"stage":frame.row,"pixel_hash":frame.pixel_hash,"rect":frame.rect,"mirror":frame.mirror,"original_art":false,"licensed_art":true,"provenance":PROVENANCE,"pack":PACK,"source_file":frame.source_file,"source_rect":frame.source_rect,"source_transform":frame.get("source_transform","crop"),"native_scale":frame.native_scale,"team_accent":"fitted-tabard-armour-harness","team_color":Palette.side_color(str(unit.get("side","PLAYER")))}


static func debug_stats() -> Dictionary:
	var bytes := 0
	for frame: Dictionary in _frames.values(): bytes += (frame.image as Image).get_width()*(frame.image as Image).get_height()*4
	return {"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"texture_bytes":bytes+(60 if _badge != null else 0),"maximum_texture_bytes":MAX_FRAMES*16*16*4+60,"cpu_pixel_bytes":bytes,"owner_atlas_copies":0,"original_art":false,"licensed_art":true,"provenance":PROVENANCE,"mapped_units":UNIT_SPRITES.size(),"mapped_heroes":HERO_SPRITES.size(),"source_files":required_files().size(),"failures":_failures.duplicate()}
