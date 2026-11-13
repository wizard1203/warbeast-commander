class_name PixelBattleRenderer
extends RefCounted
## Original, code-native pixel silhouettes. Every entry point draws only the
## values supplied by its caller: no snapshot reads, commands, collision, RNG,
## timers or authority references live here. Call from a Node2D's _draw().
## The native M9 maximum (64 soldiers, 12 workers, 2 beasts, 1 workshop,
## four economic sites, 1 flat spring and 2 hero badges) is <=1,696 primitives.
## Terrain plus economic-site props and spring uses at most 262 primitives.

const MAX_SOLDIER_PRIMITIVES := 18
const MAX_WORKER_PRIMITIVES := 15
const MAX_BEAST_PRIMITIVES := 34
const MAX_WORKSHOP_PRIMITIVES := 22
const MAX_TERRAIN_PRIMITIVES := 118
const MAX_FOOD_SITE_PRIMITIVES := 56
const MAX_MATERIAL_SITE_PRIMITIVES := 25
const MAX_DEPOT_SITE_PRIMITIVES := 25
const MAX_CONSTRUCTION_SITE_PRIMITIVES := 8
const MAX_SPRING_PRIMITIVES := 30
const MAX_HERO_BADGE_PRIMITIVES := 6

const INK := Color("172226")
const SHADOW := Color(0.035, 0.055, 0.055, 0.48)
const STEEL := Color("9aadb0")
const STEEL_LIGHT := Color("d7dcce")
const STEEL_DARK := Color("536a70")
const SKIN := Color("dbb783")
const LEATHER := Color("795c43")
const WOOD := Color("ac8156")
const WOOD_DARK := Color("604936")
const GOLD := Color("dcc47a")
const CLOTH_PLAYER := Color("4fafd2")
const CLOTH_AI := Color("d17055")
const CLOTH_PLAYER_DARK := Color("2c6576")
const CLOTH_AI_DARK := Color("81453e")
const FOOD := Color("8db369")
const MATERIAL := Color("c49b65")
const BUILDING := Color("afa0ca")


