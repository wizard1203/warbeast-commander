extends Control
## Playable isolated laboratory, not a reskinned VFX-only theater.
signal exit_requested
const Runner = preload("res://src/simulation/strategic_hero_arena_runner.gd")
const Stage = preload("res://src/presentation/strategic_hero_arena_stage.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const FirstRelease = preload("res://src/simulation/first_release_catalog.gd")
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const Fonts = preload("res://src/presentation/strategic_font.gd")
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const TextButton = preload("res://src/presentation/strategic_text_button.gd")
const AudioFeedback = preload("res://src/presentation/strategic_audio_feedback.gd")
const AudioFactory = preload("res://src/presentation/strategic_local_audio_factory.gd")
const StatisticsM69 = preload("res://src/presentation/strategic_hero_statistics_panel_m69.gd")
const ReplayReviewM69 = preload("res://src/presentation/strategic_replay_review_m69.gd")
const LoadoutReadout = preload("res://src/presentation/strategic_arena_loadout_readout.gd")
const BudgetPreset = preload("res://src/simulation/strategic_arena_budget_preset.gd")
const RosterAtlasV9 = preload("res://src/presentation/heroic_roster_v5.gd")
const ForceReadoutR19 = preload("res://src/simulation/strategic_arena_force_readout_r19.gd")
const ForceOverlayR19 = preload("res://src/presentation/strategic_arena_force_overlay_r19.gd")
const NEURAL_FEEDBACK_PATH := "res://tools/asset_workshop/neural_arena_feedback.gd"
const NEURAL_MANIFEST_PATH := AudioFactory.MANIFEST
var runner := Runner.new()
var _config: Dictionary = {}
var _mode: OptionButton
var _seed: SpinBox
var _limit: SpinBox
var _pause: Button
var _stage: Control
var _status: Label
var _metrics: RichTextLabel
var _details: RichTextLabel
var _editor: VBoxContainer
var _side := "PLAYER"
var _editing_hero := 0
var _accumulator := 0.0
var _refresh_elapsed := 0.0
var _speed := 1
var _active := false
var _selected := ""
var _side_buttons: Dictionary = {}
var _last_error := ""
var _audio: Node
var _audio_snapshot: Dictionary = {}
var _sound_enabled := true
var _trio_controls: HFlowContainer
var _trio_cell := 0
var _trio_level := 5
var _statistics_m69: Control
var _replay_m69: Control
var _inspection: VBoxContainer
var _budget_receipt: Dictionary = {}
var _budget_note: Label
var _neural_button: Label
var _configuration_panel: VBoxContainer
var _budget_target: OptionButton
var _budget_random_faction: CheckButton
var _atlas_preparation_v9: Dictionary = {}
var _statistics_was_paused_r10 := false
var _force_overlay_r19: Control
var _force_model_r19: Dictionary = {}
var _force_refreshes_r19 := 0
var _troop_investment_labels_r19: Dictionary = {}
var _investment_total_r19: Label

func _ready() -> void:
	name = "StrategicHeroArena"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_audio = AudioFactory.create()
	_audio.set_volume(0.35)
	_audio.set_muted(not _sound_enabled)
	add_child(_audio)
	initialize_budget(1701)
	visibility_changed.connect(func():
		if not is_visible_in_tree(): set_paused(true))

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color("111a18")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,14)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",9)
	margin.add_child(column)
	var header := HFlowContainer.new()
	column.add_child(header)
	var title := _label("首发三族竞技场",23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_button("ArenaStatistics","全军战斗统计",_open_statistics_m69))
	header.add_child(_button("ArenaFastReplay","快速模拟回放",_open_replay_m69))
	_budget_target = _option("ArenaBudgetTarget")
	_budget_target.fit_to_longest_item = false
	_budget_target.custom_minimum_size.x = 65
	for id: String in ["AI","PLAYER"]:
		_budget_target.add_item("右方" if id=="AI" else "左方")
		_budget_target.set_item_metadata(_budget_target.item_count-1,id)
	header.add_child(_budget_target)
	_budget_random_faction = CheckButton.new()
	_budget_random_faction.name = "ArenaBudgetRandomFaction"
	_budget_random_faction.text = "随机种族"
	_budget_random_faction.button_pressed = true
	_budget_random_faction.add_theme_font_override("font",Fonts.readable())
	_budget_random_faction.add_theme_font_size_override("font_size",13)
	header.add_child(_budget_random_faction)
	header.add_child(_button("ArenaBudgetDraw","按种子重抽",_draw_budget))
	header.add_child(_button("ArenaBudgetNext","下一种子",func(): reroll_budget_side(str(_budget_target.get_selected_metadata()),int(_seed.value)+1,_budget_random_faction.button_pressed)))
	header.add_child(_button("ArenaConfigurationToggle","配置栏",func(): _configuration_panel.visible=not _configuration_panel.visible))
	header.add_child(_button("ArenaReturn","返回大厅",func(): set_paused(true); exit_requested.emit()))
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("separation",5)
	column.add_child(toolbar)
	_mode = _option("ArenaMode")
	_mode.fit_to_longest_item = false
	_mode.custom_minimum_size.x = 165
	for id: String in Runner.MODES:
		_mode.add_item(str(Runner.MODES[id]))
		_mode.set_item_metadata(_mode.item_count-1,id)
	_mode.item_selected.connect(func(index: int):
		var left := str(_config.get("sides",{}).get("PLAYER",{}).get("faction_id","HUMAN"))
		var right := str(_config.get("sides",{}).get("AI",{}).get("faction_id",FirstRelease.DEFAULT_OPPONENT_FACTION))
		var next := Runner.preset(str(_mode.get_item_metadata(index)),left,right)
		if str(_mode.get_item_metadata(index)) == "RANDOM_TRIO": next = Runner.random_trio_preset(int(_seed.value),left,right,_trio_level,_trio_cell in [1,3],_trio_cell in [2,3])
		next.seed = int(_seed.value)
		next.limit_seconds = int(_limit.value)
		configure(next))
	toolbar.add_child(_mode)
	toolbar.add_child(_label("种子",14))
	_seed = _spin(1,2147483647,1701)
	_seed.name = "ArenaSeed"
	_seed.custom_minimum_size.x = 98
	_seed.value_changed.connect(func(value: float):
		if not _config.is_empty() and int(value)!=int(_config.get("seed",0)): _invalidate_budget("种子已修改"))
	toolbar.add_child(_seed)
	toolbar.add_child(_label("上限秒",14))
	_limit = _spin(1,300,60)
	_limit.name = "ArenaLimit"
	_limit.custom_minimum_size.x = 68
	toolbar.add_child(_limit)
	toolbar.add_child(_button("ArenaStart","开始",start_run))
	toolbar.add_child(_button("ArenaR7Preset","双法师演练",func(): configure(Runner.r7_wave_one_preset(int(_seed.value)))))
	_pause = _button("ArenaPause","暂停",func(): set_paused(not bool(runner.snapshot().get("arena",{}).get("paused",false))))
	toolbar.add_child(_pause)
	toolbar.add_child(_button("ArenaReset","重置",reset_run))
	var rate := _option("ArenaRate")
	for value: int in [1,2,4]: rate.add_item(str(value)+"×"); rate.set_item_metadata(rate.item_count-1,value)
	rate.item_selected.connect(func(index: int): _speed=int(rate.get_item_metadata(index)))
	toolbar.add_child(rate)
	var zoom := _option("ArenaZoom")
	zoom.fit_to_longest_item = false
	zoom.custom_minimum_size.x = 96
	for value: float in [1.0,1.4,2.0,2.8]:
		zoom.add_item("%.1f×视图" % value); zoom.set_item_metadata(zoom.item_count-1,value)
	zoom.select(2)
	zoom.item_selected.connect(func(index: int): _stage.zoom=float(zoom.get_item_metadata(index)); _stage.queue_redraw())
	toolbar.add_child(zoom)
	var sound := _button("ArenaSound","音效：开",func():
		_sound_enabled = not _sound_enabled
		_audio.set_muted(not _sound_enabled)
		find_child("ArenaSound",true,false).text = "音效：开" if _sound_enabled else "音效：关")
	toolbar.add_child(sound)
	toolbar.add_child(_button("ArenaShake","震屏：开",func():
		_stage.screen_shake_enabled=not _stage.screen_shake_enabled
		find_child("ArenaShake",true,false).text="震屏：开" if _stage.screen_shake_enabled else "震屏：关"
		_stage.queue_redraw()))
	_neural_button = _label("仅新音效 · 未配静音",12)
	_neural_button.name = "ArenaNeuralAudio"
	_neural_button.tooltip_text = "本机试玩统一使用新音效，尚未映射的事件静音，不混入旧音。SA3素材仍仅本地非商用。"
	toolbar.add_child(_neural_button)
	toolbar.add_child(_button("ArenaExport","导出结果",func():
		var path := "user://hero-arena-"+str(Time.get_unix_time_from_system()).replace(".","-")+".json"
		var result := export_report(path)
		_status.text = ("已保存 "+ProjectSettings.globalize_path(path)) if result.accepted else str(result.error)))
	_trio_controls = HFlowContainer.new()
	_trio_controls.name = "ArenaTrioControls"
	_trio_controls.add_theme_constant_override("separation",8)
	column.add_child(_trio_controls)
	_trio_controls.add_child(_button("ArenaTrioDraw","按当前种子抽三英雄",_draw_trio))
	_trio_controls.add_child(_button("ArenaTrioNext","下一种子重抽",func(): _seed.value += 1; _draw_trio()))
	var cell := _option("ArenaTrioCell")
	for label: String in ["无装备／无兵", "同四格装备／无兵", "无装备／带兵", "同四格装备／带兵"]: cell.add_item(label)
	cell.item_selected.connect(_set_trio_cell)
	_trio_controls.add_child(cell)
	_trio_controls.add_child(_label("统一初始等级",14))
	var trio_level := _spin(1,8,5)
	trio_level.name = "ArenaTrioLevel"
	trio_level.custom_minimum_size.x = 70
	trio_level.value_changed.connect(func(value: float):
		_invalidate_budget("英雄等级已修改")
		_trio_level = int(value)
		for side: String in Runner.SIDES:
			for hero: Dictionary in _config.sides[side].heroes: hero.level = _trio_level; hero.erase("skill_ranks")
		configure(_config))
	_trio_controls.add_child(trio_level)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	column.add_child(content)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300
	_configuration_panel = left
	content.add_child(left)
	var side_row := HBoxContainer.new()
	left.add_child(side_row)
	for id: String in Runner.SIDES:
		var button := _button("ArenaSide"+id,"左方" if id=="PLAYER" else "右方",_switch_side.bind(id))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		side_row.add_child(button)
		_side_buttons[id] = button
	var scroll := ScrollContainer.new()
	scroll.name = "ArenaConfigurationScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	_editor = VBoxContainer.new()
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor.add_theme_constant_override("separation",7)
	scroll.add_child(_editor)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(right)
	_stage = Stage.new()
	_stage.name = "HeroArenaStage"
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.unit_selected.connect(select_actor)
	_force_overlay_r19 = ForceOverlayR19.new()
	_force_overlay_r19.name = "ArenaForceOverlayR19"
	right.add_child(_force_overlay_r19)
	right.add_child(_stage)
	_metrics = _rich("ArenaMetrics",13)
	_metrics.custom_minimum_size.y = 62
	right.add_child(_metrics)
	_inspection = LoadoutReadout.new()
	_inspection.actor_selected.connect(select_actor)
	right.add_child(_inspection)
	_details = _inspection.find_child("ArenaUnitDetails",true,false)
	_budget_note = _label("",12)
	_budget_note.name = "ArenaBudgetReceipt"
	_budget_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_budget_note.visible = false
	column.add_child(_budget_note)
	_status = _label("训练夹具：免费装备／初始等级，正式经济不变。",14)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)

