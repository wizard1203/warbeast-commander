extends RefCounted
## Original weapon props and motion; catalog is the only target/effect authority.
## Shapes are snapped to a coarse pixel grid, not imported competitor artwork.
const HUMAN=preload("res://src/presentation/factions/m61_human_machine_profiles.gd")
const DEAD=preload("res://src/presentation/factions/m61_undead_underworld_profiles.gd")
const GREEN=preload("res://src/presentation/factions/m61_forest_highland_profiles.gd")
const MAX_OPERATIONS:=40
# Distinct silhouettes including mundane tools: shovels, ladles and sewing
# needles are deliberate alternatives to giving every caster another orb.
const SHAPES:={
	"oath_standard":[Vector2(-2,20),Vector2(-2,-23),Vector2(17,-23),Vector2(12,-12),Vector2(2,-12),Vector2(2,20)],
	"gate_shield":[Vector2(-14,-19),Vector2(14,-19),Vector2(13,7),Vector2(0,23),Vector2(-13,7)],
	"prism_array":[Vector2(-5,21),Vector2(-6,-5),Vector2(-13,-15),Vector2(0,-26),Vector2(13,-15),Vector2(6,-5),Vector2(5,21)],
	"kite_longbow":[Vector2(-10,-23),Vector2(3,-17),Vector2(10,-5),Vector2(10,5),Vector2(3,17),Vector2(-10,23),Vector2(-4,13),Vector2(4,3),Vector2(4,-3),Vector2(-4,-13)],
	"contract_blade":[Vector2(-3,23),Vector2(-3,10),Vector2(-11,10),Vector2(-11,5),Vector2(-4,5),Vector2(-4,-18),Vector2(0,-29),Vector2(5,-18),Vector2(4,5),Vector2(12,5),Vector2(12,10),Vector2(3,10),Vector2(3,23)],
	"pressure_ram":[Vector2(-4,23),Vector2(-4,-5),Vector2(-17,-5),Vector2(-17,-19),Vector2(17,-19),Vector2(17,-5),Vector2(4,-5),Vector2(4,23)],
	"tesla_shuttle":[Vector2(-3,21),Vector2(-3,4),Vector2(-12,0),Vector2(-12,-18),Vector2(-5,-24),Vector2(-5,-7),Vector2(5,-7),Vector2(5,-24),Vector2(12,-18),Vector2(12,0),Vector2(3,4),Vector2(3,21)],
	"rivet_carbine":[Vector2(-25,-5),Vector2(-8,-5),Vector2(-8,-11),Vector2(15,-11),Vector2(15,-7),Vector2(29,-7),Vector2(29,-1),Vector2(13,-1),Vector2(7,5),Vector2(2,5),Vector2(1,15),Vector2(-6,15),Vector2(-8,4),Vector2(-25,5)],
	"resin_welder":[Vector2(-15,-14),Vector2(-6,-19),Vector2(2,-14),Vector2(2,-5),Vector2(15,-5),Vector2(22,-11),Vector2(26,-6),Vector2(17,3),Vector2(2,3),Vector2(2,17),Vector2(-12,17)],
	"signal_array":[Vector2(-3,20),Vector2(-3,0),Vector2(-15,-11),Vector2(-17,-24),Vector2(-11,-24),Vector2(-9,-13),Vector2(0,-6),Vector2(9,-13),Vector2(11,-24),Vector2(17,-24),Vector2(15,-11),Vector2(3,0),Vector2(3,20)],
	"ash_suture":[Vector2(-2,24),Vector2(-3,-19),Vector2(0,-28),Vector2(4,-19),Vector2(2,24)],
	"judgement_scythe":[Vector2(-3,24),Vector2(-3,-15),Vector2(-13,-18),Vector2(-23,-12),Vector2(-17,-23),Vector2(-3,-27),Vector2(14,-21),Vector2(21,-12),Vector2(9,-16),Vector2(3,-15),Vector2(3,24)],
	"soul_chain":[Vector2(-9,-24),Vector2(2,-24),Vector2(8,-17),Vector2(4,-9),Vector2(10,-3),Vector2(8,8),Vector2(0,13),Vector2(5,23),Vector2(-2,27),Vector2(-10,14),Vector2(-7,5),Vector2(-1,1),Vector2(-7,-5),Vector2(-10,-14)],
	"soul_lantern":[Vector2(-4,-25),Vector2(4,-25),Vector2(8,-17),Vector2(13,-12),Vector2(13,12),Vector2(0,24),Vector2(-13,12),Vector2(-13,-12),Vector2(-8,-17)],
	"bone_bow":[Vector2(-12,-25),Vector2(0,-21),Vector2(12,-12),Vector2(16,0),Vector2(12,12),Vector2(0,21),Vector2(-12,25),Vector2(-7,16),Vector2(5,9),Vector2(9,0),Vector2(5,-9),Vector2(-7,-16)],
	"grave_hook":[Vector2(-3,24),Vector2(-3,4),Vector2(-12,-3),Vector2(-14,-18),Vector2(-4,-27),Vector2(11,-24),Vector2(16,-11),Vector2(8,-15),Vector2(4,-20),Vector2(-5,-18),Vector2(-7,-10),Vector2(3,-1),Vector2(3,24)],
	"bell":[Vector2(-3,-25),Vector2(3,-25),Vector2(3,-20),Vector2(11,-15),Vector2(14,6),Vector2(21,12),Vector2(21,17),Vector2(4,17),Vector2(4,23),Vector2(-4,23),Vector2(-4,17),Vector2(-21,17),Vector2(-21,12),Vector2(-14,6),Vector2(-11,-15),Vector2(-3,-20)],
	"shovel":[Vector2(-6,-26),Vector2(6,-26),Vector2(6,-15),Vector2(3,-12),Vector2(3,4),Vector2(11,4),Vector2(10,17),Vector2(0,26),Vector2(-10,17),Vector2(-11,4),Vector2(-3,4),Vector2(-3,-12),Vector2(-6,-15)],
	"chitin_bastion":[Vector2(-16,-17),Vector2(-8,-12),Vector2(0,-25),Vector2(8,-12),Vector2(16,-17),Vector2(19,0),Vector2(12,17),Vector2(0,25),Vector2(-12,17),Vector2(-19,0)],
	"crystal_lance":[Vector2(-3,24),Vector2(-3,-3),Vector2(-12,-8),Vector2(-6,-20),Vector2(0,-31),Vector2(8,-20),Vector2(11,-6),Vector2(3,-3),Vector2(3,24)],
	"mantis_blades":[Vector2(-5,24),Vector2(-12,12),Vector2(-13,-9),Vector2(5,-29),Vector2(16,-22),Vector2(18,-10),Vector2(8,-17),Vector2(-3,-6),Vector2(-4,9),Vector2(1,20)],
	"spore_sieve":[Vector2(-3,24),Vector2(-3,6),Vector2(-17,-1),Vector2(-20,-13),Vector2(-10,-24),Vector2(8,-24),Vector2(20,-13),Vector2(17,-1),Vector2(3,6),Vector2(3,24)],
	"fault_pick":[Vector2(-3,25),Vector2(-3,-10),Vector2(-23,-4),Vector2(-14,-18),Vector2(0,-24),Vector2(17,-18),Vector2(24,-6),Vector2(3,-10),Vector2(3,25)],
	"root_claw":[Vector2(-15,24),Vector2(-18,4),Vector2(-14,-21),Vector2(-8,-29),Vector2(-8,-2),Vector2(-3,1),Vector2(0,-25),Vector2(5,-18),Vector2(5,3),Vector2(11,0),Vector2(15,-20),Vector2(19,-12),Vector2(18,13),Vector2(9,24)],
	"thorn_vine":[Vector2(-4,25),Vector2(-9,12),Vector2(-5,1),Vector2(-13,-4),Vector2(-5,-8),Vector2(4,-19),Vector2(15,-24),Vector2(9,-13),Vector2(1,-6),Vector2(7,4),Vector2(0,10),Vector2(2,21)],
	"longbow":[Vector2(-9,-28),Vector2(4,-18),Vector2(12,0),Vector2(4,18),Vector2(-9,28),Vector2(-6,17),Vector2(5,0),Vector2(-6,-17)],
	"leaf_blades":[Vector2(0,25),Vector2(-8,11),Vector2(-10,-6),Vector2(-4,-18),Vector2(11,-28),Vector2(9,-8),Vector2(5,10)],
	"seed_mortar":[Vector2(-12,-19),Vector2(-4,-25),Vector2(10,-24),Vector2(17,-14),Vector2(15,9),Vector2(6,22),Vector2(-9,24),Vector2(-18,7)],
	"water_fan":[Vector2(-2,22),Vector2(-23,-4),Vector2(-18,-19),Vector2(-7,-15),Vector2(0,-26),Vector2(7,-15),Vector2(18,-19),Vector2(23,-4),Vector2(2,22)],
	"stone_shield":[Vector2(-17,-21),Vector2(8,-25),Vector2(19,-12),Vector2(16,16),Vector2(2,27),Vector2(-16,15),Vector2(-20,0)],
	"rune_hammer":[Vector2(-3,25),Vector2(-3,-3),Vector2(-18,-3),Vector2(-21,-20),Vector2(-13,-25),Vector2(15,-25),Vector2(21,-16),Vector2(18,-3),Vector2(3,-3),Vector2(3,25)],
	"ember_saber":[Vector2(-3,26),Vector2(-3,13),Vector2(-10,12),Vector2(-9,7),Vector2(-3,7),Vector2(-3,-13),Vector2(3,-29),Vector2(10,-35),Vector2(6,-11),Vector2(4,7),Vector2(11,6),Vector2(12,11),Vector2(3,13),Vector2(3,26)],
	"forge_ladle":[Vector2(-2,25),Vector2(-2,-4),Vector2(-13,-9),Vector2(-17,-20),Vector2(-12,-28),Vector2(0,-31),Vector2(12,-28),Vector2(17,-20),Vector2(13,-9),Vector2(2,-4),Vector2(2,25)],
	"thunder_axe":[Vector2(-3,26),Vector2(-3,-2),Vector2(-20,-4),Vector2(-25,-21),Vector2(-14,-29),Vector2(-10,-17),Vector2(-3,-14),Vector2(-3,-28),Vector2(3,-28),Vector2(3,-14),Vector2(10,-17),Vector2(14,-29),Vector2(25,-21),Vector2(20,-4),Vector2(3,-2),Vector2(3,26)],
	"winged_bow":[Vector2(-17,-24),Vector2(-3,-18),Vector2(0,-6),Vector2(3,-18),Vector2(17,-24),Vector2(12,-10),Vector2(6,1),Vector2(12,13),Vector2(17,24),Vector2(3,17),Vector2(0,6),Vector2(-3,17),Vector2(-17,24),Vector2(-12,13),Vector2(-6,1),Vector2(-12,-10)]}

