extends RefCounted
## Original M60 pixel miniatures. Authored object silhouettes + material ramps,
## never random pixels, hue-only identities, ID text or a simulation authority.
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const SpellIdentity = preload("res://src/presentation/heroic_spell_identity.gd")
const ExpansionAV=preload("res://src/presentation/heroic_expansion_av_m66.gd")
const MageAV=preload("res://src/presentation/heroic_mage_effects_m68.gd")
const RangedAV=preload("res://src/presentation/heroic_ranged_roles_m68.gd")
const VERSION := "m60-authored-pixel-identities-v1"
const SIZE := Vector2i(24,24)
const MAX_ICONS := 249 # M68 adds18 learned +6 innate icons; bounded24px RGBA.
const INK := Color("13151a")
# Motif / meaningful composition / material. Boots and compass intentionally
# retain their exact licensed cells in the parent router.
const ITEMS := {
	"IRON_BLADE":["blade","plain","steel"],"WARD_MAIL":["plate","plain","iron"],
	"LONGSIGHT":["lens","long","bronze"],"VITAL_CHARM":["heart","pendant","jade"],
	"SPELL_LENS":["lens","orbit","violet"],"SWIFT_GLOVES":["glove","plain","leather"],
	"NULL_CLOAK":["cloak","plain","violet"],"MANA_CRYSTAL":["gem","plain","blue"],
	"REGEN_RING":["ring","sprout","jade"],"MANA_BEAD":["bead","wave","blue"],
	"HEALERS_SEAL":["seal","cross","mint"],
	"VANGUARD_BLADE":["broadblade","heart","blood"],"WARDEN_CREST":["shield","crown","bronze"],
	"ARCANE_SIGIL":["rune","orbit","violet"],"SWIFT_BLADE":["twinblades","sweep","steel"],
	"SPELLWEAVE":["staff","weave","violet"],"NULL_AEGIS":["shield","crack","violet"],
	"EVERGREEN_CHARM":["heart","branches","jade"],"DEEP_CURRENT":["jar","wave","blue"],
	"MERCY_STAFF":["staff","lily","mint"],"HUNTERS_SCOPE":["lens","feather","bronze"],
	"MARCHWARD":["boot","wing","iron"],
	"WAR_STANDARD":["flag","blade","blood"],"AEGIS_STANDARD":["pennant","shield","steel"],
	"SPRING_STANDARD":["flag","sprout","jade"],"MANA_STANDARD":["pennant","gem","blue"],
	"POTION":["bottle","round","blood"],"MANA_POTION":["vial","tall","blue"],
	"RESTORATION_DRAUGHT":["bottle","twin","mint"],"CLEANSE_DRAUGHT":["bottle","spray","gold"],
	"GUARD_DRAUGHT":["bottle","shield","iron"],"HASTE_DRAUGHT":["bottle","wing","mint"],
	"ASSAULT_DRAUGHT":["flask","blade","ember"],"NULL_DRAUGHT":["flask","crescent","violet"],
	"SHIELD_DRAUGHT":["flask","heart","steel"],"GROUP_HEAL_DRAUGHT":["flask","cross","jade"],
	"ESSENCE_RESTORATION":["ampoule","crystal_wings","violet"],"ESSENCE_BULWARK":["ampoule","bastion","gold"]
}
# Every row is authored from the existing spell name/material brief, not its
# generic effect enum. A control and a damaging spell may share a mechanic but
# never the same picture. Context occupies meaningful image area, not badges.
const SKILLS := {
	"CLEAVE":["broadblade","sweep"],"RECOVER":["hand","stitch"],"RALLY":["seal","impact"],
	"SHIELD_SHOCK":["shield","impact"],"BULWARK_WARD":["bastion","guard"],"BULWARK_RECOVER":["bastion","falling"],
	"STARFIRE":["comet","trail"],"FROST_BIND":["ice","chain"],"ARCANE_BURST":["star","lance"],
	"PIERCING_SHOT":["arrow","lance"],"ARROW_RAIN":["arrows","falling"],"QUICKDRAW":["bow","wing"],
	"SEAL_STRIKE":["blade","seal"],"WHIRLWIND":["twinblades","vortex"],"BLOOD_PACT":["twinblades","chain"],
	"ASH_SHOCK":["rib","impact"],"ASH_WARD":["coffin","guard"],"ASH_MEND":["coffin","crown"],
	"MOURN_BIND":["lantern","chain"],"MOURN_FLARE":["flame","wisps"],"MOURN_OATH":["skull","extraction"],
	"CINDER_SHOT":["bone_arrow","trail"],"CINDER_FERVOR":["quiver","flame"],"CINDER_MEND":["bone_arrow","pin"],
	"COIL_SHOCK":["coil","impact"],"COIL_WARD":["plate","rivets"],"COIL_REPAIR":["gate","bolt"],
	"VOLT_BIND":["coil","cage"],"VOLT_ARC":["bolt","fork"],"VOLT_NETWORK":["circuit","storm"],
	"GEAR_SHOT":["bullet","shrapnel"],"GEAR_FERVOR":["rotor","spin"],"GEAR_REPAIR":["missile","embers"],
	"VINE_SHOCK":["heart","roots"],"VINE_WARD":["plate","branches"],"VINE_MEND":["roots","crown"],
	"LEAF_BIND":["hand","weave"],"LEAF_FLARE":["leaf","fan"],"LEAF_OATH":["bloom","cage"],
	"WIND_SHOT":["arrow","wind"],"WIND_FERVOR":["leaf","wing"],"WIND_MEND":["leaf","lance"],
	"RIDGE_SHOCK":["hammer","temper"],"RIDGE_WARD":["mountain","guard"],"RIDGE_MEND":["mountain","falling"],
	"RUNE_BIND":["rune","lock"],"RUNE_FLARE":["volcano","embers"],"RUNE_OATH":["volcano","fan"],
	"EMBER_SEAL":["blade","flame"],"EMBER_SWEEP":["broadblade","fire_sweep"],"EMBER_MEND":["blade","fissure"],
	"TUNNEL_SHOCK":["shell","impact"],"TUNNEL_WARD":["shell","guard"],"TUNNEL_MEND":["jaw","roots"],
	"ECHO_BIND":["crystals","wave"],"ECHO_FLARE":["drill","trail"],"ECHO_OATH":["crystals","implosion"],
	"SPORE_SEAL":["fang","pin"],"SPORE_SWEEP":["mantis","sweep"],"SPORE_MEND":["jaw","rift"],
	"ASH_LANTERN":["candle","halo"],"ASH_STITCH":["lantern","stitch"],"ASH_REQUIEM":["lantern","choir"],
	"GRAVE_CADENCE":["bell","wave"],"GRAVE_CHAIN":["hook","chain"],"GRAVE_TOLL":["bell","silence"],
	"COIL_BATTERY":["battery","halo"],"COIL_MEND":["satellite","repair"],"COIL_OVERHAUL":["wrench","dock"],
	"SIGNAL_MARCH":["antenna","signal"],"SIGNAL_LOCK":["circuit","cut"],"SIGNAL_BLACKOUT":["antenna","blackout"],
	"BLOOM_SPRING":["sprout","halo"],"BLOOM_TOUCH":["lily","drop"],"BLOOM_SANCTUARY":["bloom","arbor"],
	"THORN_BREEZE":["thorns","wind"],"THORN_LASH":["vine","whip"],"THORN_MAZE":["maze","bloom"],
	"HEARTH_WARMTH":["hearth","halo"],"HEARTH_MEND":["flame","hand"],"HEARTH_REFUGE":["tent","campfire"],
	"STORM_CHANT":["horn","bolt"],"STORM_HAMMER":["hammer","thunder"],"STORM_VERDICT":["mountain","storm"],
	"SPORE_GLOW":["mushroom","halo"],"SPORE_REMEDY":["mushroom","spores"],"SPORE_HAVEN":["mushroom","mycelium"],
	"QUAKE_RHYTHM":["slab","wave"],"QUAKE_SNARE":["jaw","fissure"],"QUAKE_SEAL":["slab","tectonic"]
}
const INNATES := {
	"COMMANDER":["hands","oath"],"BULWARK":["shield","companions"],"ARCANIST":["star","formation"],
	"RANGER":["bow","companions"],"DUELIST":["boot","peace"],"ASH_MARSHAL":["rib","heart"],
	"MOURN_ORACLE":["candle","delayed"],"CINDER_STALKER":["bone_arrow","wounded"],
	"COIL_WARDEN":["rivet","anchor"],"VOLT_WEAVER":["coil","triphase"],"GEAR_HUNTER":["gear","sight"],
	"VINE_WARDEN":["roots","drop"],"LEAF_SEER":["eye","branches"],"WIND_COURIER":["bow","wind"],
	"RIDGE_JARL":["shield","mountain"],"RUNE_ORACLE":["rune","coal"],"EMBER_CAVALIER":["twinblades","embers"],
	"TUNNEL_SENTINEL":["shell","formation"],"ECHO_BINDER":["crystals","spores"],"SPORE_STALKER":["mantis","companions"],
	"ASH_CHANTER":["lantern","embers"],"GRAVE_BELL":["bell","wounded"],"COIL_MEDIC":["coil","shield"],
	"SIGNAL_KEEPER":["antenna","stable"],"BLOOM_GUIDE":["sprout","afterglow"],"THORN_CHANTER":["thorns","blade"],
	"HEARTH_KEEPER":["heart","warmth"],"STORM_HERALD":["hammer","companions"],"SPORE_GUIDE":["mushroom","sharing"],
	"QUAKE_PRIEST":["slab","aftershock"]
}
const STATES := {
	"STUN":["star","confused","gold"],"ROOT":["roots","shackles","jade"],
	"SLOW":["boot","snow","blue"],"BURN":["flame","coal","ember"],
	"POISON":["fang","drop","jade"],"ARMOR_BREAK":["plate","fracture","blood"],
	"HEAL":["hand","cross","mint"],"GUARD":["shield","wall","steel"],
	"FERVOR":["glove","rays","ember"],"EQUIPMENT_AURA":["pennant","halo","gold"],
	"MARCH_CADENCE":["horn","march_steps","gold"],"BORROWED_EMBERS":["candle","sharing","blood"],
	"TRIPLE_OVERCLOCK":["gear","triphase","blue"],"ROOT_NETWORK":["roots","circuit_ring","jade"],
	"HEARTH_CHARGE":["rune","battery","ember"],"SPORE_PRESSURE":["mushroom","poison_cloud","violet"],
	"STAT_ATTACK_SPEED":["blade","metronome","steel"],"STAT_MAGIC_RESIST":["cloak","ward_runes","violet"],
	"STAT_SPELL_AMP":["staff","amplify","violet"]
}
const RAMPS := {
	"steel":["3a4754","8fadb9","e1e9db","cda25c"],"iron":["42414d","8f939b","c9c6b1","bd8a60"],
	"bronze":["645039","b18a51","ead4a1","75adae"],"jade":["315c47","75b97d","d5e5a5","d4a66e"],
	"violet":["48385d","a481bc","e8c8e0","80baba"],"blue":["304a62","6ca5ce","c5e0e3","c99c66"],
	"mint":["355a56","7bbfb2","e0e7b4","dfad95"],"blood":["593c48","c4717a","f1d2ac","a1bfc5"],
	"ember":["6a3d39","db8e50","fae2a2","9ba8c2"],"gold":["6c5734","c7aa63","f1e4b6","9d8cb3"],
	"leather":["584137","a17f51","d9ba80","8fb2af"]
}
static var _frames := {}
static var _textures := {}

