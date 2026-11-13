extends RefCounted
## Automatic body mechanics, never operational-AI commands or combat rollouts.
## One post-movement spatial preparation; damage looks up bounded recipients.
const Damage=preload("res://src/simulation/strategic_damage_rules.gd")
const Context=preload("res://src/simulation/strategic_action_context_m94.gd")
const Visibility=preload("res://src/simulation/strategic_visibility_r9.gd")

static func _military(body:Dictionary)->bool:
	return not body.is_empty() and int(body.get("hp",0))>0 and not body.has("building_type") and str(body.get("unit_type",""))!="worker" and not bool(body.get("neutral",false)) and not bool(body.get("summoned",false))

static func _combat_target(body:Dictionary)->bool:
	# Offensive effects can fight wild creatures. Protection is deliberately
	# narrower: neutral/worker/summon bodies never receive the allied link.
	return not body.is_empty() and int(body.get("hp",0))>0 and not body.has("building_type") and str(body.get("unit_type",""))!="worker"

static func _near(a:Dictionary,b:Dictionary,radius:int)->bool:
	return Vector2(a.position).distance_squared_to(Vector2(b.position))<=float(radius*radius)

static func _pool(c,point:Vector2i,radius:int)->Array[Dictionary]:
	var context:RefCounted=c._m94_support_context()
	return context.radius_pool(point,radius) if context!=null else c._ordered_units()

static func _order(rows:Array[Dictionary],point:Vector2i)->void:
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var da:=Vector2(a.position).distance_squared_to(Vector2(point));var db:=Vector2(b.position).distance_squared_to(Vector2(point))
		return da<db if da!=db else str(a.id)<str(b.id))

static func prepare(c,pulse:bool=false,pending:Dictionary={},killers:Dictionary={})->void:
	c._r4_elite_dirty=false
	var bodies:Array[Dictionary]=c._ordered_units()
	c._r4_guard_targets={}
	var context:RefCounted=c._m94_support_context()
	if context==null:context=Context.new(bodies)
	var due:Array[Dictionary]=[]
	for source:Dictionary in bodies:
		if not _military(source):continue
		var spec:Dictionary=source.get("elite_passive_r4",{})
		if spec.get("effect","")=="GUARD_AURA":
			if int(source.hp)*100<=int(source.max_hp)*int(spec.source_min_hp_percent):continue
			var allies:Array[Dictionary]=[]
			for ally:Dictionary in context.radius_pool(source.position,int(spec.radius)):
				if ally.id!=source.id and ally.side==source.side and _military(ally) and _near(source,ally,int(spec.radius)):allies.append(ally)
			_order(allies,source.position)
			for index:int in range(mini(int(spec.max_targets),allies.size())):
				var id:=str(allies[index].id)
				if not c._r4_guard_targets.has(id):c._r4_guard_targets[id]={}
				c._r4_guard_targets[id][str(source.id)]=spec
		elif pulse and spec.get("effect","")=="BURN_AURA":
			# Advance only on an actual BATTLE step, not snapshots/World messages
			# or absolute tick jumps. A newly spawned source earns its first pulse.
			if int(source.get("elite_burn_last_step_tick_r4",-1))==int(c._tick):continue
			source["elite_burn_last_step_tick_r4"]=int(c._tick)
			var elapsed:=int(source.get("elite_burn_elapsed_r4",0))+1
			source["elite_burn_elapsed_r4"]=elapsed
			if elapsed%int(spec.pulse_ticks)==0:due.append(source)
	if not pulse or due.is_empty():return
	var selected:Dictionary={}
	for source:Dictionary in due:
		var spec:Dictionary=source.elite_passive_r4;var enemies:Array[Dictionary]=[]
		for target:Dictionary in context.radius_pool(source.position,int(spec.radius)):
			if target.side!=source.side and _combat_target(target) and _near(source,target,int(spec.radius)) and int(target.hp)-int(pending.get(target.id,0))>0 and int(c._tick)>=int(target.get("elite_burn_ready_tick_r4",0)):enemies.append(target)
		_order(enemies,source.position)
		for index:int in range(mini(int(spec.max_targets),enemies.size())):
			var target:Dictionary=enemies[index];var old:Dictionary=selected.get(str(target.id),{})
			if old.is_empty() or int(spec.damage)>int(old.elite_passive_r4.damage) or (int(spec.damage)==int(old.elite_passive_r4.damage) and str(source.id)<str(old.id)):selected[str(target.id)]=source
	for id:String in selected:
		var source:Dictionary=selected[id];var target:Dictionary=c._soldiers[id];var spec:Dictionary=source.elite_passive_r4
		target["elite_burn_ready_tick_r4"]=int(c._tick)+int(spec.pulse_ticks)
		var cause:={"id":str(spec.id),"category":"OTHER","dot":true}
		var amount:int=c._resolve_damage(float(spec.damage),str(spec.attack_type),target,source,false,cause)
		var dealt:Dictionary=c._deal_body_damage_r4(target,source,amount,str(spec.attack_type),cause,pending,killers,true)
		if int(dealt.total)>0:
			source["last_elite_pulse_tick_r4"]=int(c._tick)
			c._feedback("STATUS",source,target,{"skill_id":str(spec.id),"status_kind":"BURN","phase":"PULSE","expires_tick":int(c._tick)+12,"amount":dealt.primary})

