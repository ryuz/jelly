// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    Interrupt controller
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
//                                       http://homepage3.nifty.com/ryuz
// ----------------------------------------------------------------------------



`timescale 1ns / 1ps


// register address
`define IRC_ADR_ENABLE				0
`define IRC_ADR_MASK				1
`define IRC_ADR_REQ_FACTOR_ID		2
`define IRC_ADR_REQ_PRIORITY		3
`define IRC_ADR_FACTOR_NUM			4
`define IRC_ADR_PRIORITY_MAX		5
`define IRC_ADR_FACTOR_BASE			8


// Interrupt controller
module jelly_irc
		(
			reset, clk,
			in_interrupt,
			cpu_irq, cpu_irq_ack,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	FACTOR_ID_WIDTH = 2;
	parameter	FACTOR_NUM      = (1 << FACTOR_ID_WIDTH);
	parameter	PRIORITY_WIDTH  = 3;
	
	parameter	WB_ADR_WIDTH    = 16;
	parameter	WB_DAT_WIDTH    = 32;
	localparam	WB_SEL_WIDTH    = (WB_DAT_WIDTH / 8);
	
	
	// system
	input							clk;
	input							reset;
	
	// interrupt
	input	[FACTOR_NUM-1:0]		in_interrupt;
	
	// connect for cpu
	output							cpu_irq;
	input							cpu_irq_ack;
	
	// control port (wishbone)
	input	[WB_ADR_WIDTH-1:0]		wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]		wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]		wb_dat_i;
	input							wb_we_i;
	input	[WB_SEL_WIDTH-1:0]		wb_sel_i;
	input							wb_stb_i;
	output							wb_ack_o;
	
	
	
	// control register
	reg								reg_enable;
	reg		[PRIORITY_WIDTH-1:0]	reg_mask;
	reg		[PRIORITY_WIDTH-1:0]	reg_req_priority;
	reg		[FACTOR_ID_WIDTH-1:0]	reg_req_factor_id;
	
	
	// -----------------------------
	//  recive request
	// -----------------------------

	reg								prev_enable;
	reg		[PRIORITY_WIDTH-1:0]	recv_priority;
	reg		[FACTOR_ID_WIDTH-2:0]	recv_factor_id;
	
	wire	[FACTOR_NUM-1:0]		factor_request_send;
	wire							request_recv;
	assign request_recv = (factor_request_send == {FACTOR_NUM{1'b1}});
	
	localparam	PACKET_WIDTH = (PRIORITY_WIDTH + FACTOR_ID_WIDTH);
	reg		[PACKET_WIDTH:0]		recv_counter;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			prev_enable       <= 1'b0;
			reg_req_priority  <= {PRIORITY_WIDTH{1'b1}};
			reg_req_factor_id <= {PRIORITY_WIDTH{1'b0}};
			recv_counter      <= {{PACKET_WIDTH-1{1'b0}}, 1'b1};
		end
		else begin
			prev_enable <= reg_enable;
			if ( reg_enable ) begin
				// posedge reg_enable
				if ( !prev_enable ) begin
					reg_req_priority <= {PRIORITY_WIDTH{1'b1}};
				end
				
				// state counter
				recv_counter <= {recv_counter[PACKET_WIDTH-2:0], recv_counter[PACKET_WIDTH-1]};
				
				// packet receive
				{recv_priority, recv_factor_id} <= {recv_priority, recv_factor_id, request_recv};
				
				// recive end
				if ( recv_counter[PACKET_WIDTH-1] ) begin
					reg_req_priority  <= recv_priority;
					reg_req_factor_id <= {recv_factor_id, request_recv};
				end
			end
			else begin
				recv_counter <= {{PACKET_WIDTH-1{1'b0}}, 1'b1};
			end
		end
	end
	
	assign cpu_irq = reg_enable & prev_enable & (reg_req_priority < reg_mask);
	
	
	
	// -----------------------------
	//  factors
	// -----------------------------
	
	wire	[(WB_DAT_WIDTH*FACTOR_NUM)-1:0]		factor_wb_dat_o;
	
	generate
	genvar	i;
	for ( i = FACTOR_NUM - 1; i >= 0; i = i - 1 ) begin : factor
		wire	[FACTOR_ID_WIDTH-1:0]	f_factor_id;
		assign f_factor_id = i;
		
		wire	[WB_DAT_WIDTH-1:0]		f_wb_dat_o;
		irc_factor
				#(
					.FACTOR_ID_WIDTH	(FACTOR_ID_WIDTH),
					.PRIORITY_WIDTH		(PRIORITY_WIDTH),
					.WB_DAT_WIDTH   	(WB_DAT_WIDTH)
				)
			i_irc_factor
				(
					.reset			(reset),
					.clk			(clk),

					.factor_id		(f_factor_id),
					
					.in_interrupt	(in_interrupt[i]),
					
					.reqest_reset	(~reg_enable),
					.reqest_start	(recv_counter[0]),
					.reqest_send	(factor_request_send[i]),
					.reqest_sense	(request_recv),
					
					.wb_adr_i		(wb_adr_i[1:0]),
					.wb_dat_o		(f_wb_dat_o),
					.wb_dat_i		(wb_dat_i),
					.wb_we_i		(wb_we_i),
					.wb_sel_i		(wb_sel_i),
					.wb_stb_i		(wb_stb_i & (wb_adr_i[WB_ADR_WIDTH-1:2] == (i + (`IRC_ADR_FACTOR_BASE >> 2)))),
					.wb_ack_o		()
				);
		
		if ( i == (FACTOR_NUM - 1) ) begin
			assign factor_wb_dat_o[WB_DAT_WIDTH*(i+1)-1:WB_DAT_WIDTH*i] = f_wb_dat_o;
		end
		else begin
			assign factor_wb_dat_o[WB_DAT_WIDTH*(i+1)-1:WB_DAT_WIDTH*i] = f_wb_dat_o | factor_wb_dat_o[WB_DAT_WIDTH*(i+2)-1:WB_DAT_WIDTH*(i+1)];
		end
	end
	endgenerate
	
	

	// -----------------------------
	//  register access
	// -----------------------------
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_enable <= 1'b0;
			reg_mask   <= {PRIORITY_WIDTH{1'b1}};
		end
		else begin
			// enable
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `IRC_ADR_ENABLE) ) begin
				reg_enable <= wb_dat_i;
			end
			
			// mask
			if ( wb_stb_i & wb_we_i & (wb_adr_i == `IRC_ADR_MASK) ) begin
				reg_mask <= wb_dat_i;
			end
		end
	end
	
	reg		[WB_DAT_WIDTH-1:0]		wb_dat_o;
	always @ * begin
		case ( wb_adr_i )
		`IRC_ADR_ENABLE:		wb_dat_o <= reg_enable;
		`IRC_ADR_MASK:			wb_dat_o <= reg_mask;
		`IRC_ADR_REQ_FACTOR_ID:	wb_dat_o <= reg_req_factor_id;
		`IRC_ADR_REQ_PRIORITY:	wb_dat_o <= reg_req_priority;
		`IRC_ADR_FACTOR_NUM:	wb_dat_o <= FACTOR_NUM;
		`IRC_ADR_PRIORITY_MAX:	wb_dat_o <= (1 << PRIORITY_WIDTH) - 1;
		default:				wb_dat_o <= factor_wb_dat_o[WB_DAT_WIDTH-1:0];
		endcase
	end
	
	assign wb_ack_o = 1'b1;
	
endmodule



