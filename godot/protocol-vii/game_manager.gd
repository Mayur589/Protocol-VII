extends Node

# Global Game State
var trace_level: float = 0.0
var continents_controlled: int = 0
var is_game_over: bool = false
var is_victory: bool = false

# Constants
const MAX_TRACE = 100.0
const WIN_CONTINENT_COUNT = 7

func reset_game():
	trace_level = 0.0
	continents_controlled = 0
	is_game_over = false
	is_victory = false

func add_trace(amount: float):
	trace_level += amount
	print("WARNING: Trace Level increased to ", trace_level, "%")
	if trace_level >= MAX_TRACE:
		is_game_over = true
		print("GAME OVER: Trace Limit Exceeded")

func reduce_trace(amount: float):
	trace_level -= amount
	if trace_level < 0:
		trace_level = 0.0
	print("TRACE REDUCED: Current Level = ", trace_level, "%")

func register_conquest():
	continents_controlled += 1
	print("Continents Controlled: ", continents_controlled, "/", WIN_CONTINENT_COUNT)
	if continents_controlled >= WIN_CONTINENT_COUNT:
		is_victory = true
		print("MISSION SUCCESS: GLOBAL DOMINATION ACHIEVED")
