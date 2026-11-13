extends RefCounted
## Borrowed roots, failed specimens, migrant feathers, saltwater and hollow thorn.
## Observation-only: no clocks, RNG, caches, target queries or combat writes.
const Brush = preload("res://src/presentation/m63_av_brush.gd")
const VERSION := "m63-forest-av-v1"
const PALETTES := {
	"hive":["172019","55452e","ad9060","80b7a5","fff0c4","cb8f89","a6ac7c"],
	"root":["211d19","70513d","bb8862","8dc8bd","fff2ca","b89ac5","b2bb7d"],
	"seed":["211c29","594568","ab8ac3","dfb367","fff4d6","7fc4ae","a4b29a"],
	"leaf":["251c22","784557","d68b9e","7dbfb5","fff0c5","d3b36e","a6b48a"],
	"feather":["172128","3e5b6f","87bbcf","dc9c97","fff3cf","b6c77c","afa0c6"],
	"molt":["222218","69653b","c7cb74","ac96d3","fff6d2","7fc2b3","cb9b7f"],
	"water":["1d2227","496772","89bfcb","dfa6bd","fff4d5","b8a1d1","b9af87"],
	"salt":["211c24","76536c","d5a0b8","80c7b4","fff3d5","d5bb6c","adbea0"],
	"terrace":["1d231d","646a46","becf87","b59bd0","fff7d9","d59198","8fb9c4"],
	"thorn":["211b22","6b3d52","b97691","9cc795","fff2cd","8db9ce","beaa7b"],
	"garden":["152420","35675d","79b6a4","d68ead","fff2d1","c5b777","a2a8d1"],
	"bark":["1b231c","50553a","9ca56e","8cb4a5","eee7bc","bc9988","9e8e68"],
}
const SHAPES := {
	"hive":[Vector2(-6,-4),Vector2(3,-5),Vector2(7,-1),Vector2(6,5),Vector2(-3,6),Vector2(-6,2)],
	"root":[Vector2(-7,6),Vector2(-6,-1),Vector2(-3,-5),Vector2(0,-3),Vector2(1,-7),Vector2(5,-6),Vector2(4,0),Vector2(8,4),Vector2(5,7),Vector2(1,3),Vector2(-2,2),Vector2(-3,7)],
	"pod":[Vector2(-5,-6),Vector2(3,-6),Vector2(6,-2),Vector2(5,4),Vector2(0,7),Vector2(-4,4),Vector2(-6,0)],
	"leaf":[Vector2(-9,0),Vector2(-3,-5),Vector2(4,-4),Vector2(10,0),Vector2(2,5),Vector2(-4,3)],
	"feather":[Vector2(-10,2),Vector2(-5,-3),Vector2(1,-4),Vector2(8,-2),Vector2(11,0),Vector2(3,2),Vector2(0,5),Vector2(-2,2),Vector2(-7,5)],
	"bow":[Vector2(-3,-11),Vector2(1,-8),Vector2(5,-3),Vector2(6,3),Vector2(2,9),Vector2(-2,11),Vector2(0,5),Vector2(2,1),Vector2(0,-5)],
	"arrow":[Vector2(-13,-1),Vector2(4,-1),Vector2(3,-4),Vector2(11,0),Vector2(3,4),Vector2(4,1),Vector2(-13,1),Vector2(-16,4),Vector2(-14,0),Vector2(-16,-4)],
	"shell":[Vector2(-8,-2),Vector2(-4,-6),Vector2(2,-7),Vector2(7,-3),Vector2(8,2),Vector2(3,6),Vector2(-4,5),Vector2(-7,2)],
	"cup":[Vector2(-8,-4),Vector2(7,-4),Vector2(5,3),Vector2(2,5),Vector2(2,8),Vector2(-2,8),Vector2(-2,5),Vector2(-6,2)],
	"harp":[Vector2(-7,-8),Vector2(-2,-8),Vector2(-3,-2),Vector2(5,3),Vector2(7,-7),Vector2(9,-5),Vector2(8,8),Vector2(2,8),Vector2(-7,1)],
	"thorn":[Vector2(-9,-2),Vector2(-3,-2),Vector2(-4,-6),Vector2(1,-2),Vector2(8,-2),Vector2(10,1),Vector2(3,2),Vector2(4,6),Vector2(-1,2),Vector2(-9,2)],
	"bark":[Vector2(-5,-7),Vector2(2,-6),Vector2(6,-2),Vector2(4,6),Vector2(-1,8),Vector2(-5,4)],
	"pruner":[Vector2(-2,9),Vector2(-2,0),Vector2(-7,-3),Vector2(-6,-7),Vector2(5,-6),Vector2(7,-2),Vector2(2,1),Vector2(2,9)],
}
## label, retained silhouette, palette, small crest, body-local offset,
## real attack/work branch, acoustic recipe, story anchor, counterplay.
const ACTOR_ROWS := {
	"hero:VINE_WARDEN":["枝垒","蜂箱胸格、偏长根臂、悬巢肩","hive",[Vector2(-5,-4),Vector2(3,-4),Vector2(6,-1),Vector2(5,4),Vector2(-3,5),Vector2(-5,1)],Vector2(-5,-19),"hive_knuckle",["scrape",160,.61,2,"falling_weight",.35,1.5,-.26,.07],"借根养蜂人让同行的树保留离开权；重土和轻粉分速。","绕过近身根臂，治疗不提供无敌。"],
	"hero:LEAF_SEER":["芽灯","透叶种匣、双叉嫁接杖、缺口发叶","seed",[Vector2(-5,-3),Vector2(-1,-6),Vector2(2,-2),Vector2(5,-5),Vector2(6,1),Vector2(1,5),Vector2(-4,3)],Vector2(5,-23),"specimen_flick",["bell",770,.12,2,"staggered_reprise",.26,2.8,.19,.12],"失败叶脉是育种记录；种匣保留未入册样本。","贴近脆弱施法者；种匣不暗示召唤单位。"],
	"hero:WIND_COURIER":["风翎","弯候鸟冠、四片不齐尾羽、轻骨长弓","feather",[Vector2(-6,4),Vector2(-4,-1),Vector2(0,-5),Vector2(6,-4),Vector2(2,-1),Vector2(4,2),Vector2(0,1),Vector2(-2,5)],Vector2(-4,-25),"migrant_bow",["pluck",490,.20,1,"sharp_cut",.22,1.6,.35,.03],"先递送难听的霜期实情；季节羽不是分身。","逼近或停火消耗强化窗口。"],
	"hero:BLOOM_GUIDE":["花汐","花形量水盘、盐白长靴、贝杯","water",[Vector2(-6,-1),Vector2(-2,-5),Vector2(2,-5),Vector2(6,-1),Vector2(4,4),Vector2(-3,4)],Vector2(-5,-18),"shell_tilt",["water",590,.16,3,"woven_drift",.34,1.3,.12,.14],"盐沼量水师把林外生命也算入分水图。","切断支援距离；普通攻击水珠不制造治疗。"],
	"hero:THORN_CHANTER":["棘歌","开口棘琴、种壳耳饰、不齐枝袖","thorn",[Vector2(-5,-5),Vector2(-2,-5),Vector2(-3,0),Vector2(2,3),Vector2(4,-4),Vector2(6,-3),Vector2(5,5),Vector2(0,5),Vector2(-5,1)],Vector2(5,-20),"hollow_pluck",["reed",330,.38,3,"staggered_reprise",.31,2.4,-.16,.08],"剪断主弦的采声人把缺一拍的城市杂音留在谱中。","分散并接近；棘琴不造成地形阻挡。"],
	"vine_guard":["藤卫","窄身根叉矛、斜纹树皮护肩","bark",[Vector2(-5,4),Vector2(-4,-4),Vector2(-1,-5),Vector2(0,0),Vector2(3,-4),Vector2(5,-2),Vector2(4,5)],Vector2(4,-21),"fork_spear",["crack",240,.72,1,"directional_rush",.19,1.8,-.24,.02],"架根通路轮值者以双叉撑杆守住撤离口（本轮道具延展）。","利用近战接敌面和护甲克制。"],
	"leaf_archer":["叶弓手","偏窄叶弓、扁种袋、单片背羽","feather",[Vector2(-5,3),Vector2(-3,-4),Vector2(2,-5),Vector2(5,-2),Vector2(1,0),Vector2(3,4),Vector2(-1,2)],Vector2(-5,-22),"split_recurve",["click",620,.43,2,"sharp_cut",.18,3.1,.27,.01],"迁林路标员用扁种袋区分待播种与已发箭（本轮道具延展）。","近身打断安全输出位置；单箭不是散射。"],
	"stag_rider":["鹿骑兵","鹿角坐骑、叶鞍双结、长枝骑矛","root",[Vector2(-6,-4),Vector2(-2,-1),Vector2(0,-5),Vector2(2,-1),Vector2(6,-3),Vector2(5,4),Vector2(1,2),Vector2(-3,4)],Vector2(4,-23),"antler_lance",["breath",200,.31,2,"directional_rush",.30,1.4,-.18,.06],"季候巡路骑手将迁徙绳结留在可解开的鞍扣上（道具延展）。","反骑兵与侧向截击；枝矛不扩大攻击距离。"],
	"root_mender":["根织者","根纺杖、窄肩长袍、侧挂线根轴","water",[Vector2(-5,-3),Vector2(-1,-5),Vector2(3,-3),Vector2(5,1),Vector2(1,4),Vector2(-4,3)],Vector2(5,-19),"root_spindle",["choir",430,.19,2,"inward_return",.36,1.8,.07,.16],"把断根接回水路的纺根匠保留每株树的独立线头（道具延展）。","压制支援者；普攻动作不自行增加治疗。"],
	"elder_treant":["古根灵卫","大型树卫、分层根肩、厚杖承重","hive",[Vector2(-7,4),Vector2(-6,-1),Vector2(-3,-1),Vector2(-3,-5),Vector2(0,-3),Vector2(3,-6),Vector2(6,-2),Vector2(7,4),Vector2(2,3),Vector2(-2,5)],Vector2(-4,-22),"trunk_crook",["rumble",85,.66,2,"falling_weight",.40,2.1,-.43,.18],"灵髓古根以分杈肩担承重，真实庇护治疗由支援权威驱动。","转线和奥术压力；重击不产生额外范围受击。"],
	"worker:FOREST":["织叶工人","折叶帽、分种腰匣、短剪枝锄","bark",[Vector2(-5,-2),Vector2(0,-4),Vector2(5,-1),Vector2(2,1),Vector2(4,3),Vector2(-4,3)],Vector2(-4,-14),"wedge_prune",["clang",380,.49,2,"staggered_reprise",.17,1.3,-.30,.01],"迁林工把种子分匣携带，先问根要留在哪里（道具延展）。","260生命工人仍脆弱；工作动作不赋予军事技能。"],
}
## owner, canonical label, real branch, palette, sound, story, counterplay,
## four phases, passive, observed authority guard.
const SKILL_ROWS := {
	"VINE_SHOCK":["VINE_WARDEN","根心复苏","borrowed_root_knit","hive",["buzz",175,.46,3,"inward_return",.68,1.5,-.24,.07],"借来的根回到蜂箱胸格；不召唤蜂群。","恢复后仍可受伤；条件治疗收益窗口由真实来源管理。",["手边蜂蜡格打开","两根厚根向自身内折","胸侧根格扣合表示一次HEAL","重泥先落、轻粉后散；不伪造持续治疗"],false,"HEAL SELF＋净化DoT；无敌方伤害/眩晕。"],
	"VINE_WARD":["VINE_WARDEN","老树皮","consenting_bark","bark",["rumble",110,.22,2,"breathing_lift",.34,1.4,0,.03],"愿意留下的树皮保留可松开的长缝。","移动/扎根治疗窗口结束会失去条件支援；来源以权威为准。",["被动无主动预示","无投射物","护甲及扎根窗口条件支援读真实来源","死亡/条件失效即由原状态撤去"],true,"PASSIVE_GUARD；条件 healing_received_percent 光环，不生成cast。"],
	"VINE_MEND":["VINE_WARDEN","古根囚牢","hive_root_jaws","root",["scrape",125,.74,4,"gather_and_lock",1.56,1.7,-.43,.17],"蜂箱搭桥的粗根先留缺口，再在合法落点低位扣合。","ROOT仍可普攻和施法；离开实际选点区。",["根臂低压、蜂蜡小格作预示","局部根节由低向高交错生长","主落点脚边根爪合拢；零伤ROOT","根爪下沉、蜂蜡屑退去；持续读真实状态"],false,"AREA 零伤ROOT大招；不画头顶眩晕、伤害爆心或新目标。"],
	"LEAF_BIND":["LEAF_SEER","织根缚","graft_seed_latch","seed",["click",720,.29,3,"gather_and_lock",.61,2.8,-.21,.03],"未入册种匣先检视再开壳；失控的根须需要夹住。","范围伤害＋ROOT；分散并接近施法者，定身仍能还击。",["种匣在手边翻壳","单枚种核短弧落向合法中心","种壳开成低位双根扣；真实伤害＋ROOT","空壳两片下落，根扣不自计时"],false,"AREA 混合伤害ROOT，最多四目标；附加命中仍由权威。"],
	"LEAF_FLARE":["LEAF_SEER","叶辉","sample_leaf_shear","leaf",["scrape",550,.40,4,"opening_fan",.72,2.2,.26,.08],"失败样本的宽窄叶脉组成剪枝扇，不让生长无限扩张。","离开真实扇面；SLOW不禁止普攻或施法。",["手中双叉叶刃错开","三片宽窄不同叶片沿中心主段扇展","中心短叶切；额外受击交真实连接器","叶背回翻、脉络细片落下；减速读真实状态"],false,"CONE 伤害＋SLOW；无STUN、无地面持续伤害。"],
	"LEAF_OATH":["LEAF_SEER","古根囚印","specimen_press","seed",["bell",480,.18,4,"gather_and_lock",1.66,3.2,-.18,.20],"把标本压叶夹做成可辨的双侧根钳，只夹一个真实目标。","单体零伤ROOT可被掩护；被定身者仍能还击。",["手边标本叶合页竖起","一片薄种签送往唯一中心","两片压叶板低位相向合拢","种签回折，碎壳整齐下落；无伤害炸裂"],false,"SINGLE 零伤ROOT大招；不是旧群体盟誓。"],
	"WIND_SHOT":["WIND_COURIER","风弦","season_feather_lance","feather",["crack",510,.27,2,"directional_rush",.52,1.9,.42,.04],"难听的季候实情像一根有实体羽轴的箭先抵达。","保护单个被瞄准者；没有溅射或额外穿透。",["轻骨弓后拉、季羽翘起","一根带不齐尾羽的长箭直行","唯一目标羽轴前折并短切","两片断尾羽逆行回飘"],false,"SINGLE PIERCE纯伤；仅唯一合法中心。"],
	"WIND_FERVOR":["WIND_COURIER","疾叶","molt_double_fold","molt",["pluck",395,.16,4,"staggered_reprise",.70,1.6,.25,.07],"换羽先后不同步，有限的赶路窗口留在自身肩后。","撤离攻击距离、控制或停火消耗强化时长。",["肩后两片淡金羽缘错开","自身两侧叶羽向后折展","只有自身两次轻回弹","尾羽回卷；buff存在/到期由真实来源"],false,"SELF DAMAGE_BUFF＋攻速/移速；无敌方受击。"],
	"WIND_MEND":["WIND_COURIER","逐风猎阵","migration_wing_pages","feather",["breath",270,.35,7,"breathing_lift",1.74,1.8,.35,.23],"向风断旗变成三层翼页；携季者把消息收成一条尾迹。","SELF爆发窗口可被控制/撤离消耗，无范围增益。",["自身弓口收拢、断旗尾羽竖起","三层大小不同翼页向自身后侧展开","翼页停拍并收为单尾；不画目标命中","薄页由远到近收束；强化独立到期"],false,"SELF DAMAGE_BUFF大招；不是治疗、群体增益或传送。"],
	"BLOOM_SPRING":["BLOOM_GUIDE","花泉光环","quiet_water_gauge","water",["water",460,.10,2,"woven_drift",.36,1.3,.04,.10],"花形水尺把盐沼水位记录成低亮刻线。","离开真实光环或压制来源；不会回复MP。",["被动无施放","无投射物","真实光环回血由来源读取","离场/死亡即失效，无主动花杯"],true,"AURA 生命恢复被动；无MP恢复、cast或临时护盾。"],
	"BLOOM_TOUCH":["BLOOM_GUIDE","新芽抚触","salt_rinse_cup","salt",["water",655,.21,3,"inward_return",.75,1.4,.17,.16],"贝杯倾倒后水滴上升、盐粒落下，分清排盐与分水。","切断支援范围；不复活，也不留下护甲罩。",["自身贝杯倾斜","三枚不等高水滴向自身回流","自身水尺合位；友军治疗走真实连接器","盐粒先落、水线后收，净化只读结算"],false,"HEAL SELF＋最多五友军/净化DoT；无额外治疗目标。"],
	"BLOOM_SANCTUARY":["BLOOM_GUIDE","长春庇护","saltmarsh_terraces","terrace",["choir",375,.24,6,"breathing_lift",1.92,2.0,.12,.27],"撕席签后的分水图展开错层水台，留出林外生命的通路。","治疗与净化非无敌/复活；切断支援群体。",["自身量水盘打开","三层不等高短水槽错拍展开","水珠上提、贝片内合；受益者由真实HEAL连接器","水台逐层压低，盐粒先散；无持久治疗区"],false,"HEAL SELF＋最多六友军/净化DoT大招；无护盾。"],
	"THORN_BREEZE":["THORN_CHANTER","林风光环","unmatched_reed_score","garden",["reed",305,.17,3,"woven_drift",.34,1.8,-.06,.05],"开口棘琴永远留下一拍不属于自己的声音。","离开真实移速光环；不是攻速/回蓝。",["被动无主动预示","无投射物","真实移速受益读取来源","离场/死亡即撤去，无棘墙"],true,"AURA 百分比移速被动，不生成cast。"],
	"THORN_LASH":["THORN_CHANTER","缠枝","score_whip_unroll","thorn",["pluck",285,.44,3,"sharp_cut",.66,2.5,-.32,.05],"缺拍长谱翻成三节倒刺鞭，归还时仍留断音。","避开真实直线带；ROOT可还击，附加目标归原连接器。",["开口琴后拉，短谱横置","三节棘鞭沿唯一主段依次展开","合法中心低位小根扣；伤害＋ROOT","鞭节反折回手中，无实体藤墙"],false,"LINE 混合伤害ROOT，最多四目标；不查找邻兵。"],
	"THORN_MAZE":["THORN_CHANTER","荆棘迷庭","negative_garden_score","garden",["reed",225,.52,7,"staggered_reprise",1.84,2.7,-.29,.19],"城市杂音印成空园断谱，空白通路比闭合围墙更重要。","离开真实选点区域；零伤ROOT仍能攻击施法。",["手边棘琴压低并停一拍","主中心三条断谱错层上翻","低位钩扣相向折合；零伤定身","断谱向地压平，碎种壳下沉；无障碍物"],false,"AREA 零伤ROOT大招；不画爆心、头晕或封闭地形。"],
}

