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
-- Filename     HDMIRom.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp HDMI-IP
-- PJ No.       
-- Syntax       VHDL
-- Note         

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

Entity HDMIRom Is
	Port (
        Clk				: in	std_logic;
		
		RdAddr			: in	std_logic_vector( 4 downto 0 ); -- Read Address

		HDMIConfAddr	: out	std_logic_vector( 7 downto 0 );	-- I2C HDMI Config Address
		HDMIConfData	: out	std_logic_vector( 7 downto 0 )	-- I2C HDMI Config Data
    );
End Entity HDMIRom;

Architecture rtl Of HDMIRom Is

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	type array32ofu16 is array (0 to 31) of std_logic_vector( 15 downto 0 );

	signal HDMIRom : array32ofu16 :=
	(
	-- Addr[15:8], Data[7:0]
		x"98" & x"03",		-- Must be set to 0x03 for proper operation
		x"01" & x"00",      -- Set 'N' value at 6144
		x"02" & x"18",      -- Set 'N' value at 6144
		x"03" & x"00",      -- Set 'N' value at 6144
		x"14" & x"70",      -- Set Ch count in the channel status to 8.
		x"15" & x"20",      -- Input 444 (RGB or YCrCb) with Separate Syncs, 48kHz fs
		x"16" & x"30",      -- Output format 444, 24-bit input
		x"18" & x"46",      -- Disable CSC
		x"40" & x"80",      -- General control packet enable
		x"41" & x"10",      -- Power down control
		x"49" & x"A8",      -- Set dither mode - 12-to-10 bit
		x"55" & x"10",      -- Set RGB in AVI infoframe
		x"56" & x"08",      -- Set active format aspect
		x"96" & x"F6",      -- Set interrup
		x"73" & x"07",      -- Info frame Ch count to 8
		x"76" & x"1F",      -- Set speaker allocation for 8 channels
		x"98" & x"03",      -- Must be set to 0x03 for proper operation
		x"99" & x"02",      -- Must be set to Default Value
		x"9A" & x"E0",      -- Must be set to 0b1110000
		x"9C" & x"30",      -- PLL filter R1 value
		x"9D" & x"61",      -- Set clock divide
		x"A2" & x"A4",      -- Must be set to 0xA4 for proper operation
		x"A3" & x"A4",      -- Must be set to 0xA4 for proper operation
		x"A5" & x"04",      -- Must be set to Default Value
		x"AB" & x"40",      -- Must be set to Default Value
		x"AF" & x"16",      -- Select HDMI mode
		x"BA" & x"60",      -- No clock delay
		x"D1" & x"FF",      -- Must be set to Default Value
		x"DE" & x"10",      -- Must be set to Default for proper operation
		x"E4" & x"60",      -- Must be set to Default Value
		x"FA" & x"7D",      -- Nbr of times to look for good phase
		x"FA" & x"7D"		-- not use
	);
	
--	attribute romstyle : string;
--	attribute romstyle of HDMIRom : signal is "MLAB, no_rw_check";
	
	attribute romstyle : string;
	attribute romstyle of HDMIRom : signal is "logic";
	
	signal	rRdData		: std_logic_vector( 15 downto 0 );
	
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	HDMIConfData	<= rRdData(7 downto 0);
	HDMIConfAddr	<= rRdData(15 downto 8);

----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------

	u_rRdDataDiv : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rRdData	<= HDMIRom(conv_integer(RdAddr));
		end if;
	End Process u_rRdDataDiv;

End Architecture rtl;
