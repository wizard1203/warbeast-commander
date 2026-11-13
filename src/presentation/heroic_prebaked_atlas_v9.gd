extends RefCounted
## Owned, source-bound PNG atlas cache. Never paints or imports Roster.
## CanvasItem keeps its own references while submitted draw commands need them.
const DEFAULT_MANIFEST := "res://assets/art/original/hero-atlases-r8/manifest.json"
const SCHEMA := "warbeast.hero-atlases.v1"
const FRAME_SIZE := 192
const FRAMES := 12
const WIDTH := FRAME_SIZE * FRAMES
const ATLAS_BYTES := WIDTH * FRAME_SIZE * 4
const MAX_OWNED_BYTES := 128 * 1024 * 1024
const MAX_TEXTURES := 75
const MAX_PNG_BYTES := 16 * 1024 * 1024
const SOURCE_PATHS := [
	"res://src/presentation/heroic_roster_v5.gd",
	"res://src/presentation/heroic_roster_v5_human_undead.gd",
	"res://src/presentation/heroic_roster_v5_machine_highland.gd",
	"res://src/presentation/heroic_roster_v5_forest_underground.gd",
	"res://src/presentation/heroic_roster_v5_pixels.gd",
	"res://src/presentation/heroic_elemental_finish_v6.gd",
	"res://src/presentation/heroic_r7_cinder_spectacle.gd",
	"res://src/presentation/heroic_r7_myc_spectacle.gd",
	"res://src/presentation/heroic_r7_pixel_brush.gd",
	"res://src/presentation/heroic_pixel_fx_r8.gd"
]

var _budget_bytes: int
var _capacity: int
var _manifest_path := DEFAULT_MANIFEST
var _initialized := false
var _valid := false
var _entries: Dictionary = {}
var _textures: Dictionary = {}
var _order: Array[String] = []
var _failed: Dictionary = {}
var _sources: Dictionary = {}
var _stats: Dictionary = {}

func _init(budget_bytes: int = MAX_OWNED_BYTES, max_textures: int = MAX_TEXTURES) -> void:
	_budget_bytes = clampi(budget_bytes, 0, MAX_OWNED_BYTES)
	_capacity = mini(clampi(max_textures, 0, MAX_TEXTURES), floori(float(_budget_bytes) / ATLAS_BYTES))
	reset()

func reset() -> void:
	_manifest_path = DEFAULT_MANIFEST
	_initialized = false
	_valid = false
	_entries.clear()
	_textures.clear()
	_order.clear()
	_failed.clear()
	_sources.clear()
	_stats = {"configure_us": 0, "prepare_us": 0, "read_us": 0,
		"validation_us": 0, "decode_us": 0, "texture_us": 0,
		"source_checks": 0, "loads": 0, "hits": 0, "misses": 0,
		"evictions": 0, "rejects": 0, "rejections": {}, "last_error": "",
		"deferred": 0, "over_budget": 0, "requested_heroes": [], "requested_keys": [],
		"read_bytes": 0, "verified_png_bytes": 0, "verified_rgba_bytes": 0}

func current_sources() -> Dictionary:
	var out: Dictionary = {}
	for path: String in SOURCE_PATHS:
		out[path] = FileAccess.get_sha256(path) if _safe_resource(path) else ""
	return out

func configure(manifest_path: String = DEFAULT_MANIFEST) -> Dictionary:
	reset()
	_initialized = true
	_manifest_path = manifest_path
	var started := Time.get_ticks_usec()
	var failure := _configure_pack()
	_valid = failure.is_empty()
	if not _valid:
		_reject(failure)
	_stats.configure_us = Time.get_ticks_usec() - started
	var result := diagnostics()
	result.accepted = _valid
	return result

func _configure_pack() -> String:
	if not _safe_resource(_manifest_path) or _manifest_path.get_file() != "manifest.json":
		return "unsafe_manifest_path"
	if not FileAccess.file_exists(_manifest_path):
		return "missing_manifest"
	var started := Time.get_ticks_usec()
	var file := FileAccess.open(_manifest_path, FileAccess.READ)
	if file == null or file.get_length() <= 0 or file.get_length() > 8 * 1024 * 1024:
		return "manifest_size_or_read"
	var bytes := file.get_buffer(file.get_length())
	_stats.read_us += Time.get_ticks_usec() - started
	_stats.read_bytes += bytes.size()
	started = Time.get_ticks_usec()
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not parsed is Dictionary:
		return "manifest_json"
	var data: Dictionary = parsed
	if data.get("schema") != SCHEMA or not _number_is(data.get("frame_size"), FRAME_SIZE) or not _number_is(data.get("frames"), FRAMES):
		return "manifest_schema"
	var anchor: Variant = data.get("anchor")
	if not anchor is Array or anchor.size() != 2 or not _number_is(anchor[0], 96) or not _number_is(anchor[1], 136):
		return "manifest_anchor"
	var declared: Variant = data.get("sources")
	if not declared is Dictionary or declared.size() != SOURCE_PATHS.size():
		return "source_set"
	_sources = current_sources()
	_stats.source_checks += 1
	for path: String in SOURCE_PATHS:
		if not _sha(declared.get(path)) or _sources[path] == "" or declared[path] != _sources[path]:
			return "source_mismatch:" + path
	var entries: Variant = data.get("entries")
	if not entries is Dictionary or entries.is_empty() or entries.size() > 1024:
		return "entry_set"
	var keys: Array = entries.keys()
	keys.sort()
	for key: Variant in keys:
		if not key is String or not entries[key] is Dictionary:
			return "entry_shape"
		var entry: Dictionary = entries[key]
		if not _valid_entry(key, entry):
			return "invalid_entry:" + str(key)
		_entries[key] = entry.duplicate(true)
	_stats.validation_us += Time.get_ticks_usec() - started
	return ""

