class_name BattleArena
extends Node2D

## Snapshot-only projection for the M10 compact RTS graybox. This node owns visual
## selection and UI feedback only; all movement, damage, targets, formation and
## outcome values are read from GameSimulation snapshots through GameSession.

const GameSessionClass = preload("res://src/runtime/game_session.gd")
const GameSimulationClass = preload("res://src/simulation/game_simulation.gd")
const FormationLibraryClass = preload("res://src/simulation/formation_library.gd")
const WarbandCatalogClass = preload("res://src/simulation/warband_catalog.gd")
const CampCatalogClass = preload("res://src/simulation/camp_catalog.gd")
const TacticalReadoutClass = preload("res://src/presentation/tactical_readout.gd")
const PixelBattleRendererClass = preload("res://src/presentation/pixel_battle_renderer.gd")
const BattleCameraClass = preload("res://src/presentation/battle_camera_projection.gd")
const BattleMinimapClass = preload("res://src/presentation/battle_minimap.gd")
const NeutralSpringClass = preload("res://src/simulation/neutral_spring.gd")
const BattleScenarioCatalogClass = preload("res://src/simulation/battle_scenario_catalog.gd")
const CameraNavigationInputClass = preload("res://src/presentation/camera_navigation_input.gd")

@export var scenario_id: String = BattleScenarioCatalogClass.FRONTIER_ID

const SIDE_PLAYER := GameSimulationClass.SIDE_PLAYER
const SIDE_AI := GameSimulationClass.SIDE_AI
const OUTCOME_ONGOING := GameSimulationClass.OUTCOME_ONGOING
const FORMATIONS := FormationLibraryClass.ALL

const COLOR_PAGE := Color(0.035, 0.047, 0.055, 1.0)
const COLOR_FIELD := Color(0.105, 0.145, 0.145, 1.0)
const COLOR_FIELD_EDGE := Color(0.31, 0.38, 0.34, 1.0)
const COLOR_GRID := Color(0.25, 0.31, 0.29, 0.28)
const COLOR_TEXT := Color(0.91, 0.90, 0.82, 1.0)
const COLOR_MUTED := Color(0.61, 0.64, 0.59, 1.0)
const COLOR_PLAYER := Color(0.22, 0.70, 0.91, 1.0)
const COLOR_PLAYER_DARK := Color(0.07, 0.25, 0.35, 1.0)
const COLOR_CROSSBOW_PLAYER := Color(0.67, 0.79, 1.0, 1.0)
const COLOR_AI := Color(0.93, 0.37, 0.23, 1.0)
const COLOR_AI_DARK := Color(0.34, 0.10, 0.07, 1.0)
const COLOR_CROSSBOW_AI := Color(1.0, 0.69, 0.44, 1.0)
const COLOR_ACCENT := Color(0.94, 0.76, 0.31, 1.0)
const COLOR_SUCCESS := Color(0.48, 0.86, 0.54, 1.0)
const COLOR_DANGER := Color(1.0, 0.45, 0.36, 1.0)
const COLOR_INCAPACITATED := Color(0.22, 0.23, 0.23, 1.0)
const COLOR_FOOD := Color(0.54, 0.82, 0.39, 1.0)
const COLOR_MATERIAL := Color(0.82, 0.64, 0.40, 1.0)
const COLOR_CONSTRUCTION := Color(0.75, 0.69, 0.92, 1.0)

const SOLDIER_HIT_RADIUS := 15.0
const WORKER_HIT_RADIUS := 13.0
const TOP_PANEL_HEIGHT := 44.0
const BOTTOM_PANEL_HEIGHT := 164.0
const COMBAT_EFFECT_LIMIT := 128
const COMBAT_EFFECT_SECONDS := 0.22

var _session: GameSession
var _snapshot: Dictionary = {}
var _previous_snapshot: Dictionary = {}
var _interpolation_alpha := 1.0
var _selected_warband_id := ""

var _ui_root: Control
var _top_panel: PanelContainer
var _bottom_panel: PanelContainer
var _outcome_panel: PanelContainer
var _status_label: Label
var _spring_status_label: Label
var _instruction_label: Label
var _feedback_label: Label
var _outcome_label: Label
var _restart_button: Button
var _retreat_button: Button
var _auto_engage_button: Button
var _auto_defend_button: Button
var _warband_readout_label: Label
var _camp_toggle_button: Button
var _camp_panel: PanelContainer
var _camp_status_label: Label
var _camp_work_label: Label
var _camp_eta_label: Label
var _camp_cost_label: Label
var _camp_benefit_label: Label
var _camp_progress: ProgressBar
var _camp_build_button: Button
var _camp_cancel_button: Button
var _fortify_base_button: Button
var _cards_row: HBoxContainer
var _cards_by_id: Dictionary = {}
var _formation_buttons: Dictionary = {}
var _economy_panel: PanelContainer
var _economy_summary_label: Label
var _economy_stock_label: Label
var _economy_row_labels: Dictionary = {}
var _economy_minus_buttons: Dictionary = {}
var _economy_plus_buttons: Dictionary = {}
var _transfer_from: OptionButton
var _transfer_to: OptionButton
var _transfer_button: Button
var _start_battle_button: Button
var _production_panel: PanelContainer
var _production_summary_label: Label
var _production_cost_label: Label
var _production_book_label: Label
var _production_reserved_label: Label
var _production_available_label: Label
var _production_queue_label: Label
var _production_enqueue_button: Button
var _production_guard_button: Button
var _production_crossbow_button: Button
var _production_rows: Array[Dictionary] = []
var _base_status_row: HBoxContainer
var _player_base_label: Label
var _enemy_base_label: Label
var _objective_reason_label: Label
var _presentation_font: SystemFont
var _combat_effects: Array[Dictionary] = []
var _camera: RefCounted
var _world_clip: Control
var _world_canvas: Node2D
var _navigation_row: HBoxContainer
var _navigation_buttons: Dictionary = {}
var _camera_zoom_label: Label
var _minimap: Control
var _economy_visible := false
var _camera_dragging := false
var _tactical_map_button: Button
var _expanded_map_panel: Panel
var _expanded_map: Control
var _expanded_map_title: Label
var _map_switch_button: Button
var _resource_label: Label
var _selection_portrait: Control
var _selection_health: ProgressBar
var _hero_health: ProgressBar
var _hero_experience: ProgressBar
var _enemy_cards_row: HBoxContainer
var _game_menu_panel: PanelContainer
var _menu_button: Button
var _production_toggle_button: Button
var _production_visible := false
var _camera_input: RefCounted
var _pointer_inside_window := false


func _ready() -> void:
	# Explicit CJK-capable system fallbacks prevent new Chinese objective text
	# from being shaped as missing glyphs by the default graybox font.
	_presentation_font = SystemFont.new()
	_presentation_font.font_names = PackedStringArray(["Arial Unicode MS", "Microsoft YaHei", "Noto Sans CJK SC", "PingFang SC", "sans-serif"])
	_session = GameSessionClass.new(GameSessionClass.DEFAULT_SEED, true, scenario_id)
	_snapshot = _session.get_snapshot()
	_previous_snapshot = _snapshot.duplicate(true)
	_camera = BattleCameraClass.new()
	_camera_input = CameraNavigationInputClass.new()
	_world_clip = Control.new()
	_world_clip.name = "BattleViewport"
	_world_clip.clip_contents = true
	_world_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_world_clip)
	_world_canvas = Node2D.new()
	_world_canvas.name = "BattleWorldCanvas"
	_world_canvas.draw.connect(_draw_world)
	_world_clip.add_child(_world_canvas)
	_build_hud()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	get_window().mouse_entered.connect(func() -> void: _pointer_inside_window = true)
	get_window().mouse_exited.connect(func() -> void: _pointer_inside_window = false)
	get_window().focus_exited.connect(func() -> void: _camera_dragging = false)
	_pointer_inside_window = get_viewport_rect().has_point(get_viewport().get_mouse_position())
	_ensure_selection()
	_layout_hud()
	_restore_initial_camera()
	_sync_hud()
	queue_redraw()


func _process(delta: float) -> void:
	_advance_camera_navigation(delta)
	_age_combat_effects(delta)
	var next_snapshot: Dictionary = _session.update(delta)
	var old_tick := int(_snapshot.get("tick", -1))
	var next_tick := int(next_snapshot.get("tick", -1))
	if next_tick != old_tick:
		var old_camp: Dictionary = (_snapshot.get("economy", {}) as Dictionary).get("construction", {})
		var next_camp: Dictionary = (next_snapshot.get("economy", {}) as Dictionary).get("construction", {})
		_previous_snapshot = _snapshot
		_snapshot = next_snapshot
		_observe_combat_changes(_previous_snapshot, _snapshot)
		_ensure_selection()
		_sync_hud()
		if str(old_camp.get("state", "")) != "BUILT" and str(next_camp.get("state", "")) == "BUILT":
			_set_feedback("军需工坊完工 · 招募速度 +25%", true)
		queue_redraw()
	else:
		_snapshot = next_snapshot
	_interpolation_alpha = _session.get_interpolation_alpha()
	if _interpolation_alpha < 1.0:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			if mouse_event.pressed:
				_camera_dragging = _is_ground_surface(mouse_event.position)
			else:
				_camera_dragging = false
			get_viewport().set_input_as_handled()
			return
		if mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and _is_ground_surface(mouse_event.position):
			_camera.zoom_at(mouse_event.position, 1.25 if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8)
			_camera_changed()
			get_viewport().set_input_as_handled()
			return
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_handle_arena_tap(mouse_event.position)
	elif event is InputEventMouseMotion and _camera_dragging:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE) == 0:
			_camera_dragging = false
			return
		_camera.pan_screen(motion.relative)
		_camera_changed()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_handle_arena_tap(touch_event.position)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	_ui_root = Control.new()
	_ui_root.name = "HudRoot"
	var presentation_theme := Theme.new()
	presentation_theme.default_font = _presentation_font
	_ui_root.theme = presentation_theme
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui_root)

	_top_panel = PanelContainer.new()
	_top_panel.name = "TopPanel"
	_top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.075, 0.082, 0.97), COLOR_FIELD_EDGE, 8))
	_ui_root.add_child(_top_panel)

	var top_margin := MarginContainer.new()
	_set_margins(top_margin, 10, 0, 10, 0)
	_top_panel.add_child(top_margin)
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 12)
	top_margin.add_child(heading_row)
	var title := Label.new()
	title.text = "WARBEAST"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	heading_row.add_child(title)
	_resource_label = Label.new()
	_resource_label.name = "ResourceStatus"
	_resource_label.custom_minimum_size = Vector2(174, 0)
	_resource_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_resource_label.mouse_force_pass_scroll_events = false
	_resource_label.add_theme_font_size_override("font_size", 13)
	_resource_label.add_theme_color_override("font_color", COLOR_TEXT)
	heading_row.add_child(_resource_label)
	_spring_status_label = Label.new()
	_spring_status_label.name = "SpringStatus"
	_spring_status_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_spring_status_label.mouse_force_pass_scroll_events = false
	_spring_status_label.add_theme_font_size_override("font_size", 12)
	_spring_status_label.add_theme_color_override("font_color", COLOR_ACCENT)
	heading_row.add_child(_spring_status_label)
	_build_objective_hud()
	_base_status_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(_base_status_row)
	_status_label = Label.new()
	_status_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_status_label.mouse_force_pass_scroll_events = false
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", COLOR_MUTED)
	heading_row.add_child(_status_label)
	_start_battle_button = Button.new()
	_start_battle_button.name = "StartBattleButton"
	_start_battle_button.text = "开始交战"
	_start_battle_button.custom_minimum_size = Vector2(88, 30)
	_start_battle_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_start_battle_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(_start_battle_button, true)
	_start_battle_button.pressed.connect(_on_start_battle_pressed)
	heading_row.add_child(_start_battle_button)
	_menu_button = Button.new()
	_menu_button.name = "GameMenuButton"
	_menu_button.text = "菜单"
	_menu_button.custom_minimum_size = Vector2(50, 30)
	_menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_menu_button.focus_mode = Control.FOCUS_NONE
	_menu_button.toggle_mode = true
	_style_command_button(_menu_button)
	_menu_button.pressed.connect(func() -> void: _set_menu_visible(_menu_button.button_pressed))
	heading_row.add_child(_menu_button)

	_bottom_panel = PanelContainer.new()
	_bottom_panel.name = "CommandPanel"
	_bottom_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.075, 0.082, 0.98), COLOR_FIELD_EDGE, 8))
	_ui_root.add_child(_bottom_panel)

	var bottom_margin := MarginContainer.new()
	# A dedicated left HUD slot keeps the minimap off economic/battle ground.
	_set_margins(bottom_margin, 210, 5, 10, 5)
	_bottom_panel.add_child(bottom_margin)
	var dock_row := HBoxContainer.new()
	dock_row.add_theme_constant_override("separation", 12)
	bottom_margin.add_child(dock_row)
	var selection_column := VBoxContainer.new()
	selection_column.name = "SelectionColumn"
	selection_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_column.add_theme_constant_override("separation", 5)
	dock_row.add_child(selection_column)
	var selected_row := HBoxContainer.new()
	selected_row.add_theme_constant_override("separation", 10)
	selection_column.add_child(selected_row)
	_selection_portrait = Control.new()
	_selection_portrait.name = "SelectedWarbandPortrait"
	_selection_portrait.custom_minimum_size = Vector2(58, 56)
	_selection_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_portrait.draw.connect(_draw_selection_portrait)
	selected_row.add_child(_selection_portrait)
	var facts_column := VBoxContainer.new()
	facts_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facts_column.add_theme_constant_override("separation", 2)
	selected_row.add_child(facts_column)
	_warband_readout_label = Label.new()
	_warband_readout_label.name = "WarbandReadout"
	_warband_readout_label.custom_minimum_size = Vector2(0, 35)
	_warband_readout_label.clip_text = true
	_warband_readout_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_warband_readout_label.add_theme_font_size_override("font_size", 13)
	_warband_readout_label.add_theme_color_override("font_color", COLOR_TEXT)
	facts_column.add_child(_warband_readout_label)
	_selection_health = _hud_progress(facts_column, "SelectedWarbandHealth", COLOR_SUCCESS, 5)
	var hero_bars := HBoxContainer.new()
	hero_bars.add_theme_constant_override("separation", 6)
	facts_column.add_child(hero_bars)
	_hero_health = _hud_progress(hero_bars, "SelectedHeroHealth", COLOR_PLAYER, 4)
	_hero_experience = _hud_progress(hero_bars, "SelectedHeroExperience", COLOR_ACCENT, 4)
	_cards_row = HBoxContainer.new()
	_cards_row.name = "WarbandCards"
	_cards_row.add_theme_constant_override("separation", 5)
	selection_column.add_child(_cards_row)
	_instruction_label = Label.new()
	_instruction_label.name = "OperationHelp"
	_instruction_label.visible = false
	_instruction_label.text = "选战团后点击地面移动、敌军集火；方向键或鼠标触边移动镜头"
	_instruction_label.add_theme_font_size_override("font_size", 13)
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction_label.add_theme_color_override("font_color", COLOR_TEXT)
	_feedback_label = Label.new()
	_feedback_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_feedback_label.mouse_force_pass_scroll_events = false
	_feedback_label.text = "准备就绪"
	_feedback_label.custom_minimum_size = Vector2(0, 21)
	_feedback_label.clip_text = true
	_feedback_label.add_theme_font_size_override("font_size", 11)
	_feedback_label.add_theme_color_override("font_color", COLOR_MUTED)
	selection_column.add_child(_feedback_label)
	var commands_column := VBoxContainer.new()
	commands_column.name = "CommandColumn"
	commands_column.custom_minimum_size = Vector2(320, 0)
	commands_column.add_theme_constant_override("separation", 5)
	dock_row.add_child(commands_column)
	var command_row := HBoxContainer.new()
	command_row.add_theme_constant_override("separation", 5)
	commands_column.add_child(command_row)

	for formation in FORMATIONS:
		var button := Button.new()
		button.name = "%sButton" % formation.to_pascal_case()
		button.text = _formation_short_label(formation)
		button.custom_minimum_size = Vector2(68, 30)
		button.tooltip_text = "整团阵型 · " + _formation_label(formation)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_command_button(button)
		button.pressed.connect(_on_formation_pressed.bind(formation))
		command_row.add_child(button)
		_formation_buttons[formation] = button
	var army_row := HBoxContainer.new()
	army_row.add_theme_constant_override("separation", 5)
	commands_column.add_child(army_row)

	_auto_engage_button = Button.new()
	_auto_engage_button.name = "AutoEngageButton"
	_auto_engage_button.text = "全军迎敌"
	_auto_engage_button.custom_minimum_size = Vector2(100, 30)
	_auto_engage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_engage_button.focus_mode = Control.FOCUS_NONE
	_auto_engage_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_command_button(_auto_engage_button, true)
	_auto_engage_button.pressed.connect(_on_auto_engage_pressed)
	army_row.add_child(_auto_engage_button)
	_auto_defend_button = Button.new()
	_auto_defend_button.name = "AutoDefendButton"
	_auto_defend_button.text = "全军回防"
	_auto_defend_button.custom_minimum_size = Vector2(100, 30)
	_auto_defend_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_defend_button.focus_mode = Control.FOCUS_NONE
	_auto_defend_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_command_button(_auto_defend_button, true)
	_auto_defend_button.pressed.connect(_on_auto_defend_pressed)
	_auto_defend_button.tooltip_text = "全部存活战团切为稳阵，实际返回己方守备位；途中正常还击，不传送或回血"
	army_row.add_child(_auto_defend_button)

	_retreat_button = Button.new()
	_retreat_button.name = "RetreatButton"
	_retreat_button.text = "单团撤退"
	_retreat_button.custom_minimum_size = Vector2(100, 30)
	_retreat_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_retreat_button.focus_mode = Control.FOCUS_NONE
	_retreat_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_retreat_button.add_theme_color_override("font_color", Color(1.0, 0.75, 0.68, 1.0))
	_retreat_button.add_theme_stylebox_override("normal", _panel_style(Color(0.22, 0.08, 0.07, 1.0), Color(0.50, 0.18, 0.14, 1.0), 6))
	_retreat_button.add_theme_stylebox_override("hover", _panel_style(Color(0.32, 0.11, 0.08, 1.0), COLOR_AI, 6))
	_retreat_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.14, 0.05, 0.04, 1.0), COLOR_AI, 6))
	_retreat_button.pressed.connect(_on_retreat_pressed)
	army_row.add_child(_retreat_button)
	var management_row := HBoxContainer.new()
	management_row.add_theme_constant_override("separation", 5)
	commands_column.add_child(management_row)
	var economy_button := Button.new()
	economy_button.name = "CameraEconomyButton"
	economy_button.text = "经营"
	economy_button.custom_minimum_size = Vector2(100, 30)
	economy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	economy_button.toggle_mode = true
	economy_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(economy_button)
	economy_button.pressed.connect(_on_camera_action.bind("economy"))
	management_row.add_child(economy_button)
	_navigation_buttons["economy"] = economy_button
	_production_toggle_button = Button.new()
	_production_toggle_button.name = "RecruitmentToggleButton"
	_production_toggle_button.text = "招募"
	_production_toggle_button.custom_minimum_size = Vector2(100, 30)
	_production_toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_production_toggle_button.toggle_mode = true
	_production_toggle_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(_production_toggle_button)
	_production_toggle_button.pressed.connect(func() -> void: _set_production_visible(_production_toggle_button.button_pressed))
	management_row.add_child(_production_toggle_button)

	_camp_toggle_button = Button.new()
	_camp_toggle_button.name = "CampToggleButton"
	_camp_toggle_button.text = "建设"
	_camp_toggle_button.custom_minimum_size = Vector2(100, 30)
	_camp_toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_camp_toggle_button.toggle_mode = true
	_camp_toggle_button.focus_mode = Control.FOCUS_NONE
	_camp_toggle_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_command_button(_camp_toggle_button)
	_camp_toggle_button.pressed.connect(_on_camp_toggle_pressed)
	management_row.add_child(_camp_toggle_button)

	_build_economy_panel()
	_build_production_panel()
	_build_navigation_hud()
	commands_column.add_child(_navigation_row)
	# Popups must follow fixed navigation in both drawing and GUI pick order.
	# Their top edge can overlap this row at the reference resolution.
	_build_camp_panel()
	_build_tactical_map_panel()
	_build_game_menu()

	_outcome_panel = PanelContainer.new()
	_outcome_panel.name = "OutcomePanel"
	_outcome_panel.visible = false
	_outcome_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_outcome_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.05, 0.055, 0.98), COLOR_ACCENT, 12, 2))
	_ui_root.add_child(_outcome_panel)
	var outcome_margin := MarginContainer.new()
	_set_margins(outcome_margin, 28, 22, 28, 22)
	_outcome_panel.add_child(outcome_margin)
	var outcome_vbox := VBoxContainer.new()
	outcome_vbox.add_theme_constant_override("separation", 14)
	outcome_margin.add_child(outcome_vbox)
	var outcome_kicker := Label.new()
	outcome_kicker.text = "战场裁定 · BATTLE RESOLVED"
	outcome_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_kicker.add_theme_font_size_override("font_size", 13)
	outcome_kicker.add_theme_color_override("font_color", COLOR_MUTED)
	outcome_vbox.add_child(outcome_kicker)
	_outcome_label = Label.new()
	_outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outcome_label.add_theme_font_size_override("font_size", 30)
	_outcome_label.add_theme_color_override("font_color", COLOR_ACCENT)
	outcome_vbox.add_child(_outcome_label)
	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "重新开始 · RESTART"
	_restart_button.custom_minimum_size = Vector2(300, 50)
	_restart_button.focus_mode = Control.FOCUS_NONE
	_restart_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_command_button(_restart_button, true)
	_restart_button.pressed.connect(_on_restart_pressed)
	outcome_vbox.add_child(_restart_button)
	_objective_reason_label = Label.new()
	_objective_reason_label.name = "ObjectiveOutcomeReason"
	_objective_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_reason_label.add_theme_font_size_override("font_size", 12)
	_objective_reason_label.add_theme_color_override("font_color", COLOR_MUTED)
	outcome_vbox.add_child(_objective_reason_label)


