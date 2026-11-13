extends RefCounted
const ReworkR7 = preload("res://src/simulation/strategic_hero_rework_r7_catalog.gd")
const ItemRules = preload("res://src/simulation/strategic_hero_items.gd")
const BalanceM58 = preload("res://src/simulation/strategic_hero_balance_m58.gd")
const IdentityM67 = preload("res://src/simulation/strategic_hero_identity_m67.gd")
const DamageRules = preload("res://src/simulation/strategic_damage_rules.gd")
const ExpansionM66=preload("res://src/simulation/strategic_hero_expansion_m66.gd")
const MagesM68=preload("res://src/simulation/strategic_hero_mages_m68.gd")
const PowerM69=preload("res://src/simulation/strategic_hero_power_m69.gd")
## Event-only innate authority. No scheduler, inventory, prices or free actions.
## Combat calls real-event hooks once, then settles take_due_effects through its
## normal damage/healing ledger. Secondary effects must NOT call innate hooks.
const VERSION := "m58-thirty-growing-hero-innates-v1"
const PROFILES := {
	"COMMANDER":{"name":"同袍誓约","description":"180范围最多6名友军受到主动治疗提高5%。","radius":180,"cap":6,"aura":"HEALING"},
	"DUELIST":{"name":"止戈步调","description":"180范围最多6名友军受到的眩晕、定身与减速时长减少8%。","radius":180,"cap":6,"aura":"CONTROL"},
	"RANGER":{"name":"协猎","description":"目标100范围内其他友军在过去2秒普攻过，自己的普攻基础伤害提高8%。"},
	"ARCANIST":{"name":"列阵共鸣","description":"自身100范围内有至少2名其他友军，主动技能伤害提高6%。"},
	"BULWARK":{"name":"垒盾阵心","description":"90范围最多6名友军受到的普攻伤害降低5%。","radius":90,"cap":6,"aura":"BASIC_GUARD"},
	"ASH_CHANTER":{"name":"余烬灯芯","description":"180内敌军死亡积累余烬，最多3层；下一次有效付费治疗每层额外4生命，冷却6秒。"},
	"GRAVE_BELL":{"name":"暮钟哀音","description":"180范围最多6名敌军受到的主动治疗降低8%。","radius":180,"cap":6,"aura":"WOUND","enemy_aura":true},
	"CINDER_STALKER":{"name":"残烬追猎","description":"对生命低于50%的敌军，普攻基础伤害提高8%。"},
	"MOURN_ORACLE":{"name":"迟燃烬语","description":"付费技能直接命中后附加基础伤害6%的2秒奥术余烬，每目标最多12；每次最多3目标，冷却6秒。"},
	"ASH_MARSHAL":{"name":"归骨续命","description":"180内敌军死亡恢复自身最大生命2%，最多18，冷却8秒。"},
	"COIL_MEDIC":{"name":"应急绝缘","description":"付费治疗后最多3名目标的下一次普攻受伤降低10%，每人最多抵挡10，持续3秒，冷却6秒。"},
	"SIGNAL_KEEPER":{"name":"稳频信标","description":"180范围最多3名有蓝量友军每秒额外恢复0.15蓝量。","radius":180,"cap":3,"aura":"MANA"},
	"GEAR_HUNTER":{"name":"校准齿列","description":"对同一敌人的每第三次普攻基础伤害提高20%；换目标或4秒未攻击重置。"},
	"VOLT_WEAVER":{"name":"三相回路","description":"每第三次付费施法的直接伤害提高18%，最多3目标。"},
	"COIL_WARDEN":{"name":"驻地铆定","description":"静止2秒后，受到的普攻伤害降低6%；移动即失效。"},
	"BLOOM_GUIDE":{"name":"新芽余韵","description":"付费治疗后附加有效治疗量8%的4秒持续回复，每目标最多12，同类取强。"},
	"THORN_CHANTER":{"name":"棘缠锋芒","description":"被自己定身的敌军，定身期间普攻伤害降低6%。"},
	"WIND_COURIER":{"name":"踏风蓄弦","description":"移动80距离蓄能下一次普攻，基础伤害提高15%；最多1次，触发冷却2秒。"},
	"LEAF_SEER":{"name":"林律捕隙","description":"对施法前已受减速或定身的敌军，主动技能伤害提高6%。"},
	"VINE_WARDEN":{"name":"扎根生息","description":"静止2秒后每秒回复1.5生命，移动即停止。"},
	"HEARTH_KEEPER":{"name":"炉心余温","description":"有效付费治疗后提供治疗量6%的护盾，最多18；每次最多3目标，持续4秒。"},
	"STORM_HERALD":{"name":"雷旌协击","description":"自己眩晕的最多3目标被标记3秒；下一友军普攻额外25%基础伤害，最多12，每6秒一轮。"},
	"EMBER_CAVALIER":{"name":"第三烬刃","description":"每第三次普攻附加基础伤害20%的2秒奥术灼烧。"},
	"RUNE_ORACLE":{"name":"炉符添薪","description":"对已灼烧的敌军，主动技能伤害提高8%。"},
	"RIDGE_JARL":{"name":"半血山誓","description":"自身生命不高于50%时，受到的穿刺普攻伤害降低10%。"},
	"SPORE_GUIDE":{"name":"菌丝分润","description":"有效付费治疗量的8%分给90内另一名伤员，最多12；不递归触发。"},
	"QUAKE_PRIEST":{"name":"地鸣余震","description":"自己的定身或地层解理破甲自然结束后使目标短暂减速；每目标冷却6秒，提前移除不触发。"},
	"SPORE_STALKER":{"name":"穴群夹击","description":"目标60内存在另一名友军时，自己的普攻基础伤害提高8%。"},
	"ECHO_BINDER":{"name":"孢音渗透","description":"对已中毒敌军，主动技能伤害提高8%。"},
	"TUNNEL_SENTINEL":{"name":"穴甲合阵","description":"自身90内至少2名其他友军时，受到的近战普攻伤害降低8%。"},
}

