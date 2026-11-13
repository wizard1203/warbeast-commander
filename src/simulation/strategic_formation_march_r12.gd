extends RefCounted
## Pure formation facts. No retained body references, movement, target search,
## command, stat write, random draw or authority clock lives in this helper.
## Combat owns eligibility for runtime controls that are not body fields.
const VERSION := "actual-range-march-r12-v1"
const SIDES := ["PLAYER","AI"]

static func _living(body:Dictionary)->bool:
	return int(body.get("hp",1))>0 and bool(body.get("alive",true))

static func pitch_for(members:Array[Dictionary],minimum:int=32)->int:
	var result:=maxi(1,minimum)
	for body:Dictionary in members:
		if _living(body):result=maxi(result,int(body.get("radius",0))*2+4)
	return result

static func layout_key(members:Array[Dictionary],formation:String,pitch:int)->String:
	var entries:Array[String]=[]
	for body:Dictionary in members:
		if _living(body):entries.append("%s:%d:%d"%[str(body.get("id","")),int(body.get("attack_range",0)),int(body.get("radius",0))])
	entries.sort()
	return formation+"/"+str(pitch)+"/"+";".join(entries)

## The forward axis is +X. Every distinct current final attack_range begins a
## new rank; equal ranges use deterministic ID order and centered lateral rows.
## No role/capability gate: heroes and caster/support-only groups participate.
static func layout(members:Array[Dictionary],formation:String="STEADY",pitch:int=32)->Dictionary:
	var ordered:Array[Dictionary]=[]
	for body:Dictionary in members:
		if _living(body):ordered.append(body)
	if ordered.is_empty():return {}
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ar:=int(a.get("attack_range",0));var br:=int(b.get("attack_range",0))
		return ar<br if ar!=br else str(a.get("id",""))<str(b.get("id","")))
	var gap:=pitch_for(ordered,pitch)
	if formation=="LOOSE":gap=maxi(48,gap)
	var width:=2 if formation=="COLUMN" else 3 if formation=="SPEAR" else maxi(3,ceili(sqrt(float(ordered.size())*1.5)))
	var offsets:Dictionary={};var depth:=0;var index:=0;var center:=Vector2.ZERO
	while index<ordered.size():
		var end:=index
		while end<ordered.size() and int(ordered[end].get("attack_range",0))==int(ordered[index].get("attack_range",0)):end+=1
		var cursor:=index
		while cursor<end:
			var count:=mini(width,end-cursor)
			for lateral:int in range(count):
				var point:=Vector2i(-depth*gap,roundi((float(lateral)-float(count-1)/2.0)*gap))
				offsets[str(ordered[cursor+lateral].get("id",""))]=point;center+=Vector2(point)
			depth+=1;cursor+=count
		index=end
	center/=float(ordered.size())
	var shift:=Vector2i(roundi(center.x),roundi(center.y))
	for id:String in offsets:offsets[id]=Vector2i(offsets[id])-shift
	return offsets

static func orient(offset:Vector2i,facing:String)->Vector2i:
	if facing=="WEST":return -offset
	if facing=="NORTH":return Vector2i(offset.y,-offset.x)
	if facing=="SOUTH":return Vector2i(-offset.y,offset.x)
	return offset