func _build_navigation_hud() -> void:
	_navigation_row = HBoxContainer.new()
	_navigation_row.name = "CameraNavigation"
	_navigation_row.add_theme_constant_override("separation", 5)
	_navigation_row.mouse_filter = Control.MOUSE_FILTER_STOP
	for definition: Array in [
		["overview", "总览", 48], ["zoom_out", "−", 25], ["zoom_in", "+", 25],
		["selected", "定位战团", 68], ["home", "我方据点", 68],
	]:
		var action := str(definition[0])
		var button := Button.new()
		button.name = "Camera" + action.to_pascal_case() + "Button"
		button.text = str(definition[1])
		button.custom_minimum_size = Vector2(float(definition[2]), 30)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_force_pass_scroll_events = false
		_style_command_button(button)
		button.add_theme_stylebox_override("normal", _compact_button_style(Color(0.12, 0.16, 0.16), COLOR_FIELD_EDGE))
		button.add_theme_stylebox_override("hover", _compact_button_style(Color(0.18, 0.24, 0.22), COLOR_ACCENT))
		button.add_theme_stylebox_override("pressed", _compact_button_style(Color(0.09, 0.14, 0.13), COLOR_ACCENT))
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_on_camera_action.bind(action))
		_navigation_row.add_child(button)
		_navigation_buttons[action] = button
		if action == "zoom_out":
			_camera_zoom_label = Label.new()
			_camera_zoom_label.custom_minimum_size = Vector2(40, 30)
			_camera_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_camera_zoom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_camera_zoom_label.add_theme_font_size_override("font_size", 12)
			_navigation_row.add_child(_camera_zoom_label)
	_minimap = BattleMinimapClass.new()
	_minimap.name = "BattleMinimap"
	_minimap.size = Vector2(188, 136)
	_minimap.show_expansion = false
	_minimap.location_requested.connect(_on_minimap_location)
	_ui_root.add_child(_minimap)


func _build_tactical_map_panel() -> void:
	_expanded_map_panel = Panel.new()
	_expanded_map_panel.name = "ExpandedTacticalMap"
	_expanded_map_panel.visible = false
	_expanded_map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_expanded_map_panel.mouse_force_pass_scroll_events = false
	_expanded_map_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.055, 0.057, 0.99), COLOR_ACCENT, 6, 2))
	_ui_root.add_child(_expanded_map_panel)
	_expanded_map_title = Label.new()
	_expanded_map_title.name = "TacticalMapTitle"
	_expanded_map_title.position = Vector2(12, 4)
	_expanded_map_title.size = Vector2(600, 44)
	_expanded_map_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_expanded_map_title.mouse_filter = Control.MOUSE_FILTER_STOP
	_expanded_map_title.mouse_force_pass_scroll_events = false
	_expanded_map_title.add_theme_font_size_override("font_size", 16)
	_expanded_map_title.add_theme_color_override("font_color", COLOR_ACCENT)
	_expanded_map_panel.add_child(_expanded_map_title)
	var close := Button.new()
	close.name = "CloseTacticalMapButton"
	close.text = "×"
	close.position = Vector2(624, 4)
	close.size = Vector2(44, 44)
	close.custom_minimum_size = Vector2(44, 44)
	close.focus_mode = Control.FOCUS_NONE
	close.mouse_force_pass_scroll_events = false
	_style_command_button(close)
	close.pressed.connect(_set_tactical_map_visible.bind(false))
	_expanded_map_panel.add_child(close)
	_expanded_map = BattleMinimapClass.new()
	_expanded_map.name = "ExpandedMapSurface"
	_expanded_map.show_caption = false
	_expanded_map.show_expansion = false
	_expanded_map.position = Vector2(6, 46)
	_expanded_map.size = Vector2(668, 340)
	_expanded_map.location_requested.connect(_on_minimap_location)
	_expanded_map_panel.add_child(_expanded_map)


func _build_game_menu() -> void:
	_game_menu_panel = PanelContainer.new()
	_game_menu_panel.name = "GameMenuPanel"
	_game_menu_panel.visible = false
	_game_menu_panel.mouse_force_pass_scroll_events = false
	_game_menu_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.06, 0.07, 0.99), COLOR_ACCENT, 5, 2))
	_ui_root.add_child(_game_menu_panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 8, 6, 8, 6)
	_game_menu_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := Label.new()
	title.text = "战局菜单"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	heading.add_child(title)
	var close := _drawer_close_button("CloseMenuButton", _set_menu_visible.bind(false))
	heading.add_child(close)
	_tactical_map_button = Button.new()
	_tactical_map_button.name = "TacticalMapButton"
	_tactical_map_button.text = "查看全图"
	_tactical_map_button.custom_minimum_size = Vector2(0, 34)
	_tactical_map_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(_tactical_map_button)
	_tactical_map_button.pressed.connect(_on_tactical_map_pressed)
	column.add_child(_tactical_map_button)
	_map_switch_button = Button.new()
	_map_switch_button.name = "SwitchScenarioButton"
	_map_switch_button.custom_minimum_size = Vector2(0, 34)
	_map_switch_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(_map_switch_button)
	_map_switch_button.pressed.connect(_on_switch_scenario_pressed)
	column.add_child(_map_switch_button)
	var restart := Button.new()
	restart.name = "MenuRestartButton"
	restart.text = "本图重新开始"
	restart.custom_minimum_size = Vector2(0, 34)
	restart.focus_mode = Control.FOCUS_NONE
	_style_command_button(restart)
	restart.pressed.connect(_on_restart_pressed)
	column.add_child(restart)
	var enemy_title := Label.new()
	enemy_title.text = "敌方战团 · 公开情报"
	enemy_title.add_theme_font_size_override("font_size", 12)
	enemy_title.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(enemy_title)
	_enemy_cards_row = HBoxContainer.new()
	_enemy_cards_row.name = "EnemyWarbandCards"
	_enemy_cards_row.add_theme_constant_override("separation", 6)
	column.add_child(_enemy_cards_row)
	column.add_child(_instruction_label)
	_instruction_label.visible = true
	_instruction_label.custom_minimum_size = Vector2(288, 92)
	_instruction_label.add_theme_font_size_override("font_size", 11)
	_instruction_label.add_theme_color_override("font_color", COLOR_MUTED)


func _drawer_close_button(node_name: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = "×"
	button.custom_minimum_size = Vector2(30, 30)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_force_pass_scroll_events = false
	_style_command_button(button)
	button.pressed.connect(callback)
	return button


func _hud_progress(parent: Control, node_name: String, color: Color, height: float) -> ProgressBar:
	var progress := ProgressBar.new()
	progress.name = node_name
	progress.custom_minimum_size = Vector2(0, height)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_STOP
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.015, 0.025, 0.025)
	back.set_corner_radius_all(2)
	progress.add_theme_stylebox_override("background", back)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	progress.add_theme_stylebox_override("fill", fill)
	parent.add_child(progress)
	return progress


func _on_tactical_map_pressed() -> void:
	_set_tactical_map_visible(not _expanded_map_panel.visible)


func _set_tactical_map_visible(visible: bool) -> void:
	_camera_dragging = false
	if visible:
		_close_observational_surfaces()
	_expanded_map_panel.visible = visible
	_camera_changed()


func _on_switch_scenario_pressed() -> void:
	_switch_scenario(BattleScenarioCatalogClass.TRAINING_ID if _session.get_scenario_id() == BattleScenarioCatalogClass.FRONTIER_ID else BattleScenarioCatalogClass.FRONTIER_ID)


func _switch_scenario(target_id: String) -> Dictionary:
	var result: Dictionary = _session.switch_scenario(target_id)
	if not bool(result.get("accepted", false)):
		_set_feedback("地图未切换 · %s" % str(result.get("error", "UNKNOWN")), false)
		return result
	scenario_id = _session.get_scenario_id()
	_reset_visual_state(_session.get_snapshot())
	_set_feedback("已切换%s并重开新局" % str((_snapshot.get("scenario", {}) as Dictionary).get("display_name", target_id)), true)
	return result


func _restore_initial_camera() -> void:
	var scenario: Dictionary = _snapshot.get("scenario", {})
	_camera.fit_all()
	var initial_zoom := float(scenario.get("initial_zoom", 1.0))
	if initial_zoom > 1.0:
		_camera.zoom_at(_field_rect().get_center(), initial_zoom)
		var base := _base_for_side(SIDE_PLAYER)
		if base.has("position"):
			_camera.center_on(Vector2(base["position"]))
	_camera_changed()


func _on_camera_action(action: String) -> void:
	match action:
		"overview": _camera.fit_all()
		"zoom_out": _camera.zoom_at(_field_rect().get_center(), 0.8)
		"zoom_in": _camera.zoom_at(_field_rect().get_center(), 1.25)
		"selected":
			var selected := _warband_by_id(_selected_warband_id)
			if not selected.is_empty():
				_camera.center_on(Vector2(selected["anchor"]))
		"home":
			var base := _base_for_side(SIDE_PLAYER)
			if not base.is_empty():
				_camera.center_on(Vector2(base["position"]))
		"economy":
			_set_economy_visible(not _economy_visible)
		"up": _camera.pan_screen(Vector2(0, 96))
		"left": _camera.pan_screen(Vector2(96, 0))
		"down": _camera.pan_screen(Vector2(0, -96))
		"right": _camera.pan_screen(Vector2(-96, 0))
	_camera_changed()


