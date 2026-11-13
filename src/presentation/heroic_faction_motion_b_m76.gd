extends RefCounted
## Observation-only body timing for the living root, deep furnace and exit commons.
## No image baking, texture cache, authority, sound, input or simulation time.
## The original `phase` continues to drive truthful impact/VFX settlement.
const VERSION := "m76-faction-motion-b-v1"
const FACTIONS := ["FOREST", "HIGHLAND", "UNDERGROUND"]
## faction, name, body, implement, gait ticks, timing family, story anchor.
const ROWS := {
	"worker:FOREST":["FOREST","织叶工人","BIPED","short_pruning_hoe",14,"work_scoop","分种腰匣随承重落下；短剪枝锄先抬后收，不是战矛。"],
	"vine_guard":["FOREST","藤卫","BIPED","fork_spear",13,"light_thrust","根叉矛守迁林通路；前探短，回收到护肩后。"],
	"leaf_archer":["FOREST","叶弓手","BIPED","split_recurve",12,"bow_release","路标员先拉叶弓，弦松快、重新搭箭慢。"],
	"stag_rider":["FOREST","鹿骑兵","MOUNTED","antler_lance",14,"mounted_thrust","叶鞍双结承重，鹿步一前一后，不把骑手当步兵抖动。"],
	"root_mender":["FOREST","根织者","ROBED","root_spindle",16,"thread_cast","纺根杖先牵线后收轴，避免与弓兵一样的急促吐弹。"],
	"elder_treant":["FOREST","古根灵卫","TREANT","trunk_crook",22,"root_weight","分杈厚肩先承重再回根，重击后留明显收势。"],
	"hero:VINE_WARDEN":["FOREST","枝垒","TREANT","hive_knuckle",20,"root_weight","借根养蜂者压低悬巢肩再收臂，蜂箱不随动作变脚锚。"],
	"hero:LEAF_SEER":["FOREST","芽灯","ROBED","graft_seed_case",15,"seed_flick","检视失败样本后开种匣，送核轻、合匣稍慢。"],
	"hero:WIND_COURIER":["FOREST","风翎","BIPED","migrant_bow",11,"bow_release","不齐尾羽的候鸟信使，拉弦停留与放箭回收分明。"],
	"hero:BLOOM_GUIDE":["FOREST","花汐","ROBED","saltwater_shell_cup",16,"cup_tilt","量水盘与贝杯缓倾再收，盐粒落下并不额外治疗。"],
	"hero:THORN_CHANTER":["FOREST","棘歌","ROBED","open_thorn_harp",15,"pluck_reprise","缺一拍的棘琴先停再拨，收弦比击弦多留一拍。"],
	"hero:THORN_REAVER":["FOREST","间穗","BIPED","split_grafting_sickle",11,"paired_cut","嫁接镰先短切再回手，不把开叉镰当厚重战锤。"],
	"hero:ANTLER_WARRIOR":["FOREST","巡苔","BIPED","branch_shield_spear",14,"shield_brace","守猎者以弧枝盾接重，再把短矛收回空角头架下。"],
	"hero:POLLEN_COMET":["FOREST","流穗","PETAL_ROBED","comet_seed_wand",12,"petal_cast","追踪迁徙萤群的开放花萼，轻抬杖而不伪造飞行或位移。"],
	"worker:HIGHLAND":["HIGHLAND","烬脊工人","STOCKY_BIPED","short_mason_pick",16,"work_weight","炉道修补者短镐轻敲，重腰包使搬运步频比空手慢。"],
	"ridge_guard":["HIGHLAND","山垒卫","STOCKY_BIPED","square_hammer",16,"hammer_drop","轮值护卫短方锤先抬后落，不使用崖盾的长断锤节奏。"],
	"stone_slinger":["HIGHLAND","砾石投手","BIPED","double_tail_sling",14,"sling_release","称量石子装入双尾投带，旋绳稍长、脱手短促。"],
	"rune_keeper":["HIGHLAND","符炉守望","ROBED","kiln_gauge_staff",17,"kiln_cast","窑尺先读温差再落印，不让整件法袍像剑士前扑。"],
	"fire_dragon":["HIGHLAND","火龙","DRAGON","kiln_breath",18,"breath_weight","火种守护者用承翼和收颈表达重量；不改变真实飞行层。"],
	"rune_behemoth":["HIGHLAND","符纹巨兽","COLOSSUS","strata_ram",24,"stone_weight","多层坝板承重再落，回收长于轻装兵而不降低实际攻速。"],
	"hero:RIDGE_JARL":["HIGHLAND","崖盾","HEAVY_BIPED","broken_dam_hammer",18,"hammer_drop","坝钉肩甲先沉稳再断锤落下，回收到三层护肩后。"],
	"hero:RUNE_ORACLE":["HIGHLAND","符炉","ROBED","kiln_gauge_cup",17,"kiln_cast","天气工艺师以窑尺和倒风杯试温，施法不是统一火球发射。"],
	"hero:EMBER_CAVALIER":["HIGHLAND","焰脊","BIPED","furnace_javelin_thrower",14,"javelin_release","现役身份是三矛架和投矛器：长拉短掷，绝非旧近战长刃。"],
	"hero:HEARTH_KEEPER":["HIGHLAND","炉暖","STOCKY_BIPED","oven_peel",17,"oven_lift","流动面炉主低炉勺先托举再送出，不能画成直接敌人受疗。"],
	"hero:STORM_HERALD":["HIGHLAND","雷旌","BIPED","grounding_flag_rope",15,"rope_snap","怕高的旗回收者先绷接地绳，旗落后留短回弹。"],
	"hero:SLAG_DANCER":["HIGHLAND","淬汀","BIPED","hot_cold_twin_blades",13,"paired_cut","冷热双刃先后不同拍，重回收体现试刃而非无限旋风。"],
	"hero:BASALT_CHAMPION":["HIGHLAND","层祁","HEAVY_BIPED","basalt_test_maul",20,"stone_weight","试坝武卫的错层岩肩先承重，横口重槌落后重新合架。"],
	"hero:OBSIDIAN_CANTOR":["HIGHLAND","玄烬","ROBED","ceramic_song_casket",18,"glass_cast","降温调先停息再开歌匣；碎玻扇合回胸片而非快速连射。"],
	"worker:UNDERGROUND":["UNDERGROUND","穴鸣工人","MULTILEG","wide_labor_spade",12,"work_scoop","短触须侧罐孢灯保持低身，劳动铲不同于前线螳刃。"],
	"chitin_guard":["UNDERGROUND","甲壳卫","MULTILEG","chitin_ram",12,"shell_push","护送队前足支撑再前推甲壳，回收时短顿不假造击退。"],
	"echo_shooter":["UNDERGROUND","回声射手","MULTILEG","reed_dart_fork",11,"fork_release","报距员先张横叉声架再送实物晶矢，不能靠虚影伪造额外箭。"],
	"tunnel_rider":["UNDERGROUND","洞穴蜥骑","MOUNTED_MULTILEG","lizard_fork_lance",13,"mounted_thrust","低伏六足蜥交错承重，骑手枝架前探后回，不穿墙。"],
	"spore_mender":["UNDERGROUND","孢织者","MULTILEG","culture_spindle",15,"spore_sift","双室菌罐分配不同样本，菌针略停后落而不是连射短矢。"],
	"abyss_devourer":["UNDERGROUND","深渊噬兽","HEAVY_MULTILEG","forked_jaw",19,"jaw_close","巨型追猎兽颚板先张再合，喉护回位不伪造处决事件。"],
	"hero:TUNNEL_SENTINEL":["UNDERGROUND","壳巢","HEAVY_MULTILEG","station_shell_spade",17,"shell_push","可携祖门先由宽前足撑住，再落宽铲；壳巢脚底不游移。"],
	"hero:ECHO_BINDER":["UNDERGROUND","回声","MULTILEG","cracked_resonance_staff",13,"echo_cast","偏心晶耳短暂试音再送窄晶矛，保留杂乱回声而非统一炮击。"],
	"hero:SPORE_STALKER":["UNDERGROUND","孢纹","MULTILEG","paired_rail_crossbow",11,"crossbow_release","现役六足双轨背弩先张筋再回弹，不再沿用旧双镰语义。"],
	"hero:SPORE_GUIDE":["UNDERGROUND","菌灯","MULTILEG","partition_sieve_spoon",15,"spore_sift","分格菌罐先分室再过筛，轻落孢粒不是敌人中毒结算。"],
	"hero:QUAKE_PRIEST":["UNDERGROUND","岩祷","MULTILEG","fault_ledger_pick",16,"fault_tap","石册页先校界再短镐敲落，断层印不改变地形碰撞。"],
	"hero:PRISM_MANTIS":["UNDERGROUND","隙琢","MULTILEG","paired_facet_blades",10,"paired_cut","六足避开菌床，双折棱刃一短一长回收，不成为普通人形。"],
	"hero:CARAPACE_WARRIOR":["UNDERGROUND","阙甲","HEAVY_MULTILEG","vented_shell_horn",16,"shell_push","双层通气扇盖先撑巢再收角，四足承重与螳形快切区分。"],
	"hero:MYCELIAL_CATALYST":["UNDERGROUND","沫蚀","MULTILEG","ceramic_acid_dropper",12,"acid_cast","两只釉面酸囊先压后送，四足矮身不随滴管挥动改变脚锚。"],
}
## Four authored body cells: prepare, commit, follow-through, recover.
## These are visual dwell weights, not attack intervals or new illustrations.
const TIMINGS := {
	"work_scoop":[[.28,.16,.18,.38],[.22,.22,.20,.36]],
	"work_weight":[[.32,.12,.18,.38],[.30,.14,.18,.38]],
	"light_thrust":[[.16,.12,.24,.48],[.20,.16,.22,.42]],
	"bow_release":[[.34,.14,.10,.42],[.30,.16,.16,.38]],
	"mounted_thrust":[[.22,.12,.24,.42],[.26,.14,.20,.40]],
	"thread_cast":[[.24,.18,.20,.38],[.34,.18,.16,.32]],
	"root_weight":[[.30,.10,.18,.42],[.34,.14,.18,.34]],
	"seed_flick":[[.24,.12,.16,.48],[.30,.12,.20,.38]],
	"cup_tilt":[[.24,.20,.18,.38],[.28,.24,.16,.32]],
	"pluck_reprise":[[.28,.10,.14,.48],[.32,.10,.18,.40]],
	"paired_cut":[[.18,.12,.26,.44],[.26,.14,.24,.36]],
	"shield_brace":[[.28,.12,.20,.40],[.24,.22,.20,.34]],
	"petal_cast":[[.22,.12,.18,.48],[.28,.12,.24,.36]],
	"hammer_drop":[[.34,.10,.16,.40],[.30,.14,.20,.36]],
	"sling_release":[[.30,.20,.08,.42],[.28,.16,.16,.40]],
	"kiln_cast":[[.30,.14,.18,.38],[.36,.16,.18,.30]],
	"breath_weight":[[.30,.12,.22,.36],[.34,.14,.24,.28]],
	"stone_weight":[[.36,.10,.18,.36],[.36,.14,.20,.30]],
	"javelin_release":[[.34,.14,.08,.44],[.32,.12,.18,.38]],
	"oven_lift":[[.28,.18,.18,.36],[.30,.20,.18,.32]],
	"rope_snap":[[.32,.10,.12,.46],[.34,.10,.18,.38]],
	"glass_cast":[[.28,.16,.20,.36],[.38,.12,.20,.30]],
	"shell_push":[[.30,.12,.22,.36],[.32,.16,.20,.32]],
	"fork_release":[[.28,.12,.12,.48],[.28,.14,.22,.36]],
	"spore_sift":[[.28,.18,.18,.36],[.30,.22,.20,.28]],
	"jaw_close":[[.28,.10,.18,.44],[.30,.16,.18,.36]],
	"echo_cast":[[.30,.12,.16,.42],[.32,.12,.22,.34]],
	"crossbow_release":[[.36,.12,.08,.44],[.32,.14,.20,.34]],
	"fault_tap":[[.32,.10,.22,.36],[.36,.12,.22,.30]],
	"acid_cast":[[.28,.16,.18,.38],[.34,.18,.18,.30]],
}

