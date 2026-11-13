extends Control
## Deliberately choreographed visual plate, NOT a Combat or Session instance.
const Catalog = preload("res://src/presentation/strategic_effects_catalog.gd")
const Units = preload("res://src/presentation/heroic_pixel_units.gd")
const Readout = preload("res://src/presentation/heroic_actor_readout.gd")
const Effects = preload("res://src/presentation/heroic_combat_effects.gd")
const Collection = preload("res://src/presentation/heroic_collection.gd")
const Terrain = preload("res://src/presentation/heroic_collection_terrain.gd")
const Chrome = preload("res://src/presentation/strategic_chrome.gd")
const FontClass = preload("res://src/presentation/strategic_font.gd")
const UnitCatalog = preload("res://src/simulation/strategic_unit_catalog.gd")
const GroundDetail = preload("res://src/presentation/heroic_ground_detail.gd")
const AuraArt = preload("res://src/presentation/heroic_aura_art.gd")
const Empowerment = preload("res://src/presentation/heroic_empowerment_art.gd")
var actor: Dictionary = {}
var ability: Dictionary = {}
var elapsed := 0.0
var rank := 1
var magnification := 1.5
var background := "DARK"
var facing := Vector2.RIGHT
var _target_body: Dictionary = {}
var _ground_key := ""
var _ground_texture: Texture2D
var _frame_cache: Dictionary = {}

func preview_audio_events_between(previous:float,current:float)->Array[Dictionary]:
	# Stage choreography is explicit audition, never a simulated cast/hit.
	var result:Array[Dictionary]=[]
	if actor.is_empty() or ability.is_empty() or not is_finite(previous) or not is_finite(current) or current<previous:return result
	var sample:=Catalog.sample(actor,ability,rank,0.65)
	var body:Dictionary=sample.unit
	var skill:Dictionary=sample.skill
	var kind:=str(ability.kind)
	var cue:={"hero_archetype":str(body.get("hero_archetype","")),"unit_type":str(body.get("unit_type","")),"faction_id":str(body.get("faction_id","")),"rank":rank,"attack_type":str(skill.get("attack_type",body.get("attack_type","EDGE"))),"preview_only":true,"ultimate":bool(skill.get("ultimate",false))}
	if kind in ["SKILL","NEUTRAL","SUPPORT"]:cue.merge({"kind":"SKILL","skill_id":str(ability.id),"sound_phase":"CAST"})
	elif kind=="STATUS":cue.merge({"kind":"STATUS","status_kind":str(ability.id).trim_prefix("STATUS:")})
	elif kind in ["PASSIVE","INNATE","ITEM_AURA"]:cue.merge({"kind":"BUFF","skill_id":str(ability.id),"status_kind":"AURA"})
	else:cue["kind"]="HEAL" if str(ability.id)=="HEAL" else "ATTACK"
	if previous<0.2 and current>=0.2:result.append({"marker":"start","cue":cue.duplicate(true)})
	if previous<0.84 and current>=0.84 and kind not in ["STATUS","PASSIVE","INNATE","ITEM_AURA"]:
		var impact:=cue.duplicate(true)
		var effect:=str(skill.get("effect",""))
		impact["kind"]="HEAL" if str(ability.id)=="HEAL" or effect=="HEAL" else "BUFF" if effect in ["RALLY","ARMOR_BUFF","DAMAGE_BUFF"] else "CONTROL" if effect in ["STUN","ROOT","SLOW"] else "HIT"
		impact["status_kind"]=effect
		impact["sound_phase"]="IMPACT"
		result.append({"marker":"impact","cue":impact})
	return result

