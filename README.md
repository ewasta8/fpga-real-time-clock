# Zegar Czasu Rzeczywistego (RTC) z Budzikiem na Intel MAX 10 DE10-Lite FPGA

Projekt zegara czasu rzeczywistego (RTC) z obsługą alarmu i drzemki, zaimplementowany w języku VHDL dla Intel MAX 10 DE10-Lite FPGA.

Projekt wykorzystuje architekturę strukturalną, opartą na łączeniu niezależnych modułów: jednostki sterującej, ścieżki danych, generatorów taktowania, obsługi wyświetlaczy oraz prostych bloków pomocniczych.

## Główne funkcje projektu

* **Zegar w formacie HH:MM:SS:** odliczanie czasu na 6 wyświetlaczach 7-segmentowych.
* **Edycja bez zatrzymywania zegara:** podczas wprowadzania nowych ustawień czas główny nadal liczy się w tle, a edycja odbywa się na osobnym buforze.
* **Osobna edycja czasu i budzika:** tryby edycji są kontrolowane przez maszynę stanów FSM i mają 60-sekundowy timeout.
* **Sprzętowy wyłącznik i drzemka:** alarm posiada własny suwak uzbrojenia oraz funkcję odłożenia dzwonienia na 60 sekund przyciskiem.
* **Automatyczna drzemka:** jeżeli budzik będzie dzwonił przez 60 sekund bez reakcji użytkownika, samoczynnie przejdzie w tryb drzemki.
* **Wizualny alarm:** cyfry są zastępowane migającym napisem `A L A r M` lub `A.L.A.r.M.` na 5 wyświetlaczach, a diody LED pokazują animację przesuwającego się punktu.

---

## Instrukcja Obsługi (Przyciski i Przełączniki)

Obsługa układu opiera się na przyciskach (`KEY`) oraz przełącznikach suwakowych (`SW`).

### Przełączniki (SW)

* `SW0` - Włącza i wyłącza główny wyświetlacz czasu. Gdy budzik dzwoni, wyświetlacz włącza się automatycznie niezależnie od stanu `SW0`.
* `SW1` - **Główny sprzętowy wyłącznik budzika.** Pozycja górna: budzik uzbrojony. Pozycja dolna: budzik wyłączony.
* `SW2` - Zmienia opcje wizualne dzwoniącego alarmu. Pozycja dolna: napis `A L A r M`, pozycja górna: napis z kropkami `A.L.A.r.M.`.
* `SW6` - Reset układu.
* `SW9, SW8, SW7` - Wybór elementu do edycji. Uruchomienie przełącznika oznacza wprowadzanie odpowiednio: `SW9` - godzin, `SW8` - minut, `SW7` - sekund. Możliwy jest wybór kilku elementów naraz. Wyłączenie ich na `0` jest potrzebne przy zatwierdzaniu lub anulowaniu.

### Przyciski (KEY)

* `KEY0` - W normalnym trybie aktywuje ustawianie godziny. W trybie edycji służy jako `PLUS`. Pełni również funkcję `ENTER` dla godziny oraz `ANULOWANIE` dla budzika.
* `KEY1` - W normalnym trybie aktywuje ustawianie budzika. W trybie edycji służy jako `MINUS`. Pełni również funkcję `ENTER` dla budzika oraz `ANULOWANIE` dla godziny. W trakcie dzwonienia alarmu służy jako **DRZEMKA** i odkłada dzwonienie o 60 sekund.

---

## Fazy działania programu

### 1. Normalne wyświetlanie godziny

Domyślny tryb pracy. Aby wyświetlacz był włączony, przełącznik `SW0` musi być w górze. Gdy `SW0` jest wyłączony, wyświetlacze są wygaszone. Zegar nadal liczy czas.

### 2. Edycja Godziny

