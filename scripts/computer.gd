extends Node2D

@onready var terminal_sprite: Area2D = $Visuals/TextureRect/VBoxContainer/Terminal
@onready var map_sprite: Area2D = $Visuals/TextureRect/VBoxContainer/Map


func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	terminal_sprite.modulate = Color("cccccc")
	map_sprite.modulate = Color("cccccc")

# Termial button
func _on_terminal_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/terminal.tscn")

func _on_terminal_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	terminal_sprite.modulate = Color.WHITE

func _on_terminal_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	terminal_sprite.modulate = Color("#cccccc")

# Map button
func _on_map_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/map.tscn")

func _on_map_mouse_entered() -> void:
	map_sprite.modulate = Color.WHITE

func _on_map_mouse_exited() -> void:
	map_sprite.modulate = Color("cccccc")
