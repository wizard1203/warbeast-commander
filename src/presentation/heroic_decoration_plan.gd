extends RefCounted
## Detached, bounded scenery planning for the Heroic 2D view only. Every
## accepted envelope is deliberately stricter than the rules' body clearance.
## Nothing here creates a simulation object, selection target or collision.
const Catalog = preload("res://src/presentation/heroic_decor_catalog.gd")
const HomeTerrain = preload("res://src/presentation/heroic_home_terrain.gd")
const GroundDetail = preload("res://src/presentation/heroic_ground_detail.gd")
const ShorePackingV3 = preload("res://src/presentation/heroic_shore_packing_v3.gd")
const VERSION := "heroic-decoration-plan-m66-v1"
const TOTAL_LIMIT := 168
const PROP_LIMIT := 96
const HOME_TARGET := 12
const HOME_MINIMUM := 10
const MAX_CANDIDATES := 4096
const CONTEXT_TARGETS := {"SHORE":8,"ROADSIDE":14,"VILLAGE":12,"ROCK":12,"WILD":48}
const NATURAL_WILD := ["MEADOW","THICKET","ROCK_GARDEN","DEADWOOD"]
const BIOME_ONLY := ["GRAVESTONES_BONES","SNOW_CAIRN","MACHINE_SCRAP","FUNGAL_CRYSTAL"]
const HOME_FAMILIES := {
	"HUMAN":["WELL","FENCE_CORNER","CART","CAMP_SUPPLIES","THICKET","MEADOW"],
	"FOREST":["THICKET","DEADWOOD","FUNGAL_CRYSTAL","MEADOW"],
	"UNDEAD":["GRAVESTONES_BONES","RUIN_PILLARS","THICKET","DEADWOOD"],
	"MACHINE":["MACHINE_SCRAP","THICKET","BARRELS_CRATES","CART"],
	"HIGHLAND":["SNOW_CAIRN","THICKET","ROCK_GARDEN","CAMP_SUPPLIES"],
	"UNDERGROUND":["FUNGAL_CRYSTAL","THICKET","RUIN_PILLARS","ROCK_GARDEN"],
}
const ECOLOGY_PROFILES := {
	"borderlands":{"name":"meadow-woodland-mosaic","grove_threshold":0.47,"rock_threshold":0.72,"weights":{"MEADOW":4,"THICKET":3,"ROCK_GARDEN":2,"DEADWOOD":1}},
	"river-crossroads":{"name":"riverine-broadleaf-belts","grove_threshold":0.39,"rock_threshold":0.80,"weights":{"MEADOW":3,"THICKET":6,"ROCK_GARDEN":1,"DEADWOOD":2}},
	"highland-caldera":{"name":"conifer-scree-shelves","grove_threshold":0.56,"rock_threshold":0.51,"weights":{"MEADOW":1,"THICKET":3,"ROCK_GARDEN":6,"DEADWOOD":1}},
	"debug-frontier":{"name":"open-frontier-scrub","grove_threshold":0.55,"rock_threshold":0.66,"weights":{"MEADOW":4,"THICKET":2,"ROCK_GARDEN":4,"DEADWOOD":1}},
}


static func signature(snapshot: Dictionary, landscape: Dictionary) -> String:
	var facts := _facts(snapshot, landscape)
	return var_to_str(_identity(facts)).sha256_text()