static func identity_for(unit: Dictionary) -> String:
	var kind := str(unit.get("unit_type", ""))
	if kind == "hero": return "hero:" + str(unit.get("hero_archetype", ""))
	if kind == "worker": return "worker:" + str(unit.get("faction_id", ""))
	return kind

static func describe(unit: Dictionary) -> Dictionary:
	var identity := identity_for(unit)
	if not ROWS.has(identity): return {}
	var r: Array = ROWS[identity]
	var timing: Array = TIMINGS[r[5]]
	return {"version":VERSION,"identity":identity,"faction_id":r[0],"name":r[1],"body":r[2],"weapon":r[3],"walk_cycle_ticks":r[4],"carry_cycle_ticks":float(r[4])*1.15,"timing_family":r[5],"attack_holds":timing[0].duplicate(),"cast_holds":timing[1].duplicate(),"story_anchor":r[6],"foot_anchor_policy":"unchanged-source-anchor","offset_m76":Vector2.ZERO,"body_scale_m76":Vector2.ONE,"rotation_m76":0.0,"adds_illustrations":false,"new_texture_entries":0}

static func _body_phase(phase: float, weights: Array) -> float:
	var phase_safe := clampf(phase, 0.0, .9999) if is_finite(phase) else 0.0
	var start := 0.0
	for i: int in range(4):
		var finish := start + float(weights[i])
		if phase_safe < finish or i == 3:
			return clampf((float(i)+(phase_safe-start)/maxf(.01,float(weights[i])))/4.0,0,.9999)
		start = finish
	return phase_safe

