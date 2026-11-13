extends RefCounted
## Detached, receipt-driven pixel feedback. This object never owns a body,
## authoritative position, wall clock, RNG, Node or Timer. One shared tiny
## pixel-number texture is authored on first draw, never per hit or per frame.
## Same-tick positive and negative HP settlements remain separate facts.
const VERSION := "outposts-v4-real-combat-feedback-r9"
const NUMBER_LIFETIME_TICKS := 22
const MAX_NUMBERS := 192
const MAX_SEEN_RECEIPTS := 2048
const MAX_CONTROLS := 128
const MAX_SCREEN_PULSES := 8
const MAX_SCREEN_CASTS := 128
const SCREEN_LIFETIME_TICKS := 8
const MAX_CONTINUOUS_GAP := 12
const INK := Color("141621")
const GLYPHS := "0123456789+-"
const GLYPH_SIZE := Vector2i(8,12)
const DIGITS := {
	"0":["111","101","101","101","111"],
	"1":["010","110","010","010","111"],
	"2":["111","001","111","100","111"],
	"3":["111","001","111","001","111"],
	"4":["101","101","111","001","001"],
	"5":["111","100","111","001","111"],
	"6":["111","100","111","101","111"],
	"7":["111","001","010","010","010"],
	"8":["111","101","111","101","111"],
	"9":["111","101","111","001","111"],
	"+":["000","010","111","010","000"],
	"-":["000","000","111","000","000"]
}
var _numbers: Array[Dictionary] = []
var _number_lookup: Dictionary = {}
var _target_lanes: Dictionary = {}
var _seen: Dictionary = {}
var _seen_order: Array[String] = []
var _controls: Dictionary = {}
var _screen_pulses: Array[Dictionary] = []
var _screen_casts: Dictionary = {}
var _screen_cast_order: Array[String] = []
var _signature := ""
var _side := "PLAYER"
var _last_tick := -1
var _last_phase := ""
var _primed := false
var _dropped_numbers := 0
static var _font_texture: ImageTexture
static var _font_bakes := 0

func observe(snapshot: Dictionary, side: String = "PLAYER", discontinuity: bool = false) -> void:
	if str(snapshot.get("outcome","ONGOING"))!="ONGOING":
		reset()
		return
	var tick := int(snapshot.get("tick",-1))
	if tick<0: return
	var signature := _match_signature(snapshot)
	var phase := str(snapshot.get("phase",""))
	var broken := discontinuity or (_primed and (tick<_last_tick or tick-_last_tick>MAX_CONTINUOUS_GAP or signature!=_signature or side!=_side or (phase=="LOBBY" and _last_phase!="LOBBY")))
	if broken: reset()
	_side=side
	_signature=signature
	_last_phase=phase
	# The first frame is a baseline, not a replay of the host's 4-second log.
	if not _primed:
		for event: Dictionary in _events(snapshot): _remember(str(event.get("event_id","")))
		_primed=true
		_last_tick=tick
		return
	_prune(tick)
	var actors := _actor_index(snapshot)
	for event: Dictionary in _events(snapshot):
		var receipt := str(event.get("event_id",""))
		if receipt.is_empty() or _seen.has(receipt): continue
		_remember(receipt)
		var at := int(event.get("tick",-1))
		if at<_last_tick or at>tick or tick-at>=NUMBER_LIFETIME_TICKS: continue
		var target_id := str(event.get("target",{}).get("id",""))
		var target: Dictionary=actors.get(target_id,{})
		if target.is_empty() or not _visible(target,_side): continue
		var kind := str(event.get("kind",""))
		if kind in ["HIT","HEAL"] and typeof(event.get("amount"))==TYPE_INT and int(event.amount)>0:
			_add_number(target_id,kind,int(event.amount),at,str(event.get("attack_type","")))
		if kind in ["CONTROL","STATUS"] and str(event.get("phase","START"))!="END" and str(event.get("status_kind","")) in ["STUN","ROOT","SLOW"]:
			var control_kind := str(event.status_kind)
			var until := int(event.get("expires_tick",at))
			if control_kind=="SLOW": until=mini(until,at+6)
			var older: Dictionary=_controls.get(target_id,{})
			# A simultaneous slow must not dilute the stronger stun/root jolt.
			if control_kind!="SLOW" or older.get("kind","")=="SLOW" or int(older.get("expires_tick",-1))<=at:
				_controls[target_id]={"tick":at,"expires_tick":until,"kind":control_kind}
			while _controls.size()>MAX_CONTROLS: _controls.erase(_controls.keys()[0])
		_consider_screen_pulse(event,target,at)
	_last_tick=tick