static func draw_soldier(canvas: Node2D, center: Vector2, unit_type: String,
		side: String, radius: float, alive: bool, facing: String, tick: int) -> void:
	# A 14 by 15 local-pixel figure is roughly 16 by 18 screen pixels at the
	# default radius. Small silhouettes may extend a little beyond the footprint;
	# they deliberately do not replace the authoritative hit/collision region.
	var pixel := clampf(radius / 6.0, 0.75, 1.8)
	var origin := center.round()
	var mirror := facing == "WEST" or facing == "NORTH"
	var cloth := CLOTH_PLAYER if side == "PLAYER" else CLOTH_AI
	var cloth_dark := CLOTH_PLAYER_DARK if side == "PLAYER" else CLOTH_AI_DARK
	_rect(canvas, origin, pixel, Rect2(-6, 4, 12, 3), SHADOW)
	if not alive:
		# A fallen horizontal silhouette, not a standing colored circle. No blood
		# animation or damage event is invented by presentation.
		_rect(canvas, origin, pixel, Rect2(-5, 1, 9, 3), STEEL_DARK)
		_rect(canvas, origin, pixel, Rect2(-1, 0, 5, 2), cloth_dark)
		_rect(canvas, origin, pixel, Rect2(4, 2, 2, 2), LEATHER)
		return
	var step := 1 if posmod(tick / 6, 2) == 1 else 0
	_rect(canvas, origin, pixel, Rect2(-3, 2 + step, 2, 4), INK, mirror)
	_rect(canvas, origin, pixel, Rect2(1, 3 - step, 2, 3), INK, mirror)
	if unit_type == "bright_crossbow":
		# Narrow hood and leather tunic, with the broad crossbow perpendicular to
		# its stock: the weapon shape is distinct even without faction color.
		_rect(canvas, origin, pixel, Rect2(-4, -3, 7, 7), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(-3, -2, 5, 5), cloth_dark, mirror)
		_rect(canvas, origin, pixel, Rect2(-3, -2, 1, 5), WOOD, mirror)
		_rect(canvas, origin, pixel, Rect2(-3, -8, 6, 6), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(-2, -7, 4, 2), cloth, mirror)
		_rect(canvas, origin, pixel, Rect2(0, -5, 2, 2), SKIN, mirror)
		_rect(canvas, origin, pixel, Rect2(-3, -4, 2, 2), cloth, mirror)
		_rect(canvas, origin, pixel, Rect2(1, -1, 3, 2), SKIN, mirror)
		_rect(canvas, origin, pixel, Rect2(2, -1, 5, 2), WOOD_DARK, mirror)
		_rect(canvas, origin, pixel, Rect2(5, -4, 2, 7), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(5, -3, 1, 5), WOOD, mirror)
		_rect(canvas, origin, pixel, Rect2(6, -4, 1, 1), STEEL_LIGHT, mirror)
		_rect(canvas, origin, pixel, Rect2(6, 2, 1, 1), STEEL_LIGHT, mirror)
		_rect(canvas, origin, pixel, Rect2(2, -1, 6, 1), GOLD, mirror)
	else:
		# Broad shoulders, metal helmet and a split rectangular shield identify
		# the original hinge guard; the exposed blade is always held, not swung.
		_rect(canvas, origin, pixel, Rect2(-4, -3, 8, 7), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(-3, -2, 6, 5), STEEL, mirror)
		_rect(canvas, origin, pixel, Rect2(-3, 1, 6, 2), cloth, mirror)
		_rect(canvas, origin, pixel, Rect2(-5, -3, 2, 3), STEEL_DARK, mirror)
		_rect(canvas, origin, pixel, Rect2(3, -3, 2, 3), STEEL_LIGHT, mirror)
		_rect(canvas, origin, pixel, Rect2(-3, -8, 6, 5), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(-2, -7, 4, 3), STEEL, mirror)
		_rect(canvas, origin, pixel, Rect2(0, -5, 3, 1), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(-2, -7, 3, 1), STEEL_LIGHT, mirror)
		_rect(canvas, origin, pixel, Rect2(-6, -2, 4, 6), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(-5, -1, 2, 4), cloth, mirror)
		_rect(canvas, origin, pixel, Rect2(-4, -1, 1, 4), GOLD, mirror)
		_rect(canvas, origin, pixel, Rect2(4, -5, 2, 5), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(4, -5, 1, 4), STEEL_LIGHT, mirror)
		_rect(canvas, origin, pixel, Rect2(3, -1, 3, 1), GOLD, mirror)


static func draw_hero_badge(canvas: Node2D, center: Vector2, radius: float) -> void:
	# Four original helmet-crest primitives on an existing living member. No
	# new entity, health pool, command or collision/hit region is introduced.
	var pixel := clampf(radius / 6.0, 0.75, 1.8)
	var origin := center.round()
	_rect(canvas, origin, pixel, Rect2(-3, -7, 6, 2), GOLD)
	_rect(canvas, origin, pixel, Rect2(-3, -8, 1, 2), GOLD)
	_rect(canvas, origin, pixel, Rect2(-1, -9, 2, 2), GOLD)
	_rect(canvas, origin, pixel, Rect2(2, -8, 1, 2), GOLD)


