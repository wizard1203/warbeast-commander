extends RefCounted
## V5 original authored HUMAN / UNDEAD choreography; presentation only.
## 192px, 12 poses, canonical +X, stable foot (96,136).
## Root dispatcher owns real target relations, lifetime, visibility and caches.
const Pixels = preload("res://src/presentation/heroic_roster_v5_pixels.gd")
const CinderV4 = preload("res://src/presentation/heroic_r7_cinder_spectacle.gd")
const VERSION := "hero-roster-v5-human-undead-20261102-v1"
const SIZE := 192
const FRAMES := 12
const ANCHOR := Vector2(96,136)
const PHASES := ["CAST","CONTACT","TAIL","AURA"]
const INNATE_HERO := {
	"COMMANDER": "INNATE_COMMANDER",
	"BULWARK": "INNATE_BULWARK",
	"ARCANIST": "INNATE_ARCANIST",
	"RANGER": "INNATE_RANGER",
	"DUELIST": "INNATE_DUELIST",
	"OATH_REAVER": "INNATE_OATH_REAVER",
	"BRIDGE_VANGUARD": "INNATE_BRIDGE_VANGUARD",
	"SUNGLASS_SCRIBE": "INNATE_SUNGLASS_SCRIBE",
	"ASH_MARSHAL": "INNATE_ASH_MARSHAL",
	"MOURN_ORACLE": "INNATE_MOURN_ORACLE",
	"CINDER_STALKER": "INNATE_CINDER_STALKER",
	"ASH_CHANTER": "INNATE_ASH_CHANTER",
	"GRAVE_BELL": "INNATE_GRAVE_BELL",
	"RELIC_REAVER": "INNATE_RELIC_REAVER",
	"OSSUARY_KNIGHT": "INNATE_OSSUARY_KNIGHT",
	"CINDER_TESTATOR": "INNATE_CINDER_TESTATOR"
}
const PROFILES := {
	"CLEAVE":{"hero":"COMMANDER","faction":"HUMAN","name":"协战光环","material":"COPPER_CLOTH","motif":"borrowed-seal-banner","form":"split-pennant-abacus","gesture":"抬起折页肩旗，腰算盘同拍","connection":"友军归属线是碎红布接缝","palette":["17151d","702d42","b75c59","e9b986","f9ecd0","6db8b3","f7db90"],"story":"渡口账房把撕开的航图用于急救，以铜印和青瓷补线重新承诺归途。","cast_notes":"两片不等长布签从肩后展开","contact_notes":"受益者只出现小铜扣，无敌人受击","tail_notes":"旗尾保持布料折角，来源失效即收束","passive":true,"shape":"banner","variant":1,"route_mode":1},
	"RECOVER":{"hero":"COMMANDER","faction":"HUMAN","name":"誓图重整","material":"PORCELAIN_THREAD","motif":"map-suture-stream","form":"porcelain-river-stitches","gesture":"撕图后双掌沿缺口合拢","connection":"青瓷补线顺真实受益者收针","palette":["17151d","702d42","b75c59","e9b986","f9ecd0","6db8b3","f7db90"],"story":"渡口账房把撕开的航图用于急救，以铜印和青瓷补线重新承诺归途。","cast_notes":"上举撕裂地图，红布与青线逆向展开","contact_notes":"三道不等长瓷缝在伤处缝合，不爆炸","tail_notes":"小瓷屑向上收回，余白恢复","passive":false,"shape":"suture","variant":2,"route_mode":5},
	"RALLY":{"hero":"COMMANDER","faction":"HUMAN","name":"断约裁印","material":"COPPER_SEAL","motif":"revoked-debt-stamp","form":"hanging-copper-execution","gesture":"举铜印、悬停后果断压掌","connection":"一条折断账线连向真实单体命中","palette":["17151d","702d42","b75c59","e9b986","f9ecd0","6db8b3","f7db90"],"story":"渡口账房把撕开的航图用于急救，以铜印和青瓷补线重新承诺归途。","cast_notes":"沉重铜印从斜后方抬起，红布抽紧","contact_notes":"单体方印以暗影先落、铜芯后压；不群伤","tail_notes":"断开的短红线与铜粉向两侧散去","passive":false,"shape":"stamp","variant":3,"route_mode":4},
	"SHIELD_SHOCK":{"hero":"BULWARK","faction":"HUMAN","name":"盾心恢复","material":"IRON_WOOD","motif":"sluice-repair-wedges","form":"rising-repair-crossbraces","gesture":"闸盾内收、肩架抬高","connection":"维修光点沿盾内木楔回到自身","palette":["141d24","334452","617b83","b8c5ba","f4efcc","d59d56","77c9c5"],"story":"闸门盾、铁钩与承重木楔属于断桥托梁人，防线永远留有撤离出口。","cast_notes":"三枚承重楔从下向上托住盾侧","contact_notes":"盾缝出现温暖竖向修补光，不冲击敌人","tail_notes":"楔形亮片沉回脚旁，避免治疗画成护盾","passive":false,"shape":"repair","variant":4,"route_mode":5},
	"BULWARK_WARD":{"hero":"BULWARK","faction":"HUMAN","name":"不屈甲胄","material":"IRON_WOOD","motif":"asymmetric-brace","form":"two-unmatched-gate-braces","gesture":"静止时盾钩轻扣木楔","connection":"实际结阵队友由短钩标记辨认","palette":["141d24","334452","617b83","b8c5ba","f4efcc","d59d56","77c9c5"],"story":"闸门盾、铁钩与承重木楔属于断桥托梁人，防线永远留有撤离出口。","cast_notes":"一高一低木铁撑架卡入侧翼","contact_notes":"被动护甲用受击侧小楔回应","tail_notes":"只保留不对称支撑，不造封闭无敌罩","passive":true,"shape":"brace","variant":5,"route_mode":5},
	"BULWARK_RECOVER":{"hero":"BULWARK","faction":"HUMAN","name":"垒盾震慑","material":"SLUICE_IRON","motif":"falling-gate-teeth","form":"interrupted-control-gate","gesture":"举盾顿地、铁钩先震后落","connection":"控制由竖闸齿逐层卡定","palette":["141d24","334452","617b83","b8c5ba","f4efcc","d59d56","77c9c5"],"story":"闸门盾、铁钩与承重木楔属于断桥托梁人，防线永远留有撤离出口。","cast_notes":"巨大闸门齿在背后错位抬起","contact_notes":"真实受控目标上方落下断续闸齿，无伤害爆破","tail_notes":"齿条松开回弹，灰尘比亮芯慢半拍","passive":false,"shape":"gate","variant":6,"route_mode":6},
	"STARFIRE":{"hero":"ARCANIST","faction":"HUMAN","name":"星火","material":"BROKEN_PRISM","motif":"off-axis-star-comb","form":"uneven-prism-fan","gesture":"测角架张开，手腕分开误差轴","connection":"不等长棱光沿真实扇向展开","palette":["171827","383b70","6766a5","a5c8df","f6eed9","d383ba","7be5d2"],"story":"河口磨镜匠砸碎预言镜，以误差、测角架和破边棱镜反抗命定轨道。","cast_notes":"五片破边镜从肩后倾斜折开","contact_notes":"扇形切光是斜长镜屑而非火球","tail_notes":"偏折光逐条分离，暗面先失亮","passive":false,"shape":"prism_fan","variant":7,"route_mode":1},
	"FROST_BIND":{"hero":"ARCANIST","faction":"HUMAN","name":"霜契","material":"FROST_GLASS","motif":"missing-sector-astrolabe","form":"single-frost-jaw","gesture":"双手旋定缺口测角尺","connection":"单体冰尺在脚侧闭合而非拉拽","palette":["171827","383b70","6766a5","a5c8df","f6eed9","d383ba","7be5d2"],"story":"河口磨镜匠砸碎预言镜，以误差、测角架和破边棱镜反抗命定轨道。","cast_notes":"半月测量尺从低到高咬合","contact_notes":"两支棱冰脚锁卡住实际目标，不画群爆","tail_notes":"冰尺碎为窄标度，控制到期由真实状态关闭","passive":false,"shape":"ice_jaw","variant":8,"route_mode":2},
	"ARCANE_BURST":{"hero":"ARCANIST","faction":"HUMAN","name":"星核裁决","material":"STAR_GLASS","motif":"misaligned-star-collapse","form":"single-collapsing-star-cage","gesture":"两块镜面交错锁定一个误差点","connection":"单体折光汇聚到真正命中位置","palette":["171827","383b70","6766a5","a5c8df","f6eed9","d383ba","7be5d2"],"story":"河口磨镜匠砸碎预言镜，以误差、测角架和破边棱镜反抗命定轨道。","cast_notes":"三轴星核从背后升起，中心保留黑色缺口","contact_notes":"多层错轴星核内压于单体，再甩出镜影","tail_notes":"星核碎片绕缺口下落，减速不伪装定身","passive":false,"shape":"star_cage","variant":9,"route_mode":7},
	"PIERCING_SHOT":{"hero":"RANGER","faction":"HUMAN","name":"贯弦","material":"RAIN_KITE","motif":"wet-kite-thread-pierce","form":"long-asymmetric-arrow","gesture":"折叠弓拉长，纸鸢尾受力","connection":"湿绳尾线追随真实穿刺方向","palette":["19202a","375666","6b9fba","b1d9d5","f8edd0","e4a487","f5d668"],"story":"封航港口的药单信使，用纸鸢骨架作弓，让回信沿雨丝与湿绳穿越逆风。","cast_notes":"长弦弯曲蓄势，三条雨丝向弓尖收束","contact_notes":"细长钢箭与两侧断绳沿直线抽过","tail_notes":"断鸢线弹回两侧，留细雨而非圆爆","passive":false,"shape":"kite_arrow","variant":10,"route_mode":4},
	"ARROW_RAIN":{"hero":"RANGER","faction":"HUMAN","name":"箭雨","material":"PAPER_RAIN","motif":"staggered-roof-shower","form":"slanting-kite-arrow-shower","gesture":"弓梢上挑，纸鸢尾甩开高弧","connection":"箭影由高处斜降到实际命中区","palette":["19202a","375666","6b9fba","b1d9d5","f8edd0","e4a487","f5d668"],"story":"封航港口的药单信使，用纸鸢骨架作弓，让回信沿雨丝与湿绳穿越逆风。","cast_notes":"叠开的三角纸鸢构成不对称发射架","contact_notes":"七支错时斜箭伴细绳落下，不新增命中","tail_notes":"箭尾雨点顺斜向滑走，地面无持久伤害场","passive":false,"shape":"arrow_rain","variant":11,"route_mode":6},
	"QUICKDRAW":{"hero":"RANGER","faction":"HUMAN","name":"追风齐射","material":"KITE_STRING","motif":"three-taut-bow-limbs","form":"open-wind-bow-harness","gesture":"拉弦肘抬高，披风向后张紧","connection":"强化亮线只留在弓臂与背后","palette":["19202a","375666","6b9fba","b1d9d5","f8edd0","e4a487","f5d668"],"story":"封航港口的药单信使，用纸鸢骨架作弓，让回信沿雨丝与湿绳穿越逆风。","cast_notes":"三道弓臂虚影依次张开，纸签逆风翘起","contact_notes":"自强化在武器上成形，不向敌军爆炸","tail_notes":"有限增益期间保留弦光，次数／期限归真实状态","passive":false,"shape":"bow_empower","variant":12,"route_mode":3},
	"SEAL_STRIKE":{"hero":"DUELIST","faction":"HUMAN","name":"行阵光环","material":"INK_MEASURE","motif":"suspended-ruler-spacing","form":"measured-march-brackets","gesture":"尺剑立起、印条按步轻摆","connection":"行军脚距由对称短尺标而非大环","palette":["161b23","384953","7d9797","d1d7bf","fcf4d7","bb7c88","79b8b2"],"story":"船厂调解员持未开锋的量尺剑，以口令、横栏与墨白证词保护说话者。","cast_notes":"黑白尺标在左右留出一条通路","contact_notes":"友军脚边出现小段错位步尺","tail_notes":"长期身份纹不覆盖地面范围，不新增加速","passive":true,"shape":"march","variant":13,"route_mode":5},
	"WHIRLWIND":{"hero":"DUELIST","faction":"HUMAN","name":"封刃震","material":"INK_BINDING","motif":"scissor-seal-arrest","form":"single-crossed-ruler-clamp","gesture":"两手短促错尺，剑背侧压","connection":"单个被控者收到交叉封条","palette":["161b23","384953","7d9797","d1d7bf","fcf4d7","bb7c88","79b8b2"],"story":"船厂调解员持未开锋的量尺剑，以口令、横栏与墨白证词保护说话者。","cast_notes":"一长一短量尺从两侧抬起","contact_notes":"单体交尺卡定伴墨点，无刀刃伤害浪潮","tail_notes":"封条沿垂直方向分离，纯眩晕不作斩杀","passive":false,"shape":"ruler_clamp","variant":14,"route_mode":2},
	"BLOOD_PACT":{"hero":"DUELIST","faction":"HUMAN","name":"止戈令","material":"INK_BANNERS","motif":"witness-silence-columns","form":"open-court-order-canopy","gesture":"举起空白证词、展开横栏","connection":"群控由开口证词柱连接真实受控者","palette":["161b23","384953","7d9797","d1d7bf","fcf4d7","bb7c88","79b8b2"],"story":"船厂调解员持未开锋的量尺剑，以口令、横栏与墨白证词保护说话者。","cast_notes":"四根错高黑白证词柱从身后展开","contact_notes":"开口横栏与墨签罩住命中者，不形成实体墙","tail_notes":"证词褪成横短线，根缚不误画为眩晕","passive":false,"shape":"court","variant":15,"route_mode":1},
	"OATH_NOTCH":{"hero":"OATH_REAVER","faction":"HUMAN","name":"断页留痕","material":"COPPER_PAPER","motif":"notched-verdict-edge","form":"single-notched-diagonal-cut","gesture":"断页剑斜提，再向单点落锋","connection":"铜边切痕与实际单体伤处相连","palette":["181820","5d3540","a75c5b","dfa889","fff0ce","6aa9b9","d5cb9a"],"story":"无主渡船的记录者把铜边磨成单刃长剑，只为活着的证人留下落款。","cast_notes":"残页先被拉长成剑的侧缘","contact_notes":"单点斜切以粗黑负影和铜亮边夹出护甲缺口","tail_notes":"纸屑向反方向撤离，破甲线不变大范围","passive":false,"shape":"notch_cut","variant":16,"route_mode":4},
	"OATH_EDGE_PLEDGE":{"hero":"OATH_REAVER","faction":"HUMAN","name":"见证之锋","material":"SIGNED_PAGES","motif":"three-witness-seals","form":"three-unbalanced-edge-tabs","gesture":"手指沿剑脊签下三片凭据","connection":"三个独立纸签表示有限强化，不额外造攻击","palette":["181820","5d3540","a75c5b","dfa889","fff0ce","6aa9b9","d5cb9a"],"story":"无主渡船的记录者把铜边磨成单刃长剑，只为活着的证人留下落款。","cast_notes":"三片大小不同见证页贴住剑的外缘","contact_notes":"强化挂在单刃与肩后，保留手臂留白","tail_notes":"实际次数耗尽由消费者关闭，不永久悬浮","passive":false,"shape":"edge_tabs","variant":17,"route_mode":1},
	"OATH_LAST_WITNESS":{"hero":"OATH_REAVER","faction":"HUMAN","name":"最后见证","material":"WITNESS_PAPER","motif":"unrolled-testimony-panels","form":"fan-of-suspended-witnesses","gesture":"剑横于身前，证词页抬高展开","connection":"扇形证词横栏由内到外锁住真实受控者","palette":["181820","5d3540","a75c5b","dfa889","fff0ce","6aa9b9","d5cb9a"],"story":"无主渡船的记录者把铜边磨成单刃长剑，只为活着的证人留下落款。","cast_notes":"七片倾角各异的大证词从背后打开","contact_notes":"封口纸钉与粗黑折影强调纯眩晕，没有剑气伤害","tail_notes":"纸页逐角折回，保留逃路而非实体壁垒","passive":false,"shape":"witness","variant":18,"route_mode":1},
	"BRIDGE_CROSSBEAM":{"hero":"BRIDGE_VANGUARD","faction":"HUMAN","name":"横梁开道","material":"TIMBER_IRON","motif":"launched-crossbeam-groove","form":"long-thick-crossbeam-furrow","gesture":"横梁肩架下沉、钉锤向前推送","connection":"短宽承力梁沿真实线形冲击","palette":["181d1c","4b4937","8d7149","c2a371","f4e4b7","5f9e9a","b7d7c2"],"story":"离开收费渡口的拆桥工，用旧桥桩、短柄钉锤和横梁肩架托住免费通路。","cast_notes":"两端不同的横梁从肩侧抬起","contact_notes":"长木铁梁的虚影压过实际命中线，细钉星闪","tail_notes":"斜木屑分两边，慢速碎片强调减速非眩晕","passive":false,"shape":"crossbeam","variant":19,"route_mode":4},
	"BRIDGE_LOCK_BRACE":{"hero":"BRIDGE_VANGUARD","faction":"HUMAN","name":"合榫护架","material":"JOINERY_COPPER","motif":"three-closing-mortises","form":"three-open-mortise-frames","gesture":"双臂外推、三把榫楔合入","connection":"短榫纹连接近处真实受益者","palette":["181d1c","4b4937","8d7149","c2a371","f4e4b7","5f9e9a","b7d7c2"],"story":"离开收费渡口的拆桥工，用旧桥桩、短柄钉锤和横梁肩架托住免费通路。","cast_notes":"三副开口榫架错拍合拢，不封死英雄","contact_notes":"受益者左右各一小榫角，表达护甲与协作","tail_notes":"有限增益结束后楔子撤出，不持续新建建筑","passive":false,"shape":"mortise","variant":20,"route_mode":2},
	"BRIDGE_LOAD_BEARER":{"hero":"BRIDGE_VANGUARD","faction":"HUMAN","name":"众任托梁","material":"COUNTERWEIGHT_TIMBER","motif":"raised-shoulder-gantry","form":"open-counterweight-stance","gesture":"抬肩顶梁、钉锤稳住下沿","connection":"自身综合强化沿承力折线流动","palette":["181d1c","4b4937","8d7149","c2a371","f4e4b7","5f9e9a","b7d7c2"],"story":"离开收费渡口的拆桥工，用旧桥桩、短柄钉锤和横梁肩架托住免费通路。","cast_notes":"不对称横梁巨架抬升，底部保留通路","contact_notes":"自身两侧承重棱线明亮，无群疗或免控罩","tail_notes":"梁上微尘持续落下，真实增益到期后卸荷","passive":false,"shape":"load","variant":21,"route_mode":4},
	"SUNGLASS_FOLDED_RAY":{"hero":"SUNGLASS_SCRIBE","faction":"HUMAN","name":"折日裁光","material":"SUN_MIRROR","motif":"folded-sun-needle","form":"two-fold-single-sun-needle","gesture":"三片背镜按不同轴角对焦","connection":"单束折叠日光指向一个真实目标","palette":["1b202b","425c76","7898ab","bfd6d4","fff5c7","edae64","d77f9b"],"story":"盐堤档案馆的审计者把日镜带出议事厅，折日与书签只揭露证据、不审讯灵魂。","cast_notes":"短宽镜页折成一枚长针，暖金与冷青并存","contact_notes":"单体针光从折点贯入，侧面光屑细碎","tail_notes":"镜针拆回两条暗书签，不扩散群伤","passive":false,"shape":"sun_needle","variant":22,"route_mode":4},
	"SUNGLASS_LIGHT_SHEAR":{"hero":"SUNGLASS_SCRIBE","faction":"HUMAN","name":"剪光长签","material":"GLASS_BOOKMARK","motif":"parallel-bookmark-shear","form":"offset-parallel-light-blades","gesture":"书签杖向前一剪，背镜错开","connection":"长签双刃沿真实穿线方向","palette":["1b202b","425c76","7898ab","bfd6d4","fff5c7","edae64","d77f9b"],"story":"盐堤档案馆的审计者把日镜带出议事厅，折日与书签只揭露证据、不审讯灵魂。","cast_notes":"两根长度不等的发光长签压成平行缝","contact_notes":"细长剪光以明暗双轨贯线，不画连续激光伤害","tail_notes":"书签逐段折断，残光沿原轴退去","passive":false,"shape":"sun_shear","variant":23,"route_mode":4},
	"SUNGLASS_FALLING_INDEX":{"hero":"SUNGLASS_SCRIBE","faction":"HUMAN","name":"落镜索引","material":"GLASS_ARCHIVE","motif":"numberless-mirror-cascade","form":"hanging-archive-mirror-fall","gesture":"抬杖揭起镜册，背架逐片翻页","connection":"落镜从英雄蓄势联到实际命中区域","palette":["1b202b","425c76","7898ab","bfd6d4","fff5c7","edae64","d77f9b"],"story":"盐堤档案馆的审计者把日镜带出议事厅，折日与书签只揭露证据、不审讯灵魂。","cast_notes":"五片大型不规则日镜向高处错位悬停","contact_notes":"镜册向实际目标区倾落；金光先亮、青影后碎","tail_notes":"大小镜片各自旋折消散，不持续制造地面法阵","passive":false,"shape":"mirror_fall","variant":24,"route_mode":6},
	"ASH_SHOCK":{"hero":"ASH_MARSHAL","faction":"UNDEAD","name":"余烬回生","material":"BONE_CABINET","motif":"casefile-return-suture","form":"returning-ivory-nameplates","gesture":"胸柜微开，判杖把名牌挑回骨缝","connection":"灰金铭牌由外回流自己","palette":["17191d","3a3b43","79746e","c7b99b","fff0c6","9bbca8","d78b68"],"story":"未结案守门人背负案卷柜与错判铭牌，骨钩必须守住仍可重审的门。","cast_notes":"柜门两边先开细缝，低骨火抬起","contact_notes":"碎骨名牌沿肋甲缝回收，不对敌造成震波","tail_notes":"冷骨点逐次熄灭，净化不误称免疫","passive":false,"shape":"bone_repair","variant":25,"route_mode":5},
	"ASH_WARD":{"hero":"ASH_MARSHAL","faction":"UNDEAD","name":"缝骨护甲","material":"BONE_WIRE","motif":"stitched-rib-ledger","form":"asymmetric-rib-seam","gesture":"柜铠不动，骨钩牵住侧缝","connection":"被动骨线只围局部甲缝","palette":["17191d","3a3b43","79746e","c7b99b","fff0c6","9bbca8","d78b68"],"story":"未结案守门人背负案卷柜与错判铭牌，骨钩必须守住仍可重审的门。","cast_notes":"左右肋片错开半格，细线勾合","contact_notes":"防护纹小幅反光，不制造额外护盾条","tail_notes":"常驻低亮保留骨白与灰金材料，不无限发光","passive":true,"shape":"rib","variant":26,"route_mode":2},
	"ASH_MEND":{"hero":"ASH_MARSHAL","faction":"UNDEAD","name":"灰誓镇魂","material":"GHOST_FILES","motif":"unread-docket-catches","form":"fan-of-hanging-docket-hooks","gesture":"开柜抬判杖、文件钩向前散列","connection":"扇形名牌钩锁住实际根缚者","palette":["17191d","3a3b43","79746e","c7b99b","fff0c6","9bbca8","d78b68"],"story":"未结案守门人背负案卷柜与错判铭牌，骨钩必须守住仍可重审的门。","cast_notes":"重案柜的九张残签在空中展开","contact_notes":"缺角骨钩与灰金索线落于实际受控者，非全屏吸魂","tail_notes":"细灰屑回柜，根缚与实际吸取各由真状态决定","passive":false,"shape":"docket","variant":27,"route_mode":2},
	"MOURN_BIND":{"hero":"MOURN_ORACLE","faction":"UNDEAD","name":"灰灯缚","material":"LANTERN_SHADOW","motif":"shuttered-lantern-jaws","form":"three-shadow-shutter-pylons","gesture":"偏侧灯眼闭合再张开","connection":"灯罩负影向实际小群根缚者收口","palette":["161a24","394558","6d708d","a6bcae","e7f0d4","d18b95","dfa975"],"story":"修葬灯的借眼者收集彼此矛盾的记忆，灯罩与无面铜镜使影子先于身体移动。","cast_notes":"三片遮光罩抬起，亮芯只从裂口透出","contact_notes":"阴影灯叶卡住脚侧，控制并不画成伤害炸裂","tail_notes":"灯罩反向卷回，地面不生成永久禁区","passive":false,"shape":"lantern_bind","variant":28,"route_mode":2},
	"MOURN_FLARE":{"hero":"MOURN_ORACLE","faction":"UNDEAD","name":"哀火","material":"MEMORY_FLAME","motif":"borrowed-eye-chain","form":"three-staggered-lantern-eyes","gesture":"向侧面借眼，灯柄斜抬","connection":"非规则灯眼沿真实链路依次回应","palette":["161a24","394558","6d708d","a6bcae","e7f0d4","d18b95","dfa975"],"story":"修葬灯的借眼者收集彼此矛盾的记忆，灯罩与无面铜镜使影子先于身体移动。","cast_notes":"两小一大的遮光灯眼错相打开","contact_notes":"链上真实目标各见一道横瞳与薄焰，非全部同时群爆","tail_notes":"记忆光带回收为窄线，吸取只在真实有效时显示","passive":false,"shape":"eye_chain","variant":29,"route_mode":2},
	"MOURN_OATH":{"hero":"MOURN_ORACLE","faction":"UNDEAD","name":"噬魂归烬","material":"GHOST_MIRROR","motif":"hollow-soul-convergence","form":"single-hollow-mirror-siphon","gesture":"无面铜镜朝外，灯眼瞬暗后内收","connection":"单体影丝向施法者回卷","palette":["161a24","394558","6d708d","a6bcae","e7f0d4","d18b95","dfa975"],"story":"修葬灯的借眼者收集彼此矛盾的记忆，灯罩与无面铜镜使影子先于身体移动。","cast_notes":"大铜镜空洞从背后抬起，灯芯形成偏心亮点","contact_notes":"单体黑铜裂缝与回流影丝，不凭画面复活或抓取","tail_notes":"细碎记忆沿镜边归灯，余烬缓慢散开","passive":false,"shape":"siphon","variant":30,"route_mode":5},
	"CINDER_SHOT":{"hero":"CINDER_STALKER","faction":"UNDEAD","name":"骨弦击","material":"BONE_ARROW","motif":"debt-nail-piercer","form":"long-open-rib-arrow","gesture":"低弓深拉、骨箭匣前倾","connection":"空洞箭尾严格指向单个实际目标","palette":["1c1920","4d3540","8e5e62","cfad92","fff0cf","db744f","a1bfbb"],"story":"运薪者射断债约钉，以回收骨箭、断税带与空洞箭痕追猎贩卖姓名的人。","cast_notes":"三节骨箭在弦上接榫，断税带绷紧","contact_notes":"细长骨刺贯入单体，箭后留空心负影","tail_notes":"骨节与税带逆向分离，不伪造多次射击","passive":false,"shape":"bone_arrow","variant":31,"route_mode":4},
	"CINDER_FERVOR":{"hero":"CINDER_STALKER","faction":"UNDEAD","name":"燃弦","material":"CINDER_STRING","motif":"heated-bone-bow","form":"bone-bow-flame-fingers","gesture":"拉弦手周围火纹沿指节游走","connection":"强化留在骨弓与弦，不群体着火","palette":["1c1920","4d3540","8e5e62","cfad92","fff0cf","db744f","a1bfbb"],"story":"运薪者射断债约钉，以回收骨箭、断税带与空洞箭痕追猎贩卖姓名的人。","cast_notes":"骨弓两翼燃起不等长火指，冷骨与暖煤双层","contact_notes":"自强化只挂武器，吸血不画成被动群疗","tail_notes":"有限窗口保持断税带微燃，到期立即熄芯","passive":false,"shape":"bone_bow","variant":32,"route_mode":1},
	"CINDER_MEND":{"hero":"CINDER_STALKER","faction":"UNDEAD","name":"灰烬猎杀","material":"ASH_BONE","motif":"hollow-prey-verdict","form":"single-long-bone-harpoon","gesture":"弓身压低，长骨箭与脊背齐平","connection":"长箭明芯与空洞尾痕集中一个目标","palette":["1c1920","4d3540","8e5e62","cfad92","fff0cf","db744f","a1bfbb"],"story":"运薪者射断债约钉，以回收骨箭、断税带与空洞箭痕追猎贩卖姓名的人。","cast_notes":"粗长骨箭从三节扩为带反钩的单支","contact_notes":"真实单体位置出现狭长穿刺裂口，非群伤爆炸","tail_notes":"灰尘沿箭轴漏下，残血处决不增画虚假额外箭","passive":false,"shape":"hunt","variant":33,"route_mode":4},
	"ASH_LANTERN":{"hero":"ASH_CHANTER","faction":"UNDEAD","name":"哀灯光环","material":"WARM_STITCH","motif":"theatre-lamp-trim","form":"warm-folded-stage-lanterns","gesture":"灯柄轻提，戏箱的布边依次亮起","connection":"受益者用微小缝名线而非攻击环","palette":["1a1b22","47434d","92767c","c8b9a0","fff2d0","a9d29f","dc9572"],"story":"默剧题字员推着旧戏箱，以字板、卷轴灯与缝名线让亡者重新选择角色。","cast_notes":"小字板与灯边线像幕边翻折","contact_notes":"被动回复纹从下向上轻抬，不出现受击","tail_notes":"低亮灯芯保留呼吸，不暗示额外复活","passive":true,"shape":"lantern_trim","variant":34,"route_mode":2},
	"ASH_STITCH":{"hero":"ASH_CHANTER","faction":"UNDEAD","name":"灰线缝合","material":"WARM_THREAD","motif":"name-stitch-needle","form":"two-curved-stitching-needles","gesture":"长手套上下交错，线轴从戏箱弹出","connection":"暖烬针线接向实际恢复对象","palette":["1a1b22","47434d","92767c","c8b9a0","fff2d0","a9d29f","dc9572"],"story":"默剧题字员推着旧戏箱，以字板、卷轴灯与缝名线让亡者重新选择角色。","cast_notes":"两支弯针绕开英雄体心，同时拉起长灰线","contact_notes":"恢复对象呈三道小针脚与绿色灯点，不白闪爆炸","tail_notes":"线轴回卷，净化灼毒只用熄灭的暗屑","passive":false,"shape":"thread_heal","variant":35,"route_mode":5},
	"ASH_REQUIEM":{"hero":"ASH_CHANTER","faction":"UNDEAD","name":"归名安魂","material":"THEATRE_PAPER","motif":"rewritten-two-lines","form":"two-open-script-wings","gesture":"举起两页可以重写的台词","connection":"有限技能增幅由两页脚本和受益者灯芯连接","palette":["1a1b22","47434d","92767c","c8b9a0","fff2d0","a9d29f","dc9572"],"story":"默剧题字员推着旧戏箱，以字板、卷轴灯与缝名线让亡者重新选择角色。","cast_notes":"戏箱两翼展开两张异形长台词，暖烬从内翻页","contact_notes":"友军武器／法器附近出现页签，绝不群疗绿爆","tail_notes":"已付费有限次数结束才关闭，没有永久圣域","passive":false,"shape":"script_wings","variant":36,"route_mode":3},
	"GRAVE_CADENCE":{"hero":"GRAVE_BELL","faction":"UNDEAD","name":"暮钟光环","material":"BLACK_BRONZE","motif":"open-bell-measure","form":"split-bell-metronome","gesture":"裂钟左右轻摆，校音绳按不同拍子张紧","connection":"脚边小节拍与实际受益者对应","palette":["171821","343546","716776","b5a08a","ede1b7","b7a3cd","d5b66c"],"story":"失聪潮钟校准者以胸口裂钟感受震动，用黑铜负影与迟来的金尘保留拒绝的一拍。","cast_notes":"不闭合的铜钟纹左右错一拍","contact_notes":"被动仅小幅金尘，绝不反复敲击命中","tail_notes":"保留裂口负影与稀疏拍点，非大光环罩","passive":true,"shape":"bell_meter","variant":37,"route_mode":5},
	"GRAVE_CHAIN":{"hero":"GRAVE_BELL","faction":"UNDEAD","name":"锁魂链","material":"BRONZE_LINKS","motif":"unanswered-syllable-chain","form":"offset-square-link-chant","gesture":"手指拨动校音绳，先影后链","connection":"方圆混合链节沿真实连锁顺序落下","palette":["171821","343546","716776","b5a08a","ede1b7","b7a3cd","d5b66c"],"story":"失聪潮钟校准者以胸口裂钟感受震动，用黑铜负影与迟来的金尘保留拒绝的一拍。","cast_notes":"不规则金属链从侧面抬起，黑铜影先行","contact_notes":"真实根缚目标处钩节收紧，保留低伤与吸取语义","tail_notes":"链节一端一端解开，不画无中断无限锁链","passive":false,"shape":"chain","variant":38,"route_mode":2},
	"GRAVE_TOLL":{"hero":"GRAVE_BELL","faction":"UNDEAD","name":"寂静晚钟","material":"NEGATIVE_BRONZE","motif":"silent-bell-shadow","form":"huge-open-negative-bell","gesture":"托起裂钟，周围金尘短暂停顿","connection":"黑铜钟影向实际被控区域压下","palette":["171821","343546","716776","b5a08a","ede1b7","b7a3cd","d5b66c"],"story":"失聪潮钟校准者以胸口裂钟感受震动，用黑铜负影与迟来的金尘保留拒绝的一拍。","cast_notes":"巨大裂钟负影抬至肩上，悬绳与钟舌错位","contact_notes":"开口钟罩与竖向停顿线落于实际受控者，零伤害","tail_notes":"金尘比暗影晚一拍离开，纯控不假造冲击坑","passive":false,"shape":"bell","variant":39,"route_mode":7},
	"RELIC_NAME_HOOK":{"hero":"RELIC_REAVER","faction":"UNDEAD","name":"留名倒钩","material":"SILK_BONE","motif":"unclosed-name-hooks","form":"two-reversed-costume-hooks","gesture":"双钩一收一放，侧悬名牌先摆","connection":"两目标续名通过不等长绸线真实链路","palette":["181720","493b55","8b6a8d","bea8b3","f3e9d5","92c4c1","d69679"],"story":"拒演旧角色的戏服修补者，以弯钩双刃、侧悬名牌与未合幕布替亡者终止纠缠。","cast_notes":"弯钩与半纱倒影向前分开","contact_notes":"反向钩牙在脚侧夹定，伤控不误画成拉人","tail_notes":"绸线向外滑脱，不能造成画面暗示的位移","passive":false,"shape":"hook","variant":40,"route_mode":2},
	"RELIC_COLD_EDGE":{"hero":"RELIC_REAVER","faction":"UNDEAD","name":"寒灯双刃","material":"COLD_SILK","motif":"memory-fed-twin-edges","form":"unequal-cold-double-blades","gesture":"双刃分别抬至肩侧，纱罩冷灯聚明","connection":"刀刃的冷灯脊线维持自身强化与回蓝","palette":["181720","493b55","8b6a8d","bea8b3","f3e9d5","92c4c1","d69679"],"story":"拒演旧角色的戏服修补者，以弯钩双刃、侧悬名牌与未合幕布替亡者终止纠缠。","cast_notes":"两把长度不同的弯月刃虚影从两侧探出","contact_notes":"强化只在英雄身侧，不生成分身攻击","tail_notes":"冷丝沿刀脊回流，真实时间结束才褪光","passive":false,"shape":"cold_blades","variant":41,"route_mode":3},
	"RELIC_UNFINISHED_DUEL":{"hero":"RELIC_REAVER","faction":"UNDEAD","name":"未竟独幕","material":"THEATRE_SHADOW","motif":"curtain-of-one-name","form":"single-asymmetric-curtain-close","gesture":"双手合拢旧幕而非大幅群斩","connection":"一人幕口与吸取回流保持单体关系","palette":["181720","493b55","8b6a8d","bea8b3","f3e9d5","92c4c1","d69679"],"story":"拒演旧角色的戏服修补者，以弯钩双刃、侧悬名牌与未合幕布替亡者终止纠缠。","cast_notes":"半边垂幕从高处展开，另一边仍留出口","contact_notes":"单体位置出现不对称合幕切口与窄冷芯","tail_notes":"幕边线头回卷，治疗由真实伤害吸取决定","passive":false,"shape":"curtain","variant":42,"route_mode":3},
	"OSSUARY_FERRY_STRIKE":{"hero":"OSSUARY_KNIGHT","faction":"UNDEAD","name":"渡辕横扫","material":"BONE_SAIL","motif":"ferry-oar-return","form":"wide-open-rib-oar-sweep","gesture":"长辕钩镰横举，船形肋甲后倾","connection":"扇形骨辕轨与真实伤害回流对应","palette":["191c23","3d4a53","778b8d","bdc4b6","fff0d1","92bdc9","d7a68a"],"story":"送行雪橇的驾者拆下长辕为钩镰，船形肋甲与破帆替遗物寻找有人记得的岸。","cast_notes":"巨型骨辕以不等厚两端拉出低弧","contact_notes":"扇向白骨划痕与破帆碎片，吸取不造额外击杀","tail_notes":"亮骨回收为短竖线，扇边阴影慢于刀口","passive":false,"shape":"ferry","variant":43,"route_mode":3},
	"OSSUARY_CLOSED_PALL":{"hero":"OSSUARY_KNIGHT","faction":"UNDEAD","name":"合帆骨衣","material":"OLD_SAIL_SUTURE","motif":"sail-closes-ribs","form":"folded-pall-repair","gesture":"两层破帆向胸侧合拢，骨辕收回","connection":"自疗沿帆缝上行，不连敌人","palette":["191c23","3d4a53","778b8d","bdc4b6","fff0d1","92bdc9","d7a68a"],"story":"送行雪橇的驾者拆下长辕为钩镰，船形肋甲与破帆替遗物寻找有人记得的岸。","cast_notes":"两片一长一短破帆折向自身左右","contact_notes":"帆缝亮线与小骨点修复，不提供虚假护甲罩","tail_notes":"暗灼毒碎点被排出，帆角重新露白","passive":false,"shape":"pall","variant":44,"route_mode":5},
	"OSSUARY_PROCESSION":{"hero":"OSSUARY_KNIGHT","faction":"UNDEAD","name":"归岸行列","material":"ASH_SAIL","motif":"returning-ship-rigging","form":"open-lifeline-sail-stance","gesture":"背帆张起、钩镰落在低位待发","connection":"自身帆索强化，与敌方真实吸取分别显示","palette":["191c23","3d4a53","778b8d","bdc4b6","fff0d1","92bdc9","d7a68a"],"story":"送行雪橇的驾者拆下长辕为钩镰，船形肋甲与破帆替遗物寻找有人记得的岸。","cast_notes":"三片破帆以高低三层立起，地面留船形暗影","contact_notes":"持续强化表现在帆骨与武器，不群体治疗","tail_notes":"真实增益结束后帆索依次松开，不出现召唤船","passive":false,"shape":"sails","variant":45,"route_mode":3},
	"CINDER_LINGERING_CLAUSE":{"hero":"CINDER_TESTATOR","faction":"UNDEAD","name":"余火附款","material":"ASH_CHARTER","motif":"accepted-cinder-q","form":"accepted-folded-ember-clause","gesture":"保留V4抬书印／残页身体动作","connection":"保留V4真正来源到落点链","palette":["1b171e","53353d","986057","d58d58","fff0c6","b6c5b6","efbd69"],"story":"遗嘱官保管可被本人撤回的最后一句，以残页披帘、灰匣长柄印让结束成为权利。","cast_notes":"直接委托已认可V4 cinder_q CAST","contact_notes":"直接委托已认可V4 cinder_q CONTACT","tail_notes":"不新画重复尾效，真实有限火继续由V4管理","passive":false,"shape":"v4","variant":46,"preserve_v4":true,"route_mode":6},
	"CINDER_SCATTERED_PAGES":{"hero":"CINDER_TESTATOR","faction":"UNDEAD","name":"散页炭潮","material":"CHARRED_PAPER","motif":"accepted-cinder-w","form":"accepted-charred-page-fan","gesture":"保留V4伸臂与开书姿态","connection":"保留V4扇向散页和连贯火流","palette":["1b171e","53353d","986057","d58d58","fff0c6","b6c5b6","efbd69"],"story":"遗嘱官保管可被本人撤回的最后一句，以残页披帘、灰匣长柄印让结束成为权利。","cast_notes":"直接委托已认可V4 cinder_w CAST","contact_notes":"直接委托已认可V4 cinder_w CONTACT","tail_notes":"不覆盖V4已验的隐源方向保护","passive":false,"shape":"v4","variant":47,"preserve_v4":true,"route_mode":7},
	"CINDER_FINAL_CODICIL":{"hero":"CINDER_TESTATOR","faction":"UNDEAD","name":"焚尽末章","material":"INK_FIRE","motif":"accepted-cinder-r","form":"accepted-heavy-codicil-stamp","gesture":"保留V4竖章蓄力与8姿态身体","connection":"保留真实命中再触发的重印与余火","palette":["1b171e","53353d","986057","d58d58","fff0c6","b6c5b6","efbd69"],"story":"遗嘱官保管可被本人撤回的最后一句，以残页披帘、灰匣长柄印让结束成为权利。","cast_notes":"直接委托已认可V4 cinder_r CAST","contact_notes":"直接委托已认可V4 cinder_r CONTACT","tail_notes":"直接委托V4 44tick有限TAIL，不延长规则燃烧","passive":false,"shape":"v4","variant":48,"preserve_v4":true,"route_mode":0},
	"INNATE_COMMANDER":{"hero":"COMMANDER","faction":"HUMAN","name":"同袍誓约","material":"LOW_KEY_IDENTITY","motif":"porcelain-sealed-hospital-tab","form":"porcelain-sealed-hospital-tab","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["17151d","702d42","b75c59","e9b986","f9ecd0","6db8b3","f7db90"],"story":"渡口账房把撕开的航图用于急救，以铜印和青瓷补线重新承诺归途。","cast_notes":"腰侧青瓷缝与铜扣慢拍呼吸，不按站立／移动制造新条件。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"medallion","variant":49,"route_mode":1},
	"INNATE_BULWARK":{"hero":"BULWARK","faction":"HUMAN","name":"垒盾阵心","material":"LOW_KEY_IDENTITY","motif":"evacuation-gate-notch","form":"evacuation-gate-notch","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["141d24","334452","617b83","b8c5ba","f4efcc","d59d56","77c9c5"],"story":"闸门盾、铁钩与承重木楔属于断桥托梁人，防线永远留有撤离出口。","cast_notes":"单边木楔与留出口的短闸纹，区别实际防守范围环。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"brace_mark","variant":50,"route_mode":2},
	"INNATE_ARCANIST":{"hero":"ARCANIST","faction":"HUMAN","name":"列阵共鸣","material":"LOW_KEY_IDENTITY","motif":"broken-angle-error-points","form":"broken-angle-error-points","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["171827","383b70","6766a5","a5c8df","f6eed9","d383ba","7be5d2"],"story":"河口磨镜匠砸碎预言镜，以误差、测角架和破边棱镜反抗命定轨道。","cast_notes":"缺口测角架上三枚不同高度亮点，表示个人身份而非新增伤害事件。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"prism_mark","variant":51,"route_mode":3},
	"INNATE_RANGER":{"hero":"RANGER","faction":"HUMAN","name":"协猎","material":"LOW_KEY_IDENTITY","motif":"two-tied-kite-knots","form":"two-tied-kite-knots","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["19202a","375666","6b9fba","b1d9d5","f8edd0","e4a487","f5d668"],"story":"封航港口的药单信使，用纸鸢骨架作弓，让回信沿雨丝与湿绳穿越逆风。","cast_notes":"弓侧双绳结交错，协猎触发仍由正式普攻反馈拥有。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"kite_mark","variant":52,"route_mode":4},
	"INNATE_DUELIST":{"hero":"DUELIST","faction":"HUMAN","name":"止戈步调","material":"LOW_KEY_IDENTITY","motif":"unclosed-measure-tally","form":"unclosed-measure-tally","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["161b23","384953","7d9797","d1d7bf","fcf4d7","bb7c88","79b8b2"],"story":"船厂调解员持未开锋的量尺剑，以口令、横栏与墨白证词保护说话者。","cast_notes":"一长二短尺刻绕体侧轻摆，不强行加控制光环。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"measure_mark","variant":53,"route_mode":5},
	"INNATE_OATH_REAVER":{"hero":"OATH_REAVER","faction":"HUMAN","name":"凭据截击","material":"LOW_KEY_IDENTITY","motif":"unsigned-recent-witness-tab","form":"unsigned-recent-witness-tab","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["181820","5d3540","a75c5b","dfa889","fff0ce","6aa9b9","d5cb9a"],"story":"无主渡船的记录者把铜边磨成单刃长剑，只为活着的证人留下落款。","cast_notes":"单片没有封口的证词页在剑脊附近呼吸，不伪装最近技能目标。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"page_mark","variant":54,"route_mode":6},
	"INNATE_BRIDGE_VANGUARD":{"hero":"BRIDGE_VANGUARD","faction":"HUMAN","name":"并肩承重","material":"LOW_KEY_IDENTITY","motif":"two-neighbor-shoulder-pegs","form":"two-neighbor-shoulder-pegs","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["181d1c","4b4937","8d7149","c2a371","f4e4b7","5f9e9a","b7d7c2"],"story":"离开收费渡口的拆桥工，用旧桥桩、短柄钉锤和横梁肩架托住免费通路。","cast_notes":"两枚相互错开的榫钉贴肩，实际两友军门槛仍由规则检测。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"joinery_mark","variant":55,"route_mode":7},
	"INNATE_SUNGLASS_SCRIBE":{"hero":"SUNGLASS_SCRIBE","faction":"HUMAN","name":"远镜校准","material":"LOW_KEY_IDENTITY","motif":"three-distant-mirror-ticks","form":"three-distant-mirror-ticks","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["1b202b","425c76","7898ab","bfd6d4","fff5c7","edae64","d77f9b"],"story":"盐堤档案馆的审计者把日镜带出议事厅，折日与书签只揭露证据、不审讯灵魂。","cast_notes":"小三镜以不同倾角挂背侧，不画成永远享有远距加伤。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"mirror_mark","variant":56,"route_mode":0},
	"INNATE_ASH_MARSHAL":{"hero":"ASH_MARSHAL","faction":"UNDEAD","name":"归骨续命","material":"LOW_KEY_IDENTITY","motif":"unread-cabinet-tag","form":"unread-cabinet-tag","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["17191d","3a3b43","79746e","c7b99b","fff0c6","9bbca8","d78b68"],"story":"未结案守门人背负案卷柜与错判铭牌，骨钩必须守住仍可重审的门。","cast_notes":"一块未读名牌在胸柜侧缓慢闪过，不常亮真实死亡回复。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"bone_mark","variant":57,"route_mode":1},
	"INNATE_MOURN_ORACLE":{"hero":"MOURN_ORACLE","faction":"UNDEAD","name":"迟燃烬语","material":"LOW_KEY_IDENTITY","motif":"shutter-eye-ember-notch","form":"shutter-eye-ember-notch","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["161a24","394558","6d708d","a6bcae","e7f0d4","d18b95","dfa975"],"story":"修葬灯的借眼者收集彼此矛盾的记忆，灯罩与无面铜镜使影子先于身体移动。","cast_notes":"偏心灯眼边缘一点暗烬，只有正式命中状态才有后续灼烧。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"eye_mark","variant":58,"route_mode":2},
	"INNATE_CINDER_STALKER":{"hero":"CINDER_STALKER","faction":"UNDEAD","name":"残烬追猎","material":"LOW_KEY_IDENTITY","motif":"broken-debt-arrow-nock","form":"broken-debt-arrow-nock","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["1c1920","4d3540","8e5e62","cfad92","fff0cf","db744f","a1bfbb"],"story":"运薪者射断债约钉，以回收骨箭、断税带与空洞箭痕追猎贩卖姓名的人。","cast_notes":"断税带与空心箭尾作低调标识，不给满血目标虚构残血追猎。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"arrow_mark","variant":59,"route_mode":3},
	"INNATE_ASH_CHANTER":{"hero":"ASH_CHANTER","faction":"UNDEAD","name":"余烬灯芯","material":"LOW_KEY_IDENTITY","motif":"unwritten-theatre-lamp","form":"unwritten-theatre-lamp","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["1a1b22","47434d","92767c","c8b9a0","fff2d0","a9d29f","dc9572"],"story":"默剧题字员推着旧戏箱，以字板、卷轴灯与缝名线让亡者重新选择角色。","cast_notes":"戏箱边的一圈开口缝线与小灯芯，不凭空增加余烬层数。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"thread_mark","variant":60,"route_mode":4},
	"INNATE_GRAVE_BELL":{"hero":"GRAVE_BELL","faction":"UNDEAD","name":"暮钟哀音","material":"LOW_KEY_IDENTITY","motif":"delayed-gold-bell-beat","form":"delayed-gold-bell-beat","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["171821","343546","716776","b5a08a","ede1b7","b7a3cd","d5b66c"],"story":"失聪潮钟校准者以胸口裂钟感受震动，用黑铜负影与迟来的金尘保留拒绝的一拍。","cast_notes":"裂钟负影下两枚迟来的金点，抑疗数值与受益范围另有真实来源。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"bell_mark","variant":61,"route_mode":5},
	"INNATE_RELIC_REAVER":{"hero":"RELIC_REAVER","faction":"UNDEAD","name":"未合名册","material":"LOW_KEY_IDENTITY","motif":"unclosed-silk-name-knot","form":"unclosed-silk-name-knot","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["181720","493b55","8b6a8d","bea8b3","f3e9d5","92c4c1","d69679"],"story":"拒演旧角色的戏服修补者，以弯钩双刃、侧悬名牌与未合幕布替亡者终止纠缠。","cast_notes":"弯钩旁半结名签，不把低血加伤条件伪装成持续敌人标记。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"hook_mark","variant":62,"route_mode":6},
	"INNATE_OSSUARY_KNIGHT":{"hero":"OSSUARY_KNIGHT","faction":"UNDEAD","name":"归岸余席","material":"LOW_KEY_IDENTITY","motif":"empty-returning-sail-seat","form":"empty-returning-sail-seat","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["191c23","3d4a53","778b8d","bdc4b6","fff0d1","92bdc9","d7a68a"],"story":"送行雪橇的驾者拆下长辕为钩镰，船形肋甲与破帆替遗物寻找有人记得的岸。","cast_notes":"破帆边留一块空白骨框，不常亮或反复播死亡回复。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"sail_mark","variant":63,"route_mode":7},
	"INNATE_CINDER_TESTATOR":{"hero":"CINDER_TESTATOR","faction":"UNDEAD","name":"撤回之后留灯","material":"LOW_KEY_IDENTITY","motif":"accepted-cinder-natural-refund","form":"accepted-cinder-natural-refund","gesture":"个人法器或衣装局部低幅呼吸","connection":"仅身份呼吸，不取代真实触发／受益标记","palette":["1b171e","53353d","986057","d58d58","fff0c6","b6c5b6","efbd69"],"story":"遗嘱官保管可被本人撤回的最后一句，以残页披帘、灰匣长柄印让结束成为权利。","cast_notes":"保留V4真正自然结束返蓝RETURN，不用AURA伪装每时每刻正在返蓝。","contact_notes":"不在无真实触发时播放受击或治疗","tail_notes":"来源死亡／隐藏或未具备资格时由消费者不绘制","passive":true,"shape":"v4","variant":64,"preserve_v4":true,"route_mode":0}
}

