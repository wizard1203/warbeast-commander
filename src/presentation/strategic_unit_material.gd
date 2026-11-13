extends RefCounted
## Original clustered pixel equipment. Owner panels are fixed geometry, not
## selection glow. All coordinates are relative to the real foot projection.
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const INK := Color("18252a")
const METAL := Color("bcc9bd")
const COPPER := Color("bc9465")

static func draw_details(canvas: Object, origin: Vector2, pixel: float, unit: Dictionary, pose: Dictionary, mirror: bool) -> void:
	var owner := Palette.side_color(str(unit.get("side", "PLAYER")))
	var faction := str(unit.get("faction_id", "HUMAN"))
	var type := str(unit.get("unit_type", "hinge_guard"))
	var role := str(unit.get("role", "FRONTLINE"))
	var body := str(unit.get("body_kind", "HUMANOID"))
	var materials: Dictionary = {"UNDEAD":Color("b5b5a1"),"MACHINE":Color("957764"),"FOREST":Color("617350"),"HIGHLAND":Color("a4a395"),"UNDERGROUND":Color("8c839b")}
	var material: Color = materials.get(faction, Color("83979a"))
	if body == "VEHICLE":
		# Painted hull stripes remain readable even when the gun covers turret.
		_r(canvas,origin,pixel,Rect2(-10,-5,19,3),owner,mirror)
		_r(canvas,origin,pixel,Rect2(-5,-14,10,3),owner,mirror)
		_r(canvas,origin,pixel,Rect2(-4,-14,8,1),owner.lightened(0.25),mirror)
		_r(canvas,origin,pixel,Rect2(-10,-2,19,1),owner.darkened(0.45),mirror)
		_r(canvas,origin,pixel,Rect2(-12,-1,26,2),COPPER,mirror)
		for x: int in [-10,-5,0,5,10]:
			_r(canvas,origin,pixel,Rect2(x,6,3,1),METAL.darkened(0.35),mirror)
			_r(canvas,origin,pixel,Rect2(x,-1,1,1),METAL,mirror)
		for x: int in [-8,-5,-2]: _r(canvas,origin,pixel,Rect2(x,-9,2,2),INK,mirror)
		_r(canvas,origin,pixel,Rect2(5,-14,4,2),COPPER,mirror)
		_r(canvas,origin,pixel,Rect2(6,-18,2,4),INK,mirror)
		_r(canvas,origin,pixel,Rect2(6,-18,2,1),METAL,mirror)
		_l(canvas,origin,pixel,Vector2(5,-9),Vector2(16,-9),METAL,1,mirror)
		_draw_craft(canvas,origin,pixel,unit,pose,mirror,material)
		return
	if body == "DRAGON":
		var flap := float(pose.get("step",0)) * 2
		# Wing-root harness, distinct from warm leathery membranes.
		_r(canvas,origin,pixel,Rect2(-8,-11,7,4),owner,mirror)
		_r(canvas,origin,pixel,Rect2(1,-14,7,4),owner,mirror)
		_r(canvas,origin,pixel,Rect2(-7,-11,5,1),owner.lightened(0.22),mirror)
		_r(canvas,origin,pixel,Rect2(2,-14,5,1),owner.lightened(0.22),mirror)
		for side: int in [-1,1]:
			var root := Vector2(-4,-7) if side < 0 else Vector2(3,-10)
			var tip := Vector2(-18,-19-flap) if side < 0 else Vector2(12,-24+flap)
			var edge := Vector2(-15,-6) if side < 0 else Vector2(18,-8)
			_l(canvas,origin,pixel,root,tip,Color("d6ac79"),1,mirror)
			_l(canvas,origin,pixel,root,edge,Color("754b43"),1,mirror)
			_l(canvas,origin,pixel,tip,root.lerp(edge,0.65),Color("ce9868"),1,mirror)
		for x: int in [-11,-7,-3,1]:
			_r(canvas,origin,pixel,Rect2(x,-3,3,1),Color("cc9566"),mirror)
			_r(canvas,origin,pixel,Rect2(x+1,-6,2,1),Color("674638"),mirror)
		_r(canvas,origin,pixel,Rect2(10,-16,5,2),Color("e4b97f"),mirror)
		_r(canvas,origin,pixel,Rect2(12,-18,1,1),Color("eece73"),mirror)
		_l(canvas,origin,pixel,Vector2(6,-1),Vector2(9,3),Color("b99a79"),1,mirror)
		_draw_craft(canvas,origin,pixel,unit,pose,mirror,material)
		return
	if body in ["HORSE","CAVALRY","STAG","LIZARD"]:
		# Broad saddle blanket and rider cap retain owner color independently.
		_r(canvas,origin,pixel,Rect2(-8,-9,12,6),owner,mirror)
		_r(canvas,origin,pixel,Rect2(-7,-9,10,1),owner.lightened(0.22),mirror)
		_r(canvas,origin,pixel,Rect2(-8,-3,12,1),owner.darkened(0.4),mirror)
		_r(canvas,origin,pixel,Rect2(-3,-27,6,2),owner,mirror)
		_r(canvas,origin,pixel,Rect2(-3,-20,6,3),METAL,mirror)
		_r(canvas,origin,pixel,Rect2(-3,-17,5,4),owner,mirror)
		_r(canvas,origin,pixel,Rect2(-1,-14,2,3),COPPER,mirror)
		_l(canvas,origin,pixel,Vector2(2,-13),Vector2(12,-12),INK,1,mirror)
		_l(canvas,origin,pixel,Vector2(12,-12),Vector2(14,-16),COPPER,1,mirror)
		for x: int in [-8,-3,4,8]: _r(canvas,origin,pixel,Rect2(x,5,2,2),Color("bcb3a2"),mirror)
		for x: int in [-7,0,6]: _r(canvas,origin,pixel,Rect2(x,-10,3,1),METAL.darkened(0.15),mirror)
		_draw_craft(canvas,origin,pixel,unit,pose,mirror,material)
		return
	# Wide arm planes, same anatomy scale for workers and light infantry.
	_r(canvas,origin,pixel,Rect2(-5,-7,2,7),INK,mirror)
	_r(canvas,origin,pixel,Rect2(3,-7,2,6),INK,mirror)
	_r(canvas,origin,pixel,Rect2(-5,-6,2,3),material,mirror)
	_r(canvas,origin,pixel,Rect2(3,-6,2,3),material.lightened(0.18),mirror)
	_r(canvas,origin,pixel,Rect2(-5,-3,2,2),Color("d4b998") if faction == "HUMAN" else material,mirror)
	# Fixed shoulder panels and front tabard intentionally drawn last.
	_r(canvas,origin,pixel,Rect2(-5,-9,3,3),owner,mirror)
	_r(canvas,origin,pixel,Rect2(2,-9,3,3),owner,mirror)
	_r(canvas,origin,pixel,Rect2(-2,-6,4,4),owner,mirror)
	_r(canvas,origin,pixel,Rect2(-5,-9,3,1),owner.lightened(0.25),mirror)
	_r(canvas,origin,pixel,Rect2(-2,-2,4,1),owner.darkened(0.4),mirror)
	_r(canvas,origin,pixel,Rect2(-2,-2,4,1),Color("715238"),mirror)
	_r(canvas,origin,pixel,Rect2(-0.5,-2,1,1),COPPER,mirror)
	_r(canvas,origin,pixel,Rect2(-1,-12,2,1),Color("f0d5ab") if faction == "HUMAN" else material.lightened(0.2),mirror)
	var step := float(pose.get("step",0))
	_r(canvas,origin,pixel,Rect2(-2.5,1+step,1,3),material.darkened(0.25),mirror)
	_r(canvas,origin,pixel,Rect2(0.5,1-step,1,3),material.darkened(0.1),mirror)
	if type == "worker":
		_r(canvas,origin,pixel,Rect2(-3,-12,6,1),Color("e5c779"),mirror)
		_r(canvas,origin,pixel,Rect2(-7,-3,2,4),Color("826447"),mirror)
		_r(canvas,origin,pixel,Rect2(-7,-3,2,1),Color("ccb082"),mirror)
	elif role == "HEAVY" or body == "HEAVY_BONE":
		_r(canvas,origin,pixel,Rect2(-5,-11,10,2),material.darkened(0.3),mirror)
		for x: int in [-4,2]: _r(canvas,origin,pixel,Rect2(x,-10,2,1),METAL,mirror)
		_r(canvas,origin,pixel,Rect2(-3,-16,6,2),material,mirror)
		_r(canvas,origin,pixel,Rect2(-2,-16,4,1),METAL,mirror)
		_r(canvas,origin,pixel,Rect2(-5,-4,2,1),COPPER,mirror)
	elif role == "SUPPORT":
		_r(canvas,origin,pixel,Rect2(-6,-4,3,5),Color("795740"),mirror)
		_r(canvas,origin,pixel,Rect2(-5,-4,2,3),Color("d5c594"),mirror)
		_r(canvas,origin,pixel,Rect2(-1,-17,3,1),material.lightened(0.2),mirror)
	elif role == "RANGED":
		_r(canvas,origin,pixel,Rect2(-6,-12,2,8),Color("614736"),mirror)
		for x: int in [-7,-5]: _l(canvas,origin,pixel,Vector2(x,-9),Vector2(x+1,-15),METAL,1,mirror)
	if faction == "MACHINE":
		_r(canvas,origin,pixel,Rect2(-2,-15,4,1),COPPER,mirror)
		for x: int in [-4,3]: _r(canvas,origin,pixel,Rect2(x,-8,1,1),METAL,mirror)
	elif faction == "UNDEAD":
		for x: int in [-3,2]: _r(canvas,origin,pixel,Rect2(x,-5,1,2),Color("dad2b6"),mirror)
	elif faction == "FOREST":
		_l(canvas,origin,pixel,Vector2(-4,-12),Vector2(-6,-16),Color("8daf6c"),1,mirror)
	elif faction == "HIGHLAND":
		_r(canvas,origin,pixel,Rect2(-3,-15,6,1),Color("d4cbb1"),mirror)
	elif faction == "UNDERGROUND":
		for x: int in [-2,2]: _l(canvas,origin,pixel,Vector2(x,-14),Vector2(x*2,-17),Color("b3a5c1"),1,mirror)
	_draw_craft(canvas,origin,pixel,unit,pose,mirror,material)

