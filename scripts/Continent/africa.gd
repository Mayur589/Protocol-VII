extends Node2D

@export var con_res: Resource
@onready var area: Area2D = $Area2D

func _ready() -> void:
	# Ensure the signal is connected
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
		
func _on_mouse_entered():
	Tooltip.display(con_res)

func _on_mouse_exited():
	Tooltip.hide_tooltip()

func _exit_tree():
	Tooltip.hide_tooltip()
