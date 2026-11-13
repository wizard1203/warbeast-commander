extends RefCounted
## M55: original, deterministic pixel choreography for every learned hero active.
## This module is an observation-only renderer, never a hit/range authority.
## Cast ornaments may exceed a body silhouette; hit connectors only use supplied
## settled impact_points. No proximity search, random state, nodes or simulation.
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Identity = preload("res://src/presentation/heroic_spell_identity.gd")
const Materials = preload("res://src/presentation/heroic_spell_materials.gd")
const Weapons = preload("res://src/presentation/heroic_weapon_choreography.gd")
const FactionAV = preload("res://src/presentation/heroic_faction_av.gd")
const ExpansionAV=preload("res://src/presentation/heroic_expansion_av_m66.gd")
const MageAV=preload("res://src/presentation/heroic_mage_effects_m68.gd")
const RangedAV=preload("res://src/presentation/heroic_ranged_roles_m68.gd")
const VERSION := "m63-authored-faction-gesture-feedback-v1"
const MAX_DRAW_OPERATIONS := 160
const MAX_SETTLED_IMPACTS := 6
class MaterialWash extends RefCounted:
	var target:Object
	func draw_colored_polygon(points:PackedVector2Array,color:Color)->void:
		target.draw_colored_polygon(points,Color(color,color.a*0.28))
const PALETTES := {
	"HUMAN":["201d2c","685841","c28b45","efc76e","fff1c3"],
	"UNDEAD":["21192b","51364b","a85569","da9294","ffe0bf"],
	"MACHINE":["172632","345566","5098ad","89d9e5","f5f5ce"],
	"FOREST":["172b27","345d41","6a9f56","b8dd82","f5eec2"],
	"HIGHLAND":["2b1d28","713b39","cc6741","ffa95a","fff2b2"],
	"UNDERGROUND":["231b30","533c76","9675b7","d1b3e6","fff0c9"],
}
# Per-ID selection is deliberate: an effect enum does not identify a spell.
# Each of the twelve roles has a different six-faction construction below.
const KITS := {
	"RECOVER":["mend","oath_stitch"],"RALLY":["sanctuary","six_town_standard"],
	"SHIELD_SHOCK":["tank_restore","shield_heart"],"BULWARK_RECOVER":["tank_control","falling_bastion"],
	"STARFIRE":["bolt","star_comet"],"FROST_BIND":["bind","frost_contract"],"ARCANE_BURST":["cataclysm","focused_astral_execution"],
	"PIERCING_SHOT":["shot","lance_arrow"],"ARROW_RAIN":["rain","feather_rain"],"QUICKDRAW":["hunt","six_wing_draw"],
	"WHIRLWIND":["lock","blade_verdict"],"BLOOD_PACT":["prison","crossed_oathblades"],
	"ASH_STITCH":["mend","memory_suture"],"ASH_REQUIEM":["sanctuary","returning_lanterns"],
	"ASH_SHOCK":["tank_restore","rib_rekindling"],"ASH_MEND":["tank_control","ossuary_throne"],
	"MOURN_BIND":["bind","mourning_chains"],"MOURN_FLARE":["bolt","ashen_soulflare"],"MOURN_OATH":["cataclysm","focused_soul_extraction"],
	"CINDER_SHOT":["shot","charred_bone_arrow"],"CINDER_FERVOR":["fervor","cinder_quiver"],"CINDER_MEND":["rain","focused_bone_pin"],
	"GRAVE_CHAIN":["lock","grave_hook"],"GRAVE_TOLL":["prison","silent_bell"],
	"COIL_MEND":["mend","repair_satellites"],"COIL_OVERHAUL":["sanctuary","overhaul_dock"],
	"COIL_SHOCK":["tank_restore","pressure_reboot"],"COIL_REPAIR":["tank_control","electromagnet_gate"],
	"VOLT_BIND":["bind","tesla_cage"],"VOLT_ARC":["bolt","forked_discharge"],"VOLT_NETWORK":["cataclysm","storm_switchyard"],
	"GEAR_SHOT":["shot","fragment_shell"],"GEAR_FERVOR":["fervor","rotor_overclock"],"GEAR_REPAIR":["rain","focused_missile_lock"],
	"SIGNAL_LOCK":["lock","circuit_cut"],"SIGNAL_BLACKOUT":["prison","blackout_array"],
	"BLOOM_TOUCH":["mend","opening_waterlily"],"BLOOM_SANCTUARY":["sanctuary","everbloom_arbor"],
	"VINE_SHOCK":["tank_restore","rootheart_sap"],"VINE_MEND":["tank_control","ancient_root_crown"],
	"LEAF_BIND":["bind","woven_root_fingers"],"LEAF_FLARE":["bolt","leaflight_fan"],"LEAF_OATH":["cataclysm","focused_root_prison"],
	"WIND_SHOT":["shot","split_wind_arrow"],"WIND_FERVOR":["fervor","swiftleaf_wings"],"WIND_MEND":["hunt","wild_hunt_canopy"],
	"THORN_LASH":["lock","thorn_whip"],"THORN_MAZE":["prison","thorn_labyrinth"],
	"HEARTH_MEND":["mend","hearth_embers"],"HEARTH_REFUGE":["sanctuary","undying_campfire"],
	"RIDGE_SHOCK":["tank_restore","forgeblood_temper"],"RIDGE_MEND":["tank_control","avalanche_command"],
	"RUNE_BIND":["bind","furnace_runelock"],"RUNE_FLARE":["bolt","forge_eruption"],"RUNE_OATH":["cataclysm","deepforge_caldera"],
	"EMBER_SEAL":["shot","ember_execution"],"EMBER_SWEEP":["fervor","molten_sweep"],"EMBER_MEND":["hunt","focused_molten_verdict"],
	"STORM_HAMMER":["lock","thunderhammer_drop"],"STORM_VERDICT":["prison","summit_judgement"],
	"SPORE_REMEDY":["mend","mending_sporecaps"],"SPORE_HAVEN":["sanctuary","mycelium_haven"],
	"TUNNEL_SHOCK":["tank_restore","shell_regrowth"],"TUNNEL_MEND":["tank_control","burrow_jaw"],
	"ECHO_BIND":["bind","crystal_resonance"],"ECHO_FLARE":["bolt","sonic_drill"],"ECHO_OATH":["cataclysm","focused_crystal_implosion"],
	"SPORE_SEAL":["shot","rift_stinger"],"SPORE_SWEEP":["fervor","crescent_mantis"],"SPORE_MEND":["hunt","rift_hunt"],
	"QUAKE_SNARE":["lock","fault_clamp"],"QUAKE_SEAL":["prison","tectonic_seal"],
}

