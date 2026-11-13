extends RefCounted
## Pixel source art plus factual labels. No camp state, XP or loot authority.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const Atlas = preload("res://src/presentation/heroic_2d_atlas.gd")
const Icons = preload("res://src/presentation/heroic_collection_icons.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")

static func draw_camp(canvas: CanvasItem, point: Vector2, camp: Dictionary, factor: float) -> void:
	var trial: bool = camp.get("kind") == "TRIAL"
	if camp.get("state") == "CLEARED" and not trial: return
	if trial:
		var file := "HAS Buildings Pack/Treasures/Ruins.png"
		var source := Collection.image("buildings", file) if Collection.active() else null
		if source != null:
			Collection.draw_region(canvas, "buildings", file, Rect2i(Vector2i.ZERO, source.get_size()), point, Vector2(source.get_width() * 0.5, source.get_height() - 2), 2.5 * factor)
		else: Atlas.draw_sprite(canvas, "cave", point, 2.4 * factor)
	var offset := Vector2(-78, -82 if trial else -48) * factor
	var caption := "%s · %s" % [str(camp.get("label", "野外守军")), "已清除" if camp.get("state") == "CLEARED" else str(camp.get("remaining_count", 0))]
	canvas.draw_string(ReadableFont.readable(), point + offset + Vector2(1, 1), caption, HORIZONTAL_ALIGNMENT_CENTER, 156 * factor, 14, Color("22262b"))
	canvas.draw_string(ReadableFont.readable(), point + offset, caption, HORIZONTAL_ALIGNMENT_CENTER, 156 * factor, 14, Color("eac38b") if trial else Color("e6d0a0"))

static func draw_loot(canvas: CanvasItem, point: Vector2, loot: Dictionary, factor: float) -> void:
	if loot.get("state") != "AVAILABLE": return
	var item_id := str(loot.get("item_id", ""))
	Icons.draw_symbol(canvas, item_id, point + Vector2(0, -14) * factor, Color.WHITE, 0.7 * factor)
	var caption := str(Items.ITEMS.get(item_id, {}).get("name", "战利品"))
	if loot.get("pickup_scope") == "PUBLIC":
		caption += " · 可争夺"
		for dx: int in [-15,15]:
			canvas.draw_rect(Rect2((point+Vector2(dx,-26)*factor).round(),Vector2(3,22)*factor),Color("c6a1dc"))
	canvas.draw_string(ReadableFont.readable(), point + Vector2(-70, 10) * factor, caption, HORIZONTAL_ALIGNMENT_CENTER, 140 * factor, 13, Color("f2dfa6"))