static func profile(id:String)->Dictionary:
	var value:=HUMAN.profile(id)
	if value.is_empty():value=DEAD.profile(id)
	if value.is_empty():value=GREEN.profile(id)
	return value

static func profiles()->Dictionary:
	var all:=HUMAN.profiles();all.merge(DEAD.profiles());all.merge(GREEN.profiles());return all

static func draw(ctx:Dictionary,origin:Vector2,center:Vector2,scale:float,entry:Dictionary)->bool:
	var spec:=profile(str(entry.id))
	if spec.is_empty() or not SHAPES.has(str(spec.weapon_family)):return false
	var t:=float(ctx.phase);var a:=clampf(sin(t*PI)*1.5,0,1)
	var before:=int(ctx.count);var ceiling:=mini(int(ctx.draw_limit),before+MAX_OPERATIONS)
	var old_limit:=int(ctx.draw_limit);ctx.draw_limit=ceiling
	var family:=str(spec.weapon_family)
	var release:=clampf((t-.15)/.45,0,1)
	var direction:=(center-origin).normalized()
	if direction.length_squared()<.1:direction=Vector2.RIGHT
	var angle:=direction.angle()+PI*.5
	var count:=1
	# Fan/line visual bodies describe casting material, not additional victims.
	# Existing settled connector pass remains the only extra hit indication.
	if entry.target_shape=="cone":count=3
	elif entry.target_shape=="line":count=2
	if bool(entry.at_self):
		for side:int in [-1,1]:
			_weapon(ctx,origin+Vector2(side*(22+8*release),-10-10*sin(t*PI))*scale,scale*.7,spec,side*(.35+t*.4),a*.8)
	elif str(entry.effect)=="HEAL":
		_weapon(ctx,origin+Vector2(-12,-15)*scale,scale*.75,spec,-.5+release*.8,a)
		for n:int in range(3):
			var p:=fposmod(release+n*.22,1.0)
			var at:=origin.lerp(center,p)+Vector2(0,-sin(p*PI)*28)*scale
			_chip(ctx,at,scale*(3-n*.5),str(spec.palette[3]),a)
	elif family in ["contract_blade","ember_saber","mantis_blades","leaf_blades"]:
		# A blade arc, flying-blade fan or mirrored mantis cut, never an orb.
		for n:int in range(3 if family=="leaf_blades" or bool(entry.ultimate) else 2):
			var sweep:=-1.3+release*2.6+float(n)*.45
			var at:=center+Vector2(cos(sweep)*20,sin(sweep)*10-14)*scale
			_weapon(ctx,at,scale*(.85 if n==0 else .55),spec,sweep-.6,a*(1.0-n*.18))
	elif family in ["grave_hook","soul_chain","thorn_vine"]:
		var head:=origin.lerp(center,release)
		for n:int in range(5):
			var at:=origin.lerp(head,float(n)/5)+Vector2(0,sin(float(n)*2+t*4)*5)*scale
			_weapon(ctx,at,scale*.2,spec,float(n)*.7,a*.7)
		_weapon(ctx,head,scale*.95,spec,angle+(.4 if family=="grave_hook" else -.2),a)
	elif family in ["rune_hammer","thunder_axe","pressure_ram","fault_pick","shovel","bell"]:
		# Heavy objects have a held high silhouette then a weighted descent.
		var at:=center+Vector2(0,-70*(1-release)-6)*scale
		_weapon(ctx,at,scale*(1.1 if bool(entry.ultimate) else .85),spec,-.6*(1-release),a)
		if release>.65:
			for side:int in [-1,1]:_chip(ctx,center+Vector2(side*15*release,4)*scale,scale*4,str(spec.palette[5]),a*.8)
	elif family in ["kite_longbow","longbow","bone_bow","rivet_carbine"]:
		_weapon(ctx,origin+Vector2(0,-8)*scale,scale*.72,spec,PI*.5 if family!="rivet_carbine" else direction.angle(),a)
		for n:int in range(count):
			var lane:=(float(n)-(count-1)*.5)
			var head:=origin.lerp(center,release)+direction.orthogonal()*lane*22*release*scale
			_arrow(ctx,head,angle,scale, spec,a,family=="rivet_carbine")
		if family=="rivet_carbine" and t>.17 and t<.5:
			_chip(ctx,origin+direction*22*scale,scale*8,str(spec.palette[4]),a)
	elif family in ["spore_sieve","seed_mortar","forge_ladle","water_fan","ash_suture","resin_welder"]:
		_weapon(ctx,origin+Vector2(0,-7)*scale,scale*.8,spec,-.4+release*.7,a)
		for n:int in range(count+1):
			var q:=clampf(release-float(n)*.17,0,1)
			var at:=origin.lerp(center,q)+Vector2((n-.5)*10,-sin(q*PI)*(25+n*9))*scale
			_weapon(ctx,at,scale*.28,spec,float(n)+t*2,a*.8)
	else:
		for n:int in range(count):
			var at:=origin.lerp(center,release)+direction.orthogonal()*(float(n)-(count-1)*.5)*26*release*scale
			_weapon(ctx,at,scale*(.95 if bool(entry.ultimate) else .7),spec,angle+t*.2,a)
	ctx.draw_limit=old_limit
	return true

