extends RefCounted
## Final, narrow M67 old-roster replacements. No historical live multipliers.
## No HeroCatalog preload: Innates consumes guard_aura without a dependency cycle.
const VERSION:="m67-hero-identity-v2"
const GUARDS:={"BULWARK":"BULWARK_WARD","RIDGE_JARL":"RIDGE_WARD"}
const ROWS:={
	"BLOOM_SPRING":{"effect":"AURA","aura_heal":[1,2,3],"aura_move_speed_percent":[4,6,8],"aura_radius":[165,180,195],"max_targets":5},
	"SPORE_GLOW":{"effect":"AURA","aura_heal":[1,2,3],"aura_damage":[1,2,3],"aura_radius":[150,165,180],"max_targets":4},
	"COIL_BATTERY":{"effect":"AURA","aura_armor":[1,2,3],"aura_damage":[1,2,3],"aura_radius":[150,165,180],"max_targets":4},
	"HEARTH_WARMTH":{"effect":"AURA","aura_armor":[1,2,3],"aura_heal":[1,2,3],"aura_radius":[145,160,175],"max_targets":4},
	"STORM_CHANT":{"effect":"AURA","aura_damage":[1,2,3],"aura_move_speed_percent":[3,5,7],"aura_radius":[160,175,190],"max_targets":5},
	"THORN_BREEZE":{"effect":"AURA","aura_armor":[1,2,3],"aura_move_speed_percent":[4,6,8],"aura_radius":[150,165,180],"max_targets":4},
	"BULWARK_WARD":{"effect":"PASSIVE_GUARD","passive_armor":[1,2,3]},
	"RIDGE_WARD":{"effect":"PASSIVE_GUARD","passive_armor":[1,2,3]},
	"TUNNEL_SHOCK":{"effect":"HEAL","heal":[150,210,270],"ally_heal":[70,98,126],"ally_radius":125,"radius":125,"max_targets":2,"speed_bonus":1,"duration_ticks":[80,100,120],"mana_cost":30,"max_cooldown_ticks":220},
	"ASH_REQUIEM":{"effect":"RALLY","radius":180,"ally_radius":180,"max_targets":4,"skill_damage_percent":[24,32],"healing_percent":[18,24],"charges":2,"charge_kind":"PAID_SKILL","duration_ticks":[200,240],"requires_live_source":true,"mana_cost":[70,85],"max_cooldown_ticks":800},
	"BLOOM_SANCTUARY":{"effect":"RALLY","radius":210,"ally_radius":210,"max_targets":4,"move_speed_percent":[20,26],"mana_per_second":[2,3],"duration_ticks":[180,220],"requires_live_source":true,"mana_cost":[70,85],"max_cooldown_ticks":800},
	"HEARTH_REFUGE":{"effect":"RALLY","radius":155,"ally_radius":155,"max_targets":5,"ally_guard":[3,4],"attack_speed_percent":[20,28],"duration_ticks":[200,240],"requires_live_source":true,"mana_cost":[70,85],"max_cooldown_ticks":800},
	"SPORE_HAVEN":{"effect":"DAMAGE","target_mode":"POINT","delivery":"AREA","range":200,"radius":115,"max_targets":5,"damage":0,"status_kind":"SLOW","status_power":[40,48],"status_duration_ticks":[160,220],"mana_cost":[70,85],"max_cooldown_ticks":800},
	"QUAKE_SNARE":{"name":"地层解理","effect":"DAMAGE","target_mode":"POINT","delivery":"AREA","range":225,"radius":90,"max_targets":3,"damage":0,"status_kind":"ARMOR_BREAK","status_power":[2,3,4],"status_duration_ticks":[120,160,200],"mana_cost":27,"max_cooldown_ticks":320},
	"RALLY":{"name":"断约裁印","effect":"DAMAGE","target_mode":"POINT","delivery":"SINGLE","attack_type":"IMPACT","range":175,"radius":48,"max_targets":1,"damage":[440,594],"execute_percent":35,"mana_cost":[70,85],"max_cooldown_ticks":800},
	"GEAR_REPAIR":{"name":"余热焚场","effect":"DAMAGE","target_mode":"POINT","delivery":"AREA","attack_type":"ARCANE","range":245,"radius":85,"max_targets":3,"damage":0,"status_kind":"BURN","status_power":[75,81],"status_total_damage":[600,810],"status_duration_ticks":[160,200],"mana_cost":[70,85],"max_cooldown_ticks":900},
	"WIND_MEND":{"name":"风路横剪","effect":"DAMAGE","target_mode":"POINT","delivery":"LINE","attack_type":"PIERCE","range":280,"radius":0,"line_width":48,"max_targets":4,"secondary_damage_percent":55,"damage":[260,351],"mana_cost":[70,85],"max_cooldown_ticks":900},
}
const CLEAR:=["damage","raw_damage","base_damage","heal","ally_heal","ally_guard","ally_speed","ally_radius","ally_required_tag","cleanse_dot","control_duration_ticks","damage_bonus","damage_percent","attack_speed_percent","move_speed_percent","armor_bonus","speed_bonus","range_bonus","drain_percent","drain_percent_buff","execute_percent","duration_ticks","status_kind","status_power","status_duration_ticks","status_total_damage","line_width","chain_range","cone_width","aura_armor","aura_damage","aura_heal","aura_speed","aura_move_speed_percent","aura_radius","passive_armor","conditional_aura","skill_damage_percent","healing_percent","mana_per_second","charges","charge_kind","requires_live_source","reference_skill_id","reference_primary_rank3","budget_primary_raw","budget_per_cast_raw"]
const NOTES:={
	"BLOOM_SPRING":["低强度回复并帮助近处友军移动；不再与哀灯逐阶相同","移动中的量水师为撤离分水，牺牲纯回复和覆盖人数","分割队形或逼退持有者"],
	"SPORE_GLOW":["共生回复与普攻协作的小队光环","菌群分工换取少量进攻，受益人数比纯回复更少","离开小队半径或击倒持有者"],
	"COIL_BATTERY":["同时提供数值护甲与小量固定普攻的小队光环","夜班协作维持结构与武器，比单纯护甲光环覆盖更少","散开或击退支援者；不提供回蓝"],
	"HEARTH_WARMTH":["营炉同时恢复生命与提供护甲，覆盖较小的小队","小营地用站位换取复合防护，不再复制议长光环","分割部队并离开暖炉覆盖"],
	"STORM_CHANT":["普攻与行军速度协同光环","传令使帮助行军，而墓钟保留纯攻击与抑疗定位","切断传令者与队伍"],
	"THORN_BREEZE":["近处小队获得护甲与移动协同，不回复生命","空棘琴为同行者挡开枝刺；牺牲纯行军速度与人数换护甲","分割小队或用法术压制；不能当成治疗"],
	"BULWARK_WARD":["自身被动护甲；附近有其他友军结阵时才给队友控制抗性","托梁人留出口，减少永久甲换有条件护队；不改已有天赋","分开阵线，或迫使持有者脱离受益者"],
	"RIDGE_WARD":["自身被动护甲；静止扎稳后附近友军获得普攻减伤","守闸工付出机动和永久甲，保护靠近坝板的同伴","让持有者移动，或使用付费技能而非普攻突破"],
	"TUNNEL_SHOCK":["修补自己及最近两名友军，并给自己短时移动增益；不净化","搬巢者为幼群开路，不再复制藤垒的净化自疗","耗尽有限治疗后再追击；离群单位不受救援"],
	"ASH_REQUIEM":["近处友军接下来的有限付费伤害或治疗得到强化；不直接治疗","旧戏箱改写下两句台词，而非再释放一次群疗","等窗口结束或消耗其次数；击倒来源立即失效"],
	"BLOOM_SANCTUARY":["近处友军获得有限移速与持续回蓝；不恢复生命","量水师调回春汛供给，主动治疗留给新芽抚触","阻断回流窗口，分割友军或击倒来源"],
	"HEARTH_REFUGE":["近处友军获得护甲与攻速的有限营炉窗口；不群疗","营地让整队反击，不再复制议长的恢复盟誓","远程牵制或等待营炉窗口结束；持有者倒下立即失效"],
	"SPORE_HAVEN":["在选定地区对有限敌军施加减速；零直接伤害，不定身、不治疗","发酵菌丝延缓追兵，让队伍可退出共生地而非第二次群疗","仍可攻击施法；净化减速或绕开密集区"],
	"QUAKE_SNARE":["地层裂隙削减有限敌军数值护甲；不直接伤害、定身或中毒","地鸣祭司用解理为部队打开承力缝；把强制留人留给大招","仍可自由移动、攻击和施法；撤离后等待破甲结束"],
	"RALLY":["近距离裁决一个敌军；低生命目标承受更高撞击伤害，不治疗或强化友军","渡口账房收回被滥用的铜印；长官必须在急救与近身终结之间安排位置和蓝量","保护残血同伴或拉开裁印距离；普通治疗不能被当成第二个同类大招"],
	"GEAR_REPAIR":["火药罐在选定区域引发有限目标的奥术灼烧，可净化；没有即时伤害或破甲","齿轮猎手把未散去的枪管余热装进通风弹，牺牲即时爆发换完整灼烧收益；持续伤害遵循实际灼烧的奥术结算，不套火药护甲倍率","及时净化灼烧；分散队伍，迫使持续伤害在敌军阵亡前浪费，而不是等待不存在的延迟爆炸"],
	"WIND_MEND":["沿选定方向释放穿刺横剪，后续目标伤害衰减；没有自身强化或控制","送信者借同一条风路切开队列，移动蓄势和疾叶普攻之外另有方向与站位决策","错开直线站位或用前排承接首个命中；没有虚构冲刺、位移或持续强化"],
}
static func apply(skill:Dictionary,id:String,rank:int)->Dictionary:
	if not ROWS.has(id):return skill
	var result:=skill.duplicate(true)
	for key:String in CLEAR:result.erase(key)
	result.merge({"target_mode":"SELF","delivery":"AREA","range":0,"radius":0,"max_targets":1,"secondary_damage_percent":100,"passive":false,"mana_cost":0,"max_cooldown_ticks":0},true)
	var index:=clampi(maxi(1,rank)-1,0,1 if bool(result.ultimate) else 2)
	for key:String in ROWS[id]:
		var value:Variant=ROWS[id][key];result[key]=value[index] if value is Array else value
	result.passive=result.effect in ["AURA","PASSIVE_GUARD"]
	if result.effect=="AURA":
		for field:String in ["aura_armor","aura_damage","aura_heal","aura_speed","aura_move_speed_percent"]:
			if not result.has(field):result[field]=0
		result.radius=result.aura_radius
	if id in ["BULWARK_WARD","RIDGE_WARD"]:result["conditional_aura"]=guard_aura("BULWARK" if id=="BULWARK_WARD" else "RIDGE_JARL",maxi(1,rank))
	result["power_class"]="LEARNED_PASSIVE" if result.passive else "HEALING" if result.effect=="HEAL" else "GROUP_ENHANCEMENT" if result.effect=="RALLY" else "ARMOR_DEBUFF" if id=="QUAKE_SNARE" else "PURE_DOT" if id=="GEAR_REPAIR" else "PURE_DAMAGE" if id in ["RALLY","WIND_MEND"] else "WEAK_CONTROL"
	result["balance_version"]=VERSION;result["identity_version"]=VERSION
	result["calibration_reason"]=NOTES[id][1];result["design_note"]=NOTES[id][0];result["counterplay"]=NOTES[id][2]
	return result
static func guard_aura(kind:String,rank:int)->Dictionary:
	if not GUARDS.has(kind) or rank<1:return {}
	var r:=clampi(rank,1,3)-1
	return {"attribute":"control_resist_percent" if kind=="BULWARK" else "basic_damage_reduction_percent","amount":([6,9,12] if kind=="BULWARK" else [5,8,11])[r],"radius":135 if kind=="BULWARK" else 115,"max_targets":3,"condition":"FORMATION_2_ALLIES" if kind=="BULWARK" else "STATIONARY_2S"}
static func brief(id:String)->Dictionary:
	if not NOTES.has(id):return {}
	var effect:String=ROWS[id].effect
	return {"release":"学会后存活自动生效" if effect in ["AURA","PASSIVE_GUARD"] else "选定地面点施放" if id in ["SPORE_HAVEN","QUAKE_SNARE","RALLY","GEAR_REPAIR","WIND_MEND"] else "以自身为中心发动","form":effect,"content":NOTES[id][0],"decision":NOTES[id][1],"counterplay":NOTES[id][2],"presentation_status":"以实际观察器的阶段为准；说明不决定命中"}
