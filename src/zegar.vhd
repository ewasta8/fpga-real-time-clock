library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity zegar is
    port (
        clk  : in std_logic;
        rst  : in std_logic;
        KEY0 : in std_logic;  -- Przycisk PLUS / Zatwierdzania
        KEY1 : in std_logic;  -- Przycisk MINUS / Anulowania / Budzika / Drzemki
        SW   : in std_logic_vector(9 downto 0); -- 0: Ekran, 1: Włącznik Budzika, 2: Kropki A.L.A.r.M., 9-7: Wybór
        
        HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : out std_logic_vector(7 downto 0);
        LEDR : out std_logic_vector(9 downto 0)
    );
end entity zegar;

architecture rtl of zegar is
    -- ==========================================
    -- 1. SYGNAŁY ZEGAROWE I PRZYCISKI
    -- ==========================================
    signal prescaler_q   : std_logic_vector(31 downto 0);
    signal prescaler_rst : std_logic := '0';
    signal tick_1Hz      : std_logic := '0';
    signal blink_2_5Hz   : std_logic;
    
    signal key0_pulse : std_logic;
    signal key1_pulse : std_logic;
    signal fsm_key1_pulse : std_logic; 

    -- ==========================================
    -- 2. SYGNAŁY MASZYNY STANÓW (FSM)
    -- ==========================================
    signal mux_sel     : std_logic_vector(1 downto 0);
    signal load_shadow : std_logic;
    signal save_shadow : std_logic;
    signal load_alarm  : std_logic;
    signal save_alarm  : std_logic;
    
    signal t_inc_h, t_dec_h, t_inc_m, t_dec_m, t_inc_s, t_dec_s : std_logic;
    signal a_inc_h, a_dec_h, a_inc_m, a_dec_m, a_inc_s, a_dec_s : std_logic;

    -- ==========================================
    -- 3. SYGNAŁY CZASU GŁÓWNEGO
    -- ==========================================
    signal ce_sek_dzies, ce_min_jedn, ce_min_dzies, ce_godz_jedn, ce_godz_dzies : std_logic;
    signal rst_sek_dzies, rst_min_dzies, rst_godziny : std_logic;

    signal q_s_j, q_s_dz : std_logic_vector(3 downto 0);
    signal q_m_j, q_m_dz : std_logic_vector(3 downto 0);
    signal q_h_j, q_h_dz : std_logic_vector(3 downto 0);

    -- ==========================================
    -- 4. SYGNAŁY PAMIĘCI (BRUDNOPIS + BUDZIK)
    -- ==========================================
    signal sh_s_j, sh_s_dz : std_logic_vector(3 downto 0);
    signal sh_m_j, sh_m_dz : std_logic_vector(3 downto 0);
    signal sh_h_j, sh_h_dz : std_logic_vector(3 downto 0);
    
    signal al_s_j, al_s_dz : std_logic_vector(3 downto 0) := x"0";
    signal al_m_j, al_m_dz : std_logic_vector(3 downto 0) := x"0";
    signal al_h_j, al_h_dz : std_logic_vector(3 downto 0) := x"0";
    
    signal sh_al_s_j, sh_al_s_dz : std_logic_vector(3 downto 0);
    signal sh_al_m_j, sh_al_m_dz : std_logic_vector(3 downto 0);
    signal sh_al_h_j, sh_al_h_dz : std_logic_vector(3 downto 0);
    
    -- ==========================================
    -- 5. SYGNAŁY ALARMU I DRZEMKI
    -- ==========================================
    signal alarm_trigger : std_logic := '0';
    signal alarm_active  : std_logic := '0';
    signal alarm_matched : std_logic := '0'; 
    signal snooze_active : std_logic := '0';
    signal snooze_cnt    : integer range 0 to 60 := 0;
    signal ringing_cnt   : integer range 0 to 60 := 0; -- Zlicza czas dzwonienia alarmu

    -- ==========================================
    -- 6. SYGNAŁY WYŚWIETLANIA I FALI LED
    -- ==========================================
    signal disp_h_dz, disp_h_j : std_logic_vector(3 downto 0);
    signal disp_m_dz, disp_m_j : std_logic_vector(3 downto 0);
    signal disp_s_dz, disp_s_j : std_logic_vector(3 downto 0);

    signal hex5_raw, hex4_raw, hex3_raw : std_logic_vector(6 downto 0);
    signal hex2_raw, hex1_raw, hex0_raw : std_logic_vector(6 downto 0);

    signal wave_tick : std_logic;
    signal led_wave  : std_logic_vector(9 downto 0) := "0000000001";
    signal wave_dir  : std_logic := '0';

