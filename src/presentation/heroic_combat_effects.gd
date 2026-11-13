extends RefCounted
## Semantic combat echoes from facts only; no nodes, timers, RNG or authority.
const Atlas = preload("res://src/presentation/heroic_combat_atlas.gd")
const Legacy = preload("res://src/presentation/heroic_collection_effects.gd")
const Collection = preload("res://src/presentation/heroic_collection.gd")
const WeaponArt = preload("res://src/presentation/heroic_weapon_art.gd")
const SkillArt = preload("res://src/presentation/heroic_skill_art.gd")
const ReworkR7 = preload("res://src/presentation/heroic_rework_r7_effects.gd")
const RosterV5 = preload("res://src/presentation/heroic_roster_v5.gd")
const SupportArt = preload("res://src/presentation/heroic_support_art.gd")
const TroopV4 = preload("res://src/simulation/strategic_troop_skills_v4.gd")
const CellBrushR8 = preload("res://src/presentation/m63_av_brush.gd")
const TROOP_V4_PALETTES := {
	"DENY_FORD_SEAL":["2c2429","9b704d","dec38b","fff2c6"],
	"SEAL_PAGE_VEIL":["252d30","798b86","bed3b5","eee9c6"],
	"LONELY_NAME_EMBER_CHAIN":["272330","766877","b1b99d","e1d8b9"],
	"PHASE_DISCHARGE":["1c2b36","526f83","89c6cf","f1eed4"],
	"DORMANT_BUD_PATH":["273c34","5d8558","aecb8e","dfedc6"],
	"SWIFT_WING_RETURN":["263f3a","73958a","b2d9b4","f2e9ae"],
	"KILN_BACK_FERVOR":["392731","97634a","e1a15e","ffdf9d"],
	"FROST_KILN_EMBER":["302e40","8b7788","d59469","d8ebdf"],
	"THREEFOLD_COLLAPSE_NOTE":["292437","736685","b4a0be","e8e2ba"],
	"FAULT_PIERCING_RIDGE":["27232f","736474","ac9d9b","ded3af"],
	"NAME_ASH_VIGIL_R4":["28212d","775862","c69c73","f1dcb0"],
	"RUNE_EARTHBREAK_R4":["292735","6b6873","b4a3ab","f1d9ad"],
	"DEEP_SHARED_VAULT_R4":["292532","706679","aca8a1","e5d9b7"],
}
const MAX_ACTIONS := 96
const MAX_IMPACTS := 6
const MAX_WEAPON_DRAW_COMMANDS := 96
const MAX_SKILL_DRAW_COMMANDS := 160
const MAX_SUPPORT_DRAW_COMMANDS := 64
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const CASTS := {"HUMAN":"HolyLight","UNDEAD":"DeathRipple","MACHINE":"LightningBolt","FOREST":"StoneSpikes","HIGHLAND":"FlameStrike","UNDERGROUND":"AcidSplash"}
const ROOTS := {"HUMAN":"IceSpikes","UNDEAD":"DeathRipple","MACHINE":"LightningBolt","FOREST":"StoneSpikes","HIGHLAND":"IceSpikes","UNDERGROUND":"StoneSpikes"}
const IMPACTS := {"HUMAN":"HolyLight","UNDEAD":"DeathRipple","MACHINE":"Shrapnel","FOREST":"Shrapnel","HIGHLAND":"Explosion","UNDERGROUND":"AcidSplash"}
const PHYSICAL := ["CLEAVE","WHIRLWIND","EMBER_SWEEP","SPORE_SWEEP","SEAL_STRIKE","EMBER_SEAL","SPORE_SEAL"]
const SHOTS := ["PIERCING_SHOT","CINDER_SHOT","GEAR_SHOT","WIND_SHOT"]
const SUPPORT_CASTERS := ["ASH_CHANTER","GRAVE_BELL","COIL_MEDIC","SIGNAL_KEEPER","BLOOM_GUIDE","THORN_CHANTER","HEARTH_KEEPER","STORM_HERALD","SPORE_GUIDE","QUAKE_PRIEST"]
# Four-value ramps share the licensed collection's dark outline and restricted
# highlights. Blue remains spell/MP information, never the player's team tint.
const PALETTES := {
	"HUMAN":["241d2b","99704b","efc969","fff0bb"],
	"UNDEAD":["211b2b","79556c","c88b94","f2d8ba"],
	"MACHINE":["1c2431","496878","86c7d6","f3f1c7"],
	"FOREST":["1b2826","52794b","abd17a","f1edb4"],
	"HIGHLAND":["2d2029","a24d3e","f29b4c","fff0a5"],
	"UNDERGROUND":["231d2e","755b99","bfa3de","f3e6b9"],
}

static func _alive(unit: Dictionary) -> bool:
	return int(unit.get("hp",0)) > 0 and bool(unit.get("alive",true))

static func _faction(unit: Dictionary) -> String:
	var faction := str(unit.get("faction_id","HUMAN"))
	if bool(unit.get("neutral",false)):
		faction = str(unit.get("neutral_origin_faction_id",""))
		if faction.is_empty(): faction = str({"ROCKKIN":"HIGHLAND","SPOREBROOD":"UNDERGROUND","ROAD_BAND":"HUMAN","THORN_WATCH":"FOREST","GRAVEBOUND":"UNDEAD","RUNE_WILD":"MACHINE"}.get(unit.get("neutral_series_id",""),"HUMAN"))
	return faction if faction in FACTIONS else "HUMAN"

