class_name StrategicFieldObjectiveReadout
extends RefCounted
## Read-only projection of the host's finite discovery ledger. These marks
## never participate in capture, hit testing, pathing or reward settlement.

const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const SIDES := ["PLAYER", "AI", "AI_2", "AI_3"]
const COLORS := {"SUPPLY":Color("dfbd74"), "ARMORY":Color("9db7cd"), "RELIC":Color("c3a1df")}

static func read(facts: Dictionary, site_id: String) -> Dictionary:
	var objective: Dictionary = {}
	for record: Dictionary in facts.get("field_objectives", []):
		if str(record.get("site_id", "")) == site_id: objective = record.duplicate(true); break
	if objective.is_empty() or not COLORS.has(str(objective.get("kind", ""))): return {}
	var owner := ""
	for site: Dictionary in facts.get("sites", []):
		if str(site.get("id", "")) == site_id: owner = str(site.get("owner", "")); break
	var state := str(objective.get("state", "AVAILABLE"))
	var first_owner := str(objective.get("first_owner", ""))
	objective["owner"] = owner
	objective["state_caption"] = {"AVAILABLE":"尚未搜寻 · 首次完整占领领取", "PENDING_HERO":"等待长官领取", "CLAIMED":"已搜寻 · 奖励仅一次"}.get(state, "未知")
	objective["reward_caption"] = package_caption(objective.get("reward", {}))
	objective["claimant_caption"] = side_caption(first_owner)
	objective["pending_lost"] = state == "PENDING_HERO" and owner != first_owner
	objective["actual_caption"] = package_caption(objective.get("actual_grant", {})) if state == "CLAIMED" else ""
	objective["recipient_caption"] = ""
	if not str(objective.get("recipient_id", "")).is_empty():
		objective.recipient_caption = "己方英雄"
		for hero: Dictionary in facts.get("heroes", {}).get("officers", []):
			if str(hero.get("unit_id", hero.get("id", ""))) != str(objective.recipient_id): continue
			var name := str(hero.get("name", "")).strip_edges()
			if not name.is_empty(): objective.recipient_caption = name
			break
	var detail := "%s · %s\n首次探索：%s；每局仅一次，夺回不重复领取。" % [str(objective.get("label", "探索据点")), objective.state_caption, objective.reward_caption]
	if state == "PENDING_HERO":
		detail += "\n保留给%s：%s。" % [objective.claimant_caption, "先夺回据点，再带存活地面长官进入180范围" if objective.pending_lost else "带一位存活地面长官进入180范围，自动领取"]
	elif state == "CLAIMED":
		detail += "\n%s已实际获得：%s。" % [objective.claimant_caption, objective.actual_caption]
		if not str(objective.get("recipient_caption", "")).is_empty(): detail += " 领取长官：%s。" % str(objective.recipient_caption)
		var caps: Array = objective.get("actual_grant", {}).get("capped", [])
		if not caps.is_empty():
			var limits: Array[String] = []
			if "XP" in caps: limits.append("经验已达8上限")
			if "POTION" in caps: limits.append("药水已达5上限")
			detail += "\n%s；超出部分不会转换或自动使用。" % "；".join(limits)
	if str(objective.kind) == "RELIC" and state != "CLAIMED": detail += "\n经验上限8（最高3级），药水持有上限5；不回血、不自动喝药。"
	objective["detail_caption"] = detail
	return objective

static func package_caption(package: Dictionary) -> String:
	var parts: Array[String] = []
	for pair: Array in [["FOOD","粮食"], ["MATERIAL","材料"], ["XP","经验"], ["POTION","药水"], ["skill_points","技能点"]]:
		var amount := int(package.get(pair[0], 0))
		if amount > 0: parts.append("%s +%d" % [pair[1], amount])
	return "、".join(parts) if not parts.is_empty() else "0（已达持有上限）"

static func side_caption(side: String) -> String:
	return "我方" if side == "PLAYER" else "玩家%d" % (SIDES.find(side) + 1) if side in SIDES else "尚无归属"

static func event_caption(event: Dictionary) -> String:
	return "%s · 实际获得 %s%s" % [str(event.get("label", "探索据点")), package_caption(event.get("actual_grant", {})), "（部分已达上限）" if not event.get("actual_grant", {}).get("capped", []).is_empty() else ""]

static func draw_marker(canvas: CanvasItem, point: Vector2, objective: Dictionary, compact: bool = false) -> void:
	if objective.is_empty(): return
	var state := str(objective.get("state", "AVAILABLE"))
	var color: Color = COLORS.get(str(objective.get("kind", "")), Color.WHITE)
	var radius := 7.0 if compact else 13.0
	canvas.draw_circle(point, radius, Color("101e23", 0.92))
	canvas.draw_arc(point, radius, 0, TAU, 20, Color(color, 0.45 if state == "CLAIMED" else 0.95), 1.5)
	Icons.draw_symbol(canvas, str(objective.get("icon", "hero")), point, Color("72817c") if state == "CLAIMED" else color, 0.26 if compact else 0.46)
	var badge := point + Vector2(radius * 0.72, radius * 0.72)
	if state == "PENDING_HERO":
		canvas.draw_circle(badge, 4, Color("e4b85f"))
		canvas.draw_line(badge + Vector2(0,-2.5), badge + Vector2(0,1), Color("17212a"), 1.5)
		canvas.draw_circle(badge + Vector2(0,2.5), 0.7, Color("17212a"))
	elif state == "CLAIMED":
		canvas.draw_line(badge + Vector2(-3,0), badge + Vector2(-1,2), Color("99ba9a"), 1.6)
		canvas.draw_line(badge + Vector2(-1,2), badge + Vector2(4,-3), Color("99ba9a"), 1.6)

static func draw_minimap(canvas: CanvasItem, point: Vector2, objective: Dictionary, owner_color: Color) -> void:
	var state := str(objective.get("state", "AVAILABLE"))
	var color: Color = COLORS.get(str(objective.get("kind", "")), Color.WHITE)
	var shape := PackedVector2Array()
	match str(objective.get("kind", "")):
		"SUPPLY": shape = PackedVector2Array([point+Vector2(-3,-3),point+Vector2(3,-3),point+Vector2(3,3),point+Vector2(-3,3)])
		"ARMORY": shape = PackedVector2Array([point+Vector2(0,-4),point+Vector2(4,3),point+Vector2(-4,3)])
		"RELIC": shape = PackedVector2Array([point+Vector2(0,-4),point+Vector2(4,0),point+Vector2(0,4),point+Vector2(-4,0)])
	if shape.is_empty(): return
	canvas.draw_colored_polygon(shape, owner_color)
	shape.append(shape[0])
	canvas.draw_polyline(shape, Color(color, 0.4 if state == "CLAIMED" else 1.0), 1)
	if state == "PENDING_HERO": canvas.draw_circle(point, 1.4, Color("f1bd61"))
	elif state == "CLAIMED": canvas.draw_line(point+Vector2(-2,0),point+Vector2(2,0),Color("162922"),1)
