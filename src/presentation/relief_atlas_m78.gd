extends RefCounted
## Original paper-cut strategy atlas. SVG is rasterized once, never per actor
## or per frame. All bodies share ONE GPU texture; alpha masks are CPU bits.
## This is a presentation identity library, not a rules or stat catalog.
const UnitCatalog = preload("res://src/simulation/strategic_unit_catalog.gd")
const HeroCatalog = preload("res://src/simulation/strategic_hero_catalog.gd")
const CELL := 128
const COLUMNS := 16
const MAX_ENTRIES := 384
const FOOT := Vector2(64,110)
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const BUILDINGS := ["BASE","BARRACKS","RANGE","TOWER","FOUNDRY","ALTAR","WORKSHOP","DRAGON_ROOST","SHOP","ESSENCE_MINE","VILLAGE"]
const COLORS := {
	"HUMAN":["#d9cbb0","#7e8c9b","#7f2937","#e6c772"],
	"UNDEAD":["#c8c6b8","#605871","#493658","#9dcead"],
	"MACHINE":["#b3b8b4","#69584a","#8e4e29","#e9b75b"],
	"FOREST":["#a5b49b","#665c3c","#346952","#cfd893"],
	"HIGHLAND":["#d4d8d5","#716969","#a7512e","#efc46d"],
	"UNDERGROUND":["#c4a8aa","#514a69","#513d63","#b9a6e2"]
}
static var _texture: ImageTexture
static var _entries: Dictionary = {}
static var _identity: Dictionary = {}
static var _masks: Dictionary = {}
static var _error := ""
static var _svg_bytes := 0
static var _rows := 0
static var _builds := 0