static func inspect_action(unit: Dictionary, pose: Dictionary) -> Dictionary:
	var action := str(pose.get("action","IDLE"))
	var phase := float(pose.get("phase",0))
	if not _alive(unit) or not is_finite(phase) or phase < 0 or phase >= 1: return {"supported":false}
	if action not in ["ATTACK","HEAL","POTION"] and not action.begins_with("SKILL_"): return {"supported":false}
	var skill: Dictionary = pose.get("skill",{})
	if action.begins_with("SKILL_") and skill.is_empty(): return {"supported":false}
	if action.begins_with("SKILL_") and bool(skill.get("passive",false)): return {"supported":false}
	var troop_entry := _inspect_troop_v4(unit,pose)
	if bool(troop_entry.get("supported",false)): return troop_entry
	var faction := _faction(unit)
	var kind := "spell"
	var spell: String = CASTS[faction]
	var id := action.trim_prefix("SKILL_")
	var attack_type := str(unit.get("last_action_attack_type",unit.get("attack_type","")))
	if action == "ATTACK":
		# Damage class is not a weapon silhouette: chaos heroes retain their
		# actual staff/bow/blade, and impact infantry never launch cannonballs.
		if str(unit.get("unit_type","")) == "fire_dragon": kind = "fire_projectile"
		elif str(unit.get("hero_archetype",""))=="GEAR_HUNTER": kind="gunshot"
		elif attack_type == "ARCANE" or str(unit.get("hero_archetype","")) in Legacy.MAGIC_HEROES or str(unit.get("hero_archetype","")) in SUPPORT_CASTERS: kind = "magic_projectile"
		elif attack_type == "GUNPOWDER": kind = "cannon" if unit.get("unit_type") == "gear_engine" else "gunshot"
		elif attack_type == "IMPACT" and unit.get("unit_type") == "stone_slinger": kind = "stone"
		elif float(unit.get("attack_range",0)) > 75: kind = "arrow"
		else: kind = "slash"; spell = "FirstStrike"
	elif action in ["HEAL","POTION"]: spell = "Cure"
	elif id == "ARROW_RAIN": kind = "rain"
	elif id == "GEAR_SHOT": kind = "gunshot"
	elif id in SHOTS: kind = "piercing_arrow"
	elif id in PHYSICAL and str(skill.get("effect","DAMAGE")) in ["DAMAGE","STUN","ROOT"]: kind = "slash"; spell = "FirstStrike"
	elif skill.get("effect") == "HEAL": spell = "Cure"
	elif skill.get("effect") == "ARMOR_BUFF": spell = "Shield"
	elif skill.get("effect") == "DAMAGE_BUFF": spell = "Bloodlust"
	elif skill.get("effect") == "RALLY": spell = "Bless"
	elif skill.get("effect") in ["ROOT","SLOW"]: spell = ROOTS[faction]
	elif skill.get("effect") == "STUN": spell = "LightningBolt" if faction == "MACHINE" else "StoneSpikes" if faction in ["FOREST","HIGHLAND","UNDERGROUND"] else "HolyLight"
	elif id == "STARFIRE": spell = "FireBall"
	elif id == "NEUTRAL_VENOM": spell = "AcidSplash"
	elif id == "NEUTRAL_SHARD": spell = "Shrapnel"
	elif id == "NEUTRAL_DRAIN": spell = "DeathRipple"
	elif id == "NEUTRAL_WARD": spell = "Shield"
	var entry := {"supported":true,"kind":kind,"spell":spell,"phase":phase,"faction":faction,"action":action,"rank":clampi(int(skill.get("level",1)),1,3),"at_self":action=="POTION" or str(skill.get("target_mode",""))=="SELF","delivery":str(skill.get("delivery","AREA")),"attack_type":str(skill.get("attack_type",attack_type)),"max_impacts":MAX_IMPACTS}
	var effect := str(skill.get("effect",""))
	var family := "weapon_"+kind if action=="ATTACK" else "restore" if action in ["HEAL","POTION"] or effect=="HEAL" else "guard" if effect in ["ARMOR_BUFF","PASSIVE_GUARD"] else "fervor" if effect in ["DAMAGE_BUFF","RALLY"] else "aura" if effect=="AURA" else "bind" if effect in ["ROOT","SLOW"] else "shock" if effect=="STUN" else "spell_"+(spell.to_lower() if kind=="spell" else kind)
	var intensity := 4 if bool(skill.get("ultimate",false)) else 3 if int(unit.get("population",0))>=6 else 2 if action.begins_with("SKILL_") or str(unit.get("unit_type",""))=="hero" or int(unit.get("population",0))>=3 else 1
	var layers: Array = ["weapon_trail","impact_chips"] if kind=="slash" else ["projectile_trail","impact_chips"] if kind in ["arrow","piercing_arrow","gunshot","stone","magic_projectile","cannon","fire_projectile"] else ["cast_motif","settled_impact"]
	if family in ["restore","guard","fervor","aura"]: layers=["cast_motif","rising_motes"]
	if family in ["bind","shock"]: layers=["cast_motif","control_signature"]
	if str(entry.delivery) in ["CHAIN","LINE"]: layers.append("settled_"+str(entry.delivery).to_lower())
	if intensity==4: layers.append("ultimate_crown")
	entry.merge({"profile":faction.to_lower()+"_"+family,"layers":layers,"intensity":intensity,"palette":PALETTES[faction].duplicate(),"settled_only":true,"effect":effect,"ultimate":bool(skill.get("ultimate",false)),"max_draw_operations":48},true)
	var dedicated := WeaponArt.inspect(unit,pose) if action=="ATTACK" else SupportArt.inspect(unit,pose) if action=="HEAL" else SkillArt.inspect(unit,pose)
	if bool(dedicated.get("supported",false)): entry.merge(dedicated,true)
	elif action.begins_with("SKILL_") and str(unit.get("hero_archetype","")) in SkillArt.Heroes.ARCHETYPES: return {"supported":false}
	return entry

static func _sprite(canvas: Object, spell: String, phase: float, point: Vector2, scale: float, tint: Color = Color.WHITE) -> bool:
	if Atlas.draw(canvas,spell,phase,point,scale,tint): return true
	if not Legacy.SPELLS.has(spell) or not is_finite(phase) or phase < 0 or phase >= 1: return false
	var count := int(Legacy.SPELLS[spell])
	var file := Legacy.ROOT+spell+"/"+spell+"AllFrames.png"
	return Collection.draw_region(canvas,"magic",file,Rect2i(mini(count-1,int(phase*count))*24,0,24,24),point,Vector2(12,18),scale,tint)

