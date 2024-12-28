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
-- Filename     MtDdrWr.vhd
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

Entity MtDdrWr Is
    Port
	(
		RstB				: in	std_logic;		-- Reset (Active low)
		Clk					: in	std_logic;		-- Clock
		
		-- Command I/F
		MtDdrWrReq			: in	std_logic;
		MtDdrWrBusy			: out	std_logic;
		MtDdrWrAddr			: in	std_logic_vector( 28 downto 7 );
		-- Fifo
		WrFfRdEn			: out	std_logic;
		WrFfRdData			: in	std_logic_vector( 63 downto 0 );
		WrFfRdCnt			: in	std_logic_vector( 15 downto 0 );
		
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
End Entity MtDdrWr;

Architecture rtl Of MtDdrWr Is

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------

	type	MtStateType is
						(
							stIdle,
							-- Write
							stChkWrRdy,
							stWtBurstCal,
							stWrTrans						
						);
	signal	rMtState	: MtStateType;

	signal	rMtAddr				: std_logic_vector( 28 downto 7 );	-- Transfer address to request to Avalon-bus
	signal	rMtBusy				: std_logic;
	
	-- Write
	signal	r1stRdEn			: std_logic;						-- 1st pulse to read Fifo
	signal	rWrBurstCnt			: std_logic_vector( 4 downto 0 );	-- Burst Counter for write transfer
	signal	rWrBurstEnd			: std_logic;						-- End of write burst
	signal	rMtWrite			: std_logic;						-- Output to MtWrite Port

Begin

----------------------------------------------------------------------------------
-- Output Assignment
----------------------------------------------------------------------------------

	MtDdrWrBusy			<= rMtBusy;

	MtAddress			<= rMtAddr(28 downto 7) & "000" & x"0"; -- Always align 16x64 bit = 128 byte unit (1 burst size)
	MtByteEnable		<= x"FF";
	MtRead				<= '0';				-- not read
	MtWrite				<= rMtWrite;
	MtWriteData			<= WrFfRdData;
	MtBurstCount		<= "10000";			-- fixed burst count = 16x64 bit
	
	WrFfRdEn			<= '1' when (r1stRdEn='1' or 
									(rMtState=stWrTrans and 
									 rWrBurstEnd='0' and 
									 MtWaitRequest='0') ) else '0';
	
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
						if ( MtDdrWrReq='1' ) then
							-- Write transfers
							rMtState	<= stChkWrRdy;
						else
							rMtState	<= stIdle;
						end if;

					------------------------------------------------------
					-- Write Transfer
					when stChkWrRdy	=>
						-- At least 1 burst size available in Buffer
						if ( WrFfRdCnt(15 downto 4)/=0 ) then
							rMtState	<= stWtBurstCal;
						else
							rMtState	<= stChkWrRdy;
						end if;

					when stWtBurstCal	=>
						rMtState	<= stWrTrans;
						
					when stWrTrans	=>
						-- End of burst
						if ( rWrBurstEnd='1' and MtWaitRequest='0' ) then
							rMtState	<= stIdle;
						else
							rMtState	<= stWrTrans;
						end if;
					
				end case;
			end if;
		end if;
	End Process u_rMtState;

	u_rMtAddr : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			-- Load command MtAddr buffer address
			if ( MtDdrWrReq='1' ) then
				rMtAddr(28 downto 7)	<= MtDdrWrAddr(28 downto 7);
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
					if ( MtDdrWrReq='1' ) then
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
	-- Write

	-- 1st data pre-read for data ready at same time start transfer state
	u_r1stRdEn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				r1stRdEn	<= '0';
			else
				-- State transition to stWtTrans
				if ( rMtState=stWtBurstCal ) then
					r1stRdEn	<= '1';
				else
					r1stRdEn	<= '0';
				end if;
			end if;
		end if;
	End Process u_r1stRdEn;

	u_rWrBurstCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			-- Load value before start transferring
			if ( rMtState=stWtBurstCal ) then
			-- fixed Burst size 64 x 16 bit
				rWrBurstCnt	<= "10000";
			-- End of burst transfer
			elsif ( (rMtState=stWrTrans and MtWaitRequest='0') or r1stRdEn='1' ) then
				rWrBurstCnt	<= rWrBurstCnt - 1;
			else
				rWrBurstCnt	<= rWrBurstCnt;
			end if;
		end if;
	End Process u_rWrBurstCnt;

	u_rWrBurstEnd : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			-- Clear value before start transferring
			if ( rMtState=stChkWrRdy ) then
				rWrBurstEnd	<= '0';
			-- Last data in burst
			elsif ( rMtState=stWrTrans and rWrBurstCnt=1 and MtWaitRequest='0' ) then
				rWrBurstEnd	<= '1';				
			else
				rWrBurstEnd	<= rWrBurstEnd;
			end if;
		end if;
	End Process u_rWrBurstEnd;

	u_rMtWrite : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rMtWrite	<= '0';
			else
				-- Transfer data 
				if ( rMtState=stWrTrans ) then
					-- End of transfer
					if ( rWrBurstEnd='1' and MtWaitRequest='0' ) then
						rMtWrite	<= '0';
					else
						rMtWrite	<= '1';
					end if;
				else
					rMtWrite	<= '0';
				end if;
			end if;
		end if;
	End Process u_rMtWrite;
	
End Architecture rtl;
