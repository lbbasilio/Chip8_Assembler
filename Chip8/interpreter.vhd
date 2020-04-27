library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity interpreter is

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
		keyComp: in std_logic;
		keys:		in std_logic_vector(7 downto 0);
		
		-- timers
		ST_load:	out std_logic;
		DT_load:	out std_logic
	);
	
end entity;

architecture do of interpreter is

	type state_name is (
		
		RESET,
		FETCH0, FETCH1, DECODE, ALIGN,
		IDLE0, IDLE1, IDLE2, IDLE3, IDLE4,
		LD, LDR, 
		SE0, SE1, SE2,
		SNE0, SNE1, SNE2,
		SER0, SER1, SER2,
		SNER0, SNER1, SNER2,
		ADD0, ADD1, ADD2,
		OR0, OR1, OR2,
		AND0, AND1, AND2,
		XOR0, XOR1, XOR2,
		ADDR0, ADDR1, ADDR2, ADDR3,
		SUBR0, SUBR1, SUBR2, SUBR3,
		SHR0, SHR1, SHR2, SHR3,
		SHL0, SHL1, SHL2, SHL3,
		SUBNR0, SUBNR1, SUBNR2, SUBNR3,
		
		
		JP,
		RET0, RET1,
		CALL0, CALL1, CALL2,
		LDADDR,
		JPV0,
		ADDI,
		LDLOC,
		LDBCD0, LDBCD1, LDBCD2, LDBCD3,
		
		LDMR0, LDMR1,
		
		LDRM0, LDRM1,
		
		DRW0, DRW1, DRW2,
		
		SKP0, SKP1, SKP2,
		SKPN0, SKPN1, SKPN2,
		
		LDRDT, LDDTR, LDST, LDK0, LDK1, CLS
	);
		
	-- Most operations should run through 10 states, including 2 FETCHs, DECODE and ALIGN
	-- This happens so the execution time of each instruction is equal
	-- Exceptions are: LDMR/LDRM (initializing instructions), DRW and LDK
	
	signal state:	state_name := FETCH0;
	signal regX:	std_logic_vector(4 downto 0);
	signal regY:	std_logic_vector(4 downto 0);
	
