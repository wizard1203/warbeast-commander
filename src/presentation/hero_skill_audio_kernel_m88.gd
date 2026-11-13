extends RefCounted
const RATE := 22050

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
	# Immutable local PCM copy for this synchronous complete composition.
	var foley_pcm: PackedByteArray=foley.data if foley!=null else PackedByteArray()
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
		if foley!=null:transient=float(foley_pcm.decode_s16(index*2))/32767.0*0.34 if index*2+1<foley_pcm.size() else 0.0
		var value:float=(transient+named_body+grain_layer+tail)*attack*release*_rhythm_envelope(x,dialect)
		if echo>0 and index>=echo_delay:value+=mono[index-echo_delay]*echo*.45*release
		mono[index]=value;peak=maxf(peak,absf(value))
	var data:=PackedByteArray();data.resize(count*2)
	for index:int in range(count):data.encode_s16(index*2,roundi(mono[index]*0.36/peak*32767))
	var wave:=AudioStreamWAV.new();wave.format=AudioStreamWAV.FORMAT_16_BITS;wave.mix_rate=RATE;wave.stereo=false;wave.loop_mode=AudioStreamWAV.LOOP_DISABLED;wave.data=data
	return wave