static func ensure() -> bool:
	if _texture != null: return true
	if not _error.is_empty(): return false
	var definitions: Array[Dictionary] = []
	for type: String in UnitCatalog.UNITS:
		if type in ["worker","hero"]: continue
		var recipe: Dictionary = UnitCatalog.UNITS[type]
		_register_actor(definitions,type,str(recipe.get("faction_id","HUMAN")),str(recipe.get("role","FRONTLINE")),false,type,0,str(recipe.get("body_kind","")))
	for faction: String in FACTIONS:
		_register_actor(definitions,"worker:"+faction,faction,"WORKER",false,"worker",0,"")
		var roster: Array = HeroCatalog.available_for_faction(faction)
		for slot: int in range(roster.size()):
			var archetype := str(roster[slot])
			var profile: Dictionary = HeroCatalog.profile(archetype)
			var role_id := str(profile.get("role_id",""))
			var kind := "MAGE" if role_id == "MAGE" else "SUPPORT" if role_id in ["HEAL_SUPPORT","CONTROL_SUPPORT"] else "HEAVY" if role_id == "TANK" else "FRONTLINE"
			if role_id == "PHYSICAL" and float(profile.get("stats",{}).get("attack_range",0)) > 80: kind="RANGED"
			_register_actor(definitions,"hero:"+archetype,faction,kind,true,archetype,slot,str(profile.get("body_kind","")))
		for type: String in BUILDINGS:
			definitions.append({"key":"building:"+faction+":"+type,"kind":"building","faction":faction,"type":type})
	for id: String in ["neutral_straggler","neutral_raider","neutral_hunter","neutral_brute","neutral_trial_guard","neutral_trial_sentinel"]:
		var role: String="MAGE" if id=="neutral_trial_sentinel" else "RANGED" if id=="neutral_hunter" else "HEAVY" if id in ["neutral_brute","neutral_trial_guard"] else "FRONTLINE"
		_register_actor(definitions,id,"HIGHLAND",role,false,id,0,"")
	for key: String in ["tree","pine","mountain","ice","lava","stone","flower","mushroom","food","gold","essence","loot","camp","team","shadow"]:
		definitions.append({"key":key,"kind":"prop","type":key})
	if definitions.size()>MAX_ENTRIES:
		_error="ATLAS_CAPACITY"; return false
	_rows=ceili(float(definitions.size())/COLUMNS)
	var chunks: PackedStringArray = []
	chunks.append('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"><defs><linearGradient id="ivory" x2="0.9" y2="1"><stop stop-color="#e6d4ab"/><stop offset="1" stop-color="#a8936a"/></linearGradient><linearGradient id="water" x2="0.3" y2="1"><stop stop-color="#6e9da6"/><stop offset="1" stop-color="#315d70"/></linearGradient></defs>' % [COLUMNS*CELL,_rows*CELL,COLUMNS*CELL,_rows*CELL])
	for index: int in range(definitions.size()):
		var spec: Dictionary=definitions[index]
		var origin:=Vector2i(index%COLUMNS*CELL,index/COLUMNS*CELL)
		var body := _actor_svg(spec) if spec.kind=="actor" else _building_svg(spec) if spec.kind=="building" else _prop_svg(str(spec.type))
		chunks.append('<g transform="translate(%d %d)">%s</g>' % [origin.x,origin.y,body])
		_entries[str(spec.key)]={"region":Rect2(origin,Vector2(CELL,CELL)),"scale":0.78 if bool(spec.get("hero",false)) else 0.60 if spec.kind=="actor" else 1.65 if spec.kind=="building" else 1.0,"kind":str(spec.kind),"hero":bool(spec.get("hero",false))}
	chunks.append('</svg>')
	var svg: String="".join(chunks)
	_svg_bytes=svg.length()
	var image:=Image.new()
	var status:=image.load_svg_from_string(svg)
	if status!=OK:
		_error="SVG_RASTERIZATION_%d" % status; return false
	for key: String in _entries:
		var entry: Dictionary=_entries[key]
		var pixels:=image.get_region(Rect2i(entry.region))
		var alpha:=BitMap.new()
		alpha.create_from_image_alpha(pixels,0.45)
		_masks[key]=alpha
		# Exclude pre-baked soft shadow from the selectable body footprint.
		var used:=Rect2i(CELL,CELL,0,0)
		var low:=Vector2i(CELL,CELL)
		var high:=Vector2i.ZERO
		for y: int in range(CELL):
			for x: int in range(CELL):
				if alpha.get_bit(x,y): low=low.min(Vector2i(x,y)); high=high.max(Vector2i(x+1,y+1))
		if high.x>low.x and high.y>low.y: used=Rect2i(low,high-low)
		entry["used"]=Rect2(used)
	_texture=ImageTexture.create_from_image(image)
	_builds+=1
	return true


static func _register_actor(definitions: Array[Dictionary], key: String, faction: String, role: String, hero: bool, archetype: String, slot: int, body: String) -> void:
	if role not in ["WORKER","FRONTLINE","HEAVY","RANGED","CAVALRY","SUPPORT","SIEGE","FLYING","MAGE"]: role="FRONTLINE"
	if body=="VEHICLE": role="SIEGE"
	elif body=="DRAGON": role="FLYING"
	_identity[key]={"key":key,"faction":faction,"role":role,"hero":hero,"archetype":archetype,"slot":slot}
	for frame: int in range(3): definitions.append({"key":key+":"+str(frame),"kind":"actor","faction":faction,"role":role,"hero":hero,"archetype":archetype,"slot":slot,"frame":frame})


