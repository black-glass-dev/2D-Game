class_name WorldBuilder
extends RefCounted

## Runtime-built original art kit. Gameplay collision remains deliberately simple
## and separate: all terrain shaping, detail and dressing below are visual-only.
const SAND_TEXTURE := "res://assets/textures/sand_pbr_512.png"
const CONCRETE_TEXTURE := "res://assets/textures/concrete_pbr_512.png"
const METAL_TEXTURE := "res://assets/textures/corrugated_metal_512.png"
const WOOD_TEXTURE := "res://assets/textures/weathered_crate_512.png"
const ROCK_TEXTURE := "res://assets/textures/rock_strata_512.png"
const ASPHALT_TEXTURE := "res://assets/textures/asphalt_512.png"
const DETAIL_NORMAL := "res://assets/textures/terrain_detail_normal_512.png"

static func build(root: Node3D) -> void:
	_build_environment(root)
	# Texture tints stay deliberately brighter than the source maps. The maps hold
	# the micro-detail while these values preserve readable teal/orange separation
	# under the warm, low-angle key light.
	var sand := _pbr_material(SAND_TEXTURE, Color("efb677"), 0.91, 0.0, 7.5)
	var concrete := _pbr_material(CONCRETE_TEXTURE, Color("b9cac2"), 0.72, 0.08, 2.0)
	var metal := _pbr_material(METAL_TEXTURE, Color("a4beb3"), 0.46, 0.62, 3.0)
	var olive := _pbr_material(METAL_TEXTURE, Color("7c9270"), 0.56, 0.50, 2.0)
	var crate := _pbr_material(WOOD_TEXTURE, Color("d39163"), 0.77, 0.0, 2.0)
	var asphalt := _pbr_material(ASPHALT_TEXTURE, Color("849895"), 0.85, 0.0, 4.0)
	var rock := _pbr_material(ROCK_TEXTURE, Color("ad7f68"), 0.87, 0.0, 2.0)
	var dark := _flat_material(Color("17252a"), 0.62, 0.72)
	var glass := _glass_material(Color("4c9baa"))
	var lamp_glow := _flat_material(Color("ffd29a"), 0.28, 0.30, Color("ff8b38"), 1.75)

	# The collision floor is flat, predictable and unchanged. The high-density
	# terrain mesh above it creates dunes, tire-rutted paths and visual gullies.
	_box(root, "Gameplay collision floor", Vector3(0, -0.30, 0), Vector3(128, 0.55, 128), sand)
	_build_visual_terrain(root, sand)
	_build_ground_patches(root, concrete, asphalt)
	_build_perimeter(root, metal, olive, lamp_glow)
	_build_main_outpost(root, concrete, metal, olive, glass, dark, lamp_glow)
	_build_expanded_sectors(root, concrete, metal, olive, glass, dark, lamp_glow)
	_build_watchtower(root, metal, olive, glass, crate, lamp_glow)
	_build_cover_and_containers(root, crate, metal, olive, lamp_glow)
	_build_scatter(root, rock, crate, olive)
	_build_terrain_story_details(root, asphalt, rock, crate)
	_build_lamps(root, metal, lamp_glow)
	_add_distant_mountains(root, rock)
	_add_outpost_details(root, metal, olive, crate, lamp_glow)
	_add_sign(root)
	_build_atmosphere_particles(root)

static func set_presentation_quality(root: Node3D, effects_enabled: bool, adaptive_reduced: bool, quality_tier := "HIGH") -> void:
	var high_quality := quality_tier == "HIGH" or quality_tier == "ULTRA"
	var environment_node := root.get_node_or_null("Dusty sunset environment") as WorldEnvironment
	if environment_node != null and environment_node.environment != null:
		var environment := environment_node.environment
		environment.glow_enabled = effects_enabled and not adaptive_reduced and quality_tier != "LOW"
		environment.glow_intensity = 0.88 if quality_tier == "ULTRA" else 0.70
		environment.fog_density = 0.0080 if adaptive_reduced else (0.0061 if high_quality else 0.0052)
		environment.ssao_enabled = high_quality and not adaptive_reduced
		environment.adjustment_saturation = 1.06 if effects_enabled else 1.0
	var sun := root.get_node_or_null("Low desert sun") as DirectionalLight3D
	if sun != null:
		sun.shadow_enabled = quality_tier != "LOW" and not adaptive_reduced
		sun.directional_shadow_max_distance = 72.0 if quality_tier == "ULTRA" else (52.0 if high_quality else 32.0)
	var dust := root.get_node_or_null("Ambient dust motes") as GPUParticles3D
	if dust != null:
		dust.emitting = effects_enabled and quality_tier != "LOW"

