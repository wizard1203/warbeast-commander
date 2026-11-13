extends RefCounted
## Observation-only pixel weapon, skill and acoustic identities for M66.
## Only supplied settled targets get hit marks; no proximity/RNG/gameplay writes.
const Data=preload("res://src/simulation/strategic_hero_expansion_m66.gd")
const Brush=preload("res://src/presentation/m63_av_brush.gd")
const Choreography=preload("res://src/presentation/heroic_kit_choreography_m67.gd")
const VERSION:="m66-twelve-frontline-visual-identities-v1"
const LIMIT:=120
const ICONS:={
	"OATH_NOTCH":["blade","sight"],"OATH_EDGE_PLEDGE":["broadblade","oath"],"OATH_LAST_WITNESS":["seal","wall"],"INNATE_OATH_REAVER":["seal","sight"],
	"BRIDGE_CROSSBEAM":["hammer","sweep"],"BRIDGE_LOCK_BRACE":["bastion","rivets"],"BRIDGE_LOAD_BEARER":["bastion","companions"],"INNATE_BRIDGE_VANGUARD":["hands","wall"],
	"RELIC_NAME_HOOK":["hook","pin"],"RELIC_COLD_EDGE":["twinblades","wisps"],"RELIC_UNFINISHED_DUEL":["skull","sweep"],"INNATE_RELIC_REAVER":["lantern","wounded"],
	"OSSUARY_FERRY_STRIKE":["bone_arrow","sweep"],"OSSUARY_CLOSED_PALL":["rib","drop"],"OSSUARY_PROCESSION":["coffin","march_steps"],"INNATE_OSSUARY_KNIGHT":["rib","sharing"],
	"PISTON_OFFSET_JAB":["drill","impact"],"PISTON_FLYWHEEL":["rotor","blade"],"PISTON_DEAD_CENTER":["wrench","shackles"],"INNATE_PISTON_FENCER":["rotor","metronome"],
	"RIVET_SHEAR_LINE":["wrench","fracture"],"RIVET_LOAD_PLATE":["plate","wall"],"RIVET_WORKING_PRESSURE":["battery","circuit_ring"],"INNATE_RIVET_LEGIONARY":["plate","anchor"],
	"THORN_GRAFT_CATCH":["vine","fork"],"THORN_SAP_BLADE":["blade","drop"],"THORN_GRAFT_RUPTURE":["sprout","wisps"],"INNATE_THORN_REAVER":["thorns","pin"],
	"ANTLER_BRANCH_SWEEP":["roots","fan"],"ANTLER_BARK_FOLD":["roots","march_steps"],"ANTLER_RUT_SEASON":["roots","cage"],"INNATE_ANTLER_WARRIOR":["leaf","march_steps"],
	"SLAG_TEMPER_CUT":["twinblades","snow"],"SLAG_WHITE_HEAT":["blade","temper"],"SLAG_QUENCH_VERDICT":["broadblade","fissure"],"INNATE_SLAG_DANCER":["flame","sight"],
	"BASALT_STRATA_BLOW":["hammer","fissure"],"BASALT_LOAD_TEST":["mountain","anchor"],"BASALT_FAULT_STANCE":["mountain","formation"],"INNATE_BASALT_CHAMPION":["slab","wall"],
	"PRISM_FACET_PIN":["mantis","cage"],"PRISM_DOUBLE_EDGE":["twinblades","crystal_wings"],"PRISM_REFRACTION_CUT":["crystals","fork"],"INNATE_PRISM_MANTIS":["crystals","shackles"],
	"CARAPACE_SHELL_SPLIT":["jaw","impact"],"CARAPACE_NEST_GUARD":["shell","sharing"],"CARAPACE_LAYERED_MOLT":["shell","afterglow"],"INNATE_CARAPACE_WARRIOR":["shell","ward_runes"]}
