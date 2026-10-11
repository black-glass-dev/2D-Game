class_name ServicePistol
extends Node3D

## A compact sidearm used by the Phase 7 weapon-switch flow. It intentionally
## exposes the same gameplay-facing API as ServiceRifle without coupling the
## two weapon models.
signal ammo_changed(in_magazine: int, reserve: int)
signal weapon_message(text: String)
signal shot_resolved(hit: bool, target_name: String)
signal shot_feedback(headshot: bool, eliminated: bool, target_name: String)
signal weapon_fired(origin: Vector3)

const MAGAZINE_SIZE := 12
const STARTING_RESERVE := 72
const FIRE_INTERVAL := 0.19
const RELOAD_TIME := 1.0
const DAMAGE := 29
const RANGE := 62.0
const BASE_SPREAD := 0.008
const SHOT_SOUND := preload("res://assets/audio/pistol_shot.wav")
const RELOAD_SOUND := preload("res://assets/audio/reload_click.wav")

var ammo := MAGAZINE_SIZE
var reserve := STARTING_RESERVE
var cooldown := 0.0
var reload_left := 0.0
var owner_player: OutpostPlayer
var gun_root: Node3D
var muzzle_flash: MeshInstance3D
var effects: WeaponEffects
var shot_audio: AudioStreamPlayer
var reload_audio: AudioStreamPlayer
var equipped := false
var equip_blend := 0.0
var aim_assist_enabled := true
var effects_enabled := true
var shot_serial := 0
var visual_recoil := 0.0

func _ready() -> void:
	name = "Service Pistol"
	_build_model()
	_build_audio()
	_build_effects_pool()
	ammo_changed.emit(ammo, reserve)

func bind_player(player_value: OutpostPlayer) -> void:
	owner_player = player_value

func set_equipped(enabled: bool) -> void:
	equipped = enabled
	if enabled and gun_root != null:
		gun_root.visible = true

func set_aim_assist_enabled(enabled: bool) -> void:
	aim_assist_enabled = enabled

func set_effects_enabled(enabled: bool) -> void:
	effects_enabled = enabled
	if effects != null:
		effects.set_effects_enabled(enabled)

func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	visual_recoil = move_toward(visual_recoil, 0.0, delta * 11.0)
	equip_blend = move_toward(equip_blend, 1.0 if equipped else 0.0, delta * 7.5)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			_complete_reload()
	if muzzle_flash != null:
		muzzle_flash.visible = effects_enabled and cooldown > FIRE_INTERVAL * 0.42
	_update_pose(delta)
	if gun_root != null and equip_blend <= 0.02 and not equipped:
		gun_root.visible = false