static func actor_key(entity: Dictionary, frame: int = 0) -> String:
	var type:=str(entity.get("unit_type","worker"))
	var key: String="hero:"+str(entity.get("hero_archetype",entity.get("archetype","COMMANDER"))) if type=="hero" else "worker:"+str(entity.get("faction_id","HUMAN")) if type=="worker" else type
	if not _identity.has(key):
		# Neutral variants retain their supplied military identity when present;
		# unknown custom identities use a functional silhouette, never invisible.
		key=str(entity.get("visual_unit_type",entity.get("base_unit_type",entity.get("source_unit_type",type))))
	if not _identity.has(key) and bool(entity.get("neutral",false)):
		key="neutral_hunter" if float(entity.get("attack_range",0))>80 else "neutral_brute" if float(entity.get("radius",0))>15 else "neutral_raider"
	if not _identity.has(key): key="worker:"+str(entity.get("faction_id","HUMAN"))
	if not _identity.has(key): key="worker:HUMAN"
	return key+":"+str(clampi(frame,0,2))


static func building_key(entity: Dictionary) -> String:
	var faction:=str(entity.get("faction_id","HUMAN"))
	if faction not in FACTIONS: faction="HUMAN"
	var type:=str(entity.get("building_type","BASE"))
	if type=="SITE_TOWER":type="TOWER"
	if type not in BUILDINGS:type="BARRACKS"
	return "building:"+faction+":"+type


static func bounds(key: String, factor: float = 1.0, facing: float = 1.0) -> Rect2:
	if not ensure() or not _entries.has(key) or factor<=0:return Rect2()
	var entry: Dictionary=_entries[key]
	var body: Rect2=entry.used
	var scale_value:=factor*float(entry.scale)
	var local:=Rect2((body.position-FOOT)*scale_value,body.size*scale_value)
	if facing<0:local.position.x=-local.end.x
	return local


static func contains(key: String, local: Vector2, factor: float = 1.0, facing: float = 1.0) -> bool:
	if not ensure() or not _entries.has(key) or factor<=0:return false
	var entry: Dictionary=_entries[key]
	if facing<0:local.x=-local.x
	var pixel:=Vector2i((local/(factor*float(entry.scale))+FOOT).floor())
	return Rect2i(0,0,CELL,CELL).has_point(pixel) and (_masks[key] as BitMap).get_bitv(pixel)


static func draw(canvas: CanvasItem, point: Vector2, key: String, factor: float = 1.0, tint: Color = Color.WHITE, facing: float = 1.0) -> void:
	if not ensure() or not _entries.has(key) or factor<=0:return
	var entry: Dictionary=_entries[key]
	var extent:=Vector2(CELL,CELL)*factor*float(entry.scale)
	var rect:=Rect2(point-FOOT*factor*float(entry.scale),extent)
	if facing<0:
		rect.position.x=point.x+FOOT.x*factor*float(entry.scale)
		rect.size.x=-rect.size.x
	canvas.draw_texture_rect_region(_texture,rect,entry.region,tint,false,true)


static func stats() -> Dictionary:
	return {"ready":_texture!=null,"error":_error,"entries":_entries.size(),"identities":_identity.size(),"actor_frames":3,"textures":1 if _texture!=null else 0,"capacity":MAX_ENTRIES,"builds":_builds,"width":COLUMNS*CELL,"height":_rows*CELL,"texture_bytes":COLUMNS*CELL*_rows*CELL*4,"maximum_texture_bytes":COLUMNS*CELL*ceili(float(MAX_ENTRIES)/COLUMNS)*CELL*4,"svg_bytes":_svg_bytes,"source":"original-native-svg-m78","per_frame_rasterization":false}


static func identity_manifest() -> Dictionary:
	if not ensure():return {}
	return _identity.duplicate(true)


static func _path(points: String, color: String, stroke: String = "#25302e", width: float = 2.0) -> String:
	return '<path d="%s" fill="%s" stroke="%s" stroke-width="%.1f" stroke-linejoin="round"/>' % [points,color,stroke,width]


static func _ellipse(x: float, y: float, rx: float, ry: float, color: String, opacity: float = 1.0) -> String:
	return '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s" opacity="%.2f"/>' % [x,y,rx,ry,color,opacity]


