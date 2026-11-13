class_name StrategicTextButton
extends Button
## Text-first commands retain readable Chinese and their existing hit geometry.
const UIThemeClass = preload("res://src/presentation/strategic_ui_theme.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const FrontierCommandArt = preload("res://src/presentation/strategic_frontier_command_art.gd")
const HeroicCommandArt = preload("res://src/presentation/heroic_command_art.gd")
const IconClass = preload("res://src/presentation/strategic_icon_button.gd")
var material_role := "command"
var leading_symbol := ""

func _ready() -> void:
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(state, UIThemeClass.style(state, material_role))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var painted_leading := not leading_symbol.is_empty() and (FrontierCommandArt.enabled() or HeroicCommandArt.enabled())
	var chosen := bool(get_meta("selected",false)) or (toggle_mode and button_pressed) or (painted_leading and bool(get_meta("enabled",false)))
	# Category tabs already supplied selected facts, but plain text buttons
	# previously ignored them. A toggled category is selected, not permanently
	# sunken as if a finger were still held down. No input/callback is changed.
	var held := is_pressed() and not toggle_mode
	var state := "disabled" if disabled else ("pressed" if held else ("selected" if chosen else ("hover" if is_hovered() else "normal")))
	UIThemeClass.draw_surface(self, Rect2(Vector2.ZERO, size), material_role, state)
	set_meta("painted_draw_state",{"state":state,"symbol":leading_symbol,"selected":chosen,"surface_size":size})
	var offset := 2 if held else 0
	var color := (Color("ddd2b3") if HeroicCommandArt.enabled() else Color("d9d8bb")) if not disabled else Color("838e80")
	if painted_leading:
		var icon_center := Vector2(30, size.y * 0.5 + offset)
		if HeroicCommandArt.enabled(): IconClass.draw_symbol(self, leading_symbol, icon_center, Color("72817c") if disabled else Color("d8c994"))
		else: FrontierCommandArt.draw_symbol(self, leading_symbol, icon_center, Color("72817c") if disabled else Color("d8c994"))
		# Existing Button.text and callbacks remain authoritative for legacy
		# clients/tests. Only the paint positions change, inside the same hit box.
		_caption(Vector2(60, size.y * 0.5 + 7 + offset),text,size.x-70,19,color)
		set_meta("painted_draw_state", {"state":state, "symbol":leading_symbol, "selected":chosen, "icon_center":icon_center, "surface_size":size})
		return
	var lines := text.split("\n")
	if lines.size() > 1:
		_caption(Vector2(10, size.y * 0.5 - 1 + offset),lines[0],size.x-20,21,color)
		_caption(Vector2(10, size.y * 0.5 + 19 + offset),lines[1],size.x-20,15,color)
	else:
		_caption(Vector2(10, size.y * 0.5 + 7 + offset),text,size.x-20,21,color)

func _caption(point: Vector2, caption: String, width: float, font_size: int, ink: Color) -> void:
	# One crisp shadow pixel, not an unreadable faux-pixel Chinese font or a
	# blurred glow. Both passes are paint only; Button.text stays authoritative.
	if HeroicCommandArt.enabled():
		draw_string(ReadableFont.readable(),point+Vector2(0,1),caption,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,Color("0a1212"))
	draw_string(ReadableFont.readable(),point,caption,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,ink)

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
