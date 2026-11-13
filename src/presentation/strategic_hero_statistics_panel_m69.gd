extends Control
## A pixel-styled, read-only table shared by live games, arena and replay.
signal close_requested
const UITheme = preload("res://src/presentation/strategic_ui_theme.gd")
const TextButton = preload("res://src/presentation/strategic_text_button.gd")
const Fonts = preload("res://src/presentation/strategic_font.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const MatchScores = preload("res://src/simulation/strategic_match_scores_m72.gd")
const TroopSkillsR10 = preload("res://src/simulation/strategic_troop_skills_v4.gd")
const ArmySupportR10 = preload("res://src/simulation/strategic_army_support.gd")
const COLUMNS := ["英雄 / 阵营","总伤害","普攻","技能伤害","兵 / 英雄击杀","死 / 助","自我恢复","帮助恢复","承受伤害","控制秒"]
var _facts: Dictionary = {}
var _side := ""
var _selected := ""
var _tree: Tree
var _title: Label
var _details: RichTextLabel
var _side_choice: OptionButton
var _sort_choice: OptionButton
var _built := false
var _scores: Dictionary = {}
var _mode_choice: OptionButton
var _selected_score := ""
const SCORE_COLUMNS := ["阵营","当前总分","军队","建筑","经济","英雄","装备","科技","累计表现","军队峰值"]

func _ready() -> void:
	_build()
	resized.connect(_layout)
	_layout()

func _draw() -> void:
	UITheme.draw_surface(self,Rect2(Vector2.ZERO,size),"panel")

func _build() -> void:
	if _built: return
	_built = true
	custom_minimum_size = Vector2(400,460)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_title = Label.new(); _title.name = "HeroStatisticsTitle"
	_title.add_theme_font_override("font",Fonts.readable()); _title.add_theme_font_size_override("font_size",21)
	_title.add_theme_color_override("font_color",Color("eddda9")); add_child(_title)
	_title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var close := TextButton.new(); close.name="CloseHeroStatistics"; close.text="返回"; close.position=Vector2(0,14); close.size=Vector2(80,42)
	close.pressed.connect(func(): close_requested.emit()); add_child(close)
	_side_choice=OptionButton.new(); _side_choice.name="StatisticsSideFilter"; _side_choice.add_item("全部阵营"); _side_choice.set_item_metadata(0,"")
	_style_option(_side_choice); _side_choice.item_selected.connect(func(index:int): _side=str(_side_choice.get_item_metadata(index)); _rebuild_rows()); add_child(_side_choice)
	_sort_choice=OptionButton.new(); _sort_choice.name="StatisticsSort"
	for label:String in ["按总伤害","按控制时间","按援助恢复","按英雄击杀","按承受伤害"]: _sort_choice.add_item(label)
	_style_option(_sort_choice); _sort_choice.item_selected.connect(func(_index:int): _rebuild_rows()); add_child(_sort_choice)
	_mode_choice=OptionButton.new(); _mode_choice.name="StatisticsViewMode"
	_mode_choice.add_item("英雄战绩"); _mode_choice.add_item("全军实力评分")
	_mode_choice.add_item("普通单位战绩"); _mode_choice.add_item("兵种汇总"); _mode_choice.add_item("全部单位战绩")
	_style_option(_mode_choice); _mode_choice.item_selected.connect(func(_index:int): _rebuild_rows()); add_child(_mode_choice)
	_tree=Tree.new(); _tree.name="HeroStatisticsTable"; _tree.columns=COLUMNS.size(); _tree.hide_root=true; _tree.select_mode=Tree.SELECT_ROW
	_tree.column_titles_visible=true; _tree.allow_reselect=true
	_tree.add_theme_font_override("font",Fonts.readable()); _tree.add_theme_font_override("title_button_font",Fonts.readable())
	_tree.add_theme_font_size_override("font_size",15); _tree.add_theme_constant_override("v_separation",9)
	_tree.add_theme_stylebox_override("panel",UITheme.style("normal","strip")); _tree.add_theme_stylebox_override("selected",UITheme.style("selected","hero"))
	_tree.add_theme_color_override("font_color",Color("ddd4b8")); _tree.add_theme_color_override("font_selected_color",Color("fff0b7"))
	for i:int in range(COLUMNS.size()):
		_tree.set_column_title(i,COLUMNS[i]); _tree.set_column_custom_minimum_width(i,190 if i==0 else 106 if i==4 else 82); _tree.set_column_expand(i,i==0)
	_tree.item_selected.connect(_select_row); add_child(_tree)
	_details=RichTextLabel.new(); _details.name="HeroStatisticsBreakdown"; _details.bbcode_enabled=true; _details.scroll_active=true
	_details.add_theme_font_override("normal_font",Fonts.readable()); _details.add_theme_font_size_override("normal_font_size",15)
	_details.add_theme_color_override("default_color",Color("d9d1b8")); add_child(_details)
	_layout()

func _style_option(option: OptionButton) -> void:
	option.add_theme_font_override("font",Fonts.readable()); option.add_theme_font_size_override("font_size",16)
	for state:String in ["normal","hover","pressed","focus"]: option.add_theme_stylebox_override(state,UITheme.style(state,"hero"))
	option.add_theme_color_override("font_color",Color("eddda9"))

func _layout() -> void:
	if not _built: return
	_title.position=Vector2(18,18); _title.size=Vector2(maxf(180,size.x-320),32)
	get_node("CloseHeroStatistics").position=Vector2(size.x-96,12)
	_side_choice.position=Vector2(18,58); _side_choice.size=Vector2(180,36)
	_sort_choice.position=Vector2(208,58); _sort_choice.size=Vector2(180,36)
	_mode_choice.position=Vector2(398,58) if size.x>=590 else Vector2(18,100); _mode_choice.size=Vector2(178,36)
	_tree.position=Vector2(16,106 if size.x>=590 else 148); _tree.size=Vector2(size.x-32,maxf(140,size.y*0.44))
	_details.position=Vector2(20,_tree.position.y+_tree.size.y+12); _details.size=Vector2(size.x-40,maxf(86,size.y-_details.position.y-18))
	queue_redraw()

func set_statistics(statistics: Dictionary, side_filter: String = "") -> void:
	_build()
	_facts=statistics.get("hero_statistics",statistics).duplicate(true)
	var scores:Variant=statistics.get("match_scores",{})
	_scores=scores.duplicate(true) if MatchScores.validate_snapshot(scores,int(statistics.get("tick",18000))) else {}
	# A missing score snapshot must not disable the unrelated troop views.
	_mode_choice.disabled=false
	_mode_choice.set_item_disabled(1,_scores.is_empty())
	_side=side_filter
	_rebuild_filters()
	_rebuild_rows()

func refresh(statistics: Dictionary, context: Dictionary = {}) -> void:
	set_statistics(statistics,str(context.get("side_filter",_side)))

func show_match_scores() -> void:
	_build()
	_mode_choice.select(1)
	_rebuild_rows()

func show_actor_statistics(actor_id:String) -> bool:
	_build()
	for row:Dictionary in _facts.get("heroes",[])+_facts.get("units",[]):
		if _row_id_r10(row)!=actor_id:continue
		_selected=actor_id
		_side=""
		_mode_choice.select(0 if row.has("hero_id") else 2)
		_rebuild_filters();_rebuild_rows()
		return true
	return false

static func _row_id_r10(row:Dictionary) -> String:
	return str(row.get("hero_id",row.get("actor_id",row.get("unit_id",row.get("row_id",row.get("group_id",""))))))

func _rows_r10() -> Array:
	match _mode_choice.selected:
		2:return _facts.get("units",[])
		3:return _facts.get("unit_types",[])
		4:return _facts.get("heroes",[])+_facts.get("units",[])
	return _facts.get("heroes",[])

func _rebuild_filters() -> void:
	var sides:Array[String]=[]
	for hero:Dictionary in _facts.get("heroes",[])+_facts.get("units",[]):
		if str(hero.side) not in sides: sides.append(str(hero.side))
	sides.sort(); _side_choice.clear(); _side_choice.add_item("全部阵营"); _side_choice.set_item_metadata(0,"")
	for side:String in sides: _side_choice.add_item(side); _side_choice.set_item_metadata(_side_choice.item_count-1,side)
	for index:int in range(_side_choice.item_count):
		if str(_side_choice.get_item_metadata(index))==_side: _side_choice.select(index); return
	_side=""; _side_choice.select(0)

func _rebuild_rows() -> void:
	if _mode_choice.selected==1:
		_rebuild_scores(); return
	_sort_choice.disabled=false
	_tree.columns=COLUMNS.size()
	for index:int in range(COLUMNS.size()): _tree.set_column_title(index,COLUMNS[index])
	_tree.clear(); var root:=_tree.create_item()
	var rows:Array=[]
	for hero:Dictionary in _rows_r10():
		if _side.is_empty() or str(hero.side)==_side: rows.append(hero)
	var sort_field:String=["total_damage","control_ticks","ally_healing","hero_kills","damage_taken"][_sort_choice.selected]
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.get(sort_field,0))>int(b.get(sort_field,0)) if a.get(sort_field,0)!=b.get(sort_field,0) else _row_id_r10(a)<_row_id_r10(b))
	if not rows.any(func(row:Dictionary)->bool:return _row_id_r10(row)==_selected):_selected="" if rows.is_empty() else _row_id_r10(rows[0])
	for hero:Dictionary in rows:
		var row:=_tree.create_item(root); row.set_metadata(0,_row_id_r10(hero))
		var identity:=str(hero.get("name",hero.get("unit_type",hero.get("archetype","单位"))))
		if _mode_choice.selected==3:identity+=" ×%d（存活%d）"%[int(hero.get("count",0)),int(hero.get("alive_count",0))]
		elif hero.has("hero_id"):identity+=" · Lv.%d"%int(hero.get("level",1))
		identity+=" [%s]%s"%[hero.side," †" if _mode_choice.selected!=3 and not bool(hero.get("alive",true)) else ""]
		var values:=[identity,str(hero.total_damage),str(hero.basic_damage),str(hero.learned_skill_damage),"%d / %d"%[int(hero.unit_kills),int(hero.hero_kills)],"%d / %d"%[int(hero.deaths),int(hero.assists)],str(hero.self_healing),str(hero.ally_healing),str(hero.damage_taken),"%.1f"%(float(hero.control_ticks)/20.0)]
		for i:int in range(values.size()): row.set_text(i,str(values[i])); row.set_text_alignment(i,HORIZONTAL_ALIGNMENT_LEFT if i==0 else HORIZONTAL_ALIGNMENT_CENTER)
		if _row_id_r10(hero)==_selected: row.select(0)
	var labels:Dictionary={0:"英雄战绩",2:"普通单位战绩",3:"兵种汇总",4:"全部单位战绩"}
	_tree.set_column_title(0,"兵种 / 阵营" if _mode_choice.selected==3 else "单位 / 阵营" if _mode_choice.selected>=2 else COLUMNS[0])
	_title.text="%s · %.1f 秒 · %d 项"%[labels.get(_mode_choice.selected,"战绩"),maxf(0,float(_facts.get("tick",0))/20.0),rows.size()]
	_show_details()

