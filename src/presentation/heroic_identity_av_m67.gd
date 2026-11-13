extends RefCounted
## Revised old active identities. Observation only: never finds victims.
const Brush=preload("res://src/presentation/m63_av_brush.gd")
const Data=preload("res://src/simulation/strategic_hero_identity_m67.gd")
const VERSION:="m67-revised-old-skill-av-v2"
const ROWS:={
	"ASH_REQUIEM":["ASH_CHANTER","UNDEAD","folded_script_tokens",["201723","695048","cb9669","8ccbb6","fff1d1"],["字幕板抬起，两枚未写完的台词签翻面","戏幕从手边朝近处队伍张开，不冒治疗星","台词签分成两拍；有限付费次数读真实buff","空幕回卷；没有复活或额外治疗"]],
	"BLOOM_SANCTUARY":["BLOOM_GUIDE","FOREST","returning_sluice",["172129","436873","8abfce","db9db8","fff2d2"],["量水盘倾斜，贝杯沿两侧开口","短水渠从手边分流，不制造新受益者","水珠与叶舟错速前进，表示回蓝和移动窗口","叶舟收回，增益到期或来源死亡即失效"]],
	"HEARTH_REFUGE":["HEARTH_KEEPER","HIGHLAND","oven_countermarch",["251b20","754735","e19c60","94bcd0","fff1bf"],["炉盖抬升，左右面包盾翻成开口护架","有缺口的低棚影托起暖色铆片","护架与错拍炭星强调护甲和反击，不画治疗","棚边回折；真实来源消失或到期即退"]],
	"SPORE_HAVEN":["SPORE_GUIDE","UNDERGROUND","fermenting_floor",["1f1929","634678","af88cf","c8d585","fff2d4"],["筛勺抖出带孔菌片，向选定地面洒落","低位菌褶错开铺展，不封闭成硬控牢笼","稀疏孢粒贴地拖慢落点，不画友军回血","菌片收拢；受害者减速按真实状态结束"]],
	"TUNNEL_SHOCK":["TUNNEL_SENTINEL","UNDERGROUND","evacuation_shell_patch",["201c1d","66583e","b59e6f","7bc0c9","fff2c8"],["背甲的开口护栏朝内收拢修补","两片小甲向外让出退路，不画净化火焰","壳边上扬，少量孢灯修补自身及真实受益者","甲片沿脚侧后退，短时移动读真实buff"]],
	"QUAKE_SNARE":["QUAKE_PRIEST","UNDERGROUND","cleavage_seams",["211c27","665070","ad8fbb","d7af72","fff1c9"],["测层锤敲出两片错开的承力板","选定点的短裂线向外错开，不画束足夹钳","地层边缘崩出少量铠片；只表示实际破甲","裂线淡出；敌人始终可移动攻击，破甲读真实状态"]],
	"RALLY":["COMMANDER","HUMAN","reclaimed_copper_seal",["211b22","795b46","c99760","97bbc0","fff1cb"],["长官翻起借来的铜印，单侧折页先收拢","一枚有缺口的方印朝实际单目标落下，不张开治疗篷","目标处短促铜屑与断开的契线表示撞击裁决","铜印碎影立即收回；没有友军治疗或持续保护"]],
	"GEAR_REPAIR":["GEAR_HUNTER","MACHINE","vented_heat_canisters",["211e24","68524a","ce794c","e6bb74","fff1c7"],["枪口旁三片散热翅依次张开，排出余热小罐","选定点抬起低矮通风槽与热雾，不画即时爆炸命中","稀疏炭粒从排气口上浮，灼烧只在真实命中者处持续","罐体余影熄灭；后续灼烧按真实状态期限与净化结束"]],
	"WIND_MEND":["WIND_COURIER","FOREST","crosscut_leaf_route",["17242a","467071","9dc5ad","e4bd8b","fff3d0"],["箭羽边沿抬出三枚细长叶刃，方向由真实投递确定","叶刃沿同一斜线错拍划出；不移动英雄身体","真实命中点出现短裂叶，后续目标反馈变轻","叶梗顺风路分散；不留下第二个自身攻速或移速增益"]],
}
const SHAPES:={
	"script":[Vector2(-5,-8),Vector2(4,-8),Vector2(6,-5),Vector2(6,7),Vector2(-4,8),Vector2(-5,3)],
	"cup":[Vector2(-7,-3),Vector2(7,-3),Vector2(4,3),Vector2(1,4),Vector2(1,7),Vector2(-2,7),Vector2(-2,4),Vector2(-5,2)],
	"leaf":[Vector2(-9,1),Vector2(-3,-3),Vector2(4,-4),Vector2(9,0),Vector2(3,4),Vector2(-4,3)],
	"rib":[Vector2(-10,5),Vector2(-8,-3),Vector2(-3,-7),Vector2(5,-7),Vector2(10,-2),Vector2(11,5),Vector2(7,5),Vector2(6,0),Vector2(2,-3),Vector2(-3,-2),Vector2(-5,4)],
	"spore":[Vector2(-8,2),Vector2(-6,-3),Vector2(-2,-6),Vector2(4,-5),Vector2(8,0),Vector2(4,3),Vector2(1,2),Vector2(1,7),Vector2(-2,7),Vector2(-3,2)],
	"plate":[Vector2(-6,-5),Vector2(2,-7),Vector2(7,-2),Vector2(5,5),Vector2(-1,7),Vector2(-6,3)],
}
const SOUNDS:={
	"ASH_REQUIEM":["choir",436,.19,2,"staggered_reprise",1.54,1.6,.18,.28],
	"BLOOM_SANCTUARY":["water",590,.16,3,"woven_drift",1.48,1.3,.12,.14],
	"HEARTH_REFUGE":["scrape",290,.24,6,"inward_return",1.60,1.6,.13,.25],
	"SPORE_HAVEN":["breath",385,.23,7,"opening_fan",1.53,1.6,.16,.22],
	"TUNNEL_SHOCK":["scrape",240,.28,2,"inward_return",.62,1.7,-.2,.08],
	"QUAKE_SNARE":["crack",310,.36,3,"falling_weight",.55,1.8,-.25,.08],
	"RALLY":["clang",260,.28,2,"falling_weight",1.45,1.7,-.3,.13],
	"GEAR_REPAIR":["breath",420,.36,5,"staggered_reprise",1.75,1.3,-.18,.12],
	"WIND_MEND":["scrape",740,.14,3,"opening_fan",1.30,1.6,.24,.1],
}
static func skill_profile(id:String)->Dictionary:
	if not ROWS.has(id):return {}
	var row:Array=ROWS[id];var info:=Data.brief(id)
	var voice:Array=SOUNDS[id]
	var sound:={"voice":voice[0],"frequency":voice[1],"texture":voice[2],"pulses":voice[3],"rhythm":voice[4],"seconds":voice[5],"overtone":voice[6],"sweep":voice[7],"echo":voice[8]}
	return {"skill_id":id,"name":id,"hero_id":row[0],"faction_id":row[1],"gesture":row[2],"palette":row[3].duplicate(),"phases":row[4].duplicate(),"story_anchor":info.decision,"counterplay":info.counterplay,"passive":false,"identity_version":VERSION,"sound":sound}
