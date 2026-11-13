extends VBoxContainer
## Read-only inspection of the real arena observation. No commands or grants.
signal actor_selected(id: String)
const Status = preload("res://src/presentation/strategic_hero_status_readout.gd")
const ActorInspectionV4 = preload("res://src/presentation/strategic_actor_inspection_readout.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const Fonts = preload("res://src/presentation/strategic_font.gd")
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const StatisticsLabelsR10 = preload("res://src/presentation/strategic_hero_statistics_panel_m69.gd")
var _roster: HBoxContainer
var _title: Label
var _investment_r19: Label
var _tabs: TabBar
var _icons: HBoxContainer
var _text: RichTextLabel
var _model: Dictionary = {}
var _receipt: Dictionary = {}
var _history: Array[Dictionary] = []
var _seen: Dictionary = {}
var _roster_buttons: Dictionary = {}
var _selected := ""
var _tab_identity := ""
var _focus_index := -1
var _facts: Array[Dictionary] = []

func _ready() -> void:
	name = "ArenaLoadoutInspection"
	custom_minimum_size.y = 185
	add_theme_constant_override("separation",3)
	_roster = HBoxContainer.new()
	_roster.name = "ArenaHeroSelection"
	_roster.add_theme_constant_override("separation",3)
	add_child(_roster)
	_title = Label.new()
	_title.name = "ArenaSelectedVitals"
	_title.add_theme_font_override("font",Fonts.readable())
	_title.add_theme_font_size_override("font_size",13)
	_title.add_theme_color_override("font_color",Color("dfd1ae"))
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_title)
	_investment_r19=Label.new()
	_investment_r19.name="ArenaSelectedInvestmentR19"
	_investment_r19.add_theme_font_override("font",Fonts.readable())
	_investment_r19.add_theme_font_size_override("font_size",12)
	_investment_r19.add_theme_color_override("font_color",Color("c8b67d"))
	_investment_r19.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(_investment_r19)
	_tabs = TabBar.new()
	_tabs.name = "ArenaInspectionTabs"
	for label: String in ["属性","技能","背包 4+2","实时状态","真实回执","预算","战斗统计"]: _tabs.add_tab(label)
	_tabs.add_theme_font_override("font",Fonts.readable())
	_tabs.add_theme_font_size_override("font_size",13)
	_tabs.tab_changed.connect(func(_index: int): _focus_index=-1; _render())
	add_child(_tabs)
	_icons = HBoxContainer.new()
	_icons.name = "ArenaInspectionIcons"
	_icons.add_theme_constant_override("separation",4)
	add_child(_icons)
	_text = RichTextLabel.new()
	_text.name = "ArenaUnitDetails"
	_text.bbcode_enabled = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size.y = 45
	_text.add_theme_font_override("normal_font",Fonts.readable())
	_text.add_theme_font_override("bold_font",Fonts.readable())
	_text.add_theme_font_size_override("normal_font_size",13)
	_text.add_theme_stylebox_override("normal",Chrome.style("normal","stone"))
	_text.add_theme_color_override("default_color",Color("d7d8bc"))
	add_child(_text)

func clear_history() -> void:
	_history.clear()
	_seen.clear()
	_focus_index = -1

func set_budget_receipt(receipt: Dictionary) -> void:
	_receipt = receipt.duplicate(true)
	set_meta("budget_receipt",_receipt.duplicate(true))
	if is_instance_valid(_tabs): _render()

func selected_readout() -> Dictionary:
	var result := _model.duplicate(true)
	result["budget_receipt"] = _receipt.duplicate(true)
	return result

