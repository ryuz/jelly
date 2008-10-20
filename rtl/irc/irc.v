// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    Interrupt controller
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------



`timescale 1ns / 1ps



module irc
		(
			reset, clk,
			interrupt_in, interrupt_req,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	FACTOR_NUM     = 2;
	parameter	PRIORITY_WIDTH = 3;
	
	parameter	WB_ADR_WIDTH   = 8;
	parameter	WB_DAT_WIDTH   = 32;
	localparam	WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8);
	
	// system
	input							clk;
	input							reset;
	
	// interrupt
	input	[FACTOR_NUM-1:0]		interrupt_in;
	output							interrupt_req;
	
	// control port (wishbone)
	input	[WB_ADR_WIDTH-1:0]		wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]		wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]		wb_dat_i;
	input							wb_we_i;
	input	[WB_SEL_WIDTH-1:0]		wb_sel_i;
	input							wb_stb_i;
	output							wb_ack_o;
	
	
	// register
	reg		[PRIORITY_WIDTH-1:0]	reg_mask;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_mask <= {PRIORITY_WIDTH{1'b1}};
		end
		else begin
			// enable
			if ( wb_stb_i & wb_we_i & (wb_adr_i == 0) ) begin
				reg_mask <= wb_dat_i;
			end
		end
	end
	
	
	wire	[FACTOR_NUM-1:0]		factor_interrupt_req;
	wire	[WB_DAT_WIDTH-1:0]		factor_wb_dat_o		[FACTOR_NUM-1:0];
	
	generate
	genvar	i;
	for ( i = 0; i < FACTOR_NUM; i = i + 1 ) begin : factors
		wire							f_interrupt_req;		
		wire	[WB_DAT_WIDTH-1:0]		f_wb_dat_o;
		irc_factor
				#(
					.PRIORITY_WIDTH	(PRIORITY_WIDTH	),
					.WB_DAT_WIDTH   (WB_DAT_WIDTH)
				)
			i_irc_factor
				(
					.reset			(reset),
					.clk			(clk),
					
					.interrupt_in	(interrupt_in[i]),
					.interrupt_req	(f_interrupt_req),
					.mask_level		(reg_mask),
					
					.wb_adr_i		(wb_adr_i[1:0]),
					.wb_dat_o		(f_wb_dat_o),
					.wb_dat_i		(wb_dat_i),
					.wb_we_i		(wb_we_i),
					.wb_sel_i		(wb_sel_i),
					.wb_stb_i		(wb_stb_i & (wb_adr_i[WB_ADR_WIDTH-1:2] == (i-1))),
					.wb_ack_o		()
				);
		if ( i == 0 ) begin
			assign factor_interrupt_req[i] = f_interrupt_req;
			assign factor_wb_dat_o[i]      = f_wb_dat_o;
		end
		else begin
			assign factor_interrupt_req[i] = f_interrupt_req | factor_interrupt_req[i-1];
			assign factor_wb_dat_o[i]      = f_wb_dat_o      | factor_wb_dat_o[i-1];   
		end
	end
	endgenerate
	

	assign interrupt_req  = factor_interrupt_req[FACTOR_NUM-1];

	assign wb_dat_o       =	((wb_adr_i == 0) ? FACTOR_NUM : {WB_DAT_WIDTH{1'b0}}) |
							((wb_adr_i == 3) ? reg_mask   : {WB_DAT_WIDTH{1'b0}}) |
							factor_wb_dat_o[FACTOR_NUM-1];
	
	assign wb_ack_o = 1'b1;
	
endmodule



