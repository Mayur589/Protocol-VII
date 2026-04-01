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
var tries_left: int = 3 # Added tries back

# Base file system with our hidden executable AND a decoy
var file_system = {
	"/": {
		"type": "dir",
		"children": {
			"readme.txt": {
				"type": "file", 
				"content": "Welcome Admin.\n\nNotice: Direct login has been disabled due to security protocols. Only authorized automated scripts can bypass the firewall now."
			},
			"todo.md": {
				"type": "file", 
				"content": "- Fix coffee machine\n- Hide the firewall bypass script\n- Update server logs"
			},
			"notes.txt": {
				"type": "file", 
				"content": "Note to self: I hid the bypass tool so standard users can't see it. Remember to use the 'all' flag when listing files.\n\nWARNING: Do not accidentally run the honeypot script, or the system will lock down."
			},
			".bypass.sh": {
				"type": "exe", 
				"content": "BINARY DATA - CANNOT READ IN PLAIN TEXT"
			},
			".honeypot.sh": {
				"type": "exe", 
				"content": "SECURITY TRAP"
			}
		}
	}
}

func _ready() -> void:
	original_position = container.position
	output_log.bbcode_enabled = true 
	
	force_focus()
	input_line.text_submitted.connect(_on_command_submitted)
	
	print_to_terminal("[color=#888888]Workspace Initialized...[/color]")
	print_to_terminal("Objective: Bypass the firewall.")
	print_to_terminal("Security level: [b][color=#ffff00]MEDIUM[/color][/b]. Tries remaining: " + str(tries_left) + "\n")

func _process(delta: float) -> void:
	if is_game_over: return
	
	time_elapsed += delta
	
	if time_elapsed > 45.0 and hint_level == 0:
		trigger_hint(1)
	elif time_elapsed > 90.0 and hint_level == 1:
		trigger_hint(2)

func trigger_hint(level: int):
	hint_level = level
	print_to_terminal("\n[color=#ffa500]--- SYSTEM ASSIST ---[/color]")
	
	if level == 1:
		print_to_terminal("[color=#888888]Notice: User seems idle. Have you tried reading the notes? Type [b]cat notes.txt[/b][/color]\n")
	elif level == 2:
		print_to_terminal("[color=#888888]Notice: To see hidden files, use [b]ls -a[/b]. To run a script, type [b]./script_name[/b][/color]\n")
	
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
	
	if not is_game_over:
		force_focus()

func process_command(cmd, parts):
	var arg1 = parts[1] if parts.size() > 1 else ""

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
				if item_name.begins_with(".") and not show_hidden:
					continue
					
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

		"man":
			if arg1 == "ls":
				print_to_terminal("[b]NAME[/b]\n       ls - list directory contents\n[b]DESCRIPTION[/b]\n       [b]-a, --all[/b]\n              do not ignore entries starting with .")
			else:
				print_to_terminal("What manual page do you want? (e.g., 'man ls')")

		"help":
			print_to_terminal("--- [b][color=#00ffff]SYSTEM HELP MENU[/color][/b] ---")
			print_to_terminal("Available Commands:")
			print_to_terminal("  [color=#ffff00]ls[/color]      : List directory contents (use [color=#add8e6]-a[/color] for hidden files)")
			print_to_terminal("  [color=#ffff00]cat[/color]     : Read a file (e.g., [color=#add8e6]cat notes.txt[/color])")
			print_to_terminal("  [color=#ffff00]man[/color]     : Read manual for a command (e.g., [color=#add8e6]man ls[/color])")
			print_to_terminal("  [color=#ffff00]./[/color]      : Execute a program (e.g., [color=#add8e6]./script.sh[/color])")
			print_to_terminal("  [color=#ffff00]clear[/color]   : Clear the terminal screen")
			print_to_terminal("\n[color=#888888]SYSTEM NUDGE: If you are stuck, look for hidden files and read your notes.[/color]")
			
		"clear":
			output_log.clear()
		_:
			print_to_terminal("[color=#ff4444]bash:[/color] " + cmd + ": command not found")

func get_current_dir_data():
	return file_system["/"]

# --- EXECUTION & ANIMATION LOGIC ---

func execute_script(script_name: String):
	var dir = get_current_dir_data()
	
	if dir.children.has(script_name):
		if dir.children[script_name].type == "exe":
			if script_name == ".bypass.sh":
				run_hacking_animation()
			elif script_name == ".honeypot.sh":
				# THIS IS THE TRAP
				trigger_penalty()
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
		print_to_terminal("[color=#ff4444]!!! HONEYPOT TRIGGERED. SECURITY TRACE INITIATED !!![/color]")
		print_to_terminal("[color=#ff4444]WARNING: " + str(tries_left) + " TRIES REMAINING BEFORE LOCKDOWN.[/color]\n")

func run_hacking_animation() -> void:
	is_game_over = true 
	input_line.editable = false
	input_line.release_focus()
	
	print_to_terminal("\n[color=#ffff00]Initiating bypass sequence...[/color]")
	await get_tree().create_timer(0.6).timeout
	
	print_to_terminal("[color=#00ff00]Injecting payload [||||      ] 30%[/color]")
	await get_tree().create_timer(0.5).timeout
	
	print_to_terminal("[color=#00ff00]Cracking hashes   [|||||||   ] 75%[/color]")
	await get_tree().create_timer(0.8).timeout
	
	print_to_terminal("[color=#00ff00]Bypassing node    [||||||||||] 100%[/color]")
	await get_tree().create_timer(0.5).timeout
	
	print_to_terminal("\n[b][color=#00ffff]ACCESS GRANTED - FIREWALL DISABLED[/color][/b]")
	
	await get_tree().create_timer(1.5).timeout
	Global.puzzle_won()
	_return_to_map()

func trigger_game_over() -> void:
	is_game_over = true
	input_line.editable = false
	input_line.release_focus()
	print_to_terminal("\n[b][color=red]!!! SYSTEM LOCKDOWN !!![/color][/b]")
	print_to_terminal("[color=red]Intrusion Detected. Security trace complete. Resetting Connection...[/color]")
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
