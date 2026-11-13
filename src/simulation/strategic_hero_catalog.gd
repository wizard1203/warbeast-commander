extends RefCounted
const Progression = preload("res://src/simulation/strategic_progression_catalog.gd")
const Traits = preload("res://src/simulation/strategic_combat_traits.gd")
const DamageRules = preload("res://src/simulation/strategic_damage_rules.gd")
const HeroProgression = preload("res://src/simulation/strategic_hero_progression.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const Innates = preload("res://src/simulation/strategic_hero_innates.gd")
const SkillVariety = preload("res://src/simulation/strategic_hero_skill_variety.gd")
const IdentityM67 = preload("res://src/simulation/strategic_hero_identity_m67.gd")
const ExpansionM66 = preload("res://src/simulation/strategic_hero_expansion_m66.gd")
const MagesM68 = preload("res://src/simulation/strategic_hero_mages_m68.gd")
const RolesM68 = preload("res://src/simulation/strategic_hero_roles_m68.gd")
const CalibrationM68 = preload("res://src/simulation/strategic_hero_calibration_m68.gd")
const PowerM69 = preload("res://src/simulation/strategic_hero_power_m69.gd")
const BudgetsM70 = preload("res://src/simulation/strategic_hero_budgets_m70.gd")
const TuningM71 = preload("res://src/simulation/strategic_hero_tuning_m71.gd")
const ReworkR7 = preload("res://src/simulation/strategic_hero_rework_r7_catalog.gd")
## Shared original fixed-tick hero and item rules. Observations are detached;
## authority, UI and the computer read these same numbers and descriptions.

const DEFAULT_ARCHETYPE := "COMMANDER"
const MAX_ACTIVE_HEROES := 3
const MAX_LEVEL := HeroProgression.MAX_LEVEL
const MAX_SKILL_LEVEL := 3
const MANA_REGEN_TICKS := 10
const MAXIMUM_MANA := {"COMMANDER":120,"BULWARK":100,"ARCANIST":180,"RANGER":120,"DUELIST":100,"ASH_MARSHAL":100,"MOURN_ORACLE":180,"CINDER_STALKER":120,"COIL_WARDEN":100,"VOLT_WEAVER":180,"GEAR_HUNTER":120,"VINE_WARDEN":100,"LEAF_SEER":180,"WIND_COURIER":120,"RIDGE_JARL":100,"RUNE_ORACLE":180,"EMBER_CAVALIER":100,"TUNNEL_SENTINEL":100,"ECHO_BINDER":180,"SPORE_STALKER":100}
const SKILL_MANA_COSTS := {"DAMAGE":20,"HEAL":25,"RALLY":15,"ARMOR_BUFF":15,"DAMAGE_BUFF":15,"STUN":30,"ROOT":30,"AURA":0,"PASSIVE_GUARD":0}
const ARCHETYPES := ["COMMANDER","BULWARK","ARCANIST","RANGER","DUELIST","ASH_MARSHAL","MOURN_ORACLE","CINDER_STALKER","COIL_WARDEN","VOLT_WEAVER","GEAR_HUNTER","VINE_WARDEN","LEAF_SEER","WIND_COURIER","RIDGE_JARL","RUNE_ORACLE","EMBER_CAVALIER","TUNNEL_SENTINEL","ECHO_BINDER","SPORE_STALKER","ASH_CHANTER","GRAVE_BELL","COIL_MEDIC","SIGNAL_KEEPER","BLOOM_GUIDE","THORN_CHANTER","HEARTH_KEEPER","STORM_HERALD","SPORE_GUIDE","QUAKE_PRIEST"] + ExpansionM66.IDS + MagesM68.IDS
const LEGACY_PROFILES := {
	"COMMANDER": {"id":"COMMANDER", "name":"绛栖", "ai_name":"穆桥", "title":"誓图师", "ai_title":"桥铸师", "role":"均衡长官", "description":"近战长官；范围斩击、自我恢复与友军盟誓。", "stats":{"label":"英雄长官", "max_hp":540, "damage":18, "armor":2, "attack_range":46, "attack_cooldown_ticks":18, "speed":7, "radius":14, "population":Progression.POPULATION.hero}, "skill_ids":["CLEAVE","RECOVER","RALLY"]},
	"BULWARK": {"id":"BULWARK", "name":"岩岚", "title":"垒盾长官", "role":"坦克", "description":"高生命与护甲的前排；盾震短暂眩晕敌人，护垒强化自身护甲。", "stats":{"label":"垒盾长官", "max_hp":720, "damage":12, "armor":4, "attack_range":46, "attack_cooldown_ticks":20, "speed":5, "radius":14, "population":Progression.POPULATION.hero}, "skill_ids":["SHIELD_SHOCK","BULWARK_WARD","BULWARK_RECOVER"]},
	"ARCANIST": {"id":"ARCANIST", "name":"星澜", "title":"星契术师", "role":"法师·控制输出", "description":"脆弱的远程范围法师；霜契定身阻止移动，但不能阻止目标攻击或施技。", "stats":{"label":"星契术师", "max_hp":360, "damage":16, "armor":0, "attack_range":180, "attack_cooldown_ticks":24, "speed":6, "radius":14, "population":Progression.POPULATION.hero}, "skill_ids":["STARFIRE","FROST_BIND","ARCANE_BURST"]},
	"RANGER": {"id":"RANGER", "name":"巡翎", "title":"巡弦游侠", "role":"射手·远程输出", "description":"射程最长的英雄；贯弦集中伤害，箭雨覆盖范围，急弦提高自身普攻。", "stats":{"label":"巡弦游侠", "max_hp":435, "damage":17, "armor":1, "attack_range":220, "attack_cooldown_ticks":18, "speed":7, "radius":14, "population":Progression.POPULATION.hero}, "skill_ids":["PIERCING_SHOT","ARROW_RAIN","QUICKDRAW"]},
	"DUELIST": {"id":"DUELIST", "name":"砺川", "title":"断契刃客", "role":"近战·控制输出", "description":"高速近战输出；封刃造成短暂眩晕，回旋清理近处敌人，血契恢复自身。", "stats":{"label":"断契刃客", "max_hp":495, "damage":22, "armor":1, "attack_range":46, "attack_cooldown_ticks":16, "speed":8, "radius":14, "population":Progression.POPULATION.hero}, "skill_ids":["SEAL_STRIKE","WHIRLWIND","BLOOD_PACT"]},
	"ASH_MARSHAL": {"id":"ASH_MARSHAL","faction_id":"UNDEAD","name":"灰烬统领","title":"灰誓统领","role":"坦克·续战","description":"灰誓统领；坦克·续战。","body_kind":"HEAVY_BONE","attack_layers":["GROUND"],"stats":{"label":"灰誓统领","max_hp":705,"damage":13,"armor":3,"attack_range":46,"attack_cooldown_ticks":22,"speed":5,"radius":14,"population":5},"skill_ids":["ASH_SHOCK","ASH_WARD","ASH_MEND"]},
	"MOURN_ORACLE": {"id":"MOURN_ORACLE","faction_id":"UNDEAD","name":"哀灯","title":"烬语者","role":"法师·控制","description":"烬语者；法师·控制。","body_kind":"BONE","attack_layers":["GROUND","AIR"],"stats":{"label":"烬语者","max_hp":375,"damage":15,"armor":0,"attack_range":180,"attack_cooldown_ticks":24,"speed":5,"radius":14,"population":5},"skill_ids":["MOURN_BIND","MOURN_FLARE","MOURN_OATH"]},
	"CINDER_STALKER": {"id":"CINDER_STALKER","faction_id":"UNDEAD","name":"炭翎","title":"骨弦猎手","role":"射手·续战","description":"骨弦猎手；射手·续战。","body_kind":"BONE","attack_layers":["GROUND","AIR"],"stats":{"label":"骨弦猎手","max_hp":450,"damage":18,"armor":1,"attack_range":205,"attack_cooldown_ticks":20,"speed":6,"radius":14,"population":5},"skill_ids":["CINDER_SHOT","CINDER_FERVOR","CINDER_MEND"]},
	"COIL_WARDEN": {"id":"COIL_WARDEN","faction_id":"MACHINE","name":"铆冠","title":"炉盾监工","role":"坦克·机械","description":"炉盾监工；坦克·机械。","body_kind":"MACHINE","attack_layers":["GROUND"],"stats":{"label":"炉盾监工","max_hp":735,"damage":12,"armor":4,"attack_range":46,"attack_cooldown_ticks":22,"speed":4,"radius":14,"population":5},"skill_ids":["COIL_SHOCK","COIL_WARD","COIL_REPAIR"]},
	"VOLT_WEAVER": {"id":"VOLT_WEAVER","faction_id":"MACHINE","name":"脉澜","title":"电弧织师","role":"法师·眩晕","description":"电弧织师；法师·眩晕。","body_kind":"MACHINE","attack_layers":["GROUND","AIR"],"stats":{"label":"电弧织师","max_hp":405,"damage":17,"armor":1,"attack_range":190,"attack_cooldown_ticks":26,"speed":5,"radius":14,"population":5},"skill_ids":["VOLT_BIND","VOLT_ARC","VOLT_NETWORK"]},
	"GEAR_HUNTER": {"id":"GEAR_HUNTER","faction_id":"MACHINE","name":"齿影","title":"齿轮猎手","role":"射手·机械","description":"齿轮猎手；射手·机械。","body_kind":"MACHINE","attack_layers":["GROUND","AIR"],"stats":{"label":"齿轮猎手","max_hp":465,"damage":19,"armor":2,"attack_range":215,"attack_cooldown_ticks":22,"speed":6,"radius":14,"population":5},"skill_ids":["GEAR_SHOT","GEAR_FERVOR","GEAR_REPAIR"]},
	"VINE_WARDEN": {"id":"VINE_WARDEN","faction_id":"FOREST","name":"枝垒","title":"藤垒守望","role":"坦克·森林","description":"藤垒守望；坦克·森林。","body_kind":"HUMANOID","attack_layers":["GROUND"],"stats":{"label":"藤垒守望","max_hp":660,"damage":13,"armor":3,"attack_range":46,"attack_cooldown_ticks":20,"speed":6,"radius":14,"population":5},"skill_ids":["VINE_SHOCK","VINE_WARD","VINE_MEND"]},
	"LEAF_SEER": {"id":"LEAF_SEER","faction_id":"FOREST","name":"芽灯","title":"根语祭师","role":"法师·定身","description":"根语祭师；法师·定身。","body_kind":"HUMANOID","attack_layers":["GROUND","AIR"],"stats":{"label":"根语祭师","max_hp":360,"damage":14,"armor":0,"attack_range":190,"attack_cooldown_ticks":24,"speed":7,"radius":14,"population":5},"skill_ids":["LEAF_BIND","LEAF_FLARE","LEAF_OATH"]},
	"WIND_COURIER": {"id":"WIND_COURIER","faction_id":"FOREST","name":"风翎","title":"风叶巡狩","role":"射手·机动","description":"风叶巡狩；射手·机动。","body_kind":"HUMANOID","attack_layers":["GROUND","AIR"],"stats":{"label":"风叶巡狩","max_hp":405,"damage":18,"armor":0,"attack_range":235,"attack_cooldown_ticks":18,"speed":8,"radius":14,"population":5},"skill_ids":["WIND_SHOT","WIND_FERVOR","WIND_MEND"]},
	"RIDGE_JARL": {"id":"RIDGE_JARL","faction_id":"HIGHLAND","name":"崖盾","title":"山誓领主","role":"坦克·重甲","description":"山誓领主；坦克·重甲。","body_kind":"HUMANOID","attack_layers":["GROUND"],"stats":{"label":"山誓领主","max_hp":780,"damage":14,"armor":4,"attack_range":46,"attack_cooldown_ticks":24,"speed":4,"radius":14,"population":5},"skill_ids":["RIDGE_SHOCK","RIDGE_WARD","RIDGE_MEND"]},
	"RUNE_ORACLE": {"id":"RUNE_ORACLE","faction_id":"HIGHLAND","name":"符炉","title":"符炉术师","role":"法师·控制","description":"符炉术师；法师·控制。","body_kind":"HUMANOID","attack_layers":["GROUND","AIR"],"stats":{"label":"符炉术师","max_hp":450,"damage":16,"armor":1,"attack_range":175,"attack_cooldown_ticks":26,"speed":5,"radius":14,"population":5},"skill_ids":["RUNE_BIND","RUNE_FLARE","RUNE_OATH"]},
	"EMBER_CAVALIER": {"id":"EMBER_CAVALIER","faction_id":"HIGHLAND","name":"焰脊","title":"烬刃骑长","role":"近战·控制","description":"烬刃骑长；近战·控制。","body_kind":"HUMANOID","attack_layers":["GROUND"],"stats":{"label":"烬刃骑长","max_hp":555,"damage":23,"armor":2,"attack_range":48,"attack_cooldown_ticks":18,"speed":8,"radius":14,"population":5},"skill_ids":["EMBER_SEAL","EMBER_SWEEP","EMBER_MEND"]},
	"TUNNEL_SENTINEL": {"id":"TUNNEL_SENTINEL","faction_id":"UNDERGROUND","name":"壳巢","title":"穴甲督卫","role":"坦克·穴鸣","description":"穴甲督卫；坦克·穴鸣。","body_kind":"MULTILEG","attack_layers":["GROUND"],"stats":{"label":"穴甲督卫","max_hp":675,"damage":14,"armor":3,"attack_range":46,"attack_cooldown_ticks":20,"speed":6,"radius":14,"population":5},"skill_ids":["TUNNEL_SHOCK","TUNNEL_WARD","TUNNEL_MEND"]},
	"ECHO_BINDER": {"id":"ECHO_BINDER","faction_id":"UNDERGROUND","name":"回声","title":"回声缚师","role":"法师·控制","description":"回声缚师；法师·控制。","body_kind":"MULTILEG","attack_layers":["GROUND","AIR"],"stats":{"label":"回声缚师","max_hp":375,"damage":17,"armor":0,"attack_range":165,"attack_cooldown_ticks":22,"speed":7,"radius":14,"population":5},"skill_ids":["ECHO_BIND","ECHO_FLARE","ECHO_OATH"]},
	"SPORE_STALKER": {"id":"SPORE_STALKER","faction_id":"UNDERGROUND","name":"孢纹","title":"隙影刃客","role":"近战·控制","description":"隙影刃客；近战·控制。","body_kind":"MULTILEG","attack_layers":["GROUND"],"stats":{"label":"隙影刃客","max_hp":480,"damage":24,"armor":1,"attack_range":44,"attack_cooldown_ticks":16,"speed":9,"radius":14,"population":5},"skill_ids":["SPORE_SEAL","SPORE_SWEEP","SPORE_MEND"]},
	"ASH_CHANTER":{"id":"ASH_CHANTER","faction_id":"UNDEAD","name":"烬灯","title":"归名颂者","role":"辅助·光环回复","visual_archetype":"MOURN_ORACLE","body_kind":"BONE","stats":{"label":"归名颂者","max_hp":435,"damage":10,"armor":1,"attack_range":155,"attack_cooldown_ticks":26,"speed":5,"radius":14,"population":5},"skill_ids":["ASH_LANTERN","ASH_STITCH","ASH_REQUIEM"]},
	"GRAVE_BELL":{"id":"GRAVE_BELL","faction_id":"UNDEAD","name":"暮钟","title":"墓钟司仪","role":"辅助·光环控制","visual_archetype":"MOURN_ORACLE","body_kind":"BONE","stats":{"label":"墓钟司仪","max_hp":435,"damage":11,"armor":1,"attack_range":150,"attack_cooldown_ticks":26,"speed":5,"radius":14,"population":5},"skill_ids":["GRAVE_CADENCE","GRAVE_CHAIN","GRAVE_TOLL"]},
	"COIL_MEDIC":{"id":"COIL_MEDIC","faction_id":"MACHINE","name":"焊灯","title":"稳压医师","role":"辅助·光环回复","visual_archetype":"VOLT_WEAVER","body_kind":"MACHINE","stats":{"label":"稳压医师","max_hp":465,"damage":10,"armor":2,"attack_range":155,"attack_cooldown_ticks":28,"speed":5,"radius":14,"population":5},"skill_ids":["COIL_BATTERY","COIL_MEND","COIL_OVERHAUL"]},
	"SIGNAL_KEEPER":{"id":"SIGNAL_KEEPER","faction_id":"MACHINE","name":"讯衡","title":"信标巡检","role":"辅助·光环控制","visual_archetype":"GEAR_HUNTER","body_kind":"MACHINE","stats":{"label":"信标巡检","max_hp":450,"damage":11,"armor":1,"attack_range":165,"attack_cooldown_ticks":26,"speed":5,"radius":14,"population":5},"skill_ids":["SIGNAL_MARCH","SIGNAL_LOCK","SIGNAL_BLACKOUT"]},
	"BLOOM_GUIDE":{"id":"BLOOM_GUIDE","faction_id":"FOREST","name":"花汐","title":"花泉引路人","role":"辅助·光环回复","visual_archetype":"LEAF_SEER","body_kind":"HUMANOID","stats":{"label":"花泉引路人","max_hp":390,"damage":9,"armor":0,"attack_range":170,"attack_cooldown_ticks":26,"speed":7,"radius":14,"population":5},"skill_ids":["BLOOM_SPRING","BLOOM_TOUCH","BLOOM_SANCTUARY"]},
	"THORN_CHANTER":{"id":"THORN_CHANTER","faction_id":"FOREST","name":"棘歌","title":"荆棘咏者","role":"辅助·光环控制","visual_archetype":"LEAF_SEER","body_kind":"HUMANOID","stats":{"label":"荆棘咏者","max_hp":405,"damage":10,"armor":0,"attack_range":175,"attack_cooldown_ticks":26,"speed":7,"radius":14,"population":5},"skill_ids":["THORN_BREEZE","THORN_LASH","THORN_MAZE"]},
	"HEARTH_KEEPER":{"id":"HEARTH_KEEPER","faction_id":"HIGHLAND","name":"炉暖","title":"守炉祭师","role":"辅助·光环回复","visual_archetype":"RUNE_ORACLE","body_kind":"HUMANOID","stats":{"label":"守炉祭师","max_hp":480,"damage":10,"armor":2,"attack_range":150,"attack_cooldown_ticks":28,"speed":5,"radius":14,"population":5},"skill_ids":["HEARTH_WARMTH","HEARTH_MEND","HEARTH_REFUGE"]},
	"STORM_HERALD":{"id":"STORM_HERALD","faction_id":"HIGHLAND","name":"雷旌","title":"山歌传令使","role":"辅助·光环控制","visual_archetype":"RUNE_ORACLE","body_kind":"HUMANOID","stats":{"label":"山歌传令使","max_hp":465,"damage":12,"armor":1,"attack_range":155,"attack_cooldown_ticks":28,"speed":5,"radius":14,"population":5},"skill_ids":["STORM_CHANT","STORM_HAMMER","STORM_VERDICT"]},
	"SPORE_GUIDE":{"id":"SPORE_GUIDE","faction_id":"UNDERGROUND","name":"菌灯","title":"菌光引路者","role":"辅助·光环回复","visual_archetype":"ECHO_BINDER","body_kind":"MULTILEG","stats":{"label":"菌光引路者","max_hp":405,"damage":9,"armor":0,"attack_range":150,"attack_cooldown_ticks":24,"speed":7,"radius":14,"population":5},"skill_ids":["SPORE_GLOW","SPORE_REMEDY","SPORE_HAVEN"]},
	"QUAKE_PRIEST":{"id":"QUAKE_PRIEST","faction_id":"UNDERGROUND","name":"岩祷","title":"地鸣祭司","role":"辅助·光环控制","visual_archetype":"ECHO_BINDER","body_kind":"MULTILEG","stats":{"label":"地鸣祭司","max_hp":435,"damage":11,"armor":1,"attack_range":155,"attack_cooldown_ticks":24,"speed":6,"radius":14,"population":5},"skill_ids":["QUAKE_RHYTHM","QUAKE_SNARE","QUAKE_SEAL"]},
}
const SKILLS := {
	"SUNGLASS_FOLDED_RAY":MagesM68.SKILLS.SUNGLASS_FOLDED_RAY,"SUNGLASS_LIGHT_SHEAR":MagesM68.SKILLS.SUNGLASS_LIGHT_SHEAR,"SUNGLASS_FALLING_INDEX":MagesM68.SKILLS.SUNGLASS_FALLING_INDEX,
	"CINDER_LINGERING_CLAUSE":MagesM68.SKILLS.CINDER_LINGERING_CLAUSE,"CINDER_SCATTERED_PAGES":MagesM68.SKILLS.CINDER_SCATTERED_PAGES,"CINDER_FINAL_CODICIL":MagesM68.SKILLS.CINDER_FINAL_CODICIL,
	"FLUX_BORE_LANCE":MagesM68.SKILLS.FLUX_BORE_LANCE,"FLUX_RELAY_FORK":MagesM68.SKILLS.FLUX_RELAY_FORK,"FLUX_SATURATION_CORE":MagesM68.SKILLS.FLUX_SATURATION_CORE,
	"POLLEN_FIREFLY_FAN":MagesM68.SKILLS.POLLEN_FIREFLY_FAN,"POLLEN_LONE_COMET":MagesM68.SKILLS.POLLEN_LONE_COMET,"POLLEN_COMET_PROCESSION":MagesM68.SKILLS.POLLEN_COMET_PROCESSION,
	"OBSIDIAN_GLASS_POOL":MagesM68.SKILLS.OBSIDIAN_GLASS_POOL,"OBSIDIAN_CINDER_SEAM":MagesM68.SKILLS.OBSIDIAN_CINDER_SEAM,"OBSIDIAN_NIGHT_FAN":MagesM68.SKILLS.OBSIDIAN_NIGHT_FAN,
	"MYCELIAL_ACID_VEIN":MagesM68.SKILLS.MYCELIAL_ACID_VEIN,"MYCELIAL_ACID_KERNEL":MagesM68.SKILLS.MYCELIAL_ACID_KERNEL,"MYCELIAL_SPORE_DOWNPOUR":MagesM68.SKILLS.MYCELIAL_SPORE_DOWNPOUR,
	"OATH_NOTCH":ExpansionM66.SKILLS.OATH_NOTCH,"OATH_EDGE_PLEDGE":ExpansionM66.SKILLS.OATH_EDGE_PLEDGE,"OATH_LAST_WITNESS":ExpansionM66.SKILLS.OATH_LAST_WITNESS,
	"BRIDGE_CROSSBEAM":ExpansionM66.SKILLS.BRIDGE_CROSSBEAM,"BRIDGE_LOCK_BRACE":ExpansionM66.SKILLS.BRIDGE_LOCK_BRACE,"BRIDGE_LOAD_BEARER":ExpansionM66.SKILLS.BRIDGE_LOAD_BEARER,
	"RELIC_NAME_HOOK":ExpansionM66.SKILLS.RELIC_NAME_HOOK,"RELIC_COLD_EDGE":ExpansionM66.SKILLS.RELIC_COLD_EDGE,"RELIC_UNFINISHED_DUEL":ExpansionM66.SKILLS.RELIC_UNFINISHED_DUEL,
	"OSSUARY_FERRY_STRIKE":ExpansionM66.SKILLS.OSSUARY_FERRY_STRIKE,"OSSUARY_CLOSED_PALL":ExpansionM66.SKILLS.OSSUARY_CLOSED_PALL,"OSSUARY_PROCESSION":ExpansionM66.SKILLS.OSSUARY_PROCESSION,
	"PISTON_OFFSET_JAB":ExpansionM66.SKILLS.PISTON_OFFSET_JAB,"PISTON_FLYWHEEL":ExpansionM66.SKILLS.PISTON_FLYWHEEL,"PISTON_DEAD_CENTER":ExpansionM66.SKILLS.PISTON_DEAD_CENTER,
	"RIVET_SHEAR_LINE":ExpansionM66.SKILLS.RIVET_SHEAR_LINE,"RIVET_LOAD_PLATE":ExpansionM66.SKILLS.RIVET_LOAD_PLATE,"RIVET_WORKING_PRESSURE":ExpansionM66.SKILLS.RIVET_WORKING_PRESSURE,
	"THORN_GRAFT_CATCH":ExpansionM66.SKILLS.THORN_GRAFT_CATCH,"THORN_SAP_BLADE":ExpansionM66.SKILLS.THORN_SAP_BLADE,"THORN_GRAFT_RUPTURE":ExpansionM66.SKILLS.THORN_GRAFT_RUPTURE,
	"ANTLER_BRANCH_SWEEP":ExpansionM66.SKILLS.ANTLER_BRANCH_SWEEP,"ANTLER_BARK_FOLD":ExpansionM66.SKILLS.ANTLER_BARK_FOLD,"ANTLER_RUT_SEASON":ExpansionM66.SKILLS.ANTLER_RUT_SEASON,
	"SLAG_TEMPER_CUT":ExpansionM66.SKILLS.SLAG_TEMPER_CUT,"SLAG_WHITE_HEAT":ExpansionM66.SKILLS.SLAG_WHITE_HEAT,"SLAG_QUENCH_VERDICT":ExpansionM66.SKILLS.SLAG_QUENCH_VERDICT,
	"BASALT_STRATA_BLOW":ExpansionM66.SKILLS.BASALT_STRATA_BLOW,"BASALT_LOAD_TEST":ExpansionM66.SKILLS.BASALT_LOAD_TEST,"BASALT_FAULT_STANCE":ExpansionM66.SKILLS.BASALT_FAULT_STANCE,
	"PRISM_FACET_PIN":ExpansionM66.SKILLS.PRISM_FACET_PIN,"PRISM_DOUBLE_EDGE":ExpansionM66.SKILLS.PRISM_DOUBLE_EDGE,"PRISM_REFRACTION_CUT":ExpansionM66.SKILLS.PRISM_REFRACTION_CUT,
	"CARAPACE_SHELL_SPLIT":ExpansionM66.SKILLS.CARAPACE_SHELL_SPLIT,"CARAPACE_NEST_GUARD":ExpansionM66.SKILLS.CARAPACE_NEST_GUARD,"CARAPACE_LAYERED_MOLT":ExpansionM66.SKILLS.CARAPACE_LAYERED_MOLT,
	"ASH_LANTERN":{"id":"ASH_LANTERN","name":"哀灯光环","radius":165}, "ASH_STITCH":{"id":"ASH_STITCH","name":"灰线缝合","radius":145}, "ASH_REQUIEM":{"id":"ASH_REQUIEM","name":"归名安魂","radius":185},
	"GRAVE_CADENCE":{"id":"GRAVE_CADENCE","name":"暮钟光环","radius":165}, "GRAVE_CHAIN":{"id":"GRAVE_CHAIN","name":"锁魂链","radius":75}, "GRAVE_TOLL":{"id":"GRAVE_TOLL","name":"寂静晚钟","radius":120},
	"COIL_BATTERY":{"id":"COIL_BATTERY","name":"稳压光环","radius":165}, "COIL_MEND":{"id":"COIL_MEND","name":"线圈检修","radius":145}, "COIL_OVERHAUL":{"id":"COIL_OVERHAUL","name":"全域检修","radius":185},
	"SIGNAL_MARCH":{"id":"SIGNAL_MARCH","name":"信标光环","radius":165}, "SIGNAL_LOCK":{"id":"SIGNAL_LOCK","name":"断路脉冲","radius":75}, "SIGNAL_BLACKOUT":{"id":"SIGNAL_BLACKOUT","name":"静电封锁","radius":120},
	"BLOOM_SPRING":{"id":"BLOOM_SPRING","name":"花泉光环","radius":165}, "BLOOM_TOUCH":{"id":"BLOOM_TOUCH","name":"新芽抚触","radius":145}, "BLOOM_SANCTUARY":{"id":"BLOOM_SANCTUARY","name":"长春庇护","radius":185},
	"THORN_BREEZE":{"id":"THORN_BREEZE","name":"林风光环","radius":165}, "THORN_LASH":{"id":"THORN_LASH","name":"缠枝","radius":75}, "THORN_MAZE":{"id":"THORN_MAZE","name":"荆棘迷庭","radius":120},
	"HEARTH_WARMTH":{"id":"HEARTH_WARMTH","name":"暖炉光环","radius":165}, "HEARTH_MEND":{"id":"HEARTH_MEND","name":"炉火重整","radius":145}, "HEARTH_REFUGE":{"id":"HEARTH_REFUGE","name":"不熄营火","radius":185},
	"STORM_CHANT":{"id":"STORM_CHANT","name":"战歌光环","radius":165}, "STORM_HAMMER":{"id":"STORM_HAMMER","name":"落雷锤","radius":75}, "STORM_VERDICT":{"id":"STORM_VERDICT","name":"山巅裁决","radius":120},
	"SPORE_GLOW":{"id":"SPORE_GLOW","name":"菌光光环","radius":165}, "SPORE_REMEDY":{"id":"SPORE_REMEDY","name":"孢疗","radius":145}, "SPORE_HAVEN":{"id":"SPORE_HAVEN","name":"菌丝庇所","radius":185},
	"QUAKE_RHYTHM":{"id":"QUAKE_RHYTHM","name":"穴音光环","radius":165}, "QUAKE_SNARE":{"id":"QUAKE_SNARE","name":"地鸣缚","radius":75}, "QUAKE_SEAL":{"id":"QUAKE_SEAL","name":"断层封印","radius":120},
	"CLEAVE": {"id":"CLEAVE", "name":"裂契斩", "effect":"DAMAGE", "target_mode":"POINT", "range":160, "radius":100, "damage":26, "max_cooldown_ticks":80, "description":"选择160内一点，对100范围敌兵造成26伤害（减护甲）；冷却4秒。"},
	"RECOVER": {"id":"RECOVER", "name":"重整", "effect":"HEAL", "target_mode":"SELF", "range":0, "radius":0, "heal":45, "max_cooldown_ticks":120, "description":"恢复自身45生命，不超过缺失生命；满血或倒下不能使用。冷却6秒。"},
	"RALLY": {"id":"RALLY", "name":"盟誓", "effect":"RALLY", "target_mode":"POINT", "range":160, "radius":160, "damage_bonus":3, "duration_ticks":100, "max_cooldown_ticks":160, "description":"选择160内一点，160范围友军普攻+3，持续5秒；长官倒下增益失效。冷却8秒。"},
	"SHIELD_SHOCK": {"id":"SHIELD_SHOCK", "name":"盾震", "effect":"STUN", "target_mode":"POINT", "range":160, "radius":90, "damage":18, "control_duration_ticks":20, "max_cooldown_ticks":140, "description":"选择160内一点，90范围敌兵受到18伤害（减护甲）并眩晕1秒，无法移动、普攻或施技。冷却7秒。"},
	"BULWARK_WARD": {"id":"BULWARK_WARD", "name":"护垒", "effect":"ARMOR_BUFF", "target_mode":"SELF", "range":0, "radius":0, "armor_bonus":4, "duration_ticks":100, "max_cooldown_ticks":180, "description":"自身护甲+4，持续5秒；不恢复生命，倒下后不会保留。冷却9秒。"},
	"BULWARK_RECOVER": {"id":"BULWARK_RECOVER", "name":"坚守", "effect":"HEAL", "target_mode":"SELF", "range":0, "radius":0, "heal":60, "max_cooldown_ticks":180, "description":"恢复自身60生命，不超过缺失生命；满血或倒下不能使用。冷却9秒。"},
	"STARFIRE": {"id":"STARFIRE", "name":"星火", "effect":"DAMAGE", "target_mode":"POINT", "range":260, "radius":90, "damage":34, "spell_lens":true, "max_cooldown_ticks":100, "description":"选择260内一点，90范围敌兵受到34伤害（减护甲）。星契透镜可提高伤害。冷却5秒。"},
	"FROST_BIND": {"id":"FROST_BIND", "name":"霜契", "effect":"ROOT", "target_mode":"POINT", "range":240, "radius":80, "damage":14, "spell_lens":true, "control_duration_ticks":40, "max_cooldown_ticks":180, "description":"选择240内一点，80范围敌兵受到14伤害（减护甲）并定身2秒；仍能普攻与施技。冷却9秒。"},
	"ARCANE_BURST": {"id":"ARCANE_BURST", "name":"术爆", "effect":"DAMAGE", "target_mode":"POINT", "range":220, "radius":130, "damage":42, "spell_lens":true, "max_cooldown_ticks":200, "description":"选择220内一点，130范围敌兵受到42伤害（减护甲）。星契透镜可提高伤害。冷却10秒。"},
	"PIERCING_SHOT": {"id":"PIERCING_SHOT", "name":"贯弦", "effect":"DAMAGE", "target_mode":"POINT", "range":300, "radius":50, "damage":40, "max_cooldown_ticks":100, "description":"选择300内一点，50范围敌兵受到40伤害（减护甲）；不伤害建筑。冷却5秒。"},
	"ARROW_RAIN": {"id":"ARROW_RAIN", "name":"箭雨", "effect":"DAMAGE", "target_mode":"POINT", "range":260, "radius":110, "damage":22, "max_cooldown_ticks":160, "description":"选择260内一点，110范围敌兵受到22伤害（减护甲）；不伤害建筑。冷却8秒。"},
	"QUICKDRAW": {"id":"QUICKDRAW", "name":"急弦", "effect":"DAMAGE_BUFF", "target_mode":"SELF", "range":0, "radius":0, "damage_bonus":5, "duration_ticks":100, "max_cooldown_ticks":160, "description":"自身普攻伤害+5，持续5秒；不提高技能伤害。冷却8秒。"},
	"SEAL_STRIKE": {"id":"SEAL_STRIKE", "name":"封刃", "effect":"STUN", "target_mode":"POINT", "range":140, "radius":75, "damage":20, "control_duration_ticks":20, "max_cooldown_ticks":120, "description":"选择140内一点，75范围敌兵受到20伤害（减护甲）并眩晕1秒，无法移动、普攻或施技。冷却6秒。"},
	"WHIRLWIND": {"id":"WHIRLWIND", "name":"回旋", "effect":"DAMAGE", "target_mode":"POINT", "range":150, "radius":100, "damage":32, "max_cooldown_ticks":100, "description":"选择150内一点，100范围敌兵受到32伤害（减护甲）；不伤害建筑。冷却5秒。"},
	"BLOOD_PACT": {"id":"BLOOD_PACT", "name":"血契", "effect":"HEAL", "target_mode":"SELF", "range":0, "radius":0, "heal":35, "max_cooldown_ticks":100, "description":"恢复自身35生命，不超过缺失生命；满血或倒下不能使用。冷却5秒。"},
	"ASH_SHOCK": {"id":"ASH_SHOCK","name":"烬骨震","effect":"STUN","target_mode":"POINT","range":155,"radius":85,"target_layers":["GROUND"],"max_cooldown_ticks":140,"damage":19,"control_duration_ticks":20,"description":"距离155内选点，85范围地面敌兵受到19伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵眩晕1秒，不能移动、普攻和施技。冷却7秒。"},
	"ASH_WARD": {"id":"ASH_WARD","name":"陶骨护垒","effect":"ARMOR_BUFF","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"armor_bonus":4,"duration_ticks":100,"description":"自身护甲+4，持续5秒。冷却9秒。"},
	"ASH_MEND": {"id":"ASH_MEND","name":"守烬回生","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"heal":65,"description":"恢复自身65生命，最多恢复至生命上限。冷却9秒。"},
	"MOURN_BIND": {"id":"MOURN_BIND","name":"灰灯缚","effect":"ROOT","target_mode":"POINT","range":240,"radius":95,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":180,"damage":13,"control_duration_ticks":40,"description":"距离240内选点，95范围地面/空中敌兵受到13伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵定身2秒，仍可普攻和施技。冷却9秒。"},
	"MOURN_FLARE": {"id":"MOURN_FLARE","name":"哀火","effect":"DAMAGE","target_mode":"POINT","range":240,"radius":105,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":120,"damage":36,"description":"距离240内选点，105范围地面/空中敌兵受到36伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却6秒。"},
	"MOURN_OATH": {"id":"MOURN_OATH","name":"余温盟约","effect":"RALLY","target_mode":"POINT","range":240,"radius":150,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":160,"damage_bonus":4,"duration_ticks":100,"description":"距离240内选点，150范围友军普攻+4持续5秒；长官倒下增益失效。冷却8秒。"},
	"CINDER_SHOT": {"id":"CINDER_SHOT","name":"骨弦击","effect":"DAMAGE","target_mode":"POINT","range":290,"radius":55,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":100,"damage":39,"description":"距离290内选点，55范围地面/空中敌兵受到39伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却5秒。"},
	"CINDER_FERVOR": {"id":"CINDER_FERVOR","name":"燃弦","effect":"DAMAGE_BUFF","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":160,"damage_bonus":5,"duration_ticks":100,"description":"自身普攻+5，持续5秒，不改变技能伤害。冷却8秒。"},
	"CINDER_MEND": {"id":"CINDER_MEND","name":"续烬","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":120,"heal":40,"description":"恢复自身40生命，最多恢复至生命上限。冷却6秒。"},
	"COIL_SHOCK": {"id":"COIL_SHOCK","name":"线圈震","effect":"STUN","target_mode":"POINT","range":155,"radius":85,"target_layers":["GROUND"],"max_cooldown_ticks":140,"damage":20,"control_duration_ticks":20,"description":"距离155内选点，85范围地面敌兵受到20伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵眩晕1秒，不能移动、普攻和施技。冷却7秒。"},
	"COIL_WARD": {"id":"COIL_WARD","name":"铆甲锁","effect":"ARMOR_BUFF","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"armor_bonus":5,"duration_ticks":100,"description":"自身护甲+5，持续5秒。冷却9秒。"},
	"COIL_REPAIR": {"id":"COIL_REPAIR","name":"应急检修","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"heal":55,"description":"恢复自身55生命，最多恢复至生命上限。冷却9秒。"},
	"VOLT_BIND": {"id":"VOLT_BIND","name":"电弧封锁","effect":"STUN","target_mode":"POINT","range":240,"radius":95,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":180,"damage":20,"control_duration_ticks":20,"description":"距离240内选点，95范围地面/空中敌兵受到20伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵眩晕1秒，不能移动、普攻和施技。冷却9秒。"},
	"VOLT_ARC": {"id":"VOLT_ARC","name":"脉冲爆","effect":"DAMAGE","target_mode":"POINT","range":240,"radius":105,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":120,"damage":38,"description":"距离240内选点，105范围地面/空中敌兵受到38伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却6秒。"},
	"VOLT_NETWORK": {"id":"VOLT_NETWORK","name":"功率网络","effect":"RALLY","target_mode":"POINT","range":240,"radius":150,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":160,"damage_bonus":3,"duration_ticks":100,"description":"距离240内选点，150范围友军普攻+3持续5秒；长官倒下增益失效。冷却8秒。"},
	"GEAR_SHOT": {"id":"GEAR_SHOT","name":"碎轮弹","effect":"DAMAGE","target_mode":"POINT","range":290,"radius":55,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":100,"damage":43,"description":"距离290内选点，55范围地面/空中敌兵受到43伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却5秒。"},
	"GEAR_FERVOR": {"id":"GEAR_FERVOR","name":"齿轮超频","effect":"DAMAGE_BUFF","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":160,"damage_bonus":6,"duration_ticks":100,"description":"自身普攻+6，持续5秒，不改变技能伤害。冷却8秒。"},
	"GEAR_REPAIR": {"id":"GEAR_REPAIR","name":"战地检修","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":120,"heal":35,"description":"恢复自身35生命，最多恢复至生命上限。冷却6秒。"},
	"VINE_SHOCK": {"id":"VINE_SHOCK","name":"根垒震","effect":"STUN","target_mode":"POINT","range":155,"radius":85,"target_layers":["GROUND"],"max_cooldown_ticks":140,"damage":17,"control_duration_ticks":20,"description":"距离155内选点，85范围地面敌兵受到17伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵眩晕1秒，不能移动、普攻和施技。冷却7秒。"},
	"VINE_WARD": {"id":"VINE_WARD","name":"枝甲","effect":"ARMOR_BUFF","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"armor_bonus":4,"duration_ticks":100,"description":"自身护甲+4，持续5秒。冷却9秒。"},
	"VINE_MEND": {"id":"VINE_MEND","name":"苗愈","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"heal":60,"description":"恢复自身60生命，最多恢复至生命上限。冷却9秒。"},
	"LEAF_BIND": {"id":"LEAF_BIND","name":"织根缚","effect":"ROOT","target_mode":"POINT","range":240,"radius":95,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":180,"damage":10,"control_duration_ticks":40,"description":"距离240内选点，95范围地面/空中敌兵受到10伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵定身2秒，仍可普攻和施技。冷却9秒。"},
	"LEAF_FLARE": {"id":"LEAF_FLARE","name":"叶辉","effect":"DAMAGE","target_mode":"POINT","range":240,"radius":105,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":120,"damage":32,"description":"距离240内选点，105范围地面/空中敌兵受到32伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却6秒。"},
	"LEAF_OATH": {"id":"LEAF_OATH","name":"苗圃盟誓","effect":"RALLY","target_mode":"POINT","range":240,"radius":150,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":160,"damage_bonus":4,"duration_ticks":100,"description":"距离240内选点，150范围友军普攻+4持续5秒；长官倒下增益失效。冷却8秒。"},
	"WIND_SHOT": {"id":"WIND_SHOT","name":"风弦","effect":"DAMAGE","target_mode":"POINT","range":290,"radius":55,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":100,"damage":38,"description":"距离290内选点，55范围地面/空中敌兵受到38伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却5秒。"},
	"WIND_FERVOR": {"id":"WIND_FERVOR","name":"疾叶","effect":"DAMAGE_BUFF","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":160,"damage_bonus":5,"duration_ticks":100,"description":"自身普攻+5，持续5秒，不改变技能伤害。冷却8秒。"},
	"WIND_MEND": {"id":"WIND_MEND","name":"风息","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":120,"heal":35,"description":"恢复自身35生命，最多恢复至生命上限。冷却6秒。"},
	"RIDGE_SHOCK": {"id":"RIDGE_SHOCK","name":"崖垒震","effect":"STUN","target_mode":"POINT","range":155,"radius":85,"target_layers":["GROUND"],"max_cooldown_ticks":140,"damage":22,"control_duration_ticks":20,"description":"距离155内选点，85范围地面敌兵受到22伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵眩晕1秒，不能移动、普攻和施技。冷却7秒。"},
	"RIDGE_WARD": {"id":"RIDGE_WARD","name":"炉甲","effect":"ARMOR_BUFF","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"armor_bonus":5,"duration_ticks":100,"description":"自身护甲+5，持续5秒。冷却9秒。"},
	"RIDGE_MEND": {"id":"RIDGE_MEND","name":"山誓重整","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"heal":55,"description":"恢复自身55生命，最多恢复至生命上限。冷却9秒。"},
	"RUNE_BIND": {"id":"RUNE_BIND","name":"符炉缚","effect":"ROOT","target_mode":"POINT","range":240,"radius":95,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":180,"damage":16,"control_duration_ticks":40,"description":"距离240内选点，95范围地面/空中敌兵受到16伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵定身2秒，仍可普攻和施技。冷却9秒。"},
	"RUNE_FLARE": {"id":"RUNE_FLARE","name":"炉焰","effect":"DAMAGE","target_mode":"POINT","range":240,"radius":105,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":120,"damage":40,"description":"距离240内选点，105范围地面/空中敌兵受到40伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却6秒。"},
	"RUNE_OATH": {"id":"RUNE_OATH","name":"符脊盟约","effect":"RALLY","target_mode":"POINT","range":240,"radius":150,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":160,"damage_bonus":3,"duration_ticks":100,"description":"距离240内选点，150范围友军普攻+3持续5秒；长官倒下增益失效。冷却8秒。"},
	"EMBER_SEAL": {"id":"EMBER_SEAL","name":"焰刃封","effect":"STUN","target_mode":"POINT","range":145,"radius":90,"target_layers":["GROUND"],"max_cooldown_ticks":120,"damage":24,"control_duration_ticks":20,"description":"距离145内选点，90范围地面敌兵受到24伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵眩晕1秒，不能移动、普攻和施技。冷却6秒。"},
	"EMBER_SWEEP": {"id":"EMBER_SWEEP","name":"热谷旋刃","effect":"DAMAGE","target_mode":"POINT","range":145,"radius":90,"target_layers":["GROUND"],"max_cooldown_ticks":100,"damage":35,"description":"距离145内选点，90范围地面敌兵受到35伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却5秒。"},
	"EMBER_MEND": {"id":"EMBER_MEND","name":"焰脊续战","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":120,"heal":35,"description":"恢复自身35生命，最多恢复至生命上限。冷却6秒。"},
	"TUNNEL_SHOCK": {"id":"TUNNEL_SHOCK","name":"穴鸣震","effect":"STUN","target_mode":"POINT","range":155,"radius":85,"target_layers":["GROUND"],"max_cooldown_ticks":140,"damage":18,"control_duration_ticks":20,"description":"距离155内选点，85范围地面敌兵受到18伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵眩晕1秒，不能移动、普攻和施技。冷却7秒。"},
	"TUNNEL_WARD": {"id":"TUNNEL_WARD","name":"甲壳锁","effect":"ARMOR_BUFF","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"armor_bonus":4,"duration_ticks":100,"description":"自身护甲+4，持续5秒。冷却9秒。"},
	"TUNNEL_MEND": {"id":"TUNNEL_MEND","name":"孢壳重整","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":180,"heal":60,"description":"恢复自身60生命，最多恢复至生命上限。冷却9秒。"},
	"ECHO_BIND": {"id":"ECHO_BIND","name":"声纹缚","effect":"ROOT","target_mode":"POINT","range":240,"radius":95,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":180,"damage":15,"control_duration_ticks":40,"description":"距离240内选点，95范围地面/空中敌兵受到15伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵定身2秒，仍可普攻和施技。冷却9秒。"},
	"ECHO_FLARE": {"id":"ECHO_FLARE","name":"晶鸣","effect":"DAMAGE","target_mode":"POINT","range":240,"radius":105,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":120,"damage":35,"description":"距离240内选点，105范围地面/空中敌兵受到35伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却6秒。"},
	"ECHO_OATH": {"id":"ECHO_OATH","name":"回响盟约","effect":"RALLY","target_mode":"POINT","range":240,"radius":150,"target_layers":["GROUND","AIR"],"max_cooldown_ticks":160,"damage_bonus":3,"duration_ticks":100,"description":"距离240内选点，150范围友军普攻+3持续5秒；长官倒下增益失效。冷却8秒。"},
	"SPORE_SEAL": {"id":"SPORE_SEAL","name":"隙刃封","effect":"STUN","target_mode":"POINT","range":145,"radius":90,"target_layers":["GROUND"],"max_cooldown_ticks":120,"damage":21,"control_duration_ticks":20,"description":"距离145内选点，90范围地面敌兵受到21伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。敌兵眩晕1秒，不能移动、普攻和施技。冷却6秒。"},
	"SPORE_SWEEP": {"id":"SPORE_SWEEP","name":"孢纹回旋","effect":"DAMAGE","target_mode":"POINT","range":145,"radius":90,"target_layers":["GROUND"],"max_cooldown_ticks":100,"damage":33,"description":"距离145内选点，90范围地面敌兵受到33伤害（减护甲），工人仅受伤、不提供经验，不伤建筑。冷却5秒。"},
	"SPORE_MEND": {"id":"SPORE_MEND","name":"菌息","effect":"HEAL","target_mode":"SELF","range":0,"radius":0,"target_layers":["GROUND"],"max_cooldown_ticks":120,"heal":40,"description":"恢复自身40生命，最多恢复至生命上限。冷却6秒。"},
}
const ITEMS = Items.ITEMS
static var PROFILES:Dictionary = _profiles()
static var _profile_cache_m75: Dictionary = {}
static var _skill_cache_m75: Dictionary = {}

static func _profiles()->Dictionary:
	var result:Dictionary=LEGACY_PROFILES.duplicate(true)
	for id:String in ExpansionM66.IDS:result[id]=ExpansionM66.raw_profile(id)
	for id:String in MagesM68.IDS:result[id]=MagesM68.raw_profile(id)
	return result

static func profile(archetype: String = DEFAULT_ARCHETYPE) -> Dictionary:
	# Bounded immutable-content memo; every consumer still gets a detached row.
	# Match levels/equipment/statuses do not belong to this intrinsic catalog.
	if _profile_cache_m75.has(archetype): return _profile_cache_m75[archetype].duplicate(true)
	var result := _uncached_profile_m75(archetype)
	if ReworkR7.has_hero(archetype): result.merge(ReworkR7.profile_patch(archetype),true)
	if PROFILES.has(archetype): _profile_cache_m75[archetype]=result.duplicate(true)
	return result

static func _uncached_profile_m75(archetype: String) -> Dictionary:
	if MagesM68.has_hero(archetype):
		var mage:=MagesM68.raw_profile(archetype)
		mage["growth"]=HeroProgression.growth(archetype)
		mage["growth_description"]=HeroProgression.growth_description(archetype)
		mage["innate"]=Innates.profile(archetype)
		mage["description"]="%s。%s\n%s\n三项伤害技能；大招在5/8级可学，最高8级，占5人口，每秒恢复1生命。\n%s\n天赋·%s：%s"%[mage.role,mage.story.origin,mage.story.counterplay,mage.growth_description,mage.innate.name,mage.innate.description]
		return mage
	if ExpansionM66.has_hero(archetype):
		var added:=ExpansionM66.raw_profile(archetype)
		added["growth"]=HeroProgression.growth(archetype)
		added["growth_description"]=HeroProgression.growth_description(archetype)
		added["innate"]=Innates.profile(archetype)
		added["description"]="%s。%s\n%s\n3项技能与独立天赋；普通技能最高3阶，大招在5/8级可学。最高8级，占5人口，每秒恢复1生命。\n%s\n天赋·%s：%s"%[added.role,added.story.origin,added.story.counterplay,added.growth_description,added.innate.name,added.innate.description]
		return RolesM68.apply_profile(archetype,added)
	var result: Dictionary = PROFILES.get(archetype, {}).duplicate(true)
	if not result.is_empty():
		result["stats"]["max_mana"] = int(MAXIMUM_MANA.get(archetype,150))
		result["faction_id"]=result.get("faction_id","HUMAN")
		result["attack_layers"]=result.get("attack_layers",["GROUND","AIR"] if int(result.stats.attack_range)>80 else ["GROUND"])
		result["body_kind"]=result.get("body_kind","HUMANOID")
		result.stats["attack_type"] = "CHAOS"
		result.stats["armor_type"] = "SACRED"
		result["role_id"] = HeroProgression.role(archetype)
		result.stats["hp_regen_per_second"] = 2.0 if result.role_id=="TANK" else 1.5 if result.role_id in ["HEAL_SUPPORT","CONTROL_SUPPORT"] else 1.0
		result["role"] = str(HeroProgression.ROLE_LABELS[result.role_id])
		if result.role_id=="PHYSICAL": result.role=("射手·" if int(result.stats.attack_range)>80 else "近战·")+result.role
		result["visual_archetype"] = result.get("visual_archetype",archetype)
		result["growth"] = HeroProgression.growth(archetype)
		result["growth_description"] = HeroProgression.growth_description(archetype)
		result["innate"]=Innates.profile(archetype)
		if archetype=="COMMANDER": result.stats.damage=12
		if archetype=="DUELIST": result.stats.damage=13
		# M53 army-scale hero baseline. Role growth is scaled in its own catalog.
		result.stats.max_hp=roundi(float(result.stats.max_hp)*1.5)
		result.stats.damage=roundi(float(result.stats.damage)*1.5)
		if result.role_id=="TANK": result.stats.damage=roundi(float(result.stats.damage)*1.1)
		result.stats.max_mana=roundi(float(result.stats.max_mana)*1.5)
		var kit: Array[String] = []
		for skill_id: String in result.skill_ids: kit.append(str(IdentityM67.ROWS.get(skill_id,{}).get("name",SkillVariety.ENTRIES.get(skill_id,{}).get("name",HeroProgression.skill_patch(skill_id).get("name",SKILLS[skill_id].name)))))
		result["description"] = "%s，擅长%s。\n3项技能与独立天赋；初始获得1点技能点，最高8级。普通技能最高3阶，大招在5/8级可学。\n神圣护甲使控制基础时长缩短至70%%，再计入控制抗性；占5人口。战斗中每秒恢复%.1f生命，可与装备和天赋回复相加。\n%s\n天赋·%s：%s" % [result.role,"、".join(kit),float(result.stats.hp_regen_per_second),result.growth_description,result.innate.name,result.innate.description]
	return RolesM68.apply_profile(archetype,result)

static func skills_for(archetype: String = DEFAULT_ARCHETYPE) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in PROFILES.get(archetype, {}).get("skill_ids", []):
		result.append(skill_at_level(id))
	return result

static func available_for_faction(faction_id: String)->Array[String]:
	var result: Array[String]=[]
	for id: String in ARCHETYPES:
		if profile(id).faction_id==faction_id:result.append(id)
	return result

static func item_catalog() -> Dictionary:
	return ITEMS.duplicate(true)

static func skill_at_level(id: String, level: int = 1) -> Dictionary:
	# Catalog ranks are immutable content, not hero state. Reusing the resolved
	# value avoids rebuilding descriptions and historical migration layers for
	# every unit/tick. Never cache arbitrary IDs/ranks or return the cache itself.
	var key := id+":"+str(level)
	if _skill_cache_m75.has(key): return _skill_cache_m75[key].duplicate(true)
	var result := _uncached_skill_m75(id,level)
	if not result.is_empty() and level>=0 and level<=MAX_SKILL_LEVEL and _skill_cache_m75.size()<576:
		_skill_cache_m75[key]=result.duplicate(true)
	return result

static func _uncached_skill_m75(id: String, level: int = 1) -> Dictionary:
	# Whole migrated kits bypass every historical numerical multiplier.
	# Stable live IDs retain learning/revival/asset compatibility.
	if ReworkR7.has_skill(id): return ReworkR7.skill(id,level)
	if MagesM68.SKILLS.has(id):
		var mage_skill:=TuningM71.apply(BudgetsM70.apply(PowerM69.apply(MagesM68.skill(id,level))))
		if not mage_skill.is_empty():mage_skill["description"]=describe_skill(mage_skill)
		return mage_skill
	if ExpansionM66.SKILLS.has(id):
		var added:=ExpansionM66.skill(id,level)
		added=RolesM68.apply_skill(added,id,level)
		added=PowerM69.apply(added)
		added=BudgetsM70.apply(added)
		added=TuningM71.apply(added)
		if not added.is_empty():added["description"]=describe_skill(added)
		return added
	if id not in SKILLS or level < 0 or level > HeroProgression.max_skill_rank(id): return {}
	var skill: Dictionary = SKILLS[id].duplicate(true)
	skill.merge(Traits.skill(id), true)
	var patch := HeroProgression.skill_patch(id)
	if not patch.is_empty():
		if patch.has("effect") and patch.effect!=skill.get("effect",""):
			for key: String in ["damage","heal","ally_heal","ally_guard","ally_radius","ally_required_tag","duration_ticks","damage_bonus","armor_bonus","speed_bonus","range_bonus","drain_percent","drain_percent_buff","status_kind","status_power","status_duration_ticks","execute_percent","control_duration_ticks","cleanse_dot"]: skill.erase(key)
		skill.merge(patch,true)
	if skill.effect not in ["STUN","ROOT"]: skill.erase("control_duration_ticks")
	skill["delivery"] = skill.get("delivery", "AREA")
	skill["max_targets"] = clampi(int(skill.get("max_targets", 6)), 1, 6)
	skill["attack_type"] = skill.get("attack_type", "EDGE" if id in ["CLEAVE","SEAL_STRIKE","WHIRLWIND","EMBER_SEAL","EMBER_SWEEP","SPORE_SEAL","SPORE_SWEEP"] else "IMPACT" if id in ["SHIELD_SHOCK","ASH_SHOCK","RIDGE_SHOCK","TUNNEL_SHOCK"] else "ARCANE")
	skill["source_faction"] = "HUMAN"
	for archetype: String in ARCHETYPES:
		if id in PROFILES[archetype].skill_ids: skill.source_faction = PROFILES[archetype].get("faction_id", "HUMAN"); break
	skill["presentation_style"] = str(skill.source_faction).to_lower() + "_" + str(skill.delivery).to_lower()
	skill["target_layers"]=skill.get("target_layers",["GROUND"] if id in ["CLEAVE","SHIELD_SHOCK","SEAL_STRIKE","WHIRLWIND"] else ["GROUND","AIR"])
	skill["mana_cost"] = int(skill.get("mana_cost",SKILL_MANA_COSTS[skill["effect"]]))
	skill["level"] = level
	skill["max_level"] = HeroProgression.max_skill_rank(id)
	skill["ultimate"] = id in HeroProgression.ULTIMATES
	skill["passive"] = bool(skill.get("passive",false))
	skill["learned"] = level>0
	skill["required_hero_level"] = HeroProgression.required_level(id,mini(level+1,int(skill.max_level)))
	var effective_level := maxi(1,level)
	# M50 role-preserving skill presence: costs/targets stay finite and unchanged.
	# Derived here so live HUD, lobby codex, AI and settlement share exact values.
	for key: String in ["damage", "heal", "ally_heal"]:
		if skill.has(key):
			var percent := (140 if bool(skill.ultimate) else 130) if key == "damage" else (125 if bool(skill.ultimate) else 120)
			skill[key] = (int(skill[key]) * percent + 50) / 100
	if skill.has("control_duration_ticks"):
		skill.control_duration_ticks = mini(64 if skill.effect == "ROOT" else 48, int(skill.control_duration_ticks) + (8 if bool(skill.ultimate) else 4) + (effective_level-1)*2)
	if skill.has("damage_bonus"): skill.damage_bonus = int(skill.damage_bonus) + (3 if bool(skill.ultimate) else 2)
	for key: String in ["damage", "heal", "ally_heal", "status_power"]:
		if skill.has(key): skill[key] = int(skill[key]) * (4 + effective_level - 1) / 4
	for key: String in ["damage_bonus", "armor_bonus"]:
		if skill.has(key): skill[key] = int(skill[key]) + effective_level - 1
	if skill.effect=="PASSIVE_GUARD": skill["passive_armor"]=effective_level+1
	if skill.effect=="AURA":
		skill.aura_radius=int(skill.aura_radius)+20+(effective_level-1)*15
		skill.radius=skill.aura_radius
		if int(skill.get("aura_damage",0))>0: skill.aura_damage=effective_level
		if int(skill.get("aura_heal",0))>0: skill.aura_heal=effective_level+1
		if int(skill.get("aura_armor",0))>0: skill.aura_armor=1 if effective_level<3 else 2
		if int(skill.get("aura_speed",0))>0: skill.aura_speed=1 if effective_level<3 else 2
	# M51 durability pass doubles the final M50 rank values exactly once.
	# Control windows, mana, cooldowns and target caps are deliberately unchanged.
	for key: String in ["damage", "heal", "ally_heal"]:
		if skill.has(key): skill[key] = int(skill[key]) * 2
	if str(skill.get("status_kind","")) in ["BURN","POISON"] and skill.has("status_power"):
		skill.status_power = int(skill.status_power) * 2
	for key:String in ["damage","heal","ally_heal"]:
		if skill.has(key):skill[key]=roundi(float(skill[key])*1.5)
	if str(skill.get("status_kind","")) in ["BURN","POISON"] and skill.has("status_power"):skill.status_power=roundi(float(skill.status_power)*1.5)
	var buffs:={
		"CINDER_FERVOR":{"damage_percent":[20,30,40],"damage_bonus":2,"drain_percent_buff":25},
		"GEAR_FERVOR":{"damage_percent":[20,30,40],"damage_bonus":2,"range_bonus":30},
		"WIND_FERVOR":{"damage_percent":[15,25,35],"damage_bonus":2,"move_speed_percent":[12,16,20]},
		"QUICKDRAW":{"damage_percent":[50,65],"attack_speed_percent":[15,20],"range_bonus":[24,36]},
		"CINDER_MEND":{"damage_percent":[50,65],"attack_speed_percent":[10,15],"drain_percent_buff":15},
		"GEAR_REPAIR":{"damage_percent":[50,65],"attack_speed_percent":[15,20],"range_bonus":[24,36]},
		"WIND_MEND":{"damage_percent":[45,60],"attack_speed_percent":[15,20],"move_speed_percent":[20,25]},
		"EMBER_MEND":{"damage_percent":[70,90],"drain_percent_buff":10},
		"SPORE_MEND":{"damage_percent":[55,70],"attack_speed_percent":[10,15],"move_speed_percent":[15,20]},
	}
	if buffs.has(id):
		for key:String in ["heal","ally_heal","speed_bonus"]:skill.erase(key)
		skill.effect="DAMAGE_BUFF"
		skill.target_mode="SELF"
		skill.range=0
		skill.radius=0
		skill.max_cooldown_ticks=480 if bool(skill.ultimate) else 160
		skill.duration_ticks=140 if bool(skill.ultimate) else 100
		skill.mana_cost=([45,55][mini(effective_level-1,1)] if bool(skill.ultimate) else 15)
		for key:String in buffs[id]:
			var value:Variant=buffs[id][key]
			skill[key]=value[mini(effective_level-1,value.size()-1)] if value is Array else value
	# Final authored rank budgets must follow all legacy trait, role and buff
	# overlays; otherwise focused ultimates silently become old SELF buffs.
	skill = SkillVariety.apply(skill,id,level)
	skill = IdentityM67.apply(skill,id,level)
	skill = RolesM68.apply_skill(skill,id,level)
	skill = CalibrationM68.apply(skill,id)
	skill = PowerM69.apply(skill)
	skill = BudgetsM70.apply(skill)
	skill = TuningM71.apply(skill)
	skill["description"] = describe_skill(skill)
	return skill

static func describe_skill(skill: Dictionary) -> String:
	var parts: Array[String] = ["未学习，预览1级效果" if int(skill.get("level",1))==0 else "%d级" % int(skill.get("level",1))]
	parts.append("终极技能，英雄5/8级可学，最高2级" if skill.ultimate else "普通技能，消耗技能点升级，最高3级")
	if skill.effect=="PASSIVE_GUARD":
		parts.append("被动护甲+%.2f，学会后无需施放或消耗蓝量" % float(skill.passive_armor))
		if skill.has("conditional_aura"):
			var aura: Dictionary=skill.conditional_aura
			parts.append("%s时，使%d范围内最近的最多%d名友军%s+%.2f%%。同属性效果只取最高值，条件结束或英雄倒下后失效" % [{"STATIONARY_2S":"静止2秒","ROOTED_HEAL_WINDOW":"施放根心复苏后的6秒内保持扎根","FORMATION_2_ALLIES":"自身90范围内有至少2名其他友军"}.get(aura.condition,aura.condition),int(aura.radius),int(aura.max_targets),{"attack_speed_percent":"攻击速度","healing_received_percent":"受到的主动治疗","control_resist_percent":"控制抗性","basic_damage_reduction_percent":"普攻减伤"}.get(aura.attribute,aura.attribute),float(aura.amount)])
		return "。\n".join(parts)+"。"
	if skill.effect=="AURA":
		parts.append("被动光环，影响%d范围内最近的最多%d名友军，可包括自身。英雄与装备的同属性光环只取最高值" % [int(skill.aura_radius),int(skill.max_targets)])
		for pair: Array in [["aura_damage","普攻"],["aura_armor","护甲"],["aura_speed","移动步长"]]:
			if float(skill.get(pair[0],0))>0: parts.append("%s+%.2f" % [pair[1],float(skill[pair[0]])])
		if float(skill.get("aura_move_speed_percent",0))>0: parts.append("移动速度+%.2f%%"%float(skill.aura_move_speed_percent))
		if float(skill.get("aura_heal",0))>0: parts.append("每秒恢复%.2f生命，最多恢复至生命上限" % float(skill.aura_heal))
		parts.append("不影响工人。离开范围、遗忘技能或英雄倒下后失效，无需施放或消耗蓝量")
		return "。\n".join(parts)+"。"
	if skill.target_mode == "POINT":
		parts.append("施放距离%d" % int(skill.range))
		if skill.delivery == "SINGLE": parts.append("命中落点%d范围内最近的1名敌人，无溅射" % int(skill.radius))
		elif skill.delivery == "CONE": parts.append("朝落点方向的扇形，长%d、末端宽%d，最多%d名敌人" % [int(skill.range),int(skill.cone_width),int(skill.max_targets)])
		elif skill.delivery == "LINE": parts.append("沿施法者至落点的直线，宽%d，最多%d个敌方目标" % [int(skill.line_width),int(skill.max_targets)])
		elif skill.delivery == "CHAIN": parts.append("从落点附近的敌人开始，向%d距离内的敌人跳跃，合计最多命中%d名不同敌人" % [int(skill.chain_range),int(skill.max_targets)])
		else: parts.append("作用半径%d，最多%d个目标" % [int(skill.radius),int(skill.max_targets)])
	else: parts.append("作用于自身")
	if float(skill.get("damage",0))>0: parts.append("造成%.2f点%s基础伤害，受伤害类型与护甲影响" % [float(skill.damage),DamageRules.attack_label(skill.attack_type)])
	if float(skill.get("damage",0))>0 and int(skill.get("secondary_damage_percent",100))<100: parts.append("首个目标承受全额伤害，后续目标各承受%d%%基础伤害" % int(skill.secondary_damage_percent))
	if int(skill.get("secondary_damage_percent",100))<100 and (skill.has("control_duration_ticks") or skill.has("status_kind")): parts.append("后续目标的控制与状态持续时间不变")
	if skill.effect in ["STUN","ROOT"]: parts.append("使敌人眩晕，无法移动、普攻或施放技能" if skill.effect=="STUN" else "使敌人定身，仍可普攻和施放技能")
	if skill.has("control_duration_ticks"): parts.append("控制持续%.2f秒；对神圣护甲目标，基础时长缩短至70%%，再计入控制抗性" % (float(skill.control_duration_ticks)/20.0))
	if skill.has("heal"): parts.append("恢复自身%.2f生命" % float(skill.heal))
	if skill.has("damage_bonus"): parts.append("普攻+%.2f" % float(skill.damage_bonus))
	if skill.has("damage_percent"):parts.append("普攻额外增加基础攻击的%.2f%%，光环和临时攻击加成不计入增幅"%float(skill.damage_percent))
	if skill.has("attack_speed_percent"):parts.append("攻击速度+%.2f%%"%float(skill.attack_speed_percent))
	if skill.has("move_speed_percent"):parts.append("移动速度+%.2f%%"%float(skill.move_speed_percent))
	if skill.has("armor_bonus"): parts.append("护甲+%.2f" % float(skill.armor_bonus))
	if skill.has("speed_bonus"): parts.append("移动步长%+.2f" % float(skill.speed_bonus))
	if skill.has("range_bonus"): parts.append("普攻射程+%.2f" % float(skill.range_bonus))
	if skill.has("skill_damage_percent"):parts.append("消耗蓝量的技能伤害+%.2f%%，不影响普攻"%float(skill.skill_damage_percent))
	if skill.has("healing_percent"):parts.append("主动治疗+%.2f%%"%float(skill.healing_percent))
	if skill.has("mana_per_second"):parts.append("每秒恢复%.2f蓝量，最多恢复至蓝量上限"%float(skill.mana_per_second))
	if int(skill.get("charges",-1))>0:parts.append("强化接下来%d次%s，次数用尽后结束"%[int(skill.charges),"消耗蓝量的伤害或治疗技能" if skill.get("charge_kind")=="PAID_SKILL" else "普通攻击"])
	if skill.has("duration_ticks"): parts.append("增益持续%.1f秒" % (float(skill.duration_ticks)/20.0))
	if skill.has("drain_percent"): parts.append("吸取对士兵实际伤害的%.2f%%作为自身恢复" % float(skill.drain_percent))
	if skill.has("drain_percent_buff"): parts.append("增益期间普攻吸血%.2f%%" % float(skill.drain_percent_buff))
	if skill.has("execute_percent"): parts.append("目标生命不高于35%%时基础伤害+%.2f%%" % float(skill.execute_percent))
	if skill.has("status_kind"):
		var power := float(skill.status_power)
		var label := "共造成%.2f点奥术基础伤害，每秒约%.2f点" % [float(skill.get("status_total_damage",power*float(skill.status_duration_ticks)/20.0)),power] if skill.status_kind in ["BURN","POISON"] else "移动速度-%.1f%%" % power if skill.status_kind=="SLOW" else "护甲-%.1f" % power
		parts.append("%s：%s，%.1f秒，刷新不叠加" % [{"BURN":"灼烧","POISON":"中毒","SLOW":"减速","ARMOR_BREAK":"破甲"}[skill.status_kind],label,float(skill.status_duration_ticks)/20.0])
		parts.append("相同强度可刷新，较弱效果无法延长较强效果")
	if skill.has("ally_heal"): parts.append("同时恢复附近最多%d名友军各%.2f生命%s" % [int(skill.max_targets),float(skill.ally_heal),"（仅机械）" if skill.get("ally_required_tag","")=="MACHINE" else ""])
	if skill.has("ally_guard"): parts.append("附近友军护甲+%.2f，增益取较强值" % float(skill.ally_guard))
	if skill.has("ally_speed"): parts.append("附近友军移动步长+%.2f" % float(skill.ally_speed))
	if skill.get("cleanse_dot",false): parts.append("清除受益者灼烧和中毒")
	if skill.effect in ["DAMAGE","STUN","ROOT"]: parts.append("不影响建筑；工人只受直接伤害，不受控制，也不提供经验" if float(skill.get("damage",0))>0 else "不影响工人和建筑")
	if skill.effect=="RALLY": parts.append("以自身或指定点为中心，影响最近的最多%d名友军，可包括自身；%s"%[int(skill.max_targets),"英雄倒下后增益失效" if skill.get("requires_live_source",false) else "增益持续至正常到期"])
	if skill.has("heal") or skill.has("ally_heal") or skill.has("drain_percent") or skill.has("drain_percent_buff"): parts.append("仅为存活目标恢复生命，最多恢复至生命上限")
	parts.append("消耗%d蓝量，冷却%.1f秒" % [int(skill.mana_cost),float(skill.max_cooldown_ticks)/20.0])
	return "。\n".join(parts) + "。"

static func initial_inventory() -> Dictionary:
	return Items.initial_inventory()
