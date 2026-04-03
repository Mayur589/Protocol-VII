extends Control

@onready var map_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MapButton
@onready var desktop_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/DesktopButton

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	map_button.pressed.connect(_on_map_pressed)
	desktop_button.pressed.connect(_on_desktop_pressed)

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _on_desktop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/desktop.tscn")
