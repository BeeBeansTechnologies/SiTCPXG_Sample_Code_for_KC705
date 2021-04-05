/*******************************************************************************
*                                                                              *
* System      : Spartan3E starter kit                                          *
* Block       : LOC_REG                                                        *
* Module      : LOC_REG                                                        *
* Version     : v 0.0.0 2006/07/11 11:18                                       *
*                                                                              *
* Description : Local register file                                            *
*                                                                              *
* Designer    : Tomohisa Uchida                                                *
*                                                                              *
*                Copyright (c) 2006 Tomohisa Uchida                            *
*                All rights reserved                                           *
*                                                                              *
*******************************************************************************/
module
	RBCP_TEST(
		// System
		input	wire			CLK					,	// in	: System clock
		input	wire			RSTs				,	// in	: System reset
		input	wire	[31:0]	REG_FPGA_VER        ,
		// Processor I/F
		input	wire	[31:0]	LOC_ADDR			,	// in	: Address[31:0]
		input	wire			LOC_WE				,	// in	: Write enable
		input	wire	[ 7:0]	LOC_WD				,	// in	: Write data[7:0]
		input	wire			LOC_RE				,	// in	: Read enable
		output	wire			LOC_ACK				,	// out	: Read valid
		output	wire	[ 7:0]	LOC_RD				,	// out	: Read data[7:0]
		// Register
		output	reg				SiTCPXG_OPEN_REQ	,	// Request for opening the new session
		input	wire			SiTCPXG_ESTABLISHED	,	// Establish of a session
		input	wire			SiTCPXG_CLOSE_REQ	,	// Request for closing session.
		output	reg				SiTCPXG_CLOSE_ACK	,	// Acknowledge for USER_SESSION_CLOSE_REQ.
		output	reg				LOOPBACK			,	// Loopback mode
		output	reg				SELECT_SEQ			,	// Selection of sequence data
		output	reg				DATA_GEN			,	// Data transmission enable
		output	wire	[ 7:0]	TX_RATE				,	// Transmission data rate in units of 100 Mbps
		output	wire	[23:0]	BLK_SIZE			,	// Transmission block size in bytes
		output	wire	[31:0]	SEQ_PATTERN			,	// sequence data(The default value is 0x60808040)
		output	wire	[63:0]	NUM_OF_DATA				// Number of bytes of transmitted data
	);


	reg		[ 7:0]	irAddr			;
	reg				irWe			;
	reg		[ 7:0]	irWd			;
	reg				irRe			;
	reg				Xx0Dec			;
	reg				Xx1Dec			;
	reg				Xx2Dec			;
	reg				Xx3Dec			;
	reg				Xx4Dec			;
	reg				Xx5Dec			;
	reg				Xx6Dec			;
	reg				Xx7Dec			;
	reg				Xx8Dec			;
	reg				Xx9Dec			;
	reg				XxADec			;
	reg				XxBDec			;
	reg				XxCDec			;
	reg				XxDDec			;
	reg				XxEDec			;
	reg				XxFDec			;
	reg		[ 1:0]	regWe			;
	reg		[ 7:0]	regWd			;

	reg				CLIENT_MODE		;
	wire	[ 7:0]	regX04Data		;
	reg		[ 7:0]	regX10Data		;
	reg		[ 7:0]	regX11Data		;
	reg		[ 7:0]	regX12Data		;
	reg		[ 7:0]	regX13Data		;
	reg		[ 7:0]	regX14Data		;
	reg		[ 7:0]	regX15Data		;
	reg		[ 7:0]	regX16Data		;
	reg		[ 7:0]	regX17Data		;
	reg		[ 7:0]	regX18Data		;
	reg		[ 7:0]	regX19Data		;
	reg		[ 7:0]	regX1AData		;
	reg		[ 7:0]	regX1BData		;
	reg		[ 7:0]	regX1CData		;
	reg		[ 7:0]	regX1DData		;
	reg		[ 7:0]	regX1EData		;
	reg		[ 7:0]	regX1FData		;

	wire	[ 7:0]	X00Data			;
	wire	[ 7:0]	X01Data			;
	wire	[ 7:0]	X02Data			;
	wire	[ 7:0]	X03Data			;
	wire	[ 7:0]	X04Data			;
	wire	[ 7:0]	X10Data			;
	wire	[ 7:0]	X11Data			;
	wire	[ 7:0]	X12Data			;
	wire	[ 7:0]	X13Data			;
	wire	[ 7:0]	X14Data			;
	wire	[ 7:0]	X15Data			;
	wire	[ 7:0]	X16Data			;
	wire	[ 7:0]	X17Data			;
	wire	[ 7:0]	X18Data			;
	wire	[ 7:0]	X19Data			;
	wire	[ 7:0]	X1AData			;
	wire	[ 7:0]	X1BData			;
	wire	[ 7:0]	X1CData			;
	wire	[ 7:0]	X1DData			;
	wire	[ 7:0]	X1EData			;
	wire	[ 7:0]	X1FData			;

	reg				PreMuxVal		;
	reg		[ 5:0]	PreMuxAddr		;
	reg		[39:0]	PreMuxData		;
	reg		[ 7:0]	muxData			;
	reg				muxVal			;
	reg				procAck			;
	reg		[ 7:0]	procRd			;

