extends RefCounted
## Snow-dam masonry, kiln glass, trial steel, shared ovens, grounding ropes.
## Stateless presentation; existing runtime bodies and combat rules retained.
const Brush = preload("res://src/presentation/m63_av_brush.gd")
const VERSION := "m63-highland-av-v1"
## ink / shadow / body / contrast / core / afterglow / metal
const PALETTES := {
	"dam":["181d24","405363","87a5b5","d28d64","fff0bc","b3a0c4","b7b293"],
	"strata":["1c1e28","575e77","91accd","b69acb","fff1c6","d5a171","8fb6b1"],
	"kiln":["211b25","684a70","b18ac4","8fc8b1","fff1c8","d4b56f","9eacbd"],
	"glaze":["241b1d","75453d","cc845b","80b5be","fff0b9","b39dbb","b9ad94"],
	"pour":["18202a","435876","88a6cc","ddb365","fff5cb","c693b5","9ebdab"],
	"steel":["211d22","68523d","c3a56b","8eadd0","fff1c5","c88e91","a9b9ac"],
	"wake":["251c24","754958","c98c9a","7ebdb8","fff0c7","c5ab73","a7a6c1"],
	"verdict":["211c20","784b39","d49b61","9bb9ce","fff3c8","b79ec6","bfb090"],
	"oven":["211c1b","6d5142","c4976c","90b9c5","fff0bf","b68fa9","b2bc9b"],
	"refuge":["241c24","704f67","c692a0","8fbbae","fff0c6","b49dcd","bca77f"],
	"rope":["191f29","435777","8ca8cd","d2a56c","fff2c6","b58ec5","96b6aa"],
	"flag":["211b29","604f7b","b09bce","dab16e","fff5d4","81b7c5","a9b58f"],
	"guard":["1b2025","4a5d66","92aab0","c88f6d","fff0c3","b2a1b9","b6b89a"],
	"sling":["201d25","635548","b8a079","88b4c3","fff0c9","c09aaa","a5b6ae"],
	"dragon":["221c21","68423b","bb7150","80aaa3","ffeab3","b692b8","b8ad8b"],
	"keeper":["1e2225","4c6263","96b9ad","c4a17a","fff1cf","b99ac0","aab6c5"],
	"behemoth":["191e24","405362","839ba8","c0a373","fff0ba","aaa1c4","b3bbaa"],
	"worker":["211f1d","655745","b79e70","8ba9ad","f1dfb3","b39791","adb5a0"],
}
const SHAPES := {
	"hammer":[Vector2(-8,-5),Vector2(2,-7),Vector2(8,-3),Vector2(6,3),Vector2(1,3),Vector2(1,9),Vector2(-2,9),Vector2(-2,2),Vector2(-8,1)],
	"slab":[Vector2(-8,1),Vector2(-6,-4),Vector2(3,-5),Vector2(8,-1),Vector2(6,4),Vector2(-5,5)],
	"rivet":[Vector2(-4,-4),Vector2(3,-4),Vector2(5,-1),Vector2(2,4),Vector2(-3,3)],
	"gauge":[Vector2(-7,-5),Vector2(-2,-5),Vector2(-2,-1),Vector2(7,-1),Vector2(7,3),Vector2(-7,3)],
	"glass":[Vector2(-7,0),Vector2(-2,-5),Vector2(5,-3),Vector2(7,2),Vector2(1,6),Vector2(-4,4)],
	"glaze":[Vector2(-5,-3),Vector2(-1,-7),Vector2(4,-3),Vector2(6,2),Vector2(2,5),Vector2(-4,3)],
	"slag":[Vector2(-8,-2),Vector2(-3,-6),Vector2(5,-4),Vector2(8,1),Vector2(4,6),Vector2(-5,4)],
	"blade":[Vector2(-12,2),Vector2(-7,-2),Vector2(7,-3),Vector2(14,-1),Vector2(8,2),Vector2(-3,3),Vector2(-7,5)],
	"clamp":[Vector2(-7,-5),Vector2(3,-5),Vector2(7,-1),Vector2(7,2),Vector2(2,2),Vector2(2,-1),Vector2(-3,-1),Vector2(-3,5),Vector2(-7,5)],
	"loaf":[Vector2(-7,3),Vector2(-7,-1),Vector2(-4,-5),Vector2(3,-5),Vector2(7,-1),Vector2(7,4)],
	"peel":[Vector2(-8,-3),Vector2(3,-3),Vector2(6,0),Vector2(3,3),Vector2(-8,3),Vector2(-8,1),Vector2(-14,1),Vector2(-14,-1),Vector2(-8,-1)],
	"smoke":[Vector2(-7,3),Vector2(-6,-2),Vector2(-2,-2),Vector2(-2,-6),Vector2(3,-6),Vector2(3,-2),Vector2(7,-2),Vector2(6,3),Vector2(2,5),Vector2(-4,5)],
	"shelter":[Vector2(-10,4),Vector2(-10,-1),Vector2(-4,-6),Vector2(4,-6),Vector2(10,-1),Vector2(10,4),Vector2(6,4),Vector2(5,0),Vector2(-5,0),Vector2(-6,4)],
	"flag":[Vector2(-7,-6),Vector2(7,-5),Vector2(3,-1),Vector2(7,3),Vector2(-5,4),Vector2(-7,1)],
	"fork":[Vector2(-6,-6),Vector2(-3,-6),Vector2(-3,-2),Vector2(-1,-2),Vector2(-1,-8),Vector2(2,-8),Vector2(2,-2),Vector2(5,-2),Vector2(5,-5),Vector2(7,-5),Vector2(7,2),Vector2(-6,2)],
	"sling":[Vector2(-6,-2),Vector2(-2,-5),Vector2(4,-4),Vector2(7,-1),Vector2(4,3),Vector2(-3,4)],
	"tooth":[Vector2(-8,2),Vector2(-2,-5),Vector2(1,-2),Vector2(6,-5),Vector2(9,2),Vector2(2,5)],
	"ram":[Vector2(-9,5),Vector2(-9,-1),Vector2(-5,-1),Vector2(-5,-6),Vector2(5,-6),Vector2(5,-1),Vector2(9,-1),Vector2(9,5)],
	"tongs":[Vector2(-7,-5),Vector2(-4,-5),Vector2(1,0),Vector2(5,-5),Vector2(8,-5),Vector2(3,2),Vector2(6,7),Vector2(3,8),Vector2(0,4),Vector2(-4,8),Vector2(-6,6),Vector2(-2,2)],
}
## name, silhouette, palette, body-local crest, offset, gesture, sound,
## story, counterplay. Only equipment crests are new, never whole bodies.
const ACTOR_ROWS := {
	"hero:RIDGE_JARL":["崖盾","斜断锤与三层坝钉肩板","dam",[Vector2(-6,3),Vector2(-6,-1),Vector2(-3,-1),Vector2(-3,-4),Vector2(1,-4),Vector2(1,-2),Vector2(5,-2),Vector2(6,3)],Vector2(-4,-21),"dam_hammer",["clang",150,.67,1,"falling_weight",.36,2.4,-.29,.08],"雪坝轮值守闸工以村庄坝钉拼甲，保留不同泄洪水位。","缓慢重甲可被转线与奥术针对；锤影不扩大普攻范围。"],
	"hero:RUNE_ORACLE":["符炉","多孔窑尺与偏置倒风杯","kiln",[Vector2(-6,-3),Vector2(-2,-3),Vector2(-2,-6),Vector2(3,-6),Vector2(3,-2),Vector2(6,-2),Vector2(4,3),Vector2(-5,3)],Vector2(4,-22),"kiln_gauge_cast",["bell",780,.16,3,"staggered_reprise",.31,2.8,.23,.12],"窑口天气家以温差和工艺符预警，允许别人纠正。","贴近脆弱术师，分散有限伤害与控制覆盖。"],
	"hero:EMBER_CAVALIER":["焰脊","长柄试刃、检温孔护臂与断缎","steel",[Vector2(-6,-3),Vector2(-1,-3),Vector2(1,-6),Vector2(4,-5),Vector2(3,-1),Vector2(6,2),Vector2(1,4),Vector2(-5,3)],Vector2(4,-19),"trial_blade_cut",["scrape",360,.71,2,"sharp_cut",.25,1.9,.41,.02],"封锋试刃者把奖刃熔成修索接环，刃上记工匠姓名。","接近有暴露代价；单刃不是冲锋或传送。"],
	"hero:HEARTH_KEEPER":["炉暖","面包盾孔纹、低炉勺与柴束","oven",[Vector2(-6,2),Vector2(-6,-2),Vector2(-3,-5),Vector2(3,-5),Vector2(6,-1),Vector2(6,3),Vector2(2,4),Vector2(-3,4)],Vector2(-4,-18),"oven_peel_toss",["breath",320,.27,2,"breathing_lift",.35,1.3,.10,.09],"流动面炉主把最后热食给离营者，温暖不交换服从。","切断治疗覆盖并耗蓝；普攻暖渣不假称治疗。"],
	"hero:STORM_HERALD":["雷旌","三叉接地旗与缠绳短锤","rope",[Vector2(-6,2),Vector2(-6,-3),Vector2(-3,-3),Vector2(-3,-6),Vector2(0,-6),Vector2(0,-2),Vector2(3,-2),Vector2(3,-5),Vector2(6,-5),Vector2(6,3)],Vector2(-4,-23),"grounding_flag_snap",["reed",510,.38,3,"woven_drift",.32,1.7,-.19,.10],"怕高的索道旗回收者以绳结旗语把弱声传到队尾。","分散真实链控；旗影不产生新目标或击退。"],
	"ridge_guard":["山垒卫","短方锤、低肩双坝钉","guard",[Vector2(-5,3),Vector2(-5,-3),Vector2(-1,-3),Vector2(-1,-1),Vector2(2,-1),Vector2(2,-4),Vector2(5,-4),Vector2(5,3)],Vector2(-4,-18),"guard_square_bash",["click",215,.62,2,"gather_and_lock",.22,2.2,-.14,.02],"炉道轮值护卫带短锤，区别崖盾的斜断山锤。","近战步慢，可受远程消耗；无额外眩晕。"],
	"stone_slinger":["砾石投手","双尾投带与偏侧石囊","sling",[Vector2(-6,-2),Vector2(-2,-5),Vector2(3,-4),Vector2(6,-1),Vector2(3,3),Vector2(-2,4),Vector2(-5,1)],Vector2(4,-18),"sling_overhand",["pluck",285,.46,1,"directional_rush",.24,1.5,-.34,.04],"炉道碎石手把称量石子收入双尾投带。","射程较短且无甲；单石无假散射。"],
	"fire_dragon":["烬脊火龙","真实龙身、分叉热鳞与侧吐焰","dragon",[Vector2(-6,2),Vector2(-5,-3),Vector2(-2,-1),Vector2(0,-5),Vector2(3,-2),Vector2(6,-4),Vector2(6,3)],Vector2(1,-16),"dragon_banked_breath",["crack",125,.84,3,"opening_fan",.39,1.6,-.47,.13],"热泉沟迁徙火龙保留实体龙体，吐焰带冷壳暗块。","昂贵空军仍受对空集火；碎焰不造持续地形。"],
	"rune_keeper":["符炉师","双钳短炉具与方形试釉牌","keeper",[Vector2(-5,-4),Vector2(-2,-4),Vector2(-2,0),Vector2(2,0),Vector2(2,-4),Vector2(5,-4),Vector2(5,4),Vector2(-5,4)],Vector2(4,-18),"keeper_tongs_flick",["water",620,.20,3,"inward_return",.30,1.4,.17,.08],"普通炉道医工用短钳试釉，区别天气家的长窑尺。","切断治疗距离并耗蓝；普攻不冒充自动治疗。"],
	"rune_behemoth":["符脊巨兽","大型机械身、阶梯压梁与错位岩背","behemoth",[Vector2(-7,4),Vector2(-7,0),Vector2(-4,0),Vector2(-4,-4),Vector2(0,-4),Vector2(0,-6),Vector2(4,-6),Vector2(4,-2),Vector2(7,-2),Vector2(7,4)],Vector2(0,-20),"behemoth_pile_press",["rumble",85,.88,2,"falling_weight",.40,2.7,-.54,.17],"高阶灵髓压梁机保留真实重身，不以放大炉师代替巨兽。","缓慢昂贵且不能对空；溅射由真实结算控制。"],
	"worker:HIGHLAND":["烬脊工人","短钳锤、腰侧柴筹与雪帽沿","worker",[Vector2(-5,3),Vector2(-5,-2),Vector2(-1,-2),Vector2(-1,-4),Vector2(3,-4),Vector2(5,-1),Vector2(3,3)],Vector2(-4,-14),"worker_coal_tap",["scrape",270,.61,2,"staggered_reprise",.19,1.2,-.24,.01],"按洪水年轮轮班补炉道，柴筹记录公共劳动。","无甲工人可被击杀，短工具不替代正规军。"],
}
## owner, final label, gesture, palette, sound, story, counterplay,
## four event-bound stages, passive. No numeric combat authority.
const SKILL_ROWS := {
	"RIDGE_SHOCK":["RIDGE_JARL","炉血重整","dam_rivets_inward","dam",["rumble",115,.52,3,"inward_return",.68,1.6,-.32,.09],"坝钉依次扣回旧甲，承压法用于自身。","SELF自疗无敌人伤害；集火仍有效。",["手锤下压、岩页离缝","厚岩页向自身内扣","自身铜缝合拢，HEAL无敌方受击","霜粒下落、内热收回"],false],
	"RIDGE_WARD":["RIDGE_JARL","山誓重铠","quiet_watermark_armor","dam",["clang",145,.30,1,"gather_and_lock",.25,2.1,-.10,.03],"水位年轮记录错误的开闸选择。","学习常驻被动随真实来源；无主动护盾。",["被动，无主动预示","无投递","无伤害或控制命中","真实被动来源结束"],true],
	"RIDGE_MEND":["RIDGE_JARL","崩岩号令","sluice_slab_procession","strata",["clang",100,.77,5,"falling_weight",1.85,2.6,-.55,.22],"闸门逐段放压，岩页沿贯穿方向抬落。","直线伤害兼STUN；侧移分散，岩页无碰撞。",["手锤回拉、低岩页竖起","重岩由近向远递进","合法中心层页压落表示STUN","石片侧落；额外线命中归原连接器"],false],
	"RUNE_BIND":["RUNE_ORACLE","符炉缚","kiln_single_gauge_lock","kiln",["click",720,.26,4,"gather_and_lock",.70,3.0,-.23,.07],"窑尺夹住一处温差，使预警可读。","纯单体STUN零伤且无破甲；掩护被锁对象。",["手边窑尺两臂张开","测温夹递至合法单体","上部孔尺闭锁，零伤STUN","夹口松开、砂落，无伤爆"],false],
	"RUNE_FLARE":["RUNE_ORACLE","炉焰","glaze_seams_sputter","glaze",["crack",410,.68,4,"staggered_reprise",.78,2.2,.24,.11],"裂釉分拍喷吐，冷灰护住琥珀热核。","有限区域伤害与灼烧；不造持续地形。",["手边釉片倾斜、亮缝开启","釉片低弧落到中心","不等高裂釉错拍喷出","暗渣先落、余温熄灭"],false],
	"RUNE_OATH":["RUNE_ORACLE","深炉喷涌","deep_kiln_weighted_pour","pour",["breath",195,.59,7,"opening_fan",1.82,1.7,-.28,.20],"风杯引出倾釉，大熔滴与冷壳各有重量。","扇面伤害与灼烧；侧移分散，非全屏火海。",["孔尺与暗炉口张开","不等重釉滴沿前向扇开","合法中心沉渣与热丝分层落定","重渣先沉、热丝后断，无地面DoT区"],false],
	"EMBER_SEAL":["EMBER_CAVALIER","焰刃封","trial_steel_single_clamp","steel",["scrape",310,.57,2,"gather_and_lock",.65,2.3,-.17,.03],"试刃夹具先停锋，再留有限实体刃伤。","单体伤害兼STUN；近身施放有代价。",["长柄刃后收、检温夹打开","实体刃与横夹递向单体","高位夹锁后短钢线切入","夹松、暗刃回收"],false],
	"EMBER_SWEEP":["EMBER_CAVALIER","热谷旋刃","sled_blade_straight_wake","wake",["buzz",380,.43,3,"directional_rush",.56,1.5,.48,.04],"运钢橇留下宽窄热痕，沿贯穿轴前送。","直线伤害与灼烧；侧避，非全周旋斩。",["长刃侧压、热条后收","宽窄钢线直向前行","中心短切口，其余命中归原连接器","热尾与暗灰分离后断开"],false],
	"EMBER_MEND":["EMBER_CAVALIER","熔锋决断","single_rescue_cable_cut","verdict",["pluck",240,.62,4,"sharp_cut",1.36,2.8,-.39,.16],"奖刃熔回接环的记忆化成一次准确断索。","单体伤害/低血增伤；无AOE、吸血或SELF强化。",["长刃压低、接环分开","一把长锋窄向递出","单体处暗影与锋线反向合拍","钢屑短落、刃影退去"],false],
	"HEARTH_WARMTH":["HEARTH_KEEPER","暖炉光环","quiet_shared_oven","oven",["breath",330,.12,2,"breathing_lift",.28,1.2,.07,.05],"孔中低热来自共同续火，不是伤害。","学习护甲光环读真实来源/范围；无主动治疗。",["被动，无主动预示","无投递","无假治疗命中","真实护甲光环来源结束"],true],
	"HEARTH_MEND":["HEARTH_KEEPER","炉火重整","shared_loaf_lid_exhale","oven",["water",540,.19,3,"breathing_lift",.76,1.4,.21,.14],"开炉先分热食，烟与炭星分层下沉。","SELF与有限友军治疗/短护甲；不净化或复活。",["炉勺托起面炉盖","自身两层暖烟抬起","自身面包暖缝闭合，无敌方受击","炭点内落；护甲按真实buff到期"],false],
	"HEARTH_REFUGE":["HEARTH_KEEPER","不熄营火","open_exit_oven_shelter","refuge",["choir",290,.24,6,"inward_return",1.90,1.6,.13,.25],"两片低棚影留出口，营地是可以离开的家。","SELF/有限友军群疗与短护甲；非无敌罩。",["炉盖开、棚沿外移","暖烟沿自身两侧低展","开口棚沿回暖，不造新受益者","亮芯先收、暖影退回；护甲读真源"],false],
	"STORM_CHANT":["STORM_HERALD","战歌光环","quiet_offbeat_ground_flag","flag",["reed",470,.21,3,"staggered_reprise",.29,1.5,-.12,.06],"失拍旗语允许队尾纠正前队。","真实普攻光环按来源/范围结束；不主动召雷。",["被动，无主动预示","无投递","无雷击伤害命中","真实光环离场归上游"],true],
	"STORM_HAMMER":["STORM_HERALD","落雷锤","rope_grounding_line_lock","rope",["bell",640,.37,3,"directional_rush",.74,2.9,-.36,.12],"绳锤沿地回送接地旗，绳结需被检查。","纯直线STUN零伤无灼烧；避开窄线。",["绳锤后绷成折线","短雷叉沿接地绳前送","合法中心高结锁定，STUN非伤爆","雷丝回收、铜尘下沉"],false],
	"STORM_VERDICT":["STORM_HERALD","山巅裁决","first_flag_return_verdict","flag",["reed",395,.51,5,"woven_drift",1.72,2.0,.27,.23],"第一面旗把口令交给真实链路，末队有权回应。","连锁伤害兼STUN；分散限跳，不造第二目标。",["三叉旗杆倾斜、绳结紧","旗幅沿折线递至首个合法中心","单处旗影与接地叉合拢表示STUN","布尾折返；后续命中全归原连接器"],false],
}