func numbers(snapshot: Dictionary, tick: int = -1) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if _numbers.is_empty() or str(snapshot.get("outcome","ONGOING"))!="ONGOING": return result
	if tick<0: tick=int(snapshot.get("tick",_last_tick))
	var actors := _actor_index(snapshot)
	for mark: Dictionary in _numbers:
		var age := tick-int(mark.tick)
		if age<0 or age>=NUMBER_LIFETIME_TICKS: continue
		var target: Dictionary=actors.get(str(mark.target_id),{})
		# Dead-but-visible targets retain the final actual killing number.
		# Removed/hidden targets never retain a stale position beacon.
		if target.is_empty() or not _visible(target,_side): continue
		var position: Variant=target.get("position")
		if not _point(position): continue
		var view := mark.duplicate(true)
		view["position"]=Vector2(position)
		view["text"]=("+" if mark.kind=="HEAL" else "-")+str(mark.amount)
		view["age"]=age
		view["alpha"]=minf(1.0,float(NUMBER_LIFETIME_TICKS-age)/7.0)
		view["hero"]=str(target.get("unit_type",""))=="hero"
		view["building"]=target.has("building_type")
		result.append(view)
	return result

func body_offset(unit: Dictionary, tick: int) -> Vector2:
	if int(unit.get("hp",0))<=0 or not _visible(unit,_side): return Vector2.ZERO
	var record: Dictionary=_controls.get(str(unit.get("id","")),{})
	if record.is_empty() or int(record.expires_tick)<=tick: return Vector2.ZERO
	var kind := str(record.kind)
	var actual_until := int(unit.get("stun_until_tick" if kind=="STUN" else "root_until_tick",-1)) if kind in ["STUN","ROOT"] else -1
	for status: Dictionary in unit.get("status_effects",[]):
		if str(status.get("kind",status.get("id","")))==kind: actual_until=maxi(actual_until,int(status.get("expires_tick",tick+int(status.get("remaining_ticks",0)))))
	if actual_until<=tick: return Vector2.ZERO
	var age := tick-int(record.tick)
	if age<0: return Vector2.ZERO
	var sequence: Array[Vector2]=[Vector2(1,0),Vector2(-1,0),Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]
	var magnitude := 2.0 if kind!="SLOW" and age<8 else 1.0
	return sequence[posmod(age/2,sequence.size())]*magnitude

