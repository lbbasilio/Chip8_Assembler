library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity VGA_sync is
	
	port(
		raw_clk:	 in std_logic;
		clear:	 	 in std_logic;
		pixel:	 	 in std_logic;
		color:		 in std_logic_vector(2 downto 0);
		
		coord_x:	out std_logic_vector(5 downto 0);
		coord_y:	out std_logic_vector(4 downto 0);
		pix_clk:	out std_logic;
		hsync:		out std_logic;
		vsync:		out std_logic;
		video_out:	out std_logic_vector(11 downto 0)
	);
	
end entity;

architecture behavior of VGA_sync is

	-- VGA 640 by 480 sync parameters
	constant HD: integer := 640; -- horizontal display area
	constant HF: integer := 16;  -- horizontal front porch
	constant HB: integer := 48;  -- horizontal back porch
	constant HR: integer := 96;  -- horizontal retrace

	constant VD: integer := 480; -- vertical display area
	constant VF: integer := 10;  -- vertical front porch
	constant VB: integer := 33;  -- vertical back porch
	constant VR: integer := 2;   -- vertical retrace
	
	signal pixel_clk:	std_logic := '0';
	
	signal h_count:	unsigned(9 downto 0) := (others => '0');
	signal v_count:	unsigned(9 downto 0) := (others => '0');
	
	signal video_on:	std_logic := '0';
	
	signal coord_count:	unsigned(5 downto 0) := (others => '0');
	signal aux_count:	unsigned(2 downto 0) := (others => '0');
	
	signal p_x:	std_logic_vector(5 downto 0) := (others => '0');
	signal p_y:	std_logic_vector(4 downto 0) := (others => '0');
	
	signal x_count:	unsigned(2 downto 0) := (others => '0');
	signal y_count:	unsigned(2 downto 0) := (others => '0');
	
begin
	
	process(raw_clk) -- generate 25 MHz clock
	begin
		if rising_edge(raw_clk) then
			pixel_clk <= not pixel_clk;
		end if;
	end process;
	

	process(pixel_clk, clear)
	begin
		if clear = '1' then
			h_count <= (others => '0');
			v_count <= (others => '0');
		elsif rising_edge(pixel_clk) then
			if h_count = (HD + HF + HB + HR - 1) then 
				
				if v_count = (VD + VF + VB + VR - 1) then
					v_count <= (others => '0');
				else
					v_count <= v_count + 1;
				end if;
				
				h_count <= (others => '0');
			else
				h_count <= h_count + 1;
			end if;
			
			
		end if;
	end process;
	
	process(pixel_clk)
	begin
		if rising_edge(pixel_clk) then
		
			if (h_count = HD/4 - 1) then 
				
				-- Reset p_x before every pixel on first column
				p_x <= (others => '0');
				x_count <= (others => '0');
				
				-- Reset p_y right before first visible pixel
				if (v_count = VD/3) then
					p_y <= (others => '0');
					y_count <= (others => '0');
				end if;
				
				
				
			else
				-- increment x_count / p_x
				if x_count = "100" then
					x_count <= "000";
					if p_x = "111111" then
						
						-- increment y_count / p_y
						if y_count = "100" then 
							y_count <= "000";
							p_y <= std_logic_vector(unsigned(p_y) + "00001");
						else
							y_count <= y_count + "001";
						end if;

						-- reset x_count / p_x
						x_count <= (others => '0');
						p_x <= (others => '0');
					
						
					else
						p_x <= std_logic_vector(unsigned(p_x) + "000001");
					end if;
				else
					x_count <= x_count + "001";
				end if;
			end if;
		end if;
		
	end process;		
				
	
	hsync <= '0' when h_count >= (HD + HF) and h_count < (HD + HF + HR) else
				'1';

	vsync <=	'0' when v_count >= (VD + VF) and v_count < (VD + VF + VR) else
				'1';
				
	-- Only turns on video when inside the middle 320x160 pixel square
	video_on <= '1' when (h_count >= HD/4) and (h_count < 3*HD/4) and (v_count >= VD/3) and (v_count < 2*VD/3) else
				'0';
					
	
	
	video_out(11 downto 8) <=  (others => color(2)) when video_on = '1' and pixel = '1' else
								(others => '0');
	
	video_out(7  downto 4) <=  (others => color(1)) when video_on = '0' and pixel = '1' else
								(others => '0');
	
	video_out(3  downto 0) <=  (others => color(0)) when video_on = '1' and pixel = '1' else
								(others => '0');
	
	pix_clk <= pixel_clk;
	coord_x <= p_x;
	coord_y <= p_y;
	
end architecture;
			