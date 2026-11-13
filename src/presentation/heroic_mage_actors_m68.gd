extends RefCounted
## Original coarse-pixel caster silhouettes; no troop reuse or combat writes.
const Data=preload("res://src/simulation/strategic_hero_mages_m68.gd")
const Palette=preload("res://src/presentation/strategic_side_palette.gd")
const SIZE:=Vector2i(48,48)
const MAX_FRAMES:=192
const INK:=Color("17171f")
const RAMPS:={"HUMAN":["635950","b49c74","ebddb0","9dc5cb"],"UNDEAD":["57485d","a28b9c","d7ceb2","90bfac"],"MACHINE":["44555e","8ba4b3","c8d8d0","d6a56c"],"FOREST":["3f594a","8da874","d8dca4","d7a0bb"],"HIGHLAND":["504655","8a7f91","d1c7ac","dfa16a"],"UNDERGROUND":["503f63","9478aa","c7b69a","a8c77e"]}
static var _frames:Dictionary={}
static var _order:Array[String]=[]
static var _bakes:=0
static func supported(unit:Dictionary)->bool:return unit.get("unit_type","")=="hero" and Data.has_hero(str(unit.get("hero_archetype","")))
static func reset_cache()->void:_frames.clear();_order.clear();_bakes=0
static func _r(im:Image,x:int,y:int,w:int,h:int,c:Color)->void:
	var rect:=Rect2i(x,y,w,h).intersection(Rect2i(Vector2i.ZERO,SIZE))
	if rect.size.x>0 and rect.size.y>0:im.fill_rect(rect,c)
static func _p(im:Image,vertices:Array,c:Color)->void:
	var shape:=PackedVector2Array(vertices)
	for y:int in range(2,46):
		for x:int in range(2,46):
			if Geometry2D.is_point_in_polygon(Vector2(x,y),shape):im.set_pixel(x,y,c)
static func _l(im:Image,a:Vector2i,b:Vector2i,c:Color,w:int=2)->void:
	var n:=maxi(absi(b.x-a.x),absi(b.y-a.y))
	for i:int in range(n+1):
		var point:=Vector2i(Vector2(a).lerp(Vector2(b),float(i)/maxi(1,n)).round())
		_r(im,point.x-w/2,point.y-w/2,w,w,c)
