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
-- Filename     MtDdrRd.vhd
-- Title        Avalon-Master Write DDR Controller
--
-- Company      Design Gateway Co., Ltd.
-- Project      MtDdr-IP
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       B.Attapon
-- Date         2017/11/21
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity MtDdrRd Is
    Port 
	(	
		RstB				: in	std_logic;		-- Reset (Active low)
		Clk					: in	std_logic;		-- Clock

		-- Command I/F
		MtDdrRdReq			: in	std_logic;
		MtDdrRdBusy			: out	std_logic;
		MtDdrRdAddr			: in	std_logic_vector( 28 downto 7 );
		-- Fifo
		RdFfWrEn			: out	std_logic;
		RdFfWrData			: out	std_logic_vector( 63 downto 0 );
		RdFfWrCnt			: in	std_logic_vector( 15 downto 0 );
		
		-- Master Port
		MtAddress			: out	std_logic_vector( 28 downto 0 );
		MtRead				: out	std_logic;
		MtWrite				: out	std_logic;
		MtByteEnable		: out	std_logic_vector( 7 downto 0 );
		MtReadData			: in	std_logic_vector( 63 downto 0 );
		MtReadDataValid		: in	std_logic;
		MtWriteData			: out	std_logic_vector( 63 downto 0 );
		MtBurstCount		: out	std_logic_vector( 4 downto 0 );
		MtWaitRequest		: in	std_logic
	);							
End Entity MtDdrRd;

Architecture rtl Of MtDdrRd Is

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------

	type	MtStateType is
						(
							stIdle,
							-- Read
							stChkRdRdy,
							stGenRdReq,
							stRdTrans							
						);
	signal	rMtState	: MtStateType;

	signal	rMtAddr				: std_logic_vector( 28 downto 7 );	-- Transfer address to request to Avalon-bus
	signal	rMtBusy				: std_logic;
	
	-- Read
	signal	rMtRead				: std_logic;						-- Output to MtRead Port
	signal	rRdBurstCnt			: std_logic_vector( 4 downto 0 );	-- Burst Counter for read transfer	

Begin

----------------------------------------------------------------------------------
-- Output Assignment
----------------------------------------------------------------------------------

	MtDdrRdBusy			<= rMtBusy;
	
	MtAddress			<= rMtAddr(28 downto 7) & "000" & x"0"; -- Always align 16x64bit = 128 byte unit (1 burst size)
	MtByteEnable		<= x"FF";
	MtRead				<= rMtRead;
	MtWrite				<= '0';				-- not write
	MtWriteData			<= (others=>'0');	-- not use
	MtBurstCount		<= "10000";			-- fixed burst count = 16x64 bit
	
	RdFfWrEn			<= MtReadDataValid;
	RdFfWrData			<= MtReadData;
	
----------------------------------------------------------------------------------
-- DFF
----------------------------------------------------------------------------------

	-- Avalon Read Interface
	u_rMtState : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtState		<= stIdle;
			else
				case ( rMtState ) is				
					-- Wait start pulse
					when stIdle		=>
						if ( MtDdrRdReq='1' ) then
							-- Read transfers
							rMtState	<= stChkRdRdy;
						else
							rMtState	<= stIdle;
						end if;

					------------------------------------------------------
					-- Read Transfer
					when stChkRdRdy	=>
--						if ( RdFfWrCnt(15 downto 4)/=x"FFF" ) then
						-- Free space is more than 1 burst size 
						if ( RdFfWrCnt(15 downto 5)/=("111"&x"FF") ) then
							rMtState	<= stGenRdReq;
						else
							rMtState	<= stChkRdRdy;
						end if;
						
					-- Generate read request
					when stGenRdReq	=>
						-- Request complete
						if ( rMtRead='1' and MtWaitRequest='0' ) then
							rMtState	<= stRdTrans;
						else
							rMtState	<= stGenRdReq;
						end if;
					
					when stRdTrans	=>
						-- Last data in burst
						if ( MtReadDataValid='1' and rRdBurstCnt=1 ) then
							-- End command
							rMtState	<= stIdle;
						else
							rMtState	<= stRdTrans;
						end if;
					
				end case;
			end if;
		end if;
	End Process u_rMtState;
	
	u_rMtAddr : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			-- Load command MtAddr buffer address
			if ( MtDdrRdReq='1' ) then
				rMtAddr(28 downto 7)	<= MtDdrRdAddr(28 downto 7);
			else
				rMtAddr(28 downto 7)	<= rMtAddr(28 downto 7);
			end if;
		end if;
	End Process u_rMtAddr;

	u_rMtBusy : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtBusy	<= '0';
			else
				if ( rMtState=stIdle ) then
					if ( MtDdrRdReq='1' ) then
						rMtBusy	<= '1';
					else
						rMtBusy	<= '0';
					end if;
				else
					rMtBusy	<= '1';
				end if;
			end if;
		end if;
	End Process u_rMtBusy;
	
	------------------------------------------------------------------------------
	-- Read
	
	u_rMtRead : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtRead		<= '0';
			else
				-- Request complete
				if ( rMtRead='1' and MtWaitRequest='0' ) then
					rMtRead		<= '0';
				-- Send read request when RdFifo is not full
				elsif ( rMtState=stGenRdReq ) then
					rMtRead		<= '1';
				else
					rMtRead		<= rMtRead;
				end if;
			end if;
		end if;
	End Process u_rMtRead;
	
	u_rRdBurstCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			-- Receive each data
			if ( MtReadDataValid='1' ) then
				rRdBurstCnt		<= rRdBurstCnt - 1;
			-- Load new value when read request
			elsif ( rMtState=stGenRdReq ) then
				-- fixed burst count = 16x64 bit
				rRdBurstCnt		<= "10000";
			else
				rRdBurstCnt		<= rRdBurstCnt;
			end if;
		end if;
	End Process u_rRdBurstCnt;
	
End Architecture rtl;
