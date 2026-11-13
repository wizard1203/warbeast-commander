extends RefCounted
## Wave-one paid delivery authority. Combat alone validates commands, pays MP,
## starts cooldowns and records casts. A target's r7_statuses is the ONLY DoT
## ledger: removing that record (including through ItemRules) removes its future.
const VERSION := "r7-wave1-delivery-v1"
const DamageRules = preload("res://src/simulation/strategic_damage_rules.gd")
const Geometry = preload("res://src/simulation/strategic_hero_skill_geometry.gd")
const R7Catalog = preload("res://src/simulation/strategic_hero_rework_r7_catalog.gd")
const HANDLERS := ["cinder_q", "cinder_w", "cinder_r", "myc_q", "myc_w", "myc_r"]

var _pending: Array[Dictionary] = []
var _casts: Dictionary = {}
var _targets: Dictionary = {}
var _cinder_last_refund: Dictionary = {}
var _serial := 0
var _tick := -1

func reset() -> void:
	for target: Dictionary in _targets.values(): target.get("r7_statuses", {}).clear()
	_pending.clear()
	_casts.clear()
	_targets.clear()
	_cinder_last_refund.clear()
	_serial = 0
	_tick = -1

func can_cast(unit: Dictionary) -> bool:
	return int(unit.get("hp", 0)) > 0 and not is_busy(str(unit.get("id", "")))

func is_busy(unit_id: String) -> bool:
	for event: Dictionary in _pending:
		if str(event.source_id) == unit_id and str(event.handler) == "cinder_w": return true
	return false

func cast(combat, unit: Dictionary, hero: Dictionary, skill: Dictionary, position: Vector2i, targets: Array[Dictionary]) -> void:
	var handler := str(skill.get("r7_handler", ""))
	assert(handler in HANDLERS, "Unknown authoritative R7 handler")
	_serial += 1
	_tick = int(combat._tick)
	var cast_id := "r7:%d:%d:%s" % [_tick, _serial, str(unit.id)]
	var source := _source_snapshot(unit)
	var level := int(hero.get("level", 1))
	var innate: Dictionary = R7Catalog.innate_profile(str(unit.get("hero_archetype", "")), level)
	var record := {"cast_id":cast_id, "source":source, "source_id":str(unit.id),
		"source_generation":int(unit.get("life_generation", 1)), "skill":skill.duplicate(true),
		"archetype":str(unit.get("hero_archetype", "")), "refund":roundi(float(innate.get("mana_refund", 0))),
		"p_invalid":false, "p_paid":false, "hit_ids":{}, "actual_hp_damage":false}
	_casts[cast_id] = record
	var target_id := str(targets[0].id) if not targets.is_empty() else ""
	var event := {"cast_id":cast_id, "source_id":str(unit.id), "source_side":str(unit.side),
		"handler":handler, "origin":Vector2i(unit.position), "position":position,
		"created_tick":_tick, "due_tick":_tick + maxi(1, int(skill.get("r7_delay_ticks", 1))),
		"skill_id":str(skill.id), "target_id":target_id,
		"target_generation":int(targets[0].get("life_generation", 1)) if not targets.is_empty() else -1,
		"source_move_revision":int(unit.get("r7_move_revision", 0)),
		"source_direct_intent":str(unit.get("direct_intent", "")),
		"source_direct_destination":Vector2i(unit.get("direct_destination", unit.position))}
	if handler == "myc_q" and not targets.is_empty(): event.position = Vector2i(targets[0].position)
	if handler == "cinder_r":
		if targets.is_empty():
			_casts.erase(cast_id)
			return
		var target: Dictionary = targets[0]
		_ensure_target(target)
		# A same-strength refresh cannot reissue the initial R impact. The old
		# record keeps its cast ownership and remaining finite pool.
		if _existing_blocks(combat, target, record, 1.0, false):
			_casts.erase(cast_id)
			return
		var mark_key := str(skill.id) + ":MARK"
		var old_mark: Dictionary = target.r7_statuses.get(mark_key, {})
		if not old_mark.is_empty() and float(old_mark.potency) >= _potency(record):
			_casts.erase(cast_id)
			return
		var marker := _status_identity(record, "BURN", "MARK")
		marker.merge({"expires_tick":event.due_tick, "potency":_potency(record), "target_generation":event.target_generation}, true)
		target.r7_statuses[mark_key] = marker
		event["marker_key"] = mark_key
		_emit(combat, "STATUS", record, target, {"phase":"START", "r7_phase":"MARK", "status_kind":"BURN", "expires_tick":event.due_tick})
	_pending.append(event)