static func inspect(unit: Dictionary, pose: Dictionary) -> Dictionary:
	if RangedAV.supported(unit):return RangedAV.inspect_skill(unit,pose)
	if MageAV.Data.has_hero(str(unit.get("hero_archetype",""))):return MageAV.inspect_skill(unit,pose)
	if ExpansionAV.Data.has_hero(str(unit.get("hero_archetype",""))):return ExpansionAV.inspect_skill(unit,pose)
	var action := str(pose.get("action",""))
	var phase := float(pose.get("phase",-1))
	if not action.begins_with("SKILL_") or int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not is_finite(phase) or phase<0 or phase>=1: return {"supported":false}
	var id := action.trim_prefix("SKILL_")
	var skill: Dictionary = pose.get("skill",{})
	var hero := str(unit.get("hero_archetype",""))
	if id not in KITS or skill.is_empty() or bool(skill.get("passive",false)) or int(skill.get("level",0))<1 or id not in Heroes.PROFILES.get(hero,{}).get("skill_ids",[]): return {"supported":false}
	var canonical := Heroes.skill_at_level(id,int(skill.level))
	if canonical.is_empty() or bool(canonical.get("passive",false)): return {"supported":false}
	var faction := str(canonical.source_faction)
	var identity := Identity.profile(id,hero)
	if identity.is_empty(): return {"supported":false}
	var family := str(KITS[id][0])
	var ultimate := bool(canonical.ultimate)
	var rank := int(skill.level)
	var target_shape := _target_shape(canonical)
	var extent := Vector2(154,142) if ultimate else Vector2(98,102)
	if target_shape=="single": extent=Vector2(116,158) if ultimate else Vector2(98,102)
	elif target_shape in ["line","chain","cone"]: extent=Vector2(292,180)
	elif family in ["cataclysm","prison","tank_control","sanctuary"]: extent=Vector2(244,216) if ultimate else extent
	elif family in ["shot","bolt","rain"]: extent.x=280 if ultimate else 210
	var layers := ["name_specific_structure","dark_pixel_silhouette","colored_body","luminous_core","authored_rear_material","bounded_material_particles"]
	if ultimate: layers.append("ultimate_secondary_structure"); layers.append("expanding_light_shards")
	if str(canonical.delivery) in ["CHAIN","LINE"]: layers.append("settled_"+str(canonical.delivery).to_lower())
	layers.append("contrasting_material"); layers.append("identity_rhythm")
	var result:={"supported":true,"id":id,"signature":KITS[id][1],"profile":faction.to_lower()+"_"+hero.to_lower()+"_"+str(KITS[id][1]),"family":family,"motif":KITS[id][1],"layers":layers,"visual_extent":extent*(1.0+0.08*(rank-1)),"particle_cap":24 if ultimate else 12,"max_draw_operations":MAX_DRAW_OPERATIONS,"ultimate":ultimate,"rank":rank,"phase":phase,"at_self":canonical.target_mode=="SELF","delivery":canonical.delivery,"target_shape":target_shape,"effect":canonical.effect,"faction":faction,"settled_only":true,"palette":identity.palette,"palette_story":identity.story,"palette_roles":identity.roles,"choreography":identity.choreography,"emblem":identity.emblem,"rhythm":identity.rhythm,"authoritative_radius":canonical.get("radius",0),"cone_width":canonical.get("cone_width",0),"line_width":canonical.get("line_width",0),"visual_extent_is_hit_range":false}
	var material: Dictionary=identity.get("material",{})
	result.merge({"material_mode":str(material.get("mode","")),"material_choreography":str(material.get("choreography","")),"material_particle_motion":str(material.get("particle_motion","")),"material_motion_dialect":str(material.get("motion_dialect","")),"material_signature":str(material.get("signature","")),"visual_brief":str(material.get("visual_brief","")),"narrative_prompt":str(material.get("prompt","")),"material_description":str(material.get("description","")),"material_version":Materials.VERSION,"material_particle_cap":Materials.MAX_PARTICLES,"material_layers":material.get("layers",[]).duplicate()},true)
	var weapon:=Weapons.profile(id)
	result.merge({"weapon_family":str(weapon.get("weapon_family","")),"weapon_motif":str(weapon.get("motif","")),"weapon_motion":str(weapon.get("motion","")),"weapon_phase_signature":str(weapon.get("phase_signature","")),"weapon_identity_version":str(weapon.get("identity_version",""))})
	result.layers.append("authored_weapon_silhouette")
	var authored:=FactionAV.skill_profile(id)
	if not authored.is_empty():
		result["m63_gesture"]=str(authored.get("gesture",""))
		result["m63_presentation_version"]=FactionAV.VERSION
		result["legacy_weapon_reference"]=result.weapon_family
		result["weapon_family"]=str(authored.get("gesture",""))
		result["weapon_motif"]=str(authored.get("gesture",""))
		result["weapon_motion"]=" / ".join(PackedStringArray(authored.get("phases",[])))
		result["weapon_phase_signature"]=result.weapon_motion
		result["weapon_identity_version"]=FactionAV.VERSION
		result["layers"]=["coarse_pixel_outline","body_local_anticipation","authored_delivery","truthful_primary_feedback","authored_recovery","muted_material_atmosphere"]
	return result

static func _target_shape(skill: Dictionary) -> String:
	if str(skill.get("target_mode",""))=="SELF": return "self"
	if str(skill.get("delivery","AREA"))=="SINGLE" or int(skill.get("max_targets",1))==1: return "single"
	return str(skill.get("delivery","AREA")).to_lower()

static func draw(canvas: Object, point: Vector2, target: Vector2, unit: Dictionary, pose: Dictionary, factor: float=1.0, impact_points: Array=[]) -> bool:
	if RangedAV.supported(unit):return RangedAV.draw_native(canvas,point,target,unit,pose,factor,impact_points)
	if MageAV.Data.has_hero(str(unit.get("hero_archetype",""))):return MageAV.draw_native(canvas,point,target,unit,pose,factor,impact_points)
	if ExpansionAV.Data.has_hero(str(unit.get("hero_archetype",""))):return ExpansionAV.draw_skill(canvas,point,target,unit,pose,factor,impact_points)
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0: return false
	var entry := inspect(unit,pose)
	if not bool(entry.get("supported",false)): return false
	# Eighteen operations are reserved for six actual settled connectors. A
	# visually elaborate material can never consume their hit-feedback budget.
	var ctx := {"canvas":canvas,"count":0,"draw_limit":MAX_DRAW_OPERATIONS-MAX_SETTLED_IMPACTS*3,"factor":factor,"palette":entry.palette,"phase":Identity.phase_for(float(entry.phase),str(entry.rhythm)),"rank":entry.rank,"ultimate":entry.ultimate,"faction":entry.faction,"seed":KITS.keys().find(entry.id),"quantum":maxf(1.0,factor)}
	var center := point if bool(entry.at_self) else target
	# SINGLE clicks acquire a legal victim inside a small snap radius. The
	# command's empty-ground aim is not necessarily that victim's position.
	# Only an explicitly published settled point may replace the cast center;
	# do not search nearby actors or infer a victim from geometry.
	if str(entry.delivery)=="SINGLE" and not bool(entry.at_self):
		for value: Variant in impact_points.slice(0,MAX_SETTLED_IMPACTS):
			if value is Vector2 and value.is_finite(): center=value; break
	var origin := point+Vector2(0,-21)*factor
	center+=Vector2(0,-8)*factor
	var phase := float(entry.phase)
	var scale := factor*(1.0+0.08*(int(entry.rank)-1))
	var authored:=not FactionAV.skill_profile(str(entry.id)).is_empty()
	if authored:
		# Independent native review found old family props dominated the new
		# hand gestures (including a ROOT drawn as a huge blade fence). Keep
		# sparse, low-opacity material atmosphere, not both full main effects.
		var wash:=MaterialWash.new();wash.target=canvas
		ctx.canvas=wash;ctx.draw_limit=mini(10,MAX_DRAW_OPERATIONS-MAX_SETTLED_IMPACTS*3)
		Materials.draw_behind(ctx,origin,center,scale*.85,entry)
		ctx.canvas=canvas;ctx.draw_limit=MAX_DRAW_OPERATIONS-MAX_SETTLED_IMPACTS*3
		FactionAV.draw_skill(ctx,origin,center,scale,entry)
		ctx.canvas=wash;ctx.draw_limit=mini(int(ctx.count)+8,MAX_DRAW_OPERATIONS-MAX_SETTLED_IMPACTS*3)
		Materials.draw_front(ctx,origin,center,scale*.85,entry)
		ctx.canvas=canvas
	else:
		Materials.draw_behind(ctx,origin,center,scale,entry)
		Weapons.draw(ctx,origin,center,scale,entry)
		if entry.target_shape=="single" and bool(entry.ultimate): _focused_ultimate(ctx,origin,center,scale,entry)
		elif entry.target_shape=="cone": _cone(ctx,origin,center,scale,entry)
		elif entry.target_shape=="line": _line_cast(ctx,origin,center,scale,entry)
		elif entry.target_shape=="chain": _chain_cast(ctx,origin,center,scale,entry)
		else: _family_cast(ctx,origin,center,scale,entry)
		Materials.draw_front(ctx,origin,center,scale,entry)
	ctx.draw_limit=MAX_DRAW_OPERATIONS
	# Only these supplied, authoritative points receive secondary target signs.
	if str(entry.delivery) in ["CHAIN","LINE"]:
		var previous := origin
		for value: Variant in impact_points.slice(0,MAX_SETTLED_IMPACTS):
			if value is not Vector2 or not value.is_finite(): continue
			var settled: Vector2 = value+Vector2(0,-10)*factor
			if phase>=0.26 and phase<0.82:
				_streak(ctx,previous,settled,3.5*scale,0.45,0,str(entry.delivery)=="CHAIN")
				_streak(ctx,previous,settled,1.3*scale,0.9,4,str(entry.delivery)=="CHAIN")
				_star(ctx,settled,5.0*scale,1.0,4)
			previous=settled
	return true