func camera_offset(snapshot: Dictionary, tick: int = -1, enabled: bool = true, visible_in_view: Callable = Callable()) -> Vector2:
	if not enabled or _screen_pulses.is_empty() or str(snapshot.get("outcome","ONGOING"))!="ONGOING": return Vector2.ZERO
	if tick<0: tick=int(snapshot.get("tick",_last_tick))
	var actors := _actor_index(snapshot)
	var chosen: Dictionary={}
	for pulse: Dictionary in _screen_pulses:
		var age := tick-int(pulse.tick)
		if age<0 or age>=SCREEN_LIFETIME_TICKS: continue
		var target: Dictionary=actors.get(str(pulse.target_id),{})
		if target.is_empty() or not _visible(target,_side) or not _point(target.get("position")): continue
		if visible_in_view.is_valid() and not bool(visible_in_view.call(Vector2(target.position))): continue
		if chosen.is_empty() or int(pulse.strength)>int(chosen.strength): chosen=pulse
	if chosen.is_empty(): return Vector2.ZERO
	var age := tick-int(chosen.tick)
	var amplitude := maxi(1,roundi(float(chosen.strength)*float(SCREEN_LIFETIME_TICKS-age)/float(SCREEN_LIFETIME_TICKS)))
	var sequence: Array[Vector2]=[Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	# Never sum simultaneous impulses: a 20-target ultimate is not 100px.
	return sequence[posmod(age,sequence.size())]*mini(amplitude,5)

static func draw_numbers(canvas: Object, entries: Array, project: Callable, head_offset: Callable = Callable(), factor: float = 1.0) -> int:
	if not project.is_valid() or entries.is_empty(): return 0
	var texture := _pixel_font()
	var drawn := 0
	for mark: Dictionary in entries.slice(0,MAX_NUMBERS):
		var anchor := Vector2(project.call(Vector2(mark.position)))
		if head_offset.is_valid(): anchor+=Vector2(head_offset.call(str(mark.target_id)))
		else: anchor+=Vector2(0,-maxf(28.0,38.0*factor))
		var age := int(mark.get("age",0))
		var lane := int(mark.get("lane",0))
		anchor+=Vector2((-1 if lane%2==0 else 1)*mini(lane,3)*5,-12-lane*10-mini(age,18))
		var text := str(mark.get("text",""))
		var width := text.length()*GLYPH_SIZE.x
		var origin := (anchor-Vector2(width*0.5,GLYPH_SIZE.y)).round()
		var alpha := clampf(float(mark.get("alpha",1.0)),0.0,1.0)
		var color := Color("8cf0a2") if mark.get("kind","")=="HEAL" else Color("ffd8a1")
		if mark.get("kind","")=="HIT" and mark.get("attack_type","")=="ARCANE": color=Color("d6c4ff")
		for x: int in range(text.length()):
			var glyph := GLYPHS.find(text.substr(x,1))
			if glyph<0: continue
			canvas.draw_texture_rect_region(texture,Rect2(origin+Vector2(x*GLYPH_SIZE.x,0),Vector2(GLYPH_SIZE)),Rect2(Vector2(glyph*GLYPH_SIZE.x,0),Vector2(GLYPH_SIZE)),Color(color,alpha))
		drawn+=1
	return drawn

func reset() -> void:
	_numbers.clear(); _number_lookup.clear(); _target_lanes.clear(); _seen.clear(); _seen_order.clear(); _controls.clear()
	_screen_pulses.clear(); _screen_casts.clear(); _screen_cast_order.clear()
	_signature=""; _side="PLAYER"; _last_tick=-1; _last_phase=""; _primed=false; _dropped_numbers=0

func debug_stats() -> Dictionary:
	return {"version":VERSION,"active_numbers":_numbers.size(),"max_numbers":MAX_NUMBERS,"seen_receipts":_seen.size(),"max_seen_receipts":MAX_SEEN_RECEIPTS,"active_controls":_controls.size(),"max_controls":MAX_CONTROLS,"screen_pulses":_screen_pulses.size(),"max_screen_pulses":MAX_SCREEN_PULSES,"dropped_numbers":_dropped_numbers,"created_nodes":0,"created_textures":_font_bakes,"font_pixels":GLYPHS.length()*GLYPH_SIZE.x*GLYPH_SIZE.y}

static func _pixel_font() -> ImageTexture:
	if _font_texture!=null: return _font_texture
	var image := Image.create(GLYPHS.length()*GLYPH_SIZE.x,GLYPH_SIZE.y,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for glyph: int in range(GLYPHS.length()):
		var points: Array[Vector2i]=[]
		var rows: Array=DIGITS[GLYPHS.substr(glyph,1)]
		for y: int in range(5):
			for x: int in range(3):
				if str(rows[y]).substr(x,1)=="1": points.append(Vector2i(glyph*GLYPH_SIZE.x+1+x*2,1+y*2))
		for point: Vector2i in points: image.fill_rect(Rect2i(point-Vector2i.ONE,Vector2i(4,4)),INK)
		for point: Vector2i in points: image.fill_rect(Rect2i(point,Vector2i(2,2)),Color.WHITE)
	_font_texture=ImageTexture.create_from_image(image)
	_font_bakes+=1
	return _font_texture

func _add_number(target_id: String, kind: String, amount: int, tick: int, attack_type: String) -> void:
	var key := "%s:%s:%d"%[target_id,kind,tick]
	if _number_lookup.has(key):
		var existing: Dictionary=_number_lookup[key]
		existing.amount=int(existing.amount)+amount
		return
	var previous: Dictionary=_target_lanes.get(target_id,{})
	var lane := mini(3,int(previous.get("lane",-1))+1) if tick-int(previous.get("tick",-1000))<8 else 0
	_target_lanes[target_id]={"tick":tick,"lane":lane}
	var mark := {"key":key,"target_id":target_id,"kind":kind,"amount":amount,"tick":tick,"lane":lane,"attack_type":attack_type}
	_numbers.append(mark)
	_number_lookup[key]=mark
	while _numbers.size()>MAX_NUMBERS:
		var oldest: Dictionary=_numbers.pop_front()
		_number_lookup.erase(str(oldest.key))
		_dropped_numbers+=1
	while _target_lanes.size()>MAX_NUMBERS*2: _target_lanes.erase(_target_lanes.keys()[0])

func _consider_screen_pulse(event: Dictionary, target: Dictionary, tick: int) -> void:
	if not bool(event.get("ultimate",false)) or bool(event.get("dot",false)): return
	var source: Dictionary=event.get("source",{})
	if str(source.get("unit_type",""))!="hero" and str(source.get("hero_archetype","")).is_empty(): return
	var kind := str(event.get("kind",""))
	var control := kind=="CONTROL" and str(event.get("phase","START"))!="END" and str(event.get("status_kind","")) in ["STUN","ROOT"]
	var strong := kind=="HIT" and int(event.get("amount",0))>=maxi(40,roundi(float(target.get("max_hp",0))*0.12))
	if not control and not strong: return
	var cast := str(event.get("cast_id",""))
	var key := "cast:"+cast if not cast.is_empty() else "source:%s:%s"%[str(source.get("id","")),str(event.get("skill_id",""))]
	if _screen_casts.has(key) and (not cast.is_empty() or tick-int(_screen_casts[key])<24): return
	if not _screen_casts.has(key): _screen_cast_order.append(key)
	_screen_casts[key]=tick
	while _screen_cast_order.size()>MAX_SCREEN_CASTS: _screen_casts.erase(_screen_cast_order.pop_front())
	_screen_pulses.append({"target_id":str(target.get("id","")),"tick":tick,"strength":4 if control else 5})
	while _screen_pulses.size()>MAX_SCREEN_PULSES: _screen_pulses.pop_front()

func _remember(id: String) -> void:
	if id.is_empty() or _seen.has(id): return
	_seen[id]=true
	_seen_order.append(id)
	while _seen_order.size()>MAX_SEEN_RECEIPTS: _seen.erase(_seen_order.pop_front())

func _prune(tick: int) -> void:
	for i: int in range(_numbers.size()-1,-1,-1):
		if tick-int(_numbers[i].tick)>=NUMBER_LIFETIME_TICKS:
			_number_lookup.erase(str(_numbers[i].key))
			_numbers.remove_at(i)
	for id: String in _target_lanes.keys():
		if tick-int(_target_lanes[id].tick)>=8: _target_lanes.erase(id)
	for id: String in _controls.keys():
		if int(_controls[id].expires_tick)<=tick: _controls.erase(id)
	for i: int in range(_screen_pulses.size()-1,-1,-1):
		if tick-int(_screen_pulses[i].tick)>=SCREEN_LIFETIME_TICKS: _screen_pulses.remove_at(i)

static func _events(snapshot: Dictionary) -> Array:
	return snapshot.get("combat_feedback_events",snapshot.get("combat",{}).get("combat_feedback_events",[])).slice(-256)

static func _actor_index(snapshot: Dictionary) -> Dictionary:
	var result := {}
	for group: String in ["soldiers","workers","buildings"]:
		for body: Dictionary in snapshot.get(group,[]):
			var id := str(body.get("id",""))
			if not id.is_empty(): result[id]=body
	return result

static func _visible(body: Dictionary, side: String) -> bool:
	if not bool(body.get("visible",true)) or bool(body.get("hidden",false)): return false
	return side in body.visible_to if body.get("visible_to") is Array else true

static func _point(value: Variant) -> bool:
	return (value is Vector2 or value is Vector2i) and Vector2(value).is_finite()

static func _match_signature(snapshot: Dictionary) -> String:
	var config: Dictionary=snapshot.get("match_config",snapshot.get("match_setup",{}))
	var sides: Array=[]
	for side: Dictionary in config.get("sides",[]): sides.append([side.get("side_id"),side.get("faction_id"),side.get("home")])
	return "%s:%s:%s:%s"%[str(snapshot.get("seed",0)),str(snapshot.get("ruleset","")),str(config.get("map_id","")),JSON.stringify(sides)]