func advance(combat) -> void:
	_tick = int(combat._tick)
	# Source death invalidates only future passive receipts, never paid delivery.
	for record: Dictionary in _casts.values():
		if not _source_alive(combat, record):
			record.p_invalid = true
			record.hit_ids.clear()
	var future: Array[Dictionary] = []
	for event: Dictionary in _pending:
		var record: Dictionary = _casts.get(str(event.cast_id), {})
		if record.is_empty(): continue
		if event.handler == "cinder_r":
			var marked: Dictionary = combat._soldiers.get(str(event.target_id), {})
			var marker: Dictionary = marked.get("r7_statuses", {}).get(str(event.get("marker_key", "")), {})
			if marker.is_empty() or str(marker.get("cast_id", "")) != str(event.cast_id): continue
		if event.handler == "cinder_w" and _windup_interrupted(combat, event, record):
			_emit(combat, "STATUS", record, {}, {"phase":"END", "r7_phase":"INTERRUPTED"})
			continue
		if _tick < int(event.due_tick):
			future.append(event)
			continue
		_deliver(combat, event, record)
	_pending = future
	var active_casts := {}
	for event: Dictionary in _pending: active_casts[str(event.cast_id)] = true
	for unit_id: String in _sorted_keys(_targets):
		var target: Dictionary = _targets[unit_id]
		if int(target.get("hp", 0)) <= 0:
			target.get("r7_statuses", {}).clear()
			_targets.erase(unit_id)
			continue
		var statuses: Dictionary = target.get("r7_statuses", {})
		for key: String in _sorted_keys(statuses):
			var status: Dictionary = statuses[key]
			if status.get("r7_runtime", "") != VERSION: continue
			if int(status.get("target_generation", -1)) != int(target.get("life_generation", 1)):
				statuses.erase(key)
				continue
			if status.r7_phase == "MARK":
				# Pending owns the mark transition. A dispelled/replaced marker is
				# never recreated from a hidden queue.
				if _tick > int(status.expires_tick): statuses.erase(key)
				else: active_casts[str(status.cast_id)] = true
				continue
			var record: Dictionary = _casts.get(str(status.cast_id), {})
			if record.is_empty():
				statuses.erase(key)
				continue
			if _tick >= int(status.next_tick) or _tick >= int(status.expires_tick): _settle_dot(combat, target, status, record, _tick)
			if int(target.get("hp", 0)) <= 0:
				statuses.clear()
				break
			if _tick >= int(status.expires_tick):
				_complete_cinder(combat, record, status)
				_emit(combat, "STATUS", record, target, {"phase":"END", "r7_phase":"NATURAL_END", "status_kind":status.kind})
				statuses.erase(key)
			else: active_casts[str(status.cast_id)] = true
		if statuses.is_empty(): _targets.erase(unit_id)
	for cast_id: String in _sorted_keys(_casts):
		if not active_casts.has(cast_id): _casts.erase(cast_id)

