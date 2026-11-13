extends RefCounted
## M66 additions only. Final authored numbers, never inputs to legacy multipliers.
## No simulation, RNG, timers, presentation imports or mutable match authority.
const VERSION := "m66-new-hero-authority-v1"
const SKILL_VERSION := "m67-individual-new-hero-kits-v1"
const IDS := ["OATH_REAVER","BRIDGE_VANGUARD","RELIC_REAVER","OSSUARY_KNIGHT","PISTON_FENCER","RIVET_LEGIONARY","THORN_REAVER","ANTLER_WARRIOR","SLAG_DANCER","BASALT_CHAMPION","PRISM_MANTIS","CARAPACE_WARRIOR"]
const ULTIMATES := ["OATH_LAST_WITNESS","BRIDGE_LOAD_BEARER","RELIC_UNFINISHED_DUEL","OSSUARY_PROCESSION","PISTON_DEAD_CENTER","RIVET_WORKING_PRESSURE","THORN_GRAFT_RUPTURE","ANTLER_RUT_SEASON","SLAG_QUENCH_VERDICT","BASALT_FAULT_STANCE","PRISM_REFRACTION_CUT","CARAPACE_LAYERED_MOLT"]
# Canonical level-one values are already army-scale: do not multiply by M53.
# name/title/faction/role/body/HP/attack/armor/interval/speed/MP/three skills.
const ROWS := {
	"OATH_REAVER":["凭霄","断页剑师","HUMAN","MELEE_CASTER","HUMANOID",780,31,1,19,7,210,["OATH_NOTCH","OATH_EDGE_PLEDGE","OATH_LAST_WITNESS"]],
	"BRIDGE_VANGUARD":["榫岸","渡桩先锋","HUMAN","WARRIOR","HUMANOID",930,27,3,23,6,195,["BRIDGE_CROSSBEAM","BRIDGE_LOCK_BRACE","BRIDGE_LOAD_BEARER"]],
	"RELIC_REAVER":["折名","遗物决斗者","UNDEAD","MELEE_CASTER","BONE",750,32,1,20,7,225,["RELIC_NAME_HOOK","RELIC_COLD_EDGE","RELIC_UNFINISHED_DUEL"]],
	"OSSUARY_KNIGHT":["迟舟","送行骨骑","UNDEAD","WARRIOR","HEAVY_BONE",960,26,3,24,5,195,["OSSUARY_FERRY_STRIKE","OSSUARY_CLOSED_PALL","OSSUARY_PROCESSION"]],
	"PISTON_FENCER":["尺九","偏心冲刃师","MACHINE","MELEE_CASTER","MACHINE",810,32,2,21,6,195,["PISTON_OFFSET_JAB","PISTON_FLYWHEEL","PISTON_DEAD_CENTER"]],
	"RIVET_LEGIONARY":["工七","铆阵班长","MACHINE","WARRIOR","MACHINE",990,25,3,24,5,195,["RIVET_SHEAR_LINE","RIVET_LOAD_PLATE","RIVET_WORKING_PRESSURE"]],
	"THORN_REAVER":["间穗","嫁枝刃客","FOREST","MELEE_CASTER","HUMANOID",720,30,1,18,8,225,["THORN_GRAFT_CATCH","THORN_SAP_BLADE","THORN_GRAFT_RUPTURE"]],
	"ANTLER_WARRIOR":["巡苔","空角守猎","FOREST","WARRIOR","HUMANOID",900,27,2,21,7,195,["ANTLER_BRANCH_SWEEP","ANTLER_BARK_FOLD","ANTLER_RUT_SEASON"]],
	"SLAG_DANCER":["淬汀","淬火双锋","HIGHLAND","MELEE_CASTER","HUMANOID",840,35,1,23,6,195,["SLAG_TEMPER_CUT","SLAG_WHITE_HEAT","SLAG_QUENCH_VERDICT"]],
	"BASALT_CHAMPION":["层祁","试坝武卫","HIGHLAND","WARRIOR","HUMANOID",1035,28,3,26,5,180,["BASALT_STRATA_BLOW","BASALT_LOAD_TEST","BASALT_FAULT_STANCE"]],
	"PRISM_MANTIS":["隙琢","棱足刻师","UNDERGROUND","MELEE_CASTER","MULTILEG",735,33,1,18,8,210,["PRISM_FACET_PIN","PRISM_DOUBLE_EDGE","PRISM_REFRACTION_CUT"]],
	"CARAPACE_WARRIOR":["阙甲","换壳斗卫","UNDERGROUND","WARRIOR","MULTILEG",945,28,3,23,6,180,["CARAPACE_SHELL_SPLIT","CARAPACE_NEST_GUARD","CARAPACE_LAYERED_MOLT"]],
}
const STORIES := {
	"OATH_REAVER":{"origin":"凭霄替无人认领的渡船记录失约；他把废弃的誓图铜边磨成单刃长剑，而不是替城盟追讨旧债。","turn":"洪水中没有印章的人先救了他的妹妹，他因此只给活着的证人落款。","motive":"阻止战场把人化为清账数字。","flaw":"总想在撤离前等最后一位证人，错过安全窗口。","silhouette":"长条断页剑、偏斜布签冠、单肩折页披挂","counterplay":"短施距且无位移；诱出标记后拉开，趁强化空档集火。"},
	"BRIDGE_VANGUARD":{"origin":"榫岸曾带拆迁工运走旧桥，后来用拆下的桥桩为流民建临时栈道。","turn":"城盟要求先修收费渡口，她带着未结工单离开，把最好的梁留给免费浮桥。","motive":"让通路在战事之后仍属于普通人。","flaw":"认为每个人都能承重，往往太晚承认自己的疲倦。","silhouette":"宽横梁肩架、双手短柄钉锤、方形背篓","counterplay":"均衡而非纯坦；综合架势没有回血和免控，奥术与分割友军可压制。"},
	"RELIC_REAVER":{"origin":"折名不是军魂，而是一位归名炉庭的戏服修补者；他将拒绝被复述的角色名缝在剑鞘内侧。","turn":"一出胜利戏重演了亲人的死亡，他主动烧掉自己的台词，要求死者保有沉默。","motive":"替不愿完成旧义务的归名者结束纠缠。","flaw":"太相信一场决斗能代替艰难的共同谈判。","silhouette":"弯钩双刃、无面半纱头罩、侧悬小名牌","counterplay":"钩印禁足仍能反击；寒灯只缓慢回蓝，单体夺血受魔抗和缺失生命限制，撤离可耗掉普攻强化。"},
	"OSSUARY_KNIGHT":{"origin":"迟舟驾的是低矮送行雪橇，不是贵族战马；她替愿意安息的归名者运送最后一箱遗物。","turn":"灰潮封住河道后，她拆掉雪橇长辕做武器，把自己留给了下一趟送行。","motive":"把每一次牺牲带回有人记得的岸。","flaw":"面对弃守命令常有迟疑，容易被佯攻拖住。","silhouette":"船形肋甲、长辕钩镰、双层破帆背披","counterplay":"步速慢；自强化不提供群体治疗，分散与远程消耗能打断续战。"},
	"PISTON_FENCER":{"origin":"尺九为工坊测量偏心轴；他的左右臂行程不同，剑术也故意不追求对称。","turn":"自动停工指令误伤学徒后，他给冲刃加了必须本人压住的泄压柄。","motive":"证明精度可以保护工人，而不是让工人追赶机器。","flaw":"痴迷找到一次完美冲程，会把自己置于危险中线。","silhouette":"一长一短活塞臂、侧置飞轮背包、开口焊面罩","counterplay":"冲刃投递窄而短，无突进和免伤；错开直线后反扑。"},
	"RIVET_LEGIONARY":{"origin":"工七是工坊轮班推选的班长，胸前刻的是七个可随时撤回的工位签名。","turn":"在断轨抢修中拒绝用报废工人换效率，自己举着应力板站到试压结束。","motive":"让每条命令都有人负责检修。","flaw":"总要确认两遍，容易错失追击机会。","silhouette":"梯形厚胸板、双头剪铆长柄、四片排热背栅","counterplay":"大招提高护甲、攻速和攻击；绕侧进攻与奥术攻击可克制他。"},
	"THORN_REAVER":{"origin":"间穗剪除压住水渠的耐旱藤，也给迁林者嫁接能在盐地活下来的枝条。","turn":"议庭要求保留一棵记录受害者秘密的树，她选择剪断记忆枝，承担遗忘的责任。","motive":"给生长留出可以拒绝的空间。","flaw":"过于擅长切断关系，不善于求助。","silhouette":"开叉嫁接镰、种匣短翼、半侧荆棘眼罩","counterplay":"生命偏低；束根仍允许还击，毒液有总额上限且可净化。"},
	"ANTLER_WARRIOR":{"origin":"巡苔用掉落的鹿角而非猎获战利品制作武器，负责迁林队周围的季节通路。","turn":"为了引开追兵，她公开焚掉族谱中的一段旧路，从此每年重新走一次林界。","motive":"让林海学会移动，而不是把所有生命锁在原地。","flaw":"不信永久工事，防守时容易过度游走。","silhouette":"空心双角头架、弧形枝盾、短矛与绳结尾披","counterplay":"折枝只加机动和武器延展，不加护甲；大招零伤禁足仍可反击，定身与集火能压住游猎。"},
	"SLAG_DANCER":{"origin":"淬汀为山谷试刃，她的双刀一柄留热、一柄入雪，专门检查钢是否会在救援时断裂。","turn":"一件号称无瑕的兵器伤了同伴后，她拒绝再替领主表演没有风险的庆典。","motive":"把不能承受的压力先带到自己面前。","flaw":"把疼痛当作证据，常低估长期消耗。","silhouette":"冷热双直刃、短宽炉裙、斜挂淬水筒","counterplay":"出手慢于轻刃；火伤可净化或魔抗缓解，大招单体而不清军团。"},
	"BASALT_CHAMPION":{"origin":"层祁是洪坝试压员，背上的玄武层板逐片记录历次险情，而非祖传王冠。","turn":"为救下游村落，她在表决前开启了旁泄闸，之后自愿守完三年的冬夜。","motive":"让承担风险的人也有否决权。","flaw":"习惯硬扛错误，在该撤退时不愿示弱。","silhouette":"错层岩肩、横口重槌、短烟道背柱","counterplay":"高生命低机动；被动护甲不恢复生命，大招短时间提高攻击与攻速，奥术与拉扯有效。"},
	"PRISM_MANTIS":{"origin":"隙琢替没有文字的洞群切磨声音晶片，六足步态可在不触碰育幼菌床的间隙行走。","turn":"地表买家要求统一所有回声，她切开最贵的母晶，保住三种不能互译的声音。","motive":"使不同的证词在同一出口被听见。","flaw":"追求最尖锐的切面，会忽略圆钝却可靠的答案。","silhouette":"六足低伏身、双折棱刃、偏心三角晶冠","counterplay":"脆弱近战无闪现；棱针只使敌人定身，延展重击仅两次，分散可截断大招折射连锁。"},
	"CARAPACE_WARRIOR":{"origin":"阙甲带着不能共用巢温的幼体迁徙，甲壳每一层都留有不同洞群的通气孔。","turn":"祖契不准新来者过冬，她打开自己的壳巢，把通行权从血缘改成轮值照料。","motive":"共同居住不等于变成同一种生命。","flaw":"难以放弃临时庇护，容易被人质式围点牵制。","silhouette":"四足宽壳、双层通气扇盖、前伸铲角","counterplay":"有限自疗与近军救援，没有普攻/攻速大招；爆发、分割和蓝量消耗可压制蜕甲窗口。"},
}
const SKILLS := {
	"OATH_NOTCH":{"name":"断页留痕","effect":"DAMAGE","delivery":"SINGLE","range":115,"radius":42,"max_targets":1,"damage":[160,224,288],"execute_percent":[20,25,30],"status_kind":"ARMOR_BREAK","status_power":[1,2,3],"status_duration_ticks":[80,100,120],"attack_type":"EDGE","mana_cost":28,"max_cooldown_ticks":280,"motif":"contract_notch","material":"INK_SEAL","emblem":"blade","family":"shot"},
	"OATH_EDGE_PLEDGE":{"name":"见证之锋","effect":"DAMAGE_BUFF","damage_percent":[70,95,120],"charges":3,"charge_kind":"ATTACK","duration_ticks":[140,160,180],"mana_cost":26,"max_cooldown_ticks":340,"motif":"three_witness_blade_tabs","material":"PAPER_WEAVE","emblem":"blade","family":"fervor"},
	"OATH_LAST_WITNESS":{"name":"最后见证","effect":"STUN","delivery":"CONE","range":170,"cone_width":170,"radius":0,"max_targets":4,"damage":0,"control_duration_ticks":[120,150],"attack_type":"EDGE","mana_cost":[70,85],"max_cooldown_ticks":900,"motif":"four_witness_crossbar_seal","material":"GLASS_REFRACTION","emblem":"shield","family":"prison"},
	"BRIDGE_CROSSBEAM":{"name":"横梁开道","effect":"DAMAGE","delivery":"LINE","range":155,"line_width":56,"radius":0,"max_targets":3,"damage":[150,210,270],"secondary_damage_percent":65,"attack_type":"IMPACT","status_kind":"SLOW","status_power":[20,25,30],"status_duration_ticks":[100,120,140],"mana_cost":26,"max_cooldown_ticks":260,"motif":"beam_clearing_stroke","material":"ROOT_EARTH","emblem":"shield","family":"shot"},
	"BRIDGE_LOCK_BRACE":{"name":"合榫护架","effect":"RALLY","target_mode":"SELF","radius":120,"max_targets":3,"ally_guard":[2,3,4],"attack_speed_percent":[10,15,20],"requires_live_source":true,"duration_ticks":[100,120,140],"mana_cost":28,"max_cooldown_ticks":360,"motif":"three_joined_crossbeam_braces","material":"PAPER_WEAVE","emblem":"shield","family":"sanctuary"},
	"BRIDGE_LOAD_BEARER":{"name":"众任托梁","effect":"DAMAGE_BUFF","damage_percent":[32,43],"armor_bonus":[3,4],"duration_ticks":[180,220],"mana_cost":[70,85],"max_cooldown_ticks":800,"motif":"four_point_beam_frame","material":"INK_SEAL","emblem":"shield","family":"hunt"},
	"RELIC_NAME_HOOK":{"name":"留名倒钩","effect":"ROOT","delivery":"CHAIN","range":125,"radius":42,"chain_range":65,"max_targets":2,"damage":[120,168,216],"secondary_damage_percent":65,"control_duration_ticks":[40,55,70],"attack_type":"ARCANE","mana_cost":30,"max_cooldown_ticks":320,"motif":"two_name_hooks","material":"GHOST_AFTERIMAGE","emblem":"bone","family":"bind"},
	"RELIC_COLD_EDGE":{"name":"寒灯双刃","effect":"DAMAGE_BUFF","damage_percent":[35,50,65],"mana_per_second":[1.0,1.5,2.0],"duration_ticks":[140,160,180],"mana_cost":25,"max_cooldown_ticks":360,"motif":"cold_lantern_memory_fuel","material":"BONE_LANTERN","emblem":"bone","family":"fervor"},
	"RELIC_UNFINISHED_DUEL":{"name":"未竟独幕","effect":"DAMAGE","delivery":"SINGLE","range":150,"radius":42,"max_targets":1,"damage":[525,709],"drain_percent":[20,24],"attack_type":"ARCANE","mana_cost":[70,85],"max_cooldown_ticks":800,"motif":"curtain_soul_duel","material":"ASH_RIBBON","emblem":"lantern","family":"cataclysm"},
	"OSSUARY_FERRY_STRIKE":{"name":"渡辕横扫","effect":"DAMAGE","delivery":"CONE","range":150,"cone_width":145,"radius":0,"max_targets":3,"damage":[135,189,243],"secondary_damage_percent":65,"drain_percent":[20,25,30],"attack_type":"EDGE","mana_cost":27,"max_cooldown_ticks":280,"motif":"ferry_pole_lifeline","material":"BONE_LANTERN","emblem":"bone","family":"bolt"},
	"OSSUARY_CLOSED_PALL":{"name":"合帆骨衣","effect":"HEAL","heal":[190,266,342],"cleanse_dot":true,"mana_cost":30,"max_cooldown_ticks":300,"motif":"ribbed_pall_suture","material":"GHOST_AFTERIMAGE","emblem":"shield","family":"mend"},
	"OSSUARY_PROCESSION":{"name":"归岸行列","effect":"DAMAGE_BUFF","damage_percent":[35,47],"drain_percent_buff":[24,32],"duration_ticks":[180,220],"mana_cost":[70,85],"max_cooldown_ticks":800,"motif":"returning_sail_lifelines","material":"ASH_RIBBON","emblem":"bone","family":"hunt"},
	"PISTON_OFFSET_JAB":{"name":"偏心冲刃","effect":"DAMAGE","delivery":"LINE","range":145,"line_width":32,"radius":0,"max_targets":2,"damage":[155,217,279],"secondary_damage_percent":60,"attack_type":"IMPACT","status_kind":"ARMOR_BREAK","status_power":[1,2,3],"status_duration_ticks":[100,140,180],"mana_cost":28,"max_cooldown_ticks":280,"motif":"eccentric_piston_borer","material":"RIVET_SPARK","emblem":"gear","family":"shot"},
	"PISTON_FLYWHEEL":{"name":"开环飞轮","effect":"DAMAGE_BUFF","damage_percent":[12,18,24],"attack_speed_percent":[35,45,55],"charges":3,"charge_kind":"ATTACK","duration_ticks":[120,140,160],"mana_cost":26,"max_cooldown_ticks":320,"motif":"three_exposed_piston_teeth","material":"PRESSURE_SMOKE","emblem":"gear","family":"fervor"},
	"PISTON_DEAD_CENTER":{"name":"死点剪切","effect":"STUN","delivery":"LINE","range":185,"line_width":42,"radius":0,"max_targets":3,"damage":0,"control_duration_ticks":[135,165],"attack_type":"IMPACT","mana_cost":[70,85],"max_cooldown_ticks":900,"motif":"locking_offset_shear_rail","material":"CIRCUIT_TRACE","emblem":"gear","family":"prison"},
	"RIVET_SHEAR_LINE":{"name":"剪铆断线","effect":"DAMAGE","delivery":"SINGLE","range":120,"radius":42,"max_targets":1,"damage":[190,266,342],"attack_type":"IMPACT","status_kind":"ARMOR_BREAK","status_power":[1,2,3],"status_duration_ticks":[100,140,180],"mana_cost":27,"max_cooldown_ticks":280,"motif":"rivet_shear_mark","material":"RIVET_SPARK","emblem":"gear","family":"shot"},
	"RIVET_LOAD_PLATE":{"name":"应力护板","effect":"DAMAGE_BUFF","armor_bonus":[2,3,4],"skill_damage_percent":[12,18,24],"charges":2,"charge_kind":"PAID_SKILL","duration_ticks":[140,160,180],"mana_cost":30,"max_cooldown_ticks":360,"motif":"two_charged_pressure_plates","material":"PRESSURE_SMOKE","emblem":"shield","family":"fervor"},
	"RIVET_WORKING_PRESSURE":{"name":"协同试压","effect":"RALLY","target_mode":"SELF","radius":150,"max_targets":4,"ally_guard":[2,3],"attack_speed_percent":[15,20],"requires_live_source":true,"duration_ticks":[180,220],"mana_cost":[70,85],"max_cooldown_ticks":800,"motif":"four_worker_pressure_link","material":"CIRCUIT_TRACE","emblem":"gear","family":"sanctuary"},
	"THORN_GRAFT_CATCH":{"name":"嫁枝缚切","effect":"ROOT","delivery":"CONE","range":135,"cone_width":135,"radius":0,"max_targets":3,"damage":[115,161,207],"secondary_damage_percent":65,"control_duration_ticks":[35,45,55],"attack_type":"EDGE","mana_cost":29,"max_cooldown_ticks":320,"motif":"forked_graft_hooks","material":"PETAL_SWARM","emblem":"rootclaw","family":"bind"},
	"THORN_SAP_BLADE":{"name":"流液芽刃","effect":"DAMAGE_BUFF","damage_percent":[42,57,72],"move_speed_percent":[5,8,11],"duration_ticks":[140,160,180],"mana_cost":24,"max_cooldown_ticks":360,"motif":"sap_thread_sickle","material":"RAIN_THREAD","emblem":"leaf","family":"fervor"},
	"THORN_GRAFT_RUPTURE":{"name":"断枝新生","effect":"DAMAGE","delivery":"AREA","range":160,"radius":82,"max_targets":3,"damage":0,"attack_type":"ARCANE","status_kind":"POISON","status_total_damage":[290,392],"status_duration_ticks":[160,200],"mana_cost":[70,85],"max_cooldown_ticks":900,"motif":"three_slow_germinating_grafts","material":"ROOT_EARTH","emblem":"rootclaw","family":"cataclysm"},
	"ANTLER_BRANCH_SWEEP":{"name":"空角挑枝","effect":"DAMAGE","delivery":"CONE","range":150,"cone_width":160,"radius":0,"max_targets":3,"damage":[135,189,243],"secondary_damage_percent":70,"attack_type":"PIERCE","status_kind":"ARMOR_BREAK","status_power":[1,2,3],"status_duration_ticks":[100,120,140],"mana_cost":26,"max_cooldown_ticks":280,"motif":"hollow_antler_armor_prongs","material":"PETAL_SWARM","emblem":"leaf","family":"bolt"},
	"ANTLER_BARK_FOLD":{"name":"折枝轻甲","effect":"DAMAGE_BUFF","move_speed_percent":[14,19,24],"range_bonus":[24,30,36],"duration_ticks":[140,160,180],"mana_cost":25,"max_cooldown_ticks":340,"motif":"long_branch_running_gait","material":"ROOT_EARTH","emblem":"leaf","family":"fervor"},
	"ANTLER_RUT_SEASON":{"name":"迁林猎季","effect":"ROOT","delivery":"AREA","range":175,"radius":95,"max_targets":4,"damage":0,"control_duration_ticks":[120,150],"mana_cost":[70,85],"max_cooldown_ticks":900,"motif":"empty_antler_root_corridor","material":"RAIN_THREAD","emblem":"leaf","family":"prison"},
	"SLAG_TEMPER_CUT":{"name":"冷淬截锋","effect":"ROOT","delivery":"SINGLE","range":120,"radius":42,"max_targets":1,"damage":[145,203,261],"control_duration_ticks":[40,55,70],"attack_type":"EDGE","mana_cost":30,"max_cooldown_ticks":340,"motif":"quenched_foot_edge_clamp","material":"HEAT_VEIL","emblem":"blade","family":"bind"},
	"SLAG_WHITE_HEAT":{"name":"白热刃口","effect":"DAMAGE_BUFF","damage_percent":[95,125,155],"charges":2,"charge_kind":"ATTACK","duration_ticks":[100,120,140],"mana_cost":27,"max_cooldown_ticks":360,"motif":"two_weighted_white_edges","material":"SLAG_CHUNK","emblem":"blade","family":"fervor"},
	"SLAG_QUENCH_VERDICT":{"name":"淬雪断流","effect":"DAMAGE","delivery":"SINGLE","range":145,"radius":42,"max_targets":1,"damage":[410,554],"attack_type":"EDGE","status_kind":"BURN","status_total_damage":[130,176],"status_duration_ticks":[160,200],"mana_cost":[70,85],"max_cooldown_ticks":800,"motif":"crossed_quench_burn_scar","material":"HEAT_VEIL","emblem":"blade","family":"cataclysm"},
	"BASALT_STRATA_BLOW":{"name":"试坝层击","effect":"DAMAGE","delivery":"SINGLE","range":115,"radius":42,"max_targets":1,"damage":[165,231,297],"attack_type":"IMPACT","status_kind":"ARMOR_BREAK","status_power":[2,3,4],"status_duration_ticks":[100,140,180],"mana_cost":27,"max_cooldown_ticks":300,"motif":"strata_fracture_test","material":"SLAG_CHUNK","emblem":"hammer","family":"shot"},
	"BASALT_LOAD_TEST":{"name":"承压试石","effect":"PASSIVE_GUARD","passive":true,"passive_armor":[1,2,3],"mana_cost":0,"max_cooldown_ticks":0,"motif":"load_stone_shoulder","material":"ROOT_EARTH","emblem":"shield","family":"fervor"},
	"BASALT_FAULT_STANCE":{"name":"分洪山势","effect":"DAMAGE_BUFF","damage_percent":[45,61],"armor_bonus":[2,3],"attack_speed_percent":[15,20],"duration_ticks":[140,180],"mana_cost":[70,85],"max_cooldown_ticks":800,"motif":"short_fault_counterweight","material":"PRESSURE_SMOKE","emblem":"hammer","family":"hunt"},
	"PRISM_FACET_PIN":{"name":"棱足锁切","effect":"ROOT","delivery":"LINE","range":150,"line_width":30,"radius":0,"max_targets":2,"damage":0,"control_duration_ticks":[80,100,120],"attack_type":"ARCANE","mana_cost":30,"max_cooldown_ticks":480,"motif":"two_anchored_facet_pins","material":"CRYSTAL_DUST","emblem":"jaw","family":"bind"},
	"PRISM_DOUBLE_EDGE":{"name":"双折镜锋","effect":"DAMAGE_BUFF","damage_percent":[45,60,75],"range_bonus":[24,30,36],"charges":2,"charge_kind":"ATTACK","duration_ticks":[120,140,160],"mana_cost":25,"max_cooldown_ticks":340,"motif":"two_extended_refraction_edges","material":"ECHO_BAND","emblem":"blade","family":"fervor"},
	"PRISM_REFRACTION_CUT":{"name":"三证折界","effect":"DAMAGE","delivery":"CHAIN","range":175,"radius":42,"chain_range":85,"max_targets":4,"damage":[300,405],"secondary_damage_percent":55,"execute_percent":[25,30],"attack_type":"ARCANE","mana_cost":[70,85],"max_cooldown_ticks":900,"motif":"four_settled_refraction_hops","material":"CRYSTAL_DUST","emblem":"blade","family":"cataclysm"},
	"CARAPACE_SHELL_SPLIT":{"name":"铲角裂壳","effect":"STUN","delivery":"SINGLE","range":115,"radius":42,"max_targets":1,"damage":[120,168,216],"control_duration_ticks":[30,45,60],"attack_type":"IMPACT","mana_cost":27,"max_cooldown_ticks":320,"motif":"closing_spade_pincers","material":"ECHO_BAND","emblem":"jaw","family":"lock"},
	"CARAPACE_NEST_GUARD":{"name":"通气护壳","effect":"HEAL","heal":[150,210,270],"cleanse_dot":true,"mana_cost":26,"max_cooldown_ticks":280,"motif":"vented_shell_clean_air","material":"FUNGAL_MIST","emblem":"shield","family":"mend"},
	"CARAPACE_LAYERED_MOLT":{"name":"共巢蜕甲","effect":"HEAL","heal":[240,324],"ally_heal":[120,162],"ally_guard":[3,4],"ally_radius":180,"radius":180,"max_targets":4,"cleanse_dot":true,"duration_ticks":[180,220],"mana_cost":[70,85],"max_cooldown_ticks":700,"motif":"four_shared_carapace_shelters","material":"FUNGAL_MIST","emblem":"jaw","family":"sanctuary"},
}
const INNATES := {
	"OATH_REAVER":{"name":"凭据截击","trigger":"RECENT_SKILL","percent":12,"growth":1.0,"description":"对过去3秒施放过主动技能的敌军，普攻额外造成基础攻击{P}%伤害。"},
	"BRIDGE_VANGUARD":{"name":"并肩承重","trigger":"TWO_ALLIES_GUARD","percent":8,"growth":0.75,"description":"90内至少2名其他友军时，自身受到的普攻伤害降低{P}%。"},
	"RELIC_REAVER":{"name":"未合名册","trigger":"WOUNDED_SKILL","percent":12,"growth":1.0,"description":"对生命不高于50%的敌军，主动技能的直接伤害提高{P}%，不增加持续伤害。"},
	"OSSUARY_KNIGHT":{"name":"归岸余席","trigger":"DEATH_RECOVERY","amount":18,"growth":2.0,"description":"180内敌军死亡后恢复自身{P}生命，每8秒最多一次。"},
	"PISTON_FENCER":{"name":"偏心三拍","trigger":"THIRD_SAME_TARGET","percent":24,"growth":1.5,"description":"对同一目标每第三次普攻额外造成基础攻击{P}%伤害；换目标或4秒未攻击重置。"},
	"RIVET_LEGIONARY":{"name":"停机验载","trigger":"STATIONARY_GUARD","percent":9,"growth":0.75,"description":"静止2秒后受到的普攻伤害降低{P}%；移动立即停止。"},
	"THORN_REAVER":{"name":"嫁口顺势","trigger":"CONTROLLED_BASIC","percent":14,"growth":1.0,"description":"对已减速或定身的敌军，普攻额外造成基础攻击{P}%伤害。"},
	"ANTLER_WARRIOR":{"name":"迁林蓄势","trigger":"TRAVEL_BASIC","percent":22,"growth":1.5,"description":"移动100距离蓄能下一次普攻，额外造成基础攻击{P}%伤害；最多存1次，冷却3秒。"},
	"SLAG_DANCER":{"name":"热刃试隙","trigger":"ARMORED_SKILL","percent":12,"growth":1.0,"description":"对数值护甲至少3的敌军，主动技能的直接伤害提高{P}%，伤害仍受类型与护甲影响。"},
	"BASALT_CHAMPION":{"name":"背压岩层","trigger":"MELEE_GUARD","percent":8,"growth":0.75,"description":"自身受到射程不高于80的敌方普攻伤害降低{P}%；远程和主动技能不受影响。"},
	"PRISM_MANTIS":{"name":"折面捕音","trigger":"CONTROLLED_SKILL","percent":12,"growth":1.0,"description":"对已眩晕或定身的敌军，主动技能的直接伤害提高{P}%，以命中前的状态为准。"},
	"CARAPACE_WARRIOR":{"name":"透壳气隙","trigger":"SELF_CONTROL_RESIST","percent":10,"growth":1.0,"description":"自身受到的眩晕、定身、减速时长减少{P}%；在英雄70%基础控制时长上继续缩短，受控制抗性总上限限制。"},
}
static func has_hero(id:String)->bool:return ROWS.has(id)
static func owner(id:String)->String:
	for hero:String in ROWS:
		if id in ROWS[hero][11]:return hero
	return ""
