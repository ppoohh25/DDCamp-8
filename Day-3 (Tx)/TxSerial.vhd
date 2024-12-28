library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity TxSerial Is
Port(
	RstB				: in	std_logic;
	Clk					: in	std_logic;
	
	TxFfEmpty		: in	std_logic;
	TxFfRdData	: in	std_logic_vector( 7 downto 0 );
	TxFfRdEn		: out	std_logic;
	
	SerDataOut	: out	std_logic
);
End Entity TxSerial;

Architecture rtl Of TxSerial Is

----------------------------------------------------------------------------------
-- Constant declaration
----------------------------------------------------------------------------------
constant cBuadCnt : integer := 868;

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
signal rClk_cnt 	: std_logic_vector(9 downto 0);
signal rBuadEnd 	: std_logic;
signal rSerData 	: std_logic_vector(9 downto 0);
signal SerEnd			: std_logic;

type SerStateType is 
(
	stIdle,
	stRdReq,
	stWtData,
	stWtEnd
);
signal rState : SerStateType;

signal rTxFfRdEn : std_logic_vector(1 downto 0);
signal rDataCnt  : std_logic_vector(3 downto 0);

Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
SerDataOut <= rSerData(0);
TxFfRdEn   <= rTxFfRdEn(0);
----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
u_rBuadCnt : process( Clk )
begin
	if (rising_edge(Clk)) then
		if (RstB = '0') then
			rClk_cnt <= conv_std_logic_vector(cBuadCnt,10);
			else
			if (rState = stWtEnd) then
				if (rClk_cnt = 1) then
					rClk_cnt <= conv_std_logic_vector(cBuadCnt,10);
					else
						rClk_cnt <= rClk_cnt -1;
				end if ;
			end if ;
		end if ;
	end if ;
end process ; -- u_rBuadCnt

u_rBuadEnd : process( Clk )
begin
	if (rising_edge(Clk)) then
		if (RstB = '0') then
			rBuadEnd <= '0';
			SerEnd <= '0';
			else
				if (rClk_cnt = 2) then
					if (rDataCnt = 9) then
						SerEnd <= '1';
					end if ;
					rBuadEnd <= '1';
					else
						rBuadEnd <= '0';
						SerEnd <= '0';
				end if ;
		end if ;
	end if ;
end process ; -- u_rBuadEnd

u_SerData : process( Clk ) --LSB First
begin
	if (rising_edge(Clk)) then
		if (RstB = '0') then
			rSerData <= (others => '1');
			else
				if(rTxFfRdEn(1) = '1') then
					rSerData(9) <= '1';
					rSerData(8 downto 1) <= TxFfRdData;
					rSerData(0) <= '0';
					elsif (rBuadEnd = '1') then
						rSerData(9 downto 0) <= '1' & rSerData(9 downto 1);
		end if ;
	end if ;
end if;
end process ; -- u_SerData

u_rDataCnt : process( Clk )
begin
	if (rising_edge(Clk)) then
		if (RstB = '0') then
			rDataCnt <= (others => '0');
			else
				if (rBuadEnd = '1') then
					if (rDataCnt = 9) then
						rDataCnt <= (others => '0');
						else
							rDataCnt <= rDataCnt +1;
					end if ;
				end if ;
		end if ;
	end if ;
end process ; -- u_rDataCnt

u_rState : process( Clk )
begin
	if (rising_edge(Clk)) then
		if (RstB = '0') then
			rState <= stIdle;
			else
				case( rState ) is
				
					when stIdle =>
						if (TxFfEmpty = '0') then
							rState <= stRdReq;
							else
								rState <= stIdle;
						end if ;
					
					when stRdReq =>
						rState <= stWtData;

					when stWtData =>
						if (rTxFfRdEn(1) = '1') then
							rState <= stWtEnd;
							else
								rState <= stWtData;
						end if ;

					when stWtEnd =>
						if (SerEnd = '1') then
							rState <= stIdle;
							else
								rState <= stWtEnd;
						end if ;
				
				end case ;
		end if ;
	end if ;
end process ; -- u_rState

u_rTxFfRdEn : process( Clk )
begin
	if (rising_edge(clk)) then
		if (RstB = '0') then
			rTxFfRdEn <= "00";
			else
				rTxFfRdEn(1) <= rTxFfRdEn(0);
				if (rState = stRdReq) then
					rTxFfRdEn(0) <= '1';
					else
						rTxFfRdEn(0) <= '0';
				end if ;
		end if ;
	end if ;
end process ; -- u_rTxFfRdEn

End Architecture rtl;