func _deliver(combat, event: Dictionary, record: Dictionary) -> void:
	var handler := str(event.handler)
	var skill: Dictionary = record.skill
	var targets: Array[Dictionary] = []
	if handler in ["cinder_q", "cinder_r", "myc_q"]:
		var target: Dictionary = combat._soldiers.get(str(event.target_id), {})
		if not _eligible(target, record.source, skill) or int(target.get("life_generation", 1)) != int(event.target_generation): return
		if handler == "myc_q" and (Vector2i(target.position) - Vector2i(event.position)).length_squared() > 24 * 24: return
		if handler == "cinder_r":
			var marker: Dictionary = target.get("r7_statuses", {}).get(str(event.marker_key), {})
			if marker.is_empty() or str(marker.cast_id) != str(record.cast_id): return
			target.r7_statuses.erase(str(event.marker_key))
			targets.append(target)
		else: targets.append(target)
	else:
		targets = _geometry_targets(combat, record.source, skill, Vector2i(event.origin), Vector2i(event.position))
	var weights: Array = skill.get("r7_target_weights", [1.0])
	for index: int in range(targets.size()):
		var weight := float(weights[mini(index, weights.size() - 1)])
		var target: Dictionary = targets[index]
		if _existing_blocks(combat, target, record, weight): continue
		var raw := float(skill.get("r7_initial_damage", 0)) * _multiplier(record) * weight
		if raw > 0.0: _deal_direct(combat, record, target, raw)
		_emit(combat, "STATUS", record, target, {"phase":"IMPACT", "r7_phase":"IMPACT", "r7_event":"R7_IMPACT", "status_kind":skill.get("status_kind", "")})
		if int(target.get("hp", 0)) > 0 and not skill.get("r7_segments", []).is_empty(): _attach_dot(combat, record, target, weight)

func _geometry_targets(combat, source: Dictionary, skill: Dictionary, origin: Vector2i, position: Vector2i) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for target: Dictionary in combat._ordered_units():
		if _eligible(target, source, skill): pool.append(target)
	var caster := source.duplicate(true)
	caster["position"] = origin
	return Geometry.targets(caster, skill, position, pool)

func _eligible(target: Dictionary, source: Dictionary, skill: Dictionary) -> bool:
	if target.is_empty() or int(target.get("hp", 0)) <= 0 or target.get("side", "") == source.get("side", ""): return false
	if target.has("building_type") or target.get("unit_type", "") == "worker" or target.get("role", "") == "WORKER": return false
	if bool(target.get("summoned", false)) or bool(target.get("is_summon", false)) or "SUMMON" in target.get("tags", []): return false
	return target.get("movement_layer", "GROUND") in skill.get("target_layers", ["GROUND", "AIR"])

func _windup_interrupted(combat, event: Dictionary, record: Dictionary) -> bool:
	if not _source_alive(combat, record): return true
	var actual: Dictionary = combat._soldiers[str(record.source_id)]
	# Successful explicit MOVE commands are events, including an identical
	# destination or MOVE followed by STOP/ATTACK before the next logical tick.
	if int(actual.get("r7_move_revision", 0)) != int(event.get("source_move_revision", 0)): return true
	if str(actual.get("direct_intent", "")) == "MOVE":
		if str(event.source_direct_intent) != "MOVE" or Vector2i(actual.get("direct_destination", actual.position)) != Vector2i(event.source_direct_destination): return true
	return int(actual.get("stun_until_tick", -1)) > _tick or Vector2i(actual.position) != Vector2i(event.origin)

func _ensure_target(target: Dictionary) -> void:
	if not target.has("r7_statuses"): target["r7_statuses"] = {}
	_targets[str(target.id)] = target

