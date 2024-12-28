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
-- Filename     MtDdr.vhd
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

Entity MtDdr Is
	Port 
	(	
		UserRstB		: in	std_logic;						-- Reset (Active low) (100MHz)
		UserClk			: in	std_logic;						-- User Clock (100MHz)
		
		-- DDR Controller Status
		MemInitDone		: out	std_logic;
		
		-- Command Write I/F
		MtDdrWrReq		: in	std_logic;
		MtDdrWrBusy		: out	std_logic;
		MtDdrWrAddr		: in	std_logic_vector( 28 downto 7 );
		-- User Write Fifo 
		WrFfRdEn		: out	std_logic;
		WrFfRdData		: in	std_logic_vector( 63 downto 0 );
		WrFfRdCnt		: in	std_logic_vector( 15 downto 0 );
		
		-- Command Read I/F
		MtDdrRdReq		: in	std_logic;
		MtDdrRdBusy		: out	std_logic;
		MtDdrRdAddr		: in	std_logic_vector( 28 downto 7 );
		-- User Read Fifo
		RdFfWrEn		: out	std_logic;
		RdFfWrData		: out	std_logic_vector( 63 downto 0 );
		RdFfWrCnt		: in	std_logic_vector( 15 downto 0 );
		
		-- DDR3 Interface
		DDR3_A			: out	std_logic_vector( 14 downto 0 );
		DDR3_BA			: out	std_logic_vector( 2 downto 0 );
		DDR3_CAS_n		: out	std_logic_vector( 0 downto 0 );
		DDR3_CK_n		: inout	std_logic_vector( 0 downto 0 );
		DDR3_CK_p		: inout	std_logic_vector( 0 downto 0 );
		DDR3_CKE		: out	std_logic_vector( 0 downto 0 );
		DDR3_CLK_50		: in	std_logic;
		DDR3_CS_n		: out	std_logic_vector( 0 downto 0 );
		DDR3_DM			: out	std_logic_vector( 1 downto 0 );
		DDR3_DQ			: inout	std_logic_vector( 15 downto 0 );
		DDR3_DQS_n		: inout	std_logic_vector( 1 downto 0 );
		DDR3_DQS_p		: inout	std_logic_vector( 1 downto 0 );
		DDR3_ODT		: out	std_logic_vector( 0 downto 0 );
		DDR3_RAS_n		: out	std_logic_vector( 0 downto 0 );
		DDR3_RESET_n	: out	std_logic;
		DDR3_WE_n		: out	std_logic_vector( 0 downto 0 )
	);
End Entity MtDdr;

