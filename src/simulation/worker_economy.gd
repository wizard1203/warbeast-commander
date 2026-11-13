class_name WorkerEconomy
extends RefCounted
## Deterministic graybox economy. The commander changes aggregate targets and a
## shared worker/warband/building queue; individual movement, cargo, and
## identities stay local. The stock ledger is owned here for every recipe.

const WarbandCatalog = preload("res://src/simulation/warband_catalog.gd")
const CampCatalog = preload("res://src/simulation/camp_catalog.gd")

const ROLE_FOOD := "FOOD"
const ROLE_MATERIAL := "MATERIAL"
const ROLE_CONSTRUCTION_REPAIR := "CONSTRUCTION_REPAIR"
const ROLE_RESERVE := "RESERVE"
const ASSIGNABLE_ROLES := [ROLE_FOOD, ROLE_MATERIAL, ROLE_CONSTRUCTION_REPAIR]
const ALL_ROLES := [ROLE_FOOD, ROLE_MATERIAL, ROLE_CONSTRUCTION_REPAIR, ROLE_RESERVE]

const INITIAL_WORKER_COUNT := 6
const MAX_WORKER_COUNT := 12
const WORKER_RADIUS := 8
const WORKER_MOVE_STEP := 6
const GATHER_TICKS := 12
const MAX_EVENTS := 24

const WORKER_RECIPE_ID := "recipe:worker:v1"
const WORKER_RECIPE_FOOD_COST := 2
const WORKER_RECIPE_MATERIAL_COST := 1
const WORKER_RECIPE_DURATION_TICKS := 80
const MAX_UNRESOLVED_QUEUE_ENTRIES := 3
const PRODUCTION_OUTLET := Vector2i(96, 360)

const QUEUE_WAITING := "WAITING"
const QUEUE_BLOCKED_CAPACITY := "BLOCKED_CAPACITY"
const QUEUE_RUNNING := "RUNNING"
const QUEUE_BLOCKED_OUTLET := "BLOCKED_OUTLET"
const QUEUE_BLOCKED_DEPLOYMENT := "BLOCKED_DEPLOYMENT"
const QUEUE_BLOCKED_BUILDERS := "BLOCKED_BUILDERS"
const KIND_WORKER := "WORKER"
const KIND_WARBAND := "WARBAND"
const KIND_BUILDING := "BUILDING"
const COST_RESERVED := "RESERVED"
const COST_COMMITTED_NO_REFUND := "COMMITTED_NO_REFUND"

const STATE_TRAVEL_TO_SOURCE := "TRAVEL_TO_SOURCE"
const STATE_GATHERING := "GATHERING"
const STATE_TRAVEL_TO_DEPOT := "TRAVEL_TO_DEPOT"
const STATE_TRAVEL_TO_MUSTER := "TRAVEL_TO_MUSTER"
const STATE_AT_MUSTER := "AT_MUSTER"
const STATE_TRAVEL_TO_CONSTRUCTION := "TRAVEL_TO_CONSTRUCTION"
const STATE_CONSTRUCTING := "CONSTRUCTING"
const STATE_TRAVEL_TO_RESERVE := "TRAVEL_TO_RESERVE"
const STATE_RESERVE := "RESERVE"

var _tick := 0
var _targets: Dictionary = {}
var _stock: Dictionary = {}
var _sites: Dictionary = {}
var _workers: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _queue: Array[Dictionary] = []
var _next_queue_serial := 1
var _next_worker_index := INITIAL_WORKER_COUNT
var _workshop_built := false
var _workshop_completed_tick := -1
var _origin_offset := Vector2i.ZERO


func _init(origin_offset: Vector2i = Vector2i.ZERO) -> void:
	_origin_offset = origin_offset
	reset()


func reset() -> void:
	_tick = 0
	_targets = {
		ROLE_FOOD: 2,
		ROLE_MATERIAL: 2,
		ROLE_CONSTRUCTION_REPAIR: 1,
	}
	_stock = {ROLE_FOOD: 0, ROLE_MATERIAL: 0}
	_sites = {
		"DEPOT": Vector2i(140, 360) + _origin_offset,
		ROLE_FOOD: Vector2i(145, 150) + _origin_offset,
		ROLE_MATERIAL: Vector2i(145, 570) + _origin_offset,
		ROLE_CONSTRUCTION_REPAIR: Vector2i(115, 450) + _origin_offset,
	}
	_workers.clear()
	_events.clear()
	_queue.clear()
	_next_queue_serial = 1
	_next_worker_index = INITIAL_WORKER_COUNT
	_workshop_built = false
	_workshop_completed_tick = -1
	for worker_index: int in range(INITIAL_WORKER_COUNT):
		_workers.append({
			"id": "worker_%02d" % worker_index,
			"index": worker_index,
			"position": _site_for_worker("DEPOT", worker_index),
			"role": ROLE_RESERVE,
			"desired_role": ROLE_RESERVE,
			"state": STATE_RESERVE,
			"cargo_type": "",
			"cargo_amount": 0,
			"gather_ticks_remaining": 0,
		})
	# Seed the canonical M1 lineup without changing its worker identities.
	for worker_index: int in range(INITIAL_WORKER_COUNT):
		var worker: Dictionary = _workers[worker_index]
		var initial_role := ROLE_RESERVE
		if worker_index < 2:
			initial_role = ROLE_FOOD
		elif worker_index < 4:
			initial_role = ROLE_MATERIAL
		elif worker_index == 4:
			initial_role = ROLE_CONSTRUCTION_REPAIR
		worker["desired_role"] = initial_role
		if initial_role != ROLE_RESERVE:
			_activate_role(worker, initial_role)


