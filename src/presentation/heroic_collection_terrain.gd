extends RefCounted
## Licensed Overworld presentation only. All geometry comes from observations;
## this adapter creates no terrain, paths, collision or authoritative objects.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const PixelDecorations = preload("res://src/presentation/heroic_pixel_decorations.gd")
const GroundDetail = preload("res://src/presentation/heroic_ground_detail.gd")
const RoadMaterial = preload("res://src/presentation/heroic_road_material.gd")
const RoadTiles = preload("res://src/presentation/heroic_road_tiles.gd")
const Microflora = preload("res://src/presentation/heroic_microflora.gd")
const MountainArt = preload("res://src/presentation/heroic_mountain_art.gd")
const M66TerrainArt = preload("res://src/presentation/m66_terrain_art.gd")
const HomeTerrain = preload("res://src/presentation/heroic_home_terrain.gd")
const ResourceAprons = preload("res://src/presentation/heroic_resource_aprons.gd")
const PhysicalBiomesM75 = preload("res://src/presentation/heroic_terrain_clusters_m75.gd")
const VERSION := "heroic-collection-terrain-m75-v6"
const ROOT := "HAS Overworld 2.1/"
const TREE_SHEET := ROOT + "Universal/Universal-Trees-And-Mountains.png"
const ROAD_SHEET := ROOT + "Universal/Universal-Road-Tileset.png"
const LAND_SHEETS := {
	"HUMAN":ROOT + "GrassBiome/GB-LandTileset.png",
	"FOREST":ROOT + "GrassBiome/GB-LandTileset.png",
	"MACHINE":ROOT + "DirtBiome/DB-LandTileset.png",
	"HIGHLAND":ROOT + "IceBiome/IB-LandTileset.png",
	"UNDEAD":ROOT + "MarshBiome/MB-LandTileset.png",
	"UNDERGROUND":ROOT + "CaveBiome/CB-LandTileset.png",
}
const LAND_RECTS := {
	"grass":Rect2i(16,0,16,16),
	"water":Rect2i(112,144,16,16),
	"shore_nw":Rect2i(96,128,16,16),
	"shore_n":Rect2i(112,128,16,16),
	"shore_ne":Rect2i(128,128,16,16),
	"shore_w":Rect2i(96,144,16,16),
	"shore_e":Rect2i(128,144,16,16),
	"shore_sw":Rect2i(96,160,16,16),
	"shore_s":Rect2i(112,160,16,16),
	"shore_se":Rect2i(128,160,16,16),
}
## Inspected 208px-wide tree/species blocks; each selected 32px cluster is a
## complete author composition, not a frame inferred from sheet dimensions.
const TREE_BLOCKS := {
	"HUMAN":Vector2i(0,0),
	"FOREST":Vector2i(0,288),
	"UNDEAD":Vector2i(208,0),
	"MACHINE":Vector2i(208,288),
	"HIGHLAND":Vector2i(208,48),
	"UNDERGROUND":Vector2i(0,432),
}
const MOUNTAIN_COLUMNS := {"HUMAN":0,"FOREST":0,"MACHINE":208,"UNDEAD":416,"UNDERGROUND":416,"HIGHLAND":624}
const BAYER := [0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5]
const MAX_CACHED_REGIONS := 96
static var _regions: Dictionary = {}
static var _region_bytes := 0
static var _bakes := 0


static func required_files() -> Array[String]:
	var result: Array[String] = []
	for faction: String in LAND_SHEETS:
		var file := str(LAND_SHEETS[faction])
		if not result.has(file): result.append(file)
	result.append(TREE_SHEET)
	result.append(ROAD_SHEET)
	return result


static func reset_cache() -> void:
	_regions.clear()
	_region_bytes = 0
	_bakes = 0
	Microflora.reset_cache()


