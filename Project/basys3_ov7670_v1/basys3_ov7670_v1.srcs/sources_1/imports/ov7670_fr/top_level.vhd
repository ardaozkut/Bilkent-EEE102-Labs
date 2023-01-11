library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity top_level is
    Port ( clk100          : in  STD_LOGIC;
         scale2            : in  STD_LOGIC;
         scale1            : in  STD_LOGIC;
         reset            : in  STD_LOGIC;
         ready   : out STD_LOGIC;

         vga_hsync : out  STD_LOGIC;
         vga_vsync : out  STD_LOGIC;
         vga_r     : out  STD_LOGIC_vector(3 downto 0);
         vga_g     : out  STD_LOGIC_vector(3 downto 0);
         vga_b     : out  STD_LOGIC_vector(3 downto 0);

         ov_pclk  : in  STD_LOGIC;
         ov_xclk  : out STD_LOGIC;
         ov_vsync : in  STD_LOGIC;
         ov_hsync  : in  STD_LOGIC;
         ov_data  : in  STD_LOGIC_vector(7 downto 0);
         ov_sioc  : out STD_LOGIC;
         ov_siod  : inout STD_LOGIC;
         ov_pwdn  : out STD_LOGIC;
         ov_res : out STD_LOGIC
        );
end top_level;
architecture Behavioral of top_level is

    COMPONENT VGA
        PORT(
            CLK25 : IN std_logic;
            rez_160x120 : IN std_logic;
            rez_320x240 : IN std_logic;
            Hsync : OUT std_logic;
            Vsync : OUT std_logic;
            Nblank : OUT std_logic;
            activeArea : OUT std_logic
            
        );
    END COMPONENT;

    COMPONENT ov7670_controller
        PORT(
            clk : IN std_logic;
            resend : IN std_logic;
            siod : INOUT std_logic;
            ready : OUT std_logic;
            sioc : OUT std_logic;
            reset : OUT std_logic;
            pwdn : OUT std_logic;
            xclk : OUT std_logic
        );
    END COMPONENT;

    COMPONENT debounce
        PORT(
            clk : IN std_logic;
            i : IN std_logic;
            o : OUT std_logic
        );
    END COMPONENT;

    COMPONENT frame_buffer
        PORT (
            clka : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            clkb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;
    COMPONENT ov7670_capture
        PORT(
            rez_160x120 : IN std_logic;
            rez_320x240 : IN std_logic;
            pclk : IN std_logic;
            vsync : IN std_logic;
            href : IN std_logic;
            d : IN std_logic_vector(7 downto 0);
            addr : OUT std_logic_vector(18 downto 0);
            dout : OUT std_logic_vector(11 downto 0);
            we : OUT std_logic
        );
    END COMPONENT;
    COMPONENT RGB
        PORT(
            Din : IN std_logic_vector(11 downto 0);
            Nblank : IN std_logic;
            R : OUT std_logic_vector(7 downto 0);
            G : OUT std_logic_vector(7 downto 0);
            B : OUT std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    component clk_wiz_0
        port (
            CLK_100           : in     std_logic;
            -- Clock out ports
            reset : in std_logic;
            CLK_50          : out    std_logic;
            CLK_25          : out    std_logic);
    end component;
    COMPONENT Address_Generator
        PORT(
            CLK25       : IN  std_logic;
            rez_160x120 : IN std_logic;
            rez_320x240 : IN std_logic;
            enable      : IN  std_logic;
            vsync       : in  STD_LOGIC;
            address     : OUT std_logic_vector(18 downto 0)
        );
    END COMPONENT;
    signal clk_camera : std_logic;
    signal clk_vga    : std_logic;
    signal wren       : std_logic_vector(0 downto 0);
    signal resend     : std_logic;
    signal nBlank     : std_logic;
    signal vSync      : std_logic;

    signal wraddress  : std_logic_vector(18 downto 0);
    signal wrdata     : std_logic_vector(11 downto 0);

    signal rdaddress  : std_logic_vector(18 downto 0);
    signal rddata     : std_logic_vector(11 downto 0);
    signal red,green,blue : std_logic_vector(7 downto 0);
    signal activeArea : std_logic;

    signal rez_160x120 : std_logic;
    signal rez_320x240 : std_logic;
    signal size_select: std_logic_vector(1 downto 0);
    signal rd_addr,wr_addr  : std_logic_vector(16 downto 0);
begin
    vga_r <= red(7 downto 4);
    vga_g <= green(7 downto 4);
    vga_b <= blue(7 downto 4);

    rez_160x120 <= scale2;
    rez_320x240 <= scale1;
  

    clock_divider_IP : clk_wiz_0
        port map(CLK_100 => CLK100,
                 -- Clock out ports
                 reset => reset,
                 CLK_50 => CLK_camera,
                 CLK_25 => CLK_vga);

    vga_vsync <= vsync;

    Comp_VGA: VGA PORT MAP(
            CLK25      => clk_vga,
            rez_160x120 => rez_160x120,
            rez_320x240 => rez_320x240,
            Hsync      => vga_hsync,
            Vsync      => vsync,
            Nblank     => nBlank,
            activeArea => activeArea
        );
    Comp_cam_reset: debounce PORT MAP(
            clk => clk_vga,
            i   => reset,
            o   => resend
        );
    Comp_ov7670_controller: ov7670_controller PORT MAP(
            clk             => clk_camera,
            resend          => resend,
            ready => ready,
            sioc            => ov_sioc,
            siod            => ov_siod,
            reset           => ov_res,
            pwdn            => ov_pwdn,
            xclk            => ov_xclk
        );
    size_select <= scale2&scale1;

    with size_select select
 rd_addr <= rdaddress(18 downto 2) when "00",
        rdaddress(16 downto 0) when "01",
        rdaddress(16 downto 0) when "10",
        rdaddress(16 downto 0) when "11";

    with size_select select
 wr_addr <= wraddress(18 downto 2) when "00",
        wraddress(16 downto 0) when "01",
        wraddress(16 downto 0) when "10",
        wraddress(16 downto 0) when "11";
        
    frame_buffer_IP: frame_buffer PORT MAP(
            addrb => rd_addr,
            clkb   => clk_vga,
            doutb        => rddata,

            clka   => ov_pclk,
            addra => wr_addr,
            dina      => wrdata,
            wea      => wren
        );
    Comp_ov7670_capture: ov7670_capture PORT MAP(
            pclk  => ov_pclk,
            rez_160x120 => rez_160x120,
            rez_320x240 => rez_320x240,
            vsync => ov_vsync,
            href  => ov_hsync,
            d     => ov_data,
            addr  => wraddress,
            dout  => wrdata,
            we    => wren(0)
        );
    Comp_RGB: RGB PORT MAP(
            Din => rddata,
            Nblank => activeArea,
            R => red,
            G => green,
            B => blue
        );
    Comp_Address_Generator: Address_Generator PORT MAP(
            CLK25 => clk_vga,
            rez_160x120 => rez_160x120,
            rez_320x240 => rez_320x240,
            enable => activeArea,
            vsync  => vsync,
            address => rdaddress
        );
end Behavioral;