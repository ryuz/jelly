// ---------------------------------------------------------------------------
//  Jelly
//
//                                 Copyright (C) 2009 by Ryuji Fuchikami 
//                                 http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_jbus_logger
		#(
			parameter	ADDR_WIDTH = 12,
			parameter	DATA_SIZE  = 2,		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	DATA_WIDTH = (8 << DATA_SIZE),
			parameter	SEL_WIDTH  = (DATA_WIDTH / 8),
			parameter	FILE_NAME  = "",
			parameter	DISPLAY    = 1,
			parameter	MESSAGE    = "[jbus trace]"
		)
		(
			// system
			input	wire						clk,
			input	wire						reset,
			
			// slave port
			input	wire						jbus_en,
			input	wire	[ADDR_WIDTH-1:0]	jbus_addr,
			input	wire	[DATA_WIDTH-1:0]	jbus_wdata,
			input	wire	[DATA_WIDTH-1:0]	jbus_rdata,
			input	wire						jbus_we,
			input	wire	[SEL_WIDTH-1:0]		jbus_sel,
			input	wire						jbus_valid,
			input	wire						jbus_ready
		);
	
	reg							read_busy;
	reg		[ADDR_WIDTH-1:0]	read_addr;
	reg		[SEL_WIDTH-1:0]		read_sel;

	integer						file;
	
	initial begin
		read_busy = 1'b0;
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			read_busy <= 1'b0;
			read_addr <= {ADDR_WIDTH{1'bx}};
			read_sel  <= {SEL_WIDTH{1'bx}};
		end
		else begin
			if ( jbus_en & !jbus_we & jbus_valid & jbus_ready ) begin
				read_busy <= 1'b1;
				read_addr <= jbus_addr;
				read_sel  <= jbus_sel;
			end
			else if ( jbus_ready ) begin
				read_busy <= 1'b0;
				read_addr <= {ADDR_WIDTH{1'bx}};
				read_sel  <= {SEL_WIDTH{1'bx}};
			end
			
			if ( read_busy & jbus_ready ) begin
				if ( DISPLAY ) begin
					$display("r %h %h %h %d %s", read_addr, jbus_rdata, read_sel, $time, MESSAGE);
				end
				if ( FILE_NAME != "" ) begin
					file = $fopen(FILE_NAME);
					$fdisplay(file, "r %h %h %h %d %s", read_addr, jbus_rdata, read_sel, $time, MESSAGE);
					$fclose(file);
				end
			end
			
			if ( jbus_en & jbus_we & jbus_valid & jbus_ready ) begin
				if ( DISPLAY ) begin
					$display("w %h %h %h %d %s", jbus_addr, jbus_wdata, jbus_sel, $time, MESSAGE);
				end
				if ( FILE_NAME != "" ) begin
					file = $fopen(FILE_NAME);
					$fdisplay(file, "w %h %h %h %d %s", jbus_addr, jbus_wdata, jbus_sel, $time, MESSAGE);
					$fclose(file);
				end
			end
		end
	end
	
endmodule


// end of file
