extends RefCounted
## Optional, source-bound pure batch backend. Missing/unsupported packages keep
## the complete script resolver. No authority/body references survive a call.
const Codec = preload("res://src/simulation/strategic_native_bodies_m94.gd")
const PACK_ROOT := "res://native/body_resolver_m94/"
const MANIFEST := PACK_ROOT + "manifest.json"
const DESCRIPTOR := PACK_ROOT + "warbeast_body_m94.gdextension"
const CLASS_NAME := "WarbeastBodyM94"
static var _attempted := false
static var _backend: RefCounted = null
static var _state := "UNINITIALIZED"
static var _reason := "NOT_REQUESTED"
static var _manifest_sha256 := ""
static var _binary_sha256 := ""
static var _load_attempts := 0
static var _direct_calls := 0
static var _native_hits := 0
static var _script_fallbacks := 0

static func try_resolve(bodies: Array[Dictionary], bounds: Rect2i, max_step: int) -> Dictionary:
	var bridge := get_backend()
	if bridge == null:
		_script_fallbacks += 1
		return {"accepted":false,"positions":{}}
	_direct_calls += 1
	var result: Dictionary = Codec.try_with(bridge,bodies,bounds,max_step)
	if bool(result.get("accepted",false)):
		_native_hits += 1
		return result
	_script_fallbacks += 1
	return {"accepted":false,"positions":{}}

static func get_backend() -> RefCounted:
	if not _attempted: _load_once()
	return _backend

static func diagnostics() -> Dictionary:
	return {"state":_state,"reason":_reason,"load_attempts":_load_attempts,"direct_calls":_direct_calls,"native_hits":_native_hits,"script_fallbacks":_script_fallbacks,"raw_codec_calls":0,"manifest_sha256":_manifest_sha256,"binary_sha256":_binary_sha256,"descriptor":DESCRIPTOR}

static func reset_diagnostics() -> void:
	# This does not unload/reload a native class or reset its qualification.
	_direct_calls=0; _native_hits=0; _script_fallbacks=0

static func _decline(reason: String) -> void:
	_state="SCRIPT_FALLBACK"; _reason=reason; _backend=null

static func _load_once() -> void:
	_attempted=true; _load_attempts+=1
	var version:=Engine.get_version_info()
	if OS.get_name()!="macOS" or Engine.get_architecture_name()!="arm64":
		_decline("UNQUALIFIED_PLATFORM"); return
	if int(version.get("major",0))!=4 or int(version.get("minor",0))!=7 or int(version.get("patch",0))!=2 or str(version.get("status",""))!="stable" or str(version.get("build",""))!="official" or str(version.get("hash",""))!="ed1daf0bf001b61586d9930840f2f1394092c079":
		_decline("UNQUALIFIED_ENGINE_BUILD"); return
	if not FileAccess.file_exists(MANIFEST): _decline("PACKAGE_MANIFEST_MISSING"); return
	var handle:=FileAccess.open(MANIFEST,FileAccess.READ)
	if handle==null: _decline("PACKAGE_MANIFEST_UNREADABLE"); return
	var content:=handle.get_as_text(); handle.close()
	_manifest_sha256=content.sha256_text()
	var parsed: Variant=JSON.parse_string(content)
	if not parsed is Dictionary or parsed.get("schema","")!="warbeast.native-body-pack/v1" or not parsed.get("files") is Dictionary:
		_decline("PACKAGE_MANIFEST_INVALID"); return
	if parsed.get("class_name","")!=CLASS_NAME or parsed.get("descriptor","")!="warbeast_body_m94.gdextension" or parsed.get("binary","")!="bin/libwarbeast_body_m94.dylib":
		_decline("PACKAGE_IDENTITY_INVALID"); return
	var files: Dictionary=parsed.files
	for required: String in ["body_resolver_core.hpp","body_resolver_binding.cpp","warbeast_body_m94.gdextension","bin/libwarbeast_body_m94.dylib","LICENSE","licenses/godot-cpp-LICENSE.md"]:
		if not files.has(required): _decline("PACKAGE_REQUIRED_HASH_MISSING"); return
	for relative: Variant in files:
		if typeof(relative)!=TYPE_STRING or relative.is_absolute_path() or ".." in relative.split("/") or "\\" in relative:
			_decline("PACKAGE_HASH_PATH_INVALID"); return
		var expected: Variant=files[relative]
		if typeof(expected)!=TYPE_STRING or expected.length()!=64:
			_decline("PACKAGE_HASH_INVALID"); return
		var path:=PACK_ROOT+str(relative)
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=expected:
			_decline("PACKAGE_SOURCE_OR_BINARY_DRIFT"); return
	_binary_sha256=str(files["bin/libwarbeast_body_m94.dylib"])
	# A same-named class from another extension is NOT our trusted capability.
	# Only accept pre-registration when this exact formal descriptor is loaded.
	var already_loaded:=GDExtensionManager.is_extension_loaded(DESCRIPTOR)
	if ClassDB.class_exists(CLASS_NAME) and not already_loaded:
		_decline("FOREIGN_CLASS_ALREADY_REGISTERED"); return
	if not already_loaded:
		var status:=GDExtensionManager.load_extension(DESCRIPTOR)
		if status not in [GDExtensionManager.LOAD_STATUS_OK,GDExtensionManager.LOAD_STATUS_ALREADY_LOADED]:
			_decline("EXTENSION_LOAD_DECLINED"); return
	if not GDExtensionManager.is_extension_loaded(DESCRIPTOR) or not ClassDB.class_exists(CLASS_NAME):
		_decline("FORMAL_CLASS_NOT_REGISTERED"); return
	var instance: Variant=ClassDB.instantiate(CLASS_NAME)
	if not instance is RefCounted or not instance.has_method("solve_bodies") or not instance.has_method("solve"):
		_decline("FORMAL_CAPABILITY_INCOMPLETE"); return
	_backend=instance; _state="READY"; _reason="QUALIFIED_PACKAGE"
