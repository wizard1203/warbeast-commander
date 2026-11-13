extends RefCounted
## R8 final authoring pass for the shared, pre-baked hero sheets.
## Never called from combat settlement; no Nodes, RNG, timers or textures.
const VERSION := "outposts-pixel-fx-r8-cell-material-v1"
const CELL := 2
const MAX_PARTICLES := 12

static func enhance(image:Image,id:String,row:Dictionary,phase:String,frame:int)->void:
	if image==null or image.is_empty() or row.is_empty() or phase not in ["CAST","CONTACT","TAIL","AURA"]:return
	# Retain the old silhouette/material image; rebuild its ink as complete 2px
	# cells. Picking an existing ink, rather than averaging, avoids introducing
	# soft antialias colours or losing a narrow bright authored accent.
	_cell_ink(image)
	var quiet:=phase=="AURA" or bool(row.get("passive",false))
	var seed:=absi(id.hash())
	var kind:=material_family(row)
	var inks:Array=row.get("palette",["171923","465169","93a2ab","d9c7a0","fff1d2","72bfc3","e7b573"])
	var dark:=Color(str(inks[0]))
	var mid:=Color(str(inks[mini(2,inks.size()-1)]))
	var hot:=Color(str(inks[mini(4,inks.size()-1)]))
	var accent:=Color(str(inks[mini(5,inks.size()-1)]))
	var alpha:=.32 if quiet else maxf(.08,1.0-float(frame)/12.0) if phase=="TAIL" else .88
	var count:=2 if quiet else 8 if phase=="CAST" else MAX_PARTICLES
	# Three displaced source clusters follow an updraft / fragment fan / fall,
	# never a universal circumference. Same identity keeps a stable cadence.
	for n:int in range(count):
		var age:=posmod(frame+n*3+seed%7,12)
		if phase=="TAIL" and age>11-frame:continue
		var side:=-1 if (n+seed)%2==0 else 1
		var lane:=n%3
		var x:=96+side*(22+lane*14)+(seed+n*11)%13-6
		var y:=113-lane*19
		if quiet:x=96+side*(19+n*5);y=129-n*8
		match kind:
			"fire":x+=side*age/2;y-=age*(2+lane%2)
			"water":x+=side*age;y+=age*2-18
			"ice":x+=side*age;y+=age*2-16
			"lightning":x+=side*((age/3)%2)*6;y-=age
			"leaf":x+=side*age;y-=age/2+(age/4)%2*4
			"ink":x+=side*age/2;y+=age-9
			"bone":x+=side*age;y+=age*age/10-8
			_:x+=side*age;y+=age*age/8-13
		if quiet:alpha=.24
		var at:=Vector2i(floori(float(x)/CELL)*CELL,floori(float(y)/CELL)*CELL)
		var bright:=accent if (n+seed)%3==0 else hot
		_particle(image,kind,at,age,side,dark,mid,bright,alpha,quiet)
	# The old author corridor is semantic negative space, not a transparent
	# hole in the effect's real range. It remains readable under concurrent FX.
	for y:int in range(84,138,CELL):
		for x:int in range(82,112,CELL):
			var c:=image.get_pixel(x,y)
			if c.a8>48:c.a8=48;image.fill_rect(Rect2i(x,y,CELL,CELL),c)
	for edge:int in [0,1,image.get_width()-2,image.get_width()-1]:
		image.fill_rect(Rect2i(edge,0,1,image.get_height()),Color.TRANSPARENT)
	for edge:int in [0,1,image.get_height()-2,image.get_height()-1]:
		image.fill_rect(Rect2i(0,edge,image.get_width(),1),Color.TRANSPARENT)

static func material_family(row:Dictionary)->String:
	var material:=str(row.get("material",""))+" "+str(row.get("motif",""))+" "+str(row.get("shape",""))
	material=material.to_upper()
	for word:String in ["EMBER","CINDER","KILN","FLAME","FURNACE","ASH"]:
		if material.contains(word):return "fire"
	for word:String in ["FROST","ICE","GLASS","PRISM","CRYSTAL"]:
		if material.contains(word):return "ice"
	for word:String in ["VOLT","LIGHTNING","COIL","ELECTRIC","ARC_FLASH","SIGNAL"]:
		if material.contains(word):return "lightning"
	for word:String in ["WATER","DEW","RAIN","LIQUID","ACID","FERMENT","SPORE","PORCELAIN"]:
		if material.contains(word):return "water"
	for word:String in ["LEAF","VINE","ROOT","PETAL","POLLEN","ANTLER","THORN","BLOOM"]:
		if material.contains(word):return "leaf"
	for word:String in ["BONE","IVORY","RIB","GRAVE","OSSUARY"]:
		if material.contains(word):return "bone"
	for word:String in ["INK","PAPER","SEAL","PAGE","BANNER","WITNESS","CLOTH","ARCHIVE","TESTIMONY"]:
		if material.contains(word):return "ink"
	return {"HUMAN":"ink","UNDEAD":"bone","MACHINE":"metal","FOREST":"leaf","HIGHLAND":"stone","UNDERGROUND":"ice"}.get(str(row.get("faction","")),"metal")

