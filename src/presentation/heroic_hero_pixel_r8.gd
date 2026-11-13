extends RefCounted
## R8 original 32-cell pixel masters. Presentation only: no combat or RNG.
## Every mark is a filled source cell; no runtime vector silhouettes or blur.
const Palette=preload("res://src/presentation/strategic_side_palette.gd")
const TeamMaterial=preload("res://src/presentation/heroic_team_material_m70.gd")
const VERSION:="outposts-v4-hero-pixel-r8"
const SIZE:=Vector2i(32,32)
const FOOT:=Vector2(16,29)
const MAX_FRAMES:=256
const INK:=Color("171820")
const IDS:=["OATH_REAVER","BRIDGE_VANGUARD","RELIC_REAVER","OSSUARY_KNIGHT","PISTON_FENCER","RIVET_LEGIONARY","THORN_REAVER","ANTLER_WARRIOR","SLAG_DANCER","BASALT_CHAMPION","PRISM_MANTIS","CARAPACE_WARRIOR","SUNGLASS_SCRIBE","CINDER_TESTATOR","FLUX_BOMBARDIER","POLLEN_COMET","OBSIDIAN_CANTOR","MYCELIAL_CATALYST","EMBER_CAVALIER","SPORE_STALKER"]
const FACTIONS:={"OATH_REAVER":"HUMAN","BRIDGE_VANGUARD":"HUMAN","RELIC_REAVER":"UNDEAD","OSSUARY_KNIGHT":"UNDEAD","PISTON_FENCER":"MACHINE","RIVET_LEGIONARY":"MACHINE","THORN_REAVER":"FOREST","ANTLER_WARRIOR":"FOREST","SLAG_DANCER":"HIGHLAND","BASALT_CHAMPION":"HIGHLAND","PRISM_MANTIS":"UNDERGROUND","CARAPACE_WARRIOR":"UNDERGROUND","SUNGLASS_SCRIBE":"HUMAN","CINDER_TESTATOR":"UNDEAD","FLUX_BOMBARDIER":"MACHINE","POLLEN_COMET":"FOREST","OBSIDIAN_CANTOR":"HIGHLAND","MYCELIAL_CATALYST":"UNDERGROUND","EMBER_CAVALIER":"HIGHLAND","SPORE_STALKER":"UNDERGROUND"}
const RAMPS:={"HUMAN":["514b40","9b8862","e2ce96","80a3a6"],"UNDEAD":["453947","897486","d5ccb1","80ada3"],"MACHINE":["394751","718d99","c3cec3","c68b52"],"FOREST":["314538","71935c","d2cd91","b3839d"],"HIGHLAND":["48404a","897a77","d6c5a1","ce8650"],"UNDERGROUND":["41334d","81668f","c4afbc","89ad70"]}
const FEATURES:={
	"OATH_REAVER":["偏斜布签冠","长断页剑与单肩折页披挂"],"BRIDGE_VANGUARD":["宽桥梁肩架","方背篓与双手钉槌"],
	"RELIC_REAVER":["半面纱罩","不对称弯钩刃与悬名牌"],"OSSUARY_KNIGHT":["船肋胸甲","双层破帆与长辕钩镰"],
	"PISTON_FENCER":["开口焊罩","侧飞轮与一长一短活塞刃"],"RIVET_LEGIONARY":["四片背部散热栅","梯胸厚板与剪铆长柄"],
	"THORN_REAVER":["单侧荆棘眼罩","嫁接镰与种匣短翼"],"ANTLER_WARRIOR":["空心枝角","弧枝盾与绳结短矛"],
	"SLAG_DANCER":["冷热双刃","短炉裙与斜背淬水筒"],"BASALT_CHAMPION":["错层玄武岩肩","横口重槌与短烟柱"],
	"PRISM_MANTIS":["六折节足","偏心晶冠与双折棱刃"],"CARAPACE_WARRIOR":["四足低宽壳","双层通气盖与铲角"],
	"SUNGLASS_SCRIBE":["宽方遮光帽","不对称三日镜与折书签杖"],"CINDER_TESTATOR":["低垂纸冠与煤痕脸","残页帘与可张合遗嘱册"],
	"FLUX_BOMBARDIER":["偏置磁环肩架","错位扁口线圈炮与绝缘鳍"],"POLLEN_COMET":["开放花萼披肩","三束弯萤须与彗籽细杖"],
	"OBSIDIAN_CANTOR":["弧背碎玻扇","错层曜片与方口陶歌匣"],"MYCELIAL_CATALYST":["四足矮囊身","双釉面酸囊与分叉玻璃滴管"],
	"EMBER_CAVALIER":["缺口羊皮兜帽","三支背矛与单手投矛器"],"SPORE_STALKER":["六足低伏分甲","分离双轨背弩与侧试剂囊"]}
