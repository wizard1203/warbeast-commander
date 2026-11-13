extends RefCounted
## Original world-anchored pixel ground. Optional detached landscape records
## decorate the world; they never settle collision, navigation or speed.
const HomelandArt = preload("res://src/presentation/strategic_homeland_art.gd")
const FrontierGround = preload("res://src/presentation/strategic_frontier_ground.gd")
const FrontierCollection = preload("res://src/presentation/strategic_frontier_collection.gd")
const FrontierScenery = preload("res://src/presentation/strategic_frontier_scenery.gd")
const MAX_CELLS := 256
const HOME_COLOR_LAYERS := 48
const MAX_HOME_ZONES := 4
const MAX_ROAD_SEGMENTS := 160
const MAX_ROAD_MARKS := 192
const MAX_DECORATIONS := 96
const BIOMES := {
	"GRASSLAND":Color("58684b"), "WOODLAND":Color("45664a"), "DIRT":Color("70624c"),
	"SAND":Color("9b8b62"), "SNOWFIELD":Color("9baaa4"), "STONE":Color("616b67"),
	"ASHLAND":Color("615b61"), "INDUSTRIAL":Color("756c58"), "FUNGAL":Color("626079"),
}

static func draw(canvas: Object, projected: Rect2, viewport: Rect2, map_id: String, scale_factor: float, landscape: Dictionary = {}) -> void:
	if not is_finite(scale_factor) or scale_factor <= 0: return
	var field := projected.intersection(viewport)
	if field.size.x <= 0 or field.size.y <= 0: return
	var base: Color = {"river-crossroads":Color("425c48"), "highland-caldera":Color("5a6560"), "debug-frontier":Color("4b5d55")}.get(map_id,Color("536348"))
	canvas.draw_rect(field,base)
	var bounds: Rect2 = Rect2(landscape.get("bounds",Rect2i(Vector2i.ZERO,Vector2i(projected.size/scale_factor))))
	var zones: Array = landscape.get("home_zones",[])
	_draw_home_field(canvas,projected,viewport,bounds,scale_factor,zones,base)
	FrontierGround.draw_ground(canvas,projected,viewport,scale_factor)
	if FrontierCollection.enabled() and FrontierCollection.get_entry("grass_0").get("supported",false):
		# The painted material and authored small props replace coarse legacy
		# rectangular grass strokes and polygon cell patches, not supplement
		# them. Preserve continuous cultural color fields and actual roads.
		_draw_roads(canvas,projected,viewport,bounds,scale_factor,landscape.get("roads",[]))
		_draw_decorations(canvas,projected,viewport,bounds,scale_factor,landscape.get("decorations",[]))
		return
	var stride := 76.0 * scale_factor
	while (ceil(field.size.x/stride)+2)*(ceil(field.size.y/stride)+2) > MAX_CELLS: stride *= 2
	var first := Vector2i(floor((field.position.x-projected.position.x)/stride),floor((field.position.y-projected.position.y)/stride))
	var columns := int(ceil(field.size.x/stride))+2
	var rows := int(ceil(field.size.y/stride))+2
	var seed_value := int(landscape.get("seed",0))
	var inset := 8.0*scale_factor
	# Shrinking a narrow edge viewport by a full detail margin can create a
	# negative Rect2. Such views retain the flat ground, not tiny grass strokes.
	var detail_field := field.grow(-inset) if field.size.x>inset*2 and field.size.y>inset*2 else Rect2()
	var visited := 0
	for row: int in range(rows):
		for column: int in range(columns):
			if visited >= MAX_CELLS: break
			var cell := first+Vector2i(column,row)
			var key := posmod(cell.x*73856093 ^ cell.y*19349663 ^ seed_value*83492791,997)
			var point := projected.position+Vector2(cell)*stride
			var world := bounds.position+(point-projected.position+Vector2.ONE*stride*0.5)/scale_factor
			var color := _cell_color(base,map_id,cell,key,world,zones)
			# The grid bounds detail work, never paints the background as tiles.
			# The base/home field is continuous; only small jittered clusters live
			# here, with no big hexagons, dark gutters or checkerboard gradients.
			var patch := Rect2(point,Vector2.ONE*(stride+0.25)).intersection(field)
			# Edge intersections can have a positive 1e-5 width yet collapse
			# distinct polygon vertices at CanvasItem float precision. Do not
			# submit subpixel slivers; the base ground already fills this region.
			if patch.size.x < 1.0 or patch.size.y < 1.0: continue
			visited += 1
			var small := Rect2(point+Vector2(9+key%43,11+(key*7)%37)*scale_factor,Vector2(12+key%17,6+(key*3)%9)*scale_factor)
			if key%3 and small.size.x>=1 and small.size.y>=1 and field.encloses(small):
				var p := small.position
				var s := small.size
				canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(s.x*0.15,0),p+Vector2(s.x*0.71,0),p+Vector2(s.x,s.y*0.4),p+Vector2(s.x*0.78,s.y),p+Vector2(0,s.y*0.68)]),color.darkened(0.025+float(key%3)*0.008))
			var cluster := point+Vector2(22+key%25,24+key%29)*scale_factor
			if not detail_field.has_point(cluster): continue
			var faction := home_faction_at(world,zones)
			if faction.is_empty(): _draw_cell_detail(canvas,cluster,color,key,scale_factor,map_id)
			else: HomelandArt.draw_surface_detail(canvas,cluster,scale_factor,faction,key)
	_draw_roads(canvas,projected,viewport,bounds,scale_factor,landscape.get("roads",[]))
	_draw_decorations(canvas,projected,viewport,bounds,scale_factor,landscape.get("decorations",[]))

