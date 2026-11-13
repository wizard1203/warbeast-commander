extends Node3D
## Detached scenery for the optional M31 view. Every position is observation,
## never a collider, command, resource ledger, or movement authority.
const Landscape = preload("res://src/presentation/strategic_landscape_plan.gd")
const WORLD_SCALE := 1.0 / 24.0
const VERSION := "m33-terrain-variety-v1"
const WATER_STEP := 12.0
const MAX_STATIC_INSTANCES := 3600
const GROUND_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 home_a = vec4(0.0);
uniform vec4 home_b = vec4(0.0);
uniform vec4 home_c = vec4(0.0);
uniform vec4 home_d = vec4(0.0);
uniform bool ground_overlay = false;
varying vec2 land_uv;
varying vec4 land_tint;
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float noise21(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1.0,0.0)),f.x),mix(hash21(i+vec2(0.0,1.0)),hash21(i+vec2(1.0)),f.x),f.y);
}
vec3 biome(vec3 current, vec4 home, vec2 p) {
 float influence=(1.0-smoothstep(home.z*0.52,home.z,length(p-home.xy)))*step(0.01,home.z);
 vec3 shade=vec3(0.18,0.225,0.095);
 if(home.w>0.5 && home.w<1.5) shade=vec3(0.18,0.155,0.125);
 else if(home.w>1.5 && home.w<2.5) shade=vec3(0.20,0.195,0.145);
 else if(home.w>2.5 && home.w<3.5) shade=vec3(0.105,0.18,0.085);
 else if(home.w>3.5 && home.w<4.5) shade=vec3(0.43,0.465,0.405);
 else if(home.w>4.5) shade=vec3(0.135,0.17,0.145);
 return mix(current,shade,influence*0.65);
}
void vertex(){ land_uv=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; land_tint=COLOR; }
void fragment(){
 float broad=noise21(land_uv*0.16);
 float middle=noise21(land_uv*0.68+vec2(13.7,4.9));
 float fine=noise21(land_uv*7.2);
 float grit=noise21(land_uv*29.0);
 float earth=smoothstep(0.46,0.70,broad+middle*0.23);
 vec3 grass=mix(vec3(0.105,0.165,0.059),vec3(0.205,0.25,0.105),middle);
 vec3 soil=mix(vec3(0.18,0.145,0.085),vec3(0.26,0.215,0.125),middle);
 vec3 color=mix(grass,soil,earth*0.66);
 color=biome(biome(biome(biome(color,home_a,land_uv),home_b,land_uv),home_c,land_uv),home_d,land_uv);
 color*=0.90+fine*0.14+grit*0.045;
 if(ground_overlay) color=mix(color,land_tint.rgb*(0.87+fine*0.20+grit*0.08),land_tint.a);
 ALBEDO=color; ROUGHNESS=0.97; SPECULAR=0.1;
}
"""
const WATER_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec2 water_uv;
void vertex(){water_uv=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
 float ripples=sin(water_uv.x*6.2+water_uv.y*2.8+sin(water_uv.y*0.71)*0.8+TIME*0.55);
 float longwave=sin(water_uv.x*1.3-water_uv.y*2.1+TIME*0.26);
 float crest=smoothstep(0.93,1.0,ripples)*0.009;
 ALBEDO=mix(vec3(0.045,0.13,0.155),vec3(0.11,0.235,0.245),0.48+ripples*0.035+longwave*0.035)+vec3(crest);
 ROUGHNESS=0.40+ripples*0.015; SPECULAR=0.38; METALLIC=0.0;
 NORMAL=normalize(NORMAL+vec3(ripples*0.025,longwave*0.018,0.0));
}
"""

var _signature := ""
var _build_count := 0
var _static_root: Node3D
var _diagnostics: Dictionary = {}
var _source_visuals: Dictionary = {}
var _source_instances: Dictionary = {}
var _seed := 1701
var _bounds := Rect2i()
var _plan: Dictionary = {}
var _water: Array[Dictionary] = []
var _batches: Dictionary = {}
var _shared_meshes: Dictionary = {}
var _ground_shader: Shader
var _shared_vertex_material: StandardMaterial3D
var _allocated_instances := 0
var _vertices: PackedVector3Array
var _colors: PackedColorArray


func configure(snapshot: Dictionary, landscape_plan: Dictionary = {}) -> void:
	var plan := Landscape.build(snapshot) if landscape_plan.is_empty() else landscape_plan
	var identity := Landscape.signature(snapshot)+":"+str(plan.get("seed",1701))+":"+str(plan.get("collection_version","base"))+":"+VERSION
	if identity == _signature:
		set_resource_states(snapshot)
		return
	_signature = identity
	_build_count += 1
	_seed = int(plan.get("seed",1701))
	_plan = plan
	_bounds = Rect2i(plan.get("bounds",Rect2i()))
	if is_instance_valid(_static_root):
		remove_child(_static_root)
		_static_root.free()
	_static_root = Node3D.new()
	_static_root.name = "DetachedTerrain"
	add_child(_static_root)
	_batches.clear()
	_allocated_instances = 0
	_source_visuals.clear()
	_source_instances.clear()
	_diagnostics = {"version":VERSION,"build_count":_build_count,"signature":identity,
		"static_mesh_nodes":0,"multimesh_batches":0,"instances":0,"road_count":0,
		"water_triangles":0,"shore_triangles":0,"source_count":0,"terrain_bodies":0,
		"physics_nodes":0,"world_scale":WORLD_SCALE,"ground_triangles":2,"static_triangles":0,
		"prop_variants":[],"prop_mesh_triangles":{},"shore_rock_variants":[],"source_batches":0,
		"instanced_triangles":0,"instance_limit":MAX_STATIC_INSTANCES}
	if _bounds.size.x <= 0 or _bounds.size.y <= 0: return
	var config: Dictionary = snapshot.get("match_config",{})
	var terrain: Array = snapshot.get("terrain",config.get("terrain",[])).duplicate()
	terrain.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return str(a.get("id",""))<str(b.get("id","")))
	_water.clear()
	for body: Dictionary in terrain:
		if body.get("kind") in ["LAKE","RIVER"]: _water.append(body)
	_build_ground()
	_build_yards(snapshot)
	_build_roads()
	_build_water()
	_build_obstacles(terrain)
	_build_decorations()
	_build_sources(snapshot)
	_flush_batches()
	set_resource_states(snapshot)
	set_meta("environment_diagnostics",get_diagnostics())


