extends RefCounted
## Original pixel lighting/decal authoring, not Light2D, physics or an aura.
## Eight discrete alpha inks; all expensive raster work happens at atlas bake.
const Brush = preload("res://src/presentation/heroic_r7_pixel_brush.gd")
const SIZE := 128
const ANCHOR := Vector2(64,80)
const ALPHAS := [0,16,32,48,64,96,128,160]
const VALID := {
	"cinder_q":["TRAVEL","IMPACT","LOOP","END"],
	"cinder_w":["WINDUP","IMPACT","END"],
	"cinder_r":["MARK","IMPACT","LOOP","END"],"cinder_p":["PROC"],
	"myc_q":["TRAVEL","IMPACT","LOOP","END"],
	"myc_w":["TRAVEL","IMPACT","LOOP","END"],
	"myc_r":["WARNING","IMPACT","LOOP","END"],"myc_p":["PROC"]}

static func image(handler: String, phase: String, frame: int) -> Image:
	var out := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
	out.fill(Color.TRANSPARENT)
	if frame<0 or frame>7 or phase not in VALID.get(handler,[]): return out
	var cinder := handler.begins_with("cinder_")
	var ultimate := handler.ends_with("_r")
	var end := phase=="END"
	var dark := Color("241b32") if cinder else Color("21152f")
	var middle := Color("b84b2e") if cinder else Color("60527a")
	var bright := Color("ffc975") if cinder else Color("c4e881")
	var cool := Color("889ba4") if cinder else Color("86d9ca")
	var pulse: int = [0,1,2,3,2,1,0,1][frame]
	var strength := 1.0-float(frame)*.1 if end else .85+float(pulse)*.05
	# Offset shadow and a cooler secondary lobe create depth without hiding
	# a unit. This sheet is painted BEFORE actors and has no collision/range.
	_field(out,Vector2i(69,83),Vector2i(37 if ultimate else 27,10),dark,4,strength)
	_field(out,Vector2i(61,60),Vector2i(30 if ultimate else 22,31 if ultimate else 23),middle,3,strength)
	_field(out,Vector2i(61,58),Vector2i(18,24),bright,4,strength)
	_field(out,Vector2i(49,70),Vector2i(23,12),cool,2,strength)
	if phase=="TRAVEL":
		# Two broken tapered wakes: no static sphere or radial burst.
		for lane: int in range(2):
			for i: int in range(5):
				var x := 12+i*9+frame%3
				var y := 65+lane*10-i*3+(frame+lane)%3
				_stroke(out,Vector2i(x,y),Vector2i(x+8-i/2,y-2),3,dark,4)
				_stroke(out,Vector2i(x+2,y-1),Vector2i(x+7,y-3),1,bright if lane==0 else cool,2+i/2)
	elif phase=="WARNING":
		# One lifted wet canopy, with dark volume behind pale acid filaments.
		# No closed ground ring: the authoritative 95 warning stays separate.
		for i: int in range(5):
			var x := 29+i*15
			var y := 31+absi(i-2)*4+(frame+i)%3
			_field(out,Vector2i(x,y+9),Vector2i(15,21),dark,4,strength)
			_stroke(out,Vector2i(x,y),Vector2i(x+3,58+(frame*3+i*5)%19),2,cool,3)
			_stroke(out,Vector2i(x+3,y+8),Vector2i(x+4,y+16),1,bright,6)
	elif handler=="cinder_r":
		# Upward torn flame/ink columns, NOT a horizontal AoE shockwave.
		for i: int in range(4):
			var x := 36+i*17
			var top := 22+absi(i-1)*7+(frame+i*2)%7
			var points := [Vector2i(x-5,76),Vector2i(x-8,53),Vector2i(x+2,top),Vector2i(x+6,48),Vector2i(x+4,71)]
			_poly(out,points,dark,4)
			_stroke(out,Vector2i(x-1,68),Vector2i(x+2,top+7),2,middle,4)
			_stroke(out,Vector2i(x+2,top+14),Vector2i(x+3,top+8),1,bright,5)
	elif phase=="WINDUP":
		for i: int in range(4):
			var x := 23+i*20
			_stroke(out,Vector2i(x,72),Vector2i(54+i*3,51-frame),2,dark,4)
			_stroke(out,Vector2i(x+3,70),Vector2i(x+9,65),1,bright,3+frame/3)
	elif handler=="myc_w":
		for i: int in range(3):
			var tip := Vector2i(28+i*32,39+absi(i-1)*19)
			_stroke(out,Vector2i(63,76),tip,7,dark,4)
			_stroke(out,Vector2i(63,75),tip,2,middle,3)
			var moving := Vector2(63,75).lerp(Vector2(tip),float((frame+i*2)%8)/8.0)
			_spark(out,Vector2i(moving),cool,5,i+frame)
	# Secondary wisps move in separate rhythms, grouped rather than noise.
	var amount := 11 if ultimate and not end else 7 if phase=="PROC" else 5
	for i: int in range(amount):
		var step := (frame+i*3)%8
		var x := 23+(i*19)%81+(step/3)*(1 if i%2==0 else -1)
		var y := 87-step*7-(i%3)*7
		if end: y-=frame*2
		var color := bright if i%3==0 else cool if i%3==1 else middle
		_spark(out,Vector2i(x,y),color,3 if end else 5 if i%3==0 else 3,step+i)
	if phase=="PROC":
		for i: int in range(3):
			var a := float(frame)*.45+float(i)*TAU/3.0
			var at := Vector2i(64+cos(a)*(28-frame*2),53+sin(a)*(18-frame))
			_spark(out,at,bright if i==0 else cool,6,i)
	# Honest cancellation/expiry: no decorative burn survives the finite END.
	if end:
		var multiplier := maxf(.2,1.0-float(frame)*.1)
		for y: int in range(SIZE):
			for x: int in range(SIZE):
				var c := out.get_pixel(x,y)
				if c.a>0: out.set_pixel(x,y,_ink(c,maxi(1,roundi(c.a*255*multiplier/32))))
	return out

