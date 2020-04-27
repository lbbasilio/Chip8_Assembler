library IEEE;
use IEEE.std_logic_1164.all;

entity Chip8 is

	port(
		raw_clk:	 in std_logic;
		run:		 in std_logic;
		resetn:		 in std_logic;
		
		key_press:	 in std_logic_vector(15 downto 0);
		
		color:		 in std_logic_vector(2 downto 0);
		
		hsync:		out std_logic;
		vsync:		out std_logic;
		
		dbg0:		out std_logic_vector(6  downto 0);
		dbg1:		out std_logic_vector(6  downto 0);
		dbg2:		out std_logic_vector(6  downto 0);
		dbg3:		out std_logic_vector(6  downto 0);
		Instr:		out std_logic_vector(15 downto 0);
		
--		dbgBB:		out std_logic_vector(2047 downto 0);
		dbgBB_wr:	out std_logic;
		
		video_out:	out std_logic_vector(11 downto 0);
		
		ST_active:	out std_logic
	);
	
end entity;

architecture behavior of Chip8 is
		
	component SevenSegDisplay is

		port(
			data:	 in std_logic_vector(3 downto 0);
			coded: 	out std_logic_vector(6 downto 0)
		);
		
	end component;
	
	component timer is 
	
		generic(
			size: integer := 8
		);
		
		port(
			clk, load:	 in std_logic;
			Q_in:		 in std_logic_vector(size - 1 downto 0);
			is_active:	out std_logic;
			Q_out:		out std_logic_vector(size - 1 downto 0)
		);
		
	end component;
	
	component memoryModule is
	
		port(
			clk:	 in std_logic;
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
			

			data:	out std_logic_vector(7 downto 0);
			count:	out std_logic_vector(3 downto 0)
		);
		
	end component;
	
	component controlModule is
		
		port(
			clk:		 in std_logic;
			run:		 in std_logic;
			resetn:		 in std_logic;
			count:		 in std_logic_vector(3 downto 0);
			
			data_in:	 in std_logic_vector(7 downto 0);
			data_out:	out std_logic_vector(7 downto 0);
			
			doneSP:		out std_logic;
			clearSP:	out std_logic;
			incr:		out std_logic;
			loadST:		out std_logic;
			doneMP:		out std_logic;
			loadMP:		out std_logic;
			loadI:		out std_logic;
			clearI:		out std_logic;
			clearIC:	out std_logic;
			M_wr:		out std_logic;
			
			M_in_mux:	out std_logic_vector(1 downto 0);
			M_addr_mux:	out std_logic;
			Imux:		out std_logic_vector(1 downto 0);
			MPmux:		out std_logic_vector(1 downto 0);
			
			dbgInstr:	out std_logic_vector(15 downto 0);
--			dbgG:		out std_logic_vector(7 downto 0);
			
			nnn:		out std_logic_vector(15 downto 0);
			V0:			out std_logic_vector(7  downto 0);
			
			-- Graphics Module
			clearCountX:	out std_logic;
			clearCountY:	out std_logic;
			loadX, loadY:	out std_logic;
			
			clearGPU:		out std_logic;
			
			loadSR, enSR:	out std_logic;
			BB_wr:	out std_logic;
			
			-- input
			keyComp:	 in std_logic;
			keys:	 	 in std_logic_vector(7 downto 0);
			
			-- timers 
			ST_load:	out std_logic;
			DT_load:	out std_logic;
			DT_count: 	 in std_logic_vector(7 downto 0)
		);
		
	end component;
	
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
			
			hsync, vsync:	out std_logic;
			video_out:		out std_logic_vector(11 downto 0)
		);
		
	end component;
	
	-- dbg signal, deletar dps
	signal dbgBB: std_logic_vector(2047 downto 0);
	
	
	constant DF: integer := 16; -- Division factor for Graphics Module
	-- CPU clock will be 50M / (160 * DF)
	
	
	signal G_clk: std_logic := '1';
	signal C_clk: std_logic := '1';
	signal G_count: integer range 0 to DF - 1 := 0;
	signal C_count: integer range 0 to 15 := 0;
	
	-- memory signals
	signal clearI:		std_logic;
	signal loadST:		std_logic;
	signal loadMP: 	std_logic;
	signal loadI:		std_logic;
	signal doneMP:	   std_logic;
	signal doneSP:	   std_logic;
	signal clearSP:	std_logic;
	signal clearIC:	std_logic;
	signal incr:	 	std_logic;
	signal V0:		 	std_logic_vector(7  downto 0);
	signal VX:		 	std_logic_vector(7  downto 0);
	signal nnn:		 	std_logic_vector(15 downto 0);
			
	signal MPmux:	 	std_logic_vector(1 downto 0);
	signal Imux:		std_logic_vector(1 downto 0);
		
			

	signal M_in_mux: 		std_logic_vector(1 downto 0);
	signal M_addr_mux:	std_logic;
	signal M_wr:			std_logic;			
			
			
	signal mem_data:	std_logic_vector(7 downto 0);
	signal count:		std_logic_vector(3 downto 0);
	
	signal dbgInstr:	std_logic_vector(15 downto 0);
	signal BB_data:	std_logic_vector(2047 downto 0);
	
	-- Graphics signals
	signal clear:	std_logic;
	signal BB_wr:	std_logic;
	signal loadX:	std_logic;
	signal loadY:	std_logic;
	signal loadSR:	std_logic;
	signal enSR:	std_logic;
	
	signal clearCountX:	std_logic;
	signal clearCountY:	std_logic;

	signal dataBus:	std_logic_vector(7 downto 0);
	signal collision:	std_logic;
			

	-- Timers
	constant TimerFactor: integer := 833334; -- Division factor for 60 Hz 
	
	signal T_clk:	std_logic := '1';
	signal T_count:	integer range 0 to TimerFactor - 1 := 0;
	
	signal DT_count:	std_logic_vector(7 downto 0) := (others => '0');
	signal DT_load:	std_logic := '0';
	signal ST_load:	std_logic := '0';
	
	-- Keys
	signal key:	std_logic_vector(7 downto 0) := (others => '1');
	signal key_check:	std_logic := '0';
	
