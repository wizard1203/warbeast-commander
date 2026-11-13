extends RefCounted
## Single-batch codec used by the optional source-verified production backend
## and independent native experiments. It does not discover or load libraries.
## Only immutable scalar packing crosses the bridge; unsupported inputs return
## empty so the complete original script resolver remains the fallback.
const STRIDE := 12
const MAX_ROWS := 8192
const LIMIT := 32768

static func _point(value: Variant) -> bool:
	return typeof(value)==TYPE_VECTOR2I and absi(value.x)<=LIMIT and absi(value.y)<=LIMIT

static func _inside(point: Vector2i,bounds: Rect2i,radius: int) -> bool:
	return point.x>=bounds.position.x+radius and point.x<=bounds.end.x-radius and point.y>=bounds.position.y+radius and point.y<=bounds.end.y-radius

static func try_with(bridge: RefCounted,bodies: Array[Dictionary],bounds: Rect2i,max_step: int) -> Dictionary:
	if bridge==null:return {}
	if bridge.has_method("solve_bodies"):
		# High-level bridge owns exactly the same strict row guard, Godot String
		# ordering, packing and detached map construction. Do not re-scan every
		# body in GDScript and erase the benefit of a single whole-array bridge.
		var direct: Variant=bridge.call("solve_bodies",bodies,bounds,max_step)
		if not direct is Dictionary or typeof(direct.get("accepted"))!=TYPE_BOOL or not bool(direct.accepted) or not direct.get("positions") is Dictionary:return {}
		if direct.positions.size()!=bodies.size():return {}
		return {"accepted":true,"positions":direct.positions}
	# Raw packed bridge is retained as an independent codec/reference lane.
	if not bridge.has_method("solve") or bodies.size()>MAX_ROWS or max_step<0 or max_step>64:return {}
	if not _point(bounds.position) or not _point(bounds.end) or bounds.size.x<=0 or bounds.size.y<=0:return {}
	var ordered:=bodies.duplicate(false)
	var seen: Dictionary={}
	for body: Dictionary in ordered:
		if typeof(body.get("id"))!=TYPE_STRING or seen.has(body.id):return {}
		seen[body.id]=true
		if not _point(body.get("position")) or not _point(body.get("desired")) or typeof(body.get("radius"))!=TYPE_INT or typeof(body.get("active"))!=TYPE_BOOL:return {}
		if body.has("static") and typeof(body.static)!=TYPE_BOOL:return {}
		if body.has("max_step") and typeof(body.max_step)!=TYPE_INT:return {}
		if body.has("steering_goal") and not _point(body.steering_goal):return {}
		if body.has("previous_position") and not _point(body.previous_position):return {}
		if typeof(body.get("movement_layer","GROUND"))!=TYPE_STRING or body.get("movement_layer","GROUND") not in ["GROUND","AIR"]:return {}
		var radius: int=body.radius
		if radius<0 or radius>512 or bounds.size.x<2*radius or bounds.size.y<2*radius:return {}
		if bool(body.active) and not bool(body.get("static",false)) and not _inside(body.position,bounds,radius):return {}
	# Godot's original String comparator owns ordering, including Unicode IDs.
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return str(a.id)<str(b.id))
	var words:=PackedInt32Array()
	words.resize(ordered.size()*STRIDE)
	for index: int in range(ordered.size()):
		var body: Dictionary=ordered[index]
		var old: Vector2i=body.position
		var desired: Vector2i=body.desired
		var goal: Vector2i=body.get("steering_goal",desired)
		var previous: Vector2i=body.get("previous_position",old)
		var at:=index*STRIDE
		words[at]=old.x;words[at+1]=old.y
		words[at+2]=desired.x;words[at+3]=desired.y
		words[at+4]=int(body.radius)
		words[at+5]=(1 if body.active else 0)|(2 if bool(body.get("static",false)) else 0)|(4 if body.has("steering_goal") else 0)
		words[at+6]=0 if body.get("movement_layer","GROUND")=="GROUND" else 1
		words[at+7]=mini(max_step,maxi(0,int(body.get("max_step",max_step))))
		words[at+8]=goal.x;words[at+9]=goal.y
		words[at+10]=previous.x;words[at+11]=previous.y
	var arena:=PackedInt32Array([bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y])
	var response: Variant=bridge.call("solve",words,arena,max_step)
	if typeof(response)!=TYPE_PACKED_INT32_ARRAY:return {}
	var positions: PackedInt32Array=response
	if positions.size()!=2+ordered.size()*2 or positions[0]!=0 or positions[1]!=ordered.size():return {}
	var result: Dictionary={}
	for index: int in range(ordered.size()):
		var body: Dictionary=ordered[index]
		var point:=Vector2i(positions[2+index*2],positions[3+index*2])
		if not _point(point):return {}
		var old: Vector2i=body.position
		var step:=mini(max_step,maxi(0,int(body.get("max_step",max_step))))
		if not bool(body.active) and point!=old:return {}
		if absi(point.x-old.x)>step or absi(point.y-old.y)>step:return {}
		if point!=old and not _inside(point,bounds,int(body.radius)):return {}
		result[body.id]=point
	return {"accepted":true,"positions":result}
