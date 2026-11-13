extends RefCounted
## One bounded geometry/aim contract for Combat, player automation and AI.
## Pure detached inputs: no authority, searches, randomness or mutable cache.

static func aim_position(origin: Vector2i, skill: Dictionary, target: Vector2i, bounds: Rect2i) -> Vector2i:
	if str(skill.get("delivery","AREA"))!="LINE": return target
	var direction := target-origin
	var dominant := maxi(absi(direction.x),absi(direction.y))
	if dominant==0: return target
	var position := target
	var reach := int(skill.get("range",0))
	var low := dominant
	var high := reach
	while low<=high:
		var step := (low+high)/2
		var candidate := origin+Vector2i(direction.x*step/dominant,direction.y*step/dominant)
		if valid_point(candidate,bounds) and (candidate-origin).length_squared()<=reach*reach:
			position=candidate
			low=step+1
		else: high=step-1
	return position

static func valid_point(point: Vector2i, bounds: Rect2i) -> bool:
	return point.x>=bounds.position.x and point.y>=bounds.position.y and point.x<=bounds.end.x and point.y<=bounds.end.y

static func contains(origin: Vector2i, skill: Dictionary, point: Vector2i, target: Vector2i) -> bool:
	var delivery := str(skill.get("delivery","AREA"))
	if delivery=="LINE":
		var start := Vector2(origin)
		var segment := Vector2(point-origin)
		var projection := Vector2(target-origin).dot(segment)/maxf(1.0,segment.length_squared())
		return projection>=0.0 and projection<=1.0 and (Vector2(target)-(start+segment*projection)).length_squared()<=pow(float(skill.get("line_width",0))*0.5,2)
	if delivery=="CONE":
		var direction := point-origin
		var offset := target-origin
		var reach := int(skill.get("range",0))
		if direction==Vector2i.ZERO or offset.length_squared()>reach*reach: return false
		var forward := int(offset.x)*int(direction.x)+int(offset.y)*int(direction.y)
		if forward<=0: return false
		var cross := int(offset.x)*int(direction.y)-int(offset.y)*int(direction.x)
		var half_width := float(skill.get("cone_width",0))*0.5
		return float(cross)*float(cross)*float(reach*reach)<=float(forward)*float(forward)*half_width*half_width
	if delivery=="SINGLE" and (target-origin).length_squared()>int(skill.get("range",0))*int(skill.get("range",0)): return false
	return (target-point).length_squared()<=int(skill.get("radius",0))*int(skill.get("radius",0))

static func targets(caster: Dictionary, skill: Dictionary, point: Vector2i, pool: Array[Dictionary]) -> Array[Dictionary]:
	var candidates: Array[Dictionary]=[]
	var delivery := str(skill.get("delivery","AREA"))
	for target: Dictionary in pool:
		if target.side==caster.side or int(target.get("hp",0))<=0 or target.get("movement_layer","GROUND") not in skill.target_layers: continue
		if delivery!="CHAIN" and not contains(caster.position,skill,point,target.position): continue
		candidates.append(target)
	var result: Array[Dictionary]=[]
	var anchor: Vector2i=caster.position if delivery in ["LINE","CONE"] else point
	var limit := 1 if delivery=="SINGLE" else clampi(int(skill.get("max_targets",1)),1,6)
	# A fixed anchor and unique IDs define an exact integer-distance total
	# order: removing its first member cannot change the remaining order.
	# CHAIN moves the anchor; duplicate IDs can create unstable comparator
	# ties. Preserve the original repeated-sort path in either case.
	var fixed_order := delivery!="CHAIN" and limit>1
	if fixed_order:
		var ids := {}
		for target: Dictionary in candidates:
			var id := str(target.id)
			if ids.has(id):
				fixed_order=false
				break
			ids[id]=true
	while not candidates.is_empty() and result.size()<limit:
		if result.is_empty() or not fixed_order:
			candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
				var da: int=(Vector2i(a.position)-anchor).length_squared()
				var db: int=(Vector2i(b.position)-anchor).length_squared()
				return str(a.id)<str(b.id) if da==db else da<db)
		var selected: Dictionary=candidates.pop_front()
		if delivery=="CHAIN":
			var reach := int(skill.radius) if result.is_empty() else int(skill.chain_range)
			if (Vector2i(selected.position)-anchor).length_squared()>reach*reach: break
		result.append(selected)
		if delivery=="CHAIN": anchor=selected.position
	return result
