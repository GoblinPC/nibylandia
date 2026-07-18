extends SceneTree

# Jednorazowy (uruchamiany recznie) builder TileSetu podloza z osobnych
# plikow 16x16 w art/tilemap/. Uruchom ponownie po kazdej zmianie tych
# plikow:
#   godot --headless --script res://tools/build_ground_tileset.gd
#
# Minimalny "blob" zestaw dla terrainu Match Sides: pelny kafelek x2
# (trawa, ziemia), jedna krawedz i dwa rogi (wypukly/wklesly) — kazdy
# rotowany o 90/180/270 stopni przez flip_h/flip_v/transpose zamiast
# rysowania osobnej grafiki na kazda orientacje.

const TRAWA := 0
const ZIEMIA := 1

const TOP := TileSet.CELL_NEIGHBOR_TOP_SIDE
const RIGHT := TileSet.CELL_NEIGHBOR_RIGHT_SIDE
const BOTTOM := TileSet.CELL_NEIGHBOR_BOTTOM_SIDE
const LEFT := TileSet.CELL_NEIGHBOR_LEFT_SIDE

# (flip_h, flip_v, transpose) dla rotacji 0/90/180/270 (w prawo)
const ROTATIONS := [
	[false, false, false],
	[true, false, true],
	[true, true, false],
	[false, true, true],
]


func _initialize() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)

	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_SIDES)
	tile_set.add_terrain(0)
	tile_set.add_terrain(0)
	tile_set.set_terrain_name(0, TRAWA, "Trawa")
	tile_set.set_terrain_color(0, TRAWA, Color(0.3, 0.55, 0.25))
	tile_set.set_terrain_name(0, ZIEMIA, "Ziemia")
	tile_set.set_terrain_color(0, ZIEMIA, Color(0.55, 0.4, 0.28))

	_add_full_tile(tile_set, 0, "res://art/tilemap/grass_center.png", TRAWA)
	_add_full_tile(tile_set, 1, "res://art/tilemap/ground_center.png", ZIEMIA)

	# krawedz: baza (rotacja 0) ma trawe od dolu, reszta ziemia
	_add_rotated_tile(tile_set, 2, "res://art/tilemap/ground_down.png", ZIEMIA, [
		{BOTTOM: TRAWA, TOP: ZIEMIA, RIGHT: ZIEMIA, LEFT: ZIEMIA},
		{LEFT: TRAWA, TOP: ZIEMIA, RIGHT: ZIEMIA, BOTTOM: ZIEMIA},
		{TOP: TRAWA, LEFT: ZIEMIA, RIGHT: ZIEMIA, BOTTOM: ZIEMIA},
		{RIGHT: TRAWA, TOP: ZIEMIA, LEFT: ZIEMIA, BOTTOM: ZIEMIA},
	])

	# rog wypukly: baza ma trawiasty czubek prawo+dol, reszta ziemia (dirt-majority)
	_add_rotated_tile(tile_set, 3, "res://art/tilemap/ground_corner_outside.png", ZIEMIA, [
		{RIGHT: TRAWA, BOTTOM: TRAWA, TOP: ZIEMIA, LEFT: ZIEMIA},
		{BOTTOM: TRAWA, LEFT: TRAWA, TOP: ZIEMIA, RIGHT: ZIEMIA},
		{LEFT: TRAWA, TOP: TRAWA, RIGHT: ZIEMIA, BOTTOM: ZIEMIA},
		{TOP: TRAWA, RIGHT: TRAWA, LEFT: ZIEMIA, BOTTOM: ZIEMIA},
	])

	# rog wklesly: baza ma ziemisty klin gora+prawo, reszta trawa (grass-majority)
	_add_rotated_tile(tile_set, 4, "res://art/tilemap/ground_corner_inside.png", TRAWA, [
		{TOP: ZIEMIA, RIGHT: ZIEMIA, BOTTOM: TRAWA, LEFT: TRAWA},
		{RIGHT: ZIEMIA, BOTTOM: ZIEMIA, LEFT: TRAWA, TOP: TRAWA},
		{BOTTOM: ZIEMIA, LEFT: ZIEMIA, TOP: TRAWA, RIGHT: TRAWA},
		{LEFT: ZIEMIA, TOP: ZIEMIA, RIGHT: TRAWA, BOTTOM: TRAWA},
	])

	var err := ResourceSaver.save(tile_set, "res://ground_tileset.tres")
	if err != OK:
		push_error("Zapis TileSetu nie powiodl sie: %d" % err)
	else:
		print("OK: zapisano res://ground_tileset.tres")
	quit()


func _add_full_tile(tile_set: TileSet, source_id: int, path: String, terrain: int) -> void:
	var source := TileSetAtlasSource.new()
	source.texture = load(path)
	source.texture_region_size = Vector2i(16, 16)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, source_id)
	var td := source.get_tile_data(Vector2i.ZERO, 0)
	td.terrain_set = 0
	td.terrain = terrain
	for side in [TOP, RIGHT, BOTTOM, LEFT]:
		td.set_terrain_peering_bit(side, terrain)


func _add_rotated_tile(tile_set: TileSet, source_id: int, path: String, base_terrain: int, peering_per_rotation: Array) -> void:
	var source := TileSetAtlasSource.new()
	source.texture = load(path)
	source.texture_region_size = Vector2i(16, 16)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, source_id)

	for i in range(4):
		var alt_id := 0 if i == 0 else source.create_alternative_tile(Vector2i.ZERO)
		var td := source.get_tile_data(Vector2i.ZERO, alt_id)
		var rot: Array = ROTATIONS[i]
		td.flip_h = rot[0]
		td.flip_v = rot[1]
		td.transpose = rot[2]
		td.terrain_set = 0
		td.terrain = base_terrain
		var peering: Dictionary = peering_per_rotation[i]
		for side in peering:
			td.set_terrain_peering_bit(side, peering[side])