static func draw_skill(ctx:Dictionary,origin:Vector2,center:Vector2,scale:float,entry:Dictionary)->bool:
	var id:=str(entry.get("id",""))
	if not ROWS.has(id):return false
	var palette:Array=ROWS[id][3];var t:=float(ctx.phase);var q:=clampf((t-.12)/.65,0,1);var alpha:=clampf(minf(t*7,(1-t)*6),0,1);var origin_low:=origin+Vector2(0,10)*scale
	match id:
		"ASH_REQUIEM":
			for i:int in range(2):
				var at:=origin+Vector2((i*2-1)*(7+q*11),-5-sin(q*PI)*9+i*3)*scale
				Brush.stamp(ctx,at,SHAPES.script,scale*.65,palette,(i*2-1)*(.4-q*.5),alpha)
				Brush.streak(ctx,origin_low,at,scale,Color(str(palette[3]),alpha*.5))
		"BLOOM_SANCTUARY":
			Brush.stamp(ctx,origin_low,SHAPES.cup,scale*.8,palette,-.3+q*.7,alpha)
			for i:int in range(3):
				var at:=origin_low+Vector2((i-1)*(6+q*18),5+sin(q*PI+float(i))*(3+q*3))*scale
				Brush.streak(ctx,origin_low,at,scale*2,Color(str(palette[2]),alpha*.65))
				Brush.stamp(ctx,at,SHAPES.leaf,scale*.45,palette,(i-1)*.2,alpha)
		"HEARTH_REFUGE":
			for side:int in [-1,1]:
				Brush.stamp(ctx,origin_low+Vector2(side*(10+q*8),-6)*scale,SHAPES.rib,scale*.85,palette,side*.2,alpha)
				Brush.chip(ctx,origin_low+Vector2(side*(7+q*16),-15+q*8)*scale,Vector2(1,2)*scale,Color(str(palette[4]),alpha))
		"SPORE_HAVEN":
			for i:int in range(5):
				var at:=center+Vector2((i-2)*9,7+abs(i-2)*3+sin(float(i)+q*PI)*2)*scale
				Brush.stamp(ctx,at,SHAPES.spore,scale*(.45+q*.2),palette,(i-2)*.14,alpha*.85)
				if i<4:Brush.streak(ctx,at,at+Vector2(8,4)*scale,scale,Color(str(palette[3]),alpha*.45))
		"TUNNEL_SHOCK":
			for side:int in [-1,1]:
				var at:=origin_low+Vector2(side*(15-q*8),6+q*5)*scale
				Brush.stamp(ctx,at,SHAPES.plate,scale*.72,palette,side*(.4-q*.3),alpha)
				Brush.chip(ctx,origin_low+Vector2(side*(6-q*3),-4-q*9)*scale,Vector2(1,2)*scale,Color(str(palette[3]),alpha))
		"QUAKE_SNARE":
			for i:int in range(3):
				var at:=center+Vector2((i-1)*12,6+(i%2)*5)*scale
				Brush.stamp(ctx,at+Vector2((i-1)*q*3,0)*scale,SHAPES.plate,scale*.55,palette,(i-1)*(.1+q*.2),alpha*.85)
				Brush.streak(ctx,at+Vector2(-4,-2)*scale,at+Vector2(5,3)*scale,scale*2,Color(str(palette[0]),alpha))
				Brush.chip(ctx,at+Vector2(7+q*4,-3-q*4)*scale,Vector2(1,2)*scale,Color(str(palette[3]),alpha*.8))
		"RALLY":
			var at:=origin.lerp(center,q)+Vector2(0,-sin(q*PI)*20)*scale
			Brush.stamp(ctx,at,SHAPES.plate,scale*(1.1-q*.2),palette,.35-q*.7,alpha)
			if q>.55:
				for side:int in [-1,1]:
					Brush.streak(ctx,center+Vector2(side*3,-4)*scale,center+Vector2(side*(8+q*6),6)*scale,scale,Color(str(palette[3]),alpha))
		"GEAR_REPAIR":
			for i:int in range(3):
				var at:=center+Vector2((i-1)*16,8+(i%2)*5)*scale
				Brush.stamp(ctx,at,SHAPES.cup,scale*.7,palette,.15*(i-1),alpha*.8)
				for p:int in range(3):
					Brush.chip(ctx,at+Vector2(sin(float(i+p)*1.7+q*3)*5,-4-fmod(q*21+p*6,22.0))*scale,Vector2(1,2)*scale,Color(str(palette[2+p%2]),alpha*.8))
		"WIND_MEND":
			var direction:=(center-origin).normalized();var normal:=direction.orthogonal()
			for i:int in range(3):
				var progress:=clampf(q*1.25-float(i)*.12,0,1)
				var at:=origin.lerp(center,progress)+normal*(i-1)*5*scale
				Brush.streak(ctx,at-direction*24*scale,at+direction*9*scale,scale,Color(str(palette[3]),alpha*.65))
				Brush.stamp(ctx,at,SHAPES.leaf,scale*.65,palette,direction.angle(),alpha)
	return true
