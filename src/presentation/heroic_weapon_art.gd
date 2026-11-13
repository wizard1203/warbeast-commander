extends RefCounted
const FactionAV = preload("res://src/presentation/heroic_faction_av.gd")
const ExpansionAV=preload("res://src/presentation/heroic_expansion_av_m66.gd")
const MageAV=preload("res://src/presentation/heroic_mage_effects_m68.gd")
const RangedAV=preload("res://src/presentation/heroic_ranged_roles_m68.gd")
## M55: identity-led pixel weapons, not a second attack or damage simulation.
## One bounded, stateless drawing plan drives native render and geometry audits.
const MAX_ACTIONS := 96
const MAX_IMPACTS := 6
const INK := Color("171c26")
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const PALETTES := {
	"HUMAN":["796349","d8b96b","fff0c4"],"UNDEAD":["675267","bf9a99","f1dfc3"],
	"MACHINE":["4b6775","8ec8d0","f2f2c8"],"FOREST":["4d7248","a7c76b","f0edb2"],
	"HIGHLAND":["84534b","e9944c","fff0a4"],"UNDERGROUND":["695180","bb9cd1","f0dfb5"],
}
const TROOPS := {
	"hinge_guard":"SWORD_FAN","bright_crossbow":"CROSSBOW_BOLT","iron_lancer":"LONG_PIKE",
	"grove_mender":"OATH_LANTERN","oath_cavalry":"CAVALRY_LANCE",
	"ash_guard":"BONE_HATCHET","bone_archer":"MEMORIAL_WISP","stitched_guard":"BONE_CLEAVER","ember_mender":"EMBER_SOUL",
	"rivet_guard":"RIVET_PUNCH","shard_gunner":"CRYSTAL_BULLET","gear_engine":"HEAVY_CANNON","repair_drone":"COIL_ARC",
	"vine_guard":"VINE_SICKLE","leaf_archer":"LEAF_ARROW","stag_rider":"ANTLER_THRUST","root_mender":"ROOT_WISP",
	"ridge_guard":"HAMMER_CRUSH","stone_slinger":"BOULDER","fire_dragon":"DRAGON_BREATH","rune_keeper":"RUNE_CINDER",
	"chitin_guard":"CHITIN_CLAW","echo_shooter":"ECHO_SHARD","tunnel_rider":"LIZARD_BITE","spore_mender":"SPORE_DART",
	"oath_colossus":"OATH_ARBALEST","soul_revenant":"SOUL_MAUL","aether_engine":"AETHER_SHELL",
	"elder_treant":"ROOT_SLAM","rune_behemoth":"RUNE_STOMP","abyss_devourer":"ABYSS_MAW",
	"neutral_raider":"PICK_HOOK","neutral_hunter":"LEAF_ARROW","neutral_brute":"ROCK_FIST",
	"neutral_trial_guard":"ROCK_FIST","neutral_trial_sentinel":"SEISMIC_CHUNK",
}
const HEROES := {
	"COMMANDER":"OATH_BLADE","BULWARK":"SHIELD_BASH","ARCANIST":"ARCANE_LANCE","RANGER":"OATH_ARROW","DUELIST":"DUAL_BLADE",
	"ASH_MARSHAL":"BONE_CLEAVER","MOURN_ORACLE":"SOUL_FLAME","CINDER_STALKER":"BONE_ARROW","ASH_CHANTER":"EMBER_SOUL","GRAVE_BELL":"GRAVE_CHIME",
	"COIL_WARDEN":"RIVET_PUNCH","VOLT_WEAVER":"COIL_ARC","GEAR_HUNTER":"FUSIL_SHOT","COIL_MEDIC":"WRENCH_ARC","SIGNAL_KEEPER":"SIGNAL_NEEDLE",
	"VINE_WARDEN":"ROOT_SLAM","LEAF_SEER":"ROOT_WISP","WIND_COURIER":"LEAF_ARROW","BLOOM_GUIDE":"BLOOM_SEED","THORN_CHANTER":"THORN_SEED",
	"RIDGE_JARL":"HAMMER_CRUSH","RUNE_ORACLE":"RUNE_CINDER","EMBER_CAVALIER":"EMBER_BLADE","HEARTH_KEEPER":"HEARTH_COAL","STORM_HERALD":"STORM_AXE",
	"TUNNEL_SENTINEL":"CHITIN_CLAW","ECHO_BINDER":"ECHO_SHARD","SPORE_STALKER":"DUAL_TALON","SPORE_GUIDE":"SPORE_DART","QUAKE_PRIEST":"SEISMIC_CHUNK",
}
const WORKERS := {"HUMAN":"WOOD_AXE","UNDEAD":"BONE_SPADE","MACHINE":"PICK_HOOK","FOREST":"RAKE_THRUST","HIGHLAND":"MINER_PICK","UNDERGROUND":"SHELL_PICK"}
const NAMES := {
	"MEMORIAL_WISP":"铭灯引魂","OATH_ARBALEST":"誓图重弩贯矢",
	"SWORD_FAN":"军刀扇斩","OATH_BLADE":"誓金阔刃","SHIELD_BASH":"盾缘冲击","LONG_PIKE":"长槊贯刺","CAVALRY_LANCE":"骑枪突刺",
	"BONE_HATCHET":"骨斧缺口斩","BONE_CLEAVER":"巨骨断头斩","RIVET_PUNCH":"铆拳冲压","VINE_SICKLE":"藤镰回勾","ANTLER_THRUST":"鹿角分叉刺",
	"HAMMER_CRUSH":"战锤崩岩","CHITIN_CLAW":"双钩甲爪","LIZARD_BITE":"蜥吻撕咬","COLOSSUS_HAMMER":"誓晶巨锤","SOUL_MAUL":"魂骸重槌",
	"ROOT_SLAM":"古根压击","RUNE_STOMP":"符脊震足","ABYSS_MAW":"深渊裂颚","DUAL_BLADE":"交错双刃","DUAL_TALON":"孢影三爪","EMBER_BLADE":"烬刃曳火",
	"CROSSBOW_BOLT":"重弩短矢","BONE_ARROW":"骨羽倒钩箭","LEAF_ARROW":"叶羽长箭","OATH_ARROW":"誓羽重箭","CRYSTAL_BULLET":"裂晶梭弹","FUSIL_SHOT":"猎铳铜弹",
	"HEAVY_CANNON":"重炮铁弹","AETHER_SHELL":"灵核穿甲弹","BOULDER":"抛石落砾","DRAGON_BREATH":"龙息火舌","ECHO_SHARD":"三棱回声针",
	"SPORE_DART":"孢囊毒刺","OATH_LANTERN":"誓灯光页","EMBER_SOUL":"灰魂烛火","COIL_ARC":"分叉电弧","ROOT_WISP":"根须飞叶",
	"RUNE_CINDER":"方符炉焰","ARCANE_LANCE":"星契晶芒","SOUL_FLAME":"亡魂幽焰","THORN_SEED":"荆刺蒺藜","BLOOM_SEED":"花瓣种簇",
	"STORM_AXE":"雷纹飞斧","SEISMIC_CHUNK":"地鸣碎碑","SIGNAL_NEEDLE":"讯叉脉冲","GRAVE_CHIME":"墓钟音栅","WRENCH_ARC":"扳手短弧","HEARTH_COAL":"炉心炭屑",
	"WOOD_AXE":"柴斧短劈","BONE_SPADE":"骨铲拍击","PICK_HOOK":"镐钩凿击","RAKE_THRUST":"木耙三齿","MINER_PICK":"矿镐尖击","SHELL_PICK":"壳足双镐","ROCK_FIST":"岩拳断层",
}
const MELEE := ["SWORD_FAN","OATH_BLADE","SHIELD_BASH","LONG_PIKE","CAVALRY_LANCE","BONE_HATCHET","BONE_CLEAVER","RIVET_PUNCH","VINE_SICKLE","ANTLER_THRUST","HAMMER_CRUSH","CHITIN_CLAW","LIZARD_BITE","COLOSSUS_HAMMER","SOUL_MAUL","ROOT_SLAM","RUNE_STOMP","ABYSS_MAW","DUAL_BLADE","DUAL_TALON","EMBER_BLADE","WOOD_AXE","BONE_SPADE","PICK_HOOK","RAKE_THRUST","MINER_PICK","SHELL_PICK","ROCK_FIST"]
const HEAVY := ["COLOSSUS_HAMMER","SOUL_MAUL","ROOT_SLAM","RUNE_STOMP","ABYSS_MAW","HEAVY_CANNON","AETHER_SHELL","DRAGON_BREATH","OATH_ARBALEST"]

