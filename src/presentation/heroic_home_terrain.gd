extends RefCounted
## Detached visual landforms. Native alpha borders join the authored surfaces;
## neither the surface cells nor these analytic shapes are navigation data.
const Collection = preload("res://src/presentation/heroic_collection.gd")
## VERSION identifies primary ownership geometry and seeds scenery placement.
## A secondary surface-only edit must not reshuffle unrelated decorations.
const VERSION := "heroic-shaped-homes-m45-v1"
const SURFACE_VERSION := "heroic-shaped-home-surfaces-m66-v1"
const FLAT_PATCH := Rect2i(160,272,48,48)
const TEXTURED_PATCH := Rect2i(160,224,48,48)
# Bounded world-space authoring cells, NOT GPU pixels. V2's largest authored
# 8200x5800 map uses <48k 32-world-unit cells. The final ground texture remains
# capped at2048 per axis; do not confuse the two independent budgets.
const MAX_CELLS := 65536
const MAX_HOMES := 4
const QUIET_CORE := 205.0
const CELL_WORLD := 32.0
static var _query_zones: Array=[]
static var _query_seed := -1
static var _query_cells: Dictionary={}
const PROFILES := {
	"HUMAN":"terraced-meadow", "FOREST":"lobed-root-clearing",
	"MACHINE":"stepped-industrial-yard", "UNDEAD":"fissured-marsh-tongues",
	"HIGHLAND":"snow-shelves", "UNDERGROUND":"mineral-fungal-beds",
}


static func faction_at(world: Vector2, zones: Array, seed: int, neutral_faction: String="HUMAN") -> String:
	if not world.is_finite(): return neutral_faction
	if zones!=_query_zones or seed!=_query_seed:
		_query_zones=zones.duplicate(true); _query_seed=seed; _query_cells.clear()
	var cell:=Vector2i((world/CELL_WORLD).floor())
	if _query_cells.has(cell): return str(_query_cells[cell]) if not str(_query_cells[cell]).is_empty() else neutral_faction
	var chosen := _supported_owner(cell,_homes(zones),seed)
	var faction:=str(chosen.get("faction_id","HUMAN")) if not chosen.is_empty() else ""
	if _query_cells.size()<MAX_CELLS: _query_cells[cell]=faction
	return faction if not faction.is_empty() else neutral_faction


static func transition_band(world: Vector2, zones: Array, seed: int) -> bool:
	for home: Dictionary in zones.slice(0,MAX_HOMES):
		var field:=_field(_local(world,home,seed),str(home.get("faction_id","HUMAN")),seed)
		if field> -0.24 and field<0.23: return true
	return false


static func _supported_owner(cell: Vector2i, homes: Array, seed: int) -> Dictionary:
	var chosen:=_owner((Vector2(cell)+Vector2.ONE*0.5)*CELL_WORLD,homes,seed)
	if chosen.is_empty(): return {}
	var faction:=str(chosen.get("faction_id","HUMAN"))
	for corner: Vector2i in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.UP,Vector2i(-1,-1)]:
		var supported:=true
		for offset: Vector2i in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]:
			var neighbor:=_owner((Vector2(cell+corner+offset)+Vector2.ONE*0.5)*CELL_WORLD,homes,seed)
			if neighbor.is_empty() or str(neighbor.get("faction_id","HUMAN"))!=faction: supported=false; break
		if supported: return chosen
	return {}


