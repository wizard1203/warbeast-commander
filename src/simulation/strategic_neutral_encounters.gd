extends RefCounted
## Finite neutral wilderness. This helper is owned by Combat, never a player,
## AI controller or public reward API. Positions and recipes are canonical.
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Catalog = preload("res://src/simulation/neutral_catalog.gd")
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const VERSION := "outposts-v4-finite-neutral-rewards-v1"
const SIDE := "NEUTRAL"
const HOME_SAFETY := 560
const AGGRO_RADIUS := 210
const LEASH_RADIUS := 320
const PICKUP_RADIUS := 160
const MAX_EVENTS := 24
const MAX_CAMPS := 48
const SCATTERED_HOME_DISTANCE := 620
const SCATTERED_SITE_DISTANCE := 210
const SCATTERED_SOURCE_DISTANCE := 160
const SCATTERED_CAMP_DISTANCE := 250
const MAX_DEFINITION_CACHE := 8
static var _definition_cache: Dictionary = {}
const MAX_HERO_DROPS := 128
const HERO_DROP_LIFETIME_TICKS := 12000
const BASELINE_CAMP_GOLD := {"SATELLITE":12,"SCATTERED":0,"VILLAGE":10,"RESOURCE":22,"TRIAL":42,"ESSENCE":42}
const RECIPES := {
	"SATELLITE":{"label":"小矿守卫","members":["RAIDER","RAIDER"],"reward":{"FOOD":0,"MATERIAL":18,"ESSENCE":0},"loot":["POTION","MANA_POTION"]},
	"SCATTERED":{"label":"荒径游兵群","members":["STRAGGLER","STRAGGLER"],"reward":{"FOOD":0,"MATERIAL":0,"ESSENCE":0},"loot":[]},
	"VILLAGE":{"label":"荒野游荡者", "members":["RAIDER","RAIDER"], "reward":{"FOOD":0,"MATERIAL":15,"ESSENCE":0}, "loot":["POTION","MANA_POTION","IRON_BLADE","WARD_MAIL","FIELD_BOOTS","LONGSIGHT"]},
	"RESOURCE":{"label":"资源守卫营", "members":["BRUTE","HUNTER","HUNTER"], "reward":{"FOOD":0,"MATERIAL":33,"ESSENCE":0}, "loot":["POTION","RESTORATION_DRAUGHT","SPELL_LENS","VITAL_CHARM"]},
	"TRIAL":{"label":"问鼎试境", "members":["TRIAL_GUARD","TRIAL_GUARD","TRIAL_SENTINEL"], "reward":{"FOOD":0,"MATERIAL":63,"ESSENCE":0}, "loot":["VANGUARD_BLADE","WARDEN_CREST","PATHFINDER_COMPASS","ARCANE_SIGIL"]},
	"ESSENCE":{"label":"深金矿镇守营", "members":["TRIAL_GUARD","TRIAL_GUARD","TRIAL_SENTINEL"], "reward":{"FOOD":0,"MATERIAL":63,"ESSENCE":0}, "loot":["VANGUARD_BLADE","WARDEN_CREST","PATHFINDER_COMPASS","ARCANE_SIGIL","ESSENCE_RESTORATION","ESSENCE_BULWARK"]},
}
const BODIES := Catalog.TEMPLATES
var _match: Dictionary = {}
var _seed := 1701
var _camps: Array[Dictionary] = []
var _loot: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _death_receipts: Dictionary = {}
var _pending_stock: Array[Dictionary] = []
var _pending_bounties: Array[Dictionary] = []

func _init(canonical_match: Dictionary = {}, seed: int = 1701) -> void:
	_match = canonical_match.duplicate(true)
	_seed = seed
	_camps = definitions(_match,seed)

static func definitions(canonical_match: Dictionary, seed: int = 1701) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not canonical_match.has("bounds") or not canonical_match.has("sites"): return result
	# Canonical geometry/seed only, bounded and detached. Reward admission may
	# ask for several victims in the same frame; never re-run map pathfinding
	# once per corpse, or let a rendered snapshot mutate the cached recipe.
	var cache_key:=var_to_bytes({"match":canonical_match,"seed":seed}).hex_encode().sha256_text()
	if _definition_cache.has(cache_key):return _definition_cache[cache_key].duplicate(true)
	var homes: Array[Vector2i] = []
	for slot: Dictionary in canonical_match.get("sides", []): homes.append(slot.home)
	var sites: Array = canonical_match.sites.duplicate(true)
	sites.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return str(a.id)<str(b.id))
	for site: Dictionary in sites:
		if not str(site.get("owner", "")).is_empty() or site.get("kind") not in ["VILLAGE","RESOURCE","SATELLITE"]: continue
		if not canonical_match.get("outpost_mode",false) and homes.any(func(home: Vector2i)->bool:return (home-Vector2i(site.position)).length_squared()<HOME_SAFETY*HOME_SAFETY): continue
		# Legacy kind ID names the strong guard recipe, not a spendable resource.
		var kind := "ESSENCE" if int(site.get("guardian_tier", 0)) >= 3 else str(site.kind)
		var record := _definition("camp:"+str(site.id),str(site.id),kind,site.position,canonical_match,result,seed)
		if not record.is_empty(): result.append(record)
		if result.size() >= MAX_CAMPS-1: break
	var trial := _trial_position(canonical_match, result, homes)
	if trial.has("position"):
		var record := _definition("camp:trial:01","","TRIAL",trial.position,canonical_match,result,seed)
		if not record.is_empty(): result.append(record)
	_add_scattered(canonical_match,result,homes,seed)
	if _definition_cache.size()>=MAX_DEFINITION_CACHE:_definition_cache.erase(_definition_cache.keys()[0])
	_definition_cache[cache_key]=result.duplicate(true)
	return result

