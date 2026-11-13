extends RefCounted
## Runtime-only decoration atlas. Original integer-pixel ornaments and the
## locally licensed Starter are composed once; no scene, clocks or authority.
const Catalog = preload("res://src/presentation/heroic_decor_catalog.gd")
const Atlas = preload("res://src/presentation/heroic_2d_atlas.gd")
const Brush = preload("res://src/presentation/heroic_pixel_brush.gd")
const Collection = preload("res://src/presentation/heroic_collection.gd")
const M66TerrainArt = preload("res://src/presentation/m66_terrain_art.gd")
const ATLAS_SIZE := Vector2i(512,384)
const CELL_SIZE := Vector2i(64,64)
const FOOT := Vector2i(32,52)
const CAPACITY := 48
const MAX_TEXTURE_BYTES := 512*384*4
const OUTLINE := Color("343d31")
const WOOD_DARK := Color("574632")
const WOOD := Color("927047")
const WOOD_LIGHT := Color("bd9c62")
const STONE_DARK := Color("626957")
const STONE := Color("92977b")
const STONE_LIGHT := Color("bdbea0")
const IRON := Color("677572")
const IRON_LIGHT := Color("a6afa0")
const MOSS := Color("628348")
static var _attempted := false
static var _ready := false
static var _texture: Texture2D
static var _image: Image
static var _frames: Dictionary = {}
static var _bakes := 0
static var _failures: Array[String] = []


static func _ensure_atlas() -> void:
	if _attempted: return
	_attempted = true
	var source: Dictionary = Atlas.validate_installation()
	if not bool(source.get("ready",false)):
		_failures.append("Installed Heroic Starter required for decoration compositions")
		return
	_image = Image.create(ATLAS_SIZE.x,ATLAS_SIZE.y,false,Image.FORMAT_RGBA8)
	_image.fill(Color.TRANSPARENT)
	var index := 0
	for family: String in Catalog.families():
		for variant: int in range(3):
			var brush := Brush.new()
			_paint(brush,family,variant)
			var crop_rect := Rect2i(Brush.FOOT-FOOT,CELL_SIZE)
			var used: Rect2i = brush.image.get_used_rect()
			var clipped := brush.clipped
			if not crop_rect.encloses(used): clipped += 1
			var cell: Image = brush.image.get_region(crop_rect)
			var occupied: Rect2i = cell.get_used_rect()
			var destination := Vector2i(index%8,index/8)*CELL_SIZE
			_image.blit_rect(cell,Rect2i(Vector2i.ZERO,CELL_SIZE),destination)
			var key := family+":"+str(variant)
			var definition: Dictionary = Catalog.definition(family)
			var local := Rect2(Vector2(occupied.position-FOOT),Vector2(occupied.size))
			var radius := 0.0
			for corner: Vector2 in [local.position,Vector2(local.end.x,local.position.y),local.end,Vector2(local.position.x,local.end.y)]:
				radius = maxf(radius,corner.length()*float(definition.display_scale))
			if radius > float(definition.footprint): _failures.append("Decoration exceeds declared footprint: "+key)
			if clipped > 0: _failures.append("Decoration escaped its atlas cell: "+key)
			_frames[key] = {"supported":true,"key":key,"family":family,"variant":variant,"layer":str(definition.layer),
				"rect":local,"source_rect":Rect2(Vector2(destination+occupied.position),Vector2(occupied.size)),
				"anchor":Vector2(FOOT-occupied.position),"pixel_hash":cell.get_data().hex_encode().sha256_text(),
				"source_commands":brush.commands,"clipped_commands":clipped,"licensed_components":int(brush.get_meta("heroic_source_sprites",0))>0,"source_sprite_count":int(brush.get_meta("heroic_source_sprites",0)),
				"original_ornament":true,"footprint":float(definition.footprint),"display_scale":float(definition.display_scale)}
			index += 1
	if index != CAPACITY: _failures.append("Decoration catalogue must contain exactly forty-eight cells")
	_ready = _failures.is_empty()
	if _ready: _texture = ImageTexture.create_from_image(_image)
	_bakes += 1


static func inspect(entry: Dictionary) -> Dictionary:
	_ensure_atlas()
	var family := str(entry.get("family",""))
	var variant := int(entry.get("variant",0))
	var key := family+":"+str(variant)
	if not _ready or not _frames.has(key): return {"supported":false,"key":key}
	var result: Dictionary = _frames[key].duplicate(true)
	var art_scale := float(entry.get("scale",result.display_scale))
	if not is_finite(art_scale) or art_scale <= 0: return {"supported":false,"key":key}
	result["world_bounds"] = Rect2(Vector2(result.rect.position)*art_scale,Vector2(result.rect.size)*art_scale)
	result["scale"] = art_scale
	if family=="THICKET" and Collection.active():
		result.merge(M66TerrainArt.inspect_thicket(entry),true)
		result["legacy_atlas_fields_are_fallback"] = true
	return result


