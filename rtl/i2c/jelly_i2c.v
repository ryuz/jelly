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
module jelly_i2c
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
			
			input	wire						ctl_start,
			input	wire						ctl_end,
			input	wire						ctl_send,
			input	wire						ctl_recv,
			input	wire	[7:0]				send_data,
			output	wire	[7:0]				recv_data,
			
			output	wire						busy,			
		);

	reg		[DIVIDER_WIDTH-1:0]		reg_clk_counter;
	reg								reg_clk_trig;
	reg								reg_scl_t;
	reg								reg_scl_i;
	reg								reg_sda_t;
	reg								reg_sda_i;
	reg		[7:0]					reg_send_data;
	reg		[7:0]					reg_read_data;
	reg		[1:0]					reg_busy;
	reg		[1:0]					reg_state;
	reg		[3:0]					reg_counter;
	
	parameter	[1:0]	ST_START = 2'd0, ST_END = 2'd1, ST_START = 2'd2, ST_START = 2'd3;
	
	always @( posedge clk ) begin
		if ( reset ) begin
			
		end
		else begin
			// input
			reg_scl_i <= 2c_scl_i;
			reg_sda_i <= 2c_sad_i; 
			
			// wait pullup voltage
			if ( !(reg_scl_t == 1'b1 && reg_scl_i == 1'b0) ) begin
				// counter
				reg_clk_trig    <= (reg_clk_counter == 0);
				reg_clk_counter <= (reg_clk_counter == 0) ? clk_dvider : reg_clk_counter - 1;
				
				if ( reg_clk_trig ) begin
					if ( !reg_busy ) begin
						if ( ctl_start ) begin
							reg_busy      <= 1'b1;
							reg_state     <= ST_START;
							reg_send_data <= 8'hxx;
							reg_counter   <= 0;
						end
						else if ( ctl_start ) begin
							reg_busy      <= 1'b1;
							reg_state     <= ST_END;
							reg_send_data <= 8'hxx;
							reg_counter   <= 0;
						end
						else if ( ctl_send ) begin
							reg_busy      <= 1'b1;
							reg_state     <= ST_SEND;
							reg_send_data <= send_data;
							reg_counter   <= 0;
						end
						else if ( ctl_recv ) begin
							reg_busy      <= 1'b1;
							reg_state     <= ST_START;
							reg_send_data <= 8'hxx;
							reg_counter   <= 0;
						end
					end
					else begin
						reg_counter <= reg_counter + 1;
						case ( reg_state )
						ST_START:
							begin
								case ()
							end
						
						ST_END:
						ST_START:
						ST_START:
						endcase
					end
				end
				else begin
				end
			end
		end
	end
	
	
endmodule


`default_nettype wire


// end of file

