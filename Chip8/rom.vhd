library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rom is 
	
	generic(
		addrSize:	integer := 4;
		dataSize:	integer := 9
	);
	
	port(
		clk:	 in std_logic;
		addr:	 in std_logic_vector(addrSize - 1 downto 0);
		data:	out std_logic_vector(dataSize - 1 downto 0) := (others => '0')
	);
	
end entity;

architecture remember of rom is

	type mem is array (0 to 2**addrSize - 1) of std_logic_vector(dataSize - 1 downto 0);
	
	signal info: mem;

begin 
	
	process(clk)
	begin
		
		if rising_edge(clk) then
			data <= info(to_integer(unsigned(addr)));
		end if;
		
	end process;

end architecture;