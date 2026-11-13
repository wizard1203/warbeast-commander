extends RefCounted
## Borrowed seals, river carpentry and imperfect navigation glass.
## Observation-only: no clock, RNG, cache, targeting or combat writes.
const Brush = preload("res://src/presentation/m63_av_brush.gd")
const VERSION := "m63-human-av-v1"
const PALETTES := {
	"ledger":["171c23","644349","c78083","73bdb4","fff0c8","d6aa6f","aebeb9"],
	"porcelain":["172026","435e66","84bdc3","d99a77","fff5d9","bca9d2","becab5"],
	"witness":["211b24","6c4252","cc788d","75bdbb","fff0b8","dab66f","b7c5c0"],
	"timber":["1b1b21","624d3e","ba956d","7eafbf","fff0c6","b59ac6","a5b9b3"],
	"iron":["151e26","3c5268","8cabbc","d2a365","fff3ca","b28aab","bec8b3"],
	"pile":["211d27","61516e","ac98c8","c9aa68","fff3cf","84bdb4","a7afb8"],
	"glass":["181c28","51416b","b08bd3","e4b65e","fff7dc","7cc9b5","be9793"],
	"caliper":["151e27","395c70","7bbbd0","ce8fb4","f3ffed","e9bc7b","9caec4"],
	"focus":["171727","4f3c73","a180d7","e7bf62","fff8d8","7fcfcb","cf9ab9"],
	"kite":["17201f","3e5953","83b3a1","d8a579","fff3cb","aa92ce","b7c6c0"],
	"rain":["171e27","40546b","8db8d2","d9ae62","fff0c4","c48eaa","a9b9af"],
	"taut":["211b25","6d3e50","cf7f8c","85b8cf","fff0c0","d1b371","b8c6b9"],
	"ruler":["1b2224","4e6260","a2bdad","c795aa","fff0d1","b9a777","a4b0c3"],
	"clamp":["161e25","44576b","a4b8cc","d88c76","fff4d5","95bfb2","c1ae78"],
	"verdict":["211b25","6b3d4f","c97b92","86becb","fff0ca","b49acb","bca27a"],
	"civilian":["1b211f","665844","baa47b","87b6b1","fff0cb","c3a28d","b5bdb0"],
	"arbalest":["171c23","554a3b","b89c68","91a6af","f6e9c5","6e8395","b4b5a2"],
}
const SHAPES := {
	"fold":[Vector2(-6,-4),Vector2(0,-7),Vector2(7,-3),Vector2(3,1),Vector2(6,5),Vector2(-5,3)],
	"seal":[Vector2(-4,-5),Vector2(3,-5),Vector2(5,-2),Vector2(4,4),Vector2(-4,4)],
	"wedge":[Vector2(-7,3),Vector2(3,-5),Vector2(6,-5),Vector2(6,4),Vector2(-7,4)],
	"mirror":[Vector2(-6,-2),Vector2(-1,-7),Vector2(5,-4),Vector2(7,2),Vector2(0,7),Vector2(-5,4)],
	"arrow":[Vector2(-10,-2),Vector2(4,-2),Vector2(3,-5),Vector2(11,0),Vector2(3,5),Vector2(4,2),Vector2(-10,2),Vector2(-14,5),Vector2(-12,0),Vector2(-14,-5)],
	"ruler":[Vector2(-3,8),Vector2(-3,-8),Vector2(3,-8),Vector2(3,8)],
	"slip":[Vector2(-3,-8),Vector2(4,-8),Vector2(3,5),Vector2(0,9),Vector2(-4,5)],
	"latch":[Vector2(-6,-3),Vector2(3,-3),Vector2(6,0),Vector2(3,3),Vector2(-6,3)],
	"beam":[Vector2(-8,-5),Vector2(6,-5),Vector2(9,-2),Vector2(9,5),Vector2(-8,5)],
	"adze":[Vector2(-5,8),Vector2(-5,-1),Vector2(-9,-2),Vector2(-9,-6),Vector2(7,-6),Vector2(7,-2),Vector2(-1,-1),Vector2(-1,8)],
	"windlass":[Vector2(-7,-3),Vector2(4,-3),Vector2(7,0),Vector2(4,3),Vector2(-2,3),Vector2(-2,6),Vector2(-5,6),Vector2(-5,3),Vector2(-7,3)],
}
## name, silhouette, palette, crest, body-local offset, gesture, sound tuple,
## story, counterplay. Existing bodies and affiliation panels are retained.
const ACTOR_ROWS := {
	"hero:COMMANDER":["绛栖","折页肩旗、腰间铜算盘","ledger",[Vector2(-5,-4),Vector2(5,-4),Vector2(2,0),Vector2(5,4),Vector2(-5,3)],Vector2(-5,-24),"ledger_sweep",["scrape",260,.24,2,"opening_fan",.28,1.8,-.12,.04],"渡口账房借六镇印章；撕图救人后以口述补回河道。","绕过阵线或分割友军，降低护持覆盖。"],
	"hero:BULWARK":["岩岚","低重心闸门盾、铁钩与楔肩","timber",[Vector2(-6,3),Vector2(-2,-4),Vector2(2,-4),Vector2(2,-1),Vector2(6,-1),Vector2(6,4)],Vector2(-5,-20),"gate_hook_pull",["clang",165,.55,1,"falling_weight",.34,2.5,-.28,.09],"架梁棚托梁人；每次防守都给工匠留退路。","绕背和奥术施压，恢复不能取消后续受伤。"],
	"hero:ARCANIST":["星澜","破边镜披肩、半月测角肩架","glass",[Vector2(-6,-3),Vector2(-2,-6),Vector2(4,-5),Vector2(6,0),Vector2(3,5),Vector2(1,1),Vector2(1,-2),Vector2(-3,-1),Vector2(-4,3)],Vector2(5,-25),"mirror_sliver",["bell",820,.12,2,"staggered_reprise",.30,2.7,.18,.12],"河口磨镜师砸碎误导移民船的预言镜，以裂片重新测量。","贴近脆弱施法者，分散减少扇形受击。"],
	"hero:RANGER":["巡翎","分叉纸鸢尾、折弓短披风","kite",[Vector2(-3,-6),Vector2(1,-3),Vector2(5,-6),Vector2(3,0),Vector2(5,6),Vector2(0,3),Vector2(-4,6),Vector2(-2,0)],Vector2(-5,-24),"string_snap",["pluck",430,.21,1,"sharp_cut",.23,1.5,.31,.04],"港区药单信使以纸鸢骨架制弓，随身留着迟到的回信。","逼迫停火或靠近；尾羽不延长射程。"],
	"hero:DUELIST":["砺川","方尺剑、错落印章条、双层短袍","ruler",[Vector2(-6,-3),Vector2(-1,-3),Vector2(-1,1),Vector2(2,1),Vector2(2,-5),Vector2(6,-5),Vector2(6,5),Vector2(-6,5)],Vector2(5,-19),"measured_return",["click",340,.35,3,"gather_and_lock",.26,2.1,-.16,.02],"船厂调解员用未开锋量尺剑守住证人发言。","分割友军阵线；定身不禁止还击。"],
	"hinge_guard":["合页卫","合页肩板、近身短刀与竖盾","iron",[Vector2(-6,-4),Vector2(-1,-4),Vector2(-1,-1),Vector2(2,-1),Vector2(2,-4),Vector2(6,-4),Vector2(6,4),Vector2(2,4),Vector2(2,1),Vector2(-1,1),Vector2(-1,4),Vector2(-6,4)],Vector2(-5,-23),"hinge_snap",["clang",240,.38,2,"sharp_cut",.20,2.2,-.18,.02],"渡桥合页匠轮值上阵，肩上的两叶旧门板仍能闭合。","绕开短兵接敌面，利用护甲克制。"],
	"bright_crossbow":["明契弩兵","横置弩匣、方扣与窄肩","rain",[Vector2(-6,-2),Vector2(-3,-2),Vector2(-3,-5),Vector2(3,-5),Vector2(3,-2),Vector2(6,-2),Vector2(6,2),Vector2(-6,2)],Vector2(4,-22),"catch_release",["click",560,.43,2,"directional_rush",.18,3.0,-.32,.02],"渡口验货员用双扣弩匣记录已交付的短矢。","近身与绕后；横匣不产生多发散射。"],
	"iron_lancer":["重装槊卫","长槊、重甲肩拱与双楔扣","iron",[Vector2(-6,3),Vector2(-4,-3),Vector2(-1,-5),Vector2(1,-1),Vector2(3,-5),Vector2(6,-2),Vector2(6,3)],Vector2(5,-24),"pike_set",["scrape",210,.49,1,"directional_rush",.29,1.7,.12,.05],"河堤执桩队把校直槊杆的双楔带进重装阵线。","法术与机动侧翼；长槊纹样不增加射程。"],
	"grove_mender":["林契医士","罩灯、补瓷线轴与长袍","porcelain",[Vector2(-5,-2),Vector2(-2,-5),Vector2(3,-5),Vector2(6,-1),Vector2(3,3),Vector2(-2,4),Vector2(-5,1)],Vector2(-5,-20),"porcelain_cast",["water",640,.14,3,"woven_drift",.35,1.4,.21,.13],"给河岸病床补瓷的医士以可归还的灯页传递求援。","切断治疗射程；普攻声不表示已产生治疗。"],
	"oath_cavalry":["誓图骑兵","马背短旗、辔绳与骑枪","ledger",[Vector2(-6,-4),Vector2(6,-4),Vector2(2,0),Vector2(6,4),Vector2(-2,3),Vector2(-6,1)],Vector2(4,-22),"bridle_charge",["reed",190,.33,2,"directional_rush",.31,1.8,-.22,.06],"轮值驿骑带着各镇不同旗尾，先打通回家的驿路。","以反骑兵重卫接敌，保护侧翼通路。"],
	"oath_colossus":["誓图重弩军士","轻甲皮衣、钢帽与大型横向机械重弩；架弩后坐、曲柄复位","arbalest",[Vector2(-8,-2),Vector2(-4,-2),Vector2(-4,-5),Vector2(4,-5),Vector2(4,-2),Vector2(8,-2),Vector2(8,2),Vector2(2,2),Vector2(2,5),Vector2(-2,5),Vector2(-2,2),Vector2(-8,2)],Vector2(0,-19),"arbalest_recoil",["click",330,.64,2,"directional_rush",.27,1.8,-.22,.02],"渡桥军械师以绞盘拉弦，在轻甲肩带上留下每次护航的刻记；一支重弩矢拦截地空目标。","绕侧压近远程军士，利用轻甲弱项；单点贯矢没有溅射或额外控制。"],
	"worker:HUMAN":["誓图工人","宽檐帽、围裙与工日木筹","civilian",[Vector2(-5,-3),Vector2(1,-3),Vector2(1,-1),Vector2(5,-1),Vector2(5,3),Vector2(-5,3)],Vector2(-4,-14),"adze_chip",["scrape",310,.69,2,"staggered_reprise",.19,1.3,-.25,.01],"工日可互欠的渡桥工人把木筹缝在围裙侧面。","工人无甲且可被击杀；短劈不替代正规兵。"],
}
## owner, canonical label, gesture, palette, sound tuple, story, counterplay,
## four observed phases, passive. Passive rows never create active casts.
const SKILL_ROWS := {
	"CLEAVE":["COMMANDER","同袍誓约","folded_ledger","ledger",["breath",280,.13,2,"woven_drift",.32,1.4,.08,.06],"欠账折成肩旗，盔甲的共同承诺需在场见证。","分割友军；读取真实被动护甲来源。",["被动，无主动预示","无投递","无伤害命中","既有光环随真实来源结束"],true],
	"RECOVER":["COMMANDER","重整","porcelain_stitch","porcelain",["water",570,.18,3,"inward_return",.66,1.6,.25,.14],"撕掉的航图由青瓷补线缝回，先补活人的伤。","分割受益者并消耗蓝量；不制造假友军连线。",["origin托起补线轴","三枚瓷片从外向内归位","真实受益中心短缝线","瓷线压平；有限护甲仍读真实buff"],false],
	"RALLY":["COMMANDER","盟誓","borrowed_seal_canopy","witness",["choir",350,.22,6,"breathing_lift",1.50,2.0,.18,.23],"六镇借来的铜印依次作证，旗架给伤员留通道。","离开协同覆盖；到期与死亡由既有来源处理。",["origin铜印落下","左右折布收成缺口篷檐","治疗中心抬升短旗","印章条收回；不续护甲"],false],
	"SHIELD_SHOCK":["BULWARK","盾震","inward_gate_reseat","timber",["scrape",180,.53,2,"inward_return",.58,1.8,-.31,.08],"退役闸门重新压住木楔，托梁人由此修复自身。","自我恢复不阻止后续集火。",["origin两楔外张","木楔向自身压入","自身承重扣闭合；HEAL不打敌人","木屑向内沉下"],false],
	"BULWARK_WARD":["BULWARK","护垒","settled_buttress","iron",["clang",140,.32,1,"gather_and_lock",.35,2.4,-.12,.05],"巨盾背后的斜撑长期承重，不靠临时神光。","绕背与奥术；被动不生造施法和时限。",["被动，无主动预示","无投递","无眩晕或伤害","跟随真实常驻被动"],true],
	"BULWARK_RECOVER":["BULWARK","坚守","bridge_pile_drop","pile",["rumble",110,.56,3,"falling_weight",1.35,2.5,-.52,.19],"承重法压成短促止步的桥桩，盾后保留出口。","散开避免区域眩晕；零伤，木桩没有碰撞。",["origin短横梁抬起","中心两短桩错拍落下","局部横栓锁合表示STUN","短桩下沉回收"],false],
	"STARFIRE":["ARCANIST","星火","measured_glass_fan","glass",["bell",970,.12,3,"opening_fan",.62,3.0,.32,.12],"破边航镜校准后把光折成窄扇，拒绝圆形预言。","分散扇面或贴近脆弱施法者。",["origin测角片合准","三片短玻璃沿前向打开","合法中心棱面短光","切口向前收束，无圆爆"],false],
	"FROST_BIND":["ARCANIST","霜契","ankle_calipers","caliper",["bell",730,.08,2,"gather_and_lock",.72,3.4,-.21,.11],"冷镜测角钳合住航线，只约束脚步。","ROOT仍能普攻与施技；不显示眩晕星。",["origin镜片错位测量","标线只连合法中心","低位卡尺闭合，零伤ROOT","钳口退开，无伤害碎裂"],false],
	"ARCANE_BURST":["ARCANIST","星核裁决","broken_lens_focus","focus",["crack",610,.46,4,"gather_and_lock",1.38,3.6,-.44,.21],"砸碎的预言镜在手边聚焦成可测量的光针。","掩护关键单体；折光余像不增加溅射。",["origin裂镜逐片聚焦","一根玻璃针投向单体","单点竖裂棱面，无AOE","裂镜回折；SLOW不画STUN"],false],
	"PIERCING_SHOT":["RANGER","贯弦","kite_string_lance","kite",["pluck",455,.27,2,"directional_rush",.54,1.5,.44,.05],"药单纸鸢绷成直线，先看拉弦再看一支箭。","从窄射线两侧分散；箭尾不增加线宽。",["origin短弦后拉","单一羽矛沿直线投递","中心短切口；其余真实命中归原连接器","origin纸鸢尾反弹折回"],false],
	"ARROW_RAIN":["RANGER","箭雨","rain_stake_score","rain",["reed",520,.36,5,"staggered_reprise",.76,1.9,-.24,.13],"药单纸鸢短抬后垂下雨箭，节奏来自赶路的雨。","离开实际区域；图案不增加目标或跳伤。",["origin小纸鸢抬升","中心三短箭错拍下降","局部箭脚落定，无完整弓","折尾消散，无持久地形"],false],
	"QUICKDRAW":["RANGER","追风齐射","self_returning_kite","taut",["pluck",390,.18,5,"breathing_lift",1.48,1.7,.28,.16],"迟到回信随纸鸢尾展开，绷紧弦翼留在自己身边。","逼迫停火或撤离；强化到期读真实来源。",["origin折翼展开","自身两侧张弦","只有自身回弹，无敌方命中","折翼收回；不代替真实强化到期"],false],
	"SEAL_STRIKE":["DUELIST","止戈步调","measured_march","ruler",["click",290,.25,3,"woven_drift",.30,1.3,.04,.02],"起重队的行阵口令让证人跟上队伍。","切断阵线；无光环外受益或额外斩伤。",["被动，无主动预示","无投递","无封刃伤害命中","既有光环根据来源结束"],true],
	"WHIRLWIND":["DUELIST","回旋","witness_blade_stop","clamp",["click",310,.47,3,"gather_and_lock",.64,2.8,-.34,.03],"量尺剑先截断对手动作，再让证人说话。","单体掩护；零伤STUN不是旋风斩。",["origin尺剑测长","小印送至合法中心","高位两短尺交锁，STUN","印条收回，无区域旋斩"],false],
	"BLOOD_PACT":["DUELIST","血契","unrolled_witness_slips","verdict",["scrape",230,.41,6,"woven_drift",1.55,1.6,-.17,.18],"停战条款化为留缺口的纸条，限制离开却允许还击。","ROOT仍能还击；纸条无伤害或实体阻挡。",["origin小卷页横开","三纸签依次落到中心低位","缺口脚边折尺表示ROOT","纸条向内卷回，无刀刃爆裂"],false],
}