func get_diagnostics() -> Dictionary:
	return _diagnostics.duplicate(true)


func set_resource_states(snapshot: Dictionary) -> void:
	var config: Dictionary = snapshot.get("match_config",{})
	for source: Dictionary in snapshot.get("resource_sources",config.get("sources",[])):
		var visual: Node3D = _source_visuals.get(str(source.get("id","")))
		if not is_instance_valid(visual): continue
		# Only crop tops and loose ore vanish; tilled beds and mine rubble remain.
		var visible := int(source.get("remaining",source.get("initial",1))) > 0
		if visual.has_meta("stock_visible") and bool(visual.get_meta("stock_visible")) == visible: continue
		visual.visible = visible
		visual.set_meta("stock_visible",visible)
		# Sources share spatially chunked material/mesh batches even on the
		# 24-source debug map. Touch only a changed source's range, not all crops
		# every tick; no resource or visibility fact is manufactured by the view.
		for record: Dictionary in _source_instances.get(str(source.get("id","")),[]):
			var transform: Transform3D = record.transform
			if not visible: transform.basis = transform.basis.scaled(Vector3.ZERO)
			(record.multimesh as MultiMesh).set_instance_transform(int(record.index),transform)
			record.submitted_transform = transform


static func world_position(point: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(point.x*WORLD_SCALE,height,point.y*WORLD_SCALE)


func _build_ground() -> void:
	_reset_mesh()
	var region := Rect2(_bounds).grow(64)
	_quad(world_position(region.position),world_position(Vector2(region.end.x,region.position.y)),world_position(region.end),world_position(Vector2(region.position.x,region.end.y)),Color.WHITE)
	_add_mesh("MeadowSoil",_finish_mesh(),_ground_material(false))


func _ground_material(overlay: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	if _ground_shader == null:
		_ground_shader = Shader.new()
		_ground_shader.code = GROUND_SHADER
	material.shader = _ground_shader
	material.set_shader_parameter("ground_overlay",overlay)
	var names := ["home_a","home_b","home_c","home_d"]
	var biome_ids := {"GRASSLAND":0,"ASHLAND":1,"INDUSTRIAL":2,"WOODLAND":3,"SNOWFIELD":4,"FUNGAL":5}
	var zones: Array = _plan.get("home_zones",[])
	for index: int in range(mini(zones.size(),4)):
		var zone: Dictionary = zones[index]
		var point := Vector2(zone.get("position",Vector2.ZERO))*WORLD_SCALE
		material.set_shader_parameter(names[index],Vector4(point.x,point.y,float(zone.get("radius",500))*WORLD_SCALE,float(biome_ids.get(zone.get("biome","GRASSLAND"),0))))
	return material


func _build_yards(snapshot: Dictionary) -> void:
	_reset_mesh()
	var config: Dictionary = snapshot.get("match_config",{})
	var sites: Array = snapshot.get("sites",config.get("sites",[])).duplicate()
	sites.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return str(a.get("id",""))<str(b.get("id","")))
	for site: Dictionary in sites:
		var point := Vector2(site.get("position",Vector2.ZERO))
		var radius := 118.0 if site.get("kind") == "RESOURCE" else 65.0
		var shade := Color("786c50")
		_irregular_patch(point+Vector2(0,22),radius,0.014,shade,_key(str(site.get("id",""))),0.77)
	_add_mesh("SettlementWornGround",_finish_mesh(),_ground_material(true))


func _build_roads() -> void:
	_reset_mesh()
	for road: Dictionary in _plan.get("roads",[]):
		var points: Array = road.get("points",[])
		if points.size() < 2: continue
		_diagnostics.road_count += 1
		var width := float(road.get("width",40))
		var material_id := str(road.get("material","DIRT"))
		var center := Color("87785b") if material_id in ["BRICK","STONE","SLAB"] else Color("786747")
		var edge := Color("6d6346")
		var sides: Array[Vector2] = []
		for index: int in range(points.size()):
			var tangent := Vector2(points[mini(index+1,points.size()-1)])-Vector2(points[maxi(index-1,0)])
			sides.append(Vector2(-tangent.y,tangent.x).normalized())
		for index: int in range(points.size()-1):
			var a := Vector2(points[index])
			var b := Vector2(points[index+1])
			var normal_a := sides[index]
			var normal_b := sides[index+1]
			for band: int in range(3):
				var offsets := [-0.55,-0.40,0.40,0.55]
				var colors := [Color(0,0,0,0),edge,center,Color(0,0,0,0)]
				var lo := float(offsets[band])*width
				var hi := float(offsets[band+1])*width
				_quad_colors(world_position(a+normal_a*lo,0.025),world_position(b+normal_b*lo,0.025),world_position(b+normal_b*hi,0.025),world_position(a+normal_a*hi,0.025),colors[band],colors[band],colors[band+1],colors[band+1])
			# Sparsely exposed slabs, with a packed-earth centre still dominant.
			if material_id in ["BRICK","STONE","SLAB"]:
				var distance := a.distance_to(b)
				var direction := (b-a).normalized()
				var count := mini(floori(distance/20),192)
				for tile: int in range(count):
					for lane: int in range(4):
						var key := _key(str(road.get("id",""))+":"+str(index)+":"+str(tile)+":"+str(lane))
						if key%3 != 0: continue
						var p := a+direction*(10+float(tile)*20+float(key%9)-4)+normal_a*((float(lane)-1.5)*width*0.20+float(key%7)-3)
						var half := direction*(4.5+key%4)
						var side := normal_a*(3.5+key%3)
						_quad(world_position(p-half-side,0.031),world_position(p+half-side,0.031),world_position(p+half+side,0.031),world_position(p-half+side,0.031),Color("898573").darkened(float(key%5)*0.025))
	_add_mesh("LinkedWornRoads",_finish_mesh(),_ground_material(true))


func _build_water() -> void:
	if _water.is_empty(): return
	# Sample the actual union, not each lake independently: touching lobes have
	# one continuous shoreline and never acquire interior sand rings.
	var cells: Dictionary = {}
	for water: Dictionary in _water:
		var point := Vector2(water.get("position",Vector2.ZERO))
		var radius := float(water.get("radius",40))+24
		for x: int in range(floori((point.x-radius)/WATER_STEP),ceili((point.x+radius)/WATER_STEP)):
			for z: int in range(floori((point.y-radius)/WATER_STEP),ceili((point.y+radius)/WATER_STEP)):
				cells[Vector2i(x,z)] = true
	var keys := cells.keys()
	keys.sort_custom(func(a: Vector2i,b: Vector2i)->bool:return a.x<b.x if a.y==b.y else a.y<b.y)
	var shores: Array = []
	var water_faces: Array = []
	for cell: Vector2i in keys:
		var origin := Vector2(cell)*WATER_STEP
		var corners := [origin,origin+Vector2(WATER_STEP,0),origin+Vector2(WATER_STEP,WATER_STEP),origin+Vector2(0,WATER_STEP)]
		for triangle: Array in [[corners[0],corners[1],corners[2]],[corners[0],corners[2],corners[3]]]:
			var values: Array = []
			for point: Vector2 in triangle: values.append({"p":point,"d":_water_distance(point)})
			var bank := _clip_field(_clip_field(values,19.0,true),-2.0,false)
			var wet := _clip_field(_clip_field(values,2.0,true),-5.0,false)
			var surface := _clip_field(values,-2.0,true)
			if bank.size() >= 3: shores.append({"points":bank,"color":Color("929174"),"height":0.018,"fade":true})
			if wet.size() >= 3: shores.append({"points":wet,"color":Color("607967"),"height":0.020})
			if surface.size() >= 3: water_faces.append(surface)
	_reset_mesh()
	for shore: Dictionary in shores: _field_polygon(shore.points,float(shore.height),shore.color,bool(shore.get("fade",false)))
	_diagnostics.shore_triangles = _vertices.size()/3
	_add_mesh("ContinuousWaterBanks",_finish_mesh(),_ground_material(true))
	_reset_mesh()
	for polygon: Array in water_faces: _field_polygon(polygon,0.026,Color.WHITE)
	_diagnostics.water_triangles = _vertices.size()/3
	var shader := Shader.new()
	shader.code = WATER_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	_add_mesh("LakeRiverUnion",_finish_mesh(),material)
	_queue_shore_props()


func _water_distance(point: Vector2) -> float:
	var distance := INF
	for body: Dictionary in _water:
		distance = minf(distance,point.distance_to(Vector2(body.get("position",Vector2.ZERO)))-float(body.get("radius",40)))
	return distance


func _clip_field(polygon: Array, threshold: float, lower: bool) -> Array:
	var result: Array = []
	if polygon.is_empty(): return result
	for index: int in range(polygon.size()):
		var a: Dictionary = polygon[index]
		var b: Dictionary = polygon[(index+1)%polygon.size()]
		var inside_a: bool = float(a.d)<=threshold if lower else float(a.d)>=threshold
		var inside_b: bool = float(b.d)<=threshold if lower else float(b.d)>=threshold
		if inside_a: result.append(a)
		if inside_a != inside_b:
			var fraction := (threshold-float(a.d))/(float(b.d)-float(a.d))
			result.append({"p":Vector2(a.p).lerp(Vector2(b.p),fraction),"d":threshold})
	return result


func _field_polygon(polygon: Array, height: float, color: Color, fade: bool = false) -> void:
	for index: int in range(1,polygon.size()-1):
		var indices := [0,index,index+1]
		var colors: Array[Color] = []
		for vertex: int in indices:
			var alpha := clampf((19.0-float(polygon[vertex].d))/21.0,0,1)*0.78 if fade else 1.0
			colors.append(Color(color,alpha))
		_triangle(world_position(polygon[0].p,height),world_position(polygon[index].p,height),world_position(polygon[index+1].p,height),colors[0],colors[1],colors[2])


func _queue_shore_props() -> void:
	for body: Dictionary in _water:
		var identity := str(body.get("id",""))
		var center := Vector2(body.get("position",Vector2.ZERO))
		var radius := float(body.get("radius",40))
		for index: int in range(24):
			var key := _key(identity+":"+str(index))
			var angle := (float(index)+float(key%17)/17)*TAU/24
			var point := center+Vector2.from_angle(angle)*(radius+5)
			# A circle seam inside a joined lake is not a shoreline. All props
			# stay within the already unreachable body-radius margin at the bank.
			if _water_distance(point)<1 or _water_distance(point)>9: continue
			if key%3 == 0:
				var rock_kind := "rock_"+str(_key(identity+":bank-rock:"+str(index))%3)
				if not _diagnostics.shore_rock_variants.has(rock_kind): _diagnostics.shore_rock_variants.append(rock_kind)
				_instance(rock_kind,world_position(point),Vector3(0.32,0.22,0.28),angle,Color("9b9f8d"))
			else:
				_instance("reed",world_position(point),Vector3.ONE*(0.65+float(key%7)*0.07),angle,Color.WHITE)


func _build_obstacles(terrain: Array) -> void:
	for obstacle: Dictionary in terrain:
		var kind := str(obstacle.get("kind",""))
		var point := Vector2(obstacle.get("position",Vector2.ZERO))
		var radius := float(obstacle.get("radius",40))*WORLD_SCALE
		var rng := RandomNumberGenerator.new()
		rng.seed = _key(str(obstacle.get("id","")))
		if kind == "TREE":
			_diagnostics.terrain_bodies += 1
			var biome := _biome_at(point)
			for index: int in range(3):
				var angle := float(index)*TAU/3+rng.randf_range(-0.15,0.15)
				var offset := Vector2.from_angle(angle)*radius*0.48
				var position := world_position(point)+Vector3(offset.x,0,offset.y)
				var scale_value := rng.randf_range(0.74,0.96)
				var tree := "pine" if biome == "SNOWFIELD" or (index%3 != 0 and biome not in ["WOODLAND","FUNGAL"]) else "oak"
				var variant := _key(str(obstacle.get("id",""))+":tree:"+str(index))%3
				_instance(tree+"_"+str(variant),position,Vector3.ONE*scale_value,rng.randf()*TAU,_biome_tint(biome))
		elif kind == "MOUNTAIN":
			_diagnostics.terrain_bodies += 1
			for index: int in range(8):
				var offset := Vector2.from_angle(rng.randf()*TAU)*radius*rng.randf_range(0.0,0.50)
				var size := rng.randf_range(radius*0.34,radius*0.72)
				_instance("rock_"+str(index%3),world_position(point)+Vector3(offset.x,0,offset.y),Vector3(size,size*rng.randf_range(1.0,1.6),size),rng.randf()*TAU,Color("c0bda6"))
		elif kind in ["RUIN","MONUMENT"]:
			for index: int in range(3):
				var offset := Vector3(float(index-1)*0.55,0.0,0.15*index)
				_instance("ruin",world_position(point)+offset,Vector3(0.55,1.3 if kind == "MONUMENT" else 0.55,0.55),float(index)*0.8,Color("c2b99c"))


func _build_decorations() -> void:
	for decoration: Dictionary in _plan.get("decorations",[]):
		var point := Vector2(decoration.get("position",Vector2.ZERO))
		var key := _key(str(point))
		var family := str(decoration.get("family",decoration.get("kind","GRASS"))).to_lower()
		var biome := str(decoration.get("biome","GRASSLAND"))
		var tint := _biome_tint(biome)
		var position := world_position(point)
		var scale_value := clampf(float(decoration.get("scale",1)),0.7,1.25)
		if family == "stone":
			for index: int in range(3):
				var offset := Vector3(float((key+index*7)%19-9)/25,0,float((key+index*11)%17-8)/25)
				_instance("rock_"+str((key+index)%3),position+offset,Vector3.ONE*(0.20+float((key+index)%7)/28),float(key+index),Color("b2ac91"))
		elif family in ["deadwood","log"]:
			_instance("deadwood",position,Vector3.ONE*(0.7+float(key%4)*0.1),float(key%100)*0.1,tint)
		elif family in ["bush","fern","mushroom","flower","supplies","crystal","bones","ruin","reed","scrap"]:
			var mesh_kind := "supplies" if family == "scrap" else family
			_instance(mesh_kind,position,Vector3.ONE*scale_value,float(key%100)*0.1,tint)
		else:
			for index: int in range(5):
				var offset := Vector3(float((key+index*7)%23-11)/19,0,float((key+index*13)%21-10)/19)
				_instance("grass",position+offset,Vector3.ONE*(0.65+float((key+index)%8)*0.07),float(key%100)*0.1,tint)


func _biome_at(point: Vector2) -> String:
	var biome := str({"river-crossroads":"WOODLAND","highland-caldera":"ROCKLAND","debug-frontier":"DRYLAND"}.get(str(_plan.get("map_id","")),"GRASSLAND"))
	var nearest := INF
	for zone: Dictionary in _plan.get("home_zones",[]):
		var distance := point.distance_squared_to(Vector2(zone.get("position",Vector2.ZERO)))
		if distance <= float(zone.get("radius",0))*float(zone.get("radius",0)) and distance < nearest:
			nearest = distance
			biome = str(zone.get("biome",biome))
	return biome


func _biome_tint(biome: String) -> Color:
	return {"SNOWFIELD":Color("d5d8c5"),"ASHLAND":Color("bba491"),"INDUSTRIAL":Color("b8b29b"),
		"FUNGAL":Color("a8c5b8"),"WOODLAND":Color("a7c18d"),"DRYLAND":Color("c6b58e")}.get(biome,Color.WHITE)


func _build_sources(snapshot: Dictionary) -> void:
	var config: Dictionary = snapshot.get("match_config",{})
	_reset_mesh()
	var sources: Array = snapshot.get("resource_sources",config.get("sources",[])).duplicate()
	sources.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return str(a.get("id",""))<str(b.get("id","")))
	for source: Dictionary in sources:
		var identity := str(source.get("id",""))
		var point := Vector2(source.get("position",Vector2.ZERO))
		var root := Node3D.new()
		root.name = "Source_"+identity.replace(":","_")
		root.set_meta("source_id",identity)
		_static_root.add_child(root)
		_source_visuals[identity] = root
		_diagnostics.source_count += 1
		if source.get("kind") == "FOOD" or source.get("resource") == "FOOD":
			var center := world_position(point)
			_quad(center+Vector3(-1.55,0.036,-1.5),center+Vector3(1.55,0.036,-1.5),center+Vector3(1.55,0.036,1.5),center+Vector3(-1.55,0.036,1.5),Color("51442c"))
			for row: int in range(6):
				var z := -1.22+float(row)*0.47
				_quad(center+Vector3(-1.5,0.040,z-0.10),center+Vector3(1.5,0.040,z-0.10),center+Vector3(1.5,0.040,z+0.10),center+Vector3(-1.5,0.040,z+0.10),Color("6b5935"))
				for column: int in range(12):
					var position := center+Vector3(-1.38+float(column)*0.25,0.045,z)
					_instance("wheat",position,Vector3.ONE*(0.85+float((row+column)%4)*0.08),float(column)*0.7,Color.WHITE,root)
		else:
			_irregular_patch(point,45,0.036,Color("615c4c"),_key(identity),0.85)
			for index: int in range(7):
				var angle := float(index)*2.399
				var offset := Vector3(cos(angle),0,sin(angle))*(0.3+float(index%3)*0.38)
				var size := 0.58+float(index%3)*0.25
				_instance("ore",world_position(point)+offset,Vector3(size,size*1.25,size),angle,Color.WHITE,root)
	_add_mesh("FiniteSourceGround",_finish_mesh(),_ground_material(true))


