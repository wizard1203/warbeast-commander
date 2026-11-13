extends RefCounted
## Preserved bodies + small equipment crests; independent authored pixel
## gestures, no game state. origin/center already are hand/target anchors.
const Brush = preload("res://src/presentation/m63_av_brush.gd")
const VERSION := "m63-undead-authored-av-v1"
const PALETTES := {
	"docket":["191b20","514b43","b8ab87","7fb9bd","fff0c3","b7896a","8d9995"],
	"shutter":["151d27","354d69","89a3bd","c49960","f3eed2","79bcb1","8e9ea7"],
	"bone":["211c1b","68523d","c7b17d","8cb8bf","fff0c0","bd8068","9ba296"],
	"thread":["211a1d","694d44","cd9469","86bfa3","fff1cc","bb8b9e","9ba8a0"],
	"bronze":["1c1b21","504741","a18a65","83aeb1","f8eac3","b99a5d","8a969b"],
	"ashfan":["211b23","5b4a61","ab8fa4","8cb7a2","f5ebc8","c4a164","929aa8"],
	"extract":["18201f","3c5954","8bb3a3","ca8d70","fff1c4","8e91ae","8caaa3"],
	"quiver":["1c1c23","57505f","b1a590","d2a457","fff1cc","87b5a8","a59b88"],
	"nail":["19211f","496358","93baa4","c77e63","fff2c8","aa91b9","a1a48b"],
	"curtain":["1b1d23","5d5c52","c0b58e","85bcb3","fff4db","b78f9e","929fa5"],
	"slab":["1c1d20","545650","a8aa95","bb8b6c","eee9cc","7eafa7","929a9b"],
	"worker":["211d1b","655744","b3a582","86afa9","f4e7bc","b58b68","919a90"],
	"memorial":["1b1923","514659","b2a0bb","c6b5d5","f2e6e9","82738d","a5a1a5"],
}
const SHAPES := {
	"page":[Vector2(-7,-5),Vector2(3,-5),Vector2(7,-1),Vector2(5,6),Vector2(-5,5)],
	"clasp":[Vector2(-6,-4),Vector2(1,-4),Vector2(1,-1),Vector2(6,-1),Vector2(6,4),Vector2(-6,4)],
	"bone":[Vector2(-7,-3),Vector2(-3,-3),Vector2(-2,-1),Vector2(4,-1),Vector2(5,-3),Vector2(8,-2),Vector2(8,2),Vector2(4,3),Vector2(3,1),Vector2(-2,1),Vector2(-4,3),Vector2(-7,2)],
	"shutter":[Vector2(-6,-5),Vector2(2,-5),Vector2(6,-1),Vector2(4,5),Vector2(-3,5),Vector2(-6,1)],
	"mirror":[Vector2(-2,-7),Vector2(3,-5),Vector2(4,3),Vector2(0,7),Vector2(-4,2)],
	"arrow":[Vector2(-10,-2),Vector2(3,-2),Vector2(3,-4),Vector2(10,0),Vector2(3,4),Vector2(3,2),Vector2(-10,2),Vector2(-6,0)],
	"nail":[Vector2(-10,-4),Vector2(-5,-4),Vector2(-5,-2),Vector2(7,-2),Vector2(11,0),Vector2(7,2),Vector2(-5,2),Vector2(-5,4),Vector2(-10,4)],
	"feather":[Vector2(-2,5),Vector2(-5,0),Vector2(-3,-6),Vector2(0,-3),Vector2(3,-8),Vector2(5,-2),Vector2(3,3)],
	"caption":[Vector2(-7,-5),Vector2(6,-5),Vector2(7,3),Vector2(1,3),Vector2(-2,6),Vector2(-2,3),Vector2(-7,3)],
	"needle":[Vector2(-9,-1),Vector2(5,-2),Vector2(10,0),Vector2(5,2),Vector2(-9,1)],
	"curtain":[Vector2(-8,-7),Vector2(6,-7),Vector2(8,5),Vector2(3,3),Vector2(0,6),Vector2(-3,3),Vector2(-8,5)],
	"bell":[Vector2(-6,5),Vector2(-4,1),Vector2(-4,-4),Vector2(-1,-7),Vector2(2,-7),Vector2(5,-3),Vector2(5,1),Vector2(7,5),Vector2(2,5),Vector2(1,2),Vector2(-1,5)],
	"hook":[Vector2(-6,-5),Vector2(2,-5),Vector2(6,-1),Vector2(5,4),Vector2(1,6),Vector2(-3,4),Vector2(-2,1),Vector2(1,3),Vector2(3,1),Vector2(1,-2),Vector2(-6,-2)],
	"plate":[Vector2(-8,-5),Vector2(4,-5),Vector2(8,-1),Vector2(6,5),Vector2(-5,6),Vector2(-8,2)],
	"yoke":[Vector2(-9,5),Vector2(-9,-3),Vector2(-5,-6),Vector2(-2,-3),Vector2(-2,1),Vector2(3,1),Vector2(3,-5),Vector2(7,-6),Vector2(9,-2),Vector2(9,5)],
	"spade":[Vector2(-8,-2),Vector2(1,-2),Vector2(1,-5),Vector2(7,-4),Vector2(9,1),Vector2(5,5),Vector2(1,4),Vector2(1,1),Vector2(-8,1)],
	"memorial_lamp":[Vector2(-4,-7),Vector2(3,-7),Vector2(3,-4),Vector2(6,-1),Vector2(5,6),Vector2(-5,6),Vector2(-6,-1),Vector2(-4,-4)],
	"memorial_wick":[Vector2(-3,5),Vector2(-4,0),Vector2(-2,-4),Vector2(-1,-9),Vector2(2,-3),Vector2(4,0),Vector2(3,5)],
}
## label, two non-color identifiers, palette, local crest, in-body offset,
## implemented attack gesture, frozen sound tuple, story, counterplay.
const ACTOR_ROWS := {
	"hero:ASH_MARSHAL":["灰烬统领","柜门铠扣与缺角判杖；先张卷后钝扫","docket",[Vector2(-6,-4),Vector2(4,-4),Vector2(6,-1),Vector2(2,-1),Vector2(2,4),Vector2(-6,4)],Vector2(-4,-19),"cabinet_judgement",["clang",164,.43,2,"falling_weight",.32,2.6,-.22,.07],"错判者铭牌留在铠缝里，守护能重审旧案的炉庭。","集中火力压过有限自疗，绕开坦克接敌方向。"],
	"hero:MOURN_ORACLE":["哀灯","偏侧层叠灯罩与窄铜镜；遮片侧转投光","shutter",[Vector2(-5,-5),Vector2(1,-5),Vector2(5,-2),Vector2(2,0),Vector2(4,4),Vector2(-4,4),Vector2(-5,1)],Vector2(5,-23),"borrowed_shutter",["breath",417,.18,3,"woven_drift",.35,1.5,.12,.13],"以面容记忆换回失踪街巷，灯里的证词允许互相矛盾。","散开限制连锁，逼近脆弱灯匠。"],
	"hero:CINDER_STALKER":["炭翎","横箭匣和断税带；长弓后拉再一箭直放","bone",[Vector2(-6,-3),Vector2(4,-3),Vector2(6,-1),Vector2(3,1),Vector2(3,5),Vector2(0,3),Vector2(-2,5),Vector2(-3,1),Vector2(-6,1)],Vector2(-4,-21),"bone_string_release",["pluck",336,.28,1,"directional_rush",.24,1.7,.31,.03],"回收刻名骨箭抵债，射断契约钉后拒替人追债。","接近射手或逼迫停火，单箭没有溅射。"],
	"hero:ASH_CHANTER":["烬灯","戏箱字板与卷柄；小字板翻页而非灯罩弹","thread",[Vector2(-6,-4),Vector2(6,-4),Vector2(6,2),Vector2(1,2),Vector2(-2,5),Vector2(-2,2),Vector2(-6,2)],Vector2(-4,-18),"caption_flick",["reed",573,.22,2,"opening_fan",.29,1.35,.09,.04],"默剧题字员发现笑声也能修复，让归名者自己改写角色。","切断与伤员的联系，字板普攻不表示治疗。"],
	"hero:GRAVE_BELL":["暮钟","缺口钟架与缠指绳；悬钟先摆后坠舌","bronze",[Vector2(-6,4),Vector2(-4,0),Vector2(-4,-4),Vector2(-1,-6),Vector2(2,-6),Vector2(5,-2),Vector2(5,1),Vector2(7,4),Vector2(2,4),Vector2(1,1),Vector2(-1,4)],Vector2(4,-21),"clapper_weight",["bell",202,.19,2,"staggered_reprise",.38,2.9,-.25,.16],"失听钟校以胸前裂钟感知震动，维护说话之间的停顿。","分散削弱链与群控，定身者仍能还击。"],
	"ash_guard":["灰骨卫","窄骨钩铭扣与短骨刃；短距离横削","bone",[Vector2(-5,-3),Vector2(2,-3),Vector2(5,0),Vector2(2,4),Vector2(-2,4),Vector2(-2,1),Vector2(1,1),Vector2(1,-1),Vector2(-5,-1)],Vector2(-4,-19),"ledger_bone_chop",["scrape",241,.56,1,"sharp_cut",.18,1.6,-.26,.01],"轮值归名守卫佩戴未结义务的骨钩，保留实体短刃。","利用接敌距离与护甲类型克制。"],
	"bone_archer":["铭灯术士","骨系斗篷、矩形铭灯与钩头短法杖；灯芯先内收再递杖","memorial",[Vector2(-4,-6),Vector2(3,-6),Vector2(3,-3),Vector2(5,-1),Vector2(4,5),Vector2(-4,5),Vector2(-5,-1),Vector2(-4,-3)],Vector2(4,-18),"memorial_lamp",["breath",385,.19,3,"woven_drift",.26,1.4,.12,.10],"归名术庭的巡灯学徒把刻名灰页存进方灯，以法杖引出一缕奥术灯焰。","靠近斗篷阵线并利用攻击类型克制；普通灯焰不耗MP，也不额外分裂目标。"],
	"stitched_guard":["缝骨重卫","错层宽骨板和横缝扣；板臂慢拍压下","slab",[Vector2(-7,-4),Vector2(-1,-4),Vector2(0,-1),Vector2(3,-4),Vector2(7,-2),Vector2(6,4),Vector2(1,5),Vector2(0,2),Vector2(-6,4)],Vector2(-4,-20),"stitch_slab_strike",["crack",125,.61,2,"falling_weight",.36,2.2,-.47,.09],"多份未完工约缝入承重骨板，沉重不等于额外范围。","以奥术、机动与分散接敌应对重板。"],
	"ember_mender":["灰烬缝合师","线轴耳与单针夹；细针单程递出","thread",[Vector2(-5,-4),Vector2(-1,-4),Vector2(-1,-1),Vector2(5,-1),Vector2(5,2),Vector2(-1,2),Vector2(-1,5),Vector2(-5,5)],Vector2(4,-18),"needle_prick",["pluck",741,.16,3,"woven_drift",.30,1.2,.16,.05],"缝名手艺修复战友，普攻只投针，不代替实际治疗事件。","切断治疗距离并迫其自保，可耗尽其蓝量。"],
	"soul_revenant":["摄魂巨骸","大型重骨身体与分叉铭牌承轭；三节重物依次沉落","slab",[Vector2(-7,4),Vector2(-7,-3),Vector2(-4,-5),Vector2(-1,-2),Vector2(-1,1),Vector2(2,1),Vector2(2,-4),Vector2(5,-5),Vector2(7,-2),Vector2(7,4)],Vector2(0,-22),"name_yoke_drop",["rumble",83,.68,3,"falling_weight",.40,2.6,-.58,.15],"归名者共同承担重轭，只有真实士兵伤害才回收生命。","以奥术或转线牵制，工人与建筑不供吸血。"],
	"worker:UNDEAD":["灰契工人","侧挂灰匣短铲与双页工签；短铲内收夹屑","worker",[Vector2(-5,-3),Vector2(0,-3),Vector2(0,-1),Vector2(5,-1),Vector2(5,3),Vector2(0,3),Vector2(0,5),Vector2(-5,3)],Vector2(-4,-13),"spade_name_chip",["scrape",315,.72,2,"inward_return",.19,1.3,-.19,.01],"把灰匣上的名字与工日配对，工具是短骨铲和缝名钳。","无甲工人可被击杀，采屑不创造资源与战斗命中。"],
}
## owner, final label, implemented gesture, palette, sound, story,
## counterplay, four phases, passive. No copy of simulation values.
const SKILL_ROWS := {
	"ASH_SHOCK":["ASH_MARSHAL","余烬回生","cabinet_reseat","docket",["scrape",176,.42,3,"inward_return",.66,1.8,-.28,.08],"错判者铭牌逐页归位，恢复本人而非召回亡者。","集中火力压过自疗，净化不等于免疫。",["origin胸柜双扣微开","两块铭骨向本人内扣","本人短缝合，无敌方命中","灰屑回入缝隙，不造治疗区域"],false],
	"ASH_WARD":["ASH_MARSHAL","缝骨护甲","quiet_docket_clasps","docket",["clang",151,.26,1,"gather_and_lock",.28,2.1,-.08,.04],"未结案柜扣以实体承重，不借护盾泡。","依实际护甲公式，无付费施法与倒计时。",["被动，无主动预示","无投递","无主动命中","只读既有被动系统"],true],
	"ASH_MEND":["ASH_MARSHAL","灰誓镇魂","judgement_low_fan","ashfan",["scrape",138,.57,5,"opening_fan",1.58,2.4,-.38,.16],"判杖展开钝案卷镰，纸灰压住脚步。","离开真实扇面，ROOT仍可攻击或施法。",["origin案卷侧展","三条低纸带沿前向打开","合法扇面纸条贴地定身并伤害","纸条回卷，无地形碰撞或额外跳伤"],false],
	"MOURN_BIND":["MOURN_ORACLE","灰灯缚","shutter_ankle_knots","shutter",["breath",364,.15,3,"gather_and_lock",.74,1.5,-.21,.12],"借眼灯罩合拢，让不同证词的影线停在脚边。","零伤ROOT仍可普攻与施技，散开减少覆盖。",["origin遮片压合","窄影缝送到权威中心","三枚低位绳结，无眩晕星或爆屑","结口松开，时限仍由状态负责"],false],
	"MOURN_FLARE":["MOURN_ORACLE","哀火","hollow_witness_handoff","shutter",["reed",486,.24,4,"staggered_reprise",.77,1.7,.22,.16],"空心灯纱托住片段视角，证词逐个交接。","散开限制真实连锁，没有新幽灵实体。",["origin偏侧灯罩转动","留白灯纱递向首个合法目标","局部灯纱错位，后续留给原连接器","薄纱折回，吸取依真实伤害"],false],
	"MOURN_OATH":["MOURN_ORACLE","噬魂归烬","single_mirror_unspool","extract",["choir",262,.31,6,"inward_return",1.76,1.4,-.49,.24],"无面铜镜抽回一份证词，单体生命转移留下空白。","保护关键单体、逼退灯匠，无假群伤。",["origin窄镜打开","单线连向合法单体","两半小镜向内压合同一点","证词丝回到origin，不吸动身体"],false],
	"CINDER_SHOT":["CINDER_STALKER","骨弦击","hollow_bone_puncture","bone",["pluck",318,.34,2,"directional_rush",.55,1.6,.38,.04],"回收骨箭有中空骨节，断税带随弦反弹。","单体穿刺无溅射，吸取只读真实伤害。",["origin骨弦后拉","一支长骨箭直进","单点窄穿口","灰粉沿来路短回，非额外伤害"],false],
	"CINDER_FERVOR":["CINDER_STALKER","燃弦","self_quiver_rekindle","quiver",["crack",287,.48,4,"breathing_lift",.78,1.9,.31,.09],"箭匣与低伏长弓燃起分叉热羽，焚断旧税带。","强化期迫其停火，无新灼烧与敌方命中。",["origin弓臂两侧分开","仅本人三束热羽上提","自身箭扣合上","起手收束，持续仍读真实source_buffs"],false],
	"CINDER_MEND":["CINDER_STALKER","灰烬猎杀","contract_nail_execution","nail",["crack",214,.56,3,"sharp_cut",1.34,2.7,-.42,.11],"重骨箭成为射断的契钉，执行感来自单孔钉印。","掩护被选单体，附近单位无视觉假溅射。",["origin重钉横扣弦","一枚有钉帽的骨箭直射","单体斜钉印压实，无环爆","契纸归入单孔，执行数值读权威"],false],
	"ASH_LANTERN":["ASH_CHANTER","哀灯光环","quiet_caption_wick","thread",["reed",524,.12,2,"woven_drift",.30,1.2,.09,.04],"戏箱字幕灯为归名者署名。","治疗光环随真实来源与距离失效。",["被动，无主动预示","无投递","无主动治疗命中","既有来源与死亡规则"],true],
	"ASH_STITCH":["ASH_CHANTER","灰线缝合","two_caption_stitches","thread",["pluck",682,.17,4,"woven_drift",.72,1.3,.24,.13],"绣字手套以两道暖灰线缝补，让伤者重写台词。","有限受益者与蓝量，不为未受疗者画针脚。",["origin字板侧翻、针转向","两短线弧在实际受益中心收拢","两道暖针脚，只表达治疗净化","线头压平，无敌方裂伤或持续治疗地毯"],false],
	"ASH_REQUIEM":["ASH_CHANTER","归名安魂","unwritten_curtain_return","curtain",["choir",436,.19,7,"staggered_reprise",1.94,1.6,.18,.28],"旧戏箱空幕等候下一句台词，不强迫亡者返场。","有限目标治疗与耗蓝，不复活或新增友军。",["origin字幕板抬起","实际治疗中心两片小幕错拍展开","空幕间署名灯芯升起，无伤害爆点","幕片折回，无额外疗效或复活"],false],
	"GRAVE_CADENCE":["GRAVE_BELL","暮钟光环","quiet_clapper_gap","bronze",["bell",183,.13,2,"staggered_reprise",.34,2.5,-.05,.12],"裂钟空拍为说话留下间隙，低亮钟舌不喧宾夺主。","依来源光环，不生成主动控制或独立计时。",["被动，无主动预示","无投递","无控制命中","只读既有来源光环"],true],
	"GRAVE_CHAIN":["GRAVE_BELL","锁魂链","weighted_tuning_hook","bronze",["clang",192,.38,3,"gather_and_lock",.79,2.4,-.32,.13],"校音绳的重钩锁住节拍而非拖走身体。","散开限制链条，ROOT仍可攻击，无拉拽或墙。",["origin绳端后拉","重钩与绳扣递向首个合法中心","脚边钩节落定，额外命中交原连接器","钩背松下，定身持续读权威"],false],
	"GRAVE_TOLL":["GRAVE_BELL","寂静晚钟","silent_bell_downbeat","bronze",["bell",108,.23,4,"falling_weight",2.08,3.1,-.57,.32],"裂口钟影先落，晚到金尘表示没有发声的重量。","零伤群定身，仍可还击施技，不是眩晕或沉默。",["origin小钟舌悬起","中心缺口钟影垂下","低位钟沿压脚，无星或爆裂","钟影先退、迟金尘下落，不改时限"],false],
}

