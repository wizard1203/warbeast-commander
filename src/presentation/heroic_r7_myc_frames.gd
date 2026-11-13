extends RefCounted
## V3 authored luminous hard-pixel cores, not combat authority.
## No caches or random draws. Atmosphere/glow belongs to a separate atlas layer.
## The shared atlas consumer owns timing, world direction and visibility.
const Brush = preload("res://src/presentation/heroic_r7_pixel_brush.gd")
const SIZE = 96
const FRAMES = 8
const ANCHOR = Vector2i(48, 64)

# Fifteen opaque inks plus transparent. Dark outlines are deliberately stepped,
# not antialiased; milk membrane, purple rind and acid are different materials.
const INK = Color("171722")
const EDGE = Color("282331")
const PLUM = Color("3d314c")
const RIND = Color("625069")
const MAUVE = Color("9a7592")
const MOSS = Color("405940")
const OLIVE = Color("718a45")
const ACID = Color("a4bd57")
const LIME = Color("dfeca0")
const MILK = Color("ddd2aa")
const CREAM = Color("fff0c6")
const OCHRE = Color("8b7751")
const SLIME = Color("718766")
const GLASS = Color("9bc5b7")
const TEAL = Color("3c6760")

static func clips() -> Array[String]:
	return ["myc_q:TRAVEL", "myc_q:IMPACT", "myc_q:LOOP", "myc_q:END",
		"myc_w:TRAVEL", "myc_w:IMPACT", "myc_w:LOOP", "myc_w:END",
		"myc_r:WARNING", "myc_r:IMPACT", "myc_r:LOOP", "myc_r:END", "myc_p:PROC"]

static func image(handler: String, phase: String, frame: int) -> Image:
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	out.fill(Color.TRANSPARENT)
	if frame < 0 or frame >= FRAMES or not clips().has(handler + ":" + phase):
		return out
	match handler + ":" + phase:
		"myc_q:TRAVEL": _q_travel(out, frame)
		"myc_q:IMPACT": _q_impact(out, frame)
		"myc_q:LOOP": _q_loop(out, frame)
		"myc_q:END": _q_end(out, frame)
		"myc_w:TRAVEL": _w_travel(out, frame)
		"myc_w:IMPACT": _w_impact(out, frame)
		"myc_w:LOOP": _w_loop(out, frame)
		"myc_w:END": _w_end(out, frame)
		"myc_r:WARNING": _r_warning(out, frame)
		"myc_r:IMPACT": _r_impact(out, frame)
		"myc_r:LOOP": _r_loop(out, frame)
		"myc_r:END": _r_end(out, frame)
		"myc_p:PROC": _p_proc(out, frame)
	return out