func _instance(kind: String, position: Vector3, size: Vector3, angle: float, tint: Color, parent: Node3D = null) -> void:
	if _allocated_instances >= MAX_STATIC_INSTANCES: return
	var batch_key := kind
	if parent != null:
		# Four quadrants retain coarse frustum culling. One batch per source
		# wastes submissions; one batch for the entire map wastes unseen work.
		var center := world_position(Vector2(_bounds.get_center()))
		var quadrant := (1 if position.x >= center.x else 0)+(2 if position.z >= center.z else 0)
		batch_key += "@"+str(quadrant)
	if not _batches.has(batch_key): _batches[batch_key] = {"kind":kind,"transforms":[],"colors":[],"sources":[]}
	var transforms: Array = _batches[batch_key].transforms
	if transforms.size() >= MAX_STATIC_INSTANCES: return
	transforms.append(Transform3D(Basis(Vector3.UP,angle).scaled(size),position))
	_batches[batch_key].colors.append(tint)
	_batches[batch_key].sources.append(str(parent.get_meta("source_id","")) if parent != null else "")
	_allocated_instances += 1


func _flush_batches() -> void:
	for key: String in _batches:
		var batch: Dictionary = _batches[key]
		var count := int(batch.transforms.size())
		if count == 0: continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = _prop_mesh(str(batch.kind))
		multimesh.instance_count = count
		for index: int in range(count):
			multimesh.set_instance_transform(index,batch.transforms[index])
			# These are subtle local colour variations over an already shaded mesh,
			# not a second full material albedo (which would double-darken stone).
			multimesh.set_instance_color(index,Color(batch.colors[index]).srgb_to_linear().lerp(Color.WHITE,0.72))
			var source_id := str(batch.sources[index])
			if not source_id.is_empty():
				if not _source_instances.has(source_id): _source_instances[source_id] = []
				_source_instances[source_id].append({"multimesh":multimesh,"index":index,"transform":batch.transforms[index],"submitted_transform":batch.transforms[index]})
		var node := MultiMeshInstance3D.new()
		node.name = "Instances_"+key.replace("@","_")
		node.multimesh = multimesh
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if batch.kind in ["grass","wheat"] else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_static_root.add_child(node)
		_diagnostics.multimesh_batches += 1
		_diagnostics.instances += count
		if not _diagnostics.prop_variants.has(str(batch.kind)): _diagnostics.prop_variants.append(str(batch.kind))
		var triangles := int(multimesh.mesh.surface_get_array_len(0)/3)
		_diagnostics.prop_mesh_triangles[str(batch.kind)] = triangles
		_diagnostics.instanced_triangles += triangles*count
		if "@" in key: _diagnostics.source_batches += 1
	_diagnostics.prop_variants.sort()


