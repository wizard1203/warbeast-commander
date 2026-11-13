extends RefCounted
## V4 Myc spectacle: caster gestures, organic pressure and a single rain pour.
## Pure atlas authoring. The consumer alone owns real events, time and targets.
const Brush = preload("res://src/presentation/heroic_r7_pixel_brush.gd")
const SIZE := 192
const FRAMES := 12
const ANCHOR := Vector2i(96,136)
const INK := Color("151622")
const DEEP := Color("292538")
const PLUM := Color("493650")
const RIND := Color("735574")
const VIOLET := Color("aa83a0")
const MOSS := Color("354c40")
const OLIVE := Color("688553")
const ACID := Color("a6cb61")
const LIME := Color("ddec98")
const MILK := Color("dcd9b8")
const WHITE := Color("fff5ce")
const TEAL := Color("487f75")
const GLASS := Color("a2dcc4")
const ASH := Color("7d8584")
const ALPHAS: Array[int] = [0,16,32,48,64,96,128,160,208,255]

static func clips() -> Array[String]:
	return ["myc_q:CAST","myc_q:CONTACT","myc_w:CAST","myc_w:CONTACT",
		"myc_r:CAST","myc_r:CONTACT","myc_r:TAIL","myc_p:RETURN"]

static func image(handler: String, phase: String, frame: int) -> Image:
	var out := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
	out.fill(Color.TRANSPARENT)
	if frame<0 or frame>=FRAMES or not clips().has(handler+":"+phase):
		return out
	match handler+":"+phase:
		"myc_q:CAST": _q_cast(out,frame)
		"myc_q:CONTACT": _q_contact(out,frame)
		"myc_w:CAST": _w_cast(out,frame)
		"myc_w:CONTACT": _w_contact(out,frame)
		"myc_r:CAST": _r_cast(out,frame)
		"myc_r:CONTACT": _r_contact(out,frame)
		"myc_r:TAIL": _r_tail(out,frame)
		"myc_p:RETURN": _p_return(out,frame)
	return out

static func _ink(color: Color, alpha: int = 255) -> Color:
	# All callers use the discrete authoring set. No blurred/fractional edges.
	return Color(color,float(alpha)/255.0)

static func _rect(out: Image, x: int, y: int, w: int, h: int, color: Color, alpha: int = 255) -> void:
	Brush.rect(out,x,y,w,h,_ink(color,alpha))

static func _poly(out: Image, points: Array, color: Color, alpha: int = 255) -> void:
	Brush.polygon(out,points,_ink(color,alpha))

static func _line(out: Image, a: Vector2i, b: Vector2i, width: int, color: Color, alpha: int = 255) -> void:
	Brush.line(out,a,b,width,_ink(color,alpha))

static func _oval(out: Image, bounds: Rect2i, color: Color, alpha: int = 255) -> void:
	Brush.ellipse(out,bounds,_ink(color,alpha))

static func _path(out: Image, points: Array, width: int, color: Color, alpha: int = 255) -> void:
	for index: int in range(points.size()-1):
		_line(out,Vector2i(points[index]),Vector2i(points[index+1]),width,color,alpha)

static func _flow(out: Image, points: Array, width: int, f: int, offset: int = 0) -> void:
	_path(out,points,width+6,TEAL,32)
	_path(out,points,width+2,INK,208)
	_path(out,points,maxi(1,width-2),RIND,208)
	_path(out,points,maxi(1,width-4),ACID,208)
	var segment := (f+offset)%(points.size()-1)
	var a := Vector2i(points[segment])
	var b := Vector2i(points[segment+1])
	_line(out,a,b,maxi(2,width-3),LIME)
	_line(out,a+Vector2i(0,-1),b+Vector2i(0,-1),1,WHITE)

static func _bubble(out: Image, at: Vector2i, r: int, pale: bool = false, alpha: int = 208) -> void:
	_oval(out,Rect2i(at-Vector2i(r+3,r+3),Vector2i(r*2+6,r*2+6)),TEAL,32)
	_oval(out,Rect2i(at-Vector2i(r,r),Vector2i(r*2+1,r*2+1)),INK,alpha)
	_oval(out,Rect2i(at-Vector2i(r-2,r-2),Vector2i(maxi(1,r*2-3),maxi(1,r*2-3))),GLASS if pale else ACID,alpha)
	_rect(out,at.x-r+2,at.y-r+2,maxi(1,r-1),2,WHITE if pale else LIME,alpha)
	if r>3: _rect(out,at.x+1,at.y+1,maxi(1,r-2),2,MOSS,alpha)

