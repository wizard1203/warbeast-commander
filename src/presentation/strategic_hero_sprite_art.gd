extends RefCounted
## Original M24 hero masters. Coordinates are integer logical pixels relative
## to the real foot origin. The caller owns caching, scaling and mirroring.
## Only supplied action observations move equipment; there is no local clock.
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const INK := Color("19232c")
const STEEL := Color("8d9da6")
const STEEL_LIGHT := Color("d5ded7")
const STEEL_DARK := Color("465762")
const GOLD := Color("d5b369")
const GOLD_LIGHT := Color("f0d9a1")
const WOOD := Color("99704c")
const WOOD_DARK := Color("543f36")
const BONE := Color("c7c8b3")
const BONE_LIGHT := Color("eeead0")
const BONE_DARK := Color("747b70")
const COPPER := Color("af825d")
const COPPER_LIGHT := Color("ddae7d")
const LEAF := Color("708e59")
const LEAF_LIGHT := Color("abc47b")
const FUR := Color("b3a48a")
const FUR_LIGHT := Color("e0d2b4")
const CHITIN := Color("74677e")
const CHITIN_LIGHT := Color("ada2b7")
const TEAL := Color("75bfbb")
const EMBER := Color("c57852")
const IDS := ["COMMANDER","BULWARK","ARCANIST","RANGER","DUELIST",
	"ASH_MARSHAL","MOURN_ORACLE","CINDER_STALKER",
	"COIL_WARDEN","VOLT_WEAVER","GEAR_HUNTER",
	"VINE_WARDEN","LEAF_SEER","WIND_COURIER",
	"RIDGE_JARL","RUNE_ORACLE","EMBER_CAVALIER",
	"TUNNEL_SENTINEL","ECHO_BINDER","SPORE_STALKER"]


static func supported_ids() -> PackedStringArray:
	return PackedStringArray(IDS)


static func paint(canvas: Object, unit: Dictionary, pose: Dictionary) -> void:
	var id := str(unit.get("hero_archetype", "COMMANDER"))
	if id not in IDS: id = "COMMANDER"
	var colors := _colors(unit, id)
	var action := str(pose.get("action", "IDLE"))
	if action == "FALLEN":
		_fallen(canvas, colors, id)
		return
	var moving := bool(pose.get("moving", action == "WALK"))
	var step := clampi(roundi(float(pose.get("step", 0.0)) * 2.0), -2, 2) if moving else 0
	var phase := clampf(float(pose.get("phase", 0.0)), 0.0, 1.0)
	var strike := roundi(sin(phase * PI) * 5.0) if action == "ATTACK" else 0
	var casting := action.begins_with("SKILL_") or action == "HEAL"
	var lift := roundi(sin(phase * PI) * 4.0) if casting else 0
	match id:
		"COMMANDER": _commander(canvas, colors, step, strike, lift)
		"BULWARK": _bulwark(canvas, colors, step, strike)
		"ARCANIST": _arcanist(canvas, colors, step, strike, lift)
		"RANGER": _ranger(canvas, colors, step, strike)
		"DUELIST": _duelist(canvas, colors, step, strike)
		"ASH_MARSHAL": _ash_marshal(canvas, colors, step, strike)
		"MOURN_ORACLE": _mourn_oracle(canvas, colors, step, strike, lift)
		"CINDER_STALKER": _cinder_stalker(canvas, colors, step, strike)
		"COIL_WARDEN": _coil_warden(canvas, colors, step, strike)
		"VOLT_WEAVER": _volt_weaver(canvas, colors, step, strike, lift)
		"GEAR_HUNTER": _gear_hunter(canvas, colors, step, strike)
		"VINE_WARDEN": _vine_warden(canvas, colors, step, strike)
		"LEAF_SEER": _leaf_seer(canvas, colors, step, strike, lift)
		"WIND_COURIER": _wind_courier(canvas, colors, step, strike)
		"RIDGE_JARL": _ridge_jarl(canvas, colors, step, strike)
		"RUNE_ORACLE": _rune_oracle(canvas, colors, step, strike, lift)
		"EMBER_CAVALIER": _ember_cavalier(canvas, colors, step, strike)
		"TUNNEL_SENTINEL": _tunnel_sentinel(canvas, colors, step, strike)
		"ECHO_BINDER": _echo_binder(canvas, colors, step, strike, lift)
		"SPORE_STALKER": _spore_stalker(canvas, colors, step, strike)
	# Painted affiliation panels are opaque material, never selection glows.
	# They remain visible independently of the hero's faction or weapon metal.
	var width: int = {"BULWARK":12,"ASH_MARSHAL":12,"COIL_WARDEN":13,
		"VINE_WARDEN":12,"RIDGE_JARL":12,"TUNNEL_SENTINEL":14,
		"ECHO_BINDER":10,"SPORE_STALKER":10}.get(id, 9)
	var top: int = {"TUNNEL_SENTINEL":-25,"ECHO_BINDER":-31,"SPORE_STALKER":-29}.get(id, -31)
	_owner_marks(canvas, colors, width, top)


static func _colors(unit: Dictionary, id: String) -> Dictionary:
	var faction := str(unit.get("faction_id", ""))
	if faction == "":
		faction = "UNDEAD" if id in ["ASH_MARSHAL","MOURN_ORACLE","CINDER_STALKER"] else "MACHINE" if id in ["COIL_WARDEN","VOLT_WEAVER","GEAR_HUNTER"] else "FOREST" if id in ["VINE_WARDEN","LEAF_SEER","WIND_COURIER"] else "HIGHLAND" if id in ["RIDGE_JARL","RUNE_ORACLE","EMBER_CAVALIER"] else "UNDERGROUND" if id in ["TUNNEL_SENTINEL","ECHO_BINDER","SPORE_STALKER"] else "HUMAN"
	var owner: Color = Palette.side_color(str(unit.get("side", "PLAYER")))
	var skin: Color = {"UNDEAD":BONE,"MACHINE":COPPER,"FOREST":Color("b3c595"),"HIGHLAND":Color("cfb898"),"UNDERGROUND":CHITIN_LIGHT}.get(faction, Color("ddb48c"))
	var armor: Color = {"UNDEAD":BONE_DARK,"MACHINE":COPPER,"FOREST":Color("6c7c5b"),"HIGHLAND":Color("969a96"),"UNDERGROUND":CHITIN}.get(faction, STEEL)
	return {"owner":owner,"owner_dark":owner.darkened(0.48),"owner_light":owner.lightened(0.28),
		"skin":skin,"skin_light":skin.lightened(0.22),"skin_dark":skin.darkened(0.3),
		"armor":armor,"armor_light":armor.lightened(0.28),"armor_dark":armor.darkened(0.32)}


static func _owner_marks(c: Object, p: Dictionary, width: int, top: int) -> void:
	_r(c, -width, top, 5, 5, p.owner_dark)
	_r(c, -width, top, 5, 3, p.owner)
	_r(c, -width, top, 4, 1, p.owner_light)
	_r(c, width - 5, top, 5, 5, p.owner_dark)
	_r(c, width - 5, top, 5, 3, p.owner)
	_r(c, width - 5, top, 4, 1, p.owner_light)
	_r(c, -5, top + 8, 10, 12, p.owner_dark)
	_r(c, -4, top + 8, 8, 10, p.owner)
	_r(c, -4, top + 8, 8, 1, p.owner_light)
	_r(c, -1, top + 11, 2, 3, GOLD_LIGHT)


