extends RefCounted
## Experimental, explicit-only local capability. No production consumer.
const PACK_ROOT := "res://performance-lab/batch-runtime-m100/native/"
const MANIFEST := PACK_ROOT + "build-manifest.json"
const DESCRIPTOR := PACK_ROOT + "warbeast_stat_batch_m100.gdextension"
const BINARY := ".build/gdextension-01/bin/libwarbeast_stat_batch_m100.dylib"
const CLASS_NAME := "WarbeastStatBatchM100"
static var _attempted := false
static var _backend: RefCounted = null
static var _reason := "NOT_REQUESTED"
static var _load_attempts := 0
static var _calls := 0
static var _hits := 0
static var _fallbacks := 0

static func try_boundaries(ordered: Array, records: Dictionary, technology: Dictionary, side_config: Dictionary, scope: int) -> Dictionary:
	var bridge := get_backend()
	if bridge == null:
		_fallbacks += 1
		return {"accepted":false,"flags":{}}
	_calls += 1
	var raw: Variant = bridge.validate_boundaries(ordered,records,technology,side_config,scope)
	if not raw is Dictionary or not bool(raw.get("accepted",false)) or not raw.get("flags") is Dictionary:
		_fallbacks += 1
		return {"accepted":false,"flags":{}}
	_hits += 1
	return raw

static func get_backend() -> RefCounted:
	if not _attempted:_load_once()
	return _backend

static func diagnostics() -> Dictionary:
	return {"ready":_backend!=null,"reason":_reason,"load_attempts":_load_attempts,"calls":_calls,"hits":_hits,"fallbacks":_fallbacks,"qualification":"experimental-local-only-not-default-or-mobile"}

static func _decline(reason: String) -> void:
	_reason=reason;_backend=null

static func _load_once() -> void:
	_attempted=true;_load_attempts+=1
	var version := Engine.get_version_info()
	if OS.get_name()!="macOS" or Engine.get_architecture_name()!="arm64":_decline("UNQUALIFIED_PLATFORM");return
	if int(version.get("major",0))!=4 or int(version.get("minor",0))!=7 or int(version.get("patch",0))!=2 or str(version.get("status",""))!="stable" or str(version.get("build",""))!="official" or str(version.get("hash",""))!="ed1daf0bf001b61586d9930840f2f1394092c079":_decline("UNQUALIFIED_ENGINE_BUILD");return
	if not FileAccess.file_exists(MANIFEST):_decline("EXPERIMENT_MANIFEST_MISSING");return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary or parsed.get("schema","")!="m100.stat-batch-build/v1" or not parsed.get("files") is Dictionary:_decline("EXPERIMENT_MANIFEST_INVALID");return
	if parsed.get("class_name","")!=CLASS_NAME or parsed.get("descriptor","")!="warbeast_stat_batch_m100.gdextension":_decline("EXPERIMENT_IDENTITY_INVALID");return
	var files: Dictionary=parsed.files
	for required: String in ["stat_batch_binding.cpp","CMakeLists.txt","warbeast_stat_batch_m100.gdextension",BINARY,"LICENSE"]:
		if not files.has(required):_decline("EXPERIMENT_REQUIRED_HASH_MISSING");return
	for relative: Variant in files:
		if typeof(relative)!=TYPE_STRING or relative.is_absolute_path() or ".." in relative.split("/") or "\\" in relative:_decline("EXPERIMENT_HASH_PATH_INVALID");return
		var expected: Variant=files[relative]
		if typeof(expected)!=TYPE_STRING or expected.length()!=64 or not FileAccess.file_exists(PACK_ROOT+str(relative)) or FileAccess.get_sha256(PACK_ROOT+str(relative))!=expected:_decline("EXPERIMENT_SOURCE_OR_BINARY_DRIFT");return
	var receipt: Variant=parsed.get("build_report","")
	var receipt_sha: Variant=parsed.get("build_report_sha256","")
	if typeof(receipt)!=TYPE_STRING or not receipt.begins_with("performance-lab/results/") or ".." in receipt.split("/") or "\\" in receipt or not receipt.ends_with("/report.json") or typeof(receipt_sha)!=TYPE_STRING or receipt_sha.length()!=64:_decline("EXPERIMENT_BUILD_RECEIPT_INVALID");return
	var receipt_path := "res://"+str(receipt)
	if not FileAccess.file_exists(receipt_path) or FileAccess.get_sha256(receipt_path)!=receipt_sha:_decline("EXPERIMENT_BUILD_RECEIPT_DRIFT");return
	var build: Variant=JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
	if not build is Dictionary or build.get("schema","")!="m100.native-build/v1" or not bool(build.get("accepted",false)) or not build.get("source_drift") is Array or not build.source_drift.is_empty() or not build.get("source_after_sha256") is Dictionary or not build.get("build_outputs_sha256") is Dictionary:_decline("EXPERIMENT_BUILD_NOT_ACCEPTED");return
	for required: String in ["stat_batch_binding.cpp","CMakeLists.txt","warbeast_stat_batch_m100.gdextension"]:
		if build.source_after_sha256.get(PACK_ROOT.trim_prefix("res://")+required,"")!=files[required]:_decline("EXPERIMENT_COMPILED_SOURCE_MISMATCH");return
	if build.build_outputs_sha256.get(PACK_ROOT.trim_prefix("res://")+BINARY,"")!=files[BINARY]:_decline("EXPERIMENT_COMPILED_BINARY_MISMATCH");return
	var already_loaded := GDExtensionManager.is_extension_loaded(DESCRIPTOR)
	if ClassDB.class_exists(CLASS_NAME) and not already_loaded:_decline("FOREIGN_CLASS_ALREADY_REGISTERED");return
	if not already_loaded:
		var status := GDExtensionManager.load_extension(DESCRIPTOR)
		if status not in [GDExtensionManager.LOAD_STATUS_OK,GDExtensionManager.LOAD_STATUS_ALREADY_LOADED]:_decline("EXPERIMENT_LOAD_DECLINED");return
	if not GDExtensionManager.is_extension_loaded(DESCRIPTOR) or not ClassDB.class_exists(CLASS_NAME):_decline("EXPERIMENT_CLASS_NOT_REGISTERED");return
	var instance: Variant=ClassDB.instantiate(CLASS_NAME)
	if not instance is RefCounted or not instance.has_method("validate_boundaries"):_decline("EXPERIMENT_CAPABILITY_INCOMPLETE");return
	_backend=instance;_reason="EXPLICIT_EXPERIMENT_PACKAGE"
