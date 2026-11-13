extends RefCounted
## Identity-specific echoes of an already published ordinary-unit HEAL action.
## Targets are supplied by authority/playback; never discover allies by distance,
## invent secondary recipients, spend MP or publish a persistent beneficial buff.
const MAX_ACTIONS := 64
const INK := Color("1b2127")
const SIGNATURES := {
	"grove_mender":"OATH_PAGE_STITCH","ember_mender":"BONE_CANDLE_NEEDLES","repair_drone":"REPAIR_BOLT_COILS",
	"root_mender":"BUD_SPRING","rune_keeper":"HEARTH_WARM_CURRENT","spore_mender":"MYCELIAL_SPORES","elder_treant":"ELDER_CANOPY",
}
const LABELS := {"OATH_PAGE_STITCH":"誓光折页缝合","BONE_CANDLE_NEEDLES":"骨灯余烬针","REPAIR_BOLT_COILS":"螺栓线圈修理","BUD_SPRING":"芽花泉","HEARTH_WARM_CURRENT":"炉火暖流","MYCELIAL_SPORES":"菌丝孢子","ELDER_CANOPY":"古根冠叶庇护"}
const PALETTES := {
	"OATH_PAGE_STITCH":["8c7855","d7c18b","fff0c6"],"BONE_CANDLE_NEEDLES":["70596e","caa6a4","efe0bf"],
	"REPAIR_BOLT_COILS":["4a6672","8cbac1","d9e0ad"],"BUD_SPRING":["48744e","a3c881","e7e7b2"],
	"HEARTH_WARM_CURRENT":["885449","dd9b5d","ffe6a1"],"MYCELIAL_SPORES":["745a81","bca1c0","e5d5a2"],
	"ELDER_CANOPY":["4d6748","b0c878","f0e8b0"],
}

static func inspect(unit: Dictionary, pose: Dictionary) -> Dictionary:
	var phase := float(pose.get("phase",0))
	var type := str(unit.get("unit_type",""))
	if str(pose.get("action",""))!="HEAL" or type not in SIGNATURES or float(unit.get("heal",0))<=0 or int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not is_finite(phase) or phase<0 or phase>=1: return {"supported":false}
	# Optional published allegiance is checked when available. A bare position
	# cannot prove allegiance; normal live HEAL already comes from legal combat.
	var target_side := str(pose.get("target_side",unit.get("last_action_target_side","")))
	if not target_side.is_empty() and target_side!=str(unit.get("side","")): return {"supported":false}
	var signature: String = SIGNATURES[type]
	return {"supported":true,"action":"HEAL","signature":signature,"profile":"support_"+signature.to_lower(),"label":str(LABELS[signature]),"phase":phase,"visual_extent":Vector2(60,76) if type!="elder_treant" else Vector2(82,98),"max_draw_operations":MAX_ACTIONS,"max_actions":MAX_ACTIONS,"max_impacts":1,"particle_cap":12,"layers":["identity_source","explicit_heal_delivery","identity_recovery"],"palette":PALETTES[signature].duplicate(),"settled_only":true,"target_origin":"EXPLICIT_PUBLISHED_POINT","target_allegiance":"VERIFIED_PUBLISHED_SIDE" if not target_side.is_empty() else "CALLER_AUTHORITY","persistent_buff":false}

static func _poly(out: Array, cells: Array, point: Vector2, factor: float, color: Color, angle: float=0) -> void:
	if out.size()>=MAX_ACTIONS: return
	var vertices := PackedVector2Array()
	var quantum := maxf(1,roundf(factor))
	for cell: Vector2 in cells:
		var p := ((point+cell.rotated(angle)*factor)/quantum).round()*quantum
		if vertices.is_empty() or vertices[-1]!=p: vertices.append(p)
	if vertices.size()>1 and vertices[0]==vertices[-1]: vertices.remove_at(vertices.size()-1)
	if vertices.size()<3: return
	var area := 0.0
	for i: int in range(vertices.size()): area+=vertices[i].cross(vertices[(i+1)%vertices.size()])
	if absf(area)<0.5: return
	if Geometry2D.triangulate_polygon(vertices).is_empty():
		vertices=Geometry2D.convex_hull(vertices)
		if vertices.size()>1 and vertices[0]==vertices[-1]: vertices.remove_at(vertices.size()-1)
		if vertices.size()<3: return
	out.append({"points":vertices,"color":color})

static func _stamp(out: Array, cells: Array, point: Vector2, factor: float, color: Color, angle: float=0) -> void:
	_poly(out,cells,point,factor,INK,angle)
	_poly(out,cells,point,factor*0.73,color,angle)

