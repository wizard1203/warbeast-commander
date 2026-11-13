class_name StrategicAudioFeedback
extends Node
## Local observation/receipt projection only. No simulation reference, command
## dispatch, authority timer, random generator, network or AudioServer volume
## mutation lives here. Original PCM remains the deterministic fallback/UI;
## the bounded local SoundPalette supplies provenance-tracked physical foley.
## A requested move/cast/build is ACCEPT, never a hit or finished construction.

const SAMPLE_RATE := 22050
const SoundPalette = preload("res://src/presentation/strategic_sound_palette.gd")
const MaterialEffects = preload("res://src/presentation/strategic_material_effects.gd")
const FieldObjectives = preload("res://src/presentation/strategic_field_objective_readout.gd")
const MAX_VOICES := 10
const MAX_STARTS_PER_ADVANCE := 4
const MAX_PENDING := 32
const MAX_SEEN := 512
const MAX_CUE_AGE := 0.8
const CUE_PROFILES := {
	"SELECT":[660.0, 840.0, 0.055, 0.0],
	"UI_OPEN":[420.0, 620.0, 0.085, 0.1],
	"UI_CLOSE":[620.0, 420.0, 0.070, 0.1],
	"CANCEL":[350.0, 240.0, 0.095, 0.2],
	"ACCEPT":[560.0, 720.0, 0.065, 0.0],
	"REJECT":[210.0, 145.0, 0.130, 0.5],
	"CAPTURE_START":[390.0, 590.0, 0.160, 0.1],
	"CAPTURE_CONTESTED":[310.0, 330.0, 0.180, 0.6],
	"CAPTURE_COMPLETE":[520.0, 1040.0, 0.270, 0.2],
	"CAPTURE_LOST":[490.0, 190.0, 0.250, 0.5],
	"PRODUCTION":[480.0, 780.0, 0.175, 0.2],
	"BUILD_COMPLETE":[360.0, 720.0, 0.210, 0.3],
	"TECH_COMPLETE":[740.0, 1110.0, 0.190, 0.15],
	"ATTACK":[175.0, 80.0, 0.065, 0.8],
	"ATTACK_RANGED":[1100.0, 290.0, 0.060, 0.4],
	"SKILL":[320.0, 960.0, 0.145, 0.35],
	"HEAL":[730.0, 880.0, 0.125, 0.05],
	"HARVEST":[230.0, 185.0, 0.055, 0.7],
	"MINE":[1300.0, 600.0, 0.045, 0.85],
	"BUILD":[120.0, 95.0, 0.050, 0.9],
	"MOVE":[150.0, 115.0, 0.032, 0.55],
	"TOWER_FIRE":[990.0, 185.0, 0.080, 0.6],
	"HERO_LEVEL":[580.0, 1160.0, 0.240, 0.08],
	"HERO_UPGRADE":[790.0, 1250.0, 0.165, 0.1],
	"WORKER_LOST":[300.0, 130.0, 0.195, 0.35],
	"FIELD_REWARD":[640.0, 1280.0, 0.260, 0.10],
	"HERO_EQUIPMENT_LOST":[430.0, 130.0, 0.240, 0.4],
	"HIT":[145.0,70.0,0.11,0.75],
	"CONTROL":[540.0,160.0,0.23,0.3],
	"STATUS":[410.0,290.0,0.18,0.45],
	"BUFF":[370.0,810.0,0.22,0.12],
	"ITEM":[790.0,540.0,0.2,0.18],
}
const CAPTIONS := {
	"SELECT":"已选择", "UI_OPEN":"已打开", "UI_CLOSE":"已关闭", "CANCEL":"已取消选点",
	"ACCEPT":"指令已接收", "REJECT":"指令未执行",
	"CAPTURE_START":"开始争取据点", "CAPTURE_CONTESTED":"据点正在争夺", "CAPTURE_COMPLETE":"据点占领完成", "CAPTURE_LOST":"我方据点已失守",
	"PRODUCTION":"新单位已出场", "BUILD_COMPLETE":"建筑已完工", "TECH_COMPLETE":"科技已升级",
	"ATTACK":"实际攻击", "ATTACK_RANGED":"实际远程攻击", "SKILL":"技能已施放", "HEAL":"实际治疗",
	"HARVEST":"正在采集", "MINE":"正在采矿", "BUILD":"正在施工", "MOVE":"实际行进",
	"TOWER_FIRE":"箭塔实际开火", "HERO_LEVEL":"长官升级 · 获得技能点", "HERO_UPGRADE":"技能升级完成", "WORKER_LOST":"我方工人被击杀", "FIELD_REWARD":"探索奖励已结算",
	"HERO_EQUIPMENT_LOST":"英雄倒下 · 高级装备遗落，双方均可争夺！",
	"HIT":"实际命中", "CONTROL":"控制已生效", "STATUS":"状态已生效", "BUFF":"增益已生效", "ITEM":"消耗品已使用",
}
const PRIORITIES := {"SELECT":20, "UI_OPEN":20, "UI_CLOSE":20, "CANCEL":25, "ACCEPT":30, "REJECT":65, "CAPTURE_START":60, "CAPTURE_CONTESTED":70, "CAPTURE_COMPLETE":90, "CAPTURE_LOST":100, "PRODUCTION":75, "BUILD_COMPLETE":80, "TECH_COMPLETE":80, "ATTACK":8, "ATTACK_RANGED":8, "SKILL":25, "HEAL":15, "HARVEST":3, "MINE":3, "BUILD":3, "MOVE":2, "TOWER_FIRE":15, "HERO_LEVEL":85, "HERO_UPGRADE":80, "WORKER_LOST":70, "FIELD_REWARD":95, "HERO_EQUIPMENT_LOST":100}
const COOLDOWNS := {"SELECT":0.09, "UI_OPEN":0.08, "UI_CLOSE":0.08, "CANCEL":0.1, "ACCEPT":0.06, "REJECT":0.2, "CAPTURE_START":0.4, "CAPTURE_CONTESTED":0.5, "CAPTURE_COMPLETE":0.3, "CAPTURE_LOST":0.3, "PRODUCTION":0.12, "BUILD_COMPLETE":0.25, "TECH_COMPLETE":0.25, "ATTACK":0.12, "ATTACK_RANGED":0.12, "SKILL":0.2, "HEAL":0.18, "HARVEST":0.24, "MINE":0.24, "BUILD":0.24, "MOVE":0.3, "TOWER_FIRE":0.16, "HERO_LEVEL":0.3, "HERO_UPGRADE":0.2, "WORKER_LOST":0.4, "FIELD_REWARD":0.25, "HERO_EQUIPMENT_LOST":0.4}
const IMPORTANT := ["CAPTURE_START", "CAPTURE_CONTESTED", "CAPTURE_COMPLETE", "CAPTURE_LOST", "PRODUCTION", "BUILD_COMPLETE", "TECH_COMPLETE", "HERO_LEVEL", "HERO_UPGRADE", "WORKER_LOST", "FIELD_REWARD", "HERO_EQUIPMENT_LOST"]
const COMBAT_KINDS := ["ATTACK","ATTACK_RANGED","TOWER_FIRE","SKILL","HIT","CONTROL","STATUS","HEAL","BUFF","ITEM","HARVEST","MINE","BUILD","MOVE"]