static func _drop(out: Image, at: Vector2i, length: int, fat: int, alpha: int = 255) -> void:
	_poly(out,[at+Vector2i(0,-length),at+Vector2i(fat,-4),at+Vector2i(fat+1,1),
		at+Vector2i(0,fat+1),at+Vector2i(-fat,1),at+Vector2i(-fat,-3)],INK,alpha)
	_poly(out,[at+Vector2i(0,-length+3),at+Vector2i(fat-2,-2),at+Vector2i(fat-1,1),
		at+Vector2i(0,fat-1),at+Vector2i(-fat+2,0)],ACID,alpha)
	_line(out,at+Vector2i(-1,-maxi(3,length/2)),at+Vector2i(-1,0),2,LIME,alpha)
	_rect(out,at.x-2,at.y-3,2,2,WHITE,alpha)

static func _sac(out: Image, at: Vector2i, w: int, h: int, pressure: int, alpha: int = 255) -> void:
	_poly(out,[at+Vector2i(-w,0),at+Vector2i(-w+3,-h+4),at+Vector2i(-3,-h),
		at+Vector2i(w-3,-h+2),at+Vector2i(w+2,-4),at+Vector2i(w-3,h/2),
		at+Vector2i(-w+4,h/2+2)],INK,alpha)
	_poly(out,[at+Vector2i(-w+3,-1),at+Vector2i(-w+6,-h+6),at+Vector2i(-2,-h+3),
		at+Vector2i(w-6,-h+5),at+Vector2i(w-1,-3),at+Vector2i(w-5,h/2-2),
		at+Vector2i(-w+6,h/2-1)],PLUM,alpha)
	_path(out,[at+Vector2i(-w+5,-3),at+Vector2i(-w+7,-h+7),at+Vector2i(-3,-h+5)],3,RIND,alpha)
	_line(out,at+Vector2i(-w+7,-h+7),at+Vector2i(-3,-h+5),1,MILK,alpha)
	var fill := maxi(3,h/3+pressure)
	_oval(out,Rect2i(at+Vector2i(-w+5,-fill),Vector2i(maxi(4,w*2-9),fill+h/2-2)),ACID,alpha)
	_line(out,at+Vector2i(-w+7,-fill+1),at+Vector2i(w-7,-fill+1),2,LIME,alpha)
	_rect(out,at.x-3,at.y-fill+1,3,2,WHITE,alpha)
	_line(out,at+Vector2i(0,-h+6),at+Vector2i(2,-fill+3),2,RIND,alpha)

static func _haze(out: Image, at: Vector2i, f: int, tint: Color, strength: int = 32) -> void:
	# Unequal drifting lobes make wet vapour, never a closed range ring.
	for index: int in range(4):
		var step := (f+index*3)%12
		var x := at.x+(index-2)*18+step/3
		var y := at.y-index%2*8-step
		_oval(out,Rect2i(x,y,22+index%2*8,10+index%3*4),tint,strength)
		_rect(out,x+5,y+2,7,2,tint,48 if strength==32 else 16)

static func _kernel(out: Image, at: Vector2i, f: int, radius: int = 14) -> void:
	var r := radius
	_oval(out,Rect2i(at-Vector2i(r+6,r+5),Vector2i(r*2+12,r*2+10)),TEAL,48)
	_poly(out,[at+Vector2i(-r,-3),at+Vector2i(-r+3,-r+2),at+Vector2i(1,-r-2),
		at+Vector2i(r,-r+5),at+Vector2i(r+2,3),at+Vector2i(r-4,r),
		at+Vector2i(-r+4,r-1)],INK)
	_poly(out,[at+Vector2i(-r+3,-2),at+Vector2i(-r+5,-r+5),at+Vector2i(0,-r+1),
		at+Vector2i(r-3,-r+7),at+Vector2i(r-1,2),at+Vector2i(r-6,r-3),
		at+Vector2i(-r+6,r-4)],MILK)
	_oval(out,Rect2i(at-Vector2i(r-6,r-5),Vector2i(maxi(3,r*2-10),maxi(3,r*2-10))),MOSS)
	_poly(out,[at+Vector2i(-3,-r+5),at+Vector2i(3,-6),at+Vector2i(-1,0),
		at+Vector2i(6,4),at+Vector2i(2,r-5),at+Vector2i(-4,5)],LIME)
	_path(out,[at+Vector2i(-r+5,-r+5),at+Vector2i(-5,-6),at+Vector2i(-7,2)],2,WHITE)
	_rect(out,at.x+3+f%2,at.y-3,3,2,WHITE)

