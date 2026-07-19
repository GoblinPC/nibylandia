# Status projektu — Nibylandia

Ten plik jest commitowany do repo (widoczny na GitHubie), żeby stan prac przetrwał przesiadki między komputerami. Aktualizowany na bieżąco przy większych krokach.

Ostatnia aktualizacja: 2026-07-19 (wieczór, Mac — runda kafelków wody ZAMKNIĘTA, wypchnięta na GitHuba)

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

1. ~~Dopisać teren "Woda"~~ **ZROBIONE 2026-07-19 (Mac), po przerysowaniu arkusza przez użytkownika.** TRZY terrainy: Ziemia (0), Woda (1), **Trawa (2 — pełnoprawny teren do malowania!)**. Model malowania: głównie Trawą (tło mapy), Ziemia = ścieżki, Woda = jeziora; wszystkie przejścia ziemia↔trawa i woda↔trawa dorabiają się same. Mapowanie kafelków wg jawnej listy użytkownika (patrz komentarze w `tools/build_ground_tileset.gd`); klify NIGDY się nie obracają (ścianka zawsze patrzy w dół): (1,2) klif poziomy, (0,2) narożnik z klifem (+odbicie poziome), (2,2) płaska krawędź (obroty na boki), (2,1) zewnętrzny róg (obroty ×4), (3,1) wypukły z trawą (+odbicie), (3,0) pełna woda. Zweryfikowane sondą (`tools/render_probe.gd` zrzuca PNG testowego jeziora+ścieżki; `tools/render_alts.gd` podgląd altów; oba BEZ --headless).
   Blok 12 (3,2) = wewnętrzny narożnik klifu (dorysowany przez użytkownika): ścianka z góry skręca w trawiasty brzeg; oryginał = lewy górny róg jeziora, flip_h = prawy górny; kafelek 7 (2,1) został tylko na dolne rogi (obroty 0/270). Kafelki 8 (3,1) i 9 (0,2) = styk z lądem PO SKOSIE (trawa tylko w jednym rogu bitmapy peeringu, boki wodne!): 8+flip = górne rogi wyspy, 9+flip = dolne rogi wyspy (z klifem). Komplet narożników potwierdzony sondą (jezioro + wyspa w środku).
   Blok 13 (0,3) = poprawiona wersja bloku 9 (piksele piany dopasowane do bloku 12) — ZASTĘPUJE blok 9 w rejestracji (9 zostaje w arkuszu nieużywany). Arkusz powiększony do 128×128 (8×8 pól, pozycje kafelków bez zmian, wolne pola na przyszłe grafiki — np. klify lądowe pod mechanikę wysokości).
   Weryfikacja po zmianie komputera: zrestartować edytor, przemalować kawałek wody z wyspą i ocenić złącza 12↔13; jakby coś, rejestracje kafelków są w tools/build_ground_tileset.gd z komentarzami przy każdym bloku.
   WAŻNE przy przebudowie: po każdej zmianie `ground_sheet.png` NAJPIERW `godot --headless --import`, potem builder — inaczej builder widzi starą teksturę z cache'u importu (przerobione: builder+sonda działały na starym arkuszu i wszystko wyglądało "odwrotnie"). Po przebudowie tilesetu użytkownik musi ZRESTARTOWAĆ edytor Godota (nie przeładowuje .tres w locie) i przemalować obszary malowane starą wersją.
   OGRANICZENIA level designu: woda/ścieżka szerokości 1 kratki nie ma kafelków (min. 2 szerokości); ziemia nie może dotykać wody (brak przejść — zawsze pas trawy); puste (niezamalowane) komórki NIE liczą się jako trawa — mapę najpierw zalać Trawą, gumka robi dziury w przejściach.
2. Woda NIE MA jeszcze kolizji (można po niej chodzić) — do decyzji: blokuje ruch / spowalnia / pływanie. Kod po stronie Claude'a.
3. Zauważony zabłąkany niebieski piksel na kafelku ziemi (0,1), prawy dolny róg — do poprawki w LibreSprite.
4. Zdecydować: `Ground` w `world.tscn` ma odpięty skrypt generatora (ręczne malowanie) — wracamy do proceduralnego, zostajemy przy ręcznym, czy generator jako baza + poprawki?
5. `tools/tile_preview.tscn` — scratch-scena do podglądu kafelków, do wyczyszczenia po skończeniu prac nad tilesetem.

## Podział ról (ustalony 2026-07-19)

Użytkownik sam robi grafikę i level design (malowanie map, rysowanie kafelków) — Claude tłumaczy narzędzia/workflow i pisze kod. Znaczenie nowych kafelków na spritesheecie ustalamy razem (nie zgadywać z PNG).

## Zaplanowane (dalej w kolejce)

- **Klify jako realna mechanika wysokości** (decyzja użytkownika 2026-07-19, nie tylko wizualne): wyższy teren blokuje ruch jak ściana, przejście tylko przez kafelek rampy/schodków.
  - Potrzebna grafika: krawędź klifu na suchym lądzie (bez wody na dole — przeróbka wariantu "klif z wodą"), narożnik wypukły + wklęsły dla tej krawędzi, kafelek(i) rampy.
  - Kolizja: warstwa fizyki w TileSet z wielokątem kolizji na kafelkach ściany klifu, żeby `move_and_slide()` gracza blokował się naturalnie; kafelki rampy bez kolizji.
  - Logika w `map_generator.gd` do rozmieszczania wyniesionych platform i "przebijania" ramp w ścianach klifu (to jedyne miejsce, gdzie auto-tiling świadomie się łamie).
- Serwer multiplayer na VPS (`mp.nibylandia.goblinpc.pl:9001`, Caddy + systemd) — infrastruktura opisana w `CLAUDE.md`, jeszcze nie wdrożona/nie sprawdzona per ten etap prac nad mapą.

## Uwaga dla przyszłych sesji

Instrukcje/decyzje projektowe zapisywane są zarówno tutaj (`STATUS.md`, commitowane, widoczne na każdym komputerze) jak i w lokalnej pamięci Claude Code (per-komputer, nie synchronizuje się między maszynami). Rzeczy istotne dla kontynuacji pracy na innym komputerze muszą lądować **tutaj**, nie tylko w lokalnej pamięci.
