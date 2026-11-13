extends RefCounted
## Original pixel-body author + verified offline atlas consumer. author_image
## is a build tool API: gameplay never calls it to bake a missing sprite.
const ROOT := "res://assets/art/original/outposts-v4-units/"
const PROVENANCE := "original-code-pixel-outposts-v4"
const PixelR8 = preload("res://src/presentation/heroic_troop_pixel_r8.gd")
const PIXEL_R8_SOURCE := "res://src/presentation/heroic_troop_pixel_r8.gd"
const IDS := ["seal_judicator","seal_veil_guard","grave_chain_guard","pall_lantern","induction_weaver","rail_kite","dew_thorn_scribe","canopy_glasswing","ridge_axe_guard","cinder_kiln_acolyte","resonance_driller","deep_fault_carapace","oath_colossus","soul_revenant","aether_engine","elder_treant","rune_behemoth","fire_dragon","abyss_devourer"]
const ELITE_IDS_R4 := ["oath_colossus","soul_revenant","aether_engine","elder_treant","rune_behemoth","fire_dragon","abyss_devourer"]
const ACTIONS := ["IDLE","WALK","ATTACK","HIT","FALLEN","CAST"]
const LEGACY_SPECS_R4 := {
	"seal_judicator":{"faction":"HUMAN","size":64,"anchor":Vector2i(32,60),"world_height":44,"nominal_radius":14,"footprint":[20,9],"silhouette":"split copper crest, square hanging seal, open folio"},
	"seal_veil_guard":{"faction":"HUMAN","size":64,"anchor":Vector2i(32,60),"world_height":50,"nominal_radius":16,"footprint":[25,11],"silhouette":"folded broad page-shield, domed copper helmet, low hammer"},
	"grave_chain_guard":{"faction":"UNDEAD","size":64,"anchor":Vector2i(32,60),"world_height":44,"nominal_radius":14,"footprint":[22,9],"silhouette":"hunched narrow skull, back name-slabs, long hook-chain"},
	"pall_lantern":{"faction":"UNDEAD","size":64,"anchor":Vector2i(32,60),"world_height":50,"nominal_radius":18,"footprint":[30,12],"silhouette":"skeletal flying boat, bone ribs, hanging memorial lantern"},
	"induction_weaver":{"faction":"MACHINE","size":64,"anchor":Vector2i(32,60),"world_height":46,"nominal_radius":15,"footprint":[26,12],"silhouette":"tripod chassis, open induction coil, side fork and pressure tank"},
	"rail_kite":{"faction":"MACHINE","size":64,"anchor":Vector2i(32,60),"world_height":44,"nominal_radius":16,"footprint":[30,11],"silhouette":"swept steel wings, twin engine booms, articulated general-purpose underslung turret"},
	"dew_thorn_scribe":{"faction":"FOREST","size":64,"anchor":Vector2i(32,60),"world_height":44,"nominal_radius":13,"footprint":[19,9],"silhouette":"asymmetric bud hood, dew vessel, forked live-wood staff"},
	"canopy_glasswing":{"faction":"FOREST","size":64,"anchor":Vector2i(32,60),"world_height":48,"nominal_radius":17,"footprint":[28,11],"silhouette":"four translucent leaf pinions, needle beak, seed-tail rudder"},
	"ridge_axe_guard":{"faction":"HIGHLAND","size":64,"anchor":Vector2i(32,60),"world_height":50,"nominal_radius":17,"footprint":[27,12],"silhouette":"wide fur-backed torso, double kiln axe, low horned helm"},
	"cinder_kiln_acolyte":{"faction":"HIGHLAND","size":64,"anchor":Vector2i(32,60),"world_height":46,"nominal_radius":14,"footprint":[22,10],"silhouette":"frost-brick backpack chimney, narrow hood, ember lamp staff"},
	"resonance_driller":{"faction":"UNDERGROUND","size":64,"anchor":Vector2i(32,60),"world_height":42,"nominal_radius":14,"footprint":[26,12],"silhouette":"six jointed legs, offset shell, triple tuning-fork mandibles"},
	"deep_fault_carapace":{"faction":"UNDERGROUND","size":96,"anchor":Vector2i(48,88),"world_height":76,"nominal_radius":28,"footprint":[52,20],"silhouette":"low eight-legged shale carapace, stepped plates, forward fault horn"},
	# The frame gains source detail, not world scale: these seven retain the
	# predecessor's world_height/radius/footprint contracts. A96px author is
	# compiled once; no old32px body is enlarged into a new military identity.
	"oath_colossus":{"faction":"HUMAN","size":96,"anchor":Vector2i(48,88),"world_height":64,"nominal_radius":20,"footprint":[30,12],"silhouette":"planted pavise, geared great-crossbow, copper kettle helm and quilted gunner coat"},
	"soul_revenant":{"faction":"UNDEAD","size":96,"anchor":Vector2i(48,88),"world_height":64,"nominal_radius":20,"footprint":[30,12],"silhouette":"arched ossuary shoulders, open rib furnace, slab fists and broken memorial crown"},
	"aether_engine":{"faction":"MACHINE","size":96,"anchor":Vector2i(48,88),"world_height":64,"nominal_radius":22,"footprint":[30,12],"silhouette":"low twin continuous tracks, long stepped rail barrel, exposed flywheel and offset boiler"},
	"elder_treant":{"faction":"FOREST","size":96,"anchor":Vector2i(48,88),"world_height":64,"nominal_radius":20,"footprint":[30,12],"silhouette":"four splayed buttress roots, hollow willow trunk, asymmetric leafy limbs and bark ward"},
	"rune_behemoth":{"faction":"HIGHLAND","size":96,"anchor":Vector2i(48,88),"world_height":64,"nominal_radius":20,"footprint":[30,12],"silhouette":"hunched four-legged stone bison, heavy forehooves, hooked ivory tusks and dorsal rune slabs"},
	"fire_dragon":{"faction":"HIGHLAND","size":96,"anchor":Vector2i(48,88),"world_height":65,"nominal_radius":26,"footprint":[24,9],"silhouette":"long curled tail, articulated bat wings, plated ember belly and forward horned drake head"},
	"abyss_devourer":{"faction":"UNDERGROUND","size":96,"anchor":Vector2i(48,88),"world_height":64,"nominal_radius":20,"footprint":[30,12],"silhouette":"smooth low double backplate, four thick load-bearing legs, forward armoured pincers and low broad split jaw"},
}
const RAMPS := {
	"HUMAN":["443f3b","87705a","c5aa75","e8d7a9","8eb5ba"],
	"UNDEAD":["3e3548","726171","ada18c","dfd6b4","85aa95"],
	"MACHINE":["35414a","667984","a2abb0","d4d2ba","d59456"],
	"FOREST":["304539","647b51","a4b77b","dfd9a0","97c0b9"],
	"HIGHLAND":["3d3946","736575","aaa0a0","d8cdb0","c98252"],
	"UNDERGROUND":["393143","685374","a08b9f","d2c6ac","a9bc75"],
}
static var SPECS: Dictionary = _pixel_specs_r8()

static func _pixel_specs_r8() -> Dictionary:
	# Retain world size/footprint while matching the licensed art's pixel density.
	# These are new 32-cell masters, not a resampling of the preserved R4 sheets.
	var specs := LEGACY_SPECS_R4.duplicate(true)
	for id: String in IDS:
		specs[id].size = 32
		specs[id].anchor = Vector2i(16,29)
	return specs
const INK := Color("171820")
const TEAM_BLUE := Color("4276bf")
const MAX_FRAMES := 128
const TeamMaterial = preload("res://src/presentation/heroic_team_material_m70.gd")
static var _attempted := false
static var _sheets: Dictionary = {}
static var _records: Dictionary = {}
static var _frames: Dictionary = {}
static var _order: Array[String] = []
static var _failures: Array[String] = []
static var _bakes := 0

static func reset_cache() -> void:
	_attempted=false;_sheets.clear();_records.clear();_frames.clear();_order.clear();_failures.clear();_bakes=0

static func _digest(im: Image) -> String:
	var h := HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(im.get_data());return h.finish().hex_encode()

