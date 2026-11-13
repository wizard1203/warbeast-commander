extends RefCounted
## M63 authored, stateless MACHINE presentation. Combat and hit ownership stay
## in the catalogs. Small hand tools replace the M61 oversized floating props.
const Brush = preload("res://src/presentation/m63_av_brush.gd")
const VERSION := "m63-machine-av-v1"
## Ink / shadow / body / contrast / core / afterglow / metal.
const PALETTES := {
	"pressure":["191c20","544a3b","a7794f","80a89c","ffe3a1","c4bca2","a6aeb0"],
	"shuttle":["171e24","3f4855","7a96a0","cfb35f","f4f0ba","9bbfa7","bd9870"],
	"carbine":["201b1a","614238","af704f","9baf93","ffe2a1","c1a39a","aab6ba"],
	"welder":["201d19","66503b","c39053","8ba696","fff0b2","b3c3b6","a8a995"],
	"signal":["1d1c24","554652","ad7c76","b9bfa2","fff0bc","9aa9c3","c3b290"],
	"guard":["171d21","48515a","89959c","b97a4c","f7d89d","95b3b3","c2b5a0"],
	"shard":["1d2025","464b60","8c99ba","d28e65","fff2c4","b5c6a0","b7a893"],
	"cannon":["1c211c","465342","879371","c2a175","f5dfa2","b69b8a","adb3aa"],
	"drone":["19231f","40594c","88af90","c7a06b","f8eec1","9cbdc7","bcb3a1"],
	"aether":["211a23","594356","a67d99","d5ad66","fff2bf","a3c4b4","b6aea0"],
	"worker":["201e1b","5c5140","b19a6a","94adab","f0d8a9","b69f94","a9b3a6"],
	"patch":["221e1c","725039","c48b54","96b6a0","fff2c2","c8b7a4","b4b9ae"],
	"brace":["1a211d","4a5e4d","8eae91","d2aa6e","f2e8bc","a6b5c7","b0bcb2"],
	"gate":["1a2023","415359","8ca4a6","d7a369","f1e8b4","aab4a0","b5c3c0"],
	"electrode":["231e1c","726037","d5b356","a19cb6","fff6cb","9ebcb0","bf9771"],
	"weave":["172026","335c64","76b5b7","d2a26f","eff7d2","b4c797","a696bd"],
	"switchyard":["211b28","594576","a78fc9","9ac7a7","fff0bc","d5b176","a4b4bc"],
	"shell":["211b1b","734b39","c58055","9eb6a4","fff0b9","b89e9b","b8bcb1"],
	"ratchet":["1e2119","5b6740","afbd68","c69b7b","fff2bc","95b9bf","bdb094"],
	"piercer":["201b21","5a4854","a78699","e0ac68","fff1c1","a2b9a5","b3bdc6"],
	"heat":["1e221b","526046","a4b57d","c89d78","fff2c2","a2b9b4","beb39b"],
	"resin":["201b19","714d34","d19a56","a9c1a6","fff0b5","c5b4a2","b6bcae"],
	"dock":["1e211b","515d43","9aab76","d6a16d","fff0b9","a4bdb6","c5b99b"],
	"march":["201d25","5b4d69","ad9cbc","c6b17a","fff2c9","9cb8ae","bab8a1"],
	"cut":["241d20","784f56","cc9090","a8c3ae","fff0c1","c3abc6","b9af95"],
	"shutter":["211c28","554869","a797be","d8b677","fff2cd","9db9b3","c6ad99"]
}
## name, silhouette, palette, crest polygon, body offset, actual gesture,
## voice recipe, story, counterplay. The underlying runtime body is retained.
const ACTOR_ROWS := {
	"hero:COIL_WARDEN":["铆冠","宽磁靴承重体；胸侧锅炉与低轴套冠","pressure",[Vector2(-6,2),Vector2(-6,-2),Vector2(-3,-2),Vector2(-3,-5),Vector2(0,-3),Vector2(3,-5),Vector2(3,-2),Vector2(6,-2),Vector2(6,2)],Vector2(0,-22),"pressure_punch",["rumble",110,0.72,2,"falling_weight",0.36,1.6,-0.32,0.05],"十一副身体的监工交还否决权，以可检修的压力胸扛住未决表决。","近身施压、移动打断驻地；自修不带敌方伤害。"],
	"hero:VOLT_WEAVER":["脉澜","窄织梭肩架；一高一低线圈齿","shuttle",[Vector2(-5,3),Vector2(-5,-1),Vector2(-2,-5),Vector2(0,-2),Vector2(4,-4),Vector2(6,0),Vector2(3,3)],Vector2(-3,-18),"shuttle_flick",["pluck",640,0.28,3,"staggered_reprise",0.28,2.4,0.22,0.10],"织机调音学徒用可拆铜纱修补能源接口，保留刻意停顿。","分散切断后续链段，贴近脆弱织师。"],
	"hero:GEAR_HUNTER":["齿影","偏置折肩弹仓；三段不等径齿列","carbine",[Vector2(-6,2),Vector2(-6,-1),Vector2(-3,-1),Vector2(-3,-4),Vector2(0,-4),Vector2(0,-2),Vector2(3,-2),Vector2(3,-5),Vector2(6,-5),Vector2(6,2)],Vector2(3,-19),"carbine_recoil",["crack",220,0.83,1,"sharp_cut",0.21,1.8,-0.18,0.03],"弃料签约人砸过高价核心救学徒，回收单不记录人。","掩护被破甲者，撤出强化普攻窗口。"],
	"hero:COIL_MEDIC":["焊灯","保温背炉；杯架横梁与下垂软管","welder",[Vector2(-6,-3),Vector2(6,-3),Vector2(6,0),Vector2(3,0),Vector2(3,4),Vector2(0,4),Vector2(0,0),Vector2(-3,0),Vector2(-3,3),Vector2(-6,3)],Vector2(-3,-17),"welder_spit",["breath",330,0.45,2,"inward_return",0.34,1.3,-0.12,0.08],"夜班司炉用树脂封漏，先记工人的饭点再记维修效率。","隔断少目标机械维修；普通攻击只是短树脂击。"],
	"hero:SIGNAL_KEEPER":["讯衡","双向旗板；胸前针盘和断缆扣","signal",[Vector2(-6,-4),Vector2(-1,-4),Vector2(-1,-1),Vector2(1,-1),Vector2(1,-4),Vector2(6,-4),Vector2(6,1),Vector2(2,1),Vector2(2,4),Vector2(-2,4),Vector2(-2,1),Vector2(-6,1)],Vector2(0,-19),"semaphore_tap",["click",900,0.16,4,"gather_and_lock",0.30,2.8,-0.08,0.02],"无声线路官要求可返回的回执，让指挥可以被下属纠正。","散开断开链控或离开封锁区域。"],
	"rivet_guard":["铆钉卫","平顶短冲头；偏置肩铆块","guard",[Vector2(-5,-3),Vector2(3,-3),Vector2(3,-1),Vector2(6,-1),Vector2(6,3),Vector2(-5,3)],Vector2(3,-17),"rivet_drive",["clang",175,0.78,1,"falling_weight",0.24,2.1,-0.28,0.04],"工坊轮值护卫把装轨冲头改作短程自卫，不拥有监工磁闸。","短射程且移动慢，可远程消耗。"],
	"shard_gunner":["碎晶枪手","短晶弹匣；斜角护目片","shard",[Vector2(-6,0),Vector2(-2,-4),Vector2(5,-4),Vector2(6,0),Vector2(2,3),Vector2(-4,3)],Vector2(1,-21),"shard_bolt",["crack",420,0.63,2,"opening_fan",0.18,3.2,0.08,0.02],"公社标准晶弹枪手以整齐短匣换弹，与弃料猎手重膛不同。","无甲远程兵，贴身和侧翼突破可压制。"],
	"gear_engine":["齿轮战车","矮横膛与双侧压杆；平直装甲顶","cannon",[Vector2(-7,3),Vector2(-7,-1),Vector2(-3,-1),Vector2(-3,-4),Vector2(4,-4),Vector2(4,-1),Vector2(7,-1),Vector2(7,3)],Vector2(0,-13),"cannon_lob",["rumble",90,0.88,2,"directional_rush",0.39,1.4,-0.45,0.12],"断轨拖车改造的短炮底盘，用后坐滑轨承受长程抛射。","慢速且攻击间隔长；避免地面部队密集承受真实溅射。"],
	"repair_drone":["维修机","短钳双叉；低位方形工具盒","drone",[Vector2(-5,3),Vector2(-5,-4),Vector2(-2,-4),Vector2(-2,0),Vector2(2,0),Vector2(2,-4),Vector2(5,-4),Vector2(5,3)],Vector2(0,-17),"pincer_probe",["buzz",510,0.33,3,"woven_drift",0.27,1.7,0.10,0.06],"移动工具台的针钳只维修真实机械目标，未持有焊灯检修坞。","切断维修距离、耗尽其付费蓝量；可被集火。"],
	"aether_engine":["灵核战车","阶梯重核膛；封闭双锁扣","aether",[Vector2(-7,4),Vector2(-7,-1),Vector2(-4,-1),Vector2(-4,-5),Vector2(4,-5),Vector2(4,-1),Vector2(7,-1),Vector2(7,4),Vector2(3,4),Vector2(3,1),Vector2(-3,1),Vector2(-3,4)],Vector2(0,-16),"aether_breech",["clang",125,0.92,3,"gather_and_lock",0.40,1.2,-0.52,0.16],"高阶重核膛必须逐道解锁，昂贵灵髓投入压成单支重炮弹。","较短重炮射程与高资源人口代价；分散地面队伍。"],
	"worker:MACHINE":["铆炉工人","扳钳工具架；侧挂铆钉盒","worker",[Vector2(-5,4),Vector2(-5,-3),Vector2(-1,-3),Vector2(-1,0),Vector2(2,0),Vector2(2,-4),Vector2(5,-4),Vector2(5,4)],Vector2(-4,-15),"wrench_work",["scrape",280,0.58,2,"inward_return",0.23,1.5,-0.16,0.01],"轮班修桥工带钳锤与铆钉盒，经济劳动优先于自卫。","260生命工人仍脆弱；无额外战斗或维修能力。"]
}
## hero, name, gesture, palette, sound, story, counterplay, four phases,
## passive, authority guard. Names follow the final M58 projection, not IDs.
const SKILL_ROWS := {
	"COIL_SHOCK":["COIL_WARDEN","应急检修","piston_patch","patch",["breath",150,0.60,3,"inward_return",0.62,1.4,-0.38,0.05],"第十一副机体公开泄压，再把裂口压回可修状态。","自身恢复仍可受伤，不对敌军放电。",["侧阀短汽","双活塞向内","胸侧补片扣合","薄汽退去；净化由真实结算"],false,"HEAL SELF＋净化DoT；仅自身局部，不画敌方命中。"],
	"COIL_WARD":["COIL_WARDEN","铆甲核心","planted_braces","brace",["rumble",82,0.24,2,"breathing_lift",0.38,1.3,0.0,0.02],"共同承重的磁靴先站稳，公社才能继续表决。","移动破坏驻地两秒条件；受益机械由权威筛选。",["被动无施放","驻地读取真实状态","只对真实受益显示","离场／死亡／条件失效即收"],true,"PASSIVE_GUARD＋条件机械攻速光环；不生成cast。"],
	"COIL_REPAIR":["COIL_WARDEN","电磁壁垒","relay_clamp","gate",["clang",135,0.70,3,"gather_and_lock",1.32,1.8,-0.28,0.14],"交还否决权后，监工的磁闸只为争取短暂停战时间。","隔开敌兵切断三目标连锁，纯控无伤。",["承重阀蓄压","一对磁夹向合法主目标合拢","局部闸页锁止；额外链交原连接器","闸片松开；眩晕持续由权威状态"],false,"CHAIN 零伤STUN大招，最多三目标；不是维修。"],
	"VOLT_BIND":["VOLT_WEAVER","电弧封锁","electrode_tension","electrode",["pluck",730,0.42,2,"sharp_cut",0.48,3.2,0.36,0.05],"脉澜把一次刻意停顿变成绷紧的铜纱。","单体伤害＋眩晕，掩护关键目标或突入织师近身。",["手梭停半拍","窄铜线绷向唯一目标","对置电极短促夹合","只留局部断纱，真实眩晕另行到期"],false,"SINGLE 混合伤害STUN；禁止画额外目标。"],
	"VOLT_ARC":["VOLT_WEAVER","脉冲爆","shuttle_stitch","weave",["pluck",580,0.32,5,"staggered_reprise",0.67,2.6,0.24,0.12],"可拆能源纱穿梭跳接，每个错拍都有接线位置。","分散降低连锁数量；衰减仅由权威。",["梭肩后拉","单梭之字穿线","合法主目标电针点亮","断纱回收；后续真实链段由原连接器"],false,"CHAIN 纯伤最多四目标；不寻找或虚构邻兵。"],
	"VOLT_NETWORK":["VOLT_WEAVER","风暴回路","switchyard_split","switchyard",["buzz",390,0.64,7,"woven_drift",1.76,2.2,0.45,0.20],"暴露夜班造假的错拍灯网化为不对称道岔接口。","分散限制五目标覆盖；减速仍能攻击和施法。",["偏心肩轮打开","一粗一细道岔在主段交接","局部分段导线压低","碎线落下；真实SLOW不是STUN"],false,"CHAIN 伤害＋SLOW大招；支线是材料，非额外敌兵命中。"],
	"GEAR_SHOT":["GEAR_HUNTER","碎轮弹","drill_shell","shell",["crack",245,0.88,2,"directional_rush",0.43,2.0,-0.30,0.04],"不配套轮弩把带回收印的铆钉弹压进单一护甲点。","保护被破甲者，弹壳没有额外伤害。",["弹仓卡扣","枪身后坐／单弹直出","一片斜甲断开","一枚弹壳下落；破甲按真实状态"],false,"SINGLE 火药伤害＋ARMOR_BREAK；非散射。"],
	"GEAR_FERVOR":["GEAR_HUNTER","齿轮超频","ratchet_spool","ratchet",["click",305,0.55,6,"staggered_reprise",0.72,1.7,0.40,0.03],"三片不等径轮盘依次解锁，先开救人的通路。","撤离普攻范围并消耗强化窗口。",["侧棘轮按次起转","短轴逐个弹开","仅自身侧后排汽","有限强化由真实buff来源维持／到期"],false,"SELF DAMAGE_BUFF；不画敌方命中，不自计时持续。"],
	"GEAR_REPAIR":["GEAR_HUNTER","破甲锁弹","heavy_lockshot","piercer",["crack",145,0.93,3,"falling_weight",1.38,1.4,-0.58,0.17],"为救学徒砸核心的人，让重膛弹只破开挡路的厚甲。","单个高价值目标需要掩护；无范围清场。",["两道重锁依次合上","枪管短后坐／一支重弹","局部厚甲分成两片","弹壳重落；破甲读取真实持续"],false,"SINGLE 火药伤害＋ARMOR_BREAK大招；非HEAL／SELF。"],
	"COIL_BATTERY":["COIL_MEDIC","稳压光环","insulated_tabs","heat",["reed",270,0.22,2,"breathing_lift",0.40,1.6,-0.05,0.05],"保温炉绝缘片分享安全，晚班也有固定的照料。","离开真实光环或压制医师；不制造回蓝。",["被动无施放","绝缘片低亮","真实护甲受益才保留","来源失效撤去"],true,"AURA 护甲被动；不生成cast或MP回复。"],
	"COIL_MEND":["COIL_MEDIC","线圈检修","resin_drip","resin",["water",360,0.41,3,"inward_return",0.69,1.3,-0.20,0.07],"夜班暖轨师抬软管，将热树脂滴进机械裂口。","隔开维修射程；非机械友军不能收到假治疗。",["枪嘴向下","琥珀焊珠下滴","自身补片压合","冷却短汽；友军仅由真实HEAL连接器表现"],false,"HEAL 自身＋最多两名MACHINE友军；非全军维修。"],
	"COIL_OVERHAUL":["COIL_MEDIC","全域检修","offset_dock","dock",["scrape",205,0.52,4,"breathing_lift",1.86,1.5,0.15,0.13],"拆灯供暖的司炉把检修架做成可逐层落下的工作台。","少目标治疗需要取舍，不会留下额外护盾。",["短支架错层撑起","自身两个不等高检修脚","局部树脂补片","支架落下；净化与机械友军由真实结算"],false,"HEAL＋净化DoT大招，自身＋最多三MACHINE友军；无额外护甲。"],
	"SIGNAL_MARCH":["SIGNAL_KEEPER","信标光环","flag_confirm","march",["click",810,0.12,3,"opening_fan",0.32,2.8,0.0,0.02],"无声线路官用双向旗板先送出再确认，不替人同意。","分割军阵离开覆盖；光环不等于瞬移。",["被动无施放","小旗一收一发","真实移速受益读取覆盖","离场即收"],true,"AURA 百分比移速被动；不产生cast。"],
	"SIGNAL_LOCK":["SIGNAL_KEEPER","断路脉冲","right_angle_cut","cut",["click",1000,0.20,5,"gather_and_lock",0.56,3.4,-0.16,0.03],"误码后每条命令必须可以回执，未确认支路可被截断。","分散切断三目标连锁；纯控无伤。",["两小旗收发","直角短码向主目标返回","单个剪口闭合","局部黑白停码；真实链段由原连接器"],false,"CHAIN 零伤STUN；无爆炸、维修或额外弹丸。"],
	"SIGNAL_BLACKOUT":["SIGNAL_KEEPER","静电封锁","opposed_shutters","shutter",["reed",180,0.57,6,"opening_fan",1.56,1.9,-0.34,0.11],"回执消失时，讯衡把断开式电缆折为可辨的遮板。","离开实际选点区域；不会改变视野或使部队隐身。",["施法者双旗展开","两块短遮板相向平移","命中中心错层合拢","遮板滑开；真正区域与目标交权威"],false,"AREA 零伤STUN大招，最多五目标；不是致盲。"]
}
const TOOL_SHAPES := {
	"ram":[Vector2(-6,-4),Vector2(6,-4),Vector2(6,3),Vector2(2,3),Vector2(2,9),Vector2(-2,9),Vector2(-2,3),Vector2(-6,3)],
	"shuttle":[Vector2(-9,0),Vector2(-3,-4),Vector2(5,-3),Vector2(10,0),Vector2(3,4),Vector2(-5,3)],
	"gun":[Vector2(-9,-3),Vector2(8,-3),Vector2(11,-1),Vector2(8,2),Vector2(-2,2),Vector2(-3,6),Vector2(-6,6),Vector2(-6,2),Vector2(-9,2)],
	"nozzle":[Vector2(-7,-4),Vector2(-1,-4),Vector2(-1,-1),Vector2(9,-1),Vector2(9,2),Vector2(-1,2),Vector2(-1,6),Vector2(-6,6)],
	"flag":[Vector2(-1,7),Vector2(-1,-6),Vector2(7,-6),Vector2(5,-1),Vector2(1,-1),Vector2(1,7)],
	"clamp":[Vector2(-6,-5),Vector2(-2,-5),Vector2(-2,1),Vector2(2,1),Vector2(2,-5),Vector2(6,-5),Vector2(6,5),Vector2(-6,5)],
	"shell":[Vector2(-6,-3),Vector2(3,-3),Vector2(8,0),Vector2(3,3),Vector2(-6,3)],
	"plate":[Vector2(-5,-5),Vector2(4,-5),Vector2(6,2),Vector2(1,5),Vector2(-5,3)],
	"wrench":[Vector2(-2,7),Vector2(-2,-1),Vector2(-6,-4),Vector2(-5,-8),Vector2(-2,-5),Vector2(2,-5),Vector2(5,-8),Vector2(6,-4),Vector2(2,-1),Vector2(2,7)]
}

