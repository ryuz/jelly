// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// parameter registers with shadow register(ram)
module jelly_params_ram
		#(
			parameter	NUM        = 64,
			parameter	BANK_WIDTH = 1,
			parameter	DATA_WIDTH = 32,
			parameter	ADDR_WIDTH = NUM <=     2 ?  1 :
			                         NUM <=     4 ?  2 :
			                         NUM <=     8 ?  3 :
			                         NUM <=    16 ?  4 :
			                         NUM <=    32 ?  5 :
			                         NUM <=    64 ?  6 :
			                         NUM <=   128 ?  7 :
			                         NUM <=   256 ?  8 :
			                         NUM <=   512 ?  9 :
			                         NUM <=  1024 ? 10 :
			                         NUM <=  2048 ? 11 :
			                         NUM <=  4096 ? 12 :
			                         NUM <=  8192 ? 13 :
			                         NUM <= 16384 ? 14 :
			                         NUM <= 32768 ? 15 : 16,	// ˆê•”ˆ—Œn‚Å $clog2 ‚ª³‚µ‚­“®‚©‚È‚¢‚Ì‚Å
			parameter	WRITE_ONLY   = 1,
			parameter	DOUT_REGS    = 0,
			parameter	RAM_TYPE     = "distributed",
			parameter	ENDIAN       = 0,
			parameter	INIT_PARAMS  = {(NUM*DATA_WIDTH){1'b0}},
			
			
			// local parameter
			parameter	BANK_BITS    = BANK_WIDTH > 0 ? BANK_WIDTH : 1
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire								start,
			output	wire								busy,
			
			input	wire	[BANK_BITS-1:0]				bank,
			output	wire	[NUM*DATA_WIDTH-1:0]		params,
			
			
			// memory port
			input	wire								mem_clk,
			input	wire								mem_en,
			input	wire								mem_regcke,
			input	wire								mem_we,
			input	wire	[BANK_WIDTH+ADDR_WIDTH-1:0]	mem_addr,
			input	wire	[DATA_WIDTH-1:0]			mem_din,
			output	wire	[DATA_WIDTH-1:0]			mem_dout
		);
	
	
	// -----------------------------
	//  memory
	// -----------------------------
	
	wire						rd_cke;
	wire	[ADDR_WIDTH-1:0]	rd_addr;
	wire	[DATA_WIDTH-1:0]	rd_data;
	
	generate
	if ( WRITE_ONLY ) begin : blk_sdp
		jelly_ram_simple_dualport
				#(
					.ADDR_WIDTH		(BANK_WIDTH+ADDR_WIDTH),
					.DATA_WIDTH		(DATA_WIDTH),
					.RAM_TYPE		(RAM_TYPE),
					.DOUT_REGS		(0)
				)
			i_ram_simple_dualport
				(
					.wr_clk			(mem_clk),
					.wr_en			(mem_en & mem_we),
					.wr_addr		(mem_addr),
					.wr_din			(mem_din),
					
					.rd_clk			(clk),
					.rd_en			(rd_cke),
					.rd_regcke		(1'b0),
					.rd_addr		({bank, rd_addr}),
					.rd_dout		(rd_data)
				);
		
		assign mem_dout = {DATA_WIDTH{1'b0}};
	end
	else begin : blk_dp
		jelly_ram_dualport
				#(
					.ADDR_WIDTH		(BANK_WIDTH+ADDR_WIDTH),
					.DATA_WIDTH		(DATA_WIDTH),
					.RAM_TYPE		(RAM_TYPE),
					.DOUT_REGS0		(DOUT_REGS),
					.DOUT_REGS1		(0)
				)
			i_ram_dualport
				(
					.clk0			(mem_clk),
					.en0			(mem_en),
					.regcke0		(mem_regcke),
					.we0			(mem_we),
					.addr0			(mem_addr),
					.din0			(mem_din),
					.dout0			(mem_dout),
					
					.clk1			(clk),
					.en1			(rd_cke),
					.regcke1		(1'b0),
					.we1			(1'b0),
					.addr1			({bank, rd_addr}),
					.din1			({DATA_WIDTH{1'b0}}),
					.dout1			(rd_data)
				);
	end
	endgenerate
	
	
	// -----------------------------
	//  registers
	// -----------------------------
	
	reg								reg_busy;
	reg								reg_shift;
	reg		[ADDR_WIDTH-1:0]		reg_addr;
	reg		[NUM*DATA_WIDTH-1:0]	reg_params;
	
	always @(posedge clk ) begin
		if ( reset ) begin
			reg_busy  <= 1'b0;
		end
		else begin
			if ( reg_addr == (NUM-1) ) begin
				reg_busy <= 1'b0;
			end
			else if ( start ) begin
				reg_busy <= 1'b1;
			end
		end
	end
	
	always @(posedge clk ) begin
		reg_shift <= reg_busy;
		if ( reg_busy ) begin
			reg_addr <= reg_addr + 1'b1;
		end
		else begin
			reg_addr <= {ADDR_WIDTH{1'b0}};
		end
	end
	
	always @(posedge clk ) begin
		if ( reset ) begin
			reg_params <= INIT_PARAMS;
		end
		else begin
			if ( reg_shift ) begin
				if ( ENDIAN ) begin
					reg_params <= ((reg_params << DATA_WIDTH) | rd_data);
				end
				else begin
					reg_params <= ((reg_params >> DATA_WIDTH) | (rd_data << (NUM-1)*DATA_WIDTH));
				end
			end
		end
	end
	
	assign rd_cke  = reg_busy;
	assign rd_addr = reg_addr;
	
	assign busy    = reg_busy;
	assign params  = reg_params;
	
	
endmodule


// End of file
