extends RefCounted
## Original fitted livery. Gray masks preserve author bodies and source alpha;
## player side is modulation at draw time, never a colored atlas cache key.
const Palette = preload("res://src/presentation/strategic_side_palette.gd")
const MAX_MASKS := 256
const MAX_MASK_BYTES := 2*1024*1024
const PROVENANCE := "original-fitted-team-material-m70"
const BUILDING_ZONES := {
	"BASE":[Rect2(0.16,0.34,0.16,0.25),Rect2(0.67,0.34,0.15,0.25),Rect2(0.39,0.58,0.19,0.09)],
	"BARRACKS":[Rect2(0.19,0.34,0.13,0.26),Rect2(0.46,0.23,0.16,0.10),Rect2(0.57,0.56,0.17,0.12)],
	"RANGE":[Rect2(0.13,0.21,0.12,0.28),Rect2(0.31,0.65,0.42,0.10)],
	"ALTAR":[Rect2(0.22,0.30,0.11,0.28),Rect2(0.67,0.29,0.12,0.29),Rect2(0.40,0.16,0.17,0.15)],
	"FOUNDRY":[Rect2(0.15,0.54,0.16,0.20),Rect2(0.53,0.25,0.14,0.12),Rect2(0.70,0.64,0.14,0.12)],
	"WORKSHOP":[Rect2(0.24,0.20,0.35,0.09),Rect2(0.46,0.57,0.20,0.14),Rect2(0.16,0.51,0.10,0.23)],
	"TOWER":[Rect2(0.36,0.35,0.28,0.19),Rect2(0.22,0.66,0.45,0.09)],
	"DRAGON_ROOST":[Rect2(0.19,0.28,0.16,0.21),Rect2(0.52,0.64,0.26,0.13)],
	"ESSENCE_MINE":[Rect2(0.38,0.29,0.16,0.20),Rect2(0.62,0.68,0.19,0.12),Rect2(0.19,0.63,0.13,0.15)],
	"SHOP":[Rect2(0.25,0.34,0.36,0.14),Rect2(0.44,0.66,0.23,0.14)]}
static var _masks: Dictionary = {}
static var _order: Array[String] = []
static var _bytes := 0
static var _bakes := 0

static func reset_cache() -> void:
	_masks.clear();_order.clear();_bytes=0;_bakes=0

static func _interior(image: Image,point: Vector2i) -> bool:
	var size := image.get_size()
	if point.x<1 or point.y<1 or point.x>=size.x-1 or point.y>=size.y-1:return false
	var color := image.get_pixelv(point)
	if color.a<0.5 or maxf(color.r,maxf(color.g,color.b))<0.23:return false
	# The original dark contour, holes, weapon borders and sky gaps stay intact.
	for direction: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if image.get_pixelv(point+direction).a<0.5:return false
	return true

static func _shade(color: Color,highlight: bool=false) -> Color:
	var luminance := color.r*0.27+color.g*0.57+color.b*0.16
	var value := clampf(0.40+luminance*0.70+(0.09 if highlight else 0.0),0.48,1.0)
	return Color(value,value,value,1)

