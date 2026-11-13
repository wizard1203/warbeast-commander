extends "res://src/presentation/strategic_pixel_brush.gd"
## Pure raster composition, extending the existing shape-only brush with the
## two operations used by Heroic building recipes. No scene or art fallback.

func draw_texture_rect_region(texture: Texture2D, destination: Rect2, source: Rect2, modulation: Color = Color.WHITE, _transpose: bool = false, _clip_uv: bool = true) -> void:
	commands += 1
	if texture==null or not destination.position.is_finite() or not destination.size.is_finite(): return
	var extent:=Vector2i(maxi(roundi(destination.size.x),0),maxi(roundi(destination.size.y),0))
	if extent.x<=0 or extent.y<=0: return
	var original:=texture.get_image()
	if original==null or not Rect2i(Vector2i.ZERO,original.get_size()).encloses(Rect2i(source)): return
	var pixels:=original.get_region(Rect2i(source))
	pixels.convert(Image.FORMAT_RGBA8)
	if pixels.get_size()!=extent: pixels.resize(extent.x,extent.y,Image.INTERPOLATE_NEAREST)
	if modulation!=Color.WHITE:
		for y: int in range(pixels.get_height()):
			for x: int in range(pixels.get_width()): pixels.set_pixel(x,y,pixels.get_pixel(x,y)*modulation)
	var destination_position:=Vector2i(destination.position.round())+FOOT
	var placed:=Rect2i(destination_position,extent)
	if not Rect2i(Vector2i.ZERO,SIZE).encloses(placed): clipped+=1
	image.blend_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),destination_position)


func draw_circle(center: Vector2, radius: float, color: Color) -> void:
	commands += 1
	if not center.is_finite() or not is_finite(radius) or radius<=0: return
	var bounds:=Rect2i(Vector2i((center-Vector2.ONE*radius).floor())+FOOT,Vector2i.ONE*ceili(radius*2+1))
	var safe:=bounds.intersection(Rect2i(Vector2i.ZERO,SIZE))
	if safe!=bounds: clipped+=1
	for y: int in range(safe.position.y,safe.end.y):
		for x: int in range(safe.position.x,safe.end.x):
			if Vector2(x+0.5,y+0.5).distance_squared_to(center+Vector2(FOOT))<=radius*radius: image.set_pixel(x,y,color)
