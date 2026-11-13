extends RefCounted
## Faithful item, building and spell illustrations only. Navigation and
## ambiguous economic symbols intentionally retain their original glyphs.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const Props = preload("res://src/presentation/heroic_collection_props.gd")
const Effects = preload("res://src/presentation/heroic_collection_effects.gd")
const Heroes = preload("res://src/simulation/strategic_hero_catalog.gd")
const ItemRules = preload("res://src/simulation/strategic_hero_items.gd")
const IdentityIcons = preload("res://src/presentation/heroic_identity_icons.gd")
const OutpostsV3Magic = preload("res://src/presentation/heroic_outposts_magic_camps_v3.gd")
## Complete ZIP-relative paths: equipment and skill sheets belong to different
## author-pack versions. A shared 1.1 prefix would silently misroute the compass.
const ITEM_FILES := {"sword":"IconPack 1.1/AllItems/WeaponSource/SwordOriginal.png", "bow":"IconPack 1.1/AllItems/WeaponSource/RangedOriginal.png", "shield":"IconPack 1.1/AllItems/ShieldSource/ShieldOriginal.png", "mail":"IconPack 1.1/AllItems/TorsoSource/TorsoOriginal.png", "misc":"IconPack 1.1/AllItems/MiscellaneousSource/MiscellaneousOriginal.png", "feet":"IconPack 1.1/AllItems/FeetSource/FeetOriginal.png", "skills":"IconPack 1.2/Skills/Skills.png"}
const ITEMS := {"sword":["sword", 2, 0], "IRON_BLADE":["sword", 2, 0], "bow":["bow", 1, 0], "bright_crossbow":["bow", 8, 0], "armor":["shield", 0, 0], "guard":["shield", 1, 0], "hinge_guard":["shield", 1, 0], "WARD_MAIL":["mail", 3, 0], "equipment":["mail", 3, 0], "material":["misc", 0, 0], "red_bottle":["misc", 2, 1], "blue_bottle":["misc", 2, 0], "FIELD_BOOTS":["feet", 7, 1], "PATHFINDER_COMPASS":["skills", 2, 5]}
const SPELL_ICONS := {"health":"Cure", "RECOVER":"Cure", "BULWARK_RECOVER":"Contusion", "BLOOD_PACT":"Contusion", "BULWARK_WARD":"Shield", "SHIELD_SHOCK":"Cure", "STARFIRE":"FireBall", "FROST_BIND":"FrostRing", "ARCANE_BURST":"EnergyBlast", "RALLY":"Cure", "aura_emblem":"Bless", "QUICKDRAW":"Bloodlust"}
const ITEM_ALIASES := {"SHOP":"equipment", "LONGSIGHT":"bow", "VITAL_CHARM":"health", "SPELL_LENS":"ARCANE_BURST", "VANGUARD_BLADE":"IRON_BLADE", "WARDEN_CREST":"WARD_MAIL", "ARCANE_SIGIL":"ARCANE_BURST", "WAR_STANDARD":"aura_emblem", "AEGIS_STANDARD":"BULWARK_WARD", "POTION":"red_bottle", "MANA_POTION":"blue_bottle", "RESTORATION_DRAUGHT":"RECOVER", "CLEANSE_DRAUGHT":"aura_emblem", "GUARD_DRAUGHT":"BULWARK_WARD", "HASTE_DRAUGHT":"QUICKDRAW"}


static func required_files() -> Dictionary:
	var files: Array[String] = []
	for file: String in ITEM_FILES.values(): files.append(file)
	files.sort()
	return {"icons":files}


static func inspect(symbol: String) -> Dictionary:
	var v3 := OutpostsV3Magic.inspect_symbol(symbol)
	if bool(v3.get("supported",false)):return v3
	if IdentityIcons.supported(symbol): return IdentityIcons.inspect(symbol)
	if not Collection.active(): return {"supported":false}
	# New actual inventory identities inherit their semantic author icon, not
	# an unknown plastic placeholder. Navigation symbols keep their old glyphs.
	if not ITEMS.has(symbol) and not ITEM_ALIASES.has(symbol) and ItemRules.ITEMS.has(symbol):
		var semantic := str(ItemRules.ITEMS[symbol].get("icon","equipment"))
		symbol=str({"mana":"blue_bottle","hero":"ARCANE_BURST","move":"FIELD_BOOTS","health":"health","sword":"sword","armor":"WARD_MAIL","bow":"bow","aura":"aura_emblem"}.get(semantic,"equipment"))
	if symbol == "ESSENCE_RESTORATION": symbol = "RECOVER"
	elif symbol == "ESSENCE_BULWARK": symbol = "BULWARK_WARD"
	if ITEM_ALIASES.has(symbol): symbol = str(ITEM_ALIASES[symbol])
	if symbol == "misc": symbol = "material"
	if not ITEMS.has(symbol) and not SPELL_ICONS.has(symbol) and Heroes.SKILLS.has(symbol):
		var skill := Heroes.skill_at_level(symbol, 1)
		symbol = str({"AURA":"RALLY", "PASSIVE_GUARD":"BULWARK_WARD", "HEAL":"RECOVER", "STUN":"SHIELD_SHOCK", "ROOT":"FROST_BIND", "ARMOR_BUFF":"BULWARK_WARD", "DAMAGE_BUFF":"QUICKDRAW", "RALLY":"RALLY"}.get(str(skill.get("effect", "")), "ARCANE_BURST" if skill.get("attack_type") == "ARCANE" else "sword"))
	var entry: Dictionary = {}
	if ITEMS.has(symbol):
		var item: Array = ITEMS[symbol]
		entry = {"pack":"icons", "file":str(ITEM_FILES[item[0]]), "rect":Rect2i(int(item[1]) * 16, int(item[2]) * 16, 16, 16)}
	elif SPELL_ICONS.has(symbol):
		var spell := str(SPELL_ICONS[symbol])
		entry = {"pack":"magic", "file":Effects.ROOT + spell + "/Icon" + spell + ".png", "rect":Rect2i(0, 0, 16, 16)}
	elif symbol in ["BASE", "BARRACKS", "RANGE", "TOWER", "SITE_TOWER", "ESSENCE_MINE", "FOUNDRY", "ALTAR", "WORKSHOP", "DRAGON_ROOST"]:
		var building := Props.inspect_building({"building_type":symbol, "faction_id":"HUMAN", "complete":true, "hp":1})
		if not bool(building.get("supported", false)): return {"supported":false}
		entry = {"pack":"buildings", "file":building.file, "rect":building.rect}
	else: return {"supported":false}
	var pixels: Image = Collection.image(str(entry.pack), str(entry.file))
	if pixels == null or not Rect2i(Vector2i.ZERO, pixels.get_size()).encloses(Rect2i(entry.rect)): return {"supported":false}
	entry["supported"] = true
	entry["provenance"] = "licensed"
	entry["symbol"] = symbol
	return entry


static func draw_symbol(canvas: Object, symbol: String, center: Vector2, color: Color, scale_factor: float = 1.0) -> bool:
	if not center.is_finite() or not is_finite(scale_factor) or scale_factor <= 0: return false
	if OutpostsV3Magic.draw_symbol(canvas,symbol,center,color,scale_factor):return true
	if IdentityIcons.supported(symbol): return IdentityIcons.draw_symbol(canvas,symbol,center,color,scale_factor)
	var entry := inspect(symbol)
	if not bool(entry.get("supported", false)): return false
	# Existing consumers paint a dark vector shadow pass before the foreground.
	# Source art already has shading; consume that pass without double painting.
	if maxf(color.r, maxf(color.g, color.b)) < 0.28: return true
	var disabled := color.r < 0.62 and color.g < 0.69 and color.b < 0.66
	var source: Rect2i = entry.rect
	var side := 40.0 * scale_factor
	var multiplier := side / float(maxi(source.size.x, source.size.y))
	return Collection.draw_region(canvas, str(entry.pack), str(entry.file), source, center, Vector2(source.size) * 0.5, multiplier, Color("838e8d") if disabled else Color.WHITE)


static func debug_stats() -> Dictionary:
	return {"active":Collection.active(), "item_symbols":ITEMS.size(), "spell_symbols":SPELL_ICONS.size(), "building_symbols":8, "texture_bytes":0, "cpu_pixel_bytes":0, "owner_atlas_copies":0, "shared_collection_textures":true, "identity_icons":IdentityIcons.debug_stats(), "unmapped_commands":"original_fallback"}