func _select_row() -> void:
	var item:=_tree.get_selected()
	if _mode_choice.selected==1:
		if item!=null: _selected_score=str(item.get_metadata(0)); _show_score_details()
		return
	if item!=null: _selected=str(item.get_metadata(0)); _show_details()

func _rebuild_scores() -> void:
	_sort_choice.disabled=true
	_tree.clear(); var root:=_tree.create_item()
	_tree.columns=SCORE_COLUMNS.size()
	for index:int in range(SCORE_COLUMNS.size()): _tree.set_column_title(index,SCORE_COLUMNS[index])
	var sides:Array=_scores.get("sides",{}).keys(); sides.sort()
	sides=sides.filter(func(side:Variant)->bool:return _side.is_empty() or str(side)==_side)
	if _selected_score not in sides: _selected_score=""
	for side:String in sides:
		var score:Dictionary=_scores.sides[side]; var current:Dictionary=score.current
		var values:Array=[side,current.total,current.army,current.buildings,current.economy,current.heroes,current.equipment,current.technology,score.accumulated.total,score.peaks.army]
		var row:=_tree.create_item(root); row.set_metadata(0,side)
		for index:int in range(values.size()): row.set_text(index,str(values[index]) if index==0 else "%.1f"%float(values[index]))
		if side==_selected_score: row.select(0)
	_title.text="全军实力 · %.1f秒 · 当前／累计分列"%(float(_scores.get("tick",0))/20.0)
	if _selected_score.is_empty() and root.get_first_child()!=null:
		_selected_score=str(root.get_first_child().get_metadata(0)); root.get_first_child().select(0)
	_show_score_details()