static func visual_bounds(entry: Dictionary, scale: float = 1.0) -> Rect2:
	if not is_finite(scale) or scale<=0: return Rect2()
	if str(entry.get("family","")) == "THICKET" and Collection.active():
		var grove := M66TerrainArt.thicket_bounds(entry)
		return Rect2(grove.position*scale,grove.size*scale)
	var frame := inspect(entry)
	if not bool(frame.supported): return Rect2()
	var world: Rect2 = frame.world_bounds
	return Rect2(world.position*scale,world.size*scale)


static func draw(canvas: Object, foot: Vector2, entry: Dictionary, scale: float, opacity: float = 1.0) -> bool:
	if not foot.is_finite() or not is_finite(opacity) or opacity<=0: return false
	if str(entry.get("family","")) == "THICKET" and Collection.active(): return M66TerrainArt.draw_thicket(canvas,foot,entry,scale,opacity)
	var bounds := visual_bounds(entry,scale)
	if bounds.size == Vector2.ZERO: return false
	var frame := inspect(entry)
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect_region(_texture,Rect2((foot+bounds.position).round(),bounds.size),frame.source_rect,Color(1,1,1,clampf(opacity,0,1)))
	return true


static func ground_patch(entry: Dictionary) -> Dictionary:
	var frame := inspect(entry)
	if not bool(frame.supported): return {}
	# Returned pixels and anchor are world-sized. The ground baker converts
	# them together to its own world-pixel ratio; never mutate shared sources.
	var image := _image.get_region(Rect2i(frame.source_rect))
	var extent := Vector2i(maxi(1,roundi(image.get_width()*float(frame.scale))),maxi(1,roundi(image.get_height()*float(frame.scale))))
	image.resize(extent.x,extent.y,Image.INTERPOLATE_NEAREST)
	return {"image":image,"anchor":Vector2(frame.anchor)*float(frame.scale)}


static func debug_stats() -> Dictionary:
	_ensure_atlas()
	return {"ready":_ready,"frames":_frames.size(),"capacity":CAPACITY,"texture_count":1 if _texture!=null else 0,
		"texture_bytes":MAX_TEXTURE_BYTES if _texture!=null else 0,"maximum_texture_bytes":MAX_TEXTURE_BYTES,
		"cpu_pixel_bytes":MAX_TEXTURE_BYTES if _image!=null else 0,"atlas_size":ATLAS_SIZE,"owner_atlas_copies":0,
		"bakes":_bakes,"failures":_failures.duplicate(),"version":Catalog.VERSION,"runtime_thicket_pipeline":M66TerrainArt.VERSION if Collection.active() else "starter-fallback","runtime_thicket_shares_collection_texture":Collection.active()}


