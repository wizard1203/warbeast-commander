extends RefCounted
## Explicit pixel material/weapon marks. Only supplied geometry, no hit search.
const Data=preload("res://src/simulation/strategic_hero_mages_m68.gd")
const ReworkR7=preload("res://src/simulation/strategic_hero_rework_r7_catalog.gd")
const Brush=preload("res://src/presentation/m63_av_brush.gd")
const VERSION:="m68-six-damage-mage-av-v1"
static func _skill(id:String,rank:int)->Dictionary:
	if not ReworkR7.has_skill(id): return Data.skill(id,rank)
	var result := ReworkR7.skill(id,rank)
	if result.is_empty(): return result
	var original := Data.skill(id,rank)
	for key: String in ["material","emblem","family"]:
		if not result.has(key) and original.has(key): result[key]=original[key]
	result["motif"]=str(result.r7_handler)+"_paid_delivery"
	return result
const PALETTES:={
	"SUNGLASS_SCRIBE":["211d28","705d49","d8b781","86bdc7","fff1ce"],
	"CINDER_TESTATOR":["211b29","695263","bda38d","93b9ac","f2dcab"],
	"FLUX_BOMBARDIER":["17232c","476d7e","8fc4d0","d5a479","ecf7dc"],
	"POLLEN_COMET":["1d2427","5c7058","b3c88a","d798b7","fff1be"],
	"OBSIDIAN_CANTOR":["211c29","655169","b49cab","e0a369","fff1bd"],
	"MYCELIAL_CATALYST":["211a2b","665178","aa8bc1","a0bd71","ebefbe"]}
const MOTIFS:={"SUNGLASS_SCRIBE":["lens","rune","star"],"CINDER_TESTATOR":["lantern","rib","skull"],"FLUX_BOMBARDIER":["bolt","coil","battery"],"POLLEN_COMET":["leaf","sprout","bloom"],"OBSIDIAN_CANTOR":["crystals","volcano","mountain"],"MYCELIAL_CATALYST":["fang","mushroom","shell"]}
const VOICES:={"SUNGLASS_SCRIBE":["bell",690,.14],"CINDER_TESTATOR":["choir",240,.22],"FLUX_BOMBARDIER":["buzz",330,.31],"POLLEN_COMET":["pluck",780,.12],"OBSIDIAN_CANTOR":["crack",190,.46],"MYCELIAL_CATALYST":["water",365,.3]}
const SHAPES:={
	"mirror":[Vector2(-5,-9),Vector2(3,-11),Vector2(7,-3),Vector2(3,8),Vector2(-5,6),Vector2(-7,-1)],
	"page":[Vector2(-5,-8),Vector2(4,-8),Vector2(7,-3),Vector2(5,8),Vector2(-6,6)],
	"flux":[Vector2(-8,-3),Vector2(0,-9),Vector2(5,-5),Vector2(2,-1),Vector2(9,2),Vector2(0,9),Vector2(-4,5),Vector2(-1,1)],
	"seed":[Vector2(-9,0),Vector2(-2,-5),Vector2(5,-3),Vector2(9,1),Vector2(1,5),Vector2(-5,3)],
	"shard":[Vector2(-6,8),Vector2(-4,-8),Vector2(0,-14),Vector2(7,-4),Vector2(3,9)],
	"sac":[Vector2(-7,2),Vector2(-5,-5),Vector2(1,-8),Vector2(7,-3),Vector2(8,4),Vector2(3,7),Vector2(-4,6)]}
static func icon_recipe(id:String)->Array:
	var hero:=id.trim_prefix("INNATE_") if id.begins_with("INNATE_") else Data.owner(id)
	if not PALETTES.has(hero):return []
	if id.begins_with("INNATE_"):return [MOTIFS[hero][2],"orbit"]
	var slot:int=Data.raw_profile(hero).skill_ids.find(id)
	return [MOTIFS[hero][slot],["lance","fork","falling"][slot]] if slot>=0 else []
