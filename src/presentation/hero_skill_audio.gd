extends RefCounted
## Local, original layered sound recipes. Lore supplies material and rhythm,
## never damage or event authority. Streams are lazy and bounded; the catalogue
## contains descriptions, not 72 eagerly decoded long recordings.
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const FactionAV = preload("res://src/presentation/heroic_faction_av.gd")
const RATE := 22050
const MAX_CACHE_ENTRIES := 32
const MAX_PCM_BYTES := 8 * 1024 * 1024
const VERSION := "m63-actor-material-envelope-audio-v1"
const MODES := ["PAPER_WEAVE","INK_SEAL","GLASS_REFRACTION","GHOST_AFTERIMAGE","ASH_RIBBON","BONE_LANTERN","PRESSURE_SMOKE","RIVET_SPARK","CIRCUIT_TRACE","PETAL_SWARM","ROOT_EARTH","RAIN_THREAD","SLAG_CHUNK","STONE_STRATA","HEAT_VEIL","FUNGAL_MIST","CRYSTAL_DUST","ECHO_BAND"]
const MODE_VOICES := {
	"PAPER_WEAVE":[420,0.32,5],"INK_SEAL":[155,0.24,3],"GLASS_REFRACTION":[1120,0.12,7],
	"GHOST_AFTERIMAGE":[270,0.28,2],"ASH_RIBBON":[105,0.62,4],"BONE_LANTERN":[640,0.2,3],
	"PRESSURE_SMOKE":[85,0.74,2],"RIVET_SPARK":[850,0.52,6],"CIRCUIT_TRACE":[330,0.18,8],
	"PETAL_SWARM":[740,0.16,5],"ROOT_EARTH":[95,0.48,3],"RAIN_THREAD":[1380,0.28,9],
	"SLAG_CHUNK":[120,0.66,4],"STONE_STRATA":[165,0.54,5],"HEAT_VEIL":[230,0.44,2],
	"FUNGAL_MIST":[390,0.44,6],"CRYSTAL_DUST":[1520,0.13,7],"ECHO_BAND":[210,0.22,4],
}
const ATTACK_VOICES := {"GUNPOWDER":[105,0.9,3],"IMPACT":[90,0.65,2],"EDGE":[650,0.52,4],"PIERCE":[1250,0.3,3],"ARCANE":[460,0.2,6],"CHAOS":[185,0.72,7]}
const ITEM_VOICES := {"POTION":[810,0.08,3],"MANA_POTION":[1130,0.1,4],"RESTORATION_DRAUGHT":[740,0.08,4],"CLEANSE_DRAUGHT":[1660,0.08,7],"GUARD_DRAUGHT":[320,0.28,2],"HASTE_DRAUGHT":[580,0.16,8],"ASSAULT_DRAUGHT":[840,0.3,12],"NULL_DRAUGHT":[260,0.14,4],"SHIELD_DRAUGHT":[440,0.2,3],"GROUP_HEAL_DRAUGHT":[920,0.08,5],"ESSENCE_RESTORATION":[1030,0.12,6],"ESSENCE_BULWARK":[160,0.4,3]}
static var _lore: Dictionary = {}
static var _render_manifest: Dictionary = {}
static var _render_checked := false
static var _render_root := "res://assets/audio/m63_skill_renders/"
var _cache: Dictionary = {}
var _lru: Array[String] = []
var _pcm_bytes := 0
var _build_count := 0
var _native_count := 0

static func _lore_data() -> Dictionary:
	if _lore.is_empty():
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/m57-lore.json"))
		if parsed is Dictionary: _lore=parsed
	return _lore

