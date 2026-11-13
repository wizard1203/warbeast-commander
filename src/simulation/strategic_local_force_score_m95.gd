extends RefCounted
## Plan-scope compilation, local scalar sums, one group matchup correction.
## No per-query skill parsing, per-actor armor dot product or combat rollout.
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const WINDOW := 8.0

static func profile(body: Dictionary, tick: int = 0) -> Dictionary:
	var resistance := {}
	var average := 0.0
	for kind: String in Damage.ATTACKS:
		resistance[kind]=Damage.mitigate(1.0,kind,body)
		average+=float(resistance[kind])
	average/=Damage.ATTACKS.size()
	var interval := maxf(.2,float(body.get("attack_cooldown_ticks",20))/20.0)
	var dps := maxf(0,float(body.get("damage",0)))/interval if bool(body.get("forecast_auto_attack",true)) else 0.0
	dps*=1.0+float(body.get("technology_modifiers_v4",{}).get("basic_damage_percent",0))/100.0
	var splash := float(body.get("splash_damage",0))*WINDOW/interval if dps>0 else 0.0
	var splash_cap:=maxi(0,int(body.get("splash_max_targets",1))-(0 if body.has("building_type") else 1))
	var hp := maxf(0,float(body.get("hp",0)))
	var missing := maxf(0,float(body.get("max_hp",hp))-hp)
	var p := {"resistance":resistance,"mean_resistance":average,"defense_key":str([body.get("armor_type","MAIL"),body.get("unit_type",""),body.get("building_type",""),body.get("armor",0),body.get("magic_resist_percent",0),body.get("trait_id","")]),"dps":dps,"interval":interval,"basic_raw":dps*WINDOW,"basic_kind":str(body.get("attack_type","EDGE")),"primary":0.0,"secondary":0.0,"spell_kind":"ARCANE","spell_layers":[],"spell_range":0.0,"spell_ready":WINDOW,"control_primary":0.0,"control_secondary":0.0,"self_heal":0.0,"ally_heal":0.0,"strike_heal":0.0,"enhance_raw":0.0,"defense_value":0.0,"medic_heal":0.0,"skill_cost":0.0}
	var kinds := {}
	# Only current missing HP and the bounded local window. A future lethal
	# crossing is not guaranteed healing, and a ready critical passive is NOT
	# added as permanent effective HP or as an imaginary extra attack source.
	p.self_heal=minf(missing,maxf(0,float(body.get("hp_regen_per_second",0)))*WINDOW)
	var mana := maxf(0,float(body.get("mana",0)))
	var stun := maxf(0,float(int(body.get("stun_until_tick",-1))-tick)/20.0)
	for skill: Dictionary in body.get("forecast_skills",[]):
		if not bool(skill.get("learned",true)) or bool(skill.get("passive",false)):continue
		var cost := float(skill.get("mana_cost",0))
		var ready := maxf(stun,float(skill.get("cooldown_ticks",0))/20.0)
		if cost>mana or ready>=WINDOW:continue
		var effect := str(skill.get("effect",""))
		var value := 0.0
		if effect in ["DAMAGE","STUN","ROOT"]:
			var remaining := (WINDOW-ready)/WINDOW
			var raw := (float(skill.get("damage",0))+float(skill.get("status_total_damage",0))*minf(1,(WINDOW-ready)/maxf(.05,float(skill.get("status_duration_ticks",20))/20.0)))*remaining
			var extra := mini(2,maxi(0,int(skill.get("max_targets",1))-1))
			var secondary := raw*float(skill.get("secondary_damage_percent",100))/100.0
			var control := minf(WINDOW-ready,float(skill.get("control_duration_ticks",0))/20.0)*(.65 if effect=="STUN" else .30 if effect=="ROOT" else 0.0)
			value=raw+secondary*extra+control*20
			if value>0:
				p.primary+=raw;p.secondary+=secondary*extra/2.0
				p.control_primary+=control;p.control_secondary+=control*extra/2.0
				var kind := str(skill.get("attack_type","ARCANE"))
				kinds[kind]=float(kinds.get(kind,0))+raw+secondary*extra
				for layer: String in skill.get("target_layers",["GROUND","AIR"]):
					if layer not in p.spell_layers:p.spell_layers.append(layer)
				var reach := float(skill.get("range",0)) if skill.get("target_mode","POINT")=="POINT" else float(skill.get("radius",0))
				p.spell_range=maxf(float(p.spell_range),reach)
				p.spell_ready=minf(float(p.spell_ready),ready)
				p.strike_heal+=minf(missing,float(skill.get("forecast_self_heal",0)))
		elif effect=="HEAL":
			var own := minf(missing,float(skill.get("heal",skill.get("healing",0))))
			var ally := float(skill.get("ally_heal",0))*mini(3,maxi(0,int(skill.get("max_targets",1))))
			value=own+ally
			p.self_heal+=own;p.ally_heal+=ally
		elif effect in ["DAMAGE_BUFF","ARMOR_BUFF","RALLY"]:
			var already := false
			for buff: Dictionary in body.get("source_buffs",{}).values():
				if buff.get("id")==skill.get("id") and int(buff.get("expires_tick",-1))>tick and int(buff.get("charges",-1))!=0:already=true;break
			if already:continue
			var duration := minf(WINDOW-ready,float(skill.get("duration_ticks",0))/20.0)
			var enhance := dps*duration*(float(skill.get("damage_percent",0))+float(skill.get("attack_speed_percent",0)))/100.0
			var defense := hp*maxf(0,1-Damage.armor_factor(float(skill.get("armor_bonus",0))))*duration/WINDOW
			p.enhance_raw+=enhance;p.defense_value+=defense;value=enhance+defense
		if value>0:mana-=cost;p.skill_cost+=cost
	var best := -1.0
	for kind: String in kinds:
		if float(kinds[kind])>best:p.spell_kind=kind;best=float(kinds[kind])
	var heal_cost := maxf(1,float(body.get("heal_mana_cost",15)))
	var elite:Dictionary=body.get("elite_passive_r4",{})
	if elite.get("effect","")=="BURN_AURA":
		var raw:=float(elite.damage)*floorf(WINDOW/(float(elite.pulse_ticks)/20.0))
		p.primary+=raw;p.secondary+=raw*mini(2,int(elite.max_targets)-1)/2.0
		p.spell_layers=["GROUND","AIR"];p.spell_range=maxf(float(p.spell_range),float(elite.radius));p.spell_ready=0.0;p.spell_kind=str(elite.attack_type)
	elif elite.get("effect","")=="BASIC_STUN":
		var needed:=maxi(1,int(elite.hit_interval)-int(body.get("elite_stun_hits_r4",0)))
		if ceili(WINDOW/interval)>=needed and int(body.get("elite_stun_ready_tick_r4",0))<tick+int(WINDOW*20):
			p.control_primary+=float(elite.stun_ticks)/20.0*.65
			p.spell_layers=body.get("attack_layers",["GROUND"]);p.spell_range=float(body.get("attack_range",0));p.spell_ready=0.0
	# Guard/link redistributes HP rather than creating it. Do not add the same
	# protector health again as free healing, armor or a second effective body.
	var heal_wait := maxf(stun,float(body.get("heal_cooldown_ticks",0))/20.0)
	if float(body.get("heal",0))>0 and mana>=heal_cost and heal_wait<WINDOW:
		p.medic_heal=float(body.heal)*minf(mana/heal_cost,(WINDOW-heal_wait)/maxf(.2,float(body.get("heal_max_cooldown_ticks",60))/20.0))
	p["medic_target_cap"]=maxi(1,int(body.get("heal_max_targets",1)))
	p["medic_per_target"]=float(p.medic_heal)
	p.medic_heal*=int(p.medic_target_cap)
	var raw_skills := float(p.primary)+2.0*float(p.secondary)+float(p.enhance_raw)
	var healing := float(p.self_heal)+float(p.ally_heal)+float(p.strike_heal)+float(p.defense_value)+float(p.medic_heal)
	var control_proxy := (float(p.control_primary)+2.0*float(p.control_secondary))*20.0
	var basic_max := float(p.basic_raw)+splash*float(splash_cap)
	var pressure := basic_max+raw_skills+healing+control_proxy
	var weight := hp*(.18 if body.has("building_type") else 1.0)
	var score := sqrt(maxf(0,weight/maxf(.1,average)*pressure/WINDOW))
	p["basic_score"]=score*basic_max/maxf(.001,pressure)
	p["skill_score"]=score*raw_skills/maxf(.001,pressure)
	p["heal_score"]=score*healing/maxf(.001,pressure)
	p["control_score"]=score*control_proxy/maxf(.001,pressure)
	p["raw_skills_max"]=raw_skills;p["healing_max"]=healing;p["control_proxy"]=control_proxy
	p["splash_raw"]=splash;p["basic_max"]=basic_max;p["has_effects"]=raw_skills+healing+control_proxy>0
	p["splash_extra_limit"]=splash_cap
	return p

