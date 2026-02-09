extends Node

# --- GDD: CORE VARIABLES ---
var trace_level: float = 0.0          # 0.0 to 100.0 (Failure condition)
var current_turn: int = 1
var player_name: String = "OPERATOR"

# --- GDD: WORLD STRUCTURE ---
# We define the 7 continents and their initial state
var continents = {
	"na": {"name": "North America", "control": 0.0, "omni_attention": 10.0, "status": "LOCKED"},
	"sa": {"name": "South America", "control": 0.0, "omni_attention": 5.0,  "status": "OPEN"},
	"eu": {"name": "Europe",        "control": 0.0, "omni_attention": 40.0, "status": "LOCKED"},
	"af": {"name": "Africa",        "control": 0.0, "omni_attention": 5.0,  "status": "OPEN"},
	"as": {"name": "Asia",          "control": 0.0, "omni_attention": 60.0, "status": "LOCKED"},
	"oc": {"name": "Oceania",       "control": 0.0, "omni_attention": 10.0, "status": "OPEN"},
	"an": {"name": "Antarctica",    "control": 0.0, "omni_attention": 0.0,  "status": "HIDDEN"}
}

# --- GDD: GAME STATES ---
enum State { GLOBAL_VIEW, CONTINENT_VIEW, PUZZLE_ACTIVE }
var current_state = State.GLOBAL_VIEW
var connected_continent: String = "" # Tracks which continent we are currently "in"

# --- CORE FUNCTIONS ---

func advance_turn():
	current_turn += 1
	# GDD: "World events and OMNI actions trigger at turn end"
	_trigger_omni_reaction()
	
func _trigger_omni_reaction():
	# Simple logic: OMNI Trace increases slightly every turn
	trace_level += 2.5
	if trace_level > 100.0:
		trace_level = 100.0
		# Trigger Game Over Logic here later

func get_prompt_text() -> String:
	# Dynamic prompt based on state
	match current_state:
		State.GLOBAL_VIEW:
			return "prot_vii@global:~$ "
		State.CONTINENT_VIEW:
			return "prot_vii@%s:~$ " % connected_continent
		State.PUZZLE_ACTIVE:
			return "OMNI_INTERCEPT:: "
	return "> "
