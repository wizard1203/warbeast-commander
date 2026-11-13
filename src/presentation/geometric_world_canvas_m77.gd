extends "res://src/presentation/frontier3d_world_canvas.gd"
## Optional M77 geometry view, sharing the factual input/overlay contract.
## No simulation catalogs, prices, AI cadence or body collision are changed.
const GeometryActors = preload("res://src/presentation/geometric_actors_m77.gd")
const GeometryEnvironment = preload("res://src/presentation/geometric_environment_m77.gd")
const GeometryBuildings = preload("res://src/presentation/geometric_buildings_m77.gd")
const ActorVisibility = preload("res://src/presentation/heroic_actor_readout.gd")
var view_side_id := "PLAYER"
var interpolation_fraction_m76 := 1.0
var _plan_key_m77 := ""
var _observed_landscape_snapshot_m77: Dictionary = {}
## -1 preserves the original CLI behavior; an explicit menu choice wins.
var quality_override_m78 := -1


func _ready() -> void:
	low_effects_enabled = quality_override_m78 == 1 if quality_override_m78 >= 0 else "--geometric-low-effects" in OS.get_cmdline_user_args()
	super._ready()
	var world: Node3D = terrain3d.get_parent()
	world.remove_child(terrain3d)
	terrain3d.free()
	world.remove_child(actors3d)
	actors3d.free()
	terrain3d = GeometryEnvironment.new()
	terrain3d.name = "RetainedGeometricLandscape"
	world.add_child(terrain3d)
	actors3d = GeometryActors.new()
	actors3d.name = "RetainedGeometricActors"
	world.add_child(actors3d)
	for child: Node in world.get_children():
		if child is DirectionalLight3D:
			child.light_color = Color("fff0d8")
			child.light_energy = 1.10
			child.rotation_degrees = Vector3(-58, -35, 0)
			child.directional_shadow_max_distance = 100.0
			child.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		if child is WorldEnvironment:
			child.environment.background_color = Color("9eafa8")
			child.environment.ambient_light_color = Color("bdcbd0")
			child.environment.ambient_light_energy = 0.72
	viewport3d.name = "GeometricRTSViewport"


func _refresh_landscape() -> void:
	if snapshot.is_empty(): return
	if is_same(snapshot, _observed_landscape_snapshot_m77): return
	_observed_landscape_snapshot_m77 = snapshot
	var signature := LandscapePlan.signature(snapshot) + ":m77-whole-cell"
	if signature == _plan_key_m77: return
	_plan_key_m77 = signature
	landscape_plan = LandscapePlan.build(snapshot, "TILED")
	_landscape_rebuilds += 1
	set_meta("landscape_summary", {"signature":signature, "rebuilds":_landscape_rebuilds, "roads":landscape_plan.get("roads", []).size(), "decorations":landscape_plan.get("decorations", []).size(), "failures":landscape_plan.get("failures", [])})


func _process(delta: float) -> void:
	if actors3d != null: actors3d.view_side_id = view_side_id
	super._process(delta)


func _update_blueprint() -> void:
	if blueprint_type.is_empty():
		if is_instance_valid(_preview):
			_preview.queue_free()
			_preview = null
		return
	if is_instance_valid(_preview) and str(_preview.get_meta("type", "")) != blueprint_type:
		_preview.queue_free()
		_preview = null
	if not is_instance_valid(_preview):
		var faction := "HUMAN"
		for side: Dictionary in snapshot.get("match_config", {}).get("sides", []):
			if str(side.get("side_id", side.get("id", ""))) == view_side_id: faction = str(side.get("faction_id", "HUMAN"))
		_preview = GeometryBuildings.build({"building_type":blueprint_type, "faction_id":faction}, Palette.side_color(view_side_id))
		_preview.set_meta("type", blueprint_type)
		actors3d.add_child(_preview)
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.65, 0.85, 0.78, 0.35)
		for child: Node in _preview.find_children("*", "MeshInstance3D", true, false):
			child.material_override = material
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_preview.position = Projection3D.to_visual(blueprint_point)


