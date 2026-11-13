extends Node2D
## Detached-snapshot drawing only. These original world silhouettes and brief
## action trails are not collision, targeting, capture or damage authority.

const Terrain = preload("res://src/presentation/pixel_battle_renderer.gd")
const Pixel = preload("res://src/presentation/strategic_pixel_renderer.gd")
const Pose = preload("res://src/presentation/strategic_action_pose.gd")
const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const Capture = preload("res://src/presentation/strategic_capture_readout.gd")
const FieldObjectives = preload("res://src/presentation/strategic_field_objective_readout.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const HitFeedback = preload("res://src/presentation/strategic_hit_feedback.gd")
const MaterialEffects = preload("res://src/presentation/strategic_material_effects.gd")
const LandscapePlan = preload("res://src/presentation/strategic_landscape_plan.gd")
const PrerenderedArt = preload("res://src/presentation/strategic_prerendered_art.gd")
const FrontierArt = preload("res://src/presentation/strategic_frontier_art.gd")
const FrontierCollection = preload("res://src/presentation/strategic_frontier_collection.gd")
const FrontierScenery = preload("res://src/presentation/strategic_frontier_scenery.gd")
const MAX_OCCLUSION_HINTS := 8
var _hit_feedback := HitFeedback.new()
var landscape_plan: Dictionary = {}
var _landscape_signature := ""
var _landscape_rebuilds := 0
var presentation_seed_override := -1:
	set(value):
		if presentation_seed_override == value: return
		presentation_seed_override = value
		_refresh_landscape()
var snapshot: Dictionary = {}:
	set(value):
		snapshot = value
		_hit_feedback.observe(value)
		_refresh_landscape()
var camera: RefCounted
var selected_army := ""
var selected_unit := ""
var selected_worker_id := ""
var selected_site_id := ""
var selected_building_id := ""
var feedback_marks: Array = []
var field_reward_marks: Array = []
var aim: Dictionary = {}
var blueprint_type := ""
var blueprint_point := Vector2.ZERO


func _refresh_landscape() -> void:
	var next_signature := FrontierScenery.signature(snapshot,presentation_seed_override) if not snapshot.is_empty() else ""
	if next_signature == _landscape_signature: return
	_landscape_signature = next_signature
	landscape_plan = FrontierScenery.build(snapshot,presentation_seed_override) if not snapshot.is_empty() else {}
	_landscape_rebuilds += 1
	set_meta("landscape_summary",{"signature":_landscape_signature,"rebuilds":_landscape_rebuilds,"roads":landscape_plan.get("roads",[]).size(),"decorations":landscape_plan.get("decorations",[]).size(),"collection":landscape_plan.get("collection_summary",{}).duplicate(true),"failures":landscape_plan.get("failures",[]).duplicate(true)})


func _screen(point: Vector2) -> Vector2:
	return camera.world_to_screen(point) - (get_parent() as Control).position


func _visible(center: Vector2, margin: float) -> bool:
	return Rect2(Vector2.ZERO, (get_parent() as Control).size).grow(margin).has_point(center)


static func unit_cull_margin(unit: Dictionary, scale_factor: float) -> float:
	# Include the enlarged source art, not only the old physical-foot margin.
	# The same 3px display floor is used below when the camera is far away.
	var radius := maxf(float(unit.get("visual_radius",unit.get("radius", 12))) * scale_factor, 3)
	var bounds := Pixel.unit_visual_bounds(unit, radius)
	var extent := maxf(maxf(absf(bounds.position.x), absf(bounds.end.x)), maxf(absf(bounds.position.y), absf(bounds.end.y)))
	return maxf(120 * scale_factor, extent + 12)


static func building_cull_margin(building: Dictionary, scale_factor: float) -> float:
	var bounds := Pixel.building_visual_bounds(building,scale_factor)
	var extent := maxf(maxf(absf(bounds.position.x),absf(bounds.end.x)),maxf(absf(bounds.position.y),absf(bounds.end.y)))
	return maxf(120*scale_factor,extent+12)


static func terrain_cull_margin(terrain: Dictionary, scale_factor: float) -> float:
	var legacy := 120 * scale_factor
	if terrain.get("kind") not in ["TREE","MOUNTAIN"]: return legacy
	var radius := float(terrain.get("radius",40))
	if not is_finite(radius) or radius <= 0: return legacy
	var entry_id := "tree_oak" if terrain.get("kind") == "TREE" else "rock"
	var bounds := FrontierCollection.bounds(Pixel.frontier_terrain_entry(terrain),radius/40.0*scale_factor)
	if bounds.size == Vector2.ZERO: bounds = FrontierArt.prop_bounds(Pixel.frontier_terrain_entry(terrain),radius/40.0*scale_factor)
	if bounds.size == Vector2.ZERO: bounds = PrerenderedArt.prop_bounds(entry_id,radius/40.0*scale_factor)
	if bounds.size == Vector2.ZERO: return legacy
	var extent := maxf(maxf(absf(bounds.position.x),absf(bounds.end.x)),maxf(absf(bounds.position.y),absf(bounds.end.y)))
	return maxf(legacy,extent+2)


static func resource_cull_margin(source: Dictionary, scale_factor: float) -> float:
	var entry_id := Pixel.frontier_resource_entry(source)
	return _frontier_prop_cull_margin(entry_id,scale_factor,70 * scale_factor)


static func site_cull_margin(site: Dictionary, scale_factor: float) -> float:
	var entry_id := Pixel.frontier_site_entry(site)
	return _frontier_prop_cull_margin(entry_id,scale_factor,90 * scale_factor)


static func _frontier_prop_cull_margin(entry_id: String, scale_factor: float, legacy: float) -> float:
	if entry_id.is_empty(): return legacy
	var bounds := FrontierArt.prop_bounds(entry_id,scale_factor)
	if bounds.size == Vector2.ZERO: return legacy
	var extent := maxf(maxf(absf(bounds.position.x),absf(bounds.end.x)),maxf(absf(bounds.position.y),absf(bounds.end.y)))
	return maxf(legacy,extent+2)


func get_blueprint_observation() -> Dictionary:
	if blueprint_type.is_empty():return {}
	var faction := "HUMAN"
	for side: Dictionary in snapshot.get("match_config",{}).get("sides",[]):
		if side.get("side_id")=="PLAYER":faction=str(side.get("faction_id","HUMAN"))
	var radius := int(snapshot.get("catalog",{}).get("buildings",{}).get(blueprint_type,{}).get("radius",40 if blueprint_type=="BASE" else 24 if blueprint_type=="TOWER" else 32))
	return {"building_type":blueprint_type,"radius":radius,"side":"PLAYER","faction_id":faction,"hp":1,"complete":false,"state":"BLUEPRINT","progress":0,"max_progress":100,"base_tier":1}


func shows_transient_effects() -> bool:
	# Authority freezes its tick at match end. Retire temporary attack/level
	# cues instead of holding their last animation frame forever. Inspection,
	# selection, bodies, HP and tower range remain factual and visible.
	return snapshot.get("outcome", "ONGOING") == "ONGOING"


func _draw() -> void:
	set_meta("occlusion_readouts",[])
	if camera == null or snapshot.is_empty(): return
	var projected: Rect2 = camera.get_projected_world_rect()
	projected.position -= (get_parent() as Control).position
	Terrain.draw_terrain(self, projected)
	var scale_factor := float(camera.get_scale())
	var match_config: Dictionary = snapshot.get("match_config", {})
	var viewport := Rect2(Vector2.ZERO, (get_parent() as Control).size)
	Pixel.draw_ground_theme(self, projected, viewport, str(match_config.get("map_id", "borderlands")), scale_factor,landscape_plan)
	for side: Dictionary in match_config.get("sides", []):
		var home := _screen(Vector2(side.get("home", Vector2.ZERO)))
		if _visible(home,220*scale_factor): Pixel.draw_home_material(self,home,str(side.get("faction_id","HUMAN")),scale_factor)
	Pixel.draw_water_union(self,projected,viewport,snapshot.get("terrain",[]),scale_factor,Rect2(match_config.get("bounds",Rect2i())))
	for terrain: Dictionary in snapshot.get("terrain", []):
		if terrain.get("kind") in ["LAKE","RIVER"]:continue
		var center := _screen(Vector2(terrain.get("position", Vector2.ZERO)))
		if _visible(center, float(terrain.get("radius", 40)) * scale_factor + 40):
			# The ground contact uses the same detached authored appearance as
			# the later depth-sorted body, never a generic obstacle floor plate.
			Pixel.draw_terrain_ground(self,center,FrontierScenery.terrain_observation(terrain,landscape_plan),scale_factor)
	var tick := int(snapshot.get("tick", 0))
	var transient_effects := shows_transient_effects()
	var tower_readouts := get_tower_readouts()
	set_meta("tower_readouts", tower_readouts.duplicate(true))
	for readout: Dictionary in tower_readouts:
		if readout.selected:
			draw_arc(readout.center, float(readout.screen_range), 0, TAU, 64, Color(0.86, 0.75, 0.48, 0.55), 2)
			draw_string(ReadableFont.readable(), readout.center + Vector2(18, 32), "自动防御 · 射程%d" % int(readout.attack_range), HORIZONTAL_ALIGNMENT_LEFT, 190, 14, Color("efdd9d"))
	# Exactly supplied real source positions, not four decorative rocks near an
	# unrelated capture marker. A neutral/inactive mine is visibly present but
	# darkened; it does not invent accessible stock or a new obstacle.
	for source: Dictionary in snapshot.get("resource_sources", []):
		if not Pixel.frontier_resource_entry(source).is_empty(): continue
		var center := _screen(Vector2(source.get("position", Vector2i.ZERO)))
		if _visible(center, 70 * scale_factor): Pixel.draw_resource_source(self, center, source, scale_factor)
	var capture_readouts := get_capture_readouts()
	var capture_overlays: Array[Dictionary] = []
	# Metadata is a detached record of the actual draw route, not a simulated
	# completion. Test/UI inspection can distinguish projection from settlement.
	set_meta("capture_readouts", capture_readouts.duplicate(true))
	for readout: Dictionary in capture_readouts:
		var center: Vector2 = readout.screen_center
		if readout.show_range:
			var range_color := _capture_color(str(readout.leader if readout.running else readout.owner))
			draw_arc(center, float(readout.range_radius), 0, TAU, 64, Color(range_color,0.38),1.5)
			for angle: float in [0.0,PI * 0.5,PI,PI * 1.5]:
				var radial := Vector2.from_angle(angle)
				draw_line(center + radial * (float(readout.range_radius) - 3),center + radial * (float(readout.range_radius) + 3),Color(range_color,0.75),2)
		var actual: Dictionary = {}
		for site: Dictionary in snapshot.get("sites", []):
			if str(site.get("id", "")) == str(readout.id): actual = site
		if Pixel.frontier_site_entry(actual).is_empty(): Pixel.draw_site(self, center, actual, scale_factor)
		if FrontierArt.enabled(): capture_overlays.append(readout)
		else: _draw_capture_status(readout)
	# Physical footpoint ordering lets people walk visibly in front of or behind
	# a substantial building. No depth sorting changes its actual circle body.
	var objects: Array[Dictionary] = []
	for building: Dictionary in snapshot.get("buildings", []): objects.append({"kind": "BUILDING", "value": building})
	for terrain: Dictionary in snapshot.get("terrain", []):
		if terrain.get("kind") not in ["LAKE", "RIVER"]: objects.append({"kind":"TERRAIN", "value":terrain})
	for worker: Dictionary in snapshot.get("workers", []): objects.append({"kind": "UNIT", "value": worker})
	for soldier: Dictionary in snapshot.get("soldiers", []): objects.append({"kind": "UNIT", "value": soldier})
	for source: Dictionary in snapshot.get("resource_sources", []):
		if not Pixel.frontier_resource_entry(source).is_empty(): objects.append({"kind":"RESOURCE", "value":source})
	for site: Dictionary in snapshot.get("sites", []):
		if not Pixel.frontier_site_entry(site).is_empty(): objects.append({"kind":"SITE", "value":site})
	objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_position: Vector2 = Vector2(a["value"].get("position", Vector2i.ZERO))
		var b_position: Vector2 = Vector2(b["value"].get("position", Vector2i.ZERO))
		return a_position.y < b_position.y if a_position.y != b_position.y else str(a["value"].get("id", "")) < str(b["value"].get("id", "")))
	for object: Dictionary in objects:
		var value: Dictionary = object["value"]
		var center := _screen(Vector2(value.get("position", Vector2i.ZERO)))
		var themed_terrain := value
		if object["kind"] == "TERRAIN":
			# Detached palette only; the same observation selects the tree shape
			# for both culling and drawing, including highland pine variants.
			themed_terrain = value.duplicate(false)
			themed_terrain.faction_id = Pixel.homeland_faction_at(Vector2(value.get("position",Vector2i.ZERO)),landscape_plan)
			themed_terrain = FrontierScenery.terrain_observation(themed_terrain,landscape_plan)
		var margin := unit_cull_margin(value, scale_factor) if object["kind"] == "UNIT" else 120 * scale_factor
		if object["kind"]=="BUILDING":margin=building_cull_margin(value,scale_factor)
		elif object["kind"]=="TERRAIN":margin=terrain_cull_margin(themed_terrain,scale_factor)
		elif object["kind"]=="RESOURCE":margin=resource_cull_margin(value,scale_factor)
		elif object["kind"]=="SITE":margin=site_cull_margin(value,scale_factor)
		if not _visible(center, margin): continue
		if object["kind"] == "TERRAIN":
			# Only the detached draw observation receives a cultural palette.
			# Positions, aggregate shape and navigation circles remain factual.
			Pixel.draw_terrain_prop(self, center, themed_terrain, scale_factor)
		elif object["kind"] == "RESOURCE":
			Pixel.draw_resource_source(self,center,value,scale_factor)
		elif object["kind"] == "SITE":
			Pixel.draw_site(self,center,value,scale_factor)
		elif object["kind"] == "BUILDING":
			Pixel.draw_building(self, center, value, scale_factor)
			if int(value.get("hp", 0)) <= 0: continue
			var radius := maxf(float(value.get("radius", 24)) * scale_factor, 13)
			var complete := bool(value.get("complete", false))
			var ratio := float(value.get("hp", 0)) / maxf(float(value.get("max_hp", 1)), 1) if complete else float(value.get("progress", 0)) / maxf(float(value.get("max_progress", 100)), 1)
			if not complete or ratio < 1.0: _bar(center + Vector2(-radius, radius * 0.62 + 5), radius * 2, ratio, Color("8bc2b3"))
			if complete and value.get("building_type") == "BASE":
				var roof_top := Pixel.building_visual_bounds(value,scale_factor).position.y
				draw_string(ReadableFont.readable(), center + Vector2(-20, roof_top - 6), "%d级" % int(value.get("base_tier", 1)), HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color("e1d2a1"))
				var upgrading: Dictionary = value.get("base_upgrade", {})
				if not upgrading.is_empty(): _bar(center + Vector2(-radius, radius * 0.62 + 17), radius * 2, float(upgrading.get("progress", 0)) / maxf(float(upgrading.get("max_progress", 1)), 1), Color("76b1e0"))
			if not value.get("queue", []).is_empty():
				var entry: Dictionary = value["queue"][0]
				_bar(center + Vector2(-radius, radius * 0.62 + 11), radius * 2, float(entry.get("progress", 0)) / maxf(float(entry.get("max_progress", 1)), 1), Color("e0c879"))
		else:
			var radius := maxf(float(value.get("visual_radius",value.get("radius", 12))) * scale_factor, 3)
			var pose := Pose.for_unit(value, tick)
			var alive := int(value.get("hp", 0)) > 0
			var military: bool = value.get("unit_type") != "worker"
			if alive and ((not military and str(value.get("id")) == selected_worker_id) or (military and (str(value.get("id")) == selected_unit or (not selected_army.is_empty() and str(value.get("warband_id")) == selected_army)))):
				draw_arc(center, radius + 7, 0, TAU, 20, Color("e2cf79"), 2)
			var visual := value
			if not value.has("faction_id"):
				visual = value.duplicate(true)
				for side: Dictionary in match_config.get("sides", []):
					if side.get("side_id") == value.get("side"): visual["faction_id"] = side.get("faction_id", "HUMAN")
			Pixel.draw_unit(self, center, visual, radius, pose)
			var injury: Dictionary = _hit_feedback.read(str(value.get("id","")),tick)
			if transient_effects and not injury.is_empty(): _draw_injury(center,radius,injury)
			if not military:
				var hit := read_worker_hit(value,tick)
				if transient_effects and not hit.is_empty():
					var hit_age: int = hit.age
					var fade: float = hit.fade
					draw_string(ReadableFont.readable(), center + Vector2(-10, -29 - hit_age), "-%d" % int(hit.amount), HORIZONTAL_ALIGNMENT_LEFT, 70, 15, Color(1.0, 0.7, 0.55, fade))
			Pixel.draw_control_status(self, center, value, scale_factor)
			var statuses: Array = value.get("status_effects", [])
			if alive and not statuses.is_empty():
				var seconds := 0.0
				for status: Dictionary in statuses: seconds = maxf(seconds, float(status.get("remaining_ticks", 0)) / 20.0)
				if seconds > 0: draw_string(ReadableFont.readable(), center + Vector2(12, -32) * scale_factor, "%.1fs" % seconds, HORIZONTAL_ALIGNMENT_LEFT, 50, 12, Color("f0dbb1"))
			if alive and int(value.get("hp", 0)) < int(value.get("max_hp", 1)):
				var visible_top := Pixel.unit_visual_bounds(visual,radius).position.y
				_bar(center + Vector2(-radius,visible_top-8),radius*2,float(value.get("hp",0))/maxf(float(value.get("max_hp",1)),1),Palette.side_color(str(value.get("side",""))))
	_draw_occlusion_hints()
	for soldier: Dictionary in snapshot.get("soldiers", []):
		var pose := Pose.for_unit(soldier, tick)
		var center := _screen(Vector2(soldier.get("position", Vector2i.ZERO)))
		var target := _screen(Vector2(pose["target_position"]))
		if transient_effects and (_visible(center, 240 * scale_factor) or _visible(target, 200 * scale_factor)): Pixel.draw_action_effect(self, center, target, soldier, pose, scale_factor)
	for hero: Dictionary in snapshot.get("heroes", {}).get("officers", []):
		var center := _screen(Vector2(hero.get("position", Vector2i.ZERO)))
		var age := tick - int(hero.get("last_level_up_tick", -1000000))
		if transient_effects and int(hero.get("hp", 0)) > 0 and age >= 0 and age < 25 and _visible(center, 60):
			var fade := 1.0 - float(age) / 25.0
			draw_arc(center, (20 + age) * scale_factor, 0, TAU, 28, Color(0.88, 0.8, 0.4, fade), 2)
			draw_string(ReadableFont.readable(), center + Vector2(-30, -45 - age), "升级 +1点", HORIZONTAL_ALIGNMENT_LEFT, 130, 16, Color(0.95, 0.85, 0.56, fade))
	for readout: Dictionary in tower_readouts:
		if not readout.firing: continue
		MaterialEffects.draw_tower_shot(self,readout.center+Vector2(0,-35)*scale_factor,readout.target,int(readout.age),scale_factor,Color("efdba6"))
	for army: Dictionary in snapshot.get("warbands", []):
		if bool(army.get("reserve", false)): continue
		var center := _screen(Vector2(army.get("anchor", Vector2.ZERO)))
		draw_string(ReadableFont.readable(), center + Vector2(-8, -30 * scale_factor), str(army.get("number", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.side_color(str(army.get("side", ""))))
	var intent := read_selected_intent(snapshot, selected_unit, selected_army)
	if not intent.is_empty():
		var from := _screen(intent["origin"])
		var to := _screen(intent["target"])
		var color := Color("eec46f") if intent["kind"] == "ATTACK_MOVE" else Color("ef9b82") if intent["kind"] == "ATTACK" else Color("8ccfbf")
		var count := clampi(int(from.distance_to(to) / 16), 1, 80)
		for index: int in range(count):
			draw_line(from.lerp(to, float(index) / count), from.lerp(to, (float(index) + 0.45) / count), Color(color, 0.48), 1.5)
		Pixel.draw_feedback_mark(self, to, {"kind": intent["kind"], "age": 0.0, "lifetime": 1.0}, 0.66)
		if _visible(to, 40): draw_string(ReadableFont.readable(), to + Vector2(15, 18), "方向提示", HORIZONTAL_ALIGNMENT_LEFT, 90, 12, color)
	for value: Variant in feedback_marks.slice(0, 16):
		if not value is Dictionary: continue
		var mark: Dictionary = value
		var location: Variant = mark.get("position")
		if mark.get("kind") == "SELECT":
			var selected := _find(snapshot, str(mark.get("subject_id", "")), ["workers", "soldiers", "warbands"])
			if selected.is_empty() or not _living(selected): continue
			location = selected.get("position", selected.get("anchor"))
		if not _point(location): continue
		var point := _screen(Vector2(location))
		if not _visible(point, 80): continue
		Pixel.draw_feedback_mark(self, point, mark)
		var fade := clampf(1.0 - float(mark.get("age", 0)) / maxf(float(mark.get("lifetime", 1)), 0.01), 0, 1)
		var color := Color("ed987b") if mark.get("kind") == "REJECT" else Color("ecd796")
		draw_string(ReadableFont.readable(), point + Vector2(15, 32), str(mark.get("caption", "")), HORIZONTAL_ALIGNMENT_LEFT, 140, 14, Color(color, fade))
	var preview := read_aim(snapshot, aim)
	if not preview.is_empty():
		var origin := _screen(preview["origin"])
		var target := _screen(preview["target"])
		var color := Color("9fd9d0") if preview["within_range"] else Color("e99576")
		if float(preview["range"]) > 0: draw_arc(origin, float(preview["range"]) * scale_factor, 0, TAU, 64, Color(color, 0.3), 1.5)
		if float(preview["radius"]) > 0: draw_arc(target, float(preview["radius"]) * scale_factor, 0, TAU, 48, Color(color, 0.85), 2)
		draw_line(origin, target, Color(color, 0.35), 1)
		Pixel.draw_feedback_mark(self, target, {"kind": "CAST", "age": 0.0, "lifetime": 1.0}, 0.6)
		draw_string(ReadableFont.readable(), target + Vector2(14, -14), str(preview["name"]) if preview["within_range"] else "超出施法距离", HORIZONTAL_ALIGNMENT_LEFT, 160, 14, color)
	if not blueprint_type.is_empty():
		var point := _screen(blueprint_point)
		var observation := get_blueprint_observation()
		var radius := int(observation.radius)
		set_meta("blueprint_radius", radius)
		# Scaffold ghost is presentation only, never a pre-placed obstacle.
		Pixel.draw_building(self, point, observation, scale_factor)
		draw_arc(point, radius * scale_factor + 4, 0, TAU, 24, Color("8bd5c3"), 2)
	# Frontier tall scenery never buries factual points, timers or capture
	# flags. The normal/M27 path retains its established earlier draw order.
	for readout: Dictionary in capture_overlays: _draw_capture_status(readout)
	var objective_marks: Array[Dictionary] = []
	for readout: Dictionary in capture_readouts:
		var objective: Dictionary = readout.get("field_objective", {})
		if objective.is_empty(): continue
		var compact := bool(readout.get("compact", false))
		var card: Rect2 = readout.card_rect
		var marker := Vector2(card.end.x + (9 if compact else 15), card.get_center().y)
		marker.x = clampf(marker.x, 15, (get_parent() as Control).size.x - 15)
		FieldObjectives.draw_marker(self, marker, objective, compact)
		objective_marks.append({"site_id":str(readout.id),"kind":str(objective.kind),"state":str(objective.state),"position":marker})
	set_meta("field_objective_marks", objective_marks)
	for mark: Dictionary in field_reward_marks.slice(0, 4):
		var age := float(mark.get("age", 0))
		var lifetime := float(mark.get("lifetime", 2.0))
		if age < 0 or age >= lifetime: continue
		var center := _screen(Vector2(mark.get("position", Vector2.ZERO)))
		if not _visible(center, 100): continue
		var fade := 1.0 - age/lifetime
		draw_arc(center, 32 + age * 25, 0, TAU, 40, Color("e5cf87", fade * 0.85), 2)
		Icons.draw_symbol(self, str(mark.get("icon", "hero")), center + Vector2(0, -55-age*12), Color("e1c57f",fade), 0.65)
		draw_string(ReadableFont.readable(), center + Vector2(-110,-78-age*12), str(mark.get("caption", "探索奖励已结算")), HORIZONTAL_ALIGNMENT_CENTER, 220, 15, Color("f0e0ad",fade))


func get_occlusion_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FrontierArt.enabled() or camera == null or snapshot.is_empty() or not get_parent() is Control: return result
	var tick := int(snapshot.get("tick",0))
	var scale_factor := float(camera.get_scale())
	var candidates: Array[Dictionary] = []
	for collection: String in ["workers","soldiers"]:
		for unit: Dictionary in snapshot.get(collection,[]):
			if unit.get("side") != "PLAYER" or int(unit.get("hp",0)) <= 0 or not bool(unit.get("alive",true)): continue
			var pose := Pose.for_unit(unit,tick)
			var direct := str(unit.get("id","")) == selected_unit or str(unit.get("id","")) == selected_worker_id
			var army := not selected_army.is_empty() and str(unit.get("warband_id","")) == selected_army
			if not direct and not army and pose.get("action") != "MINE": continue
			var visual := _frontier_unit_observation(unit)
			if not bool(FrontierArt.inspect_unit(visual,pose).get("supported",false)): continue
			var center := _screen(Vector2(unit.get("position",Vector2.ZERO)))
			if not _visible(center,unit_cull_margin(visual,scale_factor)): continue
			candidates.append({"unit":visual,"pose":pose,"priority":0 if direct else 1 if army else 2})
	candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return str(a.unit.get("id","")) < str(b.unit.get("id","")) if int(a.priority) == int(b.priority) else int(a.priority) < int(b.priority))
	var blockers := _frontier_occluders(scale_factor)
	# This is a bounded inspection aid, not a second all-unit render pass.
	for candidate: Dictionary in candidates.slice(0,32):
		if result.size() >= MAX_OCCLUSION_HINTS: break
		var unit: Dictionary = candidate.unit
		var pose: Dictionary = candidate.pose
		var unit_position := Vector2(unit.get("position",Vector2.ZERO))
		var center := _screen(unit_position)
		var radius := maxf(float(unit.get("visual_radius",unit.get("radius",12)))*scale_factor,3)
		var local_bounds := FrontierArt.unit_bounds(unit,radius)
		var screen_bounds := Rect2(center+local_bounds.position,local_bounds.size)
		var probes: Array[Vector2] = []
		var probes_computed := false
		for blocker: Dictionary in blockers:
			var other: Dictionary = blocker.value
			var other_position := Vector2(other.get("position",Vector2.ZERO))
			# Match the established physical-foot Y/id sort, never move a unit
			# to the foreground or treat a behind-body as an occluder.
			if other_position.y < unit_position.y or (other_position.y == unit_position.y and str(other.get("id","")) <= str(unit.get("id",""))): continue
			# Most world objects never overlap this body. Reject their cached
			# screen rectangles before any alpha probes or per-pixel inspection.
			if not screen_bounds.intersects(Rect2(blocker.screen_bounds)): continue
			if not probes_computed:
				probes = FrontierArt.unit_opaque_probes(unit,radius,pose)
				probes_computed = true
				if probes.size() < 2: break
			var blocker_center: Vector2 = blocker.screen_center
			var hidden := 0
			for probe: Vector2 in probes:
				var offset := center + probe - blocker_center
				if _frontier_occluder_contains(blocker,offset,scale_factor): hidden += 1
			if hidden < maxi(2,ceili(float(probes.size())*0.35)): continue
			result.append({"id":str(unit.get("id","")),"action":str(pose.get("action","IDLE")),
				"actualpose":pose.duplicate(true),"occludingid":str(other.get("id","")),"occluding_kind":str(blocker.kind),
				"screen_center":center,"radius":radius,"hidden_probes":hidden,"body_probes":probes.size()})
			break
	return result


func _frontier_unit_observation(unit: Dictionary) -> Dictionary:
	if unit.has("faction_id"): return unit
	var visual := unit.duplicate(false)
	for side: Dictionary in snapshot.get("match_config",{}).get("sides",[]):
		if side.get("side_id") == unit.get("side"): visual.faction_id = str(side.get("faction_id","HUMAN"))
	return visual


func _frontier_occluders(scale_factor: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for building: Dictionary in snapshot.get("buildings",[]):
		if bool(FrontierArt.inspect("building",building).get("supported",false)):
			result.append({"kind":"BUILDING","value":building,"entry":""})
	for source: Dictionary in snapshot.get("resource_sources",[]):
		var entry := Pixel.frontier_resource_entry(source)
		if not entry.is_empty(): result.append({"kind":"RESOURCE","value":source,"entry":entry})
	for site: Dictionary in snapshot.get("sites",[]):
		var entry := Pixel.frontier_site_entry(site)
		if not entry.is_empty(): result.append({"kind":"SITE","value":site,"entry":entry})
	for terrain: Dictionary in snapshot.get("terrain",[]):
		if terrain.get("kind") not in ["TREE","MOUNTAIN"]: continue
		var themed := terrain.duplicate(false)
		themed.faction_id = Pixel.homeland_faction_at(Vector2(terrain.get("position",Vector2.ZERO)),landscape_plan)
		themed = FrontierScenery.terrain_observation(themed,landscape_plan)
		var entry := Pixel.frontier_terrain_entry(themed)
		if bool(FrontierCollection.get_entry(entry).get("supported",false)) or bool(FrontierArt.inspect("prop",entry).get("supported",false)):
			result.append({"kind":"TERRAIN","value":themed,"entry":entry})
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var ap := Vector2(a.value.get("position",Vector2.ZERO))
		var bp := Vector2(b.value.get("position",Vector2.ZERO))
		return str(a.value.get("id","")) > str(b.value.get("id","")) if ap.y == bp.y else ap.y > bp.y)
	# Offscreen bodies cannot hide an onscreen probe unless their own actual
	# bounds reach the viewport; keep the same conservative cull contract.
	var visible_blockers: Array[Dictionary] = []
	for blocker: Dictionary in result:
		var value: Dictionary = blocker.value
		var margin := building_cull_margin(value,scale_factor) if blocker.kind == "BUILDING" else resource_cull_margin(value,scale_factor) if blocker.kind == "RESOURCE" else site_cull_margin(value,scale_factor) if blocker.kind == "SITE" else terrain_cull_margin(value,scale_factor)
		var center := _screen(Vector2(value.get("position",Vector2.ZERO)))
		if not _visible(center,margin): continue
		var local_bounds: Rect2
		if blocker.kind == "BUILDING": local_bounds = FrontierArt.building_bounds(value,scale_factor)
		else:
			var prop_scale := scale_factor * float(value.get("radius",40))/40.0 if blocker.kind == "TERRAIN" else scale_factor
			local_bounds = FrontierCollection.bounds(str(blocker.entry),prop_scale)
			if local_bounds.size == Vector2.ZERO: local_bounds = FrontierArt.prop_bounds(str(blocker.entry),prop_scale)
		if local_bounds.size == Vector2.ZERO: continue
		blocker["screen_center"] = center
		blocker["screen_bounds"] = Rect2(center+local_bounds.position,local_bounds.size)
		visible_blockers.append(blocker)
	return visible_blockers


static func _frontier_occluder_contains(blocker: Dictionary, offset: Vector2, scale_factor: float) -> bool:
	var value: Dictionary = blocker.value
	if blocker.kind == "BUILDING": return FrontierArt.building_body_contains(value,offset,scale_factor)
	var prop_scale := scale_factor * float(value.get("radius",40))/40.0 if blocker.kind == "TERRAIN" else scale_factor
	if FrontierCollection.get_entry(str(blocker.entry)).get("supported",false): return FrontierCollection.body_contains(str(blocker.entry),offset,prop_scale)
	return FrontierArt.prop_body_contains(str(blocker.entry),offset,prop_scale)


func _draw_occlusion_hints() -> void:
	var drawn: Array[Dictionary] = []
	for readout: Dictionary in get_occlusion_readouts():
		var unit := _find(snapshot,str(readout.id),["workers","soldiers"])
		if unit.is_empty(): continue
		var center: Vector2 = readout.screen_center
		if not FrontierArt.draw_occluded_unit(self,center,_frontier_unit_observation(unit),float(readout.radius),readout.actualpose): continue
		if readout.action == "MINE":
			# A tiny factual pickaxe badge makes genuine work visible through a
			# wall without inventing a mining action for idle/travelling workers.
			var badge := center + Vector2(10,-22)
			draw_rect(Rect2(badge-Vector2(8,8),Vector2(16,16)),Color("172b2c",0.7))
			draw_line(badge+Vector2(-4,5),badge+Vector2(3,-4),Color("b78d5b",0.9),2)
			draw_line(badge+Vector2(-4,-4),badge+Vector2(5,-2),Color("a5d2d6",0.95),2)
		drawn.append(readout)
	set_meta("occlusion_readouts",drawn.duplicate(true))


func _draw_injury(center: Vector2, radius: float, hit: Dictionary) -> void:
	# Small local chips, not a full-body recolor or a fictional impact ring.
	var phase := float(hit.phase)
	var fade := float(hit.fade)
	var pixel := maxf(radius/8.0,0.7)
	var contact := center+Vector2(0,-radius*0.8)
	if int(hit.age) < 2:
		draw_rect(Rect2(contact+Vector2(-4,-3)*pixel,Vector2(2,4)*pixel),Color(0.94,0.9,0.76,fade*0.8))
	for index: int in range(3):
		var direction := Vector2.from_angle(-2.4+index*1.8)
		var point := contact+direction*(3+phase*9)*pixel
		draw_rect(Rect2(point.round(),Vector2(2,1)*pixel),Color(0.84,0.6,0.4,fade))


func get_tower_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if camera == null or snapshot.is_empty() or not get_parent() is Control: return result
	var scale_factor := float(camera.get_scale())
	var tick := int(snapshot.get("tick", 0))
	for tower: Dictionary in snapshot.get("buildings", []):
		if tower.get("building_type") != "TOWER" or int(tower.get("hp", 0)) <= 0 or not bool(tower.get("complete", false)): continue
		var center := _screen(Vector2(tower.position))
		var target := _screen(Vector2(tower.get("last_action_target_position", tower.position)))
		var age := tick - int(tower.get("last_action_tick", -1000000))
		var firing: bool = shows_transient_effects() and snapshot.get("phase") == "BATTLE" and tower.get("last_action_kind") == "ATTACK" and age >= 0 and age < 8
		var selected: bool = tower.get("side") == "PLAYER" and str(tower.get("id", "")) == selected_building_id
		var attack_range := int(tower.get("attack_range", 0))
		if not _visible(center, attack_range * scale_factor) and not (firing and _visible(target, 40)): continue
		result.append({"id":str(tower.id), "center":center, "target":target, "attack_range":attack_range, "screen_range":attack_range * scale_factor, "selected":selected, "firing":firing, "age":age, "target_id":str(tower.get("last_action_target_id", ""))})
	return result


func get_capture_readouts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if camera == null or snapshot.is_empty() or not get_parent() is Control: return result
	var subject_id := selected_unit if not selected_unit.is_empty() else selected_army
	var subject_kind := "UNIT" if not selected_unit.is_empty() else "ARMY"
	var scale_factor := float(camera.get_scale())
	for readout: Dictionary in Capture.read_all(snapshot,subject_id,subject_kind):
		var center := _screen(Vector2(readout.position))
		if not _visible(center,site_cull_margin(readout,scale_factor)): continue
		readout["screen_center"] = center
		readout["status_radius"] = clampf((36.0 if readout.kind == "RESOURCE" else 54.0) * scale_factor,24,48)
		readout["range_radius"] = float(readout.radius) * scale_factor
		readout["selected"] = str(readout.id) == selected_site_id
		readout["show_range"] = bool(readout.running) or bool(readout.selected) or readout.state == "CONTESTED"
		readout["expanded"] = bool(readout.show_range) or (readout.state == "PREPARATION" and Capture._total(readout.observed_presence) > 0)
		readout["compact"] = FrontierArt.enabled() and scale_factor < 0.40 and not readout.expanded and not readout.selected and readout.state in ["NO_TROOPS","OWNED","PREPARATION"]
		readout["motion"] = {"active":bool(readout.running),"pulse":float(int(snapshot.get("tick",0)) % 20) / 20.0 if readout.running else 0.0,"direction":int(readout.stage_direction),"flag_raise_ratio":float(readout.ratio)}
		var card_size := Vector2(205 if readout.presence.size() > 2 else 178,65) if readout.expanded else Vector2(100,36)
		if readout.compact: card_size = Vector2(40,14)
		var card_position := center - Vector2(card_size.x * 0.5,float(readout.status_radius) + card_size.y + 7)
		var frontier_site := Pixel.frontier_site_entry(readout)
		if not frontier_site.is_empty():
			var village_bounds := FrontierArt.prop_bounds(frontier_site,scale_factor)
			card_position.y = minf(card_position.y,center.y+village_bounds.position.y-card_size.y-10)
		# Tall new roofs must not bury the existing factual capture card. Match
		# only a real living building at this site, never a decorative house.
		for building: Dictionary in snapshot.get("buildings",[]):
			if int(building.get("hp",0))<=0 or Vector2(building.get("position",Vector2.ZERO)).distance_squared_to(Vector2(readout.position))>64*64:continue
			var roof_y := _screen(Vector2(building.position)).y+Pixel.building_visual_bounds(building,scale_factor).position.y
			card_position.y=minf(card_position.y,roof_y-card_size.y-28)
		var view_size: Vector2 = (get_parent() as Control).size
		card_position.x = clampf(card_position.x,2,maxf(2,view_size.x - card_size.x - 2))
		card_position.y = clampf(card_position.y,2,maxf(2,view_size.y - card_size.y - 2))
		readout["card_rect"] = Rect2(card_position,card_size)
		result.append(readout)
	return result


func _draw_capture_status(readout: Dictionary) -> void:
	var center: Vector2 = readout.screen_center
	var radius := float(readout.status_radius)
	var owner_color := _capture_color(str(readout.owner))
	var color := _capture_color(str(readout.capture_side))
	var ratio := float(readout.ratio)
	if readout.get("compact",false):
		# Overview retires idle prose/rings, never the actual owner or ratio.
		# Selected, contested, running and occupied preparation readouts bypass
		# this branch and retain their complete numeric facts and range cues.
		var compact_card: Rect2 = readout.card_rect
		draw_rect(compact_card,Color("172c2b",0.9))
		draw_rect(compact_card,Color(owner_color,0.65),false,1)
		var owner_caption := str(Capture.SIDES.find(str(readout.owner))+1) if readout.owner in Capture.SIDES else "中"
		draw_string(ReadableFont.readable(),compact_card.position+Vector2(3,10),owner_caption,HORIZONTAL_ALIGNMENT_LEFT,12,10,owner_color)
		draw_rect(Rect2(compact_card.position+Vector2(16,5),Vector2(20,4)),Color("0d1a19"))
		draw_rect(Rect2(compact_card.position+Vector2(16,5),Vector2(20*ratio,4)),color)
		return
	draw_arc(center,radius,0,TAU,40,Color(owner_color,0.34),2)
	if ratio > 0: draw_arc(center,radius,-PI * 0.5,-PI * 0.5 + TAU * ratio,40,color,3)
	if bool(readout.running):
		var pulse := float(readout.motion.pulse)
		var active_color := _capture_color(str(readout.leader))
		draw_arc(center,radius + 3 + pulse * 5,0,TAU,40,Color(active_color,(1 - pulse) * 0.55),2)
		# The additional flag follows real settled points; only running states
		# animate. A downward arrow distinguishes removal of the old side.
		var flag_x := center.x + radius + 7
		var floor_y := center.y + 12
		var cloth_y := floor_y - 4 - float(readout.motion.flag_raise_ratio) * 26
		draw_line(Vector2(flag_x,floor_y),Vector2(flag_x,floor_y - 33),Color("dccfa9"),2)
		draw_colored_polygon(PackedVector2Array([Vector2(flag_x,cloth_y),Vector2(flag_x + 12,cloth_y + 4),Vector2(flag_x,cloth_y + 8)]),color if readout.state == "NEUTRALIZING" else active_color)
		var direction := int(readout.motion.direction)
		var point := Vector2(flag_x + 19,center.y - 5 + (pulse - 0.5) * direction * 5)
		draw_line(point + Vector2(0,6) * direction,point - Vector2(0,6) * direction,active_color,2)
		draw_line(point - Vector2(0,6) * direction,point - Vector2(-4,2) * direction,active_color,2)
		draw_line(point - Vector2(0,6) * direction,point - Vector2(4,2) * direction,active_color,2)
	elif readout.state in ["CONTESTED","PREPARATION","TERMINAL"]:
		draw_line(center + Vector2(radius + 5,-5),center + Vector2(radius + 5,6),Color("e4c687"),3)
		draw_line(center + Vector2(radius + 11,-5),center + Vector2(radius + 11,6),Color("e4c687"),3)
	var card: Rect2 = readout.card_rect
	draw_rect(card,Color("172c2b",0.92))
	draw_rect(card,Color(owner_color,0.65),false,1)
	var origin := card.position
	# In neutralisation the bar/points still belong to the old capture side;
	# the opposing leader only colors the action pulse and downward arrow.
	var points_color := color
	var font := ReadableFont.readable()
	if readout.expanded:
		draw_string(font,origin + Vector2(6,15),str(readout.status_caption).replace("敌军", "对方").replace("敌方", "对方"),HORIZONTAL_ALIGNMENT_LEFT,card.size.x - 36,13,Color("e1dec3"))
		draw_string(font,origin + Vector2(6,33),str(readout.progress_caption),HORIZONTAL_ALIGNMENT_LEFT,card.size.x - 12,14,points_color)
		draw_string(font,origin + Vector2(6,58),str(readout.presence_caption).replace("敌", "对手"),HORIZONTAL_ALIGNMENT_LEFT,card.size.x - 12,13,Color("cbdace"))
		draw_rect(Rect2(origin + Vector2(6,38),Vector2(card.size.x - 12,5)),Color("0d1a19"))
		draw_rect(Rect2(origin + Vector2(6,38),Vector2((card.size.x - 12) * ratio,5)),color)
	else:
		draw_string(font,origin + Vector2(6,16),"%d/%d" % [int(readout.progress),int(readout.max_progress)],HORIZONTAL_ALIGNMENT_LEFT,card.size.x - 12,14,color)
		draw_rect(Rect2(origin + Vector2(6,21),Vector2(card.size.x - 12,5)),Color("0d1a19"))
		draw_rect(Rect2(origin + Vector2(6,21),Vector2((card.size.x - 12) * ratio,5)),color)
	# Ownership accompanies both active and idle points; action color alone
	# never silently awards the attacking player the site.
	draw_rect(Rect2(origin + Vector2(card.size.x - 23,3),Vector2(19,18)),Color(owner_color,0.24))
	draw_string(font,origin + Vector2(card.size.x - 21,17),str(Capture.SIDES.find(str(readout.owner)) + 1) if readout.owner in Capture.SIDES else "中",HORIZONTAL_ALIGNMENT_LEFT,18,12,owner_color)
	var population_point := center + Vector2(-10,radius + 17)
	Icons.draw_symbol(self,"population",population_point + Vector2(-9,-4),owner_color,0.35)
	draw_string(font,population_point + Vector2(2,0),"+%d" % int(readout.capacity),HORIZONTAL_ALIGNMENT_LEFT,60,13,owner_color)
	if readout.selected:
		draw_string(font,center + Vector2(-44,float(readout.range_radius) + 15),"占领圈 %.0f" % float(readout.radius),HORIZONTAL_ALIGNMENT_LEFT,100,13,Color("e4d499"))


static func _capture_color(side: String) -> Color:
	return Palette.side_color(side)


func _bar(point: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(point, Vector2(width, 4)), Color("152625"))
	draw_rect(Rect2(point, Vector2(width * clampf(ratio, 0, 1), 4)), color)


static func read_worker_hit(worker: Dictionary,tick: int) -> Dictionary:
	var damage_tick := int(worker.get("last_damage_tick",-1))
	var amount := int(worker.get("last_damage_amount",0))
	var age := tick-damage_tick
	if damage_tick < 0 or amount <= 0 or age < 0 or age >= 12: return {}
	return {"age":age,"amount":amount,"fade":1.0-float(age)/12.0}


static func read_selected_intent(facts: Dictionary, unit_id: String = "", army_id: String = "") -> Dictionary:
	var source := _find(facts, unit_id, ["soldiers"]) if not unit_id.is_empty() else _find(facts, army_id, ["warbands"])
	if source.is_empty() or source.get("side") != "PLAYER" or not _living(source): return {}
	var origin: Variant = source.get("position", source.get("anchor"))
	if not _point(origin): return {}
	var army := source if unit_id.is_empty() else _find(facts, str(source.get("warband_id", "")), ["warbands"])
	var direct := str(source.get("direct_intent", "")) if not unit_id.is_empty() else ""
	if direct == "HOLD": return {}
	var kind := direct if not direct.is_empty() else str(army.get("intent", "HOLD"))
	var target: Variant = null
	if direct == "MOVE": target = source.get("direct_destination")
	elif direct == "ATTACK":
		var victim := _find(facts, str(source.get("target_id", "")), ["soldiers", "workers", "buildings"])
		if victim.is_empty() or not _living(victim): return {}
		target = victim.get("position")
	elif kind in ["MOVE", "ATTACK_MOVE", "RETREAT"]: target = army.get("destination")
	elif kind == "FOCUS":
		var victim := _find(facts, str(army.get("target_warband_id", "")), ["warbands"])
		if victim.is_empty() or not _living(victim): return {}
		target = victim.get("anchor")
	elif kind == "ATTACK_BASE":
		var victim := _find(facts, str(army.get("target_base_id", "")), ["buildings"])
		if victim.is_empty() or not _living(victim): return {}
		target = victim.get("position")
	else: return {}
	if not _point(target) or Vector2(origin).distance_squared_to(Vector2(target)) <= 7.0 * 7.0: return {}
	return {"origin": Vector2(origin), "target": Vector2(target), "kind": "ATTACK" if kind in ["ATTACK", "FOCUS", "ATTACK_BASE"] else "ATTACK_MOVE" if kind == "ATTACK_MOVE" else "MOVE", "intent": kind, "subject_id": source.get("id", "")}


static func read_aim(facts: Dictionary, request: Dictionary) -> Dictionary:
	if request.is_empty(): return {}
	var unit := _find(facts, str(request.get("unit_id", "")), ["soldiers"])
	if unit.is_empty() or not _living(unit) or unit.get("side") != "PLAYER": return {}
	var skill: Dictionary = {}
	for hero: Dictionary in facts.get("heroes", {}).get("officers", []):
		if str(hero.get("unit_id", hero.get("id", ""))) != str(unit.get("id", "")): continue
		for entry: Dictionary in hero.get("skills", []):
			if str(entry.get("id", "")) == str(request.get("skill_id", "")): skill = entry
	if skill.is_empty(): return {}
	var origin: Variant = unit.get("position")
	var target: Variant = origin if skill.get("target_mode", "POINT") == "SELF" else request.get("target_position", origin)
	if not _point(origin) or not _point(target): return {}
	var distance := maxf(float(skill.get("range", 0)), 0)
	var radius := maxf(float(skill.get("radius", 0)), 0)
	return {"origin": Vector2(origin), "target": Vector2(target), "range": distance, "radius": radius, "name": str(skill.get("name", "技能范围")), "effect": str(skill.get("effect", "")), "within_range": Vector2(origin).distance_squared_to(Vector2(target)) <= distance * distance}


static func _find(facts: Dictionary, id: String, lists: Array) -> Dictionary:
	if id.is_empty(): return {}
	for list: String in lists:
		for entity: Dictionary in facts.get(list, []):
			if str(entity.get("id", "")) == id: return entity
	return {}


static func _living(entity: Dictionary) -> bool:
	return int(entity.get("living_count", 0)) > 0 if entity.has("living_count") else int(entity.get("hp", 0)) > 0 and bool(entity.get("alive", true))


static func _point(value: Variant) -> bool:
	return (value is Vector2 or value is Vector2i) and is_finite(float(value.x)) and is_finite(float(value.y))