# Separate identity masters, authored at the final source grid. Symbols:
# k=ink,d=shade,b=material,h=edge light,a=secondary material,t=team,s=skin.
# This is not a downsample of M66/M68 art. Blank cells preserve negative space.
const MASTERS:={
"OATH_REAVER":[".......hh.......",".....hb.h.......","....bdbh........","....bbssb.......","....bsssk.......",".....sshh.......","..hdbbbdk.......",".hbbhtttbd......",".bbddtttdbb.....","..bdhtttbdd.....","..bhdtttdb......","..ddhbbhdd......","...bbkkbb.......","...bbtthb.......","...dbttbd.......","...dbbbbd.......","...dd..dd......."],
"BRIDGE_VANGUARD":["......bb........",".....hbbh.......",".....bssb.......",".....sssk.......",".....hssh.......",".hhhbbbbbbhh....",".bbdhbbhdbbb....",".dhdbttttbdd....",".dbbttthttbd....","..hbtttthtb.....","..dbtttttbd.....","..dbbhhhbbd.....","..dbbdkdbbd.....","..hbbbbbbbd.....","...dbbbbbd......","...dd...dd......","...dd...dd......"],
"RELIC_REAVER":["......dd........",".....hdbd.......","....hbbbhd......","....bbhhhd......","....bhkkhd......",".....hhdad......","...dbbbddd......","..bdttdddb......","..bttbddhbd.....","..bddbbddbd.....","..ddbttdbd......","...hbdtdad......","...dbbkbd.......","...dhbddbd......","..dbddbdabd.....","..dd...dd.......","...d....d......."],
"OSSUARY_KNIGHT":[".......dd.......",".....hdbbd......",".....bkhhb......",".....hkhhd......",".....hbbhd......","..hhdhhhbbd.....",".hbhdhkhdhhbd...",".bhhdhhhddhbd...","..dhkhkhkhbd....","..dhhhhbhhbd....","..dhkhkhkhbd....","..dbhhhhbbbd....","..dbttttttbd....","..dbttbbttbd....","..dbbhhhbbbd....","...ddbdbdd......","...dd...dd......"],
"PISTON_FENCER":["......dd........",".....hbhd.......","....hbbabd......","....bkkkab......","....hbbbhd......",".....dhdd.......","..abbbhbbdd.....","..bdhhttbbbd....","..bbttttbdbd....","..bdtthtbdbd....","..bdttttbbbd....","...hbhhbddd.....","...dhbkhd.......","...bhbbhb.......","...bdkkdb.......","...dd..dd.......","...hd..hd......."],
"RIVET_LEGIONARY":["......ddd.......",".....hbbbd......",".....bakkd......",".....hbbbd......","..hbbhhhbbh.....",".hbbbdbbbhbbd...",".bbbdhttttbbd...",".bdhbttthtbbd...",".bddbtttttbbd...",".bdhbttthtbbd...","..bbbhhhbbbd....","..hbbdbdhbbd....","..dbbhhhbbbd....","...bbddbbbd.....","...bb..bbb......","...dd..ddd......","...hd..hdd......"],
"THORN_REAVER":["......ab........",".....hbb........","....bbasb.......","....bsskk.......","....bsssb.......",".....bhbb.......","...abbhb........","..bbbttbd.......","..hbtttbb.......","..dbtttthb......","...bbttbb.......","...dhbdhb.......","...dbbtbd.......","..bbhbbbd.......","..bdb..db.......","...dd..bd.......","...d...dd......."],
"ANTLER_WARRIOR":["..h.......h.....","..bh.....hb.....","...hb...hb......","....hbbbh.......","....bbssb.......",".....sssk.......",".....hssh.......","..hbbdhhbbh.....","..bbhdttbbbd....","..dhbtttbhbd....","..dbbtttbbbd....","...dbhhhbbd.....","...hbbttbd......","...dbbbhbd......","...dbbbbd.......","...dd..dd.......","...hd..hd......."],
"SLAG_DANCER":["......dd........",".....dbbb.......",".....hbssd......",".....ssskd......",".....bssbd......","...bbhhhbd......","..dbbdttbb......","..hbttttbbd.....","..dbtttthbd.....","...bbtttbb......","...bhbbhbd......","..abbhbbbad.....","..hbbadbbhd.....","..dbbabbdbd.....","..ddd..ddd......","...bd..bd.......","...hd..hd......."],
"BASALT_CHAMPION":["......ddd.......",".....hbbbd......",".....bbssb......",".....hsskb......","....hhbbbd......",".hhbbbhbbh......",".bbbdhbdbbbhd...",".dbbdttttbhbd...",".hbbdtthtbbbd...","..bbdttttbdd....","..dbbhhhbbbd....","..dhbbbdhhbd....","..dbbhhbbbbd....","..dbbbddbbbd....","...dbb..bbd.....","...hdd..ddd.....","...hd...hdd....."],
"PRISM_MANTIS":["........h.......","......hbb.......","......bha.......",".....hbabh......",".....bbahbd.....","......hkkb......","......bbbd......","....hbbbhbbd....","...hbbtttbbbd...","..hbhttthtbbbd..","..dbbtttttbhbd..","..dbbhtttbbbd...","...hbbbhhbbd....","....ddbbbdd.....",".....ddddd......","................","................"],
"CARAPACE_WARRIOR":[".......hh.......",".....hbbbbh.....","....hbbddbbh....","...hbbhkbhbbh...","..hbbdhhbbdbbd..",".hbbddbbddhbbbd.",".bbdhtttthbbhbd.",".dbbttthttbbdbd.",".hbbttttttbdhbd.","..bbdhhhbbbhbd..","..dbbhbbbhbbd...","...dhbbbdbbd....","....bbddbbb.....","....ddddddd.....","................","................","................"],
"SUNGLASS_SCRIBE":["....hhhhhh......","...hbbbbbbh.....","..hbbdbbdbbh....","....bsssh.......","....hsskh.......",".....hshh.......","..hbddhhbb......","..bbhttttbd.....","..dbttthtb......","..dbttttbb......","...bhbbhbd......","..hdbtthbbd.....","..dbtttthbd.....","..dbhbtbbbd.....","..dbdbdbdbd.....","...hd..hd.......","...hd..hd......."],
"CINDER_TESTATOR":[".......dh.......","......dbhb......",".....hbdbdd.....","....hbbbdbd.....","....dbhhbb......",".....hkkhd......",".....bhhbd......","..dbbbddbbd.....","..bttbddbbd.....","..bttbdhbbbd....","..dbtthdbbbd....","..dbtthdbbd.....","..dbhbbhbbd.....","..hbbddbbbd.....","..dbbhbdbbd.....","..dbddbddbd.....","..dd...dddd....."],
"FLUX_BOMBARDIER":[".......dd.......",".....hbbbd......",".....bbakd......",".....hbbbd......","..hbbdhbbbd.....","..bbdhhbbbd.....",".hbbdtttthbbd...",".bbbdtttbbhbd...",".dbbdhbbhbbbd...","..hbbttttbbd....","..bbhthtbbbd....","..dbbhhhbbbd....","...hbbhdbbd.....","...ddbbddd......","...ddd.ddd......","...hd...hd......","...hd...hd......"],
"POLLEN_COMET":["....a.....a.....","...ab.....ba....","....ha...ah.....",".....abbba......",".....hssbh......",".....ssskb......",".....hssh.......","..abbhhhhbba....","..hahbttbbah....","..abhhttthba....","...abbtttba.....","...hbttthbd.....","...bbhbbhbd.....","...dbaabdb......","....dbbbd.......","....hd.hd.......","....h..h........"],
"OBSIDIAN_CANTOR":["......ddd.......",".....hbbbd......",".....bkkbd......",".....bahbd......",".....hbbhd......","...hbdhbbhd.....","..bbdhbbhbbd....",".hbdtttttbbd....",".dbbtttthhbd....","..dbttttbbd.....","..dbhbbhbbbd....","..dbahbbhbbd....","..dbbbahbbbd....","..hbbdhdbbbd....","..dbdbhbbbd.....","...hd..hdd......","...hd..hdd......"],
"MYCELIAL_CATALYST":["......a...a.....",".....hah.hah....","......bh.hb.....",".....dbbbdd.....","....dbahabbd....","...hbaahahbbd...","..hbaahabbahbd..","..bbaahbbhaabd..","..dbbahbbhaabd..","..dbtttthhbbbd..","..dbttthbbhbd...","...hbbhbbhbd....","....dbbbbdd.....",".....ddddd......","................","................","................"],
"EMBER_CAVALIER":["......ddd.......",".....hbdbd......","....hbbssbd.....","....dbsskbd.....",".....bsshdd.....",".....hbbbd......","..bbbdhbbd......","..hbbttttbd.....","..dbttthtbd.....","..dbtttttbb.....","...bhhhbbbd.....","...dbttbhbd.....","..bbdtttbbd.....","..hbdbhbbbd.....","..dbdbdbdd......","...dd..dd.......","...hd..hd......."],
"SPORE_STALKER":["................",".......hbb......","......hbbbd.....","......bakbd.....","....hbbbbhbd....","...hbbdhbbbd....","..hbbddbbdhbd...","..bbdttthbbbd...","..dbtttttbhbd...","..dbbhhhbbbd....","...hbbdhbbd.....","....dbbbbdd.....",".....ddddd......","................","................","................","................"]}
# Fallen kit is authored horizontally, independently from the standing master.
# The fragments retain each hero's identifying prop after the body settles.
const FALLEN_KIT:={
	"OATH_REAVER":[".....hh","hbbbbbd","..a...."],"BRIDGE_VANGUARD":["hhbbhh.","dbkkbd.","..bb..."],
	"RELIC_REAVER":["hh...hh",".hbbbh.","..b...."],"OSSUARY_KNIGHT":["h.h.h.h","bbbbbbd","..d.d.."],
	"PISTON_FENCER":[".hh.hhh","hbkkbbb",".hh...."],"RIVET_LEGIONARY":["h.h..h.","dbbdbbd",".dddd.."],
	"THORN_REAVER":["..hbbh.","hbb..b.","....ba."],"ANTLER_WARRIOR":[".h...h.","..bhb..","..bbb.."],
	"SLAG_DANCER":["aa...hh",".aabbh.","..bh..."],"BASALT_CHAMPION":["hbbhhb.","dbdhbd.","..bb..."],
	"PRISM_MANTIS":[".hh..hh","bb.bbb.","..h..h."],"CARAPACE_WARRIOR":["..hh...","hbbhbbh",".dkdkd."],
	"SUNGLASS_SCRIBE":["hh..hh.","habhbah",".hh.hh."],"CINDER_TESTATOR":["hhahh..","hbahbhd",".d.d.d."],
	"FLUX_BOMBARDIER":[".hhh...","hbkkbbh",".dddd.."],"POLLEN_COMET":["a.h.a..","ababa..",".b.h.a."],
	"OBSIDIAN_CANTOR":[".hbbbd.","hkkbbbd",".ddddd."],"MYCELIAL_CATALYST":[".ha.ah.","hbaaabh",".hh.hh."],
	"EMBER_CAVALIER":["h..h..h","bbbbbbd",".b..b.."],"SPORE_STALKER":["hb..bh.",".hbbh..","hbbbddh"]}
