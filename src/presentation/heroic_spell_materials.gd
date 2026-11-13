extends RefCounted
## M57: finite, sampled pixel materials, not scene particle emitters.
## Narrative briefs select real construction paths; no simulation, victim
## lookup, RNG, timers, textures, nodes or persistent per-actor state.
const VERSION := "m57-18-authored-pixel-materials-v1"
const LORE_PATH := "res://assets/data/m57-lore.json"
const MODES := ["PAPER_WEAVE","INK_SEAL","GLASS_REFRACTION","GHOST_AFTERIMAGE","ASH_RIBBON","BONE_LANTERN","PRESSURE_SMOKE","RIVET_SPARK","CIRCUIT_TRACE","PETAL_SWARM","ROOT_EARTH","RAIN_THREAD","SLAG_CHUNK","STONE_STRATA","HEAT_VEIL","FUNGAL_MIST","CRYSTAL_DUST","ECHO_BAND"]
const MAX_REAR_OPERATIONS := 22
const MAX_FRONT_OPERATIONS := 30
const MAX_PARTICLES := 12
const LAYERS := {
	"PAPER_WEAVE":["folded_cloth","stitch_thread","paper_fragment"],
	"INK_SEAL":["negative_ink_shadow","broken_contract_seal","inward_ink_drops"],
	"GLASS_REFRACTION":["offset_glass_planes","refracted_highlight","mirror_shards"],
	"GHOST_AFTERIMAGE":["delayed_spectral_silhouettes","shadow_cutout","returning_wisps"],
	"ASH_RIBBON":["curling_ash_ribbons","soot_shadow","drifting_cinders"],
	"BONE_LANTERN":["bone_arch","hanging_lantern","ascending_cold_fire"],
	"PRESSURE_SMOKE":["stepped_pressure_plumes","matte_smoke_shadow","venting_puffs"],
	"RIVET_SPARK":["metal_splinters","hot_spark_trails","ballistic_rivets"],
	"CIRCUIT_TRACE":["open_right_angle_conduits","live_terminal","stepped_current"],
	"PETAL_SWARM":["large_petals","asymmetric_petal_curtain","curved_pollen_flight"],
	"ROOT_EARTH":["raised_soil_plate","branching_roots","falling_earth_chunks"],
	"RAIN_THREAD":["staggered_rain_threads","long_droplet","descending_beads"],
	"SLAG_CHUNK":["large_slag_body","luminous_fracture","ballistic_hot_rocks"],
	"STONE_STRATA":["layered_stone_shadow","offset_rock_sheets","lateral_stone_debris"],
	"HEAT_VEIL":["vertical_heat_sheets","cool_heat_shadow","ascending_flame_tongues"],
	"FUNGAL_MIST":["porous_spore_cloud","dark_mycelial_membrane","pulsing_spore_bubbles"],
	"CRYSTAL_DUST":["faceted_prisms","contrasting_crystal_plane","collapsing_crystal_grains"],
	"ECHO_BAND":["open_echo_arcs","delayed_sound_ribbons","compressed_wave_knots"],
}
const DESCRIPTIONS := {
	"PAPER_WEAVE":"折页、织线与错时翻动的纸帛，不用同心光圈代替纹样",
	"INK_SEAL":"层叠墨影、断笔契印与向内收束的印泥碎粒",
	"GLASS_REFRACTION":"偏折晶面、冷色折光片与错位的镜像高光",
	"GHOST_AFTERIMAGE":"有缺口的半透明虚影、延迟残像与逆向游走的魂屑",
	"ASH_RIBBON":"弯折灰带、漂浮煤烟与缓慢脱落的纸灰",
	"BONE_LANTERN":"骨架拱枝、悬灯剪影与垂直归航的冷火",
	"PRESSURE_SMOKE":"阶梯状压力烟团、沉重暗面与短促泄压喷流",
	"RIVET_SPARK":"长短金属火花、铆钉破片与有重量的抛物线",
	"CIRCUIT_TRACE":"折角导线、逐段点亮的端子与不闭合的电路走线",
	"PETAL_SWARM":"大片旋瓣、交错花粉与非对称的侧向花潮",
	"ROOT_EARTH":"土皮抬升、横向根须与带泥的木质碎块",
	"RAIN_THREAD":"细长雨线、短暂串珠与按纵列错时落下的水滴",
	"SLAG_CHUNK":"大块熔渣、明暗裂口与回落的热碎石",
	"STONE_STRATA":"错层岩页、压低的地影与向两侧断开的石片",
	"HEAT_VEIL":"竖向热幕、波折的冷暗背面与上升火舌",
	"FUNGAL_MIST":"有孔洞的菌雾、厚暗菌膜与缓慢脉动的孢泡",
	"CRYSTAL_DUST":"多面晶砂、棱柱投影与由粗到细坍缩的亮屑",
	"ECHO_BAND":"不闭合的声弧、错时回声带与横向压缩的波节",
}
static var _loaded := false
static var _lore: Dictionary = {}