var _pending: Array[Dictionary] = []
var _notices: Array[Dictionary] = []
var _seen: Dictionary = {}
var _seen_order: Array[String] = []
var _last_kind: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _voice_until: Array[float] = []
var _voice_gain: Array[float] = []
var _streams: Dictionary = {}
var _sound_palette := SoundPalette.new()
var _last_sound: Dictionary = {}
var _event_seen: Dictionary = {}
var _event_order: Array[String] = []
var _voice_priority: Array[int] = []
var _combat_paused := false
var _mix_headroom := 1.0
var _clock := 0.0
var _muted := false
var _volume := 0.45
var _primed := false
var _ui_serial := 0
var _playback_starts := 0
var _last_advance_starts := 0
var _suppressed := 0
var _last_observation := ""
var muted: bool:
	get: return _muted
	set(value): set_muted(value)
var volume: float:
	get: return _volume
	set(value): set_volume(value)

func _ready() -> void:
	add_to_group("strategic_audio_feedback")
	_ensure_voices()

func _process(delta: float) -> void:
	advance(delta)

func _exit_tree() -> void:
	# Stop/clear before child teardown so an exiting scene cannot retain a
	# pending voice or cached WAV. AudioServer still consumes stop messages on
	# its own mixer schedule; immediate process quit is not a hearing test.
	reset()
	_streams.clear()
	_sound_palette.clear()

func record_ui(kind: String, entity_id: String = "") -> void:
	if kind not in ["SELECT", "UI_OPEN", "UI_CLOSE", "CANCEL"]: return
	_ui_serial += 1
	_admit(kind, entity_id, null, -1, "ui:%d" % _ui_serial)

func record_command(command: Dictionary, result: Dictionary, snapshot: Dictionary) -> void:
	if typeof(result.get("accepted")) != TYPE_BOOL or str(command.get("type", "")).is_empty(): return
	var kind := "ACCEPT" if result.accepted else "REJECT"
	var entity_id := str(command.get("unit_id", command.get("subject_id", command.get("building_id", ""))))
	var point: Variant = command.get("target_position", command.get("position"))
	var serial := int(snapshot.get("command_serial", -1))
	var key := "command:%d:%s:%s:%s" % [serial, kind, entity_id, str(command).sha256_text()]
	# Refusals do not increase the host serial: repeated human retries are valid
	# local feedback after category cooldown, but never completion evidence.
	if not result.accepted:
		_ui_serial += 1
		key += ":%d" % _ui_serial
	_admit(kind, entity_id, point, int(snapshot.get("tick", -1)), key, {"command_type":str(command.type), "error":str(result.get("error", ""))})