static func _cell_ink(image:Image)->void:
	for y:int in range(0,image.get_height()-1,CELL):
		for x:int in range(0,image.get_width()-1,CELL):
			var selected:=Color.TRANSPARENT
			var strength:=-1.0
			for dy:int in range(CELL):
				for dx:int in range(CELL):
					var ink:=image.get_pixel(x+dx,y+dy)
					# Alpha wins over a bright transparent glow. A tied alpha picks
					# a retained highlight, not a newly interpolated pastel.
					var value:=float(ink.a8)*4.0+ink.r*.30+ink.g*.59+ink.b*.11
					if value>strength:selected=ink;strength=value
			if selected.a8>0:image.fill_rect(Rect2i(x,y,CELL,CELL),selected)

static func _tile(image:Image,at:Vector2i,w:int,h:int,color:Color,alpha:float)->void:
	var clipped:=Rect2i(at,Vector2i(maxi(CELL,w),maxi(CELL,h))).intersection(Rect2i(2,2,image.get_width()-4,image.get_height()-4))
	if not clipped.has_area():return
	var ink:=color
	ink.a8=clampi(roundi(alpha*255.0/16.0)*16,0,255)
	image.fill_rect(clipped,ink)

static func _particle(image:Image,kind:String,p:Vector2i,age:int,side:int,dark:Color,mid:Color,hot:Color,alpha:float,quiet:bool)->void:
	if quiet:
		_tile(image,p,2,2,hot,alpha)
		return
	match kind:
		"fire":
			# A soot heel, short coloured fire body, hot upper tongue and
			# separated spark. Not a smooth lens flare or repeated star.
			_tile(image,p+Vector2i(-2,0),6,6,dark,alpha*.65)
			_tile(image,p,4,6,mid,alpha)
			_tile(image,p+Vector2i(0,-2),2,6,hot,alpha)
			if age%3==0:_tile(image,p+Vector2i(side*4,-6),2,2,hot,alpha*.75)
		"ice":
			_tile(image,p+Vector2i(-2,-6),6,10,dark,alpha*.8)
			_tile(image,p+Vector2i(0,-6),4,8,mid,alpha)
			_tile(image,p+Vector2i(0,-8),2,6,hot,alpha)
			_tile(image,p+Vector2i(2,0),2,4,hot,alpha*.6)
		"lightning":
			for i:int in range(3):
				var point:=p+Vector2i((i%2)*side*4,-i*4)
				_tile(image,point+Vector2i(-2,0),6,4,dark,alpha*.6)
				_tile(image,point,4,2,hot,alpha)
			if age%2==0:_tile(image,p+Vector2i(side*8,-4),4,2,mid,alpha)
		"water":
			_tile(image,p+Vector2i(-2,-4),6,8,dark,alpha*.55)
			_tile(image,p+Vector2i(0,-6),2,4,mid,alpha*.8)
			_tile(image,p,4,4,mid,alpha)
			_tile(image,p,2,2,hot,alpha)
			if age>7:_tile(image,p+Vector2i(side*6,4),4,2,hot,alpha*.55)
		"leaf":
			_tile(image,p+Vector2i(-4,0),10,4,dark,alpha*.7)
			_tile(image,p+Vector2i(-2,-2),6,6,mid,alpha)
			_tile(image,p,4,2,hot,alpha)
			_tile(image,p+Vector2i(side*4,2),4,2,mid,alpha*.7)
		"ink":
			# Broken paper tab with an offset cut corner and readable dark
			# ink dash: a fragment, not an illegible miniature glyph.
			_tile(image,p+Vector2i(-2,-2),8,8,dark,alpha*.7)
			_tile(image,p,4 if age%2 else 6,6,hot,alpha)
			_tile(image,p+Vector2i(0,2),4,2,mid,alpha)
			_tile(image,p+Vector2i(side*4,6),2,2,hot,alpha*.5)
		"bone":
			_tile(image,p+Vector2i(-2,-2),10,6,dark,alpha*.75)
			_tile(image,p,6,2,mid,alpha)
			_tile(image,p+Vector2i(0,-2),2,6,hot,alpha)
			_tile(image,p+Vector2i(6,0),2,4,hot,alpha*.75)
		_:
			_tile(image,p+Vector2i(-2,-2),8,6,dark,alpha*.75)
			_tile(image,p,4,4,mid,alpha)
			_tile(image,p,2,2,hot,alpha)
			if age%4==0:_tile(image,p+Vector2i(side*6,-2),4,2,hot,alpha*.6)