func _show_score_details() -> void:
	if _scores.is_empty():
		_details.text="这份录像未记录实力评分，可继续查看已有战绩。"; return
	var score:Dictionary=_scores.get("sides",{}).get(_selected_score,{})
	if score.is_empty(): _details.text="请选择一个阵营。"; return
	_details.text="[color=#eddda9]%s · 分数是资产／就绪度指数，不是局部胜率[/color]\n"%_selected_score
	_details.text+="军队 %d · 在场英雄 %d · 已完成建筑 %d · 已装备 %d\n"%[int(score.counts.army),int(score.counts.heroes),int(score.counts.buildings),int(score.counts.equipment)]
	_details.text+="累计自动净收入分 %.1f · 已获英雄等级 %d · 英雄归属击杀分 %.1f；历史军队峰值 %.1f\n"%[float(score.accumulated.gathered),int(score.accumulated.hero_levels),float(score.accumulated.hero_combat),float(score.peaks.army)]
	_details.text+="[color=#aab19f]当前实力：按金币成本÷10计分，存活资产按25%＋75%生命比例折算，阵亡单位不计。军队与英雄分开统计；英雄身份、等级、技能与装备分别计分。经济分按当前金币库存计算。建筑仅统计存活且完工的计分设施，商店除外；科技只计已完成等级。[/color]\n"
	_details.text+="累计实力：自动采金净收入÷10＋已获英雄等级×5＋英雄击杀分（英雄／士兵／野怪／建筑：20／2／1／5）。不含初始金币、退款、转移或赏金；击杀分仅统计英雄归属的击杀，不含全军击杀。每秒更新，历史最高值与累计值单独显示。"