func observe(previous: Dictionary, current: Dictionary, visible_world_rect: Rect2) -> void:
	if current.is_empty(): return
	var facts:=_combat_events(current)
	var observation := "%s:%d:%d:%s" % [str(current.get("seed", "")), int(current.get("tick", -1)), int(current.get("command_serial", -1)),str(facts[-1].get("event_id","")) if not facts.is_empty() else ""]
	if not _primed or previous.is_empty():
		_primed = true
		_last_observation = observation
		for event:Dictionary in _combat_events(current):_remember_event(str(event.get("event_id","")))
		return
	var tick := int(current.get("tick", -1))
	if tick < 0:return
	if tick < int(previous.get("tick", -1)) or current.get("seed") != previous.get("seed"):
		# Explicit world restart/rollback starts a silent baseline, not an old
		# battle's queued tails. A same-seed new Combat can reuse receipt IDs.
		reset();_primed=true;_last_observation=observation
		for event:Dictionary in facts:_remember_event(str(event.get("event_id","")))
		return
	# UI history can evict bounded individual IDs, but a frozen/repeated actual
	# host tick/serial must not revive old physical actions after that eviction.
	if observation == _last_observation: return
	_last_observation = observation
	_observe_sites(previous, current, tick)
	_observe_field_objectives(previous, current, tick)
	_observe_neutral_rewards(previous, current, tick)
	_observe_buildings(previous, current, tick, visible_world_rect)
	_observe_technology(previous, current, tick)
	_observe_hero_progress(previous, current, tick)
	var receipts:bool=current.has("combat_feedback_events") or current.get("combat",{}).has("combat_feedback_events")
	if receipts:_observe_combat_receipts(current,tick,visible_world_rect)
	for list: String in ["soldiers", "workers"]:
		var old_bodies := _index(previous.get(list, []))
		for body: Dictionary in current.get(list, []):
			var id := str(body.get("id", ""))
			if id.is_empty(): continue
			var old: Dictionary = old_bodies.get(id, {})
			if not _alive(body):
				if list == "workers" and body.get("side") == "PLAYER" and _alive(old) and int(body.get("death_tick", -1)) >= int(previous.get("tick", 0)):
					_admit("WORKER_LOST", id, body.get("position"), int(body.get("death_tick", tick)), "worker_death:%s:%d" % [id, int(body.get("death_tick", tick))])
				continue
			if str(body.get("side", "")) == "PLAYER" and (old.is_empty() or not _alive(old)):
				_admit("PRODUCTION", id, body.get("position"), tick, "production:%s:%d" % [id, tick], {"unit_type":str(body.get("unit_type", ""))})
			if not receipts or list=="workers":_observe_action(body, tick, visible_world_rect)
			elif _valid_point(body.get("position")) and visible_world_rect.has_point(Vector2(body.position)) and int(body.get("last_move_tick",-1))==tick:
				_admit("MOVE",id,body.position,tick,"move:%s:%d"%[id,int(tick/24)])

static func _combat_events(snapshot:Dictionary)->Array:
	return snapshot.get("combat_feedback_events",snapshot.get("combat",{}).get("combat_feedback_events",[]))

func _remember_event(id:String)->void:
	if id.is_empty() or _event_seen.has(id):return
	_event_seen[id]=true;_event_order.append(id)
	if _event_order.size()>512:_event_seen.erase(_event_order.pop_front())

func _observe_combat_receipts(snapshot:Dictionary,tick:int,visible:Rect2)->void:
	for event:Dictionary in _combat_events(snapshot):
		var receipt:=str(event.get("event_id",""))
		if receipt.is_empty() or _event_seen.has(receipt):continue
		_remember_event(receipt)
		if bool(event.get("silent_audio",false)):continue
		var at:=int(event.get("tick",-1))
		if at<0 or at>tick or tick-at>14:continue
		var source:Dictionary=event.get("source",{})
		var target:Dictionary=event.get("target",{})
		var origin:Variant=source.get("position",event.get("position"))
		var destination:Variant=target.get("position",origin)
		if not ((_valid_point(origin) and visible.has_point(Vector2(origin))) or (_valid_point(destination) and visible.has_point(Vector2(destination)))):continue
		var kind:=str(event.get("kind",""))
		if kind=="CAST":kind="SKILL"
		if kind not in COMBAT_KINDS:continue
		var details:=event.duplicate(true)
		details.erase("kind")
		details["hero_archetype"]=str(source.get("hero_archetype",""))
		details["faction_id"]=str(source.get("faction_id",""))
		details["unit_type"]=str(source.get("unit_type",""))
		details["material"]=MaterialEffects.attack_material(source)
		details["attack_type"]=str(event.get("attack_type",source.get("attack_type","EDGE")))
		details["sound_phase"]="CAST" if kind=="SKILL" else "IMPACT" if kind in ["HIT","CONTROL","STATUS"] else kind
		details["ultimate"]=bool(event.get("ultimate",false)) and kind=="SKILL"
		if str(event.get("phase",""))=="END" and kind in ["CONTROL","STATUS"]:
			details["caption"]="控制已结束" if kind=="CONTROL" else "状态已结束"
		_admit(kind,str(source.get("id","")),origin,at,"receipt:"+receipt,details)

