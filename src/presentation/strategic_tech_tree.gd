class_name StrategicTechTree
extends Control
## Read-only dependency connections. State is provided by the arena's detached
## snapshot; buttons remain separate controls and never bypass host authority.
const UIThemeClass = preload("res://src/presentation/strategic_ui_theme.gd")

var foundry_state := "NOT_BUILT"
var attack_level := 0
var armor_level := 0
var specialty_level := 0
var faction_technology_levels:Array=[]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var root_point := Vector2(116, 197)
	for index:int in range(faction_technology_levels.size()):
		var x:=87.0+index*196.0
		UIThemeClass.draw_connection(self,Vector2(148,301),Vector2(x,301),foundry_state=="BUILT")
		UIThemeClass.draw_connection(self,Vector2(x,301),Vector2(x,318),int(faction_technology_levels[index])>0)
	for row: int in range(2):
		var y := 75.0 if row == 0 else 187.0
		var level := attack_level if row == 0 else armor_level
		var prerequisite_color := Color("b5c8a2") if foundry_state == "BUILT" else Color("6c7f79")
		UIThemeClass.draw_connection(self, root_point, Vector2(166, root_point.y), foundry_state == "BUILT")
		UIThemeClass.draw_connection(self, Vector2(166, root_point.y), Vector2(166, y), foundry_state == "BUILT")
		UIThemeClass.draw_connection(self, Vector2(166, y), Vector2(198, y), foundry_state == "BUILT")
		draw_circle(Vector2(166, y), 4, Color("172328"))
		draw_circle(Vector2(166, y), 2, prerequisite_color)
		for rank: int in range(2):
			var x := 354.0 + rank * 204
			var color := Color("b5c8a2") if level >= rank + 1 else Color("6c7f79")
			UIThemeClass.draw_connection(self, Vector2(x, y), Vector2(x + 48, y), level >= rank + 1)
			draw_colored_polygon(PackedVector2Array([Vector2(x + 48, y), Vector2(x + 39, y - 5), Vector2(x + 39, y + 5)]), color)
