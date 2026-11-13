extends RefCounted
## Two authored ranged bodies and real-settled weapon/skill choreography.
## Code-native pixel masters, not stretched melee bodies or extra combat actors.
const Pixels=preload("res://src/presentation/heroic_expansion_actors_m66.gd")
const Palette=preload("res://src/presentation/strategic_side_palette.gd")
const Brush=preload("res://src/presentation/m63_av_brush.gd")
const Roles=preload("res://src/simulation/strategic_hero_roles_m68.gd")
const VERSION:="m68-ranged-physical-body-weapon-v1"
const SIZE:=Vector2i(48,48)
const FOOT:=Vector2(24,44)
const INK:=Color("17171f")
const MAX_FRAMES:=128
const PALETTES:={"EMBER_CAVALIER":["211c26","5d5057","ae907b","d78d4e","ffe0a0"],"SPORE_STALKER":["1c1925","53445f","a18aaa","8aba92","e5dbab"]}
const SILHOUETTES:={"EMBER_CAVALIER":"有缺口的高地羊皮兜帽、斜背三支熔砂矛、单手投矛器与不对称披风；没有重刃。","SPORE_STALKER":"六条折节足、低伏分瓣背甲、背负双轨弩和侧置试剂囊；没有双镰。"}
const SKILLS:={
	"EMBER_SEAL":["EMBER_CAVALIER","HIGHLAND","barbed_cinder_piton",["拉开投矛器，矛底抖落两粒暗炭","有倒钩的短矛沿真实单目标方向掷出","受击处两片烬钉交错，表示真实眩晕","矛尾熄灭；没有落地持续伤害区"]],
	"EMBER_SWEEP":["EMBER_CAVALIER","HIGHLAND","furnace_sand_corridor",["侧袋炉砂被扫入中空矛槽","三支细长砂矛沿同一窄直线错拍前进","真实命中点才出现一小簇余烬","火砂散尽；灼烧由真实状态按时结束"]],
	"EMBER_MEND":["EMBER_CAVALIER","HIGHLAND","terminal_furnace_javelin",["单独的重矛从背袋抽出，暗铁尾翼打开","长矛低弧射向单目标，不向旁人溅射","三节矛尾依次合拢，目标处出现短促破焰","矛影裂成三片暗铁，没有额外连爆"]],
	"SPORE_SEAL":["SPORE_STALKER","UNDERGROUND","closing_pore_pin",["背弩两片壳叶向内合拢","一枚空心钉刺直射真实单目标","钉刺孔口短促收合，纯控制不画伤害爆炸","两个弩齿闭合后熄灭；控制期限读真实状态"]],
	"SPORE_SWEEP":["SPORE_STALKER","UNDERGROUND","assay_chitin_bolt",["试剂囊被挤入一枚分叉短矢","短矢的壳片从后向前错开，轨迹不分裂","仅真实单目标出现三粒验脉晶屑","空心矢尾折断，不画毒雾或多目标命中"]],
	"SPORE_MEND":["SPORE_STALKER","UNDERGROUND","paired_crossbow_tension",["左右背弩轨依次张紧，试剂囊发出低亮","两条不对称菌筋沿自己的背甲绷紧","本人出现短促弩弦回弹，不画敌人受击","持续增益读真实source buff；没有额外移速效果"]],
}
const ICON_RECIPES:={"EMBER_SEAL":["arrow","pin"],"EMBER_SWEEP":["arrows","embers"],"EMBER_MEND":["arrow","lance"],"SPORE_SEAL":["bow","lock"],"SPORE_SWEEP":["arrow","extraction"],"SPORE_MEND":["bow","rift"],"INNATE_EMBER_CAVALIER":["quiver","embers"],"INNATE_SPORE_STALKER":["bow","companions"]}
const JAVELIN:=[Vector2(-15,-2),Vector2(7,-2),Vector2(8,-5),Vector2(16,0),Vector2(8,5),Vector2(7,2),Vector2(-15,2),Vector2(-12,0)]
const BOLT:=[Vector2(-10,-2),Vector2(-3,-2),Vector2(-1,-5),Vector2(10,0),Vector2(-1,5),Vector2(-3,2),Vector2(-10,2),Vector2(-6,0)]
static var _frames:Dictionary={}
static var _order:Array[String]=[]
static var _bakes:=0
static func supported(unit:Dictionary)->bool:return str(unit.get("unit_type",""))=="hero" and str(unit.get("hero_archetype","")) in Roles.IDS
static func reset_cache()->void:_frames.clear();_order.clear();_bakes=0
static func _r(im:Image,x:int,y:int,w:int,h:int,c:Color)->void:Pixels._r(im,x,y,w,h,c)
static func _p(im:Image,points:Array,c:Color)->void:Pixels._p(im,points,c)
static func _l(im:Image,a:Vector2i,b:Vector2i,c:Color,w:int=2)->void:Pixels._line(im,a,b,c,w)
static func frame(unit:Dictionary,pose:Dictionary={})->Dictionary:
	if not supported(unit):return {}
	var id:=str(unit.hero_archetype);var action:=str(pose.get("action","IDLE"))
	if action.begins_with("SKILL_") or action in ["HEAL","POTION"]:action="CAST"
	if action=="CARRY":action="WALK"
	if action=="HURT":action="HIT"
	if action not in ["IDLE","WALK","ATTACK","CAST","HIT","FALLEN"]:action="IDLE"
	var body_phase:=float(pose.get("body_phase_m76",pose.get("phase",0)))
	if not is_finite(body_phase):body_phase=0
	var bucket:=clampi(floori(body_phase*4),0,3)
	if action=="WALK":
		var body_tick:=float(pose.get("body_animation_tick_m76",pose.get("animation_tick",bucket*3)))
		bucket=posmod(floori(body_tick/3.0),4) if is_finite(body_tick) else 0
	if action=="FALLEN":bucket=0
	var mirror:=Vector2(pose.get("direction",Vector2.RIGHT)).x<0
	var side:=str(unit.get("side","PLAYER"));var key:=id+":"+side+":"+action+":"+str(bucket)+":"+str(mirror)
	if _frames.has(key):_order.erase(key);_order.append(key);return _frames[key]
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8);var colors:Array=PALETTES[id]
	var dark:=Color(colors[1]);var main:=Color(colors[2]);var accent:=Color(colors[3]);var light:=Color(colors[4]);var team:=Palette.side_color(side)
	var stride:=int([-4,-2,4,2][bucket]) if action=="WALK" else 0
	var bob:=-1 if action=="WALK" and bucket%2==0 else 0
	var retract:=(-2 if bucket==0 else -4 if bucket==1 else 3 if bucket==2 else 0) if action=="ATTACK" else 0
	if action=="HIT":bob=1 if bucket<2 else 0;retract=-2 if bucket<2 else 0
	var cast_lift:=bucket if action=="CAST" else 0
	if id=="EMBER_CAVALIER":_ember(im,dark,main,accent,light,team,stride,bob,retract,cast_lift)
	else:_spore(im,dark,main,accent,light,team,stride,bob,retract,cast_lift)
	if action=="HIT":_r(im,20,22+bucket%2,5,2,light);_r(im,16,24,2,3,accent)
	if action=="FALLEN":
		var saved:=im.duplicate() as Image;im.fill(Color.TRANSPARENT);var used:=saved.get_used_rect()
		for y:int in range(used.position.y,used.end.y):
			for x:int in range(used.position.x,used.end.x):
				var c:=saved.get_pixel(x,y)
				if c.a>.5:_r(im,9+(y-used.position.y)*3/4,35+(x-used.position.x)/5,1,1,c.darkened(.25))
	var source:=im.duplicate() as Image
	for y:int in range(2,46):
		for x:int in range(2,46):
			if source.get_pixel(x,y).a<.5:continue
			for d:Vector2i in [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
				if source.get_pixelv(Vector2i(x,y)+d).a<.5:im.set_pixelv(Vector2i(x,y)+d,INK)
	if mirror:im.flip_x()
	var anchor:=Vector2(47-FOOT.x,FOOT.y) if mirror else FOOT
	var used:=im.get_used_rect();var cropped:=im.get_region(used)
	var result:={"key":key,"image":cropped,"texture":ImageTexture.create_from_image(cropped),"rect":Rect2(Vector2(used.position)-anchor,Vector2(used.size)),"action":action,"bucket":bucket,"mirror":mirror,"pixel_hash":cropped.get_data().hex_encode().sha256_text(),"category":"m68_authored_ranged_hero","identity":id,"provenance":"original-code-pixel-m68","silhouette":SILHOUETTES[id],"motion_refinement_version":"m76-authored-four-phase-v1"}
	while _order.size()>=MAX_FRAMES:_frames.erase(_order.pop_front())
	_frames[key]=result;_order.append(key);_bakes+=1
	return result
static func _ember(im:Image,dark:Color,main:Color,accent:Color,light:Color,team:Color,stride:int,bob:int,retract:int,lift:int)->void:
	# Sloped three-javelin rack precedes an uneven wool cape, no sword silhouette.
	for i:int in range(3):
		_l(im,Vector2i(12+i*3,32),Vector2i(9+i*4,7+i*2),dark,3)
		_p(im,[Vector2(6+i*4,8+i*2),Vector2(9+i*4,3+i*2),Vector2(12+i*4,8+i*2)],main)
		_r(im,8+i*4,7+i*2,2,3,accent)
	_p(im,[Vector2(14,19+bob),Vector2(21,17+bob),Vector2(25,27+bob),Vector2(20,38+bob),Vector2(16,35+bob),Vector2(11,37+bob),Vector2(10,28+bob)],dark)
	_p(im,[Vector2(13,23+bob),Vector2(17,21+bob),Vector2(18,33+bob),Vector2(13,34+bob)],accent.darkened(.28))
	for side:int in [-1,1]:
		var x:=24+side*4;var s:=stride*side
		_p(im,[Vector2(x-3,32),Vector2(x+3,32),Vector2(x+2+s/2,39),Vector2(x+4+s/2,42),Vector2(x-4+s/2,42),Vector2(x-3,37)],dark)
		_r(im,x-2+s/2,36,3,3,main);_r(im,x-3+s/2,41,6,2,main)
	_p(im,[Vector2(20,20+bob),Vector2(26,18+bob),Vector2(31,24+bob),Vector2(30,33+bob),Vector2(20,34+bob),Vector2(17,27+bob)],main)
	_p(im,[Vector2(21,22+bob),Vector2(25,21+bob),Vector2(27,30+bob),Vector2(22,32+bob)],team)
	_r(im,21,32+bob,9,2,dark);_r(im,25,32+bob,2,2,light)
	_p(im,[Vector2(18,14+bob),Vector2(20,8+bob),Vector2(26,6+bob),Vector2(31,11+bob),Vector2(31,18+bob),Vector2(26,21+bob),Vector2(20,18+bob)],dark)
	_p(im,[Vector2(21,12+bob),Vector2(27,10+bob),Vector2(29,14+bob),Vector2(27,18+bob),Vector2(22,17+bob)],Color("d7b58d"))
	_r(im,26,12+bob,3,2,INK);_r(im,28,15+bob,2,2,Color("d7b58d"))
	_l(im,Vector2i(21,9+bob),Vector2i(25,8+bob),light,2)
	# One bent throwing arm, a dark mechanical fork and a long loaded javelin.
	_l(im,Vector2i(29,23+bob),Vector2i(31+retract,27-lift),dark,4)
	_l(im,Vector2i(31+retract,27-lift),Vector2i(36+retract,22-lift),main,3)
	_p(im,[Vector2(30+retract,21-lift),Vector2(39+retract,18-lift),Vector2(42+retract,21-lift),Vector2(38+retract,24-lift),Vector2(34+retract,24-lift)],dark)
	_l(im,Vector2i(29+retract,19-lift),Vector2i(41+retract,17-lift),main,2)
	_p(im,[Vector2(39+retract,16-lift),Vector2(44+retract,17-lift),Vector2(40+retract,19-lift)],light)
	_r(im,33+retract,19-lift,3,2,accent)
	_r(im,15,23+bob,4,4,team)
static func _spore(im:Image,dark:Color,main:Color,accent:Color,light:Color,team:Color,stride:int,bob:int,retract:int,lift:int)->void:
	for i:int in range(3):
		for side:int in [-1,1]:
			var at:=Vector2i(16+i*6,29+bob);var offset:=stride*(1 if i%2==0 else -1)
			var knee:=at+Vector2i(side*5,5+offset/2);var tip:=knee+Vector2i(side*3,7-offset/2)
			_l(im,at,knee,main,3);_l(im,knee,tip,dark,2);_r(im,knee.x-1,knee.y-1,2,2,accent)
	_p(im,[Vector2(11,25+bob),Vector2(15,18+bob),Vector2(24,15+bob),Vector2(33,20+bob),Vector2(36,28+bob),Vector2(31,34+bob),Vector2(17,34+bob),Vector2(10,30+bob)],dark)
	_p(im,[Vector2(15,24+bob),Vector2(18,20+bob),Vector2(23,18+bob),Vector2(24,27+bob),Vector2(19,31+bob),Vector2(14,29+bob)],main)
	_p(im,[Vector2(26,20+bob),Vector2(31,23+bob),Vector2(32,29+bob),Vector2(26,31+bob),Vector2(25,26+bob)],accent.darkened(.3))
	_r(im,18,29+bob,10,3,team);_r(im,21,30+bob,3,1,light)
	# Forward sighting head and lateral sample flasks are unlike the melee mantis.
	_p(im,[Vector2(27,18+bob),Vector2(31,14+bob),Vector2(36,17+bob),Vector2(36,23+bob),Vector2(31,25+bob),Vector2(28,22+bob)],main)
	_r(im,31,17+bob,5,2,INK);_r(im,33,17+bob,2,1,accent)
	for y:int in [23,28]:_r(im,10,y+bob,4,4,main);_r(im,11,y+1+bob,2,2,accent)
	# Two separated rail limbs, bent string and short horizontal bolt.
	for side:int in [-1,1]:
		var y:=15+side*(4+lift)
		_l(im,Vector2i(20,y),Vector2i(31+retract/2,y-side*3),main,3)
		_l(im,Vector2i(31+retract/2,y-side*3),Vector2i(37+retract/2,15),dark,2)
		_r(im,24,y-side,4,2,accent)
	_l(im,Vector2i(19-retract/2,10-lift),Vector2i(23-retract/2,15),light,1)
	_l(im,Vector2i(23-retract/2,15),Vector2i(19-retract/2,20+lift),light,1)
	_l(im,Vector2i(20+retract,15),Vector2i(39+retract,15),dark,3)
	_l(im,Vector2i(22+retract,15),Vector2i(40+retract,15),light,1)
	_p(im,[Vector2(38+retract,12),Vector2(44+retract,15),Vector2(38+retract,18)],accent)
static func factor(radius:float)->float:return radius/14.0*1.35 if is_finite(radius) and radius>0 else 0.0
static func visual_bounds(unit:Dictionary,radius:float,pose:Dictionary={})->Rect2:
	var f:=frame(unit,pose);return Rect2(f.rect.position*factor(radius),f.rect.size*factor(radius)) if not f.is_empty() else Rect2()
static func stable_visual_bounds(_unit:Dictionary,radius:float)->Rect2:return Rect2(Vector2(-25,-44)*factor(radius),Vector2(50,48)*factor(radius))
static func ground_footprint(unit:Dictionary,radius:float)->Vector2:return Vector2(radius*(2.4 if unit.get("hero_archetype")=="SPORE_STALKER" else 1.9),radius*.72)
static func draw(canvas:Object,point:Vector2,unit:Dictionary,radius:float,pose:Dictionary)->void:
	if factor(radius)<=0 or not point.is_finite():return
	var f:=frame(unit,pose);var r:=visual_bounds(unit,radius,pose)
	if canvas is CanvasItem:canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect(f.texture,Rect2((point+r.position).round(),r.size),false)
static func body_contains(unit:Dictionary,radius:float,pose:Dictionary,offset:Vector2)->bool:
	if factor(radius)<=0 or not offset.is_finite():return false
	var f:=frame(unit,pose);var at:=Vector2i((offset/factor(radius)-f.rect.position).floor())
	return Rect2i(Vector2i.ZERO,f.image.get_size()).has_point(at) and f.image.get_pixelv(at).a>.1
static func inspect(unit:Dictionary,pose:Dictionary={})->Dictionary:
	if not supported(unit):return {"supported":false}
	var f:=frame(unit,pose).duplicate();f.erase("texture");f.erase("image")
	f.merge({"supported":true,"original_art":true,"generated_art":false,"licensed_art":false,"coarse_outline_pixels":2,"foot_anchor":FOOT,"body_reused":false,"non_color_features":SILHOUETTES[str(unit.hero_archetype)],"version":VERSION})
	return f
static func debug_stats()->Dictionary:
	var bytes:=0
	for cached:Dictionary in _frames.values():bytes+=cached.image.get_width()*cached.image.get_height()*4
	return {"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"texture_bytes":bytes,"maximum_texture_bytes":MAX_FRAMES*48*48*4,"runtime_rng":false}
static func icon_recipe(id:String)->Array:return ICON_RECIPES.get(id,[]).duplicate()
static func actor_profile(unit:Dictionary)->Dictionary:
	if not supported(unit):return {}
	var id:=str(unit.hero_archetype)
	return {"identity":"hero:"+id,"hero_id":id,"faction_id":"HIGHLAND" if id=="EMBER_CAVALIER" else "UNDERGROUND","gesture":"loaded_thrower" if id=="EMBER_CAVALIER" else "double_rail_bow","story_anchor":Roles.STORIES[id],"sound":{"voice":"scrape" if id=="EMBER_CAVALIER" else "snap","frequency":310 if id=="EMBER_CAVALIER" else 670,"texture":.26,"pulses":2,"rhythm":"falling_weight" if id=="EMBER_CAVALIER" else "staggered_reprise","seconds":.34,"overtone":1.6,"sweep":-.12,"echo":.04}}
static func signature_for(unit:Dictionary)->String:return "CINDER_JAVELIN" if unit.get("hero_archetype")=="EMBER_CAVALIER" else "ASSAY_CROSSBOW" if unit.get("hero_archetype")=="SPORE_STALKER" else ""
static func inspect_attack(unit:Dictionary,pose:Dictionary)->Dictionary:
	var t:=float(pose.get("phase",0))
	if not supported(unit) or pose.get("action")!="ATTACK" or int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not is_finite(t) or t<0 or t>=1:return {"supported":false}
	return {"supported":true,"signature":signature_for(unit),"family":"PROJECTILE","heavy":false,"phase":t,"label":"投烬矛" if unit.hero_archetype=="EMBER_CAVALIER" else "验脉弩矢","settled_only":true,"visual_extent":Vector2(64,48),"max_draw_operations":72,"max_impacts":1,"particle_cap":8,"version":VERSION,"attack_type":str(unit.get("last_action_attack_type",unit.get("attack_type","CHAOS")))}
static func attack_plan(point:Vector2,target:Vector2,unit:Dictionary,pose:Dictionary,scale:float=1.0,_impact_points:Array=[])->Array:
	var commands:Array=[]
	if not inspect_attack(unit,pose).get("supported",false) or not point.is_finite() or not target.is_finite() or not is_finite(scale) or scale<=0:return commands
	var t:=float(pose.phase);var q:=clampf((t-.18)/.48,0,1);var alpha:=clampf(minf(t*8,(1-t)*7),0,1)
	var origin:=point+Vector2(0,-23)*scale;var at:=origin.lerp(target+Vector2(0,-12)*scale,q)
	var id:=str(unit.hero_archetype);var ctx:={"commands":commands,"count":0,"draw_limit":72,"phase":t,"quantum":maxf(1,roundf(scale))}
	var palette:Array=PALETTES[id];var angle:=origin.angle_to_point(target)
	if id=="EMBER_CAVALIER":at.y-=sin(q*PI)*12*scale
	Brush.stamp(ctx,at,JAVELIN if id=="EMBER_CAVALIER" else BOLT,scale*.5,palette,angle,alpha)
	if q>.35:Brush.streak(ctx,at-Vector2(14,0).rotated(angle)*scale,at,scale,Color(str(palette[3]),alpha*.65))
	if q>.8:
		for i:int in range(3):Brush.chip(ctx,target+Vector2((i-1)*(4+(q-.8)*20),-12-i%2*6)*scale,Vector2(1,2)*scale,Color(str(palette[3+i%2]),alpha))
	return commands
static func skill_profile(id:String)->Dictionary:
	if not SKILLS.has(id):return {}
	var row:Array=SKILLS[id];var hero:=str(row[0]);var ultimate:=id in ["EMBER_MEND","SPORE_MEND"]
	return {"skill_id":id,"hero_id":hero,"faction_id":row[1],"gesture":row[2],"phases":row[3].duplicate(),"palette":PALETTES[hero].duplicate(),"identity_version":VERSION,"story_anchor":Roles.STORIES[hero],"counterplay":"投射距离换较低身板；单体可被前排吸引，直线要分散。","passive":false,"sound":{"voice":"crack" if hero=="EMBER_CAVALIER" else "scrape","frequency":280 if hero=="EMBER_CAVALIER" else 560,"texture":.3,"pulses":3 if ultimate else 2,"rhythm":"falling_weight" if hero=="EMBER_CAVALIER" else "staggered_reprise","seconds":1.3 if ultimate else .65,"overtone":1.7,"sweep":-.2 if hero=="EMBER_CAVALIER" else .15,"echo":.12}}
static func inspect_skill(unit:Dictionary,pose:Dictionary)->Dictionary:
	var action:=str(pose.get("action",""));var id:=action.trim_prefix("SKILL_");var skill:Dictionary=pose.get("skill",{});var phase:=float(pose.get("phase",0))
	if not supported(unit) or not action.begins_with("SKILL_") or not SKILLS.has(id) or str(SKILLS[id][0])!=str(unit.hero_archetype) or int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not is_finite(phase) or phase<0 or phase>=1 or str(skill.get("id",""))!=id or int(skill.get("level",0))<1 or bool(skill.get("passive",false)):return {"supported":false}
	var canonical:=Roles.apply_skill(skill,id,int(skill.level));var info:=skill_profile(id)
	return {"supported":true,"id":id,"profile":"m68_ranged_"+id.to_lower(),"signature":info.gesture,"family":"ranged_physical","motif":info.gesture,"layers":["coarse_pixel_outline","loaded_ranged_weapon","truthful_projectile","settled_primary_feedback"],"visual_extent":Vector2(180,130),"particle_cap":12,"max_draw_operations":96,"ultimate":bool(canonical.get("ultimate",false)),"rank":canonical.level,"phase":phase,"at_self":canonical.target_mode=="SELF","delivery":canonical.delivery,"target_shape":"self" if canonical.target_mode=="SELF" else str(canonical.delivery).to_lower(),"effect":canonical.effect,"faction":info.faction_id,"settled_only":true,"palette":info.palette,"palette_roles":["ink","shadow","material","accent","core"],"palette_story":info.story_anchor,"choreography":info.gesture,"rhythm":"real_phase","weapon_family":info.gesture,"weapon_motif":info.gesture,"weapon_motion":" / ".join(PackedStringArray(info.phases)),"weapon_phase_signature":" / ".join(PackedStringArray(info.phases)),"weapon_identity_version":VERSION,"m68_presentation_version":VERSION,"visual_extent_is_hit_range":false,"authoritative_radius":canonical.radius,"line_width":canonical.get("line_width",0),"cone_width":0}
static func draw_native(canvas:Object,point:Vector2,target:Vector2,unit:Dictionary,pose:Dictionary,scale:float=1.0,impact_points:Array=[])->bool:
	var entry:=inspect_skill(unit,pose)
	if not bool(entry.get("supported",false)) or not point.is_finite() or not target.is_finite() or not is_finite(scale) or scale<=0:return false
	var origin:=point+Vector2(0,-21)*scale;var center:=point if bool(entry.at_self) else target
	if entry.delivery=="SINGLE" and not entry.at_self:
		for hit:Variant in impact_points:
			if hit is Vector2 and hit.is_finite():center=hit;break
	center+=Vector2(0,-8)*scale
	var ctx:={"canvas":canvas,"count":0,"draw_limit":96,"phase":entry.phase,"quantum":maxf(1,roundf(scale))}
	draw_skill(ctx,origin,center,scale*(1.0+.08*(int(entry.rank)-1)),entry)
	# Only published settled points receive aftermath; no old blade/beam wash.
	if entry.delivery=="LINE" and float(entry.phase)>.5:
		for hit:Variant in impact_points.slice(0,3):
			if hit is Vector2 and hit.is_finite():Brush.chip(ctx,hit+Vector2(0,-8)*scale,Vector2(2,3)*scale,Color(str(entry.palette[3]),.8*(1-float(entry.phase))))
	return true
static func draw_skill(ctx:Dictionary,origin:Vector2,center:Vector2,scale:float,entry:Dictionary)->bool:
	var id:=str(entry.get("id",""))
	if not SKILLS.has(id):return false
	var hero:=str(SKILLS[id][0]);var palette:Array=PALETTES[hero];var t:=float(ctx.phase)
	var q:=clampf((t-.15)/.65,0,1);var alpha:=clampf(minf(t*7,(1-t)*7),0,1);var angle:=origin.angle_to_point(center)
	if id=="SPORE_MEND":
		for side:int in [-1,1]:
			var at:=origin+Vector2(side*(10+q*5),-7+side*2)*scale
			Brush.stamp(ctx,at,BOLT,scale*.5,palette,side*.25,alpha)
			Brush.streak(ctx,at,origin+Vector2(side*4,4)*scale,scale,Color(str(palette[3]),alpha*.7))
		return true
	if id=="EMBER_SWEEP":
		for i:int in range(3):
			var progress:=clampf(q*1.4-float(i)*.18,0,1);var at:=origin.lerp(center,progress)+Vector2(0,-4+i*3)*scale
			Brush.stamp(ctx,at,JAVELIN,scale*.45,palette,angle,alpha)
		return true
	var at:=origin.lerp(center,q)
	if hero=="EMBER_CAVALIER":at.y-=sin(q*PI)*(24 if id=="EMBER_MEND" else 13)*scale
	Brush.stamp(ctx,at,JAVELIN if hero=="EMBER_CAVALIER" else BOLT,scale*(.95 if id=="EMBER_MEND" else .65),palette,angle,alpha)
	if q>.65:
		if id=="SPORE_SEAL":
			for side:int in [-1,1]:Brush.streak(ctx,center+Vector2(side*(12-q*8),-8)*scale,center+Vector2(side*3,4)*scale,scale*2,Color(str(palette[3]),alpha))
		else:
			for i:int in range(4 if id=="EMBER_MEND" else 3):Brush.chip(ctx,center+Vector2((i-1)*(4+q*7),-5-q*9+(i%2)*8)*scale,Vector2(1+(i%2),2)*scale,Color(str(palette[3+i%2]),alpha))
	return true
