extends RefCounted
## Exact V4 troop sound identity and bounded per-paid-cast phase ownership.
## Not a sampler, command source, fallback synth or battle rule owner.
const Catalog=preload("res://src/simulation/strategic_troop_skills_v4.gd")
const VERSION:="outposts-v4-troop-audio-r1"
const LIMIT:=512
var _casts:Dictionary={}
var _cast_order:Array[String]=[]
var _seen:Dictionary={}
var _order:Array[String]=[]

static func owns_skill(unit_type:String,skill_id:String)->bool:
	return not skill_id.is_empty() and str(Catalog.CATALOG.get(unit_type,{}).get("id",""))==skill_id

static func phase(cue:Dictionary)->String:
	if str(cue.get("phase",""))=="END" or bool(cue.get("dot",false)):return ""
	var kind:=str(cue.get("kind",""))
	if kind in ["CAST","SKILL"]:return "CAST"
	if kind in ["HIT","CONTROL","STATUS","HEAL","BUFF"]:return "IMPACT"
	return ""

static func mapping_key(cue:Dictionary)->String:
	var type:=str(cue.get("unit_type",cue.get("source",{}).get("unit_type","")))
	var skill:=str(cue.get("skill_id",""))
	if not str(cue.get("hero_archetype","")).is_empty() or not owns_skill(type,skill):return ""
	var stage:=phase(cue)
	return "TROOP_SKILL:%s:%s:%s"%[type,skill,stage] if not stage.is_empty() else ""

func _domain(cue:Dictionary)->String:
	return "%s:%s:%s:life%d"%[str(cue.get("entity_id",cue.get("source",{}).get("id",""))),str(cue.get("unit_type","")),str(cue.get("skill_id","")),int(cue.get("source_life_generation",1))]

func phase_owner(cue:Dictionary,key:String)->String:
	if bool(cue.get("preview_only",false)):return "preview:"+str(cue.get("r7_preview_id",""))+":"+key
	var domain:=_domain(cue)
	var tick:=int(cue.get("tick",-1))
	if key.ends_with(":CAST"):return domain+":paid:"+str(cue.get("event_id",tick))+":CAST"
	var cast:Dictionary=_casts.get(domain,{})
	if not cast.is_empty() and int(cast.tick)<=tick:return str(cast.owner).trim_suffix(":CAST")+":IMPACT"
	# Off-camera casts cannot reveal their source. An actual visible activation
	# without its earlier CAST may play one contact, never each DOT pulse.
	return domain+":contact:"+str(tick)+":IMPACT"

func seen(cue:Dictionary,key:String)->bool:
	return _seen.has(phase_owner(cue,key))

func remember(cue:Dictionary,key:String)->void:
	var owner:=phase_owner(cue,key)
	if _seen.has(owner):return
	_seen[owner]=true;_order.append(owner)
	if _order.size()>LIMIT:_seen.erase(_order.pop_front())
	if not key.ends_with(":CAST") or bool(cue.get("preview_only",false)):return
	var domain:=_domain(cue)
	_casts[domain]={"owner":owner,"tick":int(cue.get("tick",-1))}
	_cast_order.erase(domain);_cast_order.append(domain)
	if _cast_order.size()>LIMIT:_casts.erase(_cast_order.pop_front())

func clear()->void:
	_casts.clear();_cast_order.clear();_seen.clear();_order.clear()
