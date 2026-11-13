extends Control
## Lobby-owned fast simulation and historical-observation player. The engine
## is never advanced by playback, seek, speed, selection or statistics UI.
signal closed
const Replay = preload("res://src/simulation/strategic_battle_replay_m69.gd")
const Arena = preload("res://src/simulation/strategic_hero_arena_runner.gd")
const Stage = preload("res://src/presentation/strategic_replay_stage_m69.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Fonts = preload("res://src/presentation/strategic_font.gd")
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const TextButton = preload("res://src/presentation/strategic_text_button.gd")
const Statistics = preload("res://src/presentation/strategic_hero_statistics_panel_m69.gd")
const FileService = preload("res://src/presentation/strategic_replay_file_service_m69.gd")
const REPLAY_DIRECTORY := "user://m69-replays"
var _recorder := Replay.new()
var _recording: Dictionary = {}
var _match_request: Dictionary = {}
var _arena_request: Dictionary = {}
var _mode: OptionButton
var _seed: SpinBox
var _duration: SpinBox
var _left: OptionButton
var _right: OptionButton
var _level: SpinBox
var _cell: OptionButton
var _arena_controls: HBoxContainer
var _timeline: HSlider
var _status: Label
var _clock: Label
var _resolution: Label
var _pause: Button
var _stage: Control
var _subjects: OptionButton
var _details: RichTextLabel
var _saved: OptionButton
var _statistics: Control
var _playing := false
var _play_tick := 0.0
var _speed := 1.0
var _shown_tick := -1
var _selected := ""
var _roster_signature := ""
var _notice := ""
var _built := false
var _io_service: Node
var _io_job_id := 0
var _io_kind := ""

func _ready() -> void:
	name = "StrategicReplayReviewM69"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_io_service=FileService.acquire(get_tree())
	visible = false

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color("101b19")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,12)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",7)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("战斗快演 · 录像检阅",23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_button("ReplayReturn","返回大厅",close))
	var setup := HBoxContainer.new()
	setup.add_theme_constant_override("separation",8)
	column.add_child(setup)
	_mode = _option("ReplayMode")
	_mode.add_item("完整电脑对局 · 经营/扩张/战斗")
	_mode.add_item("随机三英雄 · 竞技场")
	_mode.add_item("当前竞技场配置")
	_mode.item_selected.connect(func(_index: int):
		_arena_controls.visible=_mode.selected==1
		_duration.max_value=900 if _mode.selected==0 else 300)
	setup.add_child(_mode)
	setup.add_child(_label("种子",15))
	_seed = _spin(1,999999,1701)
	_seed.name="ReplaySeed"
	setup.add_child(_seed)
	setup.add_child(_label("最多秒",15))
	_duration = _spin(1,900,120)
	_duration.name="ReplayDuration"
	setup.add_child(_duration)
	setup.add_child(_button("ReplayCompute","无渲染快速计算",start_simulation))
	setup.add_child(_button("ReplayCancel","停止并保留片段",func():
		if _recorder.progress().running: _recorder.cancel(); _finish_compute()))
	_arena_controls = HBoxContainer.new()
	_arena_controls.name="ReplayArenaControls"
	column.add_child(_arena_controls)
	_left = _faction_option("ReplayLeftFaction",0)
	_right = _faction_option("ReplayRightFaction",1)
	_arena_controls.add_child(_left)
	_arena_controls.add_child(_label("对",15))
	_arena_controls.add_child(_right)
	_arena_controls.add_child(_label("初始等级",15))
	_level = _spin(1,8,8)
	_level.name="ReplayHeroLevel"
	_arena_controls.add_child(_level)
	_cell = _option("ReplayContext")
	for text: String in ["无装备／无兵","四件装备／无兵","无装备／带兵","四件装备／带兵"]: _cell.add_item(text)
	_arena_controls.add_child(_cell)
	_arena_controls.visible=false
	var filebar := HBoxContainer.new()
	column.add_child(filebar)
	filebar.add_child(_button("ReplaySave","保存录像",save_recording))
	_saved = _option("ReplaySavedFiles")
	_saved.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	filebar.add_child(_saved)
	filebar.add_child(_button("ReplayLoad","载入所选录像",load_selected))
	filebar.add_child(_button("ReplayStatistics","英雄统计表",func(): _statistics.visible=not _statistics.visible))
	_status = _label("读取大厅种族与地图；快速模式会在独立副本中把全部玩家交给电脑。",15)
	_status.name="ReplayProgress"
	_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.y=42
	column.add_child(_status)
	var body := HBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	column.add_child(body)
	_stage = Stage.new()
	_stage.name="ReplayStage"
	_stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_stage.subject_selected.connect(_select_subject)
	body.add_child(_stage)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x=270
	body.add_child(sidebar)
	sidebar.add_child(_label("单位 / 建筑查阅 · 只读",17))
	_subjects = _option("ReplaySubjects")
	_subjects.custom_minimum_size.x=270
	_subjects.item_selected.connect(func(index: int): _select_subject(str(_subjects.get_item_metadata(index))); _stage.focus_subject(_selected))
	sidebar.add_child(_subjects)
	_details = RichTextLabel.new()
	_details.name="ReplaySubjectDetails"
	_details.bbcode_enabled=true
	_details.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_details.add_theme_font_override("normal_font",Fonts.readable())
	_details.add_theme_font_size_override("normal_font_size",16)
	_details.add_theme_color_override("default_color",Color("e3dbc4"))
	sidebar.add_child(_details)
	var transport := HBoxContainer.new()
	column.add_child(transport)
	transport.add_child(_button("ReplayBack","◀ 1秒",func(): seek_tick(int(_play_tick)-20)))
	_pause=_button("ReplayPlay","播放",func(): _playing=not _playing; _pause.text="暂停" if _playing else "播放")
	transport.add_child(_pause)
	transport.add_child(_button("ReplayForward","1秒 ▶",func(): seek_tick(int(_play_tick)+20)))
	var rate := _option("ReplayPlaybackRate")
	for value: float in [0.25,0.5,1.0,2.0,4.0,8.0]: rate.add_item(str(value)+"×"); rate.set_item_metadata(rate.item_count-1,value)
	rate.select(2)
	rate.item_selected.connect(func(index: int): _speed=float(rate.get_item_metadata(index)))
	transport.add_child(rate)
	_clock=_label("0.0 / 0.0 秒",16)
	_clock.name="ReplayClock"
	transport.add_child(_clock)
	_resolution = _label("采样录像 · 拖动可倒退 · 滚轮缩放/右键拖图 · 回放静音且不能指挥",14)
	_resolution.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	transport.add_child(_resolution)
	_timeline=HSlider.new()
	_timeline.name="ReplayTimeline"
	_timeline.min_value=0
	_timeline.max_value=1
	_timeline.step=1
	_timeline.custom_minimum_size.y=28
	_timeline.value_changed.connect(func(value: float): _playing=false; _pause.text="播放"; seek_tick(int(value)))
	column.add_child(_timeline)
	_statistics=Statistics.new()
	_statistics.name="ReplayHeroStatistics"
	_statistics.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_statistics.visible=false
	_statistics.close_requested.connect(func(): _statistics.visible=false)
	add_child(_statistics)
	_built=true
	_refresh_saved()

