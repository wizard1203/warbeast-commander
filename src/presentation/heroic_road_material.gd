extends RefCounted
## Source-material selection only. The caller owns the unchanged road mask.
## A material never creates a path, navigation tile, collider or live object.
const Detail = preload("res://src/presentation/heroic_ground_detail.gd")
const VERSION := "heroic-road-material-m42-v2"
const SOURCES := {
	"EARTH":Rect2i(224,16,16,16),
	"STONE":Rect2i(96,96,16,16),
	"BRICK":Rect2i(224,96,16,16),
}
const HOME_MATERIALS := {"HUMAN":"STONE","UNDEAD":"STONE","HIGHLAND":"STONE","MACHINE":"BRICK","FOREST":"EARTH","UNDERGROUND":"EARTH"}
const CELL_WORLD := 32.0


static func material_at(world: Vector2, zones: Array, seed: int) -> String:
	# The coherent boundary is selected per native world cell, not per pixel.
	# Cobble remains a short settlement apron; the long links are earthy roads.
	var cell_center := (world / CELL_WORLD).floor() * CELL_WORLD + Vector2.ONE * CELL_WORLD * 0.5
	var nearest: Dictionary = {}
	var closest := INF
	for zone: Dictionary in zones:
		var radius := maxf(float(zone.get("radius",500.0)),1.0)
		var distance := cell_center.distance_to(Vector2(zone.get("position",Vector2.ZERO))) / radius
		if distance < closest:
			closest = distance
			nearest = zone
	if nearest.is_empty() or closest >= 0.76: return "EARTH"
	var material: String = HOME_MATERIALS.get(str(nearest.get("faction_id","HUMAN")),"EARTH")
	if material == "EARTH" or closest <= 0.48: return material
	# Weathered pavers end in linked native cells. Variation has a short
	# wavelength only along the boundary and a bounded one-cell displacement;
	# it cannot speckle the road interior or grow stone islands into the wild.
	var radius := maxf(float(nearest.get("radius",500.0)),1.0)
	var irregularity := (Detail.threshold(cell_center*3.0,seed ^ 0x4c37)-0.5)*CELL_WORLD*3.0
	return material if closest*radius < radius*0.62+irregularity else "EARTH"


static func darkest(source: Image) -> Color:
	if source == null or source.is_empty(): return Color.TRANSPARENT
	var result := Color.WHITE
	var value := INF
	for y: int in range(source.get_height()):
		for x: int in range(source.get_width()):
			var color := source.get_pixel(x,y)
			if color.a < 0.999: continue
			var luminance := color.r*0.2126+color.g*0.7152+color.b*0.0722
			if luminance < value:
				value = luminance
				result = color
	return result