static func build(snapshot: Dictionary, landscape: Dictionary) -> Dictionary:
	var facts := _facts(snapshot, landscape)
	var profile: Dictionary=ECOLOGY_PROFILES.get(facts.map_id,ECOLOGY_PROFILES.borderlands).duplicate(true)
	profile["map_id"]=facts.map_id
	var plan := {"version":VERSION,"entries":[],"summary":{},"failures":[],"ecology_profile":profile}
	var state := {"families":{},"contexts":{},"props":0,"attempts":0,"homes":[],"seen":{},"eligible_families":{}}
	if facts.bounds.size.x <= 0 or facts.bounds.size.y <= 0:
		plan.failures.append({"kind":"INPUT","reason":"INVALID_BOUNDS"})
		_finalize(plan, state)
		return plan
	var key := var_to_str(_identity(facts)).sha256_text()
	var candidates := _candidates(facts, key)
	for family: String in Catalog.families():
		for candidate: Dictionary in candidates:
			if family_allowed(family,candidate.context,candidate.faction_id):
				state.eligible_families[family] = true
				break
	# Allocate quiet, culturally coherent home frames first. Their full circles
	# still yield to roads, gathering areas, terrain and all other home cores.
	for home: Dictionary in facts.homes:
		var local: Array[Dictionary] = []
		for candidate: Dictionary in candidates:
			if candidate.context=="HOME" and candidate.get("side_id","")==home.id: local.append(candidate)
		var before_plan: Dictionary = plan.duplicate(true)
		var before_state: Dictionary = state.duplicate(true)
		var count := _allocate_home(plan,state,local,home,facts,key)
		var total_attempts := int(state.attempts)-int(before_state.attempts)
		# Crowded authored towns can strand legal shoulders after greedy grove
		# placement. Try at most eight deterministic alternative orders ONLY on
		# a shortfall. Each trial starts from the same other-home layout and uses
		# unchanged family minima, envelopes, racial surface and quotas.
		if count<HOME_TARGET and facts.road_mode=="TILED" and not local.is_empty():
			for trial: int in range(1,9):
				var trial_plan: Dictionary = before_plan.duplicate(true)
				var trial_state: Dictionary = before_state.duplicate(true)
				var ordered: Array[Dictionary] = []
				var shift := trial*local.size()/9
				for index: int in range(local.size()): ordered.append(local[(index+shift)%local.size()])
				var trial_count := _allocate_home(trial_plan,trial_state,ordered,home,facts,key)
				total_attempts += int(trial_state.attempts)-int(before_state.attempts)
				if trial_count>count:
					plan=trial_plan; state=trial_state; count=trial_count
				if count>=HOME_TARGET: break
		state.attempts=int(before_state.attempts)+total_attempts
	# The single compact-map shoreline is a scarce context. Reserve its valid
	# full-envelope reed pockets before generic family minima consume them.
	# This changes priority, not clearances, quotas, biome eligibility or caps.
	var shore_candidates: Array[Dictionary]=[]
	var shore_footprint:=float(Catalog.definition("SHORE_REEDS").footprint)
	for candidate: Dictionary in candidates:
		if candidate.context!="SHORE" or not _clear(candidate.position,shore_footprint,facts):continue
		var separated:=true
		for entry: Dictionary in plan.entries:
			if Vector2(candidate.position).distance_squared_to(Vector2(entry.position))<pow(shore_footprint+float(entry.footprint)+8.0,2):separated=false;break
		if separated:shore_candidates.append(candidate)
	for candidate: Dictionary in ShorePackingV3.select(shore_candidates,int(CONTEXT_TARGETS.SHORE),shore_footprint*2+8.0):
		_place_first(plan,state,candidate,["SHORE_REEDS"],facts,key)
	# Give every applicable family its three compositions before generic fill.
	# Context gates remain mandatory: e.g. a missing shore is a reported gap,
	# never permission to scatter reeds inland.
	for family: String in Catalog.families():
		if not state.eligible_families.has(family): continue
		for _variant: int in range(3):
			if int(state.families.get(family,0)) >= 3: break
			for candidate: Dictionary in candidates:
				if candidate.context == "HOME": continue
				if _place_first(plan,state,candidate,[family],facts,key): break
	# Environmental goals keep villages, road shoulders and shores composed,
	# rather than allowing a successful wild-meadow pass to consume the cap.
	for context: String in CONTEXT_TARGETS:
		for candidate: Dictionary in candidates:
			if int(state.contexts.get(context,0)) >= int(CONTEXT_TARGETS[context]): break
			if candidate.context != context: continue
			_place_first(plan,state,candidate,_family_order(state,candidate,key,facts),facts,key)
	# A large, deterministic pool of dry wild anchors fills ordinary open maps.
	# Once the foreground quota is spent, only ground compositions are eligible.
	for candidate: Dictionary in candidates:
		if plan.entries.size() >= TOTAL_LIMIT: break
		if candidate.context == "HOME": continue
		_place_first(plan,state,candidate,_family_order(state,candidate,key,facts),facts,key)
	_finalize(plan, state)
	return plan


