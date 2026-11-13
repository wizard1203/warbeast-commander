extends RefCounted
## Authored pixel equipment and event-bound choreography for the exit commons.
## Existing arthropod/reptile bodies stay in their production sprite pipeline.
## This module owns no combat values, clock, targets, cache or random source.
const Brush = preload("res://src/presentation/m63_av_brush.gd")
const VERSION := "m63-underground-av-v1"
const PALETTES := {
	"clay":["231f1b","655347","af9876","8cbbb0","fff0c9","c58673","aab4a2"],
	"shell":["1c2422","435e57","89aaa0","d3a36c","f5edca","9c8bba","c7c2a6"],
	"echo":["1b222a","3d586c","82b7cf","e1b66c","f8f7de","be94bc","bac9bf"],
	"prism":["221e2b","584866","a697c7","82c7c6","fff3cf","dc986f","c6bb9d"],
	"blade":["262021","70504a","be8e76","85bdb3","fff0cd","ad97bf","c9cbb9"],
	"molt":["1d2723","486651","94ba8b","d28e77","fff2c6","a69ac8","c5b278"],
	"sieve":["222322","576249","a8bc83","cd926f","fff5cf","98b9c6","c7baa3"],
	"canopy":["21232a","4a5d69","89b2bd","dca986","fff0cb","b5a1c1","c8be9f"],
	"slate":["24211d","6c5a46","b49c73","a9b9bb","fff1d0","b69aaa","bfc8ba"],
	"fault":["272022","66505a","b5949b","cfb56e","fff1cf","8ababb","bbb7c4"],
	"reed":["1d2525","486365","88b6ac","d2b478","f6f0d7","b39dc2","bcc5b3"],
	"rider":["242125","575360","a49aa7","d5b46f","fff0ca","8eb8b0","c2beb1"],
	"abyss":["241d22","62434d","ad7988","b5bfa0","fff0ce","cd9a6f","b8bdc9"],
	"worker":["25221c","655b41","aca47a","88bab3","fff0c9","c59684","b6c0ab"],
}
const SHAPES := {
	"spade":[Vector2(-6,-9),Vector2(5,-9),Vector2(6,-2),Vector2(2,2),Vector2(2,11),Vector2(-2,11),Vector2(-2,2),Vector2(-6,-2)],
	"plate":[Vector2(-9,-4),Vector2(-4,-8),Vector2(5,-7),Vector2(9,-2),Vector2(7,6),Vector2(-6,6),Vector2(-9,2)],
	"crystal":[Vector2(-11,-2),Vector2(1,-3),Vector2(6,-7),Vector2(13,0),Vector2(5,6),Vector2(1,2),Vector2(-11,2)],
	"prism":[Vector2(-5,-8),Vector2(2,-10),Vector2(6,-2),Vector2(3,8),Vector2(-4,5)],
	"blade":[Vector2(-9,6),Vector2(-6,-1),Vector2(5,-9),Vector2(13,-6),Vector2(13,0),Vector2(6,-3),Vector2(-1,2),Vector2(-4,8)],
	"husk":[Vector2(-8,4),Vector2(-5,-6),Vector2(2,-9),Vector2(8,-4),Vector2(7,5),Vector2(2,8),Vector2(3,0),Vector2(-2,-3),Vector2(-4,5)],
	"sieve":[Vector2(-8,-7),Vector2(7,-7),Vector2(10,-2),Vector2(7,3),Vector2(2,5),Vector2(2,12),Vector2(-2,12),Vector2(-2,5),Vector2(-7,2),Vector2(-10,-2)],
	"spore":[Vector2(-3,-4),Vector2(2,-5),Vector2(4,0),Vector2(1,5),Vector2(-3,2)],
	"cap":[Vector2(-12,1),Vector2(-7,-5),Vector2(0,-8),Vector2(9,-4),Vector2(13,1),Vector2(8,4),Vector2(5,2),Vector2(1,4),Vector2(-3,2),Vector2(-7,4)],
	"pick":[Vector2(-11,-4),Vector2(-6,-9),Vector2(4,-9),Vector2(11,-3),Vector2(2,-4),Vector2(2,11),Vector2(-2,11),Vector2(-2,-4)],
	"slab":[Vector2(-8,-3),Vector2(3,-5),Vector2(9,-1),Vector2(7,4),Vector2(-7,4)],
	"fork":[Vector2(-9,-6),Vector2(-5,-6),Vector2(-3,-1),Vector2(4,-1),Vector2(6,-5),Vector2(10,-5),Vector2(7,3),Vector2(-5,3)],
	"jaw":[Vector2(-10,-5),Vector2(8,-5),Vector2(12,1),Vector2(7,1),Vector2(5,5),Vector2(1,1),Vector2(-1,4),Vector2(-4,0),Vector2(-9,0)],
	"dart":[Vector2(-10,-1),Vector2(3,-1),Vector2(3,-4),Vector2(11,0),Vector2(3,4),Vector2(3,1),Vector2(-10,1)],
}
## name, two non-colour cues, material, small body-local crest, offset,
## implemented attack/work gesture, nine-field sound tuple, story, counterplay.
const ACTOR_ROWS := {
	"hero:TUNNEL_SENTINEL":["壳巢","中空站台背甲、前宽节足与宽铲","shell",[Vector2(-6,3),Vector2(-6,-2),Vector2(-3,-5),Vector2(3,-5),Vector2(6,-2),Vector2(6,3),Vector2(2,3),Vector2(2,-1),Vector2(-2,-1),Vector2(-2,3)],Vector2(-3,-22),"shell_scoop",["scrape",180,.59,2,"inward_return",.34,1.7,-.27,.06],"背走祖传石门的搬巢壳车；甲壳是可离开的车站。","绕侧施压，修壳不能阻止后续集火。"],
	"hero:ECHO_BINDER":["回声","偏心晶耳、开裂共鸣杖与短触须","echo",[Vector2(-6,1),Vector2(-3,-5),Vector2(1,-6),Vector2(1,-1),Vector2(6,-3),Vector2(5,4),Vector2(0,2),Vector2(-3,5)],Vector2(5,-25),"echo_lance",["bell",820,.12,2,"staggered_reprise",.28,2.8,.22,.12],"烧掉完美地图后，开始为隔墙微弱求救留白。","贴近脆弱的晶听者；分散限制连锁。"],
	"hero:SPORE_STALKER":["孢纹","大小矿刃、菌纹试剂臂与片状护目壳","blade",[Vector2(-6,4),Vector2(-4,-2),Vector2(1,-5),Vector2(6,-4),Vector2(3,0),Vector2(0,-1),Vector2(-2,3)],Vector2(-5,-21),"mantis_sidecut",["scrape",370,.69,2,"sharp_cut",.23,2.2,.38,.02],"用感染手臂的记录推翻污染矿单的验脉者。","控制其强化窗口，留意近身短刃；她仍会受伤。"],
	"hero:SPORE_GUIDE":["菌灯","分格菌罐、长柄筛勺与菌褶灯帽","sieve",[Vector2(-6,1),Vector2(-4,-3),Vector2(0,-5),Vector2(5,-2),Vector2(6,1),Vector2(3,4),Vector2(0,2),Vector2(-3,4)],Vector2(4,-21),"sieve_dry_cast",["breath",540,.24,3,"woven_drift",.36,1.4,.13,.10],"撤回同化地方风味的酵种，逐户归还老菌的酿师。","切开支援覆盖，迫使治疗者移动并消耗蓝量。"],
	"hero:QUAKE_PRIEST":["岩祷","错层石册、钝头短镐与断层印","slate",[Vector2(-6,-3),Vector2(2,-3),Vector2(2,-5),Vector2(6,-5),Vector2(6,1),Vector2(3,1),Vector2(3,4),Vector2(-4,4),Vector2(-4,1),Vector2(-6,1)],Vector2(-4,-22),"fault_pick_tap",["rumble",125,.48,2,"staggered_reprise",.38,1.9,-.23,.07],"亲手敲碎压住新水脉的旧边石，让通行权可被重写。","ROOT仍能攻击；分散与冷却空档减轻控场。"],
	"chitin_guard":["甲壳卫","短前足撑盾、三节背甲与锯齿壳沿","shell",[Vector2(-6,-3),Vector2(-2,-3),Vector2(-2,-5),Vector2(2,-3),Vector2(6,-3),Vector2(5,4),Vector2(0,6),Vector2(-5,4)],Vector2(4,-20),"chitin_ram",["clang",235,.39,1,"gather_and_lock",.22,2.4,-.16,.02],"搬巢护送队以自身壳层轮值守住出口。","绕开近战接敌面，以克制甲类处理。"],
	"echo_shooter":["回声射手","横开双叉声架、单晶短矢与窄背壳","reed",[Vector2(-6,-4),Vector2(-3,-4),Vector2(-1,0),Vector2(2,0),Vector2(3,-4),Vector2(6,-4),Vector2(4,4),Vector2(-4,4)],Vector2(4,-22),"reed_dart",["pluck",610,.31,1,"directional_rush",.19,1.6,.40,.05],"矿道报距员用叉架校准实物晶矢；回声不是全知侦测。","贴近轻装射手，叉架不增加射程或散射。"],
	"tunnel_rider":["洞穴蜥骑","低伏六足蜥、节尾与岔形鞍架","rider",[Vector2(-6,4),Vector2(-5,-3),Vector2(-2,-5),Vector2(0,-1),Vector2(3,-5),Vector2(6,-3),Vector2(5,4),Vector2(2,2),Vector2(-2,2)],Vector2(-3,-18),"lizard_prod",["reed",205,.43,2,"directional_rush",.31,1.8,-.34,.04],"共享出口的驮运蜥队改用有退路的岔鞍执行侧翼护送。","以反骑兵接敌并守侧翼；没有穿墙或潜地。"],
	"spore_mender":["孢织者","双室腰罐、Y形菌针与低菌帽","canopy",[Vector2(-5,-4),Vector2(-1,-4),Vector2(-1,-1),Vector2(2,-1),Vector2(2,-5),Vector2(5,-5),Vector2(5,4),Vector2(-5,4)],Vector2(-4,-18),"culture_spindle",["water",650,.15,3,"inward_return",.35,1.3,.19,.09],"采不同菌室的样本再分配，不把支援写成同一种毒法。","切断治疗距离；孢压易感仍以真实施放和来源为准。"],
	"abyss_devourer":["深渊噬兽","巨大节足身、分叉颚板与四齿喉护","abyss",[Vector2(-7,-4),Vector2(7,-4),Vector2(6,3),Vector2(3,0),Vector2(1,5),Vector2(-1,1),Vector2(-4,4),Vector2(-5,0),Vector2(-7,2)],Vector2(3,-17),"abyss_jaw",["crack",95,.81,3,"falling_weight",.40,3.1,-.48,.14],"深层运输群训练的大型追猎兽，以有缺口的颚护辨认同伴。","甲类克制与集火；低血增伤不等于直接处决。"],
	"worker:UNDERGROUND":["穴鸣工人","短触须、侧罐孢灯与宽口劳动铲","worker",[Vector2(-5,-3),Vector2(3,-3),Vector2(5,-1),Vector2(3,3),Vector2(0,4),Vector2(-4,2)],Vector2(-4,-14),"worker_scoop",["scrape",290,.73,2,"staggered_reprise",.20,1.2,-.29,.01],"出口共同体轮值修道者，短柄铲留下真实劳动而非螳刃攻击。","工人可被击杀、无甲；短铲不替代正规兵。"],
}
## owner, final canonical name, implemented gesture, palette, sound, story,
## counterplay, four event-bound phases, passive. No numerical combat authority.
const SKILL_ROWS := {
	"TUNNEL_SHOCK":["TUNNEL_SENTINEL","孢壳重整","inward_shell_patch","clay",["scrape",165,.62,3,"inward_return",.63,1.5,-.34,.07],"宽铲把泥壳压回旧门裂隙，保护是让幼群可以离开。","SELF自疗可净化持续伤害；后续集火仍有效。",["手边宽铲与两片壳沿分开","泥片向自身内压","自身接缝闭合，HEAL无敌方受击","泥屑短落并收铲；不增护盾"],false],
	"TUNNEL_WARD":["TUNNEL_SENTINEL","穴甲外壳","quiet_station_shell","shell",["click",145,.28,1,"gather_and_lock",.24,1.7,-.10,.03],"中空站台的壳页重叠，护住可退出的公共车站。","常驻学习被动与有条件合阵光环读真实来源。",["被动，无主动预示","无投递","无命中或计时强化","随真实被动/光环条件结束"],true],
	"TUNNEL_MEND":["TUNNEL_SENTINEL","穴鸣禁足","evacuation_berm_fan","clay",["rumble",105,.65,4,"opening_fan",1.56,2.1,-.49,.18],"旧门成为可携带的庇护；宽铲将撤离通道外的碎壳扬成土脊。","扇面伤害与ROOT；散开或侧移，土脊无碰撞。",["宽铲贴地后压","三短土页沿前向展开","合法中心低土脊错层合拢，ROOT非STUN","碎壳平落；不造墙或追加伤害"],false],
	"ECHO_BIND":["ECHO_BINDER","声纹缚","folded_echo_knots","echo",["bell",760,.14,3,"staggered_reprise",.73,2.6,-.17,.14],"杂乱回声折成可交接的节点，细小声音也算生命证据。","真实连锁ROOT与有限毒伤；分散限制后续命中。",["手边晶矛双叉试音","折角短声带递至首个合法中心","低位晶扣锁足；其余真实连锁由结算连接器画","晶尘向内回收，不假造额外目标"],false],
	"ECHO_FLARE":["ECHO_BINDER","晶鸣","narrow_crystal_refraction","echo",["pluck",980,.21,2,"directional_rush",.57,3.1,.51,.08],"开裂共鸣杖把时差排成一条窄晶线，而非铺成统一毒雾。","窄直线伤害与有限毒伤；从两侧避开。",["手边两片晶棱排齐","单一窄晶矛沿权威方向前送","中心晶棱折成侧碎片，不增加线宽","两片小晶尘侧落，不新结算"],false],
	"ECHO_OATH":["ECHO_BINDER","晶核坍缩","single_prism_implosion","prism",["crack",570,.44,4,"gather_and_lock",1.43,3.5,-.58,.23],"被烧掉地图的空白在一处收拢，放弃把整层洞群抹成同一答案。","单体伤害及有限毒伤；棱片内塌无吸引或溅射。",["手边三小晶棱错位蓄势","一枚空心晶矛前送","合法单体的三片不对称晶棱向内坍缩","亮核缩成砂，不画外扩爆圈"],false],
	"SPORE_SEAL":["SPORE_STALKER","隙刃封","asymmetric_joint_clamp","blade",["click",330,.52,3,"gather_and_lock",.61,2.4,-.31,.03],"小刃佯动、大刃钳住关节；感染的记录并非滥杀理由。","纯单体STUN零伤无毒；掩护被锁对象并抓冷却。",["手边一大一小矿刃张开","两刃向合法单体上部合拢","高位钳口闭锁表示STUN，无刃伤爆点","钳口松开与收刃，不画毒雾"],false],
	"SPORE_SWEEP":["SPORE_STALKER","孢纹回旋","mining_side_crosscut","blade",["scrape",410,.76,2,"sharp_cut",.47,2.1,.47,.02],"试剂臂指示单处薄弱面，两把矿刃依次剪切。","单体边刃伤害与处决增伤；无全周旋风。",["短刃退到身侧校准","大刃横侧切后小刃反向收口","单体中心两道短切口，非圆环","一片蜕壳侧落，刃回原位"],false],
	"SPORE_MEND":["SPORE_STALKER","裂隙追猎","self_mantis_molt","molt",["buzz",265,.36,6,"woven_drift",1.64,1.8,.24,.13],"菌纹臂记录感官适应；不靠无敌或消失证明变种的价值。","SELF普攻/攻速强化；控制或脱离其有限窗口。",["自身试剂臂两处亮纹","不等大壳套沿双刃滑开","只有自身错位蜕壳，绝无敌方受击","壳套轻收；持续效果读真实source buff"],false],
	"SPORE_GLOW":["SPORE_GUIDE","菌光光环","quiet_partition_lamps","sieve",["breath",460,.10,2,"breathing_lift",.28,1.3,.08,.07],"各菌室保留不同风味，分格罐缝发出低辉。","学习治疗光环按来源/范围失效；不伪造主动治疗。",["被动，无主动预示","无投递","不生成假治疗命中","随真实光环来源与范围结束"],true],
	"SPORE_REMEDY":["SPORE_GUIDE","孢疗","sieved_gentle_fall","sieve",["water",625,.16,4,"breathing_lift",.77,1.4,.20,.15],"分格菌罐经长柄筛勺分配共生物，而非把所有病床染成一色。","有限受益者治疗/净化；切断支援覆盖。",["手边筛勺轻倾露出孔隙","三束孢粒柔落至真实治疗中心","低位菌丝短缝下沉，无敌人毒伤","尾粒慢落；不造持续治疗区"],false],
	"SPORE_HAVEN":["SPORE_GUIDE","菌丝庇所","porous_cap_unfold","canopy",["breath",385,.23,7,"opening_fan",1.83,1.6,.16,.22],"彼此留缺口的菌伞让共同体有共享余粮，也有独自离开的路。","真实群疗/净化及有限移速；不复活或攻击强化。",["手边分格罐如折扇张开","中心菌伞错层展开，孔间留白","治疗中心孢束下落，不假画新受益者","菌伞由边缘折回；增速到期读真实来源"],false],
	"QUAKE_RHYTHM":["QUAKE_PRIEST","穴音光环","quiet_stone_metronome","slate",["click",185,.36,2,"staggered_reprise",.26,1.6,-.12,.03],"层页石册记录路权，节拍里给异乡人留下空位。","学习移速光环；不制造传送或主动地震。",["被动，无主动预示","无投递","无伤害/控制命中","随真实光环来源与范围结束"],true],
	"QUAKE_SNARE":["QUAKE_PRIEST","地鸣缚","three_low_fault_clamps","slate",["rumble",115,.41,3,"gather_and_lock",.79,1.8,-.24,.11],"旧界石短错位，暂停脚步以确认通行权。","纯区域ROOT零伤无毒；仍能攻击/施技，净化不触发余震。",["手边钝镐轻敲石页","低位三片短层页横移","脚边错层夹缝闭合，ROOT不用头顶星","白缝缓收、石页下沉，无伤害爆裂"],false],
	"QUAKE_SEAL":["QUAKE_PRIEST","断层封印","boundary_slabs_inward","fault",["rumble",85,.70,5,"falling_weight",1.93,2.5,-.61,.26],"敲碎旧边石后重新排定通路，岩页的重量留下有限余震。","真实区域伤害/ROOT及有限毒伤；分散，岩页不封路。",["手边石册打开三页","三片错层岩页从低位向中心收拢","合法中心断层白缝错拍压合，粒尘只表达既有DoT","岩页分级下沉，不生成永久区域或额外伤害跳"],false],
}

