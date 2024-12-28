----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     Ser2Par.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp Simulation
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       U.Patheera
-- Date         2018/12/17
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Entity Ser2Par Is
Port 
(
	RstB		: in	std_logic;
	Clk			: in	std_logic;	
	
	SerDataIn	: in	std_logic;
	--SerEn		: in	std_logic;
	
	ParDataOut	: out	std_logic_vector( 7 downto 0 );
	ParValid	: out	std_logic
);
End Entity Ser2Par;

Architecture rtl Of Ser2Par Is

----------------------------------------------------------------------------------
-- Constant Declaration
----------------------------------------------------------------------------------
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	rParData0	: std_logic_vector( 7 downto 0 );
	signal	rParData1	: std_logic_vector( 7 downto 0 );
	signal	rParValid	: std_logic;
	signal	rCnt8		: std_logic_vector( 2 downto 0 );
	signal SerEn : std_logic_vector(7 downto 0);
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	ParDataOut(7 downto 0)	<= rParData(7 downto 0);
	
	ParValid				<= rParValid;

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------

	-- Count from 0 - 7 (8 value)
	-- u_rCnt8 : Process (Clk) Is
	-- Begin
	-- 	if ( rising_edge(Clk) ) then
	-- 		if ( RstB='0' ) then
	-- 			rCnt8(2 downto 0)	<= "000";
	-- 		else
	-- 			-- Count total times of SerEn='1'
	-- 			if ( SerEn='1' ) then
	-- 				rCnt8(2 downto 0)	<= rCnt8(2 downto 0) + 1;
	-- 			else
	-- 				rCnt8(2 downto 0)	<= rCnt8(2 downto 0);
	-- 			end if;
	-- 		end if;
	-- 	end if;
	-- End Process u_rCnt8;

  SerEn_Ctrl : process( Clk)
	begin
		if (rising_edge(Clk)) then
			if (RstB = '0') then
				SerEn <= (others => '0');
			elsif (SerEn = 15) then
				SerEn <= (others => '0');
				else
					SerEn <= SerEn+1;
			end if;	
		end if ;
	end process ; -- SerEn_Ctrl
	
	-- rParValid is not correct in TM=1/2 and TT=1 
	-- Problem: rParValid='1' for 2 clocks, not 1 clock)
	-- How to correct rParValid to be equal to '1' for 1 clock!!!
	u_rParValid : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rParValid	<= '0';
			else
				-- Set rParValid='1' after receives SerEn='1' every 8 timess
				if ( rCnt8(2 downto 0)=7 and SerEn = 15) then
					rParValid	<= '1';
				else
					rParValid	<= '0';
				end if;
			end if;
		end if;
	End Process u_rParValid;

	u_rParData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rParData(7 downto 0)	<= (others=>'0');
			else
				-- Receive data starting from MSB to LSB				
					rParData(7 downto 1)	<= rParData(6 downto 0);
					rParData(0)				<= SerDataIn;
				end if;
			end if;
--		end if;
	End Process u_rParData;	

	
End Architecture rtl;
