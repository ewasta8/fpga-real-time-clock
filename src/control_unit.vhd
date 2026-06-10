library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control_unit is
    port (
        clk           : in std_logic;
        rst           : in std_logic;
        tick_1Hz      : in std_logic;
        KEY0          : in std_logic;
        KEY1          : in std_logic;
        SW            : in std_logic_vector(9 downto 0);
        alarm_trigger : in std_logic;

        mux_sel      : out std_logic_vector(1 downto 0);
        load_shadow  : out std_logic;
        save_shadow  : out std_logic;
        load_alarm   : out std_logic;
        save_alarm   : out std_logic;
        
        t_inc_h : out std_logic; t_dec_h : out std_logic;
        t_inc_m : out std_logic; t_dec_m : out std_logic;
        t_inc_s : out std_logic; t_dec_s : out std_logic;
        
        a_inc_h : out std_logic; a_dec_h : out std_logic;
        a_inc_m : out std_logic; a_dec_m : out std_logic;
        a_inc_s : out std_logic; a_dec_s : out std_logic;

        alarm_active_out : out std_logic
    );
end entity control_unit;

architecture rtl of control_unit is
    signal key0_pulse     : std_logic;
    signal key1_pulse     : std_logic;
    signal fsm_key1_pulse : std_logic;

    signal alarm_active   : std_logic := '0';
    signal alarm_matched  : std_logic := '0';
    signal snooze_active  : std_logic := '0';
    signal snooze_cnt     : integer range 0 to 60 := 0;
    signal ringing_cnt    : integer range 0 to 60 := 0;
begin
    Debouncer_KEY0: entity work.debouncer port map (clk, KEY0, key0_pulse);
    Debouncer_KEY1: entity work.debouncer port map (clk, KEY1, key1_pulse);

    fsm_key1_pulse <= key1_pulse when (alarm_active = '0' and snooze_active = '0') else '0';

    Glowne_Sterowanie: entity work.rtc_fsm
        port map(
            clk => clk, rst => rst, tick_1Hz => tick_1Hz,
            key0_p => key0_pulse, key1_p => fsm_key1_pulse, sw => SW(9 downto 7),
            mux_sel => mux_sel, load_shadow => load_shadow, save_shadow => save_shadow,
            load_alarm => load_alarm, save_alarm => save_alarm,
            t_inc_h => t_inc_h, t_dec_h => t_dec_h, t_inc_m => t_inc_m, t_dec_m => t_dec_m, t_inc_s => t_inc_s, t_dec_s => t_dec_s,
            a_inc_h => a_inc_h, a_dec_h => a_dec_h, a_inc_m => a_inc_m, a_dec_m => a_dec_m, a_inc_s => a_inc_s, a_dec_s => a_dec_s
        );

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                alarm_active <= '0'; alarm_matched <= '0';
                snooze_active <= '0'; snooze_cnt <= 0;
                ringing_cnt <= 0;
            else
                if SW(1) = '0' then
                    alarm_active <= '0'; snooze_active <= '0';
                    alarm_matched <= '0'; ringing_cnt <= 0;
                else
                    if alarm_trigger = '1' and alarm_matched = '0' then
                        alarm_active <= '1'; alarm_matched <= '1'; ringing_cnt <= 0;
                    elsif alarm_trigger = '0' then
                        alarm_matched <= '0';
                    end if;
                    
                    if alarm_active = '1' and tick_1Hz = '1' then
                        ringing_cnt <= ringing_cnt + 1;
                    end if;

                    if alarm_active = '1' and ringing_cnt = 60 then
                        alarm_active <= '0'; snooze_active <= '1';
                        snooze_cnt <= 60; ringing_cnt <= 0;
                    end if;

                    if alarm_active = '1' and key1_pulse = '1' then 
                        alarm_active <= '0'; snooze_active <= '1';
                        snooze_cnt <= 60; ringing_cnt <= 0;
                    end if;

                    if snooze_active = '1' and tick_1Hz = '1' then
                        if snooze_cnt = 1 then
                            snooze_active <= '0'; alarm_active <= '1'; ringing_cnt <= 0;
                        else
                            snooze_cnt <= snooze_cnt - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    alarm_active_out <= alarm_active;
end architecture rtl;