const PALETTES:={
	"OATH_REAVER":["171923","604459","c58b9d","8ec9c3","fff0c9","b6add1","b3b5aa"],"BRIDGE_VANGUARD":["1b1b22","64543d","ba9b68","7faab9","fff0ba","be8e91","bdc9b4"],
	"RELIC_REAVER":["1d1825","5d426e","ae85bd","8bc4ba","fff1d4","d7a478","9eadc0"],"OSSUARY_KNIGHT":["1c1c22","605448","c1b48d","9a92c5","fff1c4","92b5c6","a8b7aa"],
	"PISTON_FENCER":["171d23","415a67","86b6c9","d5a073","f2f4cc","a3c3a5","b299bd"],"RIVET_LEGIONARY":["191d22","5d4f41","b99762","7fc2b9","fff1bf","c996a7","adbeb8"],
	"THORN_REAVER":["1b1c24","63465d","b689aa","8cbe82","fff0cf","86b9c5","c6ab70"],"ANTLER_WARRIOR":["17231f","416451","93b77d","c1a3cc","f8efcb","80b9c4","b9a286"],
	"SLAG_DANCER":["211a22","754744","d79868","91bbcf","fff1bf","c28fb8","b1bd9c"],"BASALT_CHAMPION":["1b1d24","55516b","a49fb8","d3a169","fff0c1","8cb9b3","baa7a4"],
	"PRISM_MANTIS":["1b1b27","4d567c","9aa3d1","ddb37d","fff2cf","8cc9ba","c395b2"],"CARAPACE_WARRIOR":["201b27","67516b","ad8eb5","9fc283","fff1cb","89b9c8","cba389"]}
const WEAPONS:={
	"OATH_REAVER":[Vector2(-3,20),Vector2(-3,6),Vector2(-10,6),Vector2(-10,2),Vector2(-3,2),Vector2(-3,-19),Vector2(3,-28),Vector2(7,-22),Vector2(5,2),Vector2(11,2),Vector2(11,6),Vector2(3,6),Vector2(3,20)],
	"BRIDGE_VANGUARD":[Vector2(-3,20),Vector2(-3,-2),Vector2(-19,-2),Vector2(-19,-12),Vector2(-10,-12),Vector2(-10,-18),Vector2(11,-18),Vector2(11,-12),Vector2(19,-12),Vector2(19,-2),Vector2(3,-2),Vector2(3,20)],
	"RELIC_REAVER":[Vector2(-3,21),Vector2(-4,-8),Vector2(-16,-11),Vector2(-21,-22),Vector2(-10,-26),Vector2(0,-19),Vector2(13,-26),Vector2(20,-19),Vector2(10,-9),Vector2(3,-8),Vector2(3,21)],
	"OSSUARY_KNIGHT":[Vector2(-3,22),Vector2(-3,-10),Vector2(-19,-3),Vector2(-14,-18),Vector2(4,-24),Vector2(20,-17),Vector2(12,-10),Vector2(3,-12),Vector2(3,22)],
	"PISTON_FENCER":[Vector2(-8,20),Vector2(-8,-2),Vector2(-12,-2),Vector2(-12,-9),Vector2(-5,-9),Vector2(-5,-19),Vector2(0,-28),Vector2(5,-19),Vector2(5,-9),Vector2(12,-9),Vector2(12,-2),Vector2(2,-2),Vector2(2,20)],
	"RIVET_LEGIONARY":[Vector2(-3,23),Vector2(-3,2),Vector2(-18,-2),Vector2(-15,-21),Vector2(-7,-25),Vector2(-7,-9),Vector2(7,-9),Vector2(7,-25),Vector2(15,-21),Vector2(18,-2),Vector2(3,2),Vector2(3,23)],
	"THORN_REAVER":[Vector2(-3,21),Vector2(-3,-7),Vector2(-16,-15),Vector2(-10,-27),Vector2(0,-21),Vector2(14,-26),Vector2(22,-14),Vector2(10,-18),Vector2(3,-9),Vector2(3,21)],
	"ANTLER_WARRIOR":[Vector2(-3,22),Vector2(-3,-8),Vector2(-18,-12),Vector2(-21,-26),Vector2(-14,-20),Vector2(-9,-21),Vector2(-3,-12),Vector2(1,-28),Vector2(6,-20),Vector2(5,-11),Vector2(13,-19),Vector2(20,-20),Vector2(15,-9),Vector2(3,-4),Vector2(3,22)],
	"SLAG_DANCER":[Vector2(-5,21),Vector2(-5,-10),Vector2(-13,-27),Vector2(-6,-23),Vector2(0,-14),Vector2(8,-29),Vector2(13,-24),Vector2(5,-7),Vector2(5,21)],
	"BASALT_CHAMPION":[Vector2(-4,22),Vector2(-4,-3),Vector2(-18,-3),Vector2(-22,-14),Vector2(-15,-24),Vector2(-3,-24),Vector2(-3,-19),Vector2(17,-19),Vector2(21,-8),Vector2(15,-1),Vector2(4,-1),Vector2(4,22)],
	"PRISM_MANTIS":[Vector2(-4,22),Vector2(-13,10),Vector2(-12,-10),Vector2(4,-27),Vector2(12,-20),Vector2(15,-8),Vector2(8,-14),Vector2(-4,-5),Vector2(-3,8),Vector2(5,18)],
	"CARAPACE_WARRIOR":[Vector2(-4,23),Vector2(-4,4),Vector2(-18,2),Vector2(-18,-12),Vector2(-8,-24),Vector2(0,-17),Vector2(9,-25),Vector2(19,-12),Vector2(18,2),Vector2(4,4),Vector2(4,23)]}