func try_fire(camera: Camera3D) -> bool:
	if not equipped or reload_left > 0.0 or cooldown > 0.0:
		return false
	if ammo <= 0:
		start_reload()
		return false
	ammo -= 1
	cooldown = FIRE_INTERVAL
	shot_serial += 1
	visual_recoil = 1.0
	ammo_changed.emit(ammo, reserve)
	_play_sound(shot_audio)
	var origin: Vector3 = camera.global_position
	weapon_fired.emit(origin)
	var direction := _apply_aim_assist(camera, _shot_direction(camera))
	var destination := origin + direction * RANGE
	var impact_normal := Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 13)
	query.collide_with_areas = true
	if owner_player != null:
		query.exclude = [owner_player.get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	var hit_target := false
	var headshot := false
	var eliminated := false
	var target_name := ""
	if not hit.is_empty():
		destination = hit["position"]
		impact_normal = hit["normal"]
		var collider: Object = hit.get("collider")
		var target := _resolve_raider(collider)
		headshot = collider is Area3D and collider.name == "Headshot hitbox"
		if target != null:
			var damage := DAMAGE * (2 if headshot else 1)
			eliminated = target.take_damage(damage, headshot)
			hit_target = true
			target_name = target.name
	if effects != null:
		effects.emit_shot(origin, destination, impact_normal, not hit.is_empty())
		if gun_root != null:
			effects.emit_casing(gun_root.global_position + camera.global_transform.basis.x * 0.07, camera.global_transform.basis.x, camera.global_transform.basis.y, shot_serial)
	shot_resolved.emit(hit_target, target_name)
	shot_feedback.emit(headshot, eliminated, target_name)
	return true

func start_reload() -> void:
	if not equipped or reload_left > 0.0 or ammo >= MAGAZINE_SIZE or reserve <= 0:
		return
	reload_left = RELOAD_TIME
	weapon_message.emit("PISTOL RELOADING")
	_play_sound(reload_audio)

func _complete_reload() -> void:
	var needed := MAGAZINE_SIZE - ammo
	var moved: int = mini(needed, reserve)
	ammo += moved
	reserve -= moved
	ammo_changed.emit(ammo, reserve)
	weapon_message.emit("PISTOL READY")

func _shot_direction(camera: Camera3D) -> Vector3:
	var spread := BASE_SPREAD * _accuracy_multiplier()
	var noise := Vector2(sin(float(shot_serial) * 18.177), cos(float(shot_serial) * 59.423))
	return (-camera.global_transform.basis.z + camera.global_transform.basis.x * noise.x * spread + camera.global_transform.basis.y * noise.y * spread).normalized()

func _accuracy_multiplier() -> float:
	return owner_player.get_accuracy_multiplier() if owner_player != null else 1.0

func _resolve_raider(collider: Object) -> Raider:
	if collider is Raider:
		return collider as Raider
	if collider is Area3D and collider.get_parent() is Raider:
		return collider.get_parent() as Raider
	return null

func _apply_aim_assist(camera: Camera3D, direction: Vector3) -> Vector3:
	if not aim_assist_enabled or not OS.has_feature("mobile") or owner_player == null:
		return direction
	var best_direction := direction
	var best_alignment := 0.992
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		if raider == null or not raider.active:
			continue
		var to_target := raider.global_position + Vector3(0, 1.35, 0) - camera.global_position
		var distance := to_target.length()
		if distance < 1.0 or distance > 38.0:
			continue
		var candidate := to_target / distance
		var alignment := direction.dot(candidate)
		if alignment > best_alignment:
			best_alignment = alignment
			best_direction = candidate
	return direction.slerp(best_direction, 0.13).normalized()

func _update_pose(delta: float) -> void:
	if gun_root == null:
		return
	var target_position := Vector3(0.30, -0.31, -0.49)
	var target_rotation := Vector3.ZERO
	if owner_player != null and owner_player.is_sprinting:
		target_position = Vector3(0.50, -0.53, -0.28)
		target_rotation = Vector3(deg_to_rad(-24.0), deg_to_rad(-12.0), deg_to_rad(8.0))
	elif owner_player != null and owner_player.is_aiming:
		target_position = Vector3(0.018, -0.205, -0.35)
	else:
		var movement := owner_player.get_move_amount() if owner_player != null else 0.0
		target_rotation = Vector3(deg_to_rad(movement * 2.2), deg_to_rad(-movement * 1.4), 0.0)
	if reload_left > 0.0:
		var progress := 1.0 - maxf(reload_left, 0.0) / RELOAD_TIME
		var arc := sin(progress * PI)
		target_position += Vector3(-0.03, -0.09 * arc, 0.13 * arc)
		target_rotation.x += deg_to_rad(38.0 * arc)
	target_position.y -= (1.0 - equip_blend) * 0.42
	target_position.z += visual_recoil * 0.055
	target_rotation.x += deg_to_rad(visual_recoil * 8.0)
	var smooth := 1.0 - exp(-delta * 17.0)
	gun_root.position = gun_root.position.lerp(target_position, smooth)
	gun_root.rotation = gun_root.rotation.lerp(target_rotation, smooth)

func _build_effects_pool() -> void:
	effects = WeaponEffects.new()
	var scene_root := get_tree().current_scene
	if scene_root != null:
		scene_root.call_deferred("add_child", effects)

func _build_audio() -> void:
	shot_audio = AudioStreamPlayer.new()
	shot_audio.stream = SHOT_SOUND
	shot_audio.volume_db = -7.0
	add_child(shot_audio)
	reload_audio = AudioStreamPlayer.new()
	reload_audio.stream = RELOAD_SOUND
	reload_audio.volume_db = -9.0
	add_child(reload_audio)

func _play_sound(player_node: AudioStreamPlayer) -> void:
	if player_node != null:
		if player_node.playing:
			player_node.stop()
		player_node.play()

func _build_model() -> void:
	gun_root = Node3D.new()
	gun_root.name = "Pistol model"
	gun_root.position = Vector3(0.30, -0.31, -0.49)
	add_child(gun_root)
	var slide := _mat(Color("303733"), 0.68)
	var grip := _mat(Color("202622"), 0.92)
	_part("Slide", Vector3(0, 0.04, -0.10), Vector3(0.13, 0.11, 0.42), slide)
	_part("Grip", Vector3(0, -0.13, 0.08), Vector3(0.11, 0.27, 0.16), grip)
	_part("Barrel", Vector3(0, 0.045, -0.34), Vector3(0.065, 0.055, 0.14), grip)
	muzzle_flash = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	muzzle_flash.mesh = mesh
	muzzle_flash.position = Vector3(0, 0.045, -0.43)
	muzzle_flash.material_override = _mat(Color("fff0c0"), 0.2, Color("ff9e3e"), 4.2)
	muzzle_flash.visible = false
	gun_root.add_child(muzzle_flash)
	gun_root.visible = false

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
