----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     UserWrDdr.vhd
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

Entity UserWrDdr Is
	Port
	(
		RstB			: in	std_logic;							-- use push button Key0 (active low)
		Clk				: in	std_logic;							-- clock input 100 MHz

		-- WrCtrl I/F
		MemInitDone		: in	std_logic;
		MtDdrWrReq		: out	std_logic;
		MtDdrWrBusy		: in	std_logic;
		MtDdrWrAddr		: out	std_logic_vector( 28 downto 7 );
		
		-- T2UWrFf I/F --FIFO
		T2UWrFfRdEn		: out	std_logic; --Read Req to FIFO
		T2UWrFfRdData	: in	std_logic_vector( 63 downto 0 ); --Data from FIFO
		T2UWrFfRdCnt	: in	std_logic_vector( 15 downto 0 ); --usedw from FIFO
		
		-- UWr2DFf I/F --MtDdr
		UWr2DFfRdEn		: in	std_logic; --Connect to Read En of FIFO
		UWr2DFfRdData	: out	std_logic_vector( 63 downto 0 ); --UserWrDdr Data to MtDdrWr
		UWr2DFfRdCnt	: out	std_logic_vector( 15 downto 0 ) --Connect to usedw of FIOF
	);
End Entity UserWrDdr;

Architecture rtl Of UserWrDdr Is

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal rMemInitDone	: std_logic_vector( 1 downto 0 );
	signal rMtDdrWrReq : std_logic ;
	signal rMtDdrWrAddr : std_logic_vector(28 downto 7) ;
	signal rDatCnt : std_logic_vector(4 downto 0) ;
	signal four : std_logic;
	signal rCnt_row : std_logic_vector(4 downto 0) ;


Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	--MemInitDone <= rMemInitDone;
	MtDdrWrReq <= rMtDdrWrReq;
	MtDdrWrAddr <= rMtDdrWrAddr;

	--Bypass From FIFO to DDR-----
	T2UWrFfRdEn <= UWr2DFfRdEn;
	UWr2DFfRdData <= T2UWrFfRdData;
	UWr2DFfRdCnt <= T2UWrFfRdCnt;

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

	u_WritereqCtrl : process (Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
			rMtDdrWrReq <= '0';
			else
				if (rMemInitDone(1) = '1') then
					if (four = '1') then
						rMtDdrWrReq <= '0';
						else
							if (MtDdrWrBusy = '1') then
								rMtDdrWrReq <= '0';
								else
									if (T2UWrFfRdCnt < 65536-32) then
										rMtDdrWrReq <= '1';
									else
										rMtDdrWrReq <= '0';
									end if;
								end if;
							end if;
					end if;
			end if;
		end if;
	end process;

	u_AddressCtrl : process (Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				rMtDdrWrAddr(26 downto 7) <= conv_std_logic_vector(24544,20) ;
				rMtDdrWrAddr(28 downto 27) <= "00";
				else
					if (rMemInitDone(1) = '1') then
						if (rMtDdrWrReq = '1' and MtDdrWrBusy = '1') then
							if (rMtDdrWrAddr(26 downto 7) = 31) then
								rMtDdrWrAddr(26 downto 7) <= conv_std_logic_vector(24544,20) ;
								rMtDdrWrAddr(28 downto 27) <= rMtDdrWrAddr(28 downto 27) + 1;
								elsif (rCnt_row = 31) then
									rMtDdrWrAddr(26 downto 7) <= rMtDdrWrAddr(26 downto 7) - 63 ;
									else
										rMtDdrWrAddr(26 downto 7) <= rMtDdrWrAddr(26 downto 7) + 1;
							end if;
							else
								rMtDdrWrAddr(26 downto 7) <= rMtDdrWrAddr(26 downto 7);
						end if;
					end if;
			end if;
		end if;
	end process;

	u_Cntrow : process (Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				rCnt_row <= (others => '0') ;
				else
					if (rMemInitDone(1) = '1') then
						if (rMtDdrWrReq = '1' and MtDdrWrBusy = '1') then
							if (rCnt_row = 31) then
								rCnt_row <= (others => '0') ;
								else
									rCnt_row <= rCnt_row + 1;
							end if;
							else
								rCnt_row <= rCnt_row;
						end if;
					end if;
			end if;
		end if;
	end process;

	-- u_AddressCtrl : process (Clk)
	-- begin
	-- 	if (rising_edge(Clk)) then
	-- 		if (RstB = '0') then
	-- 			rMtDdrWrAddr <= (others => '0') ;
	-- 			rDatCnt <= (others => '0') ;
	-- 			four <= '0';
	-- 			else
	-- 				if (rMemInitDone(1) = '1' and rMtDdrWrReq = '1' and MtDdrWrBusy = '1') then
	-- 							if (rMtDdrWrAddr(26 downto 7) = 24575) then
	-- 								if (rMtDdrWrAddr(28 downto 27) = "11") then
	-- 									four <= '1';
	-- 								else
	-- 									rMtDdrWrAddr(28 downto 27) <= rMtDdrWrAddr(28 downto 27) + 1;
	-- 									rMtDdrWrAddr(26 downto 7) <= (others => '0') ;
	-- 								end if;
	-- 							else
	-- 									rMtDdrWrAddr(26 downto 7) <= rMtDdrWrAddr(26 downto 7) + 1;
	-- 							end if;
	-- 						end if;
	-- 				end if;
	-- 	end if;
	-- end process;

End Architecture rtl;