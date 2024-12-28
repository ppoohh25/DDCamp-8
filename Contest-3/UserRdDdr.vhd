----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     UserRdDdr.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       B.Attapon
-- Date         2017/12/20
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity UserRdDdr Is
	Port
	(
		RstB			: in	std_logic;							-- use push button Key0 (active low)
		Clk				: in	std_logic;							-- clock input 100 MHz

		DipSwitch		: in 	std_logic_vector( 1 downto 0 );
		
		-- HDMICtrl I/F
		HDMIReq			: out	std_logic;
		HDMIBusy		: in	std_logic;
		
		-- RdCtrl I/F
		MemInitDone		: in	std_logic;
		MtDdrRdReq		: out	std_logic;
		MtDdrRdBusy		: in	std_logic;
		MtDdrRdAddr		: out	std_logic_vector( 28 downto 7 );
		
		-- D2URdFf I/F
		D2URdFfWrEn		: in	std_logic;
		D2URdFfWrData	: in	std_logic_vector( 63 downto 0 );
		D2URdFfWrCnt	: out	std_logic_vector( 15 downto 0 );
		
		-- URd2HFf I/F
		URd2HFfWrEn		: out	std_logic;
		URd2HFfWrData	: out	std_logic_vector( 63 downto 0 );
		URd2HFfWrCnt	: in	std_logic_vector( 15 downto 0 );

		Orange_position : in std_logic_vector(2 downto 0);
		score : out std_logic_vector(7 downto 0)
	);
End Entity UserRdDdr;

Architecture rtl Of UserRdDdr Is

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	constant Start_flow : integer := 0;
	constant End_flow : integer := 20479;
	constant End_pic : integer := 24575;
	constant orange : integer := 20480;
	constant steppix : integer := 4096;
	
	
	
	
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	rMemInitDone	: std_logic_vector( 1 downto 0 );
	signal	rHDMIReq		: std_logic;
	signal rMtDdrRdReq : std_logic ;
	signal rMtDdrRdAddr : std_logic_vector(28 downto 7) ;
	signal rStart_flow : std_logic_vector(26 downto 7);
	signal rCnt : std_logic_vector(26 downto 0);
	signal rFill : std_logic_vector(26 downto 7) ;
	signal rscore : std_logic_vector(7 downto 0);

	type FrameStateType is
		(
			 Read_Middle_to_End,
			Read_Start_to_AddrMinus1,
			ReadOrange,
			Fill_White

		);
	signal rState : FrameStateType ;

Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	HDMIReq			<= rHDMIReq;
	URd2HFfWrEn <= D2URdFfWrEn;
	URd2HFfWrData <= D2URdFfWrData;
	D2URdFfWrCnt <= URd2HFfWrCnt;
	MtDdrRdReq <= rMtDdrRdReq;
	MtDdrRdAddr <= rMtDdrRdAddr;
	score <= rscore;
----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
	
	u_rMemInitDone : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMemInitDone	<= "00";
			else
				-- Use rMemInitDone(1) in your design
				rMemInitDone	<= rMemInitDone(0) & MemInitDone;
			end if;
		end if;
	End Process u_rMemInitDone;

	u_rHDMIReq : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rHDMIReq	<= '0';
			else
				if ( HDMIBusy='0' and rMemInitDone(1)='1' ) then
					rHDMIReq	<= '1';
				elsif ( HDMIBusy='1' )  then
					rHDMIReq	<= '0';
				else
					rHDMIReq	<= rHDMIReq;
				end if;
			end if;
		end if;
	End Process u_rHDMIReq;

	u_RdReqCtrl : process (Clk)
	begin
		if (rising_edge(Clk)) then
		if (RstB = '0') then
			rMtDdrRdReq <= '0';
			else
				if (rMemInitDone(1)='1') then
					if (MtDdrRdBusy = '1') then
						rMtDdrRdReq <= '0';
						else
							if (URd2HFfWrCnt >= 32) then
								rMtDdrRdReq <= '1';
								else
									rMtDdrRdReq <= '0';
							end if;
					end if;
				end if;
		end if;
	end if;
	end process;


	-------------------------------------------------- Main Address Control ---------------------------------------------------------