static func _sound(r: Array) -> Dictionary:
	return {"voice":str(r[0]),"frequency":float(r[1]),"texture":float(r[2]),"pulses":int(r[3]),"rhythm":str(r[4]),"seconds":float(r[5]),"overtone":float(r[6]),"sweep":float(r[7]),"echo":float(r[8])}

static func actors() -> Dictionary:
	var result := {}
	for id: String in ACTOR_ROWS: result[id]=actor_profile(id)
	return result.duplicate(true)

static func skills() -> Dictionary:
	var result := {}
	for id: String in SKILL_ROWS: result[id]=skill_profile(id)
	return result.duplicate(true)

static func actor_profile(identity: String) -> Dictionary:
	if not ACTOR_ROWS.has(identity): return {}
	var r: Array=ACTOR_ROWS[identity]
	return {"identity":identity,"faction_id":"HIGHLAND","name":r[0],"silhouette":r[1],"palette":PALETTES[str(r[2])].duplicate(true),"crest":r[3].duplicate(true),"crest_offset":r[4],"gesture":r[5],"sound":_sound(r[6]),"story_anchor":r[7],"counterplay":r[8],"body_change":"preserved_body_small_equipment_crest","identity_version":VERSION}.duplicate(true)

static func skill_profile(skill_id: String) -> Dictionary:
	if not SKILL_ROWS.has(skill_id): return {}
	var r: Array=SKILL_ROWS[skill_id]
	return {"skill_id":skill_id,"hero_id":r[0],"faction_id":"HIGHLAND","name":r[1],"gesture":r[2],"palette":PALETTES[str(r[3])].duplicate(true),"sound":_sound(r[4]),"story_anchor":r[5],"counterplay":r[6],"phases":r[7].duplicate(true),"passive":bool(r[8]),"identity_version":VERSION}.duplicate(true)

