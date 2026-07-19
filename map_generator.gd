extends TileMapLayer

# Faza 1: samo podloze (trawa + platy ziemi), zeby ladnie sie ukladalo przez
# terrain auto-tiling. Sztuczne wzniesienia (Stardew-like) i elementy typu
# drzewa dojda w kolejnych fazach.
#
# Deterministyczne z ustalonego ziarna — serwer i klient generuja identyczny
# uklad lokalnie, bez replikowania kafelkow po sieci. Gdy dojdzie potrzeba
# roznych swiatow na sesje, ziarno trzeba bedzie synchronizowac przy joinie.

const WORLD_SEED := 12345
const MAP_HALF_SIZE := 24  # kafelki w kazda strone od (0,0)
const NOISE_FREQUENCY := 0.06
const DIRT_THRESHOLD := 0.15

const TERRAIN_SET := 0
const TERRAIN_ZIEMIA := 0
const GRASS_SOURCE := 0
const GRASS_ATLAS_COORDS := Vector2i(0, 0)


func _ready() -> void:
	_generate()


func _generate() -> void:
	# trawa to zwykle tlo, nie terrain — stawiana bezposrednio, bez
	# dopasowywania sasiadow (patrz komentarz w tools/build_ground_tileset.gd)
	var all_cells: Array[Vector2i] = []
	for x in range(-MAP_HALF_SIZE, MAP_HALF_SIZE):
		for y in range(-MAP_HALF_SIZE, MAP_HALF_SIZE):
			var cell := Vector2i(x, y)
			all_cells.append(cell)
			set_cell(cell, GRASS_SOURCE, GRASS_ATLAS_COORDS)

	var noise := FastNoiseLite.new()
	noise.seed = WORLD_SEED
	noise.frequency = NOISE_FREQUENCY

	var dirt_set: Dictionary = {}
	for cell in all_cells:
		if noise.get_noise_2d(cell.x, cell.y) > DIRT_THRESHOLD:
			dirt_set[cell] = true

	_smooth(dirt_set, all_cells)
	_drop_unrenderable_cells(dirt_set)

	if not dirt_set.is_empty():
		set_cells_terrain_connect(dirt_set.keys(), TERRAIN_SET, TERRAIN_ZIEMIA)


# wygladzanie automatem komorkowym (regula wiekszosci z 8 sasiadow) —
# eliminuje wezsze niz 2 kafelki pasy i pojedyncze szumowe kropki, zanim w
# ogole dotrzemy do sprawdzania, ktore ksztalty mamy narysowane
func _smooth(dirt_set: Dictionary, all_cells: Array[Vector2i]) -> void:
	const NEIGHBORS_8 := [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	for _pass in range(2):
		var next_set: Dictionary = {}
		for cell in all_cells:
			var dirt_neighbors := 0
			for offset in NEIGHBORS_8:
				if dirt_set.has(cell + offset):
					dirt_neighbors += 1
			if dirt_neighbors >= 5:
				next_set[cell] = true
		dirt_set.clear()
		for cell in next_set:
			dirt_set[cell] = true


# nasz minimalny zestaw kafelkow obsluguje tylko: pelna ziemia (0 bokow
# trawy), krawedz (1 bok), rog (2 SASIADUJACE boki) — usuwamy komorki o
# wzorcu, ktorego nie mamy czym narysowac (2 PRZECIWLEGLE boki = waski
# przesmyk, 3 lub 4 boki = koniuszek/wyspa), az zaden taki nie zostanie
func _drop_unrenderable_cells(dirt_set: Dictionary) -> void:
	var changed := true
	while changed:
		changed = false
		var to_remove: Array[Vector2i] = []
		for cell in dirt_set:
			var grass_sides := 0
			var top_grass := not dirt_set.has(cell + Vector2i(0, -1))
			var bottom_grass := not dirt_set.has(cell + Vector2i(0, 1))
			var left_grass := not dirt_set.has(cell + Vector2i(-1, 0))
			var right_grass := not dirt_set.has(cell + Vector2i(1, 0))
			for is_grass in [top_grass, bottom_grass, left_grass, right_grass]:
				if is_grass:
					grass_sides += 1
			var opposite_pair_is_grass := (top_grass and bottom_grass) or (left_grass and right_grass)
			if grass_sides >= 3 or (grass_sides == 2 and opposite_pair_is_grass):
				to_remove.append(cell)
		if not to_remove.is_empty():
			for cell in to_remove:
				dirt_set.erase(cell)
			changed = true
