extends RefCounted
## Short original material shapes driven only by an already observed attack.
## These are trajectories, NOT simulated projectiles or proof of a new hit.
## Target injury is exclusively StrategicHitFeedback's HP-difference contract;
## skill ranks, splash eligibility and areas remain in the canonical Pixel path.
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const Sprites = preload("res://src/presentation/strategic_unit_sprites.gd")
const STEEL := Color("d4decf")
const IRON := Color("657b7b")
const WOOD := Color("b89562")
const COPPER := Color("db9861")
const INK := Color("203034")

static func attack_material(unit: Dictionary) -> String:
	if unit.get("body_kind") == "DRAGON": return "FIRE"
	if unit.get("body_kind") == "VEHICLE": return "MECHANICAL"
	if unit.get("unit_type") == "hero":
		var role := str(Heroes.profile(str(unit.get("hero_archetype", "COMMANDER"))).get("role", ""))
		if "法师" in role: return "MAGIC"
		if "射手" in role: return "ARROW"
	if unit.get("role") == "SUPPORT" or unit.get("unit_type") == "grove_mender": return "MAGIC"
	if unit.get("role") == "RANGED" or unit.get("unit_type") == "bright_crossbow":
		return "MECHANICAL" if unit.get("faction_id") == "MACHINE" else "ARROW"
	return "MELEE"

static func weapon_source(center: Vector2, unit: Dictionary, pose: Dictionary, target: Vector2, world_scale: float = 1.0) -> Vector2:
	if not is_finite(world_scale) or world_scale<=0:return center.round()
	var type:=str(unit.get("unit_type","hinge_guard"))
	var recipe: Dictionary=Units.UNITS.get(type,Units.UNITS.hinge_guard)
	var radius:=float(unit.get("radius",recipe.get("radius",12)))
	var observed:=pose.duplicate(true)
	if not observed.has("direction"):observed.direction=(target-center).normalized()
	# Same quantized source recipe and foot projection as the visible body.
	# Effects remain continuous short trajectories; they do not settle damage.
	var offset:=Sprites.weapon_offset(unit,observed,maxf(radius*clampf(world_scale,0.1,5),3))
	return (center.round()+offset).round()

static func draw_attack(canvas: Object, center: Vector2, unit: Dictionary, pose: Dictionary, target: Vector2, world_scale: float = 1.0) -> void:
	if str(pose.get("action", "")) != "ATTACK" or str(unit.get("last_action_kind", "")) != "ATTACK" or int(unit.get("last_action_tick", -1)) < 0 or int(unit.get("hp", 0)) <= 0 or not bool(unit.get("alive", true)): return
	var phase := float(pose.get("phase", -1.0))
	if not is_finite(phase) or phase < 0 or phase >= 1 or not is_finite(world_scale) or world_scale <= 0: return
	var scale_factor := clampf(world_scale, 0.1, 5.0)
	var direction := (target - center).normalized()
	if direction.is_zero_approx(): direction = Vector2.RIGHT
	var material := attack_material(unit)
	var owner := Palette.side_color(str(unit.get("side", "")))
	var source := weapon_source(center,unit,pose,target,scale_factor)
	if material == "MELEE":
		_draw_melee(canvas, source, direction, phase, scale_factor, owner)
	elif material == "ARROW":
		_draw_arrow(canvas, source, target, phase, scale_factor, owner)
	elif material == "MECHANICAL":
		_draw_mechanical(canvas, source, target, phase, scale_factor, owner)
	elif material == "FIRE":
		_draw_fire(canvas, source, target, phase, scale_factor)
	else:
		_draw_magic(canvas, source, target, phase, scale_factor, unit.get("role") == "SUPPORT")

static func draw_tower_shot(canvas: Object, source: Vector2, target: Vector2, age: int, scale_factor: float, side_color: Color) -> void:
	# The caller supplies an actual complete live tower's firing readout.
	# The arrow is a short after-settlement trajectory, never new impact damage.
	if age < 0 or age >= 8 or not is_finite(scale_factor) or scale_factor <= 0: return
	_draw_arrow(canvas,source,target,float(age) / 8.0,clampf(scale_factor,0.1,5.0),side_color)

