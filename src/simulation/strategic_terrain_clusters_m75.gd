extends RefCounted
## Cached map authoring only. Three overlapping circles are one real biome;
## decorative crowns never become per-tree navigation bodies.
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const VERSION := "physical-biome-clusters-m75-v1"
const KINDS := ["TREE","MOUNTAIN","GLACIER","LAVA"]
const MAX_STATIC_BLOCKERS := 24
const FORMS := [
	[Vector2i(-88,-18),Vector2i.ZERO,Vector2i(88,26)],
	[Vector2i(-84,28),Vector2i.ZERO,Vector2i(76,-48)],
	[Vector2i(-72,-48),Vector2i.ZERO,Vector2i(88,30)],
	[Vector2i(-82,26),Vector2i.ZERO,Vector2i(72,-48)],
]

static func populate(map_id: String,bounds: Rect2i,sites: Array,sources: Array,homes: Array,terrain: Array) -> Dictionary:
	var reserved := _routes(bounds,sites,sources,homes,terrain)
	var groups: Array[Dictionary] = []
	var blockers := terrain.filter(func(body: Dictionary)->bool:return bool(body.get("blocks_ground",false))).size()
	var candidates: Array[Vector2i] = []
	for y: int in range(bounds.position.y+160,bounds.end.y-159,96):
		for x: int in range(bounds.position.x+160,bounds.end.x-159,96): candidates.append(Vector2i(x,y))
	var key := int(map_id.sha256_text().substr(0,8).hex_to_int())
	for kind_index: int in range(KINDS.size()):
		var kind: String=KINDS[kind_index]
		var desired: Vector2 = Vector2(bounds.position)+Vector2(bounds.size)*[Vector2(0.27,0.66),Vector2(0.48,0.23),Vector2(0.78,0.45),Vector2(0.51,0.79)][kind_index]
		var ordered := candidates.duplicate()
		ordered.sort_custom(func(a: Vector2i,b: Vector2i)->bool:
			var first := Vector2(a).distance_squared_to(desired)
			var second := Vector2(b).distance_squared_to(desired)
			return a.y<b.y if first==second and a.x==b.x else a.x<b.x if first==second else first<second)
		var chosen: Array[Dictionary] = []
		for radius: int in [96,84,72,64]:
			for center: Vector2i in ordered:
				var members: Array[Dictionary] = []
				for member: int in range(3):
					var delta := Vector2i((Vector2(FORMS[kind_index][member])*float(radius)/84.0).round())
					if key%2==1: delta.x=-delta.x
					var point := center+delta
					members.append({"id":"terrain:m75_%s_%02d"%[kind.to_lower(),member],"kind":kind,"position":point,"radius":radius,"blocks_ground":true,"cluster_id":"m75-"+kind.to_lower(),"cluster_index":member,"cluster_kind":kind,"cluster_version":VERSION})
				if _clear(members,bounds,sites,sources,homes,terrain,reserved): chosen=members;break
			if not chosen.is_empty(): break
		assert(not chosen.is_empty(),"Physical biome needs a bounded safe placement: "+map_id+":"+kind)
		assert(blockers+chosen.size()<=MAX_STATIC_BLOCKERS,"Static terrain must leave navigation node budget for buildings")
		terrain.append_array(chosen)
		blockers+=chosen.size()
		groups.append({"id":"m75-"+kind.to_lower(),"kind":kind,"members":chosen.size(),"radius":int(chosen[0].radius) if not chosen.is_empty() else 0})
	return {"version":VERSION,"groups":groups,"static_blockers":blockers,"maximum_static_blockers":MAX_STATIC_BLOCKERS,"reserved_routes":reserved.size(),"placement":"bounded-deterministic-union"}

static func _clear(members: Array,bounds: Rect2i,sites: Array,sources: Array,homes: Array,terrain: Array,routes: Array) -> bool:
	for body: Dictionary in members:
		var point: Vector2i=body.position
		var radius := int(body.radius)
		if not Navigation.point_clear(point,radius+18,bounds,terrain): return false
		for home: Vector2i in homes:
			if Vector2(point).distance_squared_to(home)<pow(radius+420.0,2): return false
		for site: Dictionary in sites:
			if Vector2(point).distance_squared_to(site.position)<pow(radius+100.0,2): return false
		for source: Dictionary in sources:
			if Vector2(point).distance_squared_to(source.position)<pow(radius+84.0,2): return false
		for route: Dictionary in routes:
			var distance := Vector2(point).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(point),Vector2(route.a),Vector2(route.b)))
			if distance<float(radius)+float(route.radius)+10.0: return false
	return true

static func _routes(bounds: Rect2i,sites: Array,sources: Array,homes: Array,terrain: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if homes.is_empty(): return result
	# A connected radius50 backbone gives regular ground armies open passages.
	# Preserve each home's existing central-deposit approach too: adding visual
	# richness must not secretly move the fair scarce-resource contest.
	for site: Dictionary in sites:
		_add_route(result,homes[0],site.position,50,bounds,terrain)
		if site.get("resource","")=="ESSENCE":
			for home: Vector2i in homes.slice(1): _add_route(result,home,site.position,26,bounds,terrain)
	for home: Vector2i in homes.slice(1): _add_route(result,homes[0],home,50,bounds,terrain)
	var by_id := {}
	for site: Dictionary in sites: by_id[str(site.id)]=site.position
	for source: Dictionary in sources:
		if by_id.has(str(source.site_id)): _add_route(result,source.position,by_id[str(source.site_id)],20,bounds,terrain)
	return result

static func _add_route(result: Array,start: Vector2i,target: Vector2i,radius: int,bounds: Rect2i,terrain: Array) -> void:
	var path := Navigation.find_path(start,target,radius,bounds,terrain)
	if path.is_empty():
		radius=26
		path=Navigation.find_path(start,target,radius,bounds,terrain)
	assert(not path.is_empty(),"Authored strategic endpoints must be connected before adding biome clusters")
	var previous := start
	for point: Vector2i in path:
		result.append({"a":previous,"b":point,"radius":radius})
		previous=point
