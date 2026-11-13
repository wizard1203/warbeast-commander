extends RefCounted
## Host-only immutable scalar projection for World, not a public unit snapshot.
## Canonical hero inventory/slots/life generations travel separately as roster.
const FIELDS := ["id","side","position","hp","alive","radius","unit_type","movement_layer","faction_id","hero_archetype","neutral","guarding_site_id","camp_id","camp_clear_winner","neutral_bounty_winner"]

static func project(units: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit: Dictionary in units:
		var body := {}
		for field: String in FIELDS:
			if unit.has(field): body[field] = unit[field]
		result.append(body)
	return result

## null requires the World caller's legacy per-site predicate. Preserve its
## unsupported-input behavior instead of coercing arbitrary guard IDs.
static func guards(bodies: Array) -> Variant:
	var counts := {}
	for body: Dictionary in bodies:
		if not bool(body.get("neutral",false)) or int(body.get("hp",0))<=0:continue
		var id: Variant=body.get("guarding_site_id","")
		if typeof(id) not in [TYPE_STRING,TYPE_STRING_NAME]:return null
		var key:=str(id)
		counts[key]=int(counts.get(key,0))+1
	return counts

static func capture(bodies: Array,sites: Array,sides: Array,radius: float) -> Dictionary:
	var positions:=PackedVector2Array()
	var owners:=PackedInt32Array()
	for body: Dictionary in bodies:
		var side:=sides.find(str(body.get("side","")))
		if side<0 or int(body.get("hp",0))<=0 or not bool(body.get("alive",true)) or body.get("unit_type","")=="worker" or body.get("movement_layer","GROUND")!="GROUND" or typeof(body.get("position"))!=TYPE_VECTOR2I:continue
		positions.append(Vector2(body.position))
		owners.append(side)
	var presences: Array[Dictionary]=[]
	for site: Dictionary in sites:
		var totals:=PackedInt32Array();totals.resize(sides.size())
		var point:=Vector2(site.position)
		for index: int in range(positions.size()):
			if positions[index].distance_to(point)<=radius:totals[owners[index]]+=1
		var presence: Dictionary={}
		for index: int in range(sides.size()):presence[sides[index]]=totals[index]
		presences.append(presence)
	return {"presence":presences,"guards":guards(bodies)}
