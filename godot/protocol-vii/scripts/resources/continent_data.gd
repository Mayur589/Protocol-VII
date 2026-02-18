extends Resource
class_name ContinentData

@export var name: String = "Continent"
@export_multiline var description: String = ""
@export_enum("Standard", "Aggressive", "Stealthy", "Fortified") var personality: String = "Standard"
@export_enum("HexCode", "Frequency", "NodeLink") var puzzle_type: String = "HexCode"
@export var difficulty_modifier: float = 1.0
@export var trace_speed_multiplier: float = 1.0