static func _sound(row: Array) -> Dictionary:
	return {"voice":str(row[0]),"frequency":float(row[1]),"texture":float(row[2]),"pulses":int(row[3]),"rhythm":str(row[4]),"seconds":float(row[5]),"overtone":float(row[6]),"sweep":float(row[7]),"echo":float(row[8])}

static func actors() -> Dictionary:
	var result := {}
	for identity: String in ACTOR_ROWS: result[identity] = actor_profile(identity)
	return result.duplicate(true)

static func actor_profile(identity: String) -> Dictionary:
	if not ACTOR_ROWS.has(identity): return {}
	var r: Array = ACTOR_ROWS[identity]
	return {"identity":identity,"faction_id":"HUMAN","name":r[0],"silhouette":r[1],"palette":PALETTES[str(r[2])].duplicate(true),"crest":r[3].duplicate(true),"crest_offset":r[4],"gesture":r[5],"sound":_sound(r[6]),"story_anchor":r[7],"counterplay":r[8],"body_change":"v3_authored_body_equipment_crest" if identity=="oath_colossus" else "preserved_body_small_equipment_crest","identity_version":"outposts-v3-unit-av-v1" if identity=="oath_colossus" else VERSION}.duplicate(true)

static func skills() -> Dictionary:
	var result := {}
	for skill_id: String in SKILL_ROWS: result[skill_id] = skill_profile(skill_id)
	return result.duplicate(true)