func _prop_mesh(kind: String) -> ArrayMesh:
	if _shared_meshes.has(kind): return _shared_meshes[kind]
	var saved_vertices := _vertices
	var saved_colors := _colors
	_reset_mesh()
	var family := kind.get_slice("_",0)
	var variant := kind.get_slice("_",1).to_int() if "_" in kind else 0
	if family in ["rock","ore"]:
		var stone_size := [Vector3(1,0.82,0.86),Vector3(0.82,1.12,0.76),Vector3(1.15,0.55,0.85)][variant%3] as Vector3
		_rock(Vector3(0,stone_size.y*0.72,0),stone_size,Color("92988c") if family == "rock" else Color("8f958e"),11+variant*3,true)
		if family == "ore":
			_rock(Vector3(0.22,0.85,0.30),Vector3(0.22,0.28,0.16),Color("9d9171"),5,true)
			_rock(Vector3(-0.42,0.62,-0.12),Vector3(0.18,0.37,0.21),Color("8e9b8f"),4,true)
	elif family == "pine":
		var lean := float([0.03,-0.20,0.16][variant%3])
		var crown_width := float([1.30,1.02,1.30][variant%3])
		var tier_count := 6+variant%2
		_cylinder(Vector3(0,0,0),Vector3(lean,4.2+float(variant)*0.12,0.04),0.19,0.07,Color("59442c"),7)
		for level: int in range(tier_count):
			var height := 1.15+float(level)*(0.48+variant*0.035)
			var radius := crown_width-float(level)*crown_width/8.2
			_conifer_tier(Vector3(lean*height/4.2,height,0),radius,1.25+float(variant%2)*0.22,Color("506e3e").lightened(float(level%3)*0.025),level+variant)
	elif family == "oak":
		_cylinder(Vector3(0,0,0),Vector3(0.12,2.7,0),0.23,0.14,Color("604c31"),7)
		for index: int in range(5+variant%2):
			var angle := float(index)*2.399
			var endpoint := Vector3(cos(angle)*(0.65+variant*0.06),2.45+float(index%3)*0.34+variant*0.08,sin(angle)*0.75)
			_cylinder(Vector3(0,1.8,0),endpoint,0.10,0.045,Color("604c31"),5)
			var crown := Vector3(0.86-variant*0.04,0.76-variant*0.08,0.84)
			_rock(endpoint,crown,Color("6e874b").lightened(float(index%3)*0.025),20+index+variant*7)
	elif family == "bush":
		for index: int in range(5):
			var angle := float(index)*2.399
			_rock(Vector3(cos(angle)*0.36,0.27+float(index%2)*0.11,sin(angle)*0.36),Vector3(0.48,0.38,0.43),Color("657641").lightened(float(index%2)*0.035),index+7)
	elif family == "deadwood":
		_cylinder(Vector3(-0.65,0.16,0),Vector3(0.62,0.21,0.14),0.18,0.16,Color("5e5138"),7)
		_cylinder(Vector3(-0.05,0.23,0.08),Vector3(0.30,0.57,0.28),0.085,0.025,Color("756142"),5)
	elif family == "fern":
		for frond: int in range(7):
			var angle := float(frond)*2.399
			var direction := Vector3(cos(angle),0,sin(angle))
			var side := Vector3(-direction.z,0,direction.x)
			for leaf: int in range(5):
				var fraction := float(leaf+1)/6
				var stem := direction*fraction*0.78+Vector3(0,sin(fraction*PI)*0.42+0.06,0)
				var width := (1-fraction)*0.23
				_triangle(stem-direction*0.12,stem+side*width+direction*0.14,stem+direction*0.15,Color("557545"),Color("86a05d"),Color("658447"))
				_triangle(stem-direction*0.12,stem-side*width+direction*0.14,stem+direction*0.15,Color("557545"),Color("86a05d"),Color("658447"))
	elif family == "flower":
		for index: int in range(5):
			var angle := float(index)*2.399
			var base := Vector3(cos(angle)*0.43,0,sin(angle)*0.43)
			var top := base+Vector3(0,0.34+float(index%3)*0.12,0)
			_cylinder(base,top,0.018,0.009,Color("5c7c43"),3)
			var petal := Color("d5bc78") if index%2 == 0 else Color("b5b9cf")
			for leaf: int in range(5):
				var direction := Vector3(cos(float(leaf)*TAU/5),0,sin(float(leaf)*TAU/5))
				var side := Vector3(-direction.z,0,direction.x)*0.058
				_triangle(top,top+direction*0.17+side+Vector3(0,0.045,0),top+direction*0.17-side+Vector3(0,0.045,0),Color("d3b25f"),petal,petal)
	elif family == "mushroom":
		for index: int in range(4):
			var angle := float(index)*2.399
			var base := Vector3(cos(angle)*0.38,0,sin(angle)*0.38)
			var top := base+Vector3(0,0.25+float(index%3)*0.14,0)
			_cylinder(base,top,0.055,0.037,Color("bdb598"),5)
			var cap := Color("a58072") if index%2 else Color("aa7a56")
			for side: int in range(8):
				var a := top+Vector3(cos(float(side)*TAU/8),0,sin(float(side)*TAU/8))*0.25
				var b := top+Vector3(cos(float(side+1)*TAU/8),0,sin(float(side+1)*TAU/8))*0.25
				_triangle(a,b,top+Vector3(0,0.17,0),cap.darkened(float(side%3)*0.045),cap,cap.lightened(0.04))
	elif family == "crystal":
		for index: int in range(5):
			var angle := float(index)*2.399
			var point := Vector3(cos(angle)*0.32,0,sin(angle)*0.32)
			_crystal(point,0.40+float(index%3)*0.25,0.12+float(index%2)*0.04,Color("81aaa2"),index)
	elif family == "supplies":
		_box(Vector3(-0.27,0.25,0),Vector3(0.52,0.50,0.56),Color("94744a"))
		_box(Vector3(-0.27,0.26,0),Vector3(0.55,0.07,0.59),Color("5a503c"))
		_box(Vector3(-0.27,0.25,0),Vector3(0.07,0.52,0.59),Color("5a503c"))
		_cylinder(Vector3(0.36,0,0.15),Vector3(0.36,0.56,0.15),0.23,0.21,Color("967a52"),8)
		_cylinder(Vector3(0.36,0.08,0.15),Vector3(0.36,0.14,0.15),0.235,0.235,Color("5e6459"),8)
		_cylinder(Vector3(0.36,0.39,0.15),Vector3(0.36,0.45,0.15),0.225,0.225,Color("5e6459"),8)
	elif family == "bones":
		var bone := Color("c5bfa5")
		_cylinder(Vector3(-0.57,0.07,-0.16),Vector3(0.53,0.10,0.17),0.05,0.05,bone,5)
		for index: int in range(5):
			var x := -0.32+float(index)*0.14
			_cylinder(Vector3(x,0.09,-0.21),Vector3(x,0.24,0),0.034,0.03,bone,4)
			_cylinder(Vector3(x,0.24,0),Vector3(x,0.08,0.30),0.03,0.034,bone,4)
		_box(Vector3(0.57,0.17,0.17),Vector3(0.24,0.25,0.23),bone)
		_box(Vector3(0.57,0.20,0.294),Vector3(0.12,0.06,0.01),Color("6f705b"))
	elif family == "ruin":
		for row: int in range(3):
			for column: int in range(3-row):
				var offset := float(row%2)*0.17
				_box(Vector3(float(column)*0.38-0.43+offset,float(row)*0.22+0.12,0),Vector3(0.35,0.20,0.32),Color("96947f").darkened(float((row+column)%3)*0.045))
		_box(Vector3(0.49,0.10,0.43),Vector3(0.40,0.18,0.26),Color("858772"))
	elif family == "wheat":
		for index: int in range(3):
			var offset := Vector3(float(index-1)*0.065,0,float(index%2)*0.06)
			var top := offset+Vector3(float(index-1)*0.035,0.55+float(index%2)*0.12,0.03)
			_cylinder(offset,top,0.012,0.007,Color("9b944b"),3)
			_grain(top,Color("cbb56e"))
	elif family == "reed":
		for index: int in range(6):
			var angle := float(index)*2.399
			var offset := Vector3(cos(angle)*0.13,0,sin(angle)*0.13)
			var top := offset+Vector3(cos(angle)*0.08,0.55+float(index%3)*0.12,sin(angle)*0.08)
			_cylinder(offset,top,0.012,0.007,Color("78884f"),4)
			_triangle(offset+Vector3(0,0.12,0),top*0.8+Vector3(cos(angle)*0.18,0,sin(angle)*0.18),top*0.65,Color("677b43"),Color("8b9754"),Color("677b43"))
			if index%2 == 0: _rock(top,Vector3(0.024,0.095,0.024),Color("6d6044"),index+2)
	else:
		for index: int in range(7):
			var angle := float(index)*2.399
			var offset := Vector3(cos(angle)*0.07,0,sin(angle)*0.07)
			var tip := offset+Vector3(cos(angle)*0.13,0.24+float(index%3)*0.07,sin(angle)*0.13)
			_triangle(offset+Vector3(-0.028,0,0),tip,offset+Vector3(0.028,0,0),Color("68763d"),Color("81904d"),Color("68763d"))
	var mesh := _finish_mesh()
	mesh.surface_set_material(0,_vertex_material())
	_shared_meshes[kind] = mesh
	_vertices = saved_vertices
	_colors = saved_colors
	return mesh