static func _arrow(canvas: Object, center: Vector2, direction: Vector2, factor: float, empowered: bool = false) -> void:
	# Stair-stepped shaft, two feather vanes and a broadhead, not a line particle.
	var forward := direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	var normal := Vector2(-forward.y,forward.x)
	var shapes := [PackedVector2Array([Vector2(-9,-1),Vector2(5,-1),Vector2(5,1),Vector2(-9,1)]),PackedVector2Array([Vector2(4,-3),Vector2(8,-3),Vector2(8,-1),Vector2(11,-1),Vector2(11,1),Vector2(8,1),Vector2(8,3),Vector2(4,3)]),PackedVector2Array([Vector2(-9,-1),Vector2(-13,-4),Vector2(-9,-4),Vector2(-5,-1)]),PackedVector2Array([Vector2(-9,1),Vector2(-13,4),Vector2(-9,4),Vector2(-5,1)])]
	var colors := [Color("ac8554"),Color("fff0a7") if empowered else Color("dfe5c8"),Color("c1d7b3"),Color("6e8d74")]
	for index: int in range(shapes.size()):
		var polygon := PackedVector2Array()
		for cell: Vector2 in shapes[index]: polygon.append((center+(forward*cell.x+normal*cell.y)*factor).round())
		var ctx := {"canvas":canvas,"count":0,"draw_limit":8,"quantum":maxf(1.0,factor)}
		CellBrushR8.poly(ctx,Vector2.ZERO,Array(polygon),1.0,colors[index])

static func draw_projectile(canvas: Object, origin: Vector2, target: Vector2, phase: float, factor: float = 1.0, empowered: bool = false) -> bool:
	if not origin.is_finite() or not target.is_finite() or not is_finite(phase) or phase < 0 or phase >= 1 or not is_finite(factor) or factor <= 0: return false
	_arrow(canvas,origin.lerp(target,phase),(target-origin),factor,empowered)
	return true

static func _polygon(canvas: Object, cells: Array, center: Vector2, factor: float, tint: Color, angle: float = 0.0) -> void:
	var shape := PackedVector2Array()
	for cell: Vector2 in cells:
		var pixel := (center+cell.rotated(angle)*factor).round()
		if shape.is_empty() or pixel!=shape[-1]: shape.append(pixel)
	if shape.size()>1 and shape[0]==shape[-1]: shape.remove_at(shape.size()-1)
	if shape.is_empty(): return
	var area := 0.0
	if shape.size()>=3:
		for index: int in range(shape.size()): area+=shape[index].cross(shape[(index+1)%shape.size()])
	if shape.size()>=3 and absf(area)>=0.5:
		var ctx := {"canvas":canvas,"count":0,"draw_limit":8,"quantum":maxf(1.0,factor)}
		CellBrushR8.poly(ctx,Vector2.ZERO,Array(shape),1.0,tint)
		return
	# Whole-pixel quantization legitimately collapses a tiny ember or ice
	# glint at overview zoom. Preserve its visible one-pixel/line footprint,
	# not an invalid <3-point polygon or an artificially enlarged effect.
	var first := shape[0]
	var last := first
	var longest := 0.0
	for a: Vector2 in shape:
		for b: Vector2 in shape:
			if a.distance_squared_to(b)>longest: first=a; last=b; longest=a.distance_squared_to(b)
	if longest>0:
		var ctx := {"canvas":canvas,"count":0,"draw_limit":4,"quantum":1.0}
		CellBrushR8.streak(ctx,first,last,1.0,tint)
	else: canvas.draw_rect(Rect2(first,Vector2.ONE),tint)

static func _ribbon(canvas: Object, start: Vector2, end: Vector2, width: float, factor: float, tint: Color, zigzag: bool = false) -> void:
	var distance := start.distance_to(end)
	if distance<0.001: return
	var thickness := maxf(1.0,width*factor)
	if distance<maxf(2.0,factor):
		var center := end.round()
		canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-thickness,-1),center+Vector2(thickness,-1),center+Vector2(thickness,1),center+Vector2(-thickness,1)]),tint)
		return
	# Quantized stair steps, with one polygon per color instead of particle nodes.
	var normal := (end-start).normalized().orthogonal()
	var top: Array[Vector2] = []
	var bottom: Array[Vector2] = []
	# Short trails must not quantize seven samples onto the same pixel. Adapt the
	# sample count, retain a visible one-pixel core and keep progress monotonic.
	var steps := clampi(floori(distance/maxf(3.0*factor,2.0)),1,6)
	for index: int in range(steps+1):
		var progress := float(index)/float(steps)
		var bend := (1.0 if index%2 else -1.0)*4.0*factor if zigzag and index>0 and index<steps else 0.0
		var point := start.lerp(end,progress)+normal*bend
		var edge := normal*thickness
		var quantum := maxf(1.0,factor)
		top.append(((point+edge)/quantum).round()*quantum)
		bottom.push_front(((point-edge)/quantum).round()*quantum)
	var cells := PackedVector2Array(top)
	cells.append_array(PackedVector2Array(bottom))
	var ctx := {"canvas":canvas,"count":0,"draw_limit":8,"quantum":maxf(1.0,factor)}
	CellBrushR8.poly(ctx,Vector2.ZERO,Array(cells),1.0,tint)

static func _chips(canvas: Object, point: Vector2, phase: float, factor: float, colors: Array, count: int = 3) -> void:
	if phase<0.45 or phase>=0.96: return
	var travel := (phase-0.45)*21.0
	for index: int in range(mini(count,4)):
		var direction := Vector2([-1.0,0.5,1.0,-0.5][index],[-0.6,-1.0,-0.4,0.7][index])
		var center := point+direction*(5.0+travel)*factor
		var size := 1.5 if index%2 else 2.0
		_polygon(canvas,[Vector2(-size,-size),Vector2(size,-size),Vector2(size,size),Vector2(-size,size)],center,factor,Color(str(colors[2 if index%2 else 3])))

