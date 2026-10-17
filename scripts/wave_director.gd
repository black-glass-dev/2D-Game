class_name SurvivalDirector
extends Node

signal wave_started(wave_number: int, enemy_count: int)
signal enemy_spawn_requested(serial: int)
signal wave_cleared(wave_number: int)
signal operation_complete

const WAVE_SIZES := [6, 9, 12]
const INTERMISSION := 4.0
const SURVIVAL_MODE := "SURVIVAL"
const ENDLESS_MODE := "ENDLESS"
const NORMAL_DIFFICULTY := "NORMAL"
const VALID_DIFFICULTIES := ["EASY", NORMAL_DIFFICULTY, "HARD", "NIGHTMARE"]
const SPAWN_CADENCE_MULTIPLIERS := {
	"EASY": 1.15,
	NORMAL_DIFFICULTY: 1.0,
	"HARD": 0.88,
	"NIGHTMARE": 0.76,
}
const MIN_SPAWN_INTERVAL := 0.36

var current_wave := 0
var alive := 0
var waiting_to_spawn := 0
var spawn_serial := 0
var spawn_timer := 0.0
var intermission_left := 0.0
var running := false
var completed := false
var difficulty := NORMAL_DIFFICULTY
var mode := SURVIVAL_MODE

func configure_session(session_difficulty: String, session_mode: String) -> void:
	difficulty = session_difficulty if session_difficulty in VALID_DIFFICULTIES else NORMAL_DIFFICULTY
	mode = ENDLESS_MODE if session_mode == ENDLESS_MODE else SURVIVAL_MODE

func is_endless() -> bool:
	return mode == ENDLESS_MODE

func wave_size_for(wave_number: int) -> int:
	if wave_number < 1:
		return 0
	var profile_index := (wave_number - 1) % WAVE_SIZES.size()
	return WAVE_SIZES[profile_index]

func spawn_interval_for_wave(wave_number: int) -> float:
	var profile_wave := ((maxi(wave_number, 1) - 1) % WAVE_SIZES.size()) + 1
	var base_interval := maxf(0.48, 0.95 - profile_wave * 0.12)
	return maxf(MIN_SPAWN_INTERVAL, base_interval * float(SPAWN_CADENCE_MULTIPLIERS.get(difficulty, 1.0)))

func session_profile() -> Dictionary:
	return {
		"difficulty": difficulty,
		"mode": mode,
		"spawn_cadence_multiplier": float(SPAWN_CADENCE_MULTIPLIERS.get(difficulty, 1.0)),
		"completes_after_wave_three": not is_endless(),
	}

func start_operation() -> void:
	current_wave = 0
	alive = 0
	waiting_to_spawn = 0
	spawn_serial = 0
	completed = false
	running = true
	intermission_left = 1.5

func _process(delta: float) -> void:
	if not running or completed:
		return
	if intermission_left > 0.0:
		intermission_left -= delta
		if intermission_left <= 0.0:
			_start_next_wave()
		return
	if waiting_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			waiting_to_spawn -= 1
			alive += 1
			spawn_serial += 1
			enemy_spawn_requested.emit(spawn_serial)
			spawn_timer = spawn_interval_for_wave(current_wave)

func enemy_eliminated() -> void:
	if not running or alive <= 0:
		return
	alive -= 1
	if alive == 0 and waiting_to_spawn == 0:
		wave_cleared.emit(current_wave)
		if not is_endless() and current_wave >= WAVE_SIZES.size():
			completed = true
			running = false
			operation_complete.emit()
		else:
			intermission_left = INTERMISSION

func stop_operation() -> void:
	running = false

func _start_next_wave() -> void:
	current_wave += 1
	waiting_to_spawn = wave_size_for(current_wave)
	spawn_timer = 0.1
	wave_started.emit(current_wave, waiting_to_spawn)
