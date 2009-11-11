// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// WISHBONE bus to Jelly bus
module jelly_wishbone_to_jbus
		#(
			parameter									ADDR_WIDTH   = 30,
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
			input	wire	[ADDR_WIDTH-1:0]			wb_slave_adr_i,
			input	wire	[DATA_WIDTH-1:0]			wb_slave_dat_i,
			output	wire	[DATA_WIDTH-1:0]			wb_slave_dat_o,
			input	wire								wb_slave_we_i,
			input	wire	[SEL_WIDTH-1:0]				wb_slave_sel_i,
			input	wire								wb_slave_stb_i,
			output	wire								wb_slave_ack_o,
			
			// CPU bus
			output	wire								jbus_master_en,
			output	wire	[ADDR_WIDTH-1:0]			jbus_master_addr,
			output	wire	[DATA_WIDTH-1:0]			jbus_master_wdata,
			input	wire	[DATA_WIDTH-1:0]			jbus_master_rdata,
			output	wire								jbus_master_we,
			output	wire	[SEL_WIDTH-1:0]				jbus_master_sel,
			output	wire								jbus_master_valid,
			input	wire								jbus_master_ready
		);
	
	
	// read state
	reg							reg_master_read;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_master_read<= 1'b0;
		end
		else begin
			if ( jbus_master_en & jbus_master_ready ) begin
				reg_master_read <= jbus_master_valid & !jbus_master_we;
			end
		end
	end
	
	
	generate
	if ( PIPELINE == 0 ) begin
		// no wait
		assign jbus_master_en    = 1'b1;
		assign jbus_master_addr  = wb_slave_adr_i;
		assign jbus_master_wdata = wb_slave_dat_i;
		assign jbus_master_we    = wb_slave_we_i;
		assign jbus_master_sel   = wb_slave_sel_i;
		assign jbus_master_valid = wb_slave_stb_i & !reg_master_read;
		
		assign wb_slave_dat_o = jbus_master_rdata;
		assign wb_slave_ack_o = jbus_master_ready & (reg_master_read | jbus_master_we);
	end
	else begin
		// insert FF
		reg		[ADDR_WIDTH-1:0]	reg_jbus_addr;
		reg		[DATA_WIDTH-1:0]	reg_jbus_wdata;
		reg							reg_jbus_we;
 		reg		[SEL_WIDTH-1:0]		reg_jbus_sel;
		reg							reg_jbus_valid;
		reg		[DATA_WIDTH-1:0]	reg_wb_dat_o;
		reg							reg_wb_ack_o;
		
		always @( posedge clk ) begin
			if ( reset ) begin
				reg_jbus_addr  <= {ADDR_WIDTH{1'bx}};
				reg_jbus_wdata <= {DATA_WIDTH{1'bx}};
				reg_jbus_we    <= 1'bx;
			 	reg_jbus_sel   <= {SEL_WIDTH{1'bx}};
				reg_jbus_valid <= 1'b0;
				
				reg_wb_dat_o   <= {DATA_WIDTH{1'bx}};
				reg_wb_ack_o   <= 1'b0;
			end
			else begin
				if ( jbus_master_ready ) begin
					reg_jbus_addr  <= wb_slave_adr_i;
					reg_jbus_wdata <= wb_slave_dat_i;
					reg_jbus_we    <= wb_slave_we_i;
				 	reg_jbus_sel   <= wb_slave_sel_i;
					reg_jbus_valid <= wb_slave_stb_i & !reg_master_read;
					
					reg_wb_dat_o   <= jbus_master_rdata;
					reg_wb_ack_o   <= wb_slave_stb_i & (wb_slave_we_i | & reg_master_read);
				end
				else begin
					reg_wb_dat_o   <= jbus_master_rdata;
					reg_wb_ack_o   <= 1'b0;
				end
			end
		end
		
		assign jbus_master_en    = 1'b1;
		assign jbus_master_addr  = reg_jbus_addr;
		assign jbus_master_wdata = reg_jbus_wdata;
		assign jbus_master_we    = reg_jbus_we;
		assign jbus_master_sel   = reg_jbus_sel;
		assign jbus_master_valid = reg_jbus_valid;
		
		assign wb_slave_dat_o    = reg_wb_dat_o;
		assign wb_slave_ack_o    = reg_wb_ack_o;
	end
	endgenerate
	
endmodule