func record_preview(cue:Dictionary,playback_id:String)->void:
	# Explicit read-only theater fixture. It never impersonates a host receipt.
	var details:=cue.duplicate(true)
	var kind:=str(details.get("kind",""));details.erase("kind")
	details["preview_only"]=true
	_admit(kind,"theater",null,-1,"preview:"+playback_id,details)

func cancel_preview()->void:
	for index:int in range(_pending.size()-1,-1,-1):
		if bool(_pending[index].get("preview_only",false)):_pending.remove_at(index)
	for index:int in range(_voices.size()):
		if bool(_voices[index].get_meta("sound_choice",{}).get("preview_only",false)):
			_voices[index].stop();_voice_until[index]=0.0

func set_combat_paused(value:bool)->void:
	_combat_paused=value
	if not value:return
	for index:int in range(_pending.size()-1,-1,-1):
		if _pending[index].kind in COMBAT_KINDS and not bool(_pending[index].get("preview_only",false)):_pending.remove_at(index)

func _observe_neutral_rewards(previous: Dictionary, current: Dictionary, tick: int) -> void:
	var old_events: Dictionary = {}
	for event: Dictionary in previous.get("neutral_events", []): old_events[str(event)] = true
	for event: Dictionary in current.get("neutral_events", []):
		if event.get("side") != "PLAYER" or old_events.has(str(event)): continue
		var actual_tick := int(event.get("tick", -1))
		if actual_tick < int(previous.get("tick", -1)) or actual_tick > tick: continue
		var key := "neutral:%s:%s:%d" % [str(event.get("camp_id", "")), str(event.get("type", "")), actual_tick]
		if event.get("type") == "HERO_EQUIPMENT_DROPPED":
			_admit("HERO_EQUIPMENT_LOST",str(event.get("unit_id","")),event.get("position"),actual_tick,key,{"caption":CAPTIONS.HERO_EQUIPMENT_LOST,"icon":"equipment"})
			continue
		if event.get("type") == "NEUTRAL_BOUNTY":
			var victim := str(event.get("victim_id",""))
			var material := int(event.get("reward",{}).get("MATERIAL",0))
			if victim.is_empty() or material <= 0: continue
			key += ":"+victim
			_admit("FIELD_REWARD",victim,event.get("position"),actual_tick,key,{"caption":"击杀赏金 · 金币+%d" % material,"receipt_id":key,"icon":"gold","actual_grant":event.get("reward",{}).duplicate(true)})
			continue
		if event.get("type") not in ["CAMP_CLEARED","LOOT_COLLECTED"]: continue
		var caption := "野营已清除 · 资源与战利品已结算" if event.get("type") == "CAMP_CLEARED" else "英雄已拾取 · " + str(event.get("item_id", ""))
		var icon := "equipment"
		if event.get("type") == "CAMP_CLEARED":
			for camp: Dictionary in current.get("neutral_camps",[]):
				if camp.get("id") == event.get("camp_id") and camp.get("kind") == "SCATTERED": caption = "弱营已清除"; icon = "guard"; break
		_admit("FIELD_REWARD", str(event.get("camp_id", "")), event.get("position"), actual_tick, key, {"caption":caption, "receipt_id":key, "icon":icon, "actual_grant":event.get("reward", {}).duplicate(true)})

func _observe_field_objectives(previous: Dictionary, current: Dictionary, tick: int) -> void:
	var previous_receipts: Dictionary = {}
	for event: Dictionary in previous.get("field_objective_events", []):
		previous_receipts[str(event.get("receipt_id", ""))] = true
	for event: Dictionary in current.get("field_objective_events", []):
		var receipt := str(event.get("receipt_id", ""))
		if receipt.is_empty() or previous_receipts.has(receipt) or event.get("side", "") != "PLAYER": continue
		var actual_tick := int(event.get("claimed_tick", event.get("tick", -1)))
		if actual_tick <= int(previous.get("tick", -1)) or actual_tick > tick: continue
		_admit("FIELD_REWARD", str(event.get("site_id", "")), event.get("position"), actual_tick, "field_reward:" + receipt, {"caption":FieldObjectives.event_caption(event), "receipt_id":receipt, "icon":str(event.get("icon", "hero")), "actual_grant":event.get("actual_grant", {}).duplicate(true)})

func drain_cues() -> Array[Dictionary]:
	var result: Array[Dictionary] = _notices.duplicate(true)
	_notices.clear()
	return result

