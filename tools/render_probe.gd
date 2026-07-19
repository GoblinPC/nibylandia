extends SceneTree

# Sonda do debugowania auto-tilingu: maluje testowe jezioro malarzem terenu
# (dokladnie tym, ktorego uzywa sie w edytorze) i zrzuca screenshot do
# /tmp/probe.png. Uruchamiac BEZ --headless (potrzebny rendering):
#   godot --path . --script res://tools/render_probe.gd

var _frames := 0
var _map: TileMapLayer


func _initialize() -> void:
	var holder := Node2D.new()
	holder.scale = Vector2(2, 2)  # x2, zeby bylo widac piksele
	root.add_child(holder)
	_map = TileMapLayer.new()
	_map.tile_set = load("res://ground_tileset.tres")
	holder.add_child(_map)

	# tlo: trawa jako TEREN (tak bedzie sie malowac cala mape)
	var grass: Array[Vector2i] = []
	for x in range(20):
		for y in range(11):
			grass.append(Vector2i(x, y))
	_map.set_cells_terrain_connect(grass, 0, 2)  # TRAWA

	# jezioro z wcieciem — testuje krawedzie, narozniki i klify
	var cells: Array[Vector2i] = []
	for x in range(3, 13):
		for y in range(2, 9):
			if x >= 10 and y >= 7:
				continue  # wciecie w prawym dolnym rogu jeziora
			cells.append(Vector2i(x, y))
	_map.set_cells_terrain_connect(cells, 0, 1)  # WODA

	# wyspa na srodku — testuje klify i narozniki od strony wody
	var island: Array[Vector2i] = []
	for x in range(5, 8):
		for y in range(4, 6):
			island.append(Vector2i(x, y))
	_map.set_cells_terrain_connect(island, 0, 2)  # TRAWA

	# sciezka z ziemi po trawie (obok jeziora, bez dotykania wody)
	var path: Array[Vector2i] = []
	for y in range(1, 10):
		path.append(Vector2i(15, y))
		path.append(Vector2i(16, y))
	for x in range(15, 20):
		path.append(Vector2i(x, 9))
		path.append(Vector2i(x, 10))
	_map.set_cells_terrain_connect(path, 0, 0)  # ZIEMIA

	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frames += 1
	if _frames < 6:
		return
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("/private/tmp/claude-501/-Users-goblin/bbe340b1-9ded-416f-b8ab-a5965a833bd4/scratchpad/probe.png")
	quit()
