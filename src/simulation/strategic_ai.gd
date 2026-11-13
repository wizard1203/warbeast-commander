extends RefCounted
## Bounded, deterministic macro controller. Only the host can execute its
## commands; public observations never become a second economic/combat ledger.

const World = preload("res://src/simulation/strategic_world.gd")
const Progression = preload("res://src/simulation/strategic_progression_catalog.gd")
const HeroCatalog = preload("res://src/simulation/strategic_hero_catalog.gd")
const SkillGeometry = preload("res://src/simulation/strategic_hero_skill_geometry.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Economy = preload("res://src/simulation/strategic_economy_catalog.gd")
const Difficulty = preload("res://src/simulation/strategic_ai_difficulty.gd")
const Budget = preload("res://src/simulation/strategic_ai_budget.gd")
const Tactics = preload("res://src/simulation/strategic_ai_tactics.gd")
const Opportunities = preload("res://src/simulation/strategic_ai_opportunities.gd")
const HeroMicro = preload("res://src/simulation/strategic_ai_hero_micro.gd")
const SkillMicro = preload("res://src/simulation/strategic_ai_skill_micro.gd")
const HeroItems = preload("res://src/simulation/strategic_hero_items.gd")
const LocalBattle = preload("res://src/simulation/strategic_ai_local_battle_m70.gd")
const GrowthM71 = preload("res://src/simulation/strategic_ai_growth_m71.gd")
const LocalNavigation = preload("res://src/simulation/strategic_navigation.gd")
const NeutralThreatM73 = preload("res://src/simulation/strategic_ai_neutral_threat_m73.gd")
const JourneyM73 = preload("res://src/simulation/strategic_ai_journey_m73.gd")
const EnemyValueM75 = preload("res://src/simulation/strategic_ai_enemy_value_m75.gd")
const LootM75 = preload("res://src/simulation/strategic_ai_loot_m75.gd")
const ThreatFrameM96 = preload("res://src/simulation/strategic_ai_threat_frame_m96.gd")
const Outposts = preload("res://src/simulation/strategic_ai_outposts.gd")
const DevelopmentR9 = preload("res://src/simulation/strategic_ai_development_r9.gd")
const VisibilityR9=preload("res://src/simulation/strategic_visibility_r9.gd")
const DECISION_TICKS := 40
const MAX_COMMANDS := 6
const MAX_OBSERVATIONS := 24
const WORKER_GOAL := 10
const PRESSURE_TICKS := 400
const PRESSURE_MIN_TROOPS := 4
const PRESSURE_MIN_HEALTH := 65
const ASSAULT_TICKS := 1400
const FORCED_ASSAULT_TICKS := 2200
const EXPLORATION_NEARBY_RADIUS := 900
const EXPLORATION_SCORE_BONUS := 120000
const ESSENCE_MIN_TROOPS := 8
const ESSENCE_MIN_HEALTH := 70
const ESSENCE_EARLIEST_TICKS := 1200
const ESSENCE_SCORE_BONUS := 2400000

var _seed := 1701
var _battle_start := -1
var _next_decision := -1
var _decisions := 0
var _accepted := 0
var _rejected := 0
var _status := "DORMANT"
var _expansion_site := ""
var _army_targets: Dictionary = {}
var _army_peaks: Dictionary = {}
var _regrouping: Dictionary = {}
var _observations: Array[Dictionary] = []
var _last_attempts := 0
var _assault_committed := false
var _siege_targets: Dictionary = {}
var _assessment: Dictionary = {}
var _last_hero_id := ""
var _last_reaction_hero_id := ""
var _pressure_army_id := ""
var _pressure_start_tick := -1
var _pressure_active := false
var _pressure_contact_tick := -1
var _pressure_finished := false
var _difficulty_id := Difficulty.DEFAULT_SIM_ID
var _policy: Dictionary = {}
var _planning_tick := 0
var _battle_elapsed := 0
var _last_recruit_tick := -1
var _last_hero_action_tick := -1
var _wave_army_id := ""
var _wave_start_tick := -1
var _wave_end_tick := -1
var _rest_until_tick := -1
var _wave_active := false
var _wave_count := 0
var _side_id := "AI"
var _faction_id := "HUMAN"
var _budget: RefCounted
var _tactics: RefCounted
var _next_reaction := -1
var _command_window_tick := -1
var _window_commands := 0
var _threat_locks: Dictionary = {}
var _dispatch_cursor := 0
var _last_macro_key := ""
var _pending_macro_keys: Dictionary = {}
var _resume_orders: Dictionary = {}
var _last_emergency_dispatch_tick:=-1
var _raid_targets: Dictionary = {}
var _strategic_diagnostics: Dictionary = {}
var _joint_capture: Dictionary = {}
var _joint_capture_cooldowns: Dictionary = {}
var _next_raid_tick := -1
var _hero_micro: RefCounted
var _local_battle_states: Dictionary = {}
var _local_battle_diagnostics: Dictionary = {}
var _local_battle_cache: Dictionary = {}
var _local_battle_cache_active := false
var _resolved_threat_orders: Array[Dictionary] = []
var _local_battle_work := {"queries":0,"cache_hits":0}
var _m95_force_frames: Array[Dictionary] = []
var _m95_force_frame_serial := 0
var _m94_threat_scope_active := false
var _m94_threat_cache: Array[Dictionary] = []
var _m96_threat_frames: Array[Dictionary] = []
var _m96_threat_work: Dictionary = {"prepares":0,"pair_checks":0}
var _economy_pending_since := -1
var _growth_targets: Dictionary = {}
var _growth_cooldowns: Dictionary = {}
var _military_pending_since: Dictionary = {}
var _route_journeys: Dictionary = {}
var _travel_releases: Dictionary = {}
var _loot_micro: RefCounted


func _init(seed: int = 1701, difficulty_id: String = Difficulty.DEFAULT_SIM_ID, side_id: String = "AI", faction_id: String = "HUMAN") -> void:
	assert(Difficulty.is_valid(difficulty_id), "Unsupported computer difficulty: " + difficulty_id)
	_difficulty_id = difficulty_id
	_side_id = side_id
	_faction_id = faction_id
	reset(seed)


func reset(seed: int = 1701) -> void:
	_m94_end_threat_scope()
	_seed = seed
	_battle_start = -1
	_next_decision = -1
	_decisions = 0
	_accepted = 0
	_rejected = 0
	_status = "DORMANT"
	_expansion_site = ""
	_army_targets.clear()
	_army_peaks.clear()
	_regrouping.clear()
	_observations.clear()
	_last_attempts = 0
	_assault_committed = false
	_siege_targets.clear()
	_assessment.clear()
	_last_hero_id = ""
	_last_reaction_hero_id = ""
	_pressure_army_id = ""
	_pressure_start_tick = -1
	_pressure_active = false
	_pressure_contact_tick = -1
	_pressure_finished = false
	_policy = Difficulty.get_profile(_difficulty_id)
	_planning_tick = 0
	_battle_elapsed = 0
	_last_recruit_tick = -1
	_last_hero_action_tick = -1
	_wave_army_id = ""
	_wave_start_tick = -1
	_wave_end_tick = -1
	_rest_until_tick = -1
	_wave_active = false
	_wave_count = 0
	_budget = Budget.new()
	_tactics = Tactics.new(seed,_side_id,_faction_id)
	_next_reaction = -1
	_command_window_tick = -1
	_window_commands = 0
	_threat_locks.clear()
	_dispatch_cursor = 0
	_last_macro_key = ""
	_pending_macro_keys.clear()
	_resume_orders.clear()
	_last_emergency_dispatch_tick=-1
	_raid_targets.clear()
	_strategic_diagnostics.clear()
	_joint_capture.clear()
	_joint_capture_cooldowns.clear()
	_next_raid_tick = -1
	_hero_micro = HeroMicro.new()
	_local_battle_states.clear()
	_local_battle_diagnostics.clear()
	_local_battle_cache.clear()
	_local_battle_cache_active=false
	_local_battle_work={"queries":0,"cache_hits":0}
	_economy_pending_since=-1
	_growth_targets.clear()
	_growth_cooldowns.clear()
	_military_pending_since.clear()
	_route_journeys.clear()
	_travel_releases.clear()
	_loot_micro=LootM75.new()


func configure_difficulty(id: String) -> bool:
	# The host owns preparation gating and command receipts. This guard also
	# prevents an accidental direct caller from rewriting a running planner.
	if not Difficulty.is_valid(id) or _battle_start >= 0:
		return false
	_difficulty_id = id
	reset(_seed)
	return true


func start_battle(tick: int) -> void:
	if _battle_start >= 0:
		return
	_battle_start = tick
	_next_decision = tick + int(_policy["decision_ticks"])
	_next_reaction = tick + int(_policy["reaction_ticks"])
	_status = "DEVELOPING"


func is_due(tick: int, phase: String) -> bool:
	# Exactly the public plan admission predicate, safe for the host to avoid
	# constructing observations on ticks where no AI may consume them.
	return phase == "BATTLE" and _battle_start >= 0 and (tick >= _next_decision or tick >= _next_reaction)


func plan(tick: int, phase: String, world: Dictionary, military: Dictionary, technology: Dictionary) -> Array[Dictionary]:
	# Reuse the proven bounded policy on a detached self/opponent perspective.
	# Entity IDs/positions/recipes stay REAL. Only this projection's side labels
	# normalize; the shared host executes receipts as _side_id, never as "AI".
	if not is_due(tick,phase):
		return []
	var view := _perspective(world)
	var forces := view if military == world else _perspective(military)
	var own_tech := {"AI": technology.get(_side_id, {}).duplicate(true)}
	return _plan_perspective(tick, phase, view, forces, own_tech)


func _perspective(facts: Dictionary) -> Dictionary:
	# Build exactly the old detached projection in caller key order, but do
	# not first copy values that this same function immediately discards: other
	# sides' private ledgers, filtered neutral roster rows and the replaced UI
	# building directory. Unknown fields remain fully detached, never borrowed.
	var view:Dictionary={}
	var ledgers:Array[String]=["economy","population","population_upkeep","technology","technology_queues","progression","hero_quotes"]
	var rosters:Array[String]=["buildings","workers","soldiers","warbands","armies"]
	var side_catalogs:Dictionary=facts.get("catalog",{}).get("buildings_by_side",{})
	for key:Variant in facts:
		if key in ledgers:
			view[key]={"AI":facts.get(key,{}).get(_side_id,{}).duplicate(true)}
		elif key in rosters:
			var rows:Array=facts[key].slice(0,0)
			for body:Dictionary in facts[key]:
				if not bool(body.get("neutral",false)) and body.get("side")!="NEUTRAL":rows.append(body.duplicate(true))
			view[key]=rows
		elif key=="micro_neutral_targets":view[key]=[] # Replaced below from actual soldiers, as before.
		elif key=="catalog":
			var catalog:Dictionary={}
			for field:Variant in facts[key]:catalog[field]=_m96_detach(side_catalogs[_side_id] if field=="buildings" and side_catalogs.has(_side_id) else facts[key][field])
			if side_catalogs.has(_side_id) and not catalog.has("buildings"):catalog["buildings"]=side_catalogs[_side_id].duplicate(true)
			view[key]=catalog
		else:view[key]=_m96_detach(facts[key])
	# Public snapshots keep PLAYER's default catalog for UI compatibility.
	# Select this exact controller's detached quote directory when present;
	# neither another side's prices nor mutations of caller facts may leak in.
	# Tactical self-preservation/casting may see nearby real neutral bodies,
	# without relabeling them as player troops or triggering strategic raids.
	view["micro_neutral_targets"] = facts.get("soldiers",[]).filter(func(body: Dictionary)->bool:return int(body.get("hp",0))>0 and (bool(body.get("neutral",false)) or body.get("side")=="NEUTRAL")).duplicate(true)
	view["planning_faction_id"] = _faction_id
	view["planning_view_side_r9"]=_side_id
	view["planning_spawn_direction"] = Vector2i(-1, 0)
	for side: Dictionary in facts.get("match_config", facts.get("match_settings", {})).get("sides", []):
		if str(side.get("side_id", "")) == _side_id:
			view["planning_spawn_direction"] = side.get("spawn_direction", Vector2i(-1, 0))
	for list_name: String in ["buildings", "workers", "soldiers", "warbands", "armies"]:
		# Neutrals guard a site but are never the human opponent or a planner
		# controlled roster. ATTACK_MOVE still acquires their real bodies.
		for body: Dictionary in view.get(list_name, []):
			body["side"] = "AI" if str(body.get("side", "")) == _side_id else "PLAYER"
			# A resolved attack's affiliation is immutable combat evidence. Map
			# it exactly like actor labels without turning NEUTRAL into an enemy
			# player or misclassifying another computer's worker in four-side play.
			var target_side := str(body.get("last_action_target_side", ""))
			if target_side not in ["", "NEUTRAL"]: body["last_action_target_side"] = "AI" if target_side == _side_id else "PLAYER"
	for site: Dictionary in view.get("sites", []):
		# Both the retained owner and the current capture claimant are side
		# labels. Leaving one absolute makes PLAYER/AI_2/AI_3's own complete
		# factory appear contested to the shared relative operational predicate.
		for field: String in ["owner","capture_side"]:
			if not site.has(field):continue
			var owner := str(site[field])
			if owner == _side_id:site[field] = "AI"
			elif owner not in ["", "NEUTRAL"]:site[field] = "PLAYER"
	for source: Dictionary in view.get("resource_sources", []):
		var owner := str(source.get("owner", ""))
		if owner == _side_id: source["owner"] = "AI"
		elif owner not in ["", "NEUTRAL"]: source["owner"] = "PLAYER"
	for slot: Dictionary in view.get("building_slots", []):
		var owner := str(slot.get("side", ""))
		if owner == _side_id: slot["side"] = "AI"
		elif owner not in ["", "NEUTRAL"]: slot["side"] = "PLAYER"
	for drop:Dictionary in view.get("neutral_loot",[]):
		var owner:=str(drop.get("owner",""))
		if owner==_side_id:drop["owner"]="AI"
		elif owner not in ["","NEUTRAL"]:drop["owner"]="PLAYER"
	# Discovery reservation is distinct from current territorial ownership.
	# Keep both detached labels relative to this exact controller, including
	# AI_2/AI_3; never mutate the host's shared first-claim ledger.
	for objective: Dictionary in view.get("field_objectives", []):
		for field: String in ["owner", "first_owner"]:
			if not objective.has(field): continue
			var owner := str(objective[field])
			if owner == _side_id: objective[field] = "AI"
			elif owner not in ["", "NEUTRAL"]: objective[field] = "PLAYER"
	for hero: Dictionary in view.get("heroes", {}).get("officers", []):
		hero["side"] = "AI" if str(hero.get("side", "")) == _side_id else "PLAYER"
	return view


static func _m96_detach(value:Variant)->Variant:
	return value.duplicate(true) if value is Dictionary or value is Array else value


func _plan_perspective(tick: int, phase: String, world: Dictionary, military: Dictionary, technology: Dictionary) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	if phase != "BATTLE" or _battle_start < 0 or (tick < _next_decision and tick < _next_reaction):
		return commands
	var macro_due := tick >= _next_decision
	var reaction_due := tick >= _next_reaction
	if macro_due:
		_next_decision = tick + int(_policy["decision_ticks"])
		_decisions += 1
	if reaction_due:_next_reaction = tick + int(_policy["reaction_ticks"])
	_last_attempts = 0
	_pending_macro_keys.clear()
	var elapsed := tick - _battle_start
	_planning_tick = tick
	_battle_elapsed = elapsed
	# Public plan accepts split world/combat observations as well as the merged
	# host snapshot. Both arguments here are already detached self perspectives.
	if not world.has("soldiers"):
		world["soldiers"] = military.get("soldiers",[])
		world["micro_neutral_targets"] = military.get("micro_neutral_targets",[])
	if not world.has("heroes"): world["heroes"] = military.get("heroes",{})
	if not world.has("neutral_camps"): world["neutral_camps"] = military.get("neutral_camps",[])
	if not world.has("neutral_loot"): world["neutral_loot"] = military.get("neutral_loot",[])
	world["technology"] = technology.duplicate(true)
	# Cache belongs to this exact detached observation, never merely its tick.
	# A new body/MP/tower observation at the same tick cannot reuse old risk.
	_local_battle_cache.clear()
	_local_battle_cache_active=true
	_local_battle_work={"queries":0,"cache_hits":0}
	_m94_begin_threat_scope()
	var armies := _armies(military)
	var hero_preservation: Dictionary = _hero_micro.plan(tick,world,military) if reaction_due else {}
	_tactics.consider(elapsed,_side_power(military,"AI"),_side_power(military,"PLAYER"),not _usable_essence_sites(world).is_empty())
	_policy.merge(_tactics.timing(),true)
	var targets := _military_actions(world, military, technology, elapsed, armies) if macro_due else _reaction_actions(world,military,armies)
	if macro_due:
		var waiting:={}
		for action:Dictionary in targets:
			if action.get("type") in ["ATTACK_MOVE","FOCUS","ATTACK_BASE","MOVE"]:
				var id:=str(action.get("subject_id",""));waiting[id]=true
				if not _military_pending_since.has(id):_military_pending_since[id]=tick
		for id:String in _military_pending_since.keys():
			if not waiting.has(id):_military_pending_since.erase(id)
	var development := _development_action(world, technology) if macro_due else {}
	var recruitment := _recruit_action(world, military, armies, development) if macro_due else {}
	var recruitments: Array[Dictionary] = []
	if not recruitment.is_empty():
		recruitments.append(recruitment)
		var real_target: Dictionary = _budget.target.duplicate(true)
		var real_cooldowns: Dictionary = _budget.cooldowns.duplicate(true)
		var forecast := world.duplicate(true)
		_shadow_recruit(forecast,recruitment)
		# Planning copies only reserve already quoted costs. Each real order is
		# still separately validated/debited by the host; at most3producers.
		for _slot: int in range(2):
			if recruitments[-1].get("unit_type") == "hero": break
			var next := _recruit_action(forecast,military,armies,development)
			if next.is_empty(): break
			recruitments.append(next)
			_shadow_recruit(forecast,next)
		# Previewing extra producer slots is not actual income or prerequisite
		# progress and must not acquire/renew/cancel the real intention lease.
		_budget.target = real_target
		_budget.cooldowns = real_cooldowns
	# Recruitment revalidates the one real savings lease this decision. Labour
	# reads it only after speculative extra-producer forecasts are discarded.
	var economic := _economic_action(world, development) if macro_due else {}
	if macro_due:
		if economic.is_empty():_economy_pending_since=-1
		elif _economy_pending_since<0:_economy_pending_since=tick
	var hero := _hero_action(military) if macro_due and (_last_hero_action_tick < 0 or tick - _last_hero_action_tick >= int(_policy["hero_action_ticks"])) else {}
	var loot:Dictionary=_loot_micro.plan(tick,world,military,_hero_micro.states) if macro_due else {}
	# Ready battlefield skills and owned recovery are reactions, not research /
	# inventory work. Keep their existing shared command ceiling and authority
	# costs; a two-second economy clock must not delay a one-second reaction.
	var hero_reaction := _hero_reaction(military) if reaction_due else {}
	# Never send an unaffordable development ticket every decision. The lease
	# can save for it, but host rejection is not a substitute for budgeting.
	if not development.is_empty() and (not _development_eligible(world,development) or not _can_pay(world,_development_cost(development,world))): development = {}
	_assessment = {"friendly_power": _side_power(military, "AI"), "enemy_power": _side_power(military, "PLAYER"), "worker_goal": _worker_goal(world), "military_goal":_policy["military_goal"], "military_live_plus_queued":_military_count(world,military), "assault_committed": _assault_committed, "pressure_eligible_after_ticks": _policy["pressure_ticks"], "pressure_min_troops": PRESSURE_MIN_TROOPS, "pressure_min_health_percent": PRESSURE_MIN_HEALTH}
	var candidates: Array[Dictionary] = []
	# A stream of newly replaced targets must not restart unlimited first-
	# response priority. A recently accepted defensive batch may share a due
	# macro slot with legal investment; independent reactions still answer
	# fresh threats. RETREAT never yields and total command limits stay fixed.
	var paid_work_ready:bool=not recruitment.is_empty() or not development.is_empty()
	var first_response_priority:bool=not macro_due or not paid_work_ready or _last_emergency_dispatch_tick<0 or tick-_last_emergency_dispatch_tick>=120
	var aged_idle:bool=_budget.stalled_since>=0 and _budget.stalled_decisions>=2 and tick-_budget.stalled_since>=120
	var funded_goal:bool=not _budget.target.is_empty() and int(_budget.target.get("deficit",1))==0 and tick-int(_budget.target.get("started_tick",tick))>=120
	var investment_due:bool=macro_due and paid_work_ready and (aged_idle or funded_goal)
	for action:Dictionary in targets:
		if action.get("type")=="RETREAT":candidates.append(action)
	# One endangered officer can disengage without withdrawing its healthy
	# companions. It consumes the existing side-wide command budget, never an
	# unmetered per-unit tick loop. Genuine whole-army retreat still leads.
	if not hero_preservation.is_empty():candidates.append(hero_preservation)
	# A legal labour/source adjustment must not wait behind a whole changing
	# army/recruitment round forever. Two due macro windows is a bounded service
	# lease, not extra commands or free workers; immediate retreats and genuine
	# officer preservation above still keep their ordinary precedence.
	if macro_due and not economic.is_empty() and economic not in candidates and _economy_pending_since>=0 and tick-_economy_pending_since>=int(_policy.decision_ticks)*2:
		candidates.append(economic)
	# Service an already worthwhile, authority-quoted order before another
	# complete roundtrip of refresh/labor/formation work. This spends no new
	# category of resources and never overrides an immediate retreat.
	# Growth that is safe but never dispatched is still inactivity. Give one
	# already-valid army journey bounded service after two macro windows, below
	# preservation and overdue real labour, with no extra command bandwidth.
	if macro_due:
		for action:Dictionary in targets:
			var id:=str(action.get("subject_id",""))
			if action not in candidates and _military_pending_since.has(id) and tick-int(_military_pending_since[id])>=int(_policy.decision_ticks)*2:
				candidates.append(action);break
	if investment_due:candidates.append(recruitment if not recruitment.is_empty() else development)
	# Emergency commands lead. Ordinary macro slots rotate, so a slow profile
	# is not permanently starved by an always-present labor adjustment.
	for action: Dictionary in targets:
		if action in candidates:continue
		var lock:Dictionary=_threat_locks.get(str(action.get("subject_id","")),{})
		# A new defensive handoff stays urgent until the host really accepts
		# that response. Refreshing an already engaged target is ordinary work;
		# two moving workers must not permanently consume both STANDARD slots.
		if first_response_priority and not bool(lock.get("response_applied",false)) and action==lock.get("response_order",{}):candidates.append(action)
	if macro_due and Outposts.enabled(world) and not economic.is_empty() and economic not in candidates and _can_pay(world,_order_cost(world,economic)):
		candidates.append(economic)
	if not hero_reaction.is_empty() and hero_reaction not in candidates:
		candidates.append(hero_reaction)
	var macro: Array[Dictionary] = []
	for action: Dictionary in [recruitment,economic,development,hero]:
		if not action.is_empty() and action not in candidates: macro.append(action)
	if not loot.is_empty() and loot not in candidates:macro.append(loot)
	for extra: Dictionary in recruitments.slice(1): macro.append(extra)
	for action: Dictionary in targets:
		if action not in candidates: macro.append(action)
	# Candidate lists gain/lose recruitment, skills and army work every turn.
	# Their array positions are not stable task identities. Keep the successor
	# in the canonical key space even when the previous task has disappeared.
	candidates.append_array(_ordered_macro_actions(macro,_last_macro_key))
	if _command_window_tick < 0 or tick-_command_window_tick >= 20:
		_command_window_tick = tick
		_window_commands = 0
	var available := mini(MAX_COMMANDS,int(_policy.commands_per_second)-_window_commands)
	var predicted_stock: Dictionary = world.economy.AI.stock.duplicate(true)
	var predicted_population: Dictionary = world.population.AI.duplicate(true)
	var last_macro_slot:=-1
	for action: Dictionary in candidates:
		if commands.size() >= available: break
		var cost := _order_cost(world,action)
		var allowed := true
		for resource: String in Economy.RESOURCE_KEYS:
			if int(predicted_stock.get(resource,0))<int(cost.get(resource,0)): allowed = false
		var population_cost := 0
		if action.get("type") == "ENQUEUE_UNIT":
			population_cost = int((_hero_quote(world,str(action.get("hero_archetype",""))) if action.get("unit_type") == "hero" else _recipe(str(action.unit_type))).get("population",0))
			if int(predicted_population.used)+int(predicted_population.reserved)+population_cost > int(predicted_population.maximum): allowed = false
		if not allowed: continue
		commands.append(action)
		if macro_due and (action in macro or action==economic or investment_due and action==(recruitment if not recruitment.is_empty() else development)):
			last_macro_slot=macro.find(action)
			_pending_macro_keys[JSON.stringify(action)]=_macro_task_key(action)
		for resource: String in Economy.RESOURCE_KEYS: predicted_stock[resource] = int(predicted_stock.get(resource,0))-int(cost.get(resource,0))
		predicted_population.reserved = int(predicted_population.reserved)+population_cost
	_window_commands += commands.size()
	# Legacy numeric cursor remains diagnostic only. The authoritative identity
	# advances in record_result after actual Host acceptance; reactions and
	# rejected/unserved proposals cannot move the ordinary-work ring.
	if last_macro_slot>=0:_dispatch_cursor=last_macro_slot+1
	if macro_due:
		var useful := not recruitment.is_empty() or not development.is_empty()
		_budget.observe(tick,useful,_budget_block(world,military))
	_hero_micro.selected_commands(commands)
	_local_battle_cache_active=false
	_m94_end_threat_scope()
	return commands


func record_result(tick: int, command: Dictionary, result: Dictionary, before: Dictionary, after: Dictionary) -> void:
	_hero_micro.record_result(tick,command,result)
	_loot_micro.record_result(tick,command,result)
	_last_attempts += 1
	var accepted := bool(result.get("accepted", false))
	var local_id:=str(command.get("subject_id",""))
	var rendezvous:Dictionary=_local_battle_states.get(local_id,{})
	if rendezvous.get("phase")=="RENDEZVOUS" and command.get("type")=="MOVE" and command.get("target_position")==rendezvous.get("point"):
		if accepted:
			if int(rendezvous.get("accepted_tick",-1))<0:rendezvous["accepted_tick"]=tick;rendezvous["until_tick"]=tick+240
		elif int(rendezvous.get("accepted_tick",-1))<0:
			var peer:=str(rendezvous.get("partner",""))
			_local_battle_states.erase(local_id)
			if int(_local_battle_states.get(peer,{}).get("accepted_tick",-1))<0:_local_battle_states.erase(peer)
	var macro_ticket := JSON.stringify(command)
	if _pending_macro_keys.has(macro_ticket):
		if accepted and tick==_planning_tick:_last_macro_key=str(_pending_macro_keys[macro_ticket])
		_pending_macro_keys.erase(macro_ticket)
	if accepted:
		_accepted += 1
		var travel:Dictionary=_route_journeys.get(str(command.get("subject_id","")),{})
		var accepted_leg:bool=not travel.is_empty() and command.get("type")=="ATTACK_MOVE" and command.get("target_position")==travel.get("pending_point")
		if accepted_leg and int(travel.get("accepted_tick",-1))<0:
			travel["accepted_tick"]=tick
			if int(travel.get("first_accepted_tick",-1))<0:
				travel["first_accepted_tick"]=tick
				travel["last_progress_tick"]=tick
				travel["body_progress_tick"]=tick
		var mission:Dictionary=_growth_targets.get(str(command.get("subject_id","")),{})
		if not mission.is_empty() and command.get("type")=="ATTACK_MOVE" and (command.get("target_position")==mission.get("point") or accepted_leg and travel.get("goal")==mission.get("point")) and int(mission.get("accepted_tick",-1))<0:
			mission["accepted_tick"]=tick
			mission["last_progress_tick"]=tick
		if command.get("type") in ["ATTACK_MOVE","FOCUS","ATTACK_BASE","MOVE","RETREAT","STOP"]:_military_pending_since.erase(str(command.get("subject_id","")))
		if command.get("type") in ["SET_ECONOMY_TARGETS","SET_WORK_SITE","SET_ESSENCE_SITE"]:_economy_pending_since=-1
		var subject := str(command.get("subject_id",""))
		if _resume_orders.get(subject,{}) == command: _resume_orders.erase(subject)
		if _threat_locks.has(subject) and _threat_locks[subject].get("response_order",{})==command:
			if not bool(_threat_locks[subject].get("response_applied",false)):_last_emergency_dispatch_tick=tick
			_threat_locks[subject]["response_applied"]=true
		var old_stock: Dictionary = before.get("economy",{}).get(_side_id,{}).get("stock",{})
		var new_stock: Dictionary = after.get("economy",{}).get(_side_id,{}).get("stock",{})
		for resource: String in Economy.RESOURCE_KEYS:
			if int(new_stock.get(resource,0)) < int(old_stock.get(resource,0)):
				_budget.paid(tick)
				var key := ""
				if command.get("type") == "ENQUEUE_UNIT": key = "hero:"+str(command.get("hero_archetype","")) if command.get("unit_type") == "hero" else "composition:"+str(command.get("unit_type",""))
				else: key = "development:"+_development_key(command)
				_budget.settled_target(key)
				break
		# Only the host's successful payment/skill receipt advances cooldowns.
		# Failed stock, population or outlet commands do not consume pacing.
		if command.get("type") == "ENQUEUE_UNIT": _last_recruit_tick = tick
		if command.get("type") in ["HERO_SKILL", "EQUIP_ITEM", "USE_POTION", "UPGRADE_HERO_SKILL"]: _last_hero_action_tick = tick
		# Advance spell attention only after a real accepted cast/consumption,
		# never for an unserved proposal or an empty officer's learning slot.
		if command.get("type") in ["HERO_SKILL", "USE_POTION"]:
			_last_reaction_hero_id = str(command.get("unit_id",""))
	else:
		_rejected += 1
	var observation := {
		"tick": tick, "decision": _decisions, "command": command.duplicate(true),
		"type": command.get("type", ""), "accepted": accepted,
		"error": str(result.get("error", "")), "result": result.duplicate(true),
		"side_id": _side_id, "faction_id": _faction_id,
		"stock_before": before.get("economy", {}).get(_side_id, {}).get("stock", {}).duplicate(true),
		"stock_after": after.get("economy", {}).get(_side_id, {}).get("stock", {}).duplicate(true),
		"population_before": before.get("population", {}).get(_side_id, {}).duplicate(true),
		"population_after": after.get("population", {}).get(_side_id, {}).duplicate(true),
	}
	_observations.append(observation)
	if _observations.size() > MAX_OBSERVATIONS:
		_observations.pop_front()


func get_state() -> Dictionary:
	var result := {"seed": _seed, "battle_start": _battle_start, "next_decision": _next_decision, "decisions": _decisions, "accepted": _accepted, "rejected": _rejected, "status": _status, "expansion_site": _expansion_site, "army_targets": _army_targets.duplicate(true), "army_peaks": _army_peaks.duplicate(true), "regrouping": _regrouping.duplicate(true), "observations": _observations.duplicate(true), "last_attempts": _last_attempts, "assault_committed": _assault_committed, "siege_targets": _siege_targets.duplicate(true), "assessment": _assessment.duplicate(true), "last_hero_id": _last_hero_id, "pressure_army_id": _pressure_army_id, "pressure_start_tick": _pressure_start_tick, "pressure_active": _pressure_active, "pressure_contact_tick": _pressure_contact_tick, "pressure_finished": _pressure_finished}
	result.merge(_policy_state())
	result["joint_capture_cooldowns"] = _joint_capture_cooldowns.duplicate(true)
	result["next_raid_tick"] = _next_raid_tick
	result["hero_micro"] = _hero_micro.get_state()
	result["loot_micro"] = _loot_micro.get_state()
	result["economy_pending_since"] = _economy_pending_since
	result["route_journeys"] = _route_journeys.duplicate(true)
	result["travel_releases"] = _travel_releases.duplicate(true)
	result.merge({"budget_state":_budget.get_state(),"tactic_state":_tactics.get_state(),"next_reaction":_next_reaction,"command_window_tick":_command_window_tick,"window_commands":_window_commands,"dispatch_cursor":_dispatch_cursor,"last_macro_key":_last_macro_key,"resume_orders":_resume_orders.duplicate(true),"last_emergency_dispatch_tick":_last_emergency_dispatch_tick,"last_reaction_hero_id":_last_reaction_hero_id})
	return result.duplicate(true)


func get_hero_withdrawals(tick: int) -> Dictionary:
	# Trusted Session scheduling consumes this read-only finite lease. It is
	# not an accepted client command field and never contains price/stat grants.
	return _hero_micro.withdrawal_leases(tick)


func get_snapshot(tick: int) -> Dictionary:
	var result := {"controller": "DETERMINISTIC_RULES", "status": _status, "battle_elapsed_ticks": maxi(0, tick - _battle_start) if _battle_start >= 0 else 0, "decision_interval_ticks": _policy["decision_ticks"], "max_commands_per_decision": MAX_COMMANDS, "decisions": _decisions, "accepted_commands": _accepted, "rejected_commands": _rejected, "last_attempts": _last_attempts, "expansion_site_id": _expansion_site, "army_targets": _army_targets.duplicate(true), "latest_attempts": _observations.duplicate(true), "assault_committed": _assault_committed, "siege_targets": _siege_targets.duplicate(true), "assessment": _assessment.duplicate(true), "pressure_army_id": _pressure_army_id, "pressure_start_tick": _pressure_start_tick, "pressure_active": _pressure_active, "pressure_target_base_id": str(_siege_targets.get(_pressure_army_id, "")), "pressure_contact_tick": _pressure_contact_tick, "pressure_finished": _pressure_finished}
	result.merge(_policy_state())
	result["economy_pending_since"] = _economy_pending_since
	result["route_journeys"] = _route_journeys.duplicate(true)
	result["travel_releases"] = _travel_releases.duplicate(true)
	return result.duplicate(true)


func _policy_state() -> Dictionary:
	return {"side_id":_side_id,"faction_id":_faction_id,"difficulty_id":_difficulty_id,"label":_policy["label"],"difficulty_label":_policy["label"],"policy":_policy.duplicate(true),"planning_tick":_planning_tick,"planning_elapsed_ticks":_battle_elapsed,"last_recruit_tick":_last_recruit_tick,"last_hero_action_tick":_last_hero_action_tick,"wave_army_id":_wave_army_id,"wave_start_tick":_wave_start_tick,"wave_end_tick":_wave_end_tick,"rest_until_tick":_rest_until_tick,"wave_active":_wave_active,"wave_count":_wave_count,"tactic_id":_tactics.id,"tactic_pivots":_tactics.pivots,"budget":_budget.diagnostic.duplicate(true),"threat_locks":_threat_locks.duplicate(true),"raid_targets":_raid_targets.duplicate(true),"joint_capture":_joint_capture.duplicate(true),"growth_targets":_growth_targets.duplicate(true),"growth_cooldowns":_growth_cooldowns.duplicate(true),"strategic_diagnostics":_strategic_diagnostics.duplicate(true),"local_battle":_local_battle_diagnostics.duplicate(true),"local_battle_states":_local_battle_states.duplicate(true),"local_battle_work":_local_battle_work.duplicate(true)}


func _economic_action(world: Dictionary, development: Dictionary = {}) -> Dictionary:
	if Outposts.enabled(world):
		_strategic_diagnostics["economy"] = Outposts.income_summary(world)
		return Outposts.income_action(world)
	var own: Dictionary = world["economy"]["AI"]
	var targets: Dictionary = own["targets"]
	var workers := _worker_count(world)
	var has_work: bool = false
	for building: Dictionary in _blueprints(world):
		# An unpaid placement is not a job. Captured integrated scaffolds can
		# likewise wait for ownership; the real World builder applies this gate.
		if building.get("building_type") == "SITE_TOWER" and not world.get("sites",[]).any(func(site:Dictionary)->bool:return site.get("id")==building.get("site_id") and site.get("owner")=="AI" and int(site.get("progress",0))>0): continue
		has_work = true
		break
	var builders := (2 if workers >= 8 else 1) if has_work else 0
	var stock: Dictionary = own["stock"]
	var food_available := Opportunities.available_source(world, "FOOD") > 0
	var ore_available := Opportunities.available_source(world, "MATERIAL") > 0
	var material := maxi(2, int(workers * 3 / 10))
	# Public inventory gaps change the desired labour mix; every adjustment is
	# still an ordinary +/-1 job command, and an empty work list releases labour.
	if int(stock["FOOD"]) > int(stock["MATERIAL"]) * 2 + 12:
		material = mini(5, int(workers / 2))
	elif int(stock["MATERIAL"]) > int(stock["FOOD"]) * 2 + 12:
		material = 2
	# Sequential tiers add a larger real ore commitment. Do not dismantle its
	# miner allocation merely because food is no longer > twice current ore.
	var commitment := _economic_commitment(world,development)
	var ranged := _recipe(_role_type(world,"RANGED"))
	var frontline := _recipe(_role_type(world,"FRONTLINE"))
	var ranged_material := int(ranged.get("cost",{}).get("MATERIAL",0)) if int(ranged.get("required_base_tier",1))<=_base_tier(world) else 0
	var material_buffer := maxi(100,2*ranged_material)
	var material_reserve := int(commitment.get("MATERIAL",0))+material_buffer
	var food_need := maxi(int(commitment.get("FOOD",0)),int(frontline.get("cost",{}).get("FOOD",0)))
	if int(stock["MATERIAL"]) < int(commitment.get("MATERIAL",0)):
		material = maxi(material, mini(6, int(workers / 2)))
	elif food_available and int(stock["FOOD"]) < food_need and int(stock["MATERIAL"]) >= material_reserve:
		# A covered quoted commitment plus finite replacement buffer is not an
		# excuse to mine forever while its FOOD payment cannot be made. All
		# moves still use the ordinary +/-1 host labour command below.
		material = 0 if int(stock["MATERIAL"]) >= 2*material_reserve else 1
	material = mini(material, maxi(0, workers - builders - 2))
	if not _has_mine(world) or not ore_available:
		material = 0
	if not food_available and ore_available: material = maxi(0, workers - builders)
	var essence_sites := _usable_essence_sites(world)
	# A completed, still-owned finite mine earns at most three actual workers.
	# Keep two food workers and ordinary ore/building labour before assigning it.
	var essence := mini(essence_sites.size() * Economy.ESSENCE_WORKER_CAP, maxi(0, workers - builders - material - (2 if food_available else 0)))
	if not essence_sites.is_empty():
		var selected := str(own.get("essence_site_id", ""))
		if not essence_sites.any(func(site: Dictionary) -> bool: return str(site.id) == selected):
			return {"type":"SET_ESSENCE_SITE", "site_id":essence_sites[0].id}
	var desired := {"FOOD": maxi(0, workers - builders - material - essence) if food_available else 0, "MATERIAL": material, "ESSENCE":essence, "CONSTRUCTION_REPAIR": mini(builders, workers)}
	# A role target is not admission to an unlimited source. Capacity counts
	# the entire round trip, as in World's worker slot authority. Overflow stays
	# reserve instead of permanently commanding nonexistent collection slots.
	for role:String in ["FOOD","MATERIAL","ESSENCE"]:desired[role]=mini(int(desired[role]),GrowthM71.resource_slots(world,role))
	_strategic_diagnostics["economy"] = {"food_available":food_available,"material_available":ore_available,"desired_workers":desired.duplicate(true),"expansion_urgent":_resource_urgent(world),"quoted_commitment":commitment.duplicate(true),"material_replacement_buffer":material_buffer,"material_reserve":material_reserve,"food_need":food_need,"has_committed_construction":has_work}
	# A single authoritative +/-1 transfer per decision avoids direct target
	# assignment. Builder priority keeps an expansion from starving behind food.
	var role_order:Array[String]=["CONSTRUCTION_REPAIR", "ESSENCE", "MATERIAL", "FOOD"]
	if ore_available and int(targets.get("MATERIAL",0))==0 and int(desired.MATERIAL)>0 and int(stock.get("MATERIAL",0))<material_buffer:role_order=["MATERIAL","CONSTRUCTION_REPAIR","ESSENCE","FOOD"]
	for role: String in role_order:
		if int(targets.get(role,0)) >= int(desired[role]):
			continue
		var changes: Array = [{"role": role, "delta": 1}]
		if int(targets["RESERVE"]) <= 0:
			for source: String in ["CONSTRUCTION_REPAIR", "ESSENCE", "MATERIAL", "FOOD"]:
				if source != role and int(targets.get(source,0)) > int(desired[source]):
					changes.append({"role": source, "delta": -1})
					break
			if changes.size() == 1:
				continue
		return {"type": "SET_ECONOMY_TARGETS", "changes": changes}
	for role: String in ["CONSTRUCTION_REPAIR", "ESSENCE", "MATERIAL", "FOOD"]:
		if int(targets.get(role,0)) > int(desired[role]):
			return {"type": "SET_ECONOMY_TARGETS", "changes": [{"role": role, "delta": -1}]}
	# Mining switches only after actual ownership AND completed base admission.
	if not _expansion_site.is_empty() and str(own.get("work_site_id", "")) != _expansion_site:
		for site: Dictionary in world["sites"]:
			if site["id"] == _expansion_site and _site_has_base(world, site) and _source_remaining(world, str(site["id"]), "MATERIAL") > 0:
				return {"type": "SET_WORK_SITE", "site_id": site["id"]}
	return {}


static func _macro_task_key(action: Dictionary) -> String:
	match str(action.get("type","")):
		"ENQUEUE_UNIT":return "0:recruit:"+str(action.get("building_id",""))
		"SET_ECONOMY_TARGETS","SET_ESSENCE_SITE","SET_WORK_SITE":return "1:economy"
		"PLACE_BUILDING","UPGRADE","UPGRADE_BASE","UPGRADE_TOWER":return "2:development"
		"HERO_SKILL","USE_POTION","UPGRADE_HERO_SKILL","EQUIP_ITEM","BUY_ITEM":return "3:hero:"+str(action.get("unit_id",""))
		"UNIT_MOVE","PICKUP_LOOT":return "3:loot:"+str(action.get("unit_id",""))
		"TRANSFER_UNITS":return "3:rejoin:"+str(action.get("unit_ids",[]))
		_:return "4:military:"+str(action.get("subject_id",""))


static func _ordered_macro_actions(actions: Array[Dictionary], last_key: String) -> Array[Dictionary]:
	var ordered := actions.duplicate()
	ordered.sort_custom(func(left:Dictionary,right:Dictionary)->bool:return _macro_task_key(left)<_macro_task_key(right))
	var result: Array[Dictionary]=[]
	if ordered.is_empty():return result
	var pivot:=0
	while pivot<ordered.size() and _macro_task_key(ordered[pivot])<=last_key:pivot+=1
	if pivot==ordered.size():pivot=0
	for offset:int in range(ordered.size()):result.append(ordered[(pivot+offset)%ordered.size()])
	return result


func _economic_commitment(world: Dictionary, development: Dictionary) -> Dictionary:
	# This is a read-only projection of the existing authority-quoted lease,
	# not a second bank or another reservation. update() has just discarded
	# stale/unavailable intentions; an expired lease never drives labour.
	if not _budget.target.is_empty() and _planning_tick<int(_budget.target.get("expires_tick",-1)):
		return _budget.target.get("cost",{}).duplicate(true)
	if not development.is_empty() and _development_eligible(world,development):
		var key := "development:"+_development_key(development)
		if _planning_tick>=int(_budget.cooldowns.get(key,-1)):
			return _development_cost(development,world)
	return {}


func _development_action(world: Dictionary, technology: Dictionary) -> Dictionary:
	# Do not add a long queue of unaffordable/travel-starved blueprints. The real
	# world builds one blueprint at a time and this controller honours that order.
	if not Outposts.enabled(world) and not _paid_blueprints(world).is_empty():
		return {}
	# Productive, safe territory gets serviced before optional technology or a
	# fourth production line. The normal budget lease still owns its exact cost.
	var expansion := _expansion_development(world)
	if not expansion.is_empty() and (Outposts.enabled(world) or _resource_urgent(world) or _tactics.id == "EXPANSION_BOOM" or _building_count(world, "BASE") < 2): return expansion
	if Outposts.enabled(world):
		var native := DevelopmentR9.infrastructure_action(world,_battle_elapsed,DevelopmentR9.profile(world,world))
		if not native.is_empty() and not _base_recently_attacked(world):return native
	# Capture creates a free defense scaffold. It must not block paying for
	# the very BASE that makes this resource productive; World already gives
	# that paid base construction priority. Other paid work still waits.
	if not Outposts.enabled(world) and not _blueprints(world).is_empty():return {}
	if Outposts.enabled(world) and _building_of_type(world, "BARRACKS").is_empty():
		var replacement_home := _own_base(world)
		if not replacement_home.is_empty():
			var replacement := _placement(world, "BARRACKS", replacement_home.position)
			if not replacement.is_empty(): return replacement
	var capacity := _capacity_building(world)
	if not capacity.is_empty(): return capacity
	var doctrine_home := _own_base(world)
	if not doctrine_home.is_empty() and _basic_count(world,world)>=4:
		if _tactics.id == "TECH_TIMING" and _base_tier(world)<2:
			var upgrade := _base_upgrade_request(world,2)
			if not upgrade.is_empty(): return upgrade
		if _tactics.id == "DEFENSIVE_COUNTER" and _building_count(world,"TOWER")<1 and (Outposts.enabled(world) or _base_tier(world)>=int(Progression.BUILDING_TIERS.TOWER)):
			return _placement(world,"TOWER",doctrine_home.position)
	var heavy_type := _role_type(world, "HEAVY")
	var support_type := _role_type(world, "SUPPORT")
	var initial_infrastructure_done := _building_count(world, "TOWER", true) > 0 and _building_count(world, "ALTAR", true) > 0 and _living_type(world,"hero") >= 2 and _living_type(world,heavy_type) > 0 and _living_type(world,support_type) > 0
	for site: Dictionary in world["sites"]:
		if not Outposts.enabled(world) and site["kind"] == "RESOURCE" and site.get("resource", "") != "ESSENCE" and site["owner"] == "AI" and not _site_has_any_base(world, site) and (_building_count(world, "BASE") < 2 or initial_infrastructure_done) and (int(_policy["max_bases"]) == 0 or _building_count(world,"BASE") < int(_policy["max_bases"])):
			_expansion_site = str(site["id"])
			return _placement(world, "BASE", site["position"])
	var home := _own_base(world)
	if home.is_empty():
		return {}
	# Earned central territory is serviced by its own mine, never a normal BASE.
	if _base_tier(world) >= int(Progression.BUILDING_TIERS.ESSENCE_MINE):
		for site: Dictionary in world["sites"]:
			if site.get("resource", "") != "ESSENCE" or site.get("owner", "") != "AI" or int(site.get("progress",0)) < int(site.get("threshold",World.CAPTURE_THRESHOLD)): continue
			if _source_remaining(world,str(site.id),"ESSENCE") <= 0 or _site_has_essence_mine(world,site,false): continue
			var mine_order := _placement(world,"ESSENCE_MINE",site.position)
			if not mine_order.is_empty(): return mine_order
	# Once the first extra slot has really unlocked and its altar is usable,
	# finish that declared military investment before another optional spending
	# chain. Otherwise foundry→research→Tier3 can reserve ore indefinitely and
	# suppress all paid reinforcements throughout the first-minute pressure.
	var ready_altar := _available_altar(world)
	var missing_hero := _missing_hero_type(world, world, _hero_recruit_priority(world, world))
	var hero_quote := _hero_quote(world, missing_hero)
	if _hero_saving_eligible(world,world,hero_quote,ready_altar) and ready_altar["queue"].is_empty() and (hero_quote.get("mode") == "REVIVE" or int(hero_quote.get("hero_slot", 0)) == 2):
		return {}
	# A usable, unlocked native heavy/support recipe is an earned composition
	# investment. Optional tiers, specialty, extra towers and a third officer
	# must not repeatedly reserve its first normal payment out of the same ore.
	if not _first_composition_type(world).is_empty():
		return {}
	for kind: String in ["RANGE", "FOUNDRY"]:
		if _building_of_type(world, kind).is_empty():
			if _base_tier(world) < int(Progression.BUILDING_TIERS[kind]):
				var upgrade := _base_upgrade_request(world, int(Progression.BUILDING_TIERS[kind]))
				if not upgrade.is_empty(): return upgrade
				# A paid timed BASE upgrade need not idle all construction. The
				# Tier1 altar can be built in parallel; its extra slot still waits
				# for actual Tier2 completion before any hero reservation.
				if _battle_elapsed >= int(_policy["hero_ticks"]) and _building_of_type(world,"ALTAR").is_empty(): return _placement(world,"ALTAR",home["position"])
				return {}
			return _placement(world, kind, home["position"])
	var foundry := _building_of_type(world, "FOUNDRY", true)
	var levels: Dictionary = technology.get("AI", {})
	var research_busy: bool = not world.get("technology_queues",{}).get("AI",[]).is_empty()
	# Previously paid queues/technology survive a lost highest-tier base, but a
	# surviving foundry is not authority for new requests below its Tier2 gate.
	if not foundry.is_empty() and _base_tier(world) < int(Progression.BUILDING_TIERS["FOUNDRY"]):
		return _base_upgrade_request(world, int(Progression.BUILDING_TIERS["FOUNDRY"]))
	if not foundry.is_empty() and not research_busy and _battle_elapsed >= int(_policy["technology_ticks"]):
		for kind: String in ["ATTACK", "ARMOR"]:
			if int(levels.get(kind, 0)) < 1 and _base_tier(world) >= 1 and _base_tier(world) >= int(Progression.BUILDING_TIERS["FOUNDRY"]):
				return {"type": "UPGRADE", "technology": kind, "building_id": foundry["id"]}
	# The first support role and third earned hero slot are real Tier3 content.
	# EASY retains its existing two-minute technology delay, not an early rush.
	if not foundry.is_empty() and _base_tier(world) < 3 and _battle_elapsed >= int(_policy["technology_ticks"]) and int(levels.get("ATTACK", 0)) >= 1 and int(levels.get("ARMOR", 0)) >= 1:
		var next_tier := _base_upgrade_request(world, 3)
		if not next_tier.is_empty(): return next_tier
	# A real altar enables the complementary second officer while the standard
	# build-up is still happening, not only after the starting hero dies.
	if _battle_elapsed >= int(_policy["hero_ticks"]) and _building_of_type(world, "ALTAR").is_empty():
		return _placement(world, "ALTAR", home["position"])
	# Actual exclusive producers, not a human heavy unit painted differently.
	var heavy_recipe := _recipe(heavy_type)
	var heavy_producer := str(heavy_recipe.get("building_type", "BARRACKS"))
	if heavy_producer == "DRAGON_ROOST" and _building_of_type(world, heavy_producer).is_empty():
		if _base_tier(world) >= int(heavy_recipe.get("required_base_tier", 1)):
			return _placement(world, heavy_producer, home["position"])
	if _base_tier(world)>=3 and _building_of_type(world,"DRAGON_ROOST").is_empty():
		return _placement(world,"DRAGON_ROOST",home.position)
	if not foundry.is_empty() and _battle_elapsed >= int(_policy["technology_ticks"]) and int(levels.get("ATTACK",0))>0 and int(levels.get("ARMOR",0))>0 and not research_busy:
		for unique:Dictionary in preload("res://src/simulation/strategic_faction_technologies_v4.gd").list_for(_faction(world)):
			if int(levels.get(unique.id,0))==0 and _base_tier(world)>=int(unique.required_base_tier):return {"type":"UPGRADE","technology":unique.id,"building_id":foundry.id}
	var base_count := _building_count(world, "BASE")
	if _building_count(world, "TOWER") < mini(2, base_count):
		if not Outposts.enabled(world) and _base_tier(world) < int(Progression.BUILDING_TIERS["TOWER"]): return _base_upgrade_request(world, int(Progression.BUILDING_TIERS["TOWER"]))
		var frontier := home
		for site: Dictionary in world["sites"]:
			if site["id"] == _expansion_site and _site_has_base(world, site):
				for building: Dictionary in world["buildings"]:
					if building["side"] == "AI" and building["building_type"] == "BASE" and int(building["hp"]) > 0 and (Vector2i(building["position"]) - Vector2i(site["position"])).length_squared() <= World.BASE_SITE_RADIUS * World.BASE_SITE_RADIUS:
						frontier = building
		return _placement(world, "TOWER", Vector2i(frontier["position"]) + Vector2i(-110, 0))
	if not foundry.is_empty() and not research_busy and _battle_elapsed >= int(_policy["technology_ticks"]) and int(world["economy"]["AI"]["stock"]["MATERIAL"]) >= 45:
		for kind: String in ["ATTACK", "ARMOR"]:
			if int(levels.get(kind, 0)) < mini(int(_policy["technology_max"]), _base_tier(world)):
				return {"type": "UPGRADE", "technology": kind, "building_id": foundry["id"]}
	if _base_tier(world) >= 3 and _battle_elapsed >= maxi(ESSENCE_EARLIEST_TICKS,int(_policy["technology_ticks"])) and _can_pay(world,_development_cost({"type":"UPGRADE_TOWER"},world)):
		for tower: Dictionary in world["buildings"]:
			if tower.get("side") == "AI" and tower.get("building_type") == "TOWER" and bool(tower.get("complete",false)) and int(tower.get("hp",0)) > 0 and int(tower.get("tower_level",1)) < 2 and tower.get("tower_upgrade",{}).is_empty():
				return {"type":"UPGRADE_TOWER", "building_id":tower.id}
	return {}


func _recruit_action(world: Dictionary, military: Dictionary, armies: Array[Dictionary], development: Dictionary) -> Dictionary:
	if _last_recruit_tick >= 0 and _planning_tick - _last_recruit_tick < int(_policy["recruit_ticks"]): return {}
	var development_profile := DevelopmentR9.profile(world,military) if Outposts.enabled(world) else {}
	var altar := _available_altar(world)
	var missing_hero := _missing_hero_type(world, military, _hero_recruit_priority(world, military))
	var candidate_quote := _hero_quote(world,missing_hero)
	var hero_pending := _hero_saving_eligible(world,military,candidate_quote,altar)
	var first_composition := _first_composition_type(world)
	var candidate := {}
	if hero_pending:
		candidate = {"key":"hero:"+missing_hero,"purpose":"REVIVE" if candidate_quote.get("mode") == "REVIVE" else "RECRUIT_HERO","cost":candidate_quote.cost.duplicate(true),"quote":candidate_quote.duplicate(true)}
	elif not first_composition.is_empty():
		candidate = {"key":"composition:"+first_composition,"purpose":"COMPOSITION","cost":_recipe(first_composition).cost.duplicate(true)}
	elif not development.is_empty() and _development_eligible(world,development):
		# A moving worker may change the currently free placement coordinate;
		# that is the SAME build goal, not progress or a fresh30second lease.
		var development_key := _development_key(development)
		candidate = {"key":"development:"+development_key,"purpose":"DEVELOPMENT","cost":_development_cost(development,world),"quote_command":development.duplicate(true)}
	var reserve: Dictionary = _budget.update(_planning_tick,candidate,world.economy.AI.stock,JSON.stringify(world.economy.AI.get("delivered",{})))
	var emergency: bool = candidate_quote.get("mode") != "REVIVE" and ((DevelopmentR9.emergency_rebuild(development_profile) if Outposts.enabled(world) else _basic_count(world,military)<4) or _base_recently_attacked(world))
	if emergency:
		_budget.update(_planning_tick,{},world.economy.AI.stock,"")
		reserve = {}
		for type: String in Factions.basic_units_for(_faction(world)):
			if not _can_recruit(world,type,{}): continue
			for producer: Dictionary in _producers(world,str(_recipe(type).building_type)):
				if producer.queue.is_empty(): return {"type":"ENQUEUE_UNIT","building_id":producer.id,"unit_type":type,"warband_id":_recipient_for(world,military,armies,type == _role_type(world,"RANGED"))}
	var support_type := _role_type(world, "SUPPORT")
	var heavy_type := _role_type(world, "HEAVY")
	var ranged_type := _role_type(world, "RANGED")
	var frontline_type := _role_type(world, "FRONTLINE")
	# A third new officer is optional during a frontline collapse. Rebuild at
	# least four basic fighters first rather than freezing every reinforcement
	# behind its large price. A fallen owned officer is never this luxury gate.
	if not first_composition.is_empty():
		var own_reserve := {} if str(_budget.target.get("key","")) == "composition:"+first_composition else reserve
		if _can_recruit(world,first_composition,own_reserve):
			for producer: Dictionary in _producers(world,str(_recipe(first_composition)["building_type"])):
				if producer["queue"].is_empty():
					return {"type":"ENQUEUE_UNIT","building_id":producer["id"],"unit_type":first_composition,"warband_id":_recipient_for(world,military,armies,first_composition == support_type)}
		if str(_budget.target.get("key","")) == "composition:"+first_composition: return {}
	var support_producer := _building_of_type(world, str(_recipe(support_type)["building_type"]), true)
	var support_pending: bool = _base_tier(world) >= int(_recipe(support_type).get("required_base_tier", 3)) and not support_producer.is_empty() and support_producer["queue"].is_empty() and _living_type(military,support_type) + _queued_type(world,support_type) == 0
	var worker_goal: int = int(_policy["worker_goal"]) if hero_pending or support_pending else _worker_goal(world)
	if not Outposts.enabled(world) and _worker_count(world) + _queued_type(world, "worker") < worker_goal and _can_recruit(world, "worker", reserve):
		for base: Dictionary in _producers(world, "BASE"):
			if development.get("type") == "UPGRADE_BASE" and development.get("building_id") == base["id"]: continue
			if base["queue"].is_empty():
				return {"type": "ENQUEUE_UNIT", "building_id": base["id"], "unit_type": "worker", "warband_id": ""}
	var military_capped: bool = int(_policy["military_goal"]) > 0 and _military_count(world,military) >= int(_policy["military_goal"])
	# The first actual healer is a critical composition gap, not an optional
	# luxury that cheaper guards can starve forever. Save its exact normal price
	# before optional expansion labour/extra officers, then let normal queue time
	# and physical outlet settlement create the support body.
	var hero_reserve := {} if str(_budget.target.get("key","")) == "hero:"+missing_hero else reserve
	if hero_pending and _can_recruit_hero(world, missing_hero, hero_reserve):
		return {"type": "ENQUEUE_UNIT", "building_id": altar["id"], "unit_type": "hero", "hero_archetype": missing_hero, "warband_id": _recipient_for(world, military, armies, _hero_is_ranged(missing_hero))}
	# Saving for a declared eligible officer is real budgeting, not repeatedly
	# spending the last ore on cheaper soldiers until the match ends hero-less.
	if military_capped: return {}
	var total := maxi(10, _living_type(military, frontline_type) + _living_type(military, ranged_type) + _living_type(military, heavy_type) + _living_type(military, support_type) + 1)
	var enemy_ranged := 0
	var enemy_count := 0
	for unit: Dictionary in military["soldiers"]:
		if unit["side"] == "PLAYER" and bool(unit["alive"]):
			enemy_count += 1
			if int(unit.get("attack_range", 0)) >= 100: enemy_ranged += 1
	var desired := {support_type: mini(3, maxi(1, int(ceil(total / 9.0)))), heavy_type: maxi(2, int(ceil(total * (0.25 if enemy_ranged * 2 >= enemy_count and enemy_count > 0 else 0.15)))), ranged_type: maxi(3, int(ceil(total * 0.30))), frontline_type: maxi(4, int(ceil(total * 0.45)))}
	var candidates: Array[String] = [support_type, heavy_type, ranged_type, frontline_type]
	for cavalry: String in Factions.units_for(_faction(world), "CAVALRY"):
		if cavalry not in candidates:
			candidates.append(cavalry)
			desired[cavalry] = 2
	for siege: String in Factions.units_for(_faction(world),"SIEGE"):
		if siege not in candidates:
			candidates.append(siege)
			desired[siege] = 2 if _tactics.id == "SIEGE_PUSH" else 1
	# Scarce T3 troops compete for earned resources but are never a mandatory
	# first composition reservation; no essence means the ordinary roster wins.
	if _base_tier(world) >= 3 and _battle_elapsed >= ESSENCE_EARLIEST_TICKS:
		for type: String in Factions.units_for(_faction(world)):
			if not str(_recipe(type).get("balance_role", "")).begins_with("ESSENCE_"): continue
			candidates.append(type)
			desired[type] = 1
	# V3 composition is a population budget over the entire native roster,
	# not one mirror unit per role. Capability deficits precede preferences.
	candidates.clear()
	var own_pop:=0
	var frontline_pop:=0
	var damage_pop:=0
	var anti_air_pop:=0
	var support_pop:=0
	var enemy_air:=false
	for body: Dictionary in military.get("soldiers",[]):
		if not bool(body.get("alive",int(body.get("hp",0))>0)):continue
		if body.side!="AI":
			if body.get("movement_layer","")=="AIR":enemy_air=true
			continue
		if body.get("unit_type")=="hero":continue
		var pop:=int(_recipe(str(body.unit_type)).get("population",body.get("population",1)))
		own_pop+=pop
		if "ANCHOR" in body.get("role_capabilities",[]):frontline_pop+=pop
		if "DAMAGE" in body.get("role_capabilities",[]):damage_pop+=pop
		if "AIR" in body.get("attack_layers",[]):anti_air_pop+=pop
		if int(body.get("heal",0))>0:support_pop+=pop
	for type: String in Factions.units_for(_faction(world)):
		var recipe:=_recipe(type)
		if recipe.is_empty() or _base_tier(world)<int(recipe.get("required_base_tier",1)):continue
		var stats:=Units.stats_for(type)
		if "GROUND" not in stats.get("attack_layers",[]) and not enemy_air:continue
		candidates.append(type)
		var weight:=.42 if type==Factions.main_unit_for(_faction(world)) else .18 if "ANCHOR" in stats.get("role_capabilities",[]) else .25 if "DAMAGE" in stats.get("role_capabilities",[]) else .10
		if recipe.get("production_family","")=="SPECIAL":weight=.25
		if int(stats.get("heal",0))>0:weight=.12
		desired[type]=maxi(int(recipe.population),roundi(float(maxi(20,own_pop))*weight))
	var best := {}
	var score := -INF
	for type: String in candidates:
		if not _can_recruit(world, type, reserve): continue
		var unit_pop:=int(_recipe(type).population)
		var deficit := float(int(desired[type])-unit_pop*(_living_type(military,type)+_queued_type(world,type)))/float(desired[type])
		var stats:=Units.stats_for(type)
		if enemy_air and anti_air_pop<maxi(4,own_pop/4) and "AIR" in stats.get("attack_layers",[]):deficit+=2.0
		if frontline_pop<maxi(4,own_pop/3) and "ANCHOR" in stats.get("role_capabilities",[]):deficit+=1.5
		if damage_pop<maxi(4,own_pop/3) and "DAMAGE" in stats.get("role_capabilities",[]):deficit+=1.5
		if support_pop==0 and int(stats.get("heal",0))>0 and own_pop>=16:deficit+=1.0
		deficit *= _tactics.role_weight(str(Units.UNITS.get(type,{}).get("balance_role",Units.UNITS.get(type,{}).get("role",""))))
		if Outposts.enabled(world):deficit+=DevelopmentR9.procurement_bonus(development_profile,_recipe(type),stats,_battle_elapsed,int(world.economy.AI.stock.MATERIAL))
		for producer: Dictionary in _producers(world, str(_recipe(type)["building_type"])):
			if not producer["queue"].is_empty(): continue
			if deficit > score:
				score = deficit
				best = {"type": "ENQUEUE_UNIT", "building_id": producer["id"], "unit_type": type, "warband_id": _recipient_for(world, military, armies, int(stats.get("attack_range",0))>=100)}
	return best


func _first_composition_type(world: Dictionary) -> String:
	# V4 specialists are not mandatory HEAVY upgrades. The canonical role
	# deficits choose native legal producers, not a fixed technology tier.
	if Outposts.enabled(world):return ""
	# A world-only diagnostic projection cannot prove that a paid body is
	# missing. Public plan supplies its separate combat facts before this check.
	if not world.has("soldiers"): return ""
	if int(_policy["military_goal"]) > 0 and _military_count(world,world) >= int(_policy["military_goal"]): return ""
	# Keep the existing second-officer investment ahead of optional composition
	# once its earned slot and altar are ready, but not the third officer.
	var altar := _available_altar(world)
	var missing_hero := _missing_hero_type(world,world,_hero_recruit_priority(world,world))
	var hero_quote := _hero_quote(world,missing_hero)
	if _hero_saving_eligible(world,world,hero_quote,altar) and altar["queue"].is_empty() and (hero_quote.get("mode") == "REVIVE" or int(hero_quote.get("hero_slot",0)) == 2): return ""
	for role: String in ["HEAVY","SUPPORT"]:
		var type := _role_type(world,role)
		var recipe := _recipe(type)
		if recipe.is_empty() or _base_tier(world) < int(recipe.get("required_base_tier",1)) or _living_type(world,type) + _queued_type(world,type) > 0: continue
		var prerequisites_ready:=true
		for kind: String in recipe.get("required_buildings",[]):
			if _building_of_type(world,kind,true).is_empty():prerequisites_ready=false
		if not prerequisites_ready:continue
		var population: Dictionary = world.get("population",{}).get("AI",{})
		if not population.is_empty() and int(population["used"]) + int(population["reserved"]) + int(recipe["population"]) > int(population["maximum"]): continue
		for producer: Dictionary in _producers(world,str(recipe["building_type"])):
			if producer["queue"].is_empty(): return type
	return ""


func _worker_goal(world: Dictionary) -> int:
	if Outposts.enabled(world): return 0
	var nominal:=mini(int(_policy["worker_max"]), int(_policy["worker_goal"]) + (4 if _tactics.id == "EXPANSION_BOOM" else 0) + maxi(0, _building_count(world, "BASE", true) - 1) * int(_policy["worker_per_base"]) + _usable_essence_sites(world).size() * Economy.ESSENCE_WORKER_CAP)
	var usable:=GrowthM71.resource_slots(world,"FOOD")+GrowthM71.resource_slots(world,"MATERIAL")+GrowthM71.resource_slots(world,"ESSENCE")
	return mini(nominal,maxi(6,usable+2))


func _resource_urgent(world: Dictionary) -> bool:
	if Outposts.enabled(world): return Outposts.resource_urgent(world)
	if not world.has("resource_sources"): return false
	var workers := maxi(1, _worker_count(world))
	# Three remaining cargo trips per worker is an anticipatory expansion
	# threshold, not an invented income estimate or a second source ledger.
	var saturated:=GrowthM71.resource_slots(world,"FOOD")+GrowthM71.resource_slots(world,"MATERIAL")<=workers-1
	var upkeep:Dictionary=world.get("population_upkeep",{}).get("AI",{})
	return saturated or int(upkeep.get("material_efficiency_percent",100))<100 or Opportunities.available_source(world, "FOOD") < workers * 30 or Opportunities.available_source(world, "MATERIAL") < workers * 20


func _expansion_development(world: Dictionary) -> Dictionary:
	var best := {}
	var score := 9223372036854775807
	var home := _own_base(world)
	if home.is_empty() and not Outposts.enabled(world): return {}
	for site: Dictionary in world.get("sites", []):
		if Outposts.enabled(world):
			if not Outposts.needs_income_building(world, site): continue
			if Opportunities.local_enemy_power(world, site.position) + Opportunities.fortification_pressure(world, site.position) > 0: continue
			var outpost_distance: int = 0 if home.is_empty() else (Vector2i(site.position) - Vector2i(home.position)).length_squared()
			if outpost_distance < score: best = site; score = outpost_distance
			continue
		if site.get("kind") != "RESOURCE" or site.get("resource", "") == "ESSENCE" or site.get("owner") != "AI" or _site_has_any_base(world, site): continue
		if int(site.get("progress", World.CAPTURE_THRESHOLD)) < int(site.get("threshold", World.CAPTURE_THRESHOLD)): continue
		if _source_remaining(world, str(site.id), "FOOD") <= 0 and _source_remaining(world, str(site.id), "MATERIAL") <= 0: continue
		# Paid construction is not committed into a currently observed hostile
		# force; occupy/clear it first, then workers receive a normal blueprint.
		if Opportunities.local_enemy_power(world, site.position) + Opportunities.fortification_pressure(world, site.position) > 0: continue
		var distance := (Vector2i(site.position) - Vector2i(home.position)).length_squared()
		if distance < score: best = site; score = distance
	if best.is_empty(): return {}
	var order := _placement(world, Outposts.income_building(best) if Outposts.enabled(world) else "BASE", best.position)
	if not order.is_empty(): _expansion_site = str(best.id)
	return order


static func _military_count(world: Dictionary, military: Dictionary) -> int:
	var count := 0
	for unit: Dictionary in military["soldiers"]:
		if unit["side"] == "AI" and bool(unit["alive"]): count += 1
	for producer: Dictionary in world["buildings"]:
		if producer["side"] != "AI": continue
		for entry: Dictionary in producer["queue"]:
			if entry["unit_type"] != "worker": count += 1
	return count


static func _producers(world: Dictionary, kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for producer: Dictionary in world["buildings"]:
		if producer["side"] == "AI" and producer["building_type"] == kind and bool(producer["complete"]) and int(producer["hp"]) > 0 and Outposts.building_operational(world,producer) and (kind != "BASE" or producer.get("base_upgrade", {}).is_empty()): result.append(producer)
	return result


static func _available_altar(world: Dictionary) -> Dictionary:
	for altar: Dictionary in _producers(world,"ALTAR"):
		if altar.get("queue",[]).is_empty(): return altar
	return {}


static func _can_recruit(world: Dictionary, type: String, reserve: Dictionary) -> bool:
	# Hero prices depend on the authoritative lifetime roster/level, never the
	# generic catalog recipe. Callers must select an exact quoted archetype.
	if type == "hero": return false
	var recipe := _recipe(type)
	if recipe.is_empty() or _base_tier(world) < int(recipe.get("required_base_tier", Progression.UNIT_TIERS.get(type, 1))): return false
	if type not in ["worker","hero"] and recipe.get("faction_id","")!=_faction(world):return false
	for kind: String in recipe.get("required_buildings",[]):
		if _building_of_type(world,kind,true).is_empty():return false
	var cost: Dictionary = recipe["cost"]
	if not Economy.Currency.valid_gold_cost(cost): return false
	var stock: Dictionary = world["economy"]["AI"]["stock"]
	for resource: String in Economy.RESOURCE_KEYS:
		if int(stock.get(resource,0)) < int(cost.get(resource,0)) + int(reserve.get(resource, 0)): return false
	var population: Dictionary = world.get("population", {}).get("AI", {})
	return population.is_empty() or int(population["used"]) + int(population["reserved"]) + int(recipe["population"]) <= int(population["maximum"])


static func _can_pay(world: Dictionary, cost: Dictionary) -> bool:
	if not Economy.Currency.valid_gold_cost(cost): return false
	var stock: Dictionary = world.get("economy",{}).get("AI",{}).get("stock",{})
	for resource: String in Economy.RESOURCE_KEYS:
		if int(stock.get(resource,0)) < int(cost.get(resource,0)): return false
	return true


func _hero_recruit_priority(world: Dictionary, military: Dictionary) -> Array[String]:
	# Every current identity stays a candidate. Strategy selects a role bias,
	# existing officers add composition context, and seed breaks peer ties.
	# No difficulty, price override, arbitrary roster mutation or fresh RNG.
	var weights:Dictionary={}
	match str(_tactics.id):
		"VANGUARD_RUSH":weights={"MELEE_CASTER":4,"PHYSICAL":3,"TANK":2,"WARRIOR":2}
		"RAIDER_HARASS":weights={"PHYSICAL":4,"MELEE_CASTER":3,"MAGE":2}
		"EXPANSION_BOOM":weights={"HEAL_SUPPORT":4,"TANK":3,"MAGE":2}
		"TECH_TIMING":weights={"MAGE":4,"CONTROL_SUPPORT":3,"PHYSICAL":2}
		"CREEP_ESSENCE_CONTROL":weights={"MAGE":3,"PHYSICAL":3,"HEAL_SUPPORT":2}
		"SIEGE_PUSH":weights={"MAGE":4,"CONTROL_SUPPORT":3,"HEAL_SUPPORT":2}
		"SPLIT_CAPTURE":weights={"PHYSICAL":4,"WARRIOR":3,"MELEE_CASTER":2}
		"DEFENSIVE_COUNTER":weights={"CONTROL_SUPPORT":4,"TANK":3,"MAGE":2}
	var owned_roles:Dictionary={}
	for hero:Dictionary in world.get("heroes",military.get("heroes",{})).get("officers",[]):
		if hero.get("side")!="AI":continue
		var existing:=HeroCatalog.profile(str(hero.get("archetype",hero.get("hero_archetype",""))))
		if not existing.is_empty():owned_roles[str(existing.role_id)]=int(owned_roles.get(str(existing.role_id),0))+1
	var result:Array[String]=[];var scores:Dictionary={}
	for id:String in Factions.heroes_for(_faction(world)):
		var profile:=HeroCatalog.profile(id)
		if profile.is_empty():continue
		result.append(id)
		var tie:=float(absi(hash("%d:%s:%s:%s:hero-pick"%[_seed,_side_id,_faction(world),id]))%1000)/1000.0
		scores[id]=float(weights.get(str(profile.role_id),1))-float(owned_roles.get(str(profile.role_id),0))*3.0+tie*.5
	result.sort_custom(func(a:String,b:String)->bool:return a<b if scores[a]==scores[b] else float(scores[a])>float(scores[b]))
	return result

static func _hero_is_ranged(kind:String)->bool:
	var profile:=HeroCatalog.profile(kind)
	return not profile.is_empty() and int(profile.stats.get("attack_range",0))>80

static func _missing_hero_type(world: Dictionary, military: Dictionary, ordered:Array=[]) -> String:
	# Quotes already account for dead permanent members, queued reservations,
	# duplicate recalls and tier admission. Do not reconstruct a living-only
	# roster here: that previously allowed a dead officer to free a fourth type.
	for hero: Dictionary in military.get("heroes", {}).get("officers", []):
		var type := str(hero.get("archetype", "COMMANDER"))
		if hero.get("side") == "AI" and hero.get("state") != "ACTIVE" and _hero_quote(world,type).get("mode") == "REVIVE": return type
	var available:Array=Factions.heroes_for(_faction(world))
	var preferred:Array=ordered.duplicate() if not ordered.is_empty() else available
	for type: String in preferred:
		if type in available and not _hero_quote(world,type).is_empty(): return type
	return ""


static func _hero_quote(world: Dictionary, archetype: String) -> Dictionary:
	var quote: Dictionary = world.get("hero_quotes",{}).get("AI",{}).get(archetype,{})
	return quote if bool(quote.get("accepted",false)) else {}


static func _can_recruit_hero(world: Dictionary, archetype: String, reserve: Dictionary) -> bool:
	var quote := _hero_quote(world,archetype)
	if quote.is_empty(): return false
	var stock: Dictionary = world.get("economy",{}).get("AI",{}).get("stock",{})
	for resource: String in Economy.RESOURCE_KEYS:
		if int(stock.get(resource,0)) < int(quote.get("cost",{}).get(resource,0)) + int(reserve.get(resource,0)): return false
	var population: Dictionary = world.get("population",{}).get("AI",{})
	return population.is_empty() or int(population["used"]) + int(population["reserved"]) + int(quote.get("population",5)) <= int(population["maximum"])


func _military_actions(world: Dictionary, military: Dictionary, technology: Dictionary, elapsed: int, armies: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var joint_orders := _cooperative_capture_orders(world, armies)
	if _tactics.id == "RAIDER_HARASS" and _pressure_finished:
		for army: Dictionary in armies:
			var native_home:=Vector2i(army.get("home_anchor",army.anchor))
			# Reaction may already have admitted STOP at the legal formation home.
			# HOLD's destination is merely its current anchor, not proof of return.
			var held_home:bool=army.get("intent")=="HOLD" and (Vector2i(army.anchor)-native_home).length_squared()<=160*160 and _rally_safe(world,native_home) and _rally_safe(world,Vector2i(army.anchor))
			if army.id == _pressure_army_id and (_at_safe_refuge(world,army) or held_home):
				_raid_targets.erase(_pressure_army_id)
				_pressure_army_id = ""
				_pressure_finished = false
				_next_raid_tick = elapsed + 200
				break
	var no_opposition := _living_enemy_count(military) == 0
	var enemy_has_base := false
	for building: Dictionary in world["buildings"]:
		if building["side"] == "PLAYER" and building["building_type"] == "BASE" and bool(building["complete"]) and int(building["hp"]) > 0:
			enemy_has_base = true
	var adequate_force := _side_power(military, "AI") * 10 >= _side_power(military, "PLAYER") * 9
	var ready := not enemy_has_base or elapsed >= int(_policy["forced_assault_ticks"]) or (elapsed >= int(_policy["assault_ticks"]) and adequate_force and _building_count(world, "BASE", true) >= 2 and int(technology.get("AI", {}).get("ATTACK", 0)) >= 1)
	_assault_committed = _assault_committed or ready or no_opposition
	_pressure_active = false
	if not _assault_committed and _pressure_army_id.is_empty() and int(_policy["pressure_ticks"]) >= 0 and elapsed >= int(_policy["pressure_ticks"]) and elapsed >= _next_raid_tick:
		var candidate := _pressure_candidate(world, military, armies)
		if not candidate.is_empty():
			_pressure_army_id = str(candidate["id"])
			_pressure_start_tick = elapsed
			_pressure_contact_tick = -1
	if not _assault_committed and not _pressure_army_id.is_empty() and not _pressure_finished:
		# Contact is the start of a fight, not proof that a one-swing mission is
		# complete. Keep fighting while real attacks make progress; ordinary
		# casualty/local-danger gates below still disengage a losing formation.
		var last_contact := -1
		for unit: Dictionary in military["soldiers"]:
			if unit["warband_id"] == _pressure_army_id and unit.get("last_action_kind", "") == "ATTACK" and int(unit.get("last_action_tick", -1)) >= _battle_start + _pressure_start_tick and unit.get("last_action_target_side", "") == "PLAYER" and not str(unit.get("last_action_target_id", "")).is_empty():
				if _pressure_contact_tick < 0: _pressure_contact_tick = elapsed
				last_contact = maxi(last_contact, int(unit.last_action_tick) - _battle_start)
		# A finite failed trip or a completed raid without further contact may
		# return. A live favorable fight cannot be cancelled by its own timer.
		if elapsed - _pressure_start_tick >= 800 and (last_contact < 0 or elapsed - last_contact >= 160): _pressure_finished = true
	var defenders := _defender_ids(world,military,armies)
	# Once a real assault window is open, optional solo camp growth must not
	# steal the army before the common enemy objective is considered. This
	# does not waive each order's local safety gate or borrow remote allies.
	var assault_orders := _r9_assault_orders(world, military, armies) if _assault_committed else {}
	_status = "ASSAULT" if _assault_committed else "EXPANDING"
	for army: Dictionary in armies:
		var id := str(army["id"])
		var count := int(army["living_count"])
		_army_peaks[id] = maxi(count, int(_army_peaks.get(id, 0)))
		if count <= 0:
			_threat_locks.erase(id)
			_resume_orders.erase(id)
			_growth_targets.erase(id)
			_route_journeys.erase(id)
			_travel_releases.erase(id)
			_military_pending_since.erase(id)
			continue
		var order := {}
		var threat_order := _threat_order(world,military,army,id in defenders)
		var activity:Dictionary={}
		if threat_order.is_empty() and not assault_orders.has(id) and not joint_orders.has(id) and army.get("intent")!="RETREAT" and not bool(_regrouping.get(id,false)) and _army_hp(military,id)>=55:
			# A long-lived starting deposit is not a developed economy. A safe
			# second income lane precedes optional XP tourism, but never a current
			# threat/retreat or a genuinely population-blocked village campaign.
			if _economic_expansion_needed_r9(world) and not _live_camp_contact_r9(world,army):
				var productive := _capture_target(world,army,result)
				if Outposts.is_resource_site(productive):
					_army_targets[id]=str(productive.id)
					_growth_targets.erase(id)
					activity={"type":"ATTACK_MOVE","subject_id":id,"target_position":productive.position}
					_strategic_diagnostics["economic_goal:"+id]={"tick":_planning_tick,"site_id":productive.id,"reason":"finite_second_income_before_optional_camps"}
			if activity.is_empty():activity=_active_growth_order(world,military,army,result)
		var at_home := _at_safe_refuge(world,army)
		if army.get("intent")=="RETREAT" and not at_home:
			order={"type":"RETREAT","subject_id":id}
		elif army.get("intent")=="ATTACK_BASE" and _attack_base(world,military,army).is_empty():
			# Cancel the old actual hostile march before selecting a different
			# profitable objective; a new camp must not silently preserve a dive.
			order={"type":"RETREAT","subject_id":id}
		elif joint_orders.get(id, {}).get("type") == "RETREAT":
			order = threat_order if not threat_order.is_empty() and _base_recently_attacked(world) else joint_orders[id]
		elif no_opposition and activity.is_empty():
			# Zero enemy military is not zero enemy weapons. Workers and real
			# site defenses can still be the active temporary threat to this army.
			order = threat_order if not threat_order.is_empty() else _attack_base(world, military, army)
		else:
			var hp := _army_hp(military, id)
			# Historical army size is diagnostic, not present fighting strength.
			# Healthy survivors may decisively beat a smaller enemy; the local
			# observed-force gate below still rejects a genuinely losing fight.
			var depleted := hp < 38 and _near_enemy(military, army["anchor"], 420)
			if depleted and not at_home:
				_regrouping[id] = true
			if bool(_regrouping.get(id, false)):
				if at_home:
					_regrouping.erase(id)
					order = threat_order if not threat_order.is_empty() else {"type":"STOP","subject_id":id}
				# Recovery is current health, not rebuilding an old headcount. The
				# fresh local force assessment decides whether to engage again.
				elif hp >= 55:
					_regrouping.erase(id)
				else:
					order = {"type": "RETREAT", "subject_id": id}
					_status = "REGROUPING"
			if order.is_empty() and not threat_order.is_empty():
				order = threat_order
				_status = "DEFENDING"
			elif order.is_empty() and assault_orders.has(id):
				order = assault_orders[id]
				_status = "ASSAULT"
			elif order.is_empty() and joint_orders.has(id):
				order = joint_orders[id]
				_status = "CREEP_MUSTER" if not bool(_joint_capture.get("released", false)) else "CLEARING_RESOURCE"
			elif order.is_empty() and not activity.is_empty():
				order=activity
				_status="ACTIVE_GROWTH"
			elif order.is_empty() and _assault_committed:
				var central := _essence_contest_target(world,army,result)
				var defender := _nearby_defender(military, army)
				if not defender.is_empty(): order = _enemy_order(military,army,defender)
				elif not central.is_empty():
					_army_targets[id] = str(central.id)
					order = {"type":"ATTACK_MOVE","subject_id":id,"target_position":central.position}
				else: order = _attack_base(world,military,army)
			elif order.is_empty() and id == _pressure_army_id:
				# A single stable army pressures the actual opposing position. The
				# other army retains normal capture/development, and ordinary threat
				# and casualty retreat gates above still override this commitment.
				if _pressure_finished:
					order = {"type":"STOP","subject_id":id} if at_home else {"type": "RETREAT", "subject_id": id}
					if _status == "EXPANDING": _status = "REGROUPING"
				else:
					var defender := _nearby_defender(military, army)
					order = _enemy_order(military, army, defender) if not defender.is_empty() else _pressure_order(world, military, army)
					_pressure_active = not order.is_empty()
					if _status == "EXPANDING" and _pressure_active: _status = "PRESSURING"
			elif order.is_empty():
				var site := _capture_target(world, army, result)
				if not site.is_empty():
					_army_targets[id] = str(site["id"])
					order = {"type": "ATTACK_MOVE", "subject_id": id, "target_position": site["position"]}
		# A clock can open an attack window, never waive force/weapon safety.
		# If no safe offensive objective exists, keep earning actual territory
		# rather than repeatedly issuing an impossible home-base all-in.
		if order.is_empty() and not bool(_regrouping.get(id, false)):
			var fallback := _capture_target(world, army, result)
			if not fallback.is_empty():
				_army_targets[id] = str(fallback.id)
				order = {"type":"ATTACK_MOVE","subject_id":id,"target_position":fallback.position}
				_status = "CAPTURING"
		if order.is_empty() and army.get("intent") == "ATTACK_BASE":
			# Rejecting a newly unsafe opportunity does not revoke a host order
			# already in flight. With no safe replacement, explicitly disengage;
			# idle armies with no previous siege must not be told to flee.
			order = {"type":"RETREAT","subject_id":id}
		if not _threat_locks.has(id):order=_journey_order(world,army,order)
		order = _local_battle_order(world,military,army,order)
		var pending_leg:Dictionary=_route_journeys.get(id,{})
		var needs_admission:bool=order.get("type")=="ATTACK_MOVE" and order.get("target_position")==pending_leg.get("pending_point") and int(pending_leg.get("accepted_tick",-1))<0
		if not order.is_empty() and (not _already_ordered(army, order) or needs_admission):
			result.append(order)
		elif not order.is_empty():
			var formation := _formation_for(military, army)
			if army["formation"] != formation:
				result.append({"type": "SET_FORMATION", "subject_id": id, "formation": formation})
	return result


func _r9_assault_orders(world:Dictionary,military:Dictionary,armies:Array[Dictionary])->Dictionary:
	# One observed, authority-legal base objective for every presently capable
	# formation. Evaluate living own bodies, not treasury/accumulated scores.
	# Optional growth stays available to armies for which no legal safe siege
	# exists; a clock does not turn a genuine tower trap into a good attack.
	var candidates:Array[Dictionary]=[]
	for base:Dictionary in world.get("buildings",[]):
		if base.get("side")=="PLAYER" and base.get("building_type")=="BASE" and VisibilityR9.can_observe(base,str(world.get("planning_view_side_r9","AI"))) and int(base.get("hp",0))>0 and bool(base.get("complete",false)):
			candidates.append(base)
	var result:Dictionary={};var best_count:=0;var best_distance:=INF
	for base:Dictionary in candidates:
		var proposed:Dictionary={};var distance:=0.0
		for group:Dictionary in armies:
			var id:=str(group.id)
			if int(group.get("living_count",0))<=0 or group.get("intent")=="RETREAT" or bool(_regrouping.get(id,false)) or _army_hp(military,id)<38:continue
			if not Opportunities.siege_safe(world,group,base):continue
			var forecast:=_local_forecast(world,group,base.position)
			if int(forecast.get("friendly_count",0))<=0 or bool(forecast.get("truncated",false)) or float(forecast.get("ratio",0))<1.0:continue
			proposed[id]={"type":"ATTACK_BASE","subject_id":id,"target_base_id":base.id}
			distance+=Vector2(group.anchor).distance_squared_to(Vector2(base.position))
		if proposed.size()>best_count or proposed.size()==best_count and distance<best_distance:
			result=proposed;best_count=proposed.size();best_distance=distance
	if not result.is_empty():
		var target:=str(result.values()[0].target_base_id)
		for id:String in result:_siege_targets[id]=target
		_strategic_diagnostics["assault_r9"]={"tick":_planning_tick,"phase":"COMMON_SAFE_OBJECTIVE","target_base_id":target,"army_ids":result.keys(),"reason":"legal_current_force_before_optional_growth_no_remote_strength_loan"}
	return result


func _active_growth_order(world:Dictionary,military:Dictionary,army:Dictionary,pending:Array[Dictionary])->Dictionary:
	var id:=str(army.id)
	if int(army.get("living_count",0))<2:return {}
	var previous:Dictionary=_growth_targets.get(id,{})
	if not previous.is_empty():
		var travel:Dictionary=_route_journeys.get(id,{})
		if travel.get("goal")==previous.get("point") and int(travel.get("accepted_tick",-1))>=0:
			previous["last_progress_tick"]=maxi(int(previous.get("last_progress_tick",-1)),int(travel.get("last_progress_tick",-1)))
		var distance:=_growth_body_distance(world,army,Vector2i(previous.point))
		var hp:=_growth_camp_hp(world,str(previous.camp_id))
		if distance<float(previous.get("best_distance",INF))-12.0 or hp<float(previous.get("lowest_camp_hp",INF)):
			previous["last_progress_tick"]=_planning_tick
			previous["best_distance"]=minf(distance,float(previous.get("best_distance",INF)))
			previous["lowest_camp_hp"]=minf(hp,float(previous.get("lowest_camp_hp",INF)))
		elif int(previous.get("accepted_tick",-1))>=0 and _planning_tick-int(previous.get("last_progress_tick",_planning_tick))>=GrowthM71.STALE_TICKS:
			_growth_cooldowns[str(previous.camp_id)]=_planning_tick+GrowthM71.COOLDOWN_TICKS
			_growth_targets.erase(id)
			_strategic_diagnostics["growth:"+id]={"phase":"STALE_REPLAN","camp_id":previous.camp_id,"tick":_planning_tick,"reason":"no_real_body_approach_guard_damage_or_capture_progress_for_12_seconds"}
			previous={}
	if not previous.is_empty() and int(previous.get("accepted_tick",-1))>=0:
		for cleared:Dictionary in world.get("neutral_camps",[]):
			if cleared.get("id")!=previous.get("camp_id") or cleared.get("state")!="CLEARED":continue
			for site:Dictionary in world.get("sites",[]):
				if site.get("id")!=cleared.get("site_id") or site.get("owner")=="AI":continue
				if not _capture_allowed(world,site) or not _capture_is_safe(world,army,site):break
				# Clearing the last guard is a handoff, not completion of a site
				# campaign. Keep the accepted army until real ownership changes.
				var capture_key:="%s:%s:%s"%[site.get("owner",""),site.get("capture_side",""),site.get("progress",0)]
				if previous.get("capture_key","")!=capture_key:
					previous["capture_key"]=capture_key
					previous["last_progress_tick"]=_planning_tick
				previous["stage"]="CAPTURING_CLEARED_SITE"
				_growth_targets[id]=previous
				_strategic_diagnostics["growth:"+id]={"phase":"CAPTURING_CLEARED_SITE","tick":_planning_tick,"camp_id":cleared.id,"site_id":site.id,"progress":site.get("progress",0),"lease":previous.duplicate(true)}
				return {"type":"ATTACK_MOVE","subject_id":id,"target_position":site.position}
	var best:Dictionary={};var best_score:=-INF;var rejected:Array=[]
	var opening_green:=true
	for hero:Dictionary in world.get("heroes",{}).get("officers",[]):
		if hero.get("side")=="AI" and int(hero.get("xp",0))>0:opening_green=false;break
	var has_opening_green:=false
	for camp:Dictionary in GrowthM71.candidates(world,army,_growth_cooldowns,_planning_tick):
		var occupied:=false
		for other:String in _growth_targets:
			if other!=id and _growth_targets[other].get("camp_id")==camp.id:occupied=true;break
		for command:Dictionary in pending:
			if command.get("target_position")==camp.position:occupied=true;break
		if occupied:continue
		var forecast:=_local_forecast(world,army,camp.position)
		var benefit:=_growth_value(world,army,camp,forecast)
		if not bool(benefit.safe):
			rejected.append({"camp_id":camp.id,"ratio":forecast.ratio,"loss":forecast.friendly_loss_fraction,"clear_seconds":benefit.clear_seconds_estimate,"reason":"risk_not_reward_gated"})
			continue
		# Clear the first quick green camp before investing both armies into a
		# more remote campaign. This is a finite campaign phase, not a combat
		# multiplier or a permanent preference over resource expansion.
		var quick_green:bool=opening_green and camp.get("kind")=="SCATTERED" and Vector2(camp.position).distance_to(Vector2(army.anchor))<=1100.0 and float(benefit.clear_seconds_estimate)<=35.0 and bool(benefit.safe)
		if has_opening_green and not quick_green and previous.get("camp_id")!=camp.id:continue
		var score:=float(benefit.utility)
		# A small commitment preference prevents equal camps alternating. Real
		# damage/approach must keep its 12-second lease alive; clock alone cannot.
		if previous.get("camp_id")==camp.id:
			# A genuinely progressing safe camp is a finite commitment. Do not
			# abandon its final guard whenever XP changes another target's score.
			best={"camp":camp,"benefit":benefit};best_score=score;break
		if quick_green and not has_opening_green:best={};best_score=-INF;has_opening_green=true
		if score>best_score:best={"camp":camp,"benefit":benefit};best_score=score
	if best.is_empty():
		_growth_targets.erase(id)
		_strategic_diagnostics["growth:"+id]={"phase":"NO_SAFE_CAMP","tick":_planning_tick,"rejected":rejected,"next":"existing_capture_rally_pressure_or_development_not_forced_suicide"}
		return _active_enemy_order(world,military,army)
	var camp:Dictionary=best.camp
	if previous.get("camp_id")!=camp.id:previous={"camp_id":camp.id,"point":camp.position,"started_tick":_planning_tick,"accepted_tick":-1,"last_progress_tick":_planning_tick,"best_distance":_growth_body_distance(world,army,camp.position),"lowest_camp_hp":_growth_camp_hp(world,str(camp.id))}
	previous["risk_floor"]=best.benefit.risk_floor
	previous["point"]=camp.position
	_growth_targets[id]=previous
	_strategic_diagnostics["growth:"+id]={"phase":"CLEARING_CAMP","tick":_planning_tick,"choice":best.benefit,"lease":previous.duplicate(true),"rejected":rejected,"utility":best_score}
	# Compare already-feasible rewards, not an arbitrary700px camp boundary.
	# A physically progressing accepted camp retains its finite mission lease;
	# an uncommitted inferior camp cannot suppress profitable local pressure.
	var enemy:=_active_enemy_order(world,military,army)
	var enemy_benefit:Dictionary=_strategic_diagnostics.get("active_enemy:"+id,{}).get("benefit",{})
	var committed:bool=int(previous.get("accepted_tick",-1))>=0
	if not enemy.is_empty() and not committed and float(enemy_benefit.get("utility",-INF))>best_score*1.1+0.10:
		_growth_targets.erase(id)
		_strategic_diagnostics["growth:"+id]={"phase":"PVP_OVER_UNCOMMITTED_CAMP","tick":_planning_tick,"camp_id":camp.id,"camp_utility":best_score,"enemy_benefit":enemy_benefit,"reason":"feasible_reward_and_opponent_attrition_not_future_dps"}
		return enemy
	return {"type":"ATTACK_MOVE","subject_id":id,"target_position":camp.position}


func _journey_order(world:Dictionary,army:Dictionary,order:Dictionary)->Dictionary:
	if order.get("type")!="ATTACK_MOVE":return order
	var id:=str(army.id)
	var state:Dictionary=_route_journeys.get(id,{})
	var goal:=Vector2i(order.target_position)
	var resuming:bool=not state.is_empty() and _resume_orders.get(id,{})==order
	# Temporary defense remembers a legal waypoint. The retained semantic
	# objective must survive that interruption without replaying a direct trip.
	if resuming or state.get("pending_point")==goal:goal=Vector2i(state.get("goal",goal))
	var released:Dictionary=_travel_releases.get(id,{})
	if released.get("goal")==goal and _planning_tick<int(released.get("until_tick",-1)):
		return {"type":"STOP","subject_id":id}
	var avoid:=_journey_avoid(world,army,goal)
	var result:Dictionary=JourneyM73.advance(world,army,goal,_planning_tick,avoid,state)
	_route_journeys[id]=result.state
	_strategic_diagnostics["travel:"+id]={"tick":_planning_tick,"goal":goal,"reason":result.reason,"blocked":result.blocked,"avoid":avoid,"state":result.state.duplicate(true)}
	if bool(result.blocked):
		if resuming:_resume_orders.erase(id)
		# An unaccepted blocked proposal cannot reserve a growth task forever.
		# Release that camp briefly so another feasible job can be considered.
		var growth:Dictionary=_growth_targets.get(id,{})
		if not growth.is_empty() and growth.get("point")==goal:
			_growth_cooldowns[str(growth.camp_id)]=_planning_tick+GrowthM71.COOLDOWN_TICKS
			_growth_targets.erase(id)
		if str(result.reason).contains("STALE"):
			# The pure journey stays STALE until its owner acknowledges release.
			# A later accepted attempt is distinct, after a finite cooldown.
			_route_journeys.erase(id)
			_travel_releases[id]={"goal":goal,"until_tick":_planning_tick+GrowthM71.COOLDOWN_TICKS,"reason":result.reason}
			for camp:Dictionary in world.get("neutral_camps",[]):
				if camp.has("position") and Vector2(camp.position).distance_to(Vector2(goal))<=180.0:_growth_cooldowns[str(camp.id)]=_planning_tick+GrowthM71.COOLDOWN_TICKS
		if str(result.reason).contains("CURRENTLY_EXPOSED"):return _local_withdraw(world,army,"TRAVEL_ALREADY_EXPOSED")
		# STOP freezes actual member HOLDs at their scattered positions. A legal
		# local MOVE instead lets their ordinary collision/navigation authority
		# collect reinforcements before the next bounded route proposal.
		if _rally_safe(world,Vector2i(army.anchor)) and (str(result.reason).contains("MEMBER_CORRIDOR") or str(result.reason).contains("NO_SAFE_ROUTE")):
			return {"type":"MOVE","subject_id":id,"target_position":army.anchor}
		return {"type":"STOP","subject_id":id}
	if resuming:
		if bool(result.get("arrived",false)):_resume_orders.erase(id)
		elif not result.command.is_empty():_resume_orders[id]=result.command.duplicate(true)
	return result.command


func _journey_avoid(world:Dictionary,army:Dictionary,goal:Vector2i)->Array:
	# Future travel risk is deliberately detached from present alarms. A guard
	# can be harmless while returning yet fully recover before we pass its home.
	var nearby:Array[Dictionary]=[]
	var start:=Vector2(army.anchor)
	var finish:=Vector2(goal)
	for camp:Dictionary in world.get("neutral_camps",[]):
		if not camp.has("position") or camp.get("state")=="CLEARED" or int(camp.get("remaining_count",0))<=0:continue
		var point:=Vector2(camp.position)
		if point.distance_to(finish)<180.0:continue # Destination guards are never bypassed.
		var closest:=Geometry2D.get_closest_point_to_segment(point,start,finish)
		if point.distance_to(closest)>650.0:continue
		var observed:=false
		for body:Dictionary in world.get("micro_neutral_targets",[]):
			if body.get("camp_id")==camp.id and int(body.get("hp",0))>0 and bool(body.get("visible",true)):observed=true;break
		if observed:nearby.append(camp)
	nearby.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return Vector2(a.position).distance_squared_to(start)<Vector2(b.position).distance_squared_to(start))
	if nearby.size()>4:nearby.resize(4)
	var future:=world.duplicate(false)
	future["micro_neutral_targets"]=[]
	for original:Dictionary in world.get("micro_neutral_targets",[]):
		var body:=original.duplicate(false)
		if body.has("home_position") and (bool(body.get("leashing",false)) or Vector2(body.position).distance_to(Vector2(body.home_position))>320.0):
			body.position=body.home_position;body.leashing=false;body.last_leash_tick=-1000000;body.hp=body.get("max_hp",body.hp)
		future.micro_neutral_targets.append(body)
	var future_frame:Dictionary=LocalBattle.prepare(future)
	var avoid:Array=[]
	for camp:Dictionary in nearby:
		var risk:=LocalBattle.estimate(future,army,Vector2i(camp.position),{"frame":future_frame})
		_local_battle_work.queries+=1
		if bool(risk.truncated) or float(risk.ratio)<1.08 or float(risk.friendly_loss_fraction)>0.50:
			avoid.append(str(camp.id))
			if avoid.size()>=2:break
	return avoid


func _active_enemy_order(world:Dictionary,military:Dictionary,army:Dictionary)->Dictionary:
	var candidates:Array[Dictionary]=[]
	for body:Dictionary in military.get("soldiers",[])+world.get("workers",[]):
		if body.get("side")!="PLAYER" or int(body.get("hp",0))<=0 or not bool(body.get("visible",true)) or not _army_can_hit(military,army,body):continue
		if Vector2(body.position).distance_to(Vector2(army.anchor))>900.0:continue
		candidates.append(body)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return Vector2(a.position).distance_squared_to(Vector2(army.anchor))<Vector2(b.position).distance_squared_to(Vector2(army.anchor)))
	if candidates.size()>4:candidates.resize(4)
	var best:Dictionary={};var best_value:=-INF;var best_benefit:Dictionary={}
	for body:Dictionary in candidates:
		var forecast:=_local_forecast(world,army,body.position)
		var benefit:Dictionary=EnemyValueM75.value(world,army,body,forecast,_tactics.id)
		if not bool(benefit.safe):continue
		var value:=float(benefit.utility)
		if value>best_value:best=body;best_value=value;best_benefit=benefit
	if best.is_empty():
		_strategic_diagnostics["active_enemy:"+str(army.id)]={"phase":"NO_SAFE_OBSERVED_OPPONENT","tick":_planning_tick,"candidates":candidates.size(),"reason":"risk_first_rewards_do_not_authorise_losing_fights"}
		return {}
	_strategic_diagnostics["active_enemy:"+str(army.id)]={"target_id":best.id,"priority":best_value,"tick":_planning_tick,"benefit":best_benefit,"reason":"observed_feasible_kill_xp_and_enemy_attrition_not_global_assault_timer"}
	return _enemy_order(military,army,best)


static func _growth_body_distance(world:Dictionary,army:Dictionary,point:Vector2i)->float:
	var total:=0.0;var count:=0
	for body:Dictionary in world.get("soldiers",[]):
		if body.get("side")=="AI" and body.get("warband_id")==army.id and int(body.get("hp",0))>0:total+=Vector2(body.position).distance_to(Vector2(point));count+=1
	return total/float(count) if count>0 else INF


static func _growth_camp_hp(world:Dictionary,camp_id:String)->float:
	var hp:=0.0
	for body:Dictionary in world.get("micro_neutral_targets",[]):
		if body.get("camp_id")==camp_id:hp+=maxf(0.0,float(body.get("hp",0)))
	return hp


func _capture_is_safe(world:Dictionary,army:Dictionary,site:Dictionary)->bool:
	if not world.has("micro_neutral_targets"):return Opportunities.capture_safe(world,army,site)
	for camp:Dictionary in world.get("neutral_camps",[]):
		if camp.get("site_id")==site.id and not camp.has("member_ids"):return Opportunities.capture_safe(world,army,site)
	var estimate:=_local_forecast(world,army,site.position)
	return int(estimate.friendly_count)>0 and not bool(estimate.truncated) and float(estimate.ratio)>=1.08 and float(estimate.friendly_loss_fraction)<=0.55


func _cooperative_capture_orders(world: Dictionary, armies: Array[Dictionary]) -> Dictionary:
	var orders := {}
	if _base_recently_attacked(world):
		for army: Dictionary in armies:
			if army.id in _joint_capture.get("army_ids", []) and int(army.get("living_count", 0)) > 0: orders[str(army.id)] = {"type":"RETREAT","subject_id":army.id}
		_joint_capture.clear()
		return orders
	var available: Array[Dictionary] = []
	for army: Dictionary in armies:
		if int(army.get("living_count", 0)) >= 2 and _army_hp(world, str(army.id)) >= 65 and army.get("intent") != "RETREAT" and not bool(_regrouping.get(str(army.id), false)) and _base_threat(world, world, army).is_empty(): available.append(army)
	var site := {}
	for candidate: Dictionary in world.get("sites", []):
		if candidate.id == _joint_capture.get("site_id", ""): site = candidate; break
	var locked_ids: Array = _joint_capture.get("army_ids", [])
	var lock_valid: bool = not site.is_empty() and site.get("owner") != "AI" and _planning_tick < int(_joint_capture.get("expires_tick", -1)) and locked_ids.size() == 2
	for id: String in locked_ids:
		if not available.any(func(army: Dictionary) -> bool: return army.id == id): lock_valid = false
	if lock_valid:
		var own := 0
		for id: String in locked_ids: own += Opportunities.army_power(world, id)
		var risk := Opportunities.camp_power(world, str(site.id)) + Opportunities.local_enemy_power(world, site.position) + Opportunities.fortification_pressure(world, site.position)
		if own * 5 < risk * 6: lock_valid = false
	if not lock_valid:
		var abandon_march: bool = not _joint_capture.is_empty() and (site.is_empty() or site.get("owner") != "AI")
		if not _joint_capture.is_empty() and _planning_tick >= int(_joint_capture.get("expires_tick", -1)):
			_joint_capture_cooldowns[str(_joint_capture.site_id)] = _planning_tick + 200
		_joint_capture.clear()
		_strategic_diagnostics.erase("cooperative_capture")
		site = {}
		if abandon_march:
			# Clearing planner memory does not cancel an already accepted host
			# ATTACK_MOVE. Explicitly disengage both surviving partners, with
			# RETREAT taking the ordinary emergency command priority.
			for army: Dictionary in armies:
				if army.id in locked_ids and int(army.get("living_count", 0)) > 0: orders[str(army.id)] = {"type":"RETREAT","subject_id":army.id}
			return orders
		if available.size() < 2: return orders
		# Do not freeze both independent armies in an expensive resource muster
		# while either can already gain safe XP/bounty from a nearby weak camp.
		# Existing progressing rendezvous stays stable; only new joint missions
		# compete with this solo opportunity.
		if not _economic_expansion_needed_r9(world):
			for group:Dictionary in available:
				for camp:Dictionary in GrowthM71.candidates(world,group,_growth_cooldowns,_planning_tick):
					if camp.get("kind")!="SCATTERED" or Vector2(camp.position).distance_to(Vector2(group.anchor))>1100.0:continue
					if bool(_growth_value(world,group,camp,_local_forecast(world,group,camp.position)).safe):return orders
		available.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Opportunities.army_power(world, str(a.id)) > Opportunities.army_power(world, str(b.id)))
		var pair: Array[Dictionary] = [available[0], available[1]]
		var own := Opportunities.army_power(world, str(pair[0].id)) + Opportunities.army_power(world, str(pair[1].id))
		var closest := 9223372036854775807
		for candidate: Dictionary in world.get("sites", []):
			if candidate.get("owner") == "AI" or (not Outposts.is_resource_site(candidate) if Outposts.enabled(world) else candidate.get("kind") != "RESOURCE") or candidate.get("resource", "") == "ESSENCE": continue
			if _planning_tick < int(_joint_capture_cooldowns.get(str(candidate.id), -1)): continue
			var guards := Opportunities.camp_power(world, str(candidate.id))
			if guards <= 0 or Opportunities.local_enemy_power(world, candidate.position) + Opportunities.fortification_pressure(world,candidate.position) > 0: continue
			if own * 5 < guards * 6: continue
			if _capture_is_safe(world, pair[0], candidate) or _capture_is_safe(world, pair[1], candidate): continue
			var next := (Vector2i(candidate.position)-Vector2i(pair[0].anchor)).length_squared()
			if next < closest: site = candidate; closest = next
		if site.is_empty(): return orders
		var center := (Vector2i(pair[0].anchor) + Vector2i(pair[1].anchor)) / 2
		var direction := Vector2(center-site.position).normalized()
		var rally := Vector2i(Vector2(site.position) + direction * 430.0)
		_joint_capture = {"site_id":site.id,"army_ids":[pair[0].id,pair[1].id],"rally":rally,"started_tick":_planning_tick,"expires_tick":_planning_tick+600,"released":false}
		locked_ids = _joint_capture.army_ids
	var together := true
	for army: Dictionary in available:
		if army.id in locked_ids and (Vector2i(army.anchor)-Vector2i(_joint_capture.rally)).length_squared() > 160*160: together = false
	if together: _joint_capture.released = true
	for id: String in locked_ids:
		orders[id] = {"type":"ATTACK_MOVE","subject_id":id,"target_position":site.position if bool(_joint_capture.released) else _joint_capture.rally}
	_strategic_diagnostics["cooperative_capture"] = _joint_capture.duplicate(true)
	return orders




