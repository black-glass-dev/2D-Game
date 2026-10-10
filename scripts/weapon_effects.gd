class_name WeaponEffects
extends Node3D

## Small fixed pools prevent a burst of automatic fire from allocating new Nodes.
## These meshes are intentionally low-poly/emissive to suit the existing pixel-art
## presentation and stay inexpensive on compatibility-renderer Android devices.
const POOL_SIZE := 14

var effects_enabled := true
var tracer_pool: Array[MeshInstance3D] = []
var impact_pool: Array[MeshInstance3D] = []
var casing_pool: Array[MeshInstance3D] = []
var tracer_life := PackedFloat32Array()
var impact_life := PackedFloat32Array()
var casing_life := PackedFloat32Array()
var casing_velocity: Array[Vector3] = []
var tracer_cursor := 0
var impact_cursor := 0
var casing_cursor := 0

func _ready() -> void:
	name = "Pooled weapon effects"
	_build_pools()

func set_effects_enabled(enabled: bool) -> void:
	effects_enabled = enabled
	visible = enabled

func emit_shot(origin: Vector3, destination: Vector3, impact_normal: Vector3, show_impact: bool) -> void:
	if not effects_enabled:
		return
	_spawn_tracer(origin, destination)
	if show_impact:
		_spawn_impact(destination, impact_normal)

func emit_casing(origin: Vector3, right: Vector3, upward: Vector3, serial: int) -> void:
	if not effects_enabled:
		return
	var index := casing_cursor
	casing_cursor = (casing_cursor + 1) % POOL_SIZE
	var casing := casing_pool[index]
	casing.global_position = origin
	casing.global_rotation = Vector3(float(serial % 4) * 0.35, 0.0, 0.0)
	casing.visible = true
	casing_life[index] = 0.72
	var side := 1.2 + float(serial % 3) * 0.12
	casing_velocity[index] = right.normalized() * side + upward.normalized() * 1.05

func _process(delta: float) -> void:
	for index in range(POOL_SIZE):
		if tracer_life[index] > 0.0:
			tracer_life[index] -= delta
			if tracer_life[index] <= 0.0:
				tracer_pool[index].visible = false
		if impact_life[index] > 0.0:
			impact_life[index] -= delta
			if impact_life[index] <= 0.0:
				impact_pool[index].visible = false
		if casing_life[index] > 0.0:
			casing_life[index] -= delta
			var casing := casing_pool[index]
			var velocity_value: Vector3 = casing_velocity[index]
			velocity_value.y -= 8.0 * delta
			casing_velocity[index] = velocity_value
			casing.global_position += velocity_value * delta
			casing.rotate_x(11.0 * delta)
			casing.rotate_z(7.0 * delta)
			if casing_life[index] <= 0.0:
				casing.visible = false

func _build_pools() -> void:
	tracer_life.resize(POOL_SIZE)
	impact_life.resize(POOL_SIZE)
	casing_life.resize(POOL_SIZE)
	var tracer_material := _emissive_material(Color("ffd77a"), Color("ff9e3e"), 3.2)
	var impact_material := _emissive_material(Color("fff0bf"), Color("ffae49"), 3.8)
	var casing_material := _emissive_material(Color("9b733b"), Color.TRANSPARENT, 0.0)
	for _index in range(POOL_SIZE):
		var tracer := MeshInstance3D.new()
		tracer.name = "Tracer"
		var tracer_mesh := BoxMesh.new()
		tracer_mesh.size = Vector3(0.018, 0.018, 1.0)
		tracer.mesh = tracer_mesh
		tracer.material_override = tracer_material
		tracer.visible = false
		add_child(tracer)
		tracer_pool.append(tracer)

		var impact := MeshInstance3D.new()
		impact.name = "Bullet impact spark"
		var impact_mesh := SphereMesh.new()
		impact_mesh.radius = 0.055
		impact_mesh.height = 0.11
		impact_mesh.radial_segments = 6
		impact.mesh = impact_mesh
		impact.material_override = impact_material
		impact.visible = false
		add_child(impact)
		impact_pool.append(impact)

		var casing := MeshInstance3D.new()
		casing.name = "Ejected casing"
		var casing_mesh := CylinderMesh.new()
		casing_mesh.top_radius = 0.025
		casing_mesh.bottom_radius = 0.032
		casing_mesh.height = 0.10
		casing_mesh.radial_segments = 6
		casing.mesh = casing_mesh
		casing.material_override = casing_material
		casing.visible = false
		add_child(casing)
		casing_pool.append(casing)
		casing_velocity.append(Vector3.ZERO)

func _spawn_tracer(origin: Vector3, destination: Vector3) -> void:
	var index := tracer_cursor
	tracer_cursor = (tracer_cursor + 1) % POOL_SIZE
	var tracer := tracer_pool[index]
	var offset := destination - origin
	var distance := maxf(offset.length(), 0.05)
	tracer.global_position = origin.lerp(destination, 0.5)
	tracer.look_at(destination, Vector3.UP, true)
	tracer.scale = Vector3(1.0, 1.0, distance)
	tracer.visible = true
	tracer_life[index] = 0.045

func _spawn_impact(position_value: Vector3, normal: Vector3) -> void:
	var index := impact_cursor
	impact_cursor = (impact_cursor + 1) % POOL_SIZE
	var impact := impact_pool[index]
	impact.global_position = position_value + normal.normalized() * 0.02
	impact.visible = true
	impact_life[index] = 0.10

func _emissive_material(color: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