const ORIGINAL_VALUES := {
	"COMMANDER":{"percent":5},"DUELIST":{"percent":8},"RANGER":{"percent":8},"ARCANIST":{"percent":6},"BULWARK":{"percent":5},
	"ASH_CHANTER":{"amount":4},"GRAVE_BELL":{"percent":8},"CINDER_STALKER":{"percent":8},"MOURN_ORACLE":{"percent":6,"amount_cap":12},"ASH_MARSHAL":{"max_hp_percent":2,"amount_cap":18},
	"COIL_MEDIC":{"percent":10,"amount_cap":10},"SIGNAL_KEEPER":{},"GEAR_HUNTER":{"percent":20},"VOLT_WEAVER":{"percent":18},"COIL_WARDEN":{"percent":6},
	"BLOOM_GUIDE":{"percent":8,"amount_cap":12},"THORN_CHANTER":{"percent":6},"WIND_COURIER":{"percent":15},"LEAF_SEER":{"percent":6},"VINE_WARDEN":{},
	"HEARTH_KEEPER":{"percent":6,"amount_cap":18},"STORM_HERALD":{"percent":25,"amount_cap":12},"EMBER_CAVALIER":{"percent":20},"RUNE_ORACLE":{"percent":8},"RIDGE_JARL":{"percent":10},
	"SPORE_GUIDE":{"percent":8,"amount_cap":12},"QUAKE_PRIEST":{},"SPORE_STALKER":{"percent":8},"ECHO_BINDER":{"percent":8},"TUNNEL_SENTINEL":{"percent":8}}
static var _value_cache: Dictionary = {} # At most 30 identities * eight levels.

static func growth(archetype: String) -> Dictionary:
	return PowerM69.innate_growth(_authored_growth(archetype))

static func _authored_growth(archetype: String) -> Dictionary:
	if MagesM68.has_hero(archetype):return MagesM68.innate_growth(archetype)
	if ExpansionM66.has_hero(archetype):return ExpansionM66.innate_growth(archetype)
	var result := {}
	for field: String in ORIGINAL_VALUES.get(archetype,{}):
		var old := float(ORIGINAL_VALUES[archetype][field])
		if field=="percent": result[field]={"base":roundi(old*1.6),"per_level":maxi(1,roundi(old*0.08))}
		elif field=="max_hp_percent": result[field]={"base":old*1.6,"per_level":old*0.08}
		elif field=="amount_cap": result[field]={"base":old*3.0,"per_level":old*0.35}
		else: result[field]={"base":old*2.0,"per_level":old*0.2}
	if archetype=="SIGNAL_KEEPER": result["mana_per_second"]={"base":0.45,"per_level":0.05}
	if archetype=="VINE_WARDEN": result["hp_per_second"]={"base":4.0,"per_level":0.5}
	if archetype=="QUAKE_PRIEST": result.merge({"percent":{"base":18,"per_level":1},"duration_ticks":{"base":40,"per_level":2}})
	return result

static func values(archetype: String, level: int = 1) -> Dictionary:
	return _resolved_values(archetype,level).duplicate(true)

static func _resolved_values(archetype: String, level: int) -> Dictionary:
	var key := archetype+":"+str(clampi(level,1,8))
	if not _value_cache.has(key):
		var result := {}
		# Resolve old integer-percent quantization before the final half projection;
		# otherwise floor(half(x)) silently removes another half percentage point.
		for field: String in _authored_growth(archetype):
			var rule: Dictionary=_authored_growth(archetype)[field]
			result[field]=float(rule.base)+float(rule.per_level)*float(clampi(level,1,8)-1)
		if ExpansionM66.has_hero(archetype) and result.has("percent"):result.percent=ExpansionM66.settled_innate_percent(archetype,float(result.percent))
		for field:String in PowerM69.INNATE_AMPLITUDES:
			if result.has(field):result[field]=float(result[field])*PowerM69.FACTOR
		_value_cache[key]=result
	return _value_cache[key]

static func _values(body: Dictionary, combat: RefCounted) -> Dictionary:
	var hero: Dictionary=_heroes(combat).get(str(body.get("id","")),{})
	return _resolved_values(_kind(body,combat),int(hero.get("level",1)))

static func profile(archetype: String, level: int = 1) -> Dictionary:
	if ReworkR7.has_hero(archetype): return ReworkR7.innate_profile(archetype,level)
	if MagesM68.has_hero(archetype) or ExpansionM66.has_hero(archetype):
		var result:Dictionary=MagesM68.innate_profile(archetype,level) if MagesM68.has_hero(archetype) else ExpansionM66.innate_profile(archetype,level)
		var potency:=values(archetype,level)
		var authored:Dictionary=MagesM68.INNATES[archetype] if MagesM68.has_hero(archetype) else ExpansionM66.INNATES[archetype]
		result["values"]=potency;result["growth"]=growth(archetype);result["power_version"]=PowerM69.VERSION
		result.description=str(authored.description).replace("{P}","%.2f"%float(potency.get("amount",potency.get("percent",0))))+"\n随英雄升级增强，无需学习或消耗蓝量。"
		return result
	var result: Dictionary = PROFILES.get(archetype, {}).duplicate(true)
	if not result.is_empty():
		var potency := values(archetype,level)
		result.merge({"id":"INNATE_" + archetype,"archetype":archetype,"passive":true,"mana_cost":0,"learnable":false,"level":clampi(level,1,8),"max_level":8,"automatic_level":true,"growth":growth(archetype),"values":potency,"version":VERSION},true)
		result.description=_describe(archetype,potency)+"\n随英雄升级增强，无需学习或消耗法力。"
		result["power_version"]=PowerM69.VERSION
	return result