static func _add_scattered(canonical_match: Dictionary,camps: Array,homes: Array,seed: int)->void:
	# A bounded deterministic layout, not fake RESOURCE sites. Early camps are
	# distributed per actual home, then the remaining camps fill the open field.
	var target:=8 if int(canonical_match.bounds.size.x)<3600 else 12
	var candidates: Array[Dictionary]=[]
	var bounds: Rect2i=canonical_match.bounds
	# Explicit miniature/empty test arenas are not authored strategic maps.
	if bounds.size.x<3000 or bounds.size.y<1800 or canonical_match.sites.is_empty():return
	var serial:=0
	for y: int in range(bounds.position.y+160,bounds.end.y-160,160):
		for x: int in range(bounds.position.x+160,bounds.end.x-160,160):
			var fold:=posmod(seed*109+serial*431,104729)
			var point:=Vector2i(x+fold%49-24,y+(fold/49)%49-24)
			serial+=1
			if not _scattered_clear(point,canonical_match,camps,homes):continue
			candidates.append({"position":point,"order":posmod(fold*37+seed,104729)})
	var added:=0
	for home: Vector2i in homes:
		candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
			var da:=Vector2(a.position).distance_squared_to(Vector2(home))
			var db:=Vector2(b.position).distance_squared_to(Vector2(home))
			return int(a.order)<int(b.order) if is_equal_approx(da,db) else da<db)
		for candidate: Dictionary in candidates:
			if Vector2(candidate.position).distance_to(Vector2(home))>1000:break
			if not _scattered_clear(candidate.position,canonical_match,camps,homes):continue
			var record:=_scattered_definition(added,candidate.position,canonical_match,camps,seed)
			if record.is_empty():continue
			camps.append(record);added+=1;break
	# Seed order spreads remaining opportunities instead of stacking all camps
	# around the first home or making every random map identical.
	candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return int(a.order)<int(b.order))
	for candidate: Dictionary in candidates:
		if added>=target or camps.size()>=MAX_CAMPS:break
		if not _scattered_clear(candidate.position,canonical_match,camps,homes):continue
		var record:=_scattered_definition(added,candidate.position,canonical_match,camps,seed)
		if record.is_empty():continue
		camps.append(record);added+=1
	assert(added>=8 and added<=12,"Canonical field must admit 8–12 safe scattered camps")

static func _scattered_clear(point: Vector2i,canonical_match: Dictionary,camps: Array,homes: Array)->bool:
	if not Navigation.point_clear(point,95,canonical_match.bounds,canonical_match.get("terrain",[])):return false
	for home: Vector2i in homes:
		if Vector2(point).distance_to(Vector2(home))<SCATTERED_HOME_DISTANCE:return false
	for site: Dictionary in canonical_match.sites:
		if Vector2(point).distance_to(Vector2(site.position))<SCATTERED_SITE_DISTANCE:return false
	for source: Dictionary in canonical_match.get("sources",[]):
		if Vector2(point).distance_to(Vector2(source.position))<SCATTERED_SOURCE_DISTANCE:return false
	for camp: Dictionary in camps:
		if Vector2(point).distance_to(Vector2(camp.position))<SCATTERED_CAMP_DISTANCE:return false
	for home: Vector2i in homes:
		if Navigation.find_path(home,point,22,canonical_match.bounds,canonical_match.get("terrain",[])).is_empty():return false
	return true

static func _scattered_definition(index: int,position: Vector2i,canonical_match: Dictionary,camps: Array,seed: int)->Dictionary:
	var record:=_definition("camp:scattered:%02d"%(index+1),"","SCATTERED",position,canonical_match,camps,seed)
	if record.is_empty():return {}
	# One third carry a third equally weak member. This changes a finite camp
	# recipe at creation, never its body stats, XP or loot after being attacked.
	if posmod(seed+index,3)==0:
		var profile:=Catalog.select_profile("STRAGGLER",seed,record.id,2)
		var occupied: Array=[]
		for camp: Dictionary in camps:occupied.append_array(camp.members)
		occupied.append_array(record.members)
		var placed:=_member_position(position,int(BODIES.STRAGGLER.radius),canonical_match,occupied,2)
		if placed.is_empty():return {}
		var id:="%s:unit:03"%record.id
		record.members.append({"id":id,"archetype":"STRAGGLER","variant_id":profile.id,"level":profile.level,"series_id":profile.series_id,"profile":profile,"position":placed.position,"radius":BODIES.STRAGGLER.radius})
		record.member_ids.append(id)
		record.xp_pool=int(record.xp_pool)+int(profile.xp_reward)
		record.remaining_count=record.members.size()
	_assign_scattered_bounties(record)
	return record