static func _allocate_home(plan: Dictionary,state: Dictionary,candidates: Array[Dictionary],home: Dictionary,facts: Dictionary,key: String) -> int:
	var count := 0
	var families: Dictionary = {}
	var choices: Array = HOME_FAMILIES.get(home.faction_id,HOME_FAMILIES.HUMAN)
	# Preserve the two cultural groves and three memorial variants before fill.
	if "THICKET" in choices:
		for candidate: Dictionary in candidates:
			if count>=2: break
			if _place_first(plan,state,candidate,["THICKET"],facts,key):
				count+=1; families["THICKET"]=int(families.get("THICKET",0))+1
	if home.faction_id=="UNDEAD":
		for candidate: Dictionary in candidates:
			if int(families.get("GRAVESTONES_BONES",0))>=3 or count>=HOME_TARGET: break
			if _place_first(plan,state,candidate,["GRAVESTONES_BONES"],facts,key):
				count+=1; families["GRAVESTONES_BONES"]=int(families.get("GRAVESTONES_BONES",0))+1
	for candidate: Dictionary in candidates:
		if count>=HOME_TARGET: break
		var ordered: Array = []
		for offset: int in range(choices.size()): ordered.append(choices[(count+offset)%choices.size()])
		ordered.sort_custom(func(a: String,b: String) -> bool:
			var first := int(families.get(a,0))
			var second := int(families.get(b,0))
			return first<second if first!=second else choices.find(a)<choices.find(b))
		if _place_first(plan,state,candidate,ordered,facts,key):
			count+=1
			var family := str(plan.entries[-1].family)
			families[family]=int(families.get(family,0))+1
	state.homes.append({"side_id":home.id,"faction_id":home.faction_id,"count":count,"target":HOME_TARGET,
		"minimum":HOME_MINIMUM,"shortfall":maxi(0,HOME_TARGET-count),"family_counts":families})
	return count


static func placement_clear(position: Vector2, footprint: float, snapshot: Dictionary, landscape: Dictionary) -> bool:
	if not position.is_finite() or not is_finite(footprint) or footprint < 0.0: return false
	return _clear(position, footprint, _facts(snapshot,landscape))


static func _place_first(plan: Dictionary, state: Dictionary, candidate: Dictionary, families: Array, facts: Dictionary, key: String) -> bool:
	if plan.entries.size() >= TOTAL_LIMIT or state.seen.has(candidate.id): return false
	for family: String in families:
		var definition: Dictionary = Catalog.definition(family)
		if not family_allowed(family,candidate.context,candidate.faction_id): continue
		if definition.layer == "prop" and int(state.props) >= PROP_LIMIT: continue
		var footprint := float(definition.footprint)
		state.attempts += 1
		if not _clear(candidate.position,footprint,facts): continue
		var separated := true
		for entry: Dictionary in plan.entries:
			if Vector2(candidate.position).distance_squared_to(Vector2(entry.position)) < pow(footprint+float(entry.footprint)+8.0,2):
				separated = false
				break
		if not separated: continue
		var family_count := int(state.families.get(family,0))
		# Cycling a hash-offset composition guarantees variety without mutable RNG.
		var variant := (family_count+_number(key+":"+family)%3)%3
		# Snow homes use the existing conifer composition; the other two
		# thicket variants contain broadleaf oaks and bright meadow bushes.
		if facts.road_mode=="TILED" and candidate.faction_id=="HIGHLAND" and family=="THICKET": variant=1
		plan.entries.append({"id":"decor:"+candidate.id+":"+family.to_lower(),"family":family,
			"variant":variant,"position":Vector2i(candidate.position),"faction_id":candidate.faction_id,
			"context":candidate.context,"layer":str(definition.layer),"footprint":footprint,
			"scale":float(definition.display_scale),"map_id":facts.map_id,"habitat":_habitat(candidate,facts)})
		state.seen[candidate.id] = true
		state.families[family] = family_count+1
		state.contexts[candidate.context] = int(state.contexts.get(candidate.context,0))+1
		if definition.layer == "prop": state.props += 1
		return true
	return false


