extends RefCounted
## Read-only body timing for the oath-map, ash-covenant and rivet-furnace.
## No clock, textures, transforms, simulation imports or action creation.
## Consumers retain `phase` for hit/VFX and use only the body_* projection.
const VERSION := "m76-faction-motion-a-v1"
const FACTIONS := ["HUMAN", "UNDEAD", "MACHINE"]
# faction, gait ticks/cell, attack envelope, cast envelope, work envelope,
# embodied motion identity. Four retained source cells, not newly drawn poses.
const ROWS := {
	"worker:HUMAN":["HUMAN",2.8,"lever","fold","lever","桥工弯膝承篓，凿下后慢收工具"],
	"worker:UNDEAD":["UNDEAD",3.4,"loose","veil","loose","缝名工分节拖步，灰线手臂缓慢回垂"],
	"worker:MACHINE":["MACHINE",2.6,"piston","relay","piston","检修工短行程踏步，敲击急出缓回"],
	"hinge_guard":["HUMAN",2.7,"edge","fold","lever","盾侧稳定，合页剑短蓄后收刃"],
	"bright_crossbow":["HUMAN",2.7,"bow","fold","lever","弩肩先压稳，再短促放弦并回收"],
	"iron_lancer":["HUMAN",3.2,"lever","fold","lever","重槊承重，刺出后留出收槊节拍"],
	"grove_mender":["HUMAN",3.0,"fold","fold","lever","医士抱药册，先展开再合拢"],
	"oath_cavalry":["HUMAN",2.4,"edge","fold","lever","短骑步成对落足，骑枪稳持后回正"],
	"oath_colossus":["HUMAN",3.8,"bow","lever","lever","重弩军士先压稳横弩，短促后坐后回转装填"],
	"ash_guard":["UNDEAD",3.2,"loose","veil","loose","骨卫先牵肘，再让骨刃落稳"],
	"bone_archer":["UNDEAD",3.2,"veil","fold","loose","铭灯术士先提灯收袖，杖尖送出魂光后慢收"],
	"stitched_guard":["UNDEAD",3.8,"mass","veil","loose","缝骨重卫迟落脚，重击后整躯回收"],
	"ember_mender":["UNDEAD",3.6,"veil","veil","loose","缝合师灰灯先提后覆，不使用机械急停"],
	"soul_revenant":["UNDEAD",4.0,"mass","veil","loose","巨骸两段承重，击后长悬臂"],
	"rivet_guard":["MACHINE",3.1,"piston","relay","piston","铆卫开闸后急击，回收留检修停顿"],
	"shard_gunner":["MACHINE",2.9,"recoil","relay","piston","碎晶枪先抵肩，击后机械回膛"],
	"gear_engine":["MACHINE",3.0,"recoil","relay","piston","轮车保持同一地脚，炮管承受后坐"],
	"repair_drone":["MACHINE",2.5,"relay","relay","piston","维修机探针快伸，检修时缓收"],
	"aether_engine":["MACHINE",3.5,"mass","relay","piston","灵核战车先充压，重炮后长回膛"],
	"hero:COMMANDER":["HUMAN",2.7,"edge","fold","lever","誓图师像折地图一样先聚拢再打开剑势"],
	"hero:BULWARK":["HUMAN",3.5,"mass","lever","lever","盾长官承重后压盾，回正不滑脚"],
	"hero:ARCANIST":["HUMAN",2.9,"fold","prism","lever","星契术师展开航镜再合光，不套弓弦节奏"],
	"hero:RANGER":["HUMAN",2.5,"bow","bow","lever","巡弦游侠拉弦持稳，放弦与回弓分拍"],
	"hero:DUELIST":["HUMAN",2.4,"edge","edge","lever","断契刃客短提刃，锐出手和长收势"],
	"hero:OATH_REAVER":["HUMAN",2.6,"edge","fold","lever","断页剑师让长剑先退后送，纸签随收势落定"],
	"hero:BRIDGE_VANGUARD":["HUMAN",3.3,"lever","lever","lever","渡桩先锋压横梁再起锤，重心不漂"],
	"hero:SUNGLASS_SCRIBE":["HUMAN",3.0,"prism","prism","lever","审绘师先翻页与架镜，光路收束才合页"],
	"hero:ASH_MARSHAL":["UNDEAD",3.7,"mass","veil","loose","灰誓统领骨甲迟落，灰幕回垂而非闪烁"],
	"hero:MOURN_ORACLE":["UNDEAD",3.4,"veil","veil","loose","烬语者提灯留白后封纱，保留倾听节拍"],
	"hero:CINDER_STALKER":["UNDEAD",2.9,"bow","bow","loose","骨弦猎手将骨肩压低蓄弦，收弓迟一拍"],
	"hero:ASH_CHANTER":["UNDEAD",3.5,"veil","fold","loose","归名颂者先捧灯再托起，回复动作不做重击"],
	"hero:GRAVE_BELL":["UNDEAD",3.6,"loose","bell","loose","墓钟司仪先拉钟索，撞钟后让钟影回摆"],
	"hero:RELIC_REAVER":["UNDEAD",2.7,"edge","veil","loose","遗物决斗者双钩先交错再展开，面纱慢收"],
	"hero:OSSUARY_KNIGHT":["UNDEAD",3.8,"lever","veil","loose","送行骨骑像撑船辕一样先抵稳再划出"],
	"hero:CINDER_TESTATOR":["UNDEAD",3.6,"fold","veil","loose","遗嘱官举纸停留而后落灰，避免炮术式急退"],
	"hero:COIL_WARDEN":["MACHINE",3.6,"mass","relay","piston","炉盾监工先锁肩板，重击后释压"],
	"hero:VOLT_WEAVER":["MACHINE",2.8,"relay","relay","piston","电弧织师分两拍接通线圈，随后断路回收"],
	"hero:GEAR_HUNTER":["MACHINE",2.6,"recoil","relay","piston","齿轮猎手击前定枪，后坐与回膛分开"],
	"hero:COIL_MEDIC":["MACHINE",3.0,"relay","fold","piston","稳压医师先接稳电极，再合盖收针"],
	"hero:SIGNAL_KEEPER":["MACHINE",2.9,"relay","relay","piston","信标巡检先立板，亮讯后收旗，非枪械后坐"],
	"hero:PISTON_FENCER":["MACHINE",2.5,"piston","piston","piston","偏心冲刃师蓄压短冲，长短活塞不同承重"],
	"hero:RIVET_LEGIONARY":["MACHINE",3.4,"lever","relay","piston","铆阵班长先架承重板，再合闸回收"],
	"hero:FLUX_BOMBARDIER":["MACHINE",3.2,"recoil","relay","piston","磁通炮术士先压三足再开炮，放电后回膛"],
}
# End of each retained cell. Event phase 0.5 remains the start of contact cell2.
const ENVELOPES := {
	"edge":[0.18,0.50,0.63,1.0],
	"lever":[0.28,0.50,0.68,1.0],
	"bow":[0.34,0.50,0.60,1.0],
	"mass":[0.33,0.50,0.73,1.0],
	"loose":[0.22,0.50,0.76,1.0],
	"veil":[0.30,0.50,0.80,1.0],
	"fold":[0.23,0.50,0.71,1.0],
	"prism":[0.37,0.50,0.67,1.0],
	"piston":[0.39,0.50,0.61,1.0],
	"relay":[0.32,0.50,0.64,1.0],
	"recoil":[0.35,0.50,0.57,1.0],
	"bell":[0.39,0.50,0.85,1.0],
}

