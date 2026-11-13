extends RefCounted
## Complete licensed road sprites on a detached, fixed world lattice.
## Run rectangles are clearance acceleration only; they never mask artwork.
const Routing = preload("res://src/presentation/heroic_orthogonal_roads.gd")
const Collection = preload("res://src/presentation/heroic_collection.gd")
const RoadMaterial = preload("res://src/presentation/heroic_road_material.gd")
const VERSION := "heroic-road-tiles-m45-v1"
const CELL := 32
const SOURCE_PIXELS := 16
const MAX_CELLS := 32768
const MAX_SCALED_CROPS := 128
const FILE := "HAS Overworld 2.1/Universal/Universal-Road-Tileset.png"
const BLOCKS := {"EARTH":Vector2i(208,0),"STONE":Vector2i(80,80),"BRICK":Vector2i(208,80)}
const STARTER_FILE := "res://assets/third_party/heroic_local/SP-road.png"
const STARTER_SHA256 := "247a132189a796131852813f38a92ed3778f02d5d12e07b46b686365b09d58ef"
static var _starter: Image


static func populate(plan: Dictionary, facts: Dictionary, resources: Array[Dictionary], villages: Array[Dictionary]) -> void:
	Routing.populate(plan,facts,resources,villages,{"cell":CELL,"step":CELL,"main_width":96,"branch_width":64,"tile_center":true})
	plan["road_mode"] = "TILED"
	plan["road_tiles_version"] = VERSION
	var occupied := {}
	var origin: Vector2i = plan.road_grid_origin
	# Every accepted route rectangle is already a complete aligned tile union.
	# Keep those compact runs for exact decor exclusion, not per-pixel paint.
	for rect: Rect2i in plan.road_corridors:
		var first := Vector2i((rect.position-origin)/CELL)
		var end := Vector2i((rect.end-origin)/CELL)
		for y: int in range(first.y,end.y):
			for x: int in range(first.x,end.x): occupied[Vector2i(x,y)] = true
	plan["road_cells"] = _ordered(occupied)
	plan["road_router_stats"]["paint_cells"] = occupied.size()
	plan["road_router_stats"]["clearance_representation"] = "exact-aligned-cell-runs"


static func source_rect(material: String, cell: Vector2i, occupied: Dictionary, profile: String = "COLLECTION") -> Rect2i:
	if not occupied.has(cell): return Rect2i()
	var origin: Vector2i = Vector2i(80,0) if profile == "STARTER" else BLOCKS.get(material,BLOCKS.EARTH)
	var x := 0 if not occupied.has(cell+Vector2i.LEFT) else 2 if not occupied.has(cell+Vector2i.RIGHT) else 1
	var y := 0 if not occupied.has(cell+Vector2i.UP) else 2 if not occupied.has(cell+Vector2i.DOWN) else 1
	return Rect2i(origin+Vector2i(x,y)*SOURCE_PIXELS,Vector2i.ONE*SOURCE_PIXELS)