static func inspect_ground(faction: String, tile: String = "grass") -> Dictionary:
	if not LAND_RECTS.has(tile): return {}
	return {"pack":"overworld","file":str(LAND_SHEETS.get(faction,LAND_SHEETS.HUMAN)),"rect":LAND_RECTS[tile],"faction":faction}


static func inspect_prop(terrain: Dictionary, faction: String) -> Dictionary:
	var kind := str(terrain.get("kind",""))
	var key := _key(str(terrain.get("id","terrain")))
	if kind == "TREE":
		var block: Vector2i = TREE_BLOCKS.get(faction,TREE_BLOCKS.HUMAN)
		var x: int = [32,64,128][key % 3]
		return {"pack":"overworld","file":TREE_SHEET,"rect":Rect2i(block+Vector2i(x,0),Vector2i(32,32)),"anchor":Vector2(16,30),"provenance":"licensed-overworld","species":faction}
	if kind in ["MOUNTAIN","RUIN"]:
		var column := int(MOUNTAIN_COLUMNS.get(faction,0))
		return {"pack":"overworld","file":TREE_SHEET,"rect":Rect2i(column,400,32,32),"anchor":Vector2(16,30),"provenance":"licensed-overworld","species":"mountain","parts":MountainArt.parts(terrain,faction) if kind=="MOUNTAIN" else []}
	return {"pack":"overworld","file":str(LAND_SHEETS.get(faction,LAND_SHEETS.HUMAN)),"rect":Rect2i(64,0,32,16),"anchor":Vector2(16,12),"provenance":"licensed-overworld","species":"stones"}


static func draw_prop(canvas: Object, point: Vector2, terrain: Dictionary, faction: String, factor: float) -> bool:
	if PhysicalBiomesM75.handles(terrain): return PhysicalBiomesM75.draw(canvas,point,terrain,faction,factor)
	if not Collection.active() or not point.is_finite() or not is_finite(factor) or factor <= 0: return false
	if terrain.get("kind")=="MOUNTAIN": return MountainArt.draw(canvas,point,terrain,faction,factor)
	if terrain.get("kind")=="TREE": return M66TerrainArt.draw_tree(canvas,point,terrain,faction,factor)
	var source := inspect_prop(terrain,faction)
	var radius := maxf(float(terrain.get("radius",40)),1.0)
	var size := radius/16.0 if str(terrain.get("kind","")) in ["TREE","MOUNTAIN","RUIN"] else 1.8
	return Collection.draw_region(canvas,"overworld",source.file,source.rect,point,source.anchor,size*factor,Color.WHITE)


