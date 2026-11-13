extends RefCounted
const BalanceM58 = preload("res://src/simulation/strategic_hero_balance_m58.gd")
## Retained M56 authored identity/baseline rows. The final M58 projection
## replaces numeric fields after legacy overlays, never multiplies live output
## twice. IDs, geometry, roles and progression gates remain owned by Heroes.
const VERSION := "m56-authored-skill-budgets-v1"
const PAYLOAD_FIELDS := ["damage","heal","ally_heal","ally_guard","ally_speed","ally_radius","ally_required_tag","cleanse_dot","control_duration_ticks","damage_bonus","damage_percent","attack_speed_percent","move_speed_percent","armor_bonus","speed_bonus","range_bonus","drain_percent","drain_percent_buff","execute_percent","duration_ticks","status_kind","status_power","status_duration_ticks","line_width","chain_range","cone_width"]
const ENTRIES := {
	# 誓图：星核决斗法师、穿阵射手、短促止戈辅助与区域守护。
	"RECOVER":{"heal":[180,240,300],"ally_heal":[65,85,105],"ally_radius":125,"radius":125,"max_targets":3,"ally_guard":[1,2,3],"duration_ticks":60,"mana_cost":28,"max_cooldown_ticks":180},
	"RALLY":{"heal":[230,290],"ally_heal":[125,165],"ally_radius":190,"radius":190,"max_targets":6,"ally_guard":[2,3],"duration_ticks":100,"mana_cost":[48,55],"max_cooldown_ticks":480},
	"SHIELD_SHOCK":{"heal":[190,250,310],"mana_cost":25,"max_cooldown_ticks":180},
	"BULWARK_RECOVER":{"effect":"STUN","target_mode":"POINT","delivery":"AREA","range":150,"radius":100,"max_targets":4,"damage":[80,110],"control_duration_ticks":[24,30],"mana_cost":[45,52],"max_cooldown_ticks":480},
	"STARFIRE":{"effect":"DAMAGE","target_mode":"POINT","delivery":"CONE","range":220,"radius":0,"cone_width":200,"max_targets":4,"damage":[110,145,180],"secondary_damage_percent":70,"mana_cost":24,"max_cooldown_ticks":140,"attack_type":"ARCANE"},
	"FROST_BIND":{"effect":"ROOT","target_mode":"POINT","delivery":"SINGLE","range":240,"radius":48,"max_targets":1,"damage":[90,125,160],"control_duration_ticks":[36,44,52],"mana_cost":28,"max_cooldown_ticks":180},
	"ARCANE_BURST":{"name":"星核裁决","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":250,"radius":48,"max_targets":1,"damage":[340,440],"status_kind":"SLOW","status_power":[30,40],"status_duration_ticks":40,"mana_cost":[48,58],"max_cooldown_ticks":480},
	"PIERCING_SHOT":{"effect":"DAMAGE","target_mode":"POINT","delivery":"LINE","range":300,"radius":0,"line_width":28,"max_targets":4,"damage":[130,170,210],"secondary_damage_percent":65,"mana_cost":23,"max_cooldown_ticks":140,"attack_type":"PIERCE"},
	"ARROW_RAIN":{"effect":"DAMAGE","target_mode":"POINT","delivery":"AREA","range":260,"radius":100,"max_targets":5,"damage":[85,110,135],"secondary_damage_percent":80,"mana_cost":28,"max_cooldown_ticks":200,"attack_type":"PIERCE"},
	"QUICKDRAW":{"effect":"DAMAGE_BUFF","damage_percent":[50,65],"attack_speed_percent":[15,20],"range_bonus":[24,36],"duration_ticks":140,"mana_cost":[45,55],"max_cooldown_ticks":480},
	"WHIRLWIND":{"effect":"STUN","target_mode":"POINT","delivery":"SINGLE","range":165,"radius":48,"max_targets":1,"damage":[105,145,185],"control_duration_ticks":[28,34,40],"mana_cost":25,"max_cooldown_ticks":180,"attack_type":"EDGE"},
	"BLOOD_PACT":{"effect":"ROOT","target_mode":"POINT","delivery":"AREA","range":210,"radius":120,"max_targets":4,"damage":[85,115],"secondary_damage_percent":70,"control_duration_ticks":[32,40],"mana_cost":[45,52],"max_cooldown_ticks":480},
	# 灰契：噬魂单体终结、生命转移与骨箭猎杀，不共享法师模板。
	"ASH_SHOCK":{"heal":[190,245,300],"cleanse_dot":true,"mana_cost":27,"max_cooldown_ticks":190},
	"ASH_MEND":{"effect":"ROOT","target_mode":"POINT","delivery":"CONE","range":175,"radius":0,"cone_width":220,"max_targets":4,"damage":[95,125],"secondary_damage_percent":70,"control_duration_ticks":[34,42],"drain_percent":20,"mana_cost":[48,55],"max_cooldown_ticks":500},
	"MOURN_BIND":{"effect":"ROOT","target_mode":"POINT","delivery":"AREA","range":230,"radius":85,"max_targets":3,"damage":[70,95,120],"secondary_damage_percent":80,"control_duration_ticks":[22,28,34],"mana_cost":27,"max_cooldown_ticks":190},
	"MOURN_FLARE":{"effect":"DAMAGE","target_mode":"POINT","delivery":"CHAIN","range":240,"radius":48,"chain_range":100,"max_targets":3,"damage":[115,150,185],"secondary_damage_percent":75,"drain_percent":20,"mana_cost":26,"max_cooldown_ticks":170},
	"MOURN_OATH":{"name":"噬魂归烬","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":245,"radius":48,"max_targets":1,"damage":[310,400],"drain_percent":[45,50],"mana_cost":[48,58],"max_cooldown_ticks":500},
	"CINDER_SHOT":{"effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":290,"radius":48,"max_targets":1,"damage":[160,205,250],"drain_percent":25,"mana_cost":23,"max_cooldown_ticks":150,"attack_type":"PIERCE"},
	"CINDER_FERVOR":{"effect":"DAMAGE_BUFF","damage_percent":[20,30,40],"damage_bonus":2,"drain_percent_buff":25,"duration_ticks":100,"mana_cost":18,"max_cooldown_ticks":180},
	"CINDER_MEND":{"name":"灰烬猎杀","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":300,"radius":48,"max_targets":1,"damage":[300,390],"execute_percent":[25,35],"drain_percent":25,"mana_cost":[45,55],"max_cooldown_ticks":500,"attack_type":"PIERCE"},
	"ASH_STITCH":{"heal":[145,190,235],"ally_heal":[105,135,165],"ally_radius":110,"radius":110,"max_targets":2,"cleanse_dot":true,"mana_cost":27,"max_cooldown_ticks":160},
	"ASH_REQUIEM":{"heal":[210,270],"ally_heal":[110,145],"ally_radius":205,"radius":205,"max_targets":6,"cleanse_dot":true,"mana_cost":[48,55],"max_cooldown_ticks":480},
	"GRAVE_CHAIN":{"effect":"ROOT","target_mode":"POINT","delivery":"CHAIN","range":230,"radius":48,"chain_range":95,"max_targets":3,"damage":[55,75,95],"secondary_damage_percent":80,"control_duration_ticks":[24,30,36],"drain_percent":15,"mana_cost":27,"max_cooldown_ticks":180},
	"GRAVE_TOLL":{"effect":"ROOT","target_mode":"POINT","delivery":"AREA","range":230,"radius":125,"max_targets":5,"damage":[70,95],"secondary_damage_percent":75,"control_duration_ticks":[28,34],"mana_cost":[48,55],"max_cooldown_ticks":500},
	# 铆炉：精准锁弹与链电双体系；医师是少目标重整而非泛用洪流。
	"COIL_SHOCK":{"heal":[210,270,330],"cleanse_dot":true,"mana_cost":28,"max_cooldown_ticks":200},
	"COIL_REPAIR":{"effect":"STUN","target_mode":"POINT","delivery":"CHAIN","range":170,"radius":48,"chain_range":85,"max_targets":3,"damage":[90,125],"secondary_damage_percent":75,"control_duration_ticks":[24,30],"mana_cost":[45,52],"max_cooldown_ticks":480},
	"VOLT_BIND":{"effect":"STUN","target_mode":"POINT","delivery":"SINGLE","range":245,"radius":48,"max_targets":1,"damage":[100,135,170],"control_duration_ticks":[26,32,38],"mana_cost":28,"max_cooldown_ticks":180},
	"VOLT_ARC":{"effect":"DAMAGE","target_mode":"POINT","delivery":"CHAIN","range":250,"radius":48,"chain_range":105,"max_targets":4,"damage":[110,145,180],"secondary_damage_percent":65,"mana_cost":28,"max_cooldown_ticks":180},
	"VOLT_NETWORK":{"effect":"DAMAGE","target_mode":"POINT","delivery":"CHAIN","range":250,"radius":48,"chain_range":110,"max_targets":5,"damage":[145,185],"secondary_damage_percent":70,"status_kind":"SLOW","status_power":25,"status_duration_ticks":40,"mana_cost":[50,60],"max_cooldown_ticks":500},
	"GEAR_SHOT":{"effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":290,"radius":48,"max_targets":1,"damage":[145,185,225],"status_kind":"ARMOR_BREAK","status_power":[2,3,4],"status_duration_ticks":60,"mana_cost":24,"max_cooldown_ticks":160,"attack_type":"GUNPOWDER"},
	"GEAR_FERVOR":{"effect":"DAMAGE_BUFF","damage_percent":[20,30,40],"damage_bonus":2,"range_bonus":30,"duration_ticks":100,"mana_cost":18,"max_cooldown_ticks":180},
	"GEAR_REPAIR":{"name":"破甲锁弹","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":300,"radius":48,"max_targets":1,"damage":[330,425],"status_kind":"ARMOR_BREAK","status_power":[3,4],"status_duration_ticks":100,"mana_cost":[48,58],"max_cooldown_ticks":500,"attack_type":"GUNPOWDER"},
	"COIL_MEND":{"heal":[165,210,255],"ally_heal":[120,150,180],"ally_radius":130,"radius":130,"max_targets":2,"ally_required_tag":"MACHINE","mana_cost":26,"max_cooldown_ticks":170},
	"COIL_OVERHAUL":{"heal":[220,280],"ally_heal":[200,260],"ally_radius":155,"radius":155,"max_targets":3,"ally_required_tag":"MACHINE","cleanse_dot":true,"mana_cost":[48,55],"max_cooldown_ticks":500},
	"SIGNAL_LOCK":{"effect":"STUN","target_mode":"POINT","delivery":"CHAIN","range":230,"radius":48,"chain_range":95,"max_targets":3,"damage":[60,80,100],"secondary_damage_percent":80,"control_duration_ticks":[18,22,26],"mana_cost":26,"max_cooldown_ticks":180},
	"SIGNAL_BLACKOUT":{"effect":"STUN","target_mode":"POINT","delivery":"AREA","range":235,"radius":115,"max_targets":5,"damage":[70,95],"secondary_damage_percent":70,"control_duration_ticks":[22,28],"mana_cost":[48,55],"max_cooldown_ticks":500},
	# 织叶：普通扇面/根阵，单体古根大招；游侠是自强化决斗者。
	"VINE_SHOCK":{"heal":[175,230,285],"cleanse_dot":true,"mana_cost":25,"max_cooldown_ticks":170},
	"VINE_MEND":{"effect":"ROOT","target_mode":"POINT","delivery":"AREA","range":175,"radius":130,"max_targets":5,"damage":[65,90],"secondary_damage_percent":75,"control_duration_ticks":[30,36],"mana_cost":[45,52],"max_cooldown_ticks":480},
	"LEAF_BIND":{"effect":"ROOT","target_mode":"POINT","delivery":"AREA","range":240,"radius":95,"max_targets":4,"damage":[55,75,95],"secondary_damage_percent":80,"control_duration_ticks":[26,32,38],"mana_cost":28,"max_cooldown_ticks":200},
	"LEAF_FLARE":{"effect":"DAMAGE","target_mode":"POINT","delivery":"CONE","range":225,"radius":0,"cone_width":230,"max_targets":5,"damage":[95,125,155],"secondary_damage_percent":65,"status_kind":"SLOW","status_power":20,"status_duration_ticks":35,"mana_cost":27,"max_cooldown_ticks":180},
	"LEAF_OATH":{"name":"古根囚印","effect":"ROOT","target_mode":"POINT","delivery":"SINGLE","range":250,"radius":48,"max_targets":1,"damage":[250,325],"control_duration_ticks":[56,64],"mana_cost":[48,58],"max_cooldown_ticks":520},
	"WIND_SHOT":{"effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":305,"radius":48,"max_targets":1,"damage":[150,195,240],"mana_cost":21,"max_cooldown_ticks":140,"attack_type":"PIERCE"},
	"WIND_FERVOR":{"effect":"DAMAGE_BUFF","damage_percent":[15,25,35],"damage_bonus":2,"move_speed_percent":[12,16,20],"duration_ticks":100,"mana_cost":17,"max_cooldown_ticks":180},
	"WIND_MEND":{"effect":"DAMAGE_BUFF","damage_percent":[45,60],"attack_speed_percent":[15,20],"move_speed_percent":[20,25],"duration_ticks":140,"mana_cost":[45,55],"max_cooldown_ticks":480},
	"BLOOM_TOUCH":{"heal":[120,155,190],"ally_heal":[70,90,110],"ally_radius":175,"radius":175,"max_targets":5,"cleanse_dot":true,"mana_cost":29,"max_cooldown_ticks":190},
	"BLOOM_SANCTUARY":{"heal":[200,260],"ally_heal":[120,155],"ally_radius":225,"radius":225,"max_targets":6,"cleanse_dot":true,"mana_cost":[50,58],"max_cooldown_ticks":500},
	"THORN_LASH":{"effect":"ROOT","target_mode":"POINT","delivery":"LINE","range":240,"radius":0,"line_width":48,"max_targets":4,"damage":[55,75,95],"secondary_damage_percent":75,"control_duration_ticks":[24,30,36],"mana_cost":27,"max_cooldown_ticks":190},
	"THORN_MAZE":{"effect":"ROOT","target_mode":"POINT","delivery":"AREA","range":245,"radius":140,"max_targets":5,"damage":[65,90],"secondary_damage_percent":75,"control_duration_ticks":[32,38],"mana_cost":[48,55],"max_cooldown_ticks":520},
	# 烬脊：熔锋单体处决、炉火大扇面与重甲贯穿，不只火色重染。
	"RIDGE_SHOCK":{"heal":[210,270,330],"mana_cost":28,"max_cooldown_ticks":200},
	"RIDGE_MEND":{"effect":"STUN","target_mode":"POINT","delivery":"LINE","range":220,"radius":0,"line_width":68,"max_targets":4,"damage":[100,135],"secondary_damage_percent":75,"control_duration_ticks":[22,28],"mana_cost":[48,55],"max_cooldown_ticks":500,"attack_type":"IMPACT"},
	"RUNE_BIND":{"effect":"STUN","target_mode":"POINT","delivery":"SINGLE","range":235,"radius":48,"max_targets":1,"damage":[110,145,180],"control_duration_ticks":[24,30,36],"status_kind":"ARMOR_BREAK","status_power":2,"status_duration_ticks":60,"mana_cost":28,"max_cooldown_ticks":190},
	"RUNE_FLARE":{"effect":"DAMAGE","target_mode":"POINT","delivery":"AREA","range":240,"radius":90,"max_targets":4,"damage":[95,125,155],"secondary_damage_percent":70,"status_kind":"BURN","status_power":[6,8,10],"status_duration_ticks":40,"mana_cost":27,"max_cooldown_ticks":180},
	"RUNE_OATH":{"effect":"DAMAGE","target_mode":"POINT","delivery":"CONE","range":245,"radius":0,"cone_width":240,"max_targets":5,"damage":[130,170],"secondary_damage_percent":65,"status_kind":"BURN","status_power":[8,11],"status_duration_ticks":60,"mana_cost":[50,60],"max_cooldown_ticks":520},
	"EMBER_SEAL":{"effect":"STUN","target_mode":"POINT","delivery":"SINGLE","range":155,"radius":48,"max_targets":1,"damage":[130,170,210],"control_duration_ticks":[22,28,34],"mana_cost":25,"max_cooldown_ticks":160,"attack_type":"EDGE"},
	"EMBER_SWEEP":{"effect":"DAMAGE","target_mode":"POINT","delivery":"LINE","range":175,"radius":0,"line_width":58,"max_targets":4,"damage":[105,140,175],"secondary_damage_percent":70,"status_kind":"BURN","status_power":[5,7,9],"status_duration_ticks":40,"mana_cost":25,"max_cooldown_ticks":160,"attack_type":"EDGE"},
	"EMBER_MEND":{"name":"熔锋决断","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":170,"radius":48,"max_targets":1,"damage":[320,420],"execute_percent":[25,35],"mana_cost":[45,55],"max_cooldown_ticks":500,"attack_type":"EDGE"},
	"HEARTH_MEND":{"heal":[175,225,275],"ally_heal":[80,105,130],"ally_radius":135,"radius":135,"max_targets":3,"ally_guard":[1,2,3],"duration_ticks":70,"mana_cost":28,"max_cooldown_ticks":180},
	"HEARTH_REFUGE":{"heal":[235,300],"ally_heal":[130,165],"ally_radius":170,"radius":170,"max_targets":5,"ally_guard":[2,3],"duration_ticks":100,"mana_cost":[48,55],"max_cooldown_ticks":500},
	"STORM_HAMMER":{"effect":"STUN","target_mode":"POINT","delivery":"LINE","range":235,"radius":0,"line_width":50,"max_targets":3,"damage":[65,90,115],"secondary_damage_percent":75,"control_duration_ticks":[18,22,26],"mana_cost":27,"max_cooldown_ticks":180},
	"STORM_VERDICT":{"effect":"STUN","target_mode":"POINT","delivery":"CHAIN","range":240,"radius":48,"chain_range":100,"max_targets":4,"damage":[90,120],"secondary_damage_percent":75,"control_duration_ticks":[24,30],"mana_cost":[48,55],"max_cooldown_ticks":500},
	# 穴鸣：链缚/晶线的小技能、内爆大招、双单体刃客与毒雾控场。
	"TUNNEL_SHOCK":{"heal":[175,230,285],"cleanse_dot":true,"mana_cost":25,"max_cooldown_ticks":170},
	"TUNNEL_MEND":{"effect":"ROOT","target_mode":"POINT","delivery":"CONE","range":185,"radius":0,"cone_width":230,"max_targets":5,"damage":[70,95],"secondary_damage_percent":75,"control_duration_ticks":[30,36],"mana_cost":[45,52],"max_cooldown_ticks":480},
	"ECHO_BIND":{"effect":"ROOT","target_mode":"POINT","delivery":"CHAIN","range":235,"radius":48,"chain_range":95,"max_targets":3,"damage":[55,75,95],"secondary_damage_percent":80,"control_duration_ticks":[24,30,36],"status_kind":"POISON","status_power":[4,6,8],"status_duration_ticks":40,"mana_cost":28,"max_cooldown_ticks":190},
	"ECHO_FLARE":{"effect":"DAMAGE","target_mode":"POINT","delivery":"LINE","range":250,"radius":0,"line_width":40,"max_targets":4,"damage":[100,135,170],"secondary_damage_percent":70,"status_kind":"POISON","status_power":[5,7,9],"status_duration_ticks":40,"mana_cost":27,"max_cooldown_ticks":180},
	"ECHO_OATH":{"name":"晶核坍缩","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":240,"radius":48,"max_targets":1,"damage":[300,390],"status_kind":"POISON","status_power":[12,16],"status_duration_ticks":60,"mana_cost":[48,58],"max_cooldown_ticks":500},
	"SPORE_SEAL":{"effect":"STUN","target_mode":"POINT","delivery":"SINGLE","range":150,"radius":48,"max_targets":1,"damage":[125,165,205],"control_duration_ticks":[20,26,32],"status_kind":"POISON","status_power":[5,7,9],"status_duration_ticks":40,"mana_cost":25,"max_cooldown_ticks":170,"attack_type":"EDGE"},
	"SPORE_SWEEP":{"effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","range":165,"radius":48,"max_targets":1,"damage":[160,205,250],"execute_percent":25,"mana_cost":23,"max_cooldown_ticks":160,"attack_type":"EDGE"},
	"SPORE_MEND":{"effect":"DAMAGE_BUFF","damage_percent":[55,70],"attack_speed_percent":[10,15],"move_speed_percent":[15,20],"duration_ticks":140,"mana_cost":[45,55],"max_cooldown_ticks":480},
	"SPORE_REMEDY":{"heal":[130,170,210],"ally_heal":[75,100,125],"ally_radius":165,"radius":165,"max_targets":4,"cleanse_dot":true,"mana_cost":27,"max_cooldown_ticks":180},
	"SPORE_HAVEN":{"heal":[190,250],"ally_heal":[110,145],"ally_radius":200,"radius":200,"max_targets":6,"cleanse_dot":true,"speed_bonus":1,"duration_ticks":80,"mana_cost":[48,55],"max_cooldown_ticks":480},
	"QUAKE_SNARE":{"effect":"ROOT","target_mode":"POINT","delivery":"AREA","range":225,"radius":90,"max_targets":3,"damage":[55,75,95],"secondary_damage_percent":80,"control_duration_ticks":[26,32,38],"status_kind":"POISON","status_power":[4,5,6],"status_duration_ticks":40,"mana_cost":27,"max_cooldown_ticks":190},
	"QUAKE_SEAL":{"effect":"ROOT","target_mode":"POINT","delivery":"AREA","range":230,"radius":135,"max_targets":5,"damage":[65,90],"secondary_damage_percent":75,"control_duration_ticks":[30,36],"status_kind":"POISON","status_power":[5,7],"status_duration_ticks":40,"mana_cost":[48,55],"max_cooldown_ticks":500},
}

static func apply(skill: Dictionary, id: String, rank: int) -> Dictionary:
	if not ENTRIES.has(id): return BalanceM58.apply(skill,id,rank,ENTRIES)
	var result := skill.duplicate(true)
	for key: String in PAYLOAD_FIELDS: result.erase(key)
	result.merge({"effect":"HEAL","target_mode":"SELF","delivery":"AREA","range":0,"radius":0,"max_targets":1,"secondary_damage_percent":100,"attack_type":"ARCANE","passive":false},true)
	for key: String in ENTRIES[id]:
		var value: Variant=ENTRIES[id][key]
		result[key]=value[clampi(maxi(1,rank)-1,0,value.size()-1)] if value is Array else value
	result["variety_version"]=VERSION
	result["presentation_style"]=str(result.source_faction).to_lower()+"_"+str(result.delivery).to_lower()
	return BalanceM58.apply(result,id,rank,ENTRIES)