static func _actor_svg(spec: Dictionary) -> String:
	var p: Array=COLORS.get(str(spec.faction),COLORS.HUMAN)
	var role:=str(spec.role)
	var frame:=int(spec.frame)
	var slot:=int(spec.slot)
	var hero:=bool(spec.hero)
	var faction:=str(spec.faction)
	var s: String=_ellipse(64,112,29 if hero else 24,7,"#1c2929",0.22)
	if role=="SIEGE":
		s+=_path("M22 84 L86 74 L109 88 L95 106 L27 108Z",str(p[1]))
		s+=_ellipse(34,104,12,12,"#333b3b")+_ellipse(91,101,12,12,"#333b3b")
		s+=_ellipse(34,104,5,5,str(p[3]))+_ellipse(91,101,5,5,str(p[3]))
		s+=_path("M45 81 L54 42 L63 40 L70 80Z",str(p[0]))+_path("M59 40 L110 25 L113 37 L62 51Z",str(p[1]))
		s+=_path("M30 83 L80 78 L87 86 L35 94Z",str(p[2]))
		return s
	if role=="FLYING":
		s+=_path("M61 68 L18 38 L9 65 L34 64 L20 88 L61 79 M67 70 L109 37 L119 60 L99 66 L114 86 L67 82",str(p[2]))
		s+=_path("M50 94 L53 66 L72 49 L84 56 L77 66 L70 70 L79 100 L66 108Z",str(p[1]))
		s+=_path("M73 51 L88 46 L96 51 L84 58Z",str(p[0]))+_path("M72 51 L71 36 L80 48",str(p[3]))
		return s
	var shift:=3 if frame==1 else 0
	if role=="CAVALRY":
		s+=_path("M27 83 Q44 68 78 78 L96 62 L106 68 L99 91 L85 95 L85 111 L78 111 L73 95 L47 96 L42 113 L35 113 L37 93Z",str(p[1]))
		s+='<g transform="translate(0 -18)">'
	# Underworld workers and troops are genuine chitin silhouettes, not recolors.
	if faction=="UNDERGROUND":
		s+=_path("M45 89 L27 101 L19 113 M48 98 L37 112 M78 89 L100 100 L111 112 M80 99 L92 113","none",str(p[1]),5)
		s+=_path("M41 66 L57 55 L78 61 L89 86 L75 105 L49 104 L35 86Z",str(p[2]))
		s+=_path("M42 76 L64 66 L86 78 M40 88 L64 79 L85 90","none",str(p[0]),2)
	else:
		s+=_path("M45 86 L43 %d L54 110 L62 86 M67 87 L72 109 L82 %d L79 83Z" % [108-shift,110-shift],str(p[1]))
		if role in ["MAGE","SUPPORT"]:s+=_path("M49 57 L76 57 L87 103 Q63 114 36 102Z",str(p[2]))
		else:s+=_path("M45 60 L73 55 L88 72 L77 92 L47 92 L36 73Z",str(p[0] if role=="HEAVY" else p[2]))
		s+=_path("M46 64 L58 61 L57 88 L47 85Z",str(p[0]),"none")
	# Face remains pale, machinery has a square visor, forest an antler crown.
	if faction=="MACHINE":
		s+=_path("M48 35 L75 35 L80 57 L47 59Z",str(p[0]))+_path("M51 42 L73 42 L73 49 L51 49Z",str(p[3]))
	elif faction=="UNDERGROUND":
		s+=_path("M43 47 L52 32 L75 31 L87 46 L78 62 L51 61Z",str(p[0]))+_path("M49 35 L42 19 L58 32 M71 32 L84 17 L80 39",str(p[3]))
	else:
		s+=_ellipse(63,46,14,17,str(p[0]))+_path("M49 41 L54 26 L70 27 L80 40Z",str(p[1]))
		s+=_path("M60 45 L72 46","none","#26322f",2)
		if faction=="UNDEAD":s+=_path("M50 52 L58 68 L74 57 M55 37 L57 46 M69 36 L72 44","none",str(p[1]),3)
		elif faction=="FOREST":s+=_path("M51 32 L40 23 L42 15 M73 31 L84 21 L82 12","none",str(p[1]),3)
		elif faction=="HIGHLAND":s+=_path("M49 49 L61 72 L79 53 L74 69 L61 78 L48 61Z",str(p[1]))
	# Two hero signatures: unique headpiece + cape/standard/weapon ornament.
	if hero:
		s+=_path("M42 59 L30 98 L47 105 L48 69Z",str(p[1]))
		if slot%3==0:s+=_path("M47 30 L46 18 L56 23 L63 11 L69 23 L80 18 L77 32Z",str(p[3]))
		elif slot%3==1:s+=_path("M47 34 L43 19 L53 27 L61 14 L74 24 L81 15 L79 35Z",str(p[2]))
		else:s+=_path("M45 31 L62 9 L82 32 L71 29 L62 23 L52 33Z",str(p[1]))
		s+=_path("M34 66 L25 55 L31 45 L40 60Z",str(p[3])) if slot%2==0 else _path("M30 61 L20 43 L25 27 L31 56Z",str(p[0]))
	if role=="WORKER":
		s+=_path("M39 62 L33 91 L58 94 L60 68Z",str(p[1]))
		s+=_path("M87 104 L94 53","none",str(p[1]),5)+_path("M80 52 Q96 38 110 52 L105 59 Q93 49 83 59Z",str(p[0]))
		s+=_path("M48 33 L46 23 L72 22 L80 34Z",str(p[2]))
	elif role=="RANGED":
		s+=_path("M91 44 Q116 72 91 102 M91 44 L96 74 L91 102","none",str(p[1]),4)
		s+=_path("M70 73 L110 71 M107 67 L113 71 L107 75","none",str(p[0]),2)
	elif role in ["MAGE","SUPPORT"]:
		s+=_path("M88 107 L93 39","none",str(p[1]),5)
		s+=_path("M93 40 L83 26 L94 14 L105 27Z",str(p[3]))
		s+=_ellipse(93,28,4,5,"#f0ecd1")
	elif role=="HEAVY":
		s+=_path("M24 67 L45 62 L50 90 L37 105 L22 90Z",str(p[1]))+_path("M29 70 L39 69 L43 87 L35 96 L28 86Z",str(p[3]))
		s+=_path("M87 102 L100 48","none",str(p[1]),5)+_path("M89 42 L111 47 L107 64 L87 59Z",str(p[0]))
	else:
		s+=_path("M85 84 L101 31 L109 26 L108 38 L93 87Z",str(p[0]))+_path("M81 84 L99 88","none",str(p[3]),4)
		if faction=="MACHINE":s+=_path("M78 71 L111 58 L115 70 L84 81Z",str(p[1]))
	if frame==2:s+=_path("M94 20 Q118 38 117 61","none",str(p[3]),4)
	if role=="CAVALRY":s+='</g>'
	return s


