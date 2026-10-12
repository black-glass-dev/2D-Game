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
	root.add_child(scene_root)
	await _frames(24)
	player = get_first_node_in_group("player") as OutpostPlayer
	if player == null:
		push_error("Capture harness could not locate the player.")
		quit(1)
		return
	camera = player.camera
	player.can_control = false
	var views := [
		["01_spawn_ground", Vector3(0, 1.62, 13), Vector3(1.2, -.08, 8.0)],
		["02_main_lane", Vector3(0, 1.65, 13), Vector3(-18, 7.8, -15)],
		["03_emissive_crates", Vector3(1.6, 1.55, 9.0), Vector3(-2, 1.0, 5.0)],
		["04_outpost_facade", Vector3(-8.5, 1.65, 6.0), Vector3(-8.5, 3.0, -.9)],
		["05_mesa_horizon", Vector3(2.0, 2.0, 18.0), Vector3(1.0, 7.0, -70.0)],
		["06_raider_fifteen_m", Vector3(0, 1.62, 13), Vector3(-7.0, 1.3, 1.0)],
		["07_rifle_idle", Vector3(0, 1.62, 13), Vector3(0, 1.5, -15)],
		["08_ads", Vector3(-2.0, 1.62, 13), Vector3(-2.0, 1.4, -22)],
		["09_firing", Vector3(0, 1.62, 13), Vector3(0, 1.45, -20)],
		["10_low_hp", Vector3(0, 1.62, 13), Vector3(0, 1.45, -20)],
		["11_reload_crouch", Vector3(0, 1.62, 13), Vector3(-2.0, 1.2, 5.0)]
	]
	for entry in views:
		_set_view(entry[1], entry[2])
		if entry[0] == "08_ads":
			player.set_aim(true)
		elif entry[0] == "09_firing":
			scene_root._fire()
		elif entry[0] == "10_low_hp":
			player.take_damage(74, Vector3(-8, 1, 3))
		elif entry[0] == "11_reload_crouch":
			player.request_crouch()
			scene_root._reload_active_weapon()
		await _frames(5)
		_capture(entry[0])
		player.set_aim(false)
	await _frames(2)
	quit()

func _set_view(position_value: Vector3, target: Vector3) -> void:
	camera.global_position = position_value
	camera.look_at(target, Vector3.UP, true)

func _capture(name: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png(output_directory.path_join(name + ".png"))

func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func _read_output_directory() -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--output":
			return args[index + 1]
	return ProjectSettings.globalize_path("user://operation_redline_captures")
