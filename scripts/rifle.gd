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

var ammo := MAGAZINE_SIZE
var reserve := STARTING_RESERVE
var cooldown := 0.0
var reload_left := 0.0
var muzzle_flash: MeshInstance3D
var gun_root: Node3D
var weapon_time := 0.0
var blood_particles: GPUParticles3D
var rune_lights: Array[OmniLight3D] = []

func _ready() -> void:
	name = "Diablo Hellfire Weapon"
	_build_model()
	ammo_changed.emit(ammo, reserve)

func _process(delta: float) -> void:
	weapon_time += delta
	cooldown = maxf(cooldown - delta, 0.0)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			_complete_reload()

	if muzzle_flash != null:
		muzzle_flash.visible = cooldown > FIRE_INTERVAL * 0.45

	# Continuous idle weapon sway and breathing motion (Diablo Immortal style ambient movement)
	if gun_root != null:
		var idle_sway_x := sin(weapon_time * 2.2) * 0.008
		var idle_sway_y := cos(weapon_time * 1.5) * 0.012
		var idle_rot_z := sin(weapon_time * 1.8) * 0.015

		# Base resting position + sway offset
		gun_root.position.x = lerpf(gun_root.position.x, 0.32 + idle_sway_x, minf(delta * 8.0, 1.0))
		gun_root.position.y = lerpf(gun_root.position.y, -0.28 + idle_sway_y, minf(delta * 8.0, 1.0))
		gun_root.rotation.z = lerpf(gun_root.rotation.z, idle_rot_z, minf(delta * 8.0, 1.0))
		gun_root.rotation.x = lerpf(gun_root.rotation.x, 0.0, minf(delta * 12.0, 1.0))

	# Pulse rune emission light continuously
	var rune_pulse := (sin(weapon_time * 4.0) + 1.0) * 0.5 * 1.8 + 0.6
	for rune_light in rune_lights:
		if is_instance_valid(rune_light):
			rune_light.light_energy = rune_pulse

func try_fire(camera: Camera3D) -> bool:
	if reload_left > 0.0 or cooldown > 0.0:
		return false
	if ammo <= 0:
		start_reload()
		return false
	ammo -= 1
	cooldown = FIRE_INTERVAL
	ammo_changed.emit(ammo, reserve)
	if gun_root != null:
		gun_root.rotation.x = deg_to_rad(-8.5)
		gun_root.position.z += 0.06
	var origin: Vector3 = camera.global_position
	var direction: Vector3 = -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 80.0, 5)
	query.collide_with_areas = false
	var player := camera.get_parent().get_parent()
	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		shot_resolved.emit(false, "")
		return true
	var collider: Object = hit.get("collider")
	if collider != null and collider.has_method("take_damage"):
		collider.take_damage(DAMAGE)
		shot_resolved.emit(true, collider.name)
	else:
		shot_resolved.emit(false, "")
	return true

func start_reload() -> void:
	if reload_left > 0.0 or ammo >= MAGAZINE_SIZE or reserve <= 0:
		return
	reload_left = RELOAD_TIME
	weapon_message.emit("RELOADING HELLFIRE RIFLE")

func _complete_reload() -> void:
	var needed := MAGAZINE_SIZE - ammo
	var moved: int = mini(needed, reserve)
	ammo += moved
	reserve -= moved
	ammo_changed.emit(ammo, reserve)
	weapon_message.emit("READY")

