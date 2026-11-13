extends RefCounted
## Detached VISUAL samples. No Session, battle settlement, global RNG or clock.
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Neutrals = preload("res://src/simulation/neutral_catalog.gd")
const AuraArt = preload("res://src/presentation/heroic_aura_art.gd")
const Items = preload("res://src/simulation/strategic_hero_items.gd")
const ArmySupport = preload("res://src/simulation/strategic_army_support.gd")
const Innates = preload("res://src/simulation/strategic_hero_innates.gd")
const Buffs = preload("res://src/simulation/strategic_combat_buffs.gd")
const Weapons = preload("res://src/presentation/heroic_weapon_choreography.gd")
const FactionAV = preload("res://src/presentation/heroic_faction_av.gd")
const STATUS_NAMES := {"STUN":"眩晕","ROOT":"定身","SLOW":"减速","BURN":"灼烧","POISON":"中毒","ARMOR_BREAK":"破甲","HEAL":"恢复","FERVOR":"强化","GUARD":"护盾","AURA":"光环"}
const CYCLE := 2.4

static func actors(faction: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if faction == "NEUTRAL":
		for profile: Dictionary in Neutrals.get_catalog().values():
			var body := profile.duplicate(true)
			body["faction_id"] = str(profile.origin_faction_id) if not str(profile.origin_faction_id).is_empty() else "UNDERGROUND" if profile.series_id=="SPOREBROOD" else "HIGHLAND" if profile.series_id in ["ROCKKIN","RUNE_WILD"] else "UNDEAD" if profile.series_id=="GRAVEBOUND" else "FOREST" if profile.series_id=="THORN_WATCH" else "HUMAN"
			body.merge({"side":"NEUTRAL","alive":true,"hp":profile.max_hp,"mana":profile.get("max_mana",0),"neutral":true,"neutral_level":profile.level,"population":0,"neutral_series_id":profile.series_id,"neutral_origin_faction_id":profile.origin_faction_id},true)
			result.append({"id":"NEUTRAL:"+str(profile.id),"label":str(profile.label),"group":"野怪 L%d"%int(profile.level),"unit":body,"description":str(profile.description),"neutral_skill":profile.skill.duplicate(true)})
		return result
	if not Factions.is_valid(faction): return result
	for archetype: String in Factions.heroes_for(faction):
		var profile := Heroes.profile(archetype)
		var body := _body("hero",faction,archetype)
		result.append({"id":"hero:"+archetype,"label":str(profile.name),"group":str(profile.role),"unit":body,"description":str(profile.description)})
	for id: String in Factions.units_for(faction):
		if id in ["worker","hero"]: continue
		var body := _body(id,faction)
		result.append({"id":id,"label":str(body.label),"group":"部队 · %d人口"%int(body.population),"unit":body,"description":str(body.get("trait_description",""))})
	# Fixed-outpost release has automatic income and no playable workers.
	return result

static func _body(id: String, faction: String, archetype: String="") -> Dictionary:
	var body := Units.stats_for(id,archetype if not archetype.is_empty() else Heroes.DEFAULT_ARCHETYPE)
	body.merge({"id":"preview:"+faction+":"+id+":"+archetype,"faction_id":faction,"side":"PLAYER","hp":int(body.max_hp),"alive":true,"mana":int(body.get("max_mana",0))},true)
	if id=="hero": body.merge({"hero_archetype":archetype,"hero_level":8,"innate":Heroes.profile(archetype).innate},true)
	return body

static func abilities(actor: Dictionary) -> Array[Dictionary]:
	if actor.is_empty(): return []
	var body: Dictionary = actor.unit
	var result: Array[Dictionary] = [{"id":"ATTACK","label":"普通攻击","kind":"ACTION","icon":"sword","max_rank":1,"description":"出手 → 弹道／挥击 → 命中余韵。样片固定靶位，不表示射程或伤害结算。"}]
	if str(body.unit_type)=="hero":
		for skill: Dictionary in Heroes.skills_for(str(body.hero_archetype)):
			var visual:=Weapons.profile(str(skill.id))
			var identity:="\n武器演出：%s\n动作：%s\n故事：%s\n仅改变演出，不改变数值或命中。"%[str(visual.get("weapon_family","")),str(visual.get("phase_signature","")),str(visual.get("story_anchor",""))] if not visual.is_empty() else ""
			var authored:=FactionAV.skill_profile(str(skill.id))
			if not authored.is_empty():identity="\nM63演出：%s\n分镜：%s\n故事：%s\n反制：%s\n仅改变表现；被动不生成主动施放。"%[str(authored.gesture)," / ".join(PackedStringArray(authored.phases)),str(authored.story_anchor),str(authored.counterplay)]
			result.append({"id":str(skill.id),"label":str(skill.name),"kind":"PASSIVE" if bool(skill.passive) else "SKILL","icon":str(skill.id),"max_rank":int(skill.max_level),"description":Heroes.describe_skill(skill)+identity})
		var innate: Dictionary=Heroes.profile(str(body.hero_archetype)).innate
		result.append({"id":str(innate.id),"label":"天赋 · "+str(innate.name),"kind":"INNATE","icon":"hero","max_rank":8,"description":str(innate.description)})
		for id: String in ["WAR_STANDARD","AEGIS_STANDARD","SPRING_STANDARD","MANA_STANDARD"]:
			var item: Dictionary = Items.ITEMS[id]
			result.append({"id":id,"label":"装备光环 · "+str(item.name),"kind":"ITEM_AURA","icon":"rally","max_rank":1,"description":str(item.description)})
	elif int(body.get("heal",0))>0:
		result.append({"id":"HEAL","label":"自动治疗","kind":"ACTION","icon":"potion","max_rank":1,"description":"治疗%d生命，消耗%d蓝量，间隔%.1f秒。样片仅演示治疗视觉。"%[int(body.heal),int(body.heal_mana_cost),float(body.heal_cooldown_ticks)/20.0]})
	if ArmySupport.CATALOG.has(str(body.unit_type)):
		var support:Dictionary=ArmySupport.CATALOG[str(body.unit_type)]
		result.append({"id":support.id,"label":support.name,"kind":"SUPPORT","icon":"rally","max_rank":1,"description":support.description})
	var neutral: Dictionary=actor.get("neutral_skill",{})
	if not neutral.is_empty(): result.append({"id":str(neutral.id),"label":str(neutral.label),"kind":"NEUTRAL","icon":"hero","max_rank":1,"description":str(neutral.description)})
	for kind: String in STATUS_NAMES:
		result.append({"id":"STATUS:"+kind,"label":"状态 · "+str(STATUS_NAMES[kind]),"kind":"STATUS","icon":"potion" if kind=="HEAL" else "armor" if kind=="GUARD" else "tech","max_rank":1,"description":"%s效果样片；正式战场仅在真实状态生效期间显示，不凭距离推断。"%str(STATUS_NAMES[kind])})
	return result

static func sample(actor: Dictionary, ability: Dictionary, rank: int, seconds: float) -> Dictionary:
	if actor.is_empty() or ability.is_empty(): return {}
	var elapsed := fposmod(seconds,CYCLE) if is_finite(seconds) else 0.0
	var phase := clampf((elapsed-0.2)/1.1,0,0.999)
	var active := elapsed>=0.2 and elapsed<1.3
	var body: Dictionary=actor.unit.duplicate(true)
	var id := str(ability.id)
	var kind := str(ability.kind)
	var skill := {}
	var status := {}
	var persistent: Dictionary = {}
	var pose := {"action":"IDLE","phase":phase,"direction":Vector2.RIGHT,"animation_tick":int(elapsed*20)}
	if kind=="SKILL" or kind=="PASSIVE":
		skill=Heroes.skill_at_level(id,clampi(rank,1,int(ability.max_rank)))
		if kind=="SKILL" and active: pose.action="SKILL_"+id
		elif kind=="PASSIVE": persistent=AuraArt.identity(id,str(body.faction_id),float(skill.get("aura_radius",0)) if skill.get("effect")=="AURA" else 0,"SKILL")
	elif kind=="SUPPORT":
		skill=ArmySupport.visual_skill(id)
		if active:pose.action="SKILL_"+id
		if id=="ROOT_NETWORK":persistent=AuraArt.identity(id,str(body.faction_id),160,"SUPPORT")
	elif kind=="NEUTRAL":
		skill=actor.neutral_skill.duplicate(true)
		skill.merge({"effect":str(skill.get("control","DAMAGE")),"name":skill.label,"level":1,"delivery":"AREA" if int(skill.get("max_targets",1))>1 else "DIRECT","target_mode":"ENEMY"},true)
		if active: pose.action="SKILL_"+id
	elif kind=="INNATE":
		body["hero_level"]=clampi(rank,1,8)
		body["innate"]=Innates.profile(str(body.hero_archetype),clampi(rank,1,8))
		persistent=AuraArt.identity(id,str(body.faction_id),float(body.get("innate",{}).get("radius",0)),"INNATE")
	elif kind=="ITEM_AURA":
		persistent=AuraArt.identity(id,str(body.faction_id),float(Items.ITEMS[id].aura_radius),"ITEM")
	elif kind=="STATUS":
		status={"kind":id.trim_prefix("STATUS:"),"remaining_ticks":100,"source_faction":body.faction_id}
	elif active: pose.action=id
	pose["skill"]=skill
	# Detached demonstration of finite benefits. The genuine world reads live
	# Combat records instead; this fixture never claims a cast was settled.
	if kind=="SKILL" and elapsed>=.2 and str(body.get("unit_type",""))=="hero":
		if skill.get("effect","")=="DAMAGE_BUFF" or (skill.get("effect","")=="HEAL" and skill.has("speed_bonus")):
			Buffs.apply(body,skill,4,str(body.id))
		if int(skill.get("ally_guard",0))>0:
			body["guard_until_tick"]=4+int(skill.get("duration_ticks",60))
			body["guard_armor_bonus"]=int(skill.ally_guard)
	return {"unit":body,"pose":pose,"skill":skill,"status":status,"persistent":persistent,"elapsed":elapsed,"active":active,"kind":kind,"rank":clampi(rank,1,int(ability.max_rank)),"visual_sample":true,"settlement":false}