static func scattered_bounty_total(member_count:int)->int:
	return roundi(float(maxi(0,member_count))*7.5)

static func _assign_scattered_bounties(camp:Dictionary)->void:
	# The *camp total* rounds once:2*7.5=>15,3*7.5=>23. Largest
	# remainders go to stable member IDs, never to kill order or the viewer.
	var ids:Array=camp.member_ids.duplicate()
	ids.sort()
	var total:=scattered_bounty_total(ids.size())
	var whole:int=total/maxi(1,ids.size())
	var extra:int=total%maxi(1,ids.size())
	var bounties:Dictionary={}
	for index:int in range(ids.size()):
		bounties[str(ids[index])]={"MATERIAL":whole+(1 if index<extra else 0),"FOOD":0,"ESSENCE":0}
	for member:Dictionary in camp.members:member["bounty"]=bounties[str(member.id)].duplicate(true)
	camp["member_bounties"]=bounties
	camp["total_bounty"]=total

static func _definition(id: String,site_id: String,kind: String,position: Vector2i,canonical_match: Dictionary,previous: Array,seed: int) -> Dictionary:
	var recipe: Dictionary = RECIPES[kind]
	var members: Array[Dictionary] = []
	var occupied: Array[Dictionary] = []
	for camp: Dictionary in previous: occupied.append_array(camp.members)
	for index: int in range(recipe.members.size()):
		var archetype: String = recipe.members[index]
		var profile := Catalog.select_profile(archetype,seed,id,index)
		var placed := _member_position(position,int(BODIES[archetype].radius),canonical_match,occupied+members,index)
		if placed.is_empty(): return {}
		members.append({"id":"%s:unit:%02d" % [id,index+1], "archetype":archetype,"variant_id":profile.id,"level":profile.level,"series_id":profile.series_id,"profile":profile,"position":placed.position,"radius":BODIES[archetype].radius})
	var member_ids: Array[String] = []
	var xp_pool := 0
	for member: Dictionary in members:
		member_ids.append(member.id)
		xp_pool += int(member.profile.xp_reward)
	var loot_plan:=_loot_plan(id,kind,seed)
	var result:Dictionary={"id":id,"site_id":site_id,"kind":kind,"label":recipe.label,"position":position,"radius":110 if kind=="SCATTERED" else 220 if kind in ["TRIAL","ESSENCE"] else 180,"members":members,"member_ids":member_ids,"remaining_count":members.size(),"state":"GUARDED","cleared_tick":-1,"winner_side":"","reward":recipe.reward.duplicate(true),"xp_pool":xp_pool,"loot_id":"loot:"+id,"loot_ids":loot_plan.loot_ids,"loot_items":loot_plan.loot_items,"loot_policy":"ONE_PLUS_SEEDED_HALF" if not loot_plan.loot_ids.is_empty() else "NONE","receipt_id":id+":once","catalog_version":Catalog.VERSION,"reward_version":VERSION}
	if kind=="SCATTERED":_assign_scattered_bounties(result)
	return result

static func _loot_plan(camp_id:String,kind:String,seed:int)->Dictionary:
	var choices:Array=RECIPES[kind].loot
	var result:Dictionary={"loot_ids":[],"loot_items":[]}
	if choices.is_empty():return result
	# Preserve the old first-item selection. A separate, fully local salted
	# fold determines the extra instance; no global RNG or later reroll.
	var variant:=seed
	for index:int in range(camp_id.length()):variant=posmod(variant*31+camp_id.unicode_at(index),104729)
	result.loot_ids.append("loot:"+camp_id)
	result.loot_items.append(choices[posmod(variant,choices.size())])
	var second:=posmod(seed,2147483647)
	var key:=camp_id+":v4:second-loot"
	for index:int in range(key.length()):second=posmod(second*31+key.unicode_at(index),2147483647)
	if posmod(second,2)==0:
		result.loot_ids.append("loot:"+camp_id+":02")
		result.loot_items.append(choices[posmod(second/2,choices.size())])
	return result