static func plan(bounds: Rect2, pixel: float, zones: Array, seed: int) -> Dictionary:
	var cells := {}
	var secondary := {}
	var owners := {}
	var homes := _homes(zones)
	if not is_finite(pixel) or pixel<=0 or not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x<=0 or bounds.size.y<=0: return {"cells":cells,"secondary":secondary,"owners":owners,"per_side":[],"failures":["invalid-home-bounds"]}
	var origin:=Vector2i((bounds.position/CELL_WORLD).floor())
	var limit:=Vector2i((bounds.end/CELL_WORLD).ceil())
	var columns := limit.x-origin.x
	var rows := limit.y-origin.y
	if columns*rows>MAX_CELLS: return {"cells":cells,"secondary":secondary,"owners":owners,"per_side":[],"failures":["home-cell-budget"]}
	for y: int in range(origin.y,limit.y):
		for x: int in range(origin.x,limit.x):
			var cell := Vector2i(x,y)
			var world := (Vector2(cell)+Vector2.ONE*0.5)*CELL_WORLD
			var home := _owner(world,homes,seed)
			if home.is_empty(): continue
			var faction := str(home.get("faction_id","HUMAN"))
			cells[cell]=faction
			owners[cell]=_side(home)
			if world.distance_to(Vector2(home.position))>QUIET_CORE+CELL_WORLD and _textured(_local(world,home,seed),faction): secondary[cell]=faction
	# Every surface cell belongs to a complete 2×2 block. This removes pointed
	# single-cell spurs without turning the contour into a random tile mosaic.
	cells=_supported(cells)
	for cell: Vector2i in owners.keys():
		if not cells.has(cell): owners.erase(cell); secondary.erase(cell)
	secondary=_supported(secondary)
	var per_side: Array[Dictionary]=[]
	for home: Dictionary in homes:
		var side := _side(home)
		var anchor := Vector2i((Vector2(home.position)/CELL_WORLD).floor())
		var contour: Array=[]
		var texture: Array=[]
		for cell: Vector2i in owners:
			if owners[cell]!=side: continue
			contour.append([cell.x-anchor.x,cell.y-anchor.y])
			if secondary.has(cell): texture.append([cell.x-anchor.x,cell.y-anchor.y])
		# Row-major construction gives canonical coordinates. Labels and palette
		# IDs are deliberately excluded from geometry signatures.
		per_side.append({"side_id":side,"faction_id":home.faction_id,"profile":PROFILES.get(home.faction_id,PROFILES.HUMAN),"primary_cells":contour.size(),"secondary_cells":texture.size(),"contour_sha256":var_to_str(contour).sha256_text(),"secondary_sha256":var_to_str(texture).sha256_text()})
	var fringe:=_fringe(bounds,homes,seed)
	for record: Dictionary in per_side:
		var rows_for_side: Array=[]
		for piece: Dictionary in fringe:
			if piece.side_id==record.side_id: rows_for_side.append([piece.position.x,piece.position.y])
		record["fringe_clusters"]=rows_for_side.size()
		record["fringe_sha256"]=var_to_str(rows_for_side).sha256_text()
	return {"cells":cells,"secondary":secondary,"owners":owners,"per_side":per_side,"fringe":fringe,"failures":[]}


