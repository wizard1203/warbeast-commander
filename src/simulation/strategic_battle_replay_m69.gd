extends RefCounted
## Real fixed-tick execution, detached sampled observations, never a second
## combat rules engine. Playback has no simulation, command sender or sound.
const Simulation = preload("res://src/simulation/strategic_simulation.gd")
const Arena = preload("res://src/simulation/strategic_hero_arena_runner.gd")
const Matches = preload("res://src/simulation/strategic_match_catalog.gd")
const MatchScores = preload("res://src/simulation/strategic_match_scores_m72.gd")
const VERSION := "outposts-v4.battle-observation-replay/v1"
const MAGIC := "WBREPLAY69\n"
const MAX_SECONDS := 900
const MAX_FRAMES := 1502
const MAX_BYTES := 96 * 1024 * 1024
const MAX_FILE_BYTES := 32 * 1024 * 1024
const MAX_FRAME_BYTES := 4 * 1024 * 1024
const SAMPLE_TICKS := 4 # 5 observations/s; no invented between-frame events.
var _sample_ticks := SAMPLE_TICKS
const STATIC_FIELDS := ["scenario","match_settings","match_config","match_setup","sides","arena_bounds","catalog","terrain"]
const OMITTED_FIELDS := ["computer","strategic","hero_quotes"] # duplicates / admission menus, not viewer facts.
var _engine: RefCounted
var _kind := ""
var _request: Dictionary = {}
var _frames: Array = []
var _static: Dictionary = {}
var _source: Dictionary = {}
var _source_after: Dictionary = {}
var _running := false
var _tick := 0
var _limit := 0
var _bytes := 0
var _wall_us := 0
var _termination := "READY"
var _final_hash := ""
var _error := ""

func configure_strategic(request: Dictionary, seed: int, seconds: int = 120) -> Dictionary:
	if seconds < 1 or seconds > MAX_SECONDS: return _reject("INVALID_DURATION")
	var autonomous := request.duplicate(true)
	if autonomous.is_empty(): autonomous = Matches.default_request()
	if not autonomous.get("participants") is Array: return _reject("INVALID_PARTICIPANTS")
	# All participants use the SAME public rule AI, including the left slot.
	# This detached copy does not turn the user's real match into observer mode.
	for slot: Variant in autonomous.participants:
		if not slot is Dictionary: return _reject("INVALID_PARTICIPANTS")
		slot["controller"] = "AI"
	var validation: Dictionary = Matches.resolve(autonomous)
	if not validation.accepted: return validation
	var engine := Simulation.new(seed,true)
	var configured: Dictionary = engine.configure_lobby(autonomous)
	if not configured.accepted: return configured
	engine.submit_command({"type":"START_BATTLE"})
	_begin(engine,"STRATEGIC",{"match":autonomous,"seed":seed,"limit_seconds":seconds},seconds)
	return {"accepted":true,"error":""}

func configure_arena(config: Dictionary) -> Dictionary:
	var validation: Dictionary = Arena.validate(config)
	if not validation.accepted: return validation
	var engine := Arena.new()
	var configured: Dictionary = engine.configure(config)
	if not configured.accepted: return configured
	engine.start_run()
	_begin(engine,"ARENA",config,int(config.limit_seconds))
	return {"accepted":true,"error":""}

func _begin(engine: RefCounted, kind: String, request: Dictionary, seconds: int) -> void:
	_engine = engine
	_kind = kind
	_request = request.duplicate(true)
	_frames.clear()
	_static.clear()
	_source = source_hashes()
	_source_after.clear()
	_tick = 0
	_limit = seconds * 20
	_sample_ticks=maxi(SAMPLE_TICKS,ceili(float(_limit)/1500.0))
	_bytes = 0
	_wall_us = 0
	_termination = "RUNNING"
	_final_hash = ""
	_error = ""
	_running = true
	_record()

## UI calls once/frame; the budget includes ALL authority work and recording.
## One unusually slow authority tick cannot be preempted mid-settlement.
func pump(budget_ms: float = 7.0, max_ticks: int = 160) -> Dictionary:
	if not _running: return progress()
	var start := Time.get_ticks_usec()
	var count := 0
	while _running and count < clampi(max_ticks,1,6000):
		_step()
		count += 1
		if Time.get_ticks_usec()-start >= int(clampf(budget_ms,0.1,40.0)*1000): break
	_wall_us += Time.get_ticks_usec()-start
	return progress()

