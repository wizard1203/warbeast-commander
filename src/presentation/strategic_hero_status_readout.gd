extends RefCounted
## Detached HUD projection, never an economic/combat authority. Prepare once per
## HUD refresh and share across cards; final combat values come from soldiers.
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Buffs = preload("res://src/simulation/strategic_combat_buffs.gd")
const Innates = preload("res://src/simulation/strategic_hero_innates.gd")
const Progression = preload("res://src/simulation/strategic_hero_progression.gd")
const Support = preload("res://src/simulation/strategic_army_support.gd")
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const BreakdownM75 = preload("res://src/presentation/strategic_attribute_breakdown_m75.gd")
const TechnologiesV4 = preload("res://src/simulation/strategic_faction_technologies_v4.gd")
const AURA_FIELDS = ["damage","armor","speed","move_speed_percent","heal_per_second","mana_per_second"]
const AURA_LABELS = {"damage":"普攻","armor":"护甲","speed":"移动步长","move_speed_percent":"移速%","heal_per_second":"生命/秒","mana_per_second":"蓝量/秒"}
const STATUS_NAMES = {"STUN":"眩晕","ROOT":"定身","SLOW":"减速","BURN":"灼烧","POISON":"中毒","ARMOR_BREAK":"破甲","HEAL":"持续回复","GUARD":"护盾","FERVOR":"强化"}

static func prepare(snapshot: Dictionary) -> Dictionary:
	return _prepare_context_m76(snapshot,true)

static func prepare_borrowed_m76(snapshot: Dictionary) -> Dictionary:
	# Main already owns an immutable detached observation. This internal
	# read-only view is valid only for that observation, and never goes back to
	# Session/Combat or outside the presentation owner. Public prepare() still
	# detaches every body for general callers and historical contracts.
	return _prepare_context_m76(snapshot,false)

static func _prepare_context_m76(snapshot:Dictionary,detached:bool)->Dictionary:
	var context := {"tick":int(snapshot.get("tick",0)),"bodies":{},"heroes":{},"auras":{},"source_count":0,"candidate_checks":0}
	for body: Dictionary in snapshot.get("soldiers",[]): context.bodies[str(body.id)] = body.duplicate(true) if detached else body
	for hero: Dictionary in snapshot.get("heroes",{}).get("officers",[]): context.heroes[str(hero.get("unit_id",hero.get("id","")))] = hero.duplicate(true) if detached else hero
	# This only projects provenance. Values and eligibility order mirror
	# Combat._rebuild_hero_auras; never apply its values to a soldier here.
	var ids: Array = context.heroes.keys()
	ids.sort()
	for source_id: String in ids:
		var source: Dictionary = context.bodies.get(source_id,{})
		if int(source.get("hp",0)) <= 0: continue
		var hero: Dictionary = context.heroes[source_id]
		var auras: Array[Dictionary] = []
		for skill_id: String in hero.get("skill_levels",{}):
			var rank := int(hero.skill_levels[skill_id])
			if rank <= 0: continue
			var skill := Heroes.skill_at_level(skill_id,rank)
			if skill.get("effect","") != "AURA": continue
			auras.append({"id":skill_id,"name":skill.name,"kind":"SKILL_AURA","description":skill.description,"radius":int(skill.aura_radius),"max_targets":int(skill.max_targets),"damage":float(skill.get("aura_damage",0)),"armor":float(skill.get("aura_armor",0)),"speed":float(skill.get("aura_speed",0)),"move_speed_percent":float(skill.get("aura_move_speed_percent",0)),"heal_per_second":float(skill.get("aura_heal",0))})
		var gear := Items.equipment_aura(hero)
		if int(gear.radius) > 0:
			gear.merge({"kind":"ITEM_AURA","description":"同类光环不叠加，取最高效果。"})
			auras.append(gear)
		for aura: Dictionary in auras:
			context.source_count += 1
			var candidates: Array[Dictionary] = []
			for body: Dictionary in context.bodies.values():
				context.candidate_checks += 1
				if body.get("side","") == source.get("side","") and int(body.get("hp",0)) > 0 and _distance(body,source) <= int(aura.radius)*int(aura.radius): candidates.append(body)
			candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
				var da := _distance(a,source)
				var db := _distance(b,source)
				return da < db if da != db else str(a.id) < str(b.id))
			if candidates.size() > int(aura.max_targets): candidates.resize(int(aura.max_targets))
			for body: Dictionary in candidates:
				if not context.auras.has(str(body.id)): context.auras[str(body.id)] = {}
				var winners: Dictionary = context.auras[str(body.id)]
				for field: String in AURA_FIELDS:
					var amount := float(aura.get(field,0))
					if amount <= float(winners.get(field,{}).get("amount",0)): continue
					var identity := _gear_aura_identity(hero,field,amount) if aura.kind == "ITEM_AURA" else aura
					winners[field] = {"id":identity.get("id",""),"name":identity.get("name","装备光环"),"kind":aura.kind,"source_id":source_id,"amount":amount,"field":field,"radius":aura.radius,"description":identity.get("description",aura.description)}
	return context

