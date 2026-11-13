class_name StrategicFactReadout
extends Control
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
## Compact factual tiles. Every value is published by the arena from snapshot;
## this decoration never handles input or submits an order.
const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const RosterPreview = preload("res://src/presentation/strategic_roster_preview.gd")
var entries: Array[Dictionary] = []
var mode := "tiles"
var heroic_2d := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func refresh(values: Array) -> void:
	entries.clear()
	for value: Dictionary in values: entries.append(value.duplicate(true))
	set_meta("facts", entries.duplicate(true))
	queue_redraw()

func shown_entries() -> Array[Dictionary]:
	var shown := entries
	if mode == "roster" and entries.size() > 3:
		shown = entries.slice(0, 2)
		shown.append({"symbol":"army", "caption":"另%d类" % (entries.size() - 2)})
	return shown

func cell_rect(index: int, count: int = -1) -> Rect2:
	if count < 0: count = shown_entries().size()
	if count <= 0 or index < 0 or index >= count: return Rect2()
	var width := size.x / count
	return Rect2(index * width + 2, 2, maxf(width - 5, 0), maxf(size.y - 4, 0))

func inspection_at(point: Vector2) -> Dictionary:
	var shown := shown_entries()
	for index: int in range(shown.size()):
		var rect := cell_rect(index, shown.size())
		var entry: Dictionary = shown[index]
		if rect.has_point(point) and not str(entry.get("help_text", "")).is_empty():
			return {"id":str(entry.get("inspection_id", entry.get("symbol", index))), "text":str(entry.help_text), "rect":rect}
	return {}

func _draw() -> void:
	if entries.is_empty(): return
	var shown := shown_entries()
	var width := size.x / shown.size()
	var font := ReadableFont.readable()
	var previews: Array[Dictionary] = []
	for n: int in range(shown.size()):
		var entry: Dictionary = shown[n]
		var tile := cell_rect(n, shown.size())
		draw_rect(tile, Color("192f33"))
		draw_rect(tile, Color("526359"), false, 1)
		var color := Color("d8bd87") if not entry.get("inactive", false) else Color("8b9381")
		var compact := size.y < 45
		var text_offset := 29.0 if compact else 39.0
		var visuals: Array = entry.get("visuals", [])
		if not visuals.is_empty():
			var art_width := minf((28.0 if compact else 52.0) * mini(visuals.size(), 4), tile.size.x * 0.48)
			var art := Rect2(tile.position + Vector2(4, 1), Vector2(art_width, tile.size.y - 2))
			previews.append_array(RosterPreview.draw_group(self, art, visuals, heroic_2d))
			text_offset = art_width + 12
		else:
			Icons.draw_symbol(self, str(entry.get("symbol", "army")), Vector2(tile.position.x + (14 if compact else 19), 15 if compact else 22), color, 0.38 if compact else 0.58)
		var caption := str(entry.get("caption", ""))
		if compact and entry.has("value"): caption = str(entry.value) + caption
		var narrow_armor := entry.has("armor_remaining") and tile.size.x < 150
		if narrow_armor: caption = str(entry.get("armor_number",0))
		draw_string(font, Vector2(tile.position.x + text_offset, 20 if compact else 27), caption, HORIZONTAL_ALIGNMENT_LEFT, maxf(width - text_offset - 8, 1), 12 if compact and entry.has("value") else 14 if compact else 15, Color("ddd7bb"))
		if narrow_armor:
			draw_string(font,Vector2(tile.position.x+2,size.y-5),str(entry.armor_remaining),HORIZONTAL_ALIGNMENT_CENTER,tile.size.x-4,10,Color("b9cbb0"))
		if entry.has("value") and not compact:
			draw_string(font, Vector2(tile.position.x + (text_offset if not visuals.is_empty() else 13), minf(size.y - 9, 53)), str(entry["value"]), HORIZONTAL_ALIGNMENT_LEFT, maxf(width - text_offset - 8, 1), 20, color)
		if entry.has("ratio"):
			var bar := Rect2(tile.position + Vector2(8, size.y - 10), Vector2(tile.size.x - 16, 5))
			draw_rect(bar, Color("0c2024"))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(float(entry["ratio"]), 0, 1), bar.size.y)), Color("7eb08b"))
		if entry.get("equipped", false):
			draw_line(tile.end - Vector2(21, 15), tile.end - Vector2(15, 9), Color("acd38d"), 2)
			draw_line(tile.end - Vector2(15, 9), tile.end - Vector2(6, 22), Color("acd38d"), 2)
	set_meta("painted_portraits", previews)

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
