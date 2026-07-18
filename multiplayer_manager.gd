extends Node

# Fundament sieciowy. Serwer jest autorytatywny — spawnuje graczy i
# replikuje ich stan; klient wysyla tylko intencje.

signal server_started
signal join_failed(reason: String)
signal joined_server
signal player_list_changed

const DEFAULT_PORT := 9001
const PRODUCTION_URL := "wss://mp.nibylandia.goblinpc.pl"
const LOCAL_TEST_URL := "ws://127.0.0.1:9001"
const PLAYER_SCENE := preload("res://player.tscn")
const WORLD_SCENE := "res://world.tscn"

var players: Dictionary = {}  # peer_id -> Node (player instance)
var is_server := false
var online_mode := false


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if OS.has_feature("dedicated_server") or "--server" in OS.get_cmdline_user_args():
		call_deferred("start_server")


func start_server(port: int = DEFAULT_PORT) -> void:
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_server(port)
	if err != OK:
		push_error("Nie udalo sie uruchomic serwera na porcie %d (kod bledu %d)" % [port, err])
		return
	multiplayer.multiplayer_peer = peer
	is_server = true
	online_mode = true
	server_started.emit()
	print("[MP] Serwer nasluchuje na porcie ", port)
	get_tree().change_scene_to_file(WORLD_SCENE)


func join_server(url: String) -> void:
	var peer := WebSocketMultiplayerPeer.new()
	var err := peer.create_client(url)
	if err != OK:
		join_failed.emit("Nie udalo sie utworzyc polaczenia (kod bledu %d)" % err)
		return
	multiplayer.multiplayer_peer = peer
	online_mode = true


func leave_server() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	online_mode = false
	is_server = false
	players.clear()


func _on_peer_connected(_id: int) -> void:
	pass  # spawning waits for request_spawn(), see notes there


func _on_peer_disconnected(id: int) -> void:
	if not is_server:
		return
	_despawn_player(id)


func _on_connected_to_server() -> void:
	joined_server.emit()
	get_tree().change_scene_to_file(WORLD_SCENE)


# klient wywoluje to dopiero po faktycznym zaladowaniu wspolnej sceny (z
# world.gd's _ready). spawnowanie na peer_connected zamiast tego wygenerowaloby
# wyscig — serwer moglby dodac wezel do "Players" (replikowany przez
# MultiplayerSpawner) zanim klient w ogole ma zaladowana scene/spawner,
# cichutko gubiac spawn, takze dla wlasnego awatara laczacego sie gracza.
@rpc("any_peer", "call_remote", "reliable")
func request_spawn() -> void:
	if not is_server:
		return
	var id := multiplayer.get_remote_sender_id()
	if not players.has(id):
		_spawn_player(id)


func _on_connection_failed() -> void:
	join_failed.emit("Serwer odmowil polaczenia")
	online_mode = false


func _on_server_disconnected() -> void:
	join_failed.emit("Rozlaczono z serwerem")
	online_mode = false
	players.clear()


func _spawn_player(id: int) -> void:
	var world := get_tree().current_scene
	if world == null or not world.has_node("Players"):
		# scena jeszcze sie nie zaladowala (lub nie zdazyla) — sprobuj ponownie
		# na nastepnej klatce zamiast gubic gracza
		call_deferred("_spawn_player", id)
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	players[id] = player
	world.get_node("Players").add_child(player, true)
	player_list_changed.emit()


func _despawn_player(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
		player_list_changed.emit()