static func decorate_pose(unit: Dictionary, pose: Dictionary) -> Dictionary:
	var result := pose.duplicate(false)
	var identity := identity_for(unit)
	if not ROWS.has(identity): return result
	# The per-frame path does not allocate the explanatory profile or its arrays.
	var row: Array = ROWS[identity]
	var timing: Array = TIMINGS[row[5]]
	var action := str(pose.get("action", "IDLE"))
	var phase := float(pose.get("phase", 0.0))
	var body_phase := clampf(phase,0,.9999) if is_finite(phase) else 0.0
	if action in ["ATTACK","HARVEST","MINE","BUILD"]: body_phase = _body_phase(phase,timing[0])
	elif action.begins_with("SKILL_") or action in ["CAST","HEAL","POTION"]: body_phase = _body_phase(phase,timing[1])
	result["body_phase_m76"] = body_phase
	if action in ["WALK", "CARRY"]:
		# The caller may supply continuous presentation time only while a factual
		# WALK/CARRY observation is active. No clock means no invented walking.
		var clock := float(pose.get("body_animation_tick_m76",pose.get("animation_tick",NAN)))
		if is_finite(clock):
			var cycle := float(row[4])*(1.15 if action == "CARRY" else 1.0)
			result["body_animation_tick_m76"] = fposmod(clock,maxf(cycle,1.0))*12.0/maxf(cycle,1.0)
	result["offset_m76"] = Vector2.ZERO
	result["motion_identity_m76"] = identity
	result["motion_version_m76"] = VERSION
	return result
