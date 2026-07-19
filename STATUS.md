# Status projektu — Nibylandia

Ten plik jest commitowany do repo (widoczny na GitHubie), żeby stan prac przetrwał przesiadki między komputerami. Aktualizowany na bieżąco przy większych krokach.

Ostatnia aktualizacja: 2026-07-19

## Zrobione

- Szkielet multiplayer (WebSocketMultiplayerPeer, serwer autorytatywny, spawn przez RPC `request_spawn`, autorytet po nazwie węzła) — patrz `MultiplayerManager`, `world.gd`, `player.gd`.
- Menu główne: przycisk "Graj", "Graj (lokalnie)" (tylko w edytorze), "Wyjdź" (poza wersją web).
- Pauza w grze (Esc): wróć do gry / rozłącz do menu / wyjdź z gry.
- Gracz: `CharacterBody2D`, ruch 4-kierunkowy, teraz z animowanym sprite'em goblina (`art/goblin/goblin_idle.png`, `goblin_run.png`, animacje idle/run + flip poziomy zamiast starego płaskiego prostokąta).
- Filtrowanie tekstur ustawione na "nearest" (piksele ostre, bez rozmazywania) w `project.godot`.
- TileSet podłoża (`ground_tileset.tres`) zbudowany proceduralnie skryptem `tools/build_ground_tileset.gd` z jednego spritesheeta `art/tilemap/ground_sheet.png` (siatka 4×4, kafelki 16×16). Model: jeden prawdziwy teren "Ziemia" (auto-tiling tryb Match Corners and Sides: pełny + krawędź + narożnik wypukły + narożnik wklęsły, reszta obrotów dogenerowana automatycznie), trawa to zwykły kafelek tła bez terrainu.
- Proceduralny generator terenu (`map_generator.gd`): szum Perlina + wygładzanie automatem komórkowym + odrzucanie kształtów, których tileset nie umie narysować.
- Użytkownik dorysował ręcznie do `ground_sheet.png` (siatka 4×4, wcześniej 3×2) kafelki wody: pełna woda, krawędź trawa→woda (płaska, bez klifu), krawędź trawa→woda z klifem (wariant stylistyczny), oraz najpewniej 2 narożniki (wypukły/wklęsły) dla granicy trawa/woda — **jeszcze nie przepisane do `build_ground_tileset.gd`, TileSet nie zna jeszcze tych kafelków.**
- Eksperymentalna funkcja ręcznego malowania mapy w edytorze (`Ground` w `world.tscn` ma teraz odpięty `map_generator.gd`, żeby dało się malować ręcznie bez nadpisywania przez generator przy starcie gry).

## W trakcie / do zrobienia najbliżej

1. **Dopisać teren "Woda" do `build_ground_tileset.gd`** na podstawie nowych kafelków w `ground_sheet.png` (pozycje: pełna woda, krawędź, 2 narożniki) — wzorem istniejącej "Ziemi".
2. Zdecydować: `Ground` w `world.tscn` ma teraz odpięty skrypt generatora (do ręcznego malowania) — trzeba ustalić z użytkownikiem, czy wracamy do generowania proceduralnego, zostajemy przy ręcznej mapie, czy łączymy oba (np. generator jako baza + ręczne poprawki).
3. `tools/tile_preview.tscn` — scratch-scena do podglądu kafelków z generatorem + graczem, do ogarnięcia/wyczyszczenia po skończeniu prac nad tilesetem.

## Zaplanowane (dalej w kolejce)

- **Klify jako realna mechanika wysokości** (decyzja użytkownika 2026-07-19, nie tylko wizualne): wyższy teren blokuje ruch jak ściana, przejście tylko przez kafelek rampy/schodków.
  - Potrzebna grafika: krawędź klifu na suchym lądzie (bez wody na dole — przeróbka wariantu "klif z wodą"), narożnik wypukły + wklęsły dla tej krawędzi, kafelek(i) rampy.
  - Kolizja: warstwa fizyki w TileSet z wielokątem kolizji na kafelkach ściany klifu, żeby `move_and_slide()` gracza blokował się naturalnie; kafelki rampy bez kolizji.
  - Logika w `map_generator.gd` do rozmieszczania wyniesionych platform i "przebijania" ramp w ścianach klifu (to jedyne miejsce, gdzie auto-tiling świadomie się łamie).
- Serwer multiplayer na VPS (`mp.nibylandia.goblinpc.pl:9001`, Caddy + systemd) — infrastruktura opisana w `CLAUDE.md`, jeszcze nie wdrożona/nie sprawdzona per ten etap prac nad mapą.

## Uwaga dla przyszłych sesji

Instrukcje/decyzje projektowe zapisywane są zarówno tutaj (`STATUS.md`, commitowane, widoczne na każdym komputerze) jak i w lokalnej pamięci Claude Code (per-komputer, nie synchronizuje się między maszynami). Rzeczy istotne dla kontynuacji pracy na innym komputerze muszą lądować **tutaj**, nie tylko w lokalnej pamięci.
