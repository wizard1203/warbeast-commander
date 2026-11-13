extends Node3D
## M77 optional presentation. One manager animates retained geometry; it never
## commands units, reads the authority, creates colliders or mutates observations.
const UnitModels = preload("res://src/presentation/geometric_units_m77.gd")
const BuildingModels = preload("res://src/presentation/geometric_buildings_m77.gd")
const ActionPose = preload("res://src/presentation/strategic_action_pose.gd")
const TeamPalette = preload("res://src/presentation/strategic_side_palette.gd")
const Visibility = preload("res://src/presentation/heroic_actor_readout.gd")
const WORLD_SCALE := 1.0 / 24.0
var records: Dictionary = {}
var view_side_id := "PLAYER"
var _tick := -100000
var _seconds := 0.0
var _after_tick := 0.05
var _created := 0
var _observed_facts_m77: Dictionary = {}


func observe(facts: Dictionary, delta: float) -> void:
	var active: bool = facts.get("phase", "") == "BATTLE" and facts.get("outcome", "ONGOING") == "ONGOING"
	var tick := int(facts.get("tick", 0))
	if tick != _tick or not is_same(facts, _observed_facts_m77) or records.is_empty():
		_refresh_membership(facts, tick)
		_observed_facts_m77 = facts
		_tick = tick
		_after_tick = 0.0
	else:
		_after_tick += maxf(delta, 0.0) if active else 0.05
	var fraction := clampf(_after_tick / 0.05, 0.0, 1.0)
	# Interpolate only one factual step. Paused/stalled observations must not
	# keep walking or replaying attacks indefinitely on a wall-clock timer.
	_seconds = float(tick) * 0.05 + minf(_after_tick, 0.05)
	for record: Dictionary in records.values():
		var actor: Node3D = record.root
		var entity: Dictionary = record.entity
		actor.visible = Visibility.visible_to(entity, view_side_id)
		if not actor.visible: continue
		if record.kind == "unit":
			actor.position = Vector3(record.previous).lerp(Vector3(record.target), fraction)
			var pose: Dictionary = record.pose
			if not active: pose = {"action":"IDLE", "phase":0.0, "moving":false, "direction":Vector2.DOWN}
			if bool(pose.get("moving", false)) or str(pose.get("action", "IDLE")) != "IDLE":
				var direction := Vector2(pose.get("direction", Vector2.DOWN))
				if direction.length_squared() > 0.01:
					actor.rotation.y = lerp_angle(actor.rotation.y, atan2(direction.x, direction.y), clampf(delta * 18.0, 0.0, 1.0))
			UnitModels.animate(actor, entity, pose, _seconds)
		else:
			actor.position = record.target
			var fraction_built := 1.0 if bool(entity.get("complete", true)) else clampf(float(entity.get("progress", 0)) / maxf(float(entity.get("max_progress", 100)), 1.0), 0.08, 1.0)
			actor.scale = Vector3(1.0, fraction_built, 1.0)


func _refresh_membership(facts: Dictionary, tick: int) -> void:
	var live: Dictionary = {}
	for collection: String in ["buildings", "sites", "soldiers", "workers"]:
		for supplied: Dictionary in facts.get(collection, []):
			var kind := "building" if collection == "buildings" else "site" if collection == "sites" else "unit"
			if kind == "site" and str(supplied.get("kind", "")) != "VILLAGE": continue
			if kind != "site" and not Visibility.living(supplied): continue
			var key := kind + ":" + str(supplied.get("id", ""))
			live[key] = true
			var owner := str(supplied.get("owner", "") if kind == "site" else supplied.get("side", ""))
			var signature := "%s:%s:%s:%s:%s:%s" % [supplied.get("faction_id", "HUMAN"), owner, supplied.get("unit_type", supplied.get("building_type", "VILLAGE")), supplied.get("hero_archetype", ""), supplied.get("base_tier", 1), supplied.get("complete", true)]
			if records.has(key) and str(records[key].signature) != signature:
				records[key].root.queue_free()
				records.erase(key)
			if not records.has(key):
				var entity: Dictionary = supplied
				if kind == "site":
					entity = supplied.duplicate()
					entity["building_type"] = "VILLAGE"
				var tint := TeamPalette.side_color(owner) if not owner.is_empty() else Color("8d9b87")
				var actor: Node3D = UnitModels.build(entity, tint) if kind == "unit" else BuildingModels.build(entity, tint)
				actor.name = key.replace(":", "_")
				add_child(actor)
				var target := _position(supplied)
				actor.position = target
				var bounds: AABB = UnitModels.visual_bounds(entity) if kind == "unit" else BuildingModels.visual_bounds(entity)
				records[key] = {"root":actor, "entity":supplied, "kind":kind, "signature":signature, "bounds":bounds, "previous":target, "target":target, "pose":{}}
				_created += 1
			var record: Dictionary = records[key]
			var target := _position(supplied)
			var previous: Vector3 = record.root.position
			if previous.distance_to(target) > 5.0 or tick != _tick + 1: previous = target
			record.previous = previous
			record.target = target
			record.entity = supplied
			if kind == "unit": record.pose = ActionPose.for_unit(supplied, tick)
	for key: String in records.keys():
		if not live.has(key):
			records[key].root.queue_free()
			records.erase(key)


static func _position(entity: Dictionary) -> Vector3:
	var point := Vector2(entity.get("position", Vector2.ZERO))
	# The unit model owns flight pose/height, so the root remains the factual
	# ground anchor used by selection and overlays (no duplicate altitude).
	return Vector3(point.x * WORLD_SCALE, 0.0, point.y * WORLD_SCALE)


func screen_bounds(id: String, kind: String, projection: RefCounted) -> Rect2:
	var record: Dictionary = records.get(kind + ":" + id, {})
	if record.is_empty() or not record.root.visible: return Rect2()
	var rect := Rect2()
	for index: int in range(8):
		var point: Vector3 = record.root.global_transform * AABB(record.bounds).get_endpoint(index)
		var screen: Vector2 = projection.world_to_screen_height(Vector2(point.x, point.z) / WORLD_SCALE, point.y)
		rect = Rect2(screen, Vector2.ZERO) if index == 0 else rect.expand(screen)
	return rect.grow(2.0)


func opaque_building_contains(id: String, ray_origin: Vector3, ray_direction: Vector3) -> bool:
	var record: Dictionary = records.get("building:" + id, {})
	if record.is_empty() or not record.root.visible: return false
	# Reuse generated opaque triangles, not a broad box across empty gateways.
	if not record.has("pick_mesh"):
		var faces := PackedVector3Array()
		var actor: Node3D = record.root
		for child: Node in actor.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			if mesh.mesh == null: continue
			var local := actor.global_transform.affine_inverse() * mesh.global_transform
			for vertex: Vector3 in mesh.mesh.get_faces(): faces.append(local * vertex)
		var triangles := TriangleMesh.new()
		if not triangles.create_from_faces(faces): return false
		record.pick_mesh = triangles
	var inverse: Transform3D = record.root.global_transform.affine_inverse()
	return not (record.pick_mesh as TriangleMesh).intersect_ray(inverse * ray_origin, (inverse.basis * ray_direction).normalized()).is_empty()


func get_diagnostics() -> Dictionary:
	return {"mode":"geometric-m77", "actors":records.size(), "created_total":_created, "tick":_tick, "physics_nodes":0, "model_source":"original procedural geometry", "coverage":"faction and role silhouettes; not bespoke 48-hero models"}
