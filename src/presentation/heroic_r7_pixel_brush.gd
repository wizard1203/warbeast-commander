extends RefCounted
## Tiny deterministic authoring brush. Used only while baking shared frames,
## never inside per-unit combat logic. Geometry fills whole 2px source cells.
const CELL := 2

static func rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	if w<=0 or h<=0:return
	var low:=Vector2i(roundi(float(x)/CELL)*CELL,roundi(float(y)/CELL)*CELL)
	var span:=Vector2i(ceili(float(w)/CELL)*CELL,ceili(float(h)/CELL)*CELL)
	var clipped := Rect2i(low,span).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	if clipped.has_area(): image.fill_rect(clipped,color)

static func line(image: Image, a: Vector2i, b: Vector2i, width: int, color: Color) -> void:
	var first:=Vector2i((Vector2(a)/CELL).round())
	var last:=Vector2i((Vector2(b)/CELL).round())
	var x := first.x
	var y := first.y
	var dx := absi(last.x-first.x)
	var dy := -absi(last.y-first.y)
	var sx := 1 if first.x<last.x else -1
	var sy := 1 if first.y<last.y else -1
	var error := dx+dy
	var r := maxi(CELL,ceili(float(width)/CELL)*CELL)
	for unused: int in range(dx-dy+2):
		rect(image,x*CELL-r/2,y*CELL-r/2,r,r,color)
		if x==last.x and y==last.y: break
		var twice := 2*error
		if twice>=dy: error+=dy; x+=sx
		if twice<=dx: error+=dx; y+=sy

static func polygon(image: Image, points: Array, color: Color) -> void:
	if points.size()<3: return
	var shape := PackedVector2Array()
	var low := Vector2(INF,INF)
	var high := Vector2(-INF,-INF)
	for point: Variant in points:
		var p := Vector2(point)
		shape.append(p)
		low=low.min(p); high=high.max(p)
	for y: int in range(maxi(0,floori(low.y/CELL)*CELL),mini(image.get_height(),ceili(high.y)+1),CELL):
		for x: int in range(maxi(0,floori(low.x/CELL)*CELL),mini(image.get_width(),ceili(high.x)+1),CELL):
			if Geometry2D.is_point_in_polygon(Vector2(x+CELL*.5,y+CELL*.5),shape): rect(image,x,y,CELL,CELL,color)

static func ellipse(image: Image, bounds: Rect2i, color: Color) -> void:
	if not bounds.has_area(): return
	var center := Vector2(bounds.position)+Vector2(bounds.size)*.5
	var radii := Vector2(bounds.size)*.5
	var clipped := bounds.intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	for y: int in range(floori(float(clipped.position.y)/CELL)*CELL,clipped.end.y,CELL):
		for x: int in range(floori(float(clipped.position.x)/CELL)*CELL,clipped.end.x,CELL):
			var p := (Vector2(x+CELL*.5,y+CELL*.5)-center)/radii
			if p.length_squared()<=1.0: rect(image,x,y,CELL,CELL,color)

static func stamp(image: Image, at: Vector2i, rows: Array, palette: Dictionary) -> void:
	for y: int in range(rows.size()):
		var row := str(rows[y])
		for x: int in range(row.length()):
			var symbol := row.substr(x,1)
			if palette.has(symbol): rect(image,at.x+x,at.y+y,1,1,palette[symbol])