static func _member_position(origin: Vector2i,radius: int,canonical_match: Dictionary,occupied: Array,index: int) -> Dictionary:
	var directions: Array[Vector2i] = [Vector2i(-1,1),Vector2i(1,1),Vector2i(0,-1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(1,-1),Vector2i(-1,-1)]
	for ring: int in [48,80,112,144]:
		for offset: int in range(directions.size()):
			var point := origin+directions[(index+offset)%directions.size()]*ring
			if not Navigation.point_clear(point,radius+4,canonical_match.bounds,canonical_match.get("terrain",[])): continue
			var clear := true
			for source: Dictionary in canonical_match.get("sources",[]):
				var reach := radius+int(source.get("radius",50))+4
				if (point-Vector2i(source.position)).length_squared()<reach*reach: clear=false; break
			if not clear: continue
			for body: Dictionary in occupied:
				var reach := radius+int(body.radius)+6
				if (point-Vector2i(body.position)).length_squared()<reach*reach: clear=false; break
			if clear: return {"position":point}
	return {}

static func _trial_position(canonical_match: Dictionary,camps: Array,homes: Array) -> Dictionary:
	var center: Vector2i = canonical_match.bounds.get_center()
	var directions: Array[Vector2i] = [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT,Vector2i(-1,-1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1)]
	for ring: int in [400,560,720,880,1040]:
		for direction: Vector2i in directions:
			var point := center+direction*ring
			if not Navigation.point_clear(point,150,canonical_match.bounds,canonical_match.get("terrain",[])): continue
			if homes.any(func(home: Vector2i)->bool:return (home-point).length_squared()<740*740): continue
			if canonical_match.sites.any(func(site: Dictionary)->bool:return (Vector2i(site.position)-point).length_squared()<240*240): continue
			if camps.any(func(camp: Dictionary)->bool:return (Vector2i(camp.position)-point).length_squared()<280*280): continue
			var paths := true
			for home: Vector2i in homes:
				if Navigation.find_path(home,point,22,canonical_match.bounds,canonical_match.get("terrain",[])).is_empty(): paths=false; break
			if paths: return {"position":point}
	return {}

static func definition(canonical_match: Dictionary,camp_id: String,seed: int = 1701) -> Dictionary:
	for camp: Dictionary in definitions(canonical_match,seed):
		if camp.id==camp_id: return camp
	return {}

func install(combat: RefCounted) -> void:
	for camp: Dictionary in _camps:
		# A reserved neutral formation only satisfies the physical body contract;
		# it is never returned as a commandable player army or AI controller.
		combat._warbands[camp.id] = {"id":camp.id,"number":0,"side":SIDE,"faction_id":SIDE,"reserve":true,"neutral":true,"anchor":camp.position,"destination":camp.position,"home_anchor":camp.position,"facing":"EAST","formation":"STEADY","unit_type":"neutral","intent":"HOLD","target_warband_id":"","target_base_id":"","member_ids":[],"living_count":0,"route":[],"route_target":camp.position,"route_geometry":""}
		for member: Dictionary in camp.members:
			var body: Dictionary = combat._new_body(member.id,SIDE,"hinge_guard",camp.id,member.position)
			var profile: Dictionary = member.profile
			body.merge(profile.duplicate(true),true)
			# Neutral camp placement/profile keeps its own physical and visual size.
			# _new_body's temporary infantry footprint is not its final identity.
			body["visual_radius"]=int(profile.radius)
			body.merge({"id":member.id,"side":SIDE,"faction_id":SIDE,"neutral":true,"neutral_archetype":member.archetype,"neutral_variant_id":profile.id,"neutral_level":profile.level,"neutral_series_id":profile.series_id,"neutral_origin_faction_id":profile.origin_faction_id,"neutral_base_stats":profile.duplicate(true),"neutral_skill":profile.skill.duplicate(true),"neutral_skill_ready_tick":40,"neutral_guard_until_tick":-1,"neutral_guard_armor":0,"camp_id":camp.id,"guarding_site_id":camp.site_id,"home_position":member.position,"camp_position":camp.position,"leashing":false,"last_leash_tick":-1000000,"population":0,"tags":["NEUTRAL"],"role":"NEUTRAL","movement_layer":"GROUND","trait_id":"CAMP_GUARD","trait_name":"等级%d · %s" % [profile.level,profile.series_label],"trait_description":profile.description+("\n"+str(profile.skill.label)+"："+str(profile.skill.description) if not profile.skill.is_empty() else "")},true)
			body.hp = body.max_hp
			body["mana"]=int(body.get("max_mana",0))
			if member.has("bounty"):
				body["neutral_bounty"]=member.bounty.duplicate(true)
				body.trait_description+=" 本单位击杀赏金%d金币。"%int(member.bounty.get("MATERIAL",0))
			combat._soldiers[member.id] = body
	combat._reindex()

static func refresh_stats(unit: Dictionary,tick: int) -> void:
	var stats: Dictionary = unit.get("neutral_base_stats",BODIES[unit.neutral_archetype])
	var slow := 0.0
	var armor_break := 0.0
	for status: Dictionary in unit.get("combat_statuses",{}).values():
		if int(status.expires_tick)<=tick: continue
		if status.kind=="SLOW": slow=maxf(slow,float(status.power))
		if status.kind=="ARMOR_BREAK": armor_break=maxf(armor_break,float(status.power))
	for field: String in ["max_hp","damage","attack_range","attack_cooldown_ticks"]: unit[field]=int(stats[field])
	var guard := int(unit.get("neutral_guard_armor",0)) if int(unit.get("neutral_guard_until_tick",-1))>tick else 0
	unit.armor=maxf(0,float(stats.armor)-armor_break+guard)
	unit.speed_exact=maxf(1.0,float(stats.speed)*(100-clampf(slow,0,60))/100.0)
	unit.speed=maxi(1,roundi(float(unit.speed_exact)))
	unit.hp=mini(int(unit.hp),int(unit.max_hp))

static func choose_target(unit: Dictionary,phase: String,combat: RefCounted) -> Dictionary:
	if phase!="BATTLE" or int(unit.hp)<=0 or combat._stunned(unit): return {}
	var home: Vector2i = unit.home_position
	if (Vector2i(unit.position)-home).length_squared()>LEASH_RADIUS*LEASH_RADIUS:
		unit.leashing=true
		unit.last_leash_tick=combat._tick
	if bool(unit.leashing):
		if (Vector2i(unit.position)-home).length_squared()<=24*24:
			unit.hp=unit.max_hp
			unit.combat_statuses.clear()
			unit.neutral_guard_until_tick=-1
			unit.neutral_guard_armor=0
			refresh_stats(unit,combat._tick)
			unit.leashing=false
			unit.last_leash_tick=combat._tick
		return {}
	if combat._tick-int(unit.last_leash_tick)<20: return {}
	var result := {}
	var best := AGGRO_RADIUS*AGGRO_RADIUS+1
	for target: Dictionary in combat.neutral_target_candidates_m76():
		if target.get("side") not in combat._sides or int(target.get("hp",0))<=0 or not combat._can_attack(unit,target): continue
		# Structures inside the existing camp bounds are hostile intruders too;
		# retain the shared fixed/attackability contract and ordinary workers.
		if target.has("building_type") and not combat._is_worker(target) and not combat._attackable_building(target): continue
		if (Vector2i(target.position)-home).length_squared()>LEASH_RADIUS*LEASH_RADIUS: continue
		var distance := (Vector2i(unit.position)-Vector2i(target.position)).length_squared()
		var retaliating: bool = str(unit.get("last_damage_source_id",""))==str(target.id) and combat._tick-int(unit.get("last_damage_tick",-1000000))<=100
		var reach := LEASH_RADIUS if retaliating else AGGRO_RADIUS
		if distance>reach*reach: continue
		if result.is_empty() or distance<best or (distance==best and str(target.id)<str(result.id)):
			best=distance
			result=target
	# A lost target starts a real return-and-recover phase, not a permanent
	# wounded outpost following bait across the world. Damage remains legal.
	if result.is_empty() and not str(unit.get("target_id","")).is_empty():
		unit.leashing=true
		unit.last_leash_tick=combat._tick
	return result

static func desired_position(unit: Dictionary,target: Dictionary,combat: RefCounted) -> Vector2i:
	if int(unit.hp)<=0 or combat._movement_controlled(unit): return unit.position
	if bool(unit.leashing): return unit.home_position
	if not target.is_empty():
		if combat._in_attack_range(unit,target): return unit.position
		# A structure's center is blocked navigation space. Use the same
		# exterior approach as ordinary combat without bypassing collision.
		if combat._buildings.has(target.id) and not combat._is_worker(target):
			return combat._approach_point(unit.position,target.position,int(unit.radius)+int(target.get("radius",32))+2)
		return target.position
	return unit.home_position

func advance_skills(combat: RefCounted,targets: Dictionary,damage: Dictionary,killers: Dictionary) -> void:
	# Called only by authoritative BATTLE settlement, before ordinary attacks.
	# One eligible leader in each trial/essence camp, never a new hero/army.
	# Requiring the chosen legal target also excludes preparation and passive
	# return phases: their choose_target result is empty, not a new free scan.
	for camp: Dictionary in _camps:
		if camp.state=="CLEARED" or camp.kind not in ["TRIAL","ESSENCE"]: continue
		for id: String in camp.member_ids:
			var unit: Dictionary = combat._soldiers.get(id,{})
			if unit.is_empty():continue
			var ability: Dictionary = unit.get("neutral_skill",{})
			if ability.is_empty() or int(unit.hp)<=0 or combat._stunned(unit) or bool(unit.leashing) or combat._tick<int(unit.neutral_skill_ready_tick) or int(unit.get("mana",0))<int(ability.get("mana_cost",0)): continue
			var primary: Dictionary = targets.get(id,{})
			if not _skill_target_valid(unit,primary,ability,combat,damage): continue
			var victims: Array[Dictionary] = [primary]
			if int(ability.max_targets)>1:
				var candidates: Array[Dictionary] = []
				for target: Dictionary in combat._ordered_units():
					if target.id!=primary.id and _skill_target_valid(unit,target,ability,combat,damage): candidates.append(target)
				candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
					var da: int=(Vector2i(a.position)-Vector2i(unit.position)).length_squared()
					var db: int=(Vector2i(b.position)-Vector2i(unit.position)).length_squared()
					return str(a.id)<str(b.id) if da==db else da<db)
				for target: Dictionary in candidates:
					if victims.size()>=int(ability.max_targets): break
					victims.append(target)
			unit.neutral_skill_ready_tick = combat._tick+int(ability.cooldown_ticks)
			unit.mana=int(unit.get("mana",0))-int(ability.get("mana_cost",0))
			unit.last_skill_targets = []
			for target: Dictionary in victims:
				var amount:int=combat._resolve_damage(float(ability.damage),str(ability.attack_type),target,unit,false)
				var actual := mini(amount,maxi(0,int(target.hp)-int(damage.get(target.id,0))))
				if actual<=0: continue
				damage[target.id] = int(damage.get(target.id,0))+actual
				if not killers.has(target.id): killers[target.id]=id
				combat._record_damage(target,unit,actual,str(ability.attack_type))
				combat._apply_signature(unit,target,ability)
				var control := str(ability.get("control",""))
				if control in ["ROOT","STUN"]:
					var field := "root_until_tick" if control=="ROOT" else "stun_until_tick"
					var previous_until:=int(target.get(field,-1))
					target[field] = maxi(int(target.get(field,-1)),combat._tick+Damage.control_ticks(int(ability.control_ticks),target))
					target["root_source_faction" if control=="ROOT" else "stun_source_faction"] = SIDE
					if int(target[field])>previous_until:combat._feedback("CONTROL",unit,target,{"skill_id":ability.id,"status_kind":control,"expires_tick":target[field]})
				unit.last_skill_targets.append({"id":target.id,"position":target.position,"damage":actual,"attack_type":ability.attack_type})
			if int(ability.get("self_heal",0))>0:
				var hp_before:=int(unit.hp)
				unit.hp=mini(int(unit.max_hp),int(unit.hp)+int(ability.self_heal))
				combat._healing_feedback_r9(unit,unit,int(unit.hp)-hp_before,{"id":ability.id})
			if int(ability.get("self_armor",0))>0:
				unit.neutral_guard_armor = int(ability.self_armor)
				unit.neutral_guard_until_tick = combat._tick+int(ability.self_armor_ticks)
				refresh_stats(unit,combat._tick)
			combat._record_action(unit,"SKILL_"+str(ability.id),primary.position)
			unit.last_action_skill_level = 1
			unit.last_action_radius = int(ability.range)
			unit.last_action_attack_type = str(ability.attack_type)
			unit.last_skill_tick = combat._tick
			unit.last_skill_id = ability.id
			unit.last_skill_target_position = primary.position
			unit.last_skill_level = 1
			unit.last_skill_radius = int(ability.range)