static func _family_order(state: Dictionary, candidate: Dictionary, key: String, facts: Dictionary) -> Array[String]:
	var choices: Array[String] = []
	for family: String in Catalog.families():
		if family_allowed(family,candidate.context,candidate.faction_id): choices.append(family)
	var profile: Dictionary=ECOLOGY_PROFILES.get(facts.map_id,ECOLOGY_PROFILES.borderlands)
	var habitat := _habitat(candidate,facts)
	choices.sort_custom(func(a: String,b: String) -> bool:
		# Fill coherent woodland/rock/meadow neighborhoods, while weighted
		# scarcity keeps the whole map from becoming one repeated ornament.
		var first := float(state.families.get(a,0))/float(profile.weights.get(a,1))
		var second := float(state.families.get(b,0))/float(profile.weights.get(b,1))
		if candidate.context=="WILD":
			if a==habitat: first*=0.18
			if b==habitat: second*=0.18
		if not is_equal_approx(first,second): return first < second
		return _number(key+candidate.id+a) < _number(key+candidate.id+b))
	return choices

static func _habitat(candidate: Dictionary,facts: Dictionary) -> String:
	if candidate.context=="ROCK": return "ROCK_GARDEN"
	if candidate.context=="SHORE": return "SHORE_REEDS"
	var point := Vector2(candidate.position)
	var field := GroundDetail.threshold(point*0.44,int(facts.seed)^0x6e66)
	var profile: Dictionary=ECOLOGY_PROFILES.get(facts.map_id,ECOLOGY_PROFILES.borderlands)
	if facts.map_id=="highland-caldera" and field>float(profile.rock_threshold): return "ROCK_GARDEN"
	if field>float(profile.grove_threshold): return "THICKET"
	if field<0.31:return "DEADWOOD"
	return "MEADOW"


static func family_allowed(family: String, context: String, faction: String) -> bool:
	var definition: Dictionary = Catalog.definition(family)
	if definition.is_empty() or context not in definition.contexts: return false
	# Neutral countryside is ecology, not a compulsory sample of every culture.
	# The authored ornaments still appear in their actual matching homelands.
	if context == "WILD" and family not in NATURAL_WILD: return false
	if faction.is_empty() and family in BIOME_ONLY: return false
	if context == "HOME" and faction not in definition.factions: return false
	return faction.is_empty() or definition.factions.is_empty() or faction in definition.factions


