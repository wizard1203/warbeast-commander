extends RefCounted
## Optional M77 geometric presentation. All dimensions are metres (24 rule
## units/metre); +Z is forward and the origin is a stable ground contact.
## Catalogs determine identity only. No transform, animation or mesh writes
## back to the fixed-tick match. Meshes/materials are shared across actors;
## procedural animation changes six small rigid parts, not mesh vertices.
const Catalog = preload("res://src/simulation/strategic_unit_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const LOGIC_UNITS_PER_METRE := 24.0
const MAX_SHARED_IDENTITIES := 384
static var _meshes: Dictionary = {}
static var _mesh_order: Array[String] = []
static var _material: StandardMaterial3D
static var _ring_materials: Dictionary = {}
static var _identities: Dictionary = {}
static var _rosters: Dictionary = {}


class Geometry:

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()

	func triangle(a: Vector3, b: Vector3, c: Vector3, outward: Vector3, color: Color) -> void:
		var normal := outward.normalized()
		# Godot front faces use clockwise winding; preserve outward normals.
		if (b - a).cross(c - a).dot(normal) > 0.0:
			var swap := b
			b = c
			c = swap
		vertices.append_array(PackedVector3Array([a, b, c]))
		normals.append_array(PackedVector3Array([normal, normal, normal]))
		var linear_color := color.srgb_to_linear()
		colors.append_array(PackedColorArray([linear_color, linear_color, linear_color]))

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3, color: Color) -> void:
		triangle(a, b, c, outward, color)
		triangle(a, c, d, outward, color)

	func box(center: Vector3, size: Vector3, color: Color, basis: Basis = Basis.IDENTITY) -> void:
		var h := size * 0.5
		var p: Array[Vector3] = []
		for corner: Vector3 in [Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(-h.x,h.y,-h.z),Vector3(-h.x,-h.y,h.z),Vector3(h.x,-h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z)]:
			p.append(center + basis * corner)
		quad(p[0],p[1],p[2],p[3],basis*Vector3.FORWARD,color.darkened(0.05))
		quad(p[5],p[4],p[7],p[6],basis*Vector3.BACK,color)
		quad(p[4],p[0],p[3],p[7],basis*Vector3.LEFT,color.darkened(0.12))
		quad(p[1],p[5],p[6],p[2],basis*Vector3.RIGHT,color.lightened(0.03))
		quad(p[3],p[2],p[6],p[7],basis*Vector3.UP,color.lightened(0.08))
		quad(p[4],p[5],p[1],p[0],basis*Vector3.DOWN,color.darkened(0.18))

	func cone(center: Vector3, bottom: float, top: float, height: float, color: Color, sides: int = 6, basis: Basis = Basis.IDENTITY) -> void:
		for i: int in range(sides):
			var a := float(i)*TAU/float(sides)
			var b := float(i+1)*TAU/float(sides)
			var p0 := center+basis*Vector3(cos(a)*bottom,-height*0.5,sin(a)*bottom)
			var p1 := center+basis*Vector3(cos(b)*bottom,-height*0.5,sin(b)*bottom)
			var p2 := center+basis*Vector3(cos(b)*top,height*0.5,sin(b)*top)
			var p3 := center+basis*Vector3(cos(a)*top,height*0.5,sin(a)*top)
			var normal := basis*Vector3(cos((a+b)*0.5),(bottom-top)/maxf(height,0.001),sin((a+b)*0.5))
			quad(p0,p1,p2,p3,normal,color.lightened(0.035 if i%2==0 else 0.0))
			if bottom>0.0: triangle(center-basis*Vector3(0,height*0.5,0),p1,p0,basis*Vector3.DOWN,color.darkened(0.12))
			if top>0.0: triangle(center+basis*Vector3(0,height*0.5,0),p3,p2,basis*Vector3.UP,color.lightened(0.08))

	func ellipsoid(center: Vector3, size: Vector3, color: Color, sides: int = 8, rings: int = 4) -> void:
		for r: int in range(rings):
			var lo := -PI*0.5+PI*float(r)/float(rings)
			var hi := -PI*0.5+PI*float(r+1)/float(rings)
			for i: int in range(sides):
				var a := float(i)*TAU/float(sides)
				var b := float(i+1)*TAU/float(sides)
				var p0 := center+Vector3(cos(lo)*cos(a),sin(lo),cos(lo)*sin(a))*size*0.5
				var p1 := center+Vector3(cos(lo)*cos(b),sin(lo),cos(lo)*sin(b))*size*0.5
				var p2 := center+Vector3(cos(hi)*cos(b),sin(hi),cos(hi)*sin(b))*size*0.5
				var p3 := center+Vector3(cos(hi)*cos(a),sin(hi),cos(hi)*sin(a))*size*0.5
				var outward := (Vector3(cos((lo+hi)*0.5)*cos((a+b)*0.5),sin((lo+hi)*0.5),cos((lo+hi)*0.5)*sin((a+b)*0.5))/size).normalized()
				quad(p0,p1,p2,p3,outward,color)

	func rod(start: Vector3, finish: Vector3, radius: float, color: Color, sides: int = 5) -> void:
		var delta := finish-start
		if delta.length_squared()<0.00001: return
		var up := delta.normalized()
		var right := up.cross(Vector3.FORWARD).normalized()
		if right.length_squared()<0.01: right=Vector3.RIGHT
		var back := right.cross(up).normalized()
		cone((start+finish)*0.5,radius,radius,delta.length(),color,sides,Basis(right,up,back))

	func mesh() -> ArrayMesh:
		var result := ArrayMesh.new()
		if vertices.is_empty(): return result
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_NORMAL]=normals
		arrays[Mesh.ARRAY_COLOR]=colors
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		return result


