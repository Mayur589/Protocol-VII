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

# The 3 possible "Messy Desk" scenarios
var scenarios = [
	{"hidden_file": ".key_token", "pass": "ECLIPSE_99"},
	{"hidden_file": ".sys_config", "pass": "NOVA_CORE"},
	{"hidden_file": ".admin_pass", "pass": "APOLLO_X"}
]

# The Messy Desk VFS
var file_system = {
	"/": {
		"type": "dir",
		"children": {
			"readme.txt": {"type": "file", "content": "I lost the password in this mess. I know it's hidden somewhere here. \nHint: Type 'man ls' to read the manual for the list command."},
			"todo.md": {"type": "file", "content": "- Fix coffee machine\n- Hide the security tokens\n- Update server logs"},
			"old_logs.tar.gz": {"type": "file", "content": "[GARBAGE BINARY DATA]"},
			"cat_picture.png": {"type": "file", "content": "[IMAGE DATA CORRUPTED]"},
			"notes.txt": {"type": "file", "content": "Note to self: Never leave passwords in plain sight."},
			"server_config.bak": {"type": "file", "content": "host=127.0.0.1\nport=8080\nuser=admin"},
		}
	}
}

func _ready() -> void:
	original_position = container.position
	output_log.bbcode_enabled = true 
	
	setup_random_scenario()
	force_focus()
	input_line.text_submitted.connect(_on_command_submitted)
	
	print_to_terminal("[color=#888888]Workspace Initialized...[/color]")
	print_to_terminal("Objective: Find the hidden password and login.")
	print_to_terminal("Security level: [b][color=#ffff00]MEDIUM[/color][/b]. Tries remaining: " + str(tries_left) + "\n")

func setup_random_scenario():
	var scenario = scenarios[randi() % scenarios.size()]
	winning_password = scenario["pass"]
	
	# Inject the random hidden file into the root directory
	file_system["/"]["children"][scenario["hidden_file"]] = {
		"type": "file", 
		"content": "DECRYPTED PASS: [color=#ffff00]" + winning_password + "[/color]"
	}

func print_to_terminal(text: String):
	output_log.append_text(text + "\n")

func _on_command_submitted(new_text: String):
	if is_game_over: return
	
	var input = new_text.strip_edges()
	if input == "": 
		force_focus()
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
	
	if not is_game_over:
		force_focus()

func process_command(cmd, arg):
	match cmd:
		"ls":
			var dir = get_current_dir_data()
			var list = ""
			var show_hidden = (arg == "-a") # Check if the -a flag was used
			
			for item_name in dir.children.keys():
				# Skip the file if it starts with '.' AND the user didn't type -a
				if item_name.begins_with(".") and not show_hidden:
					continue
					
				var item_data = dir.children[item_name]
				if item_data.type == "dir":
					list += "[b][color=#5DADE2]" + item_name + "[/color][/b]    " 
				else:
					# Highlight hidden files slightly differently when revealed
					if item_name.begins_with("."):
						list += "[color=#ffb6c1]" + item_name + "[/color]    "
					else:
						list += "[color=#DDDDDD]" + item_name + "[/color]    " 
			print_to_terminal(list)
			
		"cat":
			var dir = get_current_dir_data()
			if dir.children.has(arg) and dir.children[arg].type == "file":
				print_to_terminal(dir.children[arg].content)
			else:
				print_to_terminal("[color=#ff4444]cat:[/color] file not found.")

		"man":
			if arg == "ls":
				print_to_terminal("[b]NAME[/b]\n       ls - list directory contents\n\n[b]SYNOPSIS[/b]\n       ls [OPTION]...\n\n[b]DESCRIPTION[/b]\n       List information about the FILEs (the current directory by default).\n       [b]-a, --all[/b]\n              do not ignore entries starting with . (hidden files)")
			elif arg == "":
				print_to_terminal("What manual page do you want? (e.g., 'man ls')")
			else:
				print_to_terminal("No manual entry for " + arg)

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
			print_to_terminal("Commands: [color=#ffff00]ls[/color] [-a], [color=#ffff00]cat[/color], [color=#ffff00]man[/color] [cmd], [color=#ffff00]login[/color] [pass], [color=#ffff00]clear[/color]")
		"clear":
			output_log.clear()
		_:
			print_to_terminal("[color=#ff4444]Unknown command:[/color] " + cmd)

func get_current_dir_data():
	# For this puzzle, we are staying entirely in the root directory
	return file_system["/"]

# --- WIN / LOSS / EFFECTS LOGIC ---
func force_focus() -> void:
	if not is_inside_tree() or is_game_over: return
	input_line.release_focus()
	await get_tree().process_frame
	if is_inside_tree() and not is_game_over:
		input_line.grab_focus()

func trigger_game_won() -> void:
	is_game_over = true
	input_line.editable = false
	input_line.release_focus()
	print_to_terminal("\n[b][color=#00ffff]ACCESS GRANTED - UPLOADING DATA...[/color][/b]")
	await get_tree().create_timer(1.0).timeout
	Global.puzzle_won()
	_return_to_map()

func trigger_game_over() -> void:
	is_game_over = true
	input_line.editable = false
	input_line.release_focus()
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