static func _faction(unit: Dictionary) -> String:
	var faction := str(unit.get("faction_id","HUMAN"))
	if bool(unit.get("neutral",false)) or unit.has("series_id"):
		faction=str(unit.get("neutral_origin_faction_id",unit.get("origin_faction_id","")))
		if faction.is_empty(): faction=str({"ROCKKIN":"HIGHLAND","SPOREBROOD":"UNDERGROUND","ROAD_BAND":"HUMAN","THORN_WATCH":"FOREST","GRAVEBOUND":"UNDEAD","RUNE_WILD":"MACHINE"}.get(unit.get("neutral_series_id",unit.get("series_id","")),"HUMAN"))
	return faction if faction in FACTIONS else "HUMAN"

static func signature_for(unit: Dictionary) -> String:
	if RangedAV.supported(unit):return RangedAV.signature_for(unit)
	if MageAV.Data.has_hero(str(unit.get("hero_archetype",""))):return str(unit.hero_archetype).to_lower()+"_focus"
	if ExpansionAV.Data.has_hero(str(unit.get("hero_archetype",""))):return str(unit.hero_archetype).to_lower()+"_weapon"
	var type := str(unit.get("unit_type",""))
	if type=="hero": return str(HEROES.get(unit.get("hero_archetype","COMMANDER"),""))
	if type=="worker": return str(WORKERS.get(_faction(unit),""))
	# A neutral's actual body, not its camp role or numerical damage class,
	# carries the weapon. RUNE_WILD is explicitly a staff even when low-tier.
	var series := str(unit.get("neutral_series_id",unit.get("series_id","")))
	if series=="RUNE_WILD": return "RUNE_CINDER"
	if series=="SPOREBROOD" and float(unit.get("attack_range",0))>75: return "SPORE_DART"
	return str(TROOPS.get(type,TROOPS.get(str(unit.get("neutral_origin_unit_type",unit.get("origin_unit_type",""))),"")))

static func inspect(unit: Dictionary, pose: Dictionary) -> Dictionary:
	if RangedAV.supported(unit):return RangedAV.inspect_attack(unit,pose)
	if MageAV.Data.has_hero(str(unit.get("hero_archetype",""))):return MageAV.inspect_attack(unit,pose)
	if ExpansionAV.Data.has_hero(str(unit.get("hero_archetype",""))):return ExpansionAV.inspect_attack(unit,pose)
	var phase := float(pose.get("phase",0))
	if str(pose.get("action",""))!="ATTACK" or int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not is_finite(phase) or phase<0 or phase>=1: return {"supported":false}
	var signature := signature_for(unit)
	if signature.is_empty(): return {"supported":false}
	var faction := _faction(unit)
	var melee := signature in MELEE
	var heavy := signature in HEAVY
	return {"supported":true,"signature":signature,"label":str(NAMES[signature]),"profile":faction.to_lower()+"_weapon_"+signature.to_lower(),"faction":faction,"phase":phase,"family":"MELEE" if melee else "PROJECTILE","heavy":heavy,"visual_extent":Vector2.ONE*(72 if heavy else 48),"particle_cap":18 if heavy else 10,"max_actions":MAX_ACTIONS,"max_draw_operations":MAX_ACTIONS,"max_impacts":MAX_IMPACTS,"layers":["identity_windup","weapon_silhouette","identity_impact","pixel_debris"],"palette":PALETTES[faction].duplicate(),"attack_type":str(unit.get("last_action_attack_type",unit.get("attack_type",""))),"settled_only":true}

static func _poly(commands: Array, cells: Array, center: Vector2, factor: float, color: Color, angle: float=0.0) -> void:
	if commands.size()>=MAX_ACTIONS: return
	var points := PackedVector2Array()
	var quantum := maxf(1.0,roundf(factor))
	for cell: Vector2 in cells:
		var p := ((center+cell.rotated(angle)*factor)/quantum).round()*quantum
		if points.is_empty() or p!=points[-1]: points.append(p)
	if points.size()>1 and points[0]==points[-1]: points.remove_at(points.size()-1)
	if points.size()<3: return
	var area := 0.0
	for i: int in range(points.size()): area+=points[i].cross(points[(i+1)%points.size()])
	if absf(area)<0.5: return
	# Far zoom can merge the opposing notches of a barbed arrow onto one pixel.
	# Simplify only that collapsed contour rather than send a self-intersecting
	# polygon to Godot (or grow a shimmering anti-aliased sub-pixel outline).
	if factor<0.6 and Geometry2D.triangulate_polygon(points).is_empty():
		points=Geometry2D.convex_hull(points)
		if points.size()>1 and points[0]==points[-1]: points.remove_at(points.size()-1)
		if points.size()<3: return
	commands.append({"points":points,"color":color})

