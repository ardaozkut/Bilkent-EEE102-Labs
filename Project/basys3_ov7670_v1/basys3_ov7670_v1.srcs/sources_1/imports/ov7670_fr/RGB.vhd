
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity RGB is
    Port ( Din 	: in	STD_LOGIC_VECTOR (11 downto 0);			-- 8-bit pixel grayscale
         Nblank : in	STD_LOGIC;										-- signal indicates the display area, outside the display area
                                                                -- the three colors take 0
         R,G,B 	: out	STD_LOGIC_VECTOR (7 downto 0));			-- the three colors on 10 bits
end RGB;

architecture Behavioral of RGB is

begin
    R <= Din(11 downto 8) & Din(11 downto 8) when Nblank='1' else "00000000";
    G <= Din(7 downto 4)  & Din(7 downto 4)  when Nblank='1' else "00000000";
    B <= Din(3 downto 0)  & Din(3 downto 0)  when Nblank='1' else "00000000";

end Behavioral;

