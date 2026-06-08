--------------------------------------------------------------------------------
-- lab VHDL
-- decimal counter, rst synchro
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity d_cntr4ceo is
    Port    (clk : in std_logic;
             rst : in std_logic;
             ce : in std_logic;
			 ld : in std_logic;                      -- sygnał wpisu (Load)
             d : in std_logic_vector(3 downto 0);   -- dane zmienione przez użytkownika
             tc : out std_logic;
             ceo : out std_logic;
             q : out std_logic_vector(3 downto 0) );
end entity d_cntr4ceo;

architecture behav of d_cntr4ceo is
    signal q_tmp : std_logic_vector(q'range) := x"0";
    signal tci : std_logic;
begin
process(clk) begin
	if rising_edge(clk) then
        if rst='1' then
            q_tmp <= x"0";
		elsif ld='1' then
			q_tmp <= d;
        elsif ce='1' then
            if tci='1' then
                q_tmp <= x"0";
            else
	            q_tmp <= q_tmp + 1;
            end if;
        end if;
	end if;	
end process;
-- outputs
tci <= '1' when (q_tmp=9) else '0';    
ceo <= (tci and ce);
tc <= tci;    
q <= q_tmp;
end architecture behav;
--------------------------------------------------------------------------------