static func paint(image: Image, landscape: Dictionary, bounds: Rect2, pixel: float, profile: String = "AUTO") -> Dictionary:
	if image == null or image.is_empty() or not is_finite(pixel) or pixel<=0 or not bounds.position.is_finite() or not bounds.size.is_finite():
		return {"ready":false,"reason":"invalid-whole-tile-destination"}
	if image.get_width()>2048 or image.get_height()>2048 or pixel>CELL:
		return {"ready":false,"reason":"whole-tile-destination-budget"}
	var selected := ("COLLECTION" if Collection.active() else "STARTER") if profile=="AUTO" else profile
	if selected not in ["COLLECTION","STARTER"]: return {"ready":false,"reason":"unsupported-road-source-profile"}
	var source: Image = Collection.image("overworld",FILE) if selected=="COLLECTION" else _starter_source()
	if source==null: return {"ready":false,"reason":"missing-pinned-road-source","profile":selected}
	var given: Array = landscape.get("road_cells",[])
	if given.size()>MAX_CELLS: return {"ready":false,"reason":"whole-road-cell-budget"}
	var occupied := {}
	for value: Variant in given:
		if not value is Vector2i: return {"ready":false,"reason":"invalid-road-cell"}
		occupied[value] = true
	var cells := _ordered(occupied)
	var origin := Vector2(landscape.get("road_grid_origin",bounds.position))
	var overlays := {"STONE":{},"BRICK":{}}
	if selected=="COLLECTION":
		for cell: Vector2i in cells:
			var center := origin+Vector2(cell*CELL)+Vector2.ONE*CELL*0.5
			var material := RoadMaterial.material_at(center,landscape.get("home_zones",[]),int(landscape.get("seed",0)))
			if overlays.has(material): overlays[material][cell] = true
	for material: String in overlays: overlays[material] = _supported_squares(overlays[material])
	var scaled := {}
	var crops := {}
	var drawn := {"EARTH":0,"STONE":0,"BRICK":0}
	var destinations := {}
	for cell: Vector2i in cells:
		var first := Vector2i(((origin+Vector2(cell*CELL)-bounds.position)/pixel).round())
		var end := Vector2i(((origin+Vector2((cell+Vector2i.ONE)*CELL)-bounds.position)/pixel).round())
		var destination := Rect2i(first,end-first)
		if destination.size.x<=0 or destination.size.y<=0 or not Rect2i(Vector2i.ZERO,image.get_size()).encloses(destination):
			return {"ready":false,"reason":"road-cell-outside-ground-cache","cell":cell}
		destinations[cell] = destination
	for material: String in ["EARTH","STONE","BRICK"]:
		var layer: Dictionary = occupied if material=="EARTH" else overlays[material]
		for cell: Vector2i in _ordered(layer):
			var rect := source_rect(material,cell,layer,selected)
			var destination: Rect2i = destinations[cell]
			var key := str(rect)+":"+str(destination.size)
			if not scaled.has(key):
				if scaled.size()>=MAX_SCALED_CROPS: return {"ready":false,"reason":"whole-road-scaled-crop-budget"}
				var tile := source.get_region(rect)
				if destination.size!=Vector2i.ONE*SOURCE_PIXELS: tile.resize(destination.size.x,destination.size.y,Image.INTERPOLATE_NEAREST)
				scaled[key] = tile
				crops[str(rect)] = rect
			# The complete sprite, including native transparent edge pixels,
			# reaches its complete shared cell. No route silhouette clips it.
			image.blend_rect(scaled[key],Rect2i(Vector2i.ZERO,destination.size),destination.position)
			drawn[material] += 1
	var scaled_bytes := 0
	for tile: Image in scaled.values(): scaled_bytes += tile.get_width()*tile.get_height()*4
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(var_to_bytes([origin,CELL,cells]))
	return {"ready":true,"version":VERSION,"layout":"whole-authored-road-tiles","profile":selected,"tile_world":CELL,"tile_pixels":SOURCE_PIXELS,"cell_count":cells.size(),"drawn_tiles":drawn,"layers":1 if selected=="STARTER" else 3,"source_file":STARTER_FILE if selected=="STARTER" else FILE,"source_blocks":{"EARTH":Vector2i(80,0)} if selected=="STARTER" else BLOCKS.duplicate(),"source_crops":crops.values(),"crop_variants":crops.size(),"temporary_scaled_crops":scaled.size(),"temporary_scaled_cpu_bytes":scaled_bytes,"starter_cached_cpu_bytes":0 if _starter==null else 128*80*4,"extra_gpu_textures":0,"cell_plan_sha256":digest.finish().hex_encode(),"clearance_representation":"exact-aligned-cell-runs"}


static func _supported_squares(candidates: Dictionary) -> Dictionary:
	var result := {}
	for cell: Vector2i in candidates:
		for offset: Vector2i in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.UP,Vector2i(-1,-1)]:
			var top := cell+offset
			if candidates.has(top) and candidates.has(top+Vector2i.RIGHT) and candidates.has(top+Vector2i.DOWN) and candidates.has(top+Vector2i.ONE):
				result[cell] = true
				break
	return result


static func _ordered(occupied: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(occupied.keys())
	cells.sort_custom(func(a: Vector2i,b: Vector2i)->bool:return a.x<b.x if a.y==b.y else a.y<b.y)
	return cells


static func _starter_source() -> Image:
	if _starter!=null: return _starter
	if not FileAccess.file_exists(STARTER_FILE): return null
	var file := FileAccess.open(STARTER_FILE,FileAccess.READ)
	if file==null or file.get_length()!=1704 or FileAccess.get_sha256(STARTER_FILE)!=STARTER_SHA256: return null
	var source := Image.new()
	if source.load_png_from_buffer(file.get_buffer(file.get_length()))!=OK or source.get_size()!=Vector2i(128,80): return null
	source.convert(Image.FORMAT_RGBA8)
	_starter = source
	return _starter