static func _skill_target_valid(unit: Dictionary,target: Dictionary,ability: Dictionary,combat: RefCounted,damage: Dictionary) -> bool:
	if target.is_empty() or not combat._soldiers.has(str(target.get("id",""))) or target.get("side") not in combat._sides or int(target.get("hp",0))<=int(damage.get(target.get("id",""),0)): return false
	if not combat._can_attack(unit,target): return false
	if (Vector2i(target.position)-Vector2i(unit.home_position)).length_squared()>LEASH_RADIUS*LEASH_RADIUS: return false
	return (Vector2i(target.position)-Vector2i(unit.position)).length_squared()<=int(ability.range)*int(ability.range)

func record_death(killer_id: String,victim_id: String,combat: RefCounted,killer_side: String="") -> void:
	if not combat._soldiers.has(victim_id) or not bool(combat._soldiers[victim_id].get("neutral",false)) or int(combat._soldiers[victim_id].hp)>0 or _death_receipts.has(victim_id): return
	var side := killer_side
	if combat._soldiers.has(killer_id): side=str(combat._soldiers[killer_id].side)
	elif combat._buildings.has(killer_id): side=str(combat._buildings[killer_id].side)
	if side not in combat._sides: return
	_death_receipts[victim_id]={"side":side,"tick":combat._tick,"source_id":killer_id}
	for camp: Dictionary in _camps:
		if camp.id!=combat._soldiers[victim_id].camp_id: continue
		if camp.kind=="SCATTERED":
			combat._soldiers[victim_id]["neutral_bounty_winner"]=side
			_pending_bounties.append({"receipt_id":"bounty:"+victim_id,"camp_id":camp.id,"victim_id":victim_id,"side":side,"tick":combat._tick})
			_event({"type":"NEUTRAL_BOUNTY","tick":combat._tick,"position":combat._soldiers[victim_id].position,"camp_id":camp.id,"side":side,"victim_id":victim_id,"reward":camp.member_bounties[victim_id].duplicate(true)})
		# Combat applies a whole damage batch before crediting each corpse.
		# The first receipt can already see zero living members; its camp clear
		# must not suppress distinct remaining deaths from that same batch.
		# Per-victim receipts above and whole-camp settlement below stay separate.
		if camp.state=="CLEARED": return
		var remaining := 0
		for id: String in camp.member_ids:
			if int(combat._soldiers.get(id,{}).get("hp",0))>0: remaining+=1
		camp.remaining_count=remaining
		if remaining>0: return
		camp.state="CLEARED"
		camp.cleared_tick=combat._tick
		camp.winner_side=side
		for id: String in camp.member_ids:
			if combat._soldiers.has(id):combat._soldiers[id]["camp_clear_winner"]=side
		if camp.kind=="SCATTERED":
			_event({"type":"CAMP_CLEARED","tick":combat._tick,"position":camp.position,"camp_id":camp.id,"side":side,"item_id":"","reward":camp.reward.duplicate(true)})
			return
		_pending_stock.append({"receipt_id":camp.receipt_id,"camp_id":camp.id,"side":side,"tick":combat._tick})
		for index:int in range(camp.loot_ids.size()):
			var offset:=Vector2i.ZERO if camp.loot_ids.size()==1 else Vector2i(-16 if index==0 else 16,0)
			_loot.append({"id":camp.loot_ids[index],"camp_id":camp.id,"position":Vector2i(camp.position)+offset,"item_id":camp.loot_items[index],"owner":side,"state":"AVAILABLE","recipient_id":"","created_tick":combat._tick,"collected_tick":-1,"pickup_radius":PICKUP_RADIUS})
		_event({"type":"CAMP_CLEARED","tick":combat._tick,"position":camp.position,"camp_id":camp.id,"side":side,"item_id":camp.loot_items[0] if not camp.loot_items.is_empty() else "","item_ids":camp.loot_items.duplicate(),"loot_ids":camp.loot_ids.duplicate(),"reward":camp.reward.duplicate(true)})
		return

