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
-- Filename     VGAGenerator.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp HDMI-IP
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.01
-- Author       B.Attapon
-- Date         2019/12/04
-- Remark       Fix synchronization bug of HSync and VSync that is not start with sync pulse

-- Version      1.00
-- Author       B.Attapon
-- Date         2017/11/14
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Entity VGAGenerator Is
	Port 
	(
        Clk				: in	std_logic;
		RstB			: in	std_logic;
		
		-- User Output interface
		VGAReq			: in	std_logic;
		VGABusy			: out	std_logic;
		VGAError		: out	std_logic;
		
		VGAFfRdEn		: out	std_logic;
		VGAFfRdData		: in	std_logic_vector( 23 downto 0 );
		VGAFfEmpty		: in	std_logic;
		VGAFfRdCnt		: in	std_logic_vector( 15 downto 0 );	-- not use
		
		-- VGA Output Interface
		VGAClk			: out	std_logic;
		VGAClkB			: out	std_logic;
		VGADe			: out	std_logic;
		VGAHSync		: out	std_logic;
		VGAVSync		: out	std_logic;
		VGAData			: out	std_logic_vector( 23 downto 0 )
    );
End Entity VGAGenerator;

Architecture rtl Of VGAGenerator Is

----------------------------------------------------------------------------------
-- Constant Declaration
----------------------------------------------------------------------------------
	
	-- Parameter table in http://tinyvga.com/vga-timing
	