func prepare(hero_ids: Array[String]) -> Dictionary:
	# Every match begins a fresh owned generation and rechecks source identity.
	var path := _manifest_path
	var started := Time.get_ticks_usec()
	var configured := configure(path)
	if not configured.accepted:
		_stats.prepare_us = Time.get_ticks_usec() - started
		var failed_result := diagnostics()
		failed_result.accepted = false
		return failed_result
	var heroes: Array[String] = []
	for hero: String in hero_ids:
		if hero not in heroes:
			heroes.append(hero)
	heroes.sort()
	_stats.requested_heroes = heroes.duplicate()
	var selected: Array[String] = []
	var present: Dictionary = {}
	for key: String in _entries:
		var hero: String = _entries[key].hero
		if hero in heroes:
			selected.append(key)
			present[hero] = true
	selected.sort()
	_stats.requested_keys = selected.duplicate()
	var accepted := true
	if _capacity == 0 and not selected.is_empty():
		_reject("owned_budget_too_small")
		accepted = false
	for hero: String in heroes:
		if not present.has(hero):
			_reject("unknown_hero:" + hero)
			accepted = false
	for key: String in selected:
		if _textures.size() >= _capacity:
			_stats.deferred += 1
			_stats.over_budget += 1
			continue
		if _load_texture(key) == null:
			accepted = false
	_stats.prepare_us = Time.get_ticks_usec() - started
	var result := diagnostics()
	result.accepted = accepted
	return result

func texture(id: String, phase: String) -> Texture2D:
	if not _initialized:
		configure()
	if not _valid:
		return null
	var key := id + ":" + phase
	if _textures.has(key):
		_stats.hits += 1
		_order.erase(key)
		_order.append(key)
		return _textures[key]
	_stats.misses += 1
	if not _entries.has(key):
		_reject("unknown_clip:" + key)
		return null
	if _failed.has(key):
		return null
	return _load_texture(key)

func _load_texture(key: String) -> Texture2D:
	if _capacity <= 0:
		return _load_failure(key, "owned_budget_too_small")
	var entry: Dictionary = _entries[key]
	var path := _manifest_path.get_base_dir().path_join(str(entry.file))
	if not _safe_resource(path) or not FileAccess.file_exists(path):
		return _load_failure(key, "missing_or_unsafe_png")
	var started := Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() != int(entry.bytes):
		return _load_failure(key, "png_size")
	var encoded := file.get_buffer(file.get_length())
	_stats.read_us += Time.get_ticks_usec() - started
	_stats.read_bytes += encoded.size()
	started = Time.get_ticks_usec()
	if _hash(encoded) != entry.sha256:
		return _load_failure(key, "png_sha256")
	_stats.verified_png_bytes += encoded.size()
	# Reject obvious non-PNG/header corruption before calling Godot's decoder,
	# which otherwise emits an engine ERROR for predictable untrusted input.
	# Deeper PNG/CRC failures remain real decoder failures, not suppressed logs.
	if not _png_header(encoded):
		return _load_failure(key, "png_header")
	_stats.validation_us += Time.get_ticks_usec() - started
	started = Time.get_ticks_usec()
	var image := Image.new()
	if image.load_png_from_buffer(encoded) != OK or image.get_width() != WIDTH or image.get_height() != FRAME_SIZE or image.get_format() != Image.FORMAT_RGBA8 or image.has_mipmaps():
		return _load_failure(key, "png_decode_or_format")
	_stats.decode_us += Time.get_ticks_usec() - started
	started = Time.get_ticks_usec()
	var raw := image.get_data()
	if raw.size() != ATLAS_BYTES or _hash(raw) != entry.rgba_sha256:
		return _load_failure(key, "rgba_sha256")
	for frame: int in range(FRAMES):
		var pixels := image.get_region(Rect2i(frame * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)).get_data()
		if _hash(pixels) != entry.frame_rgba_sha256[frame]:
			return _load_failure(key, "frame_sha256:" + str(frame))
	_stats.verified_rgba_bytes += raw.size()
	_stats.validation_us += Time.get_ticks_usec() - started
	# Release only this cache's old ownership before admitting the next texture.
	# Canvas commands may legitimately retain the evicted texture independently.
	while _order.size() >= _capacity:
		_textures.erase(_order.pop_front())
		_stats.evictions += 1
	started = Time.get_ticks_usec()
	var loaded := ImageTexture.create_from_image(image)
	_stats.texture_us += Time.get_ticks_usec() - started
	if loaded == null or loaded.get_width() != WIDTH or loaded.get_height() != FRAME_SIZE:
		return _load_failure(key, "texture_create")
	_textures[key] = loaded
	_order.append(key)
	_stats.loads += 1
	return loaded