static func _sound(r: Array) -> Dictionary:
	return {"voice":r[0],"frequency":r[1],"texture":r[2],"pulses":r[3],"rhythm":r[4],"seconds":r[5],"overtone":r[6],"sweep":r[7],"echo":r[8]}

static func actors() -> Dictionary:
	var result := {}
	for id: String in ACTOR_ROWS: result[id] = actor_profile(id)
	return result.duplicate(true)

static func skills() -> Dictionary:
	var result := {}
	for id: String in SKILL_ROWS: result[id] = skill_profile(id)
	return result.duplicate(true)

static func actor_profile(identity: String) -> Dictionary:
	if not ACTOR_ROWS.has(identity): return {}
	var r: Array = ACTOR_ROWS[identity]
	return {"identity":identity,"faction_id":"FOREST","name":r[0],"silhouette":r[1],"palette":PALETTES[str(r[2])].duplicate(true),"crest":r[3].duplicate(true),"crest_offset":r[4],"gesture":r[5],"sound":_sound(r[6]),"story_anchor":r[7],"counterplay":r[8],"body_change":"preserved_body_small_equipment_crest","identity_version":VERSION}.duplicate(true)

static func skill_profile(skill_id: String) -> Dictionary:
	if not SKILL_ROWS.has(skill_id): return {}
	var r: Array = SKILL_ROWS[skill_id]
	return {"skill_id":skill_id,"hero_id":r[0],"faction_id":"FOREST","name":r[1],"gesture":r[2],"palette":PALETTES[str(r[3])].duplicate(true),"sound":_sound(r[4]),"story_anchor":r[5],"counterplay":r[6],"phases":r[7].duplicate(true),"passive":r[8],"authority_guard":r[9],"identity_version":VERSION}.duplicate(true)

