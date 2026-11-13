extends RefCounted
## M84: query-local center grid for engagement.
## R18 paid actions respect effective orders and observed engagement.
## No cross-action cache; passive mana preparation remains order-independent.
const Buffs=preload("res://src/simulation/strategic_combat_buffs.gd")
const TroopRuntime=preload("res://src/simulation/strategic_troop_runtime_v4.gd")
const Visibility=preload("res://src/simulation/strategic_visibility_r9.gd")
const VERSION="m58-six-army-support-v1"
const CATALOG={
	"grove_mender":{"id":"MARCH_CADENCE","name":"行阵节拍","range":160,"mana_cost":25,"cooldown_ticks":200,"duration_ticks":160,"attack_speed_percent":25,"description":"为160范围内一名交战中的非支援正规兵提高攻速25%，持续8秒。消耗25法力，冷却10秒；施放后保留至少15法力用于治疗。"},
	"ember_mender":{"id":"BORROWED_EMBERS","name":"借烬还息","range":160,"mana_cost":0,"cooldown_ticks":80,"max_targets":2,"mana_restore":6,"description":"160范围内敌方正规兵阵亡时，为自身周围160范围内最多2名缺蓝友军各恢复6法力，英雄恢复3法力。冷却4秒，不消耗法力。"},
	"repair_drone":{"id":"TRIPLE_OVERCLOCK","name":"三拍超频","range":170,"mana_cost":24,"cooldown_ticks":200,"duration_ticks":120,"attack_speed_percent":35,"charges":3,"charge_kind":"ATTACK","description":"为170范围内一名交战中的机械正规兵提高攻速35%，限接下来3次普攻、最多持续6秒；支援兵除外。消耗24法力，冷却10秒；施放后保留至少15法力。"},
	"root_mender":{"id":"ROOT_NETWORK","name":"根网汲流","range":160,"mana_cost":0,"max_targets":4,"mana_per_second":0.6,"description":"为160范围内最多4名其他缺蓝友军每秒回复0.6法力，英雄每秒回复0.3法力。同名光环不叠加；离开范围或来源阵亡后停止。"},
	"rune_keeper":{"id":"HEARTH_CHARGE","name":"炉符蓄能","range":160,"mana_cost":22,"cooldown_ticks":240,"duration_ticks":200,"skill_damage_percent":18,"healing_percent":18,"charges":2,"charge_kind":"PAID_SKILL","description":"使160范围内一名有法力的其他交战友军接下来2次消耗法力的主动伤害或治疗效果提高18%，最多持续10秒。消耗22法力，冷却12秒；施放后保留至少15法力。"},
	"spore_mender":{"id":"SPORE_PRESSURE","name":"孢压易感","range":180,"radius":90,"max_targets":3,"mana_cost":24,"cooldown_ticks":240,"duration_ticks":120,"slow_percent":20,"dot_duration_percent":25,"description":"在180施法距离内，使半径90内最多3名敌军减速20%、持续6秒，并使期间新附加的灼烧与中毒时长提高25%。消耗24法力，冷却12秒；施放后保留至少15法力。"},
}

static func visual_skill(id:String)->Dictionary:
	for spec:Dictionary in CATALOG.values():
		if spec.id==id:
			var result:=spec.duplicate(true)
			result.merge({"effect":"SLOW" if id=="SPORE_PRESSURE" else "DAMAGE_BUFF","name":spec.name,"level":1,"passive":false,"ultimate":false,"target_mode":"POINT","delivery":"AREA" if id=="SPORE_PRESSURE" else "SINGLE","max_targets":spec.get("max_targets",1),"radius":spec.get("radius",25),"attack_type":"ARCANE"},true)
			return result
	return {}

