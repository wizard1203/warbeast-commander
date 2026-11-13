extends RefCounted
## Observation-only additive readiness score. Does not roll out combat or try
## targets / spell aims. The old exchange helpers below are never called by
## estimate; they remain temporarily for historical diagnostic source seams.
const ForceScore = preload("res://src/simulation/strategic_local_force_score_m95.gd")
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const Geometry = preload("res://src/simulation/strategic_hero_skill_geometry.gd")
const Neutrals = preload("res://src/simulation/strategic_neutral_encounters.gd")
const NeutralThreat = preload("res://src/simulation/strategic_ai_neutral_threat_m73.gd")
const VERSION := "m95-additive-observed-force-v1"
const WINDOW := 8.0
const MAX_BODIES := 32
const MAX_TARGETS := 8
const LOCAL_RADIUS := 720.0
const SUPPORT_SECONDS := 3.0
const FRAME_CELL := 384

static func prepare(facts: Dictionary) -> Dictionary:
	# Exact identity and a synchronous plan lifetime, not a tick-keyed game
	# cache. No live world/body object is ever mutated by this preparation.
	var officers := {}
	for hero: Dictionary in facts.get("heroes",{}).get("officers",[]):officers[str(hero.get("id",""))]=hero
	var groups := {}
	for group: Dictionary in facts.get("warbands",facts.get("armies",[])):groups[str(group.get("id",""))]=group
	var frame := {"facts":facts,"tick":int(facts.get("tick",0)),"rows":[],"grid":{},"armies":{},"groups":groups,"max_range":0,"profiles":0}
	var seen := {}
	for original: Dictionary in facts.get("soldiers",[])+facts.get("micro_neutral_targets",[])+facts.get("workers",[])+facts.get("buildings",[]):
		var id := str(original.get("id",""))
		if seen.has(id) or not bool(original.get("alive",true)) or float(original.get("hp",0))<=0:continue
		seen[id]=true
		if original.get("side","") not in ["AI","PLAYER","NEUTRAL"] or original.get("side")!="AI" and not bool(original.get("visible",true)):continue
		if original.has("building_type") and (not bool(original.get("complete",false)) or not bool(original.get("defense_active",false))):continue
		var body := original.duplicate(false)
		if officers.has(id):
			body["forecast_skills"]=officers[id].get("skills",[])
			body["mana"]=officers[id].get("mana",0)
			body["forecast_auto_attack"]=officers[id].get("auto_attack",true)
		elif body.get("side")=="NEUTRAL" and not body.get("neutral_skill",{}).is_empty():
			var native: Dictionary=body.neutral_skill
			var skill := native.duplicate(false)
			skill.merge({"learned":true,"passive":false,"effect":str(native.get("control","DAMAGE")),"target_mode":"POINT","delivery":"SINGLE" if int(native.get("max_targets",1))==1 else "AREA","radius":0 if int(native.get("max_targets",1))==1 else int(native.get("range",0)),"target_layers":body.get("attack_layers",["GROUND"]),"cooldown_ticks":maxi(0,int(body.get("neutral_skill_ready_tick",frame.tick))-int(frame.tick)),"control_duration_ticks":int(native.get("control_ticks",0)),"status_total_damage":float(native.get("status_power",0))*float(native.get("status_duration_ticks",0))/20.0 if native.get("status_kind","") in ["POISON","BURN"] else 0.0,"forecast_self_heal":float(native.get("self_heal",0))},true)
			body["forecast_skills"]=[skill]
		elif not body.get("troop_ability",{}).is_empty():
			var native:Dictionary=body.troop_ability
			var skill:=native.duplicate(false)
			# Match the ordinary Combat technology contribution once;
			# the complete DoT pool is scaled, not multiplied again per second.
			var amp:=1.0+float(body.get("technology_modifiers_v4",{}).get("skill_damage_percent",0))/100.0
			for field:String in ["damage","secondary_damage","dot_total"]:
				if skill.has(field):skill[field]=float(skill[field])*amp
			skill.merge({"learned":true,"passive":false,"target_mode":"POINT","cooldown_ticks":maxi(0,int(body.get("troop_skill_ready_tick_v4",0))-int(frame.tick)),"status_total_damage":float(skill.get("dot_total",0)),"status_duration_ticks":int(native.get("dot_duration_ticks",20)),"secondary_damage_percent":roundi(float(native.get("secondary_damage",native.get("damage",1)))*100.0/maxf(1,float(native.get("damage",1)))),"effect":"DAMAGE_BUFF" if native.delivery=="SELF_BUFF" else "DAMAGE_LINK" if native.effect=="DAMAGE_LINK" else "ARMOR_BUFF" if native.effect=="MAGIC_RESIST_BUFF" else "ROOT" if native.has("control_kind") else "DAMAGE"},true)
			body["forecast_skills"]=[skill]
		if body.get("unit_type","")=="deep_fault_carapace":
			var proc:Dictionary=body.get("basic_proc_v4",{})
			body["splash_damage"]=int(proc.get("secondary_damage",body.get("basic_secondary_damage",0)))
			body["splash_max_targets"]=int(proc.get("max_targets",body.get("basic_max_targets",1)))
			body["splash_layers"]=proc.get("target_layers",["GROUND"])
		body["_m95_force_profile"]=ForceScore.profile(body,int(frame.tick))
		frame.profiles+=1
		if body.get("side")=="NEUTRAL" and int(body.get("neutral_guard_until_tick",-1))>int(frame.tick):
			var home := body.duplicate(false)
			home.armor=float(home.get("armor",0))-float(home.get("neutral_guard_armor",0))
			home.hp=home.get("max_hp",home.hp)
			body["_m95_home_profile"]=ForceScore.profile(home,int(frame.tick))
			frame.profiles+=1
		var index: int=frame.rows.size()
		frame.rows.append(body)
		var cell := Vector2i(floori(float(body.position.x)/FRAME_CELL),floori(float(body.position.y)/FRAME_CELL))
		if not frame.grid.has(cell):frame.grid[cell]=[]
		frame.grid[cell].append(index)
		var group_id := str(body.get("warband_id",""))
		if body.get("side")=="AI" and not group_id.is_empty():
			if not frame.armies.has(group_id):frame.armies[group_id]=[]
			frame.armies[group_id].append(index)
		frame.max_range=maxi(int(frame.max_range),int(body.get("attack_range",0)))
	return frame

