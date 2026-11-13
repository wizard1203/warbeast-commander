extends RefCounted
## Observational settlement ledger. It never mutates bodies, rules or RNG.
const SCHEMA := "m69.hero-statistics/v1"
const COMBATANT_SCHEMA := "outposts.r10-combat-statistics/v1"
const TICKS_PER_SECOND := 20
const ASSIST_WINDOW_TICKS := 200
const MAX_UNIT_RECORDS := 320
const TOTAL_FIELDS := ["total_damage","basic_damage","learned_skill_damage","innate_damage","item_damage","other_damage","dot_damage","building_damage","damage_taken","unit_kills","hero_kills","neutral_kills","building_kills","deaths","assists","self_healing","ally_healing","healing_received","control_ticks","hard_control_ticks","weak_control_ticks"]
const BUCKET_FIELDS := ["damage","building_damage","dot_damage","healing","control_ticks","hard_control_ticks","weak_control_ticks","casts"]
var _heroes: Dictionary = {}
var _units: Dictionary = {}
var _track_units := false
var _unit_tracking_truncated := false
var _unit_types_dirty := true
var _unit_types_cache: Array[Dictionary] = []
var _contributors: Dictionary = {}
var _last_hits: Dictionary = {}
var _deaths: Dictionary = {}
var _external_receipts: Dictionary = {}
var _last_control_tick := -1

func reset(track_units: bool = false) -> void:
	_heroes.clear(); _contributors.clear(); _last_hits.clear(); _deaths.clear()
	_external_receipts.clear()
	_last_control_tick = -1
	_units.clear(); _unit_types_cache.clear()
	_track_units = track_units
	_unit_tracking_truncated = false
	_unit_types_dirty = true

func set_unit_tracking(enabled: bool) -> void:
	# Trusted fixture/arena setup only. Normal strategic matches keep their
	# historical hero-only storage; this is not a player-facing command.
	if _track_units == enabled: return
	_track_units = enabled
	_units.clear(); _unit_types_cache.clear()
	_unit_tracking_truncated = false
	_unit_types_dirty = true

func _totals() -> Dictionary:
	var result := {"skills":{}}
	for field: String in TOTAL_FIELDS: result[field] = 0
	return result

func _record(id: String) -> Dictionary:
	if _heroes.has(id): return _heroes[id]
	return _units.get(id,{}) if _track_units else {}

func _changed(id: String) -> void:
	if _units.has(id): _unit_types_dirty = true

func register(body: Dictionary, hero: Dictionary = {}) -> void:
	var kind := str(body.get("unit_type",""))
	var id := str(body.get("id",""))
	if id.is_empty() or kind.is_empty() or body.has("building_type"): return
	if kind == "hero":
		if not _heroes.has(id):
			var created_hero := _totals()
			created_hero.merge({"hero_id":id,"side":str(body.get("side","")),"faction_id":str(body.get("faction_id","")),"archetype":str(body.get("hero_archetype",hero.get("archetype",""))),"name":str(hero.get("name",id)),"level":int(hero.get("level",1)),"alive":int(body.get("hp",0))>0,"life_generation":int(body.get("life_generation",1))})
			_heroes[id] = created_hero
		var hero_record: Dictionary = _heroes[id]
		hero_record.level = int(hero.get("level",hero_record.level))
		if body.has("hp"): hero_record.alive = int(body.hp)>0
		hero_record.life_generation = int(body.get("life_generation",hero_record.life_generation))
		return
	if not _track_units: return
	if not _units.has(id):
		if _units.size()>=MAX_UNIT_RECORDS:
			_unit_tracking_truncated = true
			return
		# Copy only immutable scalar identity, never the physical body's nested
		# stats, route, statuses, position or references. Death/DoT can safely
		# keep this bounded identity after Combat reclaims the actual corpse.
		var created := _totals()
		created.merge({"unit_id":id,"actor_id":id,"row_id":id,"unit_type":kind,"side":str(body.get("side","")),"faction_id":str(body.get("faction_id","")),"name":str(body.get("label",kind)),"body_kind":str(body.get("body_kind","")),"alive":int(body.get("hp",0))>0,"life_generation":int(body.get("life_generation",1))})
		_units[id] = created
		_unit_types_dirty = true
	var record: Dictionary = _units[id]
	var alive := int(body.get("hp",0))>0 if body.has("hp") else bool(record.alive)
	var generation := int(body.get("life_generation",record.life_generation))
	if bool(record.alive)!=alive or int(record.life_generation)!=generation:
		record.alive=alive; record.life_generation=generation
		_unit_types_dirty = true

