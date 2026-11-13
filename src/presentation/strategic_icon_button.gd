class_name StrategicIconButton
extends Button
## Original vector/pixel pictograms. Short captions and tooltips remain readable
## without imported franchise art, emoji glyphs or remote assets.

const UIThemeClass = preload("res://src/presentation/strategic_ui_theme.gd")
const ReadableFont = preload("res://src/presentation/strategic_font.gd")
const FrontierCommandArt = preload("res://src/presentation/strategic_frontier_command_art.gd")
const CollectionIcons = preload("res://src/presentation/heroic_collection_icons.gd")
const HeroicCommandArt = preload("res://src/presentation/heroic_command_art.gd")
var symbol := "sword"
var caption := ""
var cooldown := 0.0
var tint := Color("d8c994")
var selected := false
var required_tier := 0
var material_role := "command"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	if custom_minimum_size == Vector2.ZERO: custom_minimum_size = Vector2(68, 64)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(state, UIThemeClass.style(state, material_role))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var is_selected := selected or bool(get_meta("selected", false))
	var state := "disabled" if disabled else ("pressed" if is_pressed() else ("selected" if is_selected else ("hover" if is_hovered() else "normal")))
	var factual_state := str(get_meta("state", ""))
	var semantics := HeroicCommandArt.button_semantics(disabled, required_tier, factual_state, state) if HeroicCommandArt.enabled() else (FrontierCommandArt.button_semantics(disabled, required_tier, factual_state, state) if FrontierCommandArt.enabled() else {"frame":state,"badge":"","grayscale":disabled,"fact":factual_state})
	state = str(semantics.frame)
	var grayscale := bool(semantics.grayscale)
	UIThemeClass.draw_surface(self, Rect2(Vector2.ZERO, size), material_role, state)
	if is_selected and not HeroicCommandArt.enabled():
		draw_colored_polygon(PackedVector2Array([Vector2(size.x - 20, 5), Vector2(size.x - 5, 5), Vector2(size.x - 5, 20)]), Color("e8bd71"))
	if size.x > 250 and size.y < 80:
		var ink := Color("72817c") if grayscale else tint
		draw_symbol(self, symbol, Vector2(34, size.y * 0.5), ink, 0.8)
		draw_string(ReadableFont.readable(), Vector2(66, size.y * 0.5 + 7), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 80, 21, Color("ddd2b3") if HeroicCommandArt.enabled() else Color("e2e5d0"))
		_draw_factual_badge(str(semantics.badge))
		set_meta("painted_draw_state", {"state":state, "factual_state":factual_state, "badge":str(semantics.badge), "grayscale":grayscale, "icon_center":Vector2(34, size.y * 0.5), "surface_size":size})
		return
	var center := Vector2(size.x * 0.5, 24 if size.y < 80 else minf(size.y * 0.41, 62))
	if is_pressed(): center += Vector2(0, 2)
	var color := Color("72817c") if grayscale else tint
	draw_symbol(self, symbol, center + Vector2(0, 1), Color("15282d"), 1.0 if size.y < 80 else 1.22)
	draw_symbol(self, symbol, center, color, 1.0 if size.y < 80 else 1.22)
	var font := ReadableFont.readable()
	var text_size := 15
	draw_string(font, Vector2(0, size.y - 7), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, text_size, Color("a3a699") if grayscale and HeroicCommandArt.enabled() else (Color("ddd2b3") if HeroicCommandArt.enabled() else Color("e2e5d0")))
	if required_tier > 0:
		var badge := Rect2(size.x - 31, 3, 28, 18)
		draw_rect(badge, Color("242b29") if HeroicCommandArt.enabled() else Color("182f3e"))
		draw_rect(badge, Color("8e8267") if HeroicCommandArt.enabled() else Color("94a4ad"), false, 1)
		draw_string(font, badge.position + Vector2(0, 13), "%d级" % required_tier, HORIZONTAL_ALIGNMENT_CENTER, 28, 12, Color("d0d9df"))
	_draw_factual_badge(str(semantics.badge))
	if cooldown > 0:
		# Cooldown dims artwork, not the caption the player needs to identify it.
		draw_rect(Rect2(5, 3, maxf(size.x - 10, 1), maxf(size.y - 25, 1)), Color(0.02, 0.08, 0.08, 0.68))
		draw_string(font, Vector2(0, 35), str(ceili(cooldown)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color.WHITE)
	# Testable real draw state: this is emitted from the same notification
	# which paints the pressure offset, frame and masks, not a fake state API.
	set_meta("painted_draw_state", {"state":state, "factual_state":factual_state, "badge":str(semantics.badge), "grayscale":grayscale, "icon_center":center, "cooldown":cooldown, "required_tier":required_tier, "surface_size":size})

func _draw_factual_badge(badge: String) -> void:
	if HeroicCommandArt.enabled():
		HeroicCommandArt.draw_status_badge(self, Vector2(11, 12), badge)
		return
	if not FrontierCommandArt.enabled(): return
	FrontierCommandArt.draw_status_badge(self, Vector2(11, 12), badge)

static func draw_symbol(canvas: CanvasItem, symbol: String, center: Vector2, color: Color, scale_factor: float = 1.0) -> void:
	if symbol.is_empty(): return # Empty bag slots keep only their quiet frame.
	if symbol in ["gold", "ESSENCE_MINE"]:
		var s := maxf(scale_factor,0.1)
		# Pixel-stepped gold bars: a currency, not the retired crystal mine.
		for part: Array in [[-15,2,30,11,"161b20"],[-12,0,24,10,"936225"],[-10,-3,20,9,"e8b94d"],[-7,-3,12,3,"ffe3a0"],[-6,8,20,5,"b77e2e"],[0,6,12,3,"f4cc6a"]]:
			canvas.draw_rect(Rect2((center+Vector2(part[0],part[1])*s).round(),Vector2(part[2],part[3])*s),Color(part[4]) if color.r>0.3 else color)
		return
	if symbol == "essence":
		# Original stepped crystal pixels, not a smooth vector gem. A shared
		# economic silhouette remains legible at HUD and catalog sizes.
		var s := maxf(scale_factor, 0.1)
		for part: Array in [[-11,4,8,9,"5d496f"],[-4,-11,9,24,"463d62"],[-2,-15,5,27,"9c79bc"],[-1,-10,2,17,"e2cfed"],[6,-4,6,16,"785896"],[7,-8,3,15,"c6a5dc"],[-10,-1,4,11,"b493cc"],[-14,13,30,3,"bba575"]]:
			canvas.draw_rect(Rect2((center+Vector2(part[0],part[1])*s).round(),Vector2(part[2],part[3])*s),Color(part[4]) if color.r > 0.3 else color)
		if symbol == "ESSENCE_MINE":
			canvas.draw_rect(Rect2(center+Vector2(-17,-17)*s,Vector2(3,31)*s),Color("9b794e"))
			canvas.draw_rect(Rect2(center+Vector2(14,-17)*s,Vector2(3,31)*s),Color("9b794e"))
			canvas.draw_rect(Rect2(center+Vector2(-17,-19)*s,Vector2(34,4)*s),Color("ccb27f"))
		return
	if HeroicCommandArt.draw_symbol(canvas, symbol, center, color, scale_factor): return
	if CollectionIcons.draw_symbol(canvas, symbol, center, color, scale_factor): return
	if FrontierCommandArt.draw_symbol(canvas, symbol, center, color, scale_factor): return
	var s := scale_factor
	match symbol:
		"health":
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, 16) * s, center + Vector2(-15, 1) * s, center + Vector2(-15, -8) * s, center + Vector2(-8, -15) * s, center + Vector2(0, -8) * s, center + Vector2(8, -15) * s, center + Vector2(15, -8) * s, center + Vector2(15, 1) * s]), color)
		"range":
			canvas.draw_arc(center, 13 * s, 0, TAU, 24, color, 2 * s)
			canvas.draw_arc(center, 6 * s, 0, TAU, 16, color, 2 * s)
			for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				canvas.draw_line(center + direction * 9 * s, center + direction * 19 * s, color, 2 * s)
		"food", "economy":
			canvas.draw_line(center + Vector2(0, -16) * s, center + Vector2(0, 15) * s, color, 3 * s)
			for y: int in [-10, -2, 6]:
				canvas.draw_line(center + Vector2(0, y) * s, center + Vector2(-9, y - 6) * s, color, 5 * s)
				canvas.draw_line(center + Vector2(0, y) * s, center + Vector2(9, y - 6) * s, color, 5 * s)
		"material", "build", "worker":
			canvas.draw_line(center + Vector2(-10, 14) * s, center + Vector2(9, -12) * s, color, 5 * s)
			canvas.draw_line(center + Vector2(-4, -14) * s, center + Vector2(15, -4) * s, color, 7 * s)
		"guard", "hinge_guard":
			draw_symbol(canvas, "armor", center + Vector2(3, 2) * s, color, 0.78 * s)
			canvas.draw_line(center + Vector2(-13, 14) * s, center + Vector2(-13, -15) * s, color, 3 * s)
			canvas.draw_line(center + Vector2(-18, 1) * s, center + Vector2(-8, 1) * s, color, 3 * s)
		"lancer", "iron_lancer":
			canvas.draw_line(center + Vector2(-9, 17) * s, center + Vector2(9, -16) * s, color, 4 * s)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(3, -13) * s, center + Vector2(14, -22) * s, center + Vector2(12, -8) * s]), color)
			canvas.draw_line(center + Vector2(-16, 5) * s, center + Vector2(-8, 10) * s, color, 5 * s)
		"population":
			for x: int in [-11, 0, 11]:
				canvas.draw_circle(center + Vector2(x, -6) * s, 4 * s, color)
				canvas.draw_rect(Rect2(center + Vector2(x - 3, 1) * s, Vector2(6, 12) * s), color)
		"army":
			canvas.draw_line(center + Vector2(-9, -17) * s, center + Vector2(-9, 16) * s, color, 3 * s)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -15) * s, center + Vector2(15, -15) * s, center + Vector2(8, -8) * s, center + Vector2(15, -2) * s, center + Vector2(-9, -2) * s]), color)
			for x: int in [-3, 5, 13]: canvas.draw_rect(Rect2(center + Vector2(x - 2, 9) * s, Vector2(4, 7) * s), color)
		"recruit":
			canvas.draw_arc(center + Vector2(-5, -3) * s, 11 * s, PI, TAU, 14, color, 4 * s)
			canvas.draw_line(center + Vector2(-16, -3) * s, center + Vector2(6, -3) * s, color, 4 * s)
			canvas.draw_rect(Rect2(center + Vector2(-12, 1) * s, Vector2(14, 8) * s), color)
			canvas.draw_line(center + Vector2(11, 5) * s, center + Vector2(11, 17) * s, color, 3 * s)
			canvas.draw_line(center + Vector2(5, 11) * s, center + Vector2(17, 11) * s, color, 3 * s)
		"BASE":
			canvas.draw_rect(Rect2(center + Vector2(-13, -1) * s, Vector2(26, 17) * s), color)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-17, -1) * s, center + Vector2(0, -17) * s, center + Vector2(17, -1) * s]), color)
			canvas.draw_rect(Rect2(center + Vector2(-3, 6) * s, Vector2(6, 10) * s), Color("213637"))
			canvas.draw_rect(Rect2(center + Vector2(9, 7) * s, Vector2(8, 8) * s), Color("b89660"))
		"BARRACKS":
			canvas.draw_rect(Rect2(center + Vector2(-16, -6) * s, Vector2(30, 22) * s), color)
			canvas.draw_rect(Rect2(center + Vector2(-11, 0) * s, Vector2(20, 16) * s), Color("213637"))
			canvas.draw_line(center + Vector2(-13, -6) * s, center + Vector2(-13, -20) * s, color, 2 * s)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-13, -20) * s, center + Vector2(0, -20) * s, center + Vector2(-13, -11) * s]), color)
			draw_symbol(canvas, "armor", center + Vector2(2, 6) * s, color, 0.45 * s)
		"RANGE":
			# Two stepped pages and a suspended focus: a magic/support camp,
			# never the old bow that implied every ranged unit trained here.
			canvas.draw_rect(Rect2(center+Vector2(-18,-5)*s,Vector2(16,22)*s),color)
			canvas.draw_rect(Rect2(center+Vector2(2,-5)*s,Vector2(16,22)*s),color)
			canvas.draw_rect(Rect2(center+Vector2(-2,-2)*s,Vector2(4,24)*s),Color("39362e"))
			canvas.draw_rect(Rect2(center+Vector2(-4,-20)*s,Vector2(8,8)*s),Color("e8ca81"))
			canvas.draw_rect(Rect2(center+Vector2(-2,-12)*s,Vector2(4,5)*s),color)
		"FOUNDRY", "tech":
			canvas.draw_rect(Rect2(center + Vector2(-13, -18) * s, Vector2(7, 20) * s), color)
			canvas.draw_rect(Rect2(center + Vector2(-16, -20) * s, Vector2(13, 4) * s), color)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-18, 3) * s, center + Vector2(16, 3) * s, center + Vector2(9, 9) * s, center + Vector2(3, 9) * s, center + Vector2(6, 15) * s, center + Vector2(-11, 15) * s, center + Vector2(-8, 9) * s]), color)
			canvas.draw_rect(Rect2(center + Vector2(1, -7) * s, Vector2(15, 8) * s), Color("cc925c"))
		"ALTAR":
			canvas.draw_rect(Rect2(center + Vector2(-18, 12) * s, Vector2(36, 5) * s), color)
			for x: int in [-12, 12]: canvas.draw_rect(Rect2(center + Vector2(x - 3, -8) * s, Vector2(6, 20) * s), color)
			canvas.draw_rect(Rect2(center + Vector2(-18, -12) * s, Vector2(36, 5) * s), color)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -21) * s, center + Vector2(7, -13) * s, center + Vector2(0, -5) * s, center + Vector2(-7, -13) * s]), Color("c7bd91"))
		"TOWER":
			canvas.draw_rect(Rect2(center + Vector2(-8, -10) * s, Vector2(16, 27) * s), color)
			canvas.draw_rect(Rect2(center + Vector2(-14, -13) * s, Vector2(28, 7) * s), color)
			for x: int in [-11, 0, 11]: canvas.draw_rect(Rect2(center + Vector2(x - 3, -19) * s, Vector2(6, 8) * s), color)
			canvas.draw_line(center + Vector2(0, -4) * s, center + Vector2(0, 8) * s, Color("213637"), 4 * s)
		"resource":
			for x: int in [-13, 0, 13]: canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(x - 7, 14) * s, center + Vector2(x - 5, 4) * s, center + Vector2(x + 3, 0) * s, center + Vector2(x + 7, 14) * s]), Color("a9a18b"))
			draw_symbol(canvas, "material", center + Vector2(0, -6) * s, color, 0.75 * s)
		"village":
			for x: int in [-9, 9]:
				canvas.draw_rect(Rect2(center + Vector2(x - 7, 0) * s, Vector2(14, 13) * s), color)
				canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(x - 10, 0) * s, center + Vector2(x, -10) * s, center + Vector2(x + 10, 0) * s]), color)
				canvas.draw_rect(Rect2(center + Vector2(x - 2, 5) * s, Vector2(4, 8) * s), Color("213637"))
		"armor", "STEADY", "WARD_MAIL":
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-13, -14) * s, center + Vector2(13, -14) * s, center + Vector2(11, 6) * s, center + Vector2(0, 17) * s, center + Vector2(-11, 6) * s]), color)
			canvas.draw_line(center + Vector2(0, -10) * s, center + Vector2(0, 10) * s, Color("294346"), 3 * s)
		"bow", "bright_crossbow":
			canvas.draw_arc(center, 15 * s, -1.2, 1.2, 16, color, 3 * s)
			canvas.draw_line(center + Vector2(5, -14) * s, center + Vector2(5, 14) * s, color, 2 * s)
			canvas.draw_line(center + Vector2(-14, 0) * s, center + Vector2(17, 0) * s, color, 3 * s)
		"hero", "equipment", "RALLY":
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-15, -7) * s, center + Vector2(-8, 2) * s, center + Vector2(0, -14) * s, center + Vector2(8, 2) * s, center + Vector2(15, -7) * s, center + Vector2(12, 13) * s, center + Vector2(-12, 13) * s]), color)
		"potion", "RECOVER", "grove_mender":
			canvas.draw_rect(Rect2(center + Vector2(-4, -16) * s, Vector2(8, 6) * s), color)
			canvas.draw_circle(center + Vector2(0, 4) * s, 12 * s, color)
			canvas.draw_line(center + Vector2(-6, 4) * s, center + Vector2(6, 4) * s, Color("294346"), 3 * s)
			canvas.draw_line(center + Vector2(0, -2) * s, center + Vector2(0, 10) * s, Color("294346"), 3 * s)
		"SHIELD_SHOCK", "BULWARK_WARD", "BULWARK_RECOVER", "STARFIRE", "FROST_BIND", "ARCANE_BURST", "PIERCING_SHOT", "ARROW_RAIN", "QUICKDRAW", "SEAL_STRIKE", "WHIRLWIND", "BLOOD_PACT":
			# These twelve original glyphs share their exact draw data with the
			# read-only metadata test. Existing symbols and fallback stay unchanged.
			for primitive: Array in skill_symbol_metadata(symbol)["primitives"]:
				match primitive[0]:
					"LINE": canvas.draw_line(center + primitive[1] * s, center + primitive[2] * s, color, primitive[3] * s)
					"CUT": canvas.draw_line(center + primitive[1] * s, center + primitive[2] * s, Color("294346"), primitive[3] * s)
					"POLY":
						var points := PackedVector2Array()
						for point: Vector2 in primitive[1]: points.append(center + point * s)
						canvas.draw_colored_polygon(points, color)
					"ARC": canvas.draw_arc(center + primitive[1] * s, primitive[2] * s, primitive[3], primitive[4], 24, color, primitive[5] * s)
		"LOOSE", "COLUMN", "SPEAR":
			for n: int in range(6):
				var p := Vector2((n % 3 - 1) * 10, (n / 3) * 14 - 7)
				if symbol == "COLUMN": p = Vector2((n % 2) * 9 - 4, (n / 2) * 11 - 11)
				if symbol == "SPEAR": p = Vector2((n % 3 - 1) * 11, (n / 3) * 12 + absi(n % 3 - 1) * 8 - 10)
				canvas.draw_circle(center + p * s, 3 * s, color)
		"retreat", "home", "move", "attack_move":
			var direction := -1 if symbol in ["retreat", "home"] else 1
			canvas.draw_line(center + Vector2(-14 * direction, 0) * s, center + Vector2(13 * direction, 0) * s, color, 5 * s)
			canvas.draw_line(center + Vector2(3 * direction, -10) * s, center + Vector2(14 * direction, 0) * s, color, 5 * s)
			canvas.draw_line(center + Vector2(3 * direction, 10) * s, center + Vector2(14 * direction, 0) * s, color, 5 * s)
			if symbol == "attack_move":
				canvas.draw_line(center + Vector2(-12, 15) * s, center + Vector2(1, 2) * s, Color("e3b079"), 3 * s)
				canvas.draw_line(center + Vector2(-13, 5) * s, center + Vector2(-3, 15) * s, Color("e3b079"), 2 * s)
		"menu":
			for y: int in [-10, 0, 10]: canvas.draw_line(center + Vector2(-13, y) * s, center + Vector2(13, y) * s, color, 4 * s)
		"cancel":
			canvas.draw_arc(center, 15 * s, 0, TAU, 24, color, 2 * s)
			canvas.draw_line(center + Vector2(-8, -8) * s, center + Vector2(8, 8) * s, color, 3 * s)
			canvas.draw_line(center + Vector2(-8, 8) * s, center + Vector2(8, -8) * s, color, 3 * s)
		_:
			canvas.draw_line(center + Vector2(-10, 13) * s, center + Vector2(12, -15) * s, color, 5 * s)
			canvas.draw_line(center + Vector2(-9, 0) * s, center + Vector2(5, 12) * s, color, 4 * s)
			canvas.draw_line(center + Vector2(-12, 15) * s, center + Vector2(-6, 7) * s, Color("a28751"), 5 * s)


