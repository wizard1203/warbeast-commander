extends RefCounted
## Original M26 architectural masters. Culture changes the load-bearing body,
## roof and silhouette; the owner's small cloth panels are a separate identity.
## Inputs are detached observations. No world, clock, RNG, rules or asset reads.
const Brush = preload("res://src/presentation/strategic_pixel_brush.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const KINDS := ["BASE","BARRACKS","RANGE","TOWER","FOUNDRY","ALTAR","WORKSHOP","DRAGON_ROOST"]
const MAX_FRAMES := 64
const DRAW_SCALE := 1.12
const INK := Color("202a30")
const GOLD := Color("dfbe78")
const EMBER := Color("e6a257")
static var _frames: Dictionary = {}
static var _order: Array[String] = []
static var _bakes := 0
static var _hits := 0


static func draw(canvas: Object,center: Vector2,building: Dictionary,scale_factor: float) -> void:
	var pixel := _pixel(building,scale_factor)
	if pixel<=0 or not center.is_finite(): return
	var frame := _frame(building)
	var rect: Rect2i=frame.rect
	if canvas is CanvasItem and canvas.texture_filter!=CanvasItem.TEXTURE_FILTER_NEAREST:
		canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	# A foot is a projected world point, never an independently rounded anchor.
	canvas.draw_texture_rect(frame.texture,Rect2(center+Vector2(rect.position)*pixel,Vector2(rect.size)*pixel),false)


static func visual_bounds(building: Dictionary,scale_factor: float) -> Rect2:
	var pixel := _pixel(building,scale_factor)
	if pixel<=0:return Rect2()
	var frame := _frame(building)
	return Rect2(Vector2(frame.rect.position)*pixel,Vector2(frame.rect.size)*pixel)


static func contains_point(building: Dictionary,offset: Vector2,scale_factor: float) -> bool:
	var pixel:=_pixel(building,scale_factor)
	if pixel<=0 or not offset.is_finite():return false
	var frame:=_frame(building)
	var point:=Vector2i(floori(offset.x/pixel)-frame.rect.position.x,floori(offset.y/pixel)-frame.rect.position.y)
	var source: Image=frame.image
	if point.x<0 or point.y<0 or point.x>=source.get_width() or point.y>=source.get_height():return false
	return source.get_pixel(point.x,point.y).a>0.5


static func draw_preview(canvas: Object,center: Vector2,building: Dictionary,scale_factor: float) -> void:
	var pixel:=_pixel(building,scale_factor)
	if pixel<=0 or not center.is_finite():return
	var frame:=_frame(building)
	_nearest(canvas)
	canvas.draw_texture_rect(frame.texture,Rect2(center+Vector2(frame.rect.position)*pixel,Vector2(frame.rect.size)*pixel),false,Color(1,1,1,0.22))


static func draw_progress(canvas: Object,center: Vector2,building: Dictionary,scale_factor: float,progress: float) -> void:
	var pixel:=_pixel(building,scale_factor)
	if pixel<=0 or not center.is_finite() or not is_finite(progress):return
	var frame:=_frame(building)
	var source: Image=frame.image
	var rows:=clampi(ceili(source.get_height()*clampf(progress,0.12,1)),1,source.get_height())
	var start:=source.get_height()-rows
	var source_rect:=Rect2(0,start,source.get_width(),rows)
	var at:=Vector2(frame.rect.position)+Vector2(0,start)
	_nearest(canvas)
	canvas.draw_texture_rect_region(frame.texture,Rect2(center+at*pixel,source_rect.size*pixel),source_rect)


static func inspect(building: Dictionary) -> Dictionary:
	var frame := _frame(building)
	var source: Image=frame.image
	var copy := Image.create_from_data(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8,source.get_data())
	var mask:=PackedByteArray()
	var opaque:=0
	var owner_pixels:=0
	var colors: Dictionary={}
	var owner:=Palette.side_color(str(frame.identity.side))
	for y: int in range(source.get_height()):
		for x: int in range(source.get_width()):
			var color:=source.get_pixel(x,y)
			mask.append(1 if color.a>0.5 else 0)
			if color.a<=0.5:continue
			opaque+=1
			colors[color.to_rgba32()]=true
			if color.is_equal_approx(owner):owner_pixels+=1
	var shape:=var_to_str(frame.rect)+":"+mask.hex_encode()
	return {"image":copy,"rect":frame.rect,"source_bounds":frame.rect,"key":frame.key,
		"pixel_hash":source.get_data().hex_encode().sha256_text(),"silhouette_hash":shape.sha256_text(),
		"opaque_pixels":opaque,"owner_pixels":owner_pixels,"colors":colors.size(),
		"source_commands":frame.commands,"clipped_commands":frame.clipped,
		"canvas_size":Brush.SIZE,"identity":frame.identity.duplicate(true)}


static func cache_stats() -> Dictionary:
	var bytes:=0
	for frame: Dictionary in _frames.values():bytes+=int(frame.rect.size.x)*int(frame.rect.size.y)*4
	return {"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"hits":_hits,
		"cpu_pixel_bytes":bytes,"maximum_cpu_pixel_bytes":MAX_FRAMES*Brush.SIZE.x*Brush.SIZE.y*4}


static func clear_cache() -> void:
	_frames.clear()
	_order.clear()
	_bakes=0
	_hits=0


static func _pixel(building: Dictionary,scale_factor: float) -> float:
	var radius:=float(building.get("radius",32))
	if not is_finite(radius) or radius<=0 or not is_finite(scale_factor) or scale_factor<=0:return 0
	return maxf(radius*scale_factor/32.0,0.1)*DRAW_SCALE


static func _identity(source: Dictionary) -> Dictionary:
	var kind:=str(source.get("building_type","BASE")).to_upper()
	if kind not in KINDS:kind="BASE"
	var faction:=str(source.get("faction_id","HUMAN")).to_upper()
	if faction not in FACTIONS:faction="HUMAN"
	var side:=str(source.get("side","PLAYER"))
	if not Palette.COLORS.has(side):side="NEUTRAL"
	var raw_tier:=float(source.get("base_tier",1))
	var tier:=clampi(int(raw_tier),1,3) if is_finite(raw_tier) and kind=="BASE" else 1
	return {"building_type":kind,"faction_id":faction,"side":side,"base_tier":tier}


static func _frame(source: Dictionary) -> Dictionary:
	var identity:=_identity(source)
	var key:=JSON.stringify([identity.building_type,identity.faction_id,identity.side,identity.base_tier])
	if _frames.has(key):
		_hits+=1
		_order.erase(key)
		_order.append(key)
		return _frames[key]
	var brush:=Brush.new()
	_paint(brush,identity)
	var used:=brush.image.get_used_rect()
	var image:=brush.image.get_region(used)
	var frame: Dictionary={"identity":identity,"key":key,"image":image,"texture":ImageTexture.create_from_image(image),
		"rect":Rect2i(used.position-Brush.FOOT,used.size),"commands":brush.commands,"clipped":brush.clipped}
	while _order.size()>=MAX_FRAMES:_frames.erase(_order.pop_front())
	_order.append(key)
	_frames[key]=frame
	_bakes+=1
	return frame


static func _paint(c: Object,id: Dictionary) -> void:
	var kind:=str(id.building_type)
	var faction:=str(id.faction_id)
	var p:=_colors(faction)
	var dimensions:=_dimensions(kind)
	var w:=int(dimensions.x)
	var top:=int(dimensions.y)
	_foundation(c,w,p)
	match faction:
		"HUMAN":_human(c,kind,w,top,p)
		"UNDEAD":_undead(c,kind,w,top,p)
		"MACHINE":_machine(c,kind,w,top,p)
		"FOREST":_forest(c,kind,w,top,p)
		"HIGHLAND":_highland(c,kind,w,top,p)
		"UNDERGROUND":_underground(c,kind,w,top,p)
	_landmark(c,kind,p)
	_furnish(c,kind,w,p)
	if kind=="BASE":_tier(c,faction,int(id.base_tier),p)
	_owner_marks(c,kind,Palette.side_color(str(id.side)),p)


static func _dimensions(kind: String) -> Vector2i:
	return {"BASE":Vector2i(47,-49),"BARRACKS":Vector2i(44,-36),"RANGE":Vector2i(37,-29),
		"TOWER":Vector2i(21,-55),"FOUNDRY":Vector2i(43,-35),"ALTAR":Vector2i(35,-21),
		"WORKSHOP":Vector2i(40,-34),"DRAGON_ROOST":Vector2i(40,-29)}.get(kind,Vector2i(47,-49))


static func _colors(faction: String) -> Dictionary:
	var rows: Dictionary={
		"HUMAN":["b5a58b","776a55","dfc9a1","ae6847","674c3b","e2b37c","eadcaf"],
		"UNDEAD":["827785","403b4b","b9adae","51465e","302e3c","9d8a9d","a8d1bb"],
		"MACHINE":["bb895e","595d57","ebc493","607b77","354b4d","b5cfb7","eed079"],
		"FOREST":["9b7c50","4b5037","d2b879","66894d","344b37","b4ca78","cbdc91"],
		"HIGHLAND":["9faeaa","556c70","d3ddd0","74868e","41555e","e8eddf","a5d1d2"],
		"UNDERGROUND":["82708c","443e55","b2a1b8","92678c","533f60","d0a6b3","b9d99c"]}
	var row: Array=rows[faction]
	return {"wall":Color(row[0]),"dark":Color(row[1]),"light":Color(row[2]),"roof":Color(row[3]),
		"roof_dark":Color(row[4]),"roof_light":Color(row[5]),"glow":Color(row[6])}


static func _foundation(c: Object,w: int,p: Dictionary) -> void:
	# A shallow broken plinth gives weight without making every roof a rectangle.
	_p(c,[Vector2(-w-4,6),Vector2(-w,-1),Vector2(w-3,-2),Vector2(w+5,7),Vector2(w-1,15),Vector2(-w+5,15)],Color("26342f",0.65))
	_r(c,-w,7,w*2,6,p.dark)
	_r(c,-w+3,6,w*2-6,3,p.light)
	for x: int in range(-w+4,w-3,11):
		_r(c,x,11,8,2,p.wall)
		_r(c,x+2,7,1,3,p.dark)
	_r(c,-10,12,21,3,p.wall)
	_r(c,-7,15,15,2,p.light)


static func _human(c: Object,kind: String,w: int,top: int,p: Dictionary) -> void:
	var open:=kind in ["RANGE","ALTAR","DRAGON_ROOST"]
	if open:
		for x: int in [-w+6,w-9]:
			_r(c,x,top+10,7,-top,p.roof_dark)
			_r(c,x+1,top+11,3,-top-2,p.wall)
		_p(c,[Vector2(-w-4,top+12),Vector2(-w+11,top-7),Vector2(w-13,top-7),Vector2(w+3,top+12)],INK)
		_p(c,[Vector2(-w-1,top+10),Vector2(-w+12,top-5),Vector2(w-14,top-5),Vector2(w,top+10)],p.roof)
	else:
		_r(c,-w+3,top+9,w*2-6,2-top,INK)
		_r(c,-w+5,top+10,w*2-10,-top,p.dark)
		_r(c,-w+6,top+12,w*2-12,-top-3,p.wall)
		_r(c,w-12,top+12,7,-top-3,p.dark)
		for row: int in range(4):
			for x: int in range(-w+8,w-10,12):
				_r(c,x+(row%2)*3,top+17+row*9,8,1,p.light if row%2 else p.dark)
		_p(c,[Vector2(-w-4,top+12),Vector2(-w+8,top-8),Vector2(0,top-18),Vector2(w+4,top+10)],INK)
		_p(c,[Vector2(-w+1,top+9),Vector2(-w+10,top-6),Vector2(0,top-15),Vector2(w,top+8)],p.roof)
		_p(c,[Vector2(0,top-15),Vector2(w,top+8),Vector2(1,top+8)],p.roof_dark)
	for row: int in range(4):
		var y:=top-2+row*4
		for index: int in range(5):
			var x:=-w+14+index*(w*2-24)/5+(row%2)*3
			_l(c,Vector2(x,y),Vector2(x+7,y),p.roof_light)
	for x: int in [-w+6,0,w-9]:
		_r(c,x,top+13,3,mini(-top+1,35),p.roof_dark)
		_r(c,x+1,top+14,1,mini(-top,32),p.light)
	if not open:
		for x: int in [-w+15,w-24]:_window(c,x,top+24,p,8)
		_l(c,Vector2(-w+10,7),Vector2(-w+22,top+16),p.roof_dark,2)
		_l(c,Vector2(w-11,7),Vector2(w-23,top+16),p.roof_dark,2)
	if kind=="BASE":
		for x: int in [-37,27]:
			_r(c,x,-60,11,39,p.dark)
			_r(c,x+2,-58,7,34,p.wall)
			_p(c,[Vector2(x-2,-59),Vector2(x+5,-72),Vector2(x+13,-59)],p.roof)
			_r(c,x+3,-51,3,8,INK)


static func _undead(c: Object,kind: String,w: int,top: int,p: Dictionary) -> void:
	# Crooked shoulders, ribbed buttresses and needle roof, never a recolored hall.
	_p(c,[Vector2(-w+5,10),Vector2(-w+2,top+14),Vector2(-w+15,top+4),Vector2(-5,top-9),Vector2(w-3,top+12),Vector2(w-6,11)],INK)
	_p(c,[Vector2(-w+8,8),Vector2(-w+6,top+16),Vector2(-w+17,top+7),Vector2(-5,top-5),Vector2(w-7,top+14),Vector2(w-9,9)],p.wall)
	_p(c,[Vector2(-4,top-3),Vector2(w-7,top+14),Vector2(w-9,9),Vector2(1,9)],p.dark)
	_p(c,[Vector2(-w-1,top+17),Vector2(-w+12,top-11),Vector2(-6,top-21),Vector2(w+2,top+15),Vector2(3,top+4)],p.roof_dark)
	_p(c,[Vector2(-w+2,top+12),Vector2(-w+13,top-9),Vector2(-6,top-18),Vector2(1,top+3)],p.roof)
	for side: int in [-1,1]:
		var x:=side*(w-4)
		_p(c,[Vector2(x-7,10),Vector2(x-4,top+4),Vector2(x+2,top-14+side*3),Vector2(x+7,12)],p.dark)
		_l(c,Vector2(x-4,7),Vector2(x+1,top-10+side*3),p.light,2)
		_l(c,Vector2(x-4,0),Vector2(x-side*13,top+19),p.light,2)
		_l(c,Vector2(x-2,-9),Vector2(x-side*10,top+14),p.roof_light)
	for row: int in range(5):
		for n: int in range(5):
			var x:=-w+12+n*(w*2-24)/5
			_r(c,x+(row%2)*2,roundi(lerpf(top+18,6,row/4.0)),5,1,p.light if (n+row)%3==0 else p.dark)
	for index: int in range(9):
		var x:=-w+8+index*(w*2-14)/9
		_l(c,Vector2(x,top+7),Vector2(x+3,top+13),p.roof_light)
		_l(c,Vector2(x,top+11),Vector2(x+2,top+13),p.roof)
	for x: int in [-w+16,w-25]:
		_p(c,[Vector2(x,0),Vector2(x,top+25),Vector2(x+5,top+17),Vector2(x+10,top+25),Vector2(x+10,0)],INK)
		_r(c,x+4,top+25,2,9,p.glow)
	if kind=="BASE":
		_l(c,Vector2(-8,-56),Vector2(-10,-81),p.light,3)
		_p(c,[Vector2(-16,-62),Vector2(-10,-83),Vector2(-3,-62)],p.roof_dark)
		_l(c,Vector2(-10,-77),Vector2(-9,-64),p.roof_light)


static func _machine(c: Object,kind: String,w: int,top: int,p: Dictionary) -> void:
	# A stepped pressure shell; tiered metal roof, copper tanks and exposed ducts.
	_p(c,[Vector2(-w,11),Vector2(-w,top+14),Vector2(-w+12,top+14),Vector2(-w+12,top-5),Vector2(12,top-5),Vector2(12,top+4),Vector2(w,top+4),Vector2(w,11)],INK)
	_r(c,-w+3,top+17,w*2-6,-top-6,p.dark)
	_r(c,-w+15,top-2,w+23,22,p.wall)
	_r(c,-w+3,top+18,w*2-8,-top-8,p.wall)
	_r(c,6,top+6,w-8,4-top,p.roof_dark)
	_r(c,-w+11,top-7,w+27,5,p.roof_dark)
	_r(c,-w+12,top-7,w+25,2,p.roof_light)
	_r(c,12,top+2,w-10,5,p.roof)
	_r(c,14,top+2,w-14,1,p.roof_light)
	for row: int in range(4):
		for column: int in range(5):
			var x:=-w+7+column*(w*2-16)/5
			var y:=roundi(lerpf(top+21,3,row/3.0))
			_r(c,x,y,8,5,p.roof if (row+column)%3==0 else p.dark)
			_r(c,x,y,1,1,p.light)
			_r(c,x+6,y+3,1,1,p.light)
	# Bent supply pipe has a silhouette distinct from gothic or rooted supports.
	_r(c,-w-5,top+5,7,3-top,INK)
	_r(c,-w-4,top+6,5,1-top,p.roof)
	_r(c,-w-3,top+6,1,1-top,p.roof_light)
	_r(c,-w-4,top+5,18,6,p.roof)
	for y: int in range(top+9,top+36,9):_r(c,-w-6,y,9,2,p.light)
	_r(c,w-13,top-12,10,17,p.dark)
	_r(c,w-12,top-14,8,3,p.light)
	for index: int in range(5):_r(c,w-11,top-9+index*3,6,1,p.roof_light)
	if kind=="BASE":
		_r(c,-16,-67,32,14,p.dark)
		_r(c,-14,-65,28,11,p.roof)
		for x: int in range(-11,13,5):_r(c,x,-62,2,6,p.glow)


static func _forest(c: Object,kind: String,w: int,top: int,p: Dictionary) -> void:
	# A hollow living bole: broad roots below and layered branch-leaf roofs above.
	_p(c,[Vector2(-w-5,12),Vector2(-w+13,-6),Vector2(-w+17,top+10),Vector2(-15,top-2),Vector2(16,top+4),Vector2(w-14,-4),Vector2(w+6,11),Vector2(w-9,14),Vector2(1,7),Vector2(-w+7,15)],p.dark)
	_p(c,[Vector2(-w+8,9),Vector2(-w+20,-10),Vector2(-w+22,top+11),Vector2(-13,top+1),Vector2(11,top+8),Vector2(w-16,-6),Vector2(w,10),Vector2(17,6),Vector2(-10,5)],p.wall)
	for index: int in range(9):
		var x:=-w+17+index*(w*2-34)/9
		_l(c,Vector2(x,top+13),Vector2(x+(index%3-1)*6,5),p.light if index%3==0 else p.dark,1)
		_l(c,Vector2(x+2,top+19),Vector2(x+3,top+31),p.dark)
	for side: int in [-1,1]:
		_l(c,Vector2(side*14,-3),Vector2(side*(w+2),11),p.light,2)
		_l(c,Vector2(side*19,1),Vector2(side*(w-2),14),p.dark,2)
	# Separate asymmetrical leaf lobes leave recognisable gaps around branches.
	var lobes: Array[Vector2]=[Vector2(-w+12,top+2),Vector2(-11,top-9),Vector2(w-18,top-2)]
	for index: int in range(lobes.size()):
		var at: Vector2=lobes[index]
		_leaf(c,at,23 if kind!="TOWER" else 16,12,p)
		_l(c,at+Vector2(-14,3),at+Vector2(11,-2),p.roof_light)
		for n: int in range(4):
			_l(c,at+Vector2(-12+n*7,2),at+Vector2(-16+n*7,-3),p.roof_light)
			_l(c,at+Vector2(-10+n*7,2),at+Vector2(-6+n*7,6),p.roof_dark)
	for x: int in [-w+9,w-13]:
		_r(c,x,top+20,5,12,p.dark)
		_r(c,x+1,top+21,3,6,p.glow)
		_r(c,x-2,top+33,9,2,p.roof)
	if kind=="BASE":
		_leaf(c,Vector2(5,-64),24,14,p)
		_l(c,Vector2(4,-65),Vector2(-7,-77),p.light,2)
		_leaf(c,Vector2(-11,-77),12,6,p)


static func _highland(c: Object,kind: String,w: int,top: int,p: Dictionary) -> void:
	# Broad stepped dry-stone terraces and broken heavy snow shelves.
	_p(c,[Vector2(-w-4,12),Vector2(-w-4,top+24),Vector2(-w+7,top+24),Vector2(-w+7,top+8),Vector2(-w+18,top+8),Vector2(-w+18,top-5),Vector2(w-16,top-5),Vector2(w-16,top+9),Vector2(w-3,top+9),Vector2(w-3,top+25),Vector2(w+3,top+25),Vector2(w+3,12)],INK)
	_r(c,-w,top+25,w*2,mini(-top-10,35),p.dark)
	_r(c,-w+9,top+9,w*2-16,-top,p.wall)
	_r(c,-w+20,top-3,w*2-38,17,p.wall)
	_r(c,w-16,top+13,10,-top-4,p.dark)
	for row: int in range(5):
		for n: int in range(5):
			var x:=-w+10+n*(w*2-20)/5+(row%2)*3
			var y:=roundi(lerpf(top+15,4,row/4.0))
			_r(c,x,y,8,4,p.wall if n%2 else p.light)
			_r(c,x+1,y+3,7,1,p.dark)
	_r(c,-w+4,top+7,w*2-8,5,p.dark)
	_r(c,-w+7,top+7,w*2-15,3,p.roof_light)
	_r(c,-w+14,top+5,17,3,p.roof_light)
	_r(c,2,top+5,w-12,3,p.roof_light)
	_r(c,-w+17,top-6,w*2-34,4,p.roof_dark)
	_r(c,-w+16,top-7,w*2-32,3,p.roof_light)
	for index: int in range(6):
		var x:=-w+8+index*(w*2-14)/6
		_p(c,[Vector2(x,top+10),Vector2(x+7,top+10),Vector2(x+4,top+14),Vector2(x+2,top+13)],p.roof_light)
		_l(c,Vector2(x+2,top+19),Vector2(x+4,top+24),p.roof)
	for x: int in [-w+14,w-20]:
		_r(c,x,top+26,7,11,INK)
		_r(c,x+2,top+27,3,6,p.glow)
		_r(c,x-2,top+24,11,3,p.light)
	if kind=="BASE":
		_r(c,-13,-67,26,13,p.dark)
		_r(c,-11,-65,22,11,p.wall)
		_r(c,-15,-68,30,4,p.roof_light)
		for x: int in [-9,-1,7]:_r(c,x,-62,3,6,INK)


static func _underground(c: Object,kind: String,w: int,top: int,p: Dictionary) -> void:
	# Hewn terraced cavern, a large low mushroom awning and faceted crystal feet.
	_p(c,[Vector2(-w-3,13),Vector2(-w+1,top+21),Vector2(-w+10,top+9),Vector2(-14,top-8),Vector2(13,top-4),Vector2(w-5,top+12),Vector2(w+4,11),Vector2(w-8,15)],INK)
	_p(c,[Vector2(-w+2,11),Vector2(-w+5,top+23),Vector2(-w+14,top+11),Vector2(-13,top-4),Vector2(12,top),Vector2(w-9,top+14),Vector2(w,10),Vector2(w-9,12)],p.wall)
	_p(c,[Vector2(5,top+4),Vector2(w-9,top+14),Vector2(w,10),Vector2(8,12),Vector2(18,top+23)],p.dark)
	for row: int in range(5):
		for n: int in range(4):
			var x:=-w+12+n*(w*2-22)/4+(row%2)*2
			var y:=roundi(lerpf(top+15,4,row/4.0))
			_r(c,x,y,8,2,p.light if (row+n)%3==0 else p.dark)
			_l(c,Vector2(x+4,y+2),Vector2(x+8,y+5),p.dark)
	var cap_y:=top+7
	_p(c,[Vector2(-w-5,cap_y+10),Vector2(-w+1,cap_y),Vector2(-21,cap_y-11),Vector2(-2,cap_y-15),Vector2(21,cap_y-9),Vector2(w+2,cap_y+3),Vector2(w+5,cap_y+12)],p.roof_dark)
	_p(c,[Vector2(-w-2,cap_y+6),Vector2(-w+3,cap_y),Vector2(-20,cap_y-9),Vector2(-2,cap_y-12),Vector2(19,cap_y-7),Vector2(w,cap_y+3),Vector2(w+1,cap_y+7)],p.roof)
	for index: int in range(10):
		var x:=-w+7+index*(w*2-12)/10
		_r(c,x,cap_y+8,2,3,p.roof_light)
	for at: Vector2 in [Vector2(-21,cap_y-4),Vector2(-5,cap_y-8),Vector2(17,cap_y-2),Vector2(29,cap_y+3)]:
		_r(c,int(at.x),int(at.y),4,2,p.roof_light)
		_r(c,int(at.x)+1,int(at.y)-1,2,1,p.light)
	_crystal(c,Vector2(-w+5,10),9,23,p)
	_crystal(c,Vector2(w-4,11),8,17,p)
	if kind=="BASE":
		_crystal(c,Vector2(15,-47),8,30,p)
		_crystal(c,Vector2(26,-43),6,19,p)


static func _landmark(c: Object,kind: String,p: Dictionary) -> void:
	match kind:
		"BASE":
			_arch(c,Vector2(0,9),13,31,p)
			_r(c,-9,-19,18,3,p.light)
			for x: int in [-8,-3,2,7]:_r(c,x,-15,1,19,p.dark)
			_r(c,-6,-1,12,3,p.glow)
		"BARRACKS":
			for x: int in [-30,-8]:
				_arch(c,Vector2(x+7,10),8,22,p)
				for n: int in range(3):_r(c,x+2+n*4,-10,1,16,p.light)
			_r(c,18,-10,29,4,p.dark)
			_r(c,20,7,24,3,p.light)
			for x: int in [22,31,40]:
				_l(c,Vector2(x,11),Vector2(x-3,-28),p.light,2)
				_p(c,[Vector2(x-6,-25),Vector2(x-3,-33),Vector2(x,-25)],GOLD)
			_r(c,19,-8,9,14,p.dark)
			_r(c,20,-7,7,10,p.roof_light)
		"RANGE":
			_r(c,-30,-4,32,12,p.dark)
			for x: int in [-27,-18,-9]:
				_l(c,Vector2(x,6),Vector2(x+3,-11),p.light,2)
				_l(c,Vector2(x+3,-11),Vector2(x+4,4),p.roof_light)
			_target(c,Vector2(28,-19),p)
			_l(c,Vector2(27,-8),Vector2(18,13),p.dark,3)
			_l(c,Vector2(29,-8),Vector2(39,13),p.light,2)
			_l(c,Vector2(25,-19),Vector2(48,-25),p.light,2)
			_p(c,[Vector2(44,-28),Vector2(51,-25),Vector2(45,-22)],GOLD)
		"TOWER":
			# Narrow column, broad elevated firing gallery and an oversized crossbow.
			_r(c,-18,-57,36,5,p.dark)
			_r(c,-32,-61,64,7,INK)
			_r(c,-30,-60,60,4,p.wall)
			_r(c,-29,-60,58,1,p.light)
			for x: int in [-31,-18,-5,8,21]:
				_r(c,x,-68,9,10,p.dark)
				_r(c,x+1,-67,6,5,p.light)
			_l(c,Vector2(-22,-57),Vector2(-14,-42),p.dark,3)
			_l(c,Vector2(22,-57),Vector2(14,-42),p.light,2)
			_r(c,-7,-73,14,10,p.dark)
			_l(c,Vector2(-29,-78),Vector2(0,-71),p.light,3)
			_l(c,Vector2(0,-71),Vector2(29,-78),p.light,3)
			_l(c,Vector2(-29,-78),Vector2(29,-78),p.dark)
			_l(c,Vector2(0,-68),Vector2(0,-85),GOLD,3)
			_l(c,Vector2(-4,-81),Vector2(0,-85),p.light)
			_r(c,-3,-35,6,12,INK)
			_r(c,-1,-33,2,8,p.glow)
		"FOUNDRY":
			_r(c,20,-76,15,59,INK)
			_r(c,22,-73,11,54,p.dark)
			_r(c,22,-73,4,54,p.wall)
			_r(c,18,-77,19,5,p.light)
			for y: int in range(-69,-22,8):_r(c,22,y,11,1,p.roof_light)
			_arch(c,Vector2(-16,10),14,29,p)
			_r(c,-27,-9,22,16,Color("b76640"))
			_p(c,[Vector2(-25,6),Vector2(-21,-6),Vector2(-17,1),Vector2(-12,-11),Vector2(-7,6)],EMBER)
			_r(c,-20,1,10,5,Color("f4d28a"))
			_r(c,9,4,25,4,p.light)
			_r(c,16,8,8,6,p.dark)
			_p(c,[Vector2(8,3),Vector2(8,-2),Vector2(31,-2),Vector2(36,-6),Vector2(36,0),Vector2(28,4)],p.light)
			for x: int in [-40,-32]:_r(c,x,6,6,5,p.roof_dark)
		"ALTAR":
			_r(c,-27,3,54,8,p.dark)
			_r(c,-23,0,46,5,p.light)
			_r(c,-17,-4,34,4,p.roof_dark)
			for x: int in [-23,18]:
				_r(c,x,-43,6,43,p.dark)
				_r(c,x+1,-42,3,39,p.light)
				_r(c,x-2,-44,10,3,GOLD)
			_p(c,[Vector2(0,-68),Vector2(13,-45),Vector2(7,-27),Vector2(0,-20),Vector2(-12,-38)],INK)
			_p(c,[Vector2(0,-64),Vector2(10,-44),Vector2(0,-24),Vector2(-8,-39)],p.glow)
			_p(c,[Vector2(0,-64),Vector2(1,-41),Vector2(-8,-39)],p.light)
			_r(c,-2,-23,4,21,GOLD)
			for x: int in [-13,-5,3,11]:_r(c,x,-1,3,2,p.glow)
		"WORKSHOP":
			_r(c,-28,-6,39,15,INK)
			for x: int in range(-25,10,6):_r(c,x,-4,3,11,p.light)
			# Gantry and hanging hook sit outside the cultural roof envelope.
			_r(c,25,-68,7,75,p.dark)
			_r(c,26,-67,2,72,p.light)
			_r(c,2,-70,34,6,p.dark)
			_r(c,2,-70,33,2,p.light)
			_l(c,Vector2(29,-45),Vector2(5,-66),p.roof_light,2)
			_l(c,Vector2(8,-64),Vector2(8,-36),GOLD)
			_l(c,Vector2(8,-36),Vector2(13,-32),GOLD,2)
			_l(c,Vector2(13,-32),Vector2(17,-37),GOLD,2)
			_gear(c,Vector2(24,-16),12,p)
			_r(c,14,8,25,5,p.dark)
			for x: int in [16,34]:
				_r(c,x,6,7,10,INK)
				_r(c,x+2,8,3,6,p.light)
		"DRAGON_ROOST":
			# Raised open nesting terrace and three pale eggs, never a closed house.
			_p(c,[Vector2(-45,12),Vector2(-40,-6),Vector2(-21,-20),Vector2(15,-18),Vector2(43,-2),Vector2(48,12)],p.dark)
			_p(c,[Vector2(-41,-1),Vector2(-22,-15),Vector2(15,-14),Vector2(39,0),Vector2(27,8),Vector2(-27,8)],p.light)
			_p(c,[Vector2(-35,-1),Vector2(-20,-10),Vector2(15,-10),Vector2(34,0),Vector2(22,4),Vector2(-22,4)],p.roof_dark)
			for index: int in range(12):
				var x:=-33+index*6
				_l(c,Vector2(x,-2+index%3),Vector2(x+9,5),p.wall)
			for at: Vector2 in [Vector2(-16,-11),Vector2(-1,-17),Vector2(14,-9)]:
				_p(c,[at+Vector2(-5,7),at+Vector2(-6,0),at+Vector2(-2,-8),at+Vector2(3,-9),at+Vector2(7,-1),at+Vector2(5,7)],INK)
				_p(c,[at+Vector2(-3,5),at+Vector2(-4,0),at+Vector2(-1,-6),at+Vector2(2,-7),at+Vector2(5,-1),at+Vector2(3,5)],p.glow)
				_r(c,int(at.x)-1,int(at.y)-4,2,3,p.light)
			for side: int in [-1,1]:
				_l(c,Vector2(side*35,-2),Vector2(side*43,-44),p.dark,3)
				_p(c,[Vector2(side*43,-47),Vector2(side*30,-36),Vector2(side*49,-33)],p.roof_light)


static func _tier(c: Object,faction: String,tier: int,p: Dictionary) -> void:
	if tier<2:return
	# Real silhouette extensions, not level numerals baked into a shared roof.
	for side: int in [-1,1]:
		var x:=side*48
		if faction=="FOREST":
			_l(c,Vector2(side*35,-8),Vector2(x,-59),p.dark,5)
			_leaf(c,Vector2(x,-59),10,11,p)
		elif faction=="UNDERGROUND":_crystal(c,Vector2(x,9),10,54,p)
		elif faction=="UNDEAD":
			_p(c,[Vector2(x-7,11),Vector2(x-3,-43),Vector2(x+3,-70),Vector2(x+8,11)],p.dark)
			_l(c,Vector2(x+2,-63),Vector2(x-2,-7),p.light,2)
		elif faction=="MACHINE":
			_r(c,x-7,-48,14,57,p.dark)
			_r(c,x-5,-45,10,51,p.wall)
			_r(c,x-9,-49,18,5,p.roof_light)
			for y: int in [-36,-23,-10]:_r(c,x-6,y,12,2,p.roof)
		else:
			_r(c,x-7,-42,14,52,p.dark)
			_r(c,x-5,-39,10,47,p.wall)
			if faction=="HIGHLAND":_r(c,x-9,-43,18,5,p.roof_light)
			else:_p(c,[Vector2(x-9,-41),Vector2(x,-57),Vector2(x+9,-41)],p.roof)
			_r(c,x-1,-30,3,10,INK)
	if tier<3:return
	if faction=="FOREST":
		_l(c,Vector2(0,-56),Vector2(12,-82),p.light,3)
		_leaf(c,Vector2(13,-79),17,8,p)
	elif faction=="UNDERGROUND":
		_crystal(c,Vector2(-13,-56),9,30,p)
		_crystal(c,Vector2(4,-51),7,31,p)
	elif faction=="UNDEAD":
		_p(c,[Vector2(12,-45),Vector2(17,-86),Vector2(24,-52)],p.roof_dark)
		_l(c,Vector2(17,-82),Vector2(17,-54),p.light,2)
	elif faction=="MACHINE":
		_r(c,-9,-83,23,20,p.dark)
		_r(c,-7,-81,19,17,p.wall)
		_r(c,-11,-85,27,5,p.roof_light)
		for x: int in [-4,2,8]:_r(c,x,-77,2,9,p.glow)
	else:
		_r(c,-12,-82,24,22,p.dark)
		_r(c,-10,-79,20,17,p.wall)
		if faction=="HIGHLAND":_r(c,-15,-84,30,5,p.roof_light)
		else:
			for x: int in [-14,-4,6]:_r(c,x,-87,8,9,p.light)
		for x: int in [-6,3]:_r(c,x,-74,3,8,INK)


static func _furnish(c: Object,kind: String,w: int,p: Dictionary) -> void:
	# Functional foreground pieces and material edges, not random pixel noise.
	# These also separate the upright body from its grounded, shallow steps.
	for index: int in range(5):
		var x:=-w+7+index*(w*2-19)/5
		_r(c,x,12,8,2,p.dark)
		_r(c,x,11,6,1,p.light)
	match kind:
		"BASE":
			for side: int in [-1,1]:
				var x:=side*17
				_r(c,x-2,-11,5,12,p.dark)
				_r(c,x-1,-10,3,4,p.glow)
				_r(c,x-3,-12,7,2,p.light)
				_r(c,x-2,-5,5,1,p.light)
				_l(c,Vector2(x,-9),Vector2(x,-7),p.light)
			for y: int in [-8,2]:
				_r(c,-8,y,5,2,p.wall)
				_r(c,4,y,5,2,p.light)
		"BARRACKS":
			_crate(c,Vector2(-43,9),p)
			for x: int in [-34,5,13]:
				_r(c,x,-4,6,11,p.dark)
				_r(c,x+1,-3,4,7,p.light)
				_r(c,x+2,0,2,4,p.roof_dark)
		"RANGE":
			_crate(c,Vector2(-37,10),p)
			for index: int in range(5):
				var x:=-21+index*5
				_l(c,Vector2(x,8),Vector2(x+3,-5),p.light)
				_p(c,[Vector2(x+1,-4),Vector2(x+4,-9),Vector2(x+5,-3)],p.roof_light)
		"TOWER":
			for y: int in [-19,-7,4]:
				_r(c,-10,y,7,2,p.light)
				_r(c,4,y+3,6,1,p.dark)
			for x: int in [-16,13]:
				_r(c,x,-2,3,10,p.dark)
				_r(c,x,-3,3,2,p.light)
		"FOUNDRY":
			for index: int in range(5):
				var x:=-40+index*5
				_r(c,x,9-index%2*3,4,3,INK)
				_r(c,x,9-index%2*3,2,1,p.dark)
			_l(c,Vector2(12,0),Vector2(25,-8),p.dark,2)
			_l(c,Vector2(18,-1),Vector2(30,-7),p.light)
		"ALTAR":
			for side: int in [-1,1]:
				var x:=side*28
				_r(c,x-3,1,7,4,p.dark)
				_r(c,x-1,-10,3,12,p.light)
				_p(c,[Vector2(x-2,-10),Vector2(x-1,-17),Vector2(x+3,-11),Vector2(x+1,-8)],p.glow)
				_r(c,x-2,-1,5,1,p.roof_light)
			for index: int in range(6):
				var x:=-19+index*7
				_l(c,Vector2(x,5),Vector2(x+2,8),p.roof_dark)
				_l(c,Vector2(x+2,8),Vector2(x+4,5),p.glow)
		"WORKSHOP":
			_crate(c,Vector2(-39,10),p)
			_l(c,Vector2(-8,5),Vector2(-3,-10),p.roof_light,2)
			_r(c,-6,-13,10,4,p.dark)
			_r(c,-5,-13,8,1,p.light)
			_r(c,1,8,10,3,p.dark)
			_r(c,4,4,3,7,p.light)
		"DRAGON_ROOST":
			for side: int in [-1,1]:
				var x:=side*31
				_p(c,[Vector2(x-5,8),Vector2(x-3,2),Vector2(x+3,1),Vector2(x+6,9)],p.dark)
				_l(c,Vector2(x-3,3),Vector2(x+2,2),p.light)
			for index: int in range(6):
				var x:=-27+index*10
				_l(c,Vector2(x,9),Vector2(x+7,6),p.roof_light)
				_l(c,Vector2(x+2,7),Vector2(x+7,10),p.wall)


static func _crate(c: Object,at: Vector2,p: Dictionary) -> void:
	_r(c,int(at.x),int(at.y)-12,11,13,p.dark)
	_r(c,int(at.x)+1,int(at.y)-11,8,11,p.wall)
	_r(c,int(at.x),int(at.y)-12,11,2,p.light)
	_l(c,at+Vector2(1,-9),at+Vector2(8,-2),p.roof_dark)
	_l(c,at+Vector2(8,-9),at+Vector2(1,-2),p.roof_dark)
	_r(c,int(at.x)+8,int(at.y)-10,2,10,p.dark)


static func _owner_marks(c: Object,kind: String,owner: Color,p: Dictionary) -> void:
	var y: int={"BASE":-33,"BARRACKS":-21,"RANGE":-18,"TOWER":-48,"FOUNDRY":-27,"ALTAR":-15,"WORKSHOP":-24,"DRAGON_ROOST":-32}.get(kind,-25)
	var span:=12 if kind=="TOWER" else 23
	for side: int in [-1,1]:
		var x:=side*span-4
		_r(c,x-1,y-1,10,16,INK)
		_r(c,x,y,8,13,owner.darkened(0.42))
		_r(c,x,y,8,10,owner)
		_r(c,x,y,8,1,owner.lightened(0.28))
		_r(c,x+3,y+3,2,4,p.light)
		_p(c,[Vector2(x,y+10),Vector2(x+8,y+10),Vector2(x+4,y+14)],owner.darkened(0.42))


static func _arch(c: Object,at: Vector2,w: int,h: int,p: Dictionary) -> void:
	_p(c,[at+Vector2(-w,0),at+Vector2(-w,-h+8),at+Vector2(-w+5,-h),at+Vector2(w-5,-h),at+Vector2(w,-h+8),at+Vector2(w,0)],p.light)
	_p(c,[at+Vector2(-w+3,0),at+Vector2(-w+3,-h+9),at+Vector2(-w+7,-h+3),at+Vector2(w-7,-h+3),at+Vector2(w-3,-h+9),at+Vector2(w-3,0)],INK)
	_r(c,int(at.x)-w+4,int(at.y)-h+12,3,h-12,p.dark)
	_r(c,int(at.x)-w,int(at.y)-1,w*2,2,p.light)


static func _window(c: Object,x: int,y: int,p: Dictionary,w: int) -> void:
	_r(c,x-1,y-1,w+2,12,p.roof_dark)
	_r(c,x,y,w,9,INK)
	_r(c,x+1,y+1,w-2,6,p.glow)
	_r(c,x+w/2,y,1,9,p.dark)
	_r(c,x-2,y+9,w+4,2,p.light)


static func _target(c: Object,at: Vector2,p: Dictionary) -> void:
	_p(c,[at+Vector2(-12,-12),at+Vector2(9,-12),at+Vector2(14,-4),at+Vector2(13,10),at+Vector2(-8,13),at+Vector2(-14,4)],INK)
	_r(c,int(at.x)-10,int(at.y)-10,21,20,p.wall)
	_r(c,int(at.x)-8,int(at.y)-8,17,16,p.light)
	_r(c,int(at.x)-5,int(at.y)-5,11,10,p.roof_dark)
	_r(c,int(at.x)-3,int(at.y)-3,7,6,p.glow)
	_r(c,int(at.x)-1,int(at.y)-1,3,2,INK)


static func _gear(c: Object,at: Vector2,r: int,p: Dictionary) -> void:
	for index: int in range(8):
		var offset:=Vector2.from_angle(index*PI/4)*float(r)
		_r(c,roundi(at.x+offset.x)-2,roundi(at.y+offset.y)-2,5,5,p.dark)
	_p(c,[at+Vector2(-r,-5),at+Vector2(-5,-r),at+Vector2(5,-r),at+Vector2(r,-5),at+Vector2(r,5),at+Vector2(5,r),at+Vector2(-5,r),at+Vector2(-r,5)],p.light)
	_r(c,int(at.x)-6,int(at.y)-6,13,13,p.roof_dark)
	_r(c,int(at.x)-2,int(at.y)-2,5,5,p.wall)


static func _leaf(c: Object,at: Vector2,w: int,h: int,p: Dictionary) -> void:
	_p(c,[at+Vector2(-w,3),at+Vector2(-w+6,-h+4),at+Vector2(-5,-h),at+Vector2(7,-h+2),at+Vector2(w,-2),at+Vector2(w-3,7),at+Vector2(5,h),at+Vector2(-w+6,10)],p.roof_dark)
	_p(c,[at+Vector2(-w+3,2),at+Vector2(-w+8,-h+5),at+Vector2(-5,-h+2),at+Vector2(6,-h+4),at+Vector2(w-3,-1),at+Vector2(w-5,4),at+Vector2(3,h-3),at+Vector2(-w+7,7)],p.roof)
	_l(c,at+Vector2(-w+8,-h+5),at+Vector2(-5,-h+3),p.roof_light,2)


static func _crystal(c: Object,at: Vector2,w: int,h: int,p: Dictionary) -> void:
	_p(c,[at+Vector2(-w,0),at+Vector2(-w+2,-h+8),at+Vector2(0,-h),at+Vector2(w-1,-h+10),at+Vector2(w,0)],p.dark)
	_p(c,[at+Vector2(-w+2,-1),at+Vector2(-w+4,-h+9),at+Vector2(0,-h+3),at+Vector2(1,-2)],p.glow)
	_p(c,[at+Vector2(0,-h+3),at+Vector2(w-3,-h+11),at+Vector2(w-2,-1),at+Vector2(1,-2)],p.roof)
	_l(c,at+Vector2(0,-h+5),at+Vector2(0,-4),p.light)


static func _r(c: Object,x: int,y: int,w: int,h: int,color: Color) -> void:
	c.draw_rect(Rect2(x,y,w,h),color)


static func _l(c: Object,a: Vector2,b: Vector2,color: Color,width: int=1) -> void:
	c.draw_line(a,b,color,width)


static func _p(c: Object,points: Array,color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array(points),color)


static func _nearest(canvas: Object) -> void:
	if canvas is CanvasItem and canvas.texture_filter!=CanvasItem.TEXTURE_FILTER_NEAREST:
		canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
