@tool
extends Node3D

const HALF_W := 16.0
const HALF_D := 16.0
const ROOM_HEIGHT := 10.0
const WALL_THICKNESS := 0.4

const TABLE_MAJOR_RADIUS := 3.5
const TABLE_MINOR_RADIUS := 1.0
const MONITOR_RADIUS := 3.5
const MONITOR_COUNT := 8

var _globe: Node3D

func _ready() -> void:
	if Engine.is_editor_hint() or get_child_count() == 0:
		_build_scene()
	
	set_process(not Engine.is_editor_hint())

func _process(delta: float) -> void:
	if _globe == null:
		return
	_globe.rotate_y(TAU * delta / 12.0)

func _build_scene() -> void:
	_clear_children()

	var room_root := _make_group("RoomRoot")
	_build_room(room_root)
	_build_wall_details(room_root)
	_build_ring_table(room_root)
	_build_wall_screens(room_root)
	_build_ceiling_screens(room_root)
	_build_hologram(room_root)
	_build_lights(room_root)
	_build_camera(room_root)

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()

func _make_group(node_name: String, parent: Node = self) -> Node3D:
	var group := Node3D.new()
	group.name = node_name
	parent.add_child(group)
	if Engine.is_editor_hint():
		group.owner = get_tree().edited_scene_root
	return group