static func bake(snapshot: Dictionary, landscape: Dictionary, decorations: Array, ground_bounds: Rect2, ground_pixel: float) -> Dictionary:
	if not Collection.active(): return {"image":null,"terrain_tiles":0,"failures":["Heroic collection is not active"]}
	if not is_finite(ground_pixel) or ground_pixel <= 0 or not ground_bounds.position.is_finite() or not ground_bounds.size.is_finite() or ground_bounds.size.x <= 0 or ground_bounds.size.y <= 0:
		return {"image":null,"terrain_tiles":0,"failures":["Invalid collection ground bounds"]}
	var size := Vector2i(ceili(ground_bounds.size.x/ground_pixel),ceili(ground_bounds.size.y/ground_pixel))
	# Matches the existing canvas resolution cap; invalid calls never allocate
	# an unbounded image and never change the authoritative world rectangle.
	if size.x > 2048 or size.y > 2048: return {"image":null,"terrain_tiles":0,"failures":["Collection ground exceeds 2048px per axis"]}
	var image := Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	image.fill(Color("4dbc27"))
	var columns := ceili(float(size.x)/16.0)
	var rows := ceili(float(size.y)/16.0)
	var water := _water_cells(snapshot,ground_bounds,ground_pixel,columns,rows)
	var zones: Array = landscape.get("home_zones",[])
	var seed := int(landscape.get("seed",0))
	var shaped_homes: bool = landscape.get("road_mode")=="TILED"
	var used_biomes: Array[String] = ["HUMAN"]
	var dry_sources: Dictionary = {}
	for y: int in range(rows):
		for x: int in range(columns):
			var cell := Vector2i(x,y)
			var tile := _water_tile(cell,water) if water.has(cell) else "grass"
			var neutral := _land_region("HUMAN",tile)
			if neutral == null: return {"image":null,"terrain_tiles":0,"failures":["Missing inspected neutral land region"]}
			image.blit_rect(neutral,Rect2i(0,0,16,16),cell*16)
			var world := ground_bounds.position+Vector2(x*16+8,y*16+8)*ground_pixel
			var zone := _nearest_zone(world,zones)
			var faction := HomeTerrain.faction_at(world,zones,seed) if shaped_homes else str(zone.get("faction_id","HUMAN"))
			if not water.has(cell): dry_sources[cell] = "HUMAN"
			# Current dry homes are painted as complete native surface families
			# after neutral detail. Wet geometry stays exactly the observed mask,
			# but its shoreline palette now follows the same shaped home owner.
			if shaped_homes and not water.has(cell): continue
			if faction in ["HUMAN","FOREST"]: continue
			var regional := _land_region(faction,tile)
			if regional == null: return {"image":null,"terrain_tiles":0,"failures":["Missing inspected biome region: "+faction]}
			if not used_biomes.has(faction): used_biomes.append(faction)
			if shaped_homes:
				image.blit_rect(regional,Rect2i(0,0,16,16),cell*16)
				continue
			var weight := _home_weight(world,zone)
			if weight >= 0.999:
				image.blit_rect(regional,Rect2i(0,0,16,16),cell*16)
				if not water.has(cell): dry_sources[cell] = faction
			elif not water.has(cell):
				# Dry biome ownership is chosen once for a complete native tile.
				# Its stepped contour is only presentation, never path geometry.
				if GroundDetail.regional(world,weight,seed):
					image.blit_rect(regional,Rect2i(0,0,16,16),cell*16)
					dry_sources[cell] = faction
			else:
				# Preserve the exact existing wet/shore raster path. It already
				# follows observed water rather than decorative meadow choices.
				_blend_wet_tile(image,regional,cell,zone,ground_bounds,ground_pixel,seed)
	var detail_palettes := _detail_palettes(used_biomes)
	var detail_report := {}
	# Legacy surfaces keep their exact retained compositor order. Shaped
	# homes replace the underlying floor, so their grain belongs after them.
	if not shaped_homes: detail_report = GroundDetail.paint(image,ground_bounds,ground_pixel,water,seed,detail_palettes,zones)
	var patch_report := _bake_meadows(image,water,dry_sources,zones,seed,ground_bounds,ground_pixel,columns,rows)
	var home_report := HomeTerrain.paint(image,ground_bounds,ground_pixel,water,zones,seed,LAND_SHEETS) if shaped_homes else {}
	for home: Dictionary in home_report.get("per_side",[]):
		if int(home.primary_cells)>0 and not used_biomes.has(str(home.faction_id)): used_biomes.append(str(home.faction_id))
	if shaped_homes: detail_report = GroundDetail.paint(image,ground_bounds,ground_pixel,water,seed,detail_palettes,zones)
	# Finite native-alpha work soil sits below flowers, roads and world props.
	# No observation means no apron; dynamic resource state is never consulted.
	var apron_report := ResourceAprons.paint(image,snapshot,ground_bounds,ground_pixel,water,seed) if shaped_homes else {}
	var flora_report := {}
	if landscape.get("road_mode") in ["ORTHOGONAL","TILED"]: flora_report = Microflora.paint(image,snapshot,landscape,decorations,ground_bounds,ground_pixel,LAND_SHEETS)
	var biome_report := PhysicalBiomesM75.paint(image,snapshot,ground_bounds,ground_pixel)
	var road_report := _bake_roads(image,landscape,ground_bounds,ground_pixel,size)
	var paint_failures: Array=home_report.get("failures",[]).duplicate()
	if not bool(road_report.get("ready",false)): paint_failures.append("Road artwork failed: "+str(road_report.get("reason","unknown-road-paint-failure")))
	if not paint_failures.is_empty(): return {"image":null,"terrain_tiles":0,"home_terrain":home_report,"road_materials":road_report,"failures":paint_failures}
	_bake_decorations(image,decorations,ground_bounds,ground_pixel)
	_bakes += 1
	return {"image":image,"terrain_tiles":columns*rows,"ground_bytes":size.x*size.y*4,"biomes":used_biomes,"blend":"native-shaped-home-surfaces" if shaped_homes else "deterministic-coherent-home-transition","dry_transition":"native-alpha-edge-16px-cells" if shaped_homes else "whole-16px-visual-cell","ground_detail":detail_report,"ground_patches":patch_report,"home_terrain":home_report,"resource_aprons":apron_report,"microflora":flora_report,"physical_biomes":biome_report,"road_geometry":"whole-authored-road-tiles" if shaped_homes else "orthogonal-whole-cell-union" if landscape.get("road_mode")=="ORTHOGONAL" else "existing-union-mask","road_materials":road_report,"version":VERSION,"failures":home_report.get("failures",[]).duplicate()}