static func _draw_melee(canvas: Object, source: Vector2, direction: Vector2, phase: float, scale_factor: float, owner: Color) -> void:
	var angle := direction.angle() - 1.05 + phase * 1.7
	var fade := 1.0 - phase
	for index: int in range(4):
		var edge := Vector2.from_angle(angle + index * 0.18)
		var next := Vector2.from_angle(angle + (index + 1) * 0.18)
		var outer := (24 - index) * scale_factor
		var inner := (15 - index) * scale_factor
		canvas.draw_colored_polygon(PackedVector2Array([source + edge * inner,source + edge * outer,source + next * outer,source + next * inner]), Color(STEEL if index < 2 else owner, fade * (0.82 - index * 0.13)))
	var edge := Vector2.from_angle(angle + 0.2)
	canvas.draw_line(source + edge * 9 * scale_factor,source + edge * 24 * scale_factor,Color(STEEL,fade),maxf(scale_factor,1))
	for index: int in range(2):
		var point := source + Vector2.from_angle(angle + index * 0.7) * (18 + phase * 6) * scale_factor
		canvas.draw_rect(Rect2(point,Vector2(2,1) * scale_factor),Color(WOOD,fade))

static func _draw_arrow(canvas: Object, source: Vector2, target: Vector2, phase: float, scale_factor: float, owner: Color) -> void:
	var direction := (target - source).normalized()
	if direction.is_zero_approx(): direction = Vector2.RIGHT
	var normal := direction.orthogonal()
	var tip := source.lerp(target,minf(1.0,phase * 1.5))
	var fade := 1.0 - phase
	canvas.draw_colored_polygon(PackedVector2Array([tip - direction * 14 * scale_factor - normal * scale_factor,tip - normal * scale_factor,tip + normal * scale_factor,tip - direction * 14 * scale_factor + normal * scale_factor]),Color(WOOD,fade))
	canvas.draw_colored_polygon(PackedVector2Array([tip + direction * 3 * scale_factor,tip - direction * 5 * scale_factor + normal * 3 * scale_factor,tip - direction * 5 * scale_factor - normal * 3 * scale_factor]),Color(STEEL,fade))
	for side: int in [-1,1]:
		var tail := tip - direction * 12 * scale_factor
		canvas.draw_colored_polygon(PackedVector2Array([tail,tail - direction * 5 * scale_factor + normal * side * 3 * scale_factor,tail - direction * 5 * scale_factor]),Color(owner,fade * 0.9))
	canvas.draw_line(tip - direction * 20 * scale_factor,tip - direction * 14 * scale_factor,Color(STEEL,fade * 0.35),maxf(scale_factor,1))

