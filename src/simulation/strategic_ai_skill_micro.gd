extends RefCounted
## Read-only computer skill opportunity evaluation. It emits an ordinary paid
## command; Combat alone checks MP, rank, range, cooldown and settles effects.
## No timers, resources, random draws, or observation discovery live here.
const Geometry = preload("res://src/simulation/strategic_hero_skill_geometry.gd")
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Progress = preload("res://src/simulation/strategic_hero_progression.gd")

static func best_action(hero: Dictionary, facts: Dictionary) -> Dictionary:
	if hero.get("side") != "AI" or hero.get("state") != "ACTIVE" or int(hero.get("hp",0)) <= 0: return {}
	var tick := int(facts.get("tick",0))
	if int(hero.get("stun_until_tick",-1)) > tick: return {}
	var body := hero
	for candidate: Dictionary in facts.get("soldiers",[]):
		if candidate.get("id") == hero.id:
			body = candidate
			break
	var withdrawing := str(body.get("direct_intent","")) in ["MOVE","HOLD"]
	for army: Dictionary in facts.get("warbands",facts.get("armies",[])):
		if army.get("id") == hero.get("warband_id") and army.get("intent") == "RETREAT": withdrawing = true
	var best := {}
	var best_score := 0.0
	for skill: Dictionary in hero.get("skills",[]):
		if not available(hero,skill): continue
		var choice := _opportunity(hero,body,skill,facts,withdrawing)
		if choice.is_empty(): continue
		var score := float(choice.score)
		if score > best_score:
			best_score = score
			best = {"type":"HERO_SKILL", "unit_id":str(hero.id), "skill_id":str(skill.id)}
			if skill.get("target_mode") == "POINT": best["target_position"] = choice.get("position",hero.position)
	return best

static func learning_action(hero: Dictionary, facts: Dictionary) -> Dictionary:
	if hero.get("side") != "AI" or hero.get("state") != "ACTIVE" or int(hero.get("hp",0)) <= 0 or int(hero.get("skill_points",0)) <= 0: return {}
	if int(hero.get("stun_until_tick",-1)) > int(facts.get("tick",0)): return {}
	var body := hero
	for candidate: Dictionary in facts.get("soldiers",[]):
		if candidate.get("id") == hero.id:
			body = candidate
			break
	var withdrawing := str(body.get("direct_intent","")) in ["MOVE","HOLD"]
	for army: Dictionary in facts.get("warbands",facts.get("armies",[])):
		if army.get("id") == hero.get("warband_id") and army.get("intent") == "RETREAT": withdrawing = true
	var legal: Array = Heroes.profile(str(hero.get("archetype",Heroes.DEFAULT_ARCHETYPE))).get("skill_ids",[])
	var result := {}
	var best := 0.0
	# Exactly this hero's three published skills. This is a catalog-based
	# counterfactual, not a synthetic can_cast=true/live-rank mutation.
	for current: Dictionary in hero.get("skills",[]):
		var id := str(current.get("id",""))
		var rank := int(current.get("level",0))
		if id not in legal or not bool(current.get("can_upgrade",false)) or rank >= Progress.max_skill_rank(id): continue
		if int(hero.get("level",1)) < Progress.required_level(id,rank+1): continue
		var next := Heroes.skill_at_level(id,rank+1)
		if next.is_empty() or bool(next.get("passive",false)) or int(current.get("cooldown_ticks",0)) > 0 or int(hero.get("mana",0)) < int(next.get("mana_cost",0)): continue
		var opportunity := _opportunity(hero,body,next,facts,withdrawing)
		if opportunity.is_empty(): continue
		var score := float(opportunity.score)
		if rank > 0:
			var old := _opportunity(hero,body,Heroes.skill_at_level(id,rank),facts,withdrawing)
			score -= float(old.get("score",0))
		if score > best:
			best = score
			result = {"type":"UPGRADE_HERO_SKILL","unit_id":str(hero.id),"skill_id":id}
	# No real immediately useful active growth -> retain the caller's existing
	# ultimate-first/least-trained balancing policy, including learned passives.
	return result

static func _opportunity(hero: Dictionary, body: Dictionary, skill: Dictionary, facts: Dictionary, withdrawing: bool) -> Dictionary:
	var effect := str(skill.get("effect",""))
	if effect == "HEAL": return _healing(hero,skill,facts)
	if not withdrawing and effect in ["DAMAGE","ROOT","STUN"]: return _offense(hero,skill,facts)
	if not withdrawing and effect in ["DAMAGE_BUFF","ARMOR_BUFF","RALLY"]: return _enhancement(hero,body,skill,facts)
	return {}

