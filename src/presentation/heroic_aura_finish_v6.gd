extends RefCounted
## Decorative source/recipient material only. Facts and real radius belong to
## AuraArt and the published readout, never to this painter.
const SIZE := Vector2i(64,36)
const PHASES := 4
const PHASE_TICKS := 6
const MAX_TEXTURES := 318 # 53 existing glyphs * six materials, one legal origin.
const INK := Color("17141f")
const FACTIONS := ["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"]
const COLORS := {
	"HUMAN":["e8b95f","fff0b5","8bd4c6"],
	"UNDEAD":["c98baf","ffe7c2","8ebaaa"],
	"MACHINE":["71bfc9","e4fbf0","e2ae63"],
	"FOREST":["8fbf75","edf5ad","79c6bd"],
	"HIGHLAND":["ed9a53","ffe7a1","b3c6d8"],
	"UNDERGROUND":["b895dc","f1e2fc","8ad0cc"],
}
static var _textures: Dictionary = {}
static var _bakes := 0

static func material(faction: String) -> String:
	return faction if faction in FACTIONS else "HUMAN"

static func origin_group(origin: String) -> String:
	if origin=="ITEM": return "ITEM"
	if origin=="INNATE": return "INNATE"
	return "SKILL"

static func phase(tick: int) -> int:
	return posmod(int(maxi(tick,0)/PHASE_TICKS),PHASES)

static func tint(faction: String, index: int, alpha: float=1.0) -> Color:
	return Color(Color(str(COLORS[material(faction)][clampi(index,0,2)])),alpha)

static func texture(id: String, signature: String, faction: String, origin: String) -> Texture2D:
	var family := material(faction)
	var group := origin_group(origin)
	var legal_group := "INNATE" if id.begins_with("INNATE_") else "ITEM" if id in ["WAR_STANDARD","AEGIS_STANDARD","SPRING_STANDARD","MANA_STANDARD"] else "SKILL"
	if group!=legal_group: return null
	var key := id+":"+family+":"+group
	if _textures.has(key): return _textures[key]
	# No eviction: CanvasItem can retain commands after the producer returns.
	# Refuse extra cosmetic bakes rather than dropping a still-referenced RID.
	if _textures.size()>=MAX_TEXTURES or not _valid_signature(signature): return null
	var image := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	var base := tint(family,0,0.62)
	var bright := tint(family,1,0.88)
	var second := tint(family,2,0.72)
	_outline(image,family,base,bright,second)
	_origin_accents(image,group,base,bright,second)
	_glyph(image,signature,base,bright,second)
	var result := ImageTexture.create_from_image(image)
	_textures[key]=result
	_bakes+=1
	return result

static func debug_stats() -> Dictionary:
	return {"texture_count":_textures.size(),"texture_limit":MAX_TEXTURES,"pixel_bytes":_textures.size()*SIZE.x*SIZE.y*4,"maximum_pixel_bytes":MAX_TEXTURES*SIZE.x*SIZE.y*4,"bakes":_bakes,"phase_count":PHASES,"per_frame_bakes":false,"eviction":false}

static func draw_seal(canvas: Object, center: Vector2, id: String, signature: String, faction: String, origin: String, factor: float) -> void:
	var sheet := texture(id,signature,faction,origin)
	if sheet==null: return
	var group := origin_group(origin)
	var spread := maxf(factor,0.65)
	var offset := Vector2(0,12) if group=="INNATE" else Vector2(-17,17) if group=="SKILL" else Vector2(17,19)
	# Flattened, always behind the body; not a new selection or range ellipse.
	var extent := Vector2(SIZE)*spread*(0.90 if group=="INNATE" else 0.66)
	var at := center+offset*spread
	if not extent.is_finite() or not at.is_finite(): return
	canvas.draw_texture_rect(sheet,Rect2((at-extent*0.5).round(),extent.round()),false,Color.WHITE)