static func _family_cast(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, entry: Dictionary) -> void:
	match str(entry.family):
		"mend", "tank_restore": _restore(ctx,center,scale,entry)
		"sanctuary": _sanctuary(ctx,center,scale,entry)
		"tank_control": _bulwark(ctx,center,scale,entry)
		"bolt", "shot": _projected(ctx,origin,center,scale,entry)
		"bind", "lock": _binding(ctx,origin,center,scale,entry)
		"cataclysm": _cataclysm(ctx,center,scale,entry)
		"rain": _rain(ctx,origin,center,scale,entry)
		"fervor", "hunt": _fervor(ctx,center,scale,entry)
		"prison": _prison(ctx,center,scale,entry)

static func _focused_ultimate(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, entry: Dictionary) -> void:
	# Seven deliberately different concentrated ultimates. Surrounding material
	# is cast ornament: no area pool, radial rain or extra target marker.
	var phase:=float(ctx.phase)
	var alpha:=_envelope(phase)
	var release:=clampf((phase-0.16)/0.42,0,1)
	var second:=clampf((phase-0.48)/0.28,0,1)
	match str(entry.choreography):
		"astral_execution":
			for side: int in [-1,1]:
				var focus:=center+Vector2(side*(31-19*release),-43-side*9)*scale
				_glyph(ctx,focus,scale*(0.72+release*0.35),"crystal",alpha,side*(0.5+phase))
				_streak(ctx,focus,center+Vector2(0,-11)*scale,3.5*scale,alpha*0.7,3)
			var tip:=center+Vector2(0,-94*(1-release)-14)*scale
			_streak(ctx,tip+Vector2(-5,-35)*scale,tip,7*scale,alpha,0)
			_streak(ctx,tip+Vector2(-3,-33)*scale,tip,4*scale,alpha,2)
			_streak(ctx,tip+Vector2(-1,-25)*scale,tip,1.7*scale,alpha,4)
			if phase>0.39: _star(ctx,center+Vector2(0,-15)*scale,(18+second*8)*scale,alpha,3)
		"soul_extraction":
			for index: int in range(3):
				var knot:=center.lerp(origin,clampf((phase*1.8+index*0.23)-0.2,0,1))+Vector2(0,-sin(phase*PI+index)*12)*scale
				_streak(ctx,center+Vector2(0,-14-index*7)*scale,knot,(3.8-index*0.5)*scale,alpha*0.7,0,true)
				_streak(ctx,center+Vector2(0,-14-index*7)*scale,knot,(1.6-index*0.2)*scale,alpha,3 if index%2 else 2,true)
				_glyph(ctx,knot,scale*(0.6-index*0.08),"lantern",alpha,index*0.25)
			for side: int in [-1,1]: _glyph(ctx,center+Vector2(side*20,-29)*scale,scale*0.82,"bone",alpha,side*0.5)
			_glyph(ctx,center+Vector2(0,-38)*scale,scale*(1.1+second*0.2),"lantern",alpha)
		"bone_pin":
			var arrow:=origin.lerp(center,release)
			var angle:=(center-origin).angle()
			_streak(ctx,origin.lerp(arrow,0.58),arrow,7*scale,alpha*0.7,0)
			_streak(ctx,origin.lerp(arrow,0.58),arrow,3.5*scale,alpha,3)
			_arrow(ctx,arrow,scale*1.7,angle,alpha)
			for side: int in [-1,1]: _glyph(ctx,arrow+Vector2(-12,side*13)*scale,scale*0.64,"bone",alpha,side*0.65)
			if phase>0.42:
				_glyph(ctx,center+Vector2(0,-26)*scale,scale*1.4,"blade",alpha,0.2)
				for side: int in [-1,1]: _diamond(ctx,center+Vector2(side*(17+second*8),-9)*scale,9*scale,3*scale,5,alpha,side*0.4)
		"missile_lock":
			for side: int in [-1,1]:
				_poly(ctx,[Vector2(side*24,-46),Vector2(side*34,-46),Vector2(side*34,-34),Vector2(side*29,-34),Vector2(side*29,-41),Vector2(side*24,-41)],center,scale,0,alpha)
				_poly(ctx,[Vector2(side*25,-44),Vector2(side*32,-44),Vector2(side*32,-35),Vector2(side*30,-35),Vector2(side*30,-42),Vector2(side*25,-42)],center,scale,3,alpha)
			var missile:=origin.lerp(center,release)+Vector2(0,-sin(release*PI)*35)*scale
			var turn:=(center-origin).angle()
			_glyph(ctx,missile,scale*1.2,"crystal",alpha,turn+PI*0.5)
			_glyph(ctx,missile+Vector2(-19,-6)*scale,scale*0.57,"flame",alpha,turn-PI*0.5)
			if phase>0.4:
				_star(ctx,center+Vector2(0,-15)*scale,(22-second*6)*scale,alpha,4)
				for index: int in range(4):
					var turn2:=index*1.7+0.3
					_glyph(ctx,center+Vector2(cos(turn2)*(15+second*13),sin(turn2)*17-18)*scale,scale*0.36,"gear",alpha,index+phase*3)
		"root_prison":
			for side: int in [-1,1]:
				var grip:=center+Vector2(side*(32-release*13),-6-release*13)*scale
				_glyph(ctx,grip,scale*1.3,"rootclaw",alpha,side*(0.65-release*0.2))
				_leaf_branch(ctx,center+Vector2(side*28,9)*scale,center+Vector2(side*9,-60*release)*scale,scale*1.1,alpha)
			_glyph(ctx,center+Vector2(0,-61)*scale,scale*(0.45+release*0.7),"bloom",alpha,phase*0.8)
			for index: int in range(3): _diamond(ctx,center+Vector2((index-1)*12,-22-index*8)*scale,4*scale,7*scale,5,alpha)
		"molten_verdict":
			var drop:=center+Vector2(23*(1-release),-87*(1-release)-28)*scale
			_glyph(ctx,drop,scale*2.4,"blade",alpha,-0.63+release*0.3)
			_streak(ctx,drop+Vector2(18,-30)*scale,drop+Vector2(-16,26)*scale,8*scale,alpha*0.8,0)
			_streak(ctx,drop+Vector2(18,-30)*scale,drop+Vector2(-16,26)*scale,4*scale,alpha,3)
			if phase>0.4:
				_poly(ctx,[Vector2(-31,9),Vector2(-22,-9),Vector2(10,-22),Vector2(36,-44),Vector2(24,-22),Vector2(-10,-4)],center,scale,0,alpha)
				_poly(ctx,[Vector2(-27,7),Vector2(-20,-7),Vector2(11,-19),Vector2(30,-37),Vector2(20,-19),Vector2(-10,-2)],center,scale,2,alpha)
				_star(ctx,center+Vector2(0,-13)*scale,17*scale,alpha,4)
		"crystal_implosion":
			for index: int in range(5):
				var angle:=float(index)*TAU/5+0.3
				var distance:=47-29*release+second*8
				var shard:=center+Vector2(cos(angle)*distance,sin(angle)*distance*0.7-28)*scale
				_glyph(ctx,shard,scale*(0.65+index*0.04),"crystal",alpha,angle+PI*0.5)
				if phase<0.58: _streak(ctx,shard,center+Vector2(0,-26)*scale,1.5*scale,alpha*0.7,3)
			_diamond(ctx,center+Vector2(0,-27)*scale,(17+second*5)*scale,(26-second*6)*scale,0,alpha)
			_diamond(ctx,center+Vector2(0,-27)*scale,(13+second*3)*scale,21*scale,2,alpha)
			_diamond(ctx,center+Vector2(0,-31)*scale,6*scale,14*scale,4,alpha)
			if phase>0.48: _star(ctx,center+Vector2(0,-25)*scale,22*scale,alpha*0.9,3)
		_: _binding(ctx,origin,center,scale,entry)