static func _weapon(ctx:Dictionary,point:Vector2,scale:float,spec:Dictionary,angle:float,alpha:float)->void:
	var shape:Array=SHAPES[str(spec.weapon_family)]
	_poly(ctx,shape,point,scale,angle,Color(str(spec.palette[0]),alpha))
	_poly(ctx,shape,point+Vector2(-1,-1)*scale,scale*.76,angle,Color(str(spec.palette[2]),alpha))
	# Distinct hard material cut, not a blur; the ink body remains >=one pixel.
	_poly(ctx,[Vector2(-1,8),Vector2(-1,-14),Vector2(2,-18),Vector2(2,6)],point,scale,angle,Color(str(spec.palette[4]),alpha*.88))

static func _arrow(ctx:Dictionary,point:Vector2,angle:float,scale:float,spec:Dictionary,alpha:float,bullet:bool)->void:
	var shape:=[Vector2(-2,15),Vector2(-2,-8),Vector2(-7,-5),Vector2(0,-22),Vector2(7,-5),Vector2(2,-8),Vector2(2,15),Vector2(7,20),Vector2(0,17),Vector2(-7,20)]
	if bullet:shape=[Vector2(-4,14),Vector2(-4,-5),Vector2(0,-13),Vector2(4,-5),Vector2(4,14)]
	_poly(ctx,shape,point,scale*.75,angle,Color(str(spec.palette[0]),alpha))
	_poly(ctx,shape,point,scale*.5,angle,Color(str(spec.palette[3]),alpha))

