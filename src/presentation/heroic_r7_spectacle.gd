extends RefCounted
## Read-only cast -> delivery -> contact -> dissipating spectacle. No timers,
## particles, combat RNG, camera shake or gameplay hit-stop are introduced.
const Legacy = preload("res://src/presentation/heroic_rework_r7_effects.gd")
const Cinder = preload("res://src/presentation/heroic_r7_cinder_spectacle.gd")
const Myc = preload("res://src/presentation/heroic_r7_myc_spectacle.gd")
const Readout = preload("res://src/presentation/heroic_actor_readout.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const PixelFxR8 = preload("res://src/presentation/heroic_pixel_fx_r8.gd")
const CellBrushR8 = preload("res://src/presentation/m63_av_brush.gd")
const SIZE := 192
const FRAMES := 12
const ANCHOR := Vector2(96,136)
const MAX_ENTRIES := 32
const MAX_LINKS := 32
const MAX_TEXTURES := 16
static var _textures: Dictionary = {}
static var _bakes := 0

static func clips() -> Array[String]:
	var result := Cinder.clips()
	result.append_array(Myc.clips())
	return result

static func frame_image(handler: String, phase: String, frame: int) -> Image:
	var cinder := handler.begins_with("cinder_")
	var image := Cinder.image(handler,phase,frame) if cinder else Myc.image(handler,phase,frame)
	var row := {"faction":"UNDEAD" if cinder else "UNDERGROUND","material":"CINDER_INK_FIRE" if cinder else "ACID_SPORE_CANOPY","palette":["17121d","352435","594048","e9713c","fff0c7","83bcc3","ffd77b"] if cinder else ["151622","292538","735574","a6cb61","fff5ce","a2dcc4","ddec98"],"passive":phase=="RETURN"}
	PixelFxR8.enhance(image,handler,row,"AURA" if phase=="RETURN" else phase,frame)
	return image

static func reset_cache() -> void:
	_textures.clear(); _bakes=0

static func debug_stats() -> Dictionary:
	return {"textures":_textures.size(),"bakes":_bakes,"pixel_bytes":_textures.size()*SIZE*SIZE*FRAMES*4,
		"max_textures":MAX_TEXTURES,"max_entries":MAX_ENTRIES,"max_links":MAX_LINKS,"version":"r7-spectacle-v4"}

static func _atlas(handler: String, phase: String) -> Texture2D:
	var key := handler+":"+phase
	if _textures.has(key): return _textures[key]
	if key not in clips() or _textures.size()>=MAX_TEXTURES: return null
	var image := Image.create(SIZE*FRAMES,SIZE,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for index: int in range(FRAMES): image.blit_rect(frame_image(handler,phase,index),Rect2i(0,0,SIZE,SIZE),Vector2i(index*SIZE,0))
	var texture := ImageTexture.create_from_image(image)
	_textures[key]=texture; _bakes+=1
	return texture

static func _visible(body: Dictionary, side: String) -> bool:
	return not body.is_empty() and Readout.visible_to(body,side)

static func _entry(handler: String, phase: String, at: Vector2, first: int, last: int, tick: int, cast: String, source: String, target: String) -> Dictionary:
	var fraction := clampf(float(tick-first)/maxf(1.0,float(last-first)),0.0,.9999)
	return {"handler":handler,"phase":phase,"frame":mini(FRAMES-1,floori(fraction*FRAMES)),
		"position":at,"scale":1.0,"alpha":1.0,"angle":0.0,"cast_id":cast,"source_id":source,
		"target_id":target,"start_tick":first,"expires_tick":last,"layer":"FRONT"}

static func _link(handler: String, origin: Vector2, end: Vector2, progress: float, alpha: float, cast: String, kind: String) -> Dictionary:
	return {"handler":handler,"origin":origin,"end":end,"progress":progress,"alpha":alpha,
		"cast_id":cast,"phase":kind,"kind":kind,"layer":"REAR"}

static func plan(snapshot: Dictionary, side: String = "PLAYER", core_pending: Variant = null) -> Dictionary:
	var tick := int(snapshot.get("tick",0))
	var entries: Array[Dictionary]=[]
	var links: Array[Dictionary]=[]
	var cues: Array[Dictionary]=[]
	var recent := false
	for event: Dictionary in snapshot.get("combat_feedback_events",[]).slice(-256):
		var age := tick-int(event.get("tick",-1000000))
		if age>=0 and age<44 and str(event.get("r7_handler","")).begins_with("cinder_") or age>=0 and age<44 and str(event.get("r7_handler","")).begins_with("myc_"):
			recent=true; break
	if snapshot.get("hero_rework_r7",{}).get("pending",[]).is_empty() and not recent:
		return {"entries":entries,"links":links,"cues":cues,"dropped":0,"tick":tick}
	var bodies := {}
	var statuses := {}
	for body: Dictionary in snapshot.get("soldiers",[]):
		bodies[str(body.get("id",""))]=body
		if int(body.get("hp",0))<=0 or not _visible(body,side): continue
		for status: Dictionary in body.get("status_effects",[]):
			if Legacy.Catalog.has_skill(str(status.get("skill_id",""))) and int(status.get("expires_tick",-1))>tick:
				statuses[str(status.get("cast_id",""))+"|"+str(body.id)]={"body":body,"status":status}
	var pending: Array=core_pending if core_pending is Array else Legacy.plan(snapshot,side)
	var cast_records := {}
	for cast: Dictionary in snapshot.get("hero_rework_r7",{}).get("pending",[]).slice(0,24): cast_records[str(cast.get("cast_id",""))]=cast
	var cue_sources := {}
	for core: Dictionary in pending:
		if core.get("semantic")!="TELEGRAPH" or core.get("drawtype")!="SPRITE": continue
		var cast: Dictionary=cast_records.get(str(core.get("cast_id","")),{})
		if cast.is_empty(): continue
		var source: Dictionary=bodies.get(str(cast.source_id),{})
		if int(source.get("hp",0))<=0 or not _visible(source,side): continue
		var handler := str(cast.handler)
		var first := int(cast.created_tick)
		var last := int(cast.due_tick)
		var p := clampf(float(tick-first)/maxf(1,float(last-first)),0,.9999)
		var aim := Vector2(cast.position)
		var target: Dictionary=bodies.get(str(cast.get("target_id","")),{})
		if handler in ["cinder_q","cinder_r"] and not target.is_empty(): aim=Vector2(target.position)
		var start := Vector2(source.position)
		var entry := _entry(handler,"CAST",start,first,last,tick,str(cast.cast_id),str(source.id),str(cast.get("target_id","")))
		entry.scale=1.15 if handler.ends_with("_r") else .95
		# CAST is an upright gesture, never rotate its actor-shaped negative space.
		entries.append(entry)
		if not cue_sources.has(str(source.id)):
			cue_sources[str(source.id)]=true
			cues.append({"source_id":str(source.id),"skill_id":str(cast.skill_id),"handler":handler,
				"progress":p,"aim":aim,"start_tick":first,"expires_tick":last})
		var travel_end := Vector2(core.position) if core.phase=="TRAVEL" else aim
		if handler=="cinder_w": travel_end=Vector2(cast.origin).lerp(aim,.08+p*.18)
		links.append(_link(handler,Vector2(cast.origin),travel_end,p,.55 if handler=="cinder_w" else .85,str(cast.cast_id),"TRAVEL"))
	# A later cleanse/replacement cancels that target's old cosmetic contact too.
	var ended := {}
	var events: Array=snapshot.get("combat_feedback_events",[]).slice(-256)
	for event: Dictionary in events:
		if int(event.get("tick",tick+1))>tick: continue
		if str(event.get("r7_phase","")) in ["CLEANSED","REPLACED"]:
			ended[str(event.get("cast_id",""))+"|"+str(event.get("target",{}).get("id",""))]=true
	var groups := {}
	for event: Dictionary in events:
		var handler := str(event.get("r7_handler",""))
		if handler not in ["cinder_q","cinder_w","cinder_r","myc_q","myc_w","myc_r"]: continue
		var age := tick-int(event.get("tick",-1000000))
		if age<0 or age>=44: continue
		var cast_id := str(event.get("cast_id",""))
		var source_id := str(event.get("source",{}).get("id",""))
		var target_id := str(event.get("target",{}).get("id",""))
		var state := str(event.get("r7_phase",""))
		if state=="MANA_REFUND":
			var source: Dictionary=bodies.get(source_id,{})
			if age>=24 or int(source.get("hp",0))<=0 or not _visible(source,side): continue
			var passive := "cinder_p" if handler.begins_with("cinder") else "myc_p"
			entries.append(_entry(passive,"RETURN",Vector2(source.position),int(event.tick),int(event.tick)+24,tick,cast_id,source_id,source_id))
			continue
		if state!="IMPACT" or ended.has(cast_id+"|"+target_id): continue
		var victim: Dictionary=bodies.get(target_id,{})
		if not _visible(victim,side): continue
		if not groups.has(cast_id): groups[cast_id]={"handler":handler,"event":event,"victims":[],"ids":{}}
		var group: Dictionary=groups[cast_id]
		if not group.ids.has(target_id):
			group.ids[target_id]=true
			group.victims.append({"id":target_id,"position":Vector2(event.target.get("position",victim.position))})
	for cast_id: String in groups:
		var group: Dictionary=groups[cast_id]
		var event: Dictionary=group.event
		var handler := str(group.handler)
		var first := int(event.tick)
		var age := tick-first
		var duration := 32 if handler.ends_with("_r") else 24
		var centroid := Vector2.ZERO
		for victim: Dictionary in group.victims: centroid+=Vector2(victim.position)
		centroid/=maxi(1,group.victims.size())
		var source_id := str(event.source.get("id",""))
		var source: Dictionary=bodies.get(source_id,{})
		var origin := Vector2(event.source.get("position",centroid))
		var source_visible := _visible(source,side)
		if age<duration:
			# A hidden origin must not be reconstructible from midpoint/angle,
			# even if the explicit route itself has already been suppressed.
			var at := origin.lerp(centroid,.5) if handler=="cinder_w" and source_visible else centroid
			var entry := _entry(handler,"CONTACT",at,first,first+duration,tick,cast_id,source_id,str(group.victims[0].id))
			entry.scale=1.35 if handler.ends_with("_r") else 1.15
			entry.alpha=clampf(float(duration-age)/float(duration)*1.7,0,1)
			if handler=="cinder_w" and source_visible: entry.angle=(centroid-origin).angle()
			entries.append(entry)
		# Release trails connect only known settled targets and visible sources.
		if age<16 and source_visible:
			var previous := origin
			for victim: Dictionary in group.victims:
				links.append(_link(handler,previous,Vector2(victim.position),float(age)/16,1.0-float(age)/16,cast_id,"SETTLED"))
				if handler=="myc_w": previous=Vector2(victim.position)
				else: break
		if not handler.ends_with("_r"): continue
		var active_at := Vector2.ZERO
		var active := 0
		for victim: Dictionary in group.victims:
			var fact: Dictionary=statuses.get(cast_id+"|"+str(victim.id),{})
			if fact.is_empty(): continue
			active_at+=Vector2(fact.body.position); active+=1
		if active>0:
			var tail := _entry(handler,"TAIL",active_at/active,first,first+44,tick,cast_id,source_id,"")
			tail.scale=1.1
			tail.alpha=.5*(1.0-float(age)/44.0)
			tail.layer="REAR"
			entries.append(tail)
	# Preserve the existing core's 24-pending read domain, while making its
	# decorative omissions explicit. MAX_ENTRIES is a cap, not a fill target.
	var dropped := maxi(0,snapshot.get("hero_rework_r7",{}).get("pending",[]).size()-24)+maxi(0,entries.size()-MAX_ENTRIES)+maxi(0,links.size()-MAX_LINKS)
	return {"entries":entries.slice(0,MAX_ENTRIES),"links":links.slice(0,MAX_LINKS),"cues":cues.slice(0,32),"dropped":dropped,"tick":tick}

static func cast_body(body: Dictionary, base_pose: Dictionary, prepared: Dictionary) -> Dictionary:
	var result := {"pose":base_pose.duplicate(true),"offset":Vector2.ZERO,"active":false}
	if str(body.get("hero_archetype","")) not in Legacy.Catalog.ENABLED_HEROES or int(body.get("hp",0))<=0 or bool(base_pose.get("moving",false)): return result
	for cue: Dictionary in prepared.get("cues",[]):
		if str(cue.source_id)!=str(body.get("id","")): continue
		var p := clampf(float(cue.progress),0,.9999)
		var direction := (Vector2(cue.aim)-Vector2(body.position)).normalized()
		if direction==Vector2.ZERO: direction=Vector2.RIGHT
		result.pose.merge({"action":"SKILL_"+str(cue.skill_id),"phase":p,"body_phase_m76":p,"r7_cast_progress":p,
			"direction":direction,"target_position":Vector2(cue.aim),"moving":false,
			"skill":Heroes.skill_at_level(str(cue.skill_id),int(body.get("last_skill_level",1)))},true)
		# Clamp before integer quantization: adding vertical lift to a downward
		# cast must not exceed the declared four-pixel render-only envelope.
		result.offset=(-direction*3.0*sin(p*PI)+Vector2(0,-sin(p*PI)*1.5)).limit_length(3.0).round()
		result.active=true
		break
	return result

static func draw(canvas: Object, prepared: Dictionary, project: Callable, scale: float, layer: String = "FRONT") -> int:
	if scale<=0 or layer not in ["REAR","FRONT"]: return 0
	var count := 0
	if layer=="REAR":
		for link: Dictionary in prepared.get("links",[]).slice(0,MAX_LINKS): count+=_draw_link(canvas,link,project,scale)
	for entry: Dictionary in prepared.get("entries",[]).slice(0,MAX_ENTRIES):
		if str(entry.get("layer","FRONT"))!=layer: continue
		var at: Vector2=project.call(Vector2(entry.position))
		var factor := scale*float(entry.get("scale",1.0))
		if canvas is CanvasItem and not canvas.get_viewport_rect().grow(SIZE*factor).has_point(at): continue
		var texture := _atlas(str(entry.handler),str(entry.phase))
		if texture==null: continue
		canvas.draw_set_transform(at.round(),float(entry.get("angle",0)),Vector2.ONE*factor)
		canvas.draw_texture_rect_region(texture,Rect2(-ANCHOR,Vector2(SIZE,SIZE)),Rect2(clampi(int(entry.frame),0,FRAMES-1)*SIZE,0,SIZE,SIZE),Color(1,1,1,clampf(float(entry.get("alpha",1)),0,1)))
		canvas.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		count+=1
	return count

static func _curve(a: Vector2, b: Vector2, t: float, handler: String, progress: float) -> Vector2:
	var perpendicular := (b-a).normalized().orthogonal()
	var lift := -sin(t*PI)*(28 if handler.ends_with("_r") else 16)
	var wiggle := sin(t*TAU*1.5+progress*TAU)*sin(t*PI)*10 if handler.begins_with("myc") else sin(t*PI)*5
	return a.lerp(b,t)+Vector2(0,lift)+perpendicular*wiggle

static func _draw_link(canvas: Object, link: Dictionary, project: Callable, scale: float) -> int:
	var a: Vector2=project.call(Vector2(link.origin))+Vector2(0,-28)*scale
	var b: Vector2=project.call(Vector2(link.end))+Vector2(0,-30)*scale
	if a.distance_squared_to(b)<4: return 0
	if canvas is CanvasItem and not canvas.get_viewport_rect().grow(100*scale).intersects(Rect2(a,Vector2.ZERO).expand(b).abs()): return 0
	var cinder := str(link.handler).begins_with("cinder")
	var colors: Array=[Color("392333"),Color("ce623c"),Color("ffe2a0")] if cinder else [Color("31223f"),Color("598d91"),Color("e2f7a0")]
	var alpha := clampf(float(link.alpha),0,1)
	var p := clampf(float(link.progress),0,1)
	var count := 0
	var ctx := {"canvas":canvas,"count":0,"draw_limit":48,"quantum":maxf(1.0,2.0*scale)}
	# Eight segments, three strokes each: 24 lines total, not 24 per layer.
	for lane: int in range(3):
		var color: Color=colors[lane]; color.a=alpha*(.6 if lane==0 else .8 if lane==1 else 1.0)
		for index: int in range(8):
			var start := _curve(a,b,float(index)/8,str(link.handler),p)
			var end := _curve(a,b,float(index+1)/8,str(link.handler),p)
			CellBrushR8.streak(ctx,start.round(),end.round(),maxf(1,(8-lane*3)*scale),color)
			count+=1
	for index: int in range(4):
		var t := fposmod(p+float(index)*.23,1.0)
		var point := _curve(a,b,t,str(link.handler),p)
		var color: Color=colors[2]; color.a=alpha*(1-float(index)*.15)
		canvas.draw_rect(Rect2(point.round()-Vector2(3,2)*scale,Vector2(6 if cinder else 4,3 if cinder else 5)*scale),color)
		count+=1
	return count
