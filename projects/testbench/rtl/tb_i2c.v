`timescale 1ns / 1ps


module tb_i2c;
	parameter	RATE = 20;
	
	initial begin
		$dumpfile("tb_i2c.vcd");
		$dumpvars(0, tb_i2c);
	end
	
	
	// clock
	reg		clk;
	initial begin
		clk    = 1'b1;
	end
	always #(RATE/2) begin
		clk = ~clk;
	end
	
	// reset
	reg		reset;
	initial begin
		#0			reset = 1'b1;
		#(RATE*10)	reset = 1'b0;
	end
		
	wire			i2c_scl_t;
	wire			i2c_scl_i;
	wire			i2c_sda_t;
	wire			i2c_sda_i;
	
	reg		[2:0]	wb_adr_i = 0;
	wire	[31:0]	wb_dat_o;
	reg		[31:0]	wb_dat_i = 0;
	reg				wb_we_i  = 1'b0;
	reg		[3:0]	wb_sel_i = 4'b1111;
	reg				wb_stb_i = 1'b0;
	wire			wb_ack_o;
	
	jelly_i2c
			#(
				.DIVIDER_INIT	(100)
			)
		i_i2c
			(
				.reset			(reset),
				.clk			(clk),
				
				.i2c_scl_t		(i2c_scl_t),
				.i2c_scl_i		(i2c_scl_i),
				.i2c_sda_t		(i2c_sda_t),
				.i2c_sda_i		(i2c_sda_i),
				
				.wb_adr_i		(wb_adr_i),
				.wb_dat_o		(wb_dat_o),
				.wb_dat_i		(wb_dat_i),
				.wb_we_i		(wb_we_i),
				.wb_sel_i		(wb_sel_i),
				.wb_stb_i		(wb_stb_i),
				.wb_ack_o		(wb_ack_o)
			);
	
	wire	#10		i2c_scl;
	wire	#10		i2c_sda;
	
	pullup(i2c_scl);
	pullup(i2c_sda);
	
	assign i2c_scl   = i2c_scl_t ? 1'bz : 1'b0;
	assign i2c_sda   = i2c_sda_t ? 1'bz : 1'b0;
	assign i2c_scl_i = i2c_scl;
	assign i2c_sda_i = i2c_sda;
	
	task wait_busy;
	begin
		wb_adr_i = 0;
		wb_we_i  = 0;
		wb_stb_i = 1;
		@(negedge clk);
		while ( (wb_dat_o & 1) ) begin
			@(negedge clk);
		end
		wb_stb_i = 0;
	end
	endtask
	
	initial begin
		#1;
		@(negedge reset);
		@(negedge clk);
		@(negedge clk);
		@(negedge clk);
			// start
			wb_adr_i = 1; 
			wb_dat_i = 1; 
			wb_we_i  = 1; 
			wb_stb_i = 1; 
		@(negedge clk);
			wb_stb_i = 0; 
			wait_busy();
		
			// write
		@(negedge clk);
			wb_adr_i = 2; 
			wb_dat_i = 8'h9a; 
			wb_we_i  = 1; 
			wb_stb_i = 1; 
		@(negedge clk);
			wb_stb_i = 0;
		#(RATE*200);
			force i2c_scl = 1'b0;
		#(RATE*200);
			release i2c_scl;
			
			wait_busy();

			// read
		@(negedge clk);
			wb_adr_i = 1; 
			wb_dat_i = 4; 
			wb_we_i  = 1; 
			wb_stb_i = 1; 
		@(negedge clk);
			wb_stb_i = 0; 
		
		wait_busy();

		@(negedge clk);
			wb_adr_i = 1; 
			wb_dat_i = 2; 
			wb_we_i  = 1; 
			wb_stb_i = 1; 
		@(negedge clk);
			wb_stb_i = 0; 
		
	end

	
	initial begin
		#(RATE*20000)
			$display("time out");
			$finish;
	end
	
endmodule

