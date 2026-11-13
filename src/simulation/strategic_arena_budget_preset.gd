extends RefCounted
## Pure, seed-owned arena fixture selection. No economy payment or combat RNG.
## Equal caps are not equal spend, equal population, or equal measured power.
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const FirstRelease = preload("res://src/simulation/first_release_catalog.gd")
const ArenaRules = preload("res://src/simulation/strategic_hero_arena_runner.gd")
const VERSION := "arena-one-side-gold-budget-v3"
const DEFAULT_BUDGET := 10000
const MIN_BUDGET := 4000
const MAX_BUDGET := 30000
const WEIGHTS := {"MATERIAL":1}
const LEVELS := [8,5,5]
const SIDES := ["PLAYER","AI"]
const RANGE_ITEMS := ["LONGSIGHT","PATHFINDER_COMPASS","HUNTERS_SCOPE"]
const BASIC_ATTACK_ITEMS := ["IRON_BLADE","SWIFT_GLOVES","VANGUARD_BLADE","SWIFT_BLADE","HUNTERS_SCOPE","WAR_STANDARD"]
const HEAL_ITEMS := ["HEALERS_SEAL","MERCY_STAFF"]
const CASTER_ITEMS := ["SPELL_LENS","ARCANE_SIGIL","SPELLWEAVE","MANA_CRYSTAL","MANA_BEAD","DEEP_CURRENT","MANA_STANDARD"]
const DEFENSE_ITEMS := ["WARD_MAIL","VITAL_CHARM","NULL_CLOAK","REGEN_RING","WARDEN_CREST","NULL_AEGIS","EVERGREEN_CHARM","MARCHWARD","AEGIS_STANDARD","SPRING_STANDARD"]

static func generate(seed: int, left_faction: String, right_faction: String, budget: int = DEFAULT_BUDGET) -> Dictionary:
	if not FirstRelease.is_playable_faction(left_faction) or not FirstRelease.is_playable_faction(right_faction): return _reject("INVALID_FACTION")
	if budget < MIN_BUDGET: return _reject("BUDGET_TOO_LOW")
	if budget > MAX_BUDGET: return _reject("BUDGET_TOO_HIGH")
	var caps := _caps(budget)
	var seeds := {"PLAYER":seed,"AI":seed}
	var receipt := _receipt(seed,caps,seeds)
	var config := {"mode":"MIXED","seed":seed,"limit_seconds":120,"auto_consumables":true,"sides":{},"budget_preset_version":VERSION,"budget_preset_budget":budget,"budget_side_seeds":seeds.duplicate()}
	for side: String in SIDES:
		var faction := left_faction if side == "PLAYER" else right_faction
		var built := _side(seed,side,faction,caps)
		if not bool(built.accepted): return _reject(str(built.error))
		config.sides[side] = built.config
		receipt.sides[side] = built.receipt
	config["budget_receipt"] = receipt.duplicate(true)
	return {"accepted":true,"error":"","config":config,"receipt":receipt}