static func describe(cue: Dictionary) -> Dictionary:
	var kind:=str(cue.get("kind",""))
	var hero:=str(cue.get("hero_archetype",""))
	var id:=str(cue.get("skill_id",""))
	var rank:=clampi(int(cue.get("rank",1)),1,3)
	var phase:=str(cue.get("sound_phase","CAST" if kind=="SKILL" else kind))
	var key:=hero+":"+id
	var brief:Dictionary=_lore_data().get("skills",{}).get(key,{})
	var skill:Dictionary=Heroes.skill_at_level(id,rank) if kind=="SKILL" and not id.is_empty() else {}
	var hero_index:=maxi(0,Heroes.ARCHETYPES.find(hero))
	var slot:int=Heroes.PROFILES.get(hero,{}).get("skill_ids",[]).find(id)
	var ultimate:=bool(cue.get("ultimate",skill.get("ultimate",false)))
	var fallback:=str({"grove_mender":"PAPER_WEAVE","ember_mender":"BONE_LANTERN","repair_drone":"CIRCUIT_TRACE","root_mender":"RAIN_THREAD","rune_keeper":"SLAG_CHUNK","spore_mender":"FUNGAL_MIST"}.get(str(cue.get("unit_type","")),"ECHO_BAND"))
	var mode:=str(brief.get("material_mode",cue.get("material_mode",fallback)))
	if mode not in MODES: mode="ECHO_BAND"
	var voice:Array=MODE_VOICES[mode]
	var attack_type:=str(cue.get("attack_type",skill.get("attack_type","ARCANE")))
	if attack_type not in ATTACK_VOICES:attack_type="ARCANE"
	var duration:=0.44+float(rank-1)*0.055+float((hero_index+maxi(slot,0))%4)*0.025
	if ultimate:duration=1.15+float(rank-1)*0.18+float(hero_index%5)*0.06
	if kind!="SKILL":
		voice=ATTACK_VOICES[attack_type]
		duration=0.18 if kind in ["ATTACK","ATTACK_RANGED","TOWER_FIRE"] else 0.3
		mode=attack_type if kind in ["ATTACK","ATTACK_RANGED","TOWER_FIRE","HIT"] else str(cue.get("status_kind",cue.get("item_id",kind)))
		if kind=="HEAL":voice=[730,0.08,3]
		elif kind=="CONTROL":voice=[180,0.4,3] if mode=="STUN" else [125,0.3,5] if mode=="ROOT" else [390,0.2,4]
		elif kind=="STATUS":voice=[110,0.6,4] if mode=="BURN" else [310,0.5,7] if mode=="POISON" else [720,0.3,5]
		elif kind=="BUFF":voice=[510,0.1,6]
		elif kind=="ITEM":voice=ITEM_VOICES.get(mode,[360,0.25,5])
		if str(cue.get("phase",""))=="END":duration=0.12;voice=[float(voice[0])*0.6,float(voice[1]),2]
	if phase=="IMPACT":duration=minf(duration,0.5 if ultimate else 0.28)
	var identity:=key+":"+str(rank)+":"+phase if kind=="SKILL" else kind+":"+mode+":"+str(cue.get("material",""))+":"+phase+":"+str(cue.get("phase","START"))
	var profile_id:=VERSION+":"+identity
	var entry:={"id":profile_id,"version":VERSION,"kind":kind,"hero_archetype":hero,"skill_id":id,"rank":rank,"ultimate":ultimate,"phase":phase,"material_mode":mode,"choreography":str(brief.get("choreography","short-response")),"motion_dialect":_motion_dialect(str(brief.get("particle_motion",""))),"visual_signature":str(brief.get("signature","")),"story_prompt":str(brief.get("prompt",brief.get("visual_brief",""))),"layers":["material_transient","named_body","semantic_grains","bounded_aftertone"],"layer_count":4,"seconds":minf(duration,2.2 if ultimate else 0.8),"frequency":float(voice[0]),"texture":float(voice[1]),"pulses":int(voice[2]),"hero_voice":hero_index,"skill_slot":maxi(slot,0),"attack_type":attack_type,"preview_only":bool(cue.get("preview_only",false)),"source":"ORIGINAL_LAYERED"}
	var authored:=FactionAV.sound_profile(cue) if kind in ["SKILL","ATTACK","ATTACK_RANGED","HEAL","HARVEST","MINE","BUILD"] else {}
	if not authored.is_empty():
		entry["voice"]=str(authored.get("voice","pluck"))
		entry["overtone"]=clampf(float(authored.get("overtone",1.5)),1.1,4)
		entry["sweep"]=clampf(float(authored.get("sweep",0)), -.8,.8)
		entry["echo"]=clampf(float(authored.get("echo",0)),0,.4)
		entry["frequency"]=clampf(float(authored.get("frequency",440)),70,1800)
		entry["texture"]=clampf(float(authored.get("texture",.3)),0,1)
		entry["pulses"]=clampi(int(authored.get("pulses",3)),1,12)
		entry["motion_dialect"]=str(authored.get("rhythm","woven_drift"))
		var seconds:=float(authored.get("seconds",.25))*(1+.08*(rank-1) if kind=="SKILL" else 1.0)
		if ultimate and not bool(skill.get("ultimate",false)):seconds*=1.8
		entry["seconds"]=clampf(seconds,.08,2.2 if ultimate else .8 if kind=="SKILL" else .4)
		if phase=="IMPACT":
			entry.seconds=minf(float(entry.seconds),.5 if ultimate else .28)
			entry.frequency*=.82;entry.pulses=maxi(1,int(entry.pulses)-1)
			entry.motion_dialect="falling_weight" if str(entry.voice) in ["rumble","clang","crack"] else "sharp_cut"
	# Authored lore/catalogue changes need not edit this renderer. Bind both
	# bundled receipts and the live LRU to actual acoustics, not only hero/slot.
	entry["acoustic_fingerprint"]=acoustic_fingerprint(entry)
	entry["id"]=profile_id+":"+str(entry.acoustic_fingerprint)
	return entry