static func paint(image:Image,skill_id:String,phase:String,frame:int)->void:
	if not PROFILES.has(skill_id) or phase not in PHASES or frame<0 or frame>=FRAMES:return
	var row:Dictionary=PROFILES[skill_id]
	if bool(row.get("preserve_v4",false)):
		var handler:String={"CINDER_LINGERING_CLAUSE":"cinder_q","CINDER_SCATTERED_PAGES":"cinder_w","CINDER_FINAL_CODICIL":"cinder_r","INNATE_CINDER_TESTATOR":"cinder_p"}[skill_id]
		var actual_phase:=phase
		if handler=="cinder_p":
			# The real P is a refund event, never an always-on "refund aura".
			if phase=="AURA":return
			actual_phase="RETURN"
		var old:Image=CinderV4.image(handler,actual_phase,frame)
		image.blit_rect(old,Rect2i(0,0,SIZE,SIZE),Vector2i.ZERO)
		_finish(image)
		return
	var t:=float(frame)/11.0
	var k:=int(row.variant)
	var shape:=str(row.shape)
	# "AURA" here is a small individual identity vignette, not range/benefit
	# authority. Root only dispatches persistent visuals for real live sources.
	if phase=="AURA" or bool(row.passive):
		_identity(image,row,t,frame,shape)
		_finish(image)
		return
	match shape:
		"banner":_banner(image,row,t,frame,phase)
		"suture","repair","bone_repair","thread_heal","pall":_mend(image,row,t,frame,phase,shape)
		"stamp":_stamp(image,row,t,frame,phase)
		"brace","mortise","load":_joinery(image,row,t,frame,phase,shape)
		"gate":_gate(image,row,t,frame,phase)
		"prism_fan":_prism_fan(image,row,t,frame,phase)
		"ice_jaw","ruler_clamp":_clamp(image,row,t,frame,phase,shape)
		"star_cage":_star_cage(image,row,t,frame,phase)
		"kite_arrow","bone_arrow","hunt":_arrow(image,row,t,frame,phase,shape)
		"arrow_rain":_rain(image,row,t,frame,phase)
		"bow_empower","bone_bow","cold_blades","edge_tabs":_weapon(image,row,t,frame,phase,shape)
		"court","witness","docket","script_wings":_panels(image,row,t,frame,phase,shape)
		"notch_cut","crossbeam","ferry":_sweep(image,row,t,frame,phase,shape)
		"sun_needle","sun_shear","mirror_fall":_sun(image,row,t,frame,phase,shape)
		"lantern_bind","eye_chain","siphon":_lantern(image,row,t,frame,phase,shape)
		"chain","hook":_chain(image,row,t,frame,phase,shape)
		"bell","bell_meter":_bell(image,row,t,frame,phase)
		"curtain","sails":_cloth(image,row,t,frame,phase,shape)
		_:_identity(image,row,t,frame,shape)
	# Every active identity has a few coherent material fragments, with
	# variation in cadence and placement rather than a universal particle ring.
	if phase!="TAIL":
		var origin:=Vector2(54+k%19,62+k%11)
		_grains(image,row,origin,frame,4+k%4,1.0)
	_finish(image)

