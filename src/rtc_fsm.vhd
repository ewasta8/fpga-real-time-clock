library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rtc_fsm is
    port(
        clk      : in std_logic;
        rst      : in std_logic;
        tick_1Hz : in std_logic; 
        
        key0_p   : in std_logic; 
        key1_p   : in std_logic; 
        sw       : in std_logic_vector(9 downto 7); 
        
        mux_sel      : out std_logic_vector(1 downto 0);
        load_shadow  : out std_logic; 
        save_shadow  : out std_logic; 
        
        -- NOWE: Sterowanie cieniem budzika
        load_alarm   : out std_logic;
        save_alarm   : out std_logic;
        
        t_inc_h : out std_logic;  t_dec_h : out std_logic;
        t_inc_m : out std_logic;  t_dec_m : out std_logic;
        t_inc_s : out std_logic;  t_dec_s : out std_logic;
        
        a_inc_h : out std_logic;  a_dec_h : out std_logic;
        a_inc_m : out std_logic;  a_dec_m : out std_logic;
        a_inc_s : out std_logic;  a_dec_s : out std_logic
    );
end entity rtc_fsm;

architecture rtl of rtc_fsm is
    type state_type is (NORMALNY, EDYCJA_CZASU, EDYCJA_BUDZIKA);
    signal c_state, n_state : state_type;
    signal sw_zero : std_logic;
    signal timeout_cnt     : integer range 0 to 60 := 0;
    signal timeout_trigger : std_logic;

begin
    sw_zero <= '1' when sw = "000" else '0';
    timeout_trigger <= '1' when timeout_cnt = 60 else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                c_state <= NORMALNY;
                timeout_cnt <= 0;
            else
                c_state <= n_state;
                if n_state = NORMALNY then
                    timeout_cnt <= 0; 
                else
                    if key0_p = '1' or key1_p = '1' then
                        timeout_cnt <= 0; 
                    elsif tick_1Hz = '1' then
                        timeout_cnt <= timeout_cnt + 1; 
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(c_state, key0_p, key1_p, sw_zero, sw, timeout_trigger)
    begin
        n_state <= c_state;
        mux_sel <= "00";
        load_shadow <= '0'; save_shadow <= '0';
        load_alarm <= '0';  save_alarm <= '0';
        t_inc_h <= '0'; t_dec_h <= '0'; t_inc_m <= '0'; t_dec_m <= '0'; t_inc_s <= '0'; t_dec_s <= '0';
        a_inc_h <= '0'; a_dec_h <= '0'; a_inc_m <= '0'; a_dec_m <= '0'; a_inc_s <= '0'; a_dec_s <= '0';

        case c_state is
            when NORMALNY =>
                mux_sel <= "00"; 
                if key0_p = '1' then
                    n_state <= EDYCJA_CZASU;
                    load_shadow <= '1'; 
                elsif key1_p = '1' then
                    n_state <= EDYCJA_BUDZIKA;
                    load_alarm <= '1'; -- Kopiuj prawdziwy budzik na brudnopis
                end if;

            when EDYCJA_CZASU =>
                mux_sel <= "01"; 
                if timeout_trigger = '1' then
                    n_state <= NORMALNY;
                elsif sw_zero = '1' then
                    if key0_p = '1' then       
                        save_shadow <= '1';    
                        n_state <= NORMALNY;
                    elsif key1_p = '1' then    
                        n_state <= NORMALNY;
                    end if;
                else
                    if key0_p = '1' then
                        t_inc_h <= sw(9); t_inc_m <= sw(8); t_inc_s <= sw(7);
                    elsif key1_p = '1' then
                        t_dec_h <= sw(9); t_dec_m <= sw(8); t_dec_s <= sw(7);
                    end if;
                end if;

            when EDYCJA_BUDZIKA =>
                mux_sel <= "10"; 
                if timeout_trigger = '1' then
                    n_state <= NORMALNY;
                elsif sw_zero = '1' then
                    if key1_p = '1' then       -- Zgodnie ze spec: ZATWIERDZENIE to KEY1
                        save_alarm <= '1';
                        n_state <= NORMALNY;
                    elsif key0_p = '1' then    -- Zgodnie ze spec: ANULOWANIE to KEY0
                        n_state <= NORMALNY;
                    end if;
                else
                    if key0_p = '1' then
                        a_inc_h <= sw(9); a_inc_m <= sw(8); a_inc_s <= sw(7);
                    elsif key1_p = '1' then
                        a_dec_h <= sw(9); a_dec_m <= sw(8); a_dec_s <= sw(7);
                    end if;
                end if;
        end case;
    end process;
end architecture rtl;