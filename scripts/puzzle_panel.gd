extends Control

@onready var tier_buttons = [
	$"PanelContainer/VBoxContainer/HBoxContainer/Puzzle1/Button",
	$"PanelContainer/VBoxContainer/HBoxContainer/Puzzle2/Button",
	$"PanelContainer/VBoxContainer/HBoxContainer/Puzzle3/Button"

]

@onready var continent_logo: TextureRect = $PanelContainer/VBoxContainer/MarginContainer/HFlowContainer/ContinentLogo
@onready var lore_label: Label = $PanelContainer/VBoxContainer/MarginContainer/HFlowContainer/Panel/LoreLabel

@onready var arrow_to_puzzle_2: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/arrowToPuzzle1
@onready var arrow_to_puzzle_3: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/arrowToPuzzle2

var _typing_speed: float = 60
var _typing_time: float
var is_animation_finish: bool = false

var lore_dic: Dictionary = {
	"Africa": "Lore about the ancient civilizations and vast landscapes of Africa goes here...",
	"Antarctica": "Lore about the frozen mysteries and hidden secrets beneath the ice of Antarctica goes here...",
	"Asia": "Lore about the diverse cultures, empires, and mystical traditions of Asia goes here...",
	"Oceania": "Lore about the untamed wilderness and ancient spirits of Australia goes here...",
	"Europe": "Lore about the medieval kingdoms, old wars, and folklore of Europe goes here...",
	"North_America": "Lore about the frontier, native legends, and discovery of North America goes here...",
	"South_America": "Lore about the lost cities, deep jungles, and ancient gods of South America goes here..."
}



func _ready() -> void:
	var continent = Global.current_continent
	arrow_to_puzzle_2.modulate = "ffffff54"
	arrow_to_puzzle_3.modulate = "ffffff54"
	
	if Global.continent_accuire[continent][0] == 1:
		arrow_to_puzzle_2.modulate = "000000"
	
	if Global.continent_accuire[continent][0] == 2:
		arrow_to_puzzle_3.modulate = "000000"
	
	await assign_lore()
	setup_buttons()

func assign_image_to_button(id: String):
	var id_split = id.split("_")
	return id_split[0]
	
func setup_buttons():
	var continent = Global.current_continent
	var data = Global.player_progress[continent]
	var index = 0
	
	if is_animation_finish:
		for diff in ["EASY", "MEDIUM", "HARD"]:
			for puzzle_id in data[diff]:
				if index >= tier_buttons.size():
					return
				
				var btn = tier_buttons[index]
				var puzzle_data = data[diff][puzzle_id]
				
				if puzzle_data["state"] == "LOCKED":
					btn.disabled = true
					btn.text = assign_image_to_button(puzzle_id) + " [LOCKED]"
				elif puzzle_data["state"] == "COMPLETED":
					btn.disabled = true
					btn.text = assign_image_to_button(puzzle_id) + " [DONE]"
				else:
					btn.disabled = false
					btn.text = assign_image_to_button(puzzle_id)
					
					# Disconnect to prevent errors if this is called multiple times
					if btn.pressed.is_connected(_on_puzzle_pressed):
						btn.pressed.disconnect(_on_puzzle_pressed)
					
					btn.pressed.connect(_on_puzzle_pressed.bind(diff, puzzle_id))
				
				index += 1

func assign_lore():
	var continent = Global.current_continent
	var puzzle_completed = Global.continent_accuire[continent]
	
	if puzzle_completed[0] == 0:
		lore_label.text = lore_dic[continent]
		lore_label.visible_characters = 0
		_typing_time = 0
		
		while lore_label.visible_characters < lore_label.get_total_character_count():
			_typing_time += get_process_delta_time()
			lore_label.visible_characters = _typing_speed * _typing_time as int
			await get_tree().process_frame
			is_animation_finish = true
	else:
		lore_label.text = lore_dic[continent]


func _on_puzzle_pressed(diff: String, puzzle_id: String):
	Global.current_puzzle_diff = diff
	Global.current_puzzle_id = puzzle_id
	
	var continent = Global.current_continent
	var puzzle_data = Global.player_progress[continent][diff][puzzle_id]
	get_tree().change_scene_to_file(puzzle_data["path"])
	