func apply_target_deltas(changes: Array) -> Dictionary:
	# Validate the whole transaction before mutating anything. A paired transfer is
	# allowed when reserve is zero; a standalone increment in that state is not.
	if changes.is_empty() or changes.size() > 2:
		return _rejection("INVALID_CHANGE_COUNT")
	var next_targets: Dictionary = _targets.duplicate()
	var seen_roles := {}
	var delta_sum := 0
	for change: Variant in changes:
		if typeof(change) != TYPE_DICTIONARY:
			return _rejection("INVALID_CHANGE")
		var entry: Dictionary = change
		if entry.size() != 2 or not entry.has("role") or not entry.has("delta"):
			return _rejection("INVALID_CHANGE_FIELDS")
		if typeof(entry["role"]) != TYPE_STRING or typeof(entry["delta"]) != TYPE_INT:
			return _rejection("INVALID_CHANGE_VALUE")
		var role: String = entry["role"]
		var delta: int = entry["delta"]
		if role not in ASSIGNABLE_ROLES or delta not in [-1, 1] or seen_roles.has(role):
			return _rejection("INVALID_ROLE_DELTA")
		seen_roles[role] = true
		next_targets[role] = int(next_targets[role]) + delta
		delta_sum += delta
	if changes.size() == 2 and delta_sum != 0:
		return _rejection("INVALID_PAIRED_TRANSFER")
	var assigned := 0
	for role: String in ASSIGNABLE_ROLES:
		if int(next_targets[role]) < 0:
			return _rejection("NEGATIVE_TARGET")
		assigned += int(next_targets[role])
	if assigned > _workers.size():
		return _rejection("NO_RESERVE_WORKER")

	_targets = next_targets
	for change: Dictionary in changes:
		_record_event("TARGET_CHANGED", "", str(change["role"]), int(change["delta"]))
	_reconcile_assignments()
	return {"accepted": true, "reason": ""}


func apply_production_change(change: Dictionary) -> Dictionary:
	if typeof(change.get("operation")) != TYPE_STRING:
		return _rejection("INVALID_SCHEMA")
	var operation: String = change["operation"]
	match operation:
		"ENQUEUE":
			if typeof(change.get("recipe_id")) != TYPE_STRING:
				return _rejection("INVALID_SCHEMA")
			var recipe_id: String = change["recipe_id"]
			var recipe := _recipe_for_id(recipe_id)
			if recipe.is_empty():
				return _rejection("INVALID_SCHEMA")
			var kind: String = recipe["kind"]
			var expected_fields: Array[String] = ["operation", "recipe_id", "quantity"]
			if kind == KIND_BUILDING:
				expected_fields.append("slot_id")
			if not _has_exact_fields(change, expected_fields):
				return _rejection("INVALID_SCHEMA")
			if typeof(change["quantity"]) != TYPE_INT or int(change["quantity"]) != 1:
				return _rejection("INVALID_SCHEMA")
			if kind == KIND_BUILDING:
				if typeof(change["slot_id"]) != TYPE_STRING or change["slot_id"] != CampCatalog.WORKSHOP_SLOT_ID:
					return _rejection("INVALID_SCHEMA")
				if _workshop_built or _workshop_entry_index() >= 0:
					return _rejection("SLOT_OCCUPIED")
			if recipe_id == WORKER_RECIPE_ID and _workers.size() >= MAX_WORKER_COUNT:
				return _rejection("POPULATION_CAP")
			if _queue.size() >= MAX_UNRESOLVED_QUEUE_ENTRIES:
				return _rejection("QUEUE_FULL")
			var available := _available_stock()
			var cost: Dictionary = recipe["cost"]
			if int(available[ROLE_FOOD]) < int(cost[ROLE_FOOD]) or int(available[ROLE_MATERIAL]) < int(cost[ROLE_MATERIAL]):
				return _rejection("INSUFFICIENT_AVAILABLE_STOCK")
			var entry_id := "queue_%04d" % _next_queue_serial
			_next_queue_serial += 1
			_queue.append({
				"queue_entry_id": entry_id,
				"recipe_id": recipe_id,
				"kind": kind,
				"slot_id": recipe.get("slot_id", ""),
				"type_id": recipe["type_id"],
				"unit_type": recipe["unit_type"],
				"label": recipe["label"],
				"display_name": recipe["display_name"],
				"cost": cost.duplicate(),
				"duration_ticks": recipe["duration_ticks"],
				"member_count": recipe["member_count"],
				"quantity": 1,
				"state": QUEUE_WAITING,
				"remaining_ticks": recipe["duration_ticks"],
				"progress_remainder": 0,
				"blocked_reason": "",
				"cost_state": COST_RESERVED,
				"population_slot_reserved": false,
				"accepted_tick": _tick,
				"started_tick": -1,
			})
			_record_event("PRODUCTION_ENQUEUED", "", "", 1, entry_id)
			return {"accepted": true, "reason": "", "queue_entry_id": entry_id}
		"CANCEL":
			if not _has_exact_fields(change, ["operation", "queue_entry_id"]):
				return _rejection("INVALID_SCHEMA")
			if typeof(change["queue_entry_id"]) != TYPE_STRING:
				return _rejection("INVALID_SCHEMA")
			var cancel_index := _find_entry_index(change["queue_entry_id"])
			if cancel_index < 0:
				return _rejection("UNKNOWN_QUEUE_ENTRY")
			var cancelled: Dictionary = _queue[cancel_index]
			var was_running: bool = cancelled["cost_state"] == COST_COMMITTED_NO_REFUND
			_queue.remove_at(cancel_index)
			if cancelled["kind"] == KIND_BUILDING:
				_redirect_construction_workers()
			_record_event("PRODUCTION_CANCELLED_STARTED" if was_running else "PRODUCTION_CANCELLED_QUEUED", "", "", 1, cancelled["queue_entry_id"])
			return {"accepted": true, "reason": ""}
		"REORDER":
			if not _has_exact_fields(change, ["operation", "queue_entry_id", "target_index"]):
				return _rejection("INVALID_SCHEMA")
			if typeof(change["queue_entry_id"]) != TYPE_STRING or typeof(change["target_index"]) != TYPE_INT:
				return _rejection("INVALID_SCHEMA")
			var reorder_index := _find_entry_index(change["queue_entry_id"])
			if reorder_index < 0:
				return _rejection("UNKNOWN_QUEUE_ENTRY")
			var reordered: Dictionary = _queue[reorder_index]
			if reordered["cost_state"] != COST_RESERVED:
				return _rejection("ENTRY_ALREADY_STARTED")
			var active_entry: Dictionary = {}
			var waiting: Array[Dictionary] = []
			for entry: Dictionary in _queue:
				if entry["cost_state"] == COST_RESERVED:
					waiting.append(entry)
				else:
					active_entry = entry
			var target_index: int = change["target_index"]
			if target_index < 0 or target_index >= waiting.size():
				return _rejection("INVALID_TARGET_INDEX")
			var from_index := -1
			for index: int in range(waiting.size()):
				if waiting[index]["queue_entry_id"] == reordered["queue_entry_id"]:
					from_index = index
					break
			if from_index == target_index:
				return {"accepted": true, "reason": ""}
			waiting.remove_at(from_index)
			waiting.insert(target_index, reordered)
			_queue.clear()
			if not active_entry.is_empty():
				_queue.append(active_entry)
			_queue.append_array(waiting)
			_record_event("PRODUCTION_REORDERED", "", "", target_index, reordered["queue_entry_id"])
			return {"accepted": true, "reason": ""}
		_:
			return _rejection("INVALID_SCHEMA")


