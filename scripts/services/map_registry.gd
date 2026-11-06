extends Node

## Runtime data registry. A committed map resource is discovered from data/maps/
## and, for exported builds, also anchored by the generated packaged catalog. The
## catalog preserves the one-folder discovery model while preventing Android PCK
## exports from stripping resources which are otherwise only found dynamically.
signal maps_refreshed(map_count: int)
signal invalid_map_skipped(resource_path: String)

const MAP_DIRECTORY := "res://data/maps"

var maps_by_id: Dictionary = {}
var ordered_maps: Array[RedlineMapData] = []

func _ready() -> void:
	refresh()

func refresh() -> void:
	maps_by_id.clear()
	ordered_maps.clear()
	var discovered_paths: Array[String] = []
	var directory := DirAccess.open(MAP_DIRECTORY)
	if directory == null:
		push_warning("MapRegistry could not open %s; using packaged map anchors." % MAP_DIRECTORY)
	else:
		var resource_names := directory.get_files()
		resource_names.sort()
		for resource_name in resource_names:
			if resource_name.ends_with(".tres"):
				discovered_paths.append(MAP_DIRECTORY.path_join(resource_name))
	for resource_path in discovered_paths:
		_register_map(ResourceLoader.load(resource_path) as RedlineMapData, resource_path)
	# In a loose tree the resources above already registered. In an APK/PCK this
	# fallback is still available because each generated preload is export-visible.
	for map_data in RedlinePackagedMapCatalog.all_maps():
		_register_map(map_data, "packaged_catalog:%s" % map_data.id)
	ordered_maps.sort_custom(func(left: RedlineMapData, right: RedlineMapData) -> bool: return left.id < right.id)
	maps_refreshed.emit(ordered_maps.size())

func _register_map(map_data: RedlineMapData, source_label: String) -> void:
	if map_data == null:
		invalid_map_skipped.emit(source_label)
		return
	if not map_data.is_valid_map() or maps_by_id.has(map_data.id):
		if not map_data.is_valid_map():
			invalid_map_skipped.emit(source_label)
		return
	maps_by_id[map_data.id] = map_data
	ordered_maps.append(map_data)

func get_map(map_id: String) -> RedlineMapData:
	return maps_by_id.get(map_id) as RedlineMapData

func get_all_maps() -> Array[RedlineMapData]:
	return ordered_maps.duplicate()

func get_playable_maps() -> Array[RedlineMapData]:
	var playable_maps: Array[RedlineMapData] = []
	for map_data in ordered_maps:
		if map_data.playable:
			playable_maps.append(map_data)
	return playable_maps
