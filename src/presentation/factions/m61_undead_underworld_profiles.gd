extends RefCounted
## Authored presentation only. No catalog imports, timers, combat state or RNG.
## A family describes the prop/motion, never an additional hit or summon.
const VERSION := "m61-undead-underworld-weapon-identities-v1"
const PALETTES := {
	"ash":["17191d","55433d","c29d6b","76bcd0","fff0ca","c17c87","a9b4a1"],
	"docket":["201922","64466b","bd86be","88cba9","fff0c4","e1a465","a6a1b3"],
	"chain":["151c25","365375","7ca9d2","d59f68","f3f4d8","c48caf","99aaa4"],
	"soul":["1b1726","5d467b","b78bd6","7cd6b2","fff3d2","dc9e77","96b0c0"],
	"extraction":["15211e","365e56","78c5af","dc8870","fff4c5","b58bda","93a8ba"],
	"bone_arrow":["21191b","734735","d58d53","73b4d1","fff0b5","bd8ca9","b9bca4"],
	"cinder":["191725","4e3e71","9d85cd","efbc60","fff4d6","76c9b3","bda491"],
	"pin":["17211e","38635a","83ceb8","dc7865","fff3c6","c49bdb","b0af8b"],
	"bell":["1b1824","614775","b482bf","dfb85f","fff3d3","7bbec5","bd8c7e"],
	"spade":["201c18","665341","ab956f","83c5bb","fff1c6","ba86b5","93a2b4"],
	"shell":["17211b","435f48","92b67a","d49e72","fff0c5","a391ca","b9bc95"],
	"crystal":["1c1729","564077","a180d5","73cbb9","fff4d2","e3a26c","a2b7c9"],
	"implosion":["22182a","65437d","b58cdb","e6bc63","fff7d5","7bccc4","d18eab"],
	"mantis":["241b25","744b77","c68fc3","89d0ae","fff4cc","dfae62","9cacc6"],
	"molt":["17231d","426b4d","98ca91","e28d81","fff2c3","a3a5d8","c6b472"],
	"sieve":["1b2020","476659","8cc7a0","d3a16e","fff4cc","b69bcf","96b9c6"],
	"fault":["221d18","765d3a","cbad6d","9a92d2","fff1c6","82beb4","c98c9c"],
	"seal":["221b2b","624b7b","a98cc7","e0b766","fff4cf","87c9c0","cf8f99"],
}
## hero, faction, weapon, motif, motion, phase, timed-buff motif, palette,
## existing-story anchor, counterplay, unchanged-authority budget guard.
const ENTRIES := {
	"ASH_SHOCK":["ASH_MARSHAL","UNDEAD","ash_suture","docket_ribs_recall","inward_latch","seam_open>plates_reseat>cinders_return","","ash","胸柜保存错判者铭牌；修复像逐页重审，而不是圣光祝福。","集中火力压过有限自疗；不新增护盾。","SELF_HEAL; no area hit, resurrection or extra heal tick"],
	"ASH_WARD":["ASH_MARSHAL","UNDEAD","judgement_scythe","bone_docket_clasps","passive_settle","quiet_clasps>settle>quiet","","ash","柜门胸铠的骨扣承担未完判卷的重量。","被动护甲仍受实际攻击/护甲公式约束。","LEARNED_PASSIVE; never invent a timed glow or paid cast"],
	"ASH_MEND":["ASH_MARSHAL","UNDEAD","judgement_scythe","docket_scythe_fan","low_crescent_sweep","folded_docket>low_scythe>paper_ash","","docket","缺角判杖挥出案卷形成的钝镰；不是额外实体武器。","远离真实扇面，抓住冷却空档；无全周伤害。","CONE_ROOT_MIXED; preserve target cap, drain and falloff"],
	"MOURN_BIND":["MOURN_ORACLE","UNDEAD","soul_chain","shutter_knots","sink_three_knots","shutters_close>knots_sink>tethers_slacken","","chain","借来的眼证被灯罩分格，结扣只保留互不兼容的记忆。","纯定身不禁止攻击；不把锁结画成眩晕星。","PURE_CONTROL_AREA; zero damage and no prison collision"],
	"MOURN_FLARE":["MOURN_ORACLE","UNDEAD","soul_lantern","hollow_wisps","ascending_handoff","lamp_shutter>hollow_wisp>next_witness","","soul","灯匠借出多个视角，火焰空心处保留缺失面容。","分散限制真实连锁；后续目标按权威衰减。","CHAIN_DAMAGE; only settled targets, no ghost actors"],
	"MOURN_OATH":["MOURN_ORACLE","UNDEAD","soul_lantern","negative_soul_extraction","inward_unspool","mirror_split>single_pull>lamp_reclose","","extraction","一份证词被铜镜抽回；不用全场爆炸表达单体大招。","单体高价值施放可用距离和集火施法者制约。","SINGLE_DAMAGE_DRAIN; decorative shadow is not a clone"],
	"CINDER_SHOT":["CINDER_STALKER","UNDEAD","bone_bow","hollow_bone_arrow","straight_puncture","ribbon_draw>bone_shaft>powder_return","","bone_arrow","炭翎回收刻名骨箭，断掉的税带在弓尾摆动。","单目标箭不溅射；吸取以真实伤害为限。","SINGLE_PIERCE_DRAIN; no added projectile settlement"],
	"CINDER_FERVOR":["CINDER_STALKER","UNDEAD","bone_bow","smoldering_quiver","upward_split_flame","quiver_relight>split_ember_loop>embers_out","cinder_quiver","cinder","弃薪后留下的热羽沿弓臂、箭架燃起，不把整具骨架染白。","强化期脱离或控制；火焰不造成灼烧、范围伤害。","ATTACK_ENHANCEMENT; finite authoritative source_buffs expiry only"],
	"CINDER_MEND":["CINDER_STALKER","UNDEAD","bone_bow","contract_nail_arrow","single_pin_recoil","bent_nail_mark>heavy_pin>ash_receipt","","pin","她射断契约钉的旧事成为一次确定的追猎。","强单体爆点，不误导附近单位有范围风险。","SINGLE_EXECUTION; no additional slow, root or splash"],
	"ASH_LANTERN":["ASH_CHANTER","UNDEAD","ash_suture","caption_lantern","quiet_thread_breath","caption_edge>low_wick>caption_edge","","ash","巡演缝名师用字板让亡者重新选择角色。","治疗光环随权威来源和范围失效；不遮挡血条。","LEARNED_AURA; no fake timed enhancement"],
	"ASH_STITCH":["ASH_CHANTER","UNDEAD","ash_suture","two_warm_stitches","needle_weave","needle_turn>two_stitches>thread_withdraw","","ash","绣字长手套穿针，而非所有友军接受同一个绿色光球。","限定受益人数；粒子不能替未受疗单位报喜。","LIMITED_HEAL_CLEANSE; no overheal or continuous healing zone"],
	"ASH_REQUIEM":["ASH_CHANTER","UNDEAD","soul_lantern","unwritten_stage_lamps","staggered_lamp_rise","stage_flaps>lamps_answer>curtain_fold","","soul","归名者在旧戏箱前自己改写结局；安魂不是强迫归队。","大招有限目标和资源窗口；灯影不生成复活单位。","AREA_HEAL_CLEANSE; no summons or extra heal pulses"],
	"GRAVE_CADENCE":["GRAVE_BELL","UNDEAD","bell","silent_clapper","quiet_offbeat","suspended_clapper>quiet_gap>late_spark","","bell","失听的钟校守护说话间的停顿。","低亮来源提示不等同付费主动强化。","LEARNED_AURA; do not attach finite self-buff timer"],
	"GRAVE_CHAIN":["GRAVE_BELL","UNDEAD","grave_hook","tuning_hook_links","weighted_hook_handoff","cord_draw>hook_links>links_fall","","chain","缠指校音绳变成有重量的钩节，锁住节拍而非拉走身体。","靠散开打断连锁覆盖；定身仍可攻击。","CHAIN_ROOT_DRAIN; no pull, displacement or wall"],
	"GRAVE_TOLL":["GRAVE_BELL","UNDEAD","bell","broken_silent_bell","negative_bell_drop","black_bell_shadow>mute_clapper>late_gold_dust","","bell","钟身缺口在光里更清晰，真正的强度是留住一段无声停顿。","零伤群控；可以攻击或施法，不暗示沉默。","PURE_CONTROL_AREA_ROOT; no stun, silence or damage"],
	"TUNNEL_SHOCK":["TUNNEL_SENTINEL","UNDERGROUND","shovel","mud_spade_patch","scoop_inward","spade_lift>soil_patch>shell_close","","spade","背着旧门搬巢的壳车，用宽掘铲把泥壳压回裂隙。","有限自疗；飞起泥块不攻击周围单位。","SELF_HEAL_CLEANSE; no damage ring or new shield"],
	"TUNNEL_WARD":["TUNNEL_SENTINEL","UNDERGROUND","chitin_bastion","station_platform_shell","passive_layer_settle","shell_overlap>quiet_joint>shell_overlap","","shell","中空站台背甲保护可自行离开的幼群。","有条件光环只对实际合阵友军生效。","LEARNED_PASSIVE_CONDITIONAL_AURA; no timed spell"],
	"TUNNEL_MEND":["TUNNEL_SENTINEL","UNDERGROUND","shovel","evacuation_berm","low_fan_soil_lift","spade_ground>berm_fan>rubble_settle","","spade","旧石门不再关人，扬起的是撤离通道外的碎壳土脊。","真实扇面内控场；土脊不阻挡寻路。","CONE_ROOT_MIXED; no impassable wall or burrow teleport"],
	"ECHO_BIND":["ECHO_BINDER","UNDERGROUND","crystal_lance","echo_knots","folded_echo_handoff","fork_tap>offset_knots>returning_dust","","crystal","晶听者把过多回声折成几个可理解的节点。","真实连锁目标分散反制；不把弧带当圆形全覆盖。","CHAIN_ROOT_DOT; complete poison budget and target cap unchanged"],
	"ECHO_FLARE":["ECHO_BINDER","UNDERGROUND","crystal_lance","split_crystal_ray","forward_refraction","fork_align>angular_ray>side_shards","","crystal","开裂共鸣杖以折角晶尘测绘，不画另一条通用激光。","窄直线有方向与侧面留白；碎片不另伤目标。","LINE_DAMAGE_DOT; no width increase from decorative shards"],
	"ECHO_OATH":["ECHO_BINDER","UNDERGROUND","crystal_lance","hollow_crystal_implosion","inward_prism_collapse","asymmetric_prisms>one_core_collapse>fine_dust","","implosion","她烧掉完美地图后留下的空白，在单个目标处收拢成核。","单体内爆不是群体爆炸；结算后毒伤有限。","SINGLE_DAMAGE_DOT; no suction, splash or area slow"],
	"SPORE_SEAL":["SPORE_STALKER","UNDERGROUND","mantis_blades","asymmetric_pincer_lock","opposed_blade_close","small_feint>large_pincer>held_notch","","mantis","一大一小矿刃夹定关节；适应不等于无差别杀伤。","纯眩晕不带伤害或旧毒；完整时长读权威状态。","PURE_CONTROL_SINGLE_STUN; decorative blades deal zero damage"],
	"SPORE_SWEEP":["SPORE_STALKER","UNDERGROUND","mantis_blades","mining_shear_crosscut","one_target_crosscut","short_notch>long_shear>husk_chip","","mantis","试剂臂指示岩缝，矿刃剪断一处薄弱面而非全周旋风。","单体技能不能用360度刃环误报范围伤害。","SINGLE_EDGE_EXECUTION; no spin damage to other bodies"],
	"SPORE_MEND":["SPORE_STALKER","UNDERGROUND","mantis_blades","luminous_mantis_molt","alternating_husk_slip","arm_veins>offset_husk_loop>husk_dissolve","mantis_molt","molt","菌丝改写感官轨迹：矿刃外套壳、菌纹发光，影痕贴地错开。","强化者仍可被攻击；残相不表示隐身、免伤、分身或传送。","ATTACK_ENHANCEMENT; finite source-owned expiry, no added mobility mechanic"],
	"SPORE_GLOW":["SPORE_GUIDE","UNDERGROUND","spore_sieve","partitioned_culture_lights","quiet_spore_breath","jar_slits>low_spores>jar_slits","","sieve","分格菌罐保留每户味道，菌群不被画成一种全族意识。","光环存在性和受益范围跟随实际来源。","LEARNED_HEAL_AURA; no finite attack-buff glow"],
	"SPORE_REMEDY":["SPORE_GUIDE","UNDERGROUND","spore_sieve","sieve_spore_bundles","gentle_sieved_fall","sieve_tilt>grouped_drops>mycelium_sink","","sieve","酿师用长柄筛勺分配不同共生物；是筛落，不是同心圈爆开。","有限受益者才出现完整孢束；净化不复活。","LIMITED_HEAL_CLEANSE; no poison or infinite ground heal"],
	"SPORE_HAVEN":["SPORE_GUIDE","UNDERGROUND","spore_sieve","porous_canopy","layered_cap_unfold","jar_fan>porous_caps>low_spore_trails","","molt","庇所保留多个可退出菌室，花伞间有清晰留白。","治疗和附带移速读真实来源状态；不伪造攻击强化。","AREA_HEAL_WITH_FINITE_SPEED; preserve actual recipient scope"],
	"QUAKE_RHYTHM":["QUAKE_PRIEST","UNDERGROUND","fault_pick","layer_page_metronome","quiet_lateral_offset","stone_page>short_shift>quiet_gap","","fault","层页石册记路权，不崇拜整齐的震动。","移速光环不额外传送；不用永久强烈地震。","LEARNED_MOVE_AURA; no fake timed cast"],
	"QUAKE_SNARE":["QUAKE_PRIEST","UNDERGROUND","fault_pick","three_offset_faults","lateral_pin","blunt_pick_tap>offset_fault_clamp>dust_sink","","fault","钝头短镐敲开旧边界；错层夹缝阻止行走但不伤害。","纯定身零伤、无旧毒；地裂不改变碰撞。","PURE_CONTROL_AREA_ROOT; no damage, poison or terrain mutation"],
	"QUAKE_SEAL":["QUAKE_PRIEST","UNDERGROUND","fault_pick","broken_boundary_seal","staggered_slab_inward","stone_pages_open>fault_seal>graded_dust","","seal","断层契约被敲碎后重排；新水脉穿过旧界仍留下余震。","真实范围/人数封顶；岩页不封路、不暗示永久区域。","AREA_ROOT_DAMAGE_DOT; keep existing poison budget, not extra ground pulses"],
}

static func profile(skill_id: String) -> Dictionary:
	if not ENTRIES.has(skill_id): return {}
	var row: Array = ENTRIES[skill_id]
	return {"skill_id":skill_id,"hero_id":row[0],"faction_id":row[1],"weapon_family":row[2],"motif":row[3],"motion":row[4],"phase_signature":row[5],"persistent_motif":row[6],"palette":PALETTES[row[7]].duplicate(true),"story_anchor":row[8],"counterplay":row[9],"budget_guard":row[10],"identity_version":VERSION}

static func profiles() -> Dictionary:
	var result := {}
	for skill_id: String in ENTRIES: result[skill_id] = profile(skill_id)
	return result