## Qualitative constants, not per-query allocations or a Combat payload.
const BRIEFS:={
		"OATH_NOTCH":["切开残破誓图的接缝：单体低血处决并留下破甲刻痕。","高血前排可替残血挡刀；短施距，不提供控制。"],
		"OATH_EDGE_PLEDGE":["预签三片见证；有限三次基础攻击重击，不加攻速。","脱离接战会浪费持续窗口；次数不能靠空挥兑现。"],
		"OATH_LAST_WITNESS":["展开证词横栏；近身扇形纯眩晕，零伤害。","站散并从侧面切入；不能用来直接斩杀或清兵。"],
		"BRIDGE_CROSSBEAM":["横梁沿窄通路开道，冲击并减缓敌人。","避免排成直线；没有硬控制。"],
		"BRIDGE_LOCK_BRACE":["将有限护架分给最近三名友军，包含自身；护甲和攻速共同支撑接战。","离开施法者可保持已付费短增益，但施法者阵亡立即失效；最近满员会占掉位置。"],
		"BRIDGE_LOAD_BEARER":["独自承重的攻击/护甲姿态，没有治疗、吸血、攻速和位移。","拉扯消耗其窗口，奥术压制数值护甲。"],
		"RELIC_NAME_HOOK":["倒钩在两名敌人之间续接名字，伤害并禁足。","被禁足仍能攻击施法；拉开连锁距离。"],
		"RELIC_COLD_EDGE":["寒灯以记忆作燃料，持续基础攻击强化并缓慢回复蓝量。","拒绝让其连续普攻；不增加护甲、攻速或吸血。"],
		"RELIC_UNFINISHED_DUEL":["合拢一名目标的旧幕；单体奥术伤害转化为自身恢复。","满血时吸取会溢出，远离短施距；没有处决加成。"],
		"OSSUARY_FERRY_STRIKE":["渡辕扇扫多人，将实际伤害的一部分回收为生命。","分散站位会减少总吸取；伤害减免也减少吸取。"],
		"OSSUARY_CLOSED_PALL":["合帆缝合自身并清除灼烧中毒，不给护甲。","无法清除眩晕与禁足；满血且无受益友军时不能空放。"],
		"OSSUARY_PROCESSION":["以持续伤害/吸血而非护甲续航的归岸姿态。","集火与控制使其不能把理论吸血兑现。"],
		"PISTON_OFFSET_JAB":["不对称冲程在直线上钻开护甲，不再眩晕。","横移与远程反打；破甲并不取消攻击。"],
		"PISTON_FLYWHEEL":["三枚飞轮齿提供三次快速冲程，攻击增幅较小。","离开武器覆盖，耗掉短窗口；没有永久超频。"],
		"PISTON_DEAD_CENTER":["应力剪轨闭锁一条窄线，纯眩晕而不造成伤害。","错开直线；硬控保护军队而不是替军队输出。"],
		"RIVET_SHEAR_LINE":["剪铆单点开甲，为后续普通攻击与技能留下缺口。","切换承伤者，破甲可被更强同类覆盖但不叠层。"],
		"RIVET_LOAD_PLATE":["两块护板储存两次付费技能增幅，同时给短时护甲。","两次有效伤害/治疗技能或到期后全部耗尽；普攻不消耗技能次数。"],
		"RIVET_WORKING_PRESSURE":["最近四名友军共享攻速及护甲，包含班长，不直接提高攻击力。","优先击倒来源；最近单位占位与有限覆盖限制收益。"],
		"THORN_GRAFT_CATCH":["嫁接钩刃在近扇面造成伤害并束根。","根缚不禁止反击和施法。"],
		"THORN_SAP_BLADE":["树液沿镰延伸，攻击和步速共同强化。","不加护甲、攻速或吸血；短接战不保证完整收益。"],
		"THORN_GRAFT_RUPTURE":["三处嫁口慢慢萌发纯中毒，总额按真实时长分摊，没有即时伤害。","净化、先杀来源目标或更强覆盖可打断兑现；不生成可碰撞藤墙。"],
		"ANTLER_BRANCH_SWEEP":["空角挑枝划开扇面，穿刺并剥开护甲接缝。","没有减速或硬控；分散能减少开甲覆盖。"],
		"ANTLER_BARK_FOLD":["折枝让武器延展并改变奔行步态，增加移速和近身射程。","不是突进或闪避，不提高护甲与攻击百分比。"],
		"ANTLER_RUT_SEASON":["空角回廊使一个小区域的敌人纯禁足。","零伤害；被根缚仍可反击，分散可降低覆盖。"],
		"SLAG_TEMPER_CUT":["淬冷刀锋夹住单个对手足边，混合斩伤与禁足。","近身暴露，目标仍可普攻施法，不是眩晕。"],
		"SLAG_WHITE_HEAT":["两次白热重击，不额外加快挥刀速度。","慢攻击节奏与短窗口；脱离会使第二刀难以兑现。"],
		"SLAG_QUENCH_VERDICT":["单体交刃后留下可净化灼烧，将预算分为即时与后续。","单体而非清场；魔抗与净化降低完整预算。"],
		"BASALT_STRATA_BLOW":["一记试坝槌在单体上留破甲裂缝，不再扫直线。","无硬控，低机动会被拉扯。"],
		"BASALT_LOAD_TEST":["学习型持续护甲，不施放、不耗蓝、不增加免费治疗。","奥术和分割仍有效；不能把被动当主动技能。"],
		"BASALT_FAULT_STANCE":["短促反压姿态：攻击和攻速为主，少量护甲，无移速。","比承重姿态更短，以爆发窗口换续航。"],
		"PRISM_FACET_PIN":["两枚沿窄线折叠的棱针纯禁足，没有先手伤害。","站散与反击；英雄控制时长保护仍生效。"],
		"PRISM_DOUBLE_EDGE":["两次延展棱刃重击，受次数和时间双重限制。","没有攻速提升与位移；不给第三次免费重击。"],
		"PRISM_REFRACTION_CUT":["折界依次跳向真实敌人，后续衰减且偏向低血收割。","切断跳跃距离；一名目标不可能被重复弹射。"],
		"CARAPACE_SHELL_SPLIT":["铲角短促夹击单体，冲击与眩晕一起结算。","无范围伤害，近身有风险。"],
		"CARAPACE_NEST_GUARD":["通气甲排除灼毒并缝合自身；不再临时叠甲。","不能解除硬控，也不会补满生命。"],
		"CARAPACE_LAYERED_MOLT":["蜕下的甲为最近四名其他友军治疗并护甲，自身单独恢复。","有限近身覆盖，不复活；没有攻击与攻速强化。"],
}
static func brief(id:String)->Dictionary:
	if not BRIEFS.has(id):return {}
	return {"interaction":BRIEFS[id][0],"counterplay":BRIEFS[id][1],"version":SKILL_VERSION}
