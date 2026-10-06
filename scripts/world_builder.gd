class_name WorldBuilder
extends RefCounted

const SAND_TEXTURE := "res://assets/textures/sand_128.png"
const CONCRETE_TEXTURE := "res://assets/textures/concrete_128.png"
const METAL_TEXTURE := "res://assets/textures/painted_metal_128.png"
const WOOD_TEXTURE := "res://assets/textures/crate_128.png"

static func build(root: Node3D) -> void:
	_build_environment(root)
	var sand := _material(SAND_TEXTURE, Color("c99055"))
	var concrete := _material(CONCRETE_TEXTURE, Color("7f7566"))
	var metal := _material(METAL_TEXTURE, Color("69766d"))
	var olive := _material(METAL_TEXTURE, Color("596448"))
	var crate := _material(WOOD_TEXTURE, Color("a46f3f"))
	var dark := _flat_material(Color("1d2521"))
	var lamp_glow := _flat_material(Color("ffb35c"), Color("ff8b36"), 2.0)

	# Ground and a raised, walkable command-yard create the arena's first depth layer.
	_box(root, "Desert floor", Vector3(0, -0.25, 0), Vector3(72, 0.5, 72), sand)
	_box(root, "Command yard", Vector3(0, 0.12, -4), Vector3(26, 0.25, 20), concrete)
	_box(root, "North terrace", Vector3(0, 1.1, -19), Vector3(32, 2, 8), concrete)
	_box(root, "East ramp", Vector3(15, 0.62, -10), Vector3(6, 1, 12), sand)

	# Outer perimeter: gaps deliberately create three readable attack lanes.
	for x in [-30.0, -22.0, -14.0, 14.0, 22.0, 30.0]:
		_box(root, "Perimeter barrier", Vector3(x, 1.1, -28), Vector3(7, 2.2, 1.0), metal)
	for z in [-19.0, -10.0, 0.0, 10.0, 19.0]:
		_box(root, "West barrier", Vector3(-29, 1.1, z), Vector3(1, 2.2, 7), metal)
		_box(root, "East barrier", Vector3(29, 1.1, z), Vector3(1, 2.2, 7), metal)
	_box(root, "South gate left", Vector3(-14, 1.1, 28), Vector3(18, 2.2, 1), metal)
	_box(root, "South gate right", Vector3(14, 1.1, 28), Vector3(18, 2.2, 1), metal)

	# Main building: interior doorways and roof parapets prevent a flat arena silhouette.
	_box(root, "Command building", Vector3(-8.5, 2.1, -5.5), Vector3(9, 4, 9), concrete)
	_box(root, "Command building door", Vector3(-8.5, 1.4, -0.95), Vector3(2.4, 2.8, 0.25), dark, false)
	_box(root, "Command roof", Vector3(-8.5, 4.35, -5.5), Vector3(10, 0.45, 10), metal)
	_box(root, "Radio shed", Vector3(9, 1.6, -8), Vector3(8, 3, 6), olive)
	_box(root, "Radio shed roof", Vector3(9, 3.35, -8), Vector3(9, 0.5, 7), metal)
	_box(root, "Depot", Vector3(11, 2.1, 8.5), Vector3(11, 4, 8), concrete)
	_box(root, "Depot door", Vector3(11, 1.5, 4.45), Vector3(3.5, 3.0, 0.25), dark, false)

	# Watchtower: a strong vertical landmark and a good reference when navigating by touch.
	for corner in [Vector3(-21, 4, -18), Vector3(-15, 4, -18), Vector3(-21, 4, -12), Vector3(-15, 4, -12)]:
		_box(root, "Tower leg", corner, Vector3(0.65, 8, 0.65), metal)
	_box(root, "Watch platform", Vector3(-18, 8.0, -15), Vector3(7, 0.6, 7), metal)
	_box(root, "Watch cabin", Vector3(-18, 9.5, -15), Vector3(5.5, 2.4, 5.5), olive)
	_box(root, "Watch roof", Vector3(-18, 10.9, -15), Vector3(6.5, 0.5, 6.5), metal)

	# Cover clusters make approaches different and give both sides usable combat positions.
	for entry in [
		[Vector3(-2, 0.85, 5), Vector3(2.4, 1.7, 2.4)],
		[Vector3(3, 0.85, 7), Vector3(2.0, 1.7, 1.6)],
		[Vector3(-2, 0.85, 14), Vector3(3.2, 1.7, 1.5)],
		[Vector3(17, 0.85, -1), Vector3(2.0, 1.7, 2.0)],
		[Vector3(-18, 0.85, 5), Vector3(2.2, 1.7, 2.2)],
		[Vector3(18, 0.85, 17), Vector3(2.8, 1.7, 1.6)],
		[Vector3(-12, 0.85, 19), Vector3(2.0, 1.7, 2.0)]
	]:
		_box(root, "Cargo crate", entry[0], entry[1], crate)
		_box(root, "Cargo stripe", entry[0] + Vector3(0, 0.15, entry[1].z * 0.52 + 0.02), Vector3(entry[1].x * 0.72, 0.28, 0.06), lamp_glow, false)

	# Road markings and lamps are visual rhythm, not gameplay blockers.
	for z in range(-15, 23, 5):
		_box(root, "Road marker", Vector3(0, 0.28, z), Vector3(0.22, 0.04, 2.4), lamp_glow, false)
	for position in [Vector3(-13, 3.5, -14), Vector3(13, 3.5, -14), Vector3(-23, 3.5, 11), Vector3(22, 3.5, 15)]:
		_lamp(root, position, metal, lamp_glow)

	_add_distant_mountains(root, dark)
	_add_sign(root)

