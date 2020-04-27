library IEEE;
use IEEE.std_logic_1164.all;

entity hexLocator is
	
	port(
		hex:	 		 in std_logic_vector(7 downto 0);
		location:	out std_logic_vector(15 downto 0)
	);
	
end entity;

architecture locate of hexLocator is

	signal digit: std_logic_vector(3 downto 0);

begin

	digit <= hex(3 downto 0);
	
	location <= X"0000" when digit = X"0" else
					X"0005" when digit = X"1" else
					X"000A" when digit = X"2" else
					X"000F" when digit = X"3" else
					X"0014" when digit = X"4" else
					X"0019" when digit = X"5" else
					X"001E" when digit = X"6" else
					X"0023" when digit = X"7" else
					X"0028" when digit = X"8" else
					X"002D" when digit = X"9" else
					X"0032" when digit = X"A" else
					X"0037" when digit = X"B" else
					X"003C" when digit = X"C" else
					X"0041" when digit = X"D" else
					X"0046" when digit = X"E" else
					X"004B" when digit = X"F";

end architecture;