# Nibylandia

Gra 2D top-down (ruch w 4 kierunkach, nie platformówka) w Godot 4 — **multiplayer survival od pierwszego dnia**, nie dobudowywany później. To jest kluczowa różnica względem poprzedniego projektu (gra "Goblin", `C:\Users\Goblin\Documents\goblin`), gdzie multiplayer dobudowano do istniejącej gry jednoosobowej i wiele rzeczy trzeba było przerabiać pod sieć (globalny singleton portfela, `get_tree().get_first_node_in_group("player")` zakładające jednego gracza, itp.). Tutaj architektura ma być sieciowa **od pierwszej linijki kodu ruchu gracza**.

## Jak pracujemy

- Użytkownik (Goblin) rysuje grafikę w LibreSprite i wrzuca pliki do `art/`, testuje efekty sam, zgłasza błędy/prośby po polsku.
- Ty piszesz cały kod, robisz eksporty, wdrażasz. Nie proś użytkownika o edycję czegokolwiek w edytorze Godota — on tylko testuje gotową grę.
- Jak skończysz zadanie: zbuduj, wdróż (web + serwer jeśli dotyczy), commituj i pushuj na GitHub — bez czekania na potwierdzenie, chyba że coś jest niejednoznaczne.
- Konwencja commitów/deployu: patrz sekcja "Deploy" niżej, jest 1:1 skopiowana ze sprawdzonego flow z projektu Goblin.

## Serwer multiplayer — infrastruktura (WSPÓLNA z projektem Goblin)

Multiplayer gry Goblin już działa na tym samym VPS. Nibylandia dostaje na nim **nowy port i nową subdomenę**, żeby nie kolidować — nie potrzeba nowego serwera, ten sam VPS ma zapas mocy na obie proste gry 2D naraz.

- **VPS:** OVH, adres `51.83.134.101`, user `ubuntu`, Ubuntu 26.04 LTS.
- **SSH:** klucz `C:\Users\Goblin\.ssh\goblin_vps` (ten sam co dla Goblina, już istnieje na tym komputerze, hasło wyłączone na serwerze). Połączenie: `ssh -i ~/.ssh/goblin_vps ubuntu@51.83.134.101`.
- **Port dla Nibylandii:** `9001` (Goblin zajmuje 9000).
- **Subdomena:** `mp.nibylandia.goblinpc.pl` — **wymaga ręcznego dodania rekordu DNS przez użytkownika** w panelu LightHosting (strefa DNS `goblinpc.pl` jest tam, NIE w Vercelu): A record, nazwa `mp.nibylandia`, wartość `51.83.134.101`, TTL 3600. Sprawdź czy już istnieje: `nslookup mp.nibylandia.goblinpc.pl 8.8.8.8`.
- **Caddy** (już zainstalowany na VPS) — dopisz NOWY blok do `/etc/caddy/Caddyfile` (nie kasuj istniejącego bloku `mp.goblinpc.pl` dla Goblina!):
  ```
  mp.nibylandia.goblinpc.pl {
  	reverse_proxy localhost:9001 {
  		transport http {
  			versions 1.1
  		}
  	}
  }
  ```
  Bez `transport http { versions 1.1 }` reverse proxy Caddy nie przepuszcza poprawnie uścisku dłoni WebSocket do serwera Godota (sprawdzone/wycierpiane na Goblinie — inaczej dostaniesz "Missing or invalid header 'upgrade'" mimo poprawnych nagłówków).
  Po zmianie: `sudo systemctl reload caddy`.
- **Katalog serwera gry:** `/opt/nibylandia-server/` (analogicznie do `/opt/goblin-server/`).
- **systemd:** usługa `nibylandia-server` (skopiuj wzorzec z `/etc/systemd/system/goblin-server.service`, zmień `WorkingDirectory`/`ExecStart`/nazwę). `Restart=always`.
- **Firewall:** ufw na VPS już przepuszcza 80/443 (Caddy obsłuży routing po hoście), nowy port 9001 nie musi być otwarty na zewnątrz — Caddy łączy się z nim po `localhost`.

## Deploy (wzorzec z Goblina — kopiuj 1:1)

Web (klient, eksport Godot "Web") ląduje w repo strony (analogicznie do `goblin-shop/public/game/`) i wdraża się przez Vercel automatycznie przy pushu — ustal z użytkownikiem, gdzie strona/podstrona dla Nibylandii ma żyć.