func _name(id: String) -> String:
	return source_label_r10(id)

static func source_label_r10(id:String) -> String:
	if Heroes.SKILLS.has(id): return str(Heroes.SKILLS[id].name)
	if Items.ITEMS.has(id): return str(Items.ITEMS[id].get("label",Items.ITEMS[id].get("name",id)))
	if id.begins_with("INNATE_"): return "天生被动 · "+id.trim_prefix("INNATE_")
	for ability:Dictionary in TroopSkillsR10.CATALOG.values()+TroopSkillsR10.BASIC_PROCS.values():
		if str(ability.get("id",""))==id:return str(ability.get("label",id))
	for ability:Dictionary in ArmySupportR10.CATALOG.values():
		if str(ability.get("id",""))==id:return str(ability.get("name",id))
	return {"BASIC":"普通攻击","SUPPORT_HEAL":"自动医疗","BASIC_LIFESTEAL":"普攻吸血","ITEM_LIFESTEAL":"装备吸血","ITEM_RECOVERY":"装备／药剂持续恢复","BASE_RECOVERY":"英雄基础恢复","ITEM_AURA":"装备恢复光环"}.get(id,id)

func _show_details() -> void:
	var hero:Dictionary={}
	for candidate:Dictionary in _rows_r10():
		if _row_id_r10(candidate)==_selected: hero=candidate; break
	if hero.is_empty(): _details.text="尚无此类战绩。普通单位统计仅在新版竞技场启用，旧录像缺失时不补造历史数据。"; return
	var text:="[color=#eddda9]%s · 详细来源[/color]\n"%hero.name
	if bool(_facts.get("unit_tracking_truncated",false)):text+="[color=#e2a276]记录达到容量上限；普通单位列表／汇总仅覆盖已登记身份，不能当全量统计。[/color]\n"
	text+="天赋伤害 %d  · 装备伤害 %d  · 持续伤害 %d（已计入来源，不重复加总） · 建筑伤害 %d\n"%[int(hero.innate_damage),int(hero.item_damage),int(hero.dot_damage),int(hero.building_damage)]
	text+="表中技能伤害为英雄学习技能／普通兵主动技能的直接归属；天赋与装备另列，不重复估算强化普攻。\n"
	text+="野怪击杀 %d · 摧毁建筑 %d · 受到恢复 %d · 硬控 %.1fs / 弱控 %.1fs\n"%[int(hero.neutral_kills),int(hero.building_kills),int(hero.healing_received),float(hero.hard_control_ticks)/20.0,float(hero.weak_control_ticks)/20.0]
	text+="[color=#aab19f]强化普攻的最终扣血归普攻；强化／防御技能显示0伤害不代表未生效，不重复估算间接贡献。[/color]\n"
	if _mode_choice.selected==3:text+="同阵营同兵种的实际个体累计相加，含已阵亡单位；不是每体平均，也不是战斗力预测。\n"
	var ids:Array=hero.skills.keys(); ids.sort()
	for id:String in ids:
		var skill:Dictionary=hero.skills[id]
		text+="%s：施放 %d · 伤害 %d（持续 %d）· 恢复 %d · 控制 %.1fs\n"%[_name(id),int(skill.casts),int(skill.damage),int(skill.dot_damage),int(skill.healing),float(skill.control_ticks)/20.0]
	text+="[color=#969b8a]扣血后统计，不含过量伤害／过量治疗。助攻：10秒内真实伤害或控制参与，不含仅治疗／增益；兵、英雄、野怪、建筑分开。控制单位为「敌人×秒」，群控多个目标可超过战斗时长；敌人死亡／净化即停止，重叠按眩晕＞定身＞减速归属一次。[/color]"
	_details.text=text
