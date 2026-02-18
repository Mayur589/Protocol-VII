extends Node
class_name GameManagerMain

# --- PATH UPDATED TO MATCH YOUR TREE ---
var action_menu_scene = preload("res://scenes/terminal/action_menu.tscn")

var active_continent = null 

enum TurnState {
	VIEWING_MAP,
	CONTINENT_SELECTED,
	ACTION_CHOSEN,
	TERMINAL_ACTIVE,
	RESOLUTION,
	OMNI_REACTION,
	TURN_END
}

var current_state: TurnState = TurnState.VIEWING_MAP

@onready var map_layer = $MapLayer
@onready var terminal_layer = $TerminalLayer

func _ready():
	terminal_layer.hide()
	map_layer.show()
	
	var global_map = $MapLayer/GlobalMap
	global_map.action_requested.connect(_on_map_action_requested)
	
	enter_state(TurnState.VIEWING_MAP)

# --- STATE MACHINE ---
func enter_state(new_state: TurnState):
	current_state = new_state
	
	match current_state:
		TurnState.VIEWING_MAP:
			print("STATE: Player is looking at the global map.")
			active_continent = null
			
		TurnState.CONTINENT_SELECTED:
			print("STATE: Continent selected. Spawning Action Menu.")
			var menu_instance = action_menu_scene.instantiate()
			map_layer.add_child(menu_instance)
			menu_instance.action_selected.connect(_on_action_chosen)
			menu_instance.menu_cancelled.connect(_on_action_cancelled)
			
		TurnState.ACTION_CHOSEN:
			print("STATE: Action chosen. Booting Terminal...")
			enter_state(TurnState.TERMINAL_ACTIVE)
			
		TurnState.TERMINAL_ACTIVE:
			print("STATE: Terminal Active.")
			map_layer.hide()
			terminal_layer.show()
			
			var terminal = $TerminalLayer/TerminalInterface
			
			# Clean signals
			if terminal.is_connected("puzzle_complete", Callable(self, "_on_puzzle_complete")):
				terminal.disconnect("puzzle_complete", Callable(self, "_on_puzzle_complete"))
			
			terminal.puzzle_complete.connect(_on_puzzle_complete)
			
			# Extract Data safely
			var data_to_pass = null
			if active_continent and "data" in active_continent:
				data_to_pass = active_continent.data
			
			# Activate Terminal with Data
			terminal.activate(data_to_pass)
			
			if active_continent:
				terminal.print_to_log("[color=yellow]INFILTRATING: " + active_continent.continent_name + "...[/color]")
			
		TurnState.RESOLUTION:
			print("STATE: Puzzle solved. Returning to Map.")
			await get_tree().create_timer(1.5).timeout
			terminal_layer.hide()
			map_layer.show()
			enter_state(TurnState.OMNI_REACTION)
			
		TurnState.OMNI_REACTION:
			print("STATE: OMNI is analyzing sector...")
			GameManager.add_trace(2.0) 
			
			if GameManager.is_game_over:
				trigger_game_over_sequence()
			else:
				await get_tree().create_timer(1.0).timeout
				enter_state(TurnState.TURN_END)
			
		TurnState.TURN_END:
			print("STATE: Turn complete. Resetting...")
			enter_state(TurnState.VIEWING_MAP)

# --- SIGNAL LISTENERS ---
func _on_map_action_requested(target_continent):
	if current_state == TurnState.VIEWING_MAP:
		active_continent = target_continent
		print("Target Acquired: ", active_continent.continent_name)
		enter_state(TurnState.CONTINENT_SELECTED)

func _on_action_chosen(action_type):
	match action_type:
		0: # INFILTRATE
			enter_state(TurnState.ACTION_CHOSEN)
		1: # STABILIZE
			print("Action: Stabilizing...")
			GameManager.reduce_trace(15.0)
			enter_state(TurnState.OMNI_REACTION)
		2: # DELAY
			print("Action: Delaying OMNI...")
			enter_state(TurnState.TURN_END)

func _on_action_cancelled():
	enter_state(TurnState.VIEWING_MAP)

func _on_puzzle_complete(success: bool):
	if success:
		if active_continent:
			active_continent.current_state = Continent.ControlState.CONTROLLED
			active_continent.update_visuals()
		
		GameManager.register_conquest()
		
		if GameManager.is_victory:
			trigger_victory_sequence()
		else:
			enter_state(TurnState.RESOLUTION)
	else:
		if GameManager.is_game_over:
			trigger_game_over_sequence()
		else:
			print("Hack Aborted/Failed. Returning to Map.")
			terminal_layer.hide()
			map_layer.show()
			enter_state(TurnState.VIEWING_MAP)

# --- GAME END SEQUENCES ---
func _process(_delta):
	if GameManager.is_game_over and current_state != TurnState.TURN_END:
		trigger_game_over_sequence()

func trigger_game_over_sequence():
	terminal_layer.hide()
	map_layer.hide()
	var label = Label.new()
	label.text = "SIGNAL LOST // MISSION FAILED"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 64)
	label.modulate = Color.RED
	add_child(label)
	current_state = TurnState.TURN_END
	set_process(false)

func trigger_victory_sequence():
	terminal_layer.hide()
	map_layer.hide()
	var label = Label.new()
	label.text = "GLOBAL DOMINATION ACHIEVED"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 64)
	label.modulate = Color.GREEN
	add_child(label)
	current_state = TurnState.TURN_END
	set_process(false)
