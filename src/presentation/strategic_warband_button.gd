class_name StrategicWarbandButton
extends Button
## Read-only composition summary. The owning arena connects this one button's
## press to its existing select/locate action; portraits never own input.
const UITheme = preload("res://src/presentation/strategic_ui_theme.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const Units = preload("res://src/presentation/heroic_pixel_units.gd")
const Pixel = preload("res://src/presentation/strategic_pixel_renderer.gd")
const UnitCatalog = preload("res://src/simulation/strategic_unit_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const MAX_SLOTS := 4
const MINIMUM_SIZE := Vector2(188, 68)
const IDLE := {"action":"IDLE", "direction":Vector2.RIGHT, "step":0, "phase":0}
var selected := false
var heroic_2d := true
var _summary: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = MINIMUM_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Only the shared material painter owns the visible skin, not native button
	# captions or overlapping nested controls.
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	queue_redraw()


func refresh(army: Dictionary, soldiers: Array, is_selected: bool, use_heroic_2d: bool = true) -> void:
	refresh_summary(summarize(army, soldiers), is_selected, use_heroic_2d)


func refresh_summary(facts: Dictionary, is_selected: bool, use_heroic_2d: bool = true) -> void:
	var changed := str(facts.get("signature", "")) != str(_summary.get("signature", "")) or selected != is_selected or heroic_2d != use_heroic_2d
	_summary = facts.duplicate(true)
	selected = is_selected
	heroic_2d = use_heroic_2d
	custom_minimum_size = MINIMUM_SIZE
	set_meta("warband_id", str(_summary.get("warband_id", "")))
	set_meta("number", int(_summary.get("number", 0)))
	set_meta("total_alive", int(_summary.get("total_alive", 0)))
	set_meta("composition_slots", _summary.get("slots", []).duplicate(true))
	set_meta("overflow_count", int(_summary.get("overflow_count", 0)))
	set_meta("overflow_types", int(_summary.get("overflow_types", 0)))
	set_meta("composition_signature", str(_summary.get("signature", "")))
	set_meta("selected", selected)
	tooltip_text = _tooltip(_summary)
	if changed: queue_redraw()


func detached_summary() -> Dictionary:
	return _summary.duplicate(true)


static func summarize(army: Dictionary, soldiers: Array) -> Dictionary:
	var army_id := str(army.get("id", ""))
	var side := str(army.get("side", ""))
	var candidates: Array[Dictionary] = []
	if not army_id.is_empty() and not side.is_empty():
		for value: Variant in soldiers:
			if not value is Dictionary: continue
			var unit: Dictionary = value
			if str(unit.get("id", "")).is_empty() or str(unit.get("warband_id", "")) != army_id or str(unit.get("side", "")) != side: continue
			if int(unit.get("hp", 0)) <= 0 or not bool(unit.get("alive", true)): continue
			if str(unit.get("unit_type", "")).is_empty(): continue
			candidates.append(unit)
	# IDs are unique in authoritative snapshots. Deterministic ordering and
	# deduplication make a detached repeated observation harmless as well.
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _unit_key(a) < _unit_key(b))
	var seen := {}
	var groups := {}
	var total := 0
	for unit: Dictionary in candidates:
		var unit_id := str(unit.id)
		if seen.has(unit_id): continue
		seen[unit_id] = true
		var type := str(unit.unit_type)
		var is_hero := type == "hero"
		var archetype := str(unit.get("hero_archetype", Heroes.DEFAULT_ARCHETYPE)) if is_hero else ""
		var identity := "hero:" + archetype if is_hero else type
		if not groups.has(identity):
			var label := str(Heroes.PROFILES.get(archetype, {}).get("name", archetype)) if is_hero else str(UnitCatalog.UNITS.get(type, {}).get("label", type))
			groups[identity] = {"identity":identity, "unit_type":type, "hero_archetype":archetype, "hero":is_hero, "label":label, "count":0, "visual":unit.duplicate(true)}
		groups[identity]["count"] = int(groups[identity]["count"]) + 1
		total += 1
	var ordered: Array[Dictionary] = []
	for identity: String in groups: ordered.append(groups[identity])
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.hero) != bool(b.hero): return bool(a.hero)
		if not bool(a.hero) and int(a.count) != int(b.count): return int(a.count) > int(b.count)
		return str(a.identity) < str(b.identity))
	var slots: Array[Dictionary] = []
	var overflow_count := 0
	var signature := "%s|%d|%s|%d" % [army_id, int(army.get("number", 0)), side, total]
	for index: int in range(ordered.size()):
		var group: Dictionary = ordered[index]
		signature += "|%s:%d:%s" % [group.identity, int(group.count), str(group.visual.get("faction_id", ""))]
		if index < MAX_SLOTS: slots.append(group.duplicate(true))
		else: overflow_count += int(group.count)
	return {"warband_id":army_id, "number":int(army.get("number", 0)), "side":side, "slots":slots, "all_groups":ordered, "total_alive":total, "total_types":ordered.size(), "overflow_count":overflow_count, "overflow_types":maxi(ordered.size() - MAX_SLOTS, 0), "signature":signature}


static func _unit_key(unit: Dictionary) -> String:
	return "%s|%s|%s|%s" % [str(unit.get("id", "")), str(unit.get("unit_type", "")), str(unit.get("hero_archetype", "")), str(unit.get("faction_id", ""))]