begin
	
	process(clk, resetn)
	begin
		
		if resetn = '0' then 
			state <= RESET;
		
		elsif rising_edge(clk) then
			case state is
				
				when RESET => state <= ALIGN;
			
				when FETCH0 =>
					if run = '1' then
						state <= FETCH1;
					else 
						state <= FETCH0;
					end if;
				
				when FETCH1 => state <= DECODE;
				
				when IDLE0 => state <= IDLE1;
				when IDLE1 => state <= IDLE2;
				when IDLE2 => state <= IDLE3;
				when IDLE3 => state <= IDLE4;
				when IDLE4 => state <= ALIGN;
				when ALIGN => state <= FETCH0;
				
				when DECODE =>
					if begOp = "0110" then state <= LD;
					elsif begOp = "0011" then state <= SE0;
					elsif begOp = "0100" then state <= SNE0;
					elsif begOp = "1000" and endOp = "0000" then state <= LDR;
					elsif begOp = "0101" and endOp = "0000" then state <= SER0;
					elsif begOp = "1001" and endOp = "0000" then state <= SNER0;
					elsif begOp = "0111" then state <= ADD0;
					elsif begOp = "1000" and endOp = "0001" then state <= OR0;
					elsif begOp = "1000" and endOp = "0010" then state <= AND0;
					elsif begOp = "1000" and endOp = "0011" then state <= XOR0;
					elsif begOp = "1000" and endOp = "0100" then state <= ADDR0;
					elsif begOp = "1000" and endOp = "0101" then state <= SUBR0;
					elsif begOp = "1000" and endOp = "0110" then state <= SHR0;
					elsif begOp = "1000" and endOp = "1110" then state <= SHL0;
					elsif begOp = "1000" and endOp = "0111" then state <= SUBNR0;
					elsif begOp = "0001" then state <= JP;
					elsif begOp & RX & RY & endOp = X"00EE" then state <= RET0;
					elsif begOp = "0010" then state <= CALL0;
					elsif begOp = "1010" then state <= LDADDR;
					elsif begOp = "1011" then state <= JPV0;
					elsif begOp = "1111" and RY & endOp = X"1E" then state <= ADDI;
					elsif begOp = "1111" and RY & endOp = X"29" then state <= LDLOC;
					elsif begOp = "1111" and RY & endOp = X"33" then state <= LDBCD0;
					elsif begOp = "1111" and RY & endOp = X"55" then state <= LDMR0;
					elsif begOp = "1111" and RY & endOp = X"65" then state <= LDRM0;
					elsif begOp = "1101" then state <= DRW0;
					elsif begOp = "1110" and RY & endOp = X"9E" then state <= SKP0;
					elsif begOp = "1110" and RY & endOp = X"A1" then state <= SKPN0;
					elsif begOp = "1111" and RY & endOp = X"07" then state <= LDRDT;
					elsif begOp = "1111" and RY & endOp = X"15" then state <= LDDTR;
					elsif begOp = "1111" and RY & endOp = X"18" then state <= LDST;
					elsif begOp = "1111" and RY & endOp = X"0A" then state <= LDK0;
					elsif begOp & RX & RY & endOp = X"00E0" then state <= CLS;
					else 
						state <= DECODE; -- Invalid opcode throws sm into closed loop
					end if;
				
				when LDR => state <= IDLE0;		
				when LD  => state <= IDLE0;
				
				when SE0 => state <= SE1;
				when SE1 => state <= SE2;
				when SE2 => state <= IDLE2;
				
				when SNE0 => state <= SNE1;
				when SNE1 => state <= SNE2;
				when SNE2 => state <= IDLE2;
				
				when SER0 => state <= SER1;
				when SER1 => state <= SER2;
				when SER2 => state <= IDLE2;
				
				when SNER0 => state <= SNER1;
				when SNER1 => state <= SNER2;
				when SNER2 => state <= IDLE2;
				
				when ADD0 => state <= ADD1;
				when ADD1 => state <= ADD2;
				when ADD2 => state <= IDLE2;
				
				when OR0 => state <= OR1;
				when OR1 => state <= OR2;
				when OR2 => state <= IDLE2;
				
				when AND0 => state <= AND1;
				when AND1 => state <= AND2;
				when AND2 => state <= IDLE2;
				
				when XOR0 => state <= XOR1;
				when XOR1 => state <= XOR2;
				when XOR2 => state <= IDLE2;
				
				when ADDR0 => state <= ADDR1;
				when ADDR1 => state <= ADDR2;
				when ADDR2 => state <= ADDR3;
				when ADDR3 => state <= IDLE3;
				
				when SUBR0 => state <= SUBR1;
				when SUBR1 => state <= SUBR2;
				when SUBR2 => state <= SUBR3;
				when SUBR3 => state <= IDLE3;
				
				when SHR0 => state <= SHR1;
				when SHR1 => state <= SHR2;
				when SHR2 => state <= SHR3;
				when SHR3 => state <= IDLE3;
				
				when SHL0 => state <= SHL1;
				when SHL1 => state <= SHL2;
				when SHL2 => state <= SHL3;
				when SHL3 => state <= IDLE3;
				
				when SUBNR0 => state <= SUBNR1;
				when SUBNR1 => state <= SUBNR2;
				when SUBNR2 => state <= SUBNR3;
				when SUBNR3 => state <= IDLE3;
				
				when JP => state <= IDLE0;
				
				when RET0 => state <= RET1;
				when RET1 => state <= IDLE1;
				
				when CALL0 => state <= CALL1;
				when CALL1 => state <= CALL2;
				when CALL2 => state <= IDLE2;
				
				when LDADDR => state <= IDLE0;
				
				when JPV0 => state <= IDLE0;
				
				when ADDI => state <= IDLE0;
				
				when LDLOC => state <= IDLE0;
				
				when LDBCD0 => state <= LDBCD1;
				when LDBCD1 => state <= LDBCD2;
				when LDBCD2 => state <= LDBCD3;
				when LDBCD3 => state <= IDLE3;
				
				when LDMR0 => state <= LDMR1;
				when LDMR1 => 
					if count < RX then
						state <= LDMR1;
					else
						state <= ALIGN;
					end if;
				
				when LDRM0 => state <= LDRM1;
				when LDRM1 => 
					if count < RX then
						state <= LDRM1;
					else
						state <= ALIGN;
					end if;
					
				when DRW0 => state <= DRW1;
				when DRW1 => state <= DRW2;
				when DRW2 =>
					if count < endOp then
						state <= DRW2;
					else
						state <= ALIGN;
					end if;
					
				when SKP0 =>
					if keyComp = '1' then
						state <= SKP1;
					else
						state <= IDLE0;
					end if;
					
				when SKP1 => state <= SKP2;
				when SKP2 => state <= IDLE2;
				
				when SKPN0 =>
					if keyComp = '0' then
						state <= SKPN1;
					else
						state <= IDLE0;
					end if;
					
				when SKPN1 => state <= SKPN2;
				when SKPN2 => state <= IDLE2;
				
				when LDRDT => state <= IDLE0;
				when LDDTR => state <= IDLE0;
				when LDST  => state <= IDLE0;
				
				when LDK0 =>
					if keys(7 downto 4) = "0000" then
						state <= LDK1;
					else
						state <= LDK0;
					end if;
				
				when LDK1 => state <= ALIGN; 
				
				when CLS => state <= IDLE0;
				
			end case;
		end if;
	end process;
	
	regX <= '0' & RX;
	regY <= '0' & RY;	
	
	with state select instrWr <=
		"01" when FETCH0,
		"10" when FETCH1,
		"00" when others;
		
		
	with state select regWr <=
		regX when LD | LDR | ADD2 | OR2 | AND2 | XOR2 | ADDR3 | SUBR3 | SHR3 | SHL3 | SUBNR3 | LDRDT | LDK1,
		"10000" when SE0 | SNE0 | SER0 | SNER0 | ADD0 | OR0 | AND0 | XOR0 | ADDR0 | SUBR0 | SHR0 | SHL0 | SUBNR0, -- Accumulator
		"10001" when ADD1 | OR1 | AND1 | XOR1 | ADDR2 | SUBR2 | SHR2 | SHL2 | SUBNR2, -- Result
		"01111" when ADDR1 | SUBR1 | SHR1 | SHL1 | SUBNR1, -- Flag register
		'0' & count	when LDRM1,
		(others => '1') when others;
	
	
	with state select muxSel <=
		"11111" 	when LD  | SE0 | SNE0 | ADD1,	-- Instr
		regX 		when SE1 | SE2 | SNE1 | SNE2  | SER0 | SNER0 | ADD0 | OR0 | AND0 | XOR0 | ADDR0 | SUBR0 | SHR0 | SHL0 | SUBNR1 | SUBNR2 | ADDI | LDLOC | LDBCD1 | LDBCD2 | LDBCD3 | DRW0 | SKP0 | SKPN0 | LDDTR | LDST, 
		regY		when LDR | SER1 | SER2 | SNER1 | SNER2 | OR1 | AND1 | XOR1 | ADDR1 | ADDR2 | SUBR1 | SUBR2 | SUBNR0 | DRW1,									
		"10001" 	when ADD2 | OR2 | AND2 | XOR2 | ADDR3 | SUBR3 | SHR3 | SHL3 | SUBNR3, -- Result 
		'0' & count when LDMR1,
		"11111" 	when LDRM1,
		"10101" 	when LDRDT,
		"11011" 	when LDK1,
		"11111" 	when others;
	
	
	with state select doneMP <=
		'1'  when RESET | ALIGN | FETCH0 | JP | RET0 | CALL2 | JPV0,
		skip when SE1 | SE2 | SNE1 | SNE2 | SER1 | SER2 | SNER1 | SNER2,
		'0'  when others;
	
	
	with state select ULAop <=
		"0000" when SE1  | SE2  | SER1  | SER2,
		"0001" when SNE1 | SNE2 | SNER1 | SNER2,
		"0010" when ADD1 | ADDR1 | ADDR2,
		"0011" when SUBR1 | SUBR2 | SUBNR1 | SUBNR2,
		"0100" when OR1,
		"0101" when AND1,
		"0110" when XOR1,
		"1000" when SHR1 | SHR2,
		"1001" when SHL1 | SHL2,
		(others => '1') when others;
		
	with state select VFSel <=
		'1' when ADDR1 | SUBR1 | SHR1 | SHL1 | SUBNR1,
		'0' when others;
		
	with state select MPmux <=
		"11" when RESET,
		"01" when JPV0,
		"10" when JP | CALL2,
		"00" when RET0,
		"00" when others;
	
	with state select loadMP <=
		'1' when JP | RET0 | CALL2 | JPV0 | RESET,
		'0' when others;
		
	with state select incr <= 
		'0' when RET1,
		'1' when CALL0,
		'1' when others;
	
	with state select doneSP <=
		'1' when RET1 | CALL0,
		'0' when others;
		
	with state select loadST <=
		'1' when CALL1,
		'0' when others;
		
	with state select Imux <=
		"10" when LDADDR,
		"01" when LDLOC,
		"00" when ADDI,
		"00" when others;
		
	with state select loadI <=
		'1' when LDADDR | ADDI | LDLOC,
		'0' when others;
		
	with state select M_in_mux <=
		"01" when LDBCD3,	
		"10" when LDBCD2,
		"11" when LDBCD1,
		"00" when others;
			
	with state select M_wr <=
		'1' when LDBCD1 | LDBCD2 | LDBCD3 | LDMR1,
		'0' when others;
	
	with state select M_addr_mux <= 
		'1' when LDBCD1 | LDBCD2 | LDBCD3,
		'1' when LDMR1,
		'1' when LDRM1,
		'1' when DRW1 | DRW2,
		'0' when others;
	
	with state select clearIC <=
		'1' when LDBCD0 | LDMR0 | LDRM0 | DRW1 | RESET,
		'0' when others;
	
	with state select clearSP <=
		'1' when RESET,
		'0' when others;
		
	with state select clear <=
		'1' when RESET,
		'0' when others;
		
	with state select clearCountX <=
		'1' when DRW1,
		'0' when others;
		
	with state select clearCountY <=
		'1' when DRW1,
		'0' when others;
		
	with state select loadX <=
		'1' when DRW0,
		'0' when others;
		
	with state select loadY <=
		'1' when DRW1,
		'0' when others;
		
	with state select loadSR <=
		clk when DRW2,
		'0' when others;
		
	with state select enSR <=
		'1' when DRW2,
		'0' when others;
	
	with state select BB_wr <=
		(not clk) when DRW2,
		'0' when others;
		
	with state select DT_load <=
		'1' when LDDTR,
		'0' when others;
		
	with state select ST_load <=
		'1' when LDST,
		'0' when others;
		
	with state select clearGPU <=
		'1' when CLS | RESET,
		'0' when others;
		
end architecture;
					