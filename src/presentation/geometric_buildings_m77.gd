extends RefCounted
## M77 optional geometric architecture. Original vertex-colour geometry only.
## Presentation metres: 24 battlefield units = 1 m; Y is up, +Z is the entrance.
## This module never reads or modifies settlement, prices, collision or ownership.

const FACTIONS := ["HUMAN", "UNDEAD", "MACHINE", "FOREST", "HIGHLAND", "UNDERGROUND"]
const KINDS := ["BASE", "BARRACKS", "RANGE", "WORKSHOP", "FOUNDRY", "ALTAR", "DRAGON_ROOST", "TOWER", "MINE", "SHOP", "VILLAGE"]
const CACHE_LIMIT := 192
static var _meshes: Dictionary = {}
static var _cache_order: Array[String] = []
static var _stone_material: StandardMaterial3D
static var _light_material: StandardMaterial3D


class Geometry:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	var light_vertices := PackedVector3Array()
	var light_normals := PackedVector3Array()
	var light_colours := PackedColorArray()

	func triangle(a: Vector3, b: Vector3, c: Vector3, colour: Color, lit: bool = false) -> void:
		var normal := (b - a).cross(c - a).normalized()
		if normal.length_squared() < 0.5:
			return
		# Hex palettes are sRGB; Compatibility expects these mesh colours linear.
		var linear_colour := colour.srgb_to_linear()
		if lit:
			light_vertices.append_array(PackedVector3Array([a, c, b]))
			light_normals.append_array(PackedVector3Array([normal, normal, normal]))
			light_colours.append_array(PackedColorArray([linear_colour, linear_colour, linear_colour]))
		else:
			vertices.append_array(PackedVector3Array([a, c, b]))
			normals.append_array(PackedVector3Array([normal, normal, normal]))
			colours.append_array(PackedColorArray([linear_colour, linear_colour, linear_colour]))

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, colour: Color, lit: bool = false) -> void:
		triangle(a, b, c, colour, lit)
		triangle(a, c, d, colour, lit)

	func box(center: Vector3, size: Vector3, colour: Color, lit: bool = false) -> void:
		var r := size * 0.5
		var p: Array[Vector3] = []
		for y: float in [-r.y, r.y]:
			for z: float in [-r.z, r.z]:
				for x: float in [-r.x, r.x]:
					p.append(center + Vector3(x, y, z))
		quad(p[4], p[6], p[7], p[5], colour.lightened(0.10), lit)
		quad(p[0], p[1], p[3], p[2], colour.darkened(0.17), lit)
		quad(p[0], p[4], p[5], p[1], colour.darkened(0.13), lit)
		quad(p[2], p[3], p[7], p[6], colour, lit)
		quad(p[0], p[2], p[6], p[4], colour.darkened(0.08), lit)
		quad(p[1], p[5], p[7], p[3], colour.lightened(0.04), lit)

	func column(center: Vector3, radius: float, height: float, colour: Color, sides: int = 8, top_radius: float = -1.0, angle: float = 0.0) -> void:
		var top := radius if top_radius < 0.0 else top_radius
		var bottom_center := center - Vector3.UP * height * 0.5
		var top_center := center + Vector3.UP * height * 0.5
		for i: int in range(sides):
			var a := angle + TAU * float(i) / float(sides)
			var b := angle + TAU * float(i + 1) / float(sides)
			var radial_a := Vector3(cos(a), 0.0, sin(a))
			var radial_b := Vector3(cos(b), 0.0, sin(b))
			var p0 := bottom_center + radial_a * radius
			var p1 := top_center + radial_a * top
			var p2 := top_center + radial_b * top
			var p3 := bottom_center + radial_b * radius
			quad(p0, p1, p2, p3, colour.lightened(float(i % 3) * 0.035))
			triangle(bottom_center, p0, p3, colour.darkened(0.12))
			triangle(top_center, p2, p1, colour.lightened(0.08))

	func beam(a: Vector3, b: Vector3, width: float, colour: Color) -> void:
		var direction := (b - a).normalized()
		var side := direction.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.1:
			side = Vector3.RIGHT
		var up := side.cross(direction).normalized()
		var r := width * 0.5
		var p: Array[Vector3] = [a - side * r - up * r, a + side * r - up * r, a + side * r + up * r, a - side * r + up * r,
			b - side * r - up * r, b + side * r - up * r, b + side * r + up * r, b - side * r + up * r]
		quad(p[0], p[3], p[2], p[1], colour)
		quad(p[4], p[5], p[6], p[7], colour)
		quad(p[0], p[1], p[5], p[4], colour.darkened(0.12))
		quad(p[1], p[2], p[6], p[5], colour)
		quad(p[2], p[3], p[7], p[6], colour.lightened(0.1))
		quad(p[3], p[0], p[4], p[7], colour.darkened(0.07))

	func crystal(center: Vector3, radius: float, height: float, colour: Color) -> void:
		var apex := center + Vector3.UP * height
		var lower := center - Vector3.UP * height * 0.15
		for i: int in range(5):
			var a := TAU * float(i) / 5.0
			var b := TAU * float(i + 1) / 5.0
			var p := center + Vector3(cos(a) * radius, height * 0.2, sin(a) * radius)
			var q := center + Vector3(cos(b) * radius, height * 0.2, sin(b) * radius)
			triangle(p, apex, q, colour.lightened(float(i % 2) * 0.18), true)
			triangle(q, lower, p, colour.darkened(0.2), true)

	func mesh() -> ArrayMesh:
		var result := ArrayMesh.new()
		if not vertices.is_empty():
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_COLOR] = colours
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		if not light_vertices.is_empty():
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = light_vertices
			arrays[Mesh.ARRAY_NORMAL] = light_normals
			arrays[Mesh.ARRAY_COLOR] = light_colours
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return result

	func bounds() -> AABB:
		var result := AABB()
		var first := true
		for points: PackedVector3Array in [vertices, light_vertices]:
			for point: Vector3 in points:
				if first:
					result = AABB(point, Vector3.ZERO)
					first = false
				else:
					result = result.expand(point)
		return result


