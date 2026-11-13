extends SceneTree
## Independent first-release admission and actual UI-selector fixtures.
## The coordinator alone executes engines. This suite does not advance combat.
const Factions = preload("res://src/simulation/strategic_faction_catalog.gd")
const Matches = preload("res://src/simulation/strategic_match_catalog.gd")
const Runner = preload("res://src/simulation/strategic_hero_arena_runner.gd")
const Budget = preload("res://src/simulation/strategic_arena_budget_preset.gd")
const Units = preload("res://src/simulation/strategic_unit_catalog.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const Tech = preload("res://src/simulation/strategic_faction_technologies_v4.gd")
const Catalog = preload("res://src/presentation/strategic_pregame_catalog.gd")
const Lobby = preload("res://src/presentation/strategic_lobby.gd")
const Arena = preload("res://src/presentation/strategic_hero_arena.gd")
const Inputs = preload("res://tools/release_media/scenario_inputs.gd")
const MainView = preload("res://src/presentation/strategic_arena.gd")
const PLAYABLE := ["HUMAN","MACHINE","FOREST"]
const EXCLUDED := {"UNDEAD":{"hero":"ASH_MARSHAL","troop":"ash_guard"},"HIGHLAND":{"hero":"RIDGE_JARL","troop":"ridge_guard"},"UNDERGROUND":{"hero":"TUNNEL_SENTINEL","troop":"chitin_guard"}}
var output := ""
var checks := 0
var failures: Array[String] = []
var cases: Array[Dictionary] = []

func _initialize() -> void: call_deferred("_run")

func ck(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--json="): output=arg.trim_prefix("--json=")
		else: printerr("Unknown first-release check argument: "+arg); quit(2); return
	if not output.is_absolute_path() or FileAccess.file_exists(output):
		printerr("Require fresh absolute --json path"); quit(2); return
	var before := _pins()
	_catalog_admission()
	_match_admission()
	_arena_admission()
	_random_configuration()
	_json_admission()
	_media_scenarios()
	_main_helpers()
	await _actual_selectors()
	var after := _pins()
	ck(before==after,"evaluation leaves its source closure unchanged")
	var report := {"schema":"first-release.independent-gates/v1","accepted":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases,"source_before":before,"source_after":after,"scope":"Actual catalog, admission and instantiated lobby/guide/arena selector fixtures. Real Runner initial installation and atomic rejection, no combat advancement. Not native layout, physical input, full old-suite regression, natural economy, balance, audio, media, FPS, mobile or publication qualification."}
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output,FileAccess.WRITE)
	if file==null: printerr("Cannot create first-release report"); quit(2); return
	file.store_string(JSON.stringify(report,"\t")+"\n"); file.close()
	print("[FIRST RELEASE INDEPENDENT] "+JSON.stringify({"accepted":report.accepted,"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func _catalog_admission() -> void:
	ck(Array(Factions.IDS)==PLAYABLE,"Factions.IDS exposes exactly HUMAN/MACHINE/FOREST")
	ck(Array(Matches.FACTIONS)==PLAYABLE,"Matches.FACTIONS agrees with playable faction order")
	ck(Factions.get_catalog().size()==3,"faction profiles expose exactly three selectable factions")
	var troop_ids := {}; var hero_ids := {}; var technologies := 0
	for faction: String in PLAYABLE:
		ck(Factions.is_valid(faction),faction+": playable admission")
		ck(Factions.units_for(faction).size()==7,faction+": seven regular troops")
		ck(Factions.heroes_for(faction).size()==8,faction+": eight heroes")
		ck(Tech.list_for(faction).size()==4,faction+": four unchanged faction technologies")
		technologies+=Tech.list_for(faction).size()
		for id: String in Factions.units_for(faction):
			troop_ids[id]=true
			ck(str(Units.profile(id).get("faction_id",""))==faction and Units.is_recruitable(id),id+": real recruitable recipe belongs to its faction")
		for id: String in Factions.heroes_for(faction):
			hero_ids[id]=true
			ck(str(Heroes.profile(id).get("faction_id",""))==faction,id+": real hero belongs to its faction")
		ck(_entry_ids(Catalog.entries(faction,"TROOPS"))==_sorted(Factions.units_for(faction)),faction+": guide troop projection agrees")
		ck(_entry_ids(Catalog.entries(faction,"HEROES"))==_sorted(Factions.heroes_for(faction)),faction+": guide hero projection agrees")
	ck(troop_ids.size()==21 and hero_ids.size()==24 and technologies==12,"playable totals are 3 factions, 21 troops, 24 heroes and 12 technologies")
	var arena_catalog := Runner.catalog()
	ck(arena_catalog.factions.size()==3 and arena_catalog.heroes.size()==24 and arena_catalog.units.size()==21,"Runner selectable catalog exposes 3/24/21")
	ck(_entry_ids(arena_catalog.heroes)==_sorted(hero_ids.keys()),"Runner hero IDs match actual faction roster")
	ck(_sorted(arena_catalog.units.keys())==_sorted(troop_ids.keys()),"Runner troop IDs match actual faction roster")
	for faction: String in EXCLUDED:
		ck(not Factions.is_valid(faction) and not Factions.get_catalog().has(faction),faction+": not playable")
		ck(Factions.heroes_for(faction).is_empty() and Factions.units_for(faction).is_empty(),faction+": hidden roster is not selectable through helpers")
		for category: String in ["IDENTITY","TROOPS","HEROES","BUILDINGS","TECH","ITEMS","NEUTRALS","COMBAT","ECONOMY"]:
			ck(Catalog.entries(faction,category).is_empty(),faction+":"+category+": guide cannot bypass admission")
		ck(Heroes.ARCHETYPES.has(str(EXCLUDED[faction].hero)) and Units.UNITS.has(str(EXCLUDED[faction].troop)),faction+": shared full content definitions retained internally")
	cases.append({"kind":"catalog","factions":3,"troops":troop_ids.size(),"heroes":hero_ids.size(),"technologies":technologies})

func _participant(faction: String, controller: String = "AI") -> Dictionary:
	return {"faction_id":faction,"controller":controller,"difficulty_id":"HARD"}

func _match_admission() -> void:
	ck(bool(Matches.resolve(Matches.default_request()).accepted),"ordinary default request remains legal")
	ck(Array(Matches.get_catalog().factions)==PLAYABLE,"ordinary public catalog exposes only three factions")
	for left: String in PLAYABLE:
		for right: String in PLAYABLE:
			var request := {"map_id":"borderlands","participants":[_participant(left),_participant(right)]}
			var result := Matches.resolve(request)
			ck(bool(result.accepted),left+"/"+right+": ordinary pair accepted")
			if bool(result.accepted):
				ck(result.match_config.initial_state=={"stock":{"FOOD":0,"MATERIAL":650,"ESSENCE":0},"base_tier":1,"buildings":["BASE","BARRACKS","RANGE"]},"ordinary setup preserves normal R20 starting stock/tier/buildings")
	for faction: String in EXCLUDED:
		var request := {"map_id":"borderlands","participants":[_participant("HUMAN"),_participant(faction)]}
		ck(not bool(Matches.resolve(request).accepted),faction+": explicit ordinary faction rejected")
		request.participants[1]=_participant("MACHINE")
		request.participants[1]["starting_hero"]=EXCLUDED[faction].hero
		ck(not bool(Matches.resolve(request).accepted),str(EXCLUDED[faction].hero)+": excluded starting hero rejected")
	cases.append({"kind":"ordinary-admission","legal_pairs":9,"excluded_factions":3,"excluded_heroes":3})

func _arena_admission() -> void:
	for mode: String in Runner.MODES:
		ck(bool(Runner.validate(Runner.preset(mode)).accepted),mode+": current preset defaults legal")
	var setup := Runner.preset("MIXED","HUMAN","MACHINE")
	var runner := Runner.new()
	ck(bool(runner.configure(setup).accepted),"actual Runner installs legal mixed configuration")
	var baseline := runner.state_hash()
	for faction: String in EXCLUDED:
		var bad := setup.duplicate(true)
		bad.sides.AI.faction_id=faction
		ck(not bool(Runner.validate(bad).accepted),faction+": explicit arena faction rejected")
		ck(not bool(runner.configure(bad).accepted) and runner.state_hash()==baseline,faction+": failed configure preserves actual combat state")
		bad=setup.duplicate(true)
		bad.sides.AI.heroes[0].archetype=EXCLUDED[faction].hero
		ck(not bool(Runner.validate(bad).accepted),str(EXCLUDED[faction].hero)+": excluded arena hero rejected")
		bad=setup.duplicate(true)
		bad.sides.AI.troops=[{"unit_type":EXCLUDED[faction].troop,"count":1}]
		ck(not bool(Runner.validate(bad).accepted),str(EXCLUDED[faction].troop)+": excluded arena troop rejected")
	ck(runner.snapshot().arena.elapsed_ticks==0,"admission checks do not advance the battle")
	cases.append({"kind":"arena-admission","default_modes":Runner.MODES.size(),"excluded_factions":3,"excluded_heroes":3,"excluded_troops":3,"elapsed_ticks":0})

func _random_configuration() -> void:
	var seen := {}
	for seed: int in range(128):
		for side: String in Runner.SIDES:
			var faction := Arena.random_budget_faction(side,seed)
			ck(faction in PLAYABLE,"random side selection cannot expose excluded faction")
			seen[faction]=true
	ck(seen.size()==3,"deterministic random sample reaches all three factions")
	ck(bool(Runner.validate(Runner.random_trio_preset(20261112)).accepted),"random trio defaults legal")
	for faction: String in PLAYABLE:
		var generated := Budget.generate(20261112,faction,faction)
		ck(bool(generated.accepted),faction+": random budget fixture generates")
		if bool(generated.accepted): ck(bool(Runner.validate(generated.config).accepted),faction+": generated budget fixture admitted by actual Runner")
	for faction: String in EXCLUDED:
		ck(not bool(Budget.generate(20261112,"HUMAN",faction).accepted),faction+": excluded budget generator input denied")
	cases.append({"kind":"random-configuration","seeds":128,"sampled_factions":seen.keys()})

func _actual_selectors() -> void:
	root.size=Vector2i(1280,800); root.content_scale_size=root.size
	var lobby := Lobby.new()
	root.add_child(lobby)
	var configured := Matches.resolve({"map_id":"river-crossroads","participants":[_participant("HUMAN","HUMAN"),_participant("MACHINE"),_participant("FOREST")]})
	ck(bool(configured.accepted),"three-faction ordinary fixture accepted")
	if bool(configured.accepted): lobby.refresh(Matches.get_catalog(),configured.match_config)
	await process_frame
	for index: int in range(3):
		ck(_option_ids(lobby.find_child("LobbyFaction_%d"%index,true,false))==_sorted(PLAYABLE),"actual lobby faction selector "+str(index)+" exposes only three")
		ck(_option_ids(lobby.find_child("LobbyStartingHero_%d"%index,true,false))==_sorted(Factions.heroes_for(PLAYABLE[index])),"actual lobby starting hero selector "+str(index)+" exposes eight matching heroes")
	var guide: Control=lobby.get("_field_guide")
	guide.call("open_for_faction","HUMAN","TROOPS")
	ck(guide.visible,"actual guide opens")
	ck(_option_ids(guide.find_child("PregameGuideFaction",true,false))==_sorted(PLAYABLE),"actual guide faction selector exposes exactly three")
	var arena := Arena.new()
	root.add_child(arena)
	await process_frame
	ck(_option_ids(arena.find_child("ArenaFaction",true,false))==_sorted(PLAYABLE),"actual arena faction selector exposes exactly three")
	ck(bool(Runner.validate(arena.get("_config")).accepted),"actual arena initial configuration uses legal current defaults")
	arena.set_process(false)
	root.remove_child(arena); arena.queue_free()
	root.remove_child(lobby); lobby.queue_free()
	await process_frame
	cases.append({"kind":"instantiated-selectors","lobby_sides":3,"guide_factions":3,"arena_factions":3,"scope":"actual nodes and selection metadata, not native screenshots or physical input"})

func _media_scenarios() -> void:
	var file := FileAccess.open("res://media/first-release-20261112/scenarios.json",FileAccess.READ)
	ck(file!=null,"frozen media scenario file exists")
	if file==null: return
	var parsed: Variant=JSON.parse_string(file.get_as_text()); file.close()
	ck(parsed is Dictionary and parsed.get("scenes") is Array,"frozen media plan is parseable")
	if not parsed is Dictionary or not parsed.get("scenes") is Array: return
	ck(parsed.scenes.size()==6,"media plan contains six arena scenes")
	var counts := {"TROOP_ONLY":0,"HERO_ONLY":0,"HERO_AND_TROOPS":0}
	var factions := {}; var ids := {}
	for scene: Dictionary in parsed.scenes:
		var id := str(scene.get("id","")); ids[id]=true
		var category := str(scene.get("category",""))
		ck(counts.has(category),id+": known media category")
		if counts.has(category): counts[category]+=1
		var raw_setup: Dictionary=scene.get("config",{})
		var raw_before := var_to_str(raw_setup)
		var setup: Dictionary=Inputs.decode(raw_setup)
		ck(raw_before==var_to_str(raw_setup),id+": schema integer decoding leaves raw scenario unchanged")
		ck(bool(Runner.validate(setup).accepted),id+": media configuration passes actual Runner admission")
		ck(int(setup.get("limit_seconds",0))>=300,id+": formal five-minute arena limit")
		var sides: Dictionary=setup.get("sides",{})
		var left: Dictionary=sides.get("PLAYER",{}); var right: Dictionary=sides.get("AI",{})
		ck(left.get("faction_id","")==right.get("faction_id","") and left.get("faction_id","") in PLAYABLE,id+": both opponents are the same playable faction")
		factions[str(left.get("faction_id",""))]=true
		for side: Dictionary in [left,right]:
			if category=="TROOP_ONLY": ck(side.get("heroes",[]).is_empty() and not side.get("troops",[]).is_empty(),id+": ordinary troop-only roster")
			elif category=="HERO_ONLY": ck(not side.get("heroes",[]).is_empty() and side.get("troops",[]).is_empty(),id+": hero-only roster")
			elif category=="HERO_AND_TROOPS": ck(not side.get("heroes",[]).is_empty() and not side.get("troops",[]).is_empty(),id+": heroes and ordinary troops both present")
	ck(ids.size()==6 and not ids.has(""),"six unique nonempty media scenario identities")
	ck(factions.size()==3,"media arena plan covers all three factions")
	ck(counts=={"TROOP_ONLY":2,"HERO_ONLY":2,"HERO_AND_TROOPS":2},"exactly two scenes in each requested arena category")
	cases.append({"kind":"media-plan-admission","scenes":parsed.scenes.size(),"counts":counts,"factions":factions.keys(),"scope":"formal actual Runner admission, not executed battle or movie qualification"})

func _json_admission() -> void:
	var base := Runner.preset("MIXED","HUMAN","MACHINE")
	var encoded: Dictionary=JSON.parse_string(JSON.stringify(base))
	ck(bool(Runner.validate(Inputs.decode(encoded)).accepted),"schema decoder admits integral JSON fields through strict Runner")
	for field: String in ["seed","limit_seconds","level","skill_rank","troop_count","huge_seed","string_seed"]:
		var bad := base.duplicate(true)
		match field:
			"seed": bad.seed=1701.25
			"limit_seconds": bad.limit_seconds=60.25
			"level": bad.sides.PLAYER.heroes[0].level=5.25
			"skill_rank": bad.sides.PLAYER.heroes[0]["skill_ranks"]=[2.25,2,1]
			"troop_count": bad.sides.PLAYER.troops[0].count=2.25
			"huge_seed": bad.seed=1.0e100
			"string_seed": bad.seed="1701"
		ck(not bool(Runner.validate(Inputs.decode(bad)).accepted),field+": decoder cannot truncate or coerce invalid external input into a legal configuration")
	cases.append({"kind":"json-admission","valid_roundtrip":true,"invalid_fractional_huge_or_string_cases":7})

func _main_helpers() -> void:
	# Instantiate the actual Main script without entering the tree, so no _ready,
	# audio or autonomous process runs. Exercise the real typed-return helpers.
	var main := MainView.new()
	for faction: String in PLAYABLE:
		var resolved := Matches.resolve({"map_id":"borderlands","participants":[_participant(faction),_participant("MACHINE")]})
		ck(bool(resolved.accepted),faction+": actual Main helper fixture setup is legal")
		if not bool(resolved.accepted): continue
		var snapshot := {"outpost_mode":true,"match_config":resolved.match_config,"catalog":{"units":Runner.catalog().units}}
		var untouched := var_to_str(snapshot)
		main.set("_snapshot",snapshot)
		var choices: Array[String]=main.call("_hero_archetypes")
		ck(choices.size()==8 and _sorted(choices)==_sorted(Factions.heroes_for(faction)),faction+": actual Main typed hero helper returns complete legal faction roster")
		choices.clear()
		var cached: Array[String]=main.call("_hero_archetypes")
		ck(cached.size()==8 and _sorted(cached)==_sorted(Factions.heroes_for(faction)),faction+": actual Main typed cache returns detached hero choices")
		var units: Array[String]=main.call("_unit_types")
		var expected := Factions.units_for(faction)
		expected.append("hero")
		ck(_sorted(units)==_sorted(expected),faction+": actual Main recruit helper exposes seven regular troops plus hero and no worker")
		ck(untouched==var_to_str(snapshot),faction+": Main catalog helpers leave detached snapshot unchanged")
	main.free()
	cases.append({"kind":"actual-main-helpers","factions":3,"scope":"actual Main typed return/cache and recruitment helper, detached legal snapshots, no ready/audio/native input or battle advancement"})

func _sorted(values: Array) -> Array:
	var result := values.duplicate(); result.sort(); return result

func _entry_ids(entries: Array) -> Array:
	var result: Array=[]
	for entry: Dictionary in entries: result.append(str(entry.get("id","")))
	return _sorted(result)

func _option_ids(option: Node) -> Array:
	var result: Array=[]
	if not option is OptionButton: return result
	for index: int in range(option.item_count): result.append(str(option.get_item_metadata(index)))
	return _sorted(result)

func _pins() -> Dictionary:
	var result := Runner.source_hashes()
	for path: String in ["tests/run_first_release_checks.gd","tools/release_media/scenario_inputs.gd","media/first-release-20261112/scenarios.json","src/simulation/first_release_catalog.gd","src/simulation/strategic_match_catalog.gd","src/simulation/strategic_arena_budget_preset.gd","src/presentation/strategic_arena.gd","src/presentation/strategic_lobby.gd","src/presentation/strategic_pregame_guide.gd","src/presentation/strategic_pregame_catalog.gd","src/presentation/strategic_hero_arena.gd"]:
		result[path]=FileAccess.get_sha256("res://"+path)
	return result