static func _motif(canvas: Object, point: Vector2, entry: Dictionary, factor: float) -> void:
	var phase := float(entry.phase)
	var colors: Array = entry.palette
	var drift := Vector2(0,-phase*12.0)*factor
	var effect := str(entry.effect)
	var tint := Color(str(colors[2]))
	if effect=="HEAL" or entry.action in ["HEAL","POTION"]:
		# An outlined blooming cross reads as recovery, not a damage explosion.
		_polygon(canvas,[Vector2(-4,-11),Vector2(4,-11),Vector2(4,-4),Vector2(11,-4),Vector2(11,4),Vector2(4,4),Vector2(4,11),Vector2(-4,11),Vector2(-4,4),Vector2(-11,4),Vector2(-11,-4),Vector2(-4,-4)],point+Vector2(0,-17)*factor+drift,factor*0.62,Color(str(colors[0])))
		_polygon(canvas,[Vector2(-2,-9),Vector2(2,-9),Vector2(2,-2),Vector2(9,-2),Vector2(9,2),Vector2(2,2),Vector2(2,9),Vector2(-2,9),Vector2(-2,2),Vector2(-9,2),Vector2(-9,-2),Vector2(-2,-2)],point+Vector2(0,-17)*factor+drift,factor*0.62,Color("c9e6a0"))
	elif effect in ["ARMOR_BUFF","PASSIVE_GUARD"]:
		_polygon(canvas,[Vector2(-11,-13),Vector2(11,-13),Vector2(11,1),Vector2(6,9),Vector2(0,13),Vector2(-6,9),Vector2(-11,1)],point+Vector2(0,-14)*factor,factor,Color(str(colors[0])))
		_polygon(canvas,[Vector2(-8,-10),Vector2(8,-10),Vector2(8,0),Vector2(4,6),Vector2(0,9),Vector2(-4,6),Vector2(-8,0)],point+Vector2(0,-14)*factor,factor,tint)
	elif effect in ["ROOT","STUN"]:
		var spike := [Vector2(-10,2),Vector2(-8,-5),Vector2(-5,-13),Vector2(-3,-5),Vector2(0,-9),Vector2(2,-3),Vector2(7,-15),Vector2(9,-5),Vector2(11,2)]
		_polygon(canvas,spike,point+Vector2(0,3)*factor,factor,Color(str(colors[0])))
		_polygon(canvas,[Vector2(-7,0),Vector2(-5,-8),Vector2(-3,0),Vector2(0,-4),Vector2(3,0),Vector2(7,-9),Vector2(8,0)],point,factor,tint)
	else:
		# A cut-corner rune, not a universal circle, supports each author sprite.
		var spread := 10.0+float(entry.rank)*2.0
		_polygon(canvas,[Vector2(-spread,-3),Vector2(-spread+5,-3),Vector2(-3,-spread),Vector2(3,-spread),Vector2(spread-5,-3),Vector2(spread,-3),Vector2(spread,3),Vector2(spread-5,3),Vector2(3,spread),Vector2(-3,spread),Vector2(-spread+5,3),Vector2(-spread,3)],point,factor,Color(str(colors[0])))
		_polygon(canvas,[Vector2(-spread+3,0),Vector2(0,-spread+3),Vector2(spread-3,0),Vector2(0,spread-3)],point,factor,Color(tint,0.72))
	if int(entry.intensity)==4:
		# Large effects gain three readable heraldic teeth, not oversized bloom.
		for index: int in range(3):
			var center := point+Vector2((index-1)*13,-29-abs(index-1)*3)*factor
			_polygon(canvas,[Vector2(-3,0),Vector2(0,-7),Vector2(3,0),Vector2(0,3)],center,factor,Color(str(colors[3])))

static func _accent(canvas: Object, origin: Vector2, impact: Vector2, entry: Dictionary, factor: float) -> void:
	var phase := float(entry.phase)
	var colors: Array = entry.palette
	var direction := (impact-origin).angle()
	var kind := str(entry.kind)
	if kind=="slash":
		if phase>=0.12 and phase<0.9:
			var strike := origin.lerp(impact,0.62)
			var size := 0.85+0.12*int(entry.rank)+0.08*(int(entry.intensity)-1)
			_polygon(canvas,[Vector2(-17,-15),Vector2(-5,-20),Vector2(8,-18),Vector2(20,-9),Vector2(25,2),Vector2(18,14),Vector2(10,18),Vector2(13,8),Vector2(11,-2),Vector2(4,-10),Vector2(-5,-13)],strike,factor*size,Color(str(colors[0])),direction)
			_polygon(canvas,[Vector2(-12,-14),Vector2(-3,-17),Vector2(7,-15),Vector2(17,-7),Vector2(21,2),Vector2(17,10),Vector2(14,12),Vector2(15,4),Vector2(10,-5),Vector2(3,-11)],strike,factor*size,Color(str(colors[3])),direction)
		_chips(canvas,impact,phase,factor,colors,2 if int(entry.intensity)==1 else 3)
	elif kind in ["arrow","piercing_arrow","gunshot","stone","magic_projectile","cannon","fire_projectile"]:
		var moving := origin.lerp(impact,minf(phase/0.7,1.0))
		if phase<0.7:
			var tail := origin.lerp(moving,maxf(0.0,1.0-(0.42 if kind in ["magic_projectile","fire_projectile"] else 0.22)))
			var weight := 1.0+0.12*(int(entry.intensity)-1)
			_ribbon(canvas,tail,moving,2.5*weight,factor,Color(str(colors[0])))
			_ribbon(canvas,tail,moving,1.0*weight,factor,Color(str(colors[2])))
		if kind in ["gunshot","cannon"] and phase<0.38:
			_polygon(canvas,[Vector2(0,-2),Vector2(7,-7),Vector2(6,-2),Vector2(16,0),Vector2(6,2),Vector2(7,7),Vector2(0,2)],origin,factor,Color("fff0a5"),direction)
		_chips(canvas,impact,phase,factor,colors)
	else:
		_motif(canvas,origin+Vector2(0,18)*factor if bool(entry.at_self) else impact,entry,factor*(0.8+0.08*int(entry.rank)))
		if str(entry.effect) not in ["HEAL","ARMOR_BUFF","PASSIVE_GUARD","DAMAGE_BUFF","AURA","RALLY"]:
			_chips(canvas,impact,phase,factor,colors)

