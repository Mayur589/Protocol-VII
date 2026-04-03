extends Node2D

const DEFAULT_TINT = Color("a4a4a4")
const HOVER_TINT_BOOST = 0.25
const HOVER_GLOW = 1.6
const GLOW_RADIUS = 3.5
const GLOW_SOFTNESS = 0.45
const GLOW_COLOR = Color(0.25, 1.0, 0.55, 1.0)
const GLOW_SHADER = preload("res://Shader/continent_glow.gdshader")
const CONTINENT_TINTS = {
	"Africa": Color("7fcb7a"),
	"Asia": Color("5db6ff"),
	"Europe": Color("9a8dff"),
	"North_America": Color("f2c14e"),
	"South_America": Color("ff7aa6"),
	"Oceania": Color("4fd1c5"),
	"Antarctica": Color("b7e3ff")
}
@onready var back_arrow: Sprite2D = $BackArrow/Sprite2D

func _ready() -> void:
	for child in get_children():
		for nested_child in child.get_children():
			if nested_child is Area2D:
				_setup_continent(nested_child)
	
func _setup_continent(area: Area2D) -> void:
	if area.has_node("Sprite2D"):
		var sprite: Sprite2D = area.get_node("Sprite2D")
		_ensure_continent_material(sprite)
		_apply_continent_style(sprite, area.get_parent())
		
		area.input_event.connect(_on_continent_input.bind(area.get_parent()))
		area.mouse_entered.connect(_on_continent_hover.bind(sprite))
		area.mouse_exited.connect(_on_continent_exit.bind(sprite))
	
	var parent = area.get_parent()
	parent.con_res.Puzzles = Global.continent_puzzles[parent.con_res.Name]

func _on_continent_input(_viewport: Node, event: InputEvent, _shape_idx: int, continent: Node2D) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if continent.con_res != null:
			Global.current_continent = continent.con_res.Name
			get_tree().change_scene_to_file("res://scenes/UI/puzzle_panel.tscn")
			
# We bind the specific Sprite2D, so we know exactly which one to color
func _on_continent_hover(sprite: Sprite2D) -> void:
	_animate_continent(sprite, true)

func _on_continent_exit(sprite: Sprite2D) -> void:
	_animate_continent(sprite, false)

func _ensure_continent_material(sprite: Sprite2D) -> void:
	var material := sprite.material
	if not (material is ShaderMaterial and material.shader == GLOW_SHADER):
		var shader_material := ShaderMaterial.new()
		shader_material.shader = GLOW_SHADER
		sprite.material = shader_material
		material = shader_material

	sprite.modulate = Color.WHITE
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("glow_strength", 0.0)
	shader_material.set_shader_parameter("glow_radius", GLOW_RADIUS)
	shader_material.set_shader_parameter("glow_softness", GLOW_SOFTNESS)

func _apply_continent_style(sprite: Sprite2D, continent: Node) -> void:
	var continent_name := ""
	if continent != null and "con_res" in continent:
		continent_name = continent.con_res.Name

	var tint: Color = CONTINENT_TINTS.get(continent_name, DEFAULT_TINT)
	var glow_color: Color = tint.lerp(Color.WHITE, 0.4)

	sprite.set_meta("base_tint", tint)
	var shader_material := sprite.material as ShaderMaterial
	shader_material.set_shader_parameter("tint_color", tint)
	shader_material.set_shader_parameter("glow_color", glow_color)

func _animate_continent(sprite: Sprite2D, hovering: bool) -> void:
	if not (sprite.material is ShaderMaterial):
		return

	_kill_hover_tween(sprite)

	var base_tint: Color = sprite.get_meta("base_tint", DEFAULT_TINT)
	var target_tint = base_tint.lerp(Color.WHITE, HOVER_TINT_BOOST) if hovering else base_tint
	var target_glow = HOVER_GLOW if hovering else 0.0
	var shader_material := sprite.material as ShaderMaterial

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT if hovering else Tween.EASE_IN)
	tween.tween_property(shader_material, "shader_parameter/tint_color", target_tint, 0.18)
	tween.parallel().tween_property(shader_material, "shader_parameter/glow_strength", target_glow, 0.18)
	sprite.set_meta("hover_tween", tween)

func _kill_hover_tween(sprite: Sprite2D) -> void:
	if sprite.has_meta("hover_tween"):
		var tween = sprite.get_meta("hover_tween")
		if is_instance_valid(tween):
			tween.kill()


func _on_back_arrow_mouse_entered() -> void:
	back_arrow.modulate = Color.WHITE
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_back_arrow_mouse_exited() -> void:
	back_arrow.modulate = Color("cdcbcf")
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_back_arrow_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/desktop.tscn")