static func growth(hero:String)->Dictionary:
	return {"max_hp":42,"damage_numerator":9,"damage_denominator":2,"armor_every":3,"max_mana":7} if ROWS[hero][3]=="MELEE_CASTER" else {"max_hp":54,"damage_numerator":3,"damage_denominator":1,"armor_every":2,"max_mana":6}
static func raw_profile(hero:String)->Dictionary:
	var r:Array=ROWS[hero]
	return {"id":hero,"name":r[0],"title":r[1],"faction_id":r[2],"role_id":r[3],"role":"近战·技能输出" if r[3]=="MELEE_CASTER" else "战士·攻守均衡","body_kind":r[4],"attack_layers":["GROUND"],"stats":{"label":r[1],"max_hp":r[5],"damage":r[6],"armor":r[7],"attack_range":48,"attack_cooldown_ticks":r[8],"speed":r[9],"radius":14,"population":5,"max_mana":r[10],"attack_type":"CHAOS","armor_type":"SACRED","hp_regen_per_second":1.0},"skill_ids":r[11].duplicate(),"visual_archetype":hero,"story":STORIES[hero].duplicate(true),"identity_version":VERSION}
static func skill(id:String,rank:int)->Dictionary:
	if not SKILLS.has(id):return {}
	var ultimate:=id in ULTIMATES
	var cap:=2 if ultimate else 3
	if rank<0 or rank>cap:return {}
	var r:=maxi(1,rank)
	var result:={"id":id,"target_mode":"SELF" if SKILLS[id].effect in ["DAMAGE_BUFF","HEAL","RALLY","PASSIVE_GUARD"] else "POINT","delivery":"AREA","range":0,"radius":0,"max_targets":1,"secondary_damage_percent":100,"attack_type":"ARCANE","target_layers":["GROUND"],"passive":false,"level":rank,"max_level":cap,"ultimate":ultimate,"learned":rank>0,"required_hero_level":([5,8][mini(rank,1)] if ultimate else 1),"source_faction":ROWS[owner(id)][2],"balance_version":SKILL_VERSION}
	for field:String in SKILLS[id]:
		var value:Variant=SKILLS[id][field]
		result[field]=value[r-1] if value is Array else value
	if result.has("status_total_damage"):result["status_power"]=float(result.status_total_damage)*20.0/float(result.status_duration_ticks)
	result["power_class"]="LEARNED_PASSIVE" if bool(result.passive) else "HEALING" if result.effect=="HEAL" else "ATTACK_ENHANCEMENT" if result.effect in ["DAMAGE_BUFF","RALLY"] else "PURE_CONTROL" if result.effect in ["ROOT","STUN"] and float(result.get("damage",0))==0 else "MIXED" if result.effect in ["ROOT","STUN"] or result.has("status_kind") else "PURE_DAMAGE"
	result["presentation_style"]=str(result.source_faction).to_lower()+"_"+str(result.motif)
	result["calibration_reason"]="M67 individual interaction budgets; charges, healing, pure control, total DoT and nearest ally caps settle through existing Combat. Shape and hue do not establish kit diversity."
	result["design_brief"]=brief(id)
	return result
