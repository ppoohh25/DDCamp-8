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
-- Filename     TbCntUpDwn.vhd
-- Title        Test CntUpDwn
--
-- Company      Design Gateway Co., Ltd.
-- Project      
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
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE STD.TEXTIO.ALL;

Entity TbCntUpDwn Is
End Entity TbCntUpDwn;

Architecture HTWTestBench Of TbCntUpDwn Is

--------------------------------------------------------------------------------------------
-- Constant Declaration
--------------------------------------------------------------------------------------------

	constant	tClk			: time := 10 ns;
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------
	
	Component CntUpDwn Is
	Port 
	( 				
		RstB		: in	std_logic;
		Clk			: in	std_logic;	
		
		CntUpEn		: in	std_logic;
		CntDwnEn	: in	std_logic;
		
		CntOut		: out	std_logic_vector( 7 downto 0 )
	);
	End Component CntUpDwn;
	
-------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------
	
	signal	TM			: integer	range 0 to 65535;
	signal	TT			: integer	range 0 to 65535;
	
	signal	Clk			: std_logic;		
	signal	RstB		: std_logic;
	
	signal	CntUpEn		: std_logic;
	signal	CntDwnEn	: std_logic;		
	signal	CntOut		: std_logic_vector( 7 downto 0 );
	
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
	
	u_CntUpDwn : CntUpDwn
	Port map
	( 
		RstB		=> RstB		,		
		Clk			=> Clk		,	

		CntUpEn		=> CntUpEn	,	
		CntDwnEn	=> CntDwnEn	,

		CntOut		=> CntOut		
	);
	
-------------------------------------------------------------------------
-- Testbench
-------------------------------------------------------------------------

	u_Test : Process
	variable	iTmp	: integer range 0 to 65535;
	Begin
		-------------------------------------------
		-- TM=0 : Reset and Initial Value
		-------------------------------------------
		TM <= 0; TT <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		RstB		<= '0';
		CntUpEn		<= '0';
		CntDwnEn	<= '0';
		wait for 10*tClk;
		RstB		<= '1';

		-------------------------------------------
		-- TM=1 : Generate enable for 1 cycle
		-------------------------------------------	
		TM <= 1; TT <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		-------------------------------
		-- Check increment feature
		CntUpEn <= '1';
		wait until rising_edge(Clk);
		CntUpEn <= '0';
		wait until rising_edge(Clk);

		for i in 0 to 4 loop
			CntUpEn <= '1';
			wait until rising_edge(Clk);
			CntUpEn <= '0';
			wait until rising_edge(Clk);
		
		end loop ; -- identifier
		
		
		
		wait for 10*tClk;

		-------------------------------
		-- Check decrement feature
		TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		CntDwnEn <= '1';
		wait until rising_edge(Clk);
		CntDwnEn <= '0';
		wait until rising_edge(Clk);

		for i in 0 to 4 loop
			CntDwnEn <= '1';
			wait until rising_edge(Clk);
			CntDwnEn <= '0';
			wait until rising_edge(Clk);
		
		end loop ; -- identifier


		wait for 10*tClk;

		-------------------------------
		-- Check increment/decrement feature
		TT <= 2; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		-- Enable 1 clock
		CntUpEn <= '1';
		CntDwnEn <= '0';
		wait until rising_edge(Clk);
		CntUpEn <= '0';
		CntDwnEn <= '1';
		wait until rising_edge(Clk);
		CntUpEn <= '0';
		CntDwnEn <= '0';

		wait for 10*tClk;

		
		-- Enable 1 clock for 4 times
		TT <= 3; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 

		Same_4 : for i in 0 to 3 loop
			CntUpEn <= '1';
			CntDwnEn <= '0';
			wait until rising_edge(Clk);
			CntUpEn <= '0';
			CntDwnEn <= '1';
			wait until rising_edge(Clk);
			CntUpEn <= '0';
			CntDwnEn <= '0';
		end loop ; -- Same_4

		
		
		
		
		wait for 10*tClk;
		
		-------------------------------------------
		-- TM=2 : Generate enable more than 1 cycle
		-------------------------------------------	
		TM <= 2; TT <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		-------------------------------
		-- Generate multiple cycles by simple method
			CntUpEn <= '1';
			wait until rising_edge(Clk);
			wait until rising_edge(Clk);
			wait until rising_edge(Clk);
			CntUpEn <= '0';
			wait until rising_edge(Clk);

		wait for 10*tClk;
		
		-------------------------------
		-- Generate multiple cycles by simple method
		TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		CntDwnEn <= '1';
			 for i in 0 to 3 loop
				wait until rising_edge(Clk);
			end loop ; -- identifier
		CntDwnEn <= '0';
		wait until rising_edge(Clk);
			


		
		wait for 10*tClk;

		-------------------------------------------
		-- TM=3 : Generate signal with output condition
		-------------------------------------------	
		TM <= 3; TT <= 0; wait for 1 ns;		
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		-- Reset logic		
		RstB 	<= '0';
		wait for 10*tClk;
		RstB	<= '1';
		
		-- Count up until CntOut=5
		TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT);
		iTmp := 0;
		Loop
				CntUpEn <= '1';
				iTmp := iTmp +1;
				wait until rising_edge(Clk);
				wait for 1 ns;
				if (CntOut = 5) then
					exit;
				end if;
		end loop;
		CntUpEn <= '0';
		Report "Total CntUpEn cycle=" & integer'image(iTmp);
		wait until rising_edge(Clk);

		
		
		wait for 10*tClk;
		
		-- Count down until CntOut=0
		TT <= 2; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
				
		iTmp := 0;
		Loop
				CntDwnEn <= '1';
				iTmp := iTmp +1;
				wait until rising_edge(Clk);
				wait for 1 ns;
				if (CntOut = 0) then
					exit;
				end if;
		end loop;
		CntDwnEn <= '0';
		Report "Total CntDwnEn cycle=" & integer'image(iTmp);
		wait until rising_edge(Clk);

		wait for 10*tClk;
		
		--------------------------------------------------------
		TM <= 255; wait for 1 ns;
		wait for 20*tClk;
		Report "##### End Simulation #####" Severity Failure;		
		wait;
		
	End Process u_Test;

End Architecture HTWTestBench;