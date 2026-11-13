extends Control
## Read-only camera and selection over detached replay frames. No input can
## issue a game command, regenerate loot or settle a combat event.
signal subject_selected(id: String)
const WorldCanvas = preload("res://src/presentation/heroic_2d_world_canvas.gd")
const ArenaStage = preload("res://src/presentation/strategic_hero_arena_stage.gd")
const Camera = preload("res://src/presentation/battle_camera_projection.gd")
const HitFeedback = preload("res://src/presentation/strategic_hit_feedback.gd")
var _camera := Camera.new()
var _world: Node2D
var _arena: Control
var _observation: Dictionary = {}
var _kind := ""
var _selected := ""
var _dragging := false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(420,290)
	_world = WorldCanvas.new()
	_world.camera = _camera
	add_child(_world)
	_arena = ArenaStage.new()
	_arena.zoom = 1.7
	_arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arena.unit_selected.connect(func(id: String): _selected=id; subject_selected.emit(id))
	add_child(_arena)
	resized.connect(_configure_camera)

func show_observation(snapshot: Dictionary, kind: String) -> void:
	var rewind := int(snapshot.get("tick",0)) < int(_observation.get("tick",0))
	var changed := kind != _kind
	_kind = kind
	_observation = snapshot
	if _world == null: return
	_world.visible = kind == "STRATEGIC"
	_arena.visible = kind == "ARENA"
	if kind == "STRATEGIC":
		if rewind or changed:_world.reset_feedback()
		_world.snapshot = snapshot
		_configure_camera()
		if changed: _camera.fit_all()
		_world.queue_redraw()
	else:
		if rewind or changed:_arena.reset_feedback()
		_arena.observation = snapshot
	queue_redraw()

func reset_feedback() -> void:
	if _world!=null:_world.reset_feedback()
	if _arena!=null:_arena.reset_feedback()

func set_selected(id: String) -> void:
	_selected = id
	if _world != null:
		_world.selected_unit = id
		_world.selected_worker_id = id
		_world.selected_building_id = id
		_world.queue_redraw()
	if _arena != null: _arena.selected=id; _arena.queue_redraw()

func focus_subject(id: String) -> void:
	set_selected(id)
	for group: String in ["soldiers","workers","buildings"]:
		for body: Dictionary in _observation.get(group,[]):
			if str(body.get("id","")) != id: continue
			if _kind == "STRATEGIC":
				_camera.center_on(Vector2(body.position))
				if _camera.get_zoom()<2: _camera.zoom_at(position+size*0.5,2)
				_world.queue_redraw()
			return

func _configure_camera() -> void:
	if _world == null or _observation.is_empty(): return
	var b: Dictionary = _observation.get("arena_bounds",{})
	var bounds := Rect2i(int(b.get("min_x",0)),int(b.get("min_y",0)),int(b.get("max_x",3200))-int(b.get("min_x",0)),int(b.get("max_y",2000))-int(b.get("min_y",0)))
	_camera.configure(bounds,Rect2(position,size),5.0)
	_world.queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if _kind != "STRATEGIC": return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT: _dragging=event.pressed; accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			_camera.zoom_at(event.position+position,1.18 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.18)
			_world.queue_redraw()
			accept_event()
		elif event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			var point: Vector2 = _camera.screen_to_world(event.position+position-_world.feedback_screen_offset_r9())
			var nearest := ""
			var best := pow(32.0/maxf(_camera.get_scale(),0.1),2)
			for collection: String in ["soldiers","workers","buildings"]:
				for body: Dictionary in _observation.get(collection,[]):
					var distance := point.distance_squared_to(Vector2(body.get("position",Vector2.ZERO)))
					if distance<best: best=distance; nearest=str(body.get("id",""))
			if not nearest.is_empty(): set_selected(nearest); subject_selected.emit(nearest)
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_camera.pan_screen(event.relative)
		_world.queue_redraw()
		accept_event()
