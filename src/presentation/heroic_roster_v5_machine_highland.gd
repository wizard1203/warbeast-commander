extends RefCounted
## V5 original pixel choreography, MACHINE + HIGHLAND. Presentation only.
## Coordinates are an authoring envelope, never a hit/range/target definition.
const P = preload("res://src/presentation/heroic_roster_v5_pixels.gd")
const SIZE := 192
const FRAMES := 12
const ANCHOR := Vector2i(96,136)
const ALPHAS := [0,16,32,48,64,96,128,160,208,255]
const COIL := ["151923","303342","69545a","ae7851","ecc276","fff0bd","91bcc3"]
const VOLT := ["141b2c","293047","484e76","857bca","b8d4ec","eff9e3","c28e73"]
const GEAR := ["201d26","39343a","735e56","be8c57","edbb76","fff0bc","9eb2b1"]
const MEDIC := ["201c24","403837","73594d","b18a61","edc989","fff2c9","a4c6bb"]
const SIGNAL := ["181c2a","303649","5f5776","a38da8","e0cd9e","fff4cc","92c3c3"]
const PISTON := ["171d28","333a45","68707b","a89a83","eac47a","fff2c6","b5d6d5"]
const RIVET := ["191c26","393940","71645e","b58b67","e7bf83","fff0cc","9ebcbd"]
const FLUX := ["141d2a","293446","4b667b","7b9fad","bde1d2","f2f7d3","e5ac66"]
const RIDGE := ["191d29","353e4b","6b777f","a5b6b6","e3e8d4","fff3cc","c8885b"]
const RUNE := ["211c2b","453748","795558","c48463","efbd7b","fff0bf","9bb9bf"]
const EMBER := ["261c28","4b303b","855052","d38059","f4bb72","fff0be","92a9ae"]
const HEARTH := ["251d26","4b3538","845348","c78c5c","eac491","fff0c7","afc2ba"]
const STORM := ["19202f","38445a","697c92","a8bdd0","e0e8d2","fff6cf","b68c6c"]
const SLAG := ["201b2a","433341","80606a","d18465","f3c28b","fff1c9","97c5cf"]
const BASALT := ["201e29","414049","716d70","a49987","d4c6a7","fff0cd","ab6e55"]
const OBSIDIAN := ["181a2b","333143","63516c","9b7689","d8abb0","fff0ca","db905c"]