static func _finalize(plan: Dictionary, state: Dictionary) -> void:
	var family_counts: Dictionary = {}
	var family_shortfalls: Array = []
	var excluded_families: Array = []
	for family: String in Catalog.families():
		var count := int(state.families.get(family,0))
		if count > 0: family_counts[family] = count
		if not state.eligible_families.has(family):
			excluded_families.append({"family":family,"reason":"NO_MATCHING_BIOME_OR_CONTEXT"})
			continue
		if count < 3:
			var record := {"family":family,"count":count,"target":3,"shortfall":3-count}
			family_shortfalls.append(record)
			plan.failures.append(record.merged({"kind":"FAMILY","reason":"NO_SAFE_CONTEXT_CAPACITY"}))
	var context_counts: Dictionary = {}
	var context_shortfalls: Array = []
	for context: String in ["HOME","SHORE","ROADSIDE","VILLAGE","ROCK","WILD"]:
		var count := int(state.contexts.get(context,0))
		if count > 0: context_counts[context] = count
		if not CONTEXT_TARGETS.has(context): continue
		var target := int(CONTEXT_TARGETS[context])
		if count < target:
			var record := {"context":context,"count":count,"target":target,"shortfall":target-count}
			context_shortfalls.append(record)
			plan.failures.append(record.merged({"kind":"CONTEXT","reason":"NO_SAFE_CONTEXT_CAPACITY"}))
	for home: Dictionary in state.homes:
		if int(home.shortfall) > 0: plan.failures.append(home.merged({"kind":"HOME","reason":"NO_SAFE_HOME_CAPACITY"}))
	var shortfall: int = TOTAL_LIMIT-plan.entries.size()
	if shortfall > 0: plan.failures.append({"kind":"LAYOUT","reason":"NO_SAFE_DECORATION_CAPACITY","count":plan.entries.size(),"target":TOTAL_LIMIT,"shortfall":shortfall})
	plan.summary = {"total":plan.entries.size(),"target":TOTAL_LIMIT,"shortfall":shortfall,
		"props":int(state.props),"ground":plan.entries.size()-int(state.props),
		"family_counts":family_counts,"context_counts":context_counts,"home_counts":state.homes.duplicate(true),
		"family_shortfalls":family_shortfalls,"excluded_families":excluded_families,"context_shortfalls":context_shortfalls,"candidate_attempts":int(state.attempts)}