static func paint(destination: Image, bounds: Rect2, pixel: float, water: Dictionary, zones: Array, seed: int, land_sheets: Dictionary) -> Dictionary:
	var layout := plan(bounds,pixel,zones,seed)
	var report := {"version":SURFACE_VERSION,"primary_cells":0,"secondary_cells":0,"edge_cells":0,"native_alpha_pixels":0,"per_side":layout.per_side,"source_crops":[],"temporary_crop_tiles":0,"temporary_crop_bytes":0,"max_cells":MAX_CELLS,"extra_gpu_textures":0,"failures":layout.failures.duplicate(),"cell_world":CELL_WORLD,"fringe_clusters":0,"fringe_source_opaque_pixels":0,"fringe_source_transparent_pixels":0,"classifier_cache_cells":_query_cells.size(),"classifier_max_cells":MAX_CELLS,"quiet_human_flat_tiles":0,"quiet_human_remapped_source_pixels":0}
	if destination==null or not layout.failures.is_empty(): return report
	var crops := {}
	var source_rows := {}
	for piece: Dictionary in layout.fringe:
		var file: String=land_sheets.get(piece.faction_id,land_sheets.get("HUMAN",""))
		var key:=file+":fringe"
		if not crops.has(key):
			var source:=Collection.image("overworld",file)
			if source==null: continue
			crops[key]=source.get_region(TEXTURED_PATCH)
			source_rows[key]={"file":file,"rect":TEXTURED_PATCH,"layer":"fringe","provenance":"licensed-overworld-native-pixels"}
		var tile: Image=crops[key]
		var rect:=Rect2(Vector2(piece.position)-Vector2.ONE*48.0,Vector2.ONE*96.0)
		_blend_dry(destination,tile,_destination(rect,bounds,pixel),water)
		report.fringe_clusters+=1
		for py: int in range(48):
			for px: int in range(48):
				if tile.get_pixel(px,py).a<0.999: report.fringe_source_transparent_pixels+=1
				else: report.fringe_source_opaque_pixels+=1
	for layer: String in ["cells","secondary"]:
		var cells: Dictionary=layout[layer]
		var frame := FLAT_PATCH if layer=="cells" else TEXTURED_PATCH
		for cell: Vector2i in cells:
			var faction: String=cells[cell]
			var file: String=land_sheets.get(faction,land_sheets.get("HUMAN",""))
			var rect := crop_rect(cell,cells,frame)
			# HUMAN's primary grass is the same native fill as the neutral land.
			# Its bright flat-patch rim is not a territory or navigation boundary.
			# Keep the alpha contour, but use native central grass on that highlight.
			# FOREST shares this sheet, so derived and literal crops must not alias.
			var quiet_human_flat: bool=layer=="cells" and faction=="HUMAN"
			var key := file+":"+str(rect)+("|quiet-human-flat" if quiet_human_flat else "")
			if not crops.has(key):
				var source := Collection.image("overworld",file)
				if source==null or not Rect2i(Vector2i.ZERO,source.get_size()).encloses(rect): report.failures.append("missing-native-home-crop:"+key); continue
				crops[key]=source.get_region(rect)
				source_rows[key]={"file":file,"rect":rect,"layer":layer,"provenance":"licensed-overworld-native-pixels"}
				if quiet_human_flat:
					var remapped:=_quiet_flat_highlight(crops[key],source.get_pixelv(FLAT_PATCH.position+Vector2i(16,16)))
					source_rows[key]["provenance"]="licensed-overworld-derived-native-grass-fill"
					source_rows[key]["processing"]={"kind":"opaque-highlight-to-native-center","fill_texel":FLAT_PATCH.position+Vector2i(16,16),"remapped_source_pixels":remapped}
					report.quiet_human_flat_tiles+=1
					report.quiet_human_remapped_source_pixels+=remapped
			var tile: Image=crops[key]
			_blend_dry(destination,tile,_destination(Rect2(Vector2(cell)*CELL_WORLD,Vector2.ONE*CELL_WORLD),bounds,pixel),water)
			if layer=="cells":
				report.primary_cells+=1
				if rect.position!=frame.position+Vector2i(16,16):
					report.edge_cells+=1
					for py: int in range(16):
						for px: int in range(16):
							if tile.get_pixel(px,py).a<0.999: report.native_alpha_pixels+=1
			else: report.secondary_cells+=1
	for key: String in source_rows: report.source_crops.append(source_rows[key])
	report.temporary_crop_tiles=crops.size()
	for tile: Image in crops.values(): report.temporary_crop_bytes+=tile.get_width()*tile.get_height()*4
	report["contour_sha256"]=var_to_str(_geometry_rows(layout,"cells")).sha256_text()
	report["secondary_sha256"]=var_to_str(_geometry_rows(layout,"secondary")).sha256_text()
	report["transition"]="clustered-native-alpha-ecotone"
	report["fringe_sha256"]=var_to_str(layout.fringe).sha256_text()
	report["quiet_core_world"]=QUIET_CORE
	return report


static func _quiet_flat_highlight(tile: Image, native_fill: Color) -> int:
	var changed:=0
	for y: int in range(tile.get_height()):
		for x: int in range(tile.get_width()):
			var color:=tile.get_pixel(x,y)
			if color.a<0.999 or color.get_luminance()<=native_fill.get_luminance()+0.04: continue
			tile.set_pixel(x,y,native_fill)
			changed+=1
	return changed


static func crop_rect(cell: Vector2i, cells: Dictionary, frame: Rect2i=FLAT_PATCH) -> Rect2i:
	if not cells.has(cell): return Rect2i()
	var source: Variant=cells[cell]
	var column := 0 if cells.get(cell+Vector2i.LEFT)!=source else 2 if cells.get(cell+Vector2i.RIGHT)!=source else 1
	var row := 0 if cells.get(cell+Vector2i.UP)!=source else 2 if cells.get(cell+Vector2i.DOWN)!=source else 1
	return Rect2i(frame.position+Vector2i(column,row)*16,Vector2i(16,16))