static func _draw_mechanical(canvas: Object, source: Vector2, target: Vector2, phase: float, scale_factor: float, owner: Color) -> void:
	var direction := (target - source).normalized()
	if direction.is_zero_approx(): direction = Vector2.RIGHT
	var normal := direction.orthogonal()
	var tip := source.lerp(target,minf(1.0,phase * 1.6))
	var fade := 1.0 - phase
	# A metal shell, copper collar and angular hot exhaust are not an arrow.
	canvas.draw_colored_polygon(PackedVector2Array([tip + direction * 6 * scale_factor,tip + normal * 3 * scale_factor,tip - direction * 8 * scale_factor + normal * 3 * scale_factor,tip - direction * 8 * scale_factor - normal * 3 * scale_factor,tip - normal * 3 * scale_factor]),Color(IRON,fade))
	canvas.draw_colored_polygon(PackedVector2Array([tip + direction * 6 * scale_factor,tip + normal * 2 * scale_factor,tip - normal * 2 * scale_factor]),Color(STEEL,fade))
	canvas.draw_line(tip - direction * 5 * scale_factor - normal * 3 * scale_factor,tip - direction * 5 * scale_factor + normal * 3 * scale_factor,Color(COPPER,fade),maxf(scale_factor * 2,1))
	for index: int in range(3):
		var tail := tip - direction * (10 + index * 4) * scale_factor
		canvas.draw_colored_polygon(PackedVector2Array([tail + normal * (2 - index * 0.4) * scale_factor,tail - direction * 6 * scale_factor,tail - normal * (2 - index * 0.4) * scale_factor]),Color(COPPER.lightened(index * 0.1),fade * (0.75 - index * 0.16)))
	# Smoke belongs at the firing source, never an invented target impact.
	for index: int in range(4):
		var point := source + direction * (9 + index * 3) * scale_factor + normal * (index % 2 * 4 - 2) * scale_factor - Vector2(0,phase * 12) * scale_factor
		canvas.draw_rect(Rect2(point,Vector2(3 + index,2 + index % 2) * scale_factor),Color(INK.lightened(index * 0.05),fade * 0.35))
	canvas.draw_colored_polygon(PackedVector2Array([source + normal * 3 * scale_factor,source + direction * 16 * scale_factor,source - normal * 3 * scale_factor]),Color(owner,fade * 0.45))

static func _draw_fire(canvas: Object, source: Vector2, target: Vector2, phase: float, scale_factor: float) -> void:
	var direction := (target - source).normalized()
	if direction.is_zero_approx(): direction = Vector2.RIGHT
	var normal := direction.orthogonal()
	var endpoint := source.lerp(target,0.7 + phase * 0.3)
	var fade := 1.0 - phase
	for index: int in range(4):
		var start := source.lerp(endpoint,float(index) / 4)
		var end := source.lerp(endpoint,float(index + 1) / 4)
		var width := (3 + sin((phase + index * 0.19) * PI) * 4) * scale_factor
		canvas.draw_colored_polygon(PackedVector2Array([start - normal * width,start + normal * width,end + normal * width * 0.45,end + direction * 3 * scale_factor,end - normal * width * 0.3]),Color("dd763f",fade * 0.72))
		canvas.draw_colored_polygon(PackedVector2Array([start,end + normal * width * 0.25,end - normal * width * 0.2]),Color("f1c275",fade * 0.86))
	for index: int in range(3):
		var point := source.lerp(endpoint,(index + 1.0) / 5) + normal * (index % 2 * 2 - 1) * 9 * scale_factor * phase
		canvas.draw_rect(Rect2(point,Vector2(2,2) * scale_factor),Color("e6a753",fade * 0.65))

static func _draw_magic(canvas: Object, source: Vector2, target: Vector2, phase: float, scale_factor: float, support: bool) -> void:
	var direction := (target - source).normalized()
	if direction.is_zero_approx(): direction = Vector2.RIGHT
	var normal := direction.orthogonal()
	var orb := source.lerp(target,minf(1.0,phase * 1.5))
	var fade := 1.0 - phase
	var hue := Color("91c693") if support else Color("b39de4")
	for index: int in range(4):
		var point := orb - direction * index * 9 * scale_factor + normal * sin(phase * TAU + index) * 3 * scale_factor
		var size := (5 - index * 0.8) * scale_factor
		canvas.draw_colored_polygon(PackedVector2Array([point + direction * size,point + normal * size * 0.65,point - direction * size,point - normal * size * 0.65]),Color(hue,fade * (0.76 - index * 0.14)))
	canvas.draw_colored_polygon(PackedVector2Array([orb + direction * 2 * scale_factor,orb + normal * 2 * scale_factor,orb - direction * 2 * scale_factor,orb - normal * 2 * scale_factor]),Color(STEEL,fade))
	for index: int in range(3):
		var point := source + Vector2.from_angle(index * TAU / 3 + phase) * (6 + phase * 7) * scale_factor
		canvas.draw_rect(Rect2(point,Vector2(2,2) * scale_factor),Color(hue,fade * 0.7))