static func draw_worker(canvas: Node2D, center: Vector2, role: String,
		radius: float, cargo_amount: int, tick: int) -> void:
	var pixel := clampf(radius / 5.0, 0.7, 1.6)
	var origin := center.round()
	var role_color := FOOD
	match role:
		"MATERIAL": role_color = MATERIAL
		"CONSTRUCTION_REPAIR": role_color = BUILDING
		"RESERVE": role_color = STEEL
	var step := 1 if posmod(tick / 7, 2) == 1 else 0
	_rect(canvas, origin, pixel, Rect2(-5, 4, 10, 2), SHADOW)
	_rect(canvas, origin, pixel, Rect2(-2, 2 + step, 1, 3), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(1, 3 - step, 1, 2), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(-3, -2, 6, 5), INK)
	_rect(canvas, origin, pixel, Rect2(-2, -1, 4, 4), role_color)
	_rect(canvas, origin, pixel, Rect2(-2, -5, 4, 3), SKIN)
	_rect(canvas, origin, pixel, Rect2(-3, -6, 6, 2), WOOD)
	_rect(canvas, origin, pixel, Rect2(-2, -7, 4, 1), GOLD)
	_rect(canvas, origin, pixel, Rect2(2, -1, 2, 2), SKIN)
	# Work tools are carried in a resting pose. Only real snapshot cargo adds a
	# bundle; neither step pose nor role icon promises current gathering.
	match role:
		"FOOD":
			_rect(canvas, origin, pixel, Rect2(4, -4, 1, 7), WOOD_DARK)
			_rect(canvas, origin, pixel, Rect2(4, -5, 3, 1), STEEL_LIGHT)
			_rect(canvas, origin, pixel, Rect2(6, -4, 1, 2), STEEL)
		"MATERIAL", "CONSTRUCTION_REPAIR":
			_rect(canvas, origin, pixel, Rect2(4, -4, 1, 7), WOOD)
			_rect(canvas, origin, pixel, Rect2(3, -5, 4, 2), STEEL_DARK)
			_rect(canvas, origin, pixel, Rect2(3, -5, 3, 1), STEEL_LIGHT)
		_:
			_rect(canvas, origin, pixel, Rect2(4, -1, 1, 4), WOOD)
	if cargo_amount > 0:
		_rect(canvas, origin, pixel, Rect2(-5, -2, 3, 4), WOOD_DARK)
		_rect(canvas, origin, pixel, Rect2(-5, -2, 2, 3), role_color)
		_rect(canvas, origin, pixel, Rect2(-5, -1, 3, 1), GOLD)


static func draw_beast(canvas: Node2D, center: Vector2, side: String,
		radius: float, state: String, tick: int) -> void:
	var pixel := clampf(radius / 15.0, 0.8, 3.0)
	var origin := center.round()
	var mirror := side != "PLAYER"
	var cloth := CLOTH_PLAYER if side == "PLAYER" else CLOTH_AI
	var cloth_dark := CLOTH_PLAYER_DARK if side == "PLAYER" else CLOTH_AI_DARK
	var hide := Color("697e79")
	var hide_light := Color("8b9b82")
	var armor := STEEL
	if state == "SUPPRESSED":
		armor = STEEL_DARK
		cloth = GOLD
		cloth_dark = WOOD_DARK
	elif state == "EVACUATED":
		hide = STEEL_DARK
		hide_light = STEEL_DARK
		armor = WOOD_DARK
		cloth = LEATHER
		cloth_dark = WOOD_DARK
	# Four articulated feet, a tapered head and two flat ivory horns make a
	# creature rather than a square base. The fixed body never visually walks;
	# tick changes only its small eye glint, not a movement/attack effect.
	_rect(canvas, origin, pixel, Rect2(-12, 5, 25, 5), SHADOW)
	for foot_x: int in [-9, -3, 3, 9]:
		_rect(canvas, origin, pixel, Rect2(foot_x, 3, 3, 6), INK, mirror)
		_rect(canvas, origin, pixel, Rect2(foot_x, 6, 3, 2), hide, mirror)
	_rect(canvas, origin, pixel, Rect2(-14, -1, 4, 2), INK, mirror)
	_rect(canvas, origin, pixel, Rect2(-14, 0, 2, 2), hide, mirror)
	_rect(canvas, origin, pixel, Rect2(-11, -6, 21, 12), INK, mirror)
	_rect(canvas, origin, pixel, Rect2(-10, -5, 19, 10), hide, mirror)
	_rect(canvas, origin, pixel, Rect2(-9, 0, 16, 3), hide_light, mirror)
	_rect(canvas, origin, pixel, Rect2(-9, -7, 16, 7), STEEL_DARK, mirror)
	_rect(canvas, origin, pixel, Rect2(-8, -6, 14, 3), armor, mirror)
	_rect(canvas, origin, pixel, Rect2(-8, -6, 13, 1), STEEL_LIGHT, mirror)
	_rect(canvas, origin, pixel, Rect2(-4, -8, 8, 5), cloth_dark, mirror)
	_rect(canvas, origin, pixel, Rect2(-3, -8, 6, 2), cloth, mirror)
	_rect(canvas, origin, pixel, Rect2(6, -5, 7, 8), INK, mirror)
	_rect(canvas, origin, pixel, Rect2(7, -4, 5, 6), hide_light, mirror)
	_rect(canvas, origin, pixel, Rect2(7, -5, 5, 2), armor, mirror)
	var eye := GOLD if state == "SUPPRESSED" else STEEL_LIGHT
	if state != "EVACUATED" and posmod(tick / 50, 8) != 7:
		_rect(canvas, origin, pixel, Rect2(10, -2, 1, 1), eye, mirror)
	_rect(canvas, origin, pixel, Rect2(11, 0, 4, 3), INK, mirror)
	_rect(canvas, origin, pixel, Rect2(12, 0, 2, 2), hide, mirror)
	_rect(canvas, origin, pixel, Rect2(8, 3, 5, 1), LEATHER, mirror)
	_rect(canvas, origin, pixel, Rect2(9, -8, 2, 4), INK, mirror)
	_rect(canvas, origin, pixel, Rect2(9, -8, 1, 3), GOLD, mirror)
	_rect(canvas, origin, pixel, Rect2(13, -4, 2, 4), INK, mirror)
	_rect(canvas, origin, pixel, Rect2(13, -4, 1, 3), GOLD, mirror)
	_rect(canvas, origin, pixel, Rect2(-6, -12, 1, 7), WOOD_DARK, mirror)
	_rect(canvas, origin, pixel, Rect2(-5, -12, 6, 3), cloth, mirror)
	_rect(canvas, origin, pixel, Rect2(-4, -11, 2, 1), GOLD, mirror)


