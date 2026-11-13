extends RefCounted
## Read-only all-roster pixel spectacle. Actual catalogs/events own all rules.
const A=preload("res://src/presentation/heroic_roster_v5_human_undead.gd")
const B=preload("res://src/presentation/heroic_roster_v5_machine_highland.gd")
const C=preload("res://src/presentation/heroic_roster_v5_forest_underground.gd")
const Heroes=preload("res://src/simulation/strategic_hero_catalog.gd")
const Readout=preload("res://src/presentation/heroic_actor_readout.gd")
const MaterialV6=preload("res://src/presentation/heroic_elemental_finish_v6.gd")
const PixelFxR8=preload("res://src/presentation/heroic_pixel_fx_r8.gd")
const CellBrushR8=preload("res://src/presentation/m63_av_brush.gd")
const PrebakedV9=preload("res://src/presentation/heroic_prebaked_atlas_v9.gd")
const SIZE:=192
const FRAMES:=12
const ANCHOR:=Vector2(96,136)
const MAX_TEXTURES:=24
const MAX_ENTRIES:=48
const MAX_LINKS:=24
const V4_HEROES:=["CINDER_TESTATOR","MYCELIAL_CATALYST"]
static var _rows:Dictionary={}
static var _atlases:Dictionary={}
static var _order:Array[String]=[]
static var _bakes:=0
static var _compiled=PrebakedV9.new()
static var _fallback_requests:=0
static func _all()->Dictionary:
	if _rows.is_empty():
		for owner:Variant in [A,B,C]:_rows.merge(owner.PROFILES)
	return _rows
static func profiles()->Dictionary:return _all().duplicate(true)
static func has_profile(id:String)->bool:return _all().has(id)
static func _row(id:String)->Dictionary:return _all().get(id,{})
static func owner(id:String)->Variant:
	if A.PROFILES.has(id):return A
	if B.PROFILES.has(id):return B
	return C if C.PROFILES.has(id) else null
static func frame_image(id:String,phase:String,frame:int)->Image:
	var image:=Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
	var painter=owner(id)
	if painter!=null and phase in ["CAST","CONTACT","TAIL","AURA"]:painter.paint(image,id,phase,posmod(frame,FRAMES))
	# Refine the accepted per-skill silhouette; never alter a rule or timer.
	# Accepted V4 profiles are explicit no-ops inside the finish module.
	if painter!=null:MaterialV6.enhance(image,id,_row(id),phase,posmod(frame,FRAMES))
	if painter!=null:PixelFxR8.enhance(image,id,_row(id),phase,posmod(frame,FRAMES))
	return image
static func reset_cache()->void:
	_atlases.clear();_order.clear();_bakes=0
	_compiled.reset();_fallback_requests=0
static func prepare_match(hero_ids:Array[String],manifest_path:String=PrebakedV9.DEFAULT_MANIFEST)->Dictionary:
	# Outside draw/tick: release this producer's old references, never the
	# CanvasItem references still owned by its retained drawing commands.
	reset_cache()
	var configured:Dictionary=_compiled.configure(manifest_path)
	if not bool(configured.get("accepted",false)):return configured
	return _compiled.prepare(hero_ids)
static func debug_stats()->Dictionary:
	return {"textures":_atlases.size(),"capacity":MAX_TEXTURES,"bakes":_bakes,"procedural_bakes":_bakes,"fallback_requests":_fallback_requests,"compiled":_compiled.diagnostics(),"pixel_bytes":_atlases.size()*SIZE*SIZE*FRAMES*4,"maximum_pixel_bytes":MAX_TEXTURES*SIZE*SIZE*FRAMES*4,"entries":MAX_ENTRIES,"links":MAX_LINKS,"version":"hero-roster-pixel-r8-prebaked-v9"}
static func _atlas(id:String,phase:String)->Texture2D:
	if not has_profile(id):return null
	var ready:Texture2D=_compiled.texture(id,phase)
	if ready!=null:return ready
	var key:=id+":"+phase
	if _atlases.has(key):_order.erase(key);_order.append(key);return _atlases[key]
	# Missing, stale or rejected packs remain visible through the preserved
	# author path; diagnostics make this expensive fallback explicit.
	_fallback_requests+=1
	var image:=Image.create(SIZE*FRAMES,SIZE,false,Image.FORMAT_RGBA8)
	for n:int in range(FRAMES):image.blit_rect(frame_image(id,phase,n),Rect2i(0,0,SIZE,SIZE),Vector2i(n*SIZE,0))
	var texture:=ImageTexture.create_from_image(image)
	while _order.size()>=MAX_TEXTURES:_atlases.erase(_order.pop_front())
	_atlases[key]=texture;_order.append(key);_bakes+=1
	return texture
