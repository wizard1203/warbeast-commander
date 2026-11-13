extends RefCounted
## Map authoring only. A bounded static lattice protects potential full-build
## streets; it never moves soldiers or replaces Combat's actual navigation.
const Balance = preload("res://src/simulation/strategic_balance_catalog.gd")
const VERSION := "outposts-authored-map-v3/r2-mainland"
const CELL := 32
const CLEARANCE := 73 # 96px road half-diagonal + 4px, rounded upward.
const PORT_RADIUS := 148 # Branch lattice shift stays within capture radius180.
const MAX_CELLS := 32768
const GROUP_KINDS := ["TREE","MOUNTAIN","GLACIER","LAVA"]
const LARGE_GROUPS := [
	[Vector2i(1499,3019),Vector2i(1600,3040),Vector2i(1701,3070)],
	[Vector2i(2848,960),Vector2i(2944,928),Vector2i(3031,873)],
	[Vector2i(4590,1737),Vector2i(4672,1792),Vector2i(4773,1826)],
	[Vector2i(2850,3358),Vector2i(2944,3328),Vector2i(3026,3273)],
]
const SMALL_GROUPS := [
	[Vector2i(1115,2155),Vector2i(1216,2176),Vector2i(1317,2206)],
	[Vector2i(2176,288),Vector2i(2272,256),Vector2i(2359,201)],
	[Vector2i(3246,1257),Vector2i(3328,1312),Vector2i(3429,1346)],
	[Vector2i(2082,2302),Vector2i(2176,2272),Vector2i(2258,2217)],
]

static func build(bounds: Rect2i, sites: Array, sources: Array, homes: Array, slots: Array) -> Dictionary:
	var failures: Array[String]=[]
	var large:=bounds.size.x>5000
	var terrain: Array[Dictionary]=[]
	var groups: Array=LARGE_GROUPS if large else SMALL_GROUPS
	var summary: Array[Dictionary]=[]
	for index: int in range(groups.size()):
		var kind:=str(GROUP_KINDS[index])
		var cluster:="v3-"+kind.to_lower()
		for member: int in range(3):
			terrain.append({"id":"terrain:%s:%02d"%[cluster,member],"kind":kind,"position":bounds.position+Vector2i(groups[index][member]),"radius":96,"blocks_ground":true,"cluster_id":cluster,"cluster_index":member,"cluster_kind":kind,"cluster_version":VERSION})
		summary.append({"id":cluster,"kind":kind,"members":3,"radius":96})
	var lake:=Vector2i(2620,2220) if large else Vector2i(1860,1660)
	terrain.append({"id":"terrain:v3-lake","kind":"LAKE","position":bounds.position+lake,"radius":155,"blocks_ground":true})
	for prop: Dictionary in terrain:
		_check_prop(prop,bounds,sites,sources,homes,slots,failures)
	if not failures.is_empty():return {"accepted":false,"failures":failures}
	var obstacles: Array[Dictionary]=terrain.duplicate(true)
	for slot: Dictionary in slots:
		var radius:=0
		for kind: String in slot.get("allowed_building_types",[slot.building_type]):
			radius=maxi(radius,int(Balance.WORLD_BUILDINGS.get(kind,{}).get("radius",0)))
		if radius<=0:failures.append("missing physical slot radius: "+str(slot.id))
		obstacles.append({"position":slot.position,"radius":radius})
	for source: Dictionary in sources:obstacles.append({"position":source.position,"radius":int(source.get("radius",50))})
	if not failures.is_empty():return {"accepted":false,"failures":failures}
	var router:=StaticRoutes.new(bounds,obstacles)
	if router.grid.is_empty():return {"accepted":false,"failures":["static road lattice exceeds bounded cell budget"]}
	var root_cell:=router.mainland_root(Vector2i(bounds.get_center()))
	if root_cell<0:return {"accepted":false,"failures":["static road lattice contains no legal street"]}
	var connected:=router.tree(root_cell)
	var ports: Dictionary={}
	for site: Dictionary in sites:
		var port:=router.port(Vector2i(site.position),connected)
		if port<0:failures.append("full-build road cannot reach capture circle: "+str(site.id))
		else:ports[str(site.id)]=port
	if not failures.is_empty():return {"accepted":false,"failures":failures}
	var routes:=_roads(router,sites,ports,failures)
	return {"accepted":failures.is_empty(),"failures":failures,"terrain":terrain,"reserved_routes":routes,"physical_biomes":{"version":VERSION,"groups":summary,"static_blockers":terrain.size(),"maximum_static_blockers":24,"reserved_routes":routes.size(),"placement":"fixed-author-table-no-member-filter","route_cells":router.grid.size(),"route_clearance":CLEARANCE,"route_searches":router.searches,"potential_full_build_obstacles":obstacles.size(),"scope":"Static authoring with all potential slot footprints; actual engine paths, alpha, guards and births require independent qualification."}}

