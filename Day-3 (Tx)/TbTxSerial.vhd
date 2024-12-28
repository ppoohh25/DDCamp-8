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
-- Filename     TbTxSerial.vhd
-- Title        Test TxSerial
--
-- Company      Design Gateway Co., Ltd.
-- Project      
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       U.Patheera
-- Date         2019/12/12
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE STD.TEXTIO.ALL;

Entity TbTxSerial Is
End Entity TbTxSerial;

Architecture HTWTestBench Of TbTxSerial Is

--------------------------------------------------------------------------------------------
-- Constant Declaration
--------------------------------------------------------------------------------------------

	constant	tClk			: time := 10 ns;
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------
	
	Component TxSerial Is
	Port(
		RstB		: in	std_logic;
		Clk			: in	std_logic;
		
		TxFfEmpty	: in	std_logic;
		TxFfRdData	: in	std_logic_vector( 7 downto 0 );
		TxFfRdEn	: out	std_logic;
		
		SerDataOut	: out	std_logic
	);
	End Component TxSerial;
	
-------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------
	
	signal	TM			: integer	range 0 to 65535;
	signal 	TT			: integer range 0 to 65535;
	
	signal	RstB		: std_logic;
	signal	Clk			: std_logic;
	signal	TxFfEmpty	: std_logic;
	signal	TxFfRdData	: std_logic_vector( 7 downto 0 );
	signal	TxFfRdEn	: std_logic;
	signal	SerDataOut	: std_logic;
	
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
	
	u_TxSerial : TxSerial 
	Port map
	(
		RstB		=> RstB			,	
		Clk			=> Clk			,
		TxFfEmpty	=> TxFfEmpty	,
		TxFfRdData	=> TxFfRdData	,
		TxFfRdEn	=> TxFfRdEn	    ,
		SerDataOut	=> SerDataOut	
	);
	
-------------------------------------------------------------------------
-- Testbench
-------------------------------------------------------------------------

	u_Test : Process
	variable	vCnt	: std_logic_vector( 7 downto 0 );
	Begin
		-------------------------------------------
		-- TM=0 : Reset
		-------------------------------------------
		TM <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM); 
		TxFfEmpty	<= '1';
		TxFfRdData	<= x"00";
		
		wait for 30*tClk;

		-------------------------------------------
		-- TM=1 : Check counter value
		-------------------------------------------	
		TM <= 1; TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM); 
		TxFfEmpty <= '0';
		wait until rising_edge(Clk);
		TxFfRdData <= x"44";
		wait for 10*434*tClk;
		wait until rising_edge(Clk);
		TxFfEmpty <= '1';
		wait for 5000*tClk;

		-------------------------------------------
		-- TM=2
		-------------------------------------------	
		TM <= 2; TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM); 
		wait until rising_edge(Clk);
		TxFfEmpty <= '0';
		TxFfRdData <= x"63";
		clk_3_1 : for i in 0 to 2 loop
			wait until rising_edge(Clk);
		end loop ; -- clk_3
		TxFfEmpty <= '1';
		wait for 11*434*tClk;

		TxFfEmpty <= '0';
		TxFfRdData <= x"AD";
		clk_3_2 : for i in 0 to 2 loop
			wait until rising_edge(Clk);
		end loop ; -- clk_3
		TxFfEmpty <= '1';
		wait for 11*434*tClk;

		TxFfEmpty <= '0';
		TxFfRdData <= x"9B";
		clk_3_3 : for i in 0 to 2 loop
			wait until rising_edge(Clk);
		end loop ; -- clk_3
		TxFfEmpty <= '1';
		wait for 11*434*tClk;

		--------------------------------------------------------
		TM <= 255; wait for 1 ns;
		wait for 20*tClk;
		Report "##### End Simulation #####" Severity Failure;		
		wait;
		
	End Process u_Test;

End Architecture HTWTestBench;