func _on_minimap_location(world_position: Vector2) -> void:
	_camera.center_on(world_position)
	_camera_changed()


func _camera_changed() -> void:
	_camera_zoom_label.text = "%d%%" % roundi(_camera.get_zoom() * 100.0)
	(_navigation_buttons["economy"] as Button).set_pressed_no_signal(_economy_visible)
	_minimap.set_view(_snapshot, _camera)
	if is_instance_valid(_expanded_map):
		_expanded_map.set_view(_snapshot, _camera)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_pointer_inside_window = get_viewport_rect().has_point((event as InputEventMouseMotion).position)
	# Release is observed before GUI routing, even if a drag ends over a HUD.
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		_pointer_inside_window = get_viewport_rect().has_point(mouse_event.position)
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE and not mouse_event.pressed:
			_camera_dragging = false
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		_close_observational_surfaces()
		get_viewport().set_input_as_handled()


func _camera_key_direction() -> Vector2:
	return Vector2(
		float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
	)


func _advance_camera_navigation(delta: float) -> void:
	var pointer := get_viewport().get_mouse_position()
	if _camera_input.advance(_camera, delta, _camera_key_direction(), pointer, get_viewport_rect(), _field_rect(), _camera_input_context(pointer)):
		_camera_changed()


func _camera_input_context(pointer: Vector2) -> Dictionary:
	var focus_owner := get_viewport().gui_get_focus_owner()
	var keyboard_edit := focus_owner is LineEdit or focus_owner is TextEdit or focus_owner is SpinBox or focus_owner is OptionButton
	var option_open := _transfer_from.get_popup().visible or _transfer_to.get_popup().visible
	return {
		"window_focused": get_window().has_focus(),
		"pointer_inside_window": _pointer_inside_window,
		"blocked": _game_menu_panel.visible or _expanded_map_panel.visible or option_open,
		"dragging": _camera_dragging,
		"keyboard_blocked": keyboard_edit or option_open,
		"pointer_blocked": _is_camera_pointer_occluded(pointer),
	}


func _is_camera_pointer_occluded(pointer: Vector2) -> bool:
	# Camera edge navigation deliberately includes the field's eight-pixel
	# command padding, and does not require actual projected ground coverage.
	for control: Control in [_top_panel, _bottom_panel, _minimap, _economy_panel, _production_panel, _camp_panel, _game_menu_panel, _expanded_map_panel, _outcome_panel]:
		if control.visible and control.get_global_rect().has_point(pointer):
			return true
	return false


func _build_objective_hud() -> void:
	_base_status_row = HBoxContainer.new()
	_base_status_row.name = "BaseStatusRow"
	_base_status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_status_row.add_theme_constant_override("separation", 16)
	_player_base_label = Label.new()
	_player_base_label.name = "PlayerBaseStatus"
	_enemy_base_label = Label.new()
	_enemy_base_label.name = "EnemyBaseStatus"
	for label: Label in [_player_base_label, _enemy_base_label]:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_force_pass_scroll_events = false
		label.add_theme_font_size_override("font_size", 11)
		_base_status_row.add_child(label)
	_enemy_base_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _build_economy_panel() -> void:
	_economy_panel = PanelContainer.new()
	_economy_panel.name = "EconomyPanel"
	_economy_panel.visible = false
	_economy_panel.mouse_force_pass_scroll_events = false
	_economy_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.075, 0.082, 0.97), COLOR_FIELD_EDGE, 8))
	_ui_root.add_child(_economy_panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 6, 8, 6, 8)
	_economy_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := Label.new()
	heading.text = "勤务调配"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", COLOR_ACCENT)
	header.add_child(heading)
	header.add_child(_drawer_close_button("CloseEconomyButton", _set_economy_visible.bind(false)))
	_economy_summary_label = Label.new()
	_economy_summary_label.add_theme_font_size_override("font_size", 11)
	_economy_summary_label.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(_economy_summary_label)
	for role in ["FOOD", "MATERIAL", "CONSTRUCTION_REPAIR"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		column.add_child(row)
		var label := Label.new()
		label.custom_minimum_size = Vector2(96, 35)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", COLOR_TEXT)
		row.add_child(label)
		_economy_row_labels[role] = label
		var minus_button := Button.new()
		minus_button.name = "%sMinusButton" % role.to_pascal_case()
		minus_button.text = "−"
		minus_button.custom_minimum_size = Vector2(27, 30)
		minus_button.focus_mode = Control.FOCUS_NONE
		_style_command_button(minus_button)
		minus_button.pressed.connect(_on_economy_delta_pressed.bind(role, -1))
		row.add_child(minus_button)
		_economy_minus_buttons[role] = minus_button
		var plus_button := Button.new()
		plus_button.name = "%sPlusButton" % role.to_pascal_case()
		plus_button.text = "+"
		plus_button.custom_minimum_size = Vector2(27, 30)
		plus_button.focus_mode = Control.FOCUS_NONE
		_style_command_button(plus_button)
		plus_button.pressed.connect(_on_economy_delta_pressed.bind(role, 1))
		row.add_child(plus_button)
		_economy_plus_buttons[role] = plus_button
	_economy_stock_label = Label.new()
	_economy_stock_label.add_theme_font_size_override("font_size", 11)
	_economy_stock_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	column.add_child(_economy_stock_label)
	var transfer_title := Label.new()
	transfer_title.text = "无预备人手时，直接调拨 1 人"
	transfer_title.add_theme_font_size_override("font_size", 10)
	transfer_title.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(transfer_title)
	var transfer_row := HBoxContainer.new()
	transfer_row.add_theme_constant_override("separation", 2)
	column.add_child(transfer_row)
	_transfer_from = OptionButton.new()
	_transfer_to = OptionButton.new()
	for role in ["FOOD", "MATERIAL", "CONSTRUCTION_REPAIR"]:
		_transfer_from.add_item(_role_short_label(role))
		_transfer_to.add_item(_role_short_label(role))
	_transfer_from.custom_minimum_size = Vector2(50, 29)
	_transfer_to.custom_minimum_size = Vector2(50, 29)
	_transfer_from.add_theme_font_size_override("font_size", 10)
	_transfer_to.add_theme_font_size_override("font_size", 10)
	transfer_row.add_child(_transfer_from)
	transfer_row.add_child(_transfer_to)
	_transfer_to.select(1)
	_transfer_button = Button.new()
	_transfer_button.name = "TransferWorkerButton"
	_transfer_button.text = "→"
	_transfer_button.custom_minimum_size = Vector2(32, 29)
	_transfer_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(_transfer_button)
	_transfer_button.pressed.connect(_on_transfer_pressed)
	transfer_row.add_child(_transfer_button)


func _build_production_panel() -> void:
	_production_panel = PanelContainer.new()
	_production_panel.name = "ProductionPanel"
	_production_panel.visible = false
	_production_panel.mouse_force_pass_scroll_events = false
	_production_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.075, 0.082, 0.97), COLOR_FIELD_EDGE, 8))
	_ui_root.add_child(_production_panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 5, 7, 5, 7)
	_production_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := Label.new()
	heading.text = "营地招募"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", COLOR_ACCENT)
	header.add_child(heading)
	header.add_child(_drawer_close_button("CloseProductionButton", _set_production_visible.bind(false)))
	_production_summary_label = _production_label(column, COLOR_MUTED)
	_production_cost_label = _production_label(column, COLOR_TEXT)
	_production_book_label = _production_label(column, COLOR_TEXT)
	_production_reserved_label = _production_label(column, COLOR_MUTED)
	_production_available_label = _production_label(column, COLOR_SUCCESS)
	_production_enqueue_button = Button.new()
	_production_enqueue_button.name = "EnqueueWorkerButton"
	_production_enqueue_button.text = "招募勤务民 +1"
	_production_enqueue_button.custom_minimum_size = Vector2(0, 33)
	_production_enqueue_button.focus_mode = Control.FOCUS_NONE
	_production_enqueue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_command_button(_production_enqueue_button, true)
	_production_enqueue_button.pressed.connect(_on_enqueue_worker_pressed)
	column.add_child(_production_enqueue_button)
	_production_guard_button = Button.new()
	_production_guard_button.name = "EnqueueHingeGuardButton"
	_production_guard_button.text = "招募合页卫 · 8 人"
	_production_guard_button.custom_minimum_size = Vector2(0, 29)
	_production_guard_button.focus_mode = Control.FOCUS_NONE
	_production_guard_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_command_button(_production_guard_button)
	_production_guard_button.pressed.connect(_on_enqueue_warband_pressed.bind(WarbandCatalogClass.HINGE_GUARD_RECIPE_ID))
	column.add_child(_production_guard_button)
	_production_crossbow_button = Button.new()
	_production_crossbow_button.name = "EnqueueBrightCrossbowButton"
	_production_crossbow_button.text = "招募明契弩列 · 8 人"
	_production_crossbow_button.custom_minimum_size = Vector2(0, 29)
	_production_crossbow_button.focus_mode = Control.FOCUS_NONE
	_production_crossbow_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_command_button(_production_crossbow_button)
	_production_crossbow_button.pressed.connect(_on_enqueue_warband_pressed.bind(WarbandCatalogClass.BRIGHT_CROSSBOW_RECIPE_ID))
	column.add_child(_production_crossbow_button)
	_production_queue_label = _production_label(column, COLOR_MUTED)
	for slot_index: int in range(3):
		var row := HBoxContainer.new()
		row.name = "ProductionSlot%02d" % slot_index
		row.custom_minimum_size = Vector2(0, 39)
		row.add_theme_constant_override("separation", 2)
		column.add_child(row)
		var item_label := Label.new()
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.add_theme_font_size_override("font_size", 10)
		item_label.add_theme_color_override("font_color", COLOR_TEXT)
		item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(item_label)
		var up_button := _production_row_button(row, "↑", "UpButton%02d" % slot_index)
		up_button.tooltip_text = "将等待项上移"
		up_button.pressed.connect(_on_reorder_worker_pressed.bind(slot_index, -1))
		var down_button := _production_row_button(row, "↓", "DownButton%02d" % slot_index)
		down_button.tooltip_text = "将等待项下移"
		down_button.pressed.connect(_on_reorder_worker_pressed.bind(slot_index, 1))
		var cancel_button := _production_row_button(row, "×", "CancelButton%02d" % slot_index)
		cancel_button.tooltip_text = "取消此项；开工后不返还成本"
		cancel_button.pressed.connect(_on_cancel_worker_pressed.bind(slot_index))
		_production_rows.append({
			"label": item_label,
			"up": up_button,
			"down": down_button,
			"cancel": cancel_button,
		})


func _build_camp_panel() -> void:
	_camp_panel = PanelContainer.new()
	_camp_panel.name = "CampPanel"
	_camp_panel.visible = false
	_camp_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.075, 0.09, 0.98), COLOR_CONSTRUCTION, 8, 2))
	_ui_root.add_child(_camp_panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 12, 10, 12, 10)
	_camp_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var heading_row := HBoxContainer.new()
	column.add_child(heading_row)
	var heading := Label.new()
	heading.text = "固定槽 · 军需工坊"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", COLOR_CONSTRUCTION)
	heading_row.add_child(heading)
	var close_button := Button.new()
	close_button.name = "CloseCampButton"
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(44, 44)
	close_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(close_button)
	close_button.pressed.connect(_on_camp_close_pressed)
	heading_row.add_child(close_button)
	_camp_status_label = _camp_label(column, COLOR_TEXT)
	_camp_cost_label = _camp_label(column, COLOR_MUTED)
	_camp_progress = ProgressBar.new()
	_camp_progress.name = "CampWorkProgress"
	_camp_progress.custom_minimum_size = Vector2(0, 18)
	_camp_progress.show_percentage = false
	column.add_child(_camp_progress)
	_camp_work_label = _camp_label(column, COLOR_TEXT)
	_camp_eta_label = _camp_label(column, COLOR_MUTED)
	_camp_benefit_label = _camp_label(column, COLOR_SUCCESS)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	_camp_build_button = Button.new()
	_camp_build_button.name = "BuildWorkshopButton"
	_camp_build_button.text = "建设工坊"
	_camp_build_button.custom_minimum_size = Vector2(130, 44)
	_camp_build_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(_camp_build_button, true)
	_camp_build_button.pressed.connect(_on_build_workshop_pressed)
	actions.add_child(_camp_build_button)
	_camp_cancel_button = Button.new()
	_camp_cancel_button.name = "CancelWorkshopButton"
	_camp_cancel_button.custom_minimum_size = Vector2(130, 44)
	_camp_cancel_button.focus_mode = Control.FOCUS_NONE
	_style_command_button(_camp_cancel_button)
	_camp_cancel_button.pressed.connect(_on_cancel_workshop_pressed)
	actions.add_child(_camp_cancel_button)
	_fortify_base_button = Button.new()
	_fortify_base_button.name = "FortifyBaseButton"
	_fortify_base_button.text = "护持统御兽 · 响%d" % NeutralSpringClass.FORTIFY_COST
	_fortify_base_button.custom_minimum_size = Vector2(0, 44)
	_fortify_base_button.focus_mode = Control.FOCUS_NONE
	_fortify_base_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_fortify_base_button.mouse_force_pass_scroll_events = false
	_style_command_button(_fortify_base_button, true)
	_fortify_base_button.pressed.connect(_on_fortify_base_pressed)
	column.add_child(_fortify_base_button)