static func _stamp(commands: Array, cells: Array, center: Vector2, factor: float, color: Color, angle: float=0.0, core: Color=Color.TRANSPARENT) -> void:
	_poly(commands,cells,center,factor,INK,angle)
	_poly(commands,cells,center,factor*0.73,color,angle)
	if core.a>0: _poly(commands,[Vector2(-2,-2),Vector2(2,-2),Vector2(2,2),Vector2(-2,2)],center,factor,core)

static func _chip(commands: Array, center: Vector2, size: Vector2, factor: float, color: Color) -> void:
	_poly(commands,[Vector2(-size.x,-size.y),Vector2(size.x,-size.y),Vector2(size.x,size.y),Vector2(-size.x,size.y)],center,factor,color)

static func _blade(signature: String) -> Array:
	match signature:
		"SWORD_FAN": return [Vector2(-19,-13),Vector2(-9,-19),Vector2(5,-17),Vector2(18,-7),Vector2(22,5),Vector2(15,15),Vector2(15,4),Vector2(8,-7),Vector2(-4,-12)]
		"WOOD_AXE": return [Vector2(-10,-20),Vector2(4,-20),Vector2(17,-12),Vector2(18,-1),Vector2(8,5),Vector2(0,-3),Vector2(-13,-5),Vector2(-18,-13)]
		"OATH_BLADE": return [Vector2(-24,-15),Vector2(-12,-24),Vector2(3,-24),Vector2(20,-11),Vector2(27,5),Vector2(18,19),Vector2(19,2),Vector2(7,-12),Vector2(-8,-17)]
		"SHIELD_BASH": return [Vector2(-8,-17),Vector2(6,-17),Vector2(18,-10),Vector2(23,0),Vector2(18,10),Vector2(6,17),Vector2(-8,17),Vector2(-1,8),Vector2(4,0),Vector2(-1,-8)]
		"LONG_PIKE": return [Vector2(-24,-3),Vector2(8,-3),Vector2(8,-8),Vector2(29,0),Vector2(8,8),Vector2(8,3),Vector2(-24,3)]
		"CAVALRY_LANCE": return [Vector2(-30,-3),Vector2(8,-3),Vector2(8,-8),Vector2(34,0),Vector2(8,8),Vector2(8,3),Vector2(-30,3),Vector2(-21,8),Vector2(-32,8),Vector2(-39,3)]
		"ANTLER_THRUST": return [Vector2(-23,-3),Vector2(-4,-3),Vector2(5,-16),Vector2(8,-16),Vector2(4,-4),Vector2(18,-10),Vector2(22,-7),Vector2(10,-1),Vector2(28,0),Vector2(10,4),Vector2(19,13),Vector2(15,15),Vector2(0,4),Vector2(-23,4)]
		"BONE_HATCHET": return [Vector2(-16,-17),Vector2(-2,-24),Vector2(11,-21),Vector2(20,-12),Vector2(15,-7),Vector2(21,0),Vector2(12,9),Vector2(5,2),Vector2(7,-8),Vector2(-3,-15)]
		"BONE_CLEAVER": return [Vector2(-22,-25),Vector2(4,-29),Vector2(22,-14),Vector2(17,-8),Vector2(24,-1),Vector2(12,12),Vector2(5,7),Vector2(13,-5),Vector2(0,-16),Vector2(-19,-17)]
		"RIVET_PUNCH": return [Vector2(-21,-5),Vector2(-7,-5),Vector2(-7,-12),Vector2(9,-12),Vector2(9,-8),Vector2(20,-8),Vector2(20,8),Vector2(8,8),Vector2(8,12),Vector2(-7,12),Vector2(-7,5),Vector2(-21,5)]
		"VINE_SICKLE": return [Vector2(-20,-8),Vector2(-12,-20),Vector2(1,-22),Vector2(13,-14),Vector2(21,-3),Vector2(18,11),Vector2(6,19),Vector2(11,7),Vector2(10,-3),Vector2(3,-10),Vector2(-6,-13)]
		"HAMMER_CRUSH": return [Vector2(-7,-26),Vector2(7,-26),Vector2(7,-12),Vector2(19,-12),Vector2(19,5),Vector2(10,5),Vector2(6,13),Vector2(-6,13),Vector2(-10,5),Vector2(-19,5),Vector2(-19,-12),Vector2(-7,-12)]
		"ROCK_FIST": return [Vector2(-24,-10),Vector2(-14,-19),Vector2(7,-19),Vector2(20,-9),Vector2(24,8),Vector2(16,16),Vector2(-9,15),Vector2(-22,7)]
		"CHITIN_CLAW": return [Vector2(-24,-16),Vector2(-11,-16),Vector2(5,-8),Vector2(18,2),Vector2(23,15),Vector2(12,8),Vector2(0,-1),Vector2(-14,-6)]
		"LIZARD_BITE": return [Vector2(-21,-17),Vector2(0,-20),Vector2(23,-10),Vector2(27,-2),Vector2(18,-5),Vector2(15,1),Vector2(10,-5),Vector2(7,2),Vector2(1,-4),Vector2(-10,-5),Vector2(-20,-1)]
		"COLOSSUS_HAMMER": return [Vector2(-8,-32),Vector2(8,-32),Vector2(8,-17),Vector2(27,-17),Vector2(31,-10),Vector2(31,9),Vector2(20,9),Vector2(12,19),Vector2(-12,19),Vector2(-20,9),Vector2(-31,9),Vector2(-31,-10),Vector2(-27,-17),Vector2(-8,-17)]
		"SOUL_MAUL": return [Vector2(-23,-25),Vector2(-12,-30),Vector2(12,-30),Vector2(24,-24),Vector2(24,-5),Vector2(15,-5),Vector2(9,8),Vector2(0,15),Vector2(-9,8),Vector2(-15,-5),Vector2(-23,-5)]
		"ROOT_SLAM": return [Vector2(-25,7),Vector2(-23,-5),Vector2(-16,-15),Vector2(-10,-23),Vector2(-4,-20),Vector2(-9,-8),Vector2(0,-13),Vector2(10,-25),Vector2(16,-21),Vector2(10,-9),Vector2(23,-13),Vector2(29,-5),Vector2(19,5),Vector2(8,11)]
		"RUNE_STOMP": return [Vector2(-27,-8),Vector2(-18,-20),Vector2(13,-20),Vector2(27,-6),Vector2(27,9),Vector2(18,9),Vector2(11,17),Vector2(-12,17),Vector2(-18,9),Vector2(-27,9)]
		"ABYSS_MAW": return [Vector2(-31,-25),Vector2(-6,-27),Vector2(19,-14),Vector2(32,0),Vector2(23,-1),Vector2(19,7),Vector2(11,-3),Vector2(5,4),Vector2(-2,-8),Vector2(-13,-8),Vector2(-22,0),Vector2(-28,-4)]
		"PICK_HOOK","SHELL_PICK": return [Vector2(-22,-8),Vector2(-13,-19),Vector2(5,-19),Vector2(20,-9),Vector2(24,4),Vector2(16,-1),Vector2(8,-9),Vector2(-5,-12),Vector2(-15,-7)]
		"MINER_PICK": return [Vector2(-25,-5),Vector2(-13,-16),Vector2(4,-18),Vector2(17,-11),Vector2(27,2),Vector2(11,-5),Vector2(2,-10),Vector2(-11,-8)]
		"BONE_SPADE": return [Vector2(-8,-21),Vector2(8,-21),Vector2(10,-6),Vector2(15,3),Vector2(10,13),Vector2(0,18),Vector2(-10,13),Vector2(-15,3),Vector2(-10,-6)]
		"RAKE_THRUST": return [Vector2(-24,-3),Vector2(8,-3),Vector2(8,-14),Vector2(19,-14),Vector2(19,-10),Vector2(13,-10),Vector2(13,-3),Vector2(23,-3),Vector2(23,1),Vector2(13,1),Vector2(13,9),Vector2(19,9),Vector2(19,13),Vector2(8,13),Vector2(8,3),Vector2(-24,3)]
	return [Vector2(-18,-16),Vector2(-6,-23),Vector2(12,-17),Vector2(23,-2),Vector2(17,14),Vector2(12,3),Vector2(3,-10),Vector2(-8,-15)]

