class_name WorldBuilder
extends RefCounted

const SAND_TEXTURE := "res://assets/textures/sand_128.png"
const CONCRETE_TEXTURE := "res://assets/textures/concrete_128.png"
const METAL_TEXTURE := "res://assets/textures/painted_metal_128.png"
const WOOD_TEXTURE := "res://assets/textures/crate_128.png"

static func build(root: Node3D) -> void:
	_build_environment(root)
	# Muted earth colors keep the outpost readable in bright sunlight instead of
	# washing the whole screen orange. The 128x128 maps provide the pixel detail.
	var sand := _material(SAND_TEXTURE, Color("ae8259"))
	var concrete := _material(CONCRETE_TEXTURE, Color("79776b"))
	var metal := _material(METAL_TEXTURE, Color("637169"))
	var olive := _material(METAL_TEXTURE, Color("526049"))
	var crate := _material(WOOD_TEXTURE, Color("895c3c"))
	var dark := _flat_material(Color("252d2a"))
	var lamp_glow := _flat_material(Color("e6b66a"), Color("e28b3e"), 0.8)

	# A larger, layered 128x128 outpost gives the player routes, sightlines and
	# distinct combat zones rather than one small square survival room.
	_box(root, "Desert floor", Vector3(0, -0.25, 0), Vector3(128, 0.5, 128), sand)
	_box(root, "Command yard", Vector3(0, 0.12, -4), Vector3(36, 0.25, 24), concrete)
	_box(root, "North terrace", Vector3(0, 1.1, -26), Vector3(46, 2, 10), concrete)
	_box(root, "East ramp", Vector3(22, 0.62, -15), Vector3(8, 1, 17), sand)

	# Outer perimeter: each side is a different approach lane, with wide spaces
	# between the central command yard and the surrounding fuel/hangar sectors.
	for x in [-51.0, -40.0, -29.0, -18.0, -7.0, 7.0, 18.0, 29.0, 40.0, 51.0]:
		_box(root, "North perimeter barrier", Vector3(x, 1.1, -54), Vector3(9, 2.2, 1.0), metal)
	for z in [-43.0, -31.0, -19.0, -7.0, 7.0, 19.0, 31.0, 43.0]:
		_box(root, "West perimeter barrier", Vector3(-54, 1.1, z), Vector3(1, 2.2, 9), metal)
		_box(root, "East perimeter barrier", Vector3(54, 1.1, z), Vector3(1, 2.2, 9), metal)
	_box(root, "South gate left", Vector3(-33, 1.1, 54), Vector3(39, 2.2, 1), metal)
	_box(root, "South gate right", Vector3(33, 1.1, 54), Vector3(39, 2.2, 1), metal)

	# Main building: interior doorways and roof parapets prevent a flat arena silhouette.
	_box(root, "Command building", Vector3(-8.5, 2.1, -5.5), Vector3(9, 4, 9), concrete)
	_box(root, "Command building door", Vector3(-8.5, 1.4, -0.95), Vector3(2.4, 2.8, 0.25), dark, false)
	_box(root, "Command roof", Vector3(-8.5, 4.35, -5.5), Vector3(10, 0.45, 10), metal)
	_box(root, "Radio shed", Vector3(9, 1.6, -8), Vector3(8, 3, 6), olive)
	_box(root, "Radio shed roof", Vector3(9, 3.35, -8), Vector3(9, 0.5, 7), metal)
	_box(root, "Depot", Vector3(11, 2.1, 8.5), Vector3(11, 4, 8), concrete)
	_box(root, "Depot door", Vector3(11, 1.5, 4.45), Vector3(3.5, 3.0, 0.25), dark, false)

	# Expanded sectors: each one has a different silhouette and cover rhythm.
	_box(root, "West fuel-yard slab", Vector3(-35, 0.12, 14), Vector3(22, 0.25, 20), concrete)
	_box(root, "Fuel-yard canopy", Vector3(-35, 4.0, 14), Vector3(18, 0.45, 14), metal)
	for corner in [Vector3(-43, 2.0, 8), Vector3(-27, 2.0, 8), Vector3(-43, 2.0, 20), Vector3(-27, 2.0, 20)]:
		_box(root, "Canopy column", corner, Vector3(0.55, 4.0, 0.55), olive)
	_box(root, "North hangar", Vector3(-33, 3.1, -31), Vector3(21, 6, 13), concrete)
	_box(root, "North hangar opening", Vector3(-33, 2.0, -24.42), Vector3(8, 4.0, 0.28), dark, false)
	_box(root, "North hangar roof", Vector3(-33, 6.35, -31), Vector3(22.4, 0.55, 14.4), metal)
	_box(root, "East relay platform", Vector3(36, 1.0, -27), Vector3(20, 2.0, 15), concrete)
	_box(root, "East relay shed", Vector3(37, 3.2, -28), Vector3(9, 4.2, 7), olive)
	_box(root, "South checkpoint slab", Vector3(0, 0.12, 35), Vector3(30, 0.25, 17), concrete)
	_box(root, "Checkpoint gatehouse", Vector3(-12, 2.1, 36), Vector3(7, 4, 7), concrete)
	_box(root, "Checkpoint gatehouse roof", Vector3(-12, 4.35, 36), Vector3(8, 0.45, 8), metal)
	_box(root, "Checkpoint barricade", Vector3(8, 1.0, 38), Vector3(12, 1.8, 1.0), olive)

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
		[Vector3(-12, 0.85, 19), Vector3(2.0, 1.7, 2.0)],
		[Vector3(-39, 0.85, 10), Vector3(3.2, 1.7, 2.0)],
		[Vector3(-31, 0.85, 19), Vector3(2.0, 1.7, 2.0)],
		[Vector3(-40, 0.85, -19), Vector3(3.4, 1.7, 1.8)],
		[Vector3(-21, 0.85, -39), Vector3(2.6, 1.7, 2.2)],
		[Vector3(29, 0.85, -20), Vector3(3.0, 1.7, 2.0)],
		[Vector3(44, 0.85, -34), Vector3(2.4, 1.7, 2.4)],
		[Vector3(21, 0.85, 36), Vector3(3.2, 1.7, 1.7)],
		[Vector3(-3, 0.85, 42), Vector3(2.4, 1.7, 2.4)]
	]:
		_box(root, "Cargo crate", entry[0], entry[1], crate)
		_box(root, "Cargo stripe", entry[0] + Vector3(0, 0.15, entry[1].z * 0.52 + 0.02), Vector3(entry[1].x * 0.72, 0.28, 0.06), lamp_glow, false)

	# The route leads from the south checkpoint through the command yard to the
	# north terrace. Low-emission markers read clearly without bleaching the sand.
	for z in range(-45, 48, 7):
		_box(root, "Road marker", Vector3(0, 0.28, z), Vector3(0.22, 0.04, 2.7), lamp_glow, false)
	for position in [Vector3(-13, 3.5, -14), Vector3(13, 3.5, -14), Vector3(-23, 3.5, 11), Vector3(22, 3.5, 15), Vector3(-35, 3.5, 14), Vector3(36, 3.5, -27), Vector3(0, 3.5, 36)]:
		_lamp(root, position, metal, lamp_glow)

	_add_distant_mountains(root, dark)
	_add_outpost_details(root, metal, olive, crate, lamp_glow)
	_add_sign(root)