static func draw_workshop(canvas: Node2D, center: Vector2, radius: float,
		state: String, progress: float, _tick: int) -> void:
	var pixel := clampf(radius / 17.0, 0.8, 3.0)
	var origin := center.round()
	_rect(canvas, origin, pixel, Rect2(-15, 7, 30, 5), SHADOW)
	# Stakes indicate the existing permanent foundation, not newly solid walls.
	_rect(canvas, origin, pixel, Rect2(-13, -7, 2, 3), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(11, -7, 2, 3), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(-13, 7, 2, 3), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(11, 7, 2, 3), WOOD_DARK)
	if state == "EMPTY":
		_rect(canvas, origin, pixel, Rect2(-5, 2, 10, 2), WOOD)
		return
	_rect(canvas, origin, pixel, Rect2(-12, 5, 24, 5), STEEL_DARK)
	_rect(canvas, origin, pixel, Rect2(-11, 5, 22, 2), STEEL)
	_rect(canvas, origin, pixel, Rect2(-10, -3, 3, 9), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(7, -3, 3, 9), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(-9, -3, 1, 8), WOOD)
	_rect(canvas, origin, pixel, Rect2(7, -3, 1, 8), WOOD)
	var completed := state == "BUILT"
	var work_fraction := clampf(progress, 0.0, 1.0)
	if completed or work_fraction >= 0.5:
		_polygon(canvas, origin, pixel, [Vector2(-13, -3), Vector2(0, -12), Vector2(13, -3), Vector2(13, 0), Vector2(-13, 0)], INK)
		_polygon(canvas, origin, pixel, [Vector2(-11, -3), Vector2(0, -10), Vector2(11, -3), Vector2(11, -1), Vector2(-11, -1)], CLOTH_PLAYER_DARK)
		_rect(canvas, origin, pixel, Rect2(-8, -2, 16, 1), CLOTH_PLAYER)
	else:
		_rect(canvas, origin, pixel, Rect2(-11, -4, 22, 2), WOOD)
		_rect(canvas, origin, pixel, Rect2(-1, -10, 2, 7), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(-4, 0, 8, 6), INK)
	_rect(canvas, origin, pixel, Rect2(-4, 7, 8, 2), WOOD)
	_rect(canvas, origin, pixel, Rect2(5, 3, 8, 2), WOOD_DARK)
	_rect(canvas, origin, pixel, Rect2(8, 1, 3, 2), STEEL)
	if completed:
		_rect(canvas, origin, pixel, Rect2(2, -9, 1, 6), WOOD_DARK)
		_rect(canvas, origin, pixel, Rect2(3, -9, 4, 3), GOLD)
		_rect(canvas, origin, pixel, Rect2(4, -8, 2, 1), WOOD_DARK)