static func _draw_craft(canvas: Object, origin: Vector2, pixel: float, unit: Dictionary, pose: Dictionary, mirror: bool, material: Color) -> void:
	# Concentrated one-pixel planes/rivets stay inside the existing visual body
	# envelope. No new glow recolors the owner panels, and no independent timer
	# suggests an unobserved attack or work cycle.
	var body := str(unit.get("body_kind","HUMANOID"))
	var role := str(unit.get("role","FRONTLINE"))
	var faction := str(unit.get("faction_id","HUMAN"))
	if body == "VEHICLE":
		for x: int in [-8,-4,0]:
			_r(canvas,origin,pixel,Rect2(x,-8,2,1),METAL.darkened(0.12),mirror)
			_r(canvas,origin,pixel,Rect2(x,-7,1,2),INK,mirror)
		_r(canvas,origin,pixel,Rect2(9,-7,3,1),COPPER.lightened(0.2),mirror)
		_r(canvas,origin,pixel,Rect2(-11,3,2,1),COPPER,mirror)
		return
	if body == "DRAGON":
		for index: int in range(4):
			_r(canvas,origin,pixel,Rect2(-5+index*3,-6-index%2,2,1),Color("dbad72"),mirror)
			_r(canvas,origin,pixel,Rect2(-4+index*3,-4,1,1),Color("6f4c3d"),mirror)
		_r(canvas,origin,pixel,Rect2(10,-15,4,1),Color("edca91"),mirror)
		return
	if body in ["HORSE","CAVALRY","STAG","LIZARD"]:
		_l(canvas,origin,pixel,Vector2(7,-10),Vector2(13,-12),Color("51473b"),1,mirror)
		_r(canvas,origin,pixel,Rect2(13,-13,2,1),COPPER,mirror)
		_r(canvas,origin,pixel,Rect2(-3,-25,2,1),METAL,mirror)
		_r(canvas,origin,pixel,Rect2(0,-23,2,2),material.lightened(0.22),mirror)
		for x: int in [-7,-1,5]: _r(canvas,origin,pixel,Rect2(x,-1,2,1),material.lightened(0.1),mirror)
		return
	var edge := material.lightened(0.3)
	var shadow := material.darkened(0.25)
	_r(canvas,origin,pixel,Rect2(-3,-14,2,1),edge,mirror)
	_r(canvas,origin,pixel,Rect2(1,-13,1,2),shadow,mirror)
	var step := float(pose.get("step",0))
	_r(canvas,origin,pixel,Rect2(-2,4+step,2,1),Color("9f8c6b"),mirror)
	_r(canvas,origin,pixel,Rect2(1,4-step,2,1),Color("ba9b74"),mirror)
	_r(canvas,origin,pixel,Rect2(-3,-1,1,1),COPPER.darkened(0.1),mirror)
	if unit.get("unit_type") == "hero":
		# Hero-specific weapons already carry the main equipment silhouette.
		# Six compact craft accents retain the independent legacy hero budget;
		# do not also add the ordinary troop role's three generic gear marks.
		_r(canvas,origin,pixel,Rect2(-4,-3,1,2),METAL,mirror)
		return
	if unit.get("unit_type") == "worker":
		_r(canvas,origin,pixel,Rect2(-7,-2,1,3),Color("bda277"),mirror)
		_r(canvas,origin,pixel,Rect2(4,-5,1,2),Color("d5b68b"),mirror)
		_r(canvas,origin,pixel,Rect2(-2,-11,2,1),Color("806b46"),mirror)
	elif role == "SUPPORT":
		_r(canvas,origin,pixel,Rect2(-5,-2,1,2),Color("d5c89e"),mirror)
		_r(canvas,origin,pixel,Rect2(-5,-3,2,1),Color("698c7b"),mirror)
		_r(canvas,origin,pixel,Rect2(0,-16,1,1),edge,mirror)
	elif role == "RANGED":
		_r(canvas,origin,pixel,Rect2(-6,-8,1,5),Color("b49b6d"),mirror)
		_r(canvas,origin,pixel,Rect2(-6,-11,1,1),METAL,mirror)
		_r(canvas,origin,pixel,Rect2(3,-4,1,2),edge,mirror)
	else:
		_r(canvas,origin,pixel,Rect2(-4,-3,1,2),METAL,mirror)
		_r(canvas,origin,pixel,Rect2(4,-5,1,2),edge,mirror)
		_r(canvas,origin,pixel,Rect2(-3,-11,1,1),METAL,mirror)
	if faction == "UNDEAD":
		_r(canvas,origin,pixel,Rect2(-1,-4,2,1),Color("e0d4b4"),mirror)
	elif faction == "MACHINE":
		_r(canvas,origin,pixel,Rect2(0,-12,2,1),Color("b9c6b9"),mirror)
	elif faction == "UNDERGROUND":
		_r(canvas,origin,pixel,Rect2(-2,-10,4,1),Color("8ca5a3"),mirror)