func _draw() -> void:
	if camera == null or snapshot.is_empty(): return
	var tick := int(snapshot.get("tick", 0))
	var active := shows_transient_effects()
	for collection: String in ["workers", "soldiers"]:
		for unit: Dictionary in snapshot.get(collection, []):
			if not ActorVisibility.living(unit) or not ActorVisibility.visible_to(unit, view_side_id): continue
			var point := Vector2(unit.get("position", Vector2.ZERO))
			if not _visible(_screen(point), 100): continue
			var hero := str(unit.get("unit_type", "")) == "hero"
			var selected := str(unit.get("id", "")) in [selected_unit, selected_worker_id] or (not selected_army.is_empty() and str(unit.get("warband_id", "")) == selected_army)
			var color := Palette.side_color(str(unit.get("side", "")))
			var radius := maxf(float(unit.get("radius", 16)) + 10.0, 24.0)
			if hero:
				_ground_circle(point, radius, Color(color, 0.13), 7.0)
				_ground_circle(point, radius, Color(color, 0.75), 1.4)
			if selected: _ground_circle(point, radius + 4, Color("efdab0"), 2.0)
			if hero or selected or int(unit.get("hp", 0)) < int(unit.get("max_hp", 1)):
				var top := _height(point, 2.8 if hero else 2.15)
				var width := 54.0 if hero else 34.0
				_bar(top + Vector2(-width * 0.5, -13), width, float(unit.get("hp", 0)) / maxf(float(unit.get("max_hp", 1)), 1), color)
				if float(unit.get("max_mana", 0)) > 0:
					_bar(top + Vector2(-width * 0.5, -5), width, float(unit.get("mana", 0)) / float(unit.max_mana), Color("559ed7"))
			var pose := Pose.for_unit(unit, tick)
			if active and (str(pose.get("action", "")) == "ATTACK" or str(pose.get("action", "")).begins_with("SKILL_")): _action_feedback(unit, pose)
			if active and str(pose.get("action", "")) in ["HEAL", "POTION"]:
				var phase := float(pose.get("phase", 0))
				_ground_circle(point, 16 + phase * 17, Color(0.62, 0.88, 0.66, 1.0 - phase), 2)
			Pixel.draw_control_status(self, _height(point, 1.8), unit, float(camera.get_scale()))
			var injury: Dictionary = _hit_feedback.read(str(unit.get("id", "")), tick)
			if active and not injury.is_empty(): _draw_injury(_height(point, 1.2), 9, injury)
	for building: Dictionary in snapshot.get("buildings", []):
		if not ActorVisibility.living(building) or not ActorVisibility.visible_to(building, view_side_id): continue
		var point := Vector2(building.get("position", Vector2.ZERO))
		if not _visible(_screen(point), 220): continue
		var complete := bool(building.get("complete", false))
		var top := _height(point, 5.2 if str(building.get("building_type", "")) == "BASE" else 4.0)
		if not complete or int(building.get("hp", 0)) < int(building.get("max_hp", 1)) or str(building.get("id", "")) == selected_building_id:
			var ratio := float(building.get("hp", 0)) / maxf(float(building.get("max_hp", 1)), 1) if complete else float(building.get("progress", 0)) / maxf(float(building.get("max_progress", 1)), 1)
			_bar(top + Vector2(-32, -10), 64.0, ratio, Palette.side_color(str(building.get("side", ""))))
		if not building.get("queue", []).is_empty():
			var job: Dictionary = building.queue[0]
			_bar(top + Vector2(-32, -2), 64.0, float(job.get("progress", 0)) / maxf(float(job.get("max_progress", 1)), 1), Color("d8ba76"))
	for tower: Dictionary in get_tower_readouts():
		var building := _find(snapshot, str(tower.id), ["buildings"])
		if building.is_empty() or not ActorVisibility.visible_to(building, view_side_id): continue
		if bool(tower.get("selected", false)): _ground_circle(Vector2(building.position), float(tower.attack_range), Color("ebca83", 0.35))
		if active and bool(tower.get("firing", false)):
			var from := _height(Vector2(building.position), 3.8)
			var to := _height(Vector2(building.get("last_action_target_position", building.position)), 1.0)
			var phase := clampf(float(tower.get("age", 0)) / 7.0, 0.0, 1.0)
			var arrow := from.lerp(to, phase) + Vector2(0, -sin(phase * PI) * 16)
			draw_line(arrow - (to - from).normalized() * 11, arrow, Color("e6d2a4"), 2, true)
	_draw_sites()
	var intent := read_selected_intent(snapshot, selected_unit, selected_army)
	if not intent.is_empty():
		var from := _screen(intent.origin)
		var to := _screen(intent.target)
		var color := Color("e3b977") if str(intent.kind) == "ATTACK_MOVE" else Color("91c8bc")
		for index: int in range(20): draw_line(from.lerp(to, index / 20.0), from.lerp(to, (index + 0.5) / 20.0), Color(color, 0.45), 1.5, true)
		_ground_circle(Vector2(intent.target), 12, color)
	for mark: Dictionary in feedback_marks.slice(0, 16):
		if not _point(mark.get("position")): continue
		var fade := clampf(1.0 - float(mark.get("age", 0)) / maxf(float(mark.get("lifetime", 1)), 0.01), 0, 1)
		var point := Vector2(mark.position)
		_ground_circle(point, 13 + (1.0 - fade) * 15, Color("e8d29d", fade), 2)
		if mark.get("kind") != "SELECT": draw_string(ReadableFont.readable(), _screen(point) + Vector2(16, -12), str(mark.get("caption", "")), HORIZONTAL_ALIGNMENT_LEFT, 180, 13, Color("eadbb8", fade))
	var targeting := read_aim(snapshot, aim)
	if not targeting.is_empty():
		var color := Color("a0d4c9") if targeting.within_range else Color("e99a80")
		_ground_circle(Vector2(targeting.origin), float(targeting.range), Color(color, 0.3))
		if float(targeting.radius) > 0: _ground_circle(Vector2(targeting.target), float(targeting.radius), color, 2)
	if not blueprint_type.is_empty(): _ground_circle(blueprint_point, float(get_blueprint_observation().radius), Color("b5d6bf"), 2)
	# Resource markers communicate finite harvesting nodes, never new resource
	# ownership or extra pickups. Geometry remains the large primary cue.
	for source: Dictionary in snapshot.get("resource_sources", []):
		var selected := str(source.get("id", "")) == selected_site_id
		var point := Vector2(source.get("position", Vector2.ZERO))
		if selected and _visible(_screen(point), 100): _ground_circle(point, 53, Color("d5c090"), 1.6)