func open_for_match(request: Dictionary, seed: int = 1701) -> void:
	_match_request=request.duplicate(true)
	_seed.value=seed
	_mode.select(0)
	_duration.max_value=900
	_arena_controls.visible=false
	visible=true
	_refresh_saved()
	_notice="完整对局推进规则AI、采集、建造、生产与交战；不改变真实大厅对局。"
	_update_status()

func open_for_arena(config: Dictionary) -> void:
	_arena_request=config.duplicate(true)
	_seed.value=int(config.get("seed",1701))
	_duration.value=int(config.get("limit_seconds",60))
	_mode.select(2)
	_duration.max_value=300
	_arena_controls.visible=false
	visible=true
	_notice="当前竞技场配置：训练赠送等级/装备，非经营模式；正式战斗结算。"
	_update_status()

func close() -> void:
	if _recorder.progress().running: _recorder.cancel(); _finish_compute()
	_playing=false
	_statistics.visible=false
	if _io_job_id!=0: _io_service.abandon(_io_job_id); _io_job_id=0
	visible=false
	closed.emit()

func start_simulation() -> void:
	if _recorder.progress().running or _io_job_id!=0: return
	_playing=false
	var result: Dictionary
	if _mode.selected==0: result=_recorder.configure_strategic(_match_request,int(_seed.value),int(_duration.value))
	else:
		var config := _arena_request.duplicate(true)
		if _mode.selected==1:
			config=Arena.random_trio_preset(int(_seed.value),str(_left.get_item_metadata(_left.selected)),str(_right.get_item_metadata(_right.selected)),int(_level.value),_cell.selected in [1,3],_cell.selected in [2,3])
		if config.is_empty(): _notice="请先在英雄竞技场中配置对抗，或改选随机三英雄。"; _update_status(); return
		config.seed=int(_seed.value)
		config.limit_seconds=int(_duration.value)
		result=_recorder.configure_arena(config)
	if not result.accepted: _notice="无法开始："+str(result.error); _update_status(); return
	_recording.clear()
	_stage.visible=false # NO world/actor rendering while authority is computing.
	_shown_tick=-1
	_selected=""
	_roster_signature=""
	_timeline.editable=false
	_notice=""
	_update_status()

