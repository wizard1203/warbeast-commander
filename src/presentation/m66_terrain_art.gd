extends RefCounted
## Bounded compositions of complete licensed isolated trees. These are visual
## bodies only: no physics, randomness, selection targets or gameplay state.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const FILE := "HAS Overworld 2.1/Universal/Universal-Trees-And-Mountains.png"
const VERSION := "heroic-terrain-groves-m66-v2"
const TREE_BLOCKS := {
	"HUMAN":Vector2i(0,0), "FOREST":Vector2i(0,288),
	"UNDEAD":Vector2i(208,0), "MACHINE":Vector2i(208,288),
	"HIGHLAND":Vector2i(208,48), "UNDERGROUND":Vector2i(0,432),
	"CONIFER":Vector2i(0,48),
}
const GROVE_FORMS := [
	[Vector2(-0.34,-0.19),Vector2(0.32,-0.16),Vector2(-0.04,0.18)],
	[Vector2(-0.35,-0.24),Vector2(0.27,-0.29),Vector2(0.31,0.16),Vector2(-0.24,0.21)],
	[Vector2(-0.40,-0.15),Vector2(0.02,-0.32),Vector2(0.40,-0.05),Vector2(-0.12,0.20)],
	[Vector2(-0.34,-0.29),Vector2(0.35,-0.20),Vector2(-0.03,0.02),Vector2(-0.34,0.26),Vector2(0.32,0.28)],
]
static var _source_sha256 := ""

static func inspect_thicket(entry: Dictionary) -> Dictionary:
	if _source_sha256.is_empty(): _source_sha256=FileAccess.get_sha256(Collection.ROOT+"overworld/"+FILE)
	var parts := thicket_parts(entry)
	return {"runtime_pipeline":VERSION,"runtime_source_file":FILE,"runtime_source_sha256":_source_sha256,"runtime_parts":parts,"runtime_world_bounds":thicket_bounds(entry),"runtime_composition_sha256":var_to_str([_source_sha256,parts,float(entry.get("scale",1.4))]).sha256_text(),"runtime_provenance":"licensed-overworld-complete-isolated-tree-composition"}

static func tree_parts(terrain: Dictionary,faction: String) -> Array[Dictionary]:
	var raw_radius := float(terrain.get("radius",48))
	if not is_finite(raw_radius) or raw_radius<=0: return []
	var radius := clampf(raw_radius,12.0,160.0)
	var key := _hash(str(terrain.get("id","tree")))
	return _parts(faction,key,radius,1.0)

static func thicket_parts(entry: Dictionary) -> Array[Dictionary]:
	var faction := _grove_faction(entry)
	var key := _hash(str(entry.get("id",""))+":"+str(entry.get("variant",0))+":"+str(entry.get("map_id","borderlands")))
	var scale := float(entry.get("scale",1.4))
	var footprint := float(entry.get("footprint",56))
	if not is_finite(scale) or scale<=0 or not is_finite(footprint) or footprint<=0: return []
	var radius := minf(footprint/scale,512.0)
	return _parts(faction,key,radius,0.86)

static func _grove_faction(entry: Dictionary) -> String:
	var faction := str(entry.get("faction_id",""))
	if not faction.is_empty(): return faction
	match str(entry.get("map_id","borderlands")):
		"highland-caldera": return "CONIFER"
		"river-crossroads": return "FOREST"
		_: return "HUMAN"

static func _parts(faction: String,key: int,radius: float,density: float) -> Array[Dictionary]:
	var form: Array=GROVE_FORMS[key%GROVE_FORMS.size()]
	var result: Array[Dictionary]=[]
	for index: int in range(form.size()):
		# The 32px x=32/64/128 rectangles used by the historical consumer are
		# autotile fragments, not intact tree groups. Never reuse those cuts.
		var source := isolated_source(faction,int(key/7+index))
		var offset: Vector2=Vector2(form[index])*radius
		var body_scale := maxf(0.2,radius/float(source.size.y))*(0.91+float((key/13+index)%3)*0.07)*density
		result.append({"rect":source,"anchor":Vector2(source.size.x*0.5,source.size.y-1),"offset":offset,"scale":body_scale,"species":faction,"layer":"canopy","provenance":"licensed-overworld-complete-isolated-tree"})
	# Fit the full source rectangles, not only alpha, into the conservative
	# radial footprint. This makes draw/occlusion/placement share one envelope.
	var bounds := _part_bounds(result[0])
	for part: Dictionary in result:
		bounds=bounds.merge(_part_bounds(part))
	var length := 1.0
	for corner: Vector2 in [bounds.position,bounds.end,Vector2(bounds.end.x,bounds.position.y),Vector2(bounds.position.x,bounds.end.y)]: length=maxf(length,corner.length())
	var fit := minf(1.0,radius/length)
	for part: Dictionary in result: part.offset=Vector2(part.offset)*fit; part.scale=float(part.scale)*fit
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		return a.offset.x<b.offset.x if is_equal_approx(a.offset.y,b.offset.y) else a.offset.y<b.offset.y)
	return result

static func isolated_source(faction: String,variant: int) -> Rect2i:
	match faction:
		"FOREST": return Rect2i(160,288,48,48) if variant%4!=0 else Rect2i(16,0,16,16)
		"MACHINE": return Rect2i(208,288,32,48) if variant%4!=0 else Rect2i(224,0,16,16)
		"HIGHLAND": return Rect2i(224,48,16,16) if variant%3!=0 else Rect2i(640,0,16,16)
		"UNDEAD": return Rect2i(224,0,16,16)
		"UNDERGROUND": return Rect2i(16,432,16,16)
		"CONIFER": return Rect2i(16,48,16,16)
		_: return Rect2i(16,48,16,16) if variant%7==0 else Rect2i(16,0,16,16)

static func thicket_bounds(entry: Dictionary) -> Rect2:
	var scale := float(entry.get("scale",1.4))
	if not is_finite(scale) or scale<=0: return Rect2()
	var first := true
	var bounds := Rect2()
	for part: Dictionary in thicket_parts(entry):
		var body := _part_bounds(part)
		body=Rect2(body.position*scale,body.size*scale)
		bounds=body if first else bounds.merge(body)
		first=false
	return bounds

static func _part_bounds(part: Dictionary) -> Rect2:
	return Rect2(Vector2(part.offset)-Vector2(part.anchor)*float(part.scale),Vector2(part.rect.size)*float(part.scale))

static func draw_tree(canvas: Object,point: Vector2,terrain: Dictionary,faction: String,factor: float) -> bool:
	if not point.is_finite() or not is_finite(factor) or factor<=0: return false
	return _draw(canvas,point,tree_parts(terrain,faction),factor,1.0)

static func draw_thicket(canvas: Object,point: Vector2,entry: Dictionary,factor: float,opacity: float=1.0) -> bool:
	if not point.is_finite() or not is_finite(factor) or factor<=0 or not is_finite(opacity) or opacity<=0: return false
	var scale := float(entry.get("scale",1.4))
	if not is_finite(scale) or scale<=0: return false
	return _draw(canvas,point,thicket_parts(entry),factor*scale,clampf(opacity,0,1))

static func _draw(canvas: Object,point: Vector2,parts: Array[Dictionary],factor: float,opacity: float) -> bool:
	var drawn := false
	for part: Dictionary in parts:
		drawn=Collection.draw_region(canvas,"overworld",FILE,part.rect,point+Vector2(part.offset)*factor,part.anchor,float(part.scale)*factor,Color(1,1,1,opacity)) or drawn
	return drawn

static func _hash(value: String) -> int: return value.sha256_text().substr(0,12).hex_to_int()