static func _describe(kind: String, p: Dictionary) -> String:
	var percent := float(p.get("percent",0))
	match kind:
		"COMMANDER": return "180范围最多6名友军受到主动治疗提高%.1f%%。"%percent
		"DUELIST": return "180范围最多6名友军受到的眩晕、定身与减速时长减少%.1f%%。"%percent
		"RANGER": return "目标100范围内其他友军在过去2秒普攻过，自己的普攻额外造成基础攻击%.1f%%伤害。"%percent
		"ARCANIST": return "自身100范围内有至少2名其他友军时，主动技能的直接伤害提高%.1f%%，不增加持续伤害。"%percent
		"BULWARK": return "90范围最多6名友军受到的普攻伤害降低%.1f%%。"%percent
		"ASH_CHANTER": return "180范围内有敌军死亡时积累余烬，最多3层。下一次消耗蓝量的治疗技能每层额外恢复%.1f生命，冷却6秒。"%float(p.amount)
		"GRAVE_BELL": return "180范围最多6名敌军受到的主动治疗降低%.1f%%。"%percent
		"CINDER_STALKER": return "对生命低于50%%的敌军，普攻额外造成基础攻击%.1f%%伤害。"%percent
		"MOURN_ORACLE": return "消耗蓝量的技能造成直接伤害后，附加持续4秒的奥术余烬，共造成基础伤害的%.1f%%，每个目标最多%.1f点。每次最多影响3名敌人，冷却6秒。"%[percent,float(p.amount_cap)]
		"ASH_MARSHAL": return "180内敌军死亡恢复自身最大生命%.2f%%，每次最多%.1f，冷却8秒。"%[float(p.max_hp_percent),float(p.amount_cap)]
		"COIL_MEDIC": return "用消耗蓝量的技能治疗后，使最多3名受益者下一次受到的普攻伤害降低%.1f%%，最多抵挡%.1f点。防护持续3秒，冷却6秒。"%[percent,float(p.amount_cap)]
		"SIGNAL_KEEPER": return "180范围内最多3名有蓝量的友军每秒额外恢复%.2f蓝量。"%float(p.mana_per_second)
		"GEAR_HUNTER": return "对同一敌人的每第三次普攻额外造成基础攻击%.1f%%伤害；换目标或4秒未攻击重置。"%percent
		"VOLT_WEAVER": return "每第三次消耗蓝量施法时，对最多3名敌人造成的直接伤害提高%.1f%%。"%percent
		"COIL_WARDEN": return "静止2秒后，自己受到的普攻伤害降低%.1f%%；移动即失效。"%percent
		"BLOOM_GUIDE": return "用消耗蓝量的技能治疗后，受益者在4秒内额外恢复有效治疗量的%.1f%%，每个目标最多%.1f生命。同类效果只取最高值。"%[percent,float(p.amount_cap)]
		"THORN_CHANTER": return "被自己定身的敌人，在定身期间普攻伤害降低%.1f%%。无需造成伤害即可生效。"%percent
		"WIND_COURIER": return "移动80距离蓄能下一次普攻，额外造成基础攻击%.1f%%伤害；最多1次，冷却2秒。"%percent
		"LEAF_SEER": return "对施法前已受减速或定身的敌人，主动技能的直接伤害提高%.1f%%。"%percent
		"VINE_WARDEN": return "静止2秒后每秒回复%.1f生命，移动即停止。"%float(p.hp_per_second)
		"HEARTH_KEEPER": return "用消耗蓝量的技能有效治疗后，提供相当于治疗量%.1f%%的护盾，最多%.1f点。每次最多保护3名受益者，持续4秒。"%[percent,float(p.amount_cap)]
		"STORM_HERALD": return "自己眩晕的最多3目标被标记3秒；下一友军普攻额外%.1f%%基础伤害、最多%.1f，每6秒一轮。"%[percent,float(p.amount_cap)]
		"EMBER_CAVALIER": return "每第三次普攻附加持续4秒的奥术灼烧，共造成基础攻击的%.1f%%伤害。灼烧不会再次触发天赋。"%percent
		"RUNE_ORACLE": return "对已灼烧的敌人，主动技能的直接伤害提高%.1f%%。"%percent
		"RIDGE_JARL": return "自身生命不高于50%%时，受到的穿刺普攻伤害降低%.1f%%。"%percent
		"SPORE_GUIDE": return "用消耗蓝量的技能治疗后，将有效治疗量的%.1f%%分给90范围内另一名伤员，最多%.1f生命。这次额外治疗不会再次分润。"%[percent,float(p.amount_cap)]
		"QUAKE_PRIEST": return "自己的定身或地层解理破甲自然结束后使目标减速%.1f%%持续%.1f秒；每目标冷却6秒，提前移除、净化或被其他来源覆盖不触发。"%[percent,float(p.duration_ticks)/20.0]
		"SPORE_STALKER": return "目标60内存在另一友军时，自己的普攻额外造成基础攻击%.1f%%伤害。"%percent
		"ECHO_BINDER": return "对已中毒的敌人，主动技能的直接伤害提高%.1f%%。"%percent
		"TUNNEL_SENTINEL": return "自身90内至少2名其他友军时，自己受到的近战普攻伤害降低%.1f%%。"%percent
	return ""

static func _tick(combat: RefCounted) -> int: return int(combat.get("_tick"))
static func _soldiers(combat: RefCounted) -> Dictionary: return combat.get("_soldiers")
static func _heroes(combat: RefCounted) -> Dictionary: return combat.get("_hero_data")
static func _kind(body: Dictionary, combat: RefCounted) -> String:
	var hero: Dictionary = _heroes(combat).get(str(body.get("id", "")), {})
	var archetype := str(hero.get("archetype", body.get("hero_archetype", ""))) if _military(body) else ""
	# Their new P is owned by the finite R7 event consumer, not old M68 hooks.
	return "" if ReworkR7.has_hero(archetype) else archetype
static func _military(body: Dictionary, require_alive: bool = true) -> bool:
	if body.is_empty() or (require_alive and int(body.get("hp", 0)) <= 0): return false
	return str(body.get("unit_type", "")) != "worker" and not body.has("building_type") and "WORKER" not in body.get("tags", []) and not str(body.get("id", "")).is_empty()
static func _state(body: Dictionary) -> Dictionary:
	if not body.has("innate_state"): body["innate_state"] = {}
	return body.innate_state
