extends RefCounted
## Gold-only V2 money contract. No catalog/World imports: safe at leaf quotes.
## This is a pure value adapter, never another bank or a payment authority.
const VERSION := "outposts-gold-v2"
const KEY := "MATERIAL"
const ACTIVE_KEYS := [KEY]
const LEGACY_KEYS := ["FOOD", "MATERIAL", "ESSENCE"]
const LABEL := "金币"
const ESSENCE_CONVERSION := 25

static func zero() -> Dictionary:
	return {"FOOD":0, "MATERIAL":0, "ESSENCE":0}

static func valid_legacy_cost(value: Dictionary) -> bool:
	for key: Variant in value:
		if key not in LEGACY_KEYS or typeof(value[key]) != TYPE_INT or int(value[key]) < 0: return false
	return true

static func gold(value: Dictionary) -> int:
	if not valid_legacy_cost(value): return -1
	return int(value.get("FOOD", 0)) + int(value.get(KEY, 0)) + ESSENCE_CONVERSION * int(value.get("ESSENCE", 0))

static func cost(value: Dictionary) -> Dictionary:
	# Already canonical costs are idempotent: MATERIAL is never reweighted.
	# Malformed values remain unpayable rather than becoming a free order.
	return {"FOOD":0, "MATERIAL":gold(value), "ESSENCE":0}

static func valid_gold_cost(value: Dictionary) -> bool:
	return valid_legacy_cost(value) and int(value.get("FOOD", 0)) == 0 and int(value.get("ESSENCE", 0)) == 0

static func reward(value: Dictionary) -> Dictionary:
	# Exploration rewards may also contain XP/POTION; those are not money.
	var result := value.duplicate(true)
	var money := {"FOOD":int(value.get("FOOD", 0)), "MATERIAL":int(value.get(KEY, 0)), "ESSENCE":int(value.get("ESSENCE", 0))}
	result.merge(cost(money), true)
	return result
