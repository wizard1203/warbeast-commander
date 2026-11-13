extends RefCounted
## M65 self-built defensive identities. Base/site weapons deliberately retain
## the established single-target PIERCE budget; no free splash from ownership.
## Detached quotes only: World owns payment, construction and actual hits.
const VERSION := "gold-frontier-faction-towers-v2"
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
# Frozen V2 weapon references, before V3 army changes. Technology is applied
# by World after this base budget, never by looking up a current ranged troop.
const DEFENSE_REFERENCES := {
	"HUMAN":{"damage":30,"attack_cooldown_ticks":30},
	"UNDEAD":{"damage":32,"attack_cooldown_ticks":31},
	"MACHINE":{"damage":32,"attack_cooldown_ticks":31},
	"FOREST":{"damage":33,"attack_cooldown_ticks":29},
	"HIGHLAND":{"damage":33,"attack_cooldown_ticks":32},
	"UNDERGROUND":{"damage":32,"attack_cooldown_ticks":29}}

static func reference_stats(faction: String) -> Dictionary:
	return DEFENSE_REFERENCES.get(faction,DEFENSE_REFERENCES.HUMAN).duplicate(true)
const PROFILES := {
	"HUMAN":{"id":"HUMAN","label":"誓桥弩楼","material":"雨湿斜撑木、青瓷补线、横弩与借印旗架","attack_type":"PIERCE","cost":{"FOOD":0,"MATERIAL":380,"ESSENCE":0},"upgrade_cost":{"FOOD":0,"MATERIAL":320,"ESSENCE":0},"range":364,"cooldown_ticks":26,"dps_scale":1.05,"splash_dps_scale":0.0,"splash_radius":0,"splash_max_targets":0,"hp_scale":1.0,"armor_delta":0,"work":500,"counterplay":"稳定单体远射；重甲抵挡穿刺，绕开正面或用攻城器械拆解。"},
	"UNDEAD":{"id":"UNDEAD","label":"铭灯塔","material":"防潮矮基、开缝铭灯、裂钟黑铜与铭牌骨片","attack_type":"ARCANE","cost":{"FOOD":0,"MATERIAL":395,"ESSENCE":0},"upgrade_cost":{"FOOD":0,"MATERIAL":335,"ESSENCE":0},"range":315,"cooldown_ticks":30,"dps_scale":0.92,"splash_dps_scale":0.0,"splash_radius":0,"splash_max_targets":0,"hp_scale":1.0,"armor_delta":0,"work":520,"counterplay":"奥术单点针对重甲；斗篷、魔抗与远程攻城可克制。"},
	"MACHINE":{"id":"MACHINE","label":"铆炉炮台","material":"开检修盖的铆钉炮座、侧挂锅炉、排热槽","attack_type":"GUNPOWDER","cost":{"FOOD":0,"MATERIAL":445,"ESSENCE":0},"upgrade_cost":{"FOOD":0,"MATERIAL":380,"ESSENCE":0},"range":322,"cooldown_ticks":38,"dps_scale":0.68,"splash_dps_scale":0.20,"splash_radius":42,"splash_max_targets":2,"hp_scale":1.0,"armor_delta":0,"work":580,"counterplay":"主目标旁最多两名地面敌人受到炮片；分散阵形与飞行规避溅射。"},
	"FOREST":{"id":"FOREST","label":"候鸟棘台","material":"架空分叉木台、候鸟羽架、绷紧棘弓与贝叶水槽","attack_type":"PIERCE","cost":{"FOOD":0,"MATERIAL":310,"ESSENCE":0},"upgrade_cost":{"FOOD":0,"MATERIAL":270,"ESSENCE":0},"range":385,"cooldown_ticks":24,"dps_scale":0.88,"splash_dps_scale":0.0,"splash_radius":0,"splash_max_targets":0,"hp_scale":0.85,"armor_delta":-1,"work":440,"counterplay":"便宜、射程长，但单体DPS和耐久较低；贴近拆台。"},
	"HIGHLAND":{"id":"HIGHLAND","label":"裂岩震塔","material":"厚玄武层基、炉钉、短臂抛石架、霜边泄热口","attack_type":"IMPACT","cost":{"FOOD":0,"MATERIAL":440,"ESSENCE":0},"upgrade_cost":{"FOOD":0,"MATERIAL":380,"ESSENCE":0},"range":301,"cooldown_ticks":40,"dps_scale":0.70,"splash_dps_scale":0.23,"splash_radius":45,"splash_max_targets":2,"hp_scale":1.20,"armor_delta":1,"work":600,"counterplay":"耐久高、近程撞击溅射；昂贵且短射程，分散后用远程器械拆除。"},
	"UNDERGROUND":{"id":"UNDERGROUND","label":"壳刃哨","material":"半埋甲片、偏心壳刃轮、通气孔、独立低辉菌室","attack_type":"EDGE","cost":{"FOOD":0,"MATERIAL":330,"ESSENCE":0},"upgrade_cost":{"FOOD":0,"MATERIAL":290,"ESSENCE":0},"range":294,"cooldown_ticks":22,"dps_scale":1.0,"splash_dps_scale":0.0,"splash_radius":0,"splash_max_targets":0,"hp_scale":0.90,"armor_delta":-1,"work":460,"counterplay":"廉价、近程连续壳刃单点；生命与护甲偏低，重甲与远程有效。"},
}

