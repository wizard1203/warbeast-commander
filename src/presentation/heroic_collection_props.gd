extends RefCounted
## Locally licensed building bodies. Shared source pixels stay unchanged;
## team pennants and construction scaffolds are separate original overlays.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const PixelResources = preload("res://src/presentation/heroic_pixel_resources.gd")
const EssenceArt = preload("res://src/presentation/heroic_essence_art.gd")
const Architecture = preload("res://src/presentation/heroic_faction_architecture.gd")
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
const BUILDING_PIXEL_SCALE := 3.0
const ROOT := "HAS Buildings Pack/"
const TOWNS := {"HUMAN":"Castle", "FOREST":"Rampart", "UNDEAD":"Necropolis", "MACHINE":"Tower", "HIGHLAND":"Stronghold", "UNDERGROUND":"Inferno"}
const ROLES := {"BARRACKS":"AttributeModifier/TraningGrounds.png", "RANGE":"AttributeModifier/VeteranGuild.png", "TOWER":"AttributeModifier/Tower.png", "SITE_TOWER":"AttributeModifier/Tower.png", "ESSENCE_MINE":"Miscellaneous/Forge.png", "FOUNDRY":"AttributeModifier/Weaponsmith.png", "ALTAR":"AttributeModifier/TempleOfOrder.png", "WORKSHOP":"Miscellaneous/Forge.png", "DRAGON_ROOST":"Treasures/DragonCity.png", "SHOP":"AttributeModifier/VeteranGuild.png"}
static var _body_rects: Dictionary = {}
static var _pixel_hashes: Dictionary = {}


static func required_files() -> Dictionary:
	var files: Array[String] = []
	for town: String in TOWNS.values(): files.append(ROOT + "Towns/" + town + ".png")
	for relative: String in ROLES.values():
		if ROOT + relative not in files: files.append(ROOT + relative)
	files.append(ROOT + "AttributeModifier/TempleOfNature.png")
	files.append(ROOT + "Treasures/Ruins.png")
	files.append(ROOT + "Mines/GoldMine/GoldVein.png")
	files.sort()
	return {"buildings":files}


static func inspect_building(building: Dictionary, factor: float = 1.0) -> Dictionary:
	if not Collection.active() or not is_finite(factor) or factor <= 0: return {"supported":false}
	var original := Architecture.inspect(building,factor)
	if bool(original.get("supported",false)):return original
	var kind := str(building.get("building_type", "BASE"))
	if kind != "BASE" and not ROLES.has(kind): return {"supported":false}
	var alive := int(building.get("hp", 1)) > 0
	var relative := str(ROLES.get(kind, ""))
	if kind == "BASE": relative = "Towns/" + str(TOWNS.get(str(building.get("faction_id", "HUMAN")), "Castle")) + ".png"
	if kind == "ALTAR" and building.get("faction_id") == "FOREST": relative = "AttributeModifier/TempleOfNature.png"
	if not alive: relative = "Treasures/Ruins.png"
	var file := ROOT + relative
	var source: Image = Collection.image("buildings", file)
	if source == null: return {"supported":false}
	var dimensions := source.get_size()
	# Match ordinary Creature source pixels; do not fit every building into a
	# tiny equal box. 64px towns stay larger than 32px production structures.
	var scale_factor := (BUILDING_PIXEL_SCALE if alive else 2.0) * factor
	var anchor := Vector2(dimensions.x * 0.5, dimensions.y - 2)
	if not _body_rects.has(file):
		_body_rects[file] = source.get_used_rect()
		var digest := HashingContext.new()
		digest.start(HashingContext.HASH_SHA256)
		digest.update(source.get_data())
		_pixel_hashes[file] = digest.finish().hex_encode()
	var opaque: Rect2i = _body_rects[file]
	var body := Rect2((Vector2(opaque.position) - anchor) * scale_factor, Vector2(opaque.size) * scale_factor)
	var pole := Vector2(body.position.x + body.size.x * 0.8, body.position.y)
	var bounds := body
	var scaffold := Rect2()
	if alive:
		bounds = bounds.merge(Rect2(pole + Vector2(-1, -17) * factor, Vector2(14, 18) * factor))
		if not bool(building.get("complete", false)):
			scaffold = body.grow(4 * factor)
			bounds = bounds.merge(scaffold)
	return {"supported":true, "provenance":"licensed", "pack":"buildings", "file":file, "rect":Rect2i(Vector2i.ZERO, dimensions), "anchor":anchor, "scale":scale_factor, "source_pixel_scale":BUILDING_PIXEL_SCALE, "bounds":bounds, "body_bounds":body, "scaffold_bounds":scaffold, "pole":pole, "alive":alive, "pixel_hash":_pixel_hashes[file], "team_accent":"embedded-material-and-pennant" if alive else "none", "source_unmodified":true}


