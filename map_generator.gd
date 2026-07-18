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
const TERRAIN_GRASS := 0
const TERRAIN_DIRT := 1


func _ready() -> void:
	_generate()


func _generate() -> void:
	var all_cells: Array[Vector2i] = []
	for x in range(-MAP_HALF_SIZE, MAP_HALF_SIZE):
		for y in range(-MAP_HALF_SIZE, MAP_HALF_SIZE):
			all_cells.append(Vector2i(x, y))
	set_cells_terrain_connect(all_cells, TERRAIN_SET, TERRAIN_GRASS)

	var noise := FastNoiseLite.new()
	noise.seed = WORLD_SEED
	noise.frequency = NOISE_FREQUENCY

	var dirt_cells: Array[Vector2i] = []
	for cell in all_cells:
		if noise.get_noise_2d(cell.x, cell.y) > DIRT_THRESHOLD:
			dirt_cells.append(cell)
	if not dirt_cells.is_empty():
		set_cells_terrain_connect(dirt_cells, TERRAIN_SET, TERRAIN_DIRT)