begin
	
	G_clk_process: process(raw_clk)
	begin
		
		if rising_edge(raw_clk) then
			if G_count = DF - 1 then
				G_count <= 0;
			else
				G_count <= G_count + 1;
			end if;
			
			if G_count < DF/2 then
				G_clk <= '1';
			else
				G_clk <= '0';
			end if;
		end if;
		
	end process;
	
	C_clk_process: process(G_clk)
	begin
		if rising_edge(G_clk) then
			if C_count = 15 then
				C_count <= 0;
			else
				C_count <= C_count + 1;
			end if;
			
			if C_count < 8 then
				C_clk <= '1';
			else
				C_clk <= '0';
			end if;
		end if;
	end process;
	
	MEM: memoryModule port map(
	
		clk => C_clk,
		clearI => clearI,
		loadST => loadST,
		loadMP => loadMP,
		loadI => loadI,
		doneMP => doneMP,
		doneSP => doneSP,
		clearSP => clearSP,
		clearIC => clearIC,
		incr => incr,
		V0 => V0,
		VX => VX,
		nnn => nnn,
		
		MPmux => MPmux,
		Imux => Imux,

		M_in_mux => M_in_mux,
		M_addr_mux => M_addr_mux,
		M_wr => M_wr,
			
		data => mem_data,
		count => count
		
	);
	
	GPU: graphicsModule port map(
		
		raw_clk => raw_clk,
		clk => G_clk,
		clear => clear,
		
		BB_wr => BB_wr,
		loadX => loadX, 
		loadY => loadY,
		loadSR => loadSR, 
		enSR => enSR,
		
		clearCountX => clearCountX,
		clearCountY => clearCountY,
		color => color,
		mem_data => mem_data,
		dataBus => dataBus,
		collision => collision,
		
		dbgBB => dbgBB,
			
		hsync => hsync,
		vsync => vsync,
		video_out => video_out
	
	);
	
	CPU: controlModule port map(
	
			clk => C_clk,
			run => run,
			resetn => resetn,
			
			count => count,
			
			data_in => mem_data,
			data_out => dataBus,
			
			doneSP => doneSP,
			clearSP => clearSP,
			incr => incr,
			loadST => loadST,
			doneMP => doneMP,
			loadMP => loadMP,
			loadI => loadI,
			clearI => clearI,
			clearIC => clearIC,
			M_wr => M_wr,
			
			M_in_mux => M_in_mux,
			M_addr_mux => M_addr_mux,
			Imux => Imux,
			MPmux => MPmux,
			
			nnn => nnn,
			V0 => V0,
			
			dbgInstr => dbgInstr,
			
			-- Graphics Module
			clearCountX => clearCountX,
			clearCountY => clearCountY,
			loadX => loadX,
			loadY => loadY,
			
			clearGPU => clear,
			
			loadSR => loadSR, 
			enSR => enSR,
			BB_wr => BB_wr,
			
			-- input
			keyComp => key_check,
			keys => key,
			
			-- timers
			DT_load => DT_load,
			ST_load => ST_load,
			DT_count => DT_count
	);
	
	-- Timers
	T_clk_process: process(raw_clk)
	begin
		
		if rising_edge(raw_clk) then
			if T_count = TimerFactor - 1 then
				T_count <= 0;
			else
				T_count <= T_count + 1;
			end if;
			
			if T_count < TimerFactor/2 then
				T_clk <= '1';
			else
				T_clk <= '0';
			end if;
		end if;
		
	end process;
		
	-- Delay Timer
	DT: timer port map(T_clk, DT_load, dataBus, open, DT_count);
	
	-- Sound Timer
	ST: timer port map(T_clk, DT_load, dataBus, ST_active, open);
	
	-- Key decoding
	key <=	X"0F" when key_press(15) = '1' else
				X"0E" when key_press(14) = '1' else
				X"0D" when key_press(13) = '1' else
				X"0C" when key_press(12) = '1' else
				X"0B" when key_press(11) = '1' else
				X"0A" when key_press(10) = '1' else
				X"09" when key_press(9)  = '1' else
				X"08" when key_press(8)  = '1' else
				X"07" when key_press(7)  = '1' else
				X"06" when key_press(6)  = '1' else
				X"05" when key_press(5)  = '1' else
				X"04" when key_press(4)  = '1' else
				X"03" when key_press(3)  = '1' else
				X"02" when key_press(2)  = '1' else
				X"01" when key_press(1)  = '1' else
				X"00" when key_press(0)  = '1' else
				(others => '1');
		
	key_check <= 	'1' when dataBus = X"0F" and key_press(15) = '1' else
						'1' when dataBus = X"0E" and key_press(14) = '1' else
						'1' when dataBus = X"0D" and key_press(13) = '1' else
						'1' when dataBus = X"0C" and key_press(12) = '1' else
						'1' when dataBus = X"0B" and key_press(11) = '1' else
						'1' when dataBus = X"0A" and key_press(10) = '1' else
						'1' when dataBus = X"09" and key_press(9)  = '1' else
						'1' when dataBus = X"08" and key_press(8)  = '1' else
						'1' when dataBus = X"07" and key_press(7)  = '1' else
						'1' when dataBus = X"06" and key_press(6)  = '1' else
						'1' when dataBus = X"05" and key_press(5)  = '1' else
						'1' when dataBus = X"04" and key_press(4)  = '1' else
						'1' when dataBus = X"03" and key_press(3)  = '1' else
						'1' when dataBus = X"02" and key_press(2)  = '1' else
						'1' when dataBus = X"01" and key_press(1)  = '1' else
						'1' when dataBus = X"00" and key_press(0)  = '1' else
						'0';
	
	D0: SevenSegDisplay port map(dbgInstr(15 downto 12), dbg0);
	D1: SevenSegDisplay port map(dbgInstr(11 downto  8), dbg1);
	D2: SevenSegDisplay port map(dbgInstr(7  downto  4), dbg2);
	D3: SevenSegDisplay port map(dbgInstr(3  downto  0), dbg3);
	
	Instr <= dbgInstr;
	dbgBB_wr <= BB_wr;
	
end architecture;

	
