class_name StrategicMapCatalog
extends RefCounted
## Versioned authored closed geometry, including real joined lake lobes.
## Seeds decorate this strategic skeleton; resources/starts are not random.
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const Economy = preload("res://src/simulation/strategic_economy_catalog.gd")
const PhysicalBiomesM75 = preload("res://src/simulation/strategic_terrain_clusters_m75.gd")
const Outposts = preload("res://src/simulation/strategic_outpost_rules.gd")
const CONTENT_VERSION := 6
const IDS := ["borderlands","river-crossroads","highland-caldera","debug-frontier"]
const RIVER_RADIUS := 88
const RIVER_STEP := 160
static var _map_cache: Dictionary={}
const META := {
	"borderlands":{"name":"边境四境","size":Vector2i(3200,2000),"max_players":2,"resources":4,"villages":10},
	"river-crossroads":{"name":"河谷交汇","size":Vector2i(4000,2800),"max_players":4,"resources":8,"villages":14},
	"highland-caldera":{"name":"山炉环地","size":Vector2i(4200,3000),"max_players":4,"resources":8,"villages":16},
	"debug-frontier":{"name":"演练大边境 · DEBUG","size":Vector2i(4800,3200),"max_players":4,"resources":12,"villages":20},
}
static func get_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for id: String in IDS:
		var meta: Dictionary=META[id]
		if Outposts.enabled():
			var current:=get_map(id)
			result.append({"id":id,"name":current.name,"display_name":current.name,"version":current.version,"max_players":meta.max_players,"max_participants":meta.max_players,"debug":current.debug,"bounds":current.bounds,"resource_count":current.resource_count,"village_count":current.village_count})
			continue
		result.append({"id":id,"name":meta.name,"display_name":meta.name,"version":CONTENT_VERSION,"max_players":meta.max_players,"max_participants":meta.max_players,"debug":id=="debug-frontier","bounds":Rect2i(Vector2i(80,80),meta.size),"resource_count":meta.resources,"village_count":meta.villages})
	return result