func refresh(observation: Dictionary, config: Dictionary, selected_id: String, force: Dictionary = {}) -> void:
	if not is_instance_valid(_roster): return
	if _selected != selected_id: _focus_index=-1
	_selected = selected_id
	var retained_ids := {}
	for event: Dictionary in observation.get("combat_feedback_events",[]):
		var key := str(event.get("event_id",""))
		retained_ids[key] = true
		if key.is_empty() or _seen.has(key): continue
		_seen[key] = true
		_history.append(event.duplicate(true))
	while _history.size()>160:
		_history.pop_front()
	# The combat ring can retain 256 events while the display keeps 160. A
	# display eviction is not permission to replay that same receipt next refresh.
	for event: Dictionary in _history: retained_ids[str(event.get("event_id",""))] = true
	for key: String in _seen.keys():
		if not retained_ids.has(key): _seen.erase(key)
	var context := Status.prepare_borrowed_m76(observation)
	var body: Dictionary = context.bodies.get(selected_id,{})
	var hero: Dictionary = context.heroes.get(selected_id,{})
	var wanted := {}
	var roster_index := 0
	for side: String in ["PLAYER","AI"]:
		var ordinal := 0
		for officer: Dictionary in observation.get("heroes",{}).get("officers",[]):
			if str(officer.get("side","")) != side: continue
			var id := str(officer.get("id",""))
			wanted[id] = true
			var button: Button = _roster_buttons.get(id)
			if not is_instance_valid(button):
				button = Button.new()
				button.name = "ArenaHeroSelect_"+side+"_"+str(ordinal)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.custom_minimum_size = Vector2(0,27)
				button.add_theme_font_override("font",Fonts.readable())
				button.add_theme_font_size_override("font_size",12)
				button.clip_text = true
				button.pressed.connect(func(): actor_selected.emit(id))
				for state: String in ["normal","hover","pressed","focus"]: button.add_theme_stylebox_override(state,Chrome.style(state,"command"))
				_roster.add_child(button)
				_roster_buttons[id] = button
			var title := str(officer.get("name",id))
			button.text = ("左 " if side=="PLAYER" else "右 ")+title+" %d级"%int(officer.get("level",1))+(" †" if int(officer.get("hp",0))<=0 else "")
			button.tooltip_text = title+" · 单击只读查阅，不下达命令。"
			button.modulate = Color("f6d778") if id==selected_id else Color("df9275") if side=="AI" else Color("b9c3aa")
			button.set_meta("actor_id",id)
			button.set_meta("selected",id==selected_id)
			# Existing duel buttons survive configure(); restore semantic order
			# rather than leaving newly added heroes after the old right button.
			_roster.move_child(button,roster_index)
			roster_index += 1
			ordinal += 1
	for id: String in _roster_buttons.keys():
		if wanted.has(id): continue
		var old: Button = _roster_buttons[id]
		_roster.remove_child(old)
		old.queue_free()
		_roster_buttons.erase(id)
	_model = {"id":selected_id,"body":body.duplicate(true),"hero":hero.duplicate(true),"status":{},"equipment":[],"consumables":[],"events":[],"initial":{},"statistics":{}}
	var ledger:Dictionary=observation.get("hero_statistics",{})
	for row:Dictionary in ledger.get("heroes",[])+ledger.get("units",[]):
		if str(row.get("hero_id",row.get("actor_id",row.get("unit_id",""))))==selected_id:
			_model.statistics=row.duplicate(true);break
	if not hero.is_empty():
		_model.status = Status.read(hero,context)
		var index := int(selected_id.get_slice("_arena_hero_",1))
		var initial_heroes: Array = config.get("sides",{}).get(str(hero.get("side","")),{}).get("heroes",[])
		if selected_id.contains("_arena_hero_") and index>=0 and index<initial_heroes.size(): _model.initial = initial_heroes[index].duplicate(true)
		_model.equipment = _slot_rows(hero,_model.initial,false)
		_model.consumables = _slot_rows(hero,_model.initial,true)
	else:
		# Reuse the actual ordinary-unit projection, including canonical V4
		# names, MP and live deadlines. This pure projection also preserves the
		# arena's existing ability to inspect an observed fallen body.
		_model.status = ActorInspectionV4._regular(body,context,"soldiers") if not body.is_empty() else {}
	_model["investment"]={}
	var identity: Dictionary = body if not body.is_empty() else _model.statistics
	var key := "hero" if not hero.is_empty() or str(identity.get("unit_type",""))=="hero" else str(identity.get("unit_type",""))
	for entry: Dictionary in force.get("sides",{}).get(str(identity.get("side","")),{}).get("rows",[]):
		if str(entry.get("key",""))==key: _model.investment=entry.duplicate(true);break
	for event: Dictionary in _history:
		if str(event.get("source",{}).get("id",""))==selected_id or str(event.get("target",{}).get("id",""))==selected_id: _model.events.append(event.duplicate(true))
	set_meta("selected_readout",_model.duplicate(true))
	_render()