const VOICES:={"OATH_REAVER":["scrape",390,.30,3,"sharp_cut"],"BRIDGE_VANGUARD":["clang",180,.48,2,"falling_weight"],"RELIC_REAVER":["choir",315,.19,3,"inward_return"],"OSSUARY_KNIGHT":["reed",220,.27,4,"woven_drift"],"PISTON_FENCER":["click",620,.45,3,"directional_rush"],"RIVET_LEGIONARY":["clang",160,.55,2,"gather_and_lock"],"THORN_REAVER":["pluck",690,.18,4,"opening_fan"],"ANTLER_WARRIOR":["reed",340,.22,3,"breathing_lift"],"SLAG_DANCER":["crack",280,.55,2,"sharp_cut"],"BASALT_CHAMPION":["rumble",100,.60,2,"falling_weight"],"PRISM_MANTIS":["bell",990,.15,3,"staggered_reprise"],"CARAPACE_WARRIOR":["scrape",235,.38,3,"gather_and_lock"]}
static func sound(hero:String,slot:int=0,ultimate:bool=false)->Dictionary:
	if not VOICES.has(hero):return {}
	var v:Array=VOICES[hero]
	return {"voice":v[0],"frequency":float(v[1])*(1.0+float(slot)*.13),"texture":v[2],"pulses":int(v[3])+slot,"rhythm":v[4],"seconds":1.35 if ultimate else .52+slot*.08,"overtone":1.6+slot*.45,"sweep":-.22 if slot==0 else .18 if slot==1 else -.38,"echo":.12 if ultimate else .04}
static func actor_profile(unit:Dictionary)->Dictionary:
	var hero:=str(unit.get("hero_archetype",""))
	if not Data.has_hero(hero):return {}
	return {"identity":"hero:"+hero,"faction_id":Data.ROWS[hero][2],"name":Data.ROWS[hero][0],"silhouette":Data.STORIES[hero].silhouette,"palette":PALETTES[hero].duplicate(),"gesture":hero.to_lower()+"_actual_weapon","sound":sound(hero),"story_anchor":Data.STORIES[hero].origin,"counterplay":Data.STORIES[hero].counterplay,"identity_version":VERSION,"crest":[]}
static func skill_profile(id:String)->Dictionary:
	if not Data.SKILLS.has(id):return {}
	var hero:=Data.owner(id);var row:Dictionary=Data.SKILLS[id];var slot:int=Data.ROWS[hero][11].find(id)
	var result:={"skill_id":id,"hero_id":hero,"faction_id":Data.ROWS[hero][2],"name":row.name,"gesture":row.motif,"palette":PALETTES[hero].duplicate(),"sound":sound(hero,slot,id in Data.ULTIMATES),"story_anchor":Data.STORIES[hero].origin,"counterplay":Data.STORIES[hero].counterplay,"passive":bool(row.get("passive",false)),"identity_version":VERSION}
	result.merge(Choreography.profile(id),true)
	return result