static func _color(p: Array, slot: int, a: float) -> Color:
	return Color(str(p[slot]),clampf(a,0,1))

static func _piece(ctx: Dictionary, at: Vector2, shape: String, s: float, p: Array, angle: float, a: float) -> void:
	Brush.stamp(ctx,at,SHAPES[shape],s,p,angle,a)

static func _line(ctx: Dictionary, from: Vector2, to: Vector2, s: float, p: Array, a: float, width: float=2.0) -> void:
	Brush.streak(ctx,from,to,(width+2)*s,_color(p,0,a))
	Brush.streak(ctx,from,to,width*s,_color(p,3,a))

static func _grain(ctx: Dictionary, at: Vector2, s: float, p: Array, a: float, slot: int=5) -> void:
	Brush.chip(ctx,at,Vector2(2,1)*s,_color(p,0,a))
	Brush.chip(ctx,at-Vector2(0,1)*s,Vector2(1,1)*s,_color(p,slot,a))

static func draw_signature(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, spec: Dictionary) -> void:
	var t:=float(ctx.get("phase",-1))
	if not is_finite(t) or t<0 or t>=1 or not is_finite(scale) or scale<=0: return
	if not origin.is_finite() or not center.is_finite() or bool(spec.get("passive",false)): return
	if str(spec.get("effect","")) in ["AURA","PASSIVE_GUARD"]: return
	var p: Array=spec.get("palette",[])
	if p.size()!=7: return
	var previous_limit:=int(ctx.get("draw_limit",0))
	ctx.draw_limit=mini(previous_limit,int(ctx.get("count",0))+(36 if bool(spec.get("is_skill",false)) else 24))
	var d:=(center-origin).normalized()
	if d.length_squared()<.1: d=Vector2.RIGHT
	var a:=clampf(sin(t*PI)*1.6,0,1)
	var q:=clampf((t-.20)/.38,0,1)
	# origin already is the observed hand; swings are local to that anchor.
	if bool(spec.get("is_skill",false)):
		_draw_skill(ctx,origin,center,d,d.orthogonal(),scale,t,q,a,p,str(spec.get("gesture","")))
	else:
		_draw_actor(ctx,origin,center,d,d.orthogonal(),scale,t,q,a,p,str(spec.get("gesture","")))
	ctx.draw_limit=previous_limit