static func _r(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var rect := Rect2i(x,y,w,h).intersection(Rect2i(Vector2i.ZERO,im.get_size()))
	if rect.has_area(): im.fill_rect(rect,c)

static func _p(im: Image, points: Array, c: Color) -> void:
	var poly := PackedVector2Array(points)
	var bounds := Rect2(poly[0],Vector2.ZERO)
	for point: Vector2 in poly: bounds=bounds.expand(point)
	var rect := Rect2i(bounds).grow(1).intersection(Rect2i(2,2,im.get_width()-4,im.get_height()-4))
	for y: int in range(rect.position.y,rect.end.y):
		for x: int in range(rect.position.x,rect.end.x):
			if Geometry2D.is_point_in_polygon(Vector2(x,y),poly): im.set_pixel(x,y,c)

static func _l(im: Image, a: Vector2i, b: Vector2i, c: Color, width: int = 2) -> void:
	var n := maxi(absi(b.x-a.x),absi(b.y-a.y))
	for i: int in range(n+1):
		var p := Vector2i(Vector2(a).lerp(Vector2(b),float(i)/maxi(n,1)).round())
		_r(im,p.x-width/2,p.y-width/2,width,width,c)

static func _rim(im: Image) -> void:
	var source := im.duplicate() as Image
	for y: int in range(2,im.get_height()-2):
		for x: int in range(2,im.get_width()-2):
			if source.get_pixel(x,y).a<0.5: continue
			for off: Vector2i in [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
				if source.get_pixelv(Vector2i(x,y)+off).a<0.5: im.set_pixelv(Vector2i(x,y)+off,INK)

static func _person(im: Image, k: int, bob: int, lean: int, d: Color, b: Color, h: Color, robe: bool, wide: bool = false) -> void:
	var w := 3 if wide else 0
	var stride := int([-3,0,3,0][k])
	if robe:
		_p(im,[Vector2(23-w+lean,29+bob),Vector2(38+w+lean,29+bob),Vector2(44+w+stride/2,55),Vector2(34-stride/2,57),Vector2(30,52),Vector2(19-w-stride/2,57)],d)
		_p(im,[Vector2(27+lean,32+bob),Vector2(34+lean,31+bob),Vector2(38+stride/2,52),Vector2(27-stride/2,54)],b)
		# Walking articulates hem, boot positions and fold direction; it is
		# not a translated idle body. The same fixed sheet foot remains60.
		_r(im,23-stride,56,6,3,d);_r(im,35+stride,56,6,3,d)
		_r(im,24-stride,56,4,1,b);_r(im,36+stride,56,4,1,b)
		_l(im,Vector2i(24+lean,38+bob),Vector2i(23-stride/2,51),d,1)
		_l(im,Vector2i(36+lean,35+bob),Vector2i(38+stride/2,50),h,1)
		_r(im,28+lean,35+bob,5,13,TEAM_BLUE)
		_r(im,28+lean,35+bob,1,11,b);_r(im,29+lean,48+bob,4,1,h)
	else:
		_l(im,Vector2i(26,45),Vector2i(23-stride,57),d,7);_l(im,Vector2i(36,45),Vector2i(39+stride,57),d,7)
		_r(im,18-stride,56,10,3,b);_r(im,35+stride,56,10,3,b)
		_p(im,[Vector2(21-w+lean,28+bob),Vector2(40+w+lean,28+bob),Vector2(42+w+lean,43+bob),Vector2(35,49),Vector2(24,46)],b)
		_r(im,23+lean,34+bob,16,7,TEAM_BLUE);_r(im,25+lean,42+bob,12,3,d)
		for x: int in [25,36]: _r(im,x+lean,32+bob,1,1,h)
		_r(im,26+lean,43+bob,8,1,h);_r(im,23+lean,35+bob,1,5,b)
	_r(im,26+lean,17+bob,12,12,h);_r(im,31+lean,22+bob,8,3,INK)
	_r(im,27+lean,27+bob,9,3,b)

static func _fallen_body_v4(im: Image, id: String, k: int, d: Color, b: Color, h: Color, pale: Color, a: Color) -> void:
	# Separate authored impact/kneel/sidefall/rest poses. Nothing here scales,
	# rotates or compresses a standing raster into an indistinct flat smear.
	if id in ["seal_judicator","seal_veil_guard","grave_chain_guard","dew_thorn_scribe","ridge_axe_guard","cinder_kiln_acolyte"]:
		var y := int([33,40,46,49][k]);var head_x := int([38,43,46,48][k])
		_l(im,Vector2i(28,y+6),Vector2i(18-k,55),d,6);_l(im,Vector2i(30,y+6),Vector2i(32-k*2,57),b,5)
		_r(im,12-k,56,10,3,d);_r(im,25-k*2,56,10,3,b)
		_p(im,[Vector2(19,y+1),Vector2(33,y-4),Vector2(43,y+1),Vector2(40,y+8),Vector2(23,y+9)],b)
		_p(im,[Vector2(23,y+2),Vector2(35,y-1),Vector2(39,y+3),Vector2(27,y+6)],h)
		_l(im,Vector2i(21,y+5),Vector2i(39,y+6),d,1)
		_l(im,Vector2i(35,y+2),Vector2i(head_x-1,y+8),d,4)
		_r(im,head_x,y-5+k,9,7,pale);_r(im,head_x+3,y-3+k,6,2,INK)
		match id:
			"seal_judicator":
				_p(im,[Vector2(head_x-2,y-6+k),Vector2(head_x+2,y-12+k),Vector2(head_x+5,y-8+k),Vector2(head_x+10,y-10+k),Vector2(head_x+10,y-4+k)],h)
				_p(im,[Vector2(6,50),Vector2(12,47+k),Vector2(20,50),Vector2(21,56),Vector2(13,54),Vector2(7,57)],pale)
				_r(im,12,50,1,5,b);_r(im,43,54,9,3,h);_r(im,46,53,3,2,a)
			"seal_veil_guard":
				var shield_y := int([31,38,46,49][k])
				_p(im,[Vector2(9,shield_y),Vector2(18,shield_y-3),Vector2(30,shield_y+1),Vector2(28,57),Vector2(15,58),Vector2(8,53)],d)
				_p(im,[Vector2(11,shield_y+2),Vector2(19,shield_y),Vector2(27,shield_y+3),Vector2(25,55),Vector2(15,55)],h)
				_l(im,Vector2i(18,shield_y+1),Vector2i(19,55),b,1)
				_r(im,head_x-1,y-7+k,11,4,h);_l(im,Vector2i(42,57),Vector2i(55,52),b,3);_r(im,51,49,8,5,h)
			"grave_chain_guard":
				for i: int in range(3): _r(im,23+i*5,y-3,3,6,pale)
				for i: int in range(5): _r(im,39+i*4,55-i%2,2,2,h)
				_l(im,Vector2i(56,54),Vector2i(56,44+k*2),pale,2);_l(im,Vector2i(56,44+k*2),Vector2i(51,44+k*2),pale,2)
			"dew_thorn_scribe":
				_p(im,[Vector2(head_x-2,y-4+k),Vector2(head_x-1,y-10+k),Vector2(head_x+4,y-7+k),Vector2(head_x+8,y-11+k),Vector2(head_x+11,y-4+k)],b)
				_l(im,Vector2i(12,58),Vector2i(56,51+k),b,3);_p(im,[Vector2(50,50+k),Vector2(54,45+k),Vector2(58,50+k)],a)
				_r(im,10,48+k,7,7,h);_r(im,12,50+k,3,3,a)
			"ridge_axe_guard":
				_r(im,head_x-2,y-8+k,12,5,d);_r(im,head_x,y-7+k,9,2,h)
				_l(im,Vector2i(25,56),Vector2i(52,49+k),b,3)
				_p(im,[Vector2(47,48+k),Vector2(43,44+k),Vector2(43,54),Vector2(52,55),Vector2(58,51+k),Vector2(56,46+k)],h)
				_r(im,23,y-2,13,3,pale);_r(im,49,50+k,3,2,a)
			"cinder_kiln_acolyte":
				_r(im,17,39+k*3,11,14-k,d);_r(im,19,41+k*3,7,9-k,b)
				_r(im,17,34+k*5,5,8,h);_r(im,18,35+k*5,3,2,d)
				_l(im,Vector2i(34,58),Vector2i(56,53),h,2);_r(im,52,49,7,7,d);_r(im,54,51,3,3,a)
		return
	match id:
		"pall_lantern":
			var y := 43+k*3
			_p(im,[Vector2(9,y),Vector2(47,y-3),Vector2(56,y+2),Vector2(45,58),Vector2(19,57),Vector2(11,y+7)],d)
			_p(im,[Vector2(13,y+1),Vector2(44,y),Vector2(48,55),Vector2(20,55)],b)
			for x: int in [18,26,34,42]: _l(im,Vector2i(x,y),Vector2i(x+3,55),h,2)
			_l(im,Vector2i(31,y),Vector2i(20+k*6,20+k*9),h,3)
			_p(im,[Vector2(20+k*6,22+k*9),Vector2(12+k*3,31+k*6),Vector2(19+k*3,42+k*3),Vector2(28+k*5,38+k*5)],b)
			_r(im,43,45+k,8,9,d);_r(im,45,47+k,4,5,a);_l(im,Vector2i(14,54),Vector2i(6,57),h,2)
		"induction_weaver":
			var y := 41+k*3
			for i: int in range(3):
				var x := int([15,31,47][i]);_l(im,Vector2i(31,y),Vector2i(x,51),d,5);_l(im,Vector2i(x,51),Vector2i(x+(i-1)*(k+2),57),h,3)
			_p(im,[Vector2(19,y-2),Vector2(38,y-5),Vector2(46,y+2),Vector2(38,56),Vector2(21,55)],b)
			_r(im,23,y+2,12,3,h);_r(im,24,y+4,9,2,d)
			_l(im,Vector2i(24,y),Vector2i(28+k*4,24+k*7),h,4);_l(im,Vector2i(40,y),Vector2i(43+k*3,29+k*5),h,4)
			_l(im,Vector2i(28+k*4,24+k*7),Vector2i(43+k*3,29+k*5),a,2)
		"rail_kite":
			_p(im,[Vector2(27,40+k*3),Vector2(7,20+k*8),Vector2(9,36+k*5),Vector2(28,55)],b)
			_p(im,[Vector2(32,38+k*4),Vector2(54,24+k*7),Vector2(57,39+k*5),Vector2(37,57)],h)
			_l(im,Vector2i(10,31+k*5),Vector2i(26,51),d,2);_l(im,Vector2i(38,53),Vector2i(53,34+k*6),d,2)
			_p(im,[Vector2(27,34+k*5),Vector2(37,37+k*4),Vector2(44,51),Vector2(36,58),Vector2(26,53)],d)
			_r(im,28,44+k*2,8,4,b);_r(im,17,46+k,6,10,b);_r(im,45,47+k,6,9,b)
			_r(im,18,49+k,3,2,a);_r(im,46,50+k,3,2,a)
		"canopy_glasswing":
			for sign: int in [-1,1]:
				_p(im,[Vector2(31,39+k*4),Vector2(31+sign*21,22+k*8),Vector2(31+sign*24,39+k*5),Vector2(31+sign*9,56)],b)
				_l(im,Vector2i(31+sign*2,47+k*2),Vector2i(31+sign*18,32+k*6),a,2)
			_p(im,[Vector2(23,38+k*4),Vector2(34,40+k*3),Vector2(42,52),Vector2(35,58),Vector2(23,55)],d)
			_r(im,37,44+k*2,9,6,h);_p(im,[Vector2(45,47+k*2),Vector2(57,53),Vector2(45,53+k)],pale)
			_l(im,Vector2i(25,55),Vector2i(16-k,57),h,2);_l(im,Vector2i(28,56),Vector2i(37+k,58),b,2)
		"resonance_driller":
			for i: int in range(3):
				for sign: int in [-1,1]:
					var x := 22+i*8;_l(im,Vector2i(x,46+k*2),Vector2i(x+sign*10,51),d,3);_l(im,Vector2i(x+sign*10,51),Vector2i(x+sign*13+sign*k,57),h,2)
			_p(im,[Vector2(16,39+k*4),Vector2(28,32+k*6),Vector2(43,40+k*4),Vector2(44,53),Vector2(29,58),Vector2(17,52)],b)
			_p(im,[Vector2(21,41+k*3),Vector2(29,37+k*4),Vector2(38,43+k*2),Vector2(32,52)],h)
			for i: int in range(3): _l(im,Vector2i(40,47+i*3),Vector2i(55-i,48+i*3+k),h,2)
			_r(im,48,50+k,6,2,a)
		"deep_fault_carapace":
			for i: int in range(4):
				for sign: int in [-1,1]:
					var x := 29+i*11;_l(im,Vector2i(x,69+k*3),Vector2i(x+sign*12,78),d,6);_l(im,Vector2i(x+sign*12,78),Vector2i(x+sign*(17+k),85),h,3)
			_p(im,[Vector2(16,57+k*4),Vector2(31,45+k*6),Vector2(56,47+k*6),Vector2(76,60+k*4),Vector2(79,78),Vector2(58,85),Vector2(25,82)],d)
			_p(im,[Vector2(23,60+k*3),Vector2(36,51+k*5),Vector2(58,54+k*4),Vector2(70,67+k*3),Vector2(60,79),Vector2(30,77)],b)
			for i: int in range(4):
				var x := 28+i*10;var y := 56+k*4+absi(i-2)*2
				_p(im,[Vector2(x,y),Vector2(x+7,y-2),Vector2(x+12,y+9),Vector2(x+4,y+12)],h);_l(im,Vector2i(x+4,y+1),Vector2i(x+8,y+8),d,1)
			_p(im,[Vector2(72,63+k*3),Vector2(86,65+k*3),Vector2(89,76),Vector2(77,83),Vector2(70,77)],h)
			_l(im,Vector2i(80,67+k*3),Vector2i(88,53+k*7),pale,3);_r(im,79,74+k,7,3,d)

static func _elite_fallen_r4(im: Image, id: String, k: int, d: Color, b: Color, h: Color, pale: Color, a: Color) -> void:
	# Four drawn collapses share the same ground anchor. These are not idle
	# rasters rotated/squashed into corpses; weapon, limb and wing joints fold.
	var y := int([51,60,67,71][k])
	match id:
		"oath_colossus":
			_l(im,Vector2i(37,y+6),Vector2i(24,84),d,10);_l(im,Vector2i(46,y+7),Vector2i(50,85),b,9)
			_p(im,[Vector2(25,y-4),Vector2(44,y-8),Vector2(62,y),Vector2(56,y+11),Vector2(34,y+13)],b)
			_p(im,[Vector2(34,y-3),Vector2(47,y-5),Vector2(55,y+2),Vector2(43,y+7)],TEAM_BLUE)
			_r(im,58,y-4,13,10,h);_r(im,58,y+1,15,3,d);_r(im,61,y+5,8,3,pale)
			_p(im,[Vector2(10,y+2),Vector2(20,y-2),Vector2(31,y+6),Vector2(28,84),Vector2(14,85),Vector2(8,79)],h)
			_l(im,Vector2i(15,82),Vector2i(80,73+k*2),b,5);_l(im,Vector2i(62,63+k*4),Vector2i(63,84),h,4)
			_l(im,Vector2i(48,73+k*2),Vector2i(63,68+k*3),pale,2);_l(im,Vector2i(63,68+k*3),Vector2i(80,73+k*2),pale,2)
		"soul_revenant":
			_l(im,Vector2i(34,y+10),Vector2i(22,84),d,10);_l(im,Vector2i(54,y+10),Vector2i(62,85),b,9)
			_p(im,[Vector2(20,y),Vector2(33,y-9),Vector2(56,y-6),Vector2(72,y+3),Vector2(63,y+13),Vector2(27,y+13)],d)
			for i: int in range(4):
				_l(im,Vector2i(33+i*6,y-5),Vector2i(40+i*5,y+9),h,3)
			_l(im,Vector2i(21,y+3),Vector2i(10,80),b,12);_l(im,Vector2i(64,y+5),Vector2i(80,82),h,10)
			_r(im,55,y-13+k,14,11,pale);_r(im,60,y-8+k,10,3,d);_r(im,47,y+7,12,5,TEAM_BLUE)
			_p(im,[Vector2(22,y-4),Vector2(17,y-17+k*2),Vector2(28,y-10),Vector2(38,y-12)],h)
		"aether_engine":
			_p(im,[Vector2(13,68),Vector2(61,63),Vector2(78,74),Vector2(70,84),Vector2(19,85),Vector2(10,78)],d)
			for x: int in range(18,69,10): _r(im,x,76,6,6,b);_r(im,x+1,77,3,3,h)
			_p(im,[Vector2(18,y-2),Vector2(48,y-8),Vector2(68,y+1),Vector2(63,75),Vector2(24,79)],b)
			_p(im,[Vector2(28,y-4),Vector2(46,y-6),Vector2(55,y+1),Vector2(37,y+6)],TEAM_BLUE)
			_l(im,Vector2i(46,y),Vector2i(83,62+k*5),h,9);_l(im,Vector2i(48,y-2),Vector2i(81,59+k*5),pale,2)
			_r(im,17,y-12,10,14,d);_r(im,19,y-10,6,9,a);_r(im,24,66,7,8,h)
		"elder_treant":
			for i: int in range(4): _l(im,Vector2i(36+i*5,y+5),Vector2i(13+i*18,84),d,7)
			_p(im,[Vector2(27,y-7),Vector2(44,y-13),Vector2(62,y-2),Vector2(65,y+10),Vector2(47,82),Vector2(28,79)],b)
			_p(im,[Vector2(37,y-5),Vector2(47,y-8),Vector2(57,y),Vector2(47,y+8)],d)
			_l(im,Vector2i(30,y-1),Vector2i(12,y-7+k*4),h,7);_l(im,Vector2i(60,y+1),Vector2i(80,y+6+k*2),b,7)
			for i: int in range(5):
				var x := 16+i*13;var ly := y-12+absi(i-2)*3+k
				_p(im,[Vector2(x-5,ly),Vector2(x,ly-5),Vector2(x+10,ly-2),Vector2(x+11,ly+4),Vector2(x+2,ly+7)],h)
			_r(im,46,y+10,12,5,TEAM_BLUE);_l(im,Vector2i(36,y+1),Vector2i(33,79),d,1)
		"rune_behemoth":
			for x: int in [24,39,58,72]: _l(im,Vector2i(x,y+2),Vector2i(x+(2 if x<48 else -2),84),d,10)
			_p(im,[Vector2(17,y-3),Vector2(31,y-13),Vector2(57,y-11),Vector2(74,y-1),Vector2(77,78),Vector2(31,82),Vector2(17,72)],b)
			for i: int in range(3):
				var x := 29+i*10;_p(im,[Vector2(x,y-13),Vector2(x+5,y-21+k*2),Vector2(x+11,y-8)],h)
			_p(im,[Vector2(64,y-4),Vector2(79,y-7),Vector2(87,y+4),Vector2(83,80),Vector2(69,81)],h)
			_l(im,Vector2i(75,y+4),Vector2i(87,y-2+k*2),pale,4);_r(im,29,y,19,5,TEAM_BLUE)
		"fire_dragon":
			_l(im,Vector2i(48,y+2),Vector2i(25,79),d,12);_l(im,Vector2i(27,78),Vector2i(8,82),b,5)
			_p(im,[Vector2(24,y),Vector2(29,y-19+k*3),Vector2(40,y-28+k*5),Vector2(45,y-7),Vector2(52,y+7)],h)
			_p(im,[Vector2(48,y),Vector2(64,y-17+k*3),Vector2(75,y-22+k*4),Vector2(68,y-1),Vector2(60,y+12)],b)
			_l(im,Vector2i(35,y-17+k*3),Vector2i(42,y-3),d,2);_l(im,Vector2i(65,y-13+k*3),Vector2i(56,y+5),d,2)
			_p(im,[Vector2(29,y-2),Vector2(49,y-9),Vector2(69,y-1),Vector2(66,y+12),Vector2(40,y+15)],b)
			_l(im,Vector2i(62,y+3),Vector2i(76,76),h,10);_p(im,[Vector2(74,70),Vector2(87,74),Vector2(85,82),Vector2(73,83)],h)
			_r(im,44,y+2,14,5,TEAM_BLUE);_l(im,Vector2i(35,81),Vector2i(30,85),pale,3)
		"abyss_devourer":
			# The four thick knees buckle inward; the two independent pincers
			# fold on top of the smooth plate instead of reverting to a spider.
			for i: int in range(4):
				var x := int([21,35,53,66][i]);var off := 4 if i%2 else -4
				_l(im,Vector2i(x,y+3),Vector2i(x+off,80),d,9);_r(im,x+off-4,80,10,5,b)
			_p(im,[Vector2(13,y-2),Vector2(24,y-14),Vector2(43,y-17+k*2),Vector2(62,y-7),Vector2(69,y+6),Vector2(58,80),Vector2(28,83),Vector2(13,75)],d)
			_p(im,[Vector2(18,y-2),Vector2(28,y-10),Vector2(44,y-12+k*2),Vector2(59,y-4),Vector2(62,y+5),Vector2(48,y+10),Vector2(27,y+8)],b)
			_l(im,Vector2i(25,y-5),Vector2i(47,y-5),h,1);_l(im,Vector2i(29,y+2),Vector2i(52,y+5),d,1)
			_p(im,[Vector2(46,y+1),Vector2(59,y-3),Vector2(73,y+5),Vector2(70,77),Vector2(58,81),Vector2(47,y+10)],h)
			_l(im,Vector2i(54,y+3),Vector2i(77,76),b,9);_l(im,Vector2i(40,y+7),Vector2i(67,82),d,9)
			_p(im,[Vector2(72,72),Vector2(82,74),Vector2(87,82),Vector2(80,85),Vector2(76,79),Vector2(70,77)],h)
			_p(im,[Vector2(62,77),Vector2(75,79),Vector2(80,84),Vector2(66,85),Vector2(61,82)],b)
			_r(im,26,y+4,11,5,TEAM_BLUE);_r(im,63,y+6,6,2,a)

static func _elite_body_r4(im: Image, id: String, row: int, k: int, d: Color, b: Color, h: Color, pale: Color, a: Color) -> void:
	if row==4:
		_elite_fallen_r4(im,id,k,d,b,h,pale,a)
		return
	var bob := int([0,-1,0,1][k]) if row==0 else int([0,-1,0,-1][k]) if row==1 else 0
	var stride := int([-3,0,3,0][k]) if row==1 else 0
	var lean := int([-2,-4,3,1][k]) if row==2 else int([-3,3,-1,0][k]) if row==3 else 0
	var reach := int([0,-3,10,4][k]) if row==2 else int([0,3,7,2][k]) if row==5 else 0
	var cast_lift := int([0,4,9,3][k]) if row==5 else 0
	match id:
		"oath_colossus":
			# The great-crossbow remains a gunner, not the historical giant.
			# Back pavise, cog housing and hands form a readable firing chain.
			_l(im,Vector2i(39,65),Vector2i(32-stride,84),d,10);_l(im,Vector2i(53,65),Vector2i(59+stride,84),b,10)
			_r(im,25-stride,83,13,3,h);_r(im,54+stride,83,13,3,d)
			_p(im,[Vector2(28+lean,39+bob),Vector2(51+lean,34+bob),Vector2(62+lean,48+bob),Vector2(59,68),Vector2(45,75),Vector2(29,68)],b)
			_p(im,[Vector2(37+lean,40+bob),Vector2(49+lean,38+bob),Vector2(55,63),Vector2(43,67),Vector2(35,61)],TEAM_BLUE)
			for y: int in [49,56,63]: _l(im,Vector2i(35+lean,y+bob),Vector2i(51+lean,y-3+bob),d,1)
			_p(im,[Vector2(33+lean,28+bob),Vector2(35+lean,17+bob),Vector2(47+lean,13+bob),Vector2(57+lean,20+bob),Vector2(58+lean,29+bob)],h)
			_l(im,Vector2i(29+lean,28+bob),Vector2i(62+lean,28+bob),d,4);_r(im,39+lean,30+bob,16,11,pale);_r(im,46+lean,32+bob,10,3,d)
			_r(im,38+lean,18+bob,1,7,pale);_r(im,54+lean,21+bob,2,5,b)
			_p(im,[Vector2(9,40+bob),Vector2(20,35+bob),Vector2(31,43+bob),Vector2(28,77),Vector2(16,82),Vector2(8,73)],h)
			_p(im,[Vector2(12,44+bob),Vector2(20,41+bob),Vector2(27,46+bob),Vector2(24,73),Vector2(16,77),Vector2(11,71)],d)
			_r(im,15,48+bob,9,19,TEAM_BLUE);_l(im,Vector2i(19,51+bob),Vector2i(19,66+bob),pale,2)
			var cx := 64+reach/3;var cy := 51+bob-cast_lift/3
			_l(im,Vector2i(49+lean,47+bob),Vector2i(cx-10,cy+8),d,7);_r(im,cx-11,cy+5,8,6,pale)
			_l(im,Vector2i(35,cy+4),Vector2i(85,cy-3),b,7);_l(im,Vector2i(39,cy+2),Vector2i(84,cy-5),h,2)
			_p(im,[Vector2(cx-5,cy-22),Vector2(cx+1,cy-18),Vector2(cx+5,cy),Vector2(cx-2,cy+23),Vector2(cx-8,cy+27),Vector2(cx-5,cy+5)],h)
			_l(im,Vector2i(cx-4,cy-20),Vector2i(cx-13,cy+3),pale,1);_l(im,Vector2i(cx-13,cy+3),Vector2i(cx-7,cy+24),pale,1)
			_r(im,37,cy+7,8,9,d);_r(im,39,cy+9,4,4,h);_r(im,40,cy+10,2,2,a)
			_l(im,Vector2i(53,cy+4),Vector2i(54,cy+13+(4 if row==5 else 0)),h,3)
		"soul_revenant":
			# Empty ossuary, not a large recoloured skeleton swordsman.
			for sign: int in [-1,1]:
				_l(im,Vector2i(46+sign*11,66),Vector2i(46+sign*(18+stride),82),d,12)
				_p(im,[Vector2(46+sign*(14+stride),76),Vector2(46+sign*(24+stride),80),Vector2(46+sign*(26+stride),85),Vector2(46+sign*(12+stride),85)],h)
			_p(im,[Vector2(20+lean,33+bob),Vector2(33+lean,22+bob),Vector2(57+lean,22+bob),Vector2(70+lean,35+bob),Vector2(64,65),Vector2(47,75),Vector2(29,67)],d)
			_p(im,[Vector2(29+lean,34+bob),Vector2(45+lean,28+bob),Vector2(60+lean,37+bob),Vector2(56,61),Vector2(43,67),Vector2(32,58)],b)
			_p(im,[Vector2(36+lean,35+bob),Vector2(53+lean,34+bob),Vector2(55,54),Vector2(45,62),Vector2(35,53)],INK)
			for i: int in range(4):
				var y := 38+i*6+bob;_l(im,Vector2i(31+lean,y-1),Vector2i(42+lean,y+3),h,3);_l(im,Vector2i(58+lean,y-1),Vector2i(49+lean,y+3),pale,3)
			_r(im,42+lean,43+bob-cast_lift/3,6,9,a);_r(im,44+lean,44+bob-cast_lift/3,2,6,pale)
			for sign: int in [-1,1]:
				var hand_y := 63+bob-reach-cast_lift;var hx := 46+sign*(29+reach/4)
				_l(im,Vector2i(46+sign*21+lean,34+bob),Vector2i(hx,50+bob-cast_lift),b,11)
				_p(im,[Vector2(hx-6,hand_y-4),Vector2(hx+5,hand_y-7),Vector2(hx+9,hand_y+7),Vector2(hx-4,hand_y+11)],h)
				_l(im,Vector2i(hx-3,hand_y-1),Vector2i(hx+4,hand_y+6),d,1)
				_p(im,[Vector2(46+sign*12+lean,26+bob),Vector2(46+sign*24+lean,12+bob),Vector2(46+sign*29+lean,31+bob),Vector2(46+sign*18+lean,38+bob)],h)
			_r(im,38+lean,15+bob,16,17,pale);_p(im,[Vector2(37+lean,15+bob),Vector2(38+lean,8+bob),Vector2(43+lean,13+bob),Vector2(47+lean,6+bob),Vector2(53+lean,13+bob),Vector2(57+lean,10+bob),Vector2(55+lean,18+bob)],b)
			_r(im,41+lean,23+bob,4,4,d);_r(im,49+lean,22+bob,5,4,d);_r(im,45+lean,30+bob,8,2,d)
			_p(im,[Vector2(31,61),Vector2(43,65),Vector2(41,77),Vector2(29,74)],TEAM_BLUE);_p(im,[Vector2(49,65),Vector2(60,61),Vector2(64,74),Vector2(51,78)],TEAM_BLUE)
		"aether_engine":
			# Independent tread movement, rail recoil and open charging yoke.
			for side: int in [0,1]:
				var ty := 72+side*8;var tx := 15+side*3
				_p(im,[Vector2(tx,ty-7),Vector2(66,ty-9),Vector2(78,ty-2),Vector2(75,ty+5),Vector2(tx+4,ty+7),Vector2(tx-4,ty+1)],d)
				for i: int in range(6):
					var x := tx+4+i*8;_r(im,x,ty-3,5,5,b);_r(im,x+1,ty-2,2,2,h)
				for i: int in range(9): _r(im,tx+i*6+(posmod(k,2) if row==1 else 0),ty+4,3,2,h)
			_p(im,[Vector2(17,57+bob),Vector2(40,47+bob),Vector2(67,53+bob),Vector2(77,67+bob),Vector2(58,77+bob),Vector2(26,73+bob)],b)
			_p(im,[Vector2(28,56+bob),Vector2(42,52+bob),Vector2(59,56+bob),Vector2(63,66+bob),Vector2(43,70+bob),Vector2(28,66+bob)],TEAM_BLUE)
			_l(im,Vector2i(30,58+bob),Vector2i(57,56+bob),h,1);_l(im,Vector2i(31,68+bob),Vector2i(57,65+bob),d,1)
			_r(im,19,37+bob,13,24,d);_r(im,21,39+bob,9,17,h);_r(im,23,42+bob,5,10,a);_r(im,21,34+bob,9,4,b)
			for y: int in [43,48,53]: _r(im,23,y+bob,5,1,d)
			_p(im,[Vector2(35+lean,36+bob),Vector2(46+lean,28+bob),Vector2(62+lean,35+bob),Vector2(66+lean,51+bob),Vector2(54,62+bob),Vector2(35,54+bob)],d)
			_p(im,[Vector2(41+lean,37+bob),Vector2(48+lean,33+bob),Vector2(57+lean,38+bob),Vector2(59+lean,49+bob),Vector2(51,56+bob),Vector2(41,51+bob)],h)
			_r(im,46+lean,39+bob,8,11,d);_r(im,48+lean,41+bob,4,7,a)
			var recoil := int([0,1,-6,-2][k]) if row==2 else 0
			_l(im,Vector2i(53+recoil,40+bob),Vector2i(86+recoil,20+bob),b,12);_l(im,Vector2i(54+recoil,37+bob),Vector2i(86+recoil,17+bob),h,4)
			_l(im,Vector2i(58+recoil,40+bob),Vector2i(85+recoil,24+bob),d,3)
			_p(im,[Vector2(78+recoil,14+bob),Vector2(86+recoil,14+bob),Vector2(90+recoil,25+bob),Vector2(82+recoil,29+bob)],h)
			_l(im,Vector2i(82+recoil,18+bob),Vector2i(87+recoil,25+bob),INK,3)
			_l(im,Vector2i(38,39+bob),Vector2i(32-cast_lift/2,26+bob-cast_lift),h,4);_l(im,Vector2i(58,34+bob),Vector2i(59+cast_lift/2,19+bob-cast_lift),h,4)
			_r(im,32-cast_lift/2,25+bob-cast_lift,5,4,a);_r(im,57+cast_lift/2,18+bob-cast_lift,5,4,a)
		"elder_treant":
			# Buttress-root walker; the hollow trunk and unequal branches make
			# a warding tree, rather than another humanoid with green armour.
			for i: int in range(4):
				var rx := 23+i*15;var off := stride*(1 if i%2 else -1)
				_l(im,Vector2i(44+(i-2)*4,61+bob),Vector2i(rx+off,82),d,9);_l(im,Vector2i(rx+off,81),Vector2i(rx-8+off,85),h,4)
			_p(im,[Vector2(28+lean,30+bob),Vector2(43+lean,19+bob),Vector2(58+lean,25+bob),Vector2(62,58+bob),Vector2(57,75),Vector2(39,78),Vector2(27,67)],b)
			_p(im,[Vector2(38+lean,33+bob),Vector2(48+lean,27+bob),Vector2(55,38+bob),Vector2(53,62+bob),Vector2(43,69),Vector2(35,55+bob)],d)
			_l(im,Vector2i(31+lean,37+bob),Vector2i(34,66),h,2);_l(im,Vector2i(57+lean,36+bob),Vector2i(57,64),h,1)
			_r(im,39+lean,39+bob,5,3,pale);_r(im,49+lean,38+bob,5,3,pale);_p(im,[Vector2(41,49+bob),Vector2(51,47+bob),Vector2(48,56+bob),Vector2(43,57+bob)],INK)
			_l(im,Vector2i(30+lean,40+bob),Vector2i(14,47+bob-cast_lift),d,10);_l(im,Vector2i(14,47+bob-cast_lift),Vector2i(10,26+bob-cast_lift),b,7)
			_l(im,Vector2i(58+lean,36+bob),Vector2i(73+reach,42+bob-cast_lift),b,9);_l(im,Vector2i(73+reach,42+bob-cast_lift),Vector2i(76+reach/2,25+bob-cast_lift),h,5)
			_l(im,Vector2i(43+lean,25+bob),Vector2i(30,12+bob),d,6);_l(im,Vector2i(51+lean,26+bob),Vector2i(61,15+bob),h,5)
			for i: int in range(6):
				var x := int([11,24,37,53,66,78][i]);var y := int([23,20,18,20,22,26][i])+bob-(cast_lift if i in [0,5] else cast_lift/3)
				_p(im,[Vector2(x-7,y),Vector2(x-3,y-5),Vector2(x+5,y-6),Vector2(x+12,y),Vector2(x+8,y+8),Vector2(x-3,y+8)],b if i%2 else h)
				_l(im,Vector2i(x-2,y+2),Vector2i(x+7,y-1),pale,1);_r(im,x+1,y+5,2,1,d)
			_p(im,[Vector2(16,51+bob),Vector2(26,46+bob),Vector2(31,51+bob),Vector2(29,68),Vector2(20,72),Vector2(14,65)],TEAM_BLUE)
			_l(im,Vector2i(18,53+bob),Vector2i(26,61+bob),h,1);_r(im,22,54+bob,2,8,pale)
			_r(im,54,65,7,3,a);_r(im,55,64,5,1,pale)
		"rune_behemoth":
			# Weight sits over four broad hooves. Melee wind-up raises only the
			# near foreleg/head; the rear body stays planted at its foot anchor.
			for i: int in range(4):
				var x := int([23,38,61,75][i]);var off := stride*(1 if i%2 else -1);var lift := reach/2 if i==3 else 0
				_l(im,Vector2i(x,58+bob),Vector2i(x+off,80-lift),d,11);_r(im,x-7+off,79-lift,13,6,h);_r(im,x-5+off,83-lift,9,2,d)
			_p(im,[Vector2(13+lean,43+bob),Vector2(25+lean,25+bob),Vector2(46+lean,19+bob),Vector2(65+lean,32+bob),Vector2(75+lean,48+bob),Vector2(68,69),Vector2(35,73),Vector2(16,63)],d)
			_p(im,[Vector2(18+lean,43+bob),Vector2(29+lean,31+bob),Vector2(45+lean,26+bob),Vector2(62+lean,36+bob),Vector2(68,54+bob),Vector2(57,64),Vector2(31,65),Vector2(20,58)],b)
			for i: int in range(3):
				var x := 25+i*11;var y := 28+bob-absi(i-1)*3-cast_lift/3
				_p(im,[Vector2(x,y),Vector2(x+4,y-13-cast_lift/2),Vector2(x+11,y-8),Vector2(x+13,y+9),Vector2(x+4,y+12)],h)
				_l(im,Vector2i(x+5,y-5),Vector2i(x+6,y+5),a,2);_r(im,x+3,y,6,2,a)
			_p(im,[Vector2(58+lean,39+bob-reach/3),Vector2(72+lean,32+bob-reach/3),Vector2(84+lean,41+bob-reach/3),Vector2(87+lean,56+bob),Vector2(75+lean,65+bob),Vector2(60+lean,58+bob)],h)
			_p(im,[Vector2(65+lean,45+bob),Vector2(80+lean,43+bob),Vector2(83+lean,55+bob),Vector2(75+lean,59+bob),Vector2(65+lean,54+bob)],b)
			_r(im,71+lean,45+bob,7,3,d);_r(im,73+lean,45+bob,2,2,pale);_r(im,78+lean,55+bob,7,3,d)
			_l(im,Vector2i(63+lean,40+bob),Vector2i(66+lean,26+bob-reach/2),pale,5);_l(im,Vector2i(80+lean,40+bob),Vector2i(88+lean,30+bob-reach/2),pale,4)
			_p(im,[Vector2(25+lean,42+bob),Vector2(43+lean,40+bob),Vector2(48,59),Vector2(30,63)],TEAM_BLUE)
			for y: int in [45,52,59]: _l(im,Vector2i(29,y+bob),Vector2i(43,y-1+bob),h,1)
		"fire_dragon":
			var wing := int([-4,1,7,0][k]) if row in [0,1,5] else lean
			# Tail, limbs and neck remain individual structures even while the
			# wing membrane closes. Their small chips use source pixels, not blur.
			_l(im,Vector2i(33,62+bob),Vector2i(19,73+bob),d,9);_l(im,Vector2i(20,73+bob),Vector2i(9,64+bob+stride),b,5)
			_p(im,[Vector2(31,50+bob),Vector2(19,28+wing),Vector2(26,10+wing/2),Vector2(40,25+bob),Vector2(47,49+bob)],d)
			_p(im,[Vector2(32,45+bob),Vector2(24,28+wing),Vector2(28,16+wing/2),Vector2(37,28+bob),Vector2(42,45+bob)],a)
			_l(im,Vector2i(28,15+wing/2),Vector2i(34,42+bob),h,2);_l(im,Vector2i(25,29+wing),Vector2i(38,38+bob),b,1)
			_p(im,[Vector2(48,48+bob),Vector2(65,27-wing),Vector2(79,13-wing/2),Vector2(84,34-wing/2),Vector2(70,53+bob),Vector2(56,58+bob)],d)
			_p(im,[Vector2(54,46+bob),Vector2(68,30-wing),Vector2(77,19-wing/2),Vector2(79,33-wing/2),Vector2(67,47+bob),Vector2(57,52+bob)],h)
			_l(im,Vector2i(77,19-wing/2),Vector2i(58,48+bob),b,2);_l(im,Vector2i(79,33-wing/2),Vector2i(61,48+bob),a,1)
			_p(im,[Vector2(25+lean,51+bob),Vector2(37+lean,35+bob),Vector2(53+lean,34+bob),Vector2(66+lean,48+bob),Vector2(64,65+bob),Vector2(49,73+bob),Vector2(32,66+bob)],b)
			_p(im,[Vector2(46+lean,44+bob),Vector2(57+lean,44+bob),Vector2(60,63+bob),Vector2(49,68+bob),Vector2(42,61+bob)],h)
			for y: int in [49,55,61]: _l(im,Vector2i(46+lean,y+bob),Vector2i(57+lean,y+1+bob),d,1)
			_l(im,Vector2i(34,61+bob),Vector2i(27-stride,79+bob),d,7);_l(im,Vector2i(54,65+bob),Vector2i(61+stride,82+bob),h,6)
			for x: int in [26-stride,59+stride]: _l(im,Vector2i(x,80+bob),Vector2i(x+8,83+bob),pale,2)
			_l(im,Vector2i(58+lean,47+bob),Vector2i(70+lean,34+bob-reach/3),h,11)
			_p(im,[Vector2(67+lean,28+bob-reach/3),Vector2(80+lean,27+bob-reach/3),Vector2(88+lean,35+bob-reach/3),Vector2(86+lean,42+bob+reach/4),Vector2(73+lean,44+bob+reach/4),Vector2(66+lean,38+bob)],b)
			_r(im,76+lean,33+bob-reach/3,6,3,d);_r(im,78+lean,33+bob-reach/3,2,2,pale)
			_l(im,Vector2i(73+lean,29+bob-reach/3),Vector2i(71+lean,18+bob-reach/3),pale,3)
			_l(im,Vector2i(75+lean,40+bob+reach/4),Vector2i(86+lean,39+bob+reach/4),INK,3)
			if row in [2,5]: _r(im,79+lean,39+bob,6,2,a);_r(im,81+lean,38+bob,2,2,pale)
			for i: int in range(4):
				var x := 31+i*6;_p(im,[Vector2(x,39+bob),Vector2(x+2,32+bob),Vector2(x+5,39+bob)],h)
			_p(im,[Vector2(36+lean,44+bob),Vector2(44+lean,42+bob),Vector2(49,56+bob),Vector2(41,61+bob),Vector2(35,54+bob)],TEAM_BLUE)
		"abyss_devourer":
			# Four broad, jointed load-bearing legs, not six/eight thin spider
			# rays. The front pincers are separate arms with visible elbow mass.
			for i: int in range(4):
				var x := int([22,35,54,66][i]);var off := stride*(1 if i%2 else -1)
				var knee_x := x+int([-5,2,-1,5][i])+off;var knee_y := 72+(2 if i%2 else -1)
				_l(im,Vector2i(x,58+bob),Vector2i(knee_x,knee_y),d,10)
				_l(im,Vector2i(knee_x,knee_y),Vector2i(knee_x-2,82),b,8)
				_r(im,knee_x-7,81,12,5,d);_r(im,knee_x-5,82,8,2,h)
				_l(im,Vector2i(knee_x-2,knee_y-3),Vector2i(knee_x+2,knee_y+2),h,2)
			# Smooth rear shell and overlapping shoulder shield: no repeated
			# pointed dorsal slabs shared with the immobile fault-carapace tank.
			_p(im,[Vector2(11+lean,46+bob),Vector2(17+lean,31+bob),Vector2(31+lean,22+bob),Vector2(47+lean,22+bob),Vector2(61+lean,32+bob),Vector2(68+lean,50+bob),Vector2(62,64),Vector2(44,70),Vector2(23,65),Vector2(12,56+bob)],d)
			_p(im,[Vector2(16+lean,44+bob),Vector2(21+lean,33+bob),Vector2(33+lean,27+bob),Vector2(46+lean,27+bob),Vector2(57+lean,35+bob),Vector2(61+lean,49+bob),Vector2(53,60),Vector2(36,64),Vector2(22,58+bob)],b)
			_p(im,[Vector2(23+lean,35+bob),Vector2(34+lean,29+bob),Vector2(44+lean,29+bob),Vector2(50+lean,34+bob),Vector2(43+lean,39+bob),Vector2(30+lean,41+bob),Vector2(20+lean,45+bob)],h)
			_l(im,Vector2i(22+lean,35+bob),Vector2i(33+lean,29+bob),pale,1);_l(im,Vector2i(35+lean,29+bob),Vector2i(43+lean,29+bob),pale,1)
			_p(im,[Vector2(43+lean,41+bob),Vector2(53+lean,32+bob),Vector2(65+lean,36+bob),Vector2(72+lean,47+bob),Vector2(68+lean,59+bob),Vector2(54+lean,65+bob),Vector2(43+lean,57+bob)],h)
			_p(im,[Vector2(47+lean,43+bob),Vector2(55+lean,37+bob),Vector2(62+lean,40+bob),Vector2(65+lean,48+bob),Vector2(60+lean,55+bob),Vector2(49+lean,57+bob)],b)
			# Sparse stone/chitin fracture marks follow planes rather than a
			# noise fill. Highlights and dark cracks remain1 source pixel.
			_l(im,Vector2i(27+lean,47+bob),Vector2i(34+lean,44+bob),d,1);_l(im,Vector2i(34+lean,44+bob),Vector2i(39+lean,47+bob),d,1)
			_l(im,Vector2i(25+lean,53+bob),Vector2i(31+lean,55+bob),h,1);_r(im,40+lean,52+bob,3,1,d)
			_l(im,Vector2i(52+lean,42+bob),Vector2i(58+lean,43+bob),pale,1);_l(im,Vector2i(57+lean,49+bob),Vector2i(61+lean,51+bob),d,1)
			# Heavy far arm points over the low head. Its pincer opens at the
			# shoulder/elbow wind-up, then closes at the actual attack phase.
			var open_jaw := int([1,5,0,2][k]) if row==2 else int([1,3,5,1][k]) if row==5 else 1
			var arm_thrust := reach/3;var arm_y := 45+bob-cast_lift/3
			_l(im,Vector2i(59+lean,43+bob),Vector2i(73+lean+arm_thrust,arm_y),d,11)
			_p(im,[Vector2(61+lean,38+bob),Vector2(70+lean+arm_thrust,39+bob),Vector2(76+lean+arm_thrust,arm_y+5),Vector2(69+lean+arm_thrust,arm_y+9),Vector2(61+lean,49+bob)],h)
			_p(im,[Vector2(72+lean+arm_thrust,arm_y-2),Vector2(84+lean,arm_y-8-open_jaw),Vector2(88+lean,arm_y-5-open_jaw),Vector2(82+lean,arm_y+1),Vector2(75+lean+arm_thrust,arm_y+5)],h)
			_p(im,[Vector2(75+lean+arm_thrust,arm_y+3),Vector2(85+lean,arm_y+3+open_jaw),Vector2(87+lean,arm_y+7+open_jaw),Vector2(80+lean,arm_y+9),Vector2(73+lean+arm_thrust,arm_y+7)],b)
			_l(im,Vector2i(76+lean,arm_y-1),Vector2i(83+lean,arm_y-5-open_jaw),pale,1)
			# Low broad muzzle/mandibles: horizontal bite axis contrasts with
			# the tall fault horn of the protection tank.
			_p(im,[Vector2(60+lean,54+bob),Vector2(72+lean,50+bob),Vector2(81+lean,55+bob),Vector2(82+lean,65+bob),Vector2(72+lean,71+bob),Vector2(61+lean,66+bob)],d)
			_p(im,[Vector2(66+lean,55+bob),Vector2(75+lean,54+bob),Vector2(82+lean,58+bob),Vector2(79+lean,63+bob),Vector2(68+lean,62+bob)],h)
			_r(im,72+lean,57+bob,7,2,d);_r(im,75+lean,57+bob,2,1,a)
			_l(im,Vector2i(73+lean,65+bob),Vector2i(85+lean,62+bob-open_jaw/2),pale,3)
			_l(im,Vector2i(71+lean,68+bob),Vector2i(84+lean,69+bob+open_jaw/2),h,3)
			# Near forearm is a braced armoured weapon, not a fifth walking leg.
			_l(im,Vector2i(41+lean,54+bob),Vector2i(55+lean+arm_thrust,72+bob),d,12)
			_p(im,[Vector2(37+lean,51+bob),Vector2(47+lean,50+bob),Vector2(59+lean+arm_thrust,66+bob),Vector2(55+lean+arm_thrust,76+bob),Vector2(45+lean,69+bob)],h)
			_p(im,[Vector2(51+lean+arm_thrust,69+bob),Vector2(65+lean,67+bob-open_jaw),Vector2(75+lean,71+bob-open_jaw),Vector2(72+lean,75+bob),Vector2(58+lean+arm_thrust,77+bob)],b)
			_p(im,[Vector2(56+lean+arm_thrust,75+bob),Vector2(72+lean,76+bob+open_jaw),Vector2(77+lean,80+bob+open_jaw/2),Vector2(67+lean,82+bob),Vector2(55+lean+arm_thrust,79+bob)],h)
			_l(im,Vector2i(61+lean,72+bob-open_jaw),Vector2i(70+lean,72+bob-open_jaw),pale,1)
			_p(im,[Vector2(19+lean,48+bob),Vector2(28+lean,45+bob),Vector2(32,56),Vector2(25,60),Vector2(19,55+bob)],TEAM_BLUE)
			_p(im,[Vector2(43+lean,55+bob),Vector2(48+lean,55+bob),Vector2(54+lean,64+bob),Vector2(49+lean,69+bob),Vector2(44+lean,63+bob)],TEAM_BLUE)
	# Deliberate1px material details stay inside the2px silhouette. They do
	# not produce a uniform dither/noise skin or change the collision radius.
	if row==3: _r(im,44+lean,45+bob,5,2,pale)

static func _new_body_polish_r4(im: Image, id: String, row: int, k: int, bob: int, lean: int, reach: int, d: Color, b: Color, h: Color, pale: Color, a: Color) -> void:
	# Keep the accepted twelve source bodies, anchors and action construction.
	# Re-author material-local components rather than enlarging those rasters.
	match id:
		"seal_veil_guard":
			_p(im,[Vector2(22+lean,28+bob),Vector2(28+lean,25+bob),Vector2(33+lean,30+bob),Vector2(28+lean,34+bob),Vector2(21+lean,33+bob)],h)
			_p(im,[Vector2(36+lean,27+bob),Vector2(42+lean,27+bob),Vector2(47+lean,33+bob),Vector2(41+lean,36+bob),Vector2(35+lean,32+bob)],h)
			_l(im,Vector2i(37+lean,29+bob),Vector2i(43+lean,32+bob),pale,1)
			# Shield is laminated wood/paper inside a copper protective rim;
			# the owner panel is an inset, not a square stuck over the silhouette.
			_p(im,[Vector2(10,28-reach/3),Vector2(18,25-reach/3),Vector2(27,30-reach/3),Vector2(25,46),Vector2(18,51),Vector2(10,46)],h)
			_p(im,[Vector2(12,30-reach/3),Vector2(18,28-reach/3),Vector2(25,32-reach/3),Vector2(23,44),Vector2(18,48),Vector2(12,44)],d)
			_p(im,[Vector2(14,32-reach/4),Vector2(18,30-reach/4),Vector2(23,33-reach/4),Vector2(21,43),Vector2(18,46),Vector2(14,42)],TEAM_BLUE)
			_l(im,Vector2i(18,34-reach/4),Vector2i(18,42),pale,2);_r(im,16,37,5,1,pale)
			for x: int in [12,23]: _r(im,x,31-reach/4,1,1,pale);_r(im,x,44,1,1,pale)
			for x: int in [25,35]: _r(im,x,47,5,5,d);_r(im,x+1,48,3,1,h)
			_r(im,26+lean,19+bob,13,1,pale);_r(im,32+lean,22+bob,7,2,INK)
		"pall_lantern":
			# An armed memorial barge: prow skull, rib launchers and luminous
			# lantern focus are three separate silhouettes/materials.
			_p(im,[Vector2(44,35+bob-reach/4),Vector2(50,32+bob-reach/4),Vector2(55,36+bob-reach/4),Vector2(53,43+bob),Vector2(46,44+bob)],pale)
			_r(im,49,36+bob-reach/4,5,2,d);_l(im,Vector2i(51,42+bob),Vector2i(57,38+bob-reach/3),h,2)
			for i: int in range(2):
				var x := 21+i*11;var y := 35+bob-i*2
				_l(im,Vector2i(x,y+7),Vector2i(x+12+reach/4,y-2-reach/3),b,5)
				_l(im,Vector2i(x+3,y+3),Vector2i(x+11+reach/4,y-3-reach/3),pale,2)
				_r(im,x+7+reach/4,y-4-reach/3,4,4,d);_r(im,x+8+reach/4,y-3-reach/3,2,2,a)
			_l(im,Vector2i(15,44+bob),Vector2i(38,42+bob),h,1);_r(im,19,46+bob,2,1,d);_r(im,30,45+bob,2,1,d)
			_r(im,45,26-reach/2+bob,4,1,pale);_r(im,45,32-reach/2+bob,4,1,h)
			_r(im,21,26+bob,3,7,TEAM_BLUE);_r(im,21,26+bob,1,7,h)
		"rail_kite":
			# Swept main planes stay: add inset ribs, engine intakes and an
			# articulated downward-capable gun mount, not an AA-only sky lance.
			_p(im,[Vector2(25+lean,27+bob),Vector2(31+lean,22+bob),Vector2(38+lean,26+bob),Vector2(37+lean,33+bob),Vector2(28+lean,34+bob)],h)
			_p(im,[Vector2(29+lean,26+bob),Vector2(33+lean,24+bob),Vector2(36+lean,27+bob),Vector2(35+lean,30+bob),Vector2(29+lean,31+bob)],a)
			_l(im,Vector2i(31+lean,24+bob),Vector2i(32+lean,30+bob),d,1)
			_r(im,28+lean,35+bob,8,5,TEAM_BLUE);_r(im,29+lean,35+bob,1,4,h)
			for x: int in [19,43]:
				_r(im,x,28+bob,5,4,d);_r(im,x+1,29+bob,3,1,h)
				for y: int in [34,38]: _r(im,x+1,y+bob,3,1,h)
				_r(im,x,43+bob,5,3,d);_r(im,x+1,44+bob,3,1,a)
			_p(im,[Vector2(31,40+bob),Vector2(38,38+bob),Vector2(43,43+bob),Vector2(40,49+bob),Vector2(33,48+bob)],b)
			_r(im,34,42+bob,5,3,h)
			var aim := int([1,-1,3,1][k]) if row==2 else int([0,1,0,-1][k]) if row==5 else 0
			_l(im,Vector2i(39,43+bob),Vector2i(56+reach/4,44+bob+aim),h,4)
			_r(im,54+reach/4,43+bob+aim,4,4,d);_r(im,55+reach/4,44+bob+aim,2,1,INK)
			_l(im,Vector2i(13,21+bob),Vector2i(23,30+bob),pale,1);_l(im,Vector2i(40,30+bob),Vector2i(51,20+bob),d,1)
		"canopy_glasswing":
			# A seed-bow cradle below the head reads as ranged hardware even
			# with the leaf pinions folded. Never add a decorative damage ring.
			var bx := 45+reach/4;var by := 35+bob-reach/4
			_l(im,Vector2i(32+lean,35+bob),Vector2i(bx-4,by+4),b,4)
			_p(im,[Vector2(bx,by-10),Vector2(bx+4,by-8),Vector2(bx+3,by),Vector2(bx+1,by+12),Vector2(bx-2,by+13),Vector2(bx-1,by+1)],h)
			_l(im,Vector2i(bx+1,by-8),Vector2i(bx-4,by+1),pale,1);_l(im,Vector2i(bx-4,by+1),Vector2i(bx,by+11),pale,1)
			_l(im,Vector2i(35,by+2),Vector2i(56,by),b,3);_p(im,[Vector2(54,by-2),Vector2(58,by),Vector2(54,by+2)],pale)
			_r(im,29+lean,31+bob,5,9,TEAM_BLUE);_r(im,29+lean,31+bob,1,8,h)
			for sign: int in [-1,1]:
				_l(im,Vector2i(31+sign*7,25+bob),Vector2i(31+sign*17,21+bob),pale,1)
				_r(im,31+sign*14,24+bob,2,1,b)
		"deep_fault_carapace":
			# Overlapping armour and rooted feet make tank weight readable.
			# The fault horn is retained; it is not just the hunter body enlarged.
			for i: int in range(4):
				var x := 27+i*10;var y := 35+absi(i-2)*4+bob
				_p(im,[Vector2(x+lean-2,y+9),Vector2(x+6+lean,y+6),Vector2(x+12+lean,y+13),Vector2(x+6+lean,y+20),Vector2(x-1+lean,y+17)],b)
				_l(im,Vector2i(x+lean,y+12),Vector2i(x+6+lean,y+17),h,1)
			for x: int in [22,38,54,70]:
				_r(im,x-5,78,9,5,d);_r(im,x-4,79,7,2,h);_r(im,x-1,81,2,2,pale)
			_p(im,[Vector2(27+lean,54+bob),Vector2(34+lean,52+bob),Vector2(38+lean,58+bob),Vector2(35+lean,63+bob),Vector2(28+lean,64+bob)],TEAM_BLUE)
			_p(im,[Vector2(53+lean,49+bob),Vector2(59+lean,47+bob),Vector2(64+lean,52+bob),Vector2(61+lean,58+bob),Vector2(54+lean,58+bob)],TEAM_BLUE)
			_l(im,Vector2i(73+lean,51+bob),Vector2i(78+lean,48+bob),pale,1);_r(im,80+lean,52+bob,3,1,a)
		"seal_judicator":
			_l(im,Vector2i(28+lean,39+bob),Vector2i(31+lean,48+bob),d,1);_r(im,25+lean,25+bob,3,1,b)
		"grave_chain_guard":
			_r(im,29+lean,32+bob,1,10,b);_r(im,20,31+bob,1,8,h)
		"induction_weaver":
			_l(im,Vector2i(24+lean,27+bob),Vector2i(36+lean,24+bob),d,1);_r(im,25+lean,34+bob,12,1,h)
		"dew_thorn_scribe":
			_l(im,Vector2i(25+lean,38+bob),Vector2i(25,49),h,1);_r(im,32+lean,20+bob,3,2,b)
		"ridge_axe_guard":
			for x: int in [23,29,35]: _r(im,x+lean,31+bob,1,2,d)
		"cinder_kiln_acolyte":
			_l(im,Vector2i(27+lean,42+bob),Vector2i(25,51),d,1);_r(im,32+lean,28+bob,4,1,b)
		"resonance_driller":
			_l(im,Vector2i(22+lean,24+bob),Vector2i(26+lean,20+bob),pale,1);_r(im,30+lean,34+bob,5,1,h)

static func author_image(id: String, row: int, k: int) -> Image:
	if id in IDS: return PixelR8.author_image(id,row,k)
	if id not in IDS or row<0 or row>=6 or k<0 or k>=4: return null
	var spec: Dictionary = SPECS[id]
	var im := Image.create(int(spec.size),int(spec.size),false,Image.FORMAT_RGBA8);im.fill(Color.TRANSPARENT)
	var ramp: Array = RAMPS[spec.faction]
	var d := Color(ramp[0]);var b := Color(ramp[1]);var h := Color(ramp[2]);var pale := Color(ramp[3]);var a := Color(ramp[4])
	if id in ELITE_IDS_R4:
		_elite_body_r4(im,id,row,k,d,b,h,pale,a)
		_rim(im)
		return im
	var bob := int([0,-1,0,1][k]) if row==0 else int([0,-1,0,-1][k]) if row==1 else 0
	var lean := int([-2,-1,3,1][k]) if row==2 else int([-1,-2,1,0][k]) if row==5 else int([-3,2,-1,0][k]) if row==3 else 0
	var reach := int([0,2,9,4][k]) if row in [2,5] else 0
	var step := int([-3,0,3,0][k]) if row==1 else 0
	var body_k := k if row==1 else 1
	if row==4:
		_fallen_body_v4(im,id,k,d,b,h,pale,a)
		_rim(im)
		return im
	match id:
		"seal_judicator":
			_person(im,body_k,bob,lean,d,b,pale,true)
			_p(im,[Vector2(22+lean,19+bob),Vector2(24+lean,8+bob),Vector2(30+lean,12+bob),Vector2(36+lean,6+bob),Vector2(42+lean,17+bob)],h)
			_r(im,29+lean,12+bob,3,8,b);_r(im,38+lean,9+bob,3,9,pale)
			_l(im,Vector2i(38+lean,34+bob),Vector2i(48+reach/2,25-reach),b,5)
			_r(im,45+reach/2,18-reach,9,12,h);_r(im,47+reach/2,20-reach,5,7,d);_r(im,49+reach/2,21-reach,2,5,a)
			_p(im,[Vector2(10,32-reach/3),Vector2(20,29-reach/3),Vector2(27,33-reach/3),Vector2(26,42-reach/3),Vector2(19,39-reach/3),Vector2(10,42-reach/3)],pale)
			_l(im,Vector2i(19,31-reach/3),Vector2i(19,39-reach/3),b);_r(im,11,34-reach/3,5,2,b)
		"seal_veil_guard":
			_person(im,body_k,bob,lean,d,b,h,false,true)
			_p(im,[Vector2(22+lean,20+bob),Vector2(25+lean,10+bob),Vector2(37+lean,9+bob),Vector2(43+lean,20+bob)],h)
			_r(im,22+lean,21+bob,20,4,d);_r(im,28+lean,23+bob,10,2,pale)
			_p(im,[Vector2(8,26-reach/3),Vector2(18,22-reach/3),Vector2(30,29-reach/3),Vector2(28,49),Vector2(18,55),Vector2(7,47)],b)
			for x: int in [11,17,23]: _l(im,Vector2i(x,29-reach/3),Vector2i(x+1,47),h)
			_r(im,15,32,9,13,TEAM_BLUE);_r(im,18,35,3,7,pale)
			_l(im,Vector2i(44+lean,35),Vector2i(50+reach/2,51-reach),d,4);_r(im,44+reach/2,45-reach,13,7,h);_r(im,47+reach/2,46-reach,7,2,pale)
		"grave_chain_guard":
			_person(im,body_k,bob,lean,d,b,pale,false)
			_p(im,[Vector2(18+lean,25+bob),Vector2(18+lean,13+bob),Vector2(23+lean,11+bob),Vector2(24+lean,30+bob)],h)
			_r(im,26+lean,16+bob,13,4,b);_r(im,28+lean,19+bob,10,9,pale);_r(im,31+lean,21+bob,8,4,INK)
			for y: int in [32,37,42]: _r(im,28+lean,y+bob,9,2,pale)
			_l(im,Vector2i(40+lean,33+bob),Vector2i(47+reach/2,38-reach),h,4)
			for i: int in range(5):
				var x := 42+i*3;var y := 42-reach/2+(i%2)*2
				_r(im,x,y,3,3,h);_r(im,x+1,y+1,1,1,d)
			_l(im,Vector2i(55,44-reach/2),Vector2i(56,31-reach),pale,3);_l(im,Vector2i(56,31-reach),Vector2i(50,28-reach),pale,3)
			_r(im,18,28+bob,5,13,TEAM_BLUE)
		"pall_lantern":
			# The mast and sail sway relative to the hull in all four idle
			# cells; cropping away a whole-body bob must not erase the motion.
			var tilt := step+lean+(k*2-2 if row==0 else 0)
			_p(im,[Vector2(7,40+bob),Vector2(52,37+bob),Vector2(56,44+bob),Vector2(42,52+bob),Vector2(19,53+bob),Vector2(10,48+bob)],d)
			_p(im,[Vector2(10,41+bob),Vector2(49,40+bob),Vector2(43,48+bob),Vector2(20,49+bob)],b)
			for x: int in [16,24,32,40]: _l(im,Vector2i(x,41+bob),Vector2i(x+4,49+bob),pale,2)
			_l(im,Vector2i(32,43+bob),Vector2i(32+tilt/2,12+bob),h,3)
			_p(im,[Vector2(30+tilt/2,13+bob),Vector2(15,20+bob),Vector2(17,34+bob),Vector2(31,32+bob)],TEAM_BLUE)
			_l(im,Vector2i(34+tilt/2,17+bob),Vector2i(46,22-reach/2+bob),h,2)
			_r(im,42,23-reach/2+bob,10,12,d);_r(im,44,25-reach/2+bob,6,7,a);_r(im,46,26-reach/2+bob,2,5,pale)
			_l(im,Vector2i(15,47+bob),Vector2i(8,56+bob),h,3);_l(im,Vector2i(46,46+bob),Vector2i(54,55+bob),h,3)
		"induction_weaver":
			for i: int in range(3):
				var x := int([16,32,49][i]);_l(im,Vector2i(31,37+bob),Vector2i(x,47),d,6);_l(im,Vector2i(x,47),Vector2i(x+step*(1 if i%2 else -1),57),h,4)
			_p(im,[Vector2(18+lean,23+bob),Vector2(34+lean,19+bob),Vector2(46+lean,29+bob),Vector2(41+lean,41+bob),Vector2(21+lean,43+bob)],b)
			_r(im,23+lean,30+bob,16,6,TEAM_BLUE);_r(im,26+lean,24+bob,9,3,pale)
			_r(im,22+lean,10+bob,20,6,h);_r(im,22+lean,16+bob,5,9,h);_r(im,37+lean,15+bob,5,11,h);_r(im,27+lean,17+bob,10,5,a)
			_l(im,Vector2i(43+lean,30+bob),Vector2i(51+reach/2,22-reach),h,3)
			# Keep the extended fork inside the authored gutter, including its
			# two-pixel rim; the attack/cast thrust must not clip at phase2.
			for y: int in [18,24,30]: _r(im,47+reach/3,y-reach/2,8,2,a)
			_r(im,11+lean,26+bob,6,14,d);_r(im,12+lean,28+bob,4,4,a)
		"rail_kite":
			var wing := int([-2,1,3,0][k]) if row in [0,1,5] else lean
			_p(im,[Vector2(29,29+bob),Vector2(8,14+wing),Vector2(7,24+wing),Vector2(23,42+bob),Vector2(31,39+bob)],b)
			_p(im,[Vector2(33,28+bob),Vector2(54,13-wing),Vector2(57,22-wing),Vector2(41,41+bob),Vector2(31,39+bob)],h)
			_l(im,Vector2i(10,21+wing),Vector2i(27,36+bob),d,3);_l(im,Vector2i(35,35+bob),Vector2i(52,20-wing),d,3)
			_r(im,18,27+bob,7,21,b);_r(im,42,26+bob,7,21,b);_r(im,19,43+bob,5,6,a);_r(im,43,42+bob,5,6,a)
			_p(im,[Vector2(27+lean,21+bob),Vector2(36+lean,20+bob),Vector2(41+lean,37+bob),Vector2(33,49+bob),Vector2(26,37+bob)],d)
			_r(im,29+lean,27+bob,7,13,TEAM_BLUE);_r(im,30+lean,22+bob,5,4,pale)
			_l(im,Vector2i(33,41+bob),Vector2i(53+reach/3,41-reach/3+bob),h,4);_r(im,48+reach/3,39-reach/3+bob,7,4,d)
		"dew_thorn_scribe":
			_person(im,body_k,bob,lean,d,b,pale,true)
			_p(im,[Vector2(21+lean,19+bob),Vector2(18+lean,12+bob),Vector2(27+lean,12+bob),Vector2(30+lean,5+bob),Vector2(35+lean,11+bob),Vector2(43+lean,10+bob),Vector2(41+lean,22+bob)],b)
			_l(im,Vector2i(30+lean,10+bob),Vector2i(33+lean,17+bob),h,3)
			_l(im,Vector2i(46,56),Vector2i(45+reach/2,16-reach/2),b,3);_l(im,Vector2i(46+reach/2,22-reach/2),Vector2i(54,14-reach/2),h,3)
			_p(im,[Vector2(41+reach/2,16-reach/2),Vector2(44+reach/2,9-reach/2),Vector2(49+reach/2,16-reach/2),Vector2(46+reach/2,22-reach/2)],a)
			_r(im,11,31+bob-reach/3,12,15,d);_r(im,13,34+bob-reach/3,8,9,a);_r(im,14,30+bob-reach/3,6,4,h);_r(im,15,36+bob-reach/3,2,5,pale)
		"canopy_glasswing":
			var wing := int([-3,1,4,0][k]) if row in [0,1,5] else lean
			for sign: int in [-1,1]:
				_p(im,[Vector2(31,30+bob),Vector2(31+sign*19,10+wing),Vector2(31+sign*24,21+wing),Vector2(31+sign*12,35+bob)],b)
				_p(im,[Vector2(31+sign*3,30+bob),Vector2(31+sign*17,15+wing),Vector2(31+sign*19,23+wing),Vector2(31+sign*10,31+bob)],a)
				_l(im,Vector2i(31+sign*2,31+bob),Vector2i(31+sign*19,20+wing),h,2)
				_p(im,[Vector2(31,37+bob),Vector2(31+sign*19,36-wing),Vector2(31+sign*13,47-wing),Vector2(31+sign*3,42+bob)],h)
			_p(im,[Vector2(25+lean,22+bob),Vector2(35+lean,20+bob),Vector2(41+lean,28+bob),Vector2(34,45+bob),Vector2(29,51+bob),Vector2(25,37+bob)],d)
			_r(im,29+lean,30+bob,6,12,TEAM_BLUE);_r(im,32+lean,23+bob,5,3,pale)
			_p(im,[Vector2(38+lean,25+bob),Vector2(54+reach/3,29-reach/3+bob),Vector2(39+lean,32+bob)],pale)
			_l(im,Vector2i(30,44+bob),Vector2i(20-step,55+bob),b,3);_l(im,Vector2i(31,45+bob),Vector2i(36+step,56+bob),h,3)
		"ridge_axe_guard":
			_person(im,body_k,bob,lean,d,b,h,false,true)
			_p(im,[Vector2(17+lean,25+bob),Vector2(21+lean,17+bob),Vector2(28+lean,23+bob),Vector2(38+lean,20+bob),Vector2(46+lean,29+bob),Vector2(43+lean,36+bob),Vector2(18+lean,35+bob)],pale)
			_r(im,25+lean,13+bob,15,8,d);_r(im,27+lean,16+bob,12,5,h);_r(im,30+lean,21+bob,10,3,INK)
			_l(im,Vector2i(26+lean,16+bob),Vector2i(20+lean,10+bob),h,3);_l(im,Vector2i(38+lean,15+bob),Vector2i(43+lean,9+bob),h,3)
			_l(im,Vector2i(43,53),Vector2i(45+reach/2,18-reach),b,4)
			_p(im,[Vector2(45+reach/2,17-reach),Vector2(35+reach/2,13-reach),Vector2(35+reach/2,26-reach),Vector2(45+reach/2,24-reach)],h)
			_p(im,[Vector2(47+reach/2,17-reach),Vector2(56+reach/2,13-reach),Vector2(56+reach/2,26-reach),Vector2(47+reach/2,24-reach)],h)
			_r(im,43+reach/2,18-reach,6,4,a);_r(im,17+lean,36+bob,6,10,TEAM_BLUE)
		"cinder_kiln_acolyte":
			_r(im,16+lean,17+bob,11,29,d);_r(im,17+lean,19+bob,8,23,b)
			_r(im,17+lean,7+bob,7,15,h);_r(im,18+lean,8+bob,5,4,d)
			for y: int in [23,29,35]: _r(im,17+lean,y+bob,8,2,h)
			_person(im,body_k,bob,lean,d,b,h,true)
			_p(im,[Vector2(25+lean,23+bob),Vector2(24+lean,11+bob),Vector2(32+lean,7+bob),Vector2(40+lean,18+bob),Vector2(39+lean,25+bob)],d)
			_r(im,30+lean,19+bob,9,5,pale);_r(im,33+lean,21+bob,7,2,INK)
			_l(im,Vector2i(49,56),Vector2i(49+reach/3,17-reach/2),h,3)
			_r(im,44+reach/3,11-reach/2,12,13,d);_r(im,46+reach/3,13-reach/2,8,8,a);_r(im,48+reach/3,14-reach/2,3,5,pale)
			_r(im,29+lean,34+bob,7,11,TEAM_BLUE)
		"resonance_driller":
			for i: int in range(3):
				for sign: int in [-1,1]:
					var x := 22+i*7;var off := step*(1 if i%2 else -1)
					_l(im,Vector2i(x,35+bob),Vector2i(x+sign*12,44),d,4);_l(im,Vector2i(x+sign*12,44),Vector2i(x+sign*15+off,56),h,3)
			_p(im,[Vector2(15+lean,30+bob),Vector2(20+lean,16+bob),Vector2(33+lean,11+bob),Vector2(43+lean,24+bob),Vector2(43+lean,39+bob),Vector2(26+lean,44+bob)],b)
			_p(im,[Vector2(20+lean,28+bob),Vector2(25+lean,17+bob),Vector2(32+lean,15+bob),Vector2(38+lean,27+bob),Vector2(31+lean,33+bob)],h)
			_r(im,21+lean,31+bob,9,7,TEAM_BLUE);_r(im,35+lean,25+bob,8,7,d);_r(im,38+lean,27+bob,5,3,a)
			for y: int in [25,32,39]:
				_l(im,Vector2i(42+lean,y+bob),Vector2i(55+reach/3,y-reach/3+bob),h,3);_r(im,53+reach/3,y-4-reach/3+bob,3,8,a)
		"deep_fault_carapace":
			for i: int in range(4):
				for sign: int in [-1,1]:
					var x := 28+i*10;var off := step*(1 if i%2 else -1)
					_l(im,Vector2i(x,60+bob),Vector2i(x+sign*15,71),d,7);_l(im,Vector2i(x+sign*15,71),Vector2i(x+sign*18+off,85),h,4)
			_p(im,[Vector2(13+lean,50+bob),Vector2(24+lean,30+bob),Vector2(47+lean,20+bob),Vector2(67+lean,29+bob),Vector2(76+lean,49+bob),Vector2(70+lean,66+bob),Vector2(33+lean,73+bob),Vector2(16+lean,63+bob)],d)
			_p(im,[Vector2(19+lean,49+bob),Vector2(29+lean,34+bob),Vector2(47+lean,26+bob),Vector2(64+lean,34+bob),Vector2(69+lean,49+bob),Vector2(60+lean,62+bob),Vector2(32+lean,65+bob)],b)
			for i: int in range(4):
				var x := 27+i*10;var y := 35+absi(i-2)*4+bob
				_p(im,[Vector2(x+lean,y),Vector2(x+7+lean,y-4),Vector2(x+12+lean,y+10),Vector2(x+4+lean,y+15)],h)
				_l(im,Vector2i(x+3+lean,y+2),Vector2i(x+8+lean,y+9),pale,2)
			_r(im,27+lean,53+bob,10,10,TEAM_BLUE);_r(im,52+lean,49+bob,11,9,TEAM_BLUE)
			_p(im,[Vector2(66+lean,45+bob),Vector2(80+lean,43+bob),Vector2(86+lean,53+bob),Vector2(79+lean,67+bob),Vector2(66+lean,64+bob)],h)
			_r(im,76+lean,49+bob,8,4,d);_r(im,78+lean,50+bob,5,2,a)
			_p(im,[Vector2(73+lean,45+bob),Vector2(83+reach/3,26-reach/2+bob),Vector2(86+reach/3,46+bob)],pale)
			_l(im,Vector2i(72+lean,62+bob),Vector2i(87+reach/3,66-reach/3+bob),a,3)
	# Small material-local marks, not a uniform noise texture or thicker
	# contour: paper folds, brass rivets, wood grain and stepped shale edges.
	match id:
		"seal_judicator":
			_r(im,11,35-reach/3,5,1,b);_r(im,21,34-reach/3,3,1,b);_r(im,21,37-reach/3,3,1,b)
			_r(im,47+reach/2,20-reach,1,7,pale);_r(im,49+reach/2,25-reach,3,1,b)
		"seal_veil_guard":
			for x: int in [12,24]:
				_r(im,x,31-reach/4,1,1,pale);_r(im,x,47,1,1,pale)
			_l(im,Vector2i(12,33),Vector2i(13,46),d,1);_l(im,Vector2i(24,35),Vector2i(25,45),d,1)
			_r(im,16,33,1,9,b);_r(im,20,34,1,7,h)
		"grave_chain_guard":
			_r(im,20+lean,17+bob,2,1,d);_r(im,20+lean,21+bob,2,1,d)
			_l(im,Vector2i(29+lean,33+bob),Vector2i(34+lean,35+bob),d,1);_r(im,35+lean,38+bob,1,2,b)
		"pall_lantern":
			_l(im,Vector2i(16,46+bob),Vector2i(41,44+bob),h,1);_l(im,Vector2i(20,49+bob),Vector2i(36,47+bob),d,1)
			_r(im,18,25+bob,1,6,pale);_r(im,44,24-reach/2+bob,1,9,h)
		"induction_weaver":
			for x: int in [21,39]:
				_r(im,x+lean,28+bob,1,1,pale);_r(im,x+lean,38+bob,1,1,h)
			_r(im,24+lean,11+bob,15,1,pale);_r(im,13+lean,34+bob,2,1,b)
		"rail_kite":
			_l(im,Vector2i(13,22+bob),Vector2i(23,32+bob),h,1);_l(im,Vector2i(40,32+bob),Vector2i(51,21+bob),pale,1)
			for x: int in [20,44]: _r(im,x,30+bob,2,1,pale);_r(im,x,36+bob,2,1,d)
		"dew_thorn_scribe":
			_r(im,13,35+bob-reach/3,1,7,pale);_r(im,19,37+bob-reach/3,1,4,b)
			_l(im,Vector2i(24+lean,15+bob),Vector2i(28+lean,18+bob),h,1);_r(im,34+lean,14+bob,1,3,h)
		"canopy_glasswing":
			for sign: int in [-1,1]:
				_l(im,Vector2i(31+sign*4,28+bob),Vector2i(31+sign*13,23+bob),pale,1)
				_l(im,Vector2i(31+sign*8,39+bob),Vector2i(31+sign*14,40+bob),b,1)
		"ridge_axe_guard":
			_l(im,Vector2i(37+reach/2,16-reach),Vector2i(37+reach/2,23-reach),pale,1)
			_l(im,Vector2i(54+reach/2,16-reach),Vector2i(54+reach/2,23-reach),pale,1)
			for x: int in [20,25,40]: _r(im,x+lean,29+bob,1,3,b)
		"cinder_kiln_acolyte":
			_r(im,18+lean,13+bob,5,1,d);_r(im,20+lean,8+bob,1,4,pale)
			_r(im,46+reach/3,13-reach/2,1,7,h);_r(im,51+reach/3,17-reach/2,2,1,b)
		"resonance_driller":
			_l(im,Vector2i(24+lean,23+bob),Vector2i(32+lean,28+bob),b,1);_l(im,Vector2i(21+lean,30+bob),Vector2i(30+lean,35+bob),d,1)
			_r(im,37+lean,28+bob,1,2,pale)
		"deep_fault_carapace":
			for i: int in range(4):
				var x := 27+i*10;var y := 35+absi(i-2)*4+bob
				_l(im,Vector2i(x+2+lean,y+5),Vector2i(x+7+lean,y+13),d,1);_r(im,x+5+lean,y+2,2,1,pale)
			_l(im,Vector2i(25+lean,65+bob),Vector2i(56+lean,61+bob),h,1)
	_new_body_polish_r4(im,id,row,k,bob,lean,reach,d,b,h,pale,a)
	if row==3:
		_r(im,29+lean,31+bob,7,2,pale)
	if row==5 and id not in ["rail_kite","deep_fault_carapace"]:
		# Caster hands/tool move in the authored geometry; this small mechanism
		# highlight is secondary, never a substitute for the body pose.
		_r(im,42+lean,29-k*2,3,3,a)
	_rim(im)
	return im

static func _prepare() -> void:
	if _attempted: return
	_attempted=true
	var path := ROOT+"manifest.json"
	if not FileAccess.file_exists(path): _failures.append("V4 original actor atlas absent; diagnosed generic fallback");return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary or raw.get("accepted")!=true or raw.get("provenance")!=PROVENANCE or raw.get("identities")!=IDS or raw.get("author_source_sha256")!=FileAccess.get_sha256("res://src/presentation/heroic_outposts_v4_units.gd") or raw.get("pixel_author_sha256")!=FileAccess.get_sha256(PIXEL_R8_SOURCE):
		_failures.append("V4 atlas not accepted or author source differs");return
	for id: String in IDS:
		var record: Dictionary = raw.get("assets",{}).get(id,{})
		var relative := "runtime/"+id+"-v4.png"
		if record.get("file")!=relative or not FileAccess.file_exists(ROOT+relative) or FileAccess.get_sha256(ROOT+relative)!=record.get("sha256"):
			_failures.append(id+": atlas file/hash differs");continue
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+relative))!=OK or image.get_size()!=Vector2i(int(SPECS[id].size)*4,int(SPECS[id].size)*6):
			_failures.append(id+": atlas grid differs");continue
		image.convert(Image.FORMAT_RGBA8)
		if not record.get("frames") is Array or record.frames.size()!=24:
			_failures.append(id+": incomplete frame records");continue
		var valid := true
		for index: int in range(24):
			var cell := image.get_region(Rect2i(index%4*int(SPECS[id].size),index/4*int(SPECS[id].size),int(SPECS[id].size),int(SPECS[id].size)))
			if _digest(cell)!=str(record.frames[index].get("pixel_sha256","")): valid=false;break
		if not valid: _failures.append(id+": frame pixels differ");continue
		_sheets[id]=image;_records[id]=record.duplicate(true)