func _bucket(record: Dictionary, cause: Dictionary) -> Dictionary:
	var id := str(cause.get("id", "BASIC"))
	if not record.skills.has(id): record.skills[id] = {"id":id,"category":cause.get("category","OTHER"),"damage":0,"building_damage":0,"dot_damage":0,"healing":0,"control_ticks":0,"hard_control_ticks":0,"weak_control_ticks":0,"casts":0}
	return record.skills[id]

func cast(source: Dictionary, skill_id: String) -> void:
	register(source)
	var id := str(source.get("id",""))
	var record := _record(id)
	if record.is_empty(): return
	_bucket(record,{"id":skill_id,"category":"SKILL"}).casts += 1
	_changed(id)

func _enemy(a: Dictionary, b: Dictionary) -> bool:
	return not str(a.get("side", "")).is_empty() and not str(b.get("side", "")).is_empty() and a.side != b.side

func _life(body: Dictionary) -> String:
	return "%s:%d" % [body.get("id",""),int(body.get("life_generation",1))]

func _contribute(source: Dictionary, victim: Dictionary, tick: int) -> void:
	var id := str(source.get("id", ""))
	if _record(id).is_empty() or not _enemy(source,victim): return
	var key := _life(victim)
	if not _contributors.has(key): _contributors[key] = {}
	_contributors[key][id] = tick

func damage(source: Dictionary, victim: Dictionary, actual: int, tick: int, cause: Dictionary = {}) -> void:
	if actual <= 0 or not _enemy(source,victim): return
	register(source); register(victim)
	var id := str(source.get("id", ""))
	var building: bool = victim.has("building_type") and victim.building_type != "WORKER_OBSTACLE"
	var record := _record(id)
	if not record.is_empty():
		var bucket := _bucket(record,cause)
		if building:
			record.building_damage += actual; bucket.building_damage += actual
		else:
			record.total_damage += actual; bucket.damage += actual
			var field: String = {"BASIC":"basic_damage","SKILL":"learned_skill_damage","INNATE":"innate_damage","ITEM":"item_damage"}.get(str(cause.get("category","OTHER")),"other_damage")
			record[field] += actual
			if bool(cause.get("dot",false)): record.dot_damage += actual; bucket.dot_damage += actual
		_changed(id)
	var victim_id := str(victim.get("id",""))
	var received := _record(victim_id)
	if not received.is_empty():
		received.damage_taken += actual
		_changed(victim_id)
	_contribute(source,victim,tick)
	_last_hits[_life(victim)] = {"id":id,"side":source.side,"tick":tick}

func external(receipt: Dictionary, source: Dictionary, tick: int) -> bool:
	var id := str(receipt.get("receipt_id",""))
	if id.is_empty() or _external_receipts.has(id): return false
	_external_receipts[id] = true
	var victim: Dictionary = receipt.get("victim",{})
	damage(source,victim,int(receipt.get("actual_damage",0)),tick,receipt.get("stats_cause",{}))
	if int(victim.get("hp",1)) <= 0: death(victim,source,tick)
	return true

func heal(source: Dictionary, target: Dictionary, actual: int, cause: Dictionary = {}) -> void:
	if actual <= 0: return
	register(source); register(target)
	var target_id := str(target.get("id",""))
	var received := _record(target_id)
	if not received.is_empty():
		received.healing_received += actual
		_changed(target_id)
	var id := str(source.get("id",""))
	var record := _record(id)
	if record.is_empty() or source.get("side","") != target.get("side",""): return
	record["self_healing" if id==target_id else "ally_healing"] += actual
	_bucket(record,cause).healing += actual
	_changed(id)

func death(victim: Dictionary, fallback_source: Dictionary, tick: int) -> void:
	if int(victim.get("hp",0)) > 0: return
	register(victim); register(fallback_source)
	var key := _life(victim)
	if _deaths.has(key): return
	_deaths[key] = true
	var victim_id := str(victim.get("id",""))
	var victim_record := _record(victim_id)
	if not victim_record.is_empty():
		victim_record.deaths += 1; victim_record.alive = false
		_changed(victim_id)
	var hit: Dictionary = _last_hits.get(key,{"id":fallback_source.get("id",""),"side":fallback_source.get("side","")})
	if hit.get("side","") == victim.get("side","") or str(hit.get("side","")).is_empty(): return
	var killer := str(hit.get("id",""))
	var neutral: bool = bool(victim.get("neutral",false)) or victim.get("side","") == "NEUTRAL"
	var building: bool = victim.has("building_type") and victim.building_type != "WORKER_OBSTACLE"
	var killer_record := _record(killer)
	if not killer_record.is_empty():
		killer_record["neutral_kills" if neutral else "building_kills" if building else "hero_kills" if victim.get("unit_type","")=="hero" else "unit_kills"] += 1
		_changed(killer)
	if not neutral and not building:
		for id: String in _contributors.get(key,{}):
			var contributor := _record(id)
			if id != killer and not contributor.is_empty() and contributor.side == hit.side and tick-int(_contributors[key][id]) <= ASSIST_WINDOW_TICKS:
				contributor.assists += 1
				_changed(id)
	_contributors.erase(key); _last_hits.erase(key)