static func draw_action(canvas: Object, point: Vector2, target: Vector2, unit: Dictionary, pose: Dictionary, factor: float = 1.0, impact_points: Array = []) -> bool:
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor <= 0: return false
	var troop_entry := _inspect_troop_v4(unit,pose)
	if bool(troop_entry.get("supported",false)): return _draw_troop_v4(canvas,point,target,troop_entry,factor,impact_points)
	if RosterV5.draw_sample(canvas,point,target,unit,pose,factor,impact_points):return true
	if WeaponArt.draw(canvas,point,target,unit,pose,factor,impact_points): return true
	if SkillArt.draw(canvas,point,target,unit,pose,factor,impact_points): return true
	if SupportArt.draw(canvas,point,target,unit,pose,factor,impact_points): return true
	var entry := inspect_action(unit,pose)
	if not bool(entry.get("supported",false)): return false
	var phase := float(entry.phase)
	var scale := (1.65+0.18*(int(entry.rank)-1)+0.10*(int(entry.intensity)-1))*factor
	var center := point if bool(entry.at_self) else target
	var origin := point+Vector2(0,-18)*factor
	var impact := target+Vector2(0,-10)*factor
	_accent(canvas,origin,impact,entry,factor)
	match str(entry.kind):
		"slash":
			var strike := origin.lerp(impact,0.62)
			if not _sprite(canvas,"FirstStrike",phase,strike,scale):
				# Missing extension: source-authored magic impact, still no rings.
				_sprite(canvas,"EnergyBlast",phase,strike,scale*0.65)
			if str(entry.action).begins_with("SKILL_"): _sprite(canvas,str(CASTS[entry.faction]),phase,impact,scale*0.7)
		"arrow", "piercing_arrow":
			draw_projectile(canvas,origin,impact,minf(phase/0.8,0.999),factor,entry.kind=="piercing_arrow")
			if phase >= 0.55: _sprite(canvas,"Shrapnel",(phase-0.55)/0.45,impact,scale*0.75)
		"rain":
			for index: int in range(3):
				var landing := impact+Vector2((index-1)*22,(index%2)*14)*factor
				draw_projectile(canvas,landing+Vector2(-22,-75)*factor,landing,minf(phase/0.8,0.999),factor,true)
				if phase >= 0.55: _sprite(canvas,"Shrapnel",(phase-0.55)/0.45,landing,scale*0.6)
		"gunshot", "stone":
			var moving := origin.lerp(impact,minf(phase/0.7,1))
			var cells := PackedVector2Array([Vector2(-4,-2),Vector2(1,-2),Vector2(4,0),Vector2(1,2),Vector2(-4,2),Vector2(-5,0)]) if entry.kind=="gunshot" else PackedVector2Array([Vector2(-5,-2),Vector2(-2,-5),Vector2(3,-4),Vector2(5,1),Vector2(1,4),Vector2(-4,3)])
			var polygon := PackedVector2Array()
			var direction := (impact-origin).angle() if entry.kind=="gunshot" else 0.0
			for cell: Vector2 in cells: polygon.append((moving+cell.rotated(direction)*factor).round())
			canvas.draw_colored_polygon(polygon,Color("e8cf8c") if entry.kind=="gunshot" else Color("b4b29a"))
			if phase>=0.5: _sprite(canvas,"Shrapnel",(phase-0.5)*2,impact,scale*0.75)
		"cannon":
			var moving := origin.lerp(impact,minf(phase/0.7,1))
			_polygon(canvas,[Vector2(-6,-3),Vector2(-3,-6),Vector2(3,-6),Vector2(6,-3),Vector2(6,3),Vector2(3,6),Vector2(-3,6),Vector2(-6,3)],moving,factor,Color("211f2b"))
			_polygon(canvas,[Vector2(-3,-3),Vector2(0,-4),Vector2(3,-2),Vector2(3,1),Vector2(0,2),Vector2(-3,0)],moving,factor,Color("929c94"))
			if phase>=0.5: _sprite(canvas,"Explosion",(phase-0.5)*2,impact,scale*0.85)
		"magic_projectile", "fire_projectile":
			var moving := origin.lerp(impact,minf(phase/0.7,1))
			_sprite(canvas,"MagicArrow" if entry.kind=="magic_projectile" else "FireBall",phase,moving,scale*0.75)
			if phase >= 0.5: _sprite(canvas,str(entry.spell) if entry.kind=="magic_projectile" else "Explosion",(phase-0.5)*2,impact,scale*0.85)
		_:
			var drawn := _sprite(canvas,str(entry.spell),phase,center,scale)
			if not drawn: Legacy.draw(canvas,point,target,unit,pose,factor)
	# Applied to weapon lines as well as spells; never infer unobserved victims.
	if entry.delivery in ["CHAIN","LINE"]:
		var previous := origin
		for value: Variant in impact_points.slice(0,MAX_IMPACTS):
			if value is Vector2 and value.is_finite():
				var settled: Vector2 = value+Vector2(0,-8)*factor
				if phase>=0.18 and phase<0.9:
					_ribbon(canvas,previous,settled,3.0,factor,Color(str(entry.palette[0])),entry.delivery=="CHAIN")
					_ribbon(canvas,previous,settled,1.1,factor,Color(str(entry.palette[3])),entry.delivery=="CHAIN")
				_sprite(canvas,"LightningBolt" if entry.delivery=="CHAIN" else "Shrapnel" if entry.kind in ["arrow","piercing_arrow","gunshot","cannon","stone"] else str(entry.spell),phase,settled,scale*0.72)
				previous=settled
	return true

static func draw_hit(canvas: Object, point: Vector2, unit: Dictionary, injury: Dictionary, factor: float = 1.0) -> bool:
	var phase := float(injury.get("phase",-1))
	if injury.is_empty() or int(injury.get("amount",0)) <= 0 or not point.is_finite() or not is_finite(phase) or phase < 0 or phase >= 1 or not is_finite(factor) or factor <= 0: return false
	var type := str(unit.get("last_damage_attack_type","EDGE"))
	var spell := str(IMPACTS.get(str(unit.get("last_damage_source_faction","")),"EnergyBlast")) if type in ["ARCANE","CHAOS"] else "Explosion" if type=="GUNPOWDER" else "Shrapnel"
	# Hit confirmation is smaller than the originating cast and persistent control.
	# In particular, ordinary arcane damage must not resemble universal freezing.
	var scale := 0.85 if type in ["ARCANE","CHAOS"] else 1.3 if type=="GUNPOWDER" else 1.1
	var colors: Array = PALETTES.get(str(unit.get("last_damage_source_faction","HUMAN")),PALETTES.HUMAN)
	_chips(canvas,point,phase,factor*0.65,colors,2)
	if not _sprite(canvas,spell,phase,point,scale*factor): return _sprite(canvas,"EnergyBlast",phase,point,factor*0.7)
	return true

