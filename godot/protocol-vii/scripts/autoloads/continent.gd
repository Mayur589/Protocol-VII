extends Control
class_name Continent

# Data Resource
@export var data: ContinentData 

# Fallback name if data is missing
@export var continent_name: String = "Unknown"

enum ControlState { UNCONTROLLED, INFILTRATING, CONTROLLED, LOST }
var current_state: ControlState = ControlState.UNCONTROLLED
var omni_attention: float = 0.0

@onready var texture_button = $TextureButton 
@onready var name_label = $VBoxContainer/NameLabel
@onready var state_label = $VBoxContainer/StateLabel
@onready var attention_bar = $VBoxContainer/AttentionBar

signal continent_selected(continent_data)

func _ready():
	texture_button.pressed.connect(_on_button_pressed)
	if data:
		name_label.text = data.name
		continent_name = data.name # Sync local var
	else:
		name_label.text = continent_name
	
	update_visuals()

func update_visuals():
	attention_bar.value = omni_attention
	
	# Get current style or create new if missing
	var style = texture_button.get_theme_stylebox("normal")
	if style:
		style = style.duplicate()
	else:
		style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.5)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	
	match current_state:
		ControlState.UNCONTROLLED:
			state_label.text = "Status: Uncontrolled"
			style.border_color = Color(0.5, 0.5, 0.5)
			state_label.modulate = Color.WHITE
		ControlState.CONTROLLED:
			state_label.text = "Status: Controlled"
			style.border_color = Color(0.0, 1.0, 0.0)
			state_label.modulate = Color(0.2, 1.0, 0.2)
		ControlState.LOST:
			state_label.text = "Status: OMNI Locked"
			style.border_color = Color(1.0, 0.0, 0.0)
			state_label.modulate = Color(1.0, 0.2, 0.2)

	texture_button.add_theme_stylebox_override("normal", style)
	texture_button.add_theme_stylebox_override("hover", style)

func _on_button_pressed():
	print("Selected: ", continent_name)
	emit_signal("continent_selected", self)