func _step() -> void:
	if _kind == "STRATEGIC":
		if not _engine.advance_tick(): _finish("TERMINAL"); return
	else:
		_engine.step(1)
	_tick += 1
	if _tick % _sample_ticks == 0: _record()
	if not _running: return
	if _terminal():
		var reason := "TIME_BOUND" if _kind=="ARENA" and str(_engine.snapshot().get("arena",{}).get("outcome",""))=="TIME_BOUND" else "TERMINAL"
		_finish(reason)
	elif _tick >= _limit: _finish("TIME_BOUND")

func _terminal() -> bool:
	if _kind == "STRATEGIC": return str(_engine.get_outcome()) != "ONGOING"
	return not bool(_engine.snapshot().get("arena",{}).get("running",false))

func cancel() -> void:
	if _running: _finish("CANCELLED")

func _finish(reason: String) -> void:
	_running = false
	_termination = reason
	if _frames.is_empty() or int(_frames.back().tick) != _tick: _record()
	if _engine != null: _final_hash = str(_engine.get_state_hash()) if _kind == "STRATEGIC" else str(_engine.state_hash())
	_source_after=source_hashes()
	# Retain observations, not a live mutable engine, once the run has ended.
	_engine = null

func _observation() -> Dictionary:
	var result: Dictionary = _engine.get_snapshot() if _kind == "STRATEGIC" else _engine.snapshot()
	result["tick"] = _tick
	result["tick_ms"] = 50
	return result

func _record() -> void:
	if _engine == null: return
	var value := _observation()
	if _frames.is_empty():
		for field: String in STATIC_FIELDS:
			if value.has(field): _static[field] = value[field]
		_bytes = var_to_bytes(_static).size()
	for field: String in STATIC_FIELDS: value.erase(field)
	for field: String in OMITTED_FIELDS: value.erase(field)
	var raw := var_to_bytes(value)
	if raw.size()>MAX_FRAME_BYTES:
		_running=false
		_termination="MEMORY_BOUND"
		_error="REPLAY_FRAME_LIMIT"
		_final_hash=str(_engine.get_state_hash()) if _kind=="STRATEGIC" else str(_engine.state_hash())
		_source_after=source_hashes()
		_engine=null
		return
	# Per-frame compression keeps a five-minute full-world recording bounded.
	# Only the displayed frame is decoded; no array of giant actor dictionaries.
	var payload := raw.compress(FileAccess.COMPRESSION_GZIP)
	var needed := payload.size()+32
	if _frames.size() >= MAX_FRAMES or _bytes+needed > MAX_BYTES:
		_error = "REPLAY_MEMORY_LIMIT"
		_running = false
		_termination = "MEMORY_BOUND"
		_final_hash = str(_engine.get_state_hash()) if _kind == "STRATEGIC" else str(_engine.state_hash())
		_source_after=source_hashes()
		_engine = null
		return
	_frames.append({"tick":_tick,"payload":payload})
	_bytes += needed

func progress() -> Dictionary:
	return {"running":_running,"tick":_tick,"limit_ticks":_limit,"fraction":float(_tick)/maxf(_limit,1),"frames":_frames.size(),"bytes":_bytes,"wall_seconds":float(_wall_us)/1000000.0,"observed_speed":float(_tick)*50000.0/maxf(_wall_us,1),"termination":_termination,"error":_error,"kind":_kind}

func replay() -> Dictionary:
	return {"schema":VERSION,"kind":_kind,"request":_request.duplicate(true),"sample_ticks":_sample_ticks,"tick_ms":50,"last_tick":int(_frames.back().tick) if not _frames.is_empty() else 0,"computed_ticks":_tick,"limit_ticks":_limit,"termination":_termination,"complete":not _running,"static":_static.duplicate(true),"frames":_frames.duplicate(true),"source_sha256":_source.duplicate(true),"source_after_sha256":_source_after.duplicate(true),"source_unchanged":_source==_source_after,"final_state_sha256":_final_hash,"recorded_bytes":_bytes,"wall_seconds":float(_wall_us)/1000000.0,"scope":"Read-only sampled observations, not a command replay or resumable save. Frame period = sample_ticks * 50ms (5Hz up to 300s, adaptively fewer samples for longer runs). Full strategic mode advances rule AI, economy, construction, production and combat on the same 20Hz authority. TIME_BOUND/CANCELLED/MEMORY_BOUND are unfinished, not winners."}