static func _arrow(signature: String) -> Array:
	match signature:
		"OATH_ARBALEST":return [Vector2(-34,-2),Vector2(10,-2),Vector2(10,-7),Vector2(26,0),Vector2(10,7),Vector2(10,2),Vector2(-34,2),Vector2(-40,8),Vector2(-39,2),Vector2(-44,0),Vector2(-39,-2),Vector2(-40,-8)]
		"CROSSBOW_BOLT": return [Vector2(-14,-3),Vector2(5,-3),Vector2(5,-6),Vector2(16,0),Vector2(5,6),Vector2(5,3),Vector2(-14,3),Vector2(-20,7),Vector2(-17,0),Vector2(-20,-7)]
		"BONE_ARROW": return [Vector2(-20,-2),Vector2(6,-2),Vector2(5,-7),Vector2(14,-3),Vector2(20,0),Vector2(14,3),Vector2(5,7),Vector2(6,2),Vector2(-20,2),Vector2(-25,8),Vector2(-25,3),Vector2(-29,0),Vector2(-25,-3),Vector2(-25,-8)]
		"LEAF_ARROW": return [Vector2(-24,-2),Vector2(8,-2),Vector2(7,-5),Vector2(19,0),Vector2(7,5),Vector2(8,2),Vector2(-24,2),Vector2(-30,9),Vector2(-30,2),Vector2(-35,0),Vector2(-30,-2),Vector2(-30,-9)]
		"OATH_ARROW": return [Vector2(-25,-3),Vector2(6,-3),Vector2(6,-8),Vector2(23,0),Vector2(6,8),Vector2(6,3),Vector2(-25,3),Vector2(-32,10),Vector2(-32,4),Vector2(-38,0),Vector2(-32,-4),Vector2(-32,-10)]
		"CRYSTAL_BULLET": return [Vector2(-13,-6),Vector2(0,-9),Vector2(17,0),Vector2(0,9),Vector2(-13,6),Vector2(-5,0)]
		"FUSIL_SHOT": return [Vector2(-10,-4),Vector2(7,-4),Vector2(13,-1),Vector2(13,2),Vector2(7,5),Vector2(-10,5)]
		"AETHER_SHELL": return [Vector2(-18,-7),Vector2(-5,-11),Vector2(11,-7),Vector2(23,0),Vector2(11,7),Vector2(-5,11),Vector2(-18,7),Vector2(-11,0)]
		"ECHO_SHARD": return [Vector2(-20,-5),Vector2(3,-8),Vector2(20,0),Vector2(3,8),Vector2(-20,5),Vector2(-9,0)]
		"SPORE_DART": return [Vector2(-18,-3),Vector2(-9,-9),Vector2(0,-10),Vector2(9,-5),Vector2(20,0),Vector2(9,5),Vector2(0,10),Vector2(-9,9),Vector2(-18,3)]
		"THORN_SEED": return [Vector2(-15,-5),Vector2(-13,-17),Vector2(-5,-10),Vector2(2,-10),Vector2(14,-19),Vector2(10,-6),Vector2(19,0),Vector2(10,5),Vector2(14,16),Vector2(3,10),Vector2(-3,18),Vector2(-6,7),Vector2(-17,10),Vector2(-11,0)]
		"STORM_AXE": return [Vector2(-17,-3),Vector2(-1,-3),Vector2(3,-15),Vector2(16,-14),Vector2(21,-7),Vector2(14,-4),Vector2(8,4),Vector2(15,10),Vector2(9,15),Vector2(-2,8),Vector2(-17,3)]
		"SEISMIC_CHUNK": return [Vector2(-12,-17),Vector2(5,-17),Vector2(16,-8),Vector2(15,9),Vector2(3,17),Vector2(-12,11),Vector2(-18,-3)]
		"BLOOM_SEED": return [Vector2(-4,-6),Vector2(4,-6),Vector2(7,-2),Vector2(7,3),Vector2(3,7),Vector2(-3,7),Vector2(-7,3),Vector2(-7,-2)]
		"ARCANE_LANCE": return [Vector2(-25,-2),Vector2(-6,-6),Vector2(-1,-12),Vector2(6,-5),Vector2(27,0),Vector2(6,5),Vector2(-1,12),Vector2(-6,6),Vector2(-25,2)]
		"OATH_LANTERN": return [Vector2(-16,-14),Vector2(-3,-14),Vector2(1,-9),Vector2(14,-12),Vector2(17,-7),Vector2(17,11),Vector2(4,15),Vector2(-1,10),Vector2(-14,12)]
		"SIGNAL_NEEDLE": return [Vector2(-21,-8),Vector2(-3,-8),Vector2(-3,-3),Vector2(21,-3),Vector2(21,3),Vector2(-3,3),Vector2(-3,8),Vector2(-21,8),Vector2(-21,4),Vector2(-9,4),Vector2(-9,-4),Vector2(-21,-4)]
		"GRAVE_CHIME": return [Vector2(-3,-20),Vector2(3,-20),Vector2(3,-14),Vector2(9,-10),Vector2(10,1),Vector2(16,8),Vector2(16,12),Vector2(-16,12),Vector2(-16,8),Vector2(-10,1),Vector2(-9,-10),Vector2(-3,-14)]
		"BOULDER","HEAVY_CANNON": return [Vector2(-13,-7),Vector2(-6,-14),Vector2(9,-12),Vector2(15,-2),Vector2(10,11),Vector2(-5,14),Vector2(-15,5)]
		"RUNE_CINDER": return [Vector2(-11,-12),Vector2(10,-12),Vector2(16,-5),Vector2(11,0),Vector2(13,10),Vector2(1,14),Vector2(-11,9),Vector2(-8,0),Vector2(-15,-5)]
		"ROOT_WISP": return [Vector2(-21,-4),Vector2(-8,-9),Vector2(2,-9),Vector2(19,-1),Vector2(6,11),Vector2(-4,10),Vector2(-7,4),Vector2(-18,8)]
		"EMBER_SOUL": return [Vector2(-10,6),Vector2(-10,-1),Vector2(-4,-6),Vector2(-5,-17),Vector2(2,-10),Vector2(7,-15),Vector2(10,-4),Vector2(7,6),Vector2(11,11),Vector2(-11,11)]
		"SOUL_FLAME": return [Vector2(-12,-4),Vector2(-10,-13),Vector2(-3,-17),Vector2(7,-15),Vector2(13,-9),Vector2(14,2),Vector2(8,10),Vector2(3,13),Vector2(-5,13),Vector2(-12,6)]
		"HEARTH_COAL": return [Vector2(-13,-5),Vector2(-6,-13),Vector2(7,-12),Vector2(14,-3),Vector2(11,8),Vector2(0,14),Vector2(-11,9)]
	return [Vector2(-13,-3),Vector2(-6,-8),Vector2(5,-6),Vector2(15,0),Vector2(5,6),Vector2(-6,8),Vector2(-13,3)]

