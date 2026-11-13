extends RefCounted
## Appearance-only enrichment over the unchanged deterministic road planner.
const Landscape = preload("res://src/presentation/strategic_landscape_plan.gd")
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const Collection = preload("res://src/presentation/strategic_frontier_collection.gd")
const VERSION := "frontier-collection-m29-v1"
const DECORATION_LIMIT := 216
const DISPLAY_FOOTPRINT := 32
const VISIBLE_LIMIT := 128
const FAMILIES := ["grass","fern","flower","bush","deadwood","stone","ruin","supplies","reed","mushroom","crystal","bones"]
const RECIPES := {
	"GRASSLAND":["grass","grass","fern","flower","bush","stone","supplies"],
	"WOODLAND":["fern","fern","bush","deadwood","grass","flower"],
	"ASHLAND":["bones","bones","deadwood","ruin","stone","bush"],
	"INDUSTRIAL":["supplies","supplies","stone","ruin","grass"],
	"SNOWFIELD":["stone","stone","deadwood","bush","grass","ruin"],
	"FUNGAL":["mushroom","mushroom","crystal","fern","stone","bones"],
	"ROCKLAND":["stone","stone","grass","deadwood","ruin"],
	"DRYLAND":["stone","grass","deadwood","bones","ruin","bush"],
}


static func detached_snapshot(snapshot: Dictionary, seed_override: int = -1) -> Dictionary:
	if seed_override < 0: return snapshot
	var detached := snapshot.duplicate(false)
	detached["seed"] = seed_override
	return detached


static func signature(snapshot: Dictionary, seed_override: int = -1) -> String:
	return Landscape.signature(detached_snapshot(snapshot,seed_override))+":"+VERSION+":"+str(Collection.enabled())


static func build(snapshot: Dictionary, seed_override: int = -1) -> Dictionary:
	var appearance := detached_snapshot(snapshot,seed_override)
	var plan := Landscape.build(appearance)
	if not Collection.enabled() or not plan.get("failures",[]).is_empty(): return plan
	plan["collection_version"] = VERSION
	plan["appearance_seed"] = int(plan.seed)
	var accepted: Array[Dictionary] = []
	# The old plan supplies grouped home positions and safe road topology. Its
	# smaller details are revalidated against the full new sprite envelope.
	for previous: Dictionary in plan.get("decorations",[]):
		var point := Vector2i(previous.position)
		if not decoration_clear(point,plan,appearance,accepted): continue
		accepted.append(_separate_variants(_decoration(point,plan,appearance,previous),accepted))
	# Framing candidates come from actual forest/rock/shore edges, rather than
	# a second uniform random scatter. Stable IDs and bounded work survive
	# reordered observations, camera movement and changes in live ownership.
	var terrain: Array = appearance.get("terrain",appearance.get("match_config",{}).get("terrain",[])).duplicate()
	terrain.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return str(a.get("id",""))<str(b.get("id","")))
	for obstacle: Dictionary in terrain:
		if accepted.size() >= DECORATION_LIMIT: break
		var kind := str(obstacle.get("kind",""))
		if kind not in ["TREE","MOUNTAIN","LAKE","RIVER"]: continue
		var key := _key([plan.seed,str(obstacle.get("id","")),"framing"])
		var radius := float(obstacle.get("radius",40))+DISPLAY_FOOTPRINT+14
		for slot: int in range(3):
			if accepted.size() >= DECORATION_LIMIT: break
			var angle := float(key%1000)/1000.0*TAU+float(slot)*TAU/3
			var point := Vector2i(Vector2(obstacle.get("position",Vector2.ZERO))+Vector2.from_angle(angle)*radius)
			if not decoration_clear(point,plan,appearance,accepted): continue
			accepted.append(_separate_variants(_decoration(point,plan,appearance,{"context":"SHORE" if kind in ["LAKE","RIVER"] else "FOREST" if kind == "TREE" else "RIDGE"}),accepted))
	plan["decorations"] = accepted
	plan["collection_summary"] = _summary(accepted)
	plan["obstacle_catalog"] = _obstacle_catalog()
	var obstacle_appearances: Dictionary = {}
	for obstacle: Dictionary in terrain:
		if obstacle.get("kind") in ["TREE","MOUNTAIN"]:
			obstacle_appearances[_terrain_key(obstacle)] = _terrain_appearance(obstacle,plan)
	plan["obstacle_appearances"] = obstacle_appearances
	return plan