static func read(hero: Dictionary, context: Dictionary) -> Dictionary:
	var id := str(hero.get("unit_id",hero.get("id","")))
	var subject: Dictionary = context.get("heroes",{}).get(id,hero)
	var body: Dictionary = context.get("bodies",{}).get(id,subject)
	var tick := int(context.get("tick",0))
	var alive := int(body.get("hp",0)) > 0 and bool(body.get("alive",true))
	var buffs := Buffs.values(body.duplicate(true),tick,context.get("bodies",{}))
	var gear := Items.equipment_stats(subject)
	var technology_context:=TechnologiesV4.context_for(subject)
	var technology_modifiers:=TechnologiesV4.resolve(str(technology_context.get("faction","")),technology_context.get("levels",{}))
	var active := Items.active_bonus(subject,tick)
	var interval := int(body.get("attack_cooldown_ticks",0))
	var values := {"damage":body.get("damage",0),"armor":float(body.get("armor",0)),"attack_interval_ticks":interval,"attack_speed_percent":float(body.get("attack_speed_percent",0)),"move_speed":float(body.get("speed_exact",body.get("speed",0)))*20.0,"magic_resist_percent":float(body.get("magic_resist_percent",0)),"attack_range":body.get("attack_range",0),"control_resist_percent":float(body.get("control_resist_percent",0)),"spell_damage_percent":float(gear.skill_damage_percent)+float(active.skill_damage_percent)+float(buffs.skill_damage_percent),"healing_percent":float(gear.healing_percent)+float(active.healing_percent)+float(buffs.healing_percent),"hp_regen":0.0,"mana_regen":0.0}
	values.spell_damage_percent+=float(technology_modifiers.skill_damage_percent)
	values.healing_percent+=float(technology_modifiers.healing_percent)
	if alive:
		values.hp_regen = float(body.get("hp_regen_per_second",0.0))+float(gear.hp_regen_per_second)+float(active.hp_regen_per_second)
		values.mana_regen = 20.0/maxi(1,int(subject.get("mana_regen_ticks",Heroes.MANA_REGEN_TICKS)))+float(gear.mana_regen_per_second)+float(active.mana_regen_per_second)+float(buffs.mana_per_second)+float(body.get("support_mana_per_second",0))+float(body.get("innate_aura",{}).get("mana_regen_per_second",0))
		values.mana_regen+=float(technology_modifiers.mana_regen_per_second)
		for field: String in context.get("auras",{}).get(id,{}):
			var aura: Dictionary = context.auras[id][field]
			if field == "heal_per_second": values.hp_regen += float(aura.amount)
			if field == "mana_per_second": values.mana_regen += float(aura.amount)
		var rest := 0
		var march := 0
		for item_id: String in subject.get("equipment",[]):
			var item: Dictionary = Items.ITEMS.get(item_id,{})
			if tick-int(body.get("last_damage_tick",-1000000)) >= 100:
				rest = maxi(rest,int(item.get("rest_regen",0)))
				if tick-int(body.get("last_move_tick",-1000000)) <= 20: march = maxi(march,int(item.get("march_regen",0)))
		values.hp_regen += float(rest+march)/2.0
		if subject.get("archetype","") == "VINE_WARDEN" and tick-int(body.get("innate_state",{}).get("still_since",tick)) >= 40: values.hp_regen += float(Innates.values("VINE_WARDEN",int(subject.get("level",1))).hp_per_second)
	var stats: Array[Dictionary] = []
	_stat(stats,"damage","attack","攻击",str(values.damage),Damage.attack_summary(str(body.get("attack_type","CHAOS")))+"\n普通攻击的面板伤害。对特定目标触发的加成单独计算。")
	_stat(stats,"armor","armor","护甲","%s (%.0f%%)"%[values.armor,Damage.armor_factor(values.armor)*100],Damage.numeric_armor_summary(values.armor)+"\n"+Damage.armor_summary(str(body.get("armor_type","SACRED"))))
	_stat(stats,"attack_speed","attack_speed","攻速","%.2f/s"%(20.0/interval) if interval > 0 else "—","当前攻击间隔%.2f秒；攻速加成%s%%。"%[float(interval)/20.0,values.attack_speed_percent])
	_stat(stats,"move_speed","move","移速","%.0f"%values.move_speed,"每秒移动距离，包含装备、光环和减速效果。")
	_stat(stats,"range","range","射程",str(values.attack_range),"当前普攻射程；不等于技能施法距离。")
	_stat(stats,"magic_resist","magic_resist","魔抗","%s%%"%values.magic_resist_percent,"奥术伤害在类型和数值护甲结算后，再保留%s%%。"%(100-values.magic_resist_percent))
	_stat(stats,"hp_regen","health","回血","%.2f/s"%values.hp_regen,"每秒持续恢复的生命，包含装备、天赋与光环；限次治疗在状态栏查看。")
	_stat(stats,"mana_regen","mana","回蓝","%.2f/s"%values.mana_regen,"每秒持续恢复的法力；击杀和施法触发的返蓝另计。")
	_stat(stats,"spell_amp","spell","技能","+%s%%"%values.spell_damage_percent,"伤害技能的额外百分比加成。天赋的条件效果单独计算；主动治疗加成+%s%%。"%values.healing_percent)
	var effective := {"damage":float(values.damage),"armor":float(values.armor),"attack_speed":20.0/interval if interval>0 else 0.0,"move_speed":float(values.move_speed),"range":float(values.attack_range),"magic_resist":float(values.magic_resist_percent),"hp_regen":float(values.hp_regen),"mana_regen":float(values.mana_regen)}
	for index: int in range(stats.size()):
		var stat_id := str(stats[index].id)
		if not effective.has(stat_id):continue
		var suffix := "/s" if stat_id in ["attack_speed","hp_regen","mana_regen"] else "%" if stat_id=="magic_resist" else ""
		stats[index]=BreakdownM75.apply(stats[index],body,float(effective[stat_id]),suffix)
		if stat_id=="armor":stats[index].value+=" (%.0f%%)"%(Damage.armor_factor(float(values.armor))*100)
	var level := clampi(int(subject.get("level",1)),1,Progression.MAX_LEVEL)
	var xp := int(subject.get("xp",0))
	var floor_xp := int(Progression.XP_THRESHOLDS[level-1])
	var next_xp := Progression.next_level_xp(level)
	return {"id":id,"alive":alive,"tick":tick,"stats":stats,"current":values,"skills":_skills(subject),"effects":_effects(subject,body,context,alive),"hp":int(body.get("hp",0)),"max_hp":int(body.get("max_hp",1)),"mana":int(subject.get("mana",0)),"max_mana":int(subject.get("max_mana",0)),"xp":xp,"xp_floor":floor_xp,"next_level_xp":next_xp,"xp_ratio":clampf(float(xp-floor_xp)/maxi(1,next_xp-floor_xp),0,1) if next_xp > 0 else 1.0}