static func inspect_status(unit: Dictionary, status: Dictionary, tick: int) -> Dictionary:
	if not _alive(unit) or int(status.get("remaining_ticks",0)) <= 0 or tick < 0: return {"supported":false}
	var kind := str(status.get("effect",status.get("kind","")))
	var faction := str(status.get("source_faction",_faction(unit)))
	var spell := ""
	match kind:
		"STUN": spell = "Contusion"
		"ROOT": spell = str(ROOTS.get(faction,"IceSpikes"))
		"SLOW": spell = "IceSpikes"
		"BURN": spell = "FireBall"
		"POISON": spell = "AcidSplash"
		"ARMOR_BREAK": spell = "Shrapnel"
		"HEAL": spell = "Cure"
		"FERVOR": spell = "Bloodlust"
		"GUARD": spell = "Shield"
		"AURA": spell = "Bless"
		_: return {"supported":false}
	return {"supported":true,"spell":spell,"kind":kind,"head":kind in ["STUN","POISON","ARMOR_BREAK"],"phase":float(posmod(tick,12))/12.0,"faction":faction,"profile":"status_"+kind.to_lower(),"layers":["persistent_author_sprite","control_signature" if kind in ["STUN","ROOT","SLOW"] else "benefit_motes" if kind in ["HEAL","FERVOR","GUARD","AURA"] else "affliction_chips"],"palette":PALETTES.get(faction,PALETTES.HUMAN).duplicate(),"settled_only":true}

static func _status_signature(canvas: Object, foot: Vector2, head: Vector2, entry: Dictionary, factor: float) -> void:
	var phase := float(entry.phase)
	var kind := str(entry.kind)
	var colors: Array = entry.palette
	if kind=="STUN":
		for index: int in range(2):
			var angle := phase*TAU+float(index)*PI
			var position := head+Vector2(cos(angle)*11.0,sin(angle)*3.5-1.0)*factor
			_polygon(canvas,[Vector2(-4,0),Vector2(-1,-1),Vector2(0,-4),Vector2(1,-1),Vector2(4,0),Vector2(1,1),Vector2(0,4),Vector2(-1,1)],position,factor,Color("fff0a5"))
	elif kind in ["ROOT","SLOW"]:
		for index: int in range(2):
			var position := foot+Vector2((index*2-1)*9,1)*factor
			_polygon(canvas,[Vector2(-3,0),Vector2(-3,-5),Vector2(0,-11),Vector2(3,-5),Vector2(3,0)],position,factor,Color(str(colors[0])))
			_polygon(canvas,[Vector2(-1,0),Vector2(-1,-5),Vector2(0,-8),Vector2(1,-5),Vector2(1,0)],position,factor,Color(str(colors[2])))
	elif kind=="POISON":
		var position := head+Vector2(9,-5-phase*7)*factor
		_polygon(canvas,[Vector2(0,-5),Vector2(3,0),Vector2(3,3),Vector2(0,5),Vector2(-3,3),Vector2(-3,0)],position,factor,Color("9fcb69"))
	elif kind=="ARMOR_BREAK":
		_polygon(canvas,[Vector2(-3,-8),Vector2(4,-8),Vector2(0,-2),Vector2(4,-2),Vector2(-4,8),Vector2(-1,1),Vector2(-5,1)],head+Vector2(9,0)*factor,factor,Color("ffc07b"))
	elif kind=="BURN":
		for index: int in range(2):
			var rise := fposmod(phase+index*0.5,1.0)
			_polygon(canvas,[Vector2(-1,-2),Vector2(1,-2),Vector2(1,2),Vector2(-1,2)],foot+Vector2((index*2-1)*8,-7-rise*20)*factor,factor,Color("ffcd79"))
	else:
		for index: int in range(2):
			var rise := fposmod(phase+index*0.5,1.0)
			var position := foot+Vector2((index*2-1)*9,-6-rise*21)*factor
			_polygon(canvas,[Vector2(-2,0),Vector2(0,-3),Vector2(2,0),Vector2(0,3)],position,factor,Color(Color(str(colors[3])),0.68 if kind in ["GUARD","AURA"] else 0.9))

static func draw_status(canvas: Object, foot: Vector2, head: Vector2, unit: Dictionary, status: Dictionary, tick: int, factor: float = 1.0) -> bool:
	if not foot.is_finite() or not head.is_finite() or not is_finite(factor) or factor <= 0: return false
	if _draw_troop_status_v4(canvas,foot,head,unit,status,tick,factor): return true
	if ReworkR7.Catalog.has_skill(str(status.get("skill_id",""))): return ReworkR7.draw_status(canvas,foot,head,unit,status,tick,factor)
	var entry := inspect_status(unit,status,tick)
	if not bool(entry.get("supported",false)): return false
	var position := head+Vector2(0,6)*factor if entry.head else foot+Vector2(0,2)*factor
	# Persistent burning uses the small ember/flame ending of the author strip;
	# the tall FlameStrike column is reserved for the moment of a major cast.
	var phase := 0.667+float(entry.phase)*0.32 if entry.kind=="BURN" else float(entry.phase)
	var scale := 1.05 if entry.head or entry.kind=="BURN" else 1.5
	_status_signature(canvas,foot,head,entry,factor)
	var tint := Color(1,1,1,0.58) if entry.kind in ["AURA","GUARD"] else Color.WHITE
	if _sprite(canvas,str(entry.spell),phase,position,scale*factor,tint): return true
	return _sprite(canvas,"Contusion" if entry.kind=="STUN" else "FrostRing",float(entry.phase),position,factor)

static func _troop_by_skill_v4(id: String) -> Dictionary:
	for recipe: Dictionary in TroopV4.CATALOG.values():
		if recipe.id==id: return recipe.duplicate(true)
	for recipe: Dictionary in TroopV4.BASIC_PROCS.values():
		if recipe.id==id: return recipe.duplicate(true)
	return {}

