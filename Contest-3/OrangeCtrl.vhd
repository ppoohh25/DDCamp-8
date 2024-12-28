---------------------------------------------------------------------------
-- Use to calculate position of orange bar
----------------------------------------------------------------------------



library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity OrangeCtrl is
  port (
    Clk   : in std_logic;
    RstB : in std_logic;

    Done : in std_logic;
    WrEn : in std_logic;
    DataIn : in std_logic_vector(7 downto 0);

    Orange_position : out std_logic_vector(2 downto 0) 
    
  );
end entity;

architecture rtl of OrangeCtrl is

  signal rOrange_position : std_logic_vector(2 downto 0) ;

begin

  Orange_position <= rOrange_position;

  u_pulse : process (Clk)
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rOrange_position <= conv_std_logic_vector(4,3);
        else
          if (Done = '1' and WrEn = '1') then

            if (DataIn = x"61") then --a
              if (rOrange_position > 0 ) then
                rOrange_position <= rOrange_position - 1;
                else
                  rOrange_position <= (others => '0') ;
              end if;
            end if;
            
            
            if (DataIn = x"64") then --d
              if (rOrange_position < 7 ) then
                rOrange_position <= rOrange_position + 1;
                else
                  rOrange_position <= conv_std_logic_vector(7,3);
              end if;
            end if;

          else
            rOrange_position <= rOrange_position;

          end if;
      end if;
    end if;
  end process;

end architecture;