static func _profile(body: Dictionary) -> Dictionary:
	var cached: Dictionary=body.get("_m95_force_profile",{})
	return cached if not cached.is_empty() else profile(body)

static func summary(bodies: Array[Dictionary]) -> Dictionary:
	var r := {"count":bodies.size(),"hp":0.0,"missing_hp":0.0,"dps":0.0,"resistance":{},"mean_resistance":0.0,"bounds":{},"layers":{},"attack_mix":{},"heal_bodies":bodies}
	var classes := {}
	for b: Dictionary in bodies:
		var p := _profile(b)
		var hp := maxf(0,float(b.get("hp",0)))
		var weight := hp*(.18 if b.has("building_type") else 1.0)
		r.hp+=weight;r.missing_hp+=maxf(0,float(b.get("max_hp",hp))-hp);r.dps+=float(p.dps)
		var key := str(p.defense_key)
		if not classes.has(key):classes[key]={"profile":p,"weight":0.0}
		classes[key].weight+=weight
		var layer := str(b.get("movement_layer","GROUND"))
		r.layers[layer]=int(r.layers.get(layer,0))+1
		var point := Vector2(b.position);var radius := float(b.get("radius",14))
		var box := Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2)
		r.bounds[layer]=(r.bounds[layer] as Rect2).merge(box) if r.bounds.has(layer) else box
	for kind: String in Damage.ATTACKS:r.resistance[kind]=0.0
	# Many identical infantry share one compiled defense class; six fixed type
	# sums per class, never repeated damage formulas or per-actor armor dots.
	for group: Dictionary in classes.values():
		r.mean_resistance+=float(group.weight)*float(group.profile.mean_resistance)
		for kind: String in Damage.ATTACKS:r.resistance[kind]+=float(group.weight)*float(group.profile.resistance[kind])
	r.mean_resistance=float(r.mean_resistance)/maxf(1,float(r.hp))
	for kind: String in Damage.ATTACKS:r.resistance[kind]=float(r.resistance[kind])/maxf(1,float(r.hp))
	return r