func _camp_label(parent: Control, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _production_label(parent: Control, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _production_row_button(parent: Control, title: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = title
	button.custom_minimum_size = Vector2(24, 26)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(COLOR_MUTED, 0.45))
	button.add_theme_stylebox_override("normal", _compact_button_style(Color(0.16, 0.19, 0.18, 1.0), COLOR_FIELD_EDGE))
	button.add_theme_stylebox_override("hover", _compact_button_style(Color(0.20, 0.25, 0.22, 1.0), COLOR_ACCENT))
	button.add_theme_stylebox_override("pressed", _compact_button_style(Color(0.11, 0.15, 0.14, 1.0), COLOR_ACCENT))
	button.add_theme_stylebox_override("disabled", _compact_button_style(Color(0.08, 0.095, 0.095, 1.0), Color(0.14, 0.16, 0.15, 1.0)))
	parent.add_child(button)
	return button


func _compact_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(background, border, 4)
	style.content_margin_left = 2.0
	style.content_margin_right = 2.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


func _layout_hud() -> void:
	if not is_instance_valid(_ui_root):
		return
	var viewport_size := get_viewport_rect().size
	_top_panel.position = Vector2.ZERO
	_top_panel.size = Vector2(viewport_size.x, TOP_PANEL_HEIGHT)
	_bottom_panel.position = Vector2(0, viewport_size.y - BOTTOM_PANEL_HEIGHT)
	_bottom_panel.size = Vector2(viewport_size.x, BOTTOM_PANEL_HEIGHT)
	_economy_panel.size = Vector2(240, 300)
	_economy_panel.position = Vector2(maxf(12, viewport_size.x - 584), _bottom_panel.position.y - 308)
	_production_panel.size = Vector2(350, 418)
	_production_panel.position = Vector2(viewport_size.x - 362, _bottom_panel.position.y - 426)
	_camp_panel.size = Vector2(340, 360)
	_camp_panel.position = Vector2(viewport_size.x - 352, _bottom_panel.position.y - 368)
	_outcome_panel.size = Vector2(440, 205)
	_outcome_panel.position = (viewport_size - _outcome_panel.size) * 0.5
	var field := _field_rect()
	_world_clip.position = field.position
	_world_clip.size = field.size
	_world_canvas.position = -field.position
	_camera.configure(_session.get_arena_bounds(), field.grow(-8), float((_snapshot.get("scenario", {}) as Dictionary).get("camera_max_zoom", 2.0)))
	_minimap.position = Vector2(12, _bottom_panel.position.y + 14)
	_expanded_map_panel.position = Vector2(viewport_size.x * 0.5 - 340, TOP_PANEL_HEIGHT + (_field_rect().size.y - 392) * 0.5)
	_expanded_map_panel.size = Vector2(680, 392)
	_game_menu_panel.size = Vector2(340, 416)
	_game_menu_panel.position = Vector2(viewport_size.x - 352, TOP_PANEL_HEIGHT + 8)
	_camera_changed()


func _sync_hud() -> void:
	_camera_changed()
	_ensure_warband_cards()
	var tick := int(_snapshot.get("tick", 0))
	var outcome := str(_snapshot.get("outcome", OUTCOME_ONGOING))
	var player_living := _living_count_for_side(SIDE_PLAYER)
	var ai_living := _living_count_for_side(SIDE_AI)
	var phase := str(_snapshot.get("phase", GameSimulationClass.PHASE_BATTLE))
	var phase_label := "筹备" if phase == GameSimulationClass.PHASE_PREPARATION else "交战"
	var scenario: Dictionary = _snapshot.get("scenario", {})
	_expanded_map_title.text = "战术地图 · %s · 公开" % ("前线" if str(scenario.get("id", "")) == BattleScenarioCatalogClass.FRONTIER_ID else "训练场")
	_map_switch_button.text = "切到训练场并重开" if _session.get_scenario_id() == BattleScenarioCatalogClass.FRONTIER_ID else "切到前线并重开"
	_map_switch_button.tooltip_text = "明确切换地图并开始同种子新局；清空现有战团发展、资源、响泉、经验及对局进度。不是在现有对局上扩缩地图。"
	_status_label.text = "%s · %02d:%02d" % [phase_label, tick / GameSimulationClass.TICK_HZ / 60, (tick / GameSimulationClass.TICK_HZ) % 60]
	_status_label.tooltip_text = "友军存活%d · 敌军存活%d\n模拟时间 %.1f 秒；筹备期间可经营与计划整团行军。" % [player_living, ai_living, float(tick) / GameSimulationClass.TICK_HZ]
	_sync_spring_hud(phase, outcome)
	_instruction_label.text = "方向键 / 鼠标触边：移动镜头\n滚轮：缩放 · 中键拖动 · 小地图：定位\n点我方士兵/卡片选整团，点地面移动，点敌方集火。\n免费救援：两团8秒；守撤离圈30秒。\n" + TacticalReadoutClass.objective_advice(_snapshot)
	var readout: Dictionary = TacticalReadoutClass.project_warband(_snapshot, _selected_warband_id)
	_warband_readout_label.text = "暂无存活战团\n据点正常时可招募反攻"
	_warband_readout_label.tooltip_text = "本地事实 · 无存活战团；据点正常时可招募反攻"
	_selection_health.value = 0
	_hero_health.visible = false
	_hero_experience.visible = false
	if not readout.is_empty():
		var selected := _warband_by_id(_selected_warband_id)
		_warband_readout_label.text = "%s %s · %d/%d · HP%d/%d · %s\n%s · 就位%d/%d · %s" % [
			_warband_type_label(str(selected.get("unit_type", ""))), TacticalReadoutClass.compact_name(_selected_warband_id),
			readout["living_count"], readout["member_count"], readout["total_hp"], readout["total_max_hp"], _formation_short_label(str(selected.get("formation", "STEADY"))),
			readout["role_label"], readout["arrived_count"], readout["living_count"], _intent_label(str(selected.get("intent", "HOLD"))),
		]
		_warband_readout_label.tooltip_text = "%s · %s · %d/%d人 · 总生命%d/%d · 就位%d/%d · %s（本地事实）" % [
			TacticalReadoutClass.compact_name(_selected_warband_id), readout["role_label"], readout["living_count"], readout["member_count"],
			readout["total_hp"], readout["total_max_hp"], readout["arrived_count"], readout["living_count"], readout["status_label"],
		]
		_selection_health.max_value = maxi(1, int(readout["total_max_hp"]))
		_selection_health.value = int(readout["total_hp"])
		_selection_health.tooltip_text = "逐兵生命合计 %d/%d；各成员独立受伤，不是共享血池。" % [int(readout["total_hp"]), int(readout["total_max_hp"])]
		var hero := _hero_for_warband(_selected_warband_id)
		if not hero.is_empty():
			_warband_readout_label.text = _warband_readout_label.text.get_slice("\n", 0) + "\n%s Lv%d · HP%d/%d · %s%s" % [hero["name"], int(hero["level"]), int(hero["hp"]), int(hero["max_hp"]), _hero_xp_label(hero), " · 倒地" if str(hero["state"]) != "ACTIVE" else ""]
			_warband_readout_label.tooltip_text += " ｜ 英雄%s Lv%d %s HP%d/%d 伤害+%d%s" % [
				hero["name"], int(hero["level"]), _hero_xp_label(hero), int(hero["hp"]), int(hero["max_hp"]), int(hero["damage_bonus"]), "（倒地）" if str(hero["state"]) != "ACTIVE" else "",
			]
			_hero_health.visible = true
			_hero_health.max_value = maxi(1, int(hero["max_hp"]))
			_hero_health.value = int(hero["hp"])
			_hero_health.tooltip_text = "英雄实际成员 %s · HP%d/%d；倒地不复活、不换人。" % [hero["member_id"], int(hero["hp"]), int(hero["max_hp"])]
			_hero_experience.visible = true
			_hero_experience.max_value = maxi(1, int(hero.get("next_level_xp", int(hero["xp"]))))
			_hero_experience.value = _hero_experience.max_value if int(hero.get("next_level_xp", -1)) < 0 else int(hero["xp"])
			_hero_experience.tooltip_text = _hero_xp_label(hero) + "；经验只来自真实敌兵击倒。"
	_selection_portrait.queue_redraw()
	_sync_economy_hud(phase, outcome)
	_sync_production_hud(outcome)
	_sync_camp_hud(outcome)
	_sync_objective_hud()

	for id_value in _cards_by_id:
		var warband_id := str(id_value)
		var button := _cards_by_id[id_value] as Button
		var warband := _warband_by_id(warband_id)
		if warband.is_empty():
			button.visible = false
			continue
		var side := str(warband.get("side", "?"))
		var living := int(warband.get("living_count", 0))
		button.visible = living > 0
		var formation := str(warband.get("formation", "?"))
		var intent := str(warband.get("intent", "HOLD"))
		var unit_type := str(warband.get("unit_type", "hinge_guard"))
		var marker := "▣" if warband_id == _selected_warband_id else "◇" if unit_type == WarbandCatalogClass.BRIGHT_CROSSBOW_TYPE else "▥"
		var side_label := "友军" if side == SIDE_PLAYER else "AI"
		button.text = "%s %s %s\n%d/8 · %s" % [marker, TacticalReadoutClass.compact_name(warband_id), _warband_type_label(unit_type), living, _formation_short_label(formation)]
		button.tooltip_text = "%s %s · %s\n%d/8 · %s · %s\n%s" % [side_label, TacticalReadoutClass.compact_name(warband_id), _warband_type_label(unit_type), living, _formation_label(formation), _intent_label(intent), warband_id]
		var hero := _hero_for_warband(warband_id)
		button.add_theme_font_size_override("font_size", 10 if not hero.is_empty() else 11)
		if not hero.is_empty():
			button.text = "%s %s %s\n%s Lv%d · %s\n%d/8 · %s" % [marker, TacticalReadoutClass.compact_name(warband_id), _warband_type_label(unit_type), hero["name"], int(hero["level"]), "在场" if str(hero["state"]) == "ACTIVE" else "倒地", living, _formation_short_label(formation)]
			button.tooltip_text += "\n%s / %s · Lv%d · %s\n实际成员 %s · HP%d/%d · %s\n本团当前有效伤害+%d；基础武器值不变。\n真实敌兵击倒才增长经验；英雄倒地不换人、不复活，剩余成员仍可整团指挥。" % [
				hero["name"], hero["title"], int(hero["level"]), _hero_xp_label(hero), hero["member_id"], int(hero["hp"]), int(hero["max_hp"]), "在场" if str(hero["state"]) == "ACTIVE" else "倒地（增益停用）", int(hero["damage_bonus"]),
			]
		button.disabled = side != SIDE_PLAYER or living <= 0 or outcome != OUTCOME_ONGOING
		_style_warband_card(button, side, warband_id == _selected_warband_id)

	var selected := _warband_by_id(_selected_warband_id)
	var command_enabled := outcome == OUTCOME_ONGOING and not selected.is_empty() and int(selected.get("living_count", 0)) > 0
	var selected_formation := str(selected.get("formation", ""))
	for formation_value in _formation_buttons:
		var formation := str(formation_value)
		var formation_button := _formation_buttons[formation_value] as Button
		formation_button.disabled = not command_enabled
		formation_button.set_pressed_no_signal(command_enabled and formation == selected_formation)
	_retreat_button.disabled = not command_enabled
	_auto_engage_button.text = "全军压制" if ai_living <= 0 else "全军迎敌"
	_auto_engage_button.disabled = outcome != OUTCOME_ONGOING or player_living <= 0 or _base_for_side(SIDE_AI).is_empty()
	_auto_defend_button.disabled = outcome != OUTCOME_ONGOING or player_living <= 0 or str(_base_for_side(SIDE_PLAYER).get("state", "")) not in ["ACTIVE", "SUPPRESSED"]

	_outcome_panel.visible = outcome != OUTCOME_ONGOING
	if outcome == "PLAYER_VICTORY":
		_outcome_label.text = "指挥官，胜利"
		_outcome_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	elif outcome == "PLAYER_DEFEAT":
		_outcome_label.text = "统御兽已撤离"
		_outcome_label.add_theme_color_override("font_color", COLOR_DANGER)
	elif outcome == "DRAW":
		_outcome_label.text = "双方同时撤离 · 平局"
		_outcome_label.add_theme_color_override("font_color", COLOR_ACCENT)
	else:
		_outcome_label.text = outcome.replace("_", " ")
		_outcome_label.add_theme_color_override("font_color", COLOR_ACCENT)
	_objective_reason_label.text = "敌方统御兽撤离窗口结束" if outcome == "PLAYER_VICTORY" else "我方统御兽撤离窗口结束"
	if outcome == "DRAW":
		_objective_reason_label.text = "双方撤离期限在同一模拟 tick 到期"


func _base_for_side(side: String) -> Dictionary:
	for base: Dictionary in _snapshot.get("bases", []):
		if str(base.get("side", "")) == side:
			return base
	return {}


func _hero_for_warband(warband_id: String) -> Dictionary:
	var heroes: Dictionary = _snapshot.get("heroes", {})
	if bool(heroes.get("enabled", false)):
		for officer: Dictionary in heroes.get("officers", []):
			if str(officer.get("warband_id", "")) == warband_id:
				return officer
	return {}


func _hero_for_member(member_id: String) -> Dictionary:
	var heroes: Dictionary = _snapshot.get("heroes", {})
	if bool(heroes.get("enabled", false)):
		for officer: Dictionary in heroes.get("officers", []):
			if str(officer.get("member_id", "")) == member_id and str(officer.get("state", "")) == "ACTIVE" and int(officer.get("hp", 0)) > 0:
				return officer
	return {}


func _hero_xp_label(hero: Dictionary) -> String:
	return "XP%d · 已满级" % int(hero.get("xp", 0)) if int(hero.get("next_level_xp", -1)) < 0 else "XP%d/%d" % [int(hero.get("xp", 0)), int(hero.get("next_level_xp", 0))]


func _base_by_id(base_id: String) -> Dictionary:
	for base: Dictionary in _snapshot.get("bases", []):
		if str(base.get("id", "")) == base_id:
			return base
	return {}


func _sync_spring_hud(phase: String, outcome: String) -> void:
	var strategic: Dictionary = _snapshot.get("strategic", {})
	var spring: Dictionary = strategic.get("spring", {})
	var resonance: Dictionary = strategic.get("resonance", {})
	var owner := str(spring.get("owner", "NEUTRAL"))
	var candidate := str(spring.get("capturing_side", "NEUTRAL"))
	var ticks := int(spring.get("capture_ticks", 0))
	var required := maxi(1, int(spring.get("capture_required_ticks", NeutralSpringClass.CAPTURE_TICKS)))
	var capture := "%s夺%d%%" % [_spring_side_label(candidate), int(ticks * 100 / required)] if candidate in [SIDE_PLAYER, SIDE_AI] else "无夺取"
	var contested := bool(spring.get("contested", false))
	var blocked := bool(spring.get("income_blocked", false))
	var production := "争夺停产" if contested and blocked else "争夺" if contested else "停产" if blocked else "产出" if owner in [SIDE_PLAYER, SIDE_AI] else "待控"
	if outcome != OUTCOME_ONGOING:
		production = "终局冻结"
	elif phase != GameSimulationClass.PHASE_BATTLE:
		production = "筹备冻结"
	_spring_status_label.text = "泉%s · 响%d" % [_spring_side_label(owner), int(resonance.get(SIDE_PLAYER, 0))]
	if contested or blocked:
		_spring_status_label.text += " · 停产"
	var inside: Dictionary = spring.get("inside_counts", {})
	_spring_status_label.tooltip_text = "泉%s · %s · %s · 响我%d/敌%d\n全场公开 · 归属%s；夺取方%s，连续%d/%d tick。\n争夺%s · 敌兵阻断产出%s · 圈内实际活兵 我%d/敌%d。\n选战团后点击泉内空地：实际活兵严格超过半数入圈（8人至少5人）且无敌兵，连续4秒占领。\n已占领后每20个有效tick产响能1；任何敌兵入圈停产；不产粮材或补给。" % [
		_spring_side_label(owner), capture, production, int(resonance.get(SIDE_PLAYER, 0)), int(resonance.get(SIDE_AI, 0)),
		_spring_side_label(owner), _spring_side_label(candidate) if candidate in [SIDE_PLAYER, SIDE_AI] else "无", ticks, required,
		"是" if contested else "否", "是" if blocked else "否", int(inside.get(SIDE_PLAYER, 0)), int(inside.get(SIDE_AI, 0)),
	]
	var base := _base_for_side(SIDE_PLAYER)
	var missing := maxi(0, int(base.get("max_hp", 0)) - int(base.get("hp", 0)))
	_fortify_base_button.disabled = (
		outcome != OUTCOME_ONGOING or phase != GameSimulationClass.PHASE_BATTLE
		or str(base.get("state", "")) != "ACTIVE" or int(base.get("hp", 0)) <= 0 or missing <= 0
		or int(resonance.get(SIDE_PLAYER, 0)) < NeutralSpringClass.FORTIFY_COST
	)
	_fortify_base_button.tooltip_text = "独立响能固定消耗%d；立即恢复统御兽最多%d生命（当前缺%d）。\n不足%d生命仍付全额；仅交战中ACTIVE且受伤时可用，不需工坊。\n不复活、不治疗兵员、不改变免费救援次数或期限、不消耗粮材。" % [
		NeutralSpringClass.FORTIFY_COST, NeutralSpringClass.FORTIFY_HP, missing, NeutralSpringClass.FORTIFY_HP,
	]
	if outcome != OUTCOME_ONGOING:
		_spring_status_label.tooltip_text += "\n对局已结束，响泉与响能冻结。"
	elif phase != GameSimulationClass.PHASE_BATTLE:
		_spring_status_label.tooltip_text += "\n筹备期仅能计划行军，整个响泉经济冻结。"


func _spring_side_label(side: String) -> String:
	return "我方" if side == SIDE_PLAYER else "敌方" if side == SIDE_AI else "中立"


func _sync_objective_hud() -> void:
	for side: String in [SIDE_PLAYER, SIDE_AI]:
		var base := _base_for_side(side)
		var label := _player_base_label if side == SIDE_PLAYER else _enemy_base_label
		var name_label := "我方兽" if side == SIDE_PLAYER else "敌方兽"
		var state := str(base.get("state", "ACTIVE"))
		if state == "SUPPRESSED":
			var remaining := maxi(0, int(base.get("evacuation_deadline_tick", 0)) - int(_snapshot.get("tick", 0)))
			var rescue := "救援已用" if bool(base.get("rescue_used", false)) else "救援%.1f/8s · %d团%s" % [float(base.get("rescue_progress_ticks", 0)) / 20.0, int(base.get("rescue_eligible_warbands", 0)), "争夺" if bool(base.get("rescue_contested", false)) else ""]
			label.text = "%s受压 · 撤离%.1fs" % [name_label, float(remaining) / 20.0]
			label.tooltip_text = "%s · %s\n免费救援：两团各半数存活成员进圈，无敌兵连续8秒；每方一次。" % [label.text, rescue]
			label.add_theme_color_override("font_color", COLOR_DANGER)
		elif state == "EVACUATED":
			label.text = "%s · 已撤离" % name_label
			label.tooltip_text = label.text + "；撤离期限已经结束。"
			label.add_theme_color_override("font_color", COLOR_MUTED)
		else:
			label.text = "%s %d/%d" % [name_label, int(base.get("hp", 0)), int(base.get("max_hp", 1600))]
			label.tooltip_text = "%s · 免费救援%s\n两团各半数存活成员进圈，无敌兵连续8秒；每方一次。\n受压后30秒撤离，受压本身还不是胜负。" % [label.text, "已用" if bool(base.get("rescue_used", false)) else "可用"]
			label.add_theme_color_override("font_color", COLOR_PLAYER if side == SIDE_PLAYER else COLOR_AI)


func _sync_economy_hud(phase: String, outcome: String) -> void:
	var economy: Dictionary = _snapshot.get("economy", {})
	var targets: Dictionary = economy.get("targets", {})
	var actual: Dictionary = economy.get("actual", {})
	var stock: Dictionary = economy.get("stock", {})
	var reserve := int(targets.get("RESERVE", 0))
	var production: Dictionary = economy.get("production", {})
	var available: Dictionary = production.get("available", stock)
	var reserved: Dictionary = production.get("reserved", {})
	_resource_label.text = "粮%d  材%d  ·  勤务%d/%d  ·  队%d/3" % [int(stock.get("FOOD", 0)), int(stock.get("MATERIAL", 0)), int(economy.get("population", 6)), int(production.get("population_cap", 12)), (production.get("entries", []) as Array).size()]
	_resource_label.tooltip_text = "账面 粮%d / 材%d\n已预约 粮%d / 材%d\n可使用 粮%d / 材%d\n勤务目标/在岗在经营页；排队/取消/排序在招募页。" % [int(stock.get("FOOD", 0)), int(stock.get("MATERIAL", 0)), int(reserved.get("FOOD", 0)), int(reserved.get("MATERIAL", 0)), int(available.get("FOOD", 0)), int(available.get("MATERIAL", 0))]
	_economy_summary_label.text = "总数 %d · 预备 %d · 目标/在岗" % [int(economy.get("population", 6)), reserve]
	for role_value in _economy_row_labels:
		var role := str(role_value)
		var target_count := int(targets.get(role, 0))
		var actual_count := int(actual.get(role, 0))
		(_economy_row_labels[role_value] as Label).text = "%s %d/%d" % [_role_short_label(role), target_count, actual_count]
		(_economy_minus_buttons[role_value] as Button).disabled = target_count <= 0 or outcome != OUTCOME_ONGOING
		(_economy_plus_buttons[role_value] as Button).disabled = reserve <= 0 or outcome != OUTCOME_ONGOING
	_economy_stock_label.text = "库存  粮 %d  ·  材 %d" % [int(stock.get("FOOD", 0)), int(stock.get("MATERIAL", 0))]
	_transfer_button.disabled = outcome != OUTCOME_ONGOING
	_start_battle_button.visible = phase == GameSimulationClass.PHASE_PREPARATION and outcome == OUTCOME_ONGOING


func _sync_production_hud(outcome: String) -> void:
	var economy: Dictionary = _snapshot.get("economy", {})
	var production: Dictionary = economy.get("production", {})
	var book: Dictionary = economy.get("stock", {})
	var reserved: Dictionary = production.get("reserved", {})
	var available: Dictionary = production.get("available", {})
	var recipes: Dictionary = production.get("recipes", {})
	var cost: Dictionary = production.get("cost", {"FOOD": 2, "MATERIAL": 1})
	var population := int(production.get("active_population", economy.get("population", 6)))
	var population_cap := int(production.get("population_cap", 12))
	var slot_reservations := int(production.get("slot_reservations", 0))
	var duration_ticks := int(production.get("duration_ticks", 80))
	var effective_worker_ticks := int(production.get("effective_duration_ticks", duration_ticks))
	var entries: Array = production.get("entries", [])
	var queue_capacity := int(production.get("capacity", 3))
	var food_available := int(available.get("FOOD", int(book.get("FOOD", 0)) - int(reserved.get("FOOD", 0))))
	var material_available := int(available.get("MATERIAL", int(book.get("MATERIAL", 0)) - int(reserved.get("MATERIAL", 0))))
	var player_warbands := 0
	for warband_value in _snapshot.get("warbands", []):
		var warband: Dictionary = warband_value
		if str(warband.get("side", "")) == SIDE_PLAYER and int(warband.get("living_count", 0)) > 0:
			player_warbands += 1
	var queued_warbands := 0
	for entry_value in entries:
		var entry: Dictionary = entry_value
		if _is_warband_recipe_id(str(entry.get("recipe_id", ""))):
			queued_warbands += 1
	var warband_capacity := GameSimulationClass.MAX_PLAYER_WARBANDS
	var base_suppressed := str(_base_for_side(SIDE_PLAYER).get("state", "ACTIVE")) == "SUPPRESSED"
	_production_summary_label.text = "勤务 %d/%d · 战团 %d/%d" % [population, population_cap, player_warbands + queued_warbands, warband_capacity]
	_production_cost_label.text = "勤务 粮%d材%d · %.1f秒 · 在制%d" % [int(cost.get("FOOD", 2)), int(cost.get("MATERIAL", 1)), float(effective_worker_ticks) / float(GameSimulationClass.TICK_HZ), slot_reservations]
	_production_book_label.text = "账面    粮 %d  ·  材 %d" % [int(book.get("FOOD", 0)), int(book.get("MATERIAL", 0))]
	_production_reserved_label.text = "已预约  粮 %d  ·  材 %d" % [int(reserved.get("FOOD", 0)), int(reserved.get("MATERIAL", 0))]
	_production_available_label.text = "可使用  粮 %d  ·  材 %d" % [food_available, material_available]
	_production_queue_label.text = "队列 %d/%d · 单工位生产" % [entries.size(), queue_capacity]
	if base_suppressed:
		_production_queue_label.text = "统御兽受压 · 军事集结暂停"
	_production_enqueue_button.disabled = (
		outcome != OUTCOME_ONGOING
		or population >= population_cap
		or entries.size() >= queue_capacity
		or food_available < int(cost.get("FOOD", 2))
		or material_available < int(cost.get("MATERIAL", 1))
	)
	_production_enqueue_button.tooltip_text = _production_cost_label.text + "\n" + _production_available_label.text
	for recipe_id in [WarbandCatalogClass.HINGE_GUARD_RECIPE_ID, WarbandCatalogClass.BRIGHT_CROSSBOW_RECIPE_ID]:
		var recipe: Dictionary = recipes.get(recipe_id, WarbandCatalogClass.recipe_for_id(recipe_id))
		var recipe_cost: Dictionary = recipe.get("cost", {})
		var recipe_food := int(recipe_cost.get("FOOD", 0))
		var recipe_material := int(recipe_cost.get("MATERIAL", 0))
		var recipe_seconds := float(recipe.get("effective_duration_ticks", recipe.get("duration_ticks", 0))) / float(GameSimulationClass.TICK_HZ)
		var recipe_button := _production_guard_button if recipe_id == WarbandCatalogClass.HINGE_GUARD_RECIPE_ID else _production_crossbow_button
		recipe_button.text = "%s 8人 · 粮%d材%d · %.1f秒" % [_production_recipe_label(recipe_id), recipe_food, recipe_material, recipe_seconds]
		recipe_button.tooltip_text = recipe_button.text + "\n整团招募；八名真实成员在集结完成后出现，不传送现有部队。"
		recipe_button.disabled = (
			outcome != OUTCOME_ONGOING
			or base_suppressed
			or player_warbands + queued_warbands >= warband_capacity
			or entries.size() >= queue_capacity
			or food_available < recipe_food
			or material_available < recipe_material
		)
	var waiting_indexes: Array[int] = []
	for entry_index: int in range(entries.size()):
		if _production_is_waiting(entries[entry_index]):
			waiting_indexes.append(entry_index)
	for slot_index: int in range(_production_rows.size()):
		var row: Dictionary = _production_rows[slot_index]
		var item_label := row["label"] as Label
		var up_button := row["up"] as Button
		var down_button := row["down"] as Button
		var cancel_button := row["cancel"] as Button
		if slot_index >= entries.size():
			item_label.text = "%d  · 空" % [slot_index + 1]
			up_button.disabled = true
			down_button.disabled = true
			cancel_button.disabled = true
			continue
		var entry: Dictionary = entries[slot_index]
		var entry_id := _production_entry_id(entry)
		var short_id := entry_id.substr(maxi(0, entry_id.length() - 4))
		var state := str(entry.get("state", entry.get("status", "WAITING")))
		var entry_recipe_id := str(entry.get("recipe_id", ""))
		var entry_recipe: Dictionary = recipes.get(entry_recipe_id, {})
		var entry_cost: Dictionary = entry.get("cost", entry_recipe.get("cost", {}))
		var detail := _production_state_label(state)
		if state == "RUNNING":
			if str(entry.get("kind", "")) == "BUILDING":
				detail = "工程 %d/%d" % [int(entry.get("duration_ticks", 200)) - int(entry.get("remaining_ticks", 0)), int(entry.get("duration_ticks", 200))]
			else:
				detail = "余 %.1f秒" % [float(entry.get("effective_remaining_ticks", entry.get("remaining_ticks", 0))) / float(GameSimulationClass.TICK_HZ)]
		elif state.begins_with("BLOCKED"):
			var reason := str(entry.get("blocked_reason", entry.get("block_reason", "")))
			if not reason.is_empty():
				detail = _production_block_label(reason)
			if base_suppressed and state == "BLOCKED_DEPLOYMENT" and str(entry.get("kind", "")) == "WARBAND":
				detail = "等待统御兽救援"
		item_label.text = "%d #%s %s\n粮%d材%d · %s" % [
			slot_index + 1, short_id, _production_recipe_label(entry_recipe_id),
			int(entry_cost.get("FOOD", 0)), int(entry_cost.get("MATERIAL", 0)), detail,
		]
		var waiting_position := waiting_indexes.find(slot_index)
		up_button.disabled = outcome != OUTCOME_ONGOING or waiting_position <= 0
		down_button.disabled = outcome != OUTCOME_ONGOING or waiting_position < 0 or waiting_position >= waiting_indexes.size() - 1
		cancel_button.disabled = outcome != OUTCOME_ONGOING
		cancel_button.tooltip_text = "取消 %s；开工后不返还成本" % entry_id


func _sync_camp_hud(outcome: String) -> void:
	var economy: Dictionary = _snapshot.get("economy", {})
	var camp: Dictionary = economy.get("construction", {})
	var production: Dictionary = economy.get("production", {})
	var available: Dictionary = production.get("available", {})
	var entries: Array = production.get("entries", [])
	var state := str(camp.get("state", "EMPTY"))
	var cost: Dictionary = camp.get("cost", {"FOOD": 2, "MATERIAL": 8})
	var cost_state := str(camp.get("cost_state", ""))
	var completed := int(camp.get("work_completed", 0))
	var required := maxi(1, int(camp.get("work_required", 200)))
	var builders := int(camp.get("builders_on_site", 0))
	var eta_ticks := int(camp.get("eta_ticks", -1))
	_camp_status_label.text = _camp_state_label(state)
	_camp_status_label.add_theme_color_override("font_color", COLOR_SUCCESS if state == "BUILT" else COLOR_TEXT)
	var cost_detail := "开工后取消不退款"
	if cost_state == "RESERVED":
		cost_detail = "已预约 · 尚未扣账"
	elif cost_state == "COMMITTED_NO_REFUND":
		cost_detail = "已扣账 · 不退款"
	_camp_cost_label.text = "成本 粮%d / 材%d · %s" % [int(cost.get("FOOD", 2)), int(cost.get("MATERIAL", 8)), cost_detail]
	_camp_work_label.text = "工程 %d/%d · 现场施工 %d 人" % [completed, required, builders]
	_camp_progress.max_value = required
	_camp_progress.value = completed
	match state:
		"EMPTY":
			_camp_eta_label.text = "调配建造修复岗位即可自动施工"
		"QUEUED":
			_camp_eta_label.text = "等待前面的队列项完成"
		"BUILT":
			_camp_eta_label.text = "已完工 · 施工人手返回集结点"
		_:
			_camp_eta_label.text = "待工：请调入建造修复人手" if eta_ticks < 0 else "预计 %.1f 秒（按现场人手）" % [float(eta_ticks) / float(GameSimulationClass.TICK_HZ)]
	_camp_benefit_label.text = "生效：勤务民与战团招募 +25%" if state == "BUILT" else "完工后：勤务民与战团招募 +25%"
	_camp_build_button.text = "已建成" if state == "BUILT" else "建设工坊"
	_camp_build_button.disabled = (
		outcome != OUTCOME_ONGOING or state != "EMPTY"
		or entries.size() >= int(production.get("capacity", 3))
		or int(available.get("FOOD", 0)) < int(cost.get("FOOD", 2))
		or int(available.get("MATERIAL", 0)) < int(cost.get("MATERIAL", 8))
	)
	_camp_cancel_button.text = "取消 · 释放预约" if cost_state == "RESERVED" else "取消 · 不退款"
	_camp_cancel_button.disabled = outcome != OUTCOME_ONGOING or str(camp.get("queue_entry_id", "")).is_empty()
	_camp_toggle_button.text = "工坊已建" if state == "BUILT" else "建设"
	_camp_toggle_button.tooltip_text = "营地建设与统御兽护持\n" + _camp_state_label(state)


func _camp_state_label(state: String) -> String:
	match state:
		"EMPTY":
			return "空槽 · 可建设军需工坊"
		"QUEUED":
			return "已预约 · 等待开工"
		"BUILDING":
			return "施工中 · 只计算到位人手"
		"BLOCKED_BUILDERS":
			return "待工 · 尚无现场施工人手"
		"BUILT":
			return "军需工坊 · 已建成"
		_:
			return state


func _production_is_waiting(entry: Dictionary) -> bool:
	return str(entry.get("state", entry.get("status", ""))) in ["WAITING", "BLOCKED_CAPACITY", "QUEUED"]


func _production_entry_id(entry: Dictionary) -> String:
	return str(entry.get("queue_entry_id", entry.get("id", "")))


func _is_warband_recipe_id(recipe_id: String) -> bool:
	return recipe_id in [WarbandCatalogClass.HINGE_GUARD_RECIPE_ID, WarbandCatalogClass.BRIGHT_CROSSBOW_RECIPE_ID]


func _production_recipe_label(recipe_id: String) -> String:
	match recipe_id:
		"recipe:worker:v1":
			return "勤务民"
		WarbandCatalogClass.HINGE_GUARD_RECIPE_ID:
			return "合页卫"
		WarbandCatalogClass.BRIGHT_CROSSBOW_RECIPE_ID:
			return "明契弩列"
		CampCatalogClass.WORKSHOP_RECIPE_ID:
			return "军需工坊"
		_:
			return "未知配方"


func _warband_type_label(unit_type: String) -> String:
	match unit_type:
		WarbandCatalogClass.HINGE_GUARD_TYPE:
			return "合页卫"
		WarbandCatalogClass.BRIGHT_CROSSBOW_TYPE:
			return "明契弩列"
		_:
			return "守军"


func _production_state_label(state: String) -> String:
	match state:
		"WAITING", "QUEUED":
			return "排队"
		"BLOCKED_CAPACITY":
			return "人口满"
		"RUNNING":
			return "生产中"
		"BLOCKED_OUTLET":
			return "出口占用"
		"BLOCKED_DEPLOYMENT":
			return "集结受阻"
		"BLOCKED_BUILDERS":
			return "暂无施工人手"
		_:
			return state


func _production_block_label(reason: String) -> String:
	match reason:
		"CAPACITY", "BLOCKED_CAPACITY":
			return "等待人口空位"
		"OUTLET_OCCUPIED", "BLOCKED_OUTLET":
			return "等待出口清空"
		"BLOCKED_DEPLOYMENT":
			return "等待战团集结空位"
		"BLOCKED_BUILDERS":
			return "暂无施工人手"
		_:
			return reason


func _role_short_label(role: String) -> String:
	match role:
		"FOOD":
			return "粮"
		"MATERIAL":
			return "材"
		"CONSTRUCTION_REPAIR":
			return "修"
		_:
			return role


func _ensure_warband_cards() -> void:
	# Friendly cards lead the row even though the authoritative snapshot itself
	# remains lexically sorted by ID. Fallen history cannot expand the active HUD.
	for side_group in [SIDE_PLAYER, SIDE_AI]:
		var card_index := 0
		var parent_row := _cards_row if side_group == SIDE_PLAYER else _enemy_cards_row
		for warband_value in _snapshot.get("warbands", []):
			var warband: Dictionary = warband_value
			if str(warband.get("side", "")) != side_group or int(warband.get("living_count", 0)) <= 0:
				continue
			var warband_id := str(warband.get("id", ""))
			if warband_id.is_empty():
				continue
			if not _cards_by_id.has(warband_id):
				var button := Button.new()
				button.name = "%sCard" % warband_id.to_pascal_case()
				button.custom_minimum_size = Vector2(78 if side_group == SIDE_PLAYER else 138, 54)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.alignment = HORIZONTAL_ALIGNMENT_CENTER
				button.clip_text = true
				button.focus_mode = Control.FOCUS_NONE
				button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				button.add_theme_font_size_override("font_size", 11)
				button.pressed.connect(_on_warband_card_pressed.bind(warband_id))
				parent_row.add_child(button)
				_cards_by_id[warband_id] = button
			parent_row.move_child(_cards_by_id[warband_id], card_index)
			card_index += 1


func _handle_arena_tap(screen_position: Vector2) -> void:
	if not _is_ground_surface(screen_position) or not _arena_screen_rect().has_point(screen_position):
		return
	if str(_snapshot.get("outcome", OUTCOME_ONGOING)) != OUTCOME_ONGOING:
		_set_feedback("战斗已经结束，请重新开始", false)
		return
	for base: Dictionary in _snapshot.get("bases", []):
		var center := _sim_to_screen(_as_vector2(base["position"]))
		var hit_radius := maxf(24.0, float(base["radius"]) * _arena_scale())
		if center.distance_squared_to(screen_position) <= hit_radius * hit_radius:
			if str(base["side"]) == SIDE_AI:
				if _selected_warband_id.is_empty():
					_set_feedback("先选择友军战团，再点击敌方统御兽", false)
				else:
					_apply_command_result(_session.submit_attack_base(_selected_warband_id, str(base["id"])), "已下达战团压制 · 清场后守住救援圈")
			else:
				_set_feedback("救援：两团各半数存活成员进圈，无敌兵8秒；每方一次", true)
			get_viewport().set_input_as_handled()
			return
	var camp: Dictionary = (_snapshot.get("economy", {}) as Dictionary).get("construction", {})
	if camp.has("position"):
		var camp_center := _sim_to_screen(_as_vector2(camp["position"]))
		var hit_radius := maxf(20.0, float(camp.get("radius", 26)) * _arena_scale())
		if camp_center.distance_squared_to(screen_position) <= hit_radius * hit_radius:
			_set_camp_visible(true)
			get_viewport().set_input_as_handled()
			return
	var worker := _worker_at_screen_position(screen_position)
	if not worker.is_empty():
		var cargo_amount := int(worker.get("cargo_amount", 0))
		var cargo_description := " · 携带%s ×%d" % [_role_short_label(str(worker.get("cargo_type", ""))), cargo_amount] if cargo_amount > 0 else ""
		_set_feedback("%s · %s%s" % [str(worker.get("id", "勤务民")), str(worker.get("state", "")), cargo_description], true)
		get_viewport().set_input_as_handled()
		return

	var soldier := _soldier_at_screen_position(screen_position)
	if not soldier.is_empty():
		var side := str(soldier.get("side", ""))
		var owning_warband_id := str(soldier.get("warband_id", ""))
		if side == SIDE_PLAYER:
			_selected_warband_id = owning_warband_id
			_set_feedback("已选择战团 %s" % owning_warband_id, true)
			_sync_hud()
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if side == SIDE_AI and not _selected_warband_id.is_empty():
			var result := _session.submit_focus(_selected_warband_id, owning_warband_id)
			_apply_command_result(result, "集火 %s" % owning_warband_id)
			get_viewport().set_input_as_handled()
			return

	if _selected_warband_id.is_empty():
		_set_feedback("请先选择一个友军战团", false)
		return
	var target := _screen_to_sim(screen_position)
	var move_result := _session.submit_move(_selected_warband_id, target)
	_apply_command_result(move_result, "移动至 (%d, %d)" % [target.x, target.y])
	get_viewport().set_input_as_handled()


func _on_warband_card_pressed(warband_id: String) -> void:
	var warband := _warband_by_id(warband_id)
	if str(warband.get("side", "")) != SIDE_PLAYER or int(warband.get("living_count", 0)) <= 0:
		return
	_selected_warband_id = warband_id
	_set_feedback("已选择战团 %s" % warband_id, true)
	_sync_hud()
	queue_redraw()


func _on_formation_pressed(formation: String) -> void:
	if _selected_warband_id.is_empty():
		_set_feedback("请先选择一个友军战团", false)
		return
	var result := _session.submit_formation(_selected_warband_id, formation)
	_apply_command_result(result, "切换为 %s" % _formation_label(formation))


func _on_retreat_pressed() -> void:
	if _selected_warband_id.is_empty():
		return
	var result := _session.submit_retreat(_selected_warband_id)
	_apply_command_result(result, "战团撤回本阵")


func _on_auto_engage_pressed() -> void:
	var result := _session.submit_auto_engage()
	_apply_command_result(result, "全军已下达%s · %d 个战团" % ["压制" if _living_count_for_side(SIDE_AI) == 0 else "迎敌", int(result.get("warbands_commanded", 0))])


func _on_auto_defend_pressed() -> void:
	var result := _session.submit_auto_defend()
	_apply_command_result(result, "%d团切稳阵回防 · 实际行军，不回血" % int(result.get("warbands_commanded", 0)))


func _on_camp_toggle_pressed() -> void:
	_set_camp_visible(_camp_toggle_button.button_pressed)


func _on_camp_close_pressed() -> void:
	_set_camp_visible(false)


func _set_camp_visible(visible: bool) -> void:
	if visible:
		_close_observational_surfaces()
	_camera_dragging = false
	_camp_panel.visible = visible
	_camp_toggle_button.set_pressed_no_signal(visible)
	queue_redraw()


func _set_economy_visible(visible: bool) -> void:
	if visible:
		_close_observational_surfaces()
	_economy_visible = visible
	_economy_panel.visible = visible
	(_navigation_buttons["economy"] as Button).set_pressed_no_signal(visible)
	_camera_dragging = false
	queue_redraw()


func _set_production_visible(visible: bool) -> void:
	if visible:
		_close_observational_surfaces()
	_production_visible = visible
	_production_panel.visible = visible
	_production_toggle_button.set_pressed_no_signal(visible)
	_camera_dragging = false
	queue_redraw()


func _set_menu_visible(visible: bool) -> void:
	if visible:
		_close_observational_surfaces()
	_game_menu_panel.visible = visible
	_menu_button.set_pressed_no_signal(visible)
	_camera_dragging = false
	queue_redraw()


func _close_observational_surfaces() -> void:
	_camera_dragging = false
	_economy_visible = false
	_production_visible = false
	for control: Control in [_economy_panel, _production_panel, _camp_panel, _game_menu_panel, _expanded_map_panel]:
		if is_instance_valid(control):
			control.visible = false
	for button: Button in [_navigation_buttons.get("economy"), _production_toggle_button, _camp_toggle_button, _menu_button]:
		if is_instance_valid(button):
			button.set_pressed_no_signal(false)
	_transfer_from.get_popup().hide()
	_transfer_to.get_popup().hide()
	get_viewport().gui_release_focus()


func _on_build_workshop_pressed() -> void:
	var result := _session.submit_enqueue_workshop()
	_apply_command_result(result, "工坊已加入队列 · 调配建造修复人手施工")


func _on_cancel_workshop_pressed() -> void:
	var camp: Dictionary = (_snapshot.get("economy", {}) as Dictionary).get("construction", {})
	var queue_id := str(camp.get("queue_entry_id", ""))
	if queue_id.is_empty():
		return
	var waiting := str(camp.get("cost_state", "")) == "RESERVED"
	var result := _session.submit_cancel_production_entry(queue_id)
	_apply_command_result(result, "工坊预约已释放" if waiting else "工坊施工已取消 · 已扣成本不返还")


func _on_fortify_base_pressed() -> void:
	var result := _session.submit_fortify_base()
	_apply_command_result(result, "护持：响%d · 实际恢复%d生命" % [int(result.get("cost", NeutralSpringClass.FORTIFY_COST)), int(result.get("restored_hp", 0))])


func _on_economy_delta_pressed(role: String, delta: int) -> void:
	var result := _session.submit_economy_change(role, delta)
	_apply_command_result(result, "%s目标 %s1" % [_role_short_label(role), "+" if delta > 0 else "−"])


func _on_transfer_pressed() -> void:
	var roles := ["FOOD", "MATERIAL", "CONSTRUCTION_REPAIR"]
	var from_role: String = roles[_transfer_from.selected]
	var to_role: String = roles[_transfer_to.selected]
	if from_role == to_role:
		_set_feedback("调拨的来源和去向不能相同", false)
		return
	var result := _session.submit_economy_transfer(from_role, to_role)
	_apply_command_result(result, "%s → %s 调拨 1 人" % [_role_short_label(from_role), _role_short_label(to_role)])


func _on_enqueue_worker_pressed() -> void:
	var result := _session.submit_enqueue_worker()
	_apply_command_result(result, "勤务民已加入生产队列")


func _on_enqueue_warband_pressed(recipe_id: String) -> void:
	var result := _session.submit_enqueue_warband(recipe_id)
	_apply_command_result(result, "%s战团已加入生产队列" % _production_recipe_label(recipe_id))


func _on_cancel_worker_pressed(slot_index: int) -> void:
	var entry := _production_entry_at(slot_index)
	if entry.is_empty():
		return
	var entry_id := _production_entry_id(entry)
	var result := _session.submit_cancel_production_entry(entry_id)
	_apply_command_result(result, "已取消生产项 %s" % entry_id)


func _on_reorder_worker_pressed(slot_index: int, direction: int) -> void:
	var economy: Dictionary = _snapshot.get("economy", {})
	var production: Dictionary = economy.get("production", {})
	var entries: Array = production.get("entries", [])
	var entry := _production_entry_at(slot_index)
	if entry.is_empty() or not _production_is_waiting(entry):
		return
	var waiting_indexes: Array[int] = []
	for entry_index: int in range(entries.size()):
		if _production_is_waiting(entries[entry_index]):
			waiting_indexes.append(entry_index)
	var waiting_position := waiting_indexes.find(slot_index)
	var target_index := waiting_position + direction
	if waiting_position < 0 or target_index < 0 or target_index >= waiting_indexes.size():
		return
	var entry_id := _production_entry_id(entry)
	var result := _session.submit_reorder_production_entry(entry_id, target_index)
	_apply_command_result(result, "已调整生产项 %s 顺序" % entry_id)


func _production_entry_at(slot_index: int) -> Dictionary:
	var economy: Dictionary = _snapshot.get("economy", {})
	var production: Dictionary = economy.get("production", {})
	var entries: Array = production.get("entries", [])
	if slot_index < 0 or slot_index >= entries.size():
		return {}
	return entries[slot_index]


func _on_start_battle_pressed() -> void:
	var result := _session.submit_start_battle()
	_apply_command_result(result, "战斗开始；勤务民继续工作")


func _on_restart_pressed() -> void:
	_reset_visual_state(_session.reset())
	_set_feedback("战场已重置", true)


func _reset_visual_state(next_snapshot: Dictionary) -> void:
	_camera_dragging = false
	_combat_effects.clear()
	_snapshot = next_snapshot
	_previous_snapshot = _snapshot.duplicate(true)
	_interpolation_alpha = 1.0
	_selected_warband_id = ""
	_close_observational_surfaces()
	_ensure_selection()
	_layout_hud()
	_restore_initial_camera()
	_sync_hud()
	queue_redraw()


func _apply_command_result(result: Dictionary, success_message: String) -> void:
	_accept_session_snapshot(_session.get_snapshot())
	if bool(result.get("accepted", false)):
		_set_feedback(success_message, true)
	else:
		_set_feedback("命令被拒绝 · %s" % str(result.get("error", "UNKNOWN")), false)
	_sync_hud()
	queue_redraw()


func _accept_session_snapshot(next_snapshot: Dictionary) -> void:
	if int(next_snapshot.get("tick", -1)) != int(_snapshot.get("tick", -1)) or next_snapshot != _snapshot:
		_previous_snapshot = _snapshot
		_snapshot = next_snapshot
		_interpolation_alpha = 1.0


func _set_feedback(message: String, positive: bool) -> void:
	_feedback_label.text = message
	_feedback_label.tooltip_text = message
	_feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS if positive else COLOR_DANGER)


func _ensure_selection() -> void:
	var selected := _warband_by_id(_selected_warband_id)
	if not selected.is_empty() and str(selected.get("side", "")) == SIDE_PLAYER and int(selected.get("living_count", 0)) > 0:
		return
	_selected_warband_id = ""
	for warband_value in _snapshot.get("warbands", []):
		var warband: Dictionary = warband_value
		if str(warband.get("side", "")) == SIDE_PLAYER and int(warband.get("living_count", 0)) > 0:
			_selected_warband_id = str(warband.get("id", ""))
			return


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), COLOR_PAGE)
	draw_rect(_field_rect(), COLOR_FIELD)
	draw_rect(_field_rect(), COLOR_FIELD_EDGE, false, 2.0)
	_world_canvas.queue_redraw()