static func _fringe(bounds: Rect2, homes: Array, seed: int) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var first:=Vector2i((bounds.position/64.0).floor())
	var end:=Vector2i((bounds.end/64.0).ceil())
	var phase:=float(posmod(seed,97))*0.031
	for y: int in range(first.y,end.y):
		for x: int in range(first.x,end.x):
			if result.size()>=512: return result
			# Neighboring clumps follow a slowly warped lattice, rather than
			# exposing rows of identical little square islands at the snow edge.
			var point: Vector2=Vector2(x*64+32+sin(y*0.71+x*0.43+phase)*19.0,y*64+32+sin(x*0.83-y*0.31-phase)*19.0).round()
			var chosen: Dictionary={}
			var best:=0.11
			for home: Dictionary in homes:
				if point.distance_to(Vector2(home.position))<QUIET_CORE+68.0: continue
				var field:=_field(_local(point,home,seed),str(home.faction_id),seed)
				if field< -0.22 or field>=best: continue
				best=field; chosen=home
			if chosen.is_empty(): continue
			# A broad correlated gate leaves channels of neutral soil between
			# complete native 3×3 clumps. Density tapers over roughly three cells.
			var density:=1.0-smoothstep(-0.19,0.11,best)
			var gate: float=0.14+(sin(point.x/183.0+phase)*sin(point.y/157.0-phase)+1.0)*0.34
			if gate>density: continue
			if str(chosen.faction_id)=="HUMAN":
				# Continue the three meadow lobes rather than outlining every
				# terrace side with a necklace of identical full grass clumps.
				if not _textured(_local(point,chosen,seed)*0.8,"HUMAN"): continue
				# Keep complete native clumps outside the matching neutral floor.
				# Moving the same accepted anchors along the signed field's outer
				# normal avoids cutting them into terrace-shaped narrow strips.
				var dx:=_field(_local(point+Vector2(4,0),chosen,seed),"HUMAN",seed)-_field(_local(point-Vector2(4,0),chosen,seed),"HUMAN",seed)
				var dy:=_field(_local(point+Vector2(0,4),chosen,seed),"HUMAN",seed)-_field(_local(point-Vector2(0,4),chosen,seed),"HUMAN",seed)
				var normal:=Vector2(dx,dy)
				if normal.length_squared()<0.000001: continue
				point=(point+normal.normalized()*176.0).round()
				if not bounds.grow(-48.0).has_point(point): continue
				var core_clear:=true
				for nearby: Dictionary in homes:
					if point.distance_to(Vector2(nearby.position))<=QUIET_CORE+48.0: core_clear=false; break
				if not core_clear: continue
			result.append({"position":Vector2i(point),"faction_id":str(chosen.faction_id),"side_id":_side(chosen)})
	return result


static func _destination(world: Rect2, bounds: Rect2, pixel: float) -> Rect2i:
	# Adjacent cells share rounded edges; fractional ground-cache scales cannot
	# create a one-pixel gap between the complete native source placements.
	var first:=Vector2i(((world.position-bounds.position)/pixel).round())
	var end:=Vector2i(((world.end-bounds.position)/pixel).round())
	return Rect2i(first,end-first)


static func _blend_dry(destination: Image, source: Image, target: Rect2i, water: Dictionary) -> void:
	if target.size.x<=0 or target.size.y<=0: return
	var tile:=source.duplicate() as Image
	if tile.get_size()!=target.size: tile.resize(target.size.x,target.size.y,Image.INTERPOLATE_NEAREST)
	# The caller's wet keys describe 16 CACHE pixels, not 32 world units.
	# Preserve every wet/shore pixel even when a home cell straddles two keys.
	var wet_overlap:=false
	for y: int in range(floori(float(target.position.y)/16),ceili(float(target.end.y)/16)):
		for x: int in range(floori(float(target.position.x)/16),ceili(float(target.end.x)/16)):
			if water.has(Vector2i(x,y)): wet_overlap=true; break
	if wet_overlap:
		for y: int in range(tile.get_height()):
			for x: int in range(tile.get_width()):
				if water.has(Vector2i(floori(float(target.position.x+x)/16),floori(float(target.position.y+y)/16))): tile.set_pixel(x,y,Color.TRANSPARENT)
	destination.blend_rect(tile,Rect2i(Vector2i.ZERO,tile.get_size()),target.position)