static func _muzzle(commands: Array, origin: Vector2, signature: String, phase: float, factor: float, color: Color, angle: float) -> void:
	if phase>=0.3: return
	if signature in ["FUSIL_SHOT","CRYSTAL_BULLET","HEAVY_CANNON","AETHER_SHELL"]:
		_stamp(commands,[Vector2(0,-4),Vector2(10,-12),Vector2(7,-4),Vector2(25,0),Vector2(7,4),Vector2(10,12),Vector2(0,4)],origin,factor,color,angle)
		for i: int in range(2): _chip(commands,origin+Vector2(-7-i*5,-8-i*4).rotated(angle)*factor,Vector2(3+i,2+i),factor,Color("777b76",0.55))
	elif signature in ["COIL_ARC","SIGNAL_NEEDLE","WRENCH_ARC"]:
		_stamp(commands,[Vector2(-8,-13),Vector2(1,-13),Vector2(-3,-2),Vector2(9,-5),Vector2(1,14),Vector2(-1,3),Vector2(-9,5)],origin,factor,color,angle)
	elif signature=="DRAGON_BREATH":
		_stamp(commands,[Vector2(-5,-5),Vector2(9,-12),Vector2(15,-5),Vector2(23,-1),Vector2(14,5),Vector2(8,12),Vector2(-5,5)],origin,factor,color,angle)
	elif signature not in MELEE:
		_chip(commands,origin+Vector2(-6,-5)*factor,Vector2(2,3),factor,Color(color,0.65))
		_chip(commands,origin+Vector2(5,4)*factor,Vector2(3,2),factor,Color(color,0.65))

static func _projectile(commands: Array, origin: Vector2, impact: Vector2, entry: Dictionary, factor: float, main: Color, light: Color) -> void:
	var phase := float(entry.phase)
	var signature := str(entry.signature)
	var progress := clampf((phase-0.12)/0.56,0,1)
	var moving := origin.lerp(impact,progress)
	var angle := (impact-origin).angle() if impact.distance_squared_to(origin)>0.001 else 0.0
	_muzzle(commands,origin,signature,phase,factor,light,angle)
	if phase<0.12 or phase>=0.7: return
	if signature in ["BOULDER","SEISMIC_CHUNK"]: moving.y-=sin(progress*PI)*34*factor
	if signature=="DRAGON_BREATH":
		# Three interlocking tongues have a cone silhouette, never a fire orb.
		for i: int in range(3):
			var p := origin.lerp(moving,0.45+i*0.24)
			var shape := [Vector2(-18,-4),Vector2(-8,-10),Vector2(0,-8),Vector2(11,-14),Vector2(8,-3),Vector2(25,0),Vector2(8,3),Vector2(11,14),Vector2(0,8),Vector2(-8,10),Vector2(-18,4)]
			_stamp(commands,shape,p,factor*(0.55+i*0.17),Color("f2a148") if i<2 else Color("fff0ae"),angle)
	elif signature in ["COIL_ARC","WRENCH_ARC"]:
		for i: int in range(4):
			var p := origin.lerp(moving,0.25+i*0.23)
			_stamp(commands,[Vector2(-9,-4),Vector2(1,-9),Vector2(-1,-2),Vector2(10,-4),Vector2(0,10),Vector2(1,3),Vector2(-9,5)],p,factor*(0.7 if signature=="WRENCH_ARC" else 0.9),main,angle)
	elif signature in ["BLOOM_SEED","GRAVE_CHIME","OATH_LANTERN","SOUL_FLAME","EMBER_SOUL","HEARTH_COAL","MEMORIAL_WISP"]:
		_payload(commands,moving,signature,phase,factor,main,light,angle)
	else:
		var shape := _arrow(signature)
		_stamp(commands,shape,moving,factor*(0.82 if not bool(entry.heavy) else 1.1),main,angle,light if signature in ["AETHER_SHELL","ARCANE_LANCE","CRYSTAL_BULLET"] else Color.TRANSPARENT)
		if signature=="ECHO_SHARD":
			for signum: int in [-1,1]: _stamp(commands,shape,moving+Vector2(-12,signum*8).rotated(angle)*factor,factor*0.45,main,angle)
		if signature in ["BOULDER","SEISMIC_CHUNK","HEAVY_CANNON"]:
			_poly(commands,[Vector2(-6,-7),Vector2(2,-5),Vector2(4,1),Vector2(-5,-1)],moving,factor,light,angle)
		# Clustered short after-images, not a continuous vector ribbon.
		for i: int in range(3):
			var p := origin.lerp(moving,maxf(0,0.85-i*0.12))
			if signature in ["BONE_ARROW","LEAF_ARROW","CROSSBOW_BOLT","FUSIL_SHOT","OATH_ARBALEST"]:
				_chip(commands,p,Vector2(3-i*0.5,1),factor,Color(main,0.48-i*0.1))
			else: _chip(commands,p+Vector2(0,(i%2*2-1)*4).rotated(angle)*factor,Vector2(2.5-i*0.5,2.5-i*0.5),factor,Color(main,0.48-i*0.1))

