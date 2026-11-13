extends "res://src/simulation/strategic_stat_dependencies_m95.gd"
## All live predicates, at the original call site. No ahead result or new seam.
const NativeLiveM100 = preload("res://src/simulation/strategic_native_stat_live_m100.gd")
var _bridge: RefCounted = NativeLiveM100.get_backend()
var _native_calls := 0
var _native_fallbacks := 0
var _native_decisions := 0

func live_diagnostics() -> Dictionary:
	return {"calls":_native_calls,"decisions":_native_decisions,"fallbacks":_native_fallbacks,"native":NativeLiveM100.diagnostics()}

func reset() -> void:
	super.reset();_native_calls=0;_native_fallbacks=0;_native_decisions=0

func reusable(unit: Dictionary, hero: Dictionary, levels: Dictionary, aura: Dictionary, faction: String, tick: int, bodies: Dictionary, scope: int = 0) -> bool:
	if _bridge==null:return super.reusable(unit,hero,levels,aura,faction,tick,bodies,scope)
	var record: Dictionary=_records.get(str(unit.id),EMPTY)
	_requests+=1
	_native_calls+=1
	var outcome: int=_bridge.reusable(unit,hero,levels,aura,faction,tick,bodies,scope,record)
	if outcome<0 or outcome>3:
		_requests-=1;_native_fallbacks+=1
		return super.reusable(unit,hero,levels,aura,faction,tick,bodies,scope)
	_native_decisions+=1
	if outcome in [1,2]:_boundary_checks+=1
	if outcome<2:return false
	_hits+=1
	if outcome==3:_trusted_hits+=1
	return true
