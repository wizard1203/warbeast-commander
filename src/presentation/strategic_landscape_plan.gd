extends RefCounted
## Pure, detached presentation planning. Roads use the real terrain circles,
## but never supply movement, collision, ownership or resource authority.
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const OrthogonalRoads = preload("res://src/presentation/heroic_orthogonal_roads.gd")
const RoadTiles = preload("res://src/presentation/heroic_road_tiles.gd")
const VERSION := "landscape-m26-v1"
const DECORATION_LIMIT := 168
const ROAD_MARGIN := 4
const MAIN_ROAD_WIDTH := 64
const BRANCH_ROAD_WIDTH := 40
const HOME_RADIUS := 500
const HOME_CORE := 180
const HOME_DECOR_PER_SIDE := 12
const HOME_DECOR_MINIMUM := 6
const HOME_DECOR_FOOTPRINT := 32
const STYLES := {
	"HUMAN":{"biome":"GRASSLAND", "road_material":"BRICK"},
	"UNDEAD":{"biome":"ASHLAND", "road_material":"STONE"},
	"MACHINE":{"biome":"INDUSTRIAL", "road_material":"SLAB"},
	"FOREST":{"biome":"WOODLAND", "road_material":"DIRT"},
	"HIGHLAND":{"biome":"SNOWFIELD", "road_material":"STONE"},
	"UNDERGROUND":{"biome":"FUNGAL", "road_material":"DIRT"},
}


static func signature(snapshot: Dictionary) -> String:
	var facts := _facts(snapshot)
	# Only arrays of canonical primitives cross the fingerprint seam. Live
	# owner/stock/tick and arbitrary dictionary insertion order cannot dirty it.
	var identity: Array = [VERSION, facts.seed, facts.map_id, facts.map_version,
		[facts.bounds.position.x, facts.bounds.position.y, facts.bounds.size.x, facts.bounds.size.y]]
	for category: String in ["sites", "sources", "terrain", "sides"]:
		var records: Array = []
		for item: Dictionary in facts[category]:
			if category == "sides": records.append([item.id, item.faction_id, item.position.x, item.position.y])
			else: records.append([item.id, item.kind, item.position.x, item.position.y, item.radius, item.get("blocks_ground", false)])
		identity.append(records)
	if not str(facts.get("route_layout_version","")).is_empty():
		identity.append(str(facts.route_layout_version))
		for route: Dictionary in facts.reserved_routes:identity.append([route.get("id",""),route.get("from_id",""),route.get("to_id",""),route.get("kind",""),route.get("width",0),route.get("points",[])])
	return var_to_str(identity).sha256_text()


static func build(snapshot: Dictionary, road_mode: String = "CONTINUOUS") -> Dictionary:
	var facts := _facts(snapshot)
	var plan := {"version":VERSION, "seed":facts.seed, "map_id":facts.map_id, "bounds":facts.bounds,
		"home_zones":[], "roads":[], "decorations":[], "home_decoration_summary":[], "failures":[]}
	if facts.bounds.size.x <= 0 or facts.bounds.size.y <= 0:
		plan.failures.append({"kind":"INPUT", "reason":"INVALID_BOUNDS"})
		return plan
	for side: Dictionary in facts.sides:
		var style: Dictionary = STYLES.get(side.faction_id, STYLES.HUMAN)
		plan.home_zones.append({"side_id":side.id, "position":side.position, "faction_id":side.faction_id,
			"radius":HOME_RADIUS, "biome":style.biome, "road_material":style.road_material})
	var resources: Array[Dictionary] = []
	var villages: Array[Dictionary] = []
	for site: Dictionary in facts.sites:
		if site.kind == "RESOURCE": resources.append(site)
		elif site.kind == "VILLAGE": villages.append(site)
	if resources.is_empty(): plan.failures.append({"kind":"RESOURCE", "reason":"MISSING_RESOURCE_SITES"})
	else:
		if not str(facts.get("route_layout_version","")).is_empty(): _reserved_roads(plan,facts)
		elif road_mode == "TILED": RoadTiles.populate(plan,facts,resources,villages)
		elif road_mode == "ORTHOGONAL": OrthogonalRoads.populate(plan,facts,resources,villages)
		else: _build_roads(plan, facts, resources, villages)
	var layout_identity := _layout_identity(facts)
	_build_home_decorations(plan, facts, layout_identity)
	_build_decorations(plan, facts, layout_identity)
	return plan


