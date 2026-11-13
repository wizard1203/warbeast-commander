extends RefCounted
## Tempo only: no difficulty-dependent prices, army caps, tactics or income.
const IDS := ["EASY", "STANDARD", "HARD"]
const DEFAULT_UI_ID := "EASY"
const DEFAULT_SIM_ID := "STANDARD"
const SHARED := {"worker_goal":10,"worker_max":18,"worker_per_base":3,"recruit_ticks":0,"military_goal":0,"max_resource_sites":0,"max_bases":0,"max_villages":0,"hero_ticks":0,"technology_ticks":0,"technology_max":3,"hero_action_ticks":0,"pressure_ticks":400,"assault_ticks":1400,"forced_assault_ticks":2200,"assault_wave_ticks":0,"assault_rest_ticks":0}
const PROFILES := {
	"EASY":{"id":"EASY","label":"简单","summary":"4秒经营决策、3秒遇袭反应，每秒最多1条宏观指令；战术与规则公平一致。","decision_ticks":80,"reaction_ticks":60,"commands_per_second":1},
	"STANDARD":{"id":"STANDARD","label":"标准","summary":"2秒经营决策、1秒遇袭反应，每秒最多2条宏观指令；随机战术。","decision_ticks":40,"reaction_ticks":20,"commands_per_second":2},
	"HARD":{"id":"HARD","label":"困难","summary":"1秒经营决策、0.4秒遇袭反应，每秒最多4条宏观指令；不增加资源或属性。","decision_ticks":20,"reaction_ticks":8,"commands_per_second":4},
}

static func is_valid(id: Variant) -> bool:
	return typeof(id) == TYPE_STRING and id in IDS

static func get_profile(id: String) -> Dictionary:
	if not is_valid(id): return {}
	var result: Dictionary = SHARED.duplicate(true)
	result.merge(PROFILES[id],true)
	return result
