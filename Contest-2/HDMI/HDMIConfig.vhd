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
-- Filename     HDMIConfig.vhd
-- Title        Top I2C Master Controller
--
-- Company      Design Gateway
-- Project      DDCamp
-- PJ No.       
-- Syntax       VHDL
-- Note         
--
-- Version      1.00
-- Author       B.Attapon
-- Date         2017/11/17
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
--use IEEE.STD_LOGIC_ARITH.all;

Entity HDMIConfig Is
    Port (
        Clk      		: in        std_logic;
        RstB     		: in        std_logic;

		-- I2C Interface
        I2CSDA        	: inout     std_logic;
        I2CSCL        	: out       std_logic;
		
		-- HDMI Interface
		HDMI_TX_INT		: in		std_logic;
		
		Busy			: out		std_logic
    );
End Entity HDMIConfig;

Architecture rtl Of HDMIConfig Is

-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------

	Component I2CCtrl Is
	Port (
        Clk      		: in        std_logic;			
        RstB     		: in        std_logic; 			
										  
		I2CCmdReq		: in		std_logic; 
		I2CCmdBusy		: out		std_logic;
		I2CStartAddr	: in		std_logic_vector( 7 downto 0 );
		I2CDataOut		: in		std_logic_vector( 7 downto 0 );
		I2CDataReq		: out		std_logic;
		I2CError		: out		std_logic;

		-- I2C command
        I2CSDA        	: inout     std_logic; 			
        I2CSCL        	: out       std_logic       	
    );
	End Component I2CCtrl;
	
	Component HDMIRom Is
	Port (
        Clk				: in	std_logic;
		
		RdAddr			: in	std_logic_vector( 4 downto 0 ); -- Read Address

		HDMIConfAddr	: out	std_logic_vector( 7 downto 0 );	-- I2C HDMI Config Address
		HDMIConfData	: out	std_logic_vector( 7 downto 0 )	-- I2C HDMI Config Data
    );
	End Component HDMIRom;

----------------------------------------------------------------------------------
-- Signal Declaration
----------------------------------------------------------------------------------

	-- State Machine
	type TI2C_STATE is	(
							stChkBusy	,
							stSendWrReq	,
							stWrite		,
							stWtAddr	,
							stSendRdReq	,
							stRead		,
							stEnd
						);

	signal rState	:	TI2C_STATE;
	
	-- interface I2CCtrl
	signal	rI2CCmdReq		: std_logic; 
	signal	I2CCmdBusy		: std_logic;
	signal	I2CError		: std_logic;
	
	-- interface HDMIRom
	signal	HDMIConfAddr	: std_logic_vector( 7 downto 0 );
	signal	HDMIConfData	: std_logic_vector( 7 downto 0 );
	
	--Internal signal
	signal	rI2CCmdBusy		: std_logic_vector( 1 downto 0 );
	signal	rRomAddrCnt		: std_logic_vector( 4 downto 0 );
	signal	rBusy			: std_logic;

Begin

----------------------------------------------------------------------------------
-- Output Assignment
----------------------------------------------------------------------------------
	
	Busy	<= rBusy;
	
----------------------------------------------------------------------------------
-- DFF
----------------------------------------------------------------------------------

	u_I2CCtrl1 : I2CCtrl
	Port map
	(
	   RstB				=>	RstB			,
	   Clk				=>	Clk				,
						
	   I2CCmdReq		=>	rI2CCmdReq		,
	   I2CCmdBusy		=>	I2CCmdBusy		,
	   I2CStartAddr		=>	HDMIConfAddr	,	-- write addr
	   I2CDataOut		=>	HDMIConfData	,	-- write data
	   I2CDataReq		=>	open			,
	   I2CError			=>	I2CError		,
	   
	   I2CSDA			=>	I2CSDA			,
	   I2CSCL			=>	I2CSCL
	);

	u_rState : Process (Clk) Is
	Begin	
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rState	<= stChkBusy;
			else
				case ( rState ) is
					when stChkBusy	=>
						if ( I2CCmdBusy='0' ) then
							rState	<= stSendWrReq;
						else
							rState	<= stChkBusy;
						End if;
				
					when stSendWrReq	=>
						rState	<= stWrite;
					
					when stWrite	=>
						-- End I2C transfer
						if ( rI2CCmdBusy="10" ) then
							-- Check end position
							if ( rRomAddrCnt(4 downto 0)=31 ) then
								rState	<= stEnd;
							else
								rState	<= stWtAddr;
							end if;
						else
							rState		<= stWrite;
						end if;
						
					-- Wait data from HDMIRom valid
					when stWtAddr	=>
						rState	<= stSendWrReq;
					
					when stEnd	=>
						-- retransmission when receive interrupt
						if ( HDMI_TX_INT='0' ) then
							rState	<= stChkBusy;
						else
							rState	<= stEnd;
						end if;

					when others	=>
						rState	<= stChkBusy;

				end case;
			End if;
		end if;
	End Process u_rState;

	u_rBusy : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) )then
			if ( RstB='0' ) then
				rBusy	<= '1';
			else
				-- End of initialization
				if ( rState=stEnd ) then
					rBusy	<= '0';
				else
					rBusy	<= '1';
				End if;
			End if;
		End if;
	End Process u_rBusy;
			
	u_rI2CCmdBusy : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rI2CCmdBusy(1 downto 0)	<= "00";
			else
				-- Add FF for edge detection
				rI2CCmdBusy(1)	<= rI2CCmdBusy(0);
				rI2CCmdBusy(0)	<= I2CCmdBusy;
			end if;
		end if;
	End Process u_rI2CCmdBusy;

	u_rRomAddrCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rRomAddrCnt(4 downto 0)	<= (others=>'0');
			else
				-- Retrans from start position when stEnd->stChkBusy
				if ( rState=stEnd and HDMI_TX_INT='0' ) then
					rRomAddrCnt	<= (others=>'0');
				-- Increment to next address when stWrite->stWtAddr
				elsif ( rI2CCmdBusy="10" ) then
					if ( rRomAddrCnt(4 downto 0)=31 ) then
						rRomAddrCnt	<= (others=>'0');
					else
						rRomAddrCnt	<= rRomAddrCnt + 1;
					end if;
				else
					rRomAddrCnt	<= rRomAddrCnt;
				End if;
			End if;
		End if;
	End Process u_rRomAddrCnt;
	
	u_rI2CCmdReq : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rI2CCmdReq	<= '0';
			else
				-- Request is received
				if ( I2CCmdBusy='1' ) then
					rI2CCmdReq <= '0';
				elsif ( rState=stSendWrReq ) then
					rI2CCmdReq	<= '1';
				else
					rI2CCmdReq	<= rI2CCmdReq;
				End if;
			End if;
		End if;
	End Process u_rI2CCmdReq;
	
	u_HDMIRom : HDMIRom
	Port map(
        Clk				=> Clk			,

		RdAddr			=> rRomAddrCnt	,

		HDMIConfAddr	=> HDMIConfAddr	,
		HDMIConfData	=> HDMIConfData
    );

End Architecture rtl;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Template Generator for VHDL Coding v1.07