static func draw_terrain(canvas: Node2D, arena_rect: Rect2) -> void:
	# arena_rect is the complete projected world, never the current visible
	# camera viewport. Normalized anchors therefore stay attached to the world
	# during pan/zoom. All flat patches and tracks are decorative and passable:
	# no trees, tall rocks, walls, collision or terrain bonuses are implied.
	var grass_base := Color("273d34")
	var grass_dark := Color("22382f")
	var grass_light := Color("304639")
	var meadow := Color("2b4136")
	var camp := Color("323e34")
	var camp_edge := Color("2d3b32")
	var dirt := Color("3b4134")
	var dirt_edge := Color("343c32")
	canvas.draw_rect(arena_rect, grass_base)
	# Two worn, flat campgrounds frame the existing opposing objectives, not
	# new structures. The smaller strips remain visibly open on every side.
	for camp_x: float in [0.12, 0.68]:
		_ground_rect(canvas, arena_rect, Rect2(camp_x, 0.30, 0.20, 0.40), camp_edge)
		_ground_rect(canvas, arena_rect, Rect2(camp_x + 0.02, 0.34, 0.16, 0.32), camp)
		_ground_rect(canvas, arena_rect, Rect2(camp_x + 0.06, 0.30, 0.07, 0.40), camp)
	# Eight broad meadow patches are dark enough to leave bodies and markers
	# primary. Rectangles, not fake elevation contours, preserve terrain truth.
	for patch: int in range(8):
		var x := 0.08 + float(posmod(patch * 7, 11)) * 0.075
		var y := 0.06 if patch < 4 else 0.78
		_ground_rect(canvas, arena_rect, Rect2(x, y, 0.09, 0.10), meadow)
	# The continuous stepped track joins both campgrounds; no movement-speed
	# benefit or pathfinding authority lives here. Edge strips are also ground.
	for segment: int in range(7):
		var x := 0.13 + float(segment) * 0.105
		var y := 0.46 + float(posmod(segment, 3) - 1) * 0.012
		_ground_rect(canvas, arena_rect, Rect2(x, y - 0.010, 0.112, 0.085), dirt_edge)
		_ground_rect(canvas, arena_rect, Rect2(x, y, 0.112, 0.065), dirt)
	# A narrow service track connects the already-existing economy sites on
	# the western side. It is not a fence, map boundary or new resource route.
	_ground_rect(canvas, arena_rect, Rect2(0.037, 0.11, 0.033, 0.78), dirt_edge)
	_ground_rect(canvas, arena_rect, Rect2(0.049, 0.11, 0.013, 0.78), dirt)
	_ground_rect(canvas, arena_rect, Rect2(0.062, 0.49, 0.083, 0.025), dirt)
	# Fixed 12 by 6 grass flecks retain deterministic, bounded draw cost.
	for row: int in range(6):
		for column: int in range(12):
			var offset := Vector2(float(posmod(column * 7 + row * 3, 9)) / 12.0, float(posmod(row * 5 + column, 7)) / 10.0)
			var position := (Vector2(column, row) + offset) / Vector2(12, 6)
			_ground_rect(canvas, arena_rect, Rect2(position, Vector2(0.011, 0.010)), grass_dark if posmod(column + row, 3) == 0 else grass_light)
	# Fourteen subtle dry-grass strips give the battle lane a worn edge. These
	# are flat color, never apparent barricades or inaccessible thickets.
	for strip: int in range(14):
		var x := 0.15 + float(strip) * 0.05
		var y := 0.425 if posmod(strip, 2) == 0 else 0.56
		_ground_rect(canvas, arena_rect, Rect2(x, y, 0.016, 0.005), Color("414936"))


