extends RefCounted
## Read-only logical-screen-pixel identity frames. Never simulation geometry.
const Progression = preload("res://src/simulation/strategic_progression_catalog.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const AuraArt = preload("res://src/presentation/heroic_aura_art.gd")
const INK := Color("11151c")
const GOLD := Color("b79a55")
const MANA := Color("4c93dc")

static func living(unit: Dictionary) -> bool:
	return int(unit.get("hp",0)) > 0 and bool(unit.get("alive",true))

static func visible_to(unit: Dictionary, side: String) -> bool:
	if not bool(unit.get("visible",true)) or bool(unit.get("hidden",false)): return false
	return side in unit.visible_to if unit.get("visible_to") is Array else true

static func is_hero(unit: Dictionary) -> bool:
	return str(unit.get("unit_type",""))=="hero"

static func bar_size(unit: Dictionary, overview: bool=false) -> Vector2:
	if is_hero(unit): return Vector2(58,8) if overview else Vector2(76,10)
	var pop := int(unit.get("population",Progression.POPULATION.get(str(unit.get("unit_type","worker")),1)))
	if bool(unit.get("neutral",false)) and pop <= 0:
		var level := int(unit.get("neutral_level",unit.get("level",1)))
		pop = 1 if level <= 2 else 2 if level <= 4 else 4 if level <= 6 else 6
	if pop >= 6: return Vector2(46,6) if overview else Vector2(60,8)
	if pop == 5: return Vector2(40,6) if overview else Vector2(54,8)
	if pop >= 3: return Vector2(36,5) if overview else Vector2(48,7)
	if pop == 2: return Vector2(30,4) if overview else Vector2(40,6)
	return Vector2(24,4) if overview else Vector2(32,6)

static func bars(unit: Dictionary, stable_bounds: Rect2, overview: bool=false) -> Dictionary:
	if not living(unit): return {}
	var size := bar_size(unit,overview)
	var hp := Rect2(Vector2(-size.x*0.5,stable_bounds.position.y-size.y-7).round(),size)
	var mana := Rect2(hp.position+Vector2(0,size.y+2),size) if float(unit.get("max_mana",0))>0 else Rect2()
	# Keep mana below HP but ABOVE body, not across the head.
	if mana.has_area(): hp.position.y-=size.y+2; mana.position.y-=size.y+2
	return {"hp":hp,"mana":mana,"hero":is_hero(unit),"level":int(unit.get("hero_level",unit.get("level",1))),"overview":overview}

static func hero_ellipse(unit: Dictionary, footprint: Vector2, factor: float) -> Dictionary:
	if not living(unit) or not is_hero(unit) or factor <= 0: return {}
	# Fixed semantic footprint, never current attack bounds or weapon extent.
	return {"radii":Vector2(maxf(footprint.x*0.65,18*factor),maxf(footprint.y*0.65,7*factor)),"color":Palette.side_color(str(unit.get("side","PLAYER"))),"persistent":true,"simulation_geometry":false}

static func draw_hero_ellipse(canvas: Object, point: Vector2, unit: Dictionary, footprint: Vector2, factor: float) -> void:
	var ellipse := hero_ellipse(unit,footprint,factor)
	if ellipse.is_empty(): return
	var radii: Vector2 = ellipse.radii
	var color: Color = ellipse.color
	# Discrete transparent pixel rims, never a blur or a filled light disk.
	for layer: int in [2,1,0]:
		var alpha: float = [0.64,0.22,0.10][layer]
		var expanded := radii+Vector2(2*layer,layer)
		var unique: Dictionary = {}
		for i: int in range(64):
			var angle := TAU*float(i)/64.0
			var pixel := ((point+Vector2(cos(angle)*expanded.x,sin(angle)*expanded.y))/2.0).round()*2
			if unique.has(pixel): continue
			unique[pixel]=true
			canvas.draw_rect(Rect2(pixel,Vector2(2,2)),Color(color,alpha))
	for x: int in [-1,1]: canvas.draw_rect(Rect2((point+Vector2(x*radii.x-1,-1)).round(),Vector2(3,3)),Color("d8c485",0.8))

static func _meter(canvas: Object, rect: Rect2, ratio: float, color: Color, ornate: bool) -> void:
	canvas.draw_rect(rect,INK)
	var inner := rect.grow(-2 if ornate else -1)
	canvas.draw_rect(inner,Color("28302d"))
	var filled := floorf(inner.size.x*clampf(ratio,0,1))
	if filled > 0:
		canvas.draw_rect(Rect2(inner.position,Vector2(filled,inner.size.y)),color.darkened(0.18))
		canvas.draw_rect(Rect2(inner.position,Vector2(filled,maxf(1,floorf(inner.size.y*0.45)))),color.lightened(0.18))
	if ornate:
		for x: float in [rect.position.x-3,rect.end.x]:
			canvas.draw_rect(Rect2(Vector2(x,rect.position.y-1),Vector2(3,rect.size.y+2)),INK)
			canvas.draw_rect(Rect2(Vector2(x+1,rect.position.y),Vector2(1,rect.size.y)),GOLD)

static func draw_bars(canvas: Object, point: Vector2, unit: Dictionary, stable_bounds: Rect2, overview: bool=false) -> Dictionary:
	var info := bars(unit,stable_bounds,overview)
	if info.is_empty(): return info
	var hp: Rect2 = info.hp
	hp.position=(hp.position+point).round()
	_meter(canvas,hp,float(unit.get("hp",0))/maxf(float(unit.get("max_hp",1)),1),Palette.side_color(str(unit.get("side",""))),bool(info.hero))
	var mana: Rect2 = info.mana
	if mana.has_area():
		mana.position=(mana.position+point).round()
		_meter(canvas,mana,float(unit.get("mana",0))/maxf(float(unit.get("max_mana",1)),1),MANA,bool(info.hero))
	if bool(info.hero):
		var crown := hp.position+Vector2(-8,-2)
		canvas.draw_rect(Rect2(crown,Vector2(6,hp.size.y+4)),INK)
		canvas.draw_rect(Rect2(crown+Vector2(1,1),Vector2(4,2)),GOLD)
		for i: int in range(clampi(int(info.level),1,8)):
			canvas.draw_rect(Rect2(crown+Vector2(1+i%2*2,4+i/2*2),Vector2(1,1)),Color("e8d69c"))
	return info


static func aura_sources(snapshot: Dictionary, side: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var emitters:Array=snapshot.get("heroes",{}).get("officers",[]).duplicate()
	# ArmySupport's root network is a real non-hero passive aura. Heroes already
	# come from the richer officer view; do not emit their body copies twice.
	for body:Dictionary in snapshot.get("soldiers",[]):
		if body.get("unit_type","")=="root_mender":emitters.append(body)
	for hero: Dictionary in emitters:
		if not living(hero) or not visible_to(hero,side): continue
		if str(hero.get("id","")).is_empty() or not (hero.get("position") is Vector2 or hero.get("position") is Vector2i): continue
		if not Vector2(hero.position).is_finite(): continue
		var emitted: Dictionary = {}
		var slot := 0
		for mark: Dictionary in AuraArt.sources(hero):
			mark.slot=slot
			_add_aura(emitted,hero,int(mark.radius),str(mark.id),str(mark.origin))
			var key := str(hero.id)+":"+str(int(mark.radius))
			emitted[key].identities.append(mark)
			slot+=1
		for value: Dictionary in emitted.values(): result.append(value)
	return result

static func _add_aura(emitted: Dictionary, hero: Dictionary, radius: int, kind: String, origin: String) -> void:
	# Same emitter/radius is one readable range rim, never stacked identical
	# circles. Real beneficiary glows are separately driven by active statuses.
	var key := str(hero.id)+":"+str(radius)
	if not emitted.has(key): emitted[key]={"source_id":hero.id,"position":hero.position,"radius":radius,"side":str(hero.get("side","PLAYER")),"kinds":[],"origins":[],"identities":[]}
	if kind not in emitted[key].kinds: emitted[key].kinds.append(kind)
	if origin not in emitted[key].origins: emitted[key].origins.append(origin)

static func draw_aura_source(canvas: Object, center: Vector2, source: Dictionary, factor: float, selected: bool, tick: int=0) -> void:
	# Animation clocks belong to this draw, not the published aura facts.
	# Keep aura_sources() clock-independent and callers' dictionaries untouched.
	var visual_source:=source.duplicate()
	visual_source.tick=tick
	AuraArt.draw_source(canvas,center,visual_source,factor,selected)