static func _all(combat: RefCounted) -> Array[Dictionary]:
	# Standalone hook fixtures need not implement Combat's private preparation API.
	var context: RefCounted = combat._m93_context_current() if combat.has_method("_m93_context_current") else null
	if context != null: return context.military_all()
	var result: Array[Dictionary] = []
	var bodies := _soldiers(combat)
	var keys := bodies.keys()
	keys.sort()
	for id: String in keys:
		if _military(bodies[id]): result.append(bodies[id])
	return result
static func _near(center: Dictionary, combat: RefCounted, radius: int, same_side: bool, include_self: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var context: RefCounted = combat._m93_context_current() if combat.has_method("_m93_context_current") else null
	var pool: Array[Dictionary] = context.radius_pool(center.position, radius, true) if context != null else _all(combat)
	for other: Dictionary in pool:
		if not include_self and other.id == center.id: continue
		if (other.get("side", "") == center.get("side", "")) != same_side: continue
		if (other.position as Vector2i).distance_squared_to(center.position) <= radius * radius: result.append(other)
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var da := (a.position as Vector2i).distance_squared_to(center.position)
		var db := (b.position as Vector2i).distance_squared_to(center.position)
		return da < db or (da == db and str(a.id) < str(b.id)))
	return result
static func _mana(body: Dictionary, combat: RefCounted) -> int:
	return int(_heroes(combat).get(str(body.id), body).get("max_mana", 0))
static func _active_status(body: Dictionary, kind: String, tick: int) -> bool:
	return ItemRules.has_cleansable_status(body, [kind], tick)
static func _paid(source: Dictionary, combat: RefCounted) -> bool:
	return int(_state(source).get("paid_tick", -1000000)) == _tick(combat)
static func _target_once(source: Dictionary, target: Dictionary, group: String, cap: int) -> bool:
	var state := _state(source)
	var ids: Array = state.get(group, [])
	if str(target.id) in ids: return false
	if ids.size() >= cap: return false
	ids.append(str(target.id))
	state[group] = ids
	return true
static func _queue(target: Dictionary, source: Dictionary, id: String, kind: String, amount: float, pulses: int, tick: int, interval: int = 20, strongest: bool = false) -> void:
	if amount <= 0.0 or not _military(target): return
	if not target.has("secondary_effects"): target["secondary_effects"] = {}
	var key := "INNATE:" + str(source.id) + ":" + id
	var old: Dictionary = target.secondary_effects.get(key, {})
	if strongest and int(old.get("expires_tick", -1)) > tick and float(old.get("total_amount", 0.0)) >= amount: return
	target.secondary_effects[key] = {"id":key,"kind":kind,"attack_type":"ARCANE","source_id":str(source.id),"source_side":str(source.get("side", "")),"source_faction":str(source.get("faction_id", "")),"target_id":str(target.id),"total_amount":amount,"amount_per_pulse":amount / float(pulses),"pulses_left":pulses,"next_tick":tick + interval,"interval_ticks":interval,"expires_tick":tick + pulses * interval + 1,"origin":"INNATE","carry":0.0}
static func _shield(target: Dictionary, source: Dictionary, kind: String, amount: float, percent: float, cap: float, expiry: int, now: int) -> void:
	if not target.has("innate_shield"): target["innate_shield"] = {}
	var key := str(source.id) + ":" + kind
	var old: Dictionary = target.innate_shield.get(key, {})
	if int(old.get("expires_tick", -1)) > now:
		amount = maxf(amount,float(old.get("amount",0.0)))
		expiry = maxi(expiry,int(old.get("expires_tick",-1)))
	target.innate_shield[key] = {"kind":kind,"amount":amount,"percent":percent,"cap":cap,"expires_tick":expiry,"source_id":str(source.id)}

static func prepare(combat: RefCounted) -> void:
	var tick := _tick(combat)
	var all := _all(combat)
	# This is a single synchronous preparation, never a cross-tick identity
	# cache. Ordinary recipients keep their full old state below, but need not
	# be revisited as aura sources when they have no innate identity at all.
	var sources: Array[Dictionary] = []
	var source_kinds: Array[String] = []
	for body: Dictionary in _soldiers(combat).values():
		body["innate_aura"] = {"healing_received_percent":0,"active_healing_penalty_percent":0,"control_resist_percent":0,"basic_damage_reduction_percent":0,"attack_speed_percent":0,"mana_regen_per_second":0.0,"sources":[]}
	for body: Dictionary in all:
		var state := _state(body)
		if int(state.get("last_prepare_tick", -1000000)) != tick:
			var prior: Vector2i = state.get("last_position", body.position)
			var distance := prior.distance_to(body.position)
			if distance > 0.0:
				state["still_since"] = tick
				state["rooted_heal_until"] = -1
			elif not state.has("still_since"): state["still_since"] = tick
			state["travel"] = float(state.get("travel", 0.0)) + distance
			state["last_position"] = body.position
			state["last_prepare_tick"] = tick
		var kind := _kind(body,combat)
		if not kind.is_empty():
			sources.append(body)
			source_kinds.append(kind)
		if kind=="ANTLER_WARRIOR" and float(state.get("travel",0.0))>=100.0:
			state["m66_travel_ready"]=true
			state["travel"]=0.0
		if kind=="CARAPACE_WARRIOR":
			var own:Dictionary=body.innate_aura
			var amount:=float(_values(body,combat).percent)
			own.control_resist_percent=maxf(float(own.control_resist_percent),amount)
			own.sources.append({"source_id":body.id,"innate_id":"INNATE_"+kind,"attribute":"control_resist_percent","radius":0})
		if kind == "WIND_COURIER" and float(state.get("travel",0.0)) >= 80.0:
			state["wind_ready"] = true
			state["travel"] = 0.0 # Never bank an arbitrary number of attacks.
		if kind == "VINE_WARDEN" and tick > 0 and tick % 20 == 0 and tick - int(state.still_since) >= 40 and int(state.get("last_root_regen", -1)) != tick:
			_queue(body,body,"ROOT_REGEN","HEAL",float(_values(body,combat).hp_per_second),1,tick,1)
			state["last_root_regen"] = tick
		# An existing empty key must still be erased by the old lifecycle.
		# Only absence proves there is neither pending work nor cleanup.
		if state.has("quake_triggers"):_prepare_quake_triggers(body,state,tick,combat)
	for source_index: int in range(sources.size()):
		var source: Dictionary = sources[source_index]
		var kind: String = source_kinds[source_index]
		_prepare_tank_aura(source,kind,combat)
		var spec: Dictionary = PROFILES.get(kind,{})
		if not spec.has("aura"): continue
		var candidates := _near(source,combat,int(spec.radius),not bool(spec.get("enemy_aura",false)),true)
		if candidates.is_empty():continue
		var source_values := _values(source,combat)
		var amount: float = float(source_values.get("mana_per_second",0)) if spec.aura=="MANA" else float(source_values.get("percent",0))
		var count := 0
		for target: Dictionary in candidates:
			if spec.aura == "MANA" and _mana(target,combat) <= 0: continue
			if count >= int(spec.cap): break
			count += 1
			var aura: Dictionary = target.innate_aura
			var key: String = {"HEALING":"healing_received_percent","CONTROL":"control_resist_percent","BASIC_GUARD":"basic_damage_reduction_percent","WOUND":"active_healing_penalty_percent","MANA":"mana_regen_per_second"}[spec.aura]
			if float(aura[key]) < amount:
				aura[key] = amount
				aura.sources.append({"source_id":source.id,"innate_id":"INNATE_"+kind,"attribute":key,"radius":int(spec.radius)})
	# One periodic grant per beneficiary, so multiple same aura holders cannot
	# duplicate regen. Carry is settled by take_due_effects, never rounded away.
	if tick > 0 and tick % 20 == 0:
		for target: Dictionary in all:
			var state := _state(target)
			var aura: Dictionary = target.innate_aura
			if float(aura.mana_regen_per_second) > 0 and int(state.get("last_mana_aura_tick", -1)) != tick:
				_queue(target,target,"MANA_AURA","MANA",float(aura.mana_regen_per_second),1,tick,1)
				state["last_mana_aura_tick"] = tick