func advance_controls(bodies: Dictionary, tick: int) -> void:
	# One accepted 20 Hz logical interval, never a declared duration or tick gap.
	if tick <= _last_control_tick: return
	_last_control_tick = tick
	if tick <= 0: return
	for victim: Dictionary in bodies.values():
		if int(victim.get("hp",0)) <= 0: continue
		var source_id := ""
		var skill_id := ""
		var hard := false
		for prefix: String in ["stun","root"]:
			if int(victim.get(prefix+"_until_tick",-1)) >= tick:
				source_id = str(victim.get(prefix+"_source_id","")); skill_id = str(victim.get(prefix+"_skill_id",prefix.to_upper())); hard = true; break
		if not hard:
			var strongest := 0.0
			for key: String in victim.get("combat_statuses",{}):
				var slow: Dictionary = victim.combat_statuses[key]
				if slow.get("kind","") != "SLOW" or int(slow.get("expires_tick",-1)) < tick or float(slow.get("power",0)) <= strongest: continue
				strongest = float(slow.power)
				source_id = str(slow.get("source_id","")); skill_id = str(slow.get("skill_id","INNATE_QUAKE_PRIEST" if key=="INNATE_QUAKE_SLOW" else "SLOW"))
		var record := _record(source_id)
		if record.is_empty() or record.side == victim.get("side",""): continue
		var bucket := _bucket(record,{"id":skill_id,"category":"INNATE" if skill_id.begins_with("INNATE_") else "SKILL"})
		record.control_ticks += 1; bucket.control_ticks += 1
		var field := "hard_control_ticks" if hard else "weak_control_ticks"
		record[field] += 1; bucket[field] += 1
		_changed(source_id)
		_contribute({"id":source_id,"side":record.side},victim,tick)

func _rebuild_unit_types() -> void:
	if not _unit_types_dirty: return
	var groups := {}
	var ids := _units.keys(); ids.sort()
	for id: String in ids:
		var row: Dictionary = _units[id]
		var group_id := str(row.side)+"::"+str(row.unit_type)
		if not groups.has(group_id):
			var created_group := _totals()
			created_group.merge({"row_id":group_id,"group_id":group_id,"side":row.side,"unit_type":row.unit_type,"faction_id":row.faction_id,"name":row.name,"body_kind":row.body_kind,"count":0,"alive_count":0})
			groups[group_id] = created_group
		var group: Dictionary = groups[group_id]
		group.count += 1
		if bool(row.alive): group.alive_count += 1
		for field: String in TOTAL_FIELDS: group[field] += int(row[field])
		for skill_id: String in row.skills:
			var skill: Dictionary = row.skills[skill_id]
			var bucket := _bucket(group,{"id":skill_id,"category":skill.category})
			for field: String in BUCKET_FIELDS: bucket[field] += int(skill[field])
	_unit_types_cache.clear()
	var keys := groups.keys(); keys.sort()
	for key: String in keys: _unit_types_cache.append(groups[key])
	_unit_types_dirty = false

func snapshot(tick: int) -> Dictionary:
	var rows: Array[Dictionary] = []
	var ids := _heroes.keys(); ids.sort()
	for id: String in ids: rows.append(_heroes[id].duplicate(true))
	var units: Array[Dictionary] = []
	if _track_units:
		var unit_ids := _units.keys(); unit_ids.sort()
		for id: String in unit_ids: units.append(_units[id].duplicate(true))
		_rebuild_unit_types()
	return {"schema":SCHEMA,"combatant_schema":COMBATANT_SCHEMA,"tick":tick,"ticks_per_second":TICKS_PER_SECOND,"assist_window_ticks":ASSIST_WINDOW_TICKS,"heroes":rows,"units":units,"unit_types":_unit_types_cache.duplicate(true),"unit_tracking_enabled":_track_units,"unit_tracking_limit":MAX_UNIT_RECORDS,"unit_tracking_truncated":_unit_tracking_truncated,"control_convention":"Per living enemy / accepted tick; STUN > ROOT > SLOW; no overlap credit; cleanse/death stops; 20 ticks = 1 second.","damage_convention":"Actual HP removed after mitigation/shields, no overkill; building damage separate; DoT is a subset of source-category damage."}