func diagnostics() -> Dictionary:
	var active := 0
	for index: int in range(_voices.size()):
		if _voice_until[index] > _clock and _voices[index].playing: active += 1
	var result := {"muted":_muted, "volume":_volume,"mix_headroom":_mix_headroom,"mix_peak_bound":_mix_peak_bound(), "pending_count":_pending.size(), "notice_count":_notices.size(), "seen_count":_seen.size(),"event_seen_count":_event_seen.size(),"combat_paused":_combat_paused, "voice_count":_voices.size(), "active_voices":active, "playback_starts":_playback_starts, "last_advance_starts":_last_advance_starts, "suppressed_count":_suppressed, "generated_stream_count":_streams.size(), "baseline_established":_primed, "last_sound":_last_sound.duplicate(true)}
	result.merge(_sound_palette.diagnostics())
	return result

func set_muted(value: bool) -> void:
	_muted = value
	if value:
		_pending.clear()
		_stop_voices()

func set_volume(value: float) -> void:
	if not is_finite(value): return
	_volume = clampf(value, 0.0, 1.0)
	_rebalance_headroom()
	if _volume == 0.0: _pending.clear(); _stop_voices()

func reset() -> void:
	_pending.clear()
	_notices.clear()
	_seen.clear()
	_seen_order.clear()
	_last_kind.clear()
	_event_seen.clear();_event_order.clear();_combat_paused=false
	_stop_voices()
	_clock = 0.0
	_primed = false
	_ui_serial = 0
	_playback_starts = 0
	_last_advance_starts = 0
	_suppressed = 0
	_last_observation = ""
	_last_sound.clear()
	_mix_headroom=1.0

func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0: return
	_clock += delta
	_last_advance_starts = 0
	for index: int in range(_voices.size()):
		if _voice_until[index] <= _clock and _voices[index].playing: _voices[index].stop()
	for index: int in range(_pending.size() - 1, -1, -1):
		var allowed:=0.2 if _pending[index].kind in ["ATTACK","ATTACK_RANGED","HIT","TOWER_FIRE"] else 0.5 if _pending[index].kind in COMBAT_KINDS else MAX_CUE_AGE
		if _clock - float(_pending[index].created) > allowed: _pending.remove_at(index)
	if _muted or _volume == 0.0:
		_pending.clear()
		return
	if not is_inside_tree(): return
	_ensure_voices()
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.priority) > int(b.priority))
	var cursor:=0
	while cursor<_pending.size() and _last_advance_starts < MAX_STARTS_PER_ADVANCE:
		var cue:Dictionary=_pending[cursor]
		var voice_index := _free_voice(cue)
		if voice_index < 0:cursor+=1;continue
		_pending.remove_at(cursor)
		var kind := str(cue.kind)
		if not _streams.has(kind): _streams[kind] = make_stream(kind)
		var choice: Dictionary = _sound_palette.resolve(cue, _streams[kind])
		var stream: AudioStreamWAV = choice.stream
		if stream == null: continue
		_last_sound = choice.duplicate()
		_last_sound.erase("stream")
		_last_sound["kind"] = kind
		_voices[voice_index].stream = stream
		_voice_gain[voice_index] = float(choice.gain)
		_voice_priority[voice_index]=int(cue.priority)
		_voices[voice_index].volume_linear = _volume * _voice_gain[voice_index]
		_voices[voice_index].set_meta("sound_choice", _last_sound.duplicate(true))
		_voices[voice_index].play()
		_voice_until[voice_index] = _clock + stream.get_length()
		_playback_starts += 1
		_last_advance_starts += 1
	_rebalance_headroom()

func _mix_peak_bound()->float:
	var result:=0.0
	for index:int in range(_voices.size()):
		if _voice_until[index]>_clock and _voices[index].playing:result+=0.36*_voices[index].volume_linear
	return result

func _rebalance_headroom()->void:
	# Every bundled/generated mono stream is <=0.36 peak. A conservative local
	# sum bound keeps even coherent full-volume voices under0.92 without changing
	# AudioServer buses or compressing the user's other applications.
	var weighted:=0.0
	for index:int in range(_voices.size()):
		if _voice_until[index]>_clock and _voices[index].playing:weighted+=0.36*_voice_gain[index]
	_mix_headroom=minf(1.0,0.92/maxf(weighted,0.0001))
	for index:int in range(_voices.size()):_voices[index].volume_linear=_volume*_voice_gain[index]*_mix_headroom

static func make_stream(kind: String) -> AudioStreamWAV:
	if not CUE_PROFILES.has(kind): return null
	var profile: Array = CUE_PROFILES[kind]
	var duration := float(profile[2])
	var frames := int(ceil(duration * SAMPLE_RATE))
	var pcm := PackedByteArray()
	pcm.resize(frames * 2)
	for index: int in range(frames):
		var time := float(index) / SAMPLE_RATE
		var phase := TAU * (float(profile[0]) * time + (float(profile[1]) - float(profile[0])) * time * time / (2.0 * duration))
		var texture := float(profile[3])
		var wave := (sin(phase) + texture * 0.35 * sin(phase * 2.37) + texture * 0.17 * sin(phase * 4.11)) / (1.0 + texture * 0.52)
		var envelope := sin(PI * float(index) / maxf(float(frames - 1), 1.0))
		pcm.encode_s16(index * 2, int(round(wave * envelope * 0.22 * 32767.0)))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = SAMPLE_RATE
	result.stereo = false
	result.loop_mode = AudioStreamWAV.LOOP_DISABLED
	result.data = pcm
	return result