static func _payload(commands: Array, point: Vector2, signature: String, phase: float, factor: float, main: Color, light: Color, angle: float) -> void:
	# These carriers deliberately do not share a fire-petal or eight-point star.
	if signature=="MEMORIAL_WISP":
		# A torn memorial lamp with a narrow pale flame; not the old bone arrow
		# or an enlarged copy of a hero's skull projectile. Pure event drawing.
		_poly(commands,[Vector2(-7,-10),Vector2(4,-10),Vector2(9,-5),Vector2(7,8),Vector2(-6,8),Vector2(-10,2)],point,factor,INK,angle)
		_poly(commands,[Vector2(-5,-7),Vector2(2,-7),Vector2(5,-3),Vector2(4,5),Vector2(-4,5),Vector2(-6,1)],point,factor,Color("8c779f"),angle)
		_poly(commands,[Vector2(-3,3),Vector2(-2,-3),Vector2(0,-9),Vector2(3,-2),Vector2(2,3)],point,factor,Color("eee2ec"),angle)
		for i: int in range(3):
			var p := point+Vector2(-15-i*7,sin(phase*TAU+i)*4).rotated(angle)*factor
			_chip(commands,p,Vector2(3-i*0.5,1.5),factor,Color("b4a0c5",0.65-i*0.15))
	elif signature=="BLOOM_SEED":
		for i: int in range(4):
			var offset := Vector2(8,0).rotated(i*PI/2+phase*0.5)
			_stamp(commands,[Vector2(-4,-3),Vector2(-2,-6),Vector2(2,-6),Vector2(5,-3),Vector2(5,3),Vector2(2,6),Vector2(-2,6),Vector2(-4,3)],point+offset*factor,factor,Color("d6d7a2"),i*PI/2)
		_stamp(commands,_arrow(signature),point,factor*0.7,Color("8f9c54"),0,light)
	elif signature=="GRAVE_CHIME":
		_stamp(commands,_arrow(signature),point,factor*0.85,main)
		_poly(commands,[Vector2(-12,6),Vector2(12,6),Vector2(10,10),Vector2(-10,10)],point,factor*0.85,INK)
		_chip(commands,point+Vector2(0,12)*factor,Vector2(2,4),factor,light)
		for i: int in range(2):
			var p := point+Vector2(19+i*12,0).rotated(angle)*factor
			for signum: int in [-1,1]:
				_poly(commands,[Vector2(0,-13),Vector2(4,-10),Vector2(7,-4),Vector2(4,-3),Vector2(2,-8),Vector2(0,-9)],p,factor,Color(main,0.75-i*0.18),angle+(PI if signum>0 else 0))
	elif signature=="OATH_LANTERN":
		_stamp(commands,_arrow(signature),point,factor,Color("e5d5a3"),angle)
		_poly(commands,[Vector2(-12,-9),Vector2(-4,-9),Vector2(0,-4),Vector2(-1,7),Vector2(-11,8)],point,factor,Color("fff1cb"),angle)
		_poly(commands,[Vector2(1,-5),Vector2(11,-8),Vector2(13,-5),Vector2(13,7),Vector2(4,10),Vector2(1,7)],point,factor,Color("b99b63"),angle)
		_poly(commands,[Vector2(-1,-7),Vector2(2,-5),Vector2(2,9),Vector2(-1,7)],point,factor,INK,angle)
		_chip(commands,point+Vector2(-6,-3).rotated(angle)*factor,Vector2(3,1),factor,Color("957748"))
	elif signature=="SOUL_FLAME":
		_stamp(commands,[Vector2(-3,-6),Vector2(-14,-6),Vector2(-23,-13),Vector2(-18,-2),Vector2(-31,4),Vector2(-15,8),Vector2(-2,6)],point,factor,Color(main,0.65),angle)
		_stamp(commands,_arrow(signature),point,factor,Color("d4bdcd"))
		_chip(commands,point+Vector2(-5,-4)*factor,Vector2(2,3),factor,INK)
		_chip(commands,point+Vector2(4,-4)*factor,Vector2(2,3),factor,INK)
		_poly(commands,[Vector2(-5,4),Vector2(5,4),Vector2(3,8),Vector2(-3,8)],point,factor,INK)
	elif signature=="EMBER_SOUL":
		_stamp(commands,_arrow(signature),point,factor,Color("c99788"))
		_poly(commands,[Vector2(-8,5),Vector2(8,5),Vector2(8,10),Vector2(-8,10)],point,factor,Color("6c5264"))
		_chip(commands,point+Vector2(0,1)*factor,Vector2(1,6),factor,INK)
		_poly(commands,[Vector2(-3,-4),Vector2(0,-11),Vector2(4,-3),Vector2(1,1)],point,factor,light)
		_chip(commands,point+Vector2(-14,-5-phase*10)*factor,Vector2(2,2),factor,Color(main,0.5))
	elif signature=="HEARTH_COAL":
		_stamp(commands,_arrow(signature),point,factor,Color("66504d"),angle)
		_poly(commands,[Vector2(-7,-5),Vector2(0,-8),Vector2(7,-3),Vector2(5,6),Vector2(-3,8),Vector2(-8,2)],point,factor,Color("e37f42"),angle)
		_poly(commands,[Vector2(-4,-5),Vector2(0,-1),Vector2(5,-3),Vector2(1,4),Vector2(-1,7),Vector2(-2,1)],point,factor,Color("ffe6a2"),angle)
		for i: int in range(3):
			var p := point+Vector2(-18-i*7,(i%2*2-1)*(4+i*2)).rotated(angle)*factor
			_chip(commands,p,Vector2(2,2),factor,Color("d68a4a",0.8-i*0.2))

