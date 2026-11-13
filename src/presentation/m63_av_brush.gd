extends RefCounted
## Cell-filled faction ink. One cached stair-step contour per connected shape,
## not one display polygon with merely rounded vertices. No game state.
const MAX_CELL_SHAPES := 192
const MAX_SHAPE_CELLS := 8192
static var _cell_shapes:Dictionary={}
static var _cell_order:Array=[]

static func poly(ctx:Dictionary,center:Vector2,shape:Array,scale:float,color:Color,angle:float=0.0)->void:
	if int(ctx.get("count",0))>=int(ctx.get("draw_limit",0)) or color.a<=0.01 or not center.is_finite() or not is_finite(scale) or scale<=0:return
	var quantum:=maxf(1.0,float(ctx.get("quantum",1.0)))
	var anchor:Vector2=(center/quantum).round()*quantum
	var points:=PackedVector2Array()
	for vertex:Vector2 in shape:
		var at:Vector2=(vertex.rotated(angle)*scale/quantum).round()
		if not at.is_finite():return
		if points.is_empty() or points[-1]!=at:points.append(at)
	if points.size()>1 and points[0]==points[-1]:points.remove_at(points.size()-1)
	if points.size()<3 or Geometry2D.triangulate_polygon(points).is_empty():return
	var local_origin:=points[0]
	for i:int in range(points.size()):points[i]-=local_origin
	anchor+=local_origin*quantum
	# Local integer coordinates make translation free and cache keys bounded.
	# The cache owns geometry only: alpha/palette, commands and Canvas are not
	# retained, so an old side/skill never contaminates a later draw.
	var key:=str(points)
	var contours:Array
	if _cell_shapes.has(key):contours=_cell_shapes[key]
	else:
		contours=_raster_contours(points)
		while _cell_order.size()>=MAX_CELL_SHAPES:_cell_shapes.erase(_cell_order.pop_front())
		_cell_shapes[key]=contours;_cell_order.append(key)
	for local:PackedVector2Array in contours:
		if int(ctx.get("count",0))>=int(ctx.get("draw_limit",0)):break
		var display:=PackedVector2Array()
		for at:Vector2 in local:display.append(anchor+at*quantum)
		if ctx.has("commands"):ctx.commands.append({"points":display,"color":color})
		else:ctx.canvas.draw_colored_polygon(display,color)
		ctx.count=int(ctx.get("count",0))+1

static func _raster_contours(points:PackedVector2Array)->Array:
	var low:=points[0];var high:=points[0]
	for p:Vector2 in points:low=low.min(p);high=high.max(p)
	var bounds:=Rect2i(Vector2i(low.floor()),Vector2i((high-low).ceil())+Vector2i.ONE)
	# Broad distant effects may need a larger cell, never an unbounded bitmap
	# or a silent return to smooth vector ink. Preserve their full envelope.
	if bounds.size.x*bounds.size.y>MAX_SHAPE_CELLS:
		var stride:=ceili(sqrt(float(bounds.size.x*bounds.size.y)/MAX_SHAPE_CELLS))+1
		var coarse:=PackedVector2Array()
		for p:Vector2 in points:coarse.append((p/stride).round())
		var reduced:=_raster_contours(coarse)
		var expanded:Array=[]
		for outline:PackedVector2Array in reduced:
			var scaled:=PackedVector2Array()
			for p:Vector2 in outline:scaled.append(p*stride)
			expanded.append(scaled)
		return expanded
	var cells:Dictionary={}
	for y:int in range(bounds.position.y,bounds.end.y):
		for x:int in range(bounds.position.x,bounds.end.x):
			if Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),points):cells[Vector2i(x,y)]=true
	var edges:Dictionary={}
	for p:Vector2i in cells:
		if not cells.has(p+Vector2i.UP):_edge(edges,p,p+Vector2i.RIGHT)
		if not cells.has(p+Vector2i.RIGHT):_edge(edges,p+Vector2i.RIGHT,p+Vector2i.ONE)
		if not cells.has(p+Vector2i.DOWN):_edge(edges,p+Vector2i.ONE,p+Vector2i.DOWN)
		if not cells.has(p+Vector2i.LEFT):_edge(edges,p+Vector2i.DOWN,p)
	var result:Array=[]
	while not edges.is_empty():
		var first:Vector2i=edges.keys()[0]
		var cursor:=first;var prior:=Vector2i.RIGHT;var loop:Array=[]
		for unused:int in range(MAX_SHAPE_CELLS*4):
			loop.append(cursor)
			if not edges.has(cursor):break
			var options:Array=edges[cursor]
			var selected:=0;var best:=-999
			for i:int in range(options.size()):
				var direction:Vector2i=options[i]-cursor
				var turn:=prior.x*direction.y-prior.y*direction.x
				var score:=3 if turn>0 else 2 if prior.x*direction.x+prior.y*direction.y>0 else 1
				if score>best:best=score;selected=i
			var next:Vector2i=options[selected]
			options.remove_at(selected)
			if options.is_empty():edges.erase(cursor)
			prior=next-cursor;cursor=next
			if cursor==first:break
		if cursor!=first or loop.size()<4:continue
		var outline:=PackedVector2Array()
		for i:int in range(loop.size()):
			var before:Vector2i=loop[i]-loop[posmod(i-1,loop.size())]
			var after:Vector2i=loop[(i+1)%loop.size()]-loop[i]
			if before!=after:outline.append(Vector2(loop[i]))
		if outline.size()>=4 and not Geometry2D.triangulate_polygon(outline).is_empty():result.append(outline)
	return result

static func _edge(edges:Dictionary,a:Vector2i,b:Vector2i)->void:
	if not edges.has(a):edges[a]=[]
	edges[a].append(b)

static func cell_cache_stats()->Dictionary:
	return {"entries":_cell_shapes.size(),"maximum":MAX_CELL_SHAPES,"cell_limit":MAX_SHAPE_CELLS}

static func stamp(ctx:Dictionary,center:Vector2,shape:Array,scale:float,palette:Array,angle:float=0.0,alpha:float=1.0)->void:
	if palette.size()<5:return
	poly(ctx,center,shape,scale,Color(str(palette[0]),alpha),angle)
	poly(ctx,center+Vector2(-1,-1)*scale,shape,scale*0.67,Color(str(palette[2]),alpha),angle)
	poly(ctx,center+Vector2(-1,-2)*scale,[Vector2(-1,-2),Vector2(2,-2),Vector2(2,1),Vector2(-1,1)],scale,Color(str(palette[4]),alpha*0.85),angle)

static func chip(ctx:Dictionary,center:Vector2,size:Vector2,color:Color)->void:
	poly(ctx,center,[Vector2(-size.x,-size.y),Vector2(size.x,-size.y),Vector2(size.x,size.y),Vector2(-size.x,size.y)],1.0,color)

static func streak(ctx:Dictionary,from:Vector2,to:Vector2,width:float,color:Color)->void:
	if not from.is_finite() or not to.is_finite() or width<=0:return
	var normal:=(to-from).normalized().orthogonal()*width*0.5
	poly(ctx,Vector2.ZERO,[from-normal,to-normal,to+normal,from+normal],1.0,color)
