// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// wishbone bridge
module jelly_wishbone_bridge
		#(
			parameter	WB_ADR_WIDTH  = 30,
			parameter	WB_DAT_WIDTH  = 32,
			parameter	WB_SEL_WIDTH  = WB_DAT_WIDTH / 8,
			parameter	THROUGH = 0
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
		reg							reg_slave_dat_o;
		reg							reg_slave_ack_o;
		
		reg							reg_master_read;
		reg		[WB_ADR_WIDTH-1:0]	reg_master_adr_o;
		reg		[WB_DAT_WIDTH-1:0]	reg_master_dat_o;
		reg							reg_master_we_o;
		reg		[WB_SEL_WIDTH-1:0]	reg_master_sel_o;
		reg							reg_master_stb_o;
		
		reg		[WB_ADR_WIDTH-1:0]	reg_adr_o;
		reg		[WB_DAT_WIDTH-1:0]	reg_dat_o;
		reg							reg_we_o;
		reg		[WB_SEL_WIDTH-1:0]	reg_sel_o;
		reg							reg_stb_o;
		
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

				reg_adr_o        <= {WB_ADR_WIDTH{1'bx}};
				reg_dat_o        <= {WB_DAT_WIDTH{1'bx}};
				reg_we_o         <= 1'bx;
				reg_sel_o        <= {WB_SEL_WIDTH{1'bx}};
				reg_stb_o        <= 1'b0;
			end
			else begin
				// buffer
				if ( reg_stb_o ) begin
					if ( wb_master_ack_i ) begin
						reg_stb_o <= 1'b0;
					end
				end
				else begin
					if ( (wb_master_stb_o & ~wb_master_ack_i) ) begin
						reg_adr_o <= wb_slave_adr_i;
						reg_dat_o <= wb_slave_dat_i;
						reg_we_o  <= wb_slave_we_i;
						reg_sel_o <= wb_slave_sel_i;
						reg_stb_o <= (wb_slave_stb_i & wb_master_we_o);
					end
				end
				
				// command
				if ( ~wb_master_stb_o | wb_master_ack_i ) begin
					if ( reg_stb_o ) begin
						reg_master_read  <= 1'b0;
						reg_master_adr_o <= reg_adr_o;
						reg_master_dat_o <= reg_dat_o;
						reg_master_we_o  <= reg_we_o;
						reg_master_sel_o <= reg_sel_o;
						reg_master_stb_o <= reg_stb_o;
					end
					else begin
						reg_master_adr_o <= wb_slave_adr_i;
						reg_master_dat_o <= wb_slave_dat_i;
						reg_master_we_o  <= wb_slave_we_i;
						reg_master_sel_o <= wb_slave_sel_i;
						reg_master_stb_o <= (wb_slave_stb_i & ~reg_slave_ack_o) & ~(reg_master_read & wb_master_ack_i);
						reg_master_read  <= (wb_slave_stb_i & ~reg_slave_ack_o & ~wb_slave_we_i);
					end
				end
				
				// read data
				reg_slave_dat_o <= wb_master_dat_i;
				reg_slave_ack_o <= wb_master_stb_o & ~wb_master_we_o & wb_master_ack_i;
			end
		end
		
		assign wb_slave_dat_o = reg_slave_dat_o;
		assign wb_slave_ack_o = wb_slave_we_i ? ~reg_stb_o : reg_slave_ack_o;
		
		assign wb_master_adr_o = reg_master_adr_o;
		assign wb_master_dat_o = reg_master_dat_o;
		assign wb_master_we_o  = reg_master_we_o;
		assign wb_master_sel_o = reg_master_sel_o;
		assign wb_master_stb_o = reg_master_stb_o;		
	end
	endgenerate
	
endmodule


// end of file
