library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vram is
	
	port(
		clk, clear:	 in std_logic;
		load:			 in std_logic;
		write_en:	 in std_logic;
		wr_addr:	 	 in std_logic_vector(10 downto 0);
		rd_addr:		 in std_logic_vector(10 downto 0);
		Serial_in:	 in std_logic;
		Parallel_in: in std_logic_vector(2047 downto 0);
		Serial_out:		out std_logic;
		Parallel_out:	out std_logic_vector(2047 downto 0)
	);
	
end vram;

architecture behavior of vram is

	signal data: std_logic_vector(2047 downto 0) := (others => '0');

begin
	process(clk, clear)
	begin
		if clear = '1' then
			data <= (others => '0');
		elsif falling_edge(clk) then
			if load = '1' then
				data <= Parallel_in;
			elsif write_en = '1' then
				data(to_integer(unsigned(wr_addr))) <= Serial_in;
			end if;
		end if;
	end process;

	Parallel_out <= data;
	Serial_out <= data(to_integer(unsigned(rd_addr)));

end behavior;
