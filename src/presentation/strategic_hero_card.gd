class_name StrategicHeroCard
extends Button
## A persistent identity button; passive inspection cells never cast or select.
const UIThemeClass = preload("res://src/presentation/strategic_ui_theme.gd")
const Pixel = preload("res://src/presentation/strategic_pixel_renderer.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const CostReadout = preload("res://src/presentation/strategic_cost_readout.gd")
const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const Progression = preload("res://src/simulation/strategic_hero_progression.gd")
const Innates = preload("res://src/simulation/strategic_hero_innates.gd")
const ROSTER_WIDTH := 254.0
const ROSTER_HEIGHT := 74.0
var hero: Dictionary = {}
var selected := false
var recall_blocked_reason := ""
var revive_quote: Dictionary = {}
var readout: Dictionary = {}
var _revive_cost: Control
var _inspection_cells: Dictionary = {}
var _draw_layout_m76: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(state, UIThemeClass.style(state, "hero"))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	_revive_cost = CostReadout.new()
	_revive_cost.name = "HeroReviveCostIcons"
	_revive_cost.font_size = 12
	add_child(_revive_cost)
	resized.connect(_layout_contents)
	_update_minimum_size()
	_layout_contents()

func refresh(facts: Dictionary, is_selected: bool, recall_reason: String = "", quote: Dictionary = {}, stock: Dictionary = {}, status: Dictionary = {}) -> void:
	hero = facts.duplicate(true)
	readout = status.duplicate(true)
	selected = is_selected
	recall_blocked_reason = recall_reason
	revive_quote = quote.duplicate(true)
	_update_minimum_size()
	visible = not hero.is_empty()
	for key: String in ["unit_id", "hp", "xp", "level", "alive", "mana", "max_mana"]:
		set_meta(key, hero.get(key, false if key == "alive" else "" if key == "unit_id" else 0))
	set_meta("hero_archetype", _archetype())
	set_meta("selected", selected)
	set_meta("hero_quote", revive_quote.duplicate(true))
	var action := "单击头像或名字：选择并聚焦，不下达军令。" if hero.get("alive", false) else "已倒下：单击头像进入祭庭付费复活。"
	if not recall_blocked_reason.is_empty(): action = "单击头像查看资料。\n" + recall_blocked_reason
	tooltip_text = "%s · 等级%d\n生命 %d/%d · 蓝量 %d/%d\n经验 %d%s\n%s" % [hero.get("name","英雄"), int(hero.get("level",1)), int(hero.get("hp",0)), int(hero.get("max_hp",1)), int(hero.get("mana",0)), int(hero.get("max_mana",0)), int(hero.get("xp",0)), "/%d" % int(hero.get("next_level_xp", -1)) if int(hero.get("next_level_xp",-1)) > 0 else "（满级）", action]
	if not bool(hero.get("alive",false)):
		tooltip_text += "\n召回保留身份、等级和技能；已掉落装备不返还。"
		if not revive_quote.is_empty():
			tooltip_text += "\n复活等级%d英雄 · %d金币 · %.1f秒" % [int(revive_quote.get("level",1)),int(revive_quote.get("cost",{}).get("MATERIAL",0)),float(revive_quote.get("duration_ticks",0))/20.0]
	if _revive_cost != null:
		_revive_cost.visible = not bool(hero.get("alive",false)) and not revive_quote.is_empty()
		_revive_cost.refresh(revive_quote.get("cost",{}),stock)
	_layout_contents()
	queue_redraw()

func _archetype() -> String:
	return str(hero.get("archetype",hero.get("hero_archetype","COMMANDER")))

func _update_minimum_size() -> void:
	# Selection changes only the outline. All retained heroes expose the same
	# compact expanded information, without shifting identities under the pointer.
	custom_minimum_size = Vector2(ROSTER_WIDTH, ROSTER_HEIGHT + (22 if not hero.is_empty() and not hero.get("alive",false) else 0))

func _layout_contents() -> void:
	if _revive_cost != null:
		_revive_cost.position = Vector2(8,size.y-23)
		_revive_cost.size = Vector2(maxf(size.x-16,1),20)
	var layout := layout_snapshot()
	_draw_layout_m76=layout
	var wanted := {}
	for family: String in ["vitals","stats","skills","effects"]:
		for cell: Dictionary in layout[family]:
			var key := str(cell.key)
			wanted[key] = true
			var target: Control = _inspection_cells.get(key)
			if not is_instance_valid(target):
				target = Control.new()
				target.name = "Inspect_" + str(_inspection_cells.size())
				target.mouse_filter = Control.MOUSE_FILTER_STOP
				target.set_meta("hero_inspection_card",self)
				target.set_meta("hero_cell_key",key)
				add_child(target)
				_inspection_cells[key] = target
			target.position = cell.rect.position
			target.size = cell.rect.size
			target.tooltip_text = str(cell.text)
	for key: String in _inspection_cells.keys():
		if not wanted.has(key):
			var target: Control = _inspection_cells[key]
			remove_child(target)
			target.queue_free()
			_inspection_cells.erase(key)

func layout_snapshot() -> Dictionary:
	var portrait := Rect2(7,6,42,40)
	var bar_x := portrait.position.x
	var bar_width := portrait.size.x
	var hp_bar := Rect2(bar_x,49,bar_width,5)
	var mana_bar := Rect2(bar_x,57,bar_width,5)
	var xp_bar := Rect2(bar_x,65,bar_width,5)
	var vitals: Array[Dictionary] = [
		{"key":"hp","rect":hp_bar.grow(2),"text":"生命 %d/%d\n生命降至0时倒下。" % [int(hero.get("hp",0)),int(hero.get("max_hp",1))]},
		{"key":"mana","rect":mana_bar.grow(2),"text":"法力 %d/%d\n施放主动技能需要足够法力。" % [int(hero.get("mana",0)),int(hero.get("max_mana",0))]},
		{"key":"xp","rect":xp_bar.grow(1),"text":_xp_text()}
	]
	var stats: Array[Dictionary] = []
	var skills: Array[Dictionary] = []
	var effects: Array[Dictionary] = []
	var values: Array = readout.get("stats",[])
	var visible_stats := ["damage","armor","attack_speed","move_speed","magic_resist","spell_amp"]
	for stat_id: String in visible_stats:
		for value: Dictionary in values:
			if str(value.get("id","")) != stat_id:continue
			var index := stats.size()
			var entry: Dictionary=value.duplicate(true)
			var label := str(entry.get("compact_value",entry.value))
			if stat_id=="attack_speed": label=label.trim_suffix("/s")
			entry.merge({"key":"stat:"+str(entry.id),"rect":Rect2(56+(index%2)*48,22+floori(index/2.0)*16,47,15),"display_value":label,"text":str(entry.label)+" "+str(entry.value)+"\n"+str(entry.get("description",""))},true)
			stats.append(entry);break
	var published: Array=readout.get("skills",hero.get("skills",[]))
	for index: int in range(mini(3,published.size())):
		var entry: Dictionary=published[index].duplicate(true)
		entry["rank"]=int(entry.get("rank",entry.get("level",0)))
		entry["max_rank"]=int(entry.get("max_rank",entry.get("max_level",3)))
		entry.merge({"key":"skill:"+str(entry.id),"rect":Rect2(156+index*24,23,22,24),"icon":str(entry.id),"slot":index+1},true)
		entry["state"]=_skill_state(entry);entry["text"]=_skill_text(entry)
		skills.append(entry)
	var innate:=Innates.profile(_archetype(),int(hero.get("level",1)))
	if not innate.is_empty():
		skills.append({"key":"innate:"+str(innate.id),"id":str(innate.id),"icon":str(innate.id),"name":str(innate.name),"rect":Rect2(228,23,22,24),"passive":true,"rank":1,"max_rank":1,"innate":true,"text":str(innate.name)+" · 天生被动\n"+str(innate.description)+("\n英雄已倒下，在场效果失效。" if not hero.get("alive",false) else "")})
	var active: Array=[]
	for entry: Dictionary in readout.get("effects",[]):
		if entry.get("kind","")!="INNATE":active.append(entry)
	active.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var ra:=_effect_priority(str(a.get("kind","")))
		var rb:=_effect_priority(str(b.get("kind","")))
		return ra<rb if ra!=rb else str(a.get("id",""))+str(a.get("source_id",""))<str(b.get("id",""))+str(b.get("source_id","")))
	var shown:=mini(active.size(),4 if active.size()<=4 else 3)
	for index: int in range(shown):
		var entry: Dictionary=active[index].duplicate(true)
		entry.merge({"key":"effect:"+str(entry.get("kind",""))+":"+str(entry.id)+":"+str(entry.get("source_id","")),"rect":Rect2(156+index*24,50,22,21),"text":str(entry.get("name","状态"))+"\n"+str(entry.get("description",""))},true)
		effects.append(entry)
	if shown<active.size():
		var lines: Array[String]=["另有%d项状态（含已装备属性）："%(active.size()-shown)]
		for index: int in range(shown,active.size()):
			var entry: Dictionary=active[index]
			lines.append("%s · %s\n%s"%[entry.get("name","状态"),entry.get("source",""),entry.get("description","")])
		effects.append({"key":"effects:overflow","rect":Rect2(156+shown*24,50,22,21),"overflow":active.size()-shown,"text":"\n".join(lines)})
	return {"portrait":portrait,"hp_bar":hp_bar,"mana_bar":mana_bar,"xp_bar":xp_bar,"vitals":vitals,"stats":stats,"skills":skills,"effects":effects,"size":size,"selected":selected,"compact":false,"expanded":true,"summary_stats":visible_stats,"all_stat_count":values.size()}