const PROFILES := {
	"COIL_SHOCK":{"hero":"COIL_WARDEN","faction":"MACHINE","name":"应急检修","material":"PRESSURE_SMOKE","motif":"eleven_valve_return","form":"双斜风箱与向胸炉回拢的铜热短管","gesture":"胸炉回缩、双阀泄压再回流","connection":"两股低压汽由外侧回到自身，不画攻击射线","palette":COIL,"story":"第十一副公共机体先泄压再复位","cast_notes":"两侧开口风箱上抬","contact_notes":"铜热回流、胸前接合","tail_notes":"汽块上散，非持续治疗区","passive":false,"route_mode":5,"family":0,"variant":0},
	"COIL_WARD":{"hero":"COIL_WARDEN","faction":"MACHINE","name":"铆甲核心","material":"RIVET_PLATE","motif":"braced_cooperative_plating","form":"六片不等距肩铆板与双靴磁栓","gesture":"护肩与磁靴铆点逐片亮起","connection":"有条件攻速支援只由实际消费者发布","palette":COIL,"story":"工位投票保管的承重机壳","cast_notes":"不伪造付费施放","contact_notes":"不伪造敌人受击","tail_notes":"低亮错层胸板与靴端锚","passive":true,"route_mode":4,"family":0,"variant":1},
	"COIL_REPAIR":{"hero":"COIL_WARDEN","faction":"MACHINE","name":"电磁壁垒","material":"MAGNETIC_CLAMP","motif":"three_open_pole_locks","form":"三组高低错开的开口磁极锁爪","gesture":"不对称磁极张开后闭合","connection":"跳接只能落在实际被控者之间","palette":COIL,"story":"卸去否决权的监工用停机保人","cast_notes":"三瓣开口磁爪蓄压","contact_notes":"开口极靴扣合，零伤害不用爆炸","tail_notes":"磁齿断续放电而非击飞","passive":false,"route_mode":2,"family":0,"variant":2},
	"INNATE_COIL_WARDEN":{"hero":"COIL_WARDEN","faction":"MACHINE","name":"驻地铆定","material":"GROUND_BOLTS","motif":"two_boot_anchors","form":"双靴外侧短压钉和低位斜锚","gesture":"左右靴端短铆钉交替压下","connection":"静止资格由真状态控制，不凭动画加防御","palette":COIL,"story":"宽磁靴承担工坊而非王权","cast_notes":"无主动前摇","contact_notes":"无伤害反馈","tail_notes":"低亮脚边双锚、中央留白","passive":true,"route_mode":4,"family":0,"variant":3},
	"VOLT_BIND":{"hero":"VOLT_WEAVER","faction":"MACHINE","name":"电弧封锁","material":"WOVEN_CURRENT","motif":"misbeat_spindle_pinch","form":"两根竖梭夹纱与错拍横铜丝","gesture":"梭杖牵开两股错拍铜丝","connection":"窄梭电针到真实单目标，再织成开口束","palette":VOLT,"story":"织机断纱留下可以修补的接口","cast_notes":"偏轴梭织拉紧","contact_notes":"单体纱束短促扣合","tail_notes":"电丝分解，不画群攻圈","passive":false,"route_mode":3,"family":1,"variant":0},
	"VOLT_ARC":{"hero":"VOLT_WEAVER","faction":"MACHINE","name":"脉冲爆","material":"COPPER_ARC","motif":"shuttle_fork_handoff","form":"长折梭电线与短角副叉","gesture":"织梭折返后掷出锯齿电缕","connection":"每段真实链路有不同折点和延迟","palette":VOLT,"story":"错拍织电不是一条均匀激光","cast_notes":"横梭与斜叉分开","contact_notes":"尖短裂光沿实际链接换手","tail_notes":"散线回弹而非持续电墙","passive":false,"route_mode":2,"family":1,"variant":1},
	"VOLT_NETWORK":{"hero":"VOLT_WEAVER","faction":"MACHINE","name":"风暴回路","material":"LOOM_LIGHTNING","motif":"unequal_hanging_loom","form":"三层悬织电架和不对称破口长纱","gesture":"肩轮抬起三层破口电织机","connection":"宽主梭接细副梭，不虚构额外目标","palette":VOLT,"story":"可拆可修的能源网络，停顿也是接口","cast_notes":"上悬不等高织架点亮","contact_notes":"粗电缕编成破口层网","tail_notes":"有限缓流丝逐根熄灭","passive":false,"route_mode":3,"family":1,"variant":2},
	"INNATE_VOLT_WEAVER":{"hero":"VOLT_WEAVER","faction":"MACHINE","name":"三相回路","material":"THREE_PHASE_COPPER","motif":"staggered_three_shuttles","form":"三枚不等高的菱形短梭","gesture":"三个不等距短梭轮值","connection":"只提示已有触发，非每帧新施法","palette":VOLT,"story":"纺织节拍中的第三次回应","cast_notes":"无主动前摇","contact_notes":"非额外命中","tail_notes":"三根铜梭低亮呼吸","passive":true,"route_mode":3,"family":1,"variant":3},
	"GEAR_SHOT":{"hero":"GEAR_HUNTER","faction":"MACHINE","name":"碎轮弹","material":"GUNPOWDER_SCRAP","motif":"split_casing_auger","form":"细长齿弹黑壳与偏置低落抛壳","gesture":"折肩弹仓压进一枚带齿弹","connection":"一枚狭长弹头与抛壳，不画散弹命中","palette":GEAR,"story":"废票回收合同刻在磨损轮齿上","cast_notes":"扁口膛焰和偏置壳","contact_notes":"齿片向外剥离，中央单点裂口","tail_notes":"低落金属屑而非反复爆破","passive":false,"route_mode":4,"family":2,"variant":0},
	"GEAR_FERVOR":{"hero":"GEAR_HUNTER","faction":"MACHINE","name":"齿轮超频","material":"ECCENTRIC_ROTORS","motif":"three_unequal_magazine_wheels","form":"三片不等径露齿轮盘","gesture":"三片不等径轮盘先后啮合","connection":"亮齿附着自身武器，不画受击者","palette":GEAR,"story":"不配套的旧轮盘协同转动","cast_notes":"大轮偏转、小轮抢拍","contact_notes":"自强化显著亮齿","tail_notes":"真实增益有效期由外部控制","passive":false,"route_mode":7,"family":2,"variant":1},
	"GEAR_REPAIR":{"hero":"GEAR_HUNTER","faction":"MACHINE","name":"余热焚场","material":"VENTED_HEAT","motif":"bent_vent_cask","form":"三道弯风管罐体和分层灰热汽","gesture":"回收弹罐的三道弯风管打开","connection":"热粒输送后分层上升；无即时爆炸伤害","palette":GEAR,"story":"把旧枪管余热封进可通风弹罐","cast_notes":"歪斜排热器散开","contact_notes":"低压热幕和上升煤星，不闪白炸圈","tail_notes":"余热沿开缝衰减，可净化","passive":false,"route_mode":6,"family":2,"variant":2},
	"INNATE_GEAR_HUNTER":{"hero":"GEAR_HUNTER","faction":"MACHINE","name":"校准齿列","material":"CALIPER_TEETH","motif":"three_tooth_receipt","form":"开口三齿量规与高低短刻度","gesture":"三枚测齿短尺递进","connection":"同目标资格外部给出，非锁定所有敌人","palette":GEAR,"story":"只给真正用过的齿列打记号","cast_notes":"无主动施法","contact_notes":"不生成额外子弹","tail_notes":"短刻度沿武器侧亮起","passive":true,"route_mode":4,"family":2,"variant":3},
	"COIL_BATTERY":{"hero":"COIL_MEDIC","faction":"MACHINE","name":"稳压光环","material":"WARM_COPPER_PIPE","motif":"four_outlet_warming_manifold","form":"低铜管分配器与四个错高小端口","gesture":"保温背箱的分配管顺次点亮","connection":"四个端口是来源符号，不代表虚构受益者","palette":MEDIC,"story":"夜班修理车记得每人的饭点","cast_notes":"被动来源纹章非主动爆点","contact_notes":"不画治疗十字","tail_notes":"低暖管道和少量琥珀滴","passive":true,"route_mode":5,"family":3,"variant":0},
	"COIL_MEND":{"hero":"COIL_MEDIC","faction":"MACHINE","name":"线圈检修","material":"RESIN_STITCH","motif":"resin_ampoule_stitch","form":"侧置暖安瓿与弯针横缝","gesture":"树脂焊枪拖出弯针接缝","connection":"回流接向真实受益者，非全场治疗网","palette":MEDIC,"story":"热树脂封漏，先暖手再修零件","cast_notes":"偏置暖滴蓄在管口","contact_notes":"铜缝自下而上缝合","tail_notes":"琥珀滴凝成哑光补片","passive":false,"route_mode":5,"family":3,"variant":1},
	"COIL_OVERHAUL":{"hero":"COIL_MEDIC","faction":"MACHINE","name":"全域检修","material":"HEATED_RESIN_CANOPY","motif":"night_shift_repair_awning","form":"不对称修理暖篷与五股树脂垂线","gesture":"背箱翻开成宽暖篷，阀管向两侧托起","connection":"宽源头与有限受益者实际连接","palette":MEDIC,"story":"冻轨救援拆下最后一组车灯线圈","cast_notes":"大而不对称的修理篷展开","contact_notes":"多股暖树脂沿接缝回落","tail_notes":"薄汽上收，无持续回血地板","passive":false,"route_mode":5,"family":3,"variant":2},
	"INNATE_COIL_MEDIC":{"hero":"COIL_MEDIC","faction":"MACHINE","name":"应急绝缘","material":"RESIN_INSULATION","motif":"one_hit_bandage_tabs","form":"两枚折角树脂绝缘签","gesture":"两片树脂绝缘签夹住衣侧","connection":"抵挡资格、次数与过期只读取真实状态","palette":MEDIC,"story":"临时保温不是永久无敌","cast_notes":"无付费施放","contact_notes":"不重复触发治疗","tail_notes":"折角补片点亮后合上","passive":true,"route_mode":5,"family":3,"variant":3},
	"SIGNAL_MARCH":{"hero":"SIGNAL_KEEPER","faction":"MACHINE","name":"信标光环","material":"FLAG_CODE","motif":"two_way_reply_flags","form":"高低双向旗板和直立接地杆","gesture":"双向旗板沿不同高度翻出","connection":"行军信号是旗码，不画攻击轨道","palette":SIGNAL,"story":"让失聪与异语工人都能看懂命令","cast_notes":"不伪造主动脉冲","contact_notes":"不画受击闪白","tail_notes":"明暗旗片和接地短线","passive":true,"route_mode":2,"family":4,"variant":0},
	"SIGNAL_LOCK":{"hero":"SIGNAL_KEEPER","faction":"MACHINE","name":"断路脉冲","material":"RETURN_RECEIPT","motif":"unclosed_return_brackets","form":"两端开口回执括架与长短报码片","gesture":"针盘倒转，断开电缆两端错位接回","connection":"折角回执沿真实链路走，不是群体冲击波","palette":SIGNAL,"story":"收到不等于同意，军令必须可返回","cast_notes":"两端插片先断后接","contact_notes":"开口信号括架收紧，零伤害无碎肉","tail_notes":"细短断续报码","passive":false,"route_mode":2,"family":4,"variant":1},
	"SIGNAL_BLACKOUT":{"hero":"SIGNAL_KEEPER","faction":"MACHINE","name":"静电封锁","material":"SHUTTERED_STATIC","motif":"staggered_signal_shutters","form":"五组错高斜静电暗幕","gesture":"高低信号幕依次闭合而非全亮一圈","connection":"黑幕破口留真实目标位置","palette":SIGNAL,"story":"误码之后先切断危险总线","cast_notes":"三组不齐整遮片架起","contact_notes":"紫灰静电帘短促压暗、亮边重排","tail_notes":"断帧码片向上脱落","passive":false,"route_mode":2,"family":4,"variant":2},
	"INNATE_SIGNAL_KEEPER":{"hero":"SIGNAL_KEEPER","faction":"MACHINE","name":"稳频信标","material":"BEACON_CAPACITOR","motif":"slow_reply_droplet","form":"单滴回执与折角短回流管","gesture":"针盘边一枚水滴状回执上下交接","connection":"回蓝由真实光环所有者处理","palette":SIGNAL,"story":"安静的回应也必须被记录","cast_notes":"无主动前摇","contact_notes":"不伪造资源跳字","tail_notes":"单向回流亮签，非电爆","passive":true,"route_mode":5,"family":4,"variant":3},
	"PISTON_OFFSET_JAB":{"hero":"PISTON_FENCER","faction":"MACHINE","name":"偏心冲刃","material":"PISTON_STEEL","motif":"unequal_parallel_strokes","form":"一长一短平行钢刃和偏轴活塞","gesture":"左右臂不等行程，一长一短冲出","connection":"双轨但只沿真实窄线，不画突进残影","palette":PISTON,"story":"尺九以本人压住的泄压柄保护学徒","cast_notes":"偏心轴偏摆蓄力","contact_notes":"长短钢刃斜向咬开裂口","tail_notes":"沿行程回收的短汽痕","passive":false,"route_mode":4,"family":5,"variant":0},
	"PISTON_FLYWHEEL":{"hero":"PISTON_FENCER","faction":"MACHINE","name":"开环飞轮","material":"OPEN_FLYWHEEL","motif":"three_exposed_stroke_teeth","form":"三枚带独齿的开口偏心飞轮","gesture":"三枚开口飞轮各露一齿","connection":"自身三次武器机会，不生成三次免费攻击","palette":PISTON,"story":"测量者保留不完美的机械节拍","cast_notes":"偏置轮片拉开","contact_notes":"亮齿绕武器侧而非环满身体","tail_notes":"次数耗尽由真实状态熄灭","passive":false,"route_mode":7,"family":5,"variant":1},
	"PISTON_DEAD_CENTER":{"hero":"PISTON_FENCER","faction":"MACHINE","name":"死点剪切","material":"SHEAR_RAIL","motif":"locking_offset_shear","form":"上下两条长错位剪轨","gesture":"两条错位剪轨从不同侧搭住","connection":"窄线闭锁，绝不绘制击飞或血爆","palette":PISTON,"story":"精度是停机否决权，不是逼人追赶机器","cast_notes":"长导轨平移接近","contact_notes":"错位剪面卡在死点，纯控制无爆炸","tail_notes":"钝亮受力缝逐段断开","passive":false,"route_mode":4,"family":5,"variant":2},
	"INNATE_PISTON_FENCER":{"hero":"PISTON_FENCER","faction":"MACHINE","name":"偏心三拍","material":"GAUGE_MARKS","motif":"three_displaced_gauge_ticks","form":"三条长短不同的开口量规","gesture":"三个长短不同的量规刻度轮值","connection":"同目标第三击由真实记录决定","palette":PISTON,"story":"不追求左右臂完全对称的剑术","cast_notes":"无主动前摇","contact_notes":"不生额外穿透目标","tail_notes":"武器近侧三条开口量线","passive":true,"route_mode":4,"family":5,"variant":3},
	"RIVET_SHEAR_LINE":{"hero":"RIVET_LEGIONARY","faction":"MACHINE","name":"剪铆断线","material":"SHEARED_RIVET","motif":"diagonal_seam_unzip","form":"相向双剪头与单条斜铆裂缝","gesture":"双头剪铆长柄斜合","connection":"单个裂缝，不被名字误画成范围直线","palette":RIVET,"story":"工七让每个命令都有检修签名","cast_notes":"双剪头错开起势","contact_notes":"铆缝向两边剥开，热屑落地","tail_notes":"断铆头迟半拍下沉","passive":false,"route_mode":4,"family":6,"variant":0},
	"RIVET_LOAD_PLATE":{"hero":"RIVET_LEGIONARY","faction":"MACHINE","name":"应力护板","material":"CHARGED_LOAD_PLATES","motif":"two_plate_reservoir","form":"两块带双储能横缝的斜肩护板","gesture":"两块斜面护板扣向自身肩侧","connection":"两次付费技能机会，不画额外普攻火焰","palette":RIVET,"story":"保护承担压力的人而非遮住责任","cast_notes":"分开装载两片应力板","contact_notes":"板内两道储能横缝亮起","tail_notes":"按真实次数及期限收束","passive":false,"route_mode":5,"family":6,"variant":1},
	"RIVET_WORKING_PRESSURE":{"hero":"RIVET_LEGIONARY","faction":"MACHINE","name":"协同试压","material":"COOPERATIVE_MANIFOLD","motif":"four_signature_pressure_spokes","form":"四签端点工作架与开口承重底梁","gesture":"四片排热背栅展开成工作支架","connection":"源头四签为工位符号；受益者连线必须真实","palette":RIVET,"story":"七个工位可随时撤回班长的签名","cast_notes":"上托肩架、侧板先后开","contact_notes":"压力分路，不做敌军爆炸","tail_notes":"有限友军窗口，来源倒下即失效","passive":false,"route_mode":2,"family":6,"variant":2},
	"INNATE_RIVET_LEGIONARY":{"hero":"RIVET_LEGIONARY","faction":"MACHINE","name":"停机验载","material":"WORKBENCH_ANCHOR","motif":"stationary_test_braces","form":"两根斜撑支脚与测压签孔","gesture":"斜撑支脚落下并亮测压点","connection":"静止条件由权威状态控制","palette":RIVET,"story":"停机检查保住比进度更重要的生命","cast_notes":"无主动施法","contact_notes":"不画治疗或无敌盾","tail_notes":"双支脚与一枚签名孔","passive":true,"route_mode":4,"family":6,"variant":3},
	"FLUX_BORE_LANCE":{"hero":"FLUX_BOMBARDIER","faction":"MACHINE","name":"磁穿导枪","material":"MAGNETIC_RAIL","motif":"split_coil_bore_lance","form":"两段偏轴开口磁环与长矛导芯","gesture":"偏置磁环相向错位后推开长导芯","connection":"长矛状电流与两条断续回路同向投递","palette":FLUX,"story":"从废磁轨里听出仍活着的救援信号","cast_notes":"两段不闭合磁环蓄势","contact_notes":"细长穿芯、侧向碎铁花","tail_notes":"电流沿轨向后回卷","passive":false,"route_mode":4,"family":7,"variant":0},
	"FLUX_RELAY_FORK":{"hero":"FLUX_BOMBARDIER","faction":"MACHINE","name":"旁路分电","material":"RELAY_FORK","motif":"offset_busbar_branch","form":"竖母线和高低角状继电叉","gesture":"旁路开关像叉骨张开","connection":"分电枝段接实际后继目标，非自动四向攻击","palette":FLUX,"story":"被抛弃的信号也值得获得回应","cast_notes":"竖母线升起，副叉延后打开","contact_notes":"角状断电叉与小继电点","tail_notes":"分支灯从端部依次退回","passive":false,"route_mode":2,"family":7,"variant":1},
	"FLUX_SATURATION_CORE":{"hero":"FLUX_BOMBARDIER","faction":"MACHINE","name":"饱和磁核","material":"IRON_BLOSSOM","motif":"torn_iron_core_bloom","form":"单重磁核与七片不等长铁花","gesture":"失谐配电架托起多层沉重铁核","connection":"单一真实落点开成不规则铁花，不在每目标生核","palette":FLUX,"story":"短促过载之后必须允许线圈停机","cast_notes":"铁片绕核错层上收","contact_notes":"重铁瓣外翻、白青芯短闪","tail_notes":"铁瓣掉落与细磁屑回收","passive":false,"route_mode":7,"family":7,"variant":2},
	"INNATE_FLUX_BOMBARDIER":{"hero":"FLUX_BOMBARDIER","faction":"MACHINE","name":"双拍过载","material":"PAIRED_RELAY","motif":"alternating_dual_contact","form":"高低两枚继电触片","gesture":"一高一低两个继电触片错拍接触","connection":"仅实际第二次付费法术触发，非持续增伤","palette":FLUX,"story":"与总线脱钩的独立救援回路","cast_notes":"无主动施放","contact_notes":"不造新受击事件","tail_notes":"偏置双接点、两拍不同亮度","passive":true,"route_mode":2,"family":7,"variant":3},
	"RIDGE_SHOCK":{"hero":"RIDGE_JARL","faction":"HIGHLAND","name":"炉血重整","material":"ICE_COPPER_BACKFLOW","motif":"snow_dam_warm_return","form":"双斜冰坝板和向身回流的铜热脉","gesture":"坝板内的铜热脉回流、冰屑下落","connection":"冷影包围、热流归身，不画向外攻击","palette":RIDGE,"story":"各村坝钉拼成的礼甲必须还能保护人","cast_notes":"两块斜坝板抬开","contact_notes":"铜脉由脚侧归拢胸板","tail_notes":"薄霜碎屑融落，无持续回血区","passive":false,"route_mode":5,"family":8,"variant":0},
	"RIDGE_WARD":{"hero":"RIDGE_JARL","faction":"HIGHLAND","name":"山誓重铠","material":"STRATIFIED_DAM","motif":"village_rivet_shoulder_dam","form":"四片错层坝甲与短水位尺","gesture":"层理肩铠显出不同水位刻线","connection":"静止条件防普攻支援，只画来源而非全能护盾","palette":RIDGE,"story":"不同村落保留否决开闸的权利","cast_notes":"被动不能伪造蓄力","contact_notes":"不画受击爆炸","tail_notes":"断开的坝板与水位短尺","passive":true,"route_mode":4,"family":8,"variant":1},
	"RIDGE_MEND":{"hero":"RIDGE_JARL","faction":"HIGHLAND","name":"崩岩号令","material":"FRACTURE_PERCUSSION","motif":"staggered_dam_slab_command","form":"五段高低岩脊与断面铜钉","gesture":"斜断山锤压出一道错层岩脊","connection":"沿真实直线的重拍，不画新增山墙阻挡","palette":RIDGE,"story":"守闸者举槌示警，不替村落决定流向","cast_notes":"高低坝石向锤头积压","contact_notes":"长条错层块依次崩开","tail_notes":"雪灰与铜钉向低处落","passive":false,"route_mode":4,"family":8,"variant":2},
	"INNATE_RIDGE_JARL":{"hero":"RIDGE_JARL","faction":"HIGHLAND","name":"半血山誓","material":"DAM_RIVETS","motif":"half_waterline_notches","form":"半高缺口坝印与三枚低位坝钉","gesture":"肩侧半高水位和三枚坝钉微亮","connection":"低生命及穿刺普攻资格由实际状态决定","palette":RIDGE,"story":"缺掉的礼甲提醒守闸工留下出口","cast_notes":"无主动施放","contact_notes":"不画额外治疗","tail_notes":"半高坝印而非完整无敌圆罩","passive":true,"route_mode":4,"family":8,"variant":3},
	"RUNE_BIND":{"hero":"RUNE_ORACLE","faction":"HIGHLAND","name":"符炉缚","material":"KILN_GAUGE","motif":"inverted_weather_cup_clamp","form":"倒置陶风杯和双侧多孔夹尺","gesture":"倒置风杯降下、窑尺两边收紧","connection":"单目标工艺符夹，不画全域冰冻","palette":RUNE,"story":"工艺记号让不同语言工人看懂预警","cast_notes":"多孔窑尺的三孔先亮","contact_notes":"风杯与陶夹扣合、纯控无火爆","tail_notes":"符片开口消散，非封路建筑","passive":false,"route_mode":6,"family":9,"variant":0},
	"RUNE_FLARE":{"hero":"RUNE_ORACLE","faction":"HIGHLAND","name":"炉焰","material":"GLASS_MELT","motif":"asymmetric_molten_glass_splash","form":"不规则熔玻璃浅影与高低飞滴","gesture":"天气钟倾出琥珀玻璃液","connection":"一个实际区域的飞溅玻璃，不对每敌复制火环","palette":RUNE,"story":"看云也看炉口，承认预报会错","cast_notes":"偏斜窑口吐出暖滴","contact_notes":"大块熔滴与细火针错落","tail_notes":"热纹冷却成暗琥珀细屑","passive":false,"route_mode":0,"family":9,"variant":1},
	"RUNE_OATH":{"hero":"RUNE_ORACLE","faction":"HIGHLAND","name":"深炉喷涌","material":"KILN_PLUME","motif":"weather_kiln_three_weight_plume","form":"单侧三层长短熔焰喷舌","gesture":"倒置风杯翻成三层重喷口","connection":"宽扇炉流朝实际方向，不是三百六十度爆炸","palette":RUNE,"story":"把灾害警报变成能行动的窑口图样","cast_notes":"高陶嘴预压、下口先吐黑烟","contact_notes":"三层长短不同熔焰舌交叠","tail_notes":"琥珀飞滴与灰烟拉长散尽","passive":false,"route_mode":0,"family":9,"variant":2},
	"INNATE_RUNE_ORACLE":{"hero":"RUNE_ORACLE","faction":"HIGHLAND","name":"炉符添薪","material":"HEAT_GAUGE","motif":"burn_qualified_kiln_ticks","form":"三段短窑尺和侧向热记号","gesture":"多孔尺边的两枚热记号交接","connection":"仅对真实灼烧目标适用，不添加灼烧","palette":RUNE,"story":"炉符是测量方法，不是神谕","cast_notes":"无主动施法","contact_notes":"不增加受害者","tail_notes":"刻尺短热纹，非独立火圈","passive":true,"route_mode":4,"family":9,"variant":3},
	"EMBER_SEAL":{"hero":"EMBER_CAVALIER","faction":"HIGHLAND","name":"坠烬钉矛","material":"FURNACE_SAND_SPEAR","motif":"falling_barbed_javelin","form":"带倒钩的高落单钉矛与散炉砂","gesture":"投矛器掷出一枚可装填炉砂的钉矛","connection":"单矛高弧落针，不画近战大剑或骑兵冲锋","palette":EMBER,"story":"改用投矛为车队清出高处火线","cast_notes":"长投矛蓄在高肩侧","contact_notes":"倒钩矛尖与少量炉砂崩散","tail_notes":"嵌落短烬影，不新增定身时间","passive":false,"route_mode":0,"family":10,"variant":0},
	"EMBER_SWEEP":{"hero":"EMBER_CAVALIER","faction":"HIGHLAND","name":"炉砂穿廊","material":"HOT_SAND_RIBBON","motif":"three_open_sand_corridors","form":"三段不连续的平行长砂廊","gesture":"扁口投矛器推出长炉砂条","connection":"直廊内粗细颗粒同向，非扇面雨弹","palette":EMBER,"story":"重复装填而非挥舞旧裂谷重刃","cast_notes":"短槽内颗粒后聚","contact_notes":"三段不连续长砂带穿过真实方向","tail_notes":"金红砂尾错速下坠","passive":false,"route_mode":4,"family":10,"variant":1},
	"EMBER_MEND":{"hero":"EMBER_CAVALIER","faction":"HIGHLAND","name":"终炉重矛","material":"WHITE_HOT_JAVELIN","motif":"weighted_final_furnace_point","form":"粗重斜单矛与短白热尖芯","gesture":"沉重长矛由背侧高举、热芯后亮","connection":"粗单矛与偏置短尾，不伪造群体斩杀","palette":EMBER,"story":"猎长将最重的一矛留给真正的威胁","cast_notes":"黑暗矛翼压住短白芯","contact_notes":"单点重穿刺与不对称爆屑","tail_notes":"沿矛孔回收的火尾","passive":false,"route_mode":4,"family":10,"variant":2},
	"INNATE_EMBER_CAVALIER":{"hero":"EMBER_CAVALIER","faction":"HIGHLAND","name":"第三烬刃","material":"SAND_CHARGE_TICKS","motif":"third_spear_ember_charge","form":"三枚横砂槽和第三槽短烬","gesture":"三枚炉砂槽位递进","connection":"第三次实际普攻后才给相应受击反馈","palette":EMBER,"story":"旧烬刃的名字保留，武器已是投矛","cast_notes":"无免费施法","contact_notes":"不生成第三枚新矛","tail_notes":"第三槽短燃、其他槽哑光","passive":true,"route_mode":4,"family":10,"variant":3},
	"HEARTH_WARMTH":{"hero":"HEARTH_KEEPER","faction":"HIGHLAND","name":"暖炉光环","material":"BREAD_HEARTH","motif":"perforated_shared_hearth","form":"开口穿孔面炉和低层暖烟","gesture":"穿孔面炉的低烟与热孔交替","connection":"来源是可离开的营地，不画锁住盟友的罩","palette":HEARTH,"story":"共用面炉靠普通人互相续火","cast_notes":"被动光环不做施法爆点","contact_notes":"不画瞬间群疗","tail_notes":"低飞炭星、半开暖烟罩","passive":true,"route_mode":5,"family":11,"variant":0},
	"HEARTH_MEND":{"hero":"HEARTH_KEEPER","faction":"HIGHLAND","name":"炉火重整","material":"WARM_CLOTH_SMOKE","motif":"folded_warm_smoke_bundle","form":"三层留缝折暖布烟","gesture":"围裙翻卷、暖烟像布包合拢","connection":"向实际受益者回流；不是火焰伤敌","palette":HEARTH,"story":"把最后一炉热食分给离营的人","cast_notes":"暖烟团从低炉口向上托","contact_notes":"三层折暖纹包合并留透气缝","tail_notes":"炭点低落、薄烟上升","passive":false,"route_mode":5,"family":11,"variant":1},
	"HEARTH_REFUGE":{"hero":"HEARTH_KEEPER","faction":"HIGHLAND","name":"不熄营火","material":"MOBILE_CAMP_BRAZIER","motif":"open_campfire_awning","form":"大开口营烟篷和左右双炉轮","gesture":"宽面炉向两侧敞开、烟篷托起","connection":"来源到真实盟友有温暖分路，不是新增持续治疗","palette":HEARTH,"story":"温暖不换服从，营地始终留出口","cast_notes":"双炉轮展开不封圈","contact_notes":"非对称暖旗与炭火梁","tail_notes":"按有限强化期限散开，不永久驻场","passive":false,"route_mode":5,"family":11,"variant":2},
	"INNATE_HEARTH_KEEPER":{"hero":"HEARTH_KEEPER","faction":"HIGHLAND","name":"炉心余温","material":"BREAD_CRUST_GUARD","motif":"small_warm_crust_lamellae","form":"两片穿孔暖壳与内侧亮孔","gesture":"两片穿孔暖壳逐片合拢","connection":"仅有效治疗后的真实护盾使用此意象","palette":HEARTH,"story":"自己的份额藏进暖壳里给别人","cast_notes":"无付费施法","contact_notes":"不额外治疗","tail_notes":"小暖壳非全身永久护罩","passive":true,"route_mode":5,"family":11,"variant":3},
	"STORM_CHANT":{"hero":"STORM_HERALD","faction":"HIGHLAND","name":"战歌光环","material":"GROUNDING_CLOTH","motif":"three_prong_flag_rhythm","form":"三支错高布旗与斜接地绳","gesture":"三叉旗布按不同节拍翻动","connection":"可见口令旗不造成新雷击","palette":STORM,"story":"怕高的传令者先检查绳结","cast_notes":"被动不伪造击锤","contact_notes":"不画伤害爆闪","tail_notes":"旗角与接地绳清晰低亮","passive":true,"route_mode":2,"family":12,"variant":0},
	"STORM_HAMMER":{"hero":"STORM_HERALD","faction":"HIGHLAND","name":"落雷锤","material":"GROUNDED_THUNDER","motif":"rope_hammer_ground_wire","form":"上接短雷的横锤和沿地锯齿绳路","gesture":"缠绳锤引雷后沿地回流","connection":"线形接地而非天降群体伤害","palette":STORM,"story":"巨响必须接地，传令使不是风暴选民","cast_notes":"高处短雷接向锤端","contact_notes":"折线路脊逐段亮起，纯控制无燃烧","tail_notes":"绳结火花依次熄灭","passive":false,"route_mode":2,"family":12,"variant":1},
	"STORM_VERDICT":{"hero":"STORM_HERALD","faction":"HIGHLAND","name":"山巅裁决","material":"FLAG_CHAIN_LIGHTNING","motif":"rope_knotted_peak_arcs","form":"带粗绳结的长跳雷与高位副闪","gesture":"三叉接地旗引出带绳结的粗雷","connection":"带结雷弧跳到真实受击者，非全场雷雨","palette":STORM,"story":"让最弱的声音传到队尾","cast_notes":"旗角三支先后接闪","contact_notes":"粗锯齿雷和偏轴结点重拍","tail_notes":"余电沿接地绳分段回流","passive":false,"route_mode":2,"family":12,"variant":2},
	"INNATE_STORM_HERALD":{"hero":"STORM_HERALD","faction":"HIGHLAND","name":"雷旌协击","material":"REPLY_KNOT_MARK","motif":"three_knot_reply_flags","form":"缺角回执旗与三枚短绳结","gesture":"小回执旗与绳结短亮","connection":"标记及下一友军普攻收益由真实事件控制","palette":STORM,"story":"每个队尾都能纠正旗幅上的命令","cast_notes":"无独立施法","contact_notes":"不添加雷链命中","tail_notes":"带缺口短旗而非大雷圈","passive":true,"route_mode":2,"family":12,"variant":3},
	"SLAG_TEMPER_CUT":{"hero":"SLAG_DANCER","faction":"HIGHLAND","name":"冷淬截锋","material":"COLD_QUENCH_BLADES","motif":"foot_edge_cold_clamp","form":"低位冷夹刀与斜向热切刃","gesture":"冷刀压低、热刀后收，一冷一热夹足","connection":"根锁仍允许攻击施法，不画眩晕头星","palette":SLAG,"story":"一柄留热一柄入雪，检查救援钢刃","cast_notes":"双刃先分离再交错","contact_notes":"低位冷夹与短红切线","tail_notes":"白汽向上、冻屑下落","passive":false,"route_mode":4,"family":13,"variant":0},
	"SLAG_WHITE_HEAT":{"hero":"SLAG_DANCER","faction":"HIGHLAND","name":"白热刃口","material":"TWO_WHITE_EDGES","motif":"weighted_two_strike_forge","form":"两柄不等高的白热直刀脊","gesture":"两柄直刃各有一条白热刃脊","connection":"两次普攻机会，不能暗示额外攻速或新伤害圈","palette":SLAG,"story":"拒绝领主无风险表演的试刃者","cast_notes":"白热从刀根上行","contact_notes":"两条不等长炽刃附着武器","tail_notes":"由实际次数与期限消退","passive":false,"route_mode":4,"family":13,"variant":1},
	"SLAG_QUENCH_VERDICT":{"hero":"SLAG_DANCER","faction":"HIGHLAND","name":"淬雪断流","material":"HOT_COLD_CROSS_SCAR","motif":"crossed_quench_burn_scar","form":"冷白粗弧和热红窄线相交的单点裂痕","gesture":"热锋与雪刃沿两条不同弧交会","connection":"单体十字裂痕而非清场旋风","palette":SLAG,"story":"把不能承受的压力先带到自己面前","cast_notes":"一高一低双长刃拉开","contact_notes":"冷白粗切和热红窄切错拍相交","tail_notes":"裂口余温与雪汽分离，可净化","passive":false,"route_mode":3,"family":13,"variant":2},
	"INNATE_SLAG_DANCER":{"hero":"SLAG_DANCER","faction":"HIGHLAND","name":"热刃试隙","material":"TEMPER_GAUGE","motif":"armored_target_heat_notch","form":"一冷一暖两段刀根试温尺","gesture":"双刀根部高低温短尺交替","connection":"仅真实护甲条件触发，不可画穿甲无视规则","palette":SLAG,"story":"钢的缺陷要由试刃证实","cast_notes":"无主动技能","contact_notes":"不造额外灼烧","tail_notes":"冷暖双短纹低亮","passive":true,"route_mode":4,"family":13,"variant":3},
	"BASALT_STRATA_BLOW":{"hero":"BASALT_CHAMPION","faction":"HIGHLAND","name":"试坝层击","material":"STRATA_FRACTURE","motif":"single_layer_load_crack","form":"三层错动试石与偏置受力长缝","gesture":"横口槌压开一个错层试石","connection":"一处承力裂缝，不画贯穿直线山脊","palette":BASALT,"story":"层板记录险情，不是祖传王冠","cast_notes":"厚槌影由上方缓压","contact_notes":"三层岩片错开，一道偏置亮缝","tail_notes":"沉石与细沙不同速度下落","passive":false,"route_mode":4,"family":14,"variant":0},
	"BASALT_LOAD_TEST":{"hero":"BASALT_CHAMPION","faction":"HIGHLAND","name":"承压试石","material":"SHOULDER_STONES","motif":"unequal_shoulder_test_layers","form":"左右不等厚的三层肩试板","gesture":"左右肩不同层板慢慢对齐","connection":"持续自身护甲，不发明额外治疗或光环","palette":BASALT,"story":"让承担风险的人保有否决权","cast_notes":"没有主动蓄力","contact_notes":"不生成伤害","tail_notes":"粗层板边缘细亮、非大罩","passive":true,"route_mode":4,"family":14,"variant":1},
	"BASALT_FAULT_STANCE":{"hero":"BASALT_CHAMPION","faction":"HIGHLAND","name":"分洪山势","material":"COUNTERWEIGHT_STRATA","motif":"short_fault_pressure_stance","form":"三块翻开反压板与留缝闸底梁","gesture":"三层反压板向外翻，承重轴回正","connection":"自身短促强化，不发明回血或移动增益","palette":BASALT,"story":"在投票前开启旁泄闸后的守夜者","cast_notes":"侧闸板抬起留出中缝","contact_notes":"大斜板与短热纹交错","tail_notes":"反压板逐片退回真实强化期","passive":false,"route_mode":4,"family":14,"variant":2},
	"INNATE_BASALT_CHAMPION":{"hero":"BASALT_CHAMPION","faction":"HIGHLAND","name":"背压岩层","material":"REAR_LOAD_STONES","motif":"rear_melee_pressure_slats","form":"三片只在背侧排开的短层石","gesture":"背侧三片错层短石排开","connection":"仅近程普攻防护，不画远程免疫罩","palette":BASALT,"story":"背板记下险情，仍允许人撤退","cast_notes":"无主动施法","contact_notes":"不产生攻击岩弹","tail_notes":"背侧低亮层片、不围满身体","passive":true,"route_mode":4,"family":14,"variant":3},
	"OBSIDIAN_GLASS_POOL":{"hero":"OBSIDIAN_CANTOR","faction":"HIGHLAND","name":"碎镜炉池","material":"BLACK_GLASS","motif":"broken_asymmetric_kiln_pool","form":"锯齿黑玻浅影与七枚错高镜刃","gesture":"歌匣打开，黑曜碎镜倾向单个落点","connection":"一次实际区域接触，非新增持续伤害池","palette":OBSIDIAN,"story":"降温调让学徒听见窑壁将裂的节拍","cast_notes":"黑色斜面由上侧翻开","contact_notes":"不规则浅池与互不相同的镜刃","tail_notes":"暗玻璃反光碎去，不留新地形","passive":false,"route_mode":6,"family":15,"variant":0},
	"OBSIDIAN_CINDER_SEAM":{"hero":"OBSIDIAN_CANTOR","faction":"HIGHLAND","name":"窑缝长烬","material":"KILN_SEAM_EMBER","motif":"long_black_seam_cinders","form":"长斜黑陶板内的断续熔烬缝","gesture":"陶歌匣沿一条裂缝吐出细长热痕","connection":"直线持续灼烧无初始伤害，不画爆破","palette":OBSIDIAN,"story":"让承压者决定停火而非加速祭礼","cast_notes":"陶板拉开长而窄的裂口","contact_notes":"缝内延迟出现熔烬与黑边","tail_notes":"细屑沿窑缝上升，可净化","passive":false,"route_mode":4,"family":15,"variant":1},
	"OBSIDIAN_NIGHT_FAN":{"hero":"OBSIDIAN_CANTOR","faction":"HIGHLAND","name":"黑曜开夜","material":"OBSIDIAN_FAN","motif":"unequal_black_glass_fan","form":"八片不等长窄尖的侧开黑曜扇","gesture":"弧背碎玻扇由背侧大幅展开","connection":"宽而短的扇面，不画全向法阵","palette":OBSIDIAN,"story":"封住名窑后仍可自由打开歌匣","cast_notes":"长短黑曜片在肩上逐根开","contact_notes":"多层暗扇、白紫尖缘与琥珀断滴","tail_notes":"重镜片暗下、轻火屑上散","passive":false,"route_mode":0,"family":15,"variant":2},
	"INNATE_OBSIDIAN_CANTOR":{"hero":"OBSIDIAN_CANTOR","faction":"HIGHLAND","name":"息炉稳调","material":"COOLING_SONG_SLITS","motif":"stationary_kiln_breath_slits","form":"三段短黑曜歌槽与错拍窄反光","gesture":"歌匣三道窄槽按长呼吸点亮","connection":"静止条件只读，移动必须失效","palette":OBSIDIAN,"story":"稳住呼吸不等于稳住所有局面","cast_notes":"无主动施法","contact_notes":"不画额外护盾","tail_notes":"窄短黑曜音槽，非永久火池","passive":true,"route_mode":4,"family":15,"variant":3},
}

