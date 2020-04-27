library ieee;
use ieee.std_logic_1164.all;

entity graph_tb is
end entity;

architecture behavior of graph_tb is

	component graphicsModule is
	port(
		raw_clk, clk:	 in std_logic;
		clear:			 in std_logic;
		BB_wr:			 in std_logic;
		loadX, loadY:	 in std_logic;
		loadSR, enSR:	 in std_logic;
		clearCountX:	 in std_logic;
		clearCountY:	 in std_logic;
		color:			 in std_logic_vector(2 downto 0);
		mem_data:		 in std_logic_vector(7 downto 0);
		dataBus:		 in std_logic_vector(7 downto 0);
		collision:		out std_logic;
		
		dbgBB:			out std_logic_vector(2047 downto 0);
		dbgFB:			out std_logic_vector(2047 downto 0);
		dbgFB_out:		out std_logic;
		dbgBB_addr:		out std_logic_vector(10 downto 0);
		
		hsync, vsync:	out std_logic;
		video_out:		out std_logic_vector(11 downto 0)
	);
	end component;
	
	signal raw_clk, clk: std_logic := '0';
	signal clear: std_logic := '1';
	signal BB_wr, loadX, loadY: std_logic := '0';
	signal loadSR, enSR: std_logic := '0';
	signal clearCountX, clearCountY: std_logic := '0';
	
	signal color: std_logic_vector(2 downto 0) := (others => '1');
	signal mem_data, dataBus: std_logic_vector(7 downto 0) := (others => '0');
	
	signal collision: std_logic := '0';
	
	signal dbgBB, dbgFB: std_logic_vector(2047 downto 0) := (others => '0');
	signal dbgFB_out: std_logic := '0';
	signal dbgBB_addr: std_logic_vector(10 downto 0);
	
	signal hsync, vsync: std_logic := '0';
	signal video_out: std_logic_vector(11 downto 0) := (others => '0');
	
	signal cpu_clk: std_logic := '0';
	
begin

	UUT: graphicsModule port map(
		raw_clk, clk, clear, BB_wr, loadX, loadY, loadSR, enSR,
		clearCountX, clearCountY, color, mem_data, dataBus, collision,
		dbgBB, dbgFB, dbgFB_out, dbgBB_addr, hsync, vsync, video_out
	);
	
	mem_data <= x"FF";
	dataBus <= x"00";
	
	-- Clocks
	raw_clk_process: process
	begin
		wait for 1 ns;
		raw_clk <= not raw_clk;
	end process;
	
	clk_process: process
	begin
		wait for 4 ns;
		clk <= not clk;
	end process;
	
	cpu_clk_process: process
	begin
		wait for 64 ns;
		cpu_clk <= not clk;
	end process;
	
	--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--
	
	process
	begin
		wait for 10 ns;
		clear <= '0';
	end process;
	
	process
	begin
		
		wait for 128 ns; -- DRW0
		loadX <= '1';
		
		wait for 128 ns; -- DRW1
		loadX <= '0';
		loadY <= '1';
		clearCountX <= '1';
		clearCountY <= '1';
		
		wait for 128 ns; -- DRW2
		loadY <= '0';
		clearCountX <= '0';
		clearCountY <= '0';
		
		loadSR <= '1';
		BB_wr <= '0';
		enSR <= '1';
		
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		wait for 64 ns;
		loadSR <= not loadSR;
		BB_wr <= not BB_wr;
		
		wait for 100 ms;
	
	end process;
	
	

end architecture;
	
		
		
		
		
	
	
										 