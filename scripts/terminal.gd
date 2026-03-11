extends Control

@onready var terminal_logs: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var back_arrow: Sprite2D = $VBoxContainer/RichTextLabel/HBoxContainer/BackArrow/Sprite2D
@onready var commands: LineEdit = $VBoxContainer/LineEdit



func _ready() -> void:
	terminal_logs.text = "
	[color=#33ff33]SYSTEM INITIALIZING...[/color]

	[color=#888888]Boot sequence v3.7.12[/color]
	[color=#888888]Loading kernel modules...[/color]
	[color=#888888]Establishing secure uplink...[/color]

	[color=#33ff33]✔ Network connection established[/color]
	[color=#33ff33]✔ Encryption protocol active[/color]
	[color=#ffcc00]⚠ Unauthorized access detected[/color]

	--------------------------------------------
	"
	commands.grab_focus()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_back_arrow_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/computer.tscn")


func _on_back_arrow_mouse_entered() -> void:
	back_arrow.modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_back_arrow_mouse_exited() -> void:
	back_arrow.modulate = Color("cdcbcf")
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
func add_message_on_terminal(msg) -> void:
	terminal_logs.append_text(msg)



func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event is InputEvent:
		if event.is_action("ui_enter") and event.is_pressed():
			var text = commands.text
			command_interpreter(text)
			
func command_interpreter(text) -> void:
	var command = text.split(" ")
	
	if len(command) <= 1:
		print("Not a valid command")
		return
	
	match command[0]:
		"view":
			print("view")
		"help":
			print("help")
		"solve":
			print("solve")
		#"conquer":
			#match command[1]:
				#Global.ASIA:
					#init_puzzle(Global.ASIA)
						#
				#Global.AFRICA:
					#init_puzzle(Global.AFRICA)
								#
				#Global.ANTARCTICA:
					#init_puzzle(Global.ANTARCTICA)
								#
				#Global.SOUTH_AMERICA:
					#init_puzzle(Global.SOUTH_AMERICA)
								#
				#Global.NORTH_AMERICA:
					#init_puzzle(Global.NORTH_AMERICA)
								#
				#Global.EUROPE:
					#init_puzzle(Global.EUROPE)
								#
				#Global.OCEANIA:
					#init_puzzle(Global.OCEANIA)
				#_:
					#print("Invalid continent. Try list continent")
		_:
			print("Invalid command")


#func init_puzzle(continent_name: String):
	#var priority = ["EASY", "MEDIUM", "HARD"]
	#var puzzles = Global.continent_puzzles[continent_name]
	#var sorted_puzzles = {}
	#for key in priority:
		#if puzzles.has(key):
			#sorted_puzzles[key] = puzzles[key]
	#
	#for diff in sorted_puzzles:
		#for puzzle in sorted_puzzles[diff]:
			#Global.player_progress[continent_name][diff][puzzle] = [sorted_puzzles[diff][puzzle], false]
				#
	#for diff in sorted_puzzles:
		#for puzzle in sorted_puzzles[diff]:
			#if !Global.player_progress[continent_name][diff][puzzle][1]:
				#print(puzzle)
				#return
#
#func _give_name(puzzle_addr: String, continent_name: String) -> String:
	## res://scenes/Puzzles/hard_1.tscn -> 
	#var addr_part = puzzle_addr.split("/")
	#var diff = addr_part[-1].split(".")[0] # hard_1
	#var Name = continent_name.to_lower() + "_" + diff[0] + diff[-1] #name_h1
	#return Name
	
	
	
	
	
	