static func _owner(body:Dictionary,c:RefCounted)->Dictionary:return c.get("_hero_data").get(str(body.id),body)
static func _all(c:RefCounted)->Array[Dictionary]:return c._ordered_units()
static func _near(a:Dictionary,b:Dictionary,r:int)->bool:return (a.position as Vector2i).distance_squared_to(b.position)<=r*r
static func _regular(body:Dictionary)->bool:return int(body.get("hp",0))>0 and body.get("unit_type","") not in ["hero","worker"] and not body.has("building_type") and not bool(body.get("neutral",false)) and not bool(body.get("summoned",false))
static func _engagement_grid_m84(bodies:Array[Dictionary])->Dictionary:
	# Only positions/membership in this synchronous action are reused. Do not
	# keep this table between support actions, attacks, deaths or movement.
	if bodies.size()<64:return {}
	var buckets:Dictionary={}
	for enemy:Dictionary in bodies:
		if typeof(enemy.get("position"))!=TYPE_VECTOR2I:return {}
		var point:Vector2i=enemy.position
		if absi(point.x)>32768 or absi(point.y)>32768:return {}
		var key:=Vector2i(floori(float(point.x)/192.0),floori(float(point.y)/192.0))
		if not buckets.has(key):buckets[key]=[]
		buckets[key].append(enemy)
	return {"buckets":buckets}
static func _observed_enemy(body:Dictionary,enemy:Dictionary,reach:int)->bool:
	return enemy.side!=body.side and int(enemy.hp)>0 and Visibility.can_observe(enemy,str(body.side)) and _near(body,enemy,reach)

static func _engaged_m84(body:Dictionary,bodies:Array[Dictionary],grid:Dictionary={})->bool:
	var reach:=maxi(180,int(body.attack_range)+30)
	if grid.is_empty() or reach>4096 or typeof(body.get("position"))!=TYPE_VECTOR2I:
		for enemy:Dictionary in bodies:
			if _observed_enemy(body,enemy,reach):return true
		return false
	var point:Vector2i=body.position
	if absi(point.x)>32768 or absi(point.y)>32768:
		for enemy:Dictionary in bodies:
			if _observed_enemy(body,enemy,reach):return true
		return false
	var min_x:=floori(float(point.x-reach)/192.0)
	var max_x:=floori(float(point.x+reach)/192.0)
	var min_y:=floori(float(point.y-reach)/192.0)
	var max_y:=floori(float(point.y+reach)/192.0)
	# Very wide effects are cheaper through the existing complete scan.
	if (max_x-min_x+1)*(max_y-min_y+1)>=bodies.size():
		for enemy:Dictionary in bodies:
			if _observed_enemy(body,enemy,reach):return true
		return false
	for y:int in range(min_y,max_y+1):
		for x:int in range(min_x,max_x+1):
			for enemy:Dictionary in grid.buckets.get(Vector2i(x,y),[]):
				if _observed_enemy(body,enemy,reach):return true
	return false
static func _already(body:Dictionary,id:String,tick:int)->bool:
	for entry:Dictionary in body.get("source_buffs",{}).values():
		if entry.id==id and int(entry.expires_tick)>tick and int(entry.get("charges",-1))!=0:return true
	return false

