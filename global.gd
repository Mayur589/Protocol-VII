extends Node

var domination: int = 0
var penalty: int = 0
var player_turn: bool = true
var current_continent: String

const ASIA: String = "Asia"
const EUROPE: String = "Europe"
const NORTH_AMERICA: String = "North_America"
const SOUTH_AMERICA: String = "South_America"
const AFRICA: String = "Africa"
const OCEANIA: String = "Oceania"
const ANTARCTICA: String = "Antarctica"

var current_puzzle_diff: String = ""
var current_puzzle_id: String = ""
var omni_awareness: int = 0 

var continent_puzzles: Dictionary = {}


var continent_accuire = {
	"Asia": [0, false],
	"Africa": [0, false],
	"Antarctica": [0, false],
	"Europe": [0, false],
	"North_America": [0, false],
	"South_America": [0, false],
	"Oceania": [0, false],
}
# LOCKED → UNLOCKED → COMPLETED
var player_progress: Dictionary = {
	ASIA: _empty_difficulty_dict(),
	EUROPE: _empty_difficulty_dict(),
	NORTH_AMERICA: _empty_difficulty_dict(),
	SOUTH_AMERICA: _empty_difficulty_dict(),
	AFRICA: _empty_difficulty_dict(),
	OCEANIA: _empty_difficulty_dict(),
	ANTARCTICA: _empty_difficulty_dict(),
}

func _empty_difficulty_dict() -> Dictionary:
	return {
		"EASY": {},
		"MEDIUM": {},
		"HARD": {}
	}

#var puzzles_easy: Array[String] = [
	#"res://scenes/Puzzles/easy_1.tscn",
	#"res://scenes/Puzzles/easy_2.tscn",
	#"res://scenes/Puzzles/easy_3.tscn",
#]
#var puzzles_medium: Array[String] = [
	#"res://scenes/Puzzles/medium_1.tscn",
	#"res://scenes/Puzzles/medium_2.tscn",
	#"res://scenes/Puzzles/medium_3.tscn",
	#"res://scenes/Puzzles/medium_4.tscn",
#]
#
#var puzzles_hard: Array[String] = [
	#"res://scenes/Puzzles/hard_1.tscn",
	#"res://scenes/Puzzles/hard_2.tscn",
	#"res://scenes/Puzzles/hard_3.tscn"
#]

var puzzles_easy: Array[String] = [
	"res://scenes/Puzzles/dummy_puzzle.tscn",
	"res://scenes/Puzzles/dummy_puzzle.tscn",
	"res://scenes/Puzzles/dummy_puzzle.tscn",
]

var puzzles_medium: Array[String] = [
	"res://scenes/Puzzles/dummy_puzzle.tscn",
	"res://scenes/Puzzles/dummy_puzzle.tscn",
	"res://scenes/Puzzles/dummy_puzzle.tscn",
]

var puzzles_hard: Array[String] = [
	"res://scenes/Puzzles/dummy_puzzle.tscn",
	"res://scenes/Puzzles/dummy_puzzle.tscn",
	"res://scenes/Puzzles/dummy_puzzle.tscn",
]



var continents: Array[String] = [
	"res://scenes/Continents/africa.tscn",
	"res://scenes/Continents/asia.tscn",
	"res://scenes/Continents/antarctica.tscn",
	"res://scenes/Continents/europe.tscn",
	"res://scenes/Continents/north_america.tscn",
	"res://scenes/Continents/oceania.tscn",
	"res://scenes/Continents/south_america.tscn",
]

func _ready() -> void:
	for continent in continents:
		var scene = load(continent)
		var instance = scene.instantiate()
		add_child(instance)
		var con_name = instance.con_res.Name
		continent_puzzles[con_name] = assign_puzzles(instance)
		initialize_continent(con_name)
		instance.queue_free()
		

func assign_puzzles(con: Node2D) -> Dictionary:
	var dic = {
		"EASY": {},
		"MEDIUM": {},
		"HARD": {}
	}
	
	var diff_level = con.con_res.Difficulty
	var puzzles_needed = 3
	
	# 1. Create temporary, shuffled pools so we don't pick the exact same puzzle twice
	var pools = {
		"EASY": puzzles_easy.duplicate(),
		"MEDIUM": puzzles_medium.duplicate(),
		"HARD": puzzles_hard.duplicate()
	}
	pools["EASY"].shuffle()
	pools["MEDIUM"].shuffle()
	pools["HARD"].shuffle()
	
	# 2. Pick exactly 3 puzzles
	for i in range(puzzles_needed):
		# Roll the dice to decide which difficulty bucket to pull from
		var chosen_tier = _roll_difficulty(diff_level)
		
		# Fallback: If we ran out of puzzles in that tier, grab from anywhere else
		if pools[chosen_tier].is_empty():
			chosen_tier = _get_fallback_tier(pools)
			if chosen_tier == "": 
				break # Out of puzzles entirely!
				
		# 3. Pop the puzzle from the pool and assign it
		var puzzle_path = pools[chosen_tier].pop_back()
		var short_name = give_short_name(puzzle_path)
		var unique_id = short_name + "_" + str(i)
		
		dic[chosen_tier][unique_id] = puzzle_path
		
	return dic