static func get_map(id: String) -> Dictionary:
	if id not in IDS: return {}
	if Outposts.enabled():
		if not _map_cache.has(id): _map_cache[id]=Outposts.map_for(id,META[id],CONTENT_VERSION)
		return _map_cache[id].duplicate(true)
	if _map_cache.has(id):return _map_cache[id].duplicate(true)
	var meta: Dictionary=META[id]
	var bounds:=Rect2i(Vector2i(80,80),meta.size)
	var homes: Array=[Vector2i(400,600),Vector2i(2880,1480)] if id=="borderlands" else [Vector2i(500,650),Vector2i(bounds.end.x-500,bounds.end.y-650),Vector2i(bounds.end.x-500,650),Vector2i(500,bounds.end.y-650)]
	var resources: Array=homes.duplicate()
	if id=="borderlands": resources.append_array([Vector2i(1260,620),Vector2i(2060,1380)])
	else:
		if id=="debug-frontier":
			for home: Vector2i in homes: resources.append(home+Vector2i(200 if home.x<bounds.get_center().x else -200,100))
		resources.append_array([Vector2i(bounds.get_center().x-650,bounds.get_center().y-500),Vector2i(bounds.get_center().x+650,bounds.get_center().y+500),Vector2i(bounds.get_center().x-650,bounds.get_center().y+500),Vector2i(bounds.get_center().x+650,bounds.get_center().y-500)])
	var villages: Array[Vector2i]=[]
	if id=="borderlands": villages=[Vector2i(660,280),Vector2i(2640,1880),Vector2i(940,980),Vector2i(2360,1180),Vector2i(1200,1760),Vector2i(2100,400),Vector2i(1580,320),Vector2i(1720,1840),Vector2i(550,1500),Vector2i(2750,660)]
	else:
		for home: Vector2i in homes:
			villages.append(home+Vector2i(300 if home.x<bounds.get_center().x else -300,-300))
			villages.append(home+Vector2i(400 if home.x<bounds.get_center().x else -400,400 if home.y<bounds.get_center().y else -400))
		for index: int in range(int(meta.villages)-villages.size()):
			villages.append(Vector2i(1050+(index%4)*650,420+int(index/4)*720))
	var sites: Array[Dictionary]=[]
	var sources: Array[Dictionary]=[]
	for index: int in range(resources.size()):
		var site_id:="resource_%02d"%(index+1)
		sites.append({"id":site_id,"kind":"RESOURCE","position":resources[index],"owner":""})
		for resource: String in ["FOOD","MATERIAL"]:
			var initial:=Economy.source_stock(resource)
			var offset:=Vector2i(-100,-120) if resource=="FOOD" else Vector2i(116,-150)
			sources.append({"id":resource.to_lower()+":"+site_id,"site_id":site_id,"kind":resource,"resource":resource,"position":resources[index]+offset,"radius":50,"initial":initial})
	for index: int in range(villages.size()): sites.append({"id":"village_%02d"%(index+1),"kind":"VILLAGE","position":villages[index],"owner":""})
	var terrain: Array[Dictionary]=[]
	var center: Vector2i=bounds.get_center()
	var radius:=140 if id=="borderlands" else 210
	terrain.append(_terrain("lake_01","LAKE",center,radius,true))
	terrain.append(_terrain("mountain_01","MOUNTAIN",center+Vector2i(-450,600),80,true))
	terrain.append(_terrain("trees_01","TREE",center+Vector2i(420,-530),48,true))
	terrain.append(_terrain("ruins_01","RUIN",center+Vector2i(-500,-620),38,true))
	terrain.append(_terrain("monument_01","MONUMENT",center+Vector2i(550,650),28,false))
	# Preserve strategic access at authoring time. Obstacles keep their true
	# footprints; only authored placement moves away from flags, finite sources
	# and initial settlements. The stable bounded offsets retain replayability.
	for prop: Dictionary in terrain:
		if prop.blocks_ground:prop.position=_fit_terrain(prop.position,int(prop.radius),bounds,sites,sources,homes)
	# Author two connected water segments around a real land crossing. Fit each
	# whole segment with one translation: fitting its circles independently can
	# tear a river apart while avoiding a nearby resource flag. The 16px overlap
	# is genuine static union geometry, not a river-only collision exemption.
	# DEBUG's lake is fitted east of its original center to protect authored
	# flags. Place that map's entire river band farther east so the middle land
	# corridor remains useful even for the largest 22px ground body.
	var river_x:=center.x+(1000 if id=="debug-frontier" else 360)
	for first_index: int in [0,4]:
		var origins: Array[Vector2i]=[]
		for index: int in range(first_index,first_index+2):origins.append(Vector2i(river_x,center.y-460+index*RIVER_STEP))
		var positions:=_fit_river_segment(origins,RIVER_RADIUS,bounds,sites,sources,homes)
		for index: int in range(positions.size()):terrain.append(_terrain("river_%02d"%(first_index+index),"RIVER",positions[index],RIVER_RADIUS,true))
	# Two small, connected true obstacles change the silhouette rather than
	# merely painting a jagged edge over an unrelated circular collider. The
	# existing core, flags, finite pools and deliberately authored river remain.
	terrain.append_array(_lake_lobes(terrain[0],id,bounds,sites,sources,homes,terrain))
	_fit_land_scenery(terrain,bounds,sites,sources,homes)
	_add_essence_sites(bounds,sites,sources,homes,terrain,2 if meta.max_players==2 else 4)
	var biome_report := PhysicalBiomesM75.populate(id,bounds,sites,sources,homes,terrain)
	var result:={"id":id,"name":meta.name,"display_name":meta.name,"version":CONTENT_VERSION,"bounds":bounds,"max_players":meta.max_players,"resource_count":meta.resources,"village_count":meta.villages,"debug":id=="debug-frontier","homes":homes,"sites":sites,"sources":sources,"terrain":terrain,"physical_biomes":biome_report,"initial_zoom":2.5,"camera_max_zoom":5.0}
	_map_cache[id]=result.duplicate(true)
	return result