static func _sound(r: Array) -> Dictionary:
	return {"voice":str(r[0]),"frequency":float(r[1]),"texture":float(r[2]),"pulses":int(r[3]),"rhythm":str(r[4]),"seconds":float(r[5]),"overtone":float(r[6]),"sweep":float(r[7]),"echo":float(r[8])}

static func actors() -> Dictionary:
	var result := {}
	for identity: String in ACTOR_ROWS: result[identity]=actor_profile(identity)
	return result.duplicate(true)

static func skills() -> Dictionary:
	var result := {}
	for skill_id: String in SKILL_ROWS: result[skill_id]=skill_profile(skill_id)
	return result.duplicate(true)

static func actor_profile(identity: String) -> Dictionary:
	if not ACTOR_ROWS.has(identity): return {}
	var r: Array=ACTOR_ROWS[identity]
	return {"identity":identity,"faction_id":"UNDERGROUND","name":r[0],"silhouette":r[1],"palette":PALETTES[str(r[2])].duplicate(true),"crest":r[3].duplicate(true),"crest_offset":r[4],"gesture":r[5],"sound":_sound(r[6]),"story_anchor":r[7],"counterplay":r[8],"body_change":"preserved_body_small_equipment_crest","identity_version":VERSION}.duplicate(true)

static func skill_profile(skill_id: String) -> Dictionary:
	if not SKILL_ROWS.has(skill_id): return {}
	var r: Array=SKILL_ROWS[skill_id]
	return {"skill_id":skill_id,"hero_id":r[0],"faction_id":"UNDERGROUND","name":r[1],"gesture":r[2],"palette":PALETTES[str(r[3])].duplicate(true),"sound":_sound(r[4]),"story_anchor":r[5],"counterplay":r[6],"phases":r[7].duplicate(true),"passive":bool(r[8]),"identity_version":VERSION}.duplicate(true)

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
	var p: Array=spec.get("palette",[])
	if p.size()!=7: return
	var previous_limit:=int(ctx.get("draw_limit",0))
	ctx.draw_limit=mini(previous_limit,int(ctx.get("count",0))+(36 if bool(spec.get("is_skill",false)) else 24))
	var d:=(center-origin).normalized()
	if d.length_squared()<.1: d=Vector2.RIGHT
	var n:=d.orthogonal()
	var a:=clampf(sin(t*PI)*1.6,0,1)
	var q:=clampf((t-.20)/.36,0,1)
	# origin is already the observed hand anchor; never raise the whole actor.
	if bool(spec.get("is_skill",false)):
		_draw_skill(ctx,origin,center,d,n,scale,t,q,a,p,str(spec.get("gesture","")))
	else:
		_draw_actor(ctx,origin,center,d,n,scale,t,q,a,p,str(spec.get("gesture","")))
	ctx.draw_limit=previous_limit