static func _distance(b: Dictionary, opposition: Dictionary, layers: Array) -> float:
	var nearest := INF
	for layer: String in layers:
		if not opposition.bounds.has(layer):continue
		var box: Rect2=opposition.bounds[layer]
		var point := Vector2(b.position)
		var closest := Vector2(clampf(point.x,box.position.x,box.end.x),clampf(point.y,box.position.y,box.end.y))
		nearest=minf(nearest,point.distance_to(closest))
	return nearest

static func _activity(b: Dictionary, opposition: Dictionary, layers: Array, attack_range: float, tick: int, ready_ticks: int = 0) -> float:
	var distance := _distance(b,opposition,layers)
	if is_inf(distance):return 0.0
	var wait := maxf(float(b.get("forecast_arrival",0)),maxf(0,float(int(b.get("stun_until_tick",-1))-tick)/20.0))
	wait=maxf(wait,float(ready_ticks)/20.0)+float(b.get("forecast_delay_seconds",0))
	if distance>attack_range:
		if b.has("building_type") or bool(b.get("forecast_stationary",false)) or b.get("direct_intent","") in ["HOLD","AUTO_HOLD"]:return 0.0
		wait=maxf(wait,maxf(0,float(int(b.get("root_until_tick",-1))-tick)/20.0))
		wait+=(distance-attack_range)/maxf(20,float(b.get("speed_exact",b.get("speed",4)))*20.0)
	return clampf((WINDOW-wait)/WINDOW,0,1)