static func observation_at(recording: Dictionary, target_tick: int) -> Dictionary:
	var frames: Array = recording.get("frames",[])
	if frames.is_empty(): return {}
	var wanted := clampi(target_tick,0,int(recording.get("last_tick",0)))
	var low := 0
	var high := frames.size()-1
	while low < high:
		var mid := (low+high+1)/2
		if int(frames[mid].tick) <= wanted: low = mid
		else: high = mid-1
	var result: Dictionary = recording.get("static",{}).duplicate(true)
	var decoded := _decode_frame(frames[low])
	if decoded.is_empty(): return {}
	result.merge(decoded,true)
	result["replay_read_only"] = true
	return result

static func validate(recording: Variant, require_local_source: bool = false, cancelled: Callable = Callable()) -> Dictionary:
	if cancelled.is_valid() and bool(cancelled.call()): return _reject("REPLAY_IO_CANCELLED")
	if not recording is Dictionary:return _reject("UNSUPPORTED_REPLAY_VERSION")
	if recording.get("schema","")=="m69.battle-observation-replay/v1":return _reject("V2_REPLAY_USE_PRESERVED_V2")
	if recording.get("schema","")!=VERSION:return _reject("UNSUPPORTED_REPLAY_VERSION")
	if not _safe_value(recording,0,{"nodes":0}): return _reject("INVALID_REPLAY_VALUES")
	if recording.get("kind","") not in ["STRATEGIC","ARENA"]: return _reject("INVALID_REPLAY_KIND")
	if typeof(recording.get("complete"))!=TYPE_BOOL or not recording.complete: return _reject("INCOMPLETE_REPLAY_WRITE")
	for field: String in ["last_tick","computed_ticks","limit_ticks","sample_ticks","tick_ms"]:
		if typeof(recording.get(field))!=TYPE_INT: return _reject("INVALID_REPLAY_HEADER")
	if recording.computed_ticks<recording.last_tick or recording.computed_ticks>recording.limit_ticks: return _reject("INVALID_REPLAY_ENDPOINTS")
	if recording.get("termination","") not in ["TERMINAL","TIME_BOUND","CANCELLED","MEMORY_BOUND"]: return _reject("INVALID_REPLAY_TERMINATION")
	if not recording.get("frames") is Array or recording.frames.is_empty() or recording.frames.size()>MAX_FRAMES: return _reject("INVALID_FRAME_COUNT")
	if not recording.get("static") is Dictionary or not recording.get("request") is Dictionary or not recording.get("source_sha256") is Dictionary: return _reject("INVALID_REPLAY_HEADER")
	for field: String in ["arena_bounds","catalog","scenario","match_config","match_setup","match_settings"]:
		if recording.static.has(field) and not recording.static[field] is Dictionary: return _reject("INVALID_REPLAY_STATIC")
	if recording.static.has("terrain") and not _dictionary_rows(recording.static.terrain,2000): return _reject("INVALID_REPLAY_TERRAIN")
	for terrain: Dictionary in recording.static.get("terrain",[]):
		if typeof(terrain.get("position")) not in [TYPE_VECTOR2,TYPE_VECTOR2I] or not Vector2(terrain.position).is_finite(): return _reject("INVALID_REPLAY_TERRAIN")
		if terrain.has("radius") and (typeof(terrain.radius) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(terrain.radius)) or float(terrain.radius)<0 or float(terrain.radius)>10000): return _reject("INVALID_REPLAY_TERRAIN")
	for field: String in ["match_config","match_setup"]:
		var setup: Dictionary=recording.static.get(field,{})
		if setup.has("sides") and not _dictionary_rows(setup.sides,4): return _reject("INVALID_REPLAY_STATIC")
		for side: Dictionary in setup.get("sides",[]):
			if typeof(side.get("home")) not in [TYPE_VECTOR2I,TYPE_VECTOR2] or not Vector2(side.home).is_finite(): return _reject("INVALID_REPLAY_STATIC")
		if setup.has("bounds") and typeof(setup.bounds) not in [TYPE_RECT2I,TYPE_RECT2]: return _reject("INVALID_REPLAY_STATIC")
		if setup.has("bounds") and (Rect2(setup.bounds).size.x<=0 or Rect2(setup.bounds).size.y<=0 or Rect2(setup.bounds).size.x>100000 or Rect2(setup.bounds).size.y>100000): return _reject("INVALID_REPLAY_STATIC")
	var arena_bounds: Dictionary=recording.static.get("arena_bounds",{})
	if not arena_bounds.is_empty():
		for field: String in ["min_x","min_y","max_x","max_y"]:
			if typeof(arena_bounds.get(field)) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(arena_bounds[field])) or absf(float(arena_bounds[field]))>100000: return _reject("INVALID_REPLAY_STATIC")
		if arena_bounds.max_x<=arena_bounds.min_x or arena_bounds.max_y<=arena_bounds.min_y: return _reject("INVALID_REPLAY_STATIC")
	if recording.source_sha256.is_empty() or recording.source_sha256.size()>2048: return _reject("INVALID_SOURCE_MANIFEST")
	for path: Variant in recording.source_sha256:
		if not path is String or path.length()>512 or not recording.source_sha256[path] is String or str(recording.source_sha256[path]).length()!=64: return _reject("INVALID_SOURCE_MANIFEST")
	var expected_sample := maxi(SAMPLE_TICKS,ceili(float(recording.limit_ticks)/1500.0))
	if int(recording.get("sample_ticks",0))!=expected_sample or int(recording.get("tick_ms",0))!=50: return _reject("INVALID_REPLAY_RATE")
	if int(recording.get("limit_ticks",0))<20 or int(recording.limit_ticks)>MAX_SECONDS*20: return _reject("INVALID_REPLAY_DURATION")
	var previous := -1
	for frame: Variant in recording.frames:
		if cancelled.is_valid() and bool(cancelled.call()): return _reject("REPLAY_IO_CANCELLED")
		if not frame is Dictionary or typeof(frame.get("tick"))!=TYPE_INT or int(frame.tick)<=previous or int(frame.tick)>int(recording.limit_ticks): return _reject("INVALID_FRAME_TIMELINE")
		if not frame.get("payload") is PackedByteArray or frame.payload.is_empty() or frame.payload.size()>MAX_FRAME_BYTES: return _reject("INVALID_FRAME_PAYLOAD")
		var decoded := _decode_frame(frame)
		if decoded.is_empty() or not _safe_value(decoded,0,{"nodes":0}) or int(decoded.get("tick",-1))!=int(frame.tick): return _reject("INVALID_FRAME_PAYLOAD")
		for collection: String in ["warbands","sites","resource_sources","neutral_camps","neutral_loot","bases","combat_feedback_events","field_objectives","field_objective_events"]:
			if decoded.has(collection) and not _dictionary_rows(decoded[collection],2000): return _reject("INVALID_FRAME_COLLECTION")
		for collection: String in ["soldiers","workers","buildings"]:
			var bodies: Variant=decoded.get(collection,[])
			if not bodies is Array or bodies.size()>2000: return _reject("INVALID_FRAME_ACTORS")
			for body: Variant in bodies:
				if not body is Dictionary or not body.get("id") is String or str(body.id).length()>256: return _reject("INVALID_FRAME_ACTORS")
				if not body.get("side") is String: return _reject("INVALID_FRAME_ACTORS")
				if collection in ["soldiers","workers"] and not body.get("unit_type") is String: return _reject("INVALID_FRAME_ACTORS")
				if collection=="buildings" and not body.get("building_type") is String: return _reject("INVALID_FRAME_ACTORS")
				if typeof(body.get("position")) not in [TYPE_VECTOR2I,TYPE_VECTOR2]: return _reject("INVALID_FRAME_ACTORS")
				if not Vector2(body.position).is_finite(): return _reject("INVALID_FRAME_ACTORS")
				if typeof(body.get("hp")) not in [TYPE_INT,TYPE_FLOAT]: return _reject("INVALID_FRAME_ACTORS")
				for field: String in ["hp","max_hp","damage","armor","radius","attack_range","mana","max_mana","speed"]:
					if body.has(field) and (typeof(body[field]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(body[field]))): return _reject("INVALID_FRAME_ACTORS")
				for field: String in ["status_effects","last_skill_targets"]:
					if body.has(field) and not _dictionary_rows(body[field],256): return _reject("INVALID_FRAME_ACTORS")
				for field: String in ["source_buffs","combat_statuses"]:
					if body.has(field) and not _dictionary_values(body[field],256): return _reject("INVALID_FRAME_ACTORS")
		var heroes: Variant=decoded.get("heroes",{})
		if not heroes is Dictionary or not heroes.get("officers",[]) is Array: return _reject("INVALID_FRAME_HEROES")
		for officer: Variant in heroes.get("officers",[]):
			if not officer is Dictionary or not officer.get("id") is String or not officer.get("skills",[]) is Array: return _reject("INVALID_FRAME_HEROES")
			if not _dictionary_rows(officer.get("skills",[]),256): return _reject("INVALID_FRAME_HEROES")
			for field: String in ["item_effects","source_buffs"]:
				if officer.has(field) and not _dictionary_values(officer[field],256): return _reject("INVALID_FRAME_HEROES")
		var statistics: Variant=decoded.get("hero_statistics",{})
		if decoded.has("match_scores") and not MatchScores.validate_snapshot(decoded.match_scores,int(frame.tick)): return _reject("INVALID_FRAME_MATCH_SCORES")
		if not statistics is Dictionary or not statistics.get("heroes",[]) is Array: return _reject("INVALID_FRAME_STATISTICS")
		for hero: Variant in statistics.get("heroes",[]):
			if not hero is Dictionary: return _reject("INVALID_FRAME_STATISTICS")
			for field: String in ["hero_id","side","archetype","name"]:
				if not hero.get(field) is String: return _reject("INVALID_FRAME_STATISTICS")
			for field: String in ["level","total_damage","basic_damage","learned_skill_damage","unit_kills","hero_kills","deaths","assists","self_healing","ally_healing","damage_taken","control_ticks","innate_damage","item_damage","dot_damage","building_damage","neutral_kills","building_kills","healing_received","hard_control_ticks","weak_control_ticks"]:
				if typeof(hero.get(field)) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(hero[field])) or float(hero[field])<0: return _reject("INVALID_FRAME_STATISTICS")
			if typeof(hero.get("alive"))!=TYPE_BOOL or not hero.get("skills") is Dictionary: return _reject("INVALID_FRAME_STATISTICS")
			if hero.skills.size()>256: return _reject("INVALID_FRAME_STATISTICS")
			for skill_id: Variant in hero.skills:
				var bucket: Variant=hero.skills[skill_id]
				if not skill_id is String or not bucket is Dictionary: return _reject("INVALID_FRAME_STATISTICS")
				for field: String in ["casts","damage","dot_damage","healing","control_ticks"]:
					if typeof(bucket.get(field)) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(bucket[field])) or float(bucket[field])<0: return _reject("INVALID_FRAME_STATISTICS")
		previous = int(frame.tick)
	if int(recording.frames[0].tick)!=0 or previous!=int(recording.get("last_tick",-1)): return _reject("INVALID_FRAME_ENDPOINTS")
	if var_to_bytes(recording).size()>MAX_BYTES: return _reject("REPLAY_MEMORY_LIMIT")
	var local: bool = recording.source_sha256==source_hashes()
	if require_local_source and not local: return _reject("FOREIGN_SOURCE_REPLAY")
	return {"accepted":true,"error":"","local_source":local,"warning":"" if local else "源码版本不同：仅按历史快照查阅，不重新计算、不继续游戏。"}