static func actors() -> Dictionary:
	var result := {}
	for identity: String in ACTOR_ROWS: result[identity] = actor_profile(identity)
	return result.duplicate(true)

static func skills() -> Dictionary:
	var result := {}
	for skill_id: String in SKILL_ROWS: result[skill_id] = skill_profile(skill_id)
	return result.duplicate(true)

static func actor_profile(identity: String) -> Dictionary:
	if not ACTOR_ROWS.has(identity): return {}
	var r: Array = ACTOR_ROWS[identity]
	return {"identity":identity,"faction_id":"MACHINE","name":r[0],"silhouette":r[1],"palette":PALETTES[r[2]].duplicate(true),"crest":r[3].duplicate(true),"crest_offset":r[4],"gesture":r[5],"sound":_sound(r[6]),"story_anchor":r[7],"counterplay":r[8],"identity_version":VERSION,"body_revision":"retained_runtime_body_plus_small_crest"}.duplicate(true)

static func skill_profile(skill_id: String) -> Dictionary:
	if not SKILL_ROWS.has(skill_id): return {}
	var r: Array = SKILL_ROWS[skill_id]
	return {"skill_id":skill_id,"hero_id":r[0],"faction_id":"MACHINE","name":r[1],"gesture":r[2],"palette":PALETTES[r[3]].duplicate(true),"sound":_sound(r[4]),"story_anchor":r[5],"counterplay":r[6],"phases":r[7].duplicate(true),"passive":r[8],"authority_guard":r[9],"identity_version":VERSION}.duplicate(true)