func _existing_blocks(combat, target: Dictionary, record: Dictionary, weight: float = 1.0, replace_stronger: bool = true) -> bool:
	var skill: Dictionary = record.skill
	if skill.get("r7_segments", []).is_empty(): return false
	var old: Dictionary = target.get("r7_statuses", {}).get(str(skill.id), {})
	if old.is_empty(): return false
	if int(old.expires_tick) <= _tick:
		# Pending deliveries advance before the status loop. Settle an old
		# record ending on this very tick before any overwrite can discard its
		# fractional terminal interval or natural-completion receipt.
		var completed_cast: Dictionary = _casts.get(str(old.cast_id), {})
		if not completed_cast.is_empty():
			_settle_dot(combat, target, old, completed_cast, _tick)
			if int(target.get("hp", 0)) > 0: _complete_cinder(combat, completed_cast, old)
			_emit(combat, "STATUS", completed_cast, target, {"phase":"END", "r7_phase":"NATURAL_END", "status_kind":old.kind})
		target.r7_statuses.erase(str(skill.id))
		return int(target.get("hp", 0)) <= 0
	var potency := _potency(record) * weight
	if potency + 0.000001 < float(old.potency): return true
	# A stronger pending mark must not erase the old active tail before its
	# actual landing: the new marker can still be cleansed in transit.
	if not replace_stronger and potency > float(old.potency) + 0.000001: return false
	var old_cast: Dictionary = _casts.get(str(old.cast_id), {})
	if not old_cast.is_empty(): _settle_dot(combat, target, old, old_cast, _tick, potency > float(old.potency) + 0.000001)
	if int(target.get("hp", 0)) <= 0: return true
	if is_equal_approx(potency, float(old.potency)):
		# Preserve spent prefix AND remaining pool. Only stretch the remaining
		# original timeline; never reset progress or reissue initial damage.
		var refresh_duration := _duration_factors(record, target)
		old.expires_tick = maxi(int(old.expires_tick), _tick + int(refresh_duration.effective_ticks))
		old.progress_rate = maxf(0.0, float(old.budget_duration_ticks) - float(old.progress_ticks)) / maxf(1.0, float(int(old.expires_tick) - _tick))
		old.last_settle_tick = _tick
		old.next_tick = mini(_tick + 20, int(old.expires_tick))
		old["last_refresh_tick"] = _tick
		old["last_refresh_duration"] = refresh_duration
		return true
	if not old_cast.is_empty(): _emit(combat, "STATUS", old_cast, target, {"phase":"END", "r7_phase":"REPLACED", "status_kind":old.kind})
	target.r7_statuses.erase(str(skill.id))
	return false

func _attach_dot(combat, record: Dictionary, target: Dictionary, weight: float) -> void:
	_ensure_target(target)
	var skill: Dictionary = record.skill
	var timing := _duration_factors(record, target)
	var base_duration := int(timing.base_ticks)
	var effective_duration := int(timing.effective_ticks)
	if base_duration <= 0 or effective_duration <= 0: return
	var segments: Array[Dictionary] = []
	for segment: Dictionary in skill.get("r7_segments", []):
		segments.append({"start_tick":int(segment.start_tick), "end_tick":int(segment.end_tick), "total":float(segment.total) * _multiplier(record) * weight})
	var status := _status_identity(record, str(skill.get("status_kind", "BURN")), "ATTACHED")
	status.merge({"expires_tick":_tick + effective_duration, "next_tick":_tick + mini(20, effective_duration),
		"last_settle_tick":_tick, "progress_ticks":0.0, "progress_rate":float(base_duration) / float(effective_duration),
		"budget_duration_ticks":base_duration, "duration":timing, "segments":segments, "potency":_potency(record) * weight,
		"mitigation_carry":0.0, "actual_hp_damage":false,
		"target_generation":int(target.get("life_generation", 1))}, true)
	target.r7_statuses[str(skill.id)] = status
	_emit(combat, "STATUS", record, target, {"phase":"START", "r7_phase":"ATTACHED", "r7_event":"R7_STATUS", "status_kind":status.kind, "expires_tick":status.expires_tick})

