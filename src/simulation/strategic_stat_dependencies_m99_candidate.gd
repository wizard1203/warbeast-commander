extends RefCounted
## Isolated M99 candidate: only the private captured-record layout differs.
## No production consumer loads this script. Current authoritative dependencies
## are checked at the same requests and with the exact M95 comparison rules.
const EMPTY := {}
const EMPTY_ARRAY := []
const IDENTITY_FIELDS := ["unit_type","side","hero_archetype","neutral_archetype","life_generation"]
const RESULT_FIELDS := ["hp_regen_per_second","base_damage","damage","armor","speed_exact","speed","move_speed_percent","attack_speed_percent","magic_resist_percent","control_resist_percent","healing_percent","buff_drain_percent","attack_range","attack_cooldown_ticks","heal","heal_range","heal_max_cooldown_ticks","max_hp","max_mana"]
const NEUTRAL_RESULT_FIELDS := ["max_hp","damage","attack_range","attack_cooldown_ticks","armor","speed_exact","speed"]
const NEUTRAL_BASE_FIELDS := ["max_hp","damage","attack_range","attack_cooldown_ticks","armor","speed"]
const AURA_FIELDS := ["damage","armor","speed","move_speed_percent"]
const INNATE_FIELDS := ["attack_speed_percent","control_resist_percent"]
const ITEM_FIELDS := ["damage_bonus","armor_bonus","speed_bonus","range_bonus","max_hp_bonus","attack_speed_percent","move_speed_percent","magic_resist_percent","max_mana_bonus","hp_regen_per_second","mana_regen_per_second","skill_damage_percent","healing_percent","control_resist_percent"]

class StatRecord:
	extends RefCounted
	var body: Dictionary
	var tick: int
	var validation_scope: int
	var expires: int = 9223372036854775807
	var alive: bool
	var neutral: bool
	var identity: Dictionary
	var results: Dictionary
	var statuses: Array = []
	var neutral_base: Dictionary
	var guard_until: int
	var guard_amount: float
	var faction: String
	var levels: Dictionary
	var guard_speed: float
	var aura: Dictionary
	var aura_empty: bool
	var innate_attack_speed: float
	var innate_control_resist: float
	var base_identity: Variant
	var base: Variant
	var base_keys: Array
	var buffs: Dictionary
	var buffs_empty: bool
	var buff_keys: Array
	var source_alive: Dictionary
	var hero: bool
	var hero_level: int
	var hero_archetype: String
	var skills: Variant
	var equipment: Variant
	var hero_max_mana: int
	var items: Dictionary

var _records: Dictionary = {}
var _requests := 0
var _hits := 0
var _recomputes := 0
var _trusted_hits := 0
var _boundary_checks := 0

func reset() -> void:
	_records.clear(); _requests=0; _hits=0; _recomputes=0; _trusted_hits=0; _boundary_checks=0

func diagnostics() -> Dictionary:
	return {"requests":_requests,"hits":_hits,"recomputes":_recomputes,"records":_records.size(),"trusted_hits":_trusted_hits,"boundary_checks":_boundary_checks}