func get_ready_warband_entry() -> Dictionary:
	# The host owns the physical eight-slot placement gate. This is a detached,
	# read-only proposal; no soldier or warband identity exists until completion.
	var active_index := _active_entry_index()
	if active_index < 0:
		return {}
	var entry: Dictionary = _queue[active_index]
	if entry["kind"] != KIND_WARBAND or int(entry["remaining_ticks"]) != 0:
		return {}
	if entry["state"] != QUEUE_BLOCKED_DEPLOYMENT:
		return {}
	return entry.duplicate(true)


func complete_warband_deployment(queue_entry_id: String) -> Dictionary:
	var active_index := _active_entry_index()
	if active_index < 0:
		return _rejection("ENTRY_NOT_READY")
	var entry: Dictionary = _queue[active_index]
	if entry["queue_entry_id"] != queue_entry_id:
		return _rejection("ENTRY_NOT_READY")
	if entry["kind"] != KIND_WARBAND:
		return _rejection("NOT_WARBAND_ENTRY")
	if int(entry["remaining_ticks"]) != 0 or entry["state"] != QUEUE_BLOCKED_DEPLOYMENT:
		return _rejection("ENTRY_NOT_READY")
	_queue.remove_at(active_index)
	_record_event("WARBAND_DEPLOYED", "", "", int(entry["member_count"]), queue_entry_id)
	return {
		"accepted": true,
		"reason": "",
		"queue_entry_id": queue_entry_id,
		"recipe_id": entry["recipe_id"],
		"type_id": entry["type_id"],
		"unit_type": entry["unit_type"],
		"display_name": entry["display_name"],
		"member_count": entry["member_count"],
	}


func get_movement_intents() -> Dictionary:
	# Pure read: callers may combine these proposals with soldier intentions in a
	# shared occupancy solver before calling advance_tick(resolved_positions).
	var intents := {}
	for worker: Dictionary in _workers:
		var destination: Vector2i = _destination_for(worker)
		intents[worker["id"]] = _move_toward(worker["position"], destination)
	return intents


func get_static_bodies() -> Array[Dictionary]:
	return [{
		"id": CampCatalog.FOUNDATION_ID,
		"position": CampCatalog.WORKSHOP_POSITION + _origin_offset,
		"desired": CampCatalog.WORKSHOP_POSITION + _origin_offset,
		"radius": CampCatalog.FOUNDATION_RADIUS,
		"active": true,
		"max_step": 0,
	}]


