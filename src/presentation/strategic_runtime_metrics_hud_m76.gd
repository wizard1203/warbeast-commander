extends Control
## Read-only compact companion to StrengthScoreHUD; no match/replay reference.
const UITheme = preload("res://src/presentation/strategic_ui_theme.gd")
const Fonts = preload("res://src/presentation/strategic_font.gd")
const TooltipGate = preload("res://src/presentation/strategic_native_tooltip_gate.gd")
var _compact := false
var _facts := {}
var _fps_text := "—"
var _cpu_text := "—"
var _memory_text := "—"
var _fingerprint := ""

func _ready() -> void:
	name = "RuntimeMetricsHUD"
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = minimum_panel_size()
	_update_help()

func set_compact(value: bool) -> void:
	if value == _compact: return
	_compact = value
	custom_minimum_size = minimum_panel_size()
	queue_redraw()

func minimum_panel_size() -> Vector2:
	return Vector2(208 if _compact else 228,28)

func refresh(facts: Dictionary) -> void:
	# Explicit typed finite gates: "42"/NaN/INF/negative never become a
	# plausible measurement. A real 0% idle sample remains valid.
	var fps := _metric(facts,"fps","fps_available")
	var cpu := _metric(facts,"cpu_percent","cpu_available")
	var memory := _metric(facts,"rss_mib","rss_available")
	_fps_text = "%.1f"%fps if fps>=0 else "—"
	_cpu_text = "%.0f%%"%cpu if cpu>=0 else "—"
	_memory_text = "%.0f MiB"%memory if memory>=0 else "—"
	_facts = {"fps":fps,"cpu_percent":cpu,"rss_mib":memory,"status":str(facts.get("status","UNAVAILABLE")),"sample_age_ms":facts.get("sample_age_ms",-1.0),"sample_interval_ms":facts.get("sample_interval_ms",0.0)}
	var fingerprint := str([_fps_text,_cpu_text,_memory_text,_facts.status])
	if fingerprint == _fingerprint: return
	_fingerprint = fingerprint
	_update_help()
	queue_redraw()

func inspect() -> Dictionary:
	return {"fps_text":_fps_text,"cpu_text":_cpu_text,"memory_text":_memory_text,"metrics":_facts.duplicate(true),"preferred_size":minimum_panel_size(),"compact":_compact}

func _metric(facts: Dictionary, value_key: String, available_key: String) -> float:
	if facts.get(available_key,false) != true: return -1.0
	var value: Variant = facts.get(value_key,-1.0)
	if typeof(value) not in [TYPE_FLOAT,TYPE_INT]: return -1.0
	return float(value) if is_finite(float(value)) and float(value)>=0 else -1.0

func _update_help() -> void:
	tooltip_text = "实时性能 · 约每秒更新\nFPS：每秒实际绘制的画面帧数。\nCPU：当前游戏进程的处理器占用；单核满载为100%，多核可超过100%。\n内存：当前游戏进程的驻留内存，单位MiB，不含显存统计。\n暂未取得有效样本时显示—。"
	if _facts.get("status","") == "STALE": tooltip_text += "\n当前OS样本已过期。"

func _draw() -> void:
	UITheme.draw_surface(self,Rect2(Vector2.ZERO,size),"strip","normal")
	var width := (size.x-16)/3.0
	_caption(Vector2(8,18),"FPS "+_fps_text,width-3,_fps_color())
	_caption(Vector2(8+width,18),"CPU "+_cpu_text,width-3,Color("d5d0b8"))
	_caption(Vector2(8+2*width,18),_memory_text,width-3,Color("b8cabd"))

func _fps_color() -> Color:
	var fps := float(_facts.get("fps",-1.0))
	return Color("edb681") if fps>=0 and fps<24 else Color("c4dca7")

func _caption(point: Vector2, text: String, width: float, ink: Color) -> void:
	draw_string(Fonts.readable(),point+Vector2(0,1),text,HORIZONTAL_ALIGNMENT_LEFT,width,11,Color("0d1516"))
	draw_string(Fonts.readable(),point,text,HORIZONTAL_ALIGNMENT_LEFT,width,11,ink)

func _get_tooltip(_at_position: Vector2) -> String:
	return TooltipGate.native_text(self)
