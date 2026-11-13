extends RefCounted
## V3 uses complete authored centers. Missing content is an error, never a
## successful smaller map; visual scale and local V2 building spacing stay put.
const VERSION := "compact-gold-three-camps-v3"
const Layout = preload("res://src/simulation/strategic_outpost_map_layout_v3.gd")
const FULL_TYPES := ["BASE","BARRACKS","RANGE","FOUNDRY","ALTAR","DRAGON_ROOST","SHOP"]
const FULL_OFFSETS := [Vector2i(0,0),Vector2i(220,240),Vector2i(220,-240),Vector2i(-220,240),Vector2i(-220,-240),Vector2i(-220,0),Vector2i(220,0)]
const FULL_TOWERS := [Vector2i(0,-320),Vector2i(365,-100),Vector2i(80,390),Vector2i(-80,390),Vector2i(-365,-100)]
const SMALL_VILLAGES := [Vector2i(3800,920),Vector2i(400,2020),Vector2i(3200,320),Vector2i(1000,2620),Vector2i(2500,520),Vector2i(1700,2420),Vector2i(2900,1220),Vector2i(1300,1720),Vector2i(500,1320),Vector2i(3700,1620)]
const LARGE_VILLAGES := [Vector2i(2400,620),Vector2i(3340,3440),Vector2i(1300,1920),Vector2i(4440,2140),Vector2i(5300,1820),Vector2i(440,2240),Vector2i(1400,820),Vector2i(4340,3240),Vector2i(3600,820),Vector2i(2140,3240),Vector2i(2900,1220),Vector2i(2840,2840),Vector2i(1600,320),Vector2i(4140,3740),Vector2i(600,1420),Vector2i(5140,2640),Vector2i(3600,320),Vector2i(2140,3740),Vector2i(4400,520),Vector2i(1340,3540)]

static func enabled() -> bool: return true

static func fully_owned(site: Dictionary, side: String) -> bool:
	return not side.is_empty() and site.get("owner","")==side and site.get("capture_side","")==side and int(site.get("progress",0))>=int(site.get("threshold",200))

static func site_kind(site: Dictionary) -> String:
	return "SATELLITE" if site.get("resource","")=="ESSENCE" else str(site.get("kind",""))

static func slot_definitions(sites: Array) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for site: Dictionary in sites:
		var kind:=site_kind(site)
		if kind=="RESOURCE":
			for i: int in range(FULL_TYPES.size()): result.append(_slot(site,str(FULL_TYPES[i]),0,FULL_OFFSETS[i]))
			for i: int in range(FULL_TOWERS.size()): result.append(_slot(site,"TOWER",i,FULL_TOWERS[i]))
		elif kind=="VILLAGE":
			var training:=_slot(site,"BARRACKS",0,Vector2i(-140,0))
			training.merge({"id":"%s:TRAINING:0"%site.id,"slot_kind":"TRAINING","allowed_building_types":["BARRACKS","RANGE"],"label":"训练营（物理／魔法二选一）"},true)
			result.append(training)
			result.append(_slot(site,"SHOP",0,Vector2i(140,0)))
			result.append(_slot(site,"TOWER",0,Vector2i(-200,190)))
			result.append(_slot(site,"TOWER",1,Vector2i(200,190)))
		elif kind=="SATELLITE":
			result.append(_slot(site,"ESSENCE_MINE",0,Vector2i.ZERO))
			result.append(_slot(site,"TOWER",0,Vector2i(-110,190)))
			result.append(_slot(site,"TOWER",1,Vector2i(110,190)))
	return result

static func _slot(site: Dictionary, type: String, index: int, offset: Vector2i) -> Dictionary:
	return {"id":"%s:%s:%d"%[site.id,type,index],"site_id":site.id,"site_kind":site_kind(site),"slot_kind":type,"building_type":type,"allowed_building_types":[type],"position":Vector2i(site.position)+offset}

static func slot_accepts(slot: Dictionary, type: String) -> bool:
	return type in slot.get("allowed_building_types",[slot.get("building_type","")])

static func rate_twentieths(site: Dictionary, resource: String) -> int:
	# Values are units/sec; World accumulates numerator /20, never floats.
	if resource!="MATERIAL":return 0
	if site_kind(site)=="RESOURCE": return 20
	if site_kind(site)=="SATELLITE": return 8 if bool(site.get("rich_gold",false)) else 4
	return 0

static func rate_numerator(site: Dictionary, resource: String) -> int:
	# 20Hz with divisor 100; carry fractional maintenance income in World.
	return rate_twentieths(site,resource)*5