u_AddCtrl :	process(Clk)
  begin
    if rising_edge(Clk) then
      if RstB = '0' then
        rState <= Read_Middle_to_End;
        rMtDdrRdAddr(26 downto 7) <= (others => '0') ;
      else
        if MemInitDone = '1' and rMtDdrRdReq = '1' and MtDdrRdBusy = '1' then
          case rState is


            when (Read_Middle_to_End) =>
              if rMtDdrRdAddr(26 downto 7) = orange - 1 then
								if (rStart_flow  = 0) then
										rState <= ReadOrange;
										rMtDdrRdAddr(26 downto 7) <= rFill;
								else
									rState <= Read_Start_to_AddrMinus1;
                	rMtDdrRdAddr(26 downto 7) <= (others => '0'); 
								end if;
              else
                rMtDdrRdAddr(26 downto 7) <= rMtDdrRdAddr(26 downto 7) + 1; 
              end if;


            when (Read_Start_to_AddrMinus1) =>
              if rMtDdrRdAddr(26 downto 7) = rStart_flow - 1 then
                rState <= ReadOrange;
								rMtDdrRdAddr(26 downto 7) <= rFill;
              else
                rMtDdrRdAddr(26 downto 7) <= rMtDdrRdAddr(26 downto 7) + 1; 
              end if;


						when (ReadOrange) =>
								if (rMtDdrRdAddr(26 downto 7) = 24575) then
									if (rFill /= orange) then
										rState <= Fill_White;
										rMtDdrRdAddr(26 downto 7) <= conv_std_logic_vector(orange,20);
										else
											rState <= Read_Middle_to_End;
											rMtDdrRdAddr(26 downto 7) <= rStart_flow;
									end if;
								else
									rMtDdrRdAddr(26 downto 7) <= rMtDdrRdAddr(26 downto 7) + 1;
								end if;


								when (Fill_White) =>
									if (rMtDdrRdAddr(26 downto 7) =	rFill - 1 ) then
										rState <= Read_Middle_to_End;
										rMtDdrRdAddr(26 downto 7) <= rStart_flow;
										else
											rMtDdrRdAddr(26 downto 7) <= rMtDdrRdAddr(26 downto 7) + 1;
									end if;
          end case;
        end if; 

      end if;
    end if;
  end process;

	------------------------------------------------------------------------------------------------------------------------------

	------------------------------------------------------------ Display position of orange bar ------------------------------------------------------------------

	u_Start_address_of_orange : process (Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				rFill <= (others => '0') ;
				else
					if (MemInitDone = '1' and rMtDdrRdReq = '1' and MtDdrRdBusy = '1' and (rState = Read_Middle_to_End or rState = Read_Start_to_AddrMinus1)) then

						case (Orange_position) is
							when "000" => rFill <= conv_std_logic_vector(orange+16,20); --0
	
							when "001" => rFill <= conv_std_logic_vector(orange+12,20); --1
	
							when "010" => rFill <= conv_std_logic_vector(orange+8,20);  --2
	
							when "011" => rFill <= conv_std_logic_vector(orange+4,20);  --3
	
							when "100" => rFill <= conv_std_logic_vector(orange,20);    --4
	
							when "101" => rFill <= conv_std_logic_vector(orange+28,20); --5
	
							when "110" => rFill <= conv_std_logic_vector(orange+24,20); --6
	
							when "111" => rFill <= conv_std_logic_vector(orange+20,20); --7 
	
							when others =>
								rFill <= conv_std_logic_vector(orange,20);
						end case;
							else
								rFill <= rFill;
					end if;
			end if;
		end if;
	end process;

	--------------------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------- Control flow of picture------------------------------------------

	u_StartflowCtrl : process (Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0' ) then
				rStart_flow <= (others => '0') ;
				else
					if (DipSwitch = "01" and rMtDdrRdAddr(26 downto 7) = 24574 and rCnt = 45000000 and rState = ReadOrange and rMtDdrRdReq = '1' and MtDdrRdBusy = '1' ) then
						if (rStart_flow = 0) then
							rStart_flow <= conv_std_logic_vector(orange-steppix,20);
							else
								rStart_flow <= rStart_flow - steppix;
						end if;
					else
						rStart_flow <= rStart_flow;
					end if;
			end if;
		end if;
	end process;

	--------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------- Counter --------------------------------------------------------

	u_Cnt : process (Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				rCnt <= (others => '0') ;
				else
					if (DipSwitch = "01" ) then
						if (rMtDdrRdAddr(26 downto 7) = 24574 and rCnt = 45000000 and rMtDdrRdReq = '1' and MtDdrRdBusy = '1') then
							rCnt <= (others => '0') ;
							elsif (rCnt = 45000000) then
								rCnt <= conv_std_logic_vector(45000000,27);
								else
									rCnt <= rCnt + 1;
						end if;
						else
							rCnt <= (others => '0') ;
					end if;
					
			end if;
		end if;
	end process;

	-------------------------------------------------------------------------------------------------------------------------

	-------------------------------------------------------- Score Count ------------------------------------------------------------------------------------

	u_score : process (Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				rscore <= (others => '0') ;
			else
				if (DipSwitch = "01" and rMtDdrRdAddr(26 downto 7) = 24574 and rCnt = 45000000 and rState = ReadOrange and rMtDdrRdReq = '1' and MtDdrRdBusy = '1')  then
					case (rFill) is
						when (conv_std_logic_vector(orange+16,20)) => --0
							if (rStart_flow = 4096) then
								if (rscore < 255) then
									rscore <= rscore + 1;
									else
										rscore <= conv_std_logic_vector(255,8);
								end if;
							end if;

						when (conv_std_logic_vector(orange+12,20)) => --1
							if (rStart_flow = 12288) then
								if (rscore < 255) then
									rscore <= rscore + 1;
									else
										rscore <= conv_std_logic_vector(255,8);
								end if;
							end if;

						when (conv_std_logic_vector(orange+8,20)) => --2
							if (rStart_flow = 8192) then
								if (rscore < 255) then
									rscore <= rscore + 1;
									else
										rscore <= conv_std_logic_vector(255,8);
								end if;
							end if;

						when (conv_std_logic_vector(orange+4,20)) => --3
							if (rStart_flow = 16384) then
								if (rscore < 255) then
									rscore <= rscore + 1;
									else
										rscore <= conv_std_logic_vector(255,8);
								end if;
							end if;

						when (conv_std_logic_vector(orange,20)) => --4
							if (rStart_flow = 4096) then
								if (rscore < 255) then
									rscore <= rscore + 1;
									else
										rscore <= conv_std_logic_vector(255,8);
								end if;
							end if;

						when (conv_std_logic_vector(orange+28,20)) => --5
							if (rStart_flow = 12288) then
								if (rscore < 255) then
									rscore <= rscore + 1;
									else
										rscore <= conv_std_logic_vector(255,8);
								end if;
							end if;

						when (conv_std_logic_vector(orange+24,20)) => --6
							if (rStart_flow = 16384) then
								if (rscore < 255) then
									rscore <= rscore + 1;
									else
										rscore <= conv_std_logic_vector(255,8);
								end if;
							end if;

						when (conv_std_logic_vector(orange+20,20)) => --7
							if (rStart_flow = 4096) then
								if (rscore < 255) then
									rscore <= rscore + 1;
									else
										rscore <= conv_std_logic_vector(255,8);
								end if;
							end if;
							
						when others =>
							rscore <= rscore;
					end case;

				end if;
			end if;
		end if;
	end process;

	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

End Architecture rtl;