func advance_tick(resolved_positions: Dictionary = {}, external_bodies: Array[Dictionary] = []) -> void:
	var proposed_positions := get_movement_intents()
	_tick += 1
	for worker: Dictionary in _workers:
		var worker_id: String = worker["id"]
		var next_position: Variant = resolved_positions.get(worker_id, proposed_positions[worker_id])
		if typeof(next_position) == TYPE_VECTOR2I:
			worker["position"] = next_position
		_process_worker_state(worker)
	_advance_production(external_bodies)


func get_snapshot() -> Dictionary:
	var target_counts: Dictionary = _targets.duplicate()
	target_counts[ROLE_RESERVE] = _workers.size() - _assigned_target_count()
	var actual_counts := {
		ROLE_FOOD: 0,
		ROLE_MATERIAL: 0,
		ROLE_CONSTRUCTION_REPAIR: 0,
		ROLE_RESERVE: 0,
	}
	var worker_snapshots: Array[Dictionary] = []
	for worker: Dictionary in _workers:
		actual_counts[worker["role"]] = int(actual_counts[worker["role"]]) + 1
		worker_snapshots.append(worker.duplicate(true))
	return {
		"tick": _tick,
		"population": _workers.size(),
		"targets": target_counts,
		"actual": actual_counts,
		"stock": _stock.duplicate(),
		"workers": worker_snapshots,
		"sites": _sites.duplicate(),
		"events": _events.duplicate(true),
		"production": _production_snapshot(),
		"construction": _construction_snapshot(),
	}


func get_state_lines() -> PackedStringArray:
	var snapshot := get_snapshot()
	var targets: Dictionary = snapshot["targets"]
	var actual: Dictionary = snapshot["actual"]
	var lines := PackedStringArray()
	lines.append("EC|%d|%d|%d|%d|%d|%d|%d" % [
		_tick, int(_stock[ROLE_FOOD]), int(_stock[ROLE_MATERIAL]),
		_workers.size(), _events.size(), _next_queue_serial, _next_worker_index,
	])
	for role: String in ALL_ROLES:
		lines.append("ET|%s|%d|%d" % [role, int(targets[role]), int(actual[role])])
	for site_name: String in ["DEPOT", ROLE_FOOD, ROLE_MATERIAL, ROLE_CONSTRUCTION_REPAIR]:
		var site: Vector2i = _sites[site_name]
		lines.append("ES|%s|%d|%d" % [site_name, site.x, site.y])
	for worker: Dictionary in _workers:
		var position: Vector2i = worker["position"]
		lines.append("EW|%s|%d|%d|%s|%s|%s|%s|%d|%d" % [
			worker["id"], position.x, position.y, worker["role"],
			worker["desired_role"], worker["state"], worker["cargo_type"],
			worker["cargo_amount"], worker["gather_ticks_remaining"],
		])
	var production: Dictionary = snapshot["production"]
	var reserved: Dictionary = production["reserved"]
	var available: Dictionary = production["available"]
	var outlet: Vector2i = production["outlet"]
	lines.append("EP|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [
		production["recipe_id"], production["duration_ticks"], production["capacity"],
		production["slot_reservations"], production["population_cap"],
		int(production["cost"][ROLE_FOOD]), int(production["cost"][ROLE_MATERIAL]),
		int(reserved[ROLE_FOOD]), int(reserved[ROLE_MATERIAL]),
		int(available[ROLE_FOOD]), int(available[ROLE_MATERIAL]), outlet.x,
	])
	lines.append("EO|%d" % outlet.y)
	var construction: Dictionary = snapshot["construction"]
	var foundation: Vector2i = construction["position"]
	lines.append("ECAMP|%s|%s|%d|%d|%d|%s|%s|%s|%d|%d|%d|%d|%d|%d|%d" % [
		construction["slot_id"], construction["recipe_id"], foundation.x, foundation.y,
		construction["radius"], construction["state"], construction["queue_entry_id"],
		construction["cost_state"], construction["work_completed"], construction["work_required"],
		construction["builders_on_site"], construction["eta_ticks"], construction["completed_tick"],
		construction["production_rate_numerator"], construction["production_rate_denominator"],
	])
	for entry: Dictionary in _queue:
		lines.append("EQ|%s|%s|%d|%s|%d|%s|%s|%d|%d|%d" % [
			entry["queue_entry_id"], entry["recipe_id"], entry["quantity"],
			entry["state"], entry["remaining_ticks"], entry["blocked_reason"],
			entry["cost_state"], int(entry["population_slot_reserved"]),
			entry["accepted_tick"], entry["started_tick"],
		])
		var entry_cost: Dictionary = entry["cost"]
		lines.append("EQC|%s|%s|%d|%d|%d|%d" % [
			entry["queue_entry_id"], entry["type_id"],
			int(entry_cost[ROLE_FOOD]), int(entry_cost[ROLE_MATERIAL]),
			int(entry["duration_ticks"]), int(entry["member_count"]),
		])
		lines.append("EQK|%s|%s|%s|%d" % [
			entry["queue_entry_id"], entry["kind"], entry["slot_id"], entry["progress_remainder"],
		])
	for event: Dictionary in _events:
		lines.append("EE|%d|%s|%s|%s|%d|%s" % [
			event["tick"], event["type"], event["worker_id"],
			event["resource"], event["amount"], event["queue_entry_id"],
		])
	return lines


