class_name OutpostPlayer
extends CharacterBody3D

## Responsive first-person motor. Gameplay input stays here while the HUD only
## forwards button state, keeping desktop and touch play on the same movement path.
signal fire_requested
signal weapon_swap_requested
signal health_changed(current: int, maximum: int)
signal damage_taken(amount: int, source_position: Vector3)
signal player_down
signal movement_touch_changed(direction: Vector2, active: bool)
signal landed(impact: float)

const WALK_SPEED := 5.2
const SPRINT_SPEED := 7.35
const CROUCH_SPEED := 2.75
const AIM_SPEED := 3.15
const GROUND_ACCELERATION := 28.0
const GROUND_DECELERATION := 34.0
const AIR_ACCELERATION := 8.5
const GRAVITY := 21.0
const JUMP_VELOCITY := 7.4
const JUMP_CUT_MULTIPLIER := 0.48
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.14
const MAX_HEALTH := 100
const HEALTH_REGEN_DELAY := 4.0
const HEALTH_REGEN_PER_SECOND := 11.0
const TOUCH_RADIUS := 78.0
const STAND_HEIGHT := 1.72
const CROUCH_HEIGHT := 1.13
const STAND_HEAD_HEIGHT := 1.48
const CROUCH_HEAD_HEIGHT := 1.02
const SLIDE_DURATION := 0.62
const SLIDE_START_SPEED := 8.1
const SLIDE_END_SPEED := 3.0
const MANTLE_DURATION := 0.22
const LANDING_SOUND := preload("res://assets/audio/landing_thump.wav")

var health := MAX_HEALTH
var camera: Camera3D
var head: Node3D
var recoil_pivot: Node3D
var is_aiming := false
var is_sprinting := false
var is_crouching := false
var is_sliding := false
var is_mantling := false
var move_touch := -1
var look_touch := -1
var move_touch_origin := Vector2.ZERO
var look_touch_last := Vector2.ZERO
var touch_move := Vector2.ZERO
var movement_touch_region := Rect2()
var touch_radius := TOUCH_RADIUS
var mouse_sensitivity := 0.0028
var touch_look_sensitivity := 0.0055
var can_control := true

var capsule: CollisionShape3D
var capsule_shape: CapsuleShape3D
var coyote_left := 0.0
var jump_buffer_left := 0.0
var jump_held := false
var crouch_requested := false
var slide_left := 0.0
var slide_direction := Vector3.ZERO
var mantle_left := 0.0
var mantle_origin := Vector3.ZERO
var mantle_target := Vector3.ZERO
var previous_floor := false
var landing_dip := 0.0
var bob_phase := 0.0
var current_move_input := Vector2.ZERO
var recoil_rotation := Vector2.ZERO
var regen_delay_left := 0.0
var regen_fraction := 0.0
var landing_audio: AudioStreamPlayer

func _ready() -> void:
	name = "Player"
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	capsule = CollisionShape3D.new()
	capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.38
	capsule_shape.height = STAND_HEIGHT
	capsule.shape = capsule_shape
	capsule.position.y = STAND_HEIGHT * 0.5
	add_child(capsule)

	head = Node3D.new()
	head.name = "Head"
	head.position.y = STAND_HEAD_HEIGHT
	add_child(head)
	recoil_pivot = Node3D.new()
	recoil_pivot.name = "Recoil pivot"
	head.add_child(recoil_pivot)
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.current = true
	camera.near = 0.05
	camera.fov = 74.0
	recoil_pivot.add_child(camera)

	var fill := OmniLight3D.new()
	fill.name = "Weapon fill light"
	fill.light_color = Color("ffd7ac")
	fill.light_energy = 0.32
	fill.omni_range = 3.2
	fill.position = Vector3(0.24, -0.2, -0.45)
	camera.add_child(fill)
	landing_audio = AudioStreamPlayer.new()
	landing_audio.name = "Landing thump"
	landing_audio.stream = LANDING_SOUND
	landing_audio.volume_db = -12.0
	add_child(landing_audio)
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
	elif event is InputEventKey:
		_handle_keyboard_event(event)
	elif event is InputEventScreenTouch:
		_handle_touch_press(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)

