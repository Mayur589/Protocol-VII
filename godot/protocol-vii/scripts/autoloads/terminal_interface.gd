extends Control

signal puzzle_complete(success)

@onready var output_log = $VBoxContainer/OutputLog
@onready var input_line = $VBoxContainer/InputLine
@onready var puzzle_manager = $PuzzleManager

func _ready():
	input_line.text_submitted.connect(_on_text_submitted)
	puzzle_manager.puzzle_started.connect(_on_puzzle_started)
	puzzle_manager.puzzle_solved.connect(_on_puzzle_solved)
	puzzle_manager.puzzle_failed.connect(_on_puzzle_failed)

func activate(target_data: ContinentData = null):
	show()
	output_log.clear()
	
	print_to_log("[color=#00ff00]PROTOCOL VII TERMINAL ONLINE...[/color]")
	
	if target_data == null:
		target_data = ContinentData.new() # Default
	
	# --- NEW VISUAL LOGIC ---
	if target_data.puzzle_type == "Frequency":
		# Hide text input for visual puzzles
		input_line.hide()
		# Make sure we don't lose focus (Input works globally via _process, but good to be safe)
		grab_focus() 
	else:
		# Show text input for text puzzles
		input_line.show()
		input_line.grab_focus()
		input_line.clear()
		input_line.editable = true
	
	puzzle_manager.start_puzzle_for_continent(target_data)

func _on_text_submitted(new_text: String):
	if new_text.strip_edges() == "": return
	print_to_log("[color=#aaaaaa]> " + new_text + "[/color]")
	input_line.clear()
	puzzle_manager.check_input(new_text)

func print_to_log(bbcode_text: String):
	output_log.append_text(bbcode_text + "\n")

func _on_puzzle_started(prompt: String):
	print_to_log(prompt)

func _on_puzzle_solved():
	print_to_log("[color=green]>>> ACCESS GRANTED.[/color]")
	emit_signal("puzzle_complete", true)

func _on_puzzle_failed(trace_penalty):
	print_to_log("[color=red]>>> ERROR: TRACE ESCALATING...[/color]")
	GameManager.add_trace(trace_penalty)
	
	if GameManager.is_game_over:
		print("Terminal Locked.")
		input_line.editable = false
		emit_signal("puzzle_complete", false)