static func _paint(b: Object, family: String, variant: int) -> void:
	_shadow(b,Vector2.ZERO,20 if family=="THICKET" else 18)
	match family:
		"MEADOW":
			if variant==0:
				_sprite(b,"flowers",Vector2(-4,0));_grass(b,Vector2(15,1));_grass(b,Vector2(-14,4))
			elif variant==1:
				_sprite(b,"flowers_small",Vector2(6,1));_sprite(b,"stones_small",Vector2(-11,3),0.55);_grass(b,Vector2(16,5))
			else:
				_sprite(b,"flowers_small",Vector2(-10,-3),0.7);_sprite(b,"flowers",Vector2(10,4),0.65);_grass(b,Vector2(0,5))
		"THICKET":
			if variant==0:
				_sprite(b,"oak_pair",Vector2(0,1),0.9);_sprite(b,"bush",Vector2(-15,4),0.8);_grass(b,Vector2(15,5))
			elif variant==1:
				_sprite(b,"pine_pair",Vector2(5,0),0.85);_sprite(b,"pine",Vector2(-13,6),0.9);_stone(b,Vector2(14,6),4)
			else:
				_sprite(b,"oak",Vector2(-9,-4),1.15);_sprite(b,"bush_wide",Vector2(9,5),1.1);_stump(b,Vector2(-14,8));_grass(b,Vector2(18,7))
		"ROCK_GARDEN":
			if variant==0:
				_sprite(b,"stones",Vector2(-4,1));_stone(b,Vector2(14,5),4);_moss(b,Vector2(-9,3));_grass(b,Vector2(18,1))
			elif variant==1:
				_stone(b,Vector2(-13,4),6);_stone(b,Vector2(1,-1),9);_stone(b,Vector2(15,5),5);_moss(b,Vector2(2,5))
			else:
				for i: int in range(6): _stone(b,Vector2.from_angle(i*TAU/6)*Vector2(14,6),3)
				_grass(b,Vector2(-3,1));_moss(b,Vector2(8,6))
		"DEADWOOD":
			if variant==0:
				_sprite(b,"deadwood",Vector2(-2,1));_grass(b,Vector2(14,6));_stone(b,Vector2(-15,5),3)
			elif variant==1:
				_stump(b,Vector2(-9,3));_branch(b,Vector2(1,-5),Vector2(19,5));_grass(b,Vector2(-17,6))
			else:
				_sprite(b,"deadwood",Vector2(-5,0),0.8);_mushroom(b,Vector2(11,3),Color("aa7d57"),5);_mushroom(b,Vector2(17,6),Color("c59c6d"),3)
		"SHORE_REEDS":
			if variant==0:
				_sprite(b,"reeds",Vector2(-2,0));_stone(b,Vector2(14,5),4)
			elif variant==1:
				_sprite(b,"reeds",Vector2(-7,1),0.75);_stone(b,Vector2(13,4),6);_cattail(b,Vector2(18,-1),12)
			else:
				for i: int in range(4): _cattail(b,Vector2(-12+i*7,3+absi(i-1)),12+(i%2)*4)
				_stone(b,Vector2(0,7),4)
		"WELL":
			_well(b,Vector2(-3,3),variant)
			if variant==0: _barrel(b,Vector2(16,5))
			elif variant==1: _grass(b,Vector2(-18,7));_stone(b,Vector2(17,6),4)
			else: _trough(b,Vector2(13,5));_grass(b,Vector2(-18,7))
		"BARRELS_CRATES":
			if variant==0:
				_crate(b,Vector2(-7,3),13);_barrel(b,Vector2(10,5));_barrel(b,Vector2(-13,8),0.7)
			elif variant==1:
				_barrel(b,Vector2(-9,2));_barrel(b,Vector2(6,5));_crate(b,Vector2(16,8),8)
			else:
				_crate(b,Vector2(-8,4),15);_crate(b,Vector2(10,7),11);_cloth(b,Vector2(-14,-10),Color("7e8e73"))
		"FENCE_CORNER":
			if variant==0: _fence(b,Vector2(-17,4),Vector2(1,-4));_fence(b,Vector2(1,-4),Vector2(18,4));_grass(b,Vector2(3,7))
			elif variant==1: _fence(b,Vector2(-18,5),Vector2(-3,-1));_branch(b,Vector2(2,1),Vector2(18,7));_stump(b,Vector2(16,-1))
			else: _fence(b,Vector2(-16,4),Vector2(16,4));_stone(b,Vector2(-16,7),5);_stone(b,Vector2(16,7),5);_grass(b,Vector2(0,8))
		"SIGNPOST":
			_sign(b,Vector2(-2,4),variant)
			if variant==0: _grass(b,Vector2(12,7))
			elif variant==1: _stone(b,Vector2(-12,7),5);_stone(b,Vector2(11,7),4)
			else: _barrel(b,Vector2(13,7),0.7)
		"CART":
			_cart(b,Vector2(-1,3),variant)
			if variant==0: _crate(b,Vector2(15,8),8)
			elif variant==1: _grass(b,Vector2(-18,8))
			else: _barrel(b,Vector2(-15,5),0.7)
		"CAMP_SUPPLIES":
			if variant==0:
				_crate(b,Vector2(-9,3),11);_roll(b,Vector2(8,-1),Color("80907b"));_pot(b,Vector2(14,7),5)
			elif variant==1:
				_tent(b,Vector2(-6,4));_crate(b,Vector2(15,7),9);_roll(b,Vector2(-13,8),Color("9d815b"))
			else:
				_pot(b,Vector2(-11,3),7);_pot(b,Vector2(5,7),5);_crate(b,Vector2(15,3),9);_roll(b,Vector2(-8,9),Color("8b8b6e"))
		"RUIN_PILLARS":
			if variant==0:
				_pillar(b,Vector2(-10,3),23);_pillar(b,Vector2(13,7),12);_moss(b,Vector2(-10,5))
			elif variant==1:
				_pillar(b,Vector2(-14,4),12);_fallen_column(b,Vector2(5,5));_stone(b,Vector2(18,8),4)
			else:
				_pillar(b,Vector2(-13,5),22);_pillar(b,Vector2(13,5),16);_wall(b,Vector2(-5,4),15);_grass(b,Vector2(0,8))
		"GRAVESTONES_BONES":
			if variant==0:
				_grave(b,Vector2(-9,4),18);_grave(b,Vector2(11,7),12);_bones(b,Vector2(1,8))
			elif variant==1:
				_sarcophagus(b,Vector2(-2,4));_bones(b,Vector2(13,7));_grass(b,Vector2(-17,7),true)
			else:
				_grave(b,Vector2(1,4),14);_stone(b,Vector2(-14,7),6);_grass(b,Vector2(14,6),true);_bones(b,Vector2(-3,7))
		"FUNGAL_CRYSTAL":
			if variant==0:
				_mushroom(b,Vector2(-11,3),Color("ad8b9f"),7);_crystal(b,Vector2(7,5),14);_mushroom(b,Vector2(17,8),Color("a6a77b"),3)
			elif variant==1:
				for i: int in range(5): _mushroom(b,Vector2.from_angle(i*TAU/5)*Vector2(14,6)+Vector2(0,2),Color("ad8c79") if i%2==0 else Color("b39aac"),4+(i%2))
			else:
				_stone(b,Vector2(-10,5),8);_crystal(b,Vector2(1,3),18);_crystal(b,Vector2(13,6),11);_moss(b,Vector2(-5,9))
		"SNOW_CAIRN":
			if variant==0:
				_stone(b,Vector2(0,4),11,true);_stone(b,Vector2(-1,-4),7,true);_stone(b,Vector2(0,-11),4,true);_snow(b,Vector2(-15,7))
			elif variant==1:
				_stone(b,Vector2(-11,5),9,true);_stone(b,Vector2(11,7),7,true);_snow(b,Vector2(-1,8))
			else:
				for i: int in range(3): _stone(b,Vector2(-13+i*12,5-(i%2)*4),6,true)
				_snow(b,Vector2(0,10));_grass(b,Vector2(18,7),true)
		"MACHINE_SCRAP":
			if variant==0:
				_wheel(b,Vector2(-10,2),8);_pipe(b,Vector2(3,5),16);_metal_plate(b,Vector2(11,7),11)
			elif variant==1:
				_metal_plate(b,Vector2(-9,4),17);_metal_plate(b,Vector2(11,6),10);_bolt(b,Vector2(2,-4));_pipe(b,Vector2(-10,9),12)
			else:
				_pipe(b,Vector2(-6,0),19);_crate(b,Vector2(11,7),11);_wheel(b,Vector2(-14,7),5);_bolt(b,Vector2(1,9))