static func _draw_home_field(canvas: Object, projected: Rect2, viewport: Rect2, bounds: Rect2, scale_factor: float, zones: Array, base: Color) -> void:
	# Overlaid opaque nested fields give the home a smooth substantial biome
	# transition, independent of the coarse detail LOD and without tile seams.
	# Their many quiet color steps are not height contours or collision rings.
	var ordered := zones.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return _zone_key(a)<_zone_key(b))
	for zone: Dictionary in ordered.slice(0,MAX_HOME_ZONES):
		var world := Vector2(zone.get("position",Vector2.ZERO))
		var center := _project(world,projected,bounds,scale_factor)
		var world_radius := maxf(float(zone.get("radius",500)),1)
		var radius := world_radius*scale_factor
		if not viewport.grow(radius).has_point(center): continue
		var target: Color = BIOMES.get(str(zone.get("biome","GRASSLAND")).to_upper(),BIOMES.GRASSLAND)
		var phase := float(posmod(_zone_key(zone).hash(),1000))/1000.0*TAU
		var contour := PackedVector2Array()
		for angle: int in range(32):
			var theta := float(angle)*TAU/32
			contour.append(Vector2.from_angle(theta)*(0.91+0.06*sin(theta*3+phase)+0.03*cos(theta*5-phase)))
		for layer: int in range(1,HOME_COLOR_LAYERS):
			var ratio := float(layer)/HOME_COLOR_LAYERS
			var size := radius*(1-ratio)
			if size<1: continue
			var color := base.lerp(target,smoothstep(0.0,1.0,ratio)*0.8)
			var points := PackedVector2Array()
			for direction: Vector2 in contour: points.append(center+direction*size)
			var clipped := _clip_field(points,projected.intersection(viewport))
			if clipped.size()>=3: canvas.draw_colored_polygon(clipped,color)


static func _zone_key(zone: Dictionary) -> String:
	return str(zone.get("side_id",""))+":"+str(zone.get("position",Vector2.ZERO))+":"+str(zone.get("biome",""))


