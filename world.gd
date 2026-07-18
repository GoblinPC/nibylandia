extends Node2D

func _ready() -> void:
	MultiplayerManager.player_list_changed.connect(_refresh_status)
	MultiplayerManager.join_failed.connect(_on_join_failed)
	_refresh_status()
	if not MultiplayerManager.is_server:
		MultiplayerManager.request_spawn.rpc_id(1)

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