func _reconcile_assignments() -> void:
	# Keep every desired assignment that the new totals still need. Only surplus
	# workers move; this avoids a full roster cascade for a single +1 command.
	var wanted: Dictionary = _targets.duplicate()
	wanted[ROLE_RESERVE] = _workers.size() - _assigned_target_count()
	var desired_counts := {}
	for role: String in ALL_ROLES:
		desired_counts[role] = 0
	for worker: Dictionary in _workers:
		desired_counts[worker["desired_role"]] = int(desired_counts[worker["desired_role"]]) + 1
	var surplus := {}
	for role: String in ALL_ROLES:
		var excess: int = int(desired_counts[role]) - int(wanted[role])
		var candidates: Array[Dictionary] = []
		for worker_index: int in range(_workers.size() - 1, -1, -1):
			var worker: Dictionary = _workers[worker_index]
			if worker["desired_role"] == role and candidates.size() < excess:
				candidates.append(worker)
		surplus[role] = candidates
	for target_role: String in ALL_ROLES:
		var deficit: int = int(wanted[target_role]) - int(desired_counts[target_role])
		for _slot: int in range(maxi(0, deficit)):
			var source_role := ""
			if not (surplus[ROLE_RESERVE] as Array).is_empty():
				source_role = ROLE_RESERVE
			else:
				for candidate_role: String in ASSIGNABLE_ROLES:
					if not (surplus[candidate_role] as Array).is_empty():
						source_role = candidate_role
						break
			if source_role.is_empty():
				push_error("Worker target reconciliation has no surplus source.")
				return
			var selected: Dictionary = (surplus[source_role] as Array).pop_front()
			selected["desired_role"] = target_role
			if selected["role"] != target_role and int(selected["cargo_amount"]) == 0:
				_activate_role(selected, target_role)


func _activate_role(worker: Dictionary, new_role: String) -> void:
	worker["role"] = new_role
	worker["gather_ticks_remaining"] = 0
	match new_role:
		ROLE_FOOD, ROLE_MATERIAL:
			worker["state"] = STATE_TRAVEL_TO_SOURCE
		ROLE_CONSTRUCTION_REPAIR:
			worker["state"] = STATE_TRAVEL_TO_CONSTRUCTION if _active_building_entry_index() >= 0 else STATE_TRAVEL_TO_MUSTER
		_:
			worker["state"] = STATE_TRAVEL_TO_RESERVE
	if worker["position"] == _destination_for(worker):
		match new_role:
			ROLE_FOOD, ROLE_MATERIAL:
				worker["state"] = STATE_GATHERING
				worker["gather_ticks_remaining"] = GATHER_TICKS
			ROLE_CONSTRUCTION_REPAIR:
				worker["state"] = STATE_CONSTRUCTING if _active_building_entry_index() >= 0 else STATE_AT_MUSTER
			_:
				worker["state"] = STATE_RESERVE


func _process_worker_state(worker: Dictionary) -> void:
	match worker["state"]:
		STATE_TRAVEL_TO_SOURCE:
			if worker["position"] == _destination_for(worker):
				worker["state"] = STATE_GATHERING
				worker["gather_ticks_remaining"] = GATHER_TICKS
		STATE_GATHERING:
			worker["gather_ticks_remaining"] = maxi(0, int(worker["gather_ticks_remaining"]) - 1)
			if int(worker["gather_ticks_remaining"]) == 0:
				worker["cargo_type"] = worker["role"]
				worker["cargo_amount"] = 1
				worker["state"] = STATE_TRAVEL_TO_DEPOT
				_record_event("GATHERED", worker["id"], worker["cargo_type"], 1)
		STATE_TRAVEL_TO_DEPOT:
			if worker["position"] == _site_for_worker("DEPOT", worker["index"]):
				var delivered_type: String = worker["cargo_type"]
				if delivered_type in [ROLE_FOOD, ROLE_MATERIAL] and int(worker["cargo_amount"]) == 1:
					_stock[delivered_type] = int(_stock[delivered_type]) + 1
					_record_event("DELIVERED", worker["id"], delivered_type, 1)
				worker["cargo_type"] = ""
				worker["cargo_amount"] = 0
				if worker["role"] != worker["desired_role"]:
					_activate_role(worker, worker["desired_role"])
				else:
					worker["state"] = STATE_TRAVEL_TO_SOURCE
		STATE_TRAVEL_TO_MUSTER:
			if worker["position"] == _destination_for(worker):
				worker["state"] = STATE_AT_MUSTER
		STATE_TRAVEL_TO_CONSTRUCTION:
			if worker["position"] == _destination_for(worker):
				worker["state"] = STATE_CONSTRUCTING
		STATE_TRAVEL_TO_RESERVE:
			if worker["position"] == _destination_for(worker):
				worker["state"] = STATE_RESERVE


