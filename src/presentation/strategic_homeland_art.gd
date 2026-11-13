extends RefCounted
## Original low homeland scenery. This seam receives detached, validated
## positions only; it never reads a match, owner, timer or simulation object.
const Brush = preload("res://src/presentation/strategic_pixel_brush.gd")
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const MAX_FRAMES := 48
const SOURCE_RADIUS := 25
const FAMILY_COUNT := 3
const VARIANT_COUNT := 4
static var _frames: Dictionary = {}
static var _order: Array[String] = []
static var _bakes := 0
static var _hits := 0

static func draw_cluster(canvas: Object,center: Vector2,pixel: float,faction: String,family: int,variant: int) -> void:
	if not center.is_finite() or not is_finite(pixel) or pixel<=0: return
	var frame := _frame(faction,family,variant)
	var rect: Rect2i = frame.rect
	if canvas is CanvasItem and canvas.texture_filter!=CanvasItem.TEXTURE_FILTER_NEAREST:
		canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect(frame.texture,Rect2(center+Vector2(rect.position)*pixel,Vector2(rect.size)*pixel),false)

static func draw_surface_detail(canvas: Object,point: Vector2,pixel: float,faction: String,key: int) -> void:
	if not point.is_finite() or not is_finite(pixel) or pixel<=0: return
	# Six quiet flat strokes at most; their complete local envelope is
	# x[-11,12], y[-6,7]. They are materials, not paths or collectible objects.
	var style := _faction(faction)
	var v := posmod(key,4)
	if style=="HUMAN":
		_r(canvas,point,pixel,Rect2(-10,-3,9,4),Color("676b54"))
		_r(canvas,point,pixel,Rect2(0,-4,10,4),Color("6b6d55"))
		_r(canvas,point,pixel,Rect2(-5,2,12,3),Color("62684f"))
		_l(canvas,point,pixel,Vector2(-9,-3),Vector2(-3,-3),Color("73745b"))
		_l(canvas,point,pixel,Vector2(1,-4),Vector2(7,-4),Color("75755c"))
		_r(canvas,point,pixel,Rect2(8,3-v,2,3),Color("57674b"))
	elif style=="UNDEAD":
		_r(canvas,point,pixel,Rect2(-10,-1,13,3),Color("625e61"))
		_r(canvas,point,pixel,Rect2(-3,3,13,2),Color("686165"))
		_l(canvas,point,pixel,Vector2(-8,-5),Vector2(-1,-1),Color("57565b"))
		_l(canvas,point,pixel,Vector2(-1,-1),Vector2(2,4),Color("57565b"))
		_l(canvas,point,pixel,Vector2(0,0),Vector2(7,-2-v),Color("58565b"))
		_r(canvas,point,pixel,Rect2(6,3,3,2),Color("77716e"))
	elif style=="MACHINE":
		_r(canvas,point,pixel,Rect2(-11,-4,11,7),Color("736d5c"))
		_r(canvas,point,pixel,Rect2(1,-2,10,7),Color("6d695b"))
		_l(canvas,point,pixel,Vector2(0,-4),Vector2(0,5),Color("626457"))
		_l(canvas,point,pixel,Vector2(-10,-4),Vector2(-2,-4),Color("817760"))
		_r(canvas,point,pixel,Rect2(-9,-2,1,1),Color("89806b"))
		_r(canvas,point,pixel,Rect2(8,2+v%2,1,1),Color("89806b"))
	elif style=="FOREST":
		_l(canvas,point,pixel,Vector2(-11,5),Vector2(-2,0),Color("4b6149"))
		_l(canvas,point,pixel,Vector2(-2,0),Vector2(9,-3),Color("4c6149"))
		_l(canvas,point,pixel,Vector2(-2,0),Vector2(4,5),Color("415a43"))
		_p(canvas,point,pixel,[Vector2(-8,-2),Vector2(-9,-5),Vector2(-3,-3),Vector2(-2,0)],Color("526c4e"))
		_p(canvas,point,pixel,[Vector2(2,-3),Vector2(4,-6),Vector2(9,-5),Vector2(5,-2)],Color("536d4f"))
		_p(canvas,point,pixel,[Vector2(5,3),Vector2(10,2),Vector2(12,5),Vector2(8,6)],Color("50694c"))
	elif style=="HIGHLAND":
		_p(canvas,point,pixel,[Vector2(-11,0),Vector2(-6,-5),Vector2(1,-4),Vector2(3,0),Vector2(-3,3)],Color("9daaa4"))
		_p(canvas,point,pixel,[Vector2(1,3),Vector2(6,0),Vector2(11,2),Vector2(9,6),Vector2(4,7)],Color("9ba9a4"))
		_r(canvas,point,pixel,Rect2(-5,-1,5,2),Color("85968f"))
		_r(canvas,point,pixel,Rect2(5,3,4,2),Color("879890"))
		_l(canvas,point,pixel,Vector2(-9,2),Vector2(-5,3),Color("8c9a93"))
		_l(canvas,point,pixel,Vector2(3,-3-v%2),Vector2(7,-3),Color("9fada6"))
	else:
		_p(canvas,point,pixel,[Vector2(-11,0),Vector2(-7,-4),Vector2(-1,-3),Vector2(2,1),Vector2(-3,4)],Color("64627a"))
		_p(canvas,point,pixel,[Vector2(0,2),Vector2(5,-2),Vector2(10,0),Vector2(9,5),Vector2(4,6)],Color("5e6074"))
		_r(canvas,point,pixel,Rect2(-7,-2,2,1),Color("747286"))
		_r(canvas,point,pixel,Rect2(-3,1,2,1),Color("777288"))
		_r(canvas,point,pixel,Rect2(5,2+v%2,2,1),Color("757486"))
		_l(canvas,point,pixel,Vector2(1,4),Vector2(5,5),Color("555a6a"))