static func set_wave_atmosphere(root: Node3D, wave_number: int) -> void:
	var env_node := root.get_node_or_null("Dusty sunset environment") as WorldEnvironment
	if env_node == null or env_node.environment == null:
		return
	var env := env_node.environment
	var wave := clampi(wave_number, 1, 3)
	var fog_targets := [0.0052, 0.0071, 0.0090]
	var colors := [Color("b98161"), Color("a9644c"), Color("874542")]
	var exposure_targets := [1.08, 1.0, 0.91]
	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(env, "fog_density", fog_targets[wave - 1], 2.2)
	tween.tween_property(env, "fog_light_color", colors[wave - 1], 2.2)
	tween.tween_property(env, "tonemap_exposure", exposure_targets[wave - 1], 2.2)
	var dust := root.get_node_or_null("Ambient dust motes") as GPUParticles3D
	if dust != null:
		dust.amount = 120 + wave * 70
	var embers := root.get_node_or_null("Distant embers") as GPUParticles3D
	if embers != null:
		embers.emitting = wave >= 2
		embers.amount = 18 * wave

static func _build_environment(root: Node3D) -> void:
	var world_env := WorldEnvironment.new()
	world_env.name = "Dusty sunset environment"
	var env := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("1b596b")
	sky_material.sky_horizon_color = Color("eda06d")
	sky_material.sky_curve = 0.14
	sky_material.sky_energy_multiplier = 0.82
	sky_material.ground_bottom_color = Color("311f2a")
	sky_material.ground_horizon_color = Color("9b5d54")
	sky_material.ground_curve = 0.08
	sky_material.sun_angle_max = 4.0
	sky_material.sun_curve = 0.055
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color("6aaab3")
	env.ambient_light_energy = 0.62
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.08
	env.tonemap_white = 1.45
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.02
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.07
	env.fog_enabled = true
	env.fog_light_color = Color("b98161")
	env.fog_light_energy = 0.68
	env.fog_density = 0.0052
	env.fog_aerial_perspective = 0.82
	env.fog_sky_affect = 0.72
	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity = 0.76
	env.glow_strength = 0.92
	env.glow_bloom = 0.18
	env.glow_hdr_threshold = 1.18
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.6
	world_env.environment = env
	root.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Low desert sun"
	sun.rotation_degrees = Vector3(-37, -54, 0)
	sun.light_color = Color("ffd1a0")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 58.0
	sun.directional_shadow_fade_start = 0.72
	sun.directional_shadow_blend_splits = true
	sun.light_angular_distance = 1.05
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.25
	root.add_child(sun)

	var rim := DirectionalLight3D.new()
	rim.name = "Cool sky fill"
	rim.rotation_degrees = Vector3(-62, 122, 0)
	rim.light_color = Color("5caac3")
	rim.light_energy = 0.30
	rim.shadow_enabled = false
	root.add_child(rim)

	# A visible sun disc and horizon dust cards give the compatibility renderer a
	# cinematic atmospheric silhouette without relying on expensive volumetrics.
	var sun_disc := MeshInstance3D.new()
	sun_disc.name = "Sun disc"
	var quad := QuadMesh.new()
	quad.size = Vector2(16.0, 16.0)
	sun_disc.mesh = quad
	sun_disc.position = Vector3(-45, 24, -70)
	sun_disc.material_override = _flat_material(Color("fff0c4"), 0.1, 0.0, Color("ffb24d"), 4.5, true)
	root.add_child(sun_disc)
	for index in range(4):
		var band := MeshInstance3D.new()
		band.name = "Horizon dust band"
		var band_mesh := QuadMesh.new()
		band_mesh.size = Vector2(128.0, 4.0 + index * 1.4)
		band.mesh = band_mesh
		band.position = Vector3(0, 3.0 + index * 2.1, -62.0 - index * 8.0)
		band.material_override = _flat_material(Color(0.66, 0.30 + index * .035, 0.26, 0.19 - index * .025), 1.0, 0.0, Color.TRANSPARENT, 0.0, true)
		root.add_child(band)