static func _slot_rows(hero: Dictionary, initial: Dictionary, consumable: bool) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var key := "consumables" if consumable else "equipment"
	var ids: Array = initial.get(key,[]).duplicate()
	var current: Array = []
	if consumable:
		for slot: Dictionary in hero.get("consumable_slots",[]):
			if not str(slot.get("item_id","")).is_empty(): current.append(str(slot.item_id))
	else: current = hero.get("equipment",[]).duplicate()
	for id: String in current:
		if not ids.has(id): ids.append(id)
	var count := 2 if consumable else 4
	for index: int in range(count):
		var id := str(ids[index]) if index<ids.size() else ""
		var item: Dictionary = Items.ITEMS.get(id,{})
		var remaining := int(hero.get("inventory",{}).get(id,0)) if consumable else (1 if current.has(id) else 0)
		var state := "空位" if id.is_empty() else "持有" if remaining>0 else "已用／当前无存货" if consumable else "当前未持有（可能已掉落）"
		rows.append({"slot":index,"id":id,"name":str(item.get("name","空位")),"count":remaining,"present":remaining>0,"state":state,"description":str(item.get("description","未安装物品。")),"consumable":consumable})
	return rows

func _render() -> void:
	if not is_instance_valid(_text): return
	var body: Dictionary = _model.get("body",{})
	var hero: Dictionary = _model.get("hero",{})
	var status: Dictionary = _model.get("status",{})
	var title := str(hero.get("name",body.get("label",body.get("unit_type",_model.get("statistics",{}).get("name","单击单位查看")))))
	_title.text = "%s%s · HP %d/%d · MP %d/%d · 只读" % [title," %d级"%int(hero.get("level",1)) if not hero.is_empty() else "",int(body.get("hp",0)),int(body.get("max_hp",0)),int(body.get("mana",0)),int(body.get("max_mana",0))]
	if body.is_empty() and not _model.get("statistics",{}).is_empty():_title.text=title+" · 已离场 · 只读累计战绩"
	var investment: Dictionary = _model.get("investment",{})
	_investment_r19.text=""
	if not investment.is_empty():
		var price := "英雄训练赠予；不虚设招募单价" if bool(investment.hero) else "%d金币／个"%int(investment.gold_each)
		_investment_r19.text="%s · %d人口／个 · 本类开战人口占比%.1f%% · 存活%d／%d"%[price,int(investment.population_each),100.0*float(investment.population_share),int(investment.alive),int(investment.total)]
	var tab := _tabs.current_tab
	var facts: Array[Dictionary] = []
	var lines: Array[String] = []
	match tab:
		0:
			if hero.is_empty():
				lines.append("普攻 %s · 间隔 %.2fs · 护甲 %s（数值护甲后剩余 %.1f%%伤害）"%[str(body.get("damage","—")),float(body.get("attack_cooldown_ticks",0))/20.0,str(body.get("armor","—")),Damage.armor_factor(float(body.get("armor",0)))*100.0])
				lines.append("射程 %s · %s → %s\n%s"%[str(body.get("attack_range","—")),Damage.attack_label(str(body.get("attack_type",""))),Damage.armor_label(str(body.get("armor_type",""))),str(body.get("trait_description","普通兵按正式战斗规则结算。"))])
			else:
				var stats: Array[String] = []
				for stat: Dictionary in status.get("stats",[]): stats.append(str(stat.label)+" "+str(stat.value))
				lines.append(" · ".join(stats))
				lines.append("攻击／护甲类型：%s → %s；经验 %d／%s"%[Damage.attack_label(str(body.get("attack_type",""))),Damage.armor_label(str(body.get("armor_type",""))),int(status.get("xp",0)),str(status.get("next_level_xp",0)) if int(status.get("next_level_xp",0))>0 else "满级"])
				lines.append("基础＋净额外来自当前结算；HP/MP不拆分。恢复/增益请切换实时状态查看来源。")
		1:
			for skill: Dictionary in status.get("skills",[]):
				var state := "被动" if bool(skill.get("passive",false)) else "未学习" if int(skill.get("rank",0))<=0 else "冷却 %.1fs"%(float(skill.get("cooldown_ticks",0))/20.0) if int(skill.get("cooldown_ticks",0))>0 else "就绪" if int(body.get("mana",0))>=int(skill.get("mana_cost",0)) else "缺蓝"
				var text := "%s · %d/%d阶 · %s · 蓝%d · 基础CD %.1fs\n%s"%[str(skill.get("name",skill.id)),int(skill.get("rank",0)),int(skill.get("max_rank",3)),state,int(skill.get("mana_cost",0)),float(skill.get("max_cooldown_ticks",0))/20.0,str(skill.get("description",""))]
				facts.append({"id":str(skill.id),"caption":"%d阶"%int(skill.get("rank",0)),"cooldown":float(skill.get("cooldown_ticks",0))/20.0,"text":text})
				lines.append(text)
			var innate: Dictionary = hero.get("innate",{})
			if not innate.is_empty():
				var text := str(innate.get("name","天生被动"))+" · 随英雄等级成长\n"+str(innate.get("description",""))
				facts.append({"id":str(innate.get("id","")),"caption":"天赋","text":text})
				lines.append(text)
		2:
			for slot: Dictionary in _model.get("equipment",[])+_model.get("consumables",[]):
				var text := "%s%d：%s · %s%s\n%s"%["消耗" if slot.consumable else "装备",int(slot.slot)+1,str(slot.name),str(slot.state)," ×%d"%int(slot.count) if slot.consumable and int(slot.count)>0 else "",str(slot.description)]
				facts.append({"id":str(slot.id),"caption":("×%d"%int(slot.count) if int(slot.count)>0 else "已用" if slot.consumable and not str(slot.id).is_empty() else "空" if str(slot.id).is_empty() else "缺失"),"text":text,"absent":not bool(slot.present)})
				lines.append(text)
			lines.append("消耗品真实共用冷却 %.1fs；自动触发须满足正式使用条件，不强制浪费药水。"%(float(hero.get("item_cooldown_ticks",0))/20.0))
		3:
			for effect: Dictionary in status.get("effects",[]):
				var remaining := int(effect.get("remaining_ticks",-1))
				var text := "%s · %s · 来源 %s · %s\n%s"%[str(effect.get("name",effect.id)),str(effect.get("kind","")),str(effect.get("source","未知")),"持续／有条件" if remaining<0 else "剩余%.1fs"%(float(remaining)/20.0),str(effect.get("description",""))]
				facts.append({"id":str(effect.get("icon",effect.id)),"caption":"常驻" if remaining<0 else "%.1fs"%(float(remaining)/20.0),"text":text})
				lines.append(text)
			if lines.is_empty(): lines.append("当前无有效增益／减益。未公开来源不猜测；装备常驻属性不等于每次命中都触发特殊效果。")
		4:
			var events: Array = _model.get("events",[]).duplicate()
			events.reverse()
			for event: Dictionary in events.slice(0,35): lines.append(_event_line(event))
			if lines.is_empty(): lines.append("尚无该单位的真实事件；开始交战后记录施法、命中、控制、恢复、装备和消耗品事件。")
			lines.append("事件数值是反馈收据，不将它冒充有效HP结算总伤；精确总量查看战斗统计。")
		5:
			lines = _budget_lines()
		6:
			var record:Dictionary=_model.get("statistics",{})
			if record.is_empty():
				lines.append("此观察没有该单位的有效战绩。新版竞技场开始后记录；不从旧事件估算或补造历史。")
			else:
				lines.append("[b]总伤害 %d · 普攻 %d · 技能 %d · 承受伤害 %d[/b]"%[int(record.get("total_damage",0)),int(record.get("basic_damage",0)),int(record.get("learned_skill_damage",0)),int(record.get("damage_taken",0))])
				lines.append("击杀 士兵%d／英雄%d／野怪%d · 死亡%d · 助攻%d"%[int(record.get("unit_kills",0)),int(record.get("hero_kills",0)),int(record.get("neutral_kills",0)),int(record.get("deaths",0)),int(record.get("assists",0))])
				lines.append("帮助恢复%d · 自我恢复%d · 获得恢复%d · 控制%.1fs（敌人×秒）"%[int(record.get("ally_healing",0)),int(record.get("self_healing",0)),int(record.get("healing_received",0)),float(record.get("control_ticks",0))/20.0])
				var skill_ids:Array=record.get("skills",{}).keys();skill_ids.sort()
				for id:String in skill_ids:
					var skill:Dictionary=record.skills[id]
					lines.append("%s：伤害%d · 恢复%d · 施放%d · 控制%.1fs"%[StatisticsLabelsR10.source_label_r10(id),int(skill.get("damage",0)),int(skill.get("healing",0)),int(skill.get("casts",0)),float(skill.get("control_ticks",0))/20.0])
				lines.append("统计实际扣血／有效恢复，不含过量；持续伤害属于来源子集，不重复相加。完整兵种汇总在上方「全军战斗统计」。")
	_facts = facts
	var identity := str(tab)+":"+_selected+":"+str(facts.map(func(entry: Dictionary)->String: return str(entry.id))).sha256_text()
	if identity != _tab_identity:
		_focus_index = -1
		_tab_identity = identity
		for child: Node in _icons.get_children(): _icons.remove_child(child); child.queue_free()
		for index: int in range(mini(8,facts.size())):
			var fact: Dictionary = facts[index]
			var button := Icons.new()
			button.name = "ArenaFactIcon_"+str(tab)+"_"+str(index)
			button.symbol = str(fact.id)
			button.caption = str(fact.get("caption",""))
			button.custom_minimum_size = Vector2(51,49)
			button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			button.pressed.connect(func():
				_focus_index=index
				if index<_facts.size(): _text.text=str(_facts[index].get("text","")))
			_icons.add_child(button)
	# Icons are a compact navigation row, not an unbounded aura strip.
	_icons.visible = not facts.is_empty()
	for index: int in range(mini(facts.size(),_icons.get_child_count())):
		var button: Button = _icons.get_child(index)
		var fact: Dictionary = facts[index]
		button.set("caption",str(fact.get("caption","")))
		button.tooltip_text = str(fact.get("text",""))+"\n单击固定查阅，不会施法或使用物品。"
		button.set("cooldown",float(fact.get("cooldown",0)))
		button.modulate = Color("828a7b") if bool(fact.get("absent",false)) else Color.WHITE
		button.queue_redraw()
	_text.text = str(facts[_focus_index].get("text","")) if _focus_index>=0 and _focus_index<facts.size() else "\n\n".join(lines)