func _settle_dot(combat, target: Dictionary, status: Dictionary, record: Dictionary, tick: int, finalize: bool = false) -> void:
	var end_tick := mini(tick, int(status.expires_tick))
	var elapsed := maxi(0, end_tick - int(status.last_settle_tick))
	if elapsed <= 0 or int(target.get("hp", 0)) <= 0: return
	var before := float(status.progress_ticks)
	var after := minf(float(status.budget_duration_ticks), before + float(elapsed) * float(status.progress_rate))
	if end_tick == int(status.expires_tick): after = float(status.budget_duration_ticks)
	var raw := 0.0
	for segment: Dictionary in status.segments:
		var overlap := maxf(0.0, minf(after, float(segment.end_tick)) - maxf(before, float(segment.start_tick)))
		raw += float(segment.total) * overlap / maxf(1.0, float(int(segment.end_tick) - int(segment.start_tick)))
	var credit := float(status.mitigation_carry) + DamageRules.mitigate(raw, str(record.skill.get("attack_type", "ARCANE")), target)
	var whole := roundi(credit) if end_tick == int(status.expires_tick) or finalize else floori(credit + 0.000000001)
	status.mitigation_carry = credit - float(whole)
	status.progress_ticks = after
	status.last_settle_tick = end_tick
	status.next_tick = mini(end_tick + 20, int(status.expires_tick))
	var amount: int = combat._absorb_damage(whole, target, false)
	if whole > 0 and amount == 0: _emit(combat, "HIT", record, target, {"amount":0, "absorbed":whole, "attack_type":record.skill.get("attack_type", "ARCANE"), "dot":true})
	var actual := mini(int(target.hp), amount)
	if actual > 0:
		status.actual_hp_damage = true
		_apply_hp_damage(combat, record, target, amount, true)

func _deal_direct(combat, record: Dictionary, target: Dictionary, raw: float) -> void:
	var cause := _damage_cause(record, false)
	var amount: int = combat._resolve_damage(raw, str(record.skill.get("attack_type", "ARCANE")), target, record.source, false, cause)
	if amount > 0: _apply_hp_damage(combat, record, target, amount, false)

func _apply_hp_damage(combat, record: Dictionary, target: Dictionary, amount: int, dot: bool) -> void:
	var cause := _damage_cause(record, dot)
	var settled:Dictionary=combat._deal_body_damage_r4(target,record.source,amount,str(record.skill.get("attack_type","ARCANE")),cause)
	var actual:=int(settled.primary)
	if actual > 0:
		record.actual_hp_damage = true
		_register_myc_hit(combat, record, str(target.id))
	if not bool(target.alive): combat._credit_kill(str(record.source_id), str(target.id))

func _damage_cause(record: Dictionary, dot: bool) -> Dictionary:
	return {"id":str(record.skill.id), "category":"SKILL", "dot":dot, "cast_id":record.cast_id,
		"r7_design_id":record.skill.get("r7_design_id", ""), "rank":record.skill.get("level", 1),
		"ultimate":record.skill.get("ultimate", false)}

func _register_myc_hit(combat, record: Dictionary, target_id: String) -> void:
	if record.archetype != "MYCELIAL_CATALYST" or bool(record.p_paid) or bool(record.p_invalid): return
	if not _source_alive(combat, record):
		record.p_invalid = true
		record.hit_ids.clear()
		return
	if record.hit_ids.size() < 3: record.hit_ids[target_id] = true
	if record.hit_ids.size() >= 3: _refund(combat, record)

func _complete_cinder(combat, record: Dictionary, status: Dictionary) -> void:
	if record.archetype != "CINDER_TESTATOR" or bool(record.p_paid) or bool(record.p_invalid) or not bool(status.actual_hp_damage): return
	if not _source_alive(combat, record): return
	var owner_key := str(record.source_id)
	var previous: Dictionary = _cinder_last_refund.get(owner_key, {})
	if int(previous.get("generation", -1)) == int(record.source_generation) and _tick - int(previous.get("tick", -1000000)) < 120: return
	if _refund(combat, record): _cinder_last_refund[owner_key] = {"generation":int(record.source_generation), "tick":_tick}

func _refund(combat, record: Dictionary) -> bool:
	if bool(record.p_paid) or bool(record.p_invalid) or not _source_alive(combat, record): return false
	record.p_paid = true
	var hero: Dictionary = combat._hero_data.get(str(record.source_id), {})
	if hero.is_empty(): return false
	var before := int(hero.get("mana", 0))
	hero.mana = mini(int(hero.get("max_mana", 0)), before + int(record.refund))
	_emit(combat, "STATUS", record, combat._soldiers[str(record.source_id)], {"phase":"PROC", "r7_phase":"MANA_REFUND", "status_kind":"MANA", "amount":int(hero.mana) - before})
	return true

