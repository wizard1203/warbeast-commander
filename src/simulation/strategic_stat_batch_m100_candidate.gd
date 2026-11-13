extends "res://src/simulation/strategic_stat_dependencies_m95.gd"
## Explicit stable-scan experiment. Original records and live checks remain.
## begin/end may surround only a synchronous scan in which boundary inputs
## (identity/output/baseline/technology/faction) cannot change before their turn.
## Death cleanup, buff/source/guard/hero/status changes remain checked live.
const NativeM100 = preload("res://src/simulation/strategic_native_stat_batch_m100.gd")
const MIN_BATCH := 32
var _batch_flags: Dictionary = {}
var _batch_tick := -1
var _batch_scope := -1
var _last_batch_scope := -1
var _batch_technology: Dictionary = {}
var _batch_side_config: Dictionary = {}
var _batch_stats := {"attempts":0,"native_batches":0,"native_boundary_guards":0,"saved_boundary_guards":0,"rejected_boundary_guards":0,"fallback_boundary_guards":0,"invalidations":0,"small_skips":0,"trusted_scope_skips":0}

func begin_batch(ordered: Array, technology: Dictionary, side_config: Dictionary, tick: int, scope: int) -> bool:
	end_batch()
	_batch_stats.attempts+=1
	if ordered.size()<MIN_BATCH:_batch_stats.small_skips+=1;return false
	# Repeating the same trusted scope offers no boundary work to batch.
	# A full original check still runs if a later caller has an unexpected miss.
	if scope>0 and scope==_last_batch_scope:_batch_stats.trusted_scope_skips+=1;return false
	var result: Dictionary=NativeM100.try_boundaries(ordered,_records,technology,side_config,scope)
	if not bool(result.get("accepted",false)):return false
	_batch_flags=result.flags
	_batch_tick=tick;_batch_scope=scope
	_batch_technology=technology;_batch_side_config=side_config
	if scope>0:_last_batch_scope=scope
	_batch_stats.native_batches+=1
	_batch_stats.native_boundary_guards+=int(result.get("boundary_guards",0))
	return true

func end_batch() -> void:
	_batch_flags.clear();_batch_tick=-1;_batch_scope=-1
	_batch_technology={};_batch_side_config={}

func batch_diagnostics() -> Dictionary:
	var result: Dictionary=_batch_stats.duplicate(true)
	result["active_flags"]=_batch_flags.size()
	result["native"]=NativeM100.diagnostics()
	return result

func reset() -> void:
	super.reset();end_batch();_last_batch_scope=-1
	for key: String in _batch_stats:_batch_stats[key]=0

func remember(unit: Dictionary, hero: Dictionary, levels: Dictionary, aura: Dictionary, faction: String, tick: int, bodies: Dictionary, scope: int = 0) -> void:
	var id:=str(unit.id)
	if _batch_flags.has(id):_batch_flags.erase(id);_batch_stats.invalidations+=1
	super.remember(unit,hero,levels,aura,faction,tick,bodies,scope)

func _take_guard(unit: Dictionary, levels: Dictionary, faction: String, tick: int, scope: int) -> int:
	if tick!=_batch_tick or scope!=_batch_scope:return 3
	var id:=str(unit.id)
	var flag:=int(_batch_flags.get(id,3))
	# Every prevalidated body is consumed at most once. A same-ID remember also
	# invalidates it. Any subsequent call uses the original boundary predicates.
	_batch_flags.erase(id)
	if not bool(unit.get("neutral",false)):
		var side:=str(unit.side)
		if not is_same(levels,_batch_technology.get(side,EMPTY)) or faction!=str(_batch_side_config.get(side,EMPTY).get("faction_id","HUMAN")):return 3
	return flag

func reusable(unit: Dictionary, hero: Dictionary, levels: Dictionary, aura: Dictionary, faction: String, tick: int, bodies: Dictionary, scope: int = 0) -> bool:
	if _batch_scope<0:return super.reusable(unit,hero,levels,aura,faction,tick,bodies,scope)
	_requests+=1
	var flag:=_take_guard(unit,levels,faction,tick,scope)
	var record: Dictionary=_records.get(str(unit.id),EMPTY)
	if record.is_empty() or not is_same(record.body,unit) or tick<int(record.tick) or tick>=int(record.expires): return false
	if bool(record.alive)!=(int(unit.hp)>0) or bool(record.neutral)!=bool(unit.get("neutral",false)): return false
	var boundary: bool=scope==0 or int(record.validation_scope)!=scope
	if boundary:
		_boundary_checks+=1
		if flag==0:_batch_stats.rejected_boundary_guards+=1;return false
		if flag==1:_batch_stats.saved_boundary_guards+=1
		else:
			_batch_stats.fallback_boundary_guards+=1
			if not _fields_match(unit,record.identity): return false
			if not _exact_fields_match(unit,record.results): return false
	if record.neutral:
		if boundary and flag!=1 and not _fields_match(unit.get("neutral_base_stats",EMPTY),record.neutral_base): return false
		if record.guard_until!=int(unit.get("neutral_guard_until_tick",-1)) or record.guard_amount!=float(unit.get("neutral_guard_armor",0)): return false
	else:
		if boundary and flag!=1 and (record.faction!=faction or not _fields_match(levels,record.levels)): return false
		if record.guard_until!=int(unit.get("guard_until_tick",-1)) or record.guard_amount!=float(unit.get("guard_armor_bonus",0)) or record.guard_speed!=float(unit.get("guard_speed_bonus",0)): return false
		if not (aura.is_empty() and bool(record.aura_empty)) and not _fields_match(aura,record.aura): return false
		var innate: Dictionary=unit.get("innate_aura",EMPTY)
		if float(innate.get("attack_speed_percent",0))!=float(record.innate_attack_speed) or float(innate.get("control_resist_percent",0))!=float(record.innate_control_resist): return false
		if boundary and flag!=1:
			var baseline: Variant=unit.get("attribute_base")
			if not (baseline is Dictionary) or not is_same(baseline,record.base_identity) or baseline!=record.base or not _same_key_order(baseline,record.base_keys): return false
		var buffs: Dictionary=unit.get("source_buffs",EMPTY)
		if not (buffs.is_empty() and bool(record.buffs_empty)) and (buffs!=record.buffs or not _same_key_order(buffs,record.buff_keys)): return false
		for source_id: String in record.source_alive:
			if bool(record.source_alive[source_id])!=(int(bodies.get(source_id,EMPTY).get("hp",0))>0): return false
		if bool(record.hero)!=(not hero.is_empty()): return false
		if record.hero:
			if record.hero_level!=int(hero.level) or record.hero_archetype!=str(hero.archetype): return false
			if hero.get("skill_levels",EMPTY)!=record.skills or hero.get("equipment",EMPTY_ARRAY)!=record.equipment: return false
			if not _items_match(hero.get("item_effects",EMPTY),record.items,tick): return false
			if int(hero.max_mana)!=int(record.hero_max_mana): return false
	var statuses: Dictionary=unit.get("combat_statuses",EMPTY)
	if not (statuses.is_empty() and record.statuses.is_empty()) and not _statuses_match(statuses,record.statuses,tick): return false
	if scope>0: record.validation_scope=scope
	_hits+=1
	if not boundary: _trusted_hits+=1
	return true
