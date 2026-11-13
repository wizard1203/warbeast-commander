extends RefCounted
## Complete isolated author peaks; do not enlarge cut mountain autotiles.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const FILE := "HAS Overworld 2.1/Universal/Universal-Trees-And-Mountains.png"
const COLUMNS := {"HUMAN":0,"FOREST":0,"MACHINE":208,"UNDEAD":416,"UNDERGROUND":416,"HIGHLAND":624}
const VERSION := "heroic-layered-mountains-m66-v1"


static func parts(terrain: Dictionary,faction: String) -> Array[Dictionary]:
	var radius := maxf(float(terrain.get("radius",40)),1.0)
	var column := int(COLUMNS.get(faction,0))
	var key := str(terrain.get("id","")).sha256_text().substr(0,12).hex_to_int()
	var result: Array[Dictionary] = []
	# An asymmetric rear crest, two overlapping intact major peaks, and lower
	# foothills make a mountain range rather than three equally tall stickers.
	# Every sample remains one isolated authored peak, never cut autotile faces.
	for index: int in range(3):
		var position := Vector2((-0.58+index*0.54)*radius,-radius*(0.20+float((key/7+index)%3)*0.08))
		result.append({"rect":Rect2i(column+16,352,16,16),"anchor":Vector2(8,15),"offset":position,"scale":radius/32.0*(0.72+float((key/11+index)%3)*0.1),"layer":"rear-ridge"})
	result.append({"rect":Rect2i(column,400,32,32),"anchor":Vector2(16,30),"offset":Vector2(-radius*0.20,-radius*0.03),"scale":radius/31.0,"layer":"high-peak"})
	result.append({"rect":Rect2i(column,400,32,32),"anchor":Vector2(16,30),"offset":Vector2(radius*(0.25+float(key%3)*0.035),radius*0.20),"scale":radius/38.0,"layer":"shoulder"})
	for index: int in range(2+key%3):
		result.append({"rect":Rect2i(column+16,352,16,16),"anchor":Vector2(8,15),"offset":Vector2((-0.56+index*0.35)*radius,radius*(0.39+float((key/17+index)%2)*0.09)),"scale":radius/45.0*(0.80+float(index%2)*0.12),"layer":"foothill"})
	# Perspective allows a peak above the collision disk, but no wider ground
	# skirt than the existing circular obstacle and no new impassable terrain.
	var extent := 1.0
	for part: Dictionary in result:
		var position: Vector2=part.offset-Vector2(part.anchor)*float(part.scale)
		var end: Vector2=position+Vector2(part.rect.size)*float(part.scale)
		extent=maxf(extent,maxf(maxf(absf(position.x),absf(end.x)),maxf(end.y,-position.y*0.5))/radius)
	for part: Dictionary in result: part.offset=Vector2(part.offset)/extent; part.scale=float(part.scale)/extent
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.offset.y<b.offset.y)
	return result


static func draw(canvas: Object,point: Vector2,terrain: Dictionary,faction: String,factor: float) -> bool:
	var drawn := false
	for part: Dictionary in parts(terrain,faction):
		drawn = Collection.draw_region(canvas,"overworld",FILE,part.rect,point+Vector2(part.offset)*factor,part.anchor,float(part.scale)*factor,Color.WHITE) or drawn
	return drawn
