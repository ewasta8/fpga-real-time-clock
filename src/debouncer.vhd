library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    port (
        clk       : in  std_logic;  -- Główny zegar 50 MHz
        btn_in    : in  std_logic;  -- Fizyczne wejście przycisku z płytki
        btn_pulse : out std_logic   -- Krótki impuls '1' (dokładnie +1 dla licznika)
    );
end entity debouncer;

architecture rtl of debouncer is
    -- 20 ms przy 50 MHz = 1 000 000 cykli zegara
    constant DEBOUNCE_LIMIT : integer := 1000000;
    signal counter   : integer range 0 to DEBOUNCE_LIMIT := 0;

    -- Rejestry wewnętrzne
    signal flipflops : std_logic_vector(1 downto 0) := "11"; -- Domyślnie '1' (bo na DE10-Lite nie wciśnięty to '1')
    signal btn_state : std_logic := '1';
    signal btn_prev  : std_logic := '1';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- 1. Synchronizator podwójny (chroni przed metastabilnością)
            flipflops(0) <= btn_in;
            flipflops(1) <= flipflops(0);

            -- 2. Eliminator drgań styków (Debouncer)
            if (flipflops(1) /= btn_state) then
                counter <= counter + 1;
                if (counter = DEBOUNCE_LIMIT) then
                    btn_state <= flipflops(1); -- Zmień stan oficjalnie dopiero po 20 ms stabilności
                    counter <= 0;
                end if;
            else
                counter <= 0;
            end if;

            -- 3. Detektor Zbocza (Edge Detector)
            btn_prev <= btn_state;
            
            -- Szukamy zbocza opadającego: przycisk był '1' (puszczony), a teraz jest '0' (wciśnięty)
            if (btn_prev = '1' and btn_state = '0') then
                btn_pulse <= '1';  -- Wyślij impuls trwający 1 takt zegara
            else
                btn_pulse <= '0';
            end if;

        end if;
    end process;
end architecture rtl;