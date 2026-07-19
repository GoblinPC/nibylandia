extends Node2D

var pause_menu: CanvasLayer


func _ready() -> void:
	MultiplayerManager.player_list_changed.connect(_refresh_status)
	MultiplayerManager.join_failed.connect(_on_join_failed)
	_refresh_status()
	if not MultiplayerManager.is_server:
		MultiplayerManager.request_spawn.rpc_id(1)
	_build_pause_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_menu.visible = not pause_menu.visible
		get_viewport().set_input_as_handled()


func _build_pause_menu() -> void:
	pause_menu = CanvasLayer.new()
	pause_menu.visible = false
	add_child(pause_menu)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(center)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	center.add_child(buttons)

	_add_pause_button(buttons, "Wroc do gry", func(): pause_menu.visible = false)
	_add_pause_button(buttons, "Rozlacz i wyjdz do menu", _on_leave_pressed)
	if not OS.has_feature("web"):
		_add_pause_button(buttons, "Wyjdz z gry", func(): get_tree().quit())


func _add_pause_button(parent: Container, label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(200, 28)
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(action)
	parent.add_child(button)

func _refresh_status() -> void:
	# liczone z faktycznej zawartosci "Players" (zreplikowanej przez
	# MultiplayerSpawner), nie z MultiplayerManager.players — to drugie
	# istnieje tylko po stronie serwera
	var count: int = $Players.get_child_count()
	var role := "SERWER" if MultiplayerManager.is_server else "KLIENT"
	$HUD/StatusLabel.text = "[%s] moje ID: %d — graczy online: %d" % [role, multiplayer.get_unique_id(), count]

func _on_join_failed(reason: String) -> void:
	$HUD/StatusLabel.text = "Blad: " + reason

func _on_leave_pressed() -> void:
	MultiplayerManager.leave_server()
	get_tree().change_scene_to_file("res://main_menu.tscn")