func _destination_for(worker: Dictionary) -> Vector2i:
	if worker["state"] in [STATE_TRAVEL_TO_CONSTRUCTION, STATE_CONSTRUCTING]:
		return CampCatalog.work_position(int(worker["index"])) + _origin_offset
	var site_name: String = worker["role"]
	match worker["state"]:
		STATE_TRAVEL_TO_DEPOT, STATE_TRAVEL_TO_RESERVE, STATE_RESERVE:
			site_name = "DEPOT"
		STATE_TRAVEL_TO_MUSTER, STATE_AT_MUSTER:
			site_name = ROLE_CONSTRUCTION_REPAIR
		STATE_TRAVEL_TO_SOURCE, STATE_GATHERING:
			site_name = worker["role"]
	return _site_for_worker(site_name, int(worker["index"]))


func _site_for_worker(site_name: String, worker_index: int) -> Vector2i:
	var center: Vector2i = _sites[site_name]
	var offsets: Array[Vector2i] = [
		Vector2i(-18, -18), Vector2i(18, -18),
		Vector2i(-18, 18), Vector2i(18, 18),
		Vector2i(0, -36), Vector2i(0, 36),
		Vector2i(0, -60), Vector2i(0, 60),
		Vector2i(-18, -54), Vector2i(18, -54),
		Vector2i(-18, 54), Vector2i(18, 54),
	]
	return center + offsets[worker_index]


func _advance_production(external_bodies: Array[Dictionary]) -> void:
	var active_index := _active_entry_index()
	if active_index >= 0:
		var active: Dictionary = _queue[active_index]
		if active["kind"] == KIND_BUILDING:
			_advance_construction(active_index)
			return
		if int(active["remaining_ticks"]) > 0:
			var quarter_work: int = int(active["progress_remainder"]) + _production_rate_numerator()
			active["remaining_ticks"] = maxi(0, int(active["remaining_ticks"]) - int(quarter_work / 4))
			active["progress_remainder"] = quarter_work % 4 if int(active["remaining_ticks"]) > 0 else 0
		if int(active["remaining_ticks"]) == 0:
			if active["kind"] == KIND_WORKER:
				if _outlet_is_clear(external_bodies):
					_spawn_from_entry(active_index)
				else:
					active["state"] = QUEUE_BLOCKED_OUTLET
					active["blocked_reason"] = QUEUE_BLOCKED_OUTLET
			else:
				active["state"] = QUEUE_BLOCKED_DEPLOYMENT
				active["blocked_reason"] = QUEUE_BLOCKED_DEPLOYMENT
		return
	if _queue.is_empty():
		return
	var head: Dictionary = _queue[0]
	if head["cost_state"] != COST_RESERVED:
		return
	if head["recipe_id"] == WORKER_RECIPE_ID and _workers.size() + _population_slot_reservations() >= MAX_WORKER_COUNT:
		head["state"] = QUEUE_BLOCKED_CAPACITY
		head["blocked_reason"] = QUEUE_BLOCKED_CAPACITY
		return
	# Accepted reservations, not unreserved stock, fund the START transaction.
	var cost: Dictionary = head["cost"]
	_stock[ROLE_FOOD] = int(_stock[ROLE_FOOD]) - int(cost[ROLE_FOOD])
	_stock[ROLE_MATERIAL] = int(_stock[ROLE_MATERIAL]) - int(cost[ROLE_MATERIAL])
	head["cost_state"] = COST_COMMITTED_NO_REFUND
	head["population_slot_reserved"] = head["recipe_id"] == WORKER_RECIPE_ID
	head["state"] = QUEUE_RUNNING
	head["blocked_reason"] = ""
	head["started_tick"] = _tick
	_record_event("PRODUCTION_STARTED", "", "", 1, head["queue_entry_id"])
	if head["kind"] == KIND_BUILDING:
		_redirect_construction_workers()
		if _builders_on_site() == 0:
			head["state"] = QUEUE_BLOCKED_BUILDERS
			head["blocked_reason"] = QUEUE_BLOCKED_BUILDERS


func _advance_construction(entry_index: int) -> void:
	var entry: Dictionary = _queue[entry_index]
	var builders := _builders_on_site()
	if builders == 0:
		entry["state"] = QUEUE_BLOCKED_BUILDERS
		entry["blocked_reason"] = QUEUE_BLOCKED_BUILDERS
		return
	entry["state"] = QUEUE_RUNNING
	entry["blocked_reason"] = ""
	entry["remaining_ticks"] = maxi(0, int(entry["remaining_ticks"]) - builders)
	if int(entry["remaining_ticks"]) == 0:
		_workshop_built = true
		_workshop_completed_tick = _tick
		_queue.remove_at(entry_index)
		_redirect_construction_workers()
		_record_event("WORKSHOP_COMPLETED", "", "", CampCatalog.WORK_REQUIRED, entry["queue_entry_id"])


func _redirect_construction_workers() -> void:
	for worker: Dictionary in _workers:
		if worker["role"] == ROLE_CONSTRUCTION_REPAIR and int(worker["cargo_amount"]) == 0:
			_activate_role(worker, ROLE_CONSTRUCTION_REPAIR)


func _builders_on_site() -> int:
	if _active_building_entry_index() < 0:
		return 0
	var count := 0
	for worker: Dictionary in _workers:
		if worker["role"] != ROLE_CONSTRUCTION_REPAIR or worker["desired_role"] != ROLE_CONSTRUCTION_REPAIR:
			continue
		if int(worker["cargo_amount"]) != 0 or worker["state"] != STATE_CONSTRUCTING:
			continue
		if worker["position"] == CampCatalog.work_position(int(worker["index"])) + _origin_offset:
			count += 1
	return count