static func _candidates(frame: Dictionary,army_ids: Array,point: Vector2i) -> Array:
	var reach := ceili(LOCAL_RADIUS)+int(frame.max_range)
	var low := Vector2i(floori(float(point.x-reach)/FRAME_CELL),floori(float(point.y-reach)/FRAME_CELL))
	var high := Vector2i(floori(float(point.x+reach)/FRAME_CELL),floori(float(point.y+reach)/FRAME_CELL))
	if (high.x-low.x+1)*(high.y-low.y+1)>=frame.rows.size():return frame.rows
	var result: Array=[]
	var seen := {}
	# Projected own cohorts may originate beyond the local spatial rectangle.
	for army_id: Variant in army_ids:
		for index: int in frame.armies.get(str(army_id),[]):
			if not seen.has(index):seen[index]=true;result.append(frame.rows[index])
	for y: int in range(low.y,high.y+1):
		for x: int in range(low.x,high.x+1):
			for index: int in frame.grid.get(Vector2i(x,y),[]):
				if not seen.has(index):seen[index]=true;result.append(frame.rows[index])
	return result

static func estimate(facts: Dictionary, army: Dictionary, point: Vector2i, options: Dictionary = {}) -> Dictionary:
	var tick := int(facts.get("tick",0))
	var army_ids: Array = options.get("army_ids",[str(army.get("id",""))])
	var project := bool(options.get("project",true))
	var frame: Dictionary=options.get("frame",{})
	if frame.is_empty() or not is_same(frame.get("facts"),facts) or int(frame.get("tick",-1))!=tick:frame=prepare(facts)
	var army_map: Dictionary=frame.groups
	var allies: Array[Dictionary] = []
	var enemies: Array[Dictionary] = []
	var supports: Array = []
	for original: Dictionary in _candidates(frame,army_ids,point):
		var id := str(original.get("id",""))
		var friendly: bool = original.get("side")=="AI"
		if original.get("side")=="NEUTRAL" and original.has("home_position") and Vector2(original.home_position).distance_to(Vector2(point))>float(Neutrals.LEASH_RADIUS)+120.0:continue
		var structure := original.has("building_type")
		if structure and (not bool(original.get("complete",false)) or not bool(original.get("defense_active",false))): continue
		# Read eligibility before allocating a working body or its skill payload.
		# These facts remain immutable for this synchronous estimate; only actual
		# local participants need writable forecast fields. No cross-query cache.
		var group_id := str(original.get("warband_id",""))
		var group: Dictionary = army_map.get(group_id,army if group_id==str(army.get("id","")) else {})
		var main: bool = friendly and group_id in army_ids
		var distance := Vector2(original.get("position",point)).distance_to(Vector2(point))
		if main and original.get("direct_intent","")=="MOVE":continue
		var held: bool = main and original.get("direct_intent","") in ["HOLD","AUTO_HOLD"]
		# A new proposed attack evaluates resuming this army after travel. Its
		# OLD macro RETREAT intent is not permission to erase all live soldiers
		# from that counterfactual. Current in-progress retreats still contribute
		# no borrowed support when projection is disabled.
		if main and group.get("intent","")=="RETREAT" and not bool(options.get("allow_retreating",false)) and (not project or group_id!=str(army.get("id",""))): continue
		if main and not project and distance>LOCAL_RADIUS+float(original.get("attack_range",0)):continue
		var projected_position: Variant = null
		if main and project:
			var offset := Vector2(original.get("position",point))-Vector2(group.get("anchor",army.get("anchor",point)))
			projected_position = point + Vector2i(offset)
			distance = offset.length()
			if distance>LOCAL_RADIUS:continue
		elif not main:
			if distance > LOCAL_RADIUS + float(original.get("attack_range",0)): continue
			if friendly and not structure:
				if group.get("intent","")=="RETREAT" or original.get("direct_intent","") in ["MOVE","HOLD"]: continue
				var moving_to_fight: bool = group.get("intent","") in ["FOCUS","ATTACK_MOVE","ATTACK_BASE"] and Vector2(group.get("destination",point)).distance_to(Vector2(point))<=240.0
				if distance>180.0 and not moving_to_fight: continue
				var eta := maxf(0.0,distance-float(original.get("attack_range",0))-80.0)/_speed(original)
				if eta>SUPPORT_SECONDS: continue
				supports.append({"id":id,"eta_seconds":eta})
		if structure and distance > float(original.get("attack_range",0))+120.0: continue
		var arrival := 0.0 if main or structure else maxf(0.0,distance-float(original.get("attack_range",0))-80.0)/_speed(original)
		if arrival>=WINDOW: continue
		# Forecast only writes top-level working fields. Nested skills, gear and
		# buffs remain read-only; the neutral skill is cloned separately below.
		# Do not add nested writes or return these borrowed values to callers.
		var body: Dictionary
		if original.get("side")=="NEUTRAL":body=original.duplicate(false)
		else:
			# A local query does not need the full animation/equipment/history
			# dictionary. Compiled numeric readiness remains a borrowed value.
			body={"id":id,"side":original.side,"position":original.position,"hp":original.hp,"max_hp":original.get("max_hp",original.hp),"radius":original.get("radius",14),"movement_layer":original.get("movement_layer","GROUND"),"attack_layers":original.get("attack_layers",["GROUND","AIR"] if structure else ["GROUND"]),"attack_range":original.get("attack_range",0),"speed_exact":original.get("speed_exact",original.get("speed",4)),"direct_intent":original.get("direct_intent",""),"stun_until_tick":original.get("stun_until_tick",-1),"root_until_tick":original.get("root_until_tick",-1),"cooldown_ticks":original.get("cooldown_ticks",0),"_m95_force_profile":original._m95_force_profile}
			for field: String in ["heal_range","heal_target_tags","tags","splash_layers"]:
				if original.has(field):body[field]=original[field]
			if structure:
				body["building_type"]=original.building_type
				body["fixed"]=bool(original.get("fixed",false))
				body["attackable"]=bool(original.get("attackable",true))
		if held:
			# A new projected army order releases only its own macro HOLD. The
			# actual-position forecast keeps HOLD stationary rather than disarmed.
			if project or bool(options.get("resume_macro_hold",false)) and group_id==str(army.get("id","")): body.direct_intent=""
			else: body["forecast_stationary"]=true
		if projected_position != null: body.position = projected_position
		body["forecast_main"] = main
		body["forecast_arrival"] = arrival
		if friendly: allies.append(body)
		else: enemies.append(body)
	# A nearby sleeping camp is not an enemy player army moving to reinforce.
	# Match the existing neutral home/aggro/retaliation contract against actual
	# (or this army's projected) friendly bodies. Active pursuers remain threats.
	var participating:Array[Dictionary]=[]
	for body:Dictionary in enemies:
		if body.get("side")=="NEUTRAL":
			var state:=NeutralThreat.forecast_state(body,allies,tick,roundi(WINDOW*20.0))
			if not bool(state.can_engage):continue
			if int(state.ready_ticks)>0:
				body.position=state.position
				# Existing exchange already pays current stun; this extra delay
				# adds return/grace exactly once, rather than double-counting stun.
				body["forecast_delay_seconds"]=float(maxi(0,int(state.ready_ticks)-maxi(0,int(body.get("stun_until_tick",-1))-tick)))/20.0
				if bool(state.returns_home):
					body.hp=body.get("max_hp",body.hp)
					if int(body.get("neutral_guard_until_tick",-1))>tick:body.armor=float(body.get("armor",0))-float(body.get("neutral_guard_armor",0))
					if body.has("_m95_home_profile"):body["_m95_force_profile"]=body._m95_home_profile
		participating.append(body)
	enemies=participating
	var original_counts := {"friendly":allies.size(),"enemy":enemies.size()}
	var own_summary := ForceScore.summary(allies)
	var hostile_summary := ForceScore.summary(enemies)
	var own := ForceScore.evaluate(allies,own_summary,hostile_summary,tick)
	var hostile := ForceScore.evaluate(enemies,hostile_summary,own_summary,tick)
	var own_hp := float(own_summary.hp)
	var enemy_hp := float(hostile_summary.hp)
	# Recovery is support strength, never permission to win a matchup in which
	# no current basic/spell damage can hit (e.g. ground-only versus all air).
	var can_harm := float(own.damage)>0.0
	var ratio := 4.0 if enemies.is_empty() else 0.0 if not can_harm or float(own.score)<=0.01 else float(own.score)/maxf(0.01,float(hostile.score))
	var expected_own_loss := maxf(0.0,float(hostile.damage)-float(own.healing))
	var expected_enemy_loss := maxf(0.0,float(own.damage)-float(hostile.healing))
	var reason := "NO_OBSERVED_THREAT" if enemies.is_empty() else "NO_ELIGIBLE_DAMAGE" if not can_harm or float(own.score)<=0.01 else "UNFAVORABLE_SCORE" if ratio<0.85 else "FAVORABLE_SCORE" if ratio>1.15 else "CONTESTED_SCORE"
	return {"version":VERSION,"method":"ADDITIVE_VISIBLE_FORCE","heuristic_not_probability":true,"window_seconds":WINDOW,"point":point,"army_id":army.get("id",""),"ratio":minf(4.0,ratio),"reason":reason,"confidence":"COARSE_OBSERVED_SCORE","truncated":false,"observed_counts":original_counts,"friendly_count":allies.size(),"enemy_count":enemies.size(),"friendly_score":own.score,"enemy_score":hostile.score,"friendly_hp":own_hp,"enemy_hp":enemy_hp,"friendly_damage":own.damage,"enemy_damage":hostile.damage,"friendly_skill_damage":own.skill_damage,"enemy_skill_damage":hostile.skill_damage,"friendly_healing":own.healing,"enemy_healing":hostile.healing,"friendly_control_value":own.control_value,"enemy_control_value":hostile.control_value,"friendly_loss_fraction":minf(1.0,expected_own_loss/maxf(1.0,own_hp)),"enemy_loss_fraction":minf(1.0,expected_enemy_loss/maxf(1.0,enemy_hp)),"friendly_ids":allies.map(func(body:Dictionary)->String:return str(body.id)),"enemy_ids":enemies.map(func(body:Dictionary)->String:return str(body.id)),"reinforcements":supports,"work":{"actors":allies.size()+enemies.size(),"basic_pairs":0,"skill_aims":0,"max_actors":-1,"max_targets_per_actor":0},"limitations":["Additive readiness, not battle simulation or win probability","Layer bounding boxes and population-average armor; no exact target/path/skill geometry","At most three assumed spell/splash recipients, one shared observed MP budget","Loss/clear-time fields are coarse budget hints, not predicted settled damage","No unknown enemy or distant reinforcement guarantee"]}