static func build(entity: Dictionary, material_team: Color) -> Node3D:
	var spec := _spec(entity)
	var mesh := _mesh_for(spec, material_team)
	var root := Node3D.new()
	root.name = "Geometric_%s_%s" % [spec.faction, spec.kind]
	root.set_meta("visual_bounds", mesh.get_aabb())
	root.set_meta("visual_identity", "%s:%s" % [spec.faction, spec.kind])
	root.set_meta("geometry_style", "m77-original-faceted-architecture")
	root.set_meta("logic_units_per_metre", 24.0)
	root.set_meta("geometry_surfaces", mesh.get_surface_count())
	var instance := MeshInstance3D.new()
	instance.name = "MergedArchitecture"
	instance.mesh = mesh
	root.add_child(instance)
	return root


static func visual_bounds(entity: Dictionary) -> AABB:
	return _mesh_for(_spec(entity), Color.WHITE).get_aabb()


static func _spec(entity: Dictionary) -> Dictionary:
	var faction := str(entity.get("faction_id", entity.get("faction", "HUMAN"))).to_upper()
	if not faction in FACTIONS:
		faction = "HUMAN"
	var kind := str(entity.get("building_type", entity.get("kind", entity.get("type", "BASE")))).to_upper()
	if kind in ["SITE_TOWER", "DEFENSE_TOWER"]:
		kind = "TOWER"
	if kind in ["ESSENCE_MINE", "GOLD_MINE", "RESOURCE_MINE"]:
		kind = "MINE"
	if not kind in KINDS:
		kind = "BARRACKS"
	return {"faction": faction, "kind": kind, "level": clampi(int(entity.get("base_tier", entity.get("base_level", entity.get("level", 1)))), 1, 3),
		"complete": bool(entity.get("complete", true)), "ruin": int(entity.get("hp", 1)) <= 0}


static func _palette(faction: String) -> Dictionary:
	# Material and structural differences follow each faction, not player colour.
	match faction:
		"UNDEAD":
			return {"wall": Color("59616b"), "plinth": Color("343d48"), "wood": Color("36383e"), "roof": Color("293942"), "trim": Color("c6c4ae"), "light": Color("90dbc7")}
		"MACHINE":
			return {"wall": Color("667479"), "plinth": Color("343d43"), "wood": Color("453e36"), "roof": Color("4a555d"), "trim": Color("b98a55"), "light": Color("e2bc62")}
		"FOREST":
			return {"wall": Color("8c9471"), "plinth": Color("535f4c"), "wood": Color("695039"), "roof": Color("466652"), "trim": Color("bbb88b"), "light": Color("d7da8a")}
		"HIGHLAND":
			return {"wall": Color("8b7d72"), "plinth": Color("4b4848"), "wood": Color("51413b"), "roof": Color("665555"), "trim": Color("c09661"), "light": Color("efad60")}
		"UNDERGROUND":
			return {"wall": Color("a49c83"), "plinth": Color("615d55"), "wood": Color("5e594a"), "roof": Color("736d75"), "trim": Color("bca782"), "light": Color("b4a1db")}
		_:
			return {"wall": Color("c1bba6"), "plinth": Color("777a73"), "wood": Color("51483d"), "roof": Color("5a7480"), "trim": Color("c2a16a"), "light": Color("efce8c")}