func _box(center: Vector3, size: Vector3, color: Color) -> void:
	var box := AABB(center-size*0.5,size)
	for face: Array in [[0,2,3,1],[4,5,7,6],[0,1,5,4],[2,6,7,3],[0,4,6,2],[1,3,7,5]]:
		_quad(box.get_endpoint(face[0]),box.get_endpoint(face[1]),box.get_endpoint(face[2]),box.get_endpoint(face[3]),color)


func _crystal(base: Vector3, height: float, width: float, color: Color, variant: int) -> void:
	for index: int in range(6):
		var a := float(index)*TAU/6
		var b := float(index+1)*TAU/6
		var low_a := base+Vector3(cos(a)*width,0,sin(a)*width)
		var low_b := base+Vector3(cos(b)*width,0,sin(b)*width)
		var upper_a := low_a+Vector3(0,height*0.65,0)
		var upper_b := low_b+Vector3(0,height*0.65,0)
		var shade := color.darkened(float((index+variant)%4)*0.065)
		_quad(low_a,low_b,upper_b,upper_a,shade)
		_triangle(upper_a,upper_b,base+Vector3(width*0.20,height,0),shade,shade,shade.lightened(0.08))


func _grain(center: Vector3, color: Color) -> void:
	# A readable angular seed head, rather than a 64-triangle microscopic sphere.
	for index: int in range(4):
		var a := float(index)*TAU/4
		var b := float(index+1)*TAU/4
		var current := center+Vector3(cos(a)*0.052,0,sin(a)*0.052)
		var next := center+Vector3(cos(b)*0.052,0,sin(b)*0.052)
		_triangle(current,next,center+Vector3(0,0.17,0),color,color,color.lightened(0.04))
		_triangle(next,current,center+Vector3(0,-0.09,0),color,color,color.darkened(0.08))


