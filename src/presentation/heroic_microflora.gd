extends RefCounted
## Tiny licensed source cells, baked once into ground. No gameplay objects.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const Detail = preload("res://src/presentation/heroic_ground_detail.gd")
const HomeTerrain = preload("res://src/presentation/heroic_home_terrain.gd")
const VERSION := "heroic-microflora-m43-v1"
const LIMIT := 384
const MAX_CANDIDATES := 4096
const FOOTPRINT := 23.0
const WORLD_SIZE := 32
const CROPS := [Vector2i(32,0),Vector2i(48,0),Vector2i(32,16),Vector2i(48,16),Vector2i(64,0),Vector2i(80,16),Vector2i(96,0),Vector2i(112,0),Vector2i(160,0),Vector2i(176,16)]
static var _crops := {}


static func reset_cache() -> void: _crops.clear()


static func plan(snapshot: Dictionary,landscape: Dictionary,decorations: Array=[]) -> Array[Dictionary]:
	var bounds := Rect2i(landscape.get("bounds",Rect2i()))
	if bounds.size.x<=0 or bounds.size.y<=0: return []
	var candidates: Array[Dictionary] = []
	var seed := int(landscape.get("seed",0))
	var columns := ceili(float(bounds.size.x)/128.0)
	var rows := ceili(float(bounds.size.y)/128.0)
	for y: int in range(rows):
		for x: int in range(columns):
			if candidates.size()>=MAX_CANDIDATES: break
			var key := _hash("%d:%d:%d"%[seed,x,y])
			var center := bounds.position+Vector2i(x*128+24+key%80,y*128+24+(key/83)%80)
			# Grouped field edges: not every grid anchor receives an ornament.
			if Detail.threshold(Vector2(center),seed^0x73c1)<0.40: continue
			for member: int in range(2+key%3):
				if candidates.size()>=MAX_CANDIDATES: break
				var part := _hash("%d:%d"%[key,member])
				var point := center+Vector2i(part%81-40,(part/83)%65-32)
				candidates.append({"position":point,"rank":part,"variant":int(part%CROPS.size())})
	candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if a.rank!=b.rank: return a.rank<b.rank
		return a.position.x<b.position.x if a.position.y==b.position.y else a.position.y<b.position.y)
	var result: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		if result.size()>=LIMIT: break
		var point := Vector2(candidate.position)
		if not clear(point,snapshot,landscape,decorations): continue
		var spaced := true
		for entry: Dictionary in result:
			if point.distance_squared_to(Vector2(entry.position))<pow(30.0,2): spaced=false; break
		if not spaced: continue
		var faction := "HUMAN"
		var nearest := INF
		if landscape.get("road_mode")=="TILED": faction=HomeTerrain.faction_at(point,landscape.get("home_zones",[]),seed)
		for home: Dictionary in landscape.get("home_zones",[]):
			if landscape.get("road_mode")=="TILED": break
			var distance := point.distance_to(Vector2(home.position))/maxf(float(home.radius),1.0)
			if distance>=1.15 or distance>=nearest: continue
			var weight := 1.0-smoothstep(0.65,1.15,distance)
			if Detail.regional(point,weight,seed): faction=str(home.faction_id); nearest=distance
		result.append({"position":candidate.position,"faction_id":faction,"rect":Rect2i(CROPS[candidate.variant],Vector2i(16,16)),"variant":candidate.variant,"footprint":FOOTPRINT,"layer":"ground","provenance":"licensed-overworld"})
	return result


static func clear(point: Vector2,snapshot: Dictionary,landscape: Dictionary,decorations: Array=[]) -> bool:
	if not Rect2(landscape.get("bounds",Rect2i())).grow(-FOOTPRINT).has_point(point): return false
	if landscape.get("road_mode")=="TILED" and HomeTerrain.transition_band(point,landscape.get("home_zones",[]),int(landscape.get("seed",0))): return false
	var config: Dictionary = snapshot.get("match_config",{})
	for home: Dictionary in landscape.get("home_zones",[]):
		if point.distance_to(Vector2(home.position))<220.0+FOOTPRINT: return false
	for category: String in ["terrain","sites","sources"]:
		var values: Array = snapshot.get("resource_sources",config.get("sources",[])) if category=="sources" else snapshot.get(category,config.get(category,[]))
		for item: Dictionary in values:
			var radius := float(item.get("radius",50))
			if category=="sites": radius=100.0 if item.get("kind")=="RESOURCE" else 64.0
			if point.distance_to(Vector2(item.get("position",Vector2.ZERO)))<radius+FOOTPRINT+16.0: return false
	for road: Rect2i in landscape.get("road_corridors",[]):
		var rect := Rect2(road)
		if point.distance_to(point.clamp(rect.position,rect.end))<FOOTPRINT+12.0: return false
	for decor: Dictionary in decorations:
		if point.distance_to(Vector2(decor.position))<float(decor.footprint)+FOOTPRINT+4.0: return false
	return true


static func paint(destination: Image,snapshot: Dictionary,landscape: Dictionary,decorations: Array,bounds: Rect2,pixel: float,land_sheets: Dictionary) -> Dictionary:
	var entries := plan(snapshot,landscape,decorations)
	var variants := {}
	var biomes := {}
	var painted := 0
	for entry: Dictionary in entries:
		var file: String = land_sheets.get(entry.faction_id,land_sheets.HUMAN)
		var key := file+":"+str(entry.rect)
		if not _crops.has(key):
			var source := Collection.image("overworld",file)
			if source==null or _crops.size()>=64: continue
			_crops[key] = source.get_region(entry.rect)
		var tile: Image = _crops[key]
		var size := maxi(1,roundi(WORLD_SIZE/pixel))
		var resized := tile.duplicate() as Image
		resized.resize(size,size,Image.INTERPOLATE_NEAREST)
		var position := Vector2i(((Vector2(entry.position)-Vector2.ONE*WORLD_SIZE/2.0-bounds.position)/pixel).round())
		destination.blend_rect(resized,Rect2i(Vector2i.ZERO,resized.get_size()),position)
		variants[entry.variant] = true
		biomes[entry.faction_id] = int(biomes.get(entry.faction_id,0))+1
		painted += 1
	return {"version":VERSION,"count":painted,"limit":LIMIT,"variants":variants.size(),"biomes":biomes,"cached_regions":_crops.size(),"cached_cpu_bytes":_crops.size()*16*16*4,"max_regions":64,"extra_gpu_textures":0,"max_candidates":MAX_CANDIDATES,"entries":entries}


static func _hash(value: String) -> int: return value.sha256_text().substr(0,12).hex_to_int()
