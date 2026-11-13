extends RefCounted
## Authored changed interactions. Presentation only; no search, damage or RNG.
const Data=preload("res://src/simulation/strategic_hero_expansion_m66.gd")
const Brush=preload("res://src/presentation/m63_av_brush.gd")
const VERSION:="m67-charge-control-and-recovery-choreography-v1"
const SPECIAL:=["OATH_EDGE_PLEDGE","OATH_LAST_WITNESS","BRIDGE_LOCK_BRACE","BRIDGE_LOAD_BEARER","RELIC_COLD_EDGE","OSSUARY_FERRY_STRIKE","OSSUARY_CLOSED_PALL","OSSUARY_PROCESSION","PISTON_OFFSET_JAB","PISTON_FLYWHEEL","PISTON_DEAD_CENTER","RIVET_LOAD_PLATE","RIVET_WORKING_PRESSURE","THORN_GRAFT_RUPTURE","ANTLER_BRANCH_SWEEP","ANTLER_BARK_FOLD","ANTLER_RUT_SEASON","SLAG_TEMPER_CUT","SLAG_WHITE_HEAT","SLAG_QUENCH_VERDICT","BASALT_STRATA_BLOW","BASALT_FAULT_STANCE","PRISM_FACET_PIN","PRISM_DOUBLE_EDGE","PRISM_REFRACTION_CUT","CARAPACE_SHELL_SPLIT","CARAPACE_NEST_GUARD","CARAPACE_LAYERED_MOLT"]
static func profile(id:String)->Dictionary:
	if not Data.SKILLS.has(id):return {}
	var s:=Data.skill(id,1)
	var phases:Array[String]=["真实武器在手边预示","按真实投递释放具名材料","只给真实命中点反馈，武器回收"]
	if s.get("passive",false):phases=["被动图标保持静态","学习后真实护甲属性变化","不播放虚构施放、命中或耗蓝动画"]
	elif int(s.get("charges",-1))>0:
		phases=["将分离的签、齿、刃或护板装入武器周围","次数型强化的独立部件错峰锁定","施法装填动画退去；持续强化读取真实增益而非重播施法"]
	elif s.effect in ["STUN","ROOT"] and int(s.get("damage",0))==0:
		phases=["手边装置或空角展开，不预演伤害爆炸","真实扇/线/区域中锁定，命中点显示对应上身/脚底束具","束具的持续反馈服从真实控制到期"]
	elif s.effect=="HEAL":phases=["收拢甲片或船帆，引导向内而非射向敌人","缝合线、通气孢光沿自身躯干上升","附近受益者由真实HEAL/BUFF事件反馈，不凭空绘制四个假目标"]
	elif s.effect=="RALLY":phases=["来源手边竖起承重梁或试压接线","向外展开共享结构，最多受益者由结算决定","来源端材料收拢；各身体持续强化使用真实来源与到期"]
	elif s.get("status_kind","")=="POISON" and int(s.get("damage",0))==0:phases=["种匣裂开，细小种粒先落地","偏心芽格缓慢生长，没有即时爆炸或假召唤","中毒受害者颗粒读真实到期；种格不阻路"]
	elif id=="PRISM_REFRACTION_CUT":phases=["棱刃分光，短促保留空白","只沿已结算不同目标依次折射，后续目标不重复命中","每个折面独立退去，不绘制额外区域冲击"]
	return {"version":VERSION,"gesture":str(s.motif),"actual_render_branch":"m67-special" if id in SPECIAL else "retained-m66-weapon","release_method":"常驻学习被动" if s.get("passive",false) else "自身施放" if s.target_mode=="SELF" else "点选目标落点","style":"粗黑边像素、硬色阶、具名材料与不对称留白","phases":phases,"interaction":Data.brief(id).get("interaction",""),"counterplay":Data.brief(id).get("counterplay","")}
