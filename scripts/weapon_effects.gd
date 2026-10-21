class_name WeaponEffects
extends Node3D

## Fixed-size world-space FX pools. Effects never allocate in a firing burst;
## reusable meshes, decals and casings cycle through their slots. Ambient dust is
## GPUParticles3D in WorldBuilder, while combat puffs use these near-camera pools.
const POOL_SIZE := 18

var effects_enabled := true
var tracer_pool: Array[MeshInstance3D] = []
var impact_pool: Array[MeshInstance3D] = []
var casing_pool: Array[MeshInstance3D] = []
var smoke_pool: Array[MeshInstance3D] = []
var decal_pool: Array[MeshInstance3D] = []
var tracer_life := PackedFloat32Array()
var impact_life := PackedFloat32Array()
var casing_life := PackedFloat32Array()
var smoke_life := PackedFloat32Array()
var decal_life := PackedFloat32Array()
var casing_velocity: Array[Vector3] = []
var smoke_velocity: Array[Vector3] = []
var tracer_cursor := 0
var impact_cursor := 0
var casing_cursor := 0
var smoke_cursor := 0
var decal_cursor := 0
var tracer_material: StandardMaterial3D
var dirt_material: StandardMaterial3D
var metal_material: StandardMaterial3D
var concrete_material: StandardMaterial3D
var flesh_material: StandardMaterial3D
var smoke_material: StandardMaterial3D
var decal_material: StandardMaterial3D

func _ready() -> void:
	name = "Pooled combat FX"
	_build_pools()

func set_effects_enabled(enabled: bool) -> void:
	effects_enabled = enabled
	visible = enabled

func emit_shot(origin: Vector3, destination: Vector3, impact_normal: Vector3, show_impact: bool, surface_hint := "solid") -> void:
	if not effects_enabled:
		return
	_spawn_tracer(origin, destination)
	_spawn_smoke(origin, Vector3(0, .15, 0))
	if show_impact:
		_spawn_impact(destination, impact_normal, surface_hint)
		_spawn_decal(destination, impact_normal, surface_hint)

func emit_casing(origin: Vector3, right: Vector3, upward: Vector3, serial: int) -> void:
	if not effects_enabled:
		return
	var index := casing_cursor
	casing_cursor = (casing_cursor + 1) % POOL_SIZE
	var casing := casing_pool[index]
	casing.global_position = origin
	casing.global_rotation = Vector3(float(serial % 4) * .35, 0.0, 0.0)
	casing.visible = true
	casing_life[index] = .78
	var side := 1.2 + float(serial % 3) * .12
	casing_velocity[index] = right.normalized() * side + upward.normalized() * 1.05

func emit_footstep(position_value: Vector3, intensity := 1.0) -> void:
	if effects_enabled:
		_spawn_smoke(position_value + Vector3(0, .03, 0), Vector3(0, .18 * intensity, 0), .40)

func _process(delta: float) -> void:
	for index in range(POOL_SIZE):
		if tracer_life[index] > 0.0:
			tracer_life[index] -= delta
			if tracer_life[index] <= 0.0:
				tracer_pool[index].visible = false
		if impact_life[index] > 0.0:
			impact_life[index] -= delta
			impact_pool[index].scale += Vector3.ONE * delta * 3.4
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
		if smoke_life[index] > 0.0:
			smoke_life[index] -= delta
			var smoke := smoke_pool[index]
			smoke.global_position += smoke_velocity[index] * delta
			smoke.scale += Vector3.ONE * delta * .36
			smoke.modulate.a = clampf(smoke_life[index] * 1.5, 0.0, 1.0)
			if smoke_life[index] <= 0.0:
				smoke.visible = false
		if decal_life[index] > 0.0:
			decal_life[index] -= delta
			if decal_life[index] <= 0.0:
				decal_pool[index].visible = false

