library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity timer is 
	
	generic(
		size: integer := 8
	);
	
	port(
		clk, load:	 in std_logic;
		Q_in:			 in std_logic_vector(size - 1 downto 0);
		is_active:	out std_logic;
		Q_out:		out std_logic_vector(size - 1 downto 0)
	);
	
end entity;

architecture countdown of timer is
	
	signal count:	integer range 0 to 2**(size) - 1 := 0;
	
begin
	
	process(clk, load)
	begin
		
		if load = '1' then
			count <= to_integer(unsigned(Q_in));
		elsif rising_edge(clk) then
			if count > 0 then
				count <= count - 1;
				is_active <= '1';
			else is_active <= '0';
			end if;
		end if;
	
	end process;
	
	Q_out <= std_logic_vector(to_unsigned(count, Q_out'length));
	
end architecture;
