extends RefCounted
## Pure, world-anchored raster helpers. The caller owns the destination image;
## observations, palettes and licensed source Images are never changed here.
## No textures, global RNG, camera inputs or live actor objects are retained.
const VERSION := "heroic-ground-detail-m41-v1"
const TILE_PIXELS := 16
const AUTHOR_PATCH := Rect2i(160,224,48,48)
const CELL_WORLD := 24.0
const MAX_DETAIL_FRACTION := 0.12
const MAX_IMAGE_AXIS := 2048
const MAX_CANDIDATE_CELLS := 131072
const CLUSTERS := [
	[Vector2(0,0),Vector2(0,-2),Vector2(2,0)],
	[Vector2(0,0),Vector2(2,-2),Vector2(2,0),Vector2(4,0)],
	[Vector2(0,0),Vector2(0,-2),Vector2(2,-4)],
	[Vector2(0,0),Vector2(2,0),Vector2(4,0),Vector2(2,-2),Vector2(4,-2)],
]


static func regional(world: Vector2, weight: float, seed: int) -> bool:
	if weight <= 0.0: return false
	if weight >= 0.999: return true
	return weight > threshold(world, seed)


static func threshold(world: Vector2, seed: int) -> float:
	# Two broad continuous fields create connected, irregular islands. Unlike a
	# Bayer matrix this does not alternate the two biomes every native pixel.
	var broad := _noise(world / 156.0, seed ^ 0x5731)
	var local := _noise(world / 72.0, seed ^ 0x1b47)
	return 0.16 + (broad * 0.28 + local * 0.72) * 0.68


static func meadow(world: Vector2, seed: int) -> bool:
	# Broad world-space fields select connected visual cells, not a random
	# choice for each tile. The visual grid never becomes a movement grid.
	var broad := _noise(world / 192.0, seed ^ 0x7459)
	var local := _noise(world / 80.0, seed ^ 0x3ab1)
	return broad * 0.76 + local * 0.24 > 0.64


static func patch_rect(cell: Vector2i, cells: Dictionary) -> Rect2i:
	if not cells.has(cell): return Rect2i()
	# A cell's value is its source biome. A different biome cannot supply an
	# adjoining edge: each authored patch keeps its own pixel palette.
	var source: Variant = cells[cell]
	var n: bool = cells.get(cell + Vector2i.UP) == source
	var s: bool = cells.get(cell + Vector2i.DOWN) == source
	var w: bool = cells.get(cell + Vector2i.LEFT) == source
	var e: bool = cells.get(cell + Vector2i.RIGHT) == source
	var column := 0 if not w else 2 if not e else 1
	var row := 0 if not n else 2 if not s else 1
	return Rect2i(AUTHOR_PATCH.position + Vector2i(column,row) * TILE_PIXELS, Vector2i.ONE * TILE_PIXELS)


static func palette(fill: Image, clump: Image) -> Dictionary:
	if fill == null or clump == null or fill.is_empty() or clump.is_empty(): return {}
	if fill.get_width() > 64 or fill.get_height() > 64 or clump.get_width() > 64 or clump.get_height() > 64: return {}
	var counts: Dictionary = {}
	for y: int in range(fill.get_height()):
		for x: int in range(fill.get_width()):
			var color := fill.get_pixel(x, y)
			if color.a < 0.999: continue
			var key := color.to_rgba32()
			counts[key] = int(counts.get(key, 0)) + 1
	var base := Color.TRANSPARENT
	var most := 0
	for key: int in counts:
		if int(counts[key]) > most:
			most = int(counts[key])
			base = Color.hex(key)
	if most == 0: return {}
	var shadow := base
	var highlight := base
	var best_shadow := INF
	var best_highlight := INF
	for y: int in range(clump.get_height()):
		for x: int in range(clump.get_width()):
			var color := clump.get_pixel(x, y)
			if color.a < 0.999: continue
			var difference := _luminance(base) - _luminance(color)
			# Only quiet author colors close to this biome's flat fill may become
			# detail. Neither tinting nor interpolating produces new colors.
			if absf(difference) < 0.015 or absf(difference) > 0.17: continue
			var hue_distance := minf(absf(base.h - color.h), 1.0 - absf(base.h - color.h))
			var score := absf(absf(difference) - 0.035) + hue_distance * 0.3 + absf(base.s - color.s) * 0.08
			if difference > 0 and score < best_shadow:
				shadow = color
				best_shadow = score
			elif difference < 0 and score < best_highlight:
				highlight = color
				best_highlight = score
	if shadow == base and highlight == base: return {}
	if shadow == base: shadow = highlight
	if highlight == base: highlight = shadow
	return {"base":base, "shadow":shadow, "highlight":highlight}