static func _mesh_for(spec: Dictionary, team: Color) -> ArrayMesh:
	var key := "%s:%s:%s:%s:%s:%s" % [spec.faction, spec.kind, spec.level, spec.complete, spec.ruin, team.to_html(false)]
	if _meshes.has(key):
		return _meshes[key]
	var g := Geometry.new()
	var p := _palette(spec.faction)
	if spec.ruin:
		_rubble(g, p, str(spec.kind))
	else:
		match str(spec.kind):
			"BASE": _base(g, p, spec, team)
			"BARRACKS": _barracks(g, p, spec, team)
			"RANGE": _range(g, p, spec, team)
			"WORKSHOP": _workshop(g, p, spec, team)
			"FOUNDRY": _foundry(g, p, spec, team)
			"ALTAR": _altar(g, p, spec, team)
			"DRAGON_ROOST": _roost(g, p, spec, team)
			"TOWER": _tower(g, p, spec, team)
			"MINE": _mine(g, p, spec, team)
			"SHOP": _shop(g, p, spec, team)
			"VILLAGE": _village(g, p, spec, team)
		_architectural_signature(g, p, spec)
		if not spec.complete:
			_scaffold(g, p, g.bounds())
	var result := g.mesh()
	_materials()
	result.surface_set_material(0, _stone_material)
	if result.get_surface_count() > 1:
		result.surface_set_material(1, _light_material)
	while _cache_order.size() >= CACHE_LIMIT:
		_meshes.erase(_cache_order.pop_front())
	_cache_order.append(key)
	_meshes[key] = result
	return result


static func _materials() -> void:
	if _stone_material == null:
		_stone_material = StandardMaterial3D.new()
		_stone_material.vertex_color_use_as_albedo = true
		_stone_material.vertex_color_is_srgb = false
		_stone_material.roughness = 0.9
		_stone_material.cull_mode = BaseMaterial3D.CULL_BACK
	if _light_material == null:
		_light_material = StandardMaterial3D.new()
		_light_material.vertex_color_use_as_albedo = true
		_light_material.vertex_color_is_srgb = false
		_light_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_light_material.cull_mode = BaseMaterial3D.CULL_BACK


static func _foundation(g: Geometry, p: Dictionary, width: float, depth: float) -> void:
	g.box(Vector3(0, 0.13, 0), Vector3(width + 0.36, 0.26, depth + 0.36), p.plinth)
	g.box(Vector3(0, 0.29, 0), Vector3(width + 0.12, 0.12, depth + 0.12), p.wall.darkened(0.15))


static func _hall(g: Geometry, p: Dictionary, faction: String, center: Vector3, width: float, depth: float, height: float, team: Color) -> void:
	g.box(center + Vector3.UP * height * 0.5, Vector3(width, height, depth), p.wall)
	# Shallow masonry joints are merged geometry, not a separate object per
	# brick. They break the large blank facade without a noisy texture layer.
	for row: int in range(1, 5):
		var y := height * float(row) / 5.0
		g.box(center + Vector3(0, y, depth * 0.5 + 0.012), Vector3(width - 0.12, 0.022, 0.022), p.wall.darkened(0.15))
		for column: int in range(5):
			var x := -width * 0.5 + (float(column) + 0.5 + float(row % 2) * 0.5) * width / 5.0
			if absf(x) < width * 0.48:
				g.box(center + Vector3(x, y - height * 0.09, depth * 0.5 + 0.014), Vector3(0.016, height * 0.16, 0.024), p.wall.darkened(0.12))
	for x: float in [-0.5, 0.5]:
		g.box(center + Vector3(x * (width - 0.18), height * 0.5, depth * 0.5 + 0.025), Vector3(0.18, height + 0.1, 0.16), p.wood)
	g.box(center + Vector3(0, height * 0.44, depth * 0.5 + 0.035), Vector3(0.85, height * 0.8, 0.10), p.wood.darkened(0.35))
	g.box(center + Vector3(0, height * 0.42, depth * 0.5 + 0.095), Vector3(0.65, height * 0.73, 0.05), p.wood)
	g.box(center + Vector3(0, height * 0.4, depth * 0.5 + 0.13), Vector3(0.05, height * 0.72, 0.04), p.trim)
	for x: float in [-0.31, 0.31]:
		g.box(center + Vector3(x * width, height * 0.58, depth * 0.5 + 0.03), Vector3(0.29, 0.46, 0.07), p.wood.darkened(0.5))
		g.box(center + Vector3(x * width, height * 0.6, depth * 0.5 + 0.075), Vector3(0.15, 0.30, 0.035), p.light, true)
	_roof(g, p, faction, center + Vector3.UP * height, width + 0.45, depth + 0.45, 0.95, team)