static func acoustic_fingerprint(entry:Dictionary)->String:
	var values:Array=[]
	# Fixed ordered array avoids Dictionary insertion-order and excludes
	# observer markers (preview_only/force_compose/entity/tick) and prose.
	for field:String in ["version","kind","rank","ultimate","phase","material_mode","choreography","motion_dialect","seconds","frequency","texture","pulses","hero_voice","skill_slot","attack_type","voice","overtone","sweep","echo"]:
		values.append([field,entry.get(field)])
	return JSON.stringify(values).sha256_text().substr(0,24)

static func _motion_dialect(motion:String)->String:
	match motion:
		"close","hold","lock","clamp","prison","tighten","pledge","bind","seal":return "gather_and_lock"
		"return","extract","collapse","in","reseal":return "inward_return"
		"fall","drop","downbeat","settle":return "falling_weight"
		"fan","open","unroll","crosswake":return "opening_fan"
		"line","travel","march","dock","pierce","puncture":return "directional_rush"
		"breathe","exhale","relight","temper","shelter","rest","supply","coexist","song","chorus","flow","rise","smolder":return "breathing_lift"
		"snap","cut","execute","verdict","breach","fracture","discharge","thunder":return "sharp_cut"
		"double","reprise","relay","cadence","switchyard","overclock","offbeat":return "staggered_reprise"
		_:return "woven_drift"

static func _rhythm_envelope(x:float,dialect:String)->float:
	match dialect:
		"gather_and_lock":return 0.2+0.8*smoothstep(0.2,0.4,x)
		"inward_return":return 0.35+0.45*x+0.3*exp(-absf(x-0.7)*18)
		"falling_weight":return 0.2+0.8*exp(-fposmod(x+0.08,0.27)*17)
		"opening_fan":return 0.2+0.8*pow(maxf(0.0,sin(PI*x)),0.65)
		"directional_rush":return 0.25+0.75*exp(-x*4)+0.35*exp(-absf(x-0.65)*22)
		"breathing_lift":return 0.3+0.7*pow(maxf(0.0,sin(PI*x)),0.4)
		"sharp_cut":return 0.12+0.88*exp(-x*12)+0.5*exp(-absf(x-0.44)*32)
		"staggered_reprise":return 0.15+0.85*exp(-fposmod(x,0.31)*18)
		_:return 0.65+0.25*sin(x*TAU*2.5)

static func catalogue() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for hero:String in Heroes.ARCHETYPES:
		for id:String in Heroes.PROFILES[hero].skill_ids:
			var first:=Heroes.skill_at_level(id,1)
			if bool(first.get("passive",false)):continue
			for rank:int in range(1,int(first.max_level)+1):result.append(describe({"kind":"SKILL","hero_archetype":hero,"skill_id":id,"rank":rank}))
	return result