static var _frames:Dictionary={}
static var _order:Array[String]=[]
static var _bakes:int=0
static func supported(unit:Dictionary,_pose:Dictionary={})->bool:
	return str(unit.get("unit_type",""))=="hero" and str(unit.get("hero_archetype","")) in IDS
static func reset_cache()->void:
	_frames.clear();_order.clear();_bakes=0
static func _box(im:Image,x:int,y:int,w:int,h:int,c:Color)->void:
	var r:=Rect2i(x,y,w,h).intersection(Rect2i(Vector2i.ZERO,SIZE))
	if r.has_area():im.fill_rect(r,c)
static func _path(im:Image,points:Array,c:Color,w:int=1)->void:
	# Bresenham cells, never a Canvas line. Thick paths retain cell corners.
	for n:int in range(1,points.size()):
		var at:Vector2i=points[n-1];var end:Vector2i=points[n]
		var dx:=absi(end.x-at.x);var dy:=-absi(end.y-at.y)
		var sx:=1 if at.x<end.x else -1;var sy:=1 if at.y<end.y else -1
		var error:=dx+dy
		while true:
			_box(im,at.x-w/2,at.y-w/2,w,w,c)
			if at==end:break
			var e2:=2*error
			if e2>=dy:error+=dy;at.x+=sx
			if e2<=dx:error+=dx;at.y+=sy