static func inspect(faction: String,family: int,variant: int) -> Dictionary:
	var frame := _frame(faction,family,variant)
	var image: Image=frame.image
	var mask:=PackedByteArray()
	var opaque:=0
	var colors: Dictionary={}
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var color:=image.get_pixel(x,y)
			mask.append(1 if color.a>0.5 else 0)
			if color.a<=0.5:continue
			opaque+=1
			colors[color.to_rgba32()]=true
	# Include location and dimensions in the silhouette fingerprint. The
	# returned image owns its bytes; inspection cannot poison a cached frame.
	var shape:=var_to_str(frame.rect)+":"+mask.hex_encode()
	return {"image":Image.create_from_data(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8,image.get_data()),
		"rect":frame.rect,"key":frame.key,"pixel_hash":image.get_data().hex_encode().sha256_text(),
		"silhouette_hash":shape.sha256_text(),"clipped_commands":frame.clipped,"source_commands":frame.commands,
		"opaque_pixels":opaque,"colors":colors.size(),"source_radius":SOURCE_RADIUS,
		"faction":frame.faction,"family":frame.family,"variant":frame.variant}

static func cache_stats() -> Dictionary:
	var bytes:=0
	for frame: Dictionary in _frames.values(): bytes+=int(frame.rect.size.x)*int(frame.rect.size.y)*4
	return {"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"hits":_hits,
		"cpu_pixel_bytes":bytes,"maximum_cpu_pixel_bytes":MAX_FRAMES*(SOURCE_RADIUS*2+1)*(SOURCE_RADIUS*2+1)*4}

static func clear_cache() -> void:
	_frames.clear()
	_order.clear()
	_bakes=0
	_hits=0

static func _faction(raw: String) -> String:
	var value:=raw.to_upper()
	return value if value in FACTIONS else "HUMAN"

