extends RefCounted
## Read-only finite-benefit projection. No pruning, authority, RNG or wall clock.
const Buffs=preload("res://src/simulation/strategic_combat_buffs.gd")
const Items=preload("res://src/simulation/strategic_hero_items.gd")
const MAX_IDENTITIES:=3
const MAX_DRAW_OPERATIONS:=96
const STYLES:={"QUICKDRAW":"oath_blades","CINDER_FERVOR":"cinder_quiver","GEAR_FERVOR":"rotor_exhaust","WIND_FERVOR":"leaf_wings","SPORE_MEND":"spore_backbow"}
const M67_STYLES:={"OATH_EDGE_PLEDGE":"witness_tabs","BRIDGE_LOCK_BRACE":"bridge_braces","BRIDGE_LOAD_BEARER":"bridge_braces","RELIC_COLD_EDGE":"memory_lanterns","OSSUARY_PROCESSION":"returning_sails","PISTON_FLYWHEEL":"piston_teeth","RIVET_LOAD_PLATE":"pressure_reserve","RIVET_WORKING_PRESSURE":"pressure_links","THORN_SAP_BLADE":"sap_threads","ANTLER_BARK_FOLD":"running_branches","SLAG_WHITE_HEAT":"weighted_white_edges","BASALT_FAULT_STANCE":"fault_counterweights","PRISM_DOUBLE_EDGE":"extended_facets","ASH_REQUIEM":"memory_tokens","BLOOM_SANCTUARY":"water_return","HEARTH_REFUGE":"hearth_braces"}
const RAMPS:={
	"HUMAN":["171521","9b6842","f2c779","f9f1c3","9bcddb"],
	"UNDEAD":["171320","90455e","ef8268","ffe1ae","a7b7db"],
	"MACHINE":["121b22","4d686d","8ed1cb","f5f0ce","ef9a63"],
	"FOREST":["13201e","548361","c3d87d","f4efca","ca9bd6"],
	"HIGHLAND":["21151c","a14935","f29b4c","fff1b2","91b8d8"],
	"UNDERGROUND":["1b1426","76508c","c094d1","fbecce","8ac6ac"]}

static func prepare(snapshot:Dictionary)->Dictionary:
	var bodies:={};var heroes:={}
	for key:String in ["soldiers","workers","buildings"]:
		for body:Dictionary in snapshot.get(key,[]):bodies[str(body.get("id",""))]=body
	var officers:Variant=snapshot.get("heroes",[])
	if officers is Dictionary:officers=officers.get("officers",[])
	for hero:Dictionary in officers:heroes[str(hero.get("id",""))]=hero
	return {"tick":int(snapshot.get("tick",0)),"bodies":bodies,"heroes":heroes}

static func _living(body:Dictionary)->bool:
	return int(body.get("hp",0))>0 and bool(body.get("alive",true))

