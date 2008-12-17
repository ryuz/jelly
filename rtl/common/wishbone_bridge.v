// ---------------------------------------------------------------------------
//  Common components
//    wishbone bridge
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// wishbone bridge
module wishbone_bridge
		#(
			parameter							WB_ADR_WIDTH  = 31,
			parameter							WB_DAT_WIDTH  = 32,
			parameter							WB_SEL_WIDTH  = WB_DAT_WIDTH / 8
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// input from master device
			input	wire	[WB_ADR_WIDTH-1:0]	wb_in_adr_i,
			output	reg		[WB_DAT_WIDTH-1:0]	wb_in_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_in_dat_i,
			input	wire						wb_in_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_in_sel_i,
			input	wire						wb_in_stb_i,
			output	wire						wb_in_ack_o,
			
			// output to slave device
			output	reg		[WB_ADR_WIDTH-1:0]	wb_out_adr_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_out_dat_i,
			output	reg		[WB_DAT_WIDTH-1:0]	wb_out_dat_o,
			output	reg							wb_out_we_o,
			output	reg		[WB_SEL_WIDTH-1:0]	wb_out_sel_o,
			output	reg							wb_out_stb_o,
			input	wire						wb_out_ack_i
		);
	
	reg							reg_in_ack_o;
	
	reg							wb_out_read;
	
	reg		[WB_ADR_WIDTH-1:0]	reg_adr_o;
	reg		[WB_DAT_WIDTH-1:0]	reg_dat_o;
	reg							reg_we_o;
	reg		[WB_SEL_WIDTH-1:0]	reg_sel_o;
	reg							reg_stb_o;
	
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			wb_in_dat_o  <= {WB_DAT_WIDTH{1'bx}};
			reg_in_ack_o <= 1'b0;
			
			wb_out_adr_o <= {WB_ADR_WIDTH{1'bx}};
			wb_out_dat_o <= {WB_DAT_WIDTH{1'bx}};
			wb_out_we_o  <= 1'bx;
			wb_out_sel_o <= {WB_SEL_WIDTH{1'b0}};
			wb_out_stb_o <= 1'b0;
			wb_out_read  <= 1'b0;

			reg_adr_o    <= {WB_ADR_WIDTH{1'bx}};
			reg_dat_o    <= {WB_DAT_WIDTH{1'bx}};
			reg_we_o     <= 1'bx;
			reg_sel_o    <= {WB_SEL_WIDTH{1'bx}};
			reg_stb_o    <= 1'b0;
		end
		else begin
			// buffer
			if ( reg_stb_o ) begin
				if ( wb_out_ack_i ) begin
					reg_stb_o <= 1'b0;
				end
			end
			else begin
				if ( (wb_out_stb_o & ~wb_out_ack_i) ) begin
					reg_adr_o <= wb_in_adr_i;
					reg_dat_o <= wb_in_dat_i;
					reg_we_o  <= wb_in_we_i;
					reg_sel_o <= wb_in_sel_i;
					reg_stb_o <= (wb_in_stb_i & wb_out_we_o);
				end
			end
			
			// command
			if ( ~wb_out_stb_o | wb_out_ack_i ) begin
				if ( reg_stb_o ) begin
					wb_out_adr_o <= reg_adr_o;
					wb_out_dat_o <= reg_dat_o;
					wb_out_we_o  <= reg_we_o;
					wb_out_sel_o <= reg_sel_o;
					wb_out_stb_o <= reg_stb_o;
					wb_out_read  <= 1'b0;
				end
				else begin
					wb_out_adr_o <= wb_in_adr_i;
					wb_out_dat_o <= wb_in_dat_i;
					wb_out_we_o  <= wb_in_we_i;
					wb_out_sel_o <= wb_in_sel_i;
					wb_out_stb_o <= (wb_in_stb_i & ~reg_in_ack_o) & ~(wb_out_read & wb_out_ack_i);
					wb_out_read  <= (wb_in_stb_i & ~reg_in_ack_o & ~wb_in_we_i);
				end
			end
			
			// read data
			wb_in_dat_o <= wb_out_dat_i;
			reg_in_ack_o <= wb_out_stb_o & ~wb_out_we_o & wb_out_ack_i;
		end
	end
	
	
	assign wb_in_ack_o  = wb_in_we_i ? ~reg_stb_o : reg_in_ack_o;
	
	
endmodule

