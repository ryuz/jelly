// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale       1ns / 1ps
`default_nettype none


// nop         {4'h0, 4'hx}
// nop                      8'h80
//
// status      {4'h1, 4'hx}
// status_ack               8'h90 status
//
// read        {4'h3, sel}        size adr0 adr1 adr2 adr3  
// write_ack                8'ha0                          dat0 dat1 dat2 dat3 ....
//
// write       {4'h2, sel}        size adr0 adr1 adr2 adr3 dat0 dat1 dat2 dat3 ....
// write_ack                8'hb0                                                   8'hb1


`define COMM_CMD_NOP			4'h0
`define COMM_CMD_STATUS			4'h1
`define COMM_CMD_READ		    4'h2
`define COMM_CMD_WRITE	        4'h3

`define COMM_ACK_NOP			8'h80
`define COMM_ACK_STATUS			8'h90
`define COMM_ACK_READ			8'ha0
`define COMM_ACK_WRITE			8'hb0
`define COMM_ACK_WRITE_END		8'hb1


// debug comm
module jelly_comm_to_wishbone
		(
			// system
			input	wire				reset,
			input	wire				clk,
			input	wire				endian,
			
			// comm port
			output	wire	[7:0]		comm_tx_data,
			output	wire				comm_tx_valid,
			input	wire				comm_tx_ready,
			input	wire	[7:0]		comm_rx_data,
			input	wire				comm_rx_valid,
			output	wire				comm_rx_ready,
			
			// debug port (whishbone)
			output	wire	[31:2]		wb_adr_o,
			input	wire	[31:0]		wb_dat_i,
			output	wire	[31:0]		wb_dat_o,
			output	wire				wb_we_o,
			output	wire	[3:0]		wb_sel_o,
			output	wire				wb_stb_o,
			input	wire				wb_ack_i
		);
	
	// state
	localparam	ST_IDLE      = 0;
	localparam	ST_ACK       = 1;
	localparam	ST_STATUS    = 2;
	localparam	ST_SIZE      = 3;
	localparam	ST_ADR       = 4;
	localparam	ST_WRITE     = 5;
	localparam	ST_WRITE_END = 6;
	localparam	ST_READ      = 7;
	
	reg		[3:0]		reg_state,    next_state;
	reg		[3:0]		reg_cmd,      next_cmd;
	reg		[7:0]		reg_size,     next_size;
	reg		[1:0]		reg_count,    next_count;
	
	reg					reg_tx_valid, next_tx_valid;
	reg		[7:0]		reg_tx_data,  next_tx_data;
	
	reg		[31:2]		reg_wb_adr_o, next_wb_adr_o;
	reg		[31:0]		reg_wb_dat_o, next_wb_dat_o;
	reg					reg_wb_we_o,  next_wb_we_o;
	reg		[3:0]		reg_wb_sel_o, next_wb_sel_o;
	reg					reg_wb_stb_o, next_wb_stb_o;
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_state    <= ST_IDLE;
			reg_cmd      <= {4{1'bx}};
			reg_size     <= {8{1'bx}};
			reg_count    <= {2{1'bx}};
			
			reg_tx_valid <= 1'b0;
			reg_tx_data  <= {8{1'bx}};
			
			reg_wb_adr_o <= {30{1'bx}};
			reg_wb_dat_o <= {32{1'bx}};
			reg_wb_we_o  <= 1'bx;
			reg_wb_sel_o <= {4{1'bx}};
			reg_wb_stb_o <= 1'b0;
		end
		else begin
			reg_state    <= next_state;
			reg_cmd      <= next_cmd;
			reg_size     <= next_size;
			reg_count    <= next_count;
			                
			reg_tx_valid <= next_tx_valid;
			reg_tx_data  <= next_tx_data;
			                
			reg_wb_adr_o <= next_wb_adr_o;
			reg_wb_dat_o <= next_wb_dat_o;
			reg_wb_we_o  <= next_wb_we_o;
			reg_wb_sel_o <= next_wb_sel_o;
			reg_wb_stb_o <= next_wb_stb_o;
		end
	end
	
	
	always @* begin
		next_state    = reg_state;
		next_cmd      = reg_cmd;
		next_size     = reg_size;
		next_count    = reg_count;
		
		next_tx_valid = reg_tx_valid;
		next_tx_data  = reg_tx_data;
		
		next_wb_adr_o = reg_wb_adr_o;
		next_wb_dat_o = reg_wb_dat_o;
		next_wb_we_o  = reg_wb_we_o;
		next_wb_sel_o = reg_wb_sel_o;
		next_wb_stb_o = reg_wb_stb_o;
		
		if ( wb_ack_i ) begin
			next_wb_stb_o = 1'b0;
		end
		
		case ( reg_state )
			ST_IDLE:
				begin
					next_cmd      = comm_rx_data[7:4];
					next_tx_data  = {1'b1, comm_rx_data[6:4], 4'h0};
					next_wb_sel_o = comm_rx_data[3:0];
					if ( comm_rx_valid ) begin
						next_state    <= ST_ACK;
						next_tx_valid <= 1'b1;
					end
				end
				
			ST_ACK:
				begin
					if ( comm_tx_ready ) begin
						case ( reg_cmd )
						`COMM_CMD_NOP:		begin next_state <= ST_IDLE;   next_tx_valid   <= 1'b0;   end
						`COMM_CMD_STATUS:	begin next_state <= ST_STATUS; next_tx_data    <= endian; end
						`COMM_CMD_WRITE:	begin next_state <= ST_SIZE;   next_tx_valid   <= 1'b0;   end
						`COMM_CMD_READ:		begin next_state <= ST_SIZE;   next_tx_valid   <= 1'b0;   end
						default:			begin next_state <= ST_IDLE;   next_tx_valid   <= 1'b0;   end
						endcase
					end
				end
			
			ST_STATUS:
				begin
					if ( comm_tx_ready ) begin
						reg_state <= ST_IDLE;
						reg_tx_valid <= 1'b0;
					end
				end

			ST_SIZE:
				begin
					if ( comm_rx_valid ) begin
						reg_size  <= comm_rx_data;
						reg_state <= ST_ADR;
					end
					reg_count <= 0;
				end
				
			ST_ADR:
				begin
					if ( comm_rx_valid ) begin
						case ( reg_count ^ {2{endian}} )
						2'b00: reg_wb_adr_o[7:2]   <= comm_rx_data[7:2];
						2'b01: reg_wb_adr_o[15:8]  <= comm_rx_data[7:0];
						2'b10: reg_wb_adr_o[23:16] <= comm_rx_data[7:0];
						2'b11: reg_wb_adr_o[31:24] <= comm_rx_data[7:0];
						endcase
						if ( reg_count == 2'b11 ) begin
							reg_state <= reg_cmd[0] ? ST_WRITE : ST_READ;
						end
						reg_count <= reg_count + 1;
					end
				end
				
			ST_WRITE:
				begin
					if ( comm_rx_valid & comm_rx_ready ) begin
						case ( reg_count ^ {2{endian}} )
						2'b00: reg_wb_dat_o[7:0]   <= comm_rx_data[7:0];
						2'b01: reg_wb_dat_o[15:8]  <= comm_rx_data[7:0];
						2'b10: reg_wb_dat_o[23:16] <= comm_rx_data[7:0];
						2'b11: reg_wb_dat_o[31:24] <= comm_rx_data[7:0];
						endcase
						reg_count <= reg_count + 1;
						if ( reg_count == 2'b11 ) begin
							reg_size <= reg_size - 1;
						end
					end
					if ( wb_
					
				end
			ST_WRITE_END:
			
			ST_READ:
			default:
				begin
				end
				
			endcase
			
			
			if ( state == ST_IDLE ) begin
				reg_cmd      <= comm_rx_data[7:4];
				reg_wb_sel_o <= comm_rx_data[3:0];
			end
			
			
	
endmodule



`default_nettype wire



// end of file