static func _neutral_can_engage(body:Dictionary,allies:Array[Dictionary],tick:int)->bool:
	return NeutralThreat.forecast_can_engage(body,allies,tick,roundi(WINDOW*20.0))

static func _sort_local(bodies: Array[Dictionary], point: Vector2i) -> void:
	bodies.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if bool(a.get("forecast_main",false))!=bool(b.get("forecast_main",false)):return bool(a.get("forecast_main",false))
		var da:=Vector2(a.position).distance_squared_to(Vector2(point));var db:=Vector2(b.position).distance_squared_to(Vector2(point))
		return str(a.id)<str(b.id) if is_equal_approx(da,db) else da<db)

static func _speed(body:Dictionary)->float:
	return maxf(1.0,float(body.get("speed_exact",body.get("speed",4)))*20.0)

static func _health(bodies:Array[Dictionary])->float:
	var result:=0.0
	for body:Dictionary in bodies:
		# Stationary weapons matter through their fire and limited demolition
		# budget, not as a mobile ten-thousand-HP army able to chase everywhere.
		result+=float(body.hp)*(0.18 if body.has("building_type") else 1.0)
	return result

static func _exchange(actors:Array[Dictionary],targets:Array[Dictionary],tick:int,facts:Dictionary)->Dictionary:
	var result:={"damage":0.0,"skill_damage":0.0,"healing":0.0,"control_value":0.0,"basic_pairs":0,"skill_aims":0}
	if actors.is_empty(): return result
	# Targets are immutable throughout this one exchange. Prepare only the
	# scalar keys repeatedly read by each actor's comparison callback. Keep
	# original indices/order: the approximate-distance comparator may tie.
	var target_positions: Array[Vector2] = []
	var target_ids: Array[String] = []
	var target_layers: Array = []
	for target: Dictionary in targets:
		target_positions.append(Vector2(target.get("position",Vector2.ZERO)))
		target_ids.append(str(target.get("id","")))
		target_layers.append(target.get("movement_layer","GROUND"))
	for actor:Dictionary in actors:
		# Read-only throughout this actor's complete exchange, not per target.
		var actor_position := Vector2(actor.position)
		var actor_structure := actor.has("building_type")
		var actor_layers: Array = actor.get("attack_layers",["GROUND","AIR"] if actor_structure else ["GROUND"])
		var actor_range := float(actor.get("attack_range",0))
		var actor_stationary := bool(actor.get("forecast_stationary",false))
		var actor_speed := _speed(actor)
		var actor_root := int(actor.get("root_until_tick",-1))
		var actor_arrival := float(actor.get("forecast_arrival",0))
		var actor_stun := maxf(0.0,float(int(actor.get("stun_until_tick",-1))-tick)/20.0)
		var actor_delay := float(actor.get("forecast_delay_seconds",0))
		var actor_interval := maxf(0.2,float(actor.get("attack_cooldown_ticks",20))/20.0)
		var actor_ready := maxf(0.0,float(actor.get("cooldown_ticks",0))/20.0)
		var actor_damage := float(actor.get("damage",0))
		var actor_type := str(actor.get("attack_type","EDGE"))
		var actor_splash := float(actor.get("splash_damage",0))
		var candidates:Array[int]=[]
		var distances := PackedFloat64Array()
		distances.resize(targets.size())
		for index: int in range(targets.size()):
			if target_layers[index] in actor_layers:
				candidates.append(index)
				distances[index] = target_positions[index].distance_squared_to(actor_position)
		candidates.sort_custom(func(a:int,b:int)->bool:
			var da:float=distances[a];var db:float=distances[b]
			return target_ids[a]<target_ids[b] if is_equal_approx(da,db) else da<db)
		if candidates.size()>MAX_TARGETS:candidates.resize(MAX_TARGETS)
		var best:=0.0
		for index: int in candidates:
			var target: Dictionary = targets[index]
			result.basic_pairs+=1
			var reach:=actor_range+float(target.get("radius",14))
			# Preserve the original Vector2 distance operation rather than sqrt
			# of a cached key, which could change intermediate real_t precision.
			var distance:=actor_position.distance_to(target_positions[index])
			if actor_structure and distance>actor_range:continue
			if actor_stationary and distance>reach:continue
			var close_time:=maxf(0.0,distance-reach)/actor_speed if not actor_structure else 0.0
			if actor_root>tick and distance>reach:close_time+=float(actor_root-tick)/20.0
			var lost:=maxf(actor_arrival,close_time)+actor_stun+actor_delay
			var duration:=maxf(0.0,WINDOW-lost)
			var attacks:=maxf(0.0,(duration-actor_ready)/actor_interval)
			var amount:=Damage.mitigate(actor_damage,actor_type,target)*attacks
			# Tight formations incur the real tower splash profile; loose/ranged
			# formations naturally have fewer recipients in its radius.
			if actor_splash>0:
				var splash_targets:=0
				for other_index: int in candidates:
					var other: Dictionary = targets[other_index]
					if other.id!=target.id and target_layers[other_index] in actor.get("splash_layers",[]) and target_positions[other_index].distance_to(target_positions[index])<=float(actor.get("splash_radius",0)):splash_targets+=1
				amount+=Damage.mitigate(actor_splash,actor_type,target)*attacks*mini(maxi(0,int(actor.get("splash_max_targets",1))-(0 if actor.has("building_type") else 1)),splash_targets)
			best=maxf(best,amount)
		if bool(actor.get("forecast_auto_attack",true)):result.damage+=best
		# Empty skills contribute only additive zeroes and do not mutate actors.
		if not actor.get("forecast_skills",[]).is_empty():
			var skill_budget:=_skills(actor,actors,targets,tick,facts)
			for key:String in ["damage","skill_damage","healing","control_value","skill_aims"]:result[key]+=skill_budget.get(key,0)
		var heal_cost:=maxf(1,float(actor.get("heal_mana_cost",15)))
		if float(actor.get("heal",0))>0 and float(actor.get("mana",0))>=heal_cost:
			var casts:=minf(float(actor.get("mana",0))/heal_cost,maxf(0,WINDOW-float(actor.get("heal_cooldown_ticks",0))/20.0)/maxf(.2,float(actor.get("heal_max_cooldown_ticks",60))/20.0))
			var recipients:=mini(maxi(1,int(actor.get("heal_max_targets",1))),actors.size())
			result.healing+=float(actor.heal)*casts*recipients*0.65
	return result

