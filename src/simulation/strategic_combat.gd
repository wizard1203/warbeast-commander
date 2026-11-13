extends RefCounted
const VisibilityR9=preload("res://src/simulation/strategic_visibility_r9.gd")
## M11 deterministic military authority. Display and model callers receive
## detached observations; individual physical settlement stays in this module.

const BodyResolver = preload("res://src/simulation/unit_body_resolver.gd")
const HeroCatalog = preload("res://src/simulation/strategic_hero_catalog.gd")
const ReworkRuntimeR7 = preload("res://src/simulation/strategic_hero_rework_r7_runtime.gd")
const HeroProgression = preload("res://src/simulation/strategic_hero_progression.gd")
const SkillGeometry = preload("res://src/simulation/strategic_hero_skill_geometry.gd")
const ItemRules = preload("res://src/simulation/strategic_hero_items.gd")
const TechnologiesV4 = preload("res://src/simulation/strategic_faction_technologies_v4.gd")
const TroopRuntimeV4 = preload("res://src/simulation/strategic_troop_runtime_v4.gd")
const EliteRuntimeR4 = preload("res://src/simulation/strategic_elite_runtime_r4.gd")
var _r4_pending_damage:Dictionary={}
var _r4_elite_dirty:=true
var _r4_guard_targets:Dictionary={}
const Buffs = preload("res://src/simulation/strategic_combat_buffs.gd")
const ArmySupport = preload("res://src/simulation/strategic_army_support.gd")
const Innates = preload("res://src/simulation/strategic_hero_innates.gd")
const MilitaryFactsM93 = preload("res://src/simulation/strategic_military_facts_m93.gd")
const PreparationContextM93 = preload("res://src/simulation/strategic_preparation_context_m93.gd")
const ActionContextM94 = preload("res://src/simulation/strategic_action_context_m94.gd")
const StatDependenciesM95 = preload("res://src/simulation/strategic_stat_dependencies_m95.gd")
const Progression = preload("res://src/simulation/strategic_progression_catalog.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const FormationRolesR2 = preload("res://src/simulation/strategic_formation_roles_r2.gd")
const FormationMarchR12 = preload("res://src/simulation/strategic_formation_march_r12.gd")
const Navigation = preload("res://src/simulation/strategic_navigation.gd")
const RouteVisibilityM96 = preload("res://src/simulation/strategic_route_visibility_m96.gd")
const FieldObjectives = preload("res://src/simulation/strategic_field_objectives.gd")
const DamageRules = preload("res://src/simulation/strategic_damage_rules.gd")
const NeutralEncounters = preload("res://src/simulation/strategic_neutral_encounters.gd")
const Targeting = preload("res://src/simulation/strategic_combat_targeting.gd")
const HeroStatistics = preload("res://src/simulation/strategic_hero_statistics_m69.gd")
const FootprintR10 = preload("res://src/simulation/strategic_body_footprint_r10.gd")
const MovementRecoveryR11 = preload("res://src/simulation/strategic_movement_recovery_r11.gd")
const RECOVERY_STALL_TICKS_R11 := 24
const RECOVERY_PROGRESS_WATCHDOG_R14 := 120
const RECOVERY_TARGET_TICKS_R11 := 100
var _recovery_plans_r11 := 0
var _recovery_cursor_r11 := ""
var _recovery_waiting_r11 := false
var _recovery_pending_r11 := false
var _recovery_reserve_r11 := false
const BOUNDS := Rect2i(80, 80, 3200, 2000)
const SIDES := ["PLAYER", "AI"]
const FORMATIONS := ["STEADY", "LOOSE", "COLUMN", "SPEAR"]
const MAX_ARMIES := 12
const DISCOVERY_RANGE := 230
const SKILL_CATALOG := HeroCatalog.SKILLS

var _seed := 1701
var _tick := -1
var _warbands: Dictionary = {}
## Temporary command controllers, never recruitment/roster armies. A UI view
## change cannot create one; only an accepted explicit type command can.
var _type_cohorts_r12: Dictionary = {}
var _march_profiles_r12: Dictionary = {} # disposable, one movement batch only
var _soldiers: Dictionary = {}
var _hero_data: Dictionary = {}
const CORPSE_TTL_R9 := 200 # ten simulation seconds; pauses do not age bodies.
var _corpse_deadlines_r9: Dictionary = {}
var _corpse_buckets_r9: Dictionary = {}
var _corpse_ticks_r9: Array[int] = []
var _retired_heroes_r9: Dictionary = {} # bounded permanent officer display record, not a spatial body.
var _r7_skills := ReworkRuntimeR7.new()
var _ai_hero_withdrawals: Dictionary = {}
var _shared_xp_receipts: Dictionary = {}
var _xp_bonus_remainders_v4: Dictionary = {}
var _technology_compiled_v4: Dictionary = {}
var _hero_aura_bonuses: Dictionary = {}
var _next_army := {"PLAYER": 3, "AI": 3}
var _spawn_serial := 0
var _paid_hero_receipts: Dictionary = {}
var _paid_item_receipts: Dictionary = {}
var _field_reward_receipts: Dictionary = {}
var _neutrals: RefCounted
var _technology := {"PLAYER": {"ATTACK": 0, "ARMOR": 0}, "AI": {"ATTACK": 0, "ARMOR": 0}}
var _buildings: Dictionary = {}
var _external_hits: Array[Dictionary] = []
var _feedback_events:Array[Dictionary]=[]
var _feedback_generation:=0
var _feedback_serial:=0
var _match: Dictionary={}
var _sides: Array[String]=[]
var _side_config: Dictionary={}
var _bounds: Rect2i=BOUNDS
var _terrain: Array[Dictionary]=[]
var _route_geometry: String=""
var _route_obstacles: Array[Dictionary]=[]
var _route_plans: int=0
## Only static-circle geometry within one target/movement batch. No body,
## target or route answer is retained; independent callers use the old predicate.
var _m96_route_batch_active := false
var _m96_route_visibility: RefCounted = null
var _m96_route_work: Dictionary = {}
var _targeting:=Targeting.new()
var _hero_statistics := HeroStatistics.new()
var _statistics_batching := false
var _statistics_pending_hits: Dictionary = {}
var _choosing_targets_m76 := false
## Derived count/pitch only, never an army/position ledger. Valid exclusively
## inside the synchronous target/desired batch, after hero auto-cast changes.
var m84_layout_active := false
var m84_layout_contexts: Dictionary = {}
var _role_layouts_r2: Dictionary = {}
var _role_members_r2: Dictionary = {}
var _neutral_candidates_m76: Array[Dictionary] = []
# Static regular-unit recipes stay private. Each body keeps its own full
# baseline; only a small scalar working set is copied during refresh.
var _m87_recipes: Dictionary = {}
var _m87_baselines: Dictionary = {}
var _m87_recipe_builds := 0
var _m87_baseline_builds := 0
var _m95_stat_dependencies := StatDependenciesM95.new()
var _m95_stat_scope_serial := 0
var _m95_stat_scope := 0
# One synchronous advance only. Readers own independent top arrays while body
# fields remain live; spawn/revive/reset streams invalidate this derived order.
var _m90_order_scope := false
var _m90_order_count := -1
var _m90_ordered: Array[Dictionary] = []
# Derived, synchronous preparation only. Never survives movement or damage.
var _m93_context: RefCounted = null
var _m93_phase_builds := 0
var _m93_phase_queries := 0
var _m93_phase_candidates := 0
var _m93_owned_environment := false
var _m93_owned_admissions := 0
var _m93_empty_event_skips := 0
# Position-only facts, lazy and exclusively inside the post-movement action
# batch. HP/MP/buffs/statuses and support eligibility remain live reads.
var _m94_action_active := false
var _m94_action_context: RefCounted = null
const MAX_ROUTE_PLANS_PER_TICK:=2


func _init(seed: int = 1701, canonical_match: Dictionary={}) -> void:
	reset(seed,canonical_match)


func reset(seed: int = 1701, canonical_match: Dictionary={}) -> void:
	_recovery_cursor_r11="";_recovery_waiting_r11=false;_recovery_pending_r11=false;_recovery_reserve_r11=false
	_corpse_deadlines_r9.clear();_corpse_buckets_r9.clear();_corpse_ticks_r9.clear();_retired_heroes_r9.clear()
	_xp_bonus_remainders_v4.clear()
	_technology_compiled_v4.clear()
	_r7_skills.reset()
	_m96_end_route_batch()
	_m96_route_work = {}
	_m93_context = null
	_m93_phase_builds = 0
	_m93_phase_queries = 0
	_m93_phase_candidates = 0
	_m93_owned_environment = false
	_m93_owned_admissions = 0
	_m93_empty_event_skips = 0
	_m90_order_scope = false
	_m90_invalidate_order()
	_m87_recipes.clear()
	_m87_baselines.clear()
	_m87_recipe_builds = 0
	_m87_baseline_builds = 0
	_m95_stat_dependencies.reset()
	_m95_stat_scope_serial=0
	_m95_stat_scope=0
	_configure_match(canonical_match)
	_seed = seed
	_tick = -1
	_hero_statistics.reset()
	_statistics_batching = false
	_statistics_pending_hits.clear()
	_choosing_targets_m76 = false
	m84_layout_active = false
	m84_layout_contexts.clear()
	_neutral_candidates_m76.clear()
	_role_layouts_r2.clear()
	_role_members_r2.clear()
	_warbands = {}
	_type_cohorts_r12.clear()
	_march_profiles_r12.clear()
	_soldiers = {}
	_hero_data = {}
	_ai_hero_withdrawals.clear()
	_shared_xp_receipts.clear()
	_hero_aura_bonuses.clear()
	_next_army = {}
	_spawn_serial = 0
	_paid_hero_receipts = {}
	_paid_item_receipts = {}
	_field_reward_receipts.clear()
	_neutrals = null
	_technology = {}
	_buildings = {}
	_external_hits.clear()
	_feedback_events.clear()
	_feedback_generation+=1
	_feedback_serial=0
	_route_plans=0
	_recovery_plans_r11=0
	_terrain.clear()
	for prop: Dictionary in _match.get("terrain",[]):
		if bool(prop.get("blocks_ground",false)):_terrain.append(prop.duplicate(true))
	_refresh_route_geometry()
	for side: String in _sides:
		_next_army[side]=3
		_technology[side]={"ATTACK":0,"ARMOR":0}
		for definition:Dictionary in TechnologiesV4.list_for(_faction(side)):_technology[side][definition.id]=0
		var prefix := _prefix(side)
		var home := _home(side)
		var mirror := int(_side_config[side].spawn_direction.x)
		var frontline: String=Factions.main_unit_for(_faction(side))
		var spacing:=maxi(32,int(stats_for_type(frontline).radius)*2+4)
		_add_warband(prefix + "_alpha", side, 1, home + Vector2i(142 * mirror, -68 * mirror))
		_add_warband(prefix + "_bravo", side, 2, home + Vector2i(142 * mirror, 150 * mirror))
		_add_warband(prefix + "_reserve", side, 0, home, true)
		for group: Dictionary in Factions.opening_recipe(_faction(side)):
			var alpha:=int(group.get("warband_index",1))==1
			var army_name:=prefix+("_alpha" if alpha else "_bravo")
			for index: int in range(int(group.count)):
				var position:=home+Vector2i((110+index*spacing)*mirror,(-100 if alpha else 150)*mirror)
				_add_unit(army_name+"_s%02d"%index,side,str(group.unit_type),army_name,position)
		var archetype:=str(_side_config[side].get("starting_hero",Factions.default_hero(_faction(side))))
		var hero_id := "hero:jiangqi:v2" if side == "PLAYER" and _faction(side)=="HUMAN" else "hero:muqiao:v2" if side=="AI" and _faction(side)=="HUMAN" else "hero:%s:%s:v3" % [prefix,archetype.to_lower()]
		_add_unit(hero_id, side, "hero", prefix + "_alpha", home + Vector2i(142 * mirror, -32 * mirror),archetype,1)
		var base_id := prefix + "_base_01"
		_buildings[base_id] = {"id": base_id, "side": side, "building_type": "BASE", "position": home, "radius": 40, "hp": 1000, "complete": true}
	_reindex()
	# Initial deployment, not runtime teleportation: opening heroes and regular
	# troops share the same final-range ranks used by later march controllers.
	for army: Dictionary in _warbands.values():
		if bool(army.reserve): continue
		var members := _living_members(str(army.id))
		var offsets := FormationMarchR12.layout(members,str(army.formation),FormationMarchR12.pitch_for(members))
		for body: Dictionary in members:
			body.position=Vector2i(army.anchor)+FormationMarchR12.orient(Vector2i(offsets[str(body.id)]),str(army.facing))
			body.direct_destination=body.position;body.route_target=body.position
	_neutrals = NeutralEncounters.new(_match, _seed)
	_neutrals.install(self)


static func stats_for_type(unit_type: String, archetype: String = HeroCatalog.DEFAULT_ARCHETYPE) -> Dictionary:
	return FootprintR10.apply_owned(Units.stats_for(unit_type,archetype))


func apply_command(command: Dictionary, side: String, _sites: Array = []) -> Dictionary:
	if side not in _sides or typeof(command.get("type")) != TYPE_STRING:
		return _reject("INVALID_COMMAND")
	var kind: String = command["type"]
	if kind == "PICKUP_LOOT":
		return _neutrals.pickup(command, side, self, _tick) if _neutrals != null else _reject("UNKNOWN_LOOT")
	if kind == "CREATE_WARBAND":
		if get_warband_ids(side).size() >= MAX_ARMIES:
			return _reject("ARMY_LIMIT")
		var number := int(_next_army[side])
		var id := _prefix(side) + "_army_%02d" % number
		_add_warband(id, side, number, _home(side) + Vector2i(180*int(_side_config[side].spawn_direction.x), 0))
		_next_army[side] = number + 1
		return _accept({"warband_id": id})
	if kind == "MERGE_WARBANDS":
		var source := _owned_army(command.get("source_id"), side)
		var target := _owned_army(command.get("target_id"), side)
		if source.is_empty() or target.is_empty() or source["id"] == target["id"]:
			return _reject("INVALID_ARMY")
		_move_members(str(source["id"]), str(target["id"]))
		_warbands.erase(source["id"])
		_reindex()
		return _accept()
	if kind == "DELETE_WARBAND":
		var army := _owned_army(command.get("subject_id"), side)
		if army.is_empty(): return _reject("INVALID_ARMY")
		_move_members(str(army["id"]), _prefix(side) + "_reserve")
		_warbands.erase(army["id"])
		_reindex()
		return _accept()
	if kind == "TRANSFER_UNITS":
		return _transfer(command, side)
	if kind == "TYPE_ORDER":
		return _type_order_r12(command, side)
	if kind in ["UNIT_MOVE", "UNIT_STOP", "UNIT_ATTACK", "HERO_SKILL", "EQUIP_ITEM", "USE_POTION", "USE_ITEM", "SET_HERO_AUTOMATION", "UPGRADE_HERO_SKILL"]:
		return _unit_command(command, side)
	if kind not in ["MOVE", "STOP", "ATTACK_MOVE", "FOCUS", "ATTACK_BASE", "RETREAT", "SET_FORMATION"]:
		return _reject("UNKNOWN_COMMAND")
	var army := _owned_army(command.get("subject_id"), side)
	if army.is_empty(): return _reject("INVALID_ARMY")
	var error := _army_order_error_r12(command, side)
	if not error.is_empty(): return _reject(error)
	# An explicit valid parent command retakes its actual roster, but merely
	# inspecting/toggling views (or a rejected command) has no military effect.
	_clear_type_cohorts_r12(str(army.id))
	return _issue_army_order_r12(command, army)


func _army_order_error_r12(command: Dictionary, side: String) -> String:
	var kind: String = command.type
	if kind == "SET_FORMATION" and command.get("formation") not in FORMATIONS: return "INVALID_FORMATION"
	if kind in ["MOVE", "ATTACK_MOVE"] and not _valid_point(command.get("target_position")): return "INVALID_POSITION"
	if kind == "FOCUS":
		var enemy := _enemy_army(command.get("target_warband_id"), side)
		if enemy.is_empty() or _living_members(str(enemy.id)).is_empty(): return "INVALID_TARGET"
	if kind == "ATTACK_BASE":
		var id: Variant = command.get("target_base_id")
		if typeof(id) != TYPE_STRING or not _buildings.has(id) or not _attackable_building(_buildings[id]) or _buildings[id].side == side or int(_buildings[id].get("hp",0)) <= 0: return "INVALID_TARGET"
	return ""


func _issue_army_order_r12(command: Dictionary, army: Dictionary) -> Dictionary:
	var kind: String = command.type
	var side: String = army.side
	if kind == "SET_FORMATION":
		if command.get("formation") not in FORMATIONS: return _reject("INVALID_FORMATION")
		army["formation"] = command["formation"]
		for unit: Dictionary in _members(str(army["id"])):
			_clear_fold_slot_r12(unit)
			if unit["direct_intent"] in ["HOLD", "AUTO_HOLD"]: unit["direct_intent"] = ""
		return _accept()
	if kind == "STOP":
		army["intent"] = "HOLD"
		army["destination"] = army["anchor"]
		army["target_warband_id"] = ""
		army["target_base_id"] = ""
		for unit: Dictionary in _members(str(army["id"])):
			if _preserving_ai_hero_withdrawal(unit): continue
			_clear_fold_slot_r12(unit)
			unit["direct_intent"] = "HOLD"
			unit["direct_destination"] = unit["position"]
			unit["target_id"] = ""
		return _accept()
	if kind in ["MOVE", "ATTACK_MOVE"]:
		if not _valid_point(command.get("target_position")): return _reject("INVALID_POSITION")
		army["destination"] = command["target_position"]
	elif kind == "FOCUS":
		var enemy := _enemy_army(command.get("target_warband_id"), side)
		if enemy.is_empty() or _living_members(str(enemy["id"])).is_empty(): return _reject("INVALID_TARGET")
		army["target_warband_id"] = enemy["id"]
	elif kind == "ATTACK_BASE":
		var id: Variant = command.get("target_base_id")
		if typeof(id) != TYPE_STRING or not _buildings.has(id) or not _attackable_building(_buildings[id]) or _buildings[id]["side"] == side or int(_buildings[id].get("hp", 0)) <= 0:
			return _reject("INVALID_TARGET")
		army["target_base_id"] = id
	else:
		army["destination"] = army["home_anchor"]
	army["intent"] = kind
	if kind != "FOCUS": army["target_warband_id"] = ""
	if kind != "ATTACK_BASE": army["target_base_id"] = ""
	for unit: Dictionary in _members(str(army["id"])):
		if _preserving_ai_hero_withdrawal(unit): continue
		_clear_fold_slot_r12(unit)
		unit["direct_intent"] = ""
		unit["target_id"] = ""
	return _accept()


func _type_order_r12(command: Dictionary, side: String) -> Dictionary:
	for key: Variant in command:
		if key not in ["type", "subject_id", "unit_type", "order", "target_position"]: return _reject("INVALID_TYPE_ORDER")
	var parent := _owned_army(command.get("subject_id"), side)
	if parent.is_empty(): return _reject("INVALID_ARMY")
	if typeof(command.get("unit_type")) != TYPE_STRING or typeof(command.get("order")) != TYPE_STRING: return _reject("INVALID_TYPE_ORDER")
	var kind: String = command.order
	if kind not in ["MOVE", "ATTACK_MOVE", "STOP", "RETREAT"]: return _reject("INVALID_TYPE_ORDER")
	if kind in ["MOVE", "ATTACK_MOVE"]:
		if not _valid_point(command.get("target_position")): return _reject("INVALID_POSITION")
	elif command.has("target_position"): return _reject("INVALID_TYPE_ORDER")
	var members: Array[Dictionary] = []
	var center := Vector2.ZERO
	for body: Dictionary in _living_members(str(parent.id)):
		if body.unit_type == command.unit_type and not _preserving_ai_hero_withdrawal(body):
			members.append(body); center += Vector2(body.position)
	if members.is_empty(): return _reject("NO_TYPE_MEMBERS")
	var id := str(parent.id) + "::type::" + str(command.unit_type)
	var cohort: Dictionary = _type_cohorts_r12.get(id,{})
	if cohort.is_empty():
		cohort = parent.duplicate(true)
		cohort.merge({"id":id,"parent_id":str(parent.id),"unit_type":str(command.unit_type),"anchor":Vector2i(center / float(members.size())),"route":[],"route_geometry":""},true)
	cohort["member_ids"] = []
	for body: Dictionary in members:
		cohort.member_ids.append(str(body.id))
		body["command_army_id_r12"] = id
	cohort["living_count"] = members.size()
	_type_cohorts_r12[id] = cohort
	_role_layouts_r2.erase(id)
	var macro := {"type":kind}
	if command.has("target_position"): macro["target_position"] = command.target_position
	return _issue_army_order_r12(macro,cohort)


func _control_army_r12(body: Dictionary) -> Dictionary:
	return _type_cohorts_r12.get(str(body.get("command_army_id_r12","")),_warbands.get(str(body.get("warband_id","")),{}))


func _clear_type_cohorts_r12(parent_id: String) -> void:
	for id: String in _type_cohorts_r12.keys():
		if _type_cohorts_r12[id].parent_id != parent_id: continue
		for body: Dictionary in _members(id): body.erase("command_army_id_r12")
		_type_cohorts_r12.erase(id); _role_layouts_r2.erase(id)


func _prune_type_cohorts_r12() -> void:
	for id: String in _type_cohorts_r12.keys():
		var cohort: Dictionary = _type_cohorts_r12[id]
		var ids: Array = []
		for member_id: String in cohort.member_ids:
			var body: Dictionary = _soldiers.get(member_id,{})
			if not body.is_empty() and int(body.hp)>0 and body.warband_id==cohort.parent_id and body.unit_type==cohort.unit_type and body.get("command_army_id_r12")==id: ids.append(member_id)
			elif body.get("command_army_id_r12")==id: body.erase("command_army_id_r12")
		cohort.member_ids=ids; cohort.living_count=ids.size()
		if ids.is_empty() or not _warbands.has(cohort.parent_id):
			_type_cohorts_r12.erase(id); _role_layouts_r2.erase(id)


func configure_ai_hero_withdrawals(side: String, leases: Dictionary) -> Dictionary:
	# Trusted Session -> actual computer controller seam, not a command field.
	# Calling UNIT_MOVE, including a forged client lease, cannot enable this.
	if str(_side_config.get(side,{}).get("controller","")) != "AI": return _reject("NOT_COMPUTER_SIDE")
	for id: Variant in leases:
		if typeof(id) != TYPE_STRING or typeof(leases[id]) != TYPE_INT: return _reject("INVALID_HERO_WITHDRAWAL")
		var unit: Dictionary = _soldiers.get(id,{})
		if unit.get("side") != side or unit.get("unit_type") != "hero" or int(unit.get("hp",0)) <= 0: return _reject("INVALID_HERO_WITHDRAWAL")
		if int(leases[id]) <= _tick or int(leases[id]) > _tick+120: return _reject("INVALID_HERO_WITHDRAWAL")
	for id: String in _ai_hero_withdrawals.keys():
		if _soldiers.get(id,{}).get("side") == side: _ai_hero_withdrawals.erase(id)
	for id: String in leases: _ai_hero_withdrawals[id] = int(leases[id])
	return _accept({"lease_count":leases.size()})


func _preserving_ai_hero_withdrawal(unit: Dictionary) -> bool:
	return str(_side_config.get(str(unit.get("side","")),{}).get("controller","")) == "AI" and unit.get("unit_type") == "hero" and int(unit.get("hp",0)) > 0 and unit.get("direct_intent") == "MOVE" and int(_ai_hero_withdrawals.get(str(unit.get("id","")),-1)) > _tick


func world_military_facts_m93() -> Array[Dictionary]:
	# Internal World consumers need scalar military facts, not skills/backpacks.
	# The Host transfers the full canonical hero roster separately first.
	return MilitaryFactsM93.project(_ordered_units())


func _m93_context_current() -> RefCounted:
	return _m93_context


func _m93_begin() -> void:
	assert(_m93_context == null)
	_m93_context = PreparationContextM93.new(_ordered_units())
	_m93_phase_builds += 1


func _m93_end() -> void:
	_m93_phase_queries += int(_m93_context.queries)
	_m93_phase_candidates += int(_m93_context.candidates)
	_m93_context = null


func _m94_begin_actions() -> void:
	_m94_action_context = null
	_m94_action_active = true


func _m94_end_actions() -> void:
	_m94_action_active = false
	_m94_action_context = null


func _m94_support_context() -> RefCounted:
	if not _m94_action_active: return null
	if _m94_action_context == null:
		_m94_action_context = ActionContextM94.new(_ordered_units())
	return _m94_action_context


func advance_owned_m93(tick: int, phase: String, buildings: Array, technology: Dictionary) -> Array:
	# Host supplies fresh detached facts. Independent public callers still copy.
	_m93_owned_environment = true
	var result: Array = advance_tick(tick, phase, buildings, technology)
	_m93_owned_environment = false
	return result


func sync_environment_owned_m93(buildings: Array, terrain: Array) -> void:
	sync_terrain_m76(terrain)
	_m93_owned_environment = true
	_cache_buildings(buildings)
	_m93_owned_environment = false


func apply_settled_world_events_m93(events: Array) -> void:
	# Host-only: Combat has already reindexed, then World has settled. No
	# military writes intervene except this event stream; public API is unchanged.
	if events.is_empty():
		_m93_empty_event_skips += 1
		return
	apply_world_events(events, true)


func advance_tick(tick: int, phase: String, buildings: Array, technology: Dictionary) -> Array:
	if tick < 0 or tick <= _tick or phase not in ["PREPARATION", "BATTLE"]:
		_m90_order_scope = false
		_m90_invalidate_order()
		return []
	_m90_invalidate_order()
	_m90_order_scope = true
	_tick = tick
	_expire_corpses_r9()
	_m95_stats_begin_trusted_scope()
	_hero_statistics.advance_controls(_soldiers,_tick)
	_finish_expired_buff_feedback()
	_route_plans=0
	_recovery_plans_r11=0
	_recovery_reserve_r11=_recovery_pending_r11
	_recovery_pending_r11=false;_recovery_waiting_r11=false
	_cache_buildings(buildings)
	for side: String in _sides:
		var levels: Variant = technology.get(side, {})
		if levels is Dictionary:
			_technology[side] = {"ATTACK": clampi(int(levels.get("ATTACK", 0)), 0, 3), "ARMOR": clampi(int(levels.get("ARMOR", 0)), 0, 3)}
			for definition:Dictionary in TechnologiesV4.list_for(_faction(side)):_technology[side][definition.id]=clampi(int(levels.get(definition.id,0)),0,1)
	_m93_begin()
	_rebuild_hero_auras(phase=="BATTLE")
	Innates.prepare(self)
	if phase=="BATTLE":ArmySupport.prepare(self)
	_m93_end()
	for unit: Dictionary in _ordered_units():
		unit["cooldown_ticks"] = maxi(0, int(unit["cooldown_ticks"]) - 1)
		unit["heal_cooldown_ticks"] = maxi(0, int(unit["heal_cooldown_ticks"]) - 1)
		_refresh_stats(unit)
		if phase=="BATTLE" and not bool(unit.get("neutral",false)): _advance_hero_base_recovery(unit)
		if not _hero_data.has(str(unit.id)) and int(unit.hp)>0 and int(unit.get("max_mana",0))>0:
			unit["mana_regen_milli"]=int(unit.get("mana_regen_milli",0))+roundi(float(unit.get("mana_regen_per_second",0))*50.0)
			if int(unit.mana_regen_milli)>=1000:
				unit.mana=mini(int(unit.max_mana),int(unit.mana)+int(unit.mana_regen_milli)/1000)
				unit.mana_regen_milli=int(unit.mana_regen_milli)%1000
	for hero: Dictionary in _hero_data.values():
		for skill: String in hero["cooldowns"]:
			hero["cooldowns"][skill] = maxi(0, int(hero["cooldowns"][skill]) - 1)
		if int(_hero_body_r9(str(hero.id)).get("hp",0)) > 0:
			var item_hp_before := int(_soldiers[hero.id].hp)
			ItemRules.tick_passives(hero,_soldiers[hero.id],_tick)
			_hero_statistics.heal(_soldiers[hero.id],_soldiers[hero.id],int(_soldiers[hero.id].hp)-item_hp_before,{"id":"ITEM_RECOVERY","category":"ITEM"})
			_healing_feedback_r9(_soldiers[hero.id],_soldiers[hero.id],int(_soldiers[hero.id].hp)-item_hp_before,{"id":"ITEM_RECOVERY"})
			hero["mana_regen_progress_ticks"] = int(hero["mana_regen_progress_ticks"]) + 1
			if int(hero["mana_regen_progress_ticks"]) >= int(hero["mana_regen_ticks"]):
				hero["mana_regen_progress_ticks"] = 0
				hero["mana"] = mini(int(hero["max_mana"]),int(hero["mana"])+1)
			var regen_body:Dictionary=_soldiers[hero.id]
			var extra_mana:=float(regen_body.get("technology_modifiers_v4",{}).get("mana_regen_per_second",0.0))
			var carry:=int(regen_body.get("technology_mana_carry_v4",0))+roundi(extra_mana*50.0)
			hero.mana=mini(int(hero.max_mana),int(hero.mana)+carry/1000)
			regen_body["technology_mana_carry_v4"]=carry%1000
	if phase == "BATTLE":
		EliteRuntimeR4.prepare(self)
		_r7_skills.advance(self)
		_advance_status_damage()
		_advance_innate_effects()
	if phase == "BATTLE": _advance_hero_automation()
	_targeting.prepare(_ordered_units(),_ordered_buildings(),_tick,_hero_data)
	# Neutral camps share one ordered, current candidate projection during this
	# acquisition batch. Bodies remain live references, not a stale world cache.
	_neutral_candidates_m76.clear()
	_choosing_targets_m76 = true
	m84_layout_contexts.clear()
	m84_layout_active = true
	var targets := {}
	var bodies: Array[Dictionary] = []
	# Select once, using the existing shared spatial index and reservation rules.
	# Group contact is known before anchor/stride decisions; no forecast or new
	# all-enemy search is introduced for formation pacing.
	for unit: Dictionary in _ordered_units():
		var target := _choose_target(unit, phase)
		targets[str(unit.id)] = target
		if not bool(unit.get("neutral",false)): _targeting.reserve(unit,target)
		if phase=="BATTLE" and _group_combat_member_r13(unit):
			var owner:=_control_army_r12(unit)
			_targeting.record_group_contact_r13(unit,owner,target,_formation_slot_r12(unit,owner))
	# Only empty automatic selections may join a contact independently found
	# by this same effective formation. This keeps the fighting front stopped
	# at its real weapon reach, while its distant rear closes at natural speed.
	# The pool is capped at eight current IDs and never expands by relaying an
	# assisted target. Arena and normal battles use this one authority path.
	if phase=="BATTLE":
		for unit: Dictionary in _ordered_units():
			if not targets[str(unit.id)].is_empty() or not _group_combat_member_r13(unit):continue
			var owner:=_control_army_r12(unit)
			var joined:Dictionary=_targeting.join_group_contact_r13(unit,owner,_formation_slot_r12(unit,owner))
			if joined.is_empty():continue
			targets[str(unit.id)]=joined
			_targeting.reserve(unit,joined)
	_prepare_march_r12(targets)
	_advance_anchors(phase)
	_m96_begin_route_batch()
	for unit: Dictionary in _ordered_units():
		var target: Dictionary = targets[str(unit.id)]
		var desired_position := _desired_position(unit,target)
		var movement_credit:=float(unit.get("movement_fraction",0))+_march_speed_r12(unit,desired_position)
		unit["movement_step"]=floori(movement_credit)
		unit["movement_fraction"]=movement_credit-float(unit.movement_step)
		var desired:=_navigation_destination(unit,desired_position,target)
		var previous_position: Vector2i=unit.position-unit.last_move_direction if int(unit.last_move_tick)==_tick-1 else unit.position
		bodies.append({"id": unit["id"], "position": unit["position"], "desired":desired,"steering_goal":unit.steering_goal,"previous_position":previous_position, "radius": unit["radius"],"movement_layer":unit["movement_layer"], "active": int(unit["hp"]) > 0, "max_step": 0 if unit["direct_intent"] in ["HOLD", "AUTO_HOLD"] or _movement_controlled(unit) else int(unit.movement_step)})
	_m96_end_route_batch()
	_choosing_targets_m76 = false
	# Fair admission uses the movement traversal we already performed. After
	# reaching the end of the stable ID order, wrap on the next tick; no extra
	# full-army scan/queue of bodies or unbounded retained requests is needed.
	if _recovery_plans_r11==0 and _recovery_waiting_r11:_recovery_cursor_r11=""
	m84_layout_active = false
	m84_layout_contexts.clear()
	_march_profiles_r12.clear()
	for building: Dictionary in _ordered_buildings():
		if int(building.get("hp", 0)) > 0:
			bodies.append({"id": "structure:" + str(building["id"]), "position": building["position"], "desired": building["position"], "radius": int(building.get("radius", 40 if building.get("building_type") == "BASE" else 32)), "active": true, "max_step": 0,"static":not _is_worker(building)})
	var maximum_step := 7
	for unit: Dictionary in _ordered_units(): maximum_step = maxi(maximum_step, int(unit.get("movement_step",unit.speed)))
	for prop: Dictionary in _terrain:
		bodies.append({"id":"terrain:"+str(prop.id),"position":prop.position,"desired":prop.position,"radius":prop.radius,"active":true,"max_step":0,"movement_layer":"GROUND","static":true})
	var positions := BodyResolver.resolve(bodies, _bounds, maximum_step)
	for unit: Dictionary in _ordered_units():
		var movement: Vector2i = positions[unit["id"]] - (unit["position"] as Vector2i)
		if movement != Vector2i.ZERO:
			unit["last_move_tick"] = _tick
			unit["last_move_direction"] = movement
		unit["position"] = positions[unit["id"]]
	if phase != "BATTLE":
		_m95_stats_end_trusted_scope()
		_m90_order_scope = false
		_m90_invalidate_order()
		return []
	var damage := {}
	var killers := {}
	var building_hits: Array = []
	building_hits.append_array(take_external_hits())
	var healing := {}
	var healing_feedback:Array[Dictionary]=[]
	_statistics_batching = true
	_statistics_pending_hits.clear()
	_m94_begin_actions()
	_r4_pending_damage=damage
	EliteRuntimeR4.prepare(self,true,damage,killers)
	if _neutrals != null: _neutrals.advance_skills(self, targets, damage, killers)
	for unit: Dictionary in _ordered_units():
		if int(unit["hp"]) <= 0 or _stunned(unit) or _r7_skills.is_busy(str(unit.id)): continue
		var target: Dictionary = targets[unit["id"]]
		unit["target_id"] = str(target.get("id", ""))
		TroopRuntimeV4.try_action(unit,target,self,damage,killers)
		if not target.is_empty() and int(unit["cooldown_ticks"]) == 0 and _in_attack_range(unit, target):
			unit["cooldown_ticks"] = unit["attack_cooldown_ticks"]
			_record_action(unit, "ATTACK", target["position"])
			unit["last_action_target_id"]=str(target.id)
			unit["last_action_target_side"]=str(target.side)
			_feedback("ATTACK",unit,target,{"attack_type":unit.attack_type})
			_consume_buffs(unit,"ATTACK")
			# Retain the resolved primary layer; a later target selection must
			# not make a ground-only splash look as though it hit an AIR target.
			unit["last_action_target_layer"] = str(target.get("movement_layer", "GROUND"))
			unit["last_action_targets"]=[{"id":target.id,"position":target.position}]
			var raw := float(unit["damage"])
			if target.get("movement_layer","GROUND")=="AIR":raw+=float(unit.get("bonus_vs_air",0))
			if str(unit.get("bonus_vs_tag","")) in target.get("tags",[]): raw += int(unit.get("bonus_damage",0))
			if _soldiers.has(target.id) and int(target.get("hp",0))*100 <= int(target.get("max_hp",100))*35: raw = raw * (100+int(unit.get("execute_percent",0))) / 100
			raw+=Innates.attack_raw_bonus(unit,target,float(unit.get("base_damage",unit.damage)),self)
			raw*=float(Innates.outgoing_basic_percent(unit,self))/100.0
			raw*=TroopRuntimeV4.basic_multiplier(unit,target,_technology_modifiers_v4(str(unit.side)))
			var amount := _resolve_damage(raw,str(unit.attack_type),target,unit,true)
			if target.get("building_type", "") == "WORKER_OBSTACLE":
				building_hits.append({"worker_id":target["id"],"damage":amount,"side":unit["side"],"unit_id":unit["id"],"stats_cause":{"id":"BASIC","category":"BASIC"}})
			elif _buildings.has(target["id"]):
				building_hits.append({"building_id": target["id"], "damage": amount, "side": unit["side"], "unit_id": unit["id"],"stats_cause":{"id":"BASIC","category":"BASIC"}})
			else:
				var settled:=_deal_body_damage_r4(target,unit,amount,str(unit.attack_type),{"id":"BASIC","category":"BASIC"},damage,killers,true)
				var actual:=int(settled.primary)
				if actual > 0:
					var drain := float(unit.get("drain_percent",0)) + float(unit.get("buff_drain_percent",0)) + float(_technology_modifiers_v4(str(unit.side)).lifesteal_percent)
					var drained := _lifesteal_credit(unit,"BASIC_LIFESTEAL",float(settled.total)*drain/100.0)
					healing[unit.id] = int(healing.get(unit.id,0)) + drained
					healing_feedback.append({"source":unit,"target":unit,"amount":drained,"cause":{"id":"BASIC_LIFESTEAL","category":"BASIC"},"silent":true})
					if _hero_data.has(unit.id):
						var equipment_drain := ItemRules.equipment_drain(_hero_data[unit.id], int(settled.total))
						healing[unit.id] = int(healing.get(unit.id, 0)) + equipment_drain
						healing_feedback.append({"source":unit,"target":unit,"amount":equipment_drain,"cause":{"id":"ITEM_LIFESTEAL","category":"ITEM"},"silent":true})
					if int(unit.get("status_icd_ticks",0))==0:_apply_signature(unit,target,unit)
					TroopRuntimeV4.on_basic_hit(unit,target,self,_technology_modifiers_v4(str(unit.side)))
				if not killers.has(target["id"]): killers[target["id"]] = unit["id"]
			_add_splash_hits(unit,target,damage,killers,building_hits)
			TroopRuntimeV4.add_line_hits(unit,target,self,damage,killers,building_hits)
		var used_support:=ArmySupport.try_action(unit,self)
		if not used_support and int(unit.get("heal",0))>0 and int(unit["heal_cooldown_ticks"]) == 0 and int(unit.get("mana",0))>=int(unit.get("heal_mana_cost",0)):
			var recipients:=_injured_recipients(unit,int(unit.heal_range),maxi(1,int(unit.get("heal_max_targets",1))))
			if not recipients.is_empty():
				unit.mana=int(unit.get("mana",0))-int(unit.get("heal_mana_cost",0))
				_hero_statistics.cast(unit,"SUPPORT_HEAL")
				var powers:=Buffs.values(unit,_tick,_soldiers)
				for ally: Dictionary in recipients:
					var heal_amount:=roundi(float(unit.heal)*(1.0+float(powers.healing_percent)/100.0)*float(Innates.healing_received_percent(ally,true))/100.0)
					healing[ally.id]=int(healing.get(ally.id,0))+heal_amount
					healing_feedback.append({"source":unit,"target":ally,"amount":heal_amount})
					if int(unit.get("heal_guard",0))>0:_grant_guard(ally,int(unit.heal_guard),int(unit.get("heal_guard_duration_ticks",40)))
				_consume_buffs(unit,"PAID_SKILL")
				unit["heal_cooldown_ticks"] = int(unit["heal_max_cooldown_ticks"])
				_record_action(unit,"HEAL",recipients[0].position)
				# Existing single-target cleanse does not multiply with group size.
				if bool(unit.get("cleanse_dot",false)):_cleanse_dots(recipients[0])
	_m94_end_actions()
	_r4_pending_damage={}
	_statistics_batching = false
	for victim_id: String in damage:
		var victim: Dictionary = _soldiers[victim_id]
		var statistics_hp_before := int(victim.hp)
		victim["hp"] = maxi(0, int(victim["hp"]) - int(damage[victim_id]))
		victim["alive"] = int(victim["hp"]) > 0
		# The legacy batch reserves attack damage before some signatures flush
		# old partial DoT immediately. Only HP actually left for this batch can
		# enter the new observational ledger; do not move gameplay/VFX/AI hooks.
		var statistics_remaining := statistics_hp_before-int(victim.hp)
		for hit: Dictionary in _statistics_pending_hits.get(victim_id,[]):
			var statistics_actual := mini(statistics_remaining,int(hit.amount))
			if statistics_actual <= 0: continue
			_hero_statistics.damage(hit.source,victim,statistics_actual,_tick,hit.cause)
			_damage_feedback_r9(victim,hit.source,statistics_actual,str(hit.get("attack_type",victim.get("last_damage_attack_type","SLASH"))),hit.cause)
			statistics_remaining -= statistics_actual
		_after_body_hp_damage_r3(victim,statistics_hp_before)
	_statistics_pending_hits.clear()
	var actual_healing:={}
	for ally_id: String in healing:
		var ally: Dictionary = _soldiers[ally_id]
		if int(ally["hp"]) > 0:
			var before_hp:int=ally.hp
			ally["hp"] = mini(int(ally["max_hp"]), int(ally["hp"]) + int(healing[ally_id]))
			actual_healing[ally_id]=int(ally.hp)-before_hp
	for receipt:Dictionary in healing_feedback:
		var actual:=mini(int(receipt.amount),int(actual_healing.get(receipt.target.id,0)))
		if actual<=0:continue
		actual_healing[receipt.target.id]=int(actual_healing[receipt.target.id])-actual
		_hero_statistics.heal(receipt.source,receipt.target,actual,receipt.get("cause",{"id":"SUPPORT_HEAL","category":"OTHER"}))
		_feedback("HEAL",receipt.source,receipt.target,{"amount":actual,"skill_id":receipt.get("cause",{}).get("id","SUPPORT_HEAL"),"silent_audio":bool(receipt.get("silent",false))})
	for victim_id: String in killers:
		if int(_soldiers[victim_id]["hp"]) == 0: _credit_kill(str(killers[victim_id]), victim_id)
	_announce_innate_statuses()
	_reindex()
	_m95_stats_end_trusted_scope()
	_m90_order_scope = false
	_m90_invalidate_order()
	return building_hits


func apply_world_events(events: Array, paid_production: bool = false) -> void:
	var elite_prepared:=false
	# Admission reads the old hero roster before same-ID paid resurrection;
	# never reuse that list across a mutable production/recall event stream.
	var previous_scope := _m90_order_scope
	_m90_order_scope = false
	_m90_invalidate_order()
	# Only the adapter's completed World production stream sets paid_production.
	# Player/AI commands cannot submit events or grant themselves this provenance.
	# The default trusted fixture stream retains its original spawn semantics.
	var admission_aliases := {}
	for value: Variant in events:
		if not value is Dictionary: continue
		var event: Dictionary = value
		if event.get("type") == "DAMAGE":
			var id: Variant = event.get("target_id")
			# World towers settle after production and may refer to the newly
			# emitted recruit ID. Preserve that same-tick hit on the named body;
			# old receipts are never perpetual target aliases for later batches.
			if paid_production and typeof(id) == TYPE_STRING and admission_aliases.has(id): id = admission_aliases[id]
			if typeof(id) != TYPE_STRING or not _soldiers.has(id) or typeof(event.get("damage")) != TYPE_INT or int(event["damage"]) <= 0: continue
			var victim: Dictionary = _soldiers[id]
			if event.get("side") not in _sides or event["side"] == victim["side"] or int(victim["hp"]) <= 0: continue
			var attack_type := str(event.get("attack_type","EDGE"))
			var source:Dictionary=_buildings.get(str(event.get("source_id","")),{"id":str(event.get("source_id","")),"faction_id":_faction(str(event.side)),"side":event.side,"attack_type":attack_type,"attack_range":240})
			var amount := _resolve_damage(float(event.damage),attack_type,victim,source,true)
			if not elite_prepared:
				EliteRuntimeR4.prepare(self)
				elite_prepared=true
			_deal_body_damage_r4(victim,source,amount,attack_type)
			if not victim.alive: _credit_death_for_side(str(event.side),str(event.get("source_id","")),str(id))
		elif event.get("type") == "SPAWN":
			var side: Variant = event.get("side")
			var unit_type: Variant = event.get("unit_type")
			var army_id: Variant = event.get("warband_id", _prefix(str(side)) + "_reserve")
			var archetype: Variant = event.get("hero_archetype", Factions.default_hero(_faction(str(side))))
			if typeof(archetype) != TYPE_STRING or (event.has("hero_archetype") and unit_type != "hero") or archetype not in HeroCatalog.ARCHETYPES: continue
			if side not in _sides or typeof(unit_type) != TYPE_STRING or unit_type=="worker" or stats_for_type(unit_type, archetype).is_empty() or not _valid_point(event.get("position")): continue
			if unit_type=="hero" and archetype not in Factions.heroes_for(_faction(side)):continue
			if unit_type!="hero" and Units.UNITS[unit_type].faction_id!=_faction(side):continue
			if typeof(army_id) != TYPE_STRING: continue
			if _warbands.has(army_id) and _warbands[army_id]["side"] != side: continue
			if not str(army_id).is_empty() and not _warbands.has(army_id) and not str(army_id).begins_with(_prefix(side) + "_"): continue
			if str(army_id).is_empty() or not _warbands.has(army_id): army_id = _prefix(side) + "_reserve"
			if unit_type == "hero" and (_has_living_hero(side, archetype) or _living_hero_count(side) >= HeroCatalog.MAX_ACTIVE_HEROES): continue
			if paid_production and unit_type == "hero" and typeof(event.get("id")) != TYPE_STRING: continue
			var id: Variant = event.get("id", "recruit_%s_%04d" % [_prefix(side), _spawn_serial + 1])
			if typeof(id) != TYPE_STRING or str(id).is_empty() or _soldiers.has(id): continue
			if paid_production and unit_type == "hero" and _paid_hero_receipts.has(id): continue
			var hero_slot := 0
			if unit_type == "hero":
				var fallen_id := _fallen_hero_id(side,archetype)
				hero_slot = int(event.get("hero_slot",_hero_data[fallen_id].get("hero_slot",0) if not fallen_id.is_empty() else _empty_hero_slot(side)))
				if hero_slot < 1 or hero_slot > HeroCatalog.MAX_ACTIVE_HEROES: continue
				if paid_production and event.has("hero_mode"):
					if event.hero_mode == "REVIVE":
						if fallen_id.is_empty() or event.get("hero_id","") != fallen_id or int(_hero_data[fallen_id].get("hero_slot",0)) != hero_slot: continue
						if int(event.get("hero_life_generation",0)) != int(_hero_body_r9(fallen_id).get("life_generation",1)): continue
					elif event.hero_mode != "RECRUIT" or not fallen_id.is_empty(): continue
				if fallen_id.is_empty():
					var occupied := false
					for hero: Dictionary in get_hero_roster():
						if hero.side == side and int(hero.hero_slot) == hero_slot: occupied = true
					if occupied: continue
			var radius := int(stats_for_type(unit_type, archetype)["radius"])
			if not _spawn_clear(event["position"], radius,str(Units.UNITS[unit_type].movement_layer)): continue
			_spawn_serial += 1
			if paid_production and unit_type == "hero":
				var fallen_id := _fallen_hero_id(side, archetype)
				if not fallen_id.is_empty():
					var next_life := int(_hero_body_r9(fallen_id).get("life_generation",1))+1
					_retired_heroes_r9.erase(fallen_id);_corpse_deadlines_r9.erase(fallen_id)
					# Fresh physical body, same named officer record. In particular,
					# _add_unit must not overwrite progression or refill potions.
					_soldiers[fallen_id] = _new_body(fallen_id, side, "hero", army_id, event["position"], archetype)
					_soldiers[fallen_id]["life_generation"]=next_life
					# A former aura source becoming alive must not resurrect an old
					# rally on other units, even for instantaneous trusted fixtures.
					for ally: Dictionary in _ordered_units():
						if ally.get("rally_source_id", "") == fallen_id:
							ally["rally_until_tick"] = -1
							ally["rally_source_id"] = ""
					_refresh_stats(_soldiers[fallen_id])
					_soldiers[fallen_id]["hp"] = _soldiers[fallen_id]["max_hp"]
					_hero_data[fallen_id]["mana"] = _hero_data[fallen_id]["max_mana"]
					_hero_data[fallen_id]["mana_regen_progress_ticks"] = 0
					_paid_hero_receipts[id] = fallen_id
					admission_aliases[id] = fallen_id
					continue
			_add_unit(id, side, unit_type, army_id, event["position"], archetype,hero_slot)
			if paid_production and unit_type == "hero": _paid_hero_receipts[id] = id
	_reindex()
	_m90_order_scope = previous_scope
	_m90_invalidate_order()


func sync_environment(buildings: Array,terrain: Array=[]) -> void:
	# Adapter refreshes obstacles after world workers move and before spawns.
	sync_terrain_m76(terrain)
	_cache_buildings(buildings)


func sync_terrain_m76(terrain: Array=[]) -> void:
	# Internal host seam immediately before advance_tick, which already caches
	# the same building observations. Public sync_environment keeps doing both.
	_terrain.clear()
	for prop: Dictionary in terrain if not terrain.is_empty() else _match.get("terrain",[]):
		if bool(prop.get("blocks_ground",false)):_terrain.append(prop.duplicate(true))


func get_hero_roster() -> Array:
	var result: Array = []
	for id: String in _sorted_keys(_hero_data):
		var hero: Dictionary = _hero_data[id]
		var unit: Dictionary = _hero_body_r9(id)
		result.append({"id":id,"unit_id":id,"side":unit.side,"archetype":hero.archetype,"hero_archetype":hero.archetype,"level":int(hero.level),"alive":int(unit.hp)>0 and bool(unit.alive),"hero_slot":int(hero.get("hero_slot",1)),"life_generation":int(unit.get("life_generation",1))})
		result[-1]["inventory"]=hero.inventory.duplicate(true)
		result[-1]["equipment"]=hero.equipment.duplicate()
	return result


func _empty_hero_slot(side: String) -> int:
	var used := {}
	for hero: Dictionary in get_hero_roster():
		if hero.side == side: used[int(hero.hero_slot)] = true
	for slot: int in range(1,HeroCatalog.MAX_ACTIVE_HEROES+1):
		if not used.has(slot): return slot
	return 0


func _hero_body_r9(id: String) -> Dictionary:
	return _soldiers.get(id,_retired_heroes_r9.get(id,{}))

func _schedule_corpse_r9(body: Dictionary) -> void:
	var id := str(body.id)
	if _corpse_deadlines_r9.has(id): return
	var due := maxi(0,_tick)+CORPSE_TTL_R9
	_corpse_deadlines_r9[id]=due
	if not _corpse_buckets_r9.has(due):
		_corpse_buckets_r9[due]=[];_corpse_ticks_r9.append(due)
	_corpse_buckets_r9[due].append(id)

func _expire_corpses_r9() -> void:
	# No full dead-body scan: only buckets whose ten-second deadline arrived.
	while not _corpse_ticks_r9.is_empty() and _corpse_ticks_r9[0]<=_tick:
		var due := _corpse_ticks_r9.pop_front() as int
		var ids: Array = _corpse_buckets_r9.get(due,[])
		_corpse_buckets_r9.erase(due)
		for id: String in ids:
			if int(_corpse_deadlines_r9.get(id,-1))!=due:continue
			_corpse_deadlines_r9.erase(id)
			var body: Dictionary = _soldiers.get(id,{})
			if body.is_empty() or int(body.hp)>0:continue
			if _hero_data.has(id):
				# Permanent identity, growth, bag and death statistics must survive.
				# Keep only cold scalar readout facts, never the entity/path/buff maps.
				var record := {}
				for key: String in body:
					if not body[key] is Dictionary and not body[key] is Array:record[key]=body[key]
				record["attack_layers"]=body.get("attack_layers",[]).duplicate()
				for key: String in ["combat_statuses","source_buffs","secondary_effects","innate_aura","innate_shield"]:record[key]={}
				record.attribute_base=body.get("attribute_base",{}).duplicate(true)
				record.last_skill_targets=[];record.route=[]
				_retired_heroes_r9[id]=record
			_soldiers.erase(id)
			_m87_baselines.erase(id);_m95_stat_dependencies.forget_body(id)
			_ai_hero_withdrawals.erase(id);_hero_aura_bonuses.erase(id)
			_m96_route_work.erase(id);_r4_elite_dirty=true
			for army: Dictionary in _warbands.values():(army.member_ids as Array).erase(id)
		_m90_invalidate_order()

func get_units_snapshot() -> Array[Dictionary]:
	# Internal world synchronization needs living body facts, not expensive
	# officer skill/item descriptions and hero-statistics UI projections.
	var result: Array[Dictionary]=[]
	for unit: Dictionary in _ordered_units(): result.append(unit.duplicate(true))
	return result

func get_living_body_sides_m87() -> Array[String]:
	# Outcome needs only these current scalar facts, not detached nested bodies.
	# Preserve the authoritative alive flag (not an hp approximation), ordering
	# and unknown/neutral sides; the consumer owns its playable-side filter.
	var result: Array[String] = []
	for unit: Dictionary in _ordered_units():
		if bool(unit.get("alive", false)): result.append(str(unit["side"]))
	return result

func get_snapshot() -> Dictionary:
	var armies: Array = []
	for id: String in _sorted_keys(_warbands):
		armies.append((_warbands[id] as Dictionary).duplicate(true))
	var units: Array = []
	for unit: Dictionary in _ordered_units():
		var body := unit.duplicate(true)
		if bool(unit.get("neutral",false)):
			body["attribute_base"] = unit.get("neutral_base_stats",{}).duplicate(true)
		body["aura_sources"] = _published_aura_sources(str(unit.id))
		body["status_effects"] = _status_effects(unit)
		body["innate"]=Innates.profile(str(unit.get("hero_archetype","")),int(_hero_data.get(str(unit.id),{}).get("level",1)))
		if _hero_data.has(str(unit.id)):
			body["mana"]=int(_hero_data[unit.id].mana)
			body["max_mana"]=int(_hero_data[unit.id].max_mana)
			body["level"]=int(_hero_data[unit.id].level)
		units.append(body)
	var officers: Array = []
	for id: String in _sorted_keys(_hero_data):
		var hero: Dictionary = _hero_data[id].duplicate(true)
		var unit: Dictionary = _hero_body_r9(id)
		hero["hero_archetype"] = unit["hero_archetype"]
		hero["life_generation"] = int(unit.get("life_generation",1))
		for key: String in ["side", "faction_id","movement_layer","attack_layers","body_kind","radius", "warband_id", "position", "hp", "max_hp", "damage", "armor", "alive", "attack_range", "speed", "stun_until_tick", "root_until_tick", "last_action_tick", "last_action_kind", "last_action_target_position", "last_action_target_layer", "last_action_skill_level", "last_action_radius", "last_skill_tick", "last_skill_id", "last_skill_target_position", "last_skill_level", "last_skill_radius", "direct_intent", "attack_type", "armor_type", "trait_id", "trait_name", "trait_description", "last_skill_targets", "last_action_attack_type", "last_damage_tick", "last_damage_amount", "last_damage_attack_type", "last_damage_source_id", "last_damage_source_faction"]: hero[key] = unit[key]
		hero["status_effects"] = _status_effects(unit)
		hero["attribute_base"] = unit.get("attribute_base",{}).duplicate(true)
		hero["aura_sources"] = _published_aura_sources(id)
		var nearby_allies:Array=[]
		for ally:Dictionary in _ordered_units():
			if ally.side==unit.side and int(ally.hp)>0 and _distance_sq(ally.position,unit.position)<=180*180:nearby_allies.append(ally)
		hero.merge(ItemRules.slot_snapshot(hero, _tick,nearby_allies))
		hero["state"] = "ACTIVE" if int(unit["hp"]) > 0 else "INCAPACITATED"
		hero["damage_bonus"] = int(unit["damage"]) - int(stats_for_type("hero", hero["archetype"])["damage"])
		hero["next_level_xp"] = HeroProgression.next_level_xp(int(hero.level))
		hero["max_level"] = HeroProgression.MAX_LEVEL
		hero["role_id"] = HeroProgression.role(str(hero.archetype))
		hero["innate"]=Innates.profile(str(hero.archetype),int(hero.level))
		hero["innate_aura"]=unit.get("innate_aura",{}).duplicate(true)
		hero["growth"] = HeroProgression.growth(str(hero.archetype))
		hero["growth_description"] = HeroProgression.growth_description(str(hero.archetype))
		hero["xp_share_radius"] = HeroProgression.SHARED_XP_RADIUS
		var skills: Array = []
		for skill_id: String in HeroCatalog.profile(hero["archetype"])["skill_ids"]:
			var skill := _published_skill(hero, skill_id)
			skill["cooldown_ticks"] = hero["cooldowns"][skill_id]
			skills.append(skill)
		hero["skills"] = skills
		officers.append(hero)
	var result := {"warbands": armies, "soldiers": units, "heroes": {"enabled": true, "officers": officers}, "tick": _tick, "seed": _seed,"match_setup":_match.duplicate(true),"combat_feedback_events":_feedback_events.duplicate(true),"hero_statistics":get_hero_statistics()}
	result["type_cohorts_r12"] = _type_cohorts_r12.duplicate(true)
	result["hero_rework_r7"] = _r7_skills.get_snapshot()
	if _neutrals != null: result.merge(_neutrals.get_snapshot(), true)
	return result

func _published_aura_sources(unit_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var bonus: Dictionary = _hero_aura_bonuses.get(unit_id,{})
	for field: String in _sorted_keys(bonus.get("sources",{})):
		if float(bonus.get(field,0))<=0: continue
		var source: Dictionary = bonus.sources[field].duplicate(true)
		source["source_id"] = str(source.get("id",""))
		source["field"] = field
		source["amount"] = float(bonus[field])
		if source.get("stats_category","")=="ITEM":
			var item_field: String = {"damage":"aura_damage","armor":"aura_armor","heal_per_second":"aura_heal","mana_per_second":"aura_mana_regen"}.get(field,"")
			for item_id: String in _hero_data.get(str(source.source_id),{}).get("equipment",[]):
				if not item_field.is_empty() and is_equal_approx(float(ItemRules.ITEMS.get(item_id,{}).get(item_field,0)),float(source.amount)):
					source["item_id"] = item_id
					break
		result.append(source)
	return result


func get_population() -> Dictionary:
	var result: Dictionary={}
	for side: String in _sides:result[side]=0
	for unit: Dictionary in _ordered_units():
		if int(unit["hp"]) > 0 and result.has(unit["side"]): result[unit["side"]] = int(result[unit["side"]]) + int(unit["population"])
	return result


func get_state() -> Dictionary:
	var state := {"seed": _seed, "tick": _tick, "warbands": _warbands.duplicate(true), "soldiers": _soldiers.duplicate(true), "hero_data": _hero_data.duplicate(true), "ai_hero_withdrawals":_ai_hero_withdrawals.duplicate(true), "shared_xp_receipts":_shared_xp_receipts.duplicate(true), "next_army": _next_army.duplicate(true), "spawn_serial": _spawn_serial, "paid_hero_receipts": _paid_hero_receipts.duplicate(true), "paid_item_receipts": _paid_item_receipts.duplicate(true), "field_reward_receipts":_field_reward_receipts.duplicate(true), "technology": _technology.duplicate(true), "buildings": _buildings.duplicate(true), "external_hits":_external_hits.duplicate(true),"match":_match.duplicate(true),"terrain":_terrain.duplicate(true),"route_plans":_route_plans,"neutral_encounters":_neutrals.get_state() if _neutrals != null else {},"hero_rework_r7":_r7_skills.get_state()}
	state["corpse_lifecycle_r9"]={"deadlines":_corpse_deadlines_r9.duplicate(),"buckets":_corpse_buckets_r9.duplicate(true),"ticks":_corpse_ticks_r9.duplicate(),"hero_records":_retired_heroes_r9.duplicate(true)}
	state["movement_recovery_r11"]={"cursor":_recovery_cursor_r11,"pending":_recovery_pending_r11,"reserved":_recovery_reserve_r11,"waiting":_recovery_waiting_r11,"plans":_recovery_plans_r11}
	state["type_cohorts_r12"]=_type_cohorts_r12.duplicate(true)
	return state


func take_external_hits() -> Array:
	var hits: Array = _external_hits.duplicate(true)
	_external_hits.clear()
	return hits


func get_warband_ids(side: String) -> Array:
	var ids: Array = []
	for id: String in _sorted_keys(_warbands):
		if _warbands[id]["side"] == side and not _warbands[id]["reserve"]: ids.append(id)
	return ids


func validate_item_purchase(command: Dictionary, side: String) -> Dictionary:
	# Read-only preflight before any World ledger payment or host cache sync.
	if side not in _sides or command.size() != 4: return _reject("INVALID_PURCHASE")
	for key: String in ["type", "unit_id", "item_id", "building_id"]:
		if typeof(command.get(key)) != TYPE_STRING: return _reject("INVALID_PURCHASE")
	if command["type"] != "BUY_ITEM" or str(command["building_id"]).is_empty(): return _reject("INVALID_PURCHASE")
	var id: String = command["unit_id"]
	if not _soldiers.has(id) or _soldiers[id]["side"] != side or int(_soldiers[id]["hp"]) <= 0 or not _hero_data.has(id): return _reject("INVALID_UNIT")
	var item: String = command["item_id"]
	return ItemRules.purchase_quote(_hero_data[id], item)


func grant_paid_item(receipt: Dictionary) -> Dictionary:
	# Only the synchronous host's validated World payment result reaches here;
	# no user/AI command accepts a receipt or inventory mutation payload.
	var purchase_id: Variant = receipt.get("purchase_id")
	if not receipt.get("accepted", false) or typeof(purchase_id) != TYPE_STRING or str(purchase_id).is_empty(): return _reject("INVALID_PURCHASE_RECEIPT")
	if _paid_item_receipts.has(purchase_id): return _reject("PURCHASE_ALREADY_APPLIED")
	var side: Variant = receipt.get("side")
	if side not in _sides or typeof(receipt.get("unit_id")) != TYPE_STRING or typeof(receipt.get("item_id")) != TYPE_STRING: return _reject("INVALID_PURCHASE_RECEIPT")
	var item: String = receipt["item_id"]
	if not HeroCatalog.ITEMS.has(item): return _reject("INVALID_PURCHASE_RECEIPT")
	var preflight := validate_item_purchase({"type":"BUY_ITEM", "unit_id":receipt["unit_id"], "item_id":item, "building_id":"paid_service"}, side)
	if not preflight["accepted"]: return preflight
	if receipt.get("cost")!=preflight.cost or receipt.get("quote_version")!=preflight.version or receipt.get("consumed_components")!=preflight.consumed_components:return _reject("INVALID_PURCHASE_RECEIPT")
	var hero: Dictionary = _hero_data[receipt["unit_id"]]
	var granted := ItemRules.grant_purchase(hero, item)
	if not granted.accepted: return granted
	_refresh_item_transaction_stats(receipt.unit_id, item)
	_paid_item_receipts[purchase_id] = {"unit_id":receipt["unit_id"], "item_id":item, "side":side}
	return _accept({"purchase_id":purchase_id})

func validate_item_sale(command: Dictionary, side: String) -> Dictionary:
	if side not in _sides or command.size() != 4: return _reject("INVALID_SALE")
	for key: String in ["type", "unit_id", "item_id", "building_id"]:
		if typeof(command.get(key)) != TYPE_STRING: return _reject("INVALID_SALE")
	if command.type != "SELL_ITEM" or str(command.building_id).is_empty(): return _reject("INVALID_SALE")
	var id: String = command.unit_id
	if not _soldiers.has(id) or _soldiers[id].side != side or int(_soldiers[id].hp) <= 0 or not _hero_data.has(id): return _reject("INVALID_UNIT")
	return ItemRules.validate_sell(_hero_data[id], command.item_id)

func settle_item_sale(receipt: Dictionary) -> Dictionary:
	var sale_id: Variant = receipt.get("sale_id")
	if not receipt.get("accepted", false) or typeof(sale_id) != TYPE_STRING or str(sale_id).is_empty(): return _reject("INVALID_SALE_RECEIPT")
	if _paid_item_receipts.has(sale_id): return _reject("SALE_ALREADY_APPLIED")
	if receipt.get("side") not in _sides or typeof(receipt.get("unit_id")) != TYPE_STRING or typeof(receipt.get("item_id")) != TYPE_STRING: return _reject("INVALID_SALE_RECEIPT")
	if not ItemRules.ITEMS.has(receipt.item_id) or receipt.get("refund") != ItemRules.sell_refund(receipt.item_id): return _reject("INVALID_SALE_RECEIPT")
	var valid := validate_item_sale({"type":"SELL_ITEM","unit_id":receipt.unit_id,"item_id":receipt.item_id,"building_id":"paid_service"}, receipt.side)
	if not valid.accepted: return valid
	var sold := ItemRules.sell_item(_hero_data[receipt.unit_id], receipt.item_id)
	if not sold.accepted: return sold
	_refresh_item_transaction_stats(receipt.unit_id, receipt.item_id)
	_paid_item_receipts[sale_id] = {"unit_id":receipt.unit_id,"item_id":receipt.item_id,"side":receipt.side,"sale":true}
	return _accept({"sale_id":sale_id})


func _refresh_item_transaction_stats(unit_id: String, item_id: String) -> void:
	if int(ItemRules.ITEMS[item_id].get("aura_radius", 0)) <= 0:
		_refresh_stats(_soldiers[unit_id])
		return
	# A paid aura gain/removal changes nearby recipients, not just its owner.
	# Publish it in this command without a healing pulse or rebuilding armies.
	_rebuild_hero_auras(false)
	for unit: Dictionary in _ordered_units():
		_refresh_stats(unit)


func _grant_field_relic(receipt: Dictionary, sites: Array) -> Dictionary:
	# Internal synchronous host adapter; there is no public reward command. Both
	# requested quantities and objective identity come from the closed catalog.
	if receipt.size() != 7: return _reject("INVALID_FIELD_RECEIPT")
	for key: String in ["receipt_id", "site_id", "kind", "side", "unit_id"]:
		if typeof(receipt.get(key)) != TYPE_STRING: return _reject("INVALID_FIELD_RECEIPT")
	if typeof(receipt.get("tick")) != TYPE_INT or int(receipt.tick) != _tick or _tick <= 0: return _reject("INVALID_FIELD_RECEIPT")
	if typeof(receipt.get("captured_tick")) != TYPE_INT or int(receipt.captured_tick) <= 0 or int(receipt.captured_tick) > _tick: return _reject("INVALID_FIELD_RECEIPT")
	var record := FieldObjectives.definition(_match, receipt.site_id)
	if record.is_empty() or record.kind != "RELIC" or receipt.kind != "RELIC" or receipt.receipt_id != record.receipt_id or receipt.side not in _sides: return _reject("INVALID_FIELD_RECEIPT")
	if _field_reward_receipts.has(receipt.receipt_id): return _reject("FIELD_ALREADY_CLAIMED")
	var owned := false
	for site: Dictionary in sites:
		# A reserved archive remains collectible while defended ownership is
		# being eroded, until the existing capture authority actually clears it.
		if site.get("id") == record.site_id and site.get("kind") == "VILLAGE" and site.get("position") == record.position and site.get("owner") == receipt.side and site.get("capture_side") == receipt.side and int(site.get("progress", 0)) > 0 and int(site.get("progress", 0)) <= 200 and int(site.get("threshold", 0)) == 200: owned = true
	if not owned: return _reject("FIELD_NOT_OWNED")
	if not _hero_data.has(receipt.unit_id) or not _soldiers.has(receipt.unit_id): return _reject("INVALID_FIELD_HERO")
	var body: Dictionary = _soldiers[receipt.unit_id]
	if body.side != receipt.side or int(body.hp) <= 0 or not bool(body.alive) or body.get("movement_layer") != "GROUND" or Vector2(body.position).distance_squared_to(Vector2(record.position)) > int(record.radius) * int(record.radius): return _reject("INVALID_FIELD_HERO")
	var heroes: Array = _field_hero_observations()
	if FieldObjectives.nearest_hero(heroes, receipt.side, record.position, int(record.radius)) != receipt.unit_id: return _reject("FIELD_HERO_NOT_NEAREST")
	var hero: Dictionary = _hero_data[receipt.unit_id]
	var previous_points := int(hero.skill_points)
	var actual_xp := _grant_hero_xp(receipt.unit_id, int(record.reward.XP))
	var potion_amount := 0
	for _index: int in range(int(record.reward.POTION)):
		if ItemRules.grant_loot(hero, "POTION").accepted: potion_amount += 1
	var capped: Array[String] = []
	if actual_xp < int(record.reward.XP): capped.append("XP")
	if potion_amount < int(record.reward.POTION): capped.append("POTION")
	var grant := {"FOOD":0, "MATERIAL":0, "XP":actual_xp, "POTION":potion_amount, "skill_points":int(hero.skill_points) - previous_points, "capped":capped}
	_field_reward_receipts[receipt.receipt_id] = {"side":receipt.side, "unit_id":receipt.unit_id, "tick":_tick, "actual_grant":grant.duplicate(true)}
	return _accept({"receipt_id":receipt.receipt_id, "actual_grant":grant})


func _field_hero_observations() -> Array[Dictionary]:
	# At most three heroes per side. Do not publish/copy all combat bodies,
	# skills and cooldowns just to ask who is alive inside an archive circle.
	var result: Array[Dictionary] = []
	for id: String in _sorted_keys(_hero_data):
		var body: Dictionary = _hero_body_r9(id)
		var record := {}
		for key: String in ["id", "side", "hp", "alive", "movement_layer", "position"]: record[key] = body[key]
		result.append(record)
	return result


func get_hero_statistics() -> Dictionary:
	for id: String in _sorted_keys(_hero_data): _hero_statistics.register(_hero_body_r9(id),_hero_data[id])
	return _hero_statistics.snapshot(maxi(0,_tick))


func reset_hero_statistics(track_units:bool=false) -> bool:
	# Trusted fixture initialization, not a player command. Arena replaces the
	# default strategic roster before tick one; it must not retain ghost officers.
	if _tick > 0: return false
	_hero_statistics.reset(track_units)
	for id: String in _sorted_keys(_hero_data): _hero_statistics.register(_hero_body_r9(id),_hero_data[id])
	if track_units:
		for unit:Dictionary in _soldiers.values():
			if unit.get("unit_type","")!="hero":_hero_statistics.register(unit)
	return true


func record_external_settlements(receipts: Array) -> void:
	for receipt: Dictionary in receipts:
		var id := str(receipt.get("unit_id",""))
		var source: Dictionary = _soldiers.get(id,_buildings.get(id,{"id":id,"side":receipt.get("source_side","")}))
		if _hero_statistics.external(receipt,source,_tick):
			_damage_feedback_r9(receipt.get("victim",{}),source,int(receipt.get("actual_damage",0)),str(receipt.get("attack_type",source.get("attack_type","EDGE"))),receipt.get("stats_cause",{}))


func _unit_command(command: Dictionary, side: String) -> Dictionary:
	var id: Variant = command.get("unit_id")
	if typeof(id) != TYPE_STRING or not _soldiers.has(id) or _soldiers[id]["side"] != side or int(_soldiers[id]["hp"]) <= 0: return _reject("INVALID_UNIT")
	var unit: Dictionary = _soldiers[id]
	var kind: String = command["type"]
	if kind == "UNIT_STOP":
		_clear_fold_slot_r12(unit)
		_ai_hero_withdrawals.erase(str(id))
		unit["direct_intent"] = "HOLD"
		unit["direct_destination"] = unit["position"]
		unit["target_id"] = ""
		return _accept()
	if kind == "UNIT_MOVE":
		if not _valid_point(command.get("target_position")): return _reject("INVALID_POSITION")
		_clear_fold_slot_r12(unit)
		# A successful command is an event, even if its final destination is
		# unchanged or STOP overwrites the intent before the next battle tick.
		if HeroCatalog.ReworkR7.has_hero(str(unit.get("hero_archetype", ""))):
			unit["r7_move_revision"] = int(unit.get("r7_move_revision", 0)) + 1
		unit["direct_intent"] = "MOVE"
		unit["direct_destination"] = command["target_position"]
		unit["target_id"] = ""
		return _accept()
	if kind == "UNIT_ATTACK":
		var target: Variant = command.get("target_id", "")
		if typeof(target) != TYPE_STRING: return _reject("INVALID_TARGET")
		if not str(target).is_empty() and (not _valid_enemy_unit(str(target),side) or not _can_attack(unit,_soldiers.get(target,_buildings.get(target,{})))): return _reject("INVALID_TARGET")
		_clear_fold_slot_r12(unit)
		_ai_hero_withdrawals.erase(str(id))
		unit["direct_intent"] = "ATTACK"
		unit["target_id"] = target
		return _accept()
	if unit["unit_type"] != "hero": return _reject("NOT_HERO")
	var hero: Dictionary = _hero_data[id]
	if kind == "SET_HERO_AUTOMATION":
		if typeof(command.get("auto_attack")) != TYPE_BOOL or typeof(command.get("auto_skills")) != TYPE_BOOL: return _reject("INVALID_HERO_AUTOMATION")
		hero["auto_attack"] = command["auto_attack"]
		hero["auto_skills"] = command["auto_skills"]
		# Re-enabling after STOP is stationary assistance, not silent marching
		# a separately controlled hero back into its old army formation.
		if unit["direct_intent"] == "HOLD" and (hero.auto_attack or hero.auto_skills): unit["direct_intent"] = "AUTO_HOLD"
		return _accept()
	if kind == "UPGRADE_HERO_SKILL":
		var upgrade_id: Variant = command.get("skill_id")
		if typeof(upgrade_id) != TYPE_STRING or upgrade_id not in hero["skill_levels"]: return _reject("INVALID_SKILL")
		var level := int(hero["skill_levels"][upgrade_id])
		if level >= HeroProgression.max_skill_rank(upgrade_id): return _reject("SKILL_MAX_LEVEL")
		if int(hero.level)<HeroProgression.required_level(upgrade_id,level+1): return _reject("HERO_LEVEL_REQUIRED")
		if int(hero["skill_points"]) <= 0: return _reject("NO_SKILL_POINTS")
		hero["skill_points"] = int(hero["skill_points"]) - 1
		hero["skill_levels"][upgrade_id] = level + 1
		hero["last_skill_upgrade_tick"] = _tick
		hero["last_upgraded_skill_id"] = upgrade_id
		_reindex()
		return _accept({"skill_id":upgrade_id,"skill_level":level+1})
	if kind == "EQUIP_ITEM":
		var item: Variant = command.get("item_id")
		if typeof(item) != TYPE_STRING: return _reject("INVALID_ITEM")
		var valid := ItemRules.validate_equip(hero, item)
		if not valid.accepted: return valid
		(hero["equipment"] as Array).append(item)
		_refresh_stats(unit)
		return _accept()
	if kind in ["USE_POTION", "USE_ITEM"]:
		var item: Variant = "POTION" if kind == "USE_POTION" else command.get("item_id")
		if typeof(item) != TYPE_STRING: return _reject("INVALID_CONSUMABLE")
		if _stunned(unit): return _reject("UNIT_STUNNED")
		var item_allies:Array[Dictionary]=[]
		var item_record:Dictionary=ItemRules.ITEMS.get(item,{})
		for ally:Dictionary in _ordered_units():
			if ally.id!=unit.id and ally.side==unit.side and int(ally.hp)>0 and _distance_sq(ally.position,unit.position)<=int(item_record.get("ally_radius",0))*int(item_record.get("ally_radius",0)):item_allies.append(ally)
		item_allies.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _distance_sq(a.position,unit.position)<_distance_sq(b.position,unit.position) if _distance_sq(a.position,unit.position)!=_distance_sq(b.position,unit.position) else str(a.id)<str(b.id))
		var statuses_before := _status_effects(unit)
		var item_hp_before := int(unit.hp)
		var used := ItemRules.use_item(hero, unit, item, _tick,item_allies)
		if not used.accepted: return used
		_hero_statistics.heal(unit,unit,int(unit.hp)-item_hp_before,{"id":item,"category":"ITEM"})
		_healing_feedback_r9(unit,unit,int(unit.hp)-item_hp_before,{"id":item})
		_feedback_removed_statuses(unit,statuses_before)
		var count:=0
		for ally:Dictionary in item_allies:
			if int(used.get("ally_heal",0))<=0 or count>=int(used.get("max_targets",0)):break
			if int(ally.hp)>=int(ally.max_hp):continue
			var ally_hp_before := int(ally.hp)
			ally.hp=mini(int(ally.max_hp),int(ally.hp)+int(used.ally_heal))
			_hero_statistics.heal(unit,ally,int(ally.hp)-ally_hp_before,{"id":item,"category":"ITEM"})
			_healing_feedback_r9(unit,ally,int(ally.hp)-ally_hp_before,{"id":item})
			count+=1
		_refresh_stats(unit)
		_record_action(unit, "POTION", unit["position"])
		_feedback("ITEM",unit,unit,{"item_id":item})
		return used
	var skill_id: Variant = command.get("skill_id")
	if skill_id not in hero["cooldowns"]: return _reject("INVALID_SKILL")
	if int(hero.skill_levels.get(skill_id,0))<=0: return _reject("SKILL_NOT_LEARNED")
	if _stunned(unit): return _reject("UNIT_STUNNED")
	if int(hero["cooldowns"][skill_id]) > 0: return _reject("SKILL_COOLDOWN")
	var skill := _published_skill(hero, skill_id)
	if bool(skill.passive): return _reject("PASSIVE_SKILL")
	if skill.has("r7_handler") and not _r7_skills.can_cast(unit): return _reject("SKILL_CAST_IN_PROGRESS")
	if command.has("target_position"):
		var aimed: Variant = command["target_position"]
		var cast_range := int(skill["range"])
		if not _valid_point(aimed) or _distance_sq(unit["position"], aimed) > cast_range * cast_range: return _reject("INVALID_SKILL_RANGE")
	var position: Vector2i = command.get("target_position", unit["position"])
	# Complete every existing legality check before debiting the resource or
	# applying effects, including external hits that the host will settle later.
	if skill["effect"] == "HEAL" and int(unit["hp"]) >= int(unit["max_hp"]) and not _has_useful_ally_effect(unit,skill): return _reject("FULL_HEALTH")
	if int(hero["mana"]) < int(skill["mana_cost"]): return _reject("INSUFFICIENT_MANA")
	var skill_targets: Array[Dictionary]=[]
	if skill.effect in ["DAMAGE","STUN","ROOT"]:
		skill_targets=_skill_targets(unit,skill,position)
		if skill_targets.is_empty() and str(skill.get("r7_handler","")) not in ["cinder_w","myc_w","myc_r"]: return _reject("NO_VALID_SKILL_TARGET")
	hero["mana"] = int(hero["mana"]) - int(skill["mana_cost"])
	_hero_statistics.cast(unit,str(skill_id))
	unit["feedback_skill_id"]=skill_id
	unit["feedback_skill_rank"]=int(skill.level)
	unit["feedback_skill_ultimate"]=bool(skill.ultimate)
	_feedback("CAST",unit,{}, {"skill_id":skill_id,"rank":int(skill.level),"ultimate":bool(skill.ultimate)})
	if not skill.has("r7_handler"): Innates.on_paid_cast(unit,skill,self)
	unit["last_skill_targets"] = []
	if skill.has("r7_handler"):
		_r7_skills.cast(self,unit,hero,skill,position,skill_targets)
	elif skill["effect"] == "HEAL":
		_apply_heal(unit,float(skill["heal"]),unit,true)
	elif skill["effect"] in ["DAMAGE", "STUN", "ROOT"]:
		var drained := 0.0
		var hit_index := 0
		for enemy: Dictionary in skill_targets:
			var raw := float(skill.get("raw_damage",skill.get("damage",0)))
			if hit_index>0: raw*=float(skill.get("secondary_damage_percent",100))/100.0
			raw*=1.0+float(Innates.skill_damage_percent(unit,enemy,self))/100.0
			if _soldiers.has(enemy.id) and int(enemy.get("hp",0))*100 <= int(enemy.get("max_hp",100))*35: raw = raw*(100.0+float(skill.get("execute_percent",0)))/100.0
			var amount := _resolve_damage(raw,str(skill.attack_type),enemy,unit,false)
			var actual := mini(int(enemy.hp),amount)
			if _is_worker(enemy):
				_external_hits.append({"worker_id":enemy.id,"damage":amount,"side":side,"unit_id":id,"stats_cause":{"id":skill_id,"category":"SKILL"}})
			else:
				var settled:=_deal_body_damage_r4(enemy,unit,amount,str(skill.attack_type),{"id":skill_id,"category":"SKILL"})
				actual=int(settled.primary)
				drained += float(settled.total)*float(skill.get("drain_percent",0))/100.0
				if int(enemy.hp)==0: _credit_kill(id,str(enemy.id))
				else:
					if skill.effect in ["STUN","ROOT"]:
						var field := "stun_until_tick" if skill.effect=="STUN" else "root_until_tick"
						var until:=_tick+DamageRules.control_ticks(_enhanced_duration(unit,int(skill.control_duration_ticks),"HARD"),enemy)
						if until>int(enemy[field]):
							_feedback("CONTROL",unit,enemy,{"status_kind":skill.effect,"expires_tick":until})
							enemy[field] = until
							enemy["stun_source_faction" if skill.effect=="STUN" else "root_source_faction"] = unit.faction_id
							enemy["stun_source_id" if skill.effect=="STUN" else "root_source_id"]=id
							enemy["stun_skill_id" if skill.effect=="STUN" else "root_skill_id"]=skill_id
					Innates.on_skill_hit(unit,enemy,skill,float(skill.get("base_damage",skill.get("damage",0))),actual,self)
					_apply_signature(unit,enemy,skill)
			(unit.last_skill_targets as Array).append({"id":enemy.id,"position":enemy.position,"damage":actual,"attack_type":skill.attack_type,"damage_percent":100 if hit_index==0 else int(skill.get("secondary_damage_percent",100))})
			hit_index+=1
		var drain_hp_before := int(unit.hp)
		unit.hp = mini(int(unit.max_hp),int(unit.hp)+_lifesteal_credit(unit,str(skill_id),drained))
		_hero_statistics.heal(unit,unit,int(unit.hp)-drain_hp_before,{"id":skill_id,"category":"SKILL"})
		_healing_feedback_r9(unit,unit,int(unit.hp)-drain_hp_before,{"id":skill_id})
	elif skill["effect"] == "ARMOR_BUFF":
		_grant_guard(unit,float(skill.armor_bonus),int(skill.duration_ticks),float(skill.get("speed_bonus",0)))
		_refresh_stats(unit)
	elif skill["effect"] == "DAMAGE_BUFF":
		Buffs.apply(unit,skill,_tick,id)
		_feedback("BUFF",unit,unit)
		unit["fervor_until_tick"] = _tick + int(skill["duration_ticks"])
		unit["fervor_damage_bonus"] = int(skill.get("damage_bonus",0))
		unit["fervor_speed_bonus"] = int(skill.get("speed_bonus",0))
		unit["fervor_range_bonus"] = int(skill.get("range_bonus",0))
		unit["fervor_drain_percent"] = int(skill.get("drain_percent_buff",0))
		_refresh_stats(unit)
	elif skill["effect"] == "RALLY":
		for ally: Dictionary in _skill_allies(unit,skill,position):
			var rally_buff:=skill.duplicate(true)
			rally_buff["armor_bonus"]=float(skill.get("ally_guard",0))
			rally_buff["speed_bonus"]=float(skill.get("ally_speed",0))
			Buffs.apply(ally,rally_buff,_tick,id,"RALLY")
			_feedback("BUFF",unit,ally)
			ally["rally_until_tick"] = _tick + int(skill["duration_ticks"])
			ally["rally_damage_bonus"] = int(skill.get("damage_bonus",0))
			ally["rally_speed_bonus"] = int(skill.get("ally_speed",0))
			ally["rally_armor_bonus"] = int(skill.get("ally_guard",0))
			ally["rally_source_id"] = id
			_refresh_stats(ally)
	if bool(skill.get("cleanse_dot",false)): _cleanse_dots(unit)
	if skill.effect=="HEAL" and skill.has("speed_bonus"):
		Buffs.apply(unit,skill,_tick,id,"HEAL_BUFF")
		unit.fervor_until_tick = _tick+int(skill.get("duration_ticks",60))
		unit.fervor_damage_bonus = 0
		unit.fervor_speed_bonus = int(skill.speed_bonus)
		_refresh_stats(unit)
	if skill.has("ally_heal") or skill.has("ally_guard"):
		for ally: Dictionary in _skill_allies(unit,skill,position):
			_apply_heal(ally,float(skill.get("ally_heal",0)),unit,true)
			if skill.effect!="RALLY" and float(skill.get("ally_guard",0))>0: _grant_guard(ally,float(skill.ally_guard),int(skill.get("duration_ticks",60)))
			if bool(skill.get("cleanse_dot",false)): _cleanse_dots(ally)
	hero["cooldowns"][skill_id] = int(skill["max_cooldown_ticks"])
	_record_action(unit, "SKILL_" + str(skill_id), position if skill["target_mode"] == "POINT" else unit["position"])
	unit["last_action_skill_level"] = int(skill["level"])
	unit["last_action_radius"] = int(skill["radius"])
	unit["last_action_attack_type"] = str(skill.attack_type)
	# A legal ordinary attack later in this same tick must not erase a cast's
	# independent evidence before presentation/audio can observe it.
	unit["last_skill_tick"] = _tick
	unit["last_skill_id"] = skill_id
	unit["last_skill_target_position"] = position if skill["target_mode"] == "POINT" else unit["position"]
	unit["last_skill_level"] = int(skill["level"])
	unit["last_skill_radius"] = int(skill["radius"])
	if float(skill.get("damage",0))>0 or float(skill.get("status_total_damage",0))>0 or float(skill.get("heal",0))>0 or float(skill.get("ally_heal",0))>0:_consume_buffs(unit,"PAID_SKILL")
	unit.erase("feedback_skill_id")
	unit.erase("feedback_skill_rank")
	unit.erase("feedback_skill_ultimate")
	_announce_innate_statuses()
	_reindex()
	return _accept()


func _transfer(command: Dictionary, side: String) -> Dictionary:
	var destination: Variant = command.get("target_warband_id")
	var ids: Variant = command.get("unit_ids")
	if typeof(destination) != TYPE_STRING or not _warbands.has(destination) or _warbands[destination]["side"] != side or not ids is Array or ids.is_empty(): return _reject("INVALID_TRANSFER")
	var seen := {}
	for id: Variant in ids:
		if typeof(id) != TYPE_STRING or seen.has(id) or not _soldiers.has(id) or _soldiers[id]["side"] != side or int(_soldiers[id]["hp"]) <= 0: return _reject("INVALID_TRANSFER")
		seen[id] = true
	for id: String in seen:
		_clear_fold_slot_r12(_soldiers[id])
		_soldiers[id]["warband_id"] = destination
		if _preserving_ai_hero_withdrawal(_soldiers[id]): continue
		_soldiers[id]["direct_intent"] = ""
		_soldiers[id]["target_id"] = ""
	_reindex()
	return _accept()


func _advance_anchors(phase: String) -> void:
	var groups := _warbands.duplicate(false)
	groups.merge(_type_cohorts_r12)
	for id: String in _sorted_keys(groups):
		var army: Dictionary = groups[id]
		if army["reserve"]: continue
		var routing_radius:=0
		var members := _controlled_members_r12(army)
		var profile: Dictionary = _march_profiles_r12.get(id,{})
		if members.is_empty() or int(profile.get("count",0))==0: continue
		if bool(profile.get("contact",false)): continue
		var pace_credit := float(army.get("march_fraction_r12",0.0))+float(profile.speed_exact)
		var stride := floori(pace_credit)
		if stride<=0:
			army["march_fraction_r12"]=pace_credit
			continue
		for member: Dictionary in members:
			if member.movement_layer=="GROUND":routing_radius=maxi(routing_radius,int(member.radius))
		# The formation's nonphysical anchor must not leave its actual fighting
		# members behind. Local retaliation is transient; keep the original
		# A-move destination, resume as soon as the live attacker is gone/clear.
		if phase=="BATTLE" and army.intent=="ATTACK_MOVE" and _amove_contact_r9(army,members):continue
		# Plan real ground armies with this faction's largest catalog footprint
		# from the outset. Paid reinforcements cannot expand a cached route's
		# halo around an already stranded virtual anchor. AIR-only armies stay
		# airborne, and actual unit collision radii are never inflated here.
		if routing_radius>0:routing_radius=maxi(routing_radius,int(_side_config[army.side].ground_route_radius))
		var target: Vector2i = army["destination"]
		if phase == "BATTLE" and army["intent"] == "FOCUS":
			var enemies := _living_members(str(army["target_warband_id"]))
			if not enemies.is_empty(): target = enemies[0]["position"]
		elif phase == "BATTLE" and army["intent"] == "ATTACK_BASE" and _buildings.has(army["target_base_id"]):
			target = _buildings[army["target_base_id"]]["position"]
			var structure: Dictionary=_buildings[army.target_base_id]
			target=_approach_point(army.anchor,target,int(structure.get("radius",32))+routing_radius+4)
		if routing_radius>0 and not Navigation.point_clear(army.anchor,routing_radius,_bounds,_route_obstacles):
			var escaped:Vector2i=Navigation.escape_step(army.anchor,target,routing_radius,_bounds,_route_obstacles,stride)
			if escaped!=army.anchor:
				army["march_fraction_r12"] = pace_credit-float(stride)
				# Only the nonphysical formation anchor leaves its invalid halo;
				# actual bodies still use strict navigation and swept collision.
				army.anchor=escaped
				army.route=[]
				army.route_geometry=""
				army["route_unreachable"]=false
				if _distance_sq(escaped,army.home_anchor)<=64*64 and not Navigation.point_clear(army.home_anchor,routing_radius,_bounds,_route_obstacles) and Navigation.point_clear(escaped,routing_radius,_bounds,_route_obstacles):army.home_anchor=escaped
			continue
		# A valid center route does not imply every lateral slot is outside a
		# building. Waiting for an impossible slot deadlocks all other members.
		# Repair the virtual halo first; then a bounded static-endpoint exception
		# may follow that legal center through normal body navigation/collision.
		_prepare_fold_slots_r12(army,members)
		var regroup := false
		var allowance := FormationMarchR12.pitch_for(members)*2
		for member: Dictionary in members:
			if _movement_controlled(member): continue
			if _distance_sq(member.position,_desired_position(member,{}))>allowance*allowance: regroup=true;break
		# Folded followers still count: a slow body must be able to catch up to
		# the effective goal rather than being abandoned by an advancing anchor.
		if regroup: continue
		army["march_fraction_r12"] = pace_credit-float(stride)
		if routing_radius>0:target=_routed_point(army,army.anchor,target,routing_radius)
		var delta := target - (army["anchor"] as Vector2i)
		if delta != Vector2i.ZERO:
			army["facing"] = "EAST" if delta.x > 0 else "WEST" if delta.x < 0 else "SOUTH" if delta.y > 0 else "NORTH"
			var next:=_step_towards(army["anchor"], target, stride)
			if routing_radius>0 and not _route_obstacles.is_empty():
				# Route edges are straight segments. Axis clamping cuts their
				# corners, putting even a virtual anchor inside solid terrain;
				# its followers would then receive an unreachable formation goal.
				next=_safe_anchor_stride(army.anchor,target,stride,routing_radius)
			army["anchor"] = next


func _controlled_members_r12(army: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for body: Dictionary in _living_members(str(army.id)):
		if str(_control_army_r12(body).get("id",""))==str(army.id) and str(body.get("direct_intent","" )).is_empty(): result.append(body)
	return result


func _clear_fold_slot_r12(body: Dictionary) -> void:
	if body.has("fold_slot_r12"):
		body.erase("fold_slot_r12")
		# A changed endpoint within32px must not inherit an unreachable route or
		# a dynamic detour that was planned for the temporarily folded endpoint.
		body["route"]=[];body["route_geometry"]="";body["route_unreachable"]=false
		body.erase("recovery_r11")
	body.erase("fold_probe_tick_r12")


func _fold_slot_active_r12(body: Dictionary, army: Dictionary) -> bool:
	var state: Dictionary=body.get("fold_slot_r12",{})
	return not state.is_empty() and int(body.hp)>0 and body.movement_layer=="GROUND" and str(body.direct_intent).is_empty() and not _movement_controlled(body) and army.intent in ["MOVE","RETREAT","ATTACK_MOVE","FOCUS","ATTACK_BASE"] and not bool(_march_profiles_r12.get(str(army.id),{}).get("contact",false)) and int(state.get("expires_tick",-1))>_tick and state.get("army")==army.id and state.get("intent")==army.intent and state.get("destination")==army.destination and state.get("formation")==army.formation and state.get("facing")==army.facing and state.get("geometry")==_route_geometry and int(state.get("radius",-1))==int(body.radius) and state.get("offset")==_formation_slot_r12(body,army)-Vector2i(army.anchor)


func _prepare_fold_slots_r12(army: Dictionary,members: Array[Dictionary]) -> void:
	var probed := false
	var allowance := FormationMarchR12.pitch_for(members)*2
	var cursor := posmod(int(army.get("fold_cursor_r12",0)),maxi(1,members.size()))
	for index: int in range(members.size()):
		var member_index := (cursor+index)%members.size()
		var body: Dictionary=members[member_index]
		var active := _fold_slot_active_r12(body,army)
		if body.has("fold_slot_r12") and not active: _clear_fold_slot_r12(body)
		if army.intent not in ["MOVE","RETREAT","ATTACK_MOVE","FOCUS","ATTACK_BASE"] or body.movement_layer!="GROUND" or _movement_controlled(body): continue
		var raw := _formation_slot_r12(body,army)
		if not active and _distance_sq(body.position,raw)<=allowance*allowance: continue
		if probed or _tick<int(body.get("fold_probe_tick_r12",-1)): continue
		# At most one static endpoint probe per army/tick, only for a laggard or
		# a live exception. Round-robin admission also covers armies larger than
		# the20tick backoff; their first20 IDs must not monopolize every probe.
		probed=true
		army["fold_cursor_r12"]=(member_index+1)%members.size()
		body["fold_probe_tick_r12"]=_tick+20
		if Navigation.point_clear(raw,int(body.radius),_bounds,_route_obstacles):
			if active: _clear_fold_slot_r12(body)
			continue
		if not active:
			body["route"]=[];body["route_geometry"]="";body["route_unreachable"]=false
			body.erase("recovery_r11")
		body["fold_slot_r12"]={"army":army.id,"intent":army.intent,"destination":army.destination,"formation":army.formation,"facing":army.facing,"geometry":_route_geometry,"radius":int(body.radius),"offset":raw-Vector2i(army.anchor),"raw_slot":raw,"verified_tick":_tick,"expires_tick":_tick+200}


func _prepare_march_r12(targets: Dictionary) -> void:
	_march_profiles_r12.clear()
	var groups := _warbands.duplicate(false)
	groups.merge(_type_cohorts_r12)
	for id: String in _sorted_keys(groups):
		var army: Dictionary = groups[id]
		if bool(army.reserve): continue
		var members := _controlled_members_r12(army)
		var excluded: Dictionary = {}
		for body: Dictionary in members:
			if _movement_controlled(body): excluded[str(body.id)]=true
		var profile := FormationMarchR12.march_profile(members,excluded)
		var contact: bool = army.intent in ["ATTACK_MOVE","FOCUS","ATTACK_BASE"] and FormationMarchR12.has_contact(members,targets,_hero_data,excluded)
		if contact: army["combat_until_r12"]=_tick+8
		profile["contact"] = contact or (army.intent in ["ATTACK_MOVE","FOCUS","ATTACK_BASE"] and int(army.get("combat_until_r12",-1))>_tick)
		for body: Dictionary in members:
			if bool(profile.contact) or _movement_controlled(body) or body.movement_layer!="GROUND": _clear_fold_slot_r12(body)
		_march_profiles_r12[id]=profile


func _march_speed_r12(body: Dictionary, goal: Vector2i) -> float:
	var natural := float(body.get("speed_exact",body.speed))
	if bool(body.get("neutral",false)) or not str(body.get("direct_intent","")).is_empty(): return natural
	var army := _control_army_r12(body)
	var profile: Dictionary = _march_profiles_r12.get(str(army.get("id","")),{})
	if profile.is_empty() or bool(profile.get("contact",false)) or army.intent not in ["MOVE","RETREAT","ATTACK_MOVE","FOCUS","ATTACK_BASE"]: return natural
	# A displaced body may catch up, never above its own legal natural speed.
	# The controller waits for its slowest laggard below rather than abandoning
	# it; ordinary already-arranged travel uses exactly the common pace.
	if _distance_sq(body.position,goal)>maxi(16,int(body.radius)*2+4)*maxi(16,int(body.radius)*2+4): return natural
	return minf(natural,float(profile.speed_exact))


func _amove_contact_r9(army:Dictionary,members:Array[Dictionary])->bool:
	var sources:Dictionary={};var layers:Dictionary={}
	for member:Dictionary in members:
		if str(member.get("direct_intent",""))!="":continue
		if not _hero_data.has(str(member.id)) or bool(_hero_data[member.id].auto_attack):
			for layer:String in member.get("attack_layers",["GROUND"]):layers[layer]=true
		var at:=int(member.get("last_damage_tick",-1000000))
		if at>=0 and at<=_tick and _tick-at<=60 and int(member.get("last_damage_amount",0))>0 and sources.size()<8:
			sources[str(member.get("last_damage_source_id",""))]=true
	if layers.is_empty():return false
	for id:String in sources:
		var enemy:Dictionary=_soldiers.get(id,_buildings.get(id,{}))
		if enemy.is_empty() or int(enemy.get("hp",0))<=0 or enemy.get("side")==army.side or not VisibilityR9.can_observe(enemy,str(army.side)):continue
		if bool(enemy.get("leashing",false)) or not layers.has(str(enemy.get("movement_layer","GROUND"))):continue
		if enemy.has("building_type") and not bool(enemy.get("defense_active",false)):continue
		if _distance_sq(enemy.position,army.anchor)<=420*420:return true
	return false

func _group_combat_member_r13(unit: Dictionary) -> bool:
	if bool(unit.get("neutral",false)) or int(unit.get("hp",0))<=0 or not str(unit.get("direct_intent","")).is_empty() or _movement_controlled(unit):return false
	if _hero_data.has(str(unit.id)) and not bool(_hero_data[unit.id].auto_attack):return false
	var army:=_control_army_r12(unit)
	return not army.is_empty() and not bool(army.get("reserve",false)) and army.get("intent") in ["ATTACK_MOVE","FOCUS","ATTACK_BASE"]

func _choose_target(unit: Dictionary, phase: String) -> Dictionary:
	if bool(unit.get("neutral", false)): return NeutralEncounters.choose_target(unit, phase, self)
	var recovering_targets:Dictionary=unit.get("recovery_avoid_r11",{})
	if not recovering_targets.is_empty():
		for id:Variant in recovering_targets.keys():
			var prior:Dictionary=_soldiers.get(str(id),_buildings.get(str(id),{}))
			if int(recovering_targets[id])<=_tick or prior.is_empty() or int(prior.get("hp",0))<=0:recovering_targets.erase(id)
		if recovering_targets.is_empty():unit.erase("recovery_avoid_r11")
	if phase != "BATTLE" or int(unit["hp"]) <= 0 or _stunned(unit): return {}
	var army: Dictionary = _control_army_r12(unit)
	var direct: String = unit["direct_intent"]
	# Plain macro MOVE is travel-only too: passive in-range acquisition must
	# not pin a disengaging / rendezvous body in place. Explicit per-body
	# attacks and ATTACK_MOVE retain their existing acquisition contract.
	if direct.is_empty() and army["intent"] in ["MOVE", "RETREAT"]: return {}
	if direct == "ATTACK" and _soldiers.has(unit["target_id"]):
		var explicit: Dictionary = _soldiers[unit["target_id"]]
		if int(explicit["hp"]) > 0 and explicit["side"] != unit["side"] and _can_attack(unit,explicit): return explicit
	if direct == "ATTACK" and _buildings.has(unit["target_id"]):
		var explicit: Dictionary = _buildings[unit["target_id"]]
		if _valid_enemy_unit(str(explicit.id),str(unit.side)) and _can_attack(unit,explicit): return explicit
	# Manual attacks can keep their valid named target with automation off,
	# but a completed/invalid target must not authorize passive new discovery.
	if _hero_data.has(unit["id"]) and not bool(_hero_data[unit["id"]]["auto_attack"]): return {}
	if direct.is_empty() and army["intent"] == "ATTACK_BASE" and _buildings.has(army["target_base_id"]):
		# React locally to actual incoming fire / weapon coverage, but keep the
		# macro siege destination intact and resume it when the threat leaves.
		var response:Dictionary=_targeting.choose(unit,army,true)
		if not response.is_empty():return response
		var building: Dictionary = _buildings[army["target_base_id"]]
		if int(building.get("hp", 0)) > 0 and building["side"] != unit["side"] and _can_attack(unit,building): return building
	return _targeting.choose(unit,army)

func neutral_target_candidates_m76() -> Array[Dictionary]:
	if _choosing_targets_m76 and not _neutral_candidates_m76.is_empty(): return _neutral_candidates_m76
	var result: Array[Dictionary] = []
	# The old neutral chooser discarded every other neutral after rebuilding
	# and sorting the entire army for EACH creature. Keep that exact order,
	# but omit only universally ineligible side/dead entries once per batch.
	for body: Dictionary in _ordered_units()+_ordered_buildings():
		if body.get("side") in _sides and int(body.get("hp",0))>0: result.append(body)
	if _choosing_targets_m76: _neutral_candidates_m76 = result
	return result


func _desired_position(unit: Dictionary, target: Dictionary) -> Vector2i:
	if bool(unit.get("neutral", false)): return NeutralEncounters.desired_position(unit, target, self)
	var position: Vector2i = unit["position"]
	if int(unit["hp"]) <= 0: return position
	if _movement_controlled(unit): return position
	if unit["direct_intent"] in ["HOLD", "AUTO_HOLD"]: return position
	# A direct movement order must not turn into attack-move merely because
	# passive acquisition found a target already in range. Movement control
	# and explicit holds still take precedence; ordinary attacks are unchanged.
	if unit["direct_intent"] == "MOVE": return unit["direct_destination"]
	if not target.is_empty():
		if _in_attack_range(unit, target):
			# Weapons include the victim's body radius; ordinary spells use
			# center distance. Close only that gap under an offensive order.
			return target.position if TroopRuntimeV4.needs_skill_approach(unit,target,self) else position
		var army: Dictionary = _control_army_r12(unit)
		if unit["direct_intent"] == "ATTACK" or (unit["direct_intent"] == "" and army["intent"] in ["ATTACK_MOVE", "FOCUS", "ATTACK_BASE"]):
			return _approach_point(position,target.position,int(unit.radius)+int(target.get("radius",32))+2) if _buildings.has(target.id) and not _is_worker(target) else target["position"]
	var army: Dictionary = _control_army_r12(unit)
	if army["reserve"] or unit["direct_intent"] == "ATTACK": return position
	if _fold_slot_active_r12(unit,army): return army.anchor
	return _formation_slot_r12(unit,army)


func _formation_slot_r12(unit: Dictionary,army: Dictionary) -> Vector2i:
	# A normal army's living count and maximum body pitch do not change during
	# target selection. Compute lazily only when an actual formation goal is used.
	var layout: Dictionary = m84_layout_contexts.get(str(army.id),{}) if m84_layout_active else {}
	if layout.is_empty():
		var members := _controlled_members_r12(army)
		var pitch := FormationMarchR12.pitch_for(members)
		var signature := FormationMarchR12.layout_key(members,str(army.formation),pitch)
		layout=_role_layouts_r2.get(str(army.id),{})
		if layout.is_empty() or layout.get("signature_r12","")!=signature:
			layout={"signature_r12":signature,"count":members.size(),"pitch":pitch,"formation":army.formation,"builds":int(layout.get("builds",0))+1,"offsets":FormationMarchR12.layout(members,str(army.formation),pitch)}
			_role_layouts_r2[str(army.id)]=layout
		if m84_layout_active:m84_layout_contexts[str(army.id)]=layout
	if layout.get("offsets",{}).has(str(unit.id)):
		return Vector2i(army.anchor)+FormationMarchR12.orient(Vector2i(layout.offsets[str(unit.id)]),str(army.facing))
	return Vector2i(army.anchor)+_formation_offset(str(army.formation),int(unit.member_index),int(layout.count),str(army.facing),int(layout.pitch))


func _formation_offset(formation: String, index: int, count: int, facing: String,pitch: int=32) -> Vector2i:
	var offset: Vector2i
	match formation:
		"LOOSE": offset = Vector2i((index % 3 - 1) * maxi(48,pitch), (index / 3 - (count - 1) / 6) * maxi(48,pitch))
		"COLUMN": offset = Vector2i((index / 2 - (count - 1) / 4) * pitch, (index % 2) * pitch - pitch/2)
		"SPEAR": offset = Vector2i(-(index / 3) * pitch, (index % 3 - 1) * pitch)
		_: offset = Vector2i((index % 3 - 1) * pitch, (index / 3 - (count - 1) / 6) * pitch)
	if facing == "WEST": return Vector2i(-offset.x, -offset.y)
	if facing == "NORTH": return Vector2i(offset.y, -offset.x)
	if facing == "SOUTH": return Vector2i(-offset.y, offset.x)
	return offset


func _add_warband(id: String, side: String, number: int, anchor: Vector2i, reserve: bool = false) -> void:
	_warbands[id] = {"id": id, "number": number, "side": side,"faction_id":_faction(side), "reserve": reserve, "anchor": anchor, "destination": anchor, "home_anchor": anchor, "facing": "EAST" if int(_side_config[side].spawn_direction.x)>0 else "WEST", "formation": "STEADY", "unit_type": Factions.units_for(_faction(side),"FRONTLINE")[0], "intent": "HOLD", "target_warband_id": "", "target_base_id": "", "member_ids": [], "living_count": 0,"route":[],"route_target":anchor,"route_geometry":""}


func _add_unit(id: String, side: String, unit_type: String, army_id: String, position: Vector2i, archetype: String = HeroCatalog.DEFAULT_ARCHETYPE, hero_slot: int = 0) -> void:
	_m90_invalidate_order()
	_r4_elite_dirty=true
	var unit := _new_body(id, side, unit_type, army_id, position, archetype)
	_soldiers[id] = unit
	if unit_type == "hero":
		var assigned_slot := hero_slot if hero_slot > 0 else _empty_hero_slot(side)
		var profile := HeroCatalog.profile(archetype)
		var cooldowns := {}
		var skill_levels := {}
		for skill: String in profile["skill_ids"]:
			cooldowns[skill] = 0
			skill_levels[skill] = 0
		_hero_data[id] = {"id":id, "unit_id":id, "member_id":id, "archetype":archetype, "role":profile["role"], "description":profile["description"], "name":profile.get("ai_name", profile["name"]) if side == "AI" else profile["name"], "title":profile.get("ai_title", profile["title"]) if side == "AI" else profile["title"], "level":1, "xp":0, "credited_victim_ids":[], "cooldowns":cooldowns, "inventory":HeroCatalog.initial_inventory(), "equipment":[], "auto_attack":true, "auto_skills":false, "skill_levels":skill_levels, "skill_points":1, "last_level_up_tick":-1000000, "last_skill_upgrade_tick":-1000000, "last_upgraded_skill_id":"", "last_auto_skill_tick":-1000000}
		_hero_data[id].merge({"mana":int(profile.stats.max_mana),"max_mana":int(profile.stats.max_mana),"mana_regen_ticks":HeroCatalog.MANA_REGEN_TICKS,"mana_regen_progress_ticks":0})
		_hero_data[id]["hero_slot"] = assigned_slot
	_hero_statistics.register(unit,_hero_data.get(id,{}))
	_refresh_stats(unit)


func _new_body(id: String, side: String, unit_type: String, army_id: String, position: Vector2i, archetype: String = HeroCatalog.DEFAULT_ARCHETYPE) -> Dictionary:
	var stats := stats_for_type(unit_type, archetype)
	var unit := stats.duplicate(true)
	unit["life_generation"]=1
	unit.merge({"id": id, "side": side,"faction_id":_faction(side), "warband_id": army_id, "member_index": 0, "position": position, "hp": stats["max_hp"], "alive": true, "cooldown_ticks": 0, "heal_cooldown_ticks": 0, "heal_max_cooldown_ticks": int(stats.get("heal_cooldown_ticks",0)), "target_id": "", "direct_intent": "", "direct_destination": position, "rally_until_tick": -1, "rally_source_id": "","route":[],"route_target":position,"route_geometry":""}, true)
	# Read-only presentation evidence records resolved movement and accepted
	# actions, never an intention or a renderer-driven timer. Kept in full state
	# so deterministic replays include exactly what was physically observed.
	unit.merge({"last_move_tick": -1000000, "last_move_direction": Vector2i.ZERO, "last_action_tick": -1000000, "last_action_kind": "", "last_action_target_position": position, "last_action_target_layer":"", "last_action_skill_level":0, "last_action_radius":0,"last_action_attack_type":str(stats.get("attack_type","EDGE"))})
	unit["rally_damage_bonus"] = 3
	unit["rally_armor_bonus"] = 0
	unit.merge({"last_skill_tick":-1000000,"last_skill_id":"","last_skill_target_position":position,"last_skill_level":0,"last_skill_radius":0,"last_skill_targets":[]})
	unit.merge({"stun_until_tick":-1, "root_until_tick":-1, "guard_until_tick":-1, "guard_armor_bonus":0, "fervor_until_tick":-1, "fervor_damage_bonus":0})
	unit.merge({"combat_statuses":{},"stun_source_faction":"","root_source_faction":"","last_damage_tick":-1000000,"last_damage_source_id":"","last_damage_source_faction":"","last_damage_amount":0,"last_damage_attack_type":"","last_proc_tick":-1000000,"last_proc_id":"","last_proc_target_position":position,"guard_speed_bonus":0,"fervor_speed_bonus":0,"fervor_range_bonus":0,"fervor_drain_percent":0,"rally_speed_bonus":0})
	unit.merge({"mana":int(stats.get("max_mana",0)),"max_mana":int(stats.get("max_mana",0)),"mana_regen_milli":0,"source_buffs":{},"innate_state":{},"innate_aura":{},"shield":0,"shield_until_tick":-1})
	if unit_type == "hero": unit["hero_archetype"] = archetype
	return unit


func _record_action(unit: Dictionary, kind: String, target: Vector2i) -> void:
	unit["last_action_tick"] = _tick
	unit["last_action_kind"] = kind
	unit["last_action_target_position"] = target
	unit["last_action_target_layer"] = ""
	unit["last_action_skill_level"] = 0
	unit["last_action_radius"] = 0
	unit["last_action_attack_type"] = str(unit.get("attack_type","EDGE"))


func _advance_hero_base_recovery(unit: Dictionary) -> void:
	# One accepted 20Hz battle tick, never elapsed wall time or a tick-index gap.
	# Physical-body carry is independent of item/innate carries and fresh on revive.
	if int(unit.hp)<=0 or int(unit.hp)>=int(unit.max_hp):
		unit["base_hp_regen_milli"] = 0
		return
	var progress := int(unit.get("base_hp_regen_milli",0))+roundi(float(unit.get("hp_regen_per_second",0.0))*50.0)
	unit["base_hp_regen_milli"] = progress%1000
	var hp_before := int(unit.hp)
	unit.hp = mini(int(unit.max_hp),int(unit.hp)+progress/1000)
	_hero_statistics.heal(unit,unit,int(unit.hp)-hp_before,{"id":"BASE_RECOVERY","category":"OTHER"})
	_healing_feedback_r9(unit,unit,int(unit.hp)-hp_before,{"id":"BASE_RECOVERY"})
	if int(unit.hp)>=int(unit.max_hp): unit.base_hp_regen_milli=0


## M80: keep the already deep-detached recipe as baseline; separate the
## scalar-modified working table before technology or hero baseline writes.
func _m87_working_stats(unit: Dictionary) -> Dictionary:
	var kind := str(unit.unit_type)
	var record: Dictionary = _m87_recipes.get(kind, {})
	if record.is_empty():
		var recipe := stats_for_type(kind)
		var working: Dictionary = {}
		for field: String in ["hp_regen_per_second", "mana_regen_per_second", "magic_resist_percent", "damage", "armor", "speed", "max_mana", "attack_range", "attack_cooldown_ticks", "heal", "heal_range", "heal_cooldown_ticks", "max_hp", "tags", "unit_type"]:
			if recipe.has(field): working[field] = recipe[field]
		record = {"recipe":recipe, "working":working, "keys":recipe.keys()}
		_m87_recipes[kind] = record
		_m87_recipe_builds += 1
	var id := str(unit.id)
	var present: Variant = unit.get("attribute_base")
	# Check identity, contents and insertion order: mutation/aliasing of one
	# owned body must not poison a recipe or another body, even within a tick.
	if not (present is Dictionary) or not is_same(present, _m87_baselines.get(id)) or present != record.recipe or present.keys() != record.keys:
		present = record.recipe.duplicate(true)
		unit["attribute_base"] = present
		_m87_baselines[id] = present
		_m87_baseline_builds += 1
	# SPECIALTY changes only top-level scalars. Shared internal tags are read
	# only and never escape through a body or public result.
	return record.working.duplicate()


func _refresh_stats(unit: Dictionary) -> void:
	var hero: Dictionary=_hero_data.get(str(unit.id),{})
	var levels: Dictionary=_technology.get(str(unit.side),{})
	var aura: Dictionary=_hero_aura_bonuses.get(str(unit.id),{})
	var faction:=_faction(str(unit.side)) if not bool(unit.get("neutral",false)) else ""
	if _m95_stat_dependencies.reusable(unit,hero,levels,aura,faction,_tick,_soldiers,_m95_stat_scope):
		# Current resource values are not stat dependencies. Preserve the old
		# per-call clamps/mirror without re-running catalogs and modifier sums.
		unit.hp=mini(int(unit.hp),int(unit.max_hp))
		if not hero.is_empty():
			hero.mana=mini(int(hero.mana),int(hero.max_mana))
			unit.max_mana=int(hero.max_mana)
			unit.mana=int(hero.mana)
		return
	_refresh_stats_uncached_m95(unit)
	_m95_stat_dependencies.remember(unit,hero,levels,aura,faction,_tick,_soldiers,_m95_stat_scope)


func _m95_stats_begin_trusted_scope() -> void:
	assert(_m95_stat_scope==0)
	_m95_stat_scope_serial+=1
	_m95_stat_scope=_m95_stat_scope_serial


func _m95_stats_end_trusted_scope() -> void:
	_m95_stat_scope=0


func _m95_stats_diagnostics() -> Dictionary:
	return _m95_stat_dependencies.diagnostics()


func _technology_modifiers_v4(side:String)->Dictionary:
	var levels:Dictionary=_technology.get(side,{})
	var faction:=_faction(side) if side in _sides else ""
	var cached:Dictionary=_technology_compiled_v4.get(side,{})
	if cached.is_empty() or cached.levels!=levels or cached.faction!=faction:
		cached={"levels":levels.duplicate(),"faction":faction,"modifiers":TechnologiesV4.resolve(faction,levels)}
		_technology_compiled_v4[side]=cached
	return cached.modifiers


func _refresh_stats_uncached_m95(unit: Dictionary) -> void:
	if bool(unit.get("neutral", false)):
		NeutralEncounters.refresh_stats(unit, _tick)
		return
	var stats: Dictionary
	if unit.unit_type != "hero" and Units.UNITS.has(str(unit.unit_type)):
		stats = _m87_working_stats(unit)
	else:
		stats = stats_for_type(str(unit["unit_type"]), unit.get("hero_archetype", HeroCatalog.DEFAULT_ARCHETYPE))
		# Hero baselines are mutated by level growth below; keep full ownership.
		unit["attribute_base"] = stats
		stats = stats.duplicate()
	if unit.unit_type=="hero":
		unit.attribute_base["mana_regen_per_second"] = 20.0/float(HeroCatalog.MANA_REGEN_TICKS)
	unit["hp_regen_per_second"] = float(stats.get("hp_regen_per_second",0.0))
	var levels: Dictionary = _technology[unit["side"]]
	var technology:=TechnologiesV4.unit_modifiers(_faction(str(unit.side)),levels,stats,unit.unit_type=="hero")
	unit["technology_modifiers_v4"]=technology
	unit["hp_regen_per_second"]+=float(technology.hp_regen_per_second)
	unit["mana_regen_per_second"]=float(stats.get("mana_regen_per_second",0.0))+float(technology.mana_regen_per_second)
	if unit.unit_type!="hero":
		unit.max_mana=int(stats.get("max_mana",0))+int(technology.max_mana_bonus)
		unit.mana=mini(int(unit.get("mana",0)),int(unit.max_mana))
	var buffs:=Buffs.values(unit,_tick,_soldiers)
	var bonus:=float(buffs.damage_bonus)
	var armor_bonus := float(technology.armor_bonus)
	var speed_bonus := 0.0
	var range_bonus := int(technology.range_bonus)
	var life_bonus := 0
	if int(unit.get("guard_until_tick", -1)) > _tick and int(unit["hp"]) > 0: armor_bonus += float(unit["guard_armor_bonus"])
	if int(unit.get("guard_until_tick",-1)) > _tick: speed_bonus += float(unit.get("guard_speed_bonus",0))
	speed_bonus+=float(buffs.speed_bonus)
	range_bonus+=int(buffs.range_bonus)
	armor_bonus+=float(buffs.armor_bonus)
	var attack_speed_percent:=float(buffs.attack_speed_percent)+float(unit.get("innate_aura",{}).get("attack_speed_percent",0))+float(technology.attack_speed_percent)
	var move_speed_percent:=float(buffs.move_speed_percent)+float(technology.move_speed_percent)
	var magic_resist_percent:=float(stats.get("magic_resist_percent",0))+float(buffs.magic_resist_percent)
	var control_resist_percent:=Innates.control_resist_percent(unit)
	var healing_percent:=int(technology.healing_percent)
	var growth_damage:=0
	var growth_max_hp:=0
	var equipment_damage:=0
	var slow := 0.0
	for status: Dictionary in unit.get("combat_statuses",{}).values():
		if int(status.expires_tick)<=_tick: continue
		if status.kind=="ARMOR_BREAK": armor_bonus -= float(status.power)
		elif status.kind=="SLOW": slow = maxf(slow,float(status.power))
	if _hero_data.has(unit["id"]):
		var hero: Dictionary = _hero_data[unit["id"]]
		hero["technology_context_v4"]={"faction":_faction(str(unit.side)),"levels":levels.duplicate()}
		var growth := HeroProgression.bonuses(str(hero.archetype),int(hero.level))
		growth_damage=int(growth.damage)
		growth_max_hp=int(growth.max_hp)
		unit.attribute_base["damage"] = float(unit.attribute_base.damage)+float(growth.damage)
		unit.attribute_base["armor"] = float(unit.attribute_base.armor)+float(growth.armor)
		armor_bonus += int(growth.armor)
		life_bonus += int(growth.max_hp)
		for skill_id: String in hero.skill_levels:
			if int(hero.skill_levels[skill_id])<=0: continue
			var passive := HeroCatalog.skill_at_level(skill_id,int(hero.skill_levels[skill_id]))
			if passive.effect=="PASSIVE_GUARD" and int(unit.hp)>0: armor_bonus += float(passive.passive_armor)
		var active := ItemRules.active_bonus(hero,_tick)
		var gear:=ItemRules.equipment_stats(hero)
		bonus += int(active.get("damage_bonus",0))
		armor_bonus += int(active.get("armor_bonus",0))
		speed_bonus += int(active.get("speed_bonus",0))
		range_bonus += int(active.get("range_bonus",0))
		life_bonus += int(active.get("max_hp_bonus",0))
		equipment_damage=int(gear.damage_bonus)
		armor_bonus+=int(gear.armor_bonus)
		speed_bonus+=int(gear.speed_bonus)
		range_bonus+=int(gear.range_bonus)
		life_bonus+=int(gear.max_hp_bonus)
		attack_speed_percent+=int(gear.attack_speed_percent)+int(active.attack_speed_percent)
		move_speed_percent+=int(gear.move_speed_percent)+int(active.move_speed_percent)
		magic_resist_percent+=int(gear.magic_resist_percent)+int(active.magic_resist_percent)
		control_resist_percent+=int(gear.control_resist_percent)+int(active.control_resist_percent)
		healing_percent+=int(gear.healing_percent)+int(active.healing_percent)
		hero.max_mana=int(stats.max_mana)+int(growth.max_mana)+int(gear.max_mana_bonus)+int(active.max_mana_bonus)+int(technology.max_mana_bonus)
		hero.mana=mini(int(hero.mana),int(hero.max_mana))
		unit.max_mana=int(hero.max_mana)
		unit.mana=int(hero.mana)
	var aura: Dictionary = _hero_aura_bonuses.get(str(unit.id),{})
	bonus += float(aura.get("damage",0))
	armor_bonus += float(aura.get("armor",0))
	speed_bonus += float(aura.get("speed",0))
	move_speed_percent+=float(aura.get("move_speed_percent",0))
	unit["base_damage"]=int(stats.damage)+growth_damage+equipment_damage
	unit["damage"] = float(unit.base_damage)*(1.0+float(buffs.damage_percent)/100.0) + int(levels.get("ATTACK",0))*2 + bonus
	unit["armor"] = int(stats["armor"]) + int(levels.get("ARMOR",0)) + armor_bonus
	unit["speed_exact"] = maxf(0.1,(float(stats.speed)+speed_bonus)*(1.0+move_speed_percent/100.0)*(100-clampf(slow,0,60))/100.0)
	unit["speed"] = maxi(1,roundi(float(unit.speed_exact)))
	unit["move_speed_percent"]=move_speed_percent
	unit["attack_speed_percent"]=attack_speed_percent
	unit["magic_resist_percent"]=clampi(magic_resist_percent,0,60)
	unit["control_resist_percent"]=clampf(control_resist_percent,0,50)
	unit["healing_percent"]=healing_percent
	unit["buff_drain_percent"]=float(buffs.drain_percent)
	unit["attack_range"] = int(stats["attack_range"]) + range_bonus
	unit["attack_cooldown_ticks"]=maxi(4,roundi(float(stats.attack_cooldown_ticks)*100.0/(100.0+clampf(attack_speed_percent,0,100))))
	if stats.has("heal"):
		unit["heal"]=roundi(float(stats.heal)*(1.0+float(technology.healing_percent)/100.0))+int(technology.heal_bonus)
		unit["heal_range"]=int(stats.heal_range)
		unit["heal_max_cooldown_ticks"]=int(stats.heal_cooldown_ticks)
	# Body growth is part of the researchable body, but gear/active flat life
	# stays outside it. No free heal when the researched maximum increases.
	unit["max_hp"] = roundi(float(int(stats["max_hp"])+growth_max_hp)*(1.0+float(technology.max_hp_percent)/100.0)) + life_bonus-growth_max_hp
	unit["hp"] = mini(int(unit["hp"]), int(unit["max_hp"]))


func _credit_kill(killer_id: String, victim_id: String) -> void:
	if not _soldiers.has(killer_id) or not _soldiers.has(victim_id): return
	var killer: Dictionary = _soldiers[killer_id]
	_hero_statistics.death(_soldiers[victim_id],killer,_tick)
	# Nearby death passives also observe neutral kills; XP ownership remains
	# restricted to playable sides below. The innate owns its life receipt.
	if int(_soldiers[victim_id].hp)<=0: Innates.on_death(_soldiers[victim_id],killer,self)
	if int(_soldiers[victim_id].hp)<=0: ArmySupport.on_death(_soldiers[victim_id],self)
	_credit_death_for_side(str(killer.side),killer_id,victim_id)


func _credit_death_for_side(side: String,killer_id: String,victim_id: String) -> void:
	if _soldiers.has(victim_id): _hero_statistics.death(_soldiers[victim_id],_soldiers.get(killer_id,{"id":killer_id,"side":side}),_tick)
	if side not in _sides or not _soldiers.has(victim_id): return
	var victim: Dictionary = _soldiers[victim_id]
	if int(victim.hp)>0 or victim.side==side: return
	Innates.on_death(victim,_soldiers.get(killer_id,{}),self)
	ArmySupport.on_death(victim,self)
	var victim_level := int(_hero_data.get(victim_id,{}).get("level",victim.get("neutral_level",1)))
	var pool := HeroProgression.kill_reward(victim,victim_level)
	var award := _grant_shared_xp(side,victim.position,pool,"kill:%s:life:%d" % [victim_id,int(victim.get("life_generation",1))])
	if not bool(award.get("accepted",false)): return
	if _hero_data.has(killer_id):
		var killer:Dictionary=_hero_data[killer_id]
		killer.mana=mini(int(killer.max_mana),int(killer.mana)+int(ItemRules.equipment_stats(killer).mana_on_kill))
	if _neutrals!=null: _neutrals.record_death(killer_id,victim_id,self,side)


func _grant_shared_xp(side: String,position: Vector2i,pool: int,source_id: String) -> Dictionary:
	# Trusted settlement seam, never a player command. Full-cap heroes still
	# occupy their equal share; excess is discarded, not donated to another.
	if side not in _sides or pool<=0 or source_id.is_empty() or _shared_xp_receipts.has(source_id): return {"accepted":false}
	var base_pool:=pool
	var percentage:=int(_technology_modifiers_v4(side).hero_xp_percent)
	var numerator:=int(_xp_bonus_remainders_v4.get(side,0))+pool*(100+percentage)
	pool=numerator/100
	_xp_bonus_remainders_v4[side]=numerator%100
	var eligible: Array[String] = []
	for id: String in _sorted_keys(_hero_data):
		var body: Dictionary = _hero_body_r9(id)
		if body.side==side and int(body.hp)>0 and _distance_sq(body.position,position)<=HeroProgression.SHARED_XP_RADIUS*HeroProgression.SHARED_XP_RADIUS: eligible.append(id)
	var shares := {}
	var actual_total := 0
	for index: int in range(eligible.size()):
		var id: String = eligible[index]
		var share := pool/eligible.size() + (1 if index<pool%eligible.size() else 0)
		var actual := _grant_hero_xp(id,share)
		(_hero_data[id].credited_victim_ids as Array).append(source_id)
		shares[id]={"share":share,"actual":actual,"capped":share-actual}
		actual_total += actual
	var receipt := {"accepted":true,"side":side,"position":position,"base_pool":base_pool,"technology_percent":percentage,"pool":pool,"shares":shares,"actual_total":actual_total,"capped_or_unclaimed":pool-actual_total,"tick":_tick}
	_shared_xp_receipts[source_id]=receipt.duplicate(true)
	return receipt


func _grant_hero_xp(hero_id: String, amount: int) -> int:
	# Kills alone maintain credited_victim_ids. Archive XP shares only the level
	# transition, without manufacturing kills, healing or touching cooldowns.
	if amount <= 0 or not _hero_data.has(hero_id) or not _soldiers.has(hero_id) or int(_soldiers[hero_id].hp) <= 0: return 0
	var hero: Dictionary = _hero_data[hero_id]
	var actual := mini(amount, maxi(0, int(HeroProgression.XP_THRESHOLDS[-1]) - int(hero.xp)))
	var previous_level := int(hero.level)
	hero.xp = int(hero.xp) + actual
	hero.level = HeroProgression.level_for_xp(int(hero.xp))
	if int(hero.level) > previous_level:
		hero.skill_points = int(hero.skill_points) + int(hero.level) - previous_level
		hero.last_level_up_tick = _tick
	_refresh_stats(_soldiers[hero_id])
	return actual


func _reindex() -> void:
	_m93_begin()
	_rebuild_hero_auras(false)
	# Command-time death, transfer and revival must invalidate receiver caches
	# immediately, not grant one extra same-tick aura heal or mitigation.
	Innates.prepare(self)
	_m93_end()
	# Private disposable layout facts: reuse the existing membership pass and
	# never publish/copy cached per-body offsets into snapshots or replays.
	_role_members_r2.clear()
	for id:String in _role_layouts_r2.keys():
		if not _warbands.has(id) and not _type_cohorts_r12.has(id):_role_layouts_r2.erase(id)
	for army: Dictionary in _warbands.values():
		army["member_ids"] = []
		army["living_count"] = 0
		_role_members_r2[str(army.id)]={"ids":[],"pitch":32}
	for unit: Dictionary in _ordered_units():
		# Permanent roster accounting is independent from temporary controllers.
		var army: Dictionary = _warbands[unit["warband_id"]]
		unit["alive"] = int(unit["hp"]) > 0
		if not unit.alive:
			_clear_fold_slot_r12(unit)
			_schedule_corpse_r9(unit)
			unit.combat_statuses.clear()
			if _hero_data.has(unit.id) and _neutrals != null: _neutrals.record_hero_death(str(unit.id),self)
			if _hero_data.has(unit.id) and _hero_data[unit.id].has("item_effects"): _hero_data[unit.id].item_effects.clear()
			for field: String in ["stun_until_tick","root_until_tick","guard_until_tick","fervor_until_tick","rally_until_tick"]: unit[field] = -1
		_refresh_stats(unit)
		unit["member_index"] = int(army["living_count"])
		(army["member_ids"] as Array).append(unit["id"])
		if unit["alive"]:
			army["living_count"] = int(army["living_count"]) + 1
			army["unit_type"] = unit["unit_type"] if unit["unit_type"] != "hero" else army["unit_type"]
			var layout:Dictionary=_role_members_r2[str(army.id)]
			layout.ids.append(str(unit.id));layout.pitch=maxi(int(layout.pitch),int(unit.radius)*2+4)
	_prune_type_cohorts_r12()


func _move_members(source: String, target: String) -> void:
	for unit: Dictionary in _members(source):
		_clear_fold_slot_r12(unit)
		unit["warband_id"] = target
		if _preserving_ai_hero_withdrawal(unit): continue
		unit["direct_intent"] = ""
		unit["target_id"] = ""


func _cache_buildings(buildings: Array) -> void:
	_buildings = {}
	for value: Variant in buildings:
		if value is Dictionary and typeof(value.get("id")) == TYPE_STRING and value.get("side") in _sides and typeof(value.get("position")) == TYPE_VECTOR2I:
			_buildings[value["id"]] = value if _m93_owned_environment else value.duplicate(true)
	if _m93_owned_environment: _m93_owned_admissions += 1
	_refresh_route_geometry()


func _spawn_clear(position: Vector2i, radius: int,layer: String="GROUND") -> bool:
	if position.x < _bounds.position.x + radius or position.x > _bounds.end.x - radius or position.y < _bounds.position.y + radius or position.y > _bounds.end.y - radius: return false
	for unit: Dictionary in _ordered_units():
		if int(unit["hp"]) > 0 and unit.get("movement_layer","GROUND")==layer and _distance_sq(position, unit["position"]) < (radius + int(unit["radius"])) * (radius + int(unit["radius"])): return false
	if layer=="AIR":return true
	for prop: Dictionary in _terrain:
		if _distance_sq(position,prop.position)<(radius+int(prop.radius))*(radius+int(prop.radius)):return false
	for building: Dictionary in _ordered_buildings():
		var separation := radius + int(building.get("radius", 40 if building.get("building_type") == "BASE" else 32))
		if int(building.get("hp", 0)) > 0 and _distance_sq(position, building["position"]) < separation * separation: return false
	return true


func _nearest_injured(unit: Dictionary, radius: int) -> Dictionary:
	var recipients:=_injured_recipients(unit,radius,1)
	return recipients[0] if not recipients.is_empty() else {}

func _injured_recipients(unit: Dictionary,radius: int,limit: int) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var context: RefCounted = _m94_support_context()
	var candidates: Array[Dictionary] = context.radius_pool(unit.position,radius) if context!=null else _ordered_units()
	for ally: Dictionary in candidates:
		if ally["side"] != unit["side"] or int(ally["hp"]) <= 0 or int(ally["hp"]) >= int(ally["max_hp"]): continue
		var supported: Array=unit.get("heal_target_tags",[])
		if not supported.is_empty():
			var compatible:=false
			for tag: String in supported:
				if tag in ally.get("tags",[]):compatible=true
			if not compatible:continue
		var distance := _distance_sq(unit["position"], ally["position"])
		if distance>radius*radius:continue
		result.append(ally)
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var cross_a:=int(a.hp)*int(b.max_hp)
		var cross_b:=int(b.hp)*int(a.max_hp)
		if cross_a!=cross_b:return cross_a<cross_b
		var missing_a:=int(a.max_hp)-int(a.hp)
		var missing_b:=int(b.max_hp)-int(b.hp)
		return str(a.id)<str(b.id) if missing_a==missing_b else missing_a>missing_b)
	if result.size()>limit:result.resize(limit)
	return result


func _owned_army(id: Variant, side: String) -> Dictionary:
	return _warbands[id] if typeof(id) == TYPE_STRING and _warbands.has(id) and _warbands[id]["side"] == side and not _warbands[id]["reserve"] else {}


func _enemy_army(id: Variant, side: String) -> Dictionary:
	return _warbands[id] if typeof(id) == TYPE_STRING and _warbands.has(id) and _warbands[id]["side"] != side and not _warbands[id]["reserve"] else {}


func _has_living_hero(side: String, archetype: String = HeroCatalog.DEFAULT_ARCHETYPE) -> bool:
	for unit: Dictionary in _ordered_units():
		if unit["side"] == side and unit["unit_type"] == "hero" and unit.get("hero_archetype", HeroCatalog.DEFAULT_ARCHETYPE) == archetype and int(unit["hp"]) > 0: return true
	return false


func _fallen_hero_id(side: String, archetype: String = HeroCatalog.DEFAULT_ARCHETYPE) -> String:
	for id: String in _sorted_keys(_hero_data):
		var body := _hero_body_r9(id)
		if body.get("side") == side and body.get("unit_type") == "hero" and _hero_data[id].get("archetype", HeroCatalog.DEFAULT_ARCHETYPE) == archetype and int(body.get("hp",0)) <= 0:
			return id
	return ""


func _living_hero_count(side: String) -> int:
	var count := 0
	for unit: Dictionary in _ordered_units():
		if unit["side"] == side and unit["unit_type"] == "hero" and int(unit["hp"]) > 0: count += 1
	return count


func _published_skill(hero: Dictionary, id: String) -> Dictionary:
	var level := int(hero["skill_levels"].get(id,0))
	var skill: Dictionary = HeroCatalog.skill_at_level(id,level)
	var unit: Dictionary = _hero_body_r9(str(hero.id))
	skill["required_hero_level"] = HeroProgression.required_level(id,level+1)
	skill["can_upgrade"] = int(unit.hp)>0 and int(hero.skill_points)>0 and level<int(skill.max_level) and int(hero.level)>=int(skill.required_hero_level)
	skill["can_cast"] = level>0 and not bool(skill.passive) and int(unit.hp)>0 and not _stunned(unit) and int(hero.cooldowns[id])==0 and int(hero.mana)>=int(skill.mana_cost)
	if skill.has("r7_handler"): skill.can_cast=bool(skill.can_cast) and _r7_skills.can_cast(unit)
	var benefits:=Buffs.values(unit,_tick,_soldiers)
	var technology:=_technology_modifiers_v4(str(unit.side))
	var percentage:=float(ItemRules.equipment_skill_damage_percent(hero))+float(ItemRules.active_bonus(hero,_tick).skill_damage_percent)+float(benefits.skill_damage_percent)+float(technology.skill_damage_percent)
	if skill.has("r7_handler"):
		skill["r7_damage_multiplier"] = maxf(0.0,1.0+percentage/100.0)
		# Paid source buffs can expire or consume a charge before delivery.
		# Snapshot their duration contribution now; target vulnerability is
		# evaluated on attachment. Neither changes the finite raw damage pool.
		skill["r7_source_dot_duration_percent"] = clampi(int(benefits.dot_duration_percent), 0, 40)
		if int(skill.r7_source_dot_duration_percent) > 0 and not skill.get("r7_segments", []).is_empty():
			skill.description += " 来源持续时间加成+%d%%（完整伤害池不增加；目标易感在命中时另算，合计上限40%%）。" % int(skill.r7_source_dot_duration_percent)
	var healing:=float(ItemRules.equipment_stats(hero).healing_percent)+float(ItemRules.active_bonus(hero,_tick).healing_percent)+float(benefits.healing_percent)+float(technology.healing_percent)
	if skill.has("damage"):
		skill["base_damage"]=skill.damage
		skill["raw_damage"]=float(skill.damage)*(1.0+float(percentage)/100.0)
		skill.damage=roundi(float(skill.raw_damage))
	if str(skill.get("status_kind","")) in ["BURN","POISON"]:
		skill.status_power=float(skill.status_power)*(1.0+float(percentage)/100.0)
		if skill.has("status_total_damage"):skill.status_total_damage=float(skill.status_total_damage)*(1.0+float(percentage)/100.0)
	for key:String in ["heal","ally_heal"]:
		if skill.has(key):skill[key]=roundi(float(skill[key])*(1.0+float(healing)/100.0))
	if percentage>0:skill.description+=" 装备／增益／科技技能伤害合计+%d%%（直接与持续伤害各只应用一次，不强化普攻、治疗或控制）。"%percentage
	if healing>0:skill.description+=" 装备／增益／科技主动治疗合计+%d%%。"%healing
	return skill


func _advance_hero_automation() -> void:
	for id: String in _sorted_keys(_hero_data):
		var hero: Dictionary = _hero_data[id]
		var unit: Dictionary = _hero_body_r9(id)
		if not bool(hero["auto_skills"]) or int(unit["hp"]) <= 0 or _stunned(unit) or _tick-int(hero["last_auto_skill_tick"]) < 20: continue
		var army: Dictionary = _control_army_r12(unit)
		if unit["direct_intent"] in ["MOVE","HOLD"] or (unit["direct_intent"] == "" and army["intent"] in ["MOVE","RETREAT"]): continue
		for skill_id: String in HeroCatalog.profile(hero["archetype"])["skill_ids"]:
			if int(hero["cooldowns"][skill_id]) > 0: continue
			var skill := _published_skill(hero,skill_id)
			if not bool(skill.can_cast): continue
			var target := _useful_skill_target(unit,skill)
			if target.is_empty(): continue
			var command := {"type":"HERO_SKILL","unit_id":id,"skill_id":skill_id}
			if skill["target_mode"] == "POINT": command["target_position"] = _automatic_skill_position(unit,skill,target)
			var result := _unit_command(command,str(unit["side"]))
			if result.get("accepted",false):
				hero["last_auto_skill_tick"] = _tick
				break


func _automatic_skill_position(unit: Dictionary, skill: Dictionary, target: Dictionary) -> Vector2i:
	return SkillGeometry.aim_position(unit.position,skill,target.position,_bounds)


func _useful_skill_target(unit: Dictionary, skill: Dictionary) -> Dictionary:
	if skill.has("r7_handler"): return _r7_skills.useful_target(self,unit,skill)
	var effect: String = skill["effect"]
	if effect == "HEAL":
		return unit if int(unit["hp"])*10 <= int(unit["max_hp"])*7 or _has_useful_ally_effect(unit,skill) else {}
	if effect == "ARMOR_BUFF" and int(unit["guard_until_tick"]) > _tick: return {}
	if effect == "DAMAGE_BUFF":
		for entry:Dictionary in unit.get("source_buffs",{}).values():
			if entry.get("id")==skill.id and int(entry.expires_tick)>_tick:return {}
	if effect == "RALLY" and int(unit["rally_until_tick"]) > _tick: return {}
	var allowed := int(skill["range"]) if skill["target_mode"] == "POINT" else DISCOVERY_RANGE
	var best := allowed*allowed+1
	var result := {}
	for enemy: Dictionary in _ordered_units():
		if int(enemy["hp"]) <= 0 or enemy["side"] == unit["side"] or enemy.get("movement_layer","GROUND") not in skill.target_layers: continue
		if skill.get("power_class","")=="PURE_CONTROL":
			var field:="stun_until_tick" if skill.effect=="STUN" else "root_until_tick"
			if int(enemy.get(field,-1))>=_tick+DamageRules.control_ticks(_enhanced_duration(unit,int(skill.get("control_duration_ticks",0)),"HARD"),enemy):continue
		var distance := _distance_sq(unit["position"],enemy["position"])
		if distance < best:
			best=distance
			result=enemy
	# Skills can protect against or damage labourers too, but a nearby military
	# enemy has priority when both are eligible. Workers never grant soldier XP.
	if result.is_empty() and float(skill.get("raw_damage",skill.get("damage",0)))>0:
		for worker: Dictionary in _ordered_buildings():
			if not _is_worker(worker) or "GROUND" not in skill.target_layers or int(worker.get("hp",0)) <= 0 or worker["side"] == unit["side"]: continue
			var distance := _distance_sq(unit["position"],worker["position"])
			if distance < best:
				best=distance
				result=worker
	if result.is_empty(): return {}
	return unit if skill["target_mode"] == "SELF" or effect == "RALLY" else result


func _rebuild_hero_auras(apply_healing: bool) -> void:
	# At most three heroes per actual side, three skills each and one combined
	# equipment aura. Rebuilt from live bodies, so dead or distant sources cannot
	# leave stale passive buffs. Healing uses only the fixed 20-tick pulse.
	_hero_aura_bonuses.clear()
	var ordered := _ordered_units()
	for source_id: String in _sorted_keys(_hero_data):
		var source: Dictionary = _hero_body_r9(source_id)
		if int(source.hp)<=0: continue
		var hero: Dictionary = _hero_data[source_id]
		var auras: Array[Dictionary] = []
		for skill_id: String in hero.skill_levels:
			var rank := int(hero.skill_levels[skill_id])
			if rank<=0: continue
			var skill := HeroCatalog.skill_at_level(skill_id,rank)
			if skill.effect=="AURA": auras.append({"stats_id":skill_id,"stats_category":"SKILL","damage":float(skill.get("aura_damage",0)),"armor":float(skill.get("aura_armor",0)),"speed":float(skill.get("aura_speed",0)),"move_speed_percent":float(skill.get("aura_move_speed_percent",0)),"heal_per_second":float(skill.get("aura_heal",0)),"radius":int(skill.aura_radius),"max_targets":int(skill.max_targets)})
		var equipment_aura := ItemRules.equipment_aura(hero)
		equipment_aura["stats_id"]="ITEM_AURA"; equipment_aura["stats_category"]="ITEM"
		if int(equipment_aura.get("radius",0))>0: auras.append(equipment_aura)
		for aura: Dictionary in auras:
			var candidates: Array[Dictionary] = []
			var radius := int(aura.radius)
			var candidates_pool: Array[Dictionary] = _m93_context.radius_pool(source.position, radius) if _m93_context != null else ordered
			for ally: Dictionary in candidates_pool:
				if ally.side==source.side and int(ally.hp)>0 and _distance_sq(ally.position,source.position)<=radius*radius: candidates.append(ally)
			candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
				var left := _distance_sq(a.position,source.position)
				var right := _distance_sq(b.position,source.position)
				return left<right if left!=right else str(a.id)<str(b.id))
			if candidates.size()>int(aura.max_targets): candidates.resize(int(aura.max_targets))
			for ally: Dictionary in candidates:
				var bonus: Dictionary = _hero_aura_bonuses.get(str(ally.id),{"damage":0,"armor":0,"speed":0,"heal_per_second":0.0,"mana_per_second":0.0,"sources":{}})
				for field: String in ["damage","armor","speed","move_speed_percent","heal_per_second","mana_per_second"]:
					if float(aura.get(field,0))>float(bonus.get(field,0)):
						bonus[field]=float(aura[field])
						bonus.sources[field]={"id":source_id,"faction_id":source.faction_id,"radius":radius,"stats_id":aura.get("stats_id","AURA"),"stats_category":aura.get("stats_category","OTHER")}
				_hero_aura_bonuses[str(ally.id)]=bonus
	if apply_healing and _tick>0 and _tick%20==0:
		for id: String in _sorted_keys(_hero_aura_bonuses):
			var unit: Dictionary = _soldiers[id]
			var heal_source:Dictionary=_hero_aura_bonuses[id].sources.get("heal_per_second",{})
			var heal_key := str(heal_source.get("id",""))+":"+str(heal_source.get("stats_id","AURA"))
			var heal_carries:Dictionary=unit.get("aura_heal_carries",{})
			var heal_credit:=float(heal_carries.get(heal_key,0.0))+float(_hero_aura_bonuses[id].heal_per_second)
			heal_carries[heal_key]=heal_credit-floorf(heal_credit) if int(unit.hp)<int(unit.max_hp) else 0.0
			unit["aura_heal_carries"]=heal_carries
			_apply_heal(unit,floorf(heal_credit),_soldiers.get(str(heal_source.get("id","")),{}),false,{"id":heal_source.get("stats_id","AURA"),"category":heal_source.get("stats_category","OTHER")})
			var owner:Dictionary=_hero_data.get(id,unit)
			var mana_credit:=float(unit.get("aura_mana_carry",0))+float(_hero_aura_bonuses[id].get("mana_per_second",0))
			owner.mana=mini(int(owner.get("max_mana",0)),int(owner.get("mana",0))+floori(mana_credit))
			unit["aura_mana_carry"]=mana_credit-floorf(mana_credit)


