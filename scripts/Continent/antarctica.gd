extends Node2D

@export var con_res: Resource
@export var continent_texture: Texture2D
@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Area2D/Sprite2D

func _ready() -> void:
	if continent_texture != null:
		sprite.texture = continent_texture
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
		
func _on_mouse_entered():
	Tooltip.display(con_res)

func _on_mouse_exited():
	Tooltip.hide_tooltip()

func _exit_tree():
	Tooltip.hide_tooltip()
