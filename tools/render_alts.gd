extends SceneTree

# Podglad wszystkich altow (obrotow) kafelkow wody: kazdy wiersz = jeden
# kafelek atlasu, kolumny = kolejne alternatywy. Uruchamiac bez --headless.

var _frames := 0


func _initialize() -> void:
	var holder := Node2D.new()
	holder.scale = Vector2(3, 3)
	holder.position = Vector2(16, 16)
	root.add_child(holder)
	var map := TileMapLayer.new()
	map.tile_set = load("res://ground_tileset.tres")
	holder.add_child(map)

	var source: TileSetAtlasSource = map.tile_set.get_source(0)
	var coords_list := [Vector2i(2, 1), Vector2i(3, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
	for row in coords_list.size():
		var coords: Vector2i = coords_list[row]
		var alt_count := source.get_alternative_tiles_count(coords)
		for col in alt_count:
			var alt_id := source.get_alternative_tile_id(coords, col)
			map.set_cell(Vector2i(col * 2, row * 2), 0, coords, alt_id)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frames += 1
	if _frames < 6:
		return
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("/private/tmp/claude-501/-Users-goblin/bbe340b1-9ded-416f-b8ab-a5965a833bd4/scratchpad/alts.png")
	quit()