static func profile(hero: String, id: String) -> Dictionary:
	if not _loaded:
		_loaded=true
		if FileAccess.file_exists(LORE_PATH):
			var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(LORE_PATH))
			if parsed is Dictionary: _lore=parsed
	var brief: Dictionary=_lore.get("skills",{}).get(hero+":"+id,{})
	var mode:=str(brief.get("material_mode",""))
	if mode not in MODES: return {"supported":false}
	var motion:=str(brief.get("particle_motion",""))
	return {"supported":true,"hero_id":hero,"skill_id":id,"mode":mode,"choreography":str(brief.get("choreography","")),"particle_motion":motion,"motion_dialect":_motion_dialect(motion),"signature":str(brief.get("signature","")),"visual_brief":str(brief.get("visual_brief","")),"prompt":str(brief.get("prompt","")),"description":str(DESCRIPTIONS[mode]),"layers":LAYERS[mode].duplicate(),"version":VERSION,"particle_cap":MAX_PARTICLES,"rear_operation_cap":MAX_REAR_OPERATIONS,"front_operation_cap":MAX_FRONT_OPERATIONS}

static func draw_behind(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, entry: Dictionary) -> void:
	if str(entry.get("material_mode","")) not in MODES: return
	var before:=int(ctx.count)
	ctx.material_stage_limit=mini(int(ctx.get("draw_limit",160)),before+MAX_REAR_OPERATIONS)
	var t:=_material_phase(float(ctx.phase),str(entry.get("material_motion_dialect","")))
	# The first observed cast tick must already acknowledge the command.
	# Only its own faint rear material appears; attack bodies and emitted
	# fragments retain their zero-start envelopes and settled-hit boundaries.
	var a:=maxf(_envelope(t),.18*clampf(1.0-t/.16,0,1))
	var seed:=_seed(str(entry.id))
	var wide: bool=entry.target_shape not in ["single","chain","line"]
	var reach:=51.0 if wide and bool(entry.ultimate) else 30.0 if wide else 22.0
	var expansion:=clampf((t-0.08)/0.4,0,1)
	var focal:=center+Vector2(0,-20)*scale
	match str(entry.material_mode):
		"PAPER_WEAVE":
			for n: int in range(4):
				var side:=-1.0 if n%2 else 1.0
				var at:=center+Vector2(side*(12+n*7)*expansion,-11-n*12-t*8)*scale
				var fold:=sin(t*PI*2+n*1.7)*5
				_outlined(ctx,[Vector2(-14,-5),Vector2(8,-7-fold),Vector2(17,3),Vector2(2,8+fold),Vector2(-13,5)],at,scale,3 if n%2 else 2,a*.76,.12*side)
				_line(ctx,at+Vector2(-11,-2)*scale,at+Vector2(10,2)*scale,scale,4,a*.6)
		"INK_SEAL":
			for n: int in range(3):
				var at:=center+Vector2((n-1)*reach*.7,5-n*5)*scale
				_poly(ctx,[Vector2(-18,-5),Vector2(-12,-10),Vector2(-3,-8),Vector2(8,-12),Vector2(19,-3),Vector2(13,6),Vector2(2,3),Vector2(-7,8),Vector2(-18,4)],at,scale*(.7+expansion*.35),0,a*.52)
				_poly(ctx,[Vector2(-10,-4),Vector2(6,-4),Vector2(6,0),Vector2(0,0),Vector2(0,8),Vector2(-5,8),Vector2(-5,0),Vector2(-10,0)],at+Vector2(0,-15-n*5)*scale,scale,3 if n%2 else 2,a*.82,n*.2+t*.1)
		"GLASS_REFRACTION":
			for n: int in range(4):
				var side:=-1.0 if n%2 else 1.0
				var at:=focal+Vector2(side*(16+n*5)*(1.2-expansion*.5),-n*7)*scale
				_outlined(ctx,[Vector2(-14,-23),Vector2(2,-31),Vector2(17,3),Vector2(5,19),Vector2(-10,9)],at,scale*(.7+n*.07),2 if n%2 else 3,a*.36,side*.2)
				_line(ctx,at+Vector2(-4,-22)*scale,at+Vector2(6,7)*scale,1.2*scale,4,a*.58)
		"GHOST_AFTERIMAGE":
			for n: int in range(3):
				var lag:=float(3-n)*.15
				var at:=focal+Vector2(sin(t*3+seed)*reach*.5-(2-n)*13,-(2-n)*8-t*10)*scale
				var alpha:=a*(.12+n*.1)
				var ghost:=_afterimage_silhouette(str(entry.id))
				_poly(ctx,ghost,at,scale*(.8+lag),0,alpha+.12)
				_poly(ctx,ghost,at+Vector2(-2,-3)*scale,scale*(.72+lag),3,alpha)
				# Opaque inner absence is part of the ghost silhouette, not a
				# duplicated actor or a texture sampling the hidden battlefield.
				_poly(ctx,[Vector2(-5,-4),Vector2(5,-4),Vector2(2,12),Vector2(-2,8)],at,scale,0,alpha+.08)
		"ASH_RIBBON":
			for n: int in range(3):
				var at:=center+Vector2((n-1)*reach*.8,-n*11-t*13)*scale
				var bend:=sin(t*4+n)*9
				var shape: Array=[Vector2(-26,7),Vector2(-15,-3-bend),Vector2(1,-13),Vector2(23,-6),Vector2(31,1),Vector2(17,-1),Vector2(2,-5),Vector2(-12,3),Vector2(-22,12)]
				_poly(ctx,shape,at,scale,0,a*.28)
				_poly(ctx,shape,at+Vector2(0,-3)*scale,scale*.83,5 if n%2 else 2,a*.42)
		"BONE_LANTERN":
			for side: int in [-1,1]:
				var at:=center+Vector2(side*reach,-10-expansion*14)*scale
				_outlined(ctx,[Vector2(-3,22),Vector2(-7,5),Vector2(-5,-15),Vector2(7,-28),Vector2(19,-31),Vector2(10,-22),Vector2(2,-11),Vector2(1,7),Vector2(5,20)],at,scale,6,a*.65,side*.2)
				var lamp:=at+Vector2(side*-8,-18+sin(t*6+side)*5)*scale
				_outlined(ctx,[Vector2(-7,-10),Vector2(7,-10),Vector2(8,5),Vector2(0,13),Vector2(-8,5)],lamp,scale,3,a*.55)
				_line(ctx,lamp+Vector2(0,-5)*scale,lamp+Vector2(0,5)*scale,1.6*scale,4,a*.8)
		"PRESSURE_SMOKE":
			for n: int in range(5):
				var at:=center+Vector2((n-2)*reach*.36+(t-.5)*8,-10-n%2*13-expansion*13)*scale
				var puff: Array=[Vector2(-17,-5),Vector2(-12,-5),Vector2(-12,-13),Vector2(-4,-13),Vector2(-4,-18),Vector2(7,-18),Vector2(7,-12),Vector2(15,-12),Vector2(15,-4),Vector2(20,-4),Vector2(20,7),Vector2(12,7),Vector2(12,12),Vector2(-10,12),Vector2(-10,7),Vector2(-17,7)]
				_poly(ctx,puff,at,scale*(.55+expansion*.5+n*.05),0,a*.35)
				_poly(ctx,puff,at+Vector2(-2,-3)*scale,scale*(.48+expansion*.4+n*.04),1 if n%2 else 5,a*.26)
		"RIVET_SPARK":
			for n: int in range(5):
				var angle:=float(n)*1.27+seed*.3
				var normal:=Vector2.from_angle(angle)
				var at:=focal+Vector2(normal.x*reach*expansion,normal.y*reach*.7*expansion)*scale
				_outlined(ctx,[Vector2(-15,-3),Vector2(9,-3),Vector2(17,0),Vector2(7,4),Vector2(-13,4)],at,scale*.7,6,a*.7,angle)
				_line(ctx,at-normal*9*scale,at+normal*11*scale,1.2*scale,4,a*.9)
		"CIRCUIT_TRACE":
			for side: int in [-1,1]:
				var x:=side*reach
				var at:=center+Vector2(x,1)*scale
				var elbow:=center+Vector2(x,-42*expansion)*scale
				var end:=center+Vector2(side*9,-42*expansion)*scale
				_line(ctx,at,elbow,3.5*scale,0,a*.8)
				_line(ctx,elbow,end,3.5*scale,0,a*.8)
				_line(ctx,at,elbow,1.6*scale,2,a*.8)
				_line(ctx,elbow,end,1.6*scale,3,a*.8)
				_outlined(ctx,[Vector2(-5,-5),Vector2(5,-5),Vector2(5,5),Vector2(-5,5)],end,scale,4,a)
		"PETAL_SWARM":
			for n: int in range(5):
				var angle:=float(n)*1.9+t*2
				var at:=focal+Vector2(sin(angle)*reach,cos(angle)*reach*.45-t*8)*scale
				_outlined(ctx,[Vector2(-17,3),Vector2(-10,-10),Vector2(2,-14),Vector2(14,-5),Vector2(9,5),Vector2(-4,9)],at,scale*(.6+n*.06),2 if n%2 else 3,a*.65,angle*.7)
		"ROOT_EARTH":
			for n: int in range(4):
				var at:=center+Vector2((n-1.5)*reach*.55,9-n%2*6)*scale
				_outlined(ctx,[Vector2(-19,5),Vector2(-16,-6),Vector2(-7,-12),Vector2(0,-8),Vector2(9,-15),Vector2(19,-3),Vector2(16,7),Vector2(2,10)],at,scale,6,a*.58)
				var top:=at+Vector2((n%2*2-1)*12,-14-21*expansion)*scale
				_line(ctx,at,top,3.6*scale,0,a*.8)
				_line(ctx,at,top,1.7*scale,2,a*.85)
		"RAIN_THREAD":
			for n: int in range(6):
				var x:=(n-2.5)*reach*.38
				var progress:=clampf((t-float(n%3)*.065)/.65,0,1)
				var at:=center+Vector2(x,-78+progress*69)*scale
				_line(ctx,at+Vector2(-8,-24)*scale,at,2.2*scale,0,a*.6)
				_line(ctx,at+Vector2(-7,-21)*scale,at,scale,3 if n%2 else 4,a*.73)
		"SLAG_CHUNK":
			for n: int in range(4):
				var side:=-1.0 if n%2 else 1.0
				var at:=center+Vector2(side*(13+n*8)*expansion,7-sin(expansion*PI)*34+n%2*8)*scale
				_outlined(ctx,[Vector2(-14,-6),Vector2(-6,-14),Vector2(6,-11),Vector2(16,-1),Vector2(11,12),Vector2(-5,15),Vector2(-16,5)],at,scale*(.65+n*.08),1,a*.82,t*side+n*.3)
				_line(ctx,at+Vector2(-4,-8)*scale,at+Vector2(6,6)*scale,1.8*scale,3,a*.85)
		"STONE_STRATA":
			for n: int in range(4):
				var shift:=(n%2*2-1)*expansion*(9+n*4)
				var at:=center+Vector2(shift,10-n*10)*scale
				_outlined(ctx,[Vector2(-reach*.8,-4),Vector2(-reach*.5,-9),Vector2(reach*.68,-8),Vector2(reach,-2),Vector2(reach*.5,7),Vector2(-reach*.7,5)],at,scale,6 if n%2 else 2,a*(.55+n*.05))
		"HEAT_VEIL":
			for n: int in range(3):
				var at:=center+Vector2((n-1)*reach*.6,-12-t*13)*scale
				var sway:=sin(t*7+n*2)*7
				var veil: Array=[Vector2(-9,13),Vector2(-15,-3),Vector2(-8+sway,-22),Vector2(-4,-42),Vector2(3,-55),Vector2(1,-28),Vector2(11+sway,-9),Vector2(15,7),Vector2(7,16)]
				_poly(ctx,veil,at,scale,0,a*.22)
				_poly(ctx,veil,at+Vector2(-2,-2)*scale,scale*.8,2 if n%2 else 3,a*.32)
		"FUNGAL_MIST":
			for n: int in range(4):
				var at:=focal+Vector2((n-1.5)*reach*.48,-n%2*14-t*11)*scale
				var cloud: Array=[Vector2(-18,-4),Vector2(-12,-13),Vector2(-3,-11),Vector2(5,-18),Vector2(13,-11),Vector2(11,-3),Vector2(20,2),Vector2(14,12),Vector2(4,9),Vector2(-4,16),Vector2(-11,11),Vector2(-17,13)]
				_poly(ctx,cloud,at,scale*(.8+sin(t*PI+n)*.12),0,a*.36)
				_poly(ctx,cloud,at+Vector2(0,-3)*scale,scale*.78,2 if n%2 else 3,a*.28)
				_poly(ctx,[Vector2(-4,-3),Vector2(3,-4),Vector2(5,2),Vector2(-2,5)],at+Vector2(-4,-2)*scale,scale,0,a*.28)
		"CRYSTAL_DUST":
			for n: int in range(4):
				var angle:=float(n)*1.8+seed*.2
				var at:=focal+Vector2(cos(angle)*reach*(1.2-expansion*.5),sin(angle)*reach*.5-n*5)*scale
				_outlined(ctx,[Vector2(-10,10),Vector2(-13,-9),Vector2(1,-27),Vector2(12,-7),Vector2(8,12),Vector2(-2,19)],at,scale*(.55+n*.08),2 if n%2 else 3,a*.7,angle*.18)
				_poly(ctx,[Vector2(0,-20),Vector2(6,-6),Vector2(2,12)],at,scale*.7,4,a*.68,angle*.18)
		"ECHO_BAND":
			for n: int in range(4):
				var age:=clampf((t-n*.06)/.7,0,1)
				var width:=reach*(.35+age*.85)
				var at:=center+Vector2((n%2*2-1)*9,-10-n*11)*scale
				var band: Array=[Vector2(-width,9),Vector2(-width*.6,-1),Vector2(0,-8),Vector2(width*.7,-2),Vector2(width,5),Vector2(width*.6,1),Vector2(0,-3),Vector2(-width*.6,4)]
				_poly(ctx,band,at,scale,0,a*.45)
				_poly(ctx,band,at+Vector2(0,-2)*scale,scale*.94,3 if n%2 else 2,a*.56)
	ctx.erase("material_stage_limit")