func _active_building_entry_index() -> int:
	var index := _active_entry_index()
	return index if index >= 0 and _queue[index]["kind"] == KIND_BUILDING else -1


func _workshop_entry_index() -> int:
	for index: int in range(_queue.size()):
		if _queue[index]["kind"] == KIND_BUILDING:
			return index
	return -1


func _construction_snapshot() -> Dictionary:
	var recipe := CampCatalog.recipe_for_id(CampCatalog.WORKSHOP_RECIPE_ID)
	var result := {
		"slot_id": CampCatalog.WORKSHOP_SLOT_ID,
		"recipe_id": CampCatalog.WORKSHOP_RECIPE_ID,
		"position": CampCatalog.WORKSHOP_POSITION + _origin_offset,
		"radius": CampCatalog.FOUNDATION_RADIUS,
		"state": "BUILT" if _workshop_built else "EMPTY",
		"queue_entry_id": "",
		"cost": recipe["cost"],
		"cost_state": COST_COMMITTED_NO_REFUND if _workshop_built else "",
		"work_completed": CampCatalog.WORK_REQUIRED if _workshop_built else 0,
		"work_required": CampCatalog.WORK_REQUIRED,
		"builders_on_site": 0,
		"eta_ticks": 0 if _workshop_built else -1,
		"completed_tick": _workshop_completed_tick,
		"production_rate_numerator": _production_rate_numerator(),
		"production_rate_denominator": 4,
	}
	var index := _workshop_entry_index()
	if index < 0:
		return result
	var entry: Dictionary = _queue[index]
	result["queue_entry_id"] = entry["queue_entry_id"]
	result["cost_state"] = entry["cost_state"]
	result["work_completed"] = CampCatalog.WORK_REQUIRED - int(entry["remaining_ticks"])
	if entry["cost_state"] == COST_RESERVED:
		result["state"] = "QUEUED"
		return result
	var builders := _builders_on_site()
	result["builders_on_site"] = builders
	result["state"] = "BUILDING" if builders > 0 else QUEUE_BLOCKED_BUILDERS
	if builders > 0:
		result["eta_ticks"] = _ceil_div(int(entry["remaining_ticks"]), builders)
	return result


func _production_rate_numerator() -> int:
	return 5 if _workshop_built else 4


func _ceil_div(value: int, divisor: int) -> int:
	return int((value + divisor - 1) / divisor)


func _effective_duration_ticks(base_work: int) -> int:
	return _ceil_div(base_work * 4, _production_rate_numerator())


func _spawn_from_entry(entry_index: int) -> void:
	var entry: Dictionary = _queue[entry_index]
	var worker_index := _next_worker_index
	_next_worker_index += 1
	var worker_id := "worker_%02d" % worker_index
	_workers.append({
		"id": worker_id,
		"index": worker_index,
		"position": PRODUCTION_OUTLET + _origin_offset,
		"role": ROLE_RESERVE,
		"desired_role": ROLE_RESERVE,
		"state": STATE_TRAVEL_TO_RESERVE,
		"cargo_type": "",
		"cargo_amount": 0,
		"gather_ticks_remaining": 0,
	})
	_queue.remove_at(entry_index)
	_reconcile_assignments()
	_record_event("WORKER_SPAWNED", worker_id, "", 1, entry["queue_entry_id"])


func _outlet_is_clear(external_bodies: Array[Dictionary]) -> bool:
	for worker: Dictionary in _workers:
		if _bodies_overlap(PRODUCTION_OUTLET + _origin_offset, WORKER_RADIUS, worker["position"], WORKER_RADIUS):
			return false
	for body: Dictionary in external_bodies:
		if body.get("active", body.get("alive", true)) == false:
			continue
		if typeof(body.get("position")) != TYPE_VECTOR2I or typeof(body.get("radius")) != TYPE_INT:
			continue
		if _bodies_overlap(PRODUCTION_OUTLET + _origin_offset, WORKER_RADIUS, body["position"], body["radius"]):
			return false
	return true


func _bodies_overlap(left: Vector2i, left_radius: int, right: Vector2i, right_radius: int) -> bool:
	var combined_radius := left_radius + right_radius
	return left.distance_squared_to(right) < combined_radius * combined_radius


