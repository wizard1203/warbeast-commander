class_name WarbandCatalog
extends RefCounted
## M3's closed, immutable graybox recipe and soldier-type catalog.
## Return fresh dictionaries so callers cannot mutate catalog data.

const TYPE_HINGE_GUARD := "hinge_guard"
const TYPE_BRIGHT_CROSSBOW := "bright_crossbow"
const RECIPE_HINGE_GUARD := "recipe:warband:hinge_guard:v1"
const RECIPE_BRIGHT_CROSSBOW := "recipe:warband:bright_crossbow:v1"
const HINGE_GUARD_TYPE := TYPE_HINGE_GUARD
const BRIGHT_CROSSBOW_TYPE := TYPE_BRIGHT_CROSSBOW
const HINGE_GUARD_RECIPE_ID := RECIPE_HINGE_GUARD
const BRIGHT_CROSSBOW_RECIPE_ID := RECIPE_BRIGHT_CROSSBOW
const MEMBER_COUNT := 8


static func recipe_for_id(recipe_id: String) -> Dictionary:
	match recipe_id:
		RECIPE_HINGE_GUARD:
			return {
				"recipe_id": RECIPE_HINGE_GUARD,
				"type_id": TYPE_HINGE_GUARD,
				"unit_type": TYPE_HINGE_GUARD,
				"label": "合页卫",
				"display_name": "合页卫",
				"cost": {"FOOD": 6, "MATERIAL": 4},
				"duration_ticks": 120,
				"member_count": MEMBER_COUNT,
			}
		RECIPE_BRIGHT_CROSSBOW:
			return {
				"recipe_id": RECIPE_BRIGHT_CROSSBOW,
				"type_id": TYPE_BRIGHT_CROSSBOW,
				"unit_type": TYPE_BRIGHT_CROSSBOW,
				"label": "明契弩列",
				"display_name": "明契弩列",
				"cost": {"FOOD": 5, "MATERIAL": 6},
				"duration_ticks": 140,
				"member_count": MEMBER_COUNT,
			}
		_:
			return {}


static func stats_for_type(type_id: String) -> Dictionary:
	match type_id:
		TYPE_HINGE_GUARD:
			return {
				"type_id": TYPE_HINGE_GUARD,
				"unit_type": TYPE_HINGE_GUARD,
				"label": "合页卫",
				"display_name": "合页卫",
				"max_hp": 100,
				"damage": 20,
				"attack_range": 38,
				"attack_cooldown_ticks": 12,
			}
		TYPE_BRIGHT_CROSSBOW:
			return {
				"type_id": TYPE_BRIGHT_CROSSBOW,
				"unit_type": TYPE_BRIGHT_CROSSBOW,
				"label": "明契弩列",
				"display_name": "明契弩列",
				"max_hp": 80,
				"damage": 14,
				"attack_range": 120,
				"attack_cooldown_ticks": 18,
			}
		_:
			return {}
