library IEEE;
use IEEE.std_logic_1164.all;

entity SevenSegDisplay is

	port(
		data:	 	 in std_logic_vector(3 downto 0);
		coded: 	out std_logic_vector(6 downto 0)
	);
	
end entity;

architecture display of SevenSegDisplay is
begin

	coded <=	"1000000" when data = "0000" else
				"1111001" when data = "0001" else
				"0100100" when data = "0010" else
				"0110000" when data = "0011" else
				"0011001" when data = "0100" else
				"0010010" when data = "0101" else
				"0000010" when data = "0110" else
				"1111000" when data = "0111" else
				"0000000" when data = "1000" else
				"0010000" when data = "1001" else
				"0001000" when data = "1010" else
				"0000011" when data = "1011" else
				"1000110" when data = "1100" else
				"0100001" when data = "1101" else
				"0000110" when data = "1110" else
				"0001110" when data = "1111" else
				"1111111";

end architecture;