extends Control
## The map owns and consumes every mouse/touch event. It emits camera locations
## only, even while a military target or blueprint is armed in the arena.

signal location_requested(world_position: Vector2)
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const FieldObjectives = preload("res://src/presentation/strategic_field_objective_readout.gd")
var snapshot: Dictionary = {}
var landscape_plan: Dictionary = {}
var camera: RefCounted

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "单击定位镜头 · 全场公开 · 不发出军令或建造"

func get_map_rect() -> Rect2:
	return Rect2(Vector2(8, 8), size - Vector2(16, 30))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT: _locate(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and not event.canceled: _locate(event.position)
		accept_event()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		accept_event()

func _locate(point: Vector2) -> void:
	var rect := get_map_rect()
	if camera != null and rect.has_point(point): location_requested.emit(camera.minimap_screen_to_world(point, rect))

func _draw() -> void:
	Chrome.draw_material(self, Rect2(Vector2.ZERO, size), "map")
	var rect := get_map_rect()
	draw_rect(rect, Color("2c4337"))
	if camera == null: return
	# The same detached road plan appears here only as strategic context. This
	# layer never gains an order target, even while a map command is armed.
	for road: Dictionary in landscape_plan.get("roads",[]):
		var points: Array=road.get("points",[])
		for index: int in range(1,points.size()):
			draw_line(camera.minimap_world_to_screen(Vector2(points[index-1]),rect),camera.minimap_world_to_screen(Vector2(points[index]),rect),Color("8c8c6c",0.55),1)
	for terrain: Dictionary in snapshot.get("terrain", []):
		var point: Vector2 = camera.minimap_world_to_screen(Vector2(terrain.get("position", Vector2.ZERO)), rect)
		var bounds: Rect2i = snapshot.get("match_config", {}).get("bounds", snapshot.get("bounds", snapshot.get("scenario", {}).get("bounds", Rect2i(0, 0, 3200, 2000))))
		var scale_factor: float = rect.size.x / maxf(float(bounds.size.x), 1)
		var color := Color("507b91") if terrain.get("kind") in ["LAKE", "RIVER"] else Color("777b71") if terrain.get("kind") in ["MOUNTAIN", "RUIN"] else Color("517b4b")
		if terrain.get("kind")=="GLACIER": color=Color("699eae")
		elif terrain.get("kind")=="LAVA": color=Color("9a4933")
		draw_circle(point, maxf(float(terrain.get("radius", 1)) * scale_factor, 1), color)
	var objective_marks: Array[Dictionary] = []
	for site: Dictionary in snapshot.get("sites", []):
		var p: Vector2 = camera.minimap_world_to_screen(Vector2(site.get("position", Vector2.ZERO)), rect)
		var color: Color = Palette.side_color(str(site.get("owner", "")))
		var extent := 5 if site.get("kind") == "RESOURCE" else 3
		if site.get("resource") == "ESSENCE":
			draw_rect(Rect2(p-Vector2.ONE*6,Vector2.ONE*12),Color("2b2636"))
			draw_rect(Rect2(p+Vector2(-2,-6),Vector2(4,10)),Color("c3a0d9"))
			draw_rect(Rect2(p+Vector2(-5,-2),Vector2(3,6)),Color("a07bb9"))
			draw_rect(Rect2(p+Vector2(2,0),Vector2(3,4)),color)
			continue
		var objective := FieldObjectives.read(snapshot, str(site.get("id", "")))
		if objective.is_empty(): draw_rect(Rect2(p - Vector2.ONE * extent, Vector2.ONE * extent * 2), color)
		else:
			FieldObjectives.draw_minimap(self, p, objective, color)
			objective_marks.append({"site_id":str(site.id),"kind":str(objective.kind),"state":str(objective.state),"position":p})
	set_meta("field_objective_marks", objective_marks)
	for building: Dictionary in snapshot.get("buildings", []):
		var p: Vector2 = camera.minimap_world_to_screen(Vector2(building.get("position", Vector2.ZERO)), rect)
		if int(building.get("hp", 0)) <= 0:
			draw_line(p - Vector2.ONE * 2, p + Vector2.ONE * 2, Color("7b7564"), 1)
			draw_line(p + Vector2(-2, 2), p + Vector2(2, -2), Color("7b7564"), 1)
			continue
		draw_rect(Rect2(p - Vector2.ONE * 2, Vector2.ONE * 4), Palette.side_color(str(building.get("side", ""))))
	for soldier: Dictionary in snapshot.get("soldiers", []):
		if not soldier.get("alive", false): continue
		var p: Vector2 = camera.minimap_world_to_screen(Vector2(soldier.get("position", Vector2.ZERO)), rect)
		if soldier.get("unit_type") == "hero": draw_circle(p, 3.5, Color("e2cc80"))
		draw_circle(p, 2.5 if soldier.get("unit_type") == "hero" else 1.5, Palette.side_color(str(soldier.get("side", ""))))
	draw_rect(camera.get_minimap_view_rect(rect), Color("e3dcc5"), false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(0, size.y - 6), "地图 · 全场公开", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color("d3dbc8"))

func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.14, 0.13, 0.94)
	style.border_color = Color("7b8e75")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