static func _gable(g: Geometry, origin: Vector3, width: float, depth: float, height: float, roof: Color, trim: Color, team: Color) -> void:
	var a := origin + Vector3(-width * 0.5, 0, -depth * 0.5)
	var b := origin + Vector3(width * 0.5, 0, -depth * 0.5)
	var c := origin + Vector3(width * 0.5, 0, depth * 0.5)
	var d := origin + Vector3(-width * 0.5, 0, depth * 0.5)
	var e := origin + Vector3(0, height, -depth * 0.5)
	var f := origin + Vector3(0, height, depth * 0.5)
	g.quad(a, d, f, e, roof)
	g.quad(b, e, f, c, roof.lightened(0.07))
	# Broad roof courses preserve a slate/wood reading at common RTS zoom.
	for side: int in [-1, 1]:
		for row: int in range(1, 7):
			var fraction := float(row) / 7.0
			var next_fraction := fraction + 0.012
			var x0 := origin.x + side * width * 0.5 * fraction
			var x1 := origin.x + side * width * 0.5 * next_fraction
			var y0 := origin.y + height * (1.0 - fraction) + 0.012
			var y1 := origin.y + height * (1.0 - next_fraction) + 0.012
			var p0 := Vector3(x0, y0, origin.z - depth * 0.5)
			var p1 := Vector3(x1, y1, origin.z - depth * 0.5)
			var p2 := Vector3(x1, y1, origin.z + depth * 0.5)
			var p3 := Vector3(x0, y0, origin.z + depth * 0.5)
			if side < 0: g.quad(p0, p1, p2, p3, roof.darkened(0.15))
			else: g.quad(p0, p3, p2, p1, roof.darkened(0.10))
	g.triangle(d, c, f, trim.darkened(0.1))
	g.triangle(b, a, e, trim.darkened(0.14))
	g.beam(e, f, 0.13, trim)
	g.beam(d, f, 0.10, trim)
	g.beam(c, f, 0.10, trim)
	# Team identification is fitted to the slope, not an oversized flat patch.
	var inset := 0.30
	var z0 := origin.z + depth * 0.20
	var z1 := z0 + 0.22
	var x0 := origin.x + inset
	var x1 := origin.x + width * 0.5 - 0.15
	var y0 := origin.y + height * (1.0 - inset / (width * 0.5)) + 0.015
	var y1 := origin.y + height * (0.15 / (width * 0.5)) + 0.015
	g.quad(Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), team)


static func _roof(g: Geometry, p: Dictionary, faction: String, origin: Vector3, width: float, depth: float, rise: float, team: Color) -> void:
	match faction:
		"FOREST":
			g.column(origin + Vector3.UP * rise * 0.40, width * 0.59, rise * 1.02, p.roof, 7, width * 0.15)
			g.column(origin + Vector3(0.12, rise * 1.05, -0.08), width * 0.39, rise * 0.62, p.roof.lightened(0.09), 7, 0.0)
			g.beam(origin + Vector3(-width * 0.46, 0.13, depth * 0.32), origin + Vector3(0, rise * 1.2, 0), 0.10, p.wood)
			g.box(origin + Vector3(width * 0.29, rise * 0.26, width * 0.36), Vector3(width * 0.14, 0.15, 0.16), team)
		"UNDERGROUND":
			g.column(origin + Vector3.UP * rise * 0.3, width * 0.60, rise * 0.62, p.roof, 10, width * 0.31)
			g.column(origin + Vector3.UP * rise * 0.68, width * 0.31, rise * 0.17, p.trim, 8, width * 0.23)
			g.box(origin + Vector3(0, 0.10, width * 0.55), Vector3(width * 0.33, 0.16, 0.12), team)
		"MACHINE":
			_gable(g, origin, width, depth, rise * 0.50, p.roof, p.trim, team)
			for x: float in [-0.30, 0.30]:
				g.box(origin + Vector3(width * x, 0.15, -depth * 0.15), Vector3(0.15, 0.35, depth * 0.46), p.trim)
		"HIGHLAND":
			g.box(origin + Vector3.UP * 0.13, Vector3(width, 0.26, depth), p.roof)
			g.box(origin + Vector3.UP * 0.39, Vector3(width * 0.78, 0.26, depth * 0.77), p.roof.lightened(0.05))
			g.box(origin + Vector3.UP * 0.65, Vector3(width * 0.55, 0.26, depth * 0.55), p.roof.lightened(0.08))
			g.box(origin + Vector3(0, 0.12, depth * 0.5 + 0.015), Vector3(width * 0.38, 0.16, 0.06), team)
		"UNDEAD":
			_gable(g, origin, width, depth, rise * 1.40, p.roof, p.trim, team)
			for x: float in [-0.46, 0.46]:
				g.column(origin + Vector3(width * x, rise * 0.36, depth * 0.37), 0.12, rise * 1.7, p.trim, 5, 0.0)
		_:
			_gable(g, origin, width, depth, rise, p.roof, p.trim, team)


static func _crest(g: Geometry, center: Vector3, team: Color, frame: Color, size: float = 0.45) -> void:
	g.box(center, Vector3(size * 1.12, size * 1.35, 0.10), frame)
	g.box(center + Vector3(0, 0, 0.06), Vector3(size, size * 1.2, 0.035), team)
	g.beam(center + Vector3(-size * 0.25, -size * 0.30, 0.09), center + Vector3(size * 0.25, size * 0.3, 0.09), size * 0.10, frame)


