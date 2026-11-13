extends RefCounted
## Final army-scale additions. Does not import the public catalog or simulation.
const VERSION:="m68-six-pure-damage-mages-v1"
const IDS:=["SUNGLASS_SCRIBE","CINDER_TESTATOR","FLUX_BOMBARDIER","POLLEN_COMET","OBSIDIAN_CANTOR","MYCELIAL_CATALYST"]
const ULTIMATES:=["SUNGLASS_FALLING_INDEX","CINDER_FINAL_CODICIL","FLUX_SATURATION_CORE","POLLEN_COMET_PROCESSION","OBSIDIAN_NIGHT_FAN","MYCELIAL_SPORE_DOWNPOUR"]
# name/title/faction/body/HP/AD/armor/range/interval/speed/MP/three skills
const ROWS:={
	"SUNGLASS_SCRIBE":["照书","日镜审绘师","HUMAN","HUMANOID",590,18,0,195,26,6,285,["SUNGLASS_FOLDED_RAY","SUNGLASS_LIGHT_SHEAR","SUNGLASS_FALLING_INDEX"]],
	"CINDER_TESTATOR":["灰牒","遗火遗嘱官","UNDEAD","BONE",615,17,0,180,27,5,300,["CINDER_LINGERING_CLAUSE","CINDER_SCATTERED_PAGES","CINDER_FINAL_CODICIL"]],
	"FLUX_BOMBARDIER":["弧轧","磁通炮术士","MACHINE","MACHINE",650,19,1,185,28,5,270,["FLUX_BORE_LANCE","FLUX_RELAY_FORK","FLUX_SATURATION_CORE"]],
	"POLLEN_COMET":["流穗","流萤织星者","FOREST","HUMANOID",555,16,0,205,25,8,285,["POLLEN_FIREFLY_FAN","POLLEN_LONE_COMET","POLLEN_COMET_PROCESSION"]],
	"OBSIDIAN_CANTOR":["玄烬","黑曜咏炉人","HIGHLAND","HUMANOID",695,20,1,165,29,5,270,["OBSIDIAN_GLASS_POOL","OBSIDIAN_CINDER_SEAM","OBSIDIAN_NIGHT_FAN"]],
	"MYCELIAL_CATALYST":["沫蚀","菌酸裂化师","UNDERGROUND","MULTILEG",580,17,0,190,26,7,300,["MYCELIAL_ACID_VEIN","MYCELIAL_ACID_KERNEL","MYCELIAL_SPORE_DOWNPOUR"]],
}
const STORIES:={
	"SUNGLASS_SCRIBE":{"origin":"照书曾在盐堤档案馆用分光镜辨认被晒褪的救济名册；后来发现所谓无人领取的田地，都有被擦掉的名字。","turn":"她将审计镜从议事厅抬到战场，用分折的日光揭开被军令遮住的路径，却拒绝把镜面变成审讯刑具。","motive":"让证据在权势之外也能被看见。","flaw":"相信看得足够清楚就会获得公正，常忘记证人需要护卫。","silhouette":"不对称三片日镜背架、细长书签杖、宽方遮光帽","counterplay":"远距才能发挥天赋，近身与侧袭迫使她放弃镜阵；没有控制和回复。"},
	"CINDER_TESTATOR":{"origin":"灰牒替归名炉庭中选择终止旧誓的人写遗嘱；他保管的不是灵魂，而是仍能由本人撤回的最后一句话。","turn":"某位亡者的安息许可被反复出售，他把交易簿烧成投递火种，让欠下的暴力不能永远藏在章印后。","motive":"使结束成为一种权利，不让死者继续偿付旧债。","flaw":"为免遗言失真而事事亲自传递，常离安全队列太远。","silhouette":"悬空残页披帘、灰匣长柄印、低垂无面纸冠","counterplay":"持续火可净化；逼退他后再治疗，可削弱末章的收尾威胁。"},
	"FLUX_BOMBARDIER":{"origin":"弧轧是磁轨拆解场的女技术员，靠听线圈失谐判断废料里是否藏着仍在运行的救援信标。","turn":"工坊要求把幸存信标一并熔炼，她把它们接成不受总线控制的回路，背着报废配电架离开。","motive":"让每个被系统抛弃的信号都有一次回应。","flaw":"擅长短促过载，却常高估线圈能承受多久的连续放电。","silhouette":"双偏置磁环肩架、扁口线圈炮、竖直绝缘背鳍","counterplay":"慢步速和长普攻间隔；错开穿线、截断跳电，每第二次消耗蓝量的法术触发天赋。"},
	"POLLEN_COMET":{"origin":"流穗追踪夜行昆虫的迁徙，为迁林者寻找没有树根记忆的新路；她把光点当作生命而不是神谕。","turn":"当议庭要求用固定星图禁迁，她带着仍会改变航迹的萤群离开，允许每一季的答案不同。","motive":"保护尚未被记录的未来，不替它取唯一的名字。","flaw":"总想跟住每一道微光，面对陷阱也会多走一步。","silhouette":"开放花萼斗篷、三束弯曲萤须、细柄彗籽投杖","counterplay":"最脆却灵活；天赋要先冒险普攻同目标，分散可削弱连锁大招。"},
	"OBSIDIAN_CANTOR":{"origin":"玄烬替高地废窑唱降温调，不为祈福，只为让值夜学徒听见窑壁将裂的节拍。","turn":"贵族要求加速出炉的祭礼烧伤了工匠，他封住名窑，把裂出的黑曜玻璃收进可随时打开的歌匣。","motive":"让承压者决定何时停火。","flaw":"坚信稳住呼吸就能稳住局面，容易错过转场。","silhouette":"方口陶歌匣、错层黑曜胸片、弧背碎玻扇","counterplay":"定点蓄势而无护盾，迫使走位会断天赋；短距扇面大招暴露明显。"},
	"MYCELIAL_CATALYST":{"origin":"沫蚀负责清理被弃矿脉中的金属毒盐；她的菌酸既不能治病，也不把死去的矿工变成新劳力。","turn":"洞群为保住产量想封死受污染的支洞，她让菌群分解封门，替沉默的居民打开出口。","motive":"让被耗尽的土地与生命能够停止被索取。","flaw":"习惯等待缓慢分解，容易低估突发的直接冲击。","silhouette":"四足矮身、两只釉面酸囊、分叉玻璃滴管冠","counterplay":"主要收益在可净化毒伤；同次技能伤到三名不同敌人才恢复少量蓝量，散开与急救能拖过孢雨。"},
}
const SKILLS:={
	"SUNGLASS_FOLDED_RAY":{"name":"折日裁光","delivery":"SINGLE","range":290,"radius":48,"max_targets":1,"damage":[260,364,468],"mana_cost":32,"max_cooldown_ticks":240,"motif":"folded_sun_needle","material":"GLASS_REFRACTION"},
	"SUNGLASS_LIGHT_SHEAR":{"name":"剪光长签","delivery":"LINE","range":310,"line_width":38,"radius":0,"max_targets":4,"damage":[140,196,252],"secondary_damage_percent":70,"mana_cost":34,"max_cooldown_ticks":280,"motif":"razor_bookmark_beam","material":"INK_SEAL"},
	"SUNGLASS_FALLING_INDEX":{"name":"落镜索引","delivery":"AREA","range":270,"radius":108,"max_targets":5,"damage":[310,419],"secondary_damage_percent":80,"mana_cost":[75,90],"max_cooldown_ticks":900,"motif":"falling_mirror_index","material":"GLASS_REFRACTION"},
	"CINDER_LINGERING_CLAUSE":{"name":"余火附款","delivery":"SINGLE","range":255,"radius":48,"max_targets":1,"damage":[90,126,162],"status_kind":"BURN","status_total_damage":[160,224,288],"status_duration_ticks":[120,160,200],"mana_cost":32,"max_cooldown_ticks":280,"motif":"sealed_ember_clause","material":"ASH_RIBBON"},
	"CINDER_SCATTERED_PAGES":{"name":"散页炭潮","delivery":"CONE","range":210,"cone_width":180,"radius":0,"max_targets":3,"damage":[170,238,306],"secondary_damage_percent":70,"mana_cost":35,"max_cooldown_ticks":320,"motif":"charred_page_fan","material":"BONE_LANTERN"},
	"CINDER_FINAL_CODICIL":{"name":"焚尽末章","delivery":"SINGLE","range":260,"radius":48,"max_targets":1,"damage":[690,932],"execute_percent":[20,25],"mana_cost":[80,95],"max_cooldown_ticks":800,"motif":"last_testament_cinder_seal","material":"GHOST_AFTERIMAGE"},
	"FLUX_BORE_LANCE":{"name":"磁穿导枪","delivery":"LINE","range":280,"line_width":30,"radius":0,"max_targets":3,"damage":[220,308,396],"secondary_damage_percent":60,"mana_cost":32,"max_cooldown_ticks":260,"motif":"split_coil_bore","material":"RIVET_SPARK"},
	"FLUX_RELAY_FORK":{"name":"旁路分电","delivery":"CHAIN","range":255,"radius":48,"chain_range":105,"max_targets":4,"damage":[150,210,270],"secondary_damage_percent":75,"mana_cost":34,"max_cooldown_ticks":300,"motif":"relay_switch_fork","material":"CIRCUIT_TRACE"},
	"FLUX_SATURATION_CORE":{"name":"饱和磁核","delivery":"AREA","range":250,"radius":100,"max_targets":5,"damage":[340,459],"secondary_damage_percent":75,"mana_cost":[80,95],"max_cooldown_ticks":900,"motif":"saturation_iron_blossom","material":"PRESSURE_SMOKE"},
	"POLLEN_FIREFLY_FAN":{"name":"萤尾散弧","delivery":"CONE","range":220,"cone_width":165,"radius":0,"max_targets":3,"damage":[185,259,333],"secondary_damage_percent":75,"mana_cost":32,"max_cooldown_ticks":280,"motif":"firefly_tail_fan","material":"PETAL_SWARM"},
	"POLLEN_LONE_COMET":{"name":"独行彗籽","delivery":"SINGLE","range":285,"radius":48,"max_targets":1,"damage":[315,441,567],"mana_cost":40,"max_cooldown_ticks":360,"motif":"lone_pollen_comet","material":"RAIN_THREAD"},
	"POLLEN_COMET_PROCESSION":{"name":"万点离巢","delivery":"CHAIN","range":270,"radius":48,"chain_range":110,"max_targets":5,"damage":[330,446],"secondary_damage_percent":70,"mana_cost":[80,95],"max_cooldown_ticks":900,"motif":"migrating_comet_procession","material":"PETAL_SWARM"},
	"OBSIDIAN_GLASS_POOL":{"name":"碎镜炉池","delivery":"AREA","range":240,"radius":78,"max_targets":4,"damage":[160,224,288],"secondary_damage_percent":80,"mana_cost":32,"max_cooldown_ticks":280,"motif":"black_glass_pool","material":"RUNE_STONE"},
	"OBSIDIAN_CINDER_SEAM":{"name":"窑缝长烬","delivery":"LINE","range":255,"line_width":38,"radius":0,"max_targets":3,"damage":0,"status_kind":"BURN","status_total_damage":[230,322,414],"status_duration_ticks":[120,160,200],"mana_cost":38,"max_cooldown_ticks":360,"motif":"kiln_seam_cinders","material":"EMBER_SCALE"},
	"OBSIDIAN_NIGHT_FAN":{"name":"黑曜开夜","delivery":"CONE","range":190,"cone_width":215,"radius":0,"max_targets":4,"damage":[450,608],"secondary_damage_percent":70,"mana_cost":[85,100],"max_cooldown_ticks":800,"motif":"obsidian_night_fan","material":"RUNE_STONE"},
	"MYCELIAL_ACID_VEIN":{"name":"酸脉分流","delivery":"LINE","range":260,"line_width":42,"radius":0,"max_targets":3,"damage":[115,161,207],"secondary_damage_percent":70,"status_kind":"POISON","status_total_damage":[90,126,162],"status_duration_ticks":[120,160,200],"mana_cost":34,"max_cooldown_ticks":300,"motif":"branching_acid_vein","material":"CRYSTAL_CHIP"},
	"MYCELIAL_ACID_KERNEL":{"name":"浓酸核珠","delivery":"SINGLE","range":270,"radius":48,"max_targets":1,"damage":[285,399,513],"mana_cost":36,"max_cooldown_ticks":300,"motif":"ceramic_acid_kernel","material":"SPORE_MIST"},
	"MYCELIAL_SPORE_DOWNPOUR":{"name":"蚀穹孢雨","delivery":"AREA","range":260,"radius":100,"max_targets":5,"damage":0,"status_kind":"POISON","status_total_damage":[420,567],"status_duration_ticks":[160,200],"mana_cost":[75,90],"max_cooldown_ticks":900,"motif":"hollow_spore_downpour","material":"SPORE_MIST"},
}
const GROWTH:={
	"SUNGLASS_SCRIBE":{"max_hp":30,"damage_numerator":1,"damage_denominator":1,"armor_every":5,"max_mana":14},
	"CINDER_TESTATOR":{"max_hp":34,"damage_numerator":1,"damage_denominator":1,"armor_every":5,"max_mana":15},
	"FLUX_BOMBARDIER":{"max_hp":36,"damage_numerator":3,"damage_denominator":2,"armor_every":5,"max_mana":12},
	"POLLEN_COMET":{"max_hp":28,"damage_numerator":1,"damage_denominator":1,"armor_every":6,"max_mana":13},
	"OBSIDIAN_CANTOR":{"max_hp":39,"damage_numerator":1,"damage_denominator":1,"armor_every":4,"max_mana":12},
	"MYCELIAL_CATALYST":{"max_hp":31,"damage_numerator":1,"damage_denominator":1,"armor_every":6,"max_mana":15},
}
const RATIONALES:={
	"SUNGLASS_SCRIBE":"远距天赋与长线投递换取低生命、低普攻及缓慢护甲成长；MP用于三伤害法术。",
	"CINDER_TESTATOR":"慢速且火伤可净化，略多生命与MP；单体终结没有吸血、防护或硬控。",
	"FLUX_BOMBARDIER":"机械外壳带一点护甲和生命，代价是慢脚步、最慢普攻及较低MP成长。",
	"POLLEN_COMET":"高机动与灵活投递，以最低生命和护甲成长支付；普攻只服务天赋而非主输出。",
	"OBSIDIAN_CANTOR":"短距施法和定点天赋获得较高生命成长，但没有治疗、位移或护盾；MP不兼得最高。",
	"MYCELIAL_CATALYST":"可净化的延时输出需要MP与站位；少量多目标返蓝不回本，脆皮、护甲成长慢。",
}
const INNATES:={
	"SUNGLASS_SCRIBE":{"name":"远镜校准","percent":12,"growth":1,"description":"目标距离自己至少170时，消耗蓝量的技能直接伤害提高{P}%；不放大持续伤害。"},
	"CINDER_TESTATOR":{"name":"未燃首句","percent":10,"growth":1,"description":"目标在受击前生命不少于70%时，消耗蓝量的技能直接伤害提高{P}%；不作用于持续伤害。"},
	"FLUX_BOMBARDIER":{"name":"双拍过载","percent":16,"growth":1,"description":"每第二次消耗蓝量施法，对最多两名不同敌人的直接伤害提高{P}%；不增加持续伤害。"},
	"POLLEN_COMET":{"name":"萤路回认","percent":16,"growth":1,"description":"自己在过去3秒普攻过的同一目标，受到自己消耗蓝量的技能直接伤害提高{P}%；只记最近目标。"},
	"OBSIDIAN_CANTOR":{"name":"息炉稳调","percent":14,"growth":1,"description":"连续静止2秒后，消耗蓝量的技能直接伤害提高{P}%；移动后失效。"},
	"MYCELIAL_CATALYST":{"name":"三岔回收","amount":4,"growth":0.5,"description":"同一次消耗蓝量的伤害技能直接命中三名不同敌人后，返还{P}蓝量，每次施法仅一次；仅造成持续伤害的技能不触发。"},
}
static func has_hero(id:String)->bool:return ROWS.has(id)
static func owner(id:String)->String:
	for hero:String in IDS:
		if id in ROWS[hero][11]:return hero
	return ""