//--------------------------------------
//	Input registers
//--------------------------------------

	always	@(posedge CLK) begin
		irAddr[7:0]	<= LOC_ADDR[7:0]	;
		irWe		<= (LOC_ADDR[31:16]==16'd0) & LOC_WE			;
		irWd[7:0]	<= LOC_WD[7:0]		;
		irRe		<= (LOC_ADDR[31:16]==16'd0) & LOC_RE			;
	end

//--------------------------------------
//	Address decode
//--------------------------------------

	always@ (posedge CLK) begin
		Xx0Dec	<= (irAddr[3:0] == 4'h0);
		Xx1Dec	<= (irAddr[3:0] == 4'h1);
		Xx2Dec	<= (irAddr[3:0] == 4'h2);
		Xx3Dec	<= (irAddr[3:0] == 4'h3);
		Xx4Dec	<= (irAddr[3:0] == 4'h4);
		Xx5Dec	<= (irAddr[3:0] == 4'h5);
		Xx6Dec	<= (irAddr[3:0] == 4'h6);
		Xx7Dec	<= (irAddr[3:0] == 4'h7);
		Xx8Dec	<= (irAddr[3:0] == 4'h8);
		Xx9Dec	<= (irAddr[3:0] == 4'h9);
		XxADec	<= (irAddr[3:0] == 4'hA);
		XxBDec	<= (irAddr[3:0] == 4'hB);
		XxCDec	<= (irAddr[3:0] == 4'hC);
		XxDDec	<= (irAddr[3:0] == 4'hD);
		XxEDec	<= (irAddr[3:0] == 4'hE);
		XxFDec	<= (irAddr[3:0] == 4'hF);
		regWe[0]	<= irWe & (irAddr[7:4] == 4'h0);
		regWe[1]	<= irWe & (irAddr[7:4] == 4'h1);
		regWd[7:0]	<= irWd[7:0];
	end

//------------------------------------------------------------------------------
//	Register file
//------------------------------------------------------------------------------
//--------------------------------------
//	Registers
//--------------------------------------
	assign	regX04Data[7:0]		= {SiTCPXG_OPEN_REQ,LOOPBACK,4'b00_00,SELECT_SEQ,DATA_GEN};
	always	@(posedge CLK or posedge RSTs) begin
		if(RSTs)begin
			SiTCPXG_OPEN_REQ	<= 0;
			CLIENT_MODE			<= 0;
			SiTCPXG_CLOSE_ACK	<= 0;
			LOOPBACK			<= 0;
			SELECT_SEQ			<= 0;
			DATA_GEN			<= 0;
		end else begin
			SiTCPXG_OPEN_REQ	<= (regWe[0] & Xx4Dec)?		(regWd[7] & (~SiTCPXG_ESTABLISHED|SiTCPXG_OPEN_REQ)):		(SiTCPXG_OPEN_REQ & ~SiTCPXG_CLOSE_REQ);
			CLIENT_MODE			<= (regWe[0] & Xx4Dec & regWd[7] & ~SiTCPXG_ESTABLISHED)|(CLIENT_MODE & (SiTCPXG_OPEN_REQ|SiTCPXG_ESTABLISHED|SiTCPXG_CLOSE_REQ));
			SiTCPXG_CLOSE_ACK	<= ~CLIENT_MODE & SiTCPXG_CLOSE_REQ;
			LOOPBACK			<= (regWe[0] & Xx4Dec)?		regWd[6]:		LOOPBACK;
			SELECT_SEQ			<= (regWe[0] & Xx4Dec)?		regWd[1]:		SELECT_SEQ;
			DATA_GEN			<= (regWe[0] & Xx4Dec)?		regWd[0]:		DATA_GEN;
		end
	end

	always@ (posedge CLK or posedge RSTs) begin
		if(RSTs)begin
			regX10Data[7:0]	<= 8'd100;		// 10Gbps
			regX11Data[7:0]	<= 8'h0D;		// Block Size = (6+8+8+4)*64*512 = 0x0D0000
			regX12Data[7:0]	<= 8'h00;
			regX13Data[7:0]	<= 8'h00;
			regX14Data[7:0]	<= 8'h60;		// Size Sequence = 0x60808040
			regX15Data[7:0]	<= 8'h80;
			regX16Data[7:0]	<= 8'h80;
			regX17Data[7:0]	<= 8'h40;
			regX18Data[7:0]	<= 8'hFF;		// NUM_OF_DATA
			regX19Data[7:0]	<= 8'hFF;
			regX1AData[7:0]	<= 8'hFF;
			regX1BData[7:0]	<= 8'hFF;
			regX1CData[7:0]	<= 8'hFF;
			regX1DData[7:0]	<= 8'hFF;
			regX1EData[7:0]	<= 8'hFF;
			regX1FData[7:0]	<= 8'hFF;
		end else begin
			regX10Data[7:0]	<= (regWe[1] & Xx0Dec)?		regWd[7:0]:		regX10Data[7:0];
			regX11Data[7:0]	<= (regWe[1] & Xx1Dec)?		regWd[7:0]:		regX11Data[7:0];
			regX12Data[7:0]	<= (regWe[1] & Xx2Dec)?		regWd[7:0]:		regX12Data[7:0];
			regX13Data[7:0]	<= (regWe[1] & Xx3Dec)?		regWd[7:0]:		regX13Data[7:0];
			regX14Data[7:0]	<= (regWe[1] & Xx4Dec)?		regWd[7:0]:		regX14Data[7:0];
			regX15Data[7:0]	<= (regWe[1] & Xx5Dec)?		regWd[7:0]:		regX15Data[7:0];
			regX16Data[7:0]	<= (regWe[1] & Xx6Dec)?		regWd[7:0]:		regX16Data[7:0];
			regX17Data[7:0]	<= (regWe[1] & Xx7Dec)?		regWd[7:0]:		regX17Data[7:0];
			regX18Data[7:0]	<= (regWe[1] & Xx8Dec)?		regWd[7:0]:		regX18Data[7:0];
			regX19Data[7:0]	<= (regWe[1] & Xx9Dec)?		regWd[7:0]:		regX19Data[7:0];
			regX1AData[7:0]	<= (regWe[1] & XxADec)?		regWd[7:0]:		regX1AData[7:0];
			regX1BData[7:0]	<= (regWe[1] & XxBDec)?		regWd[7:0]:		regX1BData[7:0];
			regX1CData[7:0]	<= (regWe[1] & XxCDec)?		regWd[7:0]:		regX1CData[7:0];
			regX1DData[7:0]	<= (regWe[1] & XxDDec)?		regWd[7:0]:		regX1DData[7:0];
			regX1EData[7:0]	<= (regWe[1] & XxEDec)?		regWd[7:0]:		regX1EData[7:0];
			regX1FData[7:0]	<= (regWe[1] & XxFDec)?		regWd[7:0]:		regX1FData[7:0];
		end
	end

	assign	X00Data[7:0]	= REG_FPGA_VER[31:24];
	assign	X01Data[7:0]	= REG_FPGA_VER[23:16];
	assign	X02Data[7:0]	= REG_FPGA_VER[15: 8];
	assign	X03Data[7:0]	= REG_FPGA_VER[ 7: 0];
	assign	X04Data[7:0]	= regX04Data[7:0];
	assign	X10Data[7:0]	= regX10Data[7:0];
	assign	X11Data[7:0]	= regX11Data[7:0];
	assign	X12Data[7:0]	= regX12Data[7:0];
	assign	X13Data[7:0]	= regX13Data[7:0];
	assign	X14Data[7:0]	= regX14Data[7:0];
	assign	X15Data[7:0]	= regX15Data[7:0];
	assign	X16Data[7:0]	= regX16Data[7:0];
	assign	X17Data[7:0]	= regX17Data[7:0];
	assign	X18Data[7:0]	= regX18Data[7:0];
	assign	X19Data[7:0]	= regX19Data[7:0];
	assign	X1AData[7:0]	= regX1AData[7:0];
	assign	X1BData[7:0]	= regX1BData[7:0];
	assign	X1CData[7:0]	= regX1CData[7:0];
	assign	X1DData[7:0]	= regX1DData[7:0];
	assign	X1EData[7:0]	= regX1EData[7:0];
	assign	X1FData[7:0]	= regX1FData[7:0];

	// X10Data
	assign	TX_RATE[7:0]		= X10Data[7:0];
	// X11Data - X13Data
	assign	BLK_SIZE[23:16]		= X11Data[7:0];
	assign	BLK_SIZE[15: 8]		= X12Data[7:0];
	assign	BLK_SIZE[ 7: 0]		= X13Data[7:0];
	// X14Data - X17Data
	assign	SEQ_PATTERN[31:24]	= X14Data[7:0];
	assign	SEQ_PATTERN[23:16]	= X15Data[7:0];
	assign	SEQ_PATTERN[15: 8]	= X16Data[7:0];
	assign	SEQ_PATTERN[ 7: 0]	= X17Data[7:0];
	// X18Data - X1FData
	assign	NUM_OF_DATA[63:56]	= X18Data[7:0];
	assign	NUM_OF_DATA[55:48]	= X19Data[7:0];
	assign	NUM_OF_DATA[47:40]	= X1AData[7:0];
	assign	NUM_OF_DATA[39:32]	= X1BData[7:0];
	assign	NUM_OF_DATA[31:24]	= X1CData[7:0];
	assign	NUM_OF_DATA[23:16]	= X1DData[7:0];
	assign	NUM_OF_DATA[15: 8]	= X1EData[7:0];
	assign	NUM_OF_DATA[ 7: 0]	= X1FData[7:0];
//------------------------------------------------------------------------------
//  For debug
//------------------------------------------------------------------------------


//--------------------------------------
//	Read data mux.
//--------------------------------------

	always@ (posedge CLK) begin
		PreMuxVal		<= irRe;
		PreMuxAddr[5:0]	<= irAddr[7:2];
		PreMuxData[ 7: 0]	<= (
			((irAddr[2:0] == 3'd0)?	X00Data[7:0]:		8'h00)|
			((irAddr[2:0] == 3'd1)?	X01Data[7:0]:		8'h00)|
			((irAddr[2:0] == 3'd2)?	X02Data[7:0]:		8'h00)|
			((irAddr[2:0] == 3'd3)?	X03Data[7:0]:		8'h00)|
			((irAddr[2:0] == 3'd4)?	X04Data[7:0]:		8'h00)
		);
		PreMuxData[15: 8]	<= (
			((irAddr[1:0] == 3'd0)?	X10Data[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd1)?	X11Data[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd2)?	X12Data[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd3)?	X13Data[7:0]:		8'h00)
		);
		PreMuxData[23:16]	<= (
			((irAddr[1:0] == 3'd0)?	X14Data[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd1)?	X15Data[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd2)?	X16Data[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd3)?	X17Data[7:0]:		8'h00)
		);
		PreMuxData[31:24]	<= (
			((irAddr[1:0] == 3'd0)?	X18Data[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd1)?	X19Data[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd2)?	X1AData[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd3)?	X1BData[7:0]:		8'h00)
		);
		PreMuxData[39:32]	<= (
			((irAddr[1:0] == 3'd0)?	X1CData[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd1)?	X1DData[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd2)?	X1EData[7:0]:		8'h00)|
			((irAddr[1:0] == 3'd3)?	X1FData[7:0]:		8'h00)
		);
		muxData[7:0]	<= (
			((PreMuxAddr[5:1] == 5'b0000_0 )?	PreMuxData[ 7: 0]:		8'h00)|
			((PreMuxAddr[5:0] == 6'b0001_00)?	PreMuxData[15: 8]:		8'h00)|
			((PreMuxAddr[5:0] == 6'b0001_01)?	PreMuxData[23:16]:		8'h00)|
			((PreMuxAddr[5:0] == 6'b0001_10)?	PreMuxData[31:24]:		8'h00)|
			((PreMuxAddr[5:0] == 6'b0001_11)?	PreMuxData[39:32]:		8'h00)
		);
		muxVal	<= PreMuxVal;
	end


	always@ (posedge CLK) begin
		procAck		<= muxVal | irWe;
		procRd[7:0]	<= muxData[7:0];
	end


//------------------------------------------------------------------------------
//	Output
//------------------------------------------------------------------------------
	assign	LOC_ACK			= procAck;
	assign	LOC_RD[7:0]		= procRd[7:0];

//------------------------------------------------------------------------------
endmodule