static func skill_profile(skill_id: String) -> Dictionary:
	if not SKILL_ROWS.has(skill_id): return {}
	var r: Array = SKILL_ROWS[skill_id]
	var labels := {"CLEAVE":"协战光环","RECOVER":"誓图重整","RALLY":"守望盟誓","SHIELD_SHOCK":"盾心恢复","BULWARK_WARD":"不屈甲胄","BULWARK_RECOVER":"垒盾震慑","SEAL_STRIKE":"行阵光环","WHIRLWIND":"封刃震","BLOOD_PACT":"止戈令"}
	return {"skill_id":skill_id,"hero_id":r[0],"faction_id":"HUMAN","name":labels.get(skill_id,r[1]),"gesture":r[2],"palette":PALETTES[str(r[3])].duplicate(true),"sound":_sound(r[4]),"story_anchor":r[5],"counterplay":r[6],"phases":r[7].duplicate(true),"passive":bool(r[8]),"identity_version":VERSION}.duplicate(true)

static func _color(p: Array, slot: int, alpha: float) -> Color:
	return Color(str(p[slot]),clampf(alpha,0,1))

static func _piece(ctx: Dictionary, at: Vector2, shape: String, s: float, p: Array, angle: float, alpha: float) -> void:
	Brush.stamp(ctx,at,SHAPES[shape],s,p,angle,alpha)