func _is_worker(body: Dictionary) -> bool:
	return body.get("building_type","") == "WORKER_OBSTACLE"


func _valid_enemy_unit(id: String, side: String) -> bool:
	if _soldiers.has(id): return _soldiers[id]["side"] != side and int(_soldiers[id]["hp"]) > 0
	if _buildings.has(id):
		var body: Dictionary = _buildings[id]
		return (_is_worker(body) or _attackable_building(body)) and body["side"] != side and int(body.get("hp",0)) > 0
	return false


static func _attackable_building(body:Dictionary)->bool:
	# Constructible catalog membership is not combat targetability: captured
	# site towers are real targets, while the fixed shop is deliberately not.
	return not bool(body.get("fixed",false)) and bool(body.get("attackable",true)) and (Progression.BUILDING_TIERS.has(body.get("building_type")) or body.get("building_type")=="SITE_TOWER")


func _stunned(unit: Dictionary) -> bool:
	return int(unit.get("stun_until_tick", -1)) > _tick


func _movement_controlled(unit: Dictionary) -> bool:
	return _stunned(unit) or int(unit.get("root_until_tick", -1)) > _tick or _r7_skills.is_busy(str(unit.get("id","")))


func _status_effects(unit: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if int(unit["hp"]) <= 0: return result
	result.append_array(_r7_skills.status_snapshot(str(unit.id),_tick))
	for pair: Array in [["STUN", "stun_until_tick"], ["ROOT", "root_until_tick"]]:
		var remaining := maxi(0, int(unit.get(pair[1], -1)) - _tick)
		if remaining > 0: result.append({"id":pair[0], "kind":pair[0], "remaining_ticks":remaining, "expires_tick":unit[pair[1]],"source_faction":unit.get("stun_source_faction" if pair[0]=="STUN" else "root_source_faction",""),"source_id":unit.get("stun_source_id" if pair[0]=="STUN" else "root_source_id",""),"skill_id":unit.get("stun_skill_id" if pair[0]=="STUN" else "root_skill_id","")})
	for id: String in _sorted_keys(unit.get("combat_statuses",{})):
		var status: Dictionary=unit.combat_statuses[id]
		if int(status.expires_tick)<=_tick: continue
		var published := status.duplicate(true)
		published["id"] = id
		published["remaining_ticks"] = int(status.expires_tick)-_tick
		result.append(published)
	for buff:Dictionary in unit.get("source_buffs",{}).values():
		if buff.get("effect","")=="DAMAGE_LINK":continue
		if int(buff.expires_tick)>_tick and int(buff.get("charges",-1))!=0:result.append({"id":buff.id,"kind":"FERVOR","remaining_ticks":int(buff.expires_tick)-_tick,"expires_tick":buff.expires_tick,"source_id":buff.source_id,"source_faction":unit.faction_id})
	result.append_array(EliteRuntimeR4.visual_statuses(unit,self))
	for shield:Dictionary in unit.get("innate_shield",{}).values():
		if int(shield.expires_tick)>_tick:result.append({"id":"INNATE_SHIELD","kind":"GUARD","remaining_ticks":int(shield.expires_tick)-_tick,"expires_tick":shield.expires_tick,"source_id":shield.source_id,"source_faction":unit.faction_id})
	for effect:Dictionary in unit.get("secondary_effects",{}).values():
		var kind:=ItemRules.secondary_status_kind(effect)
		if int(effect.get("expires_tick",-1))>_tick and kind in ["BURN","POISON","HEAL"]:result.append({"id":effect.id,"kind":kind,"remaining_ticks":int(effect.expires_tick)-_tick,"expires_tick":effect.expires_tick,"source_id":effect.source_id,"source_faction":effect.source_faction})
	if not unit.get("innate_aura",{}).get("sources",[]).is_empty():result.append({"id":"INNATE_AURA","kind":"AURA","remaining_ticks":1,"source_faction":unit.faction_id})
	return result


func _resolve_damage(raw:float,attack_type:String,target:Dictionary,source:Dictionary,basic:bool=false,cause:Dictionary={})->int:
	if raw<=0:return 0
	if basic:raw*=float(Innates.incoming_basic_percent(target,source,self))/100.0
	var amount:=DamageRules.resolve(raw,attack_type,target)
	var remaining:=_absorb_damage(amount,target,basic)
	if remaining==0 and amount>0:
		var details := {"amount":0,"absorbed":amount,"attack_type":attack_type}
		if cause.get("category","")=="SKILL": details["skill_id"]=cause.get("id","")
		for key: String in ["cast_id","r7_design_id","dot","rank","ultimate"]:
			if cause.has(key): details[key]=cause[key]
		_feedback("HIT",source,target,details)
	return remaining


## The only post-mitigation body-HP settlement seam. A transfer is a partition
## of the original attack, NOT another hit: no second armor/shield/on-hit pass.
## Credit actual HP only; pending reservations prevent same-tick over-credit.
func _deal_body_damage_r4(target:Dictionary,source:Dictionary,amount:int,attack_type:String,cause:Dictionary={},pending:Dictionary={},killers:Dictionary={},batched:bool=false)->Dictionary:
	var result:={"primary":0,"transferred":0,"total":0}
	if _r4_elite_dirty:EliteRuntimeR4.prepare(self)
	var reserved:Dictionary=pending if batched else _r4_pending_damage
	var free_hp:=maxi(0,int(target.get("hp",0))-int(reserved.get(str(target.get("id","")),0)))
	if amount<=0 or free_hp<=0:return result
	var guard:=EliteRuntimeR4.protector(target,self)
	if not guard.is_empty():
		var protector:Dictionary=guard.source
		var transfer:=mini(floori(float(amount)*float(guard.percent)/100.0),int(guard.available))
		if guard.paid:transfer=mini(transfer,int(protector.elite_link_ledger_r4.remaining))
		if transfer>0:
			if guard.paid:protector.elite_link_ledger_r4.remaining=int(protector.elite_link_ledger_r4.remaining)-transfer
			var transfer_cause:=cause.duplicate();transfer_cause["redirected"]=true;transfer_cause["protected_id"]=target.id
			_record_damage(protector,source,transfer,attack_type,transfer_cause)
			if batched:pending[protector.id]=int(pending.get(protector.id,0))+transfer
			else:
				var before:=int(protector.hp);protector.hp=before-transfer;protector.alive=int(protector.hp)>0
				_after_body_hp_damage_r3(protector,before)
			protector["last_elite_redirect_tick_r4"]=_tick;protector["last_elite_redirect_amount_r4"]=transfer
			_feedback("GUARD",protector,target,{"skill_id":guard.spec.id,"amount":transfer,"expires_tick":_tick+10})
			result.transferred=transfer
	var actual:=mini(free_hp,maxi(0,amount-int(result.transferred)))
	if actual>0:
		_record_damage(target,source,actual,attack_type,cause)
		if batched:
			pending[target.id]=int(pending.get(target.id,0))+actual
			if not killers.has(target.id):killers[target.id]=source.get("id","")
		else:
			var before:=int(target.hp);target.hp=before-actual;target.alive=int(target.hp)>0
			_after_body_hp_damage_r3(target,before)
	result.primary=actual;result.total=actual+int(result.transferred)
	return result


func _absorb_damage(amount:int,target:Dictionary,basic:bool=false)->int:
	if amount<=0:return 0
	var innate_capacity:=0.0
	for shield:Dictionary in target.get("innate_shield",{}).values():
		if int(shield.get("expires_tick",-1))<=_tick:continue
		var capacity:=minf(float(amount),float(shield.amount)) if shield.kind=="FLAT" else minf(float(shield.cap),float(amount)*float(shield.percent)/100.0) if basic else 0.0
		innate_capacity=maxf(innate_capacity,capacity)
	var hero:Dictionary=_hero_data.get(str(target.get("id","")),{})
	var item_capacity:=0
	for effect:Dictionary in hero.get("item_effects",{}).values():
		if int(effect.get("expires_tick",-1))>_tick:item_capacity=maxi(item_capacity,int(effect.get("shield_remaining",0)))
	var remaining:=ItemRules.absorb_shield(hero,amount,_tick) if item_capacity>0 and float(mini(item_capacity,amount))>=innate_capacity else maxi(0,roundi(Innates.consume_shield(target,float(amount),basic,self)))
	target["damage_absorbed"]=int(target.get("damage_absorbed",0))+amount-remaining
	return remaining


func _lifesteal_credit(unit: Dictionary, id: String, raw: float) -> int:
	# Fractional skill percentages survive until integer HP settlement; independent
	# sources cannot overwrite one another's sub-HP remainder. Fresh body on revive.
	var carries: Dictionary = unit.get("lifesteal_carries",{})
	var credit := float(carries.get(id,0.0))+raw
	var whole := floori(credit+0.000000001)
	carries[id] = maxf(0.0,credit-float(whole))
	unit["lifesteal_carries"] = carries
	return whole


## Constant-time, event-driven native troop recovery. Called only AFTER real
## body HP settlement, never by snapshots/stat getters or the damage observer.
func _after_body_hp_damage_r3(body:Dictionary,hp_before:int)->void:
	var hp:=int(body.get("hp",0))
	if hp<=0 or hp>=hp_before or bool(body.get("neutral",false)) or str(body.get("unit_type",""))=="hero":return
	var spec:Dictionary=body.get("troop_passive",{})
	if spec.get("effect","")!="CRITICAL_RECOVERY":return
	var maximum:=int(body.get("max_hp",0))
	var threshold:=int(spec.get("trigger_hp_percent",0))
	if maximum<=0 or hp_before*100<=maximum*threshold or hp*100>maximum*threshold:return
	if _tick<int(body.get("troop_passive_ready_tick_r3",0)):return
	# Spend the physical body's deadline before healing or emitting callbacks.
	body["troop_passive_ready_tick_r3"]=_tick+int(spec.cooldown_ticks)
	body["last_troop_passive_tick_r3"]=_tick
	var prior_skill:Variant=body.get("feedback_skill_id")
	body["feedback_skill_id"]=str(spec.id)
	_apply_heal(body,floorf(float(maximum)*float(spec.heal_max_hp_percent)/100.0),body,false,{"id":str(spec.id),"category":"OTHER"})
	if prior_skill==null:body.erase("feedback_skill_id")
	else:body["feedback_skill_id"]=prior_skill


func _apply_heal(target:Dictionary,raw:float,source:Dictionary={},active:bool=false,cause:Dictionary={})->int:
	if raw<=0 or int(target.get("hp",0))<=0 or int(target.hp)>=int(target.max_hp):return 0
	if active:raw+=Innates.heal_raw_bonus(source,target,raw,self)
	raw=raw*float(Innates.healing_received_percent(target,active))/100.0
	var amount:=mini(int(target.max_hp)-int(target.hp),maxi(0,roundi(raw)))
	target.hp=int(target.hp)+amount
	var stats_cause := cause if not cause.is_empty() else {"id":source.get("feedback_skill_id","RECOVERY"),"category":"SKILL" if source.has("feedback_skill_id") else "OTHER"}
	_hero_statistics.heal(source,target,amount,stats_cause)
	if not source.is_empty():
		target["last_heal_source_id"]=str(source.get("id",""))
		target["last_heal_tick"]=_tick
		target["last_heal_amount"]=amount
		if _soldiers.has(str(source.get("id",""))):
			var actual_source:Dictionary=_soldiers[str(source.id)]
			actual_source["healing_done"]=int(actual_source.get("healing_done",0))+amount
	if active:Innates.on_heal(source,target,amount,self)
	_healing_feedback_r9(source,target,amount,stats_cause,not active)
	return amount


func _advance_innate_effects()->void:
	_announce_innate_statuses()
	for event:Dictionary in Innates.take_due_effects(self):
		var target:Dictionary=_soldiers.get(str(event.target_id),{})
		if target.is_empty() or int(target.hp)<=0:continue
		var kind:=str(event.kind)
		if kind=="DAMAGE":
			var source:Dictionary=_soldiers.get(str(event.source_id),{"id":event.source_id,"side":event.source_side,"faction_id":event.source_faction})
			if not target.has("secondary_damage_carry"):target["secondary_damage_carry"]={}
			var key:=str(event.id)
			var credit:=float(target.secondary_damage_carry.get(key,0))+DamageRules.mitigate(float(event.amount),str(event.attack_type),target)
			var whole:=floori(credit)
			target.secondary_damage_carry[key]=credit-float(whole)
			var amount:=_absorb_damage(whole,target,false)
			_deal_body_damage_r4(target,source,amount,str(event.attack_type),{"id":"INNATE_"+str(source.get("hero_archetype","UNKNOWN")),"category":"INNATE","dot":true})
			if not target.alive:_credit_death_for_side(str(event.source_side),str(event.source_id),str(target.id))
		else:
			if not target.has("secondary_carry"):target["secondary_carry"]={}
			var credit:=float(target.secondary_carry.get(kind,0.0))+float(event.amount)
			var whole:=floori(credit)
			target.secondary_carry[kind]=credit-float(whole)
			if kind=="HEAL":
				var heal_source:Dictionary=_soldiers.get(str(event.source_id),{})
				_apply_heal(target,float(whole),heal_source,false,{"id":"INNATE_"+str(heal_source.get("hero_archetype","UNKNOWN")),"category":"INNATE"})
			elif kind=="MANA":
				var owner:Dictionary=_hero_data.get(str(target.id),target)
				owner.mana=mini(int(owner.get("max_mana",0)),int(owner.get("mana",0))+whole)
		var semantic:=ItemRules.secondary_status_kind(event)
		if int(event.get("pulses_left",0))==1 and semantic in ["BURN","POISON"]:
			_feedback("STATUS",_soldiers.get(str(event.source_id),{"id":event.source_id,"side":event.source_side,"faction_id":event.source_faction}),target,{"status_kind":semantic,"phase":"END"})


func _announce_innate_statuses()->void:
	# Mark the existing authoritative effect, not a parallel lifetime ledger.
	# Refresh/replacement creates a new entry and therefore a new real onset.
	for target:Dictionary in _ordered_units():
		if int(target.hp)<=0:continue
		for effect:Dictionary in target.get("secondary_effects",{}).values():
			var semantic:=ItemRules.secondary_status_kind(effect)
			if effect.get("origin","")!="INNATE" or semantic not in ["BURN","POISON"] or bool(effect.get("feedback_started",false)):continue
			effect["feedback_started"]=true
			_feedback("STATUS",_soldiers.get(str(effect.source_id),{"id":effect.source_id,"side":effect.source_side,"faction_id":effect.source_faction}),target,{"status_kind":semantic,"expires_tick":effect.expires_tick})


func _end_buff_feedback(target:Dictionary,entry:Dictionary)->void:
	if bool(entry.get("feedback_ended",false)) or int(target.hp)<=0:return
	entry["feedback_ended"]=true
	_feedback("BUFF",_soldiers.get(str(entry.source_id),{"id":entry.source_id}),target,{"phase":"END","buff_id":entry.id,"skill_id":entry.id})


func _finish_expired_buff_feedback()->void:
	# Resolve expiry before stat queries prune the source-owned entry.
	for target:Dictionary in _ordered_units():
		for entry:Dictionary in target.get("source_buffs",{}).values():
			if int(entry.expires_tick)<=_tick or int(entry.get("charges",-1))==0:_end_buff_feedback(target,entry)


func _consume_buffs(target:Dictionary,kind:String)->void:
	Buffs.consume(target,kind,_tick)
	for entry:Dictionary in target.get("source_buffs",{}).values():
		if entry.get("charge_kind","")==kind and int(entry.get("charges",-1))==0:_end_buff_feedback(target,entry)


func _record_damage(victim: Dictionary, source: Dictionary, amount: int, attack_type: String, cause: Dictionary = {}) -> void:
	if amount <= 0: return
	if _statistics_batching and not bool(cause.get("dot",false)):
		var id := str(victim.id)
		if not _statistics_pending_hits.has(id): _statistics_pending_hits[id]=[]
		_statistics_pending_hits[id].append({"source":source,"amount":amount,"attack_type":attack_type,"cause":cause.duplicate(true)})
	else:
		_hero_statistics.damage(source,victim,amount,_tick,cause)
		_damage_feedback_r9(victim,source,amount,attack_type,cause)
	if _soldiers.has(str(source.get("id",""))):
		var actual_source:Dictionary=_soldiers[str(source.id)]
		actual_source["damage_dealt"]=int(actual_source.get("damage_dealt",0))+amount
	var same_tick := int(victim.get("last_damage_tick",-1000000)) == _tick
	victim["last_damage_tick"] = _tick
	victim["last_damage_amount"] = (int(victim.get("last_damage_amount",0)) if same_tick else 0) + amount
	victim["last_damage_source_id"] = str(source.get("id",""))
	victim["last_damage_source_faction"] = str(source.get("faction_id",""))
	victim["last_damage_attack_type"] = attack_type

func _damage_feedback_r9(victim: Dictionary, source: Dictionary, actual: int, attack_type: String, cause: Dictionary={}) -> void:
	if actual<=0:return
	var details := {"amount":actual,"attack_type":attack_type}
	if cause.get("category","")=="SKILL":details["skill_id"]=cause.get("id","")
	for key: String in ["cast_id","r7_design_id","dot","rank","ultimate"]:
		if cause.has(key):details[key]=cause[key]
	_feedback("HIT",source,victim,details)

func _healing_feedback_r9(source: Dictionary,target: Dictionary,actual: int,cause: Dictionary={},silent:bool=true) -> void:
	if actual>0:_feedback("HEAL",source,target,{"amount":actual,"skill_id":cause.get("id","RECOVERY"),"silent_audio":silent})


func _apply_signature(source: Dictionary, target: Dictionary, ability: Dictionary) -> void:
	var kind := str(ability.get("status_kind",""))
	if kind not in ["SLOW","BURN","POISON","ARMOR_BREAK"] or _is_worker(target) or int(target.hp)<=0: return
	var duration := _enhanced_duration(source,int(ability.get("status_duration_ticks",0)),"WEAK" if kind=="SLOW" else "DOT" if kind in ["BURN","POISON"] else "WEAK",target)
	if kind=="SLOW": duration = DamageRules.control_ticks(duration,target)
	var power := maxf(0.0,float(ability.get("status_power",0)))
	if kind in ["BURN","POISON"] and ability.has("fixed_dot_total_v4"):power=float(ability.fixed_dot_total_v4)*20.0/maxi(1,duration)
	if kind=="SLOW":power=minf(power,60.0)
	var statuses: Dictionary=target.combat_statuses
	var old: Dictionary=statuses.get(kind,{})
	var active := int(old.get("expires_tick",-1))>_tick
	# A weak arrow cannot perpetually extend a stronger hero poison/shred.
	# Equal potency refreshes, stronger potency starts its own finite duration.
	if active and power<float(old.power): return
	if active and kind in ["BURN","POISON"]:
		_settle_status_pulse(target,old,_tick)
		if int(target.hp)<=0:
			# The old unpaid fraction, not this new signature, owns the kill.
			# Normal pulse settlement credits outside its helper; refresh must
			# do the same before returning and must never reapply to a corpse.
			_credit_status_kill_r10(target,old)
			return
	var expires := maxi(_tick+duration,int(old.expires_tick)) if active and is_equal_approx(power,float(old.power)) else _tick+duration
	statuses[kind] = {"kind":kind,"power":power,"expires_tick":expires,"last_pulse_tick":_tick,"next_tick":_tick+20,"source_id":source.id,"source_side":source.side,"source_faction":source.faction_id,"attack_type":"ARCANE","skill_id":ability.get("id","BASIC_SIGNATURE"),"stats_category":ability.get("stats_category","SKILL" if ability.has("id") and HeroCatalog.SKILLS.has(ability.id) else "BASIC"),"dot_drain_percent":float(ability.get("dot_drain_percent",0))}
	if not active or power>float(old.get("power",0)):_feedback("STATUS",source,target,{"status_kind":kind,"expires_tick":expires})
	Innates.on_status_applied(source,target,statuses[kind],self)
	source.last_proc_tick = _tick
	source.last_proc_id = kind
	source.last_proc_target_position = target.position
	_refresh_stats(target)


func _advance_status_damage() -> void:
	for victim: Dictionary in _ordered_units():
		if int(victim.hp)<=0: continue
		for control:String in ["STUN","ROOT"]:
			var prefix:="stun" if control=="STUN" else "root"
			if int(victim.get(prefix+"_until_tick",-1))==_tick:
				_feedback("CONTROL",_soldiers.get(str(victim.get(prefix+"_source_id","")),{}),victim,{"status_kind":control,"phase":"END"})
		var statuses: Dictionary=victim.combat_statuses
		for kind: String in _sorted_keys(statuses):
			var status: Dictionary=statuses[kind]
			if kind in ["BURN","POISON"] and (_tick>=int(status.next_tick) or _tick>=int(status.expires_tick)):
				_settle_status_pulse(victim,status,_tick)
				if not victim.alive:
					_credit_status_kill_r10(victim,status)
					break
			if _tick>=int(status.expires_tick):
				_feedback("STATUS",_soldiers.get(str(status.source_id),{"id":status.source_id,"faction_id":status.source_faction}),victim,{"status_kind":status.get("kind",kind),"phase":"END"})
				statuses.erase(kind)


func _credit_status_kill_r10(victim:Dictionary,status:Dictionary)->void:
	var source_id:=str(status.get("source_id",""))
	if _soldiers.has(source_id):_credit_kill(source_id,str(victim.id))
	else:
		# The finite delivered status owns its trusted side even after its
		# source's ten-second corpse expiry; do not reconstruct a spatial body.
		_credit_death_for_side(str(status.get("source_side","")),source_id,str(victim.id))

func _settle_status_pulse(victim:Dictionary,status:Dictionary,tick:int)->void:
	var pulse_end:=mini(tick,int(status.expires_tick))
	var elapsed:=maxi(0,pulse_end-int(status.get("last_pulse_tick",int(status.next_tick)-20)))
	if elapsed<=0:return
	var source:Dictionary=_soldiers.get(str(status.source_id),{"id":status.source_id,"side":status.get("source_side",""),"faction_id":status.source_faction})
	var carry_key:="status_damage_carry:"+str(status.kind)
	var credit:=float(victim.get(carry_key,0))+DamageRules.mitigate(float(status.power)*float(elapsed)/20.0,"ARCANE",victim)
	var whole:=roundi(credit) if pulse_end==int(status.expires_tick) else floori(credit)
	victim[carry_key]=credit-float(whole)
	var amount:=_absorb_damage(whole,victim,false)
	if amount==0 and whole>0:_feedback("HIT",source,victim,{"amount":0,"absorbed":whole,"attack_type":"ARCANE"})
	var settled:=_deal_body_damage_r4(victim,source,amount,"ARCANE",{"id":status.get("skill_id","SIGNATURE"),"category":status.get("stats_category","OTHER"),"dot":true})
	var actual:=int(settled.total)
	if actual>0 and float(status.get("dot_drain_percent",0))>0 and int(source.get("hp",0))>0:
		_apply_heal(source,_lifesteal_credit(source,str(status.get("skill_id","DOT")),float(actual)*float(status.dot_drain_percent)/100.0),source,false,{"id":status.get("skill_id","DOT"),"category":"SKILL"})
	status["last_pulse_tick"]=pulse_end
	status.next_tick=pulse_end+20


func _enhanced_duration(source:Dictionary,duration:int,kind:String,target:Dictionary={})->int:
	var benefits:=Buffs.values(source,_tick,_soldiers) if not source.is_empty() else {}
	var field:="hard_duration_percent" if kind=="HARD" else "weak_duration_percent" if kind=="WEAK" else "dot_duration_percent"
	var percentage:=int(benefits.get(field,0))
	if kind=="DOT":
		var vulnerability:=0
		for entry:Dictionary in target.get("duration_vulnerabilities",{}).values():
			if int(entry.expires_tick)>_tick:vulnerability=maxi(vulnerability,int(entry.get(field,0)))
		percentage=mini(40,percentage+vulnerability)
	return roundi(float(duration)*(1.0+float(percentage)/100.0))


func _feedback(kind:String,source:Dictionary,target:Dictionary={},details:Dictionary={})->void:
	_feedback_serial+=1
	var actual:Dictionary=_soldiers.get(str(source.get("id","")),source)
	if kind=="CAST" and actual.get("unit_type","")!="hero":
		_hero_statistics.cast(actual,str(details.get("skill_id",actual.get("feedback_skill_id",""))))
	var identity:={}
	for key:String in ["id","side","faction_id","unit_type","hero_archetype","position","body_kind","role","attack_type"]:
		if actual.has(key):identity[key]=actual[key]
	var event:={"event_id":"%d:%d:%d"%[_seed,_feedback_generation,_feedback_serial],"tick":maxi(0,_tick),"kind":kind,"source":identity,"target":{},"skill_id":actual.get("feedback_skill_id",""),"rank":actual.get("feedback_skill_rank",1),"ultimate":actual.get("feedback_skill_ultimate",false)}
	for key:String in ["id","side","position","armor_type"]:
		if target.has(key):event.target[key]=target[key]
	event.merge(details,true)
	_feedback_events.append(event)
	while _feedback_events.size()>256 or (not _feedback_events.is_empty() and int(_feedback_events[0].tick)<_tick-80):_feedback_events.pop_front()


func _cleanse_dots(unit: Dictionary) -> void:
	# The same semantic burn/poison can originate from a signature or an
	# innate's scheduled pulses. Keep authority, preview and removal aligned;
	# periodic healing/mana and their carry are not debuffs.
	var statuses_before := _status_effects(unit)
	ItemRules.cleanse_statuses(unit,["BURN","POISON"],_tick)
	for kind:String in ["BURN","POISON"]:unit.erase("status_damage_carry:"+kind)
	_feedback_removed_statuses(unit,statuses_before)


func _feedback_removed_statuses(unit:Dictionary,before:Array[Dictionary])->void:
	# Feedback follows successful authoritative removal, never an attempted
	# cleanse. Multiple sources sharing one semantic state produce one ending.
	var remaining:={}
	var remaining_r7:={}
	for status:Dictionary in _status_effects(unit):
		remaining[str(status.get("kind",""))]=true
		if status.has("r7_handler"): remaining_r7[str(status.get("skill_id",""))+":"+str(status.get("cast_id",""))]=true
	var emitted:={}
	for status:Dictionary in before:
		var kind:=str(status.get("kind",""))
		if status.has("r7_handler"):
			# Identity is presentation metadata from the actual deleted record.
			# Two different burns must both end, not collapse into one kind END.
			var key:=str(status.get("skill_id",""))+":"+str(status.get("cast_id",""))
			if remaining_r7.has(key) or emitted.has(key): continue
			emitted[key]=true
			var owner:Dictionary=_soldiers.get(str(status.get("source_id","")),{"id":status.get("source_id",""),"faction_id":status.get("source_faction","")})
			_feedback("STATUS",owner,unit,{"status_kind":kind,"phase":"END","r7_phase":"CLEANSED",
				"r7_handler":status.r7_handler,"skill_id":status.get("skill_id",""),"cast_id":status.get("cast_id",""),
				"r7_design_id":status.get("r7_design_id",""),"rank":status.get("rank",1),"ultimate":status.get("ultimate",false)})
			continue
		if kind not in ["BURN","POISON","SLOW","STUN","ROOT"] or remaining.has(kind) or emitted.has(kind):continue
		emitted[kind]=true
		var source:Dictionary=_soldiers.get(str(status.get("source_id","")),{"id":status.get("source_id",""),"faction_id":status.get("source_faction","")})
		_feedback("CONTROL" if kind in ["STUN","ROOT"] else "STATUS",source,unit,{"status_kind":kind,"phase":"END"})


func _grant_guard(unit: Dictionary, amount: float, duration: int, speed_bonus: float=0.0) -> void:
	var active := int(unit.guard_until_tick)>_tick
	if active and amount<float(unit.guard_armor_bonus): return
	unit.guard_until_tick = maxi(int(unit.guard_until_tick),_tick+duration) if active and amount==float(unit.guard_armor_bonus) else _tick+duration
	unit.guard_armor_bonus = amount
	unit.guard_speed_bonus = speed_bonus
	_refresh_stats(unit)


func _skill_targets(caster: Dictionary, skill: Dictionary, position: Vector2i) -> Array[Dictionary]:
	var pool: Array[Dictionary]=_ordered_units().duplicate()
	if skill.has("r7_handler"): return SkillGeometry.targets(caster,skill,position,pool)
	for worker: Dictionary in _ordered_buildings():
		if _is_worker(worker) and float(skill.get("raw_damage",skill.get("damage",0)))>0: pool.append(worker)
	return SkillGeometry.targets(caster,skill,position,pool)


func _skill_allies(caster: Dictionary, skill: Dictionary, position: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var radius := int(skill.get("ally_radius",skill.radius))
	var center: Vector2i=caster.position if skill.target_mode=="SELF" else position
	for ally: Dictionary in _ordered_units():
		if ally.side!=caster.side or int(ally.hp)<=0 or _distance_sq(ally.position,center)>radius*radius: continue
		if ally.id==caster.id and skill.effect!="RALLY": continue
		if not str(skill.get("ally_required_tag","")).is_empty() and skill.ally_required_tag not in ally.get("tags",[]): continue
		result.append(ally)
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var da:=_distance_sq(a.position,center)
		var db:=_distance_sq(b.position,center)
		return str(a.id)<str(b.id) if da==db else da<db)
	if result.size()>int(skill.max_targets): result.resize(int(skill.max_targets))
	return result


func _has_useful_ally_effect(caster: Dictionary, skill: Dictionary) -> bool:
	if not skill.has("ally_heal"): return false
	for ally: Dictionary in _skill_allies(caster,skill,caster.position):
		if int(ally.hp)<int(ally.max_hp): return true
	return false


func _members(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _type_cohorts_r12.has(id):
		var cohort: Dictionary = _type_cohorts_r12[id]
		for member_id: String in cohort.member_ids:
			var body: Dictionary = _soldiers.get(member_id,{})
			if not body.is_empty() and body.warband_id==cohort.parent_id and body.get("command_army_id_r12")==id: result.append(body)
		return result
	if not _warbands.has(id): return result
	# _reindex retains every member ID in the same global lexical order.
	# Read current live records: paid recall replaces a body under its old ID.
	for member_id: String in _warbands[id]["member_ids"]:
		result.append(_soldiers[member_id])
	return result


func _living_members(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit: Dictionary in _members(id):
		if int(unit["hp"]) > 0: result.append(unit)
	return result


func _ordered_units() -> Array[Dictionary]:
	if _m90_order_scope:
		if _m90_order_count != _soldiers.size():
			_m90_ordered.clear()
			for id: String in _sorted_keys(_soldiers): _m90_ordered.append(_soldiers[id])
			_m90_order_count = _soldiers.size()
		return _m90_ordered.duplicate(false)
	var result: Array[Dictionary] = []
	for id: String in _sorted_keys(_soldiers): result.append(_soldiers[id])
	return result


func _m90_invalidate_order() -> void:
	# Existing reset/spawn/revive/admission invalidation is also the boundary
	# for a post-movement index. No stale same-ID replacement may be retained.
	_m94_end_actions()
	_m90_order_count = -1
	_m90_ordered.clear()


func _ordered_buildings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in _sorted_keys(_buildings): result.append(_buildings[id])
	return result


static func _sorted_keys(values: Dictionary) -> Array:
	var ids := values.keys()
	ids.sort()
	return ids


func _valid_point(value: Variant) -> bool:
	return typeof(value) == TYPE_VECTOR2I and value.x >= _bounds.position.x and value.y >= _bounds.position.y and value.x <= _bounds.end.x and value.y <= _bounds.end.y


static func _distance_sq(a: Vector2i, b: Vector2i) -> int:
	var delta := a - b
	return delta.x * delta.x + delta.y * delta.y


static func _in_attack_range(unit: Dictionary, target: Dictionary) -> bool:
	if not _can_attack(unit,target):return false
	var reach := int(unit["attack_range"]) + int(target.get("radius", 32 if target.has("building_type") else 12))
	return _distance_sq(unit["position"], target["position"]) <= reach * reach


static func _step_towards(position: Vector2i, target: Vector2i, speed: int) -> Vector2i:
	var delta := target - position
	return position + Vector2i(clampi(delta.x, -speed, speed), clampi(delta.y, -speed, speed))


func _prefix(side: String) -> String:
	return str(_side_config.get(side,{}).get("prefix",side.to_lower()))


func _home(side: String) -> Vector2i:
	return _side_config.get(side,{}).get("home",Vector2i.ZERO)


func _configure_match(canonical_match: Dictionary)->void:
	if not canonical_match.is_empty():_match=canonical_match.duplicate(true)
	if _match.is_empty():
		_match={"version":"strategic-match-v1","map_id":"borderlands","bounds":BOUNDS,"terrain":[],"sides":[
			{"side_id":"PLAYER","faction_id":"HUMAN","prefix":"player","home":Vector2i(400,600),"spawn_direction":Vector2i(1,0),"controller":"HUMAN"},
			{"side_id":"AI","faction_id":"HUMAN","prefix":"ai","home":Vector2i(2880,1480),"spawn_direction":Vector2i(-1,0),"controller":"AI"},
		]}
	_bounds=_match.get("bounds",BOUNDS)
	_sides.clear()
	_side_config.clear()
	for slot: Dictionary in _match.sides:
		_sides.append(str(slot.side_id))
		_side_config[slot.side_id]=slot.duplicate(true)
		var ground_radius:=0
		for id: String in Factions.units_for(slot.faction_id):
			var recipe: Dictionary=Units.UNITS[id]
			if recipe.movement_layer=="GROUND":ground_radius=maxi(ground_radius,FootprintR10.physical_radius(recipe))
		for archetype: String in Factions.heroes_for(slot.faction_id):ground_radius=maxi(ground_radius,int(stats_for_type("hero",archetype).radius))
		_side_config[slot.side_id]["ground_route_radius"]=ground_radius


func _faction(side: String)->String:
	return str(_side_config.get(side,{}).get("faction_id","HUMAN"))


static func _can_attack(unit: Dictionary,target: Dictionary)->bool:
	return not target.is_empty() and target.get("movement_layer","GROUND") in unit.get("attack_layers",["GROUND"])


static func _approach_point(origin: Vector2i,target: Vector2i,distance: int)->Vector2i:
	var delta:=Vector2(origin-target)
	if delta.is_zero_approx():delta=Vector2(-1,0)
	return target+Vector2i((delta.normalized()*distance).round())


func _refresh_route_geometry()->void:
	_route_obstacles.clear()
	for structure: Dictionary in _ordered_buildings():
		if not _is_worker(structure) and int(structure.get("hp",0))>0:
			_route_obstacles.append({"id":"structure:"+str(structure.id),"position":structure.position,"radius":int(structure.get("radius",32)),"blocks_ground":true})
	for prop: Dictionary in _terrain:
		_route_obstacles.append({"id":"terrain:"+str(prop.id),"position":prop.position,"radius":int(prop.radius),"blocks_ground":true})
	_route_obstacles.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return str(a.id)<str(b.id))
	var parts: Array[String]=[]
	for obstacle: Dictionary in _route_obstacles:parts.append("%s:%s:%d" % [obstacle.id,obstacle.position,int(obstacle.radius)])
	_route_geometry="|".join(parts)


func _navigation_destination(unit: Dictionary,goal: Vector2i,target:Dictionary={})->Vector2i:
	unit["steering_goal"]=goal
	if int(unit.hp)<=0 or goal==unit.position or _movement_controlled(unit):
		unit.erase("recovery_r11")
		return goal
	var recovery_goal:=_recovery_waypoint_r11(unit,goal,target)
	var waypoint:=recovery_goal if unit.movement_layer=="AIR" else _routed_point(unit,unit.position,recovery_goal,int(unit.radius))
	unit["steering_goal"]=waypoint
	# Visibility edges are straight, while axis clamping can cut their corners.
	# Request a true directional bounded stride, then retain swept body settling.
	# Separation alternatives still rank against the complete visible waypoint;
	# using only this short stride makes a blocked walker undo each sidestep.
	var delta:=Vector2(waypoint-unit.position)
	var step:=int(unit.get("movement_step",unit.speed))
	return waypoint if delta.length()<=step else Vector2i(unit.position)+Vector2i((delta.normalized()*step).round())


func _recovery_waypoint_r11(unit:Dictionary,goal:Vector2i,target:Dictionary)->Vector2i:
	if bool(unit.get("neutral",false)):return goal
	var army:Dictionary=_control_army_r12(unit)
	var direct:=str(unit.direct_intent)
	var state:Dictionary=unit.get("recovery_r11",{})
	var destination:Vector2i=unit.direct_destination if direct=="MOVE" else army.get("destination",goal)
	var order_changed:bool=state.is_empty() or state.get("direct")!=direct or state.get("intent")!=army.get("intent") or state.get("destination")!=destination or state.get("army")!=str(army.get("id",""))
	if order_changed:
		unit.erase("recovery_avoid_r11")
		state={"direct":direct,"intent":army.get("intent"),"destination":destination,"army":str(army.get("id","")),"route":[],"goal":goal,"next_attempt":-1,"attempts":0}
		unit["recovery_r11"]=state
	var route:Array=state.get("route",[])
	# Finish a local bypass when the same visible enemy merely paces nearby.
	# Re-aim after reaching it; repeatedly discarding the wall-corner path to
	# chase an enemy's small sideways motion traps the body at the wall again.
	var goal_slack:=160 if not target.is_empty() and str(state.get("target_id",""))==str(target.id) else 48
	if not route.is_empty() and (int(state.get("expires_tick",-1))<=_tick or state.get("geometry")!=_route_geometry or _distance_sq(state.goal,goal)>goal_slack*goal_slack):
		route.clear()
	if not route.is_empty() and not str(state.get("target_id","")).is_empty():
		var previous_target:Dictionary=_soldiers.get(str(state.target_id),_buildings.get(str(state.target_id),{}))
		if previous_target.is_empty() or not VisibilityR9.can_observe(previous_target,str(unit.side)) or int(previous_target.get("hp",0))<=0 or not target.is_empty() and str(target.id)!=str(state.target_id):route.clear()
	if not route.is_empty() and _tick>=int(state.get("blockers_check_tick",-1)):
		state.blockers_check_tick=_tick+8
		for fact:Dictionary in state.get("blockers",[]):
			var blocker:Dictionary=_soldiers.get(str(fact.id),_buildings.get(str(fact.id),{}))
			if blocker.is_empty() or not VisibilityR9.can_observe(blocker,str(unit.side)) or int(blocker.get("hp",0))<=0 or blocker.get("movement_layer","GROUND")!=fact.movement_layer or int(blocker.get("radius",0))!=int(fact.radius) or _distance_sq(blocker.position,fact.position)>16*16:
				route.clear();break
	# Reach the successive waypoints, even while the first step temporarily
	# increases distance from the final enemy. Do not discard a detour each
	# frame merely because the old static-only straight ray is unobstructed.
	while not route.is_empty() and _distance_sq(unit.position,route[0])<=64:route.pop_front()
	if route.is_empty():state.erase("blockers");state.erase("target_id")
	var waypoint:Vector2i=goal if route.is_empty() else route[0]
	var distance:=Vector2(unit.position).distance_to(Vector2(waypoint))
	if not state.has("progress_goal") or _distance_sq(state.progress_goal,waypoint)>64 or distance+4.0<float(state.get("best_distance",INF)):
		state.progress_goal=waypoint;state.best_distance=distance;state.progress_tick=_tick
	# Keep the established short-stall scheduler. A separate conservative
	# watchdog catches a moving goal endlessly refreshing it without genuine
	# approach. Its fixed reference/best distance changes only on body progress;
	# it never interrupts a committed bypass or triggers an early-army replan.
	if not route.is_empty() or not state.has("motion_goal_r14"):
		state.motion_goal_r14=waypoint;state.motion_best_r14=distance;state.motion_tick_r14=_tick
	else:
		var actual_distance:=Vector2(unit.position).distance_to(Vector2(state.motion_goal_r14))
		if actual_distance<=8.0:
			state.motion_goal_r14=waypoint;state.motion_best_r14=distance;state.motion_tick_r14=_tick
		elif actual_distance+4.0<float(state.motion_best_r14):
			state.motion_best_r14=actual_distance;state.motion_tick_r14=_tick
	var stalled_motion:=route.is_empty() and _tick-int(state.motion_tick_r14)>=RECOVERY_PROGRESS_WATCHDOG_R14
	var stagger:=posmod(str(unit.id).hash(),7)
	if (not stalled_motion and _tick-int(state.get("progress_tick",_tick))<RECOVERY_STALL_TICKS_R11+stagger) or _tick<int(state.next_attempt):return waypoint
	# At most one recovery query per tick, within the existing two-plan global
	# military budget. A failed query backs off; it cannot starve every later ID
	# or turn congestion into whole-army replanning each simulation frame.
	_recovery_waiting_r11=true;_recovery_pending_r11=true
	if str(unit.id)<=_recovery_cursor_r11 or _recovery_plans_r11>=1 or _route_plans>=MAX_ROUTE_PLANS_PER_TICK:return waypoint
	_recovery_plans_r11+=1;_route_plans+=1
	_recovery_cursor_r11=str(unit.id)
	state.attempts=int(state.attempts)+1
	state.next_attempt=_tick+32+stagger
	state.progress_tick=_tick;state.best_distance=distance;state.progress_position=unit.position;state.progress_goal=waypoint
	state.motion_goal_r14=waypoint;state.motion_best_r14=distance;state.motion_tick_r14=_tick
	route.clear()
	# Preserve an existing legal pursuit route. Only an occupied endpoint
	# requires alternate attack positions; treating every chase as a new edge
	# placement unnecessarily changed crowd convergence in the Arena regression.
	var attack_target:Dictionary=target if not target.is_empty() and (direct=="ATTACK" or direct.is_empty() and army.get("intent") in ["ATTACK_MOVE","FOCUS","ATTACK_BASE"]) else {}
	var plan:Dictionary=MovementRecoveryR11.plan(unit,goal,str(target.get("id","")),_targeting.recovery_neighbours_r11(unit),_bounds,[] if unit.movement_layer=="AIR" else _route_obstacles,attack_target)
	if bool(plan.get("accepted",false)):
		state.route=plan.route
		state.blockers=plan.blockers;state.blockers_check_tick=_tick+8
		state.target_id=str(target.get("id",""))
		state.goal=goal;state.geometry=_route_geometry;state.expires_tick=_tick+200
		var next:Vector2i=plan.route[0]
		state.progress_goal=next;state.best_distance=Vector2(unit.position).distance_to(Vector2(next))
		return next
	# Only autonomous pursuit may choose a different enemy. Explicit MOVE,
	# retreat, HOLD and a named UNIT_ATTACK keep their exact order/destination.
	# A disabled hero auto-attack never gets new acquisition from this branch.
	if direct.is_empty() and army.get("intent") in ["ATTACK_MOVE","FOCUS","ATTACK_BASE"] and not target.is_empty() and not (_hero_data.has(unit.id) and not bool(_hero_data[unit.id].auto_attack)):
		if army.get("intent")!="ATTACK_BASE" or str(target.id)!=str(army.get("target_base_id","")):
			var avoid:Dictionary=unit.get("recovery_avoid_r11",{})
			for id:Variant in avoid.keys():
				if int(avoid[id])<=_tick:avoid.erase(id)
			if avoid.size()>=8:avoid.erase(avoid.keys()[0])
			avoid[str(target.id)]=_tick+RECOVERY_TARGET_TICKS_R11
			unit["recovery_avoid_r11"]=avoid
			_targeting.forget_recovery_target_r11(str(unit.id))
			unit["target_id"]=""
	return goal


func _safe_anchor_stride(origin: Vector2i,target: Vector2i,step: int,radius: int)->Vector2i:
	var delta:=Vector2(target-origin)
	var preferred:=target if delta.length()<=step else origin+Vector2i((delta.normalized()*step).round())
	if Navigation.segment_clear(origin,preferred,radius,_bounds,_route_obstacles):return preferred
	# Integer rounding can drift a valid straight visibility edge into a
	# circle's inflated halo. Try at most 24 bounded compass strides; choose
	# only a genuinely clear swept segment that progresses to the visible
	# waypoint. No teleport, collision exemption or arbitrary escape is used.
	var best:=origin
	var remaining:=_distance_sq(origin,target)
	for distance: int in [step,maxi(1,step/2),1]:
		for direction: Vector2i in [Vector2i(-1,-1),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,-1),Vector2i(0,1),Vector2i(1,-1),Vector2i(1,0),Vector2i(1,1)]:
			var candidate:=origin+Vector2i((Vector2(direction).normalized()*distance).round())
			var value:=_distance_sq(candidate,target)
			if value<remaining and Navigation.segment_clear(origin,candidate,radius,_bounds,_route_obstacles):
				remaining=value
				best=candidate
	return best


func _routed_point(body: Dictionary,origin: Vector2i,goal: Vector2i,radius: int)->Vector2i:
	# Straight paths are cheap. Complex paths are cached and at most two bounded
	# visibility searches occur per military tick, regardless of army size.
	if origin==goal:return goal
	if _m96_route_clear(origin,goal,radius):
		body.route=[]
		body.route_target=goal
		body.route_geometry=_route_geometry
		body["route_radius"]=radius
		body["route_unreachable"]=false
		return goal
	var invalid: bool=body.get("route_geometry","")!=_route_geometry or int(body.get("route_radius",0))!=radius or _distance_sq(body.get("route_target",origin),goal)>32*32 or body.get("route",[]).is_empty() and (not bool(body.get("route_unreachable",false)) or _tick>=int(body.get("route_retry_tick",0)))
	if invalid:
		var route_limit:=MAX_ROUTE_PLANS_PER_TICK-(1 if _recovery_reserve_r11 and _recovery_plans_r11==0 else 0)
		if _route_plans>=route_limit:return origin
		_route_plans+=1
		body.route=Navigation.find_path(origin,goal,radius,_bounds,_route_obstacles)
		body.route_target=goal
		body.route_geometry=_route_geometry
		body["route_radius"]=radius
		body["route_unreachable"]=body.route.is_empty()
		body["route_retry_tick"]=_tick+20
	var route: Array=body.get("route",[])
	while not route.is_empty() and _distance_sq(origin,route[0])<=4:route.pop_front()
	return origin if route.is_empty() else Vector2i(route[0])


func _m96_begin_route_batch() -> void:
	assert(not _m96_route_batch_active and _m96_route_visibility == null)
	_m96_route_batch_active = true
	_m96_route_work = {}


func _m96_end_route_batch() -> void:
	if _m96_route_visibility != null:
		_m96_route_work = _m96_route_visibility.diagnostics()
		_m96_route_visibility.clear()
	_m96_route_visibility = null
	_m96_route_batch_active = false


func _m96_route_clear(origin: Vector2i, goal: Vector2i, radius: int) -> bool:
	if not _m96_route_batch_active:
		return Navigation.segment_clear(origin,goal,radius,_bounds,_route_obstacles)
	if _m96_route_visibility == null:
		_m96_route_visibility = RouteVisibilityM96.new(_route_obstacles)
	return _m96_route_visibility.segment_clear(origin,goal,radius,_bounds)


func _add_splash_hits(unit: Dictionary,target: Dictionary,damage: Dictionary,killers: Dictionary,hits: Array)->void:
	var radius:=int(unit.get("splash_radius",0))
	var amount:=int(unit.get("splash_damage",0))
	var layers: Array=unit.get("splash_layers",[])
	if radius<=0 or amount<=0 or target.get("movement_layer","GROUND") not in layers:return
	var extra_limit:=maxi(0,int(unit.get("splash_max_targets",1))-1)
	if extra_limit==0:return
	var candidates: Array[Dictionary]=[]
	for enemy: Dictionary in _ordered_units():
		if enemy.id==target.id or enemy.side==unit.side or int(enemy.hp)<=0 or enemy.movement_layer not in layers or _distance_sq(enemy.position,target.position)>radius*radius:continue
		candidates.append(enemy)
	for worker: Dictionary in _ordered_buildings():
		if not _is_worker(worker) or worker.id==target.id or worker.side==unit.side or int(worker.get("hp",0))<=0 or "GROUND" not in layers or _distance_sq(worker.position,target.position)>radius*radius:continue
		candidates.append(worker)
	candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var aa:=_distance_sq(a.position,target.position)
		var bb:=_distance_sq(b.position,target.position)
		return str(a.id)<str(b.id) if aa==bb else aa<bb)
	for index: int in range(mini(extra_limit,candidates.size())):
		var enemy: Dictionary=candidates[index]
		if _is_worker(enemy):
			hits.append({"worker_id":enemy.id,"damage":DamageRules.resolve(amount,str(unit.attack_type),enemy),"side":unit.side,"unit_id":unit.id})
			continue
		# A secondary basic hit has the same defensive semantics as the primary:
		# innate basic resistance, type/armor/MR, then one shield absorption.
		# Do not call on_basic or splash recursively for secondary recipients.
		var resolved:=_resolve_damage(amount,str(unit.attack_type),enemy,unit,true,{"id":"BASIC","category":"BASIC"})
		_deal_body_damage_r4(enemy,unit,resolved,str(unit.attack_type),{"id":"BASIC","category":"BASIC"},damage,killers,true)
		if not killers.has(enemy.id):killers[enemy.id]=unit.id


static func _accept(extra: Dictionary = {}) -> Dictionary:
	var result := {"accepted": true, "ok": true, "error": "", "reason": "", "code": "OK"}
	result.merge(extra)
	return result


static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "ok": false, "error": reason, "reason": reason, "code": reason}