func reusable(unit: Dictionary, hero: Dictionary, levels: Dictionary, aura: Dictionary, faction: String, tick: int, bodies: Dictionary, scope: int = 0) -> bool:
	_requests+=1
	var record: StatRecord=_records.get(str(unit.id))
	if record==null or not is_same(record.body,unit) or tick<record.tick or tick>=record.expires: return false
	if record.alive!=(int(unit.hp)>0) or record.neutral!=bool(unit.get("neutral",false)): return false
	var boundary: bool=scope==0 or record.validation_scope!=scope
	if boundary:
		_boundary_checks+=1
		if not _fields_match(unit,record.identity): return false
		if not _exact_fields_match(unit,record.results): return false
	if record.neutral:
		if boundary and not _fields_match(unit.get("neutral_base_stats",EMPTY),record.neutral_base): return false
		if record.guard_until!=int(unit.get("neutral_guard_until_tick",-1)) or record.guard_amount!=float(unit.get("neutral_guard_armor",0)): return false
	else:
		if boundary and (record.faction!=faction or not _fields_match(levels,record.levels)): return false
		if record.guard_until!=int(unit.get("guard_until_tick",-1)) or record.guard_amount!=float(unit.get("guard_armor_bonus",0)) or record.guard_speed!=float(unit.get("guard_speed_bonus",0)): return false
		if not (aura.is_empty() and record.aura_empty) and not _fields_match(aura,record.aura): return false
		var innate: Dictionary=unit.get("innate_aura",EMPTY)
		if float(innate.get("attack_speed_percent",0))!=record.innate_attack_speed or float(innate.get("control_resist_percent",0))!=record.innate_control_resist: return false
		if boundary:
			var baseline: Variant=unit.get("attribute_base")
			if not (baseline is Dictionary) or not is_same(baseline,record.base_identity) or baseline!=record.base or not _same_key_order(baseline,record.base_keys): return false
		var buffs: Dictionary=unit.get("source_buffs",EMPTY)
		if not (buffs.is_empty() and record.buffs_empty) and (buffs!=record.buffs or not _same_key_order(buffs,record.buff_keys)): return false
		for source_id: String in record.source_alive:
			if bool(record.source_alive[source_id])!=(int(bodies.get(source_id,EMPTY).get("hp",0))>0): return false
		if record.hero!=(not hero.is_empty()): return false
		if record.hero:
			if record.hero_level!=int(hero.level) or record.hero_archetype!=str(hero.archetype): return false
			if hero.get("skill_levels",EMPTY)!=record.skills or hero.get("equipment",EMPTY_ARRAY)!=record.equipment: return false
			if not _items_match(hero.get("item_effects",EMPTY),record.items,tick): return false
			if int(hero.max_mana)!=record.hero_max_mana: return false
	var statuses: Dictionary=unit.get("combat_statuses",EMPTY)
	if not (statuses.is_empty() and record.statuses.is_empty()) and not _statuses_match(statuses,record.statuses,tick): return false
	if scope>0: record.validation_scope=scope
	_hits+=1
	if not boundary: _trusted_hits+=1
	return true