static func _layout_identity(facts: Dictionary) -> String:
	# Cultural choice affects appearance, not anyone's legal cluster positions.
	# Keep a canonical static layout identity separate from the full cache key.
	var identity: Array = [VERSION,facts.seed,facts.map_id,facts.map_version,facts.bounds]
	for category: String in ["sites","sources","terrain"]: identity.append(facts[category])
	for side: Dictionary in facts.sides: identity.append([side.id,side.position])
	return var_to_str(identity).sha256_text()


static func _build_home_decorations(plan: Dictionary, facts: Dictionary, identity: String) -> void:
	for side: Dictionary in facts.sides.slice(0,4):
		var rng := RandomNumberGenerator.new()
		rng.seed = (identity+":"+side.id+":"+str(side.position)).sha256_text().substr(0,15).hex_to_int()
		var count := 0
		var candidates: Array[Vector2i] = []
		# Multiple rings frame the settlement instead of filling its quiet core.
		for radius: int in [250,335,425]:
			var rotation := rng.randf_range(0,TAU)
			for slot: int in range(24):
				var angle := rotation+float(slot)*TAU/24
				candidates.append(side.position+Vector2i(Vector2.from_angle(angle)*(radius+rng.randf_range(-12,12))))
		# Interleave rings to keep a successful inner ring from consuming every
		# slot. Candidate attempts and accepted allocations have separate bounds.
		for index: int in range(72):
			if count>=HOME_DECOR_PER_SIDE or plan.decorations.size()>=DECORATION_LIMIT: break
			var point: Vector2i = candidates[(index%3)*24+index/3]
			if not _home_decoration_clear(point,plan,facts): continue
			var style: Dictionary = STYLES.get(side.faction_id,STYLES.HUMAN)
			plan.decorations.append({"kind":"HOMELAND","side_id":side.id,"faction_id":side.faction_id,
				"position":point,"family":count%3,"variant":rng.randi_range(0,3),
				"scale":rng.randf_range(0.9,1.25),"biome":style.biome,"footprint":HOME_DECOR_FOOTPRINT})
			count+=1
		plan.home_decoration_summary.append({"side_id":side.id,"count":count,"target":HOME_DECOR_PER_SIDE,"shortfall":HOME_DECOR_PER_SIDE-count})


static func _home_decoration_clear(point: Vector2i, plan: Dictionary, facts: Dictionary) -> bool:
	var footprint := HOME_DECOR_FOOTPRINT
	if not Navigation.point_clear(point,footprint,facts.bounds,facts.terrain): return false
	for zone: Dictionary in plan.home_zones:
		if Vector2(point).distance_to(zone.position)<HOME_CORE+footprint: return false
	for site: Dictionary in facts.sites:
		if Vector2(point).distance_to(site.position)<(100 if site.kind=="RESOURCE" else 64)+footprint: return false
	for source: Dictionary in facts.sources:
		if Vector2(point).distance_to(source.position)<source.radius+footprint+8: return false
	for rectangle: Rect2i in (plan.get("road_corridors",[]) if plan.get("road_mode")=="TILED" else []):
		var shape := Rect2(rectangle)
		if Vector2(point).distance_to(Vector2(point).clamp(shape.position,shape.end))<footprint+8: return false
	for road: Dictionary in ([] if plan.get("road_mode")=="TILED" else plan.roads):
		for index: int in range(1,road.points.size()):
			var nearest := Geometry2D.get_closest_point_to_segment(point,road.points[index-1],road.points[index])
			if Vector2(point).distance_to(nearest)<float(road.width)*0.5+footprint+8: return false
	for decor: Dictionary in plan.decorations:
		if Vector2(point).distance_to(decor.position)<footprint*2+8: return false
	return true