static func _frame(raw_faction: String,raw_family: int,raw_variant: int) -> Dictionary:
	var faction:=_faction(raw_faction)
	var family:=posmod(raw_family,FAMILY_COUNT)
	var variant:=posmod(raw_variant,VARIANT_COUNT)
	var key:="%s:%d:%d"%[faction,family,variant]
	if _frames.has(key):
		_hits+=1
		_order.erase(key)
		_order.append(key)
		return _frames[key]
	var brush:=Brush.new()
	_paint(brush,faction,family,variant)
	var used:=brush.image.get_used_rect()
	var image:=brush.image.get_region(used)
	var frame: Dictionary={"key":key,"faction":faction,"family":family,"variant":variant,"image":image,
		"texture":ImageTexture.create_from_image(image),"rect":Rect2i(used.position-Brush.FOOT,used.size),
		"commands":brush.commands,"clipped":brush.clipped}
	while _order.size()>=MAX_FRAMES: _frames.erase(_order.pop_front())
	_order.append(key)
	_frames[key]=frame
	_bakes+=1
	return frame

static func _paint(canvas: Object,faction: String,family: int,variant: int) -> void:
	var palettes: Dictionary={
		"HUMAN":[Color("4a5942"),Color("6b7750")],"UNDEAD":[Color("4c4950"),Color("696065")],
		"MACHINE":[Color("545647"),Color("7c7259")],"FOREST":[Color("344b3c"),Color("4e6548")],
		"HIGHLAND":[Color("6c7d76"),Color("a6b2a9")],"UNDERGROUND":[Color("484b5e"),Color("6f6b7f")]}
	var shades: Array=palettes[faction]
	# Four low, broken ground facets—not one opaque disk or an ownership aura.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-21,0),Vector2(-16,-4),Vector2(-5,-3),Vector2(-2,3),Vector2(-9,6),Vector2(-19,4)]),shades[0])
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-6,-8),Vector2(2,-11),Vector2(10,-6),Vector2(9,0),Vector2(0,2),Vector2(-5,-2)]),shades[0])
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(5,2),Vector2(10,-3),Vector2(20,0),Vector2(21,4),Vector2(14,7),Vector2(7,6)]),shades[0])
	canvas.draw_rect(Rect2(-3,5,5,2),shades[1])
	var positions: Array[Vector2]=[Vector2(-12,0),Vector2(0,-7),Vector2(12,1)]
	if family==1: positions=[Vector2(-12,1),Vector2(-1,-5),Vector2(12,-1)]
	elif family==2: positions=[Vector2(-12,-1),Vector2(0,-7),Vector2(12,2)]
	positions[0]+=Vector2(variant%2,0)
	positions[1]+=Vector2((variant+1)%2,-variant/2)
	positions[2]+=Vector2(0,variant%2)
	for index: int in range(positions.size()):
		var at: Vector2=positions[index]
		var v:=posmod(variant+index,4)
		if faction=="HUMAN": _human(canvas,at,family,v)
		elif faction=="UNDEAD": _undead(canvas,at,family,v)
		elif faction=="MACHINE": _machine(canvas,at,family,v)
		elif faction=="FOREST": _forest(canvas,at,family,v)
		elif faction=="HIGHLAND": _highland(canvas,at,family,v)
		else: _underground(canvas,at,family,v)
	# Sparse material fragments join the group, always inside the footprint.
	for index: int in range(4):
		canvas.draw_rect(Rect2(-16+index*10,6+index%2,2,1),shades[1])