func resolve(cue:Dictionary,foley:AudioStreamWAV=null)->Dictionary:
	var entry:=describe(cue)
	var id:=str(entry.id)+("+cc0" if foley!=null else "")
	if not _cache.has(id):
		var wave:AudioStreamWAV=null
		if not bool(cue.get("force_compose",false)):wave=_native_render(entry)
		if wave!=null:_native_count+=1
		if wave==null:wave=_compose(entry,foley)
		while not _lru.is_empty() and (_cache.size()>=MAX_CACHE_ENTRIES or _pcm_bytes+wave.data.size()>MAX_PCM_BYTES):
			var oldest:String=_lru.pop_front()
			_pcm_bytes-=int(_cache[oldest].data.size())
			_cache.erase(oldest)
		_cache[id]=wave
		_pcm_bytes+=wave.data.size()
		_build_count+=1
	_lru.erase(id)
	_lru.append(id)
	var result:=entry.duplicate(true)
	result.merge({"stream":_cache[id],"gain":0.74 if bool(entry.ultimate) else 0.64,"asset_id":id,"path":"","source":"ORIGINAL_LAYERED_CC0" if foley!=null else "ORIGINAL_LAYERED"},true)
	# Preserve the supplied physical classification for existing observers and
	# player metadata. It is not a second sound recipe or a gameplay property.
	result["material"]=str(cue.get("material",""))
	return result

static func render_filename(entry:Dictionary)->String:
	if entry.kind=="SKILL" and str(entry.hero_archetype) in Heroes.ARCHETYPES:
		return (str(entry.hero_archetype)+"--"+str(entry.skill_id)+"--r"+str(entry.rank)+("--impact" if entry.phase=="IMPACT" else "")).to_lower()+".wav"
	return ("cue--"+str(entry.kind)+"--"+str(entry.material_mode)+"--"+str(entry.phase)+"--"+str(entry.acoustic_fingerprint)).to_lower().validate_filename()+".wav"

static func _native_render(entry:Dictionary)->AudioStreamWAV:
	if not _render_checked:
		_render_checked=true
		var path:=_render_root+"manifest.json"
		if FileAccess.file_exists(path):
			var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary and parsed.get("accepted",false) and parsed.get("recipe_version","")==VERSION:
				var script_path:="res://src/presentation/hero_skill_audio.gd"
				if not FileAccess.file_exists(script_path) or FileAccess.get_sha256(script_path)==parsed.get("renderer_sha256",""):_render_manifest=parsed
	var name:=render_filename(entry)
	var receipt:Dictionary=_render_manifest.get("files",{}).get(name,{})
	if receipt.get("recipe_id","")!=entry.id:return null
	var path:=_render_root+name
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=receipt.get("sha256",""):return null
	var wave:=AudioStreamWAV.load_from_file(path)
	if wave==null or wave.stereo or wave.mix_rate!=RATE or wave.format!=AudioStreamWAV.FORMAT_16_BITS or wave.get_length()>float(entry.seconds)+0.001:return null
	return wave

func diagnostics()->Dictionary:
	return {"skill_stream_cache_count":_cache.size(),"skill_pcm_bytes":_pcm_bytes,"skill_stream_builds":_build_count,"skill_native_render_hits":_native_count,"skill_synthesis_builds":_build_count-_native_count,"skill_cache_entry_limit":MAX_CACHE_ENTRIES,"skill_pcm_limit":MAX_PCM_BYTES}

func clear()->void:
	_cache.clear();_lru.clear();_pcm_bytes=0

