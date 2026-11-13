extends RefCounted
## Ordinary-body automation, not operational AI micro commands. All work is
## bounded to one legal cast or one basic hit; Combat keeps the damage batch.
const Catalog=preload("res://src/simulation/strategic_troop_skills_v4.gd")
const Buffs=preload("res://src/simulation/strategic_combat_buffs.gd")
const Damage=preload("res://src/simulation/strategic_damage_rules.gd")
const Elites=preload("res://src/simulation/strategic_elite_runtime_r4.gd")
const Visibility=preload("res://src/simulation/strategic_visibility_r9.gd")

static func autonomous_action_allowed(source:Dictionary,c)->bool:
	# Use the same effective formation and individual-order precedence as
	# Combat's targeting/movement. This guards paid actions, never passives.
	var direct:=str(source.get("direct_intent",""))
	if direct in ["MOVE","HOLD"]:return false
	return not direct.is_empty() or c._control_army_r12(source).get("intent","") not in ["MOVE","RETREAT"]

static func needs_skill_approach(source:Dictionary,target:Dictionary,c)->bool:
	# A ready offensive spell may close a weapon's radius-sized outer ring.
	# No new target scan, command, free range, cooldown reset or probe bypass.
	if source.unit_type in ["hero","worker"] or bool(source.get("neutral",false)) or not autonomous_action_allowed(source,c):return false
	var skill:Dictionary=source.get("troop_ability",{})
	if skill.is_empty() or skill.get("delivery","") not in ["SINGLE","CHAIN","AREA","LINE"] or skill.get("effect","") in ["DAMAGE_LINK","MAGIC_RESIST_BUFF"]:return false
	if int(c._tick)<int(source.get("troop_skill_ready_tick_v4",0)) or int(source.get("mana",0))<int(skill.mana_cost):return false
	var direct:=str(source.get("direct_intent",""))
	if direct!="ATTACK" and (not direct.is_empty() or c._control_army_r12(source).get("intent","") not in ["ATTACK_MOVE","FOCUS","ATTACK_BASE"]):return false
	return _acquirable(source,target,skill) and not _near(source,target,float(skill.range))

static func _near(a:Dictionary,b:Dictionary,r:float)->bool:
	return Vector2(a.position).distance_squared_to(Vector2(b.position))<=r*r

static func _pool(c,point:Vector2i,radius:int)->Array[Dictionary]:
	var context:RefCounted=c._m94_support_context()
	return context.radius_pool(point,radius) if context!=null else c._ordered_units()

static func _legal(source:Dictionary,target:Dictionary,skill:Dictionary,pending:Dictionary={})->bool:
	return not target.is_empty() and source.side!=target.side and not target.has("building_type") and str(target.get("unit_type",""))!="worker" and int(target.get("hp",0))-int(pending.get(target.get("id",""),0))>0 and str(target.get("movement_layer","GROUND")) in skill.get("target_layers",["GROUND","AIR"])

static func _acquirable(source:Dictionary,target:Dictionary,skill:Dictionary,pending:Dictionary={})->bool:
	return _legal(source,target,skill,pending) and Visibility.can_observe(target,str(source.side))

static func _order(rows:Array[Dictionary],point:Vector2i)->void:
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var da:=Vector2(a.position).distance_squared_to(Vector2(point));var db:=Vector2(b.position).distance_squared_to(Vector2(point))
		return da<db if da!=db else str(a.id)<str(b.id))

