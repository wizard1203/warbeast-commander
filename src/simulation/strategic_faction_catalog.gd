class_name StrategicFactionCatalog
extends RefCounted
const Units=preload("res://src/simulation/strategic_unit_catalog.gd")
const ExpansionM66=preload("res://src/simulation/strategic_hero_expansion_m66.gd")
const MagesM68=preload("res://src/simulation/strategic_hero_mages_m68.gd")
const TechV4=preload("res://src/simulation/strategic_faction_technologies_v4.gd")
const FirstRelease=preload("res://src/simulation/first_release_catalog.gd")
const IDS := FirstRelease.FACTION_IDS
const ARMY_VERSION := "outposts-seven-unit-armies-v4"
const SPECIAL_PRODUCER_NAMES := {"HUMAN":"誓桥军院","UNDEAD":"归名密庭","MACHINE":"零轨实验室","FOREST":"古根圣圃","HIGHLAND":"烬龙圣地","UNDERGROUND":"深鸣密地"}
const MAGIC_PRODUCER_NAMES := {"HUMAN":"契约救护院","UNDEAD":"铭灯术庭","MACHINE":"维修能量站","FOREST":"根网织坊","HIGHLAND":"符炉学舍","UNDERGROUND":"菌法孵室"}
const PHYSICAL_PRODUCER_NAMES := {"HUMAN":"誓图军械营","UNDEAD":"灰骨缝营","MACHINE":"铆炉军工营","FOREST":"巡林弓营","HIGHLAND":"山垒战营","UNDERGROUND":"隙道猎营"}
## An opening is a free military grant, not cash or a paid production order.
## Each faction grants exactly 900 gold of recipes and 10 population; the
## separately selected starting hero still costs 5 population.
const OPENING_RECIPES := {
	"HUMAN":[{"unit_type":"hinge_guard","count":3,"warband_index":1},{"unit_type":"bright_crossbow","count":2,"warband_index":2}],
	"UNDEAD":[{"unit_type":"ash_guard","count":2,"warband_index":1},{"unit_type":"bone_archer","count":2,"warband_index":2}],
	"MACHINE":[{"unit_type":"rivet_guard","count":2,"warband_index":1},{"unit_type":"shard_gunner","count":2,"warband_index":2}],
	"FOREST":[{"unit_type":"vine_guard","count":2,"warband_index":1},{"unit_type":"leaf_archer","count":3,"warband_index":2}],
	"HIGHLAND":[{"unit_type":"ridge_guard","count":2,"warband_index":1},{"unit_type":"stone_slinger","count":2,"warband_index":2}],
	"UNDERGROUND":[{"unit_type":"chitin_guard","count":3,"warband_index":1},{"unit_type":"echo_shooter","count":2,"warband_index":2}],
}
const MAIN_UNITS := {"HUMAN":"hinge_guard","UNDEAD":"bone_archer","MACHINE":"shard_gunner","FOREST":"leaf_archer","HIGHLAND":"ridge_guard","UNDERGROUND":"chitin_guard"}
const FACTIONS := {
	"HUMAN":{"id":"HUMAN","name":"誓图","label":"誓图","default_hero":"COMMANDER","hero_archetypes":["COMMANDER","BULWARK","ARCANIST","RANGER","DUELIST"]},
	"UNDEAD":{"id":"UNDEAD","name":"灰契","label":"灰契","default_hero":"ASH_MARSHAL","hero_archetypes":["ASH_MARSHAL","MOURN_ORACLE","CINDER_STALKER"]},
	"MACHINE":{"id":"MACHINE","name":"铆炉","label":"铆炉","default_hero":"COIL_WARDEN","hero_archetypes":["COIL_WARDEN","VOLT_WEAVER","GEAR_HUNTER"]},
	"FOREST":{"id":"FOREST","name":"织叶","label":"织叶","default_hero":"VINE_WARDEN","hero_archetypes":["VINE_WARDEN","LEAF_SEER","WIND_COURIER"]},
	"HIGHLAND":{"id":"HIGHLAND","name":"烬脊","label":"烬脊","default_hero":"RIDGE_JARL","hero_archetypes":["RIDGE_JARL","RUNE_ORACLE","EMBER_CAVALIER"]},
	"UNDERGROUND":{"id":"UNDERGROUND","name":"穴鸣","label":"穴鸣","default_hero":"TUNNEL_SENTINEL","hero_archetypes":["TUNNEL_SENTINEL","ECHO_BINDER","SPORE_STALKER"]},
}
## Original setting. These narratives explain identities, not hidden modifiers.
const NARRATIVES := {
	"HUMAN":{
		"homeland":"断桥平原 · 城邦盟约",
		"lore":"旧王朝撤走了守桥的军队，六座沿河城镇便把粮仓、工坊与渡桥画在同一张誓图上。如今每支远征队都携带一页副本：长官守护的不是王冠，而是地图上仍亮着灯的家。",
		"doctrine":"合页卫掩护弩兵推进，骑兵从侧翼突击远程后排；林契医士单体急救，铜印裁决师以奥术伤害和定身拦住敌人。誓图重弩军士提供远程单点火力，护印帷卫为受威胁同伴分担伤害。",
		"counterplay":"绕过盾列攻击后排，趁铜印封印冷却时突入。重弩军士行动缓慢；将受保护部队与帷卫分开，或集中攻击帷卫，可解除伤害分担。"
	},
	"UNDEAD":{
		"homeland":"余烬湿原 · 归名者的契约",
		"lore":"灰潮烧毁了城邦的户籍，却未烧尽死者留下的誓言。缝骨师用记忆的灰线重连骨骸，允许归名者完成生前未尽的责任；每取回一个名字，都必须有人替它看守熄灭的炉火。",
		"doctrine":"灰骨卫和缝骨重卫承压，铭灯术士以奥术攻击重甲；归名索卫减速追兵，灰烬缝合师治疗伤员并借敌兵阵亡回蓝。摄魂巨骸自行回复生命，以近身灯火压阵；挽灯灵舟从空中施放烬链，持续伤害可为自身回血。",
		"counterplay":"集中爆发突破持续回复和治疗，分散站位并净化烬链。归名索卫是轻甲，钩链有冷却；远离摄魂巨骸可避开灯火脉冲。"
	},
	"MACHINE":{
		"homeland":"旧轨盆地 · 自治炉城",
		"lore":"铆炉最早是为所有城镇修桥的工匠公社。地脉风暴切断旧轨后，守炉者把自身记忆刻入线圈，让没有国王的城市继续运转。他们争夺矿脉，是为了修复那条通往失联工坊的铁路。",
		"doctrine":"铆钉卫掩护碎晶枪手和齿轮战车，维修机负责机械维修；感应织流机以短距奥术连锁攻击聚集敌军。灵核战车轰击地面密阵，截空轨鸢快速转线，可对地空射击并对空中目标造成额外伤害。",
		"counterplay":"分散站位限制连锁和炮击，从侧翼突入缓慢炮阵。齿轮战车和灵核战车不能对空；截空轨鸢是轻甲，怕对空集火。"
	},
	"FOREST":{
		"homeland":"回声林海 · 活根议庭",
		"lore":"织叶把历史种进树根，每一片新叶都记得某位旅人的声音。矿道抽干了林海的地下水，守林者于是带着幼树离开故土，既寻找新的水源，也阻止任何一方把世界变成一座没有季节的工厂。",
		"doctrine":"藤卫掩护叶弓手，缠枝箭减速敌军，鹿骑兵绕后追击支援；根织者治疗多名伤员并提供回蓝，凝露芽师用地面芽阵定身。古根灵卫承担前线压力并治疗附近友军，迁林翎卫从空中快速转线。",
		"counterplay":"趁芽阵冷却时贴近脆弱射手，或用飞行单位避开地面芽阵。集中爆发、分割治疗范围可限制续航；迁林翎卫的攻速强化不提供减伤。"
	},
	"HIGHLAND":{
		"homeland":"烬脊雪线 · 深炉诸垒",
		"lore":"山脊下的深炉曾替各族熔炼盟约印章，火龙则负责守住不会熄灭的火种。大雪封山之后，诸垒各自保留一枚断裂印章；他们下山争夺补给，希望在下一次寒潮前重新接通炉道。",
		"doctrine":"山垒卫承压，砾石投手提供远程撞击火力，炉背斧卫以短时攻速强化进行近战输出。符炉师治疗并强化友军施法，霜炉烬术士以凝焰减速灼烧；符脊巨兽近身震阵，烬脊火龙从空中压制地面密阵。",
		"counterplay":"拉开距离牵制近战斧卫，净化凝焰，从多路绕过缓慢前线。奥术适合攻击重甲，穿刺防空可集中攻击轻甲火龙；分散站位可减少溅射。"
	},
	"UNDERGROUND":{
		"homeland":"菌光地层 · 穴鸣共同体",
		"lore":"穴鸣靠岩壁回声辨认道路，以菌丝交换消息。地表战争震塌了育幼洞，原本互不相见的洞群第一次共享了出口。他们带着孢子灯来到地面，要让所有占据矿井的军队听见深处仍有人生活。",
		"doctrine":"甲壳卫快速近战，回声射手以毒针消耗，洞穴蜥骑追击低血目标；孢织者治疗并减速敌军，裂页鸣师发出地面直线声束。深渊噬兽追猎残兵，玄壳鸣垒为附近友军分担伤害，以裂脊普攻穿透地面敌阵。",
		"counterplay":"横向分散避开声束和裂脊穿透，用空军攻击缺少防空的重型单位。集中处理脆弱输出并净化毒伤，及时撤走低血部队；诱使敌军远离玄壳鸣垒可解除护壳分担。"
	}
}
static func is_valid(id: String)->bool:return id in IDS

