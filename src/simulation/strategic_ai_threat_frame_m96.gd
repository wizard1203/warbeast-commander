extends RefCounted
## One synchronous AI observation: exact, ordered alarm relationships, not a
## second damage ledger or a future combat model. Callers own the scope.
const NeutralThreat = preload("res://src/simulation/strategic_ai_neutral_threat_m73.gd")
const CELL := 128

static func prepare(world: Dictionary, military: Dictionary, tick: int) -> Dictionary:
	var victims: Array[Dictionary] = []
	var grid: Dictionary = {}
	var recent_by_source: Dictionary = {}
	var max_radius := 0
	var bodies: Array=military.get("soldiers",[]).duplicate()
	bodies.append_array(world.get("workers",[]));bodies.append_array(world.get("buildings",[]))
	for body: Dictionary in bodies:
		if body.get("side")!="AI":continue
		var living:bool=bool(body.get("alive",true)) and int(body.get("hp",1))>0
		if living and not bool(body.get("attackable",true)):continue
		var damage_tick:=int(body.get("last_damage_tick",-1))
		var recent:bool=damage_tick>=0 and damage_tick<=tick and tick-damage_tick<=60
		if not living and (not recent or int(body.get("last_damage_amount",0))<=0):continue
		var index:=victims.size()
		var point:=Vector2i(body.position)
		var radius:=int(body.get("radius",14))
		victims.append({"body":body,"position":point,"living":living,"layer":str(body.get("movement_layer","GROUND")),"radius":radius,"base":body.get("building_type","")=="BASE"})
		if living:
			var cell:=_cell(point)
			if not grid.has(cell):grid[cell]=[]
			grid[cell].append(index)
			max_radius=maxi(max_radius,radius)
		if recent:
			var source:=str(body.get("last_damage_source_id",""))
			if not recent_by_source.has(source):recent_by_source[source]=[]
			recent_by_source[source].append(index)
	var layers_by_army:Dictionary={}
	for body:Dictionary in military.get("soldiers",[]):
		if body.get("side")!="AI" or not bool(body.get("alive",true)) or int(body.get("hp",1))<=0:continue
		var army:Variant=body.get("warband_id")
		if not layers_by_army.has(army):layers_by_army[army]={}
		for layer:Variant in body.get("attack_layers",["GROUND"]):layers_by_army[army][layer]=true
	var hostiles:Array=military.get("soldiers",[]).duplicate()
	hostiles.append_array(world.get("buildings",[]));hostiles.append_array(world.get("workers",[]));hostiles.append_array(world.get("micro_neutral_targets",[]))
	var alarms:Array[Dictionary]=[]
	var pair_checks:=0
	for enemy:Dictionary in hostiles:
		if enemy.get("side") not in ["PLAYER","NEUTRAL"] or not bool(enemy.get("alive",true)) or int(enemy.get("hp",1))<=0 or not bool(enemy.get("visible",true)):continue
		var point:=Vector2i(enemy.position)
		var enemy_id:=str(enemy.get("id",""))
		var neutral:bool=enemy.get("side")=="NEUTRAL"
		var structure:bool=enemy.has("building_type")
		var weapon:bool=int(enemy.get("damage",1))>0 and (not structure or bool(enemy.get("complete",false)) and bool(enemy.get("defense_active",false)))
		var layers:Array=["GROUND","AIR"] if structure else enemy.get("attack_layers",["GROUND"])
		var reach:=int(enemy.get("attack_range",0))
		var adds_radius:bool=not structure and enemy.get("unit_type","")!="worker"
		var candidates:Dictionary={}
		for index:int in recent_by_source.get(enemy_id,[]):candidates[index]=true
		if weapon:
			var broad_reach:=maxi(0,reach+(max_radius if adds_radius else 0))
			var lo:=_cell(point-Vector2i(broad_reach,broad_reach))
			var hi:=_cell(point+Vector2i(broad_reach,broad_reach))
			# Abnormal giant ranges must not make a huge empty grid walk. This is
			# only a broadphase; the original exact pair predicate remains below.
			if (hi.x-lo.x+1)*(hi.y-lo.y+1)>maxi(16,grid.size()*2):
				for index:int in range(victims.size()):
					if bool(victims[index].living):candidates[index]=true
			else:
				for y:int in range(lo.y,hi.y+1):
					for x:int in range(lo.x,hi.x+1):
						for index:int in grid.get(Vector2i(x,y),[]):candidates[index]=true
		var ordered:Array=candidates.keys();ordered.sort()
		var matches:PackedInt32Array=[]
		for index:int in ordered:
			pair_checks+=1
			var victim:Dictionary=victims[index]
			var recently_hit:bool=recent_by_source.has(enemy_id) and index in recent_by_source[enemy_id]
			var covers:=false
			if bool(victim.living) and weapon and victim.layer in layers:
				var exact_reach:int=reach+(int(victim.radius) if adds_radius else 0)
				covers=exact_reach>0 and (point-Vector2i(victim.position)).length_squared()<=exact_reach*exact_reach
			if not recently_hit and not covers:continue
			if neutral and not NeutralThreat.alarm_can_engage(enemy,victim.body,tick):continue
			matches.append(index)
		if not matches.is_empty():alarms.append({"body":enemy,"position":point,"id":enemy_id,"layer":enemy.get("movement_layer","GROUND"),"victims":matches})
	return {"victims":victims,"alarms":alarms,"layers_by_army":layers_by_army,"work":{"pair_checks":pair_checks,"victims":victims.size(),"hostiles":hostiles.size(),"alarms":alarms.size()}}

static func select(frame:Dictionary,army:Dictionary,allow_base_recall:bool=true,enemy_id:String="") -> Dictionary:
	var layers:Dictionary=frame.layers_by_army.get(army.get("id"),{})
	if layers.is_empty():return {}
	var anchor:=Vector2i(army.anchor)
	var distance:=9223372036854775807
	var best:Dictionary={}
	for alarm:Dictionary in frame.alarms:
		if not enemy_id.is_empty() and alarm.id!=enemy_id:continue
		if not layers.has(alarm.layer):continue
		var next:int=(Vector2i(alarm.position)-anchor).length_squared()
		if next>=distance:continue
		for index:int in alarm.victims:
			var victim:Dictionary=frame.victims[index]
			if (not bool(victim.base) or not allow_base_recall) and (Vector2i(victim.position)-anchor).length_squared()>420*420:continue
			best=alarm.body.duplicate(true);best["defense_anchor"]=victim.body.position;best["threat_active"]=true
			distance=next
			break
	return best

static func _cell(point:Vector2i)->Vector2i:
	return Vector2i(floori(float(point.x)/CELL),floori(float(point.y)/CELL))
