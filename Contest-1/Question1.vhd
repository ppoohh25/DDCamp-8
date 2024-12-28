----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     Question1.vhd
-- Title        Top
--
-- Company      Design Gateway Co., Ltd.
-- Project      DDCamp
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      2.00
-- Author       J.Natthapat
-- Date         2018/12/1
-- Remark       Add DipSwitch to select pattern (Vertical Color Bar, Horizontal Color Bar, Red Screen, and Blue Screen   )

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

Entity Question1 Is
	Port
	(
		RstB			: in	std_logic;							-- use push button Key0 (active low)
		Clk50			: in	std_logic;							-- clock input 50 MHz
		Button			: in	std_logic;			-- use push button Key1 (active low)
		
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
		DDR3_WE_n		: out	std_logic_vector( 0 downto 0 );
		
		-- HDMI Interface
		HDMI_TX_INT		: in	std_logic;
		HDMI_I2C_SCL	: out	std_logic;
		HDMI_I2C_SDA	: inout	std_logic;
		HDMI_TX_CLK		: out	std_logic;
		HDMI_TX_D		: out	std_logic_vector( 23 downto 0 );
		HDMI_TX_DE		: out	std_logic;
		HDMI_TX_HS		: out	std_logic;
		HDMI_TX_VS		: out	std_logic;
		
		-- Basic IO Interface
		LED				: out	std_logic_vector( 7 downto 0 );		-- active low LED (show status)
		DipSwitch		: in 	std_logic_vector( 1 downto 0 )		-- DipSwitch select TestPatt
	);
End Entity Question1;

Architecture rtl Of Question1 Is

----------------------------------------------------------------------------------
-- Component declaration
----------------------------------------------------------------------------------
	
	Component PLL50 Is
	Port 
	(
		areset			: in	std_logic  := '0';
		inclk0			: in	std_logic  := '0';
		c0				: out	std_logic;
		locked			: out	std_logic 
	);
	End Component PLL50;
	
	Component fifo256x32to64
	Port
	(
		aclr			: in	std_logic  := '0';
		
		wrclk			: in	std_logic;
		wrreq			: in	std_logic;
		data			: in	std_logic_vector( 31 downto 0 );
		wrfull			: out	std_logic;
		wrusedw			: out	std_logic_vector( 7 downto 0 );
		
		rdclk			: in	std_logic;
		rdreq			: in	std_logic;
		q				: out	std_logic_vector( 63 downto 0 );
		rdempty			: out	std_logic;
		rdusedw			: out	std_logic_vector( 6 downto 0 )
	);
	End Component fifo256x32to64;
	
	Component fifo256x64to32
	Port
	(
		aclr			: in	std_logic  := '0';
		
		wrclk			: in	std_logic;
		wrreq			: in	std_logic;
		data			: in	std_logic_vector( 63 downto 0 );
		wrfull			: out	std_logic;
		wrusedw			: out	std_logic_vector( 6 downto 0 );
		
		rdclk			: in	std_logic;
		rdreq			: in	std_logic;
		q				: out	std_logic_vector( 31 downto 0 );
		rdempty			: out	std_logic;
		rdusedw			: out	std_logic_vector( 7 downto 0 )
	);
	End Component fifo256x64to32;
	
	Component TestPatt Is
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
	End Component TestPatt;
	
	Component UserWrDdr Is
	Port
	(
		RstB			: in	std_logic;							-- use push button Key0 (active low)
		Clk				: in	std_logic;							-- clock input 100 MHz
		
		-- WrCtrl I/F
		MemInitDone		: in	std_logic;
		MtDdrWrReq		: out	std_logic;
		MtDdrWrBusy		: in	std_logic;
		MtDdrWrAddr		: out	std_logic_vector( 28 downto 7 );
		
		-- T2UWrFf I/F
		T2UWrFfRdEn		: out	std_logic;
		T2UWrFfRdData	: in	std_logic_vector( 63 downto 0 );
		T2UWrFfRdCnt	: in	std_logic_vector( 15 downto 0 );
		
		-- UWr2DFf I/F
		UWr2DFfRdEn		: in	std_logic;
		UWr2DFfRdData	: out	std_logic_vector( 63 downto 0 );
		UWr2DFfRdCnt	: out	std_logic_vector( 15 downto 0 )
	);
	End Component UserWrDdr;

	Component UserRdDdr Is
	Port
	(
		RstB			: in	std_logic;							-- use push button Key0 (active low)
		Clk				: in	std_logic;							-- clock input 100 MHz

		DipSwitch		: in 	std_logic_vector( 1 downto 0 );

		-- HDMICtrl I/F
		HDMIReq			: out	std_logic;
		HDMIBusy		: in	std_logic;
		
		-- RdCtrl I/F
		MemInitDone		: in	std_logic;
		MtDdrRdReq		: out	std_logic;
		MtDdrRdBusy		: in	std_logic;
		MtDdrRdAddr		: out	std_logic_vector( 28 downto 7 );
		
		-- D2URdFf I/F
		D2URdFfWrEn		: in	std_logic;
		D2URdFfWrData	: in	std_logic_vector( 63 downto 0 );
		D2URdFfWrCnt	: out	std_logic_vector( 15 downto 0 );
		
		-- URd2HFf I/F
		URd2HFfWrEn		: out	std_logic;
		URd2HFfWrData	: out	std_logic_vector( 63 downto 0 );
		URd2HFfWrCnt	: in	std_logic_vector( 15 downto 0 )
	);
	End Component UserRdDdr;
	
	Component MtDdr Is
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
	End Component MtDdr;
	
	Component HDMI Is
	Port
	(
		RstB			: in	std_logic;							-- use push button Key0 (active low)
		Clk				: in	std_logic;							-- clock input 100 MHz
		
		-- User Control Interface
		HDMIReq			: in	std_logic;
		HDMIBusy		: out	std_logic;							-- HDMI Busy
		HDMIStatus		: out	std_logic_vector( 1 downto 0 );		-- [1] Error Flag for HDMI Data path
																	-- [0] Busy Flag for HDMI I2C Config
		HDMIUserClk		: out	std_logic;
		
		-- User Data Interface
		HDMIFfRdEn		: out	std_logic;
		HDMIFfRdData	: in	std_logic_vector( 23 downto 0 );
		HDMIFfEmpty		: in	std_logic;
		HDMIFfRdCnt		: in	std_logic_vector( 15 downto 0 );
		
		-- HDMI Control Interface
		HDMI_TX_INT		: in	std_logic;
		HDMI_I2C_SCL	: out	std_logic;
		HDMI_I2C_SDA	: inout	std_logic;
		
		-- HDMI Data Interface
		HDMI_TX_CLK		: out	std_logic;
		HDMI_TX_D		: out	std_logic_vector( 23 downto 0 );
		HDMI_TX_DE		: out	std_logic;
		HDMI_TX_HS		: out	std_logic;
		HDMI_TX_VS		: out	std_logic
	);
	End Component HDMI;
	
