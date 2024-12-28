----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     Par2Ser.vhd
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

Entity Par2Ser Is
Port 
(
	RstB		: in	std_logic;
	Clk			: in	std_logic;	
	
	ParLoad		: in	std_logic;
	ParDataIn	: in	std_logic_vector( 7 downto 0 );
	SerEn		: in	std_logic;
	
	SerOut		: out	std_logic
);
End Entity Par2Ser;

Architecture rtl Of Par2Ser Is

----------------------------------------------------------------------------------
-- Constant Declaration
----------------------------------------------------------------------------------
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	rParData	: std_logic_vector( 7 downto 0 );

Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	SerOut	<= rParData(0);

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------

	u_rParData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rParData(7 downto 0)	<= (others=>'0');
			else
				-- Load data input
				if ( ParLoad='1' ) then
					rParData(7 downto 0)	<= ParDataIn;
				-- Shift data out, starting from LSB to MSB
				-- Fill MSB by 0
				elsif ( SerEn='1' ) then
					rParData(6 downto 0)	<= rParData(7 downto 1);
					rParData(7)				<= '0';
				else
					rParData(7 downto 0)	<= rParData(7 downto 0);
				end if;
			end if;
		end if;
	End Process u_rParData;	

End Architecture rtl;