static func _sprite(b: Object, key: String, foot: Vector2, scale: float = 1.0) -> void:
	b.set_meta("heroic_source_sprites",int(b.get_meta("heroic_source_sprites",0))+1)
	Atlas.draw_sprite(b,key,foot,scale)


static func _r(b: Object, x: float, y: float, width: float, height: float, color: Color) -> void:
	b.draw_rect(Rect2(x,y,width,height),color)


static func _p(b: Object, points: Array[Vector2], color: Color) -> void:
	b.draw_colored_polygon(PackedVector2Array(points),color)


static func _shadow(b: Object, point: Vector2, radius: int) -> void:
	_r(b,point.x-radius+3,point.y+2,radius*2-6,5,Color("344e31",0.3))
	_r(b,point.x-radius,point.y+3,radius*2,3,Color("344e31",0.2))


static func _grass(b: Object, point: Vector2, dry: bool = false) -> void:
	var color := Color("8d8b59") if dry else Color("698f42")
	b.draw_line(point+Vector2(-4,0),point+Vector2(-5,-5),color,1)
	b.draw_line(point,point+Vector2(0,-7),color.lightened(0.15),1)
	b.draw_line(point+Vector2(3,0),point+Vector2(6,-4),color,1)
	_r(b,point.x-3,point.y,7,1,color.darkened(0.15))


static func _moss(b: Object, point: Vector2) -> void:
	_r(b,point.x-4,point.y,9,2,MOSS.darkened(0.1))
	_r(b,point.x-2,point.y-1,5,1,MOSS.lightened(0.15))


static func _stone(b: Object, point: Vector2, size: int, snowy: bool = false) -> void:
	_p(b,[point+Vector2(-size,0),point+Vector2(-size+2,-size*0.6),point+Vector2(size-2,-size),point+Vector2(size,0),point+Vector2(size-3,3),point+Vector2(-size+2,3)],OUTLINE)
	_p(b,[point+Vector2(-size+2,-1),point+Vector2(-size+3,-size*0.5),point+Vector2(size-3,-size+2),point+Vector2(size-1,0),point+Vector2(0,1)],STONE)
	b.draw_line(point+Vector2(-size+3,-size*0.5),point+Vector2(size-3,-size+2),STONE_LIGHT,1)
	if snowy:
		_p(b,[point+Vector2(-size+2,-size*0.5),point+Vector2(size-3,-size+1),point+Vector2(size-1,-size*0.3),point+Vector2(0,-size*0.2)],Color("d5dfd3"))
		_r(b,point.x-2,point.y-size+2,4,1,Color("f0eddb"))


