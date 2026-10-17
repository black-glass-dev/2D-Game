extends Node

## Global state authority for the menu-to-gameplay pipeline. It intentionally has
## no scene-changing side effects yet: legacy Main.tscn remains independently
## runnable while M1 services are introduced around it.
signal state_changed(previous_state: State, next_state: State)
signal pause_changed(is_paused: bool)

enum State {
	BOOT,
	SPLASH,
	MAIN_MENU,
	MAP_SELECT,
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER,
	MISSION_COMPLETE,
}

var state: State = State.BOOT
var state_before_pause: State = State.PLAYING
const DIFFICULTIES := ["EASY", "NORMAL", "HARD", "NIGHTMARE"]
const MODES := ["SURVIVAL", "ENDLESS"]

var selected_map_id := "MP_DS_01"
var selected_difficulty := "NORMAL"
var selected_mode := "SURVIVAL"

func set_state(next_state: State) -> void:
	if state == next_state:
		return
	var previous_state := state
	state = next_state
	state_changed.emit(previous_state, state)

func select_map(map_id: String) -> void:
	if map_id.is_empty():
		return
	selected_map_id = map_id

func set_session_options(difficulty: String, mode: String) -> void:
	selected_difficulty = difficulty if difficulty in DIFFICULTIES else "NORMAL"
	selected_mode = mode if mode in MODES else "SURVIVAL"

func enter_pause() -> bool:
	if state != State.PLAYING:
		return false
	state_before_pause = state
	get_tree().paused = true
	set_state(State.PAUSED)
	pause_changed.emit(true)
	return true

func leave_pause() -> bool:
	if state != State.PAUSED:
		return false
	get_tree().paused = false
	set_state(state_before_pause)
	pause_changed.emit(false)
	return true

func is_gameplay_state() -> bool:
	return state == State.PLAYING or state == State.PAUSED
