extends RefCounted
## Pure presentation metadata. Footprints are conservative world radii at the
## declared display_scale, not physics bodies or selectable game objects.
const VERSION := "heroic-decor-m66-v1"
const DISPLAY_SCALE := 1.4
const DEFINITIONS := {
	"MEADOW":{"layer":"ground","contexts":["WILD","HOME","VILLAGE"],"factions":["HUMAN","FOREST"],"footprint":44.0,"variant_names":["白花与草穗","黄花石边","野花小径"],"source":"Starter flowers and original grass tufts"},
	"THICKET":{"layer":"prop","contexts":["WILD","HOME"],"factions":["HUMAN","UNDEAD","MACHINE","FOREST","HIGHLAND","UNDERGROUND"],"footprint":56.0,"variant_names":["外缘丛落","交错树群","层叠树冠"],"source":"Licensed Overworld racial whole-tree/woodland/fungal composition; Starter oak, pine, bush and original roots remain fallback"},
	"ROCK_GARDEN":{"layer":"ground","contexts":["WILD","ROCK","HOME"],"factions":["HIGHLAND","UNDERGROUND"],"footprint":48.0,"variant_names":["苔石散落","低矮碎岩","石环与小草"],"source":"Starter stone clusters and original moss"},
	"DEADWOOD":{"layer":"ground","contexts":["WILD","ROCK","HOME"],"factions":["FOREST","UNDEAD"],"footprint":46.0,"variant_names":["倒木与嫩芽","断桩枯枝","旧木菌簇"],"source":"Starter deadwood and original stump, shoots and fungi"},
	"SHORE_REEDS":{"layer":"ground","contexts":["SHORE"],"factions":[],"footprint":44.0,"variant_names":["芦苇水边","岸石与细苇","蒲草浅岸"],"source":"Starter reeds and original shore pebbles and cattails"},
	"WELL":{"layer":"prop","contexts":["HOME","VILLAGE"],"factions":["HUMAN"],"footprint":52.0,"variant_names":["石井与木桶","木顶旧井","矮井与水槽"],"source":"Original project pixel ornaments"},
	"BARRELS_CRATES":{"layer":"prop","contexts":["HOME","ROADSIDE","VILLAGE"],"factions":["HUMAN","MACHINE"],"footprint":46.0,"variant_names":["木桶箱堆","并排双桶","篷布货箱"],"source":"Original project pixel ornaments"},
	"FENCE_CORNER":{"layer":"prop","contexts":["HOME","VILLAGE","ROADSIDE"],"factions":["HUMAN"],"footprint":48.0,"variant_names":["木栏转角","残缺篱笆","石脚短栏"],"source":"Original project pixel ornaments"},
	"SIGNPOST":{"layer":"prop","contexts":["ROADSIDE","VILLAGE"],"factions":[],"footprint":44.0,"variant_names":["双向木牌","石基路标","旧牌与灯架"],"source":"Original project pixel ornaments; no interactive glyphs"},
	"CART":{"layer":"prop","contexts":["HOME","ROADSIDE","VILLAGE"],"factions":["HUMAN","MACHINE"],"footprint":50.0,"variant_names":["卸货木车","覆布小车","侧停手推车"],"source":"Original project pixel ornaments"},
	"CAMP_SUPPLIES":{"layer":"prop","contexts":["HOME","ROADSIDE","VILLAGE"],"factions":["HUMAN","HIGHLAND"],"footprint":50.0,"variant_names":["卷毯与箱篓","低帐与木箱","陶罐营具"],"source":"Original project pixel ornaments; not loot or production"},
	"RUIN_PILLARS":{"layer":"prop","contexts":["HOME","ROCK","WILD"],"factions":["UNDEAD","UNDERGROUND"],"footprint":54.0,"variant_names":["断柱与基座","倾倒柱石","旧门残墙"],"source":"Original project pixel ornaments"},
	"GRAVESTONES_BONES":{"layer":"prop","contexts":["HOME","ROCK"],"factions":["UNDEAD"],"footprint":50.0,"variant_names":["风化双碑","石棺残骨","矮碑与枯草"],"source":"Original project pixel ornaments"},
	"FUNGAL_CRYSTAL":{"layer":"ground","contexts":["HOME","WILD","ROCK"],"factions":["UNDERGROUND","FOREST"],"footprint":46.0,"variant_names":["苔菌与紫晶","蘑菇环","岩隙晶簇"],"source":"Original project pixel ornaments; not harvestable resources"},
	"SNOW_CAIRN":{"layer":"prop","contexts":["HOME","ROCK"],"factions":["HIGHLAND"],"footprint":46.0,"variant_names":["覆雪石堆","双层雪岩","雪地矮垒"],"source":"Original project pixel ornaments"},
	"MACHINE_SCRAP":{"layer":"ground","contexts":["HOME","ROCK","ROADSIDE"],"factions":["MACHINE"],"footprint":48.0,"variant_names":["旧轮与铁管","铁板螺栓","断管货架"],"source":"Original project pixel ornaments"},
}


static func families() -> Array[String]:
	var result: Array[String] = []
	for id: String in DEFINITIONS: result.append(id)
	return result


static func definition(id: String) -> Dictionary:
	if not DEFINITIONS.has(id): return {}
	var result: Dictionary = DEFINITIONS[id].duplicate(true)
	result["id"] = id
	result["display_scale"] = DISPLAY_SCALE
	result["variants"] = 3
	return result
