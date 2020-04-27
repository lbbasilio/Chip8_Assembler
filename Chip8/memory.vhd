library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use IEEE.numeric_std.all;

entity memory is 

	generic(
		addr_size:	integer := 12;
		data_size:	integer := 8;
		img_source:	string := "output"
	);
	
	port(
		clk:		 in std_logic;
		wr_en:	 	 in std_logic;
		addr:		 in std_logic_vector(addr_size - 1 downto 0);
		data_in:	 in std_logic_vector(data_size - 1 downto 0);
		data_out:	out std_logic_vector(data_size - 1 downto 0)
	);
	
end entity;

architecture remain of memory is
	
	type mem_type is array(0 to 2**addr_size - 1) of std_logic_vector(data_size - 1 downto 0);
	
	function my_ram_init(fileName : string) return mem_type is
		
		file fileHandle		: text open READ_MODE is fileName;
		variable currentLine	: line;
		variable tempWord		: std_logic_vector(data_size - 1 downto 0);
		variable result		: mem_type	:= (others => (others => '0'));
		
	begin

		for i in 0 to 4095 loop
		
			exit when endfile(fileHandle);
			
			readline(fileHandle, currentLine);
			hread(currentLine, tempWord);
			result(i) := tempWord; 
			
		end loop;
		
		return result;
		
	end function;
	
	-- QUARTUS MIF FILE
	signal mem_data: mem_type; -- := (others => (others => '0'));
	attribute ram_init_file : string;
	attribute ram_init_file of mem_data : signal is (img_source & ".mif");
	
	-- GENERIC HEX FILE
--	signal mem_data	:	mem_type := my_ram_init(img_source & ".hex");
	
begin

	process(clk)
	begin
	
		if rising_edge(clk) then
			if wr_en = '1' then
				mem_data(to_integer(unsigned(addr))) <= data_in;
			else
				data_out <= mem_data(to_integer(unsigned(addr)));
			end if;
		end if;
	
	end process;

end architecture;	