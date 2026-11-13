extends Control
## Actual arena observations painted by the same body/action/status renderers.
signal unit_selected(id: String)
const Units = preload("res://src/presentation/heroic_pixel_units.gd")
const Pose = preload("res://src/presentation/strategic_action_pose.gd")
const Readout = preload("res://src/presentation/heroic_actor_readout.gd")
const Effects = preload("res://src/presentation/heroic_combat_effects.gd")
const ReworkR7Effects = preload("res://src/presentation/heroic_rework_r7_effects.gd")
const R7Spectacle = preload("res://src/presentation/heroic_r7_spectacle.gd")
const RosterV5 = preload("res://src/presentation/heroic_roster_v5.gd")
var review_center := Vector2(1350,1100)
var review_extent_r12 := Vector2(900,560)
const Empowerment = preload("res://src/presentation/heroic_empowerment_art.gd")
const Aura = preload("res://src/presentation/heroic_aura_art.gd")
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const Fonts = preload("res://src/presentation/strategic_font.gd")
const HitFeedback = preload("res://src/presentation/strategic_hit_feedback.gd")
const CombatFeedbackR9 = preload("res://src/presentation/strategic_combat_feedback_r9.gd")
var observation: Dictionary = {}:
	set(value):
		observation = value
		_hit_feedback.observe(value)
		_combat_feedback_r9.observe(value)
		queue_redraw()
var selected := ""
var zoom := 1.0
## Developer readability fixture only; the default courtyard is unchanged.
var review_floor := "GRASS"
var _points: Dictionary = {}
var _factor := 1.0
var _hit_feedback := HitFeedback.new()
var _combat_feedback_r9 := CombatFeedbackR9.new()
var screen_shake_enabled := true

func reset_feedback() -> void:
	_hit_feedback.reset()
	_combat_feedback_r9.reset()

func frame_deployment_r12(snapshot: Dictionary) -> void:
	# Setup-only camera envelope. Do not zoom/pan after every combat movement,
	# shrink physical bodies, omit rear ranks or change the authority snapshot.
	var envelope := Rect2()
	var found := false
	for body: Dictionary in snapshot.get("soldiers",[]):
		if int(body.get("hp",0))<=0 or not Readout.visible_to(body,"PLAYER"): continue
		var radius := float(body.get("visual_radius",body.get("radius",12)))
		var art := Units.stable_visual_bounds(body,radius)
		var bounds := Rect2(Vector2(body.position)+art.position,art.size).grow(50)
		envelope=envelope.merge(bounds) if found else bounds
		found=true
	if found:
		review_center=envelope.get_center()
		review_extent_r12=Vector2(maxf(900,envelope.size.x),maxf(560,envelope.size.y))
	queue_redraw()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	custom_minimum_size = Vector2(430,180)
	resized.connect(queue_redraw)