static func _melee(commands: Array, origin: Vector2, impact: Vector2, entry: Dictionary, factor: float, main: Color, light: Color) -> void:
	var phase := float(entry.phase)
	if phase<0.08 or phase>=0.85: return
	var signature := str(entry.signature)
	var direction := impact-origin
	if direction.length_squared()<0.001: direction=Vector2.RIGHT
	var angle := direction.angle()
	var reach := minf(direction.length()*0.55,38*factor)
	var center := origin+direction.normalized()*reach
	var shape := _blade(signature)
	var rotation := angle
	if signature in ["LONG_PIKE","CAVALRY_LANCE","ANTLER_THRUST","RAKE_THRUST"]:
		center+=direction.normalized()*sin(clampf(phase/0.7,0,1)*PI)*10*factor
	else: rotation+=(-0.7+clampf((phase-0.1)/0.6,0,1)*1.2)
	if phase<0.2: main=Color(main,0.45); light=Color(light,0.55)
	_stamp(commands,shape,center,factor,main,rotation)
	if signature in ["DUAL_BLADE","DUAL_TALON","CHITIN_CLAW","LIZARD_BITE","ABYSS_MAW","SHELL_PICK"]:
		var second := _blade("CHITIN_CLAW" if signature in ["DUAL_TALON","SHELL_PICK"] else "SWORD_FAN" if signature=="DUAL_BLADE" else signature)
		var mirrored: Array = []
		for cell: Vector2 in second: mirrored.push_front(Vector2(cell.x,-cell.y))
		_stamp(commands,mirrored,center+Vector2(0,9).rotated(angle)*factor,factor*(0.9 if signature!="ABYSS_MAW" else 1),light,angle+0.18)
		if signature=="DUAL_TALON": _stamp(commands,_blade("CHITIN_CLAW"),center+Vector2(0,-9).rotated(angle)*factor,factor*0.85,main,angle-0.25)
	if signature in ["COLOSSUS_HAMMER","OATH_BLADE","EMBER_BLADE"]:
		for i: int in range(3):
			var p := center+Vector2(-12+i*9,-19+abs(i-1)*7).rotated(rotation)*factor
			_stamp(commands,[Vector2(-3,0),Vector2(0,-7),Vector2(3,0),Vector2(0,4)],p,factor,Color("f2a148") if signature=="EMBER_BLADE" else light)
	if signature in ["HAMMER_CRUSH","COLOSSUS_HAMMER","RUNE_STOMP","ROCK_FIST","RIVET_PUNCH","SOUL_MAUL","BONE_SPADE"]:
		_material_faces(commands,center,signature,factor,main,light,rotation)

static func _material_faces(commands: Array, point: Vector2, signature: String, factor: float, main: Color, light: Color, angle: float) -> void:
	if signature=="BONE_SPADE":
		_poly(commands,[Vector2(-6,-12),Vector2(-2,-12),Vector2(-2,1),Vector2(-8,7),Vector2(-10,3)],point,factor,light,angle)
		_poly(commands,[Vector2(1,-6),Vector2(4,-6),Vector2(4,2),Vector2(8,7),Vector2(0,12),Vector2(-3,9)],point,factor,main.darkened(0.35),angle)
		_poly(commands,[Vector2(-1,3),Vector2(2,3),Vector2(1,10),Vector2(-2,12)],point,factor,INK,angle)
	elif signature=="RUNE_STOMP":
		_poly(commands,[Vector2(-17,-10),Vector2(-11,-14),Vector2(9,-14),Vector2(15,-8),Vector2(9,-5),Vector2(-13,-5)],point,factor,light,angle)
		_poly(commands,[Vector2(11,-3),Vector2(19,-4),Vector2(19,6),Vector2(8,12),Vector2(8,5)],point,factor,main.darkened(0.4),angle)
		_poly(commands,[Vector2(-5,-3),Vector2(4,-3),Vector2(4,0),Vector2(0,0),Vector2(0,6),Vector2(-3,6),Vector2(-3,0),Vector2(-5,0)],point,factor,INK,angle)
	else:
		var broad := signature=="COLOSSUS_HAMMER" or signature=="SOUL_MAUL"
		var width := 17.0 if broad else 10.0
		_poly(commands,[Vector2(-width,-11),Vector2(width-2,-11),Vector2(width+1,-6),Vector2(-width,-6)],point,factor,light,angle)
		_poly(commands,[Vector2(width-2,-6),Vector2(width+4,-4),Vector2(width+4,3),Vector2(width-1,8),Vector2(width-2,0)],point,factor,main.darkened(0.4),angle)
		_poly(commands,[Vector2(-3,-6),Vector2(0,-6),Vector2(1,-2),Vector2(5,-2),Vector2(5,1),Vector2(-1,1)],point,factor,INK,angle)
		_chip(commands,point+Vector2(-width+3,-3).rotated(angle)*factor,Vector2(2,2),factor,light)

