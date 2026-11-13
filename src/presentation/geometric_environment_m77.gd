extends "res://src/presentation/frontier3d_environment.gd"
## Retained, chunk-instanced landscape. Terrain and road cells are observations,
## not new navigation geometry. Original meshes, no extracted commercial assets.
const MEADOW_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform bool ground_overlay=false;
uniform vec4 home_a=vec4(0.0);
uniform vec4 home_b=vec4(0.0);
uniform vec4 home_c=vec4(0.0);
uniform vec4 home_d=vec4(0.0);
varying vec2 p;
varying vec4 tint;
float h(vec2 q){return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 q){vec2 a=floor(q);vec2 b=fract(q);b=b*b*(3.0-2.0*b);return mix(mix(h(a),h(a+vec2(1,0)),b.x),mix(h(a+vec2(0,1)),h(a+vec2(1)),b.x),b.y);}
vec3 home(vec3 c,vec4 z){
 float k=(1.0-smoothstep(z.z*0.35,z.z,length(p-z.xy)))*step(0.01,z.z);
 vec3 b=vec3(0.16,0.24,0.09);
 if(z.w>0.5&&z.w<1.5)b=vec3(0.14,0.13,0.12);
 else if(z.w>1.5&&z.w<2.5)b=vec3(0.23,0.21,0.15);
 else if(z.w>2.5&&z.w<3.5)b=vec3(0.09,0.19,0.10);
 else if(z.w>3.5&&z.w<4.5)b=vec3(0.52,0.57,0.56);
 else if(z.w>4.5)b=vec3(0.12,0.17,0.18);
 return mix(c,b,k*0.75);
}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;tint=COLOR;}
void fragment(){
 float broad=n(p*0.12);float small=n(p*0.8);float grain=n(p*9.0);
 vec3 c=mix(vec3(0.12,0.205,0.07),vec3(0.25,0.30,0.12),small*0.7);
 c=mix(c,vec3(0.25,0.22,0.13),smoothstep(0.55,0.82,broad)*0.52);
 c=home(home(home(home(c,home_a),home_b),home_c),home_d);
 c*=0.93+grain*0.12;
 if(ground_overlay)c=mix(c,tint.rgb*(0.94+grain*0.1),tint.a);
 ALBEDO=c;ROUGHNESS=0.97;SPECULAR=0.0;
}
"""
var _resource_reserve_m77 := 0
var _decor_skipped_m77 := 0


func configure(snapshot: Dictionary, landscape_plan: Dictionary = {}) -> void:
	_resource_reserve_m77 = 0
	for source: Dictionary in snapshot.get("resource_sources", snapshot.get("match_config", {}).get("sources", [])):
		_resource_reserve_m77 += 60 if str(source.get("resource", source.get("kind", ""))) == "FOOD" else 7
	super.configure(snapshot, landscape_plan)


func _build_ground() -> void:
	_decor_skipped_m77 = 0
	super._build_ground()


func _ground_material(overlay: bool) -> ShaderMaterial:
	if _ground_shader == null:
		_ground_shader = Shader.new()
		_ground_shader.code = MEADOW_SHADER
	return super._ground_material(overlay)


func _build_roads() -> void:
	var cells: Array = _plan.get("road_cells", [])
	if cells.is_empty():
		super._build_roads()
		return
	_reset_mesh()
	var origin := Vector2(_plan.get("road_grid_origin", _bounds.position))
	var occupied: Dictionary = {}
	for cell: Vector2i in cells: occupied[cell] = true
	for cell: Vector2i in cells:
		var key := _key("road:" + str(cell))
		var point := origin + Vector2(cell * 32)
		var edge := not occupied.has(cell + Vector2i.LEFT) or not occupied.has(cell + Vector2i.RIGHT) or not occupied.has(cell + Vector2i.UP) or not occupied.has(cell + Vector2i.DOWN)
		var color := Color("8c8062").darkened(float(key % 5) * 0.018 + (0.08 if edge else 0.0))
		_quad(world_position(point, 0.027), world_position(point + Vector2(32, 0), 0.027), world_position(point + Vector2(32, 32), 0.027), world_position(point + Vector2(0, 32), 0.027), color)
		# Individual inset pavers, still merged into one static mesh.
		if key % 3 != 0:
			var inset := point + Vector2(3, 3)
			_quad(world_position(inset, 0.032), world_position(inset + Vector2(24, 0), 0.032), world_position(inset + Vector2(24, 24), 0.032), world_position(inset + Vector2(0, 24), 0.032), Color("a2987d").darkened(float(key % 6) * 0.025))
	_diagnostics.road_count = _plan.get("roads", []).size()
	_diagnostics["road_cells"] = cells.size()
	_add_mesh("WholeCellStoneRoad", _finish_mesh(), _ground_material(true))


func _build_obstacles(terrain: Array) -> void:
	super._build_obstacles(terrain)
	_reset_mesh()
	for body: Dictionary in terrain:
		var kind := str(body.get("kind", ""))
		if kind not in ["GLACIER", "LAVA"]: continue
		var point := Vector2(body.get("position", Vector2.ZERO))
		var radius := float(body.get("radius", 40)) * WORLD_SCALE
		var rng := RandomNumberGenerator.new()
		rng.seed = _key(str(body.get("id", "")))
		_diagnostics.terrain_bodies += 1
		for index: int in range(6):
			var direction := Vector3(cos(index * 2.399), 0.0, sin(index * 2.399))
			var offset := direction * radius * rng.randf_range(0.05, 0.45)
			var size := radius * rng.randf_range(0.36, 0.65)
			if kind == "GLACIER":
				_instance("ice_m77", world_position(point) + offset, Vector3(size, size * rng.randf_range(1.1, 1.8), size), rng.randf() * TAU, Color.WHITE)
			else:
				_instance("basalt_m77", world_position(point) + offset, Vector3(size, size * rng.randf_range(0.6, 1.2), size), rng.randf() * TAU, Color.WHITE)
				var a := world_position(point) + offset
				_quad(a + Vector3(-size * 0.35, 0.045, -0.1), a + Vector3(size * 0.5, 0.045, 0.0), a + Vector3(size * 0.4, 0.045, 0.18), a + Vector3(-size * 0.35, 0.045, 0.06), Color("c26631"))
	_add_mesh("LavaSeamsNotDamage", _finish_mesh(), _vertex_material())


func _build_decorations() -> void:
	super._build_decorations()
	# The shared planner already found safe, non-blocking homeland spots. Give
	# those semantic records proper culture props instead of generic grass.
	var families := {"HUMAN":["supplies", "flower", "bush"], "UNDEAD":["bones", "deadwood", "ruin"], "MACHINE":["supplies", "ruin", "rock_1"], "FOREST":["fern", "bush", "mushroom"], "HIGHLAND":["rock_2", "supplies", "ruin"], "UNDERGROUND":["mushroom", "crystal", "bones"]}
	for decoration: Dictionary in _plan.get("decorations", []):
		if str(decoration.get("kind", "")) != "HOMELAND": continue
		var faction := str(decoration.get("faction_id", "HUMAN"))
		var variants: Array = families.get(faction, families.HUMAN)
		var point := Vector2(decoration.get("position", Vector2.ZERO))
		var key := _key("homeland:" + str(point))
		_instance(str(variants[key % variants.size()]), world_position(point), Vector3.ONE * 1.3, float(key % 37) * 0.17, Color.WHITE)


func _instance(kind: String, position: Vector3, size: Vector3, angle: float, tint: Color, parent: Node3D = null) -> void:
	# Every family, not just sources, gets bounded spatial chunks. Each batch
	# can now be frustum-culled independently by the 3D renderer.
	if parent == null and _allocated_instances >= maxi(MAX_STATIC_INSTANCES - _resource_reserve_m77, 0):
		_decor_skipped_m77 += 1
		return
	if parent != null: _resource_reserve_m77 = maxi(_resource_reserve_m77 - 1, 0)
	var chunk := Vector2i(floori(position.x / 20.0), floori(position.z / 20.0))
	var partitioned_kind := kind + "#" + str(chunk.x) + "," + str(chunk.y)
	super._instance(partitioned_kind, position, size, angle, tint, parent)


func _prop_mesh(kind: String) -> ArrayMesh:
	var family := kind.get_slice("#", 0)
	if family not in ["ice_m77", "basalt_m77", "ore", "essence_m77"]: return super._prop_mesh(family)
	if _shared_meshes.has(family): return _shared_meshes[family]
	var previous_vertices := _vertices
	var previous_colors := _colors
	_reset_mesh()
	match family:
		"ice_m77":
			_crystal(Vector3.ZERO, 1.7, 0.8, Color("86b8c3"), 3)
			_crystal(Vector3(0.40, 0, 0.18), 0.95, 0.42, Color("c4dce0"), 6)
		"basalt_m77":
			_rock(Vector3(0, 0.65, 0), Vector3(1, 0.9, 0.8), Color("393b3a"), 9, true)
			_crystal(Vector3(0.20, 0.25, 0.35), 0.65, 0.18, Color("b85a2a"), 6)
		"ore":
			_rock(Vector3(0, 0.55, 0), Vector3(1, 0.75, 0.86), Color("737e77"), 16, true)
			for index: int in range(5):
				var angle := index * 2.399
				_crystal(Vector3(cos(angle) * 0.48, 0.45 + float(index % 2) * 0.15, sin(angle) * 0.48), 0.42, 0.20, Color("c4a45d"), index)
		"essence_m77":
			_rock(Vector3(0, 0.12, 0), Vector3(1, 0.22, 0.8), Color("555467"), 13, true)
			for index: int in range(5):
				var angle := index * 2.399
				_crystal(Vector3(cos(angle) * 0.45, 0.12, sin(angle) * 0.4), 0.8 + float(index % 3) * 0.4, 0.25, Color("9a9bc6").lightened(float(index % 2) * 0.13), index)
	var mesh := _finish_mesh()
	if mesh.get_surface_count() > 0: mesh.surface_set_material(0, _vertex_material())
	_shared_meshes[family] = mesh
	_vertices = previous_vertices
	_colors = previous_colors
	return mesh


func _build_sources(snapshot: Dictionary) -> void:
	var config: Dictionary = snapshot.get("match_config", {})
	_reset_mesh()
	for source: Dictionary in snapshot.get("resource_sources", config.get("sources", [])):
		var identity := str(source.get("id", ""))
		var point := Vector2(source.get("position", Vector2.ZERO))
		var kind := str(source.get("resource", source.get("kind", "MATERIAL")))
		var marker := Node3D.new()
		marker.name = "FiniteStock_" + identity.replace(":", "_")
		marker.set_meta("source_id", identity)
		_static_root.add_child(marker)
		_source_visuals[identity] = marker
		_diagnostics.source_count += 1
		if kind == "FOOD":
			var center := world_position(point)
			_quad(center + Vector3(-1.9, 0.036, -1.8), center + Vector3(1.9, 0.036, -1.8), center + Vector3(1.9, 0.036, 1.8), center + Vector3(-1.9, 0.036, 1.8), Color("665331"))
			for row: int in range(6):
				for column: int in range(10):
					var p := center + Vector3(-1.65 + column * 0.36, 0.045, -1.5 + row * 0.58)
					_instance("wheat", p, Vector3.ONE * (1.05 + float((row + column) % 3) * 0.1), column * 0.23, Color.WHITE, marker)
		else:
			_irregular_patch(point, 55, 0.036, Color("746f61"), _key(identity), 0.88)
			for index: int in range(7):
				var angle := index * 2.399
				var offset := Vector3(cos(angle), 0.0, sin(angle)) * (0.4 + float(index % 3) * 0.38)
				var size := 0.72 + float(index % 3) * 0.22
				_instance("essence_m77" if kind == "ESSENCE" else "ore", world_position(point) + offset, Vector3.ONE * size, angle, Color.WHITE, marker)
	_add_mesh("ResourceBeds", _finish_mesh(), _ground_material(true))


func get_diagnostics() -> Dictionary:
	var result := super.get_diagnostics()
	result["version"] = "geometric-m77-v1"
	result["chunk_metres"] = 20
	result["licensed_textures_required"] = false
	result["decor_skipped_for_resource_reserve"] = _decor_skipped_m77
	return result


func _flush_batches() -> void:
	super._flush_batches()
	for child: Node in _static_root.get_children():
		if child is MultiMeshInstance3D and (str(child.name).begins_with("Instances_grass#") or str(child.name).begins_with("Instances_wheat#")):
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
