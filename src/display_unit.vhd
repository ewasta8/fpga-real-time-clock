library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity display_unit is
    port (
        clk          : in std_logic;
        rst          : in std_logic;
        
        disp_h_dz    : in std_logic_vector(3 downto 0);
        disp_h_j     : in std_logic_vector(3 downto 0);
        disp_m_dz    : in std_logic_vector(3 downto 0);
        disp_m_j     : in std_logic_vector(3 downto 0);
        disp_s_dz    : in std_logic_vector(3 downto 0);
        disp_s_j     : in std_logic_vector(3 downto 0);
        
        mux_sel      : in std_logic_vector(1 downto 0);
        blink_2_5Hz  : in std_logic;
        wave_tick    : in std_logic;
        alarm_active : in std_logic;
        SW           : in std_logic_vector(9 downto 0);

        HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : out std_logic_vector(7 downto 0);
        LEDR : out std_logic_vector(9 downto 0)
    );
end entity display_unit;

architecture rtl of display_unit is
    signal hex5_raw, hex4_raw, hex3_raw, hex2_raw, hex1_raw, hex0_raw : std_logic_vector(6 downto 0);
    signal led_wave : std_logic_vector(9 downto 0) := "0000000001";
    signal wave_dir : std_logic := '0';
begin
    DEC5: entity work.dec7seg port map(disp_h_dz, hex5_raw);
    DEC4: entity work.dec7seg port map(disp_h_j,  hex4_raw);
    DEC3: entity work.dec7seg port map(disp_m_dz, hex3_raw);
    DEC2: entity work.dec7seg port map(disp_m_j,  hex2_raw);
    DEC1: entity work.dec7seg port map(disp_s_dz, hex1_raw);
    DEC0: entity work.dec7seg port map(disp_s_j,  hex0_raw);

    process(SW, blink_2_5Hz, mux_sel, alarm_active, hex5_raw, hex4_raw, hex3_raw, hex2_raw, hex1_raw, hex0_raw)
        variable dot_h, dot_m, dot_s : std_logic;
    begin
        dot_h := '1'; dot_m := '1'; dot_s := '1';

        if mux_sel /= "00" then
            if SW(9) = '1' then dot_h := '0'; end if;
            if SW(8) = '1' then dot_m := '0'; end if;
            if SW(7) = '1' then dot_s := '0'; end if;
        end if;

        HEX5 <= dot_h & hex5_raw; HEX4 <= '1' & hex4_raw;
        HEX3 <= dot_m & hex3_raw; HEX2 <= '1' & hex2_raw;
        HEX1 <= dot_s & hex1_raw; HEX0 <= '1' & hex0_raw;

        if mux_sel /= "00" and blink_2_5Hz = '1' then
            if SW(9) = '1' then HEX5 <= x"FF"; HEX4 <= x"FF"; end if; 
            if SW(8) = '1' then HEX3 <= x"FF"; HEX2 <= x"FF"; end if; 
            if SW(7) = '1' then HEX1 <= x"FF"; HEX0 <= x"FF"; end if; 
        end if;

        if alarm_active = '1' then
            if blink_2_5Hz = '0' then
                if SW(2) = '1' then 
                    HEX5 <= "00001000"; HEX4 <= "01000111"; HEX3 <= "00001000"; 
                    HEX2 <= "00101111"; HEX1 <= "01001000"; HEX0 <= x"FF";
                else
                    HEX5 <= "10001000"; HEX4 <= "11000111"; HEX3 <= "10001000"; 
                    HEX2 <= "10101111"; HEX1 <= "11001000"; HEX0 <= x"FF";
                end if;
            else
                HEX5 <= x"FF"; HEX4 <= x"FF"; HEX3 <= x"FF"; 
                HEX2 <= x"FF"; HEX1 <= x"FF"; HEX0 <= x"FF";
            end if;
        elsif SW(0) = '0' and mux_sel = "00" then
            HEX5 <= x"FF"; HEX4 <= x"FF"; HEX3 <= x"FF";
            HEX2 <= x"FF"; HEX1 <= x"FF"; HEX0 <= x"FF";
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' or alarm_active = '0' then
                led_wave <= "0000000001";
                wave_dir <= '0';
            elsif wave_tick = '1' then
                if wave_dir = '0' then
                    led_wave <= led_wave(8 downto 0) & '0';
                    if led_wave(8) = '1' then wave_dir <= '1'; end if; 
                else
                    led_wave <= '0' & led_wave(9 downto 1);
                    if led_wave(1) = '1' then wave_dir <= '0'; end if; 
                end if;
            end if;
        end if;
    end process;

    LEDR <= led_wave when alarm_active = '1' else (others => '0');
end architecture rtl;
