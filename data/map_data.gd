class_name RedlineMapData
extends Resource

## Data-only contract for map cards, loading, score tracking, and spawn profiles.
## A map can be added by placing a valid .tres resource in data/maps/; code does
## not carry a per-map registry array.

@export var id := ""
@export var name_bn := ""
@export var name_en := ""
@export var tagline_bn := ""
@export var tagline_en := ""
@export_file("*.tscn") var scene_path := ""
@export_file("*.png") var thumbnail_path := ""
@export_range(1, 5, 1) var difficulty_stars := 1
@export var size_label := ""
@export var environment_bn := ""
@export var environment_en := ""
@export var max_waves := 3
@export_enum("UNLOCKED", "LOCKED", "COMING_SOON") var unlock_state := "UNLOCKED"
@export var music_track := ""
@export var spawn_profile: Dictionary = {}
@export var legend_bn: PackedStringArray = []
@export var legend_en: PackedStringArray = []
@export var playable := true

func is_valid_map() -> bool:
	return not id.is_empty() and not scene_path.is_empty() and ResourceLoader.exists(scene_path)

func localized_name(locale := "en") -> String:
	return name_bn if locale.begins_with("bn") else name_en

func localized_tagline(locale := "en") -> String:
	return tagline_bn if locale.begins_with("bn") else tagline_en

func localized_environment(locale := "en") -> String:
	return environment_bn if locale.begins_with("bn") else environment_en