static func _prepare_quake_triggers(body:Dictionary,state:Dictionary,tick:int,combat:RefCounted)->void:
	# Independent accepted ROOT and ARMOR_BREAK lifecycles, one shared target
	# cooldown. A later spell cannot erase the earlier status's natural ending.
	var triggers:Dictionary=state.get("quake_triggers",{})
	var keys:Array=triggers.keys();keys.sort()
	for key:String in keys:
		var pending:Dictionary=triggers[key];var expected:=int(pending.until_tick)
		var intact:=int(body.get("root_until_tick",-1))==expected and str(body.get("root_source_id",""))==str(pending.source_id)
		if pending.trigger_kind=="ARMOR_BREAK":
			var status:Dictionary=body.get("combat_statuses",{}).get("ARMOR_BREAK",{})
			intact=int(status.get("expires_tick",-1))==expected and str(status.get("source_id",""))==str(pending.source_id)
		if not intact:triggers.erase(key);continue
		if tick<expected:continue
		triggers.erase(key)
		if tick-int(state.get("quake_last_proc",-1000000))<120:continue
		if not body.has("combat_statuses"):body["combat_statuses"]={}
		var duration:=DamageRules.control_ticks(int(pending.slow_duration_ticks),body)
		var power:=float(pending.slow_percent);var blocked:=false
		for other:Dictionary in body.combat_statuses.values():
			if other.get("kind","")=="SLOW" and int(other.get("expires_tick",-1))>tick and float(other.get("power",0))>power:blocked=true
		if not blocked:
			body.combat_statuses["INNATE_QUAKE_SLOW"]={"kind":"SLOW","power":power,"expires_tick":tick+duration,"next_tick":tick+20,"source_id":pending.source_id,"source_faction":pending.source_faction,"attack_type":"ARCANE"}
			if combat.has_method("_feedback"):combat.call("_feedback","STATUS",_soldiers(combat).get(str(pending.source_id),{"id":pending.source_id,"faction_id":pending.source_faction}),body,{"status_kind":"SLOW","expires_tick":tick+duration,"skill_id":"INNATE_QUAKE_PRIEST"})
		state["quake_last_proc"]=tick
	if triggers.is_empty():state.erase("quake_triggers")

static func _queue_quake_trigger(source:Dictionary,target:Dictionary,deadline:int,kind:String,combat:RefCounted)->void:
	var potency:=_values(source,combat);var duration:=int(potency.duration_ticks)
	if combat.has_method("_enhanced_duration"):duration=int(combat.call("_enhanced_duration",source,duration,"WEAK",target))
	var state:=_state(target)
	if not state.has("quake_triggers"):state["quake_triggers"]={}
	state.quake_triggers[str(source.id)+":"+kind]={"trigger_kind":kind,"source_id":source.id,"source_faction":source.get("faction_id",""),"until_tick":deadline,"slow_percent":float(potency.percent),"slow_duration_ticks":duration}

static func _prepare_tank_aura(source: Dictionary, kind: String, combat: RefCounted) -> void:
	var guard_id:String=IdentityM67.GUARDS.get(kind,BalanceM58.TANK_GUARDS.get(kind,""))
	if guard_id.is_empty(): return
	var hero: Dictionary=_heroes(combat).get(str(source.id),{})
	var rank := int(hero.get("skill_levels",{}).get(guard_id,0))
	var aura := IdentityM67.guard_aura(kind,rank) if IdentityM67.GUARDS.has(kind) else BalanceM58.tank_aura(kind,rank)
	aura=PowerM69.conditional_aura(aura)
	if aura.is_empty(): return
	var state := _state(source)
	var active := false
	if aura.condition=="STATIONARY_2S": active=_tick(combat)-int(state.get("still_since",_tick(combat)))>=40
	elif aura.condition=="ROOTED_HEAL_WINDOW": active=int(state.get("rooted_heal_until",-1))>_tick(combat)
	elif aura.condition=="FORMATION_2_ALLIES": active=_near(source,combat,90,true).size()>=2
	if not active: return
	var count := 0
	for target: Dictionary in _near(source,combat,int(aura.radius),true,true):
		if count>=int(aura.max_targets): break
		count+=1
		var receiver: Dictionary=target.innate_aura
		if float(receiver.get(aura.attribute,0))<float(aura.amount):
			receiver[aura.attribute]=aura.amount
			receiver.sources.append({"source_id":source.id,"innate_id":guard_id,"attribute":aura.attribute,"radius":aura.radius})