static func _q_cast(out: Image, f: int) -> void:
	_haze(out,Vector2i(94,146),f,TEAL)
	var charge := mini(7,f)
	var left := Vector2i(58,115-f%3)
	var right := Vector2i(135,111+f%2)
	_path(out,[Vector2i(78,140),Vector2i(59,135),Vector2i(47,116),Vector2i(50,94)],10,PLUM,96)
	_path(out,[Vector2i(114,141),Vector2i(141,128),Vector2i(149,108),Vector2i(139,91)],9,PLUM,96)
	_sac(out,left,13+charge/3,23+charge/2,charge)
	_sac(out,right,10+charge/4,19+charge/3,charge/2)
	_flow(out,[left+Vector2i(1,-22),Vector2i(60,75),Vector2i(74,58),Vector2i(94,53)],7,f,1)
	_flow(out,[right+Vector2i(-2,-19),Vector2i(131,69),Vector2i(117,56),Vector2i(99,53)],6,f,4)
	var launch_x := 96 if f<8 else 116+(f-8)*15
	var launch_y := 53 if f<8 else 52+(f-8)*4
	_kernel(out,Vector2i(launch_x,launch_y),f,10+mini(4,charge/2))
	if f>=8:
		_path(out,[Vector2i(100,55),Vector2i(116,54),Vector2i(launch_x-12,launch_y+3)],6,TEAL,96)
		_path(out,[Vector2i(101,54),Vector2i(115,53),Vector2i(launch_x-12,launch_y+1)],2,LIME,208)
	for index: int in range(7):
		var step := (f+index*2)%12
		var at := Vector2i(37+index*18,80-index%3*13-step)
		_bubble(out,at,2+index%3,index%3==0,160 if index%2==0 else 208)
	_line(out,Vector2i(52,132),Vector2i(62,143),2,GLASS,128)
	_line(out,Vector2i(134,134),Vector2i(125,143),2,GLASS,128)

static func _q_contact(out: Image, f: int) -> void:
	_haze(out,Vector2i(101,152),f,TEAL,32)
	var peel := mini(7,f)
	# Thick shell is pulled apart along the liquid axis, not a radial blast.
	for side: int in [-1,1]:
		var x := 96+side*(18+peel*3)
		var y := 107+f
		_poly(out,[Vector2i(x,y),Vector2i(x+side*10,82+f),Vector2i(x+side*16,91+f),
			Vector2i(x+side*10,116+f),Vector2i(x-side*3,133)],INK,208 if f<8 else 128)
		_poly(out,[Vector2i(x+side*3,y),Vector2i(x+side*11,87+f),Vector2i(x+side*12,93+f),
			Vector2i(x+side*7,114+f)],MILK,208 if f<8 else 96)
	var stream: Array = [Vector2i(74,60+f),Vector2i(65,78+f),Vector2i(71,97+f),Vector2i(75,122)]
	_path(out,stream,9,PLUM,128)
	_path(out,stream,4,ACID,208)
	_path(out,[Vector2i(72,69+f),Vector2i(68,82+f),Vector2i(74,98+f)],2,WHITE,208)
	if f<7:
		_kernel(out,Vector2i(122,116+f),f,maxi(7,13-f))
	for index: int in range(6):
		var step := (f+index*2)%12
		var at := Vector2i(48+index*17,120-step*5+index%2*6)
		_bubble(out,at,maxi(2,6-index%3-f/4),index%2==0,208 if f<7 else 96)
	# Separated low stains are spent residue, not an enclosed ground zone.
	for index: int in range(3):
		_oval(out,Rect2i(47+index*34,145+index%2*5,21-f/2,5),OLIVE,64 if f<8 else 32)

