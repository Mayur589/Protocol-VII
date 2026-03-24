extends Control

@onready var tier_buttons = [
	$"Columns/Tier 1/PanelContainer/Button",
	$"Columns/Tier 2/PanelContainer/Button",
	$"Columns/Tier 3/PanelContainer/Button",
]
@onready var back_arrow: Area2D = $BackArrow


func _ready() -> void:
	var continent = Global.current_continent
	var data = Global.player_progress[continent]
	
	var index = 0
	print(tier_buttons.size())
	
	for diff in ["EASY", "MEDIUM", "HARD"]:
		for puzzle_id in data[diff]:

			if index >= tier_buttons.size():
				return
			
			var btn = tier_buttons[index]
			var puzzle_data = data[diff][puzzle_id]
			print(puzzle_data)
			btn.text = puzzle_id
			
			if puzzle_data["state"] == "LOCKED":
				btn.disabled = true
				btn.text = puzzle_id + " [LOCKED]"
			elif puzzle_data["state"] == "COMPLETED":
				btn.disabled = true
				btn.text = puzzle_id + " [DONE]"
			else:
				btn.disabled = false
				btn.text = puzzle_id
				btn.pressed.connect(_on_puzzle_pressed.bind(diff, puzzle_id))
			
			index += 1
	
func _on_puzzle_pressed(diff: String, puzzle_id: String):
	Global.current_puzzle_diff = diff
	Global.current_puzzle_id = puzzle_id
	
	var continent = Global.current_continent
	var puzzle_data = Global.player_progress[continent][diff][puzzle_id]
	get_tree().change_scene_to_file(puzzle_data["path"])
	


func _on_back_arrow_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/map.tscn")


func _on_back_arrow_mouse_entered() -> void:
	back_arrow.modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_back_arrow_mouse_exited() -> void:
	back_arrow.modulate = Color("cdcbcf")
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