static func _human(c: Object,a: Vector2,f: int,v: int) -> void:
	var stone:=Color("888a74")
	var edge:=Color("575e4a")
	if f==0:
		# Three small stone-edged flower beds, not a food source or building.
		_p(c,a,1,[Vector2(-7,2),Vector2(-6,-3),Vector2(4,-4),Vector2(8,0),Vector2(5,4),Vector2(-3,5)],edge)
		_r(c,a,1,Rect2(-6,-2,12,4),Color("615e43"))
		_r(c,a,1,Rect2(-7,2,5,2),stone)
		_r(c,a,1,Rect2(-1,3,6,2),stone.darkened(0.12))
		_r(c,a,1,Rect2(5,0,3,2),stone)
		_r(c,a,1,Rect2(-5,-3,5,1),Color("a5a389"))
		for x: int in [-4,1,4]:
			_r(c,a,1,Rect2(x,-6-v%2,1,7),Color("566e45"))
			_r(c,a,1,Rect2(x-1,-7-v%2,3,2),Color("c0ae87") if x!=1 else Color("b69994"))
		_l(c,a,1,Vector2(-3,0),Vector2(0,-3),Color("7c8954"))
	elif f==1:
		_p(c,a,1,[Vector2(-8,0),Vector2(-5,-5),Vector2(4,-6),Vector2(8,-2),Vector2(6,4),Vector2(-4,5)],edge)
		for index: int in range(4):
			var p:=Vector2(-6+(index%2)*7,-4+(index/2)*4)
			_r(c,a,1,Rect2(p,Vector2(6,3)),Color("9b8668") if index%2 else Color("88785e"))
			_r(c,a,1,Rect2(p,Vector2(5,1)),Color("b29b77"))
		_r(c,a,1,Rect2(-2,-5,2,2),Color("626b47"))
		_r(c,a,1,Rect2(4,2,2,3),Color("6b7b4b"))
		_r(c,a,1,Rect2(-6,4,4,1),Color("a38f6d"))
	else:
		# Short broken garden posts: no traversability or fence-wall claim.
		_r(c,a,1,Rect2(-7,-6,14,3),Color("62533c"))
		_r(c,a,1,Rect2(-7,-6,14,1),Color("9c8459"))
		for x: int in [-6,0,5]:
			_r(c,a,1,Rect2(x,-9-v%2,2,13),Color("746044"))
			_r(c,a,1,Rect2(x,-9-v%2,2,2),Color("b29b70"))
			_r(c,a,1,Rect2(x+1,-5,1,6),Color("534d36"))
		_r(c,a,1,Rect2(-8,3,5,2),Color("76834f"))
		_r(c,a,1,Rect2(2,3,5,2),Color("6c7e47"))
		_l(c,a,1,Vector2(-4,3),Vector2(-2,-1),Color("9c9b65"))
		_l(c,a,1,Vector2(3,3),Vector2(4,0),Color("8e945b"))

