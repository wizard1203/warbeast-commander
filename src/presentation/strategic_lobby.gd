extends Control
## A detached match-configuration projection, not a second simulation. Every
## change is validated by GameSession before this view receives effective setup.

signal configuration_requested(request: Dictionary)
signal start_requested
signal hero_arena_requested
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const TextButton = preload("res://src/presentation/strategic_text_button.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const FieldGuide = preload("res://src/presentation/strategic_pregame_guide.gd")
const EffectsTheater = preload("res://src/presentation/strategic_effects_theater.gd")
const ReplayReview = preload("res://src/presentation/strategic_replay_review_m69.gd")
var catalog: Dictionary = {}
var effective: Dictionary = {}
var _signature := ""
var _panel: Panel
var _content: Control
var _message: Label
var _request: Dictionary = {}
var _field_guide: Control
var _effects_theater: Control
var _replay_review: Control

func _ready() -> void:
	name = "StrategicMatchLobby"
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events = false
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.028, 0.027, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_panel = Panel.new()
	_panel.name = "LobbyConfigurationPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", Chrome.style("normal", "lobby"))
	add_child(_panel)
	var material := Chrome.new()
	material.surface = "lobby"
	material.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(material)
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.position = Vector2(34, 26)
	_panel.add_child(_content)
	_field_guide = FieldGuide.new()
	_field_guide.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_field_guide)
	_effects_theater = EffectsTheater.new()
	_effects_theater.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_effects_theater)
	_replay_review = ReplayReview.new()
	_replay_review.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_replay_review.z_index = 90
	add_child(_replay_review)
	resized.connect(_layout)
	_layout()
	_rebuild()

func refresh(public_catalog: Dictionary, setup: Dictionary) -> void:
	catalog = public_catalog.duplicate(true)
	effective = setup.duplicate(true)
	var signature := JSON.stringify(effective)
	if signature != _signature:
		_signature = signature
		_rebuild()

func show_error(error: String) -> void:
	if _message != null: _message.text = "无法配置：" + error

func show_configured() -> void:
	if _message == null: return
	var first: Dictionary = effective.get("sides", [{}])[0]
	var difficulties: Array[String] = []
	for side: Dictionary in effective.get("sides", []):
		if side.get("controller") != "AI": continue
		var label := str({"EASY":"简单","STANDARD":"标准","HARD":"困难"}.get(str(side.get("difficulty_id", "EASY")), "简单"))
		if label not in difficulties: difficulties.append(label)
	_message.text = "✓ 配置已生效 · %s · %d方\n玩家1：%s / %s · 电脑：%s" % [str(effective.get("name", "地图")), effective.get("sides", []).size(), str(Factions.profile(str(first.get("faction_id", "HUMAN"))).get("label", "")), "本机" if first.get("controller") == "HUMAN" else "电脑观察", "/".join(difficulties) if not difficulties.is_empty() else "无"]

func _layout() -> void:
	if _panel == null: return
	_panel.size = Vector2(950, 618)
	_panel.position = (size - _panel.size) * 0.5
	_content.size = _panel.size - Vector2(68, 52)

func _label(text: String, point: Vector2, dimensions: Vector2, font_size: int = 19) -> Label:
	var result := Label.new()
	result.text = text
	result.position = point
	result.size = dimensions
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color("e6ddc7"))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(result)
	return result

func _option(node_name: String, point: Vector2, dimensions: Vector2) -> OptionButton:
	var option := OptionButton.new()
	option.name = node_name
	option.position = point
	option.size = dimensions
	option.custom_minimum_size = dimensions
	option.mouse_filter = Control.MOUSE_FILTER_STOP
	option.mouse_force_pass_scroll_events = false
	option.add_theme_font_size_override("font_size", 19)
	for state: String in ["normal", "hover", "pressed", "disabled"]: option.add_theme_stylebox_override(state, Chrome.style(state, "stone"))
	_content.add_child(option)
	return option

func _add(option: OptionButton, text: String, id: String) -> void:
	option.add_item(text)
	option.set_item_metadata(option.item_count - 1, id)
	option.get_popup().set_item_tooltip(option.item_count - 1, native_menu_help(text))

