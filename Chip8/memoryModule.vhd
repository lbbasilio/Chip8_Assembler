library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity memoryModule is

	port(
		clk:		 in std_logic;
		clearI:	 in std_logic;
		loadST:	 in std_logic;
		loadMP:	 in std_logic;
		loadI:	 in std_logic;
		doneMP:	 in std_logic;
		doneSP:	 in std_logic;
		clearSP: in std_logic;
		clearIC: in std_logic;
		incr:	 in std_logic;
		V0:		 in std_logic_vector(7  downto 0);
		VX:		 in std_logic_vector(7  downto 0);
		nnn:	 in std_logic_vector(15 downto 0);
		
		MPmux:	 in std_logic_vector(1 downto 0);
		Imux:	 in std_logic_vector(1 downto 0);
	
		

		M_in_mux: 	in std_logic_vector(1 downto 0);
		M_addr_mux: in std_logic;
		M_wr:		in std_logic;
		
		
		
		dbgSP:	 out std_logic_vector(3  downto 0);
		dbgST:	 out std_logic_vector(15 downto 0);
		dbgMP:	 out std_logic_vector(15 downto 0);
		dbgI:	 out std_logic_vector(15 downto 0);
		dbgM_in: out std_logic_vector(7  downto 0);
		dbgM_ad: out std_logic_vector(15 downto 0);
				
		
		
		
		data:	out std_logic_vector(7 downto 0);
		count:	out std_logic_vector(3 downto 0)
	);
	
end entity;

architecture behavior of memoryModule is
			
	component counter is

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
		
	end component;

	component memory is 

		generic(
			addr_size:	integer := 12;
			data_size:	integer := 8;
			img_source:	string := "output"
		);
		
		port(
			clk:		 	 in std_logic;
			wr_en:	 	 in std_logic;
			addr:		 	 in std_logic_vector(addr_size - 1 downto 0);
			data_in:	 	 in std_logic_vector(data_size - 1 downto 0);
			data_out:	out std_logic_vector(data_size - 1 downto 0)
		);
		
	end component;

	component reg is
	
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
		
	end component;
	
	component BCD is
	
		port(	
			bin:	 in std_logic_vector(7 downto 0);
			dec2:	out std_logic_vector(3 downto 0);
			dec1:	out std_logic_vector(3 downto 0);
			dec0:	out std_logic_vector(3 downto 0)
		);
		
	end component;
	
	component hexLocator is
	
		port(
			hex:	 		 in std_logic_vector(7 downto 0);
			location:	out std_logic_vector(15 downto 0)
		);
		
	end component;
	
	signal Mem_clk:	std_logic;
	
	signal MP_out, MP_in: std_logic_vector(15 downto 0);
	signal MP_in_sub: 	 std_logic_vector(15 downto 0);
	signal MP_add: 		 std_logic_vector(15 downto 0);
	
	signal ST_out:	 std_logic_vector(15 downto 0);
	signal ST_add:	 std_logic_vector(15 downto 0);
	signal ST_addr: std_logic_vector(3  downto 0);
	
	signal I_out, I_in:	std_logic_vector(15 downto 0);
	signal I_add, I_hex:	std_logic_vector(15 downto 0);
	
	signal IC_add:			std_logic_vector(15 downto 0);
	signal IC_count:		std_logic_vector(3  downto 0);
	
	signal Mem_addr:	std_logic_vector(15 downto 0);
	signal Mem_in:		std_logic_vector(7  downto 0);
	signal Mem_out:	std_logic_vector(7  downto 0);
	
	signal Dec2, Dec1, Dec0: std_logic_vector(3 downto 0);

begin

	-- Stack (ST)
	StackPointer: counter port map (clk, '0', incr, doneSP, clearSP, (others => '0'), ST_addr);
	Stack: memory generic map (4, 16, "empty") port map (clk, loadST, ST_addr, MP_out, ST_out);
	
	ST_add <= std_logic_vector(unsigned(ST_out) + X"0001");
	
	-- Memory Pointer (MP)
	
	MemoryPointer: counter generic map (16) port map (clk, loadMP, '1', doneMP, '0', MP_in_sub, MP_out);
	
	MP_in <=	ST_add  when MPmux = "00" else
				MP_add  when MPmux = "01" else
				nnn	  when MPmux = "10" else
				X"0000"; -- Memory starts at 0x0200
	
	MP_in_sub <= std_logic_vector(unsigned(MP_in) - X"0001");
	
	MP_add <= std_logic_vector(unsigned(V0) + unsigned(nnn));
	
	
	
	-- I register
	
	I: reg generic map (16) port map (clk, loadI, clearI, I_in, I_out);
	hex: hexLocator port map (VX, I_hex);
	
	I_in <=  I_add when Imux = "00" else
				I_hex when Imux = "01" else
				nnn	when Imux = "10" else
				(others => '0');
				
	I_add <= std_logic_vector(unsigned(VX) + unsigned(I_out));
	
	
	
	-- I counter
	
	IC: counter port map (clk, '0', '1', '1', clearIC, (others => '0'), IC_count);
	
	IC_add <= std_logic_vector(unsigned(I_out) + unsigned(IC_count));
	
	
	
	-- Program Memory
	Mem_clk <= not clk;
	Mem: memory port map (Mem_clk, M_wr, Mem_addr(11 downto 0), Mem_in, Mem_out);
	
	decimals: BCD port map (VX, Dec2, Dec1, Dec0);
	
	Mem_addr <= MP_out when M_addr_mux = '0' else 
					IC_add when M_addr_mux = '1';
					

	Mem_in	<=	"0000" & Dec2 when M_in_mux = "11" else
					"0000" & Dec1 when M_in_mux = "10" else
					"0000" & Dec0 when M_in_mux = "01" else
					VX	  			  when M_in_mux = "00";
	
	data <= Mem_out;
	count <= IC_count;
	
	
	dbgSP <= ST_addr;
	dbgST <= ST_out;
	dbgMP <= MP_out;
	dbgI <= I_out;
	dbgM_in <= Mem_in;
	dbgM_ad <= Mem_addr;
	
end architecture;
		