static func map_for(id: String, meta: Dictionary, version: int) -> Dictionary:
	var large:=int(meta.max_players)>2
	var size:=Vector2i(5740,4060) if large else Vector2i(4200,2940)
	var bounds:=Rect2i(Vector2i(80,80),size)
	var c:=Vector2i(bounds.get_center())
	var homes: Array=[bounds.position+Vector2i(520,620),bounds.end-Vector2i(520,620)]
	if int(meta.max_players)>2: homes.append_array([Vector2i(bounds.end.x-520,bounds.position.y+620),Vector2i(bounds.position.x+520,bounds.end.y-620)])
	var sites: Array[Dictionary]=[]
	var sources: Array[Dictionary]=[]
	var resource_positions: Array=homes.duplicate()
	resource_positions.append_array([c+Vector2i(-800,-500),c+Vector2i(800,500)])
	if int(meta.max_players)>2: resource_positions.append_array([c+Vector2i(-800,500),c+Vector2i(800,-500)])
	for i: int in range(resource_positions.size()):
		var site_id:="resource_%02d"%(i+1)
		var point: Vector2i=resource_positions[i]
		sites.append({"id":site_id,"label":"资源根据地 %d"%(i+1),"kind":"RESOURCE","capacity":30,"position":point,"owner":""})
		sources.append(_source(site_id,"MATERIAL",point+Vector2i(0,-500),45000))
	var satellites: Array=[Vector2i(4200,1520),Vector2i(1540,2540),Vector2i(4600,1220),Vector2i(1140,2840)] if large else [Vector2i(3800,320),Vector2i(400,2620),Vector2i(1900,320),Vector2i(2300,2620)]
	satellites.append_array([Vector2i(size.x/2,size.y/2-300),Vector2i(size.x/2,size.y/2+300)])
	for i: int in range(satellites.size()):
		var point: Vector2i=bounds.position+Vector2i(satellites[i])
		var essence: bool=i>=4
		var resource:="MATERIAL"
		var site_id:=("essence_%02d"%(i-3)) if essence else "satellite_%02d"%(i+1)
		sites.append({"id":site_id,"label":("富金矿点 %d"%(i-3)) if essence else ("金矿小点 %d"%(i+1)),"kind":"SATELLITE","resource":resource,"rich_gold":essence,"guardian_tier":3 if essence else 2,"capacity":0,"position":point,"owner":""})
		sources.append(_source(site_id,resource,point+Vector2i(0,-180),12000 if essence else 6000))
	var villages: Array=LARGE_VILLAGES if large else SMALL_VILLAGES
	if int(meta.villages)>villages.size():
		push_error("V3 author table lacks promised villages: "+id)
		return {}
	for i: int in range(int(meta.villages)):
		var point:=bounds.position+Vector2i(villages[i])
		sites.append({"id":"village_%02d"%(i+1),"label":"人口据点 %d"%(i+1),"kind":"VILLAGE","capacity":10,"position":point,"owner":""})
	var slots:=slot_definitions(sites)
	var authored:=Layout.build(bounds,sites,sources,homes,slots)
	if not bool(authored.get("accepted",false)):
		push_error("V3 authored map is invalid: "+id+" "+str(authored.get("failures",[])))
		return {}
	var expected:={"RESOURCE":resource_positions.size(),"SATELLITE":6,"VILLAGE":int(meta.villages)}
	var expected_slots:=resource_positions.size()*12+int(meta.villages)*4+18
	if sites.size()!=resource_positions.size()+6+int(meta.villages) or slots.size()!=expected_slots or sources.size()!=resource_positions.size()+6:
		push_error("V3 author content count differs: "+id)
		return {}
	return {"id":id,"name":str(meta.name)+" · 据点指挥","display_name":str(meta.name)+" · 据点指挥","version":version+200,"bounds":bounds,"max_players":meta.max_players,"resource_count":resource_positions.size(),"village_count":int(meta.villages),"debug":id=="debug-frontier","homes":homes,"sites":sites,"sources":sources,"terrain":authored.terrain,"physical_biomes":authored.physical_biomes,"reserved_routes":authored.reserved_routes,"route_layout_version":Layout.VERSION,"authored_layout_version":Layout.VERSION,"expected_site_counts":expected,"expected_slot_count":expected_slots,"initial_zoom":2.5,"camera_max_zoom":5.0,"ruleset":VERSION}

static func _source(site_id: String, resource: String, point: Vector2i, amount: int) -> Dictionary:
	return {"id":resource.to_lower()+":"+site_id,"site_id":site_id,"kind":resource,"resource":resource,"position":point,"radius":50,"initial":amount}
