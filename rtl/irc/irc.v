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
			in_interrupt,
			cpu_irq, cpu_irq_ack,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	FACTOR_ID_WIDTH  = 2;
	parameter	FACTOR_NUM       = (1 << FACTOR_ID_WIDTH);
	parameter	PRIORITY_WIDTH   = 3;
	
	parameter	WB_ADR_WIDTH   = 8;
	parameter	WB_DAT_WIDTH   = 32;
	localparam	WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8);
	
	
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
	reg								req_irq;
	reg		[PRIORITY_WIDTH-1:0]	reg_mask;
	reg		[PRIORITY_WIDTH-1:0]	reg_id;
	
		
	// request recive
	wire	[FACTOR_NUM-1:0]		factor_request_send;
	wire							request_recv;
	assign request_recv = (factor_request_send == {FACTOR_NUM{1'b1}});
	
	localparam	PACKET_WIDTH = (PRIORITY_WIDTH + FACTOR_ID_WIDTH);
	reg								recv_st_busy;
	reg		[PACKET_WIDTH-1:0]		recv_packet;
	reg		[PACKET_WIDTH:0]		recv_counter;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			req_irq      <= 1'b0;
			recv_st_busy <= 1'b0;
			recv_counter <= {PACKET_WIDTH{1'b0}};
		end
		else begin
			if ( !recv_st_busy ) begin
				if ( request_recv == 1'b0 ) begin
					recv_st_busy    <= 1'b1;
					recv_counter[0] <= 1'b1;
				end
			end
			else begin
				recv_counter <= (recv_counter << 1);
				if ( recv_counter[PACKET_WIDTH] ) begin
					recv_st_busy       <= 1'b0;
				end
				else begin
					recv_packet <= {recv_packet, request_recv};
				end
			end
			
			if ( !recv_st_busy & (request_recv == 1'b0) ) begin
				req_irq <= 1'b1;
			end
			else if ( cpu_irq_ack ) begin
				req_irq <= 1'b0;
			end
		end
	end
	
	assign cpu_irq = req_irq;
	
	
	// register access
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_id   <= {FACTOR_ID_WIDTH{1'b0}};
			reg_mask <= {PRIORITY_WIDTH{1'b1}};
		end
		else begin
		
			if ( recv_counter[PACKET_WIDTH] ) begin
				{reg_mask, reg_id} <= recv_packet;
			end
			else begin
				// mask
				if ( wb_stb_i & wb_we_i & (wb_adr_i == 1) ) begin
					reg_mask <= wb_dat_i;
				end
			end
		end
	end
	
	
	
	wire	[(WB_DAT_WIDTH*FACTOR_NUM)-1:0]		factor_wb_dat_o;
	
	generate
	genvar	i;
	for ( i = FACTOR_NUM - 1; i >= 0; i = i - 1 ) begin : factor
		wire	[WB_DAT_WIDTH-1:0]		tmp_wb_dat_o;
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

					.factor_id		(i),
					
					.in_interrupt	(in_interrupt[i]),
					.mask			(reg_mask),
					
					.reqest_send	(factor_request_send[i]),
					.reqest_sense	(request_recv),
					.reqest_busy	(recv_st_busy),
					
					.wb_adr_i		(wb_adr_i[1:0]),
					.wb_dat_o		(tmp_wb_dat_o),
					.wb_dat_i		(wb_dat_i),
					.wb_we_i		(wb_we_i),
					.wb_sel_i		(wb_sel_i),
					.wb_stb_i		(wb_stb_i & (wb_adr_i[WB_ADR_WIDTH-1:2] == (i+1))),
					.wb_ack_o		()
				);
				
		if ( i == (FACTOR_NUM - 1) ) begin
			assign factor_wb_dat_o[WB_DAT_WIDTH*(i+1)-1:WB_DAT_WIDTH*i] = tmp_wb_dat_o;
		end
		else begin
			assign factor_wb_dat_o[WB_DAT_WIDTH*(i+1)-1:WB_DAT_WIDTH*i] = tmp_wb_dat_o | factor_wb_dat_o[WB_DAT_WIDTH*(i+2)-1:WB_DAT_WIDTH*(i+1)];
		end
	end
	endgenerate
	
	
	reg		[WB_DAT_WIDTH-1:0]		wb_dat_o;
	always @ * begin
		case ( wb_adr_i )
		0:			wb_dat_o <= FACTOR_NUM;
		1:			wb_dat_o <= reg_id;
		2:			wb_dat_o <= reg_mask;
		default:	wb_dat_o <= factor_wb_dat_o[WB_DAT_WIDTH-1:0];
		endcase
	end
	
	assign wb_ack_o = 1'b1;
	
endmodule