static func draw(ctx:Dictionary,origin:Vector2,center:Vector2,id:String,t:float,scale:float,p:Array,weapon:Array,impacts:Array)->bool:
	if id not in SPECIAL:return false
	var s:=Data.skill(id,1)
	var direction:=(center-origin).normalized()
	if direction.length_squared()<.1:direction=Vector2.RIGHT
	var normal:=direction.orthogonal()
	var q:=clampf((t-.17)/.53,0,1)
	var a:=clampf(sin(t*PI)*1.4,0,1)
	var focal:=origin if s.target_mode=="SELF" else center
	# Each count is an authored assembly, not a claim about hidden live charges.
	if int(s.get("charges",-1))>0:
		var count:=int(s.charges)
		for index:int in range(count):
			var delay:=clampf(q-float(index)*.12,0,1)
			var angle:=float(index)*TAU/float(count)-PI*.5
			var offset:=Vector2(cos(angle)*float(22+index*3),sin(angle)*14-18)*scale
			var at:=origin+offset*delay
			match id:
				"OATH_EDGE_PLEDGE":_stamp(ctx,at,[Vector2(-5,17),Vector2(-5,-15),Vector2(3,-20),Vector2(6,-15),Vector2(5,17)],scale*.8,p,.12*(index-1),a)
				"PISTON_FLYWHEEL":_stamp(ctx,at,[Vector2(-7,12),Vector2(-7,-7),Vector2(-3,-7),Vector2(-3,-15),Vector2(4,-15),Vector2(4,-7),Vector2(8,-7),Vector2(8,12)],scale*.65,p,t*1.5+index*.7,a)
				"SLAG_WHITE_HEAT":_stamp(ctx,at,weapon,scale*.75,p,(index*2-1)*(.7-q*.35),a)
				"PRISM_DOUBLE_EDGE":_stamp(ctx,at,[Vector2(-4,22),Vector2(-9,-8),Vector2(-2,-30),Vector2(7,-19),Vector2(9,7),Vector2(3,24)],scale*.8,p,(index*2-1)*.65,a)
				"RIVET_LOAD_PLATE":_stamp(ctx,at,[Vector2(-11,-12),Vector2(9,-16),Vector2(14,4),Vector2(5,17),Vector2(-13,11)],scale*.8,p,(index*2-1)*.3,a)
		return true
	match id:
		"OATH_LAST_WITNESS":
			for index:int in range(4):
				var at:=origin.lerp(center,.40+float(index%2)*.28)+normal*(index-1.5)*(16+q*9)*scale
				_stamp(ctx,at,[Vector2(-5,-20),Vector2(4,-20),Vector2(4,-3),Vector2(14,-3),Vector2(14,5),Vector2(4,5),Vector2(4,17),Vector2(-5,17)],scale*.8,p,direction.angle()*.25,a)
		"PISTON_DEAD_CENTER":
			for side:int in [-1,1]:
				var off:=normal*side*(19-q*10)*scale
				Brush.streak(ctx,origin+off,center+off,5*scale,Color(str(p[0]),a*.8))
				Brush.streak(ctx,origin+off,center+off,2*scale,Color(str(p[3]),a*.7))
				_stamp(ctx,center+off,[Vector2(-3,12),Vector2(-3,-8),Vector2(9,-8),Vector2(9,-2),Vector2(3,-2),Vector2(3,12)],scale*.8,p,direction.angle(),a)
		"ANTLER_RUT_SEASON":
			for index:int in range(5):
				var angle:=float(index)*TAU/5+.3
				var at:=center+Vector2(cos(angle)*(22+q*17),sin(angle)*(12+q*8))*scale
				_stamp(ctx,at,[Vector2(-4,15),Vector2(-5,-7),Vector2(-13,-20),Vector2(-7,-17),Vector2(-2,-8),Vector2(4,-22),Vector2(7,-18),Vector2(4,-3),Vector2(7,15)],scale*.75,p,angle*.25,a)
		"PRISM_FACET_PIN":
			for index:int in range(2):
				var at:=origin.lerp(center,.45+float(index)*.45)+Vector2(0,-31*(1-q))*scale
				_stamp(ctx,at,[Vector2(-4,18),Vector2(-8,-6),Vector2(0,-24),Vector2(7,-7),Vector2(5,18)],scale*.75,p,(index*2-1)*.2,a)
		"BRIDGE_LOCK_BRACE","RIVET_WORKING_PRESSURE":
			var machine:=id=="RIVET_WORKING_PRESSURE"
			for index:int in range(4 if machine else 3):
				var angle:=float(index)*TAU/(4.0 if machine else 3.0)+(.0 if machine else -.4)
				var at:=origin+Vector2(cos(angle)*29*q,sin(angle)*16*q-14)*scale
				_stamp(ctx,at,[Vector2(-11,-5),Vector2(-5,-5),Vector2(-5,-13),Vector2(5,-13),Vector2(5,-5),Vector2(11,-5),Vector2(11,6),Vector2(-11,6)],scale*.8,p,angle*.3,a)
		"OSSUARY_CLOSED_PALL":
			for index:int in range(4):
				var at:=origin+Vector2((index%2*2-1)*(20-10*q),-8-index*9+q*7)*scale
				_stamp(ctx,at,[Vector2(-10,4),Vector2(-10,-6),Vector2(-2,-12),Vector2(11,-10),Vector2(11,-5),Vector2(1,-6),Vector2(-4,1),Vector2(-4,7)],scale*.7,p,(index%2*2-1)*.15,a)
		"CARAPACE_NEST_GUARD","CARAPACE_LAYERED_MOLT":
			var large:=id=="CARAPACE_LAYERED_MOLT"
			for index:int in range(6 if large else 3):
				var angle:=float(index)*TAU/(6.0 if large else 3.0)
				var at:=origin+Vector2(cos(angle)*(22+q*14),sin(angle)*14-22-q*12)*scale
				_stamp(ctx,at,[Vector2(-9,10),Vector2(-13,-1),Vector2(-5,-12),Vector2(4,-15),Vector2(13,-3),Vector2(9,10),Vector2(3,6),Vector2(-3,6)],scale*(.8 if large else .55),p,angle*.25,a*.8)
		"THORN_GRAFT_RUPTURE":
			for index:int in range(3):
				var at:=center+Vector2((index-1)*25,((index%2)*2-1)*11)*scale
				_stamp(ctx,at,[Vector2(-6,9),Vector2(-7,-1),Vector2(-1,-9),Vector2(6,-5),Vector2(8,3),Vector2(3,10)],scale*(.5+.5*q),p,index*.7,a)
				_stamp(ctx,at+Vector2(0,-(4+q*16))*scale,[Vector2(-3,11),Vector2(-3,0),Vector2(-11,-7),Vector2(-8,-12),Vector2(0,-6),Vector2(7,-15),Vector2(12,-10),Vector2(3,0),Vector2(3,11)],scale*.75,p,(index-1)*.35,a*.8)
		"ANTLER_BARK_FOLD":
			for side:int in [-1,1]:
				_stamp(ctx,origin+Vector2(side*(12+q*21),-16)*scale,weapon,scale*.65,p,side*(PI*.4-q*.3),a)
				for step:int in range(2):_stamp(ctx,origin+Vector2(-side*(16+step*13),9+step*5)*scale,[Vector2(-5,3),Vector2(-5,-3),Vector2(2,-8),Vector2(6,-4),Vector2(6,4)],scale*.55,p,side*.4,a*(.55-step*.2))
		"RELIC_COLD_EDGE":
			for side:int in [-1,1]:
				var at:=origin+Vector2(side*25,-24-q*12)*scale
				_stamp(ctx,at,[Vector2(-5,13),Vector2(-8,4),Vector2(-7,-8),Vector2(-2,-14),Vector2(5,-9),Vector2(9,5),Vector2(4,13)],scale*.75,p,side*.2,a)
				for grain:int in range(2):_stamp(ctx,at.lerp(origin,.25+q*.7)+Vector2(0,-grain*8)*scale,[Vector2(-3,3),Vector2(-3,-3),Vector2(3,-3),Vector2(3,3)],scale*.5,p,grain*.5,a*.7)
		"OSSUARY_PROCESSION","BRIDGE_LOAD_BEARER","BASALT_FAULT_STANCE":
			for side:int in [-1,1]:
				var at:=origin+Vector2(side*(19+q*7),-14)*scale
				var shape:Array=[Vector2(-7,22),Vector2(-12,0),Vector2(-8,-24),Vector2(2,-32),Vector2(12,-17),Vector2(10,14),Vector2(3,22)] if id=="OSSUARY_PROCESSION" else [Vector2(-11,18),Vector2(-11,-17),Vector2(3,-22),Vector2(12,-14),Vector2(12,18)] if id=="BRIDGE_LOAD_BEARER" else [Vector2(-12,15),Vector2(-16,-1),Vector2(-10,-18),Vector2(2,-23),Vector2(14,-10),Vector2(12,15)]
				_stamp(ctx,at,shape,scale*.85,p,side*(.15+q*.12),a*.85)
			if id=="BASALT_FAULT_STANCE":_stamp(ctx,origin+Vector2(0,-30-q*8)*scale,weapon,scale*.8,p,-.4+q*.5,a)
		"PRISM_REFRACTION_CUT":
			_stamp(ctx,origin+direction*16*scale,weapon,scale*.65,p,direction.angle(),a)
			var previous:=origin
			for value:Variant in impacts.slice(0,4):
				if typeof(value) not in [TYPE_VECTOR2,TYPE_VECTOR2I] or not Vector2(value).is_finite():continue
				var at:=Vector2(value)+Vector2(0,-9)*scale
				Brush.streak(ctx,previous,at,4*scale,Color(str(p[0]),a*.8))
				Brush.streak(ctx,previous,at,1.5*scale,Color(str(p[3]),a*.8))
				_stamp(ctx,at,[Vector2(-4,15),Vector2(-9,-3),Vector2(1,-20),Vector2(8,-6),Vector2(5,14)],scale*.8,p,q*.8,a)
				previous=at
		_:
			# Revised direct weapons keep actual geometry and add a distinct local
			# mark: fracture chip, foot clamp or single thermal scar, not AoE rings.
			var head:=origin.lerp(center,q)
			_stamp(ctx,head,weapon,scale*.65,p,direction.angle()+PI*.5+q*.5,a)
			if id=="SLAG_TEMPER_CUT":
				for side:int in [-1,1]:_stamp(ctx,center+Vector2(side*(13-q*5),8)*scale,[Vector2(-4,7),Vector2(-5,-8),Vector2(2,-12),Vector2(6,-5),Vector2(3,7)],scale*.7,p,side*.2,a)
			elif id=="CARAPACE_SHELL_SPLIT":
				for side:int in [-1,1]:_stamp(ctx,center+Vector2(side*(17-q*9),-15)*scale,weapon,scale*.55,p,side*1.1,a)
			elif id=="SLAG_QUENCH_VERDICT":
				var cold:Array=p.duplicate();cold[2]="8bb9cc";cold[3]="d1e3de"
				_stamp(ctx,center+Vector2(-9,-14)*scale,weapon,scale*.9,cold,-.7+q*.7,a)
				for index:int in range(3):_stamp(ctx,center+Vector2((index-1)*8,-14-index*8-q*15)*scale,[Vector2(-3,8),Vector2(-5,0),Vector2(0,-13),Vector2(4,-3),Vector2(3,7)],scale*.55,p,index*.4,a*.7)
			else:
				for index:int in range(3):_stamp(ctx,center+Vector2((index-1)*10*q,-11-index%2*8)*scale,[Vector2(-6,4),Vector2(-3,-7),Vector2(5,-5),Vector2(8,1),Vector2(2,7)],scale*.6,p,index*.7+q,a*.75)
	return true
static func _stamp(ctx:Dictionary,point:Vector2,shape:Array,scale:float,palette:Array,angle:float,alpha:float)->void:
	Brush.stamp(ctx,point,shape,scale,palette,angle,alpha)