func _valid_entry(key: String, entry: Dictionary) -> bool:
	if not _token(entry.get("id")) or not _token(entry.get("hero")) or entry.get("phase") not in ["CAST", "CONTACT", "TAIL", "AURA"]:
		return false
	if key != str(entry.id) + ":" + str(entry.phase) or not _relative_png(entry.get("file")):
		return false
	if str(entry.id).begins_with("INNATE_") and (entry.phase != "AURA" or entry.id != "INNATE_" + str(entry.hero)):
		return false
	if not _number_is(entry.get("width"), WIDTH) or not _number_is(entry.get("height"), FRAME_SIZE) or not _positive_integer(entry.get("bytes"), MAX_PNG_BYTES):
		return false
	if not _sha(entry.get("sha256")) or not _sha(entry.get("rgba_sha256")):
		return false
	var frames: Variant = entry.get("frame_rgba_sha256")
	if not frames is Array or frames.size() != FRAMES:
		return false
	for value: Variant in frames:
		if not _sha(value):
			return false
	return true

func diagnostics() -> Dictionary:
	var out := _stats.duplicate(true)
	out.merge({"version": "hero-atlas-v9", "initialized": _initialized, "valid": _valid,
		"manifest_path": _manifest_path, "entries": _entries.size(), "sources": _sources.duplicate(true),
		"loaded_keys": _order.duplicate(), "resident_bytes": _textures.size() * ATLAS_BYTES,
		"budget_bytes": _budget_bytes, "capacity": _capacity, "max_textures": MAX_TEXTURES,
		"textures": _textures.size(), "failed_keys": _failed.keys()}, true)
	return out

func _load_failure(key: String, reason: String) -> Texture2D:
	_failed[key] = reason
	_reject(reason + ":" + key)
	return null

func _reject(reason: String) -> void:
	_stats.rejects += 1
	_stats.last_error = reason
	var category := reason.get_slice(":", 0)
	_stats.rejections[category] = int(_stats.rejections.get(category, 0)) + 1

static func _hash(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

static func _png_header(bytes: PackedByteArray) -> bool:
	if bytes.size() < 33:
		return false
	var signature := [137, 80, 78, 71, 13, 10, 26, 10]
	for n: int in range(signature.size()):
		if bytes[n] != signature[n]:
			return false
	if _big_endian_u32(bytes, 8) != 13 or bytes.slice(12, 16) != PackedByteArray([73, 72, 68, 82]):
		return false
	return _big_endian_u32(bytes, 16) == WIDTH and _big_endian_u32(bytes, 20) == FRAME_SIZE and bytes[24] == 8 and bytes[25] == 6 and bytes[26] == 0 and bytes[27] == 0 and bytes[28] in [0, 1]

static func _big_endian_u32(bytes: PackedByteArray, offset: int) -> int:
	return (int(bytes[offset]) << 24) | (int(bytes[offset + 1]) << 16) | (int(bytes[offset + 2]) << 8) | int(bytes[offset + 3])

static func _number_is(value: Variant, expected: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == expected

static func _positive_integer(value: Variant, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) > 0 and float(value) <= maximum

static func _token(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	for character: String in value:
		if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_":
			return false
	return true

static func _sha(value: Variant) -> bool:
	if not value is String or value.length() != 64:
		return false
	for character: String in value:
		if character not in "0123456789abcdef":
			return false
	return true

static func _relative_png(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 256 or not value.ends_with(".png") or value.is_absolute_path() or value.contains(":") or value.contains("\\"):
		return false
	for part: String in value.split("/", true):
		if part in ["", ".", ".."]:
			return false
		for character: String in part:
			if character not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-":
				return false
	return true

static func _safe_resource(path: String) -> bool:
	if not path.begins_with("res://") or path.contains("\\"):
		return false
	var cursor := "res://"
	var parts := path.trim_prefix("res://").split("/", true)
	for part: String in parts:
		if part in ["", ".", ".."] or part.contains(":"):
			return false
		var directory := DirAccess.open(cursor)
		if directory == null or directory.is_link(part):
			return false
		cursor = cursor.path_join(part)
	return true