static func _chip(out: Array, point: Vector2, radius: Vector2, factor: float, color: Color) -> void:
	_poly(out,[Vector2(-radius.x,-radius.y),Vector2(radius.x,-radius.y),Vector2(radius.x,radius.y),Vector2(-radius.x,radius.y)],point,factor,color)

static func _leaf(out: Array, point: Vector2, factor: float, color: Color, angle: float) -> void:
	_stamp(out,[Vector2(-8,0),Vector2(-3,-5),Vector2(3,-5),Vector2(9,0),Vector2(3,5),Vector2(-3,5)],point,factor,color,angle)
	_poly(out,[Vector2(-4,-1),Vector2(5,-1),Vector2(5,1),Vector2(-4,1)],point,factor,INK,angle)

static func _page(out: Array, point: Vector2, factor: float, main: Color, light: Color, angle: float) -> void:
	_stamp(out,[Vector2(-10,-12),Vector2(6,-12),Vector2(11,-7),Vector2(11,12),Vector2(-10,12)],point,factor,main,angle)
	_poly(out,[Vector2(4,-10),Vector2(9,-5),Vector2(4,-5)],point,factor,light,angle)
	for y: int in [-3,2,7]: _poly(out,[Vector2(-6,y),Vector2(4,y),Vector2(4,y+1),Vector2(-6,y+1)],point,factor,light,angle)

static func _nut(out: Array, point: Vector2, factor: float, main: Color) -> void:
	_stamp(out,[Vector2(-8,-4),Vector2(-4,-8),Vector2(4,-8),Vector2(8,-4),Vector2(8,4),Vector2(4,8),Vector2(-4,8),Vector2(-8,4)],point,factor,main)
	_chip(out,point,Vector2(2.5,2.5),factor,INK)

static func _cap(out: Array, point: Vector2, factor: float, main: Color, light: Color) -> void:
	_stamp(out,[Vector2(-11,1),Vector2(-9,-5),Vector2(-3,-10),Vector2(4,-10),Vector2(10,-4),Vector2(12,1)],point,factor,main)
	_poly(out,[Vector2(-2,1),Vector2(3,1),Vector2(3,11),Vector2(-3,11)],point,factor,light)
	_chip(out,point+Vector2(-4,-3)*factor,Vector2(1.5,1.5),factor,light)
	_chip(out,point+Vector2(5,-4)*factor,Vector2(1.5,1.5),factor,light)

static func _source(out: Array, origin: Vector2, signature: String, phase: float, factor: float, main: Color, light: Color) -> void:
	if phase>=0.48: return
	match signature:
		"OATH_PAGE_STITCH": _page(out,origin+Vector2(3,-10)*factor,factor*0.7,main,light,-0.15)
		"BONE_CANDLE_NEEDLES":
			_stamp(out,[Vector2(-7,8),Vector2(-7,-2),Vector2(-3,-2),Vector2(-3,-13),Vector2(1,-8),Vector2(4,-14),Vector2(7,-4),Vector2(4,2),Vector2(7,8)],origin+Vector2(4,-8)*factor,factor,main)
			_chip(out,origin+Vector2(4,-4)*factor,Vector2(1,5),factor,light)
		"REPAIR_BOLT_COILS":
			_nut(out,origin+Vector2(2,-8)*factor,factor*0.8,main)
			_poly(out,[Vector2(-3,-7),Vector2(0,-11),Vector2(3,-7),Vector2(1,-2),Vector2(5,7),Vector2(2,9),Vector2(-3,-1)],origin+Vector2(9,-7)*factor,factor,light)
		"BUD_SPRING":
			for i: int in range(2): _leaf(out,origin+Vector2(i*11-4,-6)*factor,factor*0.7,main,-0.7+i*1.4)
		"HEARTH_WARM_CURRENT":
			_stamp(out,[Vector2(-12,7),Vector2(-8,-2),Vector2(-5,-1),Vector2(0,-14),Vector2(5,-4),Vector2(9,-7),Vector2(13,7)],origin+Vector2(0,-4)*factor,factor,main)
			_poly(out,[Vector2(-5,5),Vector2(1,-6),Vector2(6,5)],origin+Vector2(0,-4)*factor,factor,light)
		"MYCELIAL_SPORES": _cap(out,origin+Vector2(0,-8)*factor,factor*0.8,main,light)
		"ELDER_CANOPY":
			for i: int in range(3): _leaf(out,origin+Vector2((i-1)*12,-6-abs(i-1)*6)*factor,factor,main,(i-1)*0.6)

