library IEEE;
use IEEE.std_logic_1164.all;

entity vgasynctb is
end entity;

architecture test of vgasynctb is

    component  VGA_sync is
	
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
        
    end component;

    signal raw_clk, clear: std_logic := '1';

    signal pixel: std_logic := '0';
    signal color: std_logic_vector(2 downto 0) := "111";

    signal coord_x: std_logic_vector(5 downto 0);
    signal coord_y: std_logic_vector(4 downto 0);

    signal pix_clk, hsync, vsync: std_logic;

    signal video_out: std_logic_vector(11 downto 0);

begin

    clk_process:process
    begin
        wait for 20ps;
        raw_clk <= not raw_clk;
    end process;

    clear_process:process
    begin
        wait for 70ps;
        clear <= '0';
        pixel <= '1';
    end process;

    UUT: VGA_sync port map(
        raw_clk => raw_clk,
        clear => clear,
        pixel => pixel,
        color => color,
        
        coord_x => coord_x,
        coord_y => coord_y,
        pix_clk => pix_clk,
        hsync => hsync,
        vsync => vsync,
        video_out => video_out
    );

    end architecture;