static func paint(image:Image,skill_id:String,phase:String,frame:int)->void:
	if not PROFILES.has(skill_id) or phase not in ["CAST","CONTACT","TAIL","AURA"] or frame<0 or frame>=FRAMES:return
	var row:Dictionary=PROFILES[skill_id]
	var t:=float(frame)/11.0
	var fade:=pow(1.0-t,0.7) if phase=="TAIL" else 0.72+0.20*sin(t*TAU) if phase=="AURA" else 1.0
	var growth:=0.48+0.52*t if phase=="CAST" else 1.0
	var v:=int(row.variant)
	match int(row.family):
		0:_coil(image,row,v,phase,t,fade,growth)
		1:_volt(image,row,v,phase,t,fade,growth)
		2:_gear(image,row,v,phase,t,fade,growth)
		3:_medic(image,row,v,phase,t,fade,growth)
		4:_signal(image,row,v,phase,t,fade,growth)
		5:_piston(image,row,v,phase,t,fade,growth)
		6:_rivet(image,row,v,phase,t,fade,growth)
		7:_flux(image,row,v,phase,t,fade,growth)
		8:_ridge(image,row,v,phase,t,fade,growth)
		9:_rune(image,row,v,phase,t,fade,growth)
		10:_ember(image,row,v,phase,t,fade,growth)
		11:_hearth(image,row,v,phase,t,fade,growth)
		12:_storm(image,row,v,phase,t,fade,growth)
		13:_slag(image,row,v,phase,t,fade,growth)
		14:_basalt(image,row,v,phase,t,fade,growth)
		15:_obsidian(image,row,v,phase,t,fade,growth)
	# A sprite can overlap the hero, but cannot erase the stable body identity.
	for y:int in range(84,137):
		for x:int in range(82,111):
			var c:=image.get_pixel(x,y)
			if c.a8>48:c.a8=48;image.set_pixel(x,y,c)
	for k:int in range(SIZE):
		for edge:int in [0,1,190,191]:
			image.set_pixel(k,edge,Color.TRANSPARENT);image.set_pixel(edge,k,Color.TRANSPARENT)