static func _geometry_rows(layout: Dictionary, key: String) -> Array:
	var rows: Array=[]
	for cell: Vector2i in layout[key]: rows.append([cell.x,cell.y,layout.owners.get(cell,"")])
	return rows


static func _homes(zones: Array) -> Array[Dictionary]:
	var homes: Array[Dictionary]=[]
	for zone: Dictionary in zones:
		if not Vector2(zone.get("position",Vector2.ZERO)).is_finite() or not is_finite(float(zone.get("radius",500.0))) or float(zone.get("radius",500.0))<=0: continue
		homes.append(zone)
	homes.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return _side(a)<_side(b))
	return homes.slice(0,MAX_HOMES)


static func _side(home: Dictionary) -> String:
	return str(home.get("side_id",home.get("id","home:"+str(home.get("position",Vector2.ZERO)))))


static func _owner(world: Vector2, zones: Array, seed: int) -> Dictionary:
	if not world.is_finite(): return {}
	var chosen: Dictionary={}
	var best := -0.08
	for zone: Dictionary in zones.slice(0,MAX_HOMES):
		var position := Vector2(zone.get("position",Vector2.ZERO))
		var radius := float(zone.get("radius",500.0))
		if not position.is_finite() or not is_finite(radius) or radius<=0: continue
		if world.distance_squared_to(position)>pow(radius*1.45,2): continue
		var field := _field(_local(world,zone,seed),str(zone.get("faction_id","HUMAN")),seed)
		if field<best or (is_equal_approx(field,best) and not chosen.is_empty() and _side(zone)<_side(chosen)):
			best=field
			chosen=zone
	return chosen


static func _local(world: Vector2, home: Dictionary, seed: int) -> Vector2:
	var q := (world-Vector2(home.get("position",Vector2.ZERO)))/maxf(float(home.get("radius",500.0)),1.0)
	var turn := posmod(seed/17+int(Vector2(home.get("position",Vector2.ZERO)).x)/32,4)
	if turn==1: return Vector2(-q.y,q.x)
	if turn==2: return -q
	if turn==3: return Vector2(q.y,-q.x)
	return q


static func _field(q: Vector2, faction: String, seed: int) -> float:
	var shape := 1.0
	match faction:
		"HUMAN": shape=minf(_box(q,Vector2(0.84,0.68),0.18),_ellipse(q-Vector2(0.42,0.36),Vector2(0.49,0.43)))
		"FOREST": shape=minf(minf(_ellipse(q,Vector2(0.74,0.74)),_ellipse(q-Vector2(-0.5,-0.27),Vector2(0.47,0.46))),minf(_ellipse(q-Vector2(0.48,-0.43),Vector2(0.5,0.44)),_ellipse(q-Vector2(0.43,0.39),Vector2(0.46,0.53))))
		"MACHINE": shape=minf(_box(q,Vector2(0.86,0.57),0.06),_box(q-Vector2(0.23,0.48),Vector2(0.49,0.35),0.06))
		"UNDEAD": shape=minf(minf(_ellipse(q,Vector2(0.7,0.59)),_capsule(q,Vector2.ZERO,Vector2(-0.72,-0.5),0.24)),minf(_capsule(q,Vector2.ZERO,Vector2(0.85,0.12),0.23),_capsule(q,Vector2.ZERO,Vector2(-0.05,0.84),0.23)))
		"HIGHLAND": shape=minf(_capsule(q,Vector2(-0.55,0.17),Vector2(0.54,-0.18),0.5),minf(_ellipse(q-Vector2(-0.19,-0.5),Vector2(0.48,0.43)),_ellipse(q-Vector2(0.58,0.35),Vector2(0.41,0.36))))
		"UNDERGROUND": shape=minf(minf(_ellipse(q,Vector2(0.69,0.64)),_ellipse(q-Vector2(-0.59,0.22),Vector2(0.45,0.5))),minf(_ellipse(q-Vector2(0.55,-0.3),Vector2(0.42,0.48)),_ellipse(q-Vector2(0.48,0.48),Vector2(0.34,0.34))))
		_: shape=_box(q,Vector2(0.84,0.68),0.18)
	# Slow contour undulations preserve broad forms, rather than random cells.
	var phase := float(posmod(seed,127))*0.037
	shape+=sin(q.x*5.7+phase)*sin(q.y*4.3-phase)*0.035
	return minf(shape,q.length()-0.48)