static func _tooltip(facts: Dictionary) -> String:
	var lines: Array[String] = ["部队 %02d · %d 名存活单位" % [int(facts.get("number", 0)), int(facts.get("total_alive", 0))]]
	for group: Dictionary in facts.get("all_groups", []):
		lines.append("%s%s ×%d" % ["英雄 · " if bool(group.hero) else "", str(group.label), int(group.count)])
	if int(facts.get("overflow_count", 0)) > 0:
		lines.append("+%d：其余 %d 种单位，共 %d 名；计入总数。" % [int(facts.overflow_count), int(facts.overflow_types), int(facts.overflow_count)])
	if int(facts.get("total_alive", 0)) == 0: lines.append("空编队仍可选择与调遣，招募或调入单位后即可补员。")
	lines.append("单击选择部队并定位镜头，选择时不会下达军令。")
	return "\n".join(lines)


static func portrait_rects(surface_size: Vector2, count: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var column := maxf((surface_size.x - 16.0) / MAX_SLOTS, 1.0)
	for index: int in range(clampi(count, 0, MAX_SLOTS)):
		result.append(Rect2(8 + index * column + 2, 23, maxf(column - 4, 1), maxf(surface_size.y - 36, 1)))
	return result


static func draw_portrait(canvas: Object, rect: Rect2, visual: Dictionary, use_heroic_2d: bool = true) -> Dictionary:
	if rect.size.x <= 0 or rect.size.y <= 0: return {}
	var bounds := Units.visual_bounds(visual, 12, IDLE) if use_heroic_2d else Pixel.unit_visual_bounds(visual, 12)
	if bounds.size.x <= 0 or bounds.size.y <= 0: return {}
	var fit := minf(rect.size.x / bounds.size.x, rect.size.y / bounds.size.y)
	var actual := Units.visual_bounds(visual, 12 * fit, IDLE) if use_heroic_2d else Pixel.unit_visual_bounds(visual, 12 * fit)
	var foot := rect.get_center() - actual.get_center()
	if use_heroic_2d: Units.draw(canvas, foot, visual, 12 * fit, IDLE)
	else: Pixel.draw_unit(canvas, foot, visual, 12 * fit, IDLE)
	return {"identity":"hero:" + str(visual.get("hero_archetype", Heroes.DEFAULT_ARCHETYPE)) if visual.get("unit_type") == "hero" else str(visual.get("unit_type", "")), "bounds":Rect2(foot + actual.position, actual.size), "foot":foot, "radius":12 * fit, "heroic_2d":use_heroic_2d, "pixels":Units.inspect(visual, IDLE) if use_heroic_2d else {}}


func _draw() -> void:
	var state := "disabled" if disabled else ("pressed" if is_pressed() else ("selected" if selected else ("hover" if is_hovered() else "normal")))
	UITheme.draw_surface(self, Rect2(Vector2.ZERO, size), "command", state)
	var font := ReadableFont.readable()
	var ink := Color("eadfc3") if not disabled else Color("8e9183")
	var type_label := str(_summary.get("type_label",""))
	draw_string(font, Vector2(10, 19), type_label if not type_label.is_empty() else "%02d 队" % int(_summary.get("number", 0)), HORIZONTAL_ALIGNMENT_LEFT, 132 if not type_label.is_empty() else 55, 14, ink)
	draw_string(font, Vector2(142 if not type_label.is_empty() else 64, 19), "%d 名" % int(_summary.get("total_alive", 0)), HORIZONTAL_ALIGNMENT_LEFT, 42 if not type_label.is_empty() else 65, 13, Color("b7bf9e"))
	if int(_summary.get("overflow_count", 0)) > 0:
		draw_string(font, Vector2(130, 19), "+%d" % int(_summary.overflow_count), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 140, 13, Color("b9ad93"))
	var slots: Array = _summary.get("slots", [])
	var rects := portrait_rects(size, slots.size())
	var draw_receipts: Array[Dictionary] = []
	for index: int in range(rects.size()):
		var group: Dictionary = slots[index]
		var rect: Rect2 = rects[index]
		if bool(group.hero):
			# A small gold notch marks heroes; the canonical body carries identity.
			draw_rect(Rect2(rect.position + Vector2(0, 1), Vector2(2, 7)), Color("c7a465"))
		var receipt := draw_portrait(self, rect.grow(-1), group.visual, heroic_2d)
		receipt["count"] = int(group.count)
		receipt["slot"] = index
		draw_receipts.append(receipt)
		draw_string(font, Vector2(rect.position.x - 2, size.y - 3), "×%d" % int(group.count), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x + 4, 12, ink)
	if slots.is_empty():
		draw_string(font, Vector2(12, 49), "空编队 · 待补员", HORIZONTAL_ALIGNMENT_CENTER, size.x - 24, 14, Color("9c9c83"))
	if selected:
		draw_rect(Rect2(3, 8, 2, size.y - 16), Color("d3b273"))
	set_meta("painted_draw_state", {"state":state, "selected":selected, "portraits":draw_receipts, "surface_size":size, "total_alive":int(_summary.get("total_alive", 0)), "overflow_count":int(_summary.get("overflow_count", 0))})

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