static func _building_svg(spec: Dictionary) -> String:
	var p: Array=COLORS.get(str(spec.faction),COLORS.HUMAN)
	var type:=str(spec.type)
	var faction:=str(spec.faction)
	var s: String=_ellipse(64,112,55,12,"#172d2c",0.22)
	if type=="TOWER":
		s+=_path("M41 46 L81 44 L87 105 L39 108Z",str(p[0]))+_path("M68 46 L81 44 L87 105 L69 108Z",str(p[1]))
		s+=_path("M34 38 L43 38 L43 27 L52 27 L52 38 L67 38 L67 27 L78 27 L78 38 L90 38 L90 55 L34 55Z",str(p[1]))
		s+=_path("M49 57 L76 57 L76 69 L49 69Z",str(p[2]))+_path("M56 83 L68 83 L68 107 L56 107Z","#293736")
	elif type=="ALTAR" or type=="ESSENCE_MINE":
		s+=_path("M15 100 L62 79 L112 100 L66 121Z",str(p[1]))+_path("M25 91 L62 75 L102 91 L65 109Z",str(p[0]))
		s+=_path("M58 80 L44 55 L63 16 L84 53 L69 82Z",str(p[3]))+_path("M63 17 L64 78 L84 53Z",str(p[2]))
		s+=_path("M28 84 L28 51 L38 45 L40 88 M88 87 L89 46 L98 51 L99 83",str(p[1]))
	else:
		var castle:=type=="BASE"
		s+=_path("M18 66 L60 50 L109 67 L110 105 L63 122 L18 104Z",str(p[0]))
		s+=_path("M63 74 L109 67 L110 105 L63 122Z",str(p[1]))
		var roof: String="M10 65 L59 24 L119 63 L67 83Z"
		if faction=="FOREST":roof="M9 65 Q30 26 62 28 Q96 28 120 63 L67 83Z"
		elif faction=="UNDEAD":roof="M9 67 L34 28 L46 44 L60 12 L80 44 L96 28 L120 66 L67 83Z"
		elif faction=="MACHINE":roof="M12 56 L58 36 L118 55 L118 68 L68 87 L12 69Z"
		elif faction=="UNDERGROUND":roof="M9 66 Q8 42 34 44 Q41 19 63 29 Q91 22 98 45 Q120 43 120 65 L68 86Z"
		s+=_path(roof,str(p[2]))+_path("M62 26 L67 81 L118 63Z",str(p[1]),"none")
		s+=_path("M44 120 L43 90 Q48 77 59 89 L60 120Z","#293735")
		s+=_path("M23 76 L34 72 L34 85 L23 89Z",str(p[3]))+_path("M78 86 L91 82 L91 95 L78 99Z",str(p[3]))
		if castle:
			s+=_path("M10 104 L10 48 L26 41 L35 50 L35 111Z",str(p[0]))+_path("M4 47 L22 17 L42 47 L25 57Z",str(p[2]))
			s+=_path("M93 107 L92 45 L107 37 L119 45 L120 100Z",str(p[0]))+_path("M86 43 L105 12 L125 43 L108 51Z",str(p[2]))
		if type in ["WORKSHOP","FOUNDRY"]:
			s+=_path("M85 48 L85 11 L98 7 L103 13 L103 55Z",str(p[1]))+_path("M81 13 L96 6 L108 11 L95 18Z",str(p[0]))
			s+=_path("M80 106 L80 85 Q87 71 98 81 L99 100Z","#f0b453")
		elif type=="RANGE":
			s+=_ellipse(103,90,14,19,str(p[3]))+_ellipse(103,90,8,12,str(p[2]))+_ellipse(103,90,3,5,str(p[0]))
		elif type=="BARRACKS":s+=_path("M85 101 L105 65 M89 65 L108 98","none",str(p[0]),5)
		elif type=="SHOP":s+=_path("M26 76 L63 64 L91 79 L84 87 L57 73 L29 85Z",str(p[3]))
		elif type=="DRAGON_ROOST":s+=_path("M38 40 L24 20 L51 28 L64 9 L80 28 L107 19 L91 44Z",str(p[3]))
	# Material-specific structural ornaments, not a whole-body tint.
	if faction=="FOREST":s+=_path("M17 103 Q9 70 25 51 M106 104 Q120 74 109 54","none","#465c3d",5)
	elif faction=="MACHINE":s+=_path("M19 66 L63 83 L111 65 M64 84 L65 121","none",str(p[3]),3)
	elif faction=="HIGHLAND":s+=_path("M12 59 L24 40 L38 54 M55 29 L62 22 L73 32","none","#e4e5dd",5)
	elif faction=="UNDERGROUND":s+=_ellipse(30,87,6,4,str(p[3]))+_ellipse(95,75,6,4,str(p[3]))
	return s