static func _ink(row:Dictionary,alpha:float=1.0)->Color:return Pixels.color(row,0,alpha)
static func _c(row:Dictionary,index:int,alpha:float=1.0)->Color:return Pixels.color(row,index,alpha)
static func _opacity(phase:String,t:float)->float:
	return maxf(.08,1.0-t*.9) if phase=="TAIL" else minf(1.0,.45+t*1.2) if phase=="CAST" else maxf(.25,1.0-t*.65)
static func _stroke(out:Image,row:Dictionary,a:Vector2,b:Vector2,width:int=5,alpha:float=1.0,index:int=3)->void:
	Pixels.line(out,a+Vector2(2,3),b+Vector2(2,3),_ink(row,alpha*.35),width+3)
	Pixels.line(out,a,b,_ink(row,alpha),width+2)
	Pixels.line(out,a,b,_c(row,index,alpha),width)
	if width>=3:Pixels.line(out,a+Vector2(0,-1),b+Vector2(0,-1),_c(row,4,alpha),1)
static func _path(out:Image,row:Dictionary,points:Array,width:int=5,alpha:float=1.0,index:int=3)->void:
	for n:int in range(1,points.size()):_stroke(out,row,points[n-1],points[n],width,alpha,index)
static func _diamond(out:Image,row:Dictionary,p:Vector2,size:Vector2,alpha:float=1.0,index:int=3)->void:
	var a:Array=[p+Vector2(-size.x,0),p+Vector2(0,-size.y),p+Vector2(size.x,0),p+Vector2(0,size.y)]
	Pixels.poly(out,a,_ink(row,alpha))
	Pixels.poly(out,[p+Vector2(-size.x+3,0),p+Vector2(0,-size.y+3),p+Vector2(size.x-3,0),p+Vector2(0,size.y-3)],_c(row,index,alpha))
	Pixels.line(out,p+Vector2(0,-size.y+3),p+Vector2(size.x-3,0),_c(row,4,alpha),2)
