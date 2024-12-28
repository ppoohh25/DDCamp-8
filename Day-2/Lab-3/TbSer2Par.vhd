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
-- Filename     TbSer2Par.vhd
-- Title        Test Ser2Par
--
-- Company      Design Gateway Co., Ltd.
-- Project      
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
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE STD.TEXTIO.ALL;

Entity TbSer2Par Is
End Entity TbSer2Par;

Architecture HTWTestBench Of TbSer2Par Is

--------------------------------------------------------------------------------------------
-- Constant Declaration
--------------------------------------------------------------------------------------------

	constant	tClk			: time := 10 ns;
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------
	
	Component Ser2Par Is
	Port 
	(
		RstB		: in	std_logic;
		Clk			: in	std_logic;	
		
		SerDataIn	: in	std_logic;
		--SerEn		: in	std_logic;
		
		ParDataOut	: out	std_logic_vector( 7 downto 0 );
		ParValid	: out	std_logic
	);
	End Component Ser2Par;
	
-------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------
	
	signal	TM			: integer	range 0 to 65535;
	signal	TT			: integer	range 0 to 65535;
	
	signal	RstB		: std_logic;
	signal	Clk			: std_logic;		
	
	signal	SerDataIn	: std_logic;
	--signal	SerEn		: std_logic;

	signal	ParDataOut	: std_logic_vector( 7 downto 0 );
	signal	ParValid	: std_logic;
	
Begin

----------------------------------------------------------------------------------
-- Concurrent signal
----------------------------------------------------------------------------------
	
	u_Clk : Process
	Begin
		Clk		<= '1';
		wait for tClk/2;
		Clk		<= '0';
		wait for tClk/2;
	End Process u_Clk;
	
	u_Ser2Par : Ser2Par
	Port map
	( 
		RstB		=> RstB			,		
		Clk			=> Clk			,	

		SerDataIn	=> SerDataIn	,	
		SerEn		=> SerEn		,

		ParDataOut	=> ParDataOut	,
		ParValid	=> ParValid	
	);
	
-------------------------------------------------------------------------
-- Testbench
-------------------------------------------------------------------------

	u_Test : Process
	variable	iTmp8	: std_logic_vector(7 downto 0);
	variable	iTmp16	: std_logic_vector(15 downto 0);
	Begin
		-------------------------------------------
		-- TM=0 : Reset and Initial Value
		-------------------------------------------
		TM <= 0; TT <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		RstB		<= '0';
		SerDataIn	<= '0';
		SerEn		<= '0';
		wait for 10*tClk;
		RstB		<= '1';

		-------------------------------------------
		-- TM=1 : Send 8 data
		-------------------------------------------	
		-- TM <= 1; TT <= 0; wait for 1 ns;
		-- Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 

		-- -------------------------------
		-- -- Send 8 data continuously
		-- iTmp8	:= x"96";
		-- wait until rising_edge(Clk);
		-- For i in 0 to 7 loop
		-- 	SerEn <= '1';
		-- 	SerDataIn <= iTmp8(7-i);
		-- 	wait until rising_edge(Clk);
		-- End loop;
		-- wait for 1 ns;
		-- SerEn <= '0';

		
		-- wait for 10*tClk;
		
		-- -------------------------------
		-- -- Send 8 data (active one every 2 clock)
		-- TT <= 1; wait for 1 ns;
		-- Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
				
		-- iTmp8	:= x"A5";
		-- wait until rising_edge(Clk);
		-- For i in 0 to 7 loop
		-- 	SerEn <= '1';
		-- 	SerDataIn <= iTmp8(7-i);
		-- 	wait until rising_edge(Clk);
		-- 	SerEn <= '0';
		-- 	wait until rising_edge(Clk);
		-- End loop;
		
		-- wait for 10*tClk;
		
		-- -------------------------------------------
		-- -- TM=2 : Send 16 data
		-- -------------------------------------------	
		TM <= 2; TT <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		-------------------------------
		-- Send 16 data continuously
		iTmp16	:= x"ABCD";
		wait until rising_edge(Clk);
		For i in 0 to 15 loop
			--SerEn <= '1';
			SerDataIn <= iTmp16(15-i);
			wait until rising_edge(Clk);
		End loop;
		--SerEn <= '0';
		
		wait for 10*tClk;
		
		-- -------------------------------
		-- -- Send 16 data (active one every 2 clock)
		TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
				
		iTmp16	:= x"3579";
		wait until rising_edge(Clk);
		For i in 0 to 15 loop
			--SerEn <= '1';
			SerDataIn <= iTmp16(15-i);
			wait until rising_edge(Clk);
			--SerEn <= '0';
			wait until rising_edge(Clk);
		End loop;
		
		wait for 10*tClk;

		--------------------------------------------------------
		TM <= 255; wait for 1 ns;
		wait for 20*tClk;
		Report "##### End Simulation #####" Severity Failure;		
		wait;
		
	End Process u_Test;

End Architecture HTWTestBench;