`timescale 1ns / 1ps


module tb_fifo_async_fwtf;
	parameter	WR_RATE = 20;
	parameter	RD_RATE = 19;
	
	initial begin
		$dumpfile("tb_fifo_async_fwtf.vcd");
		$dumpvars(0, tb_fifo_async_fwtf);
	end
	
	
	// clock
	reg		wr_clk = 1'b1;
	always #(WR_RATE/2) wr_clk = ~wr_clk;

	reg		rd_clk = 1'b1;
	always #(RD_RATE/2) rd_clk = ~rd_clk;
	
	
	// reset
	reg		reset;
	initial begin
		#0				reset = 1'b1;
		#(WR_RATE*10)	reset = 1'b0;
		#(WR_RATE*1000)	$finish;
	end

	parameter	DATA_WIDTH = 8;
	parameter	PTR_WIDTH  = 4;

	reg							wr_rand;
	wire						wr_valid;
	reg		[DATA_WIDTH-1:0]	wr_data;
	wire						wr_ready;
	wire	[PTR_WIDTH:0]		wr_free_num;
	
	reg							rd_rand;
	wire						rd_valid;
	wire	[DATA_WIDTH-1:0]	rd_data;
	wire						rd_ready;
	wire	[PTR_WIDTH:0]		rd_data_num;
	reg		[DATA_WIDTH-1:0]	rd_data_exp;
	
	always @(posedge wr_clk) begin
		if ( reset ) begin
			wr_rand <= 1'b0;
			wr_data <= 0;
		end
		else begin
			wr_rand <= {$random};
			if ( wr_valid & wr_ready ) begin
				wr_data <= wr_data + 1;
			end
		end
	end
	assign wr_valid = wr_rand & (wr_data < 256);
	
	always @(posedge rd_clk) begin
		if ( reset ) begin
			rd_rand     <= 1'b0;
			rd_data_exp <= 0;
		end
		else begin
			rd_rand <= {$random};
			if ( rd_valid & rd_ready ) begin
				if ( rd_data != rd_data_exp ) begin
					$display("NG : %h", rd_data);
				end
				else begin
					$display("OK : %h", rd_data);
				end
				
				rd_data_exp <= rd_data_exp + 1;
			end
		end
	end
	assign rd_ready = rd_rand;
	
	
	jelly_fifo_async_fwtf
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.PTR_WIDTH		(PTR_WIDTH)
			)
		i_fifo_async_fwtf
			(
				.wr_reset		(reset),
				.wr_clk			(wr_clk),
				.wr_data		(wr_data),
				.wr_valid		(wr_valid),
				.wr_ready		(wr_ready),
				.wr_free_num	(wr_free_num),
				                 
				.rd_reset		(reset),
				.rd_clk			(rd_clk),
				.rd_data		(rd_data),
				.rd_valid		(rd_valid),
				.rd_ready		(rd_ready),
				.rd_data_num	(rd_data_num)
			);
	
	
endmodule