static func read(unit:Dictionary,context:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if str(unit.get("unit_type",""))!="hero" or not _living(unit) or bool(unit.get("hidden",false)) or not bool(unit.get("visible",true)):return result
	var tick:=int(context.get("tick",0));var candidates:Array[Dictionary]=[];var winners:={}
	# Match strongest-per-category authority without calling its mutating values().
	for key:String in unit.get("source_buffs",{}):
		var entry:Dictionary=unit.source_buffs[key]
		if int(entry.get("expires_tick",-1))<=tick or int(entry.get("charges",-1))==0:continue
		if bool(entry.get("requires_source",false)) and not _living(context.get("bodies",{}).get(str(entry.get("source_id","")),{})):continue
		candidates.append(entry)
		for field:String in Buffs.FIELDS:
			var group:=str(entry.get("category",""))+":"+field
			if float(entry.get(field,0))>float(winners.get(group,{}).get(field,0)):winners[group]=entry
	for entry:Dictionary in candidates:
		var fields:={}
		for field:String in Buffs.FIELDS:
			if winners.get(str(entry.get("category",""))+":"+field,{})==entry and float(entry.get(field,0))>0:fields[field]=entry[field]
		if fields.is_empty():continue
		var mark:=_mark(str(entry.id),str(entry.get("source_id","")),int(entry.expires_tick)-tick,fields,unit)
		mark["remaining_charges"]=int(entry.get("charges",-1))
		mark["charge_kind"]=str(entry.get("charge_kind",""))
		result.append(mark)
	# Guard has its own authority timer (heals can grant it without source_buffs).
	if int(unit.get("guard_until_tick",-1))>tick and (int(unit.get("guard_armor_bonus",0))>0 or int(unit.get("guard_speed_bonus",0))>0):
		result.append(_mark("GUARD",str(unit.get("id","")),int(unit.guard_until_tick)-tick,{"armor_bonus":unit.get("guard_armor_bonus",0),"speed_bonus":unit.get("guard_speed_bonus",0)},unit))
	# Item records live on the hero, not on the soldier. Do not invent an item
	# buff from equipment ownership or a generic status FERVOR tag.
	var hero:Dictionary=context.get("heroes",{}).get(str(unit.get("id","")),{})
	for key:String in hero.get("item_effects",{}):
		var entry:Dictionary=hero.item_effects[key]
		if int(entry.get("expires_tick",-1))<=tick:continue
		var fields:={};var bonus:=Items.active_bonus({"item_effects":{key:entry}},tick)
		for field:String in bonus:
			if float(bonus.get(field,0))>0:fields[field]=bonus[field]
		if int(entry.get("shield_remaining",0))>0:fields["shield_remaining"]=int(entry.shield_remaining)
		if not fields.is_empty():result.append(_mark(key,str(unit.get("id","")),int(entry.expires_tick)-tick,fields,unit))
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var order:={"ATTACK":0,"SPELL":1,"WARD":2,"FLOW":3}
		return int(order[a.kind])<int(order[b.kind]) if a.kind!=b.kind else str(a.id)+str(a.source_id)<str(b.id)+str(b.source_id))
	return result

static func _mark(id:String,source:String,remaining:int,fields:Dictionary,unit:Dictionary)->Dictionary:
	var kind:="SPELL" if float(fields.get("skill_damage_percent",0))+float(fields.get("healing_percent",0))>0 else "ATTACK" if float(fields.get("damage_percent",0))+float(fields.get("damage_bonus",0))+float(fields.get("attack_speed_percent",0))>0 else "WARD" if float(fields.get("armor_bonus",0))+float(fields.get("magic_resist_percent",0))+float(fields.get("control_resist_percent",0))+float(fields.get("shield_remaining",0))>0 else "FLOW"
	var faction:=str(unit.get("faction_id","HUMAN"))
	var fallback:="forge_flames" if faction=="HIGHLAND" else "rotor_exhaust" if faction=="MACHINE" else "leaf_wings" if faction=="FOREST" else "cinder_quiver" if faction=="UNDEAD" else "mantis_molt" if faction=="UNDERGROUND" else "oath_blades"
	return {"id":id,"source_id":source,"kind":kind,"style":M67_STYLES.get(id,STYLES.get(id,fallback)),"remaining_ticks":remaining,"fields":fields,"faction":faction}