static func _c(row:Dictionary,index:int,alpha:float=1.0)->Color:
	var c:=P.color(row,index)
	var best:=0
	var delta:=999
	for a:int in ALPHAS:
		var d:=absi(a-roundi(clampf(alpha,0.0,1.0)*255.0))
		if d<delta:best=a;delta=d
	c.a8=best
	return c

static func _path(im:Image,pts:Array,c:Color,width:int=3)->void:
	for j:int in range(pts.size()-1):P.line(im,Vector2(pts[j]),Vector2(pts[j+1]),c,width)

static func _stroke(im:Image,row:Dictionary,pts:Array,width:int=4,a:float=1.0)->void:
	_path(im,pts,_c(row,0,a),width+4)
	_path(im,pts,_c(row,3,a),width)
	_path(im,pts,_c(row,5,a),maxi(1,width/3))

static func _slab(im:Image,row:Dictionary,pts:Array,a:float=1.0)->void:
	P.poly(im,pts,_c(row,0,a))
	var center:=Vector2.ZERO
	for p:Vector2 in pts:center+=p
	center/=float(pts.size())
	var inset:Array=[]
	for p:Vector2 in pts:inset.append(p.lerp(center,0.16))
	P.poly(im,inset,_c(row,2,a))
	if pts.size()>1:P.line(im,Vector2(pts[0])+Vector2(1,2),Vector2(pts[1])+Vector2(1,2),_c(row,4,a),2)