static func draw_spring(canvas: Node2D, center: Vector2, scale: float, owner: String) -> void:
	# A flat, passable fissure, not a raised building, fence or collision body.
	# Twelve supplied-value-only primitives leave living troops visually primary.
	var origin := center.round()
	var pixel := maxf(0.1, scale)
	var water := CLOTH_PLAYER if owner == "PLAYER" else CLOTH_AI if owner == "AI" else GOLD
	_rect(canvas, origin, pixel, Rect2(-24, -10, 48, 20), Color("33493f"))
	_rect(canvas, origin, pixel, Rect2(-17, -16, 34, 32), Color("33493f"))
	_rect(canvas, origin, pixel, Rect2(-19, -7, 38, 14), INK)
	_rect(canvas, origin, pixel, Rect2(-12, -11, 24, 22), INK)
	_rect(canvas, origin, pixel, Rect2(-15, -4, 30, 8), water.darkened(0.5))
	_rect(canvas, origin, pixel, Rect2(-9, -8, 18, 16), water.darkened(0.5))
	_rect(canvas, origin, pixel, Rect2(-10, -3, 20, 3), water)
	_rect(canvas, origin, pixel, Rect2(-6, 3, 12, 2), water)
	_rect(canvas, origin, pixel, Rect2(-4, -6, 8, 2), water.lightened(0.25))
	_rect(canvas, origin, pixel, Rect2(-25, 4, 7, 2), STEEL_DARK)
	_rect(canvas, origin, pixel, Rect2(18, -5, 8, 2), STEEL_DARK)
	_rect(canvas, origin, pixel, Rect2(8, 12, 9, 2), STEEL_DARK)


