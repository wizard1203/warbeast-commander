extends RefCounted
## Detached visual routing. These cells never enter navigation or collision.
const VERSION := "heroic-orthogonal-roads-m43-v1"
const CELL := 8
const STEP := 32
const MARGIN := 4
const MAX_CELLS := 32768
const MAX_OPEN := 131072


static func populate(plan: Dictionary, facts: Dictionary, resources: Array[Dictionary], villages: Array[Dictionary], profile: Dictionary = {}) -> void:
	var main_width := int(profile.get("main_width",64))
	var branch_width := int(profile.get("branch_width",40))
	var main := Router.new(facts.bounds,facts.terrain,main_width,rectangle_clear,profile)
	var branch := Router.new(facts.bounds,facts.terrain,branch_width,rectangle_clear,profile)
	var roots := {}
	var edges: Array[Dictionary] = []
	for index: int in range(resources.size()):
		roots[resources[index].id] = resources[index].id
		for next: int in range(index+1,resources.size()):
			var a := resources[index]
			var b := resources[next]
			edges.append({"a":a,"b":b,"distance":a.position.distance_squared_to(b.position),"key":a.id+"|"+b.id})
	edges.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.key<b.key if a.distance==b.distance else a.distance<b.distance)
	for edge: Dictionary in edges:
		var a := _root(roots,edge.a.id)
		var b := _root(roots,edge.b.id)
		if a==b: continue
		var points := main.route(edge.a.position,edge.b.position)
		if points.is_empty(): continue
		roots[b] = a
		_append(plan,edge.a,edge.b,"RESOURCE",points,main_width)
	var components := {}
	for resource: Dictionary in resources: components[_root(roots,resource.id)] = true
	if components.size()>1: plan.failures.append({"kind":"RESOURCE","reason":"DISCONNECTED_RESOURCE_GRAPH","components":components.size()})
	for village: Dictionary in villages:
		var nearest := resources.duplicate()
		nearest.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
			var first: int = village.position.distance_squared_to(a.position)
			var second: int = village.position.distance_squared_to(b.position)
			return a.id<b.id if first==second else first<second)
		var connected := false
		for resource: Dictionary in nearest:
			var points := branch.route(village.position,resource.position)
			if points.is_empty(): continue
			_append(plan,village,resource,"VILLAGE",points,branch_width)
			connected = true
			break
		if not connected: plan.failures.append({"kind":"VILLAGE","from_id":village.id,"reason":"NO_REACHABLE_RESOURCE"})
	plan["road_mode"] = "ORTHOGONAL"
	plan["road_cell_size"] = int(profile.get("cell",CELL))
	plan["road_grid_origin"] = facts.bounds.position
	plan["road_router_version"] = VERSION
	plan["road_corridors"] = []
	for road: Dictionary in plan.roads:
		for index: int in range(1,road.points.size()):
			plan.road_corridors.append(corridor(road.points[index-1],road.points[index],road.width))
	plan["road_router_stats"] = {"main_cells":main.cells.size(),"branch_cells":branch.cells.size(),"max_grid_cells":MAX_CELLS,"searches":main.searches+branch.searches,"diagonal_fallbacks":0}


static func _root(roots: Dictionary,id: String) -> String:
	var value := id
	for _index: int in range(roots.size()):
		if roots[value]==value: return value
		value = roots[value]
	return value


static func _append(plan: Dictionary,a: Dictionary,b: Dictionary,kind: String,points: Array[Vector2i],width: int) -> void:
	plan.roads.append({"id":kind.to_lower()+":"+a.id+":"+b.id,"from_id":a.id,"to_id":b.id,"kind":kind,"points":points,"width":width,"material":"DIRT","from_site":a.position,"to_site":b.position})


static func corridor(a: Vector2i,b: Vector2i,width: int) -> Rect2i:
	var half := width/2
	var top := Vector2i(mini(a.x,b.x)-half,mini(a.y,b.y)-half)
	return Rect2i(top,Vector2i(absi(a.x-b.x)+width,absi(a.y-b.y)+width))


static func rectangle_clear(rect: Rect2i,bounds: Rect2i,obstacles: Array,margin: int=0) -> bool:
	var shape := Rect2(rect).grow(margin)
	if not Rect2(bounds).encloses(shape): return false
	for obstacle: Dictionary in obstacles:
		if not bool(obstacle.get("blocks_ground",true)): continue
		var point := Vector2(obstacle.position)
		var nearest := point.clamp(shape.position,shape.end)
		if point.distance_squared_to(nearest)<=pow(float(obstacle.get("radius",0)),2): return false
	return true