func _growth_value(world: Dictionary, army: Dictionary, camp: Dictionary, forecast: Dictionary) -> Dictionary:
	var benefit := GrowthM71.value(world, army, camp, forecast, _tactics.id)
	return Outposts.growth_value(world, camp, forecast, benefit, _tactics.id) if Outposts.enabled(world) else benefit


func _pressure_candidate(world: Dictionary, military: Dictionary, armies: Array[Dictionary]) -> Dictionary:
	var available := 0
	for army: Dictionary in armies:
		if int(army["living_count"]) > 0: available += 1
		# Starting limited pressure must not abandon a genuine home threat. The
		# existing defender logic can resume pressure after the threat is removed.
		if not _base_threat(world, military, army).is_empty(): return {}
	if available < 2: return {}
	var candidate := {}
	for army: Dictionary in armies:
		var raider: bool = _tactics.id == "RAIDER_HARASS"
		if int(army["living_count"]) < (2 if raider else PRESSURE_MIN_TROOPS) or (raider and int(army.living_count) > 6) or _army_hp(military, str(army["id"])) < PRESSURE_MIN_HEALTH or bool(_regrouping.get(army["id"], false)): continue
		# Prefer the even-numbered ranged group: the odd-numbered group's real
		# resource acquisition remains the first expansion chain, not a label.
		if candidate.is_empty() or (int(army.get("number",1)) % 2 == 0 and int(candidate.get("number",1)) % 2 != 0): candidate = army
	return candidate