static func begin_draw(canvas:Object)->void:
	# CanvasItem owns every texture referenced by its latest draw commands.
	# New _draw has cleared the old command list; do not release at end_draw.
	if canvas is CanvasItem:
		canvas.set_meta("roster_v5_textures",[])
		canvas.set_meta("roster_v5_prepared",true)
static func _visible(body:Dictionary,side:String)->bool:
	return not body.is_empty() and Readout.visible_to(body,side) and (body.get("position") is Vector2 or body.get("position") is Vector2i) and Vector2(body.position).is_finite()
static func _living(body:Dictionary)->bool:return int(body.get("hp",0))>0 and bool(body.get("alive",true))
static func _entry(id:String,phase:String,point:Vector2,first:int,last:int,tick:int,source:String,target:String="")->Dictionary:
	return {"id":id,"phase":phase,"position":point,"frame":clampi(floori(float(tick-first)/maxi(1,last-first)*FRAMES),0,FRAMES-1),"scale":1.0,"alpha":1.0,"angle":0.0,"source_id":source,"target_id":target,"start_tick":first,"expires_tick":last,"layer":"FRONT"}
static func _skill_for(body:Dictionary,id:String)->Dictionary:
	var hero:=str(body.get("hero_archetype",""))
	if hero not in Heroes.ARCHETYPES or str(_row(id).get("hero",""))!=hero:return {}
	if id not in Heroes.profile(hero).get("skill_ids",[]):return {}
	return Heroes.skill_at_level(id,int(body.get("last_skill_level",1)))