static func _build_visual_terrain(root: Node3D, material: Material) -> void:
	var resolution := 48
	var extent := 64.0
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var normal_step := extent * 2.0 / float(resolution)
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var fx := float(x) / float(resolution)
			var fz := float(z) / float(resolution)
			var px := lerpf(-extent, extent, fx)
			var pz := lerpf(-extent, extent, fz)
			var height := _terrain_height(px, pz)
			# Finite-difference normals let the broad dunes catch the warm sun and
			# fall into cool fill; this remains a cosmetic mesh above the flat collider.
			var slope_x := (_terrain_height(px + normal_step, pz) - _terrain_height(px - normal_step, pz)) / (normal_step * 2.0)
			var slope_z := (_terrain_height(px, pz + normal_step) - _terrain_height(px, pz - normal_step)) / (normal_step * 2.0)
			vertices.append(Vector3(px, height, pz))
			normals.append(Vector3(-slope_x, 1.0, -slope_z).normalized())
			uvs.append(Vector2(fx * 9.0, fz * 9.0))
	for z in range(resolution):
		for x in range(resolution):
			var a: int = z * (resolution + 1) + x
			var b: int = a + 1
			var c: int = a + resolution + 1
			var d: int = c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var terrain_mesh := ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var terrain := MeshInstance3D.new()
	terrain.name = "Undulating visual desert terrain"
	terrain.mesh = terrain_mesh
	terrain.material_override = material
	terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(terrain)

static func _terrain_height(x: float, z: float) -> float:
	# Three frequencies prevent the ground from reading as a single tiled plane.
	# The defended yard stays slightly recessed, leaving gameplay floor/collision
	# entirely untouched while pads and routes remain visually clean.
	var broad := sin(x * 0.049 + z * 0.012) * cos(z * 0.041) * 0.31
	var cross_dune := sin(x * 0.118 - z * 0.073) * 0.105
	var wind_ripples := sin(x * 0.39 + z * 0.14) * 0.018
	var road_flatten := exp(-abs(x) * 0.12) * 0.22
	var yard_flatten := exp(-(x * x + (z - 2.0) * (z - 2.0)) * 0.0026) * 0.24
	return -0.17 + broad + cross_dune + wind_ripples - road_flatten - yard_flatten

static func _build_ground_patches(root: Node3D, concrete: Material, asphalt: Material) -> void:
	_box(root, "Command yard concrete pad", Vector3(0, 0.035, -4), Vector3(36, 0.07, 24), concrete, false)
	_box(root, "North terrace concrete pad", Vector3(0, 0.035, -26), Vector3(46, 0.07, 10), concrete, false)
	_box(root, "West fuel-yard asphalt", Vector3(-35, 0.035, 14), Vector3(22, 0.07, 20), asphalt, false)
	_box(root, "South checkpoint asphalt", Vector3(0, 0.035, 35), Vector3(30, 0.07, 17), asphalt, false)
	_box(root, "Main packed dirt route", Vector3(0, 0.025, 21), Vector3(7.2, 0.05, 64), asphalt, false)

static func _build_perimeter(root: Node3D, metal: Material, olive: Material, glow: Material) -> void:
	for x in [-51.0, -40.0, -29.0, -18.0, -7.0, 7.0, 18.0, 29.0, 40.0, 51.0]:
		_box(root, "North blast barrier", Vector3(x, 1.1, -54), Vector3(9, 2.2, 1.0), metal)
		_box(root, "North barrier cap", Vector3(x, 2.28, -54), Vector3(9.2, 0.16, 1.18), olive, false)
	for z in [-43.0, -31.0, -19.0, -7.0, 7.0, 19.0, 31.0, 43.0]:
		_box(root, "West perimeter barrier", Vector3(-54, 1.1, z), Vector3(1, 2.2, 9), metal)
		_box(root, "East perimeter barrier", Vector3(54, 1.1, z), Vector3(1, 2.2, 9), metal)
	_box(root, "South gate left", Vector3(-33, 1.1, 54), Vector3(39, 2.2, 1), metal)
	_box(root, "South gate right", Vector3(33, 1.1, 54), Vector3(39, 2.2, 1), metal)
	# Fence posts and three wire strands create a readable defended boundary.
	for x in range(-50, 51, 10):
		_box(root, "Fence post", Vector3(float(x), 2.35, -52.8), Vector3(0.10, 2.5, 0.10), olive, false)
		for y in [1.8, 2.45, 3.05]:
			_box(root, "Perimeter wire", Vector3(float(x) + 5.0, y, -52.8), Vector3(10.0, 0.035, 0.035), glow, false)

