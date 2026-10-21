# Foundation Services Contract

## Purpose

M1 introduces global services without replacing the playable Desert runtime in the same batch. The services are registered as Godot autoloads and expose contracts that M2 menu/UI and M3 gameplay adapters can adopt incrementally.

## Autoload order

1. `SettingsService` — versioned `user://settings.cfg`, safe migration from `user://operation_redline_settings.cfg`.
2. `SaveService` — versioned `user://save.json`, unlocked maps, best results, last map, and future touch-layout ownership.
3. `MapRegistry` — scans `data/maps/*.tres` and validates `RedlineMapData` resources.
4. `InputService` — named keyboard/mouse/gamepad actions while legacy direct input remains active.
5. `AudioService` — prepares `Music`, `SFX`, and `UI` buses while current combat players retain their existing Master routing.
6. `LocalizationService` — resolves `Auto`, Bengali, and English locale preference using the initial CSV catalog.
7. `SceneLoader` — threaded request/progress/fade contract adopted by `Boot.tscn` for map hand-off.
8. `GameManager` — Boot/Menu/MapSelect/Loading/Playing/Pause/End state contract; `Main.tscn` marks Playing when it takes legacy gameplay ownership.

## Compatibility guarantees

- `Boot.tscn` is the project entry scene; `Main.tscn` remains directly runnable and is the selected `MP_DS_01` gameplay scene.
- Existing `RedlineSettings`, HUD layout ConfigFile, `WorldBuilder`, player controls, weapons, waves, and Desert spawns are not replaced in this batch.
- Legacy settings are copied into the new schema; the legacy file remains untouched.
- Legacy HUD-layout data remains untouched and is only marked as present in `save.json` for a future explicit import.
- Existing gamepad/keyboard/touch paths remain available; named InputMap actions are additive.

## MapData contract

`RedlineMapData` holds the map ID, bilingual name/tagline/environment, scene and thumbnail paths, difficulty/size labels, unlock state, music track, spawn profile, legend, and playable flag. `MP_DS_01.tres` packages the existing Desert spawn profile without changing any runtime spawn selection yet.
