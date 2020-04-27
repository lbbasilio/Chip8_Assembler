library IEEE;
use IEEE.std_logic_1164.all;

entity controlModule is

	port(
		clk:			 in std_logic;
		run:			 in std_logic;
		resetn:		 in std_logic;
		count:		 in std_logic_vector(3 downto 0);
		
		data_in:		 in std_logic_vector(7 downto 0);
		data_out:	out std_logic_vector(7 downto 0);
		
		doneSP:		out std_logic;
		clearSP:		out std_logic;
		incr:			out std_logic;
		loadST:		out std_logic;
		doneMP:		out std_logic;
		loadMP:		out std_logic;
		loadI:		out std_logic;
		clearI:		out std_logic;
		clearIC:		out std_logic;
		M_wr:			out std_logic;
		
		M_in_mux:	out std_logic_vector(1 downto 0);
		M_addr_mux:	out std_logic;
		Imux:			out std_logic_vector(1 downto 0);
		MPmux:		out std_logic_vector(1 downto 0);
		
		dbgInstr:	out std_logic_vector(15 downto 0);
--		dbgG:			out std_logic_vector(7 downto 0);
		
		nnn:			out std_logic_vector(15 downto 0);
		V0:			out std_logic_vector(7  downto 0);
		
		-- Graphics Module
		clearCountX:	out std_logic;
		clearCountY:	out std_logic;
		loadX, loadY:	out std_logic;
		
		clearGPU:		out std_logic;
		
		loadSR, enSR:	out std_logic;
		BB_wr:	out std_logic;
		
		-- input
		keyComp:	in std_logic;
		keys:	 	in std_logic_vector(7 downto 0);
		
		-- timers
		ST_load:	out std_logic;
		DT_load:	out std_logic;
		DT_count: in std_logic_vector(7 downto 0)
	);

end controlModule;

architecture behavior of controlModule is
	
	component controlUnit is
	
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
			keyComp:	 in std_logic;
			keys:		 in std_logic_vector(7 downto 0);
			
			-- timers
			ST_load:	out std_logic;
			DT_load:	out std_logic
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
	
	component multiplexer is 
	
		port(
			Regin:		 in std_logic_vector(159 downto 0);
			muxSel:		 in std_logic_vector(4 downto 0);
			dataBus:		out std_logic_vector(7 downto 0)
		);
		
	end component;
	
	component ULA is
		
		port(
			op:			 in std_logic_vector(3 downto 0);
			Acc:			 in std_logic_vector(7 downto 0);
			dataBus:		 in std_logic_vector(7 downto 0);
			skip:			out std_logic;
			carry:		out std_logic;
			result:		out std_logic_vector(7 downto 0)
		);
		
	end component;
	
	component SevenSegDisplay is

		port(
			data:	 	 in std_logic_vector(3 downto 0);
			coded: 	out std_logic_vector(6 downto 0)
		);
		
	end component;
	
	signal instr0:		std_logic_vector(7   downto 0); 
	signal instr1: 	std_logic_vector(7   downto 0);
	signal fullinstr:	std_logic_vector(15 	downto 0);
	
	signal instrWr:	std_logic_vector(1   downto 0);
	signal dataBus:	std_logic_vector(7   downto 0);
	signal muxSel:		std_logic_vector(4   downto 0);
	
	signal muxIn:		std_logic_vector(159 downto 0);
	
	signal VFSel:		std_logic;
	signal VFin:		std_logic_vector(7 	downto 0);
	signal accData:	std_logic_vector(7   downto 0);
	
	-- 0 ~ 15 == V0 ~ VF
	-- 16 == Acc
	-- 17 == G reg
	signal regWr:		std_logic_vector(17  downto 0);
	signal clear:		std_logic;
	
	-- 127 downto  0  is VF ~ V0
	-- 135 downto 128 is G reg
	signal regData:	std_logic_vector(135 downto 0); 
	
	signal ULAop:		std_logic_vector(3   downto 0);
	signal result:		std_logic_vector(7   downto 0);
	signal ULAskip:	std_logic;
	signal ULAcarry:	std_logic;
	
	
	
begin

	gen_Reg: for i in 0 to 14 generate
		
		Registers: reg port map 
		(
			clk => clk, 
			load => regWr(i),
			clear => clear,
			D_in => dataBus,
			D_out => regData(8 * i + 7 downto 8 * i)
		);
		
	end generate;
	
	VFin <=	"0000000" & ULAcarry when VFSel = '1' else
				dataBus;	
	
	VF: reg port map (clk, regWr(15), clear, VFin, regData(127 downto 120));

	Acc: reg port map (clk, regWr(16), clear, dataBus, accData);
	RG:  reg port map (clk, regWr(17), clear, result, regData(135 downto 128));
	
	I0: reg port map (clk, instrWr(0), clear, data_in, instr0);
	I1: reg port map (clk, instrWr(1), clear, data_in, instr1);
	
	muxIn <= DT_count & keys & data_in & regData;
	mux: multiplexer port map (muxIn, muxSel, dataBus);
	
	arith: ULA port map (ULAop, accData, dataBus, ULAskip, ULAcarry, result);
	
	fullinstr <= instr0 & instr1;
	CPU: controlUnit port map(
		clk => clk,
		run => run,
		resetn => resetn,
		skip => ULAskip,
		instr => fullinstr,
			
		VFSel => VFSel,
		instrWr => instrWr,
		muxSel => muxSel,
		regWr => regWr,
		ULAop => ULAop,
		
		clear => clear,
	
		-- Memory Module
		count => count,
			
		doneMP => doneMP,
		doneSP => doneSP,
			
		loadST => loadST,
		loadMP => loadMP,
		loadI => loadI,
		ClearSP => ClearSP,
		ClearIC => ClearIC,
		incr => incr,
				
		MPmux => MPmux,
		Imux => Imux,
		M_in_mux => M_in_mux,
		M_addr_mux => M_addr_mux,
		M_wr => M_wr,
		
		-- Graphics Module
		clearCountX => clearCountX,
		clearCountY => clearCountY,
		loadX => loadX,
		loadY => loady,
		
		clearGPU => clearGPU,
		
		loadSR => loadSR, 
		enSR => enSR,
		BB_wr => BB_wr,
		
		keyComp => keyComp,
		keys => keys,
		ST_load => ST_load,
		DT_load => DT_load
	);
	
	data_out <= dataBus;
	V0 <= regData(7 downto 0);
	nnn <= "0000" & instr0(3 downto 0) & instr1;
	
	dbgInstr <= instr0 & instr1;
--	dbgG <= regData(135 downto 128);
	
	clearI <= clear;
	
end architecture;
		