func _conifer_tier(center: Vector3, radius: float, height: float, color: Color, variant: int) -> void:
	for index: int in range(12):
		var angle := float(index)*TAU/12
		var next_angle := float(index+1)*TAU/12
		var low := center+Vector3(cos(angle)*radius,-0.09-float((index+variant)%3)*0.055,sin(angle)*radius)
		var next := center+Vector3(cos(next_angle)*radius,-0.09-float((index+variant+1)%3)*0.055,sin(next_angle)*radius)
		var ridge := center+Vector3(cos(angle+TAU/24)*radius*0.47,height*0.43,sin(angle+TAU/24)*radius*0.47)
		var tip := center+Vector3(0.02,height,0)
		var tint := color.lightened(float((index+variant)%4)*0.013)
		_triangle(low,next,ridge,tint,tint,tint.lightened(0.015))
		_triangle(low,ridge,tip,tint,tint,tint.lightened(0.025))
		_triangle(ridge,next,tip,tint,tint,tint.lightened(0.025))


func _rock(center: Vector3, size: Vector3, color: Color, variant: int, angular: bool = false) -> void:
	var rings: Array = []
	for row: int in range(5):
		var latitude := -PI*0.5+float(row)*PI/4
		var ring: Array[Vector3] = []
		for index: int in range(9):
			var angle := float(index)*TAU/8
			var rough := 0.88+float(posmod(index*17+row*11+variant*7,13))*0.018
			var profile := [0.72,1.0,0.93,0.66,0.30]
			var heights := [-0.58,-0.25,0.26,0.62,0.79]
			var radial := float(profile[row]) if angular else cos(latitude)
			var height := float(heights[row]) if angular else sin(latitude)
			ring.append(center+Vector3(cos(angle)*radial*rough,height*rough,sin(angle)*radial*rough)*size)
		rings.append(ring)
	for row: int in range(4):
		for index: int in range(8):
			var shade := color.darkened((0.30-float(row)*0.065) if angular else 0.07).lightened(float(posmod(row*7+index*3+variant,9))*0.009)
			_quad(rings[row][index],rings[row][index+1],rings[row+1][index+1],rings[row+1][index],shade)
	if angular:
		for index: int in range(8): _triangle(center+Vector3(0,0.80*size.y,0),rings[4][index],rings[4][index+1],color,color,color)


