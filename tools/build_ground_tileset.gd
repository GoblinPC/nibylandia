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

# TRZY prawdziwe terrainy: maluje sie glownie TRAWA (tlo mapy), ZIEMIA to
# sciezki, WODA to jeziora. Przejscia ziemia<->trawa i woda<->trawa dorabiaja
# sie same. UWAGA: nie ma kafelkow przejscia ziemia<->woda — miedzy sciezka
# a woda zawsze pas trawy.
const ZIEMIA := 0
const WODA := 1
const TRAWA := 2

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
	tile_set.add_terrain(0)
	tile_set.set_terrain_name(0, WODA, "Woda")
	tile_set.set_terrain_color(0, WODA, Color(0.3, 0.55, 0.9))
	tile_set.add_terrain(0)
	tile_set.set_terrain_name(0, TRAWA, "Trawa")
	tile_set.set_terrain_color(0, TRAWA, Color(0.35, 0.65, 0.35))

	var source := TileSetAtlasSource.new()
	source.texture = load("res://art/tilemap/ground_sheet.png")
	source.texture_region_size = Vector2i(16, 16)
	tile_set.add_source(source, 0)

	# grass_center (0,0): pelna Trawa — od teraz trawa to teren jak kazdy inny
	source.create_tile(Vector2i(0, 0))
	_set_bits(source, Vector2i(0, 0), 0, _full(TRAWA), TRAWA)

	# ground_center (1,0): pelna Ziemia, wszystkie 8 bitow
	source.create_tile(Vector2i(1, 0))
	_set_bits(source, Vector2i(1, 0), 0, _full(ZIEMIA))

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

	# ── WODA — mapowanie 1:1 wg listy uzytkownika (2026-07-19, siatka 4x4,
	# czytane jak ksiazka). Klify NIGDY sie nie obracaja (scianka zawsze
	# patrzy w dol ekranu); reszta obraca sie/odbija tak, by pokryc sloty.

	# (3,0): pelny blok wody
	source.create_tile(Vector2i(3, 0))
	_set_bits(source, Vector2i(3, 0), 0, _full(WODA), WODA)

	# (2,1): "trawa od dolu i od lewej, reszta woda" — zewnetrzny rog
	# jeziora, woda w gornym-prawym. Tylko DOLNE rogi jeziora (obroty 0/270);
	# gorne rogi maja klif — obsluguje je (3,2)
	_add_rotated_tile_subset(source, Vector2i(2, 1), [0, 3], [
		{TOP: WODA, RIGHT: WODA, TOP_RIGHT: WODA},
		{LEFT: WODA, TOP: WODA, TOP_LEFT: WODA},
	], WODA)

	# (3,2): wewnetrzny naroznik klifu (blok 12) — scianka z gory skreca
	# w trawiasty brzeg z lewej, woda w prawym dolnym; odbicie poziome
	# daje prawy gorny rog jeziora
	_add_alts(source, Vector2i(3, 2), [
		[[false, false, false], {RIGHT: WODA, BOTTOM: WODA, BOTTOM_RIGHT: WODA}],
		[[true, false, false], {BOTTOM: WODA, LEFT: WODA, BOTTOM_LEFT: WODA}],
	], WODA)

	# (3,1): "caly blok wody OPROCZ naroznika prawego dolnego" — doslownie:
	# styk z ladem tylko po skosie (gorne rogi wyspy). Woda na wszystkich
	# bokach, trawa wylacznie w jednym rogu; odbicie daje drugi rog
	_add_alts(source, Vector2i(3, 1), [
		[[false, false, false], _water_except([BOTTOM_RIGHT])],
		[[true, false, false], _water_except([BOTTOM_LEFT])],
	], WODA)

	# (0,3) = blok 13: rog z klifem po skosie (lad nad woda dotyka tylko
	# przekatna) — poprawiona wersja bloku 9 z pikselami dopasowanymi do
	# bloku 12; odbicie poziome daje lewy wariant. Blok 9 (0,2) chwilowo
	# NIEUZYWANY (zostawiony w arkuszu, mozna wrocic jedna linijka)
	_add_alts(source, Vector2i(0, 3), [
		[[false, false, false], _water_except([TOP_RIGHT])],
		[[true, false, false], _water_except([TOP_LEFT])],
	], WODA)

	# (1,2): "od dolu woda, od gory trawa z klifem" — pozioma krawedz
	# z klifem, bez obrotow (lad NAD woda)
	source.create_tile(Vector2i(1, 2))
	_set_bits(source, Vector2i(1, 2), 0, {
		BOTTOM: WODA, LEFT: WODA, RIGHT: WODA, BOTTOM_LEFT: WODA, BOTTOM_RIGHT: WODA,
	}, WODA)

	# (2,2): "od gory woda, od dolu sama trawa" — plaska krawedz; obroty
	# 90/270 daja brzegi pionowe (lewy/prawy), slot "woda od dolu" ma klif
	_add_rotated_tile_subset(source, Vector2i(2, 2), [0, 1, 3], [
		{TOP: WODA, LEFT: WODA, RIGHT: WODA, TOP_LEFT: WODA, TOP_RIGHT: WODA},
		{TOP: WODA, RIGHT: WODA, BOTTOM: WODA, TOP_RIGHT: WODA, BOTTOM_RIGHT: WODA},
		{TOP: WODA, LEFT: WODA, BOTTOM: WODA, TOP_LEFT: WODA, BOTTOM_LEFT: WODA},
	], WODA)

	var err := ResourceSaver.save(tile_set, "res://ground_tileset.tres")
	if err != OK:
		push_error("Zapis TileSetu nie powiodl sie: %d" % err)
	else:
		print("OK: zapisano res://ground_tileset.tres")
	quit()


