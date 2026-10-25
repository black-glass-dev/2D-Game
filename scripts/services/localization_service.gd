extends Node

## Registers ordinary Godot Translation resources generated from the versioned
## bilingual CSV catalog. The generated script is a deliberate export anchor:
## Android builds must not rely on a CSV that is only opened dynamically at runtime.
signal locale_changed(locale: String)

const AUTO := "AUTO"
const BENGALI := "bn"
const ENGLISH := "en"
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
	# `redline_catalog.gd` is generated from the reviewable CSV by
	# tools/generate_embedded_localization_catalog.py. Referencing it here keeps
	# the catalog in every PCK/APK; the historical APK loaded raw keys because
	# its dynamic CSV path was not a safe export inclusion boundary.
	catalog_translations = RedlineLocalizationCatalog.build_translations()
	if catalog_translations.is_empty():
		push_error("LocalizationService generated catalog is empty.")
		return
	for locale in catalog_translations:
		var translation := catalog_translations[locale] as Translation
		if translation == null:
			push_error("LocalizationService generated catalog has an invalid %s translation." % locale)
			continue
		TranslationServer.add_translation(translation)
