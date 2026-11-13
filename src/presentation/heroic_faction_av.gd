extends RefCounted
## Bounded observation-only dispatch. Catalogs and settlement remain read-only.
const Brush=preload("res://src/presentation/m63_av_brush.gd")
const Heroes=preload("res://src/simulation/strategic_hero_catalog.gd")
const Units=preload("res://src/simulation/strategic_unit_catalog.gd")
const ExpansionAV=preload("res://src/presentation/heroic_expansion_av_m66.gd")
const IdentityM67AV=preload("res://src/presentation/heroic_identity_av_m67.gd")
const MageAV=preload("res://src/presentation/heroic_mage_effects_m68.gd")
const RangedAV=preload("res://src/presentation/heroic_ranged_roles_m68.gd")
const VERSION:="m63-six-faction-av-v1"
const MODULES:={
	"HUMAN":preload("res://src/presentation/factions/m63_human_av.gd"),
	"MACHINE":preload("res://src/presentation/factions/m63_machine_av.gd"),
	"UNDEAD":preload("res://src/presentation/factions/m63_undead_av.gd"),
	"UNDERGROUND":preload("res://src/presentation/factions/m63_underground_av.gd"),
	"FOREST":preload("res://src/presentation/factions/m63_forest_av.gd"),
	"HIGHLAND":preload("res://src/presentation/factions/m63_highland_av.gd")}

static func identity_for(unit:Dictionary)->String:
	var type:=str(unit.get("unit_type",""))
	if type=="hero":return "hero:"+str(unit.get("hero_archetype",""))
	if type=="worker":return "worker:"+str(unit.get("faction_id",""))
	return str(unit.get("neutral_origin_unit_type",unit.get("origin_unit_type",type))) if bool(unit.get("neutral",false)) else type

static func faction_for(unit:Dictionary)->String:
	if str(unit.get("unit_type",""))=="hero":return str(Heroes.PROFILES.get(unit.get("hero_archetype",""),{}).get("faction_id","HUMAN"))
	var faction:=str(unit.get("faction_id",""))
	return faction if MODULES.has(faction) else str(Units.UNITS.get(unit.get("unit_type",""),{}).get("faction_id","HUMAN"))

static func actor_profile(unit:Dictionary)->Dictionary:
	var ranged:=RangedAV.actor_profile(unit)
	if not ranged.is_empty():return ranged
	var mage:=MageAV.actor_profile(unit)
	if not mage.is_empty():return mage
	var added:=ExpansionAV.actor_profile(unit)
	if not added.is_empty():return added
	var module:Variant=MODULES.get(faction_for(unit))
	return module.actor_profile(identity_for(unit)) if module!=null else {}

static func skill_profile(id:String)->Dictionary:
	var ranged:=RangedAV.skill_profile(id)
	if not ranged.is_empty():return ranged
	var mage:=MageAV.skill_profile(id)
	if not mage.is_empty():return mage
	var revised:=IdentityM67AV.skill_profile(id)
	if not revised.is_empty():return revised
	var added:=ExpansionAV.skill_profile(id)
	if not added.is_empty():return added
	for module:Variant in MODULES.values():
		var spec:Dictionary=module.skill_profile(id)
		if not spec.is_empty():return spec
	return {}

static func sound_profile(cue:Dictionary)->Dictionary:
	var spec:=skill_profile(str(cue.get("skill_id",""))) if str(cue.get("kind",""))=="SKILL" else actor_profile(cue)
	return spec.get("sound",{}).duplicate(true)

static func draw_skill(ctx:Dictionary,origin:Vector2,center:Vector2,scale:float,entry:Dictionary)->bool:
	if not RangedAV.skill_profile(str(entry.get("id",""))).is_empty():return RangedAV.draw_skill(ctx,origin,center,scale,entry)
	if not MageAV.Data.owner(str(entry.get("id",""))).is_empty():return MageAV.draw_skill(ctx,origin,center,scale,entry)
	if IdentityM67AV.ROWS.has(str(entry.get("id",""))):return IdentityM67AV.draw_skill(ctx,origin,center,scale,entry)
	var spec:=skill_profile(str(entry.get("id","")))
	if spec.is_empty():return false
	var module:Variant=MODULES.get(str(spec.get("faction_id","")))
	if module==null:return false
	for key:String in ["target_shape","ultimate","rank","effect","delivery"]:spec[key]=entry.get(key)
	spec["is_skill"]=true
	var limit:=int(ctx.draw_limit)
	ctx.draw_limit=mini(limit,int(ctx.count)+36)
	module.draw_signature(ctx,origin,center,scale,spec)
	ctx.draw_limit=limit
	return true