static func raw_profile(hero:String)->Dictionary:
	if not has_hero(hero):return {}
	var r:Array=ROWS[hero]
	return {"id":hero,"name":r[0],"title":r[1],"faction_id":r[2],"role_id":"MAGE","role":"法师·纯伤害","body_kind":r[3],"attack_layers":["GROUND","AIR"],"stats":{"label":r[1],"max_hp":r[4],"damage":r[5],"armor":r[6],"attack_range":r[7],"attack_cooldown_ticks":r[8],"speed":r[9],"max_mana":r[10],"radius":14,"population":5,"attack_type":"CHAOS","armor_type":"SACRED","hp_regen_per_second":1.0},"skill_ids":r[11].duplicate(),"visual_archetype":hero,"story":STORIES[hero].duplicate(true),"identity_version":VERSION}
static func skill(id:String,rank:int)->Dictionary:
	if not SKILLS.has(id):return {}
	var ultimate:=id in ULTIMATES
	var cap:=2 if ultimate else 3
	if rank<0 or rank>cap:return {}
	var result:={"id":id,"effect":"DAMAGE","target_mode":"POINT","delivery":"AREA","range":0,"radius":0,"max_targets":1,"secondary_damage_percent":100,"attack_type":"ARCANE","target_layers":["GROUND","AIR"],"passive":false,"level":rank,"max_level":cap,"ultimate":ultimate,"learned":rank>0,"required_hero_level":([5,8][mini(rank,1)] if ultimate else 1),"source_faction":ROWS[owner(id)][2],"balance_version":VERSION,"power_class":"PURE_DAMAGE"}
	for field:String in SKILLS[id]:
		var value:Variant=SKILLS[id][field]
		result[field]=value[maxi(1,rank)-1] if value is Array else value
	if result.has("status_total_damage"):result["status_power"]=float(result.status_total_damage)*20.0/float(result.status_duration_ticks)
	result["family"]="cataclysm" if ultimate else "bolt"
	result["emblem"]="lantern" if result.source_faction=="UNDEAD" else "gear" if result.source_faction=="MACHINE" else "leaf" if result.source_faction=="FOREST" else "rootclaw" if result.source_faction=="UNDERGROUND" else "blade"
	result["presentation_style"]=str(result.source_faction).to_lower()+"_"+str(result.motif)
	result["design_brief"]={"interaction":"付费纯伤害投递；没有控制、治疗或自强化。"+("直接与持续预算分开，持续状态可净化，刷新不叠总量。" if result.has("status_kind") else "后续目标按公布衰减结算。"),"counterplay":STORIES[owner(id)].counterplay,"version":VERSION}
	return result
static func growth(hero:String)->Dictionary:return GROWTH.get(hero,{}).duplicate(true)
static func rationale(hero:String)->String:return str(RATIONALES.get(hero,""))
static func innate_growth(hero:String)->Dictionary:
	var p:Dictionary=INNATES[hero]
	return {"amount" if p.has("amount") else "percent":{"base":p.get("amount",p.get("percent",0)),"per_level":p.growth}}
static func innate_profile(hero:String,level:int)->Dictionary:
	var p:Dictionary=INNATES[hero].duplicate(true)
	var field:="amount" if p.has("amount") else "percent"
	var value:=float(p[field])+float(p.growth)*float(clampi(level,1,8)-1)
	p.merge({"id":"INNATE_"+hero,"archetype":hero,"passive":true,"mana_cost":0,"learnable":false,"level":clampi(level,1,8),"max_level":8,"automatic_level":true,"growth":innate_growth(hero),"values":{field:value},"version":VERSION},true)
	p.description=str(p.description).replace("{P}","%.1f"%value)+"\n随英雄升级增强，无需学习或消耗蓝量。"
	return p