class Router:
	extends RefCounted
	var bounds: Rect2i
	var obstacles: Array
	var width: int
	var columns: int
	var rows: int
	var phase: int
	var cells := {}
	var searches := 0
	var rectangle_validator: Callable
	var grid_cell := CELL
	var grid_step := STEP
	var tile_center := false

	func _init(area: Rect2i,terrain: Array,diameter: int,validator: Callable,profile: Dictionary = {}) -> void:
		bounds = area
		obstacles = terrain
		width = diameter
		rectangle_validator = validator
		grid_cell = int(profile.get("cell",CELL))
		grid_step = int(profile.get("step",STEP))
		tile_center = bool(profile.get("tile_center",false))
		phase = posmod(width/2,grid_cell)
		columns = ceili(float(bounds.size.x)/grid_step)
		rows = ceili(float(bounds.size.y)/grid_step)

	func _snap(point: Vector2i) -> Vector2i:
		var offset := Vector2i.ONE*phase
		return bounds.position+offset+Vector2i((Vector2(point-bounds.position-offset)/grid_cell).round())*grid_cell

	func _clear(a: Vector2i,b: Vector2i) -> bool:
		var rect := Rect2i(Vector2i(mini(a.x,b.x)-width/2,mini(a.y,b.y)-width/2),Vector2i(absi(a.x-b.x)+width,absi(a.y-b.y)+width))
		return (a.x==b.x or a.y==b.y) and bool(rectangle_validator.call(rect,bounds,obstacles,MARGIN))

	func _elbow(a: Vector2i,b: Vector2i) -> Array[Vector2i]:
		if a==b: return [a] if _clear(a,b) else []
		if _clear(a,b): return [a,b]
		for joint: Vector2i in [Vector2i(b.x,a.y),Vector2i(a.x,b.y)]:
			if _clear(a,joint) and _clear(joint,b): return [a,joint,b]
		return []

	func route(start_site: Vector2i,target_site: Vector2i) -> Array[Vector2i]:
		searches += 1
		var start := _snap(start_site)
		var target := _snap(target_site)
		var direct := _elbow(start,target)
		if not direct.is_empty(): return direct
		if columns*rows>MAX_CELLS: return []
		var starts := _anchors(start)
		var targets := _anchors(target)
		if starts.is_empty() or targets.is_empty(): return []
		var costs := PackedInt32Array()
		costs.resize(columns*rows); costs.fill(2147483647)
		var previous := PackedInt32Array()
		previous.resize(columns*rows); previous.fill(-2)
		var closed := PackedByteArray()
		closed.resize(columns*rows)
		var heap: Array[Dictionary] = []
		for cell: int in starts:
			costs[cell] = _distance(start,_point(cell))
			previous[cell] = -1
			_push(heap,{"cell":cell,"g":costs[cell],"f":costs[cell]+_distance(_point(cell),target)})
		var found := -1
		for _iteration: int in range(MAX_OPEN):
			if heap.is_empty() or heap.size()>MAX_OPEN: break
			var entry := _pop(heap)
			var current: int = entry.cell
			if closed[current] or int(entry.g)!=costs[current]: continue
			closed[current] = 1
			if targets.has(current): found = current; break
			var grid := Vector2i(current%columns,current/columns)
			for delta: Vector2i in [Vector2i.UP,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.DOWN]:
				var next_grid := grid+delta
				if next_grid.x<0 or next_grid.y<0 or next_grid.x>=columns or next_grid.y>=rows: continue
				var next := next_grid.y*columns+next_grid.x
				if closed[next] or not _legal(next) or not _clear(_point(current),_point(next)): continue
				var cost := costs[current]+grid_step
				if cost>=costs[next]: continue
				costs[next] = cost
				previous[next] = current
				_push(heap,{"cell":next,"g":cost,"f":cost+_distance(_point(next),target)})
		if found<0: return []
		var reverse: Array[Vector2i] = []
		var cursor := found
		for _index: int in range(MAX_CELLS):
			if cursor<0: break
			reverse.append(_point(cursor))
			cursor = previous[cursor]
		reverse.reverse()
		var path := _elbow(start,reverse[0])
		path.append_array(reverse.slice(1))
		path.append_array(_elbow(reverse[-1],target).slice(1))
		var result: Array[Vector2i] = []
		for point: Vector2i in path:
			if not result.is_empty() and point==result[-1]: continue
			if result.size()>1 and ((point.x==result[-1].x and point.x==result[-2].x) or (point.y==result[-1].y and point.y==result[-2].y)):
				result[-1] = point
			else: result.append(point)
		return result

	func _anchors(point: Vector2i) -> Dictionary:
		var result := {}
		var center := Vector2i((Vector2(point-bounds.position)/grid_step).floor())
		for y: int in range(center.y-2,center.y+3):
			for x: int in range(center.x-2,center.x+3):
				if x<0 or y<0 or x>=columns or y>=rows: continue
				var cell := y*columns+x
				if _legal(cell) and not _elbow(point,_point(cell)).is_empty(): result[cell] = true
		return result

	func _point(cell: int) -> Vector2i:
		var center := 0 if tile_center else grid_step/2
		return bounds.position+Vector2i((cell%columns)*grid_step+center+phase,(cell/columns)*grid_step+center+phase)

	func _legal(cell: int) -> bool:
		if not cells.has(cell): cells[cell] = _clear(_point(cell),_point(cell))
		return cells[cell]

	func _distance(a: Vector2i,b: Vector2i) -> int: return absi(a.x-b.x)+absi(a.y-b.y)
	func _less(a: Dictionary,b: Dictionary) -> bool: return int(a.cell)<int(b.cell) if a.f==b.f else a.f<b.f

	func _push(heap: Array[Dictionary],entry: Dictionary) -> void:
		heap.append(entry)
		var index := heap.size()-1
		while index>0:
			var parent := (index-1)/2
			if not _less(heap[index],heap[parent]): break
			var item := heap[parent]; heap[parent]=heap[index]; heap[index]=item
			index = parent

	func _pop(heap: Array[Dictionary]) -> Dictionary:
		var result := heap[0]
		var tail: Dictionary = heap.pop_back()
		if heap.is_empty(): return result
		heap[0] = tail
		var index := 0
		while index*2+1<heap.size():
			var child := index*2+1
			if child+1<heap.size() and _less(heap[child+1],heap[child]): child+=1
			if not _less(heap[child],heap[index]): break
			var item := heap[index]; heap[index]=heap[child]; heap[child]=item
			index = child
		return result
