library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity brudnopis is
    port (
        clk  : in std_logic;
        load : in std_logic; -- '1' zasysa dane z wejść (np. wchodzimy w edycję)
        
        -- WEJŚCIA (Dane do zassania)
        in_h_dz, in_h_j : in std_logic_vector(3 downto 0);
        in_m_dz, in_m_j : in std_logic_vector(3 downto 0);
        in_s_dz, in_s_j : in std_logic_vector(3 downto 0);
        
        -- STEROWANIE (Sygnały z debouncerów połączone z przełącznikami)
        inc_h, dec_h : in std_logic;
        inc_m, dec_m : in std_logic;
        inc_s, dec_s : in std_logic;
        
        -- WYJŚCIA (Aktualny stan brudnopisu)
        out_h_dz, out_h_j : out std_logic_vector(3 downto 0);
        out_m_dz, out_m_j : out std_logic_vector(3 downto 0);
        out_s_dz, out_s_j : out std_logic_vector(3 downto 0)
    );
end entity brudnopis;

architecture rtl of brudnopis is
    -- Wewnętrzne rejestry przechowujące cyfry
    signal r_h_dz, r_h_j : std_logic_vector(3 downto 0) := x"0";
    signal r_m_dz, r_m_j : std_logic_vector(3 downto 0) := x"0";
    signal r_s_dz, r_s_j : std_logic_vector(3 downto 0) := x"0";
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if load = '1' then
                -- Tryb zassania danych (Kopiowanie czasu)
                r_h_dz <= in_h_dz; r_h_j <= in_h_j;
                r_m_dz <= in_m_dz; r_m_j <= in_m_j;
                r_s_dz <= in_s_dz; r_s_j <= in_s_j;
            else
                -- =======================================
                -- EDYCJA GODZIN (Modulo 24)
                -- =======================================
                if inc_h = '1' then
                    if r_h_dz = x"2" and r_h_j = x"3" then -- 23 -> 00
                        r_h_dz <= x"0"; r_h_j <= x"0";
                    elsif r_h_j = x"9" then
                        r_h_dz <= r_h_dz + 1; r_h_j <= x"0";
                    else
                        r_h_j <= r_h_j + 1;
                    end if;
                elsif dec_h = '1' then
                    if r_h_dz = x"0" and r_h_j = x"0" then -- 00 -> 23
                        r_h_dz <= x"2"; r_h_j <= x"3";
                    elsif r_h_j = x"0" then
                        r_h_dz <= r_h_dz - 1; r_h_j <= x"9";
                    else
                        r_h_j <= r_h_j - 1;
                    end if;
                end if;

                -- =======================================
                -- EDYCJA MINUT (Modulo 60)
                -- =======================================
                if inc_m = '1' then
                    if r_m_dz = x"5" and r_m_j = x"9" then -- 59 -> 00
                        r_m_dz <= x"0"; r_m_j <= x"0";
                    elsif r_m_j = x"9" then
                        r_m_dz <= r_m_dz + 1; r_m_j <= x"0";
                    else
                        r_m_j <= r_m_j + 1;
                    end if;
                elsif dec_m = '1' then
                    if r_m_dz = x"0" and r_m_j = x"0" then -- 00 -> 59
                        r_m_dz <= x"5"; r_m_j <= x"9";
                    elsif r_m_j = x"0" then
                        r_m_dz <= r_m_dz - 1; r_m_j <= x"9";
                    else
                        r_m_j <= r_m_j - 1;
                    end if;
                end if;

                -- =======================================
                -- EDYCJA SEKUND (Modulo 60)
                -- =======================================
                if inc_s = '1' then
                    if r_s_dz = x"5" and r_s_j = x"9" then
                        r_s_dz <= x"0"; r_s_j <= x"0";
                    elsif r_s_j = x"9" then
                        r_s_dz <= r_s_dz + 1; r_s_j <= x"0";
                    else
                        r_s_j <= r_s_j + 1;
                    end if;
                elsif dec_s = '1' then
                    if r_s_dz = x"0" and r_s_j = x"0" then
                        r_s_dz <= x"5"; r_s_j <= x"9";
                    elsif r_s_j = x"0" then
                        r_s_dz <= r_s_dz - 1; r_s_j <= x"9";
                    else
                        r_s_j <= r_s_j - 1;
                    end if;
                end if;
                
            end if;
        end if;
    end process;

    -- Wystawienie stanów rejestrów na wyjścia
    out_h_dz <= r_h_dz; out_h_j <= r_h_j;
    out_m_dz <= r_m_dz; out_m_j <= r_m_j;
    out_s_dz <= r_s_dz; out_s_j <= r_s_j;

end architecture rtl;