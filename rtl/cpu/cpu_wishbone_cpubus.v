// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// WISHBONE-bus to CPU-bus
module jelly_cpu_wishbone_cpubus
		#(
			parameter									ADDR_WIDTH   = 32,
			parameter									DATA_SIZE    = 2,  				// 0:8bit, 1:16bit, 2:32bit ...
			parameter									SEL_WIDTH    = (1 << DATA_SIZE),
			parameter									DATA_WIDTH   = (8 << DATA_SIZE),
			parameter									PIPELINE     = 1
		)
		(
			// system
			input	wire								reset,
			input	wire								clk,
			
			// WISHBONE bus
			input	wire	[ADDR_WIDTH-1:DATA_SIZE]	wb_adr_i,
			input	wire	[DATA_WIDTH-1:0]			wb_dat_i,
			output	wire	[DATA_WIDTH-1:0]			wb_dat_o,
			input	wire								wb_we_i,
			input	wire	[SEL_WIDTH-1:0]				wb_sel_i,
			input	wire								wb_stb_i,
			output	wire								wb_ack_o,
			
			// CPU bus
			output	wire								cpubus_interlock,
			output	wire								cpubus_en,
			output	wire								cpubus_we,
			output	wire	[SEL_WIDTH-1:0]				cpubus_sel,
			output	wire	[ADDR_WIDTH-1:0]			cpubus_addr,
			output	wire	[DATA_WIDTH-1:0]			cpubus_wdata,
			input	wire	[DATA_WIDTH-1:0]			cpubus_rdata,
			input	wire								cpubus_busy
		);
	
	generate
	if ( PIPELINE == 0 ) begin
		// no wait
		assign cpubus_interlock = 1'b0;
		assign cpubus_en        = wb_stb_i;
		assign cpubus_we        = wb_we_i;
		assign cpubus_sel       = wb_sel_i;
		assign cpubus_addr      = wb_adr_i;
		assign cpubus_wdata     = wb_dat_i;
		
		reg							cpubus_reg_ack;
		always @( posedge clk ) begin
			if ( reset ) begin
				cpubus_reg_ack <= 1'b0;
			end
			else begin
				if ( !cpubus_busy ) begin
					cpubus_reg_ack <= cpubus_en & !cpubus_we;
				end
			end
		end
		
		assign wb_dat_o = cpubus_rdata;
		assign wb_ack_o = !cpubus_busy & (cpubus_reg_ack | cpubus_we);
	end
	else begin
		// insert FF
		reg							cpubus_reg_en;
		reg							cpubus_reg_we;
 		reg		[SEL_WIDTH-1:0]		cpubus_reg_sel;
		reg		[ADDR_WIDTH-1:0]	cpubus_reg_addr;
		reg		[DATA_WIDTH-1:0]	cpubus_reg_wdata;
		reg							cpubus_reg_ack;
		
		always @( posedge clk ) begin
			if ( reset ) begin
				cpubus_reg_en    <= 1'b0;
				cpubus_reg_we    <= 1'bx;
			 	cpubus_reg_sel   <= {SEL_WIDTH{1'bx}};
				cpubus_reg_addr  <= {ADDR_WIDTH{1'bx}};
				cpubus_reg_wdata <= {DATA_WIDTH{1'bx}};
				cpubus_reg_ack   <= 1'b0;
			end
			else begin
				if ( !cpubus_busy ) begin
					cpubus_reg_en    <= wb_stb_i & !wb_ack_o & !cpubus_reg_en;
					cpubus_reg_we    <= wb_we_i;
				 	cpubus_reg_sel   <= wb_sel_i;
					cpubus_reg_addr  <= {wb_adr_i, {DATA_SIZE{1'b0}}};
					cpubus_reg_wdata <= wb_dat_i;
					cpubus_reg_ack   <= cpubus_en;
				end
				else begin
					cpubus_reg_ack   <= 1'b0;
				end
			end
		end
		assign cpubus_interlock = 1'b0;
		assign cpubus_en    = cpubus_reg_en;
		assign cpubus_we    = cpubus_reg_we;
		assign cpubus_sel   = cpubus_reg_sel;
		assign cpubus_addr  = cpubus_reg_addr;
		assign cpubus_wdata = cpubus_reg_wdata;
		
		assign wb_dat_o     = cpubus_rdata;
		assign wb_ack_o     = cpubus_reg_ack;
	end
	endgenerate
	
endmodule