static func build(entity: Dictionary, team_color: Color) -> Node3D:
	var identity := _identity(entity)
	var key := "%s|%s|%s|%s|%s" % [identity.faction,identity.kind,identity.archetype,str(identity.elite),team_color.to_html(false)]
	if not _meshes.has(key):
		_meshes[key]=_make_parts(identity,team_color)
		_mesh_order.append(key)
		if _mesh_order.size()>MAX_SHARED_IDENTITIES:
			_meshes.erase(_mesh_order.pop_front())
	var root := Node3D.new()
	root.name="GeometricActorM77"
	root.set_meta("identity_m77",identity)
	var rig := Node3D.new()
	rig.name="Rig"
	root.add_child(rig)
	var parts: Dictionary = {"rig":rig}
	var shared: Dictionary = _meshes[key]
	for part_name: String in shared:
		var spec: Dictionary=shared[part_name]
		var pivot := Node3D.new()
		pivot.name=part_name
		pivot.position=spec.position
		var instance := MeshInstance3D.new()
		instance.mesh=spec.mesh
		instance.material_override=_surface_material()
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if part_name in ["Body","Mount"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(instance)
		rig.add_child(pivot)
		parts[part_name]=pivot
		parts[part_name+"_rest"]=pivot.position
	if parts.has("RightArm") and parts.has("Weapon"):
		var weapon: Node3D=parts.Weapon
		weapon.reparent(parts.RightArm,false)
		weapon.position=shared.Weapon.position-shared.RightArm.position
		parts.Weapon_rest=weapon.position
	if identity.hero:
		var halo := MeshInstance3D.new()
		halo.name="HeroFootprint"
		halo.mesh=_hero_ring(float(identity.width)*0.72)
		halo.material_override=_hero_ring_material(team_color)
		halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(halo)
		parts["halo"]=halo
	root.set_meta("parts_m77",parts)
	root.set_meta("phase_seed_m77",float(posmod(str(entity.get("id",entity.get("unit_id",key))).hash(),997))/997.0*TAU)
	return root


static func animate(root: Node3D, entity: Dictionary, pose: Dictionary, visual_time: float) -> void:
	if not is_instance_valid(root) or not root.has_meta("parts_m77"): return
	var parts: Dictionary=root.get_meta("parts_m77")
	var identity: Dictionary=root.get_meta("identity_m77")
	var rig: Node3D=parts.rig
	var action := str(pose.get("action",entity.get("action","IDLE")))
	var phase := clampf(float(pose.get("body_phase_m76",pose.get("phase",0.0))),0.0,1.0)
	var seed := float(root.get_meta("phase_seed_m77",0.0))
	var walking := action in ["WALK","CARRY","MOVE","RUN"]
	var attacking := action in ["ATTACK","HARVEST","MINE","BUILD","WORK"]
	var casting := action.begins_with("SKILL_") or action in ["CAST","HEAL","POTION"]
	var dead := action in ["FALLEN","DEAD","DEATH"]
	var stride := sin(visual_time*9.0+seed) if walking else 0.0
	var breathe := sin(visual_time*2.4+seed)*0.008
	var attack := sin(phase*PI)
	var swing := sin(clampf((phase-0.12)/0.70,0.0,1.0)*PI)
	rig.position=Vector3(0,absf(stride)*0.035+breathe,0)
	rig.rotation=Vector3(0,0,-0.012*stride)
	if identity.kind=="FLYING": rig.position.y=1.15+sin(visual_time*2.5+seed)*0.10
	if dead:
		rig.rotation=Vector3(0,0,lerpf(0.0,1.42,clampf(phase*2.0,0.0,1.0)))
		rig.position.y=0.10
	elif action in ["HURT","HIT","DAMAGE"]:
		rig.rotation.x=-0.14*attack
		rig.position.z=-0.08*attack
	for part_name: String in ["LeftLeg","RightLeg"]:
		if parts.has(part_name):
			var leg: Node3D=parts[part_name]
			leg.position=parts[part_name+"_rest"]
			leg.rotation=Vector3(stride*0.43*(1.0 if part_name=="LeftLeg" else -1.0),0,0)
	for part_name: String in ["LeftArm","RightArm"]:
		if not parts.has(part_name): continue
		var arm: Node3D=parts[part_name]
		arm.position=parts[part_name+"_rest"]
		var sign_value := 1.0 if part_name=="LeftArm" else -1.0
		arm.rotation=Vector3(-stride*0.28*sign_value,0,0)
		if action=="CARRY": arm.rotation.x=-0.65
		if attacking:
			arm.rotation.x=-1.45*attack if part_name=="RightArm" else -0.25*attack
			arm.rotation.z=-0.35*swing if part_name=="RightArm" else 0.12*attack
			if identity.kind=="RANGED": arm.rotation.x=-1.10-0.12*attack
		if casting: arm.rotation=Vector3(-0.95-0.65*attack,0,sign_value*0.16)
	if parts.has("Weapon"):
		var weapon: Node3D=parts.Weapon
		weapon.position=parts.Weapon_rest
		weapon.rotation=Vector3.ZERO
		if attacking:
			if identity.kind=="RANGED" or identity.kind=="SIEGE":
				weapon.position.z-=0.09*attack
				weapon.rotation.x=1.10 if identity.kind=="RANGED" else -0.12*attack
			else:
				weapon.rotation=Vector3(-0.20*attack,0,-0.30*swing)
		if casting: weapon.rotation=Vector3(-0.18*attack,0,0.12*attack)
	for wing_name: String in ["LeftWing","RightWing"]:
		if parts.has(wing_name):
			var wing: Node3D=parts[wing_name]
			wing.rotation.z=sin(visual_time*6.5+seed)*(0.32 if wing_name=="LeftWing" else -0.32)
	if parts.has("Mount"):
		var mount: Node3D=parts.Mount
		mount.rotation.x=stride*0.035
	if parts.has("halo"):
		var halo: MeshInstance3D=parts.halo
		halo.visible=not dead and bool(entity.get("alive",true))


static func visual_bounds(entity: Dictionary) -> AABB:
	var identity := _identity(entity)
	var width := float(identity.width)
	var depth := 1.75 if identity.kind in ["CAVALRY","SIEGE"] else width
	var height := float(identity.height)*1.20
	if identity.kind=="FLYING":
		width=3.5
		depth=2.1
		height=3.1
	return AABB(Vector3(-width*0.5,0,-depth*0.5),Vector3(width,height,depth))


static func _identity(entity: Dictionary) -> Dictionary:
	var type := str(entity.get("unit_type","worker"))
	var hero := type=="hero"
	var archetype := str(entity.get("hero_archetype",entity.get("archetype","COMMANDER"))) if hero else type
	var cache_key := "%s|%s|%s|%s|%s|%s" % [type,archetype,str(entity.get("faction_id","")),str(entity.get("body_kind","")),str(entity.get("role","")),str(entity.get("population",""))]
	if _identities.has(cache_key): return _identities[cache_key]
	var recipe: Dictionary=Catalog.UNITS.get(type,{})
	var profile: Dictionary={}
	if hero:
		var supplied: Variant=entity.get("hero_profile",{})
		profile=supplied if supplied is Dictionary and not supplied.is_empty() else Heroes.profile(archetype)
	var faction := str(entity.get("faction_id",profile.get("faction_id",recipe.get("faction_id","HUMAN"))))
	if faction.is_empty(): faction="HUMAN"
	var body := str(entity.get("body_kind",profile.get("body_kind",recipe.get("body_kind","HUMANOID"))))
	var role := str(entity.get("role",recipe.get("role","WORKER")))
	var kind := role
	if hero:
		var hero_role := str(entity.get("role_id",profile.get("role_id","")))
		var role_text := str(profile.get("role",""))
		kind="SUPPORT" if hero_role in ["HEAL_SUPPORT","CONTROL_SUPPORT"] or "辅助" in role_text else "MAGE" if hero_role=="MAGE" or "法师" in role_text else "HEAVY" if hero_role=="TANK" or "坦克" in role_text else "FRONTLINE"
		var stats: Dictionary=profile.get("stats",{})
		if hero_role=="PHYSICAL" and float(stats.get("attack_range",entity.get("attack_range",0)))>80.0: kind="RANGED"
	elif type=="worker": kind="WORKER"
	elif body=="DRAGON" or str(entity.get("movement_layer",recipe.get("movement_layer","GROUND")))=="AIR": kind="FLYING"
	elif body=="VEHICLE" or role=="SIEGE": kind="SIEGE"
	if kind not in ["WORKER","FRONTLINE","HEAVY","RANGED","CAVALRY","SUPPORT","SIEGE","FLYING","MAGE"]:
		kind="HEAVY" if "brute" in type or "sentinel" in type else "RANGED" if "hunter" in type or "shooter" in type else "FRONTLINE"
	var population := int(entity.get("population",recipe.get("population",2)))
	var elite := not hero and population>=6
	var height := 2.20 if hero else 2.50 if elite else 1.65
	if faction=="HIGHLAND": height*=0.86
	if kind=="CAVALRY": height=2.30
	if kind=="SIEGE": height=1.55
	if kind=="FLYING": height=2.0
	var width := 1.0 if hero else 1.15 if elite else 0.76
	if kind=="HEAVY" or faction=="HIGHLAND": width*=1.22
	if body=="MULTILEG" or faction=="UNDERGROUND": width*=1.35
	var variant := posmod(archetype.hash(),8)
	if hero:
		if not _rosters.has(faction): _rosters[faction]=Heroes.available_for_faction(faction)
		var roster: Array=_rosters[faction]
		var slot := roster.find(archetype)
		if slot>=0: variant=slot
	var result := {"hero":hero,"archetype":archetype,"faction":faction,"body":body,"kind":kind,"height":height,"width":width,"elite":elite,"variant":variant}
	if _identities.size()>=MAX_SHARED_IDENTITIES: _identities.clear()
	_identities[cache_key]=result
	return result


static func _make_parts(identity: Dictionary, team: Color) -> Dictionary:
	var palette := _palette(str(identity.faction),team)
	var height := float(identity.height)
	var factor := 0.91 if identity.kind=="CAVALRY" else height/1.78
	var width := float(identity.width)/0.76
	var kind := str(identity.kind)
	var body := Geometry.new()
	var left_leg := Geometry.new()
	var right_leg := Geometry.new()
	var left_arm := Geometry.new()
	var right_arm := Geometry.new()
	var weapon := Geometry.new()
	var result: Dictionary={}
	if kind=="SIEGE":
		_vehicle(body,weapon,palette,identity)
		result.Body=_part(body,Vector3.ZERO)
		result.Weapon=_part(weapon,Vector3(0,0.90,0))
		return result
	if kind=="FLYING": return _dragon(identity,palette)
	var riding := kind=="CAVALRY"
	var lift := 0.70 if riding else 0.0
	var body_y := 1.12*factor+lift
	var shoulder_y := 1.39*factor+lift
	var hip_y := 0.74*factor+lift
	var head_y := 1.59*factor+lift
	if kind in ["MAGE","SUPPORT"]:
		body.cone(Vector3(0,0.78*factor+lift,0),0.35*width,0.20*width,1.1*factor,palette.cloth,6)
		body.box(Vector3(0,1.16*factor+lift,0.19*width),Vector3(0.20*width,0.56*factor,0.04),palette.team)
	else:
		body.box(Vector3(0,body_y,0),Vector3(0.52*width,0.59*factor,0.32*width),palette.armor)
		body.box(Vector3(0,body_y,0.185*width),Vector3(0.30*width,0.48*factor,0.045),palette.team)
		body.cone(Vector3(0,0.73*factor+lift,0),0.33*width,0.25*width,0.28*factor,palette.cloth,6)
	body.box(Vector3(0,0.88*factor+lift,0.02),Vector3(0.58*width,0.10*factor,0.36*width),palette.leather)
	body.box(Vector3(0,0.88*factor+lift,0.22*width),Vector3(0.11,0.11,0.045),palette.trim)
	_faction_body(body,identity,palette,Vector3(0,head_y,0),factor,width)
	if bool(identity.hero): _hero_regalia(body,identity,palette,factor,width,lift)
	if str(identity.faction)=="UNDERGROUND" and not riding:
		_multilegs(left_leg,right_leg,palette,width,factor)
	else:
		left_leg.box(Vector3(0,-0.27*factor,0),Vector3(0.17*width,0.55*factor,0.20*width),palette.cloth)
		right_leg.box(Vector3(0,-0.27*factor,0),Vector3(0.17*width,0.55*factor,0.20*width),palette.cloth)
		left_leg.box(Vector3(0,-0.64*factor,0.055),Vector3(0.22*width,0.20*factor,0.31*width),palette.leather)
		right_leg.box(Vector3(0,-0.64*factor,0.055),Vector3(0.22*width,0.20*factor,0.31*width),palette.leather)
	var arm_color: Color=palette.skin if kind=="WORKER" else palette.armor
	for arm: Geometry in [left_arm,right_arm]:
		arm.box(Vector3(0,-0.24*factor,0),Vector3(0.18*width,0.45*factor,0.23*width),arm_color)
		arm.box(Vector3(0,-0.48*factor,0.015),Vector3(0.20*width,0.17*factor,0.22*width),palette.skin)
		if kind!="WORKER": arm.box(Vector3(0,-0.03,0),Vector3(0.27*width,0.18*factor,0.32*width),palette.trim if bool(identity.hero) else palette.armor)
	_weapon(weapon,left_arm,identity,palette,factor,width)
	result.Body=_part(body,Vector3.ZERO)
	result.LeftLeg=_part(left_leg,Vector3(-0.17*width,hip_y,0))
	result.RightLeg=_part(right_leg,Vector3(0.17*width,hip_y,0))
	result.LeftArm=_part(left_arm,Vector3(-0.38*width,shoulder_y,0))
	result.RightArm=_part(right_arm,Vector3(0.38*width,shoulder_y,0))
	result.Weapon=_part(weapon,Vector3(0.40*width,shoulder_y-0.43*factor,0.12))
	if riding:
		var mount := Geometry.new()
		_mount(mount,identity,palette)
		result.Mount=_part(mount,Vector3.ZERO)
	return result


static func _faction_body(g: Geometry, identity: Dictionary, p: Dictionary, head: Vector3, f: float, w: float) -> void:
	var kind := str(identity.kind)
	match str(identity.faction):
		"UNDEAD":
			g.ellipsoid(head,Vector3(0.35*w,0.41*f,0.34*w),p.skin,6,3)
			g.box(head+Vector3(0,-0.15*f,0.08),Vector3(0.24*w,0.10*f,0.21),p.skin.darkened(0.1))
			for sign_value: float in [-1.0,1.0]:
				g.box(head+Vector3(sign_value*0.09*w,0.015,0.15*w),Vector3(0.075,0.075,0.04),p.dark)
				g.box(head+Vector3(sign_value*0.09*w,0.015,0.178*w),Vector3(0.04,0.035,0.02),p.glow)
			for i: int in range(3): g.rod(Vector3(-0.22*w,(1.00+i*0.14)*f,0.19),Vector3(0.22*w,(1.00+i*0.14)*f,0.19),0.032,p.skin)
			if kind!="WORKER": g.cone(head+Vector3(0,0.23*f,-0.02),0.25*w,0.07,0.28*f,p.cloth,5)
		"MACHINE":
			g.box(head,Vector3(0.40*w,0.30*f,0.34*w),p.armor)
			g.box(head+Vector3(0,0.005,0.19*w),Vector3(0.28*w,0.075*f,0.045),p.dark)
			g.box(head+Vector3(0,0.005,0.217*w),Vector3(0.17*w,0.035*f,0.02),p.glow)
			g.cone(Vector3(0,1.14*f,-0.25*w),0.21*w,0.21*w,0.49*f,p.copper,8)
			g.cone(Vector3(-0.22*w,1.51*f,-0.23*w),0.055,0.055,0.44*f,p.dark,5)
			g.box(Vector3(0,1.18*f,0.21*w),Vector3(0.19*w,0.20*f,0.045),p.glow)
		"FOREST":
			g.ellipsoid(head,Vector3(0.31*w,0.40*f,0.29*w),p.skin,6,3)
			g.cone(head+Vector3(0,0.08*f,-0.025),0.26*w,0.10*w,0.31*f,p.cloth,6)
			for sign_value: float in [-1.0,1.0]:
				g.cone(head+Vector3(sign_value*0.20*w,0.01,0),0.075,0.0,0.26*f,p.skin,4,Basis(Vector3.FORWARD,sign_value*0.8))
				if kind!="WORKER":
					g.rod(head+Vector3(sign_value*0.13,0.14*f,-0.05),head+Vector3(sign_value*0.27,0.43*f,-0.10),0.035,p.wood)
					g.rod(head+Vector3(sign_value*0.24,0.35*f,-0.09),head+Vector3(sign_value*0.38,0.41*f,-0.03),0.027,p.wood)
			g.box(Vector3(0,1.09*f,-0.22*w),Vector3(0.49*w,0.62*f,0.08),p.cloth,Basis(Vector3.RIGHT,-0.12))
		"HIGHLAND":
			g.ellipsoid(head,Vector3(0.44*w,0.42*f,0.36*w),p.skin,6,3)
			g.cone(head+Vector3(0,-0.19*f,0.14*w),0.035,0.20*w,0.36*f,p.leather,5)
			g.cone(head+Vector3(0,0.19*f,0),0.28*w,0.10*w,0.23*f,p.armor,6)
			for sign_value: float in [-1.0,1.0]:
				g.rod(head+Vector3(sign_value*0.20*w,0.15,0),head+Vector3(sign_value*0.37*w,0.24*f,0.05),0.07,p.bone)
			g.box(Vector3(0,1.35*f,-0.03),Vector3(0.80*w,0.19*f,0.43*w),p.stone)
		"UNDERGROUND":
			g.ellipsoid(head+Vector3(0,-0.12*f,0.04),Vector3(0.55*w,0.37*f,0.47*w),p.armor,6,3)
			g.ellipsoid(Vector3(0,1.12*f,-0.13*w),Vector3(0.69*w,0.62*f,0.57*w),p.cloth,6,3)
			for sign_value: float in [-1.0,1.0]:
				g.box(head+Vector3(sign_value*0.13*w,-0.075,0.25*w),Vector3(0.11,0.055,0.025),p.glow)
				g.rod(head+Vector3(sign_value*0.12*w,0.07,0.13),head+Vector3(sign_value*0.23*w,0.35*f,0.23),0.025,p.bone)
			g.box(Vector3(0,1.23*f,0.27*w),Vector3(0.32*w,0.22*f,0.06),p.team)
		_:
			g.ellipsoid(head,Vector3(0.34*w,0.40*f,0.33*w),p.skin,8,3)
			if kind=="WORKER":
				g.cone(head+Vector3(0,0.18*f,0),0.29*w,0.12*w,0.12*f,p.leather,6)
			else:
				g.cone(head+Vector3(0,0.15*f,-0.02),0.25*w,0.17*w,0.26*f,p.armor,6)
				g.box(head+Vector3(0,0.015,0.19*w),Vector3(0.29*w,0.07,0.04),p.dark)
				g.box(head+Vector3(0,0.35*f,-0.04),Vector3(0.06,0.20*f,0.23*w),p.team)
	if str(identity.faction) not in ["UNDEAD","MACHINE","UNDERGROUND"]:
		for sign_value: float in [-1.0,1.0]: g.box(head+Vector3(sign_value*0.07*w,0.015,0.17*w),Vector3(0.045,0.045,0.025),p.dark)
	if kind=="WORKER":
		g.box(Vector3(0,1.04*f,0.24*w),Vector3(0.31*w,0.55*f,0.06),p.leather)
		g.box(Vector3(0,1.21*f,-0.25*w),Vector3(0.35*w,0.35*f,0.22*w),p.wood)
		g.box(Vector3(0,1.20*f,0.28*w),Vector3(0.28*w,0.15*f,0.025),p.team)


static func _hero_regalia(g: Geometry, identity: Dictionary, p: Dictionary, f: float, w: float, lift: float) -> void:
	var variant := int(identity.variant)
	# Weapon silhouette + back/hat silhouette are independent recognition cues;
	# archetype variants are intentionally not described as hand-authored skins.
	var kind := str(identity.kind)
	if kind=="HEAVY":
		g.box(Vector3(0,1.30*f+lift,-0.02),Vector3(0.95*w,0.19*f,0.40*w),p.trim)
		g.cone(Vector3(0,1.94*f+lift,0),0.18,0,0.33*f,p.trim,4+variant%3)
	elif kind=="MAGE":
		g.cone(Vector3(0,1.84*f+lift,0),0.28*w,0.0,0.48*f,p.cloth,4+variant%3)
		g.ellipsoid(Vector3(0,1.41*f+lift,-0.26*w),Vector3(0.52*w,0.50*f,0.11),p.trim,6,3)
	elif kind=="SUPPORT":
		g.rod(Vector3(-0.25*w,1.29*f+lift,-0.27),Vector3(-0.25*w,2.05*f+lift,-0.27),0.035,p.trim)
		g.box(Vector3(-0.09*w,1.82*f+lift,-0.27),Vector3(0.34*w,0.32*f,0.07),p.team)
	elif kind=="RANGED":
		g.box(Vector3(-0.25*w,1.40*f+lift,-0.20),Vector3(0.19,0.58*f,0.20),p.leather,Basis(Vector3.FORWARD,-0.24))
		g.cone(Vector3(0,1.80*f+lift,-0.03),0.21,0.04,0.20*f,p.cloth,5)
	else:
		g.box(Vector3(0,1.10*f+lift,-0.25*w),Vector3(0.61*w,0.94*f,0.07),p.team.darkened(0.24),Basis(Vector3.RIGHT,-0.11))
		g.cone(Vector3(-0.27*w,1.53*f+lift,0),0.14,0,0.30*f,p.trim,4)
	if (variant&1)!=0:
		g.rod(Vector3(0.29*w,1.50*f+lift,-0.13),Vector3(0.47*w,1.83*f+lift,-0.20),0.045,p.bone)
	if (variant&2)!=0:
		g.box(Vector3(0.14*w,1.17*f+lift,0.23*w),Vector3(0.17,0.23,0.06),p.trim)
		g.box(Vector3(-0.21*w,1.59*f+lift,-0.27*w),Vector3(0.12,0.52*f,0.12),p.wood,Basis(Vector3.FORWARD,0.24))
	if (variant&4)!=0:
		for side: float in [-1.0,1.0]:
			g.cone(Vector3(side*0.24*w,1.80*f+lift,-0.06),0.09,0,0.31*f,p.trim,4)


static func _weapon(g: Geometry, shield: Geometry, identity: Dictionary, p: Dictionary, f: float, w: float) -> void:
	var kind := str(identity.kind)
	var faction := str(identity.faction)
	if kind=="WORKER":
		g.rod(Vector3(0,-0.20*f,0),Vector3(0,0.54*f,0),0.038,p.wood)
		g.box(Vector3(0,0.50*f,0),Vector3(0.50*f,0.11,0.10),p.armor,Basis(Vector3.FORWARD,-0.12))
		return
	if kind in ["MAGE","SUPPORT"]:
		g.rod(Vector3(0,-0.48*f,0),Vector3(0,0.84*f,0),0.045,p.wood if faction!="MACHINE" else p.copper)
		if faction=="UNDERGROUND":
			g.ellipsoid(Vector3(0,0.86*f,0),Vector3(0.41,0.24,0.35),p.cloth,6,3)
			g.cone(Vector3(0,0.80*f,0),0.10,0.0,0.25,p.glow,5)
		elif faction=="HIGHLAND":
			g.box(Vector3(0,0.78*f,0),Vector3(0.33,0.38,0.21),p.stone)
			g.box(Vector3(0,0.80*f,0.12),Vector3(0.11,0.21,0.025),p.glow)
		else:
			g.cone(Vector3(0,0.88*f,0),0.13,0,0.40,p.glow,4)
			g.cone(Vector3(0,0.66*f,0),0.0,0.13,0.20,p.trim,4)
		if bool(identity.hero):
			shield.box(Vector3(0,-0.33*f,0.20),Vector3(0.30,0.12,0.36),p.cloth)
			shield.box(Vector3(0,-0.25*f,0.20),Vector3(0.26,0.03,0.32),p.bone)
		return
	if kind=="RANGED":
		if faction=="MACHINE":
			g.box(Vector3(0,0.02,0.20),Vector3(0.18,0.22,0.65*f),p.armor)
			g.cone(Vector3(0,0.02,0.64*f),0.055,0.055,0.45*f,p.dark,6,Basis(Vector3.RIGHT,PI*0.5))
			g.box(Vector3(0,0.14,0.02),Vector3(0.15,0.08,0.18),p.team)
		elif faction=="HIGHLAND":
			g.rod(Vector3(0,-0.04,0),Vector3(0,0.45*f,0.30),0.025,p.leather)
			g.rod(Vector3(0,0.45*f,0.30),Vector3(0,0.20*f,0.55),0.025,p.leather)
			g.ellipsoid(Vector3(0,0.20*f,0.55),Vector3(0.17,0.15,0.17),p.stone,5,3)
		else:
			for sign_value: float in [-1.0,1.0]:
				g.rod(Vector3(0,0,0.16),Vector3(sign_value*0.43*f,0,0.30),0.042,p.wood)
				g.rod(Vector3(sign_value*0.43*f,0,0.30),Vector3(sign_value*0.50*f,0,0.09),0.035,p.wood)
				g.rod(Vector3(sign_value*0.50*f,0,0.09),Vector3(0,0,-0.05),0.009,p.bone)
			g.rod(Vector3(0,0.015,-0.09),Vector3(0,0.015,0.51*f),0.014,p.armor)
		return
	if kind=="HEAVY" or faction=="HIGHLAND":
		g.rod(Vector3(0,-0.22*f,0),Vector3(0,0.78*f,0),0.045,p.wood)
		if faction in ["HIGHLAND","MACHINE"]:
			g.box(Vector3(0,0.69*f,0),Vector3(0.45*f,0.31*f,0.28*f),p.stone if faction=="HIGHLAND" else p.armor)
			g.box(Vector3(0,0.69*f,0.16*f),Vector3(0.23*f,0.15*f,0.035),p.team)
		else:
			g.box(Vector3(0.11*f,0.69*f,0),Vector3(0.45*f,0.35*f,0.11),p.armor)
			g.cone(Vector3(0,0.96*f,0),0.08,0,0.27*f,p.trim,4)
	else:
		g.rod(Vector3(0,-0.18*f,0),Vector3(0,0.06*f,0),0.045,p.leather)
		g.box(Vector3(0,0.08*f,0),Vector3(0.29,0.065,0.12),p.trim)
		g.box(Vector3(0,0.40*f,0),Vector3(0.11,0.59*f,0.055),p.armor)
		g.cone(Vector3(0,0.78*f,0),0.075,0.0,0.20*f,p.armor,4)
		shield.box(Vector3(-0.07,-0.26*f,0.16),Vector3(0.41*w,0.57*f,0.13),p.armor)
		shield.box(Vector3(-0.07,-0.26*f,0.24),Vector3(0.28*w,0.40*f,0.035),p.team)
		shield.box(Vector3(-0.07,-0.26*f,0.27),Vector3(0.07,0.25*f,0.035),p.trim)


static func _multilegs(left: Geometry, right: Geometry, p: Dictionary, w: float, f: float) -> void:
	for i: int in range(3):
		var z := float(i-1)*0.30
		for sign_value: float in [-1.0,1.0]:
			var g: Geometry=left if (i+int(sign_value))%2==0 else right
			var start := Vector3(sign_value*0.02,-0.05*f,z)
			var knee := Vector3(sign_value*0.46*w,-0.22*f,z-0.05)
			var foot := Vector3(sign_value*0.59*w,-0.74*f,z+0.06)
			g.rod(start,knee,0.055,p.armor)
			g.rod(knee,foot,0.045,p.leather)


static func _mount(g: Geometry, identity: Dictionary, p: Dictionary) -> void:
	g.ellipsoid(Vector3(0,0.83,0),Vector3(0.68,0.63,1.42),p.wood,8,4)
	g.cone(Vector3(0,1.18,0.59),0.20,0.15,0.60,p.wood,6,Basis(Vector3.RIGHT,-0.35))
	g.ellipsoid(Vector3(0,1.39,0.77),Vector3(0.30,0.34,0.59),p.wood,6,3)
	for x: float in [-0.24,0.24]:
		for z: float in [-0.45,0.45]:
			g.rod(Vector3(x,0.68,z),Vector3(x,0.08,z+0.04),0.07,p.leather)
			g.box(Vector3(x,0.08,z+0.06),Vector3(0.16,0.12,0.23),p.dark)
	g.box(Vector3(0,1.13,-0.03),Vector3(0.73,0.11,0.60),p.team)
	if str(identity.faction)=="FOREST":
		for sign_value: float in [-1.0,1.0]:
			g.rod(Vector3(sign_value*0.11,1.56,0.69),Vector3(sign_value*0.30,1.91,0.60),0.035,p.bone)
			g.rod(Vector3(sign_value*0.24,1.79,0.63),Vector3(sign_value*0.41,1.88,0.74),0.025,p.bone)
	elif str(identity.faction)=="UNDERGROUND":
		g.rod(Vector3(0,0.87,-0.57),Vector3(0,0.46,-1.19),0.12,p.cloth)
		for i: int in range(4): g.cone(Vector3(0,1.17,-0.40+float(i)*0.24),0.09,0,0.20,p.bone,4)


static func _vehicle(body: Geometry, weapon: Geometry, p: Dictionary, identity: Dictionary) -> void:
	body.box(Vector3(0,0.62,0),Vector3(1.03,0.53,1.44),p.armor)
	body.box(Vector3(0,0.91,-0.10),Vector3(0.65,0.28,0.87),p.team)
	for side: float in [-1.0,1.0]:
		for z: float in [-0.48,0.48]:
			body.cone(Vector3(side*0.62,0.39,z),0.34,0.34,0.19,p.dark,8,Basis(Vector3.FORWARD,PI*0.5))
			body.cone(Vector3(side*0.73,0.39,z),0.14,0.14,0.025,p.copper,6,Basis(Vector3.FORWARD,PI*0.5))
	body.box(Vector3(0,0.62,-0.79),Vector3(0.60,0.36,0.20),p.copper)
	weapon.cone(Vector3(0,0.13,0.34),0.20,0.14,1.10,p.armor,8,Basis(Vector3.RIGHT,PI*0.5))
	weapon.cone(Vector3(0,0.13,0.91),0.14,0.14,0.03,p.dark,8,Basis(Vector3.RIGHT,PI*0.5))
	if bool(identity.elite):
		body.cone(Vector3(0,1.23,-0.37),0.22,0.05,0.50,p.glow,5)
		body.box(Vector3(0,0.62,0.78),Vector3(1.10,0.28,0.13),p.trim)


static func _dragon(identity: Dictionary, p: Dictionary) -> Dictionary:
	var body := Geometry.new()
	var head := Geometry.new()
	var left := Geometry.new()
	var right := Geometry.new()
	body.ellipsoid(Vector3(0,0.35,0),Vector3(0.80,0.70,1.48),p.cloth,8,4)
	body.rod(Vector3(0,0.29,-0.54),Vector3(0,0.03,-1.36),0.16,p.armor)
	head.ellipsoid(Vector3(0,0.42,0.78),Vector3(0.49,0.42,0.77),p.armor,6,3)
	head.box(Vector3(0,0.36,1.16),Vector3(0.31,0.19,0.39),p.armor)
	for sign_value: float in [-1.0,1.0]:
		head.rod(Vector3(sign_value*0.14,0.58,0.68),Vector3(sign_value*0.26,0.86,0.47),0.05,p.bone)
		head.box(Vector3(sign_value*0.24,0.49,0.88),Vector3(0.03,0.07,0.09),p.glow)
		body.rod(Vector3(sign_value*0.27,0.25,0.22),Vector3(sign_value*0.36,-0.16,0.46),0.07,p.armor)
	for pair: Array in [[left,-1.0],[right,1.0]]:
		var g: Geometry=pair[0]
		var sign_value := float(pair[1])
		var a := Vector3.ZERO
		var b := Vector3(sign_value*1.41,0.26,-0.36)
		var c := Vector3(sign_value*1.05,0.01,-0.91)
		var d := Vector3(sign_value*0.16,-0.05,-0.56)
		g.quad(a,b,c,d,Vector3.UP,p.team.darkened(0.18))
		g.quad(d,c,b,a,Vector3.DOWN,p.cloth)
		g.rod(a,b,0.045,p.armor)
		g.rod(b,c,0.035,p.armor)
		g.rod(a,c,0.027,p.armor)
	return {"Body":_part(body,Vector3.ZERO),"Weapon":_part(head,Vector3.ZERO),"LeftWing":_part(left,Vector3(-0.25,0.50,0.15)),"RightWing":_part(right,Vector3(0.25,0.50,0.15))}


static func _palette(faction: String, team: Color) -> Dictionary:
	var palette := {"team":team,"skin":Color("c99a70"),"armor":Color("8996a0"),"cloth":Color("3c5361"),"leather":Color("574333"),"wood":Color("72513a"),"trim":Color("c5a258"),"bone":Color("d7cfaa"),"stone":Color("777c80"),"copper":Color("94643c"),"glow":Color("c4e5e4"),"dark":Color("202933")}
	match faction:
		"UNDEAD": palette.merge({"skin":Color("c8c4ad"),"armor":Color("555b66"),"cloth":Color("423d58"),"leather":Color("383f3c"),"glow":Color("a7d8a0")},true)
		"MACHINE": palette.merge({"skin":Color("777d7c"),"armor":Color("555f63"),"cloth":Color("4c5556"),"trim":Color("b98a4d"),"glow":Color("e3ba68")},true)
		"FOREST": palette.merge({"skin":Color("b4ba86"),"armor":Color("78694d"),"cloth":Color("43634d"),"leather":Color("554a39"),"glow":Color("c7e5a0")},true)
		"HIGHLAND": palette.merge({"skin":Color("b99b83"),"armor":Color("777d80"),"cloth":Color("65515d"),"leather":Color("7a5140"),"trim":Color("ba915c"),"glow":Color("efb887")},true)
		"UNDERGROUND": palette.merge({"skin":Color("a3a18a"),"armor":Color("5b6b69"),"cloth":Color("66635c"),"leather":Color("464543"),"trim":Color("b2b295"),"glow":Color("bbddc7")},true)
	return palette


static func _part(g: Geometry, position: Vector3) -> Dictionary:
	return {"mesh":g.mesh(),"position":position}


static func _surface_material() -> StandardMaterial3D:
	if _material==null:
		_material=StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo=true
		_material.vertex_color_is_srgb=false
		_material.roughness=0.91
		_material.metallic=0.06
		# Merged primitives use flat normals, not textures or per-actor shaders.
		_material.cull_mode=BaseMaterial3D.CULL_BACK
	return _material


static func _hero_ring(radius: float) -> ArrayMesh:
	var key := "hero-ring:%.3f"%radius
	if _meshes.has(key): return _meshes[key]
	var g := Geometry.new()
	for i: int in range(32):
		var a := float(i)*TAU/32.0
		var b := float(i+1)*TAU/32.0
		var outer_a := Vector3(cos(a)*radius,0.035,sin(a)*radius*0.82)
		var outer_b := Vector3(cos(b)*radius,0.035,sin(b)*radius*0.82)
		var inner_a := Vector3(cos(a)*(radius-0.045),0.035,sin(a)*(radius-0.045)*0.82)
		var inner_b := Vector3(cos(b)*(radius-0.045),0.035,sin(b)*(radius-0.045)*0.82)
		g.quad(outer_a,outer_b,inner_b,inner_a,Vector3.UP,Color.WHITE)
	var result := g.mesh()
	_meshes[key]=result
	return result


static func _hero_ring_material(team: Color) -> StandardMaterial3D:
	var key := team.to_html(false)
	if not _ring_materials.has(key):
		var material := StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color=Color(team.r,team.g,team.b,0.72)
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		_ring_materials[key]=material
	return _ring_materials[key]