class MeasureCanvas extends RefCounted:
	var bounds := Rect2()
	var has_bounds := false
	func include_rect(rect: Rect2) -> void:
		if not rect.position.is_finite() or not rect.size.is_finite(): return
		bounds=bounds.merge(rect) if has_bounds else rect
		has_bounds=true
	func draw_colored_polygon(points: PackedVector2Array, _color: Color) -> void:
		if points.is_empty(): return
		var rect := Rect2(points[0],Vector2.ZERO)
		for point: Vector2 in points: rect=rect.expand(point)
		include_rect(rect)
	func draw_texture_rect_region(_texture: Texture2D, rect: Rect2, _region: Rect2, _tint: Color=Color.WHITE) -> void: include_rect(rect)

func _frame_sample(sample: Dictionary) -> Dictionary:
	var unit: Dictionary=sample.unit
	var skill: Dictionary=sample.skill
	var self_cast: bool = not skill.is_empty() and skill.get("target_mode")=="SELF"
	var persistent: Dictionary=sample.persistent
	var allied_recipients: bool = self_cast and int(skill.get("ally_heal",0))>0
	var has_target: bool = (not self_cast or allied_recipients) and persistent.is_empty() and sample.kind!="STATUS"
	var separation := clampf(float(unit.get("attack_range",80)),100,260)
	if not skill.is_empty():
		separation=clampf(float(skill.get("ally_radius",145))*0.5,45,115) if allied_recipients else clampf(float(skill.get("range",240))*0.45,45,160)
	var source := Vector2.ZERO
	var target := Vector2(separation*facing.x,0) if has_target else Vector2.ZERO
	var aim := Vector2(float(skill.get("range",240))*facing.x,0) if has_target and str(skill.get("delivery","AREA"))=="LINE" else target
	# Explicit visual fixtures follow the canonical cap and delivery. These are
	# not inferred victims: no simulation or nearby-target search runs here.
	var points: Array=[]
	var extra_count := mini(2,maxi(0,int(skill.get("max_targets",1))-1)) if has_target else 0
	var delivery := str(skill.get("delivery","AREA"))
	if delivery=="SINGLE": extra_count=0
	for index: int in range(extra_count):
		var side := -1.0 if index==0 else 1.0
		var local: Vector2
		if allied_recipients:
			local=Vector2(-separation*0.55,side*separation*0.65)
		elif delivery=="LINE":
			local=target+Vector2(float(skill.get("range",240))*0.18*(index+1)*facing.x,0)
		elif delivery=="CONE":
			var half_angle := atan(float(skill.get("cone_width",180))/(2.0*maxf(1,float(skill.get("range",240)))))
			var angle := half_angle*0.45*side
			local=Vector2(separation*facing.x,0).rotated(angle)*(1.15+index*0.1)
		elif delivery=="CHAIN":
			var jump := float(skill.get("chain_range",110))*0.35
			local=target+Vector2(jump*(index+1)*facing.x,jump*side*0.55)
		else:
			var radius := float(skill.get("radius",80))*0.45
			local=target+Vector2(radius*0.35*facing.x,radius*side)
		points.append(local)
	var key := str(actor.id)+":"+str(ability.id)+":"+str(rank)+":"+str(facing.x)
	var bounds: Rect2
	if _frame_cache.has(key): bounds=_frame_cache[key]
	else:
		var measure := MeasureCanvas.new()
		var body_bounds := Units.stable_visual_bounds(unit,float(unit.get("visual_radius",unit.get("radius",12))))
		measure.include_rect(body_bounds.grow(14))
		# Reserve true continuous ornament bounds even if the first sampled
		# frame precedes its onset. Cache identity cannot depend on cast phase.
		var later:=Catalog.sample(actor,ability,rank,1.8)
		var facts:=Empowerment.read(later.unit,Empowerment.prepare({"tick":36,"soldiers":[later.unit]}))
		var ornaments:=Empowerment.plan(source,later.unit,facts,36,1.0,body_bounds)
		Empowerment.draw(measure,ornaments,"REAR");Empowerment.draw(measure,ornaments,"FRONT")
		var bars := Readout.bars(unit,body_bounds)
		if bars.has("hp"): measure.include_rect(bars.hp)
		if bars.has("mana") and Rect2(bars.mana).has_area(): measure.include_rect(bars.mana)
		if has_target:
			var target_bounds := Units.stable_visual_bounds(_target_body,12)
			target_bounds.position+=target; measure.include_rect(target_bounds.grow(12))
			for point: Vector2 in points:
				var extra := target_bounds; extra.position+=point-target
				measure.include_rect(extra)
		if not persistent.is_empty():
			var radius := float(persistent.radius)
			if radius>0: measure.include_rect(Rect2(-Vector2.ONE*radius,Vector2.ONE*radius*2))
			else: measure.include_rect(Rect2(-55,-55,110,110))
		elif sample.kind!="STATUS":
			# Actual shared renderer geometry at 19 phases, cached per selection.
			# This avoids shrinking every spell to a conservative worst-case box.
			for step: int in range(21):
				var probe: Dictionary=sample.pose.duplicate(true)
				probe.phase=minf(float(step)/20.0,0.999)
				probe.action="SKILL_"+str(ability.id) if sample.kind in ["SKILL","NEUTRAL","SUPPORT"] else str(ability.id)
				probe.direction=facing
				Effects.draw_action(measure,source,aim,unit,probe,1.0,[target]+points if has_target else [])
		else: measure.include_rect(Rect2(-65,-100,130,135))
		bounds=measure.bounds
		if _frame_cache.size()>=512: _frame_cache.clear()
		_frame_cache[key]=bounds
	var content := Rect2(32,55,maxf(size.x-64,1),maxf(size.y-113,1))
	var fit := minf(content.size.x/maxf(bounds.size.x,1),content.size.y/maxf(bounds.size.y,1))
	var factor := minf(magnification,fit)
	var offset := content.get_center()-bounds.get_center()*factor
	var screen_points: Array=[]
	for point: Vector2 in points: screen_points.append((offset+point*factor).round())
	return {"source":(offset+source*factor).round(),"target":(offset+target*factor).round(),"aim":(offset+aim*factor).round(),"scale":factor,"points":screen_points,"has_target":has_target,"bounds":bounds,"content":content}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents=true
	_target_body=UnitCatalog.stats_for("hinge_guard")
	_target_body.merge({"side":"AI","alive":true,"hp":500},true)
	resized.connect(queue_redraw)