static func _compose(entry:Dictionary,foley:AudioStreamWAV)->AudioStreamWAV:
	var duration:=float(entry.seconds)
	var count:=ceili(duration*RATE)
	var mono:=PackedFloat32Array();mono.resize(count)
	var f:=float(entry.frequency)*(1.0+float(int(entry.hero_voice)%7)*0.026+float(entry.skill_slot)*0.018+float(int(entry.rank)-1)*0.035)
	var texture:=float(entry.texture)
	var pulses:=int(entry.pulses)+int(entry.skill_slot)%3
	var state:int=str(entry.id).sha256_text().substr(0,8).hex_to_int()&0x7fffffff
	var peak:=0.001
	var mode:=str(entry.material_mode)
	var dialect:=str(entry.get("motion_dialect","woven_drift"))
	var authored_voice:=str(entry.get("voice",""))
	var overtone:=float(entry.get("overtone",1.5))
	var sweep:=float(entry.get("sweep",0))
	var echo:=float(entry.get("echo",0))
	var echo_delay:=roundi(RATE*(.035+.008*float(pulses%5)))
	for index:int in range(count):
		var t:=float(index)/RATE
		var x:=t/duration
		state=(state*1103515245+12345)&0x7fffffff
		var noise:=float(state)/1073741824.0-1.0
		var carrier:=TAU*f*t
		var attack:=minf(1.0,t/0.006)
		var release:=clampf((duration-t)/0.055,0,1)
		var grains:=pow(maxf(0.0,sin(x*TAU*pulses)),3)
		var body:=sin(carrier*(1.0+0.12*sin(t*TAU*(3+int(entry.skill_slot)))))
		match mode:
			"PAPER_WEAVE":body=noise*0.45+sin(carrier)*0.35;grains=pow(absf(sin(t*TAU*13)),5)
			"INK_SEAL":body=sin(carrier*exp(-t*2.0))+sin(carrier*0.5)*0.3;grains=1.0 if x<0.12 or (x>0.34 and x<0.43) else 0.1
			"GLASS_REFRACTION":body=sin(carrier)*exp(-t*4)+sin(carrier*2.71)*exp(-t*7)*0.6
			"GHOST_AFTERIMAGE":body=(sin(carrier)+sin(carrier*1.013))*0.5;grains=sin(PI*x)*0.7+0.3
			"ASH_RIBBON":body=noise*(0.5+sin(t*TAU*3)*0.2)+sin(carrier)*0.2
			"BONE_LANTERN":body=sin(carrier)*exp(-fposmod(t,0.13)*22)+sin(carrier*1.49)*0.4
			"PRESSURE_SMOKE":body=noise*(1.0-x)*0.55+sin(carrier*(1-x*0.5))*0.45
			"RIVET_SPARK":body=noise*grains+sin(carrier*2.73)*exp(-t*12)*0.5
			"CIRCUIT_TRACE":body=sin(carrier*(1.0+floorf(x*5)*0.25))*0.65+sin(carrier*2)*0.2;grains=0.3 if fposmod(x*12,1.0)>0.45 else 1.0
			"PETAL_SWARM":body=sin(carrier*(1+x*0.3))*0.65+sin(carrier*1.5)*0.2;grains=pow(absf(sin(t*TAU*6)),2)
			"ROOT_EARTH":body=sin(carrier*(1-x*0.25))*0.65+noise*0.3;grains=pow(absf(sin(t*TAU*4)),4)
			"RAIN_THREAD":body=noise*0.3+sin(carrier*(1+x*0.6))*0.5;grains=pow(absf(sin(t*TAU*19)),6)
			"SLAG_CHUNK":body=(sin(carrier)+sin(carrier*0.51)*0.6)*0.6+noise*0.4;grains=exp(-fposmod(t,0.19)*17)
			"STONE_STRATA":body=sin(carrier*(1-floorf(x*4)*0.11))*0.5+noise*0.5;grains=exp(-fposmod(t,0.15)*20)
			"HEAT_VEIL":body=noise*0.32+sin(carrier+sin(carrier*0.03)*2)*0.5
			"FUNGAL_MIST":body=sin(carrier*(1-x*0.17))*0.3+noise*0.45;grains=pow(absf(sin(t*TAU*8)),3)
			"CRYSTAL_DUST":body=sin(carrier)*exp(-t*6)+sin(carrier*3.17)*0.4;grains=pow(absf(sin(t*TAU*15)),4)
			"ECHO_BAND":body=sin(carrier)+sin(carrier*1.333)*0.3;grains=exp(-fposmod(t,0.21)*10)
			"GUNPOWDER":body=noise*exp(-t*25)+sin(carrier*(1-x*0.5))*0.5
			"IMPACT":body=sin(carrier*(1-x*0.45))*exp(-t*14)+noise*exp(-t*32)*0.35
			"EDGE":body=noise*sin(PI*x)+sin(carrier*(1-x*0.6))*0.15
			"PIERCE":body=sin(carrier*(1-x*0.65))*0.4+noise*exp(-t*24)*0.4
			"ARCANE":body=sin(carrier*(1+x*0.5))*0.65+sin(carrier*1.51)*0.25
			"CHAOS":body=sin(carrier)*0.4+sin(carrier*1.41)*0.3+noise*0.45
		# Named actor/skill material is an actual oscillator and energy-envelope
		# choice, not merely a different filename, pitch or random-noise seed.
		if not authored_voice.is_empty():
			var c:=carrier*(1+sweep*x*.5)
			var harmonic:=sin(c*overtone)
			match authored_voice:
				"pluck":body=(sin(c)+harmonic*.35)*exp(-x*6);grains=.4+.6*exp(-fposmod(x*pulses,1.0)*10)
				"bell":body=(sin(c)+harmonic*.65+sin(c*2.71)*.2)*exp(-x*3.2);grains=.7+.3*exp(-fposmod(x*pulses,1.0)*8)
				"reed":body=sin(c)*.6+sin(c*3)*.15+harmonic*.2;grains=sin(PI*x)*(.7+.3*sin(x*TAU*pulses))
				"breath":body=noise*.6+sin(c)*.12+harmonic*.055;grains=pow(maxf(0,sin(PI*x)),.4)
				"scrape":body=noise*(.25+.75*absf(sin(c*.043)))+harmonic*.16;grains=.2+.8*x
				"click":body=noise*.7+sin(c)*.3+harmonic*.09;grains=exp(-fposmod(x*pulses,1.0)*24)
				"rumble":body=sin(c*.5)*.7+sin(c)*.25+noise*.18+harmonic*.1;grains=sin(PI*x)*(.6+.4*sin(x*TAU*pulses))
				"crack":body=noise*exp(-x*14)*.8+sin(c)*exp(-x*5)*.4+harmonic*exp(-x*8)*.1;grains=1.0 if x<.18 else .12
				"choir":body=(sin(c)+sin(c*1.012)+harmonic*.5)/2.5;grains=pow(maxf(0,sin(PI*x)),.5)
				"water":body=sin(c*(1+.4*sin(x*TAU*pulses)))*.5+noise*.12+harmonic*.08;grains=exp(-fposmod(x*pulses,1.0)*7)
				"buzz":body=sin(c)*.45+sin(c*2)*.25+harmonic*.2;grains=.4+.6*pow(absf(sin(x*TAU*pulses)),3)
				"clang":body=sin(c)*.5+sin(c*1.53)*.35+harmonic*.3+noise*exp(-x*20)*.4;grains=exp(-x*4)
			body*=1-echo*.35
		var transient:=noise*texture*exp(-t*(42 if bool(entry.ultimate) else 65))*0.35
		var named_body:=body*exp(-x*3.0)*0.52
		var grain_layer:=body*grains*sin(PI*x)*0.22
		var tail:=sin(carrier*0.5+sin(t*9))*exp(-x*5)*0.12 if bool(entry.ultimate) else sin(carrier*1.25)*exp(-x*8)*0.06
		if foley!=null:transient=float(foley.data.decode_s16(index*2))/32767.0*0.34 if index*2+1<foley.data.size() else 0.0
		var value:float=(transient+named_body+grain_layer+tail)*attack*release*_rhythm_envelope(x,dialect)
		if echo>0 and index>=echo_delay:value+=mono[index-echo_delay]*echo*.45*release
		mono[index]=value;peak=maxf(peak,absf(value))
	var data:=PackedByteArray();data.resize(count*2)
	for index:int in range(count):data.encode_s16(index*2,roundi(mono[index]*0.36/peak*32767))
	var wave:=AudioStreamWAV.new();wave.format=AudioStreamWAV.FORMAT_16_BITS;wave.mix_rate=RATE;wave.stereo=false;wave.loop_mode=AudioStreamWAV.LOOP_DISABLED;wave.data=data
	return wave