static func draw_economy_site(canvas: Node2D, center: Vector2, role: String,
		scale: float) -> void:
	# scale is the caller's world-to-screen multiplier. Keeping it unclamped
	# makes these low ground props follow precisely the same projection as the
	# authoritative site footpoint. Props are static site identity, not stock
	# quantity, obstacle bounds or a promise that a worker is currently working.
	if not is_finite(scale) or scale <= 0.0:
		return
	var origin := center.round()
	match role:
		"FOOD":
			# Original low grain beds: dark worked soil, short green blades and
			# small muted seed heads. Workers can still walk through the beds.
			for row: int in range(3):
				var y := -20.0 + float(row) * 15.0
				_rect(canvas, origin, scale, Rect2(-42, y, 84, 11), Color("3b4032"))
				_rect(canvas, origin, scale, Rect2(-40, y + 2, 80, 7), Color("444432"))
				for column: int in range(5):
					var x := -33.0 + float(column) * 16.0
					_rect(canvas, origin, scale, Rect2(x, y + 3, 2, 6), Color("5f7746"))
					_rect(canvas, origin, scale, Rect2(x - 2, y + 2, 3, 3), Color("809254"))
					_rect(canvas, origin, scale, Rect2(x + 1, y + 4, 3, 2), Color("72864d"))
			# A low collection mat beside the plot is decorative, not inventory.
			_rect(canvas, origin, scale, Rect2(27, 25, 17, 6), Color("343e30"))
			_rect(canvas, origin, scale, Rect2(28, 26, 15, 4), Color("786e47"))
			_rect(canvas, origin, scale, Rect2(30, 26, 2, 4), Color("938157"))
			_rect(canvas, origin, scale, Rect2(36, 26, 2, 4), Color("938157"))
			_rect(canvas, origin, scale, Rect2(28, 28, 15, 1), Color("554d36"))
		"MATERIAL":
			# Low stacked cut timber, not a dense forest, new mineral resource
			# or solid stack. Dark ends and seams read as wood at overview scale.
			_rect(canvas, origin, scale, Rect2(-39, -20, 80, 45), Color("333e31"))
			for log_index: int in range(7):
				var column := log_index % 2
				var row := log_index / 2
				var x := -35.0 + float(column) * 39.0
				var y := -17.0 + float(row) * 10.0
				_rect(canvas, origin, scale, Rect2(x, y, 32, 7), Color("65563c"))
				_rect(canvas, origin, scale, Rect2(x + 1, y + 1, 28, 2), Color("847047"))
				_rect(canvas, origin, scale, Rect2(x + 29, y + 1, 3, 5), Color("9b8657"))
			_rect(canvas, origin, scale, Rect2(-25, -18, 2, 35), Color("444637"))
			_rect(canvas, origin, scale, Rect2(16, -18, 2, 25), Color("444637"))
			_rect(canvas, origin, scale, Rect2(-27, 20, 51, 2), Color("4c4d38"))
		"DEPOT":
			# Open warehouse ground yard: pallet strips and low tied containers,
			# never a roof/wall footprint or a visual count of available stock.
			_rect(canvas, origin, scale, Rect2(-43, -27, 86, 58), Color("354036"))
			for line: int in range(4):
				_rect(canvas, origin, scale, Rect2(-37, -21 + line * 13, 74, 2), Color("4a4d3d"))
			for bundle: int in range(4):
				var x := -32.0 + float(bundle % 2) * 39.0
				var y := -17.0 + float(bundle / 2) * 25.0
				_rect(canvas, origin, scale, Rect2(x - 2, y + 9, 26, 4), Color("28372e"))
				_rect(canvas, origin, scale, Rect2(x, y, 22, 12), Color("695f43"))
				_rect(canvas, origin, scale, Rect2(x + 1, y + 1, 20, 3), Color("89764e"))
				_rect(canvas, origin, scale, Rect2(x + 9, y, 2, 12), Color("a08b5a"))
				_rect(canvas, origin, scale, Rect2(x, y + 6, 22, 1), Color("4d4b35"))
		"CONSTRUCTION_REPAIR":
			# Flat supply mat and spare planks mark the existing muster site;
			# the actual workshop remains a separate authoritative entity.
			_rect(canvas, origin, scale, Rect2(-27, -18, 56, 36), Color("343e35"))
			for plank: int in range(3):
				_rect(canvas, origin, scale, Rect2(-23, -13 + plank * 9, 30, 5), Color("655e46"))
				_rect(canvas, origin, scale, Rect2(-22, -12 + plank * 9, 28, 1), Color("82744f"))
			_rect(canvas, origin, scale, Rect2(13, -8, 9, 17), Color("616b62"))
		"RESERVE":
			# Optional read-only marker for a future caller; the current snapshot
			# has no distinct reserve site and this does not invent one.
			_rect(canvas, origin, scale, Rect2(-18, -10, 36, 20), Color("304036"))


static func _ground_rect(canvas: Node2D, arena_rect: Rect2,
		normalized_rect: Rect2, color: Color) -> void:
	var projected := Rect2(arena_rect.position + normalized_rect.position * arena_rect.size,
		normalized_rect.size * arena_rect.size)
	# Geometric intersection also protects very small projected worlds. Every
	# terrain primitive remains inside the supplied full-world rectangle even
	# when pixel coordinates are fractional; camera clipping is caller-owned.
	var contained := projected.intersection(arena_rect)
	if contained.has_area():
		canvas.draw_rect(contained, color)


static func _rect(canvas: Node2D, origin: Vector2, pixel: float,
		local_rect: Rect2, color: Color, mirror: bool = false) -> void:
	var x := -local_rect.end.x if mirror else local_rect.position.x
	canvas.draw_rect(Rect2(origin + Vector2(x, local_rect.position.y) * pixel, local_rect.size * pixel), color)


static func _polygon(canvas: Node2D, origin: Vector2, pixel: float,
		local_points: Array, color: Color) -> void:
	var points := PackedVector2Array()
	for point: Vector2 in local_points:
		points.append(origin + point * pixel)
	canvas.draw_colored_polygon(points, color)
