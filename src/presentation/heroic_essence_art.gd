extends RefCounted
## Original, integer-raster spirit-vein. Shared fixed pixels, two textures at
## most; no light, shader, clock, random generator or per-site atlas copies.
const SIZE := Vector2i(48,48)
const FOOT := Vector2(24,43)
const SCALE := 3.0
static var _textures: Dictionary = {}
static var _hashes: Dictionary = {}

static func _rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	image.fill_rect(Rect2i(x,y,w,h).intersection(Rect2i(Vector2i.ZERO,SIZE)),color)

static func _poly(image: Image, points: Array[Vector2], color: Color) -> void:
	var polygon := PackedVector2Array(points)
	for y: int in range(SIZE.y):
		for x: int in range(SIZE.x):
			if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),polygon): image.set_pixel(x,y,color)

static func _texture(active: bool) -> Texture2D:
	var key := str(active)
	if _textures.has(key): return _textures[key]
	var image := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_poly(image,[Vector2(4,38),Vector2(11,30),Vector2(34,28),Vector2(44,36),Vector2(41,44),Vector2(13,46),Vector2(3,42)],Color("282932"))
	_poly(image,[Vector2(6,38),Vector2(13,32),Vector2(34,31),Vector2(42,36),Vector2(39,42),Vector2(13,44),Vector2(5,41)],Color("675f69"))
	for part: Array in [[8,37,7,2],[17,42,8,2],[32,34,6,2],[35,40,5,2],[6,40,3,1]]:
		_rect(image,part[0],part[1],part[2],part[3],Color("9b8f8d"))
	# Broad facets with stepped, irregular tops rather than smooth diamonds.
	_poly(image,[Vector2(16,38),Vector2(13,13),Vector2(19,4),Vector2(25,11),Vector2(27,36),Vector2(22,41)],Color("252532"))
	_poly(image,[Vector2(17,36),Vector2(15,14),Vector2(19,7),Vector2(23,13),Vector2(25,35),Vector2(22,38)],Color("805e9b"))
	_poly(image,[Vector2(17,14),Vector2(19,8),Vector2(20,36),Vector2(18,33)],Color("c3a0db"))
	_rect(image,18,16,1,13,Color("ead6eb")); _rect(image,21,27,2,8,Color("9f7aba"))
	_poly(image,[Vector2(25,39),Vector2(25,23),Vector2(31,13),Vector2(36,21),Vector2(35,39),Vector2(30,42)],Color("252532"))
	_poly(image,[Vector2(27,37),Vector2(27,24),Vector2(31,16),Vector2(34,22),Vector2(33,37),Vector2(30,39)],Color("a67ebc"))
	_rect(image,28,25,2,11,Color("d9bbdf")); _rect(image,32,25,1,10,Color("77548d"))
	_poly(image,[Vector2(9,39),Vector2(7,25),Vector2(11,21),Vector2(16,28),Vector2(17,40)],Color("282633"))
	_poly(image,[Vector2(10,37),Vector2(9,26),Vector2(11,24),Vector2(14,29),Vector2(15,38)],Color("ac8cbe"))
	_rect(image,10,28,1,8,Color("dfc6e6"))
	for part: Array in [[20,41,5,1],[26,39,3,1],[35,37,4,1],[36,36,1,2]]: _rect(image,part[0],part[1],part[2],part[3],Color("b397be"))
	if not active:
		for y: int in range(SIZE.y):
			for x: int in range(SIZE.x):
				var c := image.get_pixel(x,y)
				var grey := (c.r*0.3+c.g*0.5+c.b*0.2)*0.65
				image.set_pixel(x,y,Color(grey,grey,grey,c.a))
	_hashes[key] = image.get_data().hex_encode().sha256_text()
	_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]

static func inspect(source: Dictionary, factor: float = 1.0) -> Dictionary:
	if not is_finite(factor) or factor <= 0: return {"supported":false}
	var active: bool = int(source.get("remaining",source.get("remaining_amount",1))) > 0 and source.get("state","") not in ["DEPLETED","EXHAUSTED"]
	_texture(active)
	var body := Rect2((Vector2(3,4)-FOOT)*SCALE*factor,Vector2(42,42)*SCALE*factor)
	var badge := Rect2(Vector2(-11,4)*factor,Vector2(22,22)*factor)
	return {"supported":true,"kind":"ESSENCE","provenance":"original-pixel-spirit-vein-m51","original_art":true,"licensed_art":false,"source_unmodified":true,"bounds":body.merge(badge),"body_bounds":body,"badge_bounds":badge,"badge_center":Vector2(0,15)*factor,"badge_size":22*factor,"available":active,"depleted":not active,"state":str(source.get("state","")),"parts":[],"pixel_hash":_hashes[str(active)],"version":"m51-essence-vein-v1"}

static func draw(canvas: Object, point: Vector2, source: Dictionary, factor: float = 1.0) -> bool:
	if not point.is_finite() or not is_finite(factor) or factor <= 0: return false
	var info := inspect(source,factor)
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect_region(_texture(bool(info.available)),Rect2((point-FOOT*SCALE*factor).round(),Vector2(SIZE)*SCALE*factor),Rect2(Vector2.ZERO,Vector2(SIZE)),Color.WHITE)
	return true

static func debug_stats() -> Dictionary:
	return {"textures":_textures.size(),"capacity":2,"texture_bytes":_textures.size()*SIZE.x*SIZE.y*4,"maximum_texture_bytes":2*SIZE.x*SIZE.y*4,"owner_atlas_copies":0,"source_pixel_scale":SCALE}