static func _base(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 6.2, 4.8)
	_hall(g, p, spec.faction, Vector3(0, 0.35, 0.4), 5.25, 3.65, 2.35, team)
	var keep_height := 3.3 + float(spec.level - 1) * 0.22
	if spec.faction == "FOREST":
		g.column(Vector3(-0.3, keep_height * 0.5, -1.6), 0.87, keep_height, p.wood, 8, 0.55)
		_roof(g, p, spec.faction, Vector3(-0.3, keep_height, -1.6), 2.3, 2.3, 1.0, team)
	elif spec.faction == "UNDERGROUND":
		g.column(Vector3(0, 1.45, -0.9), 2.4, 2.25, p.wall, 10, 1.9)
		_roof(g, p, spec.faction, Vector3(0, 2.55, -0.9), 4.0, 3.5, 1.0, team)
		g.crystal(Vector3(0, 3.3, -1.05), 0.3, 1.0, p.light)
	else:
		g.box(Vector3(0, keep_height * 0.5 + 0.15, -1.2), Vector3(2.1, keep_height, 2.0), p.wall)
		_roof(g, p, spec.faction, Vector3(0, keep_height + 0.15, -1.2), 2.55, 2.5, 0.85, team)
		for x: float in [-2.5, 2.5]:
			g.box(Vector3(x, 1.0, 1.8), Vector3(0.55, 1.9, 0.75), p.plinth)
			g.box(Vector3(x, 2.0, 1.8), Vector3(0.7, 0.18, 0.9), p.trim)
	_crest(g, Vector3(0, 2.15, 2.30), team, p.trim, 0.52)
	for x: float in [-1.0, 1.0]:
		g.box(Vector3(x, 0.15, 2.68), Vector3(1.4, 0.3, 0.75), p.plinth)
		g.box(Vector3(x, 0.35, 2.56), Vector3(1.4, 0.2, 0.5), p.wall)
	if spec.faction == "MACHINE":
		_chimney(g, p, Vector3(2.2, 0.35, -1.5), 3.8, 0.5)
	elif spec.faction == "HIGHLAND":
		for x: float in [-2.85, 2.85]:
			_brazier(g, p, Vector3(x, 0.35, 1.7), 0.9)
	elif spec.faction == "UNDEAD":
		g.crystal(Vector3(0, 4.0, -1.2), 0.25, 0.7, p.light)


static func _barracks(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 4.7, 3.8)
	_hall(g, p, spec.faction, Vector3(0, 0.35, -0.25), 4.2, 3.0, 1.95, team)
	for x: float in [-1.7, 1.7]:
		g.box(Vector3(x, 0.65, 2.05), Vector3(0.16, 0.7, 0.16), p.wood)
		g.beam(Vector3(x - 0.3, 0.88, 2.05), Vector3(x + 0.3, 0.88, 2.05), 0.13, p.wood)
		for dx: float in [-0.17, 0.17]:
			g.beam(Vector3(x + dx, 0.48, 2.05), Vector3(x + dx, 1.45, 2.05), 0.06, p.trim)
	_crest(g, Vector3(0, 2.1, 1.39), team, p.trim)


static func _range(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 4.8, 4.6)
	_hall(g, p, spec.faction, Vector3(-0.7, 0.35, -0.9), 3.1, 2.5, 1.7, team)
	for x: float in [-1.55, -0.15, 1.25]:
		g.beam(Vector3(x, 0.35, 1.3), Vector3(x, 1.45, 1.5), 0.09, p.wood)
		g.box(Vector3(x, 1.25, 1.58), Vector3(0.66, 0.66, 0.10), p.wood)
		g.box(Vector3(x, 1.25, 1.65), Vector3(0.48, 0.48, 0.05), p.trim)
		g.box(Vector3(x, 1.25, 1.69), Vector3(0.18, 0.18, 0.035), team)
	for z: float in [-1.9, -0.6, 0.7, 2.0]:
		g.box(Vector3(2.2, 0.73, z), Vector3(0.12, 0.8, 0.12), p.wood)
	g.beam(Vector3(2.2, 0.7, -1.95), Vector3(2.2, 0.7, 2.05), 0.08, p.wood)


static func _workshop(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 5.2, 4.3)
	_hall(g, p, spec.faction, Vector3(-0.5, 0.35, -0.25), 3.8, 3.4, 2.05, team)
	_crane(g, p, Vector3(1.6, 0.35, 0.1), 2.75)
	g.box(Vector3(1.55, 0.70, 1.55), Vector3(1.25, 0.45, 0.75), p.wood)
	for x: float in [1.0, 2.1]:
		g.column(Vector3(x, 0.54, 1.7), 0.27, 0.30, p.trim, 8)
	_crest(g, Vector3(-0.5, 2.04, 1.48), team, p.trim, 0.42)


static func _foundry(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 4.8, 4.0)
	_hall(g, p, spec.faction, Vector3(-0.35, 0.35, 0), 3.6, 3.1, 2.1, team)
	_chimney(g, p, Vector3(1.45, 0.35, -0.95), 3.4, 0.62)
	_chimney(g, p, Vector3(0.7, 0.35, -1.3), 2.75, 0.40)
	g.box(Vector3(1.35, 0.85, 1.1), Vector3(1.0, 1.1, 0.9), p.plinth)
	g.box(Vector3(1.35, 0.8, 1.57), Vector3(0.60, 0.50, 0.035), p.light, true)
	g.box(Vector3(1.3, 1.25, 1.2), Vector3(1.2, 0.17, 1.1), p.trim)
	_crest(g, Vector3(-0.35, 2.05, 1.6), team, p.trim, 0.40)


