library IEEE;
use IEEE.std_logic_1164.all;

entity multiplexer is

	port(
		Regin:		 in std_logic_vector(159 downto 0);
		muxSel:		 in std_logic_vector(4   downto 0);
		dataBus:		out std_logic_vector(7   downto 0)
	);
	
end entity;

architecture behaReginior of multiplexer is
begin
	
	dataBus  <= Regin(7   downto   0) when muxSel = "00000" else -- V0
					Regin(15  downto   8) when muxSel = "00001" else -- V1
					Regin(23  downto  16) when muxSel = "00010" else -- V2
					Regin(31  downto  24) when muxSel = "00011" else -- V3
					Regin(39  downto  32) when muxSel = "00100" else -- V4
					Regin(47  downto  40) when muxSel = "00101" else -- V5
					Regin(55  downto  48) when muxSel = "00110" else -- V6
					Regin(63  downto  56) when muxSel = "00111" else -- V7
					Regin(71  downto  64) when muxSel = "01000" else -- V8
					Regin(79  downto  72) when muxSel = "01001" else -- V9
					Regin(87  downto  80) when muxSel = "01010" else -- VA
					Regin(95  downto  88) when muxSel = "01011" else -- VB
					Regin(103 downto  96) when muxSel = "01100" else -- VC
					Regin(111 downto 104) when muxSel = "01101" else -- VD
					Regin(119 downto 112) when muxSel = "01110" else -- VE
					Regin(127 downto 120) when muxSel = "01111" else -- VF *
					Regin(135 downto 128) when muxSel = "10001" else -- RG
					Regin(143 downto 136) when muxSel = "11111" else -- Instr
					Regin(151 downto 144) when muxSel = "10101" else -- Keys
					Regin(159 downto 152) when muxSel = "11011" else -- DT
					"00000000";

end architecture;