func _draw_selection_portrait() -> void:
	var selected := _warband_by_id(_selected_warband_id)
	var canvas := _selection_portrait
	canvas.draw_style_box(_panel_style(Color(0.025, 0.045, 0.05), COLOR_ACCENT, 3, 2), Rect2(Vector2.ZERO, canvas.size))
	canvas.draw_line(Vector2(4, 4), Vector2(canvas.size.x - 4, 4), Color(0.8, 0.72, 0.4, 0.5), 1)
	if selected.is_empty():
		canvas.draw_string(_presentation_font, Vector2(15, 34), "—", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, COLOR_MUTED)
		return
	# An original pixel-shaped guard/crossbow portrait; identity remains the
	# selected aggregate warband, never a new independently controlled body.
	var bow := str(selected.get("unit_type", "")) == WarbandCatalogClass.BRIGHT_CROSSBOW_TYPE
	var armor := COLOR_CROSSBOW_PLAYER if bow else COLOR_PLAYER
	canvas.draw_rect(Rect2(22, 12, 14, 13), Color(0.71, 0.60, 0.43))
	canvas.draw_rect(Rect2(19, 9, 20, 8), armor.darkened(0.45))
	canvas.draw_rect(Rect2(20, 9, 18, 3), armor.lightened(0.10))
	canvas.draw_rect(Rect2(20, 26, 19, 18), armor.darkened(0.20))
	canvas.draw_rect(Rect2(25, 26, 4, 18), armor.lightened(0.10))
	canvas.draw_rect(Rect2(19, 43, 7, 6), Color(0.17, 0.22, 0.24))
	canvas.draw_rect(Rect2(33, 43, 7, 6), Color(0.17, 0.22, 0.24))
	if bow:
		canvas.draw_line(Vector2(13, 39), Vector2(47, 24), COLOR_MATERIAL, 4)
		canvas.draw_line(Vector2(34, 22), Vector2(42, 43), COLOR_TEXT, 2)
		canvas.draw_line(Vector2(17, 38), Vector2(43, 41), COLOR_MUTED, 1)
	else:
		canvas.draw_rect(Rect2(10, 26, 15, 18), armor.darkened(0.38))
		canvas.draw_rect(Rect2(12, 28, 11, 14), armor.lightened(0.10))
		canvas.draw_line(Vector2(43, 18), Vector2(43, 46), COLOR_TEXT, 3)
		canvas.draw_line(Vector2(37, 38), Vector2(49, 38), COLOR_MATERIAL, 2)
	var hero := _hero_for_warband(_selected_warband_id)
	if not hero.is_empty():
		var crown_color := COLOR_ACCENT if str(hero.get("state", "")) == "ACTIVE" else COLOR_MUTED
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(23, 7), Vector2(23, 3), Vector2(27, 5), Vector2(29, 1), Vector2(32, 5), Vector2(36, 3), Vector2(36, 7)]), crown_color)