static func building_mask(image: Image,kind: String,faction: String) -> Image:
	var mask := Image.create(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	var used := image.get_used_rect()
	if not used.has_area():return mask
	var zones: Array = BUILDING_ZONES.get("TOWER" if kind=="SITE_TOWER" else kind,BUILDING_ZONES.BASE)
	for y: int in range(used.position.y,used.end.y):
		for x: int in range(used.position.x,used.end.x):
			var point := Vector2i(x,y)
			if not _interior(image,point):continue
			var uv := (Vector2(point)-Vector2(used.position))/Vector2(used.size)
			var selected := false
			for rect: Rect2 in zones:
				if rect.has_point(uv):
					# Taper each inset into a stepped cloth/painted chevron,
					# not a floating rectangular color swatch on the roof.
					var t := (uv.y-rect.position.y)/rect.size.y
					var inset := rect.size.x*(0.12+maxf(0,t-0.70)*0.8)
					selected=uv.x>=rect.position.x+inset and uv.x<=rect.end.x-inset
					if selected:break
			var original := image.get_pixelv(point)
			# Real existing heraldic cloth is included, not the whole material.
			if faction=="HUMAN" and kind!="BASE":
				selected=original.h>0.52 and original.h<0.70 and original.s>0.45 and original.v>0.35
				# Fitted roof-slope identification ribbons, not square swatches.
				var warm_roof := original.h<0.11 and original.s>0.36 and original.v>0.30
				if warm_roof:
					match kind:
						"BARRACKS":selected=selected or (uv.y>0.09 and uv.y<0.40 and absf(uv.x-(0.46+(uv.y-0.09)*0.65))<0.075)
						"FOUNDRY":selected=selected or (uv.y>0.27 and uv.y<0.55 and absf(uv.x-(0.25+(uv.y-0.27)*0.65))<0.075)
						"WORKSHOP":selected=selected or (uv.y>0.11 and uv.y<0.42 and absf(uv.x-(0.65+(uv.y-0.11)*0.55))<0.075)
						"RANGE":selected=selected or (uv.y>0.66 and uv.y<0.78 and uv.x>0.28 and uv.x<0.76 and absf(uv.x-0.52)<0.24-maxf(0,uv.y-0.74)*0.9)
						"ESSENCE_MINE":selected=selected or (uv.y>0.55 and uv.y<0.66 and uv.x>0.19 and uv.x<0.55)
						"SHOP":selected=selected or (uv.y>0.66 and uv.y<0.78 and uv.x>0.28 and uv.x<0.70)
			elif faction=="UNDEAD" and kind!="BASE":selected=original.h>0.72 and original.h<0.95 and original.s>0.14 and original.v>0.19
			elif faction=="MACHINE" and kind!="BASE":selected=original.h>0.105 and original.h<0.18 and original.s>0.45 and original.v>0.36
			elif faction=="FOREST" and kind not in ["BASE","TOWER","ESSENCE_MINE"]:selected=(original.h>0.89 or original.h<0.045) and original.s>0.13 and original.s<0.58 and original.v>0.55
			if not selected:continue
			# Tiny alternating thread rows retain pixel-plane shading without
			# turning livery into a flat, floating rectangle.
			mask.set_pixelv(point,_shade(original,posmod(y,5)==0))
	# Some faction/role drawings have no suitably colored existing cloth.
	# Give these a small fitted painted inset rather than silently returning
	# a transparent mask and relying on the outside ownership pennant.
	var minimum := maxi(12,roundi(float(_opaque_count(image))*0.025))
	if _opaque_count(mask)<minimum:
		for y: int in range(used.position.y,used.end.y):
			for x: int in range(used.position.x,used.end.x):
				var point := Vector2i(x,y)
				if not _interior(image,point):continue
				var uv := (Vector2(point)-Vector2(used.position))/Vector2(used.size)
				for rect: Rect2 in zones:
					if not rect.has_point(uv):continue
					var t := (uv.y-rect.position.y)/rect.size.y
					var inset := rect.size.x*(0.12+maxf(0,t-0.70)*0.8)
					if uv.x>=rect.position.x+inset and uv.x<=rect.end.x-inset:mask.set_pixelv(point,_shade(image.get_pixelv(point),posmod(y,5)==0));break
	return mask

static func _store(key: String,image: Image) -> Dictionary:
	if _masks.has(key):_order.erase(key);_order.append(key);return _masks[key]
	var amount := image.get_width()*image.get_height()*4
	while not _order.is_empty() and (_order.size()>=MAX_MASKS or _bytes+amount>MAX_MASK_BYTES):
		var old: String = _order.pop_front();_bytes-=int(_masks[old].bytes);_masks.erase(old)
	if amount>MAX_MASK_BYTES:return {}
	var entry := {"image":image,"texture":ImageTexture.create_from_image(image),"bytes":amount,"pixels":_opaque_count(image)}
	_masks[key]=entry;_order.append(key);_bytes+=amount;_bakes+=1
	return entry

static func _opaque_count(image: Image) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x,y).a>0.5:count+=1
	return count

static func _retain_draw_texture_m81(canvas: Object, texture: Texture2D) -> void:
	# Canvas draw commands retain an RID, not this Texture2D owner. A later
	# actor can evict the mask while this canvas still uses its old command.
	if not canvas is CanvasItem:return
	var generation:=Engine.get_process_frames()
	var retained:Dictionary=canvas.get_meta("m81_team_texture_refs",{})
	if int(retained.get("frame",-1))!=generation:
		# Called only while recording a new draw: previous commands of THIS
		# canvas were replaced. Never release on frame_post_draw: a paused
		# canvas may keep its commands for many frames. Repaints in one process
		# frame conservatively retain their union until the next repaint.
		retained={"frame":generation,"textures":{}}
		canvas.set_meta("m81_team_texture_refs",retained)
	retained.textures[texture.get_instance_id()]=texture

