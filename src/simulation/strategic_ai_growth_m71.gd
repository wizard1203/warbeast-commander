extends RefCounted
## Bounded strategic value, deliberately separate from local weapon strength.
## Never grants XP, stock, ownership, buffs or orders. All rewards remain Host
## settlements. These utilities are priorities, not probabilities or currency.
const Heroes=preload("res://src/simulation/strategic_hero_progression.gd")
const VERSION:="m71-growth-opportunity-v1"
const MAX_CAMP_CANDIDATES:=6
const MAX_TRAVEL_DISTANCE:=1800.0
const STALE_TICKS:=240
const COOLDOWN_TICKS:=200

static func resource_slots(world:Dictionary,resource:String)->int:
	if not world.has("resource_sources"):return 999 # Legacy explicit fixtures.
	var result:=0
	for source:Dictionary in world.resource_sources:
		if source.get("owner")!="AI" or not bool(source.get("active",false)) or str(source.get("resource",source.get("kind","")))!=resource:continue
		if int(source.get("remaining_amount",source.get("remaining",0)))<=0:continue
		result+=int(source.get("worker_capacity",3 if resource=="ESSENCE" else 5))
	return result

static func candidates(world:Dictionary,army:Dictionary,cooldowns:Dictionary,tick:int)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for camp:Dictionary in world.get("neutral_camps",[]):
		if not camp.has("id") or not camp.has("position"):continue # Explicit legacy recipe-only observation.
		if camp.get("state")=="CLEARED" or int(camp.get("remaining_count",0))<=0 or tick<int(cooldowns.get(str(camp.id),-1)):continue
		var distance:=Vector2(army.anchor).distance_to(Vector2(camp.position))
		if distance>MAX_TRAVEL_DISTANCE:continue
		# Only known live bodies can justify an attack. A recipe with no current
		# member observations is not an invisible guaranteed reward.
		var visible_alive:=false
		for body:Dictionary in world.get("micro_neutral_targets",[]):
			if str(body.get("id","")) in camp.get("member_ids",[]) and int(body.get("hp",0))>0 and bool(body.get("visible",true)):visible_alive=true;break
		if visible_alive:result.append(camp)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var da:=Vector2(army.anchor).distance_squared_to(Vector2(a.position));var db:=Vector2(army.anchor).distance_squared_to(Vector2(b.position))
		return str(a.id)<str(b.id) if is_equal_approx(da,db) else da<db)
	if result.size()>MAX_CAMP_CANDIDATES:result.resize(MAX_CAMP_CANDIDATES)
	return result

