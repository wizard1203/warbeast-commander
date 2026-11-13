extends RefCounted
## Twelve original code-native pixel bodies. No ordinary-unit body reuse.
## Quantized six actions, stable feet, two-pixel dark contours, bounded LRU.
const Data=preload("res://src/simulation/strategic_hero_expansion_m66.gd")
const Palette=preload("res://src/presentation/strategic_side_palette.gd")
const SIZE:=Vector2i(48,48)
const FOOT:=Vector2(24,44)
const MAX_FRAMES:=288
const INK:=Color("17171f")
const RAMPS:={"HUMAN":["696050","b7a37b","e6d9af","7fadb1"],"UNDEAD":["554957","a594a1","d6d4b4","95b8b2"],"MACHINE":["475660","8eabb2","c7d5c6","bc8f58"],"FOREST":["40594a","92af72","d7d9a1","bc9baa"],"HIGHLAND":["57505c","a69989","ded2ac","d79562"],"UNDERGROUND":["51415f","967fa7","d6bfbc","8fb9a2"]}
static var _frames:Dictionary={}
static var _order:Array[String]=[]
static var _bakes:=0
static func supported(unit:Dictionary)->bool:return unit.get("unit_type","")=="hero" and Data.has_hero(str(unit.get("hero_archetype","")))
static func reset_cache()->void:_frames.clear();_order.clear();_bakes=0
static func _r(im:Image,x:int,y:int,w:int,h:int,c:Color)->void:
	for py:int in range(maxi(0,y),mini(SIZE.y,y+h)):
		for px:int in range(maxi(0,x),mini(SIZE.x,x+w)):im.set_pixel(px,py,c)
static func _p(im:Image,points:Array,c:Color)->void:
	var shape:=PackedVector2Array(points)
	var bounds:=Rect2(shape[0],Vector2.ZERO)
	for point:Vector2 in shape:bounds=bounds.expand(point)
	for y:int in range(maxi(0,floori(bounds.position.y)),mini(48,ceili(bounds.end.y)+1)):
		for x:int in range(maxi(0,floori(bounds.position.x)),mini(48,ceili(bounds.end.x)+1)):
			if Geometry2D.is_point_in_polygon(Vector2(x,y),shape):im.set_pixel(x,y,c)
static func _line(im:Image,a:Vector2i,b:Vector2i,c:Color,w:int=2)->void:
	var n:=maxi(absi(b.x-a.x),absi(b.y-a.y))
	for i:int in range(n+1):
		var at:=Vector2i((Vector2(a).lerp(Vector2(b),float(i)/maxi(1,n))).round())
		_r(im,at.x-w/2,at.y-w/2,w,w,c)