static func actor_profile(unit:Dictionary)->Dictionary:
	var hero:=str(unit.get("hero_archetype",""))
	if not PALETTES.has(hero):return {}
	return {"identity":"hero:"+hero,"hero_id":hero,"faction_id":Data.raw_profile(hero).faction_id,"gesture":"paid_caster_weapon","palette":PALETTES[hero],"phases":["持有物预示","沿实际普攻方向释放","真实命中反馈"],"weapon_family":"arcane","sound":_sound(hero,0,false),"crest":[],"source":VERSION}
static func skill_profile(id:String)->Dictionary:
	var hero:=Data.owner(id)
	if not PALETTES.has(hero):return {}
	var slot:int=Data.raw_profile(hero).skill_ids.find(id);var skill:=_skill(id,1)
	var names:={"SUNGLASS_SCRIBE":["棱镜书页折成一束日光","镜边切线越过实际投递路径","碎镜落于指定区域"],"CINDER_TESTATOR":["余烬封口的遗嘱页","近身灰页错拍张开","单目标遗火签名闭合"],"FLUX_BOMBARDIER":["炮口棱轨磁穿","折角电链逐靶跨接","磁通线圈反向崩散"],"POLLEN_COMET":["花粉飞萤张扇","彗籽拖出窄而长的尾迹","种子星尘连锁而非全屏爆炸"],"OBSIDIAN_CANTOR":["厚黑曜板从裂口抬升","排成窄线的热玻璃灰","近扇岩刃按层错开"],"MYCELIAL_CATALYST":["酸管喷出断续粘丝","单枚酸核短促塌陷","孢滴贴低位散落；不是施法后持续搜敌区域"]}
	return {"skill_id":id,"hero_id":hero,"faction_id":Data.raw_profile(hero).faction_id,"gesture":hero.to_lower()+"_"+str(slot),"palette":PALETTES[hero],"phases":[names[hero][slot],"沿真实"+str(skill.delivery)+"投递释放，不移动英雄","只给传入实际命中者反馈","残留随真实状态结束；纯伤不冒充控制"],"story_anchor":str(Data.STORIES[hero].get("motive","")),"counterplay":"错开投递形状；持续伤害可按实际净化规则移除；施法必须支付蓝量","passive":false,"identity_version":VERSION,"sound":_sound(hero,slot,slot==2)}
static func _sound(hero:String,slot:int,ultimate:bool)->Dictionary:
	var v:Array=VOICES[hero]
	return {"voice":v[0],"frequency":float(v[1])*(1.0+slot*.13),"texture":v[2],"pulses":2+slot*2,"rhythm":["sharp_cut","staggered_reprise","falling_weight"][slot],"seconds":1.7 if ultimate else .66,"overtone":1.35+slot*.2,"sweep":-.2 if hero in ["OBSIDIAN_CANTOR","CINDER_TESTATOR"] else .22,"echo":.16 if ultimate else .06}
