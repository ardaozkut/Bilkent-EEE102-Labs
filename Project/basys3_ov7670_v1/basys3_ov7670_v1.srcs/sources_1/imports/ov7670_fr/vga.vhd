library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity VGA is
    Port ( CLK25 : in  STD_LOGIC;									-- 25 MHz input clock							
         rez_160x120 : IN std_logic;
         rez_320x240 : IN std_logic;
         Hsync,Vsync : out  STD_LOGIC;						--two synchronization signals for the VGA screen
         Nblank : out  STD_LOGIC;								-- ADV7123 D/A converter control signal
         activeArea : out  STD_LOGIC);
end VGA;

architecture Behavioral of VGA is
    signal Hcnt:STD_LOGIC_VECTOR(9 downto 0):="0000000000";		-- for column counting (horizontal)
    signal Vcnt:STD_LOGIC_VECTOR(9 downto 0):="1000001000";		-- for row counting (vertical)

    signal video:STD_LOGIC;
    constant HM: integer :=799;	--the maximum size considered 800 (horizontal)
    constant HD: integer :=640;	--screen size (horizontal)
    constant HF: integer :=16;		--front porch
    constant HB: integer :=48;		--back porch
    constant HR: integer :=96;		--sync time
    constant VM: integer :=520;	--the maximum size considered 525 (vertical)	
    constant VD: integer :=480;	--screen size (vertical)
    constant VF: integer :=10;		--front porch
    constant VB: integer :=29;		--back porch
    constant VR: integer :=2;		--retrace

begin

    -- initialization of a counter from 0 to 799 (800 pixels per line):
    -- at each clock edge increments the column counter    
    process(CLK25)
    begin
        if (CLK25'event and CLK25='1') then
            if (Hcnt = HM) then
                Hcnt <= "0000000000";
                if (Vcnt= VM) then
                    Vcnt <= "0000000000";
                    activeArea <= '1';
                else
                    if rez_160x120 = '1' then
                        if vCnt < 120-1 then
                            activeArea <= '1';
                        end if;
                    elsif rez_320x240 = '1' then
                        if vCnt < 240-1 then
                            activeArea <= '1';
                        end if;
                    else
                        if vCnt < 480-1 then
                            activeArea <= '1';
                        end if;
                    end if;
                    Vcnt <= Vcnt+1;
                end if;
            else
                if rez_160x120 = '1' then
                    if hcnt = 160-1 then
                        activeArea <= '0';
                    end if;
                elsif rez_320x240 = '1' then
                    if hcnt = 320-1 then
                        activeArea <= '0';
                    end if;
                else
                    if hcnt = 640-1 then
                        activeArea <= '0';
                    end if;
                end if;
                Hcnt <= Hcnt + 1;
            end if;
        end if;
    end process;


    -- generation of the horizontal synchronization signal Hsync:

    process(CLK25)
    begin
        if (CLK25'event and CLK25='1') then
            if (Hcnt >= (HD+HF) and Hcnt <= (HD+HF+HR-1)) then   --- Hcnt >= 656 and Hcnt <= 751
                Hsync <= '0';
            else
                Hsync <= '1';
            end if;
        end if;
    end process;


    --generation of the vertical synchronization signal Vsync:

    process(CLK25)
    begin
        if (CLK25'event and CLK25='1') then
            if (Vcnt >= (VD+VF) and Vcnt <= (VD+VF+VR-1)) then  ---Vcnt >= 490 and vcnt<= 491
                Vsync <= '0';
            else
                Vsync <= '1';
            end if;
        end if;
    end process;


    -- Nblank and Nsync to order the ADV7123 builder:

    video <= '1' when (Hcnt < HD) and (Vcnt < VD)			-- this is to use the full 640 x 480 resolution
	
             else '0';
    Nblank <= video;


end Behavioral;