static func _altar(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 4.3, 4.0)
	for i: int in range(3):
		g.column(Vector3(0, 0.4 + float(i) * 0.16, 0), 1.8 - float(i) * 0.22, 0.18, p.wall, 8)
	g.column(Vector3(0, 1.0, -0.2), 0.85, 0.5, p.plinth, 8, 0.7)
	for x: float in [-1.35, 1.35]:
		g.column(Vector3(x, 1.55, -0.7), 0.21, 2.3, p.wall, 6, 0.17)
		g.column(Vector3(x, 2.75, -0.7), 0.36, 0.18, p.trim, 6)
	if spec.faction in ["FOREST", "UNDERGROUND"]:
		g.beam(Vector3(-1.35, 2.65, -0.7), Vector3(0, 3.25, -0.7), 0.23, p.wood)
		g.beam(Vector3(0, 3.25, -0.7), Vector3(1.35, 2.65, -0.7), 0.23, p.wood)
	elif spec.faction == "MACHINE":
		g.box(Vector3(0, 2.78, -0.7), Vector3(3.0, 0.28, 0.5), p.trim)
	else:
		_gable(g, Vector3(0, 2.7, -0.7), 3.2, 0.65, 0.65, p.roof, p.trim, team)
	g.crystal(Vector3(0, 1.35, -0.2), 0.35, 1.0, p.light)
	_crest(g, Vector3(0, 0.95, 0.8), team, p.trim, 0.46)
	for x: float in [-1.4, 1.4]:
		_brazier(g, p, Vector3(x, 0.38, 1.2), 0.6)


static func _roost(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 4.8, 4.8)
	g.column(Vector3(0, 1.45, -0.3), 1.75, 2.3, p.plinth, 7, 1.4)
	g.column(Vector3(0, 2.65, -0.3), 2.05, 0.35, p.wood, 9, 1.85)
	g.column(Vector3(0, 2.89, -0.3), 1.8, 0.14, p.roof, 9, 1.55)
	for i: int in range(9):
		var angle := TAU * float(i) / 9.0
		var pos := Vector3(cos(angle) * 1.8, 2.95, sin(angle) * 1.8 - 0.3)
		g.beam(pos - Vector3(0.25, 0.03, 0), pos + Vector3(0.25, 0.10, 0), 0.14, p.wood)
	for x: float in [-1.25, 1.25]:
		g.beam(Vector3(x, 2.5, -1.1), Vector3(x, 4.0, -1.1), 0.17, p.trim)
	g.beam(Vector3(-1.45, 4.0, -1.1), Vector3(1.45, 4.0, -1.1), 0.19, p.wood)
	_crest(g, Vector3(0, 1.75, 1.3), team, p.trim, 0.6)
	if spec.faction in ["MACHINE", "UNDERGROUND", "UNDEAD"]:
		g.crystal(Vector3(0, 2.95, -0.3), 0.3, 0.65, p.light)


static func _tower(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 2.2, 2.2)
	var height := 3.25 + 0.15 * float(spec.level - 1)
	if spec.faction in ["FOREST", "UNDERGROUND", "UNDEAD"]:
		g.column(Vector3(0, height * 0.5 + 0.35, 0), 0.78, height, p.wood if spec.faction == "FOREST" else p.wall, 7, 0.58)
	else:
		g.box(Vector3(0, height * 0.5 + 0.35, 0), Vector3(1.35, height, 1.35), p.wall)
	for y: float in [1.0, 2.4]:
		g.box(Vector3(0, y, 0.71), Vector3(0.13, 0.48, 0.06), p.wood.darkened(0.5))
	g.box(Vector3(0, height + 0.3, 0), Vector3(2.1, 0.25, 2.1), p.trim)
	for x: float in [-0.85, 0.85]:
		for z: float in [-0.85, 0.85]:
			g.box(Vector3(x, height + 0.65, z), Vector3(0.20, 0.75, 0.20), p.wood)
	_roof(g, p, spec.faction, Vector3(0, height + 1.0, 0), 2.3, 2.3, 0.75, team)
	_crest(g, Vector3(0, 2.05, 0.75), team, p.trim, 0.48)
	g.beam(Vector3(-0.48, height + 0.72, 1.03), Vector3(0.48, height + 0.72, 1.03), 0.10, p.wood)
	g.beam(Vector3(0, height + 0.72, 0.35), Vector3(0, height + 0.72, 1.35), 0.12, p.trim)