static func _dictionary_rows(value: Variant, cap: int) -> bool:
	if not value is Array or value.size()>cap: return false
	for row: Variant in value:
		if not row is Dictionary: return false
	return true

static func _dictionary_values(value: Variant, cap: int) -> bool:
	if not value is Dictionary or value.size()>cap: return false
	for key: Variant in value:
		if not value[key] is Dictionary: return false
	return true

static func _decode_frame(frame: Dictionary) -> Dictionary:
	var payload: Variant=frame.get("payload")
	if not payload is PackedByteArray or payload.is_empty() or payload.size()>MAX_FRAME_BYTES: return {}
	var raw: PackedByteArray=payload.decompress_dynamic(MAX_FRAME_BYTES,FileAccess.COMPRESSION_GZIP)
	if raw.is_empty(): return {}
	var decoded: Variant=bytes_to_var(raw)
	return decoded if decoded is Dictionary else {}

static func _safe_value(value: Variant, depth: int, budget: Dictionary) -> bool:
	budget.nodes+=1
	if depth>32 or int(budget.nodes)>2500000: return false
	match typeof(value):
		TYPE_OBJECT,TYPE_CALLABLE,TYPE_SIGNAL,TYPE_RID: return false
		# Internal route_best_distance legitimately uses INF as an unreachable
		# sentinel. Rendered positions/attributes are separately finite-checked.
		TYPE_FLOAT: return not is_nan(value)
		TYPE_VECTOR2: return value.is_finite()
		TYPE_RECT2: return value.position.is_finite() and value.size.is_finite()
		TYPE_STRING,TYPE_STRING_NAME: return str(value).length()<=1048576
		TYPE_ARRAY:
			if value.size()>20000: return false
			for item: Variant in value:
				if not _safe_value(item,depth+1,budget): return false
		TYPE_DICTIONARY:
			if value.size()>20000: return false
			for key: Variant in value:
				if typeof(key) not in [TYPE_STRING,TYPE_INT,TYPE_STRING_NAME,TYPE_VECTOR2I]: return false
				if not _safe_value(key,depth+1,budget) or not _safe_value(value[key],depth+1,budget): return false
	return true