func _draw() -> void:
	Chrome.draw_material(self,Rect2(Vector2.ZERO,size),"map")
	var inset := Rect2(8,8,size.x-16,size.y-16)
	draw_rect(inset,Color("20282c") if background=="DARK" else Color("353d31"))
	if actor.is_empty() or ability.is_empty(): return
	var faction := str(actor.unit.faction_id)
	if background=="FIELD":
		_bake_ground(faction,inset.size)
		if _ground_texture!=null: draw_texture_rect(_ground_texture,inset,false)
		# Framing foliage uses the very same licensed terrain adapter as maps.
		# Fixed edge positions cannot be mistaken for gameplay obstacles.
		for index: int in range(4):
			var point := Vector2(52+index*25,100+(index%2)*16) if index<2 else Vector2(size.x-98+(index-2)*30,78+(index%2)*20)
			Terrain.draw_prop(self,point,{"kind":"TREE","id":"theater-tree-"+str(index),"radius":19},faction,1.0)
		Terrain.draw_prop(self,Vector2(size.x-53,size.y-55),{"kind":"RUIN","id":"theater-rock","radius":14},faction,1.0)
		# Quiet center retains body/weapon contrast; no blur or particle field.
		draw_rect(inset,Color(0.03,0.06,0.05,0.27))
	else:
		for y: int in range(8,int(size.y)-8,32):
			for x: int in range(8,int(size.x)-8,32):
				if (x/32+y/32)%2==0: draw_rect(Rect2(x,y,minf(32,inset.end.x-x),minf(32,inset.end.y-y)),Color("252e32"))
	var sample := Catalog.sample(actor,ability,rank,elapsed)
	var unit: Dictionary=sample.unit
	var frame := _frame_sample(sample)
	var scale_factor := float(frame.scale)
	var source: Vector2=frame.source
	var target: Vector2=frame.target
	var aim: Vector2=frame.aim
	# Persistent samples use the exact authority radius at the selected scale.
	# A single-unit passive never borrows a fabricated range circle.
	var persistent: Dictionary=sample.persistent
	if not persistent.is_empty():
		persistent.slot=0
		Readout.draw_aura_source(self,source,{"radius":persistent.radius,"side":"PLAYER","identities":[persistent]},scale_factor,false)
	var points: Array = frame.points
	var skill: Dictionary=sample.skill
	var target_body: Dictionary = _target_body.duplicate(true)
	var allied_sample:bool = str(sample.pose.action)=="HEAL" or str(skill.get("target_mode",""))=="ALLY" or int(skill.get("ally_heal",0))>0 or (sample.kind=="SUPPORT" and str(skill.get("effect","")) not in ["STUN","ROOT","SLOW","DAMAGE"])
	if allied_sample: target_body.side="PLAYER"
	var target_pose := {"action":"IDLE","direction":-facing,"phase":0.0}
	for point: Vector2 in ([target]+points if bool(frame.has_target) else []):
		_shadow(point,scale_factor)
		Units.draw(self,point,target_body,12*scale_factor,target_pose)
	_shadow(source,scale_factor)
	Readout.draw_hero_ellipse(self,source,unit,Units.ground_footprint(unit,float(unit.get("visual_radius",unit.get("radius",12)))*scale_factor),scale_factor)
	var pose: Dictionary=sample.pose
	pose.direction=facing
	var benefit_tick:=int(float(sample.elapsed)*20)
	var benefits:=Empowerment.read(unit,Empowerment.prepare({"tick":benefit_tick,"soldiers":[unit]}))
	var ornament:=Empowerment.plan(source,unit,benefits,benefit_tick,scale_factor,Units.stable_visual_bounds(unit,float(unit.get("visual_radius",unit.get("radius",12)))*scale_factor))
	Empowerment.draw(self,ornament,"REAR")
	Units.draw(self,source,unit,float(unit.get("visual_radius",unit.get("radius",12)))*scale_factor,pose)
	Empowerment.draw(self,ornament,"FRONT")
	Readout.draw_bars(self,source,unit,Units.stable_visual_bounds(unit,float(unit.get("visual_radius",unit.get("radius",12)))*scale_factor))
	if bool(sample.active): Effects.draw_action(self,source,aim,unit,pose,scale_factor,[target]+points if bool(frame.has_target) else [])
	var status: Dictionary=sample.status
	if not status.is_empty():
		var center := source if sample.kind in ["PASSIVE","INNATE"] or status.kind in ["AURA","HEAL","GUARD","FERVOR"] else target
		Effects.draw_status(self,center,center+Vector2(0,-48)*scale_factor,unit,status,int(elapsed*20),scale_factor)
	# Hit animation remains an explicit visual sample, never fabricated HP loss.
	if sample.kind not in ["STATUS","PASSIVE","INNATE"] and sample.active and float(pose.phase)>0.58:
		var hit: Dictionary = target_body.duplicate(true)
		hit["last_damage_attack_type"]=str(skill.get("attack_type",unit.get("attack_type","EDGE")))
		hit["last_damage_source_faction"]=faction
		if str(pose.action)!="HEAL" and str(skill.get("effect","")) not in ["HEAL","RALLY","ARMOR_BUFF","DAMAGE_BUFF"]:
			Effects.draw_hit(self,target+Vector2(0,-12),hit,{"amount":1,"phase":(float(pose.phase)-0.58)/0.42},scale_factor)
	_caption(Vector2(18,28),"视觉演武  /  "+str(ability.label),19,Color("e8d3a2"))
	_caption(Vector2(18,size.y-16),"固定靶位 · 不代表范围、命中或伤害结算",14,Color("c6c6ad"))
	if scale_factor<magnification: _caption(Vector2(size.x-150,28),"完整取景 %.2f×"%scale_factor,13,Color("b6c6ad"))
	_caption(Vector2(18,size.y-42),"施放者："+str(actor.label),16,Color("f0dfaa"))
	if bool(frame.has_target): _caption(Vector2(size.x-190,size.y-42),"目标：友军靶位" if allied_sample else "目标：展示靶位",15,Color("c0b7a0"))
	if not persistent.is_empty():
		Chrome.draw_material(self,Rect2(size.x-110,54,94,94),"stone")
		AuraArt.draw_mark(self,Vector2(size.x-63,91),persistent,2.0)
		_caption(Vector2(size.x-104,127),"徽纹放大",12,Color("b6c6ad"))
	set_meta("sample",{"visual_only":true,"unit_id":actor.id,"ability":ability.id,"rank":rank,"extra_targets":points.size(),"display_scale":scale_factor,"framed_geometry":frame.bounds,"content_rect":frame.content,"persistent":persistent.duplicate(true),"enhancements":benefits.duplicate(true),"enhancement_operations":ornament.size(),"effect":Effects.inspect_action(unit,pose)})