static func _textured(q: Vector2, faction: String) -> bool:
	match faction:
		# Three broad, rounded meadow groups, not narrow rectangular bands.
		# Only the detached secondary surface changes; ownership and the quiet
		# command core still come from the unchanged primary home silhouette.
		"HUMAN": return _ellipse(q-Vector2(-0.54,0.17),Vector2(0.22,0.23))<0 or _ellipse(q-Vector2(0.21,-0.49),Vector2(0.20,0.18))<0 or _ellipse(q-Vector2(0.44,0.36),Vector2(0.27,0.20))<0
		# Distinct secondary landforms, not a recolored ring: root crescents,
		# broken work terraces, branching peat beds, snow shelves and fungal lobes.
		"FOREST": return (q.length()>0.55 and q.length()<0.91 and q.x<0.42) or _ellipse(q-Vector2(0.49,-0.42),Vector2(0.27,0.30))<0 or _capsule(q,Vector2(0.37,0.29),Vector2(0.67,0.52),0.16)<0
		"MACHINE": return _box(q-Vector2(-0.35,-0.42),Vector2(0.38,0.16),0.04)<0 or _box(q-Vector2(0.34,0.39),Vector2(0.38,0.18),0.04)<0 or _box(q-Vector2(-0.62,0.20),Vector2(0.15,0.28),0.04)<0
		"UNDEAD": return _capsule(q,Vector2(-0.76,-0.34),Vector2(0.70,0.30),0.16)<0 or _capsule(q,Vector2(0.05,-0.72),Vector2(-0.17,0.83),0.15)<0 or _ellipse(q-Vector2(-0.56,0.21),Vector2(0.22,0.29))<0
		"HIGHLAND": return _capsule(q,Vector2(-0.83,0.31),Vector2(0.78,-0.30),0.19)<0 or _capsule(q,Vector2(-0.50,-0.66),Vector2(0.40,-0.46),0.21)<0 or _ellipse(q-Vector2(0.62,0.39),Vector2(0.34,0.29))<0 or _ellipse(q-Vector2(-0.58,0.38),Vector2(0.21,0.15))<0
		"UNDERGROUND": return _ellipse(q-Vector2(-0.59,0.26),Vector2(0.40,0.39))<0 or _ellipse(q-Vector2(0.50,-0.32),Vector2(0.33,0.40))<0 or _capsule(q,Vector2(0.32,0.45),Vector2(0.57,0.62),0.16)<0 or _ellipse(q-Vector2(-0.15,-0.55),Vector2(0.18,0.19))<0
	return false


static func _box(q: Vector2, half: Vector2, rounding: float) -> float:
	var d := q.abs()-half+Vector2.ONE*rounding
	return d.max(Vector2.ZERO).length()+minf(maxf(d.x,d.y),0.0)-rounding


static func _ellipse(q: Vector2, size: Vector2) -> float:
	return ((q/size).length()-1.0)*minf(size.x,size.y)


static func _capsule(q: Vector2, a: Vector2, b: Vector2, radius: float) -> float:
	return q.distance_to(Geometry2D.get_closest_point_to_segment(q,a,b))-radius


static func _supported(cells: Dictionary) -> Dictionary:
	var result := {}
	for cell: Vector2i in cells:
		var source: String=cells[cell]
		for corner: Vector2i in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.UP,Vector2i(-1,-1)]:
			var first := cell+corner
			if cells.get(first)==source and cells.get(first+Vector2i.RIGHT)==source and cells.get(first+Vector2i.DOWN)==source and cells.get(first+Vector2i.ONE)==source:
				result[cell]=source
				break
	return result
