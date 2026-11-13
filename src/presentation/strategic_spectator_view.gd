class_name StrategicSpectatorView
extends RefCounted
## Observation identity never becomes a command identity. No snapshot remaps,
## controller writes, Session calls, or fog-of-war claims belong in this model.

static func sides(facts: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for side: Dictionary in facts.get("match_config", facts.get("match_settings", {})).get("sides", []):
		if not str(side.get("side_id", "")).is_empty(): result.append(side.duplicate(true))
	return result

static func view_side(facts: Dictionary, requested: String) -> String:
	# Scalar predicates never expose participant dictionaries. Reading them in
	# place avoids cloning the same roster for every soldier/HUD lookup, while
	# the public sides() observation keeps its detached return contract.
	for side: Dictionary in facts.get("match_config", facts.get("match_settings", {})).get("sides", []):
		if str(side.get("side_id", "")).is_empty():continue
		if side.get("side_id") == requested: return requested
	return "PLAYER"

static func local_human(facts: Dictionary) -> bool:
	var participants: Array = facts.get("match_config",facts.get("match_settings",{})).get("sides",[])
	for side: Dictionary in participants:
		if str(side.get("side_id","")).is_empty():continue
		if side.get("side_id") == "PLAYER": return side.get("controller") == "HUMAN"
	# Retain isolated legacy presentation fixtures with no match setup.
	for side:Dictionary in participants:
		if not str(side.get("side_id","")).is_empty():return false
	return true

static func observing(facts: Dictionary, requested: String, explicit_watch: bool) -> bool:
	# An obsolete/invalid foreign selection may display the safe PLAYER
	# fallback, but it must not silently regain that human's write authority.
	return explicit_watch or requested != "PLAYER" or not local_human(facts)

static func can_command(facts: Dictionary, requested: String, explicit_watch: bool) -> bool:
	return facts.get("phase") != "LOBBY" and not observing(facts, requested, explicit_watch)

static func mutation_control(node_name: String) -> bool:
	if node_name in ["WorkSiteOption", "EssenceSiteOption", "UpgradeTowerButton", "RecruitWorkerButton", "ConfirmRecruitButton", "CancelRecruitButton", "CancelRecruitTailButton", "CancelConstructionHeadButton", "CancelConstructionTailButton", "UpgradeBaseButton", "CreateArmyButton", "TransferUnitsButton", "MergeArmiesButton", "DeleteArmyButton", "FoundryPrerequisite", "HeroAutoAttackToggle", "HeroAutoSkillsToggle", "EnterSiteCircleButton", "InformationRecruitHero", "StartBattleButton", "FormationSTEADY", "FormationLOOSE", "FormationCOLUMN", "FormationSPEAR"]: return true
	for prefix: String in ["EconomyPlus", "EconomyMinus", "HeroSkillUpgrade", "TechnologyNode_", "AIDifficultyCard_", "PlaceType_"]:
		if node_name.begins_with(prefix): return true
	if node_name == "RebuildSiteDefenseButton": return true
	return false
