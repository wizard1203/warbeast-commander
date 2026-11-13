class_name TacticalReadout
extends RefCounted
## Pure presentation of current public facts. No authority writes or model calls.

const FormationLibrary = preload("res://src/simulation/formation_library.gd")
const WarbandCatalog = preload("res://src/simulation/warband_catalog.gd")
const BaseObjectives = preload("res://src/simulation/base_objectives.gd")
const ARRIVAL_RADIUS := 16


static func project_warband(snapshot: Dictionary, warband_id: String) -> Dictionary:
	var warband := _find_by_id(snapshot.get("warbands", []), warband_id)
	if warband.is_empty():
		return {}
	var soldiers_by_id := _index_soldiers(snapshot.get("soldiers", []))
	var slots := FormationLibrary.get_world_slots(
		str(warband.get("formation", "")),
		Vector2i(warband.get("anchor", Vector2i.ZERO)),
		str(warband.get("facing", FormationLibrary.FACING_EAST))
	)
	var member_count := 0
	var living_count := 0
	var total_hp := 0
	var total_max_hp := 0
	var arrived_count := 0
	var seen_members := {}
	for member_id: String in warband.get("member_ids", []):
		if seen_members.has(member_id) or not soldiers_by_id.has(member_id):
			continue
		seen_members[member_id] = true
		var soldier: Dictionary = soldiers_by_id[member_id]
		if str(soldier.get("warband_id", "")) != warband_id:
			continue
		member_count += 1
		# Fallen members remain in M6's history and in the initial-health total.
		total_max_hp += maxi(0, int(soldier.get("max_hp", 0)))
		var hp := maxi(0, int(soldier.get("hp", 0)))
		total_hp += hp
		if hp <= 0:
			continue
		living_count += 1
		var member_index := int(soldier.get("member_index", -1))
		if member_index < 0 or member_index >= slots.size():
			continue
		var offset := Vector2i(soldier.get("position", Vector2i.ZERO)) - slots[member_index]
		if offset.x * offset.x + offset.y * offset.y <= ARRIVAL_RADIUS * ARRIVAL_RADIUS:
			arrived_count += 1
	return {
		"role_label": _role_label(str(warband.get("unit_type", ""))),
		"living_count": living_count,
		"member_count": member_count,
		"total_hp": total_hp,
		"total_max_hp": total_max_hp,
		"arrived_count": arrived_count,
		"status_label": _status_label(snapshot, warband, living_count, arrived_count),
	}


static func objective_advice(snapshot: Dictionary) -> String:
	match str(snapshot.get("outcome", BaseObjectives.OUTCOME_ONGOING)):
		BaseObjectives.OUTCOME_PLAYER_VICTORY:
			return "胜利：敌方统御兽撤离窗口结束。"
		BaseObjectives.OUTCOME_PLAYER_DEFEAT:
			return "战败：己方统御兽撤离窗口结束。"
		BaseObjectives.OUTCOME_DRAW:
			return "平局：双方统御兽同时撤离。"
	var player_base := _find_by_id(snapshot.get("bases", []), BaseObjectives.PLAYER_BASE_ID)
	var enemy_base := _find_by_id(snapshot.get("bases", []), BaseObjectives.AI_BASE_ID)
	if player_base.is_empty() or enemy_base.is_empty():
		return "暂无完整据点战况。"
	if str(player_base.get("state", "")) == BaseObjectives.STATE_SUPPRESSED:
		if bool(player_base.get("rescue_used", false)):
			return "己方据点受压；救援机会已用尽。\n请留意双方撤离倒计时。"
		if bool(player_base.get("rescue_contested", false)):
			return "己方据点受压，圈内仍有敌兵。\n先清圈；有敌军时不能救援。"
		var eligible := int(player_base.get("rescue_eligible_warbands", 0))
		if eligible < 2:
			return "己方据点受压，现场战团%d/2。\n全军回防，需两团各半数进圈。" % eligible
		var progress := clampi(int(player_base.get("rescue_progress_ticks", 0)) * 100 / BaseObjectives.RESCUE_TICKS, 0, 100)
		return "己方据点救援%d%%。\n保持两团守圈，不让敌军进入。" % progress
	if str(enemy_base.get("state", "")) == BaseObjectives.STATE_SUPPRESSED:
		return "敌方据点已受压。\n守住撤离窗口，阻止敌方救援。"
	var player_living := _side_living_count(snapshot, BaseObjectives.SIDE_PLAYER)
	var enemy_living := _side_living_count(snapshot, BaseObjectives.SIDE_AI)
	if player_living == 0:
		return "友军战团已耗尽；据点仍在。\n可继续招募战团反攻。"
	if enemy_living == 0 and not enemy_base.is_empty():
		return "敌军战团已清场。\n全军压制敌方统御兽，守到撤离。"
	if str(snapshot.get("phase", "")) == "PREPARATION":
		return "筹备：招募合页卫搭配明契弩列。\n就绪后全军迎敌，再开始交战。"
	if player_living < enemy_living:
		return "当前存活：我方%d / 敌方%d。\n兵员较少；可招募或全军回防。" % [player_living, enemy_living]
	return "当前存活：我方%d / 敌方%d。\n军团配合推进，留意据点与回防。" % [player_living, enemy_living]


static func compact_name(warband_id: String) -> String:
	if warband_id in ["player_alpha", "ai_alpha"]:
		return "先锋"
	if warband_id in ["player_bravo", "ai_bravo"]:
		return "后阵"
	if warband_id.begins_with("player_recruit_"):
		var suffix := warband_id.trim_prefix("player_recruit_")
		if suffix.is_valid_int():
			return "援军%02d" % int(suffix)
	return "战团"


static func _role_label(unit_type: String) -> String:
	match unit_type:
		WarbandCatalog.HINGE_GUARD_TYPE:
			return "前排近战"
		WarbandCatalog.BRIGHT_CROSSBOW_TYPE:
			return "后排远程"
	return "战团"


static func _status_label(snapshot: Dictionary, warband: Dictionary, living_count: int, arrived_count: int) -> String:
	if living_count == 0:
		return "战团耗尽"
	if str(snapshot.get("outcome", BaseObjectives.OUTCOME_ONGOING)) != BaseObjectives.OUTCOME_ONGOING:
		return "战斗结束"
	if str(snapshot.get("phase", "")) == "PREPARATION":
		return "筹备就绪" if arrived_count == living_count else "筹备重整"
	match str(warband.get("intent", "HOLD")):
		"ATTACK_BASE":
			return "压制据点"
		"FOCUS":
			return "集火迎敌"
		"RETREAT":
			return "撤离中"
		"MOVE":
			if warband.get("anchor") != warband.get("destination"):
				return "机动中"
	return "守位戒备" if arrived_count == living_count else "阵型重整"


static func _find_by_id(entries: Array, entry_id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if str(entry.get("id", "")) == entry_id:
			return entry
	return {}


static func _index_soldiers(soldiers: Array) -> Dictionary:
	var result := {}
	for soldier: Dictionary in soldiers:
		result[str(soldier.get("id", ""))] = soldier
	return result


static func _side_living_count(snapshot: Dictionary, side: String) -> int:
	var count := 0
	for warband: Dictionary in snapshot.get("warbands", []):
		if str(warband.get("side", "")) == side:
			count += int(project_warband(snapshot, str(warband.get("id", ""))).get("living_count", 0))
	return count