func _effect_priority(kind: String) -> int:
	if kind.begins_with("DEBUFF"): return 0
	if kind in ["BUFF","CONSUMABLE","SHIELD","HOT","PERIODIC"]: return 1
	if kind.ends_with("AURA"): return 2
	return 3

func inspection_at(point: Vector2) -> Dictionary:
	var layout := layout_snapshot()
	for family: String in ["vitals","stats","skills","effects"]:
		for cell: Dictionary in layout[family]:
			if cell.rect.has_point(point):
				var inspection := cell.duplicate(true)
				inspection["passive"] = true # Input semantics, not learned-skill type.
				return inspection
	return {}

func inspection_for(key: String) -> Dictionary:
	var layout := layout_snapshot()
	for family: String in ["vitals","stats","skills","effects"]:
		for cell: Dictionary in layout[family]:
			if str(cell.key) == key:
				var inspection := cell.duplicate(true)
				inspection["passive"] = true
				return inspection
	return {}

func _xp_text() -> String:
	var level := clampi(int(hero.get("level",1)),1,8)
	var floor_xp := int(Progression.XP_THRESHOLDS[level-1])
	var ceiling := int(hero.get("next_level_xp",Progression.next_level_xp(level)))
	if level >= 8 or ceiling < 0: return "经验 %d · 满级8级\n已达到本局等级上限。"%int(hero.get("xp",0))
	return "累计经验 %d/%d\n本级经验 %d/%d"%[int(hero.get("xp",0)),ceiling,maxi(0,int(hero.get("xp",0))-floor_xp),maxi(1,ceiling-floor_xp)]