Serwer (eksport Godot "Server", Linux, `dedicated_server=true` w `export_presets.cfg`) wdraża się **ręcznie, NIE automatycznie**:
```bash
ssh -i ~/.ssh/goblin_vps ubuntu@51.83.134.101 "sudo systemctl stop nibylandia-server"
scp -i ~/.ssh/goblin_vps build/server/nibylandia_server.x86_64 build/server/nibylandia_server.pck ubuntu@51.83.134.101:/opt/nibylandia-server/
ssh -i ~/.ssh/goblin_vps ubuntu@51.83.134.101 "chmod +x /opt/nibylandia-server/nibylandia_server.x86_64 && sudo systemctl start nibylandia-server"
```
Zawsze **stop przed scp** — usługa trzyma plik binarki, nadpisanie działającego procesu się nie uda bez zatrzymania.

## Architektura multiplayer — buduj tak od razu (wnioski z Goblina)

Transport: `WebSocketMultiplayerPeer` (nie ENet/UDP — klienci to web-exporty w przeglądarce, muszą używać WebSocket). Serwer autorytatywny: serwer trzyma prawdziwy stan świata i graczy, klient wysyła tylko intencje (ruch/akcje), nie mutuje stanu samodzielnie.

Trzy konkretne pułapki, na które trafiłem przy Goblinie — unikaj ich od startu:

1. **Nie spawnuj gracza na `peer_connected`.** To wyścig: serwer może dodać węzeł gracza (replikowany przez `MultiplayerSpawner`) zanim klient w ogóle skończy wczytywać scenę ze swoim `MultiplayerSpawner` — spawn ginie bez śladu, nawet dla własnej postaci gracza. Zamiast tego: klient, w `_ready()` swojej sceny gry (po faktycznym wczytaniu), wywołuje RPC np. `request_spawn()` na serwerze (`@rpc("any_peer", "call_remote", "reliable")`), i DOPIERO wtedy serwer go spawnuje.

2. **`set_multiplayer_authority()` wywołane server-side NIE replikuje się do klientów.** To ustawia autorytet tylko w lokalnej kopii węzła na serwerze. Klient dostaje swoją kopię (przez `MultiplayerSpawner`) z domyślnym autorytetem (serwer, id=1) — jeśli gracz gra sam siebie, `is_multiplayer_authority()` zwróci false u niego samego (brak inputu, kamera się nie włączy, itd.). Rozwiązanie: nadaj węzłowi gracza `name = str(peer_id)` po stronie serwera (nazwy węzłów replikują się poprawnie — to po nich spawner dopasowuje odpowiadające sobie węzły), a w `_ready()` gracza, na KAŻDYM peerze (łącznie z serwerem), odtwórz autorytet z nazwy: `if name.is_valid_int(): set_multiplayer_authority(name.to_int())`.

3. **Testując ręcznie surowy handshake WebSocket** (np. do debugowania Caddy) nie dodawaj nagłówka `Sec-WebSocket-Protocol` — parser Godota się na nim wykłada. Prawdziwy klient Godota go nie wysyła, więc to nieistotne dla samej gry, ale zmyli Cię przy diagnozowaniu.

Warto od początku mieć: autoload `MultiplayerManager` (start/join/leave serwera + spawn/despawn), osobny eksport-preset "Server" (Linux, headless, `dedicated_server=true`), i trzymać identyfikację gracza (skoro bez logowania) jako losowy token zapisany lokalnie u klienta (`user://`), wysyłany przy każdym połączeniu — patrz decyzja o tożsamości graczy w projekcie Goblin, ten sam wzorzec pasuje tutaj.

## Ruch 4-kierunkowy (różnica względem Goblina)

Goblin był platformówką (grawitacja, skok, `move_and_slide()` z osią Y jako "dół"). Nibylandia chodzi w 4 kierunki (albo 8, jeśli dojdzie ruch po skosie) bez grawitacji — `CharacterBody2D` bez `get_gravity()`, kierunek z `Input.get_vector("move_left", "move_right", "move_up", "move_down")`, animacje idle/walk w 4 (lub 8) kierunkach zamiast idle/run/jump. Ustal z użytkownikiem wcześnie, czy ruch ma być tylko ortogonalny (4 kier., prostszy, retro) czy też diagonalny (8 kier., płynniejszy, więcej klatek animacji do narysowania) — to wpływa na to, ile grafiki użytkownik musi narysować.