static func _detail_palettes(biomes: Array[String]) -> Array:
	var palettes: Array = []
	for faction: String in biomes:
		var author_palette := GroundDetail.palette(_land_region(faction,"grass"),_region(str(LAND_SHEETS.get(faction,LAND_SHEETS.HUMAN)),Rect2i(160,224,48,48)))
		if not author_palette.is_empty(): palettes.append(author_palette)
	return palettes


static func _land_region(faction: String, tile: String) -> Image:
	return _region(str(LAND_SHEETS.get(faction,LAND_SHEETS.HUMAN)),LAND_RECTS[tile])


static func _region(file: String, rect: Rect2i) -> Image:
	var key := file+":"+str(rect)
	if _regions.has(key): return _regions[key]
	var source: Image = Collection.image("overworld",file)
	if source == null or not Rect2i(Vector2i.ZERO,source.get_size()).encloses(rect): return null
	# Crops are immutable shared CPU data, never per-player textures. Do not
	# modify the source Image returned by the collection loader.
	var cropped := source.get_region(rect)
	if _regions.size() < MAX_CACHED_REGIONS:
		_regions[key] = cropped
		_region_bytes += rect.size.x*rect.size.y*4
	return cropped


static func _water_cells(snapshot: Dictionary, bounds: Rect2, pixel: float, columns: int, rows: int) -> Dictionary:
	var wet: Array[Dictionary] = []
	for obstacle: Dictionary in snapshot.get("terrain",[]):
		if obstacle.get("kind") in ["LAKE","RIVER"]: wet.append(obstacle)
	var result: Dictionary = {}
	for y: int in range(-1,rows+1):
		for x: int in range(-1,columns+1):
			var point := bounds.position+Vector2(x*16+8,y*16+8)*pixel
			for obstacle: Dictionary in wet:
				if point.distance_squared_to(Vector2(obstacle.get("position",Vector2.ZERO))) <= pow(float(obstacle.get("radius",40)),2):
					result[Vector2i(x,y)] = true
					break
	return result


static func _water_tile(cell: Vector2i, water: Dictionary) -> String:
	var n := not water.has(cell+Vector2i.UP)
	var s := not water.has(cell+Vector2i.DOWN)
	var w := not water.has(cell+Vector2i.LEFT)
	var e := not water.has(cell+Vector2i.RIGHT)
	return "shore_nw" if n and w else "shore_ne" if n and e else "shore_sw" if s and w else "shore_se" if s and e else "shore_n" if n else "shore_s" if s else "shore_w" if w else "shore_e" if e else "water"