static func _delivery(out: Array, origin: Vector2, target: Vector2, signature: String, phase: float, factor: float, main: Color, light: Color) -> void:
	if phase<0.12 or phase>=0.72: return
	var progress := clampf((phase-0.12)/0.6,0,1)
	var angle := (target-origin).angle()
	var moving := origin.lerp(target,progress)
	match signature:
		"OATH_PAGE_STITCH":
			_page(out,moving,factor*0.55,main,light,angle*0.25)
			for i: int in range(3): _chip(out,origin.lerp(moving,0.55+i*0.12),Vector2(2,1),factor,Color(light,0.6-i*0.1))
		"BONE_CANDLE_NEEDLES":
			for i: int in range(3):
				var p := moving+Vector2(-i*11,(i%2*2-1)*4).rotated(angle)*factor
				_stamp(out,[Vector2(-9,-2),Vector2(4,-2),Vector2(10,0),Vector2(4,2),Vector2(-9,2)],p,factor*(0.8-i*0.12),light,angle)
		"REPAIR_BOLT_COILS":
			_nut(out,moving,factor*0.8,main)
			for i: int in range(3):
				var p := origin.lerp(moving,0.4+i*0.15)
				_poly(out,[Vector2(-4,-4),Vector2(4,-4),Vector2(4,4),Vector2(1,4),Vector2(1,-1),Vector2(-4,-1)],p,factor,Color(light,0.72-i*0.14),angle)
		"BUD_SPRING":
			moving.y-=sin(progress*PI)*19*factor
			for i: int in range(2): _leaf(out,moving+Vector2(i*10-6,-i*7)*factor,factor*0.7,main,angle+(i-0.5)*0.9)
			_stamp(out,[Vector2(-2,4),Vector2(-3,0),Vector2(0,-6),Vector2(3,0),Vector2(2,4)],moving+Vector2(-10,8)*factor,factor*0.7,light)
		"HEARTH_WARM_CURRENT":
			for i: int in range(3):
				var p := origin.lerp(moving,0.45+i*0.24)
				_poly(out,[Vector2(-7,5),Vector2(-10,0),Vector2(-7,-6),Vector2(-2,-6),Vector2(-5,0),Vector2(2,6),Vector2(5,0),Vector2(9,-1),Vector2(6,9),Vector2(0,11)],p,factor,Color(main,0.75-i*0.12),angle*0.2)
		"MYCELIAL_SPORES":
			for i: int in range(4):
				var p := origin.lerp(moving,0.65+i*0.12)+Vector2(0,sin(i*1.7+phase*9)*8)*factor
				_stamp(out,[Vector2(-3,-2),Vector2(-1,-4),Vector2(2,-4),Vector2(4,-1),Vector2(3,2),Vector2(0,4),Vector2(-3,2)],p,factor,light)
		"ELDER_CANOPY":
			for i: int in range(3):
				var p := moving+Vector2(-i*12,(i%2*2-1)*6).rotated(angle)*factor
				_leaf(out,p,factor*(0.9-i*0.15),main,angle-0.5+i*0.4)

