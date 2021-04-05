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
//			The original source was developed by Dr. Uchida(2018/02/23)
//			20200923	Ver 1.1		---------	Created by BBT
//
//----------------------------------------------------------------------//
module
	TCP_TEST(
		/* [System] */
		input	wire			CLK156M						,	// Tx clock
		input	wire			RSTs						,	// System reset
		input	wire	[7:0]	TX_RATE						,	// Transmission data rate in units of 100 Mbps
		input	wire	[63:0]	NUM_OF_DATA					,	// Number of bytes of transmitted data
		input	wire			DATA_GEN					,	// Data transmission enable
		input	wire			LOOPBACK					,	// Loopback mode
		input	wire	[ 2:0]	WORD_LEN					,	// Word length of test data
		input	wire			SELECT_SEQ					,	// Sequence Data select
		input	wire	[31:0]	SEQ_PATTERN					,	// sequence data(The default value is 0x60808040)
		input	wire	[23:0]	BLK_SIZE					,	// Transmission block size in bytes
		input	wire			INS_ERROR					,	// Data error insertion
		/* [SiTCP-XG I/F] */
		input	wire			SiTCPXG_ESTABLISHED			,	// Establish of a session
		output	wire	[15:0]	SiTCPXG_RX_SIZE				,	// Receive buffer size(byte) caution:Set a value of 4000 or more and (memory size-16) or less
		input	wire			SiTCPXG_RX_CLR_ENB			,	// Receive buffer Clear Enable
		output	wire			SiTCPXG_RX_CLR_REQ			,	// Receive buffer Clear Request
		output	wire	[15:0]	SiTCPXG_RX_RADR				,	// Receive buffer read address in bytes (unused upper bits are set to 0)
		input	wire	[15:0]	SiTCPXG_RX_WADR				,	// Receive buffer write address in bytes (lower 3 bits are not connected to memory)
		input	wire	[ 7:0]	SiTCPXG_RX_WENB				,	// Receive buffer byte write enable (big endian)
		input	wire	[63:0]	SiTCPXG_RX_WDAT				,	// Receive buffer write data (big endian)
		input	wire			SiTCPXG_TX_AFULL			,	// TX fifo, almost full
		output	wire	[63:0]	SiTCPXG_TX_D				,	// Tx data[63:0]
		output	wire	[ 3:0]	SiTCPXG_TX_B					// Byte length of USER_TX_DATA, one-based(zero means 8 bytes)
	);

	reg		[ 7:0]	irTxRate		;
	reg		[64:0]	irNumOfData		;
	reg				irDataGen		;
	reg				irLoopback		;
	reg		[ 8:0]	sftWordLen		;
	reg		[ 3:0]	irWordLen		;
	reg				irSelectSeq		;
	reg		[31:0]	irSeqPattern	;
	reg		[24:0]	irBlockSize		;
	reg		[ 2:0]	sftInsError		;
	reg				irInsError		;
	reg				irEstablished	;
	reg				irTxAlmostFull	;

	reg		[11:0]	MEM_RAD			;
	wire	[ 3:0]	MEM_REN			;
	reg		[ 3:0]	P0_MEM_LEN		;
	reg		[ 2:0]	P0_MEM_POS		;
	reg		[ 3:0]	P1_MEM_LEN		;
	reg		[ 2:0]	P1_MEM_POS		;
	wire	[63:0]	MEM_RDT			;
	reg		[63:0]	irRxD			;
	reg		[ 3:0]	irRxB			;

	wire			TxEnable		;
	reg				genEnb			;
	reg		[24:0]	BlockCount		;
	reg		[64:0]	TxCount			;
	reg		[ 5:0]	RateCount		;
	reg		[ 8:0]	AddToken		;
	reg		[31:0]	Bucket			;
	reg		[31:0]	SeqWordLen		;
	reg		[ 3:0]	prWordLen		;
	reg		[31:0]	genWordLen		;
	reg		[ 7:0]	genCntCy		;
	reg		[ 7:0]	genCntr			;
	reg		[ 3:0]	muxTxB			;
	reg		[ 3:0]	LastTxB			;
	reg		[63:0]	muxTxD			;
	reg		[63:0]	orTxD			;
	reg		[ 3:0]	orTxB			;


