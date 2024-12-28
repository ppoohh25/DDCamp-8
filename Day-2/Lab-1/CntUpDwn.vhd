----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     CntUpDwn.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp Simulation
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       S.Chaiwat
-- Date         2018/12/16
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Entity CntUpDwn Is
Port 
(
	RstB		: in	std_logic;
	Clk			: in	std_logic;	
	
	CntUpEn		: in	std_logic;
	CntDwnEn	: in	std_logic;
	
	CntOut		: out	std_logic_vector( 7 downto 0 )
);
End Entity CntUpDwn;

Architecture rtl Of CntUpDwn Is

----------------------------------------------------------------------------------
-- Constant Declaration
----------------------------------------------------------------------------------
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	rCnt	: std_logic_vector( 7 downto 0 );

Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	CntOut	<= rCnt;

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------

	u_rCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rCnt	<= (others=>'0');
			else
				-- Count up and Count down are active at the same time -> hold same value
				if ( CntUpEn='1' and CntDwnEn='1' ) then
					rCnt	<= rCnt;
				-- Count up
				elsif ( CntUpEn='1' ) then
					rCnt	<= rCnt + 1;
				-- Count down
				elsif ( CntDwnEn='1' ) then
					rCnt	<= rCnt - 1;
				-- No enable
				else
					rCnt	<= rCnt;
				end if;
			end if;
		end if;
	End Process u_rCnt;	

End Architecture rtl;
