//----------------------------------------------------------------------//
//
//	Copyright (c) 2020 BeeBeans Technologies All rights reserved
//
//		System		: KC705
//
//		Module		: KC705_SiTCP_XG_EEPROM
//
//		Description	: SiTCPXG(10GbE SiTCP) test bench on KC705
//
//		file		: KC705_SiTCP_XG_EEPROM.v
//
//		Note	: 
//
//		history	:
//			20200917	Ver 1.1		---------	Created by BBT
//
//----------------------------------------------------------------------//
//DIP SWはソースとボードで数字が反転している
//実機DIP SW4→ソースDIP SW0

module
	KC705_SiTCP_XG_EEPROM(
	// System
		input			USER_CLOCK_P		,	// in	: 156.25MHz
		input			USER_CLOCK_N		,	// in	: 156.25MHz
		output			USER_SMA_GPIO_P		,	// out	: 156.25MHz
		output			USER_SMA_GPIO_N		,	// out	: 156.25MHz
		input			CPU_RESET			,	// in	: System reset
	// SFP+
		output			SFP_TX_DISABLE		,	
		input			SFP_RX_N			,	
		input			SFP_RX_P			,	
		output			SFP_TX_N			,	
		output			SFP_TX_P			,	
		input			SMA_MGT_REF_CLK_P	,	
		input			SMA_MGT_REF_CLK_N	,	
	//connect EEPROM
		inout			I2C_SDA				,	
		output			I2C_SCL				,	
	// SW, LED
		input			GPIO_SW_S			,	// in	: Push Switch
		input	[3:0]	GPIO_DIP_SW			,	// in	: SW[3:0]
		output	[7:0]	GPIO_LED				// out	: LED[7:0]
	);

	wire	[31:0]	REG_FPGA_VER	;
	wire	[31:0]	REG_FPGA_ID		;

	wire			userClk			;
	wire			CLK156M			;
	reg		[7:0]	resetCntr		;
	wire			SYSRST			;
	wire			RST_EEPROM		;
	wire			EEPROM_CS		;
	wire			EEPROM_SK		;
	wire			EEPROM_DI		;
	wire			EEPROM_DO		;

	wire			SiTCPXG_OPEN_REQ	;
	wire			SiTCPXG_ESTABLISHED	;
	wire			SiTCPXG_CLOSE_REQ	;
	wire			SiTCPXG_CLOSE_ACK	;
	wire			SiTCPXG_TX_AFULL	;
	wire	[63:0]	SiTCPXG_TX_D		;
	wire	[3:0]	SiTCPXG_TX_B		;
	wire	[15:0]	SiTCPXG_RX_SIZE		;
	wire			SiTCPXG_RX_CLR_ENB	;
	wire			SiTCPXG_RX_CLR_REQ	;
	wire	[15:0]	SiTCPXG_RX_RADR		;
	wire	[15:0]	SiTCPXG_RX_WADR		;
	wire	[ 7:0]	SiTCPXG_RX_WENB		;
	wire	[63:0]	SiTCPXG_RX_WDAT		;

	wire	[63:0]	xgmii_rxd	;
	wire	[7:0]	xgmii_rxc	;
	wire	[7:0]	xgmii_txc		;
	wire	[63:0]	xgmii_txd		;

	wire			SiTCP_RESET		;
	wire	[31:0]	RBCP_ADDR		;
	wire			RBCP_WE			;
	wire	[7:0]	RBCP_WD			;
	wire			RBCP_RE			;
	wire			RBCP_ACK		;
	wire	[7:0]	RBCP_RD			;

	wire			RBCP_LOOPBACK	;
	wire			RBCP_SEL_SEQ	;
	wire			RBCP_DATA_GEN	;
	wire	[ 7:0]	RBCP_TX_RATE	;
	wire	[23:0]	RBCP_BLK_SIZE	;
	wire	[31:0]	RBCP_SEQ_PTN	;
	wire	[63:0]	RBCP_NUM_OF_DAT	;

	wire			XGMII_MDC		;
	wire			MIF_MDIO_OUT	;
	wire			XGMII_MDIO		;
	wire			XGMII_MDIO_TRI	;
	wire			XGMII_MDIO_OUT	;

	wire			intSfpTxDisable ;

	reg 	[25:0]	tgbeCnt;
	reg		[23:0]	tx_count;
	reg		[ 2:0]	rx_high;
	reg		[ 2:0]	rx_low;
	reg		[ 3:0]	rx_up;
	reg		[23:0]	rx_count;

    wire    [3:0]   DEBUG_UDP       ;


    assign  REG_FPGA_VER[31:0]      = 32'h2009_2301;    // Build date
    assign  REG_FPGA_ID[31:0]       = 32'h0000_0000;    // Lib ID

