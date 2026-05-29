extends PanelContainer

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var event_count_label: Label = $VBoxContainer/EventCountLabel

func setup_empty() -> void:
	day_label.text = ""
	event_count_label.text = ""
	modulate = Color(1, 1, 1, 0.2)

func setup_day(day: int, event_count: int, highlighted: bool) -> void:
	day_label.text = str(day)

	if event_count > 0:
		event_count_label.text = "%d hangout%s" % [
			event_count,
			"" if event_count == 1 else "s"
		]
	else:
		event_count_label.text = ""

	if highlighted:
		add_theme_stylebox_override("panel", get_highlight_stylebox())
	else:
		remove_theme_stylebox_override("panel")


func get_highlight_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.35, 0.8, 0.2)
	style.border_color = Color(0.2, 0.35, 0.8, 1.0)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