static func _nearest_zone(point: Vector2, zones: Array) -> Dictionary:
	var closest: Dictionary = {}
	var best := INF
	for zone: Dictionary in zones:
		var radius := maxf(float(zone.get("radius",500)),1.0)
		var distance := point.distance_squared_to(Vector2(zone.get("position",Vector2.ZERO)))/(radius*radius)
		if distance < 1.3225 and distance < best:
			best = distance
			closest = zone
	return closest


static func _home_weight(point: Vector2, zone: Dictionary) -> float:
	if zone.is_empty(): return 0.0
	var radius := maxf(float(zone.get("radius",500)),1.0)
	var distance := point.distance_to(Vector2(zone.get("position",Vector2.ZERO)))/radius
	return 1.0-smoothstep(0.65,1.15,distance)


static func _blend_wet_tile(image: Image, regional: Image, cell: Vector2i, zone: Dictionary, bounds: Rect2, pixel: float, seed: int) -> void:
	for py: int in range(16):
		for px: int in range(16):
			var x := cell.x*16+px
			var y := cell.y*16+py
			if x >= image.get_width() or y >= image.get_height(): continue
			var world := bounds.position+(Vector2(x,y)+Vector2.ONE*0.5)*pixel
			var weight := _home_weight(world,zone)
			# Water and shoreline pixels retain the exact M36 selection, including
			# the rare regional transition; dry tiles never enter this path.
			var chosen := (float(BAYER[posmod(y+seed,4)*4+posmod(x+seed/4,4)])+0.5)/16.0 < weight
			if chosen: image.set_pixel(x,y,regional.get_pixel(px,py))


static func _bake_meadows(image: Image, water: Dictionary, dry_sources: Dictionary, zones: Array, seed: int, bounds: Rect2, pixel: float, columns: int, rows: int) -> Dictionary:
	var candidates: Dictionary = {}
	for y: int in range(rows):
		for x: int in range(columns):
			var cell := Vector2i(x,y)
			if not dry_sources.has(cell): continue
			var world := bounds.position + Vector2(x*16+8,y*16+8)*pixel
			# Settlement cores stay quiet for roofs, workers and army silhouettes.
			if _home_weight(world,_nearest_zone(world,zones)) >= 0.999: continue
			if not GroundDetail.meadow(world,seed): continue
			var near_water := false
			for dy: int in range(-1,2):
				for dx: int in range(-1,2):
					if water.has(cell+Vector2i(dx,dy)): near_water = true
			if not near_water: candidates[cell] = dry_sources[cell]
	var patches: Dictionary = {}
	for cell: Vector2i in candidates:
		var source: String = candidates[cell]
		var n: bool = candidates.get(cell+Vector2i.UP) == source
		var s: bool = candidates.get(cell+Vector2i.DOWN) == source
		var w: bool = candidates.get(cell+Vector2i.LEFT) == source
		var e: bool = candidates.get(cell+Vector2i.RIGHT) == source
		# Every accepted cell belongs to a complete same-source 2x2 square.
		# All four members consequently survive together: no pruning-created
		# isolated sticker, single-tile spur or one-cell-wide line remains.
		var square: bool = (n and w and candidates.get(cell+Vector2i(-1,-1)) == source) or (n and e and candidates.get(cell+Vector2i(1,-1)) == source) or (s and w and candidates.get(cell+Vector2i(-1,1)) == source) or (s and e and candidates.get(cell+Vector2i(1,1)) == source)
		if square: patches[cell] = source
	var tiles: Dictionary = {}
	var slices: Dictionary = {}
	var biome_cells: Dictionary = {}
	var isolated := 0
	for cell: Vector2i in patches:
		var faction: String = patches[cell]
		biome_cells[faction] = int(biome_cells.get(faction,0))+1
		if not patches.has(cell+Vector2i.UP) and not patches.has(cell+Vector2i.DOWN) and not patches.has(cell+Vector2i.LEFT) and not patches.has(cell+Vector2i.RIGHT): isolated += 1
		var rect := GroundDetail.patch_rect(cell,patches)
		var key := faction+":"+str(rect)
		if not tiles.has(key):
			var patch := _region(str(LAND_SHEETS.get(faction,LAND_SHEETS.HUMAN)),GroundDetail.AUTHOR_PATCH)
			if patch == null: continue
			# Nine tiny slices at most per used biome, scoped to this bake, not
			# per actor/owner textures or an ever-growing static region cache.
			tiles[key] = patch.get_region(Rect2i(rect.position-GroundDetail.AUTHOR_PATCH.position,rect.size))
			slices[str(rect)] = true
		image.blend_rect(tiles[key],Rect2i(0,0,16,16),cell*16)
	return {"layout":"licensed-3x3-adjacency","tile_pixels":16,"candidate_cells":candidates.size(),"patch_cells":patches.size(),"biome_cells":biome_cells,"slice_variants":slices.size(),"temporary_crop_tiles":tiles.size(),"temporary_crop_bytes":tiles.size()*16*16*4,"contour":"stepped-authored-pixel-edge","isolated_stamps":isolated}


