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
-- Filename     TestPatt.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp HDMI-IP
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      2.00
-- Author       J.Natthapat
-- Date         2018/12/1
-- Remark       Add DipSwitch to select pattern (Vertical Color Bar, Horizontal Color Bar, Red Screen, and Blue Screen)

-- Version      1.00
-- Author       B.Attapon
-- Date         2017/11/17
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity TestPatt Is
	Port
	(
		RstB			: in	std_logic;
		Clk				: in	std_logic;
		
		--DipSwitch
		Start			: in	std_logic;
		DipSwitch		: in 	std_logic_vector( 1 downto 0 );
		
		-- HDMI Data Interface
		HDMIFfWrEn		: out	std_logic;
		HDMIFfWrData	: out	std_logic_vector( 23 downto 0 );
		HDMIFfWrCnt		: in	std_logic_vector( 15 downto 0 )
	);
End Entity TestPatt;

Architecture rtl Of TestPatt Is

----------------------------------------------------------------------------------
-- Constant Declaration
----------------------------------------------------------------------------------
	
	constant	H_TOTAL		: integer	:= 1024 - 1;
	constant	V_TOTAL		: integer	:= 768 - 1;
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	rHCnt			: std_logic_vector( 9 downto 0 );
	signal	rVCnt			: std_logic_vector( 9 downto 0 );
		
	signal	rHDMIReq		: std_logic;
	signal	rHDMIFfWrEn		: std_logic_vector( 2 downto 0 );
	signal	rHDMIBlue		: std_logic_vector( 7 downto 0 );
	signal	rHDMIGreen		: std_logic_vector( 7 downto 0 );
	signal	rHDMIRed		: std_logic_vector( 7 downto 0 );
	
	-- Vertical Color Bar
	signal	rVCBRed			: std_logic_vector( 7 downto 0 );
	signal	rVCBGreen		: std_logic_vector( 7 downto 0 );
	signal	rVCBBlue		: std_logic_vector( 7 downto 0 );
	
	-- Horizontal Color Bar
	signal	rHCBRed			: std_logic_vector( 7 downto 0 );
	signal	rHCBGreen		: std_logic_vector( 7 downto 0 );
	signal	rHCBBlue		: std_logic_vector( 7 downto 0 );
	
	signal	rEnable			: std_logic;
	
	signal	rBreakEn		: std_logic;
	signal	rBrakeEnCnt		: std_logic_vector( 6 downto 0 );
	
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	
	HDMIFfWrEn					<= rHDMIFfWrEn(2);
	HDMIFfWrData(7 downto 0)	<= rHDMIBlue(7 downto 0);
	HDMIFfWrData(15 downto 8)	<= rHDMIGreen(7 downto 0);
	HDMIFfWrData(23 downto 16)	<= rHDMIRed(7 downto 0);
	