static func _spark(im:Image,row:Dictionary,p:Vector2,size:int,a:float=1.0)->void:
	P.rect(im,roundi(p.x)-size-2,roundi(p.y)-2,size*2+5,5,_c(row,0,a))
	P.rect(im,roundi(p.x)-2,roundi(p.y)-size-2,5,size*2+5,_c(row,0,a))
	P.rect(im,roundi(p.x)-size,roundi(p.y)-1,size*2+1,3,_c(row,4,a))
	P.rect(im,roundi(p.x)-1,roundi(p.y)-size,3,size*2+1,_c(row,5,a))

static func _dust(im:Image,row:Dictionary,t:float,a:float,seed:int=0,up:bool=false)->void:
	for j:int in range(11):
		var p:=Vector2(22+fposmod(float(j*37+seed*13),148.0),38+fposmod(float(j*19+seed*7)+(1.0-t if up else t)*28.0,130.0))
		var n:=2+(j+seed)%3
		P.rect(im,roundi(p.x),roundi(p.y),n,n+1,_c(row,4 if j%3 else 2,a*(0.6 if j%2 else 0.9)))

static func _arc(im:Image,row:Dictionary,center:Vector2,radii:Vector2,start:float,end:float,width:int,a:float=1.0)->void:
	var pts:Array=[]
	for j:int in range(15):
		var angle:=lerpf(start,end,float(j)/14.0)
		pts.append(center+Vector2(cos(angle)*radii.x,sin(angle)*radii.y))
	_stroke(im,row,pts,width,a)

