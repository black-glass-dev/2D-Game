extends Node

## Loads the versioned bilingual CSV catalog at runtime and registers ordinary
## Godot Translation resources. Keeping the source catalog as CSV lets content
## remain reviewable while avoiding a generated .godot import artifact in Git.
signal locale_changed(locale: String)

const AUTO := "AUTO"
const BENGALI := "bn"
const ENGLISH := "en"
const CATALOG_PATH := "res://data/localization/redline.csv"

var active_locale := ENGLISH
var catalog_translations: Dictionary = {}

func _ready() -> void:
	_load_csv_catalog()
	apply_preference(str(SettingsService.get_setting("language", AUTO)))

func apply_preference(preference: String) -> void:
	var requested := preference.to_lower()
	if requested == AUTO.to_lower():
		requested = OS.get_locale_language().to_lower()
	active_locale = BENGALI if requested.begins_with(BENGALI) else ENGLISH
	TranslationServer.set_locale(active_locale)
	locale_changed.emit(active_locale)

func set_language_preference(preference: String) -> void:
	var normalized := preference.to_upper()
	if normalized not in [AUTO, BENGALI.to_upper(), ENGLISH.to_upper()]:
		normalized = AUTO
	SettingsService.set_setting("language", normalized)
	apply_preference(normalized)

func is_bengali() -> bool:
	return active_locale.begins_with(BENGALI)

func _load_csv_catalog() -> void:
	var catalog := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if catalog == null:
		push_warning("LocalizationService could not open %s" % CATALOG_PATH)
		return
	var headers := catalog.get_csv_line()
	if headers.size() < 2 or headers[0].strip_edges().to_lower() != "keys":
		push_warning("LocalizationService found an invalid localization CSV header.")
		return
	for index in range(1, headers.size()):
		var locale := headers[index].strip_edges().to_lower()
		if locale.is_empty():
			continue
		var translation := Translation.new()
		translation.locale = locale
		catalog_translations[locale] = translation
	while not catalog.eof_reached():
		var row := catalog.get_csv_line()
		if row.is_empty() or row[0].strip_edges().is_empty():
			continue
		var key := row[0].strip_edges()
		for index in range(1, headers.size()):
			if index >= row.size():
				continue
			var locale := headers[index].strip_edges().to_lower()
			var translation := catalog_translations.get(locale) as Translation
			if translation != null:
				translation.add_message(key, row[index].strip_edges())
	for locale in catalog_translations:
		TranslationServer.add_translation(catalog_translations[locale] as Translation)