static func _branch(b: Object, from: Vector2, to: Vector2) -> void:
	b.draw_line(from,to,WOOD_DARK,4)
	b.draw_line(from+Vector2(0,-1),to+Vector2(0,-1),WOOD,2)
	var middle := from.lerp(to,0.55)
	b.draw_line(middle,middle+Vector2(4,-6),WOOD_DARK,2)
	b.draw_line(from+Vector2(1,-2),to+Vector2(-1,-2),WOOD_LIGHT,1)


static func _stump(b: Object, point: Vector2) -> void:
	_p(b,[point+Vector2(-8,1),point+Vector2(-5,-4),point+Vector2(-5,-10),point+Vector2(5,-10),point+Vector2(5,-3),point+Vector2(8,2)],WOOD_DARK)
	_r(b,point.x-4,point.y-9,8,10,WOOD)
	_r(b,point.x-4,point.y-10,8,3,WOOD_LIGHT)
	_r(b,point.x-2,point.y-9,3,1,WOOD_DARK)
	_r(b,point.x-2,point.y-5,1,6,WOOD_LIGHT)


static func _cattail(b: Object, point: Vector2, height: int) -> void:
	b.draw_line(point,point+Vector2(0,-height),Color("667448"),1)
	_r(b,point.x-1,point.y-height,3,5,Color("907649"))
	b.draw_line(point,point+Vector2(-4,-height+6),MOSS,1)
	b.draw_line(point+Vector2(1,0),point+Vector2(5,-height+8),Color("8b9b52"),1)


static func _barrel(b: Object, point: Vector2, scale: float = 1.0) -> void:
	var w := maxi(3,roundi(5*scale))
	var h := maxi(6,roundi(13*scale))
	_p(b,[point+Vector2(-w,0),point+Vector2(-w-1,-h+3),point+Vector2(-w+1,-h),point+Vector2(w-1,-h),point+Vector2(w+1,-h+3),point+Vector2(w,0)],OUTLINE)
	_r(b,point.x-w+1,point.y-h+2,w*2-2,h-2,WOOD)
	_r(b,point.x-w+2,point.y-h+3,2,h-3,WOOD_LIGHT)
	_r(b,point.x-w,point.y-h+4,w*2,2,IRON)
	_r(b,point.x-w,point.y-3,w*2,2,IRON)
	_r(b,point.x-w+1,point.y-h+1,w*2-2,2,WOOD_LIGHT)
	_r(b,point.x-2,point.y-h+2,3,1,WOOD_DARK)


static func _crate(b: Object, point: Vector2, size: int) -> void:
	var half := floori(size*0.5)
	_r(b,point.x-half,point.y-size,size,size,OUTLINE)
	_r(b,point.x-half+1,point.y-size+1,size-2,size-2,WOOD_DARK)
	_r(b,point.x-half+2,point.y-size+2,size-4,size-4,WOOD)
	b.draw_line(point+Vector2(-half+1,-size+1),point+Vector2(half-2,-2),WOOD_LIGHT,2)
	b.draw_line(point+Vector2(-half+1,-2),point+Vector2(half-2,-size+1),WOOD_LIGHT,1)
	_r(b,point.x-half+1,point.y-size+1,size-2,1,Color("d0b47a"))


static func _well(b: Object, point: Vector2, variant: int) -> void:
	_p(b,[point+Vector2(-12,-8),point+Vector2(-8,-13),point+Vector2(8,-13),point+Vector2(12,-8),point+Vector2(10,1),point+Vector2(-10,1)],OUTLINE)
	_r(b,point.x-10,point.y-8,20,8,STONE)
	_r(b,point.x-8,point.y-11,16,5,STONE_LIGHT)
	_r(b,point.x-6,point.y-10,12,4,Color("344a46"))
	_r(b,point.x-3,point.y-9,6,1,Color("799789"))
	for x: int in [-6,1,7]: _r(b,point.x+x,point.y-6,1,5,STONE_DARK)
	_r(b,point.x-10,point.y-4,20,1,STONE_DARK)
	if variant!=2:
		for x: int in [-9,8]: _r(b,point.x+x,point.y-25,2,18,WOOD_DARK);_r(b,point.x+x,point.y-24,1,15,WOOD_LIGHT)
		if variant==1:
			_p(b,[point+Vector2(-14,-22),point+Vector2(-2,-32),point+Vector2(13,-22)],OUTLINE)
			_p(b,[point+Vector2(-11,-23),point+Vector2(-2,-30),point+Vector2(10,-23)],Color("7d7651"))
			b.draw_line(point+Vector2(-8,-24),point+Vector2(8,-24),Color("a3a06c"),1)
		else: _r(b,point.x-11,point.y-25,24,3,WOOD)
		b.draw_line(point+Vector2(0,-24),point+Vector2(0,-10),Color("c3b789"),1)