--	-- VGA Horizontal Parameter for resolution 640x480@60
--	constant	H_WHOLE_LINE	: integer	:= 800;
--	
--	constant	H_FRONT_PORCH	: integer	:= 16;
--	constant	H_SYNC_PULSE	: integer	:= 96;
--	
--	constant	H_BACK_PORCH	: integer	:= 48;
--	constant	H_VISIBLE_AREA	: integer	:= 640;
--	
--	-- VGA Vertical Parameter for resolution 640x480@60
--	constant	V_WHOLE_LINE	: integer	:= 525;
--	
--	constant	V_FRONT_PORCH	: integer	:= 10;
--	constant	V_SYNC_PULSE	: integer	:= 2;
--	
--	constant	V_BACK_PORCH	: integer	:= 33;
--	constant	V_VISIBLE_AREA	: integer	:= 480;
	
	-- Caution !!!!!!!!
	-- When there parameter is changed. 
	-- User must be ensure that rHSyncCnt and rVSyncCnt have enough number of bit to count with entire line
	-- VGA Horizontal Parameter for resolution 1024x768@60, PixClk = 65.0 MHz
	constant	H_WHOLE_LINE	: integer	:= 1344;
	
	constant	H_FRONT_PORCH	: integer	:= 24;
	constant	H_SYNC_PULSE	: integer	:= 136;
	
	constant	H_BACK_PORCH	: integer	:= 160;
	constant	H_VISIBLE_AREA	: integer	:= 1024;
	
	-- VGA Vertical Parameter for resolution 1024x768@60, PixClk = 65.0 MHz
	constant	V_WHOLE_LINE	: integer	:= 806;
	
	constant	V_FRONT_PORCH	: integer	:= 3;
	constant	V_SYNC_PULSE	: integer	:= 6;
	
	constant	V_BACK_PORCH	: integer	:= 29;
	constant	V_VISIBLE_AREA	: integer	:= 768;
	
	-- Calculate Parameters
	constant	H_VISIBLE_ST	: integer	:= H_SYNC_PULSE  + H_BACK_PORCH - 1;
	constant	H_VISIBLE_END	: integer	:= H_VISIBLE_ST  + H_VISIBLE_AREA;
	
	constant	V_VISIBLE_ST	: integer	:= V_SYNC_PULSE  + V_BACK_PORCH;
	constant	V_VISIBLE_END	: integer	:= V_VISIBLE_ST  + V_VISIBLE_AREA;
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------
	
	component PLL_VGA
	port
	(
		areset		: in	std_logic  := '0';
		inclk0		: in	std_logic  := '0';
		c0			: out	std_logic;
		locked		: out	std_logic 
	);
	end component;

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	PixClk		: std_logic;						-- Pixel Clk
	
	signal	rPLLRstBCnt	: std_logic_vector( 3 downto 0 )	:= "0000";
	signal	PLLRst		: std_logic;
	signal	PLLLock		: std_logic;
	
	signal	rPLLLock	: std_logic_vector( 1 downto 0 )	:= "00";
	signal	rRstB		: std_logic_vector( 1 downto 0 )	:= "00";
	signal	rSysRstB	: std_logic;
	
	signal	rBusy		: std_logic;
	signal	rError		: std_logic;
	signal	rSysReq		: std_logic_vector( 1 downto 0 );
	signal	rSysBusy	: std_logic_vector( 1 downto 0 );
	signal	rSysError	: std_logic_vector( 1 downto 0 );
	
	signal	rShowDisp	: std_logic;
	signal	rHSyncCnt	: std_logic_vector( 10 downto 0 );
	signal	rVSyncCnt	: std_logic_vector( 10 downto 0 );
	
	signal	rHSync		: std_logic;
	signal	rVSync		: std_logic;
	signal	rVActive	: std_logic;
	signal	rDe			: std_logic_vector( 1 downto 0 );
	signal	wFfRdEn		: std_logic;
	
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	VGAClk		<= PixClk;
	VGAClkB		<= not PixClk;
	
	VGADe		<= rDe(1);
	VGAHSync	<= rHSync;
	VGAVSync	<= rVSync;
	
	VGAData		<= VGAFfRdData;
	
	VGAFfRdEn	<= wFfRdEn;
	
	VGABusy		<= rSysBusy(1);
	VGAError	<= rSysError(1);

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------

	-------------------------------------------
	-- Reset and clock 
	
	u_rPLLRstBCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rPLLRstBCnt	<= rPLLRstBCnt(2 downto 0) & '1';
		end if;
	End Process u_rPLLRstBCnt;
	
	PLLRst	<= not rPLLRstBCnt(3);
	
	u_SysOut : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rSysBusy	<= rSysBusy(0) & rBusy;
			rSysError	<= rSysError(0) & rError;
		end if;
	End Process u_SysOut;

	u_PLL_VGA : PLL_VGA
	Port map
	(
		areset		=> PLLRst	,
		inclk0		=> Clk		,	
		c0			=> PixClk	,	-- 65.00 MHz for resolution 1024x768@60
		locked		=> PLLLock
	);
	
	u_rSysRstB : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			rPLLLock	<= rPLLLock(0)  & PLLLock;
			rRstB		<= rRstB(0) & RstB;
			rSysRstB	<= rPLLLock(1) and rRstB(1);
		end if;
	End Process u_rSysRstB;
	
	-------------------------------------------
	
	u_rBusy : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then
				rBusy	<= '0';
			else
				rSysReq	<= rSysReq(0) & VGAReq;
				-- Req form User
				if ( rSysReq(1)='1' ) then
					rBusy	<= '1';
				else
					rBusy	<= rBusy;
				end if;
			end if;
		end if;
	End Process u_rBusy;
	
	u_rShowDisp : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then
				rShowDisp	<= '0';
			else
				-- System is Busy
				if ( rBusy='1' and
					 -- Start new frame
					 rVSync='0' and
					 -- At least 32 data available
					 VGAFfRdCnt(15 downto 5)/=0 ) then
					rShowDisp	<= '1';
				else
					rShowDisp	<= rShowDisp;
				end if;
			end if;
		end if;
	End Process u_rShowDisp;
	
	u_rError : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then
				rError	<= '0';
			else
				-- ShowDisp
				if ( rShowDisp='1' and 
					 -- VGAFifo is Empty
					 VGAFfEmpty='1' and 
					 -- show display is active
					 rDe(0)='1') then
					rError	<= '1';
				else
					rError	<= rError;
				end if;
			end if;
		end if;
	End Process u_rError;
	
	u_rHSyncCnt : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then
				rHSyncCnt	<= conv_std_logic_vector(H_WHOLE_LINE, rHSyncCnt'length);
			else
				-- Count 1 to 1344
				if ( rHSyncCnt=H_WHOLE_LINE ) then
					rHSyncCnt	<= conv_std_logic_vector(1, rHSyncCnt'length);
				else
					rHSyncCnt	<= rHSyncCnt + 1;
				end if;
			end if;
		end if;
	End Process u_rHSyncCnt;
	
	u_rVSyncCnt : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then	
				rVSyncCnt	<= conv_std_logic_vector(V_WHOLE_LINE, rVSyncCnt'length);
			else
				-- Count 1 to 806
				if ( rHSyncCnt=H_WHOLE_LINE ) then
					if ( rVSyncCnt=V_WHOLE_LINE ) then
						rVSyncCnt	<= conv_std_logic_vector(1, rVSyncCnt'length);
					else
						rVSyncCnt	<= rVSyncCnt + 1;
					end if;
				else
					rVSyncCnt	<= rVSyncCnt;
				end if;
			end if;
		end if;
	End Process u_rVSyncCnt;
	
	u_rHSync : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then
				rHSync		<= '1';
			else
				if ( rHSyncCnt=H_WHOLE_LINE ) then
					rHSync		<= '0';
				elsif ( rHSyncCnt=H_SYNC_PULSE ) then
					rHSync		<= '1';
				else
					rHSync		<= rHSync;
				end if;
			end if;
		end if;
	End Process u_rHSync;
	
	u_rVSync : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then
				rVSync	<= '1';
			else
				if ( rHSyncCnt=H_WHOLE_LINE ) then
					if ( rVSyncCnt=V_WHOLE_LINE ) then
						rVSync	<= '0';
					elsif ( rVSyncCnt=V_SYNC_PULSE ) then
						rVSync	<= '1';
					else
						rVSync	<= rVSync;
					end if;
				else
					rVSync	<= rVSync;
				end if;
			end if;
		end if;
	End Process u_rVSync;
	
	u_rVActive : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then
				rVActive	<= '0';
			else
				if ( rHSyncCnt=H_WHOLE_LINE ) then
					if ( rVSyncCnt=V_VISIBLE_ST ) then
						rVActive	<= '1';
					elsif ( rVSyncCnt=V_VISIBLE_END ) then
						rVActive	<= '0';
					else
						rVActive	<= rVActive;
					end if;
				else
					rVActive	<= rVActive;
				end if;
			end if;
		end if;
	End Process u_rVActive;
	 
	u_rDe : Process (PixClk) Is
	Begin
		if ( rising_edge(PixClk) ) then
			if ( rSysRstB='0' ) then
				rDe		<= "00";
			else
				rDe(1)	<= rDe(0);
				if ( rVActive='1' and rHSyncCnt=H_VISIBLE_ST ) then
					rDe(0)	<= '1';
				elsif ( rHSyncCnt=H_VISIBLE_END ) then
					rDe(0)	<= '0';
				else
					rDe(0)	<= rDe(0);
				end if;
			end if;
		end if;
	End Process u_rDe;
		  
	wFfRdEn	<= '1' when ( rDe(0)='1' and rShowDisp='1' ) else
			   '0';

End Architecture rtl;