static func draw_skill(ctx:Dictionary,origin:Vector2,center:Vector2,scale:float,entry:Dictionary)->bool:
	var hero:=Data.owner(str(entry.get("id","")))
	if not PALETTES.has(hero):return false
	var slot:int=Data.raw_profile(hero).skill_ids.find(str(entry.id));var p:Array=PALETTES[hero]
	var phase:=float(ctx.phase);var q:=clampf((phase-.12)/.65,0,1);var alpha:=clampf(minf(phase*7,(1-phase)*6),0,1)
	var delivery:=str(entry.get("delivery","SINGLE"));var direction:=(center-origin).normalized();var normal:=direction.orthogonal()
	# Area material centers are cast ornaments, not additional acquired victims.
	var count:=5 if delivery in ["AREA","CONE"] else 3 if delivery in ["LINE","CHAIN"] else 1
	for i:int in range(count):
		var at:=origin.lerp(center,clampf(q*1.3-float(i)*.1,0,1))
		if delivery=="AREA":at=center+Vector2((i-2)*11,abs(i-2)*4)*scale
		elif delivery=="CONE":at=origin+direction*(20+q*55)*scale+normal*(i-2)*(4+q*8)*scale
		elif delivery=="CHAIN":at=origin.lerp(center,float(i+1)/count)+normal*((i%2)*2-1)*q*9*scale
		match hero:
			"SUNGLASS_SCRIBE":
				Brush.stamp(ctx,at,SHAPES.mirror,scale*(.7+slot*.15),p,-.5+q*.8,alpha)
				Brush.streak(ctx,at-direction*(12+slot*4)*scale,at+direction*7*scale,scale,Color(str(p[4]),alpha*.8))
			"CINDER_TESTATOR":
				Brush.stamp(ctx,at+Vector2(0,-q*9)*scale,SHAPES.page,scale*(.7+slot*.2),p,(i-2)*.2+q*.4,alpha*.85)
				Brush.chip(ctx,at+Vector2(3,-8-q*9)*scale,Vector2(1,2)*scale,Color(str(p[3]),alpha))
			"FLUX_BOMBARDIER":
				Brush.stamp(ctx,at,SHAPES.flux,scale*(.6+slot*.15),p,q*.4,alpha)
				Brush.streak(ctx,at-direction*13*scale,at+direction*8*scale,scale*2,Color(str(p[3]),alpha*.75))
			"POLLEN_COMET":
				Brush.stamp(ctx,at,SHAPES.seed,scale*(.7+slot*.12),p,direction.angle()+sin(q*PI)*.3,alpha)
				for n:int in range(2):Brush.chip(ctx,at-direction*(7+n*7)*scale+normal*sin(q*5+n)*4*scale,Vector2(1,1)*scale,Color(str(p[3+n]),alpha*.7))
			"OBSIDIAN_CANTOR":
				Brush.stamp(ctx,at+Vector2(0,-sin(q*PI)*(7+slot*3))*scale,SHAPES.shard,scale*(.9+slot*.15),p,(i-2)*.12,alpha)
				Brush.chip(ctx,at+Vector2(6,-4-q*5)*scale,Vector2(2,1)*scale,Color(str(p[3]),alpha))
			"MYCELIAL_CATALYST":
				Brush.stamp(ctx,at+Vector2(0,sin(q*PI+i)*3)*scale,SHAPES.sac,scale*(.65+slot*.15),p,q*.25,alpha*.85)
				Brush.streak(ctx,at-direction*12*scale,at,scale*2,Color(str(p[3]),alpha*.55))
	return true
static func append_attack(commands:Array,origin:Vector2,center:Vector2,unit:Dictionary,pose:Dictionary,scale:float,limit:int)->bool:
	var hero:=str(unit.get("hero_archetype",""))
	if not PALETTES.has(hero):return false
	var ids:Array=Data.raw_profile(hero).skill_ids;var skill:=Data.skill(ids[0],1)
	skill["delivery"]="SINGLE"
	var ctx:={"commands":commands,"count":commands.size(),"draw_limit":mini(limit,commands.size()+12),"phase":float(pose.get("phase",0)),"quantum":maxf(1,roundf(scale))}
	draw_skill(ctx,origin,center,scale*.65,skill);return true
