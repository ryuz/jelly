// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



module cpu_gpr
			(
				reset, clk, clk_x2,
				interlock,
				w0_en, w0_addr, w0_data,
				w1_en, w1_addr, w1_data,
				r0_en, r0_addr, r0_data,
				r1_en, r1_addr, r1_data
			);
	
	parameter	TYPE       = 1;		// 0: clk_x2 dp-ram, 1: dual dp-ram, 2: LUT
	parameter	DATA_WIDTH = 32;
	parameter	ADDR_WIDTH = 5;
	localparam	REG_SIZE   = (1 << ADDR_WIDTH);
	
	input						reset;
	input						clk;
	input						clk_x2;
	
	input						interlock;
	
	input						w0_en;
	input	[ADDR_WIDTH-1:0]	w0_addr;
	input	[DATA_WIDTH-1:0]	w0_data;

	input						w1_en;
	input	[ADDR_WIDTH-1:0]	w1_addr;
	input	[DATA_WIDTH-1:0]	w1_data;
	
	input						r0_en;
	input	[ADDR_WIDTH-1:0]	r0_addr;
	output	[DATA_WIDTH-1:0]	r0_data;
	
	input						r1_en;
	input	[ADDR_WIDTH-1:0]	r1_addr;
	output	[DATA_WIDTH-1:0]	r1_data;
	
	
	
	reg		clk_dly;
	always @* begin
		clk_dly = #1 clk;
	end
	
	// phase
	reg							phase;
	always @ ( posedge clk_x2 ) begin
		phase <= clk_dly;
	end
	
	
	generate
	if ( TYPE == 0 ) begin
		// ---------------------------------
		//  x2 clock DP-RAM
		// ---------------------------------
		
		// dualport ram
		wire						ram_en0;
		wire						ram_we0;
		wire	[ADDR_WIDTH-1:0]	ram_addr0;
		wire	[DATA_WIDTH-1:0]	ram_din0;
		wire	[DATA_WIDTH-1:0]	ram_dout0;
		wire						ram_en1;
		wire						ram_we1;
		wire	[ADDR_WIDTH-1:0]	ram_addr1;
		wire	[DATA_WIDTH-1:0]	ram_din1;
		wire	[DATA_WIDTH-1:0]	ram_dout1;
		
		ram_dualport_xilinx
				#(
					.DATA_WIDTH		(DATA_WIDTH),
					.ADDR_WIDTH		(ADDR_WIDTH),
					.MEM_SIZE		((1 << (ADDR_WIDTH)))
				)
			i_ram_dualport
				(
					.clk0			(clk_x2),
					.en0			(ram_en0),
					.we0			(ram_we0),
					.addr0			(ram_addr0),
					.din0			(ram_din0),
					.dout0			(ram_dout0),
					
					.clk1			(clk_x2),
					.en1			(ram_en1),
					.we1			(ram_we1),
					.addr1			(ram_addr1),
					.din1			(ram_din1),
					.dout1			(ram_dout1)
				);
		
		assign ram_en0   = (phase == 1'b0) ? r0_en   : w0_en;
		assign ram_we0   = (phase == 1'b0) ? 1'b0    : 1'b1;
		assign ram_addr0 = (phase == 1'b0) ? r0_addr : w0_addr;
		assign ram_din0  = w0_data;
		
		assign ram_en1   = (phase == 1'b0) ? r1_en   : w1_en;
		assign ram_we1   = (phase == 1'b0) ? 1'b0    : 1'b1;
		assign ram_addr1 = (phase == 1'b0) ? r1_addr : w1_addr;
		assign ram_din1  = w1_data;
		
		
		reg		[DATA_WIDTH-1:0]	r0_rdata;	
		always @ ( posedge clk or posedge reset ) begin
			if ( reset ) begin
				r0_rdata <= 0;
			end
			else begin
				if ( !interlock ) begin
					if ( r0_en ) begin
						if ( w0_en & (r0_addr == w0_addr) ) begin
							r0_rdata <= w0_data;
						end
						else if ( w1_en & (r0_addr == w1_addr) ) begin
							r0_rdata <= w1_data;
						end
						else begin
							r0_rdata <= ram_dout0;
						end
					end
				end
			end
		end
		
		reg		[DATA_WIDTH-1:0]	r1_rdata;
		always @ ( posedge clk or posedge reset ) begin
			if ( reset ) begin
				r1_rdata <= 0;
			end
			else begin
				if ( !interlock ) begin
					if ( r1_en ) begin
						if ( w0_en & (r1_addr == w0_addr) ) begin
							r1_rdata <= w0_data;
						end
						else if ( w1_en & (r1_addr == w1_addr) ) begin
							r1_rdata <= w1_data;
						end
						else begin
							r1_rdata <= ram_dout1;
						end
					end
				end
			end
		end
		
		assign r0_data = r0_rdata;
		assign r1_data = r1_rdata;
		
	end
	else if ( TYPE == 1 ) begin
		// ---------------------------------
		//  Dual DP-RAM (w1 port not support)
		// ---------------------------------
		
		genvar i;
		for ( i = 0; i < 2; i = i + 1 ) begin :dpram
			// dualport ram
			wire						ram_en0;
			wire						ram_we0;
			wire	[ADDR_WIDTH-1:0]	ram_addr0;
			wire	[DATA_WIDTH-1:0]	ram_din0;
			wire	[DATA_WIDTH-1:0]	ram_dout0;
			wire						ram_en1;
			wire						ram_we1;
			wire	[ADDR_WIDTH-1:0]	ram_addr1;
			wire	[DATA_WIDTH-1:0]	ram_din1;
			wire	[DATA_WIDTH-1:0]	ram_dout1;
			
			ram_dualport
					#(
						.DATA_WIDTH		(DATA_WIDTH),
						.ADDR_WIDTH		(ADDR_WIDTH),
						.MEM_SIZE		((1 << (ADDR_WIDTH)))
					)
				i_ram_dualport
					(
						.clk0			(clk),
						.en0			(ram_en0),
						.we0			(ram_we0),
						.addr0			(ram_addr0),
						.din0			(ram_din0),
						.dout0			(ram_dout0),
						
						.clk1			(clk),
						.en1			(ram_en1),
						.we1			(ram_we1),
						.addr1			(ram_addr1),
						.din1			(ram_din1),
						.dout1			(ram_dout1)
					);
			
			// write
			assign ram_en0   = w0_en & !interlock;
			assign ram_we0   = 1'b1;
			assign ram_addr0 = w0_addr;
			assign ram_din0  = w0_data;
			
			// read
			reg							through;
			reg		[DATA_WIDTH-1:0]	write_data;
			wire	[DATA_WIDTH-1:0]	read_data;
			always @ ( posedge clk ) begin
				if ( !interlock ) begin
					through    <= ram_en0 & ram_we0 & (ram_addr0 == ram_addr1);
					write_data <= ram_din0;
				end
			end
			assign read_data = through   ? write_data : ram_dout1;
			
			wire	[DATA_WIDTH-1:0]	ram_rdata;
			reg							prev_interlock;
			reg		[DATA_WIDTH-1:0]	prev_data;
			always @ ( posedge clk or posedge reset ) begin
				if ( reset ) begin
					prev_interlock <= 1'b0;
					prev_data      <= {DATA_WIDTH{1'bx}};
				end
				else begin
					prev_interlock <= interlock;
					prev_data      <= ram_rdata;
				end
			end
			assign ram_rdata = prev_interlock ? prev_data  : read_data;
			
			if ( i == 0 ) begin
				assign ram_en1   = r0_en;
				assign ram_we1   = 1'b0;
				assign ram_addr1 = r0_addr;
				assign ram_din1  = {DATA_WIDTH{1'b0}};
				assign r0_data   = ram_rdata;
			end
			else begin
				assign ram_en1   = r1_en;
				assign ram_we1   = 1'b0;
				assign ram_addr1 = r1_addr;
				assign ram_din1  = {DATA_WIDTH{1'b0}};
				assign r1_data   = ram_rdata;
			end
		end
	end
	else begin
		// ---------------------------------
		//  LUT (w1 port not support)
		// ---------------------------------
		
		reg		[DATA_WIDTH-1:0]	reg_gpr		[0:REG_SIZE-1];
		reg		[DATA_WIDTH-1:0]	reg_read0;
		reg		[DATA_WIDTH-1:0]	reg_read1;
		
		always @ ( posedge clk ) begin
			if ( w0_en ) begin
				reg_gpr[w0_addr] <= w0_data;
			end
			
			if ( !interlock ) begin
				if ( r0_en ) begin
					reg_read0 <= w0_en & (w0_addr == r0_addr) ? w0_data : reg_gpr[r0_addr];
				end
				
				if ( r1_en ) begin
					reg_read1 <= w0_en & (w0_addr == r1_addr) ? w0_data : reg_gpr[r1_addr];
				end
			end
		end
		
		assign r0_data = reg_read0;
		assign r1_data = reg_read1;
	end
	endgenerate
	
endmodule