static func save_file(recording: Dictionary, path: String, cancelled: Callable = Callable()) -> Dictionary:
	if FileAccess.file_exists(path): return _reject("REPLAY_ALREADY_EXISTS")
	var valid := validate(recording,false,cancelled)
	if not valid.accepted: return valid
	var raw := var_to_bytes(recording)
	var packed := raw.compress(FileAccess.COMPRESSION_GZIP)
	if cancelled.is_valid() and bool(cancelled.call()): return _reject("REPLAY_IO_CANCELLED")
	if packed.size()>MAX_FILE_BYTES: return _reject("REPLAY_FILE_LIMIT")
	if FileAccess.file_exists(path): return _reject("REPLAY_ALREADY_EXISTS")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return _reject("REPLAY_WRITE_FAILED")
	file.store_buffer(MAGIC.to_utf8_buffer())
	file.store_buffer(packed)
	file.close()
	return {"accepted":true,"error":"","path":path,"bytes":packed.size()}

static func load_file(path: String, require_local_source: bool = false, cancelled: Callable = Callable()) -> Dictionary:
	if cancelled.is_valid() and bool(cancelled.call()): return _reject("REPLAY_IO_CANCELLED")
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return _reject("REPLAY_READ_FAILED")
	if file.get_length()>MAX_FILE_BYTES+MAGIC.length() or file.get_length()<=MAGIC.length(): return _reject("REPLAY_FILE_LIMIT")
	if file.get_buffer(MAGIC.length()).get_string_from_utf8()!=MAGIC: return _reject("INVALID_REPLAY_MAGIC")
	var raw := file.get_buffer(file.get_length()-file.get_position()).decompress_dynamic(MAX_BYTES,FileAccess.COMPRESSION_GZIP)
	file.close()
	if raw.is_empty(): return _reject("INVALID_REPLAY_COMPRESSION")
	# bytes_to_var() never decodes objects; _with_objects is deliberately absent.
	var result: Variant = bytes_to_var(raw)
	var valid := validate(result,require_local_source,cancelled)
	if not valid.accepted: return valid
	valid["replay"] = result
	return valid

static func source_hashes() -> Dictionary:
	var result := {}
	_hash_tree("res://src",result)
	result["assets/data/hero-rework-r7-wave1.json"]=FileAccess.get_sha256("res://assets/data/hero-rework-r7-wave1.json")
	return result

static func _hash_tree(root: String, result: Dictionary) -> void:
	var directory := DirAccess.open(root)
	if directory == null: return
	var names := directory.get_directories()
	names.sort()
	for item: String in names: _hash_tree(root+"/"+item,result)
	var files := directory.get_files()
	files.sort()
	for item: String in files:
		if item.ends_with(".gd"): result[(root+"/"+item).trim_prefix("res://")] = FileAccess.get_sha256(root+"/"+item)

static func _reject(error: String) -> Dictionary:
	return {"accepted":false,"error":error}
