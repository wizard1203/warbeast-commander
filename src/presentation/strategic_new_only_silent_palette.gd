extends "res://src/presentation/strategic_sound_palette.gd"
## Safe checkout/export fallback when the licensed private local package is absent.
## Keep visual notices, but never synthesize or resolve historical audio.
var unavailable_reason := "PRIVATE_PACKAGE_UNAVAILABLE"
var unmapped_cues: Dictionary = {}

func resolve(cue: Dictionary, _original_fallback: AudioStreamWAV) -> Dictionary:
	var kind := str(cue.get("kind", "UNKNOWN"))
	unmapped_cues[kind] = int(unmapped_cues.get(kind, 0))+1
	return {"stream":null, "gain":0.0, "source":"NEW_ONLY_PACKAGE_UNAVAILABLE", "audio_policy":"NEW_ONLY", "reason":unavailable_reason}

func diagnostics() -> Dictionary:
	return {"audio_policy":"NEW_ONLY", "package_available":false, "package_reason":unavailable_reason, "mapping_count":0, "neural_choices":0, "legacy_choices":0, "neural_loaded":0, "neural_pcm_bytes":0, "unmapped_cues_by_kind":unmapped_cues.duplicate(true), "local_noncommercial":true}

func clear() -> void:
	unmapped_cues.clear()
