extends RefCounted
## Read-only animation projection over actual delivery/status/feedback facts.
## Authored pixel frames bake once per clip, not once per unit or particle.
const Readout = preload("res://src/presentation/heroic_actor_readout.gd")
const Catalog = preload("res://src/simulation/strategic_hero_rework_r7_catalog.gd")
const Cinder = preload("res://src/presentation/heroic_r7_cinder_frames.gd")
const Myc = preload("res://src/presentation/heroic_r7_myc_frames.gd")
const Atmosphere = preload("res://src/presentation/heroic_r7_atmosphere_frames.gd")
const PixelFxR8 = preload("res://src/presentation/heroic_pixel_fx_r8.gd")
const CellBrushR8 = preload("res://src/presentation/m63_av_brush.gd")
const SIZE := 96
const FRAMES := 8
const MAX_TEXTURES := 25
const MAX_ENTRIES := 96
const ANCHOR := Vector2(48,64)
const MAX_ATMOSPHERE_ENTRIES := 64
static var _textures: Dictionary = {}
static var _bakes := 0
static var _atmosphere_textures: Dictionary = {}
static var _atmosphere_bakes := 0

static func clips() -> Array[String]:
	var result := Cinder.clips()
	result.append_array(Myc.clips())
	return result

static func frame_image(handler: String, phase: String, frame: int) -> Image:
	var image := Cinder.image(handler,phase,frame) if handler.begins_with("cinder_") else Myc.image(handler,phase,frame)
	PixelFxR8._cell_ink(image)
	return image

static func atmosphere_image(handler: String, phase: String, frame: int) -> Image:
	var image := Atmosphere.image(handler,phase,frame)
	PixelFxR8._cell_ink(image)
	return image

static func atmosphere_front_image(handler: String, phase: String, frame: int) -> Image:
	var image := Atmosphere.front_image(handler,phase,frame)
	PixelFxR8._cell_ink(image)
	return image

static func reset_cache() -> void:
	_textures.clear()
	_bakes=0
	_atmosphere_textures.clear()
	_atmosphere_bakes=0

static func warm_cache() -> void:
	for key: String in clips():
		var parts := key.split(":")
		_atlas(parts[0],parts[1])
		_atmosphere_atlas(parts[0],parts[1])

static func debug_stats() -> Dictionary:
	return {"textures":_textures.size(),"bakes":_bakes,"max_textures":MAX_TEXTURES,
		"pixel_bytes":_textures.size()*SIZE*SIZE*FRAMES*4,"frames_per_clip":FRAMES,
		"max_entries":MAX_ENTRIES,"version":"r7-layered-pixel-v3",
		"atmosphere_textures":_atmosphere_textures.size(),"atmosphere_bakes":_atmosphere_bakes,
		"atmosphere_pixel_bytes":_atmosphere_textures.size()*128*256*FRAMES*4,
		"max_atmosphere_textures":MAX_TEXTURES,"max_atmosphere_entries":MAX_ATMOSPHERE_ENTRIES}

