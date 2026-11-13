class_name StrategicChrome
extends Control
## Original editable material ornament. All geometry stays inside its existing
## surface; decoration deliberately owns no pointer or gameplay state.
const UIThemeClass = preload("res://src/presentation/strategic_ui_theme.gd")
const HeroicArt = preload("res://src/presentation/heroic_command_art.gd")

var surface := "panel"
var emblem := "army"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_material(self, Rect2(Vector2.ZERO, size), surface)
	if surface == "panel":
		if HeroicArt.enabled():
			# A small stepped escutcheon, not an anti-aliased vector badge.
			# Kept within the historical title's icon well; no new hit surface.
			draw_rect(Rect2(22,27,24,18),Color("0b1313"))
			draw_rect(Rect2(25,45,18,5),Color("0b1313"))
			draw_rect(Rect2(29,50,10,4),Color("0b1313"))
			draw_rect(Rect2(24,29,20,15),Color("bb9253"))
			draw_rect(Rect2(27,44,14,5),Color("bb9253"))
			draw_rect(Rect2(31,49,6,3),Color("bb9253"))
			draw_rect(Rect2(25,30,8,12),Color("dbc282"))
			draw_rect(Rect2(33,30,2,18),Color("4f4733"))
			draw_rect(Rect2(24,size.y-44,size.x-48,2),Color("111d1c"))
			draw_rect(Rect2(24,size.y-42,size.x-48,1),Color("716648"))
			return
		draw_line(Vector2(24, size.y - 43), Vector2(size.x - 24, size.y - 43), Color("4f5045"), 1)
		draw_colored_polygon(PackedVector2Array([Vector2(22, 29), Vector2(46, 29), Vector2(43, 47), Vector2(34, 55), Vector2(25, 47)]), Color("b48d58"))
		draw_line(Vector2(34, 32), Vector2(34, 49), Color("273738"), 2)

static func style(state: String = "normal", material: String = "wood") -> StyleBoxFlat:
	return UIThemeClass.style(state, material)

static func draw_material(canvas: CanvasItem, rect: Rect2, material: String, pressed: bool = false, disabled: bool = false) -> void:
	UIThemeClass.draw_surface(canvas, rect, material, "disabled" if disabled else ("pressed" if pressed else "normal"))
