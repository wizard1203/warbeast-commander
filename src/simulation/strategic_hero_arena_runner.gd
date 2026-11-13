extends RefCounted
## Isolated, explicitly gifted training fixtures over the actual Combat engine.
## No session, economy stock, alternative damage formula or renderer timer.
const Combat = preload("res://src/simulation/strategic_combat.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Currency = preload("res://src/simulation/strategic_currency.gd")
const Progression = preload("res://src/simulation/strategic_hero_progression.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const FirstRelease = preload("res://src/simulation/first_release_catalog.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Matches = preload("res://src/simulation/strategic_match_catalog.gd")
const FormationMarchR12 = preload("res://src/simulation/strategic_formation_march_r12.gd")
const VERSION := "m68-real-combat-random-trio-arena-v1"
const MODES := {"DUEL":"英雄单挑", "HERO_VS_TROOPS":"英雄对兵群", "UNIT_VS_TROOPS":"单兵对兵群", "HERO_CHALLENGE":"英雄一对三", "MULTI_HERO":"三英雄混战", "MIXED":"英雄带兵团战", "RANDOM_TRIO":"随机三英雄 · 四格校准"}
const TRIO_GEAR := ["IRON_BLADE","WARD_MAIL","MANA_CRYSTAL","SWIFT_GLOVES"]
const SIDES := ["PLAYER", "AI"]
const FIXTURE_SCOPE := "Explicit isolated free training setup: trusted spawns/XP/items, not paid strategic recruitment; one full HP/MP setup after legal learning/equipment, normal kill XP thereafter."
var _config: Dictionary = {}
var _combat: RefCounted
var _running := false
var _paused := false
var _elapsed := 0
var _outcome := "READY"
var _winner := ""
var _metrics: Dictionary = {}
var _initial: Dictionary = {}
var _sources: Dictionary = {}
var _seen_events: Dictionary = {}
var _event_totals: Dictionary = {}
var _last_snapshot: Dictionary = {}
var _last_metric_tick := -1
var _initial_force_roster_r19: Dictionary = {}
const ForceReadoutR19 = preload("res://src/simulation/strategic_arena_force_readout_r19.gd")

static func catalog() -> Dictionary:
	var heroes: Array[Dictionary] = []
	var units := {}
	for faction: String in Factions.IDS:
		for kind: String in Factions.heroes_for(faction):
			var row: Dictionary = Heroes.profile(kind)
			row["id"] = kind
			heroes.append(row)
		for kind: String in Factions.units_for(faction): units[kind] = Units.profile(kind)
	return {"version":VERSION, "currency_version":Currency.VERSION, "resource_keys":Currency.ACTIVE_KEYS.duplicate(), "resource_labels":{"MATERIAL":Currency.LABEL}, "heroes":heroes, "items":Items.ITEMS.duplicate(true), "units":units, "factions":Factions.get_catalog(), "modes":MODES.duplicate(true)}

static func preset(mode: String = "DUEL", left: String = FirstRelease.DEFAULT_PLAYER_FACTION, right: String = FirstRelease.DEFAULT_OPPONENT_FACTION) -> Dictionary:
	if mode == "RANDOM_TRIO": return random_trio_preset(1701,left,right)
	var result := {"mode":mode, "seed":1701, "limit_seconds":60, "auto_consumables":true, "sides":{}}
	for side: String in SIDES:
		var faction := left if side == "PLAYER" else right
		if faction not in Factions.IDS: faction = "HUMAN"
		var count := 3 if mode in ["MULTI_HERO","MIXED"] or (mode == "HERO_CHALLENGE" and side == "AI") else 1
		if mode == "UNIT_VS_TROOPS" or (mode == "HERO_VS_TROOPS" and side == "AI"): count = 0
		var heroes: Array[Dictionary] = []
		var available: Array = Factions.heroes_for(faction)
		for index: int in range(count): heroes.append({"archetype":str(available[index]), "level":5, "equipment":[], "consumables":[]})
		var troops: Array[Dictionary] = []
		var frontline: String = Factions.main_unit_for(faction)
		if mode in ["HERO_VS_TROOPS","UNIT_VS_TROOPS"]:
			if side == "AI": troops = _opening_troops(faction)
			elif mode == "UNIT_VS_TROOPS": troops = [{"unit_type":frontline,"count":1}]
		elif mode == "MIXED": troops = _opening_troops(faction)
		result.sides[side] = {"faction_id":faction, "heroes":heroes, "troops":troops}
	return result

## Same seed/factions reproduce identities independently of Combat RNG. The four
## cells alter gear/troops only; they do not reshuffle or spend strategic stock.
static func random_trio_preset(seed: int, left: String = FirstRelease.DEFAULT_PLAYER_FACTION, right: String = FirstRelease.DEFAULT_OPPONENT_FACTION, level: int = 5, geared: bool = false, with_troops: bool = false) -> Dictionary:
	var result := preset("MIXED",left,right)
	result.mode = "RANDOM_TRIO"
	result.seed = seed
	result.auto_consumables = false
	for side: String in SIDES:
		var faction := str(result.sides[side].faction_id)
		var deck := shuffled_heroes(faction,seed,"left" if side == "PLAYER" else "right")
		var heroes: Array[Dictionary] = []
		for index: int in range(mini(3,deck.size())):
			heroes.append({"archetype":deck[index],"level":clampi(level,1,8),"equipment":TRIO_GEAR.duplicate() if geared else [],"consumables":[]})
		result.sides[side].heroes = heroes
		result.sides[side].troops = trio_troops(faction) if with_troops else []
	return result

static func shuffled_heroes(faction: String, seed: int, salt: String = "") -> Array[String]:
	var result: Array[String] = []
	for id: String in Factions.heroes_for(faction): result.append(id)
	result.sort_custom(func(a: String,b: String) -> bool:
		var aa := (str(seed)+"/"+faction+"/"+salt+"/"+a).sha256_text()
		var bb := (str(seed)+"/"+faction+"/"+salt+"/"+b).sha256_text()
		return aa < bb if aa != bb else a < b)
	return result

static func r7_wave_one_preset(seed: int = 1701) -> Dictionary:
	# Retain the old callable interface with an edition-legal mage drill.
	var result := preset("MIXED","HUMAN","MACHINE")
	result["first_release_mage_preset"]=true
	result.seed=seed
	result.limit_seconds=90
	result.auto_consumables=false
	for side: String in SIDES:
		result.sides[side].heroes=[{"archetype":"SUNGLASS_SCRIBE" if side=="PLAYER" else "FLUX_BOMBARDIER","level":8,"skill_ranks":[3,3,2],"equipment":[],"consumables":[]}]
		result.sides[side].troops=trio_troops(str(result.sides[side].faction_id))
	return result

static func trio_troops(faction: String) -> Array[Dictionary]:
	if not Factions.is_valid(faction): return []
	# Canonical opening + explicit support gift; its cost/pop are reported,
	# not asserted equal across factions with different support populations.
	var result:=_opening_troops(faction)
	result.append({"unit_type":Factions.units_for(faction,"SUPPORT")[0],"count":1})
	return result

static func _opening_troops(faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for row: Dictionary in Factions.opening_recipe(faction):result.append({"unit_type":row.unit_type,"count":row.count})
	return result

func configure(request: Dictionary) -> Dictionary:
	var validation := validate(request)
	if not validation.accepted: return validation
	_config = request.duplicate(true)
	return reset_run()

static func validate(request: Dictionary) -> Dictionary:
	if request.get("mode","") not in MODES: return _reject("INVALID_MODE")
	if typeof(request.get("seed")) != TYPE_INT: return _reject("INVALID_SEED")
	if typeof(request.get("limit_seconds")) != TYPE_INT or int(request.limit_seconds) < 1 or int(request.limit_seconds) > 300: return _reject("INVALID_TIME_LIMIT")
	if not request.get("sides") is Dictionary: return _reject("INVALID_SIDES")
	if request.has("auto_consumables") and typeof(request.auto_consumables) != TYPE_BOOL: return _reject("INVALID_AUTOMATION")
	for side: String in SIDES:
		var slot: Variant = request.sides.get(side)
		if not slot is Dictionary or slot.get("faction_id","") not in Factions.IDS: return _reject("INVALID_FACTION")
		if not slot.get("heroes") is Array or not slot.get("troops") is Array: return _reject("INVALID_ROSTER")
		if slot.heroes.size() > 3: return _reject("HERO_LIMIT")
		if request.mode == "RANDOM_TRIO" and slot.heroes.size() != 3: return _reject("RANDOM_TRIO_REQUIRES_THREE_HEROES")
		var seen: Array[String] = []
		var body_count := 0
		for hero: Variant in slot.heroes:
			if not hero is Dictionary: return _reject("INVALID_HERO")
			var kind := str(hero.get("archetype",""))
			if kind not in Factions.heroes_for(str(slot.faction_id)) or kind in seen: return _reject("INVALID_OR_DUPLICATE_HERO")
			seen.append(kind)
			if typeof(hero.get("level")) != TYPE_INT or int(hero.level) < 1 or int(hero.level) > 8: return _reject("INVALID_LEVEL")
			var equipment: Variant = hero.get("equipment",[])
			var consumables: Variant = hero.get("consumables",[])
			if not equipment is Array or not consumables is Array or equipment.size() > 4 or consumables.size() > 2: return _reject("INVALID_ITEM_SLOTS")
			var inventory_check := {"inventory":{}, "equipment":[]}
			for item: Variant in equipment + consumables:
				if typeof(item) != TYPE_STRING or item not in Items.ITEMS: return _reject("INVALID_ITEM")
				if (item in equipment) == bool(Items.ITEMS[item].get("consumable",false)): return _reject("WRONG_ITEM_SLOT")
				if not Items.grant_loot(inventory_check,item).accepted: return _reject("ITEM_NOT_LEGAL")
			if hero.has("skill_ranks"):
				var ranks: Variant = hero.skill_ranks
				if not ranks is Array or ranks.size() != 3: return _reject("INVALID_SKILL_RANKS")
				var total := 0
				var ids: Array = Heroes.profile(kind).skill_ids
				for n: int in range(3):
					if typeof(ranks[n]) != TYPE_INT or int(ranks[n]) < 0 or int(ranks[n]) > Progression.max_skill_rank(ids[n]): return _reject("INVALID_SKILL_RANK")
					if int(ranks[n]) > 0 and Progression.required_level(ids[n],int(ranks[n])) > int(hero.level): return _reject("HERO_LEVEL_REQUIRED")
					total += int(ranks[n])
				if total > int(hero.level): return _reject("NO_SKILL_POINTS")
			body_count += 1
		for troop: Variant in slot.troops:
			if not troop is Dictionary or troop.get("unit_type","") not in Factions.units_for(str(slot.faction_id)): return _reject("INVALID_TROOP")
			if typeof(troop.get("count")) != TYPE_INT or int(troop.count) < 0 or int(troop.count) > 24: return _reject("INVALID_TROOP_COUNT")
			body_count += int(troop.count)
		if body_count < 1 or body_count > 27: return _reject("INVALID_BODY_COUNT")
	return {"accepted":true, "error":""}

func reset_run() -> Dictionary:
	if _config.is_empty(): return _reject("NOT_CONFIGURED")
	_running = false
	_paused = false
	_elapsed = 0
	_outcome = "READY"
	_winner = ""
	_metrics.clear()
	_initial.clear()
	_initial_force_roster_r19.clear()
	_seen_events.clear()
	_event_totals.clear()
	_last_metric_tick = -1
	_sources = source_hashes()
	var participants: Array[Dictionary] = []
	for side: String in SIDES: participants.append({"faction_id":_config.sides[side].faction_id,"controller":"HUMAN","difficulty_id":"STANDARD"})
	var resolved: Dictionary = Matches.resolve({"map_id":"borderlands","participants":participants})
	if not resolved.accepted: return _reject("MATCH_SETUP_FAILED")
	var setup: Dictionary = resolved.match_config.duplicate(true)
	setup.terrain = []
	_combat = Combat.new(int(_config.seed),setup)
	# Explicit isolated arena installation; unlike natural Session no production,
	# workers, resources, camps, inherited hero record, building or paid receipt.
	_combat._soldiers.clear()
	_combat._hero_data.clear()
	_combat.reset_hero_statistics(true)
	_combat._buildings.clear()
	_combat._neutrals = null
	_combat._shared_xp_receipts.clear()
	_combat._feedback_events.clear()
	_combat.sync_environment([])
	_combat._reindex()
	for side: String in SIDES:
		var data: Dictionary = _config.sides[side]
		var serial := 0
		var formation: String = "player_alpha" if side == "PLAYER" else "ai_alpha"
		var center := Vector2i(1150,1100) if side == "PLAYER" else Vector2i(1550,1100)
		_combat._warbands[formation].anchor = center
		_combat._warbands[formation].home_anchor = center
		_combat._warbands[formation].destination = Vector2i(1550,1100) if side == "PLAYER" else Vector2i(1150,1100)
		for hero: Dictionary in data.heroes:
			var id := side.to_lower() + "_arena_hero_" + str(serial)
			var position := center + Vector2i(0,serial * 95 - (data.heroes.size()-1)*45)
			if not _spawn(id,side,"hero",position,formation,str(hero.archetype)): return _reject("HERO_SPAWN_FAILED")
			_install_hero(id,hero)
			serial += 1
		var troop_index := 0
		# Setup must reserve the actual new body volumes, not the authored
		# display pixels. Keep every requested troop; do not fail a legal large
		# roster or silently drop members because its old65px grid is too tight.
		var troop_radius := 0
		var troop_count := 0
		for group: Dictionary in data.troops:
			troop_radius = maxi(troop_radius,int(Combat.stats_for_type(str(group.unit_type)).radius))
			troop_count += int(group.count)
		var troop_pitch := maxi(65,2*troop_radius+4)
		var troop_front := maxi(90,troop_radius+30+8)
		var row_origin := (mini(6,troop_count)-1)*troop_pitch/2
		for group: Dictionary in data.troops:
			for n: int in range(int(group.count)):
				var id := side.to_lower() + "_arena_troop_" + str(troop_index)
				var direction := -1 if side == "PLAYER" else 1
				var position := center + Vector2i((troop_front + (troop_index/6)*troop_pitch)*direction,(troop_index%6)*troop_pitch-row_origin)
				if not _spawn(id,side,str(group.unit_type),position,formation): return _reject("TROOP_SPAWN_FAILED")
				troop_index += 1
		var result: Dictionary = _combat.apply_command({"type":"ATTACK_MOVE","subject_id":formation,"target_position":_combat._warbands[formation].destination},side)
		if not result.accepted: return _reject("ATTACK_ORDER_FAILED")
	_combat._reindex()
	# All bodies, including legally geared heroes, participate in one actual
	# range layout. Reserve both physical fronts before publishing frame zero.
	var sides := {"PLAYER":[],"AI":[]}
	for body: Dictionary in _combat._soldiers.values(): sides[str(body.side)].append(body)
	var placement := FormationMarchR12.arena_placement(sides,_combat._bounds)
	if not bool(placement.accepted): return _reject(str(placement.error))
	for body: Dictionary in _combat._soldiers.values():
		body.position = placement.positions[str(body.id)]
		body.direct_destination = body.position
		body.route=[];body.route_target=body.position;body.route_geometry=""
	for side: String in SIDES:
		var army: Dictionary = _combat._warbands["player_alpha" if side=="PLAYER" else "ai_alpha"]
		army.anchor=placement.anchors[side];army.home_anchor=army.anchor
		army.facing=placement.facings[side]
		army.destination=placement.anchors["AI" if side=="PLAYER" else "PLAYER"]
	_last_snapshot = _combat.get_snapshot()
	_initial_force_roster_r19 = ForceReadoutR19.capture(_last_snapshot)
	for body: Dictionary in _last_snapshot.soldiers:
		_initial[body.id] = {"hp":body.max_hp,"mana":body.get("max_mana",0),"level":body.get("level",0),"population":body.get("population",1),"side":body.side,"unit_type":body.unit_type,"archetype":body.get("hero_archetype","")}
		_metrics[body.id] = {"hard_control_ticks":0,"slow_ticks":0,"casts":0,"mana_paid":0,"skill_casts":{},"damage_received":0,"effective_heal_events":0,"consumables_used":0}
	_seen_events.clear()
	return {"accepted":true,"error":"","fixture_scope":FIXTURE_SCOPE}

func _spawn(id: String, side: String, type: String, position: Vector2i, army: String, archetype: String = "") -> bool:
	var event := {"type":"SPAWN","id":id,"side":side,"unit_type":type,"position":position,"warband_id":army}
	if not archetype.is_empty(): event.hero_archetype = archetype
	_combat.apply_world_events([event])
	return _combat._soldiers.has(id)

func _install_hero(id: String, setup: Dictionary) -> void:
	var hero: Dictionary = _combat._hero_data[id]
	var level := int(setup.level)
	if level > 1: _combat._grant_hero_xp(id,int(Progression.XP_THRESHOLDS[level-1]))
	var ranks: Array = setup.get("skill_ranks",default_skill_ranks(str(setup.archetype),level))
	var ids: Array = Heroes.profile(str(setup.archetype)).skill_ids
	for index: int in range(ids.size()):
		for rank: int in range(int(ranks[index])):
			var result: Dictionary = _combat.apply_command({"type":"UPGRADE_HERO_SKILL","unit_id":id,"skill_id":ids[index]},str(_combat._soldiers[id].side))
			assert(result.accepted,"Arena prevalidated learning must use Combat legality")
	hero.inventory = {}
	hero.equipment = []
	for item: String in setup.get("equipment",[]) + setup.get("consumables",[]):
		assert(Items.grant_loot(hero,item).accepted,"Arena prevalidated item must use real Items grant")
		_combat._refresh_item_transaction_stats(id,item)
	_combat._refresh_stats(_combat._soldiers[id])
	# One setup-only full recovery, never performed during running/pause/reset
	# observation. Buying ordinary-match equipment still cannot refill health.
	_combat._soldiers[id].hp = _combat._soldiers[id].max_hp
	hero.mana = hero.max_mana
	_combat.apply_command({"type":"SET_HERO_AUTOMATION","unit_id":id,"auto_attack":true,"auto_skills":true},str(_combat._soldiers[id].side))

static func default_skill_ranks(kind: String, level: int) -> Array:
	var result := [0,0,0]
	var ids: Array = Heroes.profile(kind).skill_ids
	for earned_level: int in range(1,clampi(level,1,8)+1):
		var chosen := -1
		if earned_level in [5,8] and Progression.required_level(ids[2],result[2]+1) <= earned_level: chosen = 2
		else:
			for index: int in [0,1]:
				if int(result[index]) < Progression.max_skill_rank(ids[index]) and (chosen < 0 or int(result[index]) < int(result[chosen])): chosen = index
		if chosen >= 0: result[chosen] += 1
	return result

func start_run() -> Dictionary:
	if _combat == null: return _reject("NOT_CONFIGURED")
	if _outcome not in ["READY","RUNNING"]: return _reject("RESET_REQUIRED")
	_running = true
	_paused = false
	_outcome = "RUNNING"
	return {"accepted":true,"error":""}

func set_paused(value: bool) -> void:
	_paused = value

func step(count: int = 1) -> void:
	if not _running or _paused or _combat == null: return
	for n: int in range(clampi(count,0,6000)):
		if not _running: break
		_elapsed += 1
		_combat.advance_tick(_elapsed,"BATTLE",[],{})
		if bool(_config.get("auto_consumables",true)) and _elapsed % 10 == 0: _use_consumables()
		_observe()
		_finish_if_needed()
	_last_snapshot = _combat.get_snapshot()

func _use_consumables() -> void:
	for id: String in _combat._hero_data:
		var hero: Dictionary = _combat._hero_data[id]
		var body: Dictionary = _combat._soldiers.get(id,{})
		if body.is_empty():continue
		if int(body.hp) <= 0: continue
		for item: String in hero.inventory:
			if int(hero.inventory[item]) <= 0 or not bool(Items.ITEMS.get(item,{}).get("consumable",false)): continue
			var recipe: Dictionary = Items.ITEMS[item]
			var useful := int(recipe.get("heal",0)) > 0 and int(body.hp)*100 < int(body.max_hp)*55
			useful = useful or (int(recipe.get("mana",0)) > 0 and int(hero.mana)*100 < int(hero.max_mana)*40)
			if int(recipe.get("heal",0)) <= 0 and int(recipe.get("mana",0)) <= 0: useful = not str(body.get("target_id","")).is_empty()
			if not useful: continue
			var result: Dictionary = _combat.apply_command({"type":"USE_ITEM","unit_id":id,"item_id":item},str(body.side))
			if result.accepted:
				_metrics[id].consumables_used += 1
				break

func _observe() -> void:
	if _elapsed <= _last_metric_tick: return
	_last_metric_tick = _elapsed
	for id: String in _metrics:
		var body: Dictionary = _combat._soldiers.get(id,{})
		if body.is_empty():continue
		# Keep only finite scalar legacy report facts, never a spatial body.
		var last:Dictionary={}
		for key:String in ["id","side","unit_type","hero_archetype","max_hp","max_mana","damage_dealt","healing_done","level"]:
			if body.has(key):last[key]=body[key]
		_metrics[id]["last_state"]=last
		# Combat._record_damage accumulates *all* actual same-tick damage in
		# last_damage_amount, including multiple attackers and lethal hits.
		# HP differences would incorrectly subtract real recovery or shields.
		if int(body.get("last_damage_tick",-1)) == _elapsed:
			_metrics[id].damage_received += int(body.get("last_damage_amount",0))
		# Arena only dispatches the normal one-cast-per-hero-per-tick automation;
		# its independent accepted skill record survives death and receipt eviction.
		# Pure zero-damage control is still a paid accepted cast.
		if _combat._hero_data.has(id) and int(body.get("last_skill_tick",-1)) == _elapsed:
			var skill_id := str(body.get("last_skill_id",""))
			var skill: Dictionary = _combat._published_skill(_combat._hero_data[id],skill_id)
			_metrics[id].casts += 1
			_metrics[id].mana_paid += int(skill.get("mana_cost",0))
			_metrics[id].skill_casts[skill_id] = int(_metrics[id].skill_casts.get(skill_id,0))+1
		if int(body.hp) <= 0: continue
		if maxi(int(body.stun_until_tick),int(body.root_until_tick)) > _elapsed: _metrics[id].hard_control_ticks += 1
		for status: Dictionary in _combat._status_effects(body):
			if str(status.get("kind",status.get("id",""))) == "SLOW": _metrics[id].slow_ticks += 1; break
	# Append-ordered authority feedback is bounded. Walk the fresh suffix, not
	# every retained event on every tick of a large headless matrix.
	for index: int in range(_combat._feedback_events.size()-1,-1,-1):
		var event: Dictionary = _combat._feedback_events[index]
		var id := str(event.event_id)
		if _seen_events.has(id): break
		_seen_events[id] = true
		var kind := str(event.kind)
		_event_totals[kind] = int(_event_totals.get(kind,0)) + 1
		var target := str(event.get("target",{}).get("id",""))
		if kind == "HEAL" and _metrics.has(target): _metrics[target].effective_heal_events += int(event.get("amount",0))

func _finish_if_needed() -> void:
	var alive := {"PLAYER":0,"AI":0}
	for body: Dictionary in _combat._soldiers.values():
		if int(body.hp) > 0: alive[body.side] += 1
	if int(alive.PLAYER) == 0 or int(alive.AI) == 0:
		_running = false
		if int(alive.PLAYER) == 0 and int(alive.AI) == 0: _outcome = "DRAW"
		else:
			_winner = "PLAYER" if int(alive.PLAYER) > 0 else "AI"
			_outcome = _winner + "_WIN"
	elif _elapsed >= int(_config.limit_seconds)*20:
		_running = false
		_outcome = "TIME_BOUND"
		_winner = ""

func initial_force_roster_r19() -> Dictionary:
	return _initial_force_roster_r19.duplicate(true)

func snapshot() -> Dictionary:
	if _combat == null: return {}
	var result: Dictionary = _combat.get_snapshot()
	result["arena"] = {"version":VERSION,"mode":_config.mode,"elapsed_ticks":_elapsed,"limit_ticks":int(_config.limit_seconds)*20,"running":_running,"paused":_paused,"outcome":_outcome,"winner":_winner,"fixture_scope":FIXTURE_SCOPE}
	return result

func report() -> Dictionary:
	var sides := {}
	for side: String in SIDES: sides[side] = {"initial_units":0,"initial_population":0,"alive":0,"hp":0,"max_hp":0,"damage_dealt":0,"healing_recorded":0,"hard_control_seconds":0.0,"casts":0,"mana_paid":0,"catalog_cost":{"FOOD":0,"MATERIAL":0,"ESSENCE":0}}
	var rows: Array[Dictionary] = []
	if _combat != null:
		var current:Dictionary={}
		for body:Dictionary in _combat.get_snapshot().soldiers:current[str(body.id)]=body
		for id:String in _initial:
			var initial:Dictionary=_initial[id]
			var metric: Dictionary = _metrics.get(id,{})
			var side:=str(initial.side)
			var fallback:Dictionary=metric.get("last_state",{}).duplicate()
			fallback.merge({"id":id,"side":side,"unit_type":initial.unit_type,"hero_archetype":initial.archetype,"hp":0,"mana":0},true)
			if not fallback.has("max_hp"):fallback["max_hp"]=initial.hp
			var body:Dictionary=current.get(id,fallback)
			var row := {"id":id,"side":side,"unit_type":body.unit_type,"archetype":body.get("hero_archetype",""),"hp":body.hp,"max_hp":body.max_hp,"mana":body.get("mana",0),"max_mana":body.get("max_mana",0),"alive":int(body.hp)>0,"initial_level":initial.get("level",0),"final_level":_combat._hero_data.get(id,{}).get("level",body.get("level",0)),"damage_dealt":int(body.get("damage_dealt",0)),"healing_recorded":int(body.get("healing_done",0)),"hard_control_seconds":float(metric.get("hard_control_ticks",0))/20.0,"slow_seconds":float(metric.get("slow_ticks",0))/20.0,"casts":int(metric.get("casts",0)),"mana_paid":int(metric.get("mana_paid",0)),"damage_received":int(metric.get("damage_received",0)),"effective_heal_events":int(metric.get("effective_heal_events",0)),"consumables_used":int(metric.get("consumables_used",0))}
			rows.append(row)
			row["skill_casts"] = metric.get("skill_casts",{}).duplicate(true)
			var total: Dictionary = sides[side]
			total.initial_units += 1
			total.initial_population += int(_initial.get(id,{}).get("population",1))
			total.alive += 1 if int(body.hp)>0 else 0
			for field: String in ["hp","max_hp","damage_dealt","healing_recorded","hard_control_seconds","casts","mana_paid"]: total[field] += row[field]
	for side: String in SIDES:
		if _config.is_empty(): continue
		for hero: Dictionary in _config.sides[side].heroes:
			for item: String in hero.get("equipment",[]) + hero.get("consumables",[]):
				var cost: Dictionary = Items.total_cost(item)
				for resource: String in cost: sides[side].catalog_cost[resource] += int(cost[resource])
		for group: Dictionary in _config.sides[side].troops:
			var recipe: Dictionary = Units.UNITS[group.unit_type]
			for resource: String in recipe.get("cost",{}): sides[side].catalog_cost[resource] += int(recipe.cost[resource])*int(group.count)
		# Hero slots have no invented common recruitment price. Separate the
		# authoritative troop/item budget from hero count and initial population.
		sides[side]["hero_count"] = _config.sides[side].heroes.size()
		sides[side]["damage_per_second"] = float(sides[side].damage_dealt)/maxf(float(_elapsed)/20.0,0.05)
	var after := source_hashes()
	return {"version":VERSION,"config":_config.duplicate(true),"fixture_scope":FIXTURE_SCOPE,"elapsed_ticks":_elapsed,"elapsed_seconds":float(_elapsed)/20.0,"outcome":_outcome,"winner":_winner,"running":_running,"paused":_paused,"sides":sides,"units":rows,"event_totals":_event_totals.duplicate(true),"hero_statistics":_combat.get_hero_statistics() if _combat != null else {},"state_sha256":state_hash(),"source_sha256":_sources.duplicate(true),"source_after_sha256":after,"source_unchanged":_sources==after,"scope":"M69 hero_statistics is the actual HP/control settlement ledger, including batch/instant-DoT interleaving; sides/units/event_totals retain historical event counters for matched comparison and are not an exact effective-HP ledger. Default recovery is distinct from active healing. TIME_BOUND is unfinished. Fixture troop/item prices exclude hero recruitment and are not paid."}

func state_hash() -> String:
	return (var_to_str(_combat.get_state()) + var_to_str([_elapsed,_outcome,_winner])).sha256_text() if _combat != null else ""

static func source_hashes() -> Dictionary:
	var result := {}
	for path: String in ["first_release_catalog.gd","strategic_match_catalog.gd","strategic_currency.gd","strategic_hero_arena_runner.gd","strategic_combat.gd","strategic_combat_buffs.gd","strategic_hero_catalog.gd","strategic_hero_expansion_m66.gd","strategic_hero_mages_m68.gd","strategic_hero_roles_m68.gd","strategic_hero_calibration_m68.gd","strategic_hero_growth_m67.gd","strategic_hero_identity_m67.gd","strategic_hero_progression.gd","strategic_hero_balance_m58.gd","strategic_hero_skill_variety.gd","strategic_hero_innates.gd","strategic_hero_items.gd","strategic_damage_rules.gd","strategic_unit_catalog.gd","strategic_balance_catalog.gd","strategic_faction_catalog.gd","strategic_army_support.gd","strategic_combat_traits.gd","strategic_hero_skill_geometry.gd","strategic_combat_targeting.gd","strategic_navigation.gd","unit_body_resolver.gd"]:
		var full := "res://src/simulation/"+path
		if FileAccess.file_exists(full): result[full.trim_prefix("res://")] = FileAccess.get_sha256(full)
	for extra: String in ["src/simulation/strategic_hero_rework_r7_catalog.gd","src/simulation/strategic_hero_rework_r7_runtime.gd","assets/data/hero-rework-r7-wave1.json"]:
		result[extra]=FileAccess.get_sha256("res://"+extra)
	return result

static func _reject(error: String) -> Dictionary:
	return {"accepted":false,"error":error}
