library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BCD is
	
	port(	
		bin:	 in std_logic_vector(7 downto 0);
		dec2:	out std_logic_vector(3 downto 0);
		dec1:	out std_logic_vector(3 downto 0);
		dec0:	out std_logic_vector(3 downto 0)
	);
	
end entity;

architecture decimalConversion of BCD is
	
	signal m200, m100: std_logic;
	signal aux2, aux1: std_logic_vector(7 downto 0);
	
	signal m: std_logic_vector(8 downto 0);
	
begin

	m200 <=  '1' when (unsigned(bin) > 199) else
				'0';
				
	m100 <=  '1' when (unsigned(bin) >  99) else
				'0';
				
	aux2 <=	std_logic_vector(unsigned(bin) - 200) when m200 = '1' else
				std_logic_vector(unsigned(bin) - 100) when m100 = '1' else
				bin;
				
	dec2 <=	"0010" when m200 = '1' else
				"0001" when m100 = '1' else
				"0000";
					
	m <=  "100000000" when (unsigned(aux2) > 89) else
			"010000000" when (unsigned(aux2) > 79) else
			"001000000" when (unsigned(aux2) > 69) else
			"000100000" when (unsigned(aux2) > 59) else
			"000010000" when (unsigned(aux2) > 49) else
			"000001000" when (unsigned(aux2) > 39) else
			"000000100" when (unsigned(aux2) > 29) else
			"000000010" when (unsigned(aux2) > 19) else
			"000000001" when (unsigned(aux2) >  9) else
			"000000000";
					
	aux1 <=	std_logic_vector(unsigned(aux2) - 90) when m(8) = '1' else
				std_logic_vector(unsigned(aux2) - 80) when m(7) = '1' else
				std_logic_vector(unsigned(aux2) - 70) when m(6) = '1' else
				std_logic_vector(unsigned(aux2) - 60) when m(5) = '1' else
				std_logic_vector(unsigned(aux2) - 50) when m(4) = '1' else
				std_logic_vector(unsigned(aux2) - 40) when m(3) = '1' else
				std_logic_vector(unsigned(aux2) - 30) when m(2) = '1' else
				std_logic_vector(unsigned(aux2) - 20) when m(1) = '1' else
				std_logic_vector(unsigned(aux2) - 10) when m(0) = '1' else
				aux2;
				
	dec1 <=	"1001" when m(8) = '1' else
				"1000" when m(7) = '1' else
				"0111" when m(6) = '1' else
				"0110" when m(5) = '1' else
				"0101" when m(4) = '1' else
				"0100" when m(3) = '1' else
				"0011" when m(2) = '1' else
				"0010" when m(1) = '1' else
				"0001" when m(0) = '1' else
				"0000";
	
	dec0 <= aux1(3 downto 0);
					
end architecture;