static func supported(id: String) -> bool:
	if not RangedAV.icon_recipe(id).is_empty():return true
	if not MageAV.icon_recipe(id).is_empty():return true
	if ExpansionAV.ICONS.has(id):return true
	return ITEMS.has(id) or SKILLS.has(id) or STATES.has(id) or (id.begins_with("INNATE_") and INNATES.has(id.trim_prefix("INNATE_")))

static func inspect(id: String) -> Dictionary:
	if not supported(id): return {"supported":false}
	var recipe: Array = _recipe(id)
	return {"supported":true,"symbol":id,"provenance":"original-code-pixel-m60","version":VERSION,"rect":Rect2i(Vector2i.ZERO,SIZE),"motif":recipe[0],"composition":recipe[1],"pixels":24,"coarse_outline":1,"source_pixels":"authored-semantic-shapes","licensed_art":false}

static func image(id: String) -> Image:
	if not supported(id): return null
	if _frames.has(id): return _frames[id]
	if _frames.size()>=MAX_ICONS: return null
	var recipe := _recipe(id)
	var palette: Array = _palette(id)
	var surface := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	# Compositions are behind the object. The final one-pixel dark dilation
	# creates the same readable coarse edge at HUD, shop and inventory sizes.
	_context(surface,str(recipe[1]),palette)
	_motif(surface,str(recipe[0]),Vector2i(12,12),palette)
	var outlined := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if surface.get_pixel(x,y).a<=0: continue
			for dy: int in range(-1,2):
				for dx: int in range(-1,2): _point(outlined,x+dx,y+dy,INK)
	outlined.blend_rect(surface,Rect2i(Vector2i.ZERO,SIZE),Vector2i.ZERO)
	_frames[id]=outlined
	return outlined

static func draw_symbol(canvas: Object,id: String,center: Vector2,color: Color,scale_factor: float=1.0) -> bool:
	if not supported(id) or not center.is_finite() or not is_finite(scale_factor) or scale_factor<=0: return false
	if not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b) or not is_finite(color.a): return false
	if maxf(color.r,maxf(color.g,color.b))<0.28: return true # No doubled legacy shadow pass.
	if not _textures.has(id):
		var pixels := image(id)
		if pixels==null: return false
		_textures[id]=ImageTexture.create_from_image(pixels)
	if canvas is CanvasItem: canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var side := 40.0*scale_factor
	var disabled := color.r<0.62 and color.g<0.69 and color.b<0.66
	canvas.draw_texture_rect_region(_textures[id],Rect2((center-Vector2.ONE*side*0.5).round(),Vector2.ONE*side),Rect2(Vector2.ZERO,Vector2(SIZE)),Color("838e8d") if disabled else Color.WHITE)
	return true

static func debug_stats() -> Dictionary:
	return {"version":VERSION,"m66_expansion_version":ExpansionAV.VERSION,"authored_items":ITEMS.size(),"authored_skills":SKILLS.size()+ExpansionAV.Data.SKILLS.size()+MageAV.Data.SKILLS.size(),"authored_innates":INNATES.size()+ExpansionAV.Data.IDS.size()+MageAV.Data.IDS.size(),"authored_states":STATES.size(),"frames":_frames.size(),"textures":_textures.size(),"maximum_rgba_bytes":MAX_ICONS*SIZE.x*SIZE.y*4,"runtime_rng":false}

static func _recipe(id: String) -> Array:
	var ranged:=RangedAV.icon_recipe(id)
	if not ranged.is_empty():return ranged
	var mage:=MageAV.icon_recipe(id)
	if not mage.is_empty():return mage
	if ExpansionAV.ICONS.has(id):return ExpansionAV.ICONS[id]
	if ITEMS.has(id): return ITEMS[id]
	if SKILLS.has(id): return SKILLS[id]
	if STATES.has(id): return STATES[id]
	return INNATES[id.trim_prefix("INNATE_")]

static func _hero_for(id: String) -> String:
	if id.begins_with("INNATE_"): return id.trim_prefix("INNATE_")
	for hero: String in Heroes.ARCHETYPES:
		if id in Heroes.PROFILES[hero].skill_ids: return hero
	return "COMMANDER"

