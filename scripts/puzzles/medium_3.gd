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
var tries_left = 3

# Puzzle Variables
var winning_password = ""
var active_lock_id = ""
var passwords = ["VOID_WALKER", "CYBER_PUNK", "NEURON_X"]

var file_system = {
	"/": {
		"type": "dir",
		"children": {
			"readme.txt": {
				"type": "file", 
				"content": "WARNING: The data extraction tool is heavily monitored.\nTo run it, you must terminate the active security daemon by removing its specific lock file.\nCheck the system logs to identify which daemon is currently ACTIVE."
			},
			".extract.sh": {
				"type": "exe", 
				"content": "BINARY DATA"
			}
			# system_monitor.log and the .lock files will be injected dynamically
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
	print_to_terminal("Objective: Disable the security daemon and run the extraction tool.")
	print_to_terminal("Security level: [b][color=#ff4444]SEVERE[/color][/b]. Tries remaining: " + str(tries_left) + "\n")

func setup_random_scenario():
	winning_password = passwords[randi() % passwords.size()]
	
	# 1. Generate 5 random 3-digit lock IDs
	var lock_ids = []
	for i in range(5):
		lock_ids.append(str(randi() % 900 + 100))
	
	# Pick one to be the active lock
	active_lock_id = lock_ids[randi() % lock_ids.size()]
	
	# 2. Inject the lock files into the file system
	for id in lock_ids:
		file_system["/"]["children"][".lock_" + id] = {
			"type": "file",
			"content": "LOCKED BY DAEMON " + id
		}
	
	# 3. Generate the massive system monitor log
	var log_content = ""
	for i in range(20):
		log_content += "[SYS] Routine memory check passed.\n"
		log_content += "[NET] Handshake with gateway successful.\n"
	
	# Inject the statuses of the daemons into the log
	for id in lock_ids:
		if id == active_lock_id:
			log_content += "[SEC] Daemon " + id + " status: ACTIVE\n"
		else:
			log_content += "[SEC] Daemon " + id + " status: STANDBY\n"
			
	for i in range(20):
		log_content += "[SYS] Disk defragmentation scheduled.\n"
		log_content += "[NET] Dropped packets from unknown origin.\n"

	file_system["/"]["children"]["system_monitor.log"] = {
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

func trigger_hint(level: int):
	hint_level = level
	print_to_terminal("\n[color=#ffa500]--- SYSTEM ASSIST ---[/color]")
	if level == 1:
		print_to_terminal("[color=#888888]Hint 1: Use 'grep ACTIVE system_monitor.log' to find the active daemon ID.[/color]\n")
	elif level == 2:
		print_to_terminal("[color=#888888]Hint 2: Once you know the ID, use 'rm .lock_[ID]' to delete the file, then run './.extract.sh'.[/color]\n")
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
		execute_script(target_script) 
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

		# --- NEW COMMAND: RM (REMOVE) ---
		"rm":
			if arg1 == "":
				print_to_terminal("[color=#ff4444]rm:[/color] missing operand")
				return
			var dir = get_current_dir_data()
			if dir.children.has(arg1):
				# Dictionary's erase() method perfectly simulates deleting a file!
				dir.children.erase(arg1)
				print_to_terminal("[color=#888888]Removed " + arg1 + "[/color]")
			else:
				print_to_terminal("[color=#ff4444]rm:[/color] cannot remove '" + arg1 + "': No such file or directory")

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
			print_to_terminal("  [color=#ffff00]grep[/color]    : Search a file")
			print_to_terminal("  [color=#ffff00]rm[/color]      : Remove/delete a file (e.g., [color=#add8e6]rm old_data.txt[/color])")
			print_to_terminal("  [color=#ffff00]./[/color]      : Execute a program")
			print_to_terminal("  [color=#ffff00]clear[/color]   : Clear the terminal screen")
			
		"clear":
			output_log.clear()
		_:
			print_to_terminal("[color=#ff4444]bash:[/color] " + cmd + ": command not found")

func get_current_dir_data():
	return file_system["/"]

# --- EXECUTION LOGIC ---

func execute_script(script_name: String):
	var dir = get_current_dir_data()
	
	if dir.children.has(script_name):
		if dir.children[script_name].type == "exe":
			if script_name == ".extract.sh":
				# --- THE PUZZLE CHECK ---
				# Check if the active lock file still exists in the dictionary
				var target_lock_name = ".lock_" + active_lock_id
				
				if dir.children.has(target_lock_name):
					print_to_terminal("[color=#ff4444]ERROR: Extraction blocked.[/color]")
					print_to_terminal("[color=#ff4444]Security daemon " + active_lock_id + " is still active.[/color]")
					shake_ui()
				else:
					# Success! The player deleted the correct lock file.
					run_hacking_animation()
			else:
				print_to_terminal("Executed " + script_name)
		else:
			print_to_terminal("[color=#ff4444]bash: ./" + script_name + ": Permission denied[/color]")
	else:
		print_to_terminal("[color=#ff4444]bash: ./" + script_name + ": No such file or directory[/color]")

func run_hacking_animation() -> void:
	is_game_over = true 
	input_line.editable = false
	input_line.release_focus()
	
	print_to_terminal("\n[color=#ffff00]Bypassing security node...[/color]")
	await get_tree().create_timer(0.6).timeout
	print_to_terminal("[color=#00ff00]Extracting secure data [||||||||||] 100%[/color]")
	await get_tree().create_timer(0.8).timeout
	
	print_to_terminal("\n[b][color=#00ffff]SUCCESS: Payload Extracted.[/color][/b]")
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

func _return_to_map():
	get_tree().change_scene_to_file("res://scenes/map.tscn")
