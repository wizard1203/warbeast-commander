extends RefCounted
## Explicit M101 experiment, NOT loaded by a shipping scene. These transforms
## remove repeated reads only inside their original synchronous method. There
## is no actor/tick cache and no simulation or texture-owner change.
const SOURCE := "res://src/presentation/heroic_2d_world_canvas.gd"
const SOURCE_SHA256 := "00831a9184bbc545686bbc0d355bef9059a9d25a83ea9c292b29f2d30445c7c2"

static func seams() -> Array[Dictionary]:
	return [
		{
			"id":"building_cull_bounds_once",
			"before":"\t\telif str(object.kind) == \"building\":\n\t\t\tif not Rect2(Vector2.ZERO, (get_parent() as Control).size).intersects(Rect2(point + building_visual_bounds(value, factor).position, building_visual_bounds(value, factor).size)): continue",
			"after":"\t\telif str(object.kind) == \"building\":\n\t\t\tvar cull_bounds_m101 := building_visual_bounds(value, factor)\n\t\t\tif not Rect2(Vector2.ZERO, (get_parent() as Control).size).intersects(Rect2(point + cull_bounds_m101.position, cull_bounds_m101.size)): continue"
		},
		{
			"id":"tower_projection_once_metadata_detached",
			"before":"\tset_meta(\"tower_readouts\",get_tower_readouts())\n\tfor readout: Dictionary in get_tower_readouts():",
			"after":"\tvar tower_readouts_m101 := get_tower_readouts()\n\t# The old metadata and draw arrays were separate allocations. Preserve\n\t# that nested ownership contract, not just their currently equal values.\n\tset_meta(\"tower_readouts\",tower_readouts_m101.duplicate(true))\n\tfor readout: Dictionary in tower_readouts_m101:"
		},
		{
			"id":"unit_visual_before_ellipse",
			"before":"\tvar alive:=int(unit.get(\"hp\",0))>0 and bool(unit.get(\"alive\",true))\n\tif alive:",
			"after":"\tvar alive:=int(unit.get(\"hp\",0))>0 and bool(unit.get(\"alive\",true))\n\tvar visual:=_unit_observation(unit)\n\tif alive:"
		},
		{
			"id":"hero_ellipse_reuses_local_visual",
			"before":"ActorReadout.draw_hero_ellipse(self,point,unit,Units.ground_footprint(_unit_observation(unit),radius),factor)",
			"after":"ActorReadout.draw_hero_ellipse(self,point,unit,Units.ground_footprint(visual,radius),factor)"
		},
		{
			"id":"remove_second_local_visual",
			"before":"\tvar visual:=_unit_observation(unit)\n\tvar empower:Array=[]",
			"after":"\tvar empower:Array=[]"
		}
	]

static func transform(source: String) -> Dictionary:
	var failures: Array[String] = []
	var counts: Dictionary = {}
	if source.sha256_text()!=SOURCE_SHA256:
		return {"accepted":false,"failures":["M101 actor source SHA mismatch"],"source":source,"transform_counts":counts}
	var transformed := source
	for seam: Dictionary in seams():
		var id := str(seam.id)
		var occurrences := transformed.count(str(seam.before))
		counts[id]=occurrences
		if occurrences!=1:
			failures.append("M101 actor seam must match once: "+id)
			continue
		transformed=transformed.replace(str(seam.before),str(seam.after))
	return {"accepted":failures.is_empty(),"failures":failures,"source":transformed,"transform_counts":counts}