static func producer_name(faction_id: String, building_type: String) -> String:
	if building_type=="DRAGON_ROOST": return str(SPECIAL_PRODUCER_NAMES.get(faction_id,"专属军庭"))
	if building_type=="RANGE": return str(MAGIC_PRODUCER_NAMES.get(faction_id,"魔法营"))
	if building_type=="BARRACKS": return str(PHYSICAL_PRODUCER_NAMES.get(faction_id,"物理营"))
	return ""

static func main_unit_for(id: String) -> String:
	if not is_valid(id): return ""
	return str(MAIN_UNITS.get(id, ""))

static func opening_recipe(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not is_valid(id): return result
	for row: Dictionary in OPENING_RECIPES.get(id, []): result.append(row.duplicate(true))
	return result

static func basic_units_for(id: String) -> Array[String]:
	var result: Array[String] = []
	if not is_valid(id): return result
	var main := main_unit_for(id)
	if not main.is_empty(): result.append(main)
	for row: Dictionary in OPENING_RECIPES.get(id, []):
		var unit_type := str(row.unit_type)
		if unit_type not in result: result.append(unit_type)
	return result

static func profile(id: String)->Dictionary:
	if not is_valid(id): return {}
	var result: Dictionary = FACTIONS.get(id,{}).duplicate(true)
	if not result.is_empty():
		result["hero_archetypes"]=heroes_for(id)
		result["specialty"]=specialty(id)
		result["technologies"]=TechV4.list_for(id)
		result["army_version"] = ARMY_VERSION
		result["main_unit"] = main_unit_for(id)
		result["basic_units"] = basic_units_for(id)
		result["opening_recipe"] = opening_recipe(id)
		result["production_names"] = {"BARRACKS":producer_name(id,"BARRACKS"),"RANGE":producer_name(id,"RANGE"),"DRAGON_ROOST":producer_name(id,"DRAGON_ROOST")}
		result["military_roster"] = units_for(id)
	result.merge(NARRATIVES.get(id,{}).duplicate(true))
	return result

static func identity_text(id: String, include_story: bool = true)->String:
	var record := profile(id)
	if record.is_empty(): return ""
	var lines: Array[String] = ["%s · %s" % [record.label,record.homeland]]
	if include_story: lines.append(str(record.lore))
	lines.append(str(record.doctrine))
	lines.append("应对：" + str(record.counterplay))
	return "\n".join(lines)
static func default_hero(id: String)->String:return str(FACTIONS.get(id,{}).get("default_hero","")) if is_valid(id) else ""
static func heroes_for(id: String)->Array:
	if not is_valid(id): return []
	var result: Array=FACTIONS.get(id,{}).get("hero_archetypes",[]).duplicate()
	var supports := {"UNDEAD":["ASH_CHANTER","GRAVE_BELL"],"MACHINE":["COIL_MEDIC","SIGNAL_KEEPER"],"FOREST":["BLOOM_GUIDE","THORN_CHANTER"],"HIGHLAND":["HEARTH_KEEPER","STORM_HERALD"],"UNDERGROUND":["SPORE_GUIDE","QUAKE_PRIEST"]}
	result.append_array(supports.get(id,[]))
	for hero:String in ExpansionM66.IDS:
		if str(ExpansionM66.ROWS[hero][2])==id:result.append(hero)
	for hero:String in MagesM68.IDS:
		if str(MagesM68.ROWS[hero][2])==id:result.append(hero)
	return result
static func hero_archetypes(id: String)->Array:return heroes_for(id)
static func specialty(id: String)->Dictionary:
	if not is_valid(id): return {}
	# Compatibility observation for old consumers only. New menus and the
	# authority use all four stable technology IDs, never SPECIALTY orders.
	var rows := TechV4.list_for(id)
	var result: Dictionary = rows[0].duplicate(true) if not rows.is_empty() else {}
	if not result.is_empty(): result["deprecated_first_only"]=true
	return result
static func units_for(id: String, role: String="")->Array[String]:
	var result: Array[String]=[]
	if not is_valid(id): return result
	for unit_id: String in Units.UNITS:
		var unit: Dictionary=Units.UNITS[unit_id]
		if Units.is_recruitable(unit_id) and unit.faction_id==id and (role.is_empty() or unit.role==role.to_upper()):result.append(unit_id)
	return result
static func get_catalog()->Dictionary:
	var result := {}
	for id: String in IDS: result[id] = profile(id)
	return result