Architecture rtl Of MtDdr Is

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	
	Component ddr3_qsys Is
	Port (
		reset_reset_n					: in	std_logic                     := 'X';             -- reset_n
		clk_clk							: in	std_logic                     := 'X';             -- clk
		mem_clk_clk                  	: in    std_logic                     := 'X';             -- clk
		mem_reset_reset_n            	: in    std_logic                     := 'X';             -- reset_n
		
		-- DDR Controller Status
		mem_status_local_init_done		: out	std_logic;                                        -- local_init_done
		mem_status_local_cal_success	: out	std_logic;                                        -- local_cal_success
		mem_status_local_cal_fail		: out	std_logic;                                        -- local_cal_fail
		
		-- Avalon Write Port
		avl_ddr0_waitrequest			: out	std_logic;                                        -- waitrequest
		avl_ddr0_readdata				: out	std_logic_vector(63 downto 0);                    -- readdata
		avl_ddr0_readdatavalid			: out	std_logic;                                        -- readdatavalid
		avl_ddr0_burstcount				: in	std_logic_vector(4 downto 0)  := (others => 'X'); -- burstcount
		avl_ddr0_writedata				: in	std_logic_vector(63 downto 0) := (others => 'X'); -- writedata
		avl_ddr0_address				: in	std_logic_vector(28 downto 0) := (others => 'X'); -- address
		avl_ddr0_write					: in	std_logic                     := 'X';             -- write
		avl_ddr0_read					: in	std_logic                     := 'X';             -- read
		avl_ddr0_byteenable				: in	std_logic_vector(7 downto 0)  := (others => 'X'); -- byteenable
		avl_ddr0_debugaccess			: in	std_logic                     := 'X';             -- debugaccess
		
		-- Avalon Read Port
		avl_ddr1_waitrequest			: out	std_logic;                                        -- waitrequest
		avl_ddr1_readdata				: out	std_logic_vector(63 downto 0);                    -- readdata
		avl_ddr1_readdatavalid			: out	std_logic;                                        -- readdatavalid
		avl_ddr1_burstcount				: in	std_logic_vector(4 downto 0)  := (others => 'X'); -- burstcount
		avl_ddr1_writedata				: in	std_logic_vector(63 downto 0) := (others => 'X'); -- writedata
		avl_ddr1_address				: in	std_logic_vector(28 downto 0) := (others => 'X'); -- address
		avl_ddr1_write					: in	std_logic                     := 'X';             -- write
		avl_ddr1_read					: in	std_logic                     := 'X';             -- read
		avl_ddr1_byteenable				: in	std_logic_vector(7 downto 0)  := (others => 'X'); -- byteenable
		avl_ddr1_debugaccess			: in	std_logic                     := 'X';             -- debugaccess
		
		-- DDR3 Interface
		memory_mem_a					: out	std_logic_vector(14 downto 0);                    -- mem_a
		memory_mem_ba					: out	std_logic_vector(2 downto 0);                     -- mem_ba
		memory_mem_ck					: inout	std_logic_vector(0 downto 0)  := (others => 'X'); -- mem_ck
		memory_mem_ck_n					: inout	std_logic_vector(0 downto 0)  := (others => 'X'); -- mem_ck_n
		memory_mem_cke					: out	std_logic_vector(0 downto 0);                     -- mem_cke
		memory_mem_cs_n					: out	std_logic_vector(0 downto 0);                     -- mem_cs_n
		memory_mem_dm					: out	std_logic_vector(1 downto 0);                     -- mem_dm
		memory_mem_ras_n				: out	std_logic_vector(0 downto 0);                     -- mem_ras_n
		memory_mem_cas_n				: out	std_logic_vector(0 downto 0);                     -- mem_cas_n
		memory_mem_we_n					: out	std_logic_vector(0 downto 0);                     -- mem_we_n
		memory_mem_reset_n				: out	std_logic;                                        -- mem_reset_n
		memory_mem_dq					: inout	std_logic_vector(15 downto 0) := (others => 'X'); -- mem_dq
		memory_mem_dqs					: inout	std_logic_vector(1 downto 0)  := (others => 'X'); -- mem_dqs
		memory_mem_dqs_n				: inout	std_logic_vector(1 downto 0)  := (others => 'X'); -- mem_dqs_n
		memory_mem_odt					: out	std_logic_vector(0 downto 0)                      -- mem_odt
	);
	End component ddr3_qsys;
	
	Component MtDdrWr Is
	Port
	(
		RstB				: in	std_logic;							-- Reset (Active low)
		Clk					: in	std_logic;							-- Clock
		
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
	End Component MtDdrWr;
	
	Component MtDdrRd Is
	Port
	(
		RstB				: in	std_logic;							-- Reset (Active low)
		Clk					: in	std_logic;							-- Clock
		
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
	End Component MtDdrRd;
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	-- PLL Mem RstB
	signal	rMemRstB			: std_logic_vector( 1 downto 0 )	:= "00";
	
	-- Avalon Write
	signal	MtWrAddress			: std_logic_vector( 28 downto 0 );
	signal	MtWrRead			: std_logic;
	signal	MtWrWrite			: std_logic;
	signal	MtWrByteEnable		: std_logic_vector( 7 downto 0 );
	signal	MtWrReadData		: std_logic_vector( 63 downto 0 );
	signal	MtWrReadDataValid	: std_logic;
	signal	MtWrWriteData		: std_logic_vector( 63 downto 0 );
	signal	MtWrBurstCount		: std_logic_vector( 4 downto 0 );
	signal	MtWrWaitRequest		: std_logic;
	
	-- Avalon Read
	signal	MtRdAddress			: std_logic_vector( 28 downto 0 );
	signal	MtRdRead			: std_logic;
	signal	MtRdWrite			: std_logic;
	signal	MtRdByteEnable		: std_logic_vector( 7 downto 0 );
	signal	MtRdReadData		: std_logic_vector( 63 downto 0 );
	signal	MtRdReadDataValid	: std_logic;
	signal	MtRdWriteData		: std_logic_vector( 63 downto 0 );
	signal	MtRdBurstCount		: std_logic_vector( 4 downto 0 );
	signal	MtRdWaitRequest		: std_logic;
	
Begin
	
----------------------------------------------------------------------------------
-- Output Assignment
----------------------------------------------------------------------------------
	
----------------------------------------------------------------------------------
-- DFF
----------------------------------------------------------------------------------

	u_rMemRstB : Process (DDR3_CLK_50) Is
	Begin
		if ( rising_edge(DDR3_CLK_50) ) then
			rMemRstB	<= rMemRstB(0) & UserRstB;
		end if;
	End Process u_rMemRstB;
	
	u_ddr3_qsys : ddr3_qsys
	Port map
	(
		
		-- reset_reset_n					=> '1'				,
		reset_reset_n					=> UserRstB			,
		clk_clk							=> UserClk			,
		mem_clk_clk						=> DDR3_CLK_50		,
		-- mem_reset_reset_n				=> '1'				,
		mem_reset_reset_n				=> rMemRstB(1)		,

		
		mem_status_local_init_done		=> MemInitDone		,
		mem_status_local_cal_success	=> open				,
		mem_status_local_cal_fail		=> open				,
		
		avl_ddr0_address				=> MtWrAddress		,
		avl_ddr0_read					=> MtWrRead			,
		avl_ddr0_write					=> MtWrWrite		,
		avl_ddr0_byteenable				=> MtWrByteEnable	,
		avl_ddr0_readdata				=> MtWrReadData		,
		avl_ddr0_readdatavalid			=> MtWrReadDataValid,
		avl_ddr0_writedata				=> MtWrWriteData	,
		avl_ddr0_burstcount				=> MtWrBurstCount	,
		avl_ddr0_waitrequest			=> MtWrWaitRequest	,
		avl_ddr0_debugaccess			=> '0'				,
		
		avl_ddr1_address				=> MtRdAddress		,
		avl_ddr1_read					=> MtRdRead			,
		avl_ddr1_write					=> MtRdWrite		,
		avl_ddr1_byteenable				=> MtRdByteEnable	,
		avl_ddr1_readdata				=> MtRdReadData		,
		avl_ddr1_readdatavalid			=> MtRdReadDataValid,
		avl_ddr1_writedata				=> MtRdWriteData	,
		avl_ddr1_burstcount				=> MtRdBurstCount	,
		avl_ddr1_waitrequest			=> MtRdWaitRequest	,
		avl_ddr1_debugaccess			=> '0'              ,
		
		memory_mem_a					=> DDR3_A			,
		memory_mem_ba					=> DDR3_BA			,
		memory_mem_ck					=> DDR3_CK_p		,
		memory_mem_ck_n					=> DDR3_CK_n		,
		memory_mem_cke					=> DDR3_CKE			,
		memory_mem_cs_n					=> DDR3_CS_n		,
		memory_mem_dm					=> DDR3_DM			,
		memory_mem_ras_n				=> DDR3_RAS_n		,
		memory_mem_cas_n				=> DDR3_CAS_n		,
		memory_mem_we_n					=> DDR3_WE_n		,
		memory_mem_reset_n				=> DDR3_RESET_n		,
		memory_mem_dq					=> DDR3_DQ			,
		memory_mem_dqs					=> DDR3_DQS_p		,
		memory_mem_dqs_n				=> DDR3_DQS_n		,
		memory_mem_odt					=> DDR3_ODT
	);
	
	u_MtDdrWr : MtDdrWr
	Port map
	(
		RstB					=> UserRstB			,
		Clk						=> UserClk			,
		
		-- Command I/F	
		MtDdrWrReq				=> MtDdrWrReq		,
		MtDdrWrBusy				=> MtDdrWrBusy		,
		MtDdrWrAddr				=> MtDdrWrAddr		,
		-- Fifo	
		WrFfRdEn				=> WrFfRdEn			,
		WrFfRdData				=> WrFfRdData		,
		WrFfRdCnt				=> WrFfRdCnt		,
		
		-- Master Port	
		MtAddress				=> MtWrAddress		,
		MtRead					=> MtWrRead			,
		MtWrite					=> MtWrWrite		,
		MtByteEnable			=> MtWrByteEnable	,
		MtReadData				=> MtWrReadData		,
		MtReadDataValid			=> MtWrReadDataValid,
		MtWriteData				=> MtWrWriteData	,
		MtBurstCount			=> MtWrBurstCount	,
		MtWaitRequest			=> MtWrWaitRequest
	);	
	
	u_MtDdrRd : MtDdrRd	
	Port map	
	(	
		RstB					=> UserRstB			,
		Clk						=> UserClk			,
		
		-- Command I/F	
		MtDdrRdReq				=> MtDdrRdReq		,
		MtDdrRdBusy				=> MtDdrRdBusy		,
		MtDdrRdAddr				=> MtDdrRdAddr		,
		-- Fifo	
		RdFfWrEn				=> RdFfWrEn			,
		RdFfWrData				=> RdFfWrData		,
		RdFfWrCnt				=> RdFfWrCnt		,
		
		-- Master Port	
		MtAddress				=> MtRdAddress		,
		MtRead					=> MtRdRead			,
		MtWrite					=> MtRdWrite		,
		MtByteEnable			=> MtRdByteEnable	,
		MtReadData				=> MtRdReadData		,
		MtReadDataValid			=> MtRdReadDataValid,
		MtWriteData				=> MtRdWriteData	,
		MtBurstCount			=> MtRdBurstCount	,
		MtWaitRequest			=> MtRdWaitRequest
	);
	
End Architecture rtl;
