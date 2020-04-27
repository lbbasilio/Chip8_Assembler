library IEEE;
use IEEE.std_logic_1164.all;

entity shiftReg is

	generic(
		data_size: integer := 8
	);
	
	port(
		clk:	  in std_logic;
		load:	  in std_logic;
		shift:  in std_logic;
		P_in:	  in std_logic_vector(data_size - 1 downto 0);
		S_out: out std_logic
	);
	
end entity;

architecture shifting of shiftReg is
	
	signal data: std_logic_vector(data_size - 1 downto 0);
	
begin

	process(clk, load)
	begin
		
		if load = '1' then
			data <= P_in;
		elsif rising_edge(clk) then
			if shift = '1' then
				data(data_size - 1 downto 1) <= data(data_size - 2 downto 0);
				data(0) <= '0';
			end if;
		end if;
	
	end process;
	
	S_out <= data(data_size - 1);
	
end architecture;