static func _stamp(im:Image,rows:Array,x:int,y:int,colors:Dictionary)->void:
	for py:int in range(rows.size()):
		var row:String=rows[py]
		for px:int in range(row.length()):
			var code:=row.substr(px,1)
			if colors.has(code):_box(im,x+px,y+py,1,1,colors[code])
static func _colors(id:String,side:String)->Dictionary:
	var ramp:Array=RAMPS[FACTIONS[id]]
	return {"k":INK,"d":Color(ramp[0]),"b":Color(ramp[1]),"h":Color(ramp[2]),"a":Color(ramp[3]),"t":Palette.side_color(side),"s":Color("c6a47c") if FACTIONS[id] not in ["UNDEAD","UNDERGROUND"] else Color("c8bea5")}
static func _legs(im:Image,id:String,c:Dictionary,stride:int,bob:int,brace:int)->void:
	if FACTIONS[id]=="UNDERGROUND":
		var count:=3 if id in ["PRISM_MANTIS","SPORE_STALKER"] else 2
		for n:int in range(count):
			for side:int in [-1,1]:
				var ox:=12+n*3
				var bend:=stride*(1 if n%2==0 else -1)
				var knee:=Vector2i(ox+side*(5+brace),23+bob+bend/2)
				var tip:=Vector2i(ox+side*(7+brace),28-bend/2)
				_path(im,[Vector2i(ox,20+bob),knee,tip],c.d,2)
				_path(im,[knee,tip-Vector2i(side,1)],c.b,1)
				_box(im,knee.x,knee.y,2,1,c.h)
		return
	for side:int in [-1,1]:
		var x:=16+side*3
		var knee:=Vector2i(x+side*brace,24+bob)
		var foot:=Vector2i(x+stride*side,28)
		_path(im,[Vector2i(x,21+bob),knee,foot],c.d,3)
		_path(im,[knee,foot-Vector2i(0,1)],c.b,1)
		_box(im,foot.x-1,28,4,1,c.d);_box(im,foot.x-1,27,2,1,c.h)
