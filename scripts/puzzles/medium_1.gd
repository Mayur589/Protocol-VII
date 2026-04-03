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

var passwords = ["ECLIPSE_99", "NOVA_CORE", "APOLLO_X"]

var file_system = {
	"/": {
		"type": "dir",
		"children": {
			"readme.txt": {"type": "file", "content": "Welcome to the server administration terminal.\nUse the 'help' command if you are lost."},
			"todo.md": {"type": "file", "content": "- Fix coffee machine\n- Rotate admin passwords\n- Clear old server logs (They are getting too big!)"},
			"cat_picture.png": {"type": "file", "content": "[IMAGE DATA CORRUPTED]"},
			"notes.txt": {"type": "file", "content": "Note to self: The admin password was overridden recently. Check the logs."}
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
	print_to_terminal("Objective: Find the hidden password in the logs and login.")
	print_to_terminal("Security level: [b][color=#ffff00]MEDIUM[/color][/b]. Tries remaining: " + str(tries_left) + "\n")

func setup_random_scenario():
	winning_password = passwords[randi() % passwords.size()]
	
	# Generate a massive, unreadable log file
	var log_content = ""
	for i in range(30):
		log_content += "[0" + str(randi() % 9) + ":12:" + str(randi() % 59) + "] SYSTEM NORMAL - ALL SYSTEMS GREEN\n"
		log_content += "[0" + str(randi() % 9) + ":12:" + str(randi() % 59) + "] PING RECEIVED FROM LOCALHOST\n"
	
	# Hide the password right in the middle
	log_content += "[14:02:01] CRITICAL: Admin password overridden to: " + winning_password + "\n"
	
	for i in range(30):
		log_content += "[0" + str(randi() % 9) + ":12:" + str(randi() % 59) + "] ROUTING TABLE UPDATED\n"
		log_content += "[0" + str(randi() % 9) + ":12:" + str(randi() % 59) + "] CONNECTION ALIVE\n"

	# Inject the massive file into the root directory
	file_system["/"]["children"]["server_logs.txt"] = {
		"type": "file", 
		"content": log_content
	}

func print_to_terminal(text: String):
	output_log.append_text(text + "\n")

func _on_command_submitted(new_text: String):
	if is_game_over: return
	
	var input = new_text.strip_edges()
	if input == "": 
		force_focus()
		return
	
	# Use false to remove empty strings if the user types double spaces
	var parts = input.split(" ", false) 
	var cmd = parts[0].to_lower()
	
	# Reconstruct arguments for the colorful prompt echo
	var args_str = ""
	for i in range(1, parts.size()):
		args_str += " " + parts[i]
	
	var colored_prompt = "[color=#00ff00]user@system:[/color][color=#00ffff]" + current_path + "$[/color] "
	var colored_cmd = "[color=#ffff00]" + cmd + "[/color]"
	var colored_arg = "[color=#add8e6]" + args_str + "[/color]" if args_str != "" else ""
	
	print_to_terminal(colored_prompt + colored_cmd + colored_arg)
	input_line.clear()
	
	# Pass the full parts array so process_command can handle 3-word commands
	process_command(cmd, parts) 
	
	if not is_game_over:
		force_focus()

func process_command(cmd, parts):
	# Safely extract arg1 and arg2 if they exist
	var arg1 = parts[1] if parts.size() > 1 else ""
	var arg2 = parts[2] if parts.size() > 2 else ""

	match cmd:
		"ls":
			var dir = get_current_dir_data()
			var list = ""
			var show_hidden = (arg1 == "-a")
			
			for item_name in dir.children.keys():
				if item_name.begins_with(".") and not show_hidden:
					continue
					
				var item_data = dir.children[item_name]
				if item_data.type == "dir":
					list += "[b][color=#5DADE2]" + item_name + "[/color][/b]    " 
				else:
					if item_name.begins_with("."):
						list += "[color=#ffb6c1]" + item_name + "[/color]    "
					else:
						list += "[color=#DDDDDD]" + item_name + "[/color]    " 
			print_to_terminal(list)
			
		"cat":
			if arg1 == "":
				print_to_terminal("[color=#ff4444]cat:[/color] missing file operand")
				return
				
			var dir = get_current_dir_data()
			if dir.children.has(arg1) and dir.children[arg1].type == "file":
				print_to_terminal(dir.children[arg1].content)
			else:
				print_to_terminal("[color=#ff4444]cat:[/color] file not found.")

		"grep":
			if parts.size() < 3:
				print_to_terminal("[color=#ffa500]Usage: grep [search_term] [file][/color]")
				return
				
			# Strip quotes in case they type: grep "password" server_logs.txt
			var search_term = arg1.trim_prefix('"').trim_suffix('"')
			var file_name = arg2
			var dir = get_current_dir_data()
			
			if dir.children.has(file_name) and dir.children[file_name].type == "file":
				var file_lines = dir.children[file_name].content.split("\n")
				var found = false
				
				for line in file_lines:
					if search_term.to_lower() in line.to_lower(): # Case-insensitive search
						# Highlight the matched word in red for a cool visual effect
						var highlighted_line = line.replace(search_term, "[color=#ff4444][b]" + search_term + "[/b][/color]")
						print_to_terminal(highlighted_line)
						found = true
						
				if not found:
					# grep is usually silent if nothing is found, but we'll print a helper message
					print_to_terminal("[color=#888888]No matches found.[/color]")
			else:
				print_to_terminal("[color=#ff4444]grep:[/color] " + file_name + ": No such file or directory")

		"man":
			if arg1 == "ls":
				print_to_terminal("[b]NAME[/b]\n       ls - list directory contents\n\n[b]SYNOPSIS[/b]\n       ls [OPTION]...\n\n[b]DESCRIPTION[/b]\n       List information about the FILEs.\n       [b]-a, --all[/b]\n              do not ignore entries starting with .")
			elif arg1 == "grep":
				print_to_terminal("[b]NAME[/b]\n       grep - print lines that match patterns\n\n[b]SYNOPSIS[/b]\n       grep [PATTERN] [FILE]...\n\n[b]DESCRIPTION[/b]\n       grep searches for PATTERNS in each FILE and prints matching lines.")
			elif arg1 == "":
				print_to_terminal("What manual page do you want? (e.g., 'man ls')")
			else:
				print_to_terminal("No manual entry for " + arg1)

		"login":
			if arg1 == "":
				print_to_terminal("[color=#ffa500]Usage: login [password][/color]")
				return
				
			if arg1 == winning_password:
				trigger_game_won()
			else:
				tries_left -= 1
				shake_ui()
				
				if tries_left <= 0:
					trigger_game_over()
				else:
					print_to_terminal("[color=#ff4444]INVALID PASSWORD. " + str(tries_left) + " TRIES REMAINING.[/color]")

		"help":
			print_to_terminal("--- [b][color=#00ffff]SYSTEM HELP MENU[/color][/b] ---")
			print_to_terminal("  [color=#ffff00]ls[/color]      : List directory contents (use [color=#add8e6]-a[/color] for hidden files)")
			print_to_terminal("  [color=#ffff00]cat[/color]     : Read a file")
			print_to_terminal("  [color=#ffff00]grep[/color]    : Search a file (e.g., [color=#add8e6]grep password logs.txt[/color])")
			print_to_terminal("  [color=#ffff00]man[/color]     : Read a manual page (e.g., [color=#add8e6]man grep[/color])")
			print_to_terminal("  [color=#ffff00]login[/color]   : Submit password (e.g., [color=#add8e6]login PASS[/color])")
			print_to_terminal("  [color=#ffff00]clear[/color]   : Clear the terminal screen")
			
		"clear":
			output_log.clear()
		_:
			print_to_terminal("[color=#ff4444]Unknown command:[/color] " + cmd)

func get_current_dir_data():
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

func _return_to_map():
	get_tree().change_scene_to_file("res://scenes/map.tscn")