static func _cone(ctx: Dictionary, origin: Vector2, target: Vector2, scale: float, entry: Dictionary) -> void:
	var phase:=float(ctx.phase)
	var alpha:=_envelope(phase)
	var forward:=(target-origin).normalized()
	if forward.length_squared()<0.01: forward=Vector2.RIGHT
	var normal:=forward.orthogonal()
	var length:=maxf(35,origin.distance_to(target))
	var spread:=clampf(float(entry.cone_width)*0.5,30,100)*scale
	var release:=clampf((phase-0.12)/0.48,0,1)
	# Five longitudinal ribbons share a forward fan, never a target-centered
	# circle. Offset lobes are emitted material, not fabricated settled hits.
	for index: int in range(5):
		var lane:=float(index-2)*0.5
		var end:=origin+forward*length*release+normal*spread*lane*release
		var start:=origin+forward*length*maxf(0,release-0.55)+normal*spread*lane*maxf(0,release-0.55)
		_streak(ctx,start,end,(6-absf(lane)*2)*scale,alpha*0.75,0)
		_streak(ctx,start,end,(3.5-absf(lane))*scale,alpha*0.75,2 if index%2 else 3,entry.faction in ["MACHINE","UNDERGROUND"])
		_glyph(ctx,end,scale*(0.6+release*0.3),str(entry.emblem),alpha,forward.angle()+lane*0.3)
		if phase>0.35: _diamond(ctx,end-forward*12*scale,5*scale,2*scale,5,alpha,forward.angle())
	_glyph(ctx,origin+forward*20*scale,scale*0.65,str(entry.emblem),alpha,-phase)

static func _line_cast(ctx: Dictionary, origin: Vector2, target: Vector2, scale: float, entry: Dictionary) -> void:
	var phase:=float(ctx.phase)
	var alpha:=_envelope(phase)
	var progress:=clampf((phase-0.08)/0.48,0,1)
	var end:=origin.lerp(target,progress)
	var angle:=(target-origin).angle()
	var thickness:=clampf(float(entry.line_width)*0.1,2,6)*scale
	_streak(ctx,origin,end,thickness+3*scale,alpha*0.75,0)
	_streak(ctx,origin,end,thickness,alpha*0.8,2)
	_streak(ctx,origin,end,1.3*scale,alpha,3)
	for index: int in range(4):
		var t:=clampf(progress-float(index)*0.16,0,1)
		var point:=origin.lerp(target,t)
		if entry.family=="shot": _arrow(ctx,point,scale*(0.65+float(index%2)*0.12),angle,alpha)
		else: _glyph(ctx,point,scale*(0.7+float(index%2)*0.2),str(entry.emblem),alpha,angle+PI*0.5)
		_diamond(ctx,point+Vector2(0,(-1 if index%2 else 1)*10)*scale,4*scale,2*scale,5,alpha,angle)

static func _chain_cast(ctx: Dictionary, origin: Vector2, target: Vector2, scale: float, entry: Dictionary) -> void:
	var phase:=float(ctx.phase)
	var alpha:=_envelope(phase)
	var head:=origin.lerp(target,clampf((phase-0.1)/0.42,0,1))
	_streak(ctx,origin,head,5*scale,alpha*0.85,0,true)
	_streak(ctx,origin,head,2.5*scale,alpha*0.9,2,true)
	_streak(ctx,origin,head,0.8*scale,alpha,3,true)
	# Conduit knots are parts of the travelling cast. Additional victims are
	# represented exclusively in draw() by explicit settled impact_points.
	for index: int in range(3):
		var knot:=origin.lerp(head,0.3+index*0.3)+Vector2(0,(-1 if index%2 else 1)*8)*scale
		_glyph(ctx,knot,scale*(0.38+index*0.08),str(entry.emblem),alpha,index*0.7+phase)
		_diamond(ctx,knot+Vector2(0,-12)*scale,3*scale,5*scale,5,alpha)
	_glyph(ctx,head,scale*(1.25 if bool(entry.ultimate) else 0.85),str(entry.emblem),alpha,phase*1.3)
	match str(entry.choreography):
		"switchyard":
			for side: int in [-1,1]:
				var coil:=origin+Vector2(side*16,-19)*scale
				_glyph(ctx,coil,scale*0.52,"gear",alpha,side*phase*4)
				_streak(ctx,coil,head,1.0*scale,alpha*0.6,5,true)
		"circuit":
			for index: int in range(3):
				var cut:=head+Vector2((index-1)*13,-9-index*5)*scale
				_poly(ctx,[Vector2(-3,-8),Vector2(3,-8),Vector2(3,8),Vector2(-3,8)],cut,scale,0,alpha)
				_poly(ctx,[Vector2(-1,-6),Vector2(1,-6),Vector2(1,6),Vector2(-1,6)],cut,scale,3 if index%2 else 5,alpha)
		"hook":
			for side: int in [-1,1]: _glyph(ctx,head+Vector2(side*14,-5)*scale,scale*0.52,"jaw",alpha,side*0.8)

# Drawing primitives quantize to screen pixels and reject degenerate triangles.
# Every actual operation passes a single cap; larger skills use larger shapes,
# never a per-target particle-system/node explosion.
static func _poly(ctx: Dictionary, cells: Array, center: Vector2, scale: float, color_index: int, alpha: float=1.0, angle: float=0.0) -> void:
	if int(ctx.count)>=int(ctx.get("draw_limit",MAX_DRAW_OPERATIONS)) or alpha<=0.005: return
	var points := PackedVector2Array()
	for cell: Vector2 in cells:
		var pixel := (center+cell.rotated(angle)*scale).round()
		if points.is_empty() or pixel!=points[-1]: points.append(pixel)
	if points.size()>1 and points[0]==points[-1]: points.remove_at(points.size()-1)
	if points.size()<3 or Geometry2D.triangulate_polygon(points).is_empty(): return
	var color := Color(str(ctx.palette[clampi(color_index,0,ctx.palette.size()-1)]),clampf(alpha,0,1))
	ctx.canvas.draw_colored_polygon(points,color)
	ctx.count=int(ctx.count)+1

static func _diamond(ctx: Dictionary, center: Vector2, width: float, height: float, color: int, alpha: float=1.0, angle: float=0.0) -> void:
	_poly(ctx,[Vector2(-width,0),Vector2(0,-height),Vector2(width,0),Vector2(0,height)],center,1,color,alpha,angle)

static func _star(ctx: Dictionary, center: Vector2, size: float, alpha: float, color: int=4) -> void:
	_poly(ctx,[Vector2(-size,-1),Vector2(-2,-2),Vector2(-1,-size),Vector2(1,-size),Vector2(2,-2),Vector2(size,-1),Vector2(size,1),Vector2(2,2),Vector2(1,size),Vector2(-1,size),Vector2(-2,2),Vector2(-size,1)],center,1,color,alpha)

static func _streak(ctx: Dictionary, start: Vector2, end: Vector2, width: float, alpha: float, color: int, zigzag: bool=false) -> void:
	if start.distance_squared_to(end)<1: return
	var normal := (end-start).normalized().orthogonal()
	var points: Array[Vector2]=[]
	var underside: Array[Vector2]=[]
	for index: int in range(7):
		var t:=float(index)/6.0
		var bend:=normal*(3.0 if index%2 else -3.0)*float(ctx.factor) if zigzag and index>0 and index<6 else Vector2.ZERO
		points.append(start.lerp(end,t)+normal*width+bend)
		underside.push_front(start.lerp(end,t)-normal*width+bend)
	points.append_array(underside)
	_poly(ctx,points,Vector2.ZERO,1,color,alpha)