func _pressure_order(world: Dictionary, military: Dictionary, army: Dictionary) -> Dictionary:
	# Probe the real closest military frontline, not directly bulldoze the
	# home structure. Full siege remains the distinct later commitment. Keep
	# the valid base objective so that later assault can resume its actual lock.
	var siege := _attack_base(world, military, army)
	var target := {}
	var distance := 9223372036854775807
	if _tactics.id == "RAIDER_HARASS":
		var lock := str(_raid_targets.get(str(army.id), ""))
		for worker: Dictionary in world.get("workers",[]):
			if not Opportunities.raid_safe(world, army, worker): continue
			var next: int = (Vector2i(worker.position)-Vector2i(army.anchor)).length_squared()
			# A stable victim prevents a line of moving workers from redirecting
			# a raid each decision. Re-evaluate safety before honoring the lock.
			if str(worker.id) == lock: target = worker; break
			var score := next + int(worker.hp) * 80
			if score<distance: target = worker; distance = score
		if not target.is_empty():
			_raid_targets[str(army.id)] = str(target.id)
			_strategic_diagnostics[str(army.id)] = {"role":"WORKER_RAID","target_id":target.id,"reason":"observed_exposed_worker","local_enemy_power":Opportunities.local_enemy_power(world,target.position,340)}
			return {"type":"ATTACK_MOVE","subject_id":army.id,"target_position":target.position}
		_raid_targets.erase(str(army.id))
		if Outposts.enabled(world):
			var income_raid := _outpost_income_raid(world, army)
			if not income_raid.is_empty(): return income_raid
		# A harassment group does not turn lack of an exposed worker into an
		# early frontal siege. It can clear/claim a safe objective instead.
		var capture := _capture_target(world, army, [])
		return {} if capture.is_empty() else {"type":"ATTACK_MOVE","subject_id":army.id,"target_position":capture.position}
	for enemy: Dictionary in military["soldiers"]:
		if enemy["side"] != "PLAYER" or not bool(enemy["alive"]): continue
		if (Vector2i(enemy.position)-Vector2i(army.anchor)).length_squared() > Opportunities.RAID_OBSERVATION_RADIUS * Opportunities.RAID_OBSERVATION_RADIUS: continue
		if Opportunities.local_enemy_power(world, enemy.position, 340) * 5 > Opportunities.army_power(world, str(army.id)) * 6: continue
		if Opportunities.fortification_pressure(world, enemy.position, 100) > 0: continue
		var next: int = (Vector2i(enemy["position"]) - Vector2i(army["anchor"])).length_squared()
		if next < distance:
			target = enemy
			distance = next
	return siege if target.is_empty() else _enemy_order(military, army, target)