static func _nearest_home(world: Vector2,zones: Array) -> Dictionary:
	var result: Dictionary = {}
	var distance := INF
	var winner := ""
	for zone: Dictionary in zones:
		var at := Vector2(zone.get("position",Vector2.ZERO))
		var radius := maxf(float(zone.get("radius",500)),1)
		var next := world.distance_squared_to(at)
		var key := _zone_key(zone)
		if next>=radius*radius: continue
		if next<distance or (next==distance and key<winner):
			result=zone;distance=next;winner=key
	return result


static func home_faction_at(world: Vector2,zones: Array) -> String:
	var zone := _nearest_home(world,zones)
	if zone.is_empty(): return ""
	return str(zone.get("faction_id",{"GRASSLAND":"HUMAN","ASHLAND":"UNDEAD","INDUSTRIAL":"MACHINE","WOODLAND":"FOREST","SNOWFIELD":"HIGHLAND","FUNGAL":"UNDERGROUND"}.get(str(zone.get("biome","")),"HUMAN")))


static func _clip_field(points: PackedVector2Array, field: Rect2) -> PackedVector2Array:
	# Clip the cultural field to real map/view bounds, including narrow-edge
	# views; do not paint a homeland onto the void outside the battlefield.
	if field.size.x<1 or field.size.y<1:return PackedVector2Array()
	var result := points
	for edge: int in range(4):
		var output := PackedVector2Array()
		if result.is_empty():return output
		var axis := 0 if edge<2 else 1
		var limit := field.position[axis] if edge%2==0 else field.end[axis]
		var previous := result[-1]
		var previous_inside := previous[axis]>=limit if edge%2==0 else previous[axis]<=limit
		for point: Vector2 in result:
			var inside := point[axis]>=limit if edge%2==0 else point[axis]<=limit
			if inside!=previous_inside:
				var denominator := point[axis]-previous[axis]
				if absf(denominator)>0.000001:output.append(previous.lerp(point,(limit-previous[axis])/denominator))
			if inside:output.append(point)
			previous=point;previous_inside=inside
		result=output
	var clean := PackedVector2Array()
	for point: Vector2 in result:
		if clean.is_empty() or point.distance_squared_to(clean[-1])>0.000001:clean.append(point)
	if clean.size()>1 and clean[0].distance_squared_to(clean[-1])<0.000001:clean.remove_at(clean.size()-1)
	if clean.size()<3:return PackedVector2Array()
	var extent := Rect2(clean[0],Vector2.ZERO)
	var area := 0.0
	for index: int in range(clean.size()):
		extent=extent.expand(clean[index])
		area+=clean[index].cross(clean[(index+1)%clean.size()])
	return clean if extent.size.x>=1 and extent.size.y>=1 and absf(area)>=1 else PackedVector2Array()

static func _cell_color(base: Color, map_id: String, cell: Vector2i, key: int, world: Vector2, zones: Array) -> Color:
	var broad := posmod(int(floor(float(cell.x)/4))*31+int(floor(float(cell.y)/4))*17,13)
	var color := base.lightened(float(key%3)*0.004) if key%3 else base.darkened(0.006)
	if broad == 0: color = color.lerp(BIOMES.SAND,0.08)
	elif broad in [1,2]: color = color.lerp(BIOMES.DIRT,0.08)
	elif broad == 3: color = color.lerp(BIOMES.STONE,0.1)
	if map_id == "highland-caldera" and broad in [5,6]: color = color.lerp(BIOMES.SNOWFIELD,0.12)
	var zone := _nearest_home(world,zones)
	if not zone.is_empty():
		var radius := maxf(float(zone.get("radius",500)),1)
		var distance := world.distance_to(Vector2(zone.get("position",Vector2.ZERO)))
		var target: Color = BIOMES.get(str(zone.get("biome","GRASSLAND")).to_upper(),BIOMES.GRASSLAND)
		color = color.lerp(target,smoothstep(0.0,1.0,1.0-distance/radius)*0.8)
	return color

