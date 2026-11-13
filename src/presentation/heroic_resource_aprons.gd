extends RefCounted
## Static work ground beneath PUBLIC resource observations. Native author
## pixels only; no resource ownership, simulation, nodes or GPU allocations.
const Collection=preload("res://src/presentation/heroic_collection.gd")
const VERSION="heroic-resource-aprons-m49-v1"
const FILE="HAS Overworld 2.1/DirtBiome/DB-LandTileset.png"
const PATCH=Rect2i(160,224,48,48)
const MAX_RECORDS=256
const MAX_SOURCES=64
const MAX_VISITED_PIXELS=64*128*96
const CELL=32.0

static func paint(destination: Image,snapshot: Dictionary,bounds: Rect2,pixel: float,water: Dictionary,appearance_seed: int) -> Dictionary:
	var report: Dictionary={"version":VERSION,"painted_sources":0,"inspected_records":0,"visited_pixels":0,"painted_pixels":0,"source_rect":PATCH,"source_file":FILE,"cropped_cpu_bytes":0,"extra_gpu_textures":0,"max_records":MAX_RECORDS,"max_sources":MAX_SOURCES,"max_visited_pixels":MAX_VISITED_PIXELS,"work_limited":false,"entries":[]}
	if destination==null or destination.get_width()>2048 or destination.get_height()>2048 or not is_finite(pixel) or pixel<=0 or not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x<=0 or bounds.size.y<=0:return report
	var records: Variant=snapshot.get("resource_sources",[])
	if not records is Array:return report
	var candidates: Array[Dictionary]=[]
	# Do not read Landscape's match_config fallback: a missing public list is
	# missing information, not permission to show hidden resource positions.
	for index: int in range(mini(records.size(),MAX_RECORDS)):
		report.inspected_records+=1
		if not records[index] is Dictionary:continue
		var source: Dictionary=records[index]
		var kind:=str(source.get("resource_type",source.get("kind","")))
		var point: Variant=source.get("position")
		if kind not in ["FOOD","MATERIAL"] or not (point is Vector2 or point is Vector2i):continue
		var position:=Vector2(point)
		if not position.is_finite():continue
		var id:=str(source.get("id",""))
		if id.is_empty():continue
		candidates.append({"id":id,"kind":kind,"position":position})
	candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if a.id!=b.id:return a.id<b.id
		if a.position.y!=b.position.y:return a.position.y<b.position.y
		if a.position.x!=b.position.x:return a.position.x<b.position.x
		return a.kind<b.kind)
	if candidates.is_empty():return report
	var sheet: Image=Collection.image("overworld",FILE)
	if sheet==null or not Rect2i(Vector2i.ZERO,sheet.get_size()).encloses(PATCH):return report
	var patch:=sheet.get_region(PATCH)
	report.cropped_cpu_bytes=patch.get_data_size()
	for candidate: Dictionary in candidates.slice(0,MAX_SOURCES):
		if int(report.visited_pixels)>=MAX_VISITED_PIXELS:report.work_limited=true;break
		var food: bool=candidate.kind=="FOOD"
		var cells:=Vector2i(6,4) if food else Vector2i(5,4)
		var offset:=Vector2(-112,-96) if food else Vector2(-64,-96)
		var origin:=((Vector2(candidate.position)+offset)/CELL).floor()*CELL
		var frame:=Rect2(origin,Vector2(cells)*CELL)
		var clipped:=frame.intersection(bounds)
		if not clipped.has_area():continue
		var start:=Vector2i(((clipped.position-bounds.position)/pixel).floor()).max(Vector2i.ZERO)
		var end:=Vector2i(((clipped.end-bounds.position)/pixel).ceil()).min(destination.get_size())
		# Mirror only the center native tile, never alpha-bearing border cells.
		# This varies grain without consuming the gameplay/global RNG.
		var variation: int=(str(appearance_seed)+":"+str(candidate.id)).sha256_text().substr(0,8).hex_to_int()%2
		var changed:=0
		for y: int in range(start.y,end.y):
			if int(report.visited_pixels)>=MAX_VISITED_PIXELS:report.work_limited=true;break
			for x: int in range(start.x,end.x):
				if int(report.visited_pixels)>=MAX_VISITED_PIXELS:report.work_limited=true;break
				report.visited_pixels+=1
				if water.has(Vector2i(x/16,y/16)):continue
				var local: Vector2=(bounds.position+(Vector2(x,y)+Vector2.ONE*0.5)*pixel-frame.position)/2.0
				var cell:=Vector2i(floori(local.x/16.0),floori(local.y/16.0))
				if cell.x<0 or cell.y<0 or cell.x>=cells.x or cell.y>=cells.y:continue
				var sx:=clampi(floori(local.x)%16,0,15)
				var sy:=clampi(floori(local.y)%16,0,15)
				var column:=0 if cell.x==0 else 2 if cell.x==cells.x-1 else 1
				var row:=0 if cell.y==0 else 2 if cell.y==cells.y-1 else 1
				if column==1 and row==1 and variation==1:sx=15-sx
				var color:=patch.get_pixel(column*16+sx,row*16+sy)
				# This inspected pixel sheet has binary alpha. Transparent edge
				# pixels keep the existing biome; no blended invented palette.
				if color.a<0.999:continue
				destination.set_pixel(x,y,color)
				changed+=1
		if changed==0:continue
		report.painted_sources+=1
		report.painted_pixels+=changed
		report.entries.append({"id":candidate.id,"kind":candidate.kind,"bounds":frame,"painted_pixels":changed})
	return report