static func available(hero: Dictionary, skill: Dictionary) -> bool:
	return bool(skill.get("learned",false)) and not bool(skill.get("passive",false)) and bool(skill.get("can_cast",false)) and int(skill.get("cooldown_ticks",0)) <= 0 and int(hero.get("mana",0)) >= int(skill.get("mana_cost",0))

static func _healing(hero: Dictionary, skill: Dictionary, facts: Dictionary) -> Dictionary:
	var benefit := minf(float(skill.get("heal",0)),float(int(hero.max_hp)-int(hero.hp)))
	var urgent := int(hero.hp)*100 < int(hero.max_hp)*45 and benefit > 0
	var allies: Array[Dictionary] = []
	var radius := int(skill.get("ally_radius",skill.get("radius",0)))
	for ally: Dictionary in facts.get("soldiers",[]):
		if ally.get("id") == hero.id or ally.get("side") != hero.side or int(ally.get("hp",0)) <= 0: continue
		if _distance(hero,ally) > radius*radius: continue
		var required := str(skill.get("ally_required_tag",""))
		if not required.is_empty() and required not in ally.get("tags",[]): continue
		allies.append(ally)
	# Mirror Combat's real nearest-first cap, rather than assuming the healer
	# can choose a wounded ally hidden behind several full-health recipients.
	allies.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var da := _distance(hero,a)
		var db := _distance(hero,b)
		return str(a.id) < str(b.id) if da == db else da < db)
	if allies.size() > int(skill.get("max_targets",1)): allies.resize(int(skill.get("max_targets",1)))
	for ally: Dictionary in allies:
		var effective := minf(float(skill.get("ally_heal",0)),float(int(ally.max_hp)-int(ally.hp)))
		benefit += effective
		if effective > 0 and int(ally.hp)*100 < int(ally.max_hp)*45: urgent = true
	if benefit < maxf(25.0,float(skill.get("heal",0))*0.35) and not urgent: return {}
	return {"score":benefit*(1.8 if urgent else 1.0)/_cost_weight(skill), "position":hero.position}

static func _offense(hero: Dictionary, skill: Dictionary, facts: Dictionary) -> Dictionary:
	var pool := _enemy_pool(hero,skill,facts)
	if pool.is_empty(): return {}
	var reach := int(skill.get("range",0)) if skill.get("target_mode") == "POINT" else int(skill.get("radius",0))
	var bounds: Rect2i = facts.get("match_setup",{}).get("bounds",Rect2i(0,0,100000,100000))
	var best := {}
	var best_score := 0.0
	for aim: Dictionary in pool:
		if _distance(hero,aim) > reach*reach: continue
		var point: Vector2i = Geometry.aim_position(hero.position,skill,aim.position,bounds) if skill.get("target_mode") == "POINT" else Vector2i(hero.position)
		var hits := Geometry.targets(hero,skill,point,pool)
		var score := 0.0
		for index: int in range(hits.size()):
			var target: Dictionary = hits[index]
			var scale := 1.0 if index == 0 else float(skill.get("secondary_damage_percent",100))/100.0
			if skill.has("r7_target_weights"):
				var weights: Array=skill.r7_target_weights
				scale=float(weights[mini(index,weights.size()-1)])
			var damage := Damage.resolve(float(skill.get("damage",0))*scale,str(skill.get("attack_type","ARCANE")),target)
			var hp := int(target.get("hp",0))
			var value := minf(float(hp),float(damage))
			if damage >= hp and hp > 0: value += 35.0 if target.get("unit_type") != "hero" else 90.0
			if str(skill.get("status_kind","")) in ["BURN","POISON"]:
				var tail := float(skill.get("status_total_damage",0))*scale
				if skill.has("r7_handler"):
					# Score paid future damage after the same type/armor rules,
					# discounted for delayed delivery; never predict a full combat.
					tail=Damage.mitigate(tail,str(skill.get("attack_type","ARCANE")),target)
					for state: Dictionary in target.get("r7_statuses",{}).values():
						if state.get("skill_id")==skill.id and int(state.get("expires_tick",-1))>int(facts.get("tick",0)):
							tail=0.0
				value += minf(float(maxi(0,hp-damage)),tail*0.65)
			# Zero-direct-damage utility is not zero value. Evaluate its actual
			# payload, finite useful duration and nearby army, not its class label.
			if target.get("building_type")!="WORKER_OBSTACLE" and skill.get("status_kind","") in ["SLOW","ARMOR_BREAK"]:
				var kind:String=skill.status_kind
				var old:Dictionary=target.get("combat_statuses",{}).get(kind,{})
				var remaining:=maxi(0,int(old.get("expires_tick",-1))-int(facts.get("tick",0)))
				var duration:=int(skill.get("status_duration_ticks",0))
				if kind=="SLOW":duration=Damage.control_ticks(duration,target)
				if remaining==0 or float(skill.status_power)>float(old.get("power",0)) or (float(skill.status_power)==float(old.get("power",0)) and duration>remaining):
					if kind=="SLOW":value+=float(maxi(0,duration-remaining))/20.0*float(skill.status_power)*.9
					else:
						var allied_dps:=0.0
						for ally:Dictionary in facts.get("soldiers",[]):
							if ally.get("side")==hero.side and int(ally.get("hp",0))>0 and _distance(ally,target)<=int(ally.get("attack_range",0)+80)*int(ally.get("attack_range",0)+80) and target.get("movement_layer","GROUND") in ally.get("attack_layers",["GROUND"]):allied_dps+=float(ally.get("damage",0))*20.0/maxf(1,float(ally.get("attack_cooldown_ticks",20)))
						var factor:=Damage.armor_factor(int(target.get("armor",0))-int(skill.status_power))/maxf(.01,Damage.armor_factor(int(target.get("armor",0))))-1.0
						value+=allied_dps*maxf(0,factor)*minf(4.0,float(maxi(0,duration-remaining))/20.0)
			var field := "stun_until_tick" if skill.effect == "STUN" else "root_until_tick"
			if skill.effect in ["STUN","ROOT"] and target.get("building_type") != "WORKER_OBSTACLE":
				var duration := Damage.control_ticks(int(skill.get("control_duration_ticks",0)),target)
				var remaining := maxi(0,int(target.get(field,-1))-int(facts.get("tick",0)))
				value += maxf(0.0,float(duration-remaining))*1.8
			if target.get("unit_type") == "hero": value *= 1.18
			score += value
		score /= _cost_weight(skill)
		if score > best_score:
			best_score = score
			best = {"score":score, "position":point}
	return best