static func _sound(r: Array) -> Dictionary:
	return {"voice":str(r[0]),"frequency":float(r[1]),"texture":float(r[2]),"pulses":int(r[3]),"rhythm":str(r[4]),"seconds":float(r[5]),"overtone":float(r[6]),"sweep":float(r[7]),"echo":float(r[8])}

static func actors() -> Dictionary:
	var result := {}
	for id: String in ACTOR_ROWS: result[id]=actor_profile(id)
	return result.duplicate(true)

static func actor_profile(id: String) -> Dictionary:
	if not ACTOR_ROWS.has(id): return {}
	var r: Array = ACTOR_ROWS[id]
	return {"identity":id,"faction_id":"UNDEAD","name":r[0],"silhouette":r[1],"palette":PALETTES[str(r[2])].duplicate(true),"crest":r[3].duplicate(true),"crest_offset":r[4],"gesture":r[5],"sound":_sound(r[6]),"story_anchor":r[7],"counterplay":r[8],"body_change":"v3_authored_body_equipment_crest" if id=="bone_archer" else "preserved_body_small_equipment_crest","identity_version":"outposts-v3-unit-av-v1" if id=="bone_archer" else VERSION}.duplicate(true)

static func skills() -> Dictionary:
	var result := {}
	for id: String in SKILL_ROWS: result[id]=skill_profile(id)
	return result.duplicate(true)