func configure(request: Dictionary) -> Dictionary:
	var result := runner.configure(request)
	if not result.accepted: _show_error(str(result.error)); return result
	_force_model_r19.clear()
	_config = request.duplicate(true)
	_discard_statistics_r10()
	if bool(request.get("first_release_mage_preset",false)) and is_instance_valid(_status):
		_status.text="双法师演练 · 照书与弧轧均8级，技能3/3/2级，无装备、带兵出战。此为训练预设，未按预算配平。"
	if is_instance_valid(_stage) and _stage.has_method("reset_feedback"): _stage.reset_feedback()
	_budget_receipt = request.get("budget_receipt",{}).duplicate(true)
	if is_instance_valid(_inspection): _inspection.clear_history(); _inspection.set_budget_receipt(_budget_receipt)
	_refresh_budget_note()
	_active = false
	_accumulator = 0
	_prepare_match_atlases_v9()
	if is_instance_valid(_audio): _audio.reset()
	_audio_snapshot = runner.snapshot()
	if is_instance_valid(_mode):
		_trio_controls.visible = str(_config.mode) == "RANDOM_TRIO"
		for index: int in range(_mode.item_count):
			if _mode.get_item_metadata(index) == _config.mode: _mode.select(index)
		_seed.value = int(_config.seed)
		_limit.value = int(_config.limit_seconds)
		_editing_hero = 0
		_build_editor()
		_stage.frame_deployment_r12(runner.snapshot())
		_stage.zoom = 2.0 if str(_config.mode)=="DUEL" else 1.0
		var zoom: OptionButton = find_child("ArenaZoom",true,false)
		if zoom != null: zoom.select(2 if str(_config.mode)=="DUEL" else 0)
		_refresh()
	return result

