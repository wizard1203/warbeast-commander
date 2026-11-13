extends RefCounted
## Monotonic active-time sampling, separate from fixed-step settlement. No
## engine-smoothed/capped delta, wall calendar or economic authority lives here.
var _last_usec := -1
var _active := false

func reset(now_usec: int = -1, active: bool = false) -> void:
	_last_usec = now_usec
	_active = active

func sample(now_usec: int, active: bool) -> float:
	var elapsed := 0.0
	if active and _active and _last_usec>=0 and now_usec>=_last_usec:
		elapsed = float(now_usec-_last_usec)/1_000_000.0
	_last_usec = now_usec
	_active = active
	return elapsed