## Replaces one complete starting roster only. The held side is copied byte-for-
## value (including hand-authored fields); its old receipt is never trusted.
## Shared combat RNG follows config.seed, while per-side configuration seeds
## persist separately so changing the editor seed/invalidating a quote is safe.
static func reroll_side(current: Dictionary, side: String, seed: int, faction: String = "", budget: int = -1) -> Dictionary:
	if side not in SIDES: return _reject("INVALID_SIDE")
	var valid := ArenaRules.validate(current)
	if not bool(valid.accepted): return _reject("CURRENT_"+str(valid.error))
	if faction.is_empty(): faction = str(current.sides[side].faction_id)
	if not FirstRelease.is_playable_faction(faction): return _reject("INVALID_FACTION")
	var old_receipt: Dictionary = current.get("budget_receipt",{}) if current.get("budget_receipt",{}) is Dictionary else {}
	if budget == -1:
		if current.has("budget_preset_budget"):
			if typeof(current.budget_preset_budget)!=TYPE_INT: return _reject("INVALID_BUDGET_METADATA")
			budget = int(current.budget_preset_budget)
		else:
			var old_caps: Dictionary = old_receipt.get("caps",{}) if old_receipt.get("caps",{}) is Dictionary else {}
			budget = int(old_caps.get("total",DEFAULT_BUDGET))
	if budget < MIN_BUDGET: return _reject("BUDGET_TOO_LOW")
	if budget > MAX_BUDGET: return _reject("BUDGET_TOO_HIGH")
	var caps := _caps(budget)
	var other := "AI" if side=="PLAYER" else "PLAYER"
	# Requote and reject before generating anything. Lowering a shared cap must
	# never silently replace, unequip or reduce the user's held configuration.
	var measured := _measure_side(current.sides[other],caps)
	if not bool(measured.accepted): return _reject("PRESERVED_SIDE_"+str(measured.error))
	var built := _side(seed,side,faction,caps)
	if not bool(built.accepted): return _reject(str(built.error))
	var seeds := {"PLAYER":int(current.seed),"AI":int(current.seed)}
	var prior_seeds: Variant = current.get("budget_side_seeds",old_receipt.get("side_seeds",{}))
	if prior_seeds is Dictionary:
		for key: String in SIDES:
			if typeof(prior_seeds.get(key))==TYPE_INT: seeds[key]=int(prior_seeds[key])
	seeds[side]=seed
	var receipt := _receipt(seed,caps,seeds)
	receipt["rerolled_side"]=side
	receipt["preserved_side"]=other
	receipt.sides[other]=measured.receipt
	receipt.sides[side]=built.receipt
	var config := current.duplicate(true)
	config["mode"]="MIXED"
	config["seed"]=seed
	config["auto_consumables"]=true
	config.sides[side]=built.config
	config["budget_preset_version"]=VERSION
	config["budget_preset_budget"]=budget
	config["budget_side_seeds"]=seeds.duplicate()
	config["budget_receipt"]=receipt.duplicate(true)
	return {"accepted":true,"error":"","config":config,"receipt":receipt}

static func _caps(budget: int) -> Dictionary:
	var item_cap := budget * 65 / 100
	return {"total":budget,"items":item_cap,"troops":budget-item_cap,"item_unspent_transfers_to_troops":true}

static func _receipt(seed: int, caps: Dictionary, seeds: Dictionary) -> Dictionary:
	return {"version":VERSION,"seed":seed,"side_seeds":seeds.duplicate(),"weights":WEIGHTS.duplicate(),"caps":caps.duplicate(),"levels":LEVELS.duplicate(),"sides":{},"scope":"Free isolated arena fixture; equal total caps and item ceilings, not equal measured power. Unspent item points transfer to that side's troop allowance. Hero recruitment/XP is gifted, not charged. Full authoritative component prices are included. Global seed is combat RNG; per-side seeds describe starting rosters."}

static func _measure_side(data: Dictionary, caps: Dictionary) -> Dictionary:
	var item_resources := _zero_resources()
	var hero_receipts: Array[Dictionary] = []
	for hero: Dictionary in data.heroes:
		var profile := Heroes.profile(str(hero.archetype))
		var cost := _zero_resources()
		var equipment_rows: Array[Dictionary] = []
		var consumable_rows: Array[Dictionary] = []
		for id: String in hero.get("equipment",[]):
			_add_cost(cost,Items.total_cost(id))
			equipment_rows.append(_item_receipt(profile,id))
		for id: String in hero.get("consumables",[]):
			_add_cost(cost,Items.total_cost(id))
			consumable_rows.append(_item_receipt(profile,id))
		_add_cost(item_resources,cost)
		hero_receipts.append({"archetype":hero.archetype,"level":hero.level,"role_id":str(profile.get("role_id","")),"role_label":str(profile.get("role","")),"ranged":int(profile.stats.attack_range)>80,"equipment":equipment_rows,"consumables":consumable_rows,"cap":caps.items,"allocation":"SHARED_ITEM_CAP_PRESERVED","spent":points(cost),"unspent":int(caps.items)-points(cost),"resources":cost})
	var item_spent := points(item_resources)
	if item_spent>int(caps.items): return _reject("ITEM_BUDGET_EXCEEDED")
	var troop_resources := _zero_resources()
	var rows: Array[Dictionary] = []
	var bodies := 0
	var population := 0
	for group: Dictionary in data.troops:
		var id := str(group.unit_type)
		var count := int(group.count)
		for resource: String in WEIGHTS: troop_resources[resource]+=int(Units.UNITS[id].cost.get(resource,0))*count
		bodies+=count
		population+=int(Units.UNITS[id].population)*count
		rows.append(_troop_receipt(id,count))
	var troop_spent := points(troop_resources)
	var troop_cap := int(caps.total)-item_spent
	if troop_spent>troop_cap: return _reject("TOTAL_BUDGET_EXCEEDED")
	var resources := item_resources.duplicate()
	_add_cost(resources,troop_resources)
	var total := points(resources)
	return {"accepted":true,"error":"","receipt":{"faction_id":data.faction_id,"source":"PRESERVED_CONFIG_REQUOTED","cap":caps.total,"spent":total,"unspent":int(caps.total)-total,"resources":resources,"heroes":hero_receipts,"items":{"cap":caps.items,"spent":item_spent,"unspent":int(caps.items)-item_spent,"resources":item_resources},"troops":{"cap":troop_cap,"base_cap":caps.troops,"transferred_from_items":int(caps.items)-item_spent,"spent":troop_spent,"unspent":troop_cap-troop_spent,"resources":troop_resources,"roster":rows,"body_count":bodies,"population":population,"optimization":{"method":"PRESERVED_NO_REDRAW","exact_within_constraints":false}},"body_count":data.heroes.size()+bodies,"population":5*data.heroes.size()+population}}