static func _w_cast(out: Image, f: int) -> void:
	_haze(out,Vector2i(99,149),f,PLUM)
	var curl := f%4
	var tendrils: Array[Array] = [
		[Vector2i(79,144),Vector2i(53,135),Vector2i(30,116),Vector2i(24,88),Vector2i(35,63),Vector2i(55,49+curl)],
		[Vector2i(115,143),Vector2i(142,132),Vector2i(165,112),Vector2i(172,84),Vector2i(163,63),Vector2i(141,49-curl)],
		[Vector2i(69,126),Vector2i(56,103),Vector2i(64,76),Vector2i(84,51),Vector2i(108,36+curl),Vector2i(124,41)]]
	for index: int in range(3):
		var pipe: Array = tendrils[index]
		_flow(out,pipe,10-index,f,index*3)
		var tip := Vector2i(pipe[pipe.size()-1])
		_sac(out,tip+Vector2i(0,8),9+index*2,15+index*3,(f+index*2)%6,208)
		_drop(out,tip+Vector2i(1,17+(f+index)%4),6+index,3,208)
	for index: int in range(6):
		var step := (f+index*3)%12
		_bubble(out,Vector2i(28+index*26,118-step*5-index%2*12),2+index%3,index==3,160)
	# Open prongs beside the feet suggest pressure going outward, not a shield.
	_line(out,Vector2i(38,151),Vector2i(57,154-f%3),3,TEAL,96)
	_line(out,Vector2i(152,147),Vector2i(137,155-f%2),3,TEAL,96)

static func _w_contact(out: Image, f: int) -> void:
	_haze(out,Vector2i(101,147),f,PLUM)
	var places: Array[Vector2i] = [Vector2i(48,103),Vector2i(143,91),Vector2i(126,147)]
	var roots: Array[Array] = [
		[Vector2i(77,136),Vector2i(57,129),Vector2i(41,119),Vector2i(48,103)],
		[Vector2i(113,133),Vector2i(132,125),Vector2i(149,109),Vector2i(143,91)],
		[Vector2i(113,142),Vector2i(124,150),Vector2i(141,152),Vector2i(126,147)]]
	for index: int in range(3):
		var age := (f+index*3)%12
		var at: Vector2i = places[index]
		_flow(out,roots[index],7-index,f,index*2)
		_sac(out,at,12-index*2,22-index*3,maxi(0,6-age),208 if age<8 else 128)
		# Sideways membrane lips peel at different rates; no new world targets.
		_path(out,[at+Vector2i(-7,-9),at+Vector2i(-13-age/2,-19+age),at+Vector2i(-18-age/2,-15+age)],4,RIND,208)
		_line(out,at+Vector2i(-6,-9),at+Vector2i(-12-age/2,-16+age),2,MILK,208)
		_path(out,[at+Vector2i(2,-16),at+Vector2i(8+age/3,-9),at+Vector2i(4,4)],3,LIME,208)
		if age<7: _bubble(out,at+Vector2i(9,-27-age*2),3+index%2,index==1,208)
		_drop(out,at+Vector2i(4,8+age/2),5,3,160)
	for index: int in range(4):
		var step := (f+index*2)%12
		_rect(out,36+index*35+step/3,64-step*2,2,3,GLASS,128)

static func _great_belly(out: Image, f: int, y: int, alpha: int = 255) -> void:
	var spread := 3+mini(f,7)
	# Three overlapping noncircular folds wrap a hollow illuminated underside.
	_poly(out,[Vector2i(27-spread/2,y+17),Vector2i(40,y-4),Vector2i(71,y-18),
		Vector2i(110,y-22),Vector2i(147,y-6),Vector2i(168+spread/2,y+18),
		Vector2i(145,y+35),Vector2i(121,y+26),Vector2i(95,y+39),
		Vector2i(71,y+27),Vector2i(43,y+35)],PLUM,64)
	_poly(out,[Vector2i(32,y+13),Vector2i(45,y-2),Vector2i(77,y-15),
		Vector2i(109,y-17),Vector2i(142,y-3),Vector2i(163,y+15),
		Vector2i(143,y+28),Vector2i(121,y+21),Vector2i(95,y+33),
		Vector2i(72,y+22),Vector2i(46,y+28)],INK,alpha)
	_poly(out,[Vector2i(37,y+12),Vector2i(48,y+1),Vector2i(77,y-11),
		Vector2i(108,y-13),Vector2i(139,y+1),Vector2i(157,y+14),
		Vector2i(142,y+22),Vector2i(121,y+17),Vector2i(95,y+27),
		Vector2i(73,y+17),Vector2i(47,y+22)],RIND,alpha)
	_poly(out,[Vector2i(47,y+14),Vector2i(75,y+7),Vector2i(103,y+6),
		Vector2i(145,y+14),Vector2i(121,y+19),Vector2i(95,y+25),Vector2i(73,y+17)],MOSS,alpha)
	_path(out,[Vector2i(45,y+4),Vector2i(73,y-7),Vector2i(104,y-10),Vector2i(133,y+1)],3,VIOLET,alpha)
	_path(out,[Vector2i(50,y+13),Vector2i(76,y+11),Vector2i(102,y+10),Vector2i(139,y+15)],3,LIME,alpha)
	for index: int in range(7):
		var x := 51+index*15
		var end_y := y+19+index%3*4
		_line(out,Vector2i(96+(index-3)*3,y+9),Vector2i(x,end_y),2,ACID,alpha)
		_rect(out,x,end_y,4,4,LIME if (f+index)%3==0 else OLIVE,alpha)
		if index%2==0: _rect(out,x+1,end_y,2,1,WHITE,alpha)
	# Dark notches break the umbrella outline; not an opaque giant mushroom.
	_poly(out,[Vector2i(64,y-6),Vector2i(74,y+4),Vector2i(71,y+11),Vector2i(68,y+1)],PLUM,alpha)
	_poly(out,[Vector2i(123,y-5),Vector2i(114,y+4),Vector2i(116,y+9),Vector2i(120,y+1)],PLUM,alpha)

