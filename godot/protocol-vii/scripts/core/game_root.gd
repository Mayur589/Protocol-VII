extends Node

# ==================================================
# GAME ROOT
# Central authority for:
# - Game state
# - Turn progression
# - Scene visibility
# ==================================================

# -----------------------------
# GAME STATES
# -----------------------------
# These define the high-level mode the game is currently in.
enum GameState {
	WORLD,
	TERMINAL,
	GAME_OVER
}

# Current active game state
var current_state: GameState = GameState.WORLD


# -----------------------------
# TURN SYSTEM
# -----------------------------
# Global turn counter.
# Every meaningful player action increments this.
var turn_count: int = 0


# -----------------------------
# SCENE REFERENCES
# -----------------------------
# Cached references to child scenes.
# GameRoot owns these; they never control state themselves.
@onready var world_map := $WorldMap
@onready var terminal_ui := $TerminalUI


# ==================================================
# GODOT LIFECYCLE
# ==================================================
func _ready() -> void:
	# Initialize the game when the scene starts.
	_initialize_game()


# ==================================================
# INITIALIZATION
# ==================================================
func _initialize_game() -> void:
	# Start turn count at 1 (not 0, feels better for players)
	turn_count = 1
	
	# Ensure correct initial state
	_set_game_state(GameState.WORLD)
	
	# Debug output (temporary, safe to remove later)
	print("Game started")
	print("Turn:", turn_count)


# ==================================================
# GAME STATE MANAGEMENT
# ==================================================
func _set_game_state(new_state: GameState) -> void:
	# Prevent redundant state changes
	if new_state == current_state:
		return
	
	current_state = new_state
	
	# Update scene visibility based on state
	match current_state:
		GameState.WORLD:
			_show_world()
		
		GameState.TERMINAL:
			_show_terminal()
		
		GameState.GAME_OVER:
			_show_game_over()
	
	# Debug output
	print("Game state changed to:", GameState.keys()[current_state])


# -----------------------------
# STATE VISIBILITY HELPERS
# -----------------------------
func _show_world() -> void:
	world_map.visible = true
	terminal_ui.visible = false


func _show_terminal() -> void:
	world_map.visible = false
	terminal_ui.visible = true


func _show_game_over() -> void:
	world_map.visible = false
	terminal_ui.visible = false
	# Later: show Game Over UI


# ==================================================
# TURN PROGRESSION
# ==================================================
func advance_turn() -> void:
	# Increment global turn counter
	turn_count += 1
	
	# Debug output (placeholder for HUD later)
	print("Turn advanced to:", turn_count)


# ==================================================
# TEMPORARY TESTING (REMOVE IN DAY 3)
# ==================================================
func _process(_delta: float) -> void:
	# Simple debug keys for testing state switching.
	# These WILL be removed later.
	if Input.is_action_just_pressed("ui_accept"):
		_set_game_state(GameState.TERMINAL)
	
	if Input.is_action_just_pressed("ui_cancel"):
		_set_game_state(GameState.WORLD)