static func _decoration(point: Vector2i, plan: Dictionary, snapshot: Dictionary, previous: Dictionary) -> Dictionary:
	var biome := biome_at(Vector2(point),plan)
	var context := str(previous.get("context",""))
	if context.is_empty(): context = _context_at(point,snapshot)
	var choices: Array = RECIPES.get(biome,RECIPES.GRASSLAND)
	if context == "SHORE": choices = ["reed","reed","bush","fern","stone"]
	elif context == "SETTLEMENT" and biome not in ["ASHLAND","FUNGAL"]: choices = ["supplies","supplies","grass","ruin","stone"]
	elif context == "FOREST" and biome not in ["ASHLAND","SNOWFIELD","FUNGAL"]: choices = ["fern","bush","deadwood","mushroom","grass"]
	elif context == "RIDGE": choices = ["stone","stone","grass","ruin","deadwood"]
	var family := str(choices[_key([plan.seed,point,"family",biome,context])%choices.size()])
	var available := allowed_variants(family,biome)
	var variant := 2 if family == "bush" and biome == "SNOWFIELD" else int(available[_key([plan.seed,point,"variant",family])%available.size()])
	return {"kind":"FRONTIER","position":point,"entry_id":family+"_"+str(variant),"family":family,"variant":variant,
		"biome":biome,"context":context,"scale":0.9+float(_key([plan.seed,point,"scale"])%101)/1000.0,
		"footprint":DISPLAY_FOOTPRINT,"legacy_kind":str(previous.get("kind","GRASS")),
		"legacy_family":int(previous.get("family",0)),"legacy_variant":int(previous.get("variant",0)),"legacy_scale":float(previous.get("scale",1)),
		"faction_id":str(previous.get("faction_id","HUMAN")),"side_id":str(previous.get("side_id",""))}


static func _separate_variants(decor: Dictionary, accepted: Array[Dictionary]) -> Dictionary:
	# Only locally appropriate authored siblings may break a repeated shape.
	# Industrial machinery and snow-covered plants never leak into other
	# environments through this second selection stage.
	var available := allowed_variants(str(decor.family),str(decor.biome))
	var nearby: Dictionary = {}
	for other: Dictionary in accepted:
		if str(other.family) == str(decor.family) and Vector2(other.position).distance_squared_to(Vector2(decor.position)) < 180*180:
			nearby[int(other.variant)] = true
	var start := maxi(available.find(int(decor.variant)),0)
	decor["variant"] = int(available[start])
	decor["entry_id"] = str(decor.family)+"_"+str(decor.variant)
	for offset: int in range(available.size()):
		var candidate := int(available[(start+offset)%available.size()])
		if nearby.has(candidate): continue
		decor["variant"] = candidate
		decor["entry_id"] = str(decor.family)+"_"+str(candidate)
		break
	return decor


static func allowed_variants(family: String, biome: String) -> Array:
	if (family == "supplies" and biome != "INDUSTRIAL") or (family == "bush" and biome != "SNOWFIELD"): return [0,1,3]
	return [0,1,2,3]


static func decoration_clear(point: Vector2i, plan: Dictionary, snapshot: Dictionary, accepted: Array) -> bool:
	var config: Dictionary = snapshot.get("match_config",{})
	var bounds := Rect2i(plan.get("bounds",Rect2i()))
	var terrain: Array = snapshot.get("terrain",config.get("terrain",[]))
	if not Navigation.point_clear(point,DISPLAY_FOOTPRINT,bounds,terrain): return false
	for zone: Dictionary in plan.get("home_zones",[]):
		if Vector2(point).distance_to(zone.position) < Landscape.HOME_CORE+DISPLAY_FOOTPRINT: return false
	for site: Dictionary in snapshot.get("sites",config.get("sites",[])):
		if Vector2(point).distance_to(Vector2(site.get("position",Vector2.ZERO))) < (100 if site.get("kind") == "RESOURCE" else 64)+DISPLAY_FOOTPRINT: return false
	for source: Dictionary in snapshot.get("resource_sources",config.get("sources",[])):
		if Vector2(point).distance_to(Vector2(source.get("position",Vector2.ZERO))) < float(source.get("radius",50))+DISPLAY_FOOTPRINT+8: return false
	for road: Dictionary in plan.get("roads",[]):
		var points: Array = road.get("points",[])
		for index: int in range(1,points.size()):
			var near := Geometry2D.get_closest_point_to_segment(Vector2(point),Vector2(points[index-1]),Vector2(points[index]))
			if Vector2(point).distance_to(near) < float(road.width)*0.5+DISPLAY_FOOTPRINT+8: return false
	for decor: Dictionary in accepted:
		if Vector2(point).distance_to(Vector2(decor.position)) < DISPLAY_FOOTPRINT*2+8: return false
	return true