static func _stat(list: Array[Dictionary], id: String, symbol: String, label: String, value: String, description: String) -> void:
	list.append({"id":id,"symbol":symbol,"label":label,"value":value,"description":description})

static func _skills(hero: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill: Dictionary in hero.get("skills",[]):
		var rank := int(hero.get("skill_levels",{}).get(str(skill.id),skill.get("level",0)))
		result.append({"id":str(skill.id),"name":str(skill.name),"rank":rank,"max_rank":int(skill.get("max_level",3)),"cooldown_ticks":maxi(0,int(skill.get("cooldown_ticks",hero.get("cooldowns",{}).get(skill.id,0)))),"max_cooldown_ticks":int(skill.get("max_cooldown_ticks",0)),"mana_cost":int(skill.get("mana_cost",0)),"passive":bool(skill.get("passive",false)),"can_cast":bool(skill.get("can_cast",false)),"can_upgrade":bool(skill.get("can_upgrade",false)),"description":str(skill.get("description",""))})
	return result

static func _effects(hero: Dictionary, body: Dictionary, context: Dictionary, alive: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not alive: return result
	var tick := int(context.tick)
	var id := str(body.get("id",hero.get("id","")))
	# Historical replay observations already own their rule description. A
	# stable live ID must not silently acquire today's reworked P on playback.
	var innate: Dictionary = hero.get("innate",{}).duplicate(true)
	if innate.is_empty(): innate=Innates.profile(str(hero.get("archetype","")),int(hero.get("level",1)))
	if not innate.is_empty(): _effect(result,str(innate.id),str(innate.name),id,"INNATE",-1,str(innate.description),context)
	var technology_context:=TechnologiesV4.context_for(hero)
	for technology:Dictionary in TechnologiesV4.list_for(str(technology_context.get("faction",""))):
		if int(technology_context.get("levels",{}).get(str(technology.id),0))>0:
			_effect(result,str(technology.id),str(technology.label),str(body.get("side","")),"TECHNOLOGY",-1,str(technology.description),context)
	for item_id: String in hero.get("equipment",[]):
		var item: Dictionary = Items.ITEMS.get(item_id,{})
		if not item.is_empty(): _effect(result,item_id,str(item.name),id,"EQUIPMENT",-1,str(item.description),context)
	for skill_id: String in hero.get("skill_levels",{}):
		var rank := int(hero.skill_levels[skill_id])
		if rank <= 0: continue
		var skill := Heroes.skill_at_level(skill_id,rank)
		if skill.get("effect","") == "PASSIVE_GUARD": _effect(result,skill_id,str(skill.name),id,"PASSIVE",-1,str(skill.description),context)
	var grouped := {}
	for aura: Dictionary in context.get("auras",{}).get(id,{}).values():
		var key := str(aura.source_id)+":"+str(aura.id)
		if not grouped.has(key): grouped[key] = aura.duplicate(true); grouped[key]["contributions"] = []
		grouped[key].contributions.append("%s +%s"%[AURA_LABELS.get(aura.field,aura.field),str(aura.amount)])
	for aura: Dictionary in grouped.values(): _effect(result,str(aura.id),str(aura.name),str(aura.source_id),str(aura.kind),-1,"%s\n获得：%s；范围%d。同类光环不叠加，取最高效果。"%[aura.description,"、".join(aura.contributions),aura.radius],context)
	# Innates records each increasing contender. Only its last winner per
	# attribute is effective; do not display superseded weak sources as stacked.
	var innate_winners := {}
	for source: Dictionary in body.get("innate_aura",{}).get("sources",[]): innate_winners[str(source.attribute)] = source
	for source: Dictionary in innate_winners.values():
		var origin: Dictionary = context.bodies.get(str(source.source_id),{})
		if int(origin.get("hp",0)) <= 0 or _distance(body,origin) > int(source.radius)*int(source.radius): continue
		if float(body.get("innate_aura",{}).get(str(source.attribute),0)) <= 0: continue
		var spec := _effect_identity(str(source.innate_id),str(source.source_id),context)
		var harmful: bool = source.attribute == "active_healing_penalty_percent"
		_effect(result,str(source.innate_id),str(spec.name),str(source.source_id),"DEBUFF_AURA" if harmful else "INNATE_AURA",-1,str(spec.description)+"\n离开光环范围或持有者阵亡时失效。",context)
	var source_id := str(body.get("support_aura_source_id",""))
	if float(body.get("support_mana_per_second",0)) > 0 and int(context.bodies.get(source_id,{}).get("hp",0)) > 0 and _distance(body,context.bodies[source_id]) <= 160*160:
		_effect(result,"ROOT_NETWORK","根网汲流",source_id,"SUPPORT_AURA",-1,"当前蓝量回复+%.2f/秒，补满或离场失效。"%float(body.support_mana_per_second),context)
	_finite_buffs(result,body,context)
	for key: String in hero.get("item_effects",{}):
		var entry: Dictionary = hero.item_effects[key]
		if int(entry.get("expires_tick",-1)) <= tick: continue
		# Exhausted shield-only effects must not pretend protection remains.
		var nonshield := entry.duplicate(true)
		nonshield.erase("shield_hp")
		var bonus := Items.active_bonus({"item_effects":{key:nonshield}},tick)
		var has_bonus := false
		for value: Variant in bonus.values():
			if float(value) != 0: has_bonus = true
		if not has_bonus and int(entry.get("shield_remaining",0)) <= 0: continue
		_effect(result,key,str(entry.get("name",key)),id,"CONSUMABLE",int(entry.expires_tick)-tick,str(entry.get("description",""))+ ("\n剩余护盾%d。"%int(entry.shield_remaining) if int(entry.get("shield_remaining",0)) > 0 else ""),context)
	for pair: Array in [["STUN","stun"],["ROOT","root"]]:
		var remaining := int(body.get(pair[1]+"_until_tick",-1))-tick
		if remaining > 0: _effect(result,pair[0],STATUS_NAMES[pair[0]],str(body.get(pair[1]+"_source_id","")),"DEBUFF",remaining,"眩晕禁止动作；定身仅禁止移动，可攻击施法。",context)
	for entry: Dictionary in body.get("combat_statuses",{}).values():
		if int(entry.get("expires_tick",-1)) <= tick: continue
		var kind := str(entry.get("kind",""))
		_effect(result,kind,str(STATUS_NAMES.get(kind,kind)),str(entry.get("source_id","")),"DEBUFF",int(entry.expires_tick)-tick,"%s；当前强度%s。"%[STATUS_NAMES.get(kind,kind),str(entry.get("power",0))],context)
	for entry: Dictionary in body.get("r7_statuses",{}).values():
		if int(entry.get("expires_tick",-1))<=tick: continue
		var skill_id := str(entry.get("skill_id",""))
		var spec := Heroes.skill_at_level(skill_id,int(entry.get("rank",1)))
		var mark := str(entry.get("r7_phase",""))=="MARK"
		var name := str(spec.get("name",skill_id))+("·预告" if mark else "·"+str(STATUS_NAMES.get(str(entry.get("kind","")),"持续伤害")))
		var description := "末章即将落下；净化可提前解除。" if mark else "持续受到伤害，离开落点范围仍会生效；可被净化。"
		_effect(result,skill_id,name,str(entry.get("source_id","")),"DEBUFF",int(entry.expires_tick)-tick,description,context)
	for entry: Dictionary in body.get("secondary_effects",{}).values():
		var kind := Items.secondary_status_kind(entry)
		if int(entry.get("expires_tick",-1)) <= tick or int(entry.get("pulses_left",0)) <= 0: continue
		# Innates settles one fractional mana-aura pulse on its beneficiary.
		# Effective aura provenance above already names the real hero source;
		# this internal queue entry is not a second self-cast unnamed talent.
		if kind=="MANA" and entry.get("origin","")=="INNATE" and str(entry.get("id","")).ends_with(":MANA_AURA"):continue
		var identity := _secondary_identity(entry,context)
		_effect(result,str(identity.id),str(identity.name),str(entry.get("source_id","")),"HOT" if kind == "HEAL" else "DEBUFF" if kind in ["BURN","POISON"] else "PERIODIC",int(entry.expires_tick)-tick,"%s：剩余%d次，每次基础值%.2f。"%[STATUS_NAMES.get(kind,kind),int(entry.get("pulses_left",0)),float(entry.get("amount_per_pulse",0))],context)
	for entry: Dictionary in body.get("innate_shield",{}).values():
		var capacity := float(entry.get("amount",0)) if entry.get("kind","") == "FLAT" else float(entry.get("cap",0)) if int(entry.get("percent",0)) > 0 else 0.0
		if int(entry.get("expires_tick",-1)) <= tick or capacity <= 0: continue
		var identity := _effect_identity("INNATE_"+str(context.heroes.get(str(entry.get("source_id","")),{}).get("archetype","")),str(entry.get("source_id","")),context)
		_effect(result,str(identity.id),str(identity.name),str(entry.get("source_id","")),"SHIELD",int(entry.expires_tick)-tick,"吸收受到的伤害；多个护盾同时存在时取最强效果。",context)
	var state: Dictionary = body.get("innate_state",{})
	for pair: Array in [["thorn_bind","INNATE_THORN_CHANTER"],["storm_mark","INNATE_STORM_HERALD"]]:
		var mark: Dictionary = state.get(pair[0],{})
		if int(mark.get("expires_tick",-1)) <= tick: continue
		if pair[0] == "thorn_bind" and (int(body.get("root_until_tick",-1)) != int(mark.expires_tick) or str(body.get("root_source_id",mark.source_id)) != str(mark.source_id)): continue
		var identity := _effect_identity(pair[1],str(mark.get("source_id","")),context)
		_effect(result,pair[1],str(identity.name),str(mark.get("source_id","")),"DEBUFF",int(mark.expires_tick)-tick,str(identity.description),context)
	for vulnerability_id: String in body.get("duration_vulnerabilities",{}):
		var entry: Dictionary = body.duration_vulnerabilities[vulnerability_id]
		if int(entry.get("expires_tick",-1)) <= tick: continue
		var identity := _effect_identity(vulnerability_id,"",context)
		_effect(result,vulnerability_id,str(identity.name),"","DEBUFF",int(entry.expires_tick)-tick,"期间新受到的持续伤害时长+%d%%。"%int(entry.get("dot_duration_percent",0)),context)
	if int(body.get("guard_until_tick",-1)) > tick:
		_effect(result,"GUARD","护甲强化",id,"BUFF",int(body.guard_until_tick)-tick,"当前护甲+%s、移动步长+%s。"%[float(body.get("guard_armor_bonus",0)),float(body.get("guard_speed_bonus",0))],context)
	return result

static func effects_for_actor(subject: Dictionary, body: Dictionary, context: Dictionary) -> Array[Dictionary]:
	# Regular soldiers expose the exact same finite buff/aura provenance. An
	# empty archetype intentionally grants no hero innate or fake equipment.
	return _effects(subject,body,context,int(body.get("hp",0))>0)

static func _finite_buffs(result: Array[Dictionary], body: Dictionary, context: Dictionary) -> void:
	var eligible: Array[Dictionary] = []
	var winners := {}
	for entry: Dictionary in body.get("source_buffs",{}).values():
		if int(entry.get("expires_tick",-1)) <= int(context.tick) or int(entry.get("charges",-1)) == 0: continue
		if bool(entry.get("requires_source",false)) and int(context.bodies.get(str(entry.get("source_id","")),{}).get("hp",0)) <= 0: continue
		eligible.append(entry)
		for field: String in Buffs.FIELDS:
			var key := str(entry.get("category",""))+":"+field
			if float(entry.get(field,0)) > float(winners.get(key,{}).get(field,0)): winners[key] = entry
	for entry: Dictionary in eligible:
		var contributes := false
		for winner: Dictionary in winners.values():
			if winner == entry: contributes = true; break
		if not contributes: continue
		var identity := _effect_identity(str(entry.id),str(entry.source_id),context)
		_effect(result,str(entry.id),str(identity.name),str(entry.source_id),"BUFF",int(entry.expires_tick)-int(context.tick),str(identity.description)+("\n剩余%d次。"%int(entry.charges) if int(entry.get("charges",-1)) > 0 else ""),context)

static func _effect(result: Array[Dictionary], id: String, name: String, source_id: String, kind: String, remaining: int, description: String, context: Dictionary) -> void:
	for existing: Dictionary in result:
		if existing.id == id and existing.source_id == source_id and existing.kind == kind: return
	var source := _source_name(source_id,context)
	result.append({"id":id,"icon":id,"name":name,"source":source,"source_id":source_id,"kind":kind,"remaining_ticks":remaining,"duration_ticks":remaining,"description":description+"\n来源："+source+("；剩余%.1f秒。"%(float(remaining)/20.0) if remaining >= 0 else "")})

static func _effect_identity(id: String, source_id: String, context: Dictionary) -> Dictionary:
	var source: Dictionary = context.get("heroes",{}).get(source_id,{})
	if id.begins_with("INNATE_"):
		var spec := Innates.profile(id.trim_prefix("INNATE_"),int(source.get("level",1)))
		if not spec.is_empty(): return spec
	if Heroes.SKILLS.has(id): return Heroes.skill_at_level(id,maxi(1,int(source.get("skill_levels",{}).get(id,1))))
	if Items.ITEMS.has(id): return Items.ITEMS[id]
	var support := Support.visual_skill(id)
	if not support.is_empty(): return support
	return {"id":id,"name":str(STATUS_NAMES.get(id,id)),"description":"有限状态，按当前实际剩余时间显示。"}

static func _secondary_identity(entry: Dictionary, context: Dictionary) -> Dictionary:
	var source_id := str(entry.get("source_id",""))
	var id := str(entry.get("skill_id",""))
	if id.is_empty() and entry.get("origin","") == "INNATE": id = "INNATE_"+str(context.heroes.get(source_id,{}).get("archetype",""))
	if id.is_empty(): id = str(entry.get("id",entry.get("kind","持续状态")))
	return _effect_identity(id,source_id,context)

static func _gear_aura_identity(hero: Dictionary, field: String, amount: float) -> Dictionary:
	var catalog_field := str({"damage":"aura_damage","armor":"aura_armor","heal_per_second":"aura_heal","mana_per_second":"aura_mana_regen"}.get(field,""))
	for item_id: String in hero.get("equipment",[]):
		var item: Dictionary = Items.ITEMS.get(item_id,{})
		if amount > 0 and is_equal_approx(float(item.get(catalog_field,0)),amount): return item
	return {"id":"EQUIPMENT_AURA","name":"装备光环","description":"来自当前已装备的光环装备。"}

static func _source_name(id: String, context: Dictionary) -> String:
	var hero: Dictionary = context.get("heroes",{}).get(id,{})
	if not hero.is_empty(): return str(hero.get("name",hero.get("archetype",id)))
	var body: Dictionary = context.get("bodies",{}).get(id,{})
	return str(body.get("name",body.get("label",body.get("unit_type",id)))) if not body.is_empty() else "来源未公开" if id.is_empty() else id

static func _distance(a: Dictionary,b: Dictionary) -> int:
	return int((a.get("position",Vector2i.ZERO) as Vector2i).distance_squared_to(b.get("position",Vector2i.ZERO)))