static func _atmosphere_atlas(handler: String, phase: String) -> Texture2D:
	var key := handler+":"+phase
	if _atmosphere_textures.has(key): return _atmosphere_textures[key]
	if not clips().has(key) or _atmosphere_textures.size()>=MAX_TEXTURES: return null
	var sheet := Image.create(128*FRAMES,256,false,Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for index: int in range(FRAMES):
		sheet.blit_rect(atmosphere_image(handler,phase,index),Rect2i(0,0,128,128),Vector2i(index*128,0))
		sheet.blit_rect(atmosphere_front_image(handler,phase,index),Rect2i(0,0,128,128),Vector2i(index*128,128))
	var texture := ImageTexture.create_from_image(sheet)
	_atmosphere_textures[key]=texture
	_atmosphere_bakes+=1
	return texture

static func _atlas(handler: String, phase: String) -> Texture2D:
	var key := handler+":"+phase
	if _textures.has(key): return _textures[key]
	if not clips().has(key) or _textures.size()>=MAX_TEXTURES: return null
	var sheet := Image.create(SIZE*FRAMES,SIZE,false,Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for index: int in range(FRAMES):
		var image := frame_image(handler,phase,index)
		sheet.blit_rect(image,Rect2i(0,0,SIZE,SIZE),Vector2i(index*SIZE,0))
	var texture := ImageTexture.create_from_image(sheet)
	_textures[key]=texture
	_bakes+=1
	return texture

static func _visible(body: Dictionary, side: String) -> bool:
	return not body.is_empty() and Readout.visible_to(body,side)

static func _entry(handler: String, phase: String, frame: int, position: Vector2, semantic: String) -> Dictionary:
	return {"handler":handler,"phase":phase,"frame":clampi(frame,0,7),"position":position,
		"scale":1.0,"alpha":1.0,"angle":0.0,"event_id":"","cast_id":"","target_id":"",
		"rank":1,"semantic":semantic,"damage_contact":false,"drawtype":"SPRITE"}

static func plan(snapshot: Dictionary, view_side: String = "PLAYER") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var tick := int(snapshot.get("tick",0))
	var bodies := {}
	for body: Dictionary in snapshot.get("soldiers",[]): bodies[str(body.id)]=body
	for cast: Dictionary in snapshot.get("hero_rework_r7",{}).get("pending",[]).slice(0,24):
		var source: Dictionary=bodies.get(str(cast.get("source_id","")),{})
		var target_id := str(cast.get("target_id",""))
		var target: Dictionary=bodies.get(target_id,{})
		var handler := str(cast.get("handler",""))
		# A visible caster must not disclose the location of a hidden victim.
		if not target_id.is_empty() and not _visible(target,view_side): continue
		# Local R warnings preserve counterplay without disclosing a hidden
		# caster's origin/trajectory. An unseen empty area is not public vision.
		var source_visible := _visible(source,view_side)
		var local_warning := handler in ["cinder_r","myc_r"] and _visible(target,view_side)
		if not source_visible and not local_warning: continue
		var first := int(cast.get("created_tick",tick))
		var due := int(cast.get("due_tick",tick))
		if first>tick or due<=tick: continue
		if handler=="cinder_r":
			# Item cleanse can remove the real mark before pending is retired
			# on the next Combat tick. Do not resurrect it from that queue.
			var marked := false
			for status: Dictionary in target.get("status_effects",[]):
				if str(status.get("r7_phase",""))=="MARK" and str(status.get("cast_id",""))==str(cast.get("cast_id","")) and int(status.get("expires_tick",-1))>tick:
					marked=true
					break
			if not marked: continue
		var fraction := clampf(float(tick-first)/maxf(1.0,float(due-first)),0.0,1.0)
		var origin := Vector2(cast.get("origin",Vector2.ZERO))
		var point := Vector2(cast.get("position",origin))
		if handler in ["cinder_q","cinder_r"] and not target.is_empty(): point=Vector2(target.position)
		var phase := "MARK" if handler=="cinder_r" else "WARNING" if handler=="myc_r" else "WINDUP" if handler=="cinder_w" else "TRAVEL"
		var at := origin if handler=="cinder_w" else point
		if phase=="TRAVEL": at=origin.lerp(point,fraction)+Vector2(0,-sin(fraction*PI)*22.0)
		var entry := _entry(handler,phase,floori(fraction*8),at,"TELEGRAPH")
		entry.merge({"cast_id":cast.get("cast_id",""),"target_id":target_id,"rank":int(cast.get("rank",1)),
			"progress":fraction},true)
		if source_visible: entry.merge({"origin":origin,"aim":point},true)
		if handler in ["cinder_w","myc_w"]: entry.angle=(point-origin).angle()
		if handler=="cinder_r":
			entry["sprite_offset"]=Vector2(0,-26)
			entry.scale=.84
		if handler=="myc_r": entry["sprite_offset"]=Vector2(0,-28)
		if handler=="myc_r": entry["warning_radius"]=95.0
		result.append(entry)
	var previous_chain := {}
	for event: Dictionary in snapshot.get("combat_feedback_events",[]).slice(-256):
		var handler := str(event.get("r7_handler",""))
		if not handler.begins_with("cinder_") and not handler.begins_with("myc_"): continue
		var age := tick-int(event.get("tick",-1000000))
		if age<0: continue
		var state := str(event.get("r7_phase",""))
		if state not in ["IMPACT","NATURAL_END","CLEANSED","REPLACED","INTERRUPTED","MANA_REFUND"]: continue
		var target_id := str(event.get("target",{}).get("id",""))
		var source_id := str(event.get("source",{}).get("id",""))
		var victim: Dictionary=bodies.get(target_id,{})
		var source: Dictionary=bodies.get(source_id,{})
		var owner: Dictionary=source if state in ["MANA_REFUND","INTERRUPTED"] else victim
		if not _visible(owner,view_side):
			previous_chain.erase(str(event.get("cast_id","")))
			continue
		var lifetime := 16 if state=="MANA_REFUND" else 6 if state in ["CLEANSED","REPLACED","INTERRUPTED"] else 12
		if age>=lifetime: continue
		var frame := mini(7,age*8/lifetime)
		var phase := "PROC" if state=="MANA_REFUND" else "IMPACT" if state=="IMPACT" else "END"
		var semantic := "MANA_REFUND" if state=="MANA_REFUND" else "STATUS_CLEANSED" if state=="CLEANSED" else "STATUS_ENDED"
		var direct := state=="IMPACT" and handler not in ["cinder_q","myc_r"]
		if state=="IMPACT": semantic="CONTACT" if direct else "ATTACHMENT"
		if state=="MANA_REFUND": handler="cinder_p" if handler.begins_with("cinder_") else "myc_p"
		var at := Vector2(owner.position) if state in ["MANA_REFUND","INTERRUPTED"] else Vector2(event.target.get("position",owner.position))
		var entry := _entry(handler,phase,frame,at,semantic)
		entry.merge({"event_id":str(event.get("event_id","")),"cast_id":str(event.get("cast_id","")),
			"target_id":target_id,"rank":int(event.get("rank",1)),"ending":state,"damage_contact":direct},true)
		if state=="CLEANSED": entry.merge({"alpha":1.0-float(age)/float(lifetime),"tint":Color("cfddd1")},true)
		if handler=="cinder_r":
			entry["sprite_offset"]=Vector2(0,-26)
			entry.scale=.84
		if state=="INTERRUPTED": entry.scale=.6
		if handler=="cinder_w" and state=="IMPACT":
			entry.angle=(at-Vector2(event.get("source",{}).get("position",at))).angle()
			entry.scale=.65
		if result.size()<MAX_ENTRIES: result.append(entry)
		# Only the actual distinct settled W victims form a brief connector.
		if handler=="myc_w" and state=="IMPACT":
			var cast_id := str(event.get("cast_id",""))
			if previous_chain.has(cast_id) and result.size()<MAX_ENTRIES:
				var link := _entry(handler,"IMPACT",frame,previous_chain[cast_id],"SETTLED_CHAIN")
				link.merge({"drawtype":"LINK","end_position":at,"event_id":entry.event_id,
					"cast_id":cast_id,"target_id":target_id,"alpha":1.0-float(age)/float(lifetime)},true)
				result.append(link)
			previous_chain[cast_id]=at
	return result

static func visual_plan(snapshot: Dictionary, view_side: String = "PLAYER") -> Dictionary:
	# One per-draw projection for both passes. Never store a scene across ticks,
	# and never trim the authoritative core warning to fit decorative capacity.
	var pending := plan(snapshot,view_side)
	var candidates: Array[Dictionary] = []
	for entry: Dictionary in pending:
		if entry.semantic=="TELEGRAPH" and entry.drawtype=="SPRITE": candidates.append(entry)
	var tick := int(snapshot.get("tick",0))
	for body: Dictionary in snapshot.get("soldiers",[]):
		if int(body.get("hp",0))<=0 or not _visible(body,view_side): continue
		for status: Dictionary in body.get("status_effects",[]):
			if not Catalog.has_skill(str(status.get("skill_id",""))) or str(status.get("r7_phase",""))=="MARK" or int(status.get("expires_tick",-1))<=tick: continue
			var handler := str(status.get("r7_handler",""))
			var offset := absi(str(body.get("id","")).hash())%8
			var entry := _entry(handler,"LOOP",(tick/2+offset)%8,Vector2(body.position),"ATTACHED_STATUS")
			entry.merge({"cast_id":str(status.get("cast_id","")),"target_id":str(body.id),"scale":.82,"alpha":.8},true)
			candidates.append(entry)
	for entry: Dictionary in pending:
		if entry.semantic!="TELEGRAPH" and entry.drawtype=="SPRITE": candidates.append(entry)
	var seen := {}
	var result: Array[Dictionary] = []
	var dropped := 0
	for entry: Dictionary in candidates:
		if not clips().has(str(entry.handler)+":"+str(entry.phase)): continue
		var key := str(entry.cast_id)+"|"+str(entry.target_id)
		if seen.has(key): continue
		seen[key]=true
		if result.size()>=MAX_ATMOSPHERE_ENTRIES:
			dropped+=1
			continue
		var projected := entry.duplicate(true)
		# The visual glow/decal has no gameplay radius. The sole actual range
		# remains pending.warning_radius and is still drawn by the core pass.
		projected.erase("warning_radius")
		projected.erase("sprite_offset")
		projected.erase("origin")
		projected.erase("aim")
		if str(projected.handler).ends_with("_r") and projected.phase!="LOOP": projected.scale=maxf(.95,float(projected.scale))
		result.append(projected)
	return {"pending":pending,"atmosphere":result,"dropped":dropped}

static func draw_atmosphere(canvas: Object, entries: Array, project: Callable, scale: float, layer: String = "REAR") -> int:
	if scale<=0.0 or layer not in ["REAR","FRONT"]: return 0
	var count := 0
	for entry: Dictionary in entries.slice(0,MAX_ATMOSPHERE_ENTRIES):
		var texture := _atmosphere_atlas(str(entry.handler),str(entry.phase))
		if texture==null: continue
		var at: Vector2=project.call(Vector2(entry.position))
		var factor := scale*float(entry.get("scale",1.0))
		if canvas is CanvasItem and not canvas.get_viewport_rect().grow(128*factor).has_point(at): continue
		var color := Color(1,1,1,clampf(float(entry.get("alpha",1.0)),0.0,1.0))
		canvas.draw_set_transform(at.round(),float(entry.get("angle",0.0)),Vector2.ONE*factor)
		canvas.draw_texture_rect_region(texture,Rect2(-Atmosphere.ANCHOR,Vector2(128,128)),Rect2(int(entry.frame)*128,128 if layer=="FRONT" else 0,128,128),color)
		canvas.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		count+=1
	return count

static func _draw_sprite(canvas: Object, entry: Dictionary, at: Vector2, scale: float) -> bool:
	var texture := _atlas(str(entry.handler),str(entry.phase))
	if texture==null or scale<=0.0: return false
	var factor := scale*float(entry.get("scale",1.0))
	var tint: Color=entry.get("tint",Color.WHITE)
	tint.a=clampf(float(entry.get("alpha",1.0)),0.0,1.0)
	canvas.draw_set_transform(at.round(),float(entry.get("angle",0.0)),Vector2.ONE*factor)
	canvas.draw_texture_rect_region(texture,Rect2(-ANCHOR,Vector2(SIZE,SIZE)),Rect2(int(entry.frame)*SIZE,0,SIZE,SIZE),tint)
	canvas.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	return true

static func draw_pending(canvas: Object, snapshot: Dictionary, project: Callable, scale: float, view_side: String = "PLAYER", prepared: Dictionary = {}) -> int:
	var count := 0
	for entry: Dictionary in (prepared.pending if prepared.has("pending") else plan(snapshot,view_side)):
		var at: Vector2=project.call(Vector2(entry.position))
		if entry.drawtype=="LINK":
			var end: Vector2=project.call(Vector2(entry.end_position))
			var middle := at.lerp(end,.5)+Vector2(0,-4)*scale
			var ctx := {"canvas":canvas,"count":0,"draw_limit":8,"quantum":maxf(1.0,2.0*scale)}
			CellBrushR8.streak(ctx,at.round(),middle.round(),maxf(1,3*scale),Color("282331",float(entry.alpha)))
			CellBrushR8.streak(ctx,middle.round(),end.round(),maxf(1,2*scale),Color("a4bd57",float(entry.alpha)))
			count+=1
			continue
		if entry.has("warning_radius"):
			for index: int in range(16):
				var angle := float(index)*TAU/16.0
				var p := at+Vector2(cos(angle),sin(angle))*float(entry.warning_radius)*scale
				canvas.draw_rect(Rect2(p.round(),Vector2(3,2)*maxf(1,scale)),Color("a4bd57",.35+.2*float(entry.progress)))
		if _draw_sprite(canvas,entry,at+Vector2(entry.get("sprite_offset",Vector2.ZERO))*scale,scale): count+=1
	return count

static func draw_status(canvas: Object, foot: Vector2, _head: Vector2, unit: Dictionary, status: Dictionary, tick: int, scale: float) -> bool:
	if not Catalog.has_skill(str(status.get("skill_id",""))): return false
	if int(unit.get("hp",0))<=0 or bool(unit.get("hidden",false)) or not bool(unit.get("visible",true)) or int(status.get("expires_tick",-1))<=tick: return false
	# A dispellable mark is already drawn from its real pending delivery.
	if str(status.get("r7_phase",""))=="MARK": return true
	var handler := str(status.get("r7_handler",""))
	var offset := absi(str(unit.get("id","")).hash())%8
	var entry := _entry(handler,"LOOP",(tick/2+offset)%8,Vector2.ZERO,"ATTACHED_STATUS")
	var progress := float(status.get("progress_ticks",0.0))/maxf(1.0,float(status.get("budget_duration_ticks",1)))
	entry.scale=.85 if handler=="cinder_r" else .55 if bool(status.get("ultimate",false)) else .66
	entry.alpha=.85 if progress<.75 else .65
	# A status is attached to a shoulder/flank, not a replacement body. Keep
	# stacked Q/W/R marks apart without changing any actual hit geometry.
	var offset_x := -13.0 if handler.ends_with("_q") else 13.0 if handler.ends_with("_w") else 22.0 if handler=="cinder_r" else 17.0
	return _draw_sprite(canvas,entry,foot+Vector2(offset_x,-2)*scale,scale)