static func inspect_skill(unit:Dictionary,pose:Dictionary)->Dictionary:
	var id:=str(pose.get("action","")).trim_prefix("SKILL_");var hero:=str(unit.get("hero_archetype",""));var phase:=float(pose.get("phase",-1))
	if not Data.has_hero(hero) or id not in Data.ROWS[hero][11] or int(unit.get("hp",0))<=0 or not bool(unit.get("alive",true)) or not is_finite(phase) or phase<0 or phase>=1:return {"supported":false}
	var rank:=int(pose.get("skill",{}).get("level",0));var s:=Data.skill(id,rank)
	if rank<=0 or s.is_empty() or bool(s.passive):return {"supported":false}
	var result:={"supported":true,"id":id,"hero":hero,"signature":s.motif,"profile":hero.to_lower()+"_"+str(s.motif),"family":s.family,"motif":s.motif,"phase":phase,"rank":rank,"ultimate":s.ultimate,"at_self":s.target_mode=="SELF","delivery":s.delivery,"effect":s.effect,"target_shape":"self" if s.target_mode=="SELF" else str(s.delivery).to_lower(),"faction":s.source_faction,"palette":PALETTES[hero].duplicate(),"material_mode":s.material,"layers":["actual_weapon_windup","thick_dark_pixel_edge","individual_weapon_motion","truthful_settled_hit","named_material_recovery"],"max_draw_operations":LIMIT,"visual_extent":Vector2(210,170),"settled_only":true,"visual_extent_is_hit_range":false,"authoritative_radius":s.radius,"weapon_family":hero.to_lower()+"_weapon","weapon_identity_version":VERSION,"palette_story":Data.STORIES[hero].origin,"choreography":s.motif,"emblem":s.emblem,"rhythm":"double" if s.ultimate else "snap"}
	result["choreography_version"]=Choreography.VERSION
	result["actual_render_branch"]=Choreography.profile(id).actual_render_branch
	return result
static func _paint(ctx:Dictionary,origin:Vector2,center:Vector2,hero:String,id:String,t:float,s:float,at_self:bool,ultimate:bool)->void:
	var p:Array=PALETTES[hero];var weapon:Array=WEAPONS[hero]
	var d:=(center-origin).normalized()
	if d.length_squared()<.1:d=Vector2.RIGHT
	var n:=d.orthogonal();var release:=clampf((t-.18)/.48,0,1);var a:=clampf(sin(t*PI)*1.45,0,1)
	var slot:int=Data.ROWS[hero][11].find(id)
	var hand:=origin+Vector2(7,-8)*s
	if at_self:
		for side:int in [-1,1]:
			var at:=origin+Vector2(side*(16+release*9),-14-8*sin(t*PI))*s
			if Data.ROWS[hero][3]!="WARRIOR" or ultimate:Brush.stamp(ctx,at,weapon,s*(.46 if not ultimate else .65),p,side*(.3+t*.4),a*.8)
			if Data.ROWS[hero][3]=="WARRIOR":
				Brush.stamp(ctx,origin+Vector2(side*20,-5)*s,[Vector2(-5,-15),Vector2(4,-19),Vector2(8,-6),Vector2(5,13),Vector2(-4,17),Vector2(-7,2)],s*.7,p,side*.12,a*.65)
	else:
		if ultimate and Data.ROWS[hero][3]=="MELEE_CASTER":_finisher(ctx,origin,center,hero,t,s,p,weapon,a)
		else:
			var head:=hand.lerp(center,release)
			var angle:=d.angle()+PI*.5+(-.55+release*.9 if Data.ROWS[hero][3]=="MELEE_CASTER" else .2)
			Brush.stamp(ctx,head,weapon,s*(.7 if ultimate else .5),p,angle,a)
	# Faction material has a different motion and silhouette, never just hue.
	var faction:=str(Data.ROWS[hero][2])
	var focal:=origin if at_self else center
	match faction:
		"HUMAN":
			for i:int in range(3 if ultimate else 2):
				var at:=hand.lerp(focal,(i+release)/4.0)+n*(i-1)*7*s
				Brush.stamp(ctx,at,[Vector2(-8,-3),Vector2(6,-5),Vector2(10,2),Vector2(1,6),Vector2(-6,3)],s*.7,p,(i-1)*.3,a*.55)
		"UNDEAD":
			for i:int in range(3):
				var at:=hand.lerp(focal,clampf(release-i*.14,0,1))-n*i*4*s
				Brush.stamp(ctx,at,weapon,s*(.35-i*.05),p,-.3+i*.25,a*(.34-i*.07))
		"MACHINE":
			for i:int in range(4 if ultimate else 2):
				var at:=hand-d*(i*6+release*8)*s+n*(i%2*2-1)*5*s
				Brush.stamp(ctx,at,[Vector2(-6,-3),Vector2(2,-6),Vector2(7,-1),Vector2(4,5),Vector2(-4,5)],s*.5,p,i*.5,a*.50)
		"FOREST":
			for i:int in range(5 if ultimate else 3):
				var at:=focal+Vector2(cos(i*2.4+t*2)*18*release,sin(i*2.4+t*2)*10-8-t*14)*s
				Brush.stamp(ctx,at,[Vector2(0,-7),Vector2(5,-3),Vector2(4,2),Vector2(0,7),Vector2(-4,2),Vector2(-5,-3)],s*.5,p,i*.7+t,a*.68)
		"HIGHLAND":
			for i:int in range(4 if ultimate else 2):
				var at:=focal+Vector2((i-1.5)*10*release,-20*sin(t*PI)+(i%2)*8+t*t*12)*s
				Brush.stamp(ctx,at,[Vector2(-7,-3),Vector2(-2,-7),Vector2(6,-4),Vector2(8,2),Vector2(2,6),Vector2(-6,4)],s*.6,p,i*.5,a*.7)
		"UNDERGROUND":
			for i:int in range(4 if ultimate else 2):
				var at:=focal+n*(i-1.5)*(7+release*8)*s+Vector2(0,-9-t*10)*s
				Brush.stamp(ctx,at,[Vector2(-4,8),Vector2(-7,-2),Vector2(0,-12),Vector2(7,-2),Vector2(4,8)],s*.55,p,(i-1.5)*.35,a*.62)
	if not at_self and t>=.35 and t<.85:
		Brush.stamp(ctx,center,[Vector2(-2,-12),Vector2(2,-12),Vector2(4,-1),Vector2(10,4),Vector2(7,7),Vector2(0,2),Vector2(-8,8),Vector2(-10,5),Vector2(-4,-1)],s*(1.0 if ultimate else .65),p,d.angle(),a)
		if slot==0 and Data.SKILLS[id].effect in ["STUN","ROOT"]:
			var low:bool=Data.SKILLS[id].effect=="ROOT"
			for side:int in [-1,1]:
				var at:=center+Vector2(side*(9-3*release),5 if low else -22)*s
				Brush.stamp(ctx,at,[Vector2(-3,-8),Vector2(3,-8),Vector2(3,5),Vector2(8,5),Vector2(8,9),Vector2(-3,9)],s*.45,p,PI if side<0 else 0,a*.85)