static func terrain_observation(terrain: Dictionary, plan: Dictionary) -> Dictionary:
	if not Collection.enabled() or terrain.get("kind") not in ["TREE","MOUNTAIN"]: return terrain
	var visual := terrain.duplicate(false)
	var appearance: Dictionary = plan.get("obstacle_appearances",{}).get(_terrain_key(terrain),{})
	if appearance.is_empty(): appearance = _terrain_appearance(terrain,plan)
	visual["frontier_entry"] = str(appearance.entry_id)
	visual["frontier_biome"] = str(appearance.biome)
	return visual


static func _terrain_key(terrain: Dictionary) -> String:
	return str(terrain.get("id",""))+":"+str(terrain.get("position",Vector2.ZERO))


static func _obstacle_catalog() -> Dictionary:
	var result := {"broadleaf":[],"pine":[],"rock":[]}
	# Read the actual immutable library once per plan, not per frame or prop.
	# Four deterministic fallback identities let planner-only diagnostics run
	# before asset production, while full asset acceptance remains mandatory.
	for entry_id: String in Collection.entry_ids("obstacle"):
		var family := str(Collection.get_entry(entry_id).get("family",""))
		if result.has(family): result[family].append(entry_id)
	for family: String in result:
		if result[family].is_empty():
			for variant: int in range(4): result[family].append(family+"_"+str(variant))
	return result


static func _terrain_appearance(terrain: Dictionary, plan: Dictionary) -> Dictionary:
	var point := Vector2(terrain.get("position",Vector2.ZERO))
	var biome := biome_at(point,plan)
	var key := _key([plan.get("appearance_seed",plan.get("seed",0)),str(terrain.get("id","")),point,biome])
	var family := "rock" if terrain.get("kind") == "MOUNTAIN" else "pine" if biome == "SNOWFIELD" or (biome == "ROCKLAND" and key%3 != 0) else "broadleaf"
	var candidates: Array = plan.get("obstacle_catalog",{}).get(family,[])
	return {"entry_id":str(candidates[key%candidates.size()]) if not candidates.is_empty() else family+"_"+str(key%4),"biome":biome}


static func biome_at(point: Vector2, plan: Dictionary) -> String:
	var biome := str({"river-crossroads":"WOODLAND","highland-caldera":"ROCKLAND","debug-frontier":"DRYLAND"}.get(str(plan.get("map_id","")),"GRASSLAND"))
	var nearest := INF
	var winner := ""
	for zone: Dictionary in plan.get("home_zones",[]):
		var distance := point.distance_squared_to(Vector2(zone.position))
		var identity := str(zone.get("side_id",""))
		if distance <= float(zone.radius)*float(zone.radius) and (distance < nearest or (distance == nearest and identity < winner)):
			nearest = distance
			winner = identity
			biome = str(zone.biome)
	return biome


static func _context_at(point: Vector2i, snapshot: Dictionary) -> String:
	var config: Dictionary = snapshot.get("match_config",{})
	for site: Dictionary in snapshot.get("sites",config.get("sites",[])):
		if Vector2(point).distance_to(Vector2(site.get("position",Vector2.ZERO))) < 260: return "SETTLEMENT"
	var nearest := INF
	var context := "OPEN"
	var winner := ""
	for terrain: Dictionary in snapshot.get("terrain",config.get("terrain",[])):
		var distance := Vector2(point).distance_to(Vector2(terrain.get("position",Vector2.ZERO)))-float(terrain.get("radius",40))
		var identity := str(terrain.get("id",""))
		if distance > 180 or distance > nearest or (distance == nearest and identity >= winner): continue
		nearest = distance
		winner = identity
		context = "SHORE" if terrain.get("kind") in ["LAKE","RIVER"] else "FOREST" if terrain.get("kind") == "TREE" else "RIDGE"
	return context


static func _summary(decorations: Array[Dictionary]) -> Dictionary:
	var families: Dictionary = {}
	var contexts: Dictionary = {}
	for decor: Dictionary in decorations:
		families[str(decor.family)] = int(families.get(str(decor.family),0))+1
		contexts[str(decor.context)] = int(contexts.get(str(decor.context),0))+1
	return {"count":decorations.size(),"families":families,"contexts":contexts,"footprint":DISPLAY_FOOTPRINT,"visible_limit":VISIBLE_LIMIT}


static func _key(parts: Array) -> int:
	return var_to_str(parts).sha256_text().substr(0,15).hex_to_int()
