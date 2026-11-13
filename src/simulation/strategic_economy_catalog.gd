class_name StrategicEconomyCatalog
extends RefCounted
## M51 shared finite resource scale. Food inventory is not population.
## Sampling, path travel, capture and actual payments remain world authority.
const Balance = preload("res://src/simulation/strategic_balance_catalog.gd")
const M71 = preload("res://src/simulation/strategic_economy_m71.gd")
const Currency = preload("res://src/simulation/strategic_currency.gd")
const VERSION := Currency.VERSION
const TICKS_PER_SECOND := 20
const RESOURCE_KEYS := ["MATERIAL"]
const RESOURCE_LABELS := {"MATERIAL":"金币"}
const INITIAL_STOCK := {"FOOD":0, "MATERIAL":650, "ESSENCE":0}
const DEBUG_STOCK := {"FOOD":0, "MATERIAL":7800, "ESSENCE":0}
const GATHER_TICKS := 30
const ESSENCE_GATHER_TICKS := 100
const CARGO := {"FOOD":0, "MATERIAL":10, "ESSENCE":0}
const ESSENCE_WORKER_CAP := 3
const SOURCE_STOCK := {"FOOD":0, "MATERIAL":45000, "ESSENCE":0}
const BUILDING_COSTS := {
	"SHOP":Balance.WORLD_BUILDINGS.SHOP.cost,
	"BASE":Balance.BUILDINGS.BASE.cost,
	"BARRACKS":Balance.BUILDINGS.BARRACKS.cost,
	"RANGE":Balance.BUILDINGS.RANGE.cost,
	"TOWER":Balance.BUILDINGS.TOWER.cost,
	"FOUNDRY":Balance.BUILDINGS.FOUNDRY.cost,
	"ALTAR":Balance.BUILDINGS.ALTAR.cost,
	"WORKSHOP":Balance.BUILDINGS.WORKSHOP.cost,
	"DRAGON_ROOST":Balance.BUILDINGS.DRAGON_ROOST.cost,
	"ESSENCE_MINE":Balance.BUILDINGS.ESSENCE_MINE.cost,
}
const TECH_COSTS := {
	"ATTACK":Balance.TECH_RANKS.ATTACK[0].cost,
	"ARMOR":Balance.TECH_RANKS.ARMOR[0].cost,
	"SPECIALTY":Balance.TECH_RANKS.SPECIALTY[0].cost,
}
const TOWER_UPGRADE := {"target_tier":2,"cost":{"FOOD":0,"MATERIAL":320,"ESSENCE":0},"duration_ticks":500,"max_hp":1350,"armor":6}
const SITE_DEFENSE_REBUILD := {"cost":{"FOOD":0,"MATERIAL":160,"ESSENCE":0},"work":300}

static func gather_ticks(resource: String) -> int:
	return ESSENCE_GATHER_TICKS if resource == "ESSENCE" else 45 if resource == "MATERIAL" else GATHER_TICKS

static func building_stats(type: String, tier: int = 1) -> Dictionary: return Balance.building(type, tier)
static func building_duration_ticks(type: String) -> int: return int(Balance.WORLD_BUILDINGS.get(type, {}).get("duration_ticks", 0))
static func tech_quote(track: String, rank: int) -> Dictionary: return Balance.tech_quote(track, rank)

static func cargo(resource: String) -> int:
	return int(CARGO.get(resource,0))

static func source_stock(resource: String) -> int:
	return int(SOURCE_STOCK.get(resource,0))

static func worker_capacity(resource: String)->int:return M71.worker_capacity(resource)

static func get_catalog() -> Dictionary:
	return {"version":VERSION,"currency_version":Currency.VERSION,"currency_key":Currency.KEY,"currency_label":Currency.LABEL,"collection_version":M71.VERSION,"resource_keys":RESOURCE_KEYS.duplicate(),"resource_labels":RESOURCE_LABELS.duplicate(true),"initial_stock":INITIAL_STOCK.duplicate(true),"debug_stock":DEBUG_STOCK.duplicate(true),"gather_ticks":GATHER_TICKS,"essence_gather_ticks":ESSENCE_GATHER_TICKS,"cargo":CARGO.duplicate(true),"essence_worker_cap":0,"source_worker_capacity":{"MATERIAL":0},"mineral_upkeep":[M71.upkeep(50),M71.upkeep(51),M71.upkeep(81)],"source_stock":SOURCE_STOCK.duplicate(true),"building_costs":BUILDING_COSTS.duplicate(true),"tech_costs":TECH_COSTS.duplicate(true),"tower_upgrade":TOWER_UPGRADE.duplicate(true)}