static func draw_front(ctx: Dictionary, origin: Vector2, center: Vector2, scale: float, entry: Dictionary) -> void:
	var mode:=str(entry.get("material_mode",""))
	if mode not in MODES: return
	var before:=int(ctx.count)
	ctx.material_stage_limit=mini(int(ctx.get("draw_limit",160)),before+MAX_FRONT_OPERATIONS)
	var dialect:=str(entry.get("material_motion_dialect",""))
	var t:=_material_phase(float(ctx.phase),dialect)
	var alpha:=_envelope(t)
	var seed:=_seed(str(entry.id))
	var count:=12 if bool(entry.ultimate) else 8
	var wide: bool=entry.target_shape not in ["single","chain","line"]
	var reach:=62.0 if wide and bool(entry.ultimate) else 37.0 if wide else 23.0
	for n: int in range(count):
		var lag:=float(n%4)*.045
		if dialect=="staggered_reprise" and n%2: lag+=.22
		var age:=clampf((t-lag)/(.77-lag),0,1)
		var fade:=alpha*(.72-age*.32)
		var angle:=float(n)*2.399963+seed*.1
		var unit:=Vector2(cos(angle),sin(angle)*.58)
		var local:=unit*(7+reach*age)
		var size:=2.4+float(n%3)*.8+float(entry.rank-1)*.25
		var turn:=angle
		var cells: Array
		match mode:
			"PAPER_WEAVE":
				local=Vector2((n-count*.5)*7+sin(age*7+n)*9,-8-age*(25+n%3*7))
				cells=[Vector2(-size*2,-size),Vector2(size,-size*1.2),Vector2(size*1.8,size),Vector2(-size*.8,size*.8)]; turn=sin(age*5+n)*.4
			"INK_SEAL":
				local=unit*(reach*(1-age*.75))+Vector2(0,-6-age*8)
				cells=[Vector2(-size,-size),Vector2(size*.5,-size*1.3),Vector2(size*1.4,0),Vector2(size*.4,size),Vector2(-size,size*.5)]; turn=0
			"GLASS_REFRACTION":
				local=Vector2(unit.x*reach*(1-age*.45),-12-unit.y*reach*.4-age*26)
				cells=[Vector2(-size,-size*2.4),Vector2(size*.4,-size*3.3),Vector2(size*1.4,size*1.3),Vector2(-size*.3,size*2)]; turn=angle*.18
			"GHOST_AFTERIMAGE":
				local=Vector2(sin(age*5+n+seed)*reach*.7,-7-age*(25+n%3*8))
				cells=[Vector2(-size,3*size),Vector2(-size*1.4,0),Vector2(0,-size*2),Vector2(size*1.2,-size*.5),Vector2(size,2*size),Vector2(0,size)]; turn=sin(age*4+n)*.4
			"ASH_RIBBON":
				local=Vector2((n-count*.5)*5+sin(age*4+n)*14,-7-age*(17+n%4*8))
				cells=[Vector2(-size*2,-size*.6),Vector2(size,-size),Vector2(size*2,size*.6),Vector2(-size,size)]; turn=age*1.2+n
			"BONE_LANTERN":
				local=Vector2(unit.x*(reach*.8-age*8),-4-age*(40+n%3*6))
				cells=[Vector2(-size,-size),Vector2(0,-size*2.2),Vector2(size,-size),Vector2(size*.7,size),Vector2(0,size*1.6),Vector2(-size*.7,size)]; turn=0
			"PRESSURE_SMOKE":
				local=Vector2(unit.x*reach*age,-8-unit.y*15-age*32)
				cells=[Vector2(-size*1.7,-size),Vector2(-size*.5,-size),Vector2(-size*.5,-size*1.7),Vector2(size,-size*1.7),Vector2(size,size*.2),Vector2(size*1.7,size*.2),Vector2(size*1.7,size*1.2),Vector2(-size*1.7,size*1.2)]; turn=0
			"RIVET_SPARK":
				local=Vector2(unit.x*reach*age,unit.y*reach*age-age*19+age*age*31)
				cells=[Vector2(-size*2.5,-size*.5),Vector2(size*1.7,-size*.4),Vector2(size*2.4,0),Vector2(size*1.3,size*.6),Vector2(-size*2,size*.5)]; turn=angle+age*.4
			"CIRCUIT_TRACE":
				local=Vector2((n%2*2-1)*(10+floorf(age*4)*5),-6-floorf(age*6)*7-n%3*4)
				cells=[Vector2(-size,-size),Vector2(size,-size),Vector2(size,size),Vector2(-size,size)]; turn=0
			"PETAL_SWARM":
				local=Vector2(sin(age*5+n*1.8)*reach*(.4+age*.6),-9+cos(age*5+n)*reach*.4-age*17)
				cells=[Vector2(-size*2,size*.4),Vector2(-size,-size*1.6),Vector2(size,-size*1.4),Vector2(size*2,-size*.2),Vector2(size*.5,size),Vector2(-size,size*1.1)]; turn=age*3+n
			"ROOT_EARTH":
				local=Vector2(unit.x*reach*age,10-sin(age*PI)*20+float(n%3)*3)
				cells=[Vector2(-size*1.7,-size),Vector2(size*.5,-size*1.5),Vector2(size*1.9,0),Vector2(size,size*1.2),Vector2(-size,size)]; turn=age+n
			"RAIN_THREAD":
				local=Vector2((n-count*.5)*6-8+age*10,-70+age*70)
				cells=[Vector2(-size*.5,-size*2.8),Vector2(size*.3,-size*4),Vector2(size*.8,size*.5),Vector2(0,size*1.4),Vector2(-size*.6,size*.5)]; turn=-.18
			"SLAG_CHUNK":
				local=Vector2(unit.x*reach*age,unit.y*9-sin(age*PI)*(31+n%3*7)+age*13)
				size*=1.5
				cells=[Vector2(-size,-size),Vector2(size*.2,-size*1.5),Vector2(size*1.3,-size*.2),Vector2(size*.8,size*1.4),Vector2(-size*.9,size)]; turn=age*2+n
			"STONE_STRATA":
				local=Vector2((n%2*2-1)*(9+age*reach),-3-n%3*7+age*age*14)
				cells=[Vector2(-size*2,-size*.7),Vector2(size,-size),Vector2(size*2.2,0),Vector2(size,size*.7),Vector2(-size*1.5,size*.7)]; turn=(n%2*2-1)*age*.7
			"HEAT_VEIL":
				local=Vector2(unit.x*reach*.7+sin(age*8+n)*6,-7-age*(33+n%3*9))
				cells=[Vector2(-size,size),Vector2(-size*.7,-size),Vector2(size*.2,-size*3),Vector2(size*.5,-size),Vector2(size*1.1,size),Vector2(0,size*1.7)]; turn=sin(age*6+n)*.2
			"FUNGAL_MIST":
				local=Vector2(sin(age*3+n+seed)*reach*.7,-6-age*29+sin(age*4+n)*6)
				cells=[Vector2(-size,-size),Vector2(0,-size*1.5),Vector2(size,-size),Vector2(size*1.3,size*.3),Vector2(size*.5,size*1.3),Vector2(-size*.7,size)]; turn=age*.5
			"CRYSTAL_DUST":
				local=unit*(reach*(1-age*.7))+Vector2(0,-15-age*13)
				cells=[Vector2(-size,-size),Vector2(0,-size*2),Vector2(size,-size),Vector2(size*.8,size),Vector2(0,size*1.8),Vector2(-size*.8,size)]; turn=-angle*.3
			"ECHO_BAND":
				local=Vector2((n%2*2-1)*(reach*(.25+age*.75)),-12-n%4*8+sin(age*6+n)*3)
				cells=[Vector2(-size*.4,-size*2),Vector2(size*.7,-size*1.5),Vector2(size,0),Vector2(size*.4,size*2),Vector2(-size*.8,size*1.4),Vector2(-size*.7,0)]; turn=(n%2*2-1)*.2
		# Named motion is interpreted semantically, not hashed into a random
		# jitter. Return/extract actually contract; rain/drop fall; a fan opens;
		# relay/reprise release two staggered flights. No gameplay timing changes.
		match dialect:
			"gather_and_lock": local.x*=1-age*.5; local.y-=age*6
			"inward_return": local*=1-age*.55; local.y-=age*8
			"falling_weight": local.y+=age*24; turn+=age*.2
			"opening_fan": local.x*=.6+age*.9; local.y-=sin(age*PI)*9
			"directional_rush": local.x+=(age-.4)*21; local.y-=sin(age*PI)*5
			"breathing_lift": local.y-=sin(age*TAU)*5
			"sharp_cut": local=local.rotated(-.26+age*.5); turn+=age*.4
			"woven_drift": local.x+=sin(age*TAU*1.5+n*.8)*4
		var at:=center+(local+Vector2(0,-6))*scale
		_outlined(ctx,cells,at,scale,5 if n%2 else 6,fade,turn)
	ctx.erase("material_stage_limit")