static func _glyph(ctx: Dictionary, center: Vector2, size: float, motif: String, alpha: float=1.0, angle: float=0.0) -> void:
	var shape: Array
	match motif:
		"shield": shape=[Vector2(-9,-12),Vector2(9,-12),Vector2(11,-8),Vector2(8,5),Vector2(0,13),Vector2(-8,5),Vector2(-11,-8)]
		"banner": shape=[Vector2(-8,-15),Vector2(9,-15),Vector2(9,5),Vector2(4,2),Vector2(0,10),Vector2(-5,5),Vector2(-8,8)]
		"blade": shape=[Vector2(-3,13),Vector2(-3,-10),Vector2(0,-19),Vector2(3,-10),Vector2(3,13),Vector2(8,13),Vector2(8,17),Vector2(-8,17),Vector2(-8,13)]
		"bone": shape=[Vector2(-9,-13),Vector2(-3,-12),Vector2(-1,-7),Vector2(1,7),Vector2(7,10),Vector2(6,15),Vector2(0,14),Vector2(-3,10),Vector2(-4,-5),Vector2(-10,-8)]
		"lantern": shape=[Vector2(-4,-15),Vector2(4,-15),Vector2(4,-10),Vector2(10,-6),Vector2(7,9),Vector2(2,13),Vector2(0,17),Vector2(-2,13),Vector2(-7,9),Vector2(-10,-6),Vector2(-4,-10)]
		"gear": shape=[Vector2(-5,-13),Vector2(5,-13),Vector2(5,-9),Vector2(9,-9),Vector2(9,-5),Vector2(13,-5),Vector2(13,5),Vector2(9,5),Vector2(9,9),Vector2(5,9),Vector2(5,13),Vector2(-5,13),Vector2(-5,9),Vector2(-9,9),Vector2(-9,5),Vector2(-13,5),Vector2(-13,-5),Vector2(-9,-5),Vector2(-9,-9),Vector2(-5,-9)]
		"bolt": shape=[Vector2(2,-21),Vector2(-11,2),Vector2(-2,2),Vector2(-6,20),Vector2(12,-6),Vector2(3,-6)]
		"leaf": shape=[Vector2(-13,4),Vector2(-10,-6),Vector2(1,-13),Vector2(14,-15),Vector2(12,-2),Vector2(5,9),Vector2(-5,12)]
		"bloom": shape=[Vector2(0,-17),Vector2(5,-7),Vector2(14,-12),Vector2(11,-1),Vector2(18,5),Vector2(6,7),Vector2(2,17),Vector2(-4,8),Vector2(-16,7),Vector2(-9,-1),Vector2(-12,-11),Vector2(-4,-7)]
		"flame": shape=[Vector2(-12,10),Vector2(-15,-1),Vector2(-8,-13),Vector2(-5,-3),Vector2(0,-23),Vector2(7,-10),Vector2(5,-3),Vector2(12,-8),Vector2(16,4),Vector2(9,14),Vector2(-3,17)]
		"mountain": shape=[Vector2(-21,13),Vector2(-12,-7),Vector2(-7,-2),Vector2(1,-23),Vector2(10,-9),Vector2(9,-2),Vector2(22,13)]
		"crystal": shape=[Vector2(-9,8),Vector2(-12,-6),Vector2(0,-24),Vector2(11,-8),Vector2(8,9),Vector2(0,17)]
		"mushroom": shape=[Vector2(-16,-2),Vector2(-12,-12),Vector2(-4,-17),Vector2(6,-16),Vector2(14,-9),Vector2(17,-1),Vector2(5,3),Vector2(5,14),Vector2(-5,14),Vector2(-4,3)]
		"rootclaw": shape=[Vector2(-13,17),Vector2(-15,4),Vector2(-10,-10),Vector2(-4,-24),Vector2(4,-32),Vector2(0,-15),Vector2(5,-5),Vector2(13,4),Vector2(16,17),Vector2(4,10),Vector2(0,18),Vector2(-4,12)]
		"jaw": shape=[Vector2(-15,15),Vector2(-17,-2),Vector2(-13,-18),Vector2(-5,-31),Vector2(3,-35),Vector2(-2,-20),Vector2(2,-11),Vector2(10,-18),Vector2(7,-4),Vector2(16,-8),Vector2(9,4),Vector2(15,10),Vector2(4,9),Vector2(3,17)]
		"slab": shape=[Vector2(-17,12),Vector2(-18,-7),Vector2(-12,-20),Vector2(-4,-24),Vector2(4,-17),Vector2(14,-20),Vector2(19,-7),Vector2(15,15),Vector2(5,11),Vector2(-2,17),Vector2(-9,11)]
		_: shape=[Vector2(-6,0),Vector2(0,-11),Vector2(6,0),Vector2(0,11)]
	_poly(ctx,shape,center,size*1.20,0,alpha*0.96,angle)
	_poly(ctx,shape,center,size,2,alpha*0.88,angle)
	_poly(ctx,shape,center+Vector2(-1,-2)*size,size*0.63,3,alpha,angle)
	_diamond(ctx,center+Vector2(0,-4)*size,2.0*size,5.0*size,4,alpha*0.95,angle)

static func _faction_glyph(faction: String) -> String:
	return str({"HUMAN":"banner","UNDEAD":"lantern","MACHINE":"gear","FOREST":"leaf","HIGHLAND":"flame","UNDERGROUND":"crystal"}[faction])

static func _envelope(phase: float) -> float:
	return clampf(phase/0.2,0.0,1.0)*clampf((1.0-phase)/0.24,0.0,1.0)

static func _restore(ctx: Dictionary, center: Vector2, scale: float, entry: Dictionary) -> void:
	var phase := float(ctx.phase)
	var alpha := _envelope(phase)
	var tank: bool = entry.family=="tank_restore"
	var rise := Vector2(0,-phase*29)*scale
	var count := 3 if tank else 4
	match str(entry.faction):
		"HUMAN":
			for index: int in range(count):
				var local := Vector2((index-(count-1)*0.5)*18,-12-absf(index-(count-1)*0.5)*9)*scale
				_glyph(ctx,center+local+rise,scale*0.72,"shield" if tank else "banner",alpha,0.1*(index-1))
			_streak(ctx,center+Vector2(-28,-3)*scale,center+Vector2(28,-3)*scale,2.0*scale,alpha*0.65,3)
		"UNDEAD":
			for index: int in range(4):
				var side := -1 if index%2 else 1
				_glyph(ctx,center+Vector2(side*(10+index*4),-9-index*9)*scale+rise*0.35,scale*(0.7 if tank else 0.55),"bone" if tank else "lantern",alpha,side*0.4)
			_streak(ctx,center+Vector2(-28,-26)*scale,center+Vector2(28,4)*scale,1.8*scale,alpha,3,true)
		"MACHINE":
			for index: int in range(3 if tank else 4):
				var angle := float(index)*TAU/count+phase*0.5
				var local := Vector2(cos(angle)*31,sin(angle)*16-17)*scale
				_glyph(ctx,center+local,scale*(0.65 if tank else 0.45),"gear",alpha,phase+index)
				_streak(ctx,center+local,center+Vector2(0,-17)*scale,1.3*scale,alpha*0.65,4,true)
			_glyph(ctx,center+rise*0.3,scale*0.75,"shield" if tank else "bolt",alpha)
		"FOREST":
			for index: int in range(4):
				var angle := PI*0.25+index*PI*0.5
				_glyph(ctx,center+Vector2(cos(angle)*27,sin(angle)*15-13)*scale+rise*0.45,scale*0.68,"leaf" if tank else "bloom",alpha,angle-PI*0.5)
			_glyph(ctx,center+Vector2(0,-15)*scale,scale*0.62,"bloom" if tank else "leaf",alpha)
		"HIGHLAND":
			for index: int in range(3):
				_glyph(ctx,center+Vector2((index-1)*22,-13-abs(index-1)*5)*scale+rise*0.4,scale*(0.8 if tank else 0.65),"mountain" if tank else "flame",alpha)
			_streak(ctx,center+Vector2(-33,1)*scale,center+Vector2(31,1)*scale,3*scale,alpha*0.6,2)
		"UNDERGROUND":
			for index: int in range(4):
				var local := Vector2((index-1.5)*18,-7-(index%2)*15)*scale
				_glyph(ctx,center+local+rise*0.4,scale*(0.7 if tank else 0.65),"crystal" if tank else "mushroom",alpha,(index-1.5)*0.16)
			for index: int in range(3): _diamond(ctx,center+Vector2((index-1)*16,-30-phase*28)*scale,3*scale,6*scale,4,alpha*0.75)

static func _sanctuary(ctx: Dictionary, center: Vector2, scale: float, entry: Dictionary) -> void:
	var phase := float(ctx.phase)
	var alpha := _envelope(phase)
	var spread := (40+minf(phase*2,1)*27)*scale
	var faction := str(entry.faction)
	var count := 6 if faction not in ["HIGHLAND","UNDERGROUND"] else 5
	# Entirely distinct construction: standards, hanging soul lanterns, docking
	# clamps, petals, hearths and a mycelial crown, not the same healing crosses.
	for index: int in range(count):
		var angle := float(index)*TAU/count
		var local := Vector2(cos(angle)*spread,sin(angle)*spread*0.47)
		var lift := 13+sin(phase*PI)*24
		var glyph := str({"HUMAN":"banner","UNDEAD":"lantern","MACHINE":"gear","FOREST":"bloom","HIGHLAND":"flame","UNDERGROUND":"mushroom"}[faction])
		_glyph(ctx,center+local+Vector2(0,-lift)*scale,scale*(0.95+0.15*sin(index+phase*4)),glyph,alpha,index*0.25 if faction=="FOREST" else 0)
		if faction in ["MACHINE","UNDERGROUND","HUMAN"]: _streak(ctx,center+local,center+Vector2(0,-16)*scale,2.0*scale,alpha*0.35,3,faction=="MACHINE")
		elif faction=="FOREST": _leaf_branch(ctx,center,center+local,scale,alpha*0.65)
		elif faction=="UNDEAD": _streak(ctx,center+local,center+local+Vector2(0,-65)*scale,2.5*scale,alpha*0.3,2,true)
		else: _diamond(ctx,center+local+Vector2(0,-lift-24)*scale,4*scale,9*scale,4,alpha*0.65)
	_glyph(ctx,center+Vector2(0,-32)*scale,scale*1.5,_faction_glyph(faction),alpha)
	if phase>0.28:
		for index: int in range(5): _star(ctx,center+Vector2((index-2)*23,-48-sin(index+phase*5)*20)*scale,scale*4,alpha*0.8)