static func _undead(c: Object,a: Vector2,f: int,v: int) -> void:
	if f==0:
		_p(c,a,1,[Vector2(-7,2),Vector2(-7,-3),Vector2(-2,-7),Vector2(3,-5),Vector2(7,1),Vector2(4,4)],Color("6f6867"))
		_p(c,a,1,[Vector2(-6,-2),Vector2(-2,-6),Vector2(3,-4),Vector2(2,0),Vector2(-2,2)],Color("a49a84"))
		_l(c,a,1,Vector2(-3,-4),Vector2(-1,-1),Color("d0c1a1"))
		_l(c,a,1,Vector2(0,-1),Vector2(4,1),Color("554f55"))
		_r(c,a,1,Rect2(2,-4,3,2),Color("7c7571"))
		_r(c,a,1,Rect2(-7,3,4,2),Color("b3a58c"))
		_r(c,a,1,Rect2(-6,3,2,1),Color("d2c5aa"))
		_r(c,a,1,Rect2(4,3,3,1),Color("81736a"))
		_r(c,a,1,Rect2(-1,4,3,1),Color("625a60"))
		_r(c,a,1,Rect2(-5,-4,2,1),Color("c0b297"))
		_l(c,a,1,Vector2(3,-5),Vector2(6,-3),Color("b4a58b"))
	elif f==1:
		_r(c,a,1,Rect2(-3,-7,6,10),Color("4b454a"))
		_r(c,a,1,Rect2(-2,-8,4,2),Color("7c6b64"))
		_l(c,a,1,Vector2(0,1),Vector2(-6,-7),Color("64585b"),2)
		_l(c,a,1,Vector2(-5,-5),Vector2(-7,-10),Color("655a5d"))
		_l(c,a,1,Vector2(0,-2),Vector2(5,-9-v%2),Color("7a6664"),2)
		_l(c,a,1,Vector2(3,-6),Vector2(7,-6),Color("8a736a"))
		_l(c,a,1,Vector2(0,-5),Vector2(0,-12),Color("87756d"))
		_r(c,a,1,Rect2(-7,3,5,2),Color("6c6265"))
		_r(c,a,1,Rect2(-6,2,3,1),Color("91807a"))
		_r(c,a,1,Rect2(4,2,4,2),Color("5f575e"))
		_r(c,a,1,Rect2(5,2,2,1),Color("8b7971"))
	else:
		_p(c,a,1,[Vector2(-8,0),Vector2(-5,-6),Vector2(2,-7),Vector2(7,-2),Vector2(6,4),Vector2(-3,5)],Color("4d4b53"))
		_p(c,a,1,[Vector2(-6,-1),Vector2(-4,-5),Vector2(1,-6),Vector2(5,-2),Vector2(2,2),Vector2(-4,3)],Color("77717a"))
		_l(c,a,1,Vector2(-4,-4),Vector2(0,-5),Color("9f9191"))
		_l(c,a,1,Vector2(-1,-5),Vector2(0,-1),Color("4c4b54"))
		_l(c,a,1,Vector2(0,-1),Vector2(4,0),Color("4c4b54"))
		_r(c,a,1,Rect2(-7,2,4,2),Color("80777a"))
		_r(c,a,1,Rect2(3,3,4,2),Color("8a7c7b"))
		_r(c,a,1,Rect2(4,3,2,1),Color("b0a09a"))
		_r(c,a,1,Rect2(-4,4,3,1),Color("615b64"))
		_r(c,a,1,Rect2(-6,-1,2,1),Color("a0918f"))
		_r(c,a,1,Rect2(2,-4-v%2,2,1),Color("857981"))

static func _machine(c: Object,a: Vector2,f: int,v: int) -> void:
	if f==0:
		_r(c,a,1,Rect2(-7,-4,13,5),Color("6d6450"))
		_r(c,a,1,Rect2(-7,-4,13,2),Color("a58b60"))
		_r(c,a,1,Rect2(-6,0,11,2),Color("514f43"))
		_r(c,a,1,Rect2(-8,-5,3,7),Color("8c8065"))
		_r(c,a,1,Rect2(-7,-3,1,3),Color("454c45"))
		_r(c,a,1,Rect2(3,-5,3,7),Color("c0a575"))
		_r(c,a,1,Rect2(6,-8,2,8),Color("8c7959"))
		_r(c,a,1,Rect2(4,-9,4,2),Color("ad956b"))
		_r(c,a,1,Rect2(-3,3,8,2),Color("716957"))
		_r(c,a,1,Rect2(-3,3,5,1),Color("968366"))
		_r(c,a,1,Rect2(-2,-3,1,1),Color("d0b88a"))
		_r(c,a,1,Rect2(4,-3,1,1),Color("d0b88a"))
	elif f==1:
		_p(c,a,1,[Vector2(-8,-1),Vector2(-6,-6),Vector2(3,-7),Vector2(8,-2),Vector2(6,4),Vector2(-5,5)],Color("4c544b"))
		_p(c,a,1,[Vector2(-6,-1),Vector2(-5,-5),Vector2(3,-6),Vector2(6,-2),Vector2(4,2),Vector2(-4,3)],Color("92917a"))
		_l(c,a,1,Vector2(-4,-5),Vector2(2,-6),Color("b4ab8b"))
		_l(c,a,1,Vector2(0,-5),Vector2(0,2),Color("5b6253"))
		_l(c,a,1,Vector2(-5,-1),Vector2(5,-1),Color("6c705e"))
		for p: Vector2 in [Vector2(-4,-3),Vector2(3,-3),Vector2(-3,1),Vector2(3,1)]:
			_r(c,a,1,Rect2(p,Vector2.ONE),Color("d0b487"))
		_r(c,a,1,Rect2(4,3,3,2),Color("a27f55"))
		_r(c,a,1,Rect2(-7,3,3,1),Color("82745b"))
	else:
		# Discarded short rail fittings, not a new traversable rail network.
		for y: int in [-5,0,4]:
			_r(c,a,1,Rect2(-6,y,12,2),Color("5c5e4d"))
			_r(c,a,1,Rect2(-5,y,10,1),Color("8c7d59"))
		_r(c,a,1,Rect2(-5,-7,2,12),Color("939681"))
		_r(c,a,1,Rect2(3,-8-v%2,2,13),Color("818872"))
		_r(c,a,1,Rect2(-4,-6,1,10),Color("bcc0a3"))
		_r(c,a,1,Rect2(4,-7,1,10),Color("aaa98b"))
		_r(c,a,1,Rect2(-7,3,2,2),Color("a98957"))
		_r(c,a,1,Rect2(6,-2,2,3),Color("70634b"))
		_r(c,a,1,Rect2(6,-2,1,1),Color("bd9a65"))