static func _seed(id: String) -> float:
	var value:=0
	for byte: int in id.to_utf8_buffer(): value=(value*31+byte)%997
	return float(value%59)*.1

static func _afterimage_silhouette(id: String) -> Array:
	# A cloak, empty stage costume and reversed blade are not the same ghost
	# recolored. These particular briefs call for recognisable negative shapes.
	match id:
		"QUICKDRAW","WIND_FERVOR": return [Vector2(-29,13),Vector2(-28,-5),Vector2(-20,-18),Vector2(-11,-11),Vector2(-4,-25),Vector2(2,-15),Vector2(15,-23),Vector2(25,-11),Vector2(30,8),Vector2(20,2),Vector2(19,15),Vector2(10,7),Vector2(4,20),Vector2(-3,8),Vector2(-13,17),Vector2(-17,5)]
		"EMBER_MEND": return [Vector2(-30,22),Vector2(-21,8),Vector2(-5,-15),Vector2(6,-36),Vector2(19,-50),Vector2(14,-27),Vector2(7,-10),Vector2(18,-3),Vector2(13,5),Vector2(1,-1),Vector2(-17,18)]
		"SPORE_SEAL": return [Vector2(-27,12),Vector2(-19,-1),Vector2(-13,-21),Vector2(-1,-35),Vector2(15,-44),Vector2(6,-26),Vector2(5,-12),Vector2(20,-19),Vector2(13,-3),Vector2(25,5),Vector2(11,14),Vector2(2,7),Vector2(-8,18)]
		"ASH_REQUIEM": return [Vector2(-26,17),Vector2(-21,-7),Vector2(-11,-20),Vector2(-5,-17),Vector2(4,-19),Vector2(16,-10),Vector2(26,15),Vector2(15,9),Vector2(17,25),Vector2(4,19),Vector2(-4,27),Vector2(-17,21),Vector2(-15,8)]
		_: return [Vector2(-19,20),Vector2(-15,-4),Vector2(-8,-15),Vector2(-8,-30),Vector2(-2,-39),Vector2(7,-34),Vector2(8,-17),Vector2(18,-5),Vector2(16,17),Vector2(9,10),Vector2(3,27),Vector2(-4,12),Vector2(-12,22)]

