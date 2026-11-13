extends RefCounted
## Original clustered scenery and truthful circular-union water. Supplied
## terrain records stay detached; crowns/peaks never create extra obstacles.
const MAX_WATER_BODIES := 24
const MAX_WATER_CONFIGS := 4
const WATER_STEPS := 48
const MAX_WATER_MARKS := 128
const WATER := Color("3b6d7c")
const BANK := Color("8c8c70")
const SHALLOW := Color("6e9896")
const INK := Color("2e423c")
const FrontierGround = preload("res://src/presentation/strategic_frontier_ground.gd")
static var _water_cache: Dictionary = {}
static var _water_order: Array[String] = []

static func draw_prop(canvas: Object, center: Vector2, terrain: Dictionary, scale_factor: float) -> void:
	if not is_finite(scale_factor) or scale_factor <= 0: return
	var radius := maxf(float(terrain.get("radius",40)),1)
	var pixel := maxf(radius*scale_factor/24.0,0.1)
	var variant := posmod(str(terrain.get("id","")).hash(),4)
	var faction := str(terrain.get("faction_id",""))
	if terrain.get("kind") == "TREE":
		# Five real-footprint grouped crowns, back to front. Each crown has a
		# readable light plane rather than a cloud of random isolated pixels.
		for member: Dictionary in [
			{"at":Vector2(-10,-9),"size":0.62}, {"at":Vector2(9,-8),"size":0.72},
			{"at":Vector2(-2,-2),"size":0.86}, {"at":Vector2(-12,8),"size":0.64},
			{"at":Vector2(11,9),"size":0.69},
		]:
			_draw_tree(canvas,center+Vector2(member.at)*pixel,pixel*float(member.size),variant,faction)
		for index: int in range(4):
			_rect(canvas,center,pixel,Rect2(-16+index*10,10+index%2*3,6,2),Color("62764f"))
	elif terrain.get("kind") == "MOUNTAIN":
		for member: Dictionary in [
			{"at":Vector2(-11,-5),"size":0.68}, {"at":Vector2(9,-3),"size":0.78},
			{"at":Vector2(-2,7),"size":0.93},
		]:
			_draw_peak(canvas,center+Vector2(member.at)*pixel,pixel*float(member.size),variant,faction)
		for index: int in range(6):
			var point := Vector2(-17+index*6,11+index%3*2)
			_rect(canvas,center,pixel,Rect2(point,Vector2(4,2)),Color("8e9a8c") if index%2 else Color("4d605b"))

static func _draw_tree(canvas: Object, center: Vector2, pixel: float, variant: int, faction: String="") -> void:
	var dark: Color = [Color("354c3d"),Color("344b44"),Color("3e5140"),Color("3b4c3a")][variant]
	var cultural: Dictionary = {"UNDEAD":Color("51464d"),"MACHINE":Color("4b554a"),"FOREST":Color("315c3e"),"HIGHLAND":Color("64746e"),"UNDERGROUND":Color("514b64")}
	if cultural.has(faction):dark=(cultural[faction] as Color).lightened(float(variant)*0.013)
	var leaf := dark.lightened(0.24)
	_rect(canvas,center,pixel,Rect2(-8,3,17,4),Color("2f4035",0.55))
	_rect(canvas,center,pixel,Rect2(-2,-20,4,27),Color("665240"))
	_rect(canvas,center,pixel,Rect2(0,-15,1,20),Color("a08357"))
	for tier: int in range(3):
		var y := -37+tier*10
		var extent := 9+tier*3
		_poly(canvas,center,pixel,[Vector2(-extent,y+13),Vector2(-extent+2,y+4),Vector2(-3,y-2),Vector2(2,y-4),Vector2(extent-1,y+5),Vector2(extent,y+13)],dark)
		_poly(canvas,center,pixel,[Vector2(-extent+3,y+8),Vector2(-3,y+1),Vector2(1,y-1),Vector2(4,y+7),Vector2(-1,y+10)],leaf)
		_rect(canvas,center,pixel,Rect2(4,y+9,extent-4,3),dark.lightened(0.1))
		_rect(canvas,center,pixel,Rect2(-4,y+4,4,2),Color("91a275"))
	canvas.draw_line((center+Vector2(-1,4)*pixel).round(),(center+Vector2(-6,7)*pixel).round(),Color("665240"),maxf(pixel,1))