static func _finisher(ctx:Dictionary,origin:Vector2,center:Vector2,hero:String,t:float,s:float,p:Array,weapon:Array,a:float)->void:
	var q:=clampf((t-.24)/.42,0,1)
	match hero:
		"OATH_REAVER":
			# A single descending witness blade, not another travelling Q.
			var at:=center+Vector2(0,-76*(1-q))*s
			Brush.stamp(ctx,at,weapon,s*1.15,p,.08,a)
			for side:int in [-1,1]:Brush.stamp(ctx,at+Vector2(side*13,-27)*s,[Vector2(-5,-15),Vector2(4,-10),Vector2(7,8),Vector2(-3,14)],s*.55,p,side*.2,a*.6)
		"RELIC_REAVER":
			# A curtain of offset silhouettes closes on one soul; no AoE pool.
			for side:int in [-1,1]:
				var at:=center+Vector2(side*(28-19*q),-25)*s
				Brush.stamp(ctx,at,[Vector2(-8,21),Vector2(-11,2),Vector2(-6,-19),Vector2(0,-28),Vector2(8,-19),Vector2(12,10),Vector2(6,22),Vector2(1,15),Vector2(-3,22)],s*.75,p,side*.15,a*.45)
				Brush.stamp(ctx,at,weapon,s*.55,p,side*(1.0-q)*1.2,a*.9)
		"PISTON_FENCER":
			# Opposed jaws close along the firing line. Offset pistons remain open.
			for side:int in [-1,1]:
				var at:=center+Vector2(side*(44-30*q),-12)*s
				Brush.stamp(ctx,at,[Vector2(-7,27),Vector2(-7,-21),Vector2(2,-30),Vector2(8,-21),Vector2(7,8),Vector2(16,8),Vector2(16,16),Vector2(7,16),Vector2(7,27)],s*.9,p,side*.4,a)
		"THORN_REAVER":
			# A broken seed pod ejects uneven grafts, then folds inwards.
			for i:int in range(5):
				var angle:=float(i)*TAU/5+.25
				var at:=center+Vector2(cos(angle)*(13+q*18),sin(angle)*(9+q*12)-12)*s
				Brush.stamp(ctx,at,weapon,s*.48,p,angle+t*.35,a*(.65+i*.05))
		"SLAG_DANCER":
			# Hot and quenched blades cross once; pale vapor rises after the cut.
			for side:int in [-1,1]:
				var local:Array=p.duplicate()
				if side<0:local[2]="9bbdce";local[3]="d9e4d0"
				Brush.stamp(ctx,center+Vector2(side*12*(1-q),-12)*s,weapon,s*.95,local,side*(-.8+q*1.3),a)
			for i:int in range(3):Brush.stamp(ctx,center+Vector2((i-1)*9,-20-q*26-i*7)*s,[Vector2(-5,5),Vector2(-7,-1),Vector2(-2,-7),Vector2(5,-5),Vector2(6,3)],s*.45,p,i*.4,a*.4)
		"PRISM_MANTIS":
			# Three oblique cut planes collapse, not a generic central fireball.
			for i:int in range(3):
				var at:=center+Vector2((i-1)*(23-15*q),-20+i*6)*s
				Brush.stamp(ctx,at,[Vector2(-6,30),Vector2(-13,-13),Vector2(-3,-36),Vector2(6,-22),Vector2(12,17),Vector2(4,31)],s*.85,p,-.35+(i-1)*.4,a*.68)
