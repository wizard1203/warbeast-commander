extends "res://src/simulation/strategic_ai.gd"
## M100 isolated same-policy owned-container overlays. Not used by production.
## Source-qualified complete inherited method copies, never a script transplant.
const M100_SOURCE_SHA256 := "03062f27e2d912e78ba1215a0a22a3e7874fe585579457f6ddaf6806e3fa93a8"
var m100_enable_hero_overlay := true
var m100_enable_recruit_overlay := true
var m100_enable_paired_perspective := true

func plan(tick: int, phase: String, world: Dictionary, military: Dictionary, technology: Dictionary) -> Array[Dictionary]:
	if not m100_enable_paired_perspective: return super.plan(tick,phase,world,military,technology)
	# Reuse the proven bounded policy on a detached self/opponent perspective.
	# Entity IDs/positions/recipes stay REAL. Only this projection's side labels
	# normalize; the shared host executes receipts as _side_id, never as "AI".
	if not is_due(tick,phase):
		return []
	var pair := _m100_perspectives(world,military)
	var view:Dictionary=pair.world
	var forces:Dictionary=pair.military
	var own_tech := {"AI": technology.get(_side_id, {}).duplicate(true)}
	return _plan_perspective(tick, phase, view, forces, own_tech)



func _m100_perspectives(world:Dictionary,military:Dictionary)->Dictionary:
	# Public _perspective stays unchanged. Reuse only completed owned rows
	# from the identical original soldiers container, never equal content/tick.
	var view:Dictionary=_perspective(world)
	if military==world:return {"world":view,"military":view,"shared_soldiers":false,"reason":"ORIGINAL_MERGED_INPUT"}
	if world.has("soldiers") and military.has("soldiers") and world.soldiers is Array and military.soldiers is Array and is_same(world.soldiers,military.soldiers):
		return {"world":view,"military":_m100_perspective_owned_soldiers(military,view.soldiers,view.micro_neutral_targets),"shared_soldiers":true,"reason":"EXACT_INPUT_ROSTER_IDENTITY"}
	return {"world":view,"military":_perspective(military),"shared_soldiers":false,"reason":"ORIGINAL_DOUBLE_PERSPECTIVE"}

func _m100_perspective_owned_soldiers(facts:Dictionary,owned_soldiers:Array,owned_neutrals:Array)->Dictionary:
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
			if key=="soldiers":view[key]=owned_soldiers
			else:
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
	view["micro_neutral_targets"] = owned_neutrals
	view["planning_faction_id"] = _faction_id
	view["planning_spawn_direction"] = Vector2i(-1, 0)
	for side: Dictionary in facts.get("match_config", facts.get("match_settings", {})).get("sides", []):
		if str(side.get("side_id", "")) == _side_id:
			view["planning_spawn_direction"] = side.get("spawn_direction", Vector2i(-1, 0))
	for list_name: String in ["buildings", "workers", "soldiers", "warbands", "armies"]:
		if list_name=="soldiers":continue # Already normalized exactly once by the first owned perspective.
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
		var owner := str(site.get("owner", ""))
		if owner == _side_id:
			site["owner"] = "AI"
		elif owner not in ["", "NEUTRAL"]:
			site["owner"] = "PLAYER"
	for source: Dictionary in view.get("resource_sources", []):
		var owner := str(source.get("owner", ""))
		if owner == _side_id: source["owner"] = "AI"
		elif owner not in ["", "NEUTRAL"]: source["owner"] = "PLAYER"
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




func _hero_action(military: Dictionary) -> Dictionary:
	if not m100_enable_hero_overlay: return super._hero_action(military)
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
	var observation := _m100_hero_observation(military)
	var ordered: Array = []
	for index in range(officers.size()): ordered.append(officers[(pivot + index) % officers.size()])
	observation["heroes"]["officers"] = ordered
	var action := _hero_action_unrotated(observation)
	if not action.is_empty(): _last_hero_id = str(action.get("unit_id",""))
	return action



func _plan_perspective(tick: int, phase: String, world: Dictionary, military: Dictionary, technology: Dictionary) -> Array[Dictionary]:
	if not m100_enable_recruit_overlay: return super._plan_perspective(tick,phase,world,military,technology)
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
		var forecast := _m100_recruit_forecast(world)
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
	if macro_due and not economic.is_empty() and _economy_pending_since>=0 and tick-_economy_pending_since>=int(_policy.decision_ticks)*2:
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



func _m100_hero_observation(military:Dictionary)->Dictionary:
	# Only these two containers are written by the existing rotation. The
	# replacement officers array owns its order, as in the original method.
	var observation:Dictionary=military.duplicate(false)
	observation["heroes"]=military.get("heroes",{}).duplicate(false)
	return observation

func _m100_recruit_forecast(world:Dictionary)->Dictionary:
	# All _shadow_recruit write paths are separately owned. Everything else
	# remains read-only for this synchronous forecast, including unknown keys.
	var forecast:Dictionary=world.duplicate(false)
	forecast["economy"]=world.get("economy",{}).duplicate(false)
	forecast.economy["AI"]=world.get("economy",{}).get("AI",{}).duplicate(false)
	forecast.economy.AI["stock"]=world.get("economy",{}).get("AI",{}).get("stock",{}).duplicate(true)
	forecast["population"]=world.get("population",{}).duplicate(false)
	forecast.population["AI"]=world.get("population",{}).get("AI",{}).duplicate(true)
	if world.has("buildings"):
		forecast["buildings"]=world.buildings.duplicate(false)
		for index:int in range(forecast.buildings.size()):
			var building:Dictionary=world.buildings[index].duplicate(false)
			if building.has("queue"):building["queue"]=building.queue.duplicate(true)
			forecast.buildings[index]=building
	if world.has("hero_quotes"):
		forecast["hero_quotes"]=world.hero_quotes.duplicate(false)
		if world.hero_quotes.has("AI"):forecast.hero_quotes["AI"]=world.hero_quotes.AI.duplicate(true)
	return forecast

