extends CharacterBody2D

# Top-down, bez grawitacji. Ruch pelny 8-kierunkowy (wektor znormalizowany),
# ale grafika ma tylko jedna strone (prawo) odbijana w lewo — postac idaca
# po skosie w gore/dol po prostu patrzy w strone pozioma ruchu.

const SPEED := 100.0

var facing_right := true


func _ready() -> void:
	# set_multiplayer_authority() wywolane server-side przed add_child dziala
	# tylko na kopii wezla na serwerze — MultiplayerSpawner NIE replikuje tego
	# automatycznie. Kazdy peer (takze serwer) musi odtworzyc to sam, z nazwy
	# wezla (ktora replikuje sie poprawnie, bo po niej spawner dopasowuje
	# odpowiadajace sobie wezly) — inaczej wlasny gracz klienta myslalby, ze
	# nalezy do serwera: brak inputu, kamera wylaczona.
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())

	var config := SceneReplicationConfig.new()
	for prop in ["position", "velocity", "facing_right"]:
		var path := NodePath(".:" + prop)
		config.add_property(path)
		config.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	$MultiplayerSynchronizer.replication_config = config

	$Label.text = str(get_multiplayer_authority())
	modulate = Color.from_hsv(randf(), 0.55, 1.0)
	$Camera2D.enabled = is_multiplayer_authority()


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = direction * SPEED
		if direction.x != 0.0:
			facing_right = direction.x > 0.0
		move_and_slide()

	$Visual.scale.x = 1.0 if facing_right else -1.0