static func _backs(im:Image,id:String,c:Dictionary,bob:int,k:int)->void:
	match id:
		"OATH_REAVER":
			_stamp(im,["..dbb..",".dhbbd.",".dbtbd.",".bttbd.",".dbbdd.",".hbdbd.",".dbdd..","..d...."],5,14+bob,c)
		"BRIDGE_VANGUARD":
			_stamp(im,["dhbbd","bkkkb","hbbhb","bkkkb","hbbhb","dbbbd"],6,11+bob,c)
			_box(im,5,12+bob,21,2,c.d);_box(im,5,12+bob,21,1,c.b)
			for x:int in [6,10,20,24]:_box(im,x,12+bob,1,1,c.h)
		"RELIC_REAVER":
			_path(im,[Vector2i(8,13+bob),Vector2i(5,20+bob),Vector2i(8,24)],c.d,2)
			_box(im,5,20+bob,2,3,c.h);_box(im,5,21+bob,1,1,c.a)
		"OSSUARY_KNIGHT":
			_stamp(im,["..hbd....",".hbbbd...",".dbbbhd..",".dbttbbd.",".hbtbdbd.",".dbtbdbd.",".dbbb.dd.","..dbd.d..","..dd....."],4,10+bob,c)
			_stamp(im,["..hbd",".hbbd",".dbbd",".dbtd",".dbbd","..dd."],20,14+bob,c)
		"PISTON_FENCER":
			_stamp(im,[".dbbd.","dbhhbd","bhkkhb","bhkkhb","dbhbbd",".dddd."],5,12+bob,c)
		"RIVET_LEGIONARY":
			for n:int in range(4):
				_box(im,5+n*3,8+bob,2,7,c.d);_box(im,5+n*3,8+bob,1,5,c.b);_box(im,5+n*3,9+bob,1,1,c.a)
		"THORN_REAVER":
			_stamp(im,[".hb.....bh.","hbbd...dbbh","bhd.....dhb","dbd.....dbd"],5,14+bob,c)
			_box(im,5,17+bob,3,4,c.d);_box(im,6,18+bob,1,2,c.a)
		"ANTLER_WARRIOR":
			_path(im,[Vector2i(9,20+bob),Vector2i(6,25),Vector2i(8,27)],c.b,2)
			_box(im,5,25,2,2,c.a)
		"SLAG_DANCER":
			_stamp(im,[".hh.","hbbd","dbbd","dbbd",".dd."],5,16+bob,c)
		"BASALT_CHAMPION":
			_box(im,9,6+bob,3,8,c.d);_box(im,10,7+bob,1,5,c.b);_box(im,9,6+bob,3,1,INK)
		"SUNGLASS_SCRIBE":
			_stamp(im,[".hhh....","habbh...","hbabh...",".hhh...."],3,7+bob,c)
			_stamp(im,[".hh.","hbah","habh",".hh."],22,5+bob,c)
			_stamp(im,[".hh.","hbah","habh",".hh."],5,15+bob,c)
			_path(im,[Vector2i(6,11+bob),Vector2i(12,14+bob),Vector2i(24,8+bob)],c.d,2)
		"FLUX_BOMBARDIER":
			_stamp(im,[".hh....","hbdb...","bkkb...","hbdb...",".hh...."],4,9+bob,c)
			_stamp(im,[".hh.","hbdb","bkkb","bkkb","hbdb",".hh."],22,6+bob,c)
			for n:int in range(3):_box(im,7+n*3,5+bob,1,5+n%2,c.d);_box(im,7+n*3,5+bob,1,2,c.h)
		"POLLEN_COMET":
			_stamp(im,[".aa.......a..","abba.....abba","hbba.....abbh","dbbd.....dbbd",".bb.......bb.",".db.......bd.","..d.......d.."],3,12+bob+(k%2),c)
		"OBSIDIAN_CANTOR":
			_stamp(im,[".h..............",".bh..h....h.....",".dbhdhb..hb.....","..dbhbhdhbb.....","...dbhbdbbd.....","....dbbbbd......",".....dddd......."],2,7+bob,c)
		"EMBER_CAVALIER":
			for n:int in range(3):
				_path(im,[Vector2i(8+n*2,21+bob),Vector2i(5+n*3,5+n)],c.d,2)
				_box(im,4+n*3,4+n,3,2,c.b);_box(im,5+n*3,3+n,1,1,c.h)
			_stamp(im,[".dbb..",".hbbd.",".dbbd.",".btbd.",".dbbd.",".dbdd.","..dd.."],5,16+bob,c)
		"SPORE_STALKER":
			_box(im,5,17+bob,3,4,c.b);_box(im,5,18+bob,2,2,c.a)