func _source_alive(combat, record: Dictionary) -> bool:
	var source: Dictionary = combat._soldiers.get(str(record.source_id), {})
	return not source.is_empty() and int(source.get("hp", 0)) > 0 and int(source.get("life_generation", 1)) == int(record.source_generation)

func _source_snapshot(unit: Dictionary) -> Dictionary:
	var result := {}
	for key: String in ["id", "side", "faction_id", "unit_type", "hero_archetype", "position", "body_kind", "role", "attack_type", "life_generation"]:
		if unit.has(key): result[key] = unit[key]
	return result

func _status_identity(record: Dictionary, kind: String, phase: String) -> Dictionary:
	return {"r7_runtime":VERSION, "kind":kind, "status_kind":kind, "phase":phase, "r7_phase":phase,
		"skill_id":str(record.skill.id), "cast_id":str(record.cast_id), "source_id":str(record.source_id),
		"source_side":record.source.get("side", ""), "source_faction":record.source.get("faction_id", ""),
		"r7_handler":record.skill.get("r7_handler", ""), "r7_design_id":record.skill.get("r7_design_id", ""),
		"rank":record.skill.get("level", 1), "ultimate":record.skill.get("ultimate", false)}

func _emit(combat, kind: String, record: Dictionary, target: Dictionary, details: Dictionary) -> void:
	var payload := details.duplicate(true)
	payload.merge({"skill_id":str(record.skill.id), "rank":record.skill.get("level", 1),
		"ultimate":record.skill.get("ultimate", false), "cast_id":str(record.cast_id),
		"r7_handler":record.skill.get("r7_handler", ""), "r7_design_id":record.skill.get("r7_design_id", "")}, true)
	combat._feedback(kind, record.source, target, payload)

func _multiplier(record: Dictionary) -> float:
	return maxf(0.0, float(record.skill.get("r7_damage_multiplier", 1.0)))

func _potency(record: Dictionary) -> float:
	var total := float(record.skill.get("r7_initial_damage", 0))
	for segment: Dictionary in record.skill.get("r7_segments", []): total += float(segment.total)
	return total * _multiplier(record)

func _duration(skill: Dictionary) -> int:
	var result := 0
	for segment: Dictionary in skill.get("r7_segments", []): result = maxi(result, int(segment.end_tick))
	return result

func _duration_factors(record: Dictionary, target: Dictionary) -> Dictionary:
	var base := _duration(record.skill)
	# The source bonus was snapshotted by Combat before paid charges were
	# consumed. Only target vulnerability is sampled now, at real attachment.
	var source_percent := clampi(int(record.skill.get("r7_source_dot_duration_percent", 0)), 0, 40)
	var target_percent := 0
	for entry: Dictionary in target.get("duration_vulnerabilities", {}).values():
		if int(entry.get("expires_tick", -1)) > _tick:
			target_percent = maxi(target_percent, int(entry.get("dot_duration_percent", 0)))
	var combined := clampi(source_percent + target_percent, 0, 40)
	var effective := roundi(float(base) * (1.0 + float(combined) / 100.0))
	return {"base_ticks":base, "effective_ticks":effective, "source_percent":source_percent,
		"target_percent":target_percent, "combined_percent":combined,
		"source_sample":"PAID_CAST", "target_sample":"ATTACHMENT"}