func _observe_sites(previous: Dictionary, current: Dictionary, tick: int) -> void:
	if current.get("phase", "") != "BATTLE": return
	var old_sites := _index(previous.get("sites", []))
	for site: Dictionary in current.get("sites", []):
		var id := str(site.get("id", ""))
		var old: Dictionary = old_sites.get(id, {})
		if old.is_empty(): continue
		var owner := str(site.get("owner", ""))
		var old_owner := str(old.get("owner", ""))
		if owner != old_owner:
			if old_owner == "PLAYER": _admit("CAPTURE_LOST", id, site.get("position"), tick, "capture_lost:%s:%d" % [id, tick])
			if owner == "PLAYER": _admit("CAPTURE_COMPLETE", id, site.get("position"), tick, "capture_complete:%s:%d" % [id, tick])
			continue
		if current.get("outcome", "ONGOING") != "ONGOING": continue
		var presence: Dictionary = site.get("presence", {})
		var old_presence: Dictionary = old.get("presence", {})
		var player := int(presence.get("PLAYER", 0))
		var enemy := int(presence.get("AI", 0))
		if player > 0 and enemy > 0 and (int(old_presence.get("PLAYER", 0)) == 0 or int(old_presence.get("AI", 0)) == 0):
			_admit("CAPTURE_CONTESTED", id, site.get("position"), tick, "capture_contested:%s:%d" % [id, tick])
			continue
		var progress_changed := int(site.get("progress", 0)) != int(old.get("progress", 0))
		var player_relevant := player > 0 or owner == "PLAYER" or old_owner == "PLAYER"
		var just_advancing := progress_changed and not _advancing(old)
		var leader_changed := _leader(site) != _leader(old)
		if player_relevant and progress_changed and (just_advancing or leader_changed):
			var stage := "NEUTRALIZING" if str(site.get("capture_side", "")) != _leader(site) and int(site.get("progress", 0)) > 0 else "CAPTURING"
			var caption := "敌军开始夺取我方据点" if _leader(site) == "AI" else "正在削弱敌方控制" if stage == "NEUTRALIZING" else CAPTIONS.CAPTURE_START
			_admit("CAPTURE_START", id, site.get("position"), tick, "capture_start:%s:%d" % [id, tick], {"stage":stage, "leader":_leader(site), "caption":caption})

func _observe_buildings(previous: Dictionary, current: Dictionary, tick: int, visible: Rect2) -> void:
	var old_buildings := _index(previous.get("buildings", []))
	for building: Dictionary in current.get("buildings", []):
		var id := str(building.get("id", ""))
		var old: Dictionary = old_buildings.get(id, {})
		if old.is_empty() or not _alive(building): continue
		if building.get("side") == "PLAYER" and bool(building.get("complete", false)) and not bool(old.get("complete", false)):
			_admit("BUILD_COMPLETE", id, building.get("position"), tick, "build_complete:%s:%d" % [id, tick], {"building_type":str(building.get("building_type", ""))})
		if building.get("side") == "PLAYER" and building.get("building_type") == "BASE" and int(building.get("base_tier", 1)) > int(old.get("base_tier", 1)):
			_admit("TECH_COMPLETE", id, building.get("position"), tick, "base_tier:%s:%d:%d" % [id, int(building.base_tier), tick], {"caption":"基地升至%d级 · 新内容已解锁" % int(building.base_tier), "base_tier":int(building.base_tier)})
		if building.get("side") == "PLAYER" and building.get("building_type") == "TOWER" and int(building.get("tower_level",1)) > int(old.get("tower_level",1)):
			_admit("TECH_COMPLETE",id,building.get("position"),tick,"tower_tier:%s:%d" % [id,tick],{"caption":"箭塔强化完毕 · 火力提升至4名基础远程"})
		var age := tick - int(building.get("last_action_tick", -1000000))
		if current.get("phase") == "BATTLE" and int(building.get("attack_range",0))>0 and building.get("complete", false) and building.get("defense_active",true) and building.get("last_action_kind") == "ATTACK" and age >= 0 and age < 8:
			var origin: Variant = building.get("position")
			var target: Variant = building.get("last_action_target_position")
			if (_valid_point(origin) and visible.has_point(Vector2(origin))) or (_valid_point(target) and visible.has_point(Vector2(target))):
				_admit("TOWER_FIRE", id, origin, int(building.last_action_tick), "tower_fire:%s:%d" % [id, int(building.last_action_tick)], {"target_id":str(building.get("last_action_target_id", "")), "attack_type":str(building.get("attack_type","PIERCE")), "faction_id":str(building.get("faction_id","HUMAN")), "tower_identity":str(building.get("tower_identity","")), "material":str(building.get("tower_material","ARROW"))})