static func draw_source_wisps(canvas: Object, center: Vector2, faction: String, origin: String, factor: float, tick: int) -> void:
	var group := origin_group(origin)
	var moment := phase(tick)
	var spread := maxf(factor,0.65)
	var offset := Vector2(0,12) if group=="INNATE" else Vector2(-17,17) if group=="SKILL" else Vector2(17,19)
	var at := center+offset*spread
	# Six two-stroke motes maximum per origin; body centre stays clear. The
	# four deterministic phases are pure draw commands, not texture keys.
	for index: int in range(6):
		var side := -1.0 if index%2==0 else 1.0
		var lift := float((moment+index)%PHASES)
		var reach := 17.0+float(index/2)*3.0
		var point := at+Vector2(side*(reach-lift),4.0-lift*2.0)*spread
		var end := point+Vector2(side*(1.0 if group=="ITEM" else -1.0),-3.0)*spread
		if material(faction)=="MACHINE": end=point+Vector2(side*3.0,0)*spread
		elif material(faction)=="HIGHLAND": end=point+Vector2(-side*2.0,-4.0)*spread
		elif material(faction)=="UNDERGROUND": end=point+Vector2(side*2.0,-2.0)*spread
		canvas.draw_line(point.round(),end.round(),Color(INK,0.42),maxf(2.0,roundf(spread*2.0)),false)
		canvas.draw_line(point.round(),end.round(),tint(faction,1 if index%3==moment%3 else 2,0.60),maxf(1.0,roundf(spread)),false)

static func draw_recipient_wisps(canvas: Object, center: Vector2, mark: Dictionary, factor: float, tick: int) -> void:
	var family := str(mark.get("faction","HUMAN"))
	var moment := phase(tick)
	var spread := maxf(factor,0.65)
	# This is called only after the factual recipient glyph is accepted. A
	# pair of low foot sparks is intentionally much smaller than a source.
	for edge: int in [-1,1]:
		var point := center+Vector2(float(edge)*(7.0-float(moment%2)),5.0-float(moment))*spread
		var end := point+Vector2(float(edge),-2.0)*spread
		canvas.draw_line(point.round(),end.round(),tint(family,2,0.64),maxf(1.0,roundf(spread)),false)

static func _valid_signature(signature: String) -> bool:
	var rows := signature.split("/")
	if rows.size()!=7: return false
	for row: String in rows:
		if row.length()!=7: return false
		for cell: String in row:
			if cell!="#" and cell!=".": return false
	return true

static func _pixel(image: Image, point: Vector2i, color: Color) -> void:
	if point.x<2 or point.x>=SIZE.x-2 or point.y<2 or point.y>=SIZE.y-2: return
	image.set_pixel(point.x,point.y,color)

static func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for row: int in range(y,y+height):
		for column: int in range(x,x+width): _pixel(image,Vector2i(column,row),color)

static func _stroke(image: Image, from: Vector2i, to: Vector2i, color: Color, width: int=1) -> void:
	var distance := maxi(absi(to.x-from.x),absi(to.y-from.y))
	for step: int in range(distance+1):
		var weight := float(step)/float(maxi(distance,1))
		var point := Vector2(from).lerp(Vector2(to),weight).round()
		_rect(image,int(point.x),int(point.y),width,width,color)

static func _edged(image: Image, points: Array, base: Color, bright: Color) -> void:
	for index: int in range(points.size()-1):
		_stroke(image,points[index],points[index+1],Color(INK,0.65),3)
		_stroke(image,Vector2i(points[index])+Vector2i(1,0),Vector2i(points[index+1])+Vector2i(1,0),base,1)
		if index%2==0: _stroke(image,points[index],Vector2i(Vector2(points[index]).lerp(Vector2(points[index+1]),0.42).round()),bright,1)

