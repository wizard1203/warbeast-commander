extends RefCounted
## Source-owned finite buffs. A cast never overwrites another skill's timer.
const FIELDS := ["damage_percent","damage_bonus","attack_speed_percent","move_speed_percent","speed_bonus","range_bonus","drain_percent","armor_bonus","magic_resist_percent","mana_per_second","skill_damage_percent","healing_percent","hard_duration_percent","weak_duration_percent","dot_duration_percent"]

static func apply(unit:Dictionary,skill:Dictionary,tick:int,source_id:String,category:String="SELF_SKILL")->void:
	if not unit.has("source_buffs"):unit["source_buffs"]={}
	var entry:={"id":str(skill.id),"source_id":source_id,"category":category,"expires_tick":tick+int(skill.get("duration_ticks",0)),"requires_source":bool(skill.get("requires_live_source",false))}
	for field:String in FIELDS:entry[field]=float(skill.get(field,skill.get("drain_percent_buff",0) if field=="drain_percent" else 0))
	entry["charges"]=int(skill.get("charges",-1))
	entry["charge_kind"]=str(skill.get("charge_kind",""))
	if skill.get("effect","")=="DAMAGE_LINK":
		for field:String in ["effect","cast_tick","radius","redirect_percent","hero_redirect_percent","source_min_hp"]:entry[field]=skill[field]
		entry.requires_source=true
	unit.source_buffs[source_id+":"+str(skill.id)]=entry

static func values(unit:Dictionary,tick:int,bodies:Dictionary)->Dictionary:
	var result:={}
	var groups:={}
	for field:String in FIELDS:result[field]=0
	for key:String in unit.get("source_buffs",{}).keys():
		var entry:Dictionary=unit.source_buffs[key]
		var source:Dictionary=bodies.get(str(entry.source_id),{})
		if int(entry.expires_tick)<=tick or int(entry.get("charges",-1))==0 or int(unit.hp)<=0 or (bool(entry.requires_source) and int(source.get("hp",0))<=0):
			unit.source_buffs.erase(key)
			continue
		var category:=str(entry.category)
		if not groups.has(category):groups[category]={}
		for field:String in FIELDS:groups[category][field]=maxf(float(groups[category].get(field,0)),float(entry.get(field,0)))
	for group:Dictionary in groups.values():
		for field:String in FIELDS:result[field]+=float(group.get(field,0))
	result.hard_duration_percent=mini(10,int(result.hard_duration_percent))
	result.weak_duration_percent=mini(35,int(result.weak_duration_percent))
	result.dot_duration_percent=mini(40,int(result.dot_duration_percent))
	return result

static func consume(unit:Dictionary,kind:String,tick:int)->void:
	for entry:Dictionary in unit.get("source_buffs",{}).values():
		if int(entry.get("expires_tick",-1))>tick and entry.get("charge_kind","")==kind and int(entry.get("charges",-1))>0:
			entry.charges=int(entry.charges)-1