static func _grains(out:Image,row:Dictionary,center:Vector2,frame:int,count:int,alpha:float)->void:
	var k:=int(row.variant)
	for n:int in range(count):
		var p:=center+Vector2(posmod(n*23+k*3+frame*(2+n%2),71)-35,posmod(n*17+k+frame*(1+n%3),47)-23)
		var size:=2+(n+k)%3
		Pixels.rect(out,roundi(p.x)-1,roundi(p.y)-1,size+2,size+2,_ink(row,alpha*.45))
		Pixels.rect(out,roundi(p.x),roundi(p.y),size,size,_c(row,3+(n%3),alpha))
static func _ribbon(out:Image,row:Dictionary,points:Array,width:int,t:float,alpha:float=1)->void:
	_path(out,row,points,width,alpha,2)
	for n:int in range(points.size()):
		var p:Vector2=points[n]
		Pixels.rect(out,roundi(p.x)-2,roundi(p.y)-2,4,4,_c(row,5,alpha))
	var index:=mini(points.size()-2,int(t*float(points.size()-1)))
	var p:Vector2=points[index].lerp(points[index+1],fmod(t*float(points.size()-1),1.0))
	_diamond(out,row,p,Vector2(5,7),alpha,4)
static func _panel(out:Image,row:Dictionary,p:Vector2,w:float,h:float,slant:float,alpha:float,index:int=3)->void:
	var points:Array=[p+Vector2(-w*.5,0),p+Vector2(w*.5,-slant),p+Vector2(w*.5-4,h*.45),p+Vector2(w*.5,h),p+Vector2(-w*.5+2,h-4)]
	Pixels.poly(out,points,_ink(row,alpha))
	Pixels.poly(out,[points[0]+Vector2(3,3),points[1]+Vector2(-3,4),points[3]+Vector2(-3,-4),points[4]+Vector2(2,-3)],_c(row,index,alpha))
	Pixels.line(out,points[0]+Vector2(4,3),points[1]+Vector2(-3,4),_c(row,4,alpha),2)
	for i:int in range(3):
		var y:=p.y+11+i*9
		Pixels.line(out,Vector2(p.x-w*.3,y),Vector2(p.x+w*(.22 if i%2==0 else .05),y-2),_c(row,1,alpha),2)