static func _event_line(event: Dictionary) -> String:
	var names := {"CAST":"施法","HIT":"命中","CONTROL":"控制","STATUS":"持续状态","HEAL":"恢复","BUFF":"强化","ITEM":"使用物品","ATTACK":"普攻","ATTACK_RANGED":"远程普攻"}
	var skill_id := str(event.get("skill_id",""))
	var item_id := str(event.get("item_id",""))
	var identity := str(Items.ITEMS.get(item_id,{}).get("name",item_id)) if not item_id.is_empty() else str(Heroes.SKILLS.get(skill_id,{}).get("name",skill_id))
	return "%.1fs  %s %s · %s → %s%s%s"%[float(event.get("tick",0))/20.0,str(names.get(str(event.get("kind","")),event.get("kind",""))),identity,str(event.get("source",{}).get("id","未知来源")),str(event.get("target",{}).get("id","自身／位置"))," · 量%s"%str(event.amount) if event.has("amount") else ""," · %s"%str(event.phase) if event.has("phase") else ""]

func _budget_lines() -> Array[String]:
	var lines: Array[String] = []
	if _receipt.is_empty():
		lines.append("自定义／普通训练配置，没有当前等预算票据。手工修改英雄、等级、装备、兵团或种子后，原票据失效；请重新抽取等预算阵容。")
		return lines
	lines.append("等预算训练夹具 · 以下只显示生成器票据，不另算费用；不是自然经济局付款，也不代表双方战力相等。")
	var weights: Dictionary = _receipt.get("weights",{})
	var caps: Dictionary = _receipt.get("caps",{})
	lines.append("双方上限 %d 金币；物品上限 %d，未用物品预算转入兵团。1金币=%d点。"%[int(caps.get("total",0)),int(caps.get("items",0)),int(weights.get("MATERIAL",0))])
	lines.append("各方配置种子："+JSON.stringify(_receipt.get("side_seeds",{}))+"。重抽只改一方初始配置；本局战斗随机使用当前种子。")
	for side: String in ["PLAYER","AI"]:
		var row: Dictionary = _receipt.get("sides",{}).get(side,{})
		lines.append("[b]%s：已用 %d／余 %d 点 · %s[/b]"%["左方" if side=="PLAYER" else "右方",int(row.get("spent",0)),int(row.get("unspent",0)),_resources_label(row.get("resources",{}))])
		var items: Dictionary = row.get("items",{})
		var troops: Dictionary = row.get("troops",{})
		lines.append("物品 %d／%d 点 · 兵团 %d／%d 点；%d个身体、%d人口。"%[int(items.get("spent",0)),int(items.get("cap",0)),int(troops.get("spent",0)),int(troops.get("cap",0)),int(row.get("body_count",0)),int(row.get("population",0))])
		lines.append("物品余额转兵力 %d 点；部队剩余 %d 点；%s。"%[int(troops.get("transferred_from_items",0)),int(troops.get("unspent",0)),"保留配置重新计价" if str(row.get("source",""))=="PRESERVED_CONFIG_REQUOTED" else "种子抽取，合法人数与兵种上限内尽量用满"])
		for hero: Dictionary in row.get("heroes",[]):
			var title := str(Heroes.profile(str(hero.get("archetype",""))).get("name",hero.get("archetype","英雄")))
			lines.append("%s %d级 · %s · 已用 %d／预算 %d 点"%[title,int(hero.get("level",0)),str(hero.get("role_label",hero.get("role_id",""))),int(hero.get("spent",0)),int(hero.get("cap",0))])
			var entries: Array[String] = []
			for item: Dictionary in hero.get("equipment",[])+hero.get("consumables",[]): entries.append("%s %d点（%s）"%[str(item.get("name",item.get("id",""))),int(item.get("points",0)),_resources_label(item.get("cost",{}))])
			lines.append("、".join(entries))
		for troop: Dictionary in troops.get("roster",[]): lines.append("%s ×%d · 每体%d点／%d人口（%s）"%[str(troop.get("name",troop.get("unit_type",""))),int(troop.get("count",0)),int(troop.get("points_each",0)),int(troop.get("population_each",0)),_resources_label(troop.get("cost_each",{}))])
	return lines

static func _resources_label(resources: Dictionary) -> String:
	return "金币%d"%int(resources.get("MATERIAL",0))
