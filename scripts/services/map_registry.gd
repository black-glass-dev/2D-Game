extends Node

## Runtime data registry. Exported PCK directories are scanned rather than a
## code-owned array so a new map card is added by dropping a valid .tres resource
## into data/maps alongside its thumbnail.
signal maps_refreshed(map_count: int)
signal invalid_map_skipped(resource_path: String)

const MAP_DIRECTORY := "res://data/map_data.gd".get_base_dir().path_join("maps")

var maps_by_id: Dictionary = {}
var ordered_maps: Array[RedlineMapData] = []

func _ready() -> void:
	refresh()

func refresh() -> void:
	maps_by_id.clear()
	ordered_maps.clear()
	var directory := DirAccess.open(MAP_DIRECTORY)
	if directory == null:
		push_warning("MapRegistry could not open %s" % MAP_DIRECTORY)
		maps_refreshed.emit(0)
		return
	var resource_names := directory.get_files()
	resource_names.sort()
	for resource_name in resource_names:
		if not resource_name.ends_with(".tres"):
			continue
		var resource_path := MAP_DIRECTORY.path_join(resource_name)
		var map_data := ResourceLoader.load(resource_path) as RedlineMapData
		if map_data == null or not map_data.is_valid_map() or maps_by_id.has(map_data.id):
			invalid_map_skipped.emit(resource_path)
			continue
		maps_by_id[map_data.id] = map_data
		ordered_maps.append(map_data)
	maps_refreshed.emit(ordered_maps.size())

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