static func inspect_skill(unit:Dictionary,pose:Dictionary)->Dictionary:
	var hero:=str(unit.get("hero_archetype",""));var action:=str(pose.get("action",""));var t:=float(pose.get("phase",-1))
	if not Data.has_hero(hero) or not action.begins_with("SKILL_") or int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not is_finite(t) or t<0 or t>=1:return {"supported":false}
	var id:=action.trim_prefix("SKILL_");var rank:=int(pose.get("skill",{}).get("level",0))
	if Data.owner(id)!=hero or rank<=0:return {"supported":false}
	var s:=_skill(id,rank)
	if s.is_empty():return {"supported":false}
	return {"supported":true,"id":id,"hero":hero,"signature":s.motif,"family":s.family,"motif":s.motif,"phase":t,"rank":rank,"ultimate":s.ultimate,"at_self":false,"delivery":s.delivery,"effect":s.effect,"target_shape":str(s.delivery).to_lower(),"faction":s.source_faction,"palette":PALETTES[hero],"material_mode":s.get("material","ECHO_BAND"),"layers":["coarse_pixel_edge","individual_material","actual_delivery","settled_hit_only"],"visual_extent_is_hit_range":false,"authoritative_radius":s.radius,"line_width":s.get("line_width",0),"cone_width":s.get("cone_width",0),"weapon_family":hero.to_lower()+"_focus","weapon_identity_version":VERSION,"actual_render_branch":"m68_paid_damage_material/"+hero+"/"+id,"max_draw_operations":96,"visual_extent":Vector2(210,170),"settled_only":true,"choreography":s.motif,"emblem":s.emblem,"rhythm":"double" if s.ultimate else "snap"}
static func draw_native(canvas:Object,point:Vector2,target:Vector2,unit:Dictionary,pose:Dictionary,factor:float=1.0,impacts:Array=[])->bool:
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0 or factor>16:return false
	var spec:=inspect_skill(unit,pose)
	if not bool(spec.get("supported",false)):return false
	var center:=target
	if spec.delivery=="SINGLE":
		for raw:Variant in impacts:
			if typeof(raw) in [TYPE_VECTOR2,TYPE_VECTOR2I] and Vector2(raw).is_finite():center=Vector2(raw);break
	var ctx:={"canvas":canvas,"count":0,"draw_limit":78,"phase":spec.phase,"quantum":maxf(1,roundf(factor))}
	var skill:=_skill(spec.id,spec.rank)
	draw_skill(ctx,point+Vector2(0,-18)*factor,center+Vector2(0,-9)*factor,factor*(1+.07*(int(spec.rank)-1)),skill)
	ctx.draw_limit=96
	if float(spec.phase)>.4 and float(spec.phase)<.8:
		for raw:Variant in impacts.slice(0,6):
			if typeof(raw) in [TYPE_VECTOR2,TYPE_VECTOR2I] and Vector2(raw).is_finite():Brush.stamp(ctx,Vector2(raw)+Vector2(0,-9)*factor,SHAPES["shard" if spec.hero=="OBSIDIAN_CANTOR" else "sac" if spec.hero=="MYCELIAL_CATALYST" else "seed" if spec.hero=="POLLEN_COMET" else "flux" if spec.hero=="FLUX_BOMBARDIER" else "page" if spec.hero=="CINDER_TESTATOR" else "mirror"],factor*.4,spec.palette,0,.7)
	return true
static func inspect_attack(unit:Dictionary,pose:Dictionary)->Dictionary:
	var hero:=str(unit.get("hero_archetype",""));var t:=float(pose.get("phase",-1))
	if not Data.has_hero(hero) or pose.get("action","")!="ATTACK" or int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not is_finite(t) or t<0 or t>=1:return {"supported":false}
	return {"supported":true,"signature":hero.to_lower()+"_focus","label":str(Data.raw_profile(hero).title),"faction":Data.raw_profile(hero).faction_id,"phase":t,"family":"RANGED","heavy":false,"visual_extent":Vector2(76,76),"particle_cap":12,"max_actions":96,"max_draw_operations":96,"max_impacts":6,"palette":PALETTES[hero].slice(1,4),"layers":["individual_focus","material_projectile","settled_hit"],"settled_only":true}
static func attack_plan(point:Vector2,target:Vector2,unit:Dictionary,pose:Dictionary,factor:float=1.0,_impacts:Array=[])->Array:
	var commands:Array=[]
	if not bool(inspect_attack(unit,pose).get("supported",false)) or not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0 or factor>16:return commands
	append_attack(commands,point+Vector2(0,-18)*factor,target+Vector2(0,-9)*factor,unit,pose,factor,24);return commands
