extends Control

const BG_COLOR := Color(0.06, 0.06, 0.11)
const TITLE_COLOR := Color(0.5, 0.85, 0.4)
const TEXT_DIM := Color(0.75, 0.78, 0.85)

const CONTROLS_TEXT := """WASD / strzalki — ruch
ESC — pauza (wkrotce)"""

var status_label: Label


func _ready() -> void:
	MultiplayerManager.join_failed.connect(_on_join_failed)

	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16)
	add_child(layout)

	var title := Label.new()
	title.text = "NIBYLANDIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	layout.add_child(title)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	layout.add_child(buttons)
	var play := _add_button(buttons, "Graj", _on_play_pressed)
	if OS.has_feature("editor"):
		_add_button(buttons, "Graj (lokalnie)", _on_play_local_pressed)

	var controls := Label.new()
	controls.text = CONTROLS_TEXT
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 10)
	controls.add_theme_color_override("font_color", TEXT_DIM)
	layout.add_child(controls)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", TEXT_DIM)
	layout.add_child(status_label)

	play.grab_focus()

func _add_button(parent: Container, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(150, 24)
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _on_play_pressed() -> void:
	status_label.text = "Laczenie..."
	MultiplayerManager.join_server(MultiplayerManager.PRODUCTION_URL)

func _on_play_local_pressed() -> void:
	status_label.text = "Laczenie z serwerem lokalnym..."
	MultiplayerManager.join_server(MultiplayerManager.LOCAL_TEST_URL)

func _on_join_failed(reason: String) -> void:
	status_label.text = "Blad: " + reason
