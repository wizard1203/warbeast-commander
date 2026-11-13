extends RefCounted
## Source-bound, locally qualified pure graph batch. Missing or unsupported
## packages retain the complete original script planner, never fewer obstacles.
const PACK_ROOT := "res://native/navigation_m99/"
const MANIFEST := PACK_ROOT + "manifest.json"
const DESCRIPTOR := PACK_ROOT + "warbeast_navigation_m99.gdextension"
const BINARY := "bin/libwarbeast_navigation_m99.dylib"
const CLASS_NAME := "WarbeastNavigationM99"
static var _attempted := false
static var _backend: RefCounted = null
static var _state := "UNINITIALIZED"
static var _reason := "NOT_REQUESTED"
static var _load_attempts := 0
static var _direct_calls := 0
static var _native_hits := 0
static var _script_fallbacks := 0
static var _manifest_sha256 := ""
static var _binary_sha256 := ""

static func try_solve_graph(nodes: Array[Vector2i], centers: PackedVector2Array, reach_squares: PackedFloat64Array, rectangles: Array[Rect2i]) -> Dictionary:
	var bridge := get_backend()
	if bridge == null:
		_script_fallbacks += 1
		return {"accepted":false,"path":[]}
	_direct_calls += 1
	var raw: Variant = bridge.solve_graph(nodes,centers,reach_squares,rectangles)
	if not raw is Dictionary or not bool(raw.get("accepted",false)) or not raw.get("path") is Array:
		_script_fallbacks += 1
		return {"accepted":false,"path":[]}
	var path: Array[Vector2i] = []
	if raw.path.size() > nodes.size():
		_script_fallbacks += 1
		return {"accepted":false,"path":[]}
	for value: Variant in raw.path:
		if typeof(value) != TYPE_VECTOR2I or value not in nodes:
			_script_fallbacks += 1
			return {"accepted":false,"path":[]}
		path.append(value)
	# New top-level array; no input containers or body references can escape.
	_native_hits += 1
	return {"accepted":true,"path":path}

static func get_backend() -> RefCounted:
	if not _attempted: _load_once()
	return _backend

static func diagnostics() -> Dictionary:
	return {"state":_state,"reason":_reason,"load_attempts":_load_attempts,"direct_calls":_direct_calls,"native_hits":_native_hits,"script_fallbacks":_script_fallbacks,"manifest_sha256":_manifest_sha256,"binary_sha256":_binary_sha256,"descriptor":DESCRIPTOR,"qualification":"local-qualified-mac-arm64-exact-graph-not-mobile"}

static func reset_diagnostics() -> void:
	_direct_calls=0;_native_hits=0;_script_fallbacks=0

static func _decline(reason: String) -> void:
	_state="SCRIPT_FALLBACK";_reason=reason;_backend=null