static func supported(unit: Dictionary, _pose: Dictionary = {}) -> bool:
	var id := str(unit.get("unit_type",""))
	if id not in IDS or bool(unit.get("neutral",false)) or str(unit.get("faction_id",SPECS[id].faction))!=str(SPECS[id].faction): return false
	_prepare();return _sheets.has(id)

static func _frame(unit: Dictionary, pose: Dictionary) -> Dictionary:
	if not supported(unit,pose): return {}
	var id := str(unit.unit_type);var spec: Dictionary = SPECS[id]
	var action := str(pose.get("action","IDLE"));var row := 0
	var phase := float(pose.get("body_phase_m76",pose.get("phase",0)))
	phase=clampf(phase,0,0.99999) if is_finite(phase) else 0
	var k := clampi(int(pose.get("body_idle_frame_m76",0)),0,3)
	if action in ["WALK","CARRY"]: row=1;k=posmod(floori(float(pose.get("body_animation_tick_m76",pose.get("animation_tick",0)))/3.0),4)
	elif action in ["ATTACK","HARVEST","MINE","BUILD"]: row=2;k=mini(floori(phase*4),3)
	elif action in ["HIT","HURT","DAMAGE"]: row=3;k=mini(floori(phase*4),3)
	elif action=="FALLEN": row=4;k=clampi(floori(float(pose.get("body_death_phase_v3",1))*4),0,3)
	elif action.begins_with("SKILL_") or action in ["CAST","HEAL","POTION"]: row=5;k=mini(floori(phase*4),3)
	var mirror := Vector2(pose.get("direction",Vector2.RIGHT)).x<0
	var key := "outposts-v4:"+id+":"+str(row)+":"+str(k)+":"+str(mirror)
	if _frames.has(key): _order.erase(key);_order.append(key);return _frames[key]
	var size := int(spec.size);var cell: Image = _sheets[id].get_region(Rect2i(k*size,row*size,size,size))
	if mirror: cell.flip_x()
	var used := cell.get_used_rect();var image := cell.get_region(used)
	var mask := Image.create(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8);mask.fill(Color.TRANSPARENT)
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var c := image.get_pixel(x,y)
			if c.a>0.5 and c.h>0.54 and c.h<0.7 and c.s>0.4:
				mask.set_pixel(x,y,Color(0.88,0.88,0.88,1))
	var anchor := Vector2(spec.anchor)
	if mirror: anchor.x=size-1-anchor.x
	var result := {"key":key,"identity":id,"row":row,"column":k,"mirror":mirror,"image":image,"texture":ImageTexture.create_from_image(image),"mask_texture":ImageTexture.create_from_image(mask),"rect":Rect2(Vector2(used.position)-anchor,Vector2(used.size)),"pixel_hash":_digest(image),"source_rect":Rect2i(k*size,row*size,size,size)}
	while _order.size()>=MAX_FRAMES: _frames.erase(_order.pop_front())
	_frames[key]=result;_order.append(key);_bakes+=1;return result

