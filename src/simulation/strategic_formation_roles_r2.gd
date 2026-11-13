extends RefCounted
## Original role-aware slots, computed only on composition/formation changes.
## No target orders, taunt, collision exemption or per-unit operating AI.

static func priority(body:Dictionary)->int:
	var flags:Array=body.get("role_capabilities",[])
	if "ANCHOR" in flags:return 0
	if "HEALER" in flags:return 3
	if "CASTER" in flags or int(body.get("attack_range",0))>=100:return 2
	return 1

static func layout(members:Array[Dictionary],formation:String,pitch:int)->Dictionary:
	var enabled:=false
	var ordered:Array[Dictionary]=members.duplicate()
	for body:Dictionary in ordered:
		if not body.get("role_capabilities",[]).is_empty():enabled=true;break
	if not enabled:return {}
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ar:=priority(a);var br:=priority(b)
		return ar<br if ar!=br else str(a.id)<str(b.id))
	var gap:=maxi(48,pitch) if formation=="LOOSE" else pitch
	var width:=2 if formation=="COLUMN" else 3 if formation=="SPEAR" else maxi(3,ceili(sqrt(float(members.size())*1.5)))
	var offsets:Dictionary={}
	var depth:=0
	var index:=0
	var center:=Vector2.ZERO
	while index<ordered.size():
		var rank:=priority(ordered[index])
		var end:=index
		while end<ordered.size() and priority(ordered[end])==rank:end+=1
		var cursor:=index
		while cursor<end:
			var count:=mini(width,end-cursor)
			for lateral:int in range(count):
				var point:=Vector2i(-depth*gap,roundi((float(lateral)-float(count-1)/2.0)*gap))
				offsets[str(ordered[cursor+lateral].id)]=point
				center+=Vector2(point)
			depth+=1;cursor+=count
		index=end
	center/=maxi(1,ordered.size())
	var shift:=Vector2i(roundi(center.x),roundi(center.y))
	for id:String in offsets:offsets[id]=Vector2i(offsets[id])-shift
	return offsets

static func orient(offset:Vector2i,facing:String)->Vector2i:
	if facing=="WEST":return -offset
	if facing=="NORTH":return Vector2i(offset.y,-offset.x)
	if facing=="SOUTH":return Vector2i(-offset.y,offset.x)
	return offset