static func _recovery(out: Array, point: Vector2, signature: String, phase: float, factor: float, main: Color, light: Color) -> void:
	if phase<0.42 or phase>=0.98: return
	var age := (phase-0.42)/0.56
	var drift := Vector2(0,-age*12)*factor
	var faded := Color(main,0.92-age*0.5)
	match signature:
		"OATH_PAGE_STITCH":
			for signum: int in [-1,1]: _page(out,point+Vector2(signum*13,-23)*factor+drift,factor*0.55,faded,light,signum*0.3)
			for i: int in range(4):
				var p := point+Vector2(-9+i*6,-16+i%2*4)*factor+drift
				_poly(out,[Vector2(-2,-3),Vector2(1,-3),Vector2(3,3),Vector2(0,3)],p,factor,Color(light,0.85-age*0.5))
		"BONE_CANDLE_NEEDLES":
			for signum: int in [-1,1]:
				_stamp(out,[Vector2(-3,-13),Vector2(3,-13),Vector2(3,-7),Vector2(0,-3),Vector2(3,3),Vector2(3,12),Vector2(-3,12),Vector2(-3,5),Vector2(-6,0),Vector2(-3,-6)],point+Vector2(signum*15,-20)*factor+drift,factor*0.8,faded,signum*0.2)
			for i: int in range(3): _chip(out,point+Vector2(-6+i*6,-16-i%2*6)*factor+drift,Vector2(1,3),factor,light)
		"REPAIR_BOLT_COILS":
			for i: int in range(2): _nut(out,point+Vector2(i*26-13,-22)*factor+drift,factor*0.7,faded)
			_poly(out,[Vector2(-9,-26),Vector2(-9,-30),Vector2(5,-30),Vector2(5,-26),Vector2(-4,-26),Vector2(-4,-21),Vector2(9,-21),Vector2(9,-17),Vector2(-8,-17),Vector2(-8,-21),Vector2(1,-21),Vector2(1,-26)],point+drift,factor,Color(light,0.75-age*0.4))
		"BUD_SPRING":
			_poly(out,[Vector2(-2,0),Vector2(-2,-17),Vector2(2,-17),Vector2(2,0)],point,factor,faded)
			for i: int in range(3): _leaf(out,point+Vector2((i-1)*11,-19-abs(i-1)*3)*factor,factor*0.75,faded,(i-1)*0.8)
			for signum: int in [-1,1]: _stamp(out,[Vector2(-2,3),Vector2(-3,-1),Vector2(0,-7),Vector2(3,-1),Vector2(2,3)],point+Vector2(signum*(15+age*8),-21-age*17)*factor,factor*0.7,light)
		"HEARTH_WARM_CURRENT":
			for i: int in range(3):
				var p := point+Vector2((i-1)*13,-9-i%2*9)*factor+drift
				_poly(out,[Vector2(-4,4),Vector2(-7,-2),Vector2(-4,-9),Vector2(1,-10),Vector2(-2,-2),Vector2(4,3),Vector2(5,-1),Vector2(8,-2),Vector2(7,6),Vector2(2,9)],p,factor,faded)
			for i: int in range(3): _chip(out,point+Vector2(i*10-10,-33-age*15-i%2*7)*factor,Vector2(1.5,1.5),factor,Color(light,0.8-age*0.4))
		"MYCELIAL_SPORES":
			for signum: int in [-1,1]:
				_poly(out,[Vector2(0,0),Vector2(signum*17,0),Vector2(signum*17,-7),Vector2(signum*25,-7),Vector2(signum*25,-9),Vector2(signum*14,-9),Vector2(signum*14,-3),Vector2(0,-3)],point+Vector2(0,-4)*factor,factor,faded)
				_cap(out,point+Vector2(signum*19,-11)*factor,factor*0.6,faded,light)
			for i: int in range(3): _chip(out,point+Vector2((i-1)*10,-29-age*18-i%2*5)*factor,Vector2(2,2),factor,Color(light,0.8-age*0.4))
		"ELDER_CANOPY":
			_poly(out,[Vector2(-25,-23),Vector2(-21,-37),Vector2(-10,-45),Vector2(12,-45),Vector2(23,-36),Vector2(26,-24),Vector2(22,-24),Vector2(18,-33),Vector2(10,-39),Vector2(-8,-39),Vector2(-17,-32),Vector2(-21,-23)],point+drift,factor,faded)
			for i: int in range(3): _leaf(out,point+Vector2((i-1)*17,-43-abs(i-1)*3)*factor+drift,factor*0.9,faded,(i-1)*0.6)
			for i: int in range(3): _poly(out,[Vector2(-2,0),Vector2(0,-6),Vector2(2,0),Vector2(0,3)],point+Vector2((i-1)*15,-18-age*15-i%2*7)*factor,factor,Color(light,0.85-age*0.4))

static func drawing_plan(point: Vector2, target: Vector2, unit: Dictionary, pose: Dictionary, factor: float=1.0, _impact_points: Array=[]) -> Array:
	var out: Array = []
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0 or factor>16: return out
	var info := inspect(unit,pose)
	if not bool(info.get("supported",false)): return out
	var palette: Array=info.palette
	var main := Color(str(palette[1]));var light := Color(str(palette[2]))
	var origin := point+Vector2(0,-23)*factor
	var arrival := target+Vector2(0,-18)*factor
	_source(out,origin,info.signature,info.phase,factor,main,light)
	_delivery(out,origin,arrival,info.signature,info.phase,factor,main,light)
	_recovery(out,target,info.signature,info.phase,factor,main,light)
	return out

static func draw(canvas: Object, point: Vector2, target: Vector2, unit: Dictionary, pose: Dictionary, factor: float=1.0, impact_points: Array=[]) -> bool:
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0 or factor>16 or not bool(inspect(unit,pose).get("supported",false)): return false
	for command: Dictionary in drawing_plan(point,target,unit,pose,factor,impact_points): canvas.draw_colored_polygon(command.points,command.color)
	return true
