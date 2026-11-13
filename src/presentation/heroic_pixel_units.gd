extends RefCounted
## Provenance-aware actors: actual compatible licensed Creature frames when
## available, with original integer-painted fallbacks for unsupported roles.
const CollectionUnits = preload("res://src/presentation/heroic_collection_units.gd")
const GeneratedUnits = preload("res://src/presentation/heroic_generated_units.gd")
const IdentityArt = preload("res://src/presentation/heroic_identity_art.gd")
const OutpostsV3 = preload("res://src/presentation/heroic_outposts_units_v3.gd")
const OutpostsV4 = preload("res://src/presentation/heroic_outposts_v4_units.gd")
const Catalog = preload("res://src/simulation/strategic_unit_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const FactionAV = preload("res://src/presentation/heroic_faction_av.gd")
const ExpansionActors=preload("res://src/presentation/heroic_expansion_actors_m66.gd")
const MageActors=preload("res://src/presentation/heroic_mage_actors_m68.gd")
const RangedActors=preload("res://src/presentation/heroic_ranged_roles_m68.gd")
const HeroPixelR8=preload("res://src/presentation/heroic_hero_pixel_r8.gd")
const TeamMaterial=preload("res://src/presentation/heroic_team_material_m70.gd")
const SIZE := Vector2i(48,48)
const FOOT := Vector2(24,43)
const MAX_ORIGINAL_FRAMES := 192
const MAX_FRAMES := MAX_ORIGINAL_FRAMES + CollectionUnits.MAX_FRAMES + GeneratedUnits.MAX_FRAMES + ExpansionActors.MAX_FRAMES + MageActors.MAX_FRAMES + RangedActors.MAX_FRAMES
const INK := Color("222331")
const STEEL := Color("8ea8b2")
const LIGHT := Color("dce0bf")
static var _frames: Dictionary = {}
static var _order: Array[String] = []
static var _bakes := 0


static func reset_cache() -> void:
	_frames.clear()
	_order.clear()
	_bakes = 0
	CollectionUnits.reset_cache()
	GeneratedUnits.reset_cache()
	IdentityArt.reset_cache()
	OutpostsV3.reset_cache()
	OutpostsV4.reset_cache()
	ExpansionActors.reset_cache()
	MageActors.reset_cache()
	RangedActors.reset_cache()
	HeroPixelR8.reset_cache()
	TeamMaterial.reset_cache()
	FactionAV.reset_draw_identity_cache_m80()


static func _category(unit: Dictionary) -> String:
	var type := str(unit.get("unit_type","worker"))
	var recipe: Dictionary = Catalog.UNITS.get(type,{})
	if type == "hero":
		var profile: Dictionary = Heroes.PROFILES.get(str(unit.get("hero_archetype","COMMANDER")),Heroes.PROFILES.COMMANDER)
		var role := str(profile.get("role",""))
		return "mage_hero" if "法师" in role else "ranger_hero" if "射手" in role else "tank_hero" if "坦克" in role else "blade_hero"
	var body := str(recipe.get("body_kind","HUMANOID"))
	if body == "DRAGON": return "dragon"
	if body == "VEHICLE": return "engine"
	if recipe.get("role") == "CAVALRY": return "rider"
	return {"WORKER":"worker","FRONTLINE":"guard","HEAVY":"lancer","RANGED":"ranger","SUPPORT":"mage"}.get(str(recipe.get("role","WORKER")),"guard")


static func _frame(unit: Dictionary, pose: Dictionary) -> Dictionary:
	var category := _category(unit)
	var action := str(pose.get("action","IDLE"))
	var bucket := clampi(floori(float(pose.get("body_phase_m76",pose.get("phase",0)))*3),0,2)
	if action in ["WALK","CARRY"]: bucket = posmod(floori(float(pose.get("body_animation_tick_m76",pose.get("animation_tick",0)))/3.0),4) if pose.has("body_animation_tick_m76") or pose.has("animation_tick") else 0 if float(pose.get("step",0))< -0.2 else 2 if float(pose.get("step",0))>0.2 else 1
	if action in ["IDLE","FALLEN"]: bucket = 0
	var direction := Vector2(pose.get("direction",Vector2.RIGHT))
	var mirror := direction.x < 0
	var faction := str(unit.get("faction_id",Catalog.UNITS.get(str(unit.get("unit_type","")),{}).get("faction_id","HUMAN")))
	var side := str(unit.get("side","PLAYER"))
	var key := "%s:%s:%s:%s:%d:%s:%s:%s" % [category,faction,side,action,bucket,str(mirror),str(unit.get("role","RESERVE")),str(unit.get("cargo_type","")) if int(unit.get("cargo_amount",0))>0 else ""]
	if _frames.has(key):
		_order.erase(key)
		_order.append(key)
		return _frames[key]
	var image := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var team := Palette.side_color(side)
	var skin := Color("e8c999")
	var cloth := Color("7c735b")
	if faction == "UNDEAD": skin=Color("d2d8af");cloth=Color("665276")
	elif faction == "MACHINE": skin=Color("9fafa7");cloth=Color("997857")
	elif faction == "FOREST": cloth=Color("5c834e")
	elif faction == "HIGHLAND": cloth=Color("797c8b")
	elif faction == "UNDERGROUND": skin=Color("bd916a");cloth=Color("8d6576")
	var walking := action in ["WALK","CARRY"]
	var attacking := action == "ATTACK" or action.begins_with("SKILL_")
	var working := action in ["HARVEST","MINE","BUILD"]
	var bob := -1 if walking and bucket in [0,2] else 0
	var stride := -2 if walking and bucket==0 else 2 if walking and bucket==2 else 0
	if action == "FALLEN":
		_rect(image,14,38,18,5,INK)
		_rect(image,17,37,11,4,cloth)
		_rect(image,29,38,5,3,skin)
		_rect(image,17,37,6,2,team)
	elif category == "dragon":
		_dragon(image,team,bob,stride,attacking,bucket)
	elif category == "engine":
		_rect(image,8,33+bob,30,8,INK)
		_rect(image,10,31+bob,26,8,cloth)
		for x: int in [12,22,32]:
			_rect(image,x,38,5,6,INK);_rect(image,x+1,39,3,3,STEEL)
			_rect(image,x+1+(1 if stride>0 else 0),39,1,3,Color("5b625e"))
		_rect(image,18,23+bob,12,10,INK);_rect(image,19,24+bob,10,8,STEEL)
		_rect(image,22,22+bob,7,3,team);_rect(image,29,27+bob,13 if attacking and bucket==1 else 10,4,INK)
		_rect(image,30,28+bob,10,2,Color("bfc4ad"))
	elif category == "worker":
		_worker(image,unit,faction,team,skin,cloth,action,bucket,stride,bob)
	else:
		var rider := category == "rider"
		var feet := 43 if not rider else 33
		if rider: _horse(image,cloth,stride,bob)
		var heavy := category in ["lancer","tank_hero"]
		var hero := category.ends_with("_hero")
		var mage := category in ["mage","mage_hero"]
		var ranged := category in ["ranger","ranger_hero"]
		var worker := category == "worker"
		var top := feet-24+bob-(2 if hero else 0)
		if hero:
			_rect(image,16,top+9,14,15,INK)
			_rect(image,17,top+10,12,12,team.darkened(0.35))
			_rect(image,17,top+21,5,3,team)
		if not mage:
			_rect(image,19-stride/2,feet-7,4,7+mini(stride,0),INK)
			_rect(image,25+stride/2,feet-7,4,7-maxi(stride,0),INK)
			_rect(image,19-stride/2,feet-3,5,2,Color("6c4a37"))
			_rect(image,25+stride/2,feet-3,5,2,Color("6c4a37"))
		_rect(image,17 if heavy else 19,top+9,16 if heavy else 11,10,INK)
		_rect(image,18 if heavy else 20,top+10,14 if heavy else 9,8,STEEL if heavy or category=="guard" else cloth)
		_rect(image,20,top+12,8,5,team)
		_rect(image,20,top+17,10,2,Color("66523b"))
		_rect(image,23,top+17,2,2,Color("dfc46c"))
		if mage:
			_poly(image,[Vector2(19,top+14),Vector2(28,top+14),Vector2(32,feet-1),Vector2(16,feet-1)],INK)
			_poly(image,[Vector2(20,top+15),Vector2(27,top+15),Vector2(30,feet-2),Vector2(18,feet-2)],cloth)
			_rect(image,23,top+15,3,feet-top-17,team)
			_rect(image,18+(2 if stride>0 else 0),feet-4,5,2,cloth.lightened(0.3))
		_rect(image,21,top+3,8,8,INK)
		_rect(image,22,top+4,6,6,skin)
		_rect(image,27,top+6,2,1,INK)
		_rect(image,26,top+9,3,1,Color("b38b61"))
		if worker:
			_rect(image,20,top+2,10,3,Color("88693c"));_rect(image,19,top+5,13,2,Color("d1ad68"))
		elif mage:
			_poly(image,[Vector2(18,top+3),Vector2(24,top-5),Vector2(29,top+3)],INK)
			_poly(image,[Vector2(20,top+2),Vector2(24,top-3),Vector2(27,top+2)],cloth.lightened(0.25))
			_rect(image,18,top+3,13,2,team)
		elif ranged:
			_rect(image,20,top+1,9,4,cloth.darkened(0.2));_rect(image,19,top+3,3,7,cloth)
			_rect(image,16,top+10,3,11,Color("66523b"));_rect(image,16,top+8,3,3,LIGHT)
		else:
			_rect(image,20,top+1,10,5,INK);_rect(image,21,top+2,8,3,STEEL.lightened(0.2))
			_rect(image,19,top+4,12,2,STEEL);_rect(image,21,top+6,2,3,STEEL)
			if hero: _rect(image,21,top-2,3,4,team);_rect(image,21,top-3,7,2,team.lightened(0.3))
		var arm := top+12
		_rect(image,16,arm,4,7,INK);_rect(image,17,arm+1,3,5,skin)
		_rect(image,29,arm-(3 if attacking and bucket==1 else 0),4,7,INK)
		_rect(image,30,arm+1-(3 if attacking and bucket==1 else 0),3,5,skin)
		if worker:
			var tool_top := top+4 if working and bucket==1 else top+12
			_line(image,Vector2(31,top+18),Vector2(37,tool_top),Color("b18a54"),2)
			if action == "BUILD": _rect(image,33,tool_top-2,8,4,STEEL)
			elif action == "HARVEST": _line(image,Vector2(34,tool_top),Vector2(41,tool_top+3),LIGHT,2)
			else: _line(image,Vector2(32,tool_top-1),Vector2(41,tool_top+2),STEEL,2)
			if action == "CARRY": _rect(image,13,top+12,7,10,Color("674f35"));_rect(image,14,top+13,5,7,Color("b5975f"))
		elif mage:
			_rect(image,34,top+6,2,24,Color("63513e"));_rect(image,33,top+7,4,3,Color("cab878"))
			_rect(image,32,top+2,6,6,INK);_rect(image,33,top+3,4,4,Color("81d3c1") if not attacking else Color("f4cc7a"))
			_rect(image,34,top+3,2,2,LIGHT)
		elif ranged:
			var extend := 3 if attacking and bucket==1 else 0
			_line(image,Vector2(34+extend,top+10),Vector2(36+extend,top+21),Color("d4ba79"),2)
			_line(image,Vector2(34+extend,top+10),Vector2(39+extend,top+15),Color("966d3b"),2)
			_line(image,Vector2(39+extend,top+15),Vector2(36+extend,top+21),Color("966d3b"),2)
			_line(image,Vector2(30,top+16),Vector2(40+extend,top+16),LIGHT,1)
		elif category == "lancer" or rider:
			_line(image,Vector2(34,top+29),Vector2(35,top-8),Color("ac8d5d"),2)
			_poly(image,[Vector2(33,top-7),Vector2(36,top-13),Vector2(38,top-7)],LIGHT)
			_rect(image,34,top-5,5,5,team)
		else:
			var thrust := attacking and bucket==1
			if thrust:
				_rect(image,31,top+11,12,3,INK);_rect(image,32,top+11,11,1,LIGHT);_rect(image,31,top+9,2,7,Color("c9ac61"))
			else:
				_rect(image,33,top-2,3,19,INK);_rect(image,34,top-1,1,15,LIGHT);_rect(image,31,top+12,7,2,Color("c9ac61"))
			if category in ["guard","tank_hero"]:
				_rect(image,13,top+12,9,13,INK);_rect(image,14,top+13,7,10,team.darkened(0.25));_rect(image,17,top+13,2,10,LIGHT);_rect(image,14,top+16,7,2,LIGHT)
	if category=="worker":
		# Civilian source grid is48px, versus16px licensed bodies. A two-pixel
		# outside contour preserves the same displayed black edge thickness.
		var silhouette := image.duplicate() as Image
		for y: int in range(2,SIZE.y-2):
			for x: int in range(2,SIZE.x-2):
				if silhouette.get_pixel(x,y).a < 0.5: continue
				for d: Vector2i in [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
					if silhouette.get_pixelv(Vector2i(x,y)+d).a < 0.5: image.set_pixelv(Vector2i(x,y)+d,INK)
	if mirror: image.flip_x()
	var used := image.get_used_rect()
	var cropped := image.get_region(used)
	var anchor := Vector2(47-FOOT.x,FOOT.y) if mirror else FOOT
	var rect := Rect2(Vector2(used.position)-anchor,Vector2(used.size))
	var frame := {"key":key,"image":cropped,"texture":ImageTexture.create_from_image(cropped),"rect":rect,"category":category,"action":action,"bucket":bucket,"mirror":mirror,"pixel_hash":cropped.get_data().hex_encode().sha256_text()}
	while _order.size()>=MAX_ORIGINAL_FRAMES: _frames.erase(_order.pop_front())
	_frames[key]=frame;_order.append(key);_bakes+=1
	return frame


static func _worker(image: Image, unit: Dictionary, faction: String, team: Color, skin: Color, cloth: Color, action: String, bucket: int, stride: int, bob: int) -> void:
	# Civilians share the world's matte, dark-outline pixel language. Distinct
	# hats, baskets and work clothes replace the old armed Creature mappings.
	var top := 13 + bob
	var apron := Color("c9b48b")
	if faction == "UNDEAD": apron = Color("a8ad93")
	elif faction == "MACHINE": apron = Color("b68a58")
	elif faction == "FOREST": apron = Color("9eaf73")
	elif faction == "HIGHLAND": apron = Color("9b8973")
	elif faction == "UNDERGROUND": apron = Color("b28b98")
	# Full permanent basket/satchel silhouette, even when empty.
	_rect(image,10,top+10,9,16,INK)
	_rect(image,11,top+11,7,13,Color("7c6040"))
	for y: int in [13,17,21]: _rect(image,11,top+y,7,1,Color("b39662"))
	_rect(image,12,top+10,2,15,Color("b39662"))
	_rect(image,19-stride/2,36,4,7+mini(stride,0),INK)
	_rect(image,25+stride/2,36,4,7-maxi(stride,0),INK)
	_rect(image,18-stride/2,41,6,2,Color("75563c"))
	_rect(image,25+stride/2,41,6,2,Color("75563c"))
	_rect(image,18,top+9,13,16,INK)
	_rect(image,19,top+10,11,13,cloth)
	_rect(image,21,top+11,7,13,apron)
	_rect(image,22,top+13,2,8,apron.lightened(0.16))
	_rect(image,20,top+10,3,3,team)
	_rect(image,19,top+21,11,2,Color("65503e"))
	_rect(image,23,top+21,3,2,Color("d0b77d"))
	_rect(image,20,top+1,10,10,INK)
	_rect(image,21,top+2,8,8,skin)
	_rect(image,27,top+5,2,1,INK)
	_rect(image,24,top+8,5,1,skin.darkened(0.2))
	match faction:
		"HUMAN":
			_rect(image,20,top-2,10,5,INK); _rect(image,21,top-2,8,4,Color("b69b5e"))
			_rect(image,16,top+2,18,3,INK); _rect(image,17,top+2,16,2,Color("dec888"))
			_rect(image,21,top,8,1,team)
		"UNDEAD":
			_rect(image,20,top-1,10,4,Color("665276")); _rect(image,18,top+2,4,7,Color("665276"))
			_rect(image,20,top+4,2,3,Color("a1a294")); _rect(image,28,top+6,2,2,Color("c4cbb2"))
			_rect(image,21,top-1,8,1,Color("9c8aab"))
		"MACHINE":
			_rect(image,20,top-1,11,5,INK); _rect(image,21,top-1,9,3,Color("a67b48"))
			_rect(image,24,top,3,2,Color("dfcf92")); _rect(image,21,top+4,8,3,Color("534d3e"))
			_rect(image,22,top+4,2,2,Color("a6c4be")); _rect(image,26,top+4,2,2,Color("a6c4be"))
			_rect(image,29,top+1,4,2,Color("ccb27d"))
		"FOREST":
			_poly(image,[Vector2(17,top+3),Vector2(22,top-4),Vector2(30,top),Vector2(33,top+4)],INK)
			_poly(image,[Vector2(19,top+2),Vector2(22,top-2),Vector2(29,top+1),Vector2(31,top+3)],Color("71915a"))
			_rect(image,21,top,7,1,Color("b4c47c")); _rect(image,18,top+12,2,12,Color("778e55"))
		"HIGHLAND":
			_rect(image,20,top-1,11,5,INK); _rect(image,21,top-1,9,4,Color("8b8173"))
			_rect(image,18,top+3,15,2,Color("b8a77d")); _rect(image,24,top+1,3,3,Color("e5d18c"))
			_rect(image,21,top+7,8,5,Color("b6a28b")); _rect(image,23,top+11,4,3,Color("dbccac"))
		"UNDERGROUND":
			_rect(image,21,top-3,8,6,INK); _rect(image,19,top-1,12,4,Color("9b697d"))
			_rect(image,17,top+2,17,3,Color("b1839a")); _rect(image,21,top,3,2,Color("dcc6bb"))
			_rect(image,27,top+1,2,1,Color("dcc6bb")); _rect(image,29,top+11,3,8,Color("8f6c89"))
	# Rolled sleeves, visible hand and short work tool: never sword or shield.
	_rect(image,16,top+11,4,9,INK); _rect(image,17,top+12,3,4,apron.lightened(0.12)); _rect(image,17,top+16,3,4,skin)
	var lift := -5 if action in ["MINE","HARVEST","BUILD","ATTACK"] and bucket==1 else 0
	_rect(image,29,top+11+lift,5,8,INK); _rect(image,30,top+12+lift,3,3,apron.lightened(0.12)); _rect(image,31,top+15+lift,3,4,skin)
	var tool := str(unit.get("role","RESERVE"))
	if action == "BUILD" or tool == "CONSTRUCTION_REPAIR":
		_line(image,Vector2(33,top+18+lift),Vector2(37,top+8+lift),Color("ac8954"),2)
		_rect(image,34,top+6+lift,8,4,INK); _rect(image,35,top+6+lift,6,3,Color("969e93"))
	elif action == "HARVEST" or tool == "FOOD":
		_line(image,Vector2(33,top+18+lift),Vector2(38,top+11+lift),Color("ac8954"),2)
		_line(image,Vector2(37,top+11+lift),Vector2(41,top+9+lift),Color("d8d9c0"),2)
		_rect(image,40,top+8+lift,2,3,Color("d8d9c0"))
	else:
		_line(image,Vector2(33,top+18+lift),Vector2(38,top+9+lift),Color("ac8954"),2)
		_line(image,Vector2(34,top+7+lift),Vector2(42,top+10+lift),INK,3)
		_line(image,Vector2(35,top+7+lift),Vector2(41,top+9+lift),Color("a6b1ad"),1)
	if int(unit.get("cargo_amount",0)) > 0:
		var cargo_type := str(unit.get("cargo_type",""))
		var cargo := Color("d8bd71") if cargo_type=="FOOD" else Color("bd92d4") if cargo_type=="ESSENCE" else Color("a7b3ad")
		_rect(image,11,top+7,4,4,cargo); _rect(image,15,top+9,3,3,cargo.lightened(0.12))


static func _horse(image: Image, color: Color, stride: int, bob: int) -> void:
	_rect(image,9,31+bob,29,8,INK);_rect(image,10,31+bob,26,6,color.darkened(0.15))
	_rect(image,33,24+bob,7,11,INK);_rect(image,34,25+bob,5,9,Color("a7855c"))
	_rect(image,36,24+bob,7,5,INK);_rect(image,37,25+bob,5,3,Color("bd9a69"))
	_rect(image,36,26+bob,1,1,LIGHT)
	for x: int in [11,17,29,35]: _rect(image,x+(stride if x<24 else -stride),37,3,7,INK)
	_line(image,Vector2(10,32),Vector2(6,39),INK,2)


static func _dragon(image: Image, team: Color, bob: int, stride: int, attack: bool, bucket: int) -> void:
	var wing := 5 if stride<0 else 0
	_poly(image,[Vector2(22,29+bob),Vector2(7,12-wing),Vector2(9,33+bob),Vector2(15,28+bob)],INK)
	_poly(image,[Vector2(21,29+bob),Vector2(9,16-wing),Vector2(11,30+bob),Vector2(15,26+bob)],Color("b66d47"))
	_poly(image,[Vector2(25,29+bob),Vector2(39,12-wing),Vector2(37,34+bob),Vector2(31,27+bob)],INK)
	_poly(image,[Vector2(25,29+bob),Vector2(37,16-wing),Vector2(35,30+bob),Vector2(31,26+bob)],Color("b66d47"))
	_rect(image,17,27+bob,15,13,INK);_rect(image,18,28+bob,12,11,Color("788c52"))
	_rect(image,22,32+bob,6,7,Color("c3b478"));_rect(image,26,20+bob,10,10,INK);_rect(image,27,21+bob,8,8,Color("8e9c5a"))
	_rect(image,34,24+bob,9,4,INK);_rect(image,34,24+bob,7,2,Color("a0a66a"));_rect(image,32,23+bob,2,1,Color("f4ca72"))
	_rect(image,20,28+bob,8,3,team)
	_line(image,Vector2(17,35+bob),Vector2(7,40),Color("788c52"),3)
	_rect(image,18,39,5,5,INK);_rect(image,28,39,5,5,INK)
	if attack and bucket==1: _rect(image,41,25+bob,5,4,Color("f3b65c"))


static func pixel_scale(radius: float) -> float:
	return maxf(radius/12.0*1.35,0.22) if is_finite(radius) and radius>0 else 0

static func _visual_unit(unit: Dictionary) -> Dictionary:
	if OutpostsV4.supported(unit): return unit
	if OutpostsV3.supported(unit): return unit
	if IdentityArt.supported(unit): return unit
	var source_type := str(unit.get("unit_type",""))
	if source_type in ["elder_treant","rune_behemoth"]:
		# Semantic author creatures: the tree giant must not be an enlarged
		# robed healer and the rune colossus must not look like a small shaman.
		# This is a local art projection only; no simulation hero/skill fields
		# are published or granted to these ordinary military units.
		var body := unit.duplicate()
		body["unit_type"] = "hero"
		body["hero_archetype"] = "VINE_WARDEN" if source_type=="elder_treant" else "COIL_WARDEN"
		body["essence_elite"] = true
		return body
	var record: Dictionary = Catalog.UNITS.get(str(unit.get("unit_type","")),{})
	var mapped := str(unit.get("visual_unit_type",record.get("visual_unit_type","")))
	if mapped.is_empty() or not Catalog.UNITS.has(mapped): return unit
	var visual := unit.duplicate()
	visual["unit_type"] = mapped
	visual["role"] = Catalog.UNITS[mapped].role
	visual["essence_elite"] = true
	return visual

static func _elite_scale(unit: Dictionary) -> float:
	if OutpostsV4.supported(unit): return 1.0
	if OutpostsV3.supported(unit): return 1.0
	if IdentityArt.supported(unit): return 1.0
	var type := str(unit.get("unit_type",""))
	return 1.5 if type in ["elder_treant","rune_behemoth"] else 1.25 if not str(Catalog.UNITS.get(type,{}).get("visual_unit_type","")).is_empty() else 1.0


const HERO_DISPLAY_SCALE_V5 := 1.18

static func hero_display_scale(unit: Dictionary) -> float:
	# Pure visual size. Elite proxies are military units, not hero officers.
	return HERO_DISPLAY_SCALE_V5 if unit.get("unit_type","")=="hero" and not bool(unit.get("essence_elite",false)) else 1.0

static func visual_bounds(unit: Dictionary, radius: float, pose: Dictionary = {}) -> Rect2:
	return _v4_visual_bounds(unit,radius*hero_display_scale(unit),pose)

static func _v4_visual_bounds(unit: Dictionary, radius: float, pose: Dictionary = {}) -> Rect2:
	if HeroPixelR8.supported(unit):return HeroPixelR8.visual_bounds(unit,radius,pose)
	if OutpostsV4.supported(unit,pose):return OutpostsV4.visual_bounds(unit,radius,pose)
	if OutpostsV3.supported(unit,pose):return OutpostsV3.visual_bounds(unit,radius,pose)
	if MageActors.supported(unit):return MageActors.visual_bounds(unit,radius,pose)
	if RangedActors.supported(unit):return RangedActors.visual_bounds(unit,radius,pose)
	if ExpansionActors.supported(unit):return ExpansionActors.visual_bounds(unit,radius,pose)
	if IdentityArt.supported(unit,pose): return IdentityArt.visual_bounds(unit,radius,pose)
	radius *= _elite_scale(unit)
	unit = _visual_unit(unit)
	if GeneratedUnits.supported(unit,pose): return GeneratedUnits.visual_bounds(unit,radius,pose)
	if unit.get("unit_type") != "worker" and CollectionUnits.supported(unit,pose): return CollectionUnits.visual_bounds(unit,radius,pose)
	var frame := _frame(unit,pose)
	var factor := pixel_scale(radius)
	return Rect2(Vector2(frame.rect.position)*factor,Vector2(frame.rect.size)*factor)


static func draw(canvas: Object, foot: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> void:
	_v4_draw(canvas,foot,unit,radius*hero_display_scale(unit),pose)

static func _v4_draw(canvas: Object, foot: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> void:
	if not foot.is_finite() or pixel_scale(radius)<=0: return
	if HeroPixelR8.supported(unit):HeroPixelR8.draw(canvas,foot,unit,radius,pose);return
	if OutpostsV4.supported(unit,pose):
		OutpostsV4.draw(canvas,foot,unit,radius,pose)
		FactionAV.draw_identity(canvas,foot,unit,radius,pose,_v4_stable_visual_bounds(unit,radius))
		return
	if OutpostsV3.supported(unit,pose):
		OutpostsV3.draw(canvas,foot,unit,radius,pose)
		FactionAV.draw_identity(canvas,foot,unit,radius,pose,_v4_stable_visual_bounds(unit,radius))
		return
	if MageActors.supported(unit):MageActors.draw(canvas,foot,unit,radius,pose);return
	if RangedActors.supported(unit):RangedActors.draw(canvas,foot,unit,radius,pose);return
	if ExpansionActors.supported(unit):ExpansionActors.draw(canvas,foot,unit,radius,pose);return
	if IdentityArt.supported(unit,pose):
		IdentityArt.draw(canvas,foot,unit,radius,pose)
		FactionAV.draw_identity(canvas,foot,unit,radius,pose,_v4_stable_visual_bounds(unit,radius))
		return
	var source_unit:=unit
	var source_radius:=radius
	radius *= _elite_scale(unit)
	unit = _visual_unit(unit)
	var drawn := false
	if GeneratedUnits.supported(unit,pose): drawn = GeneratedUnits.draw(canvas,foot,unit,radius,pose)
	elif unit.get("unit_type") != "worker": drawn = CollectionUnits.draw(canvas,foot,unit,radius,pose)
	if canvas is CanvasItem: canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if not drawn:
		var frame := _frame(unit,pose)
		var factor := pixel_scale(radius)
		var bounds := Rect2(Vector2(frame.rect.position)*factor,Vector2(frame.rect.size)*factor)
		canvas.draw_texture_rect(frame.texture,Rect2((foot+bounds.position).round(),bounds.size),false)
	if unit.get("essence_elite",false) and pose.get("action") != "FALLEN":
		var s := maxf(radius/12.0,0.1)
		for x: int in [-7,4]:
			canvas.draw_rect(Rect2((foot+Vector2(x,-24)*s).round(),Vector2(4,8)*s),Color("59466d"))
			canvas.draw_rect(Rect2((foot+Vector2(x+1,-25)*s).round(),Vector2(2,6)*s),Color("c8a9dd"))
	FactionAV.draw_identity(canvas,foot,source_unit,source_radius,pose,_v4_stable_visual_bounds(source_unit,source_radius))


static func body_contains(unit: Dictionary, radius: float, pose: Dictionary, offset: Vector2) -> bool:
	return _v4_body_contains(unit,radius*hero_display_scale(unit),pose,offset)

static func _v4_body_contains(unit: Dictionary, radius: float, pose: Dictionary, offset: Vector2) -> bool:
	if HeroPixelR8.supported(unit):return HeroPixelR8.body_contains(unit,radius,pose,offset)
	if OutpostsV4.supported(unit,pose):return OutpostsV4.body_contains(unit,radius,pose,offset)
	if OutpostsV3.supported(unit,pose):return OutpostsV3.body_contains(unit,radius,pose,offset)
	if MageActors.supported(unit):return MageActors.body_contains(unit,radius,pose,offset)
	if RangedActors.supported(unit):return RangedActors.body_contains(unit,radius,pose,offset)
	if ExpansionActors.supported(unit):return ExpansionActors.body_contains(unit,radius,pose,offset)
	if IdentityArt.supported(unit,pose): return IdentityArt.body_contains(unit,radius,pose,offset)
	radius *= _elite_scale(unit)
	unit = _visual_unit(unit)
	if GeneratedUnits.supported(unit,pose): return GeneratedUnits.body_contains(unit,radius,pose,offset)
	if unit.get("unit_type") != "worker" and CollectionUnits.supported(unit,pose): return CollectionUnits.body_contains(unit,radius,pose,offset)
	var factor := pixel_scale(radius)
	if factor<=0 or not offset.is_finite(): return false
	var frame := _frame(unit,pose)
	var point := Vector2i((offset/factor-Vector2(frame.rect.position)).floor())
	var image: Image = frame.image
	return Rect2i(Vector2i.ZERO,image.get_size()).has_point(point) and image.get_pixelv(point).a>0.1


static func inspect(unit: Dictionary, pose: Dictionary = {}) -> Dictionary:
	if HeroPixelR8.supported(unit):return HeroPixelR8.inspect(unit,pose)
	if OutpostsV4.supported(unit,pose):return OutpostsV4.inspect(unit,pose)
	if OutpostsV3.supported(unit,pose):return OutpostsV3.inspect(unit,pose)
	if MageActors.supported(unit):return MageActors.inspect(unit,pose)
	if RangedActors.supported(unit):return RangedActors.inspect(unit,pose)
	if ExpansionActors.supported(unit):return ExpansionActors.inspect(unit,pose)
	if IdentityArt.supported(unit,pose): return IdentityArt.inspect(unit,pose)
	var original := str(unit.get("unit_type",""))
	unit = _visual_unit(unit)
	if GeneratedUnits.supported(unit,pose): return GeneratedUnits.inspect(unit,pose)
	if unit.get("unit_type") != "worker" and CollectionUnits.supported(unit,pose): return CollectionUnits.inspect(unit,pose)
	var frame := _frame(unit,pose)
	var reason := GeneratedUnits.fallback_reason(unit) if GeneratedUnits.identity_for(unit) in GeneratedUnits.IDENTITIES else CollectionUnits.fallback_reason(unit)
	if original in OutpostsV4.IDS: reason="V4 atlas unavailable or rejected; original author fallback. "+str(OutpostsV4.status().failures)
	return {"key":frame.key,"category":frame.category,"action":frame.action,"frame":frame.bucket,"pixel_hash":frame.pixel_hash,"rect":frame.rect,"mirror":frame.mirror,"original_art":true,"licensed_art":false,"generated_art":false,"provenance":"original-pixel-civilian-m51" if original=="worker" else "original-pixel-fallback","civilian":original=="worker","faction_id":str(unit.get("faction_id","HUMAN")),"equipment":"work_tool_and_basket" if original=="worker" else "","fallback_reason":"Original faction civilian intentionally replaces armed Creature worker mapping." if original=="worker" else reason}


static func debug_stats() -> Dictionary:
	var bytes := 0
	for frame: Dictionary in _frames.values(): bytes+=(frame.image as Image).get_width()*(frame.image as Image).get_height()*4
	var licensed := CollectionUnits.debug_stats()
	var generated := GeneratedUnits.debug_stats()
	var identities := IdentityArt.debug_stats()
	var result:={"frames":_frames.size()+int(licensed.frames)+int(generated.frames)+int(identities.frames),"capacity":MAX_FRAMES+IdentityArt.MAX_FRAMES,"original_frames":_frames.size(),"original_capacity":MAX_ORIGINAL_FRAMES,"bakes":_bakes+int(licensed.bakes)+int(generated.bakes)+int(identities.bakes),"texture_bytes":bytes+int(licensed.texture_bytes)+int(generated.texture_bytes)+int(identities.texture_bytes),"maximum_texture_bytes":MAX_ORIGINAL_FRAMES*SIZE.x*SIZE.y*4+int(licensed.maximum_texture_bytes)+int(generated.maximum_texture_bytes)+int(identities.maximum_texture_bytes),"original_art":true,"licensed_cache":licensed,"generated_cache":generated,"identity_cache":identities,"owner_atlas_copies":0}
	var expansion:=ExpansionActors.debug_stats()
	for key:String in ["frames","bakes","texture_bytes","maximum_texture_bytes"]:result[key]=int(result.get(key,0))+int(expansion.get(key,0))
	result["m66_expansion_cache"]=expansion
	var outposts := OutpostsV3.debug_stats()
	for key:String in ["frames","bakes","texture_bytes","maximum_texture_bytes"]:result[key]=int(result.get(key,0))+int(outposts.get(key,0))
	result["capacity"]=int(result.capacity)+OutpostsV3.MAX_FRAMES
	result["outposts_v3_cache"]=outposts
	var outposts_v4 := OutpostsV4.debug_stats()
	for key:String in ["frames","bakes","texture_bytes","maximum_texture_bytes"]:result[key]=int(result.get(key,0))+int(outposts_v4.get(key,0))
	result["capacity"]=int(result.capacity)+OutpostsV4.MAX_FRAMES
	result["outposts_v4_cache"]=outposts_v4
	for module:Variant in [MageActors,RangedActors,HeroPixelR8]:
		var added:Dictionary=module.debug_stats()
		for key:String in ["frames","bakes","texture_bytes","maximum_texture_bytes"]:result[key]=int(result.get(key,0))+int(added.get(key,0))
	result["capacity"]=int(result.capacity)+HeroPixelR8.MAX_FRAMES
	result["hero_pixel_r8_cache"]=HeroPixelR8.debug_stats()
	var livery:=TeamMaterial.debug_stats()
	result["team_material_cache"]=livery
	result["texture_bytes"]=int(result.texture_bytes)+int(livery.rgba8_bytes)
	result["maximum_texture_bytes"]=int(result.maximum_texture_bytes)+int(livery.maximum_rgba8_bytes)
	return result


static func _m90_original_stable_visual_bounds(unit: Dictionary, radius: float) -> Rect2:
	if HeroPixelR8.supported(unit):return HeroPixelR8.stable_visual_bounds(unit,radius)
	if OutpostsV4.supported(unit):return OutpostsV4.stable_visual_bounds(unit,radius)
	if OutpostsV3.supported(unit):return OutpostsV3.stable_visual_bounds(unit,radius)
	if MageActors.supported(unit):return MageActors.stable_visual_bounds(unit,radius)
	if RangedActors.supported(unit):return RangedActors.stable_visual_bounds(unit,radius)
	if ExpansionActors.supported(unit):return ExpansionActors.stable_visual_bounds(unit,radius)
	return IdentityArt.stable_visual_bounds(unit,radius) if IdentityArt.supported(unit) else _v4_visual_bounds(unit,radius,{"action":"IDLE","direction":Vector2.RIGHT})


# Scope is exactly one synchronous Canvas draw. Never reuse an actor's stable
# geometry merely because an ID/tick matches a different observation or scale.
static var _m90_bounds_active := false
static var _m90_bounds_cache: Dictionary = {}
static var _m90_bounds_hits := 0
static var _m90_bounds_misses := 0

static func begin_draw_m90() -> void:
	_m90_bounds_cache.clear()
	_m90_bounds_hits = 0
	_m90_bounds_misses = 0
	_m90_bounds_active = true

static func end_draw_m90() -> void:
	_m90_bounds_active = false
	_m90_bounds_cache.clear()

static func stable_visual_bounds(unit: Dictionary, radius: float) -> Rect2:
	return _v4_stable_visual_bounds(unit,radius*hero_display_scale(unit))

static func _v4_stable_visual_bounds(unit: Dictionary, radius: float) -> Rect2:
	if not _m90_bounds_active: return _m90_original_stable_visual_bounds(unit,radius)
	var id := str(unit.get("id",""))
	if id.is_empty(): return _m90_original_stable_visual_bounds(unit,radius)
	var prior: Dictionary = _m90_bounds_cache.get(id,{})
	if not prior.is_empty():
		if is_same(prior.actor,unit) and float(prior.radius)==radius:
			_m90_bounds_hits += 1
			return prior.bounds
		# Same ID is not the same body or scale. Keep the original lookup.
		_m90_bounds_misses += 1
		return _m90_original_stable_visual_bounds(unit,radius)
	_m90_bounds_misses += 1
	var bounds := _m90_original_stable_visual_bounds(unit,radius)
	_m90_bounds_cache[id] = {"actor":unit,"radius":radius,"bounds":bounds}
	return bounds


static func ground_footprint(unit: Dictionary, radius: float) -> Vector2:
	return _v4_ground_footprint(unit,radius*hero_display_scale(unit))

static func _v4_ground_footprint(unit: Dictionary, radius: float) -> Vector2:
	if HeroPixelR8.supported(unit):return HeroPixelR8.ground_footprint(unit,radius)
	if OutpostsV4.supported(unit): return OutpostsV4.ground_footprint(unit,radius)
	if OutpostsV3.supported(unit): return OutpostsV3.ground_footprint(unit,radius)
	if MageActors.supported(unit):return MageActors.ground_footprint(unit,radius)
	if RangedActors.supported(unit):return RangedActors.ground_footprint(unit,radius)
	if ExpansionActors.supported(unit):return ExpansionActors.ground_footprint(unit,radius)
	if IdentityArt.supported(unit): return IdentityArt.ground_footprint(unit,radius)
	var bounds := _v4_stable_visual_bounds(unit,radius)
	return Vector2(maxf(radius*1.6,minf(bounds.size.x*0.75,radius*2.8)),radius*0.7)


static func _rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var rect := Rect2i(x,y,maxi(w,0),maxi(h,0)).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	if rect.size.x>0 and rect.size.y>0: image.fill_rect(rect,color)


static func _line(image: Image, from: Vector2, to: Vector2, color: Color, width: int = 1) -> void:
	var count := maxi(ceili(from.distance_to(to)),1)
	for i: int in range(count+1):
		var point := Vector2i(from.lerp(to,float(i)/count).round())
		_rect(image,point.x,point.y,width,width,color)


static func _poly(image: Image, vertices: Array[Vector2], color: Color) -> void:
	for y: int in range(SIZE.y):
		for x: int in range(SIZE.x):
			if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),PackedVector2Array(vertices)): image.set_pixel(x,y,color)
