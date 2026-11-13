extends RefCounted
## Fixed physical body volume, separate from the authored display radius.
## This is a deterministic stat projection, not a pose/weapon envelope and not
## an additional ledger. Existing circle/swept collision remains authoritative.
const VERSION := "body-footprint-r11-v1"

static func visual_radius(source:Dictionary)->int:
	return maxi(0,int(source.get("visual_radius",source.get("radius",12))))

static func physical_radius(source:Dictionary)->int:
	var original:=visual_radius(source)
	var kind:=str(source.get("unit_type",source.get("id","")))
	# Workers belong to the legacy worker authority, and neutral camps author
	# their own placement/radius. Do not accidentally inherit a template radius
	# expansion for them or inflate buildings passed by a generic caller.
	if bool(source.get("neutral",false)) or kind=="worker":return original
	if source.has("building_type") and (source.has("complete") or str(source.building_type)==kind):return original
	if kind=="hero" or "HERO" in source.get("tags",[]):return maxi(30,original+14)
	if original<=0:return original
	# R11 expands true personal space again: common infantry now require44
	# center separation; the largest authored28 body becomes39. Route/layout
	# consumers must reserve this same volume, without enlarging the artwork.
	return original+(11 if original>=20 else 10)

static func apply_owned(source:Dictionary)->Dictionary:
	# Caller must own this dictionary. Combat.stats_for_type already receives a
	# detached Units.stats_for result, so it need not deep-copy a second time.
	if source.is_empty():return source
	var display:=visual_radius(source)
	var physical:=physical_radius(source)
	source["visual_radius"]=display
	source["radius"]=physical
	source["body_footprint_version_r10"]=VERSION
	return source

static func project(source:Dictionary)->Dictionary:
	return apply_owned(source.duplicate(true))