static func _check_prop(prop: Dictionary,bounds: Rect2i,sites: Array,sources: Array,homes: Array,slots: Array,failures: Array[String]) -> void:
	var point:=Vector2(prop.position)
	var radius:=int(prop.radius)
	if point.x-radius-18<bounds.position.x or point.y-radius-18<bounds.position.y or point.x+radius+18>bounds.end.x or point.y+radius+18>bounds.end.y:failures.append("terrain outside protected bounds: "+str(prop.id))
	for slot: Dictionary in slots:
		if point.distance_to(Vector2(slot.position))<radius+105:failures.append("terrain overlaps authored slot: "+str(prop.id)+" / "+str(slot.id))
	for source: Dictionary in sources:
		if point.distance_to(Vector2(source.position))<radius+80:failures.append("terrain overlaps source: "+str(prop.id)+" / "+str(source.id))
	for site: Dictionary in sites:
		if point.distance_to(Vector2(site.position))<radius+100:failures.append("terrain overlaps site: "+str(prop.id)+" / "+str(site.id))
	for home: Vector2i in homes:
		if point.distance_to(Vector2(home))<radius+420:failures.append("terrain overlaps initial settlement: "+str(prop.id))

static func _roads(router: StaticRoutes,sites: Array,ports: Dictionary,failures: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var resources: Array[Dictionary]=[]
	for site: Dictionary in sites:
		if site.kind=="RESOURCE":resources.append(site)
	var roots: Dictionary={}
	var edges: Array[Dictionary]=[]
	var chosen: Dictionary={}
	for i: int in range(resources.size()):
		roots[str(resources[i].id)]=str(resources[i].id)
		for j: int in range(i+1,resources.size()):
			var a: Dictionary=resources[i]
			var b: Dictionary=resources[j]
			edges.append({"a":a,"b":b,"distance":Vector2i(a.position).distance_squared_to(Vector2i(b.position)),"key":str(a.id)+"|"+str(b.id)})
	edges.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.key<b.key if a.distance==b.distance else a.distance<b.distance)
	for edge: Dictionary in edges:
		var first:=_root(roots,str(edge.a.id))
		var second:=_root(roots,str(edge.b.id))
		if first==second:continue
		_add_road(result,router,ports,edge.a,edge.b,"RESOURCE",96,failures)
		roots[second]=first
		chosen[str(edge.key)]=true
	# One bounded extra neighbour link creates an actual alternative, rather
	# than making every distant resource pair into a crossing spoke.
	for edge: Dictionary in edges:
		if chosen.has(str(edge.key)):continue
		_add_road(result,router,ports,edge.a,edge.b,"RESOURCE",96,failures)
		break
	for site: Dictionary in sites:
		if site.kind=="RESOURCE":continue
		var nearest:=resources.duplicate()
		nearest.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
			var da:=Vector2i(site.position).distance_squared_to(Vector2i(a.position))
			var db:=Vector2i(site.position).distance_squared_to(Vector2i(b.position))
			return str(a.id)<str(b.id) if da==db else da<db)
		var links:=2 if bool(site.get("rich_gold",false)) else 1
		for index: int in range(mini(links,nearest.size())):
			_add_road(result,router,ports,nearest[index],site,"VILLAGE" if site.kind=="VILLAGE" else "SATELLITE",64,failures)
	return result

static func _root(roots: Dictionary,id: String) -> String:
	var current:=id
	for index: int in range(roots.size()):
		if str(roots[current])==current:return current
		current=str(roots[current])
	return current

static func _add_road(result: Array[Dictionary],router: StaticRoutes,ports: Dictionary,a: Dictionary,b: Dictionary,kind: String,width: int,failures: Array[String]) -> void:
	var points:=router.route(int(ports[str(a.id)]),int(ports[str(b.id)]))
	if points.is_empty():
		failures.append("authored street route unavailable: "+str(a.id)+" / "+str(b.id))
		return
	if width==64:
		# Even-width roads are centered on tile boundaries. The 16px diagonal
		# shift + a64px corridor corner +4px stays inside73px planning clearance.
		for index: int in range(points.size()):points[index]-=Vector2i.ONE*16
	result.append({"id":"v3:"+kind.to_lower()+":"+str(a.id)+":"+str(b.id),"from_id":a.id,"to_id":b.id,"kind":kind,"points":points,"width":width,"material":"DIRT","from_site":a.position,"to_site":b.position,"planning_clearance":CLEARANCE})