static func prepare(c:RefCounted)->void:
	var bodies:=_all(c)
	for body:Dictionary in bodies:body["support_mana_per_second"]=0.0;body["support_aura_source_id"]=""
	for source:Dictionary in bodies:
		if source.unit_type!="root_mender" or int(source.hp)<=0 or bool(source.get("neutral",false)):continue
		var candidates:Array[Dictionary]=[]
		var context:RefCounted=c._m93_context_current() if c.has_method("_m93_context_current") else null
		var near_bodies:Array[Dictionary]=context.radius_pool(source.position,160) if context!=null else bodies
		for ally:Dictionary in near_bodies:
			var owner:=_owner(ally,c)
			if ally.id!=source.id and ally.side==source.side and int(ally.hp)>0 and int(owner.get("max_mana",0))>int(owner.get("mana",0)) and _near(source,ally,160):candidates.append(ally)
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a.unit_type)!="hero" if (a.unit_type=="hero")!=(b.unit_type=="hero") else str(a.id)<str(b.id))
		if candidates.size()>4:candidates.resize(4)
		for ally:Dictionary in candidates:
			ally.support_mana_per_second=0.3 if ally.unit_type=="hero" else 0.6
			ally.support_aura_source_id=source.id
	for ally:Dictionary in bodies:
		if int(ally.hp)<=0:continue
		var owner:=_owner(ally,c)
		# Empty finite-buff state has no cleanup or contribution. Keep the
		# original complete resolver for EVERY nonempty state, including only
		# expired/exhausted or non-mana entries: it owns their removal too.
		var mana_per_second:=0.0
		if not (ally.get("source_buffs",{}) as Dictionary).is_empty():
			var values:=Buffs.values(ally,int(c.get("_tick")),c.get("_soldiers"))
			mana_per_second=float(values.mana_per_second)
		var rate:=float(ally.support_mana_per_second)+mana_per_second
		var credit:=float(ally.get("support_mana_carry",0))+rate/20.0
		# Twenty 0.1 MP ticks must pay 2 MP at the boundary, not defer one
		# point because binary addition happened to leave 1.9999999999999998.
		var whole:=floori(credit+0.000000001)
		owner.mana=mini(int(owner.get("max_mana",0)),int(owner.get("mana",0))+whole)
		ally["support_mana_carry"]=maxf(0.0,credit-float(whole))

static func try_action(source:Dictionary,c:RefCounted)->bool:
	# A neutral visual identity never grants a playable paid support ability.
	if bool(source.get("neutral",false)) or source.get("side","")=="NEUTRAL":return false
	if not CATALOG.has(source.unit_type) or source.unit_type in ["root_mender","ember_mender"]:return false
	if not TroopRuntime.autonomous_action_allowed(source,c):return false
	var tick:=int(c.get("_tick"))
	var spec:Dictionary=CATALOG[source.unit_type]
	if tick<int(source.get("support_ready_tick",-1)) or int(source.mana)<int(spec.mana_cost)+15:return false
	var injured:Dictionary=c._nearest_injured(source,int(source.get("heal_range",0)))
	if not injured.is_empty() and int(injured.hp)*100<int(injured.max_hp)*55 and int(source.heal_cooldown_ticks)==0:return false
	# Positions/membership are fixed only in Combat's synchronous post-move
	# action scope. Bodies, HP/MP, buffs and DPS remain current references.
	# Standalone consumers retain the original per-query construction.
	var bodies:Array[Dictionary]=_all(c)
	var context:RefCounted=c._m94_support_context() if c.has_method("_m94_support_context") else null
	var engagement_grid_m84:Dictionary=context.engagement_grid() if context!=null else _engagement_grid_m84(bodies)
	var near_bodies:Array[Dictionary]=context.radius_pool(source.position,int(spec.range)) if context!=null else bodies
	var source_engaged_m84:=false
	var source_checked_m84:=false
	var candidates:Array[Dictionary]=[]
	var area_candidates:Array[Dictionary]=[]
	for ally:Dictionary in near_bodies:
		if ally.id==source.id or int(ally.hp)<=0 or not _near(source,ally,int(spec.range)):continue
		if source.unit_type=="spore_mender":
			if ally.side!=source.side:
				if not source_checked_m84:
					source_engaged_m84=_engaged_m84(source,bodies,engagement_grid_m84)
					source_checked_m84=true
				if source_engaged_m84:
					area_candidates.append(ally)
					if Visibility.can_observe(ally,str(source.side)):candidates.append(ally)
			continue
		if ally.side!=source.side or _already(ally,str(spec.id),tick):continue
		if source.unit_type=="rune_keeper":
			if int(_owner(ally,c).get("max_mana",0))<=0:continue
		elif not _regular(ally) or "SUPPORT" in ally.get("tags",[]) or (source.unit_type=="repair_drone" and "MACHINE" not in ally.get("tags",[])):continue
		if _engaged_m84(ally,bodies,engagement_grid_m84):candidates.append(ally)
	if candidates.is_empty():return false
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var da:=float(a.damage)/maxi(1,int(a.attack_cooldown_ticks))
		var db:=float(b.damage)/maxi(1,int(b.attack_cooldown_ticks))
		return da>db if not is_equal_approx(da,db) else str(a.id)<str(b.id))
	var target:Dictionary=candidates[0]
	if source.unit_type=="spore_mender":
		# Only the autonomous anchor requires visibility. Preserve incidental
		# area hits and the primary's place inside the total three-target cap.
		area_candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			var da:=float(a.damage)/maxi(1,int(a.attack_cooldown_ticks))
			var db:=float(b.damage)/maxi(1,int(b.attack_cooldown_ticks))
			return da>db if not is_equal_approx(da,db) else str(a.id)<str(b.id))
		var area_targets:Array[Dictionary]=[target]
		for enemy:Dictionary in area_candidates:
			if enemy.id!=target.id and _near(target,enemy,90):area_targets.append(enemy)
		var count:=0
		for enemy:Dictionary in area_targets:
			if count>=3:break
			c._apply_signature(source,enemy,{"status_kind":"SLOW","status_power":20,"status_duration_ticks":120})
			if not enemy.has("duration_vulnerabilities"):enemy["duration_vulnerabilities"]={}
			enemy.duration_vulnerabilities[spec.id]={"expires_tick":tick+120,"dot_duration_percent":25}
			count+=1
	else:
		Buffs.apply(target,spec,tick,str(source.id),"SUPPORT")
		c._refresh_stats(target)
		c._feedback("BUFF",source,target,{"skill_id":spec.id})
	source.mana=int(source.mana)-int(spec.mana_cost)
	source["support_ready_tick"]=tick+int(spec.cooldown_ticks)
	c._record_action(source,"SKILL_"+str(spec.id),target.position)
	c._feedback("CAST",source,target,{"skill_id":spec.id,"rank":1})
	return true