func _process(delta: float) -> void:
	_poll_io()
	if not visible or not _built: return
	if _recorder.progress().running:
		_recorder.pump(25.0,480)
		_update_status()
		if not _recorder.progress().running: _finish_compute()
	elif _playing and not _recording.is_empty():
		_play_tick=minf(_play_tick+delta*20.0*_speed,float(_recording.last_tick))
		_display()
		if _play_tick>=float(_recording.last_tick): _playing=false; _pause.text="播放"

func _finish_compute() -> void:
	if _recorder.progress().running or int(_recorder.progress().frames)==0: return
	_recording=_recorder.replay()
	_stage.visible=true
	_timeline.editable=true
	_timeline.max_value=maxi(1,int(_recording.last_tick))
	_notice="计算完成：%s；%.1f秒逻辑 / %.2f秒实际计算（%.1f×）。%d帧，%.1f MiB。"%[str(_recording.termination),float(_recording.computed_ticks)/20.0,float(_recording.wall_seconds),float(_recording.computed_ticks)/maxf(float(_recording.wall_seconds)*20.0,0.001),_recording.frames.size(),float(_recording.recorded_bytes)/1048576.0]
	if not bool(_recording.get("source_unchanged",false)): _notice="⚠ 计算期间源码发生变化；仅保留历史快照，不作为当前源码的合格测试。\n"+_notice
	seek_tick(0)
	_update_status()

func seek_tick(tick: int) -> void:
	if _recording.is_empty(): return
	if is_instance_valid(_stage):_stage.reset_feedback()
	_play_tick=clampf(tick,0,int(_recording.last_tick))
	_display(true)

func _display(force: bool = false) -> void:
	_timeline.set_value_no_signal(_play_tick)
	_clock.text="%.1f / %.1f 秒"%[_play_tick/20.0,float(_recording.last_tick)/20.0]
	var interval := maxi(1,int(_recording.get("sample_ticks",4)))
	_resolution.text="每%.2f秒快照 · 拖动倒退 · 滚轮缩放/右键拖图 · 静音只读"%(float(interval)/20.0)
	var expected := int(_play_tick)/interval*interval
	if int(_play_tick)>=int(_recording.last_tick): expected=int(_recording.last_tick)
	if not force and expected==_shown_tick: return
	var observation := Replay.observation_at(_recording,int(_play_tick))
	if not force and int(observation.get("tick",-1))==_shown_tick: return
	_shown_tick=int(observation.get("tick",0))
	_stage.show_observation(observation,str(_recording.kind))
	_refresh_subjects(observation)
	_refresh_details(observation)
	_statistics.refresh(observation)

func _refresh_subjects(observation: Dictionary) -> void:
	var roster: Array = []
	for group: String in ["soldiers","workers","buildings"]:
		for body: Dictionary in observation.get(group,[]): roster.append(body)
	var signature := ""
	for body: Dictionary in roster: signature+=str(body.get("id",""))+"/"
	if signature==_roster_signature: return
	_roster_signature=signature
	_subjects.clear()
	for body: Dictionary in roster:
		var name := str(body.get("label",body.get("unit_type",body.get("building_type","单位"))))
		if str(body.get("hero_archetype",""))!="": name=str(Heroes.profile(str(body.hero_archetype)).get("name",name))
		_subjects.add_item("%s · %s"%[str(body.get("side","野外")),name])
		_subjects.set_item_metadata(_subjects.item_count-1,str(body.get("id","")))
	var selected_exists := false
	for body: Dictionary in roster:
		if str(body.get("id",""))==_selected: selected_exists=true; break
	# A timeline before an entity's birth/removal cannot leave a default first
	# option claiming selection while the detail panel uses a now-absent ID.
	if not selected_exists: _selected=str(roster[0].get("id","")) if not roster.is_empty() else ""
	_subjects.select(-1)
	for index: int in range(_subjects.item_count):
		if str(_subjects.get_item_metadata(index))==_selected: _subjects.select(index)
	_stage.set_selected(_selected)

