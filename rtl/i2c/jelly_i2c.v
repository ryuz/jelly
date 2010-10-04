// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    I2C
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


`define I2C_STATUS		3'b000
`define I2C_CONTROL		3'b001
`define I2C_SEND		3'b010
`define I2C_RECV		3'b011
`define I2C_DIVIDER		3'b100

`define CONTROL_START	0
`define CONTROL_STOP	1
`define CONTROL_ACK		2
`define CONTROL_NAK		3
`define CONTROL_RECV	4


// I2C
module jelly_i2c
		#(
			parameter							DIVIDER_WIDTH = 16,
			parameter							DIVIDER_INIT  = 2000,
			
			parameter							WB_ADR_WIDTH  = 3,
			parameter							WB_DAT_WIDTH  = 32,
			parameter							WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// I2C
			output	wire						i2c_scl_t,
			input	wire						i2c_scl_i,
			output	wire						i2c_sda_t,
			input	wire						i2c_sda_i,
			
			// WISHBONE
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	wire						wb_ack_o,
			
			output	wire						irq
		);
	
	
	// -------------------------
	//   Core
	// -------------------------
			
	reg		[DIVIDER_WIDTH-1:0]	clk_dvider;
	wire						cmd_start;
	wire						cmd_stop;
	wire						cmd_ack;
	wire						cmd_nak;
	wire						cmd_recv;
	wire						cmd_send;
	wire	[7:0]				recv_data;
	wire	[7:0]				send_data;
	wire						ack_status;
	wire						busy;
	
	jelly_i2c_core
			#(
				.DIVIDER_WIDTH		(DIVIDER_WIDTH)
			)
		i_i2c_core
			(
				.reset				(reset),
				.clk				(clk),
				
				.clk_dvider			(clk_dvider),
				
				.i2c_scl_t			(i2c_scl_t),
				.i2c_scl_i			(i2c_scl_i),
				.i2c_sda_t			(i2c_sda_t),
				.i2c_sda_i			(i2c_sda_i),
				
				.cmd_start			(cmd_start),
				.cmd_stop			(cmd_stop),
				.cmd_ack			(cmd_ack),
				.cmd_nak			(cmd_nak),
				.cmd_recv			(cmd_recv),
				.cmd_send			(cmd_send),
				.recv_data			(recv_data),
				.send_data			(send_data),
				.ack_status			(ack_status),
				
				.busy				(busy)
			);
	
	// -------------------------
	//  register
	// -------------------------

	always @(posedge clk) begin
		if ( reset ) begin
			clk_dvider <= DIVIDER_INIT;
		end
		else begin
			if ( (wb_adr_i == `I2C_DIVIDER) & wb_stb_i & wb_we_i ) begin
				clk_dvider <= wb_dat_i;
			end
		end
	end
	
	assign cmd_start = (wb_adr_i == `I2C_CONTROL) & wb_stb_i & wb_we_i & wb_sel_i[0] & wb_dat_i[`CONTROL_START];
	assign cmd_stop  = (wb_adr_i == `I2C_CONTROL) & wb_stb_i & wb_we_i & wb_sel_i[0] & wb_dat_i[`CONTROL_STOP];
	assign cmd_ack   = (wb_adr_i == `I2C_CONTROL) & wb_stb_i & wb_we_i & wb_sel_i[0] & wb_dat_i[`CONTROL_ACK]; 
	assign cmd_nak   = (wb_adr_i == `I2C_CONTROL) & wb_stb_i & wb_we_i & wb_sel_i[0] & wb_dat_i[`CONTROL_NAK];
	assign cmd_recv  = (wb_adr_i == `I2C_CONTROL) & wb_stb_i & wb_we_i & wb_sel_i[0] & wb_dat_i[`CONTROL_RECV];
	assign cmd_send  = (wb_adr_i == `I2C_SEND)    & wb_stb_i & wb_we_i & wb_sel_i[0];
	assign send_data = wb_dat_i[7:0];
	
	assign wb_dat_o  = (wb_adr_i == `I2C_STATUS)  ? {i2c_scl_i, i2c_sda_i, i2c_scl_t, i2c_sda_t, ack_status, 2'b00, busy} :
					   (wb_adr_i == `I2C_RECV)    ? recv_data  :
					   (wb_adr_i == `I2C_DIVIDER) ? clk_dvider : 0;
	
	assign wb_ack_o  = wb_stb_i;
	
	assign irq       = ~busy;
	
endmodule


`default_nettype wire

// end of file