func _outpost_income_raid(world: Dictionary, army: Dictionary) -> Dictionary:
	# With no worker bodies, harassment targets a known productive peripheral
	# mine instead. It remains an ordinary paced army order, not per-unit micro
	# or a license to dive a defended enemy home.
	var chosen: Dictionary = {}
	var best_distance := Opportunities.RAID_OBSERVATION_RADIUS * Opportunities.RAID_OBSERVATION_RADIUS + 1
	for site: Dictionary in world.get("sites", []):
		if site.get("kind") != "SATELLITE" or site.get("owner") != "PLAYER" or not bool(site.get("income_active", false)): continue
		for building: Dictionary in world.get("buildings", []):
			if building.get("side") != "PLAYER" or building.get("building_type") != "ESSENCE_MINE" or not bool(building.get("visible", true)) or not bool(building.get("complete", false)) or int(building.get("hp", 0)) <= 0: continue
			if building.get("site_id", "") != site.id and Vector2(building.position).distance_squared_to(Vector2(site.position)) > World.BASE_SITE_RADIUS * World.BASE_SITE_RADIUS: continue
			var distance: int = (Vector2i(building.position) - Vector2i(army.anchor)).length_squared()
			if distance >= best_distance or not Opportunities.siege_safe(world, army, building): continue
			var forecast := _local_forecast(world, army, building.position)
			if bool(forecast.get("truncated", false)) or float(forecast.get("ratio", 0.0)) < 1.08 or float(forecast.get("friendly_loss_fraction", 1.0)) > 0.40: continue
			chosen = building
			best_distance = distance
	if chosen.is_empty(): return {}
	_raid_targets[str(army.id)] = str(chosen.id)
	_strategic_diagnostics[str(army.id)] = {"role":"OUTPOST_INCOME_RAID", "target_id":chosen.id, "reason":"observed_productive_peripheral_mine", "reward_is_not_combat_power":true}
	return {"type":"ATTACK_BASE", "subject_id":army.id, "target_base_id":chosen.id}


