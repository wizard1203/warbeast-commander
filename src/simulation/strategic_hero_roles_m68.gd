extends RefCounted
## Final, army-scale roles. Presentation never owns these values.
## Two old PHYSICAL heroes become ranged; new melee casters/warriors stay intact.
const VERSION:="m68-ranged-role-budget-v1"
const IDS:=["EMBER_CAVALIER","SPORE_STALKER"]
const STATS:={
	"EMBER_CAVALIER":{"label":"投烬猎长","max_hp":720,"damage":29,"armor":1,"attack_range":215,"attack_cooldown_ticks":22,"speed":7},
	"SPORE_STALKER":{"label":"伏隙弩手","max_hp":630,"damage":27,"armor":0,"attack_range":205,"attack_cooldown_ticks":19,"speed":8},
}
const STORIES:={
	"EMBER_CAVALIER":"焰脊放下裂谷骑团的重刃，使用可重复装填炉砂的投矛器替车队清出高处火线。第三击的烬火仍依附真实普攻，不能凭站远额外触发。",
	"SPORE_STALKER":"孢纹把验脉短刃改装成背负双槽生物弩，以多足稳定试剂囊。她隔着裂隙射击，但穴群夹击仍需要另一名友军贴近受害者，不是自带的安全增伤。",
}
const ROWS:={
	"EMBER_SEAL":{"name":"坠烬钉矛","effect":"STUN","target_mode":"POINT","delivery":"SINGLE","attack_type":"PIERCE","range":260,"radius":48,"max_targets":1,"damage":[145,203,261],"control_duration_ticks":[40,55,70],"mana_cost":27,"max_cooldown_ticks":320},
	"EMBER_SWEEP":{"name":"炉砂穿廊","effect":"DAMAGE","target_mode":"POINT","delivery":"LINE","attack_type":"PIERCE","range":275,"radius":0,"line_width":36,"max_targets":3,"damage":[110,154,198],"secondary_damage_percent":70,"status_kind":"BURN","status_total_damage":[12.0,16.8,21.6],"status_duration_ticks":[120,160,200],"mana_cost":27,"max_cooldown_ticks":180},
	"EMBER_MEND":{"name":"终炉重矛","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","attack_type":"PIERCE","range":280,"radius":48,"max_targets":1,"damage":[440,594],"execute_percent":[25,35],"mana_cost":[70,85],"max_cooldown_ticks":800},
	"SPORE_SEAL":{"name":"闭孔钉刺","effect":"STUN","target_mode":"POINT","delivery":"SINGLE","attack_type":"PIERCE","range":240,"radius":48,"max_targets":1,"damage":0,"control_duration_ticks":[70,90,110],"mana_cost":27,"max_cooldown_ticks":480},
	"SPORE_SWEEP":{"name":"验脉穿刺","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","attack_type":"PIERCE","range":255,"radius":48,"max_targets":1,"damage":[180,252,324],"execute_percent":25,"mana_cost":25,"max_cooldown_ticks":180},
	"SPORE_MEND":{"name":"裂隙追猎","effect":"DAMAGE_BUFF","target_mode":"SELF","delivery":"AREA","attack_type":"ARCANE","range":0,"radius":0,"max_targets":1,"damage_percent":[55,70],"attack_speed_percent":[20,25],"duration_ticks":[200,240],"mana_cost":[70,85],"max_cooldown_ticks":800},
}
const PAYLOAD:=["damage","raw_damage","base_damage","heal","ally_heal","ally_guard","ally_speed","ally_radius","ally_required_tag","damage_bonus","damage_percent","attack_speed_percent","move_speed_percent","armor_bonus","speed_bonus","range_bonus","drain_percent","drain_percent_buff","execute_percent","control_duration_ticks","status_kind","status_power","status_total_damage","status_duration_ticks","duration_ticks","cleanse_dot","line_width","chain_range","cone_width","secondary_damage_percent","attack_charges","charge_consumer","charges","charge_kind","skill_damage_percent","healing_percent","mana_regen_per_second","mana_per_second","requires_live_source","passive_armor","passive","aura_armor","aura_damage","aura_heal","aura_speed","aura_move_speed_percent","aura_radius","conditional_aura","reference_skill_id","reference_primary_rank3","budget_primary_raw","budget_per_cast_raw"]
static func apply_profile(kind:String,profile:Dictionary)->Dictionary:
	if kind not in IDS or profile.is_empty():return profile
	var result:=profile.duplicate(true)
	result.stats.merge(STATS[kind],true)
	result["attack_layers"]=["GROUND","AIR"]
	result["title"]=str(STATS[kind].label)
	result["role"]="射手·物理输出"
	result["role_id"]="PHYSICAL"
	result["ranged_role_version"]=VERSION
	result["story_m68"]=STORIES[kind]
	result["description"]="%s。%s\n擅长远程进攻，生命与护甲较低。占5人口，拥有神圣护甲，每秒恢复1生命。\n%s\n天赋·%s：%s"%[result.role,STORIES[kind].get_slice("。",0)+"。",result.growth_description,result.innate.name,result.innate.description]
	return result
static func apply_skill(skill:Dictionary,id:String,rank:int)->Dictionary:
	if not ROWS.has(id) or skill.is_empty():return skill
	var result:=skill.duplicate(true);var row:Dictionary=ROWS[id]
	for key:String in PAYLOAD:result.erase(key)
	var r:=maxi(1,rank)
	for key:String in row:
		var value:Variant=row[key]
		result[key]=value[mini(r-1,value.size()-1)] if value is Array else value
	result["target_layers"]=["GROUND","AIR"]
	result["passive"]=false
	result["ranged_role_version"]=VERSION
	if result.has("status_total_damage"):result["status_power"]=float(result.status_total_damage)*20.0/float(result.status_duration_ticks)
	result["presentation_style"]="m68_ranged_"+id.to_lower()
	result["budget_primary_raw"]=float(result.get("damage",result.get("damage_percent",0)))
	result["budget_per_cast_raw"]=float(result.get("damage",0))*(1.0+float(result.get("max_targets",1)-1)*float(result.get("secondary_damage_percent",100))/100.0)+float(result.get("status_total_damage",0))*float(result.max_targets)
	return result