static func _bulwark(ctx: Dictionary, center: Vector2, scale: float, entry: Dictionary) -> void:
	var phase := float(ctx.phase)
	var alpha := _envelope(phase)
	var erupt := clampf((phase-0.12)*2.2,0,1)
	var faction := str(entry.faction)
	for index: int in range(5):
		var local := Vector2((index-2)*31,abs(index-2)*8)*scale
		var height: float = (50-absi(index-2)*7)*erupt
		match faction:
			"HUMAN": _glyph(ctx,center+local+Vector2(0,-height)*scale,scale*1.25,"shield",alpha,index*0.08-0.16)
			"UNDEAD":
				_glyph(ctx,center+local+Vector2(0,-height)*scale,scale*1.3,"bone",alpha,0.35*(index-2))
				_glyph(ctx,center+local+Vector2(0,-height-18)*scale,scale*0.65,"lantern",alpha)
			"MACHINE":
				_glyph(ctx,center+local+Vector2(0,-height*0.6)*scale,scale*1.45,"shield",alpha,(index-2)*0.18)
				_poly(ctx,[Vector2(-8,-height),Vector2(8,-height),Vector2(8,-height+5),Vector2(-8,-height+5)],center+local,scale,4,alpha*0.8)
				if index>0: _streak(ctx,center+local+Vector2(-31,-height)*scale,center+local+Vector2(0,-height)*scale,2*scale,alpha,3,true)
			"FOREST":
				_glyph(ctx,center+local+Vector2(0,-height*0.4)*scale,scale*1.25,"rootclaw",alpha,(index-2)*0.15)
				_glyph(ctx,center+local+Vector2(0,5)*scale,scale*0.4,"leaf",alpha,index*0.6)
			"HIGHLAND":
				_glyph(ctx,center+local+Vector2(0,-height*0.55)*scale,scale*1.6,"mountain",alpha)
				_glyph(ctx,center+local+Vector2(0,-height-8)*scale,scale*0.5,"flame",alpha)
			"UNDERGROUND":
				_glyph(ctx,center+local+Vector2(0,-height*0.25)*scale,scale*1.45,"jaw",alpha,(index-2)*0.22)
				_diamond(ctx,center+local+Vector2(0,-height-14)*scale,3*scale,6*scale,3,alpha)
	if phase>0.3:
		var wave := (phase-0.3)*120*scale
		for index: int in range(8):
			var angle := float(index)*TAU/8
			var local := Vector2(cos(angle)*wave,sin(angle)*wave*0.44)
			_diamond(ctx,center+local,10*scale,4*scale,3,alpha*0.55,angle)

static func _projected(ctx: Dictionary, origin: Vector2, target: Vector2, scale: float, entry: Dictionary) -> void:
	var phase := float(ctx.phase)
	var alpha := _envelope(phase)
	var is_shot: bool = entry.family=="shot"
	var moving := origin.lerp(target,clampf((phase-0.08)/0.48,0,1))
	var angle := (target-origin).angle()
	var tail := origin.lerp(moving,0.55)
	var faction := str(entry.faction)
	if phase<0.65:
		_streak(ctx,tail,moving,(3.5 if is_shot else 7.0)*scale,alpha*0.42,1,faction=="MACHINE")
		_streak(ctx,tail,moving,(1.5 if is_shot else 3.0)*scale,alpha*0.85,3,faction=="MACHINE")
		if is_shot:
			match faction:
				"HUMAN": _arrow(ctx,moving,scale*1.4,angle,alpha)
				"UNDEAD": _glyph(ctx,moving,scale*0.9,"bone",alpha,angle+PI*0.5)
				"MACHINE": _glyph(ctx,moving,scale*0.75,"gear",alpha,phase*12)
				"FOREST":
					_arrow(ctx,moving+Vector2(0,-5)*scale,scale,angle,alpha)
					_arrow(ctx,moving+Vector2(0,5)*scale,scale,angle,alpha)
				"HIGHLAND": _glyph(ctx,moving,scale*1.25,"blade",alpha,angle+PI*0.5)
				"UNDERGROUND": _glyph(ctx,moving,scale,"crystal",alpha,angle+PI*0.5)
		else:
			var glyph := str({"HUMAN":"crystal","UNDEAD":"lantern","MACHINE":"bolt","FOREST":"leaf","HIGHLAND":"flame","UNDERGROUND":"crystal"}[faction])
			_glyph(ctx,moving,scale*1.15,glyph,alpha,angle+PI*0.5 if faction in ["FOREST","UNDERGROUND"] else 0)
			if faction=="FOREST":
				for index: int in [-1,1]: _glyph(ctx,moving+Vector2(0,index*16)*scale,scale*0.6,"leaf",alpha,angle+index*0.7)
			if faction=="MACHINE":
				_streak(ctx,moving-Vector2(14,28)*scale,moving+Vector2(12,23)*scale,2*scale,alpha,4,true)
	if phase>=0.36:
		var bloom := clampf((phase-0.32)*2.5,0,1)
		for index: int in range(5 if is_shot else 7):
			var turn := float(index)*TAU/(5 if is_shot else 7)+phase*0.8
			var distance := (8+bloom*31)*scale
			var local := Vector2(cos(turn)*distance,sin(turn)*distance*0.6)
			_diamond(ctx,target+local,scale*(5 if is_shot else 8),scale*(2 if is_shot else 4),3,alpha*0.75,turn)
		_star(ctx,target,scale*(15 if is_shot else 25)*(1-bloom*0.35),alpha,4)
		if faction=="HIGHLAND" and not is_shot:
			for index: int in range(3): _glyph(ctx,target+Vector2((index-1)*22,-bloom*30)*scale,scale*0.8,"flame",alpha)
		elif faction=="UNDERGROUND" and not is_shot:
			_streak(ctx,origin,target,4*scale,alpha*0.4,2)
			for index: int in range(3): _diamond(ctx,target+Vector2((index-1)*20,-20)*scale,scale*5,scale*18,4,alpha*0.6)

static func _arrow(ctx: Dictionary, center: Vector2, scale: float, angle: float, alpha: float) -> void:
	_poly(ctx,[Vector2(-23,-3),Vector2(8,-3),Vector2(8,-8),Vector2(25,0),Vector2(8,8),Vector2(8,3),Vector2(-23,3),Vector2(-30,9),Vector2(-29,2),Vector2(-29,-2),Vector2(-30,-9)],center,scale,0,alpha,angle)
	_poly(ctx,[Vector2(-22,-1),Vector2(11,-1),Vector2(11,-5),Vector2(21,0),Vector2(11,5),Vector2(11,1),Vector2(-22,1)],center,scale,4,alpha,angle)
	_poly(ctx,[Vector2(-21,-2),Vector2(8,-2),Vector2(8,1),Vector2(-21,1)],center,scale,2,alpha,angle)
	_poly(ctx,[Vector2(-25,-5),Vector2(-17,-2),Vector2(-13,-2),Vector2(-22,-7)],center,scale,3,alpha,angle)