func _handle_keyboard_event(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.keycode == KEY_SPACE:
		if event.pressed and not event.echo:
			request_jump()
		set_jump_held(event.pressed)
	elif event.keycode == KEY_C and event.pressed and not event.echo:
		request_crouch()
	elif event.keycode == KEY_Q and event.pressed and not event.echo:
		weapon_swap_requested.emit()

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
		_rotate_look((event.position - look_touch_last) * touch_look_sensitivity)
		look_touch_last = event.position

func set_movement_touch_region(region: Rect2, input_radius: float = TOUCH_RADIUS) -> void:
	movement_touch_region = region
	touch_radius = maxf(28.0, input_radius)

func set_look_sensitivity(multiplier: float) -> void:
	touch_look_sensitivity = clampf(0.0055 * multiplier, 0.0025, 0.011)
	mouse_sensitivity = clampf(0.0028 * multiplier, 0.0014, 0.006)

func request_jump() -> void:
	if not can_control:
		return
	if _try_start_mantle():
		return
	jump_buffer_left = JUMP_BUFFER_TIME
	jump_held = true

func set_jump_held(held: bool) -> void:
	jump_held = held
	if not held and velocity.y > 0.0 and not is_mantling:
		velocity.y *= JUMP_CUT_MULTIPLIER

func request_crouch() -> void:
	if not can_control or is_mantling:
		return
	if is_sprinting and _horizontal_speed() > WALK_SPEED * 0.82:
		_start_slide()
		return
	crouch_requested = not crouch_requested
	if crouch_requested:
		_set_crouching(true)
	else:
		_try_stand()

func _set_touch_move(value: Vector2) -> void:
	touch_move = value.limit_length(1.0)
	movement_touch_changed.emit(touch_move, move_touch != -1)

func _rotate_look(delta: Vector2) -> void:
	var aim_multiplier := 0.62 if is_aiming else 1.0
	rotate_y(-delta.x * aim_multiplier)
	head.rotation.x = clampf(head.rotation.x - delta.y * aim_multiplier, deg_to_rad(-78), deg_to_rad(78))

func _physics_process(delta: float) -> void:
	if not can_control:
		return
	_update_health_regeneration(delta)
	if is_mantling:
		_update_mantle(delta)
		_update_view(delta)
		return

	var was_grounded := is_on_floor()
	var vertical_before_move := velocity.y
	if was_grounded:
		coyote_left = COYOTE_TIME
	else:
		coyote_left = maxf(coyote_left - delta, 0.0)
	jump_buffer_left = maxf(jump_buffer_left - delta, 0.0)

	var input_axis := _read_move_input()
	current_move_input = input_axis
	_update_sprint_state(input_axis)
	if jump_buffer_left > 0.0 and coyote_left > 0.0 and not is_sliding:
		velocity.y = JUMP_VELOCITY
		jump_buffer_left = 0.0
		coyote_left = 0.0

	if is_sliding:
		_update_slide(delta)
	else:
		_update_horizontal_movement(input_axis, delta, was_grounded)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1
	move_and_slide()

	var grounded_now := is_on_floor()
	if not previous_floor and grounded_now and vertical_before_move < -2.0:
		var impact := clampf(-vertical_before_move / 13.0, 0.0, 1.0)
		landing_dip = -lerpf(0.018, 0.09, impact)
		if landing_audio != null:
			landing_audio.volume_db = lerpf(-19.0, -8.0, impact)
			landing_audio.play()
		landed.emit(impact)
	previous_floor = grounded_now
	_update_view(delta)

func _read_move_input() -> Vector2:
	var keyboard := Vector2.ZERO
	keyboard.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	keyboard.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var input_axis := keyboard
	if touch_move.length() > 0.05:
		input_axis = touch_move
	return input_axis.limit_length(1.0)

func _update_sprint_state(input_axis: Vector2) -> void:
	var keyboard_sprint := Input.is_key_pressed(KEY_SHIFT)
	var auto_sprint := _is_mobile() and input_axis.y < -0.88 and input_axis.length() > 0.92
	is_sprinting = (keyboard_sprint or auto_sprint) and input_axis.length() > 0.18 and not is_crouching and not is_aiming and not is_sliding

func _update_horizontal_movement(input_axis: Vector2, delta: float, grounded: bool) -> void:
	var speed := CROUCH_SPEED if is_crouching else (SPRINT_SPEED if is_sprinting else (AIM_SPEED if is_aiming else WALK_SPEED))
	var desired := (global_transform.basis.x * input_axis.x) + (global_transform.basis.z * input_axis.y)
	desired.y = 0.0
	if desired.length_squared() > 0.001:
		desired = desired.normalized() * speed
	var rate := GROUND_ACCELERATION if grounded and input_axis.length() > 0.01 else GROUND_DECELERATION
	if not grounded:
		rate = AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, desired.x, rate * delta)
	velocity.z = move_toward(velocity.z, desired.z, rate * delta)

