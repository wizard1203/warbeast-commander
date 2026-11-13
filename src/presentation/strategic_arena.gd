class_name StrategicArena
extends Node2D
## M11 strategic frontier. The view owns selection, projection and target modes;
## all economy, territory, population, production, hero and combat changes pass
## through GameSession.submit_strategic. No presentation code changes a snapshot.

const SessionClass = preload("res://src/runtime/game_session.gd")
const LiveClockM75 = preload("res://src/runtime/live_match_clock_m75.gd")
const AttributeBreakdownM75 = preload("res://src/presentation/strategic_attribute_breakdown_m75.gd")
const CameraClass = preload("res://src/presentation/battle_camera_projection.gd")
const NavigationClass = preload("res://src/presentation/camera_navigation_input.gd")
const GestureClass = preload("res://src/presentation/strategic_camera_gesture.gd")
const ContextHelpClass = preload("res://src/presentation/strategic_context_help.gd")
const NativeTooltipGate = preload("res://src/presentation/strategic_native_tooltip_gate.gd")
const HelpDescriptions = preload("res://src/presentation/strategic_help_descriptions.gd")
const IconClass = preload("res://src/presentation/strategic_icon_button.gd")
const WarbandButtonClass = preload("res://src/presentation/strategic_warband_button.gd")
const RosterPreviewClass = preload("res://src/presentation/strategic_roster_preview.gd")
const JoystickClass = preload("res://src/presentation/strategic_joystick.gd")
const MapClass = preload("res://src/presentation/strategic_minimap.gd")
const CanvasClass = preload("res://src/presentation/strategic_world_canvas.gd")
const HeroicCanvas = preload("res://src/presentation/heroic_2d_world_canvas.gd")
const HeroicAtlas = preload("res://src/presentation/heroic_2d_atlas.gd")
const HeroicCollection = preload("res://src/presentation/heroic_collection.gd")
const HeroicGenerated = preload("res://src/presentation/heroic_generated_units.gd")
const RosterAtlasV9 = preload("res://src/presentation/heroic_roster_v5.gd")
const Frontier3DCanvas = preload("res://src/presentation/frontier3d_world_canvas.gd")
const Frontier3DCamera = preload("res://src/presentation/frontier3d_camera_projection.gd")
const GeometricCanvasM77 = preload("res://src/presentation/geometric_world_canvas_m77.gd")
const ReliefCanvasM78 = preload("res://src/presentation/relief_world_canvas_m78.gd")
const PixelClass = preload("res://src/presentation/strategic_pixel_renderer.gd")
const ResourceReadoutClass = preload("res://src/presentation/strategic_resource_readout.gd")
const CostReadoutClass = preload("res://src/presentation/strategic_cost_readout.gd")
const TechTreeClass = preload("res://src/presentation/strategic_tech_tree.gd")
const QueueReadoutClass = preload("res://src/presentation/strategic_queue_readout.gd")
const ChromeClass = preload("res://src/presentation/strategic_chrome.gd")
const HeroCardClass = preload("res://src/presentation/strategic_hero_card.gd")
const HeroStatusClass = preload("res://src/presentation/strategic_hero_status_readout.gd")
const ActorInspectorClass = preload("res://src/presentation/strategic_actor_inspector.gd")
const ActorInspectionReadout = preload("res://src/presentation/strategic_actor_inspection_readout.gd")
const ActorVisibilityR9 = preload("res://src/presentation/heroic_actor_readout.gd")
const SourceInspectionM71 = preload("res://src/presentation/strategic_source_inspection_m71.gd")
const FactReadoutClass = preload("res://src/presentation/strategic_fact_readout.gd")
const TextButtonClass = preload("res://src/presentation/strategic_text_button.gd")
const HeroCatalog = preload("res://src/simulation/strategic_hero_catalog.gd")
const HeroItems = preload("res://src/simulation/strategic_hero_items.gd")
const HeroBagBar = preload("res://src/presentation/strategic_hero_bag_bar.gd")
const HeroShopPanel = preload("res://src/presentation/strategic_hero_shop_panel.gd")
const OutpostShopReadout = preload("res://src/presentation/strategic_outpost_shop_readout.gd")
const CombatCatalog = preload("res://src/simulation/strategic_combat.gd")
const FeedbackClass = preload("res://src/presentation/strategic_command_feedback.gd")
const CaptureReadoutClass = preload("res://src/presentation/strategic_capture_readout.gd")
const FieldObjectiveReadout = preload("res://src/presentation/strategic_field_objective_readout.gd")
const AudioFeedbackClass = preload("res://src/presentation/strategic_audio_feedback.gd")
const LocalAudioFactory = preload("res://src/presentation/strategic_local_audio_factory.gd")
const AIDifficultyClass = preload("res://src/simulation/strategic_ai_difficulty.gd")
const LobbyClass = preload("res://src/presentation/strategic_lobby.gd")
const HeroArenaScene = preload("res://scenes/hero_arena.tscn")
const HeroStatisticsPanelM69 = preload("res://src/presentation/strategic_hero_statistics_panel_m69.gd")
const StrengthScoreHUDM74 = preload("res://src/presentation/strategic_strength_score_hud_m74.gd")
const ProcessMetricsM76 = preload("res://src/runtime/process_metrics_m76.gd")
const RuntimeMetricsHUDM76 = preload("res://src/presentation/strategic_runtime_metrics_hud_m76.gd")
const SpectatorView = preload("res://src/presentation/strategic_spectator_view.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const UnitsV4 = preload("res://src/simulation/strategic_unit_catalog.gd")
const DamageRules = preload("res://src/simulation/strategic_damage_rules.gd")
const EconomyCatalog = preload("res://src/simulation/strategic_economy_catalog.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const CatalogGridClass = preload("res://src/presentation/strategic_catalog_grid.gd")
const TransferRowsClass = preload("res://src/presentation/strategic_transfer_rows.gd")
const OutpostSlotUI = preload("res://src/presentation/strategic_outpost_slot_ui.gd")
const FrontierCommandArt = preload("res://src/presentation/strategic_frontier_command_art.gd")
const BUILDINGS := ["BASE", "BARRACKS", "RANGE", "TOWER", "FOUNDRY", "ALTAR", "DRAGON_ROOST", "ESSENCE_MINE"]
const BUILDING_NAMES := {"BASE":"资源营所", "BARRACKS":"物理营", "RANGE":"魔法营", "TOWER":"灯契箭塔", "SITE_TOWER":"据点守塔", "ESSENCE_MINE":"采金矿场", "FOUNDRY":"科技兵工坊", "ALTAR":"长官祭庭", "DRAGON_ROOST":"特色营", "SHOP":"英雄商店"}
const BUILDING_SHORT_NAMES := {"BASE":"营所", "BARRACKS":"物理营", "RANGE":"魔法营", "TOWER":"箭塔", "SITE_TOWER":"守塔", "ESSENCE_MINE":"矿场", "FOUNDRY":"兵工", "ALTAR":"祭庭", "DRAGON_ROOST":"特色营", "SHOP":"商店"}
const UNITS := ["worker", "hinge_guard", "bright_crossbow", "iron_lancer", "grove_mender", "hero"]
const UNIT_NAMES := {"worker":"工人", "hinge_guard":"合页卫", "bright_crossbow":"明契弩兵", "iron_lancer":"重装槊卫", "grove_mender":"林契医士", "hero":"英雄长官"}
const UNIT_ICONS := {"worker":"worker", "hinge_guard":"guard", "bright_crossbow":"bow", "iron_lancer":"lancer", "grove_mender":"potion", "hero":"hero"}
const UNIT_BUILDINGS := {"worker":"BASE", "hinge_guard":"BARRACKS", "bright_crossbow":"BARRACKS", "iron_lancer":"BARRACKS", "grove_mender":"RANGE", "hero":"ALTAR"}
const ROLES := ["FOOD", "MATERIAL", "ESSENCE", "CONSTRUCTION_REPAIR"]
const ROLE_NAMES := {"FOOD":"食物", "MATERIAL":"采矿", "ESSENCE":"灵髓", "CONSTRUCTION_REPAIR":"建筑工", "RESERVE":"待命"}
const SKILLS := ["CLEAVE", "RECOVER", "RALLY"]
const SKILL_NAMES := {"CLEAVE":"裂契斩", "RECOVER":"重整", "RALLY":"盟誓"}
const STEER_INTERVAL := 0.15

var _session: RefCounted
var _live_clock := LiveClockM75.new()
var _hud_refresh_elapsed := 0.0
var _computer_side_id := "AI"
var _view_side_id := "PLAYER"
var _screen_shake_enabled_r9 := true
var _explicit_observer := false
var _view_button: Button
var _snapshot: Dictionary = {}
var _camera := CameraClass.new()
var _navigation := NavigationClass.new()
var _gesture := GestureClass.new()
var _context_help: Control
var _ui: Control
var _field: Control
var _canvas: Node2D
var _minimap: Control
var _strength_scores: Control
var _runtime_metrics: Control
var _process_metrics := ProcessMetricsM76.new()
var _hero_choices_m76:Dictionary={}
var _top_panel: Panel
var _status: Label
var _resources: Control
var _troop_counts: Control
var _feedback: Label
var _toolbar: HBoxContainer
var _army_chips: HBoxContainer
var _army_scroll: ScrollContainer
var _army_mode_button_r12: Button
var _army_control_mode_r12 := "MIXED"
var _selected_unit_type_r12 := ""
var _context: HBoxContainer
var _selection_label: Label
var _backdrop: ColorRect
var _management_panel: Panel
var _panel_content: Control
var _panel_title: Label
var _panel_feedback: Label
var _panel_kind := ""
var _selected_warband_id := ""
var _selected_unit_id := ""
var _target_mode := ""
var _blueprint_type := ""
var _selected_building_slot_id := ""
var _selected_slot_building_type := ""
var _move_joystick: Control
var _attack_joystick: Control
var _skill_joysticks: Dictionary = {}
var _inventory_button: Button
var _hero_automation_button: Button
var _hero_bag: Control
var _shop_category := "BASIC"
var _shop_item_id := "POTION"
var _selected_building_id := ""
var _cancel_target_button: Button
var _move_vector := Vector2.ZERO
var _steer_elapsed := 0.0
var _steer_sent := false
var _camera_dragging := false
var _pointer_inside := true
var _pointer := Vector2(640, 360)
var _army_signature := ""
var _feedback_seconds := 0.0
var _recruit_building_id := ""
var _recruit_building_signature := ""
var _recruit_unit_type := "hinge_guard"
var _receiving_army_id := ""
var _source_army_id := ""
var _transfer_army_id := ""
var _foundry_building_id := ""
var _foundry_signature := ""
var _last_result: Dictionary = {}
var _toolbar_chrome: Control
var _management_chrome: Control
var _hero_card: Button
var _hero_roster: ScrollContainer
var _hero_cards: Control
var _hero_roster_signature := ""
var _atlas_preparation_v9: Dictionary = {}
var _primary_hero_id := ""
var _base_building_id := "player_base_01"
var _base_option_signature := ""
var _selected_facts: Control
var _actor_inspector: Control
var _hero_status_context: Dictionary = {}
var _info_button: Button
var _roster_button: Button
var _selected_worker_id := ""
var _recruit_archetype := "COMMANDER"
var _info_type := "hero"
var _info_archetype := "COMMANDER"
var _info_unit_id := ""
var _info_item := "FIELD_BOOTS"
var _skill_aim: Dictionary = {}
var _command_feedback := FeedbackClass.new()
var _audio: Node
var _selected_site_id := ""
var _selected_source_id := ""
var _field_reward_marks: Array[Dictionary] = []
var _site_button: Button
var _battle_start_button: Button
var _computer_button: Button
var _ai_difficulty_button: Button
var _outcome_notice: Label
var _outcome_seconds := 0.0
var _lobby_surface: Control
var _hero_arena_surface: Control
var _statistics_surface: Control
var _statistics_view: Control
var _statistics_refresh_elapsed := 0.0
var _secondary_surface: Control
var _technology_button: Button
var _menu_button: Button
var _composition_button: Button
var _composition_facts: Array[Dictionary] = []
var _recruit_catalog: Control
var _build_catalog: Control
var _transfer_rows: Control
var _recruit_source_initialized := false
var _receiving_army_initialized := false
var _receiving_army_signature := ""
var _presentation_seed := 1701
var _match_seed := 1701
var _appearance_seed_button: Button
## Presentation flags select a view only, never a different rules session.
var frontier_3d_enabled := false
var geometric_3d_enabled := false
var relief_2d_enabled := false
var geometric_low_effects_m78 := false
var heroic_2d_enabled := PixelClass.heroic_route()

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	relief_2d_enabled = relief_2d_enabled or "--relief-2d" in args
	geometric_3d_enabled = not relief_2d_enabled and (geometric_3d_enabled or "--geometric-3d" in args)
	geometric_low_effects_m78 = geometric_low_effects_m78 or "--geometric-low-effects" in args
	frontier_3d_enabled = not relief_2d_enabled and (frontier_3d_enabled or "--frontier-3d" in args or geometric_3d_enabled)
	heroic_2d_enabled = relief_2d_enabled or (heroic_2d_enabled and not frontier_3d_enabled and PixelClass.heroic_route())
	get_window().title = "魔兽指挥官 · 像素战场" if heroic_2d_enabled else "魔兽指挥官 · 经典战场"
	if frontier_3d_enabled:
		_camera = Frontier3DCamera.new()
		get_window().title = "魔兽指挥官 · 立体战场"
	if geometric_3d_enabled: get_window().title = "魔兽指挥官 · 几何战场"
	if relief_2d_enabled: get_window().title = "魔兽指挥官 · 浮绘战场"
	if heroic_2d_enabled and not relief_2d_enabled:
		var installation: Dictionary = HeroicAtlas.validate_installation()
		if not bool(installation.get("ready", false)):
			_show_heroic_installation_error(installation)
			return
	_match_seed = _new_match_seed()
	_session = SessionClass.new(_match_seed, true, "strategic-v1", "EASY")
	_snapshot = _session.get_snapshot()
	_audio = LocalAudioFactory.create()
	_audio.name = "StrategicAudioFeedback"
	add_child(_audio)
	_build_ui()
	_context_help = ContextHelpClass.new()
	_context_help.name = "StrategicContextHelp"
	_context_help.resolver = Callable(self, "_help_target")
	_context_help.target_validity = Callable(self, "_help_target_valid")
	_context_help.target_refresher = Callable(self, "_refresh_help_target")
	_context_help.replay_requested.connect(_replay_help_events)
	_context_help.world_hold_started.connect(func(_index: int): _gesture.suppress())
	add_child(_context_help)
	# Native tooltip timers are cached by an existing Viewport. Delaying a
	# global preference never reliably prevented the second native PopupPanel.
	# Gate only this owner while preserving every source tooltip_text verbatim.
	set_meta(NativeTooltipGate.OWNER_META, true)
	NativeTooltipGate.attach_native_subtree(_ui)
	get_tree().node_added.connect(_gate_new_help_control)
	_camera.configure(_bounds(), _field_rect(), float(_snapshot["scenario"]["camera_max_zoom"]))
	_camera.zoom_at(_field_rect().get_center(), float(_snapshot["scenario"]["initial_zoom"]))
	_camera.center_on(_home_position())
	get_viewport().size_changed.connect(_layout)
	get_window().focus_exited.connect(_clear_direct_input)
	get_window().focus_exited.connect(_dismiss_context_help)
	# Leaving the window cancels pending hover through the outside pointer;
	# a displayed explanation stays latched. Actual focus loss still clears it.
	get_window().mouse_exited.connect(func(): _pointer_inside = false)
	get_window().mouse_entered.connect(func(): _pointer_inside = true)
	_layout()
	_audio.observe({}, _snapshot, _camera.get_visible_world_rect())
	_refresh()
	_set_feedback("开局大厅：先选择地图、人数和种族；单击开始后才运行经济与战斗。", 9)

func _show_heroic_installation_error(installation: Dictionary) -> void:
	# A missing licensed local pack must not silently launch the rejected view.
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	var background := ColorRect.new()
	background.color = Color("17232a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var message := Label.new()
	message.name = "HeroicAssetInstallationRequired"
	message.position = Vector2(60, 70)
	message.size = Vector2(1120, 560)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 23)
	message.add_theme_font_override("font", ReadableFont.readable())
	message.text = "2D 像素版的本地 Heroic 素材缺失或校验失败\n\n作者素材未随公开源码再分发。缺少 Starter 请从作者页面下载免费 ZIP；完整包安装损坏时，请保留原目录并按对应安装说明处理：\n\n%s\n\n%s\n\n安装完成后重新启动。旧版仅能通过明确的旧版脚本进入，不会自动切回 3D。" % [str(installation.get("install_command", "node tools/install_heroic_starter.mjs /path/to/HAS-Starter-Pack.zip")), "\n".join(installation.get("failures", []))]
	background.add_child(message)
	push_error("Heroic 2D local assets unavailable: " + str(installation.get("failures", [])))

func _process(delta: float) -> void:
	_process_metrics.poll(Time.get_ticks_usec(),Engine.get_frames_drawn())
	if is_instance_valid(_runtime_metrics): _runtime_metrics.refresh(_process_metrics.snapshot(Time.get_ticks_usec()))
	var active: bool = not is_instance_valid(_hero_arena_surface) and not _command_desk_paused() and _snapshot.get("phase","")=="BATTLE" and _snapshot.get("outcome","")=="ONGOING"
	var live_delta := _live_clock.sample(Time.get_ticks_usec(),active)
	if is_instance_valid(_hero_arena_surface): return # Independent fixture owns its own clock and audio.
	var previous := _snapshot
	_audio.set_combat_paused(_command_desk_paused())
	# A local menu break must not become clock debt on resume. Keep the real
	# Session zero-tick read path and its pre-existing fractional accumulator.
	if active and _session.advance_live(live_delta):
		_snapshot = _session.get_snapshot()
	if is_instance_valid(_statistics_surface):
		_statistics_refresh_elapsed += delta
		if _statistics_refresh_elapsed >= 0.25:
			_statistics_refresh_elapsed = 0.0
			_statistics_view.refresh(_snapshot)
		return # The modal table owns input; observers still advance normal logic.
	_audio.observe(previous, _snapshot, _camera.get_visible_world_rect())
	_drain_outcome_cues()
	_command_feedback.advance(delta)
	for index: int in range(_field_reward_marks.size()-1, -1, -1):
		_field_reward_marks[index].age = float(_field_reward_marks[index].age) + maxf(delta, 0)
		if float(_field_reward_marks[index].age) >= float(_field_reward_marks[index].lifetime): _field_reward_marks.remove_at(index)
	_advance_direct_input(delta)
	_advance_navigation(delta)
	_feedback_seconds = maxf(_feedback_seconds - delta, 0)
	_feedback.visible = _feedback_seconds > 0 or not _target_mode.is_empty()
	_outcome_seconds = maxf(_outcome_seconds - delta, 0)
	_outcome_notice.visible = _outcome_seconds > 0 and not _backdrop.visible
	_hud_refresh_elapsed += maxf(delta,0)
	# Readouts/option lists do not need to be rebuilt at display refresh rate.
	# Input handlers still synchronously refresh after selection/commands.
	if _hud_refresh_elapsed>=0.1:
		_hud_refresh_elapsed = 0.0
		_refresh()
	else:
		_refresh_canvas(false)
	if _context_help != null: _context_help.advance(delta, _pointer if _pointer_inside else Vector2(-1, -1))

func _exit_tree() -> void:
	_process_metrics.stop()

func _command_desk_paused() -> bool:
	return (is_instance_valid(_statistics_surface) or (_backdrop != null and _backdrop.visible and _panel_kind == "menu")) \
		and _snapshot.get("phase") == "BATTLE" and _snapshot.get("outcome") == "ONGOING" \
		and _can_command()

func _field_rect() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(0, 40, size.x, maxf(size.y - 40, 1))

func _bounds() -> Rect2i:
	return _session.get_arena_bounds()

func _build_ui() -> void:
	_field = Control.new()
	_field.name = "StrategicBattlefield"
	_field.clip_contents = true
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_field)
	_canvas = _new_battlefield_canvas_m78()
	if geometric_3d_enabled: _canvas.name = "GeometricBattlefieldM77"
	if heroic_2d_enabled: _canvas.name = "HeroicPixelBattlefield"
	_field.add_child(_canvas)
	_ui = Control.new()
	_ui.name = "StrategicHUD"
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if heroic_2d_enabled:
		var hud_theme := Theme.new()
		hud_theme.default_font = ReadableFont.readable()
		_ui.theme = hud_theme
	add_child(_ui)
	_top_panel = Panel.new()
	_top_panel.name = "ResourceStrip"
	_top_panel.add_theme_stylebox_override("panel", _style(Color("162b2a")))
	_ui.add_child(_top_panel)
	var resource_chrome := ChromeClass.new()
	resource_chrome.name = "ResourceStripOrnament"
	resource_chrome.surface = "strip"
	resource_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top_panel.add_child(resource_chrome)
	_resources = ResourceReadoutClass.new()
	_resources.name = "ResourcePictograms"
	_resources.position = Vector2(18, 0)
	_resources.size = Vector2(480, 40)
	_top_panel.add_child(_resources)
	_status = _label("", 19)
	_status.name = "ResourceNumbers"
	_status.position = Vector2(535, 7)
	_top_panel.add_child(_status)
	_troop_counts = FactReadoutClass.new()
	_troop_counts.name = "TopTroopCounts"
	_troop_counts.position = Vector2(18, 42)
	_top_panel.add_child(_troop_counts)
	_composition_button = _button("军情总览", "ForceCompositionButton", Vector2(144, 40))
	_composition_button.pressed.connect(_open_panel.bind("composition"))
	_ui.add_child(_composition_button)
	_minimap = MapClass.new()
	_minimap.name = "StrategicMinimap"
	_minimap.location_requested.connect(_locate_camera)
	_ui.add_child(_minimap)
	_strength_scores = StrengthScoreHUDM74.new()
	_strength_scores.name = "StrengthScoreHUD"
	_strength_scores.details_requested.connect(_open_strength_score_details)
	_ui.add_child(_strength_scores)
	_runtime_metrics = RuntimeMetricsHUDM76.new()
	_ui.add_child(_runtime_metrics)
	_toolbar_chrome = ChromeClass.new()
	_toolbar_chrome.name = "CommandDockOrnament"
	_toolbar_chrome.surface = "dock"
	_ui.add_child(_toolbar_chrome)
	_toolbar = HBoxContainer.new()
	_toolbar.name = "ManagementSkillBar"
	_toolbar.add_theme_constant_override("separation", 8)
	_ui.add_child(_toolbar)
	for entry: Array in [["economy", "经营", "EconomyButton"], ["recruit", "招募", "RecruitButton"], ["build", "建筑", "BuildButton"], ["army", "部队", "ArmyButton"], ["tech", "科技", "TechnologyButton"], ["menu", "菜单", "MenuButton"]]:
		var button := _icon(str(entry[0]), str(entry[1]), str(entry[2]))
		button.pressed.connect(_open_panel.bind(str(entry[0])))
		if entry[0] == "tech":
			_technology_button = button
			_ui.add_child(button)
		elif entry[0] == "menu":
			_menu_button = button
			_ui.add_child(button)
		else: _toolbar.add_child(button)
	_army_scroll = ScrollContainer.new()
	_army_scroll.name = "ArmySelectionStrip"
	_army_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_army_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_ui.add_child(_army_scroll)
	_army_chips = HBoxContainer.new()
	_army_chips.add_theme_constant_override("separation", 6)
	_army_scroll.add_child(_army_chips)
	_context = HBoxContainer.new()
	_context.name = "SelectionActionBar"
	_context.add_theme_constant_override("separation", 7)
	_ui.add_child(_context)
	_selection_label = _label("", 17)
	_selection_label.name = "SelectionFacts"
	_selection_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_selection_label)
	_selected_facts = FactReadoutClass.new()
	_selected_facts.heroic_2d = heroic_2d_enabled
	_selected_facts.name = "SelectedPhysicalFacts"
	_ui.add_child(_selected_facts)
	_hero_roster = ScrollContainer.new()
	_hero_roster.name = "HeroPortraitRoster"
	_hero_roster.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_hero_roster.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_ui.add_child(_hero_roster)
	_hero_cards = Control.new()
	_hero_cards.name = "HeroStatusCards"
	_hero_roster.add_child(_hero_cards)
	_actor_inspector = ActorInspectorClass.new()
	_ui.add_child(_actor_inspector)
	_move_joystick = JoystickClass.new()
	_move_joystick.name = "MovementJoystick"
	_move_joystick.caption = "移动"
	_move_joystick.vector_changed.connect(_on_move_vector)
	_ui.add_child(_move_joystick)
	_attack_joystick = JoystickClass.new()
	_attack_joystick.name = "AttackJoystick"
	_attack_joystick.caption = "攻击"
	_attack_joystick.icon = "sword"
	_attack_joystick.gesture_finished.connect(_unit_attack)
	_ui.add_child(_attack_joystick)
	for skill_id: String in SKILLS:
		var joystick := JoystickClass.new()
		joystick.name = "Skill" + skill_id
		joystick.caption = SKILL_NAMES[skill_id]
		joystick.icon = skill_id
		joystick.custom_minimum_size = Vector2(78, 78)
		joystick.gesture_finished.connect(_cast_skill.bind(skill_id))
		joystick.vector_changed.connect(_preview_skill.bind(skill_id))
		_skill_joysticks[skill_id] = joystick
		_ui.add_child(joystick)
	_inventory_button = _icon("equipment", "装备", "InventoryButton")
	_inventory_button.pressed.connect(_open_panel.bind("inventory"))
	_ui.add_child(_inventory_button)
	_hero_automation_button = _icon("tech", "成长", "HeroAutomationButton")
	_hero_automation_button.tooltip_text = "长官：独立自动攻击/施法开关，技能点与技能升级。"
	_hero_automation_button.pressed.connect(_open_panel.bind("hero"))
	_ui.add_child(_hero_automation_button)
	_hero_bag = HeroBagBar.new()
	_hero_bag.name = "SelectedHeroBag"
	_hero_bag.use_requested.connect(_use_inventory)
	_hero_bag.inspect_requested.connect(_inspect_bag_item)
	_hero_bag.shop_requested.connect(_open_panel.bind("inventory"))
	_ui.add_child(_hero_bag)
	_info_button = _button("ⓘ 属性 / 技能", "UnitInformationButton", Vector2(202, 44))
	_info_button.pressed.connect(_open_selected_info)
	_ui.add_child(_info_button)
	_roster_button = _button("英雄 / 单位手册", "HeroRosterButton", Vector2(202, 44))
	_roster_button.pressed.connect(_open_roster)
	_ui.add_child(_roster_button)
	_battle_start_button = _button("▶ 开始交战\n占领 / 电脑将启动", "BattleStartQuickButton", Vector2(202, 54))
	_battle_start_button.tooltip_text = "筹备期可调配和行军，但占领、战斗及电脑均暂停。单击一次明确开始；不会自动开战。"
	_battle_start_button.pressed.connect(_menu_action.bind("start"))
	_ui.add_child(_battle_start_button)
	_computer_button = _button("电脑 · 筹备未启动", "ComputerActivityButton", Vector2(230, 40))
	_computer_button.pressed.connect(_open_panel.bind("computer"))
	_ui.add_child(_computer_button)
	_view_button = _button("视角 · 玩家1 ▾", "SpectatorPerspectiveButton", Vector2(180, 44))
	_view_button.pressed.connect(_open_panel.bind("perspective"))
	_ui.add_child(_view_button)
	_ai_difficulty_button = _button("AI难度 · 简单", "AIDifficultySelector", Vector2(180, 44))
	_ai_difficulty_button.pressed.connect(_open_panel.bind("difficulty"))
	_ui.add_child(_ai_difficulty_button)
	_site_button = _button("", "SiteCaptureButton", Vector2(320, 60))
	_site_button.pressed.connect(_open_panel.bind("site"))
	_ui.add_child(_site_button)
	_outcome_notice = _label("", 18)
	_outcome_notice.name = "StrategicOutcomeNotice"
	_outcome_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outcome_notice.add_theme_color_override("font_color", Color("b5dc97"))
	_outcome_notice.add_theme_color_override("font_outline_color", Color("12242a"))
	_outcome_notice.add_theme_constant_override("outline_size", 1 if heroic_2d_enabled else 4)
	_ui.add_child(_outcome_notice)
	_feedback = _label("", 18)
	_feedback.name = "ShortCommandFeedback"
	# A single-line Label otherwise expands to the complete text's minimum
	# width, ignoring the space reserved for cancel at the 1024px viewport.
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.max_lines_visible = 2
	_feedback.clip_text = true
	_feedback.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_feedback.add_theme_color_override("font_color", Color("f0df9b"))
	_feedback.add_theme_color_override("font_outline_color", Color("12242a"))
	_feedback.add_theme_constant_override("outline_size", 1 if heroic_2d_enabled else 4)
	# A quiet shared-theme pixel surface keeps instructions readable over bright
	# grass/water. Label-owned styling follows hide/cancel without an input layer.
	var feedback_surface := ChromeClass.style("normal", "strip")
	feedback_surface.set_content_margin_all(4)
	feedback_surface.content_margin_left = 8
	feedback_surface.content_margin_right = 8
	_feedback.add_theme_stylebox_override("normal", feedback_surface)
	_feedback.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_feedback)
	_cancel_target_button = _icon("cancel", "取消", "CancelTargetButton")
	_cancel_target_button.tooltip_text = "取消待选目标；不建造、不花资源、不改变部队命令。"
	_cancel_target_button.pressed.connect(_cancel_target)
	_ui.add_child(_cancel_target_button)
	_cancel_target_button.hide()
	_backdrop = ColorRect.new()
	_backdrop.name = "ManagementBackdrop"
	_backdrop.color = Color(0.025, 0.045, 0.04, 0.68)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	_ui.add_child(_backdrop)
	_management_panel = Panel.new()
	_management_panel.name = "StrategicManagementPanel"
	_management_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_management_panel.add_theme_stylebox_override("panel", _style(Color("1d3533")))
	_backdrop.add_child(_management_panel)
	_management_chrome = ChromeClass.new()
	_management_chrome.name = "ManagementMaterialOrnament"
	_management_chrome.surface = "panel"
	_management_chrome.size = Vector2(840, 530)
	_management_panel.add_child(_management_chrome)
	_panel_title = _label("", 27)
	if heroic_2d_enabled: _panel_title.add_theme_font_override("font", ReadableFont.title())
	_panel_title.position = Vector2(64, 23)
	_management_panel.add_child(_panel_title)
	_panel_feedback = _label("", 17)
	_panel_feedback.name = "ManagementCommandFeedback"
	_panel_feedback.position = Vector2(30, 500)
	_panel_feedback.add_theme_color_override("font_color", Color("f0df9b"))
	_management_panel.add_child(_panel_feedback)
	var close := _button("×", "CloseManagementButton", Vector2(64, 52))
	close.position = Vector2(742, 12)
	close.pressed.connect(_close_panel)
	_management_panel.add_child(close)
	_panel_content = Control.new()
	_panel_content.name = "ManagementContent"
	_panel_content.position = Vector2(30, 82)
	_panel_content.size = Vector2(780, 416)
	_management_panel.add_child(_panel_content)
	_secondary_surface = Control.new()
	_secondary_surface.name = "SecondaryCommandEntries"
	_secondary_surface.position = Vector2(30, 82)
	_secondary_surface.size = Vector2(780, 140)
	_secondary_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_management_panel.add_child(_secondary_surface)
	var secondary: Array[Button] = [_technology_button, _roster_button, _ai_difficulty_button, _computer_button]
	for index: int in range(secondary.size()):
		var button := secondary[index]
		button.reparent(_secondary_surface)
		button.position = Vector2((index % 2) * 395, (index / 2) * 66)
		button.custom_minimum_size = Vector2(375, 56)
		button.size = Vector2(375, 56)
	_secondary_surface.hide()
	_backdrop.hide()
	_lobby_surface = LobbyClass.new()
	_lobby_surface.configuration_requested.connect(_configure_lobby)
	_lobby_surface.start_requested.connect(_start_match)
	_lobby_surface.hero_arena_requested.connect(_open_hero_arena)
	_ui.add_child(_lobby_surface)
	_appearance_seed_button = _button("地景 1701 ↻", "FrontierAppearanceSeedButton", Vector2(176, 50))
	_appearance_seed_button.tooltip_text = "仅改变装饰外观种子；不改变战略地图、资源、碰撞、电脑或对局随机数。只可在开局前更换。"
	_appearance_seed_button.pressed.connect(_reshuffle_appearance)
	_lobby_surface.add_child(_appearance_seed_button)

func _layout() -> void:
	var size := get_viewport_rect().size
	_field.position = _field_rect().position
	_field.size = _field_rect().size
	_ui.size = size
	_top_panel.size = Vector2(size.x, 40)
	_troop_counts.size = Vector2(354, 34)
	_composition_button.position = Vector2(380, 42)
	_menu_button.position = Vector2(size.x - 84, 8)
	_menu_button.size = Vector2(68, 64)
	_minimap.position = Vector2(size.x - 196, 88)
	_minimap.size = Vector2(180, 180)
	_view_button.position = Vector2(size.x - 196, 276)
	_view_button.size = Vector2(180, 44)
	_toolbar.position = Vector2(18, size.y - 82)
	_toolbar_chrome.position = Vector2(14, size.y - 86)
	_toolbar_chrome.size = Vector2(310, 76)
	_army_scroll.position = Vector2(436, size.y - 82)
	_army_scroll.size = Vector2(maxf(size.x - 452, 260), 74)
	if _army_mode_button_r12!=null: _army_mode_button_r12.position=Vector2(342,size.y-82)
	_context.position = Vector2(size.x - 450, size.y - 162)
	_selection_label.position = Vector2(174, size.y - 176)
	_selection_label.size = Vector2(360, 36)
	_selection_label.clip_text = true
	_selected_facts.position = Vector2(174, size.y - 218)
	_selected_facts.size = Vector2(500, 44)
	_hero_roster.position = Vector2(18, 87)
	_hero_roster.size = Vector2(HeroCardClass.ROSTER_WIDTH, HeroCardClass.ROSTER_HEIGHT)
	_hero_bag.position = Vector2(18, 306)
	_hero_bag.size = Vector2(218, 160)
	_info_button.position = Vector2(174, size.y - 132)
	_info_button.custom_minimum_size = Vector2(160, 48)
	_info_button.size = Vector2(160, 48)
	_battle_start_button.position = Vector2(18, 320)
	_site_button.position = Vector2((size.x - 320) * 0.5, 140)
	_outcome_notice.position = Vector2((size.x - 570) * 0.5, 207)
	_outcome_notice.size = Vector2(570, 28)
	_move_joystick.position = Vector2(24, size.y - 216)
	_move_joystick.size = Vector2(118, 118)
	# Keep the large attack touch target above the live metrics strip (4px gap).
	# The neighboring inventory buttons already end above this strip.
	_attack_joystick.position = Vector2(size.x - 142, size.y - 236)
	_attack_joystick.size = Vector2(118, 118)
	var index := 0
	for joystick: Control in _skill_joysticks.values():
		joystick.position = Vector2(size.x - 238 - index * 96, size.y - 302)
		joystick.size = Vector2(88, 88)
		index += 1
	_inventory_button.position = Vector2(size.x - 220, size.y - 204)
	_inventory_button.size = Vector2(68, 64)
	_hero_automation_button.position = Vector2(size.x - 298, size.y - 204)
	_hero_automation_button.size = Vector2(68, 64)
	_layout_hero_feedback()
	_cancel_target_button.position = Vector2(size.x - 300, 86)
	_cancel_target_button.size = Vector2(68, 64)
	_backdrop.position = Vector2.ZERO
	_backdrop.size = size
	_management_panel.position = (size - Vector2(840, 530)) * 0.5
	_management_panel.size = Vector2(840, 530)
	_lobby_surface.position = Vector2.ZERO
	_lobby_surface.size = size
	if is_instance_valid(_hero_arena_surface): _hero_arena_surface.size = size
	_appearance_seed_button.position = (size - Vector2(950, 618)) * 0.5 + Vector2(730, 151)
	_camera.configure(_bounds(), _field_rect(), float(_snapshot["scenario"]["camera_max_zoom"]))
	_layout_hero_roster()
	_layout_actor_inspector()
	_layout_strength_scores()
	_refresh_canvas()

func _layout_strength_scores() -> void:
	if not is_instance_valid(_strength_scores) or not is_instance_valid(_army_scroll): return
	var viewport_size := get_viewport_rect().size
	_strength_scores.set_compact(viewport_size.x < 1000)
	_strength_scores.size = _strength_scores.minimum_panel_size()
	_strength_scores.position = Vector2(viewport_size.x - 16 - _strength_scores.size.x, viewport_size.y - 82)
	if is_instance_valid(_runtime_metrics):
		_runtime_metrics.set_compact(viewport_size.x < 1000)
		_runtime_metrics.size = Vector2(_strength_scores.size.x,28)
		_runtime_metrics.position = _strength_scores.position-Vector2(0,32)
	# The score owns a small dock slot, never an overlay on army selection.
	_army_scroll.size.x = maxf(1, _strength_scores.position.x - 12 - _army_scroll.position.x) if _strength_scores.visible else maxf(viewport_size.x - 358, 260)

func _refresh_strength_scores() -> void:
	if not is_instance_valid(_strength_scores): return
	_strength_scores.refresh(_snapshot, {"view_side":_view_side()})
	_strength_scores.visible = not _in_lobby() and not _backdrop.visible and not is_instance_valid(_statistics_surface) and not is_instance_valid(_hero_arena_surface)
	if is_instance_valid(_runtime_metrics): _runtime_metrics.visible = _strength_scores.visible
	_layout_strength_scores()

func _in_lobby() -> bool:
	return _snapshot.get("phase") == "LOBBY"

func _open_hero_arena() -> void:
	if not _in_lobby() or is_instance_valid(_hero_arena_surface): return
	_dismiss_context_help()
	_clear_direct_input()
	_hero_arena_surface = HeroArenaScene.instantiate()
	# This separate scene owns ordinary native tooltips, not Main's latched help.
	_hero_arena_surface.set_meta(NativeTooltipGate.OWNER_META,false)
	_hero_arena_surface.z_index = 80
	_hero_arena_surface.exit_requested.connect(_close_hero_arena)
	_ui.add_child(_hero_arena_surface)
	_hero_arena_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_audio.set_combat_paused(true)

func _close_hero_arena() -> void:
	if not is_instance_valid(_hero_arena_surface): return
	var previous := _hero_arena_surface
	_hero_arena_surface = null
	previous.set_paused(true)
	previous.hide()
	previous.queue_free()
	_dismiss_context_help()
	_clear_direct_input()
	_audio.set_combat_paused(_command_desk_paused())
	_refresh()

func _open_hero_statistics() -> void:
	if _in_lobby() or is_instance_valid(_statistics_surface): return
	_close_panel()
	_dismiss_context_help()
	_clear_direct_input()
	_cancel_target()
	var shade := ColorRect.new()
	shade.name = "BattleStatisticsModal"
	shade.color = Color("101b19")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.z_index = 90
	_ui.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_statistics_surface = shade
	_statistics_view = HeroStatisticsPanelM69.new()
	_statistics_view.name = "BattleHeroStatistics"
	shade.add_child(_statistics_view)
	_statistics_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_statistics_view.offset_left = 12
	_statistics_view.offset_top = 12
	_statistics_view.offset_right = -12
	_statistics_view.offset_bottom = -12
	_statistics_view.close_requested.connect(_close_hero_statistics)
	_statistics_view.set_statistics(_snapshot)
	_statistics_refresh_elapsed = 0.0
	_audio.set_combat_paused(_command_desk_paused())
	_refresh_strength_scores()

func _open_strength_score_details() -> void:
	_open_hero_statistics()
	if is_instance_valid(_statistics_view): _statistics_view.show_match_scores()

func _close_hero_statistics() -> void:
	if not is_instance_valid(_statistics_surface): return
	var previous := _statistics_surface
	_statistics_surface = null
	_statistics_view = null
	previous.hide()
	previous.queue_free()
	_clear_direct_input()
	get_viewport().gui_release_focus()
	_audio.set_combat_paused(_command_desk_paused())
	_refresh()

func _new_match_seed() -> int:
	# UI starts a new seed, while Session's default and seeded replay contract
	# stay deterministic. This is separate from the decorative appearance seed.
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--match-seed="): continue
		var value := arg.trim_prefix("--match-seed=")
		if value.is_valid_int() and int(value) >= 0 and int(value) <= 2147483647: return int(value)
		push_warning("Ignoring invalid --match-seed; expected integer 0..2147483647")
	return int((int(randi()) + Time.get_ticks_usec()) % 2147483647)

func _can_command() -> bool:
	return SpectatorView.can_command(_snapshot, _view_side_id, _explicit_observer)

func _view_side() -> String:
	return SpectatorView.view_side(_snapshot, _view_side_id)

func _observing() -> bool:
	return not _in_lobby() and SpectatorView.observing(_snapshot, _view_side_id, _explicit_observer)

func _perspective_panel() -> void:
	_panel_label("观察身份与指挥权限分离", Vector2.ZERO, 24)
	var hint := _panel_label("选择任意参赛方查看真实兵力、资源、建筑与英雄。\n观战不暂停电脑，也不能行军、招募、建造或购买。", Vector2(0, 54), 20)
	hint.size = Vector2(760, 80)
	var choices := _option("SpectatorSideOption", Vector2(0, 150), Vector2(750, 60))
	for side: Dictionary in SpectatorView.sides(_snapshot):
		_add_option(choices, "%s · %s · %s" % [Palette.side_label(str(side.side_id)), str(Factions.profile(str(side.get("faction_id", "HUMAN"))).get("label", "")), "人类" if side.get("controller") == "HUMAN" else "电脑"], str(side.side_id))
	_choose_option(choices, _view_side())
	choices.item_selected.connect(func(index: int): _set_perspective(str(choices.get_item_metadata(index))))
	var seed_label := _panel_label("本局种子 %d · 启动 --match-seed=%d 可复现。" % [_match_seed, _match_seed], Vector2(0, 216), 14)
	seed_label.size = Vector2(750, 22)
	var observe := _button("以当前玩家视角观战", "ObserveCurrentSideButton", Vector2(360, 64))
	observe.position = Vector2(0, 244)
	observe.pressed.connect(_set_perspective.bind(_view_side()))
	_panel_content.add_child(observe)
	var resume := _button("返回我的指挥", "ResumeLocalCommandButton", Vector2(360, 64))
	resume.position = Vector2(390, 244)
	resume.disabled = not SpectatorView.local_human(_snapshot)
	resume.tooltip_text = "只有原本的人类玩家可以恢复自己的指挥；不会接管任何电脑。"
	resume.pressed.connect(_resume_local_command)
	_panel_content.add_child(resume)
	var visibility := _panel_label("观战可查看全场，暂不显示各方战争迷雾。\n切换阵营可跟随镜头并查看资料，无法操控单位。", Vector2(0, 336), 17)
	visibility.size = Vector2(760, 68)
	visibility.tooltip_text = "对局种子 %d；启动参数 --match-seed=%d 可重现同种子地图及野怪。装饰种子独立。" % [_match_seed, _match_seed]

func _set_perspective(side_id: String) -> void:
	if _in_lobby() or SpectatorView.view_side(_snapshot, side_id) != side_id: return
	_explicit_observer = true
	_view_side_id = side_id
	_reset_perspective_selection()
	_close_panel()
	_camera.center_on(_home_position())
	_audio.record_ui("SELECT", "perspective:" + side_id)
	_refresh()
	_set_feedback("观战 · %s · 仅查看，不能发令。" % Palette.side_label(side_id), 5)

func _resume_local_command() -> void:
	if _in_lobby() or not SpectatorView.local_human(_snapshot): return
	_explicit_observer = false
	_view_side_id = "PLAYER"
	_reset_perspective_selection()
	_close_panel()
	_camera.center_on(_home_position())
	_refresh()
	_set_feedback("已返回自己的指挥；电脑的控制权不变。", 5)

func _reset_perspective_selection() -> void:
	if is_instance_valid(_canvas) and _canvas.has_method("reset_feedback"):_canvas.reset_feedback()
	_clear_direct_input()
	_cancel_target(false)
	_dismiss_context_help()
	for field: String in ["_selected_unit_type_r12", "_selected_unit_id", "_selected_worker_id", "_selected_warband_id", "_selected_building_id", "_selected_site_id", "_selected_source_id", "_source_army_id", "_transfer_army_id", "_receiving_army_id", "_recruit_building_id", "_foundry_building_id", "_primary_hero_id", "_info_unit_id"]: set(field, "")
	_army_control_mode_r12="MIXED"
	_army_signature = "__PERSPECTIVE__"
	_hero_roster_signature = "__PERSPECTIVE__"
	_recruit_building_signature = "__PERSPECTIVE__"
	_receiving_army_signature = "__PERSPECTIVE__"
	_base_option_signature = "__PERSPECTIVE__"
	_foundry_signature = "__PERSPECTIVE__"
	var archetypes := _hero_archetypes()
	if not archetypes.is_empty():
		_info_archetype = archetypes[0]
		_recruit_archetype = archetypes[0]
	_recruit_source_initialized = false
	_receiving_army_initialized = false
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") == _view_side() and building.get("building_type") == "BASE":
			_base_building_id = str(building.get("id", ""))
			break
	_build_context()

func _refresh_observer_controls() -> void:
	_view_button.visible = not _in_lobby() and not _backdrop.visible
	_view_button.text = ("观战 · " if _observing() else "视角 · ") + Palette.side_label(_view_side()) + " ▾"
	_view_button.tooltip_text = "选择所有电脑/人类参赛方的只读视角；观察不会接管该方。当前没有战争迷雾。"
	if not _observing(): return
	for control: Node in _panel_content.find_children("*", "", true, false):
		if control is BaseButton and SpectatorView.mutation_control(str(control.name)):
			control.disabled = true
			if not control.tooltip_text.begins_with("观战只读："):
				control.tooltip_text = "观战只读：此操作不会发送。\n" + control.tooltip_text

func _refresh_lobby() -> void:
	if _lobby_surface == null: return
	_lobby_surface.visible = _in_lobby()
	_appearance_seed_button.visible = _in_lobby() and (heroic_2d_enabled or FrontierCommandArt.enabled())
	_appearance_seed_button.text = "地景 %d ↻" % _presentation_seed
	if _in_lobby() and _session.has_method("get_match_catalog"):
		_lobby_surface.refresh(_session.get_match_catalog(), _snapshot.get("match_config", _snapshot.get("match_settings", {})))

func _reshuffle_appearance() -> void:
	if not _in_lobby() or not (heroic_2d_enabled or FrontierCommandArt.enabled()): return
	_presentation_seed += 1
	_appearance_seed_button.text = "地景 %d ↻" % _presentation_seed
	_refresh_canvas()

func _configure_lobby(request: Dictionary) -> void:
	if not _in_lobby(): return
	_steer_sent = false
	_clear_direct_input()
	_cancel_target(false)
	var result: Dictionary = _session.configure_lobby(request)
	_snapshot = _session.get_snapshot()
	_audio.record_command({"type":"SET_MATCH_CONFIG", "config":request}, result, _snapshot)
	if not result.get("accepted", false):
		_lobby_surface.show_error(str(result.get("error", "条件不满足")))
		return
	_army_signature = ""
	_hero_roster_signature = ""
	_primary_hero_id = ""
	_camera.configure(_bounds(), _field_rect(), float(_snapshot.get("scenario", {}).get("camera_max_zoom", 4)))
	_camera.center_on(_home_position())
	_refresh()
	_lobby_surface.show_configured()

func _start_match() -> void:
	if not _in_lobby(): return
	_steer_sent = false
	_clear_direct_input()
	_cancel_target(false)
	var result: Dictionary = _session.start_match()
	_snapshot = _session.get_snapshot()
	_audio.record_command({"type":"START_BATTLE"}, result, _snapshot)
	if not result.get("accepted", false):
		_lobby_surface.show_error(str(result.get("error", "条件不满足")))
		return
	# Prepare current match officers before starting the active wall clock.
	# Later recruits use the same precompiled supplier on first demand.
	var atlas_heroes: Array[String] = []
	for hero: Dictionary in _snapshot.get("heroes",{}).get("officers",[]):
		var archetype := str(hero.get("hero_archetype",hero.get("archetype","")))
		if not archetype.is_empty() and archetype not in atlas_heroes: atlas_heroes.append(archetype)
	var atlas_started := Time.get_ticks_usec()
	_atlas_preparation_v9 = RosterAtlasV9.prepare_match(atlas_heroes)
	_atlas_preparation_v9["whole_prepare_us"] = Time.get_ticks_usec()-atlas_started
	_live_clock.reset(Time.get_ticks_usec(),true)
	_recruit_source_initialized = false
	_receiving_army_initialized = false
	_recruit_building_id = ""
	_receiving_army_id = ""
	_source_army_id = ""
	_transfer_army_id = ""
	_camera.configure(_bounds(), _field_rect(), float(_snapshot.get("scenario", {}).get("camera_max_zoom", 4)))
	_camera.center_on(_home_position())
	_audio.record_ui("UI_OPEN", "BATTLE")
	_set_feedback("战斗开始！占领据点、开采金币，率领部队迎战。", 5)
	_refresh()

func _home_position() -> Vector2:
	for side: Dictionary in _snapshot.get("match_config", _snapshot.get("match_settings", {})).get("sides", []):
		if side.get("side_id") == _view_side(): return Vector2(side.get("home", Vector2(400, 600)))
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") == _view_side() and building.get("building_type") == "BASE" and int(building.get("hp", 0)) > 0: return Vector2(building.get("position", Vector2(400, 600)))
	return Vector2(400, 600)

func _faction_id() -> String:
	for side: Dictionary in _snapshot.get("match_config", _snapshot.get("match_settings", {})).get("sides", []):
		if side.get("side_id") == _view_side(): return str(side.get("faction_id", "HUMAN"))
	return "HUMAN"

func _building_recipes(side: String="") -> Dictionary:
	var catalog: Dictionary=_snapshot.get("catalog",{})
	return catalog.get("buildings_by_side",{}).get(_view_side() if side.is_empty() else side,catalog.get("buildings",{}))

func _building_display_name(type:String,side:String="",faction:String="")->String:
	if type=="DRAGON_ROOST" and not faction.is_empty():return Factions.producer_name(faction,type)
	var recipe:Dictionary=_building_recipes(side).get(type,{})
	return str(recipe.get("label",BUILDING_NAMES.get(type,type)))

func _tower_upgrade_quote(building: Dictionary={}) -> Dictionary:
	return _building_recipes(str(building.get("side",_view_side()))).get("TOWER",{}).get("upgrade_quote",EconomyCatalog.TOWER_UPGRADE)

func _unit_types() -> Array[String]:
	var result: Array[String] = []
	if not OutpostSlotUI.enabled(_snapshot): result.append("worker")
	var units: Dictionary = _snapshot.get("catalog", {}).get("units", {})
	var faction:=_faction_id()
	for type: String in units:
		if type in ["worker", "hero"]: continue
		if not UnitsV4.is_recruitable(type):continue
		if units[type].get("faction_id", units[type].get("faction", "HUMAN")) == faction: result.append(type)
	if result.size() == (0 if OutpostSlotUI.enabled(_snapshot) else 1):result.append_array(Factions.units_for(faction))
	result.append("hero")
	return result

func _hero_archetypes() -> Array[String]:
	var faction:=_faction_id()
	if _hero_choices_m76.has(faction):return _hero_choices_m76[faction].duplicate()
	var result: Array[String] = []
	result.assign(Factions.heroes_for(faction))
	if Factions.is_valid(faction): _hero_choices_m76[faction]=result.duplicate()
	return result

func _unit_name(type: String) -> String:
	var record: Dictionary = _snapshot.get("catalog", {}).get("units", {}).get(type, {})
	# Dictionary.get evaluates its default eagerly. Avoid generating fallback
	# hero profiles even when the authoritative catalog already has a label.
	if record.has("label"):return str(record.label)
	if record.has("name"):return str(record.name)
	return str(_base_unit_stats(type).get("label",UNIT_NAMES.get(type,type)))

func _unit_icon(type: String) -> String:
	var record: Dictionary = _snapshot.get("catalog", {}).get("units", {}).get(type, {})
	if str(record.get("production_family",""))=="MAGIC":return "potion" if str(record.get("role",""))=="SUPPORT" else "mana"
	return str(record.get("icon", UNIT_ICONS.get(type, {"FRONTLINE":"guard", "RANGED":"bow", "HEAVY":"lancer", "SUPPORT":"potion", "CAVALRY":"lancer"}.get(str(record.get("role", "")), "army"))))

func _unit_role(type: String) -> String:
	var label:=str(_snapshot.get("catalog",{}).get("units",{}).get(type,{}).get("combat_role_label",""))
	if not label.is_empty():return label
	var role := str(_snapshot.get("catalog", {}).get("units", {}).get(type, {}).get("role", ""))
	return str({"WORKER":"自动经营", "HERO":"英雄长官", "FRONTLINE":"近战前排", "RANGED":"远程输出", "HEAVY":"重型突击", "SUPPORT":"自动支援", "CAVALRY":"机动骑兵"}.get(role, "兵员"))

func _unit_building(type: String) -> String:
	return str(_snapshot.get("catalog", {}).get("units", {}).get(type, {}).get("building_type", UNIT_BUILDINGS.get(type, "")))

func _refresh() -> void:
	_refresh_lobby()
	_secondary_surface.visible = _backdrop.visible and _panel_kind == "menu"
	_technology_button.disabled = _in_lobby()
	_composition_button.visible = not _backdrop.visible
	if _panel_kind == "recruit":
		_refresh_recruit_buildings()
		_refresh_recruit_armies()
		_update_recruit_buttons(false)
	var economy: Dictionary = _snapshot.get("economy", {}).get(_view_side(), {})
	var stock: Dictionary = economy.get("stock", {})
	var population: Dictionary = _snapshot.get("population", {}).get(_view_side(), {})
	var minutes := int(_snapshot.get("tick", 0)) * int(_snapshot.get("tick_ms", 50)) / 60000
	var seconds := int(_snapshot.get("tick", 0)) * int(_snapshot.get("tick_ms", 50)) / 1000 % 60
	_resources.stock = stock
	_resources.population = population
	_resources.refresh_upkeep(SourceInspectionM71.upkeep(_snapshot,_view_side()),economy)
	_resources.queue_redraw()
	_refresh_troop_counts()
	var phase_caption: String = "大厅" if _in_lobby() else "筹备" if _snapshot.get("phase") == "PREPARATION" else "交战"
	var outcome := str(_snapshot.get("outcome", "ONGOING"))
	if _observing(): phase_caption = "观察 · " + Palette.side_label(_view_side())
	if outcome != "ONGOING": phase_caption = {"PLAYER_VICTORY":"胜利", "PLAYER_DEFEAT":"败北", "DRAW":"平局"}.get(outcome, "已结束")
	if _observing() and outcome != "ONGOING":
		var winner := str(_snapshot.get("match_result", {}).get("winner_side_id", ""))
		phase_caption = "观战结束 · " + (Palette.side_label(winner) + "胜利" if not winner.is_empty() else "平局")
	if _command_desk_paused(): phase_caption = "暂停 · 指挥台"
	_status.text = "%s  %02d:%02d" % [phase_caption, minutes, seconds]
	_status.add_theme_color_override("font_color", Color("d8bf81") if outcome == "ONGOING" else Color("b5dc97") if outcome == "PLAYER_VICTORY" else Color("edab91"))
	_status.tooltip_text = "%s · %s\n人口：已用 + 预留 / 上限。村庄+10，根据地+30；建房不能提升人口。" % [str(_snapshot.get("match_config", {}).get("name", "边境")), str(Factions.profile(_faction_id()).get("label", "誓图"))]
	_status.tooltip_text += "\n对局种子 %d · --match-seed=%d 可复现；外观种子独立。" % [_match_seed, _match_seed]
	var timing: Dictionary = _session.live_timing()
	_status.tooltip_text += "\n实时运算待处理 %.0fms；固定50ms结算，积压保留，不跳过战斗。" % float(timing.backlog_ms)
	if float(timing.backlog_ms)>1000.0: _status.text += " · 追帧"
	_refresh_army_chips()
	_refresh_selection()
	_refresh_hero_portrait()
	_refresh_readiness()
	_refresh_site_capture()
	_refresh_computer_activity()
	_refresh_ai_difficulty()
	_refresh_management_facts()
	for button: Button in _toolbar.get_children():
		button.disabled = _in_lobby()
		button.selected = _backdrop.visible and str(button.name) == {"economy":"EconomyButton", "recruit":"RecruitButton", "build":"BuildButton", "army":"ArmyButton", "tech":"TechnologyButton", "menu":"MenuButton"}.get(_panel_kind, "")
		button.queue_redraw()
	for role: String in ["FOOD", "MATERIAL", "ESSENCE", "CONSTRUCTION_REPAIR", "RESERVE"]:
		var value := _panel_content.find_child("EconomyValue" + role, true, false) as Label
		if value != null: value.text = str(economy.get("targets", {}).get(role, 0))
	_refresh_economy_controls(economy)
	var production := _panel_content.find_child("ProductionQueueFacts", true, false) as Label
	if production != null:
		var selected_building := _building(_recruit_building_id)
		var descriptions: Array[String] = []
		for entry: Dictionary in selected_building.get("queue", []):
			descriptions.append("%s %d/%d %s" % [_unit_name(str(entry.get("unit_type", ""))), int(entry.get("progress", 0)), int(entry.get("max_progress", 1)), _queue_state(str(entry.get("state", "")))])
		production.text = "生产队列 · %d/6" % descriptions.size()
		production.tooltip_text = "队首 → 队末：" + ("空" if descriptions.is_empty() else " · ".join(descriptions))
	_refresh_cost_readouts()
	if _panel_kind == "recruit": _refresh_production_queue()
	if _panel_kind == "build": _refresh_construction_queue()
	if _panel_kind in ["army", "army_more"]: _refresh_transfer_controls()
	if _panel_kind == "tech": _refresh_technology_tree()
	if _panel_kind == "info": _refresh_information()
	if _panel_kind == "hero": _refresh_hero_controls()
	if _panel_kind == "base": _refresh_base_panel()
	if _panel_kind == "tower": _refresh_tower_panel()
	if _panel_kind == "build": _refresh_build_unlocks()
	if _panel_kind == "slot_build": _refresh_slot_build_panel()
	if _panel_kind == "economy" and OutpostSlotUI.enabled(_snapshot): _refresh_outpost_economy()
	if _panel_kind == "composition": _refresh_composition()
	if _panel_kind == "source": _refresh_resource_inspection_panel()
	_refresh_observer_controls()
	_refresh_strength_scores()
	_refresh_canvas()

func _refresh_canvas(refresh_inspection: bool = true) -> void:
	if _canvas == null: return
	if refresh_inspection:
		_refresh_actor_inspector()
		_refresh_target_controls()
	_canvas.presentation_seed_override = _presentation_seed if heroic_2d_enabled or FrontierCommandArt.enabled() else -1
	if heroic_2d_enabled or geometric_3d_enabled: _canvas.view_side_id = _view_side()
	_canvas.snapshot = _snapshot
	if heroic_2d_enabled:
		_canvas.interpolation_fraction_m76 = clampf(float(_session.live_timing().backlog_ms)/50.0,0.0,1.0)
	if _canvas.has_method("feedback_screen_offset_r9"):_canvas.screen_shake_enabled=_screen_shake_enabled_r9
	_canvas.camera = _camera
	_canvas.selected_army = _selected_warband_id
	if heroic_2d_enabled: _canvas.selected_unit_type_r12 = _selected_unit_type_r12
	_canvas.selected_unit = _selected_unit_id
	_canvas.selected_worker_id = _selected_worker_id
	_canvas.selected_site_id = _selected_site_id
	_canvas.selected_building_id = _selected_building_id
	_canvas.feedback_marks = _command_feedback.get_marks()
	_canvas.field_reward_marks = _field_reward_marks.duplicate(true)
	_canvas.aim = _skill_aim.duplicate(true)
	_canvas.blueprint_type = _blueprint_type if _target_mode == "BUILD" else ""
	_canvas.blueprint_point = _camera.screen_to_world(_pointer)
	_canvas.queue_redraw()
	_minimap.snapshot = _snapshot
	_minimap.landscape_plan = _canvas.landscape_plan
	_minimap.camera = _camera
	_minimap.queue_redraw()

func _refresh_army_chips() -> void:
	var armies := _friendly_armies()
	if _army_mode_button_r12 == null:
		_army_mode_button_r12 = _icon("army","整队","ArmyControlModeR12")
		_army_mode_button_r12.custom_minimum_size=Vector2(84,68)
		_army_mode_button_r12.pressed.connect(_toggle_army_mode_r12)
		_ui.add_child(_army_mode_button_r12)
	_army_mode_button_r12.position=Vector2(342,get_viewport_rect().size.y-82)
	_army_mode_button_r12.caption="兵种" if _army_control_mode_r12=="UNIT_TYPE" else "整队"
	_army_mode_button_r12.tooltip_text="切换整队／兵种调度。兵种模式只指挥当前军团内该兵种；切换或选择不发军令、不改名册。切回整队后下新军令才统一接管。"
	_army_mode_button_r12.visible=not _in_lobby() and not _backdrop.visible
	_army_mode_button_r12.queue_redraw()
	var parent := _army(_selected_warband_id)
	var types: Array[String] = []
	if _army_control_mode_r12=="UNIT_TYPE":
		for body: Dictionary in _snapshot.get("soldiers",[]):
			if body.get("warband_id")==_selected_warband_id and int(body.get("hp",0))>0 and str(body.unit_type) not in types: types.append(str(body.unit_type))
		types.sort()
		if not _selected_unit_type_r12.is_empty() and _selected_unit_type_r12 not in types: _selected_unit_type_r12=""
	var signature := _army_control_mode_r12+":"+(_selected_warband_id if _army_control_mode_r12=="UNIT_TYPE" else "")+":"+str(types)
	for army: Dictionary in armies: signature += "%s:%d;" % [str(army.get("id")), int(army.get("number", 0))]
	if signature != _army_signature:
		_army_signature = signature
		_clear_children(_army_chips)
		for army: Dictionary in armies if _army_control_mode_r12=="MIXED" else []:
			var id := str(army["id"])
			var chip := WarbandButtonClass.new()
			chip.name = "ArmySelect_" + id
			chip.pressed.connect(_select_army.bind(id))
			_army_chips.add_child(chip)
		for type: String in types:
			var chip := WarbandButtonClass.new()
			chip.name="TypeSelectR12_"+type
			chip.pressed.connect(_select_army_type_r12.bind(_selected_warband_id,type))
			_army_chips.add_child(chip)
	for index: int in range(armies.size() if _army_control_mode_r12=="MIXED" else 0):
		var army: Dictionary = armies[index]
		var chip := _army_chips.get_child(index)
		chip.refresh(army, _snapshot.get("soldiers", []), str(army.get("id")) == _selected_warband_id, heroic_2d_enabled)
	for index: int in range(types.size()):
		var bodies: Array = []
		for body: Dictionary in _snapshot.get("soldiers",[]):
			if body.get("unit_type")==types[index]: bodies.append(body)
		var facts: Dictionary = WarbandButtonClass.summarize(parent,bodies)
		facts["type_label"]="英雄组" if types[index]=="hero" else _unit_name(types[index])
		facts.signature=str(facts.signature)+":"+str(facts.type_label)
		_army_chips.get_child(index).refresh_summary(facts,types[index]==_selected_unit_type_r12,heroic_2d_enabled)

func _toggle_army_mode_r12() -> void:
	_steer_sent=false
	_clear_direct_input();_cancel_target()
	_army_control_mode_r12="UNIT_TYPE" if _army_control_mode_r12=="MIXED" else "MIXED"
	_selected_unit_type_r12=""
	if _army_control_mode_r12=="UNIT_TYPE" and _army(_selected_warband_id).is_empty():
		var armies := _friendly_armies()
		if not armies.is_empty(): _select_army(str(armies[0].id))
	_army_signature=""
	_refresh_army_chips();_build_context();_refresh_selection();_refresh_canvas()
	_set_feedback("兵种调度：单击下方兵种头像，再选点移动或进攻；仅作用于当前军团。" if _army_control_mode_r12=="UNIT_TYPE" else "整队调度：下一条整队军令将统一接管本军团。",6)

func _select_army_type_r12(parent: String, type: String) -> void:
	_select_army(parent)
	_selected_unit_type_r12=type
	var center:=Vector2.ZERO;var count:=0
	for body: Dictionary in _snapshot.get("soldiers",[]):
		if body.get("warband_id")==parent and body.get("unit_type")==type and int(body.get("hp",0))>0: center+=Vector2(body.position);count+=1
	if count>0: _camera.center_on(center/float(count))
	_refresh_army_chips();_build_context();_refresh_selection();_refresh_canvas()

func _selected_command_army_r12() -> Dictionary:
	var parent := _army(_selected_warband_id)
	if _selected_unit_type_r12.is_empty(): return parent
	var id := _selected_warband_id+"::type::"+_selected_unit_type_r12
	var active: Dictionary = _snapshot.get("type_cohorts_r12",{}).get(id,{})
	var result: Dictionary = (parent if active.is_empty() else active).duplicate(true)
	result["living_count"]=0
	var center:=Vector2.ZERO
	for body: Dictionary in _snapshot.get("soldiers",[]):
		if body.get("warband_id")==_selected_warband_id and body.get("unit_type")==_selected_unit_type_r12 and int(body.get("hp",0))>0:
			result.living_count+=1;center+=Vector2(body.position)
	if active.is_empty() and int(result.living_count)>0: result["anchor"]=Vector2i(center/float(result.living_count))
	return result

func _refresh_selection() -> void:
	var unit := _soldier(_selected_unit_id)
	var army := _selected_command_army_r12()
	var hero := _hero(_selected_unit_id)
	var worker := _worker(_selected_worker_id)
	var worker_alive: bool = not worker.is_empty() and int(worker.get("hp", 0)) > 0 and worker.get("side")==_view_side()
	var building := _building(_selected_building_id)
	var tower_alive: bool = building.get("building_type") in ["TOWER","SITE_TOWER"] and int(building.get("hp", 0)) > 0 and bool(building.get("complete", false))
	_info_button.visible = (not unit.is_empty() or worker_alive or not army.is_empty() or not _selected_source_id.is_empty()) and not _backdrop.visible
	_roster_button.visible = true # Its persistent parent owns secondary-menu visibility.
	var unit_alive: bool = not unit.is_empty() and bool(unit.get("alive", false)) and unit.get("side") == _view_side()
	var commandable: bool = not army.is_empty() and not army.get("reserve", false) and army.get("side") == _view_side()
	if _army_control_mode_r12=="UNIT_TYPE" and _selected_unit_type_r12.is_empty(): commandable=false
	if army.is_empty() and not _selected_warband_id.is_empty():
		_clear_direct_input()
		_selected_warband_id = ""
	_move_joystick.visible = (unit_alive or commandable) and not _backdrop.visible and _can_command()
	_attack_joystick.visible = unit_alive and not _backdrop.visible and _can_command()
	_attack_joystick.available = _snapshot.get("phase") == "BATTLE" and _snapshot.get("outcome", "ONGOING") == "ONGOING"
	_inventory_button.visible = unit_alive and not hero.is_empty() and not _backdrop.visible
	_hero_bag.visible = _inventory_button.visible and _hero_bag_fits()
	# Keep the selected identity current even when the compact layout collapses
	# this view. Resizing must not reveal another hero's stale bag for a frame.
	if _inventory_button.visible: _hero_bag.refresh(hero, int(_snapshot.get("tick", 0)), "观战只读" if _observing() else "战斗已结束" if _snapshot.get("outcome", "ONGOING") != "ONGOING" else "")
	_hero_automation_button.visible = unit_alive and not hero.is_empty() and not _backdrop.visible
	_hero_automation_button.caption = "成长" + (" +%d" % int(hero.get("skill_points", 0)) if int(hero.get("skill_points", 0)) > 0 else "")
	_hero_automation_button.queue_redraw()
	for slot: int in range(SKILLS.size()):
		var skill: String = SKILLS[slot]
		var joystick: Control = _skill_joysticks[skill]
		joystick.visible = unit_alive and not hero.is_empty() and not _backdrop.visible and _can_command()
		joystick.cooldown = 0
		joystick.max_cooldown = 0
		var skill_list: Array = hero.get("skills", [])
		if slot < skill_list.size():
			var published: Dictionary = skill_list[slot]
			if not published.is_empty():
				joystick.caption = str(published.get("name", skill))
				joystick.icon = _hero_skill_symbol(published)
				joystick.cooldown = float(published.get("cooldown_ticks", 0)) * float(_snapshot.get("tick_ms", 50)) / 1000
				joystick.max_cooldown = float(published.get("max_cooldown_ticks", 0)) * float(_snapshot.get("tick_ms", 50)) / 1000
				var mana_cost := int(published.get("mana_cost", 0))
				# The visible controls and handbook must describe the same phase
				# before learning/passive state; an ended match has no live aura.
				var availability := _handbook_skill_status(published, unit, hero)
				if availability == "未学习": availability += " · 打开成长"
				elif availability == "蓝量不足": availability += " · 需%d" % mana_cost
				joystick.set_meta("mana_cost", mana_cost)
				joystick.mana_cost = mana_cost
				joystick.tooltip_text = "%s · %s · 耗蓝%d\n%s" % [published.get("name", skill), availability, mana_cost, published.get("description", "")]
		joystick.available = unit_alive and _snapshot.get("phase") == "BATTLE" and _snapshot.get("outcome", "ONGOING") == "ONGOING" and joystick.cooldown <= 0
		if int(hero.get("mana", 0)) < int(joystick.get_meta("mana_cost", 0)): joystick.available = false
		if slot < skill_list.size(): joystick.available = joystick.available and bool(skill_list[slot].get("can_cast", false))
		# Full-health self recovery may be attempted; authority also considers
		# actual wounded allies for group healing before accepting or refusing.
		# The authoritative host refuses an ineffective heal without
		# a cooldown/HP/serial write; tooltip and handbook never say it is ready.
		joystick.queue_redraw()
	_context.visible = commandable and not _backdrop.visible and _can_command()
	# Army identity/count/intent already have one factual pixel tile row.
	# Keep this line for named units and unique worker/tower guidance only.
	_selection_label.visible = (unit_alive or worker_alive or tower_alive) and not _backdrop.visible
	_selected_facts.visible = (unit_alive or commandable or worker_alive or tower_alive) and not _backdrop.visible
	# Shared label: identity changes must not inherit another entity's controls.
	_selection_label.tooltip_text = ""
	if unit_alive:
		_selection_label.text = ("英雄 · " if not hero.is_empty() else "单兵 · ") + "%s%s" % [hero.get("name", _unit_name(str(unit.get("unit_type", "")))), " · %d级 · 蓝%d/%d" % [int(hero.get("level", 1)), int(hero.get("mana", 0)), int(hero.get("max_mana", 0))] if not hero.is_empty() else ""]
		_selection_label.tooltip_text = "单击地图行军；左摇杆移动，右侧单击或拖动瞄准攻击和技能。"
		if _observing(): _selection_label.tooltip_text = "观战只读：单击实体查看属性，单击空地不发出行军或攻击指令。"
	elif commandable:
		var intent_caption: String = {"IDLE":"待命", "HOLD":"驻守", "MOVE":"行军", "ATTACK_MOVE":"攻移", "FOCUS":"进攻", "ATTACK_BASE":"攻营", "RETREAT":"退后"}.get(str(army.get("intent", "IDLE")), "待命")
		_selection_label.text = "部队 %02d   %d 名 · %s" % [int(army.get("number", 0)), int(army.get("living_count", 0)), intent_caption]
	elif worker_alive:
		_selection_label.text = "工人 · %s · 只观察，经营中统一分派" % ROLE_NAMES.get(str(worker.get("role", "RESERVE")), "待命")
		_selection_label.tooltip_text = _selection_label.text + "\n在经营界面用加减按钮调整岗位；工人自动前往采集或施工，不支持单兵摇杆、攻击或英雄技能。"
	elif tower_alive:
		_selection_label.text = "%s · %s · %.1f名基础远程火力" % [BUILDING_NAMES.get(building.get("building_type"),"箭塔"),"自动防御" if building.get("defense_active",true) else "休眠 / 争夺中",float(building.get("ranged_equivalent",0))]
		_selection_label.tooltip_text = _selection_label.text + "\n建成后自动攻击射程内的敌人；选择箭塔只查看属性和射程，不会移动建筑或释放英雄技能。"
	else:
		_selection_label.text = ""
	if unit_alive:
		_selected_facts.refresh(_attribute_facts(unit, true))
	elif commandable:
		var formation := str(army.get("formation", "STEADY"))
		var formation_caption: String = {"STEADY":"稳阵", "LOOSE":"散阵", "COLUMN":"纵队", "SPEAR":"楔阵"}.get(formation, "阵型")
		var intent_caption: String = {"IDLE":"待命", "HOLD":"驻守", "MOVE":"行军", "ATTACK_MOVE":"攻移", "FOCUS":"进攻", "ATTACK_BASE":"攻营", "RETREAT":"退后"}.get(str(army.get("intent", "IDLE")), "待命")
		var subject_id := str(army.get("id", ""))
		_selected_facts.refresh([
			{"symbol":"army", "caption":("兵种 · %d名"%int(army.get("living_count",0))) if not _selected_unit_type_r12.is_empty() else "%02d · %d名" % [int(army.get("number", 0)), int(army.get("living_count", 0))], "inspection_id":"army-count:" + subject_id, "help_text":_selection_label.text + "\n人数不含生产队列，也不是人口占用；不同兵种人口不同。兵种模式只调度当前军团中所选兵种。"},
			{"symbol":formation, "caption":formation_caption, "inspection_id":"army-formation:" + subject_id, "help_text":"当前阵型：" + formation_caption + "\n" + HelpDescriptions.operation("Formation" + formation, "阵型")},
			{"symbol":"attack_move" if army.get("intent") in ["FOCUS", "ATTACK_MOVE", "ATTACK_BASE"] else "retreat" if army.get("intent") == "RETREAT" else "move", "caption":intent_caption, "inspection_id":"army-intent:" + subject_id, "help_text":"当前军令：" + intent_caption + "\n这是公开军令状态，不表示已抵达、命中或取胜。使用选点攻移、自动进攻、退后或回防按钮改派。"}
		])
	elif worker_alive:
		_selected_facts.refresh(_attribute_facts(worker, true))
	elif tower_alive:
		_selected_facts.refresh(_attribute_facts(building, true))
	for formation: String in ["STEADY", "LOOSE", "COLUMN", "SPEAR"]:
		var button := _context.find_child("Formation" + formation, true, false) as Button
		if button != null:
			button.selected = army.get("formation") == formation
			button.queue_redraw()
	if not unit_alive and not _selected_unit_id.is_empty(): _clear_direct_input()

func _select_army(id: String) -> void:
	_selected_source_id = ""
	if _in_lobby(): return
	_steer_sent = false # Selection must not send a delayed STOP on joystick clear.
	_clear_direct_input()
	_cancel_target()
	_selected_warband_id = id
	_selected_unit_type_r12 = ""
	_selected_unit_id = ""
	_selected_worker_id = ""
	_selected_site_id = ""
	_selected_building_id = ""
	var selected := _army(id)
	if not selected.is_empty() and selected.get("side") == _view_side(): _camera.center_on(Vector2(selected.get("anchor", _home_position())))
	_audio.record_ui("SELECT", id)
	_command_feedback.select("ARMY", id, _snapshot)
	_build_context()
	_refresh_selection()
	_refresh_canvas()
	_refresh_site_capture()

func _select_unit(id: String) -> void:
	_selected_unit_type_r12=""
	_selected_source_id = ""
	if _in_lobby(): return
	_steer_sent = false
	_clear_direct_input()
	_cancel_target()
	_selected_unit_id = id
	_selected_warband_id = ""
	_selected_worker_id = ""
	_selected_site_id = ""
	_selected_building_id = ""
	var selected := _soldier(id)
	if selected.get("unit_type") == "hero" and selected.get("side") == _view_side() and selected.get("alive", false): _camera.center_on(Vector2(selected.get("position", _home_position())))
	_audio.record_ui("SELECT", id)
	_command_feedback.select("UNIT", id, _snapshot)
	_build_context()
	_refresh_selection()
	_refresh_canvas()
	_refresh_site_capture()
	_refresh_actor_inspector()

func _build_context() -> void:
	_clear_children(_context)
	if _selected_warband_id.is_empty(): return
	for action: Array in [["attack_move", "选点攻移", "AttackMoveButton"], ["retreat", "退后", "RetreatButton"], ["sword", "自动进攻", "EngageButton"], ["home", "回防", "DefendButton"]]:
		var button := _icon(str(action[0]), str(action[1]), str(action[2]))
		button.custom_minimum_size = Vector2(84, 76) if action[0] in ["attack_move", "retreat"] else Vector2(72, 68)
		button.pressed.connect(_army_action.bind(str(action[0])))
		_context.add_child(button)
	var current := str(_army(_selected_warband_id).get("formation", "STEADY"))
	var formation_button := _icon(current, "阵型", "FormationMenuButton")
	formation_button.disabled=not _selected_unit_type_r12.is_empty()
	if formation_button.disabled: formation_button.tooltip_text="切回整队调度来调整军团阵型；兵种分队沿用军团阵型。"
	formation_button.custom_minimum_size = Vector2(84, 76)
	formation_button.pressed.connect(_open_panel.bind("formation"))
	_context.add_child(formation_button)

func _formation_panel() -> void:
	_panel_label("当前部队 · 单击选择阵型", Vector2(0, 0), 22)
	var index := 0
	for formation: String in ["STEADY", "LOOSE", "COLUMN", "SPEAR"]:
		var caption: String = {"STEADY":"方阵", "LOOSE":"散阵", "COLUMN":"纵队", "SPEAR":"突阵"}[formation]
		var button := _icon(formation, caption, "Formation" + formation)
		button.position = Vector2((index % 2) * 395, 66 + (index / 2) * 130)
		button.custom_minimum_size = Vector2(375, 110)
		button.selected = _army(_selected_warband_id).get("formation") == formation
		button.pressed.connect(func(): _formation(formation); _close_panel(); _build_context())
		_panel_content.add_child(button)
		index += 1

func _formation(value: String) -> void:
	if not _can_command(): return
	if not _selected_unit_type_r12.is_empty(): return
	_submit({"type":"SET_FORMATION", "subject_id":_selected_warband_id, "formation":value})

func _army_action(action: String) -> void:
	if not _can_command(): return
	# A newly chosen immediate order replaces the pending local point plan.
	# Cancel only presentation targeting; the command below still goes through
	# the same authoritative admission and emits its own result feedback.
	if action != "attack_move": _cancel_target(false)
	if action == "attack_move":
		_clear_direct_input()
		_target_mode = "ATTACK_MOVE"
		_audio.record_ui("UI_OPEN", "ATTACK_MOVE")
		_set_feedback("进攻式移动：单击战场目的地。\n小地图只定位；单击取消返回。", 30)
	elif action == "retreat": _submit({"type":"RETREAT", "subject_id":_selected_warband_id})
	elif action == "home": _submit({"type":"MOVE", "subject_id":_selected_warband_id, "target_position":Vector2i(_home_position())})
	else:
		var army := _selected_command_army_r12()
		var enemy_id := ""
		var closest := INF
		for candidate: Dictionary in _snapshot.get("warbands", []):
			if candidate.get("side") == _view_side() or candidate.get("reserve", false) or candidate.get("neutral", false) or int(candidate.get("living_count", 0)) <= 0: continue
			var distance := Vector2(candidate.get("anchor", Vector2.ZERO)).distance_squared_to(Vector2(army.get("anchor", Vector2.ZERO)))
			if distance < closest:
				closest = distance
				enemy_id = str(candidate["id"])
		if not enemy_id.is_empty(): _submit({"type":"FOCUS", "subject_id":_selected_warband_id, "target_warband_id":enemy_id})
		else:
			for building: Dictionary in _snapshot.get("buildings", []):
				if building.get("side") != _view_side() and building.get("building_type") == "BASE" and int(building.get("hp", 0)) > 0:
					_submit({"type":"ATTACK_BASE", "subject_id":_selected_warband_id, "target_base_id":str(building["id"])})
					return

func _open_panel(kind: String) -> void:
	_dismiss_context_help()
	if _in_lobby(): return
	_clear_direct_input()
	_cancel_target()
	if _backdrop.visible and _panel_kind == kind:
		_close_panel()
		return
	var returning_to_army := _panel_kind == "army_more"
	_panel_kind = kind
	if kind == "army" and not returning_to_army and not _selected_warband_id.is_empty(): _source_army_id = _selected_warband_id
	_panel_title.text = {"economy":"经营 · 自动分工", "recruit":"招募", "build":"建筑规划", "base":"基地 · 升级与解锁", "army":"部队调配", "army_more":"部队 · 编制操作", "formation":"部队 · 阵型", "composition":"军情总览 · 实际兵力", "tech":"兵工科技", "inventory":"英雄商店 · 独立行囊", "hero":"长官 · 自动战斗与成长", "info":"单位手册 · 属性与技能", "menu":"指挥台", "site":"领地 · 占领状态", "source":"采集点 · 有限储量与工人", "computer":"规则电脑 · 实际行动", "difficulty":"电脑难度 · 运营与进攻节奏"}.get(kind, kind)
	if kind == "perspective": _panel_title.text = "观战 · 选择玩家视角"
	elif kind == "slot_build": _panel_title.text = "固定空位 · 确认建造"
	elif OutpostSlotUI.enabled(_snapshot) and kind == "economy": _panel_title.text = "领地产出 · 自动经营"
	elif OutpostSlotUI.enabled(_snapshot) and kind == "build": _panel_title.text = "建筑空位 · 领地总览"
	elif OutpostSlotUI.enabled(_snapshot) and kind == "source": _panel_title.text = "资源来源 · 占领与自动产出"
	elif _observing() and kind not in ["menu", "computer", "credits"]: _panel_title.text += " · 只读"
	_audio.record_ui("UI_OPEN", kind)
	_backdrop.show()
	_populate_panel()
	_refresh_selection()
	_refresh()

func _close_panel() -> void:
	var was_paused := _command_desk_paused()
	_dismiss_context_help()
	if _backdrop.visible: _audio.record_ui("UI_CLOSE", _panel_kind)
	# Popup menus are separate windows; hide them before the backdrop so an
	# old dropdown cannot receive a later terrain click after this panel closes.
	for child: Node in _panel_content.get_children():
		if child is OptionButton: child.get_popup().hide()
	_backdrop.hide()
	_secondary_surface.hide()
	_panel_kind = ""
	get_viewport().gui_release_focus()
	_refresh_selection()
	_refresh_hero_portrait()
	_refresh_readiness()
	_refresh_site_capture()
	for button: Button in _toolbar.get_children():
		button.selected = false
		button.queue_redraw()
	_refresh_observer_controls()
	if was_paused: _refresh()

func _on_backdrop_input(event: InputEvent) -> void:
	# Keep the backdrop present for the complete tap. Closing on touch-down
	# can expose a command button to the same touch's emulated mouse release.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed: _close_panel()
		_backdrop.accept_event()
	elif event is InputEventScreenTouch:
		if not event.pressed and not event.canceled: _close_panel()
		_backdrop.accept_event()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		_backdrop.accept_event()

func _populate_panel() -> void:
	_recruit_catalog = null
	_build_catalog = null
	_transfer_rows = null
	_clear_children(_panel_content)
	match _panel_kind:
		"economy": _economy_panel()
		"recruit": _recruit_panel()
		"build": _build_panel()
		"slot_build": _slot_build_panel()
		"base": _base_panel()
		"tower": _tower_panel()
		"army": _army_panel()
		"army_more": _army_more_panel()
		"formation": _formation_panel()
		"composition": _composition_panel()
		"tech": _technology_panel()
		"inventory": _inventory_panel()
		"hero": _hero_controls_panel()
		"info": _information_panel()
		"menu": _menu_panel()
		"credits": _heroic_credits_panel()
		"site": _site_capture_panel()
		"source": _resource_inspection_panel()
		"computer": _computer_activity_panel()
		"difficulty": _ai_difficulty_panel()
		"perspective": _perspective_panel()

func _economy_panel() -> void:
	if OutpostSlotUI.enabled(_snapshot):
		_outpost_economy_panel()
		return
	var hint := _panel_label("分派 → 自动工作", Vector2(0, 0), 20)
	hint.tooltip_text = "现有工人自动往返；建筑工依序前往蓝图。加减分派不创造工人，待命人数来自真实工人。"
	var index := 0
	for role: String in ROLES:
		var y := 44 + index * 70
		var icon := _icon("food" if role == "FOOD" else "material" if role == "MATERIAL" else "essence" if role == "ESSENCE" else "build", ROLE_NAMES[role], "RoleIcon" + role)
		icon.position = Vector2(0, y)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel_content.add_child(icon)
		var minus := _button("−1", "EconomyMinus" + role, Vector2(84, 60))
		minus.position = Vector2(105, y)
		minus.pressed.connect(_change_role.bind(role, -1))
		_panel_content.add_child(minus)
		var value := _panel_label("0", Vector2(212, y + 15), 28)
		value.name = "EconomyValue" + role
		var plus := _button("+1", "EconomyPlus" + role, Vector2(84, 60))
		plus.position = Vector2(285, y)
		plus.pressed.connect(_change_role.bind(role, 1))
		_panel_content.add_child(plus)
		index += 1
	var reserve := _panel_label("0", Vector2(510, 57), 28)
	reserve.name = "EconomyValueRESERVE"
	reserve.hide()
	_fact_view("EconomyRosterFacts", Vector2(420, 45), Vector2(336, 67))
	# Actual finite sources at the selected economic site. The two cards are
	# read-only facts; macro role allocation and one site selector stay intact.
	_fact_view("WorkResourceSourceFacts", Vector2(0, 328), Vector2(380, 72))
	_panel_label("普通采矿根据地", Vector2(420, 114), 18)
	var sites := _option("WorkSiteOption", Vector2(420, 140), Vector2(336, 48))
	sites.item_selected.connect(func(value: int): _submit({"type":"SET_WORK_SITE", "site_id":str(sites.get_item_metadata(value))}))
	_panel_label("灵髓矿点 · 须完工矿场", Vector2(420, 198), 18)
	var essence_sites := _option("EssenceSiteOption", Vector2(420, 226), Vector2(336, 48))
	essence_sites.item_selected.connect(func(value: int): _submit({"type":"SET_ESSENCE_SITE", "site_id":str(essence_sites.get_item_metadata(value))}))
	var worker := _button("工人 +1", "RecruitWorkerButton", Vector2(336, 54))
	worker.position = Vector2(420, 288)
	worker.pressed.connect(_recruit_worker)
	_panel_content.add_child(worker)
	var worker_recipe: Dictionary = _snapshot.get("catalog", {}).get("units", {}).get("worker", {})
	_cost_view("WorkerRecruitCostIcons", Vector2(420, 344), Vector2(330, 36), worker_recipe.get("cost", {}), int(worker_recipe.get("population", 1)))
	var logistics := _panel_label("食物 / 矿材单点5人 · 灵髓%d人" % EconomyCatalog.ESSENCE_WORKER_CAP, Vector2(420, 382), 16)
	logistics.name = "EconomyLogisticsHint"
	logistics.size = Vector2(336, 21)
	logistics.tooltip_text = "完工营所出工人；真实工人从选定矿点采集，并交到该矿点附近的完工营所。"
	_refresh()

func _refresh_work_sites() -> void:
	_refresh_work_site_option("WorkSiteOption", false)
	_refresh_work_site_option("EssenceSiteOption", true)

func _refresh_work_site_option(node_name: String, essence: bool) -> void:
	var option := _panel_content.find_child(node_name, true, false) as OptionButton
	if option == null: return
	var owned: Array[Dictionary] = []
	var ids: Array[String] = []
	for site: Dictionary in _snapshot.get("sites", []):
		if site.get("owner") == _view_side() and site.get("kind") == "RESOURCE" and (site.get("resource") == "ESSENCE") == essence:
			owned.append(site)
			ids.append(str(site["id"]))
	var current_ids: Array[String] = []
	for index: int in range(option.item_count): current_ids.append(str(option.get_item_metadata(index)))
	if current_ids != ids:
		# Ownership may change while this panel stays open. Rebuild membership
		# only; ordinary worker/stock ticks must not close an unchanged popup.
		option.get_popup().hide()
		option.clear()
		for site: Dictionary in owned:
			_add_option(option, _work_site_caption(site,essence), str(site["id"]))
	else:
		for index: int in range(owned.size()):
			var caption := _work_site_caption(owned[index],essence)
			if option.get_item_text(index) != caption: option.set_item_text(index, caption)
	option.disabled = owned.is_empty()
	var selected := str(_snapshot.get("economy", {}).get(_view_side(), {}).get("essence_site_id" if essence else "work_site_id", ""))
	if selected in ids:
		_choose_option(option, selected)
	else:
		# Do not display the first owned location as if the host selected it.
		option.select(-1)
		option.text = "未选择矿点" if not ids.is_empty() else "没有己方灵髓点" if essence else "没有己方资源点"
	option.tooltip_text = "灵髓单独选点；先清除强大守军并占领，附近建成灵髓矿场后分派采集工，每点最多%d名。" % EconomyCatalog.ESSENCE_WORKER_CAP if essence else "选择已占领的资源根据地；采集还需要附近有存活且完工的营所。"

func _work_site_caption(site: Dictionary, essence: bool) -> String:
	if not essence: return "%s  +%d" % [site["id"],int(site.get("capacity",30))]
	for source: Dictionary in _snapshot.get("resource_sources",[]):
		if source.get("site_id") == site.id and source.get("kind") == "ESSENCE": return "%s · 余%d · %s" % [site.id,int(source.get("remaining_amount",0)),"可采" if source.get("active",false) else "待建矿场"]
	return "%s · 没有可用灵髓来源" % site.id

func _refresh_economy_controls(economy: Dictionary) -> void:
	var targets: Dictionary = economy.get("targets", {})
	for role: String in ROLES:
		for delta: int in [-1, 1]:
			var name_prefix := "EconomyPlus" if delta > 0 else "EconomyMinus"
			var button := _panel_content.find_child(name_prefix + role, true, false) as Button
			if button == null: continue
			var reason := _economy_change_reason(role, delta, targets)
			button.disabled = not reason.is_empty()
			button.tooltip_text = "%s岗位%d · 待命%d\n%s\n%s" % [ROLE_NAMES[role], int(targets.get(role, 0)), int(targets.get("RESERVE", 0)), HelpDescriptions.operation(name_prefix + role, button.text), "不可用：" + reason if not reason.is_empty() else "单击调配1人；不消耗资源，不新增工人。"]
			button.queue_redraw()

func _economy_change_reason(role: String, delta: int, targets: Dictionary) -> String:
	if not _can_command(): return "请先开始对局" if _in_lobby() else "观察模式不能调配工人"
	if _snapshot.get("outcome", "ONGOING") != "ONGOING": return "战斗已结束"
	if delta < 0 and int(targets.get(role, 0)) <= 0: return "此岗位已无人可减少"
	if delta > 0 and int(targets.get("RESERVE", 0)) <= 0: return "没有待命工人；先减少其他岗位或招募工人"
	# World can fall back from the selected site to another usable mine. Its
	# published active source already includes ownership, stock and depot.
	if delta > 0 and role in ["MATERIAL","ESSENCE"]:
		for source: Dictionary in _snapshot.get("resource_sources", []):
			if source.get("kind") == role and source.get("owner") == _view_side() and source.get("active", false) and int(source.get("remaining_amount", 0)) > 0: return ""
		return "没有可用灵髓矿源；先占领并建成灵髓矿场" if role == "ESSENCE" else "没有可用矿源；需己方有余矿且附近有完工营所，现有矿工会自动转为待命"
	return ""

func _change_role(role: String, delta: int) -> void:
	if not _can_command(): return
	if OutpostSlotUI.enabled(_snapshot): return
	_submit({"type":"SET_ECONOMY_TARGETS", "changes":[{"role":role, "delta":delta}]})

func _recruit_worker() -> void:
	if not _can_command(): return
	if OutpostSlotUI.enabled(_snapshot): return
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") == _view_side() and building.get("building_type") == "BASE" and building.get("complete", false) and int(building.get("hp", 0)) > 0:
			_submit({"type":"ENQUEUE_UNIT", "building_id":str(building["id"]), "unit_type":"worker", "warband_id":""})
			return
	_set_feedback("没有完工根据地。", 4)

func _recruit_panel() -> void:
	_panel_label("出兵建筑", Vector2(0, 0), 18)
	var buildings := _option("RecruitBuildingOption", Vector2(0, 24), Vector2(360, 48))
	var available_buildings := _recruit_buildings()
	for building: Dictionary in available_buildings:
		_add_option(buildings, "%s · %s" % [building.get("label",_building_display_name(str(building.get("building_type","")),str(building.side))), building["id"]], str(building["id"]))
	_recruit_building_signature = ",".join(available_buildings.map(func(building: Dictionary) -> String: return str(building["id"])))
	if not _recruit_source_initialized and _recruit_building_id.is_empty():
		_recruit_building_id = str(buildings.get_item_metadata(0)) if buildings.item_count > 0 else ""
	_recruit_source_initialized = true
	_select_recruit_producer(buildings)
	_normalize_recruit_type()
	buildings.item_selected.connect(func(value: int): _recruit_building_id = str(buildings.get_item_metadata(value)); _normalize_recruit_type(); _recruit_catalog.set_category("CURRENT"); _update_recruit_buttons())
	var receiving_caption := _panel_label("接收部队", Vector2(395, 0), 18)
	receiving_caption.name = "ReceivingArmyCaption"
	var armies := _option("ReceivingArmyOption", Vector2(395, 24), Vector2(360, 48))
	_add_option(armies, "预备池 · 稍后调配", "")
	for army: Dictionary in _friendly_armies(): _add_option(armies, "部队 %02d · %d名" % [int(army.get("number", 0)), int(army.get("living_count", 0))], str(army["id"]))
	if not _receiving_army_initialized:
		if not _selected_warband_id.is_empty(): _receiving_army_id = _selected_warband_id
		_receiving_army_initialized = true
	_select_recipient_option(armies)
	_receiving_army_signature = ",".join(_friendly_armies().map(func(army: Dictionary) -> String: return str(army.id)))
	armies.item_selected.connect(func(value: int): _receiving_army_id = str(armies.get_item_metadata(value)); _update_recruit_buttons())
	_recruit_catalog = CatalogGridClass.new()
	_recruit_catalog.name = "RecruitCatalog"
	_recruit_catalog.position = Vector2(0, 78)
	_recruit_catalog.size = Vector2(480, 208)
	_panel_content.add_child(_recruit_catalog)
	_recruit_catalog.configure(_recruit_display_items(), [{"id":"CURRENT", "label":"本建筑"}, {"id":"ALL", "label":"全部兵种"}, {"id":"LOCKED", "label":"解锁预览"}], "RecruitType_")
	_recruit_catalog.set_category("CURRENT")
	_recruit_catalog.item_chosen.connect(_choose_recruit_type)
	var archetypes := _option("RecruitHeroArchetype", Vector2(500, 78), Vector2(270, 44))
	for archetype: String in _hero_archetypes():
		var profile := HeroCatalog.profile(archetype)
		_add_option(archetypes, "%s · %s" % [profile.name, profile.role], archetype)
	_choose_option(archetypes, _recruit_archetype)
	archetypes.item_selected.connect(func(index: int): _recruit_archetype = str(archetypes.get_item_metadata(index)); _update_recruit_buttons())
	var brief := _panel_label("", Vector2(500, 126), 16)
	brief.name = "RecruitUnitBrief"
	brief.size = Vector2(350, 40)
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brief.hide()
	var role_brief := _panel_label("", Vector2(500, 84), 17)
	role_brief.name = "RecruitRoleBrief"
	role_brief.size = Vector2(270, 36)
	_fact_view("RecruitAttributeIcons", Vector2(500, 130), Vector2(270, 40))
	var detail := _button("属性 / 特性", "RecruitInformationButton", Vector2(270, 46))
	detail.position = Vector2(500, 270)
	detail.pressed.connect(func(): _info_type = _recruit_unit_type; _info_archetype = _recruit_archetype; _info_unit_id = ""; _open_panel("info"))
	_panel_content.add_child(detail)
	var description := _panel_label("", Vector2(500, 175), 18)
	description.name = "RecruitCostFacts"
	description.size = Vector2(270, 50)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cost_view("RecruitCostIcons", Vector2(500, 230), Vector2(270, 36), {}, 1)
	var recruit := _button("招募 +1", "ConfirmRecruitButton", Vector2(230, 66))
	recruit.position = Vector2(540, 330)
	recruit.pressed.connect(_confirm_recruit)
	_panel_content.add_child(recruit)
	var cancel := _button("撤销首", "CancelRecruitButton", Vector2(104, 48))
	cancel.position = Vector2(276, 288)
	cancel.add_theme_font_size_override("font_size", 18)
	cancel.pressed.connect(_cancel_recruit.bind(false))
	_panel_content.add_child(cancel)
	var tail := _button("撤销末", "CancelRecruitTailButton", Vector2(104, 48))
	tail.position = Vector2(386, 288)
	tail.add_theme_font_size_override("font_size", 18)
	tail.pressed.connect(_cancel_recruit.bind(true))
	_panel_content.add_child(tail)
	var queue := _panel_label("", Vector2(0, 302), 17)
	queue.name = "ProductionQueueFacts"
	queue.size = Vector2(266, 28)
	_queue_view("ProductionQueueIcons", Vector2(0, 340), Vector2(522, 60))
	_update_recruit_buttons()

func _select_recruit_producer(option: OptionButton) -> void:
	var found := false
	for index: int in range(option.item_count):
		if str(option.get_item_metadata(index)) == _recruit_building_id: found = true
	if not found: _add_option(option, "来源已失效 · 请另选建筑" if not _recruit_building_id.is_empty() else "请选择出兵建筑", _recruit_building_id)
	_choose_option(option, _recruit_building_id)

func _hero_quote(archetype: String) -> Dictionary:
	# Quotes are detached authority facts, not a second economy implementation.
	# Missing publication must never silently charge/display the generic recipe.
	return _snapshot.get("hero_quotes", {}).get(_view_side(), {}).get(archetype, {}).duplicate(true)

func _recruit_recipe(type: String, archetype: String = "") -> Dictionary:
	var recipe: Dictionary = _snapshot.get("catalog", {}).get("units", {}).get(type, {}).duplicate(true)
	if type != "hero": return recipe
	var quote := _hero_quote(_recruit_archetype if archetype.is_empty() else archetype)
	recipe["cost"] = quote.get("cost", {}).duplicate(true)
	recipe["duration"] = int(quote.get("duration_ticks", 0))
	recipe["population"] = int(quote.get("population", 5))
	recipe["required_base_tier"] = int(quote.get("required_base_tier", 1))
	return recipe

func _hero_quote_action(quote: Dictionary) -> String:
	if quote.is_empty(): return "英雄报价暂不可用"
	if quote.get("mode") == "REVIVE": return "复活等级%d英雄" % int(quote.get("level", 1))
	if int(quote.get("hero_slot", 0)) <= 0: return "无法新增英雄"
	return "招募第%d英雄" % int(quote.get("hero_slot", 2))

func _hero_quote_summary(quote: Dictionary) -> String:
	if quote.is_empty(): return "英雄报价暂不可用，请重新打开招募面板。"
	return "%s · %.1f秒\n%s" % [_hero_quote_action(quote), int(quote.get("duration_ticks", 0)) * 0.05, _help_cost(quote.get("cost", {}), int(quote.get("population", 5)))]

func _hero_quote_block_reason(quote: Dictionary) -> String:
	if quote.is_empty(): return "英雄报价暂不可用，请重新打开招募面板"
	if quote.get("accepted", false): return ""
	return str({"HERO_ROSTER_FULL":"英雄名册已满（死亡不腾位）", "BASE_TIER_REQUIRED":"需%d级基地 · 当前%d级" % [int(quote.get("required_base_tier", 2)), _base_tier()], "HERO_ALREADY_ALIVE":"该英雄已在阵中", "HERO_ALREADY_QUEUED":"该英雄已排队招募或复活", "FOREIGN_FACTION_HERO":"只能招募本族英雄", "HERO_QUOTE_UNAVAILABLE":"英雄报价暂不可用，请重开面板"}.get(str(quote.get("error", "")), "当前英雄不可招募，请查看名册条件"))

func _recruit_lock_reason(type: String) -> String:
	if _observing(): return "观战只读：不能招募"
	if type not in ["worker","hero"] and not UnitsV4.is_recruitable(type):return "该兵种已退出本版招募"
	var building := _building(_recruit_building_id)
	if building.is_empty() or building.get("side") != _view_side() or int(building.get("hp", 0)) <= 0 or not building.get("complete", false): return "出兵建筑已失效，请另选"
	if str(building.get("building_type", "")) != _unit_building(type): return "需要" + _building_display_name(_unit_building(type))
	var recipe := _recruit_recipe(type)
	if type == "hero":
		var hero_reason := _hero_quote_block_reason(_hero_quote(_recruit_archetype))
		if not hero_reason.is_empty(): return hero_reason
	var required := int(recipe.get("required_base_tier", _snapshot.get("catalog", {}).get("progression", {}).get("unit_tiers", {}).get(type, 1)))
	if _base_tier() < required: return "需%d级基地 · 当前%d级" % [required, _base_tier()]
	for kind: String in recipe.get("required_buildings",[]):
		var ready:=false
		for candidate: Dictionary in _snapshot.get("buildings",[]):
			if candidate.get("side")==_view_side() and candidate.get("building_type")==kind and bool(candidate.get("complete",false)) and int(candidate.get("hp",0))>0:ready=true;break
		if not ready:return "需要已完工"+_building_display_name(kind)
	if type != "worker" and not _receiving_army_id.is_empty() and _army(_receiving_army_id).is_empty(): return "接收部队已失效，请重新选择"
	# Reflect the existing authority's paid-admission order. This is a detached
	# affordance only; _confirm_recruit refreshes it and World still validates.
	var queue_limit := int(_snapshot.get("catalog", {}).get("production_queue_limit", 0))
	if queue_limit > 0 and building.get("queue", []).size() >= queue_limit: return "生产队列已满（%d/%d）" % [building.queue.size(), queue_limit]
	var population: Dictionary = _snapshot.get("population", {}).get(_view_side(), {})
	if not population.is_empty():
		var required_population := int(recipe.get("population", 1))
		if int(population.used) + int(population.reserved) + required_population > int(population.maximum): return "人口不足：%d + %d / %d，需%d" % [population.used, population.reserved, population.maximum, required_population]
	var stock: Dictionary = _snapshot.get("economy", {}).get(_view_side(), {}).get("stock", {})
	var cost: Dictionary = recipe.get("cost", {})
	for resource: String in ["FOOD", "MATERIAL", "ESSENCE"]:
		if int(stock.get(resource, 0)) < int(cost.get(resource, 0)): return "%s不足：需要%d，现有%d" % [EconomyCatalog.RESOURCE_LABELS[resource], int(cost[resource]), int(stock.get(resource, 0))]
	return ""

func _select_recipient_option(option: OptionButton) -> void:
	var found := false
	for index: int in range(option.item_count):
		if str(option.get_item_metadata(index)) == _receiving_army_id: found = true
	if not found: _add_option(option, "接收部队已失效 · 请另选", _receiving_army_id)
	_choose_option(option, _receiving_army_id)

func _refresh_recruit_armies() -> void:
	var option := _panel_content.find_child("ReceivingArmyOption", true, false) as OptionButton
	if option == null: return
	var armies := _friendly_armies()
	var signature: String = ",".join(armies.map(func(army: Dictionary) -> String: return str(army.id)))
	if signature == _receiving_army_signature:
		# Identity stability does not imply stable troop counts. Refresh rows in
		# place so casualties/transfers do not close an open recipient popup.
		for army: Dictionary in armies:
			var caption := "%s · %d名" % [_army_label(str(army.id)), int(army.get("living_count", 0))]
			for index: int in range(option.item_count):
				if str(option.get_item_metadata(index)) == str(army.id) and option.get_item_text(index) != caption:
					option.set_item_text(index, caption)
		if option.selected >= 0: _update_option_caption(option, option.selected)
		return
	_receiving_army_signature = signature
	option.get_popup().hide()
	option.clear()
	_add_option(option, "预备池 · 稍后调配", "")
	for army: Dictionary in armies: _add_option(option, "%s · %d名" % [_army_label(str(army.id)), int(army.get("living_count", 0))], str(army.id))
	_select_recipient_option(option)

func _recruit_display_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var stock: Dictionary = _snapshot.get("economy", {}).get(_view_side(), {}).get("stock", {})
	for type: String in _unit_types():
		var recipe := _recruit_recipe(type)
		var reason := _recruit_lock_reason(type)
		var categories: Array[String] = []
		if str(_building(_recruit_building_id).get("building_type", "")) == _unit_building(type): categories.append("CURRENT")
		if not reason.is_empty(): categories.append("LOCKED")
		var visual := _base_unit_stats(type, _recruit_archetype).duplicate(true)
		visual["unit_type"] = type
		visual["side"] = _view_side()
		visual["faction_id"] = _faction_id()
		visual["hero_archetype"] = _recruit_archetype
		items.append({"id":type, "label":_unit_name(type), "kind":"UNIT", "categories":categories, "visual":visual, "role":_hero_quote_action(_hero_quote(_recruit_archetype)) if type == "hero" else _unit_role(type), "cost":recipe.get("cost", {}), "population":int(recipe.get("population", 1)), "required_tier":int(recipe.get("required_base_tier", 1)), "locked_reason":reason, "stock":stock})
	return items

func _choose_recruit_type(value: String) -> void:
	_recruit_unit_type = value
	_update_recruit_buttons()

func _update_recruit_buttons(refresh_view: bool = true) -> void:
	var building := _building(_recruit_building_id)
	if _recruit_catalog != null:
		_recruit_catalog.refresh_items(_recruit_display_items())
		_recruit_catalog.select_item(_recruit_unit_type)
	var label := _panel_content.find_child("RecruitCostFacts", true, false) as Label
	if label != null: label.text = "%s · 每单1名" % _unit_name(_recruit_unit_type)
	var lock_reason := _recruit_lock_reason(_recruit_unit_type)
	if label != null and not lock_reason.is_empty(): label.text += "\n" + lock_reason
	var recipe := _recruit_recipe(_recruit_unit_type)
	var pictograms := _panel_content.find_child("RecruitCostIcons", true, false) as Control
	if pictograms != null:
		pictograms.set_meta("cost", recipe.get("cost", {}).duplicate(true))
		pictograms.set_meta("population", int(recipe.get("population", 1)))
	var confirm := _panel_content.find_child("ConfirmRecruitButton", true, false) as Button
	if _recruit_unit_type != "hero":
		if label != null and label.has_meta("hero_quote"): label.remove_meta("hero_quote")
		if confirm != null and confirm.has_meta("hero_quote"): confirm.remove_meta("hero_quote")
	if confirm != null:
		confirm.disabled = not lock_reason.is_empty()
		confirm.text = "招募 +1"
		confirm.tooltip_text = lock_reason if not lock_reason.is_empty() else "每单生产1名；升级中的本基地订单暂停，完工后继续。"
	if _recruit_unit_type == "hero":
		var quote := _hero_quote(_recruit_archetype)
		if label != null:
			label.text = "%s · %.1f秒" % [_hero_quote_action(quote), int(quote.get("duration_ticks", 0)) * 0.05]
			label.set_meta("hero_quote", quote.duplicate(true))
			if not lock_reason.is_empty(): label.text += "\n" + lock_reason
		if confirm != null:
			confirm.text = "复活英雄" if quote.get("mode") == "REVIVE" else _hero_quote_action(quote)
			confirm.tooltip_text = (lock_reason + "\n" if not lock_reason.is_empty() else "") + _hero_quote_summary(quote) + "\n整局最多三种英雄，死亡仍占名册。新招募第二／三位需二／三级基地；已拥有英雄在幸存祭庭复活，不重复要求基地等级。复活满血满蓝，保留成长、现有行囊及剩余冷却；死亡掉落的装备不返还。"
			confirm.set_meta("hero_quote", quote.duplicate(true))
	var selector := _panel_content.find_child("RecruitHeroArchetype", true, false) as OptionButton
	if selector != null: selector.visible = _recruit_unit_type == "hero"
	var brief := _panel_content.find_child("RecruitUnitBrief", true, false) as Label
	if brief != null:
		brief.text = _unit_brief(_recruit_unit_type, _recruit_archetype)
	var attributes := _panel_content.find_child("RecruitAttributeIcons", true, false) as Control
	if attributes != null:
		attributes.refresh(_attribute_facts(_base_unit_stats(_recruit_unit_type, _recruit_archetype)))
		attributes.tooltip_text = _unit_brief(_recruit_unit_type, _recruit_archetype) + "\n" + _unit_trait(_recruit_unit_type, _recruit_archetype)
	var role_label := _panel_content.find_child("RecruitRoleBrief", true, false) as Label
	if role_label != null:
		role_label.visible = _recruit_unit_type != "hero"
		role_label.text = _unit_name(_recruit_unit_type) + " · " + _unit_role(_recruit_unit_type)
	var recipient := _panel_content.find_child("ReceivingArmyOption", true, false) as OptionButton
	if recipient != null:
		var worker := _recruit_unit_type == "worker"
		recipient.disabled = worker
		recipient.set_item_text(0, "经营待命队列" if worker else "预备池 · 稍后调配")
		if worker:
			_choose_option(recipient, "")
			recipient.tooltip_text = "工人进入经营待命队列，不加入军团；可在经营面板分派。"
		else: _receiving_army_id = _choose_option(recipient, _receiving_army_id)
		var recipient_caption := _panel_content.find_child("ReceivingArmyCaption", true, false) as Label
		if recipient_caption != null: recipient_caption.text = "经营队列" if worker else "接收部队"
	if refresh_view: _refresh()

func _recruit_buildings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# A service or decoration may be complete and friendly without producing
	# troops. Derive sources from this faction's real recipes, rather than a
	# historical list of excluded building kinds (which admitted fixed shops).
	var producer_types := {}
	for type: String in _unit_types(): producer_types[_unit_building(type)] = true
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") == _view_side() and building.get("complete", false) and int(building.get("hp", 0)) > 0 and producer_types.has(str(building.get("building_type", ""))):
			result.append(building)
	return result

func _refresh_recruit_buildings() -> void:
	var option := _panel_content.find_child("RecruitBuildingOption", true, false) as OptionButton
	if option == null: return
	var buildings := _recruit_buildings()
	var signature: String = ",".join(buildings.map(func(building: Dictionary) -> String: return str(building["id"])))
	if signature == _recruit_building_signature: return
	_recruit_building_signature = signature
	option.get_popup().hide()
	option.clear()
	for building: Dictionary in buildings:
		_add_option(option, "%s · %s" % [building.get("label",_building_display_name(str(building.get("building_type","")),str(building.side))), building["id"]], str(building["id"]))
	_select_recruit_producer(option)
	option.disabled = buildings.is_empty() and _recruit_building_id.is_empty()
	_update_recruit_buttons(false)

func _normalize_recruit_type() -> void:
	var building := _building(_recruit_building_id)
	var archetypes := _hero_archetypes()
	if not archetypes.is_empty() and _recruit_archetype not in archetypes: _recruit_archetype = archetypes[0]
	if _recruit_unit_type not in _unit_types() or str(building.get("building_type", "")) != _unit_building(_recruit_unit_type):
		for unit_type: String in _unit_types():
			if str(building.get("building_type", "")) == _unit_building(unit_type):
				_recruit_unit_type = unit_type
				break

func _confirm_recruit() -> void:
	if not _can_command(): return
	_snapshot = _session.get_snapshot()
	var reason := _recruit_lock_reason(_recruit_unit_type)
	if not reason.is_empty():
		_set_feedback(reason, 4)
		_refresh()
		return
	var command := {"type":"ENQUEUE_UNIT", "building_id":_recruit_building_id, "unit_type":_recruit_unit_type, "warband_id":"" if _recruit_unit_type == "worker" else _receiving_army_id}
	if _recruit_unit_type == "hero": command["hero_archetype"] = _recruit_archetype
	_submit(command)

func _cancel_recruit(from_tail: bool = false) -> void:
	if not _can_command(): return
	var building := _building(_recruit_building_id)
	var queue: Array = building.get("queue", [])
	if not queue.is_empty():
		var entry: Dictionary = queue[-1] if from_tail else queue[0]
		_submit({"type":"CANCEL_PRODUCTION", "entry_id":str(entry.get("entry_id", entry.get("id", "")))})
	else: _set_feedback("生产队列为空。", 3)

func _refresh_production_queue() -> void:
	var building := _building(_recruit_building_id)
	var queue: Array = building.get("queue", [])
	var entries: Array[Dictionary] = []
	for entry: Dictionary in queue:
		var unit_type := str(entry.get("unit_type", ""))
		var projected := {"id":str(entry.get("entry_id", entry.get("id", ""))), "symbol":_unit_icon(unit_type), "caption":_unit_name(unit_type), "state":_queue_state(str(entry.get("state", ""))), "progress":int(entry.get("progress", 0)), "max_progress":int(entry.get("max_progress", 1)), "work_kind":"production", "cost":entry.get("cost", {}), "population":int(entry.get("population", 0))}
		if unit_type == "hero":
			# Paid orders retain their own identity even while the player browses
			# another hero recipe. Never use the current picker as queue facts.
			var archetype := str(entry.get("hero_archetype", HeroCatalog.DEFAULT_ARCHETYPE))
			var profile := HeroCatalog.profile(archetype)
			projected["hero_archetype"] = archetype
			projected["caption"] = str(profile.get("name", "英雄"))
			var action := "复活等级%d英雄" % int(entry.get("hero_level", 1)) if entry.get("hero_mode") == "REVIVE" else "招募第%d英雄" % int(entry.get("hero_slot", 2))
			projected["description"] = "%s · %s\n%s；按入队时实付价格退款，不随当前报价变化。" % [str(profile.get("title", "")), str(profile.get("role", "")), action]
			projected["hero_mode"] = str(entry.get("hero_mode", "RECRUIT"))
			projected["hero_slot"] = int(entry.get("hero_slot", 2))
			projected["hero_level"] = int(entry.get("hero_level", 1))
		entries.append(projected)
	var display := _panel_content.find_child("ProductionQueueIcons", true, false) as Control
	if display != null: display.refresh(entries)
	for node_name: String in ["CancelRecruitButton", "CancelRecruitTailButton"]:
		var button := _panel_content.find_child(node_name, true, false) as Button
		if button != null:
			button.disabled = queue.is_empty()
			button.tooltip_text = "取消此建筑队首/队末真实订单，并返还该单费用与预留人口。"

func _construction_queue() -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") == _view_side() and (building.get("building_type") != "SITE_TOWER" or building.get("paid_rebuild_pending",false)) and not building.get("complete", false) and int(building.get("hp", 0)) > 0:
			queue.append(building)
	return queue

func _refresh_construction_queue() -> void:
	var queue := _construction_queue()
	var entries: Array[Dictionary] = []
	for building: Dictionary in queue:
		var type := str(building.get("building_type", ""))
		entries.append({"id":str(building["id"]), "symbol":type, "caption":building.get("label",_building_display_name(type,str(building.side))), "state":_queue_state(str(building.get("state", "BLUEPRINT"))), "progress":int(building.get("progress", 0)), "max_progress":int(building.get("max_progress", 1)), "work_kind":"construction", "cost":building.get("cost", {})})
	var display := _panel_content.find_child("ConstructionQueueIcons", true, false) as Control
	if display != null: display.refresh(entries)
	var facts := _panel_content.find_child("ConstructionQueueFacts", true, false) as Label
	if facts != null: facts.text = "施工队列 · %d · 队首 → 队末" % queue.size()
	for node_name: String in ["CancelConstructionHeadButton", "CancelConstructionTailButton"]:
		var button := _panel_content.find_child(node_name, true, false) as Button
		if button != null:
			button.disabled = queue.is_empty()
			button.tooltip_text = "移除队首/队末未完工蓝图并返还费用；已完工建筑不能取消。"

func _cancel_construction(from_tail: bool) -> void:
	if not _can_command(): return
	var queue := _construction_queue()
	if queue.is_empty(): return
	var building: Dictionary = queue[-1] if from_tail else queue[0]
	_submit({"type":"CANCEL_CONSTRUCTION", "building_id":str(building["id"])})

func _base_panel() -> void:
	_base_option_signature = "__UNINITIALIZED__"
	var choices := _option("BaseUpgradeOption", Vector2(0, 0), Vector2(460, 52))
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") == _view_side() and building.get("building_type") == "BASE" and int(building.get("hp", 0)) > 0 and building.get("complete", false):
			_add_option(choices, "%d级营所 · %s" % [int(building.get("base_tier", 1)), str(building.id)], str(building.id))
	_base_building_id = _choose_option(choices, _base_building_id)
	choices.item_selected.connect(func(index: int): _base_building_id = str(choices.get_item_metadata(index)); _refresh_base_panel())
	var facts := _panel_label("", Vector2(0, 66), 22)
	facts.name = "BaseUpgradeFacts"
	facts.size = Vector2(760, 38)
	var unlocks := _panel_label("", Vector2(0, 114), 18)
	unlocks.name = "BaseUnlockFacts"
	unlocks.size = Vector2(760, 92)
	var progress := ProgressBar.new()
	progress.name = "BaseUpgradeProgress"
	progress.position = Vector2(0, 215)
	progress.size = Vector2(760, 32)
	_panel_content.add_child(progress)
	_cost_view("BaseUpgradeCostIcons", Vector2(0, 260), Vector2(330, 44), {})
	var upgrade := _button("", "UpgradeBaseButton", Vector2(270, 66))
	upgrade.position = Vector2(0, 318)
	upgrade.pressed.connect(_upgrade_base)
	_panel_content.add_child(upgrade)
	var recruit := _button("建筑空位 →" if OutpostSlotUI.enabled(_snapshot) else "招募工人 →", "BaseRecruitEntry", Vector2(200, 66))
	recruit.position = Vector2(300, 318)
	if OutpostSlotUI.enabled(_snapshot): recruit.pressed.connect(_open_panel.bind("build"))
	else: recruit.pressed.connect(func(): _recruit_building_id = _base_building_id; _recruit_unit_type = "worker"; _open_panel("recruit"))
	_panel_content.add_child(recruit)
	var tech := _button("科技树 →", "BaseTechnologyEntry", Vector2(200, 66))
	tech.position = Vector2(530, 318)
	tech.pressed.connect(_open_panel.bind("tech"))
	_panel_content.add_child(tech)
	_refresh_base_panel()

func _refresh_base_panel() -> void:
	var button := _panel_content.find_child("UpgradeBaseButton", true, false) as Button
	if button == null: return
	var choices := _panel_content.find_child("BaseUpgradeOption", true, false) as OptionButton
	var bases: Array[Dictionary] = []
	var signature := ""
	for base: Dictionary in _snapshot.get("buildings", []):
		if base.get("side") == _view_side() and base.get("building_type") == "BASE" and int(base.get("hp", 0)) > 0 and base.get("complete", false):
			bases.append(base)
			signature += "%s:%d;" % [str(base.id), int(base.get("base_tier", 1))]
	if signature != _base_option_signature:
		_base_option_signature = signature
		choices.get_popup().hide()
		choices.clear()
		for base: Dictionary in bases: _add_option(choices, "%d级营所 · %s" % [int(base.get("base_tier", 1)), str(base.id)], str(base.id))
		_base_building_id = _choose_option(choices, _base_building_id)
	choices.disabled = bases.is_empty()
	var building := _building(_base_building_id)
	var tier := int(building.get("base_tier", 1))
	var upgrading: Dictionary = building.get("base_upgrade", {})
	var recipe: Dictionary = {}
	for entry: Dictionary in _progression().get("next_upgrades", []):
		if str(entry.get("building_id")) == _base_building_id: recipe = entry; break
	button.disabled = not recipe.get("available", false)
	button.text = "基地已满级" if tier >= 3 else "升级进行中" if not upgrading.is_empty() else "升级到%d级 · %.0f秒" % [tier + 1, float(recipe.get("duration_ticks", 0)) * 0.05]
	if bases.is_empty(): button.text = "没有可升级营所"
	button.tooltip_text = "本营所升级期间暂停出兵，其他建筑正常生产；不提升人口/体积/生命，不治疗。摧毁丢失升级投资。" + ("\n" + {"INSUFFICIENT_STOCK":"资源不足", "BASE_ALREADY_UPGRADING":"本基地升级进行中"}.get(str(recipe.get("reason", "")), "") if button.disabled else "")
	var facts := _panel_content.find_child("BaseUpgradeFacts", true, false) as Label
	facts.text = "%d级营所 · 全军最高%d级 · 英雄名册%d/3" % [tier, _base_tier(), int(_progression().get("hero_slots_used", 0))]
	facts.tooltip_text = "英雄名册包含存活、倒下和预留的首次招募订单，整局最多三种；死亡不腾出名额。基地等级只限制新招募第几位英雄，已拥有英雄复活不重新要求该等级。"
	facts.set_meta("base_tier", tier)
	var unlocks := _panel_content.find_child("BaseUnlockFacts", true, false) as Label
	var unlock_facts := _base_unlock_facts()
	unlocks.text = unlock_facts.caption
	unlocks.tooltip_text = unlock_facts.tooltip
	unlocks.set_meta("faction_id", _faction_id())
	unlocks.set_meta("unit_unlocks", unlock_facts.units.duplicate(true))
	var progress := _panel_content.find_child("BaseUpgradeProgress", true, false) as ProgressBar
	progress.max_value = maxi(int(upgrading.get("max_progress", 1)), 1)
	progress.value = int(upgrading.get("progress", 0))
	progress.visible = not upgrading.is_empty()
	progress.tooltip_text = "升级%d/%d步 · 本基地生产暂停" % [int(upgrading.get("progress", 0)), int(upgrading.get("max_progress", 1))]
	var cost := _panel_content.find_child("BaseUpgradeCostIcons", true, false) as Control
	cost.set_meta("cost", upgrading.get("cost", recipe.get("cost", {})).duplicate(true))
	cost.visible = tier < 3 or not upgrading.is_empty()
	_refresh_cost_readouts()
	var recruit := _panel_content.find_child("BaseRecruitEntry", true, false) as Button
	recruit.disabled = building.is_empty() or int(building.get("hp", 0)) <= 0

func _base_unlock_facts() -> Dictionary:
	# Recipes and their producer buildings jointly determine the actual gate;
	# selecting a different faction must never inherit human unit promises.
	var catalog: Dictionary = _snapshot.get("catalog", {})
	var building_tiers: Dictionary = catalog.get("progression", {}).get("building_tiers", {})
	var groups := {1:[], 2:[], 3:[]}
	var published: Array[Dictionary] = []
	var details: Array[String] = ["解锁等级取己方最高级的完工基地；招募需对应出兵建筑。第二、第三英雄分别需要二级、三级基地，在祭庭付费招募。整局最多3种英雄，阵亡后可在幸存祭庭复活。"]
	for type: String in _unit_types():
		if type == "hero": continue
		var recipe: Dictionary = catalog.get("units", {}).get(type, {})
		var producer := str(recipe.get("building_type", ""))
		var recipe_tier := int(recipe.get("required_base_tier", 1))
		var producer_tier := int(building_tiers.get(producer, 1))
		var required := maxi(recipe_tier, producer_tier)
		var label := _unit_name(type)
		if groups.has(required): groups[required].append(label)
		published.append({"unit_type":type, "label":label, "producer":producer, "required_base_tier":recipe_tier, "producer_base_tier":producer_tier, "effective_base_tier":required})
		var producer_label := str(catalog.get("buildings", {}).get(producer, {}).get("label", BUILDING_NAMES.get(producer, producer)))
		details.append("%s：%d级解锁；%s（建筑需%d级，兵种需%d级）。" % [label, required, producer_label, producer_tier, recipe_tier])
	var rows: Array[String] = []
	for tier: int in range(1, 4):
		var parts: Array[String] = []
		if not groups[tier].is_empty(): parts.append("·".join(groups[tier]))
		parts.append("英雄%d位" % tier)
		var buildings: Array[String] = []
		for type: String in BUILDINGS:
			if tier > 1 and int(building_tiers.get(type, 1)) == tier: buildings.append(_building_display_name(type))
		if not buildings.is_empty(): parts.append("·".join(buildings))
		if tier == 2: parts.append("科技1/2阶")
		elif tier == 3: parts.append("科技3阶")
		rows.append("%d级：%s" % [tier, " / ".join(parts)])
	details.append("科技仍需完工兵工坊和前一阶；已完成科技不会随基地损失倒退。")
	return {"caption":"\n".join(rows), "tooltip":"\n".join(details), "units":published}

func _upgrade_base() -> void:
	if not _can_command(): return
	_submit({"type":"UPGRADE_BASE", "building_id":_base_building_id})

func _tower_panel() -> void:
	_panel_title.text = "防御建筑 · 火力与升级"
	var title := _panel_label("", Vector2(0, 6), 26)
	title.name = "TowerDefenseTitle"
	_fact_view("TowerDefenseFacts",Vector2(0,60),Vector2(752,65))
	var detail := _panel_label("",Vector2(0,143),19)
	detail.name = "TowerDefenseDetails"
	detail.size = Vector2(752,102)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var progress := ProgressBar.new()
	progress.name = "TowerUpgradeProgress"
	progress.position = Vector2(0,250)
	progress.size = Vector2(752,28)
	_panel_content.add_child(progress)
	_cost_view("TowerUpgradeCostIcons",Vector2(0,290),Vector2(410,40),_tower_upgrade_quote(_building(_selected_building_id)).cost)
	var upgrade := _button("强化箭塔 → 2级", "UpgradeTowerButton", Vector2(350,64))
	upgrade.position = Vector2(0,345)
	upgrade.pressed.connect(_upgrade_tower)
	_panel_content.add_child(upgrade)
	_refresh_tower_panel()

func _refresh_tower_panel() -> void:
	var button := _panel_content.find_child("UpgradeTowerButton",true,false) as Button
	if button == null: return
	var building := _building(_selected_building_id)
	var type := str(building.get("building_type",""))
	var level := int(building.get("tower_level",1))
	var upgrade: Dictionary = building.get("tower_upgrade",{})
	var quote: Dictionary=_tower_upgrade_quote(building)
	var seconds:=float(quote.duration_ticks)/20.0
	var automatic := type == "SITE_TOWER"
	var active := bool(building.get("defense_active",true))
	var title := _panel_content.find_child("TowerDefenseTitle",true,false) as Label
	title.text = "%s · %d级 · %s" % [building.get("label",BUILDING_NAMES.get(type,"防御建筑")),level,"已激活" if active else "休眠 / 尚未完全占领"]
	var facts := _panel_content.find_child("TowerDefenseFacts",true,false) as Control
	facts.refresh(_attribute_facts(building,true,true))
	var detail := _panel_content.find_child("TowerDefenseDetails",true,false) as Label
	detail.text = "%s · 主伤害%d · 射程%d · 间隔%.2f秒。\n" % [DamageRules.attack_label(str(building.get("attack_type","PIERCE"))),int(building.get("damage",0)),int(building.get("attack_range",0)),float(building.get("attack_cooldown_ticks",1))/20.0]
	if int(building.get("splash_max_targets",0))>0:detail.text+="命中处%d范围，至多%d名地面敌人各受%d溅射；不重复命中主目标、不伤友军。\n"%[building.splash_radius,building.splash_max_targets,building.splash_damage]
	detail.text += ("据点完全占领且守塔完工后激活；己方占领点数清零前仍会防守，清零后休眠，夺占过程中不开火。" if automatic else "需要二级基地才能强化，耗时%.1f秒。升级不恢复生命。"%seconds)
	button.disabled = not _can_command() or building.get("side")!=_view_side() or automatic or building.is_empty() or level >= 2 or not upgrade.is_empty() or not building.get("complete",false) or int(building.get("hp",0)) <= 0 or _base_tier() < 2
	var stock: Dictionary = _snapshot.get("economy",{}).get(_view_side(),{}).get("stock",{})
	for resource: String in quote.cost:
		if int(stock.get(resource,0)) < int(quote.cost[resource]): button.disabled = true
	button.text = "据点守塔无需单独升级" if automatic else "已强化至2级" if level >= 2 else "升级中" if not upgrade.is_empty() else "需要2级基地" if _base_tier() < 2 else "强化防御塔 → 2级 · %.1f秒"%seconds
	button.tooltip_text = "支付费用强化防御塔；升级不恢复生命。\n" + _help_cost(quote.cost)
	var bar := _panel_content.find_child("TowerUpgradeProgress",true,false) as ProgressBar
	bar.visible = not upgrade.is_empty()
	bar.max_value = maxi(int(upgrade.get("duration_ticks",1)),1)
	bar.value = int(upgrade.get("progress",0))
	var cost := _panel_content.find_child("TowerUpgradeCostIcons",true,false) as Control
	cost.visible = not automatic and level < 2
	cost.set_meta("cost",quote.cost.duplicate(true))
	_refresh_cost_readouts()

func _upgrade_tower() -> void:
	if not _can_command(): return
	_submit({"type":"UPGRADE_TOWER","building_id":_selected_building_id})

func _build_panel() -> void:
	if OutpostSlotUI.enabled(_snapshot):
		_outpost_build_panel()
		return
	_build_catalog = CatalogGridClass.new()
	_build_catalog.name = "BuildCatalog"
	_build_catalog.size = Vector2(780, 266)
	_panel_content.add_child(_build_catalog)
	_build_catalog.configure(_build_display_items(), [{"id":"ALL", "label":"全部"}, {"id":"ECONOMY", "label":"经济"}, {"id":"PRODUCTION", "label":"生产"}, {"id":"DEFENCE", "label":"防御"}, {"id":"SPECIAL", "label":"特殊"}], "PlaceType_")
	_build_catalog.item_chosen.connect(_arm_build)
	var hint := _panel_label("选型 → 单击落点 → 建筑工自动施工", Vector2(0, 272), 18)
	hint.name = "BuildSelectionFacts"
	hint.size = Vector2(770, 32)
	hint.tooltip_text = "经营中分派建筑工；只有占领村庄/根据地增加人口，建房不加人口。"
	var facts := _panel_label("施工队列", Vector2(0, 306), 17)
	facts.name = "ConstructionQueueFacts"
	_queue_view("ConstructionQueueIcons", Vector2(0, 334), Vector2(462, 80))
	for entry: Array in [[false, "取消队首", "CancelConstructionHeadButton", 480], [true, "取消队末", "CancelConstructionTailButton", 625]]:
		var cancel := _button(str(entry[1]), str(entry[2]), Vector2(130, 60))
		cancel.position = Vector2(int(entry[3]), 340)
		cancel.pressed.connect(_cancel_construction.bind(bool(entry[0])))
		_panel_content.add_child(cancel)
	_refresh_construction_queue()
	_refresh_build_unlocks()

func _refresh_build_unlocks() -> void:
	if OutpostSlotUI.enabled(_snapshot):
		_refresh_outpost_build_slots()
		return
	if _build_catalog != null: _build_catalog.refresh_items(_build_display_items())

func _build_display_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var requirements: Dictionary = _snapshot.get("catalog", {}).get("progression", {}).get("building_tiers", {})
	for type: String in BUILDINGS:
		var recipe: Dictionary = _building_recipes().get(type, {})
		var required := int(requirements.get(type, 1))
		var category := "ECONOMY" if type in ["BASE","ESSENCE_MINE"] else "DEFENCE" if type == "TOWER" else "SPECIAL" if type in ["FOUNDRY", "ALTAR"] else "PRODUCTION"
		items.append({"id":type, "label":str(recipe.get("label",BUILDING_NAMES.get(type, type))), "kind":"BUILDING", "category":category, "visual":{"building_type":type, "side":_view_side(), "faction_id":_faction_id(), "complete":true}, "role":{"ECONOMY":"资源经营", "DEFENCE":"自动防御", "SPECIAL":"科技 / 长官", "PRODUCTION":"单位生产"}[category], "cost":recipe.get("cost", {}), "population":-1, "required_tier":required, "locked_reason":"需%d级基地" % required if _base_tier() < required else "", "stock":_snapshot.get("economy", {}).get(_view_side(), {}).get("stock", {})})
	return items

func _arm_build(building_type: String) -> void:
	if not _can_command(): return
	if OutpostSlotUI.enabled(_snapshot):
		for slot: Dictionary in _snapshot.get("building_slots", []):
			if building_type not in slot.get("allowed_building_types",[slot.get("building_type","")]) or str(slot.get("side", "")) != _view_side() or bool(slot.get("occupied", false)): continue
			_camera.center_on(Vector2(slot.get("position", Vector2.ZERO)))
			_open_building_slot(str(slot.get("id", "")))
			_selected_slot_building_type=building_type
			_refresh_slot_build_panel()
			return
		_set_feedback("没有可用的%s固定空位；先占领相应据点。" % OutpostSlotUI.LABELS.get(building_type, building_type), 6)
		return
	if _build_catalog != null: _build_catalog.select_item(building_type)
	var required := int(_snapshot.get("catalog", {}).get("progression", {}).get("building_tiers", {}).get(building_type, 1))
	if _base_tier() < required:
		var hint := _panel_content.find_child("BuildSelectionFacts", true, false) as Label
		if hint != null: hint.text = "%s · 需%d级基地，单击己方基地升级" % [BUILDING_NAMES[building_type], required]
		_set_feedback("需%d级基地才能规划%s。单击己方基地升级。" % [required, BUILDING_NAMES[building_type]], 6)
		return
	_close_panel()
	_clear_direct_input()
	_target_mode = "BUILD"
	_blueprint_type = building_type
	_audio.record_ui("UI_OPEN", "BUILD:" + building_type)
	_set_feedback("%s：单击合法地面落点。\n小地图只定位，单击取消返回。" % BUILDING_NAMES[building_type], 30)
	_refresh_canvas()

func _outpost_site(slot: Dictionary) -> Dictionary:
	for site: Dictionary in _snapshot.get("sites", []):
		if str(site.get("id", "")) == str(slot.get("site_id", "")): return site
	return {}

func _outpost_economy_panel() -> void:
	var hint := _panel_label("占领 → 基地 / 矿场完工 → 自动收入", Vector2(0, 0), 23)
	hint.tooltip_text = "完整占领并建成基地或采矿场后自动采金；失去完整控制、建筑被毁或矿脉耗尽时停产。"
	var description := RichTextLabel.new()
	description.name = "OutpostEconomyDetails"
	description.position = Vector2(0, 52)
	description.size = Vector2(770, 286)
	description.add_theme_font_override("normal_font", ReadableFont.readable())
	description.add_theme_font_size_override("normal_font_size", 20)
	description.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_content.add_child(description)
	var building_entry := _button("查看建筑空位", "OutpostEconomyBuildEntry", Vector2(330, 64))
	building_entry.position = Vector2(0, 348)
	building_entry.pressed.connect(_open_panel.bind("build"))
	_panel_content.add_child(building_entry)
	_refresh_outpost_economy()

func _refresh_outpost_economy() -> void:
	var description := _panel_content.find_child("OutpostEconomyDetails", true, false) as RichTextLabel
	if description == null: return
	var lines: Array[String] = ["无需分派农民，也无需每次领取资源。完全占领后仍需建成指定经济建筑。", ""]
	for site: Dictionary in _snapshot.get("sites", []):
		if str(site.get("owner", "")) != _view_side(): continue
		var kind := str(site.get("kind", ""))
		var title := str(site.get("label", site.get("id", "据点")))
		if kind == "VILLAGE":
			lines.append("%s · 人口据点 · 人口+%d · 不生产资源" % [title, int(site.get("capacity", 10))])
			continue
		lines.append("%s · %s" % [title, "纯资源点（不加人口）" if kind == "SATELLITE" else "资源根据地"])
		var found := false
		for source: Dictionary in _snapshot.get("resource_sources", []):
			if str(source.get("site_id", "")) != str(site.get("id", "")): continue
			found = true
			var resource := str(source.get("resource", source.get("kind", "MATERIAL")))
			var active := bool(source.get("active", false))
			var remaining := int(source.get("remaining_amount", source.get("remaining", 0)))
			var rate := float(source.get("income_per_second", source.get("passive_rate_per_second", -1)))
			var rate_caption := " · +%.2f/秒" % rate if active and rate >= 0 else ""
			lines.append("  %s · 余%d · %s%s" % [EconomyCatalog.RESOURCE_LABELS.get(resource, resource), remaining, "自动产出" if active else "未启用：占领且经济建筑完工后产出", rate_caption])
		if not found: lines.append("  未公开可用资源；检查该点基地 / 采矿场与占领状态。")
		lines.append("")
	if lines.size() <= 2: lines.append("尚未占领领地；先击败守军并进入占领圈。")
	description.text = "\n".join(lines)

func _outpost_build_panel() -> void:
	var hint := _panel_label("点地图空位 → 查看费用 → 确认自动施工", Vector2(0, 0), 21)
	hint.tooltip_text = "地图上预留的像素基座就是合法建造位置；不会进入自由选址，不需要建筑工。下方只列己方固定空位。"
	var scroll := ScrollContainer.new()
	scroll.name = "OutpostBuildSlotScroll"
	scroll.position = Vector2(0, 42)
	scroll.size = Vector2(770, 240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel_content.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.name = "OutpostBuildSlotRows"
	rows.custom_minimum_size = Vector2(742, 0)
	rows.add_theme_constant_override("separation", 6)
	scroll.add_child(rows)
	for slot: Dictionary in _snapshot.get("building_slots", []):
		if str(slot.get("side", "")) != _view_side(): continue
		var button := _button("", "OutpostSlot_" + str(slot.get("id", "")), Vector2(736, 54))
		button.set_meta("building_slot_id", str(slot.get("id", "")))
		button.pressed.connect(_locate_building_slot.bind(str(slot.get("id", ""))))
		rows.add_child(button)
	if rows.get_child_count() == 0:
		var empty := _label("尚无己方空位：先占领资源点或人口据点。", 20)
		rows.add_child(empty)
	var facts := _panel_label("自动施工队列", Vector2(0, 293), 17)
	facts.name = "ConstructionQueueFacts"
	_queue_view("ConstructionQueueIcons", Vector2(0, 322), Vector2(462, 80))
	for entry: Array in [[false, "取消队首", "CancelConstructionHeadButton", 480], [true, "取消队末", "CancelConstructionTailButton", 625]]:
		var cancel := _button(str(entry[1]), str(entry[2]), Vector2(130, 60))
		cancel.position = Vector2(int(entry[3]), 330)
		cancel.pressed.connect(_cancel_construction.bind(bool(entry[0])))
		_panel_content.add_child(cancel)
	_refresh_outpost_build_slots()
	_refresh_construction_queue()

func _refresh_outpost_build_slots() -> void:
	var rows := _panel_content.find_child("OutpostBuildSlotRows", true, false)
	if rows == null: return
	var owned_ids: Array[String] = []
	var shown_ids: Array[String] = []
	for slot: Dictionary in _snapshot.get("building_slots", []):
		if str(slot.get("side", "")) == _view_side(): owned_ids.append(str(slot.get("id", "")))
	for child: Node in rows.get_children():
		if child.has_meta("building_slot_id"): shown_ids.append(str(child.get_meta("building_slot_id")))
	if owned_ids != shown_ids:
		for child: Node in rows.get_children():
			rows.remove_child(child)
			child.queue_free()
		for slot_id: String in owned_ids:
			var button := _button("", "OutpostSlot_" + slot_id, Vector2(736, 54))
			button.set_meta("building_slot_id", slot_id)
			button.pressed.connect(_locate_building_slot.bind(slot_id))
			rows.add_child(button)
		if owned_ids.is_empty(): rows.add_child(_label("尚无己方空位：先占领资源点或人口据点。", 20))
	for child: Node in rows.get_children():
		if not child is Button or not child.has_meta("building_slot_id"): continue
		var row_button := child as Button
		var slot := OutpostSlotUI.find(_snapshot, str(child.get_meta("building_slot_id")))
		var site := _outpost_site(slot)
		var occupied := bool(slot.get("occupied", false))
		var reason := OutpostSlotUI.reason(slot, _view_side(), _observing())
		row_button.text = "%s · %s · %s" % [str(site.get("label", slot.get("site_id", "据点"))), OutpostSlotUI.label(slot), "已建 / 施工中" if occupied else "可建造 →" if reason.is_empty() else reason]
		row_button.disabled = slot.is_empty() or occupied
		row_button.tooltip_text = OutpostSlotUI.limits(str(site.get("kind", "RESOURCE"))) + "\n单击定位此空位并查看准确费用；确认前不扣费。"

func _locate_building_slot(slot_id: String) -> void:
	var slot := OutpostSlotUI.find(_snapshot, slot_id)
	if slot.is_empty(): return
	_camera.center_on(Vector2(slot.get("position", Vector2.ZERO)))
	_close_panel()
	_open_building_slot(slot_id)

func _open_building_slot(slot_id: String) -> void:
	_selected_building_slot_id = slot_id
	_selected_slot_building_type = str(OutpostSlotUI.find(_snapshot,slot_id).get("building_type",""))
	_open_panel("slot_build")

func _slot_build_panel() -> void:
	var title := _panel_label("", Vector2(8, 4), 28)
	title.name = "OutpostSlotTitle"
	title.size = Vector2(752, 40)
	var description := _panel_label("", Vector2(8, 58), 21)
	description.name = "OutpostSlotDescription"
	description.size = Vector2(752, 128)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var preview := _icon("BASE", "建筑空位", "OutpostSlotPreview")
	preview.position = Vector2(16,244)
	preview.size = Vector2(96,84)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_content.add_child(preview)
	_cost_view("OutpostSlotCost", Vector2(162,244), Vector2(560,40), {})
	var status := _panel_label("", Vector2(162,286), 20)
	status.name = "OutpostSlotStatus"
	status.size = Vector2(560, 56)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var confirm := _button("确认建造", "OutpostSlotConfirm", Vector2(360, 66))
	confirm.position = Vector2(8, 348)
	confirm.pressed.connect(_confirm_building_slot)
	_panel_content.add_child(confirm)
	var cancel := _button("返回地图", "OutpostSlotCancel", Vector2(320, 66))
	cancel.position = Vector2(402, 348)
	cancel.pressed.connect(_close_panel)
	_panel_content.add_child(cancel)
	var choices:=HBoxContainer.new()
	choices.name="OutpostSlotChoices"
	choices.position=Vector2(8,190)
	choices.add_theme_constant_override("separation",18)
	var selected:=OutpostSlotUI.find(_snapshot,_selected_building_slot_id)
	for kind: String in selected.get("allowed_building_types",[selected.get("building_type","")]):
		var option:=_button("选择物理营" if kind=="BARRACKS" else "选择魔法营","SlotChoice"+kind,Vector2(280,48))
		option.pressed.connect(func()->void:_selected_slot_building_type=kind;_refresh_slot_build_panel())
		choices.add_child(option)
	choices.visible=choices.get_child_count()>1
	_panel_content.add_child(choices)
	_refresh_slot_build_panel()

func _refresh_slot_build_panel() -> void:
	var confirm := _panel_content.find_child("OutpostSlotConfirm", true, false) as Button
	if confirm == null: return
	var slot := OutpostSlotUI.find(_snapshot, _selected_building_slot_id)
	var site := _outpost_site(slot)
	var type := _selected_slot_building_type
	if type not in slot.get("allowed_building_types",[slot.get("building_type","")]):type=str(slot.get("building_type",""))
	var recipe: Dictionary = _building_recipes().get(type, {})
	var reason := OutpostSlotUI.reason(slot, _view_side(), _observing() or not _can_command())
	var title := _panel_content.find_child("OutpostSlotTitle", true, false) as Label
	title.text = "%s · %s" % [recipe.get("label",OutpostSlotUI.LABELS.get(type,type)), str(site.get("label", slot.get("site_id", "空位")))]
	var description := _panel_content.find_child("OutpostSlotDescription", true, false) as Label
	description.text = OutpostSlotUI.limits(str(site.get("kind", "RESOURCE"))) + "\n确认后支付费用并自动施工，无需工人。未完工时取消，返还建造费用。"
	var preview := _panel_content.find_child("OutpostSlotPreview", true, false)
	preview.symbol = "MAGIC_CAMP_"+_faction_id() if type=="RANGE" else type
	preview.caption = recipe.get("label",OutpostSlotUI.LABELS.get(type,type))
	preview.queue_redraw()
	var cost := _panel_content.find_child("OutpostSlotCost", true, false) as Control
	cost.set_meta("cost", recipe.get("cost", {}).duplicate(true))
	var status := _panel_content.find_child("OutpostSlotStatus", true, false) as Label
	status.text = reason if not reason.is_empty() else "可以建造 · 自动施工 · 无需建筑工"
	if slot.has("duration_ticks"): status.text += " · %.1f秒" % (float(slot.duration_ticks) * float(_snapshot.get("tick_ms", 50)) / 1000.0)
	confirm.disabled = not reason.is_empty() or recipe.is_empty()
	confirm.text = "确认建造" if reason.is_empty() else "当前不可建造"
	confirm.tooltip_text = _help_cost(recipe.get("cost", {})) + "\n确认后支付金币。需要完整占领据点，并满足基地等级与建筑要求。"
	_refresh_cost_readouts()

func _confirm_building_slot() -> void:
	if not _can_command(): return
	var slot := OutpostSlotUI.find(_snapshot, _selected_building_slot_id)
	var reason := OutpostSlotUI.reason(slot, _view_side())
	if not reason.is_empty():
		_set_feedback(reason, 5)
		_refresh_slot_build_panel()
		return
	# Identity is looked up again now: neither a stale card nor a UI-authored
	# cost/position can turn into a second economic authority.
	var command := {"type":"PLACE_BUILDING", "building_type":_selected_slot_building_type, "position":Vector2i(slot.get("position", Vector2.ZERO))}
	var result := _submit(command)
	if bool(result.get("accepted", false)): _close_panel()

func _army_panel() -> void:
	var create := _button("新增部队 +", "CreateArmyButton", Vector2(170, 48))
	create.position = Vector2(0, 0)
	create.pressed.connect(_create_army)
	_panel_content.add_child(create)
	var swap := _button("⇄ 交换方向", "SwapArmiesButton", Vector2(180, 48))
	swap.position = Vector2(192, 0)
	swap.pressed.connect(_swap_transfer_armies)
	_panel_content.add_child(swap)
	var more := _button("编制操作", "ArmyMoreButton", Vector2(180, 48))
	more.position = Vector2(577, 0)
	more.pressed.connect(_open_panel.bind("army_more"))
	_panel_content.add_child(more)
	_panel_label("来源 ↓", Vector2(0, 53), 16)
	_panel_label("接收 ↓", Vector2(397, 53), 16)
	_fact_view("SourceRosterFacts", Vector2(0, 128), Vector2(360, 32)).mode = "roster"
	_fact_view("TargetRosterFacts", Vector2(397, 128), Vector2(360, 32)).mode = "roster"
	var sources := _option("SourceArmyOption", Vector2(0, 76), Vector2(360, 48))
	var targets := _option("TargetArmyOption", Vector2(397, 76), Vector2(360, 48))
	for army: Dictionary in _friendly_armies(true):
		var text := "预备池" if army.get("reserve", false) else "部队 %02d · %d名" % [int(army.get("number", 0)), int(army.get("living_count", 0))]
		_add_option(sources, text, str(army["id"]))
		_add_option(targets, text, str(army["id"]))
	var active_armies := _friendly_armies()
	if _source_army_id.is_empty(): _source_army_id = _selected_warband_id if not _selected_warband_id.is_empty() else str(active_armies[0].id) if not active_armies.is_empty() else str(sources.get_item_metadata(0)) if sources.item_count else ""
	if _transfer_army_id.is_empty(): _transfer_army_id = str(active_armies[1].id) if active_armies.size() > 1 else str(targets.get_item_metadata(0)) if targets.item_count else _source_army_id
	_refresh_army_option("SourceArmyOption", _source_army_id)
	_refresh_army_option("TargetArmyOption", _transfer_army_id)
	sources.item_selected.connect(func(value: int): _source_army_id = str(sources.get_item_metadata(value)); _refresh_transfer_controls())
	targets.item_selected.connect(func(value: int): _transfer_army_id = str(targets.get_item_metadata(value)); _refresh_transfer_controls())
	_transfer_rows = TransferRowsClass.new()
	_transfer_rows.heroic_2d = heroic_2d_enabled
	_transfer_rows.name = "TransferRosterRows"
	_transfer_rows.position = Vector2(0, 166)
	_transfer_rows.size = Vector2(770, 172)
	_panel_content.add_child(_transfer_rows)
	_transfer_rows.selection_changed.connect(_refresh_transfer_summary)
	var total := _panel_label("", Vector2(0, 358), 20)
	total.name = "TransferSelectionSummary"
	total.size = Vector2(440, 48)
	var transfer := _button("选择人数 →", "TransferUnitsButton", Vector2(310, 60))
	transfer.position = Vector2(447, 342)
	transfer.pressed.connect(_transfer_units)
	_panel_content.add_child(transfer)
	_refresh_transfer_controls()

func _army_more_panel() -> void:
	var route := _panel_label("来源 %s  →  接收 %s" % [_army_label(_source_army_id), _army_label(_transfer_army_id)], Vector2(0, 0), 22)
	route.size = Vector2(770, 48)
	var merge := _button("合并 → 接收部队", "MergeArmiesButton", Vector2(340, 60))
	merge.position = Vector2(0, 92)
	merge.pressed.connect(_merge_armies)
	_panel_content.add_child(merge)
	var erase := _button("删除来源部队", "DeleteArmyButton", Vector2(340, 60))
	erase.position = Vector2(397, 92)
	erase.pressed.connect(_delete_army)
	_panel_content.add_child(erase)
	var conservation := _panel_label("解散部队后，成员进入预备池", Vector2(0, 185), 20)
	conservation.tooltip_text = "调配仅更改成员归属；合并/删除不治疗、不移动。英雄身份、经验、装备和库存保持不变。"
	var back := _button("← 返回调配", "BackToArmyButton", Vector2(300, 64))
	back.position = Vector2(0, 300)
	back.pressed.connect(_open_panel.bind("army"))
	_panel_content.add_child(back)
	_refresh_transfer_controls()

func _army_label(id: String) -> String:
	var army := _army(id)
	return "请选择" if army.is_empty() else "预备池" if army.get("reserve", false) else "部队 %02d" % int(army.get("number", 0))

func _create_army() -> void:
	if not _can_command(): return
	var result := _submit({"type":"CREATE_WARBAND"})
	if result.get("accepted", false):
		var id := str(result.get("warband_id", ""))
		if not id.is_empty(): _select_army(id)
		call_deferred("_populate_panel")

func _swap_transfer_armies() -> void:
	var previous := _source_army_id
	_source_army_id = _transfer_army_id
	_transfer_army_id = previous
	var sources := _panel_content.find_child("SourceArmyOption", true, false) as OptionButton
	var targets := _panel_content.find_child("TargetArmyOption", true, false) as OptionButton
	if sources != null: _choose_option(sources, _source_army_id)
	if targets != null: _choose_option(targets, _transfer_army_id)
	_refresh_transfer_controls()

func _refresh_transfer_controls() -> void:
	_refresh_army_option("SourceArmyOption", _source_army_id)
	_refresh_army_option("TargetArmyOption", _transfer_army_id)
	var valid_route := _can_command() and not _source_army_id.is_empty() and not _transfer_army_id.is_empty() and _source_army_id != _transfer_army_id and not _army(_source_army_id).is_empty() and not _army(_transfer_army_id).is_empty()
	if _transfer_rows != null:
		_transfer_rows.configure_context(_source_army_id + "→" + _transfer_army_id, valid_route)
		var counts := {}
		var samples := {}
		for soldier: Dictionary in _snapshot.get("soldiers", []):
			if soldier.get("side") != _view_side() or not soldier.get("alive", false) or int(soldier.get("hp", 0)) <= 0 or soldier.get("warband_id") != _source_army_id: continue
			var type := str(soldier.get("unit_type", ""))
			counts[type] = int(counts.get(type, 0)) + 1
			samples[type] = soldier
		var rows: Array[Dictionary] = []
		for type: String in _unit_types():
			if int(counts.get(type, 0)) > 0: rows.append({"unit_type":type, "caption":_unit_name(type), "icon":_unit_icon(type), "available":int(counts[type]), "sample":samples[type], "visuals":_roster_visuals(type, _source_army_id)})
		_transfer_rows.refresh(rows)
		_refresh_transfer_summary()
	for entry: Array in [["MergeArmiesButton", not valid_route or bool(_army(_source_army_id).get("reserve", false)) or bool(_army(_transfer_army_id).get("reserve", false))], ["DeleteArmyButton", _army(_source_army_id).is_empty() or bool(_army(_source_army_id).get("reserve", false))]]:
		var button := _panel_content.find_child(str(entry[0]), true, false) as Button
		if button != null: button.disabled = bool(entry[1])
	_refresh_management_facts()

func _refresh_army_option(node_name: String, chosen: String) -> void:
	var option := _panel_content.find_child(node_name, true, false) as OptionButton
	if option == null: return
	var armies := _friendly_armies(true)
	var ids: Array = armies.map(func(army: Dictionary) -> String: return str(army.id))
	# Keep catalog and missing identity distinct: deleting the last army can
	# leave the same flattened IDs but changes its caption into a placeholder.
	var missing_ids: Array = [] if chosen in ids else [chosen]
	if option.get_meta("army_ids", []) == ids and option.get_meta("invalid_army_ids", []) == missing_ids:
		# Identity can stay constant through recruitment, casualties and transfers.
		# Refresh counts in place: rebuilding would close an open choice popup.
		for index: int in range(armies.size()):
			var army: Dictionary = armies[index]
			var caption := "%s · %d名" % [_army_label(str(army.id)), int(army.get("living_count", 0))]
			if option.get_item_text(index) != caption: option.set_item_text(index, caption)
		return
	option.set_meta("army_ids", ids.duplicate())
	option.set_meta("invalid_army_ids", missing_ids)
	option.get_popup().hide()
	option.clear()
	for army: Dictionary in armies: _add_option(option, "%s · %d名" % [_army_label(str(army.id)), int(army.get("living_count", 0))], str(army.id))
	if chosen not in ids: _add_option(option, "部队已失效 · 请重新选择", chosen)
	_choose_option(option, chosen)

func _refresh_transfer_summary() -> void:
	if _transfer_rows == null: return
	var count: int = _transfer_rows.total_selected()
	var label := _panel_content.find_child("TransferSelectionSummary", true, false) as Label
	if label != null: label.text = "已选 %d 名 · 各兵种独立选择" % count
	var button := _panel_content.find_child("TransferUnitsButton", true, false) as Button
	if button != null:
		button.disabled = count <= 0 or _source_army_id == _transfer_army_id or _army(_source_army_id).is_empty() or _army(_transfer_army_id).is_empty()
		button.text = "调入%s · %d名" % [_army_label(_transfer_army_id), count] if count > 0 else "选择人数 →"

func _transfer_units() -> void:
	if not _can_command(): return
	_snapshot = _session.get_snapshot()
	_refresh_transfer_controls()
	if _transfer_rows == null or _source_army_id == _transfer_army_id: return
	var remaining: Dictionary = _transfer_rows.selected_counts()
	var ids: Array[String] = []
	for soldier: Dictionary in _snapshot.get("soldiers", []):
		var type := str(soldier.get("unit_type", ""))
		if soldier.get("side") == _view_side() and soldier.get("alive", false) and int(soldier.get("hp", 0)) > 0 and soldier.get("warband_id") == _source_army_id and int(remaining.get(type, 0)) > 0:
			ids.append(str(soldier["id"])); remaining[type] = int(remaining[type]) - 1
	if ids.is_empty(): _set_feedback("来源没有该兵种。", 4); return
	_submit({"type":"TRANSFER_UNITS", "unit_ids":ids, "target_warband_id":_transfer_army_id})
	_transfer_rows.configure_context("", false)
	call_deferred("_populate_panel")

func _merge_armies() -> void:
	if not _can_command(): return
	var result := _submit({"type":"MERGE_WARBANDS", "source_id":_source_army_id, "target_id":_transfer_army_id})
	if result.get("accepted", false):
		_source_army_id = _transfer_army_id
		_select_army(_transfer_army_id)
	call_deferred("_populate_panel")

func _delete_army() -> void:
	if not _can_command(): return
	var result := _submit({"type":"DELETE_WARBAND", "subject_id":_source_army_id})
	if result.get("accepted", false):
		if _selected_warband_id == _source_army_id: _select_army("")
		_source_army_id = ""
	call_deferred("_populate_panel")

func _technology_panel() -> void:
	var base_entry := _button("", "TechnologyBaseEntry", Vector2(160, 62))
	base_entry.position = Vector2(0, 58)
	base_entry.pressed.connect(_open_panel.bind("base"))
	_panel_content.add_child(base_entry)
	_panel_label("兵工坊 → 攻击 / 护甲；依连线逐级解锁。", Vector2(0, 0), 20)
	var foundries := _option("FoundryOption", Vector2(440, 0), Vector2(318, 48))
	foundries.item_selected.connect(func(value: int): _foundry_building_id = str(foundries.get_item_metadata(value)); _refresh_technology_tree())
	_foundry_signature = "__UNINITIALIZED__"
	var tree := TechTreeClass.new()
	tree.name = "TechnologyDependencyTree"
	tree.size = Vector2(770, 400)
	_panel_content.add_child(tree)
	var prerequisite := _icon("FOUNDRY", "兵工坊", "FoundryPrerequisite")
	prerequisite.position = Vector2(0, 145)
	prerequisite.custom_minimum_size = Vector2(116, 104)
	prerequisite.pressed.connect(_arm_build.bind("FOUNDRY"))
	_panel_content.add_child(prerequisite)
	var prerequisite_label := _panel_label("", Vector2(0, 253), 18)
	prerequisite_label.name = "FoundryPrerequisiteState"
	var foundry_recipe: Dictionary = _snapshot.get("catalog", {}).get("buildings", {}).get("FOUNDRY", {})
	_cost_view("FoundryCostIcons", Vector2(0, 279), Vector2(135, 36), foundry_recipe.get("cost", {}))
	for branch: int in range(2):
		var technology := "ATTACK" if branch == 0 else "ARMOR"
		var technology_recipe: Dictionary = _snapshot.get("catalog", {}).get("technologies", {}).get(technology, {})
		for rank: int in range(1, int(technology_recipe.get("max_level", 3)) + 1):
			var x := 198 + (rank - 1) * 204
			var y := 44 + branch * 112
			var icon := _icon("sword" if technology == "ATTACK" else "armor", "%s %d · +%d" % ["攻击" if branch == 0 else "护甲", rank, int(technology_recipe.get("effect_per_level", 0))], "TechnologyNode_" + technology + "_" + str(rank))
			icon.material_role = "tech"
			icon.custom_minimum_size = Vector2(156, 62)
			icon.position = Vector2(x, y)
			icon.set_meta("technology", technology)
			icon.set_meta("rank", rank)
			icon.pressed.connect(_upgrade_technology.bind(technology, rank))
			_panel_content.add_child(icon)
			var state := _panel_label("", Vector2(x, y + 64), 15)
			state.name = "TechnologyState_" + technology + "_" + str(rank)
			_cost_view("TechnologyCost_" + technology + "_" + str(rank), Vector2(x, y + 84), Vector2(156, 28), _technology_cost(technology, rank))
	var definitions:Array=preload("res://src/simulation/strategic_faction_technologies_v4.gd").list_for(_faction_id())
	for index:int in range(definitions.size()):
		var specialty:Dictionary=definitions[index]
		var id:=str(specialty.id)
		var special_button := _icon("tech", str(specialty.label), "TechnologyNode_"+id+"_1")
		special_button.material_role = "tech"
		special_button.position = Vector2(index*196,318)
		special_button.custom_minimum_size = Vector2(174,62)
		special_button.set_meta("technology",id)
		special_button.set_meta("rank",1)
		special_button.pressed.connect(_upgrade_technology.bind(id,1))
		_panel_content.add_child(special_button)
		_cost_view("TechnologyCost_"+id+"_1",Vector2(index*196,382),Vector2(174,28),specialty.cost)
	_refresh_technology_tree()

func _technology_cost(technology: String, rank: int) -> Dictionary:
	var unique:Dictionary=preload("res://src/simulation/strategic_faction_technologies_v4.gd").lookup(technology,_faction_id())
	if not unique.is_empty():return unique.cost.duplicate(true)
	return preload("res://src/simulation/strategic_economy_catalog.gd").tech_quote(technology,rank).get("cost",{}).duplicate(true)

func _refresh_technology_tree() -> void:
	var foundries := _panel_content.find_child("FoundryOption", true, false) as OptionButton
	if foundries == null: return
	var completed: Array[Dictionary] = []
	var unfinished: Array[Dictionary] = []
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") != _view_side() or building.get("building_type") != "FOUNDRY" or int(building.get("hp", 0)) <= 0: continue
		if building.get("complete", false): completed.append(building)
		else: unfinished.append(building)
	var signature: String = ",".join(completed.map(func(building: Dictionary) -> String: return str(building["id"])))
	if signature != _foundry_signature:
		_foundry_signature = signature
		foundries.get_popup().hide()
		foundries.clear()
		for building: Dictionary in completed: _add_option(foundries, "兵工坊 · " + str(building["id"]), str(building["id"]))
		_foundry_building_id = _choose_option(foundries, _foundry_building_id)
		foundries.disabled = completed.is_empty()
	var state := "BUILT" if not completed.is_empty() else "CONSTRUCTING" if not unfinished.is_empty() else "NOT_BUILT"
	var prerequisite := _panel_content.find_child("FoundryPrerequisite", true, false) as Button
	prerequisite.set_meta("state", state)
	prerequisite.disabled = state != "NOT_BUILT" or _base_tier() < 2
	var prerequisite_label := _panel_content.find_child("FoundryPrerequisiteState", true, false) as Label
	prerequisite_label.text = "需2级基地" if state == "NOT_BUILT" and _base_tier() < 2 else {"NOT_BUILT":"□ 未建", "CONSTRUCTING":"… 施工中", "BUILT":"✓ 已建"}[state]
	var base_entry := _panel_content.find_child("TechnologyBaseEntry", true, false) as Button
	base_entry.text = "%d级基地\n升级 / 解锁 →" % _base_tier()
	prerequisite.tooltip_text = ("单击查看己方资源点的兵工坊固定空位。" if state == "NOT_BUILT" else "兵工坊正在自动施工，无需建筑工。" if state == "CONSTRUCTING" else "己方完工兵工坊已满足科技前置。") if OutpostSlotUI.enabled(_snapshot) else ("单击进入兵工坊蓝图选点。" if state == "NOT_BUILT" else "兵工坊施工中；分派建筑工自动施工。" if state == "CONSTRUCTING" else "己方完工兵工坊已满足科技前置。")
	if state == "CONSTRUCTING": prerequisite_label.tooltip_text = "%d/%d" % [int(unfinished[0].get("progress", 0)), int(unfinished[0].get("max_progress", 100))]
	var tech: Dictionary = _snapshot.get("technology", {}).get(_view_side(), {})
	var stock: Dictionary = _snapshot.get("economy", {}).get(_view_side(), {}).get("stock", {})
	var tree := _panel_content.find_child("TechnologyDependencyTree", true, false) as Control
	var research_queue:Array=_snapshot.get("technology_queues",{}).get(_view_side(),[])
	tree.foundry_state = state
	tree.attack_level = int(tech.get("ATTACK", 0))
	tree.armor_level = int(tech.get("ARMOR", 0))
	tree.faction_technology_levels=[]
	for definition:Dictionary in preload("res://src/simulation/strategic_faction_technologies_v4.gd").list_for(_faction_id()):tree.faction_technology_levels.append(int(tech.get(definition.id,0)))
	tree.queue_redraw()
	for technology: String in ["ATTACK", "ARMOR"]:
		var current := int(tech.get(technology, 0))
		for rank: int in range(1, 4):
			var button := _panel_content.find_child("TechnologyNode_" + technology + "_" + str(rank), true, false) as Button
			if button == null: continue
			var cost := _technology_cost(technology, rank)
			var affordable := int(stock.get("FOOD", 0)) >= int(cost["FOOD"]) and int(stock.get("MATERIAL", 0)) >= int(cost["MATERIAL"])
			var queued:Dictionary={}
			for entry:Dictionary in research_queue:
				if entry.get("technology")==technology and int(entry.get("rank",1))==rank:queued=entry;break
			var status := "UPGRADED" if rank <= current else str(queued.get("state","RUNNING")) if not queued.is_empty() else "RESEARCH_BUSY" if not research_queue.is_empty() else "LOCKED" if state != "BUILT" or rank != current + 1 or _base_tier() < rank else "AVAILABLE" if affordable else "UNAFFORDABLE"
			button.set_meta("state", status)
			button.disabled = status != "AVAILABLE"
			button.modulate = Color("bce0ad") if status == "UPGRADED" else Color("f0d685") if status == "AVAILABLE" else Color.WHITE
			var label := _panel_content.find_child("TechnologyState_" + technology + "_" + str(rank), true, false) as Label
			label.text = str({"UPGRADED":"✓ 已升级", "LOCKED":"× 未解锁", "AVAILABLE":"+ 可研究", "UNAFFORDABLE":"! 资源不足","RUNNING":"… 研究中","BLOCKED_FOUNDRY":"… 暂停","RESEARCH_BUSY":"… 研究忙"}.get(status,status))
			if rank > current and _base_tier() < rank: label.text = "需%d级基地" % rank
			button.tooltip_text = "需要完工兵工坊、%d级基地及前一阶科技。当前基地%d级；已完成科技不会随基地损失倒退。" % [rank, _base_tier()]
			button.tooltip_text+="\n实际研究耗时%.1f秒。"%(float(EconomyCatalog.tech_quote(technology,rank).get("duration_ticks",0))/20.0)
			if not queued.is_empty():button.tooltip_text+="\n已付费 %d/%d；不重复扣款。"%[int(queued.get("progress",0)),int(queued.get("max_progress",0))]
	for profile:Dictionary in preload("res://src/simulation/strategic_faction_technologies_v4.gd").list_for(_faction_id()):
		var special := _panel_content.find_child("TechnologyNode_"+str(profile.id)+"_1",true,false) as Button
		if special==null:continue
		var cost: Dictionary = profile.get("cost", {})
		var queued: Dictionary = {}
		for entry: Dictionary in _snapshot.get("technology_queues", {}).get(_view_side(), []):
			if entry.get("technology") == profile.id: queued = entry; break
		# Paid work has a different blocker from an unpurchased, tier-locked
		# technology. Keep the authoritative queue state instead of a boolean.
		var special_state := "UPGRADED" if int(tech.get(profile.id,0)) > 0 else str(queued.get("state", "RUNNING")) if not queued.is_empty() else "RESEARCH_BUSY" if not research_queue.is_empty() else "LOCKED" if state != "BUILT" or _base_tier() < int(profile.required_base_tier) else "UNAFFORDABLE" if int(stock.get("MATERIAL",0)) < int(cost.get("MATERIAL",0)) else "AVAILABLE"
		special.disabled = special_state != "AVAILABLE"
		special.set_meta("state", special_state)
		special.set_meta("faction_id", _faction_id())
		special.set_meta("profile", profile.duplicate(true))
		special.caption = str(profile.label)+" · "+str({"UPGRADED":"✓","RUNNING":"研究中","BLOCKED_FOUNDRY":"暂停","UNAFFORDABLE":"缺资源","AVAILABLE":"+"}.get(special_state,"T%d"%int(profile.required_base_tier)))
		special.tooltip_text = str(profile.description)+"\n需要%d级基地、完工兵工坊；%d金币，%.1f秒，单阶。"%[int(profile.required_base_tier),int(profile.cost.MATERIAL),float(profile.duration_ticks)/20.0]
		if special_state == "BLOCKED_FOUNDRY":
			special.tooltip_text += "\n研究暂停 %d/%d：需要己方存活且完工的兵工坊；保留进度，完工后自动继续，无需再次付费。" % [int(queued.get("progress", 0)), int(queued.get("max_progress", 0))]
		special.queue_redraw()
	_refresh_cost_readouts()

func _upgrade_technology(technology: String, rank: int) -> void:
	if not _can_command(): return
	var current := int(_snapshot.get("technology", {}).get(_view_side(), {}).get(technology, 0))
	if rank != current + 1 or _foundry_building_id.is_empty(): return
	_submit({"type":"UPGRADE", "technology":technology, "building_id":_foundry_building_id})

func _hero_controls_panel() -> void:
	var progress := _panel_label("", Vector2(0, 0), 21)
	progress.name = "HeroProgressFacts"
	progress.size = Vector2(760, 34)
	for entry: Array in [["HeroAutoAttackToggle", "attack", 0], ["HeroAutoSkillsToggle", "skills", 397]]:
		var toggle := _button("", str(entry[0]), Vector2(360, 58))
		toggle.set("leading_symbol", "AUTO_ATTACK" if str(entry[1]) == "attack" else "AUTO_CAST")
		toggle.position = Vector2(int(entry[2]), 42)
		toggle.pressed.connect(_toggle_hero_automation.bind(str(entry[1])))
		_panel_content.add_child(toggle)
	var learning := _panel_label("普通技能：有点即可升级 · 大招：5/8级 · 每次花1点 · 满级8", Vector2(0, 106), 16)
	learning.tooltip_text = "3技能包含全部被动。出生1点，每次升级再得1点，总计8点正好3+3+2；行军/撤退优先，自动施法每秒最多一次。"
	for slot: int in range(3):
		var row := 141 + slot * 88
		var icon := _icon("hero", "", "HeroSkillRankIcon%d" % slot)
		icon.position = Vector2(0, row)
		icon.custom_minimum_size = Vector2(64, 74)
		icon.pressed.connect(_open_hero_skill_information)
		_panel_content.add_child(icon)
		var facts := _panel_label("", Vector2(78, row + 1), 17)
		facts.name = "HeroSkillRankFacts%d" % slot
		facts.size = Vector2(440, 82)
		facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var info := _button("说明", "HeroSkillRankInfo%d" % slot, Vector2(80, 66))
		info.position = Vector2(528, row + 2)
		info.pressed.connect(_open_hero_skill_information)
		_panel_content.add_child(info)
		var upgrade := _button("升级 +", "HeroSkillUpgrade%d" % slot, Vector2(140, 66))
		upgrade.position = Vector2(618, row + 2)
		upgrade.pressed.connect(_upgrade_hero_skill.bind(slot))
		_panel_content.add_child(upgrade)
	_refresh_hero_controls()

func _open_hero_skill_information() -> void:
	_info_type = "hero"
	_info_archetype = str(_hero(_selected_unit_id).get("hero_archetype", "COMMANDER"))
	_info_unit_id = _selected_unit_id
	_open_panel("info")

func _toggle_hero_automation(kind: String) -> void:
	if not _can_command(): return
	var hero := _hero(_selected_unit_id)
	if hero.is_empty(): return
	_submit({"type":"SET_HERO_AUTOMATION", "unit_id":_selected_unit_id, "auto_attack":not bool(hero.get("auto_attack", true)) if kind == "attack" else bool(hero.get("auto_attack", true)), "auto_skills":not bool(hero.get("auto_skills", false)) if kind == "skills" else bool(hero.get("auto_skills", false))})

func _upgrade_hero_skill(slot: int) -> void:
	if not _can_command(): return
	var skills: Array = _hero(_selected_unit_id).get("skills", [])
	if slot < 0 or slot >= skills.size(): return
	_submit({"type":"UPGRADE_HERO_SKILL", "unit_id":_selected_unit_id, "skill_id":str(skills[slot].get("id", ""))})

func _refresh_hero_controls() -> void:
	var progress := _panel_content.find_child("HeroProgressFacts", true, false) as Label
	if progress == null: return
	var hero := _hero(_selected_unit_id)
	var alive := bool(hero.get("alive", false))
	var command_reason := "观战只读" if _observing() else "战斗已结束" if _snapshot.get("outcome", "ONGOING") != "ONGOING" else "英雄已倒下" if not alive else ""
	progress.text = "%s · Lv%d/8 · 经验%d%s · 技能点%d" % [str(hero.get("name", "未选择英雄")), int(hero.get("level", 1)), int(hero.get("xp", 0)), "/%d" % int(hero.get("next_level_xp", 0)) if int(hero.get("next_level_xp", -1)) >= 0 else " · 满级", int(hero.get("skill_points", 0))]
	progress.tooltip_text = str(hero.get("growth_description", "")) + "\n900范围内的己方存活英雄平分经验；满级英雄仍参与分配，但不再积累经验。"
	progress.set_meta("skill_points", int(hero.get("skill_points", 0)))
	for entry: Array in [["HeroAutoAttackToggle", "auto_attack", "自动攻击", true], ["HeroAutoSkillsToggle", "auto_skills", "自动技能", false]]:
		var toggle := _panel_content.find_child(str(entry[0]), true, false) as Button
		var enabled := bool(hero.get(str(entry[1]), bool(entry[3])))
		toggle.text = ("✓ " if enabled else "○ ") + str(entry[2]) + (" · 已开启" if enabled else " · 已关闭")
		toggle.disabled = not command_reason.is_empty()
		toggle.set_meta("enabled", enabled)
		toggle.tooltip_text = "单击切换；独立开关。手动攻击和技能仍可用；行军、撤退优先，停止后重新开启恢复站定自动战斗。"
		if not command_reason.is_empty(): toggle.tooltip_text = "不可操作：" + command_reason + "\n" + toggle.tooltip_text
	var skills: Array = hero.get("skills", [])
	for slot: int in range(3):
		var skill: Dictionary = skills[slot] if slot < skills.size() else {}
		var icon := _panel_content.find_child("HeroSkillRankIcon%d" % slot, true, false) as Button
		var facts := _panel_content.find_child("HeroSkillRankFacts%d" % slot, true, false) as Label
		var upgrade := _panel_content.find_child("HeroSkillUpgrade%d" % slot, true, false) as Button
		icon.symbol = _hero_skill_symbol(skill)
		icon.caption = ("大招" if skill.get("ultimate", false) else "被动" if skill.get("passive", false) else "技能") + str(skill.get("level", 0))
		icon.tooltip_text = str(skill.get("description", ""))
		icon.queue_redraw()
		facts.text = _hero_skill_summary(skill)
		facts.tooltip_text = str(skill.get("description", ""))
		facts.set_meta("skill", skill.duplicate(true))
		upgrade.disabled = not command_reason.is_empty() or not bool(skill.get("can_upgrade", false))
		upgrade.text = "已满级" if int(skill.get("level", 0)) >= int(skill.get("max_level", 3)) else "需英雄%d级" % int(skill.get("required_hero_level", 1)) if int(hero.get("level", 1)) < int(skill.get("required_hero_level", 1)) else "没有技能点" if int(hero.get("skill_points", 0)) <= 0 else "学习 +1" if int(skill.get("level", 0)) == 0 else "升级 +1"
		upgrade.tooltip_text = "花1技能点；普通技能有点即可升至3阶，大招5/8级各开放一阶。天赋不占这3个技能，不消耗点数。\n" + str(skill.get("description", ""))
		if not command_reason.is_empty():
			upgrade.text = command_reason
			upgrade.tooltip_text = "不可操作：" + command_reason + "\n" + upgrade.tooltip_text

func _hero_skill_symbol(skill: Dictionary) -> String:
	# A UI role (aura/heal/guard) is not an ability identity. Keep the same
	# authored picture in the roster, learning panel and existing skill stick.
	if not str(skill.get("id", "")).is_empty(): return str(skill.id)
	if skill.get("passive", false): return "armor" if skill.get("effect") == "PASSIVE_GUARD" else "army"
	if skill.get("ultimate", false) and skill.get("effect") == "HEAL": return "aura_emblem"
	return str(skill.get("id", "hero"))

func _hero_skill_summary(skill: Dictionary) -> String:
	# Keep each row bounded even for ranked control skills with equipment.
	# Full, authoritative constraints remain accessible by one-tap 说明.
	var effects: Array[String] = []
	# Control must remain visible even when an ability also deals damage or heals.
	if skill.get("effect") in ["ROOT", "STUN"]:
		effects.append(("定身" if skill.effect == "ROOT" else "眩晕") + "%.1f秒" % (float(skill.get("control_duration_ticks", 0)) / 20.0))
	for entry: Array in [["aura_damage","友军攻击+%s"],["aura_armor","友军护甲+%s"],["aura_heal","每秒回复%s"],["aura_speed","友军移速+%s"],["passive_armor","自身护甲+%s"],["damage","伤害%s"],["heal","恢复%s生命"],["damage_percent","普攻+%s%%"],["damage_bonus","普攻+%s"],["armor_bonus","护甲+%s"]]:
		if float(skill.get(entry[0],0)) > 0: effects.append(str(entry[1]) % float(skill[entry[0]]))
	if skill.get("effect") not in ["ROOT", "STUN"] and int(skill.get("duration_ticks", 0)) > 0: effects.append("持续%.1f秒" % (float(skill.duration_ticks) / 20.0))
	# At most two concise effects keep this 440px label to three physical lines.
	# All remaining effects are still shown by the adjacent information button.
	var detail := " · ".join(effects.slice(0, 2))
	if effects.size() > 2: detail += " …"
	var cap := clampi(int(skill.get("max_targets", 1)), 1, 6)
	var delivery := str(skill.get("delivery", "AREA"))
	var geometry := "%s≤%d目标" % [str({"SINGLE":"单体", "CONE":"扇形", "CHAIN":"连锁", "LINE":"贯穿", "AREA":"范围"}.get(delivery, "范围")), cap]
	if skill.get("target_mode") == "SELF" or delivery == "SELF":
		geometry = "自身"
		if skill.has("ally_heal") or skill.has("ally_guard") or skill.get("effect") == "RALLY":
			geometry = "范围≤%d友军" % cap if skill.get("effect") == "RALLY" else "自身+≤%d友军" % cap
	var area := "自身" if skill.get("target_mode") == "SELF" or delivery == "SELF" else "距离%d" % int(skill.get("range", 0))
	var usage := "%s · 蓝%d · 冷却%.1f秒" % [area, int(skill.get("mana_cost", 0)), float(skill.get("max_cooldown_ticks", 0)) / 20.0]
	if skill.get("passive", false):
		usage = "常驻 · 无耗蓝" if skill.get("effect") == "PASSIVE_GUARD" else "范围%d · 最多%d友军 · 常驻" % [int(skill.get("radius", 0)), int(skill.get("max_targets", 6))]
	else:
		detail = geometry + (" · " + detail if not detail.is_empty() else "")
	return "%s · %d/%d级\n%s\n%s" % [str(skill.get("name", "")), int(skill.get("level", 0)), int(skill.get("max_level", 3)), detail, usage]

func _inventory_panel() -> void:
	var view := HeroShopPanel.new()
	view.name = "HeroShopView"
	_panel_content.add_child(view)
	view.purchase_requested.connect(_purchase_item)
	view.sell_requested.connect(_sell_inventory)
	view.use_requested.connect(_use_inventory)
	view.hero_selected.connect(_select_shop_hero)
	view.item_selected.connect(func(id: String): _shop_item_id = id)
	view.category_changed.connect(func(category: String): _shop_category = category)
	view.configure(_snapshot, _selected_unit_id, _shop_category, _shop_item_id, _view_side(), _observing())

func _purchase_item(item: String) -> void:
	if not _can_command(): return
	var scroll := _panel_content.find_child("InventoryItemsScroll", true, false) as ScrollContainer
	var previous_scroll := int(scroll.scroll_vertical) if scroll != null else 0
	var unit_id := _selected_unit_id
	_submit({"type":"BUY_ITEM", "unit_id":_selected_unit_id, "item_id":item, "building_id":_item_service()})
	call_deferred("_rebuild_inventory_at_scroll", previous_scroll, unit_id)

func _rebuild_inventory_at_scroll(previous_scroll: int, unit_id: String) -> void:
	if _panel_kind != "inventory" or not _backdrop.visible or _selected_unit_id != unit_id: return
	_populate_panel()
	var scroll := _panel_content.find_child("InventoryItemsScroll", true, false) as ScrollContainer
	# A fresh ScrollContainer has no settled content bounds until layout runs.
	# Restore only this still-current panel, never a reopened/different hero view.
	await get_tree().process_frame
	if is_instance_valid(scroll) and not scroll.is_queued_for_deletion() and _panel_kind == "inventory" and _backdrop.visible and _selected_unit_id == unit_id:
		scroll.scroll_vertical = previous_scroll

func _item_service() -> String:
	if OutpostSlotUI.enabled(_snapshot):
		return str(OutpostShopReadout.read(_snapshot, _selected_unit_id, _view_side()).get("building_id", ""))
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") == _view_side() and building.get("building_type") == "SHOP": return str(building.id)
	return ""

func _refresh_inventory_buttons() -> void:
	if _panel_kind != "inventory": return
	var view := _panel_content.find_child("HeroShopView", true, false)
	if view != null: view.refresh(_snapshot, _selected_unit_id, _view_side(), _observing())

func _use_inventory(item: String) -> void:
	if not _can_command(): return
	if not HeroItems.ITEMS.has(item): return
	if not HeroItems.ITEMS[item].get("consumable", false):
		_inspect_bag_item(item)
		return
	_submit({"type":"USE_ITEM", "unit_id":_selected_unit_id, "item_id":item})

func _sell_inventory(item: String) -> void:
	if not _can_command(): return
	_submit({"type":"SELL_ITEM", "unit_id":_selected_unit_id, "item_id":item, "building_id":_item_service()})

func _inspect_bag_item(item: String) -> void:
	_shop_item_id = item
	_shop_category = str(HeroItems.ITEMS.get(item, {}).get("tier", "BASIC"))
	_open_panel("inventory")

func _select_shop_hero(unit_id: String) -> void:
	_select_unit(unit_id)
	if _panel_kind == "inventory" and _backdrop.visible: call_deferred("_populate_panel")

func _site_readout() -> Dictionary:
	return CaptureReadoutClass.read_site(_snapshot, _selected_site_id, _selected_unit_id if not _selected_unit_id.is_empty() else _selected_warband_id, "UNIT" if not _selected_unit_id.is_empty() else "ARMY", _view_side())

func _resource_inspection_panel() -> void:
	var description := RichTextLabel.new()
	description.name = "SourceInspectionDetails"
	description.position = Vector2(8,12)
	description.size = Vector2(736,360)
	description.add_theme_font_override("normal_font",ReadableFont.readable())
	description.add_theme_font_size_override("normal_font_size",22)
	description.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_content.add_child(description)
	_refresh_resource_inspection_panel()

func _refresh_resource_inspection_panel() -> void:
	var description := _panel_content.find_child("SourceInspectionDetails",true,false) as RichTextLabel
	if description == null: return
	var source := SourceInspectionM71.read(_snapshot,_selected_source_id,_view_side())
	description.text = str(source.get("description","此资源点已不可查阅。"))
	if OutpostSlotUI.enabled(_snapshot):
		for current: Dictionary in _snapshot.get("resource_sources", []):
			if str(current.get("id", "")) != _selected_source_id: continue
			description.text = _outpost_resource_description(current)
			break

func _outpost_resource_description(source: Dictionary) -> String:
	var site := _outpost_site({"site_id":source.get("site_id", "")})
	var resource := str(source.get("resource", source.get("kind", "MATERIAL")))
	var active := bool(source.get("active", false))
	var text := "%s · %s\n%s\n\n剩余资源：%d\n状态：%s\n\n%s\n\n无需工人；完整占领并建成%s后自动获取。失去据点或建筑被毁后不再产出。" % [str(site.get("label", source.get("site_id", "资源点"))), EconomyCatalog.RESOURCE_LABELS.get(resource, resource), Palette.side_label(str(source.get("owner", "NEUTRAL"))), int(source.get("remaining_amount", source.get("remaining", 0))), "自动产出" if active else "未启用 / 暂停", OutpostSlotUI.limits(str(site.get("kind", "RESOURCE"))), "采矿场" if str(site.get("kind", "")) == "SATELLITE" or resource == "ESSENCE" else "资源基地"]
	var rate := float(source.get("income_per_second", source.get("passive_rate_per_second", -1)))
	if rate >= 0: text += "\n当前自动收入：%.2f / 秒" % rate
	return text

func _select_tapped_source(point: Vector2) -> bool:
	var picked := ""
	var best := INF
	var visual: Array = _canvas.get_resource_readouts() if heroic_2d_enabled and _canvas != null else []
	for source: Dictionary in _snapshot.get("resource_sources",[]):
		if not bool(source.get("visible",true)): continue
		var foot: Vector2 = _camera.world_to_screen(Vector2(source.get("position",Vector2.ZERO)))
		var hit := foot.distance_to(point) <= maxf(float(source.get("radius",40))*_camera.get_scale(),24)
		for body: Dictionary in visual:
			if body.id == source.get("id") and Rect2(body.screen_bounds).has_point(point): hit = true; break
		var distance := foot.distance_squared_to(point)
		if hit and distance < best: picked = str(source.get("id","")); best = distance
	if picked.is_empty(): return false
	_clear_direct_input()
	_selected_source_id = picked
	_selected_unit_id = ""
	_selected_warband_id = ""
	_selected_worker_id = ""
	_selected_building_id = ""
	_selected_site_id = ""
	_audio.record_ui("SELECT",picked)
	_build_context()
	_refresh()
	return true

func _tapped_site(point: Vector2) -> String:
	for source: Dictionary in _snapshot.get("resource_sources", []):
		if source.get("kind") not in ["MATERIAL","ESSENCE"]: continue
		var radius := maxf(float(source.get("radius", 50)) * _camera.get_scale(), 26)
		if _camera.world_to_screen(Vector2(source.position)).distance_to(point) <= radius:
			return str(source.get("site_id", ""))
	for site: Dictionary in _snapshot.get("sites", []):
		if _camera.world_to_screen(Vector2(site.position)).distance_to(point) <= 32:
			return str(site.id)
	return ""

func _site_capture_panel() -> void:
	var points := _panel_label("", Vector2.ZERO, 28)
	points.name = "SiteCapturePoints"
	var owner := _panel_label("", Vector2(435, 7), 21)
	owner.name = "SiteCaptureOwner"
	var bar := ProgressBar.new()
	bar.name = "SiteCaptureProgress"
	bar.position = Vector2(0, 56)
	bar.size = Vector2(752, 30)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("12242a")
	background.border_color = Color("7c938b")
	background.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("61adcc")
	bar.add_theme_stylebox_override("fill", fill)
	_panel_content.add_child(bar)
	var status := _panel_label("", Vector2(0, 102), 23)
	status.name = "SiteCaptureStatus"
	var details := RichTextLabel.new()
	details.name = "SiteCaptureDetails"
	# RichTextLabel's default bundled face is not the Label system fallback;
	# new objective names must use the same complete CJK face as the HUD.
	details.add_theme_font_override("normal_font", ReadableFont.readable())
	details.position = Vector2(0, 147)
	details.size = Vector2(752, 193)
	details.add_theme_font_size_override("normal_font_size", 20)
	details.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_content.add_child(details)
	_fact_view("SiteResourceSourceFacts", Vector2(0, 263), Vector2(752, 77))
	var enter := _button("进入占领圈", "EnterSiteCircleButton", Vector2(310, 62))
	enter.position = Vector2(0, 352)
	enter.pressed.connect(_enter_site_circle)
	_panel_content.add_child(enter)
	var rebuild := _button("重建守塔", "RebuildSiteDefenseButton", Vector2(260,62))
	rebuild.position = Vector2(330,352)
	rebuild.pressed.connect(_rebuild_site_defense)
	_panel_content.add_child(rebuild)
	_cost_view("SiteDefenseRebuildCostIcons",Vector2(600,352),Vector2(152,54),{})
	_refresh_site_capture()

func _refresh_site_capture() -> void:
	if _site_button == null: return
	var readout := _site_readout()
	_site_button.visible = not readout.is_empty() and not _backdrop.visible and _target_mode.is_empty()
	if readout.is_empty(): return
	var objective: Dictionary = readout.get("field_objective", {})
	var label := str(readout.get("label","资源根据地")) if readout.kind in ["RESOURCE", "SATELLITE"] else str(objective.get("label", "野外村庄"))
	_site_button.text = "%s · %d/%d\n%s · 单击详情" % [label, readout.progress, readout.max_progress, str(readout.status_caption).replace("敌军", "对方").replace("敌方", "对方")]
	_site_button.tooltip_text = readout.range_caption
	if _panel_kind != "site": return
	var points := _panel_content.find_child("SiteCapturePoints", true, false) as Label
	if points == null: return
	points.text = readout.progress_caption
	var owner := _panel_content.find_child("SiteCaptureOwner", true, false) as Label
	owner.text = "%s · 人口 +%d" % [readout.owner_caption, readout.capacity]
	var bar := _panel_content.find_child("SiteCaptureProgress", true, false) as ProgressBar
	bar.max_value = readout.max_progress
	bar.value = readout.progress
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = Palette.side_color(str(readout.capture_side))
	var status := _panel_content.find_child("SiteCaptureStatus", true, false) as Label
	status.text = str(readout.status_caption).replace("敌军", "对方").replace("敌方", "对方") + " · " + str(readout.presence_caption).replace("敌", "对手")
	var detail := "%s\n范围 %.0f：只计算存活士兵 / 英雄，工人不能占领。\n" % [readout.range_caption, readout.radius]
	if readout.state == "GUARDED": detail += "该处仍有野怪守军；必须先清营，不能绕过守军直接计时占领。\n"
	if readout.state == "PREPARATION":
		detail += "筹备中：占领尚未开始计时。开始交战后，驻军优势会推进占领。\n"
	elif readout.running:
		detail += "预计此阶段还需 %.1f 秒；人数变化、平局或离圈会改变/暂停计时。\n" % readout.seconds_remaining
	elif readout.state == "CONTESTED": detail += "双方人数相同：占领点不会变化。\n"
	if readout.kind == "RESOURCE":
		detail += "矿洞是采矿位置，不是旗帜中心。占领后还需附近已完工营所，再在经营界面选择采矿地。"
		if readout.get("resource") == "ESSENCE": detail += "\n灵髓：2级基地解锁矿场；占领后建成专用灵髓矿场，在经营中独立选点并派工（每点%d人）。高级合成、药剂和本族顶级灵髓兵消耗此资源。" % EconomyCatalog.ESSENCE_WORKER_CAP
		detail += "\n据点守塔须建好并完成首次占领；旧方点数清零前继续防守，清零后休眠至新方完全占领。"
	elif objective.is_empty(): detail += "村庄提供人口，不持续产资源；不能自行建房增加人口。"
	else:
		detail = "人口 +%d · 占领圈 %.0f：仅存活地面士兵 / 长官计数，工人不能占领。\n" % [readout.capacity, readout.radius]
		detail += str(objective.get("detail_caption", ""))
	if OutpostSlotUI.enabled(_snapshot):
		detail = "%s\n存活地面部队在占领圈内形成数量优势后计时；先清除野怪守军。\n%s\n" % [readout.range_caption, OutpostSlotUI.limits(str(readout.kind))]
		if readout.kind in ["RESOURCE", "SATELLITE"]: detail += "完整占领并建成指定经济建筑后自动产出，失去据点或建筑被毁则停止。"
	var details := _panel_content.find_child("SiteCaptureDetails", true, false) as RichTextLabel
	details.size.y = 107 if readout.kind in ["RESOURCE", "SATELLITE"] else 193
	details.add_theme_font_size_override("normal_font_size", 17 if readout.kind in ["RESOURCE", "SATELLITE"] else 18 if not objective.is_empty() else 20)
	details.text = detail
	details.set_meta("field_objective_readout", objective.duplicate(true))
	var sources := _panel_content.find_child("SiteResourceSourceFacts", true, false) as Control
	sources.visible = readout.kind in ["RESOURCE", "SATELLITE"]
	if sources.visible: _refresh_source_facts(sources, _selected_site_id)
	var enter := _panel_content.find_child("EnterSiteCircleButton", true, false) as Button
	enter.disabled = not _can_command() or int(readout.subject_count) <= 0 or _snapshot.get("outcome", "ONGOING") != "ONGOING"
	enter.tooltip_text = "选择部队或存活士兵/英雄后，发一条正常行军指令到旗帜中心。不会瞬移、修改点数或自动开战。"
	_refresh_site_defense_rebuild(readout)

func _refresh_site_defense_rebuild(readout: Dictionary) -> void:
	var button := _panel_content.find_child("RebuildSiteDefenseButton",true,false) as Button
	if button == null: return
	var tower: Dictionary = {}
	for building: Dictionary in _snapshot.get("buildings",[]):
		if building.get("building_type") == "SITE_TOWER" and building.get("site_id") == readout.get("id"): tower = building; break
	var recipe: Dictionary = EconomyCatalog.SITE_DEFENSE_REBUILD.duplicate(true)
	var reason := ""
	if not _can_command(): reason = "观战只读" if _observing() else "请先开始对局"
	elif _snapshot.get("outcome","ONGOING") != "ONGOING": reason = "战斗已结束"
	elif readout.get("owner") != _view_side() or int(readout.get("progress",0)) < int(readout.get("max_progress",1)): reason = "需要完全占领"
	elif tower.is_empty(): reason = "此据点没有默认守塔"
	elif int(tower.get("hp",0)) > 0: reason = "守塔仍存活" if tower.get("complete",false) else "守塔施工中"
	elif recipe.is_empty(): reason = "重建目录未就绪"
	else:
		var stock: Dictionary = _snapshot.get("economy",{}).get(_view_side(),{}).get("stock",{})
		for resource: String in recipe.get("cost",{}):
			if int(stock.get(resource,0)) < int(recipe.cost[resource]): reason = "%s不足" % EconomyCatalog.RESOURCE_LABELS[resource]; break
	button.disabled = not reason.is_empty()
	button.text = reason if not reason.is_empty() else "重建守塔"
	button.tooltip_text = "默认据点守塔被毁后，完全占领者可正常付费重建。恢复为1生命蓝图，再由真实建筑工完成%d工程并逐步恢复生命；不瞬间满血、不立即开火。\n%s%s" % [int(recipe.get("work",180)),_help_cost(recipe.get("cost",{})),"\n不可用："+reason if not reason.is_empty() else ""]
	if OutpostSlotUI.enabled(_snapshot): button.tooltip_text = "已完全占领的据点可以付费重建守塔；工程自动完成，无需建筑工。\n" + _help_cost(recipe.get("cost", {})) + ("\n不可用：" + reason if not reason.is_empty() else "")
	var cost := _panel_content.find_child("SiteDefenseRebuildCostIcons",true,false) as Control
	cost.set_meta("cost",recipe.get("cost",{}).duplicate(true))
	cost.visible = not recipe.is_empty()
	_refresh_cost_readouts()

func _rebuild_site_defense() -> void:
	if not _can_command(): return
	_submit({"type":"REBUILD_SITE_DEFENSE","site_id":_selected_site_id})

func _enter_site_circle() -> void:
	if not _can_command(): return
	var readout := _site_readout()
	if readout.is_empty() or int(readout.subject_count) <= 0: return
	var command := {"type":"UNIT_MOVE", "unit_id":_selected_unit_id, "target_position":readout.position} if not _selected_unit_id.is_empty() else {"type":"MOVE", "subject_id":_selected_warband_id, "target_position":readout.position}
	_close_panel()
	_submit(command)

func _refresh_readiness() -> void:
	if _battle_start_button == null: return
	_battle_start_button.visible = _can_command() and _snapshot.get("phase") == "PREPARATION" and _snapshot.get("outcome", "ONGOING") == "ONGOING" and not _backdrop.visible
	var start := _panel_content.find_child("StartBattleButton", true, false) as Button
	if start != null:
		start.disabled = not _can_command() or _snapshot.get("phase") != "PREPARATION" or _snapshot.get("outcome", "ONGOING") != "ONGOING"

static func _computer_caption(status: String) -> String:
	return str({"DORMANT":"大厅未启动", "EXPANDING":"拓疆", "DEVELOPING":"发展", "DEFENDING":"防御", "PRESSURING":"单队前压", "ASSAULT":"全军进攻", "REGROUPING":"重整", "RESTING":"休整"}.get(status, "运营"))

func _computer_policy_caption(status: String) -> String:
	return "单团出征" if _ai_difficulty_id() == "EASY" and status == "ASSAULT" else _computer_caption(status)

func _ai_difficulty_id() -> String:
	return str(_snapshot.get("match_settings", {}).get("ai_difficulty", _snapshot.get("computer", {}).get("difficulty_id", "EASY")))

func _ai_difficulty_policy() -> Dictionary:
	var policy: Dictionary = _snapshot.get("computer", {}).get("policy", {})
	return policy if policy.get("id", "") == _ai_difficulty_id() else AIDifficultyClass.get_profile(_ai_difficulty_id())

func _ai_difficulty_label() -> String:
	return str(_ai_difficulty_policy().get("label", _ai_difficulty_id()))

func _ai_difficulty_locked() -> bool:
	return _snapshot.get("phase") != "PREPARATION" or _snapshot.get("outcome", "ONGOING") != "ONGOING"

func _ai_difficulty_panel() -> void:
	var status := _panel_label("", Vector2.ZERO, 19)
	status.name = "AIDifficultyStatus"
	status.size = Vector2(752, 52)
	for index: int in range(AIDifficultyClass.IDS.size()):
		var id: String = AIDifficultyClass.IDS[index]
		var profile: Dictionary = AIDifficultyClass.get_profile(id)
		var card := Button.new()
		card.name = "AIDifficultyCard_" + id
		card.position = Vector2(index * 257, 60)
		card.size = Vector2(238, 260)
		card.custom_minimum_size = card.size
		card.focus_mode = Control.FOCUS_NONE
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.mouse_force_pass_scroll_events = false
		card.set_meta("difficulty_id", id)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			card.add_theme_stylebox_override(state, ChromeClass.style(state, "stone"))
		card.pressed.connect(_choose_ai_difficulty.bind(id))
		_panel_content.add_child(card)
		var title := _label("", 24)
		title.name = "AIDifficultyTitle_" + id
		title.position = Vector2(12, 12)
		title.size = Vector2(214, 36)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(title)
		var cadence := _label("每%d秒决策 · 至多6条指令" % (int(profile.decision_ticks) / 20), 17)
		cadence.position = Vector2(12, 52)
		cadence.size = Vector2(214, 26)
		cadence.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cadence)
		var summary := RichTextLabel.new()
		summary.name = "AIDifficultySummary_" + id
		summary.position = Vector2(12, 85)
		summary.size = Vector2(214, 138)
		summary.text = str(profile.summary)
		summary.add_theme_font_size_override("normal_font_size", 18)
		summary.scroll_active = false
		summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(summary)
		var action := _label("", 17)
		action.name = "AIDifficultyAction_" + id
		action.position = Vector2(12, 230)
		action.size = Vector2(214, 24)
		action.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(action)
	var fair := _panel_label("同样的初始资源、单位属性与费用；只调整电脑运营和出征策略。", Vector2(0, 328), 17)
	fair.size = Vector2(752, 28)
	var restart := _button("重新开局后选择", "DifficultyRestartButton", Vector2(252, 48))
	restart.position = Vector2(500, 363)
	restart.pressed.connect(_menu_action.bind("reset"))
	_panel_content.add_child(restart)
	_refresh_ai_difficulty()

func _refresh_ai_difficulty() -> void:
	if _ai_difficulty_button == null: return
	var id := _ai_difficulty_id()
	var label := _ai_difficulty_label()
	var locked := _ai_difficulty_locked()
	_ai_difficulty_button.text = "AI难度 · " + label
	_ai_difficulty_button.tooltip_text = "本局难度已锁定；单击查看策略，重新开局后可更改。" if locked else "单击选择简单、标准或困难；筹备工作会保留。"
	if _panel_kind != "difficulty": return
	var status := _panel_content.find_child("AIDifficultyStatus", true, false) as Label
	if status != null:
		status.text = "本局：%s · 已锁定\n交战或结束后不能更改；请重新开局，再选择难度。" % label if locked else "本局：%s · 筹备期可更改\n单击卡片立即设置，保留当前经营、生产和行军安排。" % label
	for profile_id: String in AIDifficultyClass.IDS:
		var card := _panel_content.find_child("AIDifficultyCard_" + profile_id, true, false) as Button
		if card == null: continue
		var selected := profile_id == id
		card.set_meta("selected", selected)
		card.set_meta("locked", locked)
		card.add_theme_stylebox_override("normal", ChromeClass.style("selected" if selected else "normal", "stone"))
		card.tooltip_text = "本局已锁定，重新开局后可更改。" if locked else "单击设置，当前筹备进度会保留。"
		var title := card.find_child("AIDifficultyTitle_" + profile_id, true, false) as Label
		if title != null: title.text = ("✓ " if selected else "") + str(AIDifficultyClass.get_profile(profile_id).label) + (" · 当前" if selected else "")
		var action := card.find_child("AIDifficultyAction_" + profile_id, true, false) as Label
		if action != null: action.text = "已锁定 · 重新开局可更改" if locked else "当前已选" if selected else "单击选择"
		card.queue_redraw()
	var restart := _panel_content.find_child("DifficultyRestartButton", true, false) as Button
	if restart != null: restart.visible = locked

func _choose_ai_difficulty(id: String) -> void:
	if not _can_command(): return
	var result := _submit({"type":"SET_AI_DIFFICULTY", "difficulty_id":id})
	if result.get("accepted", false):
		_set_feedback("已设置电脑难度：%s；筹备安排已保留。" % _ai_difficulty_label(), 5)
	elif result.get("error") in ["AI_DIFFICULTY_LOCKED", "BATTLE_IS_TERMINAL"]:
		_set_feedback("本局电脑难度已锁定；请重新开局后选择。", 5)
	elif result.get("error") == "INVALID_AI_DIFFICULTY":
		_set_feedback("无法执行：请选择简单、标准或困难。", 5)
	_refresh_ai_difficulty()

func _computer_activity_panel() -> void:
	var sides := _option("ComputerSideOption", Vector2.ZERO, Vector2(752, 44))
	for side: Dictionary in _snapshot.get("match_config", {}).get("sides", []):
		if side.get("controller") == "AI": _add_option(sides, "%s · %s · %s" % [Palette.side_label(str(side.side_id)), Factions.profile(str(side.faction_id)).get("label", side.faction_id), AIDifficultyClass.get_profile(str(side.difficulty_id)).get("label", side.difficulty_id)], str(side.side_id))
	_computer_side_id = _choose_option(sides, _computer_side_id)
	sides.item_selected.connect(func(index: int): _computer_side_id = str(sides.get_item_metadata(index)); _refresh_computer_activity())
	var details := RichTextLabel.new()
	details.name = "ComputerActivityDetails"
	details.position = Vector2(0, 53)
	details.size = Vector2(752, 355)
	details.add_theme_font_size_override("normal_font_size", 20)
	details.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_content.add_child(details)
	_refresh_computer_activity()

func _refresh_computer_activity() -> void:
	if _computer_button == null: return
	var controllers: Dictionary = _snapshot.get("computers", {})
	var computer: Dictionary = controllers.get(_computer_side_id, _snapshot.get("computer", {}))
	var policy: Dictionary = computer.get("policy", _ai_difficulty_policy())
	var difficulty := str(policy.get("label", _ai_difficulty_label()))
	var caption := _computer_caption(str(computer.get("status", "DORMANT")))
	var queue := 0
	var queues: Array[String] = []
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("side") != _computer_side_id: continue
		for entry: Dictionary in building.get("queue", []):
			queue += 1
			queues.append("%s · %d/%d · %s" % [_unit_name(str(entry.get("unit_type", ""))), int(entry.get("progress", 0)), int(entry.get("max_progress", 1)), _queue_state(str(entry.get("state", "")))])
	var short_caption: String = "筹备" if _snapshot.get("phase") != "BATTLE" else {"PRESSURING":"前压", "ASSAULT":"攻城"}.get(str(computer.get("status", "")), caption)
	_computer_button.text = "%s电脑 · %s · %d" % [difficulty, short_caption, queue]
	if controllers.size() > 1: _computer_button.text = "%d电脑 · %s · %s" % [controllers.size(), Palette.side_label(_computer_side_id), short_caption]
	if _snapshot.get("outcome", "ONGOING") != "ONGOING": _computer_button.text = "%s电脑 · 已结束" % difficulty
	_computer_button.tooltip_text = "电脑难度：%s\n%s\n查看电脑的资源、生产与部队动向。" % [difficulty, str(policy.get("summary", ""))]
	if _panel_kind != "computer": return
	var details := _panel_content.find_child("ComputerActivityDetails", true, false) as RichTextLabel
	if details == null: return
	var troops := 0
	var heroes := 0
	for soldier: Dictionary in _snapshot.get("soldiers", []):
		if soldier.get("side") != _computer_side_id or not soldier.get("alive", false): continue
		troops += 1
		if soldier.get("unit_type") == "hero": heroes += 1
	var text := "%s · 规则电脑 · %s · %s\n" % [Palette.side_label(_computer_side_id), difficulty, caption]
	if _snapshot.get("outcome", "ONGOING") != "ONGOING":
		text = "规则电脑 · %s · 已结束（最近：%s）\n战斗已经结束，电脑和占领不再推进。\n" % [difficulty, caption]
	elif _snapshot.get("phase") != "BATTLE": text += "大厅冻结：开始前电脑不经营、造兵或进攻。\n"
	else: text += "开战 %.1f 秒 · %d 次宏观决策 · 接收 %d / 拒绝 %d\n" % [int(computer.get("battle_elapsed_ticks", 0)) * 0.05, int(computer.get("decisions", 0)), int(computer.get("accepted_commands", 0)), int(computer.get("rejected_commands", 0))]
	text += "实际存活兵员 %d（含英雄 %d） · 付费生产队列 %d\n" % [troops, heroes, queue]
	if not queues.is_empty(): text += "\n".join(queues) + "\n"
	text += "实际策略：%s\n" % str(policy.get("summary", ""))
	text += "经营决策%.1f秒／威胁反应%.1f秒；每秒最多%d条宏观指令。价格、兵力和战术不因难度改变。\n"%[float(policy.get("decision_ticks",80))/20.0,float(policy.get("reaction_ticks",60))/20.0,int(policy.get("commands_per_second",1))]
	var budget:Dictionary=computer.get("budget",{})
	var saving:Dictionary=budget.get("saving_target",{})
	if saving.is_empty():text+="\n消费预算：无锁定储蓄目标。\n"
	else:
		text+="\n消费预算：%s\n资源缺口 %s；本期还剩%.1f秒，无实际进展会释放。\n"%[str(saving.get("label",saving.get("key",""))),str(saving.get("resource_gap",{})),maxf(0,float(int(saving.get("expires_tick",0))-int(_snapshot.get("tick",0)))/20.0)]
	if not str(budget.get("block_reason","")).is_empty():text+="当前阻塞：%s\n"%str(budget.block_reason)
	if int(budget.get("last_spend_tick",-1))>=0:text+="距离上次实际付款%.1f秒。\n"%(maxi(0,int(_snapshot.get("tick",0))-int(budget.last_spend_tick))/20.0)
	if bool(budget.get("spending_stalled",false)):text+="检测到可消费订单停滞，正尝试合法后备行动。\n"
	if computer.get("pressure_active", false): text += "单队前压：%s → 玩家前线；其他部队继续经营扩张。\n" % str(computer.get("pressure_army_id", ""))
	var recent: Array = computer.get("latest_attempts", [])
	if not recent.is_empty():
		text += "\n最近实际提交（接收不等于完成）：\n"
		for index: int in range(maxi(0, recent.size() - 4), recent.size()):
			var entry: Dictionary = recent[index]
			text += "%s · %s\n" % [str(entry.get("type", "")), "接收" if entry.get("accepted", false) else "拒绝"]
	details.text = text

func _toggle_sound() -> void:
	_audio.set_muted(not _audio.muted)
	var button := _panel_content.find_child("SoundMuteButton", true, false) as Button
	if button != null: button.text = "音效 · 静音" if _audio.muted else "音效 · 开启"
	_set_feedback("音效已静音；视觉反馈仍保留。" if _audio.muted else "音效已开启。", 3)
	_audio.record_ui("SELECT", "sound")

func _change_sound_volume(value: float) -> void:
	_audio.set_volume(value)
	var caption := _panel_content.find_child("SoundVolumeCaption", true, false) as Label
	if caption != null: caption.text = "音量 %d%%" % roundi(_audio.volume * 100)

func _drain_outcome_cues() -> void:
	var chosen: Dictionary = {}
	for cue: Dictionary in _audio.drain_cues():
		if not cue.get("notify", false): continue
		if cue.get("kind") == "FIELD_REWARD" and cue.has("position"):
			_field_reward_marks.append({"receipt_id":str(cue.get("receipt_id", "")), "position":cue.position, "icon":str(cue.get("icon", "hero")), "caption":str(cue.get("caption", "探索奖励已结算")), "age":0.0, "lifetime":2.0})
			if _field_reward_marks.size() > 4: _field_reward_marks.pop_front()
		if chosen.is_empty() or int(cue.get("priority", 0)) > int(chosen.get("priority", 0)): chosen = cue
	if chosen.is_empty(): return
	var caption := str(chosen.get("caption", ""))
	var id := str(chosen.get("entity_id", ""))
	if str(chosen.get("kind", "")).begins_with("CAPTURE_"):
		var readout := CaptureReadoutClass.read_site(_snapshot, id)
		if not readout.is_empty(): caption += " · " + ("根据地 " if readout.kind == "RESOURCE" else "村庄 ") + id.get_slice("_", 1)
	elif chosen.get("kind") == "PRODUCTION": caption += " · " + _unit_name(str(chosen.get("unit_type", "")))
	elif chosen.get("kind") == "BUILD_COMPLETE": caption += " · " + _building_display_name(str(chosen.get("building_type","")))
	elif chosen.get("kind") == "TECH_COMPLETE":
		var researched:Dictionary=preload("res://src/simulation/strategic_faction_technologies_v4.gd").lookup(id,_faction_id())
		caption += " · " + str(researched.get("label",{"ATTACK":"攻击", "ARMOR":"护甲"}.get(id,id)))
	_outcome_notice.text = caption
	_outcome_seconds = 4
	_outcome_notice.visible = not _backdrop.visible

func _menu_panel() -> void:
	var paused := _command_desk_paused()
	_panel_title.text = "指挥台 · 已暂停" if paused else "指挥台"
	_panel_label("战场画风", Vector2(0, 104), 18)
	var visual_mode := OptionButton.new()
	visual_mode.name = "BattlefieldStyleM77"
	visual_mode.position = Vector2(122, 96)
	visual_mode.size = Vector2(400, 44)
	visual_mode.add_item("Heroic 像素 · 原版本")
	visual_mode.add_item("几何 2.5D · 原创低多边形试验")
	visual_mode.add_item("几何 2.5D · 无实时阴影 / 抗锯齿")
	visual_mode.add_item("纸雕浮绘 2D · 共享图集试验")
	visual_mode.select(["pixel", "geometric", "geometric-low", "relief"].find(_battlefield_style_m78()))
	visual_mode.item_selected.connect(func(index: int): _switch_battlefield_style_m78(["pixel", "geometric", "geometric-low", "relief"][index]))
	_panel_content.add_child(visual_mode)
	var n := 0
	for entry: Array in [["开始交战", "StartBattleButton", "start"], ["重新开局", "RestartStrategicButton", "reset"], ["聚焦当前根据地", "HomeCameraButton", "home"], ["完整地图", "OverviewCameraButton", "overview"], ["放大", "ZoomInButton", "zoom_in"], ["缩小", "ZoomOutButton", "zoom_out"], ["历史演练版", "LegacyModeButton", "legacy"], ["观战 / 切换视角", "PerspectiveMenuButton", "perspective"], ["英雄战斗统计", "BattleStatisticsButton", "statistics"]]:
		var button := _button(str(entry[0]), str(entry[1]), Vector2(246, 48))
		button.position = Vector2((n % 3) * 260, 156 + (n / 3) * 54)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_menu_action.bind(str(entry[2])))
		_panel_content.add_child(button)
		n += 1
	var hint := _panel_label("本地对局已暂停 · 关闭继续" if paused else "单击指挥 · 方向键 / 触边移镜头", Vector2(0, 322), 17)
	hint.tooltip_text = "亲自指挥时，打开指挥台暂停战斗，关闭后继续；经营和招募面板不暂停，电脑观战也不暂停。\n单击窗口外关闭面板。小地图用于移动镜头。"
	var computer: Dictionary = _snapshot.get("computer", {})
	var status := str(computer.get("status", computer.get("phase", "DORMANT")))
	var caption: String = _computer_policy_caption(status)
	if paused: caption = "暂停 · 关闭指挥台继续"
	var computer_fact := _panel_label("规则电脑 · " + caption, Vector2(398, 322), 17)
	computer_fact.name = "ComputerControllerFacts"
	computer_fact.tooltip_text = "电脑与玩家遵循相同的金币、人口、招募和战斗规则。电脑可查看全场战况。"
	var mute := _button("音效 · 静音" if _audio.muted else "音效 · 开启", "SoundMuteButton", Vector2(180, 44))
	mute.position = Vector2(0, 370)
	mute.pressed.connect(_toggle_sound)
	_panel_content.add_child(mute)
	var shake := _button("震屏 · 开启" if _screen_shake_enabled_r9 else "震屏 · 关闭", "ScreenShakeButton", Vector2(180,44))
	shake.position=Vector2(0,424)
	shake.tooltip_text="只改变大招的短促画面反馈，不改变伤害、控制或镜头位置。"
	shake.pressed.connect(func():
		_screen_shake_enabled_r9=not _screen_shake_enabled_r9
		shake.text="震屏 · 开启" if _screen_shake_enabled_r9 else "震屏 · 关闭"
		_refresh_canvas())
	_panel_content.add_child(shake)
	var volume := HSlider.new()
	volume.name = "SoundVolumeSlider"
	volume.position = Vector2(208, 370)
	volume.size = Vector2(240, 44)
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.01
	volume.value = _audio.volume
	volume.tooltip_text = "本游戏音效音量；不更改系统音量。"
	volume.value_changed.connect(_change_sound_volume)
	_panel_content.add_child(volume)
	var volume_caption := _panel_label("音量 %d%%" % roundi(_audio.volume * 100), Vector2(478, 381), 19)
	volume_caption.name = "SoundVolumeCaption"
	if heroic_2d_enabled:
		var credits := _button("美术署名", "HeroicArtCreditsButton", Vector2(150, 44))
		credits.position = Vector2(607, 370)
		credits.pressed.connect(_open_panel.bind("credits"))
		_panel_content.add_child(credits)


func _switch_geometry_view_m77(enabled: bool) -> void:
	# Retain the M77 interface for existing captures and regression checks.
	_switch_battlefield_style_m78("geometric" if enabled else "pixel")

func _battlefield_style_m78() -> String:
	if relief_2d_enabled: return "relief"
	if geometric_3d_enabled: return "geometric-low" if geometric_low_effects_m78 else "geometric"
	if frontier_3d_enabled: return "frontier-legacy"
	return "pixel"

func _new_battlefield_canvas_m78() -> Node2D:
	if relief_2d_enabled: return ReliefCanvasM78.new()
	if geometric_3d_enabled:
		var result := GeometricCanvasM77.new()
		result.quality_override_m78 = 1 if geometric_low_effects_m78 else 0
		return result
	return Frontier3DCanvas.new() if frontier_3d_enabled else (HeroicCanvas.new() if heroic_2d_enabled else CanvasClass.new())

func _switch_battlefield_style_m78(style: String) -> void:
	if style not in ["pixel", "geometric", "geometric-low", "relief"] or style == _battlefield_style_m78(): return
	if style == "pixel" and not bool(HeroicAtlas.validate_installation().get("ready", false)):
		_set_feedback("像素版需要已校验的 Heroic Starter 素材；几何版继续保留。", 4)
		return
	var center := Vector2(_camera.get_center())
	var zoom := float(_camera.get_zoom())
	relief_2d_enabled = style == "relief"
	geometric_3d_enabled = style in ["geometric", "geometric-low"]
	geometric_low_effects_m78 = style == "geometric-low"
	frontier_3d_enabled = geometric_3d_enabled
	heroic_2d_enabled = not geometric_3d_enabled
	_dismiss_context_help()
	_field.remove_child(_canvas)
	_canvas.queue_free()
	_camera = Frontier3DCamera.new() if geometric_3d_enabled else CameraClass.new()
	_camera.configure(_bounds(), _field_rect(), float(_snapshot["scenario"]["camera_max_zoom"]))
	_camera.zoom_at(_field_rect().get_center(), zoom)
	_camera.center_on(center)
	_canvas = _new_battlefield_canvas_m78()
	_canvas.name = "ReliefBattlefieldM78" if relief_2d_enabled else ("GeometricBattlefieldM77" if geometric_3d_enabled else "HeroicPixelBattlefield")
	_field.add_child(_canvas)
	_selected_facts.heroic_2d = heroic_2d_enabled
	get_window().title = "魔兽指挥官 · " + {"pixel":"像素战场", "geometric":"几何战场", "geometric-low":"几何战场（精简特效）", "relief":"浮绘战场"}[style]
	# Keep the session, selection, inventory and all orders. A renderer switch
	# is not a new game, command or authority tick.
	_refresh_canvas()
	_set_feedback({"pixel":"已切回 Heroic 像素原版", "geometric":"已切换几何 2.5D 原版", "geometric-low":"已切换几何低特效 · 分辨率不变", "relief":"已切换纸雕浮绘 2D 试验画面"}[style], 3)

func _heroic_credits_panel() -> void:
	_panel_title.text = "美术署名 · 2D 像素版"
	var full := HeroicCollection.active()
	var names := "Heroic Asset Series · Starter + Collection" if full else "Heroic Asset Series: Starter Pack"
	var credit := _panel_label(names + "\nArtwork by Aleksandr Makarov (iknowkingrabbit)\nUsed under the author's asset-pack licenses.", Vector2(0, 14), 23)
	credit.name = "HeroicAuthorAttribution"
	credit.size = Vector2(760, 110)
	var detail := "地形／建筑／兵种：Overworld、Buildings、Creature。\n部分图标／技能：Icon Pack、Magic Book。\n未匹配角色与地景补绘由本项目单独制作。" if full else "地形、树山、道路与房屋：作者免费 Starter。\n兵种轮廓与动作：本项目原创过渡像素美术。\n完整包尚未安装；不含《英雄之时》提取物。"
	if full:
		detail += "\nAI生成原创角色 %d/11；非上述作者绘制，无游戏提取物。" % int(HeroicGenerated.status().get("accepted_count",0))
	detail += "\nM38指挥图标／资源图／六张头像为本项目另行AI生成。"
	var coverage := _panel_label(detail, Vector2(0, 150), 21)
	coverage.size = Vector2(760, 142)
	var source := _panel_label("来源：iknowkingrabbit.itch.io\n原图仅本地合法安装，公开源码不裸图再分发。", Vector2(0, 285), 19)
	source.size = Vector2(760, 75)

func _menu_action(action: String) -> void:
	_close_panel()
	match action:
		"start":
			if _in_lobby(): _start_match()
			elif _snapshot.get("phase") == "PREPARATION": _submit({"type":"START_BATTLE"})
		"reset":
			_explicit_observer = false
			_view_side_id = "PLAYER"
			_clear_direct_input()
			# This is a new match lifecycle, not a modal interruption. Lobby
			# shielding consumes old releases, so no prior touch ownership may
			# survive into the next started match. General suppress stays intact.
			_gesture = GestureClass.new()
			_cancel_target()
			_selected_unit_id = ""
			_selected_warband_id = ""
			_selected_worker_id = ""
			_selected_site_id = ""
			_command_feedback.reset()
			_audio.reset()
			_field_reward_marks.clear()
			_match_seed = _new_match_seed()
			_snapshot = _session.reset(_match_seed)
			_audio.observe({}, _snapshot, _camera.get_visible_world_rect())
			_outcome_seconds = 0
			_outcome_notice.hide()
			_feedback.text = ""
			_panel_feedback.text = ""
			_army_signature = ""
			_camera.configure(_bounds(), _field_rect(), float(_snapshot.get("scenario", {}).get("camera_max_zoom", 4)))
			_camera.fit_all()
			_camera.zoom_at(_field_rect().get_center(), float(_snapshot["scenario"]["initial_zoom"]))
			_camera.center_on(_home_position())
			_set_feedback("返回开局大厅 · 种子%d · 原合法地图和席位已保留；单击开始。" % _match_seed, 7)
			_audio.record_ui("SELECT", "restart")
		"home": _camera.center_on(_home_position())
		"overview": _camera.fit_all()
		"zoom_in": _camera.zoom_at(_field_rect().get_center(), 1.25)
		"zoom_out": _camera.zoom_at(_field_rect().get_center(), 0.8)
		"legacy": get_tree().change_scene_to_file("res://scenes/legacy.tscn")
		"perspective": _open_panel("perspective")
		"statistics": _open_hero_statistics()
	_refresh()

func _input(event: InputEvent) -> void:
	if is_instance_valid(_hero_arena_surface): return # The laboratory GUI receives this event; no Main commands/help.
	if is_instance_valid(_statistics_surface):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_hero_statistics()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion or event is InputEventScreenTouch or event is InputEventScreenDrag:
		_pointer = event.position
	if _context_help != null and _context_help.handle_event(event):
		get_viewport().set_input_as_handled()
		return
	if _in_lobby():
		if event is InputEventKey and event.keycode == KEY_ESCAPE: get_viewport().set_input_as_handled()
		return # GUI owns lobby events; no gesture, ground tap or stale input.
	if event is InputEventMouseMotion:
		_pointer = event.position
		_pointer_inside = get_viewport_rect().has_point(_pointer)
	elif event is InputEventScreenTouch:
		_pointer = event.position
		var action := _gesture.touch(event.index, event.position, event.pressed, event.canceled, _is_ground(event.position))
		if action.has("tap"): _terrain_tap(action.tap)
		if _is_ground(event.position): get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_pointer = event.position
		var action := _gesture.drag(event.index, event.position)
		if action.has("factor"):
			_camera.pan_screen(action.midpoint - action.previous_midpoint)
			_camera.zoom_at(action.midpoint, action.factor)
			_refresh_canvas()
			get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		if not _gesture.active() and _is_ground(event.position) and not _direct_stick_active() and is_finite(event.factor) and event.factor > 0:
			_camera.zoom_at(event.position, event.factor)
			_refresh_canvas()
			get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _backdrop.visible: _close_panel()
		elif not _target_mode.is_empty(): _cancel_target()
		else: _select_army("")
		_clear_direct_input()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Real touch already owns its semantic terrain tap. Ignore the optional
		# synthetic mouse counterpart to avoid a second command after modal close.
		if event.device == InputEvent.DEVICE_ID_EMULATION: return
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _is_ground(event.position):
			_terrain_tap(event.position)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and _is_ground(event.position):
			_camera.zoom_at(event.position, 1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15)
			_refresh_canvas()
			get_viewport().set_input_as_handled()

func _terrain_tap(point: Vector2) -> void:
	if _in_lobby(): return
	# The camera's authoritative center never shakes. Undo only the painted
	# translation once, before every ordinary foot/slot/terrain hit test.
	if is_instance_valid(_canvas) and _canvas.has_method("feedback_screen_offset_r9"):point-=_canvas.feedback_screen_offset_r9()
	var world := _bounded_point(_camera.screen_to_world(point))
	if _can_command() and _target_mode == "BUILD":
		if OutpostSlotUI.enabled(_snapshot):
			if _open_tapped_building(point,true): return
			if not _open_tapped_building_slot(point,_blueprint_type): _set_feedback("请单击地图上对应类型的固定建筑空位。", 5)
			return
		var type := _blueprint_type
		_cancel_target(false)
		_submit({"type":"PLACE_BUILDING", "building_type":type, "position":world})
		return
	if _can_command() and _target_mode == "ATTACK_MOVE":
		_cancel_target(false)
		_submit({"type":"ATTACK_MOVE", "subject_id":_selected_warband_id, "target_position":world})
		return
	var nearest := ""
	var distance := 24.0 * 24.0
	for soldier: Dictionary in _snapshot.get("soldiers", []):
		if not _inspectable_actor_r9(soldier): continue
		var delta := _camera.world_to_screen(Vector2(soldier.get("position", Vector2.ZERO))).distance_squared_to(point)
		if delta < distance or (delta == distance and not nearest.is_empty() and str(soldier["id"]) < nearest):
			distance = delta
			nearest = str(soldier["id"])
	if not nearest.is_empty(): _select_unit(nearest)
	elif _select_tapped_worker(point): return
	elif _open_tapped_building(point): return
	elif _select_tapped_visual_body(point): return
	elif _open_tapped_building(point,true): return
	elif _open_tapped_building_slot(point): return
	elif _select_tapped_source(point): return
	elif _can_command() and _pickup_tapped_loot(point): return
	else:
		_selected_source_id = ""
		# Inspection is local; the ordinary order keeps the exact terrain target.
		# Entering the 180-world-unit circle is a separate explicit normal command.
		var previous_site := _selected_site_id
		_selected_site_id = _tapped_site(point)
		if _can_command() and not _selected_warband_id.is_empty(): _submit({"type":"MOVE", "subject_id":_selected_warband_id, "target_position":world})
		elif _can_command() and _selected_unit_owned_r9(): _submit({"type":"UNIT_MOVE", "unit_id":_selected_unit_id, "target_position":world})
		else:
			if not _selected_site_id.is_empty() and _selected_site_id != previous_site: _audio.record_ui("SELECT", _selected_site_id)
			_refresh()

func _open_tapped_building_slot(point: Vector2, required_type: String = "") -> bool:
	var slot := OutpostSlotUI.hit(_snapshot, _camera, point,required_type)
	if slot.is_empty(): return false
	# At strategic zoom, pad touch targets overlap. First tap zooms to the
	# site, second tap opens the deliberate pad; never build through a roof.
	if float(_camera.get_scale()) < 0.65:
		var previous_scale := float(_camera.get_scale())
		_camera.zoom_at(point,0.75/maxf(float(_camera.get_scale()),0.01))
		_camera.center_on(Vector2(slot.position))
		_refresh_canvas()
		if float(_camera.get_scale()) > previous_scale+0.01:
			_set_feedback("已放大建筑区，请单击要建造的空位。",4)
			return true
		# Very large maps/small screens can reach max zoom below the target.
		# Do not trap the player in an endless zoom-first loop: use the card.
	_open_building_slot(str(slot.get("id", "")))
	if not required_type.is_empty():
		_selected_slot_building_type=required_type
		_refresh_slot_build_panel()
	return true

func _open_tapped_building(point: Vector2, visual_body: bool = false) -> bool:
	var candidates: Array = _snapshot.get("buildings",[]).duplicate()
	if visual_body:
		# Unit feet/bodies still win. Opaque buildings precede vacant pads;
		# transparent roof corners remain ground, not rectangular hit boxes.
		candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
			var da := _camera.world_to_screen(Vector2(a.get("position",Vector2.ZERO))).distance_squared_to(point)
			var db := _camera.world_to_screen(Vector2(b.get("position",Vector2.ZERO))).distance_squared_to(point)
			return str(a.get("id",""))<str(b.get("id","")) if da==db else da<db)
	for building: Dictionary in candidates:
		if building.get("side") != _view_side() or int(building.get("hp", 0)) <= 0: continue
		var screen: Vector2 = _camera.world_to_screen(Vector2(building["position"]))
		var radius := maxf(float(building.get("radius", 24)) * float(_camera.get_scale()), 22)
		if visual_body:
			if frontier_3d_enabled or heroic_2d_enabled:
				if _canvas == null: continue
				if not _canvas.visual_body_contains(str(building.get("id","")),"building",point): continue
			elif not PixelClass.building_body_contains(building,point-screen,float(_camera.get_scale())):continue
		elif screen.distance_to(point) > radius: continue
		var type := str(building.get("building_type", ""))
		_selected_source_id = ""
		_selected_building_id = str(building.get("id", "")) if type in ["TOWER","SITE_TOWER","BASE"] or _observing() else ""
		if type in ["TOWER","SITE_TOWER"]:
			_clear_direct_input()
			_selected_unit_id = ""
			_selected_warband_id = ""
			_selected_worker_id = ""
			_selected_site_id = ""
			_build_context()
		if not building.get("complete", false): _open_panel("build" if OutpostSlotUI.enabled(_snapshot) else "economy")
		elif type in ["TOWER","SITE_TOWER"]: _open_panel("tower")
		elif type == "FOUNDRY": _open_panel("tech")
		elif type == "BASE":
			_base_building_id = str(building["id"])
			_open_panel("base")
		elif type == "SHOP":
			if _hero(_selected_unit_id).is_empty():
				var hero := _friendly_hero()
				if not hero.is_empty(): _select_unit(str(hero.get("unit_id", "")))
			_open_panel("inventory")
		elif type in ["BARRACKS", "RANGE", "ALTAR", "WORKSHOP", "DRAGON_ROOST"]:
			_recruit_building_id = str(building["id"])
			_open_panel("recruit")
		else:
			_set_feedback("%s · %d/%d%s" % [BUILDING_NAMES.get(type, type), int(building.get("hp", 0)), int(building.get("max_hp", 1)), " · 射程%d · 自动攻击" % int(building.get("attack_range", 0)) if type == "TOWER" else ""], 4)
		_refresh()
		return true
	return false

func _pickup_tapped_loot(point: Vector2) -> bool:
	for loot: Dictionary in _snapshot.get("neutral_loot", []):
		if loot.get("state") != "AVAILABLE": continue
		if _camera.world_to_screen(Vector2(loot.position)).distance_to(point) > 28: continue
		if loot.get("owner") != _view_side() and loot.get("pickup_scope") != "PUBLIC":
			_set_feedback("战利品属于另一方，无法拾取。", 4)
			return true
		var hero := _hero(_selected_unit_id)
		if hero.is_empty() or not hero.get("alive", false):
			_set_feedback("先选择一位存活英雄，再单击战利品。背包满时物品会留在原地。", 5)
			return true
		if Vector2(hero.position).distance_to(Vector2(loot.position)) > float(loot.get("pickup_radius", 160)):
			_submit({"type":"UNIT_MOVE", "unit_id":_selected_unit_id, "target_position":Vector2i(loot.position)})
			_set_feedback("英雄靠近后自动拾取；背包满则留在地面。", 4)
		else: _submit({"type":"PICKUP_LOOT", "unit_id":_selected_unit_id, "loot_id":str(loot.id)})
		return true
	return false

func _is_ground(point: Vector2) -> bool:
	if _in_lobby() or _backdrop.visible or not _field_rect().grow(-4).has_point(point) or not _camera.get_projected_world_rect().has_point(point): return false
	return not _pointer_occluded(point)

func _pointer_occluded(point: Vector2) -> bool:
	# Edge navigation uses true viewport boundaries, not the military tap inset.
	# A 4px terrain safety margin must not starve a12px camera edge band.
	for surface: Control in [_top_panel, _troop_counts, _composition_button, _menu_button, _minimap, _strength_scores, _runtime_metrics, _view_button, _toolbar, _army_scroll, _context, _move_joystick, _attack_joystick, _inventory_button, _hero_automation_button, _hero_bag, _actor_inspector, _feedback, _cancel_target_button, _hero_roster, _info_button, _roster_button, _battle_start_button, _computer_button, _ai_difficulty_button, _site_button, _selected_facts, _selection_label]:
		if surface.is_visible_in_tree() and surface.get_global_rect().has_point(point): return true
	for joystick: Control in _skill_joysticks.values():
		if joystick.is_visible_in_tree() and joystick.get_global_rect().has_point(point): return true
	return false

func _locate_camera(point: Vector2) -> void:
	if _in_lobby(): return
	_camera.center_on(point)
	_refresh_canvas()

func _advance_navigation(delta: float) -> void:
	var keys := Vector2(int(Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_LEFT)), int(Input.is_physical_key_pressed(KEY_DOWN)) - int(Input.is_physical_key_pressed(KEY_UP)))
	var active := bool(_move_joystick.active) or bool(_attack_joystick.active)
	for joystick: Control in _skill_joysticks.values(): active = active or bool(joystick.active)
	var context := _camera_input_context(_pointer)
	context["dragging"] = active or _gesture.active()
	_navigation.advance(_camera, delta, keys, _pointer, get_viewport_rect(), _field_rect(), context)

func _camera_input_context(pointer: Vector2) -> Dictionary:
	var popup_visible := false
	for child: Node in _panel_content.get_children():
		if child is OptionButton and child.get_popup().visible: popup_visible = true
	var focus := get_viewport().gui_get_focus_owner()
	var editable := focus is LineEdit or focus is TextEdit or focus is SpinBox or focus is OptionButton
	var dragging := bool(_move_joystick.active) or bool(_attack_joystick.active)
	for joystick: Control in _skill_joysticks.values(): dragging = dragging or bool(joystick.active)
	return {"window_focused":get_window().has_focus(), "blocked":_in_lobby() or _backdrop.visible or not _target_mode.is_empty() or popup_visible, "dragging":dragging, "keyboard_blocked":editable or popup_visible or _in_lobby(), "pointer_inside_window":_pointer_inside, "pointer_blocked":_pointer_occluded(pointer)}

func _advance_direct_input(delta: float) -> void:
	if not _can_command() or _backdrop.visible or _move_vector.is_zero_approx() or _snapshot.get("outcome", "ONGOING") != "ONGOING":
		_steer_elapsed = 0
		return
	_steer_elapsed += maxf(delta, 0)
	if _steer_elapsed < STEER_INTERVAL: return
	_steer_elapsed = 0 # Never catch up a stalled render frame with a tool burst.
	if not _selected_unit_id.is_empty():
		var unit := _soldier(_selected_unit_id)
		if not _selected_unit_owned_r9(): _clear_direct_input(); return
		var result := _submit({"type":"UNIT_MOVE", "unit_id":_selected_unit_id, "target_position":_bounded_point(Vector2(unit["position"]) + _move_vector * 120)})
		_steer_sent = bool(result.get("accepted", false))
	elif not _selected_warband_id.is_empty():
		var army := _selected_command_army_r12()
		if not army.is_empty():
			var result := _submit({"type":"MOVE", "subject_id":_selected_warband_id, "target_position":_bounded_point(Vector2(army["anchor"]) + _move_vector * 120)})
			_steer_sent = bool(result.get("accepted", false))

func _on_move_vector(value: Vector2) -> void:
	if not _can_command(): _move_vector = Vector2.ZERO; _steer_sent = false; return
	# A deliberate nonzero steering gesture replaces a pending point plan,
	# just like an immediate army button. Dead-zone/release vectors must not
	# erase it, and this local cancellation must not clear the captured stick.
	if not value.is_zero_approx() and not _target_mode.is_empty() and not _in_lobby() and not _backdrop.visible and _snapshot.get("outcome", "ONGOING") == "ONGOING":
		_cancel_target(false)
	_move_vector = value
	if value.is_zero_approx() and _steer_sent:
		# Clear state before dispatch: _submit refreshes selection and can clear a
		# dead unit again. A release issues one STOP, not recursive repeat writes.
		_steer_sent = false
		if not _selected_unit_id.is_empty(): _submit({"type":"UNIT_STOP", "unit_id":_selected_unit_id})
		elif not _selected_warband_id.is_empty(): _submit({"type":"STOP", "subject_id":_selected_warband_id})

func _unit_attack(direction: Vector2) -> void:
	if not _can_command() or not _selected_unit_owned_r9() or _backdrop.visible: return
	var command := {"type":"UNIT_ATTACK", "unit_id":_selected_unit_id}
	var unit := _soldier(_selected_unit_id)
	var origin := Vector2(unit.get("position", Vector2.ZERO))
	var local_range := maxf(230, float(unit.get("attack_range", 0)) + 14)
	var target_point := origin + direction * local_range
	var nearest := ""
	var distance := INF
	var targets: Array = _snapshot.get("soldiers", []).duplicate()
	targets.append_array(_snapshot.get("workers", []))
	# Use the same local aim for destructible structures; fixed shops are not
	# combat targets. The Session still validates side, life and attack layer.
	for building: Dictionary in _snapshot.get("buildings", []):
		if building.get("building_type") in BUILDINGS: targets.append(building)
	for enemy: Dictionary in targets:
		if enemy.get("side") == _view_side() or int(enemy.get("hp", 0)) <= 0: continue
		if str(enemy.get("movement_layer", "GROUND")) not in unit.get("attack_layers", ["GROUND"]): continue
		var enemy_position := Vector2(enemy.get("position", Vector2.ZERO))
		# Direct attack is a local fighting stick, not a full-map FOCUS macro.
		if origin.distance_to(enemy_position) > local_range: continue
		var d := enemy_position.distance_squared_to(target_point)
		if d < distance:
			distance = d
			nearest = str(enemy["id"])
	if nearest.is_empty():
		_command_feedback.record(command, {"accepted":false}, _snapshot)
		_audio.record_command(command, {"accepted":false, "reason":"附近没有敌军"}, _snapshot)
		_set_feedback("附近没有敌军；远征请使用部队进攻式移动。", 4)
		_refresh_canvas()
		return
	command["target_id"] = nearest
	_submit(command)

func _cast_skill(direction: Vector2, skill_id: String) -> void:
	if not _can_command() or not _selected_unit_owned_r9() or _backdrop.visible: return
	var hero := _hero(_selected_unit_id)
	var skills: Array = hero.get("skills", [])
	var slot := SKILLS.find(skill_id)
	if slot < 0 or slot >= skills.size(): return
	skill_id = str(skills[slot].id)
	var range_value := 0.0
	for skill: Dictionary in hero.get("skills", []):
		if skill.get("id") == skill_id: range_value = float(skill.get("range", 0))
	var position := Vector2(_soldier(_selected_unit_id).get("position", Vector2.ZERO))
	var command := {"type":"HERO_SKILL", "unit_id":_selected_unit_id, "skill_id":skill_id}
	if range_value > 0 and not direction.is_zero_approx(): command["target_position"] = _bounded_point(position + direction * range_value * 0.90)
	_submit(command)
	_skill_aim.clear()

func _clear_direct_input() -> void:
	_steer_sent = false
	_gesture.suppress()
	_skill_aim.clear()
	_steer_elapsed = 0
	if _move_joystick != null: _move_joystick.clear()
	_move_vector = Vector2.ZERO
	if _attack_joystick != null: _attack_joystick.clear()
	for joystick: Control in _skill_joysticks.values(): joystick.clear()

func _direct_stick_active() -> bool:
	if _move_joystick.active or _attack_joystick.active: return true
	for joystick: Control in _skill_joysticks.values():
		if joystick.active: return true
	return false

func _cancel_target(notify: bool = true) -> void:
	var had_target := not _target_mode.is_empty()
	if notify and not _target_mode.is_empty(): _audio.record_ui("CANCEL", _target_mode)
	_target_mode = ""
	_blueprint_type = ""
	_feedback_seconds = 0
	if had_target:
		# Target instructions are only valid while the target mode owns input.
		# Clear both projections before another panel can display the old prompt.
		# Successful placement submits its fresh result after this cancellation.
		_feedback.text = ""
		_feedback.tooltip_text = ""
		_feedback.hide()
		if _panel_feedback != null:
			_panel_feedback.text = ""
			_panel_feedback.tooltip_text = ""
	_refresh_canvas()

func _refresh_target_controls() -> void:
	if _cancel_target_button == null: return
	_cancel_target_button.visible = not _target_mode.is_empty() and not _backdrop.visible
	var attack_move := _context.find_child("AttackMoveButton", true, false) as Button
	if attack_move != null:
		attack_move.set("selected", _target_mode == "ATTACK_MOVE")
		attack_move.queue_redraw()
	_layout_hero_feedback()

func _submit(command: Dictionary) -> Dictionary:
	if not _can_command():
		_last_result = {"accepted":false, "error":"MATCH_NOT_STARTED" if _in_lobby() else "OBSERVER_ONLY"}
		_set_feedback("请先开始对局。" if _in_lobby() else "观察模式不发送游戏指令。", 4)
		return _last_result
	if _army_control_mode_r12=="UNIT_TYPE" and _selected_unit_type_r12.is_empty() and command.get("subject_id")==_selected_warband_id:
		_last_result={"accepted":false,"error":"SELECT_TYPE"}
		_set_feedback("请先单击下方某个兵种头像；或切回整队调度。",4)
		return _last_result
	var previous := _snapshot
	var actual := command.duplicate(true)
	if not _selected_unit_type_r12.is_empty() and command.get("subject_id")==_selected_warband_id:
		var kind := str(command.type)
		if kind in ["FOCUS","ATTACK_BASE"]:
			var target := _army(str(command.get("target_warband_id",""))) if kind=="FOCUS" else _building(str(command.get("target_base_id","")))
			if not target.is_empty(): actual={"type":"ATTACK_MOVE","subject_id":_selected_warband_id,"target_position":target.get("anchor",target.get("position",Vector2i.ZERO))}
		if actual.type in ["MOVE","ATTACK_MOVE","STOP","RETREAT"]:
			actual={"type":"TYPE_ORDER","subject_id":_selected_warband_id,"unit_type":_selected_unit_type_r12,"order":actual.type,"target_position":actual.target_position} if actual.has("target_position") else {"type":"TYPE_ORDER","subject_id":_selected_warband_id,"unit_type":_selected_unit_type_r12,"order":actual.type}
	_last_result = _session.submit_strategic(actual)
	_snapshot = _session.get_snapshot()
	var accepted := bool(_last_result.get("accepted", false))
	_command_feedback.record(command, _last_result, _snapshot)
	_audio.record_command(command, _last_result, _snapshot)
	_audio.observe(previous, _snapshot, _camera.get_visible_world_rect())
	_drain_outcome_cues()
	var reason := str(_last_result.get("reason", _last_result.get("error", _last_result.get("code", "条件不满足"))))
	_set_feedback("指令已接收" if accepted else "无法执行：" + _friendly_refusal(reason), 3)
	if not accepted:
		_feedback.tooltip_text = "诊断代码：" + reason
		_panel_feedback.tooltip_text = _feedback.tooltip_text
	_refresh()
	return _last_result

func _set_feedback(value: String, duration: float) -> void:
	_feedback.text = value
	_feedback.tooltip_text = value + "\n操作提示 · 悬浮或长按阅读完整说明。"
	if _panel_feedback != null: _panel_feedback.text = value
	_feedback_seconds = duration
	_feedback.show()
	_refresh_target_controls()

func _friendly_refusal(reason: String) -> String:
	var actual_codes := {"POPULATION_CAP":"人口不足，请占领更多据点", "HERO_CAP":"英雄名额已满，请升级基地", "HERO_ROSTER_FULL":"英雄名册已满：整局最多三种，死亡不释放名额", "HERO_ALREADY_ALIVE":"该英雄已在阵中", "HERO_ALREADY_QUEUED":"该英雄已排队招募或复活", "HERO_QUOTE_UNAVAILABLE":"英雄报价暂不可用，请重新打开招募面板", "HERO_ALREADY_PRESENT_OR_QUEUED":"该英雄已在阵中或排队中", "BUILDING_UNAVAILABLE":"建筑不可用，请重新选择", "FOREIGN_ARMY":"不能调遣其他玩家的部队"}
	if actual_codes.has(reason): return str(actual_codes[reason])
	return str({"PLACEMENT_OCCUPIED_OR_OUTSIDE":"此处被占用或超出边界，请换位置", "INSUFFICIENT_STOCK":"资源不足", "INSUFFICIENT_RESOURCES":"资源不足", "POPULATION_LIMIT":"人口不足，请占领更多据点", "CAPACITY_EXCEEDED":"人口不足，请占领更多据点", "QUEUE_FULL":"生产队列已满", "BASE_TIER_REQUIRED":"基地等级不足", "REQUIRED_BASE_TIER":"基地等级不足", "BASE_UPGRADING":"基地正在升级，订单会等待", "NOT_BATTLE_PHASE":"尚未开始交战", "BATTLE_NOT_STARTED":"尚未开始交战", "MATCH_NOT_STARTED":"请先从大厅开始对局", "INVALID_PRODUCER":"出兵建筑不可用，请重新选择", "INVALID_BUILDING":"建筑不可用，请重新选择", "NO_SKILL_POINTS":"技能点不足", "SKILL_ON_COOLDOWN":"技能冷却中", "INSUFFICIENT_MANA":"蓝量不足", "HERO_SLOTS_FULL":"英雄名额已满，请升级基地", "HERO_ALREADY_ACTIVE":"该英雄已在阵中"}.get(reason, reason if not reason.contains("_") else "当前条件不满足，请查看单位或建筑详情"))

func _bounded_point(point: Vector2) -> Vector2i:
	var bounds := _bounds()
	return Vector2i(roundi(clampf(point.x, bounds.position.x + 12, bounds.end.x - 12)), roundi(clampf(point.y, bounds.position.y + 12, bounds.end.y - 12)))

func _friendly_armies(include_reserve: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for army: Dictionary in _snapshot.get("warbands", []):
		if army.get("side") == _view_side() and (include_reserve or not army.get("reserve", false)): result.append(army)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("number", 0)) < int(b.get("number", 0)) if int(a.get("number", 0)) != int(b.get("number", 0)) else str(a.get("id", "")) < str(b.get("id", "")))
	return result

func _army(id: String) -> Dictionary:
	for army: Dictionary in _snapshot.get("warbands", []):
		if str(army.get("id")) == id: return army
	return {}

func _soldier(id: String) -> Dictionary:
	for soldier: Dictionary in _snapshot.get("soldiers", []):
		if str(soldier.get("id")) == id: return soldier
	return {}

func _hero(unit_id: String) -> Dictionary:
	for hero: Dictionary in _snapshot.get("heroes", {}).get("officers", []):
		if str(hero.get("unit_id", hero.get("member_id", ""))) == unit_id: return hero
	return {}

func _friendly_hero() -> Dictionary:
	var selected := _hero(_selected_unit_id)
	if selected.get("side") == _view_side(): return selected
	for hero: Dictionary in _snapshot.get("heroes", {}).get("officers", []):
		if hero.get("side") == _view_side(): return hero
	return {}

func _hero_for_archetype(archetype: String) -> Dictionary:
	for hero: Dictionary in _snapshot.get("heroes", {}).get("officers", []):
		if hero.get("side") == _view_side() and hero.get("hero_archetype", "COMMANDER") == archetype: return hero
	return {}

func _worker(id: String) -> Dictionary:
	for worker: Dictionary in _snapshot.get("workers", []):
		if str(worker.get("id")) == id: return worker
	return {}

func _select_tapped_worker(point: Vector2) -> bool:
	var nearest := ""
	var distance := 24.0 * 24.0
	for worker: Dictionary in _snapshot.get("workers", []):
		if worker.get("side") != _view_side() or int(worker.get("hp", 0)) <= 0: continue
		var candidate := _camera.world_to_screen(Vector2(worker.position)).distance_squared_to(point)
		if candidate < distance or (candidate == distance and not nearest.is_empty() and str(worker.id) < nearest):
			distance = candidate
			nearest = str(worker.id)
	if nearest.is_empty(): return false
	_select_worker(nearest)
	return true

func _select_tapped_visual_body(point: Vector2) -> bool:
	# Keep every original 24px soldier/worker foot tap ahead of this fallback.
	# Rendered body envelopes are screen-space, not new collision or command
	# ranges. Nearest foot then stable id resolves overlapping upper bodies.
	var nearest := ""
	var worker_selected := false
	var distance := INF
	for collection: String in ["soldiers", "workers"]:
		for unit: Dictionary in _snapshot.get(collection, []):
			if not _inspectable_actor_r9(unit): continue
			if collection == "soldiers" and (not unit.get("alive", false) or int(unit.get("hp", 0)) <= 0): continue
			if collection == "workers" and int(unit.get("hp", 0)) <= 0: continue
			var foot: Vector2 = _camera.world_to_screen(Vector2(unit.get("position", Vector2.ZERO)))
			var radius := maxf(float(unit.get("radius", 12)) * float(_camera.get_scale()), 3)
			if frontier_3d_enabled or heroic_2d_enabled:
				if _canvas == null: continue
				if not _canvas.visual_body_contains(str(unit.get("id","")),"unit",point): continue
			else:
				var body: Rect2 = PixelClass.unit_visual_bounds(unit, radius)
				if not Rect2(foot + body.position, body.size).has_point(point): continue
			var candidate := foot.distance_squared_to(point)
			var id := str(unit.get("id", ""))
			if candidate < distance or (candidate == distance and id < nearest):
				distance = candidate
				nearest = id
				worker_selected = collection == "workers"
	if nearest.is_empty(): return false
	if worker_selected: _select_worker(nearest)
	else: _select_unit(nearest)
	return true

func _inspectable_actor_r9(unit: Dictionary) -> bool:
	return ActorVisibilityR9.living(unit) and ActorVisibilityR9.visible_to(unit,_view_side())

func _selected_unit_owned_r9() -> bool:
	var unit := _soldier(_selected_unit_id)
	return not unit.is_empty() and unit.get("side")==_view_side() and _inspectable_actor_r9(unit)

func _select_worker(id: String) -> void:
	_selected_source_id = ""
	_clear_direct_input()
	_selected_worker_id = id
	_selected_unit_id = ""
	_selected_warband_id = ""
	_selected_site_id = ""
	_selected_building_id = ""
	_audio.record_ui("SELECT", id)
	_command_feedback.select("WORKER", id, _snapshot)
	_build_context()
	_refresh()

func _open_selected_info() -> void:
	_refresh_actor_inspector()
	if _selected_source_id.is_empty() and _selected_worker_id.is_empty() and _selected_unit_id.is_empty():return
	if not _selected_source_id.is_empty():
		_open_panel("source")
		return
	var unit := _soldier(_selected_unit_id)
	_info_unit_id = _selected_worker_id if not _selected_worker_id.is_empty() else _selected_unit_id
	_info_type = "worker" if not _selected_worker_id.is_empty() else str(unit.get("unit_type", "hinge_guard"))
	_info_archetype = str(unit.get("hero_archetype", "COMMANDER"))
	_open_panel("info")

func _open_roster() -> void:
	_info_type = "hero"
	_info_archetype = str(_friendly_hero().get("hero_archetype", "COMMANDER"))
	_info_unit_id = str(_friendly_hero().get("unit_id", ""))
	_open_panel("info")

func _base_unit_stats(type: String, archetype: String = "COMMANDER") -> Dictionary:
	if type == "hero": return HeroCatalog.profile(archetype).get("stats", {})
	return _snapshot.get("catalog", {}).get("unit_base_stats", {}).get(type, {})

func _unit_trait(type: String, archetype: String = "COMMANDER") -> String:
	var recipe: Dictionary = _snapshot.get("catalog", {}).get("units", {}).get(type, {})
	if type == "hero":
		var hero := HeroCatalog.profile(archetype)
		return str(hero.get("description", "")) + "\n" + _combat_type_text(hero.get("stats", {})) + "\n" + _normal_attack_permission(hero.get("attack_layers", [])) + "技能目标以各技能说明为准。"
	if type == "worker": return "自动采粮、采矿、搬运与施工；只在经营界面统一分派。有限资源站耗尽后自动停工。\n近敌会用短柄工具自动自卫，不追击、不接受逐工人军事操作；经济岗位仍优先统一调配。\n" + _normal_attack_permission(recipe.get("attack_layers", [])) + "\n" + _combat_type_text(_base_unit_stats(type))
	var stats := _base_unit_stats(type)
	var result := str(recipe.get("role_brief",_unit_role(type)))
	result += "\n优势："+"；".join(recipe.get("strengths",[]))+"\n弱点："+"；".join(recipe.get("weaknesses",[]))
	result += "\n" + _combat_type_text(stats)
	if not str(stats.get("trait_description", "")).is_empty(): result += "\n%s：%s" % [str(stats.get("trait_name", "特性")), str(stats.trait_description)]
	result += "\n" + _normal_attack_permission(stats.get("attack_layers", recipe.get("attack_layers", [])))
	if stats.get("movement_layer", recipe.get("movement_layer", "GROUND")) == "AIR": result += "\n空中单位：跨越地面障碍，但不参与占领。"
	if int(stats.get("splash_radius", 0)) > 0: result += "\n普攻溅射：半径%d，对周围地面敌人额外造成%d伤害。" % [int(stats.splash_radius), int(stats.get("splash_damage", 0))]
	if int(stats.get("heal", 0)) > 0: result += "\n自动治疗：范围%d，每%.1f秒最多治疗%d名友军，每名恢复%d生命，消耗%d法力。" % [int(stats.get("heal_range", 0)), float(stats.get("heal_cooldown_ticks", 0)) * 0.05,int(stats.get("heal_max_targets",1)),int(stats.heal),int(stats.get("heal_mana_cost",0))]
	if "MACHINE" in stats.get("heal_target_tags", []): result += "\n维修仅对机械友军生效。"
	return result

func _combat_type_text(stats: Dictionary) -> String:
	var armor_type := DamageRules.armor_for(stats)
	var attack_type := str(stats.get("attack_type", "EDGE"))
	var result := "防护：" + DamageRules.armor_label(armor_type)
	if int(stats.get("damage", 0)) > 0: result = "%s攻击 · %s" % [DamageRules.attack_label(attack_type), DamageRules.armor_label(armor_type)]
	if armor_type == "SACRED":
		result += "\n眩晕、定身和减速的基础持续时间为70%，再计算控制抗性。"
	else:
		var threats: Array[String] = []
		for attack: String in DamageRules.ATTACKS:
			var percent := DamageRules.multiplier(attack,armor_type)
			if percent > 100: threats.append("%s%d%%" % [DamageRules.attack_label(attack),percent])
		if not threats.is_empty(): result += "\n防护弱点：" + "、".join(threats) + "。"
	result += "\n悬浮攻击或护甲图标可查看各类型伤害倍率。"
	return result

func _healing_availability(skill: Dictionary, unit: Dictionary) -> String:
	if skill.get("effect") != "HEAL" or int(unit.get("hp", 0)) < int(unit.get("max_hp", 1)): return "就绪"
	return "自身满血；可恢复附近受伤友军" if int(skill.get("ally_heal", 0)) > 0 else "满血 · 暂无恢复需要"

func _normal_attack_permission(layers: Array) -> String:
	if "GROUND" in layers and "AIR" in layers: return "普通攻击：地面、空中。"
	if "GROUND" in layers: return "普通攻击：仅地面（不能攻击空中）。"
	if "AIR" in layers: return "普通攻击：仅空中（不能攻击地面）。"
	return "不进行普通攻击。"

func _unit_brief(type: String, archetype: String = "COMMANDER") -> String:
	var stats := _base_unit_stats(type, archetype)
	var role: String = str(HeroCatalog.profile(archetype).get("role", "")) if type == "hero" else _unit_role(type)
	return "%s · 生命%d  攻%d  甲%d  射程%d" % [role, int(stats.get("max_hp", 0)), int(stats.get("damage", 0)), int(stats.get("armor", 0)), int(stats.get("attack_range", 0))]

func _attribute_facts(stats: Dictionary, current: bool = false, labels: bool = false) -> Array[Dictionary]:
	var hp := "%d/%d" % [int(stats.get("hp", 0)), int(stats.get("max_hp", 0))] if current else str(stats.get("max_hp", 0))
	var result: Array[Dictionary] = []
	var armor := float(stats.get("armor",0))
	var armor_caption := "%s (剩余%.1f%%)" % [armor,DamageRules.armor_factor(armor)*100.0]
	for entry: Array in [["health", "生命", hp], ["sword", "攻击", str(stats.get("damage", 0))], ["armor", "防御", armor_caption], ["range", "射程", str(stats.get("attack_range", 0))]]:
		var fact := {"symbol":str(entry[0]), "caption":str(entry[1]) + (" · 当前" if current else " · 基础") if labels else str(entry[2]), "property":str(entry[1]), "observed":bool(current)}
		if labels: fact["value"] = str(entry[2])
		if entry[0] == "health" and current: fact["ratio"] = float(stats.get("hp", 0)) / maxi(int(stats.get("max_hp", 1)), 1)
		fact["inspection_id"] = str(entry[0])
		fact["help_text"] = "%s：%s%s" % [str(entry[1]), str(entry[2]), "（当前）" if current else "（基础）"]
		if entry[0] == "sword":
			fact["help_text"]+="\n攻击间隔%.2f秒；当前攻速加成%s%%。"%[float(stats.get("attack_cooldown_ticks",0))/20.0,float(stats.get("attack_speed_percent",0))]
			fact["help_text"] += "\n" + DamageRules.attack_summary(str(stats.get("attack_type", "EDGE"))) + "\n百分比为对目标造成的伤害，越高越有效。"
			if int(stats.get("damage", 0)) <= 0: fact["help_text"] += "\n此单位没有普通攻击。"
		elif entry[0] == "armor":
			fact["help_text"]+="\n额外魔法抗性%d%%，只在奥术伤害的类型和数值护甲结算后生效。"%int(stats.get("magic_resist_percent",0))
			fact["armor_number"] = armor
			fact["armor_remaining"] = "(剩余%.1f%%)" % (DamageRules.armor_factor(armor)*100.0)
			fact["help_text"] += "\n括号是数值护甲这一步的伤害剩余，不含护甲类型；负护甲可能超过100%。\n" + DamageRules.armor_summary(DamageRules.armor_for(stats)) + "\n" + DamageRules.numeric_armor_summary(armor) + "\n百分比为承受伤害，越低越耐打。"
		elif entry[0] == "health": fact["help_text"] += "\n生命降至0时倒下。法力%d/%d。"%[int(stats.get("mana",stats.get("max_mana",0))),int(stats.get("max_mana",0))]
		elif entry[0] == "range": fact["help_text"] += "\n普通攻击射程。移动速度%d/秒，移速加成%d%%；技能范围单独计算。"%[int(stats.get("speed",0))*20,int(stats.get("move_speed_percent",0))]
		if current and str(entry[0]) in ["sword","armor","range"]:
			var attribute_id: String = {"sword":"damage","armor":"armor","range":"range"}[str(entry[0])]
			var effective: float = float(stats.get({"damage":"damage","armor":"armor","range":"attack_range"}[attribute_id],0))
			var split: Dictionary = AttributeBreakdownM75.value(stats,attribute_id,effective)
			if labels: fact["value"] = str(split.value)
			else: fact["caption"] = str(split.compact_value)
			if entry[0]=="armor": fact["armor_number"] = str(split.compact_value)
			fact["help_text"] += "\n"+str(split.description)
		result.append(fact)
	return result

func _information_panel() -> void:
	var archetypes := _hero_archetypes()
	if _info_archetype not in archetypes and not archetypes.is_empty(): _info_archetype = archetypes[0]
	if _info_type not in _unit_types(): _info_type = _unit_types()[1]
	var types := _option("InformationUnitType", Vector2(0, 0), Vector2(360, 44))
	for type: String in _unit_types(): _add_option(types, _unit_name(type), type)
	_choose_option(types, _info_type)
	types.item_selected.connect(func(index: int): _info_type = str(types.get_item_metadata(index)); _info_unit_id = ""; _refresh_information())
	var heroes := _option("InformationHeroType", Vector2(395, 0), Vector2(360, 44))
	for archetype: String in _hero_archetypes():
		var profile := HeroCatalog.profile(archetype)
		_add_option(heroes, "%s · %s" % [profile.name, profile.role], archetype)
	_choose_option(heroes, _info_archetype)
	heroes.item_selected.connect(func(index: int): _info_archetype = str(heroes.get_item_metadata(index)); _info_unit_id = str(_hero_for_archetype(_info_archetype).get("unit_id", "")); _refresh_information())
	var stats := _panel_label("", Vector2(0, 54), 19)
	stats.name = "InformationStats"
	stats.size = Vector2(770, 54)
	stats.hide()
	_fact_view("InformationAttributeIcons", Vector2(0, 54), Vector2(770, 54))
	_cost_view("InformationCostIcons", Vector2(0, 112), Vector2(300, 36), {}, 1)
	var production := _panel_label("", Vector2(320, 118), 16)
	production.name = "InformationProduction"
	production.size = Vector2(430, 32)
	_fact_view("InformationWorkerCargo", Vector2(540, 112), Vector2(210, 36))
	var scroll := ScrollContainer.new()
	scroll.name = "InformationScroll"
	scroll.position = Vector2(0, 154)
	scroll.size = Vector2(780, 189)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel_content.add_child(scroll)
	var explanation := RichTextLabel.new()
	explanation.name = "InformationDetails"
	explanation.fit_content = true
	explanation.custom_minimum_size = Vector2(746, 189)
	explanation.add_theme_font_size_override("normal_font_size", 19)
	explanation.add_theme_color_override("default_color", Color("e1e5ce"))
	explanation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(explanation)
	var select := _button("选取本类型英雄", "InformationSelectHero", Vector2(360, 48))
	select.position = Vector2(0, 357)
	select.pressed.connect(_select_information_hero)
	_panel_content.add_child(select)
	var recruit := _button("招募 / 召回本类型", "InformationRecruitHero", Vector2(360, 48))
	recruit.position = Vector2(395, 357)
	recruit.pressed.connect(_recruit_information_hero)
	_panel_content.add_child(recruit)
	_refresh_information()

func _select_information_hero() -> void:
	var hero := _hero_for_archetype(_info_archetype)
	if hero.is_empty(): return
	_close_panel()
	_select_unit(str(hero.unit_id))
	if hero.get("alive", false): _camera.center_on(Vector2(hero.position))
	_refresh()

func _recruit_information_hero() -> void:
	var reason := _hero_recruitment_block_reason()
	if not reason.is_empty():
		_set_feedback(reason, 8)
		return
	_recruit_archetype = _info_archetype
	_recruit_unit_type = "hero"
	for building: Dictionary in _recruit_buildings():
		if building.get("building_type") == "ALTAR":
			_recruit_building_id = str(building.id)
			_open_panel("recruit")
			return
	_open_panel("build")
	_set_feedback("先在资源根据地祭庭空位确认建造；自动完工后选择此类型招募。" if OutpostSlotUI.enabled(_snapshot) else "先建长官祭庭并分派建筑工；完工后选择此类型招募。", 8)

func _handbook_skill_status(skill: Dictionary, unit: Dictionary, hero: Dictionary) -> String:
	# The handbook describes the same detached learning/castability facts as
	# the skill controls. A passive is never an active spell that is "ready".
	if hero.is_empty() or unit.is_empty(): return "未招募"
	if _snapshot.get("outcome", "ONGOING") != "ONGOING": return "战斗已结束"
	if _snapshot.get("phase") != "BATTLE": return "筹备期不可施放"
	if int(skill.get("level", 0)) <= 0: return "未学习"
	if not unit.get("alive", false) or int(unit.get("hp", 0)) <= 0:
		return "倒下 · 被动失效" if skill.get("passive", false) else "倒下不可施放"
	# Live passive auras/armor persist while stunned; only death disables them.
	if skill.get("passive", false): return "被动 · 自动生效"
	if int(unit.get("stun_until_tick", 0)) > int(_snapshot.get("tick", 0)): return "眩晕中"
	var cooldown := int(skill.get("cooldown_ticks", 0))
	if cooldown > 0: return "冷却%.1f秒" % (cooldown * float(_snapshot.get("tick_ms", 50)) / 1000.0)
	if int(hero.get("mana", 0)) < int(skill.get("mana_cost", 0)): return "蓝量不足"
	if not skill.get("can_cast", false): return "当前不可施放"
	return _healing_availability(skill, unit)

func _refresh_information() -> void:
	var label := _panel_content.find_child("InformationStats", true, false) as Label
	var detail := _panel_content.find_child("InformationDetails", true, false) as RichTextLabel
	if label == null or detail == null: return
	var hero_option := _panel_content.find_child("InformationHeroType", true, false) as OptionButton
	hero_option.visible = _info_type == "hero"
	var select := _panel_content.find_child("InformationSelectHero", true, false) as Button
	var recruit := _panel_content.find_child("InformationRecruitHero", true, false) as Button
	select.visible = _info_type == "hero"
	recruit.visible = _info_type == "hero"
	var recall_reason := _hero_recruitment_block_reason()
	recruit.disabled = not recall_reason.is_empty()
	recruit.tooltip_text = recall_reason if not recall_reason.is_empty() else "查看此类型的招募／召回条件；没有长官祭庭时打开建筑目录。"
	var record := _hero_for_archetype(_info_archetype)
	select.disabled = record.is_empty() or not record.get("alive", false)
	select.text = "选取 · " + str(record.get("name", "尚未招募")) + (" · 倒下" if not record.is_empty() and not record.get("alive", false) else "")
	var base := _base_unit_stats(_info_type, _info_archetype)
	var current := _worker(_info_unit_id) if _info_type == "worker" else _soldier(_info_unit_id)
	if _info_type == "hero":
		var officer := _hero_for_archetype(_info_archetype)
		if current.is_empty(): current = _soldier(str(officer.get("unit_id", "")))
	if not current.is_empty() and not _inspectable_actor_r9(current):current={}
	var recipe := _recruit_recipe(_info_type, _info_archetype)
	var cost := _panel_content.find_child("InformationCostIcons", true, false) as Control
	cost.set_meta("cost", recipe.get("cost", {}).duplicate(true))
	cost.set_meta("population", int(recipe.get("population", 1)))
	var production := _panel_content.find_child("InformationProduction", true, false) as Label
	production.text = "生产%.1f秒 · %s" % [float(recipe.get("duration", 0)) * 0.05, _building_display_name(str(recipe.get("building_type","")),"",str(recipe.get("faction_id","")))]
	if _info_type == "hero":
		var quote := _hero_quote(_info_archetype)
		production.text = "%s · %.1f秒" % [_hero_quote_action(quote), int(quote.get("duration_ticks", 0)) * 0.05]
		production.tooltip_text = _hero_quote_summary(quote) + "\n" + _hero_quote_block_reason(quote)
		production.set_meta("hero_quote", quote.duplicate(true))
		recruit.text = "复活本类型英雄" if quote.get("mode") == "REVIVE" else _hero_quote_action(quote)
		recruit.tooltip_text = (recall_reason + "\n" if not recall_reason.is_empty() else "") + _hero_quote_summary(quote) + "\n前往祭庭招募或复活。"
		if not record.is_empty() and bool(record.get("alive",false)):
			cost.set_meta("cost",{})
			production.text = "已在阵中 · %d级" % int(record.get("level",1))
			production.tooltip_text = "该英雄正在战场上，可点击“选取”定位英雄。"
			recruit.text = "已在阵中"
			recruit.disabled = true
			recruit.tooltip_text = "该英雄正在战场上，点击左侧“选取”定位英雄。"
	var cargo := _panel_content.find_child("InformationWorkerCargo", true, false) as Control
	cargo.visible = _info_type == "worker"
	if cargo.visible: cargo.refresh([{"symbol":"food" if current.get("cargo_type") == "FOOD" else "material" if current.get("cargo_type") == "MATERIAL" else "essence" if current.get("cargo_type") == "ESSENCE" else "worker", "caption":"携带", "value":int(current.get("cargo_amount", 0))}])
	label.text = "基础：生命%d  攻击%d  护甲%d  射程%d  移速%d/秒  人口%d\n%s" % [int(base.get("max_hp", 0)), int(base.get("damage", 0)), int(base.get("armor", 0)), int(base.get("attack_range", 0)), int(base.get("speed", 0))*20, int(recipe.get("population", 1)), "当前：生命%d/%d  攻击%d  护甲%d  射程%d  移速%d/秒" % [int(current.get("hp", 0)), int(current.get("max_hp", 0)), int(current.get("damage", 0)), int(current.get("armor", 0)), int(current.get("attack_range", 0)), int(current.get("speed", base.get("speed", 0)))*20] if not current.is_empty() else "未招募 · 显示基础属性"]
	label.set_meta("base_stats", base.duplicate(true))
	label.set_meta("current_stats", current.duplicate(true))
	var attributes := _panel_content.find_child("InformationAttributeIcons", true, false) as Control
	if attributes != null:
		attributes.refresh(_attribute_facts(current if not current.is_empty() else base, not current.is_empty(), true))
		attributes.tooltip_text = label.text + "\n分别悬浮或长按攻击／护甲格查看对应倍率。"
		attributes.set_meta("base_stats", base.duplicate(true))
		attributes.set_meta("current_stats", current.duplicate(true))
	var text: String = _unit_trait(_info_type, _info_archetype) + "\n普通攻击间隔：%.2f秒。\n" % (float(base.get("attack_cooldown_ticks", 0)) * 0.05) if _info_type != "worker" else _unit_trait(_info_type) + "\n当前分工：" + str(ROLE_NAMES.get(str(current.get("role", "RESERVE")), "待命")) + "。\n"
	if _info_type == "worker":
		text += "实际状态：%s；携带%d；资源站%s；施工项目%s。\n" % [{"RESERVE":"待命", "TRAVEL_TO_SOURCE":"前往采集", "GATHERING":"采集", "TRAVEL_TO_DEPOT":"运回营所", "TRAVEL_TO_CONSTRUCTION":"前往工地", "CONSTRUCTING":"施工", "WAITING_BUILDING":"等待蓝图", "WAITING_MINE":"等待可用矿点", "WAITING_DEPOT":"等待营所"}.get(str(current.get("state", "")), "未选取实际工人"), int(current.get("cargo_amount", 0)), str(current.get("site_id", "")), str(current.get("building_id", ""))]
	if _info_type == "hero":
		var actual := _hero(str(current.get("id", "")))
		var mana_summary := "蓝量%d/%d" % [int(actual.get("mana", 0)), int(actual.get("max_mana", 0))] if not actual.is_empty() else "尚未招募 · 基础蓝量%d" % int(base.get("max_mana", 0))
		text = _unit_trait(_info_type,_info_archetype) + "\n" + mana_summary + "\n\n技能\n"
		for skill: Dictionary in HeroCatalog.skills_for(_info_archetype):
			for published: Dictionary in actual.get("skills", []):
				if published.get("id") == skill.id:
					skill = published
			text += "%s\n%s\n当前：%s\n\n" % [skill.name, skill.description, _handbook_skill_status(skill, current, actual)]
		text += ("\n英雄名册\n该英雄已在阵中。\n" if not record.is_empty() and bool(record.get("alive",false)) else "\n招募与复活\n" + _hero_quote_summary(_hero_quote(_info_archetype)) + "\n") + "整局最多3种英雄，阵亡仍占名额。阵亡后可在祭庭付费复活，保留等级、技能和现有行囊；已掉落装备不会返还。\n"
		if "SPELL_LENS" in actual.get("equipment", []): text += "星契透镜已装备：" + str(HeroItems.ITEMS.SPELL_LENS.description) + "\n"
	for effect: Dictionary in current.get("status_effects", []): text += "%s：剩余%.1f秒\n" % [{"STUN":"眩晕", "ROOT":"定身", "SLOW":"减速", "ARMOR_BREAK":"破甲", "BURN":"灼烧", "POISON":"中毒"}.get(str(effect.get("kind", effect.get("effect", effect.get("id", "")))), "状态"), int(effect.get("remaining_ticks", 0)) * 0.05]
	detail.text = text
	_refresh_cost_readouts()

func _preview_skill(direction: Vector2, slot_id: String) -> void:
	_skill_aim.clear()
	if direction.is_zero_approx(): return
	var hero := _hero(_selected_unit_id)
	var skills: Array = hero.get("skills", [])
	var slot := SKILLS.find(slot_id)
	if slot < 0 or slot >= skills.size(): return
	var skill: Dictionary = skills[slot]
	var origin := Vector2(_soldier(_selected_unit_id).get("position", Vector2.ZERO))
	_skill_aim = {"unit_id":_selected_unit_id, "skill_id":skill.id, "range":skill.get("range", 0), "radius":skill.get("radius", 0), "target_position":_bounded_point(origin + direction * float(skill.get("range", 0)) * 0.9)}
	_refresh_canvas()

func _refresh_troop_counts() -> void:
	var counts: Dictionary = {}
	var types:=_unit_types()
	var side:=_view_side()
	for type: String in types: counts[type] = 0
	for worker: Dictionary in _snapshot.get("workers", []):
		if worker.get("side") == side and int(worker.get("hp", 0)) > 0: counts.worker += 1
	for soldier: Dictionary in _snapshot.get("soldiers", []):
		var type := str(soldier.get("unit_type", ""))
		if soldier.get("side") == side and soldier.get("alive", false) and counts.has(type): counts[type] += 1
	var facts: Array[Dictionary] = []
	for type: String in types: facts.append({"symbol":_unit_icon(type), "caption":_unit_name(type), "value":int(counts[type]), "unit_type":type, "visuals":_roster_visuals(type)})
	_composition_facts = facts
	var military := 0
	for type: String in counts:
		if type not in ["worker", "hero"]: military += int(counts[type])
	var header_facts: Array[Dictionary] = [{"symbol":"army", "caption":"兵员", "value":military}, {"symbol":"hero", "caption":"英雄", "value":int(counts.get("hero", 0))}, {"symbol":"BASE", "caption":"级基地", "value":_base_tier()}]
	if not OutpostSlotUI.enabled(_snapshot): header_facts.push_front({"symbol":"worker", "caption":"工人", "value":int(counts.get("worker", 0))})
	_troop_counts.refresh(header_facts)
	var weights: Array[String] = []
	for type: String in types: weights.append("%s %d" % [_unit_name(type), int(_snapshot.get("catalog", {}).get("units", {}).get(type, {}).get("population", 1))])
	_troop_counts.tooltip_text = "存活人数（不含排队），不是人口权重。\n每名人口：" + " · ".join(weights) + ("\n观察模式：当前为" + Palette.side_label(_view_side()) + "，仅查看。" if _observing() else "")

func _composition_panel() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "ForceCompositionScroll"
	scroll.size = Vector2(780, 410)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_content.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "ForceCompositionRows"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	_refresh_composition()

func _refresh_composition() -> void:
	var list := _panel_content.find_child("ForceCompositionRows", true, false) as VBoxContainer
	if list == null or list.get_meta("facts", []) == _composition_facts: return
	list.set_meta("facts", _composition_facts.duplicate(true))
	_clear_children(list)
	for fact: Dictionary in _composition_facts:
		var row := FactReadoutClass.new()
		row.heroic_2d = heroic_2d_enabled
		row.name = "Composition_" + str(fact.unit_type)
		row.custom_minimum_size = Vector2(740, 62)
		list.add_child(row)
		var weight := int(_snapshot.get("catalog", {}).get("units", {}).get(fact.unit_type, {}).get("population", 1))
		row.refresh([fact, {"symbol":"population", "caption":"每名人口", "value":weight}])
		row.tooltip_text = "%s · 当前%d名。" % [str(fact.caption), int(fact.value)]
		if fact.unit_type == "hero":
			for visual: Dictionary in fact.visuals:
				row.tooltip_text += "\n" + str(HeroCatalog.profile(str(visual.get("hero_archetype", "COMMANDER"))).get("name", "英雄"))

func _roster_visuals(type: String, warband_id: String = "") -> Array[Dictionary]:
	var samples: Array = []
	var side:=_view_side()
	for unit: Dictionary in _snapshot.get("workers" if type == "worker" else "soldiers", []):
		if unit.get("side") != side or int(unit.get("hp", 0)) <= 0 or not bool(unit.get("alive", true)): continue
		if not warband_id.is_empty() and str(unit.get("warband_id", "")) != warband_id: continue
		if type != "worker" and str(unit.get("unit_type", "")) != type: continue
		samples.append(unit)
	var fallback := {"unit_type":type, "side":side, "faction_id":_faction_id()}
	if type == "hero":
		var archetypes := _hero_archetypes()
		fallback["hero_archetype"] = archetypes[0] if not archetypes.is_empty() else "COMMANDER"
	return RosterPreviewClass.visuals_for(type, samples, fallback)

func _refresh_hero_portrait() -> void:
	var heroes: Array[Dictionary] = []
	var signature := ""
	for hero: Dictionary in _snapshot.get("heroes", {}).get("officers", []):
		if hero.get("side") == _view_side():
			heroes.append(hero)
	if _primary_hero_id.is_empty() and not heroes.is_empty(): _primary_hero_id = str(heroes[0].get("unit_id", ""))
	# Retain dead named officers for paid recall without hiding a third living
	# commander. Names remain bound to identity, never to current slot index.
	heroes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("alive", false)) != bool(b.get("alive", false)): return bool(a.get("alive", false))
		return str(a.get("unit_id", "")) < str(b.get("unit_id", "")))
	for hero: Dictionary in heroes: signature += "%s:%s;" % [str(hero.get("unit_id", "")), str(hero.get("alive", false))]
	if signature != _hero_roster_signature:
		_hero_roster_signature = signature
		for card: Button in _hero_cards.get_children():
			var retained := false
			for hero: Dictionary in heroes:
				if str(hero.get("unit_id")) == str(card.get_meta("unit_id", "")): retained = true; break
			if not retained:
				_hero_cards.remove_child(card)
				card.queue_free()
		_hero_card = null
		for index: int in range(heroes.size()):
			var id := str(heroes[index].get("unit_id", ""))
			var node_name := "PersistentHeroPortrait" if id == _primary_hero_id else "HeroPortrait_" + id
			var card := _hero_cards.get_node_or_null(NodePath(node_name)) as Button
			if card == null:
				card = HeroCardClass.new()
				card.name = node_name
				card.pressed.connect(_hero_portrait_pressed.bind(id))
				_hero_cards.add_child(card)
			_hero_cards.move_child(card, index)
			if id == _primary_hero_id: _hero_card = card
	var recall_reason := _hero_recruitment_block_reason()
	var stock: Dictionary = _snapshot.get("economy", {}).get(_view_side(), {}).get("stock", {})
	var status_context := HeroStatusClass.prepare_borrowed_m76(_snapshot)
	_hero_status_context = status_context
	for index: int in range(heroes.size()):
		(_hero_cards.get_child(index) as Button).refresh(heroes[index], str(heroes[index].get("unit_id")) == _selected_unit_id, recall_reason, _hero_quote(str(heroes[index].get("hero_archetype", heroes[index].get("archetype", "COMMANDER")))), stock, HeroStatusClass.read(heroes[index], status_context))
		(_hero_cards.get_child(index) as Button).visible = not _backdrop.visible
	_hero_roster.visible = not heroes.is_empty() and not _backdrop.visible
	_layout_hero_roster()

func _hero_bag_fits() -> bool:
	return get_viewport_rect().size.y >= 760 and _hero_bag.position.y + 160 < _move_joystick.position.y - 10

func _layout_hero_feedback() -> void:
	if _feedback == null or _hero_roster == null: return
	var x := _hero_roster.position.x + _hero_roster.size.x + 16
	var right := _minimap.position.x - 12
	if is_instance_valid(_actor_inspector) and _actor_inspector.visible and not _actor_inspector.compact:
		right = minf(right,_actor_inspector.position.x-12)
	if _cancel_target_button.visible: right = minf(right,_cancel_target_button.position.x-8)
	_feedback.position = Vector2(x,86)
	_feedback.size = Vector2(maxf(right-x,80),64)

func _refresh_actor_inspector() -> void:
	if _actor_inspector == null: return
	var actor := _soldier(_selected_unit_id) if not _selected_unit_id.is_empty() else _worker(_selected_worker_id)
	if not actor.is_empty() and not _inspectable_actor_r9(actor):
		_selected_unit_id="";_selected_worker_id="";_clear_direct_input()
	var id := _selected_unit_id
	var collection := "soldiers"
	if id.is_empty(): id = _selected_worker_id; collection = "workers"
	if id.is_empty(): id = _selected_building_id; collection = "buildings"
	var facts: Dictionary = ActorInspectionReadout.read(_snapshot,id,collection,_hero_status_context) if not id.is_empty() else {}
	if not _selected_source_id.is_empty(): facts = SourceInspectionM71.read(_snapshot,_selected_source_id,_view_side())
	_actor_inspector.heroic_2d = heroic_2d_enabled
	_actor_inspector.refresh(facts)
	_layout_actor_inspector()
	_layout_hero_feedback()

func _layout_actor_inspector() -> void:
	if _actor_inspector == null or _minimap == null: return
	var left := 18.0+HeroCardClass.ROSTER_WIDTH+12.0
	var right := _minimap.position.x-12.0
	var available := right-left
	_actor_inspector.set_meta("fallback_to_information",available<208)
	if available<208:
		_actor_inspector.hide()
		return # Existing Information button remains the narrow-screen fallback.
	var compact := available<270
	var dimensions := Vector2(minf(296,available),168 if compact else 206)
	if _actor_inspector.facts.get("collection") == "resource_sources": dimensions.y = 160
	var y := 158.0 if compact else 88.0
	if y+dimensions.y>get_viewport_rect().size.y-314:
		_actor_inspector.set_meta("fallback_to_information",true)
		_actor_inspector.hide()
		return
	_actor_inspector.position = Vector2(right-dimensions.x,y)
	_actor_inspector.size = dimensions
	_actor_inspector.compact = compact
	_actor_inspector.visible = not _actor_inspector.facts.is_empty() and not _backdrop.visible and not _in_lobby()
	_actor_inspector.queue_redraw()

func _layout_hero_roster() -> void:
	if _hero_roster == null or _hero_cards == null: return
	var width:=HeroCardClass.ROSTER_WIDTH
	var y := 0.0
	# Stable identity order and identical expanded rows; selection is a highlight,
	# never a collapse/reorder of the other heroes' important combat state.
	for index: int in range(_hero_cards.get_child_count()):
		var card:=_hero_cards.get_child(index) as Button
		card.position=Vector2(0,y)
		card.size=Vector2(width,card.custom_minimum_size.y)
		y+=card.size.y+(4 if index+1<_hero_cards.get_child_count() else 0)
	_hero_cards.custom_minimum_size = Vector2(width,y)
	_hero_cards.size = Vector2(width,y)
	_hero_roster.size = Vector2(width,minf(y,maxf(HeroCardClass.ROSTER_HEIGHT,get_viewport_rect().size.y-313)))
	_hero_bag.position = Vector2(18,_hero_roster.position.y+_hero_roster.size.y+8)
	_hero_bag.visible = _inventory_button.visible and _hero_bag_fits()
	_layout_hero_feedback()

func _hero_recruitment_block_reason() -> String:
	# Selection/inspection is read-only; this gates only manual recruitment
	# navigation. Keep the real host command admission and live recall intact.
	if _snapshot.get("outcome", "ONGOING") != "ONGOING": return "战斗已结束，仅可查看英雄信息。"
	if _in_lobby(): return "对局尚未开始，仅可查看英雄信息。"
	if not _can_command(): return "观察模式（观战只读），仅可查看英雄信息。"
	return ""

func _hero_portrait_pressed(unit_id: String = "") -> void:
	var hero := _hero(unit_id) if not unit_id.is_empty() else _friendly_hero()
	if hero.is_empty(): return
	var id := str(hero.get("unit_id", ""))
	_select_unit(id)
	if hero.get("alive", false):
		_camera.center_on(Vector2(hero.get("position", Vector2.ZERO)))
		_refresh_canvas()
		_refresh_hero_portrait()
		return
	var reason := _hero_recruitment_block_reason()
	if not reason.is_empty():
		_open_selected_info()
		_set_feedback(reason, 8)
		return
	for building: Dictionary in _recruit_buildings():
		if building.get("building_type") == "ALTAR":
			_recruit_building_id = str(building["id"])
			_recruit_unit_type = "hero"
			_recruit_archetype = str(hero.get("hero_archetype", "COMMANDER"))
			_open_panel("recruit")
			_set_feedback("长官倒下：" + _hero_quote_summary(_hero_quote(_recruit_archetype)), 8)
			return
	_open_panel("build")
	_set_feedback(("长官倒下：在固定祭庭空位确认建造，自动完工后付费复活。" if OutpostSlotUI.enabled(_snapshot) else "长官倒下：先建祭庭并派建筑工，完工后付费复活。") + _hero_quote_summary(_hero_quote(str(hero.get("hero_archetype", "COMMANDER")))), 8)
	var altar := _panel_content.find_child("PlaceType_ALTAR", true, false) as Button
	if altar != null:
		altar.set_meta("selected", true)
		altar.queue_redraw()

func _fact_view(node_name: String, point: Vector2, dimensions: Vector2) -> Control:
	var view := FactReadoutClass.new()
	view.heroic_2d = heroic_2d_enabled
	view.name = node_name
	view.position = point
	view.size = dimensions
	_panel_content.add_child(view)
	return view

func _refresh_source_facts(view: Control, site_id: String) -> void:
	var facts: Array[Dictionary] = []
	var lines: Array[String] = []
	var resources: Array[String] = []
	for resource: String in EconomyCatalog.RESOURCE_KEYS: resources.append(resource)
	for resource: String in resources:
		var source: Dictionary = {}
		for candidate: Dictionary in _snapshot.get("resource_sources", []):
			if str(candidate.get("site_id", "")) == site_id and str(candidate.get("resource", candidate.get("kind", ""))) == resource:
				source = candidate; break
		var label := str(EconomyCatalog.RESOURCE_LABELS[resource])
		if source.is_empty() and resource == "ESSENCE": continue
		if source.is_empty():
			facts.append({"symbol":"gold", "caption":label + " · 无来源", "value":"—", "resource":resource, "site_id":site_id, "state":"UNAVAILABLE", "inactive":true})
			lines.append(label + "：该地点没有公开资源来源。")
			continue
		var remaining := int(source.get("remaining", source.get("remaining_amount", 0)))
		var initial := int(source.get("initial", source.get("initial_amount", 0)))
		var state := str(source.get("state", "UNSERVED"))
		var status := "已耗尽" if state in ["DEPLETED", "EXHAUSTED"] else "可采集" if state == "ACTIVE" and bool(source.get("active", false)) else "无人经营"
		var workers := int(source.get("assigned_workers",0))
		var capacity := int(source.get("worker_capacity",EconomyCatalog.worker_capacity(resource)))
		var caption := "%s · %s" % [label, "自动产出" if bool(source.get("active", false)) else "未启用"] if OutpostSlotUI.enabled(_snapshot) else "%s · 工人%d/%d" % [label,workers,capacity]
		facts.append({"symbol":"gold", "caption":caption, "value":"%d / %d" % [remaining, initial], "ratio":float(remaining) / maxi(initial, 1), "resource":resource, "source_id":str(source.get("id", "")), "site_id":site_id, "remaining":remaining, "initial":initial, "state":state, "active":bool(source.get("active", false)), "inactive":not bool(source.get("active", false))})
		lines.append(str(SourceInspectionM71.read(_snapshot,str(source.get("id","")),_view_side()).get("description","")))
	view.refresh(facts)
	view.tooltip_text = "\n".join(lines) + ("\n可采集表示己方占领且附近建成灵髓矿场；还需独立选点、分派工人。耗尽不会再生。" if "ESSENCE" in resources else "\n可采集表示已有归属和附近完工营所，不表示已经分派了工人；无人经营或耗尽不会产出资源。")
	if OutpostSlotUI.enabled(_snapshot): view.tooltip_text = "完整占领并建成指定的基地 / 采矿场后自动产出；无需分派工人。失去据点、建筑被毁或资源耗尽都会停止产出。"

func _refresh_management_facts() -> void:
	_refresh_inventory_buttons()
	var computer_fact := _panel_content.find_child("ComputerControllerFacts", true, false) as Label
	if computer_fact != null:
		var computer: Dictionary = _snapshot.get("computer", {})
		var status := str(computer.get("status", computer.get("phase", "DORMANT")))
		computer_fact.text = "%s电脑 · %s" % [_ai_difficulty_label(), _computer_policy_caption(status)]
		if _snapshot.get("outcome", "ONGOING") != "ONGOING": computer_fact.text = "%s电脑 · 已结束" % _ai_difficulty_label()
		elif _command_desk_paused(): computer_fact.text = "%s电脑 · 暂停" % _ai_difficulty_label()
	var economy: Dictionary = _snapshot.get("economy", {}).get(_view_side(), {})
	var work_sources := _panel_content.find_child("WorkResourceSourceFacts", true, false) as Control
	if work_sources != null:
		var site_id := str(economy.get("work_site_id", ""))
		_refresh_work_sites()
		_refresh_source_facts(work_sources, site_id)
	var economy_facts := _panel_content.find_child("EconomyRosterFacts", true, false) as Control
	if economy_facts != null:
		var workers := 0
		for worker: Dictionary in _snapshot.get("workers", []):
			if worker.get("side") == _view_side() and int(worker.get("hp", 0)) > 0: workers += 1
		economy_facts.refresh([{"symbol":"worker", "caption":"工人总数", "value":workers}, {"symbol":"population", "caption":"待命", "value":int(economy.get("targets", {}).get("RESERVE", 0))}])
	for roster: Array in [["SourceRosterFacts", _source_army_id], ["TargetRosterFacts", _transfer_army_id]]:
		var source := _panel_content.find_child(str(roster[0]), true, false) as Control
		if source == null: continue
		var counts := {}
		for soldier: Dictionary in _snapshot.get("soldiers", []):
			if soldier.get("side") == _view_side() and soldier.get("alive", false) and soldier.get("warband_id") == roster[1]:
				var type := str(soldier.get("unit_type", ""))
				counts[type] = int(counts.get(type, 0)) + 1
		var values: Array[Dictionary] = []
		for type: String in _unit_types():
			if type != "worker" and int(counts.get(type, 0)) > 0: values.append({"symbol":_unit_icon(type), "caption":_unit_name(type).left(2), "value":int(counts[type]), "unit_type":type, "visuals":_roster_visuals(type, str(roster[1]))})
		source.refresh(values)
	var inventory_facts := _panel_content.find_child("HeroInventoryFacts", true, false) as Control
	if inventory_facts != null:
		var hero := _hero(_selected_unit_id)
		var inventory: Dictionary = hero.get("inventory", {})
		inventory_facts.refresh([{"symbol":"sword", "caption":"铁刃持有", "value":int(inventory.get("IRON_BLADE", 0)), "equipped":"IRON_BLADE" in hero.get("equipment", [])}, {"symbol":"armor", "caption":"护铠持有", "value":int(inventory.get("WARD_MAIL", 0)), "equipped":"WARD_MAIL" in hero.get("equipment", [])}, {"symbol":"potion", "caption":"药水", "value":int(inventory.get("POTION", 0))}])
		for item: String in ["IRON_BLADE", "WARD_MAIL", "POTION"]:
			var button := _panel_content.find_child("Item" + item, true, false) as Button
			if button != null:
				button.disabled = not hero.get("alive", false) or int(inventory.get(item, 0)) <= 0 or (item != "POTION" and item in hero.get("equipment", [])) or (item == "POTION" and int(hero.get("hp", 0)) >= int(hero.get("max_hp", 1)))
				button.set_meta("selected", item in hero.get("equipment", []))
				button.caption = {"IRON_BLADE":"铁刃", "WARD_MAIL":"护铠", "POTION":"药水"}[item] + " ×" + str(inventory.get(item, 0))
				button.queue_redraw()

func _building(id: String) -> Dictionary:
	for building: Dictionary in _snapshot.get("buildings", []):
		if str(building.get("id")) == id: return building
	return {}

func _progression() -> Dictionary:
	return _snapshot.get("progression", {}).get(_view_side(), {})

func _base_tier() -> int:
	return int(_progression().get("base_tier", 1))

func _recipe(id: String, building: bool) -> String:
	if id == "hero" and not building: return _hero_quote_summary(_hero_quote(_recruit_archetype))
	var catalog: Dictionary = _building_recipes() if building else _snapshot.get("catalog", {}).get("units", {})
	var entry: Dictionary = catalog.get(id, {})
	var cost: Dictionary = entry.get("cost", {})
	if cost.is_empty(): return "费用以主机校验为准"
	return "金币%d%s" % [int(cost.get("MATERIAL", 0)), "  人口%d" % int(entry.get("population", 1)) if not building else ""]

func _cost_view(node_name: String, point: Vector2, dimensions: Vector2, cost: Dictionary, population: int = -1) -> Control:
	var view := CostReadoutClass.new()
	view.name = node_name
	view.position = point
	view.size = dimensions
	view.set_meta("cost", cost.duplicate(true))
	view.set_meta("population", population)
	_panel_content.add_child(view)
	view.refresh(cost, _snapshot.get("economy", {}).get(_view_side(), {}).get("stock", {}), population)
	return view

func _refresh_cost_readouts() -> void:
	var stock: Dictionary = _snapshot.get("economy", {}).get(_view_side(), {}).get("stock", {})
	for child: Node in _panel_content.find_children("*", "", true, false):
		if child is CostReadoutClass and child.has_meta("cost"):
			child.refresh(child.get_meta("cost", {}), stock, int(child.get_meta("population", -1)))

func _queue_view(node_name: String, point: Vector2, dimensions: Vector2) -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = node_name + "Scroll"
	scroll.position = point
	scroll.size = dimensions
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_content.add_child(scroll)
	var view := QueueReadoutClass.new()
	view.name = node_name
	scroll.add_child(view)
	return view

func _queue_state(value: String) -> String:
	return {"WAITING":"等待", "RUNNING":"生产", "BLOCKED_CAPACITY":"人口不足", "BLOCKED_OUTLET":"附近堵塞", "BASE_UPGRADING":"基地升级中", "BLUEPRINT":"待建", "CONSTRUCTING":"施工", "WAITING_BUILDERS":"等待工人"}.get(value, value)

func _dismiss_context_help(cancel_contacts: bool = true) -> void:
	if _context_help != null: _context_help.dismiss(cancel_contacts)
	if cancel_contacts: _gesture.suppress()

func _gate_new_help_control(node: Node) -> void:
	if is_instance_valid(_ui) and _ui.is_ancestor_of(node): NativeTooltipGate.attach_native_control(node)

func _replay_help_events(events: Array) -> void:
	# Re-enter native GUI handling, not pressed.emit(): disabled, toggle,
	# dropdown and ScrollContainer semantics remain owned by their controls.
	if _context_help == null: return
	_context_help.replaying = true
	for event: InputEvent in events: get_viewport().push_input(event, true)
	_context_help.replaying = false

func _help_target(point: Vector2) -> Dictionary:
	if _ui == null or not get_viewport_rect().has_point(point): return {}
	# The management backdrop owns this entire input layer, including blank
	# space. Its lack of help text must not expose covered toolbar controls.
	var help_root: Control = _backdrop if is_instance_valid(_backdrop) and _backdrop.is_visible_in_tree() else _ui
	var control := _help_control_at(help_root, point)
	if control != null:
		if control is ActorInspectorClass:
			return _actor_help_target(control,control.inspection_at(control.get_global_transform_with_canvas().affine_inverse()*point))
		if control.has_meta("hero_inspection_card"):
			var card: Control = control.get_meta("hero_inspection_card")
			if is_instance_valid(card): return _hero_help_target(card, card.inspection_for(str(control.get_meta("hero_cell_key",""))))
		if control is HeroCardClass:
			var cell: Dictionary = control.inspection_at(control.get_global_transform_with_canvas().affine_inverse() * point)
			if not cell.is_empty(): return _hero_help_target(control,cell)
		if control is QueueReadoutClass and not control.entries.is_empty():
			return _queue_help_target(control, control.inspection_at(control.get_global_transform_with_canvas().affine_inverse() * point))
		if control is FactReadoutClass:
			var transform := control.get_global_transform_with_canvas()
			var cell: Dictionary = control.inspection_at(transform.affine_inverse() * point)
			if not cell.is_empty():
				return {"key":"ui:" + str(control.get_path()) + ":fact:" + str(cell.id), "kind":"ui", "text":str(cell.text), "rect":transform * Rect2(cell.rect), "control":control, "immediate":false, "passive":true}
		var explanation := _help_control_text(control)
		if not explanation.is_empty():
			return {"key":"ui:" + str(control.get_path()), "kind":"ui", "text":explanation, "rect":control.get_global_rect(), "control":control, "immediate":control == _minimap or control == _move_joystick or control is Range, "passive":not control is BaseButton and not control is JoystickClass}
	return _help_world_target(point)

func _actor_help_target(control: Control,cell: Dictionary) -> Dictionary:
	var subject_id := str(control.facts.get("id",""))
	if subject_id.is_empty(): return {}
	if cell.is_empty(): return {"key":"ui:"+str(control.get_path()),"kind":"ui","text":control.tooltip_text,"rect":control.get_global_rect(),"control":control,"immediate":false,"passive":true,"actor_id":subject_id}
	var target := _hero_help_target(control,cell)
	target["key"] = "ui:"+str(control.get_path())+":actor:"+str(cell.key)
	target["actor_id"] = subject_id
	return target

func _hero_help_target(control: Control, cell: Dictionary) -> Dictionary:
	if cell.is_empty(): return {}
	var entry := cell.duplicate(true)
	entry["id"] = str(cell.key)
	var target := _queue_help_target(control,entry)
	if target.is_empty(): return {}
	target["key"] = "ui:" + str(control.get_path()) + ":hero:" + str(cell.key)
	return target

func _queue_help_target(control: Control, cell: Dictionary) -> Dictionary:
	if cell.is_empty(): return {}
	var rect: Rect2 = control.get_global_transform_with_canvas() * Rect2(cell.rect)
	# Queue cells can slide beneath either edge of their ScrollContainer.
	# Keep the displayed anchor on its same ID, not its old index/pointer.
	rect = rect.intersection(get_viewport_rect())
	var ancestor: Node = control.get_parent()
	while ancestor != null and rect.has_area():
		if ancestor is Control and ancestor.clip_contents:
			var clip: Rect2 = ancestor.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, ancestor.size)
			rect = rect.intersection(clip)
		ancestor = ancestor.get_parent()
	if not rect.has_area(): return {}
	return {"key":"ui:" + str(control.get_path()) + ":entry:" + str(cell.id), "kind":"ui", "text":str(cell.text), "rect":rect, "control":control, "immediate":false, "passive":true}

func _refresh_help_target(target: Dictionary) -> Dictionary:
	# World inspection retains its existing stable-ID snapshot semantics. Only
	# live UI sources refresh here; no pointer hit-test may pick a new subject.
	if str(target.get("kind", "")) != "ui": return target
	var control: Variant = target.get("control")
	if not is_instance_valid(control) or not control is Control or not control.is_visible_in_tree(): return {}
	var key := "ui:" + str(control.get_path())
	var current := target.duplicate()
	if control is ActorInspectorClass and str(target.get("actor_id","")) != str(control.facts.get("id","")): return {}
	if control is ActorInspectorClass and str(target.get("key","")).begins_with(key+":actor:"):
		return _actor_help_target(control,control.inspection_for(str(target.key).trim_prefix(key+":actor:")))
	if control is HeroCardClass and str(target.get("key", "")).begins_with(key + ":hero:"):
		return _hero_help_target(control,control.inspection_for(str(target.key).trim_prefix(key + ":hero:")))
	if control is QueueReadoutClass and str(target.get("key", "")).begins_with(key + ":entry:"):
		return _queue_help_target(control, control.inspection_for(str(target.key).trim_prefix(key + ":entry:")))
	if control is FactReadoutClass and str(target.get("key", "")).begins_with(key + ":fact:"):
		var prefix := key + ":fact:"
		if not str(target.get("key", "")).begins_with(prefix): return {}
		var wanted := str(target.key).trim_prefix(prefix)
		var entries: Array = control.shown_entries()
		for index: int in range(entries.size()):
			var cell: Dictionary = control.inspection_at(control.cell_rect(index, entries.size()).get_center())
			if str(cell.get("id", "")) != wanted: continue
			current.text = str(cell.text)
			current.rect = control.get_global_transform_with_canvas() * Rect2(cell.rect)
			return current
		return {}
	if str(target.get("key", "")) != key: return {}
	current.text = _help_control_text(control)
	current.rect = control.get_global_rect()
	return current

func _help_target_valid(target: Dictionary) -> bool:
	if str(target.get("kind", "")) != "world": return true
	var key := str(target.get("key", ""))
	var prefix := key.get_slice(":", 0)
	var id := key.trim_prefix(prefix + ":")
	var collection: String = {"unit":"soldiers", "worker":"workers", "building":"buildings", "source":"resource_sources", "site":"sites", "slot":"building_slots", "loot":"neutral_loot", "camp":"neutral_camps"}.get(prefix, "")
	if collection.is_empty() or id.is_empty(): return false
	for subject: Dictionary in _snapshot.get(collection, []):
		if str(subject.get("id", "")) != id: continue
		if prefix in ["unit", "worker", "building"]:
			return int(subject.get("hp", 0)) > 0 and bool(subject.get("alive", true))
		if prefix == "loot": return subject.get("state") == "AVAILABLE"
		if prefix == "camp": return subject.get("state") == "GUARDED"
		if prefix == "slot": return not bool(subject.get("occupied", false)) and bool(subject.get("visible", true))
		return true
	return false

func _help_control_at(node: Node, point: Vector2) -> Control:
	if node is CanvasItem and not node.is_visible_in_tree(): return null
	if node is Control and node.clip_contents and not node.get_global_rect().has_point(point): return null
	# Reverse drawing order plus ancestor clipping prevents hints for cards
	# scrolled out of view or controls hidden behind a management surface.
	var children := node.get_children()
	children.reverse()
	for child: Node in children:
		var found := _help_control_at(child, point)
		if found != null: return found
	if not node is Control: return null
	var control := node as Control
	if not control.get_global_rect().has_point(point): return null
	if control is BaseButton or control is ActorInspectorClass or control is JoystickClass or control is QueueReadoutClass or not control.tooltip_text.is_empty() or control.has_meta("cost") or control.has_meta("facts"):
		return control
	return null

func _help_control_text(control: Control) -> String:
	var explanation := control.tooltip_text
	if control.has_method("detached_facts"):
		var facts: Dictionary = control.detached_facts()
		var type := str(facts.get("id", ""))
		if facts.get("kind") == "BUILDING":
			explanation = str(facts.get("label", type)) + "\n" + HelpDescriptions.building(type)
			explanation += "\n" + DamageRules.armor_summary("FORTIFIED")
			if type == "TOWER":
				var recipe: Dictionary=_building_recipes().get(type,{})
				explanation += "\n" + DamageRules.attack_summary(str(recipe.get("attack_type","PIERCE")))
				explanation += "\n"+str(recipe.get("counterplay",""))
		else:
			var archetype := str(facts.get("visual", {}).get("hero_archetype", _recruit_archetype))
			explanation = _help_unit_description(type, archetype)
			if type == "hero": explanation += "\n" + _hero_quote_summary(_hero_quote(archetype))
		explanation += "\n" + _help_cost(facts.get("cost", {}), int(facts.get("population", -1)))
		explanation += "\n需要%d级基地" % int(facts.get("required_tier", 1))
		var reason := str(facts.get("locked_reason", ""))
		explanation += "\n" + ("不可用：" + reason if not reason.is_empty() else "单击选择；具体命令仍需正常确认。")
	elif control.has_meta("unit_id") and control.has_meta("hero_archetype"):
		var id := str(control.get_meta("unit_id", ""))
		explanation = _help_hero_overview(id)
	elif control.has_meta("cost"):
		explanation = _help_cost(control.get_meta("cost", {}), int(control.get_meta("population", -1))) + ("\n" + explanation if not explanation.is_empty() else "")
	elif control.name == "ConfirmRecruitButton":
		explanation = _help_unit_description(_recruit_unit_type, _recruit_archetype) + "\n" + _recipe(_recruit_unit_type, false) + "\n" + explanation
		var reason := _recruit_lock_reason(_recruit_unit_type)
		if not reason.is_empty(): explanation += "\n不可用：" + reason
	elif control.name == "RecruitWorkerButton":
		explanation += "\n" + _recipe("worker", false)
	elif control.has_meta("profile") and str(control.name).begins_with("TechnologyNode_"):
		var profile: Dictionary = control.get_meta("profile", {})
		explanation = str(profile.get("label", "本族专精")) + "\n" + _help_cost(profile.get("cost", {})) + "\n" + explanation
	elif control.has_meta("technology"):
		var technology := str(control.get_meta("technology", "ATTACK"))
		var rank := int(control.get_meta("rank", 1))
		var recipe: Dictionary = _snapshot.get("catalog", {}).get("technologies", {}).get(technology, {})
		explanation = "%s科技 · 第%d级 · 每级+%d\n%s\n%s\n%s" % ["攻击" if technology == "ATTACK" else "护甲", rank, int(recipe.get("effect_per_level", 0)), _help_cost(_technology_cost(technology, rank)), str({"AVAILABLE":"可以研究", "UPGRADED":"已经完成", "LOCKED":"前置未满足", "UNAFFORDABLE":"当前资源不足"}.get(str(control.get_meta("state", "")), "请查看当前状态")), explanation]
	elif control is QueueReadoutClass:
		var lines: Array[String] = ["队列 · 队首 → 队末"]
		for entry: Dictionary in control.entries:
			lines.append("%s · %s · %d/%d" % [str(entry.get("caption", "")), str(entry.get("state", "")), int(entry.get("progress", 0)), int(entry.get("max_progress", 1))])
			if not str(entry.get("description", "")).is_empty(): lines.append(str(entry.description))
		if control.entries.is_empty(): lines.append("当前队列为空。")
		lines.append("使用队首／队末取消按钮撤销相应订单；查看不取消或重排。")
		explanation = "\n".join(lines)
	elif explanation.is_empty() and control.has_meta("facts"):
		var lines: Array[String] = ["当前公开数值"]
		for fact: Dictionary in control.get_meta("facts", []):
			lines.append("%s：%s" % [str(fact.get("property", fact.get("caption", "状态"))), str(fact.get("value", fact.get("caption", "—")))])
		explanation = "\n".join(lines)
	if control == _attack_joystick and explanation.is_empty(): explanation = HelpDescriptions.operation("AttackJoystick", "攻击")
	if control == _move_joystick: explanation = HelpDescriptions.operation("MovementJoystick", "移动")
	if explanation.is_empty() and control is BaseButton:
		explanation = HelpDescriptions.operation(str(control.name), str(control.text))
	if control is BaseButton and control.disabled:
		explanation += "\n当前不可用，请先满足所需条件。"
	return explanation

func _help_cost(cost: Dictionary, population: int = -1) -> String:
	var result := "费用：金币%d" % int(cost.get("MATERIAL", 0))
	if population >= 0: result += " · 人口%d" % population
	return result

func _help_hero_overview(unit_id: String) -> String:
	# Portraits are an overview, not a second copy of the full handbook.
	# Read current stable-ID facts; leave dedicated skill/matrix descriptions
	# and all inspection input ownership with their existing consumers.
	var hero := _hero(unit_id)
	var unit := _soldier(unit_id)
	if hero.is_empty() or unit.is_empty(): return "英雄资料已失效；请重新选择。"
	var profile := HeroCatalog.profile(str(hero.get("hero_archetype", "COMMANDER")))
	var next_xp := int(hero.get("next_level_xp", -1))
	var xp := "%d/%d" % [int(hero.get("xp", 0)), next_xp] if next_xp > 0 else "%d（满级）" % int(hero.get("xp", 0))
	var layers: Array = unit.get("attack_layers", profile.get("attack_layers", []))
	var layer_text := "地面/空中" if "GROUND" in layers and "AIR" in layers else "仅地面" if "GROUND" in layers else "仅空中" if "AIR" in layers else "不普攻"
	var lines: Array[String] = [
		"%s · %s · 等级%d" % [str(hero.get("name", "英雄")), str(hero.get("title", "")), int(hero.get("level", 1))],
		"%s · %s/%s" % [str(profile.get("role", "")), DamageRules.attack_label(str(unit.get("attack_type", "CHAOS"))), DamageRules.armor_label(DamageRules.armor_for(unit))],
		"生命%d/%d · 蓝量%d/%d" % [int(unit.get("hp", 0)), int(unit.get("max_hp", 0)), int(hero.get("mana", 0)), int(hero.get("max_mana", 0))],
		"攻%d · 甲%d · 射程%d · 人口%d · %s" % [int(unit.get("damage", 0)), int(unit.get("armor", 0)), int(unit.get("attack_range", 0)), int(_snapshot.get("catalog", {}).get("units", {}).get("hero", {}).get("population", 5)), layer_text],
		"经验%s · 技能点%d" % [xp, int(hero.get("skill_points", 0))]
	]
	for skill: Dictionary in hero.get("skills", []):
		var rank := int(skill.get("level", 0))
		var required := int(skill.get("required_hero_level", 1))
		var learning := "%d/%d级" % [rank, int(skill.get("max_level", 3))] if rank > 0 else "未学（%d级）" % required if int(hero.get("level", 1)) < required else "未学"
		lines.append("%s · %s · %s" % [str(skill.get("name", "技能")), learning, HelpDescriptions.skill_overview_role(skill)])
	var reason := _hero_recruitment_block_reason()
	if hero.get("alive", false): lines.append("单击选择并聚焦；不下军令。")
	else:
		lines.append("已倒下：单击查看长官资料。" if not reason.is_empty() else "已倒下：单击复活／建祭庭。")
		var quote := _hero_quote(str(hero.get("hero_archetype", "COMMANDER")))
		lines.append(_hero_quote_summary(quote))
		var quote_reason := _hero_quote_block_reason(quote)
		if not quote_reason.is_empty(): lines.append(quote_reason)
		lines.append("保留成长与行囊；掉落装备不返还。")
	if not reason.is_empty(): lines.append(reason)
	lines.append("完整属性／技能见单位手册。")
	return "\n".join(lines)

func _help_unit_description(type: String, archetype: String = "COMMANDER", observed: Dictionary = {}) -> String:
	var title := str(HeroCatalog.profile(archetype).get("name", "英雄长官")) if type == "hero" else _unit_name(type)
	var text := title + "\n" + _unit_brief(type, archetype)
	text += "\n人口占用%d" % int(_snapshot.get("catalog", {}).get("units", {}).get(type, {}).get("population", 5 if type == "hero" else 1))
	if not observed.is_empty():
		text += "\n当前：生命%d/%d · 攻击%d · 护甲%d · 射程%d" % [int(observed.get("hp", 0)), int(observed.get("max_hp", 0)), int(observed.get("damage", 0)), int(observed.get("armor", 0)), int(observed.get("attack_range", 0))]
	text += "\n" + _unit_trait(type, archetype)
	if type == "hero":
		var hero := _hero(str(observed.get("id", "")))
		if not hero.is_empty(): text += "\n等级%d · 蓝量%d/%d · 技能点%d" % [int(hero.get("level", 1)), int(hero.get("mana", 0)), int(hero.get("max_mana", 0)), int(hero.get("skill_points", 0))]
		var skills: Array = hero.get("skills", HeroCatalog.skills_for(archetype))
		for skill: Dictionary in skills:
			text += "\n%s：%s" % [str(skill.get("name", "技能")), str(skill.get("description", ""))]
	return text

func _help_world_target(point: Vector2) -> Dictionary:
	if not _is_ground(point): return {}
	var best: Dictionary = {}
	var distance := INF
	for collection: String in ["soldiers", "workers"]:
		for unit: Dictionary in _snapshot.get(collection, []):
			if int(unit.get("hp", 0)) <= 0 or not bool(unit.get("alive", true)): continue
			var id := str(unit.get("id", ""))
			var foot: Vector2 = _camera.world_to_screen(Vector2(unit.get("position", Vector2.ZERO)))
			var delta := foot.distance_squared_to(point)
			var body_hit := false
			if delta > 24.0 * 24.0:
				if heroic_2d_enabled or frontier_3d_enabled:
					body_hit = _canvas != null and _canvas.visual_body_contains(id, "unit", point)
				else:
					var body: Rect2 = PixelClass.unit_visual_bounds(unit, maxf(float(unit.get("radius", 12)) * float(_camera.get_scale()), 3))
					body_hit = Rect2(foot + body.position, body.size).has_point(point)
			if delta > 24.0 * 24.0 and not body_hit: continue
			if delta > distance or (delta == distance and str(best.get("key", "")) < "unit:" + id): continue
			var worker := collection == "workers"
			var type := "worker" if worker else str(unit.get("unit_type", "hinge_guard"))
			var text := _help_unit_description(type, str(unit.get("hero_archetype", "COMMANDER")), unit)
			if unit.get("neutral", false): text = "%s · 野怪守军\n生命%d/%d · 攻击%d · 护甲%d · 射程%d\n击杀经验%d，由附近己方英雄平摊。驻守营地，追击过远会返巢；清除整营后才可占点。有掉落的营地保底1件，固定种子50%%额外1件，同质量表。\n%s" % [str(unit.get("label", unit.get("neutral_archetype", "野怪"))), int(unit.get("hp", 0)), int(unit.get("max_hp", 1)), int(unit.get("damage", 0)), int(unit.get("armor", 0)), int(unit.get("attack_range", 0)),int(unit.get("neutral_base_stats",{}).get("xp_reward",0)), DamageRules.type_summary(unit)]
			if unit.get("neutral_archetype") == "STRAGGLER":
				text = "%s · 荒径弱营\n生命%d/%d · 攻击%d · 护甲%d · 射程%d\n本单位%d经验（附近己方英雄平摊）、%d金币赏金直接给实际击杀方；无整营奖金、不掉装备。野营不可占领、不增加人口、不会复活。\n%s" % [str(unit.get("neutral_base_stats",{}).get("label","荒径游兵")),int(unit.get("hp",0)),int(unit.get("max_hp",1)),int(unit.get("damage",0)),int(unit.get("armor",0)),int(unit.get("attack_range",0)),int(unit.get("neutral_base_stats",{}).get("xp_reward",0)),int(unit.get("neutral_bounty",{}).get("MATERIAL",0)),DamageRules.type_summary(unit)]
			if worker: text += "\n当前岗位：" + str(ROLE_NAMES.get(str(unit.get("role", "RESERVE")), "待命"))
			text += "\n" + ("中立野怪" if unit.get("neutral", false) else "己方" if unit.get("side") == _view_side() else "对方") + " · 长按只查看，不改变当前命令。"
			best = {"key":("worker:" if worker else "unit:") + id, "kind":"world", "text":text, "rect":Rect2(foot - Vector2(24, 40), Vector2(48, 48))}
			distance = delta
	if not best.is_empty(): return best
	for building: Dictionary in _snapshot.get("buildings", []):
		if int(building.get("hp", 0)) <= 0: continue
		var foot: Vector2 = _camera.world_to_screen(Vector2(building.get("position", Vector2.ZERO)))
		var radius := maxf(float(building.get("radius", 24)) * float(_camera.get_scale()), 22)
		var hit := foot.distance_to(point) <= radius
		if not hit and (heroic_2d_enabled or frontier_3d_enabled): hit = _canvas != null and _canvas.visual_body_contains(str(building.get("id", "")), "building", point)
		if not hit: continue
		var type := str(building.get("building_type", "BASE"))
		var text := str(building.get("label",_building_display_name(type,str(building.get("side",""))))) + "\n" + HelpDescriptions.building(type)
		text += "\n生命%d/%d · %s" % [int(building.get("hp", 0)), int(building.get("max_hp", 0)), "已完工" if building.get("complete", false) else "施工%d/%d" % [int(building.get("progress", 0)), int(building.get("max_progress", 100))]]
		text += "\n" + DamageRules.armor_summary(DamageRules.armor_for(building))
		if int(building.get("attack_range",0)) > 0:
			text += "\n%s · 攻击%d · 射程%d · 火力≈%.1f名基础远程" % ["自动防御" if building.get("defense_active",true) else "休眠 / 争夺中",int(building.get("damage", 0)),int(building.get("attack_range", 0)),float(building.get("ranged_equivalent",0))]
			text += "\n" + DamageRules.attack_summary(str(building.get("attack_type", "PIERCE")))
		text += "\n" + ("己方" if building.get("side") == _view_side() else "对方") + " · 长按只查看，不打开面板或下令。"
		return {"key":"building:" + str(building.get("id", "")), "kind":"world", "text":text, "rect":Rect2(foot - Vector2(radius, radius), Vector2.ONE * radius * 2)}
	var slot := OutpostSlotUI.hit(_snapshot, _camera, point)
	if not slot.is_empty():
		var site := _outpost_site(slot)
		var foot: Vector2 = _camera.world_to_screen(Vector2(slot.get("position", Vector2.ZERO)))
		var recipe: Dictionary = _building_recipes().get(str(slot.get("building_type", "")), {})
		var reason := OutpostSlotUI.reason(slot, _view_side(), _observing())
		var text := OutpostSlotUI.label(slot) + " · 固定建筑空位\n" + OutpostSlotUI.limits(str(site.get("kind", "RESOURCE"))) + "\n" + _help_cost(recipe.get("cost", {})) + "\n" + (reason if not reason.is_empty() else "单击查看，确认才扣费；无需建筑工。")
		return {"key":"slot:" + str(slot.get("id", "")), "kind":"world", "text":text, "rect":Rect2(foot-Vector2(28,24),Vector2(56,48))}
	for loot: Dictionary in _snapshot.get("neutral_loot", []):
		if loot.get("state") != "AVAILABLE": continue
		var foot: Vector2 = _camera.world_to_screen(Vector2(loot.get("position", Vector2.ZERO)))
		if foot.distance_to(point) > 28: continue
		var item: Dictionary = HeroItems.ITEMS.get(str(loot.get("item_id", "")), {})
		var ownership := "英雄遗落装备 · 所有阵营均可争夺！160范围英雄可拾取；满包保留地面，10分钟后消失。" if loot.get("pickup_scope") == "PUBLIC" else "己方可拾取：160范围英雄自动拾取；满包保留地面，单击可让所选英雄靠近。" if loot.get("owner") == _view_side() else "归另一方所有。"
		return {"key":"loot:" + str(loot.id), "kind":"world", "text":str(item.get("name", "战利品")) + "\n" + str(item.get("description", "")) + "\n" + ownership, "rect":Rect2(foot - Vector2(28, 38), Vector2(56, 56))}
	for source: Dictionary in _snapshot.get("resource_sources", []):
		var foot: Vector2 = _camera.world_to_screen(Vector2(source.get("position", Vector2.ZERO)))
		if foot.distance_to(point) > maxf(float(source.get("radius", 40)) * float(_camera.get_scale()), 24): continue
		var text := str(SourceInspectionM71.read(_snapshot,str(source.get("id","")),_view_side()).get("description",""))
		if OutpostSlotUI.enabled(_snapshot): text = _outpost_resource_description(source)
		return {"key":"source:" + str(source.get("id", "")), "kind":"world", "text":text, "rect":Rect2(foot - Vector2(24, 24), Vector2(48, 48))}
	for camp: Dictionary in _snapshot.get("neutral_camps", []):
		if camp.get("kind") != "TRIAL": continue
		var foot: Vector2 = _camera.world_to_screen(Vector2(camp.get("position", Vector2.ZERO)))
		if foot.distance_to(point) > 60: continue
		return {"key":"camp:" + str(camp.id), "kind":"world", "text":str(camp.get("label", "问鼎试境")) + "\n高难野外试炼 · 剩余守军%d\n清营金币：%d；全营经验池%d，由各次击杀附近900内己方英雄平摊。\n可能掉高级装备；不可占领、无人口、不会复活刷怪。" % [int(camp.get("remaining_count", 0)), int(camp.get("reward", {}).get("MATERIAL", 0)), int(camp.get("xp_pool", 0))], "rect":Rect2(foot - Vector2(60, 80), Vector2(120, 100))}
	for site: Dictionary in _snapshot.get("sites", []):
		var foot: Vector2 = _camera.world_to_screen(Vector2(site.get("position", Vector2.ZERO)))
		if foot.distance_to(point) > 30: continue
		var readout := CaptureReadoutClass.read_site(_snapshot, str(site.get("id", "")))
		if readout.is_empty(): continue
		var text := ("资源根据地" if site.get("kind") == "RESOURCE" else "纯资源点" if site.get("kind") == "SATELLITE" else "人口据点") + "\n%s · 人口+%d\n%s\n%s\n存活士兵／英雄占据人数优势才会推进。" % [str(readout.get("owner_caption", "中立")), int(readout.get("capacity", 0)), str(readout.get("progress_caption", "")), str(readout.get("status_caption", ""))]
		if OutpostSlotUI.enabled(_snapshot): text += "\n" + OutpostSlotUI.limits(str(site.get("kind", "RESOURCE")))
		return {"key":"site:" + str(site.get("id", "")), "kind":"world", "text":text, "rect":Rect2(foot - Vector2(24, 24), Vector2(48, 48))}
	return {}

func _icon(symbol: String, caption: String, node_name: String) -> Button:
	var button := IconClass.new()
	button.name = node_name
	button.symbol = symbol
	button.caption = caption
	button.tooltip_text = HelpDescriptions.operation(node_name, caption)
	button.mouse_force_pass_scroll_events = false
	return button

func _button(caption: String, node_name: String, minimum: Vector2) -> Button:
	var button := TextButtonClass.new()
	button.text = caption
	button.name = node_name
	button.tooltip_text = HelpDescriptions.operation(node_name, caption)
	button.custom_minimum_size = minimum
	button.size = minimum
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_force_pass_scroll_events = false
	button.add_theme_font_size_override("font_size", 21)
	return button

func _option(node_name: String, point: Vector2, minimum: Vector2) -> OptionButton:
	var option := OptionButton.new()
	option.name = node_name
	option.position = point
	option.size = minimum
	option.custom_minimum_size = minimum
	# Long authoritative IDs must not enlarge a selector beyond the modal. The
	# native popup retains the full item string and the selected tooltip does too.
	option.clip_text = true
	option.fit_to_longest_item = false
	option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	option.add_theme_font_size_override("font_size", 19)
	option.add_theme_font_override("font", ReadableFont.readable())
	option.mouse_force_pass_scroll_events = false
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		option.add_theme_stylebox_override(state, ChromeClass.style(state, "stone"))
	var popup := option.get_popup()
	popup.add_theme_font_override("font", ReadableFont.readable())
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_constant_override("v_separation", 22)
	# Native popup rows are finger-sized, not just the closed selector. Long
	# army lists remain scrollable rather than escaping the logical viewport.
	popup.max_size = Vector2i(0, 560)
	popup.add_theme_stylebox_override("panel", ChromeClass.style("normal", "stone"))
	option.item_selected.connect(func(index: int): _update_option_caption(option, index))
	_panel_content.add_child(option)
	return option

func _add_option(option: OptionButton, caption: String, value: String) -> void:
	option.add_item(caption)
	option.set_item_metadata(option.item_count - 1, value)

func _choose_option(option: OptionButton, value: String) -> String:
	for n: int in range(option.item_count):
		if str(option.get_item_metadata(n)) == value:
			option.select(n)
			_update_option_caption(option, n)
			return value
	if option.item_count > 0:
		option.select(0)
		_update_option_caption(option, 0)
		return str(option.get_item_metadata(0))
	option.tooltip_text = ""
	return ""

func _update_option_caption(option: OptionButton, index: int) -> void:
	var full := option.get_item_text(index)
	option.tooltip_text = full
	if "player_" not in full and "resource_" not in full: return
	var caption := full.split(" · ")[0]
	if str(option.name) == "WorkSiteOption": caption = "根据地"
	option.text = "%s · %02d" % [caption, index + 1]
	if str(option.name) == "WorkSiteOption": option.text += " · +30"

func _label(value: String, size_value: int = 20) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", ReadableFont.readable())
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", Color("e1e5ce"))
	label.add_theme_color_override("font_outline_color", Color("19292c"))
	label.add_theme_constant_override("outline_size", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _panel_label(value: String, point: Vector2, font_size: int) -> Label:
	var label := _label(value, font_size)
	label.position = point
	_panel_content.add_child(label)
	return label

func _style(_color: Color) -> StyleBoxFlat:
	return ChromeClass.style("normal", "stone")

func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