static func _weapon(im:Image,id:String,c:Dictionary,hand:Vector2i,off:Vector2i,k:int,action:String)->void:
	var x:=hand.x;var y:=hand.y
	var strike:=action=="ATTACK"
	match id:
		"OATH_REAVER":
			_path(im,[hand,hand+Vector2i(1,-5),hand+Vector2i(3,-12)],c.b,2)
			_path(im,[hand+Vector2i(1,-4),hand+Vector2i(3,-12)],c.h,1)
			_box(im,x-2,y-2,6,1,c.d);_box(im,x+1,y-10,2,1,c.a)
		"BRIDGE_VANGUARD":
			_path(im,[off,hand,hand+Vector2i(2,-9)],c.d,2)
			_stamp(im,[".hbbhhh.","hbbdbbbd","dbbbhbbd",".dddddd."],x-2,y-11,c)
		"RELIC_REAVER":
			_path(im,[off,off+Vector2i(-3,-6),off+Vector2i(0,-9)],c.b,2)
			_path(im,[hand,hand+Vector2i(2,-8),hand+Vector2i(5,-10),hand+Vector2i(5,-7)],c.h,1)
			_box(im,x,y-3,3,1,c.a)
		"OSSUARY_KNIGHT":
			_path(im,[Vector2i(x-2,27),hand+Vector2i(1,-10),hand+Vector2i(5,-12),hand+Vector2i(6,-9)],c.b,2)
			_path(im,[hand+Vector2i(1,-10),hand+Vector2i(5,-12)],c.h,1)
		"PISTON_FENCER":
			_path(im,[hand,hand+Vector2i(5,-7),hand+Vector2i(6,-10)],c.d,3)
			_path(im,[hand,hand+Vector2i(5,-7),hand+Vector2i(6,-10)],c.h,1)
			_box(im,x+1,y-3,3,2,c.b);_box(im,off.x-2,off.y-4,2,5,c.a)
		"RIVET_LEGIONARY":
			_path(im,[off,hand,hand+Vector2i(1,-10)],c.d,2)
			_path(im,[hand+Vector2i(1,-8),hand+Vector2i(-2,-12)],c.h,2)
			_path(im,[hand+Vector2i(1,-8),hand+Vector2i(5,-11)],c.b,2)
			_box(im,x,y-7,3,2,c.a)
		"THORN_REAVER":
			_path(im,[hand,hand+Vector2i(2,-9),hand+Vector2i(6,-12),hand+Vector2i(6,-9)],c.b,2)
			_path(im,[hand+Vector2i(2,-9),hand+Vector2i(5,-11)],c.h,1)
			_box(im,x+2,y-8,2,2,c.a)
		"ANTLER_WARRIOR":
			_stamp(im,["..hh..",".hbbd.","hbtbbd","dbttbd","dbbbbd",".dbbd.","..dd.."],off.x-3,off.y-3,c)
			_path(im,[hand+Vector2i(0,5),hand+Vector2i(2,-10)],c.b,2)
			_box(im,x+1,y-11,3,2,c.h)
		"SLAG_DANCER":
			_path(im,[off,off+Vector2i(-3,-10)],c.a,2);_path(im,[off+Vector2i(-1,-2),off+Vector2i(-3,-10)],c.h,1)
			_path(im,[hand,hand+Vector2i(4,-12)],c.b,2);_path(im,[hand,hand+Vector2i(4,-12)],Color("aac9ca"),1)
		"BASALT_CHAMPION":
			_path(im,[off,hand,hand+Vector2i(2,-9)],c.d,2)
			_stamp(im,[".hbbhhh.","hbbhbbbd","dbbhbbhd","dbbdbbbd",".dddddd."],x-2,y-12,c)
		"PRISM_MANTIS":
			for at:Vector2i in [off,hand]:
				var side:=-1 if at==off else 1
				_path(im,[at,at+Vector2i(side*4,-6),at+Vector2i(side*2,-11)],c.b,2)
				_path(im,[at+Vector2i(0,-1),at+Vector2i(side*3,-6),at+Vector2i(side*2,-10)],c.h,1)
		"CARAPACE_WARRIOR":
			_stamp(im,["...hh..","..hbbh.",".hbbbbh","hbbdbbd",".dbbbd.","..ddd.."],x-2,y-4,c)
		"SUNGLASS_SCRIBE":
			_path(im,[hand+Vector2i(-1,7),hand+Vector2i(1,-9)],c.b,2)
			_stamp(im,[".hh.","hbah","habh",".hh."],x,y-12,c)
			_stamp(im,["hbbhbbh","bhhahhb","bhdadhb",".hhahh."],off.x-3,off.y-2,c)
		"CINDER_TESTATOR":
			var width:=3 if action!="CAST" else int([2,2,3,4,4,3,3,2][k%8])
			_box(im,x-width,y-3,width*2+1,6,c.d)
			_box(im,x-width+1,y-2,width-1,4,c.h);_box(im,x+1,y-2,width-1,4,c.h)
			_box(im,x,y-2,1,5,c.a)
			_box(im,off.x-1,off.y-1,3,4,c.b);_box(im,off.x,off.y,1,2,c.h)
		"FLUX_BOMBARDIER":
			_stamp(im,[".hbbbhd...","hbbhbbbhhd","dbbkkkbbbd",".hbbhbbhdd","..dddddd.."],x-2,y-4,c)
			_box(im,x+4+(1 if strike and k==1 else 0),y-3,3,1,c.a)
		"POLLEN_COMET":
			_path(im,[hand+Vector2i(-1,6),hand+Vector2i(1,-6),hand+Vector2i(4,-9)],c.b,1)
			_stamp(im,[".ah.","abah",".ba.","..a."],x+2,y-11,c)
		"OBSIDIAN_CANTOR":
			_stamp(im,[".hbbbh.","hbbdbbd","bkkkbbd","bkhkbbd","dbbbbbd",".ddddd."],x-3,y-3,c)
			_box(im,off.x-1,off.y-1,3,3,c.a)
		"MYCELIAL_CATALYST":
			_path(im,[hand-Vector2i(4,0),hand-Vector2i(2,2),hand+Vector2i(3,-4)],c.h,2)
			_box(im,x+2,y-6,2,3,c.a);_box(im,x+3,y-5,1,1,c.d)
		"EMBER_CAVALIER":
			_path(im,[hand-Vector2i(4,0),hand+Vector2i(4,-2)],c.d,3)
			_path(im,[hand-Vector2i(5,2),hand+Vector2i(6,-4)],c.b,1)
			_box(im,x+5,y-5,3,2,c.h)
		"SPORE_STALKER":
			var spread:=2+k%2 if action=="CAST" else 2
			_path(im,[hand+Vector2i(-5,-spread),hand+Vector2i(2,-spread-2),hand+Vector2i(4,0),hand+Vector2i(2,spread+2),hand+Vector2i(-5,spread)],c.b,2)
			_path(im,[hand-Vector2i(4,0),hand+Vector2i(6,0)],c.h,1)
			_box(im,x-3,y-1,4,3,c.d)
