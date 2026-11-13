extends RefCounted
## Authored visual identities only. No combat values, RNG, clocks or actors.
## A persistent motif is a vocabulary, never evidence that a buff is active.
const VERSION := "m61-forest-highland-weapons-v1"
const HEROES := {
	"VINE_WARDEN":{"faction_id":"FOREST","story_anchor":"借根养蜂人：树愿同行但保留离开权；重土与轻粉分速，不画召唤蜂群。","counterplay":"治疗不替代走位；囚根只约束真实命中者，不把未命中者圈在假牢里。"},
	"LEAF_SEER":{"faction_id":"FOREST","story_anchor":"育种师以失败叶脉为记录：种匣、嫁接刀、根扣，拒绝把自然画成无条件绿色善意。","counterplay":"保持分散避开根区/叶扇；古根囚印只包单个真实目标，不是假群控。"},
	"WIND_COURIER":{"faction_id":"FOREST","story_anchor":"携季候鸟传霜期实情；四片不齐尾羽、轻骨弓与换羽残相，不是复制本体。","counterplay":"强化是有限普攻窗口而非范围攻击；后撤、遮蔽和控制能耗去窗口。"},
	"BLOOM_GUIDE":{"faction_id":"FOREST","story_anchor":"盐沼量水师用花盘分水而非祈祷；贝杯、水尺、粉瓣与盐白暗边并存。","counterplay":"治疗只在权威目标和距离内；花瓣不能暗示无敌、复活或新增治疗脉冲。"},
	"THORN_CHANTER":{"faction_id":"FOREST","story_anchor":"空园采声人保存一拍缺口；开口棘琴、异步棘谱和左右不齐的枝袖。","counterplay":"棘鞭是直线、迷庭是定身区；不画阻挡行走的实体墙，不掩盖可反击状态。"},
	"RIDGE_JARL":{"faction_id":"HIGHLAND","story_anchor":"雪坝守闸工以坝钉拼铠；泄洪水位、斜断山锤与厚冷层板，不是山王天选。","counterplay":"重甲并非免伤；崩岩只沿实际直线目标结算，不扩大成全屏地震。"},
	"RUNE_ORACLE":{"faction_id":"HIGHLAND","story_anchor":"窑口天气家把预警写成工艺符；多孔窑尺、玻璃热纹、冷灰与熔滴。","counterplay":"单体炉符、群体熔滴、扇形深炉分开；火势残留不代表地面持续伤害。"},
	"EMBER_CAVALIER":{"faction_id":"HIGHLAND","story_anchor":"封锋试刃者把奖刃熔成救援缆环；检温孔、试刃长锋和刻名钢线。","counterplay":"近身投递有暴露成本；处决只是一名目标，不画冲锋、传送或额外飞刃伤害。"},
	"HEARTH_KEEPER":{"faction_id":"HIGHLAND","story_anchor":"流动面炉主把营地做成可离开的家；炉勺、柴捆、带孔面包盾和蓝灰暖烟。","counterplay":"暖光不是无敌罩；恢复和短护甲分层，护甲期结束必须熄灭附着炉火。"},
	"STORM_HERALD":{"faction_id":"HIGHLAND","story_anchor":"怕高的引雷旗回收索道绳结；缠绳锤和三叉接地旗使雷沿地归航。","counterplay":"锤线能避开，峰雷只沿已命中的链路跳转；不画额外雷击或假击退。"},
}

