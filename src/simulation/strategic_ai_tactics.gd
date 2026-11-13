extends RefCounted
## Strategy is seeded independently of difficulty. Emergency defense is not
## a strategic pivot; actual pivots are bounded to two at45s intervals.
const IDS := ["VANGUARD_RUSH","RAIDER_HARASS","EXPANSION_BOOM","TECH_TIMING","CREEP_ESSENCE_CONTROL","SIEGE_PUSH","SPLIT_CAPTURE","DEFENSIVE_COUNTER"]
var id := ""
var pivots := 0
var last_pivot_tick := 0

func _init(seed: int = 1701, side: String = "AI", faction: String = "HUMAN") -> void:
	id = IDS[absi(hash("%d:%s:%s:tactics" % [seed,side,faction])) % IDS.size()]

func consider(tick: int, own_power: int, enemy_power: int, has_essence: bool) -> void:
	if pivots >= 2 or tick-last_pivot_tick < 900: return
	var next := id
	if enemy_power > own_power * 2: next = "DEFENSIVE_COUNTER"
	elif has_essence and id in ["EXPANSION_BOOM","SPLIT_CAPTURE"]: next = "CREEP_ESSENCE_CONTROL"
	if next != id:
		id = next
		pivots += 1
		last_pivot_tick = tick

func timing() -> Dictionary:
	match id:
		"VANGUARD_RUSH": return {"pressure_ticks":240,"assault_ticks":1000,"forced_assault_ticks":1600}
		"RAIDER_HARASS": return {"pressure_ticks":240,"assault_ticks":1600,"forced_assault_ticks":2400}
		"EXPANSION_BOOM": return {"pressure_ticks":800,"assault_ticks":2000,"forced_assault_ticks":2800}
		"SPLIT_CAPTURE": return {"pressure_ticks":-1,"assault_ticks":2000,"forced_assault_ticks":2800}
		"TECH_TIMING": return {"pressure_ticks":800,"assault_ticks":1800,"forced_assault_ticks":2600}
		"SIEGE_PUSH": return {"pressure_ticks":1000,"assault_ticks":2000,"forced_assault_ticks":2800}
		"DEFENSIVE_COUNTER": return {"pressure_ticks":1200,"assault_ticks":2200,"forced_assault_ticks":3000}
	return {"pressure_ticks":600,"assault_ticks":1600,"forced_assault_ticks":2400}

func role_weight(role: String) -> float:
	match id:
		"VANGUARD_RUSH": return 1.6 if role == "FRONTLINE" else 0.8
		"RAIDER_HARASS": return 1.6 if role == "CAVALRY" else 1.0
		"TECH_TIMING": return 1.5 if role in ["HEAVY","SUPPORT"] else 1.0
		"SIEGE_PUSH": return 1.7 if role in ["SIEGE","HEAVY","FLYING"] else 1.0
		"DEFENSIVE_COUNTER": return 1.35 if role in ["RANGED","SUPPORT"] else 1.0
	return 1.0

func get_state() -> Dictionary:
	return {"id":id,"pivots":pivots,"last_pivot_tick":last_pivot_tick}