static func _draw_peak(canvas: Object, center: Vector2, pixel: float, variant: int, faction: String="") -> void:
	var rock: Color = [Color("889489"),Color("8c9389"),Color("7d8d88"),Color("91998c")][variant]
	var cultural: Dictionary = {"UNDEAD":Color("847681"),"MACHINE":Color("8a9082"),"FOREST":Color("82987c"),"HIGHLAND":Color("adb8b1"),"UNDERGROUND":Color("9084a3")}
	if cultural.has(faction):rock=(cultural[faction] as Color).darkened(float(variant)*0.012)
	_poly(canvas,center,pixel,[Vector2(-17,9),Vector2(-13,-8),Vector2(-3,-35),Vector2(3,-38),Vector2(13,-13),Vector2(18,9)],Color("485b58"))
	_poly(canvas,center,pixel,[Vector2(3,-38),Vector2(13,-13),Vector2(18,9),Vector2(1,5),Vector2(-4,-9)],rock)
	_poly(canvas,center,pixel,[Vector2(-8,-20),Vector2(-3,-35),Vector2(3,-38),Vector2(7,-29),Vector2(10,-20),Vector2(3,-23),Vector2(-1,-19)],Color("c3c9b7"))
	_poly(canvas,center,pixel,[Vector2(4,-19),Vector2(9,-9),Vector2(7,-4),Vector2(12,4),Vector2(4,-1)],rock.darkened(0.2))
	canvas.draw_line((center+Vector2(-9,-5)*pixel).round(),(center+Vector2(-5,6)*pixel).round(),Color("71827a"),maxf(pixel,1))
	canvas.draw_line((center+Vector2(4,-17)*pixel).round(),(center+Vector2(10,-11)*pixel).round(),rock.lightened(0.2),maxf(pixel,1))
	_rect(canvas,center,pixel,Rect2(-9,4,6,2),Color("a0aa99"))

static func draw_water(canvas: Object, projected: Rect2, viewport: Rect2, terrain: Array, scale_factor: float, bounds: Rect2) -> void:
	if not is_finite(scale_factor) or scale_factor <= 0: return
	var waters: Array[Dictionary] = []
	for prop: Dictionary in terrain:
		if prop.get("kind") not in ["LAKE","RIVER"] or float(prop.get("radius",0)) <= 0: continue
		if waters.size() >= MAX_WATER_BODIES: break
		waters.append(prop)
	var geometry := _water_geometry(waters)
	var visible_edges: Array[Dictionary] = []
	for edge: Dictionary in geometry.edges:
		var a := _project(edge.a,projected,bounds,scale_factor)
		var b := _project(edge.b,projected,bounds,scale_factor)
		if not viewport.grow(8*scale_factor).has_point(a) and not viewport.grow(8*scale_factor).has_point(b): continue
		visible_edges.append({"a":a,"b":b,"inner_a":_project(edge.inner_a,projected,bounds,scale_factor),"inner_b":_project(edge.inner_b,projected,bounds,scale_factor)})
	# Outside bank is under ALL fills; overlap never leaves an internal beige
	# ring. Finite sampling concerns decorative shore only, not collision truth.
	for edge: Dictionary in visible_edges: canvas.draw_line(edge.a,edge.b,BANK,maxf(6*scale_factor,1))
	for fill: Dictionary in geometry.fills:
		var radius := float(fill.radius)*scale_factor
		var center := _project(fill.position,projected,bounds,scale_factor)
		if not viewport.grow(radius).has_point(center): continue
		var polygon := PackedVector2Array()
		for point: Vector2 in fill.polygon: polygon.append(_project(point,projected,bounds,scale_factor).round())
		canvas.draw_colored_polygon(polygon,WATER)
		FrontierGround.draw_water(canvas,polygon,fill.polygon)
	for edge: Dictionary in visible_edges: canvas.draw_line(edge.inner_a,edge.inner_b,SHALLOW,maxf(3*scale_factor,1))
	_draw_water_marks(canvas,projected,viewport,waters,scale_factor,bounds)