static func _impact(commands: Array, impact: Vector2, entry: Dictionary, factor: float, main: Color, light: Color, primary: bool) -> void:
	var phase := float(entry.phase)
	if phase<0.58 or phase>=0.98: return
	var signature := str(entry.signature)
	var age := (phase-0.58)/0.4
	var gain := 1.0 if primary else 0.65
	var color := Color(main,1-age*0.65)
	if signature in ["HAMMER_CRUSH","COLOSSUS_HAMMER","BOULDER","ROCK_FIST","RUNE_STOMP","SEISMIC_CHUNK","ROOT_SLAM","SOUL_MAUL","RIVET_PUNCH"]:
		# Broken radial fissures with missing pixels; never a damage-radius ring.
		for i: int in range(3):
			var angle := i*TAU/3.0+0.25
			_poly(commands,[Vector2(2,-2),Vector2(12,-2),Vector2(15,-7),Vector2(19,-7),Vector2(15,1),Vector2(9,3),Vector2(4,3)],impact,factor*gain*(0.8+age),Color("665a53",0.8-age*0.4),angle)
	elif signature in ["CHITIN_CLAW","DUAL_TALON","SHELL_PICK","LIZARD_BITE","ABYSS_MAW"]:
		for i: int in range(3):
			_poly(commands,[Vector2(-2,-11),Vector2(1,-11),Vector2(3,6),Vector2(0,11),Vector2(-1,2)],impact+Vector2((i-1)*6,0)*factor,factor*gain,Color(light,0.85-age*0.5),-0.45)
	elif signature=="HEARTH_COAL":
		for i: int in range(4):
			var p := impact+Vector2(8+age*18,0).rotated(i*PI/2+0.3)*factor*gain
			_stamp(commands,[Vector2(-4,-2),Vector2(-1,-5),Vector2(4,-2),Vector2(3,3),Vector2(-2,4)],p,factor*gain,Color("d58242",0.95-age*0.6),i*0.8)
	elif signature in ["HEAVY_CANNON","AETHER_SHELL","DRAGON_BREATH","RUNE_CINDER","EMBER_BLADE"]:
		_stamp(commands,[Vector2(-17,5),Vector2(-13,-5),Vector2(-8,-4),Vector2(-9,-17),Vector2(-2,-9),Vector2(4,-24),Vector2(8,-8),Vector2(16,-14),Vector2(13,0),Vector2(22,5),Vector2(12,12),Vector2(-9,13)],impact,factor*gain*(0.85+age*0.55),Color("f2a148",0.85-age*0.45))
		_stamp(commands,[Vector2(-7,5),Vector2(-5,-3),Vector2(1,-12),Vector2(6,-1),Vector2(10,5),Vector2(5,10),Vector2(-5,10)],impact,factor*gain,Color("fff0b4",0.9-age*0.5))
	elif signature=="BLOOM_SEED":
		for i: int in range(4):
			var p := impact+Vector2(8+age*17,0).rotated(i*PI/2+0.3)*factor*gain
			_stamp(commands,[Vector2(-4,-3),Vector2(-2,-5),Vector2(2,-5),Vector2(5,-2),Vector2(4,3),Vector2(0,5),Vector2(-4,3)],p,factor*gain*0.7,Color("d6d7a2",0.9-age*0.6),i*0.4)
	elif signature=="THORN_SEED":
		for i: int in range(3):
			var p := impact+Vector2(7+age*13,0).rotated(i*TAU/3)*factor*gain
			_stamp(commands,[Vector2(-2,6),Vector2(-2,-3),Vector2(3,-11),Vector2(3,-2),Vector2(7,0),Vector2(2,7)],p,factor*gain,color,i*TAU/3)
	elif signature in ["OATH_LANTERN","SOUL_FLAME","EMBER_SOUL","GRAVE_CHIME","MEMORIAL_WISP"]:
		_payload(commands,impact,signature,phase,factor*gain*(0.85+age*0.2),Color(main,0.85-age*0.5),Color(light,0.85-age*0.5),0.0)
	elif signature in ["SPORE_DART","ROOT_WISP"]:
		for i: int in range(4):
			var p := impact+Vector2(10+age*15,0).rotated(i*TAU/4+0.5)*factor*gain
			_stamp(commands,[Vector2(-5,-2),Vector2(0,-7),Vector2(5,-2),Vector2(2,4),Vector2(-2,4)],p,factor*gain*0.6,color,i*0.8)
	elif signature in ["COIL_ARC","WRENCH_ARC","SIGNAL_NEEDLE","STORM_AXE"]:
		for i: int in range(3):
			_poly(commands,[Vector2(2,-2),Vector2(12,-4),Vector2(10,1),Vector2(21,-1),Vector2(12,8),Vector2(14,3),Vector2(2,3)],impact,factor*gain,color,i*TAU/3+age*0.2)
	else:
		# Steel sparks and two material fragments are smaller than skill impacts.
		for i: int in range(3):
			var p := impact+Vector2(6+age*16,0).rotated(i*TAU/3-0.8)*factor*gain
			_poly(commands,[Vector2(-3,0),Vector2(0,-5),Vector2(3,0),Vector2(0,4)],p,factor*gain,Color(light,0.95-age*0.6),i)
	var fragments := 4 if bool(entry.heavy) else 2
	for i: int in range(fragments):
		var p := impact+Vector2(9+age*20,0).rotated(i*2.399+0.4)*factor*gain+Vector2(0,age*age*11)*factor
		_chip(commands,p,Vector2(2 if i%2==0 else 1,2),factor*gain,Color(main,0.85-age*0.6))

static func drawing_plan(point: Vector2, target: Vector2, unit: Dictionary, pose: Dictionary, factor: float=1.0, impact_points: Array=[]) -> Array:
	if RangedAV.supported(unit):return RangedAV.attack_plan(point,target,unit,pose,factor,impact_points)
	if MageAV.Data.has_hero(str(unit.get("hero_archetype",""))):return MageAV.attack_plan(point,target,unit,pose,factor,impact_points)
	if ExpansionAV.Data.has_hero(str(unit.get("hero_archetype",""))):return ExpansionAV.attack_plan(point,target,unit,pose,factor,impact_points)
	var commands: Array = []
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0 or factor>16: return commands
	var entry := inspect(unit,pose)
	if not bool(entry.get("supported",false)): return commands
	var origin := point+Vector2(0,-18)*factor
	var impact := target+Vector2(0,-10)*factor
	var colors: Array = entry.palette
	var main := Color(str(colors[1]))
	var light := Color(str(colors[2]))
	# Actor-specific anticipation/material replaces damage-class-only identity.
	# Reserve the existing weapon/settled impact budget; no new victims are found.
	FactionAV.append_attack(commands,origin,impact,unit,pose,factor,24)
	if entry.signature in ["BONE_ARROW","BONE_CLEAVER","BONE_HATCHET"]: main=Color("d8d4af");light=Color("fff0cf")
	if entry.signature in ["SPORE_DART","DUAL_TALON"]: main=Color("b6bd6b");light=Color("e7e7a6")
	if entry.family=="MELEE": _melee(commands,origin,impact,entry,factor,main,light)
	else: _projectile(commands,origin,impact,entry,factor,main,light)
	_impact(commands,impact,entry,factor,main,light,true)
	var unique: Array[Vector2] = [impact]
	for raw: Variant in impact_points:
		if unique.size()>=MAX_IMPACTS: break
		if typeof(raw) not in [TYPE_VECTOR2,TYPE_VECTOR2I]: continue
		var p := Vector2(raw)+Vector2(0,-10)*factor
		if not p.is_finite() or p in unique: continue
		unique.append(p)
		_impact(commands,p,entry,factor,main,light,false)
	return commands

static func draw(canvas: Object, point: Vector2, target: Vector2, unit: Dictionary, pose: Dictionary, factor: float=1.0, impact_points: Array=[]) -> bool:
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0 or factor>16 or not bool(inspect(unit,pose).get("supported",false)): return false
	var commands := drawing_plan(point,target,unit,pose,factor,impact_points)
	# A valid windup may intentionally have no visible pixels. It is handled,
	# and must not trigger an unrelated legacy fireball as a false fallback.
	for command: Dictionary in commands: canvas.draw_colored_polygon(command.points,command.color)
	return true
