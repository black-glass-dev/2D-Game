class_name ServiceRifle
extends Node3D

signal ammo_changed(in_magazine: int, reserve: int)
signal weapon_message(text: String)
signal shot_resolved(hit: bool, target_name: String)

const MAGAZINE_SIZE := 24
const STARTING_RESERVE := 144
const FIRE_INTERVAL := 0.105
const RELOAD_TIME := 1.25
const DAMAGE := 34
const RANGE := 80.0
const BASE_SPREAD := 0.0058
const MAX_BLOOM := 0.034
const RECOIL_PATTERN := [
	Vector2(1.15, 0.18), Vector2(1.35, -0.22), Vector2(1.58, 0.32),
	Vector2(1.74, -0.36), Vector2(1.92, 0.24), Vector2(2.10, -0.18)
]
const SHOT_SOUND := preload("res://assets/audio/rifle_shot.wav")
const RELOAD_SOUND := preload("res://assets/audio/reload_click.wav")

var ammo := MAGAZINE_SIZE
var reserve := STARTING_RESERVE
var cooldown := 0.0
var reload_left := 0.0
var muzzle_flash: MeshInstance3D
var muzzle_light: OmniLight3D
var gun_root: Node3D
var owner_player: OutpostPlayer
var effects: WeaponEffects
var shot_audio: AudioStreamPlayer
var reload_audio: AudioStreamPlayer
var bloom := 0.0
var shot_serial := 0
var visual_recoil := 0.0

func _ready() -> void:
	name = "Service Rifle"
	_build_model()
	_build_audio()
	_build_effects_pool()
	ammo_changed.emit(ammo, reserve)

func bind_player(player_value: OutpostPlayer) -> void:
	owner_player = player_value

func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	bloom = move_toward(bloom, 0.0, delta * 0.026)
	visual_recoil = move_toward(visual_recoil, 0.0, delta * 9.0)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			_complete_reload()
	if muzzle_flash != null:
		muzzle_flash.visible = cooldown > FIRE_INTERVAL * 0.45
	if muzzle_light != null:
		muzzle_light.light_energy = 2.5 if cooldown > FIRE_INTERVAL * 0.45 else 0.0
	_update_weapon_pose(delta)