func remember(unit: Dictionary, hero: Dictionary, levels: Dictionary, aura: Dictionary, faction: String, tick: int, bodies: Dictionary, scope: int = 0) -> void:
	_recomputes+=1
	var neutral:=bool(unit.get("neutral",false))
	var record:=StatRecord.new()
	record.body=unit; record.tick=tick; record.validation_scope=scope
	record.alive=int(unit.hp)>0; record.neutral=neutral
	record.identity=_capture(unit,IDENTITY_FIELDS)
	record.results=_capture(unit,NEUTRAL_RESULT_FIELDS if neutral else RESULT_FIELDS)
	var statuses: Dictionary=unit.get("combat_statuses",EMPTY)
	for key: String in statuses:
		var state: Dictionary=statuses[key]
		if str(state.get("kind","")) not in ["SLOW","ARMOR_BREAK"] or int(state.expires_tick)<=tick: continue
		record.statuses.append([key,str(state.kind),float(state.power),int(state.expires_tick)])
		record.expires=mini(record.expires,int(state.expires_tick))
	if neutral:
		record.neutral_base=_capture(unit.get("neutral_base_stats",EMPTY),NEUTRAL_BASE_FIELDS)
		record.guard_until=int(unit.get("neutral_guard_until_tick",-1))
		record.guard_amount=float(unit.get("neutral_guard_armor",0))
	else:
		record.faction=faction
		record.levels=_capture(levels,["ATTACK","ARMOR","SPECIALTY"])
		record.guard_until=int(unit.get("guard_until_tick",-1))
		record.guard_amount=float(unit.get("guard_armor_bonus",0))
		record.guard_speed=float(unit.get("guard_speed_bonus",0))
		record.aura=_capture_defaults(aura,AURA_FIELDS)
		record.aura_empty=aura.is_empty()
		var innate: Dictionary=unit.get("innate_aura",EMPTY)
		record.innate_attack_speed=float(innate.get("attack_speed_percent",0))
		record.innate_control_resist=float(innate.get("control_resist_percent",0))
		record.base_identity=unit.get("attribute_base",EMPTY)
		record.base=record.base_identity.duplicate(true)
		record.base_keys=record.base_identity.keys()
		record.buffs=unit.get("source_buffs",EMPTY).duplicate(true)
		record.buffs_empty=record.buffs.is_empty()
		record.buff_keys=record.buffs.keys()
		record.source_alive={}
		for key: String in record.buffs:
			var buff: Dictionary=record.buffs[key]
			if int(buff.expires_tick)>tick: record.expires=mini(record.expires,int(buff.expires_tick))
			if bool(buff.get("requires_source",false)):
				var source_id:=str(buff.source_id)
				record.source_alive[source_id]=int(bodies.get(source_id,EMPTY).get("hp",0))>0
		record.hero=not hero.is_empty()
		if record.hero:
			record.hero_level=int(hero.level); record.hero_archetype=str(hero.archetype)
			record.skills=hero.get("skill_levels",EMPTY).duplicate(true)
			record.equipment=hero.get("equipment",EMPTY_ARRAY).duplicate()
			record.hero_max_mana=int(hero.max_mana)
			record.items={}
			for key: String in hero.get("item_effects",EMPTY):
				var item: Dictionary=hero.item_effects[key]
				if int(item.expires_tick)<=tick: continue
				var values: Dictionary=_capture_defaults(item,ITEM_FIELDS)
				values["expires_tick"]=int(item.expires_tick)
				record.items[key]=values
				record.expires=mini(record.expires,int(item.expires_tick))
	if record.guard_until>tick: record.expires=mini(record.expires,record.guard_until)
	_records[str(unit.id)]=record

func _capture(source: Dictionary, fields: Array) -> Dictionary:
	var result: Dictionary={}
	for field: String in fields:
		if source.has(field): result[field]=source[field]
	return result

func _capture_defaults(source: Dictionary, fields: Array) -> Dictionary:
	var result: Dictionary={}
	for field: String in fields: result[field]=source.get(field,0)
	return result

func _fields_match(source: Dictionary, expected: Dictionary) -> bool:
	for field: String in expected:
		if source.get(field,0)!=expected[field]: return false
	return true

func _exact_fields_match(source: Dictionary, expected: Dictionary) -> bool:
	for field: String in expected:
		if not source.has(field) or typeof(source[field])!=typeof(expected[field]) or source[field]!=expected[field]: return false
	return true

func _same_key_order(source: Dictionary, expected: Array) -> bool:
	if source.size()!=expected.size(): return false
	var index:=0
	for key: Variant in source:
		if key!=expected[index]: return false
		index+=1
	return true

func _statuses_match(source: Dictionary, expected: Array, tick: int) -> bool:
	var count:=0
	for key: String in source:
		var state: Dictionary=source[key]
		if str(state.get("kind","")) not in ["SLOW","ARMOR_BREAK"] or int(state.expires_tick)<=tick: continue
		if count>=expected.size(): return false
		var old: Array=expected[count]
		if old[0]!=key or old[1]!=str(state.kind) or old[2]!=float(state.power) or old[3]!=int(state.expires_tick): return false
		count+=1
	return count==expected.size()

func _items_match(source: Dictionary, expected: Dictionary, tick: int) -> bool:
	var count:=0
	for key: String in source:
		var item: Dictionary=source[key]
		if int(item.expires_tick)<=tick: continue
		if not expected.has(key) or not _fields_match(item,expected[key]): return false
		count+=1
	return count==expected.size()