static func profile(faction: String) -> Dictionary:
	return PROFILES.get(faction,PROFILES.HUMAN).duplicate(true)

static func construction_quote(faction: String) -> Dictionary:
	var item := profile(faction)
	return {"label":item.label,"material":item.material,"cost":item.cost.duplicate(true),"hp":roundi(1000.0*float(item.hp_scale)),"armor":4+int(item.armor_delta),"work":int(item.work),"duration_ticks":int(item.work),"radius":24,"armor_type":"FORTIFIED","attack_type":item.attack_type}

static func upgrade_quote(faction: String) -> Dictionary:
	var item := profile(faction)
	return {"target_tier":2,"label":item.label,"cost":item.upgrade_cost.duplicate(true),"duration_ticks":500,"max_hp":roundi(1350.0*float(item.hp_scale)),"armor":6+int(item.armor_delta)}

static func defense_stats(faction: String, building_kind: String, tower_level: int, ranged_stats: Dictionary, equivalent: float) -> Dictionary:
	# Keep the argument for old call-site compatibility, intentionally ignore
	# current troop stats. They are no longer defense authority.
	var reference:=reference_stats(faction)
	var original_cooldown := maxi(1,int(reference.attack_cooldown_ticks))
	var result := {"damage":maxi(1,roundi(float(reference.damage)*equivalent)),"attack_cooldown_ticks":original_cooldown,"attack_range":336,"attack_type":"PIERCE","splash_damage":0,"splash_radius":0,"splash_max_targets":0,"splash_layers":[],"tower_identity":"","tower_material":"","tower_level":clampi(tower_level,1,2)}
	if building_kind != "TOWER": return result
	var item := profile(faction)
	var cooldown := int(item.cooldown_ticks)
	var budget := float(reference.damage)*equivalent*float(cooldown)/float(original_cooldown)
	result.merge({"damage":maxi(1,roundi(budget*float(item.dps_scale))),"attack_cooldown_ticks":cooldown,"attack_range":int(item.range),"attack_type":item.attack_type,"splash_damage":roundi(budget*float(item.splash_dps_scale)),"splash_radius":int(item.splash_radius),"splash_max_targets":int(item.splash_max_targets),"splash_layers":["GROUND"] if int(item.splash_max_targets)>0 else [],"tower_identity":item.label,"tower_material":item.material},true)
	return result

static func catalog() -> Dictionary:
	return {"version":VERSION,"profiles":PROFILES.duplicate(true),"free_site_defense_damage_cadence_unchanged":true,"range_multiplier":1.4,"splash_center":"actual_primary_target_position","splash_primary_excluded":true,"splash_max_targets":2}
