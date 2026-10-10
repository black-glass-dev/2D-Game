class_name Raider
extends CharacterBody3D

signal eliminated(raider: Raider, score_value: int)

const MAX_HEALTH := 100
const MOVE_SPEED := 2.35
const MOVE_ACCELERATION := 9.5
const MOVE_DECELERATION := 13.0
const ATTACK_RANGE := 14.0
const ATTACK_COOLDOWN := 1.65
const SIGHT_CHECK_INTERVAL := 0.22
const GRAVITY := 18.0
const RADAR_NEAR_RANGE := 22.0

var health := MAX_HEALTH
var attack_timer := 1.0
var sight_timer := 0.0
var radar_reveal_left := 0.0
var active := true
var body_visual: Node3D
var hit_light: OmniLight3D
var head_hitbox: Area3D
var tactics := RaiderTactics.new()
var line_of_sight := false
var attack_serial := 0
var walk_phase := 0.0
var spawn_index := 0

func setup(index: int) -> void:
	spawn_index = index
	tactics.setup(index)

func _ready() -> void:
	name = "Raider_%02d" % spawn_index
	add_to_group("raiders")
	collision_layer = 4
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.75
	collider.shape = shape
	collider.position.y = 0.87
	add_child(collider)
	_build_headshot_hitbox()
	_build_model()

func _physics_process(delta: float) -> void:
	if not active:
		return
	radar_reveal_left = maxf(radar_reveal_left - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as OutpostPlayer
	if player == null or not player.can_control:
		_update_visual_motion(delta)
		return
	var player_target := player.global_position + Vector3(0, 0.75, 0)
	var flat_player_offset := player_target - global_position
	flat_player_offset.y = 0.0
	var player_distance := flat_player_offset.length()
	sight_timer -= delta
	if sight_timer <= 0.0:
		sight_timer = SIGHT_CHECK_INTERVAL + float(spawn_index % 3) * 0.03
		line_of_sight = _has_line_of_sight(player)
	tactics.update(delta, global_position, player.global_position, line_of_sight)
	_move_to_goal(tactics.move_goal, delta)
	_update_visual_motion(delta)

	attack_timer -= delta
	if player_distance <= ATTACK_RANGE and line_of_sight and tactics.can_attack() and attack_timer <= 0.0:
		attack_timer = ATTACK_COOLDOWN + float(spawn_index % 3) * 0.12
		radar_reveal_left = 1.9
		_attempt_attack(player, player_distance)

func hear_weapon_fire(origin: Vector3) -> void:
	if not active:
		return
	tactics.hear_weapon_fire(origin, global_position)

func take_damage(amount: int, was_headshot := false) -> bool:
	if not active:
		return false
	health -= amount
	radar_reveal_left = 2.4
	tactics.receive_hit()
	_flash_body(Color("fff2c4") if not was_headshot else Color("ffdb78"))
	if health > 0:
		return false
	active = false
	collision_layer = 0
	if head_hitbox != null:
		head_hitbox.collision_layer = 0
	velocity = Vector3.ZERO
	eliminated.emit(self, 100)
	var tween := create_tween()
	tween.tween_property(body_visual, "rotation:z", deg_to_rad(84), 0.18)
	tween.parallel().tween_property(body_visual, "position:y", -0.48, 0.18)
	tween.tween_interval(2.3)
	tween.tween_callback(queue_free)
	return true

func is_radar_visible(observer_position: Vector3) -> bool:
	if not active:
		return false
	var horizontal_delta := observer_position - global_position
	horizontal_delta.y = 0.0
	return horizontal_delta.length_squared() <= RADAR_NEAR_RANGE * RADAR_NEAR_RANGE or radar_reveal_left > 0.0

func _move_to_goal(goal: Vector3, delta: float) -> void:
	var flat_goal := goal - global_position
	flat_goal.y = 0.0
	var distance := flat_goal.length()
	var target_velocity := Vector3.ZERO
	if distance > 0.65:
		var direction := flat_goal / distance
		var speed := MOVE_SPEED * tactics.speed_multiplier()
		target_velocity = direction * speed
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-delta * 8.5))
	var rate := MOVE_ACCELERATION if distance > 0.65 else MOVE_DECELERATION
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	move_and_slide()