//------------------------------------------------------------------------------
//	Buffers
//------------------------------------------------------------------------------

	IBUFDS #(
		.DIFF_TERM		("TRUE"), // Differential Termination
		.IBUF_LOW_PWR	("FALSE"), // Low power="TRUE", Highest performance="FALSE"
		.IOSTANDARD		("LVDS_25") // Specify the input I/O standard
	) USER_CLK_IBUFDS (
		.O				(userClk), // Buffer output
		.I				(USER_CLOCK_P), // Diff_p buffer input (connect directly to top-level port)
		.IB				(USER_CLOCK_N) // Diff_n buffer input (connect directly to top-level port)
	);

	OBUFDS #(
		.IOSTANDARD		("LVDS_25"), // Specify the output I/O standard
		.SLEW			("SLOW") // Specify the output slew rate
	) USER_CLK_OBUFDS (
		.O				(USER_SMA_GPIO_P), // Diff_p output (connect directly to top-level port)
		.OB				(USER_SMA_GPIO_N), // Diff_n output (connect directly to top-level port)
		.I				(userClk) // Buffer input
	);


	always @(posedge CLK156M or posedge CPU_RESET) begin
		if(CPU_RESET)begin
			resetCntr[7:0]	<= {8{1'b1}};
		end else begin
			resetCntr[7:0]	<= resetCntr[7:0] - {7'd0,resetCntr[7]};
		end
	end

	assign	SYSRST	 = resetCntr[7];
//------------------------------------------------------------------------------
//	
//------------------------------------------------------------------------------

	AT93C46_IIC #(
		.PCA9548_AD			(7'b1110_100),				// PCA9548 Dvice Address
		.PCA9548_SL			(8'b0000_1000),				// PCA9548 Select code (Ch3,Ch4 enable)
		.IIC_MEM_AD			(7'b1010_100),				// IIC Memory Dvice Address
		.FREQUENCY			(8'd156),					// CLK_IN Frequency  > 10MHz
		.DRIVE				(4),						// Output Buffer Strength
		.IOSTANDARD			("LVCMOS25"),				// I/O Standard
		.SLEW				("SLOW")					// Outputbufer Slew rate
	)
	AT93C46_IIC(
		.CLK_IN				(CLK156M),					// System Clock
		.RESET_IN			(SYSRST),					// Reset
		.IIC_INIT_OUT		(RST_EEPROM),				// IIC , AT93C46 Initialize (0=Initialize End)
		.EEPROM_CS_IN		(EEPROM_CS),				// AT93C46 Chip select
		.EEPROM_SK_IN		(EEPROM_SK),				// AT93C46 Serial data clock
		.EEPROM_DI_IN		(EEPROM_DI),				// AT93C46 Serial write data (Master to Memory)
		.EEPROM_DO_OUT		(EEPROM_DO),				// AT93C46 Serial read data(Slave to Master)
		.INIT_ERR_OUT		(),							// PCA9548 Initialize Error
		.IIC_REQ_IN			(1'b0),						// IIC ch0 Request
		.IIC_NUM_IN			(8'h00),					// IIC ch0 Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		.IIC_DAD_IN			(7'b0),						// IIC ch0 Device Address[6:0]
		.IIC_ADR_IN			(8'b0),						// IIC ch0 Word Address[7:0]
		.IIC_RNW_IN			(1'b0),						// IIC ch0 Read(1) / Write(0)
		.IIC_WDT_IN			(8'b0),						// IIC ch0 Write Data[7:0]
		.IIC_RAK_OUT		(),							// IIC ch0 Request Acknowledge
		.IIC_WDA_OUT		(),							// IIC ch0 Wite Data Acknowledge(Next Data Request)
		.IIC_WAE_OUT		(),							// IIC ch0 Wite Last Data Acknowledge(same as IIC_WDA timing)
		.IIC_BSY_OUT		(),							// IIC ch0 Busy
		.IIC_RDT_OUT		(),							// IIC ch0 Read Data[7:0]
		.IIC_RVL_OUT		(),							// IIC ch0 Read Data Valid
		.IIC_EOR_OUT		(),							// IIC ch0 End of Read Data(same as IIC_RVL timing)
		.IIC_ERR_OUT		(),							// IIC ch0 Error Detect
		// Device Interface
		.IIC_SCL_OUT		(I2C_SCL),					// IIC Clock
		.IIC_SDA_IO			(I2C_SDA)					// IIC Data
	);

//------------------------------------------------------------------------------
//	SiTCP-XG
//------------------------------------------------------------------------------
	WRAP_SiTCPXG_XC7K_128K	#(
		.RxBufferSize				("LongLong"					)	// "Byte":8bit width ,"Word":16bit width ,"LongWord":32bit width , "LongLong":64bit width
	)
	WRAP_SiTCPXG_XC7K_128K	(
		.REG_FPGA_VER				(REG_FPGA_VER[31:0] 		),	// in	: User logic Version(For example, the synthesized date)
		.REG_FPGA_ID				(REG_FPGA_ID[31:0]  		),	// in	: User logic ID (We recommend using the lower 4 bytes of the MAC address.)
		//		==== System I/F ====
		.FORCE_DEFAULTn				(GPIO_DIP_SW[3]				),	// in	: Force to set default values
		.XGMII_CLOCK				(CLK156M					),	// in	: XGMII Clock 156.25MHz
		.RSTs						(RST_EEPROM					),	// in	: System reset (Sync.)
		//		==== XGMII I/F ====
		.XGMII_RXC					(xgmii_rxc[7:0]				),	// in	: Rx control[7:0]
		.XGMII_RXD					(xgmii_rxd[63:0]			),	// in	: Rx data[63:0]
		.XGMII_TXC					(xgmii_txc[7:0]				),	// out  : Control bits[7:0]
		.XGMII_TXD					(xgmii_txd[63:0]			), 	// out  : Data[63:0]
		//		==== 93C46 I/F ====
		.EEPROM_CS					(EEPROM_CS					),	// out	: Chip select
		.EEPROM_SK					(EEPROM_SK					),	// out	: Serial data clock
		.EEPROM_DI					(EEPROM_DI					),	// out	: Serial write data
		.EEPROM_DO					(EEPROM_DO					),	// in	: Serial read data
		//		==== User I/F ====
		.SiTCP_RESET_OUT			(SiTCP_RESET				),	// out	: System reset for user's module
		//			--- RBCP ---
		.RBCP_ACT					(RBCP_ACT					),	// out	: Indicates that bus access is active.
		.RBCP_ADDR					(RBCP_ADDR[31:0]			),	// out	: Address[31:0]
		.RBCP_WE					(RBCP_WE					),	// out	: Write enable
		.RBCP_WD					(RBCP_WD[7:0]				),	// out	: Data[7:0]
		.RBCP_RE					(RBCP_RE					),	// out	: Read enable
		.RBCP_ACK					(RBCP_ACK					),	// in	: Access acknowledge
		.RBCP_RD					(RBCP_RD[7:0]				),	// in	: Read data[7:0]
		//			--- TCP ---
		.USER_SESSION_OPEN_REQ		(SiTCPXG_OPEN_REQ			),	// in	: Request for opening the new session
		.USER_SESSION_ESTABLISHED	(SiTCPXG_ESTABLISHED		),	// out	: Establish of a session
		.USER_SESSION_CLOSE_REQ		(SiTCPXG_CLOSE_REQ			),	// out	: Request for closing session.
		.USER_SESSION_CLOSE_ACK		(SiTCPXG_CLOSE_ACK			),	// in	: Acknowledge for USER_SESSION_CLOSE_REQ.
		.USER_TX_D					(SiTCPXG_TX_D[63:0]			),	// in	: Write data
		.USER_TX_B					(SiTCPXG_TX_B[3:0]			),	// in	: Byte length of USER_TX_DATA(Set to 0 if not written)
		.USER_TX_AFULL				(SiTCPXG_TX_AFULL			),	// out	: Request to stop TX
		.USER_RX_SIZE				(SiTCPXG_RX_SIZE[15:0]		),	// in	: Receive buffer size(byte) caution:Set a value of 4000 or more and (memory size-16) or less
		.USER_RX_CLR_ENB			(SiTCPXG_RX_CLR_ENB			),	// out	: Receive buffer Clear Enable
		.USER_RX_CLR_REQ			(SiTCPXG_RX_CLR_REQ			),	// in	: Receive buffer Clear Request
		.USER_RX_RADR				(SiTCPXG_RX_RADR[15:0]		),	// in	: Receive buffer read address in bytes (unused upper bits are set to 0)
		.USER_RX_WADR				(SiTCPXG_RX_WADR[15:0]		),	// out	: Receive buffer write address in bytes (lower 3 bits are not connected to memory)
		.USER_RX_WENB				(SiTCPXG_RX_WENB[ 7:0]		),	// out	: Receive buffer byte write enable (big endian)
		.USER_RX_WDAT				(SiTCPXG_RX_WDAT[63:0]		)	// out	: Receive buffer write data (big endian)
	);
//
//	TCP Checker
//

	TCP_TEST	TCP_TEST(
		/* [System] */
		.CLK156M					(CLK156M					),	// Tx clock
		.RSTs						(SiTCP_RESET				),	// System reset
		.TX_RATE					(RBCP_TX_RATE[7:0]			),	// Transmission data rate in units of 100 Mbps
		.NUM_OF_DATA				(RBCP_NUM_OF_DAT[63:0]		),	// Number of bytes of transmitted data
		.DATA_GEN					(RBCP_DATA_GEN				),	// Data transmission enable
		.LOOPBACK					(RBCP_LOOPBACK				),	// Loopback mode
		.WORD_LEN					(GPIO_DIP_SW[2:0]			),	// Word length of test data
		.SELECT_SEQ					(RBCP_SEL_SEQ				),	// Selection of sequence data
		.SEQ_PATTERN				(RBCP_SEQ_PTN[31:0]			),	// sequence data(The default value is 0x60808040)
		.BLK_SIZE					(RBCP_BLK_SIZE[23:0]		),	// Transmission block size in bytes
		.INS_ERROR					(GPIO_SW_S					),	// Data error insertion
		/* [SiTCP-XG I/F] */
		.SiTCPXG_ESTABLISHED		(SiTCPXG_ESTABLISHED		),	// Establish of a session
		.SiTCPXG_RX_SIZE			(SiTCPXG_RX_SIZE[15:0]		),	// Receive buffer size(byte) caution:Set a value of 4000 or more and (memory size-16) or less
		.SiTCPXG_RX_CLR_ENB			(SiTCPXG_RX_CLR_ENB			),	// Receive buffer Clear Enable
		.SiTCPXG_RX_CLR_REQ			(SiTCPXG_RX_CLR_REQ			),	// Receive buffer Clear Request
		.SiTCPXG_RX_RADR			(SiTCPXG_RX_RADR[15:0]		),	// Receive buffer read address in bytes (unused upper bits are set to 0)
		.SiTCPXG_RX_WADR			(SiTCPXG_RX_WADR[15:0]		),	// Receive buffer write address in bytes (lower 3 bits are not connected to memory)
		.SiTCPXG_RX_WENB			(SiTCPXG_RX_WENB[ 7:0]		),	// Receive buffer byte write enable (big endian)
		.SiTCPXG_RX_WDAT			(SiTCPXG_RX_WDAT[63:0]		),	// Receive buffer write data (big endian)
		.SiTCPXG_TX_AFULL			(SiTCPXG_TX_AFULL			),	// TX fifo, almost full
		.SiTCPXG_TX_D				(SiTCPXG_TX_D[63:0]			),	// Tx data[63:0]
		.SiTCPXG_TX_B				(SiTCPXG_TX_B[3:0]			)	// Byte length of USER_TX_DATA(Set to 0 if not written)
	);

	RBCP_TEST			RBCP_TEST(
		// System
		.CLK						(CLK156M					),	// in	 : XGMII Rx clock 157MHz
		.RSTs						(RST_EEPROM					),	// in	 : System reset
		.REG_FPGA_VER				(REG_FPGA_VER[31:0]			),
		// Processor I/F
		.LOC_ADDR					(RBCP_ADDR[31:0]			),	// in	 : Address[31:0]
		.LOC_WE						(RBCP_WE					),	// in	 : Write enable
		.LOC_WD						(RBCP_WD[7:0]				),	// in	 : Write data[7:0]
		.LOC_RE						(RBCP_RE					),	// in	 : Read enable
		.LOC_ACK					(RBCP_ACK					),	// out	 : Read valid
		.LOC_RD						(RBCP_RD[7:0]				),	// out   : Read data[7:0]
		.SiTCPXG_OPEN_REQ			(SiTCPXG_OPEN_REQ			),	// Request for opening the new session
		.SiTCPXG_ESTABLISHED		(SiTCPXG_ESTABLISHED		),	// Establish of a session
		.SiTCPXG_CLOSE_REQ			(SiTCPXG_CLOSE_REQ			),	// Request for closing session.
		.SiTCPXG_CLOSE_ACK			(SiTCPXG_CLOSE_ACK			),	// Acknowledge for USER_SESSION_CLOSE_REQ.
		.LOOPBACK					(RBCP_LOOPBACK				),	// Loopback mode
		.SELECT_SEQ					(RBCP_SEL_SEQ				),	// Selection of sequence data
		.DATA_GEN					(RBCP_DATA_GEN				),	// Data transmission e nable
		.TX_RATE					(RBCP_TX_RATE[7:0]			),	// Transmission data rate in units of 100 Mbps
		.BLK_SIZE					(RBCP_BLK_SIZE[23:0]		),	// Transmission block size in bytes
		.SEQ_PATTERN				(RBCP_SEQ_PTN[31:0]			),	// sequence data(The default value is 0x60808040)
		.NUM_OF_DATA				(RBCP_NUM_OF_DAT[63:0]		)	// Number of bytes of transmitted data
	);

//------------------------------------------------------------------------------
//	10GbE PCS/PMA
//------------------------------------------------------------------------------

	assign	SFP_TX_DISABLE	= ~intSfpTxDisable;

	wire			drp_req;
	wire	[15:0]	drp_daddr;
	wire			drp_den;
	wire	[15:0]	drp_di;
	wire	[15:0]	drp_drpdo;
	wire			drp_drdy;
	wire			drp_dwe;

	ten_gig_eth_pcs_pma		ten_gig_eth_pcs_pma	(
		.refclk_p					(SMA_MGT_REF_CLK_P			),	// input wire refclk_p
		.refclk_n					(SMA_MGT_REF_CLK_N			),	// input wire refclk_n
		.reset						(RST_EEPROM					),	// input wire reset
		.coreclk_out				(CLK156M					),	// output wire coreclk_out
		.txp						(SFP_TX_P					),	// output wire txp
		.txn						(SFP_TX_N					),	// output wire txn
		.rxp						(SFP_RX_P					),	// input wire rxp
		.rxn						(SFP_RX_N					),	// input wire rxn
		.xgmii_txd					(xgmii_txd[63:0]			),	// input wire [63 : 0] xgmii_txd
		.xgmii_txc					(xgmii_txc[7:0]				),	// input wire [7 : 0] xgmii_txc
		.xgmii_rxd					(xgmii_rxd[63:0]			),	// output wire [63 : 0] xgmii_rxd
		.xgmii_rxc					(xgmii_rxc[7:0]				),	// output wire [7 : 0] xgmii_rxc
// MDIO
		.mdc						(1'b1						),	// input wire mdc
		.mdio_in					(1'b1						),	// input wire mdio_in
		.mdio_out					(							),	// output wire mdio_out
		.mdio_tri					(							),	// output wire mdio_tri
		.prtad						(5'd0						),	// input wire [4 : 0] prtad
// SPF+ I/F
		.signal_detect				(1'b1						),	// input wire signal_detect
		.tx_fault					(1'b0						),	// input wire tx_fault
		.tx_disable					(intSfpTxDisable			),	// output wire tx_disable
// drp_interface_ports
		.dclk						(CLK156M					),	// input wire dclk	<DRP clock 156MHz>
		.drp_req					(drp_req					),	// output wire drp_req
		.drp_gnt					(drp_req					),	// input wire drp_gnt
// core_gt_drp_interface
		.drp_daddr_i				(drp_daddr[15:0]			),	// input wire [15 : 0] drp_daddr_i
		.drp_den_i					(drp_den					),	// input wire drp_den_i
		.drp_di_i					(drp_di[15:0]				),	// input wire [15 : 0] drp_di_i
		.drp_drpdo_o				(drp_drpdo[15:0]			),	// output wire [15 : 0] drp_drpdo_o
		.drp_drdy_o					(drp_drdy					),	// output wire drp_drdy_o
		.drp_dwe_i					(drp_dwe					),	// input wire drp_dwe_i
// core_gt_drp_interface
		.drp_daddr_o				(drp_daddr[15:0]			),	// output wire [15 : 0] drp_daddr_o
		.drp_den_o					(drp_den					),	// output wire drp_den_o
		.drp_di_o					(drp_di[15:0]				),	// output wire [15 : 0] drp_di_o
		.drp_drpdo_i				(drp_drpdo[15:0]			),	// input wire [15 : 0] drp_drpdo_i
		.drp_drdy_i					(drp_drdy					),	// input wire drp_drdy_i
		.drp_dwe_o					(drp_dwe					),	// output wire drp_dwe_o
//Miscellaneous port
		.core_status				(							),	// output wire [7 : 0] core_status
		.sim_speedup_control		(1'b0						),	// input wire sim_speedup_control
		.pma_pmd_type				(3'b111						),	// input wire [2 : 0] pma_pmd_type
		.resetdone_out				(							),	// output wire resetdone_out
		.rxrecclk_out				(							),	// output wire rxrecclk_out
		.txusrclk_out				(							),	// output wire txusrclk_out
		.txusrclk2_out				(							),	// output wire txusrclk2_out
		.areset_datapathclk_out		(							),	// output wire areset_datapathclk_out
		.gttxreset_out				(							),	// output wire gttxreset_out
		.gtrxreset_out				(							),	// output wire gtrxreset_out
		.txuserrdy_out				(							),	// output wire txuserrdy_out
		.reset_counter_done_out		(							),	// output wire reset_counter_done_out
		.qplllock_out				(							),	// output wire qplllock_out
		.qplloutclk_out				(							),	// output wire qplloutclk_out
		.qplloutrefclk_out			(							)	// output wire qplloutrefclk_out
	);


	always @(posedge CLK156M or posedge SiTCP_RESET) begin
		if(SiTCP_RESET)begin
			tgbeCnt[25:0] <= 25'd0;
		end else begin
			tgbeCnt[25:0] <= tgbeCnt[25:0] + 26'd1;
		end
	end

	always @(posedge CLK156M ) begin
		tx_count[23:0]	<= SiTCPXG_ESTABLISHED?		(tx_count[23:0] + (tx_count[23]?	25'd1:		{20'd0,SiTCPXG_TX_B[3:0]})):	24'd0;
		rx_high[2]	<= (SiTCPXG_RX_WENB[7:4] == 4'b1111);
		rx_high[1]	<= (
			(SiTCPXG_RX_WENB[7:4] == 4'b0111)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1011)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1101)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1110)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1100)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1010)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1001)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0110)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0101)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0011)
		);
		rx_high[0]	<= (
			(SiTCPXG_RX_WENB[7:4] == 4'b0111)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1011)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1101)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1110)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1000)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0100)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0010)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0001)
		);
		rx_low[2]	<= (SiTCPXG_RX_WENB[3:0] == 4'b1111);
		rx_low[1]	<= (
			(SiTCPXG_RX_WENB[3:0] == 4'b0111)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1011)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1101)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1110)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1100)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1010)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1001)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0110)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0101)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0011)
		);
		rx_low[0]	<= (
			(SiTCPXG_RX_WENB[3:0] == 4'b0111)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1011)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1101)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1110)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1000)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0100)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0010)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0001)
		);
		rx_up[3:0]	<= {1'b0,rx_high[2:0]} + {1'b0,rx_low[2:0]};
		rx_count[23:0]	<= SiTCPXG_ESTABLISHED?		(rx_count[23:0] + (rx_count[23]?	24'd1:		{20'd0,rx_up[3:0]})):	24'd0;
	end

	assign	GPIO_LED[0] = SiTCP_RESET;
	assign	GPIO_LED[1] = tgbeCnt[25];
	assign	GPIO_LED[2] = SiTCPXG_ESTABLISHED;
	assign	GPIO_LED[3] = tx_count[23];
	assign	GPIO_LED[4] = rx_count[23];
	assign	GPIO_LED[7:5] = 3'd0;


endmodule
