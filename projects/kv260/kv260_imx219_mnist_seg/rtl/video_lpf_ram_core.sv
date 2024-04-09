

`timescale 1ns / 1ps
`default_nettype none


module video_lpf_ram_core
        #(
            parameter   int     NUM           = 11 + 3,
            parameter   int     DATA_WIDTH    = 8,
            parameter   int     ADDR_WIDTH    = 17,
            parameter   int     MEM_SIZE      = (1 << ADDR_WIDTH),
            parameter   int     TUSER_WIDTH   = 1,
            parameter   int     TDATA_WIDTH   = NUM * DATA_WIDTH
        )
        (
            input   var logic                       aresetn,
            input   var logic                       aclk,

            input   var logic   [DATA_WIDTH:0]      param_alpha,


            input   var logic   [TUSER_WIDTH-1:0]   s_axi4s_tuser,
            input   var logic                       s_axi4s_tlast,
            input   var logic   [TDATA_WIDTH-1:0]   s_axi4s_tdata,
            input   var logic                       s_axi4s_tvalid,
            output  var logic                       s_axi4s_tready,
            
            output  var logic   [TUSER_WIDTH-1:0]   m_axi4s_tuser,
            output  var logic                       m_axi4s_tlast,
            output  var logic   [TDATA_WIDTH-1:0]   m_axi4s_tdata,
            output  var logic                       m_axi4s_tvalid,
            input   var logic                       m_axi4s_tready
        );
    
    logic                               cke         ;
    assign cke = m_axi4s_tready || !m_axi4s_tvalid;

    assign s_axi4s_tready = cke;
    

    localparam type mut_t = logic [DATA_WIDTH*2:0];

    logic   [DATA_WIDTH:0]      param_alpha1;
    assign param_alpha1 = (1 << DATA_WIDTH) - param_alpha;

    // ram
    logic   [ADDR_WIDTH-1:0]    wr_addr     ;
    logic   [TDATA_WIDTH-1:0]   wr_din      ;
    logic   [ADDR_WIDTH-1:0]    rd_addr     ;
    logic   [TDATA_WIDTH-1:0]   rd_dout     ;

    jelly2_ram_simple_dualport
            #(
                .ADDR_WIDTH     (ADDR_WIDTH ),
                .DATA_WIDTH     (TDATA_WIDTH),
                .RAM_TYPE       ("ultra"    ),
                .DOUT_REGS      (1          ),
                .FILLMEM        (1          ),
                .FILLMEM_DATA   (0          )
            )
        u_ram_simple_dualport
            (
                .wr_clk         (aclk       ),
                .wr_en          (cke        ),
                .wr_addr,
                .wr_din,

                .rd_clk         (aclk       ),
                .rd_en          (cke        ),
                .rd_regcke      (cke        ),
                .rd_addr,
                .rd_dout
            );


    logic   [TUSER_WIDTH-1:0]           st0_tuser   ;
    logic                               st0_tlast   ;
    logic   [NUM-1:0][DATA_WIDTH-1:0]   st0_tdata   ;
    logic                               st0_tvalid  ;

    logic   [ADDR_WIDTH-1:0]            st1_addr    ;
    logic   [TUSER_WIDTH-1:0]           st1_tuser   ;
    logic                               st1_tlast   ;
    logic   [NUM-1:0][DATA_WIDTH-1:0]   st1_tdata   ;
    logic                               st1_tvalid  ;

    logic   [ADDR_WIDTH-1:0]            st2_addr    ;
    logic   [TUSER_WIDTH-1:0]           st2_tuser   ;
    logic                               st2_tlast   ;
    logic   [NUM-1:0][DATA_WIDTH-1:0]   st2_tdata   ;
    logic                               st2_tvalid  ;

    logic   [ADDR_WIDTH-1:0]            st3_addr    ;
    logic   [TUSER_WIDTH-1:0]           st3_tuser   ;
    logic                               st3_tlast   ;
    logic   [NUM-1:0][DATA_WIDTH-1:0]   st3_tdata   ;
