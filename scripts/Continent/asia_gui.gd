extends Control

@onready var tier_buttons = [
	$"Columns/Tier 1/PanelContainer/Button",
	$"Columns/Tier 2/PanelContainer/Button",
	$"Columns/Tier 3/PanelContainer/Button",
]


func _ready() -> void:
	var continent = Global.current_continent
	var data = Global.player_progress[continent]
	
	var index = 0
	
	for diff in ["EASY", "MEDIUM", "HARD"]:
		for puzzle_id in data[diff]:
			
			if index >= tier_buttons.size():
				return
			
			var btn = tier_buttons[index]
			var puzzle_data = data[diff][puzzle_id]
			btn.text = puzzle_id
			
			#if puzzle_data["state"] == "LOCKED":
				#btn.disabled = true
			#else:
				#btn.disabled = false
				#btn.pressed.connect(_on_puzzle_pressed.bind(diff, puzzle_id))
			if puzzle_data["state"] == "LOCKED":
				btn.disabled = true
				btn.modulate = Color(0.5, 0.5, 0.5) # Darken locked puzzles
			elif puzzle_data["state"] == "COMPLETED":
				btn.disabled = true
				btn.modulate = Color(0, 1, 0) # Turn completed puzzles green
			else: # UNLOCKED
				btn.disabled = false
				btn.modulate = Color.WHITE
				btn.pressed.connect(_on_puzzle_pressed.bind(diff, puzzle_id))
			index += 1
	
func _on_puzzle_pressed(diff: String, puzzle_id: String):
	Global.current_puzzle_diff = diff
	Global.current_puzzle_id = puzzle_id
	
	var continent = Global.current_continent
	var puzzle_data = Global.player_progress[continent][diff][puzzle_id]
	get_tree().change_scene_to_file(puzzle_data["path"])
	
	
