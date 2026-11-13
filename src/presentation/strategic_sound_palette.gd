extends RefCounted
## A bounded local material palette, not a game event source. The caller owns
## admission, visibility, cooldowns, voices and original fallback generation.
## No network, simulation reference, global bus or gameplay RNG is used here.
const SAMPLE_RATE := 22050
const SkillAudio = preload("res://src/presentation/hero_skill_audio_runtime_m90.gd")
const SAMPLE_FILES := {
	"harvest":"kenney_rpg_audio/chop.wav",
	"blade_a":"kenney_rpg_audio/knifeSlice.wav",
	"blade_b":"kenney_rpg_audio/knifeSlice2.wav",
	"mine_a":"kenney_impact_sounds/impactMining_000.wav",
	"mine_b":"kenney_impact_sounds/impactMining_001.wav",
	"build_a":"kenney_impact_sounds/impactPlank_medium_000.wav",
	"build_b":"kenney_impact_sounds/impactPlank_medium_001.wav",
	"step_a":"kenney_impact_sounds/footstep_grass_000.wav",
	"step_b":"kenney_impact_sounds/footstep_grass_001.wav",
	"mechanical":"kenney_impact_sounds/impactMetal_light_000.wav",
	"paper":"m58_kenney_rpg_audio/bookFlip1.wav",
	"cloth":"m58_kenney_rpg_audio/cloth2.wav",
	"latch":"m58_kenney_rpg_audio/metalClick.wav",
	"bell":"m58_kenney_impact_sounds/impactBell_heavy_000.wav",
	"glass":"m58_kenney_impact_sounds/impactGlass_light_000.wav",
	"thump":"m58_kenney_impact_sounds/impactPunch_heavy_000.wav",
	"wood":"m58_kenney_impact_sounds/impactWood_heavy_000.wav",
	"anvil":"m58_kenney_impact_sounds/impactMetal_heavy_000.wav",
	"crunch":"m58_kenney_sci_fi/explosionCrunch_000.wav",
	"field":"m58_kenney_sci_fi/forceField_000.wav",
	"circuit":"m58_kenney_sci_fi/laserRetro_000.wav",
	"needle":"m58_kenney_sci_fi/laserSmall_000.wav",
	"pressure":"m58_kenney_sci_fi/lowFrequency_explosion_000.wav",
	"spore":"m58_kenney_sci_fi/slime_000.wav",
}
const MODE_FOLEY := {"PAPER_WEAVE":"paper","INK_SEAL":"latch","GLASS_REFRACTION":"glass","GHOST_AFTERIMAGE":"cloth","ASH_RIBBON":"cloth","BONE_LANTERN":"bell","PRESSURE_SMOKE":"pressure","RIVET_SPARK":"anvil","CIRCUIT_TRACE":"circuit","PETAL_SWARM":"cloth","ROOT_EARTH":"wood","RAIN_THREAD":"glass","SLAG_CHUNK":"crunch","STONE_STRATA":"thump","HEAT_VEIL":"field","FUNGAL_MIST":"spore","CRYSTAL_DUST":"glass","ECHO_BAND":"bell"}
const MATERIAL_PROFILES := {
	"ARROW":[1100.0,290.0,0.060,0.4],
	"MECHANICAL":[240.0,90.0,0.085,0.85],
	"FIRE":[180.0,110.0,0.140,0.95],
	"MAGIC":[480.0,1120.0,0.130,0.25],
}
var _asset_root: String
var _samples: Dictionary = {}
var _original_materials: Dictionary = {}
var _skill_audio := SkillAudio.new()

func _init(asset_root: String = "res://assets/audio/") -> void:
	_asset_root = asset_root

