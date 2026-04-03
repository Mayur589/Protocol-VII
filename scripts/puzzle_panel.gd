extends Control

@onready var tier_buttons = [
	$"PanelContainer/VBoxContainer/HBoxContainer/Puzzle1/Button",
	$"PanelContainer/VBoxContainer/HBoxContainer/Puzzle2/Button",
	$"PanelContainer/VBoxContainer/HBoxContainer/Puzzle3/Button"

]

@onready var back_arrow: Area2D = $BackArrow
@onready var continent_logo: TextureRect = $PanelContainer/VBoxContainer/MarginContainer/HFlowContainer/ContinentLogo
@onready var lore_label: Label = $PanelContainer/VBoxContainer/MarginContainer/HFlowContainer/Panel/LoreLabel
@onready var panel_root: PanelContainer = $PanelContainer

@onready var arrow_to_puzzle_2: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/arrowToPuzzle1
@onready var arrow_to_puzzle_3: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/arrowToPuzzle2

var _typing_speed: float = 60
var _typing_time: float
var is_animation_finish: bool = false
var _button_tweens: Dictionary = {}

var lore_dic: Dictionary = {
	"Africa": "Ancient place with very huge cultural history but taken over by a dictator from South America causing trouble to the whole world and their citizens.",
	"Antarctica": "Covered with snow is home to many natural resources be it minerals or rare animal species, that can lead to new innovations in biological field as well as military and power. However no specific rules the continent.",
	"Asia": "A emerging continent with developing technological advancements, and highly skilled human resources fit for working in any field of work efficiently and at low cost.",
	"Oceania": "An isolated continent with huge human resource, but not well utilised.  A large chunk of the crowd does not have access to basic utilities due to its isolated nature it is not able to trade with other continents.",
	"Europe": "Home to large legacy companies controls the most money and media. And can act as threat to any continent if it goes to war with any of the 7 continents. The leader of this continent controls the digital secret of the whole world as well as financial movement.",
	"North_America": "Strong politically connected country having connections with all the continents and providing supply to almost the whole world and controlling the media.",
	"South_America": "Military has main power in this continent amd control the life of the citizen of their continent. The leader's goal is to takeover the whole world with their very strong military power."
}



func _ready() -> void:
	var continent = Global.current_continent
	var locked_color := Color(0.2, 1.0, 0.2, 0.35)
	var unlocked_color := Color(0.2, 1.0, 0.2, 1.0)
	arrow_to_puzzle_2.modulate = locked_color
	arrow_to_puzzle_3.modulate = locked_color
	
	if Global.continent_accuire[continent][0] >= 1:
		arrow_to_puzzle_2.modulate = unlocked_color
	
	if Global.continent_accuire[continent][0] >= 2:
		arrow_to_puzzle_3.modulate = unlocked_color
	
	await assign_lore()
	setup_buttons()
	_play_intro()

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
					btn.modulate = Color(0.4, 0.8, 0.4, 0.5)
					btn.text = assign_image_to_button(puzzle_id) + " [LOCKED]"
				elif puzzle_data["state"] == "COMPLETED":
					btn.disabled = true
					btn.modulate = Color(0.5, 1.0, 0.6, 0.9)
					btn.text = assign_image_to_button(puzzle_id) + " [DONE]"
				else:
					btn.disabled = false
					btn.modulate = Color(1, 1, 1, 1)
					btn.text = assign_image_to_button(puzzle_id)
					
					# Disconnect to prevent errors if this is called multiple times
					if btn.pressed.is_connected(_on_puzzle_pressed):
						btn.pressed.disconnect(_on_puzzle_pressed)
					
					btn.pressed.connect(_on_puzzle_pressed.bind(diff, puzzle_id))
					_bind_button_fx(btn)
				
				index += 1

func _play_intro() -> void:
	var buttons_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for i in range(tier_buttons.size()):
		var btn: Button = tier_buttons[i]
		var target_alpha = btn.modulate.a
		btn.modulate.a = 0.0
		var delay = 0.08 * i
		buttons_tween.tween_property(btn, "modulate:a", target_alpha, 0.2).set_delay(delay)

func _bind_button_fx(btn: Button) -> void:
	if not btn.mouse_entered.is_connected(_on_puzzle_mouse_entered):
		btn.mouse_entered.connect(_on_puzzle_mouse_entered.bind(btn))
	if not btn.mouse_exited.is_connected(_on_puzzle_mouse_exited):
		btn.mouse_exited.connect(_on_puzzle_mouse_exited.bind(btn))

func _on_puzzle_mouse_entered(btn: Button) -> void:
	if btn.disabled:
		return
	_tween_button(btn, Color(0.6, 1, 0.6, 1))

func _on_puzzle_mouse_exited(btn: Button) -> void:
	if btn.disabled:
		return
	_tween_button(btn, Color(1, 1, 1, 1))

func _tween_button(btn: Button, target_color: Color) -> void:
	if _button_tweens.has(btn):
		_button_tweens[btn].kill()
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_button_tweens[btn] = tween
	tween.tween_property(btn, "modulate", target_color, 0.12)

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
		await get_tree().process_frame
		is_animation_finish = true


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
