extends SceneTree

## Genuine renderer capture harness used by CI under Xvfb/OpenGL. It loads the
## real gameplay scene, drives only presentation-state methods and saves actual
## viewport pixels; it never draws, composites or mocks a screenshot.
var output_directory := ""
var scene_root: Node3D
var player: OutpostPlayer
var camera: Camera3D

func _initialize() -> void:
	output_directory = _read_output_directory()
	DirAccess.make_dir_recursive_absolute(output_directory)
	scene_root = load("res://scenes/Main.tscn").instantiate() as Node3D
	# The capture scene is instantiated directly instead of through
	# change_scene_to_packed(). Mark it current before _ready() runs so real
	# gameplay-owned systems (notably the pooled WeaponEffects child) attach to
	# this authentic scene exactly as they do in the game, rather than emitting
	# harmless but misleading empty-pool errors in the firing frame.
	current_scene = scene_root
	root.add_child(scene_root)
	# The complete runtime scene is built synchronously on add_child; a compact
	# settle avoids spending the software-render evidence budget on idle frames.
	await _frames(8)
	player = get_first_node_in_group("player") as OutpostPlayer
	if player == null:
		push_error("Capture harness could not locate the player.")
		quit(1)
		return
	camera = player.camera
	player.can_control = false
	# A controlled, real Raider guarantees the required close/mid character
	# comparison even before a timed wave spawner reaches its next interval.
	var showcase_raider := Raider.new()
	showcase_raider.setup(97)
	showcase_raider.position = Vector3(0, .15, -2.0)
	# Capture the Raider's tactical front, exactly as it faces a player during an
	# encounter. Gameplay normally supplies this yaw through RaiderTactics, but
	# this deterministic visual harness freezes input before the AI can turn.
	showcase_raider.rotation_degrees.y = 180.0
	scene_root.add_child(showcase_raider)
	await _frames(2)
	var views := [
		["01_spawn_ground", Vector3(0, 2.0, 13), Vector3(1.2, -.10, 7.5)],
		["02_main_lane", Vector3(0, 1.65, 13), Vector3(-18, 7.8, -15)],
		["03_emissive_crates", Vector3(1.6, 1.55, 9.0), Vector3(-2, 1.0, 5.0)],
		["04_outpost_facade", Vector3(-8.5, 1.65, 6.0), Vector3(-8.5, 3.0, -.9)],
		["05_mesa_horizon", Vector3(2.0, 2.0, 18.0), Vector3(1.0, 7.0, -70.0)],
		["06_raider_fifteen_m", Vector3(32.0, 1.62, 39.0), Vector3(32.0, 1.35, 24.0)],
		["07_raider_five_m", Vector3(32.0, 1.62, 29.0), Vector3(32.0, 1.35, 24.0)],
		["08_rifle_idle", Vector3(0, 1.62, 13), Vector3(0, 1.5, -15)],
		["09_ads", Vector3(-2.0, 1.62, 13), Vector3(-2.0, 1.4, -22)],
		["10_firing", Vector3(0, 1.62, 13), Vector3(0, 1.45, -20)],
		["11_low_hp", Vector3(0, 1.62, 13), Vector3(0, 1.45, -20)],
		["12_reload_crouch", Vector3(0, 1.62, 13), Vector3(-2.0, 1.2, 5.0)]
	]
	for entry in views:
		# The showcase actor moves into an unobstructed, genuine gameplay-space
		# lane only for the two mandated distance checks. Other frames keep the
		# ambient wave scene uncluttered.
		showcase_raider.visible = false
		if entry[0] == "06_raider_fifteen_m" or entry[0] == "07_raider_five_m":
			# The east-south service yard is deliberately open visual ground; it
			# gives the same real Raider a clear silhouette at both mandated ranges.
			showcase_raider.global_position = Vector3(32.0, .15, 24.0)
			showcase_raider.visible = true
		_set_view(entry[1], entry[2])
		if entry[0] == "09_ads":
			# The before comparison worktree intentionally predates the ADS controller.
			# Keep this harness source-compatible with both revisions; the old build
			# still receives its own historical aim state, while the current build
			# gets the exact 40-degree carbine FOV.
			if player.has_method("set_ads_fov"):
				player.set_ads_fov(40.0)
			player.set_aim(true)
		elif entry[0] == "10_firing":
			# The player stays frozen to keep all comparison frames reproducible.
			# Trigger the already-equipped weapon itself rather than Main._fire(),
			# which correctly rejects fire input while the frozen player has no control.
			# This still runs the real muzzle flash, light, tracer and pooled impacts.
			if scene_root.active_weapon != null:
				scene_root.active_weapon.try_fire(camera)
		elif entry[0] == "11_low_hp":
			player.take_damage(74, Vector3(-8, 1, 3))
		elif entry[0] == "12_reload_crouch":
			player.request_crouch()
			scene_root._reload_active_weapon()
		# Let the documented 0.16 s cubic ADS tween settle before taking the
		# evidence frame; short-lived muzzle/tracer/damage frames stay immediate.
		var settle_frames := 12 if entry[0] == "09_ads" else (1 if entry[0] == "10_firing" or entry[0] == "11_low_hp" else 2)
		await _frames(settle_frames)
		_capture(entry[0])
		player.set_aim(false)
	await _frames(2)
	quit()

func _set_view(position_value: Vector3, target: Vector3) -> void:
	camera.global_position = position_value
	# Camera3D renders along local -Z. Do not use the +Z model-front option here:
	# it reverses every intended Section 8 composition and points the capture away
	# from the real Raider/outpost target.
	camera.look_at(target, Vector3.UP)

func _capture(name: String) -> void:
	var output_path := output_directory.path_join(name + ".png")
	var image := root.get_texture().get_image()
	var result := image.save_png(output_path)
	print("GRAPHICS_CAPTURE ", output_path, " result=", result, " size=", image.get_width(), "x", image.get_height())

func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func _read_output_directory() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--output":
			return args[index + 1]
	return ProjectSettings.globalize_path("user://operation_redline_captures")