static func _sound(r: Array) -> Dictionary:
	return {"voice":r[0],"frequency":r[1],"texture":r[2],"pulses":r[3],"rhythm":r[4],"seconds":r[5],"overtone":r[6],"sweep":r[7],"echo":r[8]}

static func draw_signature(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, spec: Dictionary) -> void:
	if not origin.is_finite() or not center.is_finite() or not is_finite(scale) or scale <= 0: return
	if bool(spec.get("passive",false)) or str(spec.get("effect","")) in ["AURA","PASSIVE_GUARD"]: return
	var p := clampf(float(ctx.get("phase",0.0)),0.0,1.0)
	var a := clampf(sin(p * PI) * 1.6,0.0,1.0)
	if a <= 0.01: return
	var old_limit := int(ctx.get("draw_limit",0))
	ctx.draw_limit = mini(old_limit,int(ctx.get("count",0)) + (36 if bool(spec.get("is_skill",false)) else 24))
	var colors: Array = spec.get("palette",PALETTES.pressure)
	var d := (center-origin).normalized()
	if d.length_squared() < 0.1: d = Vector2.RIGHT
	var side := d.orthogonal()
	var angle := d.angle()
	var release := clampf((p-0.16)/0.56,0.0,1.0)
	var punch := sin(release*PI)
	var hand := origin
	var hit := center
	var head := hand.lerp(hit,release)
	var g := str(spec.get("gesture",""))
	match g:
		"pressure_punch":
			_prop(ctx,hand+d*(3.0+8.0*punch)*scale,"ram",scale,colors,angle-PI*0.5,a)
			_steam(ctx,hand-d*6.0*scale,p,scale,colors,a,2)
			if p>0.48 and p<0.8: _chip(ctx,hit,Vector2(3,2)*scale,colors[6],a)
		"rivet_drive":
			_prop(ctx,hand+d*(2.0+11.0*punch)*scale,"ram",scale*0.75,colors,angle-PI*0.5,a)
			if release>0.5:
				for n: int in range(2): _chip(ctx,hit+Vector2((n*2-1)*6.0*release,-4.0+8.0*release)*scale,Vector2(2,1)*scale,colors[3],a)
		"shuttle_flick":
			_prop(ctx,hand+side*(4.0-8.0*release)*scale,"shuttle",scale*0.65,colors,angle,a)
			_prop(ctx,head+side*sin(release*TAU)*4.0*scale,"shuttle",scale*0.4,colors,angle,a)
			_line(ctx,head-d*9.0*scale,head,1.5*scale,colors[3],a)
		"carbine_recoil", "shard_bolt":
			var shard := g=="shard_bolt"
			_prop(ctx,hand-d*punch*5.0*scale,"gun",scale*(0.7 if shard else 0.95),colors,angle,a)
			_prop(ctx,head,"shell",scale*(0.4 if shard else 0.5),colors,angle,a)
			if p>0.18 and p<0.48: _chip(ctx,hand+d*10.0*scale,Vector2(3,1)*scale,colors[4],a)
			if not shard: _chip(ctx,hand+side*(6.0+5.0*release)*scale,Vector2(1,2)*scale,colors[6],a)
		"welder_spit":
			_prop(ctx,hand,"nozzle",scale*0.75,colors,angle,a)
			_prop(ctx,head+Vector2(0,-sin(release*PI)*8.0)*scale,"shell",scale*0.36,colors,angle,a)
			if p>0.6: _chip(ctx,hit,Vector2(3,1)*scale,colors[3],a)
		"semaphore_tap":
			_prop(ctx,hand+Vector2(-4,-2)*scale,"flag",scale*0.7,colors,-0.4+punch,a)
			var elbow := Vector2(head.x,hand.y)
			_line(ctx,hand,elbow,1.5*scale,colors[6],a)
			_line(ctx,elbow,head,1.5*scale,colors[3],a)
			_chip(ctx,head,Vector2(2,2)*scale,colors[4],a)
		"cannon_lob":
			_prop(ctx,hand-d*punch*6.0*scale,"gun",scale,colors,angle,a)
			_prop(ctx,head+Vector2(0,-sin(release*PI)*20.0)*scale,"shell",scale*0.65,colors,angle+release*0.25,a)
			_steam(ctx,hand-d*10.0*scale,p,scale,colors,a,3)
			if p>0.7: _prop(ctx,hit,"plate",scale*0.45,colors,release,a)
		"pincer_probe":
			_prop(ctx,hand,"clamp",scale*0.7,colors,angle-PI*0.5,a)
			_line(ctx,head-d*7.0*scale,head,2.0*scale,colors[3],a)
			_chip(ctx,head,Vector2(2,3)*scale,colors[4],a)
		"aether_breech":
			for s: int in [-1,1]: _prop(ctx,hand+side*s*(5.0+3.0*punch)*scale,"plate",scale*0.55,colors,angle,a)
			_prop(ctx,head,"shell",scale*0.9,colors,angle,a)
			_steam(ctx,hand-d*6.0*scale,p,scale,colors,a,2)
			if p>0.68:
				for s: int in [-1,1]: _prop(ctx,hit+side*s*5.0*release*scale,"plate",scale*0.45,colors,angle+s*release,a)
		"wrench_work":
			_prop(ctx,hand+Vector2(3.0*punch,4.0*punch)*scale,"wrench",scale*0.75,colors,-0.8+release*1.1,a)
			if p>0.48: _chip(ctx,hand+Vector2(5,7)*scale,Vector2(2,1)*scale,colors[6],a)
		"piston_patch":
			for s: int in [-1,1]:
				_prop(ctx,hand+Vector2(s*(11.0-7.0*release),1)*scale,"ram",scale*0.6,colors,s*PI*0.5,a)
			_prop(ctx,hand,"plate",scale*0.6,colors,0,a)
			_steam(ctx,hand+Vector2(-8,2)*scale,p,scale,colors,a,3)
		"relay_clamp":
			_prop(ctx,hand,"ram",scale*0.65,colors,-0.3,a)
			for s: int in [-1,1]:
				_prop(ctx,hit+side*s*(12.0-7.0*release)*scale,"clamp",scale*0.65,colors,angle+s*PI*0.5,a)
			if p<0.6: _line(ctx,head-d*8.0*scale,head,2.0*scale,colors[6],a)
		"electrode_tension":
			_prop(ctx,hand,"shuttle",scale*0.65,colors,angle-0.5*punch,a)
			_line(ctx,hand,head,2.0*scale,colors[3],a*0.75)
			for s: int in [-1,1]: _chip(ctx,hit+side*s*(9.0-4.0*release)*scale,Vector2(2,5)*scale,colors[2],a)
			if p>0.5 and p<0.74: _line(ctx,hit-side*3.0*scale,hit+side*3.0*scale,2.0*scale,colors[4],a)
		"shuttle_stitch":
			_prop(ctx,hand+side*(4.0-8.0*release)*scale,"shuttle",scale*0.7,colors,angle,a)
			var bend := hand.lerp(head,0.55)+side*(5.0 if p<0.55 else -5.0)*scale
			_line(ctx,hand,bend,2.0*scale,colors[6],a*0.8)
			_line(ctx,bend,head,2.0*scale,colors[3],a)
			_prop(ctx,head,"shuttle",scale*0.5,colors,angle,a)
			if p>0.65: _chip(ctx,hit,Vector2(2,4)*scale,colors[4],a)
		"switchyard_split":
			_prop(ctx,hand,"shuttle",scale*0.8,colors,angle+punch*0.3,a)
			var bend := hand.lerp(head,0.62)+side*7.0*scale
			_line(ctx,hand,bend,3.0*scale,colors[2],a)
			_line(ctx,bend,head,2.0*scale,colors[3],a)
			# This short return rail remains inside the one legal main segment.
			_line(ctx,bend-side*5.0*scale,head-d*7.0*scale,1.5*scale,colors[6],a*0.6)
			_prop(ctx,head,"shuttle",scale*0.65,colors,angle,a)
			if p>0.66:
				for n: int in range(3): _chip(ctx,hit+Vector2((n-1)*5,3+n%2)*scale,Vector2(2,1)*scale,colors[5],a)
		"drill_shell", "heavy_lockshot":
			var heavy := g=="heavy_lockshot"
			var tool_scale := scale*(1.05 if heavy else 0.85)
			_prop(ctx,hand-d*punch*(7.0 if heavy else 4.0)*scale,"gun",tool_scale,colors,angle,a)
			if heavy:
				for s: int in [-1,1]: _chip(ctx,hand+side*s*(5.0-2.0*release)*scale,Vector2(3,1)*scale,colors[6],a)
			_prop(ctx,head,"shell",scale*(0.85 if heavy else 0.55),colors,angle,a)
			if p>0.2 and p<0.48: _chip(ctx,hand+d*11.0*scale,Vector2(4 if heavy else 3,2)*scale,colors[4],a)
			if p>0.63:
				for s: int in [-1,1]: _prop(ctx,hit+side*s*5.0*release*scale,"plate",scale*(0.5 if heavy else 0.3),colors,angle+s*release,a)
			_chip(ctx,hand+side*(5.0+7.0*release)*scale,Vector2(1.5,2.5)*scale,colors[6],a)
		"ratchet_spool":
			# Cast-start only. Real buff persistence belongs to the shared owner.
			for n: int in range(3):
				var q := clampf(release*1.6-float(n)*0.23,0.0,1.0)
				_prop(ctx,hand+Vector2(-8+n*6,-4-q*5)*scale,"plate",scale*(0.32+n*0.08),colors,q*(1.0+n*0.2),a)
			_steam(ctx,hand+Vector2(-8,4)*scale,p,scale,colors,a,2)
		"resin_drip":
			_prop(ctx,hand+Vector2(-4,-3)*scale,"nozzle",scale*0.75,colors,0.4,a)
			for n: int in range(3):
				var q := clampf(release*1.5-float(n)*0.2,0.0,1.0)
				_chip(ctx,hand+Vector2(4+n*2,-8+14*q)*scale,Vector2(1.5,2.5)*scale,colors[2 if n%2==0 else 4],a)
			_prop(ctx,hand+Vector2(6,6)*scale,"plate",scale*0.45,colors,0,a)
			_steam(ctx,hand+Vector2(4,4)*scale,p,scale*0.6,colors,a*0.65,2)
		"offset_dock":
			for s: int in [-1,1]:
				var height := (5.0 if s<0 else 9.0)*punch
				_line(ctx,hand+Vector2(s*9,9)*scale,hand+Vector2(s*9,-height)*scale,3.0*scale,colors[6],a)
				_chip(ctx,hand+Vector2(s*9,-height)*scale,Vector2(5,1.5)*scale,colors[2],a)
			_prop(ctx,hand+Vector2(0,2-5*punch)*scale,"plate",scale*0.8,colors,0,a)
			for n: int in range(3): _chip(ctx,hand+Vector2(-4+n*4,-5+release*9)*scale,Vector2(1,2)*scale,colors[4],a)
			_steam(ctx,hand+Vector2(0,-4)*scale,p,scale,colors,a*0.65,2)
		"right_angle_cut":
			for s: int in [-1,1]: _prop(ctx,hand+Vector2(s*5,-2)*scale,"flag",scale*0.55,colors,s*(0.7-punch),a)
			var corner := Vector2(head.x,hand.y)
			_line(ctx,hand,corner,2.0*scale,colors[6],a)
			_line(ctx,corner,head,2.0*scale,colors[3],a)
			for s: int in [-1,1]: _chip(ctx,hit+side*s*(6.0-3.0*release)*scale,Vector2(2,4)*scale,colors[2 if s<0 else 6],a)
		"opposed_shutters":
			for s: int in [-1,1]:
				_prop(ctx,hand+Vector2(s*7,-2)*scale,"flag",scale*0.6,colors,s*(0.6+punch*0.5),a)
				var at := hit+Vector2(s*(15.0-9.0*release),s*4)*scale
				# Local control plates do not mark an invented AoE boundary.
				_prop(ctx,at,"plate",scale*0.95,colors,s*0.16,a)
				_chip(ctx,at,Vector2(3,1)*scale,colors[6],a)
			if p>0.5: _chip(ctx,hit,Vector2(1,5)*scale,colors[0],a)
		"planted_braces", "insulated_tabs", "flag_confirm":
			pass # Passive records are inspectable; no false active cast.
	ctx.draw_limit = old_limit