static func _draw_cell_detail(canvas: Object, point: Vector2, color: Color, key: int, scale_factor: float, map_id: String) -> void:
	var pale := color.lightened(0.2)
	var dark := color.darkened(0.16)
	if map_id == "highland-caldera" or key%5 == 0:
		canvas.draw_rect(Rect2(point,Vector2(15,5)*scale_factor),dark)
		canvas.draw_rect(Rect2(point+Vector2(2,-2)*scale_factor,Vector2(10,4)*scale_factor),pale)
		canvas.draw_rect(Rect2(point+Vector2(10,0)*scale_factor,Vector2(4,2)*scale_factor),color)
		canvas.draw_rect(Rect2(point+Vector2(-9,9)*scale_factor,Vector2(4,2)*scale_factor),dark)
	else:
		canvas.draw_rect(Rect2(point+Vector2(-4,2)*scale_factor,Vector2(19,3)*scale_factor),dark)
		canvas.draw_rect(Rect2(point+Vector2(0,-4)*scale_factor,Vector2(2,8)*scale_factor),pale)
		canvas.draw_rect(Rect2(point+Vector2(6,-2)*scale_factor,Vector2(3,6)*scale_factor),color.lightened(0.13))
		canvas.draw_rect(Rect2(point+Vector2(11,0)*scale_factor,Vector2(2,4)*scale_factor),pale)
		if key%7 == 0: canvas.draw_rect(Rect2(point+Vector2(2,-5)*scale_factor,Vector2(3,2)*scale_factor),Color("b3ad78"))

static func _draw_roads(canvas: Object, projected: Rect2, viewport: Rect2, bounds: Rect2, scale_factor: float, roads: Array) -> void:
	var segments := 0
	var marks := 0
	var frontier_tiles := 0
	for road: Dictionary in roads:
		var points: Array = road.get("points",[])
		var material := str(road.get("material","DIRT")).to_upper()
		var color: Color = {"STONE":Color("7b8074"),"BRICK":Color("97795b"),"SLAB":Color("85877a")}.get(material,Color("94805b"))
		var width := maxf(float(road.get("width",20))*scale_factor,1)
		for index: int in range(1,points.size()):
			if segments >= MAX_ROAD_SEGMENTS: return
			var start := _project(Vector2(points[index-1]),projected,bounds,scale_factor)
			var end := _project(Vector2(points[index]),projected,bounds,scale_factor)
			if not _segment_visible(start,end,viewport,width): continue
			if start.distance_squared_to(end)<0.0001: continue
			segments += 1
			# Width includes the complete soil shoulder: the painted strip never
			# exceeds what the router cleared. Broad muted layers read as a road,
			# not a thin ruled line or an unverified bridge over water.
			canvas.draw_line(start,end,color.darkened(0.32),width)
			canvas.draw_line(start,end,color.darkened(0.12),maxf(width-4*scale_factor,1))
			canvas.draw_line(start,end,color,maxf(width-10*scale_factor,1))
			canvas.draw_line(start,end,color.lightened(0.055),maxf(width-18*scale_factor,1))
			frontier_tiles += FrontierGround.draw_road(canvas,start,end,width,material,scale_factor,FrontierGround.MAX_ROAD_TILES-frontier_tiles)
			var direction := (end-start).normalized()
			var normal := direction.orthogonal()
			var distance := start.distance_to(end)
			# In overview the broad surface remains, fine paving is retired.
			if scale_factor<0.38: continue
			var step := maxf(32*scale_factor,9)
			for slot: int in range(1,mini(int(distance/step),48)):
				if marks >= MAX_ROAD_MARKS: break
				var at := start+direction*float(slot)*step
				if not viewport.grow(width).has_point(at): continue
				marks += 1
				if material == "SLAB":
					canvas.draw_line(at-normal*width*0.34,at+normal*width*0.34,color.darkened(0.22),maxf(scale_factor,1))
					for side: int in [-1,1]:
						var bolt := at+normal*width*0.29*side+direction*3*scale_factor
						canvas.draw_rect(Rect2(bolt-Vector2.ONE*scale_factor,Vector2.ONE*2*scale_factor),Color("b3ae93"))
				elif material in ["STONE","BRICK"]:
					# Staggered short paving seams, not full-width railway ties.
					for row: int in [-1,0,1]:
						var stone := at+normal*row*width*0.22+direction*(5 if (slot+row)%2==0 else -4)*scale_factor
						canvas.draw_line(stone-direction*5*scale_factor,stone+direction*6*scale_factor,color.lightened(0.14 if material=="STONE" else 0.09),maxf(3*scale_factor,1))
					canvas.draw_line(at-normal*width*0.31,at-normal*width*0.08,color.darkened(0.18),maxf(scale_factor,1))
				else:
					for side: int in [-1,1]:
						var rut := at+normal*width*0.22*side
						canvas.draw_line(rut-direction*step*0.4,rut+direction*step*0.4,color.darkened(0.13),maxf(2*scale_factor,1))
					canvas.draw_line(at+normal*width*0.06,at+normal*width*0.11+direction*5*scale_factor,color.lightened(0.13),maxf(2*scale_factor,1))

