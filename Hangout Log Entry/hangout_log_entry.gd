extends PanelContainer

signal edit_requested(friend_id: String, hangout_id: String)
signal selected(hangout_id: String, date_timestamp: int)

var friend_id := ""
var hangout_id := ""
var date_timestamp := 0

@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var date_label: Label = $HBoxContainer/VBoxContainer/DateLabel
@onready var notes_label: Label = $HBoxContainer/VBoxContainer/NotesLabel
@onready var icon_container: HBoxContainer = $HBoxContainer/IconContainer
@onready var edit_button: Button = $HBoxContainer/EditButton

func _ready() -> void:
	edit_button.pressed.connect(_on_edit_button_pressed)

func setup(participants: Array, _date_timestamp: int, date_text: String, hangout_type: String, notes: String, default_icon: Texture2D, p_friend_id: String, p_hangout_id: String) -> void:
	for child in icon_container.get_children():
		child.queue_free()
	
	for participant in participants:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(64, 64)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = default_icon
		icon_container.add_child(icon)
		
		var image: Texture2D = default_icon
		var image_path: String = participant.get("image_path", "")

		if image_path != "":
			var loaded_texture = load(image_path)
			if loaded_texture is Texture2D:
				image = loaded_texture

	var names := []
	for participant in participants:
		names.append("%s %s" % [
			participant.get("first_name", ""),
			participant.get("last_name", "")
		])

	name_label.text = ", ".join(names)
	date_timestamp = _date_timestamp
	date_label.text = "%s • %s" % [date_text, hangout_type]
	notes_label.text = notes if notes != "" else "No notes"
	friend_id = p_friend_id
	hangout_id = p_hangout_id


func _on_edit_button_pressed() -> void:
	edit_requested.emit(friend_id, hangout_id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		selected.emit(hangout_id, date_timestamp)