begin
    -- ==========================================
    -- A) GENERATORY I WEJŚCIA
    -- ==========================================
    Prescaler: entity work.cntr_xN
        generic map (N => 8)
        port map (clk => clk, rst => prescaler_rst, ce => '1', ceo => open, q => prescaler_q);

    process(clk) begin
        if rising_edge(clk) then
            if prescaler_q = x"49999999" then
                prescaler_rst <= '1'; tick_1Hz <= '1';
            else
                prescaler_rst <= '0'; tick_1Hz <= '0';
            end if;
        end if;
    end process;
    
    blink_2_5Hz <= prescaler_q(28);
    wave_tick <= '1' when prescaler_q(23 downto 0) = x"499999" else '0';
    
    Debouncer_KEY0: entity work.debouncer port map (clk, KEY0, key0_pulse);
    Debouncer_KEY1: entity work.debouncer port map (clk, KEY1, key1_pulse);

    -- Maska: FSM widzi KEY1 tylko gdy alarm i drzemka nie grają
    fsm_key1_pulse <= key1_pulse when (alarm_active = '0' and snooze_active = '0') else '0';

    -- ==========================================
    -- B) MÓZG: MASZYNA STANÓW (FSM)
    -- ==========================================
    Glowne_Sterowanie: entity work.rtc_fsm
        port map(
            clk => clk, rst => rst, tick_1Hz => tick_1Hz,
            key0_p => key0_pulse, key1_p => fsm_key1_pulse, sw => SW(9 downto 7),
            mux_sel => mux_sel, load_shadow => load_shadow, save_shadow => save_shadow,
            load_alarm => load_alarm, save_alarm => save_alarm,
            t_inc_h => t_inc_h, t_dec_h => t_dec_h, t_inc_m => t_inc_m, t_dec_m => t_dec_m, t_inc_s => t_inc_s, t_dec_s => t_dec_s,
            a_inc_h => a_inc_h, a_dec_h => a_dec_h, a_inc_m => a_inc_m, a_dec_m => a_dec_m, a_inc_s => a_inc_s, a_dec_s => a_dec_s
        );

    -- ==========================================
    -- C) SILNIK: GŁÓWNY ZEGAR BCD
    -- ==========================================
    rst_sek_dzies <= '1' when (q_s_dz = x"6" or rst = '1') else '0';
    rst_min_dzies <= '1' when (q_m_dz = x"6" or rst = '1') else '0';
    rst_godziny   <= '1' when (q_h_dz = x"2" and q_h_j = x"4" or rst = '1') else '0';

    Sek_Jedn: entity work.d_cntr4ceo port map(clk, rst, tick_1Hz, save_shadow, sh_s_j, open, ce_sek_dzies, q_s_j);
    Sek_Dzies: entity work.d_cntr4ceo port map(clk, rst_sek_dzies, ce_sek_dzies, save_shadow, sh_s_dz, open, ce_min_jedn, q_s_dz);
    Min_Jedn: entity work.d_cntr4ceo port map(clk, rst, ce_min_jedn, save_shadow, sh_m_j, open, ce_min_dzies, q_m_j);
    Min_Dzies: entity work.d_cntr4ceo port map(clk, rst_min_dzies, ce_min_dzies, save_shadow, sh_m_dz, open, ce_godz_jedn, q_m_dz);
    
    -- UWAGA: Zastosowano tu poprawne odwołanie do d_cntr4ceo
    Godz_Jedn: entity work.d_cntr4ceo port map(clk, rst_godziny, ce_godz_jedn, save_shadow, sh_h_j, open, ce_godz_dzies, q_h_j);
    Godz_Dzies: entity work.d_cntr4ceo port map(clk, rst_godziny, ce_godz_dzies, save_shadow, sh_h_dz, open, open, q_h_dz);

    -- ==========================================
    -- D) PAMIĘĆ: BRUDNOPIS I BUDZIK
    -- ==========================================
    Edytor_Czasu: entity work.brudnopis
        port map (
            clk => clk, load => load_shadow,
            in_h_dz => q_h_dz, in_h_j => q_h_j, in_m_dz => q_m_dz, in_m_j => q_m_j, in_s_dz => q_s_dz, in_s_j => q_s_j,
            inc_h => t_inc_h, dec_h => t_dec_h, inc_m => t_inc_m, dec_m => t_dec_m, inc_s => t_inc_s, dec_s => t_dec_s,
            out_h_dz => sh_h_dz, out_h_j => sh_h_j, out_m_dz => sh_m_dz, out_m_j => sh_m_j, out_s_dz => sh_s_dz, out_s_j => sh_s_j
        );

    Pamiec_Budzika: entity work.brudnopis
        port map (
            clk => clk, load => load_alarm,
            in_h_dz => al_h_dz, in_h_j => al_h_j, in_m_dz => al_m_dz, in_m_j => al_m_j, in_s_dz => al_s_dz, in_s_j => al_s_j,
            inc_h => a_inc_h, dec_h => a_dec_h, inc_m => a_inc_m, dec_m => a_dec_m, inc_s => a_inc_s, dec_s => a_dec_s,
            out_h_dz => sh_al_h_dz, out_h_j => sh_al_h_j, out_m_dz => sh_al_m_dz, out_m_j => sh_al_m_j, out_s_dz => sh_al_s_dz, out_s_j => sh_al_s_j
        );

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                al_s_j <= x"0"; al_s_dz <= x"0"; al_m_j <= x"0"; al_m_dz <= x"0"; al_h_j <= x"0"; al_h_dz <= x"0";
            elsif save_alarm = '1' then
                al_s_j <= sh_al_s_j; al_s_dz <= sh_al_s_dz; al_m_j <= sh_al_m_j; al_m_dz <= sh_al_m_dz; al_h_j <= sh_al_h_j; al_h_dz <= sh_al_h_dz;
            end if;
        end if;
    end process;

    -- ==========================================
    -- E) LOGIKA ALARMU Z DRZEMKĄ I WYŁĄCZNIKIEM
    -- ==========================================
    alarm_trigger <= '1' when (q_s_j = al_s_j and q_s_dz = al_s_dz and q_m_j = al_m_j and 
                               q_m_dz = al_m_dz and q_h_j = al_h_j and q_h_dz = al_h_dz) else '0';

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then 
                alarm_active <= '0';
                alarm_matched <= '0';
                snooze_active <= '0';
                snooze_cnt <= 0;
                ringing_cnt <= 0;
            else
                -- SW(1) TO GŁÓWNY WYŁĄCZNIK BUDZIKA
                if SW(1) = '0' then
                    alarm_active <= '0';
                    snooze_active <= '0';
                    alarm_matched <= '0';
                    ringing_cnt <= 0;
                else
                    -- Detekcja czasu budzenia
                    if alarm_trigger = '1' and alarm_matched = '0' then
                        alarm_active <= '1';
                        alarm_matched <= '1';
                        ringing_cnt <= 0;
                    elsif alarm_trigger = '0' then
                        alarm_matched <= '0';
                    end if;
                    
                    -- Zliczanie czasu dzwonienia alarmu
                    if alarm_active = '1' and tick_1Hz = '1' then
                        ringing_cnt <= ringing_cnt + 1;
                    end if;

                    -- AUTO-DRZEMKA (Jeśli dzwoni równo 60 sekund bez reakcji)
                    if alarm_active = '1' and ringing_cnt = 60 then
                        alarm_active <= '0';
                        snooze_active <= '1';
                        snooze_cnt <= 60;
                        ringing_cnt <= 0;
                    end if;

                    -- RĘCZNA Aktywacja drzemki przez KEY1 (nadpisuje auto-drzemkę)
                    if alarm_active = '1' and key1_pulse = '1' then 
                        alarm_active <= '0';
                        snooze_active <= '1';
                        snooze_cnt <= 60; -- Odliczanie 60 sekund
                        ringing_cnt <= 0;
                    end if;

                    -- Odliczanie trwającej drzemki
                    if snooze_active = '1' and tick_1Hz = '1' then
                        if snooze_cnt = 1 then
                            snooze_active <= '0';
                            alarm_active <= '1'; -- Wznowienie alarmu po odczekaniu drzemki
                            ringing_cnt <= 0;
                        else
                            snooze_cnt <= snooze_cnt - 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ==========================================
    -- F) MULTIPLEKSERY I DEKODERY
    -- ==========================================
    MUX_H_DZ: entity work.mux4x1 port map(q_h_dz, sh_h_dz, sh_al_h_dz, x"0", mux_sel(1), mux_sel(0), disp_h_dz);
    MUX_H_J:  entity work.mux4x1 port map(q_h_j,  sh_h_j,  sh_al_h_j,  x"0", mux_sel(1), mux_sel(0), disp_h_j);
    MUX_M_DZ: entity work.mux4x1 port map(q_m_dz, sh_m_dz, sh_al_m_dz, x"0", mux_sel(1), mux_sel(0), disp_m_dz);
    MUX_M_J:  entity work.mux4x1 port map(q_m_j,  sh_m_j,  sh_al_m_j,  x"0", mux_sel(1), mux_sel(0), disp_m_j);
    MUX_S_DZ: entity work.mux4x1 port map(q_s_dz, sh_s_dz, sh_al_s_dz, x"0", mux_sel(1), mux_sel(0), disp_s_dz);
    MUX_S_J:  entity work.mux4x1 port map(q_s_j,  sh_s_j,  sh_al_s_j,  x"0", mux_sel(1), mux_sel(0), disp_s_j);

    DEC5: entity work.dec7seg port map(disp_h_dz, hex5_raw);
    DEC4: entity work.dec7seg port map(disp_h_j,  hex4_raw);
    DEC3: entity work.dec7seg port map(disp_m_dz, hex3_raw);
    DEC2: entity work.dec7seg port map(disp_m_j,  hex2_raw);
    DEC1: entity work.dec7seg port map(disp_s_dz, hex1_raw);
    DEC0: entity work.dec7seg port map(disp_s_j,  hex0_raw);

    -- ==========================================
    -- H) EFEKTY WIZUALNE I KROPKI
    -- ==========================================
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
                    -- A. L. A. r. M.
                    HEX5 <= "00001000"; HEX4 <= "01000111"; HEX3 <= "00001000"; 
                    HEX2 <= "00101111"; HEX1 <= "01001000"; HEX0 <= x"FF";
                else
                    -- A L A r M
                    HEX5 <= "10001000"; HEX4 <= "11000111"; HEX3 <= "10001000"; 
                    HEX2 <= "10101111"; HEX1 <= "11001000"; HEX0 <= x"FF";
                end if;
            else
                HEX5 <= x"FF"; HEX4 <= x"FF"; HEX3 <= x"FF"; 
                HEX2 <= x"FF"; HEX1 <= x"FF"; HEX0 <= x"FF";
            end if;
            
        elsif SW(0) = '0' then
            HEX5 <= x"FF"; HEX4 <= x"FF"; HEX3 <= x"FF"; 
            HEX2 <= x"FF"; HEX1 <= x"FF"; HEX0 <= x"FF";
        end if;
    end process;

    -- ==========================================
    -- I) PROCES FALI LED
    -- ==========================================
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