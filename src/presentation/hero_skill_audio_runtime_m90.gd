extends "res://src/presentation/hero_skill_audio_runtime_m88.gd"
## Lazy, source-bound PCM receipts for current cues. This does not alter any
## oscillator, voice budget, acoustic identity, event or old M63 native guard.
const RENDER_ROOT_M90 := "res://assets/audio/m90_skill_renders/"
const MANIFEST_SCHEMA_M90 := "m90.current-audio-renders/v1"
var _manifest_checked_m90 := false
var _manifest_m90: Dictionary = {}
var _render_root_m90 := RENDER_ROOT_M90
var _receipt_hits_m90 := 0
var _receipt_misses_m90 := 0

static func pcm_sha256_m90(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK: return ""
	if context.update(data) != OK: return ""
	return context.finish().hex_encode()

static func foley_signature_m90(foley: AudioStreamWAV) -> String:
	if foley == null: return "none"
	var data := foley.data
	return JSON.stringify([foley.format,foley.mix_rate,foley.stereo,foley.loop_mode,foley.loop_begin,foley.loop_end,data.size(),pcm_sha256_m90(data)]).sha256_text()

static func receipt_key_m90(entry: Dictionary,signature: String) -> String:
	return JSON.stringify([str(entry.get("id","")),signature]).sha256_text()

func _signature_m90(foley: AudioStreamWAV) -> String:
	# Cold stream builds only. Hash current bytes rather than object identity:
	# an unusual caller may replace PCM inside the same AudioStreamWAV.
	return foley_signature_m90(foley)

func _manifest_allowed_m90() -> bool:
	if _manifest_checked_m90: return not _manifest_m90.is_empty()
	_manifest_checked_m90 = true
	var path := _render_root_m90.path_join("manifest.json")
	if not FileAccess.file_exists(path): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("schema") != MANIFEST_SCHEMA_M90 or parsed.get("accepted") != true or parsed.get("recipe_version") != VERSION: return false
	var pins: Dictionary = parsed.get("runtime_source_sha256",{})
	# These must be present even in a malformed or source-stripped package.
	for required: String in [SOURCE_PATH_M88,KERNEL_PATH_M88,"res://src/presentation/hero_skill_audio_runtime_m88.gd","res://src/presentation/hero_skill_audio_runtime_m90.gd","res://src/presentation/strategic_sound_palette.gd","res://src/presentation/strategic_audio_feedback.gd","res://assets/data/m57-lore.json"]:
		if not pins.has(required): return false
	for input: String in pins:
		if not input.begins_with("res://") or not FileAccess.file_exists(input) or FileAccess.get_sha256(input) != str(pins[input]): return false
	if not parsed.get("files") is Dictionary or parsed.files.is_empty(): return false
	_manifest_m90 = parsed
	return true

func _current_render_m90(entry: Dictionary,foley: AudioStreamWAV) -> AudioStreamWAV:
	if not _manifest_allowed_m90(): return null
	var signature := _signature_m90(foley)
	var key := receipt_key_m90(entry,signature)
	var receipt: Dictionary = _manifest_m90.files.get(key,{})
	if receipt.get("recipe_id") != entry.id or receipt.get("acoustic_fingerprint") != entry.acoustic_fingerprint or receipt.get("foley_signature") != signature: return null
	var name := str(receipt.get("file",""))
	if name != key + ".wav": return null
	var path := _render_root_m90.path_join(name)
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != str(receipt.get("sha256","")): return null
	var wave := AudioStreamWAV.load_from_file(path)
	if wave == null or wave.stereo or wave.mix_rate != RATE or wave.format != AudioStreamWAV.FORMAT_16_BITS or wave.loop_mode != AudioStreamWAV.LOOP_DISABLED: return null
	var data := wave.data
	if data.size() != int(receipt.get("pcm_bytes",-1)) or pcm_sha256_m90(data) != str(receipt.get("pcm_sha256","")): return null
	if data.size() != ceili(float(entry.seconds)*RATE)*2 or wave.get_length() > float(entry.seconds)+.001: return null
	return wave

func resolve(cue: Dictionary,foley: AudioStreamWAV = null) -> Dictionary:
	# Explicit forced composition continues to mean precisely that, including
	# for current exported cues and source-certificate fallback regression tests.
	if bool(cue.get("force_compose",false)): return super.resolve(cue,foley)
	var entry := describe(cue)
	var id := str(entry.id) + ("+cc0" if foley != null else "")
	if not _cache.has(id):
		var wave := _current_render_m90(entry,foley)
		if wave == null:
			_receipt_misses_m90 += 1
			return super.resolve(cue,foley)
		_receipt_hits_m90 += 1
		while not _lru.is_empty() and (_cache.size() >= MAX_CACHE_ENTRIES or _pcm_bytes + wave.data.size() > MAX_PCM_BYTES):
			var oldest: String = _lru.pop_front()
			_pcm_bytes -= int(_cache[oldest].data.size())
			_cache.erase(oldest)
		_cache[id] = wave
		_pcm_bytes += wave.data.size()
		_build_count += 1
		_native_count += 1
	_lru.erase(id)
	_lru.append(id)
	var result := entry.duplicate(true)
	result.merge({"stream":_cache[id],"gain":.74 if bool(entry.ultimate) else .64,"asset_id":id,"path":"","source":"ORIGINAL_LAYERED_CC0" if foley != null else "ORIGINAL_LAYERED"},true)
	result["material"] = str(cue.get("material",""))
	return result

func m90_diagnostics() -> Dictionary:
	return {"manifest_checked":_manifest_checked_m90,"manifest_valid":not _manifest_m90.is_empty(),"render_hits":_receipt_hits_m90,"render_misses":_receipt_misses_m90}

func clear() -> void:
	super.clear()