static func skill_profile(id: String) -> Dictionary:
	if not SKILL_ROWS.has(id): return {}
	var r: Array = SKILL_ROWS[id]
	return {"skill_id":id,"hero_id":r[0],"faction_id":"UNDEAD","name":r[1],"gesture":r[2],"palette":PALETTES[str(r[3])].duplicate(true),"sound":_sound(r[4]),"story_anchor":r[5],"counterplay":r[6],"phases":r[7].duplicate(true),"passive":bool(r[8]),"identity_version":VERSION}.duplicate(true)

static func _color(p: Array, slot: int, alpha: float) -> Color:
	return Color(str(p[slot]),clampf(alpha,0,1))

static func _piece(ctx: Dictionary, at: Vector2, shape: String, s: float, p: Array, angle: float, a: float) -> void:
	Brush.stamp(ctx,at,SHAPES[shape],s,p,angle,a)

static func _line(ctx: Dictionary, from: Vector2, to: Vector2, s: float, p: Array, a: float, width: float=1.0) -> void:
	Brush.streak(ctx,from,to,(width+2)*s,_color(p,0,a))
	Brush.streak(ctx,from,to,width*s,_color(p,3,a))

static func _string(ctx: Dictionary, o: Vector2, d: Vector2, s: float, pull: float, p: Array, a: float) -> void:
	var n := d.orthogonal()
	var notch := o-d*(2+pull*8)*s
	_line(ctx,o+n*9*s,o+d*4*s,s,p,a,2)
	_line(ctx,o+d*4*s,o-n*9*s,s,p,a,2)
	_line(ctx,o+n*9*s,notch,s,p,a,1)
	_line(ctx,notch,o-n*9*s,s,p,a,1)