static func _unit_power(unit: Dictionary) -> int:
	if not bool(unit.get("alive", false)): return 0
	var offense := int(unit.get("damage", 0)) * 160 / maxi(1, int(unit.get("attack_cooldown_ticks", 20)))
	return int(unit["hp"]) + offense + int(unit.get("armor", 0)) * 12 + mini(80, int(unit.get("attack_range", 0)) / 2) + (40 if int(unit.get("heal", 0)) > 0 or unit["unit_type"] == "grove_mender" else 0)


static func _side_power(military: Dictionary, side: String, army_id: String = "") -> int:
	var result := 0
	for unit: Dictionary in military["soldiers"]:
		if unit["side"] == side and (army_id.is_empty() or unit["warband_id"] == army_id): result += _unit_power(unit)
	return result


func _defender_ids(world: Dictionary, military: Dictionary, armies: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	var threat: Dictionary = {}
	for army: Dictionary in armies:
		threat = _base_threat(world, military, army)
		if not threat.is_empty(): break
	if threat.is_empty(): return result
	var hostile_power := 0
	for enemy: Dictionary in military["soldiers"]:
		if enemy["side"] == "PLAYER" and bool(enemy["alive"]) and (Vector2i(enemy["position"]) - Vector2i(threat["position"])).length_squared() <= 360 * 360:
			hostile_power += _unit_power(enemy)
	var remaining := armies.duplicate()
	remaining.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var a := (Vector2i(left["anchor"]) - Vector2i(threat["position"])).length_squared()
		var b := (Vector2i(right["anchor"]) - Vector2i(threat["position"])).length_squared()
		return str(left["id"]) < str(right["id"]) if a == b else a < b)
	var allocated := 0
	for army: Dictionary in remaining:
		if int(army["living_count"]) <= 0 or bool(_regrouping.get(army["id"], false)): continue
		if not _army_can_hit(military,army,threat): continue
		result.append(str(army["id"]))
		allocated += _side_power(military, "AI", str(army["id"]))
		if allocated * 4 >= hostile_power * 5: break
	return result


static func _nearby_defender(military: Dictionary, army: Dictionary) -> Dictionary:
	var best := {}
	var distance := 2147483647
	for enemy: Dictionary in military["soldiers"]:
		if enemy["side"] != "PLAYER" or not bool(enemy["alive"]) or not bool(enemy.get("visible",true)): continue
		var next := (Vector2i(enemy["position"]) - Vector2i(army["anchor"])).length_squared()
		var exposed := false
		for ally: Dictionary in military["soldiers"]:
			if ally["warband_id"] == army["id"] and bool(ally["alive"]):
				var physical := (Vector2i(enemy["position"]) - Vector2i(ally["position"])).length_squared()
				next = mini(next, physical)
				var reach := int(enemy.get("attack_range",46)) + int(ally.get("radius",14))
				exposed = exposed or physical <= reach * reach
		# Merely being inside a wide radar circle does not make a melee guard a
		# threat to the other siege army. An anchor is not a body, and predictive
		# padding is not actual enemy weapon reach. A screening army can hold
		# defenders while a genuinely unexposed force attacks the real structure.
		if exposed and next < distance:
			best = enemy
			distance = next
	return best


static func _formation_for(military: Dictionary, army: Dictionary) -> String:
	var ranged := 0
	var total := 0
	for ally: Dictionary in military["soldiers"]:
		if ally["warband_id"] == army["id"] and bool(ally["alive"]):
			total += 1
			if int(ally.get("attack_range", 0)) >= 100: ranged += 1
	return "LOOSE" if ranged * 2 >= total else "STEADY"