static func attack_raw_bonus(source: Dictionary, target: Dictionary, base: float, combat: RefCounted) -> float:
	if not _military(source) or not _military(target) or source.get("side") == target.get("side"): return 0.0
	var tick := _tick(combat)
	var state := _state(source)
	var kind := _kind(source,combat)
	var potency := _values(source,combat)
	var bonus := 0.0
	if ExpansionM66.has_hero(kind):
		var trigger:=str(ExpansionM66.INNATES[kind].trigger)
		if trigger=="RECENT_SKILL" and int(target.get("last_skill_tick",-1000000))>=0 and tick-int(target.last_skill_tick)<=60:bonus+=base*float(potency.percent)/100.0
		elif trigger=="CONTROLLED_BASIC" and (_active_status(target,"SLOW",tick) or int(target.get("root_until_tick",-1))>tick):bonus+=base*float(potency.percent)/100.0
		elif trigger=="THIRD_SAME_TARGET":
			if state.get("m66_attack_target","")!=target.id or tick-int(state.get("last_basic_tick",-1000000))>=80:state["m66_attack_count"]=0
			state["m66_attack_target"]=target.id
			state["m66_attack_count"]=int(state.get("m66_attack_count",0))+1
			if int(state.m66_attack_count)%3==0:bonus+=base*float(potency.percent)/100.0
		elif trigger=="TRAVEL_BASIC" and bool(state.get("m66_travel_ready",false)) and tick-int(state.get("m66_travel_proc",-1000000))>=60:
			bonus+=base*float(potency.percent)/100.0
			state["m66_travel_ready"]=false
			state["m66_travel_proc"]=tick
	if kind == "RANGER":
		for ally: Dictionary in _near(target,combat,100,false):
			if ally.id != source.id and ally.side == source.side and tick - int(_state(ally).get("last_basic_tick",-1000000)) <= 40: bonus += base * float(potency.percent)/100.0; break
	elif kind == "CINDER_STALKER" and int(target.hp) * 2 < int(target.max_hp): bonus += base * float(potency.percent)/100.0
	elif kind == "GEAR_HUNTER":
		if state.get("gear_target", "") != target.id or tick - int(state.get("last_basic_tick", -1000000)) >= 80: state["gear_count"] = 0
		state["gear_target"] = target.id
		state["gear_count"] = int(state.get("gear_count", 0)) + 1
		if int(state.gear_count) % 3 == 0: bonus += base * float(potency.percent)/100.0
	elif kind == "WIND_COURIER" and bool(state.get("wind_ready", false)) and tick - int(state.get("wind_last_proc", -1000000)) >= 40:
		bonus += base * float(potency.percent)/100.0
		state["wind_ready"] = false
		state["wind_last_proc"] = tick
	elif kind == "EMBER_CAVALIER":
		state["ember_attack_count"] = int(state.get("ember_attack_count",0)) + 1
		if int(state.ember_attack_count) % 3 == 0: _queue(target,source,"EMBER_THIRD","DAMAGE",base * float(potency.percent)/100.0,4,tick)
	elif kind == "SPORE_STALKER":
		for ally: Dictionary in _near(target,combat,60,false):
			if ally.id != source.id and ally.side == source.side: bonus += base * float(potency.percent)/100.0; break
	var target_state := _state(target)
	var mark: Dictionary = target_state.get("storm_mark",{})
	if not mark.is_empty() and int(mark.expires_tick) > tick and mark.side == source.side:
		bonus += minf(float(mark.get("amount_cap",36)),base * float(mark.get("percent",40))/100.0)
		target_state.erase("storm_mark")
	state["last_basic_tick"] = tick
	state["last_basic_target_id"] = target.id
	return bonus

static func skill_damage_percent(source: Dictionary, target: Dictionary, combat: RefCounted) -> float:
	if not _military(source) or not _military(target) or source.get("side") == target.get("side"): return 0
	var tick := _tick(combat)
	var kind := _kind(source,combat)
	var state := _state(source)
	var percent := float(_values(source,combat).get("percent",0))
	if MagesM68.has_hero(kind) and _paid(source,combat):
		if kind=="SUNGLASS_SCRIBE" and (source.position as Vector2i).distance_squared_to(target.position)>=170*170:return percent
		if kind=="CINDER_TESTATOR" and int(target.hp)*100>=int(target.max_hp)*70:return percent
		if kind=="FLUX_BOMBARDIER" and int(state.get("cast_serial",0))%2==0 and _target_once(source,target,"m68_flux_targets",2):return percent
		if kind=="POLLEN_COMET" and state.get("last_basic_target_id","")==target.id and tick-int(state.get("last_basic_tick",-1000000))<=60:return percent
		if kind=="OBSIDIAN_CANTOR" and tick-int(state.get("still_since",tick))>=40:return percent
	if kind=="RELIC_REAVER" and int(target.hp)*2<=int(target.max_hp):return percent
	if kind=="SLAG_DANCER" and int(target.get("armor",0))>=3:return percent
	if kind=="PRISM_MANTIS" and (int(target.get("stun_until_tick",-1))>tick or int(target.get("root_until_tick",-1))>tick):return percent
	if kind == "ARCANIST" and _near(source,combat,100,true).size() >= 2: return percent
	if kind == "LEAF_SEER" and (_active_status(target,"SLOW",tick) or int(target.get("root_until_tick",-1)) > tick): return percent
	if kind == "RUNE_ORACLE" and _active_status(target,"BURN",tick): return percent
	if kind == "ECHO_BINDER" and _active_status(target,"POISON",tick): return percent
	if kind == "VOLT_WEAVER" and _paid(source,combat) and int(state.get("cast_serial",0)) % 3 == 0:
		if _target_once(source,target,"volt_targets",3): return percent
	return 0

