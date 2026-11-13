extends Control
## Passive selected-actor card. All cells inspect, none select/cast/submit.
const ThemeArt = preload("res://src/presentation/strategic_ui_theme.gd")
const FontArt = preload("res://src/presentation/strategic_font.gd")
const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const Preview = preload("res://src/presentation/strategic_roster_preview.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
var facts: Dictionary = {}
var compact := false
var heroic_2d := true

func _ready() -> void:
	name = "SelectedActorInspector"
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	hide()

func refresh(value: Dictionary) -> void:
	facts = value.duplicate(true)
	tooltip_text = str(facts.get("label",""))+"\n"+str(facts.get("description",""))
	queue_redraw()

func _source_layout() -> Dictionary:
	var cells: Array[Dictionary] = []
	var w := size.x-18
	cells.append({"key":"reserve","family":"reserve","rect":Rect2(9,47,w,13),"text":"有限储量 %d / %d；采出即扣减，不会因重建补回。" % [int(facts.get("remaining",0)),int(facts.get("initial",0))]})
	if bool(facts.get("automatic_income",false)):
		cells.append({"key":"income","family":"income","rect":Rect2(9,67,w,29),"text":"当前净收入%.1f金币/秒 · %s\n完全占领并建成%s后自动产出，无需工人。" % [float(facts.get("net_per_second",0.0)),str(facts.get("state_caption","未启用")),str(facts.get("required_building","经济建筑"))]})
	else:
		cells.append({"key":"workers","family":"workers","rect":Rect2(9,67,w,29),"text":"已派工%d / %d；共享来源上限，满员后自动分流或等待。" % [int(facts.get("assigned_workers",0)),int(facts.get("worker_capacity",5))]})
	cells.append({"key":"efficiency","family":"efficiency","rect":Rect2(9,99,w,28),"text":str(facts.get("description",""))})
	return {"portrait":Rect2(),"cells":cells,"compact":compact,"size":size,"id":facts.get("id","")}

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag: accept_event()

func layout_snapshot() -> Dictionary:
	if facts.get("collection") == "resource_sources": return _source_layout()
	var portrait := Rect2(8,25,38 if compact else 48,40 if compact else 50)
	var cells: Array[Dictionary] = []
	var stats: Array = facts.get("stats",[])
	var start_x := 56.0 if compact else 68.0
	var columns := 2 if compact else 3
	var cell_width := (size.x-start_x-8)/columns
	for index: int in range(mini(stats.size(),6 if compact else 9)):
		var stat: Dictionary = stats[index]
		cells.append({"key":"stat:"+str(stat.id),"family":"stats","rect":Rect2(start_x+(index%columns)*cell_width,25+(index/columns)*22,cell_width-3,20),"text":str(stat.label)+" "+str(stat.value)+"\n"+str(stat.description),"id":stat.id,"icon":stat.symbol,"value":stat.get("compact_value",stat.value)})
	var width := portrait.size.x
	cells.append({"key":"hp","family":"hp","rect":Rect2(8,73 if compact else 82,width,7),"text":"生命 %d/%d"%[int(facts.get("hp",0)),int(facts.get("max_hp",1))]})
	if int(facts.get("max_mana",0))>0: cells.append({"key":"mana","family":"mana","rect":Rect2(8,83 if compact else 92,width,7),"text":"法力 %d/%d\n施放主动技能需要足够法力。"%[int(facts.get("mana",0)),int(facts.get("max_mana",0))]})
	if facts.get("hero",false): cells.append({"key":"xp","family":"xp","rect":Rect2(8,93 if compact else 102,width,5),"text":"累计经验 %d／%s"%[int(facts.get("status",{}).get("xp",0)),str(facts.get("status",{}).get("next_level_xp","满级"))]})
	var skill_y := 104.0 if compact else 120.0
	var slot := 0
	for skill: Dictionary in facts.get("skills",[]):
		if slot>=4: break
		var rect := Rect2(8+slot*(36 if compact else 48),skill_y,32 if compact else 42,28 if compact else 34)
		var cooldown := int(skill.get("cooldown_ticks",0))
		cells.append({"key":"skill:"+str(skill.id),"family":"skills","rect":rect,"text":"%s · %d/%d阶\n%s\n%s"%[skill.get("name",skill.id),int(skill.get("rank",0)),int(skill.get("max_rank",3)),"被动" if skill.get("passive",false) else "未学习" if int(skill.get("rank",0))<=0 else "冷却%.1f秒"%(cooldown/20.0) if cooldown>0 else "就绪" if int(facts.get("mana",0))>=int(skill.get("mana_cost",0)) else "法力不足",skill.get("description","")],"icon":str(skill.id),"rank":int(skill.get("rank",0)),"passive":bool(skill.get("passive",false)),"cooldown_ticks":cooldown,"max_cooldown_ticks":int(skill.get("max_cooldown_ticks",1))})
		slot+=1
	var effects: Array = facts.get("effects",[])
	var count := mini(8,effects.size())
	var effect_y := 138.0 if compact else 162.0
	for index: int in range(count):
		var effect: Dictionary = effects[index]
		var text := str(effect.get("name","状态"))+"\n"+str(effect.get("description",""))
		if index==count-1 and effects.size()>count:
			for extra: Dictionary in effects.slice(count): text+="\n\n"+str(extra.get("name","状态"))+"\n"+str(extra.get("description",""))
		cells.append({"key":"effect:"+str(effect.get("kind",""))+":"+str(effect.get("source_id",""))+":"+str(effect.get("id","")),"family":"effects","rect":Rect2(8+index*(26 if compact else 32),effect_y,23 if compact else 28,22 if compact else 26),"text":text,"icon":str(effect.get("icon",effect.get("id",""))),"harmful":str(effect.get("kind","")).begins_with("DEBUFF"),"remaining_ticks":int(effect.get("remaining_ticks",-1)),"overflow":effects.size()-count if index==count-1 else 0})
	return {"portrait":portrait,"cells":cells,"compact":compact,"size":size,"id":facts.get("id","")}

func inspection_at(point: Vector2) -> Dictionary:
	for cell: Dictionary in layout_snapshot().cells:
		if Rect2(cell.rect).has_point(point): return cell.duplicate(true)
	return {}

func inspection_for(key: String) -> Dictionary:
	for cell: Dictionary in layout_snapshot().cells:
		if str(cell.key)==key: return cell.duplicate(true)
	return {}

func _draw() -> void:
	if facts.is_empty(): return
	if facts.get("collection") == "resource_sources":
		_draw_source()
		return
	ThemeArt.draw_surface(self,Rect2(Vector2.ZERO,size),"hero","normal")
	var layout := layout_snapshot()
	var font := FontArt.readable()
	draw_string(font,Vector2(9,17),str(facts.label),HORIZONTAL_ALIGNMENT_LEFT,size.x-60,14,Color("eadcb9"))
	draw_string(font,Vector2(size.x-55,17),"查阅",HORIZONTAL_ALIGNMENT_RIGHT,45,11,Color("9cad99"))
	var portrait: Rect2 = layout.portrait
	draw_rect(portrait,Color("18241f"))
	if str(facts.get("collection",""))=="buildings":
		Icons.draw_symbol(self,"tower",portrait.get_center(),Color("d6bc87"),0.8)
	else: Preview.draw_group(self,portrait.grow(-2),[facts.body],heroic_2d)
	draw_rect(portrait,Color("726c4e"),false,2)
	for cell: Dictionary in layout.cells:
		var rect: Rect2 = cell.rect
		match str(cell.family):
			"hp": _bar(rect,float(facts.hp)/maxi(1,int(facts.max_hp)),Palette.side_color(str(facts.body.get("side","PLAYER"))))
			"mana": _bar(rect,float(facts.mana)/maxi(1,int(facts.max_mana)),Color("5d9bd5"))
			"xp": _bar(rect,float(facts.get("status",{}).get("xp_ratio",0)),Color("b38ad1"))
			"stats":
				draw_rect(rect,Color("202c27"))
				var symbol := str({"attack":"damage","attack_speed":"STAT_ATTACK_SPEED","magic_resist":"STAT_MAGIC_RESIST","mana":"blue_bottle"}.get(str(cell.icon),cell.icon))
				Icons.draw_symbol(self,symbol,rect.position+Vector2(7,9),Color("cabb8d"),0.3)
				draw_string(font,rect.position+Vector2(17,14),str(cell.value),HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-17,11,Color("e0d7bd"))
			"skills","effects":
				draw_rect(rect,Color("18221e"))
				draw_rect(rect,Color("b47868") if cell.get("harmful",false) else Color("6e7762"),false,1)
				Icons.draw_symbol(self,str(cell.icon),rect.get_center()+Vector2(0,-2),Color.WHITE,0.43 if compact else 0.5)
				if str(cell.family)=="skills":
					if int(cell.get("rank",0))<=0: draw_rect(rect.grow(-1),Color(0.04,0.07,0.05,0.65))
					elif int(cell.get("cooldown_ticks",0))>0:
						var ratio := clampf(float(cell.cooldown_ticks)/maxi(1,int(cell.max_cooldown_ticks)),0,1)
						draw_rect(Rect2(rect.position,Vector2(rect.size.x,rect.size.y*ratio)),Color(0.03,0.06,0.05,0.7))
						draw_string(font,rect.position+Vector2(0,18),str(ceili(float(cell.cooldown_ticks)/20)),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,11,Color("e9d9b1"))
					draw_string(font,rect.position+Vector2(0,rect.size.y-2),str(cell.rank),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,9,Color("e3c474"))
				elif int(cell.get("overflow",0))>0:
					draw_rect(rect.grow(-2),Color(0.04,0.08,0.06,0.75))
					draw_string(font,rect.position+Vector2(0,16),"+%d"%int(cell.overflow),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,10,Color("e9d9ad"))
				elif int(cell.get("remaining_ticks",-1))>=0:
					draw_string(font,rect.position+Vector2(0,rect.size.y-2),str(ceili(float(cell.remaining_ticks)/20)),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,9,Color("e8c19f"))
	if facts.get("skills",[]).is_empty(): draw_string(font,Vector2(9,116 if compact else 138),str(facts.get("subtitle","")),HORIZONTAL_ALIGNMENT_LEFT,size.x-18,11,Color("b3bca5"))
	if facts.get("effects",[]).is_empty(): draw_string(font,Vector2(9,153 if compact else 179),"无额外状态",HORIZONTAL_ALIGNMENT_LEFT,size.x-18,11,Color("929f8a"))
	set_meta("painted_layout",layout)

func _draw_source() -> void:
	ThemeArt.draw_surface(self,Rect2(Vector2.ZERO,size),"hero","normal")
	var font := FontArt.readable()
	var automatic := bool(facts.get("automatic_income",false))
	var symbol := "gold" if automatic else "food" if facts.get("resource") == "FOOD" else "essence" if facts.get("resource") == "ESSENCE" else "material"
	Icons.draw_symbol(self,symbol,Vector2(22,20),Color("dccb93"),0.5)
	draw_string(font,Vector2(41,24),str(facts.label),HORIZONTAL_ALIGNMENT_LEFT,size.x-49,16,Color("eadcb9"))
	draw_string(font,Vector2(9,41),"储量 %d / %d" % [int(facts.remaining),int(facts.initial)],HORIZONTAL_ALIGNMENT_LEFT,size.x-18,12,Color("c4d0b0"))
	_bar(Rect2(9,47,size.x-18,13),float(facts.remaining)/maxi(1,int(facts.initial)),Color("c4a363") if symbol in ["gold","material"] else Color("ac92c1") if symbol == "essence" else Color("8ba66d"))
	Icons.draw_symbol(self,"gold" if automatic else "worker",Vector2(19,81),Color("ddc693"),0.38)
	var source_caption := "净入 %.1f/秒 · %s" % [float(facts.get("net_per_second",0.0)),str(facts.state_caption)] if automatic else "工人 %d / %d · %s" % [int(facts.assigned_workers),int(facts.worker_capacity),str(facts.state_caption)]
	draw_string(font,Vector2(36,86),source_caption,HORIZONTAL_ALIGNMENT_LEFT,size.x-44,13,Color("e2d5af"))
	var caption := "金币收入保留 %d%%" % int(facts.efficiency_percent) if automatic else "矿材交付 %d%%" % int(facts.efficiency_percent) if facts.resource == "MATERIAL" else "不受维护费影响"
	draw_string(font,Vector2(10,118),caption,HORIZONTAL_ALIGNMENT_LEFT,size.x-20,13,Color("d2bd87"))
	draw_string(font,Vector2(10,145),"完整占领后自动开采" if automatic else "在经营中分派工人",HORIZONTAL_ALIGNMENT_LEFT,size.x-20,11,Color("a5b395"))
	set_meta("painted_layout",layout_snapshot())

func _bar(rect: Rect2,ratio: float,color: Color) -> void:
	draw_rect(rect,Color("0d1919"))
	var inside := rect.grow(-1)
	draw_rect(Rect2(inside.position,Vector2(floorf(inside.size.x*clampf(ratio,0,1)),inside.size.y)),color)
	draw_rect(rect,Color("101816"),false,1)
