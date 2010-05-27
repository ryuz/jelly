// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    I2C
//
//                                  Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale       1ns / 1ps
`default_nettype none


// uart
module jelly_i2c_core
		#(
			parameter							DIVIDER_WIDTH = 16
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			input	wire	[DIVIDER_WIDTH-1:0]	clk_dvider,
			
			output	wire						i2c_scl_t,
			input	wire						i2c_scl_i,
			output	wire						i2c_sda_t,
			input	wire						i2c_sda_i,
			
			input	wire						cmd_start,
			input	wire						cmd_stop,
			input	wire						cmd_send,
			input	wire						cmd_recv,
			
			input	wire	[7:0]				send_data,
			output	wire	[7:0]				recv_data,
			
			output	wire						busy
		);
	
	
	// state
	localparam	[1:0]	ST_START = 2'b00, ST_STOP = 2'b01, ST_SEND = 2'b10, ST_RECV = 2'b11;
	
	reg								reg_busy;
	reg		[1:0]					reg_state;
	reg		[5:0]					reg_counter;
	
	// output register
	reg								reg_sda_t;
	reg								reg_scl_t;
	
	// input double latch
	reg								reg_scl0_i;
	reg								reg_sda0_i;
	reg								reg_scl_i;
	reg								reg_sda_i;

	// clock dvider
	reg		[DIVIDER_WIDTH-1:0]		reg_clk_counter;
	reg								reg_clk_triger;
		
	
	// input double latch
	always @ (posedge clk) begin
		if ( reset ) begin
			reg_scl0_i <= 1'b1;
			reg_sda0_i <= 1'b1;
			reg_scl_i  <= 1'b1;
			reg_sda_i  <= 1'b1;
		end
		else begin
			reg_scl0_i <= i2c_scl_i;
			reg_sda0_i <= i2c_sda_i;
			reg_scl_i  <= reg_scl0_i;
			reg_sda_i  <= reg_sda0_i;
		end
	end
	
	// clock dvider
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_clk_counter <= 0;
			reg_clk_triger  <= 1'b0;
		end
		else begin
			if ( reg_busy ) begin
				if ( !(reg_scl_t == 1'b1 && reg_scl_i == 1'b0) ) begin
					if ( reg_clk_counter == 0 ) begin
						reg_clk_counter <= clk_dvider;
						reg_clk_triger  <= 1'b1;
					end
					else begin
						reg_clk_counter <= reg_clk_counter - 1'b1;
						reg_clk_triger  <= 1'b0;						
					end
				end
				else begin
					reg_clk_triger  <= 1'b0;
				end
			end
			else begin
				// idle
				reg_clk_counter <= clk_dvider;
				reg_clk_triger  <= 1'b0;
			end
		end
	end
	
	
	// state machine
	reg		[7:0]	reg_send_data;
	reg		[7:0]	reg_recv_data;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_busy      <= 1'b0;
			reg_state     <= 2'bxx;
			reg_counter   <= 0;
			reg_send_data <= 8'hxx;
			reg_recv_data <= 8'hxx;
		end
		else begin
			if ( !reg_busy ) begin
				if ( cmd_start | cmd_stop | cmd_send | cmd_recv ) begin
					reg_busy    <= 1'b1;
					reg_state   <= cmd_stop ? ST_STOP : cmd_start ? ST_START : cmd_recv ? ST_RECV : ST_SEND;
				end
				reg_send_data <= send_data;
				reg_counter   <= 0;
			end
			else begin
				if ( reg_clk_triger ) begin
					reg_counter <= reg_counter + 1'b1;
					case ( reg_state )
					ST_START:	if (reg_counter[1:0] >= 2)  reg_busy <= 1'b0;
					ST_STOP:	if (reg_counter[1:0] >= 2)  reg_busy <= 1'b0;
					ST_SEND:	if (reg_counter >= 35) reg_busy <= 1'b0;
					ST_RECV:	if (reg_counter >= 35) reg_busy <= 1'b0;
					endcase
					
					if ( reg_counter[1:0] == 2'b11 ) begin
						reg_send_data[7:0] <= {reg_send_data[6:0], 1'b1};
					end
					if ( reg_counter[1:0] == 2'b01 && !reg_counter[5] ) begin
						reg_recv_data <= {reg_recv_data[6:0], reg_sda_i};
					end
				end
			end
		end
	end
	
	// output
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_scl_t     <= 1'b1;
			reg_sda_t     <= 1'b1;
		end
		else begin
			if ( reg_busy ) begin
				case ( reg_state )
				ST_START:
					case ( reg_counter[1:0] )
					2'b00: begin reg_scl_t <= 1'b1;  reg_sda_t <= 1'b1; end
					2'b01: begin reg_scl_t <= 1'b1;  reg_sda_t <= 1'b0; end
					2'b10: begin reg_scl_t <= 1'b0;  reg_sda_t <= 1'b0; end
					endcase
				
				ST_STOP:
					case ( reg_counter[1:0] )
					2'b00: begin reg_scl_t <= 1'b0;  reg_sda_t <= 1'b0; end
					2'b01: begin reg_scl_t <= 1'b1;  reg_sda_t <= 1'b0; end
					2'b10: begin reg_scl_t <= 1'b1;  reg_sda_t <= 1'b1; end
					endcase

				ST_SEND:
					case ( reg_counter[1:0] )
					2'b00: begin reg_scl_t <= 1'b0; reg_sda_t <= reg_send_data[7]; end
					2'b01: begin reg_scl_t <= 1'b1; end
					2'b10: begin reg_scl_t <= 1'b1; end
					2'b11: begin reg_scl_t <= 1'b0; end
					endcase
				
				ST_RECV:
					case ( reg_counter[1:0] )
					2'b00: begin reg_scl_t <= 1'b0; reg_sda_t <= ~reg_counter[5]; end
					2'b01: begin reg_scl_t <= 1'b1; reg_sda_t <= ~reg_counter[5]; end
					2'b10: begin reg_scl_t <= 1'b1; reg_sda_t <= ~reg_counter[5]; end
					2'b11: begin reg_scl_t <= 1'b0; reg_sda_t <= ~reg_counter[5]; end
					endcase
				endcase
			end
		end
	end
	
	assign i2c_scl_t = reg_scl_t;
	assign i2c_sda_t = reg_sda_t;
	assign recv_data = reg_recv_data;
	assign busy      = reg_busy;
	
endmodule


`default_nettype wire


// end of file