func set_budget_receipt(receipt: Dictionary) -> void:
	_budget_receipt = receipt.duplicate(true)
	if _budget_receipt.is_empty(): _config.erase("budget_receipt")
	else: _config["budget_receipt"] = _budget_receipt.duplicate(true)
	if is_instance_valid(_inspection): _inspection.set_budget_receipt(_budget_receipt)
	_refresh_budget_note()

func _refresh_budget_note() -> void:
	if not is_instance_valid(_budget_note): return
	_budget_note.visible = not _budget_receipt.is_empty()
	_budget_note.set_meta("budget_valid",not _budget_receipt.is_empty())
	_budget_note.set_meta("receipt",_budget_receipt.duplicate(true))
	var parts: Array[String] = []
	for side: String in Runner.SIDES:
		var row: Dictionary = _budget_receipt.get("sides",{}).get(side,{})
		parts.append(("左" if side=="PLAYER" else "右")+"：已用%d／余%d点"%[int(row.get("spent",0)),int(row.get("unspent",0))])
	_budget_note.text = "等预算训练 · 上限%d点 · "%int(_budget_receipt.get("caps",{}).get("total",0))+"；".join(parts)+" · 详见查阅「预算」"

func _invalidate_budget(reason: String) -> void:
	var had_receipt := not _budget_receipt.is_empty() or _config.has("budget_receipt")
	_budget_receipt.clear()
	_config.erase("budget_receipt")
	if is_instance_valid(_inspection): _inspection.set_budget_receipt({})
	if is_instance_valid(_budget_note):
		_budget_note.set_meta("budget_valid",false)
		_budget_note.set_meta("receipt",{})
		if had_receipt:
			_budget_note.visible=true
			_budget_note.text="自定义配置 · "+reason+"；重新随机后恢复等预算阵容。"

func initialize_budget(seed: int, budget: int = BudgetPreset.DEFAULT_BUDGET) -> Dictionary:
	# Only initial setup intentionally builds both sides. Redraw below preserves
	# the other side's complete initial configuration, including manual edits.
	var sides: Dictionary = _config.get("sides",{})
	var result: Dictionary = BudgetPreset.generate(seed,str(sides.get("PLAYER",{}).get("faction_id",FirstRelease.DEFAULT_PLAYER_FACTION)),str(sides.get("AI",{}).get("faction_id",FirstRelease.DEFAULT_OPPONENT_FACTION)),budget)
	if not bool(result.get("accepted",false)): _show_error(str(result.get("error","BUDGET_GENERATION_FAILED"))); return result
	var next: Dictionary = result.config.duplicate(true)
	next.limit_seconds = int(_limit.value)
	var configured := configure(next)
	if configured.accepted:
		set_budget_receipt(result.receipt)
		_status.text="等预算阵容已就绪；再次随机只更换选定的一方。英雄等级8/5/5，每人配发四件装备、两类补给。"
	return configured

