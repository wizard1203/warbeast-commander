extends RefCounted
## R8 original 32-cell author. Shapes are authored clusters, not sampled from
## the previous 64/96-cell polygon sprites. Offline atlas compilation only.
const IDS := ["seal_judicator","seal_veil_guard","grave_chain_guard","pall_lantern","induction_weaver","rail_kite","dew_thorn_scribe","canopy_glasswing","ridge_axe_guard","cinder_kiln_acolyte","resonance_driller","deep_fault_carapace","oath_colossus","soul_revenant","aether_engine","elder_treant","rune_behemoth","fire_dragon","abyss_devourer"]
const INK := Color("191921")
const TEAM := Color("4276bf")
const TEAM_LIGHT := Color("6594d4")
const RAMPS := {
	"HUMAN":["443c36","81654b","bd985c","eed9a5","95bec0"],
	"UNDEAD":["403445","786171","b0a58b","e1dab4","94bda1"],
	"MACHINE":["34404a","667982","a6b0b2","e3dfbc","e7a758"],
	"FOREST":["304637","597341","9aaf68","e0d79b","9bd0c3"],
	"HIGHLAND":["413846","796570","b39f91","e3d0ac","e49a50"],
	"UNDERGROUND":["3b3045","705377","a28b9e","d7c9ae","bdd58b"],
}
const FACTIONS := ["HUMAN","HUMAN","UNDEAD","UNDEAD","MACHINE","MACHINE","FOREST","FOREST","HIGHLAND","HIGHLAND","UNDERGROUND","UNDERGROUND","HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","HIGHLAND","UNDERGROUND"]