static func _palette(id: String) -> Array:
	var mage:=id.trim_prefix("INNATE_") if id.begins_with("INNATE_") else MageAV.Data.owner(id)
	if MageAV.PALETTES.has(mage):
		var colors:Array=MageAV.PALETTES[mage];return [Color(colors[1]),Color(colors[2]),Color(colors[4]),Color(colors[3])]
	var added:=id.trim_prefix("INNATE_") if id.begins_with("INNATE_") else ExpansionAV.Data.owner(id)
	if ExpansionAV.PALETTES.has(added):
		var p:Array=ExpansionAV.PALETTES[added]
		return [Color(p[1]),Color(p[2]),Color(p[4]),Color(p[3])]
	if ITEMS.has(id) or STATES.has(id):
		var result := []
		for code: String in RAMPS[_recipe(id)[2]]: result.append(Color(code))
		return result
	var brief := SpellIdentity.profile(id,_hero_for(id))
	if not brief.is_empty(): return [Color(brief.palette[1]),Color(brief.palette[2]),Color(brief.palette[4]),Color(brief.palette[3])]
	var hero := _hero_for(id)
	var faction := str(Heroes.PROFILES[hero].get("faction_id","HUMAN"))
	var ramp := str({"HUMAN":"gold","UNDEAD":"blood","MACHINE":"blue","FOREST":"jade","HIGHLAND":"ember","UNDERGROUND":"violet"}.get(faction,"gold"))
	var result := []
	for code: String in RAMPS[ramp]: result.append(Color(code))
	return result

static func _point(im: Image,x: int,y: int,c: Color) -> void:
	if x>=1 and y>=1 and x<SIZE.x-1 and y<SIZE.y-1: im.set_pixel(x,y,c)

static func _rect(im: Image,x: int,y: int,w: int,h: int,c: Color) -> void:
	for py: int in range(y,y+h):
		for px: int in range(x,x+w): _point(im,px,py,c)

static func _line(im: Image,a: Vector2i,b: Vector2i,c: Color,width: int=1) -> void:
	var delta := b-a
	var steps := maxi(absi(delta.x),absi(delta.y))
	for step: int in range(steps+1):
		var p := a+Vector2i((Vector2(delta)*float(step)/float(maxi(1,steps))).round())
		_rect(im,p.x-width/2,p.y-width/2,width,width,c)

static func _poly(im: Image,points: Array,offset: Vector2i,c: Color) -> void:
	var vertices := PackedVector2Array()
	for pair: Array in points: vertices.append(Vector2(pair[0]+offset.x,pair[1]+offset.y))
	var bounds := Rect2(vertices[0],Vector2.ZERO)
	for point: Vector2 in vertices: bounds=bounds.expand(point)
	for y: int in range(floori(bounds.position.y),ceili(bounds.end.y)+1):
		for x: int in range(floori(bounds.position.x),ceili(bounds.end.x)+1):
			if Geometry2D.is_point_in_polygon(Vector2(x,y),vertices): _point(im,x,y,c)

static func _ellipse(im: Image,center: Vector2i,rx: int,ry: int,c: Color,hollow: bool=false) -> void:
	for y: int in range(-ry,ry+1):
		for x: int in range(-rx,rx+1):
			var d:=float(x*x)/float(maxi(1,rx*rx))+float(y*y)/float(maxi(1,ry*ry))
			if d<=1.0 and (not hollow or d>=0.53): _point(im,center.x+x,center.y+y,c)

