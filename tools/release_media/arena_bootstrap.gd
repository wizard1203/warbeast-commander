extends SceneTree
const Arena = preload("res://src/presentation/strategic_hero_arena.gd")

func _initialize() -> void:
	root.title = "魔兽指挥官 · 三族竞技场"
	root.size = Vector2i(1440,900)
	root.content_scale_size = Vector2i(1280,800)
	call_deferred("_boot")

func _boot() -> void:
	var arena := Arena.new()
	root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
