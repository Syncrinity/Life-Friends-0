extends Node

const FRIEND_DATA_SAVE_PATH := "user://friends.json"

func save_friends(friends: Array) -> void:
	var file := FileAccess.open(FRIEND_DATA_SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Could not save friends to: " + FRIEND_DATA_SAVE_PATH)
		return

	var json_text := JSON.stringify(friends, "\t")
	file.store_string(json_text)


func load_friends() -> Array:
	if not FileAccess.file_exists(FRIEND_DATA_SAVE_PATH):
		return []

	var file := FileAccess.open(FRIEND_DATA_SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("Could not load friends from: " + FRIEND_DATA_SAVE_PATH)
		return []

	var json_text := file.get_as_text()
	var loaded_data = JSON.parse_string(json_text)

	if loaded_data == null:
		push_error("Could not parse friends JSON.")
		return []

	if loaded_data is Array:
		return loaded_data

	return []