static func _targets(source:Dictionary,target:Dictionary,skill:Dictionary,c,pending:Dictionary)->Array[Dictionary]:
	var rows:Array[Dictionary]=[]
	var geometric_rows:Array[Dictionary]=[]
	var reach:=int(skill.get("range",0))
	for enemy:Dictionary in _pool(c,source.position,reach):
		if not _legal(source,enemy,skill,pending) or not _near(source,enemy,reach):continue
		geometric_rows.append(enemy)
		if Visibility.can_observe(enemy,str(source.side)):rows.append(enemy)
	_order(rows,source.position)
	if rows.is_empty():return []
	var primary:Dictionary=target if _acquirable(source,target,skill,pending) and _near(source,target,reach) else rows[0]
	var delivery:=str(skill.delivery)
	var result:Array[Dictionary]=[primary]
	if delivery=="CHAIN":
		var seen:={str(primary.id):true}
		while result.size()<int(skill.max_targets):
			var last:Dictionary=result[-1];var next:Array[Dictionary]=[]
			for enemy:Dictionary in _pool(c,last.position,int(skill.chain_range)):
				if not seen.has(str(enemy.id)) and _acquirable(source,enemy,skill,pending) and _near(last,enemy,int(skill.chain_range)):next.append(enemy)
			_order(next,last.position)
			if next.is_empty():break
			result.append(next[0]);seen[str(next[0].id)]=true
	elif delivery=="AREA":
		var next:Array[Dictionary]=[]
		for enemy:Dictionary in _pool(c,primary.position,int(skill.radius)):
			if enemy.id!=primary.id and _legal(source,enemy,skill,pending) and _near(primary,enemy,int(skill.radius)):next.append(enemy)
		_order(next,primary.position)
		for enemy:Dictionary in next:
			if result.size()>=int(skill.max_targets):break
			result.append(enemy)
	elif delivery=="LINE":
		var axis:=Vector2(primary.position-source.position).normalized()
		var next:Array[Dictionary]=[]
		# A visible aim point does not grant incidental geometric immunity to
		# an unseen body intersecting the actual line, just like area damage.
		for enemy:Dictionary in geometric_rows:
			if enemy.id==primary.id:continue
			var delta:=Vector2(enemy.position-source.position);var forward:=delta.dot(axis)
			if forward>=0 and forward<=reach and absf(delta.cross(axis))<=float(skill.line_width)/2.0+float(enemy.get("radius",0)):next.append(enemy)
		_order(next,source.position)
		for enemy:Dictionary in next:
			if result.size()>=int(skill.max_targets):break
			result.append(enemy)
	return result

static func _already(ally:Dictionary,id:String,power:float,tick:int)->bool:
	for buff:Dictionary in ally.get("source_buffs",{}).values():
		if buff.id==id and float(buff.get("magic_resist_percent",0))>=power and int(buff.expires_tick)>tick+20:return true
	return false

static func _arcane_threat(ally:Dictionary,c,tick:int)->bool:
	if ally.get("last_damage_attack_type","")=="ARCANE" and tick-int(ally.get("last_damage_tick",-1000000))<=60:return true
	for enemy:Dictionary in _pool(c,ally.position,500):
		if enemy.side!=ally.side and int(enemy.hp)>0 and Visibility.can_observe(enemy,str(ally.side)) and str(enemy.get("attack_type",""))=="ARCANE" and c._can_attack(enemy,ally) and c._in_attack_range(enemy,ally):return true
	for enemy:Dictionary in c._ordered_buildings():
		if enemy.side!=ally.side and int(enemy.hp)>0 and Visibility.can_observe(enemy,str(ally.side)) and bool(enemy.get("defense_active",false)) and enemy.get("attack_type","")=="ARCANE" and c._in_attack_range(enemy,ally):return true
	return false

static func _veil(source:Dictionary,skill:Dictionary,c)->Array[Dictionary]:
	var tick:int=c._tick;var rows:Array[Dictionary]=[]
	for ally:Dictionary in _pool(c,source.position,int(skill.range)):
		if ally.id==source.id or ally.side!=source.side or int(ally.hp)<=0 or ally.has("building_type") or bool(ally.get("neutral",false)) or bool(ally.get("summoned",false)) or ally.unit_type=="worker" or not _near(source,ally,int(skill.range)):continue
		var power:=float(skill.hero_magic_resist_percent if ally.unit_type=="hero" else skill.magic_resist_percent)
		if not _already(ally,str(skill.id),power,tick) and _arcane_threat(ally,c,tick):rows.append(ally)
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ha:=float(a.hp)/maxi(1,int(a.max_hp));var hb:=float(b.hp)/maxi(1,int(b.max_hp))
		return ha<hb if not is_equal_approx(ha,hb) else str(a.id)<str(b.id))
	var result:Array[Dictionary]=[];var heroes:=0
	for ally:Dictionary in rows:
		if result.size()>=int(skill.max_targets):break
		if ally.unit_type=="hero":
			if heroes>=int(skill.max_hero_targets):continue
			heroes+=1
		result.append(ally)
	return result