static func _trough(b: Object, point: Vector2) -> void:
	_r(b,point.x-6,point.y-7,13,8,WOOD_DARK)
	_r(b,point.x-5,point.y-6,11,3,Color("6d8b83"))
	_r(b,point.x-5,point.y-3,11,3,WOOD)
	_r(b,point.x-5,point.y-3,11,1,WOOD_LIGHT)


static func _cloth(b: Object, point: Vector2, color: Color) -> void:
	_p(b,[point,point+Vector2(14,-1),point+Vector2(17,8),point+Vector2(12,10),point+Vector2(0,7)],color.darkened(0.2))
	b.draw_line(point+Vector2(1,1),point+Vector2(13,0),color.lightened(0.2),1)
	b.draw_line(point+Vector2(10,1),point+Vector2(12,8),color,2)


static func _fence(b: Object, from: Vector2, to: Vector2) -> void:
	for offset: int in [-8,-3]: b.draw_line(from+Vector2(0,offset),to+Vector2(0,offset),WOOD_DARK,3);b.draw_line(from+Vector2(0,offset-1),to+Vector2(0,offset-1),WOOD_LIGHT,1)
	for point: Vector2 in [from,to]: _r(b,point.x-1,point.y-13,3,15,WOOD_DARK);_r(b,point.x-1,point.y-13,1,13,WOOD_LIGHT)


static func _sign(b: Object, point: Vector2, variant: int) -> void:
	_r(b,point.x-1,point.y-27,3,28,WOOD_DARK)
	_r(b,point.x-1,point.y-26,1,26,WOOD_LIGHT)
	_p(b,[point+Vector2(-12,-25),point+Vector2(9,-25),point+Vector2(13,-22),point+Vector2(9,-19),point+Vector2(-12,-19)],OUTLINE)
	_r(b,point.x-10,point.y-24,19,4,WOOD)
	_r(b,point.x-9,point.y-24,13,1,WOOD_LIGHT)
	if variant==0:
		_p(b,[point+Vector2(-12,-14),point+Vector2(-8,-17),point+Vector2(11,-17),point+Vector2(11,-11),point+Vector2(-8,-11)],WOOD_DARK)
		_r(b,point.x-7,point.y-16,17,3,WOOD_LIGHT)
	elif variant==1: _stone(b,point+Vector2(0,1),7)
	else:
		b.draw_line(point+Vector2(1,-26),point+Vector2(10,-27),WOOD_DARK,2)
		_r(b,point.x+9,point.y-26,4,7,OUTLINE)
		_r(b,point.x+10,point.y-25,2,4,Color("c2ab71"))


static func _wheel(b: Object, point: Vector2, size: int) -> void:
	b.draw_circle(point,size,OUTLINE)
	b.draw_circle(point,size-2,WOOD)
	b.draw_circle(point,maxi(size-4,1),Color("4b5c46"))
	b.draw_line(point+Vector2(-size+1,0),point+Vector2(size-1,0),WOOD_LIGHT,1)
	b.draw_line(point+Vector2(0,-size+1),point+Vector2(0,size-1),WOOD_LIGHT,1)
	_r(b,point.x-1,point.y-1,3,3,IRON)


static func _cart(b: Object, point: Vector2, variant: int) -> void:
	var width := 22 if variant!=2 else 17
	b.draw_line(point+Vector2(5,-2),point+Vector2(22,5),WOOD_DARK,3)
	_wheel(b,point+Vector2(-7,1),5)
	_wheel(b,point+Vector2(8,4),5)
	_r(b,point.x-12,point.y-14,width,12,OUTLINE)
	_r(b,point.x-11,point.y-13,width-2,9,WOOD)
	for y: int in [-10,-6]: _r(b,point.x-11,point.y+y,width-2,1,WOOD_DARK)
	_r(b,point.x-11,point.y-13,width-2,1,WOOD_LIGHT)
	if variant==1: _cloth(b,point+Vector2(-11,-19),Color("8c967b"))
	elif variant==0: _crate(b,point+Vector2(-3,-9),8)
	else: _branch(b,point+Vector2(-10,-17),point+Vector2(10,-9))