static func _build_main_outpost(root: Node3D, concrete: Material, metal: Material, olive: Material, glass: Material, dark: Material, glow: Material) -> void:
	_box(root, "Command building collision", Vector3(-8.5, 2.1, -5.5), Vector3(9, 4, 9), concrete)
	_box(root, "Command roof slab", Vector3(-8.5, 4.35, -5.5), Vector3(10.2, 0.38, 10.2), metal)
	_box(root, "Command door", Vector3(-8.5, 1.45, -0.94), Vector3(2.55, 2.9, 0.12), dark, false)
	_build_building_facing(root, Vector3(-8.5, 0.12, -0.91), 8.6, 4.0, glass, metal, glow)
	_add_roof_clutter(root, Vector3(-8.5, 4.6, -5.5), metal, olive)
	_box(root, "Radio shed collision", Vector3(9, 1.6, -8), Vector3(8, 3, 6), olive)
	_box(root, "Radio shed roof", Vector3(9, 3.35, -8), Vector3(9.2, 0.38, 7.2), metal)
	_build_building_facing(root, Vector3(9, 0.12, -4.93), 7.6, 3.0, glass, metal, glow)
	_add_roof_clutter(root, Vector3(9, 3.55, -8), metal, olive)
	_box(root, "Depot collision", Vector3(11, 2.1, 8.5), Vector3(11, 4, 8), concrete)
	_box(root, "Depot roof", Vector3(11, 4.35, 8.5), Vector3(12.2, 0.42, 9.2), metal)
	_box(root, "Depot rolling door", Vector3(11, 1.55, 4.43), Vector3(4.2, 3.15, 0.15), dark, false)
	_build_building_facing(root, Vector3(11, 0.12, 4.40), 10.4, 4.0, glass, metal, glow)

static func _build_expanded_sectors(root: Node3D, concrete: Material, metal: Material, olive: Material, glass: Material, dark: Material, glow: Material) -> void:
	_box(root, "Fuel-yard canopy slab", Vector3(-35, 4.0, 14), Vector3(18, 0.40, 14), metal)
	for corner in [Vector3(-43, 2.0, 8), Vector3(-27, 2.0, 8), Vector3(-43, 2.0, 20), Vector3(-27, 2.0, 20)]:
		_box(root, "Canopy column", corner, Vector3(0.55, 4.0, 0.55), olive)
		_cylinder(root, "Canopy base", corner + Vector3(0, -1.95, 0), 0.44, 0.50, 10, metal)
	_box(root, "North hangar collision", Vector3(-33, 3.1, -31), Vector3(21, 6, 13), concrete)
	_box(root, "North hangar roof", Vector3(-33, 6.35, -31), Vector3(22.4, 0.55, 14.4), metal)
	_box(root, "North hangar opening", Vector3(-33, 2.0, -24.42), Vector3(8.8, 4.4, 0.12), dark, false)
	_build_building_facing(root, Vector3(-33, 0.15, -24.40), 20.4, 6.0, glass, metal, glow)
	_add_roof_clutter(root, Vector3(-33, 6.7, -31), metal, olive)
	_box(root, "East relay platform", Vector3(36, 1.0, -27), Vector3(20, 2.0, 15), concrete)
	_box(root, "East relay shed collision", Vector3(37, 3.2, -28), Vector3(9, 4.2, 7), olive)
	_box(root, "East relay roof", Vector3(37, 5.5, -28), Vector3(10.2, 0.4, 8.2), metal)
	_build_building_facing(root, Vector3(37, 1.05, -24.45), 8.4, 4.2, glass, metal, glow)
	_box(root, "Checkpoint gatehouse collision", Vector3(-12, 2.1, 36), Vector3(7, 4, 7), concrete)
	_box(root, "Checkpoint gatehouse roof", Vector3(-12, 4.35, 36), Vector3(8.2, 0.4, 8.2), metal)
	_build_building_facing(root, Vector3(-12, 0.12, 32.45), 6.5, 4.0, glass, metal, glow)
	_box(root, "Checkpoint barricade", Vector3(8, 1.0, 38), Vector3(12, 1.8, 1.0), olive)