static func random_budget_faction(side: String, seed: int) -> String:
	var index := (str(seed)+":"+side+":arena-faction-v1").sha256_text().substr(0,12).hex_to_int() % Factions.IDS.size()
	return str(Factions.IDS[index])

func _draw_budget() -> Dictionary:
	return reroll_budget_side(str(_budget_target.get_selected_metadata()),int(_seed.value),_budget_random_faction.button_pressed)

func reroll_budget_side(side: String, seed: int, random_faction: bool = true, budget: int = -1, faction_override: String = "") -> Dictionary:
	var faction := faction_override if not faction_override.is_empty() else random_budget_faction(side,seed) if random_faction else ""
	var result: Dictionary = BudgetPreset.reroll_side(_config,side,seed,faction,budget)
	if not bool(result.get("accepted",false)):
		_show_error(str(result.get("error","BUDGET_REROLL_FAILED")))
		return result
	var next: Dictionary = result.config.duplicate(true)
	next.limit_seconds = int(_limit.value)
	var applied := configure(next)
	if not bool(applied.accepted): return applied
	set_budget_receipt(result.receipt)
	_status.text=("仅重抽右方" if side=="AI" else "仅重抽左方")+" · 另一方初始配置完整保留；新种子也用于本局战斗随机。点击开始重建战斗。"
	return {"accepted":true,"error":"","config":_config.duplicate(true),"receipt":result.receipt.duplicate(true)}

func select_actor(id: String) -> Dictionary:
	var observation:=runner.snapshot()
	for body: Dictionary in observation.get("soldiers",[]):
		if str(body.get("id",""))!=id: continue
		_selected=id
		_refresh()
		return {"accepted":true,"id":id}
	# Expired corpses have no position/control, but retain their finite score row.
	for row:Dictionary in observation.get("hero_statistics",{}).get("heroes",[])+observation.get("hero_statistics",{}).get("units",[]):
		if str(row.get("hero_id",row.get("actor_id",row.get("unit_id",""))))!=id:continue
		_selected=id;_refresh();return {"accepted":true,"id":id,"statistics_only":true}
	return {"accepted":false,"error":"UNKNOWN_ARENA_ACTOR"}

func selected_readout() -> Dictionary:
	return _inspection.selected_readout() if is_instance_valid(_inspection) else {}

func _has_neural_audio() -> bool:
	if not is_instance_valid(_audio): return false
	if _audio.has_method("is_neural_audition"): return bool(_audio.call("is_neural_audition"))
	var script: Script = _audio.get_script()
	return script!=null and script.resource_path==NEURAL_FEEDBACK_PATH

func set_neural_audio(enabled: bool) -> Dictionary:
	if not enabled: return {"accepted":false,"error":"OLD_AUDIO_DISABLED"}
	if not _has_neural_audio():
		var previous_volume := float(_audio.volume) if is_instance_valid(_audio) else 0.35
		var candidate: Node = AudioFactory.create()
		if is_instance_valid(_audio):
			_audio.reset()
			remove_child(_audio)
			_audio.queue_free()
		_audio = candidate
		_audio.set_volume(previous_volume)
		_audio.set_muted(not _sound_enabled)
		add_child(_audio)
		_audio_snapshot=runner.snapshot()
		_audio.observe({},_audio_snapshot,Rect2(700,600,1300,1100))
		_audio.set_combat_paused(bool(_audio_snapshot.get("arena",{}).get("paused",false)))
	if _has_neural_audio(): _audio._sound_palette.mode=1
	var diagnostic: Dictionary = _audio.diagnostics()
	if is_instance_valid(_neural_button): _neural_button.text="仅新音效 · 未配静音" if bool(diagnostic.get("package_available",false)) else "新音效包缺失 · 静音"
	return {"accepted":true,"enabled":true,"audio_policy":"NEW_ONLY","package_available":bool(diagnostic.get("package_available",false)),"scope":"LOCAL_NONCOMMERCIAL_AUDITION"}

func _draw_trio() -> void:
	var next := Runner.random_trio_preset(int(_seed.value),str(_config.sides.PLAYER.faction_id),str(_config.sides.AI.faction_id),_trio_level,_trio_cell in [1,3],_trio_cell in [2,3])
	next.limit_seconds = int(_limit.value)
	configure(next)
	_status.text = "本族无放回抽取三英雄；切换四格只改装备／兵团，不重新抽签。"

func _set_trio_cell(index: int) -> void:
	_invalidate_budget("随机三英雄条件已修改")
	_trio_cell = index
	for side: String in Runner.SIDES:
		for hero: Dictionary in _config.sides[side].heroes: hero.equipment = Runner.TRIO_GEAR.duplicate() if index in [1,3] else []
		_config.sides[side].troops = Runner.trio_troops(str(_config.sides[side].faction_id)) if index in [2,3] else []
	configure(_config)
	_status.text = "保留同一三英雄阵容，已切换装备／带兵条件；训练赠予，不是自然经营。"

