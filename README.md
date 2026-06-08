# Zegar Czasu Rzeczywistego (RTC) z Budzikiem na Intel MAX 10 DE10-Lite FPGA

Projekt w pełni funkcjonalnego zegara czasu rzeczywistego (RTC) z obsługą alarmu i drzemki, zaimplementowany w języku VHDL dla Intel MAX 10 DE10-Lite FPGA. 

Projekt wykorzystuje architekturę strukturalną (hierarchiczną), opartą na łączeniu niezależnych modułów, co pozwala na bardzo niskie zużycie zasobów logicznych układu FPGA.

## Główne funkcje projektu

* **Zegar w formacie HH:MM:SS:** Płynne odliczanie czasu na 6 wyświetlaczach 7-segmentowych.
* **Wielozadaniowość:** Podczas wprowadzania nowych ustawień czas główny nadal liczy się w tle, a wartości nie przeskakują samoczynnie (np. po przejściu z sekundy 59 na 00 nie zmieniają się minuty w edytorze).
* **Zaawansowany interfejs (FSM):** Niezależne tryby edycji godziny i budzika chronione przez maszynę stanów i 60-sekundowy timeout.
* **Sprzętowy wyłącznik i drzemka:** Alarm posiada własny, fizyczny suwak dezaktywacji oraz funkcję odłożenia na 60 sekund za pomocą przycisku.
* **Automatyczna drzemka:** Jeżeli budzik będzie dzwonił nieprzerwanie przez 60 sekund bez reakcji użytkownika, samoczynnie przejdzie w tryb drzemki.
* **Wizualny Alarm:** Zastąpienie cyfr pełnym, migającym napisem `A L A r M` lub `A.L.A.r.M.` (wykorzystującym 5 wyświetlaczy) oraz dynamiczny efekt "fali" przemieszczający się na diodach LED.

---

## Instrukcja Obsługi (Przyciski i Przełączniki)

Obsługa układu opiera się na przyciskach (`KEY`) oraz przełącznikach suwakowych (`SW`).

### Przełączniki (SW)
* `SW0` - Włącza i wyłącza główny wyświetlacz czasu. (Gdy budzik zadzwoni, wyświetlacz włączy się automatycznie, ignorując wyłączony `SW0`).
* `SW1` - **Główny sprzętowy wyłącznik budzika.** Pozycja górna: budzik uzbrojony. Pozycja dolna: budzik wyłączony.
* `SW2` - Zmienia opcje wizualne dzwoniącego alarmu (dół: napis `A L A r M`, góra: napis z kropkami `A.L.A.r.M.`).
* `SW9, SW8, SW7` - Wybór elementu do edycji. Uruchomienie przełącznika oznacza wprowadzanie (9: godzin, 8: minut, 7: sekund). Możliwy jest wybór kilku elementów naraz. Wyłączenie ich na `0` jest potrzebne przy zatwierdzaniu lub anulowaniu.

### Przyciski (KEY)
* `KEY0` - Naciśnięcie aktywuje ustawianie godziny. W trybie edycji służy jako `PLUS`. Pełni również funkcję `ENTER` dla godziny oraz `ANULOWANIE` dla budzika.
* `KEY1` - Naciśnięcie aktywuje ustawianie budzika. W trybie edycji służy jako `MINUS`. Pełni również funkcję `ENTER` dla budzika oraz `ANULOWANIE` dla godziny. W trakcie dzwonienia alarmu służy jako **DRZEMKA** (odkłada dzwonienie o 60 sekund).

---

## Fazy działania programu

### 1. Normalne wyświetlanie godziny
Domyślny tryb pracy. Aby wyświetlacz był włączony, przełącznik `SW0` musi być w górze. Gdy `SW0` jest wyłączony - następuje zgaszenie wyświetlacza.

### 2. Edycja Godziny
* **Wejście:** Wciśnij `KEY0`.
* **Wprowadzanie:** Wybierz edytowany element za pomocą `SW9`, `SW8` lub `SW7`. Powoduje to miganie edytowanego elementu, a kropki zaczynają mrugać. Czas zwiększasz przyciskiem `KEY0`, a zmniejszasz `KEY1`.
* **Zatwierdzenie:** Ustaw przełączniki `SW9`, `SW8`, `SW7` w pozycję `0`, a następnie kliknij `KEY0` (przycisk od godziny).
* **Anulowanie:** Ustaw przełączniki `SW9`, `SW8`, `SW7` w pozycję `0`, a następnie naciśnij `KEY1` (przycisk przeciwny do godziny).
* **Timeout:** System automatycznie wychodzi z trybu edycji po minucie braku aktywności ze strony użytkownika.

### 3. Edycja Budzika
* **Wejście:** Wciśnij `KEY1`.
* **Wprowadzanie:** Mechanika identyczna jak w przypadku godziny (wybór `SW9-7`, dodawanie/odejmowanie przyciskami).
* **Zatwierdzenie:** Ustaw przełączniki `SW9`, `SW8`, `SW7` w pozycję `0`, a następnie kliknij `KEY1` (przycisk od budzika).
* **Anulowanie:** Ustaw przełączniki `SW9`, `SW8`, `SW7` w pozycję `0`, a następnie naciśnij `KEY0` (przycisk przeciwny do budzika).

### 4. Dzwonienie Budzika i Drzemka
Gdy zrówna się czas główny z czasem alarmu, a przełącznik uzbrojenia `SW1` jest w górze, układ przechodzi w stan dzwonienia.
* Zignorowany zostaje stan wyłącznika ekranu `SW0` (budzik ma wyższy priorytet).
* Wyświetlacze pokazują migający napis `A L A r M` (lub `A.L.A.r.M.` w zależności od `SW2`). Wyświetlacz `HEX0` pozostaje wygaszony.
* Diody `LEDR` uruchamiają animację wędrującego punktu ("fala").
* **DRZEMKA:** Aby wyciszyć alarm na 60 sekund, należy nacisnąć `KEY1`. Po minucie budzik zadzwoni ponownie. Jeżeli alarm nie zostanie wyłączony, po 60 sekundach dzwonienia tryb drzemki uruchomi się automatycznie.
* **WYŁĄCZENIE:** Aby definitywnie wyłączyć budzik, przesuń suwak `SW1` w dół.

---

## 📂 Architektura Projektu (Pliki VHDL)

* `zegar.vhd` - Główny moduł (Top-Level) spinający wszystkie komponenty, zarządzający sygnałami płyty i animacją fali LED.
* `rtc_fsm.vhd` - Maszyna stanów kontrolująca logikę nawigacji, zatwierdzanie/anulowanie i systemowy timeout.
* `brudnopis.vhd` - Pamięć "cienia" pozwalająca na bezpieczną edycję cyfr bez ingerencji w aktualnie liczący zegar główny.
* `d_cntr4ceo.vhd` & `cntr_xN.vhd` - Kaskadowe, synchroniczne liczniki dziesiętne tworzące serce odliczające czas oraz preskaler sygnału (z 50 MHz do 1 Hz).
* `mux4x1.vhd` - Multipleksery kierujące odpowiednie cyfry (czas główny, brudnopis lub budzik) na dekodery.
* `dec7seg.vhd` - Dekodery BCD na fizyczne sygnały wyświetlaczy 7-segmentowych.
* `debouncer.vhd` - Układ filtracji drgań styków dla przycisków mechanicznych na płytce (wyłapujący jednozboczowe wciśnięcia).