static func _fallen(im:Image,id:String,c:Dictionary,k:int)->void:
	# Independently posed broken outline and dropped kit; no scaled standing image.
	var burrow:bool=str(FACTIONS[id])=="UNDERGROUND"
	var rows:Array=["....ddhhdd........","..dhbbdbbbbd......",".dbbhbtttbbhbd....",".hbdbtttthbbbd....","..dbbhbbbhbbd.....","...ddbddddbd......"] if burrow else [".........ddhbbd...","...ddhbbdhbkkbd...","..dbbhbbdhbbhbd...",".hbbttthbbhbbd....",".dbbtttbbdbbd.....","..dhbbhdbddd......"]
	_stamp(im,rows,5,22,c)
	if burrow:
		for x:int in [6,11,22,26]:_path(im,[Vector2i(x,25),Vector2i(x-2,22),Vector2i(x-3,24)],c.b,1)
	var metal:Color=c.h if id not in ["THORN_REAVER","ANTLER_WARRIOR","POLLEN_COMET"] else c.b
	_path(im,[Vector2i(5,27),Vector2i(10,28),Vector2i(18,28)],metal,1)
	_box(im,7,27,2,1,c.a)
	_stamp(im,FALLEN_KIT[id],3+k%2,24,c)
	# Four settled collapse poses move separate limbs/kit, not uniform compression.
	_box(im,4+k,25-k%2,2,1,c.b);_box(im,24-k,27,3,1,c.d)
static func _outline(im:Image)->void:
	var source:=im.duplicate() as Image
	for y:int in range(1,31):
		for x:int in range(1,31):
			if source.get_pixel(x,y).a<0.5:continue
			for d:Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				if source.get_pixelv(Vector2i(x,y)+d).a<0.5:im.set_pixelv(Vector2i(x,y)+d,INK)
static func frame(unit:Dictionary,pose:Dictionary={})->Dictionary:
	if not supported(unit):return {}
	var id:=str(unit.hero_archetype);var action:=str(pose.get("action","IDLE"))
	var gesture:=id in ["CINDER_TESTATOR","MYCELIAL_CATALYST"] and pose.has("r7_cast_progress") and (action in ["CAST","SKILL"] or action.begins_with("SKILL_"))
	var progress:float=0.0
	if gesture:
		var raw:Variant=pose.r7_cast_progress
		if typeof(raw) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(raw)):gesture=false
		else:progress=clampf(float(raw),0,1)
	if action.begins_with("SKILL_") or action in ["SKILL","HEAL","POTION","HARVEST","MINE","BUILD"]:action="CAST"
	if action=="CARRY":action="WALK"
	if action=="HURT":action="HIT"
	if action not in ["IDLE","WALK","ATTACK","CAST","HIT","FALLEN"]:action="IDLE"
	var phase:=float(pose.get("body_phase_m76",pose.get("phase",0)))
	if not is_finite(phase):phase=0
	var k:=clampi(floori(phase*4),0,3)
	if action=="WALK":
		var tick:=float(pose.get("body_animation_tick_m76",pose.get("animation_tick",k*3)))
		k=posmod(floori(tick/3),4) if is_finite(tick) else 0
	if gesture:k=clampi(floori(progress*8),0,7);action="CAST"
	var mirror:=Vector2(pose.get("direction",Vector2.RIGHT)).x<0
	var side:=str(unit.get("side","PLAYER"));var key:=id+":"+side+":"+action+":"+str(k)+":"+str(mirror)+(":r7-gesture8" if gesture else "")
	if _frames.has(key):_order.erase(key);_order.append(key);return _frames[key]
	var im:=Image.create(32,32,false,Image.FORMAT_RGBA8);var c:Dictionary=_colors(id,side)
	var step:=int([-2,-1,2,1][k%4]) if action=="WALK" else 0
	var bob:=-1 if action=="WALK" and k%2==0 else 0
	var lean:=0;var brace:=0
	var hand:=Vector2i(23,18);var off:=Vector2i(9,19)
	if action=="IDLE":bob=int([0,0,-1,0][k]);hand.y+=int([0,-1,-1,0][k]);off.y+=k%2
	if action=="WALK":hand.y+=step/2;off.y-=step/2
	if action=="ATTACK":
		lean=int([-1,-1,2,0][k]);bob=int([0,1,0,0][k]);brace=1
		hand+=Vector2i(int([-2,-3,3,1][k]),int([-2,-4,1,1][k]));off+=Vector2i(lean,-k%2)
	if action=="CAST":
		brace=1
		if gesture:
			lean=int([-1,-2,-1,0,1,2,1,0][k]);bob=int([1,2,1,0,0,-1,1,0][k])
			hand+=Vector2i(int([-2,-2,-1,1,3,4,2,0][k]),int([1,-1,-4,-7,-6,-3,0,1][k]));off+=Vector2i(int([-1,-2,-2,-1,0,1,0,0][k]),int([1,0,-2,-3,-3,-1,1,1][k]))
		else:
			lean=int([-1,0,1,0][k]);bob=int([1,0,-1,0][k])
			hand+=Vector2i(int([-2,-1,2,1][k]),int([0,-5,-7,-2][k]));off+=Vector2i(-1,int([0,-2,-4,-1][k]))
	if action=="HIT":
		lean=int([-2,-1,1,0][k]);bob=int([1,2,1,0][k]);hand+=Vector2i(-2,1+k%2);off+=Vector2i(-1,k%2)
	# Keep every weapon tip inside its authored 32-cell master, not a crop at
	# the image edge. Body/elbow motion remains independent of this wrist arc.
	var wrist_limit:int=22 if id in ["PISTON_FENCER","FLUX_BOMBARDIER","EMBER_CAVALIER"] else 23 if id in ["OSSUARY_KNIGHT","THORN_REAVER","SPORE_STALKER"] else 24
	hand.x=clampi(hand.x,17,wrist_limit)
	var low_weapon:=id in ["CINDER_TESTATOR","FLUX_BOMBARDIER","OBSIDIAN_CANTOR","MYCELIAL_CATALYST","SPORE_STALKER"]
	hand.y=maxi(hand.y,8 if low_weapon else 15)
	if action=="FALLEN":_fallen(im,id,c,k)
	else:
		_legs(im,id,c,step,bob,brace)
		_backs(im,id,c,bob,k)
		_stamp(im,MASTERS[id],8+lean,(7 if FACTIONS[id]=="UNDERGROUND" else 5)+bob,c)
		var shoulder:=Vector2i(21+lean,16+bob);var left:=Vector2i(11+lean,16+bob)
		if FACTIONS[id]=="UNDERGROUND":shoulder.y+=3;left.y+=3
		_path(im,[left,off+Vector2i(1,-1),off],c.d,3);_path(im,[off+Vector2i(1,-1),off],c.b,1)
		_path(im,[shoulder,hand-Vector2i(2,0),hand],c.d,3);_path(im,[hand-Vector2i(2,0),hand],c.b,1)
		_box(im,hand.x,hand.y,2,2,c.s);_box(im,off.x,off.y,2,2,c.s)
		_weapon(im,id,c,hand,off,k,action)
	_outline(im)
	if mirror:im.flip_x()
	var anchor:=Vector2(31-FOOT.x,FOOT.y) if mirror else FOOT
	var used:=im.get_used_rect();var cropped:=im.get_region(used)
	var result:={"key":key,"image":cropped,"texture":ImageTexture.create_from_image(cropped),"rect":Rect2(Vector2(used.position)-anchor,Vector2(used.size)),"source_size":SIZE,"source_grid":32,"source_rect":used,"action":action,"stage":action,"frame":k,"bucket":k,"mirror":mirror,"pixel_hash":cropped.get_data().hex_encode().sha256_text(),"category":"outposts_v4_hero_pixel_r8","identity":id,"provenance":"original-code-pixel-hero-r8","original_art":true,"licensed_art":false,"motion_refinement_version":"r8-authored-body-four-phase","silhouette":FEATURES[id]}
	if gesture:result["r7_body_gesture"]=true;result["motion_refinement_version"]="r7-authored-body-gesture8-v4"
	while _order.size()>=MAX_FRAMES:_frames.erase(_order.pop_front())
	_frames[key]=result;_order.append(key);_bakes+=1
	return result