static func plan(snapshot:Dictionary,side:String="PLAYER")->Dictionary:
	var tick:=int(snapshot.get("tick",0))
	var bodies:={};var officers:={};var entries:Array[Dictionary]=[];var quiet:Array[Dictionary]=[];var links:Array[Dictionary]=[]
	for body:Dictionary in snapshot.get("soldiers",[]):bodies[str(body.get("id",""))]=body
	for officer:Dictionary in snapshot.get("heroes",{}).get("officers",[]):officers[str(officer.get("id",""))]=officer
	for source_id:String in bodies:
		var body:Dictionary=bodies[source_id]
		var hero:=str(body.get("hero_archetype",""))
		if body.get("unit_type","")!="hero" or hero in V4_HEROES or not _visible(body,side):continue
		var live:=_living(body)
		if live:
			var passive:="INNATE_"+hero
			if has_profile(passive) and not body.get("innate",{}).is_empty():
				var mark:=_entry(passive,"AURA",Vector2(body.position),tick-12,tick+12,tick,source_id)
				mark.frame=posmod(tick/4,FRAMES);mark.scale=.38;mark.alpha=.5;mark.layer="REAR";quiet.append(mark)
			for skill:Dictionary in officers.get(source_id,{}).get("skills",[]):
				if int(skill.get("level",0))<=0 or not bool(skill.get("passive",false)) or not has_profile(str(skill.id)):continue
				var mark:=_entry(str(skill.id),"AURA",Vector2(body.position),tick-12,tick+12,tick,source_id)
				mark.frame=posmod(tick/4,FRAMES);mark.scale=.44;mark.alpha=.6;mark.layer="REAR";quiet.append(mark)
		var first:=int(body.get("last_skill_tick",-1000000));var age:=tick-first
		var id:=str(body.get("last_skill_id",""))
		if age<0 or age>=32 or not has_profile(id):continue
		var skill:=_skill_for(body,id)
		if skill.is_empty() or bool(skill.get("passive",false)):continue
		if live and age<14:
			var cast:=_entry(id,"CAST",Vector2(body.position),first,first+14,tick,source_id)
			cast.scale=1.12 if bool(skill.ultimate) else .94
			entries.append(cast)
		var duration:=32 if bool(skill.get("ultimate",false)) else 24
		if age>=duration:continue
		# Only settled target records or actual HEAL/BUFF feedback establish contact.
		var targets:Array[Dictionary]=[];var seen:={}
		for hit:Dictionary in body.get("last_skill_targets",[]):
			var victim:Dictionary=bodies.get(str(hit.get("id","")),{})
			if not _visible(victim,side):continue
			if str(skill.effect) in ["ROOT","STUN"] and int(victim.get("root_until_tick" if skill.effect=="ROOT" else "stun_until_tick",-1))<=tick:continue
			targets.append({"id":str(victim.id),"position":Vector2(hit.get("position",victim.position))});seen[str(victim.id)]=true
		for event:Dictionary in snapshot.get("combat_feedback_events",[]).slice(-256):
			if int(event.get("tick",-1))!=first or str(event.get("source",{}).get("id",""))!=source_id or str(event.get("skill_id",""))!=id or event.get("kind","") not in ["HEAL","BUFF"]:continue
			var target_id:=str(event.get("target",{}).get("id",""));var victim:Dictionary=bodies.get(target_id,{})
			if seen.has(target_id) or not _visible(victim,side):continue
			targets.append({"id":target_id,"position":Vector2(event.target.get("position",victim.position))});seen[target_id]=true
		# ARMOR_BUFF has a true guard timer but no dedicated BUFF receipt.
		if str(skill.effect)=="ARMOR_BUFF" and live and int(body.get("guard_until_tick",-1))>tick and not seen.has(source_id):targets.append({"id":source_id,"position":Vector2(body.position)})
		if targets.is_empty():continue
		var center:=Vector2.ZERO
		for target:Dictionary in targets:center+=Vector2(target.position)
		center/=targets.size()
		var contact:=_entry(id,"CONTACT",center,first,first+duration,tick,source_id,str(targets[0].id))
		contact.scale=1.3 if bool(skill.ultimate) else 1.05;contact.alpha=minf(1,float(duration-age)/8)
		if skill.get("delivery","") in ["LINE","CONE"]:contact.angle=(center-Vector2(body.position)).angle()
		entries.append(contact)
		# A path of material, not an additional damaging projectile or channel.
		if live and age<16:
			var previous:=Vector2(body.position)
			for target:Dictionary in targets.slice(0,4):
				if previous.distance_squared_to(Vector2(target.position))>36:links.append({"id":id,"origin":previous,"end":Vector2(target.position),"phase":float(age)/16,"alpha":1-float(age)/16})
				if skill.get("delivery","")=="CHAIN":previous=Vector2(target.position)
				else:break
	# Long-lived signatures and paid enhancements are anchored to true live facts.
	for target_id:String in bodies:
		var target:Dictionary=bodies[target_id]
		if not _visible(target,side) or not _living(target):continue
		var used:={}
		for status:Dictionary in target.get("status_effects",[]):
			var id:=str(status.get("skill_id",status.get("id","")))
			var source_id:=str(status.get("source_id",""));var source:Dictionary=bodies.get(source_id,{})
			if not has_profile(id) or bool(_row(id).get("preserve_v4",false)) or used.has(id):continue
			if int(status.get("expires_tick",-1))<=tick:continue
			# Paid finite buffs may outlive their source; the published timer /
			# charge state, not the caster's life, owns their lifetime.
			var e:=_entry(id,"TAIL",Vector2(target.position),tick-12,tick+12,tick,source_id,target_id)
			e.frame=posmod(tick/3,FRAMES);e.scale=.68;e.alpha=.65;e.layer="REAR";quiet.append(e);used[id]=true
		# Generic control's public status list omits identity, but the body
		# publishes the real owner skill and expiry. Never guess from proximity.
		for prefix:String in ["root","stun"]:
			var id:=str(target.get(prefix+"_skill_id",""))
			var until:=int(target.get(prefix+"_until_tick",-1))
			if until<=tick or not has_profile(id) or bool(_row(id).get("preserve_v4",false)) or used.has(id):continue
			var e:=_entry(id,"TAIL",Vector2(target.position),tick-12,until,tick,str(target.get(prefix+"_source_id","")),target_id)
			e.frame=posmod(tick/3,FRAMES);e.scale=.8;e.alpha=.65;e.layer="REAR";quiet.append(e);used[id]=true
	entries.append_array(quiet)
	var dropped:=maxi(0,entries.size()-MAX_ENTRIES)+maxi(0,links.size()-MAX_LINKS)
	return {"entries":entries.slice(0,MAX_ENTRIES),"links":links.slice(0,MAX_LINKS),"tick":tick,"dropped":dropped}
static func body_offset(body:Dictionary,tick:int)->Vector2:
	if not _living(body) or str(body.get("hero_archetype","")) in V4_HEROES or body.get("unit_type","")!="hero" or int(body.get("last_move_tick",-1))==tick:return Vector2.ZERO
	var age:=tick-int(body.get("last_skill_tick",-1000000))
	if age<0 or age>=14 or not has_profile(str(body.get("last_skill_id",""))):return Vector2.ZERO
	var p:=float(age)/14
	var aim:=Vector2(body.get("last_skill_target_position",body.position))-Vector2(body.position)
	return (-aim.normalized()*sin(p*PI)*3+Vector2(0,-sin(p*PI)*2)).limit_length(3).round()
