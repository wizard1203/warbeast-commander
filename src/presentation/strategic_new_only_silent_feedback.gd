extends "res://src/presentation/strategic_audio_feedback.gd"
const SilentPalette = preload("res://src/presentation/strategic_new_only_silent_palette.gd")

func _init(reason: String = "PRIVATE_PACKAGE_UNAVAILABLE") -> void:
	var palette := SilentPalette.new()
	palette.unavailable_reason = reason
	_sound_palette = palette

func reset() -> void:
	super.reset()
	_sound_palette.clear()

func advance(delta: float) -> void:
	# Notices still follow the normal projector, but an unavailable package must
	# not spend work synthesizing historical fallback PCM that nobody may hear.
	var palette: Variant = _sound_palette
	for cue: Dictionary in _pending:
		palette.resolve(cue, null)
	_pending.clear()
	super.advance(delta)

func set_combat_paused(value: bool) -> void:
	super.set_combat_paused(value)
	if value: _stop_voices()