static func _outline(image: Image, family: String, base: Color, bright: Color, second: Color) -> void:
	match family:
		"HUMAN":
			# Folded oath-map, paired scroll corners and torn ribbon feet.
			_edged(image,[Vector2i(9,11),Vector2i(24,6),Vector2i(39,6),Vector2i(54,11),Vector2i(54,22),Vector2i(39,29),Vector2i(24,29),Vector2i(9,22),Vector2i(9,11)],base,bright)
			_rect(image,5,15,4,7,Color(INK,0.68));_rect(image,6,15,2,5,second)
			_rect(image,56,15,3,7,Color(INK,0.68));_rect(image,56,15,1,5,second)
		"UNDEAD":
			# Two broken bone crescents, not a continuous generic halo.
			_edged(image,[Vector2i(24,5),Vector2i(14,8),Vector2i(6,16),Vector2i(10,23),Vector2i(22,29)],base,bright)
			_edged(image,[Vector2i(40,5),Vector2i(50,8),Vector2i(58,16),Vector2i(54,23),Vector2i(42,29)],base,bright)
			_stroke(image,Vector2i(17,12),Vector2i(11,15),second,2);_stroke(image,Vector2i(48,24),Vector2i(52,20),second,2)
		"MACHINE":
			# Open circuit rails and three-tooth brackets.
			_edged(image,[Vector2i(23,6),Vector2i(10,6),Vector2i(10,13),Vector2i(5,13),Vector2i(5,23),Vector2i(20,23),Vector2i(20,29)],base,bright)
			_edged(image,[Vector2i(41,6),Vector2i(54,6),Vector2i(54,13),Vector2i(59,13),Vector2i(59,23),Vector2i(44,23),Vector2i(44,29)],base,bright)
			for x: int in [19,29,39]: _rect(image,x,28,3,2,second)
		"FOREST":
			# Four unequal willow leaves and interlaced root ends.
			_edged(image,[Vector2i(24,6),Vector2i(13,7),Vector2i(6,15),Vector2i(18,15),Vector2i(24,6)],base,bright)
			_edged(image,[Vector2i(39,8),Vector2i(51,5),Vector2i(58,14),Vector2i(46,17),Vector2i(39,8)],base,bright)
			_edged(image,[Vector2i(12,22),Vector2i(19,28),Vector2i(33,30),Vector2i(48,25),Vector2i(55,19)],base,bright)
			_stroke(image,Vector2i(22,25),Vector2i(16,28),second,1);_stroke(image,Vector2i(40,26),Vector2i(48,30),second,1)
		"HIGHLAND":
			# Basalt chevrons with lifted flame teeth.
			_edged(image,[Vector2i(7,20),Vector2i(17,12),Vector2i(21,7),Vector2i(23,17)],base,bright)
			_edged(image,[Vector2i(57,21),Vector2i(49,11),Vector2i(44,5),Vector2i(42,17)],base,bright)
			_edged(image,[Vector2i(11,24),Vector2i(21,29),Vector2i(43,29),Vector2i(54,24)],base,bright)
			_rect(image,14,22,3,2,second);_rect(image,47,25,3,2,second)
		"UNDERGROUND":
			# Open resonance ribs and staggered crystalline facets.
			_edged(image,[Vector2i(24,6),Vector2i(13,8),Vector2i(7,17),Vector2i(16,27),Vector2i(25,29)],base,bright)
			_edged(image,[Vector2i(40,6),Vector2i(51,8),Vector2i(57,17),Vector2i(48,27),Vector2i(39,29)],base,bright)
			_stroke(image,Vector2i(16,16),Vector2i(21,22),second,2);_stroke(image,Vector2i(48,16),Vector2i(43,22),second,2)

static func _origin_accents(image: Image, group: String, base: Color, bright: Color, second: Color) -> void:
	match group:
		"INNATE":
			# Low paired roots: always-on identity, not an activation flash.
			_stroke(image,Vector2i(24,24),Vector2i(30,27),base,2)
			_stroke(image,Vector2i(39,24),Vector2i(33,27),base,2)
			_rect(image,30,28,4,2,bright)
		"SKILL":
			# Learned field: three compact risers, crown open at its centre.
			for x: int in [25,31,37]:
				_rect(image,x,3,2,4,Color(INK,0.70));_rect(image,x,3,1,2,second)
		"ITEM":
			# Equipment standard: two hanging hems around a metal clasp.
			_rect(image,19,25,5,6,Color(INK,0.70));_rect(image,20,25,2,4,second)
			_rect(image,41,25,5,6,Color(INK,0.70));_rect(image,42,25,2,4,second)
			_rect(image,29,29,6,2,bright)

static func _glyph(image: Image, signature: String, base: Color, bright: Color, second: Color) -> void:
	var rows := signature.split("/")
	# Preserve the complete old seven-cell glyph, widened on the ground plane.
	for y: int in range(7):
		for x: int in range(7):
			if rows[y][x]!="#": continue
			_rect(image,24+x*2,10+y,4,3,Color(INK,0.78))
	for y: int in range(7):
		for x: int in range(7):
			if rows[y][x]!="#": continue
			_rect(image,25+x*2,11+y,2,1,bright if (x+y)%3!=0 else second)
	_stroke(image,Vector2i(23,20),Vector2i(40,20),Color(base,0.32),1)