static func _build_watchtower(root: Node3D, metal: Material, olive: Material, glass: Material, crate: Material, glow: Material) -> void:
	for corner in [Vector3(-21, 4, -18), Vector3(-15, 4, -18), Vector3(-21, 4, -12), Vector3(-15, 4, -12)]:
		_box(root, "Tower leg", corner, Vector3(0.58, 8, 0.58), metal)
	_box(root, "Watch platform", Vector3(-18, 8.0, -15), Vector3(7, 0.45, 7), metal)
	_box(root, "Watch cabin", Vector3(-18, 9.5, -15), Vector3(5.5, 2.4, 5.5), olive)
	_box(root, "Watch roof", Vector3(-18, 10.9, -15), Vector3(6.7, 0.38, 6.7), metal)
	for x in [-20.4, -18.0, -15.6]:
		_box(root, "Tower front window", Vector3(x, 9.55, -12.22), Vector3(1.65, 0.85, 0.08), glass, false)
	for x in [-21.1, -14.9]:
		_box(root, "Tower railing post", Vector3(x, 8.72, -11.7), Vector3(0.09, 1.15, 0.09), metal, false)
	_box(root, "Tower railing", Vector3(-18, 8.72, -11.7), Vector3(6.2, 0.08, 0.08), metal, false)
	# visible ladder, sandbag nest and antenna
	for y in range(8):
		_box(root, "Tower ladder rung", Vector3(-14.85, 0.75 + y * 0.78, -15), Vector3(0.62, 0.07, 0.08), metal, false)
	_box(root, "Tower ladder rail", Vector3(-15.15, 3.2, -15), Vector3(0.07, 6.0, 0.07), metal, false)
	_box(root, "Tower ladder rail", Vector3(-14.55, 3.2, -15), Vector3(0.07, 6.0, 0.07), metal, false)
	for x in [-19.9, -19.0, -18.1, -17.2, -16.3]:
		_box(root, "Tower sandbag", Vector3(x, 8.55, -12.0), Vector3(0.78, 0.38, 0.35), crate, false)
	_box(root, "Tower signal beacon", Vector3(-18, 11.55, -15), Vector3(0.4, 0.22, 0.4), glow, false)

static func _build_cover_and_containers(root: Node3D, crate: Material, metal: Material, olive: Material, glow: Material) -> void:
	var entries := [
		[Vector3(-2, 0.85, 5), Vector3(2.4, 1.7, 2.4)], [Vector3(3, 0.85, 7), Vector3(2.0, 1.7, 1.6)],
		[Vector3(-2, 0.85, 14), Vector3(3.2, 1.7, 1.5)], [Vector3(17, 0.85, -1), Vector3(2.0, 1.7, 2.0)],
		[Vector3(-18, 0.85, 5), Vector3(2.2, 1.7, 2.2)], [Vector3(18, 0.85, 17), Vector3(2.8, 1.7, 1.6)],
		[Vector3(-12, 0.85, 19), Vector3(2.0, 1.7, 2.0)], [Vector3(-39, 0.85, 10), Vector3(3.2, 1.7, 2.0)],
		[Vector3(-31, 0.85, 19), Vector3(2.0, 1.7, 2.0)], [Vector3(-40, 0.85, -19), Vector3(3.4, 1.7, 1.8)],
		[Vector3(-21, 0.85, -39), Vector3(2.6, 1.7, 2.2)], [Vector3(29, 0.85, -20), Vector3(3.0, 1.7, 2.0)],
		[Vector3(44, 0.85, -34), Vector3(2.4, 1.7, 2.4)], [Vector3(21, 0.85, 36), Vector3(3.2, 1.7, 1.7)],
		[Vector3(-3, 0.85, 42), Vector3(2.4, 1.7, 2.4)]
	]
	for index in range(entries.size()):
		var position: Vector3 = entries[index][0]
		var size: Vector3 = entries[index][1]
		_box(root, "Cargo container", position, size, crate)
		_box(root, "Container top rail", position + Vector3(0, size.y * 0.52, 0), Vector3(size.x + 0.10, 0.10, size.z + 0.10), metal, false)
		_box(root, "Container emissive ID", position + Vector3(0, 0.12, size.z * 0.52 + 0.02), Vector3(size.x * 0.66, 0.20, 0.045), glow, false)
		if index % 3 == 0:
			_box(root, "Container stencil", position + Vector3(-size.x * .22, 0.58, size.z * .52 + .04), Vector3(size.x * .30, .38, .035), olive, false)
	for position in [Vector3(-13.5, 0.46, 9.5), Vector3(-12.55, 0.46, 9.5), Vector3(-11.6, 0.46, 9.5), Vector3(18.0, 0.46, -5.0), Vector3(18.95, 0.46, -5.0), Vector3(-28.0, 0.46, -22.0), Vector3(26.0, 0.46, 37.0), Vector3(27.0, 0.46, 37.0)]:
		_box(root, "Sandbag", position, Vector3(0.86, 0.5, 0.42), crate, false)

