extends Control
## Local playback and read-only catalog browsing. Intentionally no GameSession.
const Catalog = preload("res://src/presentation/strategic_effects_catalog.gd")
const Stage = preload("res://src/presentation/strategic_effects_stage.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const TextButton = preload("res://src/presentation/strategic_text_button.gd")
const PreviewCard = preload("res://src/presentation/strategic_pregame_card.gd")
const FontClass = preload("res://src/presentation/strategic_font.gd")
const AudioFeedback = preload("res://src/presentation/strategic_audio_feedback.gd")
const LocalAudioFactory = preload("res://src/presentation/strategic_local_audio_factory.gd")
var _panel: Panel
var _faction: OptionButton
var _actors_scroll: ScrollContainer
var _actors_grid: GridContainer
var _search: LineEdit
var _stage: Control
var _effects: OptionButton
var _rank: OptionButton
var _speed: OptionButton
var _zoom: OptionButton
var _background: OptionButton
var _play: Button
var _replay: Button
var _close: Button
var _mirror: Button
var _focus: Button
var _focused := false
var _timeline: HSlider
var _title: Label
var _note: Label
var _description: RichTextLabel
var _actors: Array[Dictionary] = []
var _abilities: Array[Dictionary] = []
var _cards: Dictionary = {}
var _actor: Dictionary = {}
var _ability: Dictionary = {}
var _faction_id := "HUMAN"
var _elapsed := 0.0
var _playing := false
var _rate := 1.0
var _timeline_sync := false
var _audition: Button
var _audition_enabled := false
var _audition_audio: Node
var _audition_serial := 0
var _audition_cycle := 0

class ActorCard extends Button:
	var actor: Dictionary = {}
	var selected := false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		custom_minimum_size=Vector2(124,110)
		for state: String in ["normal","hover","pressed","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
	func _draw() -> void:
		Chrome.draw_material(self,Rect2(Vector2.ZERO,size),"hero" if selected else "stone",is_pressed())
		if selected: draw_rect(Rect2(4,4,size.x-8,2),Color("d8b768"))
		PreviewCard.draw_preview(self,Rect2(15,9,size.x-30,64),{"kind":"UNIT","visual":actor.unit,"id":actor.unit.unit_type})
		draw_string(FontClass.readable(),Vector2(7,86),str(actor.label),HORIZONTAL_ALIGNMENT_CENTER,size.x-14,15,Color("eddfbb"))
		draw_string(FontClass.readable(),Vector2(7,103),str(actor.group),HORIZONTAL_ALIGNMENT_CENTER,size.x-14,12,Color("aebca8"))

func _ready() -> void:
	name="StrategicEffectsTheater"
	mouse_filter=Control.MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events=false
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	visible=false
	var shade := ColorRect.new()
	shade.color=Color(0.015,0.02,0.025,0.985)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_panel=Panel.new()
	_panel.name="EffectsTheaterPanel"
	_panel.add_theme_stylebox_override("panel",Chrome.style("normal","lobby"))
	add_child(_panel)
	var skin := Chrome.new()
	skin.surface="lobby"
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(skin)
	_title=_label("战斗演武 · 特效工坊",25)
	_note=_label("只读视觉样片 · 与正式战场共用像素角色和特效 · 大厅保持冻结",15)
	_close=_button("EffectsTheaterClose","返回大厅",close_theater)
	_focus=_button("EffectsTheaterFocus","扩大舞台",func(): _focused=not _focused; _focus.text="恢复列表" if _focused else "扩大舞台"; _layout())
	_audition=_button("EffectsTheaterAudition","◇ 试听：关",func(): set_audition_enabled(not _audition_enabled))
	_audition.toggle_mode=true
	_audition.tooltip_text="默认静音；主动开启后试听与真实素材同源的施放／命中样片。暂停、拖动时间轴、换技能会停止旧声音；演武不扣蓝、不制造真实命中。"
	_faction=_option("EffectsTheaterFaction")
	for id: String in Factions.IDS:
		_faction.add_item(str(Factions.profile(id).label))
		_faction.set_item_metadata(_faction.item_count-1,id)
	_faction.add_item("野外生灵 · 60变体")
	_faction.set_item_metadata(_faction.item_count-1,"NEUTRAL")
	_faction.item_selected.connect(func(index: int): set_faction(str(_faction.get_item_metadata(index))))
	_search=LineEdit.new()
	_search.name="EffectsTheaterSearch"
	_search.placeholder_text="搜索英雄 / 兵种"
	_search.add_theme_font_override("font",FontClass.readable())
	_search.add_theme_font_size_override("font_size",17)
	_search.text_changed.connect(func(_text: String): _filter_cards())
	_panel.add_child(_search)
	_actors_scroll=ScrollContainer.new()
	_actors_scroll.name="EffectsTheaterRoster"
	_actors_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_actors_scroll.mouse_filter=Control.MOUSE_FILTER_STOP
	_actors_scroll.mouse_force_pass_scroll_events=false
	_actors_scroll.scroll_deadzone=12
	_panel.add_child(_actors_scroll)
	_actors_grid=GridContainer.new()
	_actors_grid.columns=2
	_actors_grid.add_theme_constant_override("h_separation",8)
	_actors_grid.add_theme_constant_override("v_separation",8)
	_actors_scroll.add_child(_actors_grid)
	_stage=Stage.new()
	_stage.name="EffectsTheaterStage"
	_panel.add_child(_stage)
	_effects=_option("EffectsTheaterAbility")
	_effects.item_selected.connect(func(index: int): select_ability(str(_effects.get_item_metadata(index))))
	_rank=_option("EffectsTheaterRank")
	_rank.item_selected.connect(func(index: int): _stage.rank=index+1; _refresh_description(); replay())
	_play=_button("EffectsTheaterPlay","Ⅱ 暂停",func(): set_playing(not _playing))
	_replay=_button("EffectsTheaterReplay","↺ 重播",replay)
	_speed=_option("EffectsTheaterSpeed")
	for value: float in [0.25,0.5,1.0,1.5]:
		_speed.add_item(str(value)+"×")
		_speed.set_item_metadata(_speed.item_count-1,value)
	_speed.select(2)
	_speed.item_selected.connect(func(index: int): _rate=float(_speed.get_item_metadata(index)))
	_zoom=_option("EffectsTheaterZoom")
	for value: float in [1.0,1.5,2.0]:
		_zoom.add_item("%.1f× 像素"%value)
		_zoom.set_item_metadata(_zoom.item_count-1,value)
	_zoom.select(1)
	_zoom.item_selected.connect(func(index: int): _stage.magnification=float(_zoom.get_item_metadata(index)); _stage.queue_redraw())
	_background=_option("EffectsTheaterBackground")
	_background.add_item("种族地面")
	_background.add_item("暗色底")
	_background.select(1)
	_speed.tooltip_text="播放速度：1/4速、半速、常速、加速"
	_zoom.tooltip_text="像素放大：最近邻缩放，角色身份与正式战场一致"
	_background.tooltip_text="切换种族地面或暗色校色底，检查亮暗边缘"
	_background.item_selected.connect(func(index: int): _stage.background="FIELD" if index==0 else "DARK"; _stage.queue_redraw())
	_mirror=_button("EffectsTheaterMirror","⇄ 朝向",func(): _stage.facing=-_stage.facing; _stage.queue_redraw())
	_timeline=HSlider.new()
	_timeline.name="EffectsTheaterTimeline"
	_timeline.min_value=0
	_timeline.max_value=Catalog.CYCLE-0.001
	_timeline.step=0.001
	_timeline.custom_minimum_size=Vector2(100,28)
	_timeline.value_changed.connect(func(value: float):
		if not _timeline_sync:
			set_playing(false)
			_elapsed=value
			_refresh_stage())
	_panel.add_child(_timeline)
	_description=RichTextLabel.new()
	_description.name="EffectsTheaterDescription"
	_description.bbcode_enabled=true
	_description.add_theme_font_override("normal_font",FontClass.readable())
	_description.add_theme_font_override("bold_font",FontClass.readable())
	_description.add_theme_font_size_override("normal_font_size",17)
	_description.add_theme_color_override("default_color",Color("d7d5be"))
	_description.scroll_active=true
	_panel.add_child(_description)
	resized.connect(_layout)
	visibility_changed.connect(func():
		if not is_visible_in_tree(): set_playing(false); set_audition_enabled(false); _hide_popups())
	_layout()
	set_faction("HUMAN")

func open_for_faction(id: String) -> void:
	set_faction(id)
	visible=true
	move_to_front()
	replay()
	set_playing(true)

func close_theater() -> void:
	set_playing(false)
	set_audition_enabled(false)
	_hide_popups()
	visible=false
	_search.release_focus()

func _exit_tree()->void:
	if is_instance_valid(_audition_audio):_audition_audio.cancel_preview()

func _hide_popups() -> void:
	for option: OptionButton in [_faction,_effects,_rank,_speed,_zoom,_background]:
		if option!=null: option.get_popup().hide()

func set_faction(id: String) -> void:
	if id not in Factions.IDS and id!="NEUTRAL": return
	_faction_id=id
	for index: int in range(_faction.item_count):
		if _faction.get_item_metadata(index)==id: _faction.select(index)
	_actors=Catalog.actors(id)
	for node: Node in _actors_grid.get_children():
		_actors_grid.remove_child(node)
		node.queue_free()
	_cards.clear()
	_search.text=""
	for actor: Dictionary in _actors:
		var card := ActorCard.new()
		card.name="EffectsActor_"+str(actor.id).replace(":","_")
		card.actor=actor
		card.tooltip_text=str(actor.label)+"\n"+str(actor.description)
		card.pressed.connect(select_actor.bind(str(actor.id)))
		_actors_grid.add_child(card)
		_cards[str(actor.id)]=card
	if not _actors.is_empty(): select_actor(str(_actors[0].id))
	_actors_scroll.scroll_vertical=0

func select_actor(id: String) -> void:
	for actor: Dictionary in _actors:
		if actor.id!=id: continue
		_actor=actor.duplicate(true)
		_abilities=Catalog.abilities(actor)
		_effects.clear()
		for ability: Dictionary in _abilities:
			_effects.add_item(str(ability.label))
			_effects.set_item_metadata(_effects.item_count-1,str(ability.id))
			_effects.get_popup().set_item_tooltip(_effects.item_count-1,str(ability.description))
		for key: String in _cards:
			_cards[key].selected=key==id
			_cards[key].queue_redraw()
		select_ability("ATTACK")
		return

func select_ability(id: String) -> void:
	for ability: Dictionary in _abilities:
		if ability.id!=id: continue
		_ability=ability.duplicate(true)
		for index: int in range(_effects.item_count):
			if _effects.get_item_metadata(index)==id: _effects.select(index)
		_rank.clear()
		for number: int in range(1,int(ability.max_rank)+1): _rank.add_item("英雄 Lv.%d"%number if ability.kind=="INNATE" else "%d 阶"%number)
		_rank.disabled=int(ability.max_rank)<=1
		_stage.rank=1
		_refresh_description()
		replay()
		return

func _filter_cards() -> void:
	var term := _search.text.strip_edges().to_lower()
	for actor: Dictionary in _actors:
		_cards[str(actor.id)].visible=term.is_empty() or (str(actor.label)+str(actor.group)+str(actor.id)).to_lower().contains(term)

func _refresh_description() -> void:
	if _actor.is_empty() or _ability.is_empty(): return
	_title.text="战斗演武 · "+str(_actor.label)
	var sample := Catalog.sample(_actor,_ability,int(_stage.rank),0.65)
	var description := str(_ability.description)
	var full_description := description
	if _ability.kind in ["SKILL","PASSIVE"]:
		full_description=Catalog.Heroes.describe_skill(sample.skill)
		description=_skill_summary(sample.skill)
	if _ability.kind=="INNATE": description="英雄 Lv.%d · %s\n此处展示该等级天赋标识；不演算触发条件。"%[int(_stage.rank),str(sample.unit.get("innate",{}).get("description",description))]
	_description.text="[color=#e4c584]%s[/color]  ·  %s\n%s\n[color=#9da997]拖动时间轴可逐帧观察；仅视觉样片，不进行资源扣除、伤害或范围判定。[/color]"%[str(_ability.label),str(_actor.group),description]
	_effects.tooltip_text=full_description
	_description.tooltip_text=full_description

func _skill_summary(skill: Dictionary) -> String:
	if bool(skill.get("passive",false)): return Catalog.Heroes.describe_skill(skill)
	var terms: Array[String]=["%d阶%s"%[int(skill.get("level",1)),"大招" if bool(skill.get("ultimate",false)) else "技能"]]
	for field: String in ["damage","heal","ally_heal","damage_percent","armor_bonus"]:
		if skill.has(field): terms.append(str({"damage":"基础伤害","heal":"治疗","ally_heal":"友军治疗","damage_percent":"普攻提升","armor_bonus":"护甲+"}[field])+str(skill[field])+("%" if field=="damage_percent" else ""))
	terms.append("蓝量%d"%int(skill.get("mana_cost",0)))
	terms.append("冷却%.1f秒"%(float(skill.get("max_cooldown_ticks",skill.get("cooldown_ticks",0)))*0.05))
	terms.append("最多%d目标"%int(skill.get("max_targets",1)))
	var control := str(skill.get("effect",""))
	if control in ["STUN","ROOT","SLOW"]: terms.append(str({"STUN":"眩晕","ROOT":"定身","SLOW":"减速"}[control]))
	elif not str(skill.get("status_kind","")).is_empty(): terms.append(str(Catalog.STATUS_NAMES.get(str(skill.status_kind),str(skill.status_kind))))
	return " · ".join(terms)+"\n完整说明：悬浮／长按技能选项或本说明区。"

func set_playing(value: bool) -> void:
	_playing=value and is_visible_in_tree()
	if not _playing and is_instance_valid(_audition_audio):_audition_audio.cancel_preview()
	if _play!=null: _play.text="Ⅱ 暂停" if _playing else "▶ 播放"

func set_audition_enabled(value:bool)->void:
	_audition_enabled=value and is_visible_in_tree()
	if _audition_enabled and not is_instance_valid(_audition_audio):
		_audition_audio=get_tree().get_first_node_in_group("strategic_audio_feedback")
		if _audition_audio==null:
			_audition_audio=LocalAudioFactory.create();_audition_audio.name="TheaterAudioFeedback";add_child(_audition_audio)
	if is_instance_valid(_audition_audio):_audition_audio.cancel_preview()
	if _audition!=null:
		_audition.text="◆ 试听：开" if _audition_enabled else "◇ 试听：关"
		_audition.set_pressed_no_signal(_audition_enabled)
	if _audition_enabled:replay()

func replay() -> void:
	if is_instance_valid(_audition_audio):_audition_audio.cancel_preview()
	_audition_serial+=1;_audition_cycle=0
	_elapsed=0
	_refresh_stage()

func advance(delta: float) -> void:
	if not _playing or not is_visible_in_tree() or not is_finite(delta) or delta<=0: return
	var until:=_elapsed+minf(delta,1.0)*_rate
	if _audition_enabled and is_instance_valid(_audition_audio):_play_audio_markers(_elapsed,minf(until,Catalog.CYCLE))
	if until>=Catalog.CYCLE:
		_audition_cycle+=1
		if _audition_enabled and is_instance_valid(_audition_audio):_play_audio_markers(0.0,fposmod(until,Catalog.CYCLE))
	_elapsed=fposmod(until,Catalog.CYCLE)
	_refresh_stage()

func _play_audio_markers(previous:float,current:float)->void:
	# Sync selection before requesting explicit Stage preview cues. _draw is not
	# required and can never cause audio, so screenshots/seek remain silent.
	_stage.actor=_actor;_stage.ability=_ability
	for event:Dictionary in _stage.preview_audio_events_between(previous,current):
		_audition_audio.record_preview(event.cue,"%d:%d:%s:%s:%s"%[_audition_serial,_audition_cycle,str(_actor.get("id","")),str(_ability.get("id","")),str(event.marker)])

func _process(delta: float) -> void: advance(delta)

func _refresh_stage() -> void:
	if _stage==null: return
	_stage.actor=_actor
	_stage.ability=_ability
	_stage.elapsed=_elapsed
	_stage.queue_redraw()
	if _timeline!=null:
		_timeline_sync=true
		_timeline.value=_elapsed
		_timeline_sync=false

func preview_state() -> Dictionary:
	return {"faction":_faction_id,"actor":str(_actor.get("id","")),"ability":str(_ability.get("id","")),"elapsed":_elapsed,"playing":_playing,"speed":_rate,"rank":int(_stage.rank),"visual_only":true,"session_reference":false,"audition_enabled":_audition_enabled,"audition_serial":_audition_serial,"audition_cycle":_audition_cycle}

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		close_theater()
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch: accept_event()

func _option(node_name: String) -> OptionButton:
	var option := OptionButton.new()
	option.name=node_name
	option.add_theme_font_override("font",FontClass.readable())
	option.add_theme_font_size_override("font_size",17)
	for state: String in ["normal","hover","pressed","disabled"]: option.add_theme_stylebox_override(state,Chrome.style(state,"stone"))
	var popup := option.get_popup()
	popup.add_theme_font_override("font",FontClass.readable())
	popup.add_theme_font_size_override("font_size",20)
	popup.add_theme_constant_override("v_separation",15)
	popup.add_theme_stylebox_override("panel",Chrome.style("normal","stone"))
	_panel.add_child(option)
	return option

func _button(node_name: String, caption: String, callback: Callable) -> Button:
	var button := TextButton.new()
	button.name=node_name
	button.text=caption
	button.pressed.connect(callback)
	_panel.add_child(button)
	return button

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text=text
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",FontClass.readable())
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("e4d3ac"))
	_panel.add_child(label)
	return label

func _layout() -> void:
	if _panel==null: return
	_panel.size=Vector2(minf(1224,maxf(size.x-32,960)),minf(672,maxf(size.y-24,612)))
	_panel.position=((size-_panel.size)*0.5).round()
	var width := _panel.size.x
	var height := _panel.size.y
	_title.position=Vector2(24,16); _title.size=Vector2(width-555,35)
	_note.position=Vector2(24,53); _note.size=Vector2(width-224,25)
	_close.position=Vector2(width-178,20); _close.size=Vector2(152,52)
	_focus.position=Vector2(width-332,20); _focus.size=Vector2(144,52)
	_audition.position=Vector2(width-488,20);_audition.size=Vector2(144,52)
	for control: Control in [_faction,_search,_actors_scroll,_description]: control.visible=not _focused
	_faction.position=Vector2(22,94); _faction.size=Vector2(270,48)
	_search.position=Vector2(22,150); _search.size=Vector2(270,42)
	_actors_scroll.position=Vector2(22,204); _actors_scroll.size=Vector2(280,height-226)
	var left := 22.0 if _focused else 318.0
	var stage_width := width-left-24
	var columns := 3 if stage_width<800 else 6
	var extra_row := 54.0 if columns==3 else 0.0
	_stage.position=Vector2(left,94); _stage.size=Vector2(stage_width,height-355-extra_row)
	var below := height-249-extra_row
	_effects.position=Vector2(left,below); _effects.size=Vector2(stage_width-112,46)
	_rank.position=Vector2(width-124,below); _rank.size=Vector2(100,46)
	var y := below+56
	var gap := 8.0
	var unit_width := (stage_width-gap*(columns-1))/columns
	var controls: Array[Control]=[_play,_replay,_speed,_zoom,_background,_mirror]
	for index: int in range(controls.size()):
		controls[index].position=Vector2(left+(unit_width+gap)*(index%columns),y+54*floori(float(index)/columns))
		controls[index].size=Vector2(unit_width,46)
	_timeline.position=Vector2(left,y+52+extra_row); _timeline.size=Vector2(stage_width,26)
	_description.position=Vector2(left,y+85+extra_row); _description.size=Vector2(stage_width,height-y-97-extra_row)
	if _focused:
		_stage.size.y=height-268-extra_row
		below=height-162-extra_row
		_effects.position.y=below; _rank.position.y=below
		y=below+56
		for index: int in range(controls.size()): controls[index].position.y=y+54*floori(float(index)/columns)
		_timeline.position.y=y+52+extra_row