static func _biped(c: Object, p: Dictionary, step: int, width: int = 9, robe: bool = false) -> void:
	# Grounded, articulated anatomy shared as construction, not final silhouette.
	_r(c, -7, -9 + step, 6, 14, INK)
	_r(c, 2, -9 - step, 6, 14, INK)
	_r(c, -6, -8 + step, 4, 10, p.armor_dark)
	_r(c, 3, -8 - step, 4, 10, p.armor)
	_r(c, -8, 3 + step, 8, 3, WOOD_DARK)
	_r(c, 2, 3 - step, 8, 3, WOOD_DARK)
	_r(c, -7, 3 + step, 6, 1, p.armor_light)
	_r(c, 3, 3 - step, 6, 1, STEEL_LIGHT)
	if robe:
		_p(c, [Vector2(-width,-34),Vector2(width,-34),Vector2(width+4,2),Vector2(-width-4,2)], INK)
		_p(c, [Vector2(-width+1,-32),Vector2(width-1,-32),Vector2(width+2,0),Vector2(-width-2,0)], p.armor_dark)
		_r(c, -width+2, -25, 3, 23, p.armor)
		_r(c, width-3, -23, 2, 22, p.armor_light)
	else:
		_r(c, -width, -34, width * 2, 25, INK)
		_r(c, -width+1, -32, width * 2 - 2, 21, p.armor_dark)
		_r(c, -width+2, -31, width - 2, 15, p.armor)
		_r(c, 0, -31, width - 2, 14, p.armor_light)
	_r(c, -width-3, -31, 5, 18, INK)
	_r(c, width-2, -31, 5, 18, INK)
	_r(c, -width-2, -29, 3, 10, p.armor)
	_r(c, width-1, -29, 3, 10, p.armor_light)
	_r(c, -width-2, -18, 3, 4, p.skin_dark)
	_r(c, width-1, -18, 3, 4, p.skin)
	_r(c, -width, -12, width * 2, 3, WOOD_DARK)
	_r(c, -2, -12, 4, 3, GOLD)
	_r(c, -5, -44, 11, 12, INK)
	_r(c, -4, -43, 9, 10, p.skin_dark)
	_r(c, -3, -43, 7, 7, p.skin)
	_r(c, -3, -43, 6, 2, p.skin_light)
	_r(c, -2, -39, 2, 1, INK)
	_r(c, 3, -39, 2, 1, INK)
	_r(c, 0, -37, 2, 2, p.skin_dark)
	_r(c, -2, -34, 5, 1, p.skin_light)


static func _cape(c: Object, p: Dictionary, width: int, height: int = 34) -> void:
	_p(c, [Vector2(-width+3,-36),Vector2(width-3,-36),Vector2(width,-36+height),Vector2(2,-38+height),Vector2(-width,-35+height)], INK)
	_p(c, [Vector2(-width+4,-34),Vector2(width-4,-34),Vector2(width-2,-38+height),Vector2(-width+2,-37+height)], p.owner_dark)
	_l(c, -width+4, -30, -width+3, -39+height, p.owner, 2)
	_l(c, width-5, -29, width-3, -39+height, p.owner, 1)


static func _sword(c: Object, x: int, y: int, strike: int, long_blade: bool = false) -> void:
	var top := y - (29 if long_blade else 22)
	_p(c, [Vector2(x-2,y),Vector2(x+1,top-strike),Vector2(x+4,top+4-strike),Vector2(x+3,y)], INK)
	_p(c, [Vector2(x-1,y-1),Vector2(x+1,top+2-strike),Vector2(x+2,top+5-strike),Vector2(x+2,y-1)], STEEL)
	_l(c, x+1, top+4-strike, x, y-2, STEEL_LIGHT, 1)
	_r(c, x-4, y, 10, 2, GOLD)
	_r(c, x-1, y+2, 3, 6, WOOD_DARK)
	_r(c, x-2, y+7, 5, 2, GOLD_LIGHT)


static func _bow(c: Object, x: int, top: int, bottom: int, color: Color, pull: int, broad: bool = false) -> void:
	var mid := (top+bottom)/2
	_l(c, x-3, top, x+4, top+5, INK, 4 if broad else 3)
	_l(c, x+4, top+5, x+7, mid, INK, 4 if broad else 3)
	_l(c, x+7, mid, x+4, bottom-5, INK, 4 if broad else 3)
	_l(c, x+4, bottom-5, x-3, bottom, INK, 4 if broad else 3)
	_l(c, x-3, top, x+4, top+5, color, 2)
	_l(c, x+4, top+5, x+6, mid, color.lightened(0.2), 2)
	_l(c, x+6, mid, x+4, bottom-5, color, 2)
	_l(c, x+4, bottom-5, x-3, bottom, color.darkened(0.2), 2)
	_l(c, x-3, top, x-3-pull, mid, BONE_LIGHT, 1)
	_l(c, x-3-pull, mid, x-3, bottom, BONE_LIGHT, 1)
	_l(c, x-5-pull, mid, x+10-pull, mid, WOOD, 1)
	_p(c, [Vector2(x+11-pull,mid),Vector2(x+7-pull,mid-2),Vector2(x+7-pull,mid+2)], STEEL_LIGHT)


static func _quiver(c: Object, x: int, y: int, bone: bool = false) -> void:
	_r(c, x, y, 7, 23, INK)
	_r(c, x+1, y+1, 5, 21, BONE_DARK if bone else WOOD_DARK)
	_r(c, x+1, y+3, 2, 17, BONE if bone else WOOD)
	_r(c, x, y+3, 7, 2, GOLD)
	for index: int in range(3):
		var ax := x+1+index*2
		_l(c, ax, y+7, ax-2, y-7-index%2*2, BONE if bone else WOOD, 1)
		_r(c, ax-3, y-8-index%2*2, 3, 3, BONE_LIGHT)


static func _commander(c: Object, p: Dictionary, step: int, strike: int, lift: int) -> void:
	# A raised map-standard and open crown distinguish the balanced commander.
	_cape(c, p, 15, 39)
	_r(c, -24, -60, 2, 59, WOOD_DARK)
	_r(c, -24, -60, 1, 55, GOLD)
	_p(c, [Vector2(-22,-57),Vector2(-10,-54),Vector2(-11,-40),Vector2(-22,-43)], INK)
	_p(c, [Vector2(-21,-55),Vector2(-12,-53),Vector2(-13,-42),Vector2(-21,-44)], p.owner)
	_l(c, -20, -50, -14, -48, GOLD_LIGHT, 2)
	_p(c, [Vector2(-24,-64),Vector2(-27,-59),Vector2(-21,-59)], GOLD_LIGHT)
	_biped(c, p, step, 10)
	_r(c, -6, -46, 13, 5, INK)
	_r(c, -5, -45, 11, 3, GOLD)
	for x: int in [-5,0,5]:
		_r(c, x, -50 if x == 0 else -48, 2, 5, GOLD_LIGHT)
	_r(c, -6, -35, 13, 3, GOLD)
	_r(c, -11, -34, 5, 4, GOLD_LIGHT)
	_r(c, 7, -34, 5, 4, GOLD)
	for x: int in [-6,5]: _r(c, x, -23, 2, 9, GOLD)
	_r(c, -17, -16-lift, 7, 11, INK)
	_r(c, -16, -15-lift, 5, 9, BONE_LIGHT)
	_l(c, -15, -12-lift, -12, -12-lift, WOOD, 1)
	_l(c, -15, -9-lift, -12, -9-lift, WOOD, 1)
	_sword(c, 18, -17, strike, true)
	_r(c, -6, -6, 4, 3, GOLD)
	_r(c, 3, -6, 4, 3, GOLD_LIGHT)


