extends RefCounted
## Reward ranking is NOT current combat power, XP settlement or a win chance.
## Only already feasible, observed opponents reach this bounded comparison.
const Progression=preload("res://src/simulation/strategic_hero_progression.gd")
const Units=preload("res://src/simulation/strategic_unit_catalog.gd")
const VERSION:="m75-feasible-enemy-reward-v1"

static func value(world:Dictionary,army:Dictionary,target:Dictionary,forecast:Dictionary,tactic:String)->Dictionary:
	var level:=int(target.get("level",target.get("neutral_level",1)))
	for officer:Dictionary in world.get("heroes",{}).get("officers",[]):
		if officer.get("id")==target.get("id"):level=int(officer.get("level",level));break
	var xp_pool:=Progression.kill_reward(target,level)
	var sharers:Array[Dictionary]=[]
	for hero:Dictionary in world.get("heroes",{}).get("officers",[]):
		if hero.get("side")!="AI" or int(hero.get("hp",0))<=0:continue
		var position:=Vector2(hero.get("position",Vector2i.ZERO))
		if str(hero.get("id","")) in forecast.get("friendly_ids",[]) and hero.get("warband_id")==army.id:position+=Vector2(target.position)-Vector2(army.anchor)
		for body:Dictionary in world.get("soldiers",[]):
			if body.get("id")==hero.get("id") and body.get("direct_intent")=="MOVE":position=Vector2(body.get("direct_destination",position));break
		if position.distance_to(Vector2(target.position))<=Progression.SHARED_XP_RADIUS:sharers.append(hero)
	sharers.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a.id)<str(b.id))
	var allocations:={};var xp_value:=0.0;var level_bonus:=0.0
	for index:int in range(sharers.size()):
		var hero:Dictionary=sharers[index]
		var share:=xp_pool/sharers.size()+(1 if index<xp_pool%sharers.size() else 0)
		var actual:=mini(share,maxi(0,int(Progression.XP_THRESHOLDS[-1])-int(hero.get("xp",0))))
		allocations[str(hero.id)]={"share":share,"actual_possible":actual,"discarded_at_cap":share-actual}
		xp_value+=float(actual)*0.45
		var needed:=Progression.next_level_xp(int(hero.get("level",1)))-int(hero.get("xp",0))
		if needed>0 and actual>=needed:level_bonus=maxf(level_bonus,18.0)
	xp_value=minf(36.0,xp_value)
	var recipe:Dictionary=Units.UNITS.get(str(target.get("unit_type","")),{})
	var cost:Dictionary=recipe.get("cost",{})
	var paid_value:=float(cost.get("MATERIAL",0))
	var is_hero:bool=target.get("unit_type")=="hero"
	var is_worker:bool=target.has("desired_role")
	# Removing surviving units reduces real hostile pressure/replenishment.
	# These capped utilities are not a second bill or imaginary current DPS.
	var denial:=(34.0+float(level)*3.0 if is_hero else 30.0 if is_worker else 16.0+minf(28.0,paid_value*0.08)+minf(12.0,float(recipe.get("population",1))*2.0))
	var health_fraction:=float(target.get("hp",0))/maxf(1.0,float(target.get("max_hp",1)))
	var finish_bonus:=(1.0-clampf(health_fraction,0.0,1.0))*16.0
	var distance:=Vector2(army.anchor).distance_to(Vector2(target.position))
	var dps:=float(forecast.get("friendly_damage",0))/maxf(0.1,float(forecast.get("window_seconds",8.0)))
	var clear_seconds:=float(forecast.get("enemy_hp",0))/maxf(0.01,dps)
	var travel_seconds:=distance/70.0
	var strategic:=denial+finish_bonus+xp_value+level_bonus
	if tactic=="VANGUARD_RUSH":strategic*=1.15
	elif tactic=="RAIDER_HARASS" and (is_worker or is_hero):strategic*=1.15
	elif tactic=="DEFENSIVE_COUNTER" and distance<=420.0:strategic*=1.1
	var safe:bool=not bool(forecast.get("truncated",false)) and int(forecast.get("friendly_count",0))>0 and dps>0.0 and float(forecast.get("ratio",0))>=1.12 and float(forecast.get("friendly_loss_fraction",1.0))<=0.50 and clear_seconds<=35.0
	var utility:=strategic/(8.0+travel_seconds+clear_seconds)-float(forecast.get("friendly_loss_fraction",1.0))*1.5
	return {"version":VERSION,"target_id":target.id,"safe":safe,"utility":utility,"denial_value":denial,"finish_value":finish_bonus,"xp_pool":xp_pool,"xp_sharing_heroes":sharers.size(),"xp_allocations":allocations,"xp_value":xp_value,"level_up_bonus":level_bonus,"target_level":level,"strategic_value":strategic,"travel_seconds_estimate":travel_seconds,"clear_seconds_estimate":clear_seconds,"forecast":forecast,"reward_is_not_combat_power":true}