static func _skills(b: Dictionary, own: Dictionary, enemy: Dictionary, tick: int, basic_dps: float) -> Dictionary:
	# Numeric compiled budget only: no loop over original skills, buff parsing,
	# catalog lookup, MP re-allocation or target/geometry search on this path.
	var p := _profile(b)
	var active := _activity(b,enemy,p.spell_layers,float(p.spell_range),tick) if float(p.primary)+float(p.control_primary)>0 else 0.0
	var eligible := 0
	for layer: String in p.spell_layers:eligible+=int(enemy.layers.get(layer,0))
	var extra := minf(2,maxi(0,eligible-1))
	var raw := (float(p.primary)+float(p.secondary)*extra)*active if eligible>0 else 0.0
	var basic_active := _activity(b,enemy,b.get("attack_layers",["GROUND"]),float(b.get("attack_range",0)),tick,int(b.get("cooldown_ticks",0))) if float(p.enhance_raw)>0 else 0.0
	var enhanced := float(p.enhance_raw)*basic_active
	var eligible_missing: Array[float]=[]
	if float(p.medic_per_target)>0:
		var reach:=float(b.get("heal_range",0))
		for ally: Dictionary in own.get("heal_bodies",[]):
			if ally.has("building_type") or float(ally.get("hp",0))<=0 or Vector2(ally.position).distance_squared_to(Vector2(b.position))>reach*reach:continue
			var allowed: Array=b.get("heal_target_tags",[])
			if not allowed.is_empty() and not allowed.any(func(tag: String)->bool:return tag in ally.get("tags",[])):continue
			var missing:=maxf(0,float(ally.get("max_hp",0))-float(ally.hp))
			if missing>0:eligible_missing.append(missing)
		eligible_missing.sort()
		eligible_missing.reverse()
	var medic:=0.0
	for i: int in range(mini(int(p.medic_target_cap),eligible_missing.size())):medic+=minf(eligible_missing[i],float(p.medic_per_target))
	var healing := minf(float(own.missing_hp),float(p.self_heal)+float(p.ally_heal)+medic)
	if active>0:healing+=float(p.strike_heal)
	var temporal := clampf((WINDOW-maxf(float(b.get("forecast_arrival",0)),maxf(0,float(int(b.get("stun_until_tick",-1))-tick)/20.0))-float(b.get("forecast_delay_seconds",0)))/WINDOW,0,1)
	healing=healing*temporal+float(p.defense_value)*temporal
	var control := (float(p.control_primary)+float(p.control_secondary)*extra)*active*float(enemy.dps)/maxi(1,int(enemy.count))
	return {"damage":raw*float(enemy.resistance.get(str(p.spell_kind),1))+enhanced*float(enemy.resistance.get(str(p.basic_kind),1)),"raw_damage":raw+enhanced,"healing":healing,"control_value":control,"skill_active":active,"basic_active":basic_active}

static func evaluate(bodies: Array[Dictionary], own: Dictionary, opposition: Dictionary, tick: int) -> Dictionary:
	var r := {"score":0.0,"damage":0.0,"skill_damage":0.0,"healing":0.0,"control_value":0.0,"basic_pairs":0,"skill_aims":0}
	var basic_by_type := {}
	var raw_total := 0.0
	for b: Dictionary in bodies:
		var p := _profile(b)
		var basic_active := _activity(b,opposition,b.get("attack_layers",["GROUND","AIR"] if b.has("building_type") else ["GROUND"]),float(b.get("attack_range",0)),tick,int(b.get("cooldown_ticks",0)))
		var raw := float(p.basic_raw)*basic_active
		var enemy_count:=maxi(1,int(opposition.count))
		raw+=float(b.get("bonus_vs_air",0))/float(p.interval)*WINDOW*float(opposition.layers.get("AIR",0))/enemy_count*basic_active
		var splash_eligible:=0
		for layer: String in b.get("splash_layers",[]):splash_eligible+=int(opposition.layers.get(layer,0))
		if splash_eligible>1:raw+=float(p.splash_raw)*mini(int(p.splash_extra_limit),splash_eligible-1)*basic_active
		basic_by_type[str(p.basic_kind)]=float(basic_by_type.get(str(p.basic_kind),0))+raw
		r.score+=float(p.basic_score)*raw/maxf(.001,float(p.basic_max))
		if not bool(p.has_effects):raw_total+=raw;continue
		var spell := _skills(b,own,opposition,tick,float(p.dps))
		r.damage+=float(spell.damage);r.skill_damage+=float(spell.damage);r.healing+=float(spell.healing);r.control_value+=float(spell.control_value)
		raw_total+=raw+float(spell.raw_damage)
		r.score+=float(p.skill_score)*float(spell.raw_damage)/maxf(.001,float(p.raw_skills_max))+float(p.heal_score)*float(spell.healing)/maxf(.001,float(p.healing_max))+float(p.control_score)*minf(2,float(spell.control_value)/maxf(.001,float(p.control_proxy)))
	for kind: String in basic_by_type:r.damage+=float(basic_by_type[kind])*float(opposition.resistance.get(kind,1))
	# One six-type group correction relative to ordinary armor already included
	# in the prepared scalar. Armor is not applied twice to each actor's score.
	if raw_total>0:
		var matching := float(r.damage)/maxf(.001,raw_total*float(opposition.mean_resistance))
		r.score*=sqrt(clampf(matching,.4,1.8))
	return r
