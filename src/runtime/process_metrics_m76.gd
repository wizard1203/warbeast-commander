extends RefCounted
## Presentation-side instrumentation, never match authority or replay state.
## Call poll every displayed frame; it launches at most one non-blocking ps per
## second and polls that tiny pipe at most 10 Hz. Explicit stop is mandatory on
## owner exit. Unsupported platforms honestly retain FPS with CPU/RSS unknown.
const Backend = preload("res://src/runtime/process_metrics_backend_m76.gd")
const SAMPLE_USEC := 1000000
const PIPE_POLL_USEC := 100000
const TIMEOUT_USEC := 1000000
const STALE_USEC := 3500000
const MAX_OUTPUT_BYTES := 4096
var _backend: RefCounted
var _supported := false
var _stopped := false
var _handle := {}
var _buffer := PackedByteArray()
var _launched_usec := -1
var _next_poll_usec := -1
var _last_launch_usec := -1
var _last_cpu_usec := -1
var _last_cpu_seconds := -1.0
var _last_success_usec := -1
var _frame_usec := -1
var _drawn_frames := 0
var _fps := -1.0
var _cpu_percent := -1.0
var _rss_mib := -1.0
var _interval_ms := 0.0
var _status := "WARMUP"
var _launch_count := 0

func _init(backend: RefCounted = null) -> void:
	_backend = backend if backend != null else Backend.new()
	_supported = _backend.is_supported()
	if not _supported: _status = "UNAVAILABLE"

func poll(now_usec: int, drawn_frames: int) -> void:
	if _stopped: return
	if _frame_usec < 0 or now_usec < _frame_usec or drawn_frames < _drawn_frames:
		_frame_usec = now_usec
		_drawn_frames = drawn_frames
		_fps = -1.0
	elif now_usec - _frame_usec >= SAMPLE_USEC:
		_fps = float(drawn_frames-_drawn_frames)*1000000.0/float(now_usec-_frame_usec)
		_frame_usec = now_usec
		_drawn_frames = drawn_frames
	if not _supported: return
	if not _handle.is_empty():
		if now_usec - _launched_usec >= TIMEOUT_USEC:
			_backend.finish(_handle,true)
			_handle.clear()
			_buffer.clear()
			_mark_unavailable("TIMED_OUT")
			return
		if now_usec < _next_poll_usec: return
		_next_poll_usec = now_usec + PIPE_POLL_USEC
		_buffer.append_array(_backend.read(_handle,MAX_OUTPUT_BYTES+1-_buffer.size()))
		if _buffer.size() > MAX_OUTPUT_BYTES:
			_backend.finish(_handle,true)
			_handle.clear()
			_mark_unavailable("INVALID_SAMPLE")
			return
		if _backend.running(_handle): return
		# Non-blocking final drain after the child has exited captures bytes that
		# arrived between the preceding read and the running() observation.
		_buffer.append_array(_backend.read(_handle,MAX_OUTPUT_BYTES+1-_buffer.size()))
		var code: int = _backend.exit_code(_handle)
		_backend.finish(_handle,false)
		_handle.clear()
		var sample := parse_ps_sample(_buffer.get_string_from_utf8()) if code == 0 and _buffer.size() <= MAX_OUTPUT_BYTES else {}
		_buffer.clear()
		if sample.is_empty():
			_mark_unavailable("INVALID_SAMPLE" if code == 0 else "SAMPLE_FAILED")
			return
		_accept(sample,now_usec)
		return
	if _last_launch_usec >= 0 and now_usec-_last_launch_usec < SAMPLE_USEC: return
	_handle = _backend.begin()
	_last_launch_usec = now_usec
	_launch_count += 1
	_launched_usec = now_usec
	_next_poll_usec = now_usec + PIPE_POLL_USEC
	_buffer.clear()
	if _handle.is_empty(): _mark_unavailable("SAMPLE_FAILED")

func _accept(sample: Dictionary, now_usec: int) -> void:
	var seconds := float(sample.cpu_seconds)
	_cpu_percent = -1.0
	_interval_ms = 0.0
	if _last_cpu_usec >= 0 and now_usec > _last_cpu_usec and seconds >= _last_cpu_seconds:
		_interval_ms = float(now_usec-_last_cpu_usec)/1000.0
		_cpu_percent = (seconds-_last_cpu_seconds)*100000000.0/float(now_usec-_last_cpu_usec)
	_last_cpu_usec = now_usec
	_last_cpu_seconds = seconds
	_rss_mib = float(sample.rss_kib)/1024.0
	_last_success_usec = now_usec
	_status = "READY" if _cpu_percent >= 0 else "WARMUP"

func _mark_unavailable(reason: String) -> void:
	_status = reason
	_cpu_percent = -1.0
	_rss_mib = -1.0
	_last_cpu_usec = -1
	_last_cpu_seconds = -1.0
	_interval_ms = 0.0

func snapshot(now_usec: int) -> Dictionary:
	var fresh := _last_success_usec >= 0 and now_usec >= _last_success_usec and now_usec-_last_success_usec <= STALE_USEC and not _stopped
	return {"schema":"m76.process-metrics/v1","fps":_fps,"fps_available":_fps>=0 and not _stopped,"cpu_percent":_cpu_percent if fresh else -1.0,"cpu_available":fresh and _cpu_percent>=0,"rss_mib":_rss_mib if fresh else -1.0,"rss_available":fresh and _rss_mib>=0,"sample_age_ms":float(now_usec-_last_success_usec)/1000.0 if _last_success_usec>=0 else -1.0,"sample_interval_ms":_interval_ms,"status":"STOPPED" if _stopped else "STALE" if _last_success_usec>=0 and not fresh else _status,"pending":not _handle.is_empty(),"sample_launches":_launch_count,"cpu_semantics":"process_user_system_delta_single_core_100","memory_semantics":"resident_set_size_mib","backend":"macos_ps_interval" if _supported else "unavailable"}

func stop() -> void:
	if _stopped: return
	_stopped = true
	if not _handle.is_empty():
		_backend.finish(_handle,true)
		_handle.clear()
	_buffer.clear()

static func parse_ps_sample(text: String) -> Dictionary:
	var fields := text.strip_edges().split(" ",false)
	var clean: Array[String] = []
	for field: String in fields:
		for entry: String in field.split("\t",false): clean.append(entry)
	if clean.size() != 2 or not clean[1].is_valid_int() or int(clean[1]) < 0: return {}
	var time := clean[0]
	var days := 0
	if "-" in time:
		var day_parts := time.split("-",false)
		if day_parts.size()!=2 or not day_parts[0].is_valid_int() or int(day_parts[0])<0: return {}
		days = int(day_parts[0]); time = day_parts[1]
	var parts := time.split(":",false)
	if parts.size()<2 or parts.size()>3: return {}
	for index: int in range(parts.size()-1):
		if not parts[index].is_valid_int() or int(parts[index])<0: return {}
	if not parts[-1].is_valid_float(): return {}
	var seconds := float(parts[-1])
	if not is_finite(seconds) or seconds<0 or seconds>=60: return {}
	var minutes := int(parts[-2])
	if parts.size()==3 and minutes>=60: return {}
	var hours := int(parts[0]) if parts.size()==3 else 0
	return {"cpu_seconds":float(days*86400+hours*3600+minutes*60)+seconds,"rss_kib":int(clean[1])}