func _production_snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	for entry: Dictionary in _queue:
		var detached: Dictionary = entry.duplicate(true)
		if entry["kind"] == KIND_BUILDING:
			detached["effective_duration_ticks"] = -1
			var builders := _builders_on_site() if entry["cost_state"] == COST_COMMITTED_NO_REFUND else 0
			detached["effective_remaining_ticks"] = _ceil_div(int(entry["remaining_ticks"]), builders) if builders > 0 else -1
		else:
			detached["effective_duration_ticks"] = _effective_duration_ticks(int(entry["duration_ticks"]))
			detached["effective_remaining_ticks"] = _ceil_div(int(entry["remaining_ticks"]) * 4 - int(entry["progress_remainder"]), _production_rate_numerator())
		entries.append(detached)
	var recipes := {
		WORKER_RECIPE_ID: _recipe_for_id(WORKER_RECIPE_ID),
		WarbandCatalog.RECIPE_HINGE_GUARD: _recipe_for_id(WarbandCatalog.RECIPE_HINGE_GUARD),
		WarbandCatalog.RECIPE_BRIGHT_CROSSBOW: _recipe_for_id(WarbandCatalog.RECIPE_BRIGHT_CROSSBOW),
		CampCatalog.WORKSHOP_RECIPE_ID: _recipe_for_id(CampCatalog.WORKSHOP_RECIPE_ID),
	}
	for recipe: Dictionary in recipes.values():
		recipe["effective_duration_ticks"] = _effective_duration_ticks(int(recipe["duration_ticks"])) if recipe["kind"] != KIND_BUILDING else -1
	return {
		"recipe_id": WORKER_RECIPE_ID,
		"cost": {ROLE_FOOD: WORKER_RECIPE_FOOD_COST, ROLE_MATERIAL: WORKER_RECIPE_MATERIAL_COST},
		"duration_ticks": WORKER_RECIPE_DURATION_TICKS,
		"effective_duration_ticks": _effective_duration_ticks(WORKER_RECIPE_DURATION_TICKS),
		"capacity": MAX_UNRESOLVED_QUEUE_ENTRIES,
		"working_capacity": 1,
		"outlet": PRODUCTION_OUTLET + _origin_offset,
		"book": _stock.duplicate(),
		"reserved": _reserved_stock(),
		"available": _available_stock(),
		"entries": entries,
		"recipes": recipes,
		"slot_reservations": _population_slot_reservations(),
		"active_population": _workers.size(),
		"population_cap": MAX_WORKER_COUNT,
	}


func _reserved_stock() -> Dictionary:
	var reserved := {ROLE_FOOD: 0, ROLE_MATERIAL: 0}
	for entry: Dictionary in _queue:
		if entry["cost_state"] == COST_RESERVED:
			var cost: Dictionary = entry["cost"]
			reserved[ROLE_FOOD] = int(reserved[ROLE_FOOD]) + int(cost[ROLE_FOOD])
			reserved[ROLE_MATERIAL] = int(reserved[ROLE_MATERIAL]) + int(cost[ROLE_MATERIAL])
	return reserved


func _recipe_for_id(recipe_id: String) -> Dictionary:
	if recipe_id == WORKER_RECIPE_ID:
		return {
			"recipe_id": WORKER_RECIPE_ID,
			"kind": KIND_WORKER,
			"type_id": "",
			"unit_type": "",
			"label": "勤务民",
			"display_name": "勤务民",
			"cost": {ROLE_FOOD: WORKER_RECIPE_FOOD_COST, ROLE_MATERIAL: WORKER_RECIPE_MATERIAL_COST},
			"duration_ticks": WORKER_RECIPE_DURATION_TICKS,
			"member_count": 1,
		}
	var building := CampCatalog.recipe_for_id(recipe_id)
	if not building.is_empty():
		return building
	var warband := WarbandCatalog.recipe_for_id(recipe_id)
	if not warband.is_empty():
		warband["kind"] = KIND_WARBAND
	return warband


func _available_stock() -> Dictionary:
	var reserved := _reserved_stock()
	return {
		ROLE_FOOD: int(_stock[ROLE_FOOD]) - int(reserved[ROLE_FOOD]),
		ROLE_MATERIAL: int(_stock[ROLE_MATERIAL]) - int(reserved[ROLE_MATERIAL]),
	}


func _population_slot_reservations() -> int:
	var count := 0
	for entry: Dictionary in _queue:
		if entry["population_slot_reserved"]:
			count += 1
	return count


func _active_entry_index() -> int:
	for index: int in range(_queue.size()):
		if _queue[index]["cost_state"] == COST_COMMITTED_NO_REFUND:
			return index
	return -1


func _find_entry_index(entry_id: String) -> int:
	for index: int in range(_queue.size()):
		if _queue[index]["queue_entry_id"] == entry_id:
			return index
	return -1


func _has_exact_fields(value: Dictionary, expected_fields: Array[String]) -> bool:
	if value.size() != expected_fields.size():
		return false
	for field: String in expected_fields:
		if not value.has(field):
			return false
	return true


func _move_toward(position: Vector2i, destination: Vector2i) -> Vector2i:
	if position == destination:
		return position
	var current := Vector2(position)
	var goal := Vector2(destination)
	if current.distance_to(goal) <= float(WORKER_MOVE_STEP):
		return destination
	var moved: Vector2 = current.move_toward(goal, float(WORKER_MOVE_STEP))
	return Vector2i(roundi(moved.x), roundi(moved.y))


func _assigned_target_count() -> int:
	return int(_targets[ROLE_FOOD]) + int(_targets[ROLE_MATERIAL]) + int(_targets[ROLE_CONSTRUCTION_REPAIR])


func _record_event(event_type: String, worker_id: String, resource: String, amount: int, queue_entry_id: String = "") -> void:
	_events.append({
		"tick": _tick,
		"type": event_type,
		"worker_id": worker_id,
		"resource": resource,
		"amount": amount,
		"queue_entry_id": queue_entry_id,
	})
	if _events.size() > MAX_EVENTS:
		_events.pop_front()


func _rejection(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