func _draw_world() -> void:
	var arena_rect := _arena_screen_rect()
	_world_canvas.draw_rect(arena_rect, COLOR_FIELD)
	_draw_terrain(arena_rect)
	_world_canvas.draw_rect(arena_rect, COLOR_FIELD_EDGE, false, 2.0)
	_draw_economy_sites()
	_draw_spring()
	_draw_camp()
	_draw_command_beasts()
	_draw_intents()
	_draw_formation_projection()
	_draw_depth_entities()
	_draw_combat_effects()
	_draw_base_readouts()
	_draw_warband_labels()


func _observe_combat_changes(before: Dictionary, after: Dictionary) -> void:
	if str(after.get("phase", "")) != GameSimulationClass.PHASE_BATTLE:
		return
	var prior_by_id: Dictionary = {}
	var current_by_id: Dictionary = {}
	for soldier: Dictionary in before.get("soldiers", []):
		prior_by_id[str(soldier["id"])] = soldier
	for soldier: Dictionary in after.get("soldiers", []):
		current_by_id[str(soldier["id"])] = soldier
	for soldier: Dictionary in after.get("soldiers", []):
		var prior: Dictionary = prior_by_id.get(str(soldier["id"]), {})
		if prior.is_empty():
			continue
		var position := _as_vector2(soldier["position"])
		if int(soldier["hp"]) < int(prior["hp"]):
			_append_combat_effect({"kind": "damage", "position": position, "ttl": COMBAT_EFFECT_SECONDS})
		# Only adjacent authority ticks bind an attack to the current target.
		# Across skipped ticks a killed troop may already have been replaced by
		# a siege target while its old attack is still cooling down.
		if int(after.get("tick", 0)) != int(before.get("tick", 0)) + 1 or int(soldier["cooldown_ticks"]) <= int(prior["cooldown_ticks"]):
			continue
		var target: Dictionary = current_by_id.get(str(soldier.get("target_id", "")), {})
		if target.is_empty():
			for base: Dictionary in after.get("bases", []):
				if str(base["id"]) == str(soldier.get("target_base_id", "")):
					target = base
					break
		if not target.is_empty():
			_append_combat_effect({
				"kind": "shot" if str(soldier["unit_type"]) == WarbandCatalogClass.BRIGHT_CROSSBOW_TYPE else "strike",
				"position": position, "target": _as_vector2(target["position"]), "ttl": COMBAT_EFFECT_SECONDS,
			})