const ALL_BITS := [TOP, RIGHT, BOTTOM, LEFT, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT]


func _full(terrain: int) -> Dictionary:
	var p := {}
	for bit in ALL_BITS:
		p[bit] = terrain
	return p


# woda wszedzie poza wskazanymi bitami (te dostana trawe przez dopelnienie)
func _water_except(grass_bits: Array) -> Dictionary:
	var p := _full(WODA)
	for bit in grass_bits:
		p.erase(bit)
	return p


# nieustawione bity dopelniane sa TRAWA — w swiecie trzech terenow kazda
# "pusta" strona kafelka to po prostu trawa
func _set_bits(source: TileSetAtlasSource, coords: Vector2i, alt_id: int, peering: Dictionary, terrain: int = ZIEMIA) -> void:
	var td := source.get_tile_data(coords, alt_id)
	td.terrain_set = 0
	td.terrain = terrain
	for bit in ALL_BITS:
		td.set_terrain_peering_bit(bit, peering.get(bit, TRAWA))


# alternatywy z dowolnymi flagami [flip_h, flip_v, transpose]
func _add_alts(source: TileSetAtlasSource, coords: Vector2i, alts: Array, terrain: int) -> void:
	source.create_tile(coords)
	for j in alts.size():
		var alt_id := 0 if j == 0 else source.create_alternative_tile(coords)
		var td := source.get_tile_data(coords, alt_id)
		var flags: Array = alts[j][0]
		td.flip_h = flags[0]
		td.flip_v = flags[1]
		td.transpose = flags[2]
		_set_bits(source, coords, alt_id, alts[j][1], terrain)


func _add_rotated_tile(source: TileSetAtlasSource, coords: Vector2i, peering_per_rotation: Array) -> void:
	_add_rotated_tile_subset(source, coords, [0, 1, 2, 3], peering_per_rotation, ZIEMIA)


# jak wyzej, ale tylko wybrane obroty (rot_indices to indeksy ROTATIONS;
# peerings podawane w tej samej kolejnosci co rot_indices)
func _add_rotated_tile_subset(source: TileSetAtlasSource, coords: Vector2i, rot_indices: Array, peerings: Array, terrain: int) -> void:
	source.create_tile(coords)
	for j in rot_indices.size():
		var alt_id := 0 if j == 0 else source.create_alternative_tile(coords)
		var td := source.get_tile_data(coords, alt_id)
		var rot: Array = ROTATIONS[rot_indices[j]]
		td.flip_h = rot[0]
		td.flip_v = rot[1]
		td.transpose = rot[2]
		_set_bits(source, coords, alt_id, peerings[j], terrain)