----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	-- Reset System
	-- Clk50
	signal	rPLL50RstBCnt	: std_logic_vector( 3 downto 0 ) := "0000";
	signal	PLL50Rst		: std_logic;
	signal	PLLLock			: std_logic;
	
	-- UserClk
	signal	UserClk			: std_logic;
	signal	rPLLLockUser	: std_logic_vector( 1 downto 0 );
	signal	rSysRstB		: std_logic;
	signal	SysRst			: std_logic;
	signal	rRstBCnt		: std_logic_vector( 22 downto 0 ) := (others=>'0');	
	signal	rRstBUser		: std_logic;
	signal	rDipSw			: std_logic_vector( 1 downto 0 );

	-- Debounce
	signal	rButtonCnt		: std_logic_vector( 22 downto 0 );
	signal	rButtonCnt22	: std_logic_vector( 1 downto 0 );
	signal	rButtonPulse	: std_logic;
	
	-- T2UWrFf
	signal	T2UWrFfWrEn		: std_logic; 
	signal	T2UWrFfWrData	: std_logic_vector( 31 downto 0 );
	signal	T2UWrFfWrCnt	: std_logic_vector( 15 downto 0 );
	signal	T2UWrFfRdEn		: std_logic; 
	signal	T2UWrFfRdData	: std_logic_vector( 63 downto 0 );
	signal	T2UWrFfRdCnt	: std_logic_vector( 15 downto 0 );
	
	-- UWr2DFf
	signal	UWr2DFfRdEn		: std_logic;
	signal	UWr2DFfRdData	: std_logic_vector( 63 downto 0 );
	signal	UWr2DFfRdCnt	: std_logic_vector( 15 downto 0 );
	
	-- WrCtrl I/F
	signal	MtDdrWrReq		: std_logic;
	signal	MtDdrWrBusy		: std_logic;
	signal	MtDdrWrAddr		: std_logic_vector( 28 downto 7 );
	
	-- D2URdFf
	signal	D2URdFfWrEn		: std_logic;
	signal	D2URdFfWrData	: std_logic_vector( 63 downto 0 );
	signal	D2URdFfWrCnt	: std_logic_vector( 15 downto 0 );
	
	-- RdCtrl I/F
	signal	MtDdrRdReq		: std_logic;
	signal	MtDdrRdBusy		: std_logic;
	signal	MtDdrRdAddr		: std_logic_vector( 28 downto 7 );
	
	-- URd2HFf I/F
	signal	URd2HFfWrEn		: std_logic;
	signal	URd2HFfWrData	: std_logic_vector( 63 downto 0 );
	signal	URd2HFfWrCnt	: std_logic_vector( 15 downto 0 );
	signal	URd2HFfRdEn		: std_logic;
	signal	URd2HFfRdData	: std_logic_vector( 31 downto 0 );
	signal	URd2HFfEmpty	: std_logic;
	signal	URd2HFfRdCnt	: std_logic_vector( 15 downto 0 );
	
	-- HDMI I/F
	signal	HDMIReq			: std_logic;
	signal	HDMIBusy		: std_logic;
	signal	HDMIUserClk		: std_logic;
	
	-- Status LED
	signal	MemInitDone		: std_logic;
	signal	HDMIStatus		: std_logic_vector( 1 downto 0 );
	
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------

	-- LED Status
	LED(0)			<= not HDMIStatus(0);	-- Busy Flag for HDMI I2C Config
	LED(1)			<= not HDMIStatus(1);	-- Error Flag for HDMI Data path
	LED(2)			<= not HDMIBusy;		-- Error Flag for HDMI Data path
	LED(3)			<= not HDMI_TX_INT;		-- Interrupt from HDMI
	LED(4)			<= not MemInitDone;		-- MtDdr Initial done
	
	LED(7 downto 5)	<= (others=>'1');		-- not used

	
