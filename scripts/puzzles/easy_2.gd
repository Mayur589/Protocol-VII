extends Control

@onready var output_log: RichTextLabel = $MarginContainer/VBoxContainer/OutputLog
@onready var prompt_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PromptLabel
@onready var input_line: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/InputLine
@onready var container: MarginContainer = $MarginContainer

var current_path = "/"
var winning_password = ""
var tries_left = 3
var is_game_over = false
var original_position: Vector2

# The 3 possible directory setups
var scenarios = [
	{"dir": "vault_alpha", "file": "pass.txt", "pass": "NEON_77"},
	{"dir": "sector_9", "file": "memo.txt", "pass": "GHOST_ROOT"},
	{"dir": "backup_logs", "file": "key.txt", "pass": "VOID_NULL"}
]

var file_system = {
	"/": {
		"type": "dir",
		"children": {
			"readme.txt": {"type": "file", "content": "Find the hidden directory and use 'login [password]' to win."},
		}
	}
}

func _ready() -> void:
	original_position = container.position
	output_log.bbcode_enabled = true 
	
	setup_random_scenario()
	
	# Use the robust focus function right on startup
	force_focus()
	input_line.text_submitted.connect(_on_command_submitted)
	
	print_to_terminal("[color=#888888]System Initialized...[/color]")
	print_to_terminal("Security level: [b][color=#ff4444]HIGH[/color][/b]. Tries remaining: " + str(tries_left) + "\n")

func setup_random_scenario():
	var scenario = scenarios[randi() % scenarios.size()]
	winning_password = scenario["pass"]
	
	file_system["/"]["children"][scenario["dir"]] = {
		"type": "dir",
		"children": {
			scenario["file"]: {"type": "file", "content": "DECRYPTED PASS: [color=#ffff00]" + winning_password + "[/color]"}
		}
	}

func print_to_terminal(text: String):
	output_log.append_text(text + "\n")

func _on_command_submitted(new_text: String):
	if is_game_over: return
	
	var input = new_text.strip_edges()
	if input == "": 
		force_focus() # Keep focus even if they just hit enter on an empty line
		return
	
	var parts = input.split(" ")
	var cmd = parts[0].to_lower()
	var arg = parts[1] if parts.size() > 1 else ""
	
	var colored_prompt = "[color=#00ff00]user@system:[/color][color=#00ffff]" + current_path + "$[/color] "
	var colored_cmd = "[color=#ffff00]" + cmd + "[/color]"
	var colored_arg = " [color=#add8e6]" + arg + "[/color]" if arg != "" else ""
	
	print_to_terminal(colored_prompt + colored_cmd + colored_arg)
	input_line.clear()
	
	process_command(cmd, arg)
	
	# Lock focus back to the input line after processing
	if not is_game_over:
		force_focus()

func process_command(cmd, arg):
	match cmd:
		"ls":
			var dir = get_current_dir_data()
			var list = ""
			for item_name in dir.children.keys():
				var item_data = dir.children[item_name]
				if item_data.type == "dir":
					list += "[b][color=#5DADE2]" + item_name + "[/color][/b]    " 
				else:
					list += "[color=#DDDDDD]" + item_name + "[/color]    " 
			print_to_terminal(list)
			
		"cd":
			var root_children = file_system["/"].children
			if arg == "..":
				current_path = "/"
			elif root_children.has(arg) and root_children[arg].type == "dir":
				current_path = "/" + arg
			else:
				print_to_terminal("[color=#ff4444]error:[/color] directory '" + arg + "' not found.")
			
			prompt_label.text = "user@system:" + current_path + "$"
			
		"cat":
			var dir = get_current_dir_data()
			if dir.children.has(arg) and dir.children[arg].type == "file":
				print_to_terminal(dir.children[arg].content)
			else:
				print_to_terminal("[color=#ff4444]cat:[/color] file not found.")

		"login":
			if arg == "":
				print_to_terminal("[color=#ffa500]Usage: login [password][/color]")
				return
				
			if arg == winning_password:
				trigger_game_won()
			else:
				tries_left -= 1
				shake_ui()
				
				if tries_left <= 0:
					trigger_game_over()
				else:
					print_to_terminal("[color=#ff4444]INVALID PASSWORD. " + str(tries_left) + " TRIES REMAINING.[/color]")

		"help":
			print_to_terminal("Commands: [color=#ffff00]ls[/color], [color=#ffff00]cd[/color], [color=#ffff00]cat[/color], [color=#ffff00]login[/color] [color=#add8e6][pass][/color], [color=#ffff00]clear[/color]")
		"clear":
			output_log.clear()
		_:
			print_to_terminal("[color=#ff4444]Unknown command:[/color] " + cmd)

func get_current_dir_data():
	if current_path == "/":
		return file_system["/"]
	else:
		var folder_name = current_path.replace("/", "")
		return file_system["/"]["children"][folder_name]

# --- ROBUST FOCUS LOGIC ---
func force_focus() -> void:
	if not is_inside_tree() or is_game_over: 
		return
		
	input_line.release_focus()
	await get_tree().process_frame
	
	if is_inside_tree() and not is_game_over:
		input_line.grab_focus()

# --- WIN / LOSS / EFFECTS LOGIC ---
func trigger_game_won() -> void:
	is_game_over = true
	input_line.editable = false
	input_line.release_focus() # Ensure keyboard drops on mobile/stops taking input
	print_to_terminal("\n[b][color=#00ffff]ACCESS GRANTED - UPLOADING DATA...[/color][/b]")
	
	await get_tree().create_timer(1.0).timeout
	Global.puzzle_won()
	_return_to_map()

func trigger_game_over() -> void:
	is_game_over = true
	input_line.editable = false
	input_line.release_focus() # Ensure keyboard drops
	print_to_terminal("\n[b][color=red]!!! SYSTEM LOCKDOWN !!![/color][/b]")
	print_to_terminal("[color=red]Intrusion Detected. Resetting Connection...[/color]")
	
	await get_tree().create_timer(2.0).timeout
	Global.puzzle_lost()
	_return_to_map()

func shake_ui() -> void:
	if not container: return
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(container, "position:x", original_position.x + 10, 0.04)
		tween.tween_property(container, "position:x", original_position.x - 10, 0.04)
	tween.tween_property(container, "position:x", original_position.x, 0.04)

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")