static func identity_for(unit: Dictionary) -> String:
	var type := str(unit.get("unit_type", ""))
	if type == "hero": return "hero:" + str(unit.get("hero_archetype", ""))
	if type == "worker": return "worker:" + str(unit.get("faction_id", ""))
	return type

static func supported(unit: Dictionary) -> bool:
	var identity := identity_for(unit)
	return ROWS.has(identity) and str(unit.get("faction_id", ROWS[identity][0])) == str(ROWS[identity][0]) and not bool(unit.get("neutral", false))

static func describe(unit: Dictionary) -> Dictionary:
	if not supported(unit): return {}
	var identity := identity_for(unit)
	var row: Array = ROWS[identity]
	return {"version":VERSION,"identity":identity,"faction_id":row[0],"walk_ticks_per_cell":row[1],"carry_ticks_per_cell":float(row[1])*1.12,"source_cells":4,"attack_envelope":row[2],"cast_envelope":row[3],"work_envelope":row[4],"story_motion":row[5],"anchor_offset":Vector2.ZERO,"new_raster_frames":0,"contact_phase":0.5,"event_phase_unchanged":true}

static func _finite_phase(value: Variant) -> float:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]: return 0.0
	var number := float(value)
	return clampf(number,0.0,0.999999) if is_finite(number) else 0.0

static func _remap(phase: float, envelope: String) -> float:
	var ends: Array = ENVELOPES[envelope]
	var begin := 0.0
	for index: int in range(4):
		var end := float(ends[index])
		if phase < end:
			return (float(index)+clampf((phase-begin)/(end-begin),0.0,0.999999))*0.25
		begin=end
	return 0.999999

static func decorate_pose(unit: Dictionary, pose: Dictionary) -> Dictionary:
	# Shallow projection: nested skill data is never read or altered here.
	var result := pose.duplicate(false)
	if not supported(unit): return result
	var row: Array = ROWS[identity_for(unit)]
	var action := str(pose.get("action", "IDLE"))
	result["motion_identity_m76"]=identity_for(unit)
	# New two-body death strips use only the supplied factual fatal-hit time.
	# No timestamp means an already settled corpse, never a guessed death.
	if identity_for(unit) in ["bone_archer","oath_colossus"] and action=="FALLEN":
		var death_tick := int(unit.get("last_damage_tick",-1000000))
		var sample := float(pose.get("sample_tick_m76",-1))
		if death_tick>=0 and is_finite(sample) and sample>=death_tick:
			result["body_death_phase_v3"]=clampf((sample-float(death_tick))/12.0,0,1)
		return result
	if action in ["WALK", "CARRY"]:
		# sample_tick_m76 is supplied by the renderer; it may include a bounded
		# interpolation fraction. No observation clock => retain old fallback.
		var raw: Variant = pose.get("sample_tick_m76",pose.get("animation_tick",null))
		if typeof(raw) in [TYPE_FLOAT,TYPE_INT] and is_finite(float(raw)) and float(raw)>=0:
			var duration := float(row[1])*(1.12 if action=="CARRY" else 1.0)
			var identity := str(unit.get("id",unit.get("worker_id","")))
			var offset := float(absi(identity.hash())%4) if not identity.is_empty() else 0.0
			result["body_animation_tick_m76"]=int(floor(float(raw)*3.0/duration+offset*3.0))
		return result
	var envelope := ""
	if action=="ATTACK": envelope=str(row[2])
	elif action.begins_with("SKILL_") or action in ["HEAL","POTION"]: envelope=str(row[3])
	elif action in ["HARVEST","MINE","BUILD"]: envelope=str(row[4])
	elif action in ["HIT","HURT","DAMAGE"]: envelope="loose" if row[0]=="UNDEAD" else "recoil"
	# Idle/fallen remain tick-invariant; no invented walk, hit or death event.
	if not envelope.is_empty(): result["body_phase_m76"]=_remap(_finite_phase(pose.get("phase",0.0)),envelope)
	return result