static func _load_once() -> void:
	_attempted=true;_load_attempts+=1
	var version := Engine.get_version_info()
	if OS.get_name()!="macOS" or Engine.get_architecture_name()!="arm64":
		_decline("UNQUALIFIED_PLATFORM");return
	if int(version.get("major",0))!=4 or int(version.get("minor",0))!=7 or int(version.get("patch",0))!=2 or str(version.get("status",""))!="stable" or str(version.get("build",""))!="official" or str(version.get("hash",""))!="ed1daf0bf001b61586d9930840f2f1394092c079":
		_decline("UNQUALIFIED_ENGINE_BUILD");return
	if not FileAccess.file_exists(MANIFEST):_decline("EXPERIMENT_MANIFEST_MISSING");return
	var handle := FileAccess.open(MANIFEST,FileAccess.READ)
	if handle==null:_decline("EXPERIMENT_MANIFEST_UNREADABLE");return
	var content := handle.get_as_text();handle.close()
	_manifest_sha256=content.sha256_text()
	var parsed: Variant = JSON.parse_string(content)
	if not parsed is Dictionary or parsed.get("schema","")!="warbeast.native-navigation-pack/v1" or not parsed.get("files") is Dictionary:
		_decline("EXPERIMENT_MANIFEST_INVALID");return
	if parsed.get("class_name","")!=CLASS_NAME or parsed.get("descriptor","")!="warbeast_navigation_m99.gdextension":
		_decline("EXPERIMENT_IDENTITY_INVALID");return
	var files: Dictionary = parsed.files
	for required: String in ["navigation_graph_binding.cpp","CMakeLists.txt","warbeast_navigation_m99.gdextension",BINARY,"LICENSE","licenses/godot-cpp-LICENSE.md","qualification/build-report.json","qualification/original.gdextension","qualification/projection.json","qualification/projection-generator.mjs"]:
		if not files.has(required):_decline("EXPERIMENT_REQUIRED_HASH_MISSING");return
	for relative: Variant in files:
		if typeof(relative)!=TYPE_STRING or relative.is_absolute_path() or ".." in relative.split("/") or "\\" in relative:
			_decline("EXPERIMENT_HASH_PATH_INVALID");return
		var expected: Variant = files[relative]
		if typeof(expected)!=TYPE_STRING or expected.length()!=64 or not FileAccess.file_exists(PACK_ROOT+str(relative)) or FileAccess.get_sha256(PACK_ROOT+str(relative))!=expected:
			_decline("EXPERIMENT_SOURCE_OR_BINARY_DRIFT");return
	# The projection generator checks the retained full proof files once.
	# All original bytes are still hash-verified above; avoid JSON-parsing
	# captured armies and thousands of audio receipts in the game process.
	var proof:Variant=JSON.parse_string(FileAccess.get_file_as_string(PACK_ROOT+"qualification/projection.json"))
	if not proof is Dictionary or proof.get("schema","")!="warbeast.navigation-qualification/v1" or not bool(proof.get("accepted",false)) or proof.get("generator_sha256","")!=files["qualification/projection-generator.mjs"]:
		_decline("PACKAGE_QUALIFICATION_INVALID");return
	var build:Variant=proof.get("build")
	if not build is Dictionary or not bool(build.get("accepted",false)) or not bool(build.get("source_drift_empty",false)) or build.get("report_sha256","")!=files["qualification/build-report.json"]:
		_decline("PACKAGE_BUILD_NOT_ACCEPTED");return
	var bound_files:Array=["navigation_graph_binding.cpp","CMakeLists.txt","qualification/original.gdextension","LICENSE","licenses/godot-cpp-LICENSE.md",BINARY]
	for required:String in bound_files:
		if build.get("files",{}).get(required,"")!=files[required]:
			_decline("PACKAGE_COMPILED_SOURCE_MISMATCH");return
	var original:String=FileAccess.get_file_as_string(PACK_ROOT+"qualification/original.gdextension")
	if original.replace(".build/gdextension-01/bin/libwarbeast_navigation_m99.dylib",BINARY)!=FileAccess.get_file_as_string(DESCRIPTOR):
		_decline("PACKAGE_DESCRIPTOR_TRANSFORM_MISMATCH");return
	var qualifications:Variant=proof.get("qualifications")
	var originals:Variant=parsed.get("qualifications")
	if not qualifications is Array or qualifications.size()!=2 or not originals is Array or originals.size()!=2:
		_decline("PACKAGE_QUALIFICATION_MISSING");return
	var engine_sha:String=FileAccess.get_sha256(OS.get_executable_path())
	if engine_sha.is_empty() or proof.get("engine_sha256","")!=engine_sha:
		_decline("PACKAGE_QUALIFICATION_ENGINE_MISMATCH");return
	for index:int in range(qualifications.size()):
		var row:Variant=qualifications[index]
		var origin:Variant=originals[index]
		if not row is Dictionary or not origin is Dictionary or row.get("report")!=origin.get("report") or row.get("process")!=origin.get("process") or not files.has(row.get("report","")) or not files.has(row.get("process","")):
			_decline("PACKAGE_QUALIFICATION_PATH_INVALID");return
		if row.get("report_sha256","")!=files[row.report] or row.get("process_sha256","")!=files[row.process] or not bool(row.get("accepted",false)) or int(row.get("actual_exit_code",-1))!=0 or row.get("actual_exit_signal")!=null or not bool(row.get("engine_errors_empty",false)) or not bool(row.get("source_drift_empty",false)):
			_decline("PACKAGE_QUALIFICATION_NOT_ACCEPTED");return
		if row.get("engine_before_sha256","")!=engine_sha or row.get("engine_after_sha256","")!=engine_sha:
			_decline("PACKAGE_QUALIFICATION_ENGINE_MISMATCH");return
		for required:String in bound_files:
			if row.get("source_before_sha256",{}).get(required,"")!=files[required] or row.get("source_after_sha256",{}).get(required,"")!=files[required]:
				_decline("PACKAGE_QUALIFICATION_SOURCE_MISMATCH");return
	_binary_sha256=str(files[BINARY])
	var already_loaded := GDExtensionManager.is_extension_loaded(DESCRIPTOR)
	if ClassDB.class_exists(CLASS_NAME) and not already_loaded:
		_decline("FOREIGN_CLASS_ALREADY_REGISTERED");return
	if not already_loaded:
		var status := GDExtensionManager.load_extension(DESCRIPTOR)
		if status not in [GDExtensionManager.LOAD_STATUS_OK,GDExtensionManager.LOAD_STATUS_ALREADY_LOADED]:
			_decline("EXPERIMENT_LOAD_DECLINED");return
	if not GDExtensionManager.is_extension_loaded(DESCRIPTOR) or not ClassDB.class_exists(CLASS_NAME):
		_decline("EXPERIMENT_CLASS_NOT_REGISTERED");return
	var instance: Variant = ClassDB.instantiate(CLASS_NAME)
	if not instance is RefCounted or not instance.has_method("solve_graph"):
		_decline("EXPERIMENT_CAPABILITY_INCOMPLETE");return
	_backend=instance;_state="READY";_reason="QUALIFIED_LOCAL_PACKAGE"