static func _build_scatter(root: Node3D, rock: Material, crate: Material, olive: Material) -> void:
	# Deterministic scatter means there are no per-frame allocations and every
	# device sees the same tactical cover/landmarks.
	for index in range(112):
		var x := fposmod(float(index * 37), 104.0) - 52.0 + sin(index * 1.7) * 2.0
		var z := fposmod(float(index * 53), 100.0) - 50.0 + cos(index * 0.9) * 2.0
		if abs(x) < 19.0 and abs(z) < 25.0:
			continue
		var scale := 0.14 + float(index % 6) * 0.06
		var stone := MeshInstance3D.new()
		stone.name = "Desert rock scatter"
		var mesh := SphereMesh.new()
		mesh.radius = scale
		mesh.height = scale * (0.7 + float(index % 3) * 0.1)
		mesh.radial_segments = 6
		mesh.rings = 3
		stone.mesh = mesh
		stone.material_override = rock
		stone.position = Vector3(x, _terrain_height(x, z) + scale * 0.25, z)
		stone.rotation_degrees = Vector3(0, float(index * 31 % 360), float(index * 17 % 18) - 9.0)
		root.add_child(stone)
	for position in [Vector3(-43, .48, 8), Vector3(-42, .48, 19), Vector3(31, .48, -20), Vector3(37, .48, -35), Vector3(6, .48, 39)]:
		_cylinder(root, "Oil drum", position, 0.36, 0.92, 10, olive)
		_box(root, "Drum cap", position + Vector3(0, .48, 0), Vector3(.40, .04, .40), crate, false)

static func _build_terrain_story_details(root: Node3D, asphalt: Material, rock: Material, crate: Material) -> void:
	# Dark paired strips, gravel and small wind-bent brush break up the broad
	# terrain read without becoming gameplay geometry or allocating at runtime.
	for lane_x in [-2.15, 2.15]:
		for segment in range(16):
			var z := -44.0 + float(segment) * 5.8
			_box(root, "Weathered tyre track", Vector3(lane_x, .048, z), Vector3(.18, .025, 3.9), asphalt, false)
	for index in range(42):
		var x := fposmod(float(index * 29), 92.0) - 46.0 + sin(float(index) * 1.31) * 1.7
		var z := fposmod(float(index * 47), 88.0) - 44.0 + cos(float(index) * .81) * 1.5
		if abs(x) < 15.0 and abs(z) < 27.0:
			continue
		var ground := _terrain_height(x, z)
		var brush_root := Node3D.new()
		brush_root.name = "Dry brush cluster"
		brush_root.position = Vector3(x, ground + .13, z)
		brush_root.rotation_degrees.y = float(index * 37 % 360)
		root.add_child(brush_root)
		for blade_index in range(3):
			var blade_visual := MeshInstance3D.new()
			blade_visual.name = "Dry grass blade"
			var blade_mesh := CylinderMesh.new()
			blade_mesh.top_radius = .012
			blade_mesh.bottom_radius = .030
			blade_mesh.height = .34 + float((index + blade_index) % 4) * .055
			blade_mesh.radial_segments = 4
			blade_visual.mesh = blade_mesh
			blade_visual.material_override = crate if blade_index % 2 == 0 else rock
			blade_visual.position = Vector3((float(blade_index) - 1.0) * .07, blade_mesh.height * .45, .02 * float(blade_index % 2))
			blade_visual.rotation_degrees = Vector3(float(blade_index * 9 - 8), 0, float(blade_index * 12 - 12))
			blade_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			brush_root.add_child(blade_visual)
	for position in [Vector3(-25, .075, 26), Vector3(24, .075, 28), Vector3(-34, .075, -18), Vector3(31, .075, -14)]:
		_box(root, "Windblown scrap decal", position, Vector3(1.45, .028, .72), asphalt, false)

static func _build_lamps(root: Node3D, metal: Material, glow: Material) -> void:
	for position in [Vector3(-13, 3.5, -14), Vector3(13, 3.5, -14), Vector3(-23, 3.5, 11), Vector3(22, 3.5, 15), Vector3(-35, 3.5, 14), Vector3(36, 3.5, -27), Vector3(0, 3.5, 36)]:
		_lamp(root, position, metal, glow)
	for z in range(-45, 48, 7):
		_box(root, "Road guide light", Vector3(0, .24, z), Vector3(.24, .035, 2.6), glow, false)

