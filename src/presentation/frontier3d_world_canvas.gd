extends "res://src/presentation/strategic_world_canvas.gd"
## Optional real geometry underneath the unchanged strategic HUD. The inherited
## observation/readout helpers are shared; the old sprite draw route is not run.
const Environment3DClass = preload("res://src/presentation/frontier3d_environment.gd")
const Actors3DClass = preload("res://src/presentation/frontier3d_actors.gd")
const Projection3D = preload("res://src/presentation/frontier3d_camera_projection.gd")
var viewport3d: SubViewport
var camera3d: Camera3D
var terrain3d: Node3D
var actors3d: Node3D
var _texture_rect: TextureRect
var _bound_projection: RefCounted
var _preview: Node3D
## Low effects alters only rendering passes, never resolution or pick geometry.
var low_effects_enabled := "--frontier-low-effects" in OS.get_cmdline_user_args()

func _ready() -> void:
	viewport3d = SubViewport.new()
	viewport3d.name = "FrontierRealtimeViewport"
	viewport3d.own_world_3d = true
	viewport3d.handle_input_locally = false
	viewport3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport3d.msaa_3d = Viewport.MSAA_DISABLED if low_effects_enabled else Viewport.MSAA_2X
	viewport3d.positional_shadow_atlas_size = 1024
	add_child(viewport3d)
	_texture_rect = TextureRect.new()
	_texture_rect.name = "RealtimeBattlefieldTexture"
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.texture = viewport3d.get_texture()
	add_child(_texture_rect)
	# CanvasItem children draw after their parent. Keep all factual overlays
	# above the viewport image, not hidden underneath a child TextureRect.
	_texture_rect.show_behind_parent = true
	var world := Node3D.new()
	world.name = "FrontierWorld"
	viewport3d.add_child(world)
	var lighting := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("687169")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b7c5d3")
	environment.ambient_light_energy = 0.56
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	lighting.environment = environment
	world.add_child(lighting)
	var sun := DirectionalLight3D.new()
	sun.name = "LateMorningSun"
	sun.rotation_degrees = Vector3(-52,-32,0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 1.45
	sun.shadow_enabled = not low_effects_enabled
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 160
	sun.shadow_bias = 0.025
	sun.shadow_normal_bias = 0.65
	world.add_child(sun)
	camera3d = Camera3D.new()
	camera3d.name = "FixedObliqueCamera"
	camera3d.current = true
	world.add_child(camera3d)
	terrain3d = Environment3DClass.new()
	world.add_child(terrain3d)
	actors3d = Actors3DClass.new()
	world.add_child(actors3d)
	set_process(true)

func _process(delta: float) -> void:
	if camera == null or viewport3d == null or snapshot.is_empty(): return
	var size := Vector2i((get_parent() as Control).size)
	if viewport3d.size != size:
		viewport3d.size = Vector2i(maxi(size.x,1),maxi(size.y,1))
		_texture_rect.size = Vector2(size)
	if _bound_projection != camera:
		camera.bind_camera(camera3d)
		_bound_projection = camera
	terrain3d.configure(snapshot,landscape_plan)
	actors3d.observe(snapshot,delta)
	_update_blueprint()
	queue_redraw()

func _update_blueprint() -> void:
	if blueprint_type.is_empty():
		if is_instance_valid(_preview): _preview.queue_free(); _preview = null
		return
	if is_instance_valid(_preview) and str(_preview.get_meta("type","")) != blueprint_type:
		_preview.queue_free(); _preview = null
	if not is_instance_valid(_preview):
		var model := str(Actors3DClass.BUILDING_MODELS.get(blueprint_type,"workshop"))
		var path := Actors3DClass.ROOT+model+".glb"
		if not ResourceLoader.exists(path): return
		_preview = (load(path) as PackedScene).instantiate() as Node3D
		_preview.set_meta("type",blueprint_type)
		actors3d.add_child(_preview)
		var ghost := StandardMaterial3D.new()
		ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ghost.albedo_color = Color(0.5,0.8,0.65,0.26)
		for child: Node in _preview.find_children("*","MeshInstance3D",true,false):
			var mesh := child as MeshInstance3D
			mesh.material_override = ghost
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_preview.position = Projection3D.to_visual(blueprint_point)

func visual_body_contains(id: String, kind: String, point: Vector2) -> bool:
	if actors3d == null or camera == null: return false
	if not actors3d.screen_bounds(id,kind,camera).has_point(point): return false
	if kind == "building" and camera3d != null:
		var local := point-(get_parent() as Control).position
		return actors3d.opaque_building_contains(id,camera3d.project_ray_origin(local),camera3d.project_ray_normal(local))
	return true

func body_screen_bounds(id: String, kind: String) -> Rect2:
	return actors3d.screen_bounds(id,kind,camera) if actors3d != null and camera != null else Rect2()

func get_diagnostics() -> Dictionary:
	return {"mode":"frontier3d-m31", "quality_profile":"LOW_EFFECTS" if low_effects_enabled else "STANDARD", "render_size":viewport3d.size if viewport3d != null else Vector2i.ZERO,"environment":terrain3d.get_diagnostics() if terrain3d != null else {},"actors":actors3d.get_diagnostics() if actors3d != null else {},"render_observation":{"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"static_memory_bytes":OS.get_static_memory_usage(),"note":"single engine monitor observation, not a GPU-memory or physical-mobile benchmark"}}

func _height(point: Vector2, metres: float) -> Vector2:
	return camera.world_to_screen_height(point,metres)-(get_parent() as Control).position

func _ground_circle(point: Vector2, radius: float, color: Color, width: float = 1.5, ratio: float = 1.0) -> void:
	var points := PackedVector2Array()
	for index: int in range(65):
		var angle := -PI*0.5+float(index)/64.0*TAU*ratio
		points.append(_screen(point+Vector2.from_angle(angle)*radius))
	draw_polyline(points,color,width,true)

func _draw() -> void:
	if camera == null or snapshot.is_empty(): return
	var tick := int(snapshot.get("tick",0))
	var active := shows_transient_effects()
	var scale_factor := float(camera.get_scale())
	var font := ReadableFont.readable()
	for collection: String in ["workers","soldiers"]:
		for unit: Dictionary in snapshot.get(collection,[]):
			if int(unit.get("hp",0))<=0 or not unit.get("alive",true): continue
			var point := Vector2(unit.get("position",Vector2.ZERO))
			var foot := _screen(point)
			if not _visible(foot,100): continue
			var selected := str(unit.get("id","")) == selected_unit or str(unit.get("id","")) == selected_worker_id or (not selected_army.is_empty() and str(unit.get("warband_id","")) == selected_army)
			var color := Palette.side_color(str(unit.get("side","")))
			if selected: _ground_circle(point,float(unit.get("radius",12))+5,Color("f4d98f"),2)
			var top := _height(point,2.4 if unit.get("unit_type") == "hero" else 2.15)
			if selected or int(unit.get("hp",0)) < int(unit.get("max_hp",1)):
				_bar(top+Vector2(-17,-6),34,float(unit.get("hp",0))/maxf(float(unit.get("max_hp",1)),1),color)
			if unit.get("unit_type") == "hero" and selected:
				_bar(top+Vector2(-17,0),34,float(unit.get("mana",0))/maxf(float(unit.get("max_mana",1)),1),Color("7eaee4"))
			var pose := Pose.for_unit(unit,tick)
			if active and (pose.action == "ATTACK" or str(pose.action).begins_with("SKILL_")):
				_action_feedback(unit,pose)
			if active and pose.action in ["HEAL","POTION"]:
				_ground_circle(point,18+float(pose.phase)*20,Color(0.55,0.85,0.62,1-float(pose.phase)),2)
			Pixel.draw_control_status(self,foot,unit,scale_factor)
			if selected and not unit.get("status_effects",[]).is_empty():
				var seconds := 0.0
				for status: Dictionary in unit.status_effects: seconds = maxf(seconds,float(status.get("remaining_ticks",0))/20)
				if seconds>0: draw_string(font,top+Vector2(20,-8),"%.1fs" % seconds,HORIZONTAL_ALIGNMENT_LEFT,55,12,Color("e4c590"))
			var injury: Dictionary = _hit_feedback.read(str(unit.get("id","")),tick)
			if active and not injury.is_empty(): _draw_injury(_height(point,1.2),maxf(7,12*scale_factor),injury)
	for building: Dictionary in snapshot.get("buildings",[]):
		if int(building.get("hp",0))<=0: continue
		var point := Vector2(building.get("position",Vector2.ZERO))
		if not _visible(_screen(point),220): continue
		var complete := bool(building.get("complete",false))
		var top := _height(point,5.9 if building.get("building_type") == "BASE" else 4.0)
		if not complete or int(building.get("hp",0))<int(building.get("max_hp",1)):
			var ratio := float(building.get("hp",0))/maxf(float(building.get("max_hp",1)),1) if complete else float(building.get("progress",0))/maxf(float(building.get("max_progress",1)),1)
			_bar(top+Vector2(-32,-10),64,ratio,Color("b7c58b"))
			if not complete: draw_string(font,top+Vector2(-32,-17),"施工 %d%%" % int(ratio*100),HORIZONTAL_ALIGNMENT_LEFT,100,12,Color("e2d7ba"))
		if not building.get("queue",[]).is_empty():
			var job: Dictionary = building.queue[0]
			_bar(top+Vector2(-32,-3),64,float(job.get("progress",0))/maxf(float(job.get("max_progress",1)),1),Color("dfc27e"))
		var upgrading: Dictionary = building.get("base_upgrade",{})
		if not upgrading.is_empty(): _bar(top+Vector2(-32,5),64,float(upgrading.get("progress",0))/maxf(float(upgrading.get("max_progress",1)),1),Color("76b1e0"))
		if building.get("building_type") == "BASE": draw_string(font,top+Vector2(-25,-17),"营所 %d级" % int(building.get("base_tier",1)),HORIZONTAL_ALIGNMENT_LEFT,90,12,Color("e8dcc0"))
	for tower: Dictionary in get_tower_readouts():
		var building := _find(snapshot,str(tower.id),["buildings"])
		if building.is_empty(): continue
		if tower.selected: _ground_circle(Vector2(building.position),float(tower.attack_range),Color("ebca83",0.5))
		if tower.firing:
			var from := _height(Vector2(building.position),3.8)
			var to := _height(Vector2(building.get("last_action_target_position",building.position)),1)
			var progress := clampf(float(tower.age)/7,0,1)
			var arrow := from.lerp(to,progress)+Vector2(0,-sin(progress*PI)*16)
			draw_line(arrow-(to-from).normalized()*10,arrow,Color("f1dbb2"),2,true)
	_draw_sites()
	for hero: Dictionary in snapshot.get("heroes",{}).get("officers",[]):
		var age := tick-int(hero.get("last_level_up_tick",-1000000))
		if active and int(hero.get("hp",0))>0 and age>=0 and age<25:
			var fade := 1-float(age)/25
			_ground_circle(Vector2(hero.get("position",Vector2.ZERO)),20+float(age),Color(0.9,0.8,0.43,fade),2)
			draw_string(font,_height(Vector2(hero.get("position",Vector2.ZERO)),2.5)+Vector2(-30,-age),"升级 +1点",HORIZONTAL_ALIGNMENT_LEFT,130,15,Color(0.95,0.85,0.56,fade))
	var intent := read_selected_intent(snapshot,selected_unit,selected_army)
	if not intent.is_empty():
		var from := _screen(intent.origin)
		var to := _screen(intent.target)
		var color := Color("e5bb78") if intent.kind == "ATTACK_MOVE" else Color("ef9b82") if intent.kind == "ATTACK" else Color("9cd2cd")
		for index: int in range(24): draw_line(from.lerp(to,float(index)/24),from.lerp(to,(float(index)+0.4)/24),Color(color,0.45),1,true)
		_ground_circle(Vector2(intent.target),12,color)
	for mark: Dictionary in feedback_marks.slice(0,16):
		if not _point(mark.get("position")): continue
		var fade := clampf(1-float(mark.get("age",0))/maxf(float(mark.get("lifetime",1)),0.01),0,1)
		var color := Color("ed967d") if mark.get("kind") == "REJECT" else Color("ead69b")
		_ground_circle(Vector2(mark.position),14+(1-fade)*15,Color(color,fade),2)
		if mark.get("kind") != "SELECT": draw_string(font,_screen(Vector2(mark.position))+Vector2(16,-12),str(mark.get("caption","")),HORIZONTAL_ALIGNMENT_LEFT,150,13,Color(color,fade))
	var preview := read_aim(snapshot,aim)
	if not preview.is_empty():
		var color := Color("9fd9d0") if preview.within_range else Color("e99576")
		_ground_circle(Vector2(preview.origin),float(preview.range),Color(color,0.3))
		if float(preview.radius)>0: _ground_circle(Vector2(preview.target),float(preview.radius),color,2)
		draw_line(_screen(preview.origin),_screen(preview.target),Color(color,0.4),1,true)
	if not blueprint_type.is_empty():
		var observation := get_blueprint_observation()
		_ground_circle(blueprint_point,float(observation.radius),Color("b1d9c4"),2)
		draw_string(font,_screen(blueprint_point)+Vector2(12,-20),"单击放置 · "+blueprint_type,HORIZONTAL_ALIGNMENT_LEFT,210,14,Color("e8d5a4"))
	for mark: Dictionary in field_reward_marks.slice(0,4):
		var fade := 1-float(mark.get("age",0))/maxf(float(mark.get("lifetime",2)),0.1)
		if fade>0: draw_string(font,_height(Vector2(mark.get("position",Vector2.ZERO)),3)+Vector2(-50,-(1-fade)*24),str(mark.get("caption","探索完成")),HORIZONTAL_ALIGNMENT_LEFT,250,15,Color(0.95,0.84,0.59,fade))

func _action_feedback(unit: Dictionary, pose: Dictionary) -> void:
	var phase := float(pose.get("phase",0))
	var from := _height(Vector2(unit.position),1.3)
	var to := _height(Vector2(pose.target_position),1)
	var color := Color("b3d3e7") if str(pose.action).begins_with("SKILL_") else Color("efdab3")
	if float(unit.get("attack_range",0))>100:
		var arrow := from.lerp(to,phase)+Vector2(0,-sin(phase*PI)*12)
		draw_line(arrow-(to-from).normalized()*8,arrow,color,1.8,true)
	elif phase < 0.7:
		var direction := (to-from).normalized()
		var center := from+direction*12
		draw_arc(center,12,-1.2+direction.angle()+phase*2.5,-0.3+direction.angle()+phase*2.5,12,Color(color,1-phase),2,true)
	if str(pose.action).begins_with("SKILL_"):
		_ground_circle(Vector2(pose.target_position),float(pose.get("skill",{}).get("radius",40))*(0.7+phase*0.3),Color(color,0.8*(1-phase)),2)

func _draw_sites() -> void:
	var readouts := get_capture_readouts()
	var marks: Array[Dictionary] = []
	for readout: Dictionary in readouts:
		var point := Vector2(readout.position)
		# Never mix legacy sprite roof measurements with the new camera. The
		# numerical capture contract remains inherited from Capture.read_all.
		readout.compact = not readout.expanded and not readout.selected
		var card_size := Vector2(178,65) if readout.expanded else Vector2(66,18)
		var top := _height(point,3.2 if readout.kind == "VILLAGE" else 6.4)
		var position := top-Vector2(card_size.x/2,card_size.y+10)
		var view := (get_parent() as Control).size
		position.x = clampf(position.x,2,maxf(2,view.x-card_size.x-20))
		position.y = clampf(position.y,2,maxf(2,view.y-card_size.y-2))
		readout.card_rect = Rect2(position,card_size)
		readout.status_radius = 22
		if readout.show_range: _ground_circle(point,float(readout.radius),Color(Palette.side_color(str(readout.leader)),0.4))
		_draw_capture_status(readout)
		var objective: Dictionary = readout.get("field_objective",{})
		if not objective.is_empty():
			var location := position+Vector2(card_size.x+10,card_size.y/2)
			FieldObjectives.draw_marker(self,location,objective,true)
			marks.append({"site_id":str(readout.id),"position":location,"state":str(objective.state)})
	set_meta("capture_readouts",readouts.duplicate(true))
	set_meta("field_objective_marks",marks)
