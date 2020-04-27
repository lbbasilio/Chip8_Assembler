library IEEE;
use IEEE.std_logic_1164.all;

entity reg is

	generic(
		size:	integer := 8
	);
	
	port(
		clk:		 in std_logic;
		load:		 in std_logic;
		clear:	 in std_logic;
		D_in:		 in std_logic_vector(size - 1 downto 0);
		D_out:	out std_logic_vector(size - 1 downto 0)
	);
	
end entity;

architecture behavior of reg is
begin

	process(clk)
	begin
		
		if rising_edge(clk) then
			if clear = '1' then
				D_out <= (others => '0');
			elsif load = '1' then
				D_out <= D_in;
			end if;
			
		end if;
	
	end process;
end architecture;