static func _sprite(canvas:Object,e:Dictionary,point:Vector2,factor:float)->int:
	var texture:=_atlas(str(e.id),str(e.phase))
	if texture==null:return 0
	var scale:=factor*float(e.get("scale",1))
	if canvas is CanvasItem:
		if not canvas.get_viewport_rect().grow(SIZE*scale).has_point(point):return 0
		var held:Array=canvas.get_meta("roster_v5_textures",[]);held.append(texture);canvas.set_meta("roster_v5_textures",held)
	canvas.draw_set_transform(point.round(),float(e.get("angle",0)),Vector2.ONE*scale)
	canvas.draw_texture_rect_region(texture,Rect2(-ANCHOR,Vector2(SIZE,SIZE)),Rect2(clampi(int(e.frame),0,FRAMES-1)*SIZE,0,SIZE,SIZE),Color(1,1,1,float(e.get("alpha",1))))
	canvas.draw_set_transform(Vector2.ZERO)
	return 1
static func draw(canvas:Object,prepared:Dictionary,project:Callable,factor:float,layer:String="FRONT")->int:
	if not is_finite(factor) or factor<=0:return 0
	var count:=0
	if layer=="REAR":
		for link:Dictionary in prepared.get("links",[]).slice(0,MAX_LINKS):
			var row:=_row(str(link.id));var palette:Array=row.get("palette",[])
			if palette.size()<5:continue
			var a:Vector2=project.call(Vector2(link.origin))+Vector2(0,-28)*factor
			var b:Vector2=project.call(Vector2(link.end))+Vector2(0,-25)*factor
			var mode:=int(row.get("route_mode",absi(str(row.get("connection","")).hash())%8))
			var ink:={"canvas":canvas,"count":0,"draw_limit":40,"quantum":maxf(1.0,2.0*factor)}
			for n:int in range(8):
				var t0:=float(n)/8;var t1:=float(n+1)/8
				if mode==1 and n%3==1:continue
				var c0:=_route(a,b,t0,mode,float(link.phase),factor)
				var c1:=_route(a,b,t1,mode,float(link.phase),factor)
				CellBrushR8.streak(ink,c0.round(),c1.round(),6*factor,Color(Color(str(palette[0])),float(link.alpha)*.6))
				CellBrushR8.streak(ink,c0.round(),c1.round(),2*factor,Color(Color(str(palette[3])),float(link.alpha)*.85));count+=2
			for n:int in range(3):
				var t:=fposmod(float(link.phase)+float(n)/3,1)
				if mode==5:t=1-t
				var p:=_route(a,b,t,mode,float(link.phase),factor)
				canvas.draw_rect(Rect2(p.round(),Vector2(4,3)*factor),Color(Color(str(palette[4])),float(link.alpha)));count+=1
	for e:Dictionary in prepared.get("entries",[]).slice(0,MAX_ENTRIES):
		if e.get("layer","FRONT")==layer:count+=_sprite(canvas,e,project.call(Vector2(e.position)),factor)
	return count
static func _route(a:Vector2,b:Vector2,t:float,mode:int,phase:float,factor:float)->Vector2:
	var normal:=(b-a).normalized().orthogonal()
	var offset:=Vector2.ZERO
	match mode:
		0,1:offset=Vector2(0,-sin(t*PI)*22*factor)
		2:offset=normal*sin(t*PI)*sin(t*PI*6)*12*factor
		3:offset=normal*sin(t*TAU*2+phase*TAU)*sin(t*PI)*11*factor
		4:offset=Vector2.ZERO
		5:offset=Vector2(0,sin(t*PI)*16*factor)
		6:offset=Vector2(0,-sin(t*PI)*45*factor)
		7:offset=normal*sin(t*TAU*3-phase*TAU)*sin(t*PI)*17*factor
	return a.lerp(b,t)+offset
static func draw_sample(canvas:Object,point:Vector2,target:Vector2,unit:Dictionary,pose:Dictionary,factor:float,impacts:Array)->bool:
	var id:=str(pose.get("action","")).trim_prefix("SKILL_")
	if not has_profile(id) or bool(_row(id).get("passive",false)) or bool(_row(id).get("preserve_v4",false)) or not _living(unit):return false
	if unit.get("unit_type","")!="hero" or str(unit.get("hero_archetype",""))!=str(_row(id).get("hero","")):return false
	var p:=float(pose.get("phase",-1))
	if not is_finite(p) or p<0 or p>=1:return false
	if canvas is CanvasItem and canvas.get_meta("roster_v5_prepared",false):return true
	var skill:Dictionary=pose.get("skill",{})
	if str(skill.get("id",""))!=id or int(skill.get("level",0))<1:return false
	var e:=_entry(id,"CAST" if p<.3 else "CONTACT",point,0,12,int(p*12),str(unit.get("id","")))
	if p>=.3:
		e.position=point if skill.get("target_mode","")=="SELF" else Vector2(impacts[0]) if not impacts.is_empty() else target
		e.frame=clampi(int((p-.3)/.7*12),0,11)
	e.scale=1.25 if bool(skill.get("ultimate",false)) else 1
	_sprite(canvas,e,Vector2(e.position),factor)
	return true
