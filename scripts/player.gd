class_name OutpostPlayer
extends CharacterBody3D

signal fire_requested
signal health_changed(current: int, maximum: int)
signal player_down
signal movement_touch_changed(direction: Vector2, active: bool)

const WALK_SPEED := 5.2
const AIM_SPEED := 3.15
const ACCELERATION := 20.0
const GRAVITY := 18.0
const MAX_HEALTH := 100
const TOUCH_RADIUS := 78.0

var health := MAX_HEALTH
var camera: Camera3D
var head: Node3D
var is_aiming := false
var move_touch := -1
var look_touch := -1
var move_touch_origin := Vector2.ZERO
var look_touch_last := Vector2.ZERO
var touch_move := Vector2.ZERO
var movement_touch_region := Rect2()
var touch_radius := TOUCH_RADIUS
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
	fill.light_energy = 0.32
	fill.omni_range = 3.2
	fill.position = Vector3(0.24, -0.2, -0.45)
	camera.add_child(fill)
	if not _is_mobile():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, MAX_HEALTH)

func _unhandled_input(event: InputEvent) -> void:
	if not can_control:
		return
	if not _is_mobile() and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_look(event.relative * mouse_sensitivity)
	elif not _is_mobile() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		fire_requested.emit()
	elif not _is_mobile() and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventScreenTouch:
		_handle_touch_press(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)

func _handle_touch_press(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# The region follows the visible joystick, including a user-customized HUD
		# layout. GUI buttons consume their own touches before this handler runs.
		if movement_touch_region.has_point(event.position) and move_touch == -1:
			move_touch = event.index
			move_touch_origin = event.position
			_set_touch_move(Vector2.ZERO)
		elif look_touch == -1:
			look_touch = event.index
			look_touch_last = event.position
	else:
		if event.index == move_touch:
			move_touch = -1
			_set_touch_move(Vector2.ZERO)
		if event.index == look_touch:
			look_touch = -1

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if event.index == move_touch:
		_set_touch_move((event.position - move_touch_origin).limit_length(touch_radius) / touch_radius)
	elif event.index == look_touch:
		_rotate_look((event.position - look_touch_last) * 0.0055)
		look_touch_last = event.position

func set_movement_touch_region(region: Rect2, input_radius: float = TOUCH_RADIUS) -> void:
	movement_touch_region = region
	touch_radius = maxf(28.0, input_radius)

func _set_touch_move(value: Vector2) -> void:
	touch_move = value.limit_length(1.0)
	movement_touch_changed.emit(touch_move, move_touch != -1)

func _rotate_look(delta: Vector2) -> void:
	rotate_y(-delta.x)
	head.rotation.x = clampf(head.rotation.x - delta.y, deg_to_rad(-78), deg_to_rad(78))

func _physics_process(delta: float) -> void:
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
		velocity.y = -0.1
	move_and_slide()
	camera.fov = lerpf(camera.fov, 57.0 if is_aiming else 74.0, minf(10.0 * delta, 1.0))

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
	_set_touch_move(Vector2.ZERO)
	health_changed.emit(health, MAX_HEALTH)

func _is_mobile() -> bool:
	return OS.has_feature("mobile")