# hero, weapon, motif, motion, phase signature, persistent motif, 7 color roles,
# anticipation, travel, impact, aftermath. Strings are original instructions.
const ROWS := {
	"VINE_SHOCK":["VINE_WARDEN","root_claw","hive_root_knit","inward-knit","box-open/root-fold/sap-drip","",["15221c","37694d","7bbb7e","dd8c77","fff2c5","9ca4d5","c4b57e"],"蜂箱胸格错时打开","三段带泥根臂由脚底向胸腔卷回","根结扣合与红树液亮滴相撞","蜂蜡小屑缓慢落地，治疗只一次"],
	"VINE_WARD":["VINE_WARDEN","root_claw","bark_lamellae","quiet-shingle","learned/bark-seam/quiet","",["17221b","584f32","a7aa6c","88bca0","ece8b5","b18d86","88775b"],"被动学习后树皮细缝可见","不发射、不播放主动爆点","受益时低亮层皮交错","不创建倒计时，不冒充限时护甲"],
	"VINE_MEND":["VINE_WARDEN","root_claw","hive_root_crown","outward-latch","pollen-trace/root-jaw/earth-fall","",["211c19","715040","ba8867","8dcfc6","fff2cd","b3a1d7","a6bf8c"],"被命中者脚边低飞粉团勾出开口巢路","栗根不是弹道，逐个从命中者脚边扣起","五指根爪以不同高度合拢，粉团与重块分速","根爪与真实定身计时对应，碎土不作额外攻击"],
	"LEAF_BIND":["LEAF_SEER","seed_mortar","graft_seed_latch","fall-and-germinate","pod-flip/seed-fall/root-lock","",["201927","604674","ae8cc5","e1b360","fff5d8","82c5b0","aaa992"],"透叶种匣翻出一枚分瓣种壳","种壳短弧落在实际落点，非火炮爆炸","厚黑边根扣从四个不对称方位锁住命中者","少数空壳翻落，根须随状态而非VFX假延长"],
	"LEAF_FLARE":["LEAF_SEER","leaf_blades","graft_leaf_knives","fan-and-shear","fork-open/leaf-fan/vein-shards","",["221b20","784b5e","dc9caa","78c8c5","fff1c8","cfb967","a4b58d"],"双叉嫁接杖展开一对带缺口叶刃","五片厚叶棱按扇面分速滑出，非均匀射线","脉络刀口短闪，粗叶背留下冷色阴影","细叶脉卷回，减速只在真实受击者身上保留"],
	"LEAF_OATH":["LEAF_SEER","root_claw","single_graft_vise","opposed-close","graft-mark/opposed-clamp/seed-hush","",["15231e","396e54","7cc697","dfa458","fff6cf","b09bdc","bfb18b"],"仅主目标两侧出现嫁接口标记","两片粗根钳从相反方向交错而不是范围藤墙","琥珀种核竖向扣住单目标，零伤纯控不用爆炸","根扣保留读形但不阻止目标反击和施法"],
	"WIND_SHOT":["WIND_COURIER","longbow","migrant_feather_arrow","draw-straight-split","feather-tension/shaft-flight/tail-split","",["152024","395d71","8ac0d5","d89a9b","fff3cb","b6cb78","a996c7"],"弓尖季节羽先亮，弓弦向后拉出一段","厚箭头、窄箭杆、四片不齐尾羽直刺单目标","羽轴撞击后向前凹一下，不画群体爆圆","断尾羽逆风分离，空中的轨迹无新增伤害"],
	"WIND_FERVOR":["WIND_COURIER","winged_bow","molt_leaf_afterimages","alternating-wingbeat","molt-flash/leaf-wings/feather-return","leaf_wings",["201f19","6e6b3e","c6cb6a","aa95d8","fff5d1","7dc4b5","c99681"],"肩侧不齐淡金羽缘先后错开","两片薄厚不同的叶翼绕肩向后收展","长弓与手臂边缘持续出现分段高亮，保留身体暗部","随实际强化存在而循环；到期/耗尽/死亡后立即停"],
	"WIND_MEND":["WIND_COURIER","winged_bow","migration_canopy","layered-wing-reprise","crown-fold/three-wing-sails/one-tail","leaf_wings",["162022","3b6266","82bdc5","e4a36a","fff4cd","bd9acf","a2b783"],"雾蓝尾羽折成向风断旗，焰橙羽冠亮起","三层大小不同翼页以开-停-收的节拍向背后展开","弓口有更强的橙金短焰和冰青羽影，非群体增益","各来源强化独立到期，大招与疾叶不能互相盖掉计时"],
	"BLOOM_SPRING":["BLOOM_GUIDE","water_fan","water_gauge_petals","quiet-level-rise","level-mark/basin-open/bead-hold","",["1e2025","4d6871","88bec5","e7a7bc","fff3d2","b5a2d4","baae80"],"量水盘的两道水尺先显形","常驻光环不伪造投射物","水线与粉瓣分层，范围读形保持低亮","来源离场即失效，不变成付费强化"],
	"BLOOM_TOUCH":["BLOOM_GUIDE","water_fan","shellcup_distribution","branched-stream","cup-tilt/water-forks/petal-close","",["201b22","76536b","d79fbb","81cbb6","fff3d3","d7bc68","b4c1a0"],"贝杯倾斜，量水盘花瓣先内合","各真实受益者收到一束有断点的水线，不画连满屏网络","脚边贝壳瓣上翻，水珠先落、粉瓣后落","治愈末端细丝朝内收，不暗示持续加血"],
	"BLOOM_SANCTUARY":["BLOOM_GUIDE","water_fan","saltmarsh_sluice","offset-water-terraces","gauge-open/terrace-flow/salt-spark","",["1d201b","657048","c4d484","b59ad7","fff7d6","d98e91","8bbcaf"],"盐白水尺排成几段高低不同的开口台阶","水幕按阶梯由近及远交替展开，粉瓣侧向飘离","六个以内真实受益者各获独立花盘，不画无敌巨罩","薄盐亮粒先降、水线后断，结束不继续跳治疗"],
	"THORN_BREEZE":["THORN_CHANTER","thorn_vine","unmatched_thorn_score","offbeat-open-staves","pluck-gap/branch-note/silence","",["17221f","345d56","89bba4","d89eb5","eee9bc","9ba5d3","a79c69"],"开口棘琴留一根暗弦","短棘谱按缺一拍节奏低亮游走","受益者有小枝叶节，不把移动光环当攻速","离开光环范围即断，常驻低亮不遮主技能"],
	"THORN_LASH":["THORN_CHANTER","thorn_vine","thorn_score_whip","snap-and-recoil","string-draw/spiked-whip/backfold","",["21181d","6e3d51","bc748c","9aca90","fff2c8","8bb9ce","c2aa77"],"琴弦被拉成带缺口的酒红棘线","长鞭分三节直线抽出，倒刺朝运动反方向","每个真实命中者脚边钩出一小节嫩玉棘扣","鞭身向施法者方向折回；留下的是状态而非假墙"],
	"THORN_MAZE":["THORN_CHANTER","thorn_vine","open_garden_lattice","staggered-lattice-close","missing-beat/lattice-fold/thorn-rain","",["132220","32675f","75b9a7","d789af","fff1ce","c4b870","99a3d2"],"落区显两条不闭合棘谱，保留明显通路留白","粗棘枝不等距错开，蔷薇锋花晚一拍打开","纯控无爆心；命中脚点有钩扣读形","枝格下沉成断谱，不产生地形阻塞"],
	"RIDGE_SHOCK":["RIDGE_JARL","stone_shield","dam_nail_repair","weighted-inward-lock","watermark/plate-lock/ice-fall","",["191e23","40586a","85abbf","de8862","fff2bd","b7a2d0","c0b080"],"肩铠泄洪刻度与铜热脉短亮","坝钉层板向胸前收拢，冰屑垂直掉落","玄青层板扣紧并有短热亮缝，真实是自疗","重石先落、细霜后散，不向敌人发射碎石"],
	"RIDGE_WARD":["RIDGE_JARL","stone_shield","laminated_gateplate","quiet-layer-pressure","learned/plate-seam/quiet","",["1b2024","475561","91a1b0","c9a36c","e9e2bd","8ca8b9","9b8070"],"学会被动后肩部露出坝钉层理","无主动飞行、无假施法","低亮铜刻度与完整暗面共同保留","不使用有限计时炉火代替被动"],
	"RIDGE_MEND":["RIDGE_JARL","stone_shield","damgate_shockline","slab-by-slab-fall","hammer-drop/slab-line/cold-dust","",["1d1e25","626775","8baed3","c89ed5","fff0bd","e4a36d","85b7ac"],"斜断山锤压低，前方实际线宽有细层理暗影","四块高低不齐坝石沿直线依次翻起而非整圈震荡","每个命中目标有厚板错层与短冰屑冲击","坝石向两侧崩落，保留眩晕标识与真实时长"],
	"RUNE_BIND":["RUNE_ORACLE","rune_hammer","kiln_gauge_stamp","vertical-stamp","gauge-align/single-stamp/ash-drop","",["231b24","72456b","c184b9","84cbaa","fff3cc","d8b362","94abc3"],"多孔窑尺对准一名目标，冷色风杯停转","短厚符锤垂直盖印，不画连锁电流","碧玉刻槽与紫铜印板相扣；纯控零伤无炸焰","灰粒落下后只留眩晕读形，不暗示破甲"],
	"RUNE_FLARE":["RUNE_ORACLE","rune_hammer","kiln_glass_hail","ballistic-cluster","kiln-open/glass-hail/cinder-cool","",["261a1c","853f35","e77c4f","78bcc9","fff2af","c494c4","baa98b"],"窑尺孔口分别点亮冷蓝和橙红温差","大小不一的熔玻璃团短弧落进真实落区","熔滴先砸、湖蓝冷壳后裂，火星沿边缘弹开","实际灼烧受益者继续有小热斑，地面不新增DoT"],
	"RUNE_OATH":["RUNE_ORACLE","rune_hammer","kiln_weather_front","layered-fan-front","pressure-hold/bluefire-front/slag-return","",["171e28","3d567d","82a9df","f0b15c","fff7cb","cf91bb","92c2aa"],"窑尺向两边拉开，熔玻璃日轮侧转","扇面有三层前缘：暗烟、苍蓝炉焰、橙金渣块","强火仅覆盖实际扇形，重渣与轻焰反向运动","暗烟先稀、渣粒后落，不扩散到整个屏幕"],
	"EMBER_SEAL":["EMBER_CAVALIER","ember_saber","testblade_anneal","short-crosscut","heat-hole/one-cut/quench-spark","",["231c1e","775436","ddb15c","8d9cd3","fff2bd","d18f91","a4bfa9"],"护臂检温孔亮起一排短灯","一把实体长柄刃沿短距离交错切入，不是远程飞剑","单目标有金刃硬边与靛蓝淬火片，兼伤控","低温蒸汽往刃背退，残刃无额外命中"],
	"EMBER_SWEEP":["EMBER_CAVALIER","ember_saber","tempered_sword_rail","drawn-line-shear","blade-lower/hot-rail/cold-backedge","",["26191e","84434e","e5848a","7dc9c1","fff3c8","c8aa60","a49dcb"],"试刃长锋压到低位，刃背先显冷青","长直割线前进，珊瑚热刃与霜青回锋错开","四目标以内各有钢屑短喷，不画圆周旋风","烬痕只随真实灼烧保留；远端碎片不继续穿人"],
	"EMBER_MEND":["EMBER_CAVALIER","ember_saber","rescue_cable_verdict","held-then-single-split","nameplate/vertical-cleave/steel-cool","",["271b1c","88432f","eb8f45","9cbfda","fff8c8","bb8dca","bdaf83"],"刻名钢片在刃上向主目标对齐并短暂停顿","竖向巨刃虚影只在目标位置斩下，不造成位移","朱金刃核与苍白断层向两侧剥开，明确单体大招","一圈不闭合冷却钢屑散开，不误画自强化"],
	"HEARTH_WARMTH":["HEARTH_KEEPER","forge_ladle","traveller_oven_warmth","slow-vent","oven-door/coals-glow/smoke-thread","",["221c1a","755741","c6a276","8fbdc2","eee5bc","bd9fbd","9e9f7c"],"双轮面炉门低亮开缝","常驻灰蓝烟线向侧上方散","护甲光环以炉砖短纹而非全身烈火提示","失去来源就断，不创建临时护甲计时"],
	"HEARTH_MEND":["HEARTH_KEEPER","forge_ladle","ladle_coal_mending","pour-and-shelter","ladle-tilt/warm-pour/coal-fade","forge_flames",["231b18","7a4b36","e59a60","8ebfd1","fff1bd","ba8aa9","b3bd93"],"炉勺提起一块深色炭芯，淡蓝暖烟先冒","橙暖小流分给真实受益者，落点呈三角而非爆圆","受益者肩侧有两条短炉火边与灰蓝背烟，身体仍清晰","治疗即刻结算；附着炉火只由真实guard/source_buff剩余期驱动"],
	"HEARTH_REFUGE":["HEARTH_KEEPER","forge_ladle","open_camp_oven","asymmetric-shelter","charcoal-lift/warm-awnings/embers-die","forge_flames",["261c1c","85483e","ec8d62","ac96ce","fff4be","81c4b2","bca77b"],"炭块抬起、面包盾向外翻，低温紫霜阴影先铺","五名以内受益者各展开一小片非对称暖棚影","更长暖火舌与薄荷冷烟反相，绝不画无敌闭合穹罩","临时护甲真实到期立刻熄，暖烟余粒不得超期冒充增益"],
	"STORM_CHANT":["STORM_HERALD","thunder_axe","grounded_flag_rhythm","offbeat-banner","knot-tight/cloth-flap/earth-return","",["1a1d28","495875","8eadd0","d7ab72","eeecc9","b09cc8","8ca89c"],"接地旗绳结逐个收紧","布纹节拍随风摆，不画常驻雷暴","光环只在受益者保留短雷纹，非付费攻速","来源离场即停，低亮不吞掉技能"],
	"STORM_HAMMER":["STORM_HERALD","thunder_axe","ropehammer_groundline","skip-and-ground","rope-draw/hammer-skip/nail-close","",["171d29","3e537d","80a3db","dda264","fff4c4","b78ac9","94b9ad"],"缠绳锤横拉，三叉旗尖闪一下","斧楔形锤头沿直线分段低跳；不是抛出召唤斧","铜钉锯齿线向地面回流，纯控不画伤害爆心","折角雷纹收向接地旗，眩晕按实际目标保留"],
	"STORM_VERDICT":["STORM_HERALD","thunder_axe","summit_relay_strike","staggered-chain-ground","flag-split/relay-lightning/ground-hush","",["211a29","62477e","bd9adc","e8ac66","fff9dc","79bfd0","a0b991"],"旌旗裂边向上折起，一段绳结先发亮","锤形雷核只沿权威命中链依次跳转，不连空目标","每跳紫白短峰雷晚于金红布裂，有命中和眩晕两层","各跳雷线向地压扁消失，不画永久雷池"],
}

static func profile(skill_id: String) -> Dictionary:
	if not ROWS.has(skill_id): return {}
	var row: Array = ROWS[skill_id]
	var result: Dictionary = HEROES[str(row[0])].duplicate(true)
	result.merge({"skill_id":skill_id,"hero_id":str(row[0]),"weapon_family":str(row[1]),"motif":str(row[2]),"motion":str(row[3]),"phase_signature":str(row[4]),"persistent_motif":str(row[5]),"palette":(row[6] as Array).duplicate(true),"anticipation":str(row[7]),"travel":str(row[8]),"impact":str(row[9]),"aftermath":str(row[10]),"budget_guard":"沿用最终M58权威目录的伤害/治疗/控制/MP/冷却/范围/目标数；此profile不声明或改变数值，不以装饰推导命中。","identity_version":VERSION},true)
	return result

static func profiles() -> Dictionary:
	var result: Dictionary = {}
	for skill_id: String in ROWS: result[skill_id] = profile(skill_id)
	return result