func _attempt_attack(player: OutpostPlayer, distance: float) -> void:
	attack_serial += 1
	var range_factor := clampf(1.0 - distance / ATTACK_RANGE, 0.0, 1.0)
	var hit_chance := lerpf(0.36, 0.68, range_factor)
	var roll := fposmod(sin(float(spawn_index * 97 + attack_serial * 31)) * 43758.5453, 1.0)
	_flash_body(Color("ffb55e"))
	if roll <= hit_chance:
		player.take_damage(3 + (spawn_index % 3), global_position)

func _update_visual_motion(delta: float) -> void:
	if body_visual == null or not active:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	walk_phase += delta * (3.2 + speed * 3.8)
	var bob := sin(walk_phase) * minf(speed * 0.018, 0.05)
	body_visual.position.y = lerpf(body_visual.position.y, bob, 1.0 - exp(-delta * 10.0))
	body_visual.rotation.x = lerpf(body_visual.rotation.x, sin(walk_phase * 0.5) * minf(speed * 0.035, 0.08), 1.0 - exp(-delta * 8.0))

func _has_line_of_sight(player: OutpostPlayer) -> bool:
	var eye := global_position + Vector3(0, 1.35, 0)
	var aim_point := player.global_position + Vector3(0, 1.2, 0)
	var query := PhysicsRayQueryParameters3D.create(eye, aim_point, 3)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == player

func _build_headshot_hitbox() -> void:
	head_hitbox = Area3D.new()
	head_hitbox.name = "Headshot hitbox"
	head_hitbox.collision_layer = 8
	head_hitbox.collision_mask = 0
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	shape_node.shape = shape
	shape_node.position = Vector3(0, 1.75, 0)
	head_hitbox.add_child(shape_node)
	add_child(head_hitbox)

func _build_model() -> void:
	body_visual = Node3D.new()
	body_visual.name = "Low poly raider model"
	add_child(body_visual)
	hit_light = OmniLight3D.new()
	hit_light.name = "Hit feedback"
	hit_light.position = Vector3(0, 1.2, 0)
	hit_light.omni_range = 3.2
	hit_light.light_energy = 0.0
	body_visual.add_child(hit_light)
	var uniform := _mat(Color("665842") if spawn_index % 2 == 0 else Color("504f3e"))
	var vest := _mat(Color("273126"))
	var skin := _mat(Color("9a654b"))
	var rifle := _mat(Color("161b19"))
	_part("Torso", Vector3(0, 1.12, 0), Vector3(0.58, 0.72, 0.28), uniform)
	_part("Vest", Vector3(0, 1.15, -0.17), Vector3(0.50, 0.52, 0.08), vest)
	_part("Head", Vector3(0, 1.72, 0), Vector3(0.38, 0.38, 0.38), skin)
	_part("Helmet", Vector3(0, 1.94, 0), Vector3(0.43, 0.15, 0.43), vest)
	_part("Leg left", Vector3(-0.16, 0.43, 0), Vector3(0.18, 0.72, 0.20), uniform)
	_part("Leg right", Vector3(0.16, 0.43, 0), Vector3(0.18, 0.72, 0.20), uniform)
	_part("Rifle", Vector3(0.29, 1.12, -0.36), Vector3(0.08, 0.09, 0.58), rifle)

func _part(part_name: String, local_position: Vector3, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = local_position
	body_visual.add_child(mesh_instance)

func _flash_body(color: Color) -> void:
	if hit_light == null:
		return
	hit_light.light_color = color
	hit_light.light_energy = 2.4
	var tween := create_tween()
	tween.tween_property(hit_light, "light_energy", 0.0, 0.1)

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