static func paint(destination: Image, bounds: Rect2, pixel: float, water: Dictionary, seed: int, palettes: Array, zones: Array = []) -> Dictionary:
	var report := {"version":VERSION, "detail_pixels":0, "detail_fraction":0.0, "max_detail_fraction":MAX_DETAIL_FRACTION, "candidate_cells":0, "max_candidate_cells":MAX_CANDIDATE_CELLS, "palette_count":palettes.size()}
	if destination == null or not is_finite(pixel) or pixel <= 0 or bounds.size.x <= 0 or bounds.size.y <= 0: return report
	if destination.get_width() > MAX_IMAGE_AXIS or destination.get_height() > MAX_IMAGE_AXIS: return report
	var colors: Dictionary = {}
	for entry: Dictionary in palettes:
		if entry.has("base") and entry.has("shadow") and entry.has("highlight"):
			colors[(entry.base as Color).to_rgba32()] = entry
	if colors.is_empty(): return report
	var size := destination.get_size()
	var budget := floori(float(size.x * size.y) * MAX_DETAIL_FRACTION)
	if budget == 0: return report
	var start := Vector2i((bounds.position / CELL_WORLD).floor())
	var end := Vector2i((bounds.end / CELL_WORLD).ceil())
	if (end.x - start.x + 1) * (end.y - start.y + 1) > MAX_CANDIDATE_CELLS:
		report["skipped_reason"] = "world-detail-grid-exceeds-budget"
		return report
	for cy: int in range(start.y, end.y + 1):
		for cx: int in range(start.x, end.x + 1):
			report.candidate_cells += 1
			var cell := Vector2i(cx, cy)
			var key := _hash(cell, seed ^ 0x2d93)
			var center := Vector2(cell) * CELL_WORLD + Vector2.ONE * CELL_WORLD * 0.5
			var field := _noise(center / 124.0, seed ^ 0x6947)
			if field < 0.43 or key % 100 >= 68: continue
			var origin := Vector2(cell) * CELL_WORLD + Vector2(4 + (key % 7) * 2, 6 + ((key / 7) % 7) * 2)
			# Short linked blades/grains, not a complete circular sticker or a
			# repeated square tile. Coordinates stay anchored in world space.
			var offsets: Array = CLUSTERS[(key / 47) % CLUSTERS.size()]
			for index: int in range(offsets.size()):
				var point := Vector2i(((origin + offsets[index] - bounds.position) / pixel).floor())
				if not Rect2i(Vector2i.ZERO, size).has_point(point) or water.has(Vector2i(point.x / 16, point.y / 16)): continue
				var world := bounds.position + (Vector2(point) + Vector2.ONE * 0.5) * pixel
				# Keep the two-source transition especially quiet and legible. Its
				# irregular contour supplies detail without extra grass flecks.
				if _transitioning(world, zones): continue
				var previous := destination.get_pixelv(point)
				var color_key := previous.to_rgba32()
				# Existing authored clumps and objects are not repainted; details
				# only replace flat-fill pixels, never arbitrary source artwork.
				if not colors.has(color_key): continue
				var entry: Dictionary = colors[color_key]
				destination.set_pixelv(point, entry.highlight if index == 2 and key % 4 == 0 else entry.shadow)
				report.detail_pixels += 1
				if int(report.detail_pixels) >= budget:
					report.detail_fraction = float(report.detail_pixels) / maxi(size.x * size.y, 1)
					return report
	report.detail_fraction = float(report.detail_pixels) / maxi(size.x * size.y, 1)
	return report


static func _noise(point: Vector2, seed: int) -> float:
	var cell := Vector2i(point.floor())
	var offset := point - Vector2(cell)
	offset = offset * offset * (Vector2.ONE * 3.0 - offset * 2.0)
	var a := float(_hash(cell, seed)) / 2147483647.0
	var b := float(_hash(cell + Vector2i.RIGHT, seed)) / 2147483647.0
	var c := float(_hash(cell + Vector2i.DOWN, seed)) / 2147483647.0
	var d := float(_hash(cell + Vector2i.ONE, seed)) / 2147483647.0
	return lerpf(lerpf(a, b, offset.x), lerpf(c, d, offset.x), offset.y)


static func _hash(cell: Vector2i, seed: int) -> int:
	var value := posmod(cell.x * 92837111 + cell.y * 689287499 + posmod(seed, 104729) * 283923481, 2147483647)
	value = ((value ^ (value >> 13)) * 1274126177) & 0x7fffffff
	return value ^ (value >> 16)


static func _luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722


static func _transitioning(world: Vector2, zones: Array) -> bool:
	for zone: Dictionary in zones:
		var radius := maxf(float(zone.get("radius", 500)), 1.0)
		var distance := world.distance_to(Vector2(zone.get("position", Vector2.ZERO))) / radius
		if distance > 0.65 and distance < 1.15: return true
	return false