static func on_paid_cast(source: Dictionary, skill: Dictionary, combat: RefCounted) -> void:
	if not _military(source) or int(skill.get("mana_cost",0)) <= 0 or bool(skill.get("passive",false)): return
	var state := _state(source)
	state["cast_serial"] = int(state.get("cast_serial",0)) + 1
	state["paid_tick"] = _tick(combat)
	state["paid_skill_id"] = str(skill.get("id",""))
	if _kind(source,combat)=="VINE_WARDEN" and skill.get("id","")=="VINE_SHOCK": state["rooted_heal_until"]=_tick(combat)+120
	for key: String in ["volt_targets","mourn_targets","heal_targets","storm_targets","m68_flux_targets","m68_catalyst_targets"]: state[key] = []

static func heal_raw_bonus(source: Dictionary, target: Dictionary, raw_amount: float, combat: RefCounted) -> float:
	if _kind(source,combat) != "ASH_CHANTER" or not _paid(source,combat) or not _military(target) or source.side != target.side or int(target.hp) >= int(target.max_hp) or raw_amount <= 0: return 0.0
	var state := _state(source)
	if _tick(combat) - int(state.get("ash_heal_last",-1000000)) < 120: return 0.0
	var stacks := int(state.get("ash_embers",0))
	if stacks <= 0: return 0.0
	state["ash_embers"] = 0
	state["ash_heal_last"] = _tick(combat)
	return float(stacks)*float(_values(source,combat).amount)

static func on_heal(source: Dictionary, target: Dictionary, effective: int, combat: RefCounted) -> void:
	if effective <= 0 or not _military(source) or not _military(target) or source.side != target.side or not _paid(source,combat): return
	var kind := _kind(source,combat)
	var state := _state(source)
	var tick := _tick(combat)
	var potency := _values(source,combat)
	if kind == "COIL_MEDIC":
		if tick - int(state.get("coil_heal_last",-1000000)) < 120 and int(state.get("coil_cast_serial",-1)) != int(state.cast_serial): return
		if _target_once(source,target,"heal_targets",3):
			state["coil_heal_last"] = tick
			state["coil_cast_serial"] = state.cast_serial
			_shield(target,source,"BASIC_PERCENT",float(potency.amount_cap),float(potency.percent),float(potency.amount_cap),tick+60,tick)
	elif kind == "BLOOM_GUIDE": _queue(target,source,"BLOOM_HOT","HEAL",minf(float(potency.amount_cap),float(effective)*float(potency.percent)/100.0),4,tick,20,true)
	elif kind == "HEARTH_KEEPER" and _target_once(source,target,"heal_targets",3): _shield(target,source,"FLAT",minf(float(potency.amount_cap),float(effective)*float(potency.percent)/100.0),0,float(potency.amount_cap),tick+80,tick)
	elif kind == "SPORE_GUIDE" and _target_once(source,target,"heal_targets",1):
		for ally: Dictionary in _near(target,combat,90,true):
			if int(ally.hp) < int(ally.max_hp):
				_queue(ally,source,"SPORE_BOUNCE","HEAL",minf(float(potency.amount_cap),float(effective)*float(potency.percent)/100.0),1,tick,1)
				break

static func on_skill_hit(source: Dictionary, target: Dictionary, skill: Dictionary, base_damage: float, actual_damage: int, combat: RefCounted) -> void:
	if not _military(source) or not _military(target) or source.side == target.side or not _paid(source,combat): return
	var kind := _kind(source,combat)
	var state := _state(source)
	var target_state := _state(target)
	var tick := _tick(combat)
	var potency := _values(source,combat)
	if kind=="MYCELIAL_CATALYST" and actual_damage>0 and base_damage>0 and _target_once(source,target,"m68_catalyst_targets",3):
		if (state.m68_catalyst_targets as Array).size()==3 and int(state.get("m68_refunded_cast",-1))!=int(state.cast_serial):
			state["m68_refunded_cast"]=state.cast_serial
			_queue(source,source,"M68_THREE_BRANCH_RECOVERY","MANA",float(potency.amount),1,tick,1)
	if kind == "MOURN_ORACLE" and actual_damage > 0 and base_damage > 0:
		if tick - int(state.get("mourn_last",-1000000)) >= 120 or int(state.get("mourn_cast_serial",-1)) == int(state.cast_serial):
			if _target_once(source,target,"mourn_targets",3):
				state["mourn_last"] = tick
				state["mourn_cast_serial"] = state.cast_serial
				_queue(target,source,"MOURN_DOT","DAMAGE",minf(float(potency.amount_cap),base_damage*float(potency.percent)/100.0),4,tick)
	if kind == "THORN_CHANTER" and skill.get("effect","") == "ROOT" and int(target.get("root_until_tick",-1)) > tick and str(target.get("root_source_id",""))==str(source.id):
		target_state["thorn_bind"] = {"source_id":source.id,"expires_tick":int(target.root_until_tick),"percent":float(potency.percent)}
	if kind == "QUAKE_PRIEST" and skill.get("effect","") == "ROOT" and int(target.get("root_until_tick",-1)) > tick and str(target.get("root_source_id",""))==str(source.id):
		_queue_quake_trigger(source,target,int(target.root_until_tick),"ROOT",combat)
	if kind == "STORM_HERALD" and skill.get("effect","") == "STUN" and int(target.get("stun_until_tick",-1)) > tick and str(target.get("stun_source_id",""))==str(source.id):
		if tick - int(state.get("storm_last",-1000000)) >= 120 or int(state.get("storm_cast_serial",-1)) == int(state.cast_serial):
			if _target_once(source,target,"storm_targets",3):
				state["storm_last"] = tick
				state["storm_cast_serial"] = state.cast_serial
				target_state["storm_mark"] = {"source_id":source.id,"side":source.side,"expires_tick":tick+60,"percent":float(potency.percent),"amount_cap":float(potency.amount_cap)}