static func on_death(victim:Dictionary,c:RefCounted)->void:
	if not _regular_dead(victim) or bool(victim.get("support_death_processed",false)):return
	victim["support_death_processed"]=true
	var tick:=int(c.get("_tick"))
	var receipt:="%s:%s"%[victim.id,victim.get("life_generation",1)]
	for source:Dictionary in _all(c):
		if source.unit_type!="ember_mender" or int(source.hp)<=0 or bool(source.get("neutral",false)) or source.side=="NEUTRAL" or source.side==victim.side or not _near(source,victim,160):continue
		if source.get("last_support_death","")==receipt or tick<int(source.get("support_ready_tick",-1)):continue
		var targets:Array[Dictionary]=[]
		for ally:Dictionary in _all(c):
			var owner:=_owner(ally,c)
			if int(ally.hp)>0 and ally.side==source.side and _near(source,ally,160) and int(owner.get("max_mana",0))>int(owner.get("mana",0)):targets.append(ally)
		targets.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			if (a.unit_type=="hero")!=(b.unit_type=="hero"):return a.unit_type!="hero"
			var ao:=_owner(a,c);var bo:=_owner(b,c)
			var da:=int(ao.max_mana)-int(ao.mana);var db:=int(bo.max_mana)-int(bo.mana)
			return da>db if da!=db else str(a.id)<str(b.id))
		if targets.is_empty():continue
		if targets.size()>2:targets.resize(2)
		for ally:Dictionary in targets:
			var owner:=_owner(ally,c)
			owner.mana=mini(int(owner.max_mana),int(owner.mana)+(3 if ally.unit_type=="hero" else 6))
			c._feedback("BUFF",source,ally,{"skill_id":"BORROWED_EMBERS"})
		source["last_support_death"]=receipt
		source["support_ready_tick"]=tick+80

static func _regular_dead(body:Dictionary)->bool:
	return body.get("unit_type","") not in ["hero","worker",""] and not body.has("building_type") and not bool(body.get("neutral",false)) and not bool(body.get("summoned",false)) and int(body.get("hp",0))<=0
