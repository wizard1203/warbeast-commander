extends RefCounted
## One detached actor projection; never a combat, equipment or command owner.
const HeroStatus = preload("res://src/presentation/strategic_hero_status_readout.gd")
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const Support = preload("res://src/simulation/strategic_army_support.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const UnitCatalog = preload("res://src/simulation/strategic_unit_catalog.gd")
const Buffs = preload("res://src/simulation/strategic_combat_buffs.gd")
const BreakdownM75 = preload("res://src/presentation/strategic_attribute_breakdown_m75.gd")

static func read(snapshot: Dictionary, id: String, collection: String = "soldiers", prepared: Dictionary = {}) -> Dictionary:
	var body: Dictionary = {}
	for entry: Dictionary in snapshot.get(collection,[]):
		if str(entry.get("id","")) == id: body = entry; break
	if body.is_empty() or int(body.get("hp",0))<=0 or not bool(body.get("alive",true)): return {}
	var context := HeroStatus.prepare(snapshot) if prepared.is_empty() else prepared
	var hero: Dictionary = context.get("heroes",{}).get(id,{})
	var status: Dictionary = HeroStatus.read(hero,context) if not hero.is_empty() else _regular(body,context,collection)
	var label := str(hero.get("name",body.get("label",body.get("name",id))))
	var faction := str(body.get("faction_id","HUMAN"))
	var profile: Dictionary = UnitCatalog.profile(str(body.get("unit_type",""))) if collection != "buildings" else {}
	var type_label := str(profile.get("label",profile.get("name",body.get("trait_name",body.get("unit_type","兵员")))))
	if collection=="buildings": type_label=str(body.get("label",body.get("building_type","建筑")))
	var description := str(hero.get("description",body.get("trait_description",body.get("description",""))))
	if hero.is_empty() and not str(profile.get("combat_role_label","")).is_empty():
		description=str(profile.get("role_brief",profile.combat_role_label))+"\n弱点："+"；".join(profile.get("weaknesses",[]))+"\n"+description
	var subtitle := "%s · %s"%[Palette.side_label(str(body.get("side",""))), str(hero.get("title",type_label))]
	if not hero.is_empty(): subtitle += " · Lv.%d"%int(hero.get("level",1))
	return {"id":id,"collection":collection,"tick":int(snapshot.get("tick",0)),"hero":not hero.is_empty(),"label":label,"subtitle":subtitle,"description":description,"body":body.duplicate(true),"status":status,"hp":int(body.hp),"max_hp":int(body.get("max_hp",1)),"mana":int(hero.get("mana",body.get("mana",0))),"max_mana":int(hero.get("max_mana",body.get("max_mana",0))),"faction_id":faction,"population":int(body.get("population",0)),"skills":status.get("skills",[]),"effects":status.get("effects",[]),"stats":status.get("stats",[]),"read_only":true}

static func _regular(body: Dictionary, context: Dictionary, collection: String) -> Dictionary:
	var interval := int(body.get("attack_cooldown_ticks",0))
	var armor := float(body.get("armor",0))
	var regen := float(body.get("hp_regen_per_second",0))
	var buffs := Buffs.values(body.duplicate(true),int(context.get("tick",0)),context.get("bodies",{}))
	var mana_regen := float(body.get("mana_regen_per_second",0))+float(body.get("support_mana_per_second",0))+float(body.get("innate_aura",{}).get("mana_regen_per_second",0))+float(buffs.mana_per_second)
	for aura: Dictionary in context.get("auras",{}).get(str(body.get("id","")),{}).values():
		if aura.field=="mana_per_second":mana_regen+=float(aura.amount)
		elif aura.field=="heal_per_second":regen+=float(aura.amount)
	var stats: Array[Dictionary] = []
	_add(stats,"damage","attack","攻击",str(body.get("damage",0)),Damage.attack_summary(str(body.get("attack_type","EDGE"))))
	_add(stats,"armor","armor","护甲","%s (%.0f%%)"%[armor,100*Damage.armor_factor(armor)],Damage.numeric_armor_summary(armor)+"\n"+Damage.armor_summary(str(body.get("armor_type","UNARMORED"))))
	_add(stats,"attack_speed","attack_speed","攻速","%.2f/s"%(20.0/interval) if interval>0 else "—","普通攻击间隔：%.2f秒。"%(interval/20.0)+("建成且处于防守状态时自动攻击。" if collection=="buildings" else ""))
	_add(stats,"move_speed","move","移速","%.0f"%(float(body.get("speed_exact",body.get("speed",0)))*20),"当前战场距离／秒；建筑不能移动。")
	_add(stats,"range","range","射程",str(body.get("attack_range",0)),"普通攻击可以命中的最远距离。技能与光环的范围分别计算。")
	_add(stats,"magic_resist","magic_resist","魔抗","%d%%"%int(body.get("magic_resist_percent",0)),"奥术伤害依类型、数值护甲后再结算适用魔抗。")
	_add(stats,"hp_regen","health","回血","%.2f/s"%regen,"每秒持续恢复的生命，包含光环加成；限次治疗在状态栏中查看。")
	_add(stats,"mana_regen","mana","回蓝","%.2f/s"%mana_regen if int(body.get("max_mana",0))>0 else "—","每秒持续恢复的法力，包含光环与增益。没有法力的单位显示为—。")
	_add(stats,"population","population","人口",str(body.get("population",0)),"这名单位占用的人口容量。")
	var effective := {"damage":float(body.get("damage",0)),"armor":armor,"attack_speed":20.0/interval if interval>0 else 0.0,"move_speed":float(body.get("speed_exact",body.get("speed",0)))*20.0,"range":float(body.get("attack_range",0)),"magic_resist":float(body.get("magic_resist_percent",0)),"hp_regen":regen,"mana_regen":mana_regen}
	for index: int in range(stats.size()):
		var stat_id:=str(stats[index].id)
		if not effective.has(stat_id):continue
		if stat_id=="mana_regen" and int(body.get("max_mana",0))<=0:continue
		var suffix := "/s" if stat_id in ["attack_speed","hp_regen","mana_regen"] else "%" if stat_id=="magic_resist" else ""
		stats[index]=BreakdownM75.apply(stats[index],body,float(effective[stat_id]),suffix)
		if stat_id=="armor":stats[index].value+=" (%.0f%%)"%(Damage.armor_factor(armor)*100)
	var skills: Array[Dictionary] = []
	var tick := int(context.get("tick",0))
	if bool(body.get("neutral",false)) and not body.get("neutral_skill",{}).is_empty():
		var ability: Dictionary=body.neutral_skill.duplicate(true)
		ability.merge({"name":str(ability.get("label","野怪技能")),"rank":1,"max_rank":1,"passive":false,"cooldown_ticks":maxi(0,int(body.get("neutral_skill_ready_tick",tick))-tick),"max_cooldown_ticks":int(ability.get("cooldown_ticks",0))},true)
		skills.append(ability)
	if int(body.get("heal",0))>0:
		skills.append({"id":"FIELD_HEAL","name":"战地治疗","rank":1,"max_rank":1,"passive":false,"cooldown_ticks":int(body.get("heal_cooldown_ticks",0)),"max_cooldown_ticks":int(body.get("heal_max_cooldown_ticks",60)),"mana_cost":int(body.get("heal_mana_cost",15)),"description":"自动治疗附近受伤的%s，每个目标恢复%d点生命，最多%d个目标。"%["机械友军" if "MACHINE" in body.get("heal_target_tags",[]) else "友军",int(body.get("heal",0)),int(body.get("heal_max_targets",1))]})
	var spec: Dictionary = Support.CATALOG.get(str(body.get("unit_type","")),{})
	if not spec.is_empty():
		var skill := spec.duplicate(true)
		skill.merge({"rank":1,"max_rank":1,"passive":int(spec.get("mana_cost",0))==0,"cooldown_ticks":maxi(0,int(body.get("support_ready_tick",tick))-tick),"max_cooldown_ticks":int(spec.get("cooldown_ticks",0))},true)
		skills.append(skill)
	if not bool(body.get("neutral",false)):
		var passive:Dictionary=body.get("troop_passive",{})
		if not passive.is_empty():
			var skill:Dictionary=passive.duplicate(true)
			skill.merge({"name":str(passive.get("label",passive.id)),"rank":1,"max_rank":1,"passive":true,"mana_cost":0,"cooldown_ticks":maxi(0,int(body.get("troop_passive_ready_tick_r3",0))-tick),"max_cooldown_ticks":int(passive.get("cooldown_ticks",0))},true)
			skills.append(skill)
		var active:Dictionary=body.get("troop_ability",{})
		if not active.is_empty():
			var skill:Dictionary=active.duplicate(true)
			skill.merge({"name":str(active.get("label",active.get("id","技能"))),"rank":1,"max_rank":1,"passive":false,"cooldown_ticks":maxi(0,int(body.get("troop_skill_ready_tick_v4",tick))-tick),"max_cooldown_ticks":int(active.get("cooldown_ticks",0))},true)
			skills.append(skill)
		var proc:Dictionary=body.get("basic_proc_v4",{})
		if not proc.is_empty():
			var skill:Dictionary=proc.duplicate(true)
			skill.merge({"name":str(proc.get("label",proc.get("id","普攻特性"))),"rank":1,"max_rank":1,"passive":true,"mana_cost":0,"cooldown_ticks":maxi(0,int(body.get("basic_proc_ready_tick_v4",tick))-tick),"max_cooldown_ticks":int(proc.get("internal_cooldown_ticks",0))},true)
			skills.append(skill)
	var subject := {"unit_id":str(body.get("id","")),"archetype":"","skill_levels":{},"equipment":[]}
	var effects: Array[Dictionary] = HeroStatus.effects_for_actor(subject,body,context)
	return {"stats":stats,"skills":skills,"effects":effects,"tick":tick,"xp_ratio":0.0}

static func _add(rows: Array[Dictionary], id: String, symbol: String, label: String, value: String, description: String) -> void:
	rows.append({"id":id,"symbol":symbol,"label":label,"value":value,"description":description})