func record_hero_death(hero_id: String,combat: RefCounted) -> void:
	if not combat._hero_data.has(hero_id) or not combat._soldiers.has(hero_id): return
	var body: Dictionary = combat._soldiers[hero_id]
	if int(body.hp) > 0: return
	var hero: Dictionary = combat._hero_data[hero_id]
	var generation := int(body.get("life_generation", 1))
	# One bounded marker per persistent officer, not a receipt for every death.
	if int(hero.get("equipment_drop_life", 0)) >= generation: return
	hero["equipment_drop_life"] = generation
	var dropped := Items.drop_advanced(hero)
	if dropped.is_empty(): return
	var tick := maxi(0, int(combat._tick))
	_prune_hero_loot(tick, dropped.size())
	var origin := "hero:%s:life:%d" % [hero_id, generation]
	for index: int in range(dropped.size()):
		var item_id: String = dropped[index]
		# Tiny deterministic offsets keep the four possible icons distinct.
		var offset: Vector2i = [Vector2i(-18,-10),Vector2i(18,-10),Vector2i(-18,16),Vector2i(18,16)][index % 4]
		var position: Vector2i = body.position + offset
		position.x = clampi(position.x, combat._bounds.position.x, combat._bounds.end.x)
		position.y = clampi(position.y, combat._bounds.position.y, combat._bounds.end.y)
		_loot.append({"id":"loot:%s:%s:%d" % [origin,item_id,index],"camp_id":origin,"position":position,"item_id":item_id,"owner":"","pickup_scope":"PUBLIC","hero_drop":true,"source_hero_id":hero_id,"source_side":body.side,"life_generation":generation,"state":"AVAILABLE","recipient_id":"","created_tick":tick,"expires_tick":tick+HERO_DROP_LIFETIME_TICKS,"collected_tick":-1,"pickup_radius":PICKUP_RADIUS})
	_event({"type":"HERO_EQUIPMENT_DROPPED","tick":tick,"position":body.position,"camp_id":origin,"side":body.side,"unit_id":hero_id,"life_generation":generation,"item_ids":dropped.duplicate(),"reason":"HERO_DEATH"})