static func _prop(ctx: Dictionary, at: Vector2, shape: String, s: float, p: Array, angle: float, a: float) -> void:
	Brush.stamp(ctx,at,SHAPES[shape],s,p,angle,a)

static func _line(ctx: Dictionary, from: Vector2, to: Vector2, width: float, p: Array, a: float, slot: int = 3) -> void:
	Brush.streak(ctx,from,to,width+2,Color(str(p[0]),a))
	Brush.streak(ctx,from,to,width,Color(str(p[slot]),a))

static func _grain(ctx: Dictionary, at: Vector2, size: Vector2, p: Array, a: float, slot: int = 4) -> void:
	Brush.chip(ctx,at,size+Vector2.ONE,Color(str(p[0]),a))
	Brush.chip(ctx,at,size,Color(str(p[slot]),a))

static func _bow(ctx: Dictionary, hand: Vector2, d: Vector2, s: float, q: float, p: Array, a: float, size: float = 1.0) -> void:
	var n := d.orthogonal()
	_prop(ctx,hand,"bow",s*size,p,d.angle(),a)
	var notch := hand-d*(3+7*(1-q))*s*size
	_line(ctx,hand-n*9*s*size,notch,s,p,a,6)
	_line(ctx,notch,hand+n*9*s*size,s,p,a,6)