# The "Loot Drop" Probability Algorithm
func _roll_difficulty(diff_level: int) -> String:
	var roll = randf() # Rolls a random decimal between 0.0 and 1.0
	
	match diff_level:
		1: # Easy Continent: 70% Easy, 30% Medium
			if roll <= 0.70: return "EASY"
			else: return "MEDIUM"
			
		2: # Medium Continent: 20% Easy, 60% Medium, 20% Hard
			if roll <= 0.20: return "EASY"
			elif roll <= 0.80: return "MEDIUM"
			else: return "HARD"
			
		3: # Hard Continent: 30% Medium, 70% Hard
			if roll <= 0.30: return "MEDIUM"
			else: return "HARD"
			
		_:
			return "EASY"

# Safety fallback in case a category runs out of puzzles
func _get_fallback_tier(pools: Dictionary) -> String:
	for tier in ["EASY", "MEDIUM", "HARD"]:
		if not pools[tier].is_empty():
			return tier
	return ""


func give_short_name(addr: String) -> String:
	var parts = addr.split("/")
	var file = parts[-1].split(".")[0] 
	return file 

func initialize_continent(continent: String) -> void:
	
	var puzzles = continent_puzzles.get(continent)
	if puzzles == null:
		return
	
	var first = true
	for diff in puzzles:
		
		if !player_progress[continent][diff].is_empty():
			continue
		
		
		for short_name in puzzles[diff]:
			var path = puzzles[diff][short_name]
			
			if first:
				player_progress[continent][diff][short_name] = {
					"path": path,
					"state": "UNLOCKED"
				}
				first = false
			else:
				player_progress[continent][diff][short_name] = {
					"path": path,
					"state": "LOCKED"
				}

func puzzle_won() -> void:
	var continent = current_continent
	var diff = current_puzzle_diff
	var id = current_puzzle_id
	
	# Mark completed and give player a reward
	player_progress[continent][diff][id]["state"] = "COMPLETED"
	domination += 5
	
	_unlock_next(continent, diff, id)
	_trigger_omni_turn(true) # Pass 'true' because player won


func puzzle_lost() -> void:
	# Keep the puzzle UNLOCKED so they can try again, but penalize them
	penalty += 5
	_trigger_omni_turn(false) # Pass 'false' because player lost


func _unlock_next(continent: String, difficulty: String, completed_id: String) -> void:
	# Define the exact order of progression
	var diff_order = ["EASY", "MEDIUM", "HARD"]
	var current_keys = player_progress[continent][difficulty].keys()
	
	for i in current_keys.size():
		if current_keys[i] == completed_id:
			
			# 1. Is there another puzzle in the CURRENT difficulty tier?
			if i + 1 < current_keys.size():
				var next_id = current_keys[i + 1]
				if player_progress[continent][difficulty][next_id]["state"] == "LOCKED":
					player_progress[continent][difficulty][next_id]["state"] = "UNLOCKED"
			
			# 2. If not, jump to the NEXT available difficulty tier!
			else:
				var start_index = diff_order.find(difficulty) + 1
				
				# Look through the remaining harder tiers
				for j in range(start_index, diff_order.size()):
					var next_diff = diff_order[j]
					var next_keys = player_progress[continent][next_diff].keys()
					
					# If this harder tier actually has puzzles assigned to it
					if next_keys.size() > 0: 
						var first_id_of_next_tier = next_keys[0]
						player_progress[continent][next_diff][first_id_of_next_tier]["state"] = "UNLOCKED"
						return # We found and unlocked the next puzzle, so stop looking!
						
				print("ALL PUZZLES FOR " + continent + " ARE COMPLETED!")
				# This is where you would trigger the "Continent Conquered" logic!
				_conquer_continent(continent)
			break


func _trigger_omni_turn(player_won: bool) -> void:
	player_turn = false
	print("OMNI IS ANALYZING THREAT...")
	
	# Omni Logic: Omni reacts to the player's actions
	if player_won:
		# Omni notices the breach and increases awareness/trace routing
		omni_awareness += 3
		print("Omni trace increased to: ", omni_awareness, "%")
	else:
		# Omni capitalizes on the player's failed attempt
		omni_awareness += 12
		domination = max(0, domination - 5) # Lose some domination
		print("Omni reinforced firewalls.")
	
	# Check for Game Over condition
	if omni_awareness >= 100:
		print("GAME OVER - Omni has traced your location.")
		# get_tree().change_scene_to_file("res://scenes/game_over.tscn")
		return
		
	player_turn = true
	
func _conquer_continent(continent: String) -> void:
	# Your continent_accuire dictionary stores an array: [points/value, is_conquered]
	if continent_accuire.has(continent):
		# Mark it as true (conquered)
		continent_accuire[continent][1] = true
		print(">>> " + continent.to_upper() + " SECURED. OMNI PRESENCE PURGED.")
	
	_check_world_domination()


func _check_world_domination() -> void:
	var total_domination = true
	
	# Loop through every continent to see if ANY are still unconquered
	for cont in continent_accuire.keys():
		if continent_accuire[cont][1] == false:
			total_domination = false
			break
	
	# If the loop finishes and total_domination is STILL true, the player won!
	if total_domination:
		print("=======================================")
		print(" GLOBAL DOMINATION ACHIEVED! YOU WIN! ")
		print("=======================================")
		
		# Uncomment this when you build your victory screen!
		# get_tree().change_scene_to_file("res://scenes/victory.tscn")