static func _prop(ctx: Dictionary, at: Vector2, shape: String, scale: float, colors: Array, angle: float, alpha: float) -> void:
	Brush.poly(ctx,at,TOOL_SHAPES[shape],scale,Color(str(colors[0]),alpha),angle)
	Brush.poly(ctx,at+Vector2(-0.6,-0.6)*scale,TOOL_SHAPES[shape],scale*0.67,Color(str(colors[2]),alpha),angle)

static func _chip(ctx: Dictionary, at: Vector2, size: Vector2, color: String, alpha: float) -> void:
	Brush.chip(ctx,at,size,Color(color,alpha))

static func _line(ctx: Dictionary, from: Vector2, to: Vector2, width: float, color: String, alpha: float) -> void:
	Brush.streak(ctx,from,to,width,Color(color,alpha))

static func _steam(ctx: Dictionary, at: Vector2, phase: float, scale: float, colors: Array, alpha: float, pieces: int) -> void:
	for n: int in range(pieces):
		var q := clampf(phase*1.4-float(n)*0.18,0.0,1.0)
		_chip(ctx,at+Vector2(-n*3.0-2.0*q,-3.0-11.0*q)*scale,Vector2(2.0+q,1.5)*scale,colors[5],alpha*(1.0-q)*0.75)