static func _binding(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, entry: Dictionary) -> void:
	var phase := float(ctx.phase)
	var alpha := _envelope(phase)
	var lock: bool = entry.family=="lock"
	var faction := str(entry.faction)
	var grow := clampf(phase*2.8,0,1)
	if lock:
		if faction=="HUMAN":
			_glyph(ctx,center+Vector2(-14,-22)*scale,scale*1.5,"blade",alpha,-0.65)
			_glyph(ctx,center+Vector2(14,-22)*scale,scale*1.5,"blade",alpha,0.65)
		elif faction=="UNDEAD":
			for index: int in range(5): _glyph(ctx,origin.lerp(center,float(index)/4.0)+Vector2(0,-sin(index*PI/4)*22)*scale,scale*0.48,"bone",alpha,index*0.6)
			_glyph(ctx,center+Vector2(0,-22)*scale,scale*1.5,"lantern",alpha)
		elif faction=="MACHINE":
			for index: int in [-1,1]:
				_streak(ctx,center+Vector2(index*40,-38)*scale,center+Vector2(-index*36,12)*scale,4*scale,alpha,3,true)
				_glyph(ctx,center+Vector2(index*36,-30)*scale,scale*0.6,"gear",alpha,phase*3)
		elif faction=="FOREST":
			_leaf_branch(ctx,origin,center,scale*1.5,alpha)
			for index: int in [-1,1]: _glyph(ctx,center+Vector2(index*22,-15)*scale,scale*1.2,"leaf",alpha,index*0.6)
		elif faction=="HIGHLAND":
			_glyph(ctx,center+Vector2(0,-70*(1-grow)-26)*scale,scale*1.8,"mountain",alpha,PI)
			_streak(ctx,center+Vector2(-8,-90)*scale,center+Vector2(6,-14)*scale,3*scale,alpha,4,true)
		else:
			for index: int in [-1,1]: _glyph(ctx,center+Vector2(index*27*(1.3-grow*0.5),-8)*scale,scale*1.4,"crystal",alpha,index*0.8)
			_streak(ctx,center+Vector2(-32,6)*scale,center+Vector2(32,6)*scale,3*scale,alpha,4,true)
	else:
		var count:=3 if entry.target_shape=="single" else 5
		var half:=float(count-1)*0.5
		for index: int in range(count):
			var x := (index-half)*(12 if entry.target_shape=="single" else 18)
			var height: float = (28+absf(index-half)*8)*grow
			var local := center+Vector2(x,6)*scale
			match faction:
				"HUMAN": _glyph(ctx,local+Vector2(0,-height*0.5)*scale,scale*1.1,"crystal",alpha,(index-half)*0.2)
				"UNDEAD":
					_glyph(ctx,local+Vector2(0,-height*0.45)*scale,scale,"bone",alpha,(index-half)*0.28)
					_streak(ctx,local,center+Vector2(-x*0.4,-38)*scale,2*scale,alpha*0.65,3)
				"MACHINE":
					_streak(ctx,local,local+Vector2(0,-height)*scale,3*scale,alpha,3,true)
					_glyph(ctx,local+Vector2(0,-height)*scale,scale*0.65,"gear",alpha,phase*2)
				"FOREST": _leaf_branch(ctx,local,local+Vector2(-x*0.45,-height)*scale,scale,alpha)
				"HIGHLAND":
					_glyph(ctx,local+Vector2(0,-height*0.45)*scale,scale,"mountain",alpha)
					_poly(ctx,[Vector2(-6,-3),Vector2(-6,-11),Vector2(6,-11),Vector2(6,6),Vector2(-1,6),Vector2(-1,0),Vector2(3,0)],local+Vector2(0,-height-12)*scale,scale,4,alpha)
				"UNDERGROUND":
					_glyph(ctx,local+Vector2(0,-height*0.45)*scale,scale,"crystal",alpha,(index-half)*0.45)
					_diamond(ctx,local+Vector2(0,-height-12)*scale,3*scale,6*scale,4,alpha)
	if phase>0.42: _star(ctx,center+Vector2(0,-22)*scale,11*scale,alpha*0.8)

static func _leaf_branch(ctx: Dictionary, start: Vector2, end: Vector2, scale: float, alpha: float) -> void:
	_streak(ctx,start,end,3.5*scale,alpha,0,true)
	_streak(ctx,start,end,1.8*scale,alpha,2,true)
	for index: int in range(2):
		var local := start.lerp(end,0.35+index*0.4)
		_glyph(ctx,local+Vector2((1 if index%2 else -1)*8,-4)*scale,scale*0.45,"leaf",alpha,(index*2-1)*0.6)

static func _cataclysm(ctx: Dictionary, center: Vector2, scale: float, entry: Dictionary) -> void:
	var phase := float(ctx.phase)
	var alpha := _envelope(phase)
	var erupt := clampf((phase-0.12)*2.6,0,1)
	var faction := str(entry.faction)
	match faction:
		"HUMAN":
			# Falling constellation lances land on a fractured star seal.
			for index: int in range(5):
				var local := Vector2((index-2)*32,abs(index-2)*9)*scale
				# A compact high-sky entry preserves a large impact at normal
				# camera scale; a 250px invisible travel tail must not force the
				# entire visual workbench (and every actor) to shrink to ants.
				var top := center+local+Vector2(-25,-75*(1-erupt)-28)*scale
				_streak(ctx,top+Vector2(-15,-34)*scale,top,7*scale,alpha*0.35,2)
				_streak(ctx,top+Vector2(-9,-26)*scale,top,2.7*scale,alpha,4)
				_star(ctx,top,13*scale,alpha)
			for index: int in range(8):
				var angle:=index*TAU/8
				_diamond(ctx,center+Vector2(cos(angle)*61,sin(angle)*29)*scale,24*scale,5*scale,3,alpha*0.8,angle)
		"UNDEAD":
			# A broad soul torrent with asymmetric spectral ribs, not a meteor.
			for index: int in range(7):
				var x:=(index-3)*23
				_glyph(ctx,center+Vector2(x,-25-abs(x)*0.25-erupt*28)*scale,scale*(0.8+float(index%2)*0.35),"lantern",alpha,sin(index+phase)*0.25)
				_streak(ctx,center+Vector2(x,13)*scale,center+Vector2(x*0.65,-100*erupt)*scale,4*scale,alpha*0.42,2,true)
			for index: int in [-1,1]: _glyph(ctx,center+Vector2(index*70,-20)*scale,scale*2.0,"bone",alpha,index*0.7)
		"MACHINE":
			# Storm switchyard: octagonal conductor towers and branching bolts.
			for index: int in range(6):
				var angle:=index*TAU/6
				var node:=center+Vector2(cos(angle)*72,sin(angle)*37-22)*scale
				_glyph(ctx,node,scale*0.8,"gear",alpha,phase*3+index)
				_streak(ctx,center+Vector2(0,-57)*scale,node,6*scale,alpha*0.3,2,true)
				_streak(ctx,center+Vector2(0,-57)*scale,node,2*scale,alpha,4,true)
			_glyph(ctx,center+Vector2(0,-65)*scale,scale*2.2,"bolt",alpha)
		"FOREST":
			# Canopy columns curl inward, opening a dense, multi-storey leaf court.
			for index: int in range(6):
				var x:=(index-2.5)*29
				var top:=center+Vector2(x*0.7,-35-erupt*50-abs(x)*0.2)*scale
				_leaf_branch(ctx,center+Vector2(x,18)*scale,top,scale*1.05,alpha)
				_glyph(ctx,top,scale*1.1,"leaf",alpha,(index-2.5)*0.35)
			_glyph(ctx,center+Vector2(0,-60)*scale,scale*1.6,"bloom",alpha)
		"HIGHLAND":
			# Caldera cracks and tall offset magma pillars.
			for index: int in range(7):
				var x:=(index-3)*23
				var flame:=center+Vector2(x,-15-erupt*(20+float((index*3)%5)*12))*scale
				_glyph(ctx,flame,scale*(1.0+float(index%3)*0.25),"flame",alpha)
				_streak(ctx,center+Vector2(x*0.8,18)*scale,flame,3*scale,alpha*0.65,3,true)
			for index: int in [-1,1]: _glyph(ctx,center+Vector2(index*75,2)*scale,scale*1.2,"mountain",alpha,index*0.2)
		"UNDERGROUND":
			# Collapsing facets point toward a hovering resonance core.
			for index: int in range(7):
				var x:=(index-3)*25
				_glyph(ctx,center+Vector2(x*(1-erupt*0.25),-7-abs(x)*0.24-erupt*25)*scale,scale*(1.05+float(index%2)*0.2),"crystal",alpha,-(index-3)*0.3)
				_streak(ctx,center+Vector2(x,-20)*scale,center+Vector2(0,-75)*scale,2*scale,alpha*0.55,3)
			_diamond(ctx,center+Vector2(0,-85)*scale,18*scale,29*scale,0,alpha)
			_diamond(ctx,center+Vector2(0,-85)*scale,13*scale,22*scale,4,alpha)
	if phase>0.32:
		for index: int in range(8):
			var angle:=index*TAU/8+0.2
			var local:=Vector2(cos(angle)*(30+phase*78),sin(angle)*(18+phase*36))*scale
			_diamond(ctx,center+local,9*scale,3*scale,3,alpha*0.7,angle)