func _select_subject(id: String) -> void:
	var matched := -1
	for index: int in range(_subjects.item_count):
		if str(_subjects.get_item_metadata(index))==id: matched=index; break
	if matched<0:
		_stage.set_selected(_selected)
		return
	_selected=id
	_subjects.select(matched)
	_stage.set_selected(id)
	if not _recording.is_empty(): _refresh_details(Replay.observation_at(_recording,int(_play_tick)))

func _refresh_details(observation: Dictionary) -> void:
	var selected: Dictionary = {}
	for group: String in ["soldiers","workers","buildings"]:
		for body: Dictionary in observation.get(group,[]):
			if str(body.get("id",""))==_selected: selected=body; break
	if selected.is_empty(): _details.text="单击单位、建筑或上方列表查阅。\n历史画面只读：不会下达命令、复活或结算奖励。"; return
	var hero := str(selected.get("hero_archetype",""))
	var name := str(Heroes.profile(hero).get("name",hero)) if not hero.is_empty() else str(selected.get("label",selected.get("unit_type",selected.get("building_type","单位"))))
	var text := "[b]%s[/b]\n%s · %s\n生命 %d / %d\n"%[name,str(selected.get("side","野外")),_selected,int(selected.get("hp",0)),int(selected.get("max_hp",0))]
	if int(selected.get("max_mana",0))>0: text+="法力 %d / %d\n"%[int(selected.get("mana",0)),int(selected.get("max_mana",0))]
	text+="攻击 %s · 护甲 %s\n射程 %s · 等级 %s\n"%[str(selected.get("damage","—")),str(selected.get("armor","—")),str(selected.get("attack_range","—")),str(selected.get("level","—"))]
	for row: Dictionary in observation.get("hero_statistics",{}).get("heroes",[]):
		if str(row.get("hero_id",row.get("id","")))!=_selected: continue
		text+="\n[b]截至此帧 · 实际统计[/b]\n总伤害 %s\n普攻 %s · 技能 %s\n击杀兵 %s / 英雄 %s\n死亡 %s · 助攻 %s\n自疗 %s · 助疗 %s\n承伤 %s · 控制 %.1f秒\n"%[str(row.get("total_damage",0)),str(row.get("basic_damage",0)),str(row.get("learned_skill_damage",0)),str(row.get("unit_kills",0)),str(row.get("hero_kills",0)),str(row.get("deaths",0)),str(row.get("assists",0)),str(row.get("self_healing",0)),str(row.get("ally_healing",0)),str(row.get("damage_taken",0)),float(row.get("control_ticks",0))/20.0]
		break
	_details.text=text

func _update_status() -> void:
	var info := _recorder.progress()
	if _io_job_id!=0: _status.text="后台%s并完整校验录像中；界面仍可返回／浏览，不修改或重新计算战斗。"%("保存" if _io_kind=="SAVE" else "载入")
	elif info.running: _status.text="逻辑计算中 %.1f / %.0f 秒 · %.1f%% · 已记录%d帧 · %.1f MiB；不绘制战场，停止可保留片段。"%[float(info.tick)/20.0,float(info.limit_ticks)/20.0,float(info.fraction)*100.0,info.frames,float(info.bytes)/1048576.0]
	else: _status.text=_notice

func save_recording() -> void:
	if _io_job_id!=0 or _recorder.progress().running: return
	if _recording.is_empty(): _notice="暂无录像，先快速计算一局。"; _update_status(); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPLAY_DIRECTORY))
	var directory := DirAccess.open(REPLAY_DIRECTORY)
	if directory != null and directory.get_files().size()>=32: _notice="已有32份录像；为避免自动清除历史，请先自行整理 user://m69-replays 再保存。"; _update_status(); return
	var filename := "%s-%s-%d.wbr"%[str(_recording.kind).to_lower(),str(Time.get_unix_time_from_system()).replace(".","-"),Time.get_ticks_usec()]
	var path := REPLAY_DIRECTORY+"/"+filename
	var detached := _recording.duplicate(true)
	_io_kind="SAVE"
	_io_job_id=int(_io_service.submit_save(detached,path))
	_io_started()

