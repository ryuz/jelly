// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// wishbone bridge
module jelly_wishbone_bridge
		#(
			parameter	WB_ADR_WIDTH  = 30,
			parameter	WB_DAT_WIDTH  = 32,
			parameter	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
			parameter	THROUGH       = 1,
			parameter	MASTER_FF     = 0,
			parameter	SLAVE_FF      = !THROUGH
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// slave port
			input	wire	[WB_ADR_WIDTH-1:0]	wb_slave_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_slave_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_slave_dat_i,
			input	wire						wb_slave_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_slave_sel_i,
			input	wire						wb_slave_stb_i,
			output	wire						wb_slave_ack_o,
			
			// master port
			output	wire	[WB_ADR_WIDTH-1:0]	wb_master_adr_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_master_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_master_dat_o,
			output	wire						wb_master_we_o,
			output	wire	[WB_SEL_WIDTH-1:0]	wb_master_sel_o,
			output	wire						wb_master_stb_o,
			input	wire						wb_master_ack_i
		);
	
	// temporary
	wire	[WB_ADR_WIDTH-1:0]	wb_tmp_adr_o;
	wire	[WB_DAT_WIDTH-1:0]	wb_tmp_dat_i;
	wire	[WB_DAT_WIDTH-1:0]	wb_tmp_dat_o;
	wire						wb_tmp_we_o;
	wire	[WB_SEL_WIDTH-1:0]	wb_tmp_sel_o;
	wire						wb_tmp_stb_o;
	wire						wb_tmp_ack_i;
	
	
	// slave port
	generate
	if ( SLAVE_FF ) begin
		// insert FF
		reg		[WB_DAT_WIDTH-1:0]	reg_slave_dat_o;
		reg							reg_slave_ack_o;		
		always @ ( posedge clk ) begin
			if ( reset ) begin
				reg_slave_dat_o  <= {WB_DAT_WIDTH{1'bx}};
				reg_slave_ack_o  <= 1'b0;
			end
			else begin
				reg_slave_dat_o  <= wb_tmp_dat_i;
				reg_slave_ack_o  <= wb_tmp_stb_o & wb_tmp_ack_i;
			end
		end
		
		assign wb_tmp_adr_o    = wb_slave_adr_i;
		assign wb_tmp_dat_o    = wb_slave_dat_i;
		assign wb_tmp_we_o     = wb_slave_we_i;
		assign wb_tmp_sel_o    = wb_slave_sel_i;
		assign wb_tmp_stb_o    = wb_slave_stb_i & !reg_slave_ack_o;
		
		assign wb_slave_dat_o  = reg_slave_dat_o;
		assign wb_slave_ack_o  = reg_slave_ack_o;		
	end
	else begin
		// through
		assign wb_tmp_adr_o    = wb_slave_adr_i;
		assign wb_tmp_dat_o    = wb_slave_dat_i;
		assign wb_tmp_we_o     = wb_slave_we_i;
		assign wb_tmp_sel_o    = wb_slave_sel_i;
		assign wb_tmp_stb_o    = wb_slave_stb_i;
		
		assign wb_slave_dat_o  = wb_tmp_dat_i;
		assign wb_slave_ack_o  = wb_tmp_ack_i;
	end
	endgenerate
	
	
	// master port
	generate
	if ( MASTER_FF ) begin
		// insert FF
		reg		[WB_ADR_WIDTH-1:0]	reg_master_adr_o;
		reg		[WB_DAT_WIDTH-1:0]	reg_master_dat_o;
		reg							reg_master_we_o;
		reg		[WB_SEL_WIDTH-1:0]	reg_master_sel_o;
		reg							reg_master_stb_o;
		always @ ( posedge clk ) begin
			if ( reset ) begin
				reg_master_adr_o <= {WB_ADR_WIDTH{1'bx}};
				reg_master_dat_o <= {WB_DAT_WIDTH{1'bx}};
				reg_master_we_o  <= 1'bx;
				reg_master_sel_o <= {WB_SEL_WIDTH{1'bx}};
				reg_master_stb_o <= 1'b0;
			end
			else begin
				reg_master_adr_o <= wb_tmp_adr_o;
				reg_master_dat_o <= wb_tmp_dat_o;
				reg_master_we_o  <= wb_tmp_we_o;
				reg_master_sel_o <= wb_tmp_sel_o;
				reg_master_stb_o <= wb_tmp_stb_o & !(reg_master_stb_o & wb_tmp_ack_i);
			end
		end
		
		assign wb_master_adr_o = reg_master_adr_o;
		assign wb_master_dat_o = reg_master_dat_o;
		assign wb_master_we_o  = reg_master_we_o;
		assign wb_master_sel_o = reg_master_sel_o;
		assign wb_master_stb_o = reg_master_stb_o;
		
		assign wb_tmp_dat_i    = wb_master_dat_i;
		assign wb_tmp_ack_i    = wb_master_ack_i;		
	end
	else begin
		// through
		assign wb_master_adr_o = wb_tmp_adr_o;
		assign wb_master_dat_o = wb_tmp_dat_o;
		assign wb_master_we_o  = wb_tmp_we_o;
		assign wb_master_sel_o = wb_tmp_sel_o;
		assign wb_master_stb_o = wb_tmp_stb_o;
		              
		assign wb_tmp_dat_i    = wb_master_dat_i;
		assign wb_tmp_ack_i    = wb_master_ack_i;
	end
	endgenerate
	
	/*
	generate
	if ( THROUGH ) begin
		assign wb_master_adr_o = wb_slave_adr_i;
		assign wb_slave_dat_o  = wb_master_dat_i;
		assign wb_master_dat_o = wb_slave_dat_i;
		assign wb_master_we_o  = wb_slave_we_i;
		assign wb_master_sel_o = wb_slave_sel_i;
		assign wb_master_stb_o = wb_slave_stb_i;
		assign wb_slave_ack_o  = wb_master_ack_i;
	end
	else begin
		reg		[WB_DAT_WIDTH-1:0]	reg_slave_dat_o;
		reg							reg_slave_ack_o;
		
		reg							reg_master_read;
		reg		[WB_ADR_WIDTH-1:0]	reg_master_adr_o;
		reg		[WB_DAT_WIDTH-1:0]	reg_master_dat_o;
		reg							reg_master_we_o;
		reg		[WB_SEL_WIDTH-1:0]	reg_master_sel_o;
		reg							reg_master_stb_o;
		
		always @ ( posedge clk ) begin
			if ( reset ) begin
				reg_slave_dat_o  <= {WB_DAT_WIDTH{1'bx}};
				reg_slave_ack_o  <= 1'b0;
				
				reg_master_adr_o <= {WB_ADR_WIDTH{1'bx}};
				reg_master_dat_o <= {WB_DAT_WIDTH{1'bx}};
				reg_master_we_o  <= 1'bx;
				reg_master_sel_o <= {WB_SEL_WIDTH{1'b0}};
				reg_master_stb_o <= 1'b0;
				reg_master_read  <= 1'b0;
			end
			else begin
				if ( !wb_master_stb_o | wb_master_ack_i ) begin
					reg_master_adr_o <= wb_slave_adr_i;
					reg_master_dat_o <= wb_slave_dat_i;
					reg_master_we_o  <= wb_slave_we_i;
					reg_master_sel_o <= wb_slave_sel_i;
					reg_master_stb_o <= wb_slave_stb_i & !reg_slave_ack_o;
				end
				
				reg_slave_data_o <= wb_master_dat_i;
				reg_slave_ack_o  <= wb_master_ack_i;
			end
		end
		
		assign wb_slave_dat_o  = reg_slave_dat_o;
		assign wb_slave_ack_o  = reg_slave_ack_o;
		
		assign wb_master_adr_o = reg_master_adr_o;
		assign wb_master_dat_o = reg_master_dat_o;
		assign wb_master_we_o  = reg_master_we_o;
		assign wb_master_sel_o = reg_master_sel_o;
		assign wb_master_stb_o = reg_master_stb_o;		
	end
	endgenerate
	*/
	
endmodule


// end of file