func _skill_state(skill: Dictionary) -> String:
	if not hero.get("alive",false): return "INCAPACITATED"
	if int(skill.get("rank",skill.get("level",0))) <= 0: return "UNLEARNED"
	if bool(skill.get("passive",false)): return "PASSIVE"
	if int(hero.get("stun_until_tick",-1)) > int(readout.get("tick",0)): return "STUNNED"
	if int(skill.get("cooldown_ticks",0)) > 0: return "COOLDOWN"
	if int(hero.get("mana",0)) < int(skill.get("mana_cost",0)): return "MANA"
	if skill.has("can_cast") and not bool(skill.can_cast): return "UNAVAILABLE"
	return "READY"

func _skill_text(skill: Dictionary) -> String:
	var rank := int(skill.get("rank",0))
	var state := str({"INCAPACITATED":"已倒下","UNLEARNED":"未学习","PASSIVE":"被动","STUNNED":"眩晕中","COOLDOWN":"冷却 %.1f秒"%(float(skill.get("cooldown_ticks",0))/20.0),"MANA":"蓝量不足","UNAVAILABLE":"当前不可施放","READY":"就绪"}.get(_skill_state(skill),"当前不可施放"))
	return "%s · %d/%d级 · %s\n%s"%[skill.get("name","技能"),rank,int(skill.get("max_rank",3)),state,skill.get("description","")]

