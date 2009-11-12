// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


module jelly_wishbone_width_converter
		#(
			parameter	WB_SLAVE_DAT_SIZE   = 3,	// 2^n (0:8bit, 1:16bit, 2:32bit, 3:64bit ...)
			parameter	WB_SLAVE_ADR_WIDTH  = 29,
			parameter	WB_SLAVE_DAT_WIDTH  = (8 << WB_SLAVE_DAT_SIZE),
			parameter	WB_SLAVE_SEL_WIDTH  = (1 << WB_SLAVE_DAT_SIZE),
			
			parameter	WB_MASTER_DAT_SIZE  = 2,	// 2^n (0:8bit, 1:16bit, 2:32bit, 3:64bit ...)
			parameter	WB_MASTER_ADR_WIDTH = WB_SLAVE_ADR_WIDTH + WB_SLAVE_DAT_SIZE - WB_MASTER_DAT_SIZE,
			parameter	WB_MASTER_DAT_WIDTH = (8 << WB_MASTER_DAT_SIZE),
			parameter	WB_MASTER_SEL_WIDTH = (1 << WB_MASTER_DAT_SIZE)
		)
		(
			// system
			input	wire								clk,
			input	wire								reset,
			
			input	wire								endian,
			
			// master port
			input	wire	[WB_SLAVE_ADR_WIDTH-1:0]	wb_slave_adr_i,
			output	wire	[WB_SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_o,
			input	wire	[WB_SLAVE_DAT_WIDTH-1:0]	wb_slave_dat_i,
			input	wire								wb_slave_we_i,
			input	wire	[WB_SLAVE_SEL_WIDTH-1:0]	wb_slave_sel_i,
			input	wire								wb_slave_stb_i,
			output	wire								wb_slave_ack_o,
			
			// master port
			output	wire	[WB_MASTER_ADR_WIDTH-1:0]	wb_master_adr_o,
			output	wire	[WB_MASTER_DAT_WIDTH-1:0]	wb_master_dat_o,
			input	wire	[WB_MASTER_DAT_WIDTH-1:0]	wb_master_dat_i,
			output	wire								wb_master_we_o,
			output	wire	[WB_MASTER_SEL_WIDTH-1:0]	wb_master_sel_o,
			output	wire								wb_master_stb_o,
			input	wire								wb_master_ack_i
		);
	
	localparam	RATE = (WB_SLAVE_DAT_SIZE > WB_MASTER_DAT_SIZE) ? (WB_SLAVE_DAT_SIZE - WB_MASTER_DAT_SIZE) : (WB_MASTER_DAT_SIZE - WB_SLAVE_DAT_SIZE);
	
	generate
	if ( WB_MASTER_DAT_SIZE < WB_SLAVE_DAT_SIZE ) begin
		// to narrow
		reg		[RATE-1:0]					reg_counter;
		integer								i0, j0;
		reg		[WB_SLAVE_DAT_WIDTH-1:0]	reg_master_dat_i;
		always @(posedge clk) begin
			if ( reset ) begin
				reg_counter <= {RATE{1'b0}};
			end
			else begin
				if ( wb_slave_stb_i & ((wb_master_sel_o == 0) | wb_master_ack_i) ) begin
					reg_counter <= reg_counter + 1;
				end
			end
			
			for ( i0 = 0; i0 < (1 << RATE); i0 = i0 + 1 ) begin
				if ( i0 == reg_counter ) begin
					for ( j0 = 0; j0 < WB_MASTER_DAT_WIDTH; j0 = j0 + 1 ) begin
						reg_master_dat_i[WB_MASTER_DAT_WIDTH*i0 + j0] <= wb_master_dat_i[j0];
					end
				end
			end
		end
		
		reg		[WB_MASTER_DAT_WIDTH-1:0]	tmp_master_dat_o;
		reg		[WB_MASTER_SEL_WIDTH-1:0]	tmp_master_sel_o;
		reg		[WB_SLAVE_DAT_WIDTH-1:0]	tmp_slave_dat_o;
		integer								i1, j1;
		always @* begin
			tmp_master_dat_o = {WB_MASTER_DAT_WIDTH{1'b0}};
			tmp_master_sel_o = {WB_MASTER_SEL_WIDTH{1'b0}}; 
			tmp_slave_dat_o  = {WB_SLAVE_DAT_WIDTH-1{1'b0}};
			for ( i1 = 0; i1 < (1 << RATE); i1 = i1 + 1 ) begin
				if ( i1 == (reg_counter ^ {RATE{endian}}) ) begin
					for ( j1 = 0; j1 < WB_MASTER_DAT_WIDTH; j1 = j1 + 1 ) begin
						tmp_master_dat_o[j1] = wb_slave_dat_i[WB_MASTER_DAT_WIDTH*i1 + j1];
					end
					for ( j1 = 0; j1 < WB_MASTER_SEL_WIDTH; j1 = j1 + 1 ) begin
						tmp_master_sel_o[j1] = wb_slave_sel_i[WB_MASTER_SEL_WIDTH*i1 + j1];
					end
				end
			end
			
			for ( i1 = 0; i1 < (1 << RATE); i1 = i1 + 1 ) begin
				if ( i1 == {RATE{1'b1}} ) begin
					for ( j1 = 0; j1 < WB_MASTER_DAT_WIDTH; j1 = j1 + 1 ) begin
						tmp_slave_dat_o[WB_MASTER_DAT_WIDTH*(i1 ^ {RATE{endian}}) + j1] = wb_master_dat_i[j1];
					end
				end
				else begin
					for ( j1 = 0; j1 < WB_MASTER_DAT_WIDTH; j1 = j1 + 1 ) begin
						tmp_slave_dat_o[WB_MASTER_DAT_WIDTH*(i1 ^ {RATE{endian}}) + j1] = reg_master_dat_i[WB_MASTER_DAT_WIDTH*i1 + j1];
					end
				end
			end			
		end
		
		assign wb_master_adr_o = {wb_slave_adr_i, reg_counter};
		assign wb_master_dat_o = tmp_master_dat_o;
		assign wb_master_we_o  = wb_slave_we_i;
		assign wb_master_sel_o = tmp_master_sel_o;
		assign wb_master_stb_o = wb_slave_stb_i & (tmp_master_sel_o != 0);
		
		assign wb_slave_dat_o  = tmp_slave_dat_o;
		assign wb_slave_ack_o  = (reg_counter == {RATE{1'b1}}) & ((wb_master_sel_o == 0) | wb_master_ack_i); 
	end
	else if ( WB_MASTER_DAT_SIZE > WB_SLAVE_DAT_SIZE ) begin
		// to wide
		reg		[WB_MASTER_SEL_WIDTH-1:0]	tmp_master_sel_o;
		reg		[WB_SLAVE_DAT_WIDTH-1:0]	tmp_slave_dat_o;
		integer								i, j;
		always @* begin
		    tmp_master_sel_o = {WB_MASTER_SEL_WIDTH{1'b0}};
		    tmp_slave_dat_o  = {WB_SLAVE_DAT_WIDTH{1'b0}};
			for ( i = 0; i < (1 << RATE); i = i + 1 ) begin
				if ( i == (wb_slave_adr_i[RATE-1:0] ^ {RATE{endian}}) ) begin
					for ( j = 0; j < WB_SLAVE_SEL_WIDTH; j = j + 1 ) begin
						tmp_master_sel_o[WB_SLAVE_SEL_WIDTH*i + j] = wb_slave_sel_i[j];
					end
					for ( j = 0; j < WB_SLAVE_DAT_WIDTH; j = j + 1 ) begin
						tmp_slave_dat_o[j] = wb_master_dat_i[WB_SLAVE_DAT_WIDTH*i + j];
					end					
				end
			end
		end
		assign wb_master_adr_o = (wb_slave_adr_i >> RATE);
		assign wb_master_dat_o = {(1 << RATE){wb_slave_dat_i}};
		assign wb_slave_dat_o  = tmp_slave_dat_o;
		assign wb_master_we_o  = wb_slave_we_i;
		assign wb_master_sel_o = tmp_master_sel_o;
		assign wb_master_stb_o = wb_slave_stb_i;
		assign wb_slave_ack_o  = wb_master_ack_i;
	end
	else begin
		// same width
		assign wb_master_adr_o = wb_slave_adr_i;
		assign wb_master_dat_o = wb_slave_dat_i;
		assign wb_slave_dat_o  = wb_master_dat_i;
		assign wb_master_we_o  = wb_slave_we_i;
		assign wb_master_sel_o = wb_slave_sel_i;
		assign wb_master_stb_o = wb_slave_stb_i;
		assign wb_slave_ack_o  = wb_master_ack_i;
	end
	endgenerate
	
endmodule


// end of file
