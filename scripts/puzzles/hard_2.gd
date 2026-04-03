extends Control

@onready var output_log: RichTextLabel = $MarginContainer/VBoxContainer/OutputLog
@onready var prompt_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/PromptLabel
@onready var input_line: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/InputLine
@onready var container: MarginContainer = $MarginContainer

var current_path = "/"
var is_game_over = false
var original_position: Vector2
var time_elapsed: float = 0.0
var hint_level: int = 0
var tries_left: int = 5 

# Puzzle Variables
var winning_password = ""
var env_secret_key = ""
var passwords = ["NEXUS_PROTOCOL", "AURA_SPHERE", "CHRONOS_DRIVE"]

var file_system = {
	"/": {
		"type": "dir",
		"children": {
			"readme.txt": {
				"type": "file", 
				"content": "SYSTEM ALERT: Decryption tool permissions have been revoked to prevent unauthorized access.\nIf you are an admin, restore execute permissions using the 'chmod' utility before running."
			},
			"notes.md": {
				"type": "file",
				"content": "- The master decryption key is no longer stored in plain text files.\n- It has been moved to the secure environment variables. Type 'env' to view them."
			},
			".decrypt.sh": {
				"type": "exe", 
				"content": "BINARY DATA",
				"is_executable": false # THIS IS THE NEW MECHANIC
			}
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
	print_to_terminal("Objective: Restore permissions, find the key, and decrypt the token.")
	print_to_terminal("Security level: [b][color=#ff4444]HARD[/color][/b]. Tries remaining: " + str(tries_left) + "\n")

func setup_random_scenario():
	winning_password = passwords[randi() % passwords.size()]
	
	# Generate a random 6-character alphanumeric key
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	for i in range(6):
		env_secret_key += chars[randi() % chars.length()]

func _process(delta: float) -> void:
	if is_game_over: return
	time_elapsed += delta
	
	if time_elapsed > 60.0 and hint_level == 0:
		trigger_hint(1)
	elif time_elapsed > 120.0 and hint_level == 1:
		trigger_hint(2)
	elif time_elapsed > 180.0 and hint_level == 2:
		trigger_hint(3)

func trigger_hint(level: int):
	hint_level = level
	print_to_terminal("\n[color=#ffa500]--- SYSTEM ASSIST ---[/color]")
	if level == 1:
		print_to_terminal("[color=#888888]Hint 1: Find the hidden script and make it executable by typing [b]chmod +x .decrypt.sh[/b][/color]\n")
	elif level == 2:
		print_to_terminal("[color=#888888]Hint 2: Type [b]env[/b] to view background variables and locate the MASTER_KEY.[/color]\n")
	elif level == 3:
		print_to_terminal("[color=#888888]Hint 3: Run the script and pass the key to it: [b]./.decrypt.sh [YOUR_KEY][/b][/color]\n")
	force_focus()

func print_to_terminal(text: String):
	output_log.append_text(text + "\n")

func _on_command_submitted(new_text: String):
	if is_game_over: return
	var input = new_text.strip_edges()
	if input == "": 
		force_focus()
		return
		
	time_elapsed = 0.0 
	var parts = input.split(" ", false) 
	var cmd = parts[0].to_lower()
	
	var args_str = ""
	for i in range(1, parts.size()):
		args_str += " " + parts[i]
	
	var colored_prompt = "[color=#00ff00]user@system:[/color][color=#00ffff]" + current_path + "$[/color] "
	var colored_cmd = "[color=#ffff00]" + cmd + "[/color]"
	var colored_arg = "[color=#add8e6]" + args_str + "[/color]" if args_str != "" else ""
	
	print_to_terminal(colored_prompt + colored_cmd + colored_arg)
	input_line.clear()
	process_command(cmd, parts) 
	if not is_game_over: force_focus()

func process_command(cmd, parts):
	var arg1 = parts[1] if parts.size() > 1 else ""
	var arg2 = parts[2] if parts.size() > 2 else ""

	if cmd.begins_with("./"):
		var target_script = cmd.trim_prefix("./")
		execute_script(target_script, arg1) 
		return

	match cmd:
		"ls":
			var dir = get_current_dir_data()
			var list = ""
			var show_hidden = (arg1 == "-a")
			for item_name in dir.children.keys():
				if item_name.begins_with(".") and not show_hidden: continue
				var item_data = dir.children[item_name]
				
				if item_data.type == "dir":
					list += "[b][color=#5DADE2]" + item_name + "[/color][/b]    " 
				elif item_data.type == "exe":
					# VISUAL CLUE: If it is not executable, it prints like a normal text file
					if item_data.has("is_executable") and not item_data.is_executable:
						list += "[color=#DDDDDD]" + item_name + "[/color]    "
					else:
						# Once chmod +x is run, it turns green!
						list += "[b][color=#00ff00]" + item_name + "[/color][/b]    " 
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
			if dir.children.has(arg1):
				if dir.children[arg1].type == "exe":
					print_to_terminal("[color=#ff4444]cat:[/color] cannot read binary/executable file.")
				else:
					print_to_terminal(dir.children[arg1].content)
			else:
				print_to_terminal("[color=#ff4444]cat:[/color] file not found.")

		# --- NEW COMMAND: CHMOD ---
		"chmod":
			if arg1 == "" or arg2 == "":
				print_to_terminal("[color=#ffa500]Usage: chmod [permissions] [file][/color]")
				print_to_terminal("Example: chmod +x script.sh")
				return
				
			var dir = get_current_dir_data()
			if dir.children.has(arg2):
				if arg1 == "+x":
					if dir.children[arg2].type == "exe":
						dir.children[arg2].is_executable = true
						print_to_terminal("[color=#888888]Permissions updated. Execution rights granted to " + arg2 + "[/color]")
					else:
						print_to_terminal("[color=#888888]Permissions updated. (Note: File is not a binary script)[/color]")
				else:
					print_to_terminal("[color=#ff4444]chmod:[/color] unsupported permission flag. Try '+x'.")
			else:
				print_to_terminal("[color=#ff4444]chmod:[/color] cannot access '" + arg2 + "': No such file or directory")

		# --- NEW COMMAND: ENV ---
		"env":
			print_to_terminal("USER=admin")
			print_to_terminal("HOME=/root")
			print_to_terminal("TERM=xterm-256color")
			print_to_terminal("PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
			print_to_terminal("[b][color=#00ff00]MASTER_KEY=" + env_secret_key + "[/color][/b]")
			print_to_terminal("LANG=en_US.UTF-8")

		"login":
			if arg1 == "":
				print_to_terminal("[color=#ffa500]Usage: login [password_token][/color]")
				return
			if arg1 == winning_password:
				trigger_game_won()
			else:
				trigger_penalty()

		"help":
			print_to_terminal("--- [b][color=#00ffff]SYSTEM HELP MENU[/color][/b] ---")
			print_to_terminal("  [color=#ffff00]ls[/color]      : List directory contents (use [color=#add8e6]-a[/color] for hidden files)")
			print_to_terminal("  [color=#ffff00]cat[/color]     : Read a file")
			print_to_terminal("  [color=#ffff00]chmod[/color]   : Change file permissions (e.g., [color=#add8e6]chmod +x .decrypt.sh[/color])")
			print_to_terminal("  [color=#ffff00]env[/color]     : Print environment variables")
			print_to_terminal("  [color=#ffff00]./[/color]      : Execute a program (e.g., [color=#add8e6]./.decrypt.sh KEY[/color])")
			print_to_terminal("  [color=#ffff00]login[/color]   : Submit password (e.g., [color=#add8e6]login PASS[/color])")
			print_to_terminal("  [color=#ffff00]clear[/color]   : Clear the terminal screen")
			
		"clear":
			output_log.clear()
		_:
			print_to_terminal("[color=#ff4444]bash:[/color] " + cmd + ": command not found")

func get_current_dir_data():
	return file_system["/"]

# --- EXECUTION LOGIC ---

func execute_script(script_name: String, passed_arg: String):
	var dir = get_current_dir_data()
	
	if dir.children.has(script_name):
		if dir.children[script_name].type == "exe":
			
			# 1. Check if the file is executable!
			if dir.children[script_name].has("is_executable") and dir.children[script_name].is_executable == false:
				print_to_terminal("[color=#ff4444]bash: ./" + script_name + ": Permission denied[/color]")
				print_to_terminal("[color=#888888](Hint: Check file execution permissions)[/color]")
				shake_ui()
				return
			
			# 2. If it is executable, check the puzzle arguments
			if script_name == ".decrypt.sh":
				if passed_arg == "":
					print_to_terminal("[color=#ff4444]FATAL: Missing Master Key.[/color]")
					print_to_terminal("Usage: ./.decrypt.sh [KEY]")
				elif passed_arg == env_secret_key:
					run_hacking_animation()
				else:
					print_to_terminal("[color=#ff4444]ERROR: Decryption failed. Invalid Master Key.[/color]")
					shake_ui()
			else:
				print_to_terminal("Executed " + script_name)
		else:
			print_to_terminal("[color=#ff4444]bash: ./" + script_name + ": Permission denied[/color]")
	else:
		print_to_terminal("[color=#ff4444]bash: ./" + script_name + ": No such file or directory[/color]")

func trigger_penalty() -> void:
	tries_left -= 1
	shake_ui()
	if tries_left <= 0:
		trigger_game_over()
	else:
		print_to_terminal("[color=#ff4444]WARNING: " + str(tries_left) + " TRIES REMAINING BEFORE LOCKDOWN.[/color]\n")

func run_hacking_animation() -> void:
	is_game_over = true 
	input_line.editable = false
	input_line.release_focus()
	
	print_to_terminal("\n[color=#ffff00]Validating Master Key...[/color]")
	await get_tree().create_timer(0.6).timeout
	print_to_terminal("[color=#00ff00]Decrypting token hashes [||||||||||] 100%[/color]")
	await get_tree().create_timer(0.8).timeout
	
	print_to_terminal("\n[b][color=#00ffff]SUCCESS: Data Decrypted.[/color][/b]")
	print_to_terminal("The generated access token is: [b][color=#ffff00]" + winning_password + "[/color][/b]")
	print_to_terminal("Please use the 'login' command to proceed.\n")
	
	is_game_over = false
	input_line.editable = true
	force_focus()

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

func _return_to_map():
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func force_focus() -> void:
	if not is_inside_tree() or is_game_over: return
	input_line.release_focus()
	await get_tree().process_frame
	if is_inside_tree() and not is_game_over:
		input_line.grab_focus()

func shake_ui() -> void:
	if not container: return
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(container, "position:x", original_position.x + 10, 0.04)
		tween.tween_property(container, "position:x", original_position.x - 10, 0.04)
	tween.tween_property(container, "position:x", original_position.x, 0.04)