func start_run() -> Dictionary:
	if int(_seed.value)!=int(_config.get("seed",0)): _invalidate_budget("种子已修改")
	_config.seed = int(_seed.value)
	_config.limit_seconds = int(_limit.value)
	var setup := runner.configure(_config)
	if not setup.accepted: _show_error(str(setup.error)); return setup
	_discard_statistics_r10()
	_active = false
	_prepare_match_atlases_v9()
	if is_instance_valid(_stage) and _stage.has_method("reset_feedback"): _stage.reset_feedback()
	var result := runner.start_run()
	_force_model_r19.clear()
	_stage.frame_deployment_r12(runner.snapshot())
	_audio.reset()
	if is_instance_valid(_inspection): _inspection.clear_history()
	_audio_snapshot = runner.snapshot()
	_audio.observe({},_audio_snapshot,Rect2(700,600,1300,1100))
	_active = result.accepted
	_accumulator = 0
	_pause.text = "暂停"
	_status.text = "战斗进行中，击杀可获得经验。修改阵容后点击“开始”重新开战。"
	if bool(_config.get("r7_wave_one", false)):
		_status.text = "双法师演练 · 灰牒与沫蚀均8级，技能3/3/2级，无装备、带兵出战。此为训练预设，未按预算配平。"
	_refresh()
	return result

func set_paused(value: bool) -> void:
	runner.set_paused(value)
	if is_instance_valid(_audio): _audio.set_combat_paused(value)
	_accumulator = 0
	if is_instance_valid(_pause): _pause.text = "继续" if value else "暂停"
	_refresh()

func reset_run() -> Dictionary:
	if is_instance_valid(_stage) and _stage.has_method("reset_feedback"): _stage.reset_feedback()
	var result := runner.reset_run()
	_force_model_r19.clear()
	_stage.frame_deployment_r12(runner.snapshot())
	if bool(result.get("accepted",false)): _discard_statistics_r10()
	if is_instance_valid(_audio): _audio.reset()
	if is_instance_valid(_inspection): _inspection.clear_history()
	_audio_snapshot = runner.snapshot()
	_active = false
	_accumulator = 0
	_prepare_match_atlases_v9()
	if is_instance_valid(_pause): _pause.text = "暂停"
	_refresh()
	return result

func _prepare_match_atlases_v9() -> void:
	var heroes: Array[String] = []
	for side: String in Runner.SIDES:
		for hero: Dictionary in _config.get("sides",{}).get(side,{}).get("heroes",[]):
			var archetype := str(hero.get("archetype",""))
			if not archetype.is_empty() and archetype not in heroes: heroes.append(archetype)
	var at := Time.get_ticks_usec()
	_atlas_preparation_v9 = RosterAtlasV9.prepare_match(heroes)
	_atlas_preparation_v9["whole_prepare_us"] = Time.get_ticks_usec()-at
	# A missing pack must not make skills disappear or change the match. The
	# original author fallback remains, with rejection/bake counters exposed.

func snapshot() -> Dictionary: return runner.snapshot()

func _open_statistics_m69() -> void:
	# Capture the pre-modal state only on entry. A reentrant open already sees
	# the modal's own pause and must not turn it into the user's original state.
	if not is_instance_valid(_statistics_m69) or not _statistics_m69.visible:
		_statistics_was_paused_r10=bool(runner.snapshot().get("arena",{}).get("paused",false))
	set_paused(true)
	if not is_instance_valid(_statistics_m69):
		_statistics_m69 = StatisticsM69.new()
		_statistics_m69.name = "ArenaHeroStatistics"
		_statistics_m69.z_index = 30
		add_child(_statistics_m69)
		_statistics_m69.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_statistics_m69.close_requested.connect(_close_statistics_r10)
	_statistics_m69.set_statistics(runner.snapshot())
	_statistics_m69.show_actor_statistics(_selected)
	_statistics_m69.show()

func _close_statistics_r10() -> void:
	if not is_instance_valid(_statistics_m69) or not _statistics_m69.visible:return
	_statistics_m69.hide()
	var restore_pause:=_statistics_was_paused_r10
	_statistics_was_paused_r10=false
	set_paused(restore_pause)

func _discard_statistics_r10() -> void:
	# configure/start/reset have installed a new match. Retire its old readout
	# without restoring a pause captured from the previous match's lifetime.
	if is_instance_valid(_statistics_m69):
		_statistics_m69.hide()
		_statistics_m69.set_statistics({})
	_statistics_was_paused_r10=false

func _open_replay_m69() -> void:
	set_paused(true)
	if not is_instance_valid(_replay_m69):
		_replay_m69 = ReplayReviewM69.new()
		_replay_m69.z_index = 40
		add_child(_replay_m69)
	_replay_m69.open_for_arena(_config)