func _shadow(point: Vector2, factor: float) -> void:
	for row: int in range(-3,4):
		var width := (8-absi(row))*2*factor
		draw_rect(Rect2((point+Vector2(-width,row*2*factor)).round(),Vector2(width*2,2*factor)),Color(0.04,0.05,0.06,0.36))

func _bake_ground(faction: String, dimensions: Vector2) -> void:
	var key := faction+":"+str(dimensions)
	if key==_ground_key: return
	_ground_key=key
	_ground_texture=null
	var tile := Terrain.inspect_ground(faction)
	var sheet := Collection.image("overworld",str(tile.file))
	if sheet==null: return
	var raster_size := Vector2i((dimensions/2).ceil())
	var raster := Image.create(raster_size.x,raster_size.y,false,Image.FORMAT_RGBA8)
	for y: int in range(0,raster_size.y,16):
		for x: int in range(0,raster_size.x,16): raster.blit_rect(sheet,tile.rect,Vector2i(x,y))
	var cells := {}
	for y: int in range(0,ceili(float(raster_size.y)/16)):
		for x: int in range(0,ceili(float(raster_size.x)/16)):
			# Grass clumps frame the field rather than filling the actor area.
			var edge_cluster := (x<5 and y>raster_size.y/16-5) or (x>raster_size.x/16-7 and y<4)
			if edge_cluster and GroundDetail.meadow(Vector2(x*32,y*32),1701): cells[Vector2i(x,y)]=faction
	# Author edges contain alpha; composite over the base rather than punching
	# rectangular holes through it. The licensed source sheet stays unchanged.
	for cell: Vector2i in cells: raster.blend_rect(sheet,GroundDetail.patch_rect(cell,cells),cell*16)
	var palette := GroundDetail.palette(sheet.get_region(tile.rect),sheet.get_region(GroundDetail.AUTHOR_PATCH))
	if not palette.is_empty(): GroundDetail.paint(raster,Rect2(Vector2.ZERO,dimensions),2,{},1701,[palette])
	_ground_texture=ImageTexture.create_from_image(raster)

func _caption(point: Vector2, text: String, font_size: int, color: Color, width: float=-1) -> void:
	# Bright snow must not erase the actor/sample labels. Discrete two-pixel
	# ink offsets, not a blurred shadow, preserve the shared pixel silhouette.
	for offset: Vector2 in [Vector2(-2,0),Vector2(2,0),Vector2(0,-2),Vector2(0,2)]:
		draw_string(FontClass.readable(),point+offset,text,HORIZONTAL_ALIGNMENT_CENTER if width>0 else HORIZONTAL_ALIGNMENT_LEFT,width,font_size,Color("172020"))
	draw_string(FontClass.readable(),point,text,HORIZONTAL_ALIGNMENT_CENTER if width>0 else HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color)
