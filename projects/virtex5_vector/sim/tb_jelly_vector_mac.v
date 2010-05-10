`timescale 1ns / 1ps


module tb_jelly_vector_mac;
	parameter	RATE       = 5;
	
	
	initial begin
		$dumpfile("tb_jelly_vector_mac.vcd");
		$dumpvars(0, tb_jelly_vector_mac);
	end
	
	// reset
	reg		reset;
	initial begin
		#0			reset = 1'b1;
		#(RATE*10)	reset = 1'b0;
		#(RATE*10000) $finish;
	end
	
	// clock
	reg		clk = 1'b1;
	always #(RATE/2) begin
		clk = ~clk;
	end
	
	jelly_vector_mac
			#(
				.STAGE0_REG		(0),
				.STAGE1_REG		(1),
				.STAGE2_REG		(1),
				.STAGE3_REG		(1),
				.STAGE4_REG		(1),
				.STAGE5_REG		(1),
				.STAGE6_REG		(1),
				.STAGE7_REG		(1),
				.STAGE8_REG		(1)
			)
		i_vector_mac
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(1'b1),
				
				.in_size		(2'b00),
				.in_addsub		(1'b1),
				.in_feedback	(1'b1),
				.in_shift		(0),
				.in_clip		(0),
				.in_src0_sign	(1),
				.in_src1_sign	(1),
				.in_src2_sign	(1),
				.in_dst_sign	(1),
				.in_src0_data	(1),
				.in_src1_data	(1),
				.in_src2_data	(1),
				
				.out_dst_data	()
			);
	

endmodule