func _observe_hero_progress(previous: Dictionary, current: Dictionary, tick: int) -> void:
	var old_heroes := _index(previous.get("heroes", {}).get("officers", []))
	for hero: Dictionary in current.get("heroes", {}).get("officers", []):
		if hero.get("side") != "PLAYER": continue
		var id := str(hero.get("id", hero.get("unit_id", "")))
		var old: Dictionary = old_heroes.get(id, {})
		if old.is_empty(): continue
		if int(hero.get("level", 1)) > int(old.get("level", 1)):
			_admit("HERO_LEVEL", id, hero.get("position"), int(hero.get("last_level_up_tick", tick)), "hero_level:%s:%d" % [id, int(hero.get("level", 1))], {"level":int(hero.get("level", 1)), "skill_points":int(hero.get("skill_points", 0))})
		if int(hero.get("last_skill_upgrade_tick", -1)) > int(old.get("last_skill_upgrade_tick", -1)) or hero.get("skill_levels", {}) != old.get("skill_levels", {}):
			_admit("HERO_UPGRADE", id, hero.get("position"), int(hero.get("last_skill_upgrade_tick", tick)), "hero_upgrade:%s:%s" % [id, str(hero.get("skill_levels", {}))], {"skill_id":str(hero.get("last_upgraded_skill_id", ""))})

func _observe_technology(previous: Dictionary, current: Dictionary, tick: int) -> void:
	var before: Dictionary = previous.get("technology", {}).get("PLAYER", {})
	var after: Dictionary = current.get("technology", {}).get("PLAYER", {})
	for technology: String in after:
		var level := int(after[technology])
		if before.has(technology) and level > int(before[technology]):
			_admit("TECH_COMPLETE", technology, null, tick, "technology:%s:%d" % [technology, level], {"level":level})

func _observe_action(body: Dictionary, tick: int, visible: Rect2) -> void:
	var point: Variant = body.get("position")
	if not _valid_point(point): return
	var origin_visible := visible.has_point(Vector2(point))
	var target: Variant = body.get("action_position" if body.get("unit_type") == "worker" else "last_action_target_position", point)
	var action_visible := origin_visible or (_valid_point(target) and visible.has_point(Vector2(target)))
	var id := str(body.get("id", ""))
	var identity:={"unit_type":str(body.get("unit_type","")),"hero_archetype":str(body.get("hero_archetype","")),"faction_id":str(body.get("faction_id","HUMAN")),"attack_type":str(body.get("attack_type","EDGE")),"material":MaterialEffects.attack_material(body)}
	var skill_tick := int(body.get("last_skill_tick", -1000000))
	var skill_target: Variant = body.get("last_skill_target_position", point)
	if (body.get("unit_type") == "hero" or bool(body.get("neutral",false))) and tick - skill_tick >= 0 and tick - skill_tick < 14 and (origin_visible or (_valid_point(skill_target) and visible.has_point(Vector2(skill_target)))):
		_admit("SKILL", id, point, skill_tick, "skill:%s:%s:%d" % [id, str(body.get("last_skill_id", "")), skill_tick])
	if body.get("unit_type", "") == "worker":
		var work := str(body.get("action_kind", ""))
		var attack_age := tick-int(body.get("last_action_tick",-1000000))
		if origin_visible and work == "ATTACK" and attack_age >= 0 and attack_age < 8:
			_admit("ATTACK",id,point,int(body.last_action_tick),"worker_defense:%s:%d" % [id,int(body.last_action_tick)],identity)
		if action_visible and work in ["HARVEST", "MINE", "BUILD"] and int(body.get("action_tick", -1)) == tick:
			_admit(work, id, point, tick, "work:%s:%s:%d" % [id, work, int(tick / 16)],identity)
		var movement: Vector2 = Vector2(body.get("movement_delta", Vector2i.ZERO))
		if origin_visible and movement != Vector2.ZERO: _admit("MOVE", id, point, tick, "move:%s:%d" % [id, int(tick / 24)])
		return
	var action_tick := int(body.get("last_action_tick", -1000000))
	var age := tick - action_tick
	var action := str(body.get("last_action_kind", ""))
	if action_visible and age >= 0 and age < 16:
		var kind := ""
		if action == "ATTACK": kind = "ATTACK" if MaterialEffects.attack_material(body) == "MELEE" else "ATTACK_RANGED"
		elif action in ["HEAL", "POTION"]: kind = "HEAL"
		elif action.begins_with("SKILL_") and skill_tick < 0: kind = "SKILL"
		if not kind.is_empty(): _admit(kind, id, point, action_tick, "action:%s:%s:%d" % [id, action, action_tick],identity)
	if origin_visible and int(body.get("last_move_tick", -1)) == tick and Vector2(body.get("last_move_direction", Vector2i.ZERO)) != Vector2.ZERO:
		_admit("MOVE", id, point, tick, "move:%s:%d" % [id, int(tick / 24)])