static func factor(radius:float)->float:return radius/14.0*2.0 if is_finite(radius) and radius>0 else 0.0
static func visual_bounds(unit:Dictionary,radius:float,pose:Dictionary={})->Rect2:
	var f:=frame(unit,pose);var s:=factor(radius)
	return Rect2(f.rect.position*s,f.rect.size*s) if not f.is_empty() else Rect2()
static func stable_visual_bounds(_unit:Dictionary,radius:float)->Rect2:
	return Rect2(Vector2(-17,-30)*factor(radius),Vector2(34,32)*factor(radius))
static func ground_footprint(unit:Dictionary,radius:float)->Vector2:
	if FACTIONS.get(str(unit.get("hero_archetype","")),"")=="UNDERGROUND":return Vector2(radius*2.4,radius*0.8)
	return Vector2(radius*1.9,radius*0.72)
static func draw(canvas:Object,point:Vector2,unit:Dictionary,radius:float,pose:Dictionary)->void:
	if not point.is_finite() or factor(radius)<=0:return
	var f:=frame(unit,pose)
	if f.is_empty():return
	if canvas is CanvasItem:canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var rect:=Rect2(f.rect.position*factor(radius),f.rect.size*factor(radius))
	# Canvas rendering commands can outlive the cold-frame LRU reference.
	# Retain the actual texture using the established draw-lifetime owner.
	TeamMaterial._retain_draw_texture_m81(canvas,f.texture)
	canvas.draw_texture_rect(f.texture,Rect2((point+rect.position).round(),rect.size),false)
static func body_contains(unit:Dictionary,radius:float,pose:Dictionary,offset:Vector2)->bool:
	if factor(radius)<=0 or not offset.is_finite():return false
	var f:=frame(unit,pose)
	if f.is_empty():return false
	var at:=Vector2i((offset/factor(radius)-f.rect.position).floor())
	return Rect2i(Vector2i.ZERO,f.image.get_size()).has_point(at) and f.image.get_pixelv(at).a>0.5
static func inspect(unit:Dictionary,pose:Dictionary={})->Dictionary:
	if not supported(unit):return {"supported":false}
	var f:=frame(unit,pose).duplicate();f.erase("image");f.erase("texture")
	f.merge({"supported":true,"generated_art":false,"body_reused":false,"source_grid":32,"coarse_outline_pixels":1,"foot_anchor":FOOT,"non_color_features":FEATURES[str(unit.hero_archetype)].duplicate(),"version":VERSION,"hard_alpha":true})
	return f
static func debug_stats()->Dictionary:
	var bytes:=0
	for cached:Dictionary in _frames.values():bytes+=cached.image.get_width()*cached.image.get_height()*4
	return {"frames":_frames.size(),"capacity":MAX_FRAMES,"bakes":_bakes,"texture_bytes":bytes,"maximum_texture_bytes":MAX_FRAMES*32*32*4,"runtime_rng":false,"source_grid":SIZE,"version":VERSION}
