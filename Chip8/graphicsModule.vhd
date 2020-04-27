library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity graphicsModule is
	
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
	
end entity;

architecture visual of graphicsModule is

	component vram is
			
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

	component shiftReg is
	
		generic(
			data_size: integer := 8
		);
		
		port(
			clk:	  in std_logic;
			load:	  in std_logic;
			shift:  in std_logic;
			P_in:	  in std_logic_vector(data_size - 1 downto 0);
			S_out: out std_logic
		);
		
	end component;
	
	component VGA_sync is
	
		port(
			raw_clk:	 	 in std_logic;
			clear:	 	 in std_logic;
			pixel:	 	 in std_logic;
			color:		 in std_logic_vector(2 downto 0);
			
			coord_x:		out std_logic_vector(5 downto 0);
			coord_y:		out std_logic_vector(4 downto 0);
			pix_clk:		out std_logic;
			hsync:		out std_logic;
			vsync:		out std_logic;
			video_out:	out std_logic_vector(11 downto 0)
		);

	end component;
		
	constant zeros: std_logic_vector(2047 downto 0) := (others => '0');

	signal BB_wr_xreg:	std_logic_vector(5 downto 0);
	signal BB_wr_yreg:	std_logic_vector(4 downto 0);
	signal BB_wr_addr:	std_logic_vector(10 downto 0);
	signal BB_data:		std_logic_vector(2047 downto 0);
	
	signal x_count:	std_logic_vector(2 downto 0);
	signal y_count:	std_logic_vector(3 downto 0);
	signal y_en:		std_logic := '0';

	signal SR_out:	std_logic := '0';
	
	
	signal pixel:		std_logic;
	signal load_FB: 	std_logic;
	signal FB_rd_addr:	std_logic_vector(10 downto 0);
	signal FB_data:		std_logic_vector(2047 downto 0);
	
	signal FB_coord_x:	std_logic_vector(5 downto 0);
	signal FB_coord_y:	std_logic_vector(4 downto 0);
	
	signal collision_check:	std_logic_vector(2047 downto 0);
	signal new_pixel:		std_logic;
	signal old_pixel:		std_logic;
	
	signal v_sync: std_logic := '1';
	signal h_sync: std_logic := '1';
	
begin 

	VX_reg: reg generic map(6) port map(clk, loadX, clear, dataBus(5 downto 0), BB_wr_xreg);
	VY_reg: reg generic map(5) port map(clk, loadY, clear, dataBus(4 downto 0), BB_wr_yreg);
	
	countX: counter generic map(3) port map(clk, '0', '1',  '1', clearCountX, (others => '0'), x_count);
	countY: counter generic map(4) port map(clk, '0', '1', y_en, clearCountY, (others => '0'), y_count);
	
	y_en <= 	'1' when (x_count = "111" or clearCountY = '1') else '0';
	
	D_in: shiftReg port map(clk, loadSR, enSR, mem_data, SR_out);
	
	back_buffer:  vram port map(
			
			clk => clk,
			clear => clear,
			load => '0',
			write_en => BB_wr,
			wr_addr => BB_wr_addr,
			
			rd_addr => BB_wr_addr,
			Serial_in => new_pixel,
			Parallel_in => (others => '0'),
			Serial_out => old_pixel,
			Parallel_out => BB_data
	);
	
	front_buffer: vram port map(
		
		clk => clk,
		clear => clear,	
		load => load_FB,
		write_en => '0',
		wr_addr => (others => '0'),
		
		rd_addr => FB_rd_addr,
		Serial_in => '0',
		Parallel_in => BB_data,
		Serial_out => pixel,
		Parallel_out => FB_data
	
	);
	
	VGA: VGA_sync port map(
		
		raw_clk => raw_clk,
		clear => clear,
		pixel => pixel,
		color => color,
		
		coord_x => FB_coord_x,
		coord_y => FB_coord_y,
		
		pix_clk => open,
		hsync => h_sync,
		vsync => v_sync,
		
		video_out => video_out
		
	);
	
	BB_wr_addr <= std_logic_vector(unsigned(BB_wr_yreg) + unsigned(y_count)) & std_logic_vector(unsigned(BB_wr_xreg) + unsigned(x_count));
	FB_rd_addr <= FB_coord_y & FB_coord_x;	
	
	collision_check <= BB_data xor FB_data;
	collision <= '1' when collision_check = zeros else '0';
		
	new_pixel <= SR_out xor old_pixel;
	
	load_FB <= not v_sync ;
	vsync <= v_sync;
	hsync <= h_sync;
	
	dbgBB <= BB_data;
	dbgFB <= FB_data;
	dbgFB_out <= pixel;
	dbgBB_addr <= BB_wr_addr;
	
end architecture;
			