static func _forest(c: Object,a: Vector2,f: int,v: int) -> void:
	if f==0:
		_l(c,a,1,Vector2(0,4),Vector2(0,-10-v%2),Color("7d8b58"))
		for tier: int in range(4):
			var y: int=-8+tier*3
			var reach: int=4+tier
			_p(c,a,1,[Vector2(0,y+2),Vector2(-reach,y-1),Vector2(-reach+1,y-4),Vector2(-1,y)],Color("52764b"))
			_p(c,a,1,[Vector2(0,y+2),Vector2(reach,y-1),Vector2(reach-1,y-3),Vector2(1,y)],Color("688951"))
			_r(c,a,1,Rect2(-reach+1,y-2,2,1),Color("81985c"))
		_r(c,a,1,Rect2(-6,3,4,2),Color("465b3d"))
	elif f==1:
		_r(c,a,1,Rect2(-8,-3,15,6),Color("4a4934"))
		_r(c,a,1,Rect2(-7,-4,13,3),Color("766143"))
		_r(c,a,1,Rect2(-7,-3,3,5),Color("a68c5f"))
		_r(c,a,1,Rect2(-6,-2,1,3),Color("584e36"))
		_l(c,a,1,Vector2(-2,-2),Vector2(5,-2),Color("96805a"))
		_l(c,a,1,Vector2(0,0),Vector2(6,1),Color("3d4733"))
		_r(c,a,1,Rect2(-2,-5,7,3),Color("486540"))
		_r(c,a,1,Rect2(-1,-6,4,2),Color("729057"))
		_r(c,a,1,Rect2(4,-4,2,2),Color("8c9f63"))
		_r(c,a,1,Rect2(-5,3,4,2),Color("5a7447"))
		_r(c,a,1,Rect2(4,2,3,2),Color("6b8350"))
		_r(c,a,1,Rect2(5,-7-v%2,1,3),Color("8f9572"))
		_r(c,a,1,Rect2(3,-8-v%2,4,2),Color("b29e7d"))
	else:
		_l(c,a,1,Vector2(-7,3),Vector2(0,-1),Color("5f6040"),2)
		_l(c,a,1,Vector2(0,-1),Vector2(7,3),Color("746c47"),2)
		_l(c,a,1,Vector2(0,0),Vector2(3,-7),Color("7a754b"),2)
		_l(c,a,1,Vector2(-5,2),Vector2(-7,0),Color("9a9161"))
		_l(c,a,1,Vector2(2,0),Vector2(5,1),Color("a0925b"))
		_p(c,a,1,[Vector2(-7,-3),Vector2(-7,-7),Vector2(-2,-5),Vector2(0,-2)],Color("55784b"))
		_p(c,a,1,[Vector2(1,-5),Vector2(4,-10),Vector2(7,-8),Vector2(5,-4)],Color("6e8a52"))
		_p(c,a,1,[Vector2(3,3),Vector2(6,-1),Vector2(8,0),Vector2(7,4)],Color("547046"))
		_r(c,a,1,Rect2(-5,-7,2,2),Color("b7a4a0"))
		_r(c,a,1,Rect2(4,-10,2,2),Color("c1b78c"))
		_r(c,a,1,Rect2(-2,1,4,2),Color("4b583c"))