static func draw_signature(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, spec: Dictionary) -> void:
	var t := float(ctx.get("phase",-1))
	if not is_finite(t) or t<0 or t>=1 or not is_finite(scale) or scale<=0: return
	if bool(spec.get("passive",false)) or not origin.is_finite() or not center.is_finite(): return
	var p: Array = spec.get("palette",[])
	if p.size()!=7: return
	var skill := bool(spec.get("is_skill",false))
	var old_limit := int(ctx.get("draw_limit",0))
	ctx.draw_limit=mini(old_limit,int(ctx.get("count",0))+(36 if skill else 24))
	var d := (center-origin).normalized()
	if d.length_squared()<.1: d=Vector2.RIGHT
	var q := clampf((t-.18)/.56,0,1)
	var a := clampf(sin(t*PI)*1.4,0,1)
	if skill: _draw_skill(ctx,origin,center,d,d.orthogonal(),scale,t,q,a,p,str(spec.get("gesture","")))
	else: _draw_actor(ctx,origin,center,d,d.orthogonal(),scale,t,q,a,p,str(spec.get("gesture","")))
	ctx.draw_limit=old_limit

static func _draw_actor(ctx: Dictionary, o: Vector2, c: Vector2, d: Vector2, n: Vector2, s: float, t: float, q: float, a: float, p: Array, g: String) -> void:
	var angle := d.angle()
	match g:
		"cabinet_judgement":
			_piece(ctx,o-d*4*s,"page",s*.75,p,-.4-q*.6,a)
			_line(ctx,o-d*6*s,o+d*(9+13*sin(t*PI))*s,s,p,a,3)
			_piece(ctx,o+d*(10+13*sin(t*PI))*s,"clasp",s*.7,p,angle-.9+q*1.5,a)
		"borrowed_shutter":
			_piece(ctx,o+n*4*s,"shutter",s*.8,p,angle-.6+q*.8,a)
			if t>.24: _piece(ctx,o.lerp(c,q),"mirror",s*.5,p,angle+PI*.5,a)
		"bone_string_release":
			_string(ctx,o,d,s,1-q,p,a)
			if t>.24: _piece(ctx,o.lerp(c,q),"arrow",s*.65,p,angle,a)
		"caption_flick":
			_piece(ctx,o,"caption",s*.6,p,-.6+q*.7,a)
			if t>.26: _piece(ctx,o.lerp(c,q)+n*sin(q*PI)*5*s,"page",s*.55,p,angle+q*.7,a)
		"clapper_weight":
			_piece(ctx,o+n*3*s,"bell",s*.7,p,-.6+q*.8,a)
			var head := o.lerp(c,q)+Vector2(0,-6*sin(q*PI))*s
			_line(ctx,head-d*7*s,head,s,p,a,1)
			_piece(ctx,head,"clasp",s*.45,p,angle+PI*.5,a)
		"ledger_bone_chop":
			_piece(ctx,o+d*(7+12*sin(t*PI))*s,"bone",s*.9,p,angle-.8+q*1.5,a)
			if t>.48: _line(ctx,o+d*9*s-n*5*s,o+d*18*s+n*3*s,s,p,a*.6,1)
		"crossbow_spring":
			_line(ctx,o-n*7*s,o+n*7*s,s,p,a,3)
			_piece(ctx,o-d*5*(1-q)*s,"clasp",s*.7,p,angle,a)
			if t>.30: _piece(ctx,o.lerp(c,q),"arrow",s*.45,p,angle,a)
		"memorial_lamp":
			# Staff/lantern anticipation only. The one real travelling payload
			# belongs to WeaponArt.MEMORIAL_WISP, never a second bone arrow.
			var lamp:=o-d*(5*(1-q))*s+n*4*s
			_line(ctx,o-n*4*s+Vector2(0,7)*s,o-n*4*s+Vector2(0,-13)*s,s,p,a,1)
			_piece(ctx,lamp,"memorial_lamp",s*.62,p,0,a)
			if t>.28:
				_piece(ctx,lamp+Vector2(0,-7-4*q)*s,"memorial_wick",s*.38,p,angle*.08,a*.85)
				Brush.chip(ctx,lamp-d*7*s+Vector2(0,-10)*s,Vector2(1.5,1)*s,_color(p,3,a*.6))
		"stitch_slab_strike":
			_piece(ctx,o+d*(5+13*q)*s,"plate",s,p,angle-.7+q*1.2,a)
			_piece(ctx,o+d*(4+9*q)*s+n*7*s,"bone",s*.7,p,angle+.3,a)
			if t>.5: _line(ctx,o+d*8*s-n*6*s,o+d*17*s+n*3*s,s,p,a,1)
		"needle_prick":
			_piece(ctx,o,"caption",s*.45,p,-.25,a)
			if t>.24: _piece(ctx,o.lerp(c,q),"needle",s*.5,p,angle,a)
		"name_yoke_drop":
			var at := o+d*14*s+Vector2(0,-11*(1-q)+6*q)*s
			_piece(ctx,at,"yoke",s*1.05,p,-.3+q*.35,a)
			for i: int in range(2): _piece(ctx,at+Vector2(-7+float(i)*14,4+float(i)*4)*s,"plate",s*.55,p,float(i)*.4,a*.85)
		"spade_name_chip":
			_piece(ctx,o+d*7*s,"spade",s*.8,p,angle-.8+q*1.1,a)
			if t>.50 and t<.88: _piece(ctx,o+d*(15-7*q)*s+n*3*s,"page",s*.32,p,-q,a*.75)