static func plan(point:Vector2,unit:Dictionary,marks:Array,tick:int,factor:float,bounds:Rect2)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	if not point.is_finite() or not is_finite(factor) or factor<=0 or factor>8 or not bounds.position.is_finite() or not bounds.size.is_finite() or not _living(unit):return out
	var scale:=maxf(factor,.5)
	# Stable body bounds, never sword/cast extent; body remains visible between
	# the bright shoulders. Simulation tick freezes both flicker and orbit.
	var half:=clampf(bounds.size.x*.43,10*scale,24*scale)
	var height:=clampf(bounds.size.y*.70,25*scale,51*scale)
	for slot:int in range(mini(marks.size(),MAX_IDENTITIES)):
		var mark:Dictionary=marks[slot]
		if int(mark.get("remaining_ticks",0))<=0:continue
		var ramp:Array=RAMPS.get(str(mark.get("faction","HUMAN")),RAMPS.HUMAN)
		var phase:=float(posmod(tick+slot*11,48))/48.0
		var pulse:=.78+.15*sin(phase*TAU)
		if _m67_plan(out,point,mark,ramp,scale,half,height,phase,pulse):continue
		if str(mark.get("style",""))=="spore_backbow":
			# Fixed doubled bow arms sit close to the back shell. No travelling
			# missiles, extra victims, old giant sickles or fake charge counters.
			for side:int in [-1,1]:
				var at:=point+Vector2(side*(half+7*scale),-height*.65)
				var bend:=sin(phase*TAU)*2.0
				_outline(out,at,[Vector2(-10,-2),Vector2(-6,-7-bend),Vector2(5,-7-bend),Vector2(10,-2),Vector2(6,1),Vector2(3,-3),Vector2(-4,-3),Vector2(-6,1)],scale*.9,ramp,2,pulse*.85,"REAR")
				_outline(out,at+Vector2(0,1)*scale,[Vector2(-7,0),Vector2(7,0),Vector2(7,2),Vector2(-7,2)],scale*.75,ramp,4,.8,"FRONT")
			continue
		# Legacy identities have different first silhouettes, not a shared
		# twin-flame shell with different colors. All are finite-benefit marks;
		# none depicts extra targets, missiles, attacks or a larger hit radius.
		_legacy_plan(out,point,str(mark.get("style","")),ramp,scale,half+slot*3*scale,height,phase,pulse)
		# Spell empowerment: orbiting book-like shards, not a false weapon aura.
		if mark.kind=="SPELL":
			for n:int in range(3):
				var turn:=phase*TAU+float(n)*TAU/3
				var at:=point+Vector2(cos(turn)*(half+9*scale),-height*.52+sin(turn)*height*.4)
				_legacy_outline(out,at,[Vector2(-5,-8),Vector2(2,-11),Vector2(7,-3),Vector2(3,9),Vector2(-5,5)],scale*.8,ramp,4,.88,"FRONT" if sin(turn)>0 else "REAR")
		# A few bright, large pixels on the torso edge communicate active energy
		# at distant zoom. Never place a solid overlay over the actor's face.
		for n:int in range(3):
			var travel:=fposmod(phase+n*.33,1.0)
			var at:=point+Vector2((1 if n%2 else -1)*(half+3*scale),-travel*height)
			_legacy_outline(out,at,[Vector2(-2,0),Vector2(0,-4),Vector2(2,0),Vector2(0,3)],scale*1.25,ramp,3,.95,"FRONT")
	return out

