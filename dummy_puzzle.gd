extends Control

@onready var label: Label = $VBoxContainer/Label
@onready var win_button: Button = $VBoxContainer/HBoxContainer/WinButton
@onready var lose_button: Button = $VBoxContainer/HBoxContainer/LoseButton

func _ready() -> void:
	# Change the mouse back to the normal cursor just in case
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	# Display exactly which puzzle we are testing
	label.text = "Target: %s\nDifficulty: %s\nNode ID: %s\n\nOmni Awareness: %s%%" % [
		Global.current_continent, 
		Global.current_puzzle_diff, 
		Global.current_puzzle_id,
		Global.omni_awareness
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Connect the buttons via code
	win_button.pressed.connect(_on_win_pressed)
	lose_button.pressed.connect(_on_lose_pressed)


func _on_win_pressed() -> void:
	print(">>> SYSTEM BREACHED SUCCESSFULLY")
	Global.puzzle_won()
	_return_to_map()


func _on_lose_pressed() -> void:
	print(">>> CRITICAL FAILURE: TRACE DETECTED")
	Global.puzzle_lost()
	_return_to_map()


func _return_to_map() -> void:
	# Change this path if your puzzle tree/selection screen is named differently!
	get_tree().change_scene_to_file("res://scenes/map.tscn")
