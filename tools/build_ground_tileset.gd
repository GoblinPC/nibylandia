extends SceneTree

# Jednorazowy (uruchamiany recznie) builder TileSetu podloza z jednego
# spritesheeta art/tilemap/ground_sheet.png (siatka 3x2, kafelki 16x16).
# Uruchom ponownie po kazdej zmianie tego pliku:
#   godot --headless --script res://tools/build_ground_tileset.gd
#
# Model "jeden terrain" (tak jak w wiekszosci tutoriali): tylko "Ziemia"
# jest prawdziwym terrainem. Trawa to zwykly, nie-terrainowy kafelek
# stawiany bezposrednio jako tlo (patrz map_generator.gd).
#
# Tryb Match Corners and Sides (nie tylko Sides!): rog wypukly (duzo Ziemi,
# maly naroznik trawy) i rog wklesly (duzo trawy, maly naroznik Ziemi) maja
# IDENTYCZNY wzorzec 4 bokow — tylko przekatne (rogi-sasiedzi) je odrozniaja.
# Bez sprawdzania przekatnych Godot nie potrafi wybrac miedzy nimi.

const ZIEMIA := 0
const BG := -1  # brak terrainu (trawa jako zwykle tlo) — wartosc domyslna, nie trzeba jej ustawiac

const TOP := TileSet.CELL_NEIGHBOR_TOP_SIDE
const RIGHT := TileSet.CELL_NEIGHBOR_RIGHT_SIDE
const BOTTOM := TileSet.CELL_NEIGHBOR_BOTTOM_SIDE
const LEFT := TileSet.CELL_NEIGHBOR_LEFT_SIDE
const TOP_LEFT := TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER
const TOP_RIGHT := TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER
const BOTTOM_LEFT := TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER
const BOTTOM_RIGHT := TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER

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
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	tile_set.add_terrain(0)
	tile_set.set_terrain_name(0, ZIEMIA, "Ziemia")
	tile_set.set_terrain_color(0, ZIEMIA, Color(0.55, 0.4, 0.28))

	var source := TileSetAtlasSource.new()
	source.texture = load("res://art/tilemap/ground_sheet.png")
	source.texture_region_size = Vector2i(16, 16)
	tile_set.add_source(source, 0)

	# grass_center (0,0): zwykly kafelek tla, bez terrainu w ogole
	source.create_tile(Vector2i(0, 0))

	# ground_center (1,0): pelna Ziemia, wszystkie 8 bitow
	source.create_tile(Vector2i(1, 0))
	_set_bits(source, Vector2i(1, 0), 0, {
		TOP: ZIEMIA, RIGHT: ZIEMIA, BOTTOM: ZIEMIA, LEFT: ZIEMIA,
		TOP_LEFT: ZIEMIA, TOP_RIGHT: ZIEMIA, BOTTOM_LEFT: ZIEMIA, BOTTOM_RIGHT: ZIEMIA,
	})

	# ground_down (2,0): krawedz, baza ma "brak terrainu" (trawe) od dolu
	# (BOTTOM_LEFT/BOTTOM_RIGHT rogi tez nieustawione — sasiaduja z trawa)
	_add_rotated_tile(source, Vector2i(2, 0), [
		{TOP: ZIEMIA, RIGHT: ZIEMIA, LEFT: ZIEMIA, TOP_LEFT: ZIEMIA, TOP_RIGHT: ZIEMIA},
		{TOP: ZIEMIA, RIGHT: ZIEMIA, BOTTOM: ZIEMIA, TOP_RIGHT: ZIEMIA, BOTTOM_RIGHT: ZIEMIA},
		{RIGHT: ZIEMIA, LEFT: ZIEMIA, BOTTOM: ZIEMIA, BOTTOM_RIGHT: ZIEMIA, BOTTOM_LEFT: ZIEMIA},
		{TOP: ZIEMIA, LEFT: ZIEMIA, BOTTOM: ZIEMIA, BOTTOM_LEFT: ZIEMIA, TOP_LEFT: ZIEMIA},
	])

	# ground_corner_outside (0,1): rog wypukly — duzo Ziemi, maly naroznik
	# trawy w JEDNYM rogu (3 przekatne z 4 to nadal Ziemia)
	_add_rotated_tile(source, Vector2i(0, 1), [
		{TOP: ZIEMIA, LEFT: ZIEMIA, TOP_LEFT: ZIEMIA, TOP_RIGHT: ZIEMIA, BOTTOM_LEFT: ZIEMIA},
		{TOP: ZIEMIA, RIGHT: ZIEMIA, TOP_LEFT: ZIEMIA, TOP_RIGHT: ZIEMIA, BOTTOM_RIGHT: ZIEMIA},
		{RIGHT: ZIEMIA, BOTTOM: ZIEMIA, TOP_RIGHT: ZIEMIA, BOTTOM_RIGHT: ZIEMIA, BOTTOM_LEFT: ZIEMIA},
		{LEFT: ZIEMIA, BOTTOM: ZIEMIA, TOP_LEFT: ZIEMIA, BOTTOM_LEFT: ZIEMIA, BOTTOM_RIGHT: ZIEMIA},
	])

	# ground_corner_inside (1,1): rog wklesly — duzo trawy, maly naroznik
	# Ziemi w JEDNYM rogu (tylko 1 przekatna z 4 to Ziemia)
	_add_rotated_tile(source, Vector2i(1, 1), [
		{TOP: ZIEMIA, RIGHT: ZIEMIA, TOP_RIGHT: ZIEMIA},
		{RIGHT: ZIEMIA, BOTTOM: ZIEMIA, BOTTOM_RIGHT: ZIEMIA},
		{BOTTOM: ZIEMIA, LEFT: ZIEMIA, BOTTOM_LEFT: ZIEMIA},
		{LEFT: ZIEMIA, TOP: ZIEMIA, TOP_LEFT: ZIEMIA},
	])

	var err := ResourceSaver.save(tile_set, "res://ground_tileset.tres")
	if err != OK:
		push_error("Zapis TileSetu nie powiodl sie: %d" % err)
	else:
		print("OK: zapisano res://ground_tileset.tres")
	quit()


func _set_bits(source: TileSetAtlasSource, coords: Vector2i, alt_id: int, peering: Dictionary) -> void:
	var td := source.get_tile_data(coords, alt_id)
	td.terrain_set = 0
	td.terrain = ZIEMIA
	for side in peering:
		td.set_terrain_peering_bit(side, peering[side])


func _add_rotated_tile(source: TileSetAtlasSource, coords: Vector2i, peering_per_rotation: Array) -> void:
	source.create_tile(coords)
	for i in range(4):
		var alt_id := 0 if i == 0 else source.create_alternative_tile(coords)
		var td := source.get_tile_data(coords, alt_id)
		var rot: Array = ROTATIONS[i]
		td.flip_h = rot[0]
		td.flip_v = rot[1]
		td.transpose = rot[2]
		_set_bits(source, coords, alt_id, peering_per_rotation[i])