# Each string is one original source pixel row. The transparent dots are
# deliberate contour notches; long surfaces use two-to-four cell clusters.
const BODIES := {
	"seal_judicator":[
		"...hh....pp...", "...hph..hpp...", "....hhhpp....", "...bbhhhbb...",
		"...bppppb....", "....pddp.....", "...dddddb....", ".bbhhbbbbb...",
		".bhhb==bbhh..", "..bb+==bbhh..", "...b+==bdd...", "...d+==bd....",
		"..db+==bb....", "..db+==bh....", ".dbb+==bbd...", ".dbbhhhbbd...",
		".dbbdddbbd...", "..ddddddd...."],
	"seal_veil_guard":[
		".......hhhh...", ".....hhhpphh..", "....hhbbbbbh..", "....hpppppph..",
		".....pddddd...", "....bbbbbb....", "..hhhbbbbhhh..", ".hhhbb==bbhh..",
		".hbbbp==bbh...", ".bbddp==bbdd..", "..bddp==bbdd..", "..bbbp==bbdd..",
		"..bbbhhhbbdd..", "...bbbddbdd...", "...dddddddd..."],
	"grave_chain_guard":[
		"..hh.........", "..hph........", "..hpp..ppp...", "..hbb.ppppp..",
		"..hbb.pddpp..", "..hbb..ppp...", "..hdd..db....", "..hbbbpbbb...",
		"..hbbpppbb...", "...bbddpbbb..", "...bppppbb...", "...bdddppb...",
		"...bppppbd...", "...b==ddbd...", "...b==bbbd...", "....ddddd...."],
	"pall_lantern":[
		"........hh.............", "........hh.............", "...bbb..hh.............",
		"..b==bb.hh.............", ".b+===b.hh.............", ".b+===bbhh.............",
		".b+====bhh.............", "..b+===bhh.............", "..bb===bhh.............",
		"...bb==bhh.............", "....bbbbhh.............", "........hh.............",
		"...pp...hh...pp........", "..pbbp..hh..pbbp.......", ".ppbbpphhhhppbbpp......",
		".dbhhhbbhhbbhhbbd......", "..dbbppbbppbbppbbdd....", "...dbbhhbbhhbbhhbdd....",
		"....ddbbbhhhbbbbdd.....", "......dddddddddd......."],
	"induction_weaver":[
		".....hhhhhhh.......", "....hhppppphh......", "....hbb...bbh......",
		"....hb.....bh......", "....haa...aah......", "....hhhaaahhh......",
		"...bbbhhhhhbbb.....", "..hhbbbbbbbbbph....", ".hhppbbb==bbbphh...",
		".hbbbbb+==bbbhhh...", ".dbbbbh+==hbbbdd...", "..dbbbh+==hbbdd....",
		"...ddbbhhhbbdd.....", ".....dddddd........"],
	"rail_kite":[
		"...........hh...........", "..........hpph..........", "..........hbbh..........",
		".........hb==bh.........", "........hbb+==bh........", ".......hbdb+==bdh.......",
		"......hbbdb+==bdbh......", "......hhhdb+==bdhh......", ".......ddbb==bbdd.......",
		"........ddbbbbdd........", ".........dbbbbd.........", ".........dbddbd........."],
	"dew_thorn_scribe":[
		"......hh.....", "..hhh.hph....", "..hpphhph....", "...hhphphhhh.",
		"....hhhhhpph.", "....bbbpphh..", "....bppppb...", ".....pddp....",
		"....bbbbbb...", "...hhbb==bb..", "..bhhbb==bb..", "..bbbbb+=bb..",
		"...dbbb+=bd..", "...dbhh+=bd..", "..dbbhh+=bbd.", "..dbbbh+=bbd.",
		"..dbbhhhhbbd.", "...dddddddd.."],
	"canopy_glasswing":[
		"...........hh............", "..........hpph...........", ".........hbbbh...........",
		"..........pddpp..........", ".........bbbbbph.........", "........hb==bbph.........",
		"........hb+==bbh.........", "........db+==bbd.........", ".........b+==bd..........",
		".........bbbbb...........", "..........ddbd...........", "..........dbbd..........."],
	"ridge_axe_guard":[
		".hh.........hh....", ".hpp.......hpp....", "..hhbbhhhbbhh.....", "...hhppppphh......",
		"...hbbbbbpph......", "....pdddddpp......", "..pppbbbbpppp.....", ".ppbhhhhhhhhpp....",
		".phhbbb==bbhhp....", ".hhbbbp==bbbhd....", "..dbbbp==bbbdd....", "..dbbbp==bbbdd....",
		"..dbbbhhhhhbbd....", "...ddbbbddbbdd....", "....ddddddddd....."],
	"cinder_kiln_acolyte":[
		"..hhh...........", "..hph...........", "..hbh...........", "..hbh...hh......",
		"..hph..hbbh.....", "..bbb.hbbbbh....", ".hhbhhbbppbbh...", ".hbabbpddppbh...",
		".hbaabbppbbbd...", ".hbbbdbbbbbbb...", ".hpphdbb==bbh...", ".hbbhdbb+=bbh...",
		".hpphdbb+=bbd...", ".hbbhdbb+=bbd...", ".dddddbb+=bbd...", ".....dbbhhbbd...",
		"....dbbbhbbbd...", "....ddddddddd..."],
	"resonance_driller":[
		".......hhh............", ".....hhppph...........", "....hbppppph..........",
		"...hbpphhbph..........", "..hbpphhbbbh..........", "..hbphhbbbdd..........",
		".hbphhbbbbddd.........", ".hbhbbb==bbddd........", ".hbbbb+==bbdbbh.......",
		"..dbbb+==bbbaahh......", "..ddbbhhhbbbaaah......", "...ddbbbbbbdddd.......",
		".....ddddddd.........."],
	"deep_fault_carapace":[
		".........hhh.............", "......hhhhphhh...........", "....hhhpphbbhhh..........",
		"...hhppphbbbhphh.........", "..hhpphhbbhhppphh........", ".hhpphhbbhhpphhbhh.......",
		".hbphhbbhhpphhbbbhh......", ".hbhhbbhhpphhbbbdbh......", ".hbbb==bbbb==bbbdbh......",
		".hbb+==bbb+==bbdbbh......", "..hbbhbbbbbhbbbdbbhpp....", "...dbbpphhppbbbbhbbpph...",
		"....ddbbhhhhbbddhbbddph..", "......dddddddd..dbbaah...", "................dddd...."],
	"oath_colossus":[
		"........hhhhhh.........", ".......hhppppph........", "......hhbbbbbphh.......",
		"......hhhhhhhhhh.......", ".......hpppph..........", "........pddpp..........",
		".....bbbdbbbbbb........", "....hhbbbbb==bbh.......", "...hhhbbbbp==bbhh......",
		"...hhbbhbbp==bbhh......", "....dbbhbbp==bbbd......", "....dbbhbbp==bbbd......",
		".....bbhhhphhhhbd......", ".....bbbbbddbbbbd......", ".....ddbbdddbbdd.......",
		"......ddddddddd........"],
	"soul_revenant":[
		"......pp......pp........", "......php....php........", "....hhhpphhhhpphh.......",
		"...hhppphpppphppphh.....", "..hhpbbhppddpphbbphh....", "..hppbbhhpppphhbbpph....",
		"..hbbbbbdbppbdbbbbbh....", ".hppbbbbppddppbbbbpph...", ".hppbbhhpbaabphhbbpph...",
		"..hbbbhppbaabpphbbbh....", "..hbbbhpbdaadbphbbbh....", "..hbbbpphdaadhppbbbh....",
		"...dbbbpphhhhppbbbd.....", "....dbbbhhpphhbbbd......", ".....dbbhhddhhbbd.......",
		"......dddddddddd........"],
	"aether_engine":[
		".............pphh........", "............hphhbh.......", "..........hhphhbbh.......",
		".........hphhbbhhd.......", ".......hhphhbbhhd........", "......hpphhbbhhd.........",
		".....hphhbbbdd...........", ".....hhhhbbdd.hhhhh......", "...hhhbbbbbh..hpppph.....",
		"..hhppbbbbhhhhhbbaph.....", ".hhbbbhhbbhbbbhbaaph.....", ".hbbbpphb==bbbhaabph.....",
		".hbbbhph+==bbbbhhhbh.....", "..hbbbph+==bbbbbbhbd.....", "..ddddddhhhhhhhhdddd.....",
		".hhbbddbbddbbddbbddhh....", ".hbppbbppbbppbbppbbbh....", ".hbbbddbbddbbddbbddbh....",
		"..dddddddddddddddddd....."],
	"elder_treant":[
		"..hhh........hh.........", ".hhpphh....hhhphh.......", ".hpphbbh..hhppbbhh......",
		"..hhbbbhhhhpphbbbh......", "...hbphhhpphhbbbhh......", "..hhpphbbhbbbhhhh.......",
		".hhpphhbbbppbbbh........", ".hbbhhbbbpppbbbhhh......", "..hhhbbhdddpbbhhpph.....",
		"...hbbhpdddpbbhppph.....", "...hbbhpdddpbbhbbhh.....", "..hhbbhpdddpbbbhh.......",
		".hhbbhhpdddpbhbbhh......", ".hbbhbbhppphhbbbhh......", "..hhbbbh==hbbbbhh.......",
		"...hbbb+==hbbbhd........", "...hbbbbhhbbbbhd........", "....dbbbddbbbdd........."],
	"rune_behemoth":[
		".......hh....hh..........", "......hpph..hpph.........", ".....hbpph..hbph.........",
		"....hhbbbhhhbbphh........", "...hhppbbbppbbhbbhh......", "..hhpphhbbhbbhhbbbhh.....",
		".hhpphhbbhhbbhbbbbbph....", ".hbbhhhbbhbbhhbbbbbpph...", ".hbbhbbbhhbbhbbbbdbbph...",
		".hbbb==bbbbbbbbbdbbpph...", ".hbb+==bbbbhhbbbdbddpp...", "..hbbbbbbhhhbbbhhhppph...",
		"...dbbbbhhbbbbhd..ppph...", "....dbbbddbbbbdd...pp....", ".....dddddddddd.........."],
	"fire_dragon":[
		"...............hh........", "..............hpph..hh...", ".............hbbbh.hpph..",
		".............hbbbhhbbh...", "...........hhbbbhppbbh...", "..........hbbbbhpddpph...",
		".........hbbbabhpppph....", "........hbbbbaabhhhh.....", ".......hbbbaaabbh........",
		"......hbbbbaaaabph.......", ".....hbbbbbaaaabph.......", "....hbbbbbbhabbph........",
		"....hbbbbb==bbph.........", ".....hbbb+==bbh..........", "......dbbbbbbhd..........",
		".......ddddddd..........."],
	"abyss_devourer":[
		".......hhhhhhh..........", "....hhhhpphpphhh........", "...hhpppphbbhppphh......",
		"..hhpphhbbhbbhppphh.....", ".hhpphhbbbhbbbhhbbhh....", ".hbbhhbbbbhhbbb==bbh....",
		".hbhbbbbbbhbbbp==bbh....", ".hbbbbb==bbbbbphhhhph...", ".hbbbb+==bbbbhppddppph..",
		"..hbbbbhhbbbhpppddppph..", "...dbbbbbbbhbbpppppph...", "....ddbbddbbddhhhhhh....",
		".....dddddddd..........."],
}