func _live_camp_contact_r9(world:Dictionary,army:Dictionary)->bool:
	var enemies:Dictionary={}
	for body:Dictionary in world.get("micro_neutral_targets",[]):
		if int(body.get("hp",0))>0:enemies[str(body.get("id",""))]=body
	for body:Dictionary in world.get("soldiers",[]):
		if body.get("side")!="AI" or body.get("warband_id")!=army.id or int(body.get("hp",0))<=0:continue
		var at:=int(body.get("last_action_tick",-1000000))
		if at>_planning_tick or _planning_tick-at>40 or body.get("last_action_kind","")!="ATTACK":continue
		var target:Dictionary=enemies.get(str(body.get("last_action_target_id","")),{})
		if target.is_empty() or not VisibilityR9.can_observe(target,str(world.get("planning_view_side_r9","AI"))):continue
		var reach:=int(body.get("attack_range",0))+int(target.get("radius",12))+24
		if Vector2(body.position).distance_squared_to(Vector2(target.position))<=reach*reach:return true
	return false

func _economic_expansion_needed_r9(world:Dictionary)->bool:
	if not Outposts.enabled(world):return false
	var pop:Dictionary=world.get("population",{}).get("AI",{})
	if int(pop.get("maximum",30))-int(pop.get("used",0))-int(pop.get("reserved",0))<4:return false
	return Outposts.economic_expansion_needed(world)

func _capture_target(world: Dictionary, army: Dictionary, pending: Array[Dictionary]) -> Dictionary:
	var previous := str(_army_targets.get(army["id"], ""))
	var needs_resources := _resource_urgent(world)
	var population: Dictionary = world.get("population", {}).get("AI", {})
	var needs_capacity := int(population.get("maximum", 30)) - int(population.get("used", 0)) - int(population.get("reserved", 0)) < 4
	var expansion_needed := _economic_expansion_needed_r9(world)
	for site: Dictionary in world["sites"]:
		if site.id == previous and site.get("resource","") == "ESSENCE" and not _ready_for_essence(world,army,site):
			_army_targets.erase(str(army.id))
			previous = ""
			break
	for site: Dictionary in world["sites"]:
		if site["id"] == previous and site["owner"] != "AI" and not _site_travel_cooled(world,str(site.id)) and _capture_allowed(world,site) and _capture_is_safe(world, army, site) and (not (needs_resources or expansion_needed) or (Outposts.is_resource_site(site) if Outposts.enabled(world) else site.kind == "RESOURCE")) and (site.get("resource","") != "ESSENCE" or _ready_for_essence(world,army,site)):
			return site
	var best := {}
	var best_score := 9223372036854775807
	for site: Dictionary in world["sites"]:
		if site["owner"] == "AI":
			continue
		if _site_travel_cooled(world,str(site.id)):continue
		if not _capture_allowed(world,site): continue
		if not _capture_is_safe(world, army, site): continue
		if (Outposts.is_resource_site(site) if Outposts.enabled(world) else site.kind == "RESOURCE") and site.get("resource", "") != "ESSENCE" and _source_remaining(world, str(site.id), "FOOD") <= 0 and _source_remaining(world, str(site.id), "MATERIAL") <= 0: continue
		if site.get("resource","") == "ESSENCE" and not _ready_for_essence(world,army,site): continue
		# Avoid converting nearby neutral-site exploration into an accidental
		# early home rush before the declared build-up period. Active assault is
		# a separate real BASE order, not a label on this capture command.
		var near_enemy_home := false
		for building: Dictionary in world["buildings"]:
			if building["side"] == "PLAYER" and building["building_type"] == "BASE" and int(building["hp"]) > 0 and (Vector2i(site["position"]) - Vector2i(building["position"])).length_squared() < 800 * 800:
				near_enemy_home = true
		if near_enemy_home:
			continue
		var occupied := false
		for command: Dictionary in pending:
			if command.get("target_position", Vector2i.ZERO) == site["position"]:
				occupied = true
		for other_id: String in _army_targets:
			if other_id != str(army["id"]) and _army_targets[other_id] == site["id"]:
				occupied = true
		if occupied:
			continue
		var distance := (Vector2i(site["position"]) - Vector2i(army["anchor"])).length_squared()
		# One army seeks an expansion resource; the other adds nearby capacity.
		var preferred := "RESOURCE" if int(army.get("number", 1)) % 2 == 1 else "VILLAGE"
		if _tactics.id == "EXPANSION_BOOM": preferred = "RESOURCE"
		if _tactics.id == "DEFENSIVE_COUNTER": preferred = "VILLAGE"
		if expansion_needed:preferred="RESOURCE"
		if needs_capacity: preferred = "VILLAGE"
		if needs_resources: preferred = "RESOURCE"
		var kind_penalty: int = Outposts.capture_kind_penalty(site, preferred) if Outposts.enabled(world) else (0 if site["kind"] == preferred else 1800000)
		var score: int = distance + kind_penalty + (2000000 if site["owner"] == "PLAYER" else 0)
		if _tactics.id == "SPLIT_CAPTURE" and site.owner == "PLAYER": score -= 1200000
		# Weakened perimeter holdings are cheaper than fortified home armies.
		score += Opportunities.local_enemy_power(world, site.position) * 200
		if _tactics.id == "CREEP_ESSENCE_CONTROL":
			for camp: Dictionary in world.get("neutral_camps",[]):
				if camp.get("site_id") == site.id and camp.get("state") != "CLEARED": score -= 250000
		# A small nearby discovery preference cannot bypass the candidate gates
		# above, steal another army's lock or change the army's strategic role.
		score -= _exploration_bonus(world, army, site, distance)
		if site.get("resource","") == "ESSENCE": score -= ESSENCE_SCORE_BONUS * (2 if _tactics.id == "CREEP_ESSENCE_CONTROL" else 1)
		if score < best_score:
			best = site
			best_score = score
	return best


func _site_travel_cooled(world:Dictionary,site_id:String)->bool:
	for camp:Dictionary in world.get("neutral_camps",[]):
		if camp.get("site_id")==site_id and _planning_tick<int(_growth_cooldowns.get(str(camp.get("id","")),-1)):return true
	return false


func _essence_contest_target(world: Dictionary, army: Dictionary, pending: Array[Dictionary]) -> Dictionary:
	# Reuse the same ownership, pending-target, enemy-home and EASY-cap guards.
	# Only the detached candidate list is narrowed; no public state is changed.
	var view: Dictionary = world.duplicate(false)
	view["sites"] = world.get("sites",[]).filter(func(site: Dictionary) -> bool: return int(site.get("guardian_tier", 0)) >= 3 if Outposts.enabled(world) else site.get("resource","") == "ESSENCE")
	# EASY limits still need all already-owned territory, not a truncated count.
	for site: Dictionary in world.get("sites",[]):
		if (int(site.get("guardian_tier", 0)) < 3 if Outposts.enabled(world) else site.get("resource","") != "ESSENCE") and site.get("owner","") == "AI": view.sites.append(site)
	var target := _capture_target(view,army,pending)
	return target if (int(target.get("guardian_tier", 0)) >= 3 if Outposts.enabled(world) else target.get("resource","") == "ESSENCE") else {}


func _ready_for_essence(world: Dictionary, army: Dictionary, site: Dictionary) -> bool:
	if Outposts.enabled(world): return _capture_is_safe(world, army, site)
	if _base_tier(world) < 3 or _battle_elapsed < maxi(ESSENCE_EARLIEST_TICKS,int(_policy["technology_ticks"])): return false
	if int(army.get("living_count",0)) < ESSENCE_MIN_TROOPS or _army_hp(world,str(army.id)) < ESSENCE_MIN_HEALTH: return false
	var escort := false
	for body: Dictionary in world.get("soldiers",[]):
		if body.get("side") == "AI" and body.get("warband_id") == army.id and body.get("unit_type") == "hero" and bool(body.get("alive",false)) and int(body.get("hp",0)) > 0 and body.get("movement_layer","GROUND") == "GROUND": escort = true
	if not escort: return false
	# Public camp profiles are a finite observed budget, not a hidden resource
	# grant or free damage. With no camp, the conservative troop gates remain.
	for camp: Dictionary in world.get("neutral_camps",[]):
		if camp.get("site_id") != site.id or camp.get("state") == "CLEARED": continue
		var hostile_power := 0
		for member: Dictionary in camp.get("members",[]):
			var profile: Dictionary = member.get("profile",{})
			if profile.is_empty(): continue
			var observed := profile.duplicate(false)
			observed.merge({"alive":true,"hp":int(profile.get("max_hp",0)),"unit_type":"neutral"},true)
			hostile_power += _unit_power(observed)
		if hostile_power > 0 and _side_power(world,"AI",str(army.id)) * 5 < hostile_power * 6: return false
	return true


static func _exploration_bonus(world: Dictionary, army: Dictionary, site: Dictionary, distance: int) -> int:
	if distance > EXPLORATION_NEARBY_RADIUS * EXPLORATION_NEARBY_RADIUS: return 0
	for objective: Dictionary in world.get("field_objectives", []):
		if objective.get("site_id") != site.get("id") or objective.get("state") != "AVAILABLE" or not str(objective.get("first_owner", "")).is_empty(): continue
		if objective.get("kind") not in ["SUPPLY", "ARMORY", "RELIC"]: continue
		if objective.get("kind") == "RELIC":
			var escort := false
			for unit: Dictionary in world.get("soldiers", []):
				if unit.get("side") == "AI" and unit.get("warband_id") == army.get("id") and unit.get("unit_type") == "hero" and bool(unit.get("alive", false)) and int(unit.get("hp", 0)) > 0 and unit.get("movement_layer", "GROUND") == "GROUND":
					escort = true
					break
			if not escort: return 0
		return maxi(0, EXPLORATION_SCORE_BONUS - distance / 8)
	return 0


func _capture_allowed(world: Dictionary, site: Dictionary) -> bool:
	return true


static func _development_cost(command: Dictionary, world: Dictionary) -> Dictionary:
	if command.is_empty(): return {}
	if command["type"] == "PLACE_BUILDING":
		if Outposts.enabled(world): return Outposts.slot_for_order(world, command).get("cost", {}).duplicate(true)
		return _building_recipe(world,str(command["building_type"])).get("cost",{}).duplicate(true)
	if command["type"] == "UPGRADE_TOWER":
		if world.get("catalog",{}).has("buildings"):
			return _building_recipe(world,"TOWER").get("upgrade_quote",{}).get("cost",{}).duplicate(true)
		return Economy.TOWER_UPGRADE.cost.duplicate(true)
	if command["type"] == "UPGRADE_BASE":
		for base: Dictionary in world["buildings"]:
			if base["id"] == command["building_id"]:
				return Progression.BASE_UPGRADES.get(int(base.get("base_tier", 1)) + 1, {}).get("cost", {}).duplicate(true)
	if command["type"] == "UPGRADE":
		var unique:Dictionary=preload("res://src/simulation/strategic_faction_technologies_v4.gd").lookup(str(command.get("technology","")),_faction(world))
		if not unique.is_empty():return unique.cost.duplicate(true)
		var levels: Dictionary = world.get("technology", {}).get("AI", {})
		var level := int(levels.get(command["technology"], 0)) + 1
		return Economy.tech_quote(str(command.technology),level).get("cost",{}).duplicate(true)
	return {}


static func _development_key(command: Dictionary) -> String:
	return "%s:%s:%s" % [command.get("type",""),command.get("building_type",command.get("technology","")),command.get("building_id","")]


static func _order_cost(world: Dictionary, command: Dictionary) -> Dictionary:
	if command.get("type") == "ENQUEUE_UNIT":
		return (_hero_quote(world,str(command.get("hero_archetype",""))) if command.get("unit_type") == "hero" else _recipe(str(command.unit_type))).get("cost",{}).duplicate(true)
	if command.get("type") == "BUY_ITEM":
		for hero: Dictionary in world.get("heroes",{}).get("officers",[]):
			if hero.get("id")==command.get("unit_id"):return HeroItems.purchase_quote(hero,str(command.get("item_id",""))).get("cost",{}).duplicate(true)
	return _development_cost(command,world)


func _attack_base(world: Dictionary, military: Dictionary, army: Dictionary) -> Dictionary:
	var best := {}
	var distance := 9223372036854775807
	var locked := str(_siege_targets.get(army["id"], ""))
	for building: Dictionary in world["buildings"]:
		if building["id"] == locked and building["side"] == "PLAYER" and building["building_type"] == "BASE" and int(building["hp"]) > 0 and bool(building["complete"]):
			if Opportunities.siege_safe(world, army, building): return {"type": "ATTACK_BASE", "subject_id": army["id"], "target_base_id": locked}
			_siege_targets.erase(str(army.id))
	for building: Dictionary in world["buildings"]:
		if building["side"] != "PLAYER" or building["building_type"] != "BASE" or int(building["hp"]) <= 0 or not bool(building["complete"]):
			continue
		if not Opportunities.siege_safe(world, army, building): continue
		var next: int = (Vector2i(building["position"]) - Vector2i(army["anchor"])).length_squared()
		if next < distance:
			best = building
			distance = next
	if not best.is_empty():
		_siege_targets[str(army["id"])] = str(best["id"])
		return {"type": "ATTACK_BASE", "subject_id": army["id"], "target_base_id": best["id"]}
	# The win condition includes surviving military, not only structures. After
	# the last real base falls, finish that actual remaining army through FOCUS.
	var any_base := false
	for building: Dictionary in world.get("buildings", []):
		if building.get("side") == "PLAYER" and building.get("building_type") == "BASE" and int(building.get("hp",0)) > 0: any_base = true
	if any_base:
		_strategic_diagnostics[str(army.id)] = {"role":"REGROUP_OR_CAPTURE","reason":"no_safe_base_assault","own_power":Opportunities.army_power(world,str(army.id))}
		return {}
	for enemy: Dictionary in military["soldiers"]:
		if enemy["side"] != "PLAYER" or not bool(enemy["alive"]): continue
		var next: int = (Vector2i(enemy["position"]) - Vector2i(army["anchor"])).length_squared()
		if next < distance:
			best = enemy
			distance = next
	return {} if best.is_empty() else _enemy_order(military, army, best)


static func _enemy_order(military: Dictionary, army: Dictionary, enemy: Dictionary) -> Dictionary:
	# Reserve pools have real attackable physical soldiers, but are intentionally
	# not FOCUS-commandable armies. Use a legal macro attack-move instead of
	# weakening combat's reserve contract or controlling an individual soldier.
	for target: Dictionary in military["warbands"]:
		if target["id"] == enemy.get("warband_id","") and not bool(target.get("reserve", false)):
			return {"type": "FOCUS", "subject_id": army["id"], "target_warband_id": enemy["warband_id"]}
	return {"type": "ATTACK_MOVE", "subject_id": army["id"], "target_position": enemy["position"]}


func _m94_begin_threat_scope() -> void:
	# Only the completed detached inputs of one synchronous plan may be borrowed.
	# Host command execution happens after the scope ends, never inside it.
	_m94_threat_cache.clear()
	_m96_threat_frames.clear()
	_m96_threat_work={"prepares":0,"pair_checks":0}
	_m95_force_frames.clear()
	_resolved_threat_orders.clear()
	_m95_force_frame_serial = 0
	_m94_threat_scope_active = true


func _m94_end_threat_scope() -> void:
	_m94_threat_scope_active = false
	_m94_threat_cache.clear()
	_m96_threat_frames.clear()
	_m95_force_frames.clear()
	_resolved_threat_orders.clear()
	_m95_force_frame_serial = 0


func _base_threat(world: Dictionary, military: Dictionary, army: Dictionary, allow_base_recall: bool = true) -> Dictionary:
	if not _m94_threat_scope_active:
		return _base_threat_uncached_m94(world, military, army, allow_base_recall)
	for entry: Dictionary in _m94_threat_cache:
		if is_same(entry.world, world) and is_same(entry.military, military) and is_same(entry.army, army) and bool(entry.allow_base_recall) == allow_base_recall:
			# Callers keep the original independent-result contract, including
			# empty threats. No diagnostic counter or public AI work is changed.
			return entry.result.duplicate(true)
	var result:Dictionary=ThreatFrameM96.select(_m96_threat_frame(world,military),army,allow_base_recall)
	if _m94_threat_cache.size() < 64:
		_m94_threat_cache.append({"world":world,"military":military,"army":army,"allow_base_recall":allow_base_recall,"result":result.duplicate(true)})
	return result


func _m96_threat_frame(world:Dictionary,military:Dictionary)->Dictionary:
	for entry:Dictionary in _m96_threat_frames:
		if is_same(entry.world,world) and is_same(entry.military,military):return entry.frame
	var frame:Dictionary=ThreatFrameM96.prepare(world,military,_planning_tick)
	_m96_threat_work.prepares+=1
	_m96_threat_work.pair_checks+=int(frame.work.pair_checks)
	if _m94_threat_scope_active and _m96_threat_frames.size()<8:_m96_threat_frames.append({"world":world,"military":military,"frame":frame})
	return frame


func _m96_locked_threat(world:Dictionary,military:Dictionary,army:Dictionary,enemy_id:String,allow_base_recall:bool)->Dictionary:
	# The old isolated observations retained the identical own victims/layers;
	# only the hostile ID was filtered. Reuse that exact ordered relation.
	if _m94_threat_scope_active:return ThreatFrameM96.select(_m96_threat_frame(world,military),army,allow_base_recall,enemy_id)
	var isolated:=military.duplicate(false)
	isolated["soldiers"]=military.get("soldiers",[]).filter(func(body:Dictionary)->bool:return body.get("side")=="AI" or body.get("id")==enemy_id)
	var isolated_world:=world.duplicate(false)
	for key:String in ["buildings","workers","micro_neutral_targets"]:
		isolated_world[key]=world.get(key,[]).filter(func(body:Dictionary)->bool:return body.get("side")=="AI" or body.get("id")==enemy_id) if key!="micro_neutral_targets" else world.get(key,[]).filter(func(body:Dictionary)->bool:return body.get("id")==enemy_id)
	return _base_threat_uncached_m94(isolated_world,isolated,army,allow_base_recall)


func _base_threat_uncached_m94(world: Dictionary, military: Dictionary, army: Dictionary, allow_base_recall: bool = true) -> Dictionary:
	var best: Dictionary = {}
	var distance := 9223372036854775807
	var victims: Array = military.get("soldiers", []).duplicate()
	victims.append_array(world.get("workers", [])); victims.append_array(world.get("buildings", []))
	# Parallel immutable values avoid re-reading the same victim dictionaries
	# for every weapon pair. Preserve the original concatenation/filter order.
	var eligible: Array[Dictionary] = []
	var positions: Array[Vector2i] = []
	var living_values: Array[bool] = []
	var recent_values: Array[bool] = []
	var sources: Array[String] = []
	var radii: Array[int] = []
	var victim_layers: Array[String] = []
	for victim: Dictionary in victims:
		if victim.get("side") != "AI": continue
		if (victim.get("building_type", "") != "BASE" or not allow_base_recall) and (Vector2i(victim.position) - Vector2i(army.anchor)).length_squared() > 420 * 420: continue
		var living: bool = bool(victim.get("alive", true)) and int(victim.get("hp", 1)) > 0
		if living and not bool(victim.get("attackable", true)): continue
		var damage_tick := int(victim.get("last_damage_tick", -1))
		var recent: bool = damage_tick >= 0 and damage_tick <= _planning_tick and _planning_tick - damage_tick <= 60
		if not living and (not recent or int(victim.get("last_damage_amount", 0)) <= 0): continue
		eligible.append(victim)
		positions.append(Vector2i(victim.position)); living_values.append(living)
		recent_values.append(recent); sources.append(str(victim.get("last_damage_source_id", "")))
		radii.append(int(victim.get("radius", 14))); victim_layers.append(str(victim.get("movement_layer", "GROUND")))
	if eligible.is_empty(): return best
	var layers: Dictionary = {}
	for ally: Dictionary in military.get("soldiers", []):
		if ally.get("side") == "AI" and ally.get("warband_id") == army.get("id") and bool(ally.get("alive", true)) and int(ally.get("hp", 1)) > 0:
			for layer: Variant in ally.get("attack_layers", ["GROUND"]): layers[layer] = true
	if layers.is_empty(): return best
	var hostiles: Array = military.get("soldiers", []).duplicate()
	hostiles.append_array(world.get("buildings", [])); hostiles.append_array(world.get("workers", [])); hostiles.append_array(world.get("micro_neutral_targets", []))
	for enemy: Dictionary in hostiles:
		if enemy.get("side") not in ["PLAYER", "NEUTRAL"] or not bool(enemy.get("alive", true)) or int(enemy.get("hp", 1)) <= 0 or not bool(enemy.get("visible", true)): continue
		if not layers.has(enemy.get("movement_layer", "GROUND")): continue
		var enemy_position := Vector2i(enemy.position)
		var next: int = (enemy_position - Vector2i(army.anchor)).length_squared()
		if next >= distance: continue
		var enemy_id := str(enemy.get("id", ""))
		var neutral: bool = enemy.get("side") == "NEUTRAL"
		var structure: bool = enemy.has("building_type")
		var weapon: bool = int(enemy.get("damage", 1)) > 0 and (not structure or bool(enemy.get("complete", false)) and bool(enemy.get("defense_active", false)))
		var attack_layers: Array = ["GROUND", "AIR"] if structure else enemy.get("attack_layers", ["GROUND"])
		var base_reach := int(enemy.get("attack_range", 0))
		var adds_radius: bool = not structure and enemy.get("unit_type", "") != "worker"
		for index: int in range(eligible.size()):
			var recently_hit: bool = recent_values[index] and sources[index] == enemy_id
			# Dead recent victims survive as alarm anchors, never weapon targets.
			if not living_values[index] and not recently_hit: continue
			var covers := false
			if living_values[index] and weapon and victim_layers[index] in attack_layers:
				var reach: int = base_reach + (radii[index] if adds_radius else 0)
				covers = reach > 0 and (enemy_position - positions[index]).length_squared() <= reach * reach
			if not recently_hit and not covers: continue
			# This read-only predicate is deliberately deferred until a pair can
			# matter. It does not mutate neutral state or planner diagnostics.
			if neutral and not NeutralThreatM73.alarm_can_engage(enemy, eligible[index], _planning_tick): continue
			best = enemy.duplicate(true); best["defense_anchor"] = eligible[index].position; best["threat_active"] = true
			distance = next
			break
	return best

static func _weapon_covers(enemy:Dictionary,victim:Dictionary)->bool:
	if int(enemy.get("damage",1))<=0:return false
	var structure:bool=enemy.has("building_type")
	if structure and (not bool(enemy.get("complete",false)) or not bool(enemy.get("defense_active",false))):return false
	# World guns fire at both actual layers and use center distance. Worker
	# defense is ground-only and also uses center distance. Only Combat's
	# military weapon settlement adds the target's body radius.
	var layers:Array=["GROUND","AIR"] if structure else enemy.get("attack_layers",["GROUND"])
	if victim.get("movement_layer","GROUND") not in layers:return false
	var reach:int=int(enemy.get("attack_range",0))
	if not structure and enemy.get("unit_type","")!="worker":reach+=int(victim.get("radius",14))
	return reach>0 and (Vector2i(enemy.position)-Vector2i(victim.position)).length_squared()<=reach*reach


static func _army_can_hit(military: Dictionary, army: Dictionary, enemy: Dictionary) -> bool:
	for ally: Dictionary in military.get("soldiers",[]):
		if ally.get("side") == "AI" and ally.get("warband_id") == army.get("id") and bool(ally.get("alive",true)) and int(ally.get("hp",1)) > 0 and enemy.get("movement_layer","GROUND") in ally.get("attack_layers",["GROUND"]): return true
	return false