static func draw_signature(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, spec: Dictionary) -> void:
	var t := float(ctx.get("phase",-1))
	if not is_finite(t) or t<=0 or t>=1 or not origin.is_finite() or not center.is_finite() or not is_finite(scale) or scale<=0: return
	if bool(spec.get("passive",false)) or str(spec.get("effect","")) in ["AURA","PASSIVE_GUARD"]: return
	var p: Array = spec.get("palette",[])
	if p.size()!=7: return
	var limit := int(ctx.get("draw_limit",0))
	ctx.draw_limit = mini(limit,int(ctx.get("count",0))+(36 if bool(spec.get("is_skill",false)) else 24))
	var d := (center-origin).normalized()
	if d.length_squared()<.1: d=Vector2.RIGHT
	var q := clampf((t-.20)/.44,0,1)
	var a := clampf(sin(t*PI)*1.5,0,1)
	# origin already is the actual elevated hand anchor. Never raise it again.
	if bool(spec.get("is_skill",false)):
		_draw_skill(ctx,origin,center,d,d.orthogonal(),scale,t,q,a,p,str(spec.get("gesture","")))
	else:
		_draw_actor(ctx,origin,center,d,d.orthogonal(),scale,t,q,a,p,str(spec.get("gesture","")))
	ctx.draw_limit=limit