static func try_action(source:Dictionary,target:Dictionary,c,pending:Dictionary,killers:Dictionary)->bool:
	if source.unit_type in ["hero","worker"] or bool(source.get("neutral",false)) or int(source.hp)<=0 or c._stunned(source):return false
	var skill:Dictionary=source.get("troop_ability",{})
	if skill.is_empty():return false
	var tick:int=c._tick
	if tick<int(source.get("troop_skill_ready_tick_v4",0)) or tick<int(source.get("troop_probe_tick_v4",0)) or int(source.get("mana",0))<int(skill.mana_cost):return false
	if not autonomous_action_allowed(source,c):return false
	source["troop_probe_tick_v4"]=tick+5
	var recipients:Array[Dictionary]=[]
	if skill.effect=="DAMAGE_LINK":recipients=Elites.link_targets(source,skill,c)
	elif skill.effect=="MAGIC_RESIST_BUFF":recipients=_veil(source,skill,c)
	elif skill.delivery=="SELF_BUFF":
		if target.is_empty() or int(target.get("hp",0))<=0 or not c._in_attack_range(source,target):return false
		recipients=[source]
	else:recipients=_targets(source,target,skill,c,pending)
	if recipients.is_empty():return false
	source.mana=int(source.mana)-int(skill.mana_cost)
	source["feedback_skill_id"]=skill.id;source["feedback_skill_rank"]=1;source["feedback_skill_ultimate"]=false
	source["troop_skill_ready_tick_v4"]=tick+int(skill.cooldown_ticks)
	source["last_skill_tick"]=tick;source["last_skill_id"]=skill.id;source["last_skill_level"]=1
	source["last_skill_radius"]=int(skill.get("radius",0));source["last_skill_target_position"]=recipients[0].position
	source["last_skill_targets"]=[]
	if skill.effect=="DAMAGE_LINK":source["elite_link_ledger_r4"]={"cast_tick":tick,"remaining":int(skill.shared_transfer_cap),"expires_tick":tick+int(skill.duration_ticks)}
	c._record_action(source,"SKILL_"+str(skill.id),recipients[0].position)
	c._feedback("CAST",source,recipients[0],{"skill_id":skill.id,"rank":1,"material":skill.get("material",""),"delivery":skill.delivery})
	var benefits:=Buffs.values(source,tick,c._soldiers)
	var amplification:=1.0+(float(benefits.skill_damage_percent)+float(source.get("technology_modifiers_v4",{}).get("skill_damage_percent",0)))/100.0
	for index:int in range(recipients.size()):
		var enemy:Dictionary=recipients[index]
		if skill.delivery=="SELF_BUFF" or skill.effect in ["MAGIC_RESIST_BUFF","DAMAGE_LINK"]:
			var buff:=skill.duplicate(true)
			if skill.effect=="DAMAGE_LINK":buff["cast_tick"]=tick
			if skill.effect=="MAGIC_RESIST_BUFF":buff.magic_resist_percent=int(skill.hero_magic_resist_percent if enemy.unit_type=="hero" else skill.magic_resist_percent)
			Buffs.apply(enemy,buff,tick,str(source.id),"V4_VEIL" if skill.effect=="MAGIC_RESIST_BUFF" else "V4_TROOP_SELF_SKILL")
			c._refresh_stats(enemy);c._feedback("BUFF",source,enemy,{"skill_id":skill.id,"expires_tick":tick+int(skill.duration_ticks)})
			(source.last_skill_targets as Array).append({"id":enemy.id,"position":enemy.position,"effect":skill.effect,"damage":0})
			continue
		var raw:=float(skill.get("damage",0) if index==0 else skill.get("secondary_damage",skill.get("damage",0)))*amplification
		var amount:int=c._resolve_damage(raw,str(skill.attack_type),enemy,source,false,{"id":skill.id,"category":"SKILL"})
		var dealt:Dictionary=c._deal_body_damage_r4(enemy,source,amount,str(skill.attack_type),{"id":skill.id,"category":"SKILL"},pending,killers,true)
		var actual:=int(dealt.primary)
		if int(enemy.hp)-int(pending.get(enemy.id,0))>0:
			if skill.has("control_kind"):
				var field:="root_until_tick" if skill.control_kind=="ROOT" else "stun_until_tick"
				var until:=tick+Damage.control_ticks(c._enhanced_duration(source,int(skill.control_duration_ticks),"HARD"),enemy)
				if until>int(enemy.get(field,-1)):
					enemy[field]=until;enemy["root_source_id" if skill.control_kind=="ROOT" else "stun_source_id"]=source.id
					enemy["root_skill_id" if skill.control_kind=="ROOT" else "stun_skill_id"]=skill.id
					enemy["root_source_faction" if skill.control_kind=="ROOT" else "stun_source_faction"]=source.faction_id
					c._feedback("CONTROL",source,enemy,{"skill_id":skill.id,"status_kind":skill.control_kind,"expires_tick":until})
			if skill.has("dot_total"):
				var signature:={"id":skill.id,"stats_category":"SKILL","status_kind":skill.dot_kind,"status_duration_ticks":skill.dot_duration_ticks,"status_power":float(skill.dot_total)*20.0/float(skill.dot_duration_ticks)*amplification,"fixed_dot_total_v4":float(skill.dot_total)*amplification,"dot_drain_percent":skill.get("dot_drain_percent",0)}
				c._apply_signature(source,enemy,signature)
			if skill.has("status_kind"):c._apply_signature(source,enemy,skill)
		(source.last_skill_targets as Array).append({"id":enemy.id,"position":enemy.position,"damage":actual,"attack_type":skill.attack_type})
	if skill.delivery!="SELF_BUFF" and skill.effect not in ["MAGIC_RESIST_BUFF","DAMAGE_LINK"]:c._consume_buffs(source,"PAID_SKILL")
	source.erase("feedback_skill_id");source.erase("feedback_skill_rank");source.erase("feedback_skill_ultimate")
	return true