func _create_standard_material(
	mat_name: String,
	albedo: Color,
	roughness: float,
	metallic: float = 0.0,
	emission_color: Color = Color.BLACK,
	emission_energy: float = 0.0,
	transparency: BaseMaterial3D.Transparency = BaseMaterial3D.TRANSPARENCY_DISABLED,
	cull_mode: BaseMaterial3D.CullMode = BaseMaterial3D.CULL_BACK
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = mat_name
	material.albedo_color = albedo
	material.roughness = roughness
	material.metallic = metallic
	material.cull_mode = cull_mode
	material.transparency = transparency
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = emission_energy
	return material

func _create_screen_material(color: Color, strength: float) -> ShaderMaterial:
	var shader := Shader.new()
	# REMOVED: depth_draw_alpha_prepass (Invalid in Godot 4)
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
uniform vec4 screen_color : source_color;
uniform float emission_strength;
void fragment() {
	ALBEDO = screen_color.rgb * 0.08;
	EMISSION = screen_color.rgb * emission_strength;
	ALPHA = 1.0;
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("screen_color", color)
	material.set_shader_parameter("emission_strength", strength)
	return material

func _create_hologram_material() -> ShaderMaterial:
	var shader := Shader.new()
	# REMOVED: depth_draw_alpha_prepass (Invalid in Godot 4)
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, fog_disabled;
uniform vec4 glow_color : source_color;
uniform float alpha;
uniform float glow_strength;
uniform float scanline_density;
uniform float grid_density;
uniform float pulse_speed;
void fragment() {
	vec2 uv = UV;
	float scan = 0.65 + 0.35 * sin((uv.y + TIME * pulse_speed) * scanline_density);
	float line_u = 1.0 - smoothstep(0.47, 0.5, abs(fract(uv.x * grid_density) - 0.5));
	float line_v = 1.0 - smoothstep(0.47, 0.5, abs(fract(uv.y * grid_density) - 0.5));
	float grid = max(line_u, line_v);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.4);
	ALBEDO = glow_color.rgb * 0.12;
	EMISSION = glow_color.rgb * (0.35 + fresnel * 1.5 + grid * 0.35) * glow_strength * scan;
	ALPHA = alpha * (0.5 + fresnel * 0.5);
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("glow_color", Color(0.0, 0.8, 1.0, 1.0))
	material.set_shader_parameter("alpha", 0.3)
	material.set_shader_parameter("glow_strength", 2.5)
	material.set_shader_parameter("scanline_density", 120.0)
	material.set_shader_parameter("grid_density", 18.0)
	material.set_shader_parameter("pulse_speed", 1.0)
	return material

func _spawn_box(parent: Node, n_name: String, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, with_col: bool = true) -> Node3D:
	var container := Node3D.new()
	container.name = n_name
	container.position = pos
	container.rotation_degrees = rot
	parent.add_child(container)
	if Engine.is_editor_hint(): container.owner = get_tree().edited_scene_root

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = mat
	container.add_child(mesh_instance)
	if Engine.is_editor_hint(): mesh_instance.owner = get_tree().edited_scene_root

	if with_col:
		var body := StaticBody3D.new()
		container.add_child(body)
		var collision := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		collision.shape = box_shape
		body.add_child(collision)
		if Engine.is_editor_hint():
			body.owner = get_tree().edited_scene_root
			collision.owner = get_tree().edited_scene_root
	return container

func _spawn_plane(parent: Node, n_name: String, size: Vector2, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var container := Node3D.new()
	container.name = n_name
	container.position = pos
	container.rotation_degrees = rot
	parent.add_child(container)
	if Engine.is_editor_hint(): container.owner = get_tree().edited_scene_root

	var mesh_instance := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = size
	mesh_instance.mesh = plane_mesh
	mesh_instance.material_override = mat
	container.add_child(mesh_instance)
	if Engine.is_editor_hint(): mesh_instance.owner = get_tree().edited_scene_root
	return container

func _spawn_cylinder(parent: Node, n_name: String, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var container := Node3D.new()
	container.name = n_name
	container.position = pos
	container.rotation_degrees = rot
	parent.add_child(container)
	if Engine.is_editor_hint(): container.owner = get_tree().edited_scene_root

	var mesh_instance := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = mat
	container.add_child(mesh_instance)
	if Engine.is_editor_hint(): mesh_instance.owner = get_tree().edited_scene_root
	return container

func _spawn_torus(parent: Node, n_name: String, major_r: float, minor_r: float, pos: Vector3, mat: Material) -> Node3D:
	var container := Node3D.new()
	container.name = n_name
	container.position = pos
	parent.add_child(container)
	if Engine.is_editor_hint(): container.owner = get_tree().edited_scene_root

	var mesh_instance := MeshInstance3D.new()
	var torus_mesh := TorusMesh.new()
	# FIX: Godot 4 uses inner_radius and outer_radius
	torus_mesh.inner_radius = major_r - minor_r
	torus_mesh.outer_radius = major_r + minor_r
	
	mesh_instance.mesh = torus_mesh
	mesh_instance.material_override = mat
	container.add_child(mesh_instance)
	if Engine.is_editor_hint(): mesh_instance.owner = get_tree().edited_scene_root
	return container

func _spawn_sphere(parent: Node, n_name: String, radius: float, pos: Vector3, mat: Material) -> Node3D:
	var container := Node3D.new()
	container.name = n_name
	container.position = pos
	parent.add_child(container)
	if Engine.is_editor_hint(): container.owner = get_tree().edited_scene_root

	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	mesh_instance.mesh = sphere_mesh
	mesh_instance.material_override = mat
	container.add_child(mesh_instance)
	if Engine.is_editor_hint(): mesh_instance.owner = get_tree().edited_scene_root
	return container

func _build_room(parent: Node3D) -> void:
	var wall_mat := _create_standard_material("Wall", Color(0.12, 0.12, 0.16), 0.6)
	var floor_mat := _create_standard_material("Floor", Color(0.08, 0.08, 0.10), 0.15, 0.2)
	var ceil_mat := _create_standard_material("Ceil", Color(0.10, 0.10, 0.13), 0.7)

	_spawn_box(parent, "Floor", Vector3(HALF_W * 2.0, WALL_THICKNESS, HALF_D * 2.0), Vector3(0, -WALL_THICKNESS * 0.5, 0), floor_mat)
	_spawn_box(parent, "Ceiling", Vector3(HALF_W * 2.0, WALL_THICKNESS, HALF_D * 2.0), Vector3(0, ROOM_HEIGHT + WALL_THICKNESS * 0.5, 0), ceil_mat)
	_spawn_box(parent, "Wall_Back", Vector3(HALF_W * 2.0 + WALL_THICKNESS * 2.0, ROOM_HEIGHT, WALL_THICKNESS), Vector3(0, 0.5 * ROOM_HEIGHT, HALF_D + WALL_THICKNESS * 0.5), wall_mat)
	_spawn_box(parent, "Wall_Front", Vector3(HALF_W * 2.0 + WALL_THICKNESS * 2.0, ROOM_HEIGHT, WALL_THICKNESS), Vector3(0, 0.5 * ROOM_HEIGHT, -HALF_D - WALL_THICKNESS * 0.5), wall_mat)
	_spawn_box(parent, "Wall_Left", Vector3(WALL_THICKNESS, ROOM_HEIGHT, HALF_D * 2.0), Vector3(-HALF_W - WALL_THICKNESS * 0.5, 0.5 * ROOM_HEIGHT, 0), wall_mat)
	_spawn_box(parent, "Wall_Right", Vector3(WALL_THICKNESS, ROOM_HEIGHT, HALF_D * 2.0), Vector3(HALF_W + WALL_THICKNESS * 0.5, 0.5 * ROOM_HEIGHT, 0), wall_mat)

func _build_wall_details(parent: Node3D) -> void:
	var bank_mat := _create_standard_material("Server_Bank", Color(0.15, 0.15, 0.20), 0.3, 0.9)
	var led_mat := _create_standard_material("Server_LED", Color(0.0, 1.0, 0.4), 0.05, 0.0, Color(0.0, 1.0, 0.4), 3.0)

	for side in [-1.0, 1.0]:
		var x: float = side * 15.2
		for i in range(4):
			var z := -6.0 + float(i) * 4.0
			var bank := _spawn_box(parent, "Server_%d" % i, Vector3(0.8, 3.6, 7.0), Vector3(x, 3.0, z), bank_mat)
			var led_x := 0.41 if side > 0.0 else -0.41
			_spawn_box(bank, "LED", Vector3(0.04, 3.2, 0.10), Vector3(led_x, 0.0, 0.0), led_mat, Vector3.ZERO, false)

func _build_ring_table(parent: Node3D) -> void:
	var table_mat := _create_standard_material("Table_Body", Color(0.08, 0.08, 0.10), 0.2, 0.5)
	var metal_mat := _create_standard_material("Monitor_Metal", Color(0.18, 0.18, 0.20), 0.3, 1.0)
	var screen_mat := _create_screen_material(Color(0.0, 0.8, 1.0), 5.0)

	_spawn_torus(parent, "Ring_Table", TABLE_MAJOR_RADIUS, TABLE_MINOR_RADIUS, Vector3(0, 0.5, 0), table_mat)

	for i in range(MONITOR_COUNT):
		var angle := deg_to_rad(float(i) * 45.0)
		var x := MONITOR_RADIUS * cos(angle)
		var z := MONITOR_RADIUS * sin(angle)
		var orient := rad_to_deg(angle)

		_spawn_box(parent, "M_Stand_%d" % i, Vector3(0.16, 0.16, 0.40), Vector3(x, 1.1, z), metal_mat, Vector3(0, -orient, 0), false)
		_spawn_box(parent, "M_Frame_%d" % i, Vector3(0.10, 1.70, 1.04), Vector3(x, 1.38, z), metal_mat, Vector3(0, -orient, 0), false)
		_spawn_plane(parent, "M_Screen_%d" % i, Vector2(1.2, 0.9), Vector3(x * 0.98, 1.38, z * 0.98), screen_mat, Vector3(0, -orient + 90.0, 90.0))

func _build_wall_screens(parent: Node3D) -> void:
	var frame_mat := _create_standard_material("Screen_Frame", Color(0.04, 0.04, 0.04), 0.4)
	var screen_mat := _create_screen_material(Color(0.0, 0.25, 1.0), 2.5)
	_spawn_box(parent, "WallScreen_Frame", Vector3(22.0, 11.0, 0.4), Vector3(0, 5.0, 15.6), frame_mat)
	_spawn_plane(parent, "WallScreen_Display", Vector2(21.2, 10.4), Vector3(0, 5.0, 15.5), screen_mat, Vector3(90.0, 0.0, 0.0))

func _build_ceiling_screens(parent: Node3D) -> void:
	var support_mat := _create_standard_material("Ceil_Support", Color(0.1, 0.1, 0.1), 0.2, 1.0)
	var screen_mat := _create_screen_material(Color(1.0, 0.55, 0.0), 4.0)
	for side in [-1.0, 1.0]:
		var x: float = side * 6.0
		_spawn_cylinder(parent, "CeilSupport", 0.08, 2.2, Vector3(x, 9.0, 4.0), support_mat)
		_spawn_box(parent, "CeilScreen", Vector3(6.4, 3.8, 0.16), Vector3(x, 7.9, 4.0), screen_mat, Vector3(-20.0, 0.0, 0.0), false)

func _build_hologram(parent: Node3D) -> void:
	var holo_mat := _create_hologram_material()
	_globe = _spawn_sphere(parent, "Holo_Globe", 1.8, Vector3(0, 3.5, 0), holo_mat)

func _build_lights(parent: Node3D) -> void:
	var main_spot := SpotLight3D.new()
	main_spot.name = "Spot_Main"
	main_spot.position = Vector3(0, 9.2, 0)
	main_spot.light_energy = 40.0
	main_spot.shadow_enabled = true
	parent.add_child(main_spot)
	main_spot.look_at(Vector3.ZERO, Vector3.FORWARD) 
	if Engine.is_editor_hint(): main_spot.owner = get_tree().edited_scene_root

	var globe_glow := OmniLight3D.new()
	globe_glow.position = Vector3(0, 3.5, 0)
	globe_glow.light_energy = 8.0
	globe_glow.light_color = Color(0.0, 0.6, 1.0)
	parent.add_child(globe_glow)
	if Engine.is_editor_hint(): globe_glow.owner = get_tree().edited_scene_root

func _build_camera(parent: Node3D) -> void:
	var camera := Camera3D.new()
	camera.name = "Main_Camera"
	camera.position = Vector3(0, 8.0, 14.0) 
	camera.fov = 45.0
	camera.current = true
	camera.look_at(Vector3(0, 2.5, 0), Vector3.UP)
	parent.add_child(camera)
	if Engine.is_editor_hint(): camera.owner = get_tree().edited_scene_root