static func _pot(b: Object, point: Vector2, size: int) -> void:
	_p(b,[point+Vector2(-size,0),point+Vector2(-size,-size),point+Vector2(-2,-size-4),point+Vector2(3,-size-4),point+Vector2(size,-size),point+Vector2(size,0)],OUTLINE)
	_r(b,point.x-size+1,point.y-size,size*2-2,size,Color("a07e57"))
	_r(b,point.x-size+2,point.y-size+1,2,maxi(size-2,1),Color("c7a476"))
	_r(b,point.x-2,point.y-size-3,5,2,WOOD_DARK)


static func _roll(b: Object, point: Vector2, color: Color) -> void:
	_r(b,point.x-8,point.y-6,17,7,OUTLINE)
	_r(b,point.x-7,point.y-5,15,5,color)
	_r(b,point.x-6,point.y-5,12,1,color.lightened(0.2))
	for x: int in [-3,4]: _r(b,point.x+x,point.y-5,1,5,WOOD_LIGHT)


static func _tent(b: Object, point: Vector2) -> void:
	_p(b,[point+Vector2(-14,0),point+Vector2(-2,-20),point+Vector2(12,-4),point+Vector2(16,1)],OUTLINE)
	_p(b,[point+Vector2(-11,-1),point+Vector2(-2,-18),point+Vector2(6,-3)],Color("9c9a73"))
	_p(b,[point+Vector2(-2,-18),point+Vector2(11,-4),point+Vector2(14,0),point+Vector2(6,-3)],Color("727b5e"))
	_p(b,[point+Vector2(-5,0),point+Vector2(-1,-10),point+Vector2(3,0)],Color("424d3b"))
	b.draw_line(point+Vector2(-2,-18),point+Vector2(14,0),Color("c0b68a"),1)


static func _pillar(b: Object, point: Vector2, height: int) -> void:
	_r(b,point.x-7,point.y-4,14,5,OUTLINE)
	_r(b,point.x-5,point.y-height,10,height-2,STONE_DARK)
	_r(b,point.x-4,point.y-height+1,6,height-3,STONE)
	_r(b,point.x-4,point.y-height+1,2,height-4,STONE_LIGHT)
	_r(b,point.x-6,point.y-height-2,12,4,STONE_LIGHT)
	_r(b,point.x-5,point.y-3,10,3,STONE)
	b.draw_line(point+Vector2(1,-height+7),point+Vector2(-1,-height+11),STONE_DARK,1)


static func _fallen_column(b: Object, point: Vector2) -> void:
	_p(b,[point+Vector2(-12,-5),point+Vector2(9,-12),point+Vector2(13,-4),point+Vector2(-8,4)],OUTLINE)
	_p(b,[point+Vector2(-10,-5),point+Vector2(8,-10),point+Vector2(11,-4),point+Vector2(-8,2)],STONE)
	b.draw_line(point+Vector2(-10,-5),point+Vector2(8,-10),STONE_LIGHT,2)
	for x: int in [-4,4]: b.draw_line(point+Vector2(x,-7),point+Vector2(x+2,0),STONE_DARK,1)


static func _wall(b: Object, point: Vector2, width: int) -> void:
	_r(b,point.x-width*0.5,point.y-10,width,11,STONE_DARK)
	_r(b,point.x-width*0.5+1,point.y-9,width-2,9,STONE)
	_r(b,point.x-width*0.5,point.y-10,width,2,STONE_LIGHT)
	_r(b,point.x-width*0.5+1,point.y-4,width-2,1,STONE_DARK)
	_r(b,point.x+1,point.y-8,1,4,STONE_DARK)


static func _grave(b: Object, point: Vector2, height: int) -> void:
	_p(b,[point+Vector2(-7,1),point+Vector2(-6,-height+3),point+Vector2(-3,-height),point+Vector2(4,-height),point+Vector2(7,-height+4),point+Vector2(6,1)],OUTLINE)
	_r(b,point.x-5,point.y-height+4,10,height-4,STONE_DARK)
	_r(b,point.x-4,point.y-height+3,7,height-4,STONE)
	_r(b,point.x-4,point.y-height+3,2,height-5,STONE_LIGHT)
	_r(b,point.x-1,point.y-height+7,4,1,STONE_DARK)
	_r(b,point.x-1,point.y-height+10,3,1,STONE_DARK)
	_moss(b,point+Vector2(0,2))


