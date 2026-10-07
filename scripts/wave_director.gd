class_name SurvivalDirector
extends Node

signal wave_started(wave_number: int, enemy_count: int)
signal enemy_spawn_requested(serial: int)
signal wave_cleared(wave_number: int)
signal operation_complete

const WAVE_SIZES := [6, 9, 12]
const INTERMISSION := 4.0

var current_wave := 0
var alive := 0
var waiting_to_spawn := 0
var spawn_serial := 0
var spawn_timer := 0.0
var intermission_left := 0.0
var running := false
var completed := false

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
			spawn_timer = maxf(0.48, 0.95 - current_wave * 0.12)

func enemy_eliminated() -> void:
	if not running or alive <= 0:
		return
	alive -= 1
	if alive == 0 and waiting_to_spawn == 0:
		wave_cleared.emit(current_wave)
		if current_wave >= WAVE_SIZES.size():
			completed = true
			running = false
			operation_complete.emit()
		else:
			intermission_left = INTERMISSION

func stop_operation() -> void:
	running = false

func _start_next_wave() -> void:
	current_wave += 1
	waiting_to_spawn = WAVE_SIZES[current_wave - 1]
	spawn_timer = 0.1
	wave_started.emit(current_wave, waiting_to_spawn)