static func _facts(snapshot: Dictionary) -> Dictionary:
	var config: Dictionary = snapshot.get("match_config", {})
	var bounds := Rect2i()
	var given: Variant = config.get("bounds", snapshot.get("bounds"))
	if given is Rect2i: bounds = given
	elif given is Rect2: bounds = Rect2i(given)
	else:
		var arena: Dictionary = snapshot.get("arena_bounds", {})
		if arena.has("min_x") and arena.has("max_x"):
			bounds = Rect2i(int(arena.min_x), int(arena.min_y), int(arena.max_x)-int(arena.min_x), int(arena.max_y)-int(arena.min_y))
	var facts := {"seed":int(snapshot.get("seed", config.get("seed", 1701))),
		"map_id":str(config.get("map_id", snapshot.get("map_id", ""))),
		"map_version":str(config.get("map_version", config.get("version", ""))),
		"bounds":bounds, "sites":[], "sources":[], "terrain":[], "sides":[],"route_layout_version":str(config.get("route_layout_version",snapshot.get("route_layout_version",""))),"reserved_routes":config.get("reserved_routes",snapshot.get("reserved_routes",[])).duplicate(true)}
	for category: String in ["sites", "sources", "terrain"]:
		var records: Array = snapshot.get("resource_sources", config.get("sources", [])) if category == "sources" else snapshot.get(category, config.get(category, []))
		for item: Dictionary in records:
			var position := Vector2i(item.get("position", Vector2i.ZERO))
			facts[category].append({"id":str(item.get("id", "")), "kind":str(item.get("kind", "")),
				"position":position, "radius":int(item.get("radius", 50 if category == "sources" else 0)),
				"blocks_ground":bool(item.get("blocks_ground", category == "terrain"))})
		facts[category].sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	for side: Dictionary in config.get("sides", snapshot.get("sides", [])):
		facts.sides.append({"id":str(side.get("side_id", "")), "faction_id":str(side.get("faction_id", "HUMAN")), "position":Vector2i(side.get("home", Vector2i.ZERO))})
	facts.sides.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	return facts


static func _reserved_roads(plan: Dictionary,facts: Dictionary) -> void:
	# V3 already reserved whole-cell streets against potential full construction.
	# Presentation consumes detached author facts; it cannot silently reroute a
	# blocked branch, omit a satellite or become a second movement authority.
	var routes: Array=facts.get("reserved_routes",[])
	if routes.is_empty() or routes.size()>64:
		plan.failures.append({"kind":"ROAD","reason":"INVALID_RESERVED_ROUTE_COUNT"})
		return
	var occupied: Dictionary={}
	var corridors: Array[Rect2i]=[]
	var seen: Dictionary={}
	for source: Dictionary in routes:
		var id:=str(source.get("id",""))
		var width:=int(source.get("width",0))
		var points: Array=source.get("points",[])
		if id.is_empty() or seen.has(id) or width not in [64,96] or points.size()<2 or points.size()>2048:
			plan.failures.append({"kind":"ROAD","reason":"INVALID_RESERVED_ROUTE","id":id})
			return
		seen[id]=true
		for index: int in range(1,points.size()):
			if not points[index-1] is Vector2i or not points[index] is Vector2i:
				plan.failures.append({"kind":"ROAD","reason":"INVALID_RESERVED_POINT","id":id})
				return
			var first: Vector2i=points[index-1]
			var next: Vector2i=points[index]
			var rectangle:=OrthogonalRoads.corridor(first,next,width)
			var local:=rectangle.position-Vector2i(facts.bounds.position)
			if (first.x!=next.x and first.y!=next.y) or posmod(local.x,RoadTiles.CELL)!=0 or posmod(local.y,RoadTiles.CELL)!=0 or rectangle.size.x%RoadTiles.CELL!=0 or rectangle.size.y%RoadTiles.CELL!=0 or not OrthogonalRoads.rectangle_clear(rectangle,facts.bounds,facts.terrain,4):
				plan.failures.append({"kind":"ROAD","reason":"RESERVED_ROUTE_NOT_CLEAR_WHOLE_CELLS","id":id,"segment":index-1})
				return
			corridors.append(rectangle)
			var low:=Vector2i(local/RoadTiles.CELL)
			var high:=Vector2i((rectangle.end-Vector2i(facts.bounds.position))/RoadTiles.CELL)
			for y: int in range(low.y,high.y):
				for x: int in range(low.x,high.x):occupied[Vector2i(x,y)]=true
			if occupied.size()>RoadTiles.MAX_CELLS:
				plan.failures.append({"kind":"ROAD","reason":"RESERVED_WHOLE_CELL_BUDGET"})
				return
		plan.roads.append(source.duplicate(true))
	var cells: Array[Vector2i]=[]
	cells.assign(occupied.keys())
	cells.sort_custom(func(a: Vector2i,b: Vector2i)->bool:return a.x<b.x if a.y==b.y else a.y<b.y)
	plan.merge({"road_mode":"TILED","road_cell_size":RoadTiles.CELL,"road_grid_origin":facts.bounds.position,"road_router_version":facts.route_layout_version,"road_tiles_version":RoadTiles.VERSION,"road_cells":cells,"road_corridors":corridors,"road_router_stats":{"source":"reserved-author-streets","paint_cells":cells.size(),"max_grid_cells":RoadTiles.MAX_CELLS,"searches":0,"live_reroutes":0,"diagonal_fallbacks":0,"clearance_representation":"exact-aligned-cell-runs"}})