static func _r(im: Image,x: int,y: int,w: int,h: int,c: Color) -> void:
	var rect := Rect2i(x,y,w,h).intersection(Rect2i(2,2,28,28))
	if rect.has_area(): im.fill_rect(rect,c)

static func _stamp(im: Image,x: int,y: int,rows: Array,p: Dictionary) -> void:
	for yy: int in range(rows.size()):
		var line: String=rows[yy]
		for xx: int in range(line.length()):
			var key:=line.substr(xx,1)
			if p.has(key): _r(im,x+xx,y+yy,1,1,p[key])

static func _outline(im: Image) -> void:
	var source := im.duplicate() as Image
	for y: int in range(2,30):
		for x: int in range(2,30):
			if source.get_pixel(x,y).a<0.5: continue
			for off: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var at:=Vector2i(x,y)+off
				if source.get_pixelv(at).a<0.5: im.set_pixelv(at,INK)

static func _palette(id: String) -> Dictionary:
	var ramp: Array=RAMPS[FACTIONS[IDS.find(id)]]
	return {"d":Color(ramp[0]),"b":Color(ramp[1]),"h":Color(ramp[2]),"p":Color(ramp[3]),"a":Color(ramp[4]),"=":TEAM,"+":TEAM_LIGHT,"i":INK}