func _cylinder(start: Vector3, end: Vector3, bottom_radius: float, top_radius: float, color: Color, segments: int) -> void:
	var axis := (end-start).normalized()
	var tangent := axis.cross(Vector3.FORWARD).normalized()
	if tangent.length_squared()<0.01: tangent = axis.cross(Vector3.RIGHT).normalized()
	var bitangent := tangent.cross(axis).normalized()
	for index: int in range(segments):
		var angle := float(index)*TAU/segments
		var next_angle := float(index+1)*TAU/segments
		var radial := tangent*cos(angle)+bitangent*sin(angle)
		var next := tangent*cos(next_angle)+bitangent*sin(next_angle)
		_quad(start+radial*bottom_radius,start+next*bottom_radius,end+next*top_radius,end+radial*top_radius,color.lightened(float(index%3)*0.018))
		_triangle(end,end+radial*top_radius,end+next*top_radius,color,color,color)


func _irregular_patch(center: Vector2, radius: float, height: float, color: Color, variant: int, y_scale: float) -> void:
	var count := 20
	for index: int in range(count):
		var angle := float(index)*TAU/count
		var next := float(index+1)*TAU/count
		var current_radius := radius*(0.91+float(posmod(variant+index*7,13))*0.012)
		var next_radius := radius*(0.91+float(posmod(variant+(index+1)*7,13))*0.012)
		var edge := center+Vector2(cos(angle),sin(angle)*y_scale)*current_radius
		var next_edge := center+Vector2(cos(next),sin(next)*y_scale)*next_radius
		var inner := center+(edge-center)*0.58
		var next_inner := center+(next_edge-center)*0.58
		_triangle(world_position(center,height),world_position(inner,height),world_position(next_inner,height),color.lightened(0.025),color,color)
		var transparent := Color(color,0)
		_quad_colors(world_position(inner,height),world_position(edge,height),world_position(next_edge,height),world_position(next_inner,height),color,transparent,transparent,color)


