extends RefCounted
## JSON has one number type; the arena authority deliberately requires ints.
## Decode only schema integer fields, never prices, damage or runtime state.
static func decode(config: Dictionary) -> Dictionary:
	var result := config.duplicate(true)
	for key: String in ["seed","limit_seconds"]:
		if result.has(key): result[key]=_integer(result[key])
	for side: String in ["PLAYER","AI"]:
		for hero: Dictionary in result.get("sides",{}).get(side,{}).get("heroes",[]):
			if hero.has("level"): hero["level"]=_integer(hero.level)
			if hero.has("skill_ranks"):
				for index: int in range(hero.skill_ranks.size()): hero.skill_ranks[index]=_integer(hero.skill_ranks[index])
		for troop: Dictionary in result.get("sides",{}).get(side,{}).get("troops",[]):
			if troop.has("count"): troop["count"]=_integer(troop.count)
	return result

static func _integer(value: Variant) -> Variant:
	if typeof(value)==TYPE_FLOAT and is_finite(value) and floor(value)==value and abs(value)<=9007199254740991.0: return int(value)
	return value