func _append_combat_effect(effect: Dictionary) -> void:
	if _combat_effects.size() >= COMBAT_EFFECT_LIMIT:
		_combat_effects.pop_front()
	_combat_effects.append(effect)


func _age_combat_effects(delta: float) -> void:
	if _combat_effects.is_empty():
		return
	for index: int in range(_combat_effects.size() - 1, -1, -1):
		_combat_effects[index]["ttl"] = float(_combat_effects[index]["ttl"]) - maxf(0.0, delta)
		if float(_combat_effects[index]["ttl"]) <= 0.0:
			_combat_effects.remove_at(index)
	queue_redraw()


func _draw_combat_effects() -> void:
	for effect: Dictionary in _combat_effects:
		var center := _sim_to_screen(effect["position"])
		var alpha := clampf(float(effect["ttl"]) / COMBAT_EFFECT_SECONDS, 0.0, 1.0) * 0.72
		var kind := str(effect["kind"])
		if kind == "damage":
			_world_canvas.draw_rect(Rect2(center - Vector2(7, 9), Vector2(14, 18)), Color(COLOR_DANGER, alpha * 0.28), false, 1.5)
		else:
			var target := _sim_to_screen(effect["target"])
			if kind == "shot":
				_world_canvas.draw_line(center, target, Color(COLOR_TEXT, alpha), 1.2)
			else:
				var direction := (target - center).normalized()
				var impact := center + direction * 9.0
				_world_canvas.draw_line(impact + Vector2(-3, -3), impact + Vector2(3, 3), Color(COLOR_ACCENT, alpha), 1.5)
				_world_canvas.draw_line(impact + Vector2(-3, 3), impact + Vector2(3, -3), Color(COLOR_ACCENT, alpha), 1.5)


func _draw_terrain(arena_rect: Rect2) -> void:
	PixelBattleRendererClass.draw_terrain(_world_canvas, arena_rect)
	var label_color := Color(COLOR_MUTED, 0.52)
	_world_canvas.draw_string(_presentation_font, arena_rect.position + Vector2(12, 22), "西侧统御台", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, label_color)
	_world_canvas.draw_string(_presentation_font, Vector2(arena_rect.end.x - 88, arena_rect.position.y + 22), "东侧统御台", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, label_color)


func _draw_intents() -> void:
	for warband_value in _snapshot.get("warbands", []):
		var warband: Dictionary = warband_value
		if str(warband.get("id", "")) != _selected_warband_id or int(warband.get("living_count", 0)) <= 0:
			continue
		var side := str(warband.get("side", ""))
		var color := COLOR_PLAYER if side == SIDE_PLAYER else COLOR_AI
		var anchor := _interpolated_warband_position(warband, "anchor")
		var destination := _as_vector2(warband.get("destination", anchor))
		var anchor_screen := _sim_to_screen(anchor)
		var destination_screen := _sim_to_screen(destination)
		if anchor.distance_squared_to(destination) > 16.0:
			_world_canvas.draw_line(anchor_screen, destination_screen, Color(color, 0.52), 2.0)
			_world_canvas.draw_circle(destination_screen, 7.0, Color(color, 0.16))
			_world_canvas.draw_arc(destination_screen, 10.0, 0.0, TAU, 20, Color(color, 0.72), 1.5)

		var focus_target_id := str(warband.get("focus_target_id", ""))
		if not focus_target_id.is_empty():
			var target_warband := _warband_by_id(focus_target_id)
			if not target_warband.is_empty():
				var target_anchor := _interpolated_warband_position(target_warband, "anchor")
				_world_canvas.draw_line(anchor_screen, _sim_to_screen(target_anchor), Color(COLOR_ACCENT, 0.48), 1.5)
		var focus_base_id := str(warband.get("focus_base_id", ""))
		if not focus_base_id.is_empty():
			var target_base := _base_by_id(focus_base_id)
			if not target_base.is_empty():
				_world_canvas.draw_line(anchor_screen, _sim_to_screen(_as_vector2(target_base["position"])), Color(COLOR_ACCENT, 0.48), 1.5)


func _draw_spring() -> void:
	var spring: Dictionary = (_snapshot.get("strategic", {}) as Dictionary).get("spring", {})
	if not spring.has("position"):
		return
	var center := _sim_to_screen(_as_vector2(spring["position"]))
	var radius := float(spring.get("control_radius", NeutralSpringClass.CONTROL_RADIUS)) * _arena_scale()
	var owner := str(spring.get("owner", "NEUTRAL"))
	var color := COLOR_PLAYER if owner == SIDE_PLAYER else COLOR_AI if owner == SIDE_AI else COLOR_ACCENT
	var contested := bool(spring.get("contested", false))
	var blocked := bool(spring.get("income_blocked", false))
	_world_canvas.draw_circle(center, radius, Color(color, 0.06))
	_world_canvas.draw_arc(center, radius, 0, TAU, 48, Color(color, 0.55), 1.3)
	PixelBattleRendererClass.draw_spring(_world_canvas, center, _arena_scale(), owner)
	var candidate := str(spring.get("capturing_side", "NEUTRAL"))
	var progress := clampf(float(spring.get("capture_ticks", 0)) / maxf(1, float(spring.get("capture_required_ticks", NeutralSpringClass.CAPTURE_TICKS))), 0, 1)
	if progress > 0 and candidate in [SIDE_PLAYER, SIDE_AI]:
		_world_canvas.draw_arc(center, radius - 3, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, COLOR_PLAYER if candidate == SIDE_PLAYER else COLOR_AI, 2.0)
	var status := "争夺停产 · 占领中断" if contested and blocked else "争夺 · 占领中断" if contested else "敌兵停产" if blocked else "%s夺取%d%%" % [_spring_side_label(candidate), roundi(progress * 100)] if candidate in [SIDE_PLAYER, SIDE_AI] else "全场公开"
	_world_canvas.draw_string(_presentation_font, center + Vector2(-55, radius + 15), "%s响泉 · %s" % [_spring_side_label(owner), status], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)


func _draw_formation_projection() -> void:
	var selected := _warband_by_id(_selected_warband_id)
	if selected.is_empty():
		return
	var destination := _as_vector2(selected.get("destination", selected.get("anchor", Vector2.ZERO)))
	var formation := str(selected.get("formation", "STEADY"))
	var facing := str(selected.get("facing", FormationLibraryClass.FACING_EAST))
	for offset in _formation_preview_offsets(formation, facing):
		var slot_screen := _sim_to_screen(destination + offset)
		_world_canvas.draw_circle(slot_screen, 3.5, Color(COLOR_PLAYER, 0.18))
		_world_canvas.draw_arc(slot_screen, 5.0, 0.0, TAU, 12, Color(COLOR_PLAYER, 0.42), 1.0)


