extends Control

@onready var output_history: RichTextLabel = $Background/MarginContainer/VBoxContainer/OutputHistory
@onready var command_input: LineEdit = $Background/MarginContainer/VBoxContainer/InputBar/MarginContainer/HBoxContainer/CommandInput
@onready var prompt_label: Label = $Background/MarginContainer/VBoxContainer/InputBar/MarginContainer/HBoxContainer/PromptLabel

# Styling Constants for the "Warp" look
const COL_CMD_BG = "#24283b" # Dark Blue-Grey for command block
const COL_CMD_TXT = "#7aa2f7" # Cyan for command text
const COL_ERR = "#f7768e"     # Red/Pink for errors
const COL_SUCCESS = "#9ece6a" # Green for success

func _ready():
	_update_prompt()
	
	# Initial Message
	print_block("SYSTEM", "PROTOCOL VII TERMINAL ONLINE", COL_SUCCESS)
	
	# Connect signals
	command_input.text_submitted.connect(_on_text_submitted)
	
	# FORCE FOCUS: Do this at start
	command_input.grab_focus()

func _input(event):
	# FORCE FOCUS: If user clicks anywhere, grab focus back
	if event is InputEventMouseButton and event.pressed:
		command_input.grab_focus()

func _on_text_submitted(new_text: String):
	if new_text.strip_edges() == "":
		# Even if empty, keep focus!
		command_input.call_deferred("grab_focus") 
		return
	
	# 1. Clear input immediately
	command_input.clear()
	
	# 2. Print the User's Command as a stylized "Block"
	# We use a table or simply a colored background for the command line
	var timestamp = Time.get_time_string_from_system()
	var user_block = "[cell][color=#565f89]%s[/color] [bgcolor=%s]  %s  [/bgcolor][/cell]" % [timestamp, COL_CMD_BG, new_text]
	output_history.append_text(user_block + "\n")
	
	# 3. Process the logic
	_process_command(new_text)
	
	# 4. CRITICAL: Re-grab focus immediately after processing
	command_input.call_deferred("grab_focus")

func _process_command(raw_text: String):
	var parts = raw_text.split(" ", false)
	var command = parts[0].to_lower()
	var args = parts.slice(1)
	
	if commands.has(command):
		commands[command].call(args)
	else:
		print_line("[color=" + COL_ERR + "]ERROR: Command not recognized.[/color]")

# --- HELPER FUNCTIONS FOR MODERN LOOK ---

func print_line(text: String):
	# Standard output with a little padding
	output_history.append_text("  " + text + "\n")

func print_block(header: String, body: String, color: String):
	# Prints a distinct block of information
	output_history.append_text("\n[color=%s][b]┌─ %s[/b][/color]\n" % [color, header])
	output_history.append_text("[color=%s]│[/color]  %s\n" % [color, body])
	output_history.append_text("[color=%s]└───────────────────────[/color]\n" % color)

# --- COMMAND DICTIONARY (Keep your game logic here) ---
var commands = {
	"help": _cmd_help,
	"clear": _cmd_clear,
	"list": _cmd_list
}

func _cmd_help(_args):
	print_block("HELP", "Available commands:\n- list\n- connect [node]\n- clear", "#bb9af7")

func _cmd_clear(_args):
	output_history.clear()

func _cmd_list(_args):
	# Example of accessing your GameManager (from previous steps)
	# Ensure GameManager is an Autoload for this to work
	if GameManager: 
		var output = ""
		for key in GameManager.continents:
			output += "- " + GameManager.continents[key]["name"] + "\n"
		print_line(output)

func _update_prompt():
	# If using the GameManager from previous steps:
	if GameManager:
		prompt_label.text = GameManager.get_prompt_text()
	else:
		prompt_label.text = "user@sys:~$ "