static func _line(ctx: Dictionary, from: Vector2, to: Vector2, s: float, p: Array, a: float, width: float = 2.0) -> void:
	Brush.streak(ctx,from,to,(width+2)*s,_color(p,0,a))
	Brush.streak(ctx,from,to,width*s,_color(p,3,a))

static func _string(ctx: Dictionary, hand: Vector2, d: Vector2, s: float, tension: float, p: Array, a: float) -> void:
	var n := d.orthogonal()
	var notch := hand-d*(3+tension*8)*s
	_line(ctx,hand+n*8*s,notch,s,p,a,1)
	_line(ctx,notch,hand-n*8*s,s,p,a,1)

static func draw_signature(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, spec: Dictionary) -> void:
	var t := float(ctx.get("phase",-1))
	if not is_finite(t) or t<0 or t>=1 or not is_finite(scale) or scale<=0: return
	if bool(spec.get("passive",false)): return
	var p: Array = spec.get("palette",[])
	if p.size()!=7: return
	var old_limit := int(ctx.get("draw_limit",0))
	ctx.draw_limit = mini(old_limit,int(ctx.get("count",0))+(36 if bool(spec.get("is_skill",false)) else 24))
	var d := (center-origin).normalized()
	if d.length_squared()<.1: d=Vector2.RIGHT
	var q := clampf((t-.22)/.44,0,1)
	var a := clampf(sin(t*PI)*1.35,0,1)
	var hand := origin+Vector2(0,-8)*scale
	if bool(spec.get("is_skill",false)):
		_draw_skill(ctx,origin,center,hand,d,d.orthogonal(),d.angle(),scale,t,q,a,p,str(spec.get("gesture","")))
	else:
		_draw_actor(ctx,origin,center,hand,d,d.orthogonal(),d.angle(),scale,t,q,a,p,str(spec.get("gesture","")))
	ctx.draw_limit=old_limit

