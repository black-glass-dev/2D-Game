class_name OutpostPlayer
extends CharacterBody3D

signal fire_requested
signal health_changed(current: int, maximum: int)
signal player_down

const WALK_SPEED := 5.2
const AIM_SPEED := 3.15
const ACCELERATION := 20.0
const GRAVITY := 18.0
const JUMP_VELOCITY := 6.2
const MAX_HEALTH := 100

var health := MAX_HEALTH
var camera: Camera3D
var head: Node3D
var character_mesh_root: Node3D
var hair_strand_nodes: Array[Node3D] = []
var animation_time := 0.0

var is_aiming := false
var move_touch := -1
var look_touch := -1
var move_touch_origin := Vector2.ZERO
var look_touch_last := Vector2.ZERO
var touch_move := Vector2.ZERO
var mouse_sensitivity := 0.0028
var can_control := true

func _ready() -> void:
	name = "Player"
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.72
	capsule.shape = shape
	capsule.position.y = 0.86
	add_child(capsule)

	head = Node3D.new()
	head.name = "Head"
	head.position.y = 1.48
	add_child(head)
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.current = true
	camera.near = 0.05
	camera.fov = 74.0
	head.add_child(camera)

	var fill := OmniLight3D.new()
	fill.name = "Weapon fill light"
	fill.light_color = Color("ffd7ac")
	fill.light_energy = 0.45
	fill.omni_range = 4.0
	fill.position = Vector3(0.24, -0.2, -0.45)
	camera.add_child(fill)

	_build_character_model()

	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, MAX_HEALTH)

func _unhandled_input(event: InputEvent) -> void:
	if not can_control:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_look(event.relative * mouse_sensitivity)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		fire_requested.emit()
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey and event.keycode == KEY_SPACE and event.pressed:
		jump()
	elif event is InputEventScreenTouch:
		_handle_touch_press(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)

func jump() -> void:
	if is_on_floor() and can_control:
		velocity.y = JUMP_VELOCITY

func _handle_touch_press(event: InputEventScreenTouch) -> void:
	var width := get_viewport().get_visible_rect().size.x
	if event.pressed:
		if event.position.x < width * 0.46 and move_touch == -1:
			move_touch = event.index
			move_touch_origin = event.position
			touch_move = Vector2.ZERO
		elif look_touch == -1:
			look_touch = event.index
			look_touch_last = event.position
	else:
		if event.index == move_touch:
			move_touch = -1
			touch_move = Vector2.ZERO
		if event.index == look_touch:
			look_touch = -1

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if event.index == move_touch:
		var radius := maxf(get_viewport().get_visible_rect().size.x * 0.10, 72.0)
		touch_move = (event.position - move_touch_origin).limit_length(radius) / radius
	elif event.index == look_touch:
		_rotate_look((event.position - look_touch_last) * 0.007)
		look_touch_last = event.position

func _rotate_look(delta: Vector2) -> void:
	rotate_y(-delta.x)
	head.rotation.x = clampf(head.rotation.x - delta.y, deg_to_rad(-78), deg_to_rad(78))

