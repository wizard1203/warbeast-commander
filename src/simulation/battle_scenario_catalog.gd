class_name BattleScenarioCatalog
extends RefCounted
## Closed, versioned M9 geometry. Lookups always construct detached values;
## callers cannot stretch a running encounter by mutating a shared definition.

const TRAINING_ID := "training-v1"
const FRONTIER_ID := "frontier-v1"
const STRATEGIC_ID := "strategic-v1"
const STRATEGIC_BOUNDS := Rect2i(80, 80, 3200, 2000)

const TRAINING_BOUNDS := Rect2i(80, 80, 1120, 560)
const FRONTIER_BOUNDS := Rect2i(80, 80, 2240, 1120)
const FRONTIER_LOCAL_OFFSET := Vector2i(80, 280)
const TRAINING_DEPLOYMENT_ANCHORS: Array[Vector2i] = [
	Vector2i(390, 360), Vector2i(420, 160),
	Vector2i(420, 560), Vector2i(540, 360),
]
const TRAINING_DEFENSE_ANCHORS: Array[Vector2i] = [
	Vector2i(330, 250), Vector2i(330, 470),
	Vector2i(426, 290), Vector2i(426, 410),
	Vector2i(214, 354), Vector2i(246, 276),
]


static func get_scenario(scenario_id: String) -> Dictionary:
	if scenario_id == STRATEGIC_ID:
		return {
			"id": STRATEGIC_ID, "version": 1, "display_name": "四境争夺",
			"bounds": STRATEGIC_BOUNDS, "local_offset": Vector2i.ZERO,
			"base_positions": {"PLAYER": Vector2i(400, 600), "AI": Vector2i(2880, 1480)},
			"camera_max_zoom": 5.0, "initial_zoom": 2.5, "heroes_enabled": true,
			"resource_site_count": 4, "village_count": 10,
		}
	if scenario_id not in [TRAINING_ID, FRONTIER_ID]:
		return {}
	var frontier := scenario_id == FRONTIER_ID
	var offset := FRONTIER_LOCAL_OFFSET if frontier else Vector2i.ZERO
	var deployment_anchors: Array[Vector2i] = []
	var defense_anchors: Array[Vector2i] = []
	for anchor: Vector2i in TRAINING_DEPLOYMENT_ANCHORS:
		deployment_anchors.append(anchor + offset)
	for anchor: Vector2i in TRAINING_DEFENSE_ANCHORS:
		defense_anchors.append(anchor + offset)
	return {
		"id": scenario_id,
		"version": 1,
		"display_name": "宽阔前线" if frontier else "训练场",
		"bounds": FRONTIER_BOUNDS if frontier else TRAINING_BOUNDS,
		"local_offset": offset,
		"base_positions": {
			"PLAYER": Vector2i(410, 640) if frontier else Vector2i(330, 360),
			"AI": Vector2i(1990, 640) if frontier else Vector2i(950, 360),
		},
		"spawn_anchors": {
			"player_alpha": Vector2i(340, 520) if frontier else Vector2i(260, 240),
			"player_bravo": Vector2i(340, 760) if frontier else Vector2i(260, 480),
			"ai_alpha": Vector2i(2060, 520) if frontier else Vector2i(1020, 240),
			"ai_bravo": Vector2i(2060, 760) if frontier else Vector2i(1020, 480),
		},
		"deployment_anchors": deployment_anchors,
		"defense_anchors": defense_anchors,
		"spring_position": Vector2i(1200, 640) if frontier else Vector2i(640, 360),
		"camera_max_zoom": 4.0 if frontier else 2.0,
		"initial_zoom": 2.0 if frontier else 1.0,
		"heroes_enabled": frontier,
	}