static func _ink(color: Color, level: int) -> Color:
	var result := color
	result.a=float(ALPHAS[clampi(level,0,7)])/255.0
	return result

static func front_image(handler: String, phase: String, frame: int) -> Image:
	var out := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
	out.fill(Color.TRANSPARENT)
	if frame<0 or frame>7 or phase not in VALID.get(handler,[]): return out
	var cinder := handler.begins_with("cinder_")
	var ultimate := handler.ends_with("_r")
	var ending := phase=="END"
	var hot := Color("ffdf94") if cinder else Color("e7ffb2")
	var edge := Color("e35b40") if cinder else Color("91e0d4")
	var dusk := Color("817e9e") if cinder else Color("a286c5")
	if ending: hot=Color("a1a0ad"); edge=Color("817e91")
	var intensity := maxi(1,6-frame/2) if ending else 7
	if phase=="WARNING":
		# One overhead rain curtain, only during the real warning. Its open
		# bottom and vertical motion cannot be mistaken for a blast ring.
		_field(out,Vector2i(63,30),Vector2i(49,19),dusk,3,1.0)
		_field(out,Vector2i(57,29),Vector2i(38,13),edge,4,1.0)
		for i: int in range(7):
			var x := 19+i*15
			var y := 14+absi(i-3)*4+(frame+i)%4
			_stroke(out,Vector2i(x-5,y+5),Vector2i(x,y),2,dusk,5)
			_stroke(out,Vector2i(x,y),Vector2i(x+7,y+3),1,edge,6)
			var fall := (frame*6+i*11)%62
			_luminous_stroke(out,Vector2i(x+3,y+fall),Vector2i(x+1,y+fall+10),2,edge,hot,6)
			_spark(out,Vector2i(x+1,y+fall+9),hot,7,i)
	elif cinder and ultimate:
		# Four separated ink-fire tongues, with cool ghosts and sharp warm
		# tips. They flank one marked body; no horizontal damage shockwave.
		for i: int in range(4):
			var x := 29+i*23
			var top := 12+absi(i-1)*6+(frame+i*2)%8
			var bend := -7 if i<2 else 7
			var sway := (frame+i*3)%7-3
			_field(out,Vector2i(x+sway,57),Vector2i(13,30),edge,5,1.0)
			_poly(out,[Vector2i(x-6,90),Vector2i(x-10,64),Vector2i(x+bend,45),
				Vector2i(x+3+sway,top),Vector2i(x+7,50),Vector2i(x+11,42),
				Vector2i(x+8,77),Vector2i(x+3,91)],edge,intensity-1)
			_poly(out,[Vector2i(x-1,86),Vector2i(x-4,65),Vector2i(x+2+sway,top+14),
				Vector2i(x+5,57),Vector2i(x+3,78)],hot,intensity)
			_stroke(out,Vector2i(x-6,88),Vector2i(x-10,73),2,dusk,4)
			_spark(out,Vector2i(x+3,top+5),hot,intensity,i+frame)
	elif handler=="myc_w":
		for i: int in range(4):
			var x := 21+i*28
			var y := 42+(i%2)*35
			_stroke(out,Vector2i(x-6,y+13),Vector2i(x+3,y),3,dusk,4)
			_luminous_stroke(out,Vector2i(x+3,y),Vector2i(x+9,y+5),2,edge,hot,intensity)
			_spark(out,Vector2i(x+3,y+(frame+i*2)%8),hot,intensity,i)
	elif cinder:
		# Torn ink strokes and ember smears, not the fungus' liquid membrane.
		for i: int in range(4 if ultimate or phase=="PROC" else 3):
			var x := 27 if i%2==0 else 98
			var y := 42+i*13+(frame+i)%5
			var direction := 1 if i%2==0 else -1
			_field(out,Vector2i(x,y),Vector2i(13,17),edge,5,1.0)
			_poly(out,[Vector2i(x-5,y+11),Vector2i(x+direction*5,y+2),
				Vector2i(x+direction*8,y-11),Vector2i(x+direction*10,y+1),
				Vector2i(x+2,y+10)],edge,intensity-1)
			_stroke(out,Vector2i(x,y+7),Vector2i(x+direction*6,y-4),2,hot,intensity)
	else:
		# Unequal beaded liquid curves for Q, a loose spore veil for R and
		# three returning droplets for P. Never reuse the ink-fire rectangles.
		for i: int in range(3):
			var side := -1 if i%2==0 else 1
			var x := 64+side*(34+i*3)
			var y := 37+i*21+(frame+i*2)%7
			if handler=="myc_r":
				_field(out,Vector2i(x,y),Vector2i(17,11),dusk,5,1.0)
				_field(out,Vector2i(x+side*3,y-4),Vector2i(10,7),edge,4,1.0)
				_spark(out,Vector2i(x+side*6,y-8),hot,intensity,i+frame)
			else:
				var a := Vector2i(x-side*3,y-9)
				var b := Vector2i(x+side*7,y)
				var c := Vector2i(x+side*3,y+11)
				_field(out,b,Vector2i(13,16),edge,4,1.0)
				_stroke(out,a,b,2,dusk,5)
				_stroke(out,b,c,2,edge,intensity-1)
				Brush.ellipse(out,Rect2i(c-Vector2i(3+i%2,5),Vector2i(6+i%2*2,10)),_ink(hot,intensity))
				Brush.rect(out,c.x-1,c.y-3,2,2,_ink(Color("ffffff"),intensity))
	var count := 13 if ultimate and not ending else 6
	for i: int in range(count):
		var step := (frame+i*3)%8
		var at := Vector2i(15+(i*17)%98,103-step*10-(i%2)*7)
		_spark(out,at,hot if i%3==0 else edge if i%3==1 else dusk,intensity if i%3==0 else 4,step+i)
	# Deliberate negative space, not accidental clipping. Keep faces, body
	# team colour, weapons and HP/MP bars readable under concurrent spells.
	Brush.rect(out,48,28,32,56,Color.TRANSPARENT)
	return out

