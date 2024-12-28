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
-- Filename     I2CCtrl.vhd
-- Title        I2C Master Controller
--
-- Company      Design Gateway
-- Project      DDCamp
-- PJ No.       
-- Syntax       VHDL
-- Note         
--
-- Version      1.00
-- Author       U.Patheera
-- Date         2017/12/05
-- Remark       Modify to support only write command
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
--use IEEE.STD_LOGIC_ARITH.all;

Entity I2CCtrl Is
-- Generic parameters
-- Port List
    Port 
	(
        RstB     		: in        std_logic; 			
        Clk      		: in        std_logic;			
										  
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
End Entity I2CCtrl;

Architecture rtl Of I2CCtrl Is

----------------------------------------------------------------------------------
-- Constant Declaration
----------------------------------------------------------------------------------

	-- Slave Device Address
	constant	cI2CDevId	: std_logic_vector( 6 downto 0 ):= "0111001";	-- 0x72
	-- DivClk = half period of SCL
	constant	cDivClk		: std_logic_vector( 11 downto 0 ):= x"9C4";		-- (RefClk/(2xSCLClk)) = (100 MHz/(2x20 kHz))

----------------------------------------------------------------------------------
-- Signal Declaration
----------------------------------------------------------------------------------

	-- State Machine
	type I2C_STATE is	(	
							stIdle,		
							stStart0,
							stStart1,
		                 	stTxDevId0,
							stNop0,
		                 	stTxIndex,
							stNop1,
		                 	stTxData,	
							stNop2,
							stFinish
						);

	signal rState	:	I2C_STATE;

	-- User interface
	signal	rI2CCmdBusy		: std_logic;
	signal	rI2CStartAddr	: std_logic_vector( 7 downto 0 );

	signal 	rI2CSDA			: std_logic;
	signal	rI2CSCL			: std_logic;
	signal	rDataCnt		: std_logic_vector( 2 downto 0 );
	signal	rDivCnt			: std_logic_vector( 11 downto 0 );
	signal	rShiftReg		: std_logic_vector( 7 downto 0 );
	signal	rI2CSDAOe		: std_logic_vector( 3 downto 0 );
	signal	rI2CSDAin		: std_logic;
	signal	rDivEn			: std_logic;	
	signal	rDivEnHalf		: std_logic;
	signal	rI2CAck			: std_logic;
	signal	rI2CError		: std_logic;
	
	-- FIFO interface
	signal	rI2CDataReq 	: std_logic_vector( 1 downto 0 );

Begin

----------------------------------------------------------------------------------
-- Output Assignment
----------------------------------------------------------------------------------

	I2CSDA			<= rI2CSDA when rI2CSDAOe(3) = '1' else 'Z';
    I2CSCL    		<= rI2CSCL;
	I2CDataReq		<= rI2CDataReq(0);
	I2CError		<= rI2CError;

	I2CCmdBusy		<= rI2CCmdBusy;
	
----------------------------------------------------------------------------------
-- DFF
----------------------------------------------------------------------------------

	-- Main State Control
	u_rState : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB = '0' ) then
				rState	<= stIdle;
			else
				-- Receive request from user
				if ( rState=stIdle and I2CCmdReq='1' ) then
					rState	<= stStart0;
				elsif ( rDivEn='1' and rI2CSCL='1' ) then
					case rState is
						-- Prepare Start condition : SCL and SDA='1'
						when stStart0	=>
							rState	<= stStart1;
							
						-- Make falling edge of SDA -> Start bit of I2C : SCL='1', SDA='0'
						when stStart1	=>
							rState	<= stTxDevId0;
							
						-- Send 8-bit device ID. Use rDataCnt to count 8-bit data
						when stTxDevId0	=>
							if ( rDataCnt="111" ) then
								rState	<= stNop0;
							else
								rState	<= stTxDevId0;
							end if;
							
						-- Check Device ID ACK from I2C Slave
						when stNop0	=>
							-- Slave send ACK (rI2CAck assert when SDA='0')
							if ( rI2CAck='1' ) then
								rState <= stTxIndex;
							-- Slave not send ACK
							else	
								rState	<= stFinish;
							end if;
							
						-- Send 8-bit address. Use rDataCnt to count 8-bit data
						when stTxIndex	=>
							if ( rDataCnt="111" ) then
								rState	<= stNop1;
							else
								rState	<= stTxIndex;
							end if;

						-- Check Address ACK from I2C Slave
						when stNop1	=>
							-- Slave send ACK (rI2CAck assert when SDA='0')
							if ( rI2CAck='1' ) then
								rState <= stTxData;
							-- Slave not send ACK
							else
								rState <= stFinish;
							end if;
							
						-- Send 8-bit data. Use rDataCnt to count 8-bit data
						when stTxData	=>
							if ( rDataCnt="111" ) then
								rState	<= stNop2;
							else
								rState	<= stTxData;
							end if;

						--Check Data ACK for write command.
						when stNop2	=>
							rState <= stFinish;
														
						when stFinish	=>
							rState	<= stIdle;
							
						when others => 
							rState	<= rState;
					end case;
				else
					rState	<= rState;
				end if;
			end if;
		end if;
	End Process u_rState;

	-- Busy during write/read operation
	u_I2CCmdBusy : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rI2CCmdBusy	<= '0';
			else
				if ( rState=stIdle ) then
					rI2CCmdBusy	<= '0';
				else
					rI2CCmdBusy	<= '1';
				end if;
			end if;
		end if;
	End Process u_I2CCmdBusy;

	-- Count 1 byte data (8-bit)
	u_rDataCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB = '0' ) then
				rDataCnt	<= "000";
			else
				-- Transfer 8-bit to I2C bus
				if ( rState=stTxDevId0 or rState=stTxIndex or rState=stTxData ) then
					if ( rDivEn='1' and rI2CSCL='1' ) then
						rDataCnt	<= rDataCnt + 1;
					else
						rDataCnt	<= rDataCnt;
					end if;
				else
					rDataCnt	<= "000";
				end if;
			end if;
		end if;
	End Process u_rDataCnt;

	----------------------------------------------------
	-- Generate I2C clock (SCL)
	
	-- Counter for clock divider
	u_rDivCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rDivCnt		<= cDivClk;
			else
				if ( rState=stIdle or rDivEn='1' ) then
					-- wait for DivEn 1 clk
					rDivCnt	<= cDivClk;
				else
					rDivCnt	<= rDivCnt - 1;
				end if;
			end if;
		end if;
	End Process u_rDivCnt;

	-- Generate pulse when end of clock divider period
	u_rDivEn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rDivEn <= '0';
			else
				if ( rDivCnt=1 ) then
					rDivEn <= '1';
				else
					rDivEn <= '0';
				end if;
			end if;
		end if;
	End Process u_rDivEn;
	
	-- Generate pulse at half of clock divider period
	u_rDivEnHalf : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rDivEnHalf <= '0';
			else
				if ( rDivCnt=('0'&cDivClk(11 downto 1)) ) then
					rDivEnHalf <= '1';
				else
					rDivEnHalf <= '0';
				end if;
			end if;
		end if;
	End Process u_rDivEnHalf;

	-- Generate I2C Clock output
	u_rI2CSCL : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB = '0' ) then
				rI2CSCL	<= '1';
			else
				if ( rState=stIdle or rState=stStart0  
				-- Protect clock toggle to '0' when end of transfer
				 or (rState=stFinish and rI2CSCL='1') ) then
					rI2CSCL		<= '1';
				elsif ( rDivEn='1' ) then
					rI2CSCL 	<= not rI2CSCL;
				else
					rI2CSCL 	<= rI2CSCL;
				end if;
			end if;
		end if;
	End Process u_rI2CSCL;

	----------------------------------------------------
	-- Generate I2C data bus (SDA)
	
	-- Request sending data
	u_rI2CDataReq : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rI2CDataReq(1 downto 0) <= "00";
			else
				rI2CDataReq(1)	<= rI2CDataReq(0);
				-- Request data
				if ( rDivEnHalf='1' and rI2CSCL='0' and rState=stNop1 ) then
					rI2CDataReq(0) <= '1';
				else
					rI2CDataReq(0) <= '0';
				end if;
			end if;
		end if;
	End Process u_rI2CDataReq;

	u_rI2CStartAddr : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rI2CStartAddr	<= (others=>'0');
			else
				-- Latch input
				if ( I2CCmdReq='1' and rI2CCmdBusy='0' ) then
					rI2CStartAddr	<= I2CStartAddr;
				else
					rI2CStartAddr	<= rI2CStartAddr;
				end if;
			end if;
		end if;
	End Process u_rI2CStartAddr;
			
	-- Shift register for send data out to I2C
	u_ShiftReg : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rShiftReg	<= x"00";
			else		
				-- Load sending data 
				if ( rI2CDataReq(1)='1' ) then
					rShiftReg 	<= I2CDataOut;			
				elsif ( rDivEnHalf='1' ) then
					-- Load deviceID
					if ( rState=stStart1 ) then
						rShiftReg 	<= cI2CDevId&'0';
					-- Load register address
					elsif ( rState=stNop0 ) then
						rShiftReg	<= rI2CStartAddr;
					-- Shift data when SCL='0'
					elsif ( rI2CSCL='0' ) then
						rShiftReg	<= rShiftReg(6 downto 0)&'0';
					else
						rShiftReg 	<= rShiftReg;
					end if;					
				else
					rShiftReg 	<= rShiftReg;
				end if;		
			end if;
		end if;
	End Process u_ShiftReg;
	
	-- Generate I2CSDA
	u_rI2CSDA : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB = '0' ) then
				rI2CSDA	<= '1';
			else
				case rState is
					-- Generate Start flag by transition from '1' to '0'
					when stIdle 	=> rI2CSDA	<= '1';				
					when stStart1	=> rI2CSDA	<= '0';					

					-- Send device ID, register addres, and data
					when stTxDevId0 | stTxIndex | stTxData  =>
						-- I2C starts sending from MSB to LSB
						if ( rI2CSCL='0' and rDivEnHalf='1' ) then
							rI2CSDA	<= rShiftReg(7);
						else
							rI2CSDA	<= rI2CSDA;
						end if;
						
					-- Generate Stop flag by transition from '0' to '1'
					when stFinish	=>
						if ( rDivEnHalf='1' ) then
							if ( rI2CSCL='0' ) then
								rI2CSDA <= '0';
							else
								rI2CSDA <= '1';
							end if;
						else
							rI2CSDA	<= rI2CSDA;
						end if;
							
					when others => 
						rI2CSDA	<= rI2CSDA;
				end case;		
			end if;
		end if;
	End Process u_rI2CSDA;

	-- Data output Enable
	u_I2CSDAOe : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rI2CSDAOe	<= "0000";
			else
				rI2CSDAOe(3 downto 1)	<= rI2CSDAOe(2 downto 0);
				-- Disable output enable when receiving ACK from Slave
				if ( rState=stNop0 or rState=stNop1 or rState=stNop2 ) then
					rI2CSDAOe(0)	<= '0';
				else
					rI2CSDAOe(0)	<= '1';
				end if;			
			end if;
		end if;
	End Process u_I2CSDAOe;

	-- Input FF
	u_rI2CSDAin : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rI2CSDAin	<= I2CSDA;
		end if;
	End Process u_rI2CSDAin;
	
	-- Get Acknowlege Back from Slave
	u_rI2CAck : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB = '0' ) then
				rI2CAck		<= '0';
			else
				-- Receive ACK 
				if ( rState=stNop0 or rState=stNop1 ) then
					-- Ack from slave
					if ( rI2CSCL='1' and rDivEnHalf='1' ) then
						rI2CAck		<= not rI2CSDAin;
						-- synthesis translate_off
						if ( rI2CSDAin/='0' ) then
							rI2CAck	<= '1';
						else
							rI2CAck	<= '0';
						end if;
						-- synthesis translate_on						
					else
						rI2CAck		<= rI2CAck;
					end if;
				else
					rI2CAck		<= '1';
				end if;
			end if;
		end if;
	End Process u_rI2CAck;
		
	-- Command Error
	u_rI2CError : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rI2CError <= '0';
			else
				-- Clear flag when start 
				if ( rState=stStart0 ) then
					rI2CError <= '0';
				elsif ( rI2CAck='0' ) then
					rI2CError <= '1';
				else
					rI2CError <= rI2CError;
				end if;
			end if;
		end if;
	End Process u_rI2CError;
	
End Architecture rtl;


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Template Generator for VHDL Coding v1.07