static func draw_building(canvas: Object,point: Vector2,building: Dictionary,entry: Dictionary,image: Image,modulation: Color) -> bool:
	if not bool(entry.get("alive",false)) or image==null:return false
	var key := "base:"+str(entry.get("pixel_hash",""))+":"+str(building.get("faction_id","HUMAN"))
	var cached: Dictionary = _masks.get(key,{})
	if cached.is_empty():cached=_store(key,building_mask(image,str(building.get("building_type","BASE")),str(building.get("faction_id","HUMAN"))))
	if cached.is_empty() or int(cached.pixels)==0:return false
	var scale := float(entry.scale)
	_retain_draw_texture_m81(canvas,cached.texture)
	canvas.draw_texture_rect_region(cached.texture,Rect2((point-Vector2(entry.anchor)*scale).round(),Vector2(image.get_size())*scale),Rect2(Vector2.ZERO,Vector2(image.get_size())),Palette.side_color(str(building.get("side","")))*modulation)
	return true

static func actor_mask(image: Image,rect: Rect2,logical_size: int,unit: Dictionary,mirror: bool=false) -> Image:
	var mask := Image.create(image.get_width(),image.get_height(),false,Image.FORMAT_RGBA8)
	mask.fill(Color.TRANSPARENT)
	# Source-foot coordinates, not attack-dependent used-rectangle fractions.
	# The new tabard/armour inlay is an original fitted surface, not a claim
	# that an automatic classifier has discovered the author's cloth pixels.
	var ratio := float(logical_size)/32.0
	var main := Rect2(Vector2(-4.8,-14)*ratio,Vector2(8.4,7.5)*ratio)
	var strap := Rect2(Vector2(-5.8,-11)*ratio,Vector2(10.4,2.0)*ratio)
	var shoulder := Rect2(Vector2(-7.5,-12)*ratio,Vector2(3.7,7)*ratio)
	var body := str(unit.get("body_kind",""))
	if body=="DRAGON" or str(unit.get("unit_type",""))=="fire_dragon":main=Rect2(Vector2(-5,-11)*ratio,Vector2(8,5)*ratio)
	if str(unit.get("unit_type",""))=="chitin_guard":
		# The licensed low spider has no upright chest. Its fitted colored
		# carapace band sits near the substrate, between legs and face.
		main=Rect2(Vector2(-9,-20)*ratio,Vector2(18,15)*ratio)
		strap=Rect2(Vector2(-9,-17)*ratio,Vector2(18,3)*ratio)
		shoulder=Rect2()
	if str(unit.get("hero_archetype",""))=="VINE_WARDEN":
		# Its bend/whip frames split the trunk around the fixed foot axis.
		# Two thin fitted branch bindings remain on opaque wood rather than
		# painting a humanoid chest rectangle into the empty central gap.
		main=Rect2(Vector2(-13,-19)*ratio,Vector2(26,4.5)*ratio)
		strap=Rect2(Vector2(-13,-12)*ratio,Vector2(26,3.5)*ratio)
		shoulder=Rect2()
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var point := Vector2i(x,y)
			if not _interior(image,point):continue
			var local := Vector2(point)+rect.position+Vector2(0.5,0.5)
			if mirror:local.x=-local.x
			if not main.has_point(local) and not strap.has_point(local) and not shoulder.has_point(local):continue
			# Break the central plate at a seam; keep a material buckle and
			# most of the original torso visible, rather than one large dye.
			if absf(local.x)<ratio*0.55 and local.y>-10*ratio:continue
			mask.set_pixelv(point,_shade(image.get_pixelv(point),posmod(y,4)==0))
	return mask

static func draw_actor(canvas: Object,foot: Vector2,unit: Dictionary,pose: Dictionary,frame: Dictionary,factor: float,logical_size: int) -> bool:
	if str(pose.get("action","IDLE"))=="FALLEN" or int(unit.get("hp",1))<=0 or not bool(unit.get("alive",true)):return false
	if not frame.get("image") is Image or factor<=0 or not foot.is_finite():return false
	var key := "actor:"+str(frame.key)+":"+str(logical_size)+("-shell" if unit.get("unit_type")=="chitin_guard" else "-body")
	var cached: Dictionary = _masks.get(key,{})
	if cached.is_empty():cached=_store(key,actor_mask(frame.image,Rect2(frame.rect),logical_size,unit,bool(frame.get("mirror",false))))
	if cached.is_empty() or int(cached.pixels)==0:return false
	var bounds := Rect2(Vector2(frame.rect.position)*factor,Vector2(frame.rect.size)*factor)
	_retain_draw_texture_m81(canvas,cached.texture)
	canvas.draw_texture_rect(cached.texture,Rect2((foot+bounds.position).round(),bounds.size),false,Palette.side_color(str(unit.get("side",""))))
	return true

static func debug_stats() -> Dictionary:
	return {"provenance":PROVENANCE,"masks":_masks.size(),"capacity":MAX_MASKS,"rgba8_bytes":_bytes,"maximum_rgba8_bytes":MAX_MASK_BYTES,"bakes":_bakes,"owner_atlas_copies":0,"side_in_cache_key":false,"source_images_mutated":false}