func _threat_order(world: Dictionary, military: Dictionary, army: Dictionary, allow_base_recall: bool = true) -> Dictionary:
	var id := str(army.id)
	if _local_battle_states.get(id,{}).get("phase")=="WITHDRAW":return _local_battle_order(world,military,army,{})
	# Explicit retreat remains travel-only until its real safe destination.
	if army.get("intent") == "RETREAT":
		_threat_locks.erase(id)
		_resume_orders.erase(id)
		if not _at_safe_refuge(world,army): return {}
	var fresh := _base_threat(world,military,army,allow_base_recall)
	var own_front := _r9_formation_threat(world,military,army)
	if not own_front.is_empty(): fresh = own_front
	var lock: Dictionary = _threat_locks.get(id,{})
	if lock.is_empty() and not fresh.is_empty():
		lock = {"enemy_id":fresh.id,"anchor":fresh.defense_anchor,"locked_tick":_planning_tick,"last_active_tick":_planning_tick,"previous_order":_resume_orders.get(id,_resume_order(army)).duplicate(true),"response_applied":false}
		_resume_orders.erase(id)
		_threat_locks[id] = lock
	if lock.is_empty():
		var pending: Dictionary = _resume_orders.get(id,{})
		if not pending.is_empty() and (_already_ordered(army,pending) or not _resume_valid(pending,world,military)): _resume_orders.erase(id); return {}
		return pending.duplicate(true)
	var enemy := {}
	for body: Dictionary in military.get("soldiers",[])+world.get("buildings",[])+world.get("workers",[])+world.get("micro_neutral_targets",[]):
		if body.get("id") == lock.enemy_id and body.get("side") in ["PLAYER","NEUTRAL"] and bool(body.get("alive",true)) and int(body.get("hp",1)) > 0 and bool(body.get("visible",true)): enemy = body; break
	var valid := not enemy.is_empty() and _army_can_hit(military,army,enemy) and (Vector2i(enemy.position)-Vector2i(lock.anchor)).length_squared() <= 420*420
	if valid:
		if not _m96_locked_threat(world,military,army,str(lock.enemy_id),allow_base_recall).is_empty() or not _r9_formation_threat(world,military,army,str(lock.enemy_id)).is_empty(): lock.last_active_tick = _planning_tick
	var clear := _planning_tick-int(lock.locked_tick) >= 80 and _planning_tick-int(lock.last_active_tick) >= 60
	if not valid or clear:
		_threat_locks.erase(id)
		var resume: Dictionary = lock.get("previous_order",{})
		if not _resume_valid(resume,world,military): return {}
		_resume_orders[id] = resume.duplicate(true)
		return resume
	var response:Dictionary={"type":"ATTACK_BASE","subject_id":id,"target_base_id":enemy.id} if enemy.has("building_type") else _enemy_order(military,army,enemy)
	response=_local_battle_order(world,military,army,response,true)
	lock["response_order"]=response.duplicate(true)
	return response


func _r9_formation_threat(world:Dictionary,military:Dictionary,army:Dictionary,enemy_id:String="")->Dictionary:
	# Reuse this observation's real damage / weapon relationships. A stretched
	# member is still part of its formation, although outside the generic420px
	# local-protection circle. Bound the formation window at the existing local
	# estimator's720px radius; the defense lock still limits chasing to420px.
	var frame:=_m96_threat_frame(world,military)
	var layers:Dictionary=frame.layers_by_army.get(army.get("id"),{})
	var best:Dictionary={};var distance:=INF
	for alarm:Dictionary in frame.alarms:
		if not enemy_id.is_empty() and alarm.id!=enemy_id:continue
		if not layers.has(alarm.layer):continue
		for index:int in alarm.victims:
			var victim:Dictionary=frame.victims[index]
			if victim.body.get("warband_id","")!=army.get("id") or victim.body.get("side")!="AI":continue
			if Vector2(victim.position).distance_squared_to(Vector2(army.anchor))>LocalBattle.LOCAL_RADIUS*LocalBattle.LOCAL_RADIUS:continue
			var next:=Vector2(alarm.position).distance_squared_to(Vector2(victim.position))
			if next>=distance:continue
			best=alarm.body.duplicate(true);best["defense_anchor"]=victim.position;best["threat_active"]=true;best["formation_alert_r9"]=true;distance=next
	return best


static func _resume_order(army: Dictionary) -> Dictionary:
	var result := {"type":army.get("intent","HOLD"),"subject_id":army.id}
	match str(result.type):
		"ATTACK_BASE": result["target_base_id"] = army.get("target_base_id","")
		"FOCUS": result["target_warband_id"] = army.get("target_warband_id","")
		"MOVE", "ATTACK_MOVE": result["target_position"] = army.get("destination",army.anchor)
		_: return {"type":"STOP","subject_id":army.id}
	return result


static func _resume_valid(order: Dictionary, world: Dictionary, military: Dictionary) -> bool:
	if order.get("type") == "ATTACK_BASE":
		for building: Dictionary in world.get("buildings",[]):
			if building.get("id") == order.get("target_base_id") and building.get("side") == "PLAYER" and int(building.get("hp",0))>0 and bool(building.get("attackable",true)): return true
		return false
	if order.get("type") == "FOCUS":
		for body: Dictionary in military.get("soldiers",[]):
			if body.get("warband_id") == order.get("target_warband_id") and body.get("side") == "PLAYER" and bool(body.get("alive",false)): return true
		return false
	return not order.is_empty()


func _reaction_actions(world: Dictionary, military: Dictionary, armies: Array[Dictionary]) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var defenders := _defender_ids(world,military,armies)
	for army: Dictionary in armies:
		if int(army.get("living_count",0)) <= 0:
			_threat_locks.erase(str(army.id)); _resume_orders.erase(str(army.id)); continue
		var order := _threat_order(world,military,army,str(army.id) in defenders)
		if order.is_empty() and army.get("intent") == "RETREAT" and _at_safe_refuge(world,army):
			_regrouping.erase(str(army.id))
			order = {"type":"STOP","subject_id":army.id}
		if not _threat_locks.has(str(army.id)):order=_journey_order(world,army,order)
		order=_local_battle_order(world,military,army,order,true)
		if not order.is_empty() and not _already_ordered(army,order): commands.append(order)
	return commands


func _local_forecast(world:Dictionary,army:Dictionary,point:Vector2i,project:bool=true,army_ids:Array=[],resume_macro_hold:bool=false)->Dictionary:
	var ids:Array=[str(army.id)] if army_ids.is_empty() else army_ids
	var frame: Dictionary=_m95_force_frame(world)
	var key:="%s:%s:%s:%s:%s:%s"%[army.id,point,project,ids,resume_macro_hold,frame.get("scope_id",-1)]
	if _local_battle_cache_active and _local_battle_cache.has(key):
		_local_battle_work.cache_hits+=1
		return _local_battle_cache[key].duplicate(true)
	# Resume is local eligibility, not a second whole-soldier observation copy.
	# Only the commanded army's macro holds may be released by this proposal.
	var result:=LocalBattle.estimate(world,army,point,{"project":project,"army_ids":ids,"resume_macro_hold":resume_macro_hold,"frame":frame})
	_local_battle_work.queries+=1
	if _local_battle_cache_active and _local_battle_cache.size()<128:_local_battle_cache[key]=result.duplicate(true)
	return result


func _m95_force_frame(world:Dictionary)->Dictionary:
	if not _local_battle_cache_active:return {}
	for entry:Dictionary in _m95_force_frames:
		if is_same(entry.world,world):return entry.frame
	var frame:Dictionary=LocalBattle.prepare(world)
	frame["scope_id"]=_m95_force_frame_serial
	_m95_force_frame_serial+=1
	# A bounded set of exact detached projections, cleared before Host commands.
	# Counterfactual future worlds cannot borrow another observation's profile.
	if _m95_force_frames.size()<8:_m95_force_frames.append({"world":world,"frame":frame})
	return frame


func _local_battle_order(world:Dictionary,military:Dictionary,army:Dictionary,proposed:Dictionary,active_threat:bool=false)->Dictionary:
	# A real-position threat response has already passed this gate. Do not
	# reinterpret the exact resolved order as a new projected march when the
	# outer macro/reaction loop sees it again in the SAME immutable plan.
	# Unchecked resume orders, changed destinations and new observations miss.
	if _local_battle_cache_active:
		for resolved:Dictionary in _resolved_threat_orders:
			if is_same(resolved.world,world) and is_same(resolved.military,military) and is_same(resolved.army,army) and resolved.order==proposed:
				return resolved.order.duplicate(true)
	var result:=_evaluate_local_battle_order(world,military,army,proposed,active_threat)
	# Never memo travel/withdrawal: safe destinations must still be revalidated.
	if _local_battle_cache_active and active_threat and result.get("type") in ["FOCUS","ATTACK_MOVE","ATTACK_BASE"] and _resolved_threat_orders.size()<128:
		_resolved_threat_orders.append({"world":world,"military":military,"army":army,"order":result.duplicate(true)})
	return result


func _evaluate_local_battle_order(world:Dictionary,military:Dictionary,army:Dictionary,proposed:Dictionary,active_threat:bool=false)->Dictionary:
	var id:=str(army.id)
	if army.get("side","AI")!="AI":return proposed
	var state:Dictionary=_local_battle_states.get(id,{})
	if state.get("phase")=="WITHDRAW":
		var old_journey:Dictionary=state.get("restore_journey",{})
		if not old_journey.is_empty():
			var locally_clear:=_rally_safe(world,Vector2i(army.anchor)) and _base_threat(world,military,army,false).is_empty()
			if not locally_clear:state["clear_since"]=-1
			elif int(state.get("clear_since",-1))<0:state["clear_since"]=_planning_tick
			var destination:Vector2i=old_journey.get("target_position",army.anchor)
			if locally_clear and _planning_tick-int(state.get("clear_since",_planning_tick))>=60 and _resume_valid(old_journey,world,military) and _local_point_clear(world,destination) and _rally_safe(world,destination):
				_local_battle_states.erase(id)
				_threat_locks.erase(id)
				_resume_orders[id]=old_journey.duplicate(true)
				_local_battle_diagnostics[id]={"phase":"RESTORE_SAFE_JOURNEY","tick":_planning_tick,"reason":"three_real_seconds_without_local_threat","order":old_journey.duplicate(true)}
				return old_journey.duplicate(true)
		if not _rally_safe(world,Vector2i(state.point)) or not _local_point_clear(world,Vector2i(state.point)):
			return _local_withdraw(world,army,"SAFE_POINT_CHANGED")
		if (Vector2i(army.anchor)-Vector2i(state.point)).length_squared()>160*160:
			return state.order.duplicate(true)
		_local_battle_states.erase(id)
		_local_battle_diagnostics[id]={"phase":"ARRIVED_SAFE_POINT","tick":_planning_tick,"reason":"withdrawal_travel_completed"}
		# End the travel-only state before fresh defense/occupation. A future
		# real threat is evaluated anew; never preserve permanent non-attack.
		return {"type":"STOP","subject_id":id}
	if proposed.get("type")=="RETREAT":return proposed
	if state.get("phase")=="RENDEZVOUS":
		var partner:Dictionary={}
		for group:Dictionary in _armies(military):
			if group.id==state.partner and int(group.get("living_count",0))>0:partner=group;break
		var expired:=_planning_tick>=int(state.until_tick) or partner.is_empty()
		var safe:=_rally_safe(world,Vector2i(state.point))
		if expired or not safe:
			_local_battle_states.erase(id)
			return _local_withdraw(world,army,"RENDEZVOUS_INVALIDATED")
		var arrived:bool=(Vector2i(army.anchor)-Vector2i(state.point)).length_squared()<=140*140 and (Vector2i(partner.anchor)-Vector2i(state.point)).length_squared()<=140*140
		var partner_state:Dictionary=_local_battle_states.get(str(partner.id),{})
		if not arrived or int(state.get("accepted_tick",-1))<0 or int(partner_state.get("accepted_tick",-1))<0:return {"type":"MOVE","subject_id":id,"target_position":state.point}
		var resumed:Dictionary=state.get("resume",proposed).duplicate(true)
		_local_battle_states[id]={"phase":"JOINED","until_tick":_planning_tick+80,"partner":partner.id,"resume":resumed.duplicate(true)}
		_local_battle_states[str(partner.id)]={"phase":"JOINED","until_tick":_planning_tick+80,"partner":id,"resume":resumed.merged({"subject_id":partner.id},true)}
		state=_local_battle_states[id]
		_local_battle_diagnostics[id]={"phase":"RENDEZVOUS_COMPLETE","tick":_planning_tick,"partner":partner.id,"reason":"real_both_armies_arrived"}
		proposed=resumed
	if state.get("phase")=="JOINED" and proposed.is_empty():proposed=state.get("resume",{}).duplicate(true)
	if proposed.is_empty() and army.get("intent","") in ["FOCUS","ATTACK_MOVE","ATTACK_BASE"]:proposed=_resume_order(army)
	if proposed.get("type","") not in ["FOCUS","ATTACK_MOVE","ATTACK_BASE"]:return proposed
	var point:Vector2i=army.anchor
	if proposed.get("type")=="ATTACK_MOVE":point=proposed.target_position
	elif proposed.get("type")=="ATTACK_BASE":
		var found:=false
		for building:Dictionary in world.get("buildings",[]):
			if building.get("id")==proposed.get("target_base_id") and bool(building.get("visible",true)):point=building.position;found=true;break
		if not found:return {}
	elif proposed.get("type")=="FOCUS":
		var nearest:=INF
		for body:Dictionary in military.get("soldiers",[]):
			if body.get("warband_id")!=proposed.get("target_warband_id") or int(body.get("hp",0))<=0 or not bool(body.get("visible",true)):continue
			var distance:=Vector2(body.position).distance_squared_to(Vector2(army.anchor))
			if distance<nearest:nearest=distance;point=body.position
		if nearest==INF:return {}
	# A reaction samples actual current bodies; a newly issued objective also
	# evaluates the location into which it would commit this one army.
	var nearby_cohort:Array=[id]
	if _planning_tick<int(state.get("until_tick",-1)) and state.has("partner"):
		for group:Dictionary in _armies(military):
			if group.id==state.partner and group.get("intent")!="RETREAT" and _local_battle_states.get(str(group.id),{}).get("phase")!="WITHDRAW" and (Vector2i(group.anchor)-Vector2i(army.anchor)).length_squared()<=200*200:nearby_cohort.append(str(group.id));break
	var forecast:=_local_forecast(world,army,point,not active_threat,nearby_cohort,active_threat)
	if int(forecast.enemy_count)==0:return proposed
	if int(forecast.friendly_count)==0:
		_local_battle_diagnostics[id]={"phase":"NO_AVAILABLE_LOCAL_FORCE","tick":_planning_tick,"forecast":forecast,"reason":"defer_new_march_without_overriding_independent_body_travel"}
		return {}
	var ratio:=float(forecast.ratio)
	var severe:=ratio<0.62 or (float(forecast.friendly_loss_fraction)>.75 and float(forecast.enemy_loss_fraction)<.40)
	var committed:bool=state.get("phase")=="ENGAGE" and _planning_tick<int(state.get("until_tick",-1))
	var floor:=0.82 if active_threat or committed else (1.08 if _tactics.id in ["RAIDER_HARASS","EXPANSION_BOOM","DEFENSIVE_COUNTER"] else 1.0)
	var growth:Dictionary=_growth_targets.get(id,{})
	if not active_threat and not growth.is_empty() and Vector2i(growth.point)==point:floor=minf(floor,float(growth.get("risk_floor",floor)))
	if bool(forecast.truncated):floor=maxf(floor,1.2)
	_local_battle_diagnostics[id]={"phase":"ENGAGE" if ratio>=floor else "DISENGAGE","tick":_planning_tick,"forecast":forecast,"threshold":floor,"severe":severe,"committed":committed,"tactic":_tactics.id}
	if ratio>=floor or committed and not severe:
		_local_battle_states[id]={"phase":"ENGAGE","until_tick":int(state.until_tick) if committed else _planning_tick+80,"point":point}
		if nearby_cohort.size()>1:_local_battle_states[id]["partner"]=nearby_cohort[1]
		return proposed
	# Severe local danger interrupts immediately. A nearby partner is useful
	# only after a real rendezvous, not as a remote strength loan.
	var rally:=_local_rendezvous(world,military,army,point,proposed)
	if not rally.is_empty():return rally
	return _local_withdraw(world,army,"SEVERE_LOCAL_RISK" if severe else "UNFAVORABLE_LOCAL_EXCHANGE")


func _local_withdraw(world:Dictionary,army:Dictionary,reason:String)->Dictionary:
	var point:=_local_safe_point(world,army)
	if (Vector2i(army.anchor)-point).length_squared()<=160*160:
		# Rejecting a distant unsafe objective does not require another escape
		# journey when already at a verified safe refuge. Repeated MOVE/STOP
		# cycles used to consume EASY's only shared command slot indefinitely.
		_local_battle_states.erase(str(army.id))
		if not _local_battle_diagnostics.has(str(army.id)):_local_battle_diagnostics[str(army.id)]={}
		_local_battle_diagnostics[str(army.id)].merge({"decision":"HOLD_SAFE","reason":reason,"safe_point":point},true)
		return {"type":"STOP","subject_id":army.id}
	var command:Dictionary={"type":"RETREAT","subject_id":army.id}
	if point!=Vector2i(army.get("home_anchor",point)):command={"type":"MOVE","subject_id":army.id,"target_position":point}
	_local_battle_states[str(army.id)]={"phase":"WITHDRAW","point":point,"order":command.duplicate(true),"started_tick":_planning_tick}
	var previous:Dictionary=_threat_locks.get(str(army.id),{}).get("previous_order",{})
	# Never restore the aggressive objective that was just judged unsafe. A
	# pre-existing noncombat journey may resume only after three actually clear
	# seconds plus fresh endpoint validation in the withdrawal branch above.
	if previous.get("type") in ["MOVE","STOP"]:_local_battle_states[str(army.id)]["restore_journey"]=previous.duplicate(true)
	if not _local_battle_diagnostics.has(str(army.id)):_local_battle_diagnostics[str(army.id)]={}
	_local_battle_diagnostics[str(army.id)].merge({"decision":"WITHDRAW","reason":reason,"safe_point":point},true)
	_threat_locks.erase(str(army.id));_resume_orders.erase(str(army.id))
	return command


static func _local_point_clear(world:Dictionary,point:Vector2i)->bool:
	# Formation anchors cannot target the center of their own solid base.
	# Ignore transient friendly bodies here; the real separation solver owns
	# those, while terrain/building passability remains authoritative.
	var bounds:Rect2i=world.get("match_setup",{}).get("bounds",World.BOUNDS)
	var obstacles:Array=[]
	for building:Dictionary in world.get("buildings",[]):
		if int(building.get("hp",0))>0:obstacles.append({"position":building.position,"radius":int(building.get("radius",40)),"blocks_ground":true})
	for prop:Dictionary in world.get("terrain",[]):
		if bool(prop.get("blocks_ground",false)):obstacles.append(prop)
	return LocalNavigation.point_clear(point,24,bounds,obstacles)


static func _local_safe_point(world:Dictionary,army:Dictionary)->Vector2i:
	var homes:Array[Vector2i]=[Vector2i(army.get("home_anchor",army.anchor))]
	var bases:Array[Dictionary]=[]
	for base:Dictionary in world.get("buildings",[]):
		if base.get("side")=="AI" and base.get("building_type")=="BASE" and int(base.get("hp",0))>0 and bool(base.get("complete",false)):bases.append(base)
	bases.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return Vector2(a.position).distance_squared_to(Vector2(army.anchor))<Vector2(b.position).distance_squared_to(Vector2(army.anchor)))
	for base:Dictionary in bases.slice(0,3):
		for direction:Vector2i in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(1,1)]:homes.append(Vector2i(base.position)+direction*(int(base.get("radius",40))+100))
	var best:=Vector2i(army.get("home_anchor",army.anchor));var cost:=INF
	for point:Vector2i in homes:
		if not _local_point_clear(world,point) or not _rally_safe(world,point):continue
		var next:=Vector2(point).distance_squared_to(Vector2(army.anchor))
		# A safe endpoint behind enemy weapons is not a free safe route. Penalize
		# observable approach exposure; actual navigation still owns movement.
		for step:int in [1,2,3]:
			var sample:=Vector2i(Vector2(army.anchor).lerp(Vector2(point),float(step)/4.0))
			if not _rally_safe(world,sample):next+=4000000.0
		if next<cost:cost=next;best=point
	return best


func _local_rendezvous(world:Dictionary,military:Dictionary,army:Dictionary,point:Vector2i,resume:Dictionary)->Dictionary:
	var candidates:=_armies(military)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return Vector2(a.anchor).distance_squared_to(Vector2(army.anchor))<Vector2(b.anchor).distance_squared_to(Vector2(army.anchor)))
	for partner:Dictionary in candidates:
		if partner.id==army.id or int(partner.get("living_count",0))<=0 or partner.get("intent")=="RETREAT" or _local_battle_states.get(str(partner.id),{}).get("phase") in ["WITHDRAW","RENDEZVOUS"]:continue
		var separation:=Vector2(partner.anchor).distance_to(Vector2(army.anchor))
		if separation<180.0 or separation>650.0:continue
		var combined:=_local_forecast(world,army,point,true,[str(army.id),str(partner.id)])
		if float(combined.ratio)<1.12 or bool(combined.truncated):continue
		var midpoint:Vector2i=(Vector2i(army.anchor)+Vector2i(partner.anchor))/2
		var home:=_safe_anchor(world,army)
		var direction:=Vector2(home-midpoint).normalized()
		for rally:Vector2i in [midpoint+Vector2i(direction*180.0),midpoint,home]:
			if not _rally_safe(world,rally) or not _local_point_clear(world,rally):continue
			var proposal_until:=_planning_tick+maxi(40,int(_policy.decision_ticks)*2)
			_local_battle_states[str(army.id)]={"phase":"RENDEZVOUS","point":rally,"partner":partner.id,"accepted_tick":-1,"until_tick":proposal_until,"resume":resume.duplicate(true)}
			_local_battle_states[str(partner.id)]={"phase":"RENDEZVOUS","point":rally,"partner":army.id,"accepted_tick":-1,"until_tick":proposal_until,"resume":resume.merged({"subject_id":partner.id},true)}
			_local_battle_diagnostics[str(army.id)].merge({"decision":"RENDEZVOUS","partner":partner.id,"rally":rally,"combined_future_forecast":combined,"not_yet_present":true},true)
			return {"type":"MOVE","subject_id":army.id,"target_position":rally}
	return {}


static func _rally_safe(world:Dictionary,point:Vector2i)->bool:
	for enemy:Dictionary in world.get("soldiers",[])+world.get("buildings",[])+world.get("micro_neutral_targets",[]):
		if enemy.get("side") not in ["PLAYER","NEUTRAL"] or int(enemy.get("hp",0))<=0 or not bool(enemy.get("visible",true)):continue
		if enemy.has("building_type") and (not bool(enemy.get("complete",false)) or not bool(enemy.get("defense_active",false))):continue
		var reach:=int(enemy.get("attack_range",0))+100
		if float(enemy.get("damage",0))>0 and (Vector2i(enemy.position)-point).length_squared()<=reach*reach:return false
	return true


static func _safe_anchor(world: Dictionary, army: Dictionary) -> Vector2i:
	var best := Vector2i(army.get("home_anchor",army.anchor))
	var distance := 9223372036854775807
	for base: Dictionary in world.get("buildings",[]):
		if base.get("side") != "AI" or base.get("building_type") != "BASE" or int(base.get("hp",0)) <= 0 or not bool(base.get("complete",false)): continue
		var next: int = (Vector2i(base.position)-Vector2i(army.anchor)).length_squared()
		if next < distance: best = base.position; distance = next
	return best