func _draw_economy_sites() -> void:
	var economy: Dictionary = _snapshot.get("economy", {})
	var sites: Dictionary = economy.get("sites", {})
	for site_value in sites:
		var site := str(site_value)
		var center := _sim_to_screen(_as_vector2(sites[site_value]))
		var color := COLOR_ACCENT
		var label := "仓库"
		match site:
			"FOOD":
				color = COLOR_FOOD
				label = "食物"
			"MATERIAL":
				color = COLOR_MATERIAL
				label = "材料"
			"CONSTRUCTION_REPAIR":
				color = COLOR_CONSTRUCTION
				label = "营建集结"
		_world_canvas.draw_circle(center, 15.0 * _arena_scale(), Color(color, 0.22))
		PixelBattleRendererClass.draw_economy_site(_world_canvas, center, site, _arena_scale())
		_world_canvas.draw_arc(center, 17.0 * _arena_scale(), 0.0, TAU, 20, Color(color, 0.8), 1.4)
		_world_canvas.draw_string(_presentation_font, center + Vector2(12, -12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	var production: Dictionary = economy.get("production", {})
	if production.has("outlet"):
		var outlet_center := _sim_to_screen(_as_vector2(production["outlet"]))
		var outlet_blocked := false
		for entry_value in production.get("entries", []):
			var entry: Dictionary = entry_value
			if str(entry.get("state", "")) == "BLOCKED_OUTLET":
				outlet_blocked = true
		var outlet_color := COLOR_DANGER if outlet_blocked else COLOR_ACCENT
		var half_size := 10.0 * _arena_scale()
		_world_canvas.draw_rect(Rect2(outlet_center - Vector2.ONE * half_size, Vector2.ONE * half_size * 2.0), Color(outlet_color, 0.22))
		_world_canvas.draw_rect(Rect2(outlet_center - Vector2.ONE * half_size, Vector2.ONE * half_size * 2.0), outlet_color, false, 1.5)
		_world_canvas.draw_string(_presentation_font, outlet_center + Vector2(10, 26), "生产出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, outlet_color)


func _draw_command_beasts() -> void:
	for base: Dictionary in _snapshot.get("bases", []):
		var center := _sim_to_screen(_as_vector2(base["position"]))
		var radius := float(base["radius"]) * _arena_scale()
		var circle_radius := 150.0 * _arena_scale()
		var state := str(base["state"])
		var friendly := str(base["side"]) == SIDE_PLAYER
		var color := COLOR_PLAYER if friendly else COLOR_AI
		if state == "SUPPRESSED":
			color = COLOR_DANGER
		_world_canvas.draw_circle(center, circle_radius, Color(color, 0.035))
		_world_canvas.draw_arc(center, circle_radius, 0.0, TAU, 64, Color(color, 0.18), 1.0)
		var rescue_progress := float(base.get("rescue_progress_ticks", 0)) / 160.0
		if rescue_progress > 0.0:
			_world_canvas.draw_arc(center, circle_radius, -PI * 0.5, -PI * 0.5 + TAU * rescue_progress, 64, COLOR_SUCCESS, 2.0)
		_world_canvas.draw_circle(center, radius, Color(color, 0.16))
		_world_canvas.draw_arc(center, radius, 0.0, TAU, 32, color, 1.5)


func _draw_base_readouts() -> void:
	for base: Dictionary in _snapshot.get("bases", []):
		var center := _sim_to_screen(_as_vector2(base["position"]))
		var radius := float(base["radius"]) * _arena_scale()
		var state := str(base["state"])
		var friendly := str(base["side"]) == SIDE_PLAYER
		var color := COLOR_PLAYER if friendly else COLOR_AI
		if state == "SUPPRESSED":
			color = COLOR_DANGER
		var hp_fraction := clampf(float(base["hp"]) / maxf(1.0, float(base["max_hp"])), 0.0, 1.0)
		var health := Rect2(center + Vector2(-radius, -radius - 9), Vector2(radius * 2.0, 4))
		_world_canvas.draw_rect(health, COLOR_PAGE)
		_world_canvas.draw_rect(Rect2(health.position, Vector2(health.size.x * hp_fraction, health.size.y)), color)
		var label := "我方统御兽" if friendly else "敌方统御兽 · 点击压制"
		if state == "SUPPRESSED":
			var remaining := maxi(0, int(base["evacuation_deadline_tick"]) - int(_snapshot.get("tick", 0)))
			label = "受压 · 撤离 %.1fs" % (float(remaining) / float(GameSimulationClass.TICK_HZ))
		_world_canvas.draw_string(_presentation_font, center + Vector2(-35, radius + 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)


func _draw_camp() -> void:
	var camp: Dictionary = (_snapshot.get("economy", {}) as Dictionary).get("construction", {})
	if not camp.has("position"):
		return
	var center := _sim_to_screen(_as_vector2(camp["position"]))
	var radius := float(camp.get("radius", 26)) * _arena_scale()
	var state := str(camp.get("state", "EMPTY"))
	var color := COLOR_SUCCESS if state == "BUILT" else COLOR_CONSTRUCTION
	_world_canvas.draw_circle(center, radius, Color(0.08, 0.10, 0.12, 0.98))
	_world_canvas.draw_arc(center, radius, 0.0, TAU, 28, color, 1.5)
	if _camp_panel.visible:
		_world_canvas.draw_arc(center, radius + 4.0, 0.0, TAU, 28, COLOR_ACCENT, 1.5)
	var progress := clampf(float(camp.get("work_completed", 0)) / maxf(1.0, float(camp.get("work_required", 200))), 0.0, 1.0)
	var label := "固定槽 · 点击营建"
	if state == "BUILT":
		label = "军需工坊 · +25%"
	elif state != "EMPTY":
		if progress > 0.0:
			_world_canvas.draw_arc(center, radius + 2.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 28, COLOR_ACCENT, 2.0)
		label = "工坊 · %d%%" % roundi(progress * 100.0)
	_world_canvas.draw_string(_presentation_font, center + Vector2(-25, radius + 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)


func _get_depth_entities() -> Array[Dictionary]:
	var entities: Array[Dictionary] = []
	for base: Dictionary in _snapshot.get("bases", []):
		entities.append({"id": "base:" + str(base["id"]), "kind": "base", "position": Vector2(base["position"]), "data": base})
	var economy: Dictionary = _snapshot.get("economy", {})
	var camp: Dictionary = economy.get("construction", {})
	if camp.has("position"):
		entities.append({"id": "camp:" + str(camp.get("slot_id", "workshop")), "kind": "camp", "position": Vector2(camp["position"]), "data": camp})
	for soldier: Dictionary in _snapshot.get("soldiers", []):
		entities.append({"id": "soldier:" + str(soldier["id"]), "kind": "soldier", "position": _interpolated_soldier_position(soldier), "data": soldier})
	for worker: Dictionary in economy.get("workers", []):
		entities.append({"id": "worker:" + str(worker["id"]), "kind": "worker", "position": _interpolated_worker_position(worker), "data": worker})
	entities.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_position: Vector2 = left["position"]
		var right_position: Vector2 = right["position"]
		return str(left["id"]) < str(right["id"]) if left_position.y == right_position.y else left_position.y < right_position.y
	)
	return entities


func _draw_depth_entities() -> void:
	for entity: Dictionary in _get_depth_entities():
		var data: Dictionary = entity["data"]
		var position: Vector2 = entity["position"]
		var center := _sim_to_screen(position)
		match str(entity["kind"]):
			"base":
				PixelBattleRendererClass.draw_beast(_world_canvas, center, str(data["side"]), float(data["radius"]) * _arena_scale(), str(data["state"]), int(_snapshot["tick"]))
			"camp":
				var progress := clampf(float(data.get("work_completed", 0)) / maxf(1.0, float(data.get("work_required", 200))), 0.0, 1.0)
				PixelBattleRendererClass.draw_workshop(_world_canvas, center, float(data.get("radius", 26)) * _arena_scale(), str(data.get("state", "EMPTY")), progress, int(_snapshot["tick"]))
			"soldier": _draw_soldier(data, position)
			"worker": _draw_worker(data, position)


func _draw_soldier(soldier: Dictionary, position: Vector2) -> void:
	var body_radius := float(GameSimulationClass.SOLDIER_BODY_RADIUS) * _arena_scale()
	var screen_position := _sim_to_screen(position)
	var side := str(soldier.get("side", ""))
	var unit_type := str(soldier.get("unit_type", WarbandCatalogClass.HINGE_GUARD_TYPE))
	var incapacitated := bool(soldier.get("incapacitated", false))
	var selected := str(soldier.get("warband_id", "")) == _selected_warband_id and not incapacitated

	if selected:
		_world_canvas.draw_arc(screen_position, body_radius + 2.5, 0.0, TAU, 20, Color(COLOR_ACCENT, 0.76), 1.2)
	var warband := _warband_by_id(str(soldier.get("warband_id", "")))
	PixelBattleRendererClass.draw_soldier(_world_canvas, screen_position, unit_type, side, body_radius, not incapacitated, str(warband.get("facing", "EAST")), int(_snapshot.get("tick", 0)))
	if incapacitated:
		return
	if not _hero_for_member(str(soldier["id"])).is_empty():
		PixelBattleRendererClass.draw_hero_badge(_world_canvas, screen_position, body_radius)

	var hp := int(soldier.get("hp", 0))
	var max_hp := maxi(int(soldier.get("max_hp", 1)), 1)
	var health_ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bar_rect := Rect2(screen_position + Vector2(-body_radius, -body_radius - 5), Vector2(body_radius * 2.0, 2.5))
	_world_canvas.draw_rect(bar_rect, Color(0.02, 0.025, 0.025, 0.92))
	var health_color := COLOR_SUCCESS if health_ratio > 0.45 else COLOR_DANGER
	_world_canvas.draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * health_ratio, bar_rect.size.y)), health_color)



func _draw_worker(worker: Dictionary, position: Vector2) -> void:
	var radius := 8.0 * _arena_scale()
	var screen_position := _sim_to_screen(position)
	var role := str(worker.get("role", "RESERVE"))
	PixelBattleRendererClass.draw_worker(_world_canvas, screen_position, role, radius, int(worker.get("cargo_amount", 0)), int(_snapshot.get("tick", 0)))
	if str(worker.get("state", "")) == "CONSTRUCTING":
		_world_canvas.draw_arc(screen_position, radius + 2.0, -PI * 0.8, -PI * 0.2, 8, COLOR_ACCENT, 1.5)
		_world_canvas.draw_line(screen_position + Vector2(0, -radius - 3), screen_position + Vector2(4, -radius - 7), COLOR_CONSTRUCTION, 1.5)


func _draw_warband_labels() -> void:
	for warband_value in _snapshot.get("warbands", []):
		var warband: Dictionary = warband_value
		var anchor := _interpolated_warband_position(warband, "anchor")
		var screen_position := _sim_to_screen(anchor)
		var side := str(warband.get("side", ""))
		var color := COLOR_PLAYER if side == SIDE_PLAYER else COLOR_AI
		var warband_id := str(warband.get("id", ""))
		var living := int(warband.get("living_count", 0))
		var selected := warband_id == _selected_warband_id
		_world_canvas.draw_circle(screen_position, 3.0, COLOR_ACCENT if selected else color)
		if selected:
			_world_canvas.draw_arc(screen_position, 20.0, 0.0, TAU, 28, Color(COLOR_ACCENT, 0.58), 2.0)
		if living <= 0:
			continue
		# Cards retain every living friendly identity; only the selected friendly
		# needs a world label when several armies converge on one objective.
		if side == SIDE_PLAYER and not selected:
			continue
		var label := "%s %d/8" % [TacticalReadoutClass.compact_name(warband_id), living]
		var label_offset := Vector2(-42, 50) if side == SIDE_PLAYER else Vector2(-42, -39)
		_world_canvas.draw_string(_presentation_font, screen_position + label_offset, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(color, 0.9))


func _soldier_at_screen_position(screen_position: Vector2) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := SOLDIER_HIT_RADIUS * SOLDIER_HIT_RADIUS
	for soldier_value in _snapshot.get("soldiers", []):
		var soldier: Dictionary = soldier_value
		if int(soldier.get("hp", 0)) <= 0:
			continue
		var soldier_screen := _sim_to_screen(_interpolated_soldier_position(soldier))
		if not _is_ground_surface(soldier_screen):
			continue
		var distance := soldier_screen.distance_squared_to(screen_position)
		if distance <= closest_distance:
			closest = soldier
			closest_distance = distance
	return closest


func _worker_at_screen_position(screen_position: Vector2) -> Dictionary:
	var closest: Dictionary = {}
	var closest_distance := WORKER_HIT_RADIUS * WORKER_HIT_RADIUS
	var economy: Dictionary = _snapshot.get("economy", {})
	for worker_value in economy.get("workers", []):
		var worker: Dictionary = worker_value
		var worker_screen := _sim_to_screen(_interpolated_worker_position(worker))
		if not _is_ground_surface(worker_screen):
			continue
		var distance := worker_screen.distance_squared_to(screen_position)
		if distance <= closest_distance:
			closest = worker
			closest_distance = distance
	return closest


func _interpolated_soldier_position(soldier: Dictionary) -> Vector2:
	var current := _as_vector2(soldier.get("position", Vector2.ZERO))
	var soldier_id := str(soldier.get("id", ""))
	var previous := _previous_soldier_by_id(soldier_id)
	if previous.is_empty():
		return current
	var before := _as_vector2(previous.get("position", current))
	return before.lerp(current, _interpolation_alpha)


func _interpolated_worker_position(worker: Dictionary) -> Vector2:
	var current := _as_vector2(worker.get("position", Vector2.ZERO))
	var economy: Dictionary = _previous_snapshot.get("economy", {})
	for previous_value in economy.get("workers", []):
		var previous: Dictionary = previous_value
		if str(previous.get("id", "")) == str(worker.get("id", "")):
			return _as_vector2(previous.get("position", current)).lerp(current, _interpolation_alpha)
	return current


func _interpolated_warband_position(warband: Dictionary, key: String) -> Vector2:
	var current := _as_vector2(warband.get(key, Vector2.ZERO))
	var previous := _previous_warband_by_id(str(warband.get("id", "")))
	if previous.is_empty():
		return current
	return _as_vector2(previous.get(key, current)).lerp(current, _interpolation_alpha)


func _warband_by_id(warband_id: String) -> Dictionary:
	if warband_id.is_empty():
		return {}
	for warband_value in _snapshot.get("warbands", []):
		var warband: Dictionary = warband_value
		if str(warband.get("id", "")) == warband_id:
			return warband
	return {}


func _previous_warband_by_id(warband_id: String) -> Dictionary:
	for warband_value in _previous_snapshot.get("warbands", []):
		var warband: Dictionary = warband_value
		if str(warband.get("id", "")) == warband_id:
			return warband
	return {}


func _previous_soldier_by_id(soldier_id: String) -> Dictionary:
	for soldier_value in _previous_snapshot.get("soldiers", []):
		var soldier: Dictionary = soldier_value
		if str(soldier.get("id", "")) == soldier_id:
			return soldier
	return {}


func _living_count_for_side(side: String) -> int:
	var total := 0
	for warband_value in _snapshot.get("warbands", []):
		var warband: Dictionary = warband_value
		if str(warband.get("side", "")) == side:
			total += int(warband.get("living_count", 0))
	return total


func _field_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(Vector2(0, TOP_PANEL_HEIGHT), Vector2(viewport_size.x, maxf(180, viewport_size.y - TOP_PANEL_HEIGHT - BOTTOM_PANEL_HEIGHT)))


func _is_ground_surface(screen_position: Vector2) -> bool:
	if not _field_rect().grow(-8).has_point(screen_position):
		return false
	if _game_menu_panel.visible or _expanded_map_panel.visible or _transfer_from.get_popup().visible or _transfer_to.get_popup().visible:
		return false
	return not _is_camera_pointer_occluded(screen_position)


func _arena_screen_rect() -> Rect2:
	return _camera.get_projected_world_rect()


func _arena_scale() -> float:
	return _camera.get_scale()


func _sim_to_screen(sim_position: Vector2) -> Vector2:
	return _camera.world_to_screen(sim_position)


func _screen_to_sim(screen_position: Vector2) -> Vector2i:
	var bounds := _session.get_arena_bounds()
	var mapped: Vector2 = _camera.screen_to_world(screen_position)
	return Vector2i(
		clampi(roundi(mapped.x), bounds.position.x, bounds.end.x),
		clampi(roundi(mapped.y), bounds.position.y, bounds.end.y)
	)


func _formation_preview_offsets(formation: String, facing: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for offset: Vector2i in FormationLibraryClass.get_world_slots(formation, Vector2i.ZERO, facing):
		result.append(Vector2(offset))
	return result


func _as_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	if value is Dictionary:
		return Vector2(float(value.get("x", 0)), float(value.get("y", 0)))
	return Vector2.ZERO


func _formation_label(formation: String) -> String:
	match formation:
		"STEADY":
			return "稳阵"
		"MARCH_COLUMN":
			return "行军纵队"
		"WIDE_LINE":
			return "宽线"
		"DISPERSED":
			return "疏散"
		_:
			return formation


func _formation_short_label(formation: String) -> String:
	match formation:
		"MARCH_COLUMN":
			return "纵队"
		"WIDE_LINE":
			return "宽线"
		"DISPERSED":
			return "疏散"
		_:
			return "稳阵"


func _intent_label(intent: String) -> String:
	match intent:
		"MOVE":
			return "行军"
		"FOCUS":
			return "迎敌"
		"ATTACK_BASE":
			return "攻城"
		"RETREAT":
			return "撤回"
		_:
			return "守备"


func _style_command_button(button: Button, prominent: bool = false) -> void:
	button.mouse_force_pass_scroll_events = false
	var normal_color := Color(0.16, 0.19, 0.18, 1.0) if not prominent else Color(0.23, 0.19, 0.09, 1.0)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", COLOR_ACCENT)
	button.add_theme_color_override("font_disabled_color", Color(COLOR_MUTED, 0.45))
	button.add_theme_stylebox_override("normal", _panel_style(normal_color, Color(0.28, 0.34, 0.31, 1.0), 6))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.20, 0.25, 0.22, 1.0), COLOR_ACCENT, 6))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.11, 0.15, 0.14, 1.0), COLOR_ACCENT, 6, 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.08, 0.095, 0.095, 1.0), Color(0.14, 0.16, 0.15, 1.0), 6))


func _style_warband_card(button: Button, side: String, selected: bool) -> void:
	var color := COLOR_PLAYER if side == SIDE_PLAYER else COLOR_AI
	var background := Color(0.055, 0.14, 0.18, 1.0) if side == SIDE_PLAYER else Color(0.18, 0.075, 0.055, 1.0)
	var border := COLOR_ACCENT if selected else Color(color, 0.55)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(COLOR_TEXT, 0.72))
	button.add_theme_stylebox_override("normal", _panel_style(background, border, 6, 2 if selected else 1))
	button.add_theme_stylebox_override("hover", _panel_style(background.lightened(0.08), COLOR_ACCENT, 6, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(background.darkened(0.08), COLOR_ACCENT, 6, 2))
	button.add_theme_stylebox_override("disabled", _panel_style(background, border, 6, 2 if selected else 1))


func _panel_style(background: Color, border: Color, radius: int, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _set_margins(container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)


func _on_viewport_size_changed() -> void:
	_layout_hud()
	queue_redraw()
