extends RefCounted
## Read-only M65 tower feedback. Secondary marks exist only for recorded hits,
## not for units merely standing inside a decorative splash circle.
const Arrows = preload("res://src/presentation/heroic_combat_effects.gd")
const MAX_TARGETS := 3
const MAX_AGE := 8

static func inspect(readout: Dictionary) -> Dictionary:
	var age:=int(readout.get("age",-1))
	if not bool(readout.get("firing",false)) or age<0 or age>=MAX_AGE or not bool(readout.get("defense_active",true)):return {"supported":false}
	var targets: Array=[]
	var ids: Dictionary={}
	for hit: Variant in readout.get("targets",[]):
		if not hit is Dictionary:continue
		var id:=str(hit.get("id",""))
		var point: Variant=hit.get("position")
		if id.is_empty() or ids.has(id) or not point is Vector2 or not point.is_finite():continue
		ids[id]=true
		targets.append({"id":id,"position":point,"primary":bool(hit.get("primary",false))})
		if targets.size()>=MAX_TARGETS:break
	if targets.is_empty():return {"supported":false}
	var attack:=str(readout.get("attack_type","PIERCE"))
	var kind:=str({"PIERCE":"THORN_BOLT" if readout.get("faction_id")=="FOREST" else "BRIDGE_BOLT","ARCANE":"SOUL_LANTERN","GUNPOWDER":"RIVET_SHELL","IMPACT":"BASALT_CHUNK","EDGE":"CHITIN_BLADE"}.get(attack,"BRIDGE_BOLT"))
	return {"supported":true,"kind":kind,"attack_type":attack,"phase":float(age)/float(MAX_AGE),"targets":targets,"max_targets":MAX_TARGETS,"source_tick":int(readout.get("source_tick",0)),"settled_only":true}

static func draw(canvas: Object, origin: Vector2, readout: Dictionary, factor: float) -> bool:
	if not origin.is_finite() or not is_finite(factor) or factor<=0:return false
	var entry:=inspect(readout)
	if not entry.get("supported",false):return false
	var phase:=float(entry.phase)
	var primary: Vector2=entry.targets[0].position
	var progress:=minf(1,phase/0.62)
	var point:=origin.lerp(primary,progress)
	var direction:=(primary-origin).normalized()
	var scale:=maxf(0.5,factor)
	if phase<0.62:
		match str(entry.kind):
			"BRIDGE_BOLT","THORN_BOLT":
				Arrows.draw_projectile(canvas,origin,primary,minf(0.999,progress),scale,str(entry.kind)=="THORN_BOLT")
				if entry.kind=="THORN_BOLT":
					for at: Vector2 in [Vector2(-9,-3),Vector2(-6,3)]:_cell(canvas,point+at*scale,Vector2(4,2),scale,Color("86a959"))
			"SOUL_LANTERN":
				for index: int in range(4):
					var tail:=point-direction*(index*5.0)*scale
					_cell(canvas,tail,Vector2(5-index,3),scale,Color("5b6570") if index>1 else Color("9bccb5"))
				_cell(canvas,point+Vector2(-3,-4)*scale,Vector2(6,6),scale,Color("202331"))
				_cell(canvas,point+Vector2(-2,-5)*scale,Vector2(4,5),scale,Color("d3ecd1"))
				_cell(canvas,point+Vector2(0,-3)*scale,Vector2(1,2),scale,Color("53676b"))
			"RIVET_SHELL":
				for index: int in range(4):_cell(canvas,point-direction*(index*4.0)*scale,Vector2(3,2),scale,Color("efb35d") if index<2 else Color("675b51"))
				_chunk(canvas,point,scale,Color("24282c"),Color("a4a4a0"))
			"BASALT_CHUNK":
				var lob:=point+Vector2(0,-sin(progress*PI)*32)*scale
				_chunk(canvas,lob,scale*1.4,Color("343944"),Color("aabac4"))
			"CHITIN_BLADE":
				var angle:=phase*TAU*2
				for index: int in range(6):
					var edge:=Vector2.from_angle(angle+index*TAU/6)*5*scale
					_cell(canvas,point+edge,Vector2(3,2),scale,Color("252936"))
					_cell(canvas,point+edge+Vector2(-1,-1)*scale,Vector2(2,1),scale,Color("d5c7a4"))
				_cell(canvas,point-Vector2.ONE*2*scale,Vector2(4,4),scale,Color("8da892"))
	if phase>=0.5:
		for hit: Dictionary in entry.targets:
			var at: Vector2=hit.position
			var accent:=Color("b5d6a9") if entry.kind in ["THORN_BOLT","SOUL_LANTERN"] else Color("eab66b") if entry.kind=="RIVET_SHELL" else Color("b7c3c5") if entry.kind=="BASALT_CHUNK" else Color("dfc8a1")
			var size:=1.0 if bool(hit.primary) else 0.7
			for index: int in range(6):
				var ray:=Vector2.from_angle(index*TAU/6+0.3)
				var radius:=(4+(phase-0.5)*24)*size*scale
				_cell(canvas,at+ray*radius,Vector2(3,2),scale,accent if index%2==0 else Color("37383d"))
	return true

static func _chunk(canvas: Object, point: Vector2, scale: float, dark: Color, light: Color) -> void:
	_cell(canvas,point+Vector2(-4,-3)*scale,Vector2(7,6),scale,dark)
	_cell(canvas,point+Vector2(-2,-4)*scale,Vector2(4,2),scale,dark)
	_cell(canvas,point+Vector2(-3,-2)*scale,Vector2(4,2),scale,light)

static func _cell(canvas: Object, point: Vector2, extent: Vector2, scale: float, color: Color) -> void:
	canvas.draw_rect(Rect2(point.round(),(extent*scale).round().max(Vector2.ONE)),color)