static func _draw_actor(ctx: Dictionary, o: Vector2, c: Vector2, d: Vector2, n: Vector2, s: float, t: float, q: float, a: float, p: Array, gesture: String) -> void:
	var angle:=d.angle()
	match gesture:
		"dam_hammer":
			var at:=o.lerp(c,q*.75)+Vector2(0,-10*sin(t*PI))*s
			_piece(ctx,at,"hammer",s*.87,p,-.7+q*1.3,a)
			if t>.58: _piece(ctx,c+Vector2(2,(t-.58)*10)*s,"slab",s*.43,p,.1,a*.8)
		"kiln_gauge_cast":
			_piece(ctx,o,"gauge",s*.75,p,-.35+q*.65,a)
			if t>.20 and t<.79: _piece(ctx,o.lerp(c,q)+n*sin(q*PI)*6*s,"glass",s*.5,p,angle+q*.6,a)
			if t>.60: _grain(ctx,c+Vector2(4,(t-.60)*14)*s,s,p,a,6)
		"trial_blade_cut":
			var at:=o.lerp(c,q*.86)
			_piece(ctx,at+n*(7-5*q)*s,"blade",s*.84,p,angle-.75+q*.95,a)
			if t>.53 and t<.82: _line(ctx,c-n*5*s-d*5*s,c+n*5*s+d*5*s,s,p,a,1)
		"oven_peel_toss":
			_piece(ctx,o,"peel",s*.66,p,angle-.4+q*.6,a)
			if t>.20 and t<.78: _piece(ctx,o.lerp(c,q)+Vector2(0,-sin(q*PI)*10)*s,"glaze",s*.44,p,-.3+q,a)
			if t>.61: _grain(ctx,c+Vector2(-3,(t-.61)*9)*s,s,p,a,5)
		"grounding_flag_snap":
			_piece(ctx,o-n*5*s,"flag",s*.67,p,-.5+q*.6,a)
			if t>.20 and t<.76:
				var at:=o.lerp(c,q)
				_line(ctx,at-d*8*s,at+n*3*s,s,p,a,1)
				_line(ctx,at+n*3*s,at+d*5*s,s,p,a,1)
			if t>.58: _piece(ctx,c,"fork",s*.40,p,angle-PI*.5,a)
		"guard_square_bash":
			_piece(ctx,o.lerp(c,q*.68),"rivet",s*.95,p,angle+.15*(1-q),a)
			_line(ctx,o-d*4*s,o+d*(7+sin(t*PI)*8)*s,s,p,a,2)
			if t>.57: _grain(ctx,c+Vector2(2,(t-.57)*8)*s,s,p,a,6)
		"sling_overhand":
			var lift:=o+Vector2(-5*(1-q),-9*sin(t*PI))*s
			_piece(ctx,lift,"sling",s*.54,p,-.8+q*1.3,a)
			_line(ctx,o,lift,s,p,a,1)
			if t>.20 and t<.79: _piece(ctx,o.lerp(c,q)+Vector2(0,-sin(q*PI)*20)*s,"slab",s*.42,p,q*.7,a)
		"dragon_banked_breath":
			_piece(ctx,o-d*4*s,"tooth",s*.60,p,angle,a)
			if t>.20 and t<.79:
				var at:=o.lerp(c,q)
				_piece(ctx,at,"slag",s*(.5+q*.30),p,angle,a)
				_piece(ctx,at-d*9*s+n*4*s,"glaze",s*.36,p,angle+.4,a*.8)
			if t>.60: _grain(ctx,c+Vector2(-5,(t-.60)*14)*s,s,p,a,2)
		"keeper_tongs_flick":
			_piece(ctx,o,"tongs",s*.6,p,-.25+q*.5,a)
			if t>.20 and t<.77: _piece(ctx,o.lerp(c,q),"rivet",s*.39,p,angle+q*.8,a)
			if t>.59: _line(ctx,c-d*4*s,c+d*3*s,s,p,a*.7,1)
		"behemoth_pile_press":
			var at:=o.lerp(c,q*.70)+Vector2(0,-14*(1-q))*s
			_piece(ctx,at,"ram",s*1.05,p,-.10+q*.12,a)
			if t>.56:
				_piece(ctx,c+Vector2(-8,4+(t-.56)*6)*s,"slab",s*.55,p,-.18,a*.85)
				_piece(ctx,c+Vector2(9,7+(t-.56)*4)*s,"rivet",s*.45,p,.16,a*.7)
		"worker_coal_tap":
			_piece(ctx,o+d*(sin(t*PI)*5)*s,"tongs",s*.56,p,-.7+q*1.15,a)
			if t>.48: _grain(ctx,o+d*7*s+Vector2(0,4+(t-.48)*9)*s,s,p,a,2)

