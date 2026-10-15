extends SceneTree

## Headless integration harness for the actual front-end hand-off. It starts the
## default Boot scene, requests MP_DS_01 through the same private UI action a
## START MISSION button uses, and waits for SceneLoader to replace the current
## scene with the unchanged Desert gameplay scene.
const BOOT_SCENE := preload("res://scenes/Boot.tscn")
const DESERT_SCENE_PATH := "res://scenes/Main.tscn"
const MAX_FRAMES := 300

func _initialize() -> void:
	var boot := BOOT_SCENE.instantiate() as Control
	if boot == null:
		push_error("Boot-flow test could not instantiate Boot.tscn.")
		quit(1)
		return
	current_scene = boot
	root.add_child(boot)
	await process_frame
	boot.call("_show_menu")
	await process_frame
	boot.call("_start_selected_map")
	for frame in range(MAX_FRAMES):
		await process_frame
		if current_scene != null and current_scene != boot and current_scene.scene_file_path == DESERT_SCENE_PATH:
			if GameManager.state != GameManager.State.PLAYING:
				push_error("Boot-flow test reached Desert but GameManager is not Playing.")
				quit(1)
				return
			print("BOOT_FLOW_PASS frames=", frame + 1, " map=", GameManager.selected_map_id)
			quit()
			return
	push_error("Boot-flow test timed out before SceneLoader reached Main.tscn.")
	quit(1)