func _draw() -> void:
	var state := "disabled" if disabled else "pressed" if is_pressed() else "selected" if selected else "hover" if is_hovered() else "normal"
	UIThemeClass.draw_surface(self,Rect2(Vector2.ZERO,size),"hero",state)
	# Refresh/resize already built the same cell geometry and descriptions.
	# Public layout_snapshot remains a detached fresh read for inspectors/tests.
	var layout := _draw_layout_m76 if not _draw_layout_m76.is_empty() and _draw_layout_m76.get("size")==size else layout_snapshot()
	var alive := bool(hero.get("alive",false))
	var ink := Color("eadcb9") if alive else Color("9e9e8e")
	var portrait: Rect2 = layout.portrait
	draw_rect(portrait,Color("172322"))
	Pixel.draw_hero_portrait(self,portrait.grow(-2),_archetype(),alive)
	UIThemeClass.draw_frame(self,portrait,"hero",state)
	var font := ReadableFont.readable()
	draw_string(font,Vector2(56,17),str(hero.get("name","英雄")),HORIZONTAL_ALIGNMENT_LEFT,size.x-111,12,ink)
	var level_text:="Lv.%d"%int(hero.get("level",1))
	if int(hero.get("skill_points",0))>0:level_text+=" +%d"%int(hero.skill_points)
	draw_string(font,Vector2(size.x-56,17),level_text,HORIZONTAL_ALIGNMENT_RIGHT,50,12,Color("e4c57f"))
	if selected:draw_rect(Rect2(2,5,2,ROSTER_HEIGHT-10),Color("edc67e"))
	var hp := int(hero.get("hp",0))
	var mana := int(hero.get("mana",0))
	_bar(layout.hp_bar,clampf(float(hp)/maxi(1,int(hero.get("max_hp",1))),0,1),Palette.side_color(str(hero.get("side","PLAYER"))))
	_bar(layout.mana_bar,clampf(float(mana)/maxi(1,int(hero.get("max_mana",1))),0,1),Color("5d9bd5"))
	var level := clampi(int(hero.get("level",1)),1,8)
	var floor_xp := int(Progression.XP_THRESHOLDS[level-1])
	var next_xp := int(hero.get("next_level_xp",Progression.next_level_xp(level)))
	var xp_ratio := float(readout.get("xp_ratio",clampf(float(int(hero.get("xp",0))-floor_xp)/maxi(1,next_xp-floor_xp),0,1) if next_xp > 0 else 1.0))
	_bar(layout.xp_bar,xp_ratio,Color("b38ad1"))
	for cell: Dictionary in layout.stats:_draw_stat(cell)
	for cell: Dictionary in layout.skills:_draw_skill(cell,alive)
	for cell: Dictionary in layout.effects:_draw_effect(cell)
	if layout.effects.is_empty():draw_string(font,Vector2(157,65),"无额外状态" if alive else "倒下 · 可复活",HORIZONTAL_ALIGNMENT_LEFT,size.x-161,11,Color("939d90"))
	if not alive:
		draw_line(portrait.position+Vector2(6,8),portrait.end-Vector2(6,8),Color("be8970"),2)
	set_meta("painted_draw_state",layout)

func _draw_stat(cell: Dictionary) -> void:
	var rect: Rect2 = cell.rect
	draw_rect(rect,Color("202a28"))
	draw_line(rect.position+Vector2(0,rect.size.y-1),rect.end-Vector2(1,1),Color("4e5141"),1)
	var symbol := str({"attack":"damage","attack_speed":"STAT_ATTACK_SPEED","magic_resist":"STAT_MAGIC_RESIST","spell":"STAT_SPELL_AMP","mana":"blue_bottle"}.get(str(cell.get("symbol","")),cell.get("symbol","damage")))
	Icons.draw_symbol(self,symbol,rect.position+Vector2(6,7),Color("c6bb90"),0.25)
	for run: Dictionary in _stat_text_layout(cell):
		draw_string(ReadableFont.readable(),Vector2(run.origin),str(run.text),HORIZONTAL_ALIGNMENT_LEFT,float(run.width),int(run.font_size),Color("dfb792") if bool(run.get("negative",false)) else Color("b9c99f") if bool(run.get("bonus",false)) else Color("e0d7bd"))

func _stat_text_layout(cell: Dictionary) -> Array[Dictionary]:
	var rect: Rect2=cell.rect
	var font := ReadableFont.readable()
	var value := str(cell.get("display_value",cell.value))
	var font_size := 12
	while font_size>9 and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>rect.size.x-14:font_size-=1
	if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>rect.size.x-14:
		# Keep the signed pair, but omit redundant zero before decimals in this
		# compact glance row. The shared tooltip retains exact units and total.
		if value.begins_with("0."):value=value.trim_prefix("0")
		value=value.replace("+0.","+.").replace("−0.","−.")
	var width:=maxf(1,rect.size.x-13)
	if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
		var split:=maxi(value.find("+",1),value.find("−",1))
		if split>0:
			# A rare long fractional pair keeps both operands readable rather
			# than clipping the modifier or inflating the three-hero roster.
			return [{"text":value.left(split),"font_size":9,"origin":rect.position+Vector2(13,7),"width":width},{"text":value.substr(split),"font_size":8,"origin":rect.position+Vector2(13,14),"width":width,"bonus":true,"negative":value.substr(split).begins_with("−")}]
	return [{"text":value,"font_size":font_size,"origin":rect.position+Vector2(13,12),"width":width}]