static func _sole(im: Image,x: int,y: int,p: Dictionary,wide: int=3) -> void:
	_r(im,x,y,wide,2,p.d);_r(im,x,y,wide-1,1,p.h)

static func _legs(im: Image,id: String,k: int,row: int,p: Dictionary) -> void:
	var step := int([-1,0,1,0][k]) if row==1 else 0
	match id:
		"seal_judicator","dew_thorn_scribe","cinder_kiln_acolyte":
			_r(im,12-step,25,3,3,p.b);_r(im,18+step,25,3,3,p.d)
			_sole(im,11-step,27,p,4);_sole(im,18+step,27,p,4)
		"seal_veil_guard","ridge_axe_guard","oath_colossus","soul_revenant":
			_r(im,11-step,24,4,4,p.b);_r(im,18+step,24,4,4,p.d)
			_sole(im,10-step,27,p,5);_sole(im,18+step,27,p,5)
		"grave_chain_guard":
			_stamp(im,12-step,24,["pp","bd","pp","hh"],p)
			_stamp(im,18+step,24,["pp","db","pp","hh"],p)
		"induction_weaver":
			for i: int in range(3):
				var x:=int([7,15,24][i]);var stride:=step*(1 if i%2==0 else -1)
				_r(im,x,21,3,3,p.b);_r(im,x+stride,23,2,4,p.h);_sole(im,x-1+stride,27,p,4)
		"resonance_driller","deep_fault_carapace","abyss_devourer":
			var count:=4 if id=="deep_fault_carapace" else 3 if id=="resonance_driller" else 2
			for i: int in range(count):
				var x:=7+i*(4 if count==4 else 6);var stride:=step*(1 if i%2==0 else -1)
				_r(im,x-2,21,3,3,p.d);_r(im,x-3+stride,23,2,4,p.h);_sole(im,x-4+stride,27,p,4)
				_r(im,x+2,22,3,3,p.b);_r(im,x+4-stride,24,2,3,p.h);_sole(im,x+4-stride,27,p,4)
		"elder_treant":
			_stamp(im,6-step,23,["..bb..",".bhhb.","bbhhbb","hbb.hh"],p)
			_stamp(im,17+step,23,["..bb..",".bhhb.","bbhhbb","hbb.hh"],p)
			_r(im,10+step,25,3,3,p.h);_r(im,21-step,25,3,3,p.b)
		"rune_behemoth":
			for x: int in [8,13,20,25]:
				var stride:=step*(1 if x%2 else -1)
				_r(im,x+stride,22,3,5,p.b);_sole(im,x-1+stride,27,p,4)

