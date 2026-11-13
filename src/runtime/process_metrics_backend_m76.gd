extends RefCounted
## macOS development/export-without-sandbox adapter. No shell, user path, PID
## parameter or system-wide query. The only permitted target is this game.
const PS := "/bin/ps"

func is_supported() -> bool:
	return OS.get_name() == "macOS" and not OS.is_sandboxed() and FileAccess.file_exists(PS) and OS.has_method("execute_with_pipe")

func begin() -> Dictionary:
	if not is_supported(): return {}
	return OS.execute_with_pipe(PS,PackedStringArray(["-p",str(OS.get_process_id()),"-o","time=","-o","rss="]),false)

func read(handle: Dictionary, maximum: int) -> PackedByteArray:
	var stream: FileAccess = handle.get("stdio")
	return stream.get_buffer(maximum) if stream != null and stream.is_open() else PackedByteArray()

func running(handle: Dictionary) -> bool:
	return int(handle.get("pid",0)) > 0 and OS.is_process_running(int(handle.pid))

func exit_code(handle: Dictionary) -> int:
	return OS.get_process_exit_code(int(handle.get("pid",0)))

func finish(handle: Dictionary, terminate: bool) -> void:
	# handle is accepted only from execute_with_pipe above. Never target the
	# parent game or any external/user-owned process during timeout/shutdown.
	if terminate and running(handle): OS.kill(int(handle.pid))
	for key: String in ["stdio","stderr"]:
		var stream: FileAccess = handle.get(key)
		if stream != null and stream.is_open(): stream.close()