static func _draw_actor(ctx: Dictionary, o: Vector2, c: Vector2, d: Vector2, n: Vector2, s: float, t: float, q: float, a: float, p: Array, gesture: String) -> void:
	var angle:=d.angle()
	match gesture:
		"shell_scoop":
			_piece(ctx,o-d*(4-7*q)*s,"spade",s*.78,p,-.7+q*1.1,a)
			_piece(ctx,o+n*5*s,"plate",s*.46,p,.3-q*.3,a*.8)
			if t>.54: _grain(ctx,o+d*8*s+Vector2(0,(t-.54)*12)*s,s,p,a)
		"echo_lance":
			_piece(ctx,o,"fork",s*.65,p,angle,a)
			if t>.20 and t<.78:
				_piece(ctx,o.lerp(c,q),"crystal",s*.58,p,angle,a)
				_line(ctx,o.lerp(c,maxf(0,q-.14)),o.lerp(c,q),s,p,a*.65,1)
			if t>.56: _grain(ctx,c-n*5*s+d*(t-.56)*8*s,s,p,a,6)
		"mantis_sidecut":
			var at:=o.lerp(c,q)
			_piece(ctx,at+n*(8-6*q)*s,"blade",s*.68,p,angle-1.0+q*1.4,a)
			_piece(ctx,at-n*(5-3*q)*s,"blade",s*.43,p,angle+1.5-q*.9,a*.8)
		"sieve_dry_cast":
			_piece(ctx,o,"sieve",s*.66,p,-.4+q*.8,a)
			if t>.22 and t<.77: _piece(ctx,o.lerp(c,q)+Vector2(0,-sin(q*PI)*7)*s,"spore",s*.55,p,angle,a)
			if t>.58: _grain(ctx,c+Vector2(3,(t-.58)*14)*s,s,p,a,6)
		"fault_pick_tap":
			_piece(ctx,o.lerp(c,q*.70)+Vector2(0,-8*(1-q))*s,"pick",s*.69,p,-.6+q*.9,a)
			if t>.52:
				_piece(ctx,c+Vector2(-4,3)*s,"slab",s*.42,p,0,a*.85)
				_piece(ctx,c+Vector2(5,5)*s,"slab",s*.32,p,.15,a*.65)
		"chitin_ram":
			_piece(ctx,o.lerp(c,q*.65),"plate",s*.82,p,angle*.25,a)
			if t>.48 and t<.76: _line(ctx,c-d*7*s,c+d*2*s,s,p,a,2)
		"reed_dart":
			_piece(ctx,o,"fork",s*.70,p,angle,a)
			if t>.18 and t<.81: _piece(ctx,o.lerp(c,q),"dart",s*.55,p,angle,a)
			if t>.58: _line(ctx,c-d*4*s,c+d*2*s,s,p,a*.65,1)
		"lizard_prod":
			_piece(ctx,o+d*(q*7)*s,"fork",s*.78,p,angle+.15,a)
			_piece(ctx,o.lerp(c,q*.75),"dart",s*.62,p,angle,a)
			if t>.62: _grain(ctx,o-d*6*s+Vector2(0,10)*s,s,p,a,2)
		"culture_spindle":
			_piece(ctx,o,"fork",s*.56,p,-.3-q*.5,a)
			if t>.20 and t<.80:
				var at:=o.lerp(c,q)+n*sin(q*PI)*5*s
				_line(ctx,at-d*7*s,at+d*3*s,s,p,a,1)
				_piece(ctx,at,"spore",s*.4,p,angle,a)
		"abyss_jaw":
			var at:=o.lerp(c,q*.82)
			var gap:=7.0*(1-sin(t*PI))
			_piece(ctx,at+n*gap*s,"jaw",s*.87,p,angle,a)
			_piece(ctx,at-n*(gap+2)*s,"jaw",s*.72,p,angle+PI,a*.9)
			if t>.59: _grain(ctx,at-d*4*s+Vector2(0,5)*s,s,p,a,6)
		"worker_scoop":
			_piece(ctx,o+d*(sin(t*PI)*5)*s,"spade",s*.58,p,-.7+q*1.5,a)
			if t>.43: _grain(ctx,o+d*7*s+Vector2(0,4+(t-.43)*8)*s,s,p,a,2)