static func frame(unit:Dictionary,pose:Dictionary={})->Dictionary:
	if not supported(unit):return {}
	var id:=str(unit.hero_archetype);var faction:=str(Data.raw_profile(id).faction_id)
	var action:=str(pose.get("action","IDLE"))
	# Opt-in only: keep every old action/key/pixel path byte-equivalent when
	# the shared R7 cast projection did not supply an actual cast progress.
	var r7_gesture:=id in ["CINDER_TESTATOR","MYCELIAL_CATALYST"] and pose.has("r7_cast_progress") and (action in ["SKILL","CAST"] or action.begins_with("SKILL_"))
	var r7_progress:=0.0
	if r7_gesture:
		var raw_progress:Variant=pose.r7_cast_progress
		if typeof(raw_progress) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(raw_progress)):
			r7_gesture=false
		else:
			r7_progress=clampf(float(raw_progress),0.0,1.0)
			action="CAST"
	if action.begins_with("SKILL_"):action="CAST"
	if action in ["HEAL","POTION","HARVEST","MINE","BUILD"]:action="CAST"
	if action not in ["IDLE","WALK","CARRY","ATTACK","CAST","HIT","HURT","FALLEN"]:action="IDLE"
	var body_phase:=float(pose.get("body_phase_m76",pose.get("phase",0)))
	if not is_finite(body_phase):body_phase=0
	var bucket:=clampi(floori(body_phase*4),0,3)
	if action in ["WALK","CARRY"]:
		var body_tick:=float(pose.get("body_animation_tick_m76",pose.get("animation_tick",bucket*3)))
		bucket=posmod(floori(body_tick/3.0),4) if is_finite(body_tick) else 0
	if action=="FALLEN":bucket=0
	if r7_gesture:bucket=clampi(floori(r7_progress*8.0),0,7)
	var mirror:=Vector2(pose.get("direction",Vector2.RIGHT)).x<0;var side:=str(unit.get("side","PLAYER"))
	var key:=id+":"+side+":"+action+":"+str(bucket)+":"+str(mirror)
	if r7_gesture:key+=":r7-gesture8"
	if _frames.has(key):_order.erase(key);_order.append(key);return _frames[key]
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8);var ramp:Array=RAMPS[faction]
	var d:=Color(ramp[0]);var b:=Color(ramp[1]);var h:=Color(ramp[2]);var a:=Color(ramp[3]);var team:=Palette.side_color(side)
	var bob:=-1 if action in ["WALK","CARRY"] and bucket%2==0 else 0
	var step:=int([-4,-2,4,2][bucket]) if action in ["WALK","CARRY"] else 0
	if action in ["HIT","HURT"]:bob=1 if bucket<2 else 0
	var reach:=bucket*2 if action in ["CAST","ATTACK"] else 0
	match id:
		"SUNGLASS_SCRIBE":
			_p(im,[Vector2(16,23+bob),Vector2(28,22+bob),Vector2(34+step/2,39),Vector2(25-step/3,42),Vector2(12-step/2,39)],d)
			_p(im,[Vector2(18,24+bob),Vector2(26,24+bob),Vector2(29+step/2,36),Vector2(20-step/2,39)],b)
			_r(im,19,26+bob,5,11,team);_r(im,19-step/2,38,5,4,h);_r(im,28+step/2,39,5,3,b)
			_r(im,19,14+bob,10,9,h);_r(im,22,17+bob,8,2,INK)
			_p(im,[Vector2(15,15+bob),Vector2(17,7+bob),Vector2(23,10+bob),Vector2(29,5+bob),Vector2(33,14+bob)],b)
			_l(im,Vector2i(35,39),Vector2i(35+reach/3,10),h)
			_p(im,[Vector2(32,10),Vector2(36,5),Vector2(41,10),Vector2(36,15)],a)
			_p(im,[Vector2(8,24-reach/2),Vector2(15,22-reach/2),Vector2(21,25-reach/2),Vector2(20,32-reach/2),Vector2(14,29-reach/2),Vector2(8,31-reach/2)],h)
		"CINDER_TESTATOR":
			if r7_gesture:
				_cinder_cast8(im,bucket,d,b,h,a,team)
			else:
				_p(im,[Vector2(16,19+bob),Vector2(28,17+bob),Vector2(33+step/2,40),Vector2(26+step/2,42),Vector2(23,36),Vector2(17-step/2,43),Vector2(12-step/2,38)],d)
				_p(im,[Vector2(18,26+bob),Vector2(23,22+bob),Vector2(27+step/2,40),Vector2(20-step/2,38)],b)
				_p(im,[Vector2(16,20+bob),Vector2(18,9+bob),Vector2(25,5+bob),Vector2(31,15+bob),Vector2(29,23+bob),Vector2(25,17+bob),Vector2(21,19+bob)],b)
				_r(im,21,13+bob,7,6,h);_r(im,23,15+bob,6,2,INK);_r(im,18,25,4,9,team)
				_l(im,Vector2i(34,38),Vector2i(37,17-reach/2),d,3)
				_p(im,[Vector2(30,20-reach/2),Vector2(35,14-reach/2),Vector2(41,16-reach/2),Vector2(42,23-reach/2),Vector2(35,26-reach/2)],h)
				_r(im,35,18-reach/2,2,7,a);_r(im,10,31,3,6,h)
		"FLUX_BOMBARDIER":
			for x:int in [13,25,33]:_l(im,Vector2i(23,30),Vector2i(x+step,41),d,4)
			_p(im,[Vector2(12,19+bob),Vector2(24,13+bob),Vector2(33,20+bob),Vector2(31,34+bob),Vector2(16,36+bob)],b)
			_r(im,16,24+bob,12,6,team);_r(im,17,31+bob,11,2,h)
			_r(im,19,8+bob,8,11,d);_r(im,21,11+bob,6,3,a)
			for y:int in [17,22,27]:_r(im,28,y+bob,12+reach/3,3,d);_r(im,31,y+bob,8+reach/3,1,h)
			_r(im,9,22+bob,5,9,d);_r(im,10,24+bob,3,3,a)
		"POLLEN_COMET":
			for sign:int in [-1,1]:
				_p(im,[Vector2(23,23+bob),Vector2(23+sign*14,14+bob-step/2),Vector2(23+sign*16,25+bob),Vector2(23+sign*7,33+bob)],d)
				_l(im,Vector2i(23,25+bob),Vector2i(23+sign*12,20+bob-step/2),a)
			_p(im,[Vector2(18,23+bob),Vector2(28,23+bob),Vector2(33,34+bob),Vector2(23,39+bob),Vector2(14,34+bob)],b)
			_r(im,21,25+bob,5,10,team);_r(im,20,13+bob,8,9,h)
			_p(im,[Vector2(15,15+bob),Vector2(20,6+bob),Vector2(24,11+bob),Vector2(30,7+bob),Vector2(32,17+bob)],b)
			_r(im,24,16+bob,5,2,INK);_l(im,Vector2i(32,35),Vector2i(36,22-reach),h)
			_r(im,35,18-reach,4,4,a);_r(im,20,39+bob,3,3,h)
		"OBSIDIAN_CANTOR":
			_p(im,[Vector2(11,22+bob),Vector2(19,17+bob),Vector2(29,19+bob),Vector2(36+step/2,34),Vector2(31+step/2,41),Vector2(13-step/2,41)],d)
			_p(im,[Vector2(19,23+bob),Vector2(28,23+bob),Vector2(31+step/2,38),Vector2(18-step/2,39)],b)
			_r(im,20,28+bob,6,9,team);_r(im,16-step/2,39,6,4,h);_r(im,28+step/2,39,6,4,h)
			_p(im,[Vector2(16,19+bob),Vector2(18,7+bob),Vector2(24,4+bob),Vector2(29,9+bob),Vector2(31,21+bob)],d)
			_r(im,21,14+bob,8,3,a);_r(im,22,16+bob,4,4,INK)
			_l(im,Vector2i(37,39),Vector2i(39,12-reach/3),h,3)
			_p(im,[Vector2(34,15-reach/3),Vector2(35,7-reach/3),Vector2(40,3-reach/3),Vector2(43,12-reach/3),Vector2(41,19-reach/3)],b)
		"MYCELIAL_CATALYST":
			if r7_gesture:
				_myc_cast8(im,bucket,d,b,h,a,team)
			else:
				for i:int in range(2):
					for sign:int in [-1,1]:_l(im,Vector2i(17+i*11,29+bob),Vector2i(17+i*11+sign*9,40+step*(1 if i%2 else -1)/2),b,3)
				_p(im,[Vector2(13,29+bob),Vector2(15,18+bob),Vector2(22,12+bob),Vector2(31,15+bob),Vector2(36,26+bob),Vector2(29,34+bob),Vector2(18,34+bob)],d)
				_p(im,[Vector2(16,25+bob),Vector2(18,18+bob),Vector2(26,16+bob),Vector2(31,22+bob),Vector2(29,29+bob),Vector2(19,31+bob)],b)
				_r(im,17,24+bob,5,4,team);_r(im,25,18+bob,5,7,a);_r(im,24,20+bob,2,2,h)
				for x:int in [13,20,30]:_r(im,x,10+bob,4,6,a)
				_l(im,Vector2i(30,27+bob),Vector2i(40,22-reach/2),h,3);_r(im,39,20-reach/2,4,5,a)
	if action in ["HIT","HURT"]:_r(im,20,24,8,2,h)
	if action=="CAST" and not r7_gesture:_r(im,34,19-bucket,3,3,a);_r(im,37,16-bucket,2,2,h)
	if action=="FALLEN":
		var saved:=im.duplicate() as Image;im.fill(Color.TRANSPARENT)
		for y:int in range(2,46):
			for x:int in range(2,46):
				var c:=saved.get_pixel(x,y)
				if c.a>.5:_r(im,8+y*3/4,31+x/4,1,1,c.darkened(.2))
	var original:=im.duplicate() as Image
	for y:int in range(2,46):
		for x:int in range(2,46):
			if original.get_pixel(x,y).a<.5:continue
			for delta:Vector2i in [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
				if original.get_pixelv(Vector2i(x,y)+delta).a<.5:im.set_pixelv(Vector2i(x,y)+delta,INK)
	if mirror:im.flip_x()
	var foot:=Vector2(23,44) if mirror else Vector2(24,44);var used:=im.get_used_rect();var cropped:=im.get_region(used)
	var result:={"key":key,"image":cropped,"texture":ImageTexture.create_from_image(cropped),"rect":Rect2(Vector2(used.position)-foot,Vector2(used.size)),"action":action,"bucket":bucket,"mirror":mirror,"pixel_hash":cropped.get_data().hex_encode().sha256_text(),"category":"m68_damage_mage","identity":id,"provenance":"original-code-pixel-m68","original_art":true,"licensed_art":false,"motion_refinement_version":"m76-authored-four-phase-v1"}
	if r7_gesture:
		result.motion_refinement_version="r7-authored-body-gesture8-v4"
		result["r7_body_gesture"]=true
	while _order.size()>=MAX_FRAMES:_frames.erase(_order.pop_front())
	_frames[key]=result;_order.append(key);_bakes+=1;return result

static func _cinder_cast8(im:Image,k:int,d:Color,b:Color,h:Color,a:Color,team:Color)->void:
	# Torso/hood lean, both elbows, wrists, book opening and robe weight all
	# move. No added VFX layer is used as a substitute for a body pose.
	var lean:int=[-2,-3,-2,-1,1,3,2,0][k]
	var duck:int=[1,2,1,0,0,1,1,0][k]
	var hem:int=[-1,-2,-1,1,2,1,-1,0][k]
	var off:=Vector2i([12,10,9,10,12,14,13,12][k],[32,29,24,20,21,26,30,32][k])
	var hand:=Vector2i([29,28,29,31,34,35,33,30][k],[28,24,20,16,18,24,27,29][k])
	var elbow:=Vector2i([27,25,25,27,30,32,30,28][k],[30,29,26,23,24,28,30,31][k])
	# Back sleeve before the torso, then the casting sleeve in front.
	_l(im,Vector2i(17+lean,25+duck),off,d,5)
	_r(im,off.x-1,off.y-1,3,4,h)
	_p(im,[Vector2(16+lean,20+duck),Vector2(28+lean,18+duck),Vector2(31+lean,30),Vector2(33+hem,40),Vector2(27,42),Vector2(24,37+duck),Vector2(18,43),Vector2(12+hem,39)],d)
	_p(im,[Vector2(18+lean,25+duck),Vector2(23+lean,23+duck),Vector2(27+hem,39),Vector2(21+hem,38)],b)
	_p(im,[Vector2(18+lean,26+duck),Vector2(22+lean,25+duck),Vector2(24+lean,36),Vector2(19+lean,35)],team)
	_l(im,Vector2i(17,38),Vector2i(18,42),b,3)
	_l(im,Vector2i(27,38),Vector2i(28,42),d,3)
	# Preserve the pointed hood, pale face strip and dark eye line identity.
	_p(im,[Vector2(16+lean,21+duck),Vector2(18+lean,10+duck),Vector2(25+lean,5+duck),Vector2(31+lean,16+duck),Vector2(29+lean,24+duck),Vector2(25+lean,18+duck),Vector2(21+lean,20+duck)],b)
	_r(im,21+lean,14+duck,7,6,h)
	_r(im,23+lean,16+duck,6,2,INK)
	_l(im,Vector2i(27+lean,25+duck),elbow,d,5)
	_l(im,elbow,hand,b,4)
	_r(im,hand.x-1,hand.y-1,4,3,h)
	var w:int=[8,8,10,12,12,10,10,8][k]
	var bx:=hand.x+1
	var by:=hand.y-1
	_p(im,[Vector2(bx-w/2-1,by-6),Vector2(bx,by-4),Vector2(bx+w/2,by-6),Vector2(bx+w/2,by+5),Vector2(bx,by+7),Vector2(bx-w/2-1,by+5)],d)
	_p(im,[Vector2(bx-w/2+1,by-4),Vector2(bx,by-2),Vector2(bx+w/2-1,by-4),Vector2(bx+w/2-1,by+3),Vector2(bx,by+5),Vector2(bx-w/2+1,by+3)],h)
	_l(im,Vector2i(bx,by-3),Vector2i(bx,by+4),a,1)
	_l(im,Vector2i(bx+2,by-1),Vector2i(bx+w/2-2,by-2),b,1)
	_r(im,11+hem,33,5,7,d)
	_r(im,12+hem,35,3,2,h)

static func _myc_cast8(im:Image,k:int,d:Color,b:Color,h:Color,a:Color,team:Color)->void:
	# Four grounded legs compress, brace and push; the sack shifts forward
	# while the front nozzle rises, whips forward and returns independently.
	var lean:int=[-1,-2,-1,1,3,4,2,0][k]
	var down:int=[2,4,3,1,0,-1,1,2][k]
	var rear:=Vector2i([10,9,8,8,7,8,9,10][k],[41,42,42,41,41,42,42,41][k])
	var front:=Vector2i([38,38,39,40,40,41,39,38][k],[41,42,42,41,40,41,42,41][k])
	var tube:=Vector2i([36,36,37,38,40,41,39,37][k],[27,25,20,17,19,24,27,27][k])
	var rear_knee:=Vector2i([10,9,10,11,10,10,11,11][k],[34,36,35,33,31,32,34,35][k])
	var front_knee:=Vector2i([33,34,35,36,38,39,36,34][k],[34,36,35,32,30,33,35,35][k])
	_l(im,Vector2i(17+lean,29+down),rear_knee,d,4)
	_l(im,rear_knee,rear,b,3)
	_l(im,Vector2i(28+lean,29+down),front_knee,d,4)
	_l(im,front_knee,front,b,3)
	# Far pair uses distinct knees/feet, never a two-leg human template.
	_l(im,Vector2i(19+lean,30+down),Vector2i(20+lean/2,37+down/2),d,3)
	_l(im,Vector2i(20+lean/2,37+down/2),Vector2i(17,42),b,3)
	_l(im,Vector2i(29+lean,29+down),Vector2i(29+lean,36+down/2),d,3)
	_l(im,Vector2i(29+lean,36+down/2),Vector2i(31,42),b,3)
	_p(im,[Vector2(13+lean,29+down),Vector2(15+lean,18+down),Vector2(22+lean,12+down),Vector2(31+lean,15+down),Vector2(36+lean,26+down),Vector2(29+lean,34+down),Vector2(18+lean,34+down)],d)
	_p(im,[Vector2(16+lean,25+down),Vector2(18+lean,18+down),Vector2(26+lean,16+down),Vector2(31+lean,22+down),Vector2(29+lean,29+down),Vector2(19+lean,31+down)],b)
	_r(im,17+lean,24+down,5,4,team)
	_r(im,25+lean,18+down,5,7,a)
	_r(im,24+lean,20+down,2,2,h)
	for i:int in range(3):
		var x:int=[13,20,30][i]
		_r(im,x+lean,10+down+i%2,4,6-i%2,a)
	_l(im,Vector2i(30+lean,27+down),Vector2i(tube.x-5,tube.y+2),d,5)
	_l(im,Vector2i(tube.x-5,tube.y+2),tube,h,3)
	_r(im,tube.x-1,tube.y-2,3,5,a)
	_r(im,tube.x,tube.y-1,2,2,INK)
static func factor(radius:float)->float:return radius/14.0*1.35 if is_finite(radius) and radius>0 else 0.0
static func visual_bounds(unit:Dictionary,radius:float,pose:Dictionary={})->Rect2:
	var f:=frame(unit,pose);return Rect2(f.rect.position*factor(radius),f.rect.size*factor(radius)) if not f.is_empty() else Rect2()
static func stable_visual_bounds(_unit:Dictionary,radius:float)->Rect2:return Rect2(Vector2(-25,-44)*factor(radius),Vector2(50,46)*factor(radius))
static func ground_footprint(_unit:Dictionary,radius:float)->Vector2:return Vector2(23,10)*factor(radius)
static func draw(canvas:Object,foot:Vector2,unit:Dictionary,radius:float,pose:Dictionary)->void:
	if not foot.is_finite() or factor(radius)<=0:return
	var f:=frame(unit,pose);var rect:=visual_bounds(unit,radius,pose)
	if f.is_empty():return
	if canvas is CanvasItem:canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect(f.texture,Rect2((foot+rect.position).round(),rect.size),false)
static func body_contains(unit:Dictionary,radius:float,pose:Dictionary,offset:Vector2)->bool:
	if factor(radius)<=0:return false
	var f:=frame(unit,pose);var pixel:=Vector2i((offset/factor(radius)-f.rect.position).floor())
	return Rect2i(Vector2i.ZERO,f.image.get_size()).has_point(pixel) and f.image.get_pixelv(pixel).a>.1
static func inspect(unit:Dictionary,pose:Dictionary={})->Dictionary:
	var f:=frame(unit,pose).duplicate();f.erase("image");f.erase("texture");return f
static func debug_stats()->Dictionary:
	var bytes:=0
	for f:Dictionary in _frames.values():bytes+=f.image.get_width()*f.image.get_height()*4
	return {"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"texture_bytes":bytes,"maximum_texture_bytes":MAX_FRAMES*48*48*4}