static func _parts(im: Image,id: String,row: int,k: int,p: Dictionary,bob: int,lean: int) -> void:
	var thrust:=int([0,1,3,1][k]) if row in [2,5] else 0
	var lift:=int([0,1,3,1][k]) if row==5 else 0
	var breath:=int([0,0,1,0][k])
	match id:
		"seal_judicator":
			_stamp(im,3+lean,17-lift,["ppp.ppp","phppphp","ppphppp","bbbhbbb"],p)
			_stamp(im,24+thrust/2,13-lift+bob,["hhhh","hpph","haah","hbah","hhhh"],p)
			_r(im,22+lean,17-lift,3,3,p.h);_r(im,20+lean,13+bob+breath,3,2,p.b)
		"seal_veil_guard":
			_stamp(im,3+lean,12+bob,["..hhh..",".hppph.","hbbhbbh","h==h==h","h+=h+=h","h+=h+=h","hbbhbbh",".hbhbh.","..hhh.."],p)
			_stamp(im,24+thrust/2,20-lift,["hhpp","hbhh","hhhh",".bb.",".bb."],p)
			_r(im,21+lean,17-lift-breath,3,4,p.b)
		"grave_chain_guard":
			_r(im,20+lean,17-lift-breath,3,4,p.p)
			for i: int in range(3):
				_stamp(im,21+i*2+thrust/3,20-lift+i%2,["hh","hb","hh"],p)
			_stamp(im,26+thrust/3,15-lift,[".pp","pp.","p..","p..","pp."],p)
		"pall_lantern":
			_stamp(im,22,10+bob-lift+breath,["hhhhh","haphh","haaph","hapbh","hhhhh","..h.."],p)
			# Suspended curved oars end in broad blades beside the hull. They
			# never become upright load-bearing feet below the floating boat.
			_stamp(im,2,21-bob,["...hhh","..hph.",".hpph.","..hh.."],p)
			_stamp(im,24,20+bob,["hhh...",".hph..",".hpph.","..hh.."],p)
			_r(im,14,7+breath+bob,2,4,p.p)
		"induction_weaver":
			_stamp(im,25,12-lift-thrust/2,["h.h","hhh","h.h","hhh",".h.",".h."],p)
			_r(im,23,18-lift,3,3,p.h)
			_stamp(im,5,15+bob+breath,["hhh","hah","hbh","hah","hhh"],p)
		"rail_kite":
			var flap:=int([0,-1,0,1][k]) if row in [0,1,5] else -lean
			_stamp(im,3,9+flap,["hh......","hpph....","hbbphh..",".hbbpphh","..hbbpph","...hhbbh",".....hhh"],p)
			_stamp(im,22,9-flap,["......hh","....hpph","..hhbbph","hhppbbh.","hppbbh..","hbbhh...","hhh....."],p)
			_stamp(im,7,17+bob,["hhhh","haah","hbph","haah",".hh."],p)
			_stamp(im,23,17+bob,["hhhh","haah","hbph","haah",".hh."],p)
			_r(im,19,22-thrust/2,7+thrust/2,3,p.h);_r(im,21,22-thrust/2,4,1,p.p)
		"dew_thorn_scribe":
			_stamp(im,4,18-lift,[".hh.","hpph","haah","haah","hbah","hhhh"],p)
			_stamp(im,25,9-lift+bob,[".hh.","haph","haah",".hh.",".bb.",".bb.",".bb.",".bb.",".bb.",".bb.",".bb.",".bb.",".bb."],p)
			_r(im,21+lean,17-lift-breath,4,3,p.h)
		"canopy_glasswing":
			var flap:=int([0,-2,0,2][k]) if row in [0,1,5] else -lean
			_stamp(im,3,7+flap,[".hh.....","haphh...","hppaph..","hbppaph.",".hbppphh","..hbbphh","...hhhh."],p)
			_stamp(im,21,7-flap,[".....hh.","...hhpah","..hpapph",".hpappbh","hhpppbh.","hhpbbh..",".hhhh..."],p)
			_stamp(im,4,19-flap/2,["hhpph","hbbph",".hbh.","..h.."],p)
			_stamp(im,23,19+flap/2,["hpphh","hpbbh",".hbh.","..h.."],p)
			_stamp(im,19+thrust/2,15-lift,[".hhh","hpph",".bh.","hpph",".hhh"],p)
			_r(im,14,26+bob,2,2,p.h);_r(im,19,25-bob,2,2,p.b)
		"ridge_axe_guard":
			_stamp(im,24,9-thrust/2-lift,["hh.hh","hp.hph","hp.hph","hhahh","..b..","..b..","..b..","..b..","..b..","..b..","..b..","..b.."],p)
			_r(im,21+lean,17-lift-breath,4,4,p.h)
			_r(im,7+lean,17+bob+breath,4,4,p.p)
		"cinder_kiln_acolyte":
			_stamp(im,25,10-lift,["hhhh","hpph","haah","hbah","hhhh",".hh.",".hh.",".hh.",".hh.",".hh.",".hh.",".hh.",".hh."],p)
			_r(im,20+lean,18-lift-breath,5,3,p.h)
			_r(im,8+lean,9+bob+breath,2,2,p.h)
		"resonance_driller":
			for i: int in range(3):
				_stamp(im,24+thrust/2,12+i*4-lift,[".hh","hhh",".hh"],p)
			_r(im,20+lean,16+bob+breath,3,3,p.h)
		"deep_fault_carapace":
			_stamp(im,24+thrust/3,10-lift,["..ph",".pph","ppph",".hbh",".hbh"],p)
			_r(im,21+lean,18+bob+breath,3,2,p.a)
		"oath_colossus":
			_stamp(im,3,14+bob,[".hhhh.","hpppph","hbbhbh","h==hbh","h+=hbh","h+=hbh","hbbhbh","hbbhbh","hhhhhh"],p)
			_stamp(im,19+thrust/3,11-lift,["...hh....","..hpph...","hhbppbhhh","hpphhhhph","..hpph...","...hh....","...bb...."],p)
			_r(im,18+lean,19-lift-breath,5,3,p.h)
		"soul_revenant":
			_stamp(im,4+lean,17+bob+breath,["pppp","phhp","pbpp","pppp","hbbh"],p)
			_stamp(im,24+thrust/3,16-thrust/2-lift,["pppp","phhp","pbpp","pppp","hbbh"],p)
			_stamp(im,9+lean,21+bob,["==","+=","+=","bb"],p)
			_r(im,14+lean,15+bob+breath,2,3,p.a)
		"aether_engine":
			# Track links cycle as real surface motion; flywheel opens in cast.
			for i: int in range(5): _r(im,6+i*4+posmod(k,2),26,2,1,p.p)
			_stamp(im,9+lean,16+bob+breath,["hhh","hph","hbh","hhh"],p)
			_r(im,21,14-lift,3,3,p.a);_r(im,23+thrust/3,7-lift,3,2,p.h)
		"elder_treant":
			# Wood is a distinct local material, not another green leaf plane.
			# The dark central opening remains hollow and the team sash stays.
			_r(im,10+lean,16+bob,2,5,Color("795d3e"))
			_r(im,10+lean,16+bob,1,3,Color("ba9863"))
			_r(im,15+lean,15+bob,3,6,Color("795d3e"))
			_r(im,15+lean,15+bob,1,4,Color("ba9863"))
			_r(im,11+lean,21+bob,6,1,Color("b18c57"))
			_stamp(im,3+lean,14-lift-breath,[".bb.","bbhb","bhhb",".bb.",".bb.",".bb.","bbbh"],p)
			_stamp(im,24,16-thrust/2-lift,["hh.","hph","hph","bb.","bb.","bbb"],p)
			_r(im,11+lean,6+bob+breath,3,2,p.p)
		"rune_behemoth":
			# A hooked ivory tusk silhouettes above a dark lower jaw; the face
			# can now separate from the light stone backplate at world scale.
			_stamp(im,25+thrust/3,16-thrust/2,[".pp","ppp","pp.","p..","pp."],p)
			_r(im,25+thrust/3,21+bob,3,2,p.d)
			_r(im,26+thrust/3,20+bob,2,1,p.p)
			_r(im,25+thrust/3,23+bob,3,1,p.h)
			_r(im,8+lean,12+bob+breath,3,2,p.p)
			_r(im,23+lean,17+bob+breath,2,2,p.d)
		"fire_dragon":
			var flap:=int([0,-2,0,2][k]) if row in [0,1,5] else -lean
			_stamp(im,5,7+flap,[".....hh..","....hpph.","...hpbbph","..hpbbbh.",".hpbbbh..","hpbabh...","hbaabh...",".haah....","..hh....."],p)
			_stamp(im,16,6-flap,[".hh......","hpph.....","hbbph....",".hbbph...","..hbbph..","..hbbaph.","...hbaabh","....haah.",".....hh.."],p)
			_stamp(im,3,22+bob,[".hhh....","hbbbh...","hbhhhh..","hhh..hhh","......hh"],p)
			_stamp(im,14,24,["hh..hh","hph.hph",".pp..pp"],p)
			_r(im,26,13-thrust/2,3,2,p.h)
		"abyss_devourer":
			_stamp(im,23+thrust/3,20-thrust/2,[".hhh","hpph","hddh","hpph",".hhh"],p)
			_stamp(im,22+thrust/3,24-thrust/2,["hhhh","hpph","hhhh"],p)
			_r(im,9+lean,12+bob+breath,4,2,p.p)