static func _draw_skill(ctx: Dictionary, o: Vector2, c: Vector2, d: Vector2, n: Vector2, s: float, t: float, q: float, a: float, p: Array, gesture: String) -> void:
	var angle:=d.angle()
	var low:=c+Vector2(0,6)*s
	match gesture:
		"inward_shell_patch":
			_piece(ctx,o+Vector2(-7+7*q,4-3*q)*s,"spade",s*.78,p,-.8+q*1.1,a)
			for i: int in range(3):
				var shift:=Vector2((i-1)*(14-10*q),6+abs(i-1)*3)*s
				_piece(ctx,o+shift,"plate",s*(.55 if i==1 else .42),p,(i-1)*.23*(1-q),a)
			if t>.74: _grain(ctx,o+Vector2(-4,(t-.74)*14)*s,s,p,a,2)
		"evacuation_berm_fan":
			_piece(ctx,o+Vector2(0,5-6*q)*s,"spade",s*.84,p,-.7+q*1.6,a)
			if t>.20:
				var at:=o.lerp(low,q)
				for i: int in range(3):
					var lane:=float(i-1)
					_piece(ctx,at+n*lane*(4+q*8)*s+Vector2(0,(1-q)*5)*s,"slab",s*(.62-absf(lane)*.08),p,angle+lane*.36,a)
				if t>.55: _line(ctx,low-n*10*s,low+n*10*s,s,p,a*.8,1)
				if t>.78: _grain(ctx,low+Vector2(5,(t-.78)*15)*s,s,p,a,2)
		"folded_echo_knots":
			_piece(ctx,o,"fork",s*.75,p,angle,a)
			if t>.20 and t<.60:
				var head:=o.lerp(c,q)
				var kink:=o.lerp(head,.6)+n*5*s
				_line(ctx,o,kink,s,p,a,1)
				_line(ctx,kink,head,s,p,a,1)
				_piece(ctx,head,"crystal",s*.5,p,angle,a)
			elif t>=.60:
				_piece(ctx,low-Vector2(7,0)*s,"prism",s*.58,p,-.55,a)
				_piece(ctx,low+Vector2(7,1)*s,"prism",s*.45,p,.55,a)
				_line(ctx,low-Vector2(5,1)*s,low+Vector2(5,1)*s,s,p,a,1)
				_grain(ctx,low+Vector2(2,5)*s,s,p,a,3)
		"narrow_crystal_refraction":
			_piece(ctx,o+Vector2(0,-3)*s,"crystal",s*.68,p,angle,a)
			if t>.20 and t<.57:
				var head:=o.lerp(c,q)
				_line(ctx,o,head,s,p,a,2)
				_piece(ctx,head,"crystal",s*.8,p,angle,a)
			elif t>=.57:
				_piece(ctx,c,"crystal",s*.74,p,angle,a)
				for side: int in [-1,1]: _piece(ctx,c+n*side*(4+(t-.57)*13)*s,"prism",s*.32,p,angle+side*.8,a*.8)
		"single_prism_implosion":
			_piece(ctx,o,"fork",s*.75,p,angle,a)
			if t<.20:
				for i: int in range(3): _piece(ctx,o+Vector2(i*5-5,-7+abs(i-1)*3)*s,"prism",s*.32,p,float(i)*.6,a)
			elif t<.54: _piece(ctx,o.lerp(c,q),"crystal",s*.85,p,angle,a)
			else:
				var collapse:=clampf((t-.54)/.37,0,1)
				for i: int in range(3):
					var offset: Vector2=[Vector2(-13,-4),Vector2(8,-11),Vector2(5,10)][i]
					_piece(ctx,c+offset*(1-collapse)*s,"prism",s*(.72-collapse*.37),p,float(i)*1.8-collapse,a)
				_grain(ctx,c,s*(1.8-collapse),p,a,4)
		"asymmetric_joint_clamp":
			if t<.20:
				_piece(ctx,o+n*6*s,"blade",s*.72,p,angle-.7,a)
				_piece(ctx,o-n*4*s,"blade",s*.43,p,angle+1.7,a)
			else:
				var top:=c+Vector2(0,-11)*s
				var at:=o.lerp(top,q)
				var gap:=9.0*(1-q)+3.0
				_piece(ctx,at+n*gap*s,"blade",s*.75,p,angle-.4,a)
				_piece(ctx,at-n*gap*s,"blade",s*.46,p,angle+PI+.4,a)
				if t>.55: _line(ctx,top-Vector2(4,0)*s,top+Vector2(5,0)*s,s,p,a,2)
		"mining_side_crosscut":
			var at:=o.lerp(c,q)
			if t<.54:
				_piece(ctx,at+n*(9-7*q)*s,"blade",s*.84,p,angle-1.1+q*1.5,a)
				_piece(ctx,o-n*4*s,"blade",s*.44,p,angle+1.5,a*.7)
			else:
				_piece(ctx,c-n*3*s,"blade",s*.50,p,angle+2.6-(t-.54)*2,a)
				_line(ctx,c-n*7*s-d*4*s,c+n*5*s+d*4*s,s,p,a,2)
				if t>.78: _piece(ctx,c+Vector2(7,(t-.78)*16)*s,"husk",s*.34,p,.7,a*.7)
		"self_mantis_molt":
			for side: int in [-1,1]:
				_piece(ctx,o+Vector2(side*(5+q*4),side*2)*s,"husk",s*(.78 if side==1 else .54),p,side*(.4+q*.3),a)
				_line(ctx,o+Vector2(side*2,3)*s,o+Vector2(side*7,-5)*s,s,p,a,1)
			if t>.57: _grain(ctx,o+Vector2(-7,(t-.57)*14)*s,s,p,a,3)
		"sieved_gentle_fall":
			_piece(ctx,o,"sieve",s*.78,p,-.4+q*.7,a)
			if t>.20:
				for i: int in range(3):
					var fall:=clampf((t-.20-float(i)*.06)/.53,0,1)
					var at:=o.lerp(c,fall)+Vector2((i-1)*5,-sin(fall*PI)*12)*s
					_piece(ctx,at,"spore",s*(.44+float(i)*.06),p,float(i)*.4,a*.85)
				if t>.65: _line(ctx,low-Vector2(5,0)*s,low+Vector2(4,2)*s,s,p,a*.7,1)
		"porous_cap_unfold":
			_piece(ctx,o,"sieve",s*.82,p,-.5+q*.8,a)
			if t>.20:
				var fold:=clampf((t-.20)/.40,0,1)*(1-clampf((t-.78)/.22,0,1))
				for i: int in range(3):
					var lane:=float(i-1)
					var at:=c+Vector2(lane*11*fold,-11-absf(lane)*4)*s
					_piece(ctx,at,"cap",s*(.62 if i==1 else .46),p,lane*.2*fold,a)
					if t>.54: _piece(ctx,at+Vector2(lane,11+q*5)*s,"spore",s*.36,p,0,a*.75)
		"three_low_fault_clamps":
			_piece(ctx,o,"pick",s*.72,p,-.45+q*.55,a)
			if t>.20:
				var sink:=clampf((t-.78)/.22,0,1)*6
				for i: int in range(3):
					var lane:=float(i-1)
					var at:=low+Vector2(lane*(13-q*5),lane*3+sink)*s
					_piece(ctx,at,"slab",s*(.60 if i==1 else .46),p,lane*.08,a)
					if t>.54: _line(ctx,at-Vector2(4,0)*s,at+Vector2(4,0)*s,s,p,a*.8,1)
		"boundary_slabs_inward":
			_piece(ctx,o,"pick",s*.80,p,-.7+q*.8,a)
			if t<.20:
				for i: int in range(3): _piece(ctx,o+Vector2(i*4-4,5+i*2)*s,"slab",s*.35,p,(i-1)*.15,a)
			else:
				var press:=clampf((t-.20)/.46,0,1)
				# E-UG-01: retain the exact low slab footprint; give the mass a
				# darker held underside and staggered ivory seams on beige ground.
				var mass:=clampf((t-.20)/.12,0,1)*(1-clampf((t-.92)/.08,0,1))
				for i: int in range(3):
					var lane:=float(i-1)
					var at:=low+Vector2(lane*(19-press*10),lane*5+(1-press)*6)*s
					var slab_scale:=s*(.93 if i==1 else .68)
					var tilt:=lane*(.20-press*.13)
					Brush.poly(ctx,at,SHAPES.slab,slab_scale,_color(p,0,mass).darkened(.22),tilt)
					_piece(ctx,at,"slab",slab_scale,p,tilt,maxf(a,mass*.92))
					var seam:=clampf((t-(.44+i*.06))/.12,0,1)*mass
					if seam>.01:
						var left:=at-Vector2(5,0)*s
						var notch:=at+Vector2(-1,-1)*s
						var right:=at+Vector2(4,-1)*s
						Brush.streak(ctx,left,notch,4*s,_color(p,0,seam))
						Brush.streak(ctx,notch,right,4*s,_color(p,0,seam))
						Brush.streak(ctx,left,notch,1.8*s,_color(p,4,seam))
						Brush.streak(ctx,notch,right,1.8*s,_color(p,4,seam))
				if t>.62 and t<.84:
					Brush.streak(ctx,low-Vector2(4,-1)*s,low+Vector2(4,1)*s,4*s,_color(p,0,mass))
					Brush.streak(ctx,low-Vector2(4,-1)*s,low+Vector2(4,1)*s,1.6*s,_color(p,4,mass))
				if t>.69:
					_grain(ctx,low+Vector2(-6,6+(t-.69)*12)*s,s,p,a,3)
					_grain(ctx,low+Vector2(6,8+(t-.69)*9)*s,s,p,a*.8,5)
