class_name StrategicCaptureReadout
extends RefCounted
## Detached territorial observation only. Points, ownership and settled counts
## come from the supplied site. Physical counts explain preparation/range but
## never update capture authority, grant capacity or dispatch a soldier.

const SIDES := ["PLAYER", "AI", "AI_2", "AI_3"]
const RUNNING_STATES := ["CAPTURING", "NEUTRALIZING", "RESTORING"]
const FieldObjectives = preload("res://src/presentation/strategic_field_objective_readout.gd")


static func read_all(facts: Dictionary, subject_id: String = "", subject_kind: String = "ARMY", view_side: String = "PLAYER") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for site: Dictionary in facts.get("sites", []):
		var readout := read_site(facts, str(site.get("id", "")), subject_id, subject_kind, view_side)
		if not readout.is_empty(): result.append(readout)
	return result


static func read_site(facts: Dictionary, id: String, subject_id: String = "", subject_kind: String = "ARMY", view_side: String = "PLAYER") -> Dictionary:
	var site: Dictionary = {}
	for value: Dictionary in facts.get("sites", []):
		if str(value.get("id", "")) == id:
			site = value
			break
	if site.is_empty() or not _point(site.get("position")): return {}
	var maximum := int(site.get("max_progress", site.get("threshold", 0)))
	var radius := float(site.get("radius", 0))
	if maximum <= 0 or not is_finite(radius) or radius <= 0: return {}
	var progress := int(site.get("progress", 0))
	var owner := str(site.get("owner", ""))
	var capture_side := str(site.get("capture_side", ""))
	var supplied_presence: Dictionary = site.get("presence", {})
	var presence := {"PLAYER":int(supplied_presence.get("PLAYER", 0)), "AI":int(supplied_presence.get("AI", 0))}
	var observed_presence := {"PLAYER":0, "AI":0}
	for side: String in ["AI_2", "AI_3"]:
		if supplied_presence.has(side) or _side_active(facts, side):
			presence[side] = int(supplied_presence.get(side, 0))
			observed_presence[side] = 0
	var subject_presence := 0
	var subject_count := 0
	var nearest_distance := INF
	var center := Vector2(site.position)
	for soldier: Dictionary in facts.get("soldiers", []):
		if not _military(soldier): continue
		var distance := Vector2(soldier.position).distance_to(center)
		var side := str(soldier.side)
		if not observed_presence.has(side): observed_presence[side] = 0
		if distance <= radius:
			observed_presence[side] = int(observed_presence[side]) + 1
		var selected := not subject_id.is_empty() and side == view_side and ((subject_kind == "UNIT" and str(soldier.get("id", "")) == subject_id) or (subject_kind == "ARMY" and str(soldier.get("warband_id", "")) == subject_id))
		if selected:
			subject_count += 1
			nearest_distance = minf(nearest_distance, distance)
			if distance <= radius: subject_presence += 1
	var phase := str(facts.get("phase", "PREPARATION"))
	var outcome := str(facts.get("outcome", "ONGOING"))
	var leader := _leader(presence)
	var state := "NO_TROOPS"
	if outcome != "ONGOING": state = "TERMINAL"
	elif phase != "BATTLE": state = "PREPARATION"
	elif int(site.get("neutral_guard_count", 0)) > 0: state = "GUARDED"
	elif _total(presence) == 0:
		state = "OWNED" if owner in SIDES and progress >= maximum else "NO_TROOPS"
	elif leader.is_empty(): state = "CONTESTED"
	elif not capture_side.is_empty() and capture_side != leader and progress > 0: state = "NEUTRALIZING"
	elif owner == leader and progress >= maximum: state = "OWNED"
	elif owner == leader and progress > 0: state = "RESTORING"
	else: state = "CAPTURING"
	var running := state in RUNNING_STATES
	var remaining := progress if state == "NEUTRALIZING" else maxi(maximum - progress, 0)
	var tick_seconds := maxf(float(facts.get("tick_ms", 50)), 0) / 1000.0
	var seconds_remaining := remaining * tick_seconds if running else -1.0
	var progress_caption := "旧方点 %d/%d" % [progress, maximum] if state == "NEUTRALIZING" else "占领点 %d/%d" % [progress, maximum]
	var captions := {"GUARDED":"先清除%d名野怪守军" % int(site.get("neutral_guard_count", 0)), "PREPARATION":"筹备 · 开战后计时", "TERMINAL":"战斗结束 · 占领冻结", "NO_TROOPS":"无人入圈 · 占领暂停", "CONTESTED":"人数平局 · 进度暂停", "OWNED":"已占领", "RESTORING":"巩固己方占领点" if leader == view_side else "敌军巩固占领点", "NEUTRALIZING":"削减敌方占领点" if leader == view_side else "敌军削减己方点数", "CAPTURING":"我方正在占领" if leader == view_side else "敌军正在占领"}
	var outside := subject_count > 0 and subject_presence == 0
	var distance_to_circle := maxf(nearest_distance - radius, 0) if subject_count > 0 else -1.0
	var range_caption := "占领范围 %.0f · 仅存活地面兵员计数；工人与空中单位不占领" % radius
	if bool(facts.get("outpost_mode",false)):
		range_caption = "占领范围 %.0f · 仅存活地面兵员计数；空中单位不占领" % radius
	if outside: range_caption += "；所选兵在圈外，最近还需 %.1f" % distance_to_circle
	elif subject_count > 0: range_caption += "；所选部队 %d 名在圈内" % subject_presence
	var display_presence: Dictionary = observed_presence if state == "PREPARATION" else presence
	var presence_caption := "现场 我 %d : 敌 %d" % [int(display_presence.PLAYER), int(display_presence.AI)] if state == "PREPARATION" else "我 %d : 敌 %d" % [int(presence.PLAYER), int(presence.AI)]
	if view_side == "AI" and display_presence.size() == 2:
		presence_caption = ("现场 " if state == "PREPARATION" else "") + "我 %d : 敌 %d" % [int(display_presence.AI), int(display_presence.PLAYER)]
	if display_presence.size() > 2:
		var portions: Array[String] = []
		for side: String in display_presence: portions.append("%d:%d" % [SIDES.find(side) + 1, int(display_presence[side])])
		presence_caption = " · ".join(portions)
	return {
		"field_objective":FieldObjectives.read(facts, id),
		"id":id, "kind":str(site.get("kind", "")), "resource":str(site.get("resource","")), "position":site.position,
		"label":str(site.get("label", "资源根据地" if site.get("kind") == "RESOURCE" else "灵髓矿点" if site.get("resource","")=="ESSENCE" else "纯资源矿点" if site.get("kind")=="SATELLITE" else "野外村庄")),
		"radius":radius, "capacity":int(site.get("capacity",0)), "owner":owner,
		"capture_side":capture_side, "progress":progress, "max_progress":maximum,
		"ratio":clampf(float(progress) / maximum,0,1), "presence":presence,
		"observed_presence":observed_presence, "leader":leader,
		"observed_leader":_leader(observed_presence), "phase":phase, "outcome":outcome,
		"state":state, "running":running, "stage_direction":-1 if state == "NEUTRALIZING" else 1 if running else 0,
		"progress_caption":progress_caption, "status_caption":str(captions[state]),
		"owner_caption":"己方占领" if owner == view_side else "玩家%d占领" % (SIDES.find(owner) + 1) if owner in SIDES else "中立",
		"presence_caption":presence_caption, "range_caption":range_caption,
		"seconds_remaining":seconds_remaining,
		"subject_id":subject_id, "subject_kind":subject_kind, "subject_count":subject_count,
		"subject_presence":subject_presence, "subject_nearest_distance":nearest_distance if subject_count > 0 else -1.0,
		"subject_outside_range":outside, "subject_distance_to_circle":distance_to_circle,
	}


static func _leader(presence: Dictionary) -> String:
	var largest := 0
	var result := ""
	for side: String in presence:
		var count := int(presence[side])
		if count > largest: largest = count; result = side
		elif count == largest: result = ""
	return result

static func _total(presence: Dictionary) -> int:
	var result := 0
	for count: Variant in presence.values(): result += int(count)
	return result

static func _side_active(facts: Dictionary, side: String) -> bool:
	for record: Dictionary in facts.get("match_config", {}).get("sides", []):
		if record.get("side_id") == side: return true
	for soldier: Dictionary in facts.get("soldiers", []):
		if soldier.get("side") == side: return true
	return false


static func _military(soldier: Dictionary) -> bool:
	return str(soldier.get("side", "")) in SIDES and soldier.get("movement_layer", "GROUND") == "GROUND" and soldier.get("unit_type", "") != "worker" and int(soldier.get("hp", 0)) > 0 and bool(soldier.get("alive", true)) and typeof(soldier.get("position")) == TYPE_VECTOR2I


static func _point(value: Variant) -> bool:
	return (value is Vector2 or value is Vector2i) and is_finite(float(value.x)) and is_finite(float(value.y))