static func _legacy_plan(out:Array[Dictionary],point:Vector2,style:String,ramp:Array,scale:float,half:float,height:float,phase:float,pulse:float)->void:
	for side:int in [-1,1]:
		var wave:=sin(phase*TAU+side*.7)
		var at:=point+Vector2(side*(half+3*scale),-height*.43)
		match style:
			"oath_blades":
				# Upright steel/inscribed tabs hang separately from the hero's
				# real weapon. Cross guards and folded ribbons replace fire.
				var blade:=[Vector2(-3,17),Vector2(-3,-16),Vector2(0,-28),Vector2(4,-16),Vector2(4,17),Vector2(0,13)]
				_legacy_outline(out,at+Vector2(0,wave*3)*scale,blade,scale*.86,ramp,2,pulse,"REAR")
				_legacy_outline(out,at+Vector2(side*7,-15-wave*2)*scale,_mirror([Vector2(-3,-7),Vector2(5,-7),Vector2(5,9),Vector2(1,5),Vector2(-3,11)],side),scale*.65,ramp,4,.82,"REAR")
				_legacy_outline(out,at+Vector2(0,7)*scale,[Vector2(-7,-2),Vector2(7,-2),Vector2(7,1),Vector2(2,1),Vector2(2,5),Vector2(-2,5),Vector2(-2,1),Vector2(-7,1)],scale*.7,ramp,3,.88,"FRONT")
			"cinder_quiver":
				# Hollow funeral-quiver ribs and hanging ember lamps. Gaps
				# distinguish the shroud from living fire or a second body.
				var shroud:=[Vector2(-7,17),Vector2(-10,4),Vector2(-8,-14),Vector2(-3,-28),Vector2(3,-24),Vector2(8,-7),Vector2(6,15),Vector2(1,5),Vector2(-2,-5),Vector2(-3,13)]
				_legacy_outline(out,at+Vector2(side*2,wave*3)*scale,_mirror(shroud,side),scale*.85,ramp,2,.71,"REAR")
				var lamp:=at+Vector2(side*7,-23-wave*3)*scale
				_legacy_outline(out,lamp,[Vector2(-4,7),Vector2(-6,-2),Vector2(-3,-8),Vector2(3,-8),Vector2(6,-2),Vector2(4,7)],scale*.7,ramp,3,pulse,"REAR")
				_legacy_outline(out,at+Vector2(-side*3,9)*scale,_mirror([Vector2(-7,2),Vector2(-2,-5),Vector2(3,-3),Vector2(7,-9),Vector2(5,3),Vector2(-1,7)],side),scale*.65,ramp,4,.81,"FRONT")
			"rotor_exhaust":
				# Hard stepped flywheels, travelling piston teeth and short
				# rectangular vents: no soft smoke/fire silhouette.
				var gear:=[Vector2(-10,-12),Vector2(-4,-12),Vector2(-4,-18),Vector2(4,-18),Vector2(4,-12),Vector2(10,-12),Vector2(10,-4),Vector2(14,-4),Vector2(14,4),Vector2(10,4),Vector2(10,12),Vector2(4,12),Vector2(4,18),Vector2(-4,18),Vector2(-4,12),Vector2(-10,12),Vector2(-10,4),Vector2(-14,4),Vector2(-14,-4),Vector2(-10,-4)]
				_legacy_outline(out,at+Vector2(side*3,-1)*scale,gear,scale*.74,ramp,2,.88,"REAR")
				for index:int in range(2):
					var lift:=fposmod(phase+index*.5,1.0)
					_legacy_outline(out,at+Vector2(side*(3+lift*3),12-lift*29)*scale,[Vector2(-4,-3),Vector2(4,-3),Vector2(4,2),Vector2(-4,2)],scale*.7,ramp,4,.80-lift*.22,"FRONT")
				_legacy_outline(out,point+Vector2(side*(half-2*scale),-height*.18),[Vector2(-4,-4),Vector2(4,-4),Vector2(4,5),Vector2(-4,5)],scale*.65,ramp,3,.82,"FRONT")
			"leaf_wings":
				# Three separate feather-leaves fan outward. Mirroring the
				# shapes (not just origins) gives a true open wing silhouette.
				for index:int in range(3):
					var leaf_at:=point+Vector2(side*(half+(index*5+2)*scale),-height*(.23+index*.17)+wave*(index+1)*scale)
					var leaf:=[Vector2(-2,9),Vector2(-7,2),Vector2(-10,-8),Vector2(-8,-20),Vector2(-1,-29),Vector2(4,-21),Vector2(8,-8),Vector2(5,2)]
					_legacy_outline(out,leaf_at,_mirror(leaf,side),scale*(.60-index*.05),ramp,2 if index%2 else 4,pulse*.88,"REAR")
				_legacy_outline(out,at+Vector2(side*2,6)*scale,_mirror([Vector2(-3,10),Vector2(-3,-7),Vector2(4,-15),Vector2(6,-12),Vector2(1,-4),Vector2(1,10)],side),scale*.7,ramp,3,.83,"FRONT")
			"mantis_molt":
				# Disconnected chitin plates float away from a split shell.
				# Their folded, asymmetric facets are not giant phantom blades.
				for index:int in range(3):
					var plate_at:=point+Vector2(side*(half+(3+index*2)*scale),-height*(.20+index*.24)+wave*2*scale)
					var plate:=[Vector2(-6,8),Vector2(-10,-1),Vector2(-6,-13),Vector2(2,-17),Vector2(8,-7),Vector2(6,5),Vector2(1,-2),Vector2(-2,5)]
					_legacy_outline(out,plate_at,_mirror(plate,side),scale*(.70-index*.05),ramp,2 if index!=1 else 4,pulse*.86,"REAR")
				_legacy_outline(out,at+Vector2(-side*2,9)*scale,_mirror([Vector2(-5,5),Vector2(-6,-4),Vector2(0,-9),Vector2(5,-4),Vector2(3,4)],side),scale*.65,ramp,3,.86,"FRONT")
			_:
				# Highland alone owns a furnace-flame mantle. Two bright
				# tongues plus low square slag sparks preserve forge identity.
				var flame:=[Vector2(-8,15),Vector2(-10,2),Vector2(-7,-9),Vector2(-6,-22),Vector2(-1,-15),Vector2(3,-33-wave*4),Vector2(8,-18),Vector2(7,-2),Vector2(10,7),Vector2(5,16)]
				_legacy_outline(out,at,_mirror(flame,side),scale*.86,ramp,2,pulse*.9,"REAR")
				_legacy_outline(out,at+Vector2(-side*3,3)*scale,_mirror([Vector2(-3,10),Vector2(-5,0),Vector2(-1,-15),Vector2(3,-7),Vector2(4,4),Vector2(1,10)],side),scale*.65,ramp,3,.90,"FRONT")
				_legacy_outline(out,point+Vector2(side*(half-1*scale),-height*.15),_mirror([Vector2(-6,5),Vector2(-6,-5),Vector2(-2,-5),Vector2(-2,1),Vector2(6,1),Vector2(6,5)],side),scale*.72,ramp,4,.86,"FRONT")

