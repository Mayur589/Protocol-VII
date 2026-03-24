extends Control

@onready var heading: RichTextLabel = $MarginContainer/VBoxContainer/heading
@onready var commands: RichTextLabel = $MarginContainer/VBoxContainer/commands
@onready var line_edit: LineEdit = $MarginContainer/VBoxContainer/LineEdit
@onready var status_label: RichTextLabel = $MarginContainer/VBoxContainer/status 
@onready var container: MarginContainer = $MarginContainer

var cyber_tasks = {
	"Install BurpSuite": ["sudo apt update", "sudo apt install default-jre", "wget https://portswigger.net/burp/releases/download?product=community&type=Linux", "chmod +x burpsuite_community_linux.sh", "./burpsuite_community_linux.sh"],
	"Nmap Network Scan": ["sudo apt update", "sudo apt install nmap", "ip a", "nmap -sn 192.168.1.0/24", "nmap -sV 192.168.1.1", "nmap -A 192.168.1.1"],
	"Docker Setup": ["sudo apt update", "sudo apt install docker.io", "sudo systemctl start docker", "sudo systemctl enable docker", "sudo docker run hello-world"],
	"Metasploit Installation": ["sudo apt update", "sudo apt install metasploit-framework", "msfconsole", "search exploit", "use exploit/example", "run"],
	"Basic WiFi Recon": ["sudo apt update", "sudo apt install aircrack-ng", "ip link", "sudo airmon-ng start wlan0", "sudo airodump-ng wlan0mon", "sudo airodump-ng --bssid TARGET_BSSID -c CHANNEL wlan0mon"]
}

var current_task_name: String = ""
var current_command_list: Array = []
var current_command_index: int = 0
var max_tries: int = 3
var current_tries: int = 3
var original_position: Vector2

func _ready() -> void:
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	original_position = container.position

	for label in [heading, commands, status_label]:
		label.bbcode_enabled = true
	
	reset_game()

func reset_game() -> void:
	current_tries = max_tries
	update_status_display()
	pick_random_task()
	line_edit.editable = true
	line_edit.grab_focus()

func pick_random_task() -> void:
	var keys = cyber_tasks.keys()
	current_task_name = keys[randi() % keys.size()]
	current_command_list = cyber_tasks[current_task_name]
	current_command_index = 0
	
	heading.text = "[center][b][color=cyan]TASK:[/color][/b] " + current_task_name + "[/center]"
	update_command_display()

func update_status_display() -> void:
	var color = "green"
	if current_tries == 2: color = "yellow"
	if current_tries == 1: color = "red"
	
	status_label.text = "[center]SECURITY STATUS: [b][color=" + color + "]" + str(current_tries) + " TRIES LEFT[/color][/b][/center]"

func update_command_display() -> void:
	var display_text = ""
	for i in range(current_command_list.size()):
		if i < current_command_index:
			display_text += "[color=green][s]" + current_command_list[i] + "[/s][/color]\n"
		elif i == current_command_index:
			display_text += "[b]> " + current_command_list[i] + "[/b]\n"
		else:
			display_text += "[color=gray]" + current_command_list[i] + "[/color]\n"
	commands.text = display_text

func _on_line_edit_text_submitted(new_text: String) -> void:
	var target_command = current_command_list[current_command_index]
	
	if new_text.strip_edges() == target_command:
		current_command_index += 1
		line_edit.clear()
		
		if current_command_index >= current_command_list.size():
			heading.text = "[center][color=yellow]ACCESS GRANTED - UPLOADING DATA...[/color][/center]"
			line_edit.editable = false # Stop input immediately
			await get_tree().create_timer(1.0).timeout
			Global.puzzle_won()
			_return_to_map()
			return 
		else:
			update_command_display()
	else:
		current_tries -= 1
		update_status_display()
		shake_ui()
		line_edit.clear() 
		
		if current_tries <= 0:
			trigger_game_over()
			return 
	
	force_focus()

func force_focus() -> void:
	if not is_inside_tree(): 
		return
		
	line_edit.release_focus()
	await get_tree().process_frame
	if is_inside_tree():
		line_edit.grab_focus()

func trigger_game_over() -> void:
	line_edit.editable = false
	heading.text = "[center][color=red][b]!!! SYSTEM LOCKDOWN !!![/b][/color][/center]"
	commands.text = "[center][color=red]Intrusion Detected. Resetting Connection...[/color][/center]"
	
	await get_tree().create_timer(2.0).timeout
	Global.puzzle_lost()
	_return_to_map()

func shake_ui() -> void:
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(container, "position:x", original_position.x + 10, 0.04)
		tween.tween_property(container, "position:x", original_position.x - 10, 0.04)
	tween.tween_property(container, "position:x", original_position.x, 0.04)

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")
