class_name StrategicQueueReadout
extends Control
## A scrollable, icon-first projection of the authoritative ordered queue.

const Icons = preload("res://src/presentation/strategic_icon_button.gd")
const Pixel = preload("res://src/presentation/strategic_pixel_renderer.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
# Production and automatic construction progress in fixed simulation ticks.
const TICKS_PER_SECOND := 20.0
var entries: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func refresh(values: Array[Dictionary]) -> void:
	entries = values.duplicate(true)
	custom_minimum_size = Vector2(maxi(112, entries.size() * 112), 60)
	size = custom_minimum_size
	set_meta("entry_ids", entries.map(func(entry: Dictionary) -> String: return str(entry.get("id", ""))))
	queue_redraw()

func cell_rect(index: int) -> Rect2:
	return Rect2(index * 112 + 2, 1, 104, 57) if index >= 0 and index < entries.size() else Rect2()

func inspection_at(point: Vector2) -> Dictionary:
	for index: int in range(entries.size()):
		if cell_rect(index).has_point(point): return _inspection(index)
	return {}

func inspection_for(id: String) -> Dictionary:
	if id.is_empty(): return {}
	for index: int in range(entries.size()):
		if str(entries[index].get("id", "")) == id: return _inspection(index)
	return {}

func _inspection(index: int) -> Dictionary:
	var entry: Dictionary = entries[index]
	var id := str(entry.get("id", ""))
	if id.is_empty(): return {}
	var lines: Array[String] = [str(entry.get("caption", "订单"))]
	if not str(entry.get("description", "")).is_empty(): lines.append(str(entry.description))
	lines.append("队列：%d/%d · %s" % [index + 1, entries.size(), str(entry.get("state", ""))])
	var progress := int(entry.get("progress", 0))
	var maximum := maxi(1, int(entry.get("max_progress", 1)))
	if entry.get("work_kind") == "production":
		lines.append("生产进度：%.1f/%.1f秒" % [progress / TICKS_PER_SECOND, maximum / TICKS_PER_SECOND])
		lines.append("剩余生产工时：" + _remaining_work(entry))
		lines.append("不含前序排队、暂停与出口等待。")
	else:
		lines.append("施工进度：%.1f/%.1f秒" % [progress / TICKS_PER_SECOND, maximum / TICKS_PER_SECOND])
		lines.append("完整控制本点时自动施工，无需建筑工；不含失去控制或暂停的时间。")
	var cost: Dictionary = entry.get("cost", {})
	if not cost.is_empty():
		var paid := "已付：%d金币" % int(cost.get("MATERIAL", 0))
		if entry.has("population"): paid += " · 预留人口%d" % int(entry.population)
		lines.append(paid)
	lines.append("订单 " + id)
	lines.append("仅查看；用撤销首／末按钮取消。")
	return {"id":id, "text":"\n".join(lines), "rect":cell_rect(index)}

func _remaining_work(entry: Dictionary) -> String:
	return "%.1f秒" % (maxi(0, int(entry.get("max_progress", 0)) - int(entry.get("progress", 0))) / TICKS_PER_SECOND)

func _draw() -> void:
	var font := ReadableFont.readable()
	if entries.is_empty():
		draw_string(font, Vector2(8, 36), "队列为空", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("a9b5a4"))
		return
	for n: int in range(entries.size()):
		var entry: Dictionary = entries[n]
		var x := n * 112.0
		draw_rect(cell_rect(n), Color("29463e"))
		if entry.has("hero_archetype"):
			Pixel.draw_hero_portrait(self, Rect2(x + 8, 4, 28, 32), str(entry.hero_archetype))
		else:
			Icons.draw_symbol(self, str(entry.get("symbol", "build")), Vector2(x + 24, 20), Color("d8d5a0"), 0.55)
		draw_string(font, Vector2(x + 44, 17), str(entry.get("caption", "")), HORIZONTAL_ALIGNMENT_LEFT, 63, 13, Color("e1e5ce"))
		draw_string(font, Vector2(x + 44, 35), str(entry.get("state", "")), HORIZONTAL_ALIGNMENT_LEFT, 63, 13, Color("c9c6ab"))
		var value := int(entry.get("progress", 0))
		var maximum := maxi(1, int(entry.get("max_progress", 1)))
		draw_rect(Rect2(x + 9, 40, 90, 4), Color("182d29"))
		draw_rect(Rect2(x + 9, 40, 90 * clampf(float(value) / maximum, 0, 1), 4), Color("bbbc83"))
		var work := _remaining_work(entry) + "工时" if entry.get("work_kind") == "production" else _remaining_work(entry) + "施工"
		draw_string(font, Vector2(x + 9, 57), work, HORIZONTAL_ALIGNMENT_LEFT, 90, 13, Color("e1e5ce"))

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