func resolve(cue: Dictionary, original_fallback: AudioStreamWAV) -> Dictionary:
	var kind := str(cue.get("kind", ""))
	if kind in ["HARVEST","MINE","BUILD"] and str(cue.get("unit_type",""))=="worker" and not str(cue.get("faction_id","")).is_empty():
		return _skill_audio.resolve(cue,_sample("harvest" if kind=="HARVEST" else "mine_a" if kind=="MINE" else "build_a"))
	if kind=="SKILL" and not str(cue.get("skill_id","")).is_empty():
		var recipe:=SkillAudio.describe(cue)
		return _skill_audio.resolve(cue,_sample(str(MODE_FOLEY.get(recipe.material_mode,"field"))))
	if kind in ["HIT","CONTROL","STATUS","BUFF","ITEM"] or (kind in ["ATTACK","ATTACK_RANGED","TOWER_FIRE","HEAL"] and cue.has("attack_type")):
		var chosen:=str({"GUNPOWDER":"crunch","IMPACT":"thump","EDGE":"blade_a","PIERCE":"needle","ARCANE":"field","CHAOS":"pressure"}.get(str(cue.get("attack_type","ARCANE")),"field"))
		if kind in ["CONTROL","STATUS"]:chosen=str({"STUN":"anvil","ROOT":"wood","SLOW":"cloth","BURN":"crunch","POISON":"spore","ARMOR_BREAK":"latch"}.get(str(cue.get("status_kind","")),"field"))
		elif kind in ["HEAL","BUFF","ITEM"]:chosen="glass" if "MANA" in str(cue.get("item_id","")) else "bell" if kind=="HEAL" else "latch"
		return _skill_audio.resolve(cue,_sample(chosen))
	var material := str(cue.get("material", "MELEE" if kind == "ATTACK" else "ARROW" if kind in ["ATTACK_RANGED", "TOWER_FIRE"] else ""))
	var options: Array[String] = []
	var gain := 1.0
	match kind:
		"HARVEST": options.assign(["harvest"]); gain = 0.38
		"MINE": options.assign(["mine_a", "mine_b"]); gain = 0.42
		"BUILD": options.assign(["build_a", "build_b"]); gain = 0.42
		"MOVE": options.assign(["step_a", "step_b"]); gain = 0.24
		"ATTACK", "ATTACK_RANGED":
			if material == "MELEE": options.assign(["blade_a", "blade_b"]); gain = 0.52
			elif material == "MECHANICAL": options.assign(["mechanical"]); gain = 0.42
	# A stable event choice, independent of playback order or simulation RNG.
	if not options.is_empty():
		var identity := "%s:%s:%d" % [kind,str(cue.get("entity_id", "")),int(cue.get("tick", -1))]
		# Hash the complete event rather than taking the parity of String.hash:
		# correlated entity/tick suffixes can otherwise always select one of two.
		var variant_seed := identity.sha256_text().substr(0, 8).hex_to_int()
		var asset_id := options[posmod(variant_seed, options.size())]
		var sample := _sample(asset_id)
		if sample != null:
			return {"stream":sample, "gain":gain, "material":material, "source":"KENNEY_CC0", "asset_id":asset_id, "path":_asset_root.path_join(str(SAMPLE_FILES[asset_id]))}
	if kind in ["ATTACK", "ATTACK_RANGED", "TOWER_FIRE"] and MATERIAL_PROFILES.has(material):
		if not _original_materials.has(material): _original_materials[material] = _make_material(material)
		return {"stream":_original_materials[material], "gain":1.0, "material":material, "source":"ORIGINAL_MATERIAL", "asset_id":"original:" + material.to_lower(), "path":""}
	return {"stream":original_fallback, "gain":1.0, "material":material, "source":"ORIGINAL_FALLBACK", "asset_id":"original:" + kind.to_lower(), "path":""}

func diagnostics() -> Dictionary:
	var loaded := 0
	var bytes := 0
	for wave: Variant in _samples.values():
		if wave is AudioStreamWAV:
			loaded += 1
			bytes += wave.data.size()
	var result:={"sample_cache_count":_samples.size(), "loaded_sample_count":loaded, "sample_pcm_bytes":bytes, "original_material_count":_original_materials.size()}
	result.merge(_skill_audio.diagnostics())
	return result

func clear() -> void:
	_samples.clear()
	_original_materials.clear()
	_skill_audio.clear()

func _sample(asset_id: String) -> AudioStreamWAV:
	if not SAMPLE_FILES.has(asset_id): return null
	if _samples.has(asset_id): return _samples[asset_id]
	var path := _asset_root.path_join(str(SAMPLE_FILES[asset_id]))
	var wave: AudioStreamWAV = null
	# Raw WAV loading works in the first headless run without .godot imports.
	# Exported projects may instead contain only a valid imported resource.
	if FileAccess.file_exists(path): wave = AudioStreamWAV.load_from_file(path)
	elif ResourceLoader.exists(path): wave = ResourceLoader.load(path) as AudioStreamWAV
	if wave != null and (wave.get_length() <= 0.02 or wave.get_length() > 0.321 or wave.stereo or wave.mix_rate != SAMPLE_RATE or wave.format != AudioStreamWAV.FORMAT_16_BITS): wave = null
	_samples[asset_id] = wave # Cache absence too; retries cannot become I/O spam.
	return wave

func _make_material(material: String) -> AudioStreamWAV:
	var profile: Array = MATERIAL_PROFILES[material]
	var duration := float(profile[2])
	var frames := int(ceil(duration * SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(frames * 2)
	for index: int in range(frames):
		var time := float(index) / SAMPLE_RATE
		var phase := TAU * (float(profile[0]) * time + (float(profile[1]) - float(profile[0])) * time * time / (2.0 * duration))
		var texture := float(profile[3])
		var wave := (sin(phase) + texture * 0.35 * sin(phase * 2.37) + texture * 0.17 * sin(phase * 4.11)) / (1.0 + texture * 0.52)
		var envelope := sin(PI * float(index) / maxf(float(frames - 1), 1.0))
		data.encode_s16(index * 2, int(round(wave * envelope * 0.22 * 32767.0)))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = SAMPLE_RATE
	result.stereo = false
	result.loop_mode = AudioStreamWAV.LOOP_DISABLED
	result.data = data
	return result