func _vertex_material() -> StandardMaterial3D:
	if _shared_vertex_material != null: return _shared_vertex_material
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	# Compatibility ignores vertex_color_is_srgb. Mesh/tint values have already
	# been explicitly linearized; relying on that flag bleaches dirt and stone.
	material.vertex_color_is_srgb = false
	material.roughness = 0.94
	material.metallic_specular = 0.16
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shared_vertex_material = material
	return material


func _add_mesh(node_name: String, mesh: ArrayMesh, material: Material) -> void:
	if mesh.get_surface_count() == 0: return
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_static_root.add_child(node)
	_diagnostics.static_mesh_nodes += 1
	for surface: int in range(mesh.get_surface_count()):
		_diagnostics.static_triangles += mesh.surface_get_array_len(surface)/3


func _reset_mesh() -> void:
	_vertices = PackedVector3Array()
	_colors = PackedColorArray()


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	_quad_colors(a,b,c,d,color,color,color,color)


func _quad_colors(a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	_triangle(a,b,c,ca,cb,cc)
	_triangle(a,c,d,ca,cc,cd)


func _triangle(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	_vertices.append(a)
	_vertices.append(b)
	_vertices.append(c)
	_colors.append(ca.srgb_to_linear())
	_colors.append(cb.srgb_to_linear())
	_colors.append(cc.srgb_to_linear())


func _finish_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if _vertices.is_empty(): return mesh
	var normals := PackedVector3Array()
	for index: int in range(0,_vertices.size(),3):
		var normal := (_vertices[index+2]-_vertices[index]).cross(_vertices[index+1]-_vertices[index]).normalized()
		for _copy: int in range(3): normals.append(normal)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh


func _key(identity: String) -> int:
	return (str(_seed)+":"+identity).sha256_text().substr(0,15).hex_to_int()