static func _water_geometry(waters: Array) -> Dictionary:
	# Cache immutable WORLD geometry, never a camera projection. Canonical
	# circle facts are the identity; camera, seed and tick cannot stale a shore.
	var signature := ""
	for body: Dictionary in waters: signature += "%s:%s:%s:%s;"%[str(body.get("id","")),str(body.kind),str(body.position),str(body.radius)]
	if _water_cache.has(signature): return _water_cache[signature]
	var exposed: Array[Dictionary] = []
	var fills: Array[Dictionary] = []
	for index: int in range(waters.size()):
		var body: Dictionary = waters[index]
		var origin := Vector2(body.position)
		var radius := float(body.radius)
		var polygon := PackedVector2Array()
		for step: int in range(WATER_STEPS):
			var angle := float(step)*TAU/WATER_STEPS
			var next_angle := float(step+1)*TAU/WATER_STEPS
			var a := origin+Vector2.from_angle(angle)*radius
			var b := origin+Vector2.from_angle(next_angle)*radius
			var mid := origin+Vector2.from_angle((angle+next_angle)*0.5)*radius
			polygon.append(a)
			if _covered_by_other(a,index,waters) or _covered_by_other(b,index,waters) or _covered_by_other(mid,index,waters): continue
			exposed.append({"a":a,"b":b,"inner_a":origin+Vector2.from_angle(angle)*maxf(radius-5,0),"inner_b":origin+Vector2.from_angle(next_angle)*maxf(radius-5,0)})
		fills.append({"position":origin,"radius":radius,"polygon":polygon})
	var result := {"edges":exposed,"fills":fills}
	if _water_order.size()>=MAX_WATER_CONFIGS: _water_cache.erase(_water_order.pop_front())
	_water_order.append(signature)
	_water_cache[signature] = result
	return result

static func _draw_water_marks(canvas: Object, projected: Rect2, viewport: Rect2, waters: Array, scale_factor: float, bounds: Rect2) -> void:
	var marks := 0
	var visited := {}
	var stride := 28.0
	while (ceil(viewport.size.x/(stride*scale_factor))+2)*(ceil(viewport.size.y/(stride*scale_factor))+2) > 512: stride *= 2
	for body: Dictionary in waters:
		var origin := Vector2(body.position)
		var radius := float(body.radius)
		var first := Vector2i(floor((origin.x-radius)/stride),floor((origin.y-radius)/stride))
		var cells := int(ceil(radius*2/stride))+2
		for row: int in range(cells):
			for column: int in range(cells):
				if marks >= MAX_WATER_MARKS: return
				var cell := first+Vector2i(column,row)
				if visited.has(cell): continue
				visited[cell] = true
				var key := posmod(cell.x*31+cell.y*17,11)
				var world := Vector2(cell)*stride+Vector2(7+key%7,11+key%5)
				var point := _project(world,projected,bounds,scale_factor)
				if not viewport.grow(6*scale_factor).has_point(point): continue
				if not _inside_union(world,waters,12) or not _inside_union(world+Vector2(10,0),waters,8): continue
				marks += 1
				var is_river := _inside_kind(world,waters,"RIVER")
				if is_river:
					canvas.draw_line(point,point+Vector2(0,10)*scale_factor,Color("87b1b3"),maxf(scale_factor,1))
					canvas.draw_line(point+Vector2(-3,6)*scale_factor,point+Vector2(0,10)*scale_factor,Color("87b1b3"),maxf(scale_factor,1))
					canvas.draw_line(point+Vector2(3,6)*scale_factor,point+Vector2(0,10)*scale_factor,Color("87b1b3"),maxf(scale_factor,1))
				else:
					canvas.draw_rect(Rect2(point.round(),Vector2(9+key%7,1)*scale_factor),Color("7a9f9e"))
					if key%3 == 0: canvas.draw_rect(Rect2((point+Vector2(5,3)*scale_factor).round(),Vector2(4,1)*scale_factor),Color("527e87"))

static func _covered_by_other(point: Vector2, excluded: int, waters: Array) -> bool:
	for index: int in range(waters.size()):
		if index == excluded: continue
		var body: Dictionary = waters[index]
		if point.distance_squared_to(Vector2(body.position)) < float(body.radius)*float(body.radius): return true
	return false

static func _inside_union(point: Vector2, waters: Array, margin: float = 0) -> bool:
	for body: Dictionary in waters:
		var radius := maxf(float(body.radius)-margin,0)
		if point.distance_squared_to(Vector2(body.position)) <= radius*radius: return true
	return false

static func _inside_kind(point: Vector2, waters: Array, kind: String) -> bool:
	for body: Dictionary in waters:
		if body.kind == kind and point.distance_squared_to(Vector2(body.position)) < float(body.radius)*float(body.radius): return true
	return false

static func _project(world: Vector2, projected: Rect2, bounds: Rect2, scale_factor: float) -> Vector2:
	return projected.position+(world-bounds.position)*scale_factor

static func _rect(canvas: Object, center: Vector2, pixel: float, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2((center+rect.position*pixel).round(),rect.size*pixel),color)

static func _poly(canvas: Object, center: Vector2, pixel: float, points: Array, color: Color) -> void:
	var polygon := PackedVector2Array()
	for point: Vector2 in points: polygon.append((center+point*pixel).round())
	canvas.draw_colored_polygon(polygon,color)
