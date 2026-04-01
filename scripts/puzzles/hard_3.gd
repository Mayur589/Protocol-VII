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

# --- HYDRA PUZZLE VARIABLES ---
var winning_password = ""
var passwords = ["AEGIS_SHIELD", "TITAN_FALL", "CHIMERA_X"]

var daemon_exists: bool = true
var worm_running: bool = true
var current_worm_pid: String = ""
var worm_respawn_timer: float = 0.0

var file_system = {
	"/": {
		"type": "dir",
		"children": {
			"readme.txt": {
				"type": "file", 
				"content": "WARNING: System infected by a self-replicating WORM.\nThe unlocking executable cannot run while the WORM is consuming memory.\nStandard termination commands seem ineffective. It keeps coming back."
			},
			"unlock.exe": {
				"type": "exe", 
				"content": "BINARY DATA"
			},
			".daemon_hydra": {
				"type": "file",
				"content": "while true; do\n  if ! pgrep HYDRA_WORM; then\n    start HYDRA_WORM\n  fi\n  sleep 2\ndone"
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
	print_to_terminal("Objective: Eradicate the malware and unlock the system.")
	print_to_terminal("Security level: [b][color=#ff4444]NIGHTMARE[/color][/b]. Tries remaining: " + str(tries_left) + "\n")

func setup_random_scenario():
	winning_password = passwords[randi() % passwords.size()]
	generate_new_worm_pid()

func generate_new_worm_pid():
	# Generates a random 4-digit process ID
	current_worm_pid = str(randi() % 9000 + 1000)

func _process(delta: float) -> void:
	if is_game_over: return
	
	time_elapsed += delta
	
	# --- THE HYDRA RESPAWN LOGIC ---
	if daemon_exists and not worm_running:
		worm_respawn_timer += delta
		# The worm comes back to life 3 seconds after being killed!
		if worm_respawn_timer >= 3.0:
			worm_running = true
			generate_new_worm_pid()
			print_to_terminal("\n[color=#ff4444][SYSTEM ALERT] Malware detected in memory. HYDRA_WORM has respawned.[/color]")
			shake_ui()
			force_focus()
	
	# Hints
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
		print_to_terminal("[color=#888888]Hint 1: Type [b]ps[/b] to see running processes. Use [b]kill [PID][/b] to stop the worm.[/color]\n")
	elif level == 2:
		print_to_terminal("[color=#888888]Hint 2: The worm keeps restarting! There must be a hidden script keeping it alive. Use [b]ls -a[/b][/color]\n")
	elif level == 3:
		print_to_terminal("[color=#888888]Hint 3: Delete the respawner using [b]rm .daemon_hydra[/b], THEN kill the worm, THEN run ./unlock.exe[/color]\n")
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

		"rm":
			if arg1 == "":
				print_to_terminal("[color=#ff4444]rm:[/color] missing operand")
				return
			var dir = get_current_dir_data()
			if dir.children.has(arg1):
				dir.children.erase(arg1)
				print_to_terminal("[color=#888888]Removed " + arg1 + "[/color]")
				
				# If they deleted the daemon, it stops the respawn cycle!
				if arg1 == ".daemon_hydra":
					daemon_exists = false
			else:
				print_to_terminal("[color=#ff4444]rm:[/color] cannot remove '" + arg1 + "': No such file or directory")

		# --- NEW COMMAND: PS (Process Status) ---
		"ps":
			print_to_terminal("[b]  PID TTY          TIME CMD[/b]")
			print_to_terminal("    1 ?        00:00:02 systemd")
			print_to_terminal("  514 tty1     00:00:00 bash")
			
			if worm_running:
				print_to_terminal("[color=#ff4444] " + current_worm_pid + " tty1     00:45:12 HYDRA_WORM[/color]")
			
			print_to_terminal("  " + str(randi() % 900 + 8000) + " tty1     00:00:00 ps")

		# --- NEW COMMAND: KILL ---
		"kill":
			if arg1 == "":
				print_to_terminal("[color=#ffa500]Usage: kill [PID][/color]")
				return
				
			if arg1 == current_worm_pid and worm_running:
				worm_running = false
				worm_respawn_timer = 0.0 # Reset timer for the respawn logic
				print_to_terminal("[color=#888888]Process " + current_worm_pid + " terminated.[/color]")
			elif arg1 == "1" or arg1 == "514":
				print_to_terminal("[color=#ff4444]kill: Permission denied. Cannot kill critical system process.[/color]")
			else:
				print_to_terminal("[color=#ff4444]kill: (" + arg1 + ") - No such process[/color]")

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
			print_to_terminal("  [color=#ffff00]rm[/color]      : Remove a file")
			print_to_terminal("  [color=#ffff00]ps[/color]      : List active system processes (PID)")
			print_to_terminal("  [color=#ffff00]kill[/color]    : Terminate a process by PID (e.g., [color=#add8e6]kill 1234[/color])")
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
			if script_name == "unlock.exe":
				# PUZZLE CHECK: Is the worm still running?
				if worm_running:
					print_to_terminal("[color=#ff4444]ERROR: System memory locked by malicious process.[/color]")
					print_to_terminal("[color=#ff4444]Execution of unlock.exe aborted.[/color]")
					shake_ui()
				else:
					run_hacking_animation()
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
	
	print_to_terminal("\n[color=#ffff00]Memory clear. Executing unlock sequence...[/color]")
	await get_tree().create_timer(0.6).timeout
	print_to_terminal("[color=#00ff00]Bypassing root mainframe [||||||||||] 100%[/color]")
	await get_tree().create_timer(0.8).timeout
	
	print_to_terminal("\n[b][color=#00ffff]SUCCESS: System Unlocked.[/color][/b]")
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