static func pixel_scale(unit: Dictionary, radius: float) -> float:
	if not is_finite(radius) or radius<=0 or not supported(unit): return 0
	var id := str(unit.unit_type)
	return radius/float(SPECS[id].nominal_radius)*float(SPECS[id].world_height)/float(_records[id].idle_height)

static func visual_bounds(unit: Dictionary, radius: float, pose: Dictionary = {}) -> Rect2:
	var factor := pixel_scale(unit,radius);var frame := _frame(unit,pose)
	return Rect2(Vector2(frame.rect.position)*factor,Vector2(frame.rect.size)*factor) if factor>0 and not frame.is_empty() else Rect2()

static func stable_visual_bounds(unit: Dictionary, radius: float) -> Rect2:
	var factor := pixel_scale(unit,radius)
	if factor<=0: return Rect2()
	var r: Array = _records[str(unit.unit_type)].stable_body_bounds
	return Rect2(Vector2(r[0],r[1])*factor,Vector2(r[2],r[3])*factor)

static func ground_footprint(unit: Dictionary, radius: float) -> Vector2:
	if not supported(unit) or not is_finite(radius) or radius<=0: return Vector2.ZERO
	var s: Dictionary = SPECS[str(unit.unit_type)]
	return Vector2(s.footprint[0],s.footprint[1])*radius/float(s.nominal_radius)

