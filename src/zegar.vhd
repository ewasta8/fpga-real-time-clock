library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity zegar is
    port (
        clk  : in std_logic;
        KEY0 : in std_logic;
        KEY1 : in std_logic;
        SW   : in std_logic_vector(9 downto 0);
        
        HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : out std_logic_vector(7 downto 0);
        LEDR : out std_logic_vector(9 downto 0)
    );
end entity zegar;

architecture structural of zegar is
    signal rst : std_logic;
    
    -- Wewnętrzne sygnały taktujące
    signal tick_1Hz, blink_2_5Hz, wave_tick : std_logic;
    
    -- Sygnały FSM i kontroli
    signal mux_sel : std_logic_vector(1 downto 0);
    signal load_shadow, save_shadow, load_alarm, save_alarm : std_logic;
    signal t_inc_h, t_dec_h, t_inc_m, t_dec_m, t_inc_s, t_dec_s : std_logic;
    signal a_inc_h, a_dec_h, a_inc_m, a_dec_m, a_inc_s, a_dec_s : std_logic;
    
    -- Sygnały alarmu
    signal alarm_trigger, alarm_active : std_logic;
    
    -- Szyny danych BCD
    signal disp_h_dz, disp_h_j : std_logic_vector(3 downto 0);
    signal disp_m_dz, disp_m_j : std_logic_vector(3 downto 0);
    signal disp_s_dz, disp_s_j : std_logic_vector(3 downto 0);

begin
    rst <= SW(6);

    TIMING_INST: entity work.timing_unit
        port map (
            clk         => clk,
            rst         => rst,
            tick_1Hz    => tick_1Hz,
            blink_2_5Hz => blink_2_5Hz,
            wave_tick   => wave_tick
        );

    CONTROL_INST: entity work.control_unit
        port map (
            clk              => clk,
            rst              => rst,
            tick_1Hz         => tick_1Hz,
            KEY0             => KEY0,
            KEY1             => KEY1,
            SW               => SW,
            alarm_trigger    => alarm_trigger,
            mux_sel          => mux_sel,
            load_shadow      => load_shadow,
            save_shadow      => save_shadow,
            load_alarm       => load_alarm,
            save_alarm       => save_alarm,
            t_inc_h => t_inc_h, t_dec_h => t_dec_h, 
            t_inc_m => t_inc_m, t_dec_m => t_dec_m, 
            t_inc_s => t_inc_s, t_dec_s => t_dec_s,
            a_inc_h => a_inc_h, a_dec_h => a_dec_h, 
            a_inc_m => a_inc_m, a_dec_m => a_dec_m, 
            a_inc_s => a_inc_s, a_dec_s => a_dec_s,
            alarm_active_out => alarm_active
        );

    DATAPATH_INST: entity work.datapath_unit
        port map (
            clk           => clk,
            rst           => rst,
            tick_1Hz      => tick_1Hz,
            mux_sel       => mux_sel,
            load_shadow   => load_shadow,
            save_shadow   => save_shadow,
            load_alarm    => load_alarm,
            save_alarm    => save_alarm,
            t_inc_h => t_inc_h, t_dec_h => t_dec_h, 
            t_inc_m => t_inc_m, t_dec_m => t_dec_m, 
            t_inc_s => t_inc_s, t_dec_s => t_dec_s,
            a_inc_h => a_inc_h, a_dec_h => a_dec_h, 
            a_inc_m => a_inc_m, a_dec_m => a_dec_m, 
            a_inc_s => a_inc_s, a_dec_s => a_dec_s,
            disp_h_dz     => disp_h_dz,
            disp_h_j      => disp_h_j,
            disp_m_dz     => disp_m_dz,
            disp_m_j      => disp_m_j,
            disp_s_dz     => disp_s_dz,
            disp_s_j      => disp_s_j,
            alarm_trigger => alarm_trigger
        );

    DISPLAY_INST: entity work.display_unit
        port map (
            clk          => clk,
            rst          => rst,
            disp_h_dz    => disp_h_dz,
            disp_h_j     => disp_h_j,
            disp_m_dz    => disp_m_dz,
            disp_m_j     => disp_m_j,
            disp_s_dz    => disp_s_dz,
            disp_s_j     => disp_s_j,
            mux_sel      => mux_sel,
            blink_2_5Hz  => blink_2_5Hz,
            wave_tick    => wave_tick,
            alarm_active => alarm_active,
            SW           => SW,
            HEX5         => HEX5,
            HEX4         => HEX4,
            HEX3         => HEX3,
            HEX2         => HEX2,
            HEX1         => HEX1,
            HEX0         => HEX0,
            LEDR         => LEDR
        );

end architecture structural;