----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------

-----------------------------------------------------
-- Power on Reset
	
	u_rPLL50RstBCnt : Process (Clk50) Is
	Begin
		if ( rising_edge(Clk50) ) then
			rPLL50RstBCnt	<= rPLL50RstBCnt(2 downto 0) & '1';
		end if;
	End Process u_rPLL50RstBCnt;
	
	PLL50Rst	<= not rPLL50RstBCnt(3);

	u_PLL50 : PLL50
	Port map
	(
		areset		=> PLL50Rst			,
		inclk0		=> Clk50			,
		c0			=> UserClk			, -- UserClk: 100 MHz	
		locked		=> PLLLock
	);
	
	u_rRstBCnt : Process (Clk50) Is
	Begin
		if ( rising_edge(Clk50) ) then
			if ( RstB='0' ) then
				rRstBCnt	<= (others=>'0');
			else
				if ( rRstBCnt(22)='1' ) then
					rRstBCnt	<= rRstBCnt;
				else
					rRstBCnt	<= rRstBCnt + 1;
				end if;
			end if;
		end if;
	End Process u_rRstBCnt;
	
	u_rSysRstB : Process (UserClk) Is
	Begin
		if ( rising_edge(UserClk) ) then
			rPLLLockUser	<= rPLLLockUser(0) & PLLLock;
			rRstBUser		<= rRstBCnt(22);	
			rSysRstB		<= rPLLLockUser(1) and rRstBUser;
		end if;
	End Process u_rSysRstB;
	
	SysRst		<= not rSysRstB;
	
	u_rDipSw : Process (UserClk) Is
	Begin
		if ( rising_edge(UserClk) ) then
			rDipSw		<= DipSwitch;
		end if;
	End Process u_rDipSw;