static func draw(canvas: Object, foot: Vector2, unit: Dictionary, radius: float, pose: Dictionary) -> bool:
	var factor := pixel_scale(unit,radius);var frame := _frame(unit,pose)
	if factor<=0 or frame.is_empty() or not foot.is_finite(): return false
	if canvas is CanvasItem: canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var bounds := Rect2((foot+Vector2(frame.rect.position)*factor).round(),Vector2(frame.rect.size)*factor)
	TeamMaterial._retain_draw_texture_m81(canvas,frame.texture);canvas.draw_texture_rect(frame.texture,bounds,false)
	if str(pose.get("action",""))!="FALLEN" and int(unit.get("hp",1))>0:
		TeamMaterial._retain_draw_texture_m81(canvas,frame.mask_texture)
		canvas.draw_texture_rect(frame.mask_texture,bounds,false,TeamMaterial.Palette.side_color(str(unit.get("side","PLAYER"))))
	return true

static func body_contains(unit: Dictionary, radius: float, pose: Dictionary, offset: Vector2) -> bool:
	var factor := pixel_scale(unit,radius);var frame := _frame(unit,pose)
	if factor<=0 or frame.is_empty() or not offset.is_finite(): return false
	var p := Vector2i((offset/factor-Vector2(frame.rect.position)).floor())
	return Rect2i(Vector2i.ZERO,frame.image.get_size()).has_point(p) and frame.image.get_pixelv(p).a>0.1