static func frame(unit:Dictionary,pose:Dictionary={})->Dictionary:
	if not supported(unit):return {}
	var id:=str(unit.hero_archetype)
	var action:=str(pose.get("action","IDLE"))
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
	var mirror:=Vector2(pose.get("direction",Vector2.RIGHT)).x<0
	var side:=str(unit.get("side","PLAYER"))
	var key:=id+":"+side+":"+action+":"+str(bucket)+":"+str(mirror)
	if _frames.has(key):_order.erase(key);_order.append(key);return _frames[key]
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8)
	var ramp:Array=RAMPS[Data.ROWS[id][2]]
	var dark:=Color(ramp[0]);var body:=Color(ramp[1]);var light:=Color(ramp[2]);var accent:=Color(ramp[3]);var team:=Palette.side_color(side)
	# Four genuinely different support/recovery foot positions, not A/B/C/B.
	var stride:=int([-4,-2,4,2][bucket]) if action in ["WALK","CARRY"] else 0
	var bob:=-1 if action in ["WALK","CARRY"] and bucket%2==0 else 0
	# Upper-body compression leaves the feet and world anchor planted.
	if action in ["HIT","HURT"]:bob=1 if bucket<2 else 0
	var swinging:=action in ["ATTACK","CAST"]
	var reach:=bucket*2 if swinging else 0
	var heavy:bool=Data.ROWS[id][3]=="WARRIOR"
	var top:=12+bob
	if id in ["OATH_REAVER","PISTON_FENCER"]:_refined_sample(im,id,team,dark,body,light,accent,bob,stride,reach)
	else:_refined_roster(im,id,team,dark,body,light,accent,bob,stride,reach)
	if action in ["HIT","HURT"]:_r(im,20,20,8,3,light)
	if action=="CAST":
		_r(im,30,20-bucket,4,4,accent);_r(im,33,17-bucket,2,2,light)
	if action=="FALLEN":
		var saved:=im.duplicate() as Image
		im.fill(Color.TRANSPARENT)
		var used:=saved.get_used_rect()
		for y:int in range(used.position.y,used.end.y):
			for x:int in range(used.position.x,used.end.x):
				var c:=saved.get_pixel(x,y)
				if c.a>.5:_r(im,10+(y-used.position.y)*3/4,34+(x-used.position.x)/4,1,1,c.darkened(.25))
	# Dilate only outside alpha; dark contour is never anti-aliased or blurred.
	var source:=im.duplicate() as Image
	for y:int in range(2,46):
		for x:int in range(2,46):
			if source.get_pixel(x,y).a<.5:continue
			for d:Vector2i in [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
				if source.get_pixelv(Vector2i(x,y)+d).a<.5:im.set_pixelv(Vector2i(x,y)+d,INK)
	if mirror:im.flip_x()
	var anchor:=Vector2(47-FOOT.x,FOOT.y) if mirror else FOOT
	var used:=im.get_used_rect();var cropped:=im.get_region(used)
	var result:={"key":key,"image":cropped,"texture":ImageTexture.create_from_image(cropped),"rect":Rect2(Vector2(used.position)-anchor,Vector2(used.size)),"action":action,"bucket":bucket,"mirror":mirror,"pixel_hash":cropped.get_data().hex_encode().sha256_text(),"category":"m66_authored_hero","identity":id,"provenance":"original-code-pixel-m66","silhouette":Data.STORIES[id].silhouette,"motion_refinement_version":"m76-authored-four-phase-v1"}
	while _order.size()>=MAX_FRAMES:_frames.erase(_order.pop_front())
	_frames[key]=result;_order.append(key);_bakes+=1
	return result
static func factor(radius:float)->float:return radius/14.0*1.35 if is_finite(radius) and radius>0 else 0.0
static func _refined_roster(im:Image,id:String,team:Color,dark:Color,body:Color,light:Color,accent:Color,bob:int,stride:int,reach:int)->void:
	var faction:String=Data.ROWS[id][2]
	var heavy:bool=Data.ROWS[id][3]=="WARRIOR"
	if faction=="UNDERGROUND":
		# Jointed legs taper from shell to substrate; no humanoid fallback.
		for i:int in range(3 if id=="PRISM_MANTIS" else 2):
			var at:=Vector2(14+i*7,31+bob)
			for side:int in [-1,1]:
				var knee:=at+Vector2(side*7,5+stride*.3*(1 if i%2 else -1))
				var tip:=knee+Vector2(side*4,5-stride*.2*(1 if i%2 else -1))
				_line(im,Vector2i(at),Vector2i(knee),body,3);_line(im,Vector2i(knee),Vector2i(tip),dark,2);_r(im,int(knee.x)-1,int(knee.y)-1,2,2,light)
		if id=="PRISM_MANTIS":
			_p(im,[Vector2(15,26+bob),Vector2(22,21+bob),Vector2(31,25+bob),Vector2(34,32+bob),Vector2(29,37+bob),Vector2(18,36+bob),Vector2(13,31+bob)],dark)
			_p(im,[Vector2(18,25+bob),Vector2(22,23+bob),Vector2(27,26+bob),Vector2(28,32+bob),Vector2(22,34+bob),Vector2(17,30+bob)],body)
			_p(im,[Vector2(20,25+bob),Vector2(23,24+bob),Vector2(24,30+bob),Vector2(20,31+bob)],team)
			_p(im,[Vector2(20,22+bob),Vector2(19,15+bob),Vector2(24,9+bob),Vector2(29,15+bob),Vector2(27,23+bob)],accent)
			_p(im,[Vector2(23,18+bob),Vector2(24,11+bob),Vector2(27,16+bob),Vector2(26,20+bob)],light)
			_r(im,21,21+bob,2,1,INK);_r(im,26,21+bob,2,1,INK)
			for side:int in [-1,1]:
				var x:=23+side*11
				_p(im,[Vector2(x,29),Vector2(x+side*7,18-reach/3),Vector2(x+side*4,10),Vector2(x-side*2,15),Vector2(x+side*2,21),Vector2(x-side*2,28)],body)
				_line(im,Vector2i(x+side*4,12),Vector2i(x+side*5,18-reach/3),light,1)
		else:
			_p(im,[Vector2(10,25+bob),Vector2(14,18+bob),Vector2(24,13+bob),Vector2(34,17+bob),Vector2(38,25+bob),Vector2(35,33+bob),Vector2(24,37+bob),Vector2(12,33+bob)],dark)
			_p(im,[Vector2(13,24+bob),Vector2(18,18+bob),Vector2(24,16+bob),Vector2(27,23+bob),Vector2(24,31+bob),Vector2(15,31+bob)],body)
			_p(im,[Vector2(27,18+bob),Vector2(32,20+bob),Vector2(35,26+bob),Vector2(32,31+bob),Vector2(27,31+bob),Vector2(29,25+bob)],accent.darkened(.25))
			_p(im,[Vector2(18,20+bob),Vector2(22,18+bob),Vector2(23,22+bob),Vector2(19,25+bob),Vector2(16,24+bob)],light)
			for i:int in range(3):
				_line(im,Vector2i(17+i*6,24+bob),Vector2i(16+i*6,29+bob),accent,2)
			_r(im,20,32+bob,10,3,team)
			_p(im,[Vector2(32,30),Vector2(38+reach/3,24),Vector2(44,25),Vector2(41,31),Vector2(35,34)],body)
			_line(im,Vector2i(38,27),Vector2i(42,26),light,1)
		return
	# Uneven overlapping greaves, not two rectangular boots.
	_p(im,[Vector2(18,33),Vector2(24,33),Vector2(23-stride/2,38),Vector2(24-stride/2,42),Vector2(17-stride/2,43),Vector2(17,38)],dark)
	_p(im,[Vector2(26,33),Vector2(31,33),Vector2(30+stride/2,39),Vector2(33+stride/2,42),Vector2(26+stride/2,43),Vector2(25,38)],dark)
	_p(im,[Vector2(18,35),Vector2(22,34),Vector2(22,38),Vector2(19,40)],body);_r(im,27+stride/2,36,3,3,light)
	_r(im,17-stride/2,41,6,2,body);_r(im,27+stride/2,41,6,2,body)
	# Back equipment alters the silhouette before the shaped torso overlaps it.
	match id:
		"BRIDGE_VANGUARD":
			_p(im,[Vector2(11,19),Vector2(16,17),Vector2(18,24),Vector2(16,37),Vector2(10,35),Vector2(9,27)],dark)
			for y:int in [23,28,33]:_line(im,Vector2i(11,y),Vector2i(16,y-1),accent,2)
			_p(im,[Vector2(12,17),Vector2(14,13),Vector2(33,14),Vector2(35,18),Vector2(31,19),Vector2(28,17),Vector2(16,17)],body)
		"RELIC_REAVER":_p(im,[Vector2(17,22),Vector2(12,19),Vector2(10,32),Vector2(14,35),Vector2(16,31),Vector2(20,37),Vector2(22,27)],dark)
		"OSSUARY_KNIGHT":
			_p(im,[Vector2(12,21),Vector2(8,11),Vector2(14,6),Vector2(18,17),Vector2(20,28),Vector2(15,33)],accent.darkened(.2))
			_p(im,[Vector2(14,11),Vector2(16,20),Vector2(18,25),Vector2(13,22)],body)
		"RIVET_LEGIONARY":
			for i:int in range(4):_p(im,[Vector2(10,10+i*5),Vector2(15,9+i*5),Vector2(17,13+i*5),Vector2(12,14+i*5)],accent)
		"THORN_REAVER":
			_p(im,[Vector2(17,21),Vector2(9,11),Vector2(10,24),Vector2(5,22),Vector2(10,32),Vector2(17,30)],dark)
			_p(im,[Vector2(11,16),Vector2(14,21),Vector2(14,27),Vector2(9,25)],accent)
		"ANTLER_WARRIOR":_p(im,[Vector2(14,23),Vector2(10,25),Vector2(8,34),Vector2(12,38),Vector2(18,34),Vector2(18,26)],dark)
		"SLAG_DANCER":
			_p(im,[Vector2(11,17),Vector2(15,16),Vector2(18,20),Vector2(16,33),Vector2(11,34),Vector2(9,25)],dark)
			_line(im,Vector2i(12,20),Vector2i(13,30),accent,3);_r(im,11,19,4,2,light)
		"BASALT_CHAMPION":
			_p(im,[Vector2(13,9),Vector2(17,8),Vector2(20,12),Vector2(19,29),Vector2(12,27)],dark)
			_r(im,14,11,3,4,accent);_r(im,14,17,3,3,body)
	var wide:=2 if heavy else 0
	_p(im,[Vector2(19-wide,23+bob),Vector2(23,20+bob),Vector2(29+wide,23+bob),Vector2(32+wide,29+bob),Vector2(29,35+bob),Vector2(19,35+bob),Vector2(16-wide,29+bob)],body)
	_p(im,[Vector2(20,23+bob),Vector2(24,22+bob),Vector2(25,30+bob),Vector2(22,33+bob),Vector2(18,30+bob)],light)
	_p(im,[Vector2(27,24+bob),Vector2(30+wide,26+bob),Vector2(31,30+bob),Vector2(28,34+bob),Vector2(25,33+bob)],dark)
	_p(im,[Vector2(22,25+bob),Vector2(27,24+bob),Vector2(28,28+bob),Vector2(26,32+bob),Vector2(22,31+bob)],team)
	_r(im,20,33+bob,10,2,accent.darkened(.25));_r(im,24,33+bob,2,2,light)
	# Chamfered shoulders and articulated forearms.
	_p(im,[Vector2(16-wide,22+bob),Vector2(19,20+bob),Vector2(22,23+bob),Vector2(20,27+bob),Vector2(16-wide,28+bob),Vector2(14-wide,26+bob)],body)
	_line(im,Vector2i(16-wide,23+bob),Vector2i(19,22+bob),light,1)
	_p(im,[Vector2(29,22+bob),Vector2(33+wide,23+bob),Vector2(35,27+bob),Vector2(32,30+bob),Vector2(29,27+bob)],dark)
	_r(im,31,28+bob,3,5,body);_r(im,32,30+bob,2,3,light)
	# Faces are small faceted forms beneath a shaped headpiece.
	var flesh:=Color("ceb78d") if faction in ["HUMAN","HIGHLAND"] else Color("c8cfa9") if faction=="FOREST" else light
	_p(im,[Vector2(20,13+bob),Vector2(24,10+bob),Vector2(29,13+bob),Vector2(30,18+bob),Vector2(26,22+bob),Vector2(21,19+bob)],flesh.darkened(.2))
	_p(im,[Vector2(22,13+bob),Vector2(27,13+bob),Vector2(28,16+bob),Vector2(26,19+bob),Vector2(23,18+bob)],flesh)
	_r(im,26,14+bob,3,2,INK);_r(im,28,16+bob,2,2,flesh);_r(im,24,19+bob,3,1,dark)
	match id:
		"BRIDGE_VANGUARD":
			_p(im,[Vector2(18,14+bob),Vector2(20,9+bob),Vector2(25,7+bob),Vector2(30,11+bob),Vector2(31,15+bob),Vector2(27,13+bob),Vector2(21,13+bob)],dark)
			_line(im,Vector2i(21,10+bob),Vector2i(27,10+bob),light,2)
			_line(im,Vector2i(32,35),Vector2i(37+reach/3,20),dark,3)
			_p(im,[Vector2(31,18),Vector2(38+reach/3,15),Vector2(43,18),Vector2(42,24),Vector2(34,25),Vector2(31,22)],body)
			_p(im,[Vector2(33,18),Vector2(39,17),Vector2(40,20),Vector2(34,21)],light)
		"RELIC_REAVER":
			_p(im,[Vector2(17,16+bob),Vector2(19,10+bob),Vector2(24,6+bob),Vector2(30,10+bob),Vector2(32,20+bob),Vector2(29,25+bob),Vector2(26,21+bob),Vector2(22,24+bob),Vector2(18,21+bob)],dark)
			_p(im,[Vector2(21,14+bob),Vector2(27,13+bob),Vector2(29,17+bob),Vector2(26,18+bob),Vector2(21,17+bob)],body);_r(im,24,16+bob,4,1,INK)
			for side:int in [-1,1]:
				var x:=24+side*(11+reach/3)
				_line(im,Vector2i(x,34),Vector2i(x+side*2,17+reach/3),body,2)
				_p(im,[Vector2(x-4,17+reach/3),Vector2(x-2,11+reach/3),Vector2(x+5,9+reach/3),Vector2(x+7,13+reach/3),Vector2(x+2,16+reach/3),Vector2(x+3,12+reach/3),Vector2(x,13+reach/3)],light)
			_r(im,13,27,3,5,accent);_r(im,13,28,2,1,team)
		"OSSUARY_KNIGHT":
			for y:int in [25,29,33]:
				_p(im,[Vector2(16,y),Vector2(22,y+1),Vector2(29,y-1),Vector2(31,y+1),Vector2(23,y+3),Vector2(17,y+2)],light)
			_p(im,[Vector2(19,14+bob),Vector2(21,9+bob),Vector2(28,9+bob),Vector2(31,14+bob),Vector2(27,13+bob),Vector2(22,13+bob)],body)
			_r(im,22,15+bob,2,2,INK);_r(im,27,15+bob,2,2,INK);_r(im,25,17+bob,1,2,INK)
			_line(im,Vector2i(31,37),Vector2i(37,11),body,2)
			_p(im,[Vector2(30,12),Vector2(34,7),Vector2(42,8),Vector2(44,13+reach/3),Vector2(39,16),Vector2(40,12),Vector2(34,12)],light)
		"RIVET_LEGIONARY":
			_p(im,[Vector2(18,15+bob),Vector2(19,11+bob),Vector2(23,8+bob),Vector2(29,10+bob),Vector2(32,15+bob),Vector2(29,19+bob),Vector2(21,18+bob)],dark)
			_p(im,[Vector2(21,11+bob),Vector2(25,10+bob),Vector2(29,13+bob),Vector2(29,15+bob),Vector2(21,14+bob)],body);_r(im,25,14+bob,5,2,accent)
			for x:int in [17,29]:_r(im,x,25+bob,2,2,light)
			_line(im,Vector2i(33,37),Vector2i(37,15-reach/2),dark,3)
			_p(im,[Vector2(31,14-reach/2),Vector2(35,9-reach/2),Vector2(38,10-reach/2),Vector2(37,16-reach/2),Vector2(42,13-reach/2),Vector2(44,17-reach/2),Vector2(40,22-reach/2),Vector2(34,21-reach/2)],body);_line(im,Vector2i(34,15-reach/2),Vector2i(38,18-reach/2),light,1)
		"THORN_REAVER":
			_p(im,[Vector2(17,16+bob),Vector2(20,10+bob),Vector2(25,6+bob),Vector2(31,12+bob),Vector2(30,17+bob),Vector2(26,13+bob),Vector2(21,16+bob)],dark)
			_line(im,Vector2i(21,12+bob),Vector2i(25,9+bob),body,2)
			_line(im,Vector2i(31,36),Vector2i(37,15),body,2)
			_p(im,[Vector2(30,15),Vector2(34,8),Vector2(40,8),Vector2(44,14+reach/3),Vector2(43,21),Vector2(39,16),Vector2(39,12),Vector2(34,13)],light)
			_line(im,Vector2i(21,28+bob),Vector2i(25,31+bob),accent,1)
		"ANTLER_WARRIOR":
			for side:int in [-1,1]:
				var x:=24+side*5
				_line(im,Vector2i(x,13),Vector2i(x+side*3,6),body,2);_line(im,Vector2i(x+side*3,6),Vector2i(x+side*7,4),light,2);_line(im,Vector2i(x+side*3,6),Vector2i(x+side*2,3),light,1)
			_p(im,[Vector2(10,24),Vector2(14,21),Vector2(19,25),Vector2(19,32),Vector2(14,38),Vector2(9,34)],body)
			_p(im,[Vector2(12,25),Vector2(15,24),Vector2(17,27),Vector2(15,33),Vector2(12,34)],team);_line(im,Vector2i(11,26),Vector2i(12,32),light,1)
			_line(im,Vector2i(32,37),Vector2i(37+reach/3,9),body,2);_p(im,[Vector2(35,11),Vector2(39,5),Vector2(40,11)],light)
		"SLAG_DANCER":
			_p(im,[Vector2(18,29),Vector2(30,28),Vector2(31,37),Vector2(27,39),Vector2(24,36),Vector2(20,39),Vector2(17,36)],accent.darkened(.2))
			_p(im,[Vector2(20,30),Vector2(24,30),Vector2(23,36),Vector2(20,36)],accent)
			_p(im,[Vector2(19,14+bob),Vector2(20,10+bob),Vector2(28,9+bob),Vector2(31,13+bob),Vector2(28,14+bob),Vector2(22,13+bob)],dark)
			for side:int in [-1,1]:
				var x:=24+side*10
				var steel:=Color("a8c4ca") if side<0 else Color("dfaa76")
				_p(im,[Vector2(x-2,31),Vector2(x+side*3,15),Vector2(x+side*6,8+reach/2),Vector2(x+side*7,16),Vector2(x+2,32)],body)
				_line(im,Vector2i(x,29),Vector2i(x+side*5,12+reach/2),steel,1);_line(im,Vector2i(x-3,31),Vector2i(x+4,30),dark,2)
		"BASALT_CHAMPION":
			for i:int in range(3):
				_p(im,[Vector2(10+i*3,16+i*4),Vector2(17+i*2,13+i*4),Vector2(22+i,17+i*4),Vector2(19+i,21+i*4),Vector2(12+i*3,20+i*4)],body)
				_line(im,Vector2i(12+i*3,16+i*4),Vector2i(17+i*2,15+i*4),light,1)
			_p(im,[Vector2(20,15+bob),Vector2(19,11+bob),Vector2(24,8+bob),Vector2(29,11+bob),Vector2(31,16+bob),Vector2(27,14+bob),Vector2(22,15+bob)],dark)
			_p(im,[Vector2(22,18+bob),Vector2(28,18+bob),Vector2(28,22+bob),Vector2(24,25+bob),Vector2(21,22+bob)],body)
			_line(im,Vector2i(32,38),Vector2i(37,17),dark,3)
			_p(im,[Vector2(30,12),Vector2(36,9),Vector2(43,12+reach/3),Vector2(44,19),Vector2(38,22),Vector2(31,19)],body)
			_p(im,[Vector2(32,12),Vector2(36,11),Vector2(41,13),Vector2(39,16),Vector2(33,15)],light)
static func _refined_sample(im:Image,id:String,team:Color,dark:Color,body:Color,light:Color,accent:Color,bob:int,stride:int,reach:int)->void:
	if id=="OATH_REAVER":
		# Cloth falls in three unequal planes, rather than a square tabard.
		_p(im,[Vector2(18,21),Vector2(13,23),Vector2(10,32),Vector2(12,38),Vector2(16,35),Vector2(19,39),Vector2(22,33),Vector2(21,24)],dark)
		_p(im,[Vector2(17,23),Vector2(13,25),Vector2(12,33),Vector2(14,35),Vector2(16,30)],accent)
		_p(im,[Vector2(18,25),Vector2(16,34),Vector2(19,36),Vector2(20,29)],accent.darkened(.2))
		# Bent knees and overlapping greaves produce a fighting stance.
		_p(im,[Vector2(20,33),Vector2(25,34),Vector2(23-stride/2,39),Vector2(24-stride/2,42),Vector2(17-stride/2,42),Vector2(18,38)],dark)
		_p(im,[Vector2(26,33),Vector2(30,34),Vector2(29+stride/2,39),Vector2(32+stride/2,42),Vector2(25+stride/2,43),Vector2(25,38)],body)
		_r(im,19-stride/2,36,3,3,body);_r(im,26+stride/2,37,3,3,light);_r(im,18-stride/2,41,5,2,Color("7b674d"));_r(im,26+stride/2,41,6,2,dark)
		_p(im,[Vector2(19,23+bob),Vector2(24,20+bob),Vector2(29,23+bob),Vector2(31,29+bob),Vector2(28,35+bob),Vector2(20,35+bob),Vector2(17,29+bob)],body)
		_p(im,[Vector2(24,23+bob),Vector2(28,24+bob),Vector2(29,29+bob),Vector2(27,34+bob),Vector2(23,33+bob)],team.darkened(.16))
		_p(im,[Vector2(23,23+bob),Vector2(26,23+bob),Vector2(25,31+bob),Vector2(23,32+bob)],team)
		_p(im,[Vector2(18,23+bob),Vector2(21,21+bob),Vector2(23,23+bob),Vector2(21,27+bob),Vector2(17,27+bob)],light)
		_p(im,[Vector2(28,22+bob),Vector2(32,23+bob),Vector2(34,27+bob),Vector2(31,29+bob),Vector2(29,26+bob)],dark)
		_line(im,Vector2i(20,28+bob),Vector2i(21,32+bob),light,1);_r(im,21,33+bob,8,2,Color("6f5540"));_r(im,24,33+bob,2,2,light)
		_p(im,[Vector2(19,13+bob),Vector2(22,10+bob),Vector2(27,10+bob),Vector2(30,13+bob),Vector2(29,19+bob),Vector2(26,22+bob),Vector2(22,20+bob),Vector2(20,18+bob)],Color("b99b79"))
		_p(im,[Vector2(22,13+bob),Vector2(27,12+bob),Vector2(28,16+bob),Vector2(26,19+bob),Vector2(23,18+bob)],Color("e0c79d"))
		_r(im,26,14+bob,3,2,INK);_r(im,28,16+bob,2,2,Color("e0c79d"));_r(im,24,19+bob,3,1,dark)
		_p(im,[Vector2(18,13+bob),Vector2(19,9+bob),Vector2(22,11+bob),Vector2(23,5+bob),Vector2(26,8+bob),Vector2(29,6+bob),Vector2(29,12+bob),Vector2(25,13+bob)],body)
		_r(im,21,11+bob,7,2,accent);_r(im,24,8+bob,2,3,team)
		# Broken spine, a bright bevel and a separate hilt, not a white stick.
		var lean:=reach/2
		if reach in [2,4]:
			_p(im,[Vector2(32,27),Vector2(39,21-lean),Vector2(44,20-lean),Vector2(42,24),Vector2(35,30)],body)
			_line(im,Vector2i(35,27),Vector2i(43,21-lean),light,1)
		else:
			_p(im,[Vector2(33,27),Vector2(34+lean,12),Vector2(37+lean,6),Vector2(39+lean/2,12),Vector2(36,27)],body)
			_p(im,[Vector2(35,25),Vector2(36+lean,12),Vector2(37+lean,8),Vector2(37,25)],light)
		_p(im,[Vector2(30,27),Vector2(33,26),Vector2(37,27),Vector2(39,29),Vector2(35,29),Vector2(32,30)],accent)
		_line(im,Vector2i(34,30),Vector2i(33,34),dark,2);_r(im,31,31,3,3,Color("d7b58c"))
	else:
		# Unequal pistons, faceted knee guards and a segmented offset flywheel.
		_p(im,[Vector2(11,17),Vector2(17,13),Vector2(22,17),Vector2(23,26),Vector2(18,32),Vector2(11,29),Vector2(8,23)],dark)
		_p(im,[Vector2(12,18),Vector2(17,16),Vector2(20,19),Vector2(20,25),Vector2(16,28),Vector2(11,25)],accent)
		_p(im,[Vector2(13,20),Vector2(17,18),Vector2(18,23),Vector2(15,26),Vector2(12,23)],dark)
		_r(im,11,20,2,3,light);_r(im,17,26,2,3,light)
		_p(im,[Vector2(18,33),Vector2(23,33),Vector2(22-stride/2,38),Vector2(24-stride/2,42),Vector2(17-stride/2,42),Vector2(17,38)],dark)
		_p(im,[Vector2(26,33),Vector2(31,32),Vector2(31+stride/2,39),Vector2(34+stride/2,42),Vector2(27+stride/2,43),Vector2(26,38)],body)
		_p(im,[Vector2(18,36),Vector2(22,35),Vector2(22,38),Vector2(19,40)],body);_r(im,28+stride/2,36,3,3,light)
		_p(im,[Vector2(17,23+bob),Vector2(22,20+bob),Vector2(29,22+bob),Vector2(32,28+bob),Vector2(29,34+bob),Vector2(21,36+bob),Vector2(16,30+bob)],body)
		_p(im,[Vector2(18,24+bob),Vector2(22,22+bob),Vector2(25,24+bob),Vector2(24,30+bob),Vector2(20,32+bob),Vector2(18,29+bob)],light)
		_p(im,[Vector2(26,24+bob),Vector2(29,25+bob),Vector2(30,29+bob),Vector2(27,33+bob),Vector2(24,33+bob)],dark)
		_r(im,22,25+bob,5,3,team);_r(im,21,34+bob,7,2,accent)
		_p(im,[Vector2(20,12+bob),Vector2(25,10+bob),Vector2(30,13+bob),Vector2(31,17+bob),Vector2(27,22+bob),Vector2(21,20+bob),Vector2(19,16+bob)],body)
		_p(im,[Vector2(22,12+bob),Vector2(27,12+bob),Vector2(29,14+bob),Vector2(22,15+bob)],light)
		_r(im,21,15+bob,9,3,dark);_r(im,22,15+bob,3,1,accent);_r(im,26,16+bob,3,1,Color("b5d2c8"))
		_p(im,[Vector2(23,19+bob),Vector2(29,18+bob),Vector2(27,21+bob),Vector2(24,21+bob)],accent)
		# Front arm is a telescoping blade, not a cannon silhouette.
		_p(im,[Vector2(29,24),Vector2(33,22),Vector2(36,25),Vector2(35,30),Vector2(30,31)],dark)
		_r(im,33,25,7+reach/2,4,body);_r(im,35,25,6+reach/3,1,light)
		_p(im,[Vector2(37+reach/2,24),Vector2(44,25),Vector2(41+reach/2,28),Vector2(36+reach/2,29)],light)
		_line(im,Vector2i(18,28),Vector2i(13,34),dark,3);_r(im,12,30,3,5,body);_r(im,12,31,1,3,light)
static func visual_bounds(unit:Dictionary,radius:float,pose:Dictionary={})->Rect2:
	var f:=frame(unit,pose);return Rect2(f.rect.position*factor(radius),f.rect.size*factor(radius)) if not f.is_empty() else Rect2()
static func stable_visual_bounds(unit:Dictionary,radius:float)->Rect2:return visual_bounds(unit,radius,{"action":"IDLE","direction":Vector2.RIGHT})
static func ground_footprint(unit:Dictionary,radius:float)->Vector2:return Vector2(radius*(2.4 if Data.ROWS[str(unit.hero_archetype)][4]=="MULTILEG" else 1.9),radius*.72)
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
	var f:=frame(unit,pose).duplicate()
	f.erase("texture");f.erase("image")
	f.merge({"supported":true,"original_art":true,"generated_art":false,"licensed_art":false,"coarse_outline_pixels":2,"foot_anchor":FOOT,"body_reused":false,"non_color_features":Data.STORIES[str(unit.hero_archetype)].silhouette})
	return f
static func debug_stats()->Dictionary:
	var bytes:=0
	for cached:Dictionary in _frames.values():bytes+=cached.image.get_width()*cached.image.get_height()*4
	return {"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"texture_bytes":bytes,"maximum_texture_bytes":MAX_FRAMES*48*48*4,"runtime_rng":false}