static func _build_building_facing(root: Node3D, origin: Vector3, width: float, height: float, glass: Material, metal: Material, glow: Material) -> void:
	# Modular glass, mullions and trim sit on top of durable gameplay boxes. The
	# previous single solid frame hid every window; four slim rails now expose the
	# cool reflective pane and add a convincing architectural silhouette.
	for x in [-0.34, 0.0, 0.34]:
		var window_width := width * .20
		var window_height := height * .20
		var window_center := origin + Vector3(x * width, height * .57, -0.025)
		_box(root, "Reinforced teal window", window_center, Vector3(window_width, window_height, .06), glass, false)
		_box(root, "Window frame top", window_center + Vector3(0, window_height * .53, .045), Vector3(window_width + .09, .055, .055), metal, false)
		_box(root, "Window frame bottom", window_center + Vector3(0, -window_height * .53, .045), Vector3(window_width + .09, .055, .055), metal, false)
		_box(root, "Window frame left", window_center + Vector3(-window_width * .53, 0, .045), Vector3(.055, window_height + .10, .055), metal, false)
		_box(root, "Window frame right", window_center + Vector3(window_width * .53, 0, .045), Vector3(.055, window_height + .10, .055), metal, false)
		_box(root, "Window mullion", window_center + Vector3(0, 0, .047), Vector3(.04, window_height, .057), metal, false)
	_box(root, "Building lintel", origin + Vector3(0, height * .94, .03), Vector3(width + .18, .18, .14), metal, false)
	_box(root, "Emergency strip", origin + Vector3(0, height * .12, -.045), Vector3(width * .68, .08, .035), glow, false)

static func _add_roof_clutter(root: Node3D, position: Vector3, metal: Material, olive: Material) -> void:
	_box(root, "Roof air unit", position + Vector3(-1.5, .45, -.8), Vector3(1.7, .8, 1.0), olive, false)
	_box(root, "Roof air unit grille", position + Vector3(-1.5, .63, -1.32), Vector3(1.35, .42, .035), metal, false)
	_cylinder(root, "Roof water tank", position + Vector3(1.5, .8, .75), .52, 1.5, 12, metal)
	_box(root, "Roof antenna", position + Vector3(2.6, 1.55, -1.35), Vector3(.08, 2.4, .08), metal, false)

static func _add_outpost_details(root: Node3D, metal: Material, olive: Material, _crate: Material, glow: Material) -> void:
	_box(root, "Radio mast", Vector3(9.0, 6.6, -8.0), Vector3(.12, 6.0, .12), metal, false)
	_box(root, "Radio mast crossbar", Vector3(9.0, 8.4, -8.0), Vector3(2.7, .08, .08), metal, false)
	_box(root, "Radio beacon", Vector3(9.0, 9.55, -8.0), Vector3(.42, .22, .42), glow, false)
	_box(root, "Generator housing", Vector3(-4.8, 1.0, -14.2), Vector3(4.2, 1.8, .7), metal)
	_box(root, "Generator cable", Vector3(-2.8, .24, -14.2), Vector3(4.6, .09, .09), olive, false)
	for index in range(4):
		_box(root, "Generator indicator", Vector3(-6.0 + index * .8, 1.36, -14.57), Vector3(.28, .18, .05), glow, false)

static func _add_distant_mountains(root: Node3D, material: Material) -> void:
	var entries := [
		[Vector3(-56, 8, -66), 17.0], [Vector3(-30, 7, -74), 14.0], [Vector3(0, 10, -82), 22.0],
		[Vector3(36, 8, -72), 17.0], [Vector3(62, 12, -68), 23.0], [Vector3(-68, 10, -44), 18.0], [Vector3(70, 11, -39), 20.0]
	]
	for index in range(entries.size()):
		var mountain := MeshInstance3D.new()
		mountain.name = "Strata mesa depth layer"
		mountain.position = entries[index][0]
		var scale: float = entries[index][1]
		var mesh := CylinderMesh.new()
		mesh.top_radius = scale * (.30 + float(index % 3) * .05)
		mesh.bottom_radius = scale
		mesh.height = scale * (0.8 + float(index % 2) * .18)
		mesh.radial_segments = 7
		mountain.mesh = mesh
		mountain.material_override = material
		mountain.rotation_degrees.y = float(index * 37)
		root.add_child(mountain)
		# Mesa crown reads more naturally than a cone even through the fog.
		_cylinder(root, "Mesa crown", mountain.position + Vector3(0, scale * .45, 0), scale * .34, scale * .12, 7, material)

