extends Node3D
## View-only actors. No physics body, world mutation, combat or steering lives here.
const Pose3D = preload("res://src/presentation/strategic_action_pose.gd")
const SidePalette = preload("res://src/presentation/strategic_side_palette.gd")
const SCALE := 1.0 / 24.0
const ROOT := "res://assets/art/frontier3d/"
const BUILDING_MODELS := {"BASE":"keep", "BARRACKS":"barracks", "RANGE":"barracks", "TOWER":"tower", "FOUNDRY":"workshop", "WORKSHOP":"workshop", "ALTAR":"keep", "DRAGON_ROOST":"barracks"}
var records: Dictionary = {}
var _scenes: Dictionary = {}
var _team_materials: Dictionary = {}
var _normalized_materials: Dictionary = {}
var _missing: Dictionary = {}
var _last_tick := -1
var _actions: Dictionary = {}
var _pick_geometry: Dictionary = {}

func observe(facts: Dictionary, delta: float) -> void:
	var live: Dictionary = {}
	var tick := int(facts.get("tick",0))
	var active: bool = facts.get("outcome","ONGOING") == "ONGOING"
	_actions.clear()
	for collection: String in ["buildings","sites","soldiers","workers"]:
		for supplied: Dictionary in facts.get(collection,[]):
			var kind := "building" if collection == "buildings" else "site" if collection == "sites" else "unit"
			if kind != "site" and (int(supplied.get("hp",0)) <= 0 or not supplied.get("alive",true)): continue
			# Resource sites already have an actual base, or remain an empty legal
			# construction site; never invent a colliding second keep on top.
			if kind == "site" and supplied.get("kind") != "VILLAGE": continue
			var id := kind+":"+str(supplied.get("id",""))
			live[id] = true
			var model := model_for(supplied,kind)
			var owner := str(supplied.get("owner","") if kind == "site" else supplied.get("side",""))
			var signature := model+":"+owner
			if records.has(id) and records[id].signature != signature:
				records[id].root.queue_free(); records.erase(id)
			if not records.has(id):
				var actor := _instantiate(model,owner)
				if actor == null: continue
				add_child(actor)
				var animation := _find_animation(actor)
				records[id] = {"root":actor,"model":model,"signature":signature,"animation":animation,"clip":"","kind":kind,"observation_id":str(supplied.get("id","")),"bounds":_bounds(actor)}
				actor.position = _point(supplied)
				actor.rotation.y = PI if kind == "unit" and owner != "PLAYER" else 0.0
			var record: Dictionary = records[id]
			var actor: Node3D = record.root
			var target := _point(supplied)
			actor.position = actor.position.lerp(target,clampf(delta*24,0,1)) if kind == "unit" and actor.position.distance_to(target)<5 else target
			if kind == "unit":
				var pose := Pose3D.for_unit(supplied,tick)
				var direction := Vector2(pose.direction)
				var action := str(pose.action) if active else "IDLE"
				# With no observed movement/action there is no factual facing to
				# replace. Retain the last heading (initially toward the camera).
				if pose.moving or action not in ["IDLE","FALLEN"]:
					actor.rotation.y = lerp_angle(actor.rotation.y,atan2(direction.x,direction.y),clampf(delta*16,0,1))
				_actions[str(supplied.get("id",""))] = action
				var clip := "WALK" if action in ["WALK","CARRY"] else "WORK" if action in ["HARVEST","MINE","BUILD"] else "ATTACK" if action == "ATTACK" or action.begins_with("SKILL_") else "IDLE"
				_play(record,clip,pose)
			elif kind == "building":
				# Future geometry is not the collision body. Incomplete buildings
				# visibly rise from foundations; construction facts stay unchanged.
				var complete := bool(supplied.get("complete",false))
				var fraction := 1.0 if complete else clampf(float(supplied.get("progress",0))/maxf(float(supplied.get("max_progress",100)),1),0.06,1)
				actor.scale.y = fraction
				if model == "keep": actor.scale = Vector3.ONE * (1.0+0.08*maxi(int(supplied.get("base_tier",1))-1,0)) * Vector3(1,fraction,1)
	for id: String in records.keys():
		if not live.has(id): records[id].root.queue_free(); records.erase(id)
	_last_tick = tick

static func model_for(entity: Dictionary, kind: String) -> String:
	if kind == "site": return "village"
	if kind == "building": return str(BUILDING_MODELS.get(str(entity.get("building_type","")),"workshop"))
	var unit := str(entity.get("unit_type",""))
	if unit == "worker": return "worker"
	if unit == "hero": return "hero"
	if unit in ["bright_crossbow","grove_mender"] or float(entity.get("attack_range",0))>100: return "crossbow"
	return "infantry"

