// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_axi4s_master_model
        #(
            parameter   AXI4S_DATA_WIDTH = 32,
            parameter   X_NUM            = 640,
            parameter   Y_NUM            = 480,
            parameter   PGM_FILE         = "",
            parameter   PPM_FILE         = "",
            parameter   BUSY_RATE        = 0,
            parameter   RANDOM_SEED      = 0,
            parameter   INTERVAL         = 0
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,
            
            output  wire    [0:0]                   m_axi4s_tuser,
            output  wire                            m_axi4s_tlast,
            output  wire    [AXI4S_DATA_WIDTH-1:0]  m_axi4s_tdata,
            output  wire                            m_axi4s_tvalid,
            input   wire                            m_axi4s_tready
        );
    
    reg     reg_aresetn = 1'b0;
    always @( posedge aclk ) begin
        reg_aresetn <= aresetn;
    end
    
    reg     [31:0]      reg_rand_seed = RANDOM_SEED;
    reg     [31:0]      reg_rand;
    always @( posedge aclk ) begin
        if ( !reg_aresetn ) begin
            reg_rand_seed <= RANDOM_SEED;
            reg_rand      <= 99;
        end
        else begin
            reg_rand      <= {$random(reg_rand_seed)};
        end
    end
    
    integer interval_count = 0;
    
    wire    busy = ((reg_rand % 100) < BUSY_RATE) || (interval_count > 0);
    
    
    reg     [AXI4S_DATA_WIDTH-1:0]      mem     [0:X_NUM*Y_NUM-1];
    integer                             fp;
    integer                             i;
    integer                             w, h, d;
    integer                             p0, p1, p2;
    integer                             tmp0, tmp1;
    
    initial begin
        for ( i = 0; i < X_NUM*Y_NUM; i = i+1 ) begin
            mem[i] = i;
        end
        
        if ( PGM_FILE != "" ) begin
            fp = $fopen(PGM_FILE, "r");
            if ( fp != 0 ) begin
                tmp0 = $fscanf(fp, "P2", tmp1);
                tmp0 = $fscanf(fp, "%d%d", w, h);
                tmp0 = $fscanf(fp, "%d", d);
                
                for ( i = 0; i < X_NUM*Y_NUM; i = i+1 ) begin
                    tmp0 = $fscanf(fp, "%d", p0);
                    mem[i] = p0;
                end
                
                $fclose(fp);
            end
            else begin
                $display("open error : %s", PGM_FILE);
            end
        end
        
        if ( PPM_FILE != "" ) begin
            fp = $fopen(PPM_FILE, "r");
            if ( fp != 0 ) begin
                tmp0 = $fscanf(fp, "P3", tmp1);
                tmp0 = $fscanf(fp, "%d%d", w, h);
                tmp0 = $fscanf(fp, "%d", d);
                
                for ( i = 0; i < X_NUM*Y_NUM; i = i+1 ) begin
                    tmp0 = $fscanf(fp, "%d%d%d", p0, p1, p2);
                    mem[i] = ((p2<<16) | (p1 << 8) | p0);
                end
                
                $fclose(fp);
            end
            else begin
                $display("open error : %s", PPM_FILE);
            end
        end
    end
    
    
    wire        cke = (!m_axi4s_tvalid || m_axi4s_tready) && !busy;
    
    integer     x = 0;
    integer     y = 0;
    always @(posedge aclk) begin
        if ( !reg_aresetn ) begin
            x <= 0;
            y <= 0;
        end
        else if ( cke ) begin
            x <= x + 1;
            if ( x == (X_NUM-1) ) begin
                x <= 0;
                y <= y + 1;
                if ( y == (Y_NUM-1) ) begin
                    y <= 0;
                end
            end
        end
    end
    
    always @(posedge aclk) begin
        if ( !reg_aresetn ) begin
            interval_count <= 0;
        end
        else begin
            if ( interval_count > 0 ) begin
                interval_count <= interval_count - 1;
            end
            else begin
                if ( x == (X_NUM-1) && y == (Y_NUM-1) && m_axi4s_tvalid && m_axi4s_tready ) begin
                    interval_count <= INTERVAL;
                end
            end
        end
    end
    
    
    assign m_axi4s_tuser  = m_axi4s_tvalid ? (x == 0) && (y == 0) : 1'bx;
    assign m_axi4s_tlast  = m_axi4s_tvalid ? (x == X_NUM-1)       : 1'bx;
    assign m_axi4s_tdata  = m_axi4s_tvalid ? mem[y*X_NUM + x]     : {AXI4S_DATA_WIDTH{1'bx}};
    assign m_axi4s_tvalid = reg_aresetn & !busy;

//  assign m_axi4s_tdata[AXI4S_DATA_WIDTH/2-1:0] = x;
//  assign m_axi4s_tdata[AXI4S_DATA_WIDTH-1:AXI4S_DATA_WIDTH/2] = y;
//  assign m_axi4s_tdata[7:0]   = (x<<4) + 1;
//  assign m_axi4s_tdata[15:8]  = (x<<4) + 2;
//  assign m_axi4s_tdata[23:16] = (x<<4) + 3;
    
endmodule


`default_nettype wire


// end of file