func _build_pools() -> void:
	tracer_life.resize(POOL_SIZE)
	impact_life.resize(POOL_SIZE)
	casing_life.resize(POOL_SIZE)
	smoke_life.resize(POOL_SIZE)
	decal_life.resize(POOL_SIZE)
	tracer_material = _emissive_material(Color("ffd77a"), Color("ff9e3e"), 3.8)
	dirt_material = _emissive_material(Color("d99462"), Color("ff8042"), .6)
	metal_material = _emissive_material(Color("fff3be"), Color("ffb13c"), 4.3)
	concrete_material = _emissive_material(Color("d0c7ae"), Color("ffb157"), 1.2)
	flesh_material = _emissive_material(Color("dc6659"), Color("ec4036"), 1.4)
	smoke_material = _transparent_material(Color(.58, .48, .40, .48))
	decal_material = _transparent_material(Color(.12, .07, .045, .62))
	for _index in range(POOL_SIZE):
		var tracer := MeshInstance3D.new()
		tracer.name = "Pooled bullet tracer"
		var tracer_mesh := BoxMesh.new()
		tracer_mesh.size = Vector3(.018, .018, 1.0)
		tracer.mesh = tracer_mesh
		tracer.material_override = tracer_material
		tracer.visible = false
		add_child(tracer)
		tracer_pool.append(tracer)

		var impact := MeshInstance3D.new()
		impact.name = "Pooled surface impact"
		var impact_mesh := SphereMesh.new()
		impact_mesh.radius = .055
		impact_mesh.height = .11
		impact_mesh.radial_segments = 7
		impact.mesh = impact_mesh
		impact.material_override = dirt_material
		impact.visible = false
		add_child(impact)
		impact_pool.append(impact)

		var casing := MeshInstance3D.new()
		casing.name = "Pooled ejected casing"
		var casing_mesh := CylinderMesh.new()
		casing_mesh.top_radius = .025
		casing_mesh.bottom_radius = .032
		casing_mesh.height = .10
		casing_mesh.radial_segments = 6
		casing.mesh = casing_mesh
		casing.material_override = _emissive_material(Color("b5833e"), Color.TRANSPARENT, 0.0)
		casing.visible = false
		add_child(casing)
		casing_pool.append(casing)
		casing_velocity.append(Vector3.ZERO)

		var smoke := MeshInstance3D.new()
		smoke.name = "Pooled smoke puff"
		var smoke_mesh := SphereMesh.new()
		smoke_mesh.radius = .13
		smoke_mesh.height = .19
		smoke_mesh.radial_segments = 6
		smoke.mesh = smoke_mesh
		smoke.material_override = smoke_material
		smoke.visible = false
		add_child(smoke)
		smoke_pool.append(smoke)
		smoke_velocity.append(Vector3.ZERO)

		var decal := MeshInstance3D.new()
		decal.name = "Pooled bullet scar decal"
		var decal_mesh := QuadMesh.new()
		decal_mesh.size = Vector2(.12, .12)
		decal.mesh = decal_mesh
		decal.material_override = decal_material
		decal.visible = false
		add_child(decal)
		decal_pool.append(decal)

func _spawn_tracer(origin: Vector3, destination: Vector3) -> void:
	var index := tracer_cursor
	tracer_cursor = (tracer_cursor + 1) % POOL_SIZE
	var tracer := tracer_pool[index]
	var offset := destination - origin
	var distance := maxf(offset.length(), .05)
	tracer.global_position = origin.lerp(destination, .5)
	tracer.look_at(destination, Vector3.UP, true)
	tracer.scale = Vector3(1.0, 1.0, distance)
	tracer.visible = true
	tracer_life[index] = .045

func _spawn_impact(position_value: Vector3, normal: Vector3, surface_hint: String) -> void:
	var index := impact_cursor
	impact_cursor = (impact_cursor + 1) % POOL_SIZE
	var impact := impact_pool[index]
	impact.global_position = position_value + normal.normalized() * .025
	impact.scale = Vector3.ONE
	impact.material_override = _impact_material(surface_hint)
	impact.visible = true
	impact_life[index] = .14 if surface_hint == "metal" else .20
	_spawn_smoke(impact.global_position, normal.normalized() * .22, .48)

func _spawn_decal(position_value: Vector3, normal: Vector3, surface_hint: String) -> void:
	if surface_hint == "flesh":
		return
	var index := decal_cursor
	decal_cursor = (decal_cursor + 1) % POOL_SIZE
	var decal := decal_pool[index]
	decal.global_position = position_value + normal.normalized() * .012
	var facing := decal.global_position - normal.normalized()
	decal.look_at(facing, Vector3.UP, true)
	decal.scale = Vector3.ONE * (.70 if surface_hint == "metal" else 1.0)
	decal.visible = true
	decal_life[index] = 5.4

func _spawn_smoke(position_value: Vector3, direction: Vector3, life := .62) -> void:
	var index := smoke_cursor
	smoke_cursor = (smoke_cursor + 1) % POOL_SIZE
	var smoke := smoke_pool[index]
	smoke.global_position = position_value
	smoke.scale = Vector3.ONE
	smoke.modulate = Color.WHITE
	smoke.visible = true
	smoke_life[index] = life
	smoke_velocity[index] = direction + Vector3(.018 * float(index % 3), .08, .016 * float((index + 1) % 3))

func _impact_material(surface_hint: String) -> StandardMaterial3D:
	match surface_hint:
		"metal":
			return metal_material
		"concrete":
			return concrete_material
		"flesh":
			return flesh_material
		_:
			return dirt_material

func _emissive_material(color: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .7
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material

func _transparent_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return material