static func native_menu_help(text: String) -> String:
	# PopupMenu is a Window, not Control: its item tooltip does not use the
	# shared Control gate. Bound its native text without truncating information.
	# A CJK glyph occupies about two Latin columns at the same native font.
	var result := ""
	var columns := 0
	for character: String in text:
		if character == "\n": result += character; columns = 0; continue
		var width := 2 if character.unicode_at(0)>=0x2e80 else 1
		if columns+width>44: result += "\n"; columns = 0
		result += character
		columns += width
	return result

func _choose(option: OptionButton, id: String) -> void:
	for index: int in range(option.item_count):
		if str(option.get_item_metadata(index)) == id:
			option.select(index)
			option.tooltip_text = option.get_item_text(index)
			return

func _records(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in catalog.get(key, []):
		var record: Dictionary = value if value is Dictionary else {"id":str(value), "label":str(value)}
		if key == "factions" and not Factions.is_valid(str(record.get("id",record.get("faction_id","")))): continue
		result.append(record)
	return result

func _map_id(value: Dictionary) -> String:
	return str(value.get("id", value.get("map_id", "")))

func _maximum(value: Dictionary) -> int:
	return int(value.get("max_participants", value.get("max_players", 2)))

func _rebuild() -> void:
	if _content == null: return
	for node: Node in _content.get_children():
		_content.remove_child(node)
		node.queue_free()
	var sides: Array = effective.get("sides", [])
	_request = {"map_id":str(effective.get("map_id", "borderlands")), "participants":[]}
	for side: Dictionary in sides: _request.participants.append({"faction_id":str(side.get("faction_id", "HUMAN")), "controller":str(side.get("controller", "AI")), "difficulty_id":str(side.get("difficulty_id", "EASY")),"starting_hero":str(side.get("starting_hero",Factions.default_hero(str(side.get("faction_id","HUMAN")))))})
	if _request.participants.is_empty(): _request.participants = [{"faction_id":"HUMAN", "controller":"HUMAN", "difficulty_id":"EASY"}, {"faction_id":"HUMAN", "controller":"AI", "difficulty_id":"EASY"}]
	_label("魔兽指挥官", Vector2.ZERO, Vector2(480, 40), 30)
	_label("首发三族版 · 单击指挥，军团作战", Vector2(0, 44), Vector2(480, 30), 20)
	_label("选择地图、种族和初始英雄，准备好后开始对局。", Vector2(0, 91), Vector2(860, 24), 16)
	var maps := _option("LobbyMapOption", Vector2(0, 125), Vector2(468, 50))
	var map: Dictionary = {}
	for record: Dictionary in _records("maps"):
		_add(maps, str(record.get("label", record.get("name", _map_id(record)))) + (" · 演练 / DEBUG" if record.get("debug", false) else ""), _map_id(record))
		if _map_id(record) == _request.map_id: map = record
	_choose(maps, _request.map_id)
	maps.item_selected.connect(func(index: int): _change_map(str(maps.get_item_metadata(index))))
	var count := _option("LobbyParticipantCount", Vector2(488, 125), Vector2(184, 50))
	for amount: int in range(2, _maximum(map) + 1): _add(count, "%d 方混战" % amount, str(amount))
	_choose(count, str(_request.participants.size()))
	count.item_selected.connect(func(index: int): _change_count(int(count.get_item_metadata(index))))
	var guide := TextButton.new()
	guide.name = "LobbyFieldGuideButton"
	guide.text = "战前图鉴\n种族 · 攻防"
	# Arena owns an existing appearance-seed button beside the map selector.
	# Keep the guide in the otherwise empty upper-right title area.
	guide.position = Vector2(736,10)
	guide.size = Vector2(136,64)
	guide.custom_minimum_size = guide.size
	guide.tooltip_text = "查阅各族兵种、英雄、建筑、科技、物品与野怪资料。"
	guide.pressed.connect(func(): _field_guide.open_for_faction(str(_request.participants[0].faction_id)))
	_content.add_child(guide)
	var theater := TextButton.new()
	theater.name = "LobbyEffectsTheaterButton"
	theater.text = "战斗演武\n普攻 · 技能特效"
	theater.position = Vector2(588, 10)
	theater.size = Vector2(138, 64)
	theater.custom_minimum_size = theater.size
	theater.tooltip_text = "观看普通攻击、技能、天赋和状态特效。可暂停、慢放或重播。"
	theater.pressed.connect(func(): _effects_theater.open_for_faction(str(_request.participants[0].faction_id)))
	_content.add_child(theater)
	var arena := TextButton.new()
	arena.name = "LobbyHeroArenaButton"
	arena.text = "英雄竞技场\n阵容 · 战斗统计"
	arena.position = Vector2(440,10)
	arena.size = Vector2(138,64)
	arena.custom_minimum_size = arena.size
	arena.tooltip_text = "设置英雄等级、装备和兵力，进行单挑或团战。配置仅用于竞技场。"
	arena.pressed.connect(func(): hero_arena_requested.emit())
	_content.add_child(arena)
	var replay := TextButton.new()
	replay.name = "LobbyReplayButton"
	replay.text = "快速模拟\n录像 · 统计"
	replay.position = Vector2(0,490)
	replay.size = Vector2(156,64)
	replay.custom_minimum_size = replay.size
	replay.tooltip_text = "快速模拟电脑对战或三英雄竞技场，再用进度条与播放速度查看战斗回放。"
	replay.pressed.connect(func(): _replay_review.open_for_match(effective.get("request",{}),1701))
	_content.add_child(replay)
	var map_bounds: Variant = map.get("bounds", effective.get("bounds", Rect2i()))
	var dimensions := ""
	if map_bounds is Rect2i or map_bounds is Rect2: dimensions = "%d × %d" % [int(map_bounds.size.x), int(map_bounds.size.y)]
	var map_facts := _label("%s · %s" % [dimensions, "演练：T2 / 全建筑 / 1200库存 / 部分占领" if effective.get("debug", false) else "正常对局 · 有限采集 / 真实地形"], Vector2(0, 185), Vector2(882, 30), 17)
	map_facts.name = "LobbyMapFacts"
	map_facts.set_meta("map_id", _request.map_id)
	map_facts.set_meta("debug", bool(effective.get("debug", false)))
	_label("玩家 / 阵营色", Vector2(0, 232), Vector2(134, 28), 17)
	_label("种族", Vector2(140, 232), Vector2(180, 28), 17)
	_label("免费初始英雄", Vector2(334, 232), Vector2(210, 28), 17)
	_label("控制方式", Vector2(552, 232), Vector2(150, 28), 17)
	_label("电脑难度", Vector2(710, 232), Vector2(162, 28), 17)
	for index: int in range(_request.participants.size()):
		var participant: Dictionary = _request.participants[index]
		var row := 266 + index * 54
		var side_id: String = str(sides[index].get("side_id", "PLAYER")) if index < sides.size() else ["PLAYER", "AI", "AI_2", "AI_3"][index]
		var identity := _label("■ %s" % Palette.side_label(side_id), Vector2(0, row + 10), Vector2(134, 40), 18)
		identity.add_theme_color_override("font_color", Palette.side_color(side_id))
		var faction := _option("LobbyFaction_%d" % index, Vector2(140, row), Vector2(180, 48))
		for record: Dictionary in _records("factions"):
			var id := str(record.get("id", record.get("faction_id", "")))
			_add(faction, str(Factions.profile(id).get("label", record.get("label", id))) + " · " + str({"HUMAN":"人族","MACHINE":"机械","FOREST":"森林"}.get(id, "")), id)
			faction.get_popup().set_item_tooltip(faction.item_count - 1, native_menu_help(Factions.identity_text(id)))
		_choose(faction, participant.faction_id)
		faction.tooltip_text = Factions.identity_text(str(participant.faction_id)) + "\n单击更换种族；悬浮或长按阅读背景与战术。"
		faction.item_selected.connect(func(selection: int): _change_participant(index, "faction_id", str(faction.get_item_metadata(selection))))
		var hero_choice := _option("LobbyStartingHero_%d" % index, Vector2(334,row),Vector2(210,48))
		for archetype: String in Factions.heroes_for(participant.faction_id):
			var profile: Dictionary = Heroes.profile(archetype)
			_add(hero_choice,str(profile.get("name",archetype)),archetype)
			hero_choice.get_popup().set_item_tooltip(hero_choice.item_count-1,native_menu_help(str(profile.get("description",""))+"\n开局免费 · 5人口；死亡后按等级付费复活。"))
		_choose(hero_choice,str(participant.get("starting_hero",Factions.default_hero(participant.faction_id))))
		hero_choice.tooltip_text += "\n从本族全部英雄中选择；开局免费，仍占5人口。"
		hero_choice.item_selected.connect(func(selection: int): _change_participant(index,"starting_hero",str(hero_choice.get_item_metadata(selection))))
		var controller := _option("LobbyController_%d" % index, Vector2(552, row), Vector2(150, 48))
		for record: Dictionary in _records("controllers"):
			var id := str(record.get("id", record.get("controller", "")))
			if id == "HUMAN" and index != 0: continue
			_add(controller, "玩家操控" if id == "HUMAN" else "规则电脑", id)
		_choose(controller, participant.controller)
		controller.item_selected.connect(func(selection: int): _change_participant(index, "controller", str(controller.get_item_metadata(selection))))
		var difficulty := _option("LobbyDifficulty_%d" % index, Vector2(710, row), Vector2(162, 48))
		for record: Dictionary in _records("difficulties"):
			var id := str(record.get("id", record.get("difficulty_id", "")))
			_add(difficulty, str({"EASY":"简单", "STANDARD":"标准", "HARD":"困难"}.get(id, record.get("label", id))), id)
		_choose(difficulty, participant.difficulty_id)
		difficulty.disabled = participant.controller != "AI"
		difficulty.item_selected.connect(func(selection: int): _change_participant(index, "difficulty_id", str(difficulty.get_item_metadata(selection))))
	_message = _label("本机操控玩家1，其余为电脑（非联网）。\n玩家1选电脑：全电脑观察，不发军令。", Vector2(168, 490), Vector2(380, 52), 16)
	_message.name = "LobbyFeedback"
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.clip_text = true
	_message.size = Vector2(380, 52)
	var start := TextButton.new()
	start.name = "LobbyStartBattleButton"
	start.text = "▶ 开始交战"
	start.position = Vector2(570, 490)
	start.size = Vector2(302, 64)
	start.custom_minimum_size = start.size
	start.tooltip_text = "单击一次建立所选地图和全部实际参与方，开始经济、占领与战斗。不会自动开始。"
	start.pressed.connect(func(): start_requested.emit())
	_content.add_child(start)

func _change_map(id: String) -> void:
	_request.map_id = id
	for record: Dictionary in _records("maps"):
		if _map_id(record) == id:
			while _request.participants.size() > _maximum(record): _request.participants.pop_back()
	configuration_requested.emit(_request.duplicate(true))

func _change_count(count: int) -> void:
	while _request.participants.size() > count: _request.participants.pop_back()
	while _request.participants.size() < count: _request.participants.append({"faction_id":"HUMAN", "controller":"AI", "difficulty_id":"EASY"})
	configuration_requested.emit(_request.duplicate(true))

func _change_participant(index: int, key: String, value: String) -> void:
	if key == "controller" and value == "HUMAN" and index != 0: return
	if key == "faction_id" and not Factions.is_valid(value): return
	_request.participants[index][key] = value
	if key == "faction_id": _request.participants[index]["starting_hero"] = Factions.default_hero(value)
	configuration_requested.emit(_request.duplicate(true))

func _gui_input(event: InputEvent) -> void:
	# Outside presses are intentionally inert. Neither escape nor backdrop close
	# can reveal a battlefield while the authoritative host is still in LOBBY.
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag: accept_event()