func try_fire(camera: Camera3D) -> bool:
	if reload_left > 0.0 or cooldown > 0.0:
		return false
	if ammo <= 0:
		start_reload()
		return false
	ammo -= 1
	cooldown = FIRE_INTERVAL
	shot_serial += 1
	var recoil_step: Vector2 = RECOIL_PATTERN[(shot_serial - 1) % RECOIL_PATTERN.size()]
	if owner_player != null:
		owner_player.add_recoil(recoil_step.x, recoil_step.y)
	bloom = minf(MAX_BLOOM, bloom + 0.0048 * _accuracy_multiplier())
	visual_recoil = 1.0
	ammo_changed.emit(ammo, reserve)
	_play_sound(shot_audio)

	var origin: Vector3 = camera.global_position
	var direction := _shot_direction(camera)
	var destination := origin + direction * RANGE
	var impact_normal := Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 5)
	query.collide_with_areas = false
	if owner_player != null:
		query.exclude = [owner_player.get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	var hit_target := false
	var target_name := ""
	if not hit.is_empty():
		destination = hit["position"]
		impact_normal = hit["normal"]
		var collider: Object = hit.get("collider")
		if collider != null and collider.has_method("take_damage"):
			collider.take_damage(DAMAGE)
			hit_target = true
			target_name = collider.name
	if effects != null:
		effects.emit_shot(origin, destination, impact_normal, not hit.is_empty())
		if gun_root != null:
			effects.emit_casing(gun_root.global_position + camera.global_transform.basis.x * 0.10, camera.global_transform.basis.x, camera.global_transform.basis.y, shot_serial)
	shot_resolved.emit(hit_target, target_name)
	return true

func start_reload() -> void:
	if reload_left > 0.0 or ammo >= MAGAZINE_SIZE or reserve <= 0:
		return
	reload_left = RELOAD_TIME
	weapon_message.emit("RELOADING")
	_play_sound(reload_audio)

func _complete_reload() -> void:
	var needed := MAGAZINE_SIZE - ammo
	var moved: int = mini(needed, reserve)
	ammo += moved
	reserve -= moved
	ammo_changed.emit(ammo, reserve)
	weapon_message.emit("READY")

func _shot_direction(camera: Camera3D) -> Vector3:
	var spread := BASE_SPREAD * _accuracy_multiplier() + bloom
	var noise := Vector2(sin(float(shot_serial) * 12.9898), cos(float(shot_serial) * 78.233))
	var forward: Vector3 = -camera.global_transform.basis.z
	var right: Vector3 = camera.global_transform.basis.x
	var up: Vector3 = camera.global_transform.basis.y
	return (forward + right * noise.x * spread + up * noise.y * spread).normalized()

func _accuracy_multiplier() -> float:
	return owner_player.get_accuracy_multiplier() if owner_player != null else 1.0

func _update_weapon_pose(delta: float) -> void:
	if gun_root == null:
		return
	var target_position := Vector3(0.32, -0.28, -0.56)
	var target_rotation := Vector3.ZERO
	if owner_player != null and owner_player.is_sprinting:
		target_position = Vector3(0.52, -0.52, -0.34)
		target_rotation = Vector3(deg_to_rad(-24.0), deg_to_rad(-13.0), deg_to_rad(8.0))
	elif owner_player != null and owner_player.is_aiming:
		target_position = Vector3(0.025, -0.21, -0.39)
		target_rotation = Vector3(deg_to_rad(-1.2), 0.0, 0.0)
	else:
		var movement := owner_player.get_move_amount() if owner_player != null else 0.0
		target_rotation = Vector3(deg_to_rad(movement * 2.0), deg_to_rad(-movement * 1.6), deg_to_rad(movement * 1.1))
	if reload_left > 0.0:
		var reload_progress := 1.0 - maxf(reload_left, 0.0) / RELOAD_TIME
		var reload_arc := sin(reload_progress * PI)
		target_position += Vector3(0.08, -0.10 * reload_arc, 0.14 * reload_arc)
		target_rotation.x += deg_to_rad(42.0 * reload_arc)
	target_position.z += visual_recoil * 0.072
	target_rotation.x += deg_to_rad(visual_recoil * 7.0)
	var smooth := 1.0 - exp(-delta * 16.0)
	gun_root.position = gun_root.position.lerp(target_position, smooth)
	gun_root.rotation = gun_root.rotation.lerp(target_rotation, smooth)

func _build_effects_pool() -> void:
	effects = WeaponEffects.new()
	var scene_root := get_tree().current_scene
	if scene_root != null:
		scene_root.call_deferred("add_child", effects)

func _build_audio() -> void:
	shot_audio = AudioStreamPlayer.new()
	shot_audio.name = "Rifle report"
	shot_audio.stream = SHOT_SOUND
	shot_audio.volume_db = -5.0
	add_child(shot_audio)
	reload_audio = AudioStreamPlayer.new()
	reload_audio.name = "Reload click"
	reload_audio.stream = RELOAD_SOUND
	reload_audio.volume_db = -8.0
	add_child(reload_audio)

func _play_sound(player_node: AudioStreamPlayer) -> void:
	if player_node == null:
		return
	if player_node.playing:
		player_node.stop()
	player_node.play()

func _build_model() -> void:
	gun_root = Node3D.new()
	gun_root.name = "Rifle model"
	gun_root.position = Vector3(0.32, -0.28, -0.56)
	add_child(gun_root)
	var body_mat := _mat(Color("303a35"), 0.72)
	var accent_mat := _mat(Color("626a45"), 0.85)
	var black_mat := _mat(Color("151c1a"), 0.92)
	_part("Receiver", Vector3(0, 0, 0), Vector3(0.18, 0.16, 0.52), body_mat)
	_part("Handguard", Vector3(0, -0.005, -0.38), Vector3(0.14, 0.13, 0.38), accent_mat)
	_part("Barrel", Vector3(0, 0.025, -0.70), Vector3(0.06, 0.06, 0.30), black_mat)
	_part("Stock", Vector3(0, -0.04, 0.34), Vector3(0.15, 0.13, 0.34), black_mat)
	_part("Magazine", Vector3(0, -0.19, 0.05), Vector3(0.10, 0.26, 0.16), black_mat)
	_part("Sight", Vector3(0, 0.13, -0.08), Vector3(0.045, 0.06, 0.12), black_mat)
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "Muzzle flash"
	var flash := SphereMesh.new()
	flash.radius = 0.07
	flash.height = 0.14
	muzzle_flash.mesh = flash
	muzzle_flash.position = Vector3(0, 0.025, -0.88)
	muzzle_flash.material_override = _mat(Color("fff0c0"), 0.2, Color("ff8d25"), 5.0)
	muzzle_flash.visible = false
	gun_root.add_child(muzzle_flash)
	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "Muzzle flash light"
	muzzle_light.light_color = Color("ff9e41")
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 2.3
	muzzle_light.position = muzzle_flash.position
	gun_root.add_child(muzzle_light)

func _part(part_name: String, position_value: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position_value
	gun_root.add_child(visual)

func _mat(color: Color, roughness: float, emission := Color.TRANSPARENT, energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