static func building_visual_bounds(building: Dictionary, factor: float = 1.0) -> Rect2:
	var entry := inspect_building(building, factor)
	return entry.bounds if bool(entry.get("supported", false)) else Rect2()


static func building_body_contains(building: Dictionary, offset: Vector2, factor: float = 1.0) -> bool:
	if not offset.is_finite(): return false
	var entry := inspect_building(building, factor)
	if not bool(entry.get("supported", false)): return false
	if entry.has("architecture_key"):return Architecture.body_contains(entry,offset)
	var pixel := Vector2i((offset / float(entry.scale) + Vector2(entry.anchor)).floor())
	if not Rect2i(entry.rect).has_point(pixel): return false
	# Pennants/scaffolds do not enlarge the selectable opaque building body.
	var source: Image = Collection.image("buildings", str(entry.file))
	return source.get_pixelv(pixel).a > 0.1


static func building_source_image(entry: Dictionary) -> Image:
	# Detached per-role image for source-alpha inspection; atlas draw calls
	# still share six textures across owners and construction states.
	if entry.has("architecture_key"):return Architecture.frame_image(entry)
	return Collection.image(str(entry.get("pack","buildings")),str(entry.get("file","")))


static func draw_building(canvas: Object, point: Vector2, building: Dictionary, factor: float = 1.0) -> bool:
	if not point.is_finite(): return false
	var entry := inspect_building(building, factor)
	if not bool(entry.get("supported", false)): return false
	var modulation := Color.WHITE if bool(building.get("complete", false)) or not entry.alive else Color(1, 1, 1, 0.55)
	if building.get("building_type") == "SITE_TOWER" and not building.get("defense_active",false): modulation = Color("777b80")
	if entry.has("architecture_key"):
		if not Architecture.draw_body(canvas,point,entry,modulation,str(building.get("side",""))):return false
	elif not Collection.draw_region(canvas, "buildings", str(entry.file), entry.rect, point, entry.anchor, float(entry.scale), modulation): return false
	if not entry.alive: return true
	if not entry.has("architecture_key"):TeamMaterial.draw_building(canvas,point,building,entry,Collection.image("buildings",str(entry.file)),modulation)
	if building.get("building_type") == "ESSENCE_MINE" and not entry.has("architecture_key"): EssenceArt.draw(canvas,point+Vector2(20,0)*factor,{"remaining":1},factor*0.28)
	var team := Palette.side_color(str(building.get("side", "")))
	var pole: Vector2 = point + Vector2(entry.pole)
	canvas.draw_line(pole + Vector2(0, 1) * factor, pole + Vector2(0, -17) * factor, Color("d1b483"), maxf(factor, 1))
	canvas.draw_colored_polygon(PackedVector2Array([pole + Vector2(1, -17) * factor, pole + Vector2(12, -15) * factor, pole + Vector2(9, -9) * factor, pole + Vector2(1, -10) * factor]), team)
	if building.get("building_type") == "BASE":
		for i: int in range(clampi(int(building.get("base_tier", 1)), 1, 3)):
			canvas.draw_rect(Rect2(pole + Vector2(2 + i * 3, -15) * factor, Vector2(2, 2) * factor), Color("f4e1a4"))
	elif building.get("building_type") in ["TOWER","SITE_TOWER"]:
		for i: int in range(clampi(int(building.get("tower_level",1)),1,2)):
			canvas.draw_rect(Rect2(pole+Vector2(2+i*4,-14)*factor,Vector2(3,3)*factor),Color("e5c78f"))
	if not bool(building.get("complete", false)):
		var scaffold: Rect2 = entry.scaffold_bounds
		if entry.has("architecture_key"):
			# One logical pixel is three world pixels, just like the source body.
			# Coarse outlined beams replace a hairline vector construction grid.
			var logical:=maxf(1,roundf(3*factor))
			for x: float in [scaffold.position.x,scaffold.end.x-logical*2]:
				canvas.draw_rect(Rect2((point+Vector2(x,scaffold.position.y)).round(),Vector2(logical*2,scaffold.size.y).round()),Color("1c2025"))
				canvas.draw_rect(Rect2((point+Vector2(x+logical,scaffold.position.y+logical)).round(),Vector2(logical,maxf(logical,scaffold.size.y-logical*2)).round()),Color("aa8458"))
			for level: float in [0.15,0.48,0.82]:
				var y:=scaffold.position.y+roundf(scaffold.size.y*level/logical)*logical
				canvas.draw_rect(Rect2((point+Vector2(scaffold.position.x,y)).round(),Vector2(scaffold.size.x,logical*2).round()),Color("1c2025"))
				canvas.draw_rect(Rect2((point+Vector2(scaffold.position.x+logical,y)).round(),Vector2(maxf(logical,scaffold.size.x-logical*2),logical).round()),Color("c6a36c"))
		else:
			for x: float in [scaffold.position.x + factor, scaffold.end.x - factor]:
				canvas.draw_line(point + Vector2(x, scaffold.end.y - factor), point + Vector2(x, scaffold.position.y + factor), Color("d7ba82"), maxf(factor * 2, 1))
			for level: float in [0.15, 0.48, 0.82]:
				var y := scaffold.position.y + scaffold.size.y * level
				canvas.draw_line(point + Vector2(scaffold.position.x + factor, y), point + Vector2(scaffold.end.x - factor, y), Color("b99965"), maxf(factor * 2, 1))
	return true