func _admit(kind: String, entity_id: String, point: Variant, tick: int, key: String, details: Dictionary = {}) -> void:
	if not CUE_PROFILES.has(kind) or _seen.has(key): return
	_seen[key] = true
	_seen_order.append(key)
	if _seen_order.size() > MAX_SEEN: _seen.erase(_seen_order.pop_front())
	var cooldown_key:=kind
	if kind=="SKILL":cooldown_key+=":"+entity_id+":"+str(details.get("skill_id",""))
	elif kind in ["CONTROL","STATUS"]:cooldown_key+=":"+str(details.get("status_kind",""))
	elif kind=="ITEM":cooldown_key+=":"+str(details.get("item_id",""))
	elif kind in ["ATTACK","ATTACK_RANGED","HIT","BUFF"]:cooldown_key+=":"+str(details.get("attack_type",details.get("skill_id","")))
	var cooling := _clock - float(_last_kind.get(cooldown_key, -1000000.0)) < float(COOLDOWNS.get(kind,0.08))
	var notify := kind in IMPORTANT
	if cooling and not notify:
		_suppressed += 1
		return
	var cue := {"kind":kind, "caption":CAPTIONS[kind], "entity_id":entity_id, "tick":tick, "notify":notify, "priority":int(PRIORITIES.get(kind,18))+ (20 if bool(details.get("ultimate",false)) else 0), "created":_clock}
	if _valid_point(point): cue["position"] = Vector2(point)
	cue.merge(details.duplicate(true), true)
	_enqueue(_notices, cue)
	if cooling or _muted or _volume == 0.0 or (_combat_paused and kind in COMBAT_KINDS and not bool(details.get("preview_only",false))):
		_suppressed += 1
		return
	_last_kind[cooldown_key] = _clock
	_enqueue(_pending, cue)

func _enqueue(buffer: Array[Dictionary], cue: Dictionary) -> void:
	if buffer.size() >= MAX_PENDING:
		var weakest := 0
		for index: int in range(1, buffer.size()):
			if int(buffer[index].priority) < int(buffer[weakest].priority): weakest = index
		if int(cue.priority) < int(buffer[weakest].priority): return
		buffer.remove_at(weakest)
	buffer.append(cue.duplicate(true))

func _ensure_voices() -> void:
	if not is_inside_tree(): return
	while _voices.size() < MAX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.name = "FeedbackVoice%d" % (_voices.size() + 1)
		voice.max_polyphony = 1
		voice.volume_linear = _volume
		add_child(voice)
		_voices.append(voice)
		_voice_until.append(0.0)
		_voice_gain.append(1.0)
		_voice_priority.append(0)

func _free_voice(cue:Dictionary) -> int:
	var indices:Array=range(8,10) if cue.kind not in COMBAT_KINDS else range(6,8) if bool(cue.get("ultimate",false)) else range(0,6)
	for index:int in indices:
		if _voice_until[index]<=_clock:return index
	# Protect strategic/UI slots. Important hero signatures can replace a quiet
	# ordinary hit, but never create more players or an unbounded tail queue.
	if int(cue.priority)>=40:
		var weakest:=-1
		for index:int in range(0,6):
			if _voice_priority[index]<int(cue.priority) and (weakest<0 or _voice_priority[index]<_voice_priority[weakest]):weakest=index
		if weakest>=0:_voices[weakest].stop();return weakest
	return -1

func _stop_voices() -> void:
	for index: int in range(_voices.size()):
		_voices[index].stop()
		_voices[index].stream = null
		_voices[index].remove_meta("sound_choice")
		_voice_until[index] = 0.0
		_voice_gain[index] = 1.0

static func _index(values: Array) -> Dictionary:
	var result := {}
	for value: Dictionary in values:
		if not str(value.get("id", "")).is_empty(): result[str(value.id)] = value
	return result

static func _alive(body: Dictionary) -> bool:
	return int(body.get("hp", 0)) > 0 and bool(body.get("alive", true))

static func _valid_point(point: Variant) -> bool:
	return (point is Vector2 or point is Vector2i) and is_finite(float(point.x)) and is_finite(float(point.y))

static func _leader(site: Dictionary) -> String:
	var presence: Dictionary = site.get("presence", {})
	var player := int(presence.get("PLAYER", 0))
	var enemy := int(presence.get("AI", 0))
	return "" if player == enemy else "PLAYER" if player > enemy else "AI"

static func _advancing(site: Dictionary) -> bool:
	var leader := _leader(site)
	return not leader.is_empty() and (int(site.get("progress", 0)) < int(site.get("max_progress", 200)) or leader != str(site.get("capture_side", "")))