func load_selected() -> void:
	if _recorder.progress().running or _io_job_id!=0: return
	if _saved.selected<0 or _saved.get_item_metadata(_saved.selected)==null: return
	var path := str(_saved.get_item_metadata(_saved.selected))
	_playing=false
	_io_kind="LOAD"
	_io_job_id=int(_io_service.submit_load(path))
	_io_started()

func _io_started() -> void:
	if _io_job_id==0:
		_notice="无法启动录像文件后台处理。"
	_update_status()

func _poll_io() -> void:
	if _io_job_id==0: return
	var result: Dictionary=_io_service.take_result(_io_job_id)
	if result.is_empty(): return
	_io_job_id=0
	if _io_kind=="SAVE":
		_notice="已保存 "+ProjectSettings.globalize_path(str(result.path)) if result.accepted else "保存失败："+str(result.error)
		_refresh_saved()
		_update_status()
	else: _accept_loaded(result)
	_io_kind=""

func _accept_loaded(result: Dictionary) -> void:
	if not result.accepted: _notice="载入失败："+str(result.error); _update_status(); return
	_recording=result.replay
	_playing=false
	_shown_tick=-1
	_roster_signature=""
	_selected=""
	_stage.visible=true
	_timeline.max_value=maxi(1,int(_recording.last_tick))
	_timeline.editable=true
	_notice="已载入历史只读录像 · "+str(_recording.termination)+(str(result.warning) if not str(result.warning).is_empty() else " · 当前源码一致。")
	if not bool(_recording.get("source_unchanged",false)): _notice="⚠ 此录像录制期间源码变化；不可作为当前源码合格测试。\n"+_notice
	seek_tick(0)
	_update_status()

func _exit_tree() -> void:
	if _io_job_id!=0 and is_instance_valid(_io_service): _io_service.abandon(_io_job_id)
	_io_job_id=0

func _refresh_saved() -> void:
	_saved.clear()
	var directory := DirAccess.open(REPLAY_DIRECTORY)
	if directory == null: _saved.add_item("尚未保存录像"); _saved.set_item_metadata(0,null); return
	var files := directory.get_files()
	files.sort()
	files.reverse()
	for filename: String in files:
		if not filename.ends_with(".wbr"): continue
		_saved.add_item(filename)
		_saved.set_item_metadata(_saved.item_count-1,REPLAY_DIRECTORY+"/"+filename)
	if _saved.item_count==0: _saved.add_item("尚未保存录像"); _saved.set_item_metadata(0,null)

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text=text
	label.add_theme_font_override("font",Fonts.readable())
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("dfd8bc"))
	return label

func _button(id: String, text: String, action: Callable) -> Button:
	# Dense transport uses the same authored pixel chrome with a real 16px
	# label, instead of cropping the legacy TextButton's fixed 21px painter.
	var button := Button.new()
	button.name=id
	button.text=text
	button.add_theme_font_override("font",Fonts.readable())
	button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",Color("e3dbc4"))
	for state: String in ["normal","hover","pressed","disabled","focus"]: button.add_theme_stylebox_override(state,Chrome.style(state,"stone"))
	button.custom_minimum_size=Vector2(maxf(78,Fonts.readable().get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+28),36)
	button.pressed.connect(action)
	return button

func _option(id: String) -> OptionButton:
	var result := OptionButton.new()
	result.name=id
	result.custom_minimum_size=Vector2(100,36)
	result.add_theme_font_override("font",Fonts.readable())
	result.add_theme_font_size_override("font_size",15)
	for state: String in ["normal","hover","pressed","disabled"]: result.add_theme_stylebox_override(state,Chrome.style(state,"stone"))
	return result

func _faction_option(id: String, selected: int) -> OptionButton:
	var result := _option(id)
	for faction: String in Factions.IDS: result.add_item(str(Factions.profile(faction).get("label",faction))); result.set_item_metadata(result.item_count-1,faction)
	result.select(selected)
	return result

func _spin(minimum: int, maximum: int, current: int) -> SpinBox:
	var result := SpinBox.new()
	result.min_value=minimum
	result.max_value=maximum
	result.step=1
	result.value=current
	result.custom_minimum_size.x=82
	result.add_theme_font_size_override("font_size",15)
	return result
