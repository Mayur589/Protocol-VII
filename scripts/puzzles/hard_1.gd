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

# Give them more tries for this one, as SQLi requires trial and error
var tries_left: int = 10 

# Puzzle Variables
var winning_password = ""
var admin_user = ""
var admins = ["sys_admin", "root_user", "db_master"]
var tokens = ["OMEGA_KEY", "QUANTUM_HASH", "GHOST_TOKEN"]

var file_system = {
	"/": {
		"type": "dir",
		"children": {
			"readme.txt": {
				"type": "file", 
				"content": "CRITICAL: The main login server is down. \nTo retrieve the emergency access token, you must use the local database administration tool.\nEnsure you have the correct admin username before attempting access."
			},
			".db_admin.sh": {
				"type": "exe", 
				"content": "BINARY DATA"
			},
			".db_admin.src": {
				"type": "file",
				"content": "==== SOURCE CODE RECOVERED ====\n#!/bin/bash\nUSER=$1\nPASS=$2\n\n# Vulnerable Query String Construction\nQUERY=\"SELECT token FROM users WHERE user='\" + USER + \"' AND pass='\" + PASS + \"';\"\n\nexecute_sql(QUERY)\n==============================="
			}
			# access.log will be injected dynamically
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
	print_to_terminal("Objective: Retrieve the access token from the local database.")
	print_to_terminal("Security level: [b][color=#ff4444]EXTREME[/color][/b]. Tries remaining: " + str(tries_left) + "\n")

func setup_random_scenario():
	winning_password = tokens[randi() % tokens.size()]
	admin_user = admins[randi() % admins.size()]
	
	# Generate an access log containing the username
	var log_content = "08:14 - User j_smith logged out.\n"
	log_content += "08:42 - Failed login attempt for user: " + admin_user + "\n"
	log_content += "09:01 - Database backup completed.\n"
	log_content += "09:15 - Connection timeout on port 3306.\n"

	file_system["/"]["children"]["access.log"] = {
		"type": "file", 
		"content": log_content
	}

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
		print_to_terminal("[color=#888888]Hint 1: Check the 'access.log' to find the administrator's username.[/color]\n")
	elif level == 2:
		print_to_terminal("[color=#888888]Hint 2: Read '.db_admin.src'. The script directly pastes your input into the SQL query without checking it.[/color]\n")
	elif level == 3:
		print_to_terminal("[color=#888888]Hint 3: SQL Injection! If you make the password [color=#ffffff]' OR 1=1 --[/color] the query will always be true.[/color]\n")
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
		# We need the ENTIRE rest of the string as the password payload to handle spaces in SQLi
		var pass_payload = ""
		for i in range(2, parts.size()):
			pass_payload += parts[i] + " "
		pass_payload = pass_payload.strip_edges()
		
		execute_script(target_script, arg1, pass_payload) 
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

		"grep":
			if parts.size() < 3:
				print_to_terminal("[color=#ffa500]Usage: grep [search_term] [file][/color]")
				return
			var search_term = arg1.trim_prefix('"').trim_suffix('"')
			var file_name = arg2
			var dir = get_current_dir_data()
			if dir.children.has(file_name) and dir.children[file_name].type == "file":
				var file_lines = dir.children[file_name].content.split("\n")
				var found = false
				for line in file_lines:
					if search_term.to_lower() in line.to_lower(): 
						var highlighted_line = line.replace(search_term, "[color=#ff4444][b]" + search_term + "[/b][/color]")
						print_to_terminal(highlighted_line)
						found = true
				if not found:
					print_to_terminal("[color=#888888]No matches found.[/color]")
			else:
				print_to_terminal("[color=#ff4444]grep:[/color] " + file_name + ": No such file or directory")

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
			print_to_terminal("  [color=#ffff00]grep[/color]    : Search a file")
			print_to_terminal("  [color=#ffff00]./[/color]      : Execute a program (e.g., [color=#add8e6]./script.sh user pass[/color])")
			print_to_terminal("  [color=#ffff00]clear[/color]   : Clear the terminal screen")
			
		"clear":
			output_log.clear()
		_:
			print_to_terminal("[color=#ff4444]bash:[/color] " + cmd + ": command not found")

func get_current_dir_data():
	return file_system["/"]

# --- EXECUTION & SQL INJECTION LOGIC ---

func execute_script(script_name: String, user_input: String, pass_input: String):
	var dir = get_current_dir_data()
	
	if dir.children.has(script_name):
		if dir.children[script_name].type == "exe":
			if script_name == ".db_admin.sh":
				
				if user_input == "" or pass_input == "":
					print_to_terminal("[color=#ffa500]Usage: ./.db_admin.sh [username] [password][/color]")
					return
				
				var simulated_query = "SELECT token FROM users WHERE user='" + user_input + "' AND pass='" + pass_input + "';"
				print_to_terminal("\n[color=#888888][DB_ENGINE] Executing: " + simulated_query + "[/color]")
				
				# 2. Check if the injection was successful
				if is_sqli_successful(user_input, pass_input):
					print_to_terminal("[color=#00ff00][DB_ENGINE] Result: 1 Row Returned.[/color]")
					run_hacking_animation()
				else:
					print_to_terminal("[color=#ff4444][DB_ENGINE] Result: 0 Rows Returned. Access Denied.[/color]\n")
					trigger_penalty()
			else:
				print_to_terminal("Executed " + script_name)
		else:
			print_to_terminal("[color=#ff4444]bash: ./" + script_name + ": Permission denied[/color]")
	else:
		print_to_terminal("[color=#ff4444]bash: ./" + script_name + ": No such file or directory[/color]")

func is_sqli_successful(user_input: String, pass_input: String) -> bool:
	# They must have the correct admin username to narrow the scope of the puzzle
	if user_input != admin_user:
		return false
		
	# Clean up the password payload to evaluate the logic easily
	var p = pass_input.to_upper().replace(" ", "")
	
	# Check for classic SQLi patterns: ' OR 1=1, ' OR 'a'='a, ' OR TRUE
	if p.begins_with("'OR"):
		# Ensure they are equating something to true
		if "1=1" in p or "'A'='A'" in p or "TRUE" in p or "'1'='1" in p:
			# Ensure they comment out the end of the query or close the quote
			if "--" in p or "#" in p or p.ends_with("'"):
				return true
				
	return false

# --- GAME STATE LOGIC ---

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
	
	print_to_terminal("\n[color=#ffff00]Dumping database tables...[/color]")
	await get_tree().create_timer(0.6).timeout
	print_to_terminal("[color=#00ff00]Extracting sys_admin credentials [||||||||||] 100%[/color]")
	await get_tree().create_timer(0.8).timeout
	
	print_to_terminal("\n[b][color=#00ffff]SUCCESS: Record Extracted.[/color][/b]")
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