static func _motion_dialect(motion: String) -> String:
	match motion:
		"close","hold","lock","clamp","prison","tighten","pledge","bind","seal": return "gather_and_lock"
		"return","extract","collapse","in","reseal": return "inward_return"
		"fall","drop","downbeat","settle": return "falling_weight"
		"fan","open","unroll","crosswake": return "opening_fan"
		"line","travel","march","dock","pierce","puncture": return "directional_rush"
		"breathe","exhale","relight","temper","shelter","rest","supply","coexist","song","chorus","flow","rise","smolder": return "breathing_lift"
		"snap","cut","execute","verdict","breach","fracture","discharge","thunder": return "sharp_cut"
		"double","reprise","relay","cadence","switchyard","overclock","offbeat": return "staggered_reprise"
		_: return "woven_drift"

static func _material_phase(t: float, dialect: String) -> float:
	if dialect=="gather_and_lock": return clampf(t*.6 if t<.35 else .21+(t-.35)*(.79/.65),0,1)
	if dialect=="sharp_cut": return pow(t,.82)
	if dialect=="inward_return": return pow(t,1.16)
	return t

static func _envelope(t: float) -> float:
	return clampf(t/.18,0,1)*clampf((1-t)/.24,0,1)

static func _outlined(ctx: Dictionary, cells: Array, at: Vector2, scale: float, color: int, alpha: float, angle: float=0.0) -> void:
	_poly(ctx,cells,at,scale*1.25,0,alpha*.88,angle)
	_poly(ctx,cells,at+Vector2(-.6,-.6)*scale,scale*.82,color,alpha,angle)

