extends Node

## Locale selection is kept separate from visible UI migration. The CSV catalog
## is introduced now; M2 converts player-facing labels to translation keys after
## the Bengali font is imported and verified.
signal locale_changed(locale: String)

const AUTO := "AUTO"
const BENGALI := "bn"
const ENGLISH := "en"

var active_locale := ENGLISH

func _ready() -> void:
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
