library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter is

	generic(
		size:	integer := 4
	);
	
	port(
		clk:		 in std_logic;
		load:		 in std_logic;
		up:		 in std_logic;
		enable:	 in std_logic;
		clear:	 in std_logic;
		Q_in:		 in std_logic_vector(size - 1 downto 0);
		Q_out:	out std_logic_vector(size - 1 downto 0)
	);
	
end entity;

architecture counting of counter is

	signal count: integer range 0 to 2**size - 1 := 0;
	
begin

	process(clk)
	begin
		
		if rising_edge(clk) and enable = '1' then
			
			if clear = '1' then 
				count <= 0;
			
			elsif load = '1' then
				count <= to_integer(unsigned(Q_in));
			
			-- count up
			elsif up = '1' then
				if count = 2**size - 1 then
					count <= 0;
				else count <= count + 1;
				end if;
			
			-- count down
			else
				if count = 0 then 
					count <= 2**size - 1;
				else
					count <= count - 1;
				end if;
			
			end if;
		
		end if;
		
	end process;
	
	Q_out <= std_logic_vector(to_unsigned(count, Q_out'length));
	
end architecture;