class_name ServiceRifle
extends Node3D

signal ammo_changed(in_magazine: int, reserve: int)
signal weapon_message(text: String)
signal shot_resolved(hit: bool, target_name: String)
signal shot_feedback(headshot: bool, eliminated: bool, target_name: String)
signal weapon_fired(origin: Vector3)

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
var muzzle_flare: MeshInstance3D
var muzzle_light: OmniLight3D
var muzzle_flash_left := 0.0
var effects_enabled := true
var gun_root: Node3D
var owner_player: OutpostPlayer
var effects: WeaponEffects
var shot_audio: AudioStreamPlayer
var reload_audio: AudioStreamPlayer
var bloom := 0.0
var shot_serial := 0
var visual_recoil := 0.0
var aim_assist_enabled := true
var equipped := true
var equip_blend := 1.0
var view_time := 0.0

func _ready() -> void:
	name = "Service Rifle"
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
	equip_blend = move_toward(equip_blend, 1.0 if equipped else 0.0, delta * 7.5)
	bloom = move_toward(bloom, 0.0, delta * 0.026)
	visual_recoil = move_toward(visual_recoil, 0.0, delta * 9.0)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			_complete_reload()
	var flash_active := effects_enabled and muzzle_flash_left > 0.0
	if muzzle_flash != null:
		muzzle_flash.visible = flash_active
	if muzzle_flare != null:
		muzzle_flare.visible = flash_active
		muzzle_flare.rotation_degrees.z = sin(view_time * 92.0) * 18.0
	if muzzle_light != null:
		muzzle_light.light_energy = 2.5 if flash_active else 0.0
	_update_weapon_pose(delta)
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
	# Decouple the light/flash persistence from fire cadence: a short but stable
	# 0.12 s visual window remains readable on 30 FPS mobile hardware.
	muzzle_flash_left = 0.12
	shot_serial += 1
	var recoil_step: Vector2 = RECOIL_PATTERN[(shot_serial - 1) % RECOIL_PATTERN.size()]
	if owner_player != null:
		owner_player.add_recoil(recoil_step.x, recoil_step.y)
	bloom = minf(MAX_BLOOM, bloom + 0.0048 * _accuracy_multiplier())
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
			effects.emit_casing(gun_root.global_position + camera.global_transform.basis.x * 0.10, camera.global_transform.basis.x, camera.global_transform.basis.y, shot_serial)
	shot_resolved.emit(hit_target, target_name)
	shot_feedback.emit(headshot, eliminated, target_name)
	return true

func start_reload() -> void:
	if not equipped or reload_left > 0.0 or ammo >= MAGAZINE_SIZE or reserve <= 0:
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
		var target_point := raider.global_position + Vector3(0, 1.35, 0)
		var to_target := target_point - camera.global_position
		var distance := to_target.length()
		if distance < 1.0 or distance > 42.0:
			continue
		var target_direction := to_target / distance
		var alignment := direction.dot(target_direction)
		if alignment > best_alignment:
			best_alignment = alignment
			best_direction = target_direction
	return direction.slerp(best_direction, 0.16).normalized()

