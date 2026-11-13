extends RefCounted
## Detached finite semantic mission. Callers stamp accepted_tick only after a
## real matching Host receipt; this module never claims acceptance or capture.
const Route=preload("res://src/simulation/strategic_ai_route_m73.gd")
const VERSION:="m73-semantic-waypoint-journey-v1"
const STALE_TICKS:=240
const PROGRESS_PIXELS:=12.0
const WAYPOINT_RADIUS:=10.0

static func advance(world:Dictionary,army:Dictionary,goal:Vector2i,tick:int,avoid_ids:Array,state:Dictionary)->Dictionary:
	var next:Dictionary=state.duplicate(true)
	var result:={"state":next,"command":{},"blocked":false,"reason":"PENDING","arrived":false}
	var fresh:bool=next.is_empty() or next.get("goal")!=goal
	if fresh:
		var proposal:Dictionary=Route.propose(world,army,goal,tick,avoid_ids)
		next={"version":VERSION,"goal":goal,"waypoints":proposal.waypoints.duplicate(),"index":0,"accepted_tick":-1,"first_accepted_tick":-1,"body_progress_tick":-1,"last_progress_tick":tick,"best_leg_distance":-1.0,"pending_point":proposal.next_point,"started_tick":tick,"phase":"PENDING","route_reason":proposal.reason,"envelope_radius":int(proposal.envelope_radius),"last_checked_tick":tick,"route_work":proposal.work.duplicate(true)}
		result.state=next
		if bool(proposal.blocked):return _block(result,"ROUTE_"+str(proposal.reason))
	elif next.get("phase")=="STALE":return _block(result,"STALE_NO_BODY_PROGRESS",false)
	elif next.get("phase")=="BLOCKED" or next.get("waypoints",[]).is_empty():
		# One fresh bounded full-goal query on the next decision after a changed
		# corridor was blocked. Never combine unlimited full replans in one call.
		var proposal:Dictionary=Route.propose(world,army,goal,tick,avoid_ids)
		if bool(proposal.blocked):return _block(result,"ROUTE_"+str(proposal.reason))
		next.waypoints=proposal.waypoints.duplicate();next.index=0;next.pending_point=proposal.next_point;next.accepted_tick=-1;next.best_leg_distance=-1.0;next.envelope_radius=int(proposal.envelope_radius);next.route_work=proposal.work.duplicate(true);next.route_reason=proposal.reason;next.phase="PENDING"
		next.last_checked_tick=tick
		fresh=true
	var path:Array=next.get("waypoints",[])
	var index:=clampi(int(next.get("index",0)),0,maxi(0,path.size()-1))
	if path.is_empty():return _block(result,"EMPTY_ROUTE")
	var point:=Vector2i(path[index])
	var distance:=_body_distance(world,army,point)
	if not is_finite(distance):return _block(result,"NO_AVAILABLE_MEMBERS")
	var accepted:bool=int(next.get("accepted_tick",-1))>=0
	if accepted:
		# Backward-compatible with the first integration callback, which stamps
		# accepted_tick only. This is derived solely from a supplied real receipt,
		# never from proposing an order or seeing the same destination on screen.
		if int(next.get("first_accepted_tick",-1))<0:next.first_accepted_tick=int(next.accepted_tick)
		if int(next.get("body_progress_tick",-1))<0:next.body_progress_tick=int(next.first_accepted_tick)
		next.last_progress_tick=int(next.body_progress_tick)
	# A proposal waiting for bandwidth is not an already-running expedition.
	# Once accepted, only actual body approach or actual arrival renews its lease.
	var best_distance:=float(next.get("best_leg_distance",-1.0))
	if not is_finite(best_distance) or best_distance<0.0:next.best_leg_distance=distance
	elif accepted and distance<best_distance-PROGRESS_PIXELS:
		next.best_leg_distance=distance;next.last_progress_tick=tick;next.body_progress_tick=tick
	if accepted and _reached(world,army,point,int(next.get("envelope_radius",48))):
		next.last_progress_tick=tick;next.body_progress_tick=tick
		if index==path.size()-1:
			next.phase="ARRIVED";next.last_checked_tick=tick;result.reason="ARRIVED_AT_APPROACH_NOT_CAPTURE";result.arrived=true
			return result
		index+=1;next.index=index;point=Vector2i(path[index]);next.pending_point=point;next.accepted_tick=-1;next.best_leg_distance=_body_distance(world,army,point);next.phase="PENDING";accepted=false
	if accepted and tick-int(next.get("last_progress_tick",tick))>=STALE_TICKS:
		next.phase="STALE"
		return _block(result,"STALE_NO_BODY_PROGRESS",false)
	if not fresh:
		# Recheck only this next leg with current visibility, actual bodies and
		# physical geometry. A new detour can splice in, at most Route's one
		# bounded query (two Navigation searches), rather than blindly keeping an
		# old waypoint or issuing a direct final command through changed danger.
		var validation:Dictionary=Route.propose(world,army,point,tick,avoid_ids)
		next.last_checked_tick=tick;next.route_work=validation.work.duplicate(true);next.route_reason=validation.reason
		if bool(validation.blocked):return _block(result,"LEG_"+str(validation.reason))
		if validation.waypoints.size()>1:
			var replacement:Array=validation.waypoints.duplicate()
			for remainder:int in range(index+1,path.size()):replacement.append(path[remainder])
			if replacement.size()>Route.MAX_WAYPOINTS:return _block(result,"WAYPOINT_BUDGET_EXCEEDED")
			next.waypoints=replacement;next.index=0;next.pending_point=Vector2i(replacement[0]);next.accepted_tick=-1;next.best_leg_distance=_body_distance(world,army,Vector2i(replacement[0]));next.phase="PENDING";point=next.pending_point;accepted=false
		next.envelope_radius=int(validation.envelope_radius)
	var command:={"type":"ATTACK_MOVE","subject_id":str(army.get("id","")),"target_position":point}
	# A temporary defense can replace the actual destination. Restore the same
	# checked leg without resetting its already-running acceptance/progress clock.
	if not accepted or army.get("intent")!="ATTACK_MOVE" or army.get("destination")!=point:result.command=command
	next.pending_point=point;next.phase="TRAVELLING" if accepted else "PENDING";result.reason="TRAVELLING" if accepted else "AWAITING_HOST_ACCEPTANCE"
	return result

static func _block(result:Dictionary,reason:String,mark_blocked:bool=true)->Dictionary:
	result.blocked=true;result.reason=reason;result.command={}
	if mark_blocked:result.state.phase="BLOCKED"
	return result

static func _members(world:Dictionary,army:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for body:Dictionary in world.get("soldiers",[]):
		if body.get("side")==army.get("side","AI") and body.get("warband_id")==army.get("id") and int(body.get("hp",0))>0 and body.get("direct_intent","")!="MOVE":result.append(body)
	return result

static func _body_distance(world:Dictionary,army:Dictionary,point:Vector2i)->float:
	var members:=_members(world,army)
	if members.is_empty():return INF
	var total:=0.0
	for member:Dictionary in members:total+=Vector2(member.position).distance_to(Vector2(point))
	return total/float(members.size())

static func _reached(world:Dictionary,army:Dictionary,point:Vector2i,envelope:int)->bool:
	if Vector2(army.get("anchor",point)).distance_to(Vector2(point))>WAYPOINT_RADIUS:return false
	var members:=_members(world,army)
	if members.is_empty():return false
	for member:Dictionary in members:
		if Vector2(member.position).distance_to(Vector2(point))>float(maxi(48,envelope+12)):return false
	return true