static func _draw_skill(ctx: Dictionary, o: Vector2, c: Vector2, d: Vector2, n: Vector2, s: float, t: float, q: float, a: float, p: Array, g: String) -> void:
	var angle := d.angle()
	match g:
		"cabinet_reseat":
			var chest := o+Vector2(0,7)*s
			for side: int in [-1,1]: _piece(ctx,chest+Vector2(float(side)*(17-12*q),0)*s,"plate",s*.7,p,float(side)*(.25-.2*q),a)
			if t>.38:
				_piece(ctx,chest,"clasp",s*.65,p,0,a)
				_line(ctx,chest+Vector2(0,-5)*s,chest+Vector2(0,5)*s,s,p,a,1)
		"judgement_low_fan":
			_piece(ctx,o,"page",s*.9,p,angle-.6+q,a)
			for i: int in range(3):
				var lane := float(i)-1
				_piece(ctx,o.lerp(c,q)+n*lane*12*q*s+Vector2(0,5)*s,"page",s*(.65+.18*q),p,angle+lane*.45+q*.5,a)
			if t>.55:
				_line(ctx,c+Vector2(-10,9)*s,c+Vector2(-2,9)*s,s,p,a,2)
				_line(ctx,c+Vector2(3,9)*s,c+Vector2(11,8)*s,s,p,a,2)
		"shutter_ankle_knots":
			for side: int in [-1,1]: _piece(ctx,o+n*float(side)*(7-4*q)*s,"shutter",s*.55,p,angle+float(side)*(.45-.3*q),a)
			if t>.24 and t<.62: _line(ctx,o,o.lerp(c,q),s,p,a*.6,1)
			if t>.34:
				for i: int in range(3): _piece(ctx,c+Vector2((float(i)-1)*(17-7*q),8+float(i%2)*3)*s,"hook",s*.5,p,PI*.5+float(i-1)*.3,a)
		"hollow_witness_handoff":
			_piece(ctx,o,"shutter",s*.8,p,-.5+q*.6,a)
			var head := o.lerp(c,q)
			for side: int in [-1,1]: _piece(ctx,head+n*float(side)*4*s,"curtain",s*.45,p,angle+float(side)*.45,a)
			if t>.58: _piece(ctx,c+Vector2(0,-4)*s,"mirror",s*.55,p,.15,a*.8)
		"single_mirror_unspool":
			_piece(ctx,o,"mirror",s*.8,p,-.2+q*.4,a)
			if t>.20 and t<.78: _line(ctx,o,c,s,p,a*.75,1)
			for side: int in [-1,1]: _piece(ctx,c+n*float(side)*(11-7*q)*s,"mirror",s*.7,p,angle+float(side)*(.6-q*.4),a)
			if t>.56: _piece(ctx,c.lerp(o,clampf((t-.56)/.40,0,1)),"needle",s*.5,p,angle+PI,a)
		"hollow_bone_puncture":
			_string(ctx,o,d,s,1-q,p,a)
			if t>.22: _piece(ctx,o.lerp(c,q),"arrow",s*.95,p,angle,a)
			if t>.62:
				_line(ctx,c-d*6*s,c+d*5*s,s,p,a,1)
				_piece(ctx,c-d*(5+10*clampf((t-.62)/.34,0,1))*s+n*3*s,"bone",s*.3,p,angle,a*.6)
		"self_quiver_rekindle":
			_string(ctx,o,d,s,sin(t*PI),p,a)
			for i: int in range(3):
				var u := clampf((t-.12-float(i)*.09)/.56,0,1)
				_piece(ctx,o+Vector2(-7+float(i)*7,8-13*u-float(i%2)*4)*s,"feather",s*.65,p,(float(i)-1)*.4,a)
			if t>.6: _piece(ctx,o+Vector2(0,5)*s,"clasp",s*.5,p,0,a)
		"contract_nail_execution":
			_string(ctx,o,d,s,1-q,p,a)
			if t>.22: _piece(ctx,o.lerp(c,q),"nail",s*.9,p,angle,a)
			if t>.48:
				_piece(ctx,c,"clasp",s*.65,p,angle-.45,a)
				_line(ctx,c-d*7*s,c+d*7*s,s,p,a,2)
		"two_caption_stitches":
			_piece(ctx,o,"caption",s*.7,p,-.5+q*.6,a)
			_piece(ctx,o+d*(5+5*q)*s,"needle",s*.5,p,angle,a)
			for i: int in range(2):
				var u := clampf((t-.18-float(i)*.16)/.44,0,1)
				var at := c+Vector2(-9+float(i)*15,-9*(1-u)+float(i)*4)*s
				if t>.18+float(i)*.16:
					_line(ctx,at+Vector2(-3,-3)*s,at+Vector2(3,3)*s,s,p,a,1)
					_piece(ctx,at,"needle",s*.45,p,.65,a*.8)
		"unwritten_curtain_return":
			_piece(ctx,o+Vector2(0,-4*sin(t*PI))*s,"caption",s*.85,p,-.2,a)
			for side: int in [-1,1]:
				var u := clampf((t-.18-(.10 if side==1 else 0.0))/.48,0,1)
				_piece(ctx,c+Vector2(float(side)*(5+8*u),-8*u)*s,"curtain",s*.9,p,float(side)*(.1+u*.3),a)
			if t>.42: _piece(ctx,c+Vector2(0,-4-10*q)*s,"caption",s*.55,p,0,a)
		"weighted_tuning_hook":
			_piece(ctx,o-d*5*(1-q)*s,"clasp",s*.6,p,angle,a)
			var head := o.lerp(c,q)+Vector2(0,5*sin(q*PI))*s
			_piece(ctx,head,"hook",s*.8,p,angle,a)
			for i: int in range(2): _piece(ctx,head-d*(7+float(i)*8)*s,"clasp",s*.35,p,angle+PI*.5,a*.75)
			if t>.57: _line(ctx,c+Vector2(-7,8)*s,c+Vector2(7,8)*s,s,p,a,2)
		"silent_bell_downbeat":
			_piece(ctx,o+Vector2(0,-3)*s,"clasp",s*.6,p,PI*.5,a)
			var drop := clampf((t-.23)/.42,0,1)
			_piece(ctx,c+Vector2(0,-22*(1-drop))*s,"bell",s*(1.15+.3*drop),p,0,a*.8)
			if t>.48:
				for side: int in [-1,1]: _line(ctx,c+Vector2(float(side)*6,9)*s,c+Vector2(float(side)*17,9)*s,s,p,a,2)
			if t>.68:
				for i: int in range(2):
					var fall := clampf((t-.68-float(i)*.08)/.22,0,1)
					Brush.chip(ctx,c+Vector2(-8+float(i)*16,-2+fall*13)*s,Vector2.ONE*s,_color(p,5,a*.7))
## The three quiet_* gestures are design records only, never active casts.
## Persistent buffs/auras, additional chain hits and expiry stay upstream.
