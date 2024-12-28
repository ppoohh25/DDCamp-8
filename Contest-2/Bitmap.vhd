library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity Bitmap is
  port (
    Clk   : in std_logic;
    RstB : in std_logic;
    
    DataIn : in std_logic_vector(7 downto 0);
    EnIn : in std_logic;

    DataOut : out std_logic_vector(31 downto 0);
    EnOut : out std_logic
  );
end entity;

architecture rtl of Bitmap is

  ------------------------------------------------------------------
  --signal
  ------------------------------------------------------------------

  signal rDataOut : std_logic_vector(31 downto 0);
  signal rEnOut : std_logic;
  signal DatCnt : std_logic_vector(5 downto 0);
  signal rcntpix : std_logic_vector(19 downto 0) ;
  

  type BitmapStateType is
		(
			stCut,
			stData1,
      stData2,
      stData3
		);
	signal rState : BitmapStateType ;

  ------------------------------------------------------------------

begin

  ------------------------------------------------------------------
  --Output
  ------------------------------------------------------------------

  DataOut <= rDataOut(31 downto 0);
  EnOut <= rEnOut;

  ------------------------------------------------------------------


  ------------------------------------------------------------------
  --State Machine
  ------------------------------------------------------------------
  u_State : process (Clk)
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rState <= stCut;
        DatCnt <= (others => '0') ;
        else

          ------------ Cut first 54 bytes --------------------------------
            case (rState) is
              when stCut =>
              if (EnIn = '1') then
                if (DatCnt = 53) then
                  DatCnt <= (others => '0') ;
                  rState <= stData1;
                  else
                    DatCnt <= DatCnt + 1;
                end if;
              end if;
          ----------------------------------------------------------------

          ------------ Get First Byte of Data ----------------------------
              when (stData1) =>
                  if (EnIn = '1') then
                    rState <= stData2;
                    else
                      rState <= stData1;
                  end if;
          ----------------------------------------------------------------

          ------------ Get Second Byte of Data ----------------------------
              when (stData2) =>
                if (EnIn = '1') then
                  rState <= stData3;
                  else
                    rState <= stData2;
                end if;
          ----------------------------------------------------------------

          ------------ Get Third Byte of Data ----------------------------
              when (stData3) =>
                if (EnIn = '1') then
                  if (rcntpix = 786431) then --End of picture
                    rState <= stCut;
                    else
                      rState <= stData1;
                  end if;
                  else
                    rState <= stData3;
                end if;

          ------------------------------------------------------------------
            end case;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------


  ------------------------------------------------------------------
  --Data arrangement
  ------------------------------------------------------------------
  u_Data : process (Clk)
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rDataOut <= (others => '0') ;
        else
          case (rState) is
            when (stData1) =>
              if (EnIn = '1') then
                rDataOut(7 downto 0) <= DataIn; --first Data in with arrange bit
              end if;

            when (stData2) =>
            if (EnIn = '1') then
              rDataOut(15 downto 8) <= DataIn;  --Second Data in with arrange bit
            end if;

            when (stData3) =>
            if (EnIn = '1') then
              rDataOut(23 downto 16) <= DataIn; --Third Data in with arrange bit
            end if;

            when (stCut) =>
              rDataOut <= (others => '0') ;

          end case;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------

  ------------------------------------------------------------------
  --Enable that send to FIFO
  ------------------------------------------------------------------
  u_EnCtrl : process (Clk)
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rEnOut <= '0';
        else
          if (rState = stData3 and EnIn = '1') then
            rEnOut <= '1';
            else
              rEnOut <= '0';
          end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------


  ------------------------------------------------------------------
  --Count pixel of picture
  ------------------------------------------------------------------
  u_cntpix : process (Clk)
  begin
    if (rising_edge(Clk)) then
      if (RstB = '0') then
        rcntpix <= (others => '0') ;
      else
        if (rEnOut = '1') then
          if (rcntpix = 786431 ) then --End pixel
            rcntpix <= (others => '0') ;
            else
              rcntpix <= rcntpix + 1 ;
          end if;
          else
            rcntpix <= rcntpix;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------
  

end architecture;