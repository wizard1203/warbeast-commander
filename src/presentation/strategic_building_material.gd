extends RefCounted
## Finite original masonry/roof/tool textures and six construction traditions.
## Owner roofs/flags, door openings and authoritative footprints stay intact.

static func draw(canvas: Object, origin: Vector2, pixel: float, type: String, faction: String = "HUMAN") -> void:
	var mortar: Color = {"UNDEAD":Color("55515a"),"MACHINE":Color("685d4d"),"FOREST":Color("4d6550"),"HIGHLAND":Color("606e6a"),"UNDERGROUND":Color("56526d")}.get(faction,Color("526665"))
	var trim: Color = {"UNDEAD":Color("a9a995"),"MACHINE":Color("b99a70"),"FOREST":Color("8d9c6a"),"HIGHLAND":Color("c4cab9"),"UNDERGROUND":Color("a79dbb")}.get(faction,Color("b09b73"))
	if type == "DRAGON_ROOST":
		for index: int in range(5):
			var point := origin+Vector2(-11+index*5,-16+index%2*6)*pixel
			canvas.draw_line(point,point+Vector2(3,-4)*pixel,Color("697d7b"),maxf(pixel,1))
			canvas.draw_rect(Rect2(point+Vector2(0,3)*pixel,Vector2(3,1)*pixel),Color("b1b9a6"))
		_draw_faction(canvas,origin,pixel,type,faction,trim)
		return
	if type == "ALTAR":
		for x: int in [-13,-5,3,11]:
			canvas.draw_rect(Rect2((origin+Vector2(x,5)*pixel).round(),Vector2(1,4)*pixel),Color("526768"))
			canvas.draw_rect(Rect2((origin+Vector2(x+1,3)*pixel).round(),Vector2(3,1)*pixel),Color("d1ccb1"))
		_draw_faction(canvas,origin,pixel,type,faction,trim)
		return
	var stone := type in ["BASE","TOWER"]
	var span := 24 if type == "TOWER" else 40
	var bottom := 9
	var rows := 5 if type == "TOWER" else 3
	for row: int in range(rows):
		var y := bottom-row*6
		for side: int in [-1,1]:
			var x := side*(span*0.5-5)
			canvas.draw_line((origin+Vector2(x-3,y)*pixel).round(),(origin+Vector2(x+3,y)*pixel).round(),mortar if stone else Color("705340"),maxf(pixel,1))
			canvas.draw_rect(Rect2((origin+Vector2(x+row%2*2,y-5)*pixel).round(),Vector2(1,4)*pixel),mortar.lightened(0.14) if stone else Color("be9970"))
	if type != "TOWER":
		for x: int in [-15,-7,1,9]:
			canvas.draw_rect(Rect2((origin+Vector2(x,-27+absi(x)/6)*pixel).round(),Vector2(5,1)*pixel),trim)
	else:
		for x: int in [-15,-3,9]: canvas.draw_rect(Rect2((origin+Vector2(x,-40)*pixel).round(),Vector2(5,1)*pixel),Color("dbcbb0"))
	_draw_faction(canvas,origin,pixel,type,faction,trim)

static func _draw_faction(canvas: Object, origin: Vector2, pixel: float, type: String, faction: String, trim: Color) -> void:
	var y := -31 if type == "TOWER" else -16 if type in ["ALTAR","DRAGON_ROOST"] else -20
	# Five or fewer clustered marks per building. They do not cover the central
	# doorway, fixed side-color roofs or the upper flag ownership panel.
	if faction == "MACHINE":
		_r(canvas,origin,pixel,Rect2(-19,y,8,3),Color("79664b"))
		_r(canvas,origin,pixel,Rect2(-18,y,6,1),trim)
		for x: int in [-18,-13]: _r(canvas,origin,pixel,Rect2(x,y+1,1,1),Color("d0b58b"))
		_r(canvas,origin,pixel,Rect2(12,5,7,2),Color("aa8a61"))
	elif faction == "FOREST":
		canvas.draw_line((origin+Vector2(-18,9)*pixel).round(),(origin+Vector2(-18,y)*pixel).round(),Color("60784f"),maxf(pixel,1))
		for offset: Vector2 in [Vector2(-21,y+2),Vector2(-18,y+9),Vector2(-22,y+16)]:
			_r(canvas,origin,pixel,Rect2(offset,Vector2(5,2)),trim)
		_r(canvas,origin,pixel,Rect2(13,8,8,2),Color("6c8057"))
	elif faction == "UNDEAD":
		canvas.draw_line((origin+Vector2(-19,y+2)*pixel).round(),(origin+Vector2(-13,y+11)*pixel).round(),trim,maxf(pixel,1))
		for index: int in range(3):
			canvas.draw_line((origin+Vector2(-20+index*2,y+5+index*2)*pixel).round(),(origin+Vector2(-15+index*2,y+2+index*2)*pixel).round(),trim.darkened(0.12),maxf(pixel,1))
		_r(canvas,origin,pixel,Rect2(12,9,9,2),Color("625a65"))
	elif faction == "HIGHLAND":
		_r(canvas,origin,pixel,Rect2(-20,y,11,2),trim)
		_r(canvas,origin,pixel,Rect2(-18,y+2,7,1),trim.darkened(0.1))
		_r(canvas,origin,pixel,Rect2(11,y+2,8,2),trim)
		canvas.draw_line((origin+Vector2(-18,1)*pixel).round(),(origin+Vector2(-14,7)*pixel).round(),Color("a6afa0"),maxf(pixel,1))
	elif faction == "UNDERGROUND":
		canvas.draw_line((origin+Vector2(-17,y+12)*pixel).round(),(origin+Vector2(-16,y+2)*pixel).round(),trim,maxf(pixel*2,1))
		canvas.draw_line((origin+Vector2(-17,y+12)*pixel).round(),(origin+Vector2(-21,y+6)*pixel).round(),Color("7d9997"),maxf(pixel*2,1))
		_r(canvas,origin,pixel,Rect2(-16,y+3,1,6),Color("cad2bd"))
		_r(canvas,origin,pixel,Rect2(11,9,8,2),Color("7e748e"))
	else:
		_r(canvas,origin,pixel,Rect2(-20,y+1,10,2),trim)
		_r(canvas,origin,pixel,Rect2(-19,y+3,1,6),Color("77583e"))
		_r(canvas,origin,pixel,Rect2(-12,y+3,1,6),Color("77583e"))
		_r(canvas,origin,pixel,Rect2(12,7,8,2),Color("9c9072"))

static func _r(canvas: Object, origin: Vector2, pixel: float, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2((origin+rect.position*pixel).round(),rect.size*pixel),color)