static func _banner(out:Image,row:Dictionary,t:float,f:int,phase:String)->void:
	var a:=_opacity(phase,t)
	_stroke(out,row,Vector2(54,140),Vector2(54,40),5,a,2)
	for n:int in range(3):
		var p:=Vector2(64+n*24,42+n*8+sin(t*TAU+n)*4)
		_panel(out,row,p,26-n*3,48+n*8,8,a,3 if n%2 else 5)
	_ribbon(out,row,[Vector2(54,139),Vector2(67,147),Vector2(128,144),Vector2(152,130)],3,t,a*.7)
	_grains(out,row,Vector2(120,70),f,5,a)
static func _mend(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	var spread:=43.0+sin(t*PI)*13
	if shape=="pall":
		_panel(out,row,Vector2(57,48-t*5),32,80,14,a,2)
		_panel(out,row,Vector2(135,60+t*3),26,67,-9,a,3)
	elif shape=="repair":
		for n:int in range(3):
			var x:=49+n*41
			Pixels.poly(out,[Vector2(x,139),Vector2(x+12,139),Vector2(x+8,111-n*9),Vector2(x+3,117-n*9)],_ink(row,a))
			_stroke(out,row,Vector2(x+5,136),Vector2(x+6,111-n*9),5,a,3)
	elif shape=="bone_repair":
		for n:int in range(6):
			var q:=Vector2(96+cos(n*1.2)*spread,103+sin(n*1.2)*28-t*13)
			_diamond(out,row,q,Vector2(7,12),a,3)
	else:
		for side:int in [-1,1]:
			_ribbon(out,row,[Vector2(96+side*spread,143),Vector2(96+side*(spread+14),106),Vector2(96+side*32,64),Vector2(96+side*13,51)],3+int(shape=="thread_heal"),t,a)
	for n:int in range(7):
		var x:=48+posmod(n*17+int(row.variant),95)
		var y:=146-posmod(f*5+n*19,86)
		Pixels.rect(out,x,y,3,7,_c(row,5,a*.65))
		if n%2==0:Pixels.rect(out,x-2,y+2,7,2,_c(row,4,a))
	# Recovery stitches, not a damage splash or gameplay shield.
	if shape=="suture":
		for n:int in range(4):
			_stroke(out,row,Vector2(46+n*30,141),Vector2(53+n*30,131),3,a,5)
static func _stamp(out:Image,row:Dictionary,t:float,f:int,phase:String)->void:
	var a:=_opacity(phase,t)
	var y:=41.0-t*17 if phase=="CAST" else 60.0+minf(1,t*3)*47 if phase=="CONTACT" else 109-t*5
	Pixels.rect(out,53,141,85,8,_ink(row,a*.45))
	_stroke(out,row,Vector2(96,y-17),Vector2(96,y+7),10,a,2)
	Pixels.poly(out,[Vector2(57,y),Vector2(132,y+4),Vector2(139,y+42),Vector2(51,y+36)],_ink(row,a))
	Pixels.poly(out,[Vector2(61,y+5),Vector2(127,y+9),Vector2(132,y+34),Vector2(59,y+29)],_c(row,2,a))
	_path(out,row,[Vector2(69,y+14),Vector2(112,y+14),Vector2(112,y+25),Vector2(84,y+25)],3,a,4)
	_grains(out,row,Vector2(95,135),f,9,a)
static func _joinery(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	if shape=="load":
		_path(out,row,[Vector2(35,135),Vector2(46,48),Vector2(144,39),Vector2(161,132)],9,a,2)
		_stroke(out,row,Vector2(43,71),Vector2(147,61),7,a,3)
		_diamond(out,row,Vector2(151,87+t*6),Vector2(10,19),a,5)
	else:
		var count:=3 if shape=="mortise" else 2
		for n:int in range(count):
			var x:=41+n*(49 if count==3 else 103)
			var y:=71+n%2*15
			_path(out,row,[Vector2(x+19,143),Vector2(x,y+20),Vector2(x+12,y),Vector2(x+28,y+7)],6,a,2+n%2)
			Pixels.rect(out,x+7,roundi(y+14+sin(t*TAU+n)*3),14,5,_c(row,5,a))
	_grains(out,row,Vector2(96,51),f,5,a*.7)
static func _gate(out:Image,row:Dictionary,t:float,f:int,phase:String)->void:
	var a:=_opacity(phase,t)
	var drop:=0.0 if phase=="CAST" else minf(1,t*3)*43
	var lift:=sin(t*PI)*12
	_stroke(out,row,Vector2(35,54-lift+drop),Vector2(157,54-lift+drop),9,a,2)
	for n:int in range(7):
		var x:=42+n*17
		var y:=61-lift+drop
		_stroke(out,row,Vector2(x,y),Vector2(x+3,y+35+(n%3)*7),6,a,3)
		Pixels.poly(out,[Vector2(x-4,y+32),Vector2(x+7,y+32),Vector2(x+3,y+49)],_c(row,4,a))
	for n:int in range(4):
		Pixels.rect(out,40+n*32,148+n%2*5,17,3,_ink(row,a*.4))
	_grains(out,row,Vector2(101,141),f,7,a*.7)
static func _prism_fan(out:Image,row:Dictionary,t:float,f:int,phase:String)->void:
	var a:=_opacity(phase,t)
	for n:int in range(5):
		var angle:=-1.3+n*.31+t*.18
		var reach:=(38+t*20 if phase=="CAST" else 77-t*17 if phase=="CONTACT" else 81+t*9)
		var p:=Vector2(83,115)+Vector2(cos(angle),sin(angle))*(reach+n%3*10)
		_diamond(out,row,p,Vector2(8+n%2*3,19+n*3),a,3+n%2)
		_ribbon(out,row,[Vector2(69,120),Vector2(94+n*8,83+n*3),p+Vector2(16,0)],3,t,a*.75)
	_grains(out,row,Vector2(138,63),f,8,a)
static func _clamp(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	var gap:=29*(1-t)+9 if phase=="CONTACT" else 24+sin(t*PI)*17
	if shape=="ice_jaw":
		for side:int in [-1,1]:
			var x:=96+side*gap
			_path(out,row,[Vector2(x,151),Vector2(x+side*18,132),Vector2(x+side*12,71),Vector2(x-side*7,52)],7,a,3)
			for n:int in range(3):_diamond(out,row,Vector2(x+side*12,91+n*15),Vector2(8,12),a,5)
	else:
		_stroke(out,row,Vector2(46-gap*.2,51),Vector2(142-gap,148),9,a,3)
		_stroke(out,row,Vector2(147+gap*.2,58),Vector2(52+gap,145),7,a,5)
		for n:int in range(6):Pixels.rect(out,60+n*13,70+n*12,7,2,_c(row,1,a))
	_grains(out,row,Vector2(97,146),f,5,a*.8)
static func _star_cage(out:Image,row:Dictionary,t:float,f:int,phase:String)->void:
	var a:=_opacity(phase,t)
	var r:=38+t*27 if phase=="CAST" else 67-t*31 if phase=="CONTACT" else 48+t*19
	for n:int in range(3):
		var angle:=n*TAU/3+t*.32
		var p:=Vector2(96,91)+Vector2(cos(angle)*r,sin(angle)*r*.8)
		var q:=Vector2(96,91)-Vector2(cos(angle)*r,sin(angle)*r*.8)
		_stroke(out,row,p,q,4+n%2,a*.8,2+n)
		_diamond(out,row,p,Vector2(8,14),a,3)
	_diamond(out,row,Vector2(96,75),Vector2(20-t*7,31-t*9),a,4)
	Pixels.rect(out,90,68,12,19,_ink(row,a))
	_grains(out,row,Vector2(96,91),f,9,a)
static func _arrow(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	var y:=82+sin(t*PI)*8
	var length:=111.0 if shape=="hunt" else 99.0 if shape=="kite_arrow" else 91.0
	var tip:=159.0 if phase=="CONTACT" else 135+t*27
	_stroke(out,row,Vector2(tip-length,y+12),Vector2(tip,y),6 if shape=="hunt" else 4,a,3)
	Pixels.poly(out,[Vector2(tip-21,y-13),Vector2(tip+12,y),Vector2(tip-18,y+16),Vector2(tip-10,y)],_ink(row,a))
	Pixels.poly(out,[Vector2(tip-15,y-8),Vector2(tip+5,y),Vector2(tip-13,y+10),Vector2(tip-7,y)],_c(row,4,a))
	if shape=="kite_arrow":
		_ribbon(out,row,[Vector2(35,y+23),Vector2(61,y+4),Vector2(86,y+18),Vector2(123,y+6)],2,t,a)
		for n:int in range(3):_panel(out,row,Vector2(44+n*16,y+22+n*5),9,16,3,a,5)
	else:
		for n:int in range(4):
			var x:=tip-34-n*19
			_stroke(out,row,Vector2(x,y+4),Vector2(x-3,y-8-(n%2)*6),4,a,3)
		_ribbon(out,row,[Vector2(31,111),Vector2(54,119),Vector2(83,110),Vector2(114,104)],3,t,a*.55)
	_grains(out,row,Vector2(145,y),f,7,a)
static func _rain(out:Image,row:Dictionary,t:float,f:int,phase:String)->void:
	var a:=_opacity(phase,t)
	for n:int in range(8):
		var x:=30+n*17+posmod(f+n*3,9)
		var y:=22+posmod(f*2+n*11,58) if phase=="CAST" else 31+posmod(f*7+n*17,90)
		_stroke(out,row,Vector2(x,y),Vector2(x+14,y+37),2,a*.7,2)
		Pixels.poly(out,[Vector2(x+9,y+30),Vector2(x+20,y+36),Vector2(x+13,y+42)],_c(row,4,a))
		if n%3==0:_panel(out,row,Vector2(x-6,y-8),12,19,3,a*.7,5)
	# A slanted shower, not an expanding ring or a persistent target zone.
	for n:int in range(3):Pixels.rect(out,48+n*35,147+n%2*4,19,3,_ink(row,a*.35))
static func _weapon(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	if shape=="edge_tabs":
		for n:int in range(3):
			_panel(out,row,Vector2(53+n*41,53+(n%2)*15+sin(t*TAU+n)*4),17+n*3,43,11-n*4,a,3 if n%2 else 5)
		_stroke(out,row,Vector2(53,127),Vector2(147,42),5,a*.9,2)
	elif shape=="cold_blades":
		for side:int in [-1,1]:
			var x:=96+side*43
			_path(out,row,[Vector2(x,147),Vector2(x+side*14,98),Vector2(x-side*8,47),Vector2(x+side*23,61)],6,a,5 if side<0 else 3)
			_grains(out,row,Vector2(x,73),f+side*3,4,a*.7)
	else:
		var x:=142.0
		_path(out,row,[Vector2(x-24,149),Vector2(x+18,113),Vector2(x+25,71),Vector2(x-8,34)],5,a,3)
		_stroke(out,row,Vector2(x-24,149),Vector2(x-8,34),2,a*.7,5)
		for n:int in range(5 if shape=="bone_bow" else 3):
			var y:=47+n*20
			var p:=Vector2(146+sin(t*TAU+n)*7,y)
			_diamond(out,row,p,Vector2(6,13+n%2*4),a,5 if shape=="bone_bow" else 4)
		if shape=="bow_empower":_ribbon(out,row,[Vector2(43,128),Vector2(47,73),Vector2(70,42)],3,t,a*.6)
static func _panels(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	var count:=7 if shape=="witness" else 5 if shape=="docket" else 4 if shape=="court" else 2
	for n:int in range(count):
		var fraction:=float(n)/maxi(1,count-1)
		var x:=29+fraction*135
		var lift:=18*(1-t) if phase=="CAST" else -8+minf(1,t*3)*13 if phase=="CONTACT" else t*17
		var y:=42+absf(fraction-.5)*35+sin(t*TAU+n)*4+lift
		var w:=17.0 if count>=5 else 24.0 if count==4 else 39.0
		var h:=(58+(n%3)*13)*(1-t*.55 if phase=="TAIL" else .7+t*.3 if phase=="CAST" else 1.0)
		_panel(out,row,Vector2(x,y),w,h,8 if n%2 else -9,a,3 if n%2 else 5)
		if shape=="docket":
			_path(out,row,[Vector2(x,y+h-8),Vector2(x+11,y+h+3),Vector2(x+7,y+h+12),Vector2(x-3,y+h+10)],3,a,2)
		elif shape=="witness":
			Pixels.rect(out,roundi(x)-2,roundi(y+h+7),4,12,_c(row,4,a))
		elif shape=="script_wings":
			_ribbon(out,row,[Vector2(x,y+60),Vector2(x-12,y+77),Vector2(x+17,y+88)],3,t,a*.7)
	if shape=="court":_stroke(out,row,Vector2(25,69),Vector2(165,61),4,a*.8,2)
	_grains(out,row,Vector2(96,50),f,4,a*.65)
static func _sweep(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	if shape=="crossbeam":
		var y:=82-t*8
		Pixels.poly(out,[Vector2(25,y+13),Vector2(161,y-11),Vector2(168,y+12),Vector2(37,y+38)],_ink(row,a))
		Pixels.poly(out,[Vector2(33,y+16),Vector2(157,y-5),Vector2(161,y+7),Vector2(40,y+30)],_c(row,2,a))
		for n:int in range(4):_stroke(out,row,Vector2(51+n*29,y+10-n*4),Vector2(53+n*29,y+26-n*4),3,a,4)
	elif shape=="notch_cut":
		_path(out,row,[Vector2(45,145),Vector2(72,114),Vector2(117,69),Vector2(151,39)],8,a,2)
		_path(out,row,[Vector2(55,139),Vector2(83,117),Vector2(116,78),Vector2(150,48)],3,a,4)
		_panel(out,row,Vector2(57,56+t*20),17,37,11,a*.85,5)
		Pixels.rect(out,117,104,12,5,_ink(row,a))
	else:
		var p:Array=[]
		for n:int in range(9):
			var angle:=-2.45+n*.29+t*.22
			p.append(Vector2(97,132)+Vector2(cos(angle)*74,sin(angle)*66))
		_path(out,row,p,7,a,3)
		for n:int in range(4):
			var q:Vector2=p[n*2]
			_stroke(out,row,q,q+Vector2(-8,-18+n*3),4,a*.8,5)
	_grains(out,row,Vector2(130,99),f,8,a)
static func _sun(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	if shape=="mirror_fall":
		for n:int in range(5):
			var x:=35+n*31
			var y:float=55-n%2*17-t*18 if phase=="CAST" else 25+posmod(f*7+n*18,101)
			_diamond(out,row,Vector2(x,y),Vector2(12+(n%2)*3,22+(n%3)*4),a,3+n%2)
			_stroke(out,row,Vector2(x-2,y-24),Vector2(x+2,y-39),2,a*.45,5)
	elif shape=="sun_shear":
		_path(out,row,[Vector2(24,107),Vector2(62,76),Vector2(112,73),Vector2(170,56)],7,a,2)
		_path(out,row,[Vector2(28,124),Vector2(69,92),Vector2(115,88),Vector2(168,76)],5,a,5)
		for n:int in range(3):_diamond(out,row,Vector2(62+n*42,76-n*7),Vector2(6,11),a,4)
	else:
		_diamond(out,row,Vector2(58,79+sin(t*TAU)*4),Vector2(17,29),a,3)
		_diamond(out,row,Vector2(115,63),Vector2(10,22),a,5)
		_path(out,row,[Vector2(29,120),Vector2(58,79),Vector2(115,63),Vector2(171,84)],5,a,4)
		_stroke(out,row,Vector2(121,66),Vector2(168,83),2,a*.7,5)
	_grains(out,row,Vector2(118,52),f,7,a*.8)
static func _lantern(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	if shape=="siphon":
		# A hollow, irregular mirror with a single off-centre eye; no damage ring.
		_path(out,row,[Vector2(45,132),Vector2(32,80),Vector2(52,37),Vector2(123,30),Vector2(158,79),Vector2(144,134)],8,a,2)
		_diamond(out,row,Vector2(127,62),Vector2(10,18),a,4)
		for n:int in range(3):_ribbon(out,row,[Vector2(151,129+n*5),Vector2(132,112-n*8),Vector2(61,101-n*9),Vector2(44,77)],3,1-t,a*.7)
	elif shape=="eye_chain":
		for n:int in range(3):
			var p:=Vector2(41+n*54,103-n%2*43+sin(t*TAU+n)*5)
			_lamp_eye(out,row,p,20-n%2*4,a)
			if n>0:_ribbon(out,row,[Vector2(p.x-51,p.y+26),Vector2(p.x-24,p.y-14),p],3,t,a*.7)
	else:
		for n:int in range(3):
			var x:=39+n*57
			var y:=66+n%2*27
			_lamp_eye(out,row,Vector2(x,y),18,a)
			_path(out,row,[Vector2(x-14,y+11),Vector2(x-22,y+47),Vector2(x+8,y+56)],5,a,2)
			Pixels.rect(out,x-3,y+31+f%3,5,15,_c(row,5,a*.7))
	_grains(out,row,Vector2(98,67),f,6,a*.7)
static func _lamp_eye(out:Image,row:Dictionary,p:Vector2,size:float,a:float)->void:
	Pixels.poly(out,[p+Vector2(-size,-5),p+Vector2(-size*.45,-size),p+Vector2(size*.6,-size*.7),p+Vector2(size,5),p+Vector2(0,size*.7)],_ink(row,a))
	_stroke(out,row,p+Vector2(-size+3,0),p+Vector2(size-3,0),5,a,2)
	_diamond(out,row,p+Vector2(size*.2,-2),Vector2(4,9),a,4)
static func _chain(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	for n:int in range(7):
		var p:=Vector2(30+n*21,97+sin(t*TAU+n*.67)*22)
		if shape=="hook" and n%3==0:
			_path(out,row,[p+Vector2(-7,15),p+Vector2(8,-16),p+Vector2(13,-10),p+Vector2(8,3),p+Vector2(-2,3)],5,a,3)
		else:
			_path(out,row,[p+Vector2(-8,0),p+Vector2(0,-9),p+Vector2(9,0),p+Vector2(0,8),p+Vector2(-8,0)],4,a,3 if n%2 else 5)
		if n<6:_stroke(out,row,p+Vector2(5,0),Vector2(p.x+16,p.y+5),2,a*.8,2)
	_grains(out,row,Vector2(146,95),f,5,a*.7)
static func _bell(out:Image,row:Dictionary,t:float,f:int,phase:String)->void:
	var a:=_opacity(phase,t)
	var shift:=sin(t*TAU)*6 if phase=="CAST" else sin(t*PI)*3 if phase=="CONTACT" else t*8
	_path(out,row,[Vector2(34+shift,136),Vector2(52+shift,117),Vector2(59+shift,58),Vector2(80+shift,36),Vector2(117+shift,40),Vector2(140+shift,67),Vector2(148+shift,117),Vector2(162+shift,135)],8,a,2)
	_stroke(out,row,Vector2(34+shift,136),Vector2(162+shift,135),6,a,3)
	_stroke(out,row,Vector2(109+shift,44),Vector2(93+shift,77),4,a,5)
	_stroke(out,row,Vector2(93+shift,77),Vector2(112+shift,99),4,a,5)
	_diamond(out,row,Vector2(114+shift,111),Vector2(9,16),a,4)
	for n:int in range(5):Pixels.rect(out,36+n*30,149+((f+n)%3),3,6,_c(row,4,a*.75))
static func _cloth(out:Image,row:Dictionary,t:float,f:int,phase:String,shape:String)->void:
	var a:=_opacity(phase,t)
	if shape=="curtain":
		var close:=20+t*17 if phase=="CONTACT" else 17+sin(t*PI)*12
		_panel(out,row,Vector2(44+close*.25,34),43,109,16,a,2)
		_panel(out,row,Vector2(149-close*.25,58),31,85,-15,a,5)
		_ribbon(out,row,[Vector2(48,43),Vector2(81,28),Vector2(132,39),Vector2(158,60)],4,t,a)
		_stroke(out,row,Vector2(134-close*.2,88),Vector2(116,140),3,a*.8,4)
	else:
		for n:int in range(3):
			var x:=38+n*56
			var y:=38+(n%2)*19
			_panel(out,row,Vector2(x,y),29+n*3,75-(n%2)*9,11-n*8,a,2+n%3)
			_stroke(out,row,Vector2(x-14,y+70),Vector2(x+12,y+3),3,a,4)
		_ribbon(out,row,[Vector2(37,144),Vector2(72,153),Vector2(124,149),Vector2(157,134)],4,t,a*.75)
	_grains(out,row,Vector2(96,47),f,5,a*.6)

static func _identity(out:Image,row:Dictionary,t:float,f:int,shape:String)->void:
	# Small personal marks avoid pretending an innate condition is currently
	# satisfied. Genuine benefit/range/trigger visuals are separate consumers.
	var k:=int(row.variant)
	var base:=Vector2(57+k%8,112-k%3*6)
	var a:=.5+float(f%6)*.05
	if shape in ["banner","march","medallion","page_mark"]:
		_panel(out,row,base+Vector2(0,-17),17+k%4,29+k%5,3+k%7,a,3)
		_diamond(out,row,base+Vector2(11,17),Vector2(4,7),a,5)
	elif shape in ["brace","brace_mark","joinery_mark","mortise"]:
		_path(out,row,[base+Vector2(-7,21),base+Vector2(-11,-8),base+Vector2(9,-15),base+Vector2(13,8)],4,a,2)
		Pixels.rect(out,roundi(base.x)+10,roundi(base.y)+4,8,4,_c(row,4,a))
	elif shape in ["prism_mark","mirror_mark"]:
		for n:int in range(3):_diamond(out,row,base+Vector2(n*11-10,-14+n%2*17),Vector2(5,10+n%2*2),a,3+n%2)
	elif shape in ["kite_mark","arrow_mark"]:
		_path(out,row,[base+Vector2(-10,-22),base+Vector2(11,-3),base+Vector2(-6,22)],3,a,3)
		_panel(out,row,base+Vector2(3,0),9,17,6,a,5)
	elif shape in ["rib","bone_mark"]:
		for n:int in range(3):_path(out,row,[base+Vector2(-11+n*2,-19+n*12),base+Vector2(8+n*2,-14+n*12),base+Vector2(14,-7+n*12)],3,a,3)
	elif shape in ["eye_mark","lantern_trim"]:
		_lamp_eye(out,row,base+Vector2(0,-9),14,a)
		Pixels.rect(out,roundi(base.x)-3,roundi(base.y)+12,5,9,_c(row,5,a))
	elif shape in ["bell_mark","bell_meter"]:
		_path(out,row,[base+Vector2(-12,14),base+Vector2(-6,-16),base+Vector2(10,-20),base+Vector2(17,11)],4,a,3)
		Pixels.rect(out,roundi(base.x)-14,roundi(base.y)+14,32,3,_c(row,2,a))
	elif shape in ["hook_mark","measure_mark"]:
		_path(out,row,[base+Vector2(-8,23),base+Vector2(13,-16),base+Vector2(4,-24),base+Vector2(-9,-12)],4,a,3)
		for n:int in range(3):Pixels.rect(out,roundi(base.x)-8+n*6,roundi(base.y)-4+n*7,7,2,_c(row,5,a))
	elif shape in ["sail_mark","sails"]:
		_panel(out,row,base+Vector2(0,-20),20,35,9,a,2)
		_stroke(out,row,base+Vector2(-11,17),base+Vector2(11,-16),2,a,4)
	else:
		_ribbon(out,row,[base+Vector2(-8,21),base+Vector2(-16,-7),base+Vector2(0,-19),base+Vector2(13,-6)],2,t,a)
	# This different material mote moves around an open, non-circular ladder,
	# giving 12 actual authored poses even for deliberately low-key passives.
	var p:=base+Vector2(-17+f*3,-28+(f%4)*4)
	Pixels.rect(out,roundi(p.x)-1,roundi(p.y)-1,5,5,_ink(row,.4))
	Pixels.rect(out,roundi(p.x),roundi(p.y),3,3,_c(row,4,.8))
static func _finish(out:Image)->void:
	# Always reserve two transparent edge pixels and readable body core.
	out.fill_rect(Rect2i(0,0,SIZE,2),Color.TRANSPARENT)
	out.fill_rect(Rect2i(0,SIZE-2,SIZE,2),Color.TRANSPARENT)
	out.fill_rect(Rect2i(0,0,2,SIZE),Color.TRANSPARENT)
	out.fill_rect(Rect2i(SIZE-2,0,2,SIZE),Color.TRANSPARENT)
	for y:int in range(84,136):
		for x:int in range(82,110):
			var c:=out.get_pixel(x,y)
			if c.a>48.0/255.0:
				c.a=48.0/255.0
				out.set_pixel(x,y,c)