static func _bulwark(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_cape(c, p, 17, 33)
	_biped(c, p, step, 12)
	_r(c, -8, -48, 16, 10, INK)
	_r(c, -7, -47, 14, 7, STEEL)
	_r(c, -6, -47, 12, 2, STEEL_LIGHT)
	_r(c, -5, -42, 12, 2, STEEL_DARK)
	_r(c, -3, -42, 7, 1, GOLD)
	_r(c, -14, -35, 28, 8, INK)
	_r(c, -13, -34, 26, 5, STEEL_LIGHT)
	_r(c, -12, -33, 24, 2, STEEL)
	_r(c, -10, -22, 20, 9, STEEL_DARK)
	for y: int in [-22,-18,-14]: _r(c, -9, y, 18, 1, STEEL)
	_p(c, [Vector2(-25,-36),Vector2(-9,-36),Vector2(-7,-14),Vector2(-16,4),Vector2(-25,-10)], INK)
	_p(c, [Vector2(-23,-34),Vector2(-11,-34),Vector2(-9,-14),Vector2(-16,1),Vector2(-23,-11)], GOLD)
	_p(c, [Vector2(-21,-31),Vector2(-13,-31),Vector2(-12,-14),Vector2(-16,-3),Vector2(-21,-12)], p.owner_dark)
	_r(c, -20, -28, 7, 14, p.owner)
	_r(c, -20, -28, 6, 2, p.owner_light)
	_r(c, -18, -25, 3, 11, GOLD_LIGHT)
	_r(c, -21, -21, 9, 3, GOLD_LIGHT)
	_sword(c, 18, -15, strike)
	for x: int in [-7,4]:
		_r(c, x, -7, 5, 7, STEEL)
		_r(c, x, -7, 5, 2, STEEL_LIGHT)


static func _arcanist(c: Object, p: Dictionary, step: int, strike: int, lift: int) -> void:
	var violet := Color("7d6c9d")
	var bright := Color("c8b7e3")
	_cape(c, p, 14, 38)
	_biped(c, p, step, 8, true)
	_p(c, [Vector2(-10,-33),Vector2(8,-33),Vector2(14,2),Vector2(-13,2)], violet)
	_r(c, -8, -24, 3, 24, violet.lightened(0.15))
	_r(c, 6, -22, 3, 23, violet.darkened(0.25))
	_l(c, -11, 0, 11, 0, GOLD, 2)
	_r(c, -7, -45, 15, 5, INK)
	_p(c, [Vector2(-10,-44),Vector2(-5,-57),Vector2(-1,-52),Vector2(4,-61),Vector2(9,-43)], INK)
	_p(c, [Vector2(-8,-44),Vector2(-4,-54),Vector2(-1,-49),Vector2(4,-57),Vector2(7,-44)], violet)
	_l(c, -4, -52, -1, -46, bright, 2)
	_l(c, 4, -54, 5, -46, bright, 1)
	_r(c, -8, -44, 17, 2, GOLD)
	_r(c, -14, -26-lift, 8, 12, INK)
	_r(c, -13, -25-lift, 6, 10, BONE_LIGHT)
	_r(c, -13, -25-lift, 1, 10, GOLD)
	_l(c, -11, -23-lift, -8, -23-lift, violet, 1)
	_l(c, -11, -20-lift, -8, -20-lift, violet, 1)
	_r(c, 19, -51-lift-strike, 3, 55, INK)
	_r(c, 20, -50-lift-strike, 1, 53, GOLD)
	_p(c, [Vector2(20,-60-lift),Vector2(26,-54-lift),Vector2(20,-47-lift),Vector2(14,-54-lift)], INK)
	_p(c, [Vector2(20,-59-lift),Vector2(24,-54-lift),Vector2(20,-49-lift),Vector2(16,-54-lift)], violet)
	_r(c, 19, -57-lift, 3, 5, bright)
	_r(c, 21, -53-lift, 2, 2, STEEL_LIGHT)
	_r(c, 16, -49-lift, 9, 2, GOLD)
	for y: int in [-5,-1]: _r(c, -3, y, 6, 1, bright)


static func _ranger(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_quiver(c, -19, -39)
	_cape(c, p, 13, 34)
	_biped(c, p, step, 8)
	_p(c, [Vector2(-8,-42),Vector2(-3,-51),Vector2(7,-47),Vector2(10,-37),Vector2(5,-34),Vector2(3,-42)], INK)
	_p(c, [Vector2(-6,-42),Vector2(-2,-48),Vector2(5,-45),Vector2(7,-39),Vector2(4,-38),Vector2(2,-43)], Color("536e50"))
	_p(c, [Vector2(-3,-48),Vector2(-8,-58),Vector2(-1,-53),Vector2(1,-46)], LEAF_LIGHT)
	_l(c, -5, -54, -1, -48, BONE_LIGHT, 1)
	_r(c, -8, -34, 16, 4, Color("628058"))
	_r(c, -6, -28, 12, 16, WOOD_DARK)
	_l(c, -6, -30, 6, -14, GOLD, 2)
	_r(c, -5, -10, 3, 9, Color("6f855c"))
	_r(c, 4, -10, 3, 9, Color("91a479"))
	_r(c, -13, -20, 4, 7, WOOD)
	_r(c, -13, -20, 4, 1, BONE_LIGHT)
	_bow(c, 14, -43, 2, WOOD, strike)
	_r(c, 5, -28, 8, 3, p.skin)
	_r(c, 10, -27, 3, 2, p.skin_light)
	for y: int in [-18,-14]: _r(c, 6, y, 2, 1, GOLD)


static func _duelist(c: Object, p: Dictionary, step: int, strike: int) -> void:
	var scarf := Color("b16a5c")
	_p(c, [Vector2(-5,-34),Vector2(-22,-35),Vector2(-26,-26),Vector2(-18,-29),Vector2(-9,-27)], INK)
	_p(c, [Vector2(-5,-33),Vector2(-21,-33),Vector2(-23,-28),Vector2(-17,-30),Vector2(-9,-29)], scarf)
	_biped(c, p, step, 7)
	_r(c, -5, -46, 12, 6, Color("4d403d"))
	_r(c, -7, -44, 15, 3, scarf)
	_r(c, 5, -43, 5, 2, scarf.lightened(0.2))
	_p(c, [Vector2(-5,-45),Vector2(-14,-51),Vector2(-10,-42),Vector2(-7,-35)], INK)
	_l(c, -12, -48, -8, -38, Color("6d5548"), 2)
	_r(c, -8, -35, 16, 4, scarf)
	_r(c, -5, -29, 10, 17, p.owner_dark)
	_r(c, -4, -12, 3, 7, scarf)
	_r(c, 2, -12, 3, 9, scarf.darkened(0.2))
	_sword(c, 17, -18, strike)
	_p(c, [Vector2(-12,-14),Vector2(-25,-34-strike),Vector2(-23,-36-strike),Vector2(-8,-16)], INK)
	_p(c, [Vector2(-12,-16),Vector2(-24,-34-strike),Vector2(-22,-32-strike),Vector2(-10,-16)], STEEL_LIGHT)
	_l(c, -15, -17, -8, -23, GOLD, 2)
	_l(c, -12, -17, -7, -11, WOOD_DARK, 3)
	_r(c, -6, -5, 4, 5, STEEL_DARK)
	_r(c, 3, -4, 4, 5, STEEL)
	_r(c, 6, -25, 3, 6, GOLD)


static func _ash_marshal(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_cape(c, p, 18, 37)
	_biped(c, p, step, 12)
	_r(c, -8, -47, 17, 8, INK)
	_r(c, -7, -46, 15, 5, BONE_DARK)
	for x: int in [-7,-1,6]:
		_p(c, [Vector2(x,-45),Vector2(x+1,-56),Vector2(x+4,-45)], BONE)
		_r(c, x+1, -50, 1, 4, BONE_LIGHT)
	_r(c, -6, -41, 5, 2, INK)
	_r(c, 2, -41, 5, 2, INK)
	_r(c, -4, -40, 2, 1, EMBER)
	_r(c, 3, -40, 2, 1, EMBER)
	for y: int in [-29,-24,-19]:
		_r(c, -10, y, 20, 3, BONE)
		_r(c, -9, y, 18, 1, BONE_LIGHT)
	_r(c, -2, -31, 4, 19, BONE_DARK)
	_p(c, [Vector2(-25,-37),Vector2(-21,-43),Vector2(-11,-43),Vector2(-8,-36),Vector2(-8,-2),Vector2(-25,-2)], INK)
	_p(c, [Vector2(-23,-36),Vector2(-20,-41),Vector2(-12,-41),Vector2(-10,-35),Vector2(-10,-4),Vector2(-23,-4)], BONE_DARK)
	_r(c, -21, -33, 9, 24, BONE)
	_r(c, -21, -33, 3, 24, BONE_LIGHT)
	_r(c, -19, -28, 6, 12, p.owner_dark)
	_r(c, -19, -27, 5, 9, p.owner)
	_r(c, -18, -24, 4, 1, EMBER)
	_r(c, 16, -32-strike, 3, 30, WOOD_DARK)
	_p(c, [Vector2(15,-47-strike),Vector2(25,-46-strike),Vector2(25,-26-strike),Vector2(17,-22-strike)], INK)
	_p(c, [Vector2(17,-45-strike),Vector2(23,-44-strike),Vector2(23,-28-strike),Vector2(18,-25-strike)], STEEL_DARK)
	_r(c, 22, -42-strike, 2, 12, STEEL_LIGHT)
	for x: int in [-7,4]: _r(c, x, -6, 4, 7, BONE)


static func _mourn_oracle(c: Object, p: Dictionary, step: int, strike: int, lift: int) -> void:
	var veil := Color("65606d")
	_p(c, [Vector2(-11,-46),Vector2(0,-56),Vector2(12,-45),Vector2(16,3),Vector2(-15,3)], INK)
	_p(c, [Vector2(-9,-44),Vector2(0,-53),Vector2(10,-43),Vector2(13,1),Vector2(-12,1)], veil)
	_biped(c, p, step, 8, true)
	_p(c, [Vector2(-9,-43),Vector2(-5,-50),Vector2(4,-51),Vector2(10,-42),Vector2(7,-35),Vector2(3,-42),Vector2(-4,-42),Vector2(-7,-35)], veil)
	_r(c, -4, -42, 8, 7, BONE)
	_r(c, -3, -41, 2, 3, INK)
	_r(c, 2, -41, 2, 3, INK)
	for x: int in [-3,0,3]: _r(c, x, -35, 1, 3, BONE_LIGHT)
	_r(c, -9, -28, 3, 27, veil.lightened(0.2))
	_r(c, 6, -27, 4, 28, veil.darkened(0.2))
	for x: int in [-10,-5,4,9]: _r(c, x, -2, 2, 5, BONE_DARK)
	_l(c, -14, -26-lift, -20, -22-lift, BONE, 2)
	_l(c, -20, -22-lift, -20, -16-lift, STEEL, 1)
	_r(c, -24, -17-lift, 8, 13, INK)
	_r(c, -23, -16-lift, 6, 11, COPPER)
	_r(c, -22, -14-lift, 4, 7, Color("a6b88a"))
	_r(c, -21, -13-lift, 2, 5, BONE_LIGHT)
	_r(c, -24, -5-lift, 8, 2, BONE_DARK)
	_r(c, 18, -55-lift-strike, 3, 57, WOOD_DARK)
	_r(c, 18, -54-lift-strike, 1, 55, BONE)
	_p(c, [Vector2(18,-60-lift),Vector2(25,-57-lift),Vector2(26,-50-lift),Vector2(21,-46-lift),Vector2(21,-50-lift),Vector2(23,-53-lift),Vector2(18,-56-lift)], BONE)
	_r(c, 19, -52-lift, 3, 5, TEAL)
	_r(c, 8, -32, 5, 4, BONE_LIGHT)
	_l(c, -6, -30, 6, -25, BONE_DARK, 2)


static func _cinder_stalker(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_quiver(c, -20, -42, true)
	_cape(c, p, 12, 30)
	_biped(c, p, step, 7)
	_r(c, -7, -46, 14, 7, BONE_DARK)
	_r(c, -6, -45, 12, 3, BONE)
	_p(c, [Vector2(-6,-44),Vector2(-11,-51),Vector2(-9,-41)], BONE_LIGHT)
	_p(c, [Vector2(6,-44),Vector2(10,-49),Vector2(9,-40)], BONE)
	_r(c, -3, -40, 2, 2, EMBER)
	_r(c, 2, -40, 3, 2, INK)
	for y: int in [-28,-23,-18]:
		_r(c, -6, y, 12, 2, BONE)
		_r(c, -5, y, 4, 1, BONE_LIGHT)
	_r(c, -8, -32, 4, 5, BONE_LIGHT)
	_r(c, 5, -32, 4, 5, BONE)
	_bow(c, 14, -48, 4, BONE, strike, true)
	_p(c, [Vector2(12,-46),Vector2(8,-53),Vector2(14,-50)], BONE_LIGHT)
	_p(c, [Vector2(16,0),Vector2(21,5),Vector2(17,-4)], BONE)
	_r(c, 7, -28, 7, 3, BONE)
	for x: int in [-6,4]:
		_r(c, x, -5, 3, 7, BONE_DARK)
		_r(c, x, -5, 2, 2, BONE_LIGHT)


static func _robot(c: Object, p: Dictionary, step: int, width: int = 11) -> void:
	for side: int in [-1,1]:
		var x := -8 if side < 0 else 3
		var dy := step if side < 0 else -step
		_r(c, x, -12+dy, 6, 16, INK)
		_r(c, x+1, -11+dy, 4, 11, COPPER)
		_r(c, x+1, -7+dy, 4, 2, STEEL_DARK)
		_r(c, x-1, 2+dy, 9, 4, INK)
		_r(c, x, 3+dy, 7, 2, STEEL)
	_r(c, -width, -35, width*2, 24, INK)
	_r(c, -width+1, -34, width*2-2, 21, COPPER)
	_r(c, -width+2, -33, width*2-4, 3, COPPER_LIGHT)
	_r(c, 3, -29, width-4, 15, COPPER.darkened(0.25))
	_r(c, -width-3, -31, 5, 16, INK)
	_r(c, width-2, -31, 5, 16, INK)
	_r(c, -width-2, -30, 3, 11, STEEL)
	_r(c, width-1, -30, 3, 11, STEEL_LIGHT)
	for x: int in [-width+2,width-4]:
		for y: int in [-31,-17]: _r(c, x, y, 2, 2, STEEL_LIGHT)
	_r(c, -7, -47, 14, 13, INK)
	_r(c, -6, -46, 12, 11, COPPER)
	_r(c, -5, -45, 10, 2, COPPER_LIGHT)
	_r(c, -5, -41, 10, 3, INK)
	_r(c, -4, -40, 8, 1, TEAL)
	_r(c, -3, -36, 6, 1, STEEL_DARK)


static func _coil_warden(c: Object, p: Dictionary, step: int, strike: int) -> void:
	# A boiler's broad, nearly rectangular body is unlike a humanoid tank.
	_r(c, -13, -56, 6, 30, INK)
	_r(c, -12, -55, 4, 27, STEEL_DARK)
	_r(c, -14, -56, 8, 3, COPPER_LIGHT)
	_r(c, 7, -52, 6, 25, INK)
	_r(c, 8, -51, 4, 22, COPPER)
	_r(c, 6, -52, 8, 3, STEEL)
	_robot(c, p, step, 13)
	_r(c, -9, -48, 18, 12, INK)
	_r(c, -8, -47, 16, 8, COPPER)
	_r(c, -7, -46, 14, 2, COPPER_LIGHT)
	_r(c, -6, -42, 12, 2, INK)
	_r(c, -4, -42, 8, 1, TEAL)
	_r(c, -11, -28, 22, 13, STEEL_DARK)
	for x: int in [-8,-4,0,4,8]: _r(c, x, -26, 2, 9, INK)
	_r(c, -26, -35, 15, 35, INK)
	_r(c, -25, -34, 13, 32, STEEL_DARK)
	_r(c, -24, -33, 11, 3, COPPER_LIGHT)
	_r(c, -24, -27, 11, 17, p.owner)
	_r(c, -24, -27, 3, 17, p.owner_light)
	for y: int in [-24,-20,-16]: _r(c, -22, y, 7, 1, p.owner_dark)
	_r(c, -24, -7, 11, 3, COPPER)
	_r(c, 19, -35-strike, 3, 34, INK)
	_r(c, 20, -34-strike, 1, 31, WOOD)
	_r(c, 13, -45-strike, 14, 13, INK)
	_r(c, 14, -44-strike, 12, 10, COPPER)
	_r(c, 14, -44-strike, 12, 2, COPPER_LIGHT)
	_r(c, 24, -42-strike, 2, 7, STEEL)


static func _volt_weaver(c: Object, p: Dictionary, step: int, strike: int, lift: int) -> void:
	for side: int in [-1,1]:
		var x := side*14-3
		_r(c, x, -53, 6, 30, INK)
		_r(c, x+1, -51, 4, 26, STEEL_DARK)
		for y: int in [-49,-44,-39]:
			_r(c, x-1, y, 8, 3, COPPER)
			_r(c, x-1, y, 7, 1, COPPER_LIGHT)
		_r(c, x+1, -58, 2, 6, TEAL)
	_robot(c, p, step, 8)
	_r(c, -4, -53, 2, 9, STEEL_LIGHT)
	_r(c, 3, -56, 2, 12, COPPER_LIGHT)
	_r(c, -6, -53, 6, 2, STEEL)
	_r(c, 1, -56, 6, 2, COPPER)
	_r(c, -7, -35, 14, 3, TEAL.darkened(0.3))
	_r(c, -6, -26, 12, 11, STEEL_DARK)
	for y: int in [-24,-20,-16]: _r(c, -5, y, 10, 1, TEAL)
	_r(c, 21, -53-lift-strike, 2, 56, INK)
	_r(c, 21, -52-lift-strike, 1, 54, COPPER_LIGHT)
	_l(c, 21, -51-lift, 16, -59-lift, STEEL, 2)
	_l(c, 21, -51-lift, 26, -59-lift, STEEL, 2)
	_r(c, 15, -60-lift, 3, 3, TEAL)
	_r(c, 25, -60-lift, 3, 3, TEAL)
	_r(c, -14, -20-lift, 5, 7, INK)
	_r(c, -13, -19-lift, 3, 5, COPPER_LIGHT)
	_r(c, -13, -19-lift, 3, 1, TEAL)


static func _gear_hunter(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_r(c, -20, -47, 6, 35, INK)
	_r(c, -19, -46, 4, 30, STEEL_DARK)
	for y: int in [-44,-38,-32]: _r(c, -19, y, 4, 2, COPPER_LIGHT)
	_l(c, -17, -18, -24, 2, STEEL, 2)
	_l(c, -17, -18, -13, 2, STEEL, 2)
	_robot(c, p, step, 8)
	_p(c, [Vector2(-10,-33),Vector2(-2,-30),Vector2(-3,1),Vector2(-14,3)], WOOD_DARK)
	_p(c, [Vector2(3,-31),Vector2(10,-33),Vector2(14,2),Vector2(5,0)], Color("6e6256"))
	_l(c, -10, -29, -12, 0, COPPER, 1)
	_l(c, 9, -29, 12, 0, COPPER_LIGHT, 1)
	_r(c, -8, -49, 17, 5, INK)
	_r(c, -7, -48, 15, 3, WOOD_DARK)
	_r(c, -4, -51, 9, 3, STEEL_DARK)
	_r(c, -7, -42, 15, 4, INK)
	_r(c, -5, -41, 4, 2, GOLD)
	_r(c, 2, -41, 4, 2, TEAL)
	_l(c, -4, -32, 5, -17, COPPER_LIGHT, 2)
	_r(c, 1-strike, -29, 24, 7, INK)
	_r(c, 3-strike, -28, 20, 4, COPPER)
	_r(c, 9-strike, -28, 14, 1, STEEL_LIGHT)
	_r(c, 12-strike, -34, 8, 4, INK)
	_r(c, 13-strike, -33, 6, 2, STEEL)
	_r(c, 18-strike, -33, 1, 2, TEAL)
	_r(c, 24-strike, -30, 3, 9, STEEL_DARK)
	_r(c, 25-strike, -28, 2, 4, INK)
	_r(c, 6-strike, -22, 4, 6, WOOD_DARK)
	_r(c, 2, -25, 5, 4, COPPER_LIGHT)
	for y: int in [-15,-11]: _r(c, 8, y, 2, 2, GOLD)


static func _vine_warden(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_cape(c, p, 16, 34)
	_biped(c, p, step, 12)
	_p(c, [Vector2(-7,-44),Vector2(-11,-54),Vector2(-18,-56),Vector2(-12,-57),Vector2(-8,-54),Vector2(-6,-61),Vector2(-4,-52),Vector2(-2,-44)], WOOD_DARK)
	_p(c, [Vector2(4,-44),Vector2(8,-55),Vector2(14,-59),Vector2(12,-52),Vector2(19,-54),Vector2(12,-47),Vector2(8,-44)], WOOD)
	_l(c, -8, -52, -6, -56, LEAF_LIGHT, 2)
	_l(c, 9, -51, 13, -55, LEAF_LIGHT, 2)
	_r(c, -7, -45, 14, 8, WOOD_DARK)
	_r(c, -6, -44, 12, 3, WOOD)
	_r(c, -5, -40, 10, 2, LEAF_LIGHT)
	_r(c, -13, -35, 26, 9, WOOD_DARK)
	for x: int in [-11,-6,4,9]:
		_r(c, x, -34, 3, 7, WOOD)
		_r(c, x, -34, 2, 2, LEAF)
	for x: int in [-7,-2,4]: _l(c, x, -26, x+1, -13, WOOD_DARK, 2)
	_p(c, [Vector2(-26,-35),Vector2(-20,-41),Vector2(-10,-36),Vector2(-9,-7),Vector2(-16,1),Vector2(-25,-7)], INK)
	_p(c, [Vector2(-24,-34),Vector2(-20,-38),Vector2(-12,-34),Vector2(-11,-8),Vector2(-16,-1),Vector2(-23,-8)], WOOD_DARK)
	for x: int in [-22,-18,-14]:
		_r(c, x, -32, 2, 22, WOOD)
		_r(c, x, -30, 1, 15, LEAF)
	_r(c, -22, -27, 10, 10, p.owner_dark)
	_r(c, -21, -26, 8, 7, p.owner)
	_p(c, [Vector2(-21,-14),Vector2(-15,-18),Vector2(-16,-12)], LEAF_LIGHT)
	_r(c, 18, -35-strike, 3, 35, WOOD_DARK)
	_p(c, [Vector2(12,-46-strike),Vector2(20,-49-strike),Vector2(26,-42-strike),Vector2(24,-32-strike),Vector2(16,-30-strike)], INK)
	_p(c, [Vector2(14,-44-strike),Vector2(20,-46-strike),Vector2(24,-41-strike),Vector2(22,-34-strike),Vector2(17,-33-strike)], WOOD)
	_l(c, 15, -42-strike, 22, -38-strike, LEAF_LIGHT, 2)
	for x: int in [-7,4]: _r(c, x, -5, 4, 6, WOOD)


static func _leaf_seer(c: Object, p: Dictionary, step: int, strike: int, lift: int) -> void:
	_cape(c, p, 15, 37)
	_biped(c, p, step, 8, true)
	_p(c, [Vector2(-10,-34),Vector2(0,-30),Vector2(10,-34),Vector2(14,1),Vector2(-13,1)], Color("506c4b"))
	for y: int in [-27,-19,-11]:
		_p(c, [Vector2(-10,y),Vector2(-2,y-4),Vector2(-2,y+5)], LEAF)
		_p(c, [Vector2(2,y-4),Vector2(10,y),Vector2(2,y+5)], LEAF_LIGHT)
	_p(c, [Vector2(-8,-43),Vector2(-5,-56),Vector2(0,-51),Vector2(5,-59),Vector2(10,-42)], INK)
	_p(c, [Vector2(-6,-43),Vector2(-4,-53),Vector2(0,-48),Vector2(5,-55),Vector2(7,-43)], LEAF)
	_l(c, -3, -49, 0, -43, LEAF_LIGHT, 2)
	_l(c, 5, -51, 3, -44, LEAF_LIGHT, 1)
	_r(c, -8, -43, 17, 2, WOOD)
	_r(c, -7, -34, 14, 4, LEAF_LIGHT)
	_r(c, 18, -50-lift-strike, 3, 54, WOOD_DARK)
	_r(c, 18, -49-lift-strike, 1, 52, WOOD)
	_l(c, 19, -48-lift, 13, -59-lift, WOOD, 2)
	_l(c, 19, -48-lift, 24, -59-lift, WOOD, 2)
	_p(c, [Vector2(12,-55-lift),Vector2(10,-59-lift),Vector2(16,-56-lift)], LEAF_LIGHT)
	_p(c, [Vector2(23,-56-lift),Vector2(26,-60-lift),Vector2(26,-54-lift)], LEAF)
	_r(c, 17, -54-lift, 5, 4, TEAL)
	_r(c, 18, -54-lift, 2, 2, BONE_LIGHT)
	_r(c, -15, -22-lift, 7, 8, WOOD_DARK)
	_p(c, [Vector2(-16,-24-lift),Vector2(-11,-28-lift),Vector2(-6,-23-lift)], LEAF_LIGHT)
	_r(c, -13, -21-lift, 4, 5, BONE)
	_l(c, -10, -1, 10, -1, WOOD, 2)


static func _wind_courier(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_quiver(c, -17, -37)
	_p(c, [Vector2(-6,-33),Vector2(-17,-36),Vector2(-27,-28),Vector2(-21,-24),Vector2(-26,-17),Vector2(-13,-20),Vector2(-6,-11)], INK)
	_p(c, [Vector2(-7,-31),Vector2(-16,-34),Vector2(-23,-28),Vector2(-18,-25),Vector2(-22,-20),Vector2(-13,-22),Vector2(-7,-14)], Color("829c64"))
	_l(c, -17, -29, -9, -21, LEAF_LIGHT, 1)
	_l(c, -18, -23, -10, -18, LEAF_LIGHT, 1)
	_biped(c, p, step, 7)
	_r(c, -5, -45, 12, 4, Color("567951"))
	_p(c, [Vector2(-3,-44),Vector2(-15,-54),Vector2(-5,-52),Vector2(2,-44)], LEAF_LIGHT)
	_p(c, [Vector2(0,-45),Vector2(-7,-57),Vector2(2,-52),Vector2(6,-44)], BONE_LIGHT)
	_p(c, [Vector2(-5,-39),Vector2(-11,-42),Vector2(-6,-35)], p.skin)
	_p(c, [Vector2(5,-39),Vector2(11,-42),Vector2(6,-35)], p.skin_light)
	_r(c, -8, -34, 16, 4, LEAF)
	_l(c, -6, -29, 6, -16, WOOD, 2)
	_r(c, -7, -10, 4, 10, LEAF.darkened(0.25))
	_r(c, 3, -10, 4, 10, LEAF)
	_bow(c, 15, -47, 2, LEAF_LIGHT, strike)
	_r(c, 6, -29, 9, 3, p.skin)
	_r(c, 11, -28, 4, 2, p.skin_light)
	for x: int in [-6,3]:
		_r(c, x, -5, 3, 1, WOOD)
		_r(c, x, -2, 3, 1, WOOD)


static func _ridge_jarl(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_cape(c, p, 18, 39)
	_biped(c, p, step, 12)
	_p(c, [Vector2(-8,-46),Vector2(-18,-56),Vector2(-17,-47),Vector2(-10,-39)], INK)
	_p(c, [Vector2(8,-46),Vector2(19,-56),Vector2(17,-45),Vector2(10,-39)], INK)
	_p(c, [Vector2(-9,-45),Vector2(-16,-52),Vector2(-15,-46),Vector2(-10,-41)], FUR_LIGHT)
	_p(c, [Vector2(9,-45),Vector2(17,-52),Vector2(15,-45),Vector2(10,-41)], FUR)
	_r(c, -8, -49, 16, 9, INK)
	_r(c, -7, -48, 14, 6, STEEL)
	_r(c, -6, -48, 12, 2, STEEL_LIGHT)
	_r(c, -1, -48, 3, 8, GOLD)
	_r(c, -5, -36, 11, 8, WOOD_DARK)
	_r(c, -4, -36, 3, 7, FUR)
	_r(c, 1, -36, 4, 8, FUR_LIGHT)
	for x: int in [-15,-9,-3,3,9]:
		_p(c, [Vector2(x,-35),Vector2(x+5,-38),Vector2(x+7,-29),Vector2(x+3,-26)], FUR)
		_r(c, x+2, -34, 2, 4, FUR_LIGHT)
	_p(c, [Vector2(-26,-32),Vector2(-20,-38),Vector2(-10,-34),Vector2(-8,-11),Vector2(-17,1),Vector2(-25,-8)], INK)
	_p(c, [Vector2(-24,-31),Vector2(-19,-35),Vector2(-12,-32),Vector2(-10,-11),Vector2(-17,-2),Vector2(-23,-9)], STEEL_DARK)
	_r(c, -22, -29, 10, 17, STEEL)
	_l(c, -21, -25, -14, -18, STEEL_LIGHT, 2)
	_l(c, -14, -28, -20, -14, GOLD, 2)
	_r(c, -21, -10, 7, 5, p.owner)
	_r(c, 19, -36-strike, 3, 35, WOOD_DARK)
	_r(c, 12, -46-strike, 15, 13, INK)
	_r(c, 13, -45-strike, 13, 10, STEEL)
	_r(c, 13, -45-strike, 13, 3, STEEL_LIGHT)
	_r(c, 15, -40-strike, 8, 3, GOLD)
	for x: int in [-7,4]: _r(c, x, -6, 5, 6, STEEL_LIGHT)


static func _rune_oracle(c: Object, p: Dictionary, step: int, strike: int, lift: int) -> void:
	# Squat forge priest with a recognisable anvil carried behind his shoulder.
	_r(c, -23, -43, 13, 5, INK)
	_p(c, [Vector2(-25,-49),Vector2(-8,-49),Vector2(-11,-42),Vector2(-21,-42)], STEEL_DARK)
	_r(c, -23, -49, 14, 2, STEEL_LIGHT)
	_r(c, -20, -42, 7, 15, COPPER)
	_r(c, -22, -29, 11, 4, STEEL_DARK)
	_cape(c, p, 15, 35)
	_biped(c, p, step, 10, true)
	_r(c, -8, -48, 16, 6, INK)
	_r(c, -7, -47, 14, 4, STEEL)
	_r(c, -6, -47, 12, 1, STEEL_LIGHT)
	_r(c, -5, -46, 2, 3, TEAL)
	_r(c, 3, -46, 2, 3, GOLD)
	_r(c, -7, -35, 14, 10, WOOD_DARK)
	for x: int in [-6,-1,4]:
		_r(c, x, -34, 3, 13, FUR)
		_r(c, x, -32, 1, 9, FUR_LIGHT)
		_r(c, x, -24, 3, 2, COPPER)
	_r(c, -10, -18, 20, 17, WOOD_DARK)
	_r(c, -8, -17, 16, 14, Color("8b765b"))
	for x: int in [-6,5]: _r(c, x, -16, 2, 10, COPPER_LIGHT)
	_r(c, 19, -47-lift-strike, 3, 51, WOOD_DARK)
	_r(c, 20, -46-lift-strike, 1, 49, COPPER)
	_p(c, [Vector2(13,-59-lift),Vector2(24,-60-lift),Vector2(27,-47-lift),Vector2(15,-45-lift)], INK)
	_p(c, [Vector2(15,-57-lift),Vector2(23,-58-lift),Vector2(25,-49-lift),Vector2(17,-47-lift)], STEEL_DARK)
	_l(c, 18, -55-lift, 22, -51-lift, TEAL, 2)
	_l(c, 22, -55-lift, 18, -50-lift, TEAL, 1)
	_r(c, -15, -20-lift, 6, 8, INK)
	_r(c, -14, -19-lift, 4, 6, GOLD)
	_r(c, -13, -18-lift, 2, 2, EMBER)
	for x: int in [-6,4]: _r(c, x, 1, 4, 3, FUR_LIGHT)


static func _ember_cavalier(c: Object, p: Dictionary, step: int, strike: int) -> void:
	var rust := Color("a9654a")
	_p(c, [Vector2(-7,-35),Vector2(-16,-38),Vector2(-23,-24),Vector2(-21,1),Vector2(-10,-3)], INK)
	_p(c, [Vector2(-8,-33),Vector2(-15,-35),Vector2(-20,-23),Vector2(-19,-2),Vector2(-11,-6)], rust.darkened(0.2))
	_l(c, -18, -24, -17, -4, rust, 2)
	_biped(c, p, step, 9)
	_p(c, [Vector2(-4,-46),Vector2(-2,-61),Vector2(3,-55),Vector2(7,-57),Vector2(5,-44)], INK)
	_p(c, [Vector2(-2,-46),Vector2(0,-57),Vector2(3,-51),Vector2(5,-53),Vector2(3,-45)], rust)
	_l(c, 0, -52, 1, -46, GOLD_LIGHT, 2)
	_r(c, -7, -45, 15, 7, STEEL_DARK)
	_r(c, -6, -44, 13, 3, STEEL)
	_r(c, 0, -43, 3, 7, GOLD)
	_r(c, 1, -40, 5, 1, INK)
	for x: int in [-13,-8,-3]:
		_p(c, [Vector2(x,-34),Vector2(x+4,-38),Vector2(x+7,-28),Vector2(x+3,-26)], FUR)
		_r(c, x+2, -34, 2, 4, FUR_LIGHT)
	_r(c, -8, -28, 16, 15, STEEL_DARK)
	for y: int in [-26,-21,-16]: _r(c, -7, y, 14, 1, STEEL)
	_r(c, -6, -12, 4, 11, rust)
	_r(c, 3, -12, 4, 10, p.owner_dark)
	_p(c, [Vector2(12,-13),Vector2(15,-34-strike),Vector2(20,-49-strike),Vector2(26,-52-strike),Vector2(24,-35-strike),Vector2(17,-12)], INK)
	_p(c, [Vector2(14,-15),Vector2(17,-34-strike),Vector2(21,-47-strike),Vector2(24,-49-strike),Vector2(22,-35-strike),Vector2(16,-15)], STEEL)
	_l(c, 17, -18, 23, -44-strike, STEEL_LIGHT, 1)
	_l(c, 9, -15, 20, -12, GOLD, 2)
	_r(c, 11, -13, 4, 10, WOOD_DARK)
	_r(c, 10, -5, 6, 3, GOLD)
	_r(c, -8, -5, 4, 4, STEEL_LIGHT)
	_r(c, 4, -5, 4, 4, STEEL)


static func _arthropod(c: Object, p: Dictionary, step: int, legs: int, width: int, top: int) -> void:
	for side: int in [-1,1]:
		for index: int in range(legs/2):
			var y := -17+index*6
			var dy := step if (index+1)%2 == 0 else -step
			var outer := side*(width+8-index)
			_l(c, side*(width-2), y, outer, y+4+dy, INK, 4)
			_l(c, outer, y+4+dy, side*(width+5-index), 4+dy, INK, 3)
			_l(c, side*(width-2), y-1, outer, y+3+dy, CHITIN, 2)
			_l(c, outer, y+3+dy, side*(width+5-index), 3+dy, CHITIN_LIGHT, 1)
	_r(c, -width, top, width*2, -top-6, INK)
	_r(c, -width+1, top+1, width*2-2, -top-8, CHITIN)
	_r(c, -width+2, top+2, width*2-4, 3, CHITIN_LIGHT)
	_r(c, 2, top+7, width-3, -top-18, Color("514c64"))
	_r(c, -6, top-13, 12, 13, INK)
	_r(c, -5, top-12, 10, 10, CHITIN_LIGHT)
	_r(c, -4, top-10, 8, 3, INK)
	_r(c, -3, top-9, 2, 1, TEAL)
	_r(c, 2, top-9, 2, 1, TEAL)
	for x: int in [-5,2]: _r(c, x, top-3, 3, 4, BONE_DARK)


static func _tunnel_sentinel(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_arthropod(c, p, step, 6, 14, -29)
	_p(c, [Vector2(-14,-28),Vector2(-16,-40),Vector2(-8,-48),Vector2(8,-48),Vector2(16,-40),Vector2(14,-28)], INK)
	_p(c, [Vector2(-12,-29),Vector2(-14,-39),Vector2(-7,-46),Vector2(7,-46),Vector2(14,-39),Vector2(12,-29)], CHITIN)
	_r(c, -10, -39, 20, 4, CHITIN_LIGHT)
	for x: int in [-11,-5,2,8]:
		_p(c, [Vector2(x,-43),Vector2(x+2,-52),Vector2(x+5,-43)], BONE_DARK)
		_r(c, x+2, -47, 1, 3, BONE_LIGHT)
	_r(c, -7, -39, 14, 3, INK)
	_r(c, -5, -38, 3, 1, TEAL)
	_r(c, 3, -38, 3, 1, TEAL)
	for y: int in [-23,-17,-11]: _r(c, -11, y, 22, 1, CHITIN_LIGHT)
	_r(c, -27, -35, 14, 35, INK)
	_p(c, [Vector2(-26,-34),Vector2(-15,-34),Vector2(-14,-9),Vector2(-20,1),Vector2(-26,-8)], CHITIN_LIGHT)
	_r(c, -24, -31, 8, 18, CHITIN)
	_r(c, -23, -29, 6, 14, p.owner)
	_r(c, -23, -29, 2, 14, p.owner_light)
	_r(c, -22, -23, 4, 2, BONE_LIGHT)
	_l(c, 18, -9, 19+strike, -39, INK, 4)
	_l(c, 18, -10, 19+strike, -38, WOOD, 2)
	_p(c, [Vector2(17+strike,-39),Vector2(20+strike,-52),Vector2(22+strike,-39)], BONE)
	_l(c, 20+strike, -47, 20+strike, -39, BONE_LIGHT, 1)
	_r(c, -6, -8, 12, 3, BONE_DARK)


static func _echo_binder(c: Object, p: Dictionary, step: int, strike: int, lift: int) -> void:
	# Three grounded legs and a broad acoustic cap, not a robed human reuse.
	_l(c, 0, -11, 0, 4+step, INK, 5)
	_l(c, 0, -10, 0, 3+step, CHITIN_LIGHT, 2)
	_l(c, -4, 4+step, 4, 4+step, INK, 3)
	_arthropod(c, p, step, 2, 10, -34)
	_p(c, [Vector2(-18,-43),Vector2(-15,-51),Vector2(-5,-57),Vector2(8,-55),Vector2(17,-47),Vector2(18,-42)], INK)
	_p(c, [Vector2(-16,-44),Vector2(-13,-50),Vector2(-4,-54),Vector2(7,-53),Vector2(14,-47),Vector2(15,-44)], CHITIN)
	_r(c, -14, -44, 28, 3, CHITIN_LIGHT)
	_r(c, -13, -41, 26, 2, CHITIN.darkened(0.25))
	_r(c, -9, -50, 5, 1, CHITIN_LIGHT)
	_r(c, 3, -48, 7, 1, CHITIN_LIGHT)
	for x: int in [-10,-4,3,9]:
		_r(c, x, -48, 2, 3, TEAL.darkened(0.1))
	_r(c, -5, -40, 10, 5, CHITIN_LIGHT)
	_r(c, -4, -38, 8, 1, INK)
	for y: int in [-28,-21,-14]:
		_r(c, -8, y, 16, 2, CHITIN_LIGHT)
		_r(c, -7, y+1, 14, 1, CHITIN.darkened(0.3))
	_r(c, 20, -52-lift-strike, 2, 55, CHITIN_LIGHT)
	_r(c, 16, -60-lift, 3, 14, INK)
	_r(c, 25, -60-lift, 3, 14, INK)
	_r(c, 17, -60-lift, 1, 12, TEAL)
	_r(c, 26, -60-lift, 1, 12, TEAL)
	_r(c, 17, -48-lift, 10, 3, CHITIN_LIGHT)
	_r(c, 19, -47-lift, 6, 2, COPPER)
	_r(c, -19, -25-lift, 6, 9, INK)
	_r(c, -18, -24-lift, 4, 7, CHITIN_LIGHT)
	_r(c, -17, -23-lift, 2, 4, TEAL)
	_r(c, -6, -10, 12, 3, CHITIN_LIGHT)


static func _spore_stalker(c: Object, p: Dictionary, step: int, strike: int) -> void:
	_arthropod(c, p, step, 4, 10, -30)
	_p(c, [Vector2(-16,-41),Vector2(-14,-49),Vector2(-5,-53),Vector2(7,-52),Vector2(14,-46),Vector2(17,-39),Vector2(5,-35),Vector2(-8,-35)], INK)
	_p(c, [Vector2(-14,-41),Vector2(-12,-47),Vector2(-4,-50),Vector2(6,-49),Vector2(12,-45),Vector2(14,-40),Vector2(4,-37),Vector2(-7,-37)], Color("75647e"))
	_p(c, [Vector2(-13,-41),Vector2(-6,-43),Vector2(0,-39),Vector2(12,-41),Vector2(4,-37),Vector2(-7,-37)], CHITIN_LIGHT)
	for point: Vector2 in [Vector2(-8,-46),Vector2(-1,-48),Vector2(6,-45)]:
		_r(c, int(point.x), int(point.y), 3, 2, Color("a5b29a"))
	_r(c, -6, -36, 12, 4, INK)
	_r(c, -4, -35, 3, 1, TEAL)
	_r(c, 2, -35, 3, 1, TEAL)
	_p(c, [Vector2(-8,-30),Vector2(-15,-33),Vector2(-18,-21),Vector2(-12,-13),Vector2(-8,-17)], CHITIN.darkened(0.25))
	_p(c, [Vector2(8,-30),Vector2(15,-33),Vector2(18,-21),Vector2(12,-13),Vector2(8,-17)], CHITIN)
	for y: int in [-25,-20,-15]: _r(c, -7, y, 14, 1, CHITIN_LIGHT)
	_p(c, [Vector2(-13,-15),Vector2(-24,-33-strike),Vector2(-27,-28-strike),Vector2(-24,-39-strike),Vector2(-19,-38-strike),Vector2(-23,-35-strike),Vector2(-10,-18)], INK)
	_p(c, [Vector2(-13,-17),Vector2(-24,-35-strike),Vector2(-25,-30-strike),Vector2(-25,-37-strike),Vector2(-21,-37-strike),Vector2(-24,-35-strike),Vector2(-11,-18)], BONE)
	_p(c, [Vector2(12,-16),Vector2(24,-38-strike),Vector2(27,-34-strike),Vector2(25,-45-strike),Vector2(20,-43-strike),Vector2(24,-41-strike),Vector2(9,-18)], INK)
	_p(c, [Vector2(12,-18),Vector2(24,-41-strike),Vector2(25,-36-strike),Vector2(24,-43-strike),Vector2(22,-42-strike),Vector2(24,-41-strike),Vector2(10,-18)], STEEL_LIGHT)
	_l(c, -16, -19, -10, -23, COPPER, 2)
	_l(c, 10, -22, 16, -18, COPPER_LIGHT, 2)
	_r(c, -15, -25, 3, 2, CHITIN_LIGHT)
	_r(c, 12, -25, 3, 2, CHITIN_LIGHT)
	_r(c, -6, -9, 12, 3, CHITIN_LIGHT)


static func _fallen(c: Object, p: Dictionary, id: String) -> void:
	_p(c, [Vector2(-22,1),Vector2(-12,-5),Vector2(7,-4),Vector2(23,3),Vector2(18,7),Vector2(-17,7)], INK)
	_p(c, [Vector2(-20,2),Vector2(-11,-3),Vector2(7,-2),Vector2(20,3),Vector2(17,5),Vector2(-16,5)], p.owner_dark)
	_r(c, -11, -2, 23, 6, p.owner)
	_r(c, -10, -2, 20, 2, p.owner_light)
	if id in ["COIL_WARDEN","VOLT_WEAVER","GEAR_HUNTER"]:
		_r(c, -17, -4, 12, 9, INK)
		_r(c, -16, -3, 10, 7, COPPER)
		_r(c, -15, -3, 8, 1, COPPER_LIGHT)
		_r(c, -14, 0, 6, 2, STEEL_DARK)
		for x: int in [4,10,16]: _r(c, x, 3, 5, 3, STEEL)
	elif id in ["TUNNEL_SENTINEL","ECHO_BINDER","SPORE_STALKER"]:
		_p(c, [Vector2(-18,-1),Vector2(-13,-7),Vector2(3,-6),Vector2(10,2),Vector2(2,6),Vector2(-14,5)], CHITIN)
		_l(c, -13, -4, 3, -3, CHITIN_LIGHT, 2)
		for x: int in [-12,-3,6]:
			_l(c, x, 2, x+8, 6, CHITIN_LIGHT, 2)
			_l(c, x, 1, x+6, -4, CHITIN, 2)
	elif id in ["ASH_MARSHAL","MOURN_ORACLE","CINDER_STALKER"]:
		_r(c, -18, -3, 10, 8, INK)
		_r(c, -17, -2, 8, 6, BONE)
		_r(c, -16, 0, 2, 2, INK)
		_r(c, -12, 0, 2, 2, INK)
		for x: int in [-3,2,7]: _r(c, x, 1, 3, 4, BONE_LIGHT)
	else:
		_r(c, -18, -3, 10, 8, INK)
		_r(c, -17, -2, 8, 6, p.skin_dark)
		_r(c, -16, -2, 6, 2, p.skin)
		_r(c, -4, -1, 15, 3, p.armor)
		_r(c, -4, -1, 13, 1, p.armor_light)
	_r(c, 13, 2, 8, 4, WOOD_DARK)


static func _r(canvas: Object, x: int, y: int, width: int, height: int, color: Color) -> void:
	if width > 0 and height > 0: canvas.draw_rect(Rect2(x, y, width, height), color)


static func _l(canvas: Object, x1: int, y1: int, x2: int, y2: int, color: Color, width: int = 1) -> void:
	canvas.draw_line(Vector2(x1, y1), Vector2(x2, y2), color, width)


static func _p(canvas: Object, points: Array, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array(points), color)
