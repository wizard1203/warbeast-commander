extends RefCounted
## Ten optional original Magic Book strips. No owner/phase/rank texture copies.
const MANIFEST := "res://assets/art/heroic/combat-effects-manifest.json"
const ROOT := "res://assets/third_party/heroic_combat_local/"
const BUDGET := 92160
const PINNED := {
	"FirstStrike":[427,"73e443fbdb38c37673edbae5a051084bb820686c41e81f4e78faed4ac70f7742"],
	"Shrapnel":[544,"4a2706df89e8a3d65210b2b8dfaf37ad9a57878037c14a3449291e2c5a625341"],
	"LightningBolt":[227,"fca67d9b3c3fc56f09eda89ea7de4788a6615b932367ee810dbab3493282d692"],
	"DeathRipple":[422,"58efbc96430cd42d415e47f46a89f6b82a6037d0d25b7a7aec1fdcdefceb0c6f"],
	"AcidSplash":[426,"6038215b4864ab52d6b6101c44553a0374d6cce1fde36de4d0dd66b5adf44334"],
	"IceSpikes":[463,"ca42ae86061ed11e1ab6a4b2ec0c32d6ee386fb19fca8395e8adc4a3d98a4e67"],
	"StoneSpikes":[442,"b2cff2ad394cd2203b8cb1e5aa3de887a48e7580b8d565ca4abc7325d0d07e56"],
	"HolyLight":[498,"aac9474a73d100874c1b48ce55bf66a4e5589f71df44c00dec4604244f6b7fac"],
	"FlameStrike":[368,"c92d0b8bad0796665d9186b2a2369a73575514c268cd558f67ed1bacee61d444"],
	"Explosion":[568,"5f63ba870f33c4bc0185925c66b2ea0284bdb258ff620f68ebfdb7d72db4d1aa"]
}
static var _attempted := false
static var _ready := false
static var _images: Dictionary = {}
static var _textures: Dictionary = {}
static var _reason := "Optional combat pack absent or rejected; existing pixel effects remain available."

static func _linked(path: String) -> bool:
	var current := "res://"
	for part: String in path.trim_prefix("res://").split("/", false):
		var parent := DirAccess.open(current)
		if parent == null or parent.is_link(part): return true
		current = current.path_join(part)
	return false

static func _ensure() -> void:
	if _attempted: return
	_attempted = true
	if not FileAccess.file_exists(MANIFEST) or _linked(MANIFEST): return
	var manifest := FileAccess.open(MANIFEST, FileAccess.READ)
	if manifest == null or manifest.get_length() > 16384: return
	var contract: Variant = JSON.parse_string(manifest.get_as_text())
	if not contract is Dictionary or contract.get("schema_version") != 1 or contract.get("pack_id") != "heroic-combat-effects-m42" or contract.get("runtime_root") != ROOT or contract.get("public_raw_redistribution") != false: return
	if contract.get("selected_rgba8_bytes") != BUDGET or contract.get("texture_budget_bytes") != BUDGET: return
	var files: Variant = contract.get("files")
	if not files is Dictionary or files.size() != PINNED.size(): return
	var verified: Dictionary = {}
	for spell: String in PINNED:
		var member := "HAS Magic Book 1.1/%s/%sAllFrames.png" % [spell, spell]
		var spec: Variant = files.get(member)
		if not spec is Dictionary or spec.get("file") != spell + ".png" or spec.get("bytes") != PINNED[spell][0] or spec.get("sha256") != PINNED[spell][1] or spec.get("width") != 96 or spec.get("height") != 24: return
		var path := ROOT + spell + ".png"
		if not FileAccess.file_exists(path) or _linked(path): return
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_length() != int(PINNED[spell][0]) or FileAccess.get_sha256(path) != str(PINNED[spell][1]): return
		var pixels := Image.new()
		if pixels.load_png_from_buffer(file.get_buffer(int(PINNED[spell][0]))) != OK or pixels.get_size() != Vector2i(96,24): return
		pixels.convert(Image.FORMAT_RGBA8)
		verified[spell] = pixels
	_images = verified
	_ready = true
	_reason = ""

static func inspect(spell: String, phase: float) -> Dictionary:
	if not PINNED.has(spell) or not is_finite(phase) or phase < 0 or phase >= 1: return {"supported":false}
	_ensure()
	if not _ready: return {"supported":false,"fallback_reason":_reason}
	return {"supported":true,"spell":spell,"frame":mini(3,int(phase*4)),"rect":Rect2i(mini(3,int(phase*4))*24,0,24,24),"anchor":Vector2(12,18),"provenance":"licensed-heroic-magic-book","source_unmodified":true,"file":ROOT+spell+".png","sha256":PINNED[spell][1]}

static func draw(canvas: Object, spell: String, phase: float, point: Vector2, scale: float, tint: Color = Color.WHITE) -> bool:
	if not point.is_finite() or not is_finite(scale) or scale <= 0: return false
	var entry := inspect(spell, phase)
	if not bool(entry.get("supported",false)): return false
	if not _textures.has(spell): _textures[spell] = ImageTexture.create_from_image(_images[spell])
	if canvas is CanvasItem: canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw_texture_rect_region(_textures[spell],Rect2((point-Vector2(entry.anchor)*scale).round(),Vector2(24,24)*scale),Rect2(entry.rect),tint)
	return true

static func debug_stats() -> Dictionary:
	_ensure()
	return {"ready":_ready,"strips":_images.size(),"textures":_textures.size(),"texture_bytes":_textures.size()*96*24*4,"cpu_pixel_bytes":_images.size()*96*24*4,"texture_budget_bytes":BUDGET,"owner_atlas_copies":0,"source_unmodified":true,"fallback_reason":_reason}