static func skill_symbol_metadata(id: String) -> Dictionary:
	# Local pictogram facts, not game stats or skill mechanics. Geometry is
	# bounded and detached; changing returned metadata cannot alter another draw.
	var archetype := ""
	var glyph := ""
	var primitives: Array = []
	match id:
		"SHIELD_SHOCK":
			archetype = "BULWARK"
			glyph = "impact_shield"
			primitives = [["POLY", [Vector2(-17,-13),Vector2(5,-13),Vector2(3,7),Vector2(-6,17),Vector2(-15,7)]], ["CUT",Vector2(-6,-9),Vector2(-6,9),3.0], ["LINE",Vector2(10,-16),Vector2(7,-7),3.0], ["LINE",Vector2(7,-7),Vector2(16,-1),3.0], ["LINE",Vector2(16,-1),Vector2(10,8),3.0]]
		"BULWARK_WARD":
			archetype = "BULWARK"
			glyph = "fortified_plate"
			primitives = [["POLY", [Vector2(-13,-16),Vector2(13,-16),Vector2(16,-4),Vector2(11,10),Vector2(0,18),Vector2(-11,10),Vector2(-16,-4)]], ["CUT",Vector2(-8,-7),Vector2(8,-7),3.0], ["CUT",Vector2(-8,2),Vector2(8,2),3.0], ["CUT",Vector2(0,-12),Vector2(0,12),3.0], ["LINE",Vector2(-19,-9),Vector2(-19,8),2.0], ["LINE",Vector2(19,-9),Vector2(19,8),2.0]]
		"BULWARK_RECOVER":
			archetype = "BULWARK"
			glyph = "sheltering_cross"
			primitives = [["ARC",Vector2.ZERO,17.0,0.0,PI,3.0], ["POLY", [Vector2(-14,-15),Vector2(-5,-15),Vector2(-6,-3),Vector2(-10,2),Vector2(-13,-3)]], ["LINE",Vector2(5,-13),Vector2(5,7),6.0], ["LINE",Vector2(-4,-3),Vector2(14,-3),6.0]]
		"STARFIRE":
			archetype = "ARCANIST"
			glyph = "rising_star_flame"
			primitives = [["POLY", [Vector2(0,-19),Vector2(3,-6),Vector2(10,-11),Vector2(15,2),Vector2(10,14),Vector2(0,18),Vector2(-11,12),Vector2(-15,0),Vector2(-7,4),Vector2(-5,-9)]], ["CUT",Vector2(0,3),Vector2(0,12),3.0], ["LINE",Vector2(-17,-12),Vector2(-14,-8),2.0], ["LINE",Vector2(16,-16),Vector2(13,-10),2.0]]
		"FROST_BIND":
			archetype = "ARCANIST"
			glyph = "binding_snowflake"
			for angle: float in [0.0,PI/3.0,2.0*PI/3.0]:
				var axis := Vector2(cos(angle),sin(angle))
				var wing := Vector2(-axis.y,axis.x)
				primitives.append(["LINE",-axis*17.0,axis*17.0,3.0])
				for sign_value: float in [-1.0,1.0]:
					primitives.append(["LINE",axis*sign_value*12.0+wing*5.0,axis*sign_value*7.0,2.0])
					primitives.append(["LINE",axis*sign_value*12.0-wing*5.0,axis*sign_value*7.0,2.0])
		"ARCANE_BURST":
			archetype = "ARCANIST"
			glyph = "radial_arcane_burst"
			primitives = [["ARC",Vector2.ZERO,18.0,0.0,TAU,2.0], ["POLY", [Vector2(0,-14),Vector2(4,-5),Vector2(12,-12),Vector2(6,-2),Vector2(15,0),Vector2(6,3),Vector2(12,12),Vector2(3,6),Vector2(0,15),Vector2(-3,6),Vector2(-12,12),Vector2(-6,3),Vector2(-15,0),Vector2(-6,-3),Vector2(-12,-12),Vector2(-4,-5)]], ["CUT",Vector2(-3,0),Vector2(3,0),4.0]]
		"PIERCING_SHOT":
			archetype = "RANGER"
			glyph = "single_piercing_arrow"
			primitives = [["ARC",Vector2(5,-4),10.0,-0.7,0.7,2.0], ["ARC",Vector2(5,-4),10.0,2.5,3.8,2.0], ["LINE",Vector2(-15,16),Vector2(13,-13),4.0], ["POLY", [Vector2(5,-14),Vector2(17,-17),Vector2(14,-5)]], ["LINE",Vector2(-15,6),Vector2(-5,16),3.0]]
		"ARROW_RAIN":
			archetype = "RANGER"
			glyph = "three_falling_arrows"
			for offset: Vector2 in [Vector2(-11,-2),Vector2(0,3),Vector2(11,-4)]:
				primitives.append(["LINE",offset+Vector2(0,-13),offset+Vector2(0,11),3.0])
				primitives.append(["POLY",[offset+Vector2(-5,6),offset+Vector2(0,15),offset+Vector2(5,6)]])
		"QUICKDRAW":
			archetype = "RANGER"
			glyph = "rapid_arrow_trails"
			primitives = [["LINE",Vector2(-7,0),Vector2(15,0),4.0], ["POLY", [Vector2(8,-7),Vector2(18,0),Vector2(8,7)]], ["LINE",Vector2(-18,-10),Vector2(2,-10),3.0], ["LINE",Vector2(-18,10),Vector2(2,10),3.0], ["LINE",Vector2(-18,0),Vector2(-12,0),3.0], ["LINE",Vector2(-2,-16),Vector2(6,-10),2.0], ["LINE",Vector2(-2,16),Vector2(6,10),2.0]]
		"SEAL_STRIKE":
			archetype = "DUELIST"
			glyph = "sealed_blade"
			primitives = [["LINE",Vector2(-14,-12),Vector2(7,-12),3.0], ["LINE",Vector2(-14,-12),Vector2(-14,9),3.0], ["LINE",Vector2(-14,9),Vector2(7,9),3.0], ["LINE",Vector2(7,-12),Vector2(7,9),3.0], ["LINE",Vector2(-9,15),Vector2(15,-16),5.0], ["LINE",Vector2(-10,1),Vector2(4,13),4.0], ["LINE",Vector2(10,10),Vector2(18,10),3.0], ["LINE",Vector2(14,6),Vector2(14,14),3.0]]
		"WHIRLWIND":
			archetype = "DUELIST"
			glyph = "orbiting_blades"
			primitives = [["ARC",Vector2.ZERO,15.0,-2.7,-0.1,3.0], ["ARC",Vector2.ZERO,15.0,0.4,3.0,3.0], ["POLY", [Vector2(12,-8),Vector2(18,1),Vector2(8,2)]], ["POLY", [Vector2(-12,8),Vector2(-18,-1),Vector2(-8,-2)]], ["LINE",Vector2(-6,7),Vector2(7,-7),4.0], ["LINE",Vector2(-8,0),Vector2(0,8),3.0]]
		"BLOOD_PACT":
			archetype = "DUELIST"
			glyph = "life_drop_pact"
			primitives = [["POLY", [Vector2(0,-19),Vector2(6,-7),Vector2(12,2),Vector2(11,10),Vector2(5,16),Vector2(-5,16),Vector2(-11,10),Vector2(-12,2),Vector2(-6,-7)]], ["CUT",Vector2(-6,6),Vector2(6,6),3.0], ["CUT",Vector2(0,0),Vector2(0,12),3.0], ["LINE",Vector2(-18,-6),Vector2(-14,-2),2.0], ["LINE",Vector2(18,-6),Vector2(14,-2),2.0]]
	if primitives.is_empty(): return {}
	return {"id":id,"archetype":archetype,"glyph":glyph,"primitives":primitives.duplicate(true)}

func _get_tooltip(_at_position: Vector2) -> String:
	return preload("res://src/presentation/strategic_native_tooltip_gate.gd").native_text(self)
