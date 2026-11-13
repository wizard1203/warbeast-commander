extends RefCounted
## Integer, local raster brush for original sprite recipes. No scene, clock,
## renderer or authority access; shapes are clipped to the declared image.
const SIZE := Vector2i(128,112)
const FOOT := Vector2i(64,92)
var image: Image = Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
var commands := 0
var clipped := 0

func _init() -> void:
	image.fill(Color.TRANSPARENT)

func draw_rect(rect: Rect2,color: Color) -> void:
	commands += 1
	if not rect.position.is_finite() or not rect.size.is_finite(): return
	var start := Vector2i(roundi(rect.position.x),roundi(rect.position.y))+FOOT
	var extent := Vector2i(maxi(roundi(rect.size.x),0),maxi(roundi(rect.size.y),0))
	_fill(Rect2i(start,extent),color)

func draw_line(from: Vector2,to: Vector2,color: Color,width: float=1) -> void:
	commands += 1
	if not from.is_finite() or not to.is_finite() or not is_finite(width): return
	var a := Vector2i(roundi(from.x),roundi(from.y))+FOOT
	var b := Vector2i(roundi(to.x),roundi(to.y))+FOOT
	var dx := absi(b.x-a.x)
	var sx := 1 if a.x<b.x else -1
	var dy := -absi(b.y-a.y)
	var sy := 1 if a.y<b.y else -1
	var error := dx+dy
	var thickness := clampi(roundi(width),1,16)
	for index: int in range(512):
		_fill(Rect2i(a-Vector2i.ONE*floori(float(thickness)/2),Vector2i.ONE*thickness),color)
		if a==b: break
		var twice := error*2
		if twice>=dy:
			error+=dy
			a.x+=sx
		if twice<=dx:
			error+=dx
			a.y+=sy

func draw_colored_polygon(points: PackedVector2Array,color: Color) -> void:
	commands += 1
	if points.size()<3 or points.size()>64: return
	var polygon := PackedVector2Array()
	var low := SIZE.y
	var high := 0
	for point: Vector2 in points:
		if not point.is_finite(): return
		var next := point+Vector2(FOOT)
		polygon.append(next)
		low=mini(low,floori(next.y))
		high=maxi(high,ceili(next.y))
		if next.x<0 or next.x>SIZE.x or next.y<0 or next.y>SIZE.y: clipped+=1
	for y: int in range(maxi(low,0),mini(high,SIZE.y)):
		var row := float(y)+0.5
		var crossings: Array[float] = []
		for index: int in range(polygon.size()):
			var a: Vector2=polygon[index]
			var b: Vector2=polygon[(index+1)%polygon.size()]
			if (a.y<=row and b.y>row) or (b.y<=row and a.y>row): crossings.append(a.x+(row-a.y)*(b.x-a.x)/(b.y-a.y))
		crossings.sort()
		for index: int in range(0,crossings.size()-1,2):
			var left := ceili(crossings[index]-0.5)
			var right := ceili(crossings[index+1]-0.5)
			_fill(Rect2i(left,y,maxi(right-left,0),1),color)

func _fill(rect: Rect2i,color: Color) -> void:
	if rect.size.x<=0 or rect.size.y<=0: return
	var safe := rect.intersection(Rect2i(Vector2i.ZERO,SIZE))
	if safe!=rect: clipped+=1
	if safe.size.x>0 and safe.size.y>0: image.fill_rect(safe,color)
