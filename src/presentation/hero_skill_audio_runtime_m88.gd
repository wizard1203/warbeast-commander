extends "res://src/presentation/hero_skill_audio.gd"
## Certified byte-equivalent fast fallback; original renderer and its bundled
## WAV receipts remain unchanged. Any source mismatch uses the original path.
const KernelM88 = preload("res://src/presentation/hero_skill_audio_kernel_m88.gd")
const SOURCE_PATH_M88 := "res://src/presentation/hero_skill_audio.gd"
const KERNEL_PATH_M88 := "res://src/presentation/hero_skill_audio_kernel_m88.gd"
const ORIGINAL_SHA_M88 := "f5944ca35b812d34d9368ff639fdf8fedf92d56896947106bee9454f9cf212db"
const KERNEL_SHA_M88 := "6430648507987c8537382f85fe6339b289fe6bbee7b3e183da51393f19553744"
var _fast_checked_m88 := false
var _fast_verified_m88 := false

static func _certificate_matches_m88(original_digest: String, kernel_digest: String) -> bool:
	return original_digest == ORIGINAL_SHA_M88 and kernel_digest == KERNEL_SHA_M88

func _source_digest_m88(path: String) -> String:
	# A source-stripped export deliberately falls back until independently
	# certified by its build pipeline; absence never means trusted.
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

func _fast_path_allowed_m88() -> bool:
	if not _fast_checked_m88:
		_fast_checked_m88 = true
		_fast_verified_m88 = _certificate_matches_m88(_source_digest_m88(SOURCE_PATH_M88), _source_digest_m88(KERNEL_PATH_M88))
	return _fast_verified_m88

func resolve(cue:Dictionary,foley:AudioStreamWAV=null)->Dictionary:
	if not _fast_path_allowed_m88(): return super.resolve(cue,foley)
	var entry:=describe(cue)
	var id:=str(entry.id)+("+cc0" if foley!=null else "")
	if not _cache.has(id):
		var wave:AudioStreamWAV=null
		if not bool(cue.get("force_compose",false)):wave=_native_render(entry)
		if wave!=null:_native_count+=1
		if wave==null:wave=KernelM88._compose(entry,foley)
		while not _lru.is_empty() and (_cache.size()>=MAX_CACHE_ENTRIES or _pcm_bytes+wave.data.size()>MAX_PCM_BYTES):
			var oldest:String=_lru.pop_front()
			_pcm_bytes-=int(_cache[oldest].data.size())
			_cache.erase(oldest)
		_cache[id]=wave
		_pcm_bytes+=wave.data.size()
		_build_count+=1
	_lru.erase(id)
	_lru.append(id)
	var result:=entry.duplicate(true)
	result.merge({"stream":_cache[id],"gain":0.74 if bool(entry.ultimate) else 0.64,"asset_id":id,"path":"","source":"ORIGINAL_LAYERED_CC0" if foley!=null else "ORIGINAL_LAYERED"},true)
	# Preserve the supplied physical classification for existing observers and
	# player metadata. It is not a second sound recipe or a gameplay property.
	result["material"]=str(cue.get("material",""))
	return result
