library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity RxSerial Is
Port(
	RstB		: in	std_logic;
	Clk			: in	std_logic;
	
	SerDataIn	: in	std_logic;
	
	RxFfFull	: in	std_logic;
	RxFfWrData	: out	std_logic_vector( 7 downto 0 );
	RxFfWrEn	: out	std_logic
);
End Entity RxSerial;

Architecture rtl Of RxSerial Is

----------------------------------------------------------------------------------
-- Constant declaration
----------------------------------------------------------------------------------
constant cSampling : integer := 108;--Use 921600
constant cSampling_div_2 : integer := 54;--Use 921600


----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	rSerDataIn	: std_logic;
	signal rRxFfWrData : std_logic_vector(7 downto 0) ;
	signal Buff_rRxFfWrData : std_logic_vector(9 downto 0);
	signal rRxFfWrEn : std_logic;
	signal rSamCnt : std_logic_vector(10 downto 0);
	type RxStateType is
		(
			stIdle,
			stStart_bit,
			stReset,
			stData_bit,
			stEnd_bit
		);
	signal rState : RxStateType ;
	signal rSam : std_logic;
	signal rCntData : std_logic_vector(3 downto 0);
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	RxFfWrData <= rRxFfWrData;
	RxFfWrEn <= rRxFfWrEn;
----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------

	u_rSerDataIn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rSerDataIn		<= SerDataIn;
		end if;
	End Process u_rSerDataIn;

-----------------------------------------------------------------------------------
-- State Machine
-----------------------------------------------------------------------------------
	u_State : process (Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				rState <= stIdle;
				rCntData <= (others => '0')  ;
				Buff_rRxFfWrData <= ((others => '0') );
				rCntData <= (others => '0');
			else
				case (rState) is

					------------------------ Idle ---------------------------------------------
					when stIdle =>
						if (rSerDataIn = '0') then
							rState <= stStart_bit;
							rCntData <= (others => '0');
							else
								rState <= stIdle;
						end if;
					
					--------------------------------------------------------------------------


					----------------------- Start bit -----------------------------------------

						when stStart_bit =>
							if (rSam = '1') then
								Buff_rRxFfWrData(9) <= rSerDataIn;
							end if;
							if (rSamCnt = cSampling_div_2) then
								rState <= stReset;
								else
									rState <= stStart_bit;
							end if;
						
					---------------------------------------------------------------------------

							
					-------------------------- Reset counter ------------------------------------
							when stReset =>
								rState <= stData_bit;

					----------------------------------------------------------------------------


					----------------------------- Data bit --------------------------------------

							when stData_bit =>
								if (rSam = '1') then
											rCntData <= rCntData + 1;
											Buff_rRxFfWrData(8) <= rSerDataIn;
											Buff_rRxFfWrData(7 downto 0) <= Buff_rRxFfWrData(8 downto 1);
								end if;

								if (rCntData = 8 and rSamCnt = cSampling) then
									rState <= stEnd_bit;
								end if;

						---------------------------------------------------------------------------

						----------------------------- End Bit ------------------------------------
							when stEnd_bit =>
								if (rSam = '1') then
									Buff_rRxFfWrData(9) <= rSerDataIn;
									else
										if (rSamCnt = cSampling) then
											rState <= stIdle;
											else
												rState <= stEnd_bit;
										end if;
								end if;
								
							--------------------------------------------------------------------------
				end case;
			end if;
		end if;
	end process;
-----------------------------------------------------------------------------------


-----------------------------------------------------------------------------------
-- Sample Count
-----------------------------------------------------------------------------------

u_SamCnt : process (Clk)
begin
	if (rising_edge(Clk)) then
	if (RstB = '0' or rState = stIdle or rState = stReset) then
		rSamCnt <= (others => '0')  ;
		rSam <= '0';
		else
			if (rSamCnt = cSampling_div_2) then
				rSam <= '1';
				else
					rSam <= '0';
			end if;

			if (rSamCnt = cSampling) then
				rSamCnt <= (others => '0') ;
				else
					rSamCnt <= rSamCnt + 1;
			end if;
			end if;
	end if;
end process;

--------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- Enable Control
-----------------------------------------------------------------------------------

u_RxFfWrEn_Ctrl : process (Clk)
begin
	if (rising_edge(Clk)) then
		if (RstB = '0') then
			rRxFfWrEn <= '0';
			rRxFfWrData <= (others => '0'); 
			else
				if (rState = stEnd_bit and Buff_rRxFfWrData(9) = '1' and rSamCnt = cSampling and RxFfFull = '0') then
					rRxFfWrEn <= '1';
					rRxFfWrData <= Buff_rRxFfWrData(8 downto 1);
					else
						rRxFfWrEn <= '0';
				end if;
		end if;
	end if;
end process;

--------------------------------------------------------------------------------------
End Architecture rtl;