static func _inspect_troop_v4(unit: Dictionary, pose: Dictionary) -> Dictionary:
	var action := str(pose.get("action","IDLE"));var phase := float(pose.get("phase",0))
	if not _alive(unit) or bool(unit.get("neutral",false)) or not is_finite(phase) or phase<0 or phase>=1: return {"supported":false}
	var skill := TroopV4.ability_for(str(unit.get("unit_type","")))
	if str(unit.get("unit_type",""))=="deep_fault_carapace" and action=="ATTACK": skill=TroopV4.proc_for("deep_fault_carapace")
	elif skill.is_empty() or action!="SKILL_"+str(skill.id): return {"supported":false}
	var id := str(skill.id)
	if not TROOP_V4_PALETTES.has(id): return {"supported":false}
	return {"supported":true,"kind":"v4_troop","skill_id":id,"skill":skill,"profile":"outposts_v4_"+id.to_lower(),"phase":phase,"action":action,"effect":str(skill.get("effect","DAMAGE")),"delivery":str(skill.get("delivery","SINGLE")),"at_self":skill.get("delivery","")=="SELF_BUFF","rank":1,"intensity":3 if int(unit.get("population",0))>=6 else 2,"faction":_faction(unit),"palette":TROOP_V4_PALETTES[id].duplicate(),"layers":["authored_body_cast","material_link","actual_settled_targets"],"max_impacts":mini(MAX_IMPACTS,int(skill.get("max_targets",1))),"max_draw_operations":64,"settled_only":true,"ultimate":false,"original_art":true}

