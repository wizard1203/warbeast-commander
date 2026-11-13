extends RefCounted
## Four small shared material tiles; no world geometry or simulation authority.
const Art = preload("res://src/presentation/strategic_frontier_art.gd")
const SOURCE := "res://assets/art/frontier_slice/terrain-source.png"
const TILE_SIZE := 256
const TEXTURE_BYTES := 4 * TILE_SIZE * TILE_SIZE * 4
const MAX_GROUND_TILES := 256
const MAX_ROAD_TILES := 384
static var _attempted := false
static var _tiles: Array[CanvasTexture] = []
static var _failures: Array[String] = []

static func reset_cache() -> void:
	_attempted = false
	_tiles.clear()
	_failures.clear()

static func debug_stats() -> Dictionary:
	if Art.enabled(): _ensure_loaded()
	return {"textures":_tiles.size(), "texture_bytes":_tiles.size() * TILE_SIZE * TILE_SIZE * 4,
		"retained_cpu_images":0, "source":SOURCE, "failures":_failures.duplicate()}

static func _ensure_loaded() -> bool:
	if _attempted: return _tiles.size() == 4
	_attempted = true
	if not FileAccess.file_exists(SOURCE):
		_failures.append("Frontier terrain input missing; existing terrain retained.")
		return false
	var source := Image.new()
	if source.load_png_from_buffer(FileAccess.get_file_as_bytes(SOURCE)) != OK or source.is_empty() or source.get_width() != source.get_height() or source.get_width() > 2048:
		_failures.append("Frontier terrain input dimensions invalid; existing terrain retained.")
		return false
	source.convert(Image.FORMAT_RGBA8)
	var half := source.get_width() / 2
	for row: int in range(2):
		for column: int in range(2):
			var image := source.get_region(Rect2i(column * half, row * half, half, half))
			image.resize(TILE_SIZE, TILE_SIZE, Image.INTERPOLATE_LANCZOS)
			var texture := CanvasTexture.new()
			texture.diffuse_texture = ImageTexture.create_from_image(image)
			texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			texture.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			_tiles.append(texture)
	return true

static func draw_ground(canvas: Object, projected: Rect2, viewport: Rect2, scale_factor: float) -> void:
	if not Art.enabled() or not is_finite(scale_factor) or scale_factor <= 0 or not _ensure_loaded(): return
	var field := projected.intersection(viewport)
	if field.size.x < 1 or field.size.y < 1: return
	var stride := 256.0 * scale_factor
	while (ceil(field.size.x / stride) + 2) * (ceil(field.size.y / stride) + 2) > MAX_GROUND_TILES: stride *= 2
	var first := Vector2i(((field.position - projected.position) / stride).floor())
	var count := 0
	for row: int in range(ceili(field.size.y / stride) + 2):
		for column: int in range(ceili(field.size.x / stride) + 2):
			if count >= MAX_GROUND_TILES: return
			var tile := Rect2(projected.position + Vector2(first + Vector2i(column, row)) * stride, Vector2.ONE * stride)
			var clipped := tile.intersection(field)
			if clipped.size.x < 1 or clipped.size.y < 1: continue
			var region := Rect2((clipped.position - tile.position) / stride * TILE_SIZE, clipped.size / stride * TILE_SIZE)
			# A restrained material layer retains the existing faction/biome field.
			canvas.draw_texture_rect_region(_tiles[0], clipped, region, Color(1, 1, 1, 0.22))
			count += 1

static func draw_road(canvas: Object, start: Vector2, end: Vector2, width: float, material: String, scale_factor: float, budget: int) -> int:
	if not Art.enabled() or budget <= 0 or scale_factor < 0.38 or not _ensure_loaded(): return 0
	var distance := start.distance_to(end)
	if distance < 1: return 0
	var direction := (end - start) / distance
	var normal := direction.orthogonal() * maxf(width - 12 * scale_factor, 1) * 0.5
	var tiles := mini(ceili(distance / maxf(128 * scale_factor, 16)), budget)
	if tiles <= 0: return 0
	var texture := _tiles[2 if material in ["STONE", "BRICK", "SLAB"] else 1]
	for index: int in range(tiles):
		var a := start + direction * distance * index / tiles
		var b := start + direction * distance * (index + 1) / tiles
		canvas.draw_polygon(PackedVector2Array([a - normal, b - normal, b + normal, a + normal]),
			PackedColorArray([Color(1, 1, 1, 0.38)]),
			PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), texture)
	return tiles

static func draw_water(canvas: Object, polygon: PackedVector2Array, world_polygon: PackedVector2Array) -> void:
	if not Art.enabled() or polygon.size() < 3 or polygon.size() != world_polygon.size() or not _ensure_loaded(): return
	var uv := PackedVector2Array()
	for point: Vector2 in world_polygon: uv.append(point / 220.0)
	canvas.draw_polygon(polygon, PackedColorArray([Color(1, 1, 1, 0.34)]), uv, _tiles[3])
