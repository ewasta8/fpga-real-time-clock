--------------------------------------------------------------------------------
-- lab VHDL
-- multiplexer 4x1 (Zaktualizowany dla 4-bitowych cyfr BCD)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity mux4x1 is
    port (
        d0, d1, d2, d3 : in  std_logic_vector(3 downto 0); -- Zmiana na wektory 4-bitowe
        s0, s1         : in  std_logic;                    -- Sygnały sterujące (wybór)
        y              : out std_logic_vector(3 downto 0)  -- Wyjście cyfry
    );
end entity mux4x1;

architecture behav of mux4x1 is
    signal sel : std_logic_vector(1 downto 0);
begin
    -- Połączenie dwóch bitów wyboru w jeden wektor dla instrukcji 'select'
    sel <= s1 & s0;

    with sel select
        y <= d0 when "00", -- Wybór 0: Czas Główny
             d1 when "01", -- Wybór 1: Brudnopis Edycji Czasu
             d2 when "10", -- Wybór 2: Pamięć Budzika
             d3 when others;
             
end architecture behav;
--------------------------------------------------------------------------------