static func _v4_points(target: Vector2, entry: Dictionary, values: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for value: Variant in values:
		if result.size()>=int(entry.max_impacts): break
		if value is Vector2 and value.is_finite(): result.append(value)
	if result.is_empty(): result.append(target)
	return result

static func _page_v4(canvas: Object, point: Vector2, factor: float, colors: Array, phase: float) -> void:
	var width := 9.0+sin(phase*PI)*4.0
	_polygon(canvas,[Vector2(-width,-15),Vector2(0,-19),Vector2(width,-13),Vector2(width,6),Vector2(0,12),Vector2(-width,5)],point,factor,Color(str(colors[0])))
	_polygon(canvas,[Vector2(-width+3,-12),Vector2(0,-15),Vector2(width-3,-10),Vector2(width-3,3),Vector2(0,8),Vector2(-width+3,2)],point,factor,Color(Color(str(colors[2])),0.86))
	_ribbon(canvas,point+Vector2(0,-13)*factor,point+Vector2(0,7)*factor,0.8,factor,Color(str(colors[3])))

static func _feathers_v4(canvas: Object, center: Vector2, phase: float, factor: float, colors: Array) -> void:
	for index: int in range(4):
		var angle := phase*TAU+float(index)*TAU/4.0
		var p := center+Vector2(cos(angle)*19,sin(angle)*7-12)*factor
		_polygon(canvas,[Vector2(-3,6),Vector2(-4,-3),Vector2(1,-10),Vector2(5,-4),Vector2(1,4)],p,factor,Color(str(colors[0])),angle*0.3)
		_polygon(canvas,[Vector2(-1,4),Vector2(-1,-3),Vector2(1,-7),Vector2(2,-3)],p,factor,Color(str(colors[2])),angle*0.3)

static func _draw_troop_v4(canvas: Object, point: Vector2, target: Vector2, entry: Dictionary, factor: float, impact_points: Array) -> bool:
	var id := str(entry.skill_id);var phase := float(entry.phase);var colors: Array = entry.palette
	var skill: Dictionary = entry.skill;var origin := point+Vector2(0,-23)*factor
	var points := _v4_points(target,entry,impact_points)
	var scale := factor*1.25
	match id:
		"DENY_FORD_SEAL":
			var impact := points[0]+Vector2(0,-12)*factor
			if phase<0.48:
				var travel := origin.lerp(impact,phase/0.48)
				_page_v4(canvas,travel,scale*0.55,colors,phase)
				_ribbon(canvas,origin.lerp(travel,0.5),travel,1.2,factor,Color(str(colors[2])))
			else:
				_page_v4(canvas,impact,scale,colors,phase)
				_sprite(canvas,"HolyLight",(phase-0.48)/0.52,points[0],factor*1.3,Color("edcf9a"))
		"SEAL_PAGE_VEIL":
			for p: Vector2 in points:
				var center := p+Vector2(0,-19)*factor
				if phase<0.65: _ribbon(canvas,origin,center,1.0,factor,Color(Color(str(colors[2])),0.65))
				_page_v4(canvas,center,scale,colors,phase)
				_sprite(canvas,"Shield",phase,p,factor,Color(0.86,1.0,0.9,0.7))
		"LONELY_NAME_EMBER_CHAIN","PHASE_DISCHARGE":
			var previous := origin
			for p: Vector2 in points:
				var impact := p+Vector2(0,-14)*factor
				_ribbon(canvas,previous,impact,3.0,factor,Color(str(colors[0])),id=="PHASE_DISCHARGE")
				_ribbon(canvas,previous,impact,1.0,factor,Color(str(colors[2])),id=="PHASE_DISCHARGE")
				if id=="PHASE_DISCHARGE": _sprite(canvas,"LightningBolt",phase,impact,factor*1.1)
				else:
					_page_v4(canvas,impact,scale*0.5,colors,phase)
					_sprite(canvas,"DeathRipple",phase,p,factor*1.2,Color(0.82,0.94,0.83,0.8))
				previous=impact
		"DORMANT_BUD_PATH":
			for p: Vector2 in points:
				var spike := [Vector2(-13,2),Vector2(-11,-6),Vector2(-5,-2),Vector2(-2,-18),Vector2(2,-4),Vector2(8,-12),Vector2(12,3)]
				_polygon(canvas,spike,p,scale,Color(str(colors[0])))
				_polygon(canvas,[Vector2(-9,0),Vector2(-7,-6),Vector2(-3,0),Vector2(0,-12),Vector2(3,0),Vector2(8,-5),Vector2(9,0)],p,scale,Color(str(colors[2])))
				_sprite(canvas,"StoneSpikes",phase,p,factor*1.2,Color(0.72,1.0,0.78,0.9))
				_chips(canvas,p,phase,factor,colors,3)
		"SWIFT_WING_RETURN":
			_feathers_v4(canvas,point,phase,factor*1.2,colors)
			_sprite(canvas,"Bless",phase,point,factor*1.3,Color(0.8,1.0,0.81,0.75))
		"KILN_BACK_FERVOR":
			for index: int in range(3):
				var p := point+Vector2((index-1)*12,-5-phase*11)*factor
				_polygon(canvas,[Vector2(-6,3),Vector2(-5,-7),Vector2(-1,-17),Vector2(1,-7),Vector2(4,-12),Vector2(6,2)],p,factor,Color(str(colors[0])))
				_polygon(canvas,[Vector2(-3,0),Vector2(-1,-11),Vector2(1,-3),Vector2(3,0)],p,factor,Color(str(colors[2])))
			_sprite(canvas,"Bloodlust",phase,point,factor*1.3,Color("eab47d"))
		"FROST_KILN_EMBER":
			var impact := points[0]+Vector2(0,-12)*factor
			var travel := origin.lerp(impact,minf(1.0,phase/0.5))
			_sprite(canvas,"FireBall",phase,travel,factor,Color("dfd8e5"))
			if phase>=0.42:
				_sprite(canvas,"IceSpikes",(phase-0.42)/0.58,points[0],factor*1.1,Color("c1dedc"))
				_sprite(canvas,"FlameStrike",(phase-0.42)/0.58,points[0],factor*1.05,Color("f5c598"))
		"THREEFOLD_COLLAPSE_NOTE","FAULT_PIERCING_RIDGE":
			var direction := (target-point).normalized()
			if direction.length_squared()<0.1: direction=Vector2.RIGHT
			var finish := point+direction*float(skill.range)*factor
			var advance := point.lerp(finish,minf(1.0,phase/0.6))
			_ribbon(canvas,point+Vector2(0,-5)*factor,advance+Vector2(0,-5)*factor,4.5 if id=="FAULT_PIERCING_RIDGE" else 2.5,factor,Color(str(colors[0])))
			_ribbon(canvas,point+Vector2(0,-5)*factor,advance+Vector2(0,-5)*factor,1.2,factor,Color(str(colors[2])))
			for index: int in range(3):
				var position := point.lerp(advance,float(index+1)/3.0)
				_polygon(canvas,[Vector2(-4,4),Vector2(-1,-7),Vector2(2,-3),Vector2(5,4)],position,factor,Color(str(colors[3])),direction.angle())
			for p: Vector2 in points:
				_sprite(canvas,"StoneSpikes" if id=="FAULT_PIERCING_RIDGE" else "EnergyBlast",phase,p,factor*1.2,Color("c6b7d0"))
				_chips(canvas,p,phase,factor,colors,2)
		_: return false
	return true

static func _draw_troop_status_v4(canvas: Object, foot: Vector2, head: Vector2, unit: Dictionary, status: Dictionary, tick: int, factor: float) -> bool:
	if not _alive(unit) or int(status.get("remaining_ticks",0))<=0: return false
	var id := str(status.get("skill_id",status.get("id","")))
	if not TROOP_V4_PALETTES.has(id): return false
	var colors: Array = TROOP_V4_PALETTES[id];var phase := float(posmod(tick,24))/24.0
	match id:
		"SEAL_PAGE_VEIL":
			_page_v4(canvas,foot+Vector2(14,-18)*factor,factor*0.65,colors,phase)
			_page_v4(canvas,foot+Vector2(-12,-11)*factor,factor*0.35,colors,fposmod(phase+0.4,1.0))
		"NAME_ASH_VIGIL_R4":
			for index:int in range(3):
				var ember:=foot+Vector2((index-1)*13,-4-fposmod(phase+index*0.3,1.0)*10)*factor
				_polygon(canvas,[Vector2(-4,2),Vector2(-5,-4),Vector2(-1,-10),Vector2(1,-4),Vector2(4,-5),Vector2(4,2)],ember,factor*0.7,Color(str(colors[0])))
				_polygon(canvas,[Vector2(-2,0),Vector2(0,-7),Vector2(2,0)],ember,factor*0.7,Color(str(colors[2])))
		"RUNE_EARTHBREAK_R4":
			_sprite(canvas,"StoneSpikes",phase,foot,factor*0.9,Color("e0c49e"))
			_chips(canvas,head+Vector2(0,5)*factor,phase,factor,colors,3)
		"DEEP_SHARED_VAULT_R4":
			var extent:=21.0 if bool(status.get("elite_source",false)) else 12.0
			for side:int in [-1,1]:
				var p:=foot+Vector2(side*extent,-6)*factor
				_polygon(canvas,[Vector2(-5,4),Vector2(-5,-7),Vector2(0,-11),Vector2(5,-7),Vector2(5,4)],p,factor*0.7,Color(str(colors[0])))
				_polygon(canvas,[Vector2(-3,1),Vector2(-3,-6),Vector2(0,-8),Vector2(3,-6),Vector2(3,1)],p,factor*0.7,Color(str(colors[2])))
		"SWIFT_WING_RETURN": _feathers_v4(canvas,foot,phase,factor*0.85,colors)
		"KILN_BACK_FERVOR":
			_sprite(canvas,"FireBall",0.667+phase*0.32,foot+Vector2(-11,-5)*factor,factor,Color("edc18c"))
			_sprite(canvas,"FireBall",0.667+fposmod(phase+0.5,1.0)*0.32,foot+Vector2(10,-8)*factor,factor*0.8,Color("e1a366"))
		"DENY_FORD_SEAL": _page_v4(canvas,head+Vector2(8,10)*factor,factor*0.45,colors,phase)
		"DORMANT_BUD_PATH":
			_sprite(canvas,"StoneSpikes",phase,foot,factor,Color(0.72,1.0,0.78,0.85))
		"LONELY_NAME_EMBER_CHAIN":
			_sprite(canvas,"DeathRipple",phase,foot,factor*0.7,Color(0.82,0.94,0.83,0.72))
		"FROST_KILN_EMBER":
			_sprite(canvas,"FireBall",0.667+phase*0.32,foot,factor*0.9,Color("e0c3c2"))
		_: return false
	return true

static func debug_stats() -> Dictionary:
	return {"version":"heroic-pixel-combat-m54","optional_atlas":Atlas.debug_stats(),"max_visible_actions":MAX_ACTIONS,"max_settled_impacts_per_cast":MAX_IMPACTS,"max_cast_draw_commands":48,"effect_nodes":0,"timers":0,"owner_atlas_copies":0,"phase_source":"observed_action_hit_or_active_status","original_art":["feathered_pixel_arrow","outlined_weapon_crescent","quantized_projectile_ribbon","muzzle_star","impact_chips","recovery_cross","guard_crest","settled_chain_arc","control_spikes","ultimate_heraldry","status_motes"],"licensed_art":"existing Magic Book plus ten optional unchanged strips"}
