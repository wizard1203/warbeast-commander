extends RefCounted
## Observation eligibility only; no vision simulation, presentation dependency
## or side effects. Absent masks preserve this version's public-battle model.
static func can_observe(body:Dictionary,side:String)->bool:
	if not bool(body.get("visible",true)) or bool(body.get("hidden",false)):return false
	return side in body.visible_to if body.get("visible_to") is Array else true