static func _add_essence_sites(bounds: Rect2i,sites: Array,sources: Array,homes: Array,terrain: Array,count: int) -> void:
	# Choose a whole mirrored group, not the first N clear candidates (which
	# clustered every mine on one side). Homes are offset from bounds by 40px.
	var center:=Vector2i.ZERO
	for home: Vector2i in homes:center+=home
	center=Vector2i(center.x/homes.size(),center.y/homes.size())
	var best: Array[Vector2i]=[]
	var best_score:=INF
	for dx: int in [180,260,340,420,500,580,660,720,820,940]:
		for dy: int in [180,260,340,420,500,580,660,740,800]:
			for sign_y: int in [-1,1]:
				var points: Array[Vector2i]=[center+Vector2i(dx,dy*sign_y),center-Vector2i(dx,dy*sign_y)]
				if count==4:points.append_array([center+Vector2i(-dx,dy*sign_y),center+Vector2i(dx,-dy*sign_y)])
				var score:=_essence_group_score(points,center,bounds,sites,sources,homes,terrain)
				if score<best_score:best_score=score;best=points
	assert(best.size()==count,"Central essence deposits need a fair clear land group")
	for index: int in range(best.size()):
		var site_id:="essence_%02d"%(index+1)
		var point: Vector2i=best[index]
		sites.append({"id":site_id,"kind":"RESOURCE","resource":"ESSENCE","capacity":0,"position":point,"owner":""})
		sources.append({"id":"essence:"+site_id,"site_id":site_id,"kind":"ESSENCE","resource":"ESSENCE","position":point+Vector2i(-96,-96),"radius":50,"initial":Economy.source_stock("ESSENCE")})

static func _essence_group_score(points: Array[Vector2i],center: Vector2i,bounds: Rect2i,sites: Array,sources: Array,homes: Array,terrain: Array) -> float:
	var placed_sites: Array=sites.duplicate()
	var placed_sources: Array=sources.duplicate()
	for point: Vector2i in points:
		for home: Vector2i in homes:
			if Vector2(point).distance_to(Vector2(home))<700:return INF
		if not _authoring_clear(point,145,bounds,placed_sites,placed_sources,homes) or not Navigation.point_clear(point,150,bounds,terrain) or not Navigation.point_clear(point+Vector2i(-96,-96),65,bounds,terrain):return INF
		placed_sites.append({"kind":"RESOURCE","position":point})
		placed_sources.append({"position":point+Vector2i(-96,-96)})
	var nearest: Array[float]=[]
	for home: Vector2i in homes:
		var minimum:=INF
		for point: Vector2i in points:
			var path:=Navigation.find_path(home,point,26,bounds,terrain)
			if path.is_empty():return INF
			var length:=0.0
			var previous:=home
			for step: Vector2i in path:length+=Vector2(previous).distance_to(Vector2(step));previous=step
			minimum=minf(minimum,length)
		nearest.append(minimum)
	var low: float=nearest.min()
	var high: float=nearest.max()
	var gap: float=(high-low)/maxf(1.0,low)
	if gap>0.05:return INF
	# Among <=5% path-fair groups, prefer the central, compact contest.
	return Vector2(points[0]).distance_to(Vector2(center))+gap*1000.0

static func _fit_land_scenery(terrain: Array,bounds: Rect2i,sites: Array,sources: Array,homes: Array) -> void:
	var water: Array[Dictionary]=[]
	for prop: Dictionary in terrain:
		if prop.kind in ["LAKE","RIVER"]:water.append(prop)
	var directions: Array[Vector2i]=[Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP,Vector2i.DOWN,Vector2i(1,-1),Vector2i(-1,-1),Vector2i(1,1),Vector2i(-1,1)]
	for prop: Dictionary in terrain:
		if prop.kind not in ["TREE","MOUNTAIN"]:continue
		if Navigation.point_clear(prop.position,int(prop.radius)+6,bounds,water):continue
		var origin: Vector2i=prop.position
		var found:=false
		for distance: int in [80,160,240,320,480]:
			for direction: Vector2i in directions:
				var candidate:=origin+direction*distance
				if not _authoring_clear(candidate,int(prop.radius),bounds,sites,sources,homes) or not Navigation.point_clear(candidate,int(prop.radius)+6,bounds,water):continue
				var probe:=prop.duplicate(true)
				probe.position=candidate
				if not _river_access_clear(probe,bounds,terrain):continue
				prop.position=candidate
				found=true
				break
			if found:break
		assert(found,"Land scenery must retain a bounded dry protected position")

