extends RefCounted
const ArmySupport=preload("res://src/simulation/strategic_army_support.gd")
const TroopSkillsV4=preload("res://src/simulation/strategic_troop_skills_v4.gd")
## Pure supplied-observation animation. Tick alone never starts walking,
## gathering, attacking or healing. No timer, RNG, authority or input lives here.

const ACTION_TICKS := {"ATTACK": 8, "HEAL": 12, "POTION": 14, "SKILL_CLEAVE": 14, "SKILL_RECOVER": 16, "SKILL_RALLY": 16}
const HeroCatalog = preload("res://src/simulation/strategic_hero_catalog.gd")

static func _observed_skill(unit: Dictionary, id: String) -> bool:
	return not _troop_skill_v4(unit,id).is_empty() or HeroCatalog.SKILLS.has(id) or (ArmySupport.CATALOG.has(str(unit.get("unit_type",""))) and ArmySupport.CATALOG[str(unit.unit_type)].id==id) or (bool(unit.get("neutral",false)) and not id.is_empty() and str(unit.get("neutral_skill",{}).get("id",""))==id)

static func _troop_skill_v4(unit: Dictionary, id: String) -> Dictionary:
	if bool(unit.get("neutral",false)) or unit.get("unit_type","") in ["hero","worker"]: return {}
	var skill := TroopSkillsV4.ability_for(str(unit.get("unit_type","")))
	if skill.is_empty() or skill.id!=id: return {}
	skill["level"]=1;skill["passive"]=false;skill["ultimate"]=false
	skill["target_mode"]="SELF" if skill.delivery=="SELF_BUFF" else "POINT"
	return skill


static func for_unit(unit: Dictionary, tick: int) -> Dictionary:
	var direction := Vector2.RIGHT if unit.get("side") == "PLAYER" else Vector2.LEFT
	var moving := false
	var action := "IDLE"
	var phase := 0.0
	var target: Vector2 = Vector2(unit.get("position", Vector2i.ZERO))
	if int(unit.get("hp", 0)) <= 0 or not bool(unit.get("alive", true)):
		return {"action": "FALLEN", "phase": 0.0, "moving": false, "step": 0.0, "direction": direction, "target_position": target}
	if unit.get("unit_type") == "worker":
		var delta: Vector2 = Vector2(unit.get("movement_delta", Vector2i.ZERO))
		moving = delta != Vector2.ZERO
		if moving: direction = delta.normalized()
		var observed := str(unit.get("action_kind", "IDLE"))
		var attack_age := tick-int(unit.get("last_action_tick",-1000000))
		# The world derives these observations from actual work/station state.
		# Waiting, blocked travel and reserve never wave a tool or walk in place.
		if observed == "ATTACK" and attack_age >= 0 and attack_age < 8:
			action = "ATTACK"
			phase = float(attack_age)/8.0
			target = Vector2(unit.get("last_action_target_position",unit.get("position",Vector2i.ZERO)))
			if target != Vector2(unit.get("position",Vector2i.ZERO)): direction = (target-Vector2(unit.position)).normalized()
		elif observed in ["HARVEST", "MINE", "BUILD"]:
			action = observed
			phase = float(posmod(tick, 16)) / 16.0
			target = Vector2(unit.get("action_position", unit.get("position", Vector2i.ZERO)))
			if target != Vector2(unit.get("position", Vector2i.ZERO)): direction = (target - Vector2(unit["position"])).normalized()
		elif moving:
			action = "CARRY" if int(unit.get("cargo_amount", 0)) > 0 else "WALK"
	else:
		moving = int(unit.get("last_move_tick", -1000000)) == tick
		var delta: Vector2 = Vector2(unit.get("last_move_direction", Vector2i.ZERO))
		if delta != Vector2.ZERO: direction = delta.normalized()
		var observed := str(unit.get("last_action_kind", ""))
		var age := tick - int(unit.get("last_action_tick", -1000000))
		var skill_age := tick - int(unit.get("last_skill_tick", -1000000))
		var skill_id := str(unit.get("last_skill_id", ""))
		if skill_age >= 0 and skill_age < 14 and _observed_skill(unit,skill_id):
			observed = "SKILL_" + skill_id
			age = skill_age
		var duration := int(ACTION_TICKS.get(observed, 0))
		if duration == 0 and observed.begins_with("SKILL_") and _observed_skill(unit,observed.trim_prefix("SKILL_")): duration = 14
		if duration > 0 and age >= 0 and age < duration:
			action = observed
			phase = float(age) / float(duration)
			target = Vector2(unit.get("last_action_target_position", unit.get("position", Vector2i.ZERO)))
			if skill_age >= 0 and skill_age < 14 and _observed_skill(unit,skill_id): target = Vector2(unit.get("last_skill_target_position", target))
			if target != Vector2(unit.get("position", Vector2i.ZERO)): direction = (target - Vector2(unit["position"])).normalized()
		elif moving: action = "WALK"
	var step := sin(float(posmod(tick, 12)) / 12.0 * TAU) if moving else 0.0
	var result := {"action": action, "phase": phase, "moving": moving, "step": step, "direction": direction, "target_position": target}
	# Only factual walking needs the ordered atlas playback clock. Idle and
	# fallen observations retain their original tick-invariant value contract.
	if action == "WALK": result["animation_tick"] = tick
	if action.begins_with("SKILL_"):
		var independent := action.trim_prefix("SKILL_") == str(unit.get("last_skill_id", "")) and tick - int(unit.get("last_skill_tick", -1000000)) < 14
		var rank := clampi(int(unit.get("last_skill_level", 1) if independent else unit.get("last_action_skill_level", 1)), 1, 3)
		result["skill"] = HeroCatalog.skill_at_level(action.trim_prefix("SKILL_"), rank)
		if result.skill.is_empty():result.skill=_troop_skill_v4(unit,action.trim_prefix("SKILL_"))
		if result.skill.is_empty():result.skill=ArmySupport.visual_skill(action.trim_prefix("SKILL_"))
		# An invalid historical hero rank is not a neutral spell. Only the
		# observed neutral identity may fall back to its own detached recipe.
		var neutral_skill: Dictionary = unit.get("neutral_skill", {})
		if result["skill"].is_empty() and bool(unit.get("neutral",false)) and str(neutral_skill.get("id",""))==action.trim_prefix("SKILL_"):
			var skill: Dictionary = neutral_skill.duplicate(true)
			skill.merge({"effect":str(skill.get("control","DAMAGE")),"target_mode":"POINT","delivery":"AREA","level":1,"radius":int(skill.get("range",0))},true)
			result.skill = skill
		if not result["skill"].is_empty(): result["skill"]["radius"] = int(unit.get("last_skill_radius", result["skill"].get("radius", 0)) if independent else unit.get("last_action_radius", result["skill"].get("radius", 0)))
	return result