func _draw() -> void:
	RosterV5.begin_draw(self)
	Chrome.draw_material(self,Rect2(Vector2.ZERO,size),"map")
	var inner := Rect2(10,10,maxf(size.x-20,1),maxf(size.y-20,1))
	var floor_colors: Array[Color] = [Color("2e382e"),Color("354032"),Color("303b30"),Color("46513b")]
	if review_floor=="DARK": floor_colors=[Color("151b23"),Color("202631"),Color("19212b"),Color("343b46")]
	elif review_floor=="SNOW": floor_colors=[Color("c4cabc"),Color("d3d9c9"),Color("cbd1c1"),Color("a4b9ac")]
	draw_rect(inner,floor_colors[0])
	# Original bounded pixel training courtyard, not extra simulation obstacles.
	for y: int in range(14,int(size.y)-14,24):
		for x: int in range(14,int(size.x)-14,32):
			var light := (x/32 + y/24) % 3
			draw_rect(Rect2(x,y,29,21),floor_colors[1] if light == 0 else floor_colors[2])
			if light == 1: draw_rect(Rect2(x+20,y+5,3,2),floor_colors[3])
	for x: int in range(16,int(size.x)-16,32):
		draw_rect(Rect2(x,14,29,7),Color("5d5b4b"))
		draw_rect(Rect2(x,size.y-24,29,7),Color("494b40"))
	_points.clear()
	if observation.is_empty(): return
	var bodies: Array = observation.get("soldiers",[]).duplicate()
	bodies=bodies.filter(func(body:Dictionary)->bool:return Readout.visible_to(body,"PLAYER"))
	bodies.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return Vector2(a.position).y < Vector2(b.position).y if Vector2(a.position).y != Vector2(b.position).y else str(a.id)<str(b.id))
	_factor = minf(maxf(inner.size.x-80,1)/review_extent_r12.x,maxf(inner.size.y-100,1)/review_extent_r12.y)*zoom
	var center := review_center
	var screen_center := inner.get_center()+Vector2(0,28)
	var unshaken := screen_center
	screen_center+=_combat_feedback_r9.camera_offset(observation,-1,screen_shake_enabled,func(p:Vector2)->bool:return inner.has_point(unshaken+(p-center)*_factor))
	var heads:Dictionary={}
	var tick := int(observation.get("tick",0))
	var context := Empowerment.prepare(observation)
	# The arena must show the same equipment / learned / innate aura facts as
	# the world. A nearby actor is not evidence that it received a benefit.
	for source: Dictionary in Readout.aura_sources(observation,"PLAYER"):
		var at := (screen_center+(Vector2(source.position)-center)*_factor).round()
		Readout.draw_aura_source(self,at,source,_factor,str(source.source_id)==selected,tick)
	var r7_visual := ReworkR7Effects.visual_plan(observation,"PLAYER")
	var spectacle := R7Spectacle.plan(observation,"PLAYER",r7_visual.pending)
	var roster_v5 := RosterV5.plan(observation,"PLAYER")
	RosterV5.draw(self,roster_v5,func(p:Vector2)->Vector2:return (screen_center+(p-center)*_factor).round(),_factor,"REAR")
	ReworkR7Effects.draw_atmosphere(self,r7_visual.atmosphere,func(p:Vector2)->Vector2:return (screen_center+(p-center)*_factor).round(),_factor)
	R7Spectacle.draw(self,spectacle,func(p:Vector2)->Vector2:return (screen_center+(p-center)*_factor).round(),_factor,"REAR")
	for body: Dictionary in bodies:
		var point := (screen_center+(Vector2(body.position)-center)*_factor).round()
		_points[body.id] = point
		var radius := maxf(float(body.get("visual_radius",body.get("radius",12)))*_factor,3)
		var pose := Pose.for_unit(body,tick)
		var cast_offset := RosterV5.body_offset(body,tick)
		if str(body.get("hero_archetype","")) in ReworkR7Effects.Catalog.ENABLED_HEROES:
			var casting := R7Spectacle.cast_body(body,pose,spectacle)
			pose=casting.pose
			cast_offset=Vector2(casting.offset)
		var bounds := Units.stable_visual_bounds(body,radius)
		heads[str(body.id)]=Vector2(0,bounds.position.y-10)
		Readout.draw_hero_ellipse(self,point,body,Units.ground_footprint(body,radius),_factor)
		if str(body.id) == selected and int(body.hp)>0:
			draw_rect(Rect2(point+Vector2(-25,-9)*_factor,Vector2(50,18)*_factor),Color("e2cf87"),false,2)
		var marks := Empowerment.read(body,context)
		var operations := Empowerment.plan(point,body,marks,tick,_factor,bounds)
		Empowerment.draw(self,operations,"REAR")
		Units.draw(self,point+cast_offset*_factor+_combat_feedback_r9.body_offset(body,tick)*_factor,body,radius,pose)
		Empowerment.draw(self,operations,"FRONT")
		var injury := _hit_feedback.read(str(body.id),tick)
		if not injury.is_empty():
			Effects.draw_hit(self,point+Vector2(0,bounds.position.y*0.45),body,injury,_factor)
		Aura.draw_beneficiaries(self,point,body,_factor,tick)
		for status: Dictionary in body.get("status_effects",[]).slice(0,4):
			if not ReworkR7Effects.Catalog.has_skill(str(status.get("skill_id",""))):
				Effects.draw_status(self,point,point+Vector2(0,bounds.position.y),body,status,tick,_factor)
	ReworkR7Effects.draw_atmosphere(self,r7_visual.atmosphere,func(p:Vector2)->Vector2:return (screen_center+(p-center)*_factor).round(),_factor,"FRONT")
	# Persistent R7 seals must survive the following Y-sorted bodies. Keep
	# their shoulder anchors, but draw their cores above bodies, below bars.
	for body: Dictionary in bodies:
		var point: Vector2 = _points[body.id]
		for status: Dictionary in body.get("status_effects",[]).slice(0,4):
			if ReworkR7Effects.Catalog.has_skill(str(status.get("skill_id",""))):
				ReworkR7Effects.draw_status(self,point,point,body,status,tick,_factor)
	for body: Dictionary in bodies:
		var point: Vector2 = _points[body.id]
		var pose := Pose.for_unit(body,tick)
		var impacts: Array = []
		for hit: Dictionary in body.get("last_skill_targets",[]): impacts.append((screen_center+(Vector2(hit.position)-center)*_factor).round())
		var target := (screen_center+(Vector2(pose.target_position)-center)*_factor).round()
		if not pose.get("skill",{}).has("r7_handler"): Effects.draw_action(self,point,target,body,pose,_factor,impacts)
	ReworkR7Effects.draw_pending(self,observation,func(p:Vector2)->Vector2:return (screen_center+(p-center)*_factor).round(),_factor,"PLAYER",r7_visual)
	R7Spectacle.draw(self,spectacle,func(p:Vector2)->Vector2:return (screen_center+(p-center)*_factor).round(),_factor,"FRONT")
	RosterV5.draw(self,roster_v5,func(p:Vector2)->Vector2:return (screen_center+(p-center)*_factor).round(),_factor,"FRONT")
	for body: Dictionary in bodies:
		var point: Vector2 = _points[body.id]
		var radius := maxf(float(body.get("visual_radius",body.get("radius",12)))*_factor,3)
		Readout.draw_bars(self,point,body,Units.stable_visual_bounds(body,radius),_factor<0.75)
	var status: Dictionary = observation.get("arena",{})
	CombatFeedbackR9.draw_numbers(self,_combat_feedback_r9.numbers(observation),func(p:Vector2)->Vector2:return (screen_center+(p-center)*_factor).round(),func(id:String)->Vector2:return heads.get(id,Vector2(0,-40*_factor)),_factor)
	var caption := "真实战斗 · %.1f / %.0f 秒" % [float(status.get("elapsed_ticks",0))/20.0,float(status.get("limit_ticks",0))/20.0]
	draw_string(Fonts.readable(),Vector2(26,42),caption,HORIZONTAL_ALIGNMENT_LEFT,size.x-52,18,Color("e8d7a9"))
	draw_string(Fonts.readable(),Vector2(26,size.y-38),"单击查看单位 · 训练装备与等级不影响正式对战",HORIZONTAL_ALIGNMENT_LEFT,size.x-52,14,Color("a7b39b"))

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: return
	var nearest := ""
	var best := 70.0*70.0
	for id: String in _points:
		var distance: float = Vector2(_points[id]).distance_squared_to(event.position+Vector2(0,25*_factor))
		if distance < best:
			best = distance
			nearest = id
	if not nearest.is_empty():
		selected = nearest
		unit_selected.emit(nearest)
		queue_redraw()
	accept_event()