static func _enhancement(hero: Dictionary, body: Dictionary, skill: Dictionary, facts: Dictionary) -> Dictionary:
	var tick := int(facts.get("tick",0))
	for buff: Dictionary in body.get("source_buffs",{}).values():
		if buff.get("id") == skill.id and int(buff.get("expires_tick",-1)) > tick and int(buff.get("charges",-1)) != 0: return {}
	if skill.effect == "ARMOR_BUFF" and int(body.get("guard_until_tick",-1)) > tick: return {}
	if skill.effect == "RALLY" and int(body.get("rally_until_tick",-1)) > tick: return {}
	var attack_range := int(hero.get("attack_range",0))+int(skill.get("range_bonus",0))+50
	var engaged := false
	for enemy: Dictionary in facts.get("soldiers",[])+facts.get("micro_neutral_targets",[]):
		if enemy.get("side") == hero.side or int(enemy.get("hp",0)) <= 0 or enemy.get("movement_layer","GROUND") not in hero.get("attack_layers",["GROUND"]): continue
		if _distance(hero,enemy) <= attack_range*attack_range: engaged = true
	for building: Dictionary in facts.get("buildings",[]):
		if building.get("side") == hero.side or building.get("side") in ["", "NEUTRAL"] or int(building.get("hp",0)) <= 0: continue
		if _distance(hero,building) <= attack_range*attack_range: engaged = true
	if not engaged: return {}
	var allies := 1
	if skill.effect == "RALLY":
		allies = 0
		var radius := int(skill.get("radius",0))
		for ally: Dictionary in facts.get("soldiers",[]):
			if ally.get("side") == hero.side and int(ally.get("hp",0)) > 0 and _distance(hero,ally) <= radius*radius: allies += 1
		allies = mini(allies,int(skill.get("max_targets",1)))
	var score := (55.0+float(skill.get("damage_percent",0))*1.1+float(skill.get("attack_speed_percent",0))*1.2)*float(allies)
	return {"score":score/_cost_weight(skill), "position":hero.position}

static func _enemy_pool(hero: Dictionary, skill: Dictionary, facts: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy: Dictionary in facts.get("soldiers",[])+facts.get("micro_neutral_targets",[]):
		if enemy.get("side") != hero.side and int(enemy.get("hp",0)) > 0 and enemy.get("movement_layer","GROUND") in skill.get("target_layers",[]): result.append(enemy)
	if not skill.has("r7_handler") and float(skill.get("damage",0))>0 and "GROUND" in skill.get("target_layers",[]):
		for worker: Dictionary in facts.get("workers",[]):
			if worker.get("side") == hero.side or int(worker.get("hp",0)) <= 0: continue
			var target := worker.duplicate(true)
			target["building_type"] = "WORKER_OBSTACLE"
			target["movement_layer"] = "GROUND"
			result.append(target)
	return result

static func _cost_weight(skill: Dictionary) -> float:
	return 1.0+float(skill.get("mana_cost",0))*0.012

static func _distance(a: Dictionary, b: Dictionary) -> int:
	return (Vector2i(a.position)-Vector2i(b.position)).length_squared()