static func _r_cast(out: Image, f: int) -> void:
	# The large caster-side canopy is a gesture/charging image. Only root's
	# accepted event can transport and pour it over a real landing position.
	_haze(out,Vector2i(103,65),f,PLUM,32)
	_great_belly(out,f,38-f%3,208)
	_sac(out,Vector2i(52,108),12,24,mini(7,f),208)
	_sac(out,Vector2i(143,103),14,28,mini(6,f),208)
	_flow(out,[Vector2i(53,85),Vector2i(46,66),Vector2i(61,55),Vector2i(80,58)],7,f,1)
	_flow(out,[Vector2i(141,76),Vector2i(149,62),Vector2i(136,53),Vector2i(119,57)],8,f,5)
	for index: int in range(7):
		var step := (f+index*2)%12
		var x := 43+index*18
		var y := 77+step*3+index%2*5
		# A sparse charging veil beside, not over, the hero silhouette.
		if x<80 or x>113:
			_drop(out,Vector2i(x,y),8+index%3,3,128 if step>7 else 208)
		else:
			_line(out,Vector2i(x,65),Vector2i(x,75+step/2),1,GLASS,96)
	for index: int in range(8):
		var step := (f+index*3)%12
		_bubble(out,Vector2i(24+index*20,143-step*5-index%2*7),2+index%3,index%3==0,128)

static func _r_contact(out: Image, f: int) -> void:
	# One large pour at the real landing position, never one canopy per victim.
	_haze(out,Vector2i(102,143),f,PLUM,32)
	if f<7:
		_great_belly(out,11-f,38-f*2,160 if f>3 else 208)
	for index: int in range(9):
		var step := (f*2+index*3)%12
		var x := 30+index*17
		var y := 65+step*6
		var a := 208 if f<7 and index%3==0 else 96
		# Vertical delivery, not outward blast. Broken coverage avoids implying
		# a second range ring or a continuous floor damage field.
		_line(out,Vector2i(x,y-17),Vector2i(x+1,y-7),2,GLASS,64)
		_drop(out,Vector2i(x+1,y),9+index%4,3+index%2,a)
	for index: int in range(5):
		var step := (f+index*2)%12
		var x := 42+index*26
		var y := 151-step*3
		_bubble(out,Vector2i(x,y),2+index%2,index%2==0,128 if f<7 else 64)
	if f>6:
		_haze(out,Vector2i(109,106),f,PLUM,16)
	# Two thin open floor streaks are reflected wet light, never a hit border.
	_path(out,[Vector2i(29,151),Vector2i(52,154),Vector2i(67,150)],3,TEAL,48)
	_path(out,[Vector2i(129,156),Vector2i(146,151),Vector2i(162,153)],2,VIOLET,48)

static func _r_tail(out: Image, f: int) -> void:
	# Root bounds this short after-rain by an actual successful R attachment.
	# Open staggered vapour, no dome, enclosing circle, control or floor zone.
	_haze(out,Vector2i(80,141),f,PLUM,16)
	_haze(out,Vector2i(137,119),f,TEAL,16)
	for index: int in range(8):
		var step := (f+index*3)%12
		var x := 28+index*19+(f+index)%3
		var y := 69+step*6+index%2*5
		_line(out,Vector2i(x,y-9),Vector2i(x+1,y-3),1,GLASS,48)
		_drop(out,Vector2i(x,y),4,2,64 if step<8 else 32)
	for index: int in range(6):
		var step := (f+index*2)%12
		var at := Vector2i(39+index*23,146-step*5)
		_rect(out,at.x,at.y,2,2,VIOLET,64)
		_rect(out,at.x+2,at.y-2,1,1,LIME,96 if step<3 else 32)