static func _draw_decorations(canvas: Object, projected: Rect2, viewport: Rect2, bounds: Rect2, scale_factor: float, decorations: Array) -> void:
	var count := 0
	var collection_count := 0
	for decor: Dictionary in decorations:
		var kind := str(decor.get("kind","GRASS")).to_upper()
		var point := _project(Vector2(decor.get("position",Vector2.ZERO)),projected,bounds,scale_factor)
		var pixel := clampf(float(decor.get("scale",1.0)),0.5,1.5)*scale_factor
		if kind == "FRONTIER":
			if collection_count >= FrontierScenery.VISIBLE_LIMIT: continue
			# Fine low props retire in strategic overview. Source-derived bounds
			# keep a partial edge sprite visible without adding hit geometry.
			if pixel < 0.22: continue
			var entry_id := str(decor.get("entry_id",""))
			var visual_bounds := FrontierCollection.bounds(entry_id,pixel)
			if visual_bounds.size != Vector2.ZERO:
				if not viewport.intersects(Rect2(point+visual_bounds.position,visual_bounds.size)): continue
				if FrontierCollection.draw(canvas,point,entry_id,pixel):
					collection_count += 1
					continue
			kind = str(decor.get("legacy_kind","GRASS"))
			pixel = clampf(float(decor.get("legacy_scale",1)),0.5,1.5)*scale_factor
		if count >= MAX_DECORATIONS: continue
		var minimum_pixel := 0.15 if kind=="HOMELAND" else 0.42
		if pixel < minimum_pixel or not viewport.grow((25 if kind=="HOMELAND" else 20)*pixel).has_point(point): continue
		count += 1
		var variant := int(decor.get("legacy_variant",decor.get("variant",0))) if decor.get("kind") == "FRONTIER" else int(decor.get("variant",0))
		if kind=="HOMELAND":
			HomelandArt.draw_cluster(canvas,point,pixel,str(decor.get("faction_id","HUMAN")),int(decor.get("legacy_family",decor.get("family",0))),variant)
			continue
		var hue: Color = BIOMES.get(str(decor.get("biome","GRASSLAND")).to_upper(),BIOMES.GRASSLAND)
		canvas.draw_rect(Rect2((point+Vector2(-7,1)*pixel).round(),Vector2(15,3)*pixel),Color(hue.darkened(0.26),0.65))
		if kind == "MUSHROOM":
			canvas.draw_rect(Rect2((point+Vector2(-1,-6)*pixel).round(),Vector2(3,8)*pixel),Color("a0a296"))
			canvas.draw_rect(Rect2((point+Vector2(-6,-9)*pixel).round(),Vector2(12,4)*pixel),Color("8c809c"))
			canvas.draw_rect(Rect2((point+Vector2(-3,-11)*pixel).round(),Vector2(7,3)*pixel),Color("b19caf"))
			canvas.draw_rect(Rect2((point+Vector2(2,-8)*pixel).round(),Vector2(2,1)*pixel),Color("d1c7b1"))
		elif kind == "CRYSTAL":
			canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(-5,2)*pixel,point+Vector2(-4,-8)*pixel,point+Vector2(0,-13)*pixel,point+Vector2(4,-5)*pixel,point+Vector2(3,2)*pixel]),Color("8f9caa"))
			canvas.draw_line(point+Vector2(0,-10)*pixel,point+Vector2(0,0)*pixel,Color("b9b5c5"),maxf(pixel,1))
			canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(5,2)*pixel,point+Vector2(5,-4)*pixel,point+Vector2(9,-7)*pixel,point+Vector2(11,2)*pixel]),Color("778d92"))
		elif kind in ["STONE","SNOW_PATCH"]:
			canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(-7,0)*pixel,point+Vector2(-4,-6)*pixel,point+Vector2(3,-7)*pixel,point+Vector2(8,-1)*pixel,point+Vector2(6,3)*pixel]),hue.lightened(0.18))
			canvas.draw_line(point+Vector2(-3,-5)*pixel,point+Vector2(3,-6)*pixel,hue.lightened(0.4),maxf(pixel,1))
			canvas.draw_rect(Rect2(point+Vector2(3,0)*pixel,Vector2(4,2)*pixel),hue.darkened(0.14))
		elif kind == "LOG":
			canvas.draw_rect(Rect2(point+Vector2(-9,-4)*pixel,Vector2(18,7)*pixel),Color("62513f"))
			canvas.draw_rect(Rect2(point+Vector2(-8,-4)*pixel,Vector2(4,6)*pixel),Color("b3986e"))
			canvas.draw_line(point+Vector2(-2,-2)*pixel,point+Vector2(7,-2)*pixel,Color("8b714f"),maxf(pixel,1))
		elif kind == "SCRAP":
			canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(-8,0)*pixel,point+Vector2(-3,-7)*pixel,point+Vector2(6,-5)*pixel,point+Vector2(9,2)*pixel]),Color("78776b"))
			canvas.draw_line(point+Vector2(-3,-5)*pixel,point+Vector2(5,-4)*pixel,Color("b1916e"),maxf(pixel,1))
			canvas.draw_rect(Rect2(point+Vector2(3,0)*pixel,Vector2(3,2)*pixel),Color("464f4c"))
		else:
			for blade: int in range(3):
				var height := (10 if kind == "REED" else 7 if kind == "BUSH" else 5)+blade%2*2
				var offset := Vector2(-5+blade*5,2-height-((variant+blade)%2))*pixel
				canvas.draw_rect(Rect2((point+offset).round(),Vector2(4 if kind == "BUSH" else 2,height)*pixel),hue.lightened(0.2+blade*0.02))
			if kind == "FLOWER": canvas.draw_rect(Rect2((point+Vector2(-1,-7)*pixel).round(),Vector2(3,3)*pixel),Color("c9b78d") if variant%2 else Color("b7a0a1"))

static func _project(world: Vector2, projected: Rect2, bounds: Rect2, scale_factor: float) -> Vector2:
	return projected.position+(world-bounds.position)*scale_factor

static func _segment_visible(start: Vector2, end: Vector2, viewport: Rect2, margin: float) -> bool:
	var box := Rect2(Vector2(minf(start.x,end.x),minf(start.y,end.y)),Vector2(absf(end.x-start.x),absf(end.y-start.y))).grow(margin)
	return box.intersects(viewport)