func _instantiate(model: String, owner: String) -> Node3D:
	if not _scenes.has(model):
		var path := ROOT+model+".glb"
		if not ResourceLoader.exists(path): _missing[model] = true; return null
		_scenes[model] = load(path)
		_missing.erase(model)
	var actor := (_scenes[model] as PackedScene).instantiate() as Node3D
	if actor == null: return null
	actor.name = model
	_tint_team(actor,owner)
	return actor

func _tint_team(node: Node, owner: String) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		for index: int in range(mesh.mesh.get_surface_count() if mesh.mesh != null else 0):
			var material := mesh.get_active_material(index)
			if not material is StandardMaterial3D: continue
			var team := "TEAM" in material.resource_name.to_upper()
			var key := str(material.get_instance_id())+(":"+owner if team else "")
			if not _normalized_materials.has(key):
				var copy := material.duplicate() as StandardMaterial3D
				# Native import inspection found surface0 loses this flag despite
				# having valid glTF COLOR_0. Normalize all palette surfaces once.
				copy.vertex_color_use_as_albedo = true
				copy.vertex_color_is_srgb = false
				if team:
					copy.albedo_color = SidePalette.side_color(owner).darkened(0.3)
					_team_materials[key] = copy
				_normalized_materials[key] = copy
			mesh.set_surface_override_material(index,_normalized_materials[key])
	for child: Node in node.get_children(): _tint_team(child,owner)

func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node as AnimationPlayer
	for child: Node in node.get_children():
		var player := _find_animation(child)
		if player != null: return player
	return null

func _play(record: Dictionary, clip: String, pose: Dictionary) -> void:
	var player: AnimationPlayer = record.animation
	if player == null: return
	var name := ""
	for candidate: String in player.get_animation_list():
		if candidate.to_upper().ends_with(clip): name = candidate; break
	if name.is_empty(): return
	if record.clip != name:
		player.play(name,0.08)
		record.clip = name
	if clip == "ATTACK":
		player.seek(clampf(float(pose.get("phase",0)),0,0.99)*player.get_animation(name).length,true)
		player.pause()
	elif not player.is_playing(): player.play(name)

func _point(entity: Dictionary) -> Vector3:
	var value := Vector2(entity.get("position",Vector2.ZERO))
	return Vector3(value.x*SCALE,0,value.y*SCALE)

func _bounds(actor: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child: Node in actor.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		var local := actor.global_transform.affine_inverse()*mesh.global_transform
		var box := local*mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func screen_bounds(id: String, kind: String, projection: RefCounted) -> Rect2:
	var key := kind+":"+id
	if not records.has(key): return Rect2()
	var record: Dictionary = records[key]
	var actor: Node3D = record.root
	var box: AABB = record.bounds
	var rect := Rect2()
	for index: int in range(8):
		var vertex := actor.global_transform*box.get_endpoint(index)
		var screen: Vector2 = projection.world_to_screen_height(Vector2(vertex.x,vertex.z)/SCALE,vertex.y)
		rect = Rect2(screen,Vector2.ZERO) if index == 0 else rect.expand(screen)
	return rect.grow(3)

func opaque_building_contains(id: String, ray_origin: Vector3, ray_direction: Vector3) -> bool:
	var key := "building:"+id
	if not records.has(key): return false
	var record: Dictionary = records[key]
	var actor: Node3D = record.root
	var model := str(record.model)
	if not _pick_geometry.has(model):
		# One cached CPU BVH per source model, not physics colliders. Roof
		# corners and gateway air remain ground instead of invisible hit boxes.
		var faces := PackedVector3Array()
		for node: Node in actor.find_children("*","MeshInstance3D",true,false):
			var mesh := node as MeshInstance3D
			var local := actor.global_transform.affine_inverse()*mesh.global_transform
			for vertex: Vector3 in mesh.mesh.get_faces(): faces.append(local*vertex)
		var triangles := TriangleMesh.new()
		if not triangles.create_from_faces(faces): return false
		_pick_geometry[model] = triangles
	var inverse := actor.global_transform.affine_inverse()
	return not (_pick_geometry[model] as TriangleMesh).intersect_ray(inverse*ray_origin,(inverse.basis*ray_direction).normalized()).is_empty()

func get_diagnostics() -> Dictionary:
	var animations := 0
	for record: Dictionary in records.values():
		if record.animation != null: animations += 1
	return {"actors":records.size(),"cached_models":_scenes.size(),"team_materials":_team_materials.size(),"animated_actors":animations,"missing_models":_missing.keys(),"actions":_actions.duplicate(),"tick":_last_tick,"coverage":"human-frontier prototype; other cultures/advanced profiles use role proxies"}