static func on_death(victim: Dictionary, killer: Dictionary, combat: RefCounted) -> void:
	if not _military(victim,false) or int(victim.get("hp",0)) > 0: return
	var state := _state(victim)
	if bool(state.get("death_receipted",false)): return
	state["death_receipted"] = true
	var tick := _tick(combat)
	for source: Dictionary in _all(combat):
		if source.side == victim.side or (source.position as Vector2i).distance_squared_to(victim.position) > 180*180: continue
		var kind := _kind(source,combat)
		var own := _state(source)
		if kind == "ASH_CHANTER": own["ash_embers"] = mini(3,int(own.get("ash_embers",0))+1)
		elif kind == "ASH_MARSHAL" and tick - int(own.get("ash_death_last",-1000000)) >= 160:
			var potency := _values(source,combat)
			_queue(source,source,"ASH_DEATH","HEAL",minf(float(potency.amount_cap),float(source.max_hp)*float(potency.max_hp_percent)/100.0),1,tick,1)
			own["ash_death_last"] = tick
		elif kind=="OSSUARY_KNIGHT" and tick-int(own.get("m66_death_last",-1000000))>=160:
			_queue(source,source,"M66_FERRY_DEATH","HEAL",float(_values(source,combat).amount),1,tick,1)
			own["m66_death_last"]=tick

static func on_status_applied(source:Dictionary,target:Dictionary,status:Dictionary,combat:RefCounted)->void:
	# Record the accepted status AFTER strongest-source/refresh legality. An
	# animation, attempted weak overwrite, cleanse or guessed timer cannot proc.
	if status.get("kind","")!="ARMOR_BREAK" or _kind(source,combat)!="QUAKE_PRIEST" or not _military(target):return
	_queue_quake_trigger(source,target,int(status.expires_tick),"ARMOR_BREAK",combat)

static func incoming_basic_percent(target: Dictionary, source: Dictionary, combat: RefCounted) -> float:
	# A tower is also a real basic-attack source. Only proc targets exclude
	# buildings/workers; incoming defense must not silently ignore enemy towers.
	if not _military(target) or source.is_empty() or source.get("side","") == target.get("side",""): return 100
	var reduction := float(target.get("innate_aura",{}).get("basic_damage_reduction_percent",0))
	var kind := _kind(target,combat)
	var percent := float(_values(target,combat).get("percent",0))
	if kind=="BRIDGE_VANGUARD" and _near(target,combat,90,true).size()>=2:reduction=maxf(reduction,percent)
	if kind=="RIVET_LEGIONARY" and _tick(combat)-int(_state(target).get("still_since",_tick(combat)))>=40:reduction=maxf(reduction,percent)
	if kind=="BASALT_CHAMPION" and int(source.get("attack_range",999))<=80:reduction=maxf(reduction,percent)
	if kind == "COIL_WARDEN" and _tick(combat) - int(_state(target).get("still_since",_tick(combat))) >= 40: reduction = maxf(reduction,percent)
	if kind == "RIDGE_JARL" and int(target.hp)*2 <= int(target.max_hp) and source.get("attack_type","") == "PIERCE": reduction = maxf(reduction,percent)
	if kind == "TUNNEL_SENTINEL" and int(source.get("attack_range",999)) <= 80 and _near(target,combat,90,true).size() >= 2: reduction = maxf(reduction,percent)
	return 100 - reduction
static func outgoing_basic_percent(source: Dictionary, combat: RefCounted) -> float:
	var bind: Dictionary = _state(source).get("thorn_bind",{})
	if not bind.is_empty() and int(bind.expires_tick) > _tick(combat) and int(source.get("root_until_tick",-1)) == int(bind.expires_tick) and str(source.get("root_source_id",bind.source_id)) == str(bind.source_id): return 100-float(bind.get("percent",10))
	return 100
static func healing_received_percent(target: Dictionary, active: bool = true) -> float:
	if not active: return 100 # Passive regen/HoT never double dips active-heal auras.
	var aura: Dictionary = target.get("innate_aura",{})
	return 100 + float(aura.get("healing_received_percent",0)) - float(aura.get("active_healing_penalty_percent",0))
static func control_resist_percent(target: Dictionary) -> float: return float(target.get("innate_aura",{}).get("control_resist_percent",0))

static func consume_shield(target: Dictionary, damage: float, is_basic: bool, combat: RefCounted) -> float:
	var shields: Dictionary = target.get("innate_shield",{})
	var tick := _tick(combat)
	var chosen := ""
	var best := 0.0
	var ids := shields.keys()
	ids.sort()
	for id: String in ids:
		var shield: Dictionary = shields[id]
		if int(shield.expires_tick) <= tick: continue
		var amount := minf(damage,float(shield.amount)) if shield.kind == "FLAT" else minf(float(shield.cap),damage*float(shield.percent)/100.0) if is_basic else 0.0
		if amount > best: chosen = id; best = amount
	if chosen.is_empty(): return maxf(0.0,damage)
	if shields[chosen].kind == "BASIC_PERCENT": shields.erase(chosen)
	else:
		shields[chosen].amount = float(shields[chosen].amount) - best
		if float(shields[chosen].amount) <= 0.0: shields.erase(chosen)
	return maxf(0.0,damage-best)

static func take_due_effects(combat: RefCounted) -> Array[Dictionary]:
	# Fractional amount is intentionally unrounded; per-beneficiary/kind carry
	# lives in the host settlement. Emit only once, never change HP/MP here.
	var result: Array[Dictionary] = []
	var tick := _tick(combat)
	for target: Dictionary in _all(combat):
		var effects: Dictionary = target.get("secondary_effects",{})
		var keys := effects.keys()
		keys.sort()
		for key: String in keys:
			var effect: Dictionary = effects[key]
			if effect.get("origin","") != "INNATE" or int(effect.get("next_tick",tick+1)) > tick: continue
			var event := effect.duplicate(true)
			event["amount"] = float(effect.amount_per_pulse)
			result.append(event)
			effect.pulses_left = int(effect.pulses_left)-1
			effect.next_tick = int(effect.next_tick)+int(effect.interval_ticks)
			if int(effect.pulses_left) <= 0: effects.erase(key)
	return result