static func _stroke(out: Image, a: Vector2i, b: Vector2i, width: int, color: Color, level: int) -> void:
	Brush.line(out,a,b,width,_ink(color,level))

static func _luminous_stroke(out: Image, a: Vector2i, b: Vector2i, width: int, edge: Color, hot: Color, level: int) -> void:
	# Beaded glow shoulders avoid the square-ended glass-panel appearance.
	for fraction: float in [.2,.5,.8]:
		var at := Vector2i(Vector2(a).lerp(Vector2(b),fraction))
		_field(out,at,Vector2i(width+7,width+9),edge,mini(level,5),1.0)
	_stroke(out,a,b,width,hot,level)

static func _poly(out: Image, points: Array, color: Color, level: int) -> void:
	Brush.polygon(out,points,_ink(color,level))

static func _spark(out: Image, at: Vector2i, color: Color, level: int, shape: int) -> void:
	# Tiny angled leaf, broken hooked fleck or slit; never a smooth star flare.
	_stroke(out,at+Vector2i(-3,2),at+Vector2i(2,-2),1,color,level)
	if shape%3==0: _stroke(out,at+Vector2i(-1,-3),at+Vector2i(1,3),1,color,maxi(1,level-1))
	elif shape%3==1: _stroke(out,at+Vector2i(2,-2),at+Vector2i(4,0),1,color,maxi(1,level-1))

static func _field(out: Image, center: Vector2i, radii: Vector2i, color: Color, level: int, strength: float) -> void:
	# Quantized 2px clusters, not a blurred full-resolution gradient. Uneven
	# shoulders and holes keep the footprint from reading as an aura radius.
	for y: int in range(maxi(2,center.y-radii.y),mini(126,center.y+radii.y),2):
		for x: int in range(maxi(2,center.x-radii.x),mini(126,center.x+radii.x),2):
			var p := (Vector2(x,y)-Vector2(center))/Vector2(radii)
			var d := p.length_squared()
			if d>=1.0 or (x/2+y/2)%11==0: continue
			var ink := maxi(1,roundi((1.0-d)*float(level)*strength))
			Brush.rect(out,x,y,2,2,_ink(color,ink))