static func basic_multiplier(source:Dictionary,target:Dictionary,mods:Dictionary)->float:
	if bool(source.get("neutral",false)) or source.unit_type=="worker":return 1.0
	var percent:=float(mods.get("basic_damage_percent",0))
	var ratio:=float(target.get("hp",0))/maxi(1,int(target.get("max_hp",1)))
	if ratio>0.70:percent+=float(mods.get("high_hp_basic_damage_percent",0))
	if ratio<0.35:percent+=float(mods.get("low_hp_basic_damage_percent",0))
	return 1.0+percent/100.0

static func on_basic_hit(source:Dictionary,target:Dictionary,c,mods:Dictionary)->void:
	var tick:int=c._tick
	Elites.on_basic_hit(source,target,c)
	if source.unit_type=="grave_chain_guard" and tick>=int(source.get("basic_proc_ready_tick_v4",0)):
		c._apply_signature(source,target,Catalog.BASIC_PROCS.grave_chain_guard)
		source["basic_proc_ready_tick_v4"]=tick+160
	if float(mods.get("poison_damage_per_second",0))>0:
		c._apply_signature(source,target,{"id":"VEIN_POISON_EDGE","status_kind":"POISON","status_power":mods.poison_damage_per_second,"status_duration_ticks":mods.poison_duration_ticks})
		Buffs.apply(source,{"id":"VEIN_POISON_EDGE","move_speed_percent":mods.on_hit_move_speed_percent,"duration_ticks":mods.on_hit_move_duration_ticks},tick,str(source.id),"V4_TECH_ON_HIT")
		c._refresh_stats(source)

static func add_line_hits(source:Dictionary,primary:Dictionary,c,pending:Dictionary,killers:Dictionary,building_hits:Array)->void:
	if source.unit_type!="deep_fault_carapace":return
	var spec:Dictionary=source.get("basic_proc_v4",Catalog.BASIC_PROCS.deep_fault_carapace)
	var axis:=Vector2(primary.position-source.position).normalized()
	var candidates:Array[Dictionary]=[]
	for enemy:Dictionary in _pool(c,source.position,int(spec.range)):
		if enemy.id==primary.id or not _legal(source,enemy,spec,pending):continue
		var delta:=Vector2(enemy.position-source.position);var forward:=delta.dot(axis)
		if forward>=0 and forward<=int(spec.range) and absf(delta.cross(axis))<=float(spec.line_width)/2.0+float(enemy.get("radius",0)):candidates.append(enemy)
	_order(candidates,source.position)
	var count:=1
	for enemy:Dictionary in candidates:
		if count>=int(spec.max_targets):break
		var amount:int=c._resolve_damage(float(spec.secondary_damage),str(spec.attack_type),enemy,source,true,{"id":"BASIC","category":"BASIC"})
		var dealt:Dictionary=c._deal_body_damage_r4(enemy,source,amount,str(spec.attack_type),{"id":"BASIC","category":"BASIC"},pending,killers,true)
		var actual:=int(dealt.primary)
		if not source.has("last_action_targets"):source["last_action_targets"]=[]
		(source.last_action_targets as Array).append({"id":enemy.id,"position":enemy.position,"damage":actual,"attack_type":spec.attack_type})
		if not killers.has(enemy.id):killers[enemy.id]=source.id
		count+=1
