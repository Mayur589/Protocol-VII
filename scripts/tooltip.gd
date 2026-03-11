extends CanvasLayer

@onready var panel = get_node_or_null("displayContainer")
@onready var label = get_node_or_null("displayContainer/message")
var tween: Tween

func _ready():
	if panel:
		panel.hide()
		# This ensures the tooltip doesn't block the mouse
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if label:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		printerr("ERROR: Tooltip script cannot find 'displayContainer'. Check your scene tree!")

func _process(_delta):
	if is_instance_valid(panel) and panel.visible:
		_reposition()

func _enter_tree():
	_force_hide()

func _force_hide():
	if is_instance_valid(panel):
		panel.hide()

func display(con_res):
	if not is_instance_valid(panel) or not is_instance_valid(label): 
		return
	
	label.clear()
	if tween: tween.kill() 
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var stats = _get_continent_stats(con_res.Name)
	
	
	# --- HEADER ---
	label.text = "[center][outline_size=6][outline_color=#000000][font_size=26][b]%s[/b][/font_size][/outline_color][/outline_size][/center]" % con_res.Name.to_upper()
	label.append_text("[center][color=#888888][font_size=14]INTEL REPORT[/font_size][/color][/center]\n")
	label.append_text("[center]──────────────────[/center]\n")
	
	# --- STATS WITH "DATA BARS" ---
	# We use a custom function to create visual bars like [■■■□□]
	label.append_text("\n[font_size=18]")
	label.append_text("[color=#ff4d4d]⚔ MILITARY[/color] [right]%d[/right]\n" % con_res.Military_Power)
	label.append_text("[color=#00ffff]🌐 CYBER[/color]    [right]%d[/right]\n" % con_res.Cyber_strength)
	label.append_text("[color=#ffd700]⚖ POLITICAL[/color][right]%d[/right]\n" % con_res.Political_influence)
	
	# --- PROGRESS ---
	label.append_text("\n[center][color=#32cd32]PUZZLES DECRYPTED[/color][/center]")
	var bar = _create_progress_bar(stats.unlocked, stats.total)
	label.append_text("[center][font_size=20]%s[/font_size][/center]" % bar)
	label.append_text("[center][font_size=14]%d / %d COMPLETED[/font_size][/center]" % [stats.unlocked, stats.total])
	
	panel.modulate.a = 0
	panel.scale = Vector2(0.9, 0.9)
	panel.show()
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.25)
	panel.reset_size()
	_reposition()

# Helper function to create a "Gamer" progress bar using text symbols
func _create_progress_bar(unlocked: int, total: int) -> String:
	if total == 0: return "□□□□□□□□□□"
	var size = 10
	var filled = int(round(float(unlocked) / total * size))
	var bar = ""
	for i in range(size):
		if i < filled:
			bar += "■" # Filled block
		else:
			bar += "□" # Empty block
	return bar


func _reposition():
	panel.reset_size()
	
	var mouse_pos = get_viewport().get_mouse_position()
	var screen_size = get_viewport().get_visible_rect().size
	var margin = 25
	
	var target_pos = mouse_pos + Vector2(margin, margin)
	
	# Flip if too far right
	if target_pos.x + panel.size.x > screen_size.x:
		target_pos.x = mouse_pos.x - panel.size.x - margin
		
	# Flip if too far down
	if target_pos.y + panel.size.y > screen_size.y:
		target_pos.y = mouse_pos.y - panel.size.y - margin
	
	# Clamp to screen
	target_pos.x = clamp(target_pos.x, 10, screen_size.x - panel.size.x - 10)
	target_pos.y = clamp(target_pos.y, 10, screen_size.y - panel.size.y - 10)
		
	panel.global_position = target_pos


func _get_continent_stats(con_name: String) -> Dictionary:
	var unlocked = 0
	var total = 0
	if Global.player_progress.has(con_name):
		var con_data = Global.player_progress[con_name]
		for diff in con_data:
			for puzzle_id in con_data[diff]:
				total += 1
				var state = con_data[diff][puzzle_id]["state"]
				if state == "COMPLETED":
					unlocked += 1
	return {"unlocked": unlocked, "total": total}

func hide_tooltip():
	if not is_instance_valid(panel) or not panel.visible: return
	
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Fade out and shrink slightly before hiding
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(panel, "scale", Vector2(0.95, 0.95), 0.15)
	tween.tween_callback(panel.hide)
