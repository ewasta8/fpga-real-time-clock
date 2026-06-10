library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dec7seg is
    generic (delay: time := 3 ns);
    Port ( hex : in std_logic_vector(3 downto 0);
           seg : out std_logic_vector(6 downto 0));
end entity dec7seg;

architecture with_delay of dec7seg is
signal seg_s: std_logic_vector(seg'range);

begin
  seg <= not seg_s after delay;
   with hex select             --        0
	seg_s <= "0000110" when "0001",--    -----
		"1011011" when "0010",     --    5|     |1
		"1001111" when "0011",	   --     |  6  |
		"1100110" when "0100",	   --      -----
		"1101101" when "0101",	   --    4|     |2
		"1111101" when "0110",	   --     |     |
		"0000111" when "0111",     --      -----
		"1111111" when "1000",	   --        3
		"1101111" when "1001",	   --
    "0111111" when "0000",
    "1110111" when "1010",
    "1111100" when "1011",
    "0111001" when "1100",
    "1011110" when "1101",
    "1111001" when "1110",
    "1110001" when "1111",
    "0000000" when others
    ;      --
end architecture with_delay;