static func _draw_actor(ctx: Dictionary, o: Vector2, c: Vector2, d: Vector2, n: Vector2, s: float, t: float, q: float, a: float, p: Array, g: String) -> void:
	var swing := sin(q*PI)
	match g:
		"hive_knuckle":
			_prop(ctx,o+d*(4+13*swing)*s,"root",s,p,d.angle()-.5+.7*q,a)
			_prop(ctx,o-n*5*s,"hive",s*.55,p,-.2,a)
			if t>.62: _grain(ctx,o+d*20*s+Vector2(0,8*q)*s,Vector2(2,1)*s,p,a,2)
		"specimen_flick":
			_prop(ctx,o,"pod",s*.65,p,-.5+q,a)
			if t>.22: _prop(ctx,o.lerp(c,q)+n*sin(q*PI)*7*s,"leaf",s*.55,p,d.angle()+q*.4,a)
		"migrant_bow":
			_bow(ctx,o,d,s,q,p,a)
			if t>.24: _prop(ctx,o.lerp(c,q),"arrow",s*.65,p,d.angle(),a)
		"shell_tilt":
			_prop(ctx,o,"cup",s*.7,p,-.5+q*.8,a)
			if t>.23: _grain(ctx,o.lerp(c,q)+Vector2(0,-sin(q*PI)*10)*s,Vector2(2,3)*s,p,a,3)
		"hollow_pluck":
			_prop(ctx,o,"harp",s*.75,p,-.2+swing*.2,a)
			if t>.26: _prop(ctx,o.lerp(c,q),"thorn",s*.50,p,d.angle(),a)
		"fork_spear":
			_line(ctx,o-d*7*s,o+d*(12+16*swing)*s,2*s,p,a,2)
			_prop(ctx,o+d*(12+16*swing)*s,"root",s*.6,p,d.angle()-PI*.5,a)
		"split_recurve":
			_bow(ctx,o,d,s,q,p,a,.70)
			if t>.30: _prop(ctx,o.lerp(c,q),"arrow",s*.45,p,d.angle(),a)
		"antler_lance":
			_line(ctx,o-d*8*s,o+d*(17+19*swing)*s,2.5*s,p,a,2)
			_prop(ctx,o+d*(18+19*swing)*s,"leaf",s*.65,p,d.angle(),a)
			_prop(ctx,o-d*5*s+n*5*s,"feather",s*.45,p,d.angle()+.5,a)
		"root_spindle":
			_prop(ctx,o,"root",s*.65,p,-.4+q*.5,a)
			if t>.25:
				var head := o.lerp(c,q)
				_line(ctx,head-d*7*s,head,1.5*s,p,a,6)
				_prop(ctx,head,"pod",s*.42,p,q,a)
		"trunk_crook":
			_prop(ctx,o+d*12*s+Vector2(0,-17*(1-q))*s,"root",s*1.25,p,-.4+q*.5,a)
			_line(ctx,o,o+d*12*s+Vector2(0,-17*(1-q))*s,4*s,p,a,2)
			if t>.60: _prop(ctx,o+d*18*s+Vector2(0,8*q)*s,"bark",s*.45,p,q,a)
		"wedge_prune":
			_prop(ctx,o+d*7*s,"pruner",s*.75,p,-.9+1.4*q,a)
			if t>.55: _prop(ctx,o+d*12*s+n*(3+5*q)*s,"leaf",s*.3,p,q,a)