static func _bones(b: Object, point: Vector2) -> void:
	var bone := Color("c2bd9a")
	b.draw_line(point+Vector2(-7,-2),point+Vector2(5,1),bone,2)
	for offset: Vector2 in [Vector2(-7,-3),Vector2(-7,-1),Vector2(5,0),Vector2(5,2)]: _r(b,point.x+offset.x,point.y+offset.y,2,2,bone)
	_r(b,point.x+5,point.y-6,5,4,bone)
	_r(b,point.x+6,point.y-5,1,1,STONE_DARK)
	_r(b,point.x+8,point.y-5,1,1,STONE_DARK)


static func _sarcophagus(b: Object, point: Vector2) -> void:
	_p(b,[point+Vector2(-16,-7),point+Vector2(-11,-13),point+Vector2(13,-8),point+Vector2(15,1),point+Vector2(-13,2)],OUTLINE)
	_p(b,[point+Vector2(-14,-7),point+Vector2(-10,-11),point+Vector2(11,-7),point+Vector2(12,-2),point+Vector2(-11,-1)],STONE)
	b.draw_line(point+Vector2(-11,-10),point+Vector2(10,-6),STONE_LIGHT,1)
	b.draw_line(point+Vector2(-3,-8),point+Vector2(-1,-3),STONE_DARK,1)


static func _mushroom(b: Object, point: Vector2, color: Color, size: int) -> void:
	_r(b,point.x-1,point.y-size,3,size+1,Color("bdb89b"))
	_p(b,[point+Vector2(-size,-size+1),point+Vector2(-size+2,-size*2),point+Vector2(size-2,-size*2),point+Vector2(size,-size+1)],OUTLINE)
	_p(b,[point+Vector2(-size+1,-size),point+Vector2(-size+3,-size*2+1),point+Vector2(size-3,-size*2+1),point+Vector2(size-1,-size)],color)
	_r(b,point.x-size+3,point.y-size*2+2,maxi(size-3,1),1,color.lightened(0.25))
	_r(b,point.x+1,point.y-size*2+3,1,1,Color("d8cbbb"))


static func _crystal(b: Object, point: Vector2, height: int) -> void:
	_p(b,[point+Vector2(-5,0),point+Vector2(-5,-height+5),point+Vector2(0,-height),point+Vector2(6,-height+6),point+Vector2(4,1)],OUTLINE)
	_p(b,[point+Vector2(-3,-1),point+Vector2(-3,-height+5),point+Vector2(0,-height+2),point+Vector2(1,-2)],Color("9699b7"))
	_p(b,[point+Vector2(0,-height+2),point+Vector2(4,-height+6),point+Vector2(3,-1),point+Vector2(1,-2)],Color("646e8e"))
	b.draw_line(point+Vector2(-2,-height+5),point+Vector2(-2,-4),Color("c0c5cb"),1)


static func _snow(b: Object, point: Vector2) -> void:
	_r(b,point.x-7,point.y,14,2,Color("b7c8bd"))
	_r(b,point.x-5,point.y-1,10,2,Color("d5dfd3"))
	_r(b,point.x-2,point.y-2,4,1,Color("eeeddb"))


static func _pipe(b: Object, point: Vector2, width: int) -> void:
	_r(b,point.x-width*0.5,point.y-5,width,7,OUTLINE)
	_r(b,point.x-width*0.5+1,point.y-4,width-2,4,IRON)
	_r(b,point.x-width*0.5+1,point.y-4,width-2,1,IRON_LIGHT)
	_r(b,point.x+width*0.5-3,point.y-6,3,9,IRON)
	_r(b,point.x+width*0.5-2,point.y-4,1,4,OUTLINE)


static func _metal_plate(b: Object, point: Vector2, width: int) -> void:
	_p(b,[point+Vector2(-width*0.5,-6),point+Vector2(width*0.5-3,-8),point+Vector2(width*0.5,0),point+Vector2(-width*0.5+2,2)],OUTLINE)
	_p(b,[point+Vector2(-width*0.5+2,-5),point+Vector2(width*0.5-4,-6),point+Vector2(width*0.5-2,-1),point+Vector2(-width*0.5+3,0)],IRON)
	b.draw_line(point+Vector2(-width*0.5+2,-5),point+Vector2(width*0.5-4,-6),IRON_LIGHT,1)
	_r(b,point.x-2,point.y-3,2,1,Color("9b7b52"))


static func _bolt(b: Object, point: Vector2) -> void:
	_r(b,point.x-2,point.y-3,5,4,OUTLINE)
	_r(b,point.x-1,point.y-2,3,2,IRON_LIGHT)
	_r(b,point.x,point.y-1,1,1,IRON)