static func _bake_roads(image: Image, landscape: Dictionary, bounds: Rect2, pixel: float, size: Vector2i) -> Dictionary:
	if landscape.get("road_mode")=="TILED": return RoadTiles.paint(image,landscape,bounds,pixel)
	# Preserve the M34/M35 corridor geometry exactly. Artwork
	# changes do not make a bridge, a new navigable tile or a thinner main road.
	var road_mask := Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	road_mask.fill(Color.TRANSPARENT)
	var stamps: Dictionary = {}
	# The canonical M43 rectangles are the exact shared visual corridor; the
	# legacy brush remains available only to retained non-Heroic consumers.
	if landscape.get("road_mode") == "ORTHOGONAL":
		for rect: Rect2i in landscape.get("road_corridors",[]):
			# Raster pixel centers lie inside the world rectangle, including on
			# large maps whose cache pixel ratio is not an integer.
			var first := Vector2i(((Vector2(rect.position)-bounds.position)/pixel-Vector2.ONE*0.5).ceil())
			var end := Vector2i(((Vector2(rect.end)-bounds.position)/pixel-Vector2.ONE*0.5).ceil())
			road_mask.fill_rect(Rect2i(first,end-first),Color.WHITE)
	for road: Dictionary in ([] if landscape.get("road_mode")=="ORTHOGONAL" else landscape.get("roads",[])):
		var diameter := clampi(roundi(float(road.get("width",40))/pixel),12,48)
		if not stamps.has(diameter):
			var brush := Image.create(diameter,diameter,false,Image.FORMAT_RGBA8)
			brush.fill(Color.TRANSPARENT)
			var radius := float(diameter)*0.5
			for py: int in range(diameter):
				for px: int in range(diameter):
					var delta := Vector2(px+0.5,py+0.5)-Vector2.ONE*radius
					var octagon := maxf(absf(delta.x),absf(delta.y))+minf(absf(delta.x),absf(delta.y))*0.42
					if octagon <= radius: brush.set_pixel(px,py,Color.WHITE)
			stamps[diameter] = brush
		var points: Array = road.get("points",[])
		for index: int in range(1,points.size()):
			var start := (Vector2(points[index-1])-bounds.position)/pixel
			var end := (Vector2(points[index])-bounds.position)/pixel
			var count := maxi(ceili(start.distance_to(end)/4.0),1)
			for step: int in range(count+1): road_mask.blend_rect(stamps[diameter],Rect2i(0,0,diameter,diameter),Vector2i((start.lerp(end,float(step)/count)-Vector2.ONE*diameter/2.0).round()))
	var materials: Dictionary = {}
	var edges: Dictionary = {}
	var counts := {"EARTH":0,"STONE":0,"BRICK":0}
	for material: String in RoadMaterial.SOURCES:
		var tile := _region(ROAD_SHEET,RoadMaterial.SOURCES[material])
		if tile == null: return {"ready":false,"reason":"missing-inspected-road-material"}
		materials[material] = tile.get_data()
		edges[material] = RoadMaterial.darkest(tile)
	var mask := road_mask.get_data()
	var ground_data := image.get_data()
	var zones: Array = landscape.get("home_zones",[])
	var seed := int(landscape.get("seed",0))
	var cell_materials: Dictionary = {}
	var edge_count := 0
	for y: int in range(1,size.y-1):
		for x: int in range(1,size.x-1):
			var index: int = (y*size.x+x)*4
			if mask[index+3] == 0: continue
			var edge := mask[index-4+3] == 0 or mask[index+4+3] == 0 or mask[index-size.x*4+3] == 0 or mask[index+size.x*4+3] == 0
			var world := bounds.position+(Vector2(x,y)+Vector2.ONE*0.5)*pixel
			var cell := Vector2i((world/RoadMaterial.CELL_WORLD).floor())
			if not cell_materials.has(cell): cell_materials[cell] = RoadMaterial.material_at(world,zones,seed)
			# One native-pixel earth shoulder separates paving from the grass.
			# Both shoulder and outline stay inside the original union mask.
			var shoulder := edge
			if x>1 and y>1 and x<size.x-2 and y<size.y-2:
				shoulder = shoulder or mask[index-8+3] == 0 or mask[index+8+3] == 0 or mask[index-size.x*8+3] == 0 or mask[index+size.x*8+3] == 0
			var material: String = "EARTH" if shoulder else cell_materials[cell]
			var road_data: PackedByteArray = materials[material]
			# Retain the original fixed world-bake origin for source tiling; it
			# does not follow the camera or change with an actor's world position.
			var source_index: int = ((y%16)*16+x%16)*4
			if edge:
				var color: Color = edges.EARTH
				ground_data[index] = color.r8; ground_data[index+1] = color.g8; ground_data[index+2] = color.b8
				edge_count += 1
			else:
				for channel: int in range(3): ground_data[index+channel] = road_data[source_index+channel]
			ground_data[index+3] = 255
			counts[material] += 1
	image.set_data(size.x,size.y,false,Image.FORMAT_RGBA8,ground_data)
	# Hash raw bytes without allocating a second, twice-as-large hex string.
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(mask)
	return {"ready":true,"version":RoadMaterial.VERSION,"source_crops":RoadMaterial.SOURCES.duplicate(),"pixel_counts":counts,"outline_pixels":edge_count,"mask_sha256":digest.finish().hex_encode(),"mask_hash_encoding":"raw-rgba8","material_cells":cell_materials.size(),"extra_gpu_textures":0}


