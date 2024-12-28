-------------------------------------------------------------------------------------------------------
-- Copyright (c) 2017, Design Gateway Co., Ltd.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
-- 1. Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright notice,
-- this list of conditions and the following disclaimer in the documentation
-- and/or other materials provided with the distribution.
--
-- 3. Neither the name of the copyright holder nor the names of its contributors
-- may be used to endorse or promote products derived from this software
-- without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
-- IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
-- EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     TbRxSerial.vhd
-- Title        Test RxSerial
--
-- Company      Design Gateway Co., Ltd.
-- Project      
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       U.Patheera
-- Date         2019/12/13
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE STD.TEXTIO.ALL;

Entity TbRxSerial Is
End Entity TbRxSerial;

Architecture HTWTestBench Of TbRxSerial Is

--------------------------------------------------------------------------------------------
-- Constant Declaration
--------------------------------------------------------------------------------------------

	constant	tClk			: time := 10 ns;
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------
	
	Component RxSerial Is
	Port(
		RstB		: in	std_logic;
		Clk			: in	std_logic;
		
		SerDataIn	: in	std_logic;
		
		RxFfFull	: in	std_logic;
		RxFfWrData	: out	std_logic_vector( 7 downto 0 );
		RxFfWrEn	: out	std_logic
	);
	End Component RxSerial;
	
-------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------
	
	signal	TM			: integer	range 0 to 65535;
	
	signal	RstB		: std_logic;
	signal	Clk			: std_logic;
	signal	SerDataIn	: std_logic;
	signal	RxFfFull	: std_logic;
	signal	RxFfWrData	: std_logic_vector( 7 downto 0 );
	signal	RxFfWrEn	: std_logic;
	
Begin

----------------------------------------------------------------------------------
-- Concurrent signal
----------------------------------------------------------------------------------
	
	u_RstB : Process
	Begin
		RstB	<= '0';
		wait for 20*tClk;
		RstB	<= '1';
		wait;
	End Process u_RstB;

	u_Clk : Process
	Begin
		Clk		<= '1';
		wait for tClk/2;
		Clk		<= '0';
		wait for tClk/2;
	End Process u_Clk;
	
	u_RxSerial : RxSerial 
	Port map
	(
		RstB		=> RstB			,	
		Clk			=> Clk			,
		SerDataIn	=> SerDataIn	,	
		RxFfFull	=> RxFfFull	    ,
		RxFfWrData	=> RxFfWrData	,
		RxFfWrEn	=> RxFfWrEn	
	);
	
-------------------------------------------------------------------------
-- Testbench
-------------------------------------------------------------------------

	u_Test : Process
	variable	iSerData	: std_logic_vector( 9 downto 0 );
	Begin
		-------------------------------------------
		-- TM=0 : Reset
		-------------------------------------------
		TM <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM); 
		SerDataIn	<= '1';
		RxFfFull	<= '0';
		wait for 30*tClk;

		-------------------------------------------
		-- TM=1 : Check counter value
		-------------------------------------------	
		TM <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM); 

		wait until rising_edge(Clk);
		iSerData 	:= '1'&x"99"&'0';
		For i in 0 to 9 loop
			SerDataIn	<= iSerData(0);
			wait for 108*tClk;
			wait until rising_edge(Clk);
			iSerData	:= '1' & iSerData(9 downto 1);
		End loop;
		
			wait until rising_edge(Clk);
			iSerData 	:= '1'&x"88"&'0';
			For i in 0 to 9 loop
				SerDataIn	<= iSerData(0);
				wait for 108*tClk;
				wait until rising_edge(Clk);
				iSerData	:= '1' & iSerData(9 downto 1);
			End loop;

			wait until rising_edge(Clk);
			iSerData 	:= '1'&x"77"&'0';
			For i in 0 to 9 loop
				SerDataIn	<= iSerData(0);
				wait for 108*tClk;
				wait until rising_edge(Clk);
				iSerData	:= '1' & iSerData(9 downto 1);
			End loop;

				wait until rising_edge(Clk);
			iSerData 	:= '1'&x"AC"&'0';
			For i in 0 to 9 loop
				SerDataIn	<= iSerData(0);
				wait for 108*tClk;
				wait until rising_edge(Clk);
				iSerData	:= '1' & iSerData(9 downto 1);
			End loop;

				wait until rising_edge(Clk);
			iSerData 	:= '1'&x"5B"&'0';
			For i in 0 to 9 loop
				SerDataIn	<= iSerData(0);
				wait for 108*tClk;
				wait until rising_edge(Clk);
				iSerData	:= '1' & iSerData(9 downto 1);
			End loop;

				wait until rising_edge(Clk);
			iSerData 	:= '1'&x"99"&'0';
			For i in 0 to 9 loop
				SerDataIn	<= iSerData(0);
				wait for 108*tClk;
				wait until rising_edge(Clk);
				iSerData	:= '1' & iSerData(9 downto 1);
			End loop;

		wait for 100*tClk;
		
		
		--------------------------------------------------------
		TM <= 255; wait for 1 ns;
		wait for 20*tClk;
		Report "##### End Simulation #####" Severity Failure;		
		wait;
		
	End Process u_Test;

End Architecture HTWTestBench;