class_name CampCatalog
extends RefCounted
## Closed M4 fixed-slot catalog. Every public dictionary is detached.

const WORKSHOP_RECIPE_ID := "recipe:building:quartermaster_workshop:v1"
const WORKSHOP_SLOT_ID := "slot:quartermaster_workshop:v1"
const FOUNDATION_ID := "foundation:quartermaster_workshop:v1"
const WORKSHOP_POSITION := Vector2i(230, 420)
const FOUNDATION_RADIUS := 26
const WORK_REQUIRED := 200
const WORK_OFFSETS: Array[Vector2i] = [
	Vector2i(-60, -60), Vector2i(-60, -36), Vector2i(-60, -12),
	Vector2i(-60, 12), Vector2i(-60, 36), Vector2i(-60, 60),
	Vector2i(-36, -60), Vector2i(-12, -60), Vector2i(12, -60),
	Vector2i(36, -60), Vector2i(60, -36), Vector2i(60, 36),
]


static func recipe_for_id(recipe_id: String) -> Dictionary:
	if recipe_id != WORKSHOP_RECIPE_ID:
		return {}
	return {
		"recipe_id": WORKSHOP_RECIPE_ID,
		"kind": "BUILDING",
		"slot_id": WORKSHOP_SLOT_ID,
		"type_id": "quartermaster_workshop",
		"unit_type": "",
		"label": "军需工坊",
		"display_name": "军需工坊",
		"cost": {"FOOD": 2, "MATERIAL": 8},
		"duration_ticks": WORK_REQUIRED,
		"work_required": WORK_REQUIRED,
		"member_count": 0,
	}


static func get_slot(slot_id: String = WORKSHOP_SLOT_ID) -> Dictionary:
	if slot_id != WORKSHOP_SLOT_ID:
		return {}
	return {
		"slot_id": WORKSHOP_SLOT_ID,
		"foundation_id": FOUNDATION_ID,
		"position": WORKSHOP_POSITION,
		"radius": FOUNDATION_RADIUS,
		"recipe_id": WORKSHOP_RECIPE_ID,
	}


static func work_position(worker_index: int) -> Vector2i:
	assert(worker_index >= 0 and worker_index < WORK_OFFSETS.size())
	return WORKSHOP_POSITION + WORK_OFFSETS[worker_index]