//------------------------------------------------------------------------------
//	Input buffer
//------------------------------------------------------------------------------
	always @(posedge CLK156M) begin
		irTxRate[7:0]		<= TX_RATE[7:0];
		irNumOfData[64:0]	<= {1'b1,NUM_OF_DATA[63:0]} - 65'd1;
		irDataGen			<= DATA_GEN;
		irLoopback			<= LOOPBACK;
		sftWordLen[2:0]		<= WORD_LEN[2:0];
		sftWordLen[5:3]		<= sftWordLen[2:0];
		sftWordLen[8:6]		<= sftWordLen[5:3];
		irWordLen[3:0]		<= {1'b0,sftWordLen[8:6]} + 4'd1;
		irSelectSeq			<= SELECT_SEQ;
		irSeqPattern[31:0]	<= SEQ_PATTERN[31:0];
		irBlockSize[24:0]	<= {1'b1,BLK_SIZE[23:0]} - 25'd1;
		sftInsError[2:0]	<= {sftInsError[1:0],INS_ERROR};
		irInsError			<= sftInsError[2];
		irEstablished		<= SiTCPXG_ESTABLISHED;
		irTxAlmostFull		<= SiTCPXG_TX_AFULL;
	end

//------------------------------------------------------------------------------
//	Controller
//------------------------------------------------------------------------------
	assign		SiTCPXG_RX_SIZE[15:0]	= 16'd4000;
	assign		SiTCPXG_RX_CLR_REQ		= SiTCPXG_RX_CLR_ENB;
	assign		SiTCPXG_RX_RADR[15:0]	= {4'b0000,MEM_RAD[11:0]};
	assign		MEM_REN[3]		= (irTxAlmostFull & irEstablished)?	1'b0:			(MEM_RAD[11:3] != SiTCPXG_RX_WADR[11:3]);
	assign		MEM_REN[2:0]	= (irTxAlmostFull & irEstablished)?	MEM_RAD[2:0]:	SiTCPXG_RX_WADR[2:0];

	always @(posedge CLK156M) begin
		MEM_RAD[ 2:0]	<= SiTCPXG_RX_CLR_REQ?		SiTCPXG_RX_WADR[2:0]:		(MEM_REN[3]?	3'b000:		MEM_REN[2:0]);
		MEM_RAD[11:3]	<= SiTCPXG_RX_CLR_REQ?		SiTCPXG_RX_WADR[11:3]:		(MEM_RAD[11:3] + {8'd0,MEM_REN[3]});
		P0_MEM_LEN[3]	<= MEM_REN[3] & (MEM_RAD[2:0] == 3'd0);
		P0_MEM_LEN[2:0]	<= (MEM_REN[3]?		3'd0:	MEM_REN[2:0]) - MEM_RAD[2:0];
		P0_MEM_POS[2:0]	<= MEM_RAD[2:0];
		P1_MEM_LEN[3:0]	<= P0_MEM_LEN[3:0];
		P1_MEM_POS[2:0]	<= P0_MEM_POS[2:0];
	end


	RAMB36E1	#(
		.RAM_MODE						("SDP"										),
		.RDADDR_COLLISION_HWCONFIG		("DELAYED_WRITE"							),
		.READ_WIDTH_A					(72											),
		.WRITE_WIDTH_B					(72											),
		.DOA_REG						(1											),
		.DOB_REG						(1											),
		.EN_ECC_READ					("FALSE"									),
		.EN_ECC_WRITE					("FALSE"									),
		.SIM_COLLISION_CHECK			("GENERATE_X_ONLY"							),
		.SIM_DEVICE						("7SERIES"									)
	)
	RX_BUF	(
		.CLKBWRCLK						(CLK156M									),	// In MODE = SDP, this is the WRCLK.
		.ADDRBWRADDR					({1'b0,SiTCPXG_RX_WADR[11:3],6'b00_0000}	),	// In RAM_MODE = SDP, this is the WRADDR bus
		.ENBWREN						(1'b1										),	// In RAM_MODE = SDP, this is the WREN
		.WEBWE							(SiTCPXG_RX_WENB[7:0]						),	// In RAM_MODE = SDP, this is the byte-wide Write enable
		.DIBDI							(SiTCPXG_RX_WDAT[63:32]						),
		.DIADI							(SiTCPXG_RX_WDAT[31: 0]						),	// In RAM_MODE = SDP,use only for 72bit bus
		.DIPBDIP						(4'b0000									),
		.DIPADIP						(4'b0000									),	// In RAM_MODE = SDP,use only for 72bit bus
		.CLKARDCLK						(CLK156M									),	// In RAM_MODE = SDP, this is the RDCLK.
		.ADDRARDADDR					({1'b0,MEM_RAD[11:3],6'b00_0000}			),	//  In RAM_MODE = SDP, this is the RDADDR bus.
		.ENARDEN						(1'b1										),	// In RAM_MODE = SDP, this is the RDEN
		.DOBDO							(MEM_RDT[63:32]								),	// In RAM_MODE = SDP,use only for 72bit bus
		.DOADO							(MEM_RDT[31: 0]								),
		.DOPBDOP						(											),	// In RAM_MODE = SDP,use only for 72bit bus
		.DOPADOP						(											),
		.CASCADEOUTA					(											),
		.CASCADEOUTB					(											),
		.DBITERR						(											),
		.ECCPARITY						(											),
		.RDADDRECC						(											),
		.SBITERR						(											),
		.RSTREGB						(1'b0										),
		.CASCADEINA						(											),
		.CASCADEINB						(											),
		.INJECTDBITERR					(1'b0										),
		.INJECTSBITERR					(1'b0										),
		.WEA							(4'b0000									),
		.REGCEAREGCE					(1'b1										),	// In RAM_MODE = SDP, this is the REGCE
 		.REGCEB							(1'b1										),
		.RSTREGARSTREG					(1'b0										),	// In RAM_MODE = SDP, this is the RSTREG
		.RSTRAMARSTRAM					(1'b0										),	// In RAM_MODE = SDP, this is the RSTRAM
		.RSTRAMB						(1'b0										)
	);


	always @(posedge CLK156M) begin
		irRxD[63:0]		<= (
			((P1_MEM_POS[2:0] == 3'd0)?		MEM_RDT[63:0]:						64'd0)|
			((P1_MEM_POS[2:0] == 3'd1)?		{MEM_RDT[55:0],MEM_RDT[ 7:0]}:		64'd0)|
			((P1_MEM_POS[2:0] == 3'd2)?		{MEM_RDT[47:0],MEM_RDT[15:0]}:		64'd0)|
			((P1_MEM_POS[2:0] == 3'd3)?		{MEM_RDT[39:0],MEM_RDT[23:0]}:		64'd0)|
			((P1_MEM_POS[2:0] == 3'd4)?		{MEM_RDT[31:0],MEM_RDT[31:0]}:		64'd0)|
			((P1_MEM_POS[2:0] == 3'd5)?		{MEM_RDT[23:0],MEM_RDT[39:0]}:		64'd0)|
			((P1_MEM_POS[2:0] == 3'd6)?		{MEM_RDT[15:0],MEM_RDT[47:0]}:		64'd0)|
			((P1_MEM_POS[2:0] == 3'd7)?		{MEM_RDT[ 7:0],MEM_RDT[55:0]}:		64'd0)
		);
		irRxB[3:0]		<= P1_MEM_LEN[3:0];
	end
//
//	RateCount[5:0]	32,9,11,...,31,33,10,12,14,...30,32,9	: 2count/25clock(@156.25MHz) = 12.5MByte/sec = 100Mbps
//
	assign	TxEnable	= genEnb & BlockCount[24] & TxCount[64];


	always @(posedge CLK156M) begin
		genEnb				<= irEstablished & ~irTxAlmostFull & irDataGen;
		BlockCount[24:0]	<= (irEstablished & (Bucket[31]|BlockCount[24]))?		(BlockCount[24:0] - {21'd0,(TxEnable?	genWordLen[31:28]:	4'd0)}):	irBlockSize[24:0];
		if(!irEstablished)begin
			TxCount[64:0]		<= irNumOfData[64:0];
			RateCount[5:0]		<= 6'd0;
			AddToken[8:0]		<= 9'd0;
			Bucket[31:0]		<= 32'd0;
		end else begin
			TxCount[64:0]		<= TxCount[64:0] - {61'd0,(TxEnable?	genWordLen[31:28]:	4'd0)};
			RateCount[5:0]		<= RateCount[5:0] - (RateCount[5]?	6'd23:		6'b11_1110);
			AddToken[8:0]		<= {1'b0,((RateCount[5] & (Bucket[31:30] != 2'b01))?	irTxRate[7:0]:	8'd0)} - {5'd0,(TxEnable?	genWordLen[31:28]:	4'd0)};
			Bucket[31:0]		<= Bucket[31:0] + {{24{AddToken[8]}},AddToken[7:0]};
		end
	end

	always @(posedge CLK156M) begin
		if(!irEstablished)begin
			SeqWordLen[31:0]	<= irSeqPattern[31:0];
			prWordLen[3:0]		<= 4'h0;
			genWordLen[31:0]		<= 32'h0000_0000;
			genCntCy[7:0]		<= 8'b0000_0000;
			genCntr[7:0]		<= 8'd1;
		end else begin
			if(TxEnable)begin
				SeqWordLen[31:0]	<= irSelectSeq?		{SeqWordLen[27:0],SeqWordLen[31:28]}:		SeqWordLen[31:0];
				prWordLen[ 3:0]		<= irSelectSeq?		SeqWordLen[31:28]:		irWordLen[3:0];
				genWordLen[31:28]	<= prWordLen[3:0];
				genWordLen[27:24]	<= prWordLen[3:0] + 4'd1;
				genWordLen[23:20]	<= prWordLen[3:0] + 4'd2;
				genWordLen[19:16]	<= prWordLen[3:0] + 4'd3;
				genWordLen[15:12]	<= prWordLen[3:0] + 4'd4;
				genWordLen[11: 8]	<= prWordLen[3:0] + 4'd5;
				genWordLen[ 7: 4]	<= prWordLen[3:0] + 4'd6;
				genWordLen[ 3: 0]	<= prWordLen[3:0] + 4'd7;
				{genCntCy[7],genCntr[7:0]}	<= {1'b0,genCntr[7:0]} + {5'b0_0000,genWordLen[31:28]} + {8'b0_0000_000,genCntCy[7]};
				genCntCy[6] 				<= ({1'b0,genCntr[7:0]} + {5'b0_0000,genWordLen[27:24]}) > 9'h0ff;
				genCntCy[5] 				<= ({1'b0,genCntr[7:0]} + {5'b0_0000,genWordLen[23:20]}) > 9'h0ff;
				genCntCy[4] 				<= ({1'b0,genCntr[7:0]} + {5'b0_0000,genWordLen[19:16]}) > 9'h0ff;
				genCntCy[3] 				<= ({1'b0,genCntr[7:0]} + {5'b0_0000,genWordLen[15:12]}) > 9'h0ff;
				genCntCy[2] 				<= ({1'b0,genCntr[7:0]} + {5'b0_0000,genWordLen[11: 8]}) > 9'h0ff;
				genCntCy[1] 				<= ({1'b0,genCntr[7:0]} + {5'b0_0000,genWordLen[ 7: 4]}) > 9'h0ff;
				genCntCy[0] 				<= ({1'b0,genCntr[7:0]} + {5'b0_0000,genWordLen[ 3: 0]}) > 9'h0ff;
			end
		end
	end


	always @(posedge CLK156M) begin
		muxTxB[3:0] 	<= TxEnable?	genWordLen[31:28]:		4'd0;
		LastTxB[3:0]	<= TxEnable?	(TxCount[3:0] + 1'b1):	4'd0;
		if(TxEnable)begin
			muxTxD[63:56]	<= (genCntr[7:0] + ((genCntCy[7]            )?	8'd1:	8'd0)) ^ (irInsError?	8'd1:	8'd0);
			muxTxD[55:48]	<= (genCntr[7:0] + ((genCntCy[7]|genCntCy[6])?	8'd2:	8'd1));
			muxTxD[47:40]	<= (genCntr[7:0] + ((genCntCy[7]|genCntCy[5])?	8'd3:	8'd2));
			muxTxD[39:32]	<= (genCntr[7:0] + ((genCntCy[7]|genCntCy[4])?	8'd4:	8'd3));
			muxTxD[31:24]	<= (genCntr[7:0] + ((genCntCy[7]|genCntCy[3])?	8'd5:	8'd4));
			muxTxD[23:16]	<= (genCntr[7:0] + ((genCntCy[7]|genCntCy[2])?	8'd6:	8'd5));
			muxTxD[15: 8]	<= (genCntr[7:0] + ((genCntCy[7]|genCntCy[1])?	8'd7:	8'd6));
			muxTxD[ 7: 0]	<= (genCntr[7:0] + ((genCntCy[7]|genCntCy[0])?	8'd8:	8'd7));
		end
	end



	always @(posedge CLK156M) begin
		orTxD[63:0] <= irLoopback?		irRxD[63:0]:	muxTxD[63:0];
		orTxB[3:0]	<= irLoopback?		irRxB[3:0]:		(TxCount[64]?	muxTxB[3:0]:	LastTxB[3:0]);
	end

	assign	SiTCPXG_TX_D[63:0] = orTxD[63:0];
	assign	SiTCPXG_TX_B[3:0]	= orTxB[3:0];


//------------------------------------------------------------------------------
endmodule