static func _build_atmosphere_particles(root: Node3D) -> void:
	var dust := GPUParticles3D.new()
	dust.name = "Ambient dust motes"
	dust.position = Vector3(0, 3.0, 0)
	dust.amount = 190
	dust.lifetime = 11.0
	dust.visibility_aabb = AABB(Vector3(-55, -2, -55), Vector3(110, 12, 110))
	var dust_mesh := QuadMesh.new()
	dust_mesh.size = Vector2(.13, .13)
	dust.draw_pass_1 = dust_mesh
	var dust_material := StandardMaterial3D.new()
	dust_material.albedo_color = Color(1.0, .66, .42, .20)
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust_material.vertex_color_use_as_albedo = true
	dust_mesh.material = dust_material
	var dust_process := ParticleProcessMaterial.new()
	dust_process.direction = Vector3(.35, .04, .18)
	dust_process.spread = 70.0
	dust_process.gravity = Vector3(0, .018, 0)
	dust_process.initial_velocity_min = .16
	dust_process.initial_velocity_max = .46
	dust_process.scale_min = .55
	dust_process.scale_max = 1.6
	dust.process_material = dust_process
	root.add_child(dust)
	var embers := GPUParticles3D.new()
	embers.name = "Distant embers"
	embers.position = Vector3(0, 1.3, -8)
	embers.amount = 34
	embers.lifetime = 4.0
	embers.emitting = false
	embers.visibility_aabb = AABB(Vector3(-36, -1, -36), Vector3(72, 12, 72))
	var ember_mesh := QuadMesh.new()
	ember_mesh.size = Vector2(.06, .06)
	embers.draw_pass_1 = ember_mesh
	var ember_material := _flat_material(Color("ffbf72"), 0.2, 0.0, Color("ff4d1c"), 3.0, true)
	ember_mesh.material = ember_material
	var ember_process := ParticleProcessMaterial.new()
	ember_process.direction = Vector3(.10, 1.0, .12)
	ember_process.spread = 35.0
	ember_process.gravity = Vector3(0, .20, 0)
	ember_process.initial_velocity_min = .25
	ember_process.initial_velocity_max = .65
	ember_process.scale_min = .7
	ember_process.scale_max = 1.2
	embers.process_material = ember_process
	root.add_child(embers)

static func _box(parent: Node3D, label: String, position_value: Vector3, size: Vector3, material: Material, collision := true) -> Node3D:
	var holder := Node3D.new()
	holder.name = label
	holder.position = position_value
	parent.add_child(holder)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
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

static func _cylinder(parent: Node3D, label: String, position_value: Vector3, radius: float, height: float, segments: int, material: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.position = position_value
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * .96
	mesh.height = height
	mesh.radial_segments = segments
	visual.mesh = mesh
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(visual)

static func _lamp(parent: Node3D, position_value: Vector3, pole_material: Material, glow_material: Material) -> void:
	_box(parent, "Lamp pole", position_value + Vector3(0, -1.6, 0), Vector3(.16, 3.3, .16), pole_material)
	_box(parent, "Lamp fixture", position_value, Vector3(.9, .20, .9), glow_material, false)
	var light := OmniLight3D.new()
	light.name = "Warm lamp spill"
	light.position = position_value
	light.light_color = Color("ffc271")
	light.light_energy = 1.35
	light.omni_range = 7.5
	light.omni_attenuation = 1.8
	parent.add_child(light)

static func _add_sign(root: Node3D) -> void:
	# A painted metal plaque gives the 3D text a high-contrast weathered backing;
	# billboard mode keeps the words readable through dust without using a UI label.
	var plaque := _flat_material(Color("3b2b29"), .72, .30)
	_box(root, "Redline Outpost painted sign plaque", Vector3(-8.4, 3.34, -0.83), Vector3(6.0, 1.72, .10), plaque, false)
	var outpost_sign := Label3D.new()
	outpost_sign.name = "REDLINE OUTPOST signage"
	outpost_sign.text = "REDLINE\nOUTPOST"
	outpost_sign.font_size = 96
	outpost_sign.outline_size = 18
	outpost_sign.modulate = Color("fff0c7")
	outpost_sign.outline_modulate = Color("5d2e2b")
	outpost_sign.pixel_size = .006
	outpost_sign.position = Vector3(-8.4, 3.4, -0.90)
	outpost_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	outpost_sign.render_priority = 1
	root.add_child(outpost_sign)

static func _pbr_material(texture_path: String, tint: Color, roughness: float, metallic: float, uv_scale: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = load(texture_path)
	material.normal_enabled = true
	material.normal_texture = load(DETAIL_NORMAL)
	material.normal_scale = .28
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.texture_repeat = true
	material.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	material.roughness = roughness
	material.metallic = metallic
	return material

static func _flat_material(color: Color, roughness := .72, metallic := .0, emission := Color.TRANSPARENT, energy := .0, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.no_depth_test = false
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material

static func _glass_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, .72)
	material.metallic = .45
	material.roughness = .18
	material.emission_enabled = true
	material.emission = color * .25
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material