static func append_attack(commands:Array,origin:Vector2,center:Vector2,unit:Dictionary,pose:Dictionary,scale:float,limit:int)->void:
	if MageAV.append_attack(commands,origin,center,unit,pose,scale,limit):return
	var spec:=actor_profile(unit)
	if spec.is_empty():return
	spec["is_skill"]=false
	spec["target_shape"]="single";spec["ultimate"]=false;spec["rank"]=1
	var ctx:={"commands":commands,"count":commands.size(),"draw_limit":mini(limit,commands.size()+24),"phase":float(pose.get("phase",0)),"quantum":maxf(1,roundf(scale))}
	MODULES[str(spec.faction_id)].draw_signature(ctx,origin,center,scale,spec)

const MAX_DRAW_IDENTITY_PROFILES_M80 := 256
static var _draw_identity_profiles_m80: Dictionary = {}


static func reset_draw_identity_cache_m80() -> void:
	_draw_identity_profiles_m80.clear()


static func draw_identity_cache_stats_m80() -> Dictionary:
	return {"entries":_draw_identity_profiles_m80.size(),"maximum":MAX_DRAW_IDENTITY_PROFILES_M80}


static func _draw_identity_profile_m80(unit: Dictionary) -> Dictionary:
	# All actor_profile selectors were audited: unit_type (Ranged), archetype
	# (Ranged/Mage/Expansion), faction_for, identity_for (six static modules).
	# The delimiter guard preserves unusual imported strings without collisions.
	var selectors: Array[String] = [str(unit.get("unit_type","")),str(unit.get("hero_archetype","")),faction_for(unit),identity_for(unit)]
	for selector: String in selectors:
		if selector.contains("\u001f"): return actor_profile(unit)
	var key := "\u001f".join(selectors)
	if _draw_identity_profiles_m80.has(key): return _draw_identity_profiles_m80[key]
	var original := actor_profile(unit)
	# Empty/no-crest author profiles retain the original path, not a negative
	# cache. Unknown input can never grow this cache. Only render fields survive.
	if original.is_empty() or not original.get("crest",[]) is Array or not original.get("palette",[]) is Array: return original
	var crest: Array = original.get("crest",[])
	var palette: Array = original.get("palette",[])
	if crest.size()<3 or palette.size()<5 or not original.get("crest_offset",Vector2(-4,-17)) is Vector2: return original
	for vertex: Variant in crest:
		if not vertex is Vector2 or not Vector2(vertex).is_finite(): return original
	if _draw_identity_profiles_m80.size()>=MAX_DRAW_IDENTITY_PROFILES_M80: return original
	var projected := {"crest":crest.duplicate(true),"palette":palette.duplicate(true),"crest_offset":original.get("crest_offset",Vector2(-4,-17))}
	_draw_identity_profiles_m80[key] = projected
	return projected


static func draw_identity(canvas:Object,foot:Vector2,unit:Dictionary,radius:float,pose:Dictionary,bounds:Rect2=Rect2())->void:
	if pose.get("action")=="FALLEN" or int(unit.get("hp",1))<=0 or not bool(unit.get("alive",true)):return
	var spec:=_draw_identity_profile_m80(unit)
	if spec.is_empty():return
	var shape:Array=spec.get("crest",[])
	if shape.size()<3:return
	var scale:=clampf(radius/12.0,0.3,2.8)
	var offset:Vector2=spec.get("crest_offset",Vector2(-4,-17))
	var mirrored:=Vector2(pose.get("direction",Vector2.RIGHT)).x<0
	if mirrored:
		offset.x=-offset.x
		shape=shape.duplicate()
		for i:int in range(shape.size()):shape[i]=Vector2(-shape[i].x,shape[i].y)
	if bounds.size!=Vector2.ZERO:
		# Identity additions fit the existing stable body, never grow selection,
		# health bars or culling envelopes when a particular attack frame expands.
		var safe:=bounds.grow(-maxf(1,scale))
		var extent:=Vector2(7,7)*scale
		scale=minf(scale,minf(safe.size.x/16.0,safe.size.y/16.0))
		extent=Vector2(7,7)*scale
		offset=Vector2(clampf(offset.x*scale,safe.position.x+extent.x,safe.end.x-extent.x),clampf(offset.y*scale,safe.position.y+extent.y,safe.end.y-extent.y))/maxf(scale,0.001)
	var ctx:={"canvas":canvas,"count":0,"draw_limit":3,"quantum":maxf(1,roundf(scale))}
	Brush.stamp(ctx,foot+offset*scale,shape,scale,spec.get("palette",[]))