static func _mine(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 4.7, 4.1)
	g.column(Vector3(-0.55, 0.9, -0.7), 1.75, 1.45, p.plinth, 7, 1.15)
	g.box(Vector3(-0.55, 0.9, 0.72), Vector3(1.35, 1.35, 0.10), p.wood.darkened(0.6))
	for x: float in [-1.35, 0.25]:
		g.box(Vector3(x, 0.95, 0.82), Vector3(0.19, 1.6, 0.22), p.wood)
	g.box(Vector3(-0.55, 1.82, 0.82), Vector3(1.95, 0.25, 0.27), p.wood)
	for x: float in [-0.9, -0.2]:
		g.beam(Vector3(x, 0.4, 0.8), Vector3(x, 0.4, 2.05), 0.075, p.trim)
	_crane(g, p, Vector3(1.45, 0.35, -0.6), 2.1)
	g.box(Vector3(1.40, 0.6, 1.15), Vector3(0.85, 0.6, 0.85), p.wood)
	g.crystal(Vector3(1.40, 0.96, 1.15), 0.18, 0.45, p.light)
	_crest(g, Vector3(-0.55, 1.82, 1.0), team, p.trim, 0.3)
	if spec.faction == "FOREST":
		g.column(Vector3(-1.25, 1.7, -0.7), 0.7, 1.0, p.roof, 7, 0.05)
	elif spec.faction == "UNDERGROUND":
		g.crystal(Vector3(-1.15, 1.6, -0.8), 0.23, 0.75, p.light)