func _draw_skill(cell: Dictionary, alive: bool) -> void:
	var rect: Rect2 = cell.rect
	draw_rect(rect,Color("111b1d"))
	draw_rect(rect,Color("9b8860") if cell.get("innate",false) else Color("6e7769"),false,1)
	Icons.draw_symbol(self,str(cell.get("icon",cell.get("id",""))),rect.get_center()+Vector2(0,-2),Color.WHITE,0.43)
	var rank := int(cell.get("rank",0))
	var passive := bool(cell.get("passive",false))
	var cd := maxi(0,int(cell.get("cooldown_ticks",0)))
	var mp := not passive and int(hero.get("mana",0)) < int(cell.get("mana_cost",0))
	var blocked := str(cell.get("state",_skill_state(cell))) in ["STUNNED","UNAVAILABLE"]
	if not alive or rank <= 0:
		draw_rect(rect.grow(-2),Color(0.04,0.07,0.07,0.73))
	elif blocked: draw_rect(rect.grow(-2),Color(0.15,0.07,0.08,0.72))
	elif cd > 0:
		var ratio := clampf(float(cd)/maxi(1,int(cell.get("max_cooldown_ticks",cd))),0,1)
		draw_rect(Rect2(rect.position+Vector2(2,2),Vector2(rect.size.x-4,(rect.size.y-6)*ratio)),Color(0.03,0.05,0.06,0.75))
	elif mp: draw_rect(rect.grow(-2),Color(0.04,0.12,0.24,0.60))
	var label:="×" if not alive else "—" if rank<=0 else "" if passive else "!" if blocked else str(ceili(float(cd)/20.0)) if cd>0 else "MP" if mp else ""
	if not label.is_empty():
		draw_string_outline(ReadableFont.readable(),rect.position+Vector2(0,17),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,11,2,Color("111919"))
		draw_string(ReadableFont.readable(),rect.position+Vector2(0,17),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,11,Color("ecdfb8"))
	var max_rank:=int(cell.get("max_rank",3))
	var pip_width:=4.0
	var pip_start:=(rect.size.x-(max_rank*(pip_width+2)-2))/2
	for index: int in range(int(cell.get("max_rank",3))):
		draw_rect(Rect2(rect.position+Vector2(pip_start+index*(pip_width+2),rect.size.y-4),Vector2(pip_width,2)),Color("e1bc62") if index<rank else Color("484c43"))

func _draw_effect(cell: Dictionary) -> void:
	var rect: Rect2 = cell.rect
	var harmful := str(cell.get("kind","")).begins_with("DEBUFF")
	draw_rect(rect,Color("242a27"))
	draw_rect(rect,Color("c27e72") if harmful else Color("91a38a"),false,1)
	if cell.has("overflow"):
		draw_string(ReadableFont.readable(),rect.position+Vector2(0,15),"+%d"%int(cell.overflow),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,12,Color("e9d9ad"))
		return
	Icons.draw_symbol(self,str(cell.get("icon",cell.get("id",""))),rect.get_center(),Color.WHITE,0.42)
	var remaining := int(cell.get("remaining_ticks",-1))
	if remaining >= 0:
		draw_rect(Rect2(rect.position+Vector2(1,rect.size.y-10),Vector2(rect.size.x-2,9)),Color("152120"))
		draw_string(ReadableFont.readable(),rect.position+Vector2(0,rect.size.y-2),str(ceili(float(remaining)/20.0)),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,9,Color("f1c6a3") if harmful else Color("e0e0c0"))

func _bar(rect: Rect2, ratio: float, color: Color) -> void:
	draw_rect(rect,Color("101c1e"))
	if ratio > 0:
		var inner := rect.grow(-1)
		draw_rect(Rect2(inner.position,Vector2(floorf(inner.size.x*ratio),inner.size.y)),color)
		draw_line(inner.position,inner.position+Vector2(maxf(0,floorf(inner.size.x*ratio)-1),0),color.lightened(0.2),1)
	draw_rect(rect,Color("121717"),false,1)

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