func _update_weapon_pose(delta: float) -> void:
	if gun_root == null:
		return
	var target_position := Vector3(0.32, -0.28, -0.56)
	var target_rotation := Vector3.ZERO
	if owner_player != null and owner_player.is_sprinting:
		target_position = Vector3(0.52, -0.52, -0.34)
		target_rotation = Vector3(deg_to_rad(-24.0), deg_to_rad(-13.0), deg_to_rad(8.0))
	elif owner_player != null and owner_player.is_aiming:
		# The open reflex sight aligns below the ADS reticle without ever placing a
		# solid mesh across the world view.
		target_position = Vector3(0.018, -0.17, -0.43)
		target_rotation = Vector3(deg_to_rad(-1.0), 0.0, 0.0)
	else:
		var movement := owner_player.get_move_amount() if owner_player != null else 0.0
		var breathing := sin(view_time * 1.45) * 0.006
		target_position += Vector3(sin(view_time * 0.72) * 0.004, breathing, 0.0)
		target_rotation = Vector3(deg_to_rad(movement * 2.0 + breathing * 48.0), deg_to_rad(-movement * 1.6), deg_to_rad(movement * 1.1))
	if reload_left > 0.0:
		var reload_progress := 1.0 - maxf(reload_left, 0.0) / RELOAD_TIME
		var reload_arc := sin(reload_progress * PI)
		target_position += Vector3(0.08, -0.10 * reload_arc, 0.14 * reload_arc)
		target_rotation.x += deg_to_rad(42.0 * reload_arc)
	target_position.y -= (1.0 - equip_blend) * 0.42
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
	# This deliberately uses an unshaded/no-depth viewmodel material fallback in
	# the Compatibility renderer. It provides the separate-viewmodel behaviour
	# (never clips into world walls) without an additional mobile SubViewport.
	gun_root = Node3D.new()
	gun_root.name = "Detailed first-person service rifle"
	gun_root.position = Vector3(0.32, -0.28, -0.56)
	add_child(gun_root)
	var gunmetal := _mat(Color("2b3838"), 0.42, 0.72)
	var worn_metal := _mat(Color("657469"), 0.48, 0.64)
	var polymer := _mat(Color("121b1d"), 0.88, 0.06)
	var olive := _mat(Color("596447"), 0.72, 0.18)
	var brass := _mat(Color("b98b48"), 0.42, 0.72)
	var glove := _mat(Color("293534"), 0.86, 0.10)
	var sleeve := _mat(Color("526353"), 0.92, 0.02)
	_part("Machined upper receiver", Vector3(0, 0, 0), Vector3(.19, .17, .54), gunmetal)
	_part("Lower receiver", Vector3(0, -.11, .02), Vector3(.17, .12, .38), worn_metal)
	_part("Ventilated handguard", Vector3(0, -.002, -.40), Vector3(.16, .15, .42), olive)
	_cylinder_part("Fluted barrel", Vector3(0, .025, -.73), .036, .36, 10, polymer)
	_cylinder_part("Flash hider", Vector3(0, .025, -.94), .052, .11, 8, gunmetal)
	_part("Adjustable stock", Vector3(0, -.045, .36), Vector3(.16, .14, .37), polymer)
	_part("Cheek riser", Vector3(0, .065, .39), Vector3(.10, .06, .20), worn_metal)
	_part("Curved magazine", Vector3(0, -.23, .055), Vector3(.11, .30, .18), polymer)
	_part("Magazine witness strip", Vector3(.058, -.23, .055), Vector3(.01, .18, .12), brass)
	_part("Rail", Vector3(0, .125, -.16), Vector3(.055, .032, .58), gunmetal)
	# The former opaque Holographic sight box was the black ADS rectangle seen on
	# phones. This is a real open reflex frame: four slim metal rails plus a
	# transparent emissive lens, never a dark filled panel over the world.
	_part("Open optic base", Vector3(0, .158, -.12), Vector3(.13, .032, .20), gunmetal)
	_part("Open optic left frame", Vector3(-.058, .215, -.12), Vector3(.016, .13, .18), worn_metal)
	_part("Open optic right frame", Vector3(.058, .215, -.12), Vector3(.016, .13, .18), worn_metal)
	_part("Open optic brow", Vector3(0, .276, -.12), Vector3(.13, .016, .18), worn_metal)
	_part("Open optic glass", Vector3(0, .216, -.20), Vector3(.092, .105, .007), _lens_material())
	for offset in [-.30, -.16, -.02, .12]:
		_part("Handguard vent", Vector3(.085, -.015, offset - .30), Vector3(.014, .045, .055), polymer)
	_build_arms(sleeve, glove)
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "Layered rifle muzzle flash"
	var flash := SphereMesh.new()
	flash.radius = .085
	flash.height = .19
	flash.radial_segments = 8
	muzzle_flash.mesh = flash
	muzzle_flash.position = Vector3(0, .025, -.995)
	muzzle_flash.material_override = _mat(Color("fff1c1"), .2, .0, Color("ff7d20"), 6.0)
	muzzle_flash.visible = false
	gun_root.add_child(muzzle_flash)
	# A separate tapered hot core makes the flash read as a layered combustion
	# event rather than a single glowing sphere, while reusing the same light.
	muzzle_flare = MeshInstance3D.new()
	muzzle_flare.name = "Rifle tapered muzzle flare"
	var flare := CylinderMesh.new()
	flare.top_radius = .018
	flare.bottom_radius = .11
	flare.height = .34
	flare.radial_segments = 6
	muzzle_flare.mesh = flare
	muzzle_flare.position = Vector3(0, .025, -1.15)
	muzzle_flare.rotation_degrees.x = 90.0
	muzzle_flare.material_override = _mat(Color("fff5ce"), .12, .0, Color("ff6e1d"), 7.5)
	muzzle_flare.visible = false
	gun_root.add_child(muzzle_flare)
	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "Rifle pooled muzzle light"
	muzzle_light.light_color = Color("ff9e41")
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 2.8
	muzzle_light.position = muzzle_flash.position
	gun_root.add_child(muzzle_light)

func _build_arms(sleeve: Material, glove: Material) -> void:
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "Gloved forearm"
		arm.position = Vector3(.20 * side, -.22, -.03 if side < 0.0 else -.28)
		arm.rotation_degrees = Vector3(-25, 0, -13 * side)
		gun_root.add_child(arm)
		_cylinder_part_on(arm, "Sleeve", Vector3(0, 0, .13), .075, .38, 10, sleeve)
		var hand := MeshInstance3D.new()
		hand.name = "Gloved hand"
		var hand_mesh := SphereMesh.new()
		hand_mesh.radius = .10
		hand_mesh.height = .16
		hand_mesh.radial_segments = 10
		hand.mesh = hand_mesh
		hand.material_override = glove
		hand.position = Vector3(0, .01, -.11)
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

func _lens_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.82, 0.78, 0.16)
	material.metallic = 0.35
	material.roughness = 0.08
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color("42d9c8")
	material.emission_energy_multiplier = 0.28
	material.no_depth_test = true
	return material

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