func useful_target(combat, unit: Dictionary, skill: Dictionary) -> Dictionary:
	if not can_cast(unit): return {}
	var candidates: Array[Dictionary] = []
	var reach := int(skill.get("range", 0))
	for target: Dictionary in combat._ordered_units():
		if not _eligible(target, unit, skill) or (Vector2i(target.position) - Vector2i(unit.position)).length_squared() > reach * reach: continue
		var old: Dictionary = target.get("r7_statuses", {}).get(str(skill.id), {})
		if not old.is_empty() and int(old.get("expires_tick", -1)) > int(combat._tick): continue
		candidates.append(target)
	var best: Dictionary = {}
	var best_score := -1.0
	for candidate: Dictionary in candidates:
		var hits: Array[Dictionary] = _geometry_targets(combat, unit, skill, Vector2i(unit.position), Vector2i(candidate.position))
		if hits.is_empty(): continue
		if str(skill.get("r7_handler", "")) == "cinder_w" and hits.size() < 2 and int(candidate.hp) > int(skill.get("r7_initial_damage", 0)): continue
		var score := 0.0
		var weights: Array = skill.get("r7_target_weights", [1.0])
		for index: int in range(hits.size()):
			var target: Dictionary = hits[index]
			var weight := float(weights[mini(index, weights.size() - 1)])
			var potential := float(skill.get("r7_initial_damage", 0)) + float(skill.get("status_total_damage", 0)) * 0.6
			score += minf(float(target.hp), potential * weight) * (1.25 if target.get("unit_type", "") == "hero" else 1.0)
		if score > best_score or (is_equal_approx(score, best_score) and str(candidate.id) < str(best.get("id", "~"))):
			best = candidate
			best_score = score
	return best

func status_snapshot(unit_id: String, tick: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var target: Dictionary = _targets.get(unit_id, {})
	if target.is_empty() or int(target.get("hp", 0)) <= 0: return result
	for key: String in _sorted_keys(target.get("r7_statuses", {})):
		var status: Dictionary = target.r7_statuses[key]
		if status.get("r7_runtime", "") != VERSION or int(status.get("expires_tick", -1)) < tick: continue
		var published := status.duplicate(true)
		published["id"] = key
		published["remaining_ticks"] = maxi(0, int(status.expires_tick) - tick)
		published.erase("segments")
		result.append(published)
	return result

func cleanse(unit_id: String, kinds: Array, combat) -> void:
	var target: Dictionary = _targets.get(unit_id, combat._soldiers.get(unit_id, {}))
	if target.is_empty(): return
	var statuses: Dictionary = target.get("r7_statuses", {})
	for key: String in _sorted_keys(statuses):
		var status: Dictionary = statuses[key]
		if status.get("kind", "") not in kinds: continue
		var record: Dictionary = _casts.get(str(status.get("cast_id", "")), {})
		if not record.is_empty(): _emit(combat, "STATUS", record, target, {"phase":"END", "r7_phase":"CLEANSED", "status_kind":status.kind})
		statuses.erase(key)

func get_snapshot() -> Dictionary:
	# HUD/VFX need finite delivery geometry, not deep copies of skill recipes,
	# passive receipts or status segment pools. get_state remains authoritative.
	var pending: Array[Dictionary] = []
	for event: Dictionary in _pending:
		var published := {}
		for key: String in ["cast_id", "source_id", "source_side", "handler", "origin", "position", "created_tick", "due_tick", "skill_id", "target_id"]:
			if event.has(key): published[key] = event[key]
		var record: Dictionary = _casts.get(str(event.cast_id), {})
		if not record.is_empty():
			published["rank"] = int(record.skill.get("level", 1))
			published["ultimate"] = bool(record.skill.get("ultimate", false))
		pending.append(published)
	return {"version":VERSION, "tick":_tick, "pending":pending,
		"active_cast_count":_casts.size(), "tracked_target_count":_targets.size()}

func get_state() -> Dictionary:
	var states: Array[Dictionary] = []
	for unit_id: String in _sorted_keys(_targets):
		var target: Dictionary = _targets[unit_id]
		for key: String in _sorted_keys(target.get("r7_statuses", {})):
			var status: Dictionary = target.r7_statuses[key].duplicate(true)
			status["target_id"] = unit_id
			status["id"] = key
			states.append(status)
	return {"version":VERSION, "tick":_tick, "pending":_pending.duplicate(true), "statuses":states,
		"casts":_casts.duplicate(true), "serial":_serial, "cinder_refund_ticks":_cinder_last_refund.duplicate(true),
		"active_cast_count":_casts.size(), "tracked_target_count":_targets.size()}

func _sorted_keys(value: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key: Variant in value: keys.append(str(key))
	keys.sort()
	return keys