func _prune_hero_loot(tick: int, incoming: int = 0) -> void:
	for index: int in range(_loot.size()-1,-1,-1):
		var loot: Dictionary = _loot[index]
		if not bool(loot.get("hero_drop", false)): continue
		if loot.state == "AVAILABLE" and tick < int(loot.expires_tick): continue
		if loot.state == "AVAILABLE": _expire_loot(loot,tick,"TTL")
		_loot.remove_at(index)
	var hero_count := _loot.filter(func(entry: Dictionary)->bool:return bool(entry.get("hero_drop",false))).size()
	while hero_count + incoming > MAX_HERO_DROPS:
		var removed := false
		for index: int in range(_loot.size()):
			if not bool(_loot[index].get("hero_drop",false)): continue
			_expire_loot(_loot[index],tick,"GROUND_LIMIT")
			_loot.remove_at(index)
			hero_count -= 1
			removed = true
			break
		if not removed: break

func _expire_loot(loot: Dictionary,tick: int,reason: String) -> void:
	_event({"type":"LOOT_EXPIRED","tick":tick,"position":loot.position,"camp_id":loot.camp_id,"side":loot.source_side,"item_id":loot.item_id,"loot_id":loot.id,"hero_drop":true,"reason":reason})

func settle(world: RefCounted,combat: RefCounted,tick: int) -> void:
	for receipt: Dictionary in _pending_bounties.duplicate(true):
		receipt.tick=tick
		var result: Dictionary=world._grant_neutral_bounty(receipt)
		if result.get("accepted",false) or result.get("error","")=="NEUTRAL_BOUNTY_ALREADY_CLAIMED":
			for index: int in range(_pending_bounties.size()-1,-1,-1):
				if _pending_bounties[index].receipt_id==receipt.receipt_id:_pending_bounties.remove_at(index)
	for receipt: Dictionary in _pending_stock.duplicate(true):
		# A skill can clear a camp between fixed ticks. World settles the same
		# receipt on its next authoritative tick, without trusting its old time.
		receipt.tick=tick
		var result: Dictionary = world._grant_neutral_stock(receipt)
		if result.get("accepted",false) or result.get("error","")=="NEUTRAL_ALREADY_CLAIMED":
			for index: int in range(_pending_stock.size()-1,-1,-1):
				if _pending_stock[index].receipt_id==receipt.receipt_id: _pending_stock.remove_at(index)
	_prune_hero_loot(tick)
	for loot: Dictionary in _loot:
		if loot.state!="AVAILABLE": continue
		var candidates: Array[Dictionary] = []
		for id: String in combat._sorted_keys(combat._hero_data):
			var body: Dictionary = combat._hero_body_r9(id)
			if (bool(loot.get("hero_drop",false)) or body.side==loot.owner) and int(body.hp)>0 and (Vector2i(body.position)-Vector2i(loot.position)).length_squared()<=PICKUP_RADIUS*PICKUP_RADIUS: candidates.append(body)
		candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
			var da: int=(Vector2i(a.position)-Vector2i(loot.position)).length_squared()
			var db: int=(Vector2i(b.position)-Vector2i(loot.position)).length_squared()
			return str(a.id)<str(b.id) if da==db else da<db)
		for body: Dictionary in candidates:
			if pickup({"type":"PICKUP_LOOT","unit_id":body.id,"loot_id":loot.id},str(body.side),combat,tick).get("accepted",false): break

