extends Control
## A native-only presenter gate. tooltip_text remains the unmodified source
## consumed by ContextHelp. No global timer, copied text ledger or hidden popup.
const OWNER_META := "shared_context_help_owner"

func _get_tooltip(_at_position: Vector2) -> String:
	return native_text(self)

static func native_text(control: Control) -> String:
	var ancestor: Node = control
	while ancestor != null:
		if ancestor.has_meta(OWNER_META):
			return "" if bool(ancestor.get_meta(OWNER_META)) else control.tooltip_text
		ancestor = ancestor.get_parent()
	return control.tooltip_text

static func attach_native_control(node: Node) -> void:
	# A script derived from Control can attach to an otherwise unscripted Label,
	# Button, etc. Their native class, signals, input and properties stay intact.
	# Scripted widgets explicitly delegate _get_tooltip instead: never replace
	# their behavior scripts or overwrite descriptions during refresh.
	if node is Control and node.get_script() == null:
		node.set_script(load("res://src/presentation/strategic_native_tooltip_gate.gd"))

static func attach_native_subtree(node: Node) -> void:
	attach_native_control(node)
	for child: Node in node.get_children(): attach_native_subtree(child)
