// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale       1ns / 1ps
`default_nettype none


// nop         8'h00
// nop               8'h80
//
// status      8'h01
// status_ack        8'h81 status
//
// read        8'h03       adr0 adr1 adr2 adr3 size  
// read_ack          8'ha0                          dat0 dat1 dat2 dat3 ....
//
// write       8'h02       adr0 adr1 adr2 adr3 size dat0 dat1 dat2 dat3 ....
// write_ack         8'h82                                                   8'hc2


`define COMM_CMD_NOP			8'h00
`define COMM_CMD_STATUS			8'h01
`define COMM_CMD_READ		    8'h02
`define COMM_CMD_WRITE	        8'h03

`define COMM_ACK_NOP			8'h80
`define COMM_ACK_STATUS			8'h81
`define COMM_ACK_READ			8'h82
`define COMM_ACK_WRITE			8'h82
`define COMM_ACK_WRITE_END		8'hc2


// debug comm
module jelly_comm_to_wishbone
		#(
			parameter	ADR_WIDTH = 32,
			parameter	DAT_SIZE  = 2,					// log2 (0:8bit, 1:16nit, 2:32bit, ...)
			parameter	DAT_WIDTH = (8 << DAT_SIZE),
			parameter	SEL_WIDTH = (8 << DAT_SIZE)
		)
		(
			// system
			input	wire							reset,
			input	wire							clk,
			input	wire							endian,
			
			// comm port
			output	wire	[7:0]					comm_tx_data,
			output	wire							comm_tx_valid,
			input	wire							comm_tx_ready,
			input	wire	[7:0]					comm_rx_data,
			input	wire							comm_rx_valid,
			output	wire							comm_rx_ready,
			
			// debug port (whishbone)
			output	wire	[ADR_WIDTH-1:DAT_SIZE]	wb_adr_o,
			input	wire	[DAT_WIDTH-1:0]			wb_dat_i,
			output	wire	[DAT_WIDTH-1:0]			wb_dat_o,
			output	wire							wb_we_o,
			output	wire	[SEL_WIDTH:0]			wb_sel_o,
			output	wire							wb_stb_o,
			input	wire							wb_ack_i
		);
	
	localparam	ADR_BYTES = ((ADR_WIDTH + 3) >> 2);
	
	// status
	wire	[7:0]	status_data;
	assign status_data[3:0] = ADR_BYTES;
	assign status_data[5:4] = DAT_SIZE;
	assign status_data[7]   = endian;
	
	
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
	
	reg		[7:0]		reg_cmd,      next_cmd;
	reg		[7:0]		reg_size,     next_size;
	reg		[1:0]		reg_count,    next_count;
	
	reg					reg_tx_valid, next_tx_valid;
	reg		[7:0]		reg_tx_data,  next_tx_data;
	
	reg					reg_rx_ready, next_rx_ready;
	
	reg		[31:0]		reg_wb_adr_o, next_wb_adr_o;
	reg		[31:0]		reg_wb_dat_o, next_wb_dat_o;
	reg		[31:0]		reg_wb_dat_i, next_wb_dat_i;
	reg					reg_wb_we_o,  next_wb_we_o;
	reg		[3:0]		reg_wb_sel_o, next_wb_sel_o;
	reg					reg_wb_stb_o, next_wb_stb_o;
	
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_state    <= ST_IDLE;
			reg_cmd      <= {8{1'bx}};
			reg_size     <= {8{1'bx}};
			reg_count    <= {2{1'bx}};
			
			reg_tx_valid <= 1'b0;
			reg_tx_data  <= {8{1'bx}};
			
			reg_wb_adr_o <= {30{1'bx}};
			reg_wb_dat_o <= {32{1'bx}};
			reg_wb_dat_i <= {32{1'bx}};
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
			reg_wb_dat_i <= next_wb_dat_i;
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
		
		// wishbone access end
		if ( wb_ack_i ) begin
			next_wb_stb_o = 1'b0;
			next_wb_sel_o = 4'b0000; 
			next_wb_dat_i = wb_dat_i;
		end
		
		// fifo tx access end
		if ( comm_tx_ready ) begin
			next_tx_valid = 1'b0;
		end
		
		case ( reg_state )
			ST_IDLE:
				begin
					next_cmd     = comm_rx_data;
					next_tx_data = (next_cmd | 8'h80);
					if ( comm_rx_valid ) begin
						next_state    = ST_ACK;
						next_tx_valid = 1'b1;
					end
				end
				
			ST_ACK:
				begin
					next_count = 0;
					if ( comm_tx_ready ) begin
						case ( reg_cmd )
						`COMM_CMD_NOP:		begin next_state = ST_IDLE;   next_tx_valid = 1'b0;        end
						`COMM_CMD_STATUS:	begin next_state = ST_STATUS; next_tx_data  = status_data; end
						`COMM_CMD_WRITE:	begin next_state = ST_ADR;    next_tx_valid = 1'b0;        end
						`COMM_CMD_READ:		begin next_state = ST_ADR;    next_tx_valid = 1'b0;        end
						default:			begin next_state = ST_IDLE;   next_tx_valid = 1'b0;        end
						endcase
					end
				end
				
			ST_STATUS:
				begin
					if ( comm_tx_ready ) begin
						reg_state    = ST_IDLE;
						reg_tx_valid = 1'b0;
					end
				end
								
			ST_ADR:
				begin
					if ( comm_rx_valid ) begin
						case ( reg_count ^ {2{endian}} )
						2'b00: reg_wb_adr_o[7:0]   <= comm_rx_data;
						2'b01: reg_wb_adr_o[15:8]  <= comm_rx_data;
						2'b10: reg_wb_adr_o[23:16] <= comm_rx_data;
						2'b11: reg_wb_adr_o[31:24] <= comm_rx_data;
						endcase
						if ( reg_count == 2'b11 ) begin
							next_state = ST_ADR;
						end
						next_count <= reg_count + 1;
					end
				end
				
			ST_SIZE:
				begin
					if ( comm_rx_valid ) begin
						reg_size  = comm_rx_data;
						if ( reg_cmd[0] ) begin
							next_state         = ST_WRITE;
							next_comm_rx_ready = 1'b1;
						end
						else begin
							next_state         = ST_READ;
						end
					end
				end
				
			ST_WRITE:
				begin
					if ( wb_stb_o & wb_ack_i & !reg_comm_rx_ready ) begin
						next_tx_valid = 1'b1;
						next_tx_data  = `COMM_ACK_WRITE_END;
						next_state    = ST_WRITE_END;
					end
					if ( comm_rx_valid & comm_rx_ready ) begin
						case ( reg_wb_adr_o[1:0] ^ {2{endian}} )
						2'b00: begin next_wb_dat_o[7:0]   <= comm_rx_data; next_wb_sel_o[0] <= 1'b1; end
						2'b01: begin next_wb_dat_o[15:8]  <= comm_rx_data; next_wb_sel_o[1] <= 1'b1; end
						2'b10: begin next_wb_dat_o[23:16] <= comm_rx_data; next_wb_sel_o[2] <= 1'b1; end
						2'b11: begin next_wb_dat_o[31:24] <= comm_rx_data; next_wb_sel_o[3] <= 1'b1; end
						endcase
						next_wb_adr_o = next_wb_adr_o + 1;
						next_size     = next_size - 1;
						if ( reg_wb_adr_o[1:0] == 2'b11 ) begin
							next_wb_stb_o = 1'b1;
							next_size     = reg_size - 1;
							if ( next_size == 0 ) begin
								next_comm_rx_ready = 1'b0;
							end
						end
					end
				end
				
			ST_WRITE_END:
				begin
					if ( comm_tx_ready ) begin
						next_tx_valid = 1'b0;
						next_state    = ST_WRITE_END;
					end
				end
				
			ST_READ:
				begin
					if ( !reg_wb_stb_o ) begin
						if ( n
						next_tx_data = 
					
					if ( comm_tx_ready ) begin
						next_tx_valid = 1'b0;
						next_state    = ST_WRITE_END;
					end					
				end
			endcase
		end
	end
	
	
	assign comm_rx_ready = reg_rx_ready & !(wb_stb_o & !wb_ack_i);
	
endmodule



`default_nettype wire



// end of file
