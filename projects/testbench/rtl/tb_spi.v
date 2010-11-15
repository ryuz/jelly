`timescale 1ns / 1ps


module tb_spi;
	parameter	RATE = 20;
	
	initial begin
		$dumpfile("tb_spi.vcd");
		$dumpvars(0, tb_spi);
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
	
	wire			spi_cs_n;
	wire			spi_clk;
	wire			spi_di;
	reg				spi_do = 0;
	
	reg		[2:0]	wb_adr_i = 0;
	wire	[31:0]	wb_dat_o;
	reg		[31:0]	wb_dat_i = 0;
	reg				wb_we_i  = 1'b0;
	reg		[3:0]	wb_sel_i = 4'b1111;
	reg				wb_stb_i = 1'b0;
	wire			wb_ack_o;
	
	jelly_spi
			#(
				.DIVIDER_INIT	(100)
			)
		i_spi
			(
				.reset			(reset),
				.clk			(clk),
				
				.spi_cs_n		(spi_cs_n),
				.spi_clk		(spi_clk),
				.spi_di			(spi_di),
				.spi_do			(spi_do),
				
				.wb_adr_i		(wb_adr_i),
				.wb_dat_o		(wb_dat_o),
				.wb_dat_i		(wb_dat_i),
				.wb_we_i		(wb_we_i),
				.wb_sel_i		(wb_sel_i),
				.wb_stb_i		(wb_stb_i),
				.wb_ack_o		(wb_ack_o)
			);
	
	always @( negedge spi_clk) begin
		spi_do <= {$random};
	end
	
	
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
		
			// write
			wb_adr_i = 2; 
			wb_dat_i = 8'h55;
			wb_we_i  = 1; 
			wb_stb_i = 1; 
		@(negedge clk);
			wb_stb_i = 0; 
			wait_busy();
		
			// write
			wb_adr_i = 2; 
			wb_dat_i = 8'haa;
			wb_we_i  = 1; 
			wb_stb_i = 1; 
		@(negedge clk);
			wb_stb_i = 0; 
			wait_busy();
		
	end

	
	initial begin
		#(RATE*20000)
			$display("time out");
			$finish;
	end
	
endmodule