static func _highland(c: Object,a: Vector2,f: int,v: int) -> void:
	if f==0:
		_p(c,a,1,[Vector2(-8,1),Vector2(-5,-6),Vector2(3,-7),Vector2(8,-1),Vector2(5,4),Vector2(-4,5)],Color("5b6d68"))
		_p(c,a,1,[Vector2(-6,-1),Vector2(-3,-5),Vector2(3,-6),Vector2(6,-1),Vector2(2,2)],Color("929f94"))
		_p(c,a,1,[Vector2(-5,-4),Vector2(-2,-7),Vector2(3,-7),Vector2(5,-4),Vector2(1,-3)],Color("c3cfc2"))
		_l(c,a,1,Vector2(-4,-4),Vector2(1,-5),Color("d8ddcb"))
		_l(c,a,1,Vector2(-1,-3),Vector2(0,1),Color("6c8077"))
		_r(c,a,1,Rect2(4,0,2,2),Color("aebdad"))
		_r(c,a,1,Rect2(-7,3,4,2),Color("a5b4a8"))
		_r(c,a,1,Rect2(-6,3,3,1),Color("d1d8c8"))
		_r(c,a,1,Rect2(4,3,4,2),Color("7d9186"))
		_r(c,a,1,Rect2(-3,4,4,1),Color("65796f"))
		_r(c,a,1,Rect2(5,2,2,1),Color("becabc"))
	elif f==1:
		for tier: int in range(3):
			var width:=14-tier*4
			var y:=2-tier*4
			_r(c,a,1,Rect2(-width/2,y,width,4),Color("647c74"))
			_r(c,a,1,Rect2(-width/2+1,y,width-2,2),Color("9daca0"))
			_r(c,a,1,Rect2(width/2-3,y+2,3,2),Color("788f85"))
		_r(c,a,1,Rect2(-2,-8-v%2,5,2),Color("d6ddcd"))
		_r(c,a,1,Rect2(-6,1,5,1),Color("c0ccb8"))
		_r(c,a,1,Rect2(2,5,4,1),Color("4d665e"))
	else:
		_p(c,a,1,[Vector2(-7,1),Vector2(-7,-6),Vector2(-2,-9),Vector2(5,-7),Vector2(8,-1),Vector2(4,4),Vector2(-3,5)],Color("536962"))
		_p(c,a,1,[Vector2(-5,-1),Vector2(-5,-5),Vector2(-1,-7),Vector2(4,-5),Vector2(5,0),Vector2(1,2)],Color("8c9e92"))
		_l(c,a,1,Vector2(-3,-5),Vector2(2,-6),Color("b4c0ac"))
		_l(c,a,1,Vector2(-2,-3),Vector2(2,-3),Color("5a6c63"))
		_l(c,a,1,Vector2(0,-5),Vector2(0,0),Color("5a6c63"))
		_l(c,a,1,Vector2(-2,0),Vector2(0,-2),Color("5a6c63"))
		_r(c,a,1,Rect2(-7,3,4,2),Color("926c52"))
		_r(c,a,1,Rect2(-6,3,2,1),Color("b08a67"))
		_r(c,a,1,Rect2(4,2,3,2),Color("836649"))
		_r(c,a,1,Rect2(5,2,2,1),Color("b09b76"))
		_r(c,a,1,Rect2(2,-7-v%2,3,1),Color("c3cebd"))