static func value(world:Dictionary,army:Dictionary,camp:Dictionary,forecast:Dictionary,tactic:String)->Dictionary:
	var xp_sharers:Array[Dictionary]=[]
	for hero:Dictionary in world.get("heroes",{}).get("officers",[]):
		if hero.get("side")!="AI" or int(hero.get("hp",0))<=0:continue
		var position:Vector2=Vector2(hero.get("position",Vector2i.ZERO))
		if str(hero.get("id","")) in forecast.get("friendly_ids",[]) and hero.get("warband_id")==army.id:position+=Vector2(camp.position)-Vector2(army.anchor)
		for body:Dictionary in world.get("soldiers",[]):
			if body.get("id")==hero.get("id") and body.get("direct_intent")=="MOVE":position=Vector2(body.get("direct_destination",position));break
		if position.distance_to(Vector2(camp.position))<=Heroes.SHARED_XP_RADIUS:xp_sharers.append(hero)
	xp_sharers.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a.id)<str(b.id))
	var xp_pool:=0
	for body:Dictionary in world.get("micro_neutral_targets",[]):
		if body.get("id") in camp.get("member_ids",[]) and int(body.get("hp",0))>0 and bool(body.get("visible",true)):xp_pool+=int(body.get("xp_reward",0))
	# The public initial pool is a fallback for observations predating per-body
	# XP. It is never awarded, and cannot exceed the remaining fraction.
	if xp_pool==0 and not xp_sharers.is_empty():xp_pool=int(camp.get("xp_pool",0))*int(camp.get("remaining_count",0))/maxi(1,camp.get("member_ids",[]).size())
	var xp_value:=0.0
	var level_up_bonus:=0.0
	var allocations:={};var growing_heroes:=0
	for index:int in range(xp_sharers.size()):
		var hero:Dictionary=xp_sharers[index]
		var share:=xp_pool/xp_sharers.size()+(1 if index<xp_pool%xp_sharers.size() else 0)
		var actual:=mini(share,maxi(0,int(Heroes.XP_THRESHOLDS[-1])-int(hero.get("xp",0))))
		allocations[str(hero.id)]={"share":share,"actual_possible":actual,"discarded_at_cap":share-actual}
		if int(hero.get("level",1))>=Heroes.MAX_LEVEL:continue
		growing_heroes+=1
		xp_value+=float(actual)*0.45
		var needed:=Heroes.next_level_xp(int(hero.get("level",1)))-int(hero.get("xp",0))
		if needed>0 and actual>=needed:level_up_bonus=maxf(level_up_bonus,18.0)
	xp_value=minf(36.0,xp_value)
	var material:=int(camp.get("reward",{}).get("MATERIAL",0))
	if camp.has("member_bounties"):
		for body:Dictionary in world.get("micro_neutral_targets",[]):
			if int(body.get("hp",0))>0 and bool(body.get("visible",true)):material+=int(camp.member_bounties.get(str(body.get("id","")),{}).get("MATERIAL",0))
	elif camp.has("member_bounty"):material+=int(camp.member_bounty.get("MATERIAL",0))*int(camp.get("remaining_count",0))
	else:material+=int(camp.get("total_bounty",0))*int(camp.get("remaining_count",0))/maxi(1,camp.get("member_ids",[]).size())
	var unlock:=0.0
	var pop:Dictionary=world.get("population",{}).get("AI",{})
	for site:Dictionary in world.get("sites",[]):
		if site.id!=camp.get("site_id") or site.get("owner")=="AI":continue
		unlock=36.0 if site.get("kind")=="RESOURCE" else 22.0
		if int(pop.get("maximum",30))-int(pop.get("used",0))-int(pop.get("reserved",0))<4:unlock+=20.0
		if site.get("kind")=="RESOURCE" and resource_slots(world,"FOOD")+resource_slots(world,"MATERIAL")<=_workers(world):unlock+=24.0
	var loot:=8.0 if camp.get("kind")!="SCATTERED" else 0.0
	var distance:=Vector2(army.anchor).distance_to(Vector2(camp.position))
	var dps:=float(forecast.get("friendly_damage",0))/maxf(0.1,float(forecast.get("window_seconds",8.0)))
	var kill_seconds:=float(forecast.get("enemy_hp",0))/maxf(0.01,dps)
	var travel:=distance/70.0
	var strategic:=xp_value+level_up_bonus+minf(18.0,float(material)*0.5)+unlock+loot
	if tactic=="CREEP_ESSENCE_CONTROL":strategic*=1.25
	elif tactic=="EXPANSION_BOOM" and unlock>0:strategic*=1.20
	elif tactic=="VANGUARD_RUSH":strategic*=0.85
	var upkeep:Dictionary=world.get("population_upkeep",{}).get("AI",{})
	var upkeep_bonus:=6.0 if int(upkeep.get("material_efficiency_percent",100))<100 else 0.0
	var utility:=(strategic+upkeep_bonus)/(8.0+travel+kill_seconds)-float(forecast.get("friendly_loss_fraction",1.0))*1.5
	var non_neutral:=false
	for body:Dictionary in world.get("soldiers",[])+world.get("buildings",[]):
		if body.get("id") in forecast.get("enemy_ids",[]) and body.get("side")=="PLAYER":non_neutral=true;break
	# Valuable development can accept a modest but bounded trade. It never
	# weakens the entry requirement for enemy armies, towers, truncation or a
	# genuinely losing camp; reward is not added to HP/DPS/ratio.
	var floor:=1.0 if strategic>=45.0 and not non_neutral else 1.08
	var safe:=not bool(forecast.get("truncated",false)) and int(forecast.get("friendly_count",0))>0 and dps>0.0 and float(forecast.get("ratio",0))>=floor and float(forecast.get("friendly_loss_fraction",1.0))<=0.50 and kill_seconds<=35.0
	return {"version":VERSION,"camp_id":camp.id,"site_id":camp.get("site_id",""),"utility":utility,"safe":safe,"risk_floor":floor,"xp_pool":xp_pool,"eligible_xp_heroes":growing_heroes,"xp_sharing_heroes":xp_sharers.size(),"xp_allocations":allocations,"level_up_bonus":level_up_bonus,"material_reward_observed":material,"territory_unlock_value":unlock,"strategic_value":strategic,"maintenance_pressure_value":upkeep_bonus,"travel_seconds_estimate":travel,"clear_seconds_estimate":kill_seconds,"forecast":forecast,"reward_is_not_combat_power":true}

static func _workers(world:Dictionary)->int:
	var result:=0
	for worker:Dictionary in world.get("workers",[]):
		if worker.get("side")=="AI" and int(worker.get("hp",0))>0:result+=1
	return result