static func _chip(ctx:Dictionary,point:Vector2,scale:float,color:String,alpha:float)->void:
	_poly(ctx,[Vector2(-1,0),Vector2(0,-2),Vector2(2,0),Vector2(0,1)],point,scale,0,Color(color,alpha))

static func _poly(ctx:Dictionary,shape:Array,point:Vector2,scale:float,angle:float,color:Color)->void:
	if int(ctx.count)>=int(ctx.draw_limit) or color.a<=.01:return
	var q:=maxf(1,float(ctx.get("quantum",1)))
	var points:=PackedVector2Array()
	for vertex:Vector2 in shape:
		var at:=((point+vertex.rotated(angle)*scale)/q).round()*q
		if points.is_empty() or points[-1]!=at:points.append(at)
	if points.size()>1 and points[0]==points[-1]:points.remove_at(points.size()-1)
	if points.size()<3:return
	var area:=0.0
	for n:int in range(points.size()):area+=points[n].cross(points[(n+1)%points.size()])
	if absf(area)<.5:return
	# Quantization can fold a narrow chain notch onto itself at distant zoom.
	# Reject that tiny ornament rather than sending an invalid polygon to GPU.
	if Geometry2D.triangulate_polygon(points).is_empty():return
	ctx.canvas.draw_colored_polygon(points,color);ctx.count=int(ctx.count)+1
