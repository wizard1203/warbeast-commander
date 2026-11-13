extends RefCounted
## Read-only projection of authoritative, pre-typed construction slots.
## This helper never invents a position, quote, income or placement permission.

const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const LABEL_OUTLINE_PX := 2
const LABELS := {"BASE":"资源基地", "BARRACKS":"物理营", "RANGE":"魔法营", "FOUNDRY":"兵工坊", "ALTAR":"英雄祭庭", "DRAGON_ROOST":"特色营", "ESSENCE_MINE":"采矿场", "SHOP":"英雄商店", "TOWER":"防御塔"}

static func enabled(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("outpost_mode", false))

static func find(snapshot: Dictionary, slot_id: String) -> Dictionary:
	for slot: Dictionary in snapshot.get("building_slots", []):
		if str(slot.get("id", "")) == slot_id: return slot
	return {}

static func label(slot: Dictionary) -> String:
	if slot.get("allowed_building_types",[]).size()>1:return "军营二选一"
	return str(slot.get("label", LABELS.get(str(slot.get("building_type", "")), str(slot.get("building_type", "")))))

static func reason(slot: Dictionary, view_side: String, observer: bool = false) -> String:
	if slot.is_empty(): return "空位已失效，请重新选择"
	if bool(slot.get("occupied", false)): return "此位置已有建筑或施工项目"
	if observer: return "观战只读，不能建造"
	if str(slot.get("side", "")) != view_side: return "先完全占领该据点"
	var code := str(slot.get("reason", ""))
	if not bool(slot.get("available", false)):
		return str({"NEEDS_COMPLETE_CAPTURE":"需要完全占领据点", "PLACEMENT_BLOCKED":"空位被单位或障碍占用", "INSUFFICIENT_STOCK":"资源不足", "BASE_TIER_REQUIRED":"基地等级不足", "SITE_NOT_OWNED":"先完全占领该据点", "SITE_CONTESTED":"据点正在争夺", "SLOT_OCCUPIED":"此空位已有建筑", "PREREQUISITE":"尚未满足前置条件", "NEUTRALS_PRESENT":"先清除据点野怪"}.get(code, code if not code.is_empty() else "暂不满足建造条件"))
	return ""

static func limits(site_kind: String) -> String:
	match site_kind:
		"SATELLITE": return "纯资源点：采矿场1座、防御塔最多2座；不提供人口，不能建基地。"
		"VILLAGE": return "人口据点：物理营或魔法营二选一共1座、英雄商店1座、防御塔最多2座；不生产资源。"
		_: return "资源根据地：每类功能建筑各1座、防御塔最多5座；占领且基地完工后自动产出。"

static func hit(snapshot: Dictionary, camera: RefCounted, point: Vector2, required_type: String = "") -> Dictionary:
	if not enabled(snapshot): return {}
	var result: Dictionary = {}
	var best := INF
	for slot: Dictionary in snapshot.get("building_slots", []):
		if bool(slot.get("occupied", false)) or not bool(slot.get("visible", true)): continue
		if not required_type.is_empty() and required_type not in slot.get("allowed_building_types",[slot.get("building_type","")]): continue
		var screen: Vector2 = camera.world_to_screen(Vector2(slot.get("position", Vector2.ZERO)))
		var distance := screen.distance_squared_to(point)
		var radius := clampf(36.0 * float(camera.get_scale()), 24.0, 42.0)
		if distance <= radius * radius and distance < best:
			result = slot
			best = distance
	return result

static func visual_envelope(factor: float) -> Rect2:
	# Actual screen-space icon and label footprint, not the command hit radius.
	# Noninteractive scenery may be suppressed behind this surface; buildings,
	# units, authoritative placement and map geometry must never be changed.
	var scale_value := clampf(factor, 0.45, 1.5)
	var result := Rect2(Vector2(-28,-20)*scale_value,Vector2(56,40)*scale_value)
	if factor >= 0.55:
		var font := ReadableFont.readable()
		var font_size := maxi(11,roundi(13*scale_value))
		var ascent := font.get_ascent(font_size)
		var descent := font.get_descent(font_size)
		result = result.merge(Rect2(Vector2(-43,36)*scale_value-Vector2(0,ascent),Vector2(86*scale_value,ascent+descent)).grow(LABEL_OUTLINE_PX))
	return result

static func draw(canvas: CanvasItem, snapshot: Dictionary, world_to_screen: Callable, factor: float, view_side: String) -> void:
	if not enabled(snapshot): return
	for slot: Dictionary in snapshot.get("building_slots", []):
		if bool(slot.get("occupied", false)) or not bool(slot.get("visible", true)): continue
		var point: Vector2 = world_to_screen.call(Vector2(slot.get("position", Vector2.ZERO)))
		var field := canvas.get_parent() as Control
		if field != null and not Rect2(Vector2.ZERO, field.size).grow(80).has_point(point): continue
		var scale_value := clampf(factor, 0.45, 1.5)
		var own := str(slot.get("side", "")) == view_side
		var tint := Palette.side_color(view_side) if own else Color("90866b")
		if own and not bool(slot.get("available", false)): tint = Color("a79b78")
		# Stepped, opaque dark rim and stone blocks keep the current chunky
		# pixel language; no per-slot texture, blur, animation or physics node.
		canvas.draw_rect(Rect2((point + Vector2(-28,-20)*scale_value).round(), Vector2(56,40)*scale_value), Color("111918"))
		canvas.draw_rect(Rect2((point + Vector2(-25,-17)*scale_value).round(), Vector2(50,34)*scale_value), Color("514c3b") if own else Color("343b32"))
		for corner: Vector2 in [Vector2(-28,-20),Vector2(18,-20),Vector2(-28,10),Vector2(18,10)]:
			canvas.draw_rect(Rect2((point+corner*scale_value).round(),Vector2(10,10)*scale_value),tint)
		var symbol:=str(slot.get("building_type","BASE"))
		if symbol=="RANGE":symbol="MAGIC_CAMP_"+str(slot.get("faction_id","HUMAN"))
		Icons.draw_symbol(canvas,symbol,point+Vector2(0,-2)*scale_value,tint,0.65*scale_value)
		if factor >= 0.55:
			# Snow and sand need the same readable, hard dark pixel contour as
			# grass. This is a font outline, not a blur or a new floating panel.
			canvas.draw_string_outline(ReadableFont.readable(),point+Vector2(-43,36)*scale_value,label(slot),HORIZONTAL_ALIGNMENT_CENTER,86*scale_value,maxi(11,roundi(13*scale_value)),LABEL_OUTLINE_PX,Color("111918"))
			canvas.draw_string(ReadableFont.readable(),point+Vector2(-43,36)*scale_value,label(slot),HORIZONTAL_ALIGNMENT_CENTER,86*scale_value, maxi(11,roundi(13*scale_value)),Color("e6d5a9"))
