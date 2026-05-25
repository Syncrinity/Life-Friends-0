extends Control

@export var profile_card_scene: PackedScene
@export var default_profile_image: Texture2D

@onready var search_bar: LineEdit = $Panel/VBoxContainer/HBoxContainer/SearchBar
@onready var add_friend_button: Button = $Panel/VBoxContainer/HBoxContainer/AddFriendButton
@onready var grid_container: GridContainer = $Panel/VBoxContainer/ScrollContainer/MarginContainer/GridContainer

@onready var add_friend_window: Window = $Panel/AddFriendWindow
@onready var first_name_input: LineEdit = $Panel/AddFriendWindow/VBoxContainer/FirstNameInput
@onready var last_name_input: LineEdit = $Panel/AddFriendWindow/VBoxContainer/LastNameInput
@onready var save_button: Button = $Panel/AddFriendWindow/VBoxContainer/SaveButton


var friends := []

func _ready() -> void:
	grid_container.columns = 3
	search_bar.placeholder_text = "Search"
	
	first_name_input.placeholder_text = "First name"
	last_name_input.placeholder_text = "Last name"
	
	add_friend_window.hide()
	
	# connect buttons
	add_friend_button.pressed.connect(_on_add_friend_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	search_bar.text_changed.connect(_on_search_text_changed)

	load_friend_data()
	add_friend_id_if_missing()
	populate_friend_grid(friends)
	

# disable the current focus when clicking on a non-focusable element
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if not search_bar.get_global_rect().has_point(get_global_mouse_position()):
				search_bar.release_focus()

func populate_friend_grid(friend_list: Array) -> void:
	for child in grid_container.get_children():
		child.queue_free()

	for friend in friend_list:
		var card = profile_card_scene.instantiate()
		grid_container.add_child(card)

		var image: Texture2D = default_profile_image
		var image_path: String = friend.get("image_path", "")

		if image_path != "":
			var loaded_texture = load(image_path)
			if loaded_texture is Texture2D:
				image = loaded_texture

		card.setup(
			friend.get("id", ""),
			friend.get("first_name", ""),
			friend.get("last_name", ""),
			image,
			friend.get("last_seen_timestamp", 0)
		)
		
		card.delete_requested.connect(_on_profile_delete_requested)
		card.check_in_requested.connect(_on_profile_check_in_requested)

func _on_profile_delete_requested(friend_id: String) -> void:
	friends = friends.filter(
		func(friend):
			return friend.get("id", "") != friend_id
	)

	DataManager.save_friends(friends)
	populate_friend_grid(friends)

func _on_add_friend_button_pressed() -> void:
	first_name_input.text = ""
	last_name_input.text = ""
	add_friend_window.show()
	first_name_input.grab_focus()


func _on_save_button_pressed() -> void:
	var first_name := first_name_input.text.strip_edges()
	var last_name := last_name_input.text.strip_edges()

	if first_name == "" and last_name == "":
		return

	var new_friend := {
		"id": str(Time.get_unix_time_from_system()) + "_" + str(randi()),
		"first_name": first_name,
		"last_name": last_name,
		"image_path": "",
		"last_seen_timestamp": 0,
		"hangouts": []
	}

	friends.append(new_friend)
	DataManager.save_friends(friends)

	add_friend_window.hide()
	search_bar.text = ""
	populate_friend_grid(friends)

func _on_search_text_changed(new_text: String) -> void:
	var search_text := new_text.to_lower().strip_edges()

	if search_text == "":
		populate_friend_grid(friends)
		return

	var filtered_friends := friends.filter(
		func(friend):
			var first_name := str(friend["first_name"]).to_lower()
			var last_name := str(friend["last_name"]).to_lower()
			var full_name := first_name + " " + last_name

			return first_name.contains(search_text) \
				or last_name.contains(search_text) \
				or full_name.contains(search_text)
	)

	populate_friend_grid(filtered_friends)

func load_friend_data() -> void:
	friends = DataManager.load_friends()

# patch -- adds a friendID if the friend didn't get one from an older patch
func add_friend_id_if_missing() -> void:
	var changed := false

	for friend in friends:
		if not friend.has("id"):
			friend["id"] = str(Time.get_unix_time_from_system()) + "_" + str(randi())
			changed = true

	if changed:
		DataManager.save_friends(friends)

func _on_profile_check_in_requested(friend_id: String) -> void:
	var now := Time.get_unix_time_from_system()

	for friend in friends:
		if friend.get("id", "") == friend_id:
			friend["last_seen_timestamp"] = now

			if not friend.has("hangouts"):
				friend["hangouts"] = []

			friend["hangouts"].append({
				"date_timestamp": now,
				"type": "Hangout",
				"notes": ""
			})

			break

	DataManager.save_friends(friends)
	populate_friend_grid(friends)
