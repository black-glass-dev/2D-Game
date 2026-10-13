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
var muzzle_flare: MeshInstance3D
var muzzle_light: OmniLight3D
var muzzle_flash_left := 0.0
var effects: WeaponEffects
var shot_audio: AudioStreamPlayer
var reload_audio: AudioStreamPlayer
var equipped := false
var equip_blend := 0.0
var aim_assist_enabled := true
var effects_enabled := true
var shot_serial := 0
var visual_recoil := 0.0
var view_time := 0.0

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
	view_time += delta
	cooldown = maxf(cooldown - delta, 0.0)
	muzzle_flash_left = maxf(muzzle_flash_left - delta, 0.0)
	visual_recoil = move_toward(visual_recoil, 0.0, delta * 11.0)
	equip_blend = move_toward(equip_blend, 1.0 if equipped else 0.0, delta * 7.5)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			_complete_reload()
	var flash_active := effects_enabled and muzzle_flash_left > 0.0
	if muzzle_flash != null:
		muzzle_flash.visible = flash_active
	if muzzle_flare != null:
		muzzle_flare.visible = flash_active
		muzzle_flare.rotation_degrees.z = sin(view_time * 86.0) * 16.0
	if muzzle_light != null:
		muzzle_light.light_energy = 2.1 if flash_active else 0.0
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
	muzzle_flash_left = 0.12
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
	var surface_hint := "dirt"
	if not hit.is_empty():
		destination = hit["position"]
		impact_normal = hit["normal"]
		var collider: Object = hit.get("collider")
		var target := _resolve_raider(collider)
		surface_hint = _surface_hint(collider, target)
		headshot = collider is Area3D and collider.name == "Headshot hitbox"
		if target != null:
			var damage := DAMAGE * (2 if headshot else 1)
			eliminated = target.take_damage(damage, headshot)
			hit_target = true
			target_name = target.name
	if effects != null:
		effects.emit_shot(origin, destination, impact_normal, not hit.is_empty(), surface_hint)
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

func _surface_hint(collider: Object, target: Raider) -> String:
	if target != null:
		return "flesh"
	if collider is Node:
		var surface_name := (collider as Node).name.to_lower()
		if "metal" in surface_name or "lamp" in surface_name or "container" in surface_name or "barrier" in surface_name:
			return "metal"
		if "concrete" in surface_name or "building" in surface_name or "pad" in surface_name:
			return "concrete"
	return "dirt"

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
		var breathing := sin(view_time * 1.55) * .006
		target_position += Vector3(sin(view_time * .70) * .003, breathing, 0.0)
		target_rotation = Vector3(deg_to_rad(movement * 2.2 + breathing * 48.0), deg_to_rad(-movement * 1.4), 0.0)
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
	gun_root.name = "Detailed first-person service pistol"
	gun_root.position = Vector3(0.30, -0.31, -0.49)
	add_child(gun_root)
	var slide := _mat(Color("394344"), .40, .72)
	var worn := _mat(Color("69706a"), .48, .58)
	var polymer := _mat(Color("161e20"), .90, .05)
	var brass := _mat(Color("b98b48"), .42, .72)
	var glove := _mat(Color("2a3535"), .84, .08)
	var sleeve := _mat(Color("526353"), .92, .02)
	_part("Machined slide", Vector3(0, .045, -.11), Vector3(.145, .12, .47), slide)
	_part("Slide serrations", Vector3(.077, .055, .06), Vector3(.012, .075, .13), worn)
	_part("Polymer frame", Vector3(0, -.055, -.04), Vector3(.13, .12, .30), polymer)
	_part("Textured grip", Vector3(0, -.18, .095), Vector3(.12, .30, .17), polymer)
	_part("Magazine base", Vector3(0, -.35, .11), Vector3(.14, .045, .19), worn)
	_cylinder_part("Threaded barrel", Vector3(0, .05, -.37), .038, .15, 10, polymer)
	_part("Front sight", Vector3(0, .125, -.30), Vector3(.034, .05, .04), brass)
	_part("Rear sight", Vector3(0, .125, .08), Vector3(.070, .05, .04), brass)
	_build_arm(sleeve, glove)
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "Layered pistol muzzle flash"
	var mesh := SphereMesh.new()
	mesh.radius = .06
	mesh.height = .12
	mesh.radial_segments = 8
	muzzle_flash.mesh = mesh
	muzzle_flash.position = Vector3(0, .045, -.47)
	muzzle_flash.material_override = _mat(Color("fff0c0"), .2, .0, Color("ff9e3e"), 5.2)
	muzzle_flash.visible = false
	gun_root.add_child(muzzle_flash)
	muzzle_flare = MeshInstance3D.new()
	muzzle_flare.name = "Pistol tapered muzzle flare"
	var flare := CylinderMesh.new()
	flare.top_radius = .014
	flare.bottom_radius = .075
	flare.height = .23
	flare.radial_segments = 6
	muzzle_flare.mesh = flare
	muzzle_flare.position = Vector3(0, .045, -.57)
	muzzle_flare.rotation_degrees.x = 90.0
	muzzle_flare.material_override = _mat(Color("fff4d0"), .12, .0, Color("ff7b21"), 6.7)
	muzzle_flare.visible = false
	gun_root.add_child(muzzle_flare)
	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "Pistol pooled muzzle light"
	muzzle_light.light_color = Color("ff9e3e")
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 2.1
	muzzle_light.position = muzzle_flash.position
	gun_root.add_child(muzzle_light)
	gun_root.visible = false

func _build_arm(sleeve: Material, glove: Material) -> void:
	var arm := Node3D.new()
	arm.name = "Pistol gloved forearm"
	arm.position = Vector3(.09, -.21, .11)
	arm.rotation_degrees = Vector3(-17, 0, -7)
	gun_root.add_child(arm)
	_cylinder_part_on(arm, "Sleeve", Vector3(0, 0, .16), .09, .48, 10, sleeve)
	var hand := MeshInstance3D.new()
	hand.name = "Gloved pistol hand"
	var hand_mesh := SphereMesh.new()
	hand_mesh.radius = .115
	hand_mesh.height = .18
	hand_mesh.radial_segments = 10
	hand.mesh = hand_mesh
	hand.material_override = glove
	hand.position = Vector3(0, .02, -.15)
	arm.add_child(hand)

func _part(part_name: String, position_value: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position_value
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gun_root.add_child(visual)

func _cylinder_part(part_name: String, position_value: Vector3, radius: float, height: float, segments: int, material: Material) -> void:
	_cylinder_part_on(gun_root, part_name, position_value, radius, height, segments, material)

func _cylinder_part_on(parent: Node3D, part_name: String, position_value: Vector3, radius: float, height: float, segments: int, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position_value
	visual.rotation_degrees.x = 90
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)

func _mat(color: Color, roughness: float, metallic := 0.0, emission := Color.TRANSPARENT, energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.no_depth_test = true
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
