extends Control
## Compact original pictograms plus real numeric ledgers, never fake stock.
const Icons = preload("res://src/presentation/strategic_icon_button.gd")
var stock: Dictionary = {}
var population: Dictionary = {}
var upkeep: Dictionary = {}

func refresh_upkeep(value: Dictionary, economy: Dictionary = {}) -> void:
	upkeep = value.duplicate(true)
	tooltip_text = "金币：唯一资源，建造、招募、研究和购物均使用它。完整占领且经济建筑完工后自动采金。\n人口：已用 + 预留 / 上限；村庄+10、根据地+30。\n采金效率%d%%；已用人口≤50为100%%，51–80为70%%，81+为40%%。仅自动采金受维护费影响，击杀赏金、退款不受影响。" % int(upkeep.get("material_efficiency_percent",100))
	tooltip_text += "\n自动采金累计：采出%d，净入库%d，维护费%d。" % [int(economy.get("delivered_gross",{}).get("MATERIAL",0)),int(economy.get("delivered",{}).get("MATERIAL",0)),int(economy.get("taxed",{}).get("MATERIAL",0))]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "金币：唯一资源。完整占领且基地或采矿场完工后自动产出。人口：已用人口 + 已预留 / 上限。"

func _draw() -> void:
	var font := ThemeDB.fallback_font
	Icons.draw_symbol(self, "gold", Vector2(18, 20), Color("e6bf67"), 0.65)
	draw_string(font, Vector2(43, 24), str(stock.get("MATERIAL", 0)), HORIZONTAL_ALIGNMENT_LEFT, 105, 22, Color("f0dfa9"))
	var efficiency := int(upkeep.get("material_efficiency_percent",100))
	draw_string(font, Vector2(43, 39), "采金%d%%" % efficiency, HORIZONTAL_ALIGNMENT_LEFT, 100, 11, Color("d8bb7c") if efficiency < 100 else Color("a8bb94"))
	Icons.draw_symbol(self, "population", Vector2(177, 20), Color("abc8ce"), 0.6)
	draw_string(font, Vector2(199, 27), "%d +%d / %d" % [int(population.get("used", 0)), int(population.get("reserved", 0)), int(population.get("maximum", 0))], HORIZONTAL_ALIGNMENT_LEFT, 150, 19, Color("e1e5ce"))

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