static func innate_growth(hero:String)->Dictionary:
	var p:Dictionary=INNATES[hero]
	return {"amount" if p.has("amount") else "percent":{"base":p.get("amount",p.get("percent",0)),"per_level":p.growth}}
static func innate_profile(hero:String,level:int)->Dictionary:
	var p:Dictionary=INNATES[hero].duplicate(true)
	var field:="amount" if p.has("amount") else "percent"
	var value:=float(p[field])+float(p.growth)*float(clampi(level,1,8)-1)
	if field=="percent":value=settled_innate_percent(hero,value)
	p.merge({"id":"INNATE_"+hero,"archetype":hero,"passive":true,"mana_cost":0,"learnable":false,"level":clampi(level,1,8),"max_level":8,"automatic_level":true,"growth":innate_growth(hero),"values":{field:value},"version":VERSION},true)
	p.description=str(p.description).replace("{P}","%.1f"%value)+"\n随英雄升级增强，无需学习或消耗蓝量。"
	return p
static func settled_innate_percent(hero:String,value:float)->float:
	# Existing incoming/control/direct-spell interfaces settle integer percent.
	# Publish the same stepped value; fractional BASIC raw hooks retain carry.
	return floorf(value) if hero in ["BRIDGE_VANGUARD","RELIC_REAVER","RIVET_LEGIONARY","SLAG_DANCER","BASALT_CHAMPION","PRISM_MANTIS","CARAPACE_WARRIOR"] else value
