library IEEE;
use IEEE.std_logic_1164.all;

entity controlUnit is
	
	port(
		clk:		 in std_logic;
		run:		 in std_logic;
		resetn:	 in std_logic;
		skip:		 in std_logic;
		instr:	 in std_logic_vector(15 downto 0);
		
		VFSel:	out std_logic;
		instrWr:	out std_logic_vector(1  downto 0);
		muxSel:	out std_logic_vector(4  downto 0);
		regWr:	out std_logic_vector(17 downto 0);
		ULAop:	out std_logic_vector(3  downto 0);
		
		clear:	out std_logic;
		
		-- Memory Module
		count:	 in std_logic_vector(3 downto 0);
		
		doneMP:	out std_logic;
		doneSP:	out std_logic;
			
		loadST:	out std_logic;
		loadMP:	out std_logic;
		loadI:	out std_logic;
		ClearSP:	out std_logic;
		ClearIC:	out std_logic;
		incr:		out std_logic;
					
		MPmux:	 	out std_logic_vector(1 downto 0);
		Imux:		 	out std_logic_vector(1 downto 0);
		M_in_mux: 	out std_logic_vector(1 downto 0);
		M_addr_mux: out std_logic;
		M_wr:			out std_logic;
		
		-- Graphics Module
		clearCountX:	out std_logic;
		clearCountY:	out std_logic;
		loadX, loadY:	out std_logic;
		
		clearGPU:		out std_logic;
		
		loadSR, enSR:	out std_logic;
		BB_wr:	out std_logic;
		
		-- input
		keyComp: in std_logic;
		keys:		in std_logic_vector(7 downto 0);
		
		-- timers
		ST_load:	out std_logic;
		DT_load:	out std_logic
	);
	
end entity;

architecture control of controlUnit is
	
	component interpreter is

		port(
			clk:		 in std_logic;
			resetn:	 in std_logic;
			run:		 in std_logic;
			
			begOp:	 in std_logic_vector(3  downto 0); -- Beginning of opcode
			RX,RY:	 in std_logic_vector(3  downto 0); -- Middle of opcode
			endOp:	 in std_logic_vector(3  downto 0); -- End of opcode
			
			-- Control Module
			skip:		 in std_logic;
			
			instrWr:	out std_logic_vector(1 downto 0);
			regWr:	out std_logic_vector(4 downto 0);
			ULAop:	out std_logic_vector(3 downto 0);
			muxSel:	out std_logic_vector(4 downto 0);
			VFSel:	out std_logic;
			clear:	out std_logic;
			
			-- Memory Module
			count:	 in std_logic_vector(3 downto 0);
			
			doneMP:	out std_logic;
			doneSP:	out std_logic;
			
			loadST:	out std_logic;
			loadMP:	out std_logic;
			loadI:	out std_logic;
			clearSP:	out std_logic;
			clearIC:	out std_logic;
			incr:		out std_logic;
			
			MPmux:	 	out std_logic_vector(1 downto 0);
			Imux:		 	out std_logic_vector(1 downto 0);
			M_in_mux: 	out std_logic_vector(1 downto 0);
			M_addr_mux: out std_logic;
			M_wr:			out std_logic;
			
			-- Graphics Module
			clearCountX:	out std_logic;
			clearCountY:	out std_logic;
			loadX, loadY:	out std_logic;
			
			clearGPU:		out std_logic;
			
			loadSR, enSR:	out std_logic;
			BB_wr:	out std_logic;
			
			-- input
			keyComp:	 in std_logic;
			keys:		 in std_logic_vector(7 downto 0);
			
			-- timers
			ST_load:	out std_logic;
			DT_load:	out std_logic
		);
		
	end component;
		
	signal regCoded: 	std_logic_vector(4  downto 0);
	
begin

	CPU: interpreter port map 
	(
		clk => clk, 
		resetn => resetn, 
		run => run, 
		begOp => instr(15 downto 12), 
		RX => instr(11 downto 8),
		RY => instr(7  downto  4), 
		endOp => instr(3  downto 0),
		
		-- Control Module
		skip => skip,
		
		instrWr => instrWr, 
		regWr => regCoded,
		ULAop => ULAop, 
		muxSel => muxSel, 
		VFSel => VFSel, 
		clear => clear,
		
		count => count,
		
		doneMP => doneMP,
		doneSP => doneSP,
		loadST => loadST,
		loadMP => loadMP,
		loadI	 => loadI,
		
		ClearSP => ClearSP,
		ClearIC => ClearIC,
		incr => incr,
		
		MPmux => MPmux,
		Imux  => Imux,
		M_in_mux	=> M_in_mux,
		M_addr_mux => M_addr_mux,
		M_wr => M_wr,
		
		-- Graphics Module
		clearCountX => clearCountX,
		clearCountY => clearCountY,
		loadX => loadX,
		loadY => loadY,
		
		clearGPU => clearGPU,
		
		loadSR => loadSR, 
		enSR => enSR,
		BB_wr => BB_wr,
		
		keyComp => keyComp,
		keys => keys,
		
		ST_load => ST_load,
		DT_load => DT_load
	);
	
	-- Decode 
	with regCoded select regWr <=	   "000000000000000001" when "00000", -- V0
												"000000000000000010" when "00001", -- V1
												"000000000000000100" when "00010", -- V2
												"000000000000001000" when "00011", -- V3
												"000000000000010000" when "00100", -- V4
												"000000000000100000" when "00101", -- V5
												"000000000001000000" when "00110", -- V6
												"000000000010000000" when "00111", -- V7
												"000000000100000000" when "01000", -- V8
												"000000001000000000" when "01001", -- V9
												"000000010000000000" when "01010", -- VA
												"000000100000000000" when "01011", -- VB
												"000001000000000000" when "01100", -- VC
												"000010000000000000" when "01101", -- VD
												"000100000000000000" when "01110", -- VE
												"001000000000000000" when "01111", -- VF *
												"010000000000000000" when "10000", -- Acc
												"100000000000000000" when "10001", -- RG
												"000000000000000000" when others;
				
												
end architecture;
	