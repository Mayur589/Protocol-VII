extends Node2D

const HOVER_COLOR = Color.WHITE
const DEFAULT_COLOR = Color("a4a4a4")
@onready var back_arrow: Sprite2D = $BackArrow/Sprite2D

func _ready() -> void:
	for child in get_children():
		for nested_child in child.get_children():
			if nested_child is Area2D:
				_setup_continent(nested_child)
	
func _setup_continent(area: Area2D) -> void:
	if area.has_node("Sprite2D"):
		var sprite: Sprite2D = area.get_node("Sprite2D")
		sprite.modulate = DEFAULT_COLOR
		
		area.input_event.connect(_on_continent_input.bind(area.get_parent()))
		area.mouse_entered.connect(_on_continent_hover.bind(sprite))
		area.mouse_exited.connect(_on_continent_exit.bind(sprite))
	
	var parent = area.get_parent()
	parent.con_res.Puzzles = Global.continent_puzzles[parent.con_res.Name]

func _on_continent_input(_viewport: Node, event: InputEvent, _shape_idx: int, continent: Node2D) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if continent.con_res != null:
			Global.current_continent = continent.con_res.Name
			get_tree().change_scene_to_file("res://scenes/puzzle_display.tscn")
			
# We bind the specific Sprite2D, so we know exactly which one to color
func _on_continent_hover(sprite: Sprite2D) -> void:
	sprite.modulate = HOVER_COLOR

func _on_continent_exit(sprite: Sprite2D) -> void:
	sprite.modulate = DEFAULT_COLOR


func _on_back_arrow_mouse_entered() -> void:
	back_arrow.modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_back_arrow_mouse_exited() -> void:
	back_arrow.modulate = Color("cdcbcf")
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_back_arrow_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/computer.tscn")
