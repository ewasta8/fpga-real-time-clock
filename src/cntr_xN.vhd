--------------------------------------------------------------------------------
-- lab VHDL
-- x stage decimal counter, async reset, generate for
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cntr_xN is
    generic(N : natural := 6);
    port (
        clk : in std_logic;
        rst : in std_logic;
        ce : in std_logic;
        ceo : out std_logic;
        q : out std_logic_vector(4*N-1 downto 0)
    );
end entity cntr_xN;

architecture struct of cntr_xN is
    signal cei : std_logic_vector(N downto 0);
begin
    cei(0) <= ce;
    ceo <= cei(N);
    gen: for i in 1 to N generate
        cntr: entity work.d_cntr4ceo
        port map(
            clk => clk,
            rst => rst,
            ce  => cei(i-1),
            ld  => '0',
            d   => "0000",
            tc  => open,
            ceo => cei(i),
            q   => q((i*4)-1 downto (i-1)*4)
        );
    end generate;
    
end architecture struct;