static func threatened(ally:Dictionary,c)->bool:
	if int(c._tick)-int(ally.get("last_damage_tick",-1000000))<=60:return true
	for enemy:Dictionary in _pool(c,ally.position,600):
		if enemy.side!=ally.side and int(enemy.get("hp",0))>0 and Visibility.can_observe(enemy,str(ally.side)) and c._can_attack(enemy,ally) and c._in_attack_range(enemy,ally):return true
	for enemy:Dictionary in c._ordered_buildings():
		if enemy.side!=ally.side and int(enemy.get("hp",0))>0 and Visibility.can_observe(enemy,str(ally.side)) and bool(enemy.get("defense_active",false)) and c._in_attack_range(enemy,ally):return true
	return false

static func link_targets(source:Dictionary,skill:Dictionary,c)->Array[Dictionary]:
	var rows:Array[Dictionary]=[]
	for ally:Dictionary in _pool(c,source.position,int(skill.range)):
		if ally.id==source.id or ally.side!=source.side or not _military(ally) or not _near(source,ally,int(skill.range)) or not threatened(ally,c):continue
		var covered:=false
		for buff:Dictionary in ally.get("source_buffs",{}).values():
			if buff.get("effect","")=="DAMAGE_LINK" and int(buff.get("expires_tick",0))>int(c._tick)+20 and not protector(ally,c).is_empty():covered=true;break
		if not covered:rows.append(ally)
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ha:=float(a.hp)/maxi(1,int(a.max_hp));var hb:=float(b.hp)/maxi(1,int(b.max_hp))
		return ha<hb if not is_equal_approx(ha,hb) else str(a.id)<str(b.id))
	return rows.slice(0,int(skill.max_targets))

static func protector(target:Dictionary,c)->Dictionary:
	if not _military(target):return {}
	var entries:Array[Dictionary]=[]
	var guards:Dictionary=c._r4_guard_targets.get(str(target.id),{})
	for source_id:String in guards:
		entries.append({"source_id":source_id,"spec":guards[source_id],"paid":false})
	for buff:Dictionary in target.get("source_buffs",{}).values():
		if buff.get("effect","")=="DAMAGE_LINK" and int(buff.get("expires_tick",0))>int(c._tick):entries.append({"source_id":str(buff.source_id),"spec":buff,"paid":true})
	var best:Dictionary={}
	for entry:Dictionary in entries:
		var source:Dictionary=c._soldiers.get(str(entry.source_id),{});var spec:Dictionary=entry.spec
		if not _military(source) or source.id==target.id or source.side!=target.side or not _near(source,target,int(spec.radius)):continue
		var floor_hp:=int(spec.get("source_min_hp",1))
		if entry.paid:
			var ledger:Dictionary=source.get("elite_link_ledger_r4",{})
			if int(ledger.get("expires_tick",0))<=int(c._tick) or int(ledger.get("remaining",0))<=0 or int(ledger.get("cast_tick",-1))!=int(spec.get("cast_tick",-2)):continue
		else:floor_hp=ceili(float(source.max_hp)*float(spec.source_min_hp_percent)/100.0)
		var available:int=int(source.hp)-int(c._r4_pending_damage.get(str(source.id),0))-floor_hp
		if available<=0:continue
		var percent:=int(spec.hero_redirect_percent if target.unit_type=="hero" else spec.redirect_percent)
		if best.is_empty() or percent>int(best.percent) or (percent==int(best.percent) and str(source.id)<str(best.source.id)):
			best={"source":source,"spec":spec,"paid":entry.paid,"percent":percent,"available":available}
	return best

static func on_basic_hit(source:Dictionary,target:Dictionary,c)->void:
	var spec:Dictionary=source.get("elite_passive_r4",{})
	if spec.get("effect","")!="BASIC_STUN" or not _combat_target(target):return
	var hits:=mini(int(spec.hit_interval),int(source.get("elite_stun_hits_r4",0))+1)
	source["elite_stun_hits_r4"]=hits
	if hits<int(spec.hit_interval) or int(c._tick)<int(source.get("elite_stun_ready_tick_r4",0)):return
	if int(target.hp)-int(c._r4_pending_damage.get(str(target.id),0))<=0:return
	var until:int=int(c._tick)+Damage.control_ticks(int(spec.stun_ticks),target)
	if until<=int(target.get("stun_until_tick",-1)):return
	source["elite_stun_hits_r4"]=0;source["elite_stun_ready_tick_r4"]=int(c._tick)+int(spec.cooldown_ticks)
	target["stun_until_tick"]=until;target["stun_source_id"]=source.id;target["stun_skill_id"]=spec.id;target["stun_source_faction"]=source.faction_id
	source["last_elite_stun_tick_r4"]=int(c._tick)
	c._feedback("CONTROL",source,target,{"skill_id":spec.id,"status_kind":"STUN","expires_tick":until})

static func visual_statuses(unit:Dictionary,c)->Array[Dictionary]:
	# Read-only observed eligibility. Never renew a lease or mutate a ledger.
	var rows:Array[Dictionary]=[]
	if not _military(unit):return rows
	var spec:Dictionary=unit.get("elite_passive_r4",{})
	if spec.get("effect","")=="BURN_AURA" or (spec.get("effect","")=="GUARD_AURA" and int(unit.hp)*100>int(unit.max_hp)*int(spec.source_min_hp_percent)):
		rows.append({"id":spec.id,"kind":"AURA","remaining_ticks":1,"source_id":unit.id,"source_faction":unit.faction_id,"radius":spec.radius,"elite_source":true})
	var guard:=protector(unit,c)
	if not guard.is_empty():
		rows.append({"id":guard.spec.id,"kind":"GUARD","remaining_ticks":maxi(1,int(guard.spec.get("expires_tick",int(c._tick)+1))-int(c._tick)),"source_id":guard.source.id,"source_faction":guard.source.faction_id,"elite_source":false})
	return rows