static func _build_roads(plan: Dictionary, facts: Dictionary, resources: Array[Dictionary], villages: Array[Dictionary]) -> void:
	var main_router := RoadRouter.new(facts.bounds, facts.terrain, MAIN_ROAD_WIDTH / 2 + ROAD_MARGIN)
	var branch_router := RoadRouter.new(facts.bounds, facts.terrain, BRANCH_ROAD_WIDTH / 2 + ROAD_MARGIN)
	var roots: Dictionary = {}
	var edges: Array[Dictionary] = []
	for index: int in range(resources.size()):
		roots[resources[index].id] = resources[index].id
		for next: int in range(index + 1, resources.size()):
			var first: Dictionary = resources[index]
			var second: Dictionary = resources[next]
			edges.append({"a":first, "b":second, "distance":first.position.distance_squared_to(second.position), "key":first.id+"|"+second.id})
	edges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.key < b.key if a.distance == b.distance else a.distance < b.distance)
	for edge: Dictionary in edges:
		var first_root := _root(roots, edge.a.id)
		var second_root := _root(roots, edge.b.id)
		if first_root == second_root: continue
		var points := main_router.route(edge.a.position, edge.b.position)
		if points.is_empty(): continue
		roots[second_root] = first_root
		_add_road(plan, edge.a, edge.b, "RESOURCE", points, MAIN_ROAD_WIDTH)
	var components: Dictionary = {}
	for resource: Dictionary in resources: components[_root(roots, resource.id)] = true
	if components.size() > 1:
		plan.failures.append({"kind":"RESOURCE", "reason":"DISCONNECTED_RESOURCE_GRAPH", "components":components.size()})
	for village: Dictionary in villages:
		var nearest := resources.duplicate()
		nearest.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var first: float = Vector2(village.position).distance_squared_to(a.position)
			var second: float = Vector2(village.position).distance_squared_to(b.position)
			return a.id < b.id if first == second else first < second)
		var connected := false
		for resource: Dictionary in nearest:
			var points := branch_router.route(village.position, resource.position)
			if points.is_empty(): continue
			_add_road(plan, village, resource, "VILLAGE", points, BRANCH_ROAD_WIDTH)
			connected = true
			break
		if not connected: plan.failures.append({"kind":"VILLAGE", "from_id":village.id, "reason":"NO_REACHABLE_RESOURCE"})


static func _root(roots: Dictionary, id: String) -> String:
	var current := id
	for _step: int in range(roots.size()):
		var next: String = roots[current]
		if next == current: return current
		current = next
	return current


