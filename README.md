# Tiny Shop · Sort & Restore

Pionowy prototyp gry casual na Androida, stworzony w Godot 4 i GDScript. Etap 1 obejmuje ekran startowy z miniaturowym sklepikiem, jedną planszę sortowania i interaktywny podgląd przykładowej oferty.

## Uruchomienie

Otwórz `project.godot` w Godot 4.7.2, poczekaj na import grafik i uruchom projekt klawiszem **F5**. Projekt korzysta z renderera Compatibility. Do lokalnej oceny ekranów wystarczy desktopowa wersja Godot.

```sh
godot --editor --path .
godot --path .
```

## Rozgrywka

- Rozpocznij grę na ekranie głównym.
- Dotknij produktu na półce, by przenieść go na tackę. Tacka mieści siedem przedmiotów.
- Trzy takie same produkty na tacy tworzą komplet i znikają. Opróżnij półki, aby ukończyć planszę i otrzymać 120 monet.
- Przycisk **Cofnij** przywraca stan sprzed ostatniego ruchu. **Od nowa** ustawia produkty w pozycjach początkowych.
- W oknie sklepu **Otwórz próbkę** odtwarza animację rozpakowania. Waluta i cofnięcia widoczne w ofercie należą do podglądu.

Mysz działa jako odpowiednik dotyku w wersji desktopowej.

## Ocena na ekranie telefonu

Poniższe zrzuty pochodzą z działającej gry uruchomionej w Godot na pulpicie Linux.

| Ekran | 720 × 1600 | 1080 × 1920 |
| --- | --- | --- |
| Start | [PNG](docs/screenshots/start-720x1600.png) | [PNG](docs/screenshots/start-1080x1920.png) |
| Rozgrywka | [PNG](docs/screenshots/rozgrywka-720x1600.png) | [PNG](docs/screenshots/rozgrywka-1080x1920.png) |
| Sklep | [PNG](docs/screenshots/sklep-720x1600.png) | [PNG](docs/screenshots/sklep-1080x1920.png) |

Uruchom poniższe polecenia osobno. Do oceny pełnych wymiarów okna potrzebny jest pulpit o odpowiednim rozmiarze.

```sh
godot --path . --resolution 720x1600
godot --path . --resolution 1080x1920
```

W obu rozdzielczościach sprawdzono cały przebieg myszą. Test objął otwieranie oferty, rozpakowanie próbki, limit siedmiu miejsc, cofnięcie, reset, zebranie wszystkich 12 kompletów, nagrodę 120 monet i powrót do menu. Obejrzano układ i czytelność trzech ekranów w pełnych wymiarach okna.

### Android

Zainstaluj szablony eksportu odpowiadające wersji Godot i ustaw ścieżki do Android SDK oraz Java SDK w ustawieniach edytora. Otwórz **Project → Export**, wybierz preset **Android** i wyeksportuj kompilację testową do APK.

```sh
godot --headless --path . --export-debug Android /ścieżka/TinyShop-stage1-debug.apk
```

Eksport testowy wykonano z Android Build Tools 36.0.0 i Java 21. APK jest podpisany kluczem debugowania, obsługuje ARM64 i wymaga co najmniej Androida 7.0 (API 24). Docelowe 60 FPS wymaga pomiaru na fizycznym telefonie.

## Struktura projektu

| Ścieżka | Zawartość |
| --- | --- |
| `project.godot` | Ustawienia Godot, rozdzielczość bazowa i orientacja pionowa |
| `export_presets.cfg` | Preset eksportu Android ARM64 |
| `scenes/main.tscn` | Scena startowa projektu |
| `scripts/` | Nawigacja, ekrany i logika sortowania |
| `assets/art/` | Ilustracja sklepiku, regał, ikona aplikacji i osobne grafiki produktów |
| `assets/fonts/` | Kroje Fraunces i Plus Jakarta Sans oraz ich licencje OFL |
| [ART_DIRECTION.md](ART_DIRECTION.md) | Paleta, oświetlenie, materiały i wytyczne dla grafik |

Projekt demonstracyjny nie wymaga płatnych bibliotek ani usług.