static func points(cost: Dictionary) -> int:
	var result := 0
	for resource: String in WEIGHTS: result += int(cost.get(resource,0)) * int(WEIGHTS[resource])
	return result

static func _side(seed: int, side: String, faction: String, caps: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	# Stable domain-separated hash, never seed()/randi() on the global RNG.
	rng.seed = (str(seed)+"/"+faction+"/"+side+"/"+VERSION).sha256_text().substr(0,15).hex_to_int()
	var deck: Array = Factions.heroes_for(faction).duplicate()
	_shuffle(deck,rng)
	var heroes: Array[Dictionary] = []
	var hero_receipts: Array[Dictionary] = []
	var item_resources := _zero_resources()
	var aura_used := false
	for index: int in range(3):
		var hero_id := str(deck[index])
		var hero_cap := int(caps.items) / 3 + (1 if index < int(caps.items) % 3 else 0)
		var chosen := _loadout(hero_id,hero_cap,aura_used,rng)
		if not bool(chosen.accepted): return chosen
		heroes.append({"archetype":hero_id,"level":LEVELS[index],"equipment":chosen.equipment,"consumables":chosen.consumables})
		var profile := Heroes.profile(hero_id)
		hero_receipts.append({"archetype":hero_id,"level":LEVELS[index],"role_id":str(profile.get("role_id","")),"role_label":str(profile.get("role","")),"ranged":int(profile.stats.attack_range)>80,"equipment":chosen.equipment_receipts,"consumables":chosen.consumable_receipts,"cap":hero_cap,"spent":chosen.spent,"unspent":hero_cap-int(chosen.spent),"resources":chosen.resources.duplicate()})
		_add_cost(item_resources,chosen.resources)
		aura_used = aura_used or bool(chosen.aura_used)
	var item_spent := points(item_resources)
	var troop_cap := int(caps.total)-item_spent
	var army := _army(faction,troop_cap,rng)
	if not bool(army.accepted): return army
	var resources := item_resources.duplicate()
	_add_cost(resources,army.resources)
	var spent := points(resources)
	var troop_spent := points(army.resources)
	return {"accepted":true,"error":"","config":{"faction_id":faction,"heroes":heroes,"troops":army.roster},"receipt":{"faction_id":faction,"source":"RANDOM_SEEDED","cap":caps.total,"spent":spent,"unspent":int(caps.total)-spent,"resources":resources,"heroes":hero_receipts,"items":{"cap":caps.items,"spent":item_spent,"unspent":int(caps.items)-item_spent,"resources":item_resources},"troops":{"cap":troop_cap,"base_cap":caps.troops,"transferred_from_items":int(caps.items)-item_spent,"spent":troop_spent,"unspent":troop_cap-troop_spent,"resources":army.resources,"roster":army.receipt,"body_count":army.body_count,"population":army.population,"optimization":army.optimization},"body_count":3+int(army.body_count),"population":15+int(army.population)}}

static func _loadout(hero_id: String, cap: int, previous_aura: bool, rng: RandomNumberGenerator) -> Dictionary:
	var profile := Heroes.profile(hero_id)
	var equipment: Array[String] = []
	var consumables: Array[String] = []
	var resources := _zero_resources()
	var budget_left := cap
	# Reserve useful supplies before drawing equipment. One recovery and one
	# battle buff provide actual automatic-use candidates, not fake charges.
	var recovery := ["POTION","MANA_POTION","RESTORATION_DRAUGHT","ESSENCE_RESTORATION","GROUP_HEAL_DRAUGHT"]
	var buffs := ["GUARD_DRAUGHT","HASTE_DRAUGHT","ASSAULT_DRAUGHT","NULL_DRAUGHT","SHIELD_DRAUGHT","ESSENCE_BULWARK"]
	if str(profile.role_id)=="MAGE": buffs.erase("ASSAULT_DRAUGHT")
	if str(profile.role_id)=="TANK": recovery.erase("MANA_POTION")
	_shuffle(recovery,rng)
	_shuffle(buffs,rng)
	for pool: Array in [recovery,buffs]:
		var selected := ""
		for id: String in pool:
			var price := points(Items.total_cost(id))
			if price <= budget_left - 650:
				selected = id
				break
		if selected.is_empty():
			# Low-cap fixtures retain the same useful slot categories.
			selected = "POTION" if consumables.is_empty() else "GUARD_DRAUGHT"
		consumables.append(selected)
		var cost := Items.total_cost(selected)
		budget_left -= points(cost)
		_add_cost(resources,cost)
	var aura_used := previous_aura
	var core_candidates: Array[String] = []
	var candidates: Array[String] = []
	for id: String in Items.ITEMS:
		if not equipment_allowed(hero_id,id): continue
		if aura_used and str(Items.ITEMS[id].tier)=="AURA": continue
		candidates.append(id)
		if _core_item(profile,id): core_candidates.append(id)
	for slot: int in range(4):
		var pool: Array[String] = core_candidates if slot==0 else candidates
		var affordable: Array[String] = []
		for id: String in pool:
			if id in equipment: continue
			if aura_used and str(Items.ITEMS[id].tier)=="AURA": continue
			var remaining := candidates.duplicate()
			remaining.erase(id)
			for held: String in equipment: remaining.erase(held)
			# Reserve cheapest legal distinct completion; a costly early draw
			# must never leave a hero with only 3 equipment slots.
			var floor_cost := _equipment_floor(remaining,3-slot,aura_used or str(Items.ITEMS[id].tier)=="AURA")
			if points(Items.total_cost(id)) + floor_cost <= budget_left: affordable.append(id)
		if affordable.is_empty(): return _reject("NO_LEGAL_FULL_LOADOUT")
		var selected := _weighted_item(profile,affordable,rng)
		equipment.append(selected)
		var cost := Items.total_cost(selected)
		budget_left -= points(cost)
		_add_cost(resources,cost)
		aura_used = aura_used or str(Items.ITEMS[selected].tier)=="AURA"
	var equipment_receipts: Array[Dictionary] = []
	var consumable_receipts: Array[Dictionary] = []
	for id: String in equipment: equipment_receipts.append(_item_receipt(profile,id))
	for id: String in consumables: consumable_receipts.append(_item_receipt(profile,id))
	return {"accepted":true,"error":"","equipment":equipment,"consumables":consumables,"equipment_receipts":equipment_receipts,"consumable_receipts":consumable_receipts,"resources":resources,"spent":points(resources),"aura_used":aura_used}

static func equipment_allowed(hero_id: String, item_id: String) -> bool:
	if not Items.ITEMS.has(item_id) or bool(Items.ITEMS[item_id].get("consumable",false)): return false
	var profile := Heroes.profile(hero_id)
	if profile.is_empty(): return false
	if item_id in RANGE_ITEMS and int(profile.stats.attack_range)<=80: return false
	if item_id in RANGE_ITEMS and str(profile.role_id)=="MAGE": return false
	if item_id in BASIC_ATTACK_ITEMS and str(profile.role_id)=="MAGE": return false
	if item_id in HEAL_ITEMS and not _has_healing(profile): return false
	return true

static func _has_healing(profile: Dictionary) -> bool:
	for id: String in profile.skill_ids:
		var skill := Heroes.skill_at_level(id,1)
		if float(skill.get("heal",0))>0 or float(skill.get("ally_heal",0))>0 or float(skill.get("aura_heal",0))>0: return true
	return false

static func _core_item(profile: Dictionary, item_id: String) -> bool:
	match str(profile.role_id):
		"MAGE": return item_id in ["SPELL_LENS","ARCANE_SIGIL","SPELLWEAVE"]
		"TANK": return item_id in ["WARD_MAIL","WARDEN_CREST","NULL_AEGIS","AEGIS_STANDARD"]
		"HEAL_SUPPORT": return item_id in ["HEALERS_SEAL","MERCY_STAFF","MANA_BEAD","DEEP_CURRENT","SPRING_STANDARD"]
		"CONTROL_SUPPORT": return item_id in ["MANA_CRYSTAL","MANA_BEAD","DEEP_CURRENT","MANA_STANDARD"]
		"MELEE_CASTER": return item_id in ["IRON_BLADE","SWIFT_BLADE","SPELL_LENS","ARCANE_SIGIL"]
		_: return item_id in ["IRON_BLADE","SWIFT_GLOVES","VANGUARD_BLADE","SWIFT_BLADE","HUNTERS_SCOPE"]

static func _item_weight(profile: Dictionary, item_id: String) -> float:
	var item: Dictionary = Items.ITEMS[item_id]
	var role := str(profile.role_id)
	var weight := 1.0
	if role in ["MAGE","MELEE_CASTER"] and item_id in CASTER_ITEMS: weight += 2.5
	if role in ["HEAL_SUPPORT","CONTROL_SUPPORT"] and (item_id in CASTER_ITEMS or item_id in HEAL_ITEMS): weight += 2.5
	if role in ["PHYSICAL","WARRIOR","MELEE_CASTER"] and item_id in BASIC_ATTACK_ITEMS: weight += 3.0
	if role in ["TANK","WARRIOR"] and item_id in DEFENSE_ITEMS: weight += 3.0
	if int(profile.stats.attack_range)>80 and item_id in RANGE_ITEMS: weight += 2.0
	if str(item.tier)=="ADVANCED": weight *= 1.6
	if str(item.tier)=="AURA": weight *= 0.75
	return weight

static func _weighted_item(profile: Dictionary, candidates: Array[String], rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for id: String in candidates: total += _item_weight(profile,id)
	var roll := rng.randf() * total
	for id: String in candidates:
		roll -= _item_weight(profile,id)
		if roll <= 0.0: return id
	return candidates.back()

static func _equipment_floor(candidates: Array[String], count: int, aura_used: bool) -> int:
	var prices: Array[int] = []
	for id: String in candidates:
		if aura_used and str(Items.ITEMS[id].tier)=="AURA": continue
		prices.append(points(Items.total_cost(id)))
	prices.sort()
	if prices.size()<count: return 99999999
	var result := 0
	for index: int in range(count): result += prices[index]
	return result

static func _item_receipt(profile: Dictionary, id: String) -> Dictionary:
	return {"id":id,"name":Items.ITEMS[id].name,"tier":Items.ITEMS[id].tier,"cost":Items.total_cost(id),"points":points(Items.total_cost(id)),"weight":_item_weight(profile,id)}

static func _army(faction: String, cap: int, rng: RandomNumberGenerator) -> Dictionary:
	var counts := {}
	var resources := _zero_resources()
	var body_count := 0
	var population := 0
	# The same native opening is the minimum army in every consumer. This
	# arena additionally gifts one support inside its equal gold budget.
	var minimums:=Factions.opening_recipe(faction)
	var supports: Array=Factions.units_for(faction,"SUPPORT")
	if minimums.is_empty() or supports.is_empty():return _reject("FACTION_ROLE_MISSING")
	minimums.append({"unit_type":str(supports[0]),"count":1})
	var role_minimums: Dictionary={}
	for row: Dictionary in minimums:
		var id:=str(row.unit_type)
		for index: int in range(int(row.count)):
			counts[id]=int(counts.get(id,0))+1
			_add_cost(resources,Units.UNITS[id].cost)
			body_count+=1
			population+=int(Units.UNITS[id].population)
			var role:=str(Units.UNITS[id].role)
			role_minimums[role]=int(role_minimums.get(role,0))+1
	if points(resources)>cap: return _reject("TROOP_BUDGET_TOO_LOW")
	var ids: Array[String] = Factions.units_for(faction)
	_shuffle(ids,rng)
	var divisor := 0
	var type_limits := {}
	for id: String in ids:
		divisor = _gcd(divisor,points(Units.UNITS[id].cost))
		type_limits[id]=1 if int(Units.UNITS[id].cost.get("ESSENCE",0))>0 else 8
	divisor=maxi(1,divisor)
	var base_spent := points(resources)
	var remaining_cap := (cap-base_spent)/divisor
	var remaining_bodies := 24-body_count
	var body_mask := (1 << (remaining_bodies+1))-1
	# At each attainable price, bit n means exactly n added bodies. This keeps
	# every feasible count without copying whole army dictionaries or favoring a
	# greedy expensive draw. Stage history supports random optimal backtracking.
	var initial := PackedInt32Array()
	initial.resize(remaining_cap+1)
	initial.fill(0)
	initial[0]=1
	var stages: Array[PackedInt32Array] = [initial]
	var limits: Array[int] = []
	var prices: Array[int] = []
	for id: String in ids:
		var limit := int(type_limits[id])-int(counts.get(id,0))
		var price := points(Units.UNITS[id].cost)/divisor
		limits.append(limit)
		prices.append(price)
		var previous: PackedInt32Array = stages.back()
		var next := PackedInt32Array()
		next.resize(remaining_cap+1)
		next.fill(0)
		for spent: int in range(remaining_cap+1):
			if previous[spent]==0: continue
			for quantity: int in range(limit+1):
				var target := spent+quantity*price
				if target>remaining_cap: break
				next[target] |= (int(previous[spent]) << quantity) & body_mask
		stages.append(next)
	var final: PackedInt32Array = stages.back()
	var best := remaining_cap
	while best>0 and final[best]==0: best-=1
	var choices: Array[int] = []
	for n: int in range(remaining_bodies+1):
		if int(final[best]) & (1 << n): choices.append(n)
	var selected_bodies := choices[rng.randi_range(0,choices.size()-1)]
	var cursor_spent := best
	var cursor_bodies := selected_bodies
	for index: int in range(ids.size()-1,-1,-1):
		var previous: PackedInt32Array = stages[index]
		var quantities: Array[int] = []
		for quantity: int in range(limits[index]+1):
			var before_spent := cursor_spent-quantity*prices[index]
			var before_bodies := cursor_bodies-quantity
			if before_spent<0 or before_bodies<0: continue
			if int(previous[before_spent]) & (1 << before_bodies): quantities.append(quantity)
		if quantities.is_empty(): return _reject("TROOP_OPTIMIZER_BACKTRACK_FAILED")
		var selected := quantities[rng.randi_range(0,quantities.size()-1)]
		cursor_spent-=selected*prices[index]
		cursor_bodies-=selected
		var id := ids[index]
		if selected==0: continue
		counts[id]=int(counts.get(id,0))+selected
		for resource: String in WEIGHTS: resources[resource]+=int(Units.UNITS[id].cost.get(resource,0))*selected
		body_count+=selected
		population+=int(Units.UNITS[id].population)*selected
	var roster: Array[Dictionary] = []
	var receipt: Array[Dictionary] = []
	for id: String in counts:
		roster.append({"unit_type":id,"count":counts[id]})
		receipt.append(_troop_receipt(id,int(counts[id])))
	var reachable := 0
	for mask: int in final:
		if mask!=0: reachable+=1
	return {"accepted":true,"error":"","roster":roster,"receipt":receipt,"resources":resources,"body_count":body_count,"population":population,"optimization":{"method":"BOUNDED_COUNT_BITSET","exact_within_constraints":true,"best_spent":base_spent+best*divisor,"role_minimums":role_minimums,"opening_recipe":Factions.opening_recipe(faction),"max_bodies":24,"type_limits":type_limits,"price_gcd":divisor,"reachable_spends":reachable}}

static func _troop_receipt(id: String, count: int) -> Dictionary:
	return {"unit_type":id,"name":Units.UNITS[id].label,"count":count,"cost_each":Units.UNITS[id].cost.duplicate(),"points_each":points(Units.UNITS[id].cost),"population_each":Units.UNITS[id].population}

static func _gcd(a: int, b: int) -> int:
	while b!=0:
		var saved := b
		b=a%b
		a=saved
	return a

static func _zero_resources() -> Dictionary: return {"FOOD":0,"MATERIAL":0,"ESSENCE":0}
static func _add_cost(target: Dictionary, cost: Dictionary) -> void:
	for resource: String in WEIGHTS: target[resource] += int(cost.get(resource,0))
static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index: int in range(values.size()-1,0,-1):
		var other := rng.randi_range(0,index)
		var saved: Variant = values[index]
		values[index] = values[other]
		values[other] = saved
static func _reject(error: String) -> Dictionary:
	return {"accepted":false,"error":error,"config":{},"receipt":{}}