----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
	
	u_rHCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rHCnt	<= (others=>'0');
			else
				if ( rHDMIFfWrEn(0)='1' ) then
					-- Last Horizontal pixel
					if ( rHCnt=H_TOTAL ) then
						rHCnt	<= (others=>'0');
					else
						rHCnt	<= rHCnt + 1;
					end if;
				else
					rHCnt	<= rHCnt;
				end if;
			end if;
		end if;
	End Process u_rHCnt;
	
	u_rVCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rVCnt	<= (others=>'0');
			else
				if ( rHDMIFfWrEn(0)='1' and
					 -- Last Horizontal pixel
					 rHCnt=H_TOTAL ) then
					 -- Last Vertical pixel
					if ( rVCnt=V_TOTAL ) then
						rVCnt	<= (others=>'0');
					else
						rVCnt	<= rVCnt + 1;
					end if;
				else
					rVCnt	<= rVCnt;
				end if;
			end if;
		end if;
	End Process u_rVCnt;
	
	u_rBreakEn : Process(Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rBreakEn	<= '0';
			else
				if ( rBrakeEnCnt(6 downto 0)="111"&x"F" ) then
					rBreakEn	<= '1';
				else
					rBreakEn	<= '0';
				end if;
			end if;
		end if;
	End Process u_rBreakEn;
	
	u_rBrakeEnCnt : Process(Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rBrakeEnCnt(6 downto 0)	<= (others=>'0');
			else
				rBrakeEnCnt(6 downto 0)	<= rBrakeEnCnt(6 downto 0) + 1;
			end if;
		end if;
	End Process u_rBrakeEnCnt;
	
	u_rEnable : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rEnable		<= '0';
			else
				if ( Start='1' ) then
					rEnable		<= '1';
				elsif ( rHDMIFfWrEn(0)='1' and rVCnt=V_TOTAL and rHCnt=H_TOTAL ) then
					rEnable		<= '0';
				else
					rEnable		<= rEnable;
				end if;
			end if;
		end if;
	End Process u_rEnable;
	
	u_rHDMIFfWrEn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rHDMIFfWrEn(2 downto 0)		<= "000";
			else
				rHDMIFfWrEn(2 downto 1)	<= rHDMIFfWrEn(1 downto 0);
				-- Break when free space is less than 8
				if ( rEnable='1' and not(rHDMIFfWrEn(0)='1' and rVCnt=V_TOTAL and rHCnt=H_TOTAL) ) then
					if ( HDMIFfWrCnt(15 downto 3)/=('1'&x"FFF") and rBreakEn='1') then
						rHDMIFfWrEn(0)	<= '1';
					else
						rHDMIFfWrEn(0)	<= '0';
					end if;
				else
					rHDMIFfWrEn(0)	<= '0';
				end if;
			end if;
		end if;
	End Process u_rHDMIFfWrEn;
	
	-- Vertical Color Bar
	u_rVCBData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			case ( conv_integer(rHCnt) ) is
				-- White
				when 0		=>
					rVCBRed		<= x"FF";
					rVCBGreen	<= x"FF";
					rVCBBlue	<= x"FF";
				-- Yellow
				when 128		=>
					rVCBRed		<= x"FF";
					rVCBGreen	<= x"FF";
					rVCBBlue	<= x"00";
				-- Cyan
				when 256	=>
					rVCBRed		<= x"00";
					rVCBGreen	<= x"FF";
					rVCBBlue	<= x"FF";
				-- Green
				when 384	=>
					rVCBRed		<= x"00";
					rVCBGreen	<= x"FF";
					rVCBBlue	<= x"00";
				-- Magenta
				when 512	=>
					rVCBRed		<= x"FF";
					rVCBGreen	<= x"00";
					rVCBBlue	<= x"FF";
				-- Red
				when 640	=>
					rVCBRed		<= x"FF";
					rVCBGreen	<= x"00";
					rVCBBlue	<= x"00";
				-- Blue
				when 768	=>
					rVCBRed		<= x"00";
					rVCBGreen	<= x"00";
					rVCBBlue	<= x"FF";
				-- Black
				when 896	=>
					rVCBRed		<= x"00";
					rVCBGreen	<= x"00";
					rVCBBlue	<= x"00";
				when others	=>
					rVCBRed		<= rVCBRed;
					rVCBGreen	<= rVCBGreen;
					rVCBBlue	<= rVCBBlue;
			end case;
		end if;
	End Process u_rVCBData;
	
	-- Horizontal Color Bar
	u_rHCBData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			case ( conv_integer(rVCnt) ) is
				-- Black
				when 0		=>
					rHCBRed		<= x"00";
					rHCBGreen	<= x"00";
					rHCBBlue	<= x"00";
				-- Blue
				when 96		=>
					rHCBRed		<= x"00";
					rHCBGreen	<= x"00";
					rHCBBlue	<= x"FF";
				-- Red
				when 192	=>
					rHCBRed		<= x"FF";
					rHCBGreen	<= x"00";
					rHCBBlue	<= x"00";
				-- Magenta
				when 288	=>
					rHCBRed		<= x"FF";
					rHCBGreen	<= x"00";
					rHCBBlue	<= x"FF";
				-- Green
				when 384	=>
					rHCBRed		<= x"00";
					rHCBGreen	<= x"FF";
					rHCBBlue	<= x"00";
				-- Cyan
				when 480	=>
					rHCBRed		<= x"00";
					rHCBGreen	<= x"FF";
					rHCBBlue	<= x"FF";
				-- Yellow
				when 576	=>
					rHCBRed		<= x"FF";	
					rHCBGreen	<= x"FF";	
					rHCBBlue	<= x"00";	
				-- White
				when 672	=>
					rHCBRed		<= x"FF";	
					rHCBGreen	<= x"FF";	
					rHCBBlue	<= x"FF";	

				when others	=>
					rHCBRed		<= rHCBRed;
					rHCBGreen	<= rHCBGreen;
					rHCBBlue	<= rHCBBlue;
			end case;
		end if;
	End Process u_rHCBData;

	u_HDMIFfWrData : Process (Clk) Is
	Begin	
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rHDMIRed	<= x"FF";	-- 255
				rHDMIGreen	<= x"FF";	-- 255
				rHDMIBlue	<= x"FF";	-- 255
			else
				case ( DipSwitch(1 downto 0) ) is
					-- Vertical Color Bar
					when "00" 	=>
						rHDMIRed	<= rVCBRed;			
						rHDMIGreen	<= rVCBGreen;		
						rHDMIBlue	<= rVCBBlue;
	
					-- Horizontal Color Bar	
					when "01"	=>
						rHDMIRed	<= rHCBRed;			
						rHDMIGreen	<= rHCBGreen;			
						rHDMIBlue	<= rHCBBlue;
						
					-- Red Screen
					when "10"	=>
						rHDMIRed	<= x"FF";			-- 255	
						rHDMIGreen	<= (others=>'0');	-- 0	
						rHDMIBlue	<= (others=>'0');	-- 0	
						
					-- Blue Screen
					-- when "11"
					when others =>
						rHDMIRed	<= (others=>'0');	-- 0	
                        rHDMIGreen	<= (others=>'0');	-- 0	
				        rHDMIBlue	<= x"FF";			-- 255	
				end case;
			end if;
		end if;
	End Process u_HDMIFfWrData;
	
End Architecture rtl;