static func _skills(actor:Dictionary,allies:Array[Dictionary],targets:Array[Dictionary],tick:int,facts:Dictionary)->Dictionary:
	var result:={"damage":0.0,"skill_damage":0.0,"healing":0.0,"control_value":0.0,"skill_aims":0}
	if actor.get("direct_intent","")=="MOVE" or actor.get("direct_intent","")=="HOLD" and not bool(actor.get("forecast_stationary",false)):return result
	var mana:=float(actor.get("mana",0))
	var choices:Array[Dictionary]=[]
	for skill:Dictionary in actor.get("forecast_skills",[]):
		if not bool(skill.get("learned",false)) or bool(skill.get("passive",false)):continue
		var available_at:=maxf(float(actor.get("forecast_arrival",0)),float(skill.get("cooldown_ticks",0))/20.0)
		available_at=maxf(available_at,maxf(0.0,float(int(actor.get("stun_until_tick",-1))-tick)/20.0))+float(actor.get("forecast_delay_seconds",0))
		if available_at>=WINDOW or float(skill.get("mana_cost",0))>mana:continue
		var best_damage:=0.0;var best_control:=0.0;var heal:=0.0
		if skill.get("effect","")=="HEAL":
			heal=minf(float(skill.get("heal",0)),float(actor.get("max_hp",actor.hp))-float(actor.hp)+float(actor.get("max_hp",actor.hp))*0.15)
			var recipients:=0
			for ally:Dictionary in allies:
				if ally.id==actor.id or Vector2(ally.position).distance_to(Vector2(actor.position))>float(skill.get("ally_radius",skill.get("radius",0))):continue
				if recipients>=int(skill.get("max_targets",1)):break
				heal+=minf(float(skill.get("ally_heal",0)),float(ally.get("max_hp",ally.hp))-float(ally.hp)+float(ally.hp)*0.10);recipients+=1
		elif skill.get("effect","") in ["DAMAGE","STUN","ROOT"]:
			var aims:=targets.slice(0,MAX_TARGETS)
			for aim:Dictionary in aims:
				result.skill_aims+=1
				var reach:=float(skill.get("range",0)) if skill.get("target_mode")=="POINT" else float(skill.get("radius",0))
				var offset:=Vector2(aim.position)-Vector2(actor.position)
				var advance:=maxf(0.0,offset.length()-reach+1.0)
				if bool(actor.get("forecast_stationary",false)) and advance>0.0:continue
				var travel:=advance/_speed(actor)
				if advance>0:travel+=maxf(0.0,float(int(actor.get("root_until_tick",-1))-tick)/20.0)
				if available_at+travel>=WINDOW:continue
				# ETA alone is insufficient: SINGLE/CONE/LINE geometry must use
				# the future legal cast origin, not the still out-of-range old body.
				var caster:=actor.duplicate(false)
				caster.position=Vector2i(Vector2(actor.position)+offset.normalized()*advance)
				var point:Vector2i=Geometry.aim_position(caster.position,skill,aim.position,facts.get("match_setup",{}).get("bounds",Rect2i(0,0,100000,100000))) if skill.get("target_mode")=="POINT" else Vector2i(caster.position)
				var hits:=Geometry.targets(caster,skill,point,targets)
				var damage:=0.0;var control:=0.0
				for index:int in range(hits.size()):
					var target:Dictionary=hits[index]
					var scale:=1.0 if index==0 else float(skill.get("secondary_damage_percent",100))/100.0
					var raw:=float(skill.get("damage",0))*scale
					var dot:=float(skill.get("status_total_damage",0))*scale*minf(1.0,(WINDOW-available_at-travel)/maxf(0.05,float(skill.get("status_duration_ticks",20))/20.0))
					damage+=minf(float(target.hp),Damage.mitigate(raw,str(skill.get("attack_type","ARCANE")),target)+Damage.mitigate(dot,"ARCANE",target))
					if skill.get("effect","") in ["STUN","ROOT"]:
						var duration:=float(Damage.control_ticks(int(skill.get("control_duration_ticks",0)),target))/20.0
						control+=minf(WINDOW-available_at-travel,duration)*float(target.get("damage",0))*20.0/maxf(1.0,float(target.get("attack_cooldown_ticks",20)))*(0.65 if skill.effect=="STUN" else 0.30)
				if damage+control>best_damage+best_control:best_damage=damage;best_control=control
			if best_damage>0:heal+=minf(float(skill.get("forecast_self_heal",0)),maxf(0.0,float(actor.get("max_hp",actor.hp))-float(actor.hp)))
		elif skill.get("effect","") in ["DAMAGE_BUFF","ARMOR_BUFF","RALLY"] and not targets.is_empty():
			var already:=false
			for entry:Dictionary in actor.get("source_buffs",{}).values():
				if entry.get("id")==skill.id and int(entry.get("expires_tick",-1))>tick:already=true
			if already:continue
			var duration:=minf(WINDOW-available_at,float(skill.get("duration_ticks",0))/20.0)
			var dps:=float(actor.get("base_damage",actor.get("damage",0)))*20.0/maxf(1.0,float(actor.get("attack_cooldown_ticks",20)))
			if not bool(actor.get("forecast_auto_attack",true)):dps=0.0
			if bool(actor.get("forecast_stationary",false)):
				var in_range:=false
				for target:Dictionary in targets:
					if target.get("movement_layer","GROUND") in actor.get("attack_layers",["GROUND"]) and Vector2(target.position).distance_to(Vector2(actor.position))<=float(actor.get("attack_range",0))+float(target.get("radius",14)):in_range=true;break
				if not in_range:dps=0.0
			best_damage=dps*duration*(float(skill.get("damage_percent",0))+float(skill.get("attack_speed_percent",0)))/100.0
			# Defensive self-enhancement is survival budget, not fictitious DPS.
			heal+=float(actor.hp)*maxf(0.0,1.0-Damage.armor_factor(float(skill.get("armor_bonus",0))))*minf(1.0,duration/WINDOW)
		choices.append({"cost":float(skill.get("mana_cost",0)),"damage":best_damage,"healing":heal,"control":best_control,"value":best_damage+heal+best_control})
	choices.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.value)/maxf(1.0,float(a.cost))>float(b.value)/maxf(1.0,float(b.cost)))
	for choice:Dictionary in choices:
		if float(choice.cost)>mana:continue
		mana-=float(choice.cost)
		result.damage+=choice.damage;result.skill_damage+=choice.damage;result.healing+=choice.healing;result.control_value+=choice.control
	return result