func _start_slide() -> void:
	is_sprinting = false
	is_sliding = true
	slide_left = SLIDE_DURATION
	slide_direction = -global_transform.basis.z
	slide_direction.y = 0.0
	slide_direction = slide_direction.normalized()
	velocity.x = slide_direction.x * maxf(_horizontal_speed(), SLIDE_START_SPEED)
	velocity.z = slide_direction.z * maxf(_horizontal_speed(), SLIDE_START_SPEED)
	crouch_requested = false
	_set_crouching(true)

func _update_slide(delta: float) -> void:
	slide_left -= delta
	velocity.x = move_toward(velocity.x, slide_direction.x * SLIDE_END_SPEED, 14.0 * delta)
	velocity.z = move_toward(velocity.z, slide_direction.z * SLIDE_END_SPEED, 14.0 * delta)
	if slide_left <= 0.0 or _horizontal_speed() <= SLIDE_END_SPEED + 0.15:
		is_sliding = false
		if not crouch_requested:
			_try_stand()

func _set_crouching(enabled: bool) -> void:
	is_crouching = enabled
	var height := CROUCH_HEIGHT if enabled else STAND_HEIGHT
	capsule_shape.height = height
	capsule.position.y = height * 0.5

func _try_stand() -> void:
	if not is_crouching:
		return
	if not _has_headroom():
		crouch_requested = true
		return
	crouch_requested = false
	_set_crouching(false)

func _has_headroom() -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, CROUCH_HEIGHT * 0.72, 0),
		global_position + Vector3(0, STAND_HEIGHT + 0.08, 0),
		collision_mask
	)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _try_start_mantle() -> bool:
	if is_mantling or not is_on_floor() or _horizontal_speed() < 1.2:
		return false
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var space := get_world_3d().direct_space_state
	var low_query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.68, 0), global_position + Vector3(0, 0.68, 0) + forward * 1.05, 1)
	low_query.exclude = [get_rid()]
	if space.intersect_ray(low_query).is_empty():
		return false
	var high_query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.42, 0), global_position + Vector3(0, 1.42, 0) + forward * 1.05, 1)
	high_query.exclude = [get_rid()]
	if not space.intersect_ray(high_query).is_empty():
		return false
	var top_start: Vector3 = global_position + forward * 1.22 + Vector3(0, 1.55, 0)
	var down_query := PhysicsRayQueryParameters3D.create(top_start, top_start + Vector3.DOWN * 2.0, 1)
	down_query.exclude = [get_rid()]
	var top_hit := space.intersect_ray(down_query)
	if top_hit.is_empty():
		return false
	var top: Vector3 = top_hit["position"]
	var rise: float = top.y - global_position.y
	if rise < 0.24 or rise > 1.12:
		return false
	is_mantling = true
	mantle_left = MANTLE_DURATION
	mantle_origin = global_position
	mantle_target = top + forward * 0.42 + Vector3(0, 0.08, 0)
	velocity = Vector3.ZERO
	return true

func _update_mantle(delta: float) -> void:
	mantle_left = maxf(mantle_left - delta, 0.0)
	var weight := 1.0 - mantle_left / MANTLE_DURATION
	weight = weight * weight * (3.0 - 2.0 * weight)
	var target_position := mantle_origin.lerp(mantle_target, weight)
	var collision: KinematicCollision3D = move_and_collide(target_position - global_position, true)
	if collision != null:
		is_mantling = false
		return
	global_position = target_position
	if mantle_left <= 0.0:
		is_mantling = false
		velocity = Vector3.ZERO