static func _fallen(im: Image,id: String,k: int,p: Dictionary) -> void:
	# Deliberately drawn fallen silhouettes. No rotation/scaling of a standing
	# sprite; appendages settle separately in four distinct authored phases.
	var drop:=int([0,1,2,2][k]);var slip:=int([0,1,1,2][k])
	match id:
		"seal_judicator":
			_stamp(im,8,20+drop,["..hhhh........",".hhpphh.......",".hbbpbbhhh....","..bb===bbhhh..","...bbhhbbbpph.","..bbbbddbbpph.","...dddddd.hh.."],p)
			_stamp(im,3+slip,25,["ppp.ppp","phppphp","bbbhbbb"],p);_r(im,25,26-drop,3,2,p.h)
		"seal_veil_guard":
			_stamp(im,9,20+drop,["...hhhpph......","..hhbbpph......",".bb===bbbbbh...","bb+===bbbbhh...","..bbhhbbddhh...","...dddddddd...."],p)
			_stamp(im,3,23+slip,[".hhhhhh.","hpppppph","h==hbbbh","h+=hbbbh",".hhhhhh."],p)
		"grave_chain_guard":
			_stamp(im,6,22+drop,["hhhhhh...ppp...","hbbhhhppppppp..","..bbbppddpddp..","...bbbbppppp...","..hhddhhddhhh.."],p)
			for i: int in range(4): _r(im,20+i*2,27-i%2-slip/2,2,1,p.h)
		"pall_lantern":
			_stamp(im,4,19+drop,["...hh.................","..bhhhhhh.............",".b==bbh..hhh..hh......",".b+===bhh..hhpphhh....","..bbb==bhhhhhbbphhh...","...ddbbbbppbbppbbdd...",".....ddbbbhhhbbbdd....",".......ddddddddd......"],p)
			_stamp(im,24,24-slip,["hhhh","haah","hhhh"],p)
		"induction_weaver":
			_stamp(im,8,20+drop,["..hhhhhh.........",".hhpbbphh..hhh...","hbb...bbh.haah...","hbbbbbbbbhhbbh...",".bb==bbbbhhh.....",".bb+==bbddbb.....","..ddddddd..hhh..."],p)
			_stamp(im,3+slip,25,["hbbbh","hh.hh"],p)
		"rail_kite":
			_stamp(im,3,21+drop,["hh.............hh........","hpphh....hh...hpphh......",".hbbhhhhhbbhhhhbbbh......","..hhbbb+==bbbbbbhhh......","...hhbb+==bbhhhaaahh.....",".....hhhbbhhh..hhhh......"],p)
			_r(im,7+slip,26-drop,3,2,p.h);_r(im,25-slip,25,3,2,p.b)
		"dew_thorn_scribe":
			_stamp(im,8,22+drop,["..hh...hhh.......",".hphh.hhphh......","..hhppppbbbbb....","...bb+===bbbhh...","...dbbbhhhbbbh...","....ddddddddd...."],p)
			_stamp(im,3,25-slip/2,["hhhh","haah","hhhh"],p);_r(im,23,26-slip,6,2,p.h)
		"canopy_glasswing":
			_stamp(im,4,21+drop,["hhpahh.......hh.....","hppapphh..hhhpph....",".hbbpphhhhhbbbph....","..hhhhbb+==bbhhh....","..hpphhbb+==bbhh....","...hh...dddddhhhh..."],p)
			_r(im,23-slip,24-slip/2,4,2,p.h)
		"ridge_axe_guard":
			_stamp(im,6,21+drop,["..hhpphh...........",".hppbbpphhh........","hhbbb===bbbhpph....","hbbbp===bbbppph....",".hhbbhhhddbhhh.....","..dddddddddd......."],p)
			_stamp(im,24-slip,23,["hh.hh","hppph","hh.hh"],p)
		"cinder_kiln_acolyte":
			_stamp(im,5,21+drop,["hhhhh...............","hbhphhhh............","hbahhbbbhh..........","hbbhhhbb+==bbbpph...","hhhh..bb+==bbbpph...","......dddddddhhh...."],p)
			_stamp(im,25-slip,24,["hhhh","haah","hhhh"],p)
		"resonance_driller":
			_stamp(im,5,21+drop,["..hhpphhh..........",".hbbppbbbhh........","hbb==bbbbaaahh.....",".bb+==bbbbbhhh.....","..ddbbddbbdd.......","hhh..hh..hh..hh...."],p)
			_r(im,22+slip,24-slip/2,5,2,p.h)
		"deep_fault_carapace":
			_stamp(im,3,19+drop,["....hhh...hhhh............","..hhhpphhhppphh...........",".hhpphhbbhhpphhhhh........","hbbhhhbbbbhbbbbbphhhh.....","hbb==bbbbbb==bbphddph.....",".bb+==bbbbb+==bphppph.....","..ddbbhhhhhhbbddhhhh......","hhh..hh..hh..hh..hh......."],p)
			_r(im,24-slip,20+drop,3,3,p.p)
		"oath_colossus":
			_stamp(im,9,21+drop,[".hhppphh..........","hhbbhhpphh........","hbb===bbbhh.......",".bb+==bbbbbbhh....","..bbhhbbddbbhh....","...dddddddddd....."],p)
			_stamp(im,3,23,["hhhh","h==h","h+=h","hbbh","hhhh"],p)
			_stamp(im,23-slip,24,[".hh.","hphh",".hh."],p)
		"soul_revenant":
			_stamp(im,4,20+drop,[".pphhh.............","hppphhhhhpppp......","hbbphbbhddppph.....",".bbhhpphddppph.....","..hbbpphddpph......",".hpphhhpppphhpph...","..hhddhhddhhddhh..."],p)
			_r(im,24-slip,24-slip/2,4,3,p.p)
		"aether_engine":
			_stamp(im,3,20+drop,["........hhhh.............","....hhhphbbhhh...........","..hhpphhhbbhbbphh........",".hbbb==bbhhbaabhh........",".hbb+==bbbhhaabhh........","..hhhhhhhhhhhhhh.........",".hbbddbbddbbddbbhh.......","..ddddddddddddddd........"],p)
			_r(im,23-slip,23-slip,4,2,p.h)
		"elder_treant":
			_stamp(im,3,19+drop,[".hhh...hh................","hhpphhhbphh..............","hpphbbhhhbbh.............",".hbbphhbbppbbhhh.........","..hhbbbbhdddpbbbhh.......","...hhbbbhdddpbbbbbh......","hhh..hhbbhhhbbhhhhh......",".hhhhh..hhhhhhh.........."],p)
			_r(im,12,23+drop,6,1,Color("b18c57"))
			_r(im,12,24+drop,6,1,Color("795d3e"))
			_r(im,14,24+drop,2,1,p.d)
			_r(im,24-slip,25-slip,4,2,p.h)
		"rune_behemoth":
			_stamp(im,3,20+drop,["....hhh...hhh............","..hhppphhhppphhh.........",".hpphhbbhhbbhhbbphh......","hbbhbbbbb==bbbbppph......","hbbbbb+==bbbbppddph......",".hbbhhbbhhhhhhhppph......","..ddhhddhhddhhdddd......."],p)
			_r(im,24-slip,24-slip/2,3,3,p.p)
			_r(im,24-slip,24+drop,3,1,p.d)
			_r(im,25-slip,23+drop,2,1,p.p)
		"fire_dragon":
			_stamp(im,3,20+drop,["....hhhh......hh.........","...hphbbhh...hpph........","..hpbbbhhbbhhhbbphh......",".hpbbbhbbbaaabbbppph.....","hbbbhhhbbbaaabphddph.....",".hhh..hbb==bbphpppph.....","..hhhhbb+==bbhhhhhh......","......dddddddd..........."],p)
			_r(im,24-slip,23-slip/2,3,2,p.h)
		"abyss_devourer":
			_stamp(im,3,20+drop,["....hhhhhhhh.............","..hhppphbbhpphh..........",".hpphhbbbbhhppphh........","hbbhhbbb==bbbbphppph.....","hbbbbb+==bbbbphddpph.....",".hbbhhhhbbhhhhpppph......","..ddhhddhhddhhhhhh......."],p)
			_r(im,23-slip,24-slip/2,3,3,p.p)

static func author_image(id: String,row: int,k: int) -> Image:
	var im:=Image.create(32,32,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	if id not in IDS or row<0 or row>5 or k<0 or k>3: return im
	var p:=_palette(id)
	if row==4:
		_fallen(im,id,k,p);_outline(im);return im
	var bob:=int([0,-1,0,0][k]) if row in [0,1] else 0
	var lean:=int([0,-1,1,0][k]) if row==3 else int([0,-1,1,0][k]) if row in [2,5] else 0
	var base: Array=BODIES[id]
	var width:=0
	for line: String in base: width=maxi(width,line.length())
	var x:=16-width/2+lean
	var y:=26-base.size()+bob
	if id in ["pall_lantern","rail_kite","canopy_glasswing","fire_dragon"]: y-=2
	_legs(im,id,k,row,p)
	_stamp(im,x,y,base,p)
	_parts(im,id,row,k,p,bob,lean)
	if row==3:
		# Actual recoil: bent shoulder/arm or an opened chassis seam, not a
		# flat full-body flash. Position and width change across the four cells.
		_r(im,12+lean,18+k%2,3,2,p.d)
		_r(im,16+lean,19-k%2,2,2,p.h)
	_outline(im)
	return im