static func draw_skill(canvas:Object,point:Vector2,target:Vector2,unit:Dictionary,pose:Dictionary,factor:float=1.0,impacts:Array=[])->bool:
	if not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0 or factor>16:return false
	var spec:=inspect_skill(unit,pose)
	if not bool(spec.get("supported",false)):return false
	var center:=point if spec.at_self else target
	if spec.delivery=="SINGLE" and not spec.at_self:
		for v:Variant in impacts:
			if typeof(v) in [TYPE_VECTOR2,TYPE_VECTOR2I] and Vector2(v).is_finite():center=Vector2(v);break
	var ctx:={"canvas":canvas,"count":0,"draw_limit":LIMIT-18,"phase":spec.phase,"quantum":maxf(1.0,roundf(factor))}
	var rendered:=Choreography.draw(ctx,point+Vector2(0,-18)*factor,center+Vector2(0,-9)*factor,str(spec.id),float(spec.phase),factor*(1+.07*(int(spec.rank)-1)),spec.palette,WEAPONS[spec.hero],impacts)
	if not rendered:_paint(ctx,point+Vector2(0,-18)*factor,center+Vector2(0,-9)*factor,str(spec.hero),str(spec.id),float(spec.phase),factor*(1+.07*(int(spec.rank)-1)),bool(spec.at_self),bool(spec.ultimate))
	# Additional hit feedback only from actual authority-supplied targets.
	ctx.draw_limit=LIMIT
	if not spec.at_self and float(spec.phase)>.4 and float(spec.phase)<.8:
		for v:Variant in impacts.slice(1,6):
			if typeof(v) not in [TYPE_VECTOR2,TYPE_VECTOR2I] or not Vector2(v).is_finite():continue
			Brush.stamp(ctx,Vector2(v)+Vector2(0,-10)*factor,[Vector2(-4,0),Vector2(0,-7),Vector2(4,0),Vector2(0,6)],factor*.7,spec.palette,0,.75)
	return true
static func inspect_attack(unit:Dictionary,pose:Dictionary)->Dictionary:
	var hero:=str(unit.get("hero_archetype",""));var t:=float(pose.get("phase",-1))
	if not Data.has_hero(hero) or pose.get("action","")!="ATTACK" or int(unit.get("hp",0))<=0 or not is_finite(t) or t<0 or t>=1:return {"supported":false}
	return {"supported":true,"signature":hero.to_lower()+"_weapon","label":Data.STORIES[hero].silhouette,"profile":hero.to_lower()+"_actual_blade","faction":Data.ROWS[hero][2],"phase":t,"family":"MELEE","heavy":Data.ROWS[hero][3]=="WARRIOR","visual_extent":Vector2(76,76),"particle_cap":12,"max_actions":96,"max_draw_operations":96,"max_impacts":6,"palette":PALETTES[hero].slice(1,4),"layers":["individual_weapon","material_recoil","settled_hit"],"settled_only":true}
static func attack_plan(point:Vector2,target:Vector2,unit:Dictionary,pose:Dictionary,factor:float=1.0,impacts:Array=[])->Array:
	var result:Array=[];var info:=inspect_attack(unit,pose)
	if not bool(info.get("supported",false)) or not point.is_finite() or not target.is_finite() or not is_finite(factor) or factor<=0 or factor>16:return result
	var hero:=str(unit.hero_archetype)
	var ctx:={"commands":result,"count":0,"draw_limit":96,"phase":info.phase,"quantum":maxf(1.0,roundf(factor))}
	_paint(ctx,point+Vector2(0,-18)*factor,target+Vector2(0,-10)*factor,hero,"",float(info.phase),factor,false,false)
	return result