static func inspect_resource(source: Dictionary, factor: float = 1.0) -> Dictionary:
	return PixelResources.inspect(source, factor)


static func resource_visual_bounds(source: Dictionary, factor: float = 1.0) -> Rect2:
	var entry := inspect_resource(source,factor)
	return entry.bounds if entry.get("supported",false) else Rect2()


static func draw_resource(canvas: Object, point: Vector2, source: Dictionary, factor: float = 1.0, include_floor: bool = true) -> bool:
	return PixelResources.draw(canvas, point, source, factor, include_floor)

static func draw_resource_floor(canvas: Object, point: Vector2, source: Dictionary, factor: float = 1.0) -> bool:
	return PixelResources.draw_floor(canvas, point, source, factor)


static func debug_stats() -> Dictionary:
	return {"active":Collection.active(), "building_roles":ROLES.size(), "faction_towns":TOWNS.size(), "body_metadata_entries":_body_rects.size(), "metadata_capacity":16, "texture_bytes":0, "cpu_pixel_bytes":0, "owner_atlas_copies":0, "shared_collection_textures":true, "building_pixel_scale":BUILDING_PIXEL_SCALE, "resource_types":["FOOD", "MATERIAL", "ESSENCE"], "food_fields":"licensed-starter-field-composition", "pixel_resources":PixelResources.debug_stats(),"architecture":Architecture.status()}