func pickup(command: Dictionary,side: String,combat: RefCounted,tick: int) -> Dictionary:
	if command.size()!=3 or typeof(command.get("unit_id"))!=TYPE_STRING or typeof(command.get("loot_id"))!=TYPE_STRING: return _reject("INVALID_LOOT_REQUEST")
	if not combat._hero_data.has(command.unit_id) or not combat._soldiers.has(command.unit_id): return _reject("INVALID_LOOT_HERO")
	var body: Dictionary = combat._soldiers[command.unit_id]
	if body.side!=side or side not in combat._sides or int(body.hp)<=0: return _reject("INVALID_LOOT_HERO")
	for loot: Dictionary in _loot:
		if loot.id!=command.loot_id: continue
		if loot.state!="AVAILABLE": return _reject("LOOT_ALREADY_COLLECTED")
		if not bool(loot.get("hero_drop",false)) and loot.owner!=side: return _reject("FOREIGN_LOOT")
		if bool(loot.get("hero_drop",false)) and tick >= int(loot.expires_tick): return _reject("LOOT_EXPIRED")
		if (Vector2i(body.position)-Vector2i(loot.position)).length_squared()>PICKUP_RADIUS*PICKUP_RADIUS: return _reject("LOOT_OUT_OF_RANGE")
		var result: Dictionary = Items.grant_loot(combat._hero_data[command.unit_id],str(loot.item_id))
		if not result.get("accepted",false): return result
		loot.state="COLLECTED"
		loot.recipient_id=command.unit_id
		loot.collected_tick=tick
		combat._refresh_stats(body)
		_event({"type":"LOOT_COLLECTED","tick":tick,"position":loot.position,"camp_id":loot.camp_id,"side":side,"item_id":loot.item_id,"unit_id":body.id,"hero_drop":bool(loot.get("hero_drop",false)),"source_side":loot.get("source_side",loot.owner)})
		return {"accepted":true,"error":"","loot_id":loot.id,"item_id":loot.item_id,"unit_id":body.id}
	return _reject("UNKNOWN_LOOT")

func _event(event: Dictionary) -> void:
	_events.append(event)
	if _events.size()>MAX_EVENTS: _events.pop_front()

func get_snapshot() -> Dictionary:
	return {"neutral_camps":_camps.duplicate(true),"neutral_loot":_loot.duplicate(true),"neutral_events":_events.duplicate(true)}

func get_state() -> Dictionary:
	return {"version":VERSION,"seed":_seed,"camps":_camps.duplicate(true),"loot":_loot.duplicate(true),"events":_events.duplicate(true),"death_receipts":_death_receipts.duplicate(true),"pending_stock":_pending_stock.duplicate(true),"pending_bounties":_pending_bounties.duplicate(true)}

static func _reject(reason: String) -> Dictionary:
	return {"accepted":false,"error":reason}
