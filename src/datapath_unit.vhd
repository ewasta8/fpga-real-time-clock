library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity datapath_unit is
    port (
        clk, rst, tick_1Hz : in std_logic;
        mux_sel            : in std_logic_vector(1 downto 0);
        load_shadow        : in std_logic;
        save_shadow        : in std_logic;
        load_alarm         : in std_logic;
        save_alarm         : in std_logic;
        
        t_inc_h, t_dec_h, t_inc_m, t_dec_m, t_inc_s, t_dec_s : in std_logic;
        a_inc_h, a_dec_h, a_inc_m, a_dec_m, a_inc_s, a_dec_s : in std_logic;

        disp_h_dz, disp_h_j : out std_logic_vector(3 downto 0);
        disp_m_dz, disp_m_j : out std_logic_vector(3 downto 0);
        disp_s_dz, disp_s_j : out std_logic_vector(3 downto 0);
        
        alarm_trigger : out std_logic
    );
end entity datapath_unit;

architecture rtl of datapath_unit is
    signal ce_sek_dzies, ce_min_jedn, ce_min_dzies, ce_godz_jedn, ce_godz_dzies : std_logic;
    signal rst_sek_dzies, rst_min_dzies, rst_godziny : std_logic;

    signal q_s_j, q_s_dz, q_m_j, q_m_dz, q_h_j, q_h_dz : std_logic_vector(3 downto 0);
    signal sh_s_j, sh_s_dz, sh_m_j, sh_m_dz, sh_h_j, sh_h_dz : std_logic_vector(3 downto 0);
    
    signal al_s_j, al_s_dz, al_m_j, al_m_dz, al_h_j, al_h_dz : std_logic_vector(3 downto 0) := x"0";
    signal sh_al_s_j, sh_al_s_dz, sh_al_m_j, sh_al_m_dz, sh_al_h_j, sh_al_h_dz : std_logic_vector(3 downto 0);
begin
    rst_sek_dzies <= '1' when (q_s_dz = x"6" or rst = '1') else '0';
    rst_min_dzies <= '1' when (q_m_dz = x"6" or rst = '1') else '0';
    rst_godziny   <= '1' when ((q_h_dz = x"2" and q_h_j = x"4") or rst = '1') else '0';

    Sek_Jedn:   entity work.d_cntr4ceo port map(clk, rst, tick_1Hz, save_shadow, sh_s_j, open, ce_sek_dzies, q_s_j);
    Sek_Dzies:  entity work.d_cntr4ceo port map(clk, rst_sek_dzies, ce_sek_dzies, save_shadow, sh_s_dz, open, ce_min_jedn, q_s_dz);
    Min_Jedn:   entity work.d_cntr4ceo port map(clk, rst, ce_min_jedn, save_shadow, sh_m_j, open, ce_min_dzies, q_m_j);
    Min_Dzies:  entity work.d_cntr4ceo port map(clk, rst_min_dzies, ce_min_dzies, save_shadow, sh_m_dz, open, ce_godz_jedn, q_m_dz);
    Godz_Jedn:  entity work.d_cntr4ceo port map(clk, rst_godziny, ce_godz_jedn, save_shadow, sh_h_j, open, ce_godz_dzies, q_h_j);
    Godz_Dzies: entity work.d_cntr4ceo port map(clk, rst_godziny, ce_godz_dzies, save_shadow, sh_h_dz, open, open, q_h_dz);

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

    MUX_H_DZ: entity work.mux4x1
        port map(d0 => q_h_dz, d1 => sh_h_dz, d2 => sh_al_h_dz, d3 => x"0",
                 s0 => mux_sel(0), s1 => mux_sel(1), y => disp_h_dz);
    MUX_H_J: entity work.mux4x1
        port map(d0 => q_h_j, d1 => sh_h_j, d2 => sh_al_h_j, d3 => x"0",
                 s0 => mux_sel(0), s1 => mux_sel(1), y => disp_h_j);
    MUX_M_DZ: entity work.mux4x1
        port map(d0 => q_m_dz, d1 => sh_m_dz, d2 => sh_al_m_dz, d3 => x"0",
                 s0 => mux_sel(0), s1 => mux_sel(1), y => disp_m_dz);
    MUX_M_J: entity work.mux4x1
        port map(d0 => q_m_j, d1 => sh_m_j, d2 => sh_al_m_j, d3 => x"0",
                 s0 => mux_sel(0), s1 => mux_sel(1), y => disp_m_j);
    MUX_S_DZ: entity work.mux4x1
        port map(d0 => q_s_dz, d1 => sh_s_dz, d2 => sh_al_s_dz, d3 => x"0",
                 s0 => mux_sel(0), s1 => mux_sel(1), y => disp_s_dz);
    MUX_S_J: entity work.mux4x1
        port map(d0 => q_s_j, d1 => sh_s_j, d2 => sh_al_s_j, d3 => x"0",
                 s0 => mux_sel(0), s1 => mux_sel(1), y => disp_s_j);

    alarm_trigger <= '1' when (q_s_j = al_s_j and q_s_dz = al_s_dz and q_m_j = al_m_j and 
                               q_m_dz = al_m_dz and q_h_j = al_h_j and q_h_dz = al_h_dz) else '0';
end architecture rtl;
