extends RefCounted
## Intention lease, never a stock/debit ledger. Costs come from authority facts.
const LEASE_TICKS := 600
const COOLDOWN_TICKS := 200
var target: Dictionary = {}
var cooldowns: Dictionary = {}
var last_spend_tick := -1
var stalled_since := -1
var stalled_decisions := 0
var diagnostic: Dictionary = {}

func update(tick: int, candidate: Dictionary, stock: Dictionary, income_progress: String) -> Dictionary:
	var key := str(candidate.get("key",""))
	if not target.is_empty() and str(target.key) != key: target.clear()
	if candidate.is_empty():
		target.clear()
	elif not target.is_empty():
		var deficit := _deficit(candidate.get("cost",{}),stock)
		if deficit < int(target.deficit) and income_progress != str(target.progress) or str(candidate.get("construction_progress","")) != str(target.get("construction_progress","")):
			target.expires_tick = tick + LEASE_TICKS
		target.deficit = deficit
		target.progress = income_progress
		target.merge(candidate.duplicate(true),true)
		target.construction_progress = candidate.get("construction_progress","")
		if tick >= int(target.expires_tick):
			cooldowns[key] = tick + COOLDOWN_TICKS
			target.clear()
	elif tick >= int(cooldowns.get(key,-1)):
		target = candidate.duplicate(true)
		target["started_tick"] = tick
		target["expires_tick"] = tick + LEASE_TICKS
		target["deficit"] = _deficit(candidate.cost,stock)
		target["progress"] = income_progress
	if not target.is_empty():
		var gaps := {}
		for resource: String in target.cost: gaps[resource] = maxi(0,int(target.cost[resource])-int(stock.get(resource,0)))
		target["resource_gap"] = gaps
	return target.get("cost",{}).duplicate(true)

func paid(tick: int) -> void:
	last_spend_tick = tick
	stalled_since = -1
	stalled_decisions = 0
	diagnostic["last_spend_tick"] = tick
	diagnostic["stall_decisions"] = 0
	diagnostic["spending_stalled"] = false
	if str(diagnostic.get("block_reason","")).begins_with("SAVING"):
		diagnostic["block_reason"] = "PAID_AWAITING_RECHECK"

func settled_target(key: String) -> void:
	if not target.is_empty() and str(target.key)==key:
		target.clear()
		diagnostic["saving_target"] = {}

func get_state() -> Dictionary:
	return {"target":target.duplicate(true),"cooldowns":cooldowns.duplicate(true),"last_spend_tick":last_spend_tick,"stalled_since":stalled_since,"stalled_decisions":stalled_decisions,"diagnostic":diagnostic.duplicate(true)}

func observe(tick: int, useful_affordable: bool, block: String) -> void:
	if useful_affordable and target.is_empty():
		if stalled_since < 0: stalled_since = tick
		stalled_decisions += 1
	else:
		stalled_since = -1
		stalled_decisions = 0
	diagnostic = {"observed_tick":tick,"saving_target":target.duplicate(true),"block_reason":block,"last_spend_tick":last_spend_tick,"affordable_useful_idle":useful_affordable,"stall_decisions":stalled_decisions,"spending_stalled":stalled_decisions >= 3 and stalled_since >= 0 and tick - stalled_since >= 120}

static func _deficit(cost: Dictionary, stock: Dictionary) -> int:
	var amount := 0
	for resource: String in cost: amount += maxi(0,int(cost[resource])-int(stock.get(resource,0)))
	return amount