func _bar(point: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_style_box(_meter_background(), Rect2(point - Vector2(1, 1), Vector2(width + 2, 7)))
	var length := (width - 2.0) * clampf(ratio, 0.0, 1.0)
	if length > 0: draw_rect(Rect2(point + Vector2(1, 1), Vector2(length, 3)), color)


func _meter_background() -> StyleBoxFlat:
	# One resource, not one allocation per health bar per display frame.
	if not has_meta("m77_meter"):
		var style := StyleBoxFlat.new()
		style.bg_color = Color("1c2525")
		style.border_color = Color("667265")
		style.set_border_width_all(1)
		style.set_corner_radius_all(1)
		set_meta("m77_meter", style)
	return get_meta("m77_meter") as StyleBoxFlat


func _action_feedback(unit: Dictionary, pose: Dictionary) -> void:
	if not ActorVisibility.visible_to(unit, view_side_id): return
	var phase := clampf(float(pose.get("phase", 0)), 0.0, 1.0)
	var from := _height(Vector2(unit.get("position", Vector2.ZERO)), 1.35)
	var target := Vector2(pose.get("target_position", unit.get("position", Vector2.ZERO)))
	var to := _height(target, 1.0)
	var direction := (to - from).normalized()
	var magic := str(pose.get("action", "")).begins_with("SKILL_")
	var attack := str(unit.get("attack_type", "SLASH"))
	var colors := {"ARCANE":Color("83b8dc"), "PIERCE":Color("dcd3b6"), "GUNPOWDER":Color("eabf7b"), "CHAOS":Color("b498c7"), "IMPACT":Color("dec9a3")}
	var color: Color = colors.get(attack, Color("e4d7bc"))
	if magic:
		var skill: Dictionary = pose.get("skill", {})
		var kind := str(skill.get("kind", skill.get("effect", "DAMAGE")))
		if kind in ["HEAL", "RECOVER", "BUFF", "RALLY"]: color = Color("9bc991")
		var focus := from.lerp(to, minf(phase * 1.45, 1.0))
		for layer: int in range(3):
			var half := float(7 - layer * 2)
			var points := PackedVector2Array([focus + Vector2(0, -half), focus + Vector2(half * 0.6, 0), focus + Vector2(0, half), focus + Vector2(-half * 0.6, 0)])
			draw_colored_polygon(points, Color(color.lightened(layer * 0.12), (1.0 - phase) * (0.5 + layer * 0.2)))
		if phase > 0.45:
			for index: int in range(8):
				var radial := Vector2.from_angle(index * TAU / 8.0 + phase) * (8.0 + phase * 24.0)
				draw_line(to + radial * 0.45, to + radial, Color(color, 1.0 - phase), 1.5, true)
	elif float(unit.get("attack_range", 0)) > 100.0:
		var projectile := from.lerp(to, phase) + Vector2(0, -sin(phase * PI) * (0 if attack == "GUNPOWDER" else 16))
		draw_line(projectile - direction * 13.0, projectile, color, 2.0, true)
		if attack == "GUNPOWDER" and phase < 0.25:
			for index: int in range(4):
				var spread := direction.rotated((index - 1.5) * 0.20)
				draw_line(from + spread * 10, from + spread * (18.0 + index * 2), Color("f3db9c", 1.0 - phase * 3.0), 2, true)
	else:
		var angle := direction.angle()
		var center := from + direction * 13.0
		if phase < 0.8:
			for index: int in range(3):
				draw_arc(center, 15.0 + index * 2.5, angle - 1.3 + phase * 2.6, angle - 0.4 + phase * 2.6, 12, Color(color, (1.0 - phase) * (0.6 - index * 0.13)), 2.0, true)


func get_diagnostics() -> Dictionary:
	var result := super.get_diagnostics()
	result["mode"] = "geometric-m77"
	result["coverage"] = "six faction role models; hero-specific bespoke models and complete 144-skill 3D VFX remain future work"
	return result