-----------------------------------------------------
-- Debounce Button

	u_rButtonCnt : Process (UserClk) Is
	Begin
		if ( rising_edge(UserClk) ) then
			if ( rSysRstB='0' ) then
				rButtonCnt	<= (others=>'0');
			else
				if ( Button='0' ) then
					if ( rButtonCnt(22)='1' ) then
						rButtonCnt	<= rButtonCnt;
					else
						rButtonCnt	<= rButtonCnt + 1;
					end if;
				else
					rButtonCnt	<= (others=>'0');
				end if;
			end if;
		end if;
	End Process u_rButtonCnt;

	u_rButtonCnt22 : Process (UserClk) Is
	Begin
		if ( rising_edge(UserClk) ) then
			if ( rSysRstB='0' ) then
				rButtonCnt22	<= "00";
			else
				rButtonCnt22	<= rButtonCnt22(0) & rButtonCnt(22);
			end if;
		end if;
	End Process u_rButtonCnt22;

	u_rButtonPulse : Process (UserClk) Is
	Begin
		if ( rising_edge(UserClk) ) then
			if ( rSysRstB='0' ) then
				rButtonPulse	<= '0';
			else
				if ( rButtonCnt22(1 downto 0)="01" ) then
					rButtonPulse	<= '1';
				else
					rButtonPulse	<= '0';
				end if;
			end if;
		end if;
	End Process u_rButtonPulse;
	
