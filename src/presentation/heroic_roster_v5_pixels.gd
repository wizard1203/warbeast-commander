extends RefCounted
## Original cell-painted primitives; authoring only, never combat state.
## A logical cell is 3 source pixels, not an antialiased geometric edge.
const SIZE := 192
const CELL := 3
static func rect(image:Image,x:int,y:int,w:int,h:int,tint:Color)->void:
	if w<=0 or h<=0:return
	var low:=Vector2i(roundi(float(x)/CELL)*CELL,roundi(float(y)/CELL)*CELL)
	var span:=Vector2i(ceili(float(w)/CELL)*CELL,ceili(float(h)/CELL)*CELL)
	var r:=Rect2i(low,span).intersection(Rect2i(3,3,186,186))
	if r.has_area():image.fill_rect(r,tint)
static func line(image:Image,a:Vector2,b:Vector2,tint:Color,width:int=1)->void:
	var first:Vector2=(a/CELL).round()*CELL
	var last:Vector2=(b/CELL).round()*CELL
	var steps:=maxi(1,ceili(first.distance_to(last)/CELL))
	var thickness:=maxi(CELL,ceili(float(width)/CELL)*CELL)
	for n:int in range(steps+1):
		var p:=Vector2i((first.lerp(last,float(n)/steps)/CELL).round())*CELL
		rect(image,p.x-thickness/2,p.y-thickness/2,thickness,thickness,tint)
static func poly(image:Image,vertices:Array,tint:Color)->void:
	var points:=PackedVector2Array(vertices)
	if points.size()<3:return
	var box:=Rect2(points[0],Vector2.ZERO)
	for v:Vector2 in points:box=box.expand(v)
	var bounds:=Rect2i(Vector2i(box.position.floor()),Vector2i(box.size.ceil())+Vector2i.ONE).intersection(Rect2i(2,2,188,188))
	for y:int in range(maxi(3,floori(float(bounds.position.y)/CELL)*CELL),bounds.end.y,CELL):
		for x:int in range(maxi(3,floori(float(bounds.position.x)/CELL)*CELL),bounds.end.x,CELL):
			if Geometry2D.is_point_in_polygon(Vector2(x+CELL*.5,y+CELL*.5),points):rect(image,x,y,CELL,CELL,tint)
static func ellipse(image:Image,center:Vector2,radii:Vector2,tint:Color,filled:bool=true,width:int=1)->void:
	if radii.x<=0 or radii.y<=0:return
	for y:int in range(maxi(3,floori((center.y-radii.y)/CELL)*CELL),mini(189,ceili(center.y+radii.y)+1),CELL):
		for x:int in range(maxi(3,floori((center.x-radii.x)/CELL)*CELL),mini(189,ceili(center.x+radii.x)+1),CELL):
			var p:=Vector2(x+CELL*.5,y+CELL*.5)-center
			var outer:=p.x*p.x/(radii.x*radii.x)+p.y*p.y/(radii.y*radii.y)
			var inner:=false
			if not filled and radii.x>width and radii.y>width:
				inner=p.x*p.x/pow(maxf(1,radii.x-maxi(CELL,width)),2)+p.y*p.y/pow(maxf(1,radii.y-maxi(CELL,width)),2)<1
			if outer<=1 and not inner:rect(image,x,y,CELL,CELL,tint)
static func color(row:Dictionary,index:int,alpha:float=1)->Color:
	var colors:Array=row.get("palette",["222331","56667b","99acaf","e5ce96","fff0c9"])
	var c:=Color(str(colors[posmod(index,colors.size())]));c.a=alpha
	return c