func _build_model() -> void:
	gun_root = Node3D.new()
	gun_root.name = "Rifle model"
	gun_root.position = Vector3(0.32, -0.28, -0.56)
	add_child(gun_root)

	# High-detail materials: dark forged steel, dried blood crimson, glowing demonic runes, bone accents
	var dark_steel := _mat(Color("1a181b"), 0.45)
	var blood_stained_metal := _mat(Color("5e1114"), 0.35)
	var fresh_blood := _mat(Color("99080d"), 0.2, Color("b30b12"), 0.6)
	var bone_white := _mat(Color("c4b89c"), 0.75)
	var obsidian := _mat(Color("0f0d12"), 0.25)
	var glowing_rune_mat := _mat(Color("ff2200"), 0.1, Color("ff1a00"), 3.5)

	# Main Receiver & Frame with spiked demonic geometry
	_part("Receiver Main", Vector3(0, 0, 0), Vector3(0.18, 0.18, 0.54), dark_steel)
	_part("Receiver Spine Plate", Vector3(0, 0.10, 0.02), Vector3(0.14, 0.06, 0.48), blood_stained_metal)
	_part("Blood Streak Left", Vector3(-0.092, -0.01, -0.05), Vector3(0.01, 0.12, 0.35), fresh_blood)
	_part("Blood Streak Right", Vector3(0.092, -0.01, -0.05), Vector3(0.01, 0.12, 0.35), fresh_blood)

	# Serrated Bayonet / Underbarrel Scythe (Diablo Immortal dangerous aesthetic)
	_part("Bayonet Mount", Vector3(0, -0.08, -0.55), Vector3(0.06, 0.08, 0.20), dark_steel)
	_part("Blade Serrated Main", Vector3(0, -0.16, -0.75), Vector3(0.02, 0.18, 0.48), blood_stained_metal)
	_part("Blade Edge Blood Coat", Vector3(0, -0.22, -0.77), Vector3(0.025, 0.08, 0.46), fresh_blood)

	# Spikes along blade & barrel
	for z_pos in [-0.58, -0.68, -0.78, -0.88]:
		_part("Spike Blade", Vector3(0, -0.26, z_pos), Vector3(0.03, 0.06, 0.04), bone_white)

	# Barrel with Hellfire Rune Inlays
	_part("Heavy Barrel", Vector3(0, 0.025, -0.72), Vector3(0.08, 0.08, 0.42), obsidian)
	_part("Rune Core Glowing", Vector3(0, 0.025, -0.68), Vector3(0.085, 0.04, 0.32), glowing_rune_mat)

	# Demonic Rune OmniLight
	var rune_light := OmniLight3D.new()
	rune_light.name = "Rune Light"
	rune_light.position = Vector3(0, 0.05, -0.68)
	rune_light.light_color = Color("ff2200")
	rune_light.light_energy = 1.8
	rune_light.omni_range = 1.8
	gun_root.add_child(rune_light)
	rune_lights.append(rune_light)

	# Stock with Skull/Bone structure
	_part("Stock Base", Vector3(0, -0.04, 0.34), Vector3(0.14, 0.14, 0.36), obsidian)
	_part("Stock Spine Bone", Vector3(0, 0.04, 0.34), Vector3(0.10, 0.06, 0.32), bone_white)
	_part("Stock Buttpad Blood", Vector3(0, -0.04, 0.51), Vector3(0.15, 0.18, 0.04), fresh_blood)

	# Curved Curved Horn Magazine with Blood Drips
	_part("Extended Curved Mag", Vector3(0, -0.24, 0.04), Vector3(0.09, 0.32, 0.18), dark_steel)
	_part("Mag Blood Dip", Vector3(0, -0.36, 0.04), Vector3(0.095, 0.10, 0.185), fresh_blood)

	# Iron Sights / Horn Sights
	_part("Rear Horn Sight Left", Vector3(-0.06, 0.15, -0.08), Vector3(0.02, 0.09, 0.08), bone_white)
	_part("Rear Horn Sight Right", Vector3(0.06, 0.15, -0.08), Vector3(0.02, 0.09, 0.08), bone_white)
	_part("Front Sight Tip", Vector3(0, 0.11, -0.82), Vector3(0.02, 0.09, 0.04), fresh_blood)

	# Muzzle Flash
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "Muzzle flash"
	var flash := SphereMesh.new()
	flash.radius = 0.09
	flash.height = 0.18
	muzzle_flash.mesh = flash
	muzzle_flash.position = Vector3(0, 0.025, -0.95)
	muzzle_flash.material_override = _mat(Color("ffffff"), 0.1, Color("ff2a00"), 6.0)
	muzzle_flash.visible = false
	gun_root.add_child(muzzle_flash)

func _part(part_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position
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