static func _motif(im: Image,kind: String,o: Vector2i,p: Array) -> void:
	var shade: Color=p[0]; var body: Color=p[1]; var light: Color=p[2]; var accent: Color=p[3]
	match kind:
		"blade","broadblade":
			_poly(im,[[5,-9],[8,-10],[7,-5],[-3,6],[-6,3]],o,body)
			_line(im,o+Vector2i(6,-8),o+Vector2i(-4,3),light)
			_line(im,o+Vector2i(-6,1),o+Vector2i(0,7),accent,2)
			_line(im,o+Vector2i(-4,6),o+Vector2i(-8,10),shade,2)
			if kind=="broadblade": _poly(im,[[-2,0],[0,-6],[6,-9],[5,-1],[-1,6]],o,body); _line(im,o+Vector2i(4,-7),o+Vector2i(-2,3),light)
		"twinblades":
			_poly(im,[[-8,-8],[-6,-8],[3,3],[1,5]],o,body); _poly(im,[[7,-9],[8,-6],[-2,6],[-4,3]],o,accent)
			_line(im,o+Vector2i(-7,-8),o+Vector2i(1,2),light); _line(im,o+Vector2i(7,-8),o+Vector2i(-2,3),light)
			_line(im,o+Vector2i(-6,7),o+Vector2i(0,7),shade,2); _line(im,o+Vector2i(1,5),o+Vector2i(5,9),shade,2)
		"plate":
			_poly(im,[[-6,-8],[-2,-7],[0,-4],[3,-7],[7,-8],[9,-3],[5,-1],[5,8],[-5,8],[-5,-1],[-9,-3]],o,body)
			_poly(im,[[-4,-2],[0,0],[4,-2],[3,6],[-3,6]],o,shade); _line(im,o+Vector2i(-5,-6),o+Vector2i(-7,-3),light,2); _line(im,o+Vector2i(0,1),o+Vector2i(0,6),accent)
		"shield":
			_poly(im,[[-7,-7],[0,-9],[7,-7],[6,3],[3,7],[0,10],[-5,5]],o,body)
			_poly(im,[[-5,-5],[0,-7],[4,-5],[4,2],[0,7],[-3,3]],o,shade)
			_line(im,o+Vector2i(-6,-5),o+Vector2i(-5,2),light); _line(im,o+Vector2i(0,-5),o+Vector2i(0,4),accent,2)
		"bastion":
			_rect(im,o.x-8,o.y-3,16,12,shade)
			for x: int in [-8,-2,4]: _rect(im,o.x+x,o.y-8,4,13,body); _rect(im,o.x+x,o.y-8,2,2,light)
			_poly(im,[[-3,9],[-3,3],[0,0],[3,3],[3,9]],o,INK); _line(im,o+Vector2i(-8,8),o+Vector2i(8,8),accent)
		"glove","hand","hands":
			_poly(im,[[-5,9],[-6,1],[-9,-2],[-8,-5],[-5,-3],[-5,-9],[-3,-9],[-2,-3],[-1,-10],[1,-10],[1,-3],[3,-8],[5,-8],[4,-1],[6,-4],[8,-3],[5,5],[3,9]],o,body)
			_line(im,o+Vector2i(-4,6),o+Vector2i(3,6),shade,2); _line(im,o+Vector2i(-3,-7),o+Vector2i(-2,0),light)
			if kind=="glove": _rect(im,o.x-4,o.y+6,7,4,accent); _point(im,o.x,o.y+7,light)
			if kind=="hands": _line(im,o+Vector2i(-8,7),o+Vector2i(-9,1),accent,3); _line(im,o+Vector2i(7,7),o+Vector2i(9,0),accent,3)
		"cloak":
			_poly(im,[[-3,-9],[3,-9],[5,-4],[8,7],[3,10],[0,8],[-4,10],[-8,7],[-5,-4]],o,body)
			_poly(im,[[-2,-6],[2,-6],[3,-2],[-3,-2]],o,INK); _line(im,o+Vector2i(-3,-1),o+Vector2i(-5,7),light); _line(im,o+Vector2i(2,0),o+Vector2i(4,7),shade,2); _point(im,o.x,o.y,accent)
		"lens":
			_line(im,o+Vector2i(-7,6),o+Vector2i(7,-6),shade,7); _line(im,o+Vector2i(-7,5),o+Vector2i(6,-7),body,5)
			_ellipse(im,o+Vector2i(7,-6),3,4,accent); _line(im,o+Vector2i(5,-7),o+Vector2i(7,-8),light,2); _line(im,o+Vector2i(-7,3),o+Vector2i(-4,6),light)
		"heart":
			_poly(im,[[-7,-5],[-4,-8],[0,-5],[4,-8],[7,-5],[7,0],[0,9],[-7,0]],o,body)
			_line(im,o+Vector2i(-5,-5),o+Vector2i(-5,-1),light,2); _line(im,o+Vector2i(0,6),o+Vector2i(5,0),shade,2)
		"gem","crystals","ice":
			_poly(im,[[0,-10],[5,-4],[4,4],[0,9],[-5,2],[-4,-5]],o,body); _line(im,o+Vector2i(0,-8),o+Vector2i(-1,4),light,2); _poly(im,[[2,-4],[4,-3],[3,3],[0,8]],o,shade)
			if kind!="gem": _poly(im,[[-9,-3],[-6,-6],[-5,2],[-3,6],[-7,6]],o,accent); _poly(im,[[6,-6],[9,-3],[8,5],[5,8]],o,body); _point(im,o.x+7,o.y-3,light)
		"ring","bead":
			_ellipse(im,o+Vector2i(0,2),7,7,body,true); _line(im,o+Vector2i(-6,2),o+Vector2i(-4,6),light,2)
			if kind=="ring": _poly(im,[[-4,-4],[0,-8],[4,-4],[0,0]],o,accent); _point(im,o.x,o.y-6,light)
			else: _ellipse(im,o+Vector2i(0,-3),5,5,accent); _rect(im,o.x-2,o.y-6,2,3,light)
		"seal","rune":
			_poly(im,[[-6,-7],[5,-8],[8,-2],[5,6],[-1,9],[-7,4]],o,shade)
			if kind=="seal": _ellipse(im,o,6,6,body); _line(im,o+Vector2i(-4,0),o+Vector2i(4,0),light,2); _line(im,o+Vector2i(0,-4),o+Vector2i(0,4),accent,2)
			else: _line(im,o+Vector2i(-4,3),o+Vector2i(2,-6),body,2); _line(im,o+Vector2i(-3,-3),o+Vector2i(4,2),accent,2); _line(im,o+Vector2i(1,2),o+Vector2i(-1,6),light,2)
		"jar","bottle","flask","ampoule","vial":
			var wide := 6 if kind in ["jar","flask"] else 3 if kind=="vial" else 5
			_poly(im,[[-3,-8],[3,-8],[3,-3],[wide,-1],[wide,7],[wide-2,9],[-wide+2,9],[-wide,7],[-wide,-1],[-3,-3]],o,body)
			_rect(im,o.x-3,o.y-10,6,3,shade); _rect(im,o.x-3,o.y-8,2,4,light)
			_poly(im,[[-wide+1,2],[0,1],[wide-1,2],[wide-1,6],[wide-3,8],[-wide+2,8]],o,accent); _rect(im,o.x-wide+1,o.y,2,5,light)
			if kind=="ampoule": _rect(im,o.x-1,o.y-9,2,17,light); _line(im,o+Vector2i(-3,9),o+Vector2i(3,9),shade,2)
			if kind=="jar": _rect(im,o.x-5,o.y-7,10,3,accent)
		"staff":
			_line(im,o+Vector2i(-5,10),o+Vector2i(3,-6),shade,3); _line(im,o+Vector2i(-5,9),o+Vector2i(3,-6),body)
			_poly(im,[[2,-10],[7,-7],[5,-3],[1,-2],[-1,-6]],o,accent); _line(im,o+Vector2i(2,-8),o+Vector2i(4,-7),light,2)
		"flag","pennant":
			_line(im,o+Vector2i(-6,-10),o+Vector2i(-6,10),shade,2); _line(im,o+Vector2i(-7,-9),o+Vector2i(-7,8),light)
			if kind=="flag": _poly(im,[[-5,-8],[7,-7],[5,-3],[8,2],[-5,1]],o,body)
			else: _poly(im,[[-5,-9],[7,-7],[4,-2],[7,2],[-5,6]],o,body)
			_line(im,o+Vector2i(-4,-7),o+Vector2i(4,-6),light); _rect(im,o.x-3,o.y-3,4,2,accent)
		"arrow","bone_arrow","arrows":
			_line(im,o+Vector2i(-7,8),o+Vector2i(6,-6),body,2); _poly(im,[[2,-7],[8,-10],[7,-3]],o,light); _line(im,o+Vector2i(-9,4),o+Vector2i(-4,9),accent,2)
			if kind=="bone_arrow": _rect(im,o.x-3,o.y,3,2,shade); _rect(im,o.x,o.y-3,3,2,shade)
			if kind=="arrows": _line(im,o+Vector2i(-9,0),o+Vector2i(0,-9),accent,2); _line(im,o+Vector2i(0,9),o+Vector2i(9,0),body,2)
		"bow":
			_poly(im,[[-6,-9],[0,-6],[4,0],[3,5],[-1,10],[2,4],[2,0],[-1,-5]],o,body); _line(im,o+Vector2i(-6,-9),o+Vector2i(-1,10),light); _line(im,o+Vector2i(-8,6),o+Vector2i(7,-5),accent)
		"quiver":
			_poly(im,[[-6,-1],[2,-5],[7,7],[-1,10]],o,body); _line(im,o+Vector2i(-5,-2),o+Vector2i(1,-5),light,2)
			for x: int in [-4,0,4]: _line(im,o+Vector2i(x+2,2),o+Vector2i(x-2,-9),accent); _rect(im,o.x+x-3,o.y-9,3,3,light)
		"star","comet":
			_poly(im,[[0,-9],[2,-3],[8,-4],[4,1],[7,6],[1,4],[-3,9],[-3,3],[-9,0],[-3,-2]],o,body); _ellipse(im,o,2,2,light)
			if kind=="comet": _line(im,o+Vector2i(-2,2),o+Vector2i(-8,9),accent,3)
		"lantern","candle":
			if kind=="lantern": _line(im,o+Vector2i(-4,-6),o+Vector2i(4,-6),accent,2); _rect(im,o.x-5,o.y-4,11,11,shade); _rect(im,o.x-3,o.y-3,7,8,body); _line(im,o+Vector2i(-3,-9),o+Vector2i(3,-9),body); _line(im,o+Vector2i(-3,-9),o+Vector2i(-4,-7),body); _line(im,o+Vector2i(3,-9),o+Vector2i(4,-7),body); _rect(im,o.x-6,o.y+7,13,2,accent)
			else: _rect(im,o.x-3,o.y-1,7,10,body); _line(im,o+Vector2i(-3,0),o+Vector2i(2,0),light); _point(im,o.x+1,o.y+2,accent)
			_poly(im,[[0,-7],[2,-3],[1,1],[-2,-1],[-2,-4]],o,light)
		"rib","coffin","skull":
			if kind=="rib":
				_line(im,o+Vector2i(0,-8),o+Vector2i(0,9),accent,2)
				for y: int in [-6,-1,4]: _line(im,o+Vector2i(-6,y-2),o+Vector2i(-7,y+1),body,2); _line(im,o+Vector2i(-7,y+1),o+Vector2i(6,y+1),body,2); _line(im,o+Vector2i(6,y+1),o+Vector2i(5,y-2),light)
			elif kind=="coffin": _poly(im,[[-4,-10],[4,-10],[7,-4],[4,10],[-4,10],[-7,-4]],o,body); _poly(im,[[-3,-7],[3,-7],[4,-3],[2,7],[-2,7],[-4,-3]],o,shade); _line(im,o+Vector2i(-2,-2),o+Vector2i(2,-2),light); _line(im,o+Vector2i(0,-4),o+Vector2i(0,3),accent)
			else: _ellipse(im,o+Vector2i(0,-2),7,7,body); _rect(im,o.x-4,o.y+3,9,5,body); _rect(im,o.x-5,o.y-3,3,3,INK); _rect(im,o.x+2,o.y-3,3,3,INK); _point(im,o.x,o.y+1,shade); _line(im,o+Vector2i(-3,5),o+Vector2i(3,5),accent)
		"hook":
			_line(im,o+Vector2i(5,-9),o+Vector2i(-4,1),shade,2); _poly(im,[[-5,-2],[-7,3],[-5,8],[0,9],[6,4],[5,1],[2,6],[-2,6],[-4,3]],o,body); _line(im,o+Vector2i(-6,2),o+Vector2i(-4,6),light)
		"bell":
			_poly(im,[[-2,-9],[2,-9],[2,-7],[5,-5],[5,1],[8,5],[8,7],[-8,7],[-8,5],[-5,1],[-5,-5],[-2,-7]],o,body); _line(im,o+Vector2i(-4,-4),o+Vector2i(-4,3),light,2); _ellipse(im,o+Vector2i(0,9),2,1,accent); _line(im,o+Vector2i(-6,6),o+Vector2i(6,6),shade)
		"gear","rotor","rivet":
			_ellipse(im,o,6,6,body)
			for d: Vector2i in [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]: _rect(im,o.x+d.x*7-1,o.y+d.y*7-1,3,3,accent)
			if kind=="gear": _ellipse(im,o,3,3,INK); _ellipse(im,o+Vector2i(-1,-1),1,1,light)
			elif kind=="rotor":
				for q: Vector2i in [Vector2i(1,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(-1,-1)]: _line(im,o+q*2,o+q*6,shade,2)
				_ellipse(im,o,2,2,light)
			else: _poly(im,[[0,-4],[4,0],[0,4],[-4,0]],o,shade); _line(im,o+Vector2i(-2,-2),o+Vector2i(2,2),light)
		"coil","battery":
			_rect(im,o.x-4,o.y-8,9,16,shade); _rect(im,o.x-2,o.y-10,5,2,accent)
			for y: int in [-6,-2,2,6]: _line(im,o+Vector2i(-6,y),o+Vector2i(6,y-2),body,2); _point(im,o.x-5,o.y+y,light)
			if kind=="battery": _rect(im,o.x-3,o.y-5,7,11,body); _line(im,o+Vector2i(0,-3),o+Vector2i(0,3),light,2); _line(im,o+Vector2i(-2,0),o+Vector2i(2,0),light,2)
		"bolt": _poly(im,[[0,-10],[6,-10],[1,-2],[6,-2],[-4,10],[-1,1],[-6,1]],o,body); _line(im,o+Vector2i(1,-8),o+Vector2i(-2,-1),light,2)
		"circuit","antenna","satellite":
			if kind=="circuit":
				_rect(im,o.x-3,o.y-3,7,7,shade); _rect(im,o.x-1,o.y-1,3,3,light)
				for v: Vector2i in [Vector2i(-8,-7),Vector2i(8,-6),Vector2i(7,8),Vector2i(-7,7)]: _line(im,o,o+Vector2i(v.x,0),body); _line(im,o+Vector2i(v.x,0),o+v,body); _rect(im,o.x+v.x-1,o.y+v.y-1,3,3,accent)
			elif kind=="antenna": _line(im,o+Vector2i(0,-8),o+Vector2i(0,8),body,2); _poly(im,[[-5,9],[0,2],[5,9]],o,shade); _ellipse(im,o+Vector2i(0,-8),2,2,light); _line(im,o+Vector2i(-5,-6),o+Vector2i(5,-6),accent)
			else: _ellipse(im,o,4,4,body); _rect(im,o.x-9,o.y-6,4,7,accent); _rect(im,o.x+6,o.y+1,4,7,accent); _line(im,o+Vector2i(-6,-2),o+Vector2i(6,3),light,2)
		"gate": _rect(im,o.x-8,o.y-8,4,17,body); _rect(im,o.x+5,o.y-8,4,17,body); _rect(im,o.x-8,o.y-8,17,4,accent); _line(im,o+Vector2i(-6,-6),o+Vector2i(-6,7),light); _line(im,o+Vector2i(0,-2),o+Vector2i(0,8),shade,2)
		"bullet","missile","drill":
			_poly(im,[[-6,8],[-8,4],[3,-7],[8,-10],[8,-4],[-2,8]],o,body); _line(im,o+Vector2i(-4,3),o+Vector2i(6,-7),light,2); _line(im,o+Vector2i(-7,4),o+Vector2i(-2,8),accent,2)
			if kind=="missile": _poly(im,[[-4,1],[-9,-1],[-5,-4],[1,-5]],o,accent); _poly(im,[[0,6],[2,10],[5,6],[5,0]],o,accent)
			if kind=="drill":
				for d: int in [-3,0,3]: _line(im,o+Vector2i(d-4,-d+2),o+Vector2i(d+2,-d+6),shade)
		"wrench":
			_line(im,o+Vector2i(-6,9),o+Vector2i(3,-4),body,4); _poly(im,[[0,-6],[1,-10],[4,-10],[2,-6],[5,-3],[8,-6],[9,-3],[5,0],[1,-1]],o,accent); _line(im,o+Vector2i(-6,8),o+Vector2i(-1,1),light)
		"lily","bloom","sprout","leaf":
			_line(im,o+Vector2i(0,-1),o+Vector2i(0,10),shade,2)
			if kind=="leaf": _poly(im,[[-7,5],[-6,-2],[-1,-8],[7,-10],[6,-2],[1,5]],o,body); _line(im,o+Vector2i(-5,5),o+Vector2i(5,-7),light); _line(im,o+Vector2i(-1,1),o+Vector2i(3,1),accent)
			elif kind=="sprout": _poly(im,[[-1,0],[-7,-2],[-8,-6],[-3,-5],[0,-1]],o,body); _poly(im,[[0,-2],[1,-7],[6,-10],[7,-5],[3,-1]],o,accent); _line(im,o+Vector2i(1,-4),o+Vector2i(5,-7),light)
			else:
				for dx: int in [-6,0,6]: _poly(im,[[dx,-8-abs(dx)/3],[dx+3,-4],[dx+2,1],[0,4],[dx-3,-2]],o,accent if dx==0 else body)
				_rect(im,o.x-2,o.y-1,5,3,light)
				if kind=="lily": _ellipse(im,o+Vector2i(0,6),8,3,shade); _line(im,o+Vector2i(-5,5),o+Vector2i(5,5),body)
		"roots","vine","thorns","maze":
			if kind=="maze":
				for x: int in [-7,-1,5]: _line(im,o+Vector2i(x,-8),o+Vector2i(x,7),body,2)
				_line(im,o+Vector2i(-7,-8),o+Vector2i(7,-8),accent,2); _line(im,o+Vector2i(-7,7),o+Vector2i(7,7),accent,2); _rect(im,o.x-5,o.y+1,4,2,body)
			else:
				_line(im,o+Vector2i(-6,9),o+Vector2i(0,-5),body,3); _line(im,o+Vector2i(0,-5),o+Vector2i(6,-9),body,2); _line(im,o+Vector2i(-1,0),o+Vector2i(7,5),accent,2)
				for y: int in [-5,0,5]: _poly(im,[[-3,y],[-8,y-3],[-6,y+2]],o,accent)
				if kind=="roots": _line(im,o+Vector2i(0,0),o+Vector2i(1,9),shade,3); _line(im,o+Vector2i(2,6),o+Vector2i(7,9),body,2)
				if kind=="thorns": _poly(im,[[2,-5],[9,-6],[4,-1]],o,light); _poly(im,[[1,4],[9,6],[3,7]],o,light)
		"mushroom":
			_rect(im,o.x-2,o.y,5,10,shade); _poly(im,[[-9,0],[-7,-5],[-3,-8],[3,-8],[7,-4],[9,1],[3,3],[-3,3]],o,body); _rect(im,o.x-5,o.y-5,3,2,light); _rect(im,o.x+3,o.y-2,2,2,accent); _line(im,o+Vector2i(-2,8),o+Vector2i(2,8),light)
		"shell":
			_poly(im,[[0,-10],[6,-7],[9,-1],[7,6],[0,10],[-7,6],[-9,-1],[-6,-7]],o,body); _line(im,o+Vector2i(0,-7),o+Vector2i(0,7),shade,2); _line(im,o+Vector2i(-5,-4),o+Vector2i(-7,2),light,2); _line(im,o+Vector2i(2,-3),o+Vector2i(7,-1),accent)
		"jaw","fang","mantis":
			if kind=="fang": _poly(im,[[-4,-9],[5,-7],[6,-1],[1,5],[-5,10],[-2,2],[-3,-4]],o,body); _line(im,o+Vector2i(-2,-7),o+Vector2i(3,-5),light,2)
			elif kind=="mantis": _line(im,o+Vector2i(0,-7),o+Vector2i(0,9),body,3); _poly(im,[[-1,-5],[-7,-10],[-9,-4],[-7,1],[-6,-6]],o,accent); _poly(im,[[1,-4],[8,-8],[9,-2],[6,3],[7,-5]],o,body); _line(im,o+Vector2i(-4,4),o+Vector2i(-8,9),light,2); _line(im,o+Vector2i(3,3),o+Vector2i(7,8),accent,2)
			else:
				_poly(im,[[-9,-7],[-5,-9],[-7,0],[-3,6],[0,9],[-6,7],[-9,2]],o,body); _poly(im,[[9,-7],[5,-9],[7,0],[3,6],[0,9],[6,7],[9,2]],o,accent)
				for y: int in [-5,0,4]: _line(im,o+Vector2i(-7,y),o+Vector2i(-4,y+1),light,2); _line(im,o+Vector2i(7,y),o+Vector2i(4,y+1),light,2)
		"mountain","volcano","slab":
			if kind=="slab": _poly(im,[[-8,-7],[5,-9],[9,-3],[7,8],[-7,9],[-9,2]],o,body); _line(im,o+Vector2i(0,-6),o+Vector2i(-2,0),shade,2); _line(im,o+Vector2i(-2,0),o+Vector2i(3,5),accent,2); _line(im,o+Vector2i(-7,-4),o+Vector2i(-7,3),light)
			else: _poly(im,[[-10,8],[-3,-7],[0,-10],[3,-5],[10,8]],o,body); _poly(im,[[0,-9],[0,8],[9,8]],o,shade); _poly(im,[[-4,-3],[0,-9],[3,-3],[0,-4],[-2,-1]],o,light if kind=="mountain" else accent)
		"hammer":
			_line(im,o+Vector2i(-5,10),o+Vector2i(3,-6),shade,3); _poly(im,[[-3,-9],[4,-10],[9,-6],[5,0],[-2,-3],[-5,-6]],o,body); _line(im,o+Vector2i(-2,-8),o+Vector2i(3,-9),light,2); _rect(im,o.x+5,o.y-5,2,2,accent)
		"hearth","tent":
			if kind=="hearth": _rect(im,o.x-8,o.y-7,17,16,body); _rect(im,o.x-5,o.y-4,11,12,INK); _rect(im,o.x-9,o.y-9,19,3,accent); _rect(im,o.x-9,o.y+8,19,2,shade)
			else: _poly(im,[[-10,8],[0,-9],[10,8]],o,body); _poly(im,[[-5,8],[0,-5],[5,8]],o,shade); _line(im,o+Vector2i(0,-9),o+Vector2i(7,6),light); _line(im,o+Vector2i(-10,9),o+Vector2i(-7,9),accent,2)
		"flame": _poly(im,[[0,-10],[4,-4],[4,-7],[8,0],[6,7],[0,10],[-6,7],[-8,1],[-5,-5],[-4,0],[-1,-4]],o,body); _poly(im,[[0,-3],[4,3],[2,7],[-2,8],[-3,3]],o,light); _line(im,o+Vector2i(-6,4),o+Vector2i(-3,7),accent)
		"horn": _poly(im,[[-9,2],[-6,-1],[-4,2],[0,2],[5,-1],[7,-7],[10,-8],[9,0],[5,5],[-1,8],[-6,7]],o,body); _line(im,o+Vector2i(-5,5),o+Vector2i(2,4),light,2); _line(im,o+Vector2i(-8,0),o+Vector2i(-4,7),accent,2)
		"eye": _poly(im,[[-9,0],[-4,-5],[3,-6],[9,0],[5,5],[-3,6]],o,body); _ellipse(im,o,4,4,accent); _ellipse(im,o,2,3,INK); _point(im,o.x-1,o.y-2,light)
		"boot": _poly(im,[[-5,-9],[2,-9],[2,1],[5,3],[8,3],[9,7],[6,9],[-6,9],[-7,6],[-5,1]],o,body); _rect(im,o.x-5,o.y-7,7,3,accent); _line(im,o+Vector2i(-4,-2),o+Vector2i(-4,5),light); _line(im,o+Vector2i(-5,7),o+Vector2i(7,7),shade,2)

static func _context(im: Image,kind: String,p: Array) -> void:
	var c: Color=p[3]; var b: Color=p[1]; var l: Color=p[2]; var o:=Vector2i(12,12)
	match kind:
		"plain","round": pass
		"long": _line(im,Vector2i(2,20),Vector2i(17,5),b,3); _line(im,Vector2i(2,18),Vector2i(17,3),l)
		"pendant": _line(im,Vector2i(5,2),Vector2i(8,7),c); _line(im,Vector2i(19,2),Vector2i(16,7),c); _line(im,Vector2i(5,2),Vector2i(19,2),b)
		"orbit","halo": _ellipse(im,o,10,8,c,true); _rect(im,3,6,2,2,l)
		"wave": _line(im,Vector2i(2,17),Vector2i(7,20),c,2); _line(im,Vector2i(7,20),Vector2i(16,18),c,2); _line(im,Vector2i(16,18),Vector2i(21,20),l)
		"sprout","lily","branches","bloom","roots","arbor","canopy":
			_line(im,Vector2i(2,19),Vector2i(5,9),c,2); _line(im,Vector2i(21,20),Vector2i(19,8),c,2)
			_poly(im,[[1,11],[1,6],[6,9],[5,13]],Vector2i.ZERO,b); _poly(im,[[18,9],[22,4],[22,10],[20,13]],Vector2i.ZERO,l)
			if kind in ["arbor","canopy"]: _line(im,Vector2i(4,6),Vector2i(12,2),c,2); _line(im,Vector2i(12,2),Vector2i(21,5),b,2)
			if kind=="roots": _line(im,Vector2i(3,17),Vector2i(8,22),b,2); _line(im,Vector2i(17,20),Vector2i(21,22),c,2)
		"heart": _poly(im,[[-4,-1],[-2,-4],[0,-2],[2,-4],[4,-1],[0,4]],Vector2i(5,17),c)
		"cross": _rect(im,2,5,7,3,l); _rect(im,4,3,3,7,c)
		"crown": _poly(im,[[2,7],[2,2],[6,5],[10,1],[12,5],[17,1],[20,5],[22,2],[21,7]],Vector2i.ZERO,c); _line(im,Vector2i(4,7),Vector2i(20,7),l)
		"weave","stitch":
			_line(im,Vector2i(2,5),Vector2i(21,18),c); _line(im,Vector2i(3,3),Vector2i(20,20),b)
			for x: int in [3,7,11,15,19]: _line(im,Vector2i(x,6+x/2),Vector2i(x+2,3+x/2),l)
			if kind=="weave":
				_line(im,Vector2i(2,8),Vector2i(2,19),b,2); _line(im,Vector2i(2,19),Vector2i(7,22),c,2)
				_line(im,Vector2i(21,8),Vector2i(21,20),c,2); _line(im,Vector2i(21,20),Vector2i(17,22),l)
		"crack","cut","fissure","tectonic","rift":
			_line(im,Vector2i(3,2),Vector2i(8,8),c,2); _line(im,Vector2i(8,8),Vector2i(3,12),c,2); _line(im,Vector2i(3,12),Vector2i(7,22),b,2)
			_line(im,Vector2i(17,2),Vector2i(21,8),l); _line(im,Vector2i(21,8),Vector2i(17,16),c,2)
			if kind=="tectonic": _rect(im,16,19,6,3,b)
			if kind=="rift": _line(im,Vector2i(19,18),Vector2i(22,21),l,2)
		"blade": _line(im,Vector2i(2,21),Vector2i(18,3),c,3); _line(im,Vector2i(3,18),Vector2i(8,22),l,2)
		"shield","bastion":
			_poly(im,[[1,8],[5,6],[9,8],[8,14],[5,18],[2,14]],Vector2i.ZERO,c)
			if kind=="bastion": _rect(im,17,4,5,16,b); _rect(im,16,2,3,4,l); _rect(im,20,2,3,4,c)
		"gem","crystal_wings":
			_poly(im,[[1,13],[4,7],[7,13],[5,20]],Vector2i.ZERO,c)
			if kind=="crystal_wings": _poly(im,[[17,12],[21,5],[22,13],[18,20]],Vector2i.ZERO,l)
		"tall": _rect(im,9,1,6,7,b); _rect(im,10,2,2,3,l)
		"twin": _rect(im,2,8,4,11,c); _rect(im,2,6,4,3,b); _rect(im,19,7,3,12,l); _rect(im,18,5,5,3,b)
		"spray","spores","shrapnel","embers":
			for particle: Array in [[2,3,3,2],[18,2,2,3],[1,13,2,2],[20,17,3,3],[4,21,2,1]]: _rect(im,particle[0],particle[1],particle[2],particle[3],l if int(particle[0])>12 else c)
			if kind=="spores": _ellipse(im,Vector2i(18,6),2,2,c)
		"wing","feather":
			_poly(im,[[2,12],[1,3],[4,6],[8,5],[7,10],[10,13],[6,13]],Vector2i.ZERO,c); _poly(im,[[17,13],[21,4],[22,11],[20,17]],Vector2i.ZERO,l)
		"flame": _poly(im,[[1,20],[1,13],[4,7],[4,13],[7,11],[7,18],[5,22]],Vector2i.ZERO,c); _poly(im,[[17,21],[20,13],[19,8],[22,12],[22,19],[20,22]],Vector2i.ZERO,l)
		"crescent": _ellipse(im,Vector2i(5,8),4,7,c); _ellipse(im,Vector2i(7,6),3,5,Color.TRANSPARENT)
		"sweep","fire_sweep","vortex","spin":
			_line(im,Vector2i(2,7),Vector2i(5,3),c,2); _line(im,Vector2i(5,3),Vector2i(16,1),c,2); _line(im,Vector2i(16,1),Vector2i(21,6),l,2)
			_line(im,Vector2i(22,15),Vector2i(18,20),b,2); _line(im,Vector2i(18,20),Vector2i(7,22),c,2)
			if kind=="fire_sweep": _poly(im,[[19,16],[22,10],[21,19]],Vector2i.ZERO,l)
			if kind=="vortex": _line(im,Vector2i(3,11),Vector2i(1,17),l,2)
		"rays","impact","thunder","temper":
			for ray: Array in [[[2,4],[5,7]],[[19,2],[17,6]],[[22,14],[19,15]],[[5,21],[7,18]]]: _line(im,Vector2i(ray[0][0],ray[0][1]),Vector2i(ray[1][0],ray[1][1]),c,2)
			if kind=="thunder": _poly(im,[[1,1],[6,1],[3,5],[6,5],[1,11],[3,5],[1,5]],Vector2i.ZERO,l)
			if kind=="temper": _rect(im,17,19,6,3,c)
		"guard","cage","lock":
			_line(im,Vector2i(2,5),Vector2i(2,20),b,2); _line(im,Vector2i(22,4),Vector2i(22,20),c,2)
			_line(im,Vector2i(2,20),Vector2i(10,22),l,2); _line(im,Vector2i(22,20),Vector2i(15,22),l,2)
			if kind=="cage": _line(im,Vector2i(3,3),Vector2i(20,2),c,2)
			if kind=="lock": _rect(im,1,1,6,5,l)
		"falling":
			for v: Vector2i in [Vector2i(2,2),Vector2i(9,1),Vector2i(19,3)]: _line(im,v,v+Vector2i(0,5),c,2)
			_line(im,Vector2i(3,21),Vector2i(19,21),b,2)
		"trail","lance","pin","wind":
			_line(im,Vector2i(1,16),Vector2i(9,8),c,2); _line(im,Vector2i(3,22),Vector2i(12,13),b,2)
			if kind=="lance": _line(im,Vector2i(2,13),Vector2i(20,1),l)
			if kind=="pin": _line(im,Vector2i(17,17),Vector2i(22,22),c,2); _line(im,Vector2i(17,21),Vector2i(21,17),l,2)
			if kind=="wind": _line(im,Vector2i(1,10),Vector2i(6,6),l); _line(im,Vector2i(3,9),Vector2i(1,5),c)
		"seal": _rect(im,1,1,7,7,c); _line(im,Vector2i(2,3),Vector2i(6,6),l,2); _rect(im,17,18,5,4,b)
		"chain":
			for point: Vector2i in [Vector2i(3,4),Vector2i(2,10),Vector2i(4,17),Vector2i(20,6),Vector2i(21,13),Vector2i(19,20)]: _ellipse(im,point,2,3,c,true)
		"wisps","choir","afterglow":
			_poly(im,[[1,18],[3,12],[2,6],[6,10],[6,17],[4,21]],Vector2i.ZERO,c); _poly(im,[[18,22],[20,15],[18,8],[22,11],[23,18],[21,22]],Vector2i.ZERO,l)
			if kind=="choir": _ellipse(im,Vector2i(12,2),3,1,b)
			if kind=="afterglow": _rect(im,8,21,8,2,b)
		"extraction","implosion":
			for v: Vector2i in [Vector2i(2,2),Vector2i(21,3),Vector2i(1,21),Vector2i(22,21)]: _line(im,v,Vector2i(12,12),c,2)
			if kind=="implosion": _line(im,Vector2i(2,10),Vector2i(5,12),l,2)
		"rivets":
			for point: Vector2i in [Vector2i(2,3),Vector2i(21,3),Vector2i(2,20),Vector2i(21,20)]: _rect(im,point.x,point.y,2,2,c)
		"bolt","fork","storm":
			_poly(im,[[1,2],[6,2],[3,7],[6,7],[1,14],[3,8],[1,8]],Vector2i.ZERO,c)
			_line(im,Vector2i(18,1),Vector2i(22,7),l,2); _line(im,Vector2i(22,7),Vector2i(18,13),c,2)
			if kind=="storm": _rect(im,3,20,4,2,b); _rect(im,18,18,4,3,c)
		"fan":
			for end: Vector2i in [Vector2i(1,1),Vector2i(10,1),Vector2i(21,3)]: _line(im,Vector2i(4,21),end,c,2)
		"repair","dock":
			_rect(im,1,16,6,3,c); _rect(im,3,14,2,7,l)
			_rect(im,18,3,4,6,b)
			if kind=="dock": _rect(im,1,20,21,2,c); _rect(im,19,13,3,8,l)
		"signal","blackout","stable":
			_line(im,Vector2i(1,5),Vector2i(4,2),c,2); _line(im,Vector2i(4,2),Vector2i(8,1),l)
			_line(im,Vector2i(17,1),Vector2i(21,4),c,2); _line(im,Vector2i(21,4),Vector2i(22,9),l)
			if kind=="blackout": _line(im,Vector2i(2,20),Vector2i(21,2),c,2)
			if kind=="stable": _rect(im,2,19,7,3,b)
		"drop": _poly(im,[[3,2],[6,8],[5,11],[1,10],[1,6]],Vector2i.ZERO,l); _point(im,3,7,c)
		"whip": _line(im,Vector2i(1,2),Vector2i(9,2),c,2); _line(im,Vector2i(9,2),Vector2i(21,9),c,2); _line(im,Vector2i(21,9),Vector2i(20,19),l,2); _line(im,Vector2i(20,19),Vector2i(15,22),b,2)
		"silence": _line(im,Vector2i(2,2),Vector2i(22,22),c,2); _rect(im,1,17,3,2,l); _rect(im,20,4,3,2,b)
		"hand": _poly(im,[[1,14],[5,13],[7,17],[12,19],[19,17],[22,19],[18,22],[6,22]],Vector2i.ZERO,c)
		"campfire": _poly(im,[[2,17],[5,9],[7,14],[10,11],[9,19],[5,22]],Vector2i.ZERO,l); _line(im,Vector2i(17,20),Vector2i(22,22),c,2)
		"mycelium":
			for end: Vector2i in [Vector2i(1,20),Vector2i(3,13),Vector2i(22,21),Vector2i(21,12)]: _line(im,Vector2i(12,20),end,c,2)
			_line(im,Vector2i(3,16),Vector2i(1,13),l); _line(im,Vector2i(19,18),Vector2i(22,16),l)
		"oath": _line(im,Vector2i(1,3),Vector2i(8,1),c,2); _line(im,Vector2i(15,2),Vector2i(22,6),l,2); _line(im,Vector2i(1,20),Vector2i(5,22),b,2)
		"companions","formation":
			for x: int in [2,20]: _ellipse(im,Vector2i(x,7),2,2,c); _rect(im,x-1,11,3,7,b)
			if kind=="formation": _rect(im,8,1,8,2,l); _rect(im,8,22,8,1,l)
		"peace": _line(im,Vector2i(2,3),Vector2i(7,7),c,2); _line(im,Vector2i(2,7),Vector2i(7,3),l,2); _rect(im,19,15,3,6,b)
		"delayed": _ellipse(im,Vector2i(4,4),3,3,c,true); _line(im,Vector2i(4,4),Vector2i(4,1),l); _rect(im,20,16,2,5,b)
		"wounded": _poly(im,[[1,4],[4,1],[7,3],[7,8],[2,11]],Vector2i.ZERO,c); _line(im,Vector2i(2,5),Vector2i(6,5),INK,2); _line(im,Vector2i(17,21),Vector2i(22,17),l,2)
		"anchor": _line(im,Vector2i(2,18),Vector2i(21,18),c,2); _line(im,Vector2i(2,18),Vector2i(2,12),l,2); _line(im,Vector2i(21,18),Vector2i(21,12),l,2); _rect(im,8,21,8,2,b)
		"triphase": _ellipse(im,Vector2i(3,3),2,2,l); _ellipse(im,Vector2i(21,8),2,2,c); _ellipse(im,Vector2i(18,22),2,1,b); _line(im,Vector2i(3,3),Vector2i(21,8),c)
		"sight": _line(im,Vector2i(1,4),Vector2i(1,1),l,2); _line(im,Vector2i(1,1),Vector2i(6,1),l,2); _line(im,Vector2i(18,22),Vector2i(22,22),c,2); _line(im,Vector2i(22,22),Vector2i(22,18),c,2)
		"mountain": _poly(im,[[1,22],[6,10],[10,22]],Vector2i.ZERO,c); _poly(im,[[16,22],[20,12],[23,22]],Vector2i.ZERO,l)
		"coal": _poly(im,[[1,16],[5,14],[8,18],[5,22],[1,21]],Vector2i.ZERO,c); _rect(im,19,2,3,3,l)
		"warmth": _ellipse(im,Vector2i(12,21),9,1,c); _line(im,Vector2i(2,12),Vector2i(1,5),b,2); _line(im,Vector2i(21,11),Vector2i(22,3),l,2)
		"sharing": _line(im,Vector2i(1,3),Vector2i(8,3),c,2); _line(im,Vector2i(1,3),Vector2i(4,1),l); _line(im,Vector2i(16,20),Vector2i(22,20),b,2); _line(im,Vector2i(22,20),Vector2i(19,22),l)
		"aftershock": _line(im,Vector2i(1,3),Vector2i(5,5),c,2); _line(im,Vector2i(5,5),Vector2i(1,8),c,2); _line(im,Vector2i(19,14),Vector2i(22,17),l,2); _line(im,Vector2i(22,17),Vector2i(19,21),l,2)
		"confused": _ellipse(im,Vector2i(12,12),10,5,c,true); _rect(im,2,3,3,2,l); _rect(im,20,19,2,3,b)
		"shackles": _ellipse(im,Vector2i(3,17),2,4,c,true); _ellipse(im,Vector2i(20,18),2,4,l,true); _line(im,Vector2i(3,20),Vector2i(20,22),c)
		"snow":
			for point: Vector2i in [Vector2i(3,4),Vector2i(19,2),Vector2i(21,17)]: _line(im,point-Vector2i(2,0),point+Vector2i(2,0),l); _line(im,point-Vector2i(0,2),point+Vector2i(0,2),c)
		"fracture": _line(im,Vector2i(3,1),Vector2i(20,22),l,3); _line(im,Vector2i(13,10),Vector2i(20,6),c,2); _rect(im,1,17,3,5,b)
		"wall": _rect(im,1,5,3,17,c); _rect(im,20,5,3,17,b); _rect(im,1,3,6,3,l); _rect(im,17,3,6,3,l)
		"march_steps":
			_rect(im,2,1,3,5,c); _rect(im,6,8,3,5,l); _rect(im,15,17,3,5,c); _rect(im,20,11,3,5,b)
		"circuit_ring": _line(im,Vector2i(1,3),Vector2i(6,3),c); _line(im,Vector2i(1,3),Vector2i(1,19),c); _line(im,Vector2i(1,19),Vector2i(21,19),l); _rect(im,19,2,3,6,b)
		"battery": _rect(im,1,9,5,12,c); _rect(im,2,7,3,2,l); _line(im,Vector2i(19,2),Vector2i(22,7),l,2); _line(im,Vector2i(22,7),Vector2i(19,12),b,2)
		"poison_cloud":
			_ellipse(im,Vector2i(4,18),3,3,c); _ellipse(im,Vector2i(18,20),3,2,b); _ellipse(im,Vector2i(21,6),2,3,l)
		"metronome": _line(im,Vector2i(1,7),Vector2i(5,3),l,2); _line(im,Vector2i(5,3),Vector2i(1,1),c,2); _line(im,Vector2i(4,14),Vector2i(8,10),c,2); _line(im,Vector2i(8,10),Vector2i(4,7),l,2)
		"ward_runes": _rect(im,1,4,4,2,c); _rect(im,2,2,2,6,l); _poly(im,[[20,2],[22,5],[20,8],[18,5]],Vector2i.ZERO,c); _line(im,Vector2i(2,21),Vector2i(7,21),b,2)
		"amplify": _line(im,Vector2i(1,3),Vector2i(6,3),c,2); _line(im,Vector2i(1,3),Vector2i(1,8),l,2); _line(im,Vector2i(17,22),Vector2i(22,22),c,2); _line(im,Vector2i(22,22),Vector2i(22,17),l,2); _line(im,Vector2i(2,21),Vector2i(19,4),b)