static func draw_ranged_weapon(canvas: Object, origin: Vector2, pixel: float, faction: String, recoil: float, mirror: bool) -> void:
	if faction == "MACHINE":
		_r(canvas,origin,pixel,Rect2(2+recoil,-2,8,3),INK,mirror)
		_r(canvas,origin,pixel,Rect2(4+recoil,-3,4,2),COPPER,mirror)
		_r(canvas,origin,pixel,Rect2(9+recoil,-2,4,1),METAL,mirror)
		_r(canvas,origin,pixel,Rect2(5+recoil,1,2,2),INK,mirror)
	elif faction in ["FOREST","UNDEAD"]:
		var wood := Color("a5bd72") if faction == "FOREST" else Color("d1c9ab")
		_l(canvas,origin,pixel,Vector2(6+recoil,-10),Vector2(9+recoil,-4),wood,2,mirror)
		_l(canvas,origin,pixel,Vector2(9+recoil,-4),Vector2(6+recoil,3),wood,2,mirror)
		_l(canvas,origin,pixel,Vector2(6+recoil,-10),Vector2(6+recoil,3),Color("c3b79a"),1,mirror)
		_l(canvas,origin,pixel,Vector2(4+recoil,-4),Vector2(12+recoil,-4),METAL,1,mirror)
	elif faction == "HIGHLAND":
		_l(canvas,origin,pixel,Vector2(3,-2),Vector2(8+recoil,-8),Color("a89373"),1,mirror)
		_l(canvas,origin,pixel,Vector2(8+recoil,-8),Vector2(12,-4),Color("a89373"),1,mirror)
		_r(canvas,origin,pixel,Rect2(7+recoil,-10,3,3),METAL,mirror)
	elif faction == "UNDERGROUND":
		_r(canvas,origin,pixel,Rect2(2+recoil,-3,8,3),Color("7c6b8b"),mirror)
		_r(canvas,origin,pixel,Rect2(9+recoil,-4,3,4),Color("bca9c6"),mirror)
		_r(canvas,origin,pixel,Rect2(10+recoil,-3,2,2),Color("74b5ac"),mirror)
	else:
		_r(canvas,origin,pixel,Rect2(2+recoil,-1,9,2),Color("675140"),mirror)
		_r(canvas,origin,pixel,Rect2(6+recoil,-5,2,9),INK,mirror)
		_r(canvas,origin,pixel,Rect2(6+recoil,-4,1,7),COPPER,mirror)
		_l(canvas,origin,pixel,Vector2(4+recoil,-4),Vector2(4+recoil,3),Color("c3b79a"),1,mirror)
		_r(canvas,origin,pixel,Rect2(3+recoil,-1,9,1),METAL,mirror)

static func _r(canvas: Object, origin: Vector2, pixel: float, rect: Rect2, color: Color, mirror: bool) -> void:
	var point := rect.position
	if mirror: point.x = -point.x - rect.size.x
	canvas.draw_rect(Rect2((origin+point*pixel).round(),rect.size*pixel),color)

static func _l(canvas: Object, origin: Vector2, pixel: float, a: Vector2, b: Vector2, color: Color, width: float, mirror: bool) -> void:
	canvas.draw_line((origin+Vector2(-a.x if mirror else a.x,a.y)*pixel).round(),(origin+Vector2(-b.x if mirror else b.x,b.y)*pixel).round(),color,maxf(pixel*width,1))
