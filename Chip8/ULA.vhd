library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ULA is

	port(
		op:			 in std_logic_vector(3 downto 0);
		Acc:			 in std_logic_vector(7 downto 0);
		dataBus:		 in std_logic_vector(7 downto 0);
		skip:			out std_logic;
		carry:		out std_logic;
		result:		out std_logic_vector(7 downto 0)
	);
	
end entity;

-- operations
-- 0000: SE
-- 0001: SNE
-- 0010: ADD
-- 0011: SUB
-- 0100: b_OR
-- 0101: b_AND
-- 0110: b_XOR
-- 1000: SHR
-- 1001: SHL

architecture logicArith of ULA is

	signal SE:		std_logic;
	signal SNE:		std_logic;
	
	signal ADDa:	std_logic_vector(8 downto 0);
	signal ADD:		std_logic_vector(7 downto 0);
	signal ADDc:	std_logic;
	
	signal SUB:		std_logic_vector(7 downto 0);
	signal SUBc:	std_logic;
	
	signal b_OR: 	std_logic_vector(7 downto 0);
	signal b_AND:	std_logic_vector(7 downto 0);
	signal b_XOR:	std_logic_vector(7 downto 0);
	
	signal SHR:		std_logic_vector(7 downto 0);
	signal SHRc:	std_logic;
	
	signal SHL:		std_logic_vector(7 downto 0);
	signal SHLc:	std_logic;

begin
	
	SE  <= '1' when Acc = DataBus else
			 '0';
			
	SNE <= '0' when Acc = DataBus else
			 '1';
	
	ADDa <= std_logic_vector(unsigned('0' & Acc) + unsigned('0' & DataBus));
	ADDc <= ADDa(8);
	ADD  <= ADDa(7 downto 0);
	
	SUB  <= std_logic_vector(unsigned(Acc) - unsigned(DataBus));
	SUBc <=  '1' when Acc > DataBus else
				'0';
	
	
	b_OR  <= Acc or  DataBus;
	b_AND <= Acc and DataBus;
	b_XOR <= Acc xor DataBus;
	
	SHR  <= '0' & Acc(7 downto 1);
	SHRc <= Acc(0);
	
	SHL  <= Acc(6 downto 0) & '0';
	SHLc <= Acc(7);
	
	with op select skip <=
		SE		when "0000",
		SNE 	when "0001",
		'0' 	when others;
		
	with op select result <=
		ADD	when "0010",
		SUB	when "0011",
		b_OR	when "0100",
		b_AND	when "0101",
		b_XOR when "0110",
		SHR	when "1000",
		SHL	when "1001",
		(others => '0') when others;
		
	with op select carry <=
		ADDc when "0010",
		SUBc when "0011",
		SHRc when "1000",
		SHLc when "1001",
		'0'  when others;

end architecture;		