static func _candidates(facts: Dictionary, key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	# Four homes must not consume the entire finite pool before villages and
	# countryside are even considered. These generation budgets sum to4096;
	# they never change emitted quotas or legal-placement rules.
	if facts.homes.size()>2:
		seen["_budgets"]={"HOME":2048,"SHORE":512,"ROCK":384,"ROADSIDE":512,"VILLAGE":384,"WILD":256}
		seen["_counts"]={}
	for home: Dictionary in facts.homes:
		# Preserve the four original rings and append two interior shoulders.
		# The230 ring fits smaller civilian motifs outside the180px quiet core;
		# its full clearance cannot fit/steal a56px obligatory grove slot.
		# New real biomes/road shapes must not starve a racial home;
		# every extra candidate still passes the same full-envelope clearance.
		var radii: Array = [275,350,425,475,310,230]
		# Add radial shoulders INSIDE the same existing230..475 home band.
		# Angular refinement alone cannot find a narrow pocket between rings.
		if facts.road_mode=="TILED" and home.faction_id=="UNDEAD": radii.append_array([260,290,330,370,400,450])
		for ring: int in range(radii.size()):
			var radius := int(radii[ring])
			var rotation := _fraction(key+home.id+str(ring))*TAU
			# The memorial biome has narrow irregular arms. Sample its existing
			# rings more finely, retaining the same full-envelope road/scenery
			# clearance,12-home quota and168/96 caps; never fill with collisions.
			var samples := 64 if home.faction_id=="UNDEAD" else 32
			# Compact fixed-slot towns leave narrow legal biome shoulders.
			# Search those same rings more finely; keep their cultural surface,
			# full-envelope separation, home quota and global caps unchanged.
			if facts.road_mode=="TILED" and home.faction_id=="UNDERGROUND": samples=96
			for slot: int in range(samples):
				var angle := rotation+float(slot)*TAU/float(samples)
				var point: Vector2i=home.position+Vector2i(Vector2.from_angle(angle)*radius)
				# Wrong-surface anchors are not four-player home candidates; do
				# not spend their scarce budget then reclassify them as countryside.
				if facts.homes.size()>2 and HomeTerrain.faction_at(Vector2(point),facts.homes,int(facts.seed),"")!=home.faction_id:continue
				_add_candidate(result,seen,point,"HOME",home.faction_id,"home:"+home.id+":%d:%d"%[ring,slot],home.id)
	for terrain: Dictionary in facts.terrain:
		if terrain.kind in ["LAKE","RIVER"]:
			# Compact V3 streets leave narrower valid shore pockets. Search the
			# same shore context more finely; retain all clearances and quotas.
			for ring: int in range(4):
				for slot: int in range(128):
					var angle := float(slot)*TAU/128.0+_fraction(key+terrain.id)*0.4
					var point: Vector2i = terrain.position+Vector2i(Vector2.from_angle(angle)*(float(terrain.radius)+[58,76,112,154][ring]))
					_add_candidate(result,seen,point,"SHORE","","shore:"+terrain.id+":%d:%d"%[ring,slot])
		elif terrain.kind in ["MOUNTAIN","RUIN","MONUMENT","ROCK"]:
			for ring: int in range(3):
				for slot: int in range(48):
					var angle := float(slot)*TAU/48.0+_fraction(key+terrain.id)*0.4
					var point: Vector2i = terrain.position+Vector2i(Vector2.from_angle(angle)*(float(terrain.radius)+[82,136,192][ring]))
					if facts.homes.size()>2 and not _clear(point,46.0,facts):continue
					_add_candidate(result,seen,point,"ROCK","","rock:"+terrain.id+":%d:%d"%[ring,slot])
	for road: Dictionary in facts.roads:
		for index: int in range(1,road.points.size()):
			var start := Vector2(road.points[index-1])
			var end := Vector2(road.points[index])
			var distance := start.distance_to(end)
			if distance <= 0.0: continue
			var normal := (end-start).normalized().orthogonal()
			var samples := clampi(ceili(distance/200.0),1,24)
			for slot: int in range(samples):
				var point := start.lerp(end,(float(slot)+0.5)/samples)
				for side: int in [-1,1]:
					for shoulder: int in range(2):
						var offset: float = float(road.width)*0.5+[88.0,124.0][shoulder]
						_add_candidate(result,seen,Vector2i(point+normal*side*offset),"ROADSIDE","","road:"+road.id+":%d:%d:%d:%d"%[index,slot,side,shoulder])
	for site: Dictionary in facts.sites:
		if site.kind != "VILLAGE": continue
		for ring: int in range(2):
			for slot: int in range(16):
				var angle := float(slot)*TAU/16.0+_fraction(key+site.id)*0.5
				_add_candidate(result,seen,site.position+Vector2i(Vector2.from_angle(angle)*[158,225][ring]),"VILLAGE","","village:"+site.id+":%d:%d"%[ring,slot])
	# Retain the shared planner's safe anchors as candidates, not as authority or
	# random sprite IDs. Their old kinds inform only appropriate wild context.
	for anchor: Dictionary in facts.anchors:
		if anchor.kind == "HOMELAND": continue
		_add_candidate(result,seen,anchor.position,"WILD","","legacy:"+str(anchor.position.x)+":"+str(anchor.position.y))
	# Stratified dry-space fill is deliberately bounded. A hash jitter removes
	# the visible grid without consulting global RNG or live simulation state.
	var columns := clampi(ceili(sqrt(900.0*float(facts.bounds.size.x)/maxf(1.0,facts.bounds.size.y))),1,48)
	var rows := clampi(ceili(900.0/columns),1,48)
	for y: int in range(rows):
		for x: int in range(columns):
			var id := "wild:%d:%d"%[x,y]
			var point: Vector2i = facts.bounds.position+Vector2i(
				roundi((x+0.15+_fraction(key+id+"x")*0.7)*facts.bounds.size.x/columns),
				roundi((y+0.15+_fraction(key+id+"y")*0.7)*facts.bounds.size.y/rows))
			_add_candidate(result,seen,point,"WILD","",id)
	# Shore and roadside context can overlap a homeland's outer ring. Keep that
	# environmental context, but do not introduce another culture's graves,
	# scrap or snow there. Generic empty-faction families remain appropriate.
	for candidate: Dictionary in result:
		if facts.road_mode=="TILED":
			var surface := HomeTerrain.faction_at(Vector2(candidate.position),facts.homes,int(facts.seed),"")
			if candidate.context=="HOME" and surface!=candidate.faction_id:
				candidate.context="WILD"
				candidate.side_id=""
			candidate.faction_id=surface
			continue
		if candidate.context == "HOME": continue
		var nearest := INF
		for home: Dictionary in facts.homes:
			var distance := Vector2(candidate.position).distance_to(Vector2(home.position))
			if distance <= 500.0 and distance < nearest:
				nearest = distance
				candidate.faction_id = home.faction_id
	# Sort within each context, so input-array order and loop refactoring cannot
	# produce different ties. Home grouping remains available by side_id.
	for candidate: Dictionary in result: candidate["rank"] = _number(key+candidate.id)
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.context != b.context: return str(a.context)<str(b.context)
		return str(a.id)<str(b.id) if a.rank == b.rank else int(a.rank)<int(b.rank))
	return result


static func _add_candidate(result: Array[Dictionary], seen: Dictionary, position: Vector2i, context: String, faction: String, id: String, side_id: String = "") -> void:
	if result.size() >= MAX_CANDIDATES: return
	if seen.has("_budgets") and int(seen._counts.get(context,0))>=int(seen._budgets.get(context,0)): return
	var position_key := "%d:%d"%[position.x,position.y]
	if seen.has(position_key): return
	seen[position_key] = true
	if seen.has("_budgets"): seen._counts[context]=int(seen._counts.get(context,0))+1
	result.append({"id":id,"position":position,"context":context,"faction_id":faction,"side_id":side_id})


static func _clear(position: Vector2, footprint: float, facts: Dictionary) -> bool:
	var bounds: Rect2i = facts.bounds
	if position.x-footprint < bounds.position.x or position.y-footprint < bounds.position.y or position.x+footprint >= bounds.end.x or position.y+footprint >= bounds.end.y: return false
	for home: Dictionary in facts.homes:
		if position.distance_squared_to(Vector2(home.position)) < pow(180.0+footprint,2): return false
	for site: Dictionary in facts.sites:
		var radius := 100.0 if site.kind == "RESOURCE" else 64.0
		if position.distance_squared_to(Vector2(site.position)) < pow(radius+footprint+12.0,2): return false
	for source: Dictionary in facts.sources:
		if position.distance_squared_to(Vector2(source.position)) < pow(float(source.radius)+footprint+16.0,2): return false
	for terrain: Dictionary in facts.terrain:
		if position.distance_squared_to(Vector2(terrain.position)) < pow(float(terrain.radius)+footprint+8.0,2): return false
	for road_rect: Rect2i in facts.road_corridors:
		var rectangle := Rect2(road_rect)
		if position.distance_squared_to(position.clamp(rectangle.position,rectangle.end)) < pow(20.0+footprint,2): return false
	for road: Dictionary in ([] if not facts.road_corridors.is_empty() else facts.roads):
		for index: int in range(1,road.points.size()):
			var nearest := Geometry2D.get_closest_point_to_segment(position,Vector2(road.points[index-1]),Vector2(road.points[index]))
			if position.distance_squared_to(nearest) < pow(float(road.width)*0.5+20.0+footprint,2): return false
	return true


static func _facts(snapshot: Dictionary, landscape: Dictionary) -> Dictionary:
	var config: Dictionary = snapshot.get("match_config",{})
	var bounds := Rect2i()
	var raw: Variant = config.get("bounds",landscape.get("bounds",snapshot.get("bounds")))
	if raw is Rect2i: bounds = raw
	elif raw is Rect2: bounds = Rect2i(raw)
	else:
		var arena: Dictionary = snapshot.get("arena_bounds",{})
		if arena.has("min_x") and arena.has("max_x"):
			bounds = Rect2i(int(arena.min_x),int(arena.min_y),int(arena.max_x)-int(arena.min_x),int(arena.max_y)-int(arena.min_y))
	var facts := {"seed":int(snapshot.get("seed",landscape.get("seed",config.get("seed",1701)))),
		"map_id":str(config.get("map_id",snapshot.get("map_id",landscape.get("map_id","")))),
		"map_version":str(config.get("map_version",config.get("version",""))),
		"bounds":bounds,"road_mode":str(landscape.get("road_mode","")),"sites":[],"sources":[],"terrain":[],"homes":[],"roads":[],"road_corridors":landscape.get("road_corridors",[]).duplicate(),"anchors":[]}
	for category: String in ["sites","sources","terrain"]:
		var fallback: Array = snapshot.get("resource_sources",[]) if category == "sources" else snapshot.get(category,[])
		var records: Array = config.get(category,fallback)
		for item: Dictionary in records:
			facts[category].append({"id":str(item.get("id","")),"kind":str(item.get("kind","")),
				"position":Vector2i(item.get("position",Vector2i.ZERO)),"radius":float(item.get("radius",50.0 if category == "sources" else 0.0))})
		facts[category].sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			return _record_key(a)<_record_key(b))
	for side: Dictionary in config.get("sides",snapshot.get("sides",landscape.get("home_zones",[]))):
		facts.homes.append({"id":str(side.get("side_id",side.get("id",""))),"faction_id":str(side.get("faction_id","HUMAN")),
			"position":Vector2i(side.get("home",side.get("position",Vector2i.ZERO)))})
	facts.homes.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return str(a.id)<str(b.id))
	for road: Dictionary in landscape.get("roads",[]):
		var points: Array = []
		for point: Variant in road.get("points",[]): points.append(Vector2i(point))
		facts.roads.append({"id":str(road.get("id","")),"width":float(road.get("width",0.0)),"points":points})
	facts.roads.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return str(a.id)<str(b.id))
	for anchor: Dictionary in landscape.get("decorations",[]):
		facts.anchors.append({"position":Vector2i(anchor.get("position",Vector2i.ZERO)),"kind":str(anchor.get("kind",""))})
	facts.anchors.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var first := "%d:%d:%s"%[a.position.x,a.position.y,a.kind]
		var second := "%d:%d:%s"%[b.position.x,b.position.y,b.kind]
		return first<second)
	return facts


static func _identity(facts: Dictionary) -> Array:
	var result: Array = [VERSION,Catalog.VERSION,facts.seed,facts.map_id,facts.map_version,
		[facts.bounds.position.x,facts.bounds.position.y,facts.bounds.size.x,facts.bounds.size.y]]
	if facts.road_mode=="TILED": result.append(["TILED",HomeTerrain.VERSION])
	for category: String in ["sites","sources","terrain"]:
		var rows: Array = []
		for item: Dictionary in facts[category]: rows.append([item.id,item.kind,item.position.x,item.position.y,item.radius])
		result.append(rows)
	var homes: Array = []
	for home: Dictionary in facts.homes: homes.append([home.id,home.faction_id,home.position.x,home.position.y])
	result.append(homes)
	var roads: Array = []
	for road: Dictionary in facts.roads:
		var points: Array = []
		for point: Vector2i in road.points: points.append([point.x,point.y])
		roads.append([road.id,road.width,points])
	result.append(roads)
	var anchors: Array = []
	for anchor: Dictionary in facts.anchors: anchors.append([anchor.kind,anchor.position.x,anchor.position.y])
	result.append(anchors)
	return result


static func _record_key(record: Dictionary) -> String:
	return "%s:%s:%d:%d:%s"%[record.id,record.kind,record.position.x,record.position.y,str(record.radius)]


static func _number(key: String) -> int:
	return key.sha256_text().substr(0,12).hex_to_int()


static func _fraction(key: String) -> float:
	return float(_number(key)%1000003)/1000003.0
