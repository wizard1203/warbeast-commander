extends RefCounted
## Detached explanation of NeutralEncounters' lifecycle. This never chooses a
## target, advances a return, heals a body, or changes live authority.
const Neutrals = preload("res://src/simulation/strategic_neutral_encounters.gd")
const VERSION := "m73-neutral-current-and-reentry-v1"

static func alarm_can_engage(body:Dictionary,victim:Dictionary,tick:int)->bool:
	if not _live_visible(body) or not _eligible_target(body,victim):return false
	if not body.has("home_position"):return true # Existing explicit old fixture.
	if _returning(body) or tick-int(body.get("last_leash_tick",-1000000))<20 or int(body.get("stun_until_tick",-1))>tick:return false
	return _within_acquisition(body,victim,Vector2(body.get("position",Vector2.ZERO)),tick)

static func forecast_can_engage(body:Dictionary,allies:Array[Dictionary],tick:int,window_ticks:int=160)->bool:
	return bool(forecast_state(body,allies,tick,window_ticks).can_engage)

static func forecast_state(body:Dictionary,allies:Array[Dictionary],tick:int,window_ticks:int=160)->Dictionary:
	var origin:=Vector2(body.get("position",Vector2.ZERO))
	var result:={"can_engage":false,"position":Vector2i(origin),"ready_ticks":0,"returns_home":false,"reason":"NO_LEGAL_TARGET"}
	if not _live_visible(body):result.reason="DEAD_OR_UNOBSERVED";return result
	if not body.has("home_position"):
		result.can_engage=true;result.reason="LEGACY_EXPLICIT_FIXTURE";return result
	var ready:=maxi(0,int(body.get("stun_until_tick",-1))-tick)
	if _returning(body):
		# At home the real authority restores HP, clears temporary guard armor,
		# and waits 20 ticks. Pay return plus grace before any forecasted attack;
		# do not claim the current traveler's weapon circle is firing now.
		var speed:=maxf(1.0,float(body.get("speed_exact",body.get("speed",1))))
		ready+=ceili(maxf(0.0,origin.distance_to(Vector2(body.home_position))-24.0)/speed)+20
		origin=Vector2(body.home_position)
		result.returns_home=true
	else:
		ready=maxi(ready,maxi(0,20-(tick-int(body.get("last_leash_tick",-1000000)))))
	result.position=Vector2i(origin);result.ready_ticks=ready
	if ready>=window_ticks:result.reason="RECOVERY_OUTSIDE_WINDOW";return result
	for ally:Dictionary in allies:
		if _eligible_target(body,ally) and _within_acquisition(body,ally,origin,tick+ready):
			result.can_engage=true
			result.reason="RETURN_AND_REENTER" if result.returns_home else "RECOVER_AND_REENTER" if ready>0 else "ACTIVE_ACQUISITION"
			return result
	return result

static func _live_visible(body:Dictionary)->bool:
	return bool(body.get("alive",true)) and float(body.get("hp",0))>0 and bool(body.get("visible",true))

static func _returning(body:Dictionary)->bool:
	return bool(body.get("leashing",false)) or Vector2(body.get("position",Vector2.ZERO)).distance_squared_to(Vector2(body.home_position))>float(Neutrals.LEASH_RADIUS*Neutrals.LEASH_RADIUS)

static func _eligible_target(body:Dictionary,target:Dictionary)->bool:
	if target.is_empty() or not bool(target.get("alive",true)) or float(target.get("hp",0))<=0:return false
	if target.get("side","") not in ["AI","PLAYER"]:return false
	if target.get("movement_layer","GROUND") not in body.get("attack_layers",["GROUND"]):return false
	if target.has("building_type") and target.get("building_type")!="WORKER_OBSTACLE" and (bool(target.get("fixed",false)) or not bool(target.get("attackable",true))):return false
	return true

static func _within_acquisition(body:Dictionary,target:Dictionary,origin:Vector2,tick:int)->bool:
	if Vector2(target.get("position",Vector2.ZERO)).distance_squared_to(Vector2(body.home_position))>float(Neutrals.LEASH_RADIUS*Neutrals.LEASH_RADIUS):return false
	var damage_tick:=int(body.get("last_damage_tick",-1000000))
	var retaliating:=str(body.get("last_damage_source_id",""))==str(target.get("id","")) and damage_tick>=0 and damage_tick<=tick and tick-damage_tick<=100
	var reach:=float(Neutrals.LEASH_RADIUS if retaliating else Neutrals.AGGRO_RADIUS)
	return origin.distance_squared_to(Vector2(target.get("position",Vector2.ZERO)))<=reach*reach