static func _draw_skill(ctx: Dictionary, o: Vector2, c: Vector2, d: Vector2, n: Vector2, s: float, t: float, q: float, a: float, p: Array, gesture: String) -> void:
	var angle:=d.angle()
	var settle:=clampf((t-.78)/.22,0,1)
	match gesture:
		"dam_rivets_inward":
			_piece(ctx,o+Vector2(-4,2+q*3)*s,"hammer",s*.68,p,-.6+q*.8,a)
			for side: int in [-1,1]:
				var at:=o+Vector2(side*(16-q*11),2+side*2+settle*5)*s
				_piece(ctx,at,"slab",s*(.65-settle*.18),p,side*(.25-q*.20),a)
			if t>.58: _line(ctx,o+Vector2(-5,2)*s,o+Vector2(5,-1)*s,s,p,a,1)
			if t>.78: _grain(ctx,o+Vector2(-7,7+settle*7)*s,s,p,a,6)
		"sluice_slab_procession":
			_piece(ctx,o+Vector2(0,-7*(1-q))*s,"hammer",s*.80,p,-.8+q*1.1,a)
			if t>.20:
				for i: int in range(3):
					var u:=clampf((t-.20-float(i)*.075)/.38,0,1)
					var at:=o.lerp(c,u)+Vector2(0,-(1-u)*(12-float(i)*2)+settle*7)*s+n*(float(i)-1)*4*s
					_piece(ctx,at,"slab",s*(.65+float(i)*.12-settle*.20),p,(i-1)*.10,a)
				if t>.58: _line(ctx,c+Vector2(-8,-8)*s,c+Vector2(9,-8)*s,s,p,a,3)
				if t>.78: _grain(ctx,c+Vector2(10+settle*7,9)*s,s,p,a,6)
		"kiln_single_gauge_lock":
			var top:=c+Vector2(0,-8)*s
			var at:=o.lerp(top,q)
			for side: int in [-1,1]:
				_piece(ctx,at+n*side*(10-6*q+settle*5)*s,"gauge",s*.75,p,angle+(0 if side==1 else PI),a)
			if t>.58: _piece(ctx,top,"glass",s*(.46-settle*.17),p,0,a*.7)
			if t>.78: _grain(ctx,top+Vector2(4,7+settle*9)*s,s,p,a,6)
		"glaze_seams_sputter":
			_piece(ctx,o,"gauge",s*.68,p,-.35+q*.7,a)
			if t>.20 and t<.58: _piece(ctx,o.lerp(c,q)+Vector2(0,-sin(q*PI)*10)*s,"glaze",s*.72,p,q*.6,a)
			elif t>=.58:
				for i: int in range(3):
					var off:=float(i-1)
					var rise:=sin(clampf((t-.58-float(i)*.025)/.36,0,1)*PI)
					_piece(ctx,c+Vector2(off*10,-rise*(12+float(i)*5)+settle*8)*s,"glaze",s*(.63-absf(off)*.08),p,off*.3,a)
				if t>.79: _grain(ctx,c+Vector2(-8,8+settle*6)*s,s,p,a,6)
		"deep_kiln_weighted_pour":
			_piece(ctx,o,"gauge",s*.92,p,-.5+q*.9,a)
			if t<.20: _piece(ctx,o+d*8*s,"slag",s*.72,p,angle,a)
			else:
				for i: int in range(3):
					var lane:=float(i-1)
					var u:=clampf((t-.20-float(i)*.045)/.40,0,1)
					var at:=o.lerp(c,u)+n*lane*(3+10*u)*s+Vector2(0,-sin(u*PI)*(14-absf(lane)*4)+settle*7)*s
					_piece(ctx,at,"slag",s*(.92-absf(lane)*.22-settle*.25),p,angle+lane*.35,a)
					if t>.58 and t<.84: _line(ctx,at-d*(9+absf(lane)*3)*s,at,s,p,a*.75,1)
				if t>.80: _grain(ctx,c+Vector2(-7,8+settle*8)*s,s,p,a,6)
		"trial_steel_single_clamp":
			var at:=o.lerp(c,q)
			_piece(ctx,at,"blade",s*.88,p,angle-.35+q*.25,a)
			var top:=at+Vector2(0,-8)*s
			_piece(ctx,top-n*(8-5*q+settle*5)*s,"clamp",s*.65,p,angle,a)
			_piece(ctx,top+n*(6-3*q+settle*4)*s,"clamp",s*.46,p,angle+PI,a*.85)
			if t>.58 and t<.78: _line(ctx,c-d*5*s,c+d*6*s,s,p,a,1)
		"sled_blade_straight_wake":
			var at:=o.lerp(c,q)
			_piece(ctx,at+n*(7-4*q)*s,"blade",s*.95,p,angle,a)
			if t>.20:
				_line(ctx,o.lerp(c,maxf(0,q-.28))+n*5*s,at+n*5*s,s,p,a,3)
				_line(ctx,o.lerp(c,maxf(0,q-.43))-n*5*s,at-n*5*s,s,p,a*.8,1)
				if t>.58: _piece(ctx,c-n*(2+settle*6)*s,"blade",s*(.40-settle*.1),p,angle+PI,a*.7)
		"single_rescue_cable_cut":
			if t<.20:
				_piece(ctx,o-d*5*s,"blade",s*.95,p,angle-.4,a)
				for side: int in [-1,1]: _piece(ctx,o+n*side*6*s,"rivet",s*.36,p,side*.5,a)
			elif t<.58: _piece(ctx,o.lerp(c,q),"blade",s*1.18,p,angle-.2+q*.3,a)
			else:
				var cut:=clampf((t-.58)/.20,0,1)
				_piece(ctx,c+n*(9-18*cut)*s,"blade",s*(1.15-settle*.6),p,angle-.55+cut*.8,a)
				_piece(ctx,c-n*(8-16*cut)*s,"blade",s*(.72-settle*.35),p,angle+PI+.35-cut*.6,a*.6)
				_line(ctx,c-n*10*s-d*5*s,c+n*10*s+d*5*s,s,p,a,2)
				if t>.80: _grain(ctx,c+Vector2(7,5+settle*11)*s,s,p,a,6)
		"shared_loaf_lid_exhale":
			_piece(ctx,o+Vector2(-4,2)*s,"peel",s*.76,p,-.5+q*.8,a)
			if t>.20:
				for i: int in range(2):
					var rise:=clampf((t-.20-float(i)*.10)/.48,0,1)
					_piece(ctx,o+Vector2(float(i*2-1)*(6+rise*4),-3-rise*(7+float(i)*4))*s,"smoke",s*(.68-rise*.2),p,float(i)*.1,a*.75)
				if t>.54: _piece(ctx,o+Vector2(0,5+settle*4)*s,"loaf",s*(.63-settle*.2),p,0,a)
				if t>.76: _grain(ctx,o+Vector2(5,2+settle*7)*s,s,p,a,4)
		"open_exit_oven_shelter":
			_piece(ctx,o+Vector2(-5,0)*s,"peel",s*.78,p,-.4+q*.5,a)
			if t>.20:
				var spread:=sin(clampf((t-.20)/.80,0,1)*PI)
				for side: int in [-1,1]:
					var at:=o+Vector2(side*(7+spread*10),-5-spread*4)*s
					_piece(ctx,at,"shelter",s*.70,p,side*.18,a)
					if t>.54: _piece(ctx,at+Vector2(-side*3,9+settle*4)*s,"loaf",s*.43,p,side*.2,a*.8)
				if t>.70: _piece(ctx,o+Vector2(0,-5-settle*5)*s,"smoke",s*.54,p,0,a*.5)
		"rope_grounding_line_lock":
			_piece(ctx,o,"hammer",s*.61,p,-.6+q*.7,a)
			var at:=o.lerp(c,q)
			if t>.20 and t<.58:
				var knot:=o.lerp(at,.5)+n*5*s
				_line(ctx,o,knot,s,p,a,1)
				_line(ctx,knot,at,s,p,a,1)
				_piece(ctx,at,"fork",s*.56,p,angle-PI*.5,a)
			elif t>=.58:
				var top:=c+Vector2(0,-8)*s
				_line(ctx,top-n*8*s,top+n*8*s,s,p,a,3)
				_piece(ctx,top,"fork",s*(.63-settle*.2),p,0,a)
				if t>.80: _grain(ctx,c+Vector2(-4,7+settle*8)*s,s,p,a,6)
		"first_flag_return_verdict":
			_piece(ctx,o,"fork",s*.70,p,-.4+q*.65,a)
			if t<.20: _piece(ctx,o-n*7*s,"flag",s*.65,p,-.6,a)
			elif t<.58:
				var at:=o.lerp(c,q)+n*sin(q*PI)*7*s
				_line(ctx,o,at,s,p,a*.8,1)
				_piece(ctx,at,"flag",s*.89,p,angle-.35+q*.5,a)
			else:
				_piece(ctx,c+Vector2(-5,-9+settle*5)*s,"flag",s*(1.0-settle*.35),p,-.2+settle*.6,a)
				_piece(ctx,c+Vector2(4,-7)*s,"fork",s*.74,p,.25,a)
				_line(ctx,c+Vector2(-8,-8)*s,c+Vector2(8,-8)*s,s,p,a,2)
				if t>.80: _grain(ctx,c+Vector2(5,6+settle*9)*s,s,p,a,6)
## Three quiet passive gestures intentionally generate no active casts.