func _update_view(delta: float) -> void:
	if recoil_pivot != null:
		recoil_rotation = recoil_rotation.lerp(Vector2.ZERO, _smooth_weight(delta, 8.5))
		recoil_pivot.rotation.x = lerpf(recoil_pivot.rotation.x, recoil_rotation.x, _smooth_weight(delta, 24.0))
		recoil_pivot.rotation.y = lerpf(recoil_pivot.rotation.y, recoil_rotation.y, _smooth_weight(delta, 24.0))
	var horizontal_speed := _horizontal_speed()
	var moving_factor := clampf(horizontal_speed / SPRINT_SPEED, 0.0, 1.0)
	var bob_speed := 7.0 + horizontal_speed * 1.35
	bob_phase += delta * bob_speed
	var bob_scale := 0.018 * moving_factor
	if is_crouching:
		bob_scale *= 0.58
	if is_aiming:
		bob_scale *= 0.30
	var target_head_height := CROUCH_HEAD_HEIGHT if is_crouching else STAND_HEAD_HEIGHT
	head.position.y = lerpf(head.position.y, target_head_height, _smooth_weight(delta, 14.0))
	landing_dip = move_toward(landing_dip, 0.0, delta * 0.38)
	var target_camera_position := Vector3(sin(bob_phase) * bob_scale * 0.45, abs(cos(bob_phase * 2.0)) * bob_scale + landing_dip, 0)
	camera.position = camera.position.lerp(target_camera_position, _smooth_weight(delta, 16.0))
	var target_roll := sin(bob_phase) * bob_scale * (0.42 if not is_aiming else 0.15)
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, _smooth_weight(delta, 12.0))
	var target_fov := 57.0 if is_aiming else (82.0 if is_sprinting else 74.0)
	camera.fov = lerpf(camera.fov, target_fov, _smooth_weight(delta, 9.0))

func _horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()

func _smooth_weight(delta: float, sharpness: float) -> float:
	return 1.0 - exp(-sharpness * delta)

func set_aim(enabled: bool) -> void:
	is_aiming = enabled and not is_sprinting and not is_sliding

func add_recoil(vertical_degrees: float, horizontal_degrees: float) -> void:
	# Recoil is an independent pivot, so recovery never fights direct look input.
	recoil_rotation.x = clampf(recoil_rotation.x - deg_to_rad(vertical_degrees), deg_to_rad(-13.0), deg_to_rad(2.0))
	recoil_rotation.y = clampf(recoil_rotation.y + deg_to_rad(horizontal_degrees), deg_to_rad(-5.0), deg_to_rad(5.0))

func get_move_amount() -> float:
	return current_move_input.length()

func get_accuracy_multiplier() -> float:
	if is_crouching:
		return 0.58
	if is_aiming:
		return 0.72
	if is_sprinting:
		return 1.65
	return 1.0

func _update_health_regeneration(delta: float) -> void:
	if health >= MAX_HEALTH:
		regen_fraction = 0.0
		return
	regen_delay_left = maxf(regen_delay_left - delta, 0.0)
	if regen_delay_left > 0.0:
		return
	regen_fraction += HEALTH_REGEN_PER_SECOND * delta
	var restored := int(floor(regen_fraction))
	if restored <= 0:
		return
	regen_fraction -= float(restored)
	health = mini(MAX_HEALTH, health + restored)
	health_changed.emit(health, MAX_HEALTH)

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO) -> void:
	if health <= 0:
		return
	health = max(health - amount, 0)
	regen_delay_left = HEALTH_REGEN_DELAY
	regen_fraction = 0.0
	damage_taken.emit(amount, source_position)
	health_changed.emit(health, MAX_HEALTH)
	if health == 0:
		can_control = false
		player_down.emit()

func reset_at(spawn_point: Vector3) -> void:
	health = MAX_HEALTH
	global_position = spawn_point
	velocity = Vector3.ZERO
	can_control = true
	is_sprinting = false
	is_sliding = false
	is_mantling = false
	regen_delay_left = 0.0
	regen_fraction = 0.0
	crouch_requested = false
	_set_crouching(false)
	_set_touch_move(Vector2.ZERO)
	health_changed.emit(health, MAX_HEALTH)

func _is_mobile() -> bool:
	return OS.has_feature("mobile")