static func _build_environment(root: Node3D) -> void:
	var world_env := WorldEnvironment.new()
	world_env.name = "Dusty sunset environment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("786555")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("cbb198")
	env.ambient_light_energy = 0.48
	env.fog_enabled = true
	env.fog_light_color = Color("937863")
	env.fog_light_energy = 0.48
	env.fog_density = 0.0065
	world_env.environment = env
	root.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Low desert sun"
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("ffd8ae")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 46
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
	light.light_color = Color("e8a85c")
	light.light_energy = 1.15
	light.omni_range = 6.5
	parent.add_child(light)

static func _add_outpost_details(root: Node3D, metal: Material, olive: Material, crate: Material, glow: Material) -> void:
	# Small repeated shapes give the low-poly scene a lived-in military silhouette
	# without adding animated meshes or expensive dynamic lights.
	for position in [Vector3(4.0, 0.48, -13.0), Vector3(4.9, 0.48, -13.0), Vector3(13.0, 0.48, 15.0), Vector3(13.9, 0.48, 15.0), Vector3(-39.0, 0.48, 11.0), Vector3(-38.1, 0.48, 11.0), Vector3(-37.2, 0.48, 11.0), Vector3(34.0, 0.48, -36.0), Vector3(35.0, 0.48, -36.0)]:
		_barrel(root, position, olive)
	for position in [Vector3(-13.5, 0.46, 9.5), Vector3(-12.55, 0.46, 9.5), Vector3(-11.6, 0.46, 9.5), Vector3(18.0, 0.46, -5.0), Vector3(18.95, 0.46, -5.0), Vector3(-28.0, 0.46, -22.0), Vector3(26.0, 0.46, 37.0), Vector3(27.0, 0.46, 37.0)]:
		_box(root, "Sandbag", position, Vector3(0.86, 0.5, 0.42), crate, false)
	_box(root, "Radio mast", Vector3(9.0, 6.6, -8.0), Vector3(0.12, 6.0, 0.12), metal, false)
	_box(root, "Radio mast crossbar", Vector3(9.0, 8.4, -8.0), Vector3(2.7, 0.08, 0.08), metal, false)
	_box(root, "Radio beacon", Vector3(9.0, 9.55, -8.0), Vector3(0.42, 0.22, 0.42), glow, false)
	_box(root, "Supply rack", Vector3(-4.8, 1.0, -14.2), Vector3(4.2, 1.8, 0.7), metal)
	_box(root, "Supply rack crates", Vector3(-4.8, 2.05, -14.2), Vector3(3.65, 0.55, 0.62), crate, false)

static func _barrel(parent: Node3D, position: Vector3, material: Material) -> void:
	var barrel := MeshInstance3D.new()
	barrel.name = "Fuel drum"
	barrel.position = position
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.34
	mesh.bottom_radius = 0.34
	mesh.height = 0.92
	mesh.radial_segments = 8
	barrel.mesh = mesh
	barrel.material_override = material
	parent.add_child(barrel)

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
	# The command-building front faces the player spawn (+Z), so no Y flip is
	# needed. Keeping it unflipped avoids mirrored lettering on mobile.
	outpost_sign.rotation_degrees = Vector3.ZERO
	root.add_child(outpost_sign)

static func _material(texture_path: String, tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = load(texture_path)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = true
	material.uv1_scale = Vector3(8.0, 8.0, 8.0)
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