static func _coil(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		for side:int in [-1,1]:
			var x:=96+side*(27+31*g)
			_slab(im,r,[Vector2(x-13,68+9*t),Vector2(x+9,60+9*t),Vector2(x+16,101),Vector2(x-7,113)],a)
			for j:int in range(4):
				var p:=Vector2(x-side*t*24,47+float(j*16)-t*15)
				P.ellipse(im,p,Vector2(11+4*j,5+j),_c(r,1,a*0.6))
			_stroke(im,r,[Vector2(x,116),Vector2(x-side*13,135),Vector2(96+side*12,130)],3,a)
	elif v==1:
		for side:int in [-1,1]:
			for j:int in range(3):
				var x:=96+side*(30+j*13)
				_slab(im,r,[Vector2(x-side*8,82+j*11),Vector2(x+side*15,76+j*11),Vector2(x+side*18,94+j*11),Vector2(x-side*6,101+j*11)],a*0.85)
				P.rect(im,x-side*7+side*roundi(t*17),83+j*11,4,3,_c(r,5,a*0.75))
			P.rect(im,66 if side<0 else 121,141,6,7,_c(r,4,a))
	elif v==2:
		for j:int in range(3):
			var x:=43+j*53
			var yy:=69+float(j%2)*20
			var close:=12.0*(1.0-t) if phase=="CONTACT" else 12.0*t
			_stroke(im,r,[Vector2(x-18-close,yy+43),Vector2(x-18-close,yy),Vector2(x+13+close,yy),Vector2(x+13+close,yy+32)],7,a)
			P.rect(im,x-24-roundi(close),roundi(yy)+26,13,11,_c(r,6,a))
			_spark(im,r,Vector2(x,yy+21),2+(j%2),a)
	else:
		for side:int in [-1,1]:
			var x:=96+side*24
			_slab(im,r,[Vector2(x-side*11,131),Vector2(x+side*13,133),Vector2(x+side*19,148),Vector2(x-side*8,148)],a*0.8)
			P.rect(im,x-3,141-roundi(t*4),6,4,_c(r,4,a))
	if not bool(r.passive):_dust(im,r,t,a*0.5,v,true)

static func _volt(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		var gap:=14+20*g
		for side:int in [-1,1]:
			var x:=96+side*gap
			_stroke(im,r,[Vector2(x,147),Vector2(x-side*11,111),Vector2(x+side*7,74),Vector2(x-side*6,36),Vector2(x+side*16,23)],4,a)
			_slab(im,r,[Vector2(x-8,46),Vector2(x+9,34),Vector2(x+15,53),Vector2(x-5,66)],a)
		for j:int in range(3):P.line(im,Vector2(57,54+j*29),Vector2(135,61+j*29),_c(r,6,a*0.65),2)
		# Current visibly advances along the two open woven rails after contact.
		# These knots are energy marks on existing strands, not extra victims.
		for j:int in range(3):
			var yy:=38.0+fposmod(t*83.0+float(j)*29.0,98.0)
			var side:=-1.0 if j%2==0 else 1.0
			_spark(im,r,Vector2(96.0+side*(gap-4.0+sin(yy*0.09)*5.0),yy),2,a*0.85)
	elif v==1:
		var y:=56+roundi(t*18)
		_stroke(im,r,[Vector2(17,120),Vector2(47,110),Vector2(37,y+29),Vector2(78,y+34),Vector2(65,y),Vector2(115,y+8),Vector2(137,31),Vector2(176,47)],5,a)
		_stroke(im,r,[Vector2(89,y+5),Vector2(117,112),Vector2(155,106),Vector2(170,142)],3,a*0.85)
		_spark(im,r,Vector2(139,31),5,a)
	elif v==2:
		for j:int in range(3):
			var y:=29+j*35
			_stroke(im,r,[Vector2(20+j*10,y+15),Vector2(56,y+7),Vector2(75,y+19),Vector2(101,y-3),Vector2(134,y+11),Vector2(175-j*4,y-10)],6-j,a)
			P.line(im,Vector2(44+j*26,37),Vector2(58+j*30,145),_c(r,3,a*0.65),3)
		_slab(im,r,[Vector2(62,30),Vector2(115,17),Vector2(143,34),Vector2(77,47)],a*0.85)
		_dust(im,r,t,a*0.55,15,true)
	else:
		for j:int in range(3):
			var x:=58+j*32
			var y:=137+((j+roundi(t*3))%3)*5
			_slab(im,r,[Vector2(x-10,y),Vector2(x+7,y-7),Vector2(x+13,y+4),Vector2(x-4,y+10)],a)
			P.rect(im,x-2,y-2,4,4,_c(r,5,a*(0.5+0.5*sin(t*TAU+float(j)))))

static func _gear(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		var x:=52+82*t if phase=="CAST" else 107.0
		_slab(im,r,[Vector2(x-47,83),Vector2(x+30,77),Vector2(x+54,91),Vector2(x+25,108),Vector2(x-47,105)],a)
		_stroke(im,r,[Vector2(x-38,93),Vector2(x+36,92)],5,a)
		for j:int in range(4):
			var px:=x-36+j*17
			P.rect(im,roundi(px),74-j%2*5,6,11,_c(r,4,a))
		_slab(im,r,[Vector2(39,132+t*22),Vector2(54,124+t*22),Vector2(62,138+t*22),Vector2(45,146+t*22)],a*0.8)
	elif v==1:
		for j:int in range(3):
			var center:=Vector2(48+j*45,73+float(j%2)*52)
			var radius:=15+j*7
			_arc(im,r,center,Vector2(radius,radius*0.7),t*TAU+j, t*TAU+j+4.8,5,a)
			for k:int in range(3):
				var ang:=t*TAU+float(k)*TAU/3.0+j
				var p:=center+Vector2(cos(ang)*radius,sin(ang)*radius*0.7)
				P.rect(im,roundi(p.x)-4,roundi(p.y)-4,8,7,_c(r,4,a))
	elif v==2:
		for j:int in range(3):
			var x:=40+j*49
			_slab(im,r,[Vector2(x-12,125),Vector2(x-12,67+j*9),Vector2(x+15,59+j*9),Vector2(x+22,82+j*9),Vector2(x+5,91+j*9),Vector2(x+9,128)],a*0.75)
			for k:int in range(4):
				var yy:=40+float(k*22)-t*31
				P.ellipse(im,Vector2(x+sin(t*TAU+k)*8,yy+16*j),Vector2(12+k*3,7+k),_c(r,1,a*0.6))
			P.rect(im,x-3,101-j*7,7,14,_c(r,4,a*0.8))
		_dust(im,r,t,a*0.7,22,true)
	else:
		_stroke(im,r,[Vector2(51,134),Vector2(51,146),Vector2(139,146),Vector2(139,133)],2,a*0.75)
		for j:int in range(3):P.rect(im,63+j*27,133-roundi(t*3),6,10+j*2,_c(r,4,a))

static func _medic(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		for j:int in range(4):
			var x:=36+j*39
			var yy:=146-float(j%2)*12
			_stroke(im,r,[Vector2(96,139),Vector2(96,153),Vector2(x,153),Vector2(x,yy)],3,a*0.9)
			P.rect(im,x-6,roundi(yy)-5,12,9,_c(r,2,a))
			P.rect(im,x-3,roundi(yy)-4,5,4,_c(r,4,a))
	elif v==1:
		var y:=43+22*t
		_slab(im,r,[Vector2(43,y),Vector2(64,y-8),Vector2(80,y+20),Vector2(63,y+39),Vector2(47,y+24)],a)
		_stroke(im,r,[Vector2(67,y+22),Vector2(58,106),Vector2(129,127),Vector2(150,96)],4,a)
		for j:int in range(6):
			var x:=55+j*18
			P.line(im,Vector2(x,112+j*2),Vector2(x+4,126+j*2),_c(r,5,a),3)
		P.ellipse(im,Vector2(144,84+12*t),Vector2(7,11),_c(r,4,a))
	elif v==2:
		_slab(im,r,[Vector2(22,57),Vector2(79,23),Vector2(164,45),Vector2(174,76),Vector2(112,60),Vector2(54,78)],a)
		for j:int in range(5):
			var x:=30+j*31
			_stroke(im,r,[Vector2(x,64),Vector2(x+4,103),Vector2(x+13,118+t*12)],3,a*0.8)
			P.ellipse(im,Vector2(x+13,128+t*12),Vector2(5,8),_c(r,4,a))
		_dust(im,r,t,a*0.5,3,true)
	else:
		for side:int in [-1,1]:
			var x:=96+side*36
			_slab(im,r,[Vector2(x-9,109),Vector2(x+10,104),Vector2(x+15,133),Vector2(x-7,140)],a*0.85)
			P.rect(im,x-3,111+roundi(t*9),5,8,_c(r,4,a))

static func _signal(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		for side:int in [-1,1]:
			var x:=96+side*49
			_stroke(im,r,[Vector2(x,140),Vector2(x,67)],3,a*0.8)
			_slab(im,r,[Vector2(x,70),Vector2(x+side*(28+4*sin(t*TAU)),75),Vector2(x+side*23,91),Vector2(x,85)],a)
			P.rect(im,x-3,133,7,7,_c(r,6,a))
	elif v==1:
		for side:int in [-1,1]:
			var x:=96+side*(22+24*(1.0-t) if phase=="CONTACT" else 22+24*t)
			_stroke(im,r,[Vector2(x-side*12,50),Vector2(x,50),Vector2(x,132),Vector2(x-side*16,132)],5,a)
			for j:int in range(4):P.rect(im,roundi(x)-3,64+j*16,6,5 if j%2 else 9,_c(r,4,a))
		_stroke(im,r,[Vector2(26,96),Vector2(53,96),Vector2(53,84)],2,a*0.7)
	elif v==2:
		for j:int in range(5):
			var x:=22+j*31
			var top:=30+(j*17)%33
			var fall:=t*18 if j%2 else -t*10
			_slab(im,r,[Vector2(x,top+fall),Vector2(x+19,top-7+fall),Vector2(x+24,135+fall),Vector2(x+4,143+fall)],a*0.85)
			for k:int in range(3):P.rect(im,x+3,top+20*k+roundi(fall),16,3,_c(r,6 if k%2 else 4,a*(0.55+0.4*sin(t*TAU+j))))
		_dust(im,r,t,a*0.45,4,true)
	else:
		var yy:=134-10*sin(t*PI)
		_slab(im,r,[Vector2(62,yy),Vector2(68,yy-14),Vector2(74,yy),Vector2(68,yy+8)],a)
		_stroke(im,r,[Vector2(112,143),Vector2(129,143),Vector2(129,128),Vector2(138,128)],2,a)

static func _piston(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		var push:=t*34 if phase=="CAST" else (1.0-t)*15
		for j:int in range(2):
			var y:=79+j*35
			var len:=89 if j==0 else 62
			_slab(im,r,[Vector2(23+push,y-11),Vector2(23+push+len,y-8),Vector2(40+push+len,y+3),Vector2(23+push+len,y+9),Vector2(23+push,y+10)],a)
			P.line(im,Vector2(38+push,y),Vector2(19+push+len,y),_c(r,5,a),3)
		_spark(im,r,Vector2(155,85),4,a)
	elif v==1:
		for j:int in range(3):
			var center:=Vector2(43+j*50,74+float(j%2)*49)
			_arc(im,r,center,Vector2(23,18),t*TAU+j, t*TAU+j+4.3,5,a)
			var p:=center+Vector2(cos(t*TAU+j)*25,sin(t*TAU+j)*18)
			_slab(im,r,[p+Vector2(-5,-7),p+Vector2(8,-2),p+Vector2(6,7),p+Vector2(-7,5)],a)
	elif v==2:
		var shift:=25*(1.0-t) if phase=="CONTACT" else 25*t
		_slab(im,r,[Vector2(17,51+shift),Vector2(171,67+shift),Vector2(169,85+shift),Vector2(20,70+shift)],a)
		_slab(im,r,[Vector2(28,128-shift),Vector2(158,105-shift),Vector2(173,121-shift),Vector2(33,147-shift)],a)
		for j:int in range(7):P.line(im,Vector2(34+j*20,80+shift),Vector2(43+j*19,101-shift),_c(r,4,a),4)
		_spark(im,r,Vector2(149,86),5,a*0.8)
	else:
		for j:int in range(3):
			P.rect(im,53+j*31,131-j*3,17+j*3,4,_c(r,4,a*(0.55+0.4*sin(t*TAU+j))))
			P.rect(im,53+j*31,128-j*3,3,12,_c(r,2,a))

static func _rivet(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		var open:=8+26*t
		_slab(im,r,[Vector2(49-open,47),Vector2(88-open,73),Vector2(139-open,134),Vector2(116-open,144)],a)
		_slab(im,r,[Vector2(126+open,43),Vector2(143+open,65),Vector2(87+open,118),Vector2(62+open,110)],a)
		_stroke(im,r,[Vector2(54,145),Vector2(85,117),Vector2(93,103),Vector2(116,79),Vector2(140,56)],3,a)
		_dust(im,r,t,a*0.65,6)
	elif v==1:
		for side:int in [-1,1]:
			var x:=96+side*(31+7*sin(t*PI))
			_slab(im,r,[Vector2(x-13,65),Vector2(x+14,71),Vector2(x+18,126),Vector2(x-18,137)],a)
			for j:int in range(2):P.rect(im,roundi(x)-9,85+j*25,18,4,_c(r,4,a))
	elif v==2:
		var ends:Array=[Vector2(29,70),Vector2(62,31),Vector2(137,34),Vector2(170,101)]
		for j:int in range(4):
			var e:Vector2=ends[j]
			_stroke(im,r,[Vector2(96,76),Vector2(e.x,76),e],4,a*0.9)
			_slab(im,r,[e+Vector2(-10,-9),e+Vector2(13,-5),e+Vector2(10,12),e+Vector2(-10,9)],a)
			P.rect(im,roundi(e.x)-5,roundi(e.y)-2,10,4,_c(r,5,a*(0.7+0.3*sin(t*TAU+j))))
		_slab(im,r,[Vector2(55,143),Vector2(130,143),Vector2(142,157),Vector2(45,157)],a*0.7)
	else:
		for side:int in [-1,1]:
			var x:=96+side*37
			_stroke(im,r,[Vector2(x-side*13,121),Vector2(x,144),Vector2(x+side*21,149)],5,a*0.85)
			P.rect(im,x-3,136,7,5,_c(r,4,a))

static func _flux(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		for j:int in range(2):_arc(im,r,Vector2(45+j*49,91),Vector2(18+j*4,39-j*7),-1.8+t,1.7+t,5,a*0.9)
		_slab(im,r,[Vector2(20,84),Vector2(145,80),Vector2(179,92),Vector2(143,103),Vector2(20,100)],a)
		_stroke(im,r,[Vector2(28,92),Vector2(164,92)],6,a)
		for j:int in range(6):P.rect(im,33+j*22,112+roundi(sin(t*TAU+j)*4),11,3,_c(r,6,a*0.7))
	elif v==1:
		_stroke(im,r,[Vector2(36,145),Vector2(60,103),Vector2(83,112),Vector2(100,71),Vector2(99,28)],7,a)
		_stroke(im,r,[Vector2(75,115),Vector2(123,106),Vector2(145,134),Vector2(171,125)],4,a)
		_stroke(im,r,[Vector2(98,73),Vector2(135,58),Vector2(159,29)],4,a)
		for p:Vector2 in [Vector2(36,145),Vector2(171,125),Vector2(159,29)]:_spark(im,r,p,4,a)
		# Relay beads move along the authored conductors instead of freezing on hit.
		var relay_paths:Array=[[Vector2(36,145),Vector2(60,103),Vector2(83,112),Vector2(100,71),Vector2(99,28)],[Vector2(75,115),Vector2(123,106),Vector2(145,134),Vector2(171,125)],[Vector2(98,73),Vector2(135,58),Vector2(159,29)]]
		for j:int in range(relay_paths.size()):
			var points:Array=relay_paths[j]
			var progress:=fposmod(t*0.88+float(j)*0.23,1.0)*float(points.size()-1)
			var segment:=mini(points.size()-2,floori(progress))
			var point:Vector2=Vector2(points[segment]).lerp(Vector2(points[segment+1]),fposmod(progress,1.0))
			P.rect(im,roundi(point.x)-3,roundi(point.y)-3,7,6,_c(r,5,a))
	elif v==2:
		var open:=0.45+0.55*t if phase=="CONTACT" else g
		for j:int in range(7):
			var ang:=float(j)*TAU/7.0+t*0.3
			var n:=Vector2(cos(ang),sin(ang)*0.78)
			var q:=Vector2(96,96)+n*(29+35*open)
			var tang:=Vector2(-n.y,n.x)*12
			_slab(im,r,[Vector2(96,96)+n*14,q+tang,q+n*(16+float(j%3)*4),q-tang],a)
		P.ellipse(im,Vector2(96,96),Vector2(15,18),_c(r,0,a))
		P.ellipse(im,Vector2(96,91),Vector2(10,12),_c(r,5,a*(1.0-t*0.6)))
		_dust(im,r,t,a*0.8,7)
	else:
		for j:int in range(2):
			var x:=64+j*66
			_slab(im,r,[Vector2(x-11,132-j*8),Vector2(x+9,127-j*8),Vector2(x+13,146-j*8),Vector2(x-7,149-j*8)],a)
			_spark(im,r,Vector2(x,135-j*8),2,a*(0.55+0.4*sin(t*TAU+float(j)*PI)))

static func _ridge(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		for side:int in [-1,1]:
			var x:=96+side*(33+16*g)
			_slab(im,r,[Vector2(x-17,58),Vector2(x+13,51),Vector2(x+22,122),Vector2(x-14,133)],a)
			_stroke(im,r,[Vector2(x,128),Vector2(x-side*7,112),Vector2(96+side*12,121)],4,a)
			for j:int in range(4):P.rect(im,roundi(x)+j*4-8,32+j*26+roundi(t*18),4,7,_c(r,4,a*0.8))
	elif v==1:
		for j:int in range(4):
			var side:=-1 if j<2 else 1
			var x:=96+side*(31+(j%2)*22)
			_slab(im,r,[Vector2(x-14,83+(j%2)*17),Vector2(x+13,73+(j%2)*19),Vector2(x+19,112+(j%2)*15),Vector2(x-14,121+(j%2)*15)],a)
			P.line(im,Vector2(x-9,93+(j%2)*17),Vector2(x+11,88+(j%2)*17),_c(r,6,a),2)
			P.rect(im,x-8+roundi(t*18),88+(j%2)*17,4,3,_c(r,4,a))
	elif v==2:
		for j:int in range(5):
			var x:=18+j*31
			var y:=117-float(j%2)*19-13*sin(t*PI+float(j)*0.45)
			_slab(im,r,[Vector2(x,y),Vector2(x+18,y-38-float(j%3)*7),Vector2(x+31,y-18),Vector2(x+30,y+19)],a)
			P.line(im,Vector2(x+12,y-24),Vector2(x+26,y-9),_c(r,6,a),3)
		_stroke(im,r,[Vector2(21,150),Vector2(55,142),Vector2(79,150),Vector2(116,133),Vector2(168,142)],4,a*0.8)
		_dust(im,r,t,a*0.75,8)
	else:
		_stroke(im,r,[Vector2(52,137),Vector2(63,137),Vector2(63,151),Vector2(140,151),Vector2(140,131)],2,a*0.8)
		for j:int in range(3):P.rect(im,66+j*24,140,5,6+roundi(t*3),_c(r,6,a))

static func _rune(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		_slab(im,r,[Vector2(49,47),Vector2(139,47),Vector2(123,74+12*t),Vector2(66,74+12*t)],a)
		for side:int in [-1,1]:
			var x:=96+side*(29+22*(1.0-t))
			_stroke(im,r,[Vector2(x,75),Vector2(x,139),Vector2(x-side*15,139)],6,a)
			for j:int in range(3):P.rect(im,roundi(x)-3,82+j*17,6,6,_c(r,4,a))
	elif v==1:
		_slab(im,r,[Vector2(31,126),Vector2(49,96),Vector2(77,105),Vector2(106,87),Vector2(137,101),Vector2(168,128),Vector2(139,148),Vector2(64,143)],a*0.8)
		for j:int in range(7):
			var x:=30+j*22
			var y:=90-float((j*17)%40)-sin(t*PI)*28
			_slab(im,r,[Vector2(x,y),Vector2(x+6,y-13),Vector2(x+12,y+7),Vector2(x+4,y+16)],a)
			P.rect(im,x+4,roundi(y),4,8,_c(r,5,a))
		_dust(im,r,t,a*0.6,9)
	elif v==2:
		for j:int in range(3):
			var yy:=44+j*43
			var tip:=160-float(j)*12+10*sin(t*PI+float(j))
			_slab(im,r,[Vector2(24,96),Vector2(70,yy+4),Vector2(tip,yy-13),Vector2(tip-19,yy+10),Vector2(100,yy+23),Vector2(54,110)],a)
			_stroke(im,r,[Vector2(29,96),Vector2(82,yy+14),Vector2(tip-13,yy+3)],5,a)
		_dust(im,r,t,a*0.7,19,true)
	else:
		for j:int in range(3):
			var x:=56+j*39
			P.rect(im,x,132-j%2*5,5,15,_c(r,2,a))
			P.rect(im,x,136-j%2*5,9,3,_c(r,4,a*(0.6+0.35*sin(t*TAU+j))))

static func _ember(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		var y:=39+56*t if phase=="CAST" else 69.0
		_slab(im,r,[Vector2(121,y-20),Vector2(134,y+13),Vector2(126,y+79),Vector2(119,y+94),Vector2(114,y+77),Vector2(116,y+15)],a)
		_stroke(im,r,[Vector2(124,y-10),Vector2(123,y+76)],3,a)
		for j:int in range(5):P.rect(im,130+j*7,roundi(y)+j*12,4,6,_c(r,4,a*0.7))
		# Detached sand has weight after the barb settles; the main spear stays put.
		for j:int in range(6):
			var sand:=Vector2(105.0+float((j*17)%61)+t*float(j-2)*3.0,89.0+float(j)*9.0+t*29.0)
			P.rect(im,roundi(sand.x),roundi(sand.y),3+j%2,4,_c(r,4 if j%2 else 2,a*0.85))
	elif v==1:
		for j:int in range(3):
			var yy:=70+j*24
			var x:=23+fposmod(t*75+float(j*21),70.0)
			_slab(im,r,[Vector2(x,yy-5),Vector2(x+68,yy-8),Vector2(174,yy),Vector2(x+68,yy+8),Vector2(x,yy+4)],a*0.8)
			for k:int in range(6):P.rect(im,roundi(x)+k*15,yy+10+(k%2)*3,5 if k%3 else 8,3,_c(r,4,a))
	elif v==2:
		_slab(im,r,[Vector2(53,32),Vector2(75,34),Vector2(157,129),Vector2(171,155),Vector2(143,143),Vector2(62,58)],a)
		_stroke(im,r,[Vector2(66,44),Vector2(151,137)],9,a)
		_slab(im,r,[Vector2(135,138),Vector2(147,113),Vector2(176,165),Vector2(144,153)],a)
		for j:int in range(8):
			var angle:=float(j)*TAU/8.0
			var p:=Vector2(139,130)+Vector2(cos(angle)*41,sin(angle)*27)*(0.4+0.6*t)
			P.rect(im,roundi(p.x),roundi(p.y),4+j%3,3,_c(r,4,a))
	else:
		for j:int in range(3):
			P.rect(im,57+j*31,137-j%2*8,14,5,_c(r,2,a))
			if j==2:_spark(im,r,Vector2(127,136-roundi(sin(t*PI)*4)),3,a)
			else:P.rect(im,59+j*31,138-j%2*8,6,2,_c(r,3,a))

static func _hearth(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		_slab(im,r,[Vector2(39,129),Vector2(55,100),Vector2(133,100),Vector2(151,132),Vector2(129,150),Vector2(59,150)],a*0.75)
		for j:int in range(5):
			var x:=57+j*18
			P.rect(im,x,117+j%2*7,7,5,_c(r,4,a*(0.6+0.35*sin(t*TAU+j))))
		for j:int in range(3):P.ellipse(im,Vector2(53+j*43,81-t*11),Vector2(13+j*2,6),_c(r,1,a*0.45))
	elif v==1:
		for j:int in range(3):
			var yy:=52+j*30-8*sin(t*PI)
			_slab(im,r,[Vector2(38+j*7,yy+19),Vector2(62,yy),Vector2(126,yy+7),Vector2(157-j*8,yy+30),Vector2(125,yy+39),Vector2(57,yy+30)],a*0.8)
			P.line(im,Vector2(55+j*6,yy+25),Vector2(138-j*5,yy+26),_c(r,4,a),3)
		_dust(im,r,t,a*0.5,11,true)
	elif v==2:
		_slab(im,r,[Vector2(19,86),Vector2(57,37),Vector2(114,25),Vector2(171,62),Vector2(159,91),Vector2(116,59),Vector2(58,68)],a*0.85)
		for side:int in [-1,1]:
			var x:=96+side*64
			_stroke(im,r,[Vector2(x,84),Vector2(x,137),Vector2(x-side*20,157)],6,a)
			P.ellipse(im,Vector2(x,145),Vector2(13,10),_c(r,0,a))
			P.ellipse(im,Vector2(x,142),Vector2(7,6),_c(r,4,a))
		for j:int in range(5):_spark(im,r,Vector2(35+j*29,117-8*sin(t*TAU+j)),2,a*0.8)
	else:
		for side:int in [-1,1]:
			var x:=96+side*32
			_slab(im,r,[Vector2(x-12,119),Vector2(x+6,114),Vector2(x+14,135),Vector2(x,144),Vector2(x-15,136)],a*0.85)
			P.rect(im,x-3,125-roundi(t*3),5,4,_c(r,5,a))

static func _storm(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		for j:int in range(3):
			var x:=47+j*49
			_stroke(im,r,[Vector2(x,146),Vector2(x,86-j*11)],3,a*0.9)
			_slab(im,r,[Vector2(x,87-j*11),Vector2(x+25,80-j*11+sin(t*TAU+j)*5),Vector2(x+17,101-j*11),Vector2(x,106-j*11)],a)
			P.line(im,Vector2(x,146),Vector2(x+15,154),_c(r,6,a*0.8),2)
	elif v==1:
		_stroke(im,r,[Vector2(49,22),Vector2(40,54),Vector2(63,54),Vector2(49,91),Vector2(74,118)],6,a)
		_slab(im,r,[Vector2(58,105),Vector2(90,93),Vector2(108,110),Vector2(74,129)],a)
		_stroke(im,r,[Vector2(74,129),Vector2(107,135),Vector2(119,122),Vector2(145,134),Vector2(173,126)],4,a)
		for j:int in range(4):P.rect(im,85+j*22,143,7,3,_c(r,4,a*(0.55+0.4*sin(t*TAU+j))))
	elif v==2:
		var pts:Array=[Vector2(27,34),Vector2(51,65),Vector2(77,53),Vector2(66,87),Vector2(104,102),Vector2(129,81),Vector2(122,123),Vector2(164,151)]
		_stroke(im,r,pts,8,a)
		for j:int in range(1,pts.size(),2):
			var p:Vector2=pts[j]
			_slab(im,r,[p+Vector2(-9,-6),p+Vector2(7,-12),p+Vector2(12,6),p+Vector2(-7,11)],a)
		_stroke(im,r,[Vector2(76,54),Vector2(124,24),Vector2(148,48)],4,a*0.8)
		_dust(im,r,t,a*0.6,12,true)
	else:
		_stroke(im,r,[Vector2(61,149),Vector2(61,125),Vector2(78,125)],2,a)
		_slab(im,r,[Vector2(62,126),Vector2(82,120),Vector2(76,136),Vector2(62,137)],a)
		for j:int in range(3):P.rect(im,105+j*14,138+roundi(sin(t*TAU+j)*3),5,6,_c(r,4,a))

static func _slag(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		var gap:=14*(1.0-t) if phase=="CONTACT" else 14*t
		_slab(im,r,[Vector2(30,117+gap),Vector2(126,103+gap),Vector2(159,119),Vector2(123,128+gap),Vector2(37,131+gap)],a)
		_slab(im,r,[Vector2(155,53-gap),Vector2(125,94-gap),Vector2(64,133),Vector2(81,109-gap),Vector2(138,48-gap)],a)
		P.line(im,Vector2(42,122+gap),Vector2(145,119),_c(r,6,a),4)
		_stroke(im,r,[Vector2(140,58-gap),Vector2(90,111-gap)],3,a)
	elif v==1:
		for j:int in range(2):
			var x:=48+j*79
			var yy:=34+j*23
			_slab(im,r,[Vector2(x-9,yy+95),Vector2(x-9,yy+15),Vector2(x+2,yy),Vector2(x+12,yy+14),Vector2(x+10,yy+97)],a)
			P.line(im,Vector2(x+1,yy+21),Vector2(x+1,yy+83),_c(r,5,a*(0.75+0.25*sin(t*TAU+j))),5)
			for k:int in range(4):P.rect(im,x-19+(k%2)*35,yy+k*23,3,8,_c(r,4,a*0.7))
	elif v==2:
		_arc(im,r,Vector2(96,93),Vector2(73,55),-2.6+0.5*t,-0.1+0.5*t,11,a)
		_stroke(im,r,[Vector2(37,42),Vector2(85,77),Vector2(119,126),Vector2(150,158)],10,a)
		P.line(im,Vector2(153,44),Vector2(41,144),_c(r,6,a),7)
		_path(im,[Vector2(154,44),Vector2(117,78),Vector2(106,96),Vector2(69,119),Vector2(41,144)],_c(r,5,a),3)
		for j:int in range(6):P.ellipse(im,Vector2(35+j*25,151-t*29+float(j%2)*8),Vector2(10,5),_c(r,1,a*0.45))
		_dust(im,r,t,a*0.7,13)
	else:
		_stroke(im,r,[Vector2(54,141),Vector2(68,128),Vector2(78,132)],2,a)
		P.line(im,Vector2(117,132),Vector2(140,145),_c(r,6,a),4)
		P.rect(im,67,129-roundi(t*3),5,4,_c(r,4,a))

static func _basalt(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		for j:int in range(3):
			var y:=76+j*29+float(j%2)*8*t
			_slab(im,r,[Vector2(40+j*8,y),Vector2(121+j*9,y-8),Vector2(153-j*3,y+15),Vector2(59-j*5,y+23)],a)
		_stroke(im,r,[Vector2(119,46),Vector2(105,83),Vector2(112,111),Vector2(91,139)],4,a)
		_dust(im,r,t,a*0.65,14)
	elif v==1:
		for side:int in [-1,1]:
			for j:int in range(3):
				var x:=96+side*(27+j*12)
				_slab(im,r,[Vector2(x-side*9,84+j*14),Vector2(x+side*17,76+j*12),Vector2(x+side*21,95+j*13),Vector2(x-side*7,106+j*14)],a*0.85)
				P.rect(im,x+side*roundi(t*15),84+j*13,4,3,_c(r,4,a*0.85))
	elif v==2:
		for j:int in range(3):
			var xx:=34+j*47
			var yy:=58+(j%2)*31
			var shift:=8*sin(t*PI+float(j))
			_slab(im,r,[Vector2(xx-15,yy+shift),Vector2(xx+25,yy-17+shift),Vector2(xx+36,yy+49),Vector2(xx+3,yy+69)],a)
			P.line(im,Vector2(xx-4,yy+17),Vector2(xx+21,yy+8),_c(r,6,a),5)
		_stroke(im,r,[Vector2(20,153),Vector2(69,151),Vector2(96,139),Vector2(124,154),Vector2(169,151)],5,a*0.8)
	else:
		for j:int in range(3):
			var x:=45+j*38
			_slab(im,r,[Vector2(x,129-j%2*9),Vector2(x+25,122-j%2*9),Vector2(x+30,143),Vector2(x+4,151)],a*0.8)
			P.line(im,Vector2(x+5,134),Vector2(x+20,130),_c(r,4,a*(0.65+0.3*sin(t*TAU+j))),2)

static func _obsidian(im:Image,r:Dictionary,v:int,phase:String,t:float,a:float,g:float)->void:
	if v==0:
		_slab(im,r,[Vector2(19,124),Vector2(48,100),Vector2(82,109),Vector2(108,86),Vector2(151,100),Vector2(173,133),Vector2(142,153),Vector2(83,148),Vector2(51,160)],a)
		for j:int in range(7):
			var x:=33+j*22
			var y:=103-float((j*19)%51)-sin(t*PI)*18
			_slab(im,r,[Vector2(x-7,y+29),Vector2(x+3,y-12),Vector2(x+11,y+13),Vector2(x+4,y+33)],a)
			P.line(im,Vector2(x+2,y+1),Vector2(x+6,y+18),_c(r,5,a*0.85),2)
	elif v==1:
		_slab(im,r,[Vector2(18,81),Vector2(166,65),Vector2(177,106),Vector2(28,125)],a*0.85)
		var pts:Array=[Vector2(22,104),Vector2(51,96),Vector2(76,104),Vector2(103,88),Vector2(128,93),Vector2(169,77)]
		_stroke(im,r,pts,5,a)
		for j:int in range(8):
			var x:=26+j*19
			var y:=78-float(j%3)*12-t*23
			P.rect(im,x,roundi(y),4,10,_c(r,6,a*0.8))
	elif v==2:
		var origin:=Vector2(38,124)
		for j:int in range(8):
			var angle:=-1.34+float(j)*0.22
			var length:=99+float((j*19)%47)
			var n:=Vector2(cos(angle),sin(angle))
			var tang:=Vector2(-n.y,n.x)*(7+float(j%3)*2)
			var tip:=origin+n*length*(0.65+0.35*g)
			_slab(im,r,[origin+n*13,tip-tang,tip+n*11,tip+tang],a)
			P.line(im,origin+n*31,tip,_c(r,4 if j%2 else 5,a),2)
		_dust(im,r,t,a*0.65,15,true)
	else:
		for j:int in range(3):
			var x:=56+j*32
			_slab(im,r,[Vector2(x-4,131),Vector2(x+12,128),Vector2(x+15,145),Vector2(x-5,148)],a*0.8)
			P.rect(im,x,134-roundi(sin(t*PI)*3),8,3,_c(r,4,a*(0.6+0.35*sin(t*TAU+float(j)*1.6))))