static func inspect(unit: Dictionary, pose: Dictionary = {}) -> Dictionary:
	var frame := _frame(unit,pose)
	if frame.is_empty(): return {"supported":false,"fallback_reason":status()}
	var id := str(unit.unit_type)
	return {"supported":true,"identity":id,"category":id,"key":frame.key,"frame":frame.column,"stage":frame.row,"action":str(pose.get("action","IDLE")),"mirror":frame.mirror,"rect":frame.rect,"pixel_hash":frame.pixel_hash,"source_rect":frame.source_rect,"source_file":_records[id].file,"source_sha256":_records[id].sha256,"provenance":PROVENANCE,"original_art":true,"generated_art":false,"licensed_art":false,"new_body_identity":true,"silhouette":SPECS[id].silhouette,"team_accent":"authored-blue-cloth-panels","owner_atlas_copies":0}

static func status() -> Dictionary:
	_prepare()
	return {"ready":not _sheets.is_empty(),"complete":_sheets.size()==IDS.size() and _failures.is_empty(),"accepted_count":_sheets.size(),"expected_count":IDS.size(),"identities":_sheets.keys(),"failures":_failures.duplicate(),"provenance":PROVENANCE,"owner_atlas_copies":0}

static func debug_stats() -> Dictionary:
	var result := status();var bytes := 0
	for frame: Dictionary in _frames.values(): bytes+=frame.image.get_width()*frame.image.get_height()*8
	result.merge({"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"texture_bytes":bytes,"maximum_texture_bytes":MAX_FRAMES*96*96*8},true)
	return result