static func _draw_skill(ctx: Dictionary, o: Vector2, c: Vector2, d: Vector2, n: Vector2, s: float, t: float, q: float, a: float, p: Array, g: String) -> void:
	var head := o.lerp(c,q)
	var tail := clampf((t-.72)/.28,0,1)
	match g:
		"borrowed_root_knit":
			_prop(ctx,o,"hive",s*.85,p,0,a)
			for sign: int in [-1,1]:
				_prop(ctx,o+Vector2(sign*(15-10*q),6-5*q)*s,"root",s*.8,p,sign*(.8-.6*q),a)
			if t>.56: _grain(ctx,o+Vector2(0,2)*s,Vector2(2,3)*s,p,a,3)
			if t>.72: _grain(ctx,o+Vector2(-9,5+9*tail)*s,Vector2(2,1)*s,p,a*.7,2)
		"hive_root_jaws":
			_prop(ctx,o-d*(3+4*q)*s,"hive",s*.8,p,-.3,a)
			if t>.20:
				for i: int in range(3):
					var u := clampf((t-.20-float(i)*.10)/.36,0,1)
					var at := c+Vector2((i-1)*(17-7*u),12-17*u+tail*12)*s
					_prop(ctx,at,"root",s*(.5+.6*u),p,(i-1)*(.8-.4*u),a)
			if t>.63: _grain(ctx,c+Vector2(-14,8+10*tail)*s,Vector2(1,2)*s,p,a*.65,5)
		"graft_seed_latch":
			_prop(ctx,o,"pod",s*.75,p,-.5+q*.7,a)
			if t>.20 and t<.64: _prop(ctx,head+Vector2(0,-sin(q*PI)*17)*s,"pod",s*.55,p,q*.9,a)
			if t>.54:
				for sign: int in [-1,1]: _prop(ctx,c+Vector2(sign*(13-8*q),6+tail*8)*s,"root",s*.8,p,sign*(.7-.4*q),a)
			if t>.72: _prop(ctx,c+Vector2(8*tail,-4+13*tail)*s,"pod",s*.3,p,tail,a*.6)
		"sample_leaf_shear":
			for sign: int in [-1,1]: _prop(ctx,o+n*sign*(3+2*q)*s,"leaf",s*.6,p,d.angle()+sign*(.6-.3*q),a)
			if t>.20:
				for i: int in range(3):
					var lane := float(i)-1
					_prop(ctx,head+n*lane*(4+11*q)*s-d*tail*7*s,"leaf",s*(.65+float(i%2)*.20),p,d.angle()+lane*(.16+.36*q)-tail*.5,a)
			if t>.58 and t<.78: _line(ctx,c-d*6*s,c+d*6*s,1.5*s,p,a,4)
		"specimen_press":
			_prop(ctx,o,"leaf",s*.85,p,PI*.5-q*.3,a)
			if t>.20 and t<.64: _prop(ctx,head,"pod",s*.5,p,d.angle(),a)
			if t>.38:
				for sign: int in [-1,1]:
					_prop(ctx,c+Vector2(sign*(19-13*q+tail*4),4+tail*8)*s,"bark",s*1.15,p,sign*(.25-.2*q),a)
			if t>.60: _prop(ctx,c+Vector2(0,7)*s,"leaf",s*.65,p,0,a)
		"season_feather_lance":
			_bow(ctx,o,d,s,q,p,a,1.15)
			_prop(ctx,o-d*5*s-n*7*s,"feather",s*.6,p,d.angle()-.5+q*.7,a)
			if t>.20 and t<.81: _prop(ctx,head,"arrow",s*.95,p,d.angle(),a)
			if t>.58 and t<.79: _line(ctx,c-d*9*s,c+d*5*s,2*s,p,a,4)
			if t>.72:
				for sign: int in [-1,1]: _prop(ctx,c-d*(5+11*tail)*s+n*sign*(3+4*tail)*s,"feather",s*.35,p,d.angle()+sign*tail,a*.7)
		"molt_double_fold":
			_bow(ctx,o,d,s,q,p,a,.85)
			for sign: int in [-1,1]:
				var u := clampf((t-.16-(.12 if sign==1 else 0.0))/.42,0,1)
				var at := o+Vector2(sign*(7+13*sin(u*PI)),-4-5*sin(u*PI))*s
				_prop(ctx,at,"feather",s*(.7 if sign<0 else 1.0),p,sign*(.1+u*.7),a)
			if t>.72: _prop(ctx,o+Vector2(-7-6*tail,3+6*tail)*s,"feather",s*.35,p,-tail,a*.65)
		"migration_wing_pages":
			_prop(ctx,o,"bow",s*.9,p,d.angle()-.2+q*.3,a)
			for i: int in range(3):
				var u := clampf((t-.15-float(i)*.10)/.40,0,1)
				var reach := sin(u*PI*.70)*(1-tail*.85)
				var at := o+Vector2(-8-float(i)*8*reach,-10-float(i)*7*reach)*s
				_prop(ctx,at,"feather",s*(1.3-float(i)*.25),p,-.35-float(i)*.25+u*.6,a)
			if t>.58: _line(ctx,o+Vector2(-8,-4)*s,o+Vector2(-23+tail*14,-3)*s,2*s,p,a,3)
		"salt_rinse_cup":
			_prop(ctx,o+Vector2(-4,-2)*s,"cup",s*.85,p,-.35+q*.9,a)
			for i: int in range(3):
				var u := clampf((t-.23-float(i)*.08)/.42,0,1)
				_grain(ctx,o+Vector2(-7+float(i)*7,12-18*u+tail*3)*s,Vector2(1.5,2.5)*s,p,a,3)
			if t>.56: _line(ctx,o+Vector2(-7,4)*s,o+Vector2(7,4)*s,1.5*s,p,a,4)
			if t>.72: _grain(ctx,o+Vector2(9,4+12*tail)*s,Vector2(1,1)*s,p,a,6)
		"saltmarsh_terraces":
			_prop(ctx,o,"shell",s*.9,p,-.25+q*.4,a)
			for i: int in range(3):
				var u := clampf((t-.18-float(i)*.10)/.40,0,1)
				var level := float(i)*5*(1-tail)
				var left := o+Vector2(-17+float(i)*4,-level+8)*s
				_line(ctx,left,left+Vector2((17-float(i)*2)*u,0)*s,3*s,p,a,3)
				_prop(ctx,left+Vector2((17-float(i)*2)*u,-3-4*u)*s,"shell",s*(.50-float(i)*.08),p,-.2+u*.5,a)
			if t>.62: _grain(ctx,o+Vector2(10,5-13*q+12*tail)*s,Vector2(2,3)*s,p,a,4)
		"score_whip_unroll":
			_prop(ctx,o,"harp",s*.8,p,-.3+q*.4,a)
			if t>.20:
				var end := o.lerp(c,q*(1-tail*.82))
				_line(ctx,o,end,2*s,p,a,2)
				for i: int in range(3):
					var pos := o.lerp(end,(float(i)+1)/3.0)
					_prop(ctx,pos,"thorn",s*(.55+float(i)*.09),p,d.angle(),a)
			if t>.60 and t<.82: _prop(ctx,c+Vector2(0,6)*s,"root",s*.5,p,0,a)
		"negative_garden_score":
			_prop(ctx,o,"harp",s*.8,p,-.2-q*.3,a)
			if t>.21:
				for i: int in range(3):
					var u := clampf((t-.21-float(i)*.11)/.35,0,1)
					var at := c+Vector2(-15+float(i)*13,9-9*u+tail*11+float(i%2)*4)*s
					_prop(ctx,at,"thorn",s*(.7+u*.25),p,(float(i)-1)*.24,a)
					if t>.45+float(i)*.07: _prop(ctx,at+Vector2(3,-5*u)*s,"root",s*.48,p,(float(i)-1)*.5,a)
			if t>.74: _grain(ctx,c+Vector2(-7,4+13*tail)*s,Vector2(1,2)*s,p,a*.6,6)
## consenting_bark / quiet_water_gauge / unmatched_reed_score are intentionally
## records only. Real passive/aura source, death and expiry stay upstream.
