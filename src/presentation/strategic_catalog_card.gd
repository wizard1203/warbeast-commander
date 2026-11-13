class_name StrategicCatalogCard
extends "res://src/presentation/strategic_icon_button.gd"
## A catalog choice is an inspection request, never permission to recruit/build.
## All supplied facts are detached; a lock keeps its reason readable by tapping.

const Pixel = preload("res://src/presentation/strategic_pixel_renderer.gd")
const CostReadout = preload("res://src/presentation/strategic_cost_readout.gd")
var _facts: Dictionary = {}
var _cost_view: Control

func _ready() -> void:
	super._ready()
	# Let touch sessions bubble to the owning ScrollContainer. That container
	# stops them before the battlefield and cancels a button press when dragging.
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(174, 148)
	# The card paints its own shared pixel surface; native Button styles would
	# otherwise duplicate that frame and obscure the selected factual border.
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_cost_view = CostReadout.new()
	_cost_view.name = "CatalogCostIcons"
	_cost_view.font_size = 15
	_cost_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cost_view)
	resized.connect(_layout_cost)
	_layout_cost()
	_refresh_cost()

func refresh(facts: Dictionary) -> void:
	_facts = facts.duplicate(true)
	caption = str(_facts.get("label", _facts.get("id", "")))
	symbol = str(_facts.get("id", ""))
	required_tier = int(_facts.get("required_tier", 0)) if not str(_facts.get("locked_reason", "")).is_empty() else 0
	set_meta("catalog_item_id", str(_facts.get("id", "")))
	if not has_meta("selected"): set_meta("selected", false)
	set_meta("locked_reason", str(_facts.get("locked_reason", "")))
	set_meta("required_base_tier", int(_facts.get("required_tier", 1)))
	set_meta("visual_facts", _facts.get("visual", {}).duplicate(true))
	if str(_facts.get("kind", "UNIT")) == "BUILDING": set_meta("building_type", symbol)
	else: set_meta("unit_type", symbol)
	# Locked entries are still choices: arena confirmation remains authoritative.
	disabled = false
	tooltip_text = "%s · %s\n%s" % [caption, str(_facts.get("role", "")), str(_facts.get("locked_reason", "单击查看；确认后才会下达命令"))]
	_refresh_cost()
	queue_redraw()

func detached_facts() -> Dictionary:
	return _facts.duplicate(true)

func _layout_cost() -> void:
	if _cost_view == null: return
	_cost_view.position = Vector2(7, size.y - 49)
	_cost_view.size = Vector2(maxf(size.x - 14, 1), 44)

func _refresh_cost() -> void:
	if _cost_view != null:
		_cost_view.refresh(_facts.get("cost", {}), _facts.get("stock", {}), int(_facts.get("population", -1)))

func _draw() -> void:
	var chosen := selected or bool(get_meta("selected", false))
	var locked := not str(_facts.get("locked_reason", "")).is_empty()
	var background := Color("26383c") if chosen else Color("1d2c30")
	if is_pressed(): background = background.darkened(0.2)
	elif is_hovered(): background = background.lightened(0.08)
	if HeroicCommandArt.enabled():
		var state := "pressed" if is_pressed() else ("selected" if chosen else ("hover" if is_hovered() else "normal"))
		HeroicCommandArt.draw_surface(self,Rect2(Vector2.ZERO,size),"panel",state)
		# A quiet display well and cost ledger, not another loud outer frame.
		draw_rect(Rect2(7,28,80,70),Color("192422"))
		draw_rect(Rect2(7,28,80,2),Color("101a19"))
		draw_rect(Rect2(7,size.y-50,size.x-14,43),Color("1b2826"))
	else:
		draw_style_box(_surface(background,chosen),Rect2(Vector2.ZERO,size))
	var font := ReadableFont.readable()
	draw_string(font, Vector2(9, 23), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 18, 17, Color("f0e5ca"))
	var art := Rect2(8, 29, 78, 69)
	draw_visual(self, art, _facts)
	var text_x := 92.0
	var text_width := maxf(size.x - text_x - 7, 1)
	draw_string(font, Vector2(text_x, 48), str(_facts.get("role", "")), HORIZONTAL_ALIGNMENT_LEFT, text_width, 14, Color("a6c5bd"))
	var status := str(_facts.get("locked_reason", "")) if locked else "可选择"
	# The full reason is also shown by the arena's selected-item detail, not hover.
	draw_string(font, Vector2(text_x, 72), status, HORIZONTAL_ALIGNMENT_LEFT, text_width, 13, Color("dcb781") if locked else Color("88b999"))
	if chosen:
		if HeroicCommandArt.enabled():
			draw_rect(Rect2(size.x-18,8,10,8),Color("141e1a"))
			draw_rect(Rect2(size.x-16,11,3,3),Color("efd18a"))
			draw_rect(Rect2(size.x-13,9,4,3),Color("efd18a"))
		else: draw_circle(Vector2(size.x-12,12),4,Color("ecc87c"))
	draw_line(Vector2(8, size.y - 52), Vector2(size.x - 8, size.y - 52), Color("415255"), 1)

static func _surface(fill: Color, chosen: bool) -> StyleBoxFlat:
	if HeroicCommandArt.enabled(): return UIThemeClass.style("selected" if chosen else "normal","panel")
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("e2ba71") if chosen else Color("536b6a")
	style.set_border_width_all(2 if chosen else 1)
	style.set_corner_radius_all(5)
	return style

static func draw_visual(canvas: Object, rect: Rect2, facts: Dictionary) -> void:
	var visual: Dictionary = facts.get("visual", {}).duplicate(true)
	if str(facts.get("kind", "UNIT")) == "BUILDING":
		visual["building_type"] = str(visual.get("building_type", facts.get("id", "BASE")))
		visual["side"] = str(visual.get("side", "PLAYER"))
		visual["radius"] = 24
		visual["hp"] = maxi(int(visual.get("hp", 100)), 1)
		visual["complete"] = true
		var bounds := Pixel.building_visual_bounds(visual,1)
		var scale_factor := minf(rect.size.x / maxf(bounds.size.x,1), rect.size.y / maxf(bounds.size.y,1))
		var center := rect.get_center() - bounds.get_center()*scale_factor
		Pixel.draw_building(canvas, center, visual, scale_factor)
	else:
		visual["unit_type"] = str(visual.get("unit_type", facts.get("id", "worker")))
		visual["side"] = str(visual.get("side", "PLAYER"))
		# Same pixel identity as the battlefield, not the M38 illustrated bust.
		var bounds := Pixel.unit_visual_bounds(visual, 12)
		var fit := minf(rect.size.x / maxf(bounds.size.x, 1), rect.size.y / maxf(bounds.size.y, 1))
		var center := rect.get_center() - bounds.get_center() * fit
		Pixel.draw_unit(canvas, center, visual, 12 * fit, {"action":"IDLE", "direction":Vector2.RIGHT, "step":0, "phase":0})

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