static func _shop(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	_foundation(g, p, 4.7, 3.7)
	_hall(g, p, spec.faction, Vector3(0, 0.35, -0.45), 3.8, 2.5, 1.65, team)
	for x: float in [-1.85, 1.85]:
		g.box(Vector3(x, 1.0, 1.45), Vector3(0.10, 1.4, 0.10), p.wood)
	for i: int in range(6):
		var x0 := -1.95 + float(i) * 0.65
		var colour: Color = team if i % 2 == 0 else p.trim
		g.quad(Vector3(x0, 1.93, 0.7), Vector3(x0 + 0.65, 1.93, 0.7), Vector3(x0 + 0.65, 1.50, 1.7), Vector3(x0, 1.50, 1.7), colour)
	g.box(Vector3(0, 0.8, 1.3), Vector3(3.4, 0.7, 0.7), p.wood)
	g.box(Vector3(0, 1.19, 1.3), Vector3(3.6, 0.10, 0.85), p.trim)
	for x: float in [-1.05, 0.0, 1.05]:
		g.column(Vector3(x, 1.42, 1.3), 0.14, 0.34, p.light, 6, 0.10)
		g.box(Vector3(x + 0.25, 1.32, 1.3), Vector3(0.24, 0.18, 0.32), p.roof)


static func _village(g: Geometry, p: Dictionary, spec: Dictionary, team: Color) -> void:
	# Capturable civilian shelter, not a production building or enlarged barracks.
	_foundation(g, p, 2.65, 2.25)
	_hall(g, p, spec.faction, Vector3(0, 0.35, -0.20), 2.35, 1.95, 1.4, team)
	g.box(Vector3(-0.78, 0.42, 1.08), Vector3(0.75, 0.22, 0.45), p.wood)
	g.box(Vector3(-0.78, 0.61, 1.08), Vector3(0.58, 0.16, 0.32), p.trim)
	# Small larder containers reinforce the non-military silhouette.
	for x: float in [0.75, 1.08]:
		g.column(Vector3(x, 0.57, 0.93), 0.14, 0.42, p.wood, 7, 0.12)
		g.column(Vector3(x, 0.59, 0.93), 0.15, 0.06, p.trim, 7)
	_crest(g, Vector3(0, 1.54, 0.84), team, p.trim, 0.27)


static func _chimney(g: Geometry, p: Dictionary, foot: Vector3, height: float, width: float) -> void:
	g.box(foot + Vector3.UP * height * 0.5, Vector3(width, height, width), p.plinth)
	g.box(foot + Vector3.UP * (height - 0.18), Vector3(width * 1.2, 0.22, width * 1.2), p.trim)
	g.box(foot + Vector3.UP * (height + 0.005), Vector3(width * 0.72, 0.02, width * 0.72), p.wood.darkened(0.65))


static func _crane(g: Geometry, p: Dictionary, foot: Vector3, height: float) -> void:
	g.beam(foot, foot + Vector3.UP * height, 0.18, p.wood)
	g.beam(foot + Vector3(0, height, 0), foot + Vector3(0, height, 1.1), 0.18, p.trim)
	g.beam(foot + Vector3(0, height * 0.55, 0), foot + Vector3(0, height, 0.9), 0.10, p.wood)
	g.beam(foot + Vector3(0, height, 1.05), foot + Vector3(0, height * 0.42, 1.05), 0.035, p.wood.darkened(0.3))
	g.box(foot + Vector3(0, height * 0.40, 1.05), Vector3(0.34, 0.16, 0.32), p.trim)


static func _brazier(g: Geometry, p: Dictionary, foot: Vector3, height: float) -> void:
	g.column(foot + Vector3.UP * height * 0.5, 0.16, height, p.plinth, 6, 0.13)
	g.column(foot + Vector3.UP * height, 0.26, 0.17, p.trim, 6, 0.35)
	g.crystal(foot + Vector3.UP * (height + 0.12), 0.16, 0.42, p.light)


static func _scaffold(g: Geometry, p: Dictionary, bounds: AABB) -> void:
	var height := minf(bounds.size.y * 0.72, 3.2)
	var x := bounds.size.x * 0.5 + 0.12
	var z := bounds.size.z * 0.5 + 0.12
	for side: float in [-1.0, 1.0]:
		for depth: float in [-1.0, 1.0]:
			g.beam(Vector3(side * x, 0.05, depth * z), Vector3(side * x, height, depth * z), 0.09, p.wood)
		g.beam(Vector3(-x, height * 0.47, side * z), Vector3(x, height * 0.47, side * z), 0.08, p.wood)
		g.beam(Vector3(-x, height * 0.85, side * z), Vector3(x, height * 0.85, side * z), 0.08, p.wood)
		g.beam(Vector3(-x, 0.2, side * z), Vector3(x, height * 0.85, side * z), 0.06, p.wood)


static func _architectural_signature(g: Geometry, p: Dictionary, spec: Dictionary) -> void:
	# The same production function must not become one shared hut with six paints.
	# Small load-bearing forms also distinguish non-roofed mines, perches and altars.
	var bounds := g.bounds()
	var width := bounds.size.x
	var depth := bounds.size.z
	var rear := bounds.position.z + 0.2
	var height := minf(bounds.size.y * 0.55, 2.2)
	var offset := minf(width * 0.4, 2.35)
	match str(spec.faction):
		"HUMAN":
			for x: float in [-offset, offset]:
				g.box(Vector3(x, 0.36, rear), Vector3(0.55, 0.30, 0.65), p.plinth)
				g.beam(Vector3(x, 0.45, rear), Vector3(x * 0.94, height, rear + 0.22), 0.21, p.wall)
				g.box(Vector3(x * 0.94, height, rear + 0.22), Vector3(0.38, 0.15, 0.4), p.trim)
		"UNDEAD":
			for x: float in [-offset, offset]:
				g.beam(Vector3(x, 0.3, rear), Vector3(x * 0.82, height + 0.4, rear + 0.1), 0.15, p.trim)
				g.column(Vector3(x * 0.82, height + 0.6, rear + 0.1), 0.15, 0.65, p.trim, 5, 0.0)
		"MACHINE":
			g.box(Vector3(-offset, height * 0.5, rear + 0.25), Vector3(0.4, height, 0.7), p.plinth)
			for y: float in [0.5, 0.75, 1.0]:
				g.box(Vector3(-offset - 0.22, y, rear + 0.25), Vector3(0.045, 0.08, 0.52), p.trim)
			g.beam(Vector3(offset, 0.4, rear), Vector3(offset * 0.9, height, rear + 0.35), 0.19, p.trim)
		"FOREST":
			for x: float in [-offset, offset]:
				g.beam(Vector3(x * 1.08, 0.15, rear - 0.15), Vector3(x * 0.82, 0.65, rear + 0.18), 0.30, p.wood)
				g.beam(Vector3(x * 0.82, 0.65, rear + 0.18), Vector3(x * 0.77, height + 0.15, rear + 0.35), 0.20, p.wood)
				g.column(Vector3(x * 0.77, height + 0.2, rear + 0.35), 0.5, 0.4, p.roof, 6, 0.04)
		"HIGHLAND":
			for x: float in [-offset, offset]:
				g.column(Vector3(x, 0.7, rear + 0.3), 0.46, 1.0, p.plinth, 5, 0.28)
				g.column(Vector3(x * 0.97, 1.3, rear + 0.3), 0.32, 0.3, p.trim, 5, 0.28)
			g.box(Vector3(0, 0.39, rear + depth * 0.15), Vector3(width * 0.66, 0.16, 0.36), p.plinth)
		"UNDERGROUND":
			for x: float in [-offset, offset]:
				g.column(Vector3(x, 0.6, rear + 0.2), 0.47, 0.75, p.wall, 7, 0.3)
				g.crystal(Vector3(x, 0.95, rear + 0.2), 0.13, 0.50, p.light)
			g.beam(Vector3(-offset, 0.55, rear + 0.2), Vector3(0, 1.35, rear - 0.1), 0.20, p.trim)
			g.beam(Vector3(0, 1.35, rear - 0.1), Vector3(offset, 0.55, rear + 0.2), 0.20, p.trim)


static func _rubble(g: Geometry, p: Dictionary, kind: String) -> void:
	var width := 5.5 if kind == "BASE" else 3.8
	for i: int in range(7):
		var x := sin(float(i) * 2.33) * width * 0.34
		var z := cos(float(i) * 1.71) * width * 0.27
		g.column(Vector3(x, 0.15, z), 0.35 + float(i % 3) * 0.15, 0.25 + float(i % 2) * 0.23, p.plinth, 5, 0.15)
	g.beam(Vector3(-1.1, 0.15, -0.5), Vector3(1.15, 0.4, 0.4), 0.18, p.wood)