* **Wejście:** Wciśnij `KEY0`.
* **Wprowadzanie:** Wybierz edytowany element za pomocą `SW9`, `SW8` lub `SW7`. Wybrane pole ma włączoną kropkę i miga razem z odpowiadającymi mu cyframi. Czas zwiększasz przyciskiem `KEY0`, a zmniejszasz `KEY1`.
* **Zatwierdzenie:** Ustaw przełączniki `SW9`, `SW8`, `SW7` w pozycję `0`, a następnie kliknij `KEY0`.
* **Anulowanie:** Ustaw przełączniki `SW9`, `SW8`, `SW7` w pozycję `0`, a następnie naciśnij `KEY1`.
* **Timeout:** System automatycznie wychodzi z trybu edycji po minucie braku aktywności ze strony użytkownika.

### 3. Edycja Budzika

* **Wejście:** Wciśnij `KEY1`.
* **Wprowadzanie:** Mechanika jest taka sama jak w przypadku godziny: wybór `SW9-SW7`, dodawanie `KEY0`, odejmowanie `KEY1`.
* **Zatwierdzenie:** Ustaw przełączniki `SW9`, `SW8`, `SW7` w pozycję `0`, a następnie kliknij `KEY1`.
* **Anulowanie:** Ustaw przełączniki `SW9`, `SW8`, `SW7` w pozycję `0`, a następnie naciśnij `KEY0`.
* **Timeout:** System automatycznie wychodzi z trybu edycji po minucie braku aktywności ze strony użytkownika.

Po resecie zapamiętany czas alarmu jest ustawiony na `00:00:00`.

### 4. Dzwonienie Budzika i Drzemka

Gdy czas główny zrówna się z czasem alarmu, a przełącznik uzbrojenia `SW1` jest w górze, układ przechodzi w stan dzwonienia.

* Zignorowany zostaje stan wyłącznika ekranu `SW0`, ponieważ alarm ma wyższy priorytet.
* Wyświetlacze pokazują migający napis `A L A r M` albo `A.L.A.r.M.`, zależnie od `SW2`. Wyświetlacz `HEX0` pozostaje wygaszony.
* Na Diodach `LEDR` uruchamia się animacja wędrującego punktu.
* **DRZEMKA:** Aby wyciszyć alarm na 60 sekund, należy nacisnąć `KEY1`. Po minucie budzik zadzwoni ponownie. Jeżeli alarm nie zostanie wyłączony, po 60 sekundach dzwonienia tryb drzemki uruchomi się automatycznie.
* **WYŁĄCZENIE:** Aby definitywnie wyłączyć budzik, przesuń `SW1` w dół.

---

## Architektura Projektu (Pliki VHDL)

* `zegar.vhd` - Główny moduł top-level, który łączy jednostkę taktowania, sterowanie, ścieżkę danych i wyświetlanie. Reset układu jest podłączony do `SW6`.
* `timing_unit.vhd` - Generuje impulsy czasowe: `tick_1Hz`, sygnał migania oraz takt animacji LED.
* `control_unit.vhd` - Łączy debouncery, FSM oraz logikę alarmu, drzemki i automatycznej drzemki.
* `rtc_fsm.vhd` - Maszyna stanów kontrolująca tryby normalny, edycję czasu, edycję budzika, zatwierdzanie/anulowanie i timeout.
* `datapath_unit.vhd` - Zawiera liczniki czasu, pamięć budzika, bufory edycji i multipleksery wybierające dane do wyświetlenia.
* `display_unit.vhd` - Obsługuje dekodowanie cyfr na wyświetlacze, wygaszanie `SW0`, miganie pól edycji, napis alarmu i animację `LEDR`.
* `brudnopis.vhd` - Bufor edycji pozwalający zmieniać cyfry bez bezpośredniej ingerencji w aktualnie liczony czas lub zapisany alarm.
* `d_cntr4ceo.vhd` - 4-bitowy licznik dziesiętny z wejściem ładowania i wyjściem przeniesienia.
* `cntr_xN.vhd` - Kaskada liczników dziesiętnych używana jako preskaler.
* `mux4x1.vhd` - Multiplekser 4x1 dla 4-bitowych cyfr BCD.
* `dec7seg.vhd` - Dekoder BCD/hex na sygnały wyświetlacza 7-segmentowego.
* `debouncer.vhd` - Układ filtracji drgań styków i detekcji pojedynczego impulsu po naciśnięciu przycisku.