static func _add_road(plan: Dictionary, first: Dictionary, second: Dictionary, kind: String, points: Array[Vector2i], width: int) -> void:
	var material := "DIRT"
	var midpoint := (Vector2(first.position) + Vector2(second.position)) * 0.5
	var closest := INF
	for zone: Dictionary in plan.home_zones:
		var distance := midpoint.distance_to(zone.position)
		if distance < closest and distance <= float(zone.radius) * 1.3:
			closest = distance
			material = zone.road_material
	plan.roads.append({"id":kind.to_lower()+":"+first.id+":"+second.id, "from_id":first.id, "to_id":second.id,
		"kind":kind, "points":points.duplicate(), "width":width, "material":material})


static func _build_decorations(plan: Dictionary, facts: Dictionary, identity: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = identity.substr(0, 15).hex_to_int()
	var columns := clampi(ceili(sqrt(400.0 * facts.bounds.size.x / maxf(facts.bounds.size.y, 1))), 1, 48)
	var rows := clampi(ceili(400.0 / columns), 1, 48)
	var cells: Array[int] = []
	for index: int in range(columns * rows): cells.append(index)
	for index: int in range(cells.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var saved: int = cells[index]
		cells[index] = cells[other]
		cells[other] = saved
	var clusters: Array[Vector2] = []
	for _index: int in range(8):
		clusters.append(Vector2(facts.bounds.position) + Vector2(rng.randf(), rng.randf()) * Vector2(facts.bounds.size))
	for cell: int in cells:
		if plan.decorations.size() >= DECORATION_LIMIT: break
		var point: Vector2i = facts.bounds.position + Vector2i(roundi((float(cell % columns) + rng.randf_range(0.12, 0.88)) * facts.bounds.size.x / columns),
			roundi((float(cell / columns) + rng.randf_range(0.12, 0.88)) * facts.bounds.size.y / rows))
		var clustered := false
		for center: Vector2 in clusters:
			if center.distance_squared_to(point) < 360.0 * 360.0: clustered = true; break
		if not clustered and rng.randf() > 0.42: continue
		if not _decoration_clear(point, plan, facts): continue
		var biome := {"river-crossroads":"WOODLAND", "highland-caldera":"ROCKLAND", "debug-frontier":"DRYLAND"}.get(facts.map_id, "GRASSLAND") as String
		var nearest := INF
		for zone: Dictionary in plan.home_zones:
			var distance := Vector2(point).distance_squared_to(zone.position)
			if distance < nearest and distance <= float(zone.radius * zone.radius): nearest = distance; biome = zone.biome
		var choices: Array = {
			"GRASSLAND":["GRASS","GRASS","FLOWER","BUSH","STONE"],
			"ASHLAND":["STONE","LOG","BUSH"],
			"INDUSTRIAL":["SCRAP","STONE","GRASS"],
			"WOODLAND":["GRASS","BUSH","LOG","FLOWER"],
			"SNOWFIELD":["SNOW_PATCH","STONE","BUSH"],
			"FUNGAL":["MUSHROOM","CRYSTAL","STONE"],
			"ROCKLAND":["STONE","SNOW_PATCH","GRASS"],
			"DRYLAND":["STONE","GRASS","BUSH"],
		}.get(biome, ["GRASS","STONE"])
		# Appearance never consumes the position RNG: changing one culture must
		# not reshuffle another home or neutral candidate locations.
		var detail_key := posmod((str(facts.seed)+":"+str(point)).hash(),1000003)
		plan.decorations.append({"kind":choices[detail_key%choices.size()], "position":point,
			"variant":detail_key%4, "scale":0.75+float(detail_key%501)/1000.0, "biome":biome})


static func _decoration_clear(point: Vector2i, plan: Dictionary, facts: Dictionary) -> bool:
	if not Navigation.point_clear(point, 14, facts.bounds, facts.terrain): return false
	for zone: Dictionary in plan.home_zones:
		if Vector2(point).distance_squared_to(zone.position) < float(HOME_CORE * HOME_CORE): return false
	for site: Dictionary in facts.sites:
		var radius := 100 if site.kind == "RESOURCE" else 64
		if Vector2(point).distance_squared_to(site.position) < radius * radius: return false
	for source: Dictionary in facts.sources:
		var radius: int = source.radius + 22
		if Vector2(point).distance_squared_to(source.position) < radius * radius: return false
	for decor: Dictionary in plan.decorations:
		if decor.get("kind")=="HOMELAND" and Vector2(point).distance_to(decor.position)<HOME_DECOR_FOOTPRINT+18: return false
	for road: Dictionary in plan.roads:
		var points: Array = road.points
		for index: int in range(1, points.size()):
			var closest := Geometry2D.get_closest_point_to_segment(Vector2(point), Vector2(points[index-1]), Vector2(points[index]))
			if Vector2(point).distance_squared_to(closest) < pow(float(road.width) * 0.5 + 20, 2): return false
	return true


class RoadRouter:
	extends RefCounted
	## Bounded eight-neighbour grid search, cached cell/edge legality per width.
	## Final shortcuts are revalidated against exact circles, not the grid mask.
	const STEP := 64
	const MAX_GRID_CELLS := 8192
	const MAX_OPEN_ITEMS := 32768
	var bounds: Rect2i
	var obstacles: Array
	var clearance: int
	var columns: int
	var rows: int
	var cell_clear: Dictionary = {}
	var edge_clear: Dictionary = {}

	func _init(given_bounds: Rect2i, given_obstacles: Array, radius: int) -> void:
		bounds = given_bounds
		obstacles = given_obstacles
		clearance = radius
		columns = ceili(float(bounds.size.x) / STEP)
		rows = ceili(float(bounds.size.y) / STEP)

	func route(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
		var empty: Array[Vector2i] = []
		if not Navigation.point_clear(start, clearance, bounds, obstacles) or not Navigation.point_clear(target, clearance, bounds, obstacles): return empty
		if Navigation.segment_clear(start, target, clearance, bounds, obstacles): return [start, target]
		var grid_route := _grid_route(start, target)
		if not grid_route.is_empty(): return grid_route
		# A grid samples space and can miss narrow but real passages. The
		# existing bounded circle visibility planner is a rare exact-geometry
		# fallback, never a straight-line escape hatch or authority mutation.
		var fallback: Array[Vector2i] = [start]
		for point: Vector2i in Navigation.find_path(start, target, clearance, bounds, obstacles):
			if not Navigation.segment_clear(fallback[-1], point, clearance, bounds, obstacles): return empty
			fallback.append(point)
		return fallback if fallback.size() > 1 and fallback[-1] == target else empty

	func _grid_route(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
		var empty: Array[Vector2i] = []
		if columns * rows > MAX_GRID_CELLS: return empty
		var starts := _anchors(start)
		var targets := _anchors(target)
		if starts.is_empty() or targets.is_empty(): return empty
		var target_set: Dictionary = {}
		for cell: int in targets: target_set[cell] = true
		var cost := PackedFloat64Array()
		cost.resize(columns * rows); cost.fill(INF)
		var previous := PackedInt32Array()
		previous.resize(columns * rows); previous.fill(-2)
		var closed := PackedByteArray()
		closed.resize(columns * rows)
		var heap: Array[Dictionary] = []
		for cell: int in starts:
			cost[cell] = Vector2(start).distance_to(_point(cell))
			previous[cell] = -1
			_push(heap, {"cell":cell, "g":cost[cell], "f":cost[cell]+Vector2(_point(cell)).distance_to(target)})
		var found := -1
		for _iteration: int in range(MAX_GRID_CELLS):
			if heap.is_empty() or heap.size() > MAX_OPEN_ITEMS: break
			var entry := _pop(heap)
			var current: int = entry.cell
			if closed[current] or float(entry.g) > cost[current]: continue
			closed[current] = 1
			if target_set.has(current): found = current; break
			var grid := Vector2i(current % columns, current / columns)
			for delta: Vector2i in [Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(-1,0), Vector2i(1,0), Vector2i(-1,1), Vector2i(0,1), Vector2i(1,1)]:
				var next_grid := grid + delta
				if next_grid.x < 0 or next_grid.y < 0 or next_grid.x >= columns or next_grid.y >= rows: continue
				var next := next_grid.y * columns + next_grid.x
				if closed[next] or not _cell_legal(next) or not _edge_legal(current, next): continue
				var candidate := cost[current] + Vector2(delta).length() * STEP
				if candidate >= cost[next]: continue
				cost[next] = candidate
				previous[next] = current
				_push(heap, {"cell":next, "g":candidate, "f":candidate+Vector2(_point(next)).distance_to(target)})
		if found < 0: return empty
		var reverse: Array[Vector2i] = [target]
		var cursor := found
		for _step: int in range(MAX_GRID_CELLS):
			if cursor < 0: break
			reverse.append(_point(cursor))
			cursor = previous[cursor]
		reverse.append(start)
		reverse.reverse()
		var result: Array[Vector2i] = [start]
		var index := 0
		while index < reverse.size()-1:
			var farthest := index+1
			for next: int in range(index+2, reverse.size()):
				if Navigation.segment_clear(reverse[index], reverse[next], clearance, bounds, obstacles): farthest = next
			if not Navigation.segment_clear(reverse[index], reverse[farthest], clearance, bounds, obstacles): return empty
			result.append(reverse[farthest])
			index = farthest
		return result

	func _anchors(point: Vector2i) -> Array[int]:
		var result: Array[int] = []
		var center := Vector2i(floori(float(point.x-bounds.position.x) / STEP), floori(float(point.y-bounds.position.y) / STEP))
		for y: int in range(center.y-2, center.y+3):
			for x: int in range(center.x-2, center.x+3):
				if x < 0 or y < 0 or x >= columns or y >= rows: continue
				var cell := y*columns+x
				if _cell_legal(cell) and Navigation.segment_clear(point, _point(cell), clearance, bounds, obstacles): result.append(cell)
		result.sort_custom(func(a: int, b: int) -> bool:
			var first := point.distance_squared_to(_point(a))
			var second := point.distance_squared_to(_point(b))
			return a < b if first == second else first < second)
		if result.size() > 8: result.resize(8)
		return result

	func _point(cell: int) -> Vector2i:
		return bounds.position + Vector2i((cell % columns)*STEP+STEP/2, (cell / columns)*STEP+STEP/2)

	func _cell_legal(cell: int) -> bool:
		if not cell_clear.has(cell): cell_clear[cell] = Navigation.point_clear(_point(cell), clearance, bounds, obstacles)
		return cell_clear[cell]

	func _edge_legal(first: int, second: int) -> bool:
		var key := mini(first,second)*MAX_GRID_CELLS+maxi(first,second)
		if not edge_clear.has(key): edge_clear[key] = Navigation.segment_clear(_point(first), _point(second), clearance, bounds, obstacles)
		return edge_clear[key]

	func _less(first: Dictionary, second: Dictionary) -> bool:
		return int(first.cell) < int(second.cell) if is_equal_approx(float(first.f), float(second.f)) else float(first.f) < float(second.f)

	func _push(heap: Array[Dictionary], entry: Dictionary) -> void:
		heap.append(entry)
		var index := heap.size()-1
		while index > 0:
			var parent := (index-1)/2
			if not _less(heap[index], heap[parent]): break
			var saved := heap[parent]
			heap[parent] = heap[index]
			heap[index] = saved
			index = parent

	func _pop(heap: Array[Dictionary]) -> Dictionary:
		var result: Dictionary = heap[0]
		var tail: Dictionary = heap.pop_back()
		if heap.is_empty(): return result
		heap[0] = tail
		var index := 0
		while index*2+1 < heap.size():
			var child := index*2+1
			if child+1 < heap.size() and _less(heap[child+1],heap[child]): child += 1
			if not _less(heap[child],heap[index]): break
			var saved := heap[index]
			heap[index] = heap[child]
			heap[child] = saved
			index = child
		return result