-----------------------------------------------------
-- RxSerial

	u_TestPatt : TestPatt
	Port map
	(
		RstB			=> rSysRstB			,
		Clk				=> UserClk			,
		
		Start			=> rButtonPulse		, 
		DipSwitch		=> rDipSw			,
		
		HDMIFfWrEn		=> T2UWrFfWrEn		,
		HDMIFfWrData	=> T2UWrFfWrData(23 downto 0)	,
		HDMIFfWrCnt		=> T2UWrFfWrCnt
	);
	
	T2UWrFfWrData(31 downto 24)	<= (others=>'0');
	
	-- Fill Fifo count 
	T2UWrFfWrCnt(15 downto 8)	<= (others=>'1');
	T2UWrFfRdCnt(15 downto 7)	<= (others=>'0');
	
	-- Fifo TestPatt -> UserWrDdr -> MtDdr
	u_T2UWrFf : fifo256x32to64
	Port map
	(
		aclr			=> SysRst			,
		
		wrclk			=> UserClk			,
		wrreq			=> T2UWrFfWrEn		,
		data			=> T2UWrFfWrData	,
		wrfull			=> open				,
		wrusedw			=> T2UWrFfWrCnt(7 downto 0),
		
		rdclk			=> UserClk			,
		rdreq			=> T2UWrFfRdEn		,
		q				=> T2UWrFfRdData	,
		rdempty			=> open				,
		rdusedw			=> T2UWrFfRdCnt(6 downto 0)
	);
	
	u_UserWrDdr : UserWrDdr
	Port map
	(
		RstB			=> rSysRstB			,
		Clk				=> UserClk			,

		-- WrCtrl I/F
		MemInitDone		=> MemInitDone		,
		MtDdrWrReq		=> MtDdrWrReq		,
		MtDdrWrBusy		=> MtDdrWrBusy		,
		MtDdrWrAddr		=> MtDdrWrAddr		,

		-- T2UWrFf I/F
		T2UWrFfRdEn		=> T2UWrFfRdEn		,
		T2UWrFfRdData	=> T2UWrFfRdData	,
		T2UWrFfRdCnt	=> T2UWrFfRdCnt		,

		-- UWr2DFf I/F
		UWr2DFfRdEn		=> UWr2DFfRdEn		,
		UWr2DFfRdData	=> UWr2DFfRdData	,
		UWr2DFfRdCnt	=> UWr2DFfRdCnt
	);
	
	-- DDR Interface
	u_MtDdr : MtDdr
    Port map
	(
		UserRstB		=> rSysRstB			,
		UserClk			=> UserClk			,

		MemInitDone		=> MemInitDone		,
		
		MtDdrWrReq		=> MtDdrWrReq		,
		MtDdrWrBusy		=> MtDdrWrBusy		,
		MtDdrWrAddr		=> MtDdrWrAddr		,
		
		WrFfRdEn		=> UWr2DFfRdEn		,
		WrFfRdData		=> UWr2DFfRdData	,
		WrFfRdCnt		=> UWr2DFfRdCnt		,
		
		MtDdrRdReq		=> MtDdrRdReq		,
		MtDdrRdBusy		=> MtDdrRdBusy		,
		MtDdrRdAddr		=> MtDdrRdAddr		,
		
		RdFfWrEn		=> D2URdFfWrEn		,
		RdFfWrData		=> D2URdFfWrData	,
		RdFfWrCnt		=> D2URdFfWrCnt		,
		
		DDR3_A			=> DDR3_A			,
		DDR3_BA			=> DDR3_BA			,
		DDR3_CAS_n		=> DDR3_CAS_n		,
		DDR3_CK_n		=> DDR3_CK_n		,
		DDR3_CK_p		=> DDR3_CK_p		,
		DDR3_CKE		=> DDR3_CKE			,
		DDR3_CLK_50		=> DDR3_CLK_50		,
		DDR3_CS_n		=> DDR3_CS_n		,
		DDR3_DM			=> DDR3_DM			,
		DDR3_DQ			=> DDR3_DQ			,
		DDR3_DQS_n		=> DDR3_DQS_n		,
		DDR3_DQS_p		=> DDR3_DQS_p		,
		DDR3_ODT		=> DDR3_ODT			,
		DDR3_RAS_n		=> DDR3_RAS_n		,
		DDR3_RESET_n	=> DDR3_RESET_n		,
		DDR3_WE_n		=> DDR3_WE_n		
	);
	
	u_UserRdDdr : UserRdDdr
	Port map
	(
		RstB			=> rSysRstB			,
		Clk				=> UserClk			,

		DipSwitch		=> rDipSw			,
		
		-- HDMICtrl I/F
		MemInitDone		=> MemInitDone		,
		HDMIReq			=> HDMIReq			,
		HDMIBusy		=> HDMIBusy			,

		-- RdCtrl I/F
		MtDdrRdReq		=> MtDdrRdReq		,
		MtDdrRdBusy		=> MtDdrRdBusy		,
		MtDdrRdAddr		=> MtDdrRdAddr		,

		-- D2URdFf I/F
		D2URdFfWrEn		=> D2URdFfWrEn		,
		D2URdFfWrData	=> D2URdFfWrData	,
		D2URdFfWrCnt	=> D2URdFfWrCnt		,

		-- URd2HFf I/F
		URd2HFfWrEn		=> URd2HFfWrEn		,
		URd2HFfWrData	=> URd2HFfWrData	,
		URd2HFfWrCnt	=> URd2HFfWrCnt
	);
	
	-- Fill Fifo count 
	URd2HFfWrCnt(15 downto 7)	<= (others=>'1');
	URd2HFfRdCnt(15 downto 8)	<= (others=>'0');
	
	-- Fifo MtDdr -> UserRdDdr -> HDMI
	u_URd2HFf : fifo256x64to32
	Port map
	(
		aclr			=> SysRst			,
		
		wrclk			=> UserClk			,
		wrreq			=> URd2HFfWrEn		,
		data			=> URd2HFfWrData	,
		wrfull			=> open				,
		wrusedw			=> URd2HFfWrCnt(6 downto 0),
		
		rdclk			=> HDMIUserClk		,
		rdreq			=> URd2HFfRdEn		,
		q				=> URd2HFfRdData	,
		rdempty			=> URd2HFfEmpty		,
		rdusedw			=> URd2HFfRdCnt(7 downto 0)
	);
	
	-- HDMI Display interface
	u_HDMI : HDMI
	Port map
	(
		RstB			=> rSysRstB			,
		Clk				=> UserClk			,
		
		HDMIReq			=> HDMIReq			,
		HDMIBusy		=> HDMIBusy			,
		HDMIStatus		=> HDMIStatus		,
		HDMIUserClk		=> HDMIUserClk		,
		
		HDMIFfRdEn		=> URd2HFfRdEn		,
		HDMIFfRdData	=> URd2HFfRdData(23 downto 0),
		HDMIFfEmpty		=> URd2HFfEmpty		,
		HDMIFfRdCnt		=> URd2HFfRdCnt		,
		
		HDMI_TX_INT		=> HDMI_TX_INT		,
		HDMI_I2C_SCL	=> HDMI_I2C_SCL		,
		HDMI_I2C_SDA	=> HDMI_I2C_SDA		,
		
		HDMI_TX_CLK		=> HDMI_TX_CLK		,
		HDMI_TX_D		=> HDMI_TX_D		,
		HDMI_TX_DE		=> HDMI_TX_DE		,
		HDMI_TX_HS		=> HDMI_TX_HS		,
		HDMI_TX_VS		=> HDMI_TX_VS
	);
	
End Architecture rtl;