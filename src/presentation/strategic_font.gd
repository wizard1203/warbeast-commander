extends RefCounted
## Native CJK shaping for CanvasItem text. The platform resolves installed
## fonts; there is no downloaded font or franchise asset dependency.
static var _font: SystemFont
static var _title: SystemFont
const HeroicCommandArt = preload("res://src/presentation/heroic_command_art.gd")
static func readable() -> Font:
	if _font == null:
		_font = SystemFont.new()
		_font.font_names = PackedStringArray(["Heiti SC", "PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", "WenQuanYi Micro Hei", "Arial Unicode MS"] if HeroicCommandArt.enabled() else ["PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", "WenQuanYi Micro Hei", "Heiti SC", "Arial Unicode MS"])
		_font.allow_system_fallback = true
		# font_names chooses a system face; it is not per-glyph fallback. Some
		# installed PingFang faces omit individual common characters (e.g. 远).
		# Keep the existing preferred face, but attach installed complete local
		# faces explicitly so every HUD consumer shares the same CJK coverage.
		var glyph_fallbacks: Array[Font] = []
		for family: String in ["Heiti SC", "Arial Unicode MS"]:
			if OS.get_system_font_path(family).is_empty(): continue
			var fallback := SystemFont.new()
			fallback.font_names = PackedStringArray([family])
			fallback.allow_system_fallback = false
			glyph_fallbacks.append(fallback)
		_font.fallbacks = glyph_fallbacks
	return _font

## Reserved for existing headings at least 20 px. Body labels, counters and
## controls keep the readable sans face; no tiny pixel-font CJK compromise.
static func title() -> Font:
	if not HeroicCommandArt.enabled(): return readable()
	if _title == null:
		_title = SystemFont.new()
		_title.font_names = PackedStringArray(["Songti SC", "Noto Serif CJK SC", "Source Han Serif SC", "Heiti SC", "PingFang SC"])
		_title.allow_system_fallback = true
		_title.fallbacks = [readable()]
	return _title

static func inspect() -> Dictionary:
	return {"body_families":Array((readable() as SystemFont).font_names), "title_families":Array((title() as SystemFont).font_names), "source":"installed-system-fonts", "downloaded":false, "bundled_font_bytes":0}
