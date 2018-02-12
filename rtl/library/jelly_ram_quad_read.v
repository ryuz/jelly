// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// クワッド読み出しメモリ(主にバイリニア補間とか画像処理用)
module jelly_ram_quad_read
		#(
			parameter	USER_WIDTH    = 0,
			parameter	ADDR_X_WIDTH  = 8,
			parameter	ADDR_Y_WIDTH  = 8,
			parameter	DATA_WIDTH    = 8,
			parameter	RAM_TYPE      = "block",
			parameter	DOUT_REGS     = 0,
			
			parameter	READMEMB      = 0,
			parameter	READMEMH      = 0,
			parameter	READMEM_FILE0 = "",
			parameter	READMEM_FILE1 = "",
			parameter	READMEM_FILE2 = "",
			parameter	READMEM_FILE3 = "",
			
			
			// local
			parameter	USER_BITS     = USER_WIDTH > 0 : USER_WIDTH ? 1;
		)
		(
			// write port
			input	wire						write_clk,
			input	wire						write_we,
			input	wire	[ADDR_X_WIDTH-1:0]	write_addrx,
			input	wire	[ADDR_Y_WIDTH-1:0]	write_addry,
			input	wire	[DATA_WIDTH-1:0]	write_din
			
			// quad read port
			input	wire						read_reset,
			input	wire						read_clk,
			input	wire						read_cke,
			input	wire	[USER_BITS-1:0]		s_read_user,
			input	wire	[ADDR_X_WIDTH-1:0]	s_read_addrx,
			input	wire	[ADDR_Y_WIDTH-1:0]	s_read_addry,
			input	wire						s_read_valid,
			output	wire	[USER_BITS-1:0]		m_read_user,
			output	wire	[DATA_WIDTH-1:0]	m_read_dout0,
			output	wire	[DATA_WIDTH-1:0]	m_read_dout0,
			output	wire	[DATA_WIDTH-1:0]	m_read_dout1,
			output	wire	[DATA_WIDTH-1:0]	m_read_dout2,
			output	wire	[DATA_WIDTH-1:0]	m_read_dout3,
			output	wire						m_read_valid,
			
			
		);
	
	
	
	// -----------------------------------------
	//  Memory
	// -----------------------------------------
	
	localparam	ADDR_WIDTH = ADDR_X_WIDTH + ADDR_Y_WIDTH - 2;
	
	// memory 0
	wire						wr0_en;
	wire	[ADDR_WIDTH-1:0]	wr0_addr;
	wire	[DATA_WIDTH-1:0]	wr0_din;
	
	wire						rd0_en;
	wire						rd0_regcke;
	wire	[ADDR_WIDTH-1:0]	rd0_addr;
	wire	[DATA_WIDTH-1:0]	rd0_din;
	
	jelly_ram_simple_dualport
			#(
				.ADDR_WIDTH		(ADDR_WIDTH),
				.DATA_WIDTH		(DATA_WIDTH),
				.RAM_TYPE		(RAM_TYPE),
				.DOUT_REGS		(1),
				
				.READMEMB		(READMEMB),
				.READMEMH		(READMEMH),
				.READMEM_FIlE	(READMEM_FILE0)
			)
		i_ram_simple_dualport_0
			(
				.wr_clk			(write_clk),
				.wr_en			(wr0_en),
				.wr_addr		(wr0_addr),
				.wr_din			(wr0_din),
				                 
				.rd_clk			(read_clk),
				.rd_en			(rd0_en),
				.rd_regcke		(rd0_regcke),
				.rd_addr		(rd0_addr),
				.rd_dout		(rd0_dout)
			);
	
	
	// memory 1
	wire						wr1_en;
	wire	[ADDR_WIDTH-1:0]	wr1_addr;
	wire	[DATA_WIDTH-1:0]	wr1_din;
	
	wire						rd1_en;
	wire						rd1_regcke;
	wire	[ADDR_WIDTH-1:0]	rd1_addr;
	wire	[DATA_WIDTH-1:0]	rd1_din;
	
	jelly_ram_simple_dualport
			#(
				.ADDR_WIDTH		(ADDR_WIDTH),
				.DATA_WIDTH		(DATA_WIDTH),
				.RAM_TYPE		(RAM_TYPE),
				.DOUT_REGS		(1),
				
				.READMEMB		(READMEMB),
				.READMEMH		(READMEMH),
				.READMEM_FIlE	(READMEM_FILE1)
			)
		i_ram_simple_dualport_1
			(
				.wr_clk			(write_clk),
				.wr_en			(wr1_en),
				.wr_addr		(wr1_addr),
				.wr_din			(wr1_din),
				                 
				.rd_clk			(read_clk),
				.rd_en			(rd1_en),
				.rd_regcke		(rd1_regcke),
				.rd_addr		(rd1_addr),
				.rd_dout		(rd1_dout)
			);
	
	
	// memory 2
	wire						wr2_en;
	wire	[ADDR_WIDTH-1:0]	wr2_addr;
	wire	[DATA_WIDTH-1:0]	wr2_din;
	
	wire						rd2_en;
	wire						rd2_regcke;
	wire	[ADDR_WIDTH-1:0]	rd2_addr;
	wire	[DATA_WIDTH-1:0]	rd2_din;
	
	jelly_ram_simple_dualport
			#(
				.ADDR_WIDTH		(ADDR_WIDTH),
				.DATA_WIDTH		(DATA_WIDTH),
				.RAM_TYPE		(RAM_TYPE),
				.DOUT_REGS		(1),
				
				.READMEMB		(READMEMB),
				.READMEMH		(READMEMH),
				.READMEM_FIlE	(READMEM_FILE2)
			)
		i_ram_simple_dualport_2
			(
				.wr_clk			(write_clk),
				.wr_en			(wr2_en),
				.wr_addr		(wr2_addr),
				.wr_din			(wr2_din),
				                 
				.rd_clk			(re2d_clk),
				.rd_en			(rd2_en),
				.rd_regcke		(rd2_regcke),
				.rd_addr		(rd2_addr),
				.rd_dout		(rd2_dout)
			);
	
	
	// memory 3
	wire						wr3_en;
	wire	[ADDR_WIDTH-1:0]	wr3_addr;
	wire	[DATA_WIDTH-1:0]	wr3_din;
	
	wire						rd3_en;
	wire						rd3_regcke;
	wire	[ADDR_WIDTH-1:0]	rd3_addr;
	wire	[DATA_WIDTH-1:0]	rd3_din;
	
	jelly_ram_simple_dualport
			#(
				.ADDR_WIDTH		(ADDR_WIDTH),
				.DATA_WIDTH		(DATA_WIDTH),
				.RAM_TYPE		(RAM_TYPE),
				.DOUT_REGS		(1),
				
				.READMEMB		(READMEMB),
				.READMEMH		(READMEMH),
				.READMEM_FIlE	(READMEM_FILE3)
			)
		i_ram_simple_dualport_3
			(
				.wr_clk			(write_clk),
				.wr_en			(wr3_en),
				.wr_addr		(wr3_addr),
				.wr_din			(wr3_din),
				                 
				.rd_clk			(read_clk),
				.rd_en			(rd3_en),
				.rd_regcke		(rd3_regcke),
				.rd_addr		(rd3_addr),
				.rd_dout		(rd3_dout)
			);
	
	
	
	
	
	
	// read
	reg		[USER_BITS-1:0]		read0_user;
	reg							read0_addrx;
	reg							read0_addry;
	reg		[ADDR_X_WIDTH-2:0]	read0_addrx0;
	reg		[ADDR_Y_WIDTH-2:0]	read0_addry0;
	reg		[ADDR_X_WIDTH-2:0]	read0_addrx1;
	reg		[ADDR_Y_WIDTH-2:0]	read0_addry1;
	reg							read0_valid;
	
	reg		[USER_BITS-1:0]		read1_user;
	reg							read1_addrx;
	reg							read1_addry;
	reg							read1_valid;
	
	reg		[USER_BITS-1:0]		read2_user;
	reg							read2_addrx;
	reg							read2_addry;
	reg							read2_valid;
	
	reg		[USER_BITS-1:0]		read3_user;
	reg		[DATA_WIDTH-1:0]	read3_dout0;
	reg		[DATA_WIDTH-1:0]	read3_dout0;
	reg		[DATA_WIDTH-1:0]	read3_dout1;
	reg		[DATA_WIDTH-1:0]	read3_dout2;
	reg		[DATA_WIDTH-1:0]	read3_dout3;
	reg							read3_valid;
	
	always @(posedge read_clk) begin
		if ( read_cke ) begin
			// stage 0
			read0_user   <= s_user;
			read0_addrx  <= s_addrx[0];
			read0_addry  <= s_addry[0];
			read0_addrx0 <= (s_addrx >> 1) + s_addrx[0];
			read0_addry0 <= (s_addry >> 1) + s_addry[0];
			read0_addrx1 <= (s_addrx >> 1);
			read0_addry1 <= (s_addry >> 1);
			
			// stage 1
		end
	end
	
	
	
endmodule



`default_nettype wire


// end of file