static func _mirror(shape:Array,side:int)->Array:
	var result:Array=[]
	for point:Vector2 in shape:result.append(Vector2(point.x*side,point.y))
	return result

static func _legacy_outline(out:Array[Dictionary],center:Vector2,shape:Array,scale:float,ramp:Array,index:int,alpha:float,layer:String)->void:
	if out.size()+2>MAX_DRAW_OPERATIONS:return
	for pass_index:int in range(2):
		var points:=PackedVector2Array()
		for vertex:Vector2 in shape:
			var point:Vector2=(center+vertex*scale*(1.0 if pass_index==0 else .72)).round()
			if points.is_empty() or points[-1]!=point:points.append(point)
		if points.size()>1 and points[0]==points[-1]:points.remove_at(points.size()-1)
		# Quantization can collapse a tiny inner facet at distant zoom. Keep
		# its point/edge meaning as one legal pixel rectangle, never submit
		# a zero-area polygon. Original M67/spore path stays byte-identical.
		var area:=0.0
		for i:int in range(points.size()):area+=points[i].cross(points[(i+1)%points.size()])
		if points.size()<3 or absf(area)<.5:
			var rect:=Rect2(center.round(),Vector2.ONE)
			for point:Vector2 in points:rect=rect.expand(point)
			var size:=Vector2(maxf(1,rect.size.x),maxf(1,rect.size.y))
			points=PackedVector2Array([rect.position,rect.position+Vector2(size.x,0),rect.position+size,rect.position+Vector2(0,size.y)])
		out.append({"points":points,"color":Color(Color(str(ramp[0 if pass_index==0 else index])),minf(1,alpha*(1.12 if pass_index==0 else 1))),"layer":layer})