static func _rect(out: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	Brush.rect(out, x, y, w, h, color)

static func _poly(out: Image, points: Array, color: Color) -> void:
	Brush.polygon(out, points, color)

static func _line(out: Image, a: Vector2i, b: Vector2i, width: int, color: Color) -> void:
	Brush.line(out, a, b, width, color)

static func _oval(out: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	Brush.ellipse(out, Rect2i(x, y, w, h), color)

static func _bubble(out: Image, at: Vector2i, radius: int, light: bool = false) -> void:
	var r := maxi(2, radius)
	_oval(out, at.x-r, at.y-r, r*2+1, r*2+1, INK)
	_oval(out, at.x-r+2, at.y-r+2, maxi(1,r*2-3), maxi(1,r*2-3), ACID if light else OLIVE)
	_rect(out, at.x-r+2, at.y-r+2, maxi(1,r-1), 2, MILK if light else LIME)
	_rect(out, at.x+maxi(0,r-3), at.y+1, 2, maxi(1,r-2), MOSS)

static func _drop(out: Image, at: Vector2i, length: int, fat: int = 3) -> void:
	_poly(out, [at+Vector2i(0,-length), at+Vector2i(fat+1,-3), at+Vector2i(fat,2),
		at+Vector2i(0,4), at+Vector2i(-fat,2), at+Vector2i(-fat-1,-3)], INK)
	_poly(out, [at+Vector2i(0,-length+3), at+Vector2i(fat-1,-2), at+Vector2i(fat-1,1),
		at+Vector2i(0,2), at+Vector2i(-fat+1,0), at+Vector2i(-fat+1,-2)], ACID)
	_rect(out, at.x-1, at.y-3, 2, 3, CREAM)

static func _nodule(out: Image, at: Vector2i, r: int, pulse: int, split: bool = false) -> void:
	var w := r + pulse
	_oval(out, at.x-w, at.y-r, w*2+1, r*2+1, INK)
	_oval(out, at.x-w+2, at.y-r+2, w*2-3, r*2-3, PLUM)
	_oval(out, at.x-w+3, at.y-r+2, maxi(2,w), maxi(2,r-1), RIND)
	_rect(out, at.x-w+3, at.y-r+2, maxi(2,w-1), 2, MAUVE)
	_line(out, at+Vector2i(-2,-r+3), at+Vector2i(1,r-2), 3, MOSS)
	_line(out, at+Vector2i(-1,-r+3), at+Vector2i(2,r-2), 1, LIME)
	if split:
		_line(out, at+Vector2i(0,-1), at+Vector2i(w-2,-r+3), 2, INK)
		_rect(out, at.x+w-3, at.y-r+2, 2, 2, ACID)

static func _packet(out: Image, a: Vector2i, b: Vector2i, f: int, offset: int = 0) -> void:
	# The bright parcel remains inside an already drawn pipe. It conveys flow,
	# not a new branch, world range or additional target acquisition.
	var t := (f+offset)%8
	var at := Vector2i(a.x+(b.x-a.x)*t/7,a.y+(b.y-a.y)*t/7)
	_line(out,at-Vector2i(2,0),at+Vector2i(2,-1),3,LIME)
	_rect(out,at.x,at.y-1,2,1,CREAM)

static func _mote(out: Image, at: Vector2i, type: int, bright: bool = false) -> void:
	# Distinct tiny asymmetric fragments; never a full-body opaque halo.
	match type%3:
		0:
			_poly(out,[at+Vector2i(-2,0),at+Vector2i(0,-3),at+Vector2i(2,-1),at+Vector2i(1,2)],PLUM)
			_rect(out,at.x,at.y-2,1,3,LIME if bright else MAUVE)
		1:
			_line(out,at+Vector2i(-2,1),at+Vector2i(2,-2),2,TEAL)
			_rect(out,at.x,at.y-2,2,1,GLASS)
		2:
			_rect(out,at.x-1,at.y-2,3,4,MOSS)
			_rect(out,at.x,at.y-2,2,2,CREAM if bright else ACID)

static func _seed(out: Image, at: Vector2i, type: int, radius: int, f: int) -> void:
	var r := maxi(2,radius)
	match type:
		0:
			# Curved purple ferment bean with a bright cleavage, not a bubble.
			_poly(out,[at+Vector2i(-r,0),at+Vector2i(-r+1,-r),at+Vector2i(1,-r-1),
				at+Vector2i(r,0),at+Vector2i(r-1,r),at+Vector2i(-1,r+1)],INK)
			_oval(out,at.x-r+2,at.y-r+1,maxi(2,r*2-3),maxi(2,r*2-1),RIND)
			_line(out,at+Vector2i(-1,-r+1),at+Vector2i(1,r-1),1,MAUVE)
			_rect(out,at.x,at.y-1,1,2,LIME)
		1:
			# Small clear teardrop, the faintly cyan glass medium.
			_drop(out,at,r+2,maxi(2,r-1))
			_line(out,at+Vector2i(-1,-r+1),at+Vector2i(-1,1),2,GLASS)
			_rect(out,at.x-1,at.y-r+1,2,1,CREAM)
		2:
			# Irregular acid grain with two little barbs.
			_poly(out,[at+Vector2i(-r,-1),at+Vector2i(-2,-r),at+Vector2i(1,-r+1),
				at+Vector2i(r+1,0),at+Vector2i(1,r),at+Vector2i(-r+1,r-1)],INK)
			_poly(out,[at+Vector2i(-r+2,-1),at+Vector2i(-1,-r+2),at+Vector2i(r-1,0),
				at+Vector2i(1,r-2),at+Vector2i(-r+2,r-2)],ACID)
			_rect(out,at.x-1,at.y-1,2,2,LIME)
			_rect(out,at.x+r,at.y+f%2,2,1,MOSS)

static func _q_travel(out: Image, f: int) -> void:
	var squash: Array[int] = [0, 1, 3, 2, 0, -1, 1, 2]
	var s: int = squash[f]
	# A heavy off-centre nucleus rolls inside a thick porcelain membrane.
	_poly(out, [Vector2i(29-s,45+s), Vector2i(33-s,36+s), Vector2i(45,31+s),
		Vector2i(58+s,34+s), Vector2i(65+s,43), Vector2i(64+s,55-s),
		Vector2i(56,63-s), Vector2i(40-s,63), Vector2i(31-s,57)], INK)
	_poly(out, [Vector2i(32-s,45+s), Vector2i(36-s,38+s), Vector2i(45,34+s),
		Vector2i(56+s,37+s), Vector2i(62+s,44), Vector2i(61+s,53-s),
		Vector2i(54,60-s), Vector2i(41-s,60), Vector2i(34-s,55)], MILK)
	_poly(out, [Vector2i(41-s,39+s), Vector2i(51,38), Vector2i(59+s,44),
		Vector2i(57+s,54-s), Vector2i(47,58-s), Vector2i(39-s,52)], MOSS)
	_oval(out, 42-s, 41+s, 15+s, 13-s, ACID)
	_rect(out, 46-s, 41+s, 7, 3, LIME)
	_poly(out, [Vector2i(34-s,42+s),Vector2i(39-s,37+s),Vector2i(46-s,36+s),
		Vector2i(43-s,40+s),Vector2i(38-s,43+s)], CREAM)
	_line(out, Vector2i(60+s,42), Vector2i(57+s,49-s), 3, PLUM)
	_rect(out, 55+s, 50-s, 5, 3, OCHRE)
	# Sheared milk tails change topology, rather than translating the bead.
	for i: int in range(3):
		var x := 25-i*6 + (f+i)%3
		var y := 46+i*5 - (f+i)%4
		_line(out, Vector2i(x-3,y+1), Vector2i(x+3+(f+i)%2,y-1), 3, INK)
		_line(out, Vector2i(x-1,y), Vector2i(x+2,y-1), 1, MILK if i%2==0 else RIND)
	_rect(out, 49+(f%3)*2, 55-(f%2)*3, 2, 2, GLASS)
	# Glaze fractures reveal the same living core. Luminous seams use little
	# area; the consumer can add a softer low-alpha fringe without blurring ink.
	_line(out,Vector2i(42-s,37+s),Vector2i(45-s,44+s),2,PLUM)
	_line(out,Vector2i(45-s,44+s),Vector2i(41-s,51),2,PLUM)
	_line(out,Vector2i(44-s,38+s),Vector2i(46-s,44+s),1,LIME)
	_line(out,Vector2i(46-s,44+s),Vector2i(43-s,48),1,CREAM)
	_line(out,Vector2i(51,40),Vector2i(55+s,44),2,LIME)
	_rect(out,52,41,3,2,CREAM)
	var bend := f%3-1
	_line(out,Vector2i(32-s,49),Vector2i(22,47+bend),5,INK)
	_line(out,Vector2i(28-s,49),Vector2i(22,48+bend),2,ACID)
	_line(out,Vector2i(30-s,55),Vector2i(19,60-bend),3,PLUM)
	_line(out,Vector2i(28-s,55),Vector2i(21,58-bend),1,MILK)
	for i: int in range(4):
		var step := (f+i*2)%8
		var at := Vector2i(26+i*7,35-step-i%2*3)
		_bubble(out,at,2+i%2,i%2==0)
		if i==2: _mote(out,at+Vector2i(-5,4),1,true)

static func _q_impact(out: Image, f: int) -> void:
	var spread: Array[int] = [0, 3, 8, 12, 16, 18, 20, 21]
	var d: int = spread[f]
	var h := maxi(3, 17-f*2)
	_oval(out, 30-d/3, 57, 35+d/2, 10, INK)
	_oval(out, 33-d/3, 59, 29+d/2, 5, MOSS)
	_oval(out, 38-f, 56+f/2, 23+f*2, 7, ACID if f<5 else OLIVE)
	# Four asymmetric shell petals peel back; no circular blast ring.
	_poly(out,[Vector2i(46,58),Vector2i(36-d,45-f),Vector2i(31-d,47-f),
		Vector2i(36-d,55),Vector2i(43,62)],INK)
	_poly(out,[Vector2i(43,58),Vector2i(36-d,48-f),Vector2i(34-d,49-f),
		Vector2i(38-d,53),Vector2i(43,60)],MILK)
	_poly(out,[Vector2i(50,58),Vector2i(56+d,39+f),Vector2i(63+d,44+f),
		Vector2i(60+d,51+f),Vector2i(53,63)],INK)
	_poly(out,[Vector2i(52,57),Vector2i(57+d,43+f),Vector2i(60+d,45+f),
		Vector2i(57+d,51+f),Vector2i(53,60)],CREAM)
	_poly(out,[Vector2i(42,63),Vector2i(33-d/2,67+f),Vector2i(36-d/2,73+f),
		Vector2i(45,67)],INK)
	_poly(out,[Vector2i(42,64),Vector2i(36-d/2,68+f),Vector2i(38-d/2,70+f),Vector2i(44,66)],OCHRE)
	_poly(out,[Vector2i(53,64),Vector2i(65+d/2,63+f),Vector2i(68+d/2,69+f),Vector2i(55,68)],INK)
	_poly(out,[Vector2i(55,65),Vector2i(65+d/2,66+f),Vector2i(65+d/2,68+f),Vector2i(55,66)],MILK)
	# Nucleus vents through an irregular black pore as the lobes flatten.
	_poly(out,[Vector2i(43,61),Vector2i(41,57-h),Vector2i(47,53-h),
		Vector2i(55,57-h/2),Vector2i(57,61),Vector2i(50,65)],INK)
	_poly(out,[Vector2i(45,60),Vector2i(44,57-h),Vector2i(47,56-h),
		Vector2i(52,58-h/2),Vector2i(54,61),Vector2i(49,63)],ACID)
	_rect(out,46,57-h,3,3,LIME)
	_rect(out,49,59-h/2,3,3,PLUM)
	for i: int in range(3):
		var at := Vector2i(28+i*18+(i-1)*d/2, 42+(i%2)*8+f*2)
		_rect(out,at.x,at.y,3,3,INK)
		_rect(out,at.x+1,at.y,1,2,ACID if f<6 else MILK)
	# Three rising boiling groups follow the broken core, not radial sparks.
	for i: int in range(3):
		var at := Vector2i(38+i*9+(i-1)*(f%3),43-f*2+i%2*3)
		_bubble(out,at,maxi(2,4-f/3+i%2),i==1)
		_mote(out,at+Vector2i(4,-5),i,f<4)
	if f<5:
		_line(out,Vector2i(44,52),Vector2i(46,43-f),2,LIME)
		_line(out,Vector2i(46,43-f),Vector2i(50,46-f),1,CREAM)
		_rect(out,49,55-h/2,2,2,CREAM)

static func _q_loop(out: Image, f: int) -> void:
	var pulse: Array[int] = [0,1,2,1,0,-1,-1,0]
	var p: int = pulse[f]
	# One large milk-rimmed lesion: the single-target concentrated identity.
	_poly(out,[Vector2i(34-p,44),Vector2i(39,36-p),Vector2i(52,34),Vector2i(61+p,42),
		Vector2i(60,57+p),Vector2i(52,63),Vector2i(38-p,58)],INK)
	_poly(out,[Vector2i(37-p,44),Vector2i(41,39-p),Vector2i(51,37),Vector2i(58+p,44),
		Vector2i(57,55+p),Vector2i(51,59),Vector2i(41-p,56)],MILK)
	_poly(out,[Vector2i(42,43-p),Vector2i(49,39),Vector2i(55+p,45),
		Vector2i(52,54+p),Vector2i(44-p,56),Vector2i(39,50)],MOSS)
	_line(out,Vector2i(43,43-p),Vector2i(50+p,43),2,LIME)
	_line(out,Vector2i(53+p,46),Vector2i(50,53+p),2,ACID)
	_rect(out,44+p,46,6,5,PLUM)
	_rect(out,46+p,47,3,2,INK)
	for i: int in range(3):
		var step := (f+i*3)%8
		var at := Vector2i(38+i*10,57+step)
		_rect(out,at.x-1,at.y-2,3,4,INK)
		_rect(out,at.x,at.y-2,1,2,ACID if step<5 else OLIVE)
	_rect(out,33-p,43+(f%3),2,3,GLASS)
	# A narrow bright seam breathes around the pore; the core is still hollow.
	_line(out,Vector2i(40-p,45),Vector2i(43-p,39),1,CREAM)
	_line(out,Vector2i(54+p,49),Vector2i(52,56+p),2,LIME)
	for i: int in range(2):
		var step := (f+i*4)%8
		_mote(out,Vector2i(31+i*35,41-step),i+1,step<3)
	_bubble(out,Vector2i(58+p,35-f%3),2,true)

static func _q_end(out: Image, f: int) -> void:
	var shrink := maxi(1, 13-f*2)
	var cx := 48+f%2
	_oval(out,cx-shrink-2,46+f,shrink*2+5,maxi(3,17-f*2),INK)
	_oval(out,cx-shrink,48+f,maxi(1,shrink*2+1),maxi(1,13-f*2),RIND)
	if f<5:
		_line(out,Vector2i(43+f,48+f),Vector2i(51-f/2,53+f),maxi(1,4-f),MILK)
		_rect(out,48-f/2,49+f, maxi(1,4-f/2),maxi(1,4-f),OLIVE)
	for i: int in range(3):
		var x := 35+i*12 + (i-1)*f/2
		var y := 61+f*2+(i%2)*3
		_rect(out,x,y,maxi(1,3-f/3),maxi(1,3-f/4),INK)
		if f<6: _rect(out,x+1,y,1,1,MILK)
	if f<5:
		_mote(out,Vector2i(38-f/2,39-f),1,f<2)
		_mote(out,Vector2i(58+f/2,42-f*2),0,f<2)
		_rect(out,cx,49+f,1,maxi(1,4-f),LIME)

static func _w_travel(out: Image, f: int) -> void:
	# A pressure tube with growing local fork buds; consumer routes the actual
	# first-hit and subsequent links, never these illustrative local branches.
	var extent := 18+f*3
	var junction := Vector2i(43+f/2,50)
	var inlet := Vector2i(17,62)
	var tip := Vector2i(mini(83,43+extent),40+(f%3))
	_line(out,inlet,Vector2i(30,54),8,INK)
	_line(out,Vector2i(30,54),junction,8,INK)
	_line(out,junction,tip,7,INK)
	_line(out,inlet,Vector2i(30,54),4,RIND)
	_line(out,Vector2i(30,54),junction,4,OLIVE)
	_line(out,junction,tip,3,ACID)
	_line(out,Vector2i(23,58),Vector2i(29,55),1,MILK)
	for i: int in range(3):
		var at := Vector2i(28+i*14,55-i*5)
		_nodule(out,at,5+(i%2),((f+i)%4)/2,i==1)
	var fork := maxi(0,f-1)
	_line(out,junction, junction+Vector2i(9+fork*2,-8-fork),5,INK)
	_line(out,junction, junction+Vector2i(9+fork*2,-8-fork),2,ACID)
	_line(out,junction+Vector2i(3,0),junction+Vector2i(13+fork,10+fork),4,INK)
	_line(out,junction+Vector2i(3,0),junction+Vector2i(13+fork,10+fork),1,SLIME)
	_drop(out,tip,5+f%3,3)
	_packet(out,inlet,Vector2i(30,54),f)
	_packet(out,Vector2i(30,54),junction,f,3)
	_packet(out,junction,tip,f,5)
	_packet(out,junction,junction+Vector2i(9+fork*2,-8-fork),f,2)
	_packet(out,junction+Vector2i(3,0),junction+Vector2i(13+fork,10+fork),f,6)
	for i: int in range(3):
		var at := Vector2i(27+i*15,46-i*4)
		_mote(out,at+Vector2i((f+i)%3-1,-(f+i*2)%5),i,(f+i)%3==0)

static func _w_impact(out: Image, f: int) -> void:
	var push: Array[int] = [0,2,5,8,11,12,12,11]
	var d: int = push[f]
	var center := Vector2i(48,57)
	# Three unequal cauliflower lobes split along different fault seams.
	var tips: Array[Vector2i] = [Vector2i(31-d,46-f/2),Vector2i(64+d,48+f/2),Vector2i(51,72+f/2)]
	for i: int in range(3):
		_line(out,center,tips[i],7-i,INK)
		_line(out,center,tips[i],3,RIND)
		_line(out,center+Vector2i(0,-1),tips[i]+Vector2i(0,-1),1,ACID)
		_nodule(out,tips[i],maxi(3,7-f/2+i%2),f%2,true)
	_nodule(out,center,10-f/3,f%3-1,true)
	_line(out,center+Vector2i(-3,-4),center+Vector2i(4,5),3,ACID)
	_rect(out,43-f/2,51+f/2,3,2,CREAM)
	for i: int in range(4):
		var x := 31+i*11+(i%2*2-1)*f
		var y := 33+(i%2)*7+f*3
		_rect(out,x,y,2,3,INK)
		_rect(out,x,y,1,2,MAUVE if i%2==0 else ACID)
	for i: int in range(3):
		var at: Vector2i = tips[i]
		var opening := (f+i*2)%8
		# The three unequal sacs peel at different times, leaving purple lips.
		_line(out,at+Vector2i(-4,-3),at+Vector2i(2,-5-opening/3),2,MAUVE)
		_line(out,at+Vector2i(-2,-2),at+Vector2i(2,opening/2),2,LIME)
		if opening<4:
			_rect(out,at.x,at.y-2,2,2,CREAM)
			_bubble(out,at+Vector2i(4,-7-opening),2+i%2,i==1)
		_packet(out,center,at,f,i*2)
		_mote(out,at+Vector2i(-4,7-f%4),i,opening<3)

static func _w_loop(out: Image, f: int) -> void:
	# Distributed purple comma knots: markedly smaller than Q's single pore.
	var places: Array[Vector2i] = [Vector2i(34,43),Vector2i(60,49),Vector2i(44,63)]
	for i: int in range(3):
		var p := (f+i*3)%8
		var at: Vector2i = places[i]+Vector2i(0,(p/3)-1)
		_nodule(out,at,6-(i%2),1 if p<3 else 0,true)
		_line(out,at+Vector2i(3,2),at+Vector2i(6+p/3,7),3,INK)
		_line(out,at+Vector2i(3,2),at+Vector2i(5+p/3,6),1,OLIVE)
		_rect(out,at.x-1,at.y-2,2,2,LIME if p<4 else ACID)
		if p>3: _rect(out,at.x+6,at.y+7+p%3,2,2,ACID)
	_rect(out,49+f%3,42-f%2,2,2,MAUVE)
	for i: int in range(3):
		var at: Vector2i = places[i]
		var step := (f+i*3)%8
		_line(out,at+Vector2i(-3,-3),at+Vector2i(1,-1),1,CREAM if step<3 else MAUVE)
		_mote(out,at+Vector2i(7,-5-step/2),i,step<3)

static func _w_end(out: Image, f: int) -> void:
	# Tube deflates into disconnected rind chips rather than a Q membrane.
	for i: int in range(4):
		var x := 27+i*12+(i%2*2-1)*f/2
		var y := 46+(i%2)*10+f*2
		var w := maxi(2,8-f)
		_poly(out,[Vector2i(x-w,y),Vector2i(x+2,y-3),Vector2i(x+w,y),
			Vector2i(x+w-2,y+3),Vector2i(x-w+2,y+2)],INK)
		_line(out,Vector2i(x-w+2,y),Vector2i(x+2,y-1),maxi(1,3-f/3),RIND)
		if f<5: _rect(out,x-2,y,3,1,ACID)
	_rect(out,44+f,69+f,2,2,OLIVE)
	if f<5:
		_packet(out,Vector2i(32,49),Vector2i(39,55),f,1)
		_mote(out,Vector2i(64-f,34-f),0,f<2)

static func _canopy(out: Image, f: int, lift: int, collapse: int = 0) -> void:
	var open := 13+mini(f,5)*2-collapse
	var y := 23+lift
	# Inverted ceramic mushroom belly, scalloped underside, no spherical aura.
	_poly(out,[Vector2i(48-open,y+2),Vector2i(40-open/2,y-7),Vector2i(48,y-12),
		Vector2i(60+open/2,y-6),Vector2i(49+open,y+4),Vector2i(58,y+9),
		Vector2i(50,y+6),Vector2i(40,y+10),Vector2i(34,y+6)],INK)
	_poly(out,[Vector2i(51-open,y+1),Vector2i(41-open/2,y-5),Vector2i(48,y-9),
		Vector2i(58+open/2,y-4),Vector2i(46+open,y+3),Vector2i(57,y+6),
		Vector2i(49,y+3),Vector2i(40,y+7),Vector2i(36,y+4)],RIND)
	_line(out,Vector2i(36-open/3,y-1),Vector2i(45,y-6),3,MAUVE)
	_line(out,Vector2i(45,y-6),Vector2i(56+open/3,y-3),2,MILK)
	for i: int in range(4):
		var x := 34+i*9
		_line(out,Vector2i(x,y+3),Vector2i(48+(i-1)*3,y-4),2,PLUM)
		_rect(out,x,y+5+(i%2),3,3,ACID if (f+i)%3==0 else OLIVE)
	_rect(out,45,y-10,5,2,CREAM)
	_rect(out,57,y,4,2,PLUM)
	# A broad violet outside fold, deep belly cavity and little luminous gills
	# make the airborne warning feel atmospheric without making the body solid.
	_line(out,Vector2i(49-open,y+2),Vector2i(37,y+7),3,PLUM)
	_line(out,Vector2i(60,y+6),Vector2i(48+open,y+3),3,PLUM)
	_poly(out,[Vector2i(36,y+2),Vector2i(47,y-1),Vector2i(62,y+2),
		Vector2i(55,y+5),Vector2i(43,y+5)],MOSS)
	_line(out,Vector2i(38,y+2),Vector2i(48,y+1),2,ACID)
	_line(out,Vector2i(48,y+1),Vector2i(59,y+3),2,LIME)
	_rect(out,46+(f%3),y+1,3,1,CREAM)
	for i: int in range(3):
		_line(out,Vector2i(41+i*8,y+4),Vector2i(43+i*7,y+8),1,LIME if (f+i)%3==0 else OLIVE)

static func _r_warning(out: Image, f: int) -> void:
	_canopy(out,f,-3+(f%2))
	# Hanging fluid is anticipatory. These are not attached poison marks.
	for i: int in range(4):
		var x := 30+i*12+(i%2)*3
		var y := 37+(i%2)*5+(f+i)%4
		var length := 5+(f+i)%5
		_drop(out,Vector2i(x,y),length,3+(i%2))
		_line(out,Vector2i(x,28+i%2*3),Vector2i(x,y-length),2,INK)
		_line(out,Vector2i(x,29+i%2*3),Vector2i(x,y-length+1),1,SLIME)
	# Spaced hollow teardrop shadows, not filled circles claiming damage.
	for i: int in range(3):
		var x := 28+i*20
		var y := 67+i%2*4
		_line(out,Vector2i(x-4,y),Vector2i(x,y-3-f/3),2,PLUM)
		_line(out,Vector2i(x,y-3-f/3),Vector2i(x+5,y),2,PLUM)
		_line(out,Vector2i(x-4,y),Vector2i(x+5,y),1,OLIVE)
	# Two offset rain depths and upward spores give opposing vertical motion.
	# No repeated world-zone hit is implied; this remains the one pre-impact cue.
	for i: int in range(5):
		var step := (f+i*3)%8
		var x := 20+i*13+(i%2)*2
		var y := 42+step*3
		_line(out,Vector2i(x,y-5),Vector2i(x,y),1,SLIME if i%2==0 else MAUVE)
		_rect(out,x,y,1,2,ACID if step<5 else MILK)
	for i: int in range(3):
		var step := (f+i*2)%8
		_mote(out,Vector2i(27+i*21,62-step*4),i,step<3)
	_bubble(out,Vector2i(39,34+f%3),3,true)
	_bubble(out,Vector2i(61,36-f%2),2,false)

static func _r_impact(out: Image, f: int) -> void:
	# This is the small per-victim attachment, not the one area warning.
	# Keep the torso centre clear: brief side drips become 2-3 little pores.
	# R has zero direct damage, so no canopy, burst, radial spray or hit flash.
	if f<5:
		var y := 30+f*5
		_drop(out,Vector2i(61,y),5,2)
		_drop(out,Vector2i(69,y+9),4,2)
		_line(out,Vector2i(61,y-10),Vector2i(61,y-7),1,SLIME)
		if f<3:
			_rect(out,68,y+1,1,3,MILK)
	var places: Array[Vector2i] = [Vector2i(61,47),Vector2i(66,58),Vector2i(58,65)]
	for i: int in range(3):
		var age := f-2-i
		if age<0:
			continue
		var at: Vector2i = places[i]
		var opening := mini(3,age)
		_poly(out,[at+Vector2i(-3,-2),at+Vector2i(1,-3),at+Vector2i(4,0),
			at+Vector2i(2,3),at+Vector2i(-2,3),at+Vector2i(-4,0)],INK)
		_poly(out,[at+Vector2i(-2,-1),at+Vector2i(1,-2),at+Vector2i(2,0),
			at+Vector2i(1,2),at+Vector2i(-2,1)],MILK if opening<2 else RIND)
		_rect(out,at.x-1,at.y,opening+1,1,ACID)
		if opening>1:
			_rect(out,at.x,at.y-1,1,2,MOSS)
			_rect(out,at.x-2,at.y-1,1,2,LIME)
			_rect(out,at.x,at.y-2,1,1,CREAM)
		if age>1:
			_rect(out,at.x+1,at.y+3+age%2,1,2,OLIVE)
			_mote(out,at+Vector2i(5,-3-age),i,age<4)
	if f>4:
		_rect(out,70-f%3,52+f,1,2,GLASS)

static func _r_loop(out: Image, f: int) -> void:
	# Attached poison only: no continued damaging floor or repeated rain zone.
	var places: Array[Vector2i] = [Vector2i(29,43),Vector2i(65,42),Vector2i(35,61),Vector2i(61,64)]
	for i: int in range(4):
		var p := (f+i*2)%8
		var at: Vector2i = places[i]
		var height := 6+p/3
		_line(out,at+Vector2i(0,5),at+Vector2i(1,-height),4,INK)
		_line(out,at+Vector2i(0,3),at+Vector2i(1,-height+2),1,SLIME)
		# A tiny upside-down cup distinguishes the R buds from W's commas.
		_poly(out,[at+Vector2i(-6,-height+1),at+Vector2i(-3,-height-4),
			at+Vector2i(2,-height-5),at+Vector2i(6,-height+1),at+Vector2i(1,-height+3)],INK)
		_poly(out,[at+Vector2i(-3,-height),at+Vector2i(-2,-height-2),
			at+Vector2i(2,-height-3),at+Vector2i(3,-height),at+Vector2i(1,-height+1)],RIND)
		_rect(out,at.x-2,at.y-height-1,3,1,MAUVE)
		_rect(out,at.x,at.y-height+2,2,2,LIME if p<3 else OLIVE)
		if p>4: _rect(out,at.x,at.y+4+p%3,2,2,ACID)
	# Two breath bubbles, deliberately not a halo enveloping the whole body.
	_rect(out,44+f%3,33-f%2,2,2,GLASS)
	_rect(out,51-f%2,59+f%3,2,2,MILK)
	for i: int in range(4):
		var at: Vector2i = places[i]
		var step := (f+i*2)%8
		_line(out,at+Vector2i(-2,-6),at+Vector2i(2,-7),1,LIME if step<4 else MAUVE)
		if i%2==0:
			_mote(out,at+Vector2i(-5,-10-step),i,step<3)

static func _r_end(out: Image, f: int) -> void:
	for i: int in range(4):
		var x := 29+i*12+(i%2)*2
		var y := 46+(i%2)*12+f
		var h := maxi(1,7-f)
		_line(out,Vector2i(x,y),Vector2i(x+1,y+h),maxi(1,4-f/2),PLUM)
		_line(out,Vector2i(x,y),Vector2i(x+3,y+maxi(1,h/2)),1,MAUVE)
		if f<5: _rect(out,x+1,y+h,2,2,OLIVE)
		_rect(out,x-2+(i%2*2-1)*f/2,y+11+f,1,2,OCHRE)
	_rect(out,47,65+f,2,1,SLIME)
	if f<5:
		_mote(out,Vector2i(36,36-f*2),0,f<2)
		_mote(out,Vector2i(66,42-f*2),1,f<2)

static func _p_proc(out: Image, f: int) -> void:
	# Three unequal ferment seeds converge into the hero's glazed siphon.
	# This clip means a real refund already happened; it is not a hit counter.
	var paths: Array[Array] = [
		[Vector2i(23,31),Vector2i(26,29),Vector2i(30,30),Vector2i(35,34),Vector2i(40,39),Vector2i(44,44),Vector2i(47,47),Vector2i(48,47)],
		[Vector2i(73,41),Vector2i(70,38),Vector2i(66,36),Vector2i(61,36),Vector2i(56,39),Vector2i(52,43),Vector2i(49,47),Vector2i(48,46)],
		[Vector2i(38,73),Vector2i(34,69),Vector2i(34,64),Vector2i(36,59),Vector2i(40,55),Vector2i(44,52),Vector2i(47,49),Vector2i(48,45)]]
	# Two glazed bags and a bent glass inlet, not a rising flame shell.
	_nodule(out,Vector2i(40,58),8,0)
	_nodule(out,Vector2i(57,61),7,1)
	_line(out,Vector2i(40,55),Vector2i(45,43),5,INK)
	_line(out,Vector2i(45,43),Vector2i(53,42),5,INK)
	_line(out,Vector2i(40,55),Vector2i(45,43),2,TEAL)
	_line(out,Vector2i(45,43),Vector2i(53,42),2,GLASS)
	_line(out,Vector2i(57,57),Vector2i(53,42),4,INK)
	_line(out,Vector2i(57,57),Vector2i(53,42),1,SLIME)
	for i: int in range(3):
		var at: Vector2i = paths[i][f]
		var r := maxi(2,5-i-f/4)
		_seed(out,at,i,r,f)
		if f>0 and f<6:
			var old: Vector2i=paths[i][f-1]
			_rect(out,old.x-1,old.y,2,1,TEAL if i==1 else MOSS)
	if f>=4:
		# The converged droplet travels up, visibly opposite the acid delivery.
		var y := 51-(f-4)*4
		_drop(out,Vector2i(49,y),4,2)
		_rect(out,48,y-3,2,2,GLASS)
		_rect(out,37,57,3+f-4,2,LIME)
		_rect(out,54,60,2+f-4,2,ACID)
	# Distinct seed wakes coalesce; no whole-body explosion at refund time.
	for i: int in range(3):
		var at: Vector2i = paths[i][f]
		if f<6:
			_mote(out,at+Vector2i(-5+i*2,4+(f+i)%2),i,f>2)
		if f>1 and f<6:
			var prev: Vector2i = paths[i][f-2]
			_line(out,prev,at,1,TEAL if i==1 else PLUM)
			_rect(out,at.x-1,at.y-1,1,1,CREAM)
	if f>=5:
		_line(out,Vector2i(46,47),Vector2i(51,43-(f-5)*2),2,GLASS)
		_rect(out,49,43-(f-5)*2,2,2,CREAM)