static func _draw_actor(ctx: Dictionary, origin: Vector2, center: Vector2, hand: Vector2, d: Vector2, n: Vector2, angle: float, s: float, t: float, q: float, a: float, p: Array, gesture: String) -> void:
	match gesture:
		"ledger_sweep":
			_piece(ctx,hand+Vector2(-6,-4)*s,"fold",s,p,-.6+q,a)
			_line(ctx,hand,hand+d*(8+12*sin(t*PI))*s,s,p,a)
			if t>.40 and t<.72: _piece(ctx,hand+d*20*s,"seal",s*.55,p,angle,a)
		"gate_hook_pull":
			_piece(ctx,hand+d*(5+9*q)*s,"wedge",s,p,angle+.25*(1-q),a)
			_line(ctx,hand-n*5*s,hand+d*13*s+n*4*s,s,p,a,3)
		"mirror_sliver":
			_piece(ctx,hand,"mirror",s*.65,p,-.4+q*.9,a)
			_piece(ctx,hand.lerp(center,q),"mirror",s*.45,p,angle+q,a)
		"string_snap":
			_string(ctx,hand,d,s,1-q,p,a)
			if t>.25: _piece(ctx,hand.lerp(center,q),"arrow",s*.60,p,angle,a)
		"measured_return":
			_piece(ctx,hand+d*(7+12*sin(t*PI))*s,"ruler",s,p,angle-.7+1.4*q,a)
			_piece(ctx,hand+n*5*s,"slip",s*.55,p,-.2-q*.4,a*.8)
		"hinge_snap":
			_piece(ctx,hand+n*4*s,"latch",s,p,angle+.6*(1-q),a)
			_piece(ctx,hand-n*4*s,"latch",s*.8,p,angle-.6*(1-q),a)
		"catch_release":
			_line(ctx,hand-n*7*s,hand+n*7*s,s,p,a,3)
			_piece(ctx,hand-d*4*(1-q)*s,"latch",s*.8,p,angle,a)
			if t>.32: _line(ctx,hand.lerp(center,q)-d*8*s,hand.lerp(center,q)+d*5*s,s,p,a,2)
		"pike_set":
			_line(ctx,hand-d*7*s,hand+d*(12+22*sin(t*PI))*s,s,p,a)
			_piece(ctx,hand+d*(13+22*sin(t*PI))*s,"wedge",s*.6,p,angle,a)
		"porcelain_cast":
			_piece(ctx,hand,"seal",s*.65,p,-.25,a)
			_piece(ctx,hand.lerp(center,q)+Vector2(0,-sin(q*PI)*12)*s,"fold",s*.65,p,q*.5,a)
		"bridle_charge":
			_piece(ctx,hand-d*8*s+n*5*s,"fold",s,p,angle-.7-q*.5,a)
			_line(ctx,hand-d*10*s,hand+d*(14+24*q)*s,s,p,a,2)
		"beam_drop":
			var at := hand+d*12*s+Vector2(0,-15*(1-q))*s
			_piece(ctx,at,"beam",s*1.15,p,angle-.5+q*.7,a)
			if t>.56:
				_line(ctx,at,at+Vector2(0,12)*s,s,p,a,4)
				_piece(ctx,at+Vector2(-8,10)*s,"wedge",s*.5,p,0,a*.7)
		"arbalest_recoil":
			# Broad horizontal limbs and a winding latch recoil at the hand;
			# the single travelling quarrel stays in WeaponArt.OATH_ARBALEST.
			var breech:=hand-d*(7*(1-q))*s
			_piece(ctx,breech,"windlass",s*.78,p,angle,a)
			_line(ctx,breech-n*11*s,breech+n*11*s,s,p,a,2)
			_line(ctx,breech-n*11*s,breech+d*(4+5*q)*s,s,p,a,1)
			_line(ctx,breech+n*11*s,breech+d*(4+5*q)*s,s,p,a,1)
			if t>.3 and t<.74:_piece(ctx,breech-d*10*s+n*5*s,"latch",s*.35,p,angle+q,a*.8)
		"adze_chip":
			_piece(ctx,hand+d*8*s,"adze",s*.85,p,-1+q*1.5,a)
			if t>.52 and t<.83: _piece(ctx,hand+d*13*s+n*4*s,"wedge",s*.4,p,q,a*.7)

