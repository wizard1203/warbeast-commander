extends RefCounted
## Read-only projections of the real content catalogs. No match or commands.
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const HeroEconomy = preload("res://src/simulation/strategic_hero_economy.gd")
const HeroGrowth = preload("res://src/simulation/strategic_hero_progression.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const World = preload("res://src/simulation/strategic_world.gd")
const Progression = preload("res://src/simulation/strategic_progression_catalog.gd")
const Damage = preload("res://src/simulation/strategic_damage_rules.gd")
const Neutrals = preload("res://src/simulation/neutral_catalog.gd")
const EncountersV4 = preload("res://src/simulation/strategic_neutral_encounters.gd")
const Economy = preload("res://src/simulation/strategic_economy_catalog.gd")
const CATEGORIES := [
	{"id":"IDENTITY", "label":"种族特色"}, {"id":"TROOPS", "label":"兵种"},
	{"id":"HEROES", "label":"英雄"}, {"id":"BUILDINGS", "label":"建筑"},
	{"id":"TECH", "label":"科技"}, {"id":"ITEMS", "label":"装备 / 药水"},
	{"id":"NEUTRALS", "label":"野怪"}, {"id":"COMBAT", "label":"攻防指南"},
	{"id":"ECONOMY", "label":"经济 / 防御"},
]
const ROLE_LABELS := {"WORKER":"经营 / 建设", "FRONTLINE":"前线步兵", "RANGED":"远程火力", "HEAVY":"重型单位", "CAVALRY":"机动骑兵", "SUPPORT":"战场支援"}

static func entries(faction_id: String, category: String) -> Array[Dictionary]:
	if not Factions.is_valid(faction_id): return []
	match category:
		"IDENTITY": return _identity(faction_id)
		"TROOPS": return _troops(faction_id)
		"HEROES": return _heroes(faction_id)
		"BUILDINGS": return _buildings(faction_id)
		"TECH": return _technologies(faction_id)
		"ITEMS": return _items()
		"NEUTRALS": return _neutrals()
		"COMBAT": return _combat()
		"ECONOMY": return _economy()
	return []

static func _entry(id: String, label: String, kind: String, role: String, description: String, visual: Dictionary = {}, icon: String = "army") -> Dictionary:
	return {"id":id, "label":label, "kind":kind, "role":role, "description":description, "visual":visual.duplicate(true), "icon":icon, "cost":{}, "population":-1, "required_tier":0}

static func _identity(faction: String) -> Array[Dictionary]:
	var record := Factions.profile(faction)
	var first := Factions.main_unit_for(faction)
	var result: Array[Dictionary] = []
	result.append(_entry(faction, str(record.label), "UNIT", "种族背景 / 战术", "[b]%s[/b]\n\n%s\n\n[b]战术特色[/b]\n%s\n\n[b]应对方法[/b]\n%s" % [record.homeland,record.lore,record.doctrine,record.counterplay], Units.stats_for(first)))
	for special:Dictionary in preload("res://src/simulation/strategic_faction_technologies_v4.gd").list_for(faction):
		var technology := _entry(str(special.id),str(special.label),"ICON","本族专属科技",str(special.description)+"\n\n需要%d级基地与完工科技兵工坊。研究时间：%.1f秒。"%[int(special.required_base_tier),float(special.duration_ticks)/20.0],{},"tech")
		technology.cost=special.cost.duplicate(true);technology.required_tier=int(special.required_base_tier)
		result.append(technology)
	return result

static func _troops(faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# The fixed-outpost ruleset has no recruitable or simulated workers.
	var ids: Array[String] = []
	ids.append_array(Factions.units_for(faction))
	for id: String in ids:
		var recipe := Units.profile(id)
		var stats: Dictionary = recipe.stats
		var producer: String = recipe.building_type
		var tier := maxi(int(recipe.required_base_tier), int(Progression.BUILDING_TIERS.get(producer,1)))
		var description := str(recipe.get("role_brief",""))+"\n优势："+"；".join(recipe.get("strengths",[]))+"\n弱点："+"；".join(recipe.get("weaknesses",[]))+"\n\n"+_stats(stats) + "\n\n[b]%s[/b]\n%s\n\n[b]招募[/b]\n%d级基地 · %s\n训练时间：%.1f秒；占%d人口。" % [stats.get("trait_name","单位特色"),stats.get("trait_description",""),tier,World.building_catalog_for_faction(faction)[producer].label,float(recipe.duration_ticks)/20.0,recipe.population]
		var visual := stats.duplicate(true)
		visual.faction_id = faction
		var item := _entry(id, str(recipe.label), "UNIT", str(recipe.get("combat_role_label",ROLE_LABELS.get(recipe.role,recipe.role))), description, visual)
		item.merge({"cost":recipe.cost.duplicate(true),"population":int(recipe.population),"required_tier":tier},true)
		result.append(item)
	return result

static func _heroes(faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in Factions.heroes_for(faction):
		var profile := Heroes.profile(id)
		var stats := Units.stats_for("hero",id)
		var second: Dictionary = HeroEconomy.RECRUIT_COSTS[2]
		var third: Dictionary = HeroEconomy.RECRUIT_COSTS[3]
		var description := "[b]%s[/b]\n3个可学习技能，另有独立天赋。普通技能最高3级；大招在英雄5级、8级时可提升。" % profile.role
		if profile.has("innate"):description+="\n\n[b]天赋 · %s[/b]\n%s"%[profile.innate.name,profile.innate.description]
		description += "\n\n[b]招募与复活[/b]\n初始英雄可从本族任选，免费获得。\n第二位：%d金币，需要二级基地；第三位：%d金币，需要三级基地。训练时间均为%.1f秒。\n整局最多拥有3种英雄，阵亡仍占名额。已有英雄可在幸存祭庭复活，无需再次满足基地等级。\n复活费用：160＋40×（等级−1）金币；等待时间为每级16.5秒，最长55秒。保留成长与现有行囊，已掉落装备不会返还。\n\n[b]技能与升级效果[/b]" % [second.MATERIAL,third.MATERIAL,HeroEconomy.RECRUIT_TICKS/20.0]
		for skill_id: String in profile.skill_ids:
			var skill := Heroes.skill_at_level(skill_id,1)
			description += "\n\n[color=#ecd095][b]%s%s[/b][/color]" % [skill.name," · 大招" if skill.ultimate else " · 被动" if skill.passive else ""]
			for rank: int in range(1,HeroGrowth.max_skill_rank(skill_id)+1):
				var ranked := Heroes.skill_at_level(skill_id,rank)
				description += "\n%s" % ranked.description
		description += "\n\n" + _stats(stats) + "\n\n[b]成长[/b]\n%s\n\n每位英雄独立背包：%d个装备槽、%d类消耗品槽。" % [profile.growth_description,Items.EQUIPMENT_SLOTS,Items.CONSUMABLE_SLOTS]
		var visual := stats.duplicate(true)
		visual["hero_archetype"] = id
		visual["archetype"] = id
		var item := _entry(id, str(profile.name) + " · " + str(profile.title), "UNIT", str(profile.role), description, visual)
		# No single flat price describes free first pick, later recruits and
		# level-based revival. The detail above explains the actual contexts.
		item.cost = {}
		item["contextual_hero_cost"] = true
		item.population = int(Units.UNITS.hero.population)
		item.required_tier = 0
		result.append(item)
	return result

static func _buildings(faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var catalog: Dictionary=World.building_catalog_for_faction(faction)
	for id: String in catalog:
		# V2 has exactly the paid tower pads; the old free site-tower is not
		# an additional building that players can place in this ruleset.
		if id in ["SITE_TOWER","WORKSHOP"]: continue
		var record: Dictionary = catalog[id]
		var tier := int(Progression.BUILDING_TIERS.get(id,1))
		var outputs: Array[String] = []
		for unit_id: String in Units.get_units_for_faction(faction):
			if unit_id == "worker": continue
			var unit: Dictionary = Units.UNITS[unit_id]
			if unit.building_type == id: outputs.append("全部本族英雄" if unit_id == "hero" else str(unit.label))
		var description := "[b]建筑属性[/b]\n生命 %d · %s · 护甲 %d (剩余%.1f%%)\n需要%d级基地。建造时间：%.1f秒；失去据点完整控制时暂停施工。" % [record.hp,Damage.armor_label("FORTIFIED"),int(record.get("armor",0)),Damage.armor_factor(int(record.get("armor",0)))*100.0,tier,float(record.work)/20.0]
		if id == "BASE": description += "\n\n每个资源根据地只有1个基地空位。完全占领且本点基地完工后，有限金矿自动产出金币；人口来自占领：资源根据地30，人口据点10，纯资源点0。建筑本身不增加人口，也不生产工人。\n\n基地升级2/3级，分别解锁更高科技及首次招募第2/3位英雄的权限；整局最多三种，死亡仍占名册，已有英雄复活不重新要求原基地等级。升级期间本营所停止生产。"
		elif id == "TOWER":
			description += "\n\n自动攻击 · %s · 主伤害%d · 射程%d · 间隔%.2f秒。" % [Damage.attack_label(str(record.attack_type)),record.damage,record.attack_range,float(record.attack_cooldown_ticks)/20.0]
			if int(record.get("splash_max_targets",0))>0:description+="\n主目标旁%d范围，最多%d名地面敌人各受%d伤害；不伤友军、不重复主目标。"%[record.splash_radius,record.splash_max_targets,record.splash_damage]
			description+="\n"+str(record.get("counterplay",""))+"\n\n资源根据地最多5座，人口据点和纯资源点各最多2座；一级基地即可建造。强化需2级基地，%.1f秒，不治疗建筑；费用：%d金币。"%[float(record.upgrade_quote.duration_ticks)/20.0,record.upgrade_quote.cost.MATERIAL]
		elif id == "ESSENCE_MINE": description += "\n\n只可建在已完全占领的纯资源点或富金矿点的唯一矿场空位。必须先清除野怪守军；完工后自动开采有限金矿，无需工人。纯资源点不提供人口，不能建基地或其他功能楼，只额外提供2个防御塔空位。"
		elif id == "SHOP": description += "\n\n资源根据地和人口据点各有1个商店空位，纯资源点不能建商店。主基地初始商店已完工，后续商店需要付费建造；必须完整控制据点且商店存活完工，英雄在服务范围内才能交易。\n\n装备、药水及缺件合成均只消耗金币。每位英雄4个装备槽、2类消耗品槽；同类消耗品最多2份，共享20秒冷却。"
		elif id == "FOUNDRY": description += "\n\n研究攻击、护甲与本族特色科技；具体等级与价格见科技页。"
		elif id == "BARRACKS":description+="\n\n物理营：步兵、射手、骑兵和机械火力。人口据点只有一个共享军营空位，可选择物理营或魔法营，不能同时建两种。"
		elif id == "RANGE":description+="\n\n魔法营：攻击术士、治疗、维修和能量支援。初始已赠送；普通支援需要二级基地。人口据点军营二选一。"
		elif id == "DRAGON_ROOST":description+="\n\n%s，仅资源根据地可建，需要三级基地；提供两种本族专属兵。"%Factions.producer_name(faction,id)
		elif outputs.is_empty(): description += "\n\n可在资源根据地的对应空位建造。"
		if not outputs.is_empty(): description += "\n\n[b]可招募[/b]\n" + "、".join(outputs) + "。\n需满足兵种的基地等级、金币和人口要求。"
		var item := _entry(id, str(record.label), "BUILDING", "建筑 · %d级" % tier, description, {"building_type":id,"faction_id":faction,"side":"PLAYER","complete":true,"hp":record.hp})
		item.cost = record.cost.duplicate(true)
		item.required_tier = tier
		result.append(item)
	return result

static func _technologies(faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target: int in Progression.BASE_UPGRADES:
		var upgrade: Dictionary = Progression.BASE_UPGRADES[target]
		var item := _entry("BASE_%d" % target,"%d级基地" % target,"BUILDING","升级解锁", "在完工营所升级；全军最高完工基地等级作为解锁等级。\n\n升级至%d级解锁首次招募第%d位英雄的权限，并继续解锁相应兵种、建筑与科技。整局名册最多三种，死亡不腾位；已拥有英雄复活不重新要求原招募基地等级。耗时%.1f秒，期间该营所不出兵。\n\n升级不直接增加人口、不扩大体积、不治疗基地或全军。" % [target,target,float(upgrade.duration_ticks)/20.0],{"building_type":"BASE","faction_id":faction,"side":"PLAYER","hp":1000,"complete":true,"base_tier":target})
		item.cost = upgrade.cost.duplicate(true)
		item.required_tier = target-1
		result.append(item)
	for id: String in World.TECHNOLOGY_CATALOG:
		if id == "SPECIALTY": continue
		var record: Dictionary = World.TECHNOLOGY_CATALOG[id]
		for rank: int in range(1,int(record.max_level)+1):
			var description := "全体正规兵和英雄每级%s+%d，升至%d级累计+%d。\n\n需要%d级基地、完工科技兵工坊及前一级研究。" % ["普攻攻击力" if id=="ATTACK" else "护甲",record.effect_per_level,rank,rank*int(record.effect_per_level),maxi(2,rank)]
			var item := _entry("%s_%d" % [id,rank],"%s %d" % [record.label,rank],"ICON","通用科技",description,{},"sword" if id=="ATTACK" else "armor")
			var quote:=Economy.tech_quote(id,rank)
			item.cost=quote.cost.duplicate(true)
			item.description+="\n研究时间：%.1f秒。"%(float(quote.duration_ticks)/20.0)
			item.required_tier = maxi(2,rank)
			result.append(item)
	var identity:=_identity(faction)
	for index:int in range(1,identity.size()):result.append(identity[index])
	return result

static func _items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in Items.ITEMS:
		var record: Dictionary = Items.ITEMS[id]
		var category: String = {"BASIC":"初级装备","ADVANCED":"合成装备","AURA":"光环装备","CONSUMABLE":"消耗品"}.get(str(record.tier),str(record.tier))
		var description := str(record.description)
		if record.has("components"):
			var components: Array[String] = []
			for component: String in record.components: components.append(str(Items.ITEMS[component].name))
			var total := Items.total_cost(id)
			description += "\n\n[b]合成[/b]\n%s → %s\n完整购入：%d金币。已有组件自动抵扣，也可直接购买并补齐缺件；成品占1个装备槽。" % [" + ".join(components),record.name,total.MATERIAL]
		description += "\n\n[b]携带与使用[/b]\n%s\n购买时需英雄靠近己方商店。" % ("每位英雄最多携带2类消耗品，每类2份；使用后共享20秒冷却。" if record.get("consumable",false) else "每位英雄有4个装备槽，同件装备最多携带1件。")
		if record.tier in ["ADVANCED","AURA"]: description += "\n\n[b]阵亡掉落[/b]\n英雄阵亡时掉落，任意阵营英雄均可拾取。地面物品保留10分钟；背包已满时留在地面。"
		var item := _entry(id,str(record.name),"ICON",category,description,{},id)
		item.cost = Items.total_cost(id)
		result.append(item)
	return result

static func _neutrals() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var catalog := Neutrals.get_catalog()
	for id: String in catalog:
		var record: Dictionary = catalog[id]
		var skill: Dictionary = record.get("skill",{})
		var description := "[b]等级%d · %s[/b]\n" % [int(record.level),str(record.get("series_label","荒野"))]
		if not skill.is_empty(): description += "\n[b]精英技能：%s[/b]\n%s\n\n" % [skill.label,skill.description]
		else: description += "无主动技能。\n\n"
		description += str(record.get("description","")) + "\n\n" + _stats(record)
		description += "\n\n[b]击杀经验[/b]\n每只%d经验，由附近己方英雄平分。较强营地适合集结部队后挑战。" % int(record.xp_reward)
		if record.get("template_id") == "STRAGGLER":
			description = "[b]等级1 · 荒径游兵[/b]\n2–3名游兵成组，没有主动技能。\n\n"+_stats(record)+"\n\n[b]击杀奖励[/b]\n每只%d经验，由附近己方英雄平分。2只营总赏金%d金币，3只营%d金币，逐只击杀领取；赏金不扣维护费，不掉落装备。\n\n营地每局随机，离巢过远会返回并恢复生命；清除后不再刷新。"%[int(record.xp_reward),EncountersV4.scattered_bounty_total(2),EncountersV4.scattered_bounty_total(3)]
		var visual := record.duplicate(true)
		visual["neutral"] = true
		visual["side"] = "NEUTRAL"
		visual["faction_id"] = record.get("origin_faction_id","NEUTRAL")
		var item := _entry(id,str(record.label),"UNIT","Lv.%d · %s" % [int(record.level),str(record.get("series_label","荒野"))],description,visual)
		result.append(item)
	return result

static func _combat() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var description := "[b]伤害倍率[/b]\n70%表示承受原伤害的70%；200%表示承受双倍伤害。攻击类型与护甲类型决定第一步倍率，之后再计算数值护甲和适用魔抗。\n\n[b]计算方式[/b]\n" + Damage.formula_summary()
	for armor: int in [0,5,10,-5]: description += "\n\n" + Damage.numeric_armor_summary(armor)
	description += "\n\n例如：原伤害100，类型倍率70%，数值护甲5，最终约为100 × 0.70 / 1.30 = 54。有效命中取整后至少造成1点伤害。\n\n英雄承受的基础控制时长为70%，再计算控制抗性；持续伤害不因此缩短。"
	result.append(_entry("FORMULA","如何计算伤害","ICON","伤害剩余 / 数值护甲",description,{},"tech"))
	for attack: String in Damage.ATTACKS:
		result.append(_entry("ATTACK_"+attack,Damage.attack_label(attack),"ICON","攻击 → 全部护甲","[b]类型后伤害剩余（尚未应用数值护甲）[/b]\n\n"+Damage.attack_summary(attack),{},"hero" if attack=="ARCANE" else "sword"))
	for armor: String in Damage.ARMORS:
		result.append(_entry("ARMOR_"+armor,Damage.armor_label(armor),"ICON","护甲 ← 全部攻击","[b]类型后伤害剩余（尚未应用数值护甲）[/b]\n\n"+Damage.armor_summary(armor),{},"armor"))
	return result

static func _economy() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for resource: String in Economy.RESOURCE_KEYS:
		var description := "[b]%s[/b]\n建造、招募、研究和购买物品均消耗金币。普通开局拥有%d金币。\n\n清除守军、完整占领并建成基地或采矿场后，自动开采金币。失去完整占领、经济建筑被毁或矿脉耗尽时停止产出。" % [Economy.RESOURCE_LABELS[resource],int(Economy.INITIAL_STOCK.MATERIAL)]
		description += "\n\n资源根据地：基地完工后20金币/秒，初始储量45000。\n普通金矿小点：采矿场完工后4金币/秒，储量6000。\n富金矿点：采矿场完工后8金币/秒，储量12000，守军更强。以上为维护费前速率；本局剩余量与净收入以资源来源面板为准。"
		description += "\n\n已用人口≤50 / 51–80 / 81+时，自动金币收入保留100% / 70% / 40%；预留人口不计。击杀赏金、出售和取消退款不扣维护费。金币采集不会增加人口。"
		result.append(_entry("RESOURCE_"+resource,str(Economy.RESOURCE_LABELS[resource]),"ICON","据点自动经济",description,{},"gold"))
	result.append(_entry("TERRITORY_DEFENSE","据点建设与防御","BUILDING","据点 / 基地 / 防御塔","[b]据点与建筑位[/b]\n资源根据地：提供30人口，各功能建筑限1座，防御塔最多5座。\n人口据点：提供10人口；物理营或魔法营二选一，商店1座，防御塔最多2座。\n纯资源点：不提供人口，可建1座采矿场和2座防御塔。\n\n完整占领后，单击空位并确认建造。施工自动进行；失去完整控制时暂停。\n\n[b]防御[/b]\n完工基地与防御塔自动攻击范围内的敌人。己方占领点数清零前仍会防守，清零后停止；夺占过程中保持休眠。占点不会免费获得敌方建筑。\n\n各族防御塔的攻击类型与溅射不同，详细属性见建筑页。防御塔一级基地可建；强化需二级基地，耗时25秒，升级不恢复建筑生命。",{"building_type":"TOWER","faction_id":"HUMAN","side":"PLAYER","complete":true,"hp":1000}))
	return result

static func _stats(stats: Dictionary) -> String:
	var cooldown := int(stats.get("attack_cooldown_ticks",stats.get("cooldown",0)))
	return "[b]基础属性[/b]\n生命 %d · 攻击 %d · 护甲 %d (剩余%.1f%%)\n射程 %d · 攻击间隔 %.2f秒 · 移速 %d/秒\n攻击类型：%s\n护甲类型：%s\n护甲括号表示数值护甲计算后的伤害剩余，需另乘护甲类型倍率。" % [int(stats.get("max_hp",0)),int(stats.get("damage",0)),int(stats.get("armor",0)),Damage.armor_factor(int(stats.get("armor",0)))*100.0,int(stats.get("attack_range",stats.get("range",0))),float(cooldown)/20.0,int(stats.get("speed",0))*20,Damage.attack_label(str(stats.get("attack_type","EDGE"))),Damage.armor_label(str(stats.get("armor_type","UNARMORED")))]
