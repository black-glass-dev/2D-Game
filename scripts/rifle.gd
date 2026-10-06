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

func _ready() -> void:
	name = "Service Rifle"
	_build_model()
	ammo_changed.emit(ammo, reserve)

func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			_complete_reload()
	if muzzle_flash != null:
		muzzle_flash.visible = cooldown > FIRE_INTERVAL * 0.45
	if gun_root != null:
		gun_root.rotation.x = lerpf(gun_root.rotation.x, 0.0, minf(delta * 14.0, 1.0))

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
		gun_root.rotation.x = deg_to_rad(-5.5)
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
	weapon_message.emit("RELOADING")

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