static func _draw_skill(ctx: Dictionary, origin: Vector2, center: Vector2, hand: Vector2, d: Vector2, n: Vector2, angle: float, s: float, t: float, q: float, a: float, p: Array, gesture: String) -> void:
	match gesture:
		"porcelain_stitch":
			_piece(ctx,hand+Vector2(-5,-5*(1-q))*s,"seal",s*.8,p,-.4+q*.5,a)
			for i: int in range(3):
				var u := clampf((t-.15-float(i)*.11)/.55,0,1)
				_piece(ctx,center+Vector2((float(i)-1)*16,-15-float(i%2)*8)*s*(1-u),"slip",s*.55,p,-.6+float(i)*.5,a)
			if t>.52: _line(ctx,center+Vector2(-7,-1)*s,center+Vector2(6,-4)*s,s,p,a,1)
		"borrowed_seal_canopy":
			_piece(ctx,hand+Vector2(0,-5+8*q)*s,"seal",s*.85,p,0,a)
			for i: int in range(3):
				var u := clampf((t-.18-float(i)*.08)/.48,0,1)
				_piece(ctx,center+Vector2((float(i)-1)*(20-7*u),-6-15*u)*s,"fold",s*(.65+u*.3),p,(float(i)-1)*.2,a)
			if t>.45: _line(ctx,center+Vector2(-20,-21)*s,center+Vector2(16,-21)*s,s,p,a,2)
		"inward_gate_reseat":
			for sign: int in [-1,1]: _piece(ctx,origin+Vector2(float(sign)*(19-13*q),-7+q*3)*s,"wedge",s,p,0 if sign==1 else PI,a)
			if t>.42:
				_piece(ctx,origin+Vector2(0,-8)*s,"latch",s,p,PI*.5,a)
				_line(ctx,origin+Vector2(-9,1)*s,origin+Vector2(8,1)*s,s,p,a,2)
		"bridge_pile_drop":
			_piece(ctx,hand+Vector2(0,-12*(1-q))*s,"beam",s*.85,p,-.2*(1-q),a)
			for i: int in range(2):
				var u := clampf((t-.23-float(i)*.12)/.42,0,1)
				_piece(ctx,center+Vector2(-13+float(i)*26,-29*(1-u))*s,"beam",s*.8,p,PI*.5,a)
			if t>.60: _line(ctx,center+Vector2(-14,-4)*s,center+Vector2(14,-4)*s,s,p,a,4)
		"measured_glass_fan":
			_piece(ctx,hand,"mirror",s*.9,p,-.3+q*.6,a)
			for i: int in range(3):
				var lane := float(i)-1
				_piece(ctx,hand.lerp(center,q)+n*lane*15*q*s,"mirror",s*.6,p,angle+lane*(.15+q*.45),a)
			if t>.62: _line(ctx,center-d*8*s,center+d*7*s,s,p,a,1)
		"ankle_calipers":
			for sign: int in [-1,1]: _piece(ctx,hand+n*float(sign)*5*s,"mirror",s*.45,p,float(sign)*(.6-q*.3),a)
			if t>.22 and t<.55: _line(ctx,hand,hand.lerp(center,q),s,p,a*.65,1)
			for sign: int in [-1,1]: _piece(ctx,center+Vector2(float(sign)*(18-11*q),7)*s,"latch",s*.8,p,0 if sign==1 else PI,a)
		"broken_lens_focus":
			for i: int in range(3): _piece(ctx,hand+Vector2((float(i)-1)*(14-9*q),-12*(1-q)-float(i%2)*5)*s,"mirror",s*.7,p,(float(i)-1)*(.7-q*.4),a)
			if t>.29 and t<.74:
				var head := hand.lerp(center,q)
				_line(ctx,head-d*14*s,head+d*9*s,s,p,a,3)
			if t>.62:
				_piece(ctx,center,"mirror",s*(1.6-q*.55),p,PI*.25,a)
				_line(ctx,center+Vector2(0,-13)*s,center+Vector2(0,9)*s,s,p,a,2)
		"kite_string_lance":
			_string(ctx,hand,d,s,1-q,p,a)
			_piece(ctx,hand-d*8*s+n*7*s,"fold",s*.6,p,angle-.5+q*.9,a)
			if t>.22 and t<.82: _piece(ctx,hand.lerp(center,q),"arrow",s*.9,p,angle,a)
			if t>.64: _line(ctx,center-d*7*s,center+d*5*s,s,p,a,1)
		"rain_stake_score":
			_piece(ctx,hand+Vector2(0,-14*sin(t*PI))*s,"fold",s*.8,p,-.5+q*.7,a)
			for i: int in range(3):
				var u := clampf((t-.24-float(i)*.13)/.40,0,1)
				if t>.24+float(i)*.13: _piece(ctx,center+Vector2((float(i)-1)*13,-34*(1-u)+3)*s,"arrow",s*.55,p,PI*.5,a)
		"self_returning_kite":
			for sign: int in [-1,1]:
				var at := origin+Vector2(float(sign)*(8+13*sin(t*PI)),-12-5*sin(t*PI))*s
				_piece(ctx,at,"fold",s,p,float(sign)*(.15+q*.7),a)
				_line(ctx,hand,at,s,p,a*.8,1)
			_string(ctx,hand,d,s,sin(t*PI),p,a)
		"witness_blade_stop":
			_piece(ctx,hand+d*(4+5*q)*s,"ruler",s*.8,p,angle-.4+q*.4,a)
			if t<.62: _piece(ctx,hand.lerp(center,q),"seal",s*.55,p,0,a)
			if t>.38:
				for sign: int in [-1,1]: _piece(ctx,center+Vector2(float(sign)*5,-12)*s,"ruler",s*.85,p,float(sign)*(.8-.4*q),a)
		"unrolled_witness_slips":
			_piece(ctx,hand,"slip",s,p,PI*.5,a)
			for i: int in range(3):
				var u := clampf((t-.17-float(i)*.12)/.50,0,1)
				_piece(ctx,center+Vector2((float(i)-1)*17,8-27*(1-u))*s,"slip",s*.85,p,(float(i)-1)*(.3-.15*q),a)
			if t>.50:
				_line(ctx,center+Vector2(-22,9)*s,center+Vector2(-7,9)*s,s,p,a,2)
				_line(ctx,center+Vector2(7,9)*s,center+Vector2(22,9)*s,s,p,a,2)
## folded_ledger / settled_buttress / measured_march intentionally do not
## draw active casts. Existing aura source, death and expiry remain upstream.
