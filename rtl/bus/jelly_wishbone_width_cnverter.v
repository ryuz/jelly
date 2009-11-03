// ---------------------------------------------------------------------------
//  Jelly
//   WISHBONE bus bridge width converter
//                                 Copyright (C) 2009 by Ryuji Fuchikami 
//                                 http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_wishbone_width_cnverter
		#(
			parameter	SLAVE_DAT_SIZE   = 3,	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	MASTER_DAT_SIZE  = 2,	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	SLAVE_ADR_WIDTH  = 29,
			parameter	SLAVE_DAT_WIDTH  = (8 << SLAVE_DAT_SIZE),
			parameter	SLAVE_SEL_WIDTH  = (1 << SLAVE_DAT_SIZE),
			parameter	MASTER_ADR_WIDTH = SLAVE_ADR_WIDTH + MASTER_DAT_SIZE - SLAVE_DAT_SIZE,
			parameter	MASTER_DAT_WIDTH = (8 << MASTER_DAT_SIZE),
			parameter	MASTER_SEL_WIDTH = (1 << MASTER_DAT_SIZE)
		)
		(
			// system
			input	wire							clk,
			input	wire							reset,
			
			input	wire							endian,
			
			// master port
			input	wire	[SLAVE_ADR_WIDTH-1:0]	wb_slave_adr_i,
			output	wire	[SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_o,
			input	wire	[SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_i,
			input	wire							wb_slave_we_i,
			input	wire	[SLAVE_SEL_WIDTH-1:0]	wb_slave_sel_i,
			input	wire							wb_slave_stb_i,
			output	wire							wb_slave_ack_o,
			
			// master port
			output	wire	[MASTER_ADR_WIDTH-1:0]	wb_master_adr_o,
			output	wire	[MASTER_DAT_WIDTH-1:0]	wb_master_dat_o,
			input	wire	[MASTER_DAT_WIDTH-1:0]	wb_master_dat_i,
			output	wire							wb_master_we_o,
			output	wire	[MASTER_SEL_WIDTH-1:0]	wb_master_sel_o,
			output	wire							wb_master_stb_o,
			input	wire							wb_master_ack_i
		);
	
	localparam	RATE = (SLAVE_DAT_SIZE > MASTER_DAT_SIZE) ? (SLAVE_DAT_SIZE - MASTER_DAT_SIZE) : (MASTER_DAT_SIZE - SLAVE_DAT_SIZE);
	
	generate
	if ( MASTER_DAT_SIZE < SLAVE_DAT_SIZE ) begin
		// to narrow
		reg		[RATE-1:0]				reg_counter;
		integer							i0, j0;
		reg		[SLAVE_DAT_WIDTH-1:0]	reg_master_dat_i;
		always @(posedge clk) begin
			if ( reset ) begin
				reg_counter <= {RATE{1'b0}};
			end
			else begin
				if ( wb_slave_stb_i & ((wb_master_sel_o == 0) | wb_master_ack_i) ) begin
					reg_counter <= reg_counter;
				end
			end
			
			for ( i0 = 0; i0 < (1 << RATE); i0 = i0 + 1 ) begin
				if ( i0 == reg_counter ) begin
					for ( j0 = 0; j0 < MASTER_DAT_WIDTH; j0 = j0 + 1 ) begin
						reg_master_dat_i[MASTER_DAT_WIDTH*i0 + j0] <= wb_master_dat_i[j0];
					end
				end
			end
		end
		
		reg		[MASTER_DAT_WIDTH-1:0]	tmp_master_dat_o;
		reg		[MASTER_DAT_WIDTH-1:0]	tmp_master_sel_o;
		reg		[MASTER_DAT_WIDTH-1:0]	tmp_master_dat_i	[0:(1 << RATE)-2];
		reg		[SLAVE_DAT_WIDTH-1:0]	tmp_slave_dat_o;
		integer							i1, j1;
		always @( reg_counter or wb_slave_dat_i or wb_master_dat_i or reg_master_dat_i ) begin
			for ( i1 = 0; i1 < (1 << RATE); i1 = i1 + 1 ) begin
				if ( i1 == (reg_counter ^ {RATE{endian}}) ) begin
					for ( j1 = 0; j1 < MASTER_DAT_WIDTH; j1 = j1 + 1 ) begin
						tmp_master_dat_o[j1] = wb_slave_dat_i[MASTER_DAT_WIDTH*i1 + j1];
					end
					for ( j1 = 0; j1 < MASTER_SEL_WIDTH; j1 = j1 + 1 ) begin
						tmp_master_sel_o[j1] = wb_slave_sel_i[MASTER_SEL_WIDTH*i1 + j1];
					end
				end
			end
			
			for ( i1 = 0; i1 < (1 << RATE); i1 = i1 + 1 ) begin
				if ( i1 == {RATE{1'b1}} ) begin
					for ( j1 = 0; j1 < MASTER_DAT_WIDTH; j1 = j1 + 1 ) begin
						tmp_slave_dat_o[MASTER_DAT_WIDTH*(i1 ^ {RATE{endian}}) + j1] = wb_master_dat_i[j1];
					end
				end
				else begin
					for ( j1 = 0; j1 < MASTER_DAT_WIDTH; j1 = j1 + 1 ) begin
						tmp_slave_dat_o[MASTER_DAT_WIDTH*(i1 ^ {RATE{endian}}) + j1] = reg_master_dat_i[MASTER_DAT_WIDTH*i1 + j1];
					end
				end
			end			
		end
		
		assign wb_master_adr_o = {wb_slave_adr_i, reg_counter};
		assign wb_master_dat_o = tmp_master_dat_o;
		assign wb_master_sel_o = tmp_master_sel_o;
		assign wb_master_stb_o = wb_master_stb_o & (tmp_master_sel_o != 0);
		
		assign wb_slave_dat_o  = tmp_slave_dat_o;
		assign wb_slave_ack_o  = (reg_counter == {RATE{1'b1}}) & ((wb_master_sel_o == 0) | wb_master_ack_i); 
	end
	else if ( MASTER_DAT_SIZE > SLAVE_DAT_SIZE ) begin
		// to wide
		
	end
	else begin
		// same width
		assign wb_master_adr_o = wb_slave_adr_i;
		assign wb_master_dat_o = wb_slave_dat_o;
		assign wb_slave_dat_i  = wb_master_dat_i;
		assign wb_master_we_o  = wb_slave_we_i;
		assign wb_master_sel_o = wb_slave_sel_i;
		assign wb_master_stb_o = wb_slave_stb_i;
		assign wb_slave_ack_o  = wb_master_ack_i;
	end
	endgenerate
	
endmodule


// end of file
