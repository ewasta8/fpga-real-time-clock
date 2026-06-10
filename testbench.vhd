library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity tb_zegar is
end entity tb_zegar;
 
architecture sim of tb_zegar is
    signal clk  : std_logic := '0';
    signal KEY0 : std_logic := '1';
    signal KEY1 : std_logic := '1';
    
    -- Inicjalizacja SW z '1' na końcu, żeby ekrany nie były wygaszone
    signal SW   : std_logic_vector(9 downto 0) := "0000000001";
    
    signal HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : std_logic_vector(7 downto 0);
    signal LEDR : std_logic_vector(9 downto 0);
    
    constant CLK_PERIOD : time := 20 ns; -- 50 MHz
begin
    -- Instancja głównego modułu
    UUT: entity work.zegar
        port map (
            clk => clk, KEY0 => KEY0, KEY1 => KEY1, SW => SW,
            HEX5 => HEX5, HEX4 => HEX4, HEX3 => HEX3, HEX2 => HEX2, HEX1 => HEX1, HEX0 => HEX0, LEDR => LEDR
        );
 
    -- Generacja zegara 50 MHz
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;
 
    -- Główny wektor testowy
    stim_proc: process
    begin
        -- SZYBKI RESET (Tu koniecznie musi być 'ns'!)
        SW(6) <= '1'; 
        wait for 100 ns;
        SW(6) <= '0';
        wait for 100 ns;
        
        -- ====================================================================
        -- ETAP 1: USTAWIENIE BUDZIKA NA 00:00:01
        -- ====================================================================
        KEY1 <= '0'; wait for 50 ms; 
        KEY1 <= '1'; wait for 50 ms;
        
        SW(7) <= '1'; wait for 10 ns;
        
        KEY0 <= '0'; wait for 50 ms; 
        KEY0 <= '1'; wait for 50 ms;
        
        SW(7) <= '0'; wait for 10 ns;
        
        KEY1 <= '0'; wait for 50 ms; 
        KEY1 <= '1'; wait for 50 ms;
        
        -- ====================================================================
        -- ETAP 2: USTAWIENIE CZASU NA 00:00:01 I WYZWOLENIE ALARMU
        -- ====================================================================
        KEY0 <= '0'; wait for 50 ms; 
        KEY0 <= '1'; wait for 50 ms;
        
        SW(7) <= '1'; wait for 10 ns;
        
        KEY0 <= '0'; wait for 50 ms; 
        KEY0 <= '1'; wait for 50 ms;
        
        SW(7) <= '0'; wait for 10 ns;
        
        -- Włączenie przełącznika aktywacji alarmu SW(1) = '1'
        SW(1) <= '1'; wait for 10 ns;
        
        -- Zatwierdzenie czasu
        KEY0 <= '0'; wait for 50 ms; 
        KEY0 <= '1'; wait for 50 ms;
        
        -- Czekamy aż budzik dzwoni (fala LED i ekrany)
        wait for 100 ms;
        
        wait;
    end process;
end architecture sim;