extends RefCounted
## Permanent factual heraldry, plus V6 presentation-only material shimmer.
## Never infers an affected unit from proximity: beneficiary marks require
## published facts. Core glyphs remain stable when the visual clock changes.
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Innates = preload("res://src/simulation/strategic_hero_innates.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const Finish = preload("res://src/presentation/heroic_aura_finish_v6.gd")
const INK := Color("14141f")
const RANGE_ALPHA := 0.24
const SELECTED_RANGE_ALPHA := 0.32
const RAMPS := {"HUMAN":"f3d58b","UNDEAD":"dda6b2","MACHINE":"9cdae1","FOREST":"b4d584","HIGHLAND":"ffc17b","UNDERGROUND":"d7b4ee"}
# Seven-cell heraldic stamps, deliberately authored per identity rather than
# recolouring one universal rune. Three transparent border pixels hold glow.
const GLYPHS := {
	"ROOT_NETWORK":"#..#..#/.#.#.#./..###../#######/..###../.#.#.#./#..#..#",
	"INNATE_COMMANDER":"..#..../..####./..#..#./..####./..#..../..#..../.###...",
	"INNATE_DUELIST":"#.....#/.#...#./..#.#../...#.../..#.#../.#...#./#.....#",
	"INNATE_RANGER":".#...#./.##.##./..###../...#.../..###../.#.#.#./...#...",
	"INNATE_ARCANIST":"...#.../.#####./.#.#.#./.#.#.#./.#.#.#./.#####./...#...",
	"INNATE_BULWARK":".#####./.#.#.#./##.#.##/.#.#.#./.#.#.#./..###../...#...",
	"INNATE_ASH_CHANTER":"...#.../..###../..#.#../.#####./.#.#.#./..###../...#...",
	"INNATE_GRAVE_BELL":"..###../.#...#./.#.#.#./.#...#./##...##/..#.#../...#...",
	"INNATE_CINDER_STALKER":"##...##/.##.##./..###../...#.../...#.../..#.#../.#...#.",
	"INNATE_MOURN_ORACLE":"......./..###../.#...#./#..#..#/.#...#./..###../...#...",
	"INNATE_ASH_MARSHAL":"#..#..#/#..#..#/.#.#.#./.#####./.#.#.#./..###../...#...",
	"INNATE_COIL_MEDIC":"..#.#../.#####./##.#.##/.#####./##.#.##/.#####./..#.#..",
	"INNATE_SIGNAL_KEEPER":"#..#..#/.#.#.#./..###../...#.../..###../...#.../.#####.",
	"INNATE_GEAR_HUNTER":"..#.#../.##.##./##...##/...#.../##...##/.##.##./..#.#..",
	"INNATE_VOLT_WEAVER":"...#.../..###../.#.#.#./#..#..#/.#####./..#.#../.#####.",
	"INNATE_COIL_WARDEN":"...#.../.#####./...#.../#..#..#/#..#..#/.#.#.#./..###..",
	"INNATE_BLOOM_GUIDE":"..#.#../.#.#.#./#..#..#/.#####./#..#..#/.#.#.#./..#.#..",
	"INNATE_THORN_CHANTER":"#....#./.##.#../..###../.##.##./..###../..#.##./.#....#",
	"INNATE_WIND_COURIER":"###.###/.##.##./..###../...#.../..#.#../.#...#./.......",
	"INNATE_LEAF_SEER":"....##./..##.#./.#...#./.#..#../.#.#.../..#..../.#.....",
	"INNATE_VINE_WARDEN":"...#.../.#.#.#./..###../...#.../..###../.#.#.#./#..#..#",
	"INNATE_HEARTH_KEEPER":".#####./.#...#./.#.#.#./.##.##./.#.#.#./.#####./##...##",
	"INNATE_STORM_HERALD":"....#../...##../..##.../.#####./...##../..##.../..#....",
	"INNATE_EMBER_CAVALIER":".##.##./##...##/#.....#/#..#..#/.#.#.#./..###../...#...",
	"INNATE_RUNE_ORACLE":".#####./.#...#./.###.#./.#.#.#./.#.###./.#...#./.#####.",
	"INNATE_RIDGE_JARL":"...#.../..#.#../.#...#./#######/..###../..###../.#####.",
	"INNATE_SPORE_GUIDE":"..###../.#####./##.#.##/...#.../.##.##./##...##/.#...#.",
	"INNATE_QUAKE_PRIEST":"#.....#/.#...#./..#.#../...#.../..#.#../.#.#.#./#..#..#",
	"INNATE_SPORE_STALKER":"##...##/#.#.#.#/.#.#.#./..###../.#...#./#.....#/.......",
	"INNATE_ECHO_BINDER":"..#.#../.#...#./#.#.#.#/#.#.#.#/#.#.#.#/.#...#./..#.#..",
	"INNATE_TUNNEL_SENTINEL":"..###../.#.#.#./#.#.#.#/#..#..#/.#.#.#./..###../...#...",
	"CLEAVE":"...#.../..###../.##.##./...#.../.#####./.#.#.#./...#...",
	"SEAL_STRIKE":"#..#..#/.#####./...#.../.#####./#..#..#/...#.../.#####.",
	"ASH_LANTERN":"..#.#../...#.../..###../.#.#.#./.#...#./..###../..#.#..",
	"GRAVE_CADENCE":".#...#./.##.##./.#.#.#./.#####./...#.../..#.#../.#...#.",
	"COIL_BATTERY":"..###../.#####./.#.#.#./.##.##./.#.#.#./.#####./..###..",
	"SIGNAL_MARCH":"#.....#/.#.#.#./..###../...#.../.#####./...#.../..#.#..",
	"BLOOM_SPRING":"...#.../.#.#.#./..###../###.###/..###../.#.#.#./...#...",
	"THORN_BREEZE":"#.#.#.#/.#####./..###../...#.../..###../.#####./#.#.#.#",
	"HEARTH_WARMTH":"......./.#...#./..#.#../.##.##./.#.#.#./.#####./##...##",
	"STORM_CHANT":"#.#.#.#/.#.#.#./..###../.#####./..###../...#.../..#....",
	"SPORE_GLOW":".##.##./#######/.#.#.#./...#.../..###../.#.#.#./#..#..#",
	"QUAKE_RHYTHM":"#..#..#/.#.#.#./..###../###.###/..#.#../.#...#./#.....#",
	"BULWARK_WARD":"#######/#.#.#.#/.#####./.#...#./.#.#.#./..###../...#...",
	"ASH_WARD":"#.....#/.#####./.#.#.#./..###../.#.#.#./..###../...#...",
	"COIL_WARD":"..#.#../.#####./#.#.#.#/.#.#.#./#.#.#.#/.#####./..###..",
	"VINE_WARD":".#.#.#./..###../.#...#./#.#.#.#/.#.#.#./..###../.#.#.#.",
	"RIDGE_WARD":"...#.../..###../.#.#.#./#..#..#/.#####./.#.#.#./..###..",
	"TUNNEL_WARD":".#####./#..#..#/#.#.#.#/.#.#.#./..###../.#.#.#./#..#..#",
	"WAR_STANDARD":".#####./.#.#.#./.#.#.#./.#####./...#.../..###../.#.#.#.",
	"AEGIS_STANDARD":".#####./.#...#./.#.#.#./..###../...#.../.#####./...#...",
	"SPRING_STANDARD":".#####./.#.#.#./.##.##./.#.#.#./...#.../..###../...#...",
	"MANA_STANDARD":".#####./.#.#.#./.#.#.#./..###../...#.../.#.#.#./..###..",
}
static var _textures: Dictionary = {}

static func identity(id: String, faction: String, radius: float=0.0, origin: String="INNATE") -> Dictionary:
	# NaN/INF is invalid observation data, not an unbounded aura. Negative finite
	# radii normalize to zero: this denotes a single-unit passive, not a range.
	if not GLYPHS.has(id) or not is_finite(radius): return {}
	return {"id":id,"signature":GLYPHS[id],"faction":faction,"radius":maxf(radius,0.0),"origin":origin,"persistent":true,"minimum_alpha":0.56,"simulation_geometry":false}

static func sources(hero: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if int(hero.get("hp",0))<=0 or not bool(hero.get("alive",true)) or not bool(hero.get("visible",true)) or bool(hero.get("hidden",false)): return result
	var emitted: Dictionary = {}
	var faction := str(hero.get("faction_id","HUMAN"))
	if hero.get("unit_type","")=="root_mender":result.append(identity("ROOT_NETWORK",faction,160,"SUPPORT"))
	var archetype := str(hero.get("hero_archetype",hero.get("archetype","")))
	var innate: Dictionary = hero.get("innate",Innates.profile(archetype))
	var own := identity("INNATE_"+archetype,faction,float(innate.get("radius",0)),"INNATE")
	if not own.is_empty(): result.append(own); emitted[str(own.id)]=true
	for skill: Dictionary in hero.get("skills",[]):
		if int(skill.get("level",0))<=0 or str(skill.get("effect","")) not in ["AURA","PASSIVE_GUARD"]: continue
		var mark := identity(str(skill.get("id","")),faction,float(skill.get("aura_radius",0)) if skill.get("effect")=="AURA" else 0.0,"SKILL")
		if not mark.is_empty() and not emitted.has(str(mark.id)): result.append(mark); emitted[str(mark.id)]=true
	for item_id: String in hero.get("equipment",[]):
		if item_id not in ["WAR_STANDARD","AEGIS_STANDARD","SPRING_STANDARD","MANA_STANDARD"]: continue
		var mark := identity(item_id,faction,200.0,"ITEM")
		if not mark.is_empty() and not emitted.has(str(mark.id)): result.append(mark); emitted[str(mark.id)]=true
	return result

static func beneficiaries(unit: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not bool(unit.get("visible",true)) or bool(unit.get("hidden",false)): return result
	var emitted: Dictionary = {}
	if not str(unit.get("support_aura_source_id","")).is_empty():
		var support_mark:=identity("ROOT_NETWORK","FOREST",0.0,"BENEFICIARY")
		support_mark.source_id=unit.support_aura_source_id
		result.append(support_mark)
	for fact: Dictionary in unit.get("innate_aura",{}).get("sources",[]):
		var id := str(fact.get("innate_id",""))
		if emitted.has(id): continue
		var archetype := id.trim_prefix("INNATE_")
		if not id.begins_with("INNATE_") or not Heroes.PROFILES.has(archetype): continue
		# The passive's material language follows its actual source, even when
		# an enemy bell debuffs a soldier from another faction.
		var source_faction := str(Heroes.PROFILES[archetype].get("faction_id","HUMAN"))
		var mark := identity(id,source_faction,0.0,"BENEFICIARY")
		if mark.is_empty(): continue
		mark.source_id=str(fact.get("source_id","")); result.append(mark); emitted[id]=true
	# M75 publishes winning learned/item aura sources from actual settlement.
	# A nearby hero, inventory entry or generic AURA status is not sufficient.
	for fact: Dictionary in unit.get("aura_sources",[]):
		var id := str(fact.get("item_id",fact.get("stats_id","")))
		if emitted.has(id) or not GLYPHS.has(id): continue
		var source_id := str(fact.get("source_id",fact.get("id","")))
		if source_id.is_empty(): continue
		var mark := identity(id,str(fact.get("faction_id","HUMAN")),0.0,"BENEFICIARY")
		mark.source_id=source_id
		result.append(mark)
		emitted[id]=true
	return result

static func _texture(id: String) -> Texture2D:
	if _textures.has(id): return _textures[id]
	if not GLYPHS.has(id): return null
	var bitmap := Image.create(13,13,false,Image.FORMAT_RGBA8)
	var occupied: Dictionary = {}
	var rows: PackedStringArray = str(GLYPHS[id]).split("/")
	for y: int in range(rows.size()):
		for x: int in range(rows[y].length()):
			if rows[y][x]=="#": occupied[Vector2i(x+3,y+3)]=true
	for y: int in range(13):
		for x: int in range(13):
			var point := Vector2i(x,y)
			var distance := 4
			for near: Vector2i in occupied:
				distance=mini(distance,maxi(absi(near.x-x),absi(near.y-y)))
			if distance==0: bitmap.set_pixel(x,y,Color(1,1,1,0.82))
			elif distance==1: bitmap.set_pixel(x,y,Color(0.12,0.10,0.17,0.65))
			elif distance==2: bitmap.set_pixel(x,y,Color(1,1,1,0.14))
	var texture := ImageTexture.create_from_image(bitmap)
	_textures[id]=texture
	return texture

static func draw_mark(canvas: Object, center: Vector2, mark: Dictionary, factor: float=1.0, beneficiary: bool=false, _tick: int=0) -> bool:
	if not center.is_finite() or not is_finite(factor) or factor<=0 or not GLYPHS.has(mark.get("id","")): return false
	var tint := Color(str(RAMPS.get(mark.get("faction","HUMAN"),RAMPS.HUMAN)))
	var cell := clampf(roundf(factor*1.6),1,3) if not beneficiary else clampf(roundf(factor),1,2)
	var size := Vector2(13,13)*cell
	canvas.draw_texture_rect(_texture(str(mark.id)),Rect2((center-size*0.5).round(),size),false,Color(tint,0.94 if beneficiary else 1.0))
	return true

static func draw_source(canvas: Object, center: Vector2, source: Dictionary, factor: float, selected: bool) -> void:
	if not center.is_finite() or not is_finite(factor) or factor<=0: return
	var raw_radius:=float(source.get("radius",0))
	if not is_finite(raw_radius): return
	var radius := maxf(raw_radius,0.0)*factor
	if not is_finite(radius): return
	if not (center+Vector2.ONE*radius).is_finite() or not (center-Vector2.ONE*radius).is_finite(): return
	if radius>0:
		var team := Palette.side_color(str(source.get("side","PLAYER")))
		# Truthful circle, rounded to pixels: a quiet, thicker team under-rim
		# plus intermittent material inlay, never a second false radius. Fixed
		# upper bound is below the old 240-segment per-source outline.
		var segments := clampi(ceili(TAU*minf(radius,200.0)/12),32,64)
		var phase := Finish.phase(int(source.get("tick",0)))
		var family := "HUMAN"
		for mark: Dictionary in source.get("identities",[]):
			if GLYPHS.has(str(mark.get("id",""))): family=str(mark.get("faction","HUMAN"));break
		var last := (center+Vector2(radius,0)).round()
		for index: int in range(1,segments+1):
			var at := (center+Vector2.from_angle(TAU*float(index)/segments)*radius).round()
			canvas.draw_line(last,at,Color(team,SELECTED_RANGE_ALPHA if selected else RANGE_ALPHA),3 if selected else 2,false)
			if index%4==phase:
				canvas.draw_line(last,at,Finish.tint(family,1 if index%8==phase else 2,0.44 if selected else 0.31),1,false)
			last=at
	var emitted: Dictionary = {}
	var ground_origins: Dictionary = {}
	for mark: Dictionary in source.get("identities",[]):
		var id:=str(mark.get("id",""))
		if emitted.has(id) or not GLYPHS.has(id): continue
		emitted[id]=true
		var origin := Finish.origin_group(str(mark.get("origin","INNATE")))
		if not ground_origins.has(origin):
			ground_origins[origin]=true
			# One seal per origin in an already merged emitter/radius group,
			# rather than four overlapping equipment circles. The exact old
			# identity stamp is still rendered below, once for every real mark.
			Finish.draw_seal(canvas,center,id,str(GLYPHS[id]),str(mark.get("faction","HUMAN")),origin,factor)
			# Zero-range passive is a local identity, not an animated aura rim.
			if radius>0: Finish.draw_source_wisps(canvas,center,str(mark.get("faction","HUMAN")),origin,factor,int(source.get("tick",0)))
		var slot := maxi(int(mark.get("slot",0)),0)
		var offsets := [Vector2(-27,9),Vector2(0,21),Vector2(27,9),Vector2(-31,-11),Vector2(31,-11),Vector2(0,-31),Vector2(-45,5)]
		draw_mark(canvas,center+offsets[mini(slot,6)]*maxf(factor,0.65),mark,factor,false,int(source.get("tick",0)))

static func draw_beneficiaries(canvas: Object, center: Vector2, unit: Dictionary, factor: float, tick: int=0) -> int:
	if not center.is_finite() or not is_finite(factor) or factor<=0: return 0
	var marks := beneficiaries(unit)
	for index: int in range(mini(marks.size(),5)):
		# Keep factual benefit signatures just outside the foot, never pasted
		# across a soldier's belt, face or weapon animation.
		var horizontal:=(index-(mini(marks.size(),5)-1)*0.5)*12
		var depth:=13+absf(horizontal)*0.08
		var at := center+Vector2(horizontal,depth)*maxf(factor,0.65)
		if draw_mark(canvas,at,marks[index],factor,true,tick): Finish.draw_recipient_wisps(canvas,at,marks[index],factor,tick)
	return mini(marks.size(),5)

static func debug_stats() -> Dictionary:
	var result := Finish.debug_stats()
	result["legacy_glyph_textures"]=_textures.size()
	result["legacy_glyph_texture_limit"]=GLYPHS.size()
	result["maximum_source_range_lines"]=80
	result["maximum_source_wisp_lines"]=36
	result["maximum_recipient_marks"]=5
	result["maximum_recipient_wisp_lines"]=10
	return result