func export_report(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return {"accepted":false,"error":"CANNOT_WRITE_REPORT"}
	file.store_string(JSON.stringify(runner.report(),"\t")+"\n")
	return {"accepted":true,"path":path}

func _process(delta: float) -> void:
	if not _active or not is_visible_in_tree(): return
	var state: Dictionary = runner.snapshot().get("arena",{})
	if bool(state.get("paused",false)): return
	_accumulator += minf(delta,0.25)*float(_speed)
	var steps := mini(20,floori(_accumulator/0.05))
	if steps>0:
		_accumulator -= float(steps)*0.05
		runner.step(steps)
		var current := runner.snapshot()
		_stage.observation = current
		_audio.observe(_audio_snapshot,current,Rect2(700,600,1300,1100))
		_audio_snapshot = current
	_refresh_elapsed += delta
	if _refresh_elapsed >= 0.2:
		_refresh_elapsed = 0
		_refresh()
	if not bool(runner.snapshot().get("arena",{}).get("running",false)):
		_active = false
		_audio.set_combat_paused(true)
		_refresh()

func _switch_side(side: String) -> void:
	_side = side
	_editing_hero = 0
	_build_editor()

func _build_editor() -> void:
	_troop_investment_labels_r19.clear()
	_investment_total_r19 = null
	for child: Node in _editor.get_children(): _editor.remove_child(child); child.queue_free()
	for side: String in _side_buttons: _side_buttons[side].set_meta("selected",side==_side); _side_buttons[side].queue_redraw()
	var data: Dictionary = _config.sides[_side]
	_editor.add_child(_label("配置：下次开始生效",15))
	var faction := _option("ArenaFaction")
	for id: String in Factions.IDS:
		faction.add_item(str(Factions.profile(id).label)); faction.set_item_metadata(faction.item_count-1,id)
		if id == data.faction_id: faction.select(faction.item_count-1)
	faction.item_selected.connect(func(index: int):
		_invalidate_budget("种族已修改")
		var next := Runner.preset(str(_config.mode),str(faction.get_item_metadata(index)),str(faction.get_item_metadata(index)))
		if str(_config.mode) == "RANDOM_TRIO": next = Runner.random_trio_preset(int(_seed.value),str(faction.get_item_metadata(index)),str(faction.get_item_metadata(index)),_trio_level,_trio_cell in [1,3],_trio_cell in [2,3])
		_config.sides[_side] = next.sides[_side]
		_editing_hero = 0
		_build_editor())
	_editor.add_child(faction)
	_editor.add_child(_label("本族英雄（最多3位、不重复）",14))
	for index: int in range(data.heroes.size()):
		var hero: Dictionary = data.heroes[index]
		var row := HBoxContainer.new()
		var edit := _button("ArenaEditHero"+str(index),str(index+1),_select_hero.bind(index))
		edit.custom_minimum_size.x = 40
		row.add_child(edit)
		var option := _option("ArenaHero"+str(index))
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for kind: String in Factions.heroes_for(str(data.faction_id)):
			option.add_item(str(Heroes.profile(kind).name)); option.set_item_metadata(option.item_count-1,kind)
			if kind == hero.archetype: option.select(option.item_count-1)
		option.item_selected.connect(func(which: int):
			_invalidate_budget("英雄已修改")
			_config.sides[_side].heroes[index].archetype = str(option.get_item_metadata(which))
			_config.sides[_side].heroes[index].erase("skill_ranks")
			_editing_hero = index
			_build_editor())
		row.add_child(option)
		var level := _spin(1,8,int(hero.level))
		level.custom_minimum_size.x = 65
		level.value_changed.connect(func(value: float):
			_invalidate_budget("英雄等级已修改")
			_config.sides[_side].heroes[index].level = int(value)
			_config.sides[_side].heroes[index].erase("skill_ranks")
			_editing_hero = index
			_build_editor())
		row.add_child(level)
		_editor.add_child(row)
	if not data.heroes.is_empty(): _build_hero_loadout(data)
	else: _editor.add_child(_label("该预设无英雄，使用下方普通兵。",14))
	_editor.add_child(_label("普通部队（合法本族单位）",15))
	var troop_count := 0
	for group: Dictionary in data.troops: troop_count += int(group.get("count",0))
	_editor.add_child(_label("%d种兵 · %d个普通单位；全部组别均可查阅。"%[data.troops.size(),troop_count],13))
	_investment_total_r19 = _label("",12)
	_investment_total_r19.name = "ArenaTroopInvestmentTotalR19"
	_investment_total_r19.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_editor.add_child(_investment_total_r19)
	for index: int in range(maxi(3,data.troops.size())):
		var row := HBoxContainer.new()
		var option := _option("ArenaTroop"+str(index))
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_item("不出兵"); option.set_item_metadata(0,"")
		for kind: String in Factions.units_for(str(data.faction_id)):
			option.add_item(str(Runner.Units.UNITS[kind].label)); option.set_item_metadata(option.item_count-1,kind)
			var recipe: Dictionary = Runner.Units.UNITS[kind]
			option.set_item_tooltip(option.item_count-1,"%s · 每个%d金币／%d人口"%[str(recipe.label),int(recipe.cost.get("MATERIAL",0)),int(recipe.population)])
		var group: Dictionary = data.troops[index] if index < data.troops.size() else {"unit_type":"","count":0}
		for which: int in range(option.item_count):
			if option.get_item_metadata(which) == group.unit_type: option.select(which)
		var count := _spin(0,24,int(group.count))
		count.name = "ArenaTroopCountR19_"+str(index)
		count.custom_minimum_size.x = 72
		option.item_selected.connect(func(which: int):
			var chosen := str(option.get_item_metadata(which))
			_store_troop(index,chosen,maxi(1,int(count.value)) if not chosen.is_empty() else 0)
			_build_editor())
		count.value_changed.connect(func(value: float):
			_store_troop(index,str(option.get_selected_metadata()),int(value))
			if int(value)==0: _build_editor()
			else: _refresh_configuration_costs_r19())
		row.add_child(option); row.add_child(count); _editor.add_child(row)
		var investment := _label("",12)
		investment.name="ArenaTroopInvestmentR19_"+str(index)
		investment.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_editor.add_child(investment)
		_troop_investment_labels_r19[index]=investment
	_refresh_configuration_costs_r19()
	var note := _label("装备为训练赠予；价格仅用于比较投入。\n初始1—8级，战斗击杀继续获得经验。",13)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_editor.add_child(note)

func _refresh_configuration_costs_r19() -> void:
	var data: Dictionary = _config.get("sides",{}).get(_side,{})
	var totals: Dictionary = ForceReadoutR19.configuration(data)
	if is_instance_valid(_investment_total_r19):
		_investment_total_r19.text="下局部队标价 %d金币 · 全队%d人口（含英雄）；占比按本方初始人口。"%[int(totals.gold),int(totals.population)]
	for index: int in _troop_investment_labels_r19:
		var label: Label = _troop_investment_labels_r19[index]
		var groups: Array = data.get("troops",[])
		if index>=groups.size(): label.text="未编入部队";continue
		var group: Dictionary = groups[index]
		var recipe: Dictionary = Runner.Units.UNITS.get(str(group.unit_type),{})
		var count := int(group.get("count",0))
		var population := int(recipe.get("population",0))
		var gold := int(recipe.get("cost",{}).get("MATERIAL",0))
		label.text="%d金币／个 · %d人口／个\n本组%d金币 · %d人口，占本方%.1f%%"%[gold,population,gold*count,population*count,100.0*population*count/maxi(1,int(totals.population))]

func force_readout_r19() -> Dictionary:
	return _force_model_r19.duplicate(true)

func _select_hero(index: int) -> void:
	_editing_hero = index
	_build_editor()

func _build_hero_loadout(data: Dictionary) -> void:
	_editing_hero = clampi(_editing_hero,0,data.heroes.size()-1)
	var hero: Dictionary = data.heroes[_editing_hero]
	var profile: Dictionary = Heroes.profile(str(hero.archetype))
	_editor.add_child(_label("查阅／装备："+str(profile.name),16))
	var ranks: Array = hero.get("skill_ranks",Runner.default_skill_ranks(str(hero.archetype),int(hero.level)))
	for index: int in range(3):
		var skill: Dictionary = Heroes.skill_at_level(str(profile.skill_ids[index]))
		var row := HBoxContainer.new()
		var label := _label(str(skill.name)+("〔大招5/8级〕" if bool(skill.ultimate) else ""),14)
		label.tooltip_text = str(skill.get("description",""))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var rank := _spin(0,2 if bool(skill.ultimate) else 3,int(ranks[index]))
		rank.custom_minimum_size.x = 65
		rank.value_changed.connect(func(value: float):
			_invalidate_budget("技能配点已修改")
			var current: Array = _config.sides[_side].heroes[_editing_hero].get("skill_ranks",Runner.default_skill_ranks(str(hero.archetype),int(hero.level))).duplicate()
			current[index] = int(value)
			_config.sides[_side].heroes[_editing_hero].skill_ranks = current)
		row.add_child(rank); _editor.add_child(row)
	_editor.add_child(_button("ArenaAutoSkills","自动分配合法技能点",func(): _invalidate_budget("技能配点已修改"); _config.sides[_side].heroes[_editing_hero].erase("skill_ranks"); _build_editor()))
	for key: String in ["equipment","consumables"]:
		_editor.add_child(_label("四装备格" if key=="equipment" else "两消耗品格 · 每种一份",14))
		var values: Array = hero.get(key,[])
		for slot: int in range(4 if key=="equipment" else 2):
			var option := _option("Arena"+key+str(slot))
			option.add_item("— 空位 —"); option.set_item_metadata(0,"")
			for id: String in Items.ITEMS:
				if bool(Items.ITEMS[id].get("consumable",false)) != (key=="consumables"): continue
				option.add_item(str(Items.ITEMS[id].name)); option.set_item_metadata(option.item_count-1,id)
				if slot < values.size() and values[slot] == id: option.select(option.item_count-1)
			var selected_id := str(option.get_selected_metadata())
			option.tooltip_text = str(Items.ITEMS.get(selected_id,{}).get("description","训练空位"))
			option.item_selected.connect(func(which: int):
				_invalidate_budget("装备／消耗品已修改")
				var selected: Array = _config.sides[_side].heroes[_editing_hero].get(key,[]).duplicate()
				while selected.size() < (4 if key=="equipment" else 2): selected.append("")
				selected[slot] = str(option.get_item_metadata(which))
				_config.sides[_side].heroes[_editing_hero][key] = selected.filter(func(item: String) -> bool: return not item.is_empty())
				_build_editor())
			_editor.add_child(option)

func _store_troop(index: int, kind: String, count: int) -> void:
	_invalidate_budget("兵团已修改")
	var rows: Array = _config.sides[_side].troops.duplicate(true)
	while rows.size() <= index: rows.append({"unit_type":"","count":0})
	rows[index] = {"unit_type":kind,"count":count}
	_config.sides[_side].troops = rows.filter(func(row: Dictionary) -> bool: return not str(row.unit_type).is_empty() and int(row.count)>0)

func _refresh() -> void:
	if not is_instance_valid(_stage): return
	var observation := runner.snapshot()
	_stage.observation = observation
	# Existing 5Hz UI boundary, never the render loop or every logic tick.
	# Paused clicks reuse the model; new runs explicitly invalidate it above.
	if _force_model_r19.is_empty() or int(_force_model_r19.get("observation_tick",-2))!=int(observation.get("tick",0)):
		_force_model_r19=ForceReadoutR19.build(observation,runner.initial_force_roster_r19())
		_force_refreshes_r19+=1
		_force_overlay_r19.refresh(_force_model_r19)
	var result := runner.report()
	var lines: Array[String] = []
	for side: String in Runner.SIDES:
		var row: Dictionary = result.sides[side]
		var actual_hero_damage := 0
		var actual_troop_damage:=0
		var actual_taken:=0
		for hero: Dictionary in observation.get("hero_statistics",{}).get("heroes",[]):
			if hero.side == side: actual_hero_damage += int(hero.total_damage);actual_taken+=int(hero.damage_taken)
		for troop:Dictionary in observation.get("hero_statistics",{}).get("units",[]):
			if troop.side==side:actual_troop_damage+=int(troop.total_damage);actual_taken+=int(troop.damage_taken)
		lines.append("[color=%s]%s[/color] 存活 %d/%d · 人口 %d · 生命 %d/%d · 兵装标价 %d金币\n全军实伤 %d（英雄%d／兵种%d） · 全军承伤 %d · 受硬控 %.1fs · 施法 %d / 蓝 %d" % ["e4c25c" if side=="PLAYER" else "df9275","左方" if side=="PLAYER" else "右方",row.alive,row.initial_units,row.initial_population,row.hp,row.max_hp,int(row.catalog_cost.get("MATERIAL",0)),actual_hero_damage+actual_troop_damage,actual_hero_damage,actual_troop_damage,actual_taken,row.hard_control_seconds,row.casts,row.mana_paid])
	_metrics.text = "[b]%s[/b]  %s\n%s" % [str(Runner.MODES.get(str(_config.get("mode","")),"")),_outcome_label(str(result.outcome)),"\n".join(lines)]
	var body: Dictionary = {}
	for candidate: Dictionary in observation.get("soldiers",[]):
		if str(candidate.id) == _selected: body = candidate; break
	var retained_stat:=false
	for entry:Dictionary in observation.get("hero_statistics",{}).get("heroes",[])+observation.get("hero_statistics",{}).get("units",[]):
		if str(entry.get("hero_id",entry.get("actor_id",entry.get("unit_id",""))))==_selected:retained_stat=true;break
	if body.is_empty() and not retained_stat and not observation.get("soldiers",[]).is_empty(): body = observation.soldiers[0]; _selected=str(body.id)
	_stage.selected = _selected
	if is_instance_valid(_inspection): _inspection.refresh(observation,_config,_selected,_force_model_r19)

func _hero_skill_line(observation: Dictionary, body: Dictionary) -> String:
	for hero: Dictionary in observation.get("heroes",{}).get("officers",[]):
		if hero.id != body.id: continue
		var parts: Array[String] = []
		for skill: Dictionary in hero.skills: parts.append("%s %d级 %s" % [skill.name,skill.level,"被动" if skill.passive else "%.1fs" % (float(skill.cooldown_ticks)/20.0)])
		var gear: Array[String] = []
		for item: String in hero.equipment: gear.append(str(Items.ITEMS.get(item,{}).get("name",item)))
		return " · ".join(parts)+("\n装备："+"／".join(gear) if not gear.is_empty() else "\n装备：无装训练")
	return str(body.get("trait_description","与编队共同作战，自动攻击可及的敌人。"))

func _show_error(error: String) -> void:
	_last_error = error
	var explanation := "随机三英雄必须每方恰好3位同族不同英雄" if error == "RANDOM_TRIO_REQUIRES_THREE_HEROES" else error
	if is_instance_valid(_status): _status.text="配置未生效："+explanation+"（检查重复英雄、技能点和装备格）"

static func _outcome_label(value: String) -> String:
	return str({"READY":"待开始","RUNNING":"交战中","TIME_BOUND":"时间上限 · 未结束，不计胜","PLAYER_WIN":"左方全歼对手","AI_WIN":"右方全歼对手","DRAW":"双方全灭"}.get(value,value))

static func _label(text: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font",Fonts.readable())
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",Color("dfd1ae"))
	return result

static func _rich(id: String, font_size: int) -> RichTextLabel:
	var result := RichTextLabel.new()
	result.name = id
	result.bbcode_enabled = true
	result.add_theme_font_override("normal_font",Fonts.readable())
	result.add_theme_font_override("bold_font",Fonts.readable())
	result.add_theme_font_size_override("normal_font_size",font_size)
	result.add_theme_color_override("default_color",Color("d7d8bc"))
	result.add_theme_stylebox_override("normal",Chrome.style("normal","stone"))
	return result

static func _option(id: String) -> OptionButton:
	var result := OptionButton.new()
	result.name = id
	result.custom_minimum_size.y = 34
	result.add_theme_font_override("font",Fonts.readable())
	result.add_theme_font_size_override("font_size",15)
	for state: String in ["normal","hover","pressed","disabled","focus"]: result.add_theme_stylebox_override(state,Chrome.style(state,"command"))
	return result

static func _button(id: String, text: String, callback: Callable) -> Button:
	# The general TextButton paints at fixed 21px; this dense laboratory uses
	# genuine 15px labels so smaller hit boxes do not silently clip their text.
	var result := Button.new()
	result.name = id
	result.text = text
	result.add_theme_font_override("font",Fonts.readable())
	result.add_theme_font_size_override("font_size",15)
	for state: String in ["normal","hover","pressed","disabled","focus"]: result.add_theme_stylebox_override(state,Chrome.style(state,"command"))
	result.custom_minimum_size = Vector2(maxi(54,text.length()*15+20),35)
	result.pressed.connect(callback)
	return result

static func _spin(low: int, high: int, value: int) -> SpinBox:
	var result := SpinBox.new()
	result.min_value=low; result.max_value=high; result.step=1; result.value=value
	result.add_theme_font_override("font",Fonts.readable())
	result.add_theme_font_size_override("font_size",15)
	return result
