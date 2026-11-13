class_name StrategicCostReadout
extends Control
## Original pictograms with exact catalog numbers. A visible ! is used in
## addition to colour when current stock cannot pay a resource cost.

const Icons = preload("res://src/presentation/strategic_icon_button.gd")
var cost: Dictionary = {}
var stock: Dictionary = {}
var population := -1
var font_size := 20
var show_resources := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var entries: Array = [["gold", "MATERIAL", int(cost.get("MATERIAL", 0))]] if show_resources else []
	if population >= 0: entries.append(["population", "POPULATION", population])
	if entries.is_empty(): return
	var columns := 2 if entries.size()>3 and size.y>=40 else entries.size()
	var width := size.x / float(columns)
	var rows := ceili(float(entries.size())/float(columns))
	var height := size.y/float(rows)
	for n: int in range(entries.size()):
		var entry: Array = entries[n]
		var insufficient: bool = not stock.is_empty() and entry[1] != "POPULATION" and int(stock.get(entry[1], 0)) < int(entry[2])
		var color := Color("e8bf8f") if insufficient else Color("d8d5a0")
		var offset := Vector2(float(n%columns)*width,float(n/columns)*height)
		Icons.draw_symbol(self, str(entry[0]), offset+Vector2(12, height * 0.5), color, 0.45 if height<28 else 0.55)
		var number := str(entry[2]) + ("!" if insufficient else "")
		draw_string(ThemeDB.fallback_font, offset+Vector2(27, height * 0.5 + font_size * 0.35), number, HORIZONTAL_ALIGNMENT_LEFT, width - 27, font_size, color)

func refresh(cost_value: Dictionary, stock_value: Dictionary, population_value: int = -1) -> void:
	cost = cost_value.duplicate(true)
	stock = stock_value.duplicate(true)
	population = population_value
	set_meta("resource_values", cost.duplicate(true))
	set_meta("population_value", population)
	set_meta("show_resources", show_resources)
	tooltip_text = "金币 %d%s。数字后的 ! 表示当前库存不足。" % [int(cost.get("MATERIAL", 0)), "；人口 %d" % population if population >= 0 else ""]
	if not show_resources: tooltip_text = "人口 %d；资源费用依取得方式变化，请查看详情。" % population
	queue_redraw()

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
