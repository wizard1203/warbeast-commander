extends Node
## Tree-owned file worker lifetime. No scene callback, Combat or drawing enters
## a worker. Views may disappear immediately while cancellation drains safely.
const Replay = preload("res://src/simulation/strategic_battle_replay_m69.gd")
const SERVICE_NAME := "M69ReplayFileService"
const MAX_JOBS := 2
class Cancellation extends RefCounted:
	var _mutex := Mutex.new()
	var _cancelled := false
	func cancel() -> void:
		_mutex.lock(); _cancelled=true; _mutex.unlock()
	func requested() -> bool:
		_mutex.lock(); var result := _cancelled; _mutex.unlock(); return result
var _jobs: Dictionary = {}
var _next_id := 0

static func acquire(tree: SceneTree) -> Node:
	var existing := tree.root.get_node_or_null(SERVICE_NAME)
	if existing!=null: return existing
	var service := new()
	service.name=SERVICE_NAME
	# The Viewport may currently be entering its main scene; defer structural
	# insertion. The returned object can safely queue work before first process.
	tree.root.add_child.call_deferred(service)
	return service

func submit_load(path: String) -> int:
	var cancel := Cancellation.new()
	return _submit(Replay.load_file.bind(path,false,cancel.requested),cancel)

func submit_save(recording: Dictionary, path: String) -> int:
	var cancel := Cancellation.new()
	return _submit(Replay.save_file.bind(recording,path,cancel.requested),cancel)

func _submit(work: Callable, cancel: RefCounted) -> int:
	_poll()
	if _jobs.size()>=MAX_JOBS: return 0
	var thread := Thread.new()
	if thread.start(work)!=OK: return 0
	_next_id+=1
	_jobs[_next_id]={"thread":thread,"cancel":cancel,"done":false,"abandoned":false,"result":{}}
	return _next_id

func _process(_delta: float) -> void:
	_poll()

func _poll() -> void:
	for id: int in _jobs.keys():
		var job: Dictionary=_jobs[id]
		if not bool(job.done) and not job.thread.is_alive():
			var result: Variant=job.thread.wait_to_finish()
			job.result=result if result is Dictionary else {"accepted":false,"error":"REPLAY_IO_FAILED"}
			job.thread=null
			job.done=true
		if bool(job.done) and bool(job.abandoned): _jobs.erase(id)

func take_result(id: int) -> Dictionary:
	_poll()
	if not _jobs.has(id) or not bool(_jobs[id].done): return {}
	var result: Dictionary=_jobs[id].result
	_jobs.erase(id)
	return result

func abandon(id: int) -> void:
	if not _jobs.has(id): return
	_jobs[id].abandoned=true
	_jobs[id].cancel.cancel()
	_poll()

func active_jobs() -> int:
	_poll()
	return _jobs.size()

func _exit_tree() -> void:
	# App shutdown only; ordinary view closure never waits here. Frame-by-frame
	# cooperative checks bound validation cancellation, rather than 600 frames.
	for job: Dictionary in _jobs.values(): job.cancel.cancel()
	for job: Dictionary in _jobs.values():
		if job.thread!=null and job.thread.is_started(): job.thread.wait_to_finish()
	_jobs.clear()