static func _bake_decorations(image: Image, decorations: Array, bounds: Rect2, pixel: float) -> void:
	for decor: Dictionary in decorations:
		if str(decor.get("layer","")) != "ground": continue
		var patch: Dictionary = PixelDecorations.ground_patch(decor)
		if patch.is_empty(): continue
		var pixels := (patch.image as Image).duplicate() as Image
		var extent := Vector2i(maxi(1,roundi(pixels.get_width()/pixel)),maxi(1,roundi(pixels.get_height()/pixel)))
		pixels.resize(extent.x,extent.y,Image.INTERPOLATE_NEAREST)
		var pos := (Vector2(decor.position)-bounds.position)/pixel
		image.blend_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),Vector2i((pos-Vector2(patch.anchor)/pixel).round()))


static func debug_stats() -> Dictionary:
	return {"version":VERSION,"bakes":_bakes,"cached_regions":_regions.size(),"max_cached_regions":MAX_CACHED_REGIONS,"cached_cpu_pixel_bytes":_region_bytes,"owner_texture_copies":0,"prop_texture_copies":0,"required_files":required_files().size(),"physical_biomes":PhysicalBiomesM75.debug_stats()}


static func _key(value: String) -> int:
	return value.sha256_text().substr(0,12).hex_to_int()