## Caller passes already legal installed bodies after hero gear/progression.
## The helper reserves actual circular extents on each side of the shared
## front gap, then fits the combined layout inside the actual map rectangle.
## It never shortens a roster, shrinks a body, admits a spawn or moves a body.
static func arena_placement(sides:Dictionary,bounds:Rect2i,midpoint:Vector2i=Vector2i(1350,1100),clearance:int=240)->Dictionary:
	var local:Dictionary={};var extents:Dictionary={};var seen:Dictionary={}
	for side:String in SIDES:
		var members:Array[Dictionary]=[]
		for value:Variant in sides.get(side,[]):
			if not value is Dictionary:return {"accepted":false,"error":"INVALID_MEMBER"}
			var body:Dictionary=value
			if not _living(body):continue
			var id:=str(body.get("id",""))
			if id.is_empty() or seen.has(id) or int(body.get("radius",-1))<0:return {"accepted":false,"error":"INVALID_MEMBER_ID_OR_RADIUS"}
			seen[id]=true;members.append(body)
		if members.is_empty():return {"accepted":false,"error":"EMPTY_SIDE"}
		var offsets:=layout(members,"STEADY",pitch_for(members))
		var left:=2147483647;var right:=-2147483648;var top:=2147483647;var bottom:=-2147483648
		var facing:="EAST" if side=="PLAYER" else "WEST"
		for body:Dictionary in members:
			var point:=orient(Vector2i(offsets[str(body.id)]),facing);var radius:=int(body.radius)
			offsets[str(body.id)]=point
			left=mini(left,point.x-radius);right=maxi(right,point.x+radius);top=mini(top,point.y-radius);bottom=maxi(bottom,point.y+radius)
		local[side]=offsets;extents[side]={"left":left,"right":right,"top":top,"bottom":bottom}
	var gap:=maxi(4,clearance);var half_gap:=gap/2
	var player:Dictionary=extents.PLAYER;var enemy:Dictionary=extents.AI
	var minimum_mid:=bounds.position.x+half_gap+int(player.right)-int(player.left)
	var maximum_mid:=bounds.end.x-(gap-half_gap)-int(enemy.right)+int(enemy.left)
	var minimum_y:=maxi(bounds.position.y-int(player.top),bounds.position.y-int(enemy.top))
	var maximum_y:=mini(bounds.end.y-int(player.bottom),bounds.end.y-int(enemy.bottom))
	if minimum_mid>maximum_mid or minimum_y>maximum_y:return {"accepted":false,"error":"FORMATION_DOES_NOT_FIT"}
	var split_x:=clampi(midpoint.x,minimum_mid,maximum_mid);var center_y:=clampi(midpoint.y,minimum_y,maximum_y)
	var anchors:={"PLAYER":Vector2i(split_x-half_gap-int(player.right),center_y),"AI":Vector2i(split_x+gap-half_gap-int(enemy.left),center_y)}
	var positions:Dictionary={}
	for side:String in SIDES:
		for id:String in local[side]:positions[id]=Vector2i(anchors[side])+Vector2i(local[side][id])
	return {"accepted":true,"error":"","positions":positions,"anchors":anchors,"facings":{"PLAYER":"EAST","AI":"WEST"},"offsets":local,"extents":extents,"front_clearance":gap}

## Supplying an exclusion means Combat already knows the body is controlled,
## independently withdrawing or otherwise ineligible in this actual batch.
## Disabled auto-attack alone does not cancel a hero's ordinary army travel.
static func is_follower(body:Dictionary,excluded:Dictionary={})->bool:
	return _living(body) and not bool(body.get("neutral",false)) and str(body.get("direct_intent","")).is_empty() and not excluded.has(str(body.get("id","")))

## Current effective speed includes legitimate gear/buffs/slows. The result is
## only a derived stride limit; this function never writes a natural speed or
## consumes either a body's or an army's fractional movement credit.
static func march_profile(members:Array[Dictionary],excluded:Dictionary={})->Dictionary:
	var pace:=INF;var ids:Array[String]=[]
	for body:Dictionary in members:
		if not is_follower(body,excluded):continue
		pace=minf(pace,maxf(0.0,float(body.get("speed_exact",body.get("speed",0)))))
		ids.append(str(body.get("id","")))
	ids.sort()
	return {"count":ids.size(),"ids":ids,"speed_exact":0.0 if ids.is_empty() else pace}

## Only already selected targets enter this decision. There is no hidden-enemy
## scan, new target acquisition, retained target lease or forecast here. Combat
## keeps explicit attacks' own natural speed regardless of formation pacing.
static func has_contact(members:Array[Dictionary],targets:Dictionary,heroes:Dictionary={},excluded:Dictionary={})->bool:
	for body:Dictionary in members:
		if not is_follower(body,excluded):continue
		var id:=str(body.get("id",""));var hero:Dictionary=heroes.get(id,{})
		if not hero.is_empty() and not bool(hero.get("auto_attack",true)):continue
		var target:Dictionary=targets.get(id,{})
		if target.is_empty() or int(target.get("hp",0))<=0 or target.get("side")==body.get("side"):continue
		if str(target.get("movement_layer","GROUND")) in body.get("attack_layers",["GROUND"]):return true
	return false