func _physics_process(delta: float) -> void:
	animation_time += delta
	_update_continuous_animation(delta)

	if not can_control:
		return
	var keyboard := Vector2.ZERO
	keyboard.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	keyboard.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var input_axis := keyboard
	if touch_move.length() > 0.05:
		input_axis = touch_move
	input_axis = input_axis.limit_length(1.0)
	var desired := (global_transform.basis.x * input_axis.x) + (global_transform.basis.z * input_axis.y)
	desired.y = 0.0
	var speed := AIM_SPEED if is_aiming else WALK_SPEED
	velocity.x = move_toward(velocity.x, desired.x * speed, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, desired.z * speed, ACCELERATION * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		if velocity.y < 0.0:
			velocity.y = -0.1
	move_and_slide()
	camera.fov = lerpf(camera.fov, 57.0 if is_aiming else 74.0, minf(10.0 * delta, 1.0))

func _update_continuous_animation(delta: float) -> void:
	# Continuous idle breathing & hair motion
	var breathing := sin(animation_time * 2.0) * 0.008
	if head != null:
		head.position.y = 1.48 + breathing

	# Dynamic hair sway animation based on time and movement velocity
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var hair_sway_freq := 3.0 + horizontal_speed * 1.5
	var hair_sway_amp := 0.05 + horizontal_speed * 0.04

	var index := 0
	for hair in hair_strand_nodes:
		if is_instance_valid(hair):
			var phase := float(index) * 0.4
			var sway_z := sin(animation_time * hair_sway_freq + phase) * hair_sway_amp
			var sway_x := cos(animation_time * (hair_sway_freq * 0.8) + phase) * (hair_sway_amp * 0.5)
			hair.rotation.z = lerpf(hair.rotation.z, sway_z, minf(delta * 10.0, 1.0))
			hair.rotation.x = lerpf(hair.rotation.x, sway_x, minf(delta * 10.0, 1.0))
		index += 1

func _build_character_model() -> void:
	character_mesh_root = Node3D.new()
	character_mesh_root.name = "Character visual design"
	add_child(character_mesh_root)

	var dark_armor_mat := _mat(Color("1b2024"), 0.5)
	var plate_gold_mat := _mat(Color("b3863b"), 0.3)
	var crimson_cape_mat := _mat(Color("8f131a"), 0.6)
	var skin_mat := _mat(Color("c49372"), 0.8)
	var hair_mat := _mat(Color("171415"), 0.4)
	var hair_highlight_mat := _mat(Color("3b2820"), 0.5)

	# Main Body Armor & Pauldrons (Detailed Hero Main Character)
	_part(character_mesh_root, "Chest Plate", Vector3(0, 1.05, 0), Vector3(0.52, 0.62, 0.32), dark_armor_mat)
	_part(character_mesh_root, "Golden Crest", Vector3(0, 1.15, 0.17), Vector3(0.18, 0.28, 0.04), plate_gold_mat)
	_part(character_mesh_root, "Left Shoulder Armor", Vector3(-0.32, 1.28, 0), Vector3(0.22, 0.22, 0.26), plate_gold_mat)
	_part(character_mesh_root, "Right Shoulder Armor", Vector3(0.32, 1.28, 0), Vector3(0.22, 0.22, 0.26), plate_gold_mat)
	_part(character_mesh_root, "Cape Back", Vector3(0, 0.85, -0.18), Vector3(0.54, 1.05, 0.06), crimson_cape_mat)

	# Head & Long Flowing Hair (Very long hair extending down back & shoulders)
	var head_mesh_root := Node3D.new()
	head_mesh_root.name = "Head Mesh Root"
	head_mesh_root.position = Vector3(0, 1.48, 0)
	character_mesh_root.add_child(head_mesh_root)

	_part(head_mesh_root, "Character Head", Vector3(0, 0.12, 0), Vector3(0.28, 0.30, 0.28), skin_mat)
	_part(head_mesh_root, "Hair Top Base", Vector3(0, 0.26, -0.02), Vector3(0.32, 0.12, 0.32), hair_mat)

	# Long Hair Strands hanging down back and front shoulders
	hair_strand_nodes.clear()

	# Long Hair Strands on the back
	for i in range(5):
		var x_offset := float(i - 2) * 0.07
		var strand := _part_returning(head_mesh_root, "Hair Strand Back %d" % i, Vector3(x_offset, -0.22, -0.16), Vector3(0.065, 0.68, 0.08), hair_highlight_mat if i % 2 == 1 else hair_mat)
		hair_strand_nodes.append(strand)

	# Long Hair Strands draped over shoulders (front/sides)
	var strand_left := _part_returning(head_mesh_root, "Hair Strand Front Left", Vector3(-0.16, -0.18, 0.08), Vector3(0.06, 0.58, 0.07), hair_mat)
	var strand_right := _part_returning(head_mesh_root, "Hair Strand Front Right", Vector3(0.16, -0.18, 0.08), Vector3(0.06, 0.58, 0.07), hair_mat)
	hair_strand_nodes.append(strand_left)
	hair_strand_nodes.append(strand_right)

func set_aim(enabled: bool) -> void:
	is_aiming = enabled

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		can_control = false
		player_down.emit()

func reset_at(spawn_point: Vector3) -> void:
	health = MAX_HEALTH
	global_position = spawn_point
	velocity = Vector3.ZERO
	can_control = true
	health_changed.emit(health, MAX_HEALTH)

func _part(parent: Node3D, part_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	_part_returning(parent, part_name, position, size, material)

func _part_returning(parent: Node3D, part_name: String, position: Vector3, size: Vector3, material: Material) -> Node3D:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position
	parent.add_child(visual)
	return visual

func _mat(color: Color, roughness: float, emission := Color.TRANSPARENT, energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
