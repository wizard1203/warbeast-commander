extends RefCounted
## Authored visual identities only. No combat numbers, timers, target decisions,
## random sampling or writable cache; the authority remains the merged catalog.
const VERSION := "m61-human-machine-weapon-identities-v1"
const HEROES := {
	"COMMANDER":["HUMAN","oath_standard"],
	"BULWARK":["HUMAN","gate_shield"],
	"ARCANIST":["HUMAN","prism_array"],
	"RANGER":["HUMAN","kite_longbow"],
	"DUELIST":["HUMAN","contract_blade"],
	"COIL_WARDEN":["MACHINE","pressure_ram"],
	"VOLT_WEAVER":["MACHINE","tesla_shuttle"],
	"GEAR_HUNTER":["MACHINE","rivet_carbine"],
	"COIL_MEDIC":["MACHINE","resin_welder"],
	"SIGNAL_KEEPER":["MACHINE","signal_array"],
}
## Ink / shadow / body / contrasting material / hot core / afterglow / metal.
## Separate skill scores avoid a universal faction color or shared hero tint.
const PALETTES := {
	"oath_cloth":["15191e","594536","caa571","69bcb5","fff0c4","d57b80","aeb6b4"],
	"oath_mend":["161e21","435c61","81bfc2","e7aa83","fff7d7","b5a4cf","b8c4ac"],
	"oath_standard":["21191f","773e50","d87986","70c6c1","fff0ae","dab574","b6c6c2"],
	"gate_timbers":["1b1a1b","695343","be9d6f","81b8cf","fff0c7","b598ce","a9b7b3"],
	"gate_iron":["141c25","3a5269","82adc2","d8a25f","fff3c7","b78aac","bdc7ad"],
	"gate_piles":["201a24","61506e","ad94cf","d6b76c","fff5ce","7cc0b7","9eacb5"],
	"prism_fan":["181725","57416d","b28cdb","edb75e","fff7da","7dd0bf","bd8b86"],
	"prism_clamp":["141b25","37596e","76bfd6","d18ab7","f3ffeb","ecbc76","9aa5bd"],
	"prism_execution":["171426","4b3677","9e75de","edc35f","fff9da","73d2d1","d599bc"],
	"kite_lance":["141b1c","395851","81b4a1","dfa274","fff4cc","ab8bd4","b8c7c0"],
	"kite_rain":["161c24","3d526b","80b6d5","e8b15d","ffedbf","c78aa4","a5b3aa"],
	"kite_overdraw":["21151e","71374b","d8777e","83bfdd","fff2bd","d8ad64","b1c1b3"],
	"contract_walk":["1c2020","4d6260","a4c0ab","c694a6","fff2d5","b6a16f","9daac0"],
	"contract_clamp":["161c22","435467","a1b7ca","dc7e68","fff4d2","90c3b4","c6ad75"],
	"contract_verdict":["21151f","743544","cc647b","87c6d4","fff0c3","ad95da","bd9d70"],
	"pressure_repair":["201b1a","72513c","cd975f","83c2b9","fff2c3","b99dcb","aabbb5"],
	"pressure_anchor":["19211e","475d4e","91b693","d9a96e","fff4c9","91a7d1","b4c2ba"],
	"pressure_gate":["141d24","31546d","6badd0","e49b65","f2f7d4","bb8bcd","a8baac"],
	"tesla_clamp":["1d1b20","726437","dbc15c","aa86d4","fff9da","6dbecb","c79275"],
	"tesla_shuttle":["131f24","2d5c70","6ac3d9","e68b83","f3fff0","c5a257","ad9bcb"],
	"tesla_switchyard":["1b1729","4f3b7e","9b7bd6","79d2b1","fff3d0","e1aa69","8faac3"],
	"carbine_shell":["21191c","704236","ca7456","73aace","fff1bc","b39ad3","b8baa3"],
	"carbine_rotor":["1b201a","59663d","a3b95e","ce86bd","fff0c4","80bed3","bba382"],
	"carbine_piercer":["161d25","3e516d","7aa0c8","efaa62","fff5cb","bc87ae","a7c4b3"],
	"welder_battery":["19211f","4c6557","9dbf87","ce97a9","fff5ce","82bcd0","bfb48c"],
	"welder_mend":["191b1c","664d3e","c98c5a","76d0b8","fff5cb","aa92cf","a8b9b7"],
	"welder_dock":["191e1b","4a5b44","8db077","db8c77","fff2bd","80bcd0","c4b995"],
	"signal_march":["172027","415a73","88b6d0","d4a76a","fff5cd","b994bf","a6b9ac"],
	"signal_lock":["23191e","7a4351","d88891","82c9bd","fff0bf","ba9ad7","bcad89"],
	"signal_blackout":["1b1723","514368","a28ac4","ddb568","fff4d1","6bbbc3","c49a88"],
}
## hero, motif, motion, phase signature, finite-buff motif, palette, story,
## counterplay, authority guard. Passive rows remain useful to the codex but
## must never spawn active casts or finite-duration enhancement effects.
const ROWS := {
	"CLEAVE":["COMMANDER","folded_standard","hinged_cloth","fold_hold_unfurl","","oath_cloth","渡口账房把公共欠账折成可归还的军旗。","绕开盟友覆盖，迫使部队分散。","AURA；非伤害斩击；不制造命中或限时强化。"],
	"RECOVER":["COMMANDER","porcelain_stitch","interleaved_lacing","lift_stitch_settle","oath_blades","oath_mend","撕开航图救人后，用青瓷线补回口述的支流。","消耗蓝量，分割治疗目标；缝线只连真实受益者。","HEAL＋有限 ally_guard；治疗和护甲各取真实状态，非普攻强化。"],
	"RALLY":["COMMANDER","witness_standards","cloth_relay","stamp_raise_shelter","oath_blades","oath_standard","各镇借来的印章组成守望旗架，而非王冠圣光。","越过共同防线，或等待防护到期。","HEAL＋有限 ally_guard；不是旧版 effect=RALLY，不添加攻击力。"],
	"SHIELD_SHOCK":["BULWARK","loadbearing_wedges","inward_bracing","brace_fit_release","","gate_timbers","闸门盾来自架梁棚，以木楔和铁钩重整受力。","恢复不阻止敌军继续集火；不绘制敌人受伤。","真实 HEAL 自身恢复；旧 ID 不代表盾击或眩晕。"],
	"BULWARK_WARD":["BULWARK","gate_buttresses","low_static_support","settled_breath","","gate_iron","守桥者先留撤离通路，再让巨盾承重。","绕背或以克制护甲的攻击施压。","PASSIVE_GUARD；常驻条件反馈，不伪造有限持续时间。"],
	"BULWARK_RECOVER":["BULWARK","gate_pile_driver","paired_pile_drop","lift_drop_woodlock","","gate_piles","把闸门承重法用于钉住阵前通路，盾后仍留出口。","散开避免被区域眩晕；范围外没有木桩命中。","零伤纯控大招 AREA；不增加地刺伤害或地形碰撞。"],
	"STARFIRE":["ARCANIST","prism_fan","refracted_fan","glass_align_split","","prism_fan","河口磨镜师拒绝预言，用破镜测量不同角度。","分散扇面与贴近脆弱施法者；不得画成全圆爆炸。","CONE 最多四目标；无额外碎片伤害。"],
	"FROST_BIND":["ARCANIST","mirror_calipers","opposed_plane_clamp","measure_close_hold","","prism_clamp","测角架锁住一条错误航线，冷凝在镜片边缘。","定身仍能攻击施法；不画眩晕符号。","SINGLE 零伤 ROOT；夹片仅对应真实目标。"],
	"ARCANE_BURST":["ARCANIST","falling_prism_lance","convergent_lens","refract_focus_pierce","","prism_execution","把被砸碎的预言镜聚成一束可验证的星核轨迹。","避免单个关键单位暴露；单体不得冒充大范围清场。","SINGLE 混合伤害＋减速大招；视觉折光不新增弹道反弹。"],
	"PIERCING_SHOT":["RANGER","feather_lance","taut_straightline","draw_arrow_release","","kite_lance","港区药单纸鸢的骨架制成穿阵长弓。","从窄射线两侧分散；箭尾不扩大实际线宽。","LINE 最多四目标；一个箭身，不伪造散射目标。"],
	"ARROW_RAIN":["RANGER","rain_stakes","staggered_descent","kite_lift_rain_embed","","kite_rain","纸鸢把药单送过封航线；战时垂下雨箭标桩。","离开落箭区域，利用较长冷却。","AREA 最多五目标；雨箭是同次命中演出，无额外跳伤。"],
	"QUICKDRAW":["RANGER","kite_overdraw","elastic_feather_return","unfold_sustain_refold","oath_blades","kite_overdraw","巡翎终于不再丢下回信，把纸鸢尾张成持续绷紧的弦翼。","逼迫停火或撤离射程，等待强化窗口结束。","SELF DAMAGE_BUFF 大招；12/14秒读取真实独立来源，不凭施法残影续期。"],
	"SEAL_STRIKE":["DUELIST","ruler_march","measured_footfall","measure_step_release","","contract_walk","船厂调解员把起重队口令编成无刃行阵节拍。","切断友军阵线，不在光环外显示受益。","AURA 行阵；不是旧版封刃伤害。"],
	"WHIRLWIND":["DUELIST","ruler_sword_clamp","crossed_blade_stop","measure_cross_lock","","contract_clamp","量尺剑未开锋；先封住刀，再让证人说完。","单体控制可被其他部队掩护；不能误示旋风范围伤害。","SINGLE 零伤 STUN；只有真实命中目标获得封刀印。"],
	"BLOOD_PACT":["DUELIST","contract_blade_fence","descending_seal_slips","unroll_sign_bind","","contract_verdict","停战条款化为断续尺剑与印章条，守住证人发言的区域。","定身仍允许还击；不把纸剑做成实体墙。","AREA 零伤 ROOT 大招；无新增伤害、阻挡或召唤物。"],
	"COIL_SHOCK":["COIL_WARDEN","pressure_piston_patch","inward_piston_return","vent_press_seal","","pressure_repair","第十一副承重机体打开可检修的压力阀，而不宣称永远正确。","恢复期间仍可受伤；不给敌军绘制电击。","HEAL＋净化DoT；不是旧版连锁伤害。"],
	"COIL_WARD":["COIL_WARDEN","magnetic_braces","planted_relay","plant_settle_conduct","","pressure_anchor","宽厚磁靴让工坊争论时仍有共同承重的地面。","移动打破驻地条件；机械攻速光环需真实达成条件。","PASSIVE_GUARD；条件光环不变，非有限爆发。"],
	"COIL_REPAIR":["COIL_WARDEN","magnetic_gate_clamps","relay_gate_snap","charge_clamp_echo","","pressure_gate","主动交还否决权的监工以磁闸暂时止住攻势。","隔开目标切断连锁；不是群体维修或伤害冲击。","CHAIN 零伤 STUN 大招，最多三目标；无额外磁力位移。"],
	"VOLT_BIND":["VOLT_WEAVER","electrode_clamp","taut_copper_stitch","pause_tension_snap","","tesla_clamp","织机调音学徒把每次停顿积成可计量的蓄压。","单体混合控制；没有命中的附近敌人不生成电极。","SINGLE 伤害＋STUN；电缆末端只落真实目标。"],
	"VOLT_ARC":["VOLT_WEAVER","stitched_arc","shuttle_hop","weave_skip_return","","tesla_shuttle","断纱记录被织成可拆的线路，电弧像穿梭织梭。","分散降低连锁总量；后续目标保留权威衰减。","CHAIN 最多四目标；每段只演真实连锁，非全屏随机雷。"],
	"VOLT_NETWORK":["VOLT_WEAVER","switchyard_fork","asymmetric_switchyard","coil_open_branch_ground","","tesla_switchyard","错拍停电暴露伪造夜班；大招让每条支线显出接续关系。","分散打断高覆盖收益，减速不冒充眩晕。","CHAIN 混合伤害＋SLOW 大招；不得添加全屏接地伤害。"],
	"GEAR_SHOT":["GEAR_HUNTER","shell_drill","recoil_drill","latch_flash_drill","","carbine_shell","零件不配套的轮弩用带回收印的铆钉弹确认目标。","以其他单位掩护破甲目标；弹壳不是第二发子弹。","SINGLE 火药伤害＋ARMOR_BREAK；非多发散射。"],
	"GEAR_FERVOR":["GEAR_HUNTER","ratchet_overdrive","ratchet_spin_vent","spool_sustain_brake","rotor_exhaust","carbine_rotor","不等径轮盘加速，废票弹仓锁扣逐个亮起，仍优先把人领走。","停火与撤离消耗8/9/10秒窗口；不能无限延续。","SELF DAMAGE_BUFF 普通技能；来源独立到期，排汽不遮蔽枪口方向。"],
	"GEAR_REPAIR":["GEAR_HUNTER","armor_piercer","heavy_breech_release","sight_lock_breech_break","","carbine_piercer","为救维修学徒曾砸掉高价核心，如今锁弹只为破开挡路钢甲。","单个关键单位保留掩护；大弹头不伪造AOE。","SINGLE 火药伤害＋ARMOR_BREAK 大招；不是旧版SELF强化或治疗。"],
	"COIL_BATTERY":["COIL_MEDIC","insulated_heat_tabs","alternating_warmth","idle_tab_breath","","welder_battery","夜班修理车的保温箱以固定绝缘片分享安全。","拉开维修者与机械前线，不对未受益单位显示光环。","AURA 护甲；不凭图标创造MP回复。"],
	"COIL_MEND":["COIL_MEDIC","resin_weld","falling_amber_beads","hose_lift_weld_cool","","welder_mend","树脂焊枪与保温炉背箱是暖轨师的工作工具。","隔断维修射程，非机械目标不显示假修复。","HEAL 自身＋最多两名机械友军；不新增持续回血。"],
	"COIL_OVERHAUL":["COIL_MEDIC","repair_dock","offset_jack_stands","dock_raise_weld_lower","","welder_dock","拆掉车灯也要给夜班工人热汤；临时检修坞分区开合。","分散迫使少目标维修取舍；不绘制全军无差别治疗。","HEAL＋净化DoT，最多三名机械友军；没有额外护甲持续增益。"],
	"SIGNAL_MARCH":["SIGNAL_KEEPER","semaphore_steps","two_way_flag","flag_confirm_step","","signal_march","失聪线路官用针盘和双向旗板让军令可以被质疑。","迫使部队分散离开信标；节拍不伪装瞬移。","AURA 百分比移速；不制造额外攻击效果。"],
	"SIGNAL_LOCK":["SIGNAL_KEEPER","circuit_cutters","right_angle_cut","send_receive_cut","","signal_lock","误码救援后，每条命令都必须保留可返回的确认线路。","隔开连锁目标，避免集群被无伤断路。","CHAIN 零伤 STUN；断路亮点不是弹药爆炸。"],
	"SIGNAL_BLACKOUT":["SIGNAL_KEEPER","semaphore_cage","opposed_shutters","raise_cross_extinguish","","signal_blackout","针盘失去回执时，断开式电缆带围成可读的封锁扇页。","离开区域；只眩晕实际命中对象，不隐藏可见性。","AREA 零伤 STUN 大招；不是致盲、隐身或战争迷雾效果。"],
}

static func profiles() -> Dictionary:
	var result := {}
	for skill_id: String in ROWS:
		result[skill_id] = profile(skill_id)
	return result

static func profile(skill_id: String) -> Dictionary:
	if not ROWS.has(skill_id):
		return {}
	var row: Array = ROWS[skill_id]
	var owner: Array = HEROES[str(row[0])]
	return {"skill_id":skill_id,"hero_id":str(row[0]),"faction_id":str(owner[0]),"weapon_family":str(owner[1]),"motif":str(row[1]),"motion":str(row[2]),"phase_signature":str(row[3]),"persistent_motif":str(row[4]),"palette":PALETTES[str(row[5])].duplicate(true),"story_anchor":str(row[6]),"counterplay":str(row[7]),"budget_guard":str(row[8]),"identity_version":VERSION}
