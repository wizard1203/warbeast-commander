extends RefCounted
## Detached investment/readiness index, not damage, income or a win oracle.
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Balance = preload("res://src/simulation/strategic_balance_catalog.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Towers = preload("res://src/simulation/strategic_faction_towers.gd")
const VERSION := "m72.match-scores/v1"
const RESOURCE_WEIGHTS := {"MATERIAL":1.0}
const CATEGORIES := ["army","buildings","economy","heroes","equipment","technology"]
var _scores: Dictionary = {}
var _peaks: Dictionary = {}
var _hero_levels: Dictionary = {}
var _last_tick := -1

static func value(cost: Dictionary) -> float:
	var result := 0.0
	for key: String in RESOURCE_WEIGHTS: result += maxf(0,float(cost.get(key,0))) * float(RESOURCE_WEIGHTS[key])
	return result / 10.0

static func _readiness(body: Dictionary) -> float:
	if float(body.get("hp",0)) <= 0: return 0.0
	return 0.25 + 0.75 * clampf(float(body.hp)/maxf(1,float(body.get("max_hp",body.hp))),0,1)

func observe(world: Dictionary, combat: Dictionary, tick: int, sides: Array) -> void:
	# The Host alone advances this cache, once per logical second. UI reads
	# cannot accumulate score, discover assets, or consume a random number.
	if tick <= _last_tick or (_last_tick >= 0 and tick-_last_tick < 20): return
	_last_tick = tick
	var rows := {}
	for slot: Variant in sides:
		var side := str(slot.get("side_id","")) if slot is Dictionary else str(slot)
		if side.is_empty() or side == "NEUTRAL": continue
		var current := {"army":0.0,"buildings":0.0,"economy":0.0,"heroes":0.0,"equipment":0.0,"technology":0.0}
		var counts := {"army":0,"workers":0,"heroes":0,"buildings":0,"equipment":0}
		for body: Dictionary in combat.get("soldiers",[]):
			if body.get("side") != side or body.get("unit_type") == "hero" or float(body.get("hp",0)) <= 0: continue
			var recipe: Dictionary = Units.UNITS.get(str(body.get("unit_type","")),{})
			if recipe.is_empty(): continue
			current.army += value(recipe.get("cost",{})) * _readiness(body); counts.army += 1
		var hero_rows: Variant = combat.get("heroes",{})
		var officers: Array = hero_rows.get("officers",[]) if hero_rows is Dictionary else []
		for hero: Dictionary in officers:
			if hero.get("side") != side: continue
			var id := str(hero.get("id",hero.get("unit_id","")))
			var level := maxi(1,int(hero.get("level",1)))
			var previous: Dictionary = _hero_levels.get(id,{"side":side,"level":1})
			_hero_levels[id] = {"side":side,"level":maxi(level,int(previous.level))}
			if float(hero.get("hp",0)) <= 0: continue
			var ranks := 0
			for skill: Dictionary in hero.get("skills",[]): ranks += maxi(0,int(skill.get("level",0)))
			var ready := _readiness(hero)
			var mana := clampf(float(hero.get("mana",0))/maxf(1,float(hero.get("max_mana",1))),0,1)
			current.heroes += (40.0+8.0*(level-1)+2.0*ranks) * ready * (0.85+0.15*mana)
			counts.heroes += 1
			for item_id: String in hero.get("equipment",[]):
				var item: Dictionary = Items.ITEMS.get(item_id,{})
				if item.is_empty() or bool(item.get("consumable",false)): continue
				current.equipment += value(Items.total_cost(item_id))*ready; counts.equipment += 1
		for worker: Dictionary in world.get("workers",[]):
			if worker.get("side") != side or float(worker.get("hp",0)) <= 0: continue
			current.economy += value(Units.UNITS.worker.cost)*_readiness(worker); counts.workers += 1
		var bank: Dictionary = world.get("economy",{}).get(side,{})
		current.economy += value(bank.get("stock",{}))
		for building: Dictionary in world.get("buildings",[]):
			if building.get("side") != side or float(building.get("hp",0)) <= 0 or not bool(building.get("complete",false)): continue
			if bool(building.get("fixed",false)) or building.get("building_type") == "SHOP": continue
			var replacement := value(building.get("cost",{}))
			if building.get("building_type") == "BASE":
				for tier: int in range(2,int(building.get("base_tier",1))+1): replacement += value(Balance.BASE_UPGRADES.get(tier,{}).get("cost",{}))
			if building.get("building_type") == "TOWER" and int(building.get("tower_level",1)) >= 2: replacement += value(Towers.upgrade_quote(str(building.get("faction_id","HUMAN"))).cost)
			# Capturable default defenses have no paid construction recipe;
			# their actual operational weapon capacity still has index value.
			if building.get("building_type") == "SITE_TOWER" and bool(building.get("defense_active",false)):
				replacement = float(building.get("damage",0))*20.0/maxf(1,float(building.get("attack_cooldown_ticks",30)))
			current.buildings += replacement*_readiness(building); counts.buildings += 1
		for technology: String in world.get("technology",{}).get(side,{}):
			var rank := maxi(0,int(world.technology[side][technology]))
			var recipes: Array = Balance.TECH_RANKS.get(technology,[])
			for index: int in range(mini(rank,recipes.size())): current.technology += value(recipes[index].get("cost",{}))
		current["total"] = 0.0
		if not _peaks.has(side): _peaks[side] = {}
		for category: String in CATEGORIES:
			current[category] = snappedf(float(current[category]),0.1)
			current.total += float(current[category])
			_peaks[side][category] = maxf(float(_peaks[side].get(category,0)),float(current[category]))
		current.total = snappedf(float(current.total),0.1)
		_peaks[side]["total"] = maxf(float(_peaks[side].get("total",0)),float(current.total))
		var levels := 0
		for entry: Dictionary in _hero_levels.values():
			if entry.side == side: levels += int(entry.level)-1
		var achievements := 0.0
		for hero: Dictionary in combat.get("hero_statistics",{}).get("heroes",[]):
			if hero.get("side") == side:
				achievements += 20*int(hero.get("hero_kills",0))+2*int(hero.get("unit_kills",0))+int(hero.get("neutral_kills",0))+5*int(hero.get("building_kills",0))
		var gathered := value(bank.get("delivered",{}))
		rows[side] = {"side":side,"current":current,"counts":counts,"peaks":_peaks[side].duplicate(true),"accumulated":{"gathered":gathered,"hero_levels":levels,"hero_combat":achievements,"total":snappedf(gathered+levels*5.0+achievements,0.1)}}
	_scores = {"schema":VERSION,"tick":tick,"sides":rows,"formula":{"resource_weights":RESOURCE_WEIGHTS.duplicate(true),"resource_divisor":10,"readiness":"alive: 0.25+0.75*HP/maxHP; dead:0","hero":"(40+8*(level-1)+2*learned ranks)*HP readiness*(0.85+0.15*MP ratio); equipment priced separately","accumulated":"net worker deliveries/10 weighted; earned hero levels*5; hero-attributed hero/unit/neutral/building kills*20/2/1/5","scope":"Investment/readiness index, NOT exact combat power or win probability. Economy includes bank and living workers, not imaginary future income. Historical peaks and achievements never supply local DPS. Gathered excludes initial stock, refunds, transfers and bounty; hero combat is not all-army kills. Missing old replay scores remain absent."}}

func snapshot() -> Dictionary:
	return _scores.duplicate(true)

static func validate_snapshot(scores: Variant, frame_tick: int = 18000) -> bool:
	# Optional on legacy recordings. Present data must be safe for the shared
	# live/replay table, including non-finite values allowed elsewhere as paths.
	if not scores is Dictionary: return false
	if scores.is_empty(): return true
	if scores.get("schema") != VERSION or typeof(scores.get("tick")) != TYPE_INT: return false
	if int(scores.tick) < 0 or int(scores.tick) > frame_tick: return false
	if not scores.get("sides") is Dictionary or scores.sides.size() > 4: return false
	for side: Variant in scores.sides:
		if side not in ["PLAYER","AI","AI_2","AI_3"]: return false
		var row: Variant = scores.sides[side]
		if not row is Dictionary or row.get("side") != side: return false
		for group: String in ["current","peaks"]:
			if not row.get(group) is Dictionary: return false
			for key: String in CATEGORIES + ["total"]:
				if not _finite_score(row[group].get(key)): return false
		if not row.get("counts") is Dictionary or not row.get("accumulated") is Dictionary: return false
		for key: String in ["army","workers","heroes","buildings","equipment"]:
			if typeof(row.counts.get(key)) != TYPE_INT or int(row.counts[key]) < 0 or int(row.counts[key]) > 10000: return false
		for key: String in ["gathered","hero_levels","hero_combat","total"]:
			if not _finite_score(row.accumulated.get(key)): return false
		var sum := 0.0
		for key: String in CATEGORIES:
			sum += float(row.current[key])
			if float(row.peaks[key])+0.001 < float(row.current[key]): return false
		if absf(sum-float(row.current.total)) > 0.01: return false
		if float(row.peaks.total)+0.001 < float(row.current.total): return false
	return true

static func _finite_score(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0 and float(value) <= 1e12