static func _at_safe_refuge(world:Dictionary,army:Dictionary)->bool:
	if (Vector2i(army.anchor)-_safe_anchor(world,army)).length_squared()<=160*160:return true
	# RETREAT is a Host journey to the formation's actual legal home, not to
	# the solid BASE center. Native landing points can be >160 from that center.
	if army.get("intent")!="RETREAT":return false
	var landing:=Vector2i(army.get("destination",army.get("home_anchor",army.anchor)))
	return (Vector2i(army.anchor)-landing).length_squared()<=160*160 and _rally_safe(world,landing) and _rally_safe(world,Vector2i(army.anchor))


func _base_recently_attacked(world: Dictionary) -> bool:
	for base: Dictionary in world.get("buildings",[]):
		if base.get("side") == "AI" and base.get("building_type") == "BASE" and int(base.get("hp",0)) > 0 and int(base.get("last_damage_tick",-1)) >= 0 and _planning_tick-int(base.last_damage_tick) <= 60: return true
	return false


static func _basic_count(world: Dictionary, military: Dictionary) -> int:
	var count:=0
	for type:String in Factions.basic_units_for(_faction(world)):count+=_living_type(military,type)
	return count


func _hero_saving_eligible(world: Dictionary, military: Dictionary, quote: Dictionary, altar: Dictionary) -> bool:
	if _battle_elapsed < int(_policy.hero_ticks) or quote.is_empty() or altar.is_empty(): return false
	var pop: Dictionary = world.get("population",{}).get("AI",{})
	if not pop.is_empty() and int(pop.used)+int(pop.reserved)+int(quote.get("population",5)) > int(pop.maximum): return false
	if quote.get("mode") == "RECRUIT" and (_basic_count(world,military)<4 or _base_recently_attacked(world)): return false
	return true


static func _development_eligible(world: Dictionary, command: Dictionary) -> bool:
	if command.get("type") == "PLACE_BUILDING":
		if Outposts.enabled(world): return not Outposts.slot_for_order(world, command).is_empty()
		return _worker_count(world)>0 and (_paid_blueprints(world).is_empty() if command.get("building_type")=="BASE" else _blueprints(world).is_empty())
	if command.get("type") == "UPGRADE" and not world.get("technology_queues",{}).get("AI",[]).is_empty(): return false
	for building: Dictionary in world.get("buildings",[]):
		if building.get("id") == command.get("building_id") and building.get("side") == "AI" and bool(building.get("complete",false)) and int(building.get("hp",0)) > 0: return true
	return false


func _budget_block(world: Dictionary, military: Dictionary) -> String:
	var population: Dictionary = world.get("population",{}).get("AI",{})
	var minimum_population := 1 if _worker_count(world)<_worker_goal(world) else 2
	if not population.is_empty() and int(population.maximum)-int(population.used)-int(population.reserved)<minimum_population: return "POPULATION"
	for building: Dictionary in world.get("buildings",[]):
		if building.get("side") != "AI": continue
		for order: Dictionary in building.get("queue",[]):
			if str(order.get("state","")).begins_with("BLOCKED_"): return str(order.state)
	if not _budget.target.is_empty(): return "SAVING_"+str(_budget.target.get("purpose",""))
	if _producers(world,"BARRACKS").is_empty() and _producers(world,"RANGE").is_empty(): return "NO_PRODUCER"
	var producers: Array = _producers(world,"BARRACKS")+_producers(world,"RANGE")+_producers(world,"DRAGON_ROOST")
	if not producers.is_empty() and producers.all(func(body: Dictionary)->bool:return not body.get("queue",[]).is_empty()): return "PRODUCTION_QUEUES"
	return "NONE"


static func _shadow_recruit(forecast: Dictionary, command: Dictionary) -> void:
	var type := str(command.get("unit_type",""))
	var recipe := _recipe(type)
	var quote := _hero_quote(forecast,str(command.get("hero_archetype",""))) if type == "hero" else recipe
	for resource: String in Economy.RESOURCE_KEYS:
		forecast.economy.AI.stock[resource] = int(forecast.economy.AI.stock.get(resource,0))-int(quote.get("cost",{}).get(resource,0))
	forecast.population.AI.reserved = int(forecast.population.AI.reserved)+int(quote.get("population",0))
	for building: Dictionary in forecast.buildings:
		if building.id == command.get("building_id"): building.queue.append(command.duplicate(true)); break
	if type == "hero": forecast.hero_quotes.AI.clear()


func _capacity_building(world: Dictionary) -> Dictionary:
	var pop: Dictionary = world.get("population",{}).get("AI",{})
	if not pop.is_empty() and int(pop.maximum)-int(pop.used)-int(pop.reserved) < 4: return {}
	if not Outposts.enabled(world) and _worker_count(world) < 6: return {}
	for role: String in ["FRONTLINE","RANGED","SIEGE"]:
		if Factions.units_for(_faction(world),role).is_empty(): continue
		var type := _role_type(world,role)
		var recipe := _recipe(type)
		if recipe.is_empty() or _base_tier(world)<int(recipe.get("required_base_tier",1)): continue
		var kind := str(recipe.building_type)
		var producers := _producers(world,kind)
		if producers.is_empty() or producers.size() >= 3 or producers.any(func(body: Dictionary)->bool:return body.get("queue",[]).is_empty()): continue
		var catalog_recipe := _building_recipe(world,kind)
		if catalog_recipe.is_empty(): continue
		var needed: Dictionary = catalog_recipe.cost.duplicate(true)
		for resource: String in Economy.RESOURCE_KEYS: needed[resource] = int(needed.get(resource,0))+2*int(recipe.cost.get(resource,0))
		if not _can_pay(world,needed): continue
		var home := _own_base(world)
		if not home.is_empty(): return _placement(world,kind,home.position)
	return {}


func _hero_reaction(military: Dictionary) -> Dictionary:
	var officers: Array = military.get("heroes",{}).get("officers",[])
	if officers.is_empty(): return {}
	var pivot := 0
	for index: int in range(officers.size()):
		if str(officers[index].get("id","")) == _last_reaction_hero_id:
			pivot = (index+1)%officers.size()
	# Owned urgent recovery precedes offense, but never materializes an item or
	# bypasses its normal shared cooldown. An officer with no ready choice is
	# skipped, not allowed to consume the side's finite command allocation.
	for offset: int in range(officers.size()):
		var hero: Dictionary = officers[(pivot+offset)%officers.size()]
		if hero.get("side") != "AI" or hero.get("state") != "ACTIVE" or int(hero.get("hp",0)) <= 0: continue
		if int(hero.get("stun_until_tick",0)) > int(military.get("tick",0)): continue
		if int(hero.hp)*5 < int(hero.max_hp)*2 and int(hero.get("inventory",{}).get("POTION",0))>0 and int(hero.get("item_cooldown_ticks",0))<=0:
			return {"type":"USE_POTION","unit_id":hero.id}
	for offset: int in range(officers.size()):
		var hero: Dictionary = officers[(pivot+offset)%officers.size()]
		var action := SkillMicro.best_action(hero,military)
		if not action.is_empty(): return action
	return {}


func _hero_action(military: Dictionary) -> Dictionary:
	var officers: Array = military.get("heroes", {}).get("officers", [])
	if officers.is_empty(): return {}
	# Up to three officers share one bounded hero-action slot. Rotate equipment
	# and spell attention; urgent, owned potions precede the fair round robin.
	for hero: Dictionary in officers:
		if hero.get("side") == "AI" and hero.get("state") == "ACTIVE" and int(hero["hp"]) * 5 < int(hero["max_hp"]) * 2 and int(hero.get("inventory",{}).get("POTION",0)) > 0 and int(hero.get("item_cooldown_ticks",0))<=0:
			_last_hero_id = str(hero["id"])
			return {"type":"USE_POTION","unit_id":hero["id"]}
	var pivot := 0
	for index in range(officers.size()):
		if officers[index]["id"] == _last_hero_id: pivot = (index + 1) % maxi(1,officers.size())
	var observation := military.duplicate(true)
	var ordered: Array = []
	for index in range(officers.size()): ordered.append(officers[(pivot + index) % officers.size()])
	observation["heroes"]["officers"] = ordered
	var action := _hero_action_unrotated(observation)
	if not action.is_empty(): _last_hero_id = str(action.get("unit_id",""))
	return action


func _hero_action_unrotated(military: Dictionary) -> Dictionary:
	for hero: Dictionary in military.get("heroes", {}).get("officers", []):
		if hero.get("side") != "AI" or hero.get("state") != "ACTIVE":
			continue
		if int(hero.get("stun_until_tick", 0)) > int(military.get("tick", 0)): continue
		var id := str(hero["id"])
		var hp := int(hero["hp"])
		var maximum := int(hero["max_hp"])
		if hp * 5 < maximum * 2 and int(hero.get("inventory", {}).get("POTION", 0)) > 0 and int(hero.get("item_cooldown_ticks",0))<=0:
			return {"type": "USE_POTION", "unit_id": id}
		var active_skill:=SkillMicro.best_action(hero,military)
		# An already learned, actually useful heal must not wait behind spending
		# seven new level-up points on passives/ultimates while an ally dies.
		if not active_skill.is_empty():
			for skill: Dictionary in hero.get("skills",[]):
				if skill.get("id")==active_skill.get("skill_id") and skill.get("effect")=="HEAL":return active_skill
		# Spend actual earned points through the same ordinary command channel,
		# once in this officer's existing paced action slot. Rank and ownership
		# remain Combat's authority, not a planner-side inventory/stat write.
		if int(hero.get("skill_points", 0)) > 0:
			var opportunity:=SkillMicro.learning_action(hero,military)
			if not opportunity.is_empty():return opportunity
			var legal_ids: Array = HeroCatalog.profile(str(hero.get("archetype", HeroCatalog.DEFAULT_ARCHETYPE))).get("skill_ids", [])
			var learning: Array = hero.get("skills", []).duplicate()
			# Learn an available ultimate first, otherwise the least-trained
			# basic. Points, gates and actual learned passives remain authority.
			learning.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
				if bool(a.get("ultimate",false))!=bool(b.get("ultimate",false)): return bool(a.get("ultimate",false))
				return int(a.get("level",0))<int(b.get("level",0)))
			for skill: Dictionary in learning:
				if skill.get("id") in legal_ids and bool(skill.get("can_upgrade", false)):
					return {"type":"UPGRADE_HERO_SKILL","unit_id":id,"skill_id":skill["id"]}
		for item: String in ["IRON_BLADE", "WARD_MAIL", "FIELD_BOOTS", "LONGSIGHT", "VITAL_CHARM", "SPELL_LENS"]:
			if item not in hero.get("equipment", []) and int(hero.get("inventory", {}).get(item, 0)) > 0:
				return {"type": "EQUIP_ITEM", "unit_id": id, "item_id": item}
		if not active_skill.is_empty():return active_skill
	return {}


static func _hero_skill_enemy(hero: Dictionary, skill: Dictionary, military: Dictionary) -> Dictionary:
	var allowed := int(skill.get("range",0)) if skill.get("target_mode")=="POINT" else int(skill.get("radius",0))
	var best := allowed*allowed+1
	var result := {}
	for enemy: Dictionary in military.get("soldiers",[]):
		if enemy.get("side")==hero.get("side") or not bool(enemy.get("alive",false)) or enemy.get("movement_layer","GROUND") not in skill.get("target_layers",[]): continue
		var distance: int=(Vector2i(enemy.position)-Vector2i(hero.position)).length_squared()
		if distance<best or distance==best and not result.is_empty() and str(enemy.id)<str(result.id):
			best=distance
			result=enemy
	return result


static func _skill_available(hero: Dictionary, skill: Dictionary) -> bool:
	return bool(skill.get("learned",true)) and not bool(skill.get("passive",false)) and bool(skill.get("can_cast",true)) and int(skill.get("cooldown_ticks", 0)) <= 0 and int(hero.get("mana", 0)) >= int(skill.get("mana_cost", 0))


static func _ready_skill_id(hero: Dictionary, id: String) -> bool:
	for skill: Dictionary in hero.get("skills", []):
		if skill.get("id") == id: return _skill_available(hero, skill)
	return false


func _placement(world: Dictionary, kind: String, origin: Vector2i) -> Dictionary:
	if Outposts.enabled(world): return Outposts.placement(world, kind, origin)
	if _base_tier(world) < int(Progression.BUILDING_TIERS.get(kind, 1)): return {}
	var recipe := _building_recipe(world,kind)
	if recipe.is_empty(): return {}
	# BASE candidates stay within the published owned-site radius. Producers use
	# separated rings; outlet space is checked too, so construction does not cage
	# the only actual recruitment doorway.
	for ring: int in [110, 170, 230]:
		for offset: Vector2i in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			var point := origin + offset * ring
			if kind in ["BASE","ESSENCE_MINE"] and (point - origin).length_squared() > World.BASE_SITE_RADIUS * World.BASE_SITE_RADIUS:
				continue
			var radius := int(recipe["radius"])
			var direction: Vector2i = world.get("planning_spawn_direction", Vector2i(-1, 0))
			var outlet := point + direction * (radius + 36)
			if _point_clear(world, point, radius + 12) and _point_clear(world, outlet, 18):
				return {"type": "PLACE_BUILDING", "building_type": kind, "position": point}
	return {}


static func _building_recipe(world: Dictionary, kind: String) -> Dictionary:
	# The live host publishes this exact controller's faction quote. Legacy
	# isolated fixtures may omit a catalog, but an authoritative published
	# directory must never silently fall back to another faction's tower price.
	var catalog: Dictionary = world.get("catalog",{})
	if catalog.has("buildings"):
		return catalog.buildings.get(kind,{}).duplicate(true)
	return World.BUILDING_CATALOG.get(kind,{}).duplicate(true)


static func _point_clear(world: Dictionary, point: Vector2i, radius: int) -> bool:
	var bounds: Dictionary = world.get("arena_bounds", {"min_x": World.BOUNDS.position.x, "min_y": World.BOUNDS.position.y, "max_x": World.BOUNDS.end.x, "max_y": World.BOUNDS.end.y})
	if point.x - radius < int(bounds["min_x"]) or point.y - radius < int(bounds["min_y"]) or point.x + radius >= int(bounds["max_x"]) or point.y + radius >= int(bounds["max_y"]):
		return false
	for list: Array in [world.get("buildings", []), world.get("workers", []), world.get("soldiers", [])]:
		for body: Dictionary in list:
			if int(body.get("hp", 0)) <= 0 or str(body.get("movement_layer", "GROUND")) == "AIR":
				continue
			var separation := radius + int(body.get("radius", 12)) + 8
			if (Vector2i(body["position"]) - point).length_squared() < separation * separation:
				return false
	for obstacle: Dictionary in world.get("terrain", []):
		if not bool(obstacle.get("blocks_ground", false)): continue
		var separation := radius + int(obstacle.get("radius", 0))
		if (Vector2i(obstacle["position"]) - point).length_squared() < separation * separation: return false
	return true


static func _already_ordered(army: Dictionary, command: Dictionary) -> bool:
	if command.get("type") == "STOP": return army.get("intent") == "HOLD"
	if army["intent"] != command["type"]:
		return false
	match str(command["type"]):
		"MOVE", "ATTACK_MOVE": return army["destination"] == command["target_position"]
		"FOCUS": return army["target_warband_id"] == command["target_warband_id"]
		"ATTACK_BASE": return army["target_base_id"] == command["target_base_id"]
		"RETREAT": return true
	return false


static func _armies(military: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for army: Dictionary in military["warbands"]:
		if army["side"] == "AI" and not bool(army.get("reserve", false)):
			result.append(army)
	return result


static func _recipient(armies: Array[Dictionary], ranged: bool) -> String:
	for army: Dictionary in armies:
		if (int(army.get("number", 1)) % 2 == 0) == ranged:
			return str(army["id"])
	return "" if armies.is_empty() else str(armies[0]["id"])


func _recipient_for(world: Dictionary, military: Dictionary, armies: Array[Dictionary], ranged: bool) -> String:
	var best := ""
	var score := INF
	for army: Dictionary in armies:
		var incoming := 0
		for producer: Dictionary in world["buildings"]:
			if producer["side"] != "AI": continue
			for entry: Dictionary in producer["queue"]:
				if str(entry.get("warband_id", "")) == str(army["id"]): incoming += 1
		var count := int(army["living_count"]) + incoming
		var preference := (int(army.get("number", 1)) % 2 == 0) == ranged
		var next := float(count) + (0.0 if preference else 2.0)
		if bool(_regrouping.get(army["id"], false)): next -= 5.0
		if next < score:
			score = next
			best = str(army["id"])
	return best


static func _worker_count(world: Dictionary) -> int:
	var count := 0
	for worker: Dictionary in world["workers"]:
		if worker["side"] == "AI" and int(worker["hp"]) > 0: count += 1
	return count


static func _living_type(military: Dictionary, type: String) -> int:
	var count := 0
	for unit: Dictionary in military.get("soldiers", []):
		if unit["side"] == "AI" and unit["unit_type"] == type and bool(unit["alive"]): count += 1
	return count


static func _living_enemy_count(military: Dictionary) -> int:
	var count := 0
	for unit: Dictionary in military["soldiers"]:
		if unit["side"] == "PLAYER" and bool(unit["alive"]): count += 1
	return count


static func _queued_type(world: Dictionary, type: String) -> int:
	var count := 0
	for building: Dictionary in world["buildings"]:
		if building["side"] != "AI": continue
		for entry: Dictionary in building["queue"]:
			if entry["unit_type"] == type: count += 1
	return count


static func _building_of_type(world: Dictionary, type: String, complete: bool = false) -> Dictionary:
	for building: Dictionary in world["buildings"]:
		if building["side"] == "AI" and building["building_type"] == type and int(building["hp"]) > 0 and (not complete or bool(building["complete"]) and Outposts.building_operational(world,building)):
			return building
	return {}


static func _building_count(world: Dictionary, type: String, complete: bool = false) -> int:
	var count := 0
	for building: Dictionary in world["buildings"]:
		if building["side"] == "AI" and building["building_type"] == type and int(building["hp"]) > 0 and (not complete or bool(building["complete"])): count += 1
	return count


static func _own_base(world: Dictionary) -> Dictionary:
	return _building_of_type(world, "BASE", true)


static func _base_tier(world: Dictionary) -> int:
	var published: Dictionary = world.get("progression", {}).get("AI", {})
	if published.has("base_tier"): return clampi(int(published["base_tier"]), 1, 3)
	var tier := 1
	for base: Dictionary in world.get("buildings", []):
		if base.get("side") == "AI" and base.get("building_type") == "BASE" and bool(base.get("complete", false)) and int(base.get("hp", 0)) > 0:
			tier = maxi(tier, int(base.get("base_tier", 1)))
	return mini(3, tier)


static func _base_upgrade_request(world: Dictionary, target_tier: int) -> Dictionary:
	if _base_tier(world) >= target_tier: return {}
	var selected := {}
	for base: Dictionary in world.get("buildings", []):
		if base.get("side") != "AI" or base.get("building_type") != "BASE" or not bool(base.get("complete", false)) or int(base.get("hp", 0)) <= 0: continue
		if not base.get("base_upgrade", {}).is_empty(): return {}
		if selected.is_empty() or int(base.get("base_tier", 1)) > int(selected.get("base_tier", 1)): selected = base
	return {} if selected.is_empty() else {"type":"UPGRADE_BASE", "building_id":selected["id"]}


static func _blueprints(world: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for building: Dictionary in world["buildings"]:
		if building["side"] == "AI" and int(building["hp"]) > 0 and not bool(building["complete"]): result.append(building)
	return result


static func _paid_blueprints(world:Dictionary)->Array[Dictionary]:
	return _blueprints(world).filter(func(building:Dictionary)->bool:return building.get("building_type")!="SITE_TOWER" or bool(building.get("paid_rebuild_pending",false)))


static func _site_has_base(world: Dictionary, site: Dictionary) -> bool:
	if site["owner"] != "AI": return false
	for building: Dictionary in world["buildings"]:
		if building["side"] == "AI" and building["building_type"] == "BASE" and int(building["hp"]) > 0 and bool(building["complete"]) and (Vector2i(building["position"]) - Vector2i(site["position"])).length_squared() <= World.BASE_SITE_RADIUS * World.BASE_SITE_RADIUS:
			return true
	return false


static func _site_has_any_base(world: Dictionary, site: Dictionary) -> bool:
	for building: Dictionary in world["buildings"]:
		if building["side"] == "AI" and building["building_type"] == "BASE" and int(building["hp"]) > 0 and (Vector2i(building["position"]) - Vector2i(site["position"])).length_squared() <= World.BASE_SITE_RADIUS * World.BASE_SITE_RADIUS:
			return true
	return false


static func _has_mine(world: Dictionary) -> bool:
	for site: Dictionary in world["sites"]:
		if site["kind"] == "RESOURCE" and site.get("resource","") != "ESSENCE" and _site_has_base(world, site) and _source_remaining(world, str(site["id"]), "MATERIAL") > 0: return true
	return false


static func _site_has_essence_mine(world: Dictionary, site: Dictionary, complete: bool = true) -> bool:
	if site.get("owner","") != "AI" or site.get("resource","") != "ESSENCE": return false
	for building: Dictionary in world.get("buildings",[]):
		if building.get("side") == "AI" and building.get("building_type") == "ESSENCE_MINE" and int(building.get("hp",0)) > 0 and (not complete or bool(building.get("complete",false))) and (Vector2i(building.position)-Vector2i(site.position)).length_squared() <= World.BASE_SITE_RADIUS * World.BASE_SITE_RADIUS: return true
	return false


static func _usable_essence_sites(world: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for site: Dictionary in world.get("sites",[]):
		if Outposts.enabled(world):
			if site.get("owner") == "AI" and int(site.get("guardian_tier", 0)) >= 3 and bool(site.get("income_active", false)) and _source_remaining(world, str(site.get("id", "")), "MATERIAL") > 0: result.append(site)
			continue
		if _site_has_essence_mine(world,site) and _source_remaining(world,str(site.id),"ESSENCE") > 0: result.append(site)
	return result


static func _source_remaining(world: Dictionary, site_id: String, resource: String) -> int:
	# Legacy detached policy fixtures did not publish sources. Current authority
	# always supplies the finite ledger; no absent-source grant enters the host.
	if not world.has("resource_sources"): return 0 if resource == "ESSENCE" else 1
	for source: Dictionary in world["resource_sources"]:
		if str(source.get("site_id", "")) == site_id and str(source.get("resource", source.get("kind", ""))) == resource:
			return int(source.get("remaining", source.get("remaining_amount", 0)))
	return 0


static func _faction(world: Dictionary) -> String:
	return str(world.get("planning_faction_id", "HUMAN"))


static func _role_type(world: Dictionary, role: String) -> String:
	var types: Array = Factions.units_for(_faction(world), role)
	types = types.filter(func(id: String) -> bool: return not str(_recipe(id).get("balance_role", "")).begins_with("ESSENCE_"))
	if types.is_empty() and role == "HEAVY":
		types = Factions.units_for(_faction(world), "CAVALRY").filter(func(id: String) -> bool: return not str(_recipe(id).get("balance_role", "")).begins_with("ESSENCE_"))
	if not types.is_empty(): return str(types[0])
	# A missing role never grants a foreign human unit to another faction.
	return Factions.main_unit_for(_faction(world))


static func _recipe(type: String) -> Dictionary:
	return Units.UNITS.get(type, {})


static func _army_hp(military: Dictionary, id: String) -> int:
	var hp := 0
	var maximum := 0
	for unit: Dictionary in military["soldiers"]:
		if unit["warband_id"] == id and bool(unit["alive"]):
			hp += int(unit["hp"])
			maximum += int(unit["max_hp"])
	return 100 if maximum == 0 else int(hp * 100 / maximum)


static func _near_enemy(military: Dictionary, position: Vector2i, radius: int) -> bool:
	for unit: Dictionary in military["soldiers"]:
		if unit["side"] == "PLAYER" and bool(unit["alive"]) and (Vector2i(unit["position"]) - position).length_squared() <= radius * radius: return true
	return false