static func _seed(out: Image, at: Vector2i, type: int, size: int) -> void:
	var r := maxi(3,size)
	if type==0:
		_poly(out,[at+Vector2i(-r,0),at+Vector2i(-r+2,-r),at+Vector2i(1,-r-2),
			at+Vector2i(r,0),at+Vector2i(r-1,r),at+Vector2i(-2,r+1)],INK)
		_oval(out,Rect2i(at-Vector2i(r-2,r-1),Vector2i(r*2-3,r*2-1)),RIND)
		_line(out,at+Vector2i(-1,-r+2),at+Vector2i(2,r-2),2,VIOLET)
		_rect(out,at.x,at.y-2,2,3,LIME)
	elif type==1:
		_drop(out,at,r+4,maxi(3,r-1))
		_line(out,at+Vector2i(-2,-r+1),at+Vector2i(-2,1),3,GLASS)
		_rect(out,at.x-2,at.y-r+1,2,2,WHITE)
	else:
		_poly(out,[at+Vector2i(-r,-2),at+Vector2i(-2,-r),at+Vector2i(2,-r+1),
			at+Vector2i(r+2,0),at+Vector2i(2,r),at+Vector2i(-r+1,r-2)],INK)
		_poly(out,[at+Vector2i(-r+2,-1),at+Vector2i(-1,-r+2),at+Vector2i(r-1,0),
			at+Vector2i(1,r-2),at+Vector2i(-r+2,r-3)],ACID)
		_rect(out,at.x-2,at.y-2,3,2,LIME)
		_line(out,at+Vector2i(r,0),at+Vector2i(r+3,2),2,MOSS)

static func _p_return(out: Image, f: int) -> void:
	var paths: Array[Array] = [
		[Vector2i(31,42),Vector2i(35,39),Vector2i(43,42),Vector2i(48,49),Vector2i(51,59),Vector2i(51,71),Vector2i(54,83),Vector2i(58,94),Vector2i(62,102),Vector2i(66,108),Vector2i(68,110),Vector2i(68,110)],
		[Vector2i(165,53),Vector2i(162,47),Vector2i(155,46),Vector2i(147,50),Vector2i(143,59),Vector2i(141,68),Vector2i(138,79),Vector2i(135,91),Vector2i(131,100),Vector2i(128,107),Vector2i(127,110),Vector2i(127,110)],
		[Vector2i(41,160),Vector2i(45,165),Vector2i(53,167),Vector2i(62,163),Vector2i(68,155),Vector2i(70,144),Vector2i(67,134),Vector2i(63,126),Vector2i(61,119),Vector2i(64,114),Vector2i(68,111),Vector2i(68,110)]]
	_haze(out,Vector2i(100,149),f,TEAL,32)
	_sac(out,Vector2i(66,120),13,24,mini(8,f),208)
	_sac(out,Vector2i(130,120),11,22,mini(8,f),208)
	_flow(out,[Vector2i(64,97),Vector2i(68,79),Vector2i(78,68),Vector2i(86,66)],6,f,2)
	_flow(out,[Vector2i(129,99),Vector2i(127,82),Vector2i(117,70),Vector2i(107,66)],6,f,5)
	for index: int in range(3):
		var at := Vector2i(paths[index][f])
		var tail: Array = []
		for back: int in range(maxi(0,f-4),f+1): tail.append(paths[index][back])
		_path(out,tail,10,TEAL if index==1 else PLUM,32)
		_path(out,tail,3,GLASS if index==1 else ACID,128)
		_seed(out,at,index,maxi(3,7-index-f/5))
		if f>1:
			var echo := Vector2i(paths[index][f-2])
			_bubble(out,echo+Vector2i(-4,3),2,index==1,96)
	if f>=8:
		var up := (f-8)*5
		_drop(out,Vector2i(84,83-up),5,3,208)
		_drop(out,Vector2i(111,83-up),5,3,208)
		_line(out,Vector2i(81,77-up),Vector2i(85,73-up),2,GLASS)
		_line(out,Vector2i(109,76-up),Vector2i(112,72-up),2,WHITE)