static func _prop_svg(type: String) -> String:
	var s: String=_ellipse(64,112,35,8,"#21382e",0.20)
	match type:
		"tree","pine":
			s+=_path("M59 109 L59 72 L70 70 L73 109Z","#6d5c41")
			if type=="pine":s+=_path("M15 93 L34 68 L27 68 L48 40 L43 40 L63 11 L86 42 L80 42 L102 68 L93 68 L115 94Z","#496f5c")
			else:s+=_path("M14 73 Q7 54 25 45 Q17 25 44 23 Q56 8 78 23 Q103 14 107 42 Q127 51 113 77 L94 87 L35 91Z","#517458")
			s+=_path("M30 55 Q34 28 62 28 L61 75 L34 79Z","#789273","none")
		"mountain","ice","gold":
			var color: String="#7c8c88" if type=="mountain" else "#9dbfbd" if type=="ice" else "#98845b"
			s+=_path("M4 109 L38 45 L57 64 L79 19 L123 108 L84 119 L43 116Z",color)
			s+=_path("M79 20 L72 79 L91 66 L123 108 L83 118Z","#4d6868" if type!="gold" else "#6d674f","none")
			s+=_path("M27 65 L38 45 L51 62 L40 58 M66 42 L79 20 L94 49 L81 39 L74 48Z","#d4ded4" if type!="gold" else "#f2d476","none")
			if type=="gold":s+=_path("M36 90 L48 75 L61 92 L49 108Z M81 87 L94 73 L105 97 L91 110Z","#e9bd4f")
		"food":
			s+=_path("M7 99 L67 71 L122 95 L67 122Z","#6d6844")
			for i: int in range(6):
				var x:=25+i*15
				s+=_path("M%d 108 L%d 56 M%d 74 L%d 65 M%d 86 L%d 78" % [x,x,x,x-8,x,x+9],"none","#b59c54",3)
				s+=_ellipse(x,56,5,15,"#e2c473")
		"essence":
			s+=_path("M16 104 L33 73 L56 91 L74 48 L109 105 L70 123Z","#655976")
			s+=_path("M51 99 L49 50 L66 21 L85 51 L78 101Z","#ae9bcc")+_path("M65 24 L65 96 L85 51Z","#e1d0f1")
		"lava":s+=_path("M8 110 L24 62 L50 75 L73 33 L116 106Z","#5b4e46")+_path("M66 55 L57 82 L72 88 L61 110 M32 80 L39 97 L25 106","none","#df9258",6)
		"flower":
			for i: int in range(4):s+=_path("M%d 111 L%d 89" % [36+i*15,36+i*15],"none","#647c57",2)+_ellipse(36+i*15,89,5,5,"#c9b589" if i%2==0 else "#be9b8d")
		"mushroom":s+=_path("M51 108 L54 79 L72 79 L77 108Z","#aa9c9a")+_path("M24 84 Q33 36 65 38 Q100 40 112 84Z","#867591")+_ellipse(52,60,6,4,"#d5c8c6")
		"team":return _path("M57 63 L73 63 L73 82 L65 89 L57 82Z","#ffffff","#26332f",1.4)
		"shadow":return _ellipse(64,110,33,9,"#1f312a",0.22)
		"loot":s+=_path("M39 78 L63 66 L91 79 L90 108 L63 120 L39 106Z","#c7a360")+_path("M39 80 L63 92 L91 79 M63 92 L63 120","none","#5c583c",3)
		"camp":s+=_path("M21 111 L63 39 L108 111Z","#857a60")+_path("M63 40 L64 111 L109 111Z","#5f6557")+_path("M46 111 L63 82 L80 111Z","#2a3d35")
		_:s+=_path("M24 110 L34 91 L68 80 L100 95 L107 111Z","#829083")+_path("M35 93 L69 82 L80 96 L47 101Z","#a2ada1","none")
	return s