static func _rain(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, entry: Dictionary) -> void:
	var phase:=float(ctx.phase)
	var alpha:=_envelope(phase)
	var faction:=str(entry.faction)
	var count:=7 if bool(entry.ultimate) else 5
	for index: int in range(count):
		var landing:=center+Vector2((index-(count-1)*0.5)*24,(index%3-1)*17)*scale
		var progress:=clampf((phase-0.06-float(index%3)*0.04)/0.48,0,1)
		var projectile:=landing+Vector2(-37,-120)*(1-progress)*scale
		if phase<0.7:
			if faction=="MACHINE":
				_glyph(ctx,projectile,scale*0.55,"gear",alpha,index+phase*10)
				_streak(ctx,projectile+Vector2(-5,-24)*scale,projectile,2*scale,alpha,4)
			else: _arrow(ctx,projectile,scale*(1.0 if faction=="HUMAN" else 0.85),PI*0.4,alpha)
		if phase>0.38:
			_star(ctx,landing,scale*(13 if faction=="MACHINE" else 8),alpha)
			if faction=="UNDEAD": _glyph(ctx,landing+Vector2(0,-14)*scale,scale*0.7,"lantern",alpha)
			elif faction=="MACHINE":
				for side: int in [-1,1]: _diamond(ctx,landing+Vector2(side*12,-9)*scale,3*scale,7*scale,3,alpha,side*0.5)
	if bool(entry.ultimate):
		_streak(ctx,origin,center,5*scale,alpha*0.25,3,faction=="MACHINE")
		_glyph(ctx,origin+Vector2(0,-30)*scale,scale*0.9,"gear" if faction=="MACHINE" else "bone",alpha)

static func _fervor(ctx: Dictionary, center: Vector2, scale: float, entry: Dictionary) -> void:
	var phase:=float(ctx.phase)
	var alpha:=_envelope(phase)
	var ultimate:=bool(entry.ultimate)
	var faction:=str(entry.faction)
	var spread:=scale*(56 if ultimate else 35)
	for side: int in [-1,1]:
		for index: int in range(3):
			var offset:=Vector2(side*(spread/scale+index*8),-22-index*15)*scale
			var glyph:=str({"HUMAN":"banner","UNDEAD":"bone","MACHINE":"gear","FOREST":"leaf","HIGHLAND":"flame","UNDERGROUND":"crystal"}[faction])
			_glyph(ctx,center+offset,scale*(0.85 if ultimate else 0.65),glyph,alpha,side*(0.4+index*0.18)+phase*0.2)
			if ultimate: _streak(ctx,center+Vector2(0,-18)*scale,center+offset,3*scale,alpha*0.35,3,faction=="MACHINE")
	if faction=="HIGHLAND" or faction=="UNDERGROUND":
		# The melee sweep has a long crescent edge rather than six floating icons.
		for side: int in [-1,1]:
			_poly(ctx,[Vector2(-48,-15),Vector2(-18,-31),Vector2(25,-20),Vector2(49,7),Vector2(20,-8),Vector2(-15,-19)],center+Vector2(0,side*9)*scale,scale,3,alpha*0.75,side*phase*1.2)
	elif faction=="MACHINE": _glyph(ctx,center+Vector2(0,-27)*scale,scale*1.25,"gear",alpha,phase*6)
	elif faction=="FOREST": _glyph(ctx,center+Vector2(0,-35)*scale,scale,"bloom",alpha)
	else: _star(ctx,center+Vector2(0,-36)*scale,scale*(19 if ultimate else 11),alpha)

static func _prison(ctx: Dictionary, center: Vector2, scale: float, entry: Dictionary) -> void:
	var phase:=float(ctx.phase)
	var alpha:=_envelope(phase)
	var faction:=str(entry.faction)
	var rise:=clampf((phase-0.1)*2.5,0,1)
	match faction:
		"HUMAN":
			for index: int in [-1,1]:
				_glyph(ctx,center+Vector2(index*30,-55*rise)*scale,scale*2.3,"blade",alpha,index*0.6)
				_glyph(ctx,center+Vector2(index*75,-9)*scale,scale,"banner",alpha)
			_streak(ctx,center+Vector2(-83,10)*scale,center+Vector2(83,10)*scale,3*scale,alpha*0.7,3)
		"UNDEAD":
			# Large hollow bell and dangling clappers, no copied caster sprite.
			var shell: Array=[Vector2(-44,4),Vector2(-32,-6),Vector2(-29,-49),Vector2(-18,-68),Vector2(18,-68),Vector2(29,-49),Vector2(32,-6),Vector2(44,4),Vector2(44,12),Vector2(18,12),Vector2(11,4),Vector2(-11,4),Vector2(-18,12),Vector2(-44,12)]
			_poly(ctx,shell,center+Vector2(0,-13*rise)*scale,scale,0,alpha*0.85)
			_poly(ctx,shell,center+Vector2(0,-16*rise)*scale,scale*0.88,2,alpha*0.64)
			_glyph(ctx,center+Vector2(0,-20)*scale,scale*1.3,"lantern",alpha)
			for index: int in [-1,1]: _glyph(ctx,center+Vector2(index*62,-20)*scale,scale,"bone",alpha,index*0.4)
		"MACHINE":
			for index: int in range(4):
				var x:=(index-1.5)*43
				_glyph(ctx,center+Vector2(x,-20-45*rise)*scale,scale*0.9,"gear",alpha,phase*3+index)
				_streak(ctx,center+Vector2(x,12)*scale,center+Vector2(x,-55*rise)*scale,3*scale,alpha,3,true)
				if index<3: _streak(ctx,center+Vector2(x,-55*rise)*scale,center+Vector2(x+43,-55*rise)*scale,2*scale,alpha,4,true)
		"FOREST":
			# A low interlocking thorn lattice, deliberately unlike the mage's
			# tall canopy or the tank's woody root-claw crown.
			for index: int in range(4):
				var shift:=(index-1.5)*29
				var start:=center+Vector2(-75,shift*0.6-20)*scale
				var finish:=center+Vector2(75,-shift*0.6-20)*scale
				_streak(ctx,start,finish,4*scale,alpha,0,true)
				_streak(ctx,start,finish,2*scale,alpha,3,true)
				_streak(ctx,start+Vector2(0,-33)*scale,finish+Vector2(0,33)*scale,3*scale,alpha*0.8,2,true)
				for side: int in [-1,1]:
					var top:=center+Vector2(side*(42+index*12),-28-(index%2)*29)*scale
					_glyph(ctx,top,scale*0.8,"rootclaw",alpha,side*(0.5+index*0.2))
		"HIGHLAND":
			for index: int in [-1,0,1]:
				var local:=center+Vector2(index*62,-15)*scale
				_streak(ctx,local+Vector2(index*10,-120*(1-rise)-52)*scale,local,5*scale,alpha,3,true)
				_streak(ctx,local+Vector2(index*10,-120*(1-rise)-52)*scale,local,1.8*scale,alpha,4,true)
				_glyph(ctx,local,scale*1.5,"mountain",alpha)
			_glyph(ctx,center+Vector2(0,-52)*scale,scale*1.6,"flame",alpha)
		"UNDERGROUND":
			for index: int in range(7):
				var x:=(index-3)*24
				_glyph(ctx,center+Vector2(x,-8-float(index%2)*18*rise)*scale,scale*(0.8+rise*0.4),"slab",alpha,(index-3)*0.1)
				_streak(ctx,center+Vector2(x,18)*scale,center+Vector2(-x*0.5,-28)*scale,2.5*scale,alpha*0.8,3,true)
			_glyph(ctx,center+Vector2(0,-61*rise)*scale,scale,"mushroom",alpha)
	if phase>0.35:
		for index: int in range(8):
			var angle:=index*TAU/8
			_star(ctx,center+Vector2(cos(angle)*86,sin(angle)*39)*scale,scale*4,alpha*0.75)

