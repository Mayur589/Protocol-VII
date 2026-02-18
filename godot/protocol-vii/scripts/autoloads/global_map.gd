extends Control

@onready var continents = $ContinentsContainer.get_children()
@onready var trace_bar = $GlobalTraceBar

signal action_requested(continent_target)

func _ready():
	for continent in continents:
		if continent is Continent:
			continent.continent_selected.connect(_on_continent_selected)

func _process(_delta):
	if trace_bar:
		trace_bar.value = GameManager.trace_level

func _on_continent_selected(continent_node):
	emit_signal("action_requested", continent_node)