static func _line(ctx: Dictionary, start: Vector2, end: Vector2, width: float, color: int, alpha: float) -> void:
	if start.distance_squared_to(end)<1: return
	var normal:=(end-start).normalized().orthogonal()*width
	_poly(ctx,[start+normal,end+normal,end-normal,start-normal],Vector2.ZERO,1,color,alpha)

static func _poly(ctx: Dictionary, cells: Array, at: Vector2, scale: float, color_index: int, alpha: float=1.0, angle: float=0.0) -> void:
	if int(ctx.count)>=mini(int(ctx.get("draw_limit",160)),int(ctx.get("material_stage_limit",160))) or alpha<=.005: return
	var points:=PackedVector2Array()
	for cell: Vector2 in cells:
		var vertex:=(at+cell.rotated(angle)*scale).round()
		if points.is_empty() or vertex!=points[-1]: points.append(vertex)
	if points.size()>1 and points[0]==points[-1]: points.remove_at(points.size()-1)
	if points.size()<3 or Geometry2D.triangulate_polygon(points).is_empty(): return
	var color:=Color(str(ctx.palette[clampi(color_index,0,ctx.palette.size()-1)]),clampf(alpha,0,1))
	ctx.canvas.draw_colored_polygon(points,color)
	ctx.count=int(ctx.count)+1