static func _m67_plan(out:Array[Dictionary],point:Vector2,mark:Dictionary,ramp:Array,scale:float,half:float,height:float,phase:float,pulse:float)->bool:
	if str(mark.get("style","")) not in M67_STYLES.values():return false
	var style:=str(mark.style)
	var charges:=clampi(int(mark.get("remaining_charges",-1)),0,3)
	# The count is the actual published remaining charge value; no phase-based
	# fake consumption. Noncharged windows never receive charge pips.
	if int(mark.get("remaining_charges",-1))>0:
		for index:int in range(charges):
			var at:=point+Vector2((index-(charges-1)*.5)*13*scale,-height-10*scale)
			var shape:Array=[Vector2(-4,8),Vector2(-4,-6),Vector2(0,-12),Vector2(5,-5),Vector2(4,8)]
			if style=="piston_teeth":shape=[Vector2(-5,7),Vector2(-5,-2),Vector2(-2,-2),Vector2(-2,-9),Vector2(3,-9),Vector2(3,-2),Vector2(6,-2),Vector2(6,7)]
			elif style in ["pressure_reserve","memory_tokens"]:shape=[Vector2(-6,7),Vector2(-8,-2),Vector2(-3,-9),Vector2(5,-8),Vector2(8,1),Vector2(3,8)]
			elif style=="extended_facets":shape=[Vector2(-3,11),Vector2(-6,-4),Vector2(1,-14),Vector2(6,-4),Vector2(3,11)]
			_outline(out,at,shape,scale*.7,ramp,4,.9,"FRONT")
	for side:int in [-1,1]:
		var at:=point+Vector2(side*(half+4*scale),-height*.44)
		match style:
			"witness_tabs","weighted_white_edges","extended_facets":
				var shape:Array=[Vector2(-4,18),Vector2(-4,-11),Vector2(1,-26),Vector2(6,-11),Vector2(4,18)] if style=="witness_tabs" else [Vector2(-6,18),Vector2(-7,-5),Vector2(-3,-25),Vector2(2,-33),Vector2(8,-11),Vector2(5,18)] if style=="weighted_white_edges" else [Vector2(-3,22),Vector2(-10,-7),Vector2(1,-30),Vector2(9,-12),Vector2(5,19)]
				_outline(out,at+Vector2(side*3,sin(phase*TAU)*3)*scale,shape,scale*.85,ramp,2,pulse*.8,"REAR")
				_outline(out,at,shape,scale*.48,ramp,3,.83,"FRONT")
			"piston_teeth","pressure_reserve","pressure_links":
				_outline(out,at,[Vector2(-8,-17),Vector2(6,-17),Vector2(12,-5),Vector2(8,15),Vector2(-8,15),Vector2(-12,4)],scale,ramp,2,.65,"REAR")
				for index:int in range(2):
					var dy:=fposmod(phase+index*.5,1.0)*25
					_outline(out,at+Vector2(side*4,-dy)*scale,[Vector2(-5,2),Vector2(-5,-4),Vector2(5,-4),Vector2(5,2)],scale*.65,ramp,4,.7,"FRONT")
			"memory_lanterns","returning_sails","memory_tokens":
				var shape:Array=[Vector2(-6,16),Vector2(-11,3),Vector2(-7,-18),Vector2(0,-28),Vector2(7,-16),Vector2(12,6),Vector2(5,17)] if style!="returning_sails" else [Vector2(-10,25),Vector2(-15,6),Vector2(-10,-22),Vector2(2,-35),Vector2(14,-14),Vector2(12,19),Vector2(4,26)]
				_outline(out,at,shape,scale*.85,ramp,2,.58,"REAR")
				for index:int in range(2):_outline(out,at+Vector2(side*(5+index*7),-10-sin(phase*TAU+index)*8)*scale,[Vector2(-3,5),Vector2(-5,-3),Vector2(0,-10),Vector2(5,-2),Vector2(3,5)],scale*.65,ramp,4,.78,"FRONT")
			"sap_threads","running_branches","water_return":
				var shape:Array=[Vector2(-3,21),Vector2(-7,0),Vector2(-15,-14),Vector2(-9,-18),Vector2(-1,-7),Vector2(8,-26),Vector2(13,-21),Vector2(3,1),Vector2(4,21)] if style!="water_return" else [Vector2(-4,19),Vector2(-8,8),Vector2(-4,-9),Vector2(3,-23),Vector2(7,-15),Vector2(8,1),Vector2(3,15)]
				_outline(out,at+Vector2(side*4,sin(phase*TAU+side)*4)*scale,shape,scale*.9,ramp,2,pulse*.75,"REAR")
				_outline(out,at+Vector2(side*7,-6)*scale,shape,scale*.55,ramp,4,.65,"FRONT")
			"bridge_braces","hearth_braces","fault_counterweights":
				var shape:Array=[Vector2(-10,22),Vector2(-10,-22),Vector2(-3,-22),Vector2(-3,-8),Vector2(11,-8),Vector2(11,1),Vector2(-3,1),Vector2(-3,22)] if style!="fault_counterweights" else [Vector2(-13,17),Vector2(-16,-4),Vector2(-6,-24),Vector2(5,-21),Vector2(15,-5),Vector2(10,17)]
				_outline(out,at,shape,scale*.85,ramp,2,.74,"REAR")
				_outline(out,at+Vector2(side*2,-7)*scale,[Vector2(-3,6),Vector2(-5,-1),Vector2(0,-9),Vector2(5,-1),Vector2(3,6)],scale*.8,ramp,3,pulse*.8,"FRONT")
	return true

static func _outline(out:Array[Dictionary],center:Vector2,shape:Array,scale:float,ramp:Array,index:int,alpha:float,layer:String)->void:
	if out.size()+2>MAX_DRAW_OPERATIONS:return
	for pass_index:int in range(2):
		var points:=PackedVector2Array()
		for vertex:Vector2 in shape:points.append((center+vertex*scale*(1.0 if pass_index==0 else .72)).round())
		out.append({"points":points,"color":Color(Color(str(ramp[0 if pass_index==0 else index])),alpha),"layer":layer})

static func draw(canvas:Object,operations:Array,layer:String)->int:
	var count:=0
	for operation:Dictionary in operations.slice(0,MAX_DRAW_OPERATIONS):
		if operation.layer!=layer:continue
		canvas.draw_colored_polygon(operation.points,operation.color);count+=1
	return count