static func _lake_lobes(core: Dictionary,map_id: String,bounds: Rect2i,sites: Array,sources: Array,homes: Array,terrain: Array) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var directions: Array[Vector2i]=[Vector2i(74,18),Vector2i(-46,-65),Vector2i(-72,23),Vector2i(34,70),Vector2i(53,-60),Vector2i(-18,75),Vector2i(0,-76),Vector2i(76,-10)]
	var radius:=ceili(float(core.radius)*0.60)
	var first:=posmod(IDS.find(map_id)*2,directions.size())
	for index: int in range(directions.size()):
		var direction: Vector2i=directions[(first+index)%directions.size()]
		var point: Vector2i=core.position+Vector2i(roundi(float(direction.x)*int(core.radius)/100.0),roundi(float(direction.y)*int(core.radius)/100.0))
		if not _authoring_clear(point,radius,bounds,sites,sources,homes):continue
		var lobe:=_terrain("lake_01_lobe_%02d"%(result.size()+1),"LAKE",point,radius,true)
		if not _river_access_clear(lobe,bounds,terrain):continue
		var separated:=true
		for previous: Dictionary in result:
			if Vector2(point).distance_to(Vector2(previous.position))<float(core.radius)*0.55:separated=false
		if not separated:continue
		result.append(lobe)
		if result.size()==2:break
	assert(not result.is_empty(),"Versioned lake needs at least one protected real lobe")
	return result

static func _river_access_clear(lobe: Dictionary,bounds: Rect2i,terrain: Array) -> bool:
	var rivers: Array[Dictionary]=[]
	for prop: Dictionary in terrain:
		if prop.kind=="RIVER":rivers.append(prop)
	rivers.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return str(a.id)<str(b.id))
	if rivers.size()!=4:return false
	var y:=int((int(rivers[1].position.y)+int(rivers[2].position.y))/2)
	var x:=int(rivers[1].position.x)
	if not Navigation.segment_clear(Vector2i(x-130,y),Vector2i(x+130,y),26,bounds,[lobe]):return false
	# Keep the pre-existing land approaches to each joined river available too.
	for river: Dictionary in rivers:
		for direction: int in [-1,1]:
			if not Navigation.point_clear(river.position+Vector2i(direction*160,-80),26,bounds,[lobe]):return false
	return true
static func _terrain(id: String,kind: String,position: Vector2i,radius: int,blocks: bool) -> Dictionary:
	return {"id":"terrain:"+id,"kind":kind,"position":position,"radius":radius,"blocks_ground":blocks}
static func _fit_terrain(origin: Vector2i,radius: int,bounds: Rect2i,sites: Array,sources: Array,homes: Array) -> Vector2i:
	if _authoring_clear(origin,radius,bounds,sites,sources,homes):return origin
	var directions: Array[Vector2i]=[Vector2i(0,1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]
	for distance: int in [160,320,480,640,800]:
		for direction: Vector2i in directions:
			var candidate:=origin+direction*distance
			if _authoring_clear(candidate,radius,bounds,sites,sources,homes):return candidate
	assert(false,"Authored obstacle has no bounded legal placement")
	return origin
static func _fit_river_segment(origins: Array[Vector2i],radius: int,bounds: Rect2i,sites: Array,sources: Array,homes: Array) -> Array[Vector2i]:
	var offsets: Array[Vector2i]=[Vector2i.ZERO]
	var directions: Array[Vector2i]=[Vector2i(0,1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]
	for distance: int in [160,320,480,640,800]:
		for direction: Vector2i in directions:offsets.append(direction*distance)
	for offset: Vector2i in offsets:
		var candidates: Array[Vector2i]=[]
		for origin: Vector2i in origins:
			var point:=origin+offset
			if not _authoring_clear(point,radius,bounds,sites,sources,homes):break
			candidates.append(point)
		if candidates.size()==origins.size():return candidates
	assert(false,"Authored river segment has no bounded legal placement")
	return origins.duplicate()
static func _authoring_clear(point: Vector2i,radius: int,bounds: Rect2i,sites: Array,sources: Array,homes: Array) -> bool:
	if point.x-radius<bounds.position.x or point.y-radius<bounds.position.y or point.x+radius>=bounds.end.x or point.y+radius>=bounds.end.y:return false
	for site: Dictionary in sites:
		# Leave an actual capture/construction envelope, not only the tiny flag.
		# Version5 deliberately fixes three cramped v4 authoring placements.
		var reach:=radius+76
		if (point-Vector2i(site.position)).length_squared()<reach*reach:return false
	for source: Dictionary in sources:
		var reach:=radius+50+4
		if (point-Vector2i(source.position)).length_squared()<reach*reach:return false
	for home: Vector2i in homes:
		var reach:=radius+380
		if (point-home).length_squared()<reach*reach:return false
	return true