static func _underground(c: Object,a: Vector2,f: int,v: int) -> void:
	if f==0:
		for index: int in range(3):
			var x: int=-5+index*5
			var top: int=-7-index%2*4-v%2
			_r(c,a,1,Rect2(x,top+3,2,7+index%2*2),Color("858b8d"))
			_r(c,a,1,Rect2(x-3,top+1,7,3),Color("85768f"))
			_r(c,a,1,Rect2(x-1,top,4,2),Color("a497aa"))
			_r(c,a,1,Rect2(x-2,top+2,2,1),Color("c2b4bc"))
			_r(c,a,1,Rect2(x+2,top+3,2,1),Color("615d77"))
	elif f==1:
		for index: int in range(3):
			var x: int=-5+index*5
			var top: int=-7-index%2*5-v%2
			_p(c,a,1,[Vector2(x-2,3),Vector2(x-2,top+3),Vector2(x,top),Vector2(x+3,top+4),Vector2(x+3,3)],Color("6f7788"))
			_p(c,a,1,[Vector2(x,top),Vector2(x+3,top+4),Vector2(x+2,2),Vector2(x,0)],Color("8d92a0"))
			_l(c,a,1,Vector2(x,top+3),Vector2(x,0),Color("b0acb4"))
			_r(c,a,1,Rect2(x+1,2,3,2),Color("555e70"))
		_r(c,a,1,Rect2(-6,4,4,1),Color("8a859d"))
	else:
		_p(c,a,1,[Vector2(-8,1),Vector2(-6,-4),Vector2(0,-6),Vector2(6,-3),Vector2(8,2),Vector2(3,5),Vector2(-4,5)],Color("625b75"))
		_p(c,a,1,[Vector2(-6,-1),Vector2(-2,-4),Vector2(3,-3),Vector2(6,1),Vector2(2,3),Vector2(-3,2)],Color("8d7c8f"))
		_l(c,a,1,Vector2(-3,-3),Vector2(-1,2),Color("b2a09f"))
		_l(c,a,1,Vector2(0,-3),Vector2(2,2),Color("5b586d"))
		_l(c,a,1,Vector2(3,-1),Vector2(4,1),Color("5b586d"))
		_r(c,a,1,Rect2(-5,-1,2,1),Color("c0ada8"))
		_r(c,a,1,Rect2(0,0,1,1),Color("c1aca5"))
		_r(c,a,1,Rect2(5,3,2,2),Color("797e8b"))
		_r(c,a,1,Rect2(6,3,1,1),Color("a7a0ae"))
		_r(c,a,1,Rect2(-7,3,3,2),Color("6d7083"))
		_r(c,a,1,Rect2(-6,3,1,1),Color("9b95a8"))
		_r(c,a,1,Rect2(2,-5-v%2,2,1),Color("988a9c"))

static func _r(canvas: Object,at: Vector2,pixel: float,rect: Rect2,color: Color) -> void:
	canvas.draw_rect(Rect2(at+rect.position*pixel,rect.size*pixel),color)

static func _l(canvas: Object,at: Vector2,pixel: float,a: Vector2,b: Vector2,color: Color,width: float=1) -> void:
	canvas.draw_line(at+a*pixel,at+b*pixel,color,maxf(width*pixel,0.1))

static func _p(canvas: Object,at: Vector2,pixel: float,points: Array,color: Color) -> void:
	var polygon:=PackedVector2Array()
	for point: Vector2 in points:polygon.append(at+point*pixel)
	canvas.draw_colored_polygon(polygon,color)