class StaticRoutes:
	extends RefCounted
	var bounds: Rect2i
	var columns:=0
	var rows:=0
	var grid:=PackedByteArray()
	var searches:=0
	var _trees: Dictionary={}

	func _init(area: Rect2i,obstacles: Array) -> void:
		bounds=area
		columns=ceili(float(area.size.x)/CELL)
		rows=ceili(float(area.size.y)/CELL)
		if columns*rows>MAX_CELLS:return
		grid.resize(columns*rows)
		grid.fill(1)
		for cell: int in range(grid.size()):
			var p:=point(cell)
			if p.x-CLEARANCE<bounds.position.x or p.y-CLEARANCE<bounds.position.y or p.x+CLEARANCE>bounds.end.x or p.y+CLEARANCE>bounds.end.y:grid[cell]=0
		# Stamp each inflated local disk, not all obstacles for every map cell.
		for obstacle: Dictionary in obstacles:
			var center:=Vector2i(obstacle.position)
			var reach:=int(obstacle.radius)+CLEARANCE
			var lo:=Vector2i((Vector2(center-bounds.position-Vector2i.ONE*(reach+16))/CELL).floor())
			var hi:=Vector2i((Vector2(center-bounds.position+Vector2i.ONE*(reach+16))/CELL).ceil())
			for y: int in range(maxi(0,lo.y),mini(rows,hi.y+1)):
				for x: int in range(maxi(0,lo.x),mini(columns,hi.x+1)):
					var cell:=y*columns+x
					if point(cell).distance_squared_to(center)<reach*reach:grid[cell]=0

	func point(cell: int) -> Vector2i:
		return bounds.position+Vector2i(cell%columns,int(cell/columns))*CELL+Vector2i.ONE*16

	func nearest_clear(target: Vector2i) -> int:
		var best:=-1
		var distance:=9223372036854775807
		for cell: int in range(grid.size()):
			if grid[cell]==0:continue
			var next:=point(cell).distance_squared_to(target)
			if next<distance:best=cell;distance=next
		return best

	func mainland_root(target: Vector2i) -> int:
		# A legal cell near the center can be a tiny courtyard enclosed by
		# full-build footprints. Choose the largest street component, not that
		# accidental island. All objective ports must STILL belong to it below.
		# One bounded O(cells) pass at map creation, no extra per-tick routing.
		var seen:=PackedByteArray()
		seen.resize(grid.size())
		seen.fill(0)
		var queue:=PackedInt32Array()
		queue.resize(grid.size())
		var best:=-1
		var largest:=0
		var best_distance:=9223372036854775807
		for start:int in range(grid.size()):
			if grid[start]==0 or seen[start]!=0:continue
			var head:=0
			var tail:=1
			queue[0]=start
			seen[start]=1
			var nearest:=start
			var distance:=point(start).distance_squared_to(target)
			while head<tail:
				var current:=queue[head]
				head+=1
				var next_distance:=point(current).distance_squared_to(target)
				if next_distance<distance or next_distance==distance and current<nearest:
					nearest=current
					distance=next_distance
				var x:=current%columns
				for next:int in [current-columns,current-1 if x>0 else -1,current+1 if x<columns-1 else -1,current+columns]:
					if next<0 or next>=grid.size() or grid[next]==0 or seen[next]!=0:continue
					seen[next]=1
					queue[tail]=next
					tail+=1
			if tail>largest or tail==largest and (distance<best_distance or distance==best_distance and nearest<best):
				largest=tail
				best=nearest
				best_distance=distance
		return best

	func tree(start: int) -> PackedInt32Array:
		if _trees.has(start):return _trees[start]
		var previous:=PackedInt32Array()
		previous.resize(grid.size())
		previous.fill(-2)
		if start<0 or start>=grid.size() or grid[start]==0:return previous
		var queue:=PackedInt32Array()
		queue.resize(grid.size())
		queue[0]=start
		previous[start]=-1
		var head:=0
		var tail:=1
		while head<tail:
			var current:=queue[head]
			head+=1
			var x:=current%columns
			for next: int in [current-columns,current-1 if x>0 else -1,current+1 if x<columns-1 else -1,current+columns]:
				if next<0 or next>=grid.size() or grid[next]==0 or previous[next]!=-2:continue
				previous[next]=current
				queue[tail]=next
				tail+=1
		searches+=1
		_trees[start]=previous
		return previous

	func port(center: Vector2i,connected: PackedInt32Array) -> int:
		var desired:=center+Vector2i(0,120)
		var best:=-1
		var distance:=9223372036854775807
		var local:=center-bounds.position
		var lo:=Vector2i((Vector2(local-Vector2i.ONE*PORT_RADIUS)/CELL).floor())
		var hi:=Vector2i((Vector2(local+Vector2i.ONE*PORT_RADIUS)/CELL).ceil())
		for y: int in range(maxi(0,lo.y),mini(rows,hi.y+1)):
			for x: int in range(maxi(0,lo.x),mini(columns,hi.x+1)):
				var cell:=y*columns+x
				if connected[cell]==-2 or grid[cell]==0:continue
				var p:=point(cell)
				if p.distance_squared_to(center)>PORT_RADIUS*PORT_RADIUS:continue
				var next:=p.distance_squared_to(desired)
				if next<distance:best=cell;distance=next
		return best

	func route(start: int,target: int) -> Array[Vector2i]:
		var result: Array[Vector2i]=[]
		var previous:=tree(start)
		if target<0 or target>=grid.size() or previous[target]==-2:return result
		var reverse: Array[Vector2i]=[]
		var cursor:=target
		for index: int in range(grid.size()):
			if cursor<0:break
			reverse.append(point(cursor))
			cursor=previous[cursor]
		reverse.reverse()
		for p: Vector2i in reverse:
			if result.size()>1 and ((p.x==result[-1].x and p.x==result[-2].x) or (p.y==result[-1].y and p.y==result[-2].y)):result[-1]=p
			else:result.append(p)
		return result