static func _build_environment(root: Node3D) -> void:
	var world_env := WorldEnvironment.new()
	world_env.name = "Dusty sunset environment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d2865c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e6ad83")
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color("c98c67")
	env.fog_light_energy = 0.8
	env.fog_density = 0.012
	world_env.environment = env
	root.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Low desert sun"
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("ffd0a0")
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70
	root.add_child(sun)

static func _box(parent: Node3D, label: String, position: Vector3, size: Vector3, material: Material, collision := true) -> Node3D:
	var holder := Node3D.new()
	holder.name = label
	holder.position = position
	parent.add_child(holder)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	holder.add_child(visual)
	if collision:
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		holder.add_child(body)
	return holder

static func _lamp(parent: Node3D, position: Vector3, pole_material: Material, glow_material: Material) -> void:
	_box(parent, "Lamp pole", position + Vector3(0, -1.6, 0), Vector3(0.16, 3.3, 0.16), pole_material)
	_box(parent, "Lamp", position, Vector3(0.8, 0.22, 0.8), glow_material, false)
	var light := OmniLight3D.new()
	light.name = "Warm pool light"
	light.position = position
	light.light_color = Color("ffad5b")
	light.light_energy = 2.2
	light.omni_range = 9.0
	parent.add_child(light)

static func _add_distant_mountains(root: Node3D, material: Material) -> void:
	for entry in [
		[Vector3(-38, 7, -47), 12.0], [Vector3(-21, 5, -50), 9.0],
		[Vector3(2, 8, -52), 14.0], [Vector3(28, 6, -48), 11.0], [Vector3(47, 9, -51), 15.0]
	]:
		var mountain := MeshInstance3D.new()
		mountain.name = "Distant mesa"
		mountain.position = entry[0]
		var mesh := CylinderMesh.new()
		mesh.top_radius = entry[1] * 0.45
		mesh.bottom_radius = entry[1]
		mesh.height = entry[1] * 1.2
		mesh.radial_segments = 6
		mountain.mesh = mesh
		mountain.material_override = material
		root.add_child(mountain)

static func _add_sign(root: Node3D) -> void:
	var outpost_sign := Label3D.new()
	outpost_sign.name = "Outpost sign"
	outpost_sign.text = "REDLINE\nOUTPOST"
	outpost_sign.font_size = 64
	outpost_sign.outline_size = 8
	outpost_sign.modulate = Color("ffe0ad")
	outpost_sign.position = Vector3(-8.4, 3.4, -0.88)
	outpost_sign.rotation_degrees = Vector3(0, 180, 0)
	root.add_child(outpost_sign)

static func _material(texture_path: String, tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = load(texture_path)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = BaseMaterial3D.TEXTURE_REPEAT_ENABLED
	material.roughness = 0.9
	return material

static func _flat_material(color: Color, emission := Color.TRANSPARENT, energy := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
