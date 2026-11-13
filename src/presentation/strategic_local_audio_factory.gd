extends RefCounted
## Default local gameplay audio policy: new SA3 sounds, or explicit silence.
## Raw/private audio remains local noncommercial evaluation material. This
## factory grants no distribution or commercial rights and downloads nothing.
const MANIFEST := "res://private-materials/outposts-v4-audio/package-38/manifest.json"
const LOCAL_FEEDBACK := "res://tools/asset_workshop/neural_arena_feedback.gd"
const SilentFeedback = preload("res://src/presentation/strategic_new_only_silent_feedback.gd")

static func create(manifest_path: String = "") -> Node:
	# Optional path is a narrow test seam: failure tests never rename or damage
	# the user's real private package. Empty selects the installed local package.
	var path := MANIFEST if manifest_path.is_empty() else manifest_path
	if not FileAccess.file_exists(path): return SilentFeedback.new("PRIVATE_MANIFEST_MISSING")
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return SilentFeedback.new("PRIVATE_MANIFEST_INVALID_JSON")
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return SilentFeedback.new("PRIVATE_MANIFEST_INVALID_JSON")
	if parsed.get("license_scope", "") != "LOCAL_NONCOMMERCIAL_EVALUATION_ONLY":
		return SilentFeedback.new("PRIVATE_MANIFEST_LICENSE_SCOPE_REJECTED")
	if not parsed.get("entries") is Dictionary or parsed.entries.is_empty():
		return SilentFeedback.new("PRIVATE_MANIFEST_EMPTY_OR_INVALID_ENTRIES")
	if not ResourceLoader.exists(LOCAL_FEEDBACK): return SilentFeedback.new("LOCAL_AUDIO_ADAPTER_MISSING")
	var adapter: Script = load(LOCAL_FEEDBACK)
	if adapter == null or not adapter.can_instantiate(): return SilentFeedback.new("LOCAL_AUDIO_ADAPTER_UNAVAILABLE")
	var feedback: Node = adapter.new(path)
	if not feedback.has_method("diagnostics"):
		feedback.free()
		return SilentFeedback.new("LOCAL_AUDIO_ADAPTER_INTERFACE_INVALID")
	var state: Dictionary = feedback.diagnostics()
	if state.get("audio_policy", "") != "NEW_ONLY" or int(state.get("mapping_count", 0)) <= 0:
		feedback.free()
		return SilentFeedback.new("PRIVATE_MANIFEST_HAS_NO_VALID_MAPPINGS")
	return feedback
