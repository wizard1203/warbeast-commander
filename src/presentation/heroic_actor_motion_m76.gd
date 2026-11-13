extends RefCounted
## Render-only body timing. Original semantic phase stays untouched for VFX,
## input and combat; the body consumers explicitly opt into private fields.
const A=preload("res://src/presentation/heroic_faction_motion_a_m76.gd")
const B=preload("res://src/presentation/heroic_faction_motion_b_m76.gd")
const Pose=preload("res://src/presentation/strategic_action_pose.gd")
const OutpostsV4=preload("res://src/presentation/heroic_outposts_v4_units.gd")

static func for_body(unit:Dictionary,pose:Dictionary,tick:int,fraction:float)->Dictionary:
	if bool(unit.get("neutral",false)):return pose.duplicate(false)
	var action:=str(pose.get("action","IDLE"))
	var part:=clampf(fraction,0.0,1.0) if is_finite(fraction) else 1.0
	var projected:=pose.duplicate(false)
	var sample:=maxf(0.0,float(tick)-1.0+part)
	projected["sample_tick_m76"]=sample
	projected["body_animation_tick_m76"]=sample
	# Refine existing event frames within a fixed step without creating events.
	var duration:=int(Pose.ACTION_TICKS.get(action,14 if action.begins_with("SKILL_") else 16 if action in ["HARVEST","MINE","BUILD"] else 0))
	if duration>0:projected["phase"]=clampf(float(pose.get("phase",0))+(-1.0+part)/float(duration),0,.999999)
	if str(unit.get("unit_type","")) in OutpostsV4.IDS:
		projected["motion_identity_m76"]=str(unit.unit_type)
		if duration>0: projected["body_phase_m76"]=projected.phase
		if action=="IDLE": projected["body_idle_frame_m76"]=posmod(floori(sample/12.0)+absi(str(unit.get("id","")).hash())%4,4)
		if action=="FALLEN":
			var death_tick := int(unit.get("last_damage_tick",-1000000))
			if death_tick>=0 and sample>=death_tick: projected["body_death_phase_v3"]=clampf((sample-death_tick)/12.0,0,1)
		projected["phase"]=pose.get("phase",0.0)
		return projected
	var faction:=str(unit.get("faction_id",""))
	projected=A.decorate_pose(unit,projected) if faction in A.FACTIONS else B.decorate_pose(unit,projected)
	projected["phase"]=pose.get("phase",0.0)
	# These authored idle strips already exist. Playback adds no synthetic walk
	# or action and does not alter stable body bounds or the fallen frame.
	if action=="IDLE" and projected.has("motion_identity_m76"):
		projected["body_idle_frame_m76"]=posmod(floori(sample/12.0)+absi(str(unit.get("id","")).hash())%4,4)
	return projected
