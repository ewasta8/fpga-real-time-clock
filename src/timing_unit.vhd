library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity timing_unit is
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        tick_1Hz    : out std_logic;
        blink_2_5Hz : out std_logic;
        wave_tick   : out std_logic
    );
end entity timing_unit;

architecture rtl of timing_unit is
    signal prescaler_q   : std_logic_vector(31 downto 0);
    signal prescaler_rst : std_logic := '0';
begin
    Prescaler: entity work.cntr_xN
        generic map (N => 8)
        port map (clk => clk, rst => prescaler_rst or rst, ce => '1', ceo => open, q => prescaler_q);

    process(clk) begin
        if rising_edge(clk) then
            if prescaler_q = x"49999999" then
                prescaler_rst <= '1';
                tick_1Hz <= '1';
            else
                prescaler_rst <= '0';
                tick_1Hz <= '0';
            end if;
        end if;
    end process;
    
    blink_2_5Hz <= prescaler_q(28);
    wave_tick <= '1' when prescaler_q(23 downto 0) = x"499999" else '0';
end architecture rtl;