//  logic   [NUM-1:0][DATA_WIDTH-1:0]   st3_rdata   ;
    logic                               st3_tvalid  ;

    logic   [ADDR_WIDTH-1:0]            st4_addr    ;
    logic   [TUSER_WIDTH-1:0]           st4_tuser   ;
    logic                               st4_tlast   ;
    logic   [NUM-1:0][DATA_WIDTH-1:0]   st4_tdata   ;
    logic   [NUM-1:0][DATA_WIDTH-1:0]   st4_rdata   ;
    logic                               st4_tvalid  ;

    logic   [ADDR_WIDTH-1:0]            st5_addr    ;
    logic   [TUSER_WIDTH-1:0]           st5_tuser   ;
    logic                               st5_tlast   ;
    logic   [NUM-1:0][DATA_WIDTH-1:0]   st5_tdata   ;
    logic                               st5_tvalid  ;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            st0_tvalid <= 1'b0;
            st1_tvalid <= 1'b0;
            st2_tvalid <= 1'b0;
            st3_tvalid <= 1'b0;
            st4_tvalid <= 1'b0;
            st5_tvalid <= 1'b0;
        end
        else if ( cke ) begin
            st0_tvalid <= s_axi4s_tvalid;
            st1_tvalid <= st0_tvalid;
            st2_tvalid <= st1_tvalid;
            st3_tvalid <= st2_tvalid;
            st4_tvalid <= st3_tvalid;
            st5_tvalid <= st4_tvalid;
        end
    end
    
    always_ff @(posedge aclk) begin
        if ( cke ) begin
            // stage0
            st0_tuser <=  s_axi4s_tuser;
            st0_tlast <=  s_axi4s_tlast;
            st0_tdata <=  s_axi4s_tdata;

            // stage1
            st1_addr  <= st1_addr + ADDR_WIDTH'(st1_tvalid);
            if ( st0_tvalid && st0_tuser[0] ) begin
                st1_addr <= '0;
            end
            st1_tuser <=  st0_tuser;
            st1_tlast <=  st0_tlast;
            st1_tdata <=  st0_tdata;

            // stage2
            st2_addr  <=  st1_addr;
            st2_tuser <=  st1_tuser;
            st2_tlast <=  st1_tlast;
            st2_tdata <=  st1_tdata;

            // stage3
            st3_addr  <=  st2_addr;
            st3_tuser <=  st2_tuser;
            st3_tlast <=  st2_tlast;
            st3_tdata <=  st2_tdata;
//          st3_rdata <=  rd_dout;

            // stage4
            st4_addr  <=  st3_addr;
            st4_tuser <=  st3_tuser;
            st4_tlast <=  st3_tlast;
            for ( int i = 0; i < NUM; i = i + 1 ) begin
                st4_tdata[i] <=  DATA_WIDTH'((mut_t'(st3_tdata[i]) * mut_t'(param_alpha1)) >> DATA_WIDTH);
                st4_rdata[i] <=  DATA_WIDTH'((mut_t'(rd_dout  [i]) * mut_t'(param_alpha )) >> DATA_WIDTH);
            end

            // stage5
            st5_addr  <=  st4_addr;
            st5_tuser <=  st4_tuser;
            st5_tlast <=  st4_tlast;
            for ( int i = 0; i < NUM; i = i + 1 ) begin
                st5_tdata[i] <= st4_tdata[i] + st4_rdata[i];
            end

        end
    end

    assign rd_addr = st1_addr   ;
    assign wr_addr = st5_addr   ;
    assign wr_din  = st5_tdata  ;
    
    assign m_axi4s_tuser  = st5_tuser   ;
    assign m_axi4s_tlast  = st5_tlast   ;
    assign m_axi4s_tdata  = st5_tdata   ;
    assign m_axi4s_tvalid = st5_tvalid  ;

endmodule



`default_nettype wire



// end of file
