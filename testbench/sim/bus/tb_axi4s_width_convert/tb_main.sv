
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire        aresetn,
            input   wire        aclk
        );
    

    parameter   bit     HAS_STRB         = 1;
    parameter   bit     HAS_KEEP         = 0;
    parameter   bit     HAS_FIRST        = 1;
    parameter   bit     HAS_LAST         = 1;
    parameter   bit     HAS_ALIGN_S      = 0;  // slave 側のアライメントを指定する
    parameter   bit     HAS_ALIGN_M      = 0;  // master 側のアライメントを指定する
    parameter   int     BYTE_WIDTH       = 8;
    parameter   int     S_TDATA_WIDTH    = 4*8;
    parameter   int     M_TDATA_WIDTH    = 5*8;
    parameter   int     S_TUSER_WIDTH    = 0;
    parameter   bit     AUTO_FIRST       = (HAS_LAST & !HAS_FIRST);    // last の次を自動的に first とする
    parameter   bit     FIRST_OVERWRITE  = 1;  // first時前方に残変換があれば吐き出さずに上書き
    parameter   bit     FIRST_FORCE_LAST = 1;  // first時前方に残変換があれば強制的にlastを付与(残が無い場合はlastはつかない)
    parameter   int     ALIGN_S_WIDTH    = $clog2(S_TDATA_WIDTH / BYTE_WIDTH);
    parameter   int     ALIGN_M_WIDTH    = $clog2(M_TDATA_WIDTH / BYTE_WIDTH);
    parameter   bit     S_REGS           = 1;

    // local
    localparam  int     S_TSTRB_WIDTH    = S_TDATA_WIDTH / BYTE_WIDTH;
    localparam  int     S_TKEEP_WIDTH    = S_TDATA_WIDTH / BYTE_WIDTH;
    localparam  int     M_TSTRB_WIDTH    = M_TDATA_WIDTH / BYTE_WIDTH;
    localparam  int     M_TKEEP_WIDTH    = M_TDATA_WIDTH / BYTE_WIDTH;
    localparam  int     M_TUSER_WIDTH    = S_TUSER_WIDTH * M_TDATA_WIDTH / S_TDATA_WIDTH;
    localparam  int     S_TDATA_BITS     = S_TDATA_WIDTH > 0 ? S_TDATA_WIDTH : 1;
    localparam  int     S_TSTRB_BITS     = S_TSTRB_WIDTH > 0 ? S_TSTRB_WIDTH : 1;
    localparam  int     S_TKEEP_BITS     = S_TKEEP_WIDTH > 0 ? S_TKEEP_WIDTH : 1;
    localparam  int     S_TUSER_BITS     = S_TUSER_WIDTH > 0 ? S_TUSER_WIDTH : 1;
    localparam  int     M_TDATA_BITS     = M_TDATA_WIDTH > 0 ? M_TDATA_WIDTH : 1;
    localparam  int     M_TSTRB_BITS     = M_TSTRB_WIDTH > 0 ? M_TSTRB_WIDTH : 1;
    localparam  int     M_TKEEP_BITS     = M_TKEEP_WIDTH > 0 ? M_TKEEP_WIDTH : 1;
    localparam  int     M_TUSER_BITS     = M_TUSER_WIDTH > 0 ? M_TUSER_WIDTH : 1;
        


//    logic                        aresetn;
//    logic                        aclk;
    logic                        aclken = 1'b1;

    logic                        endian;

    logic    [ALIGN_S_WIDTH-1:0] s_align_s;
    logic    [ALIGN_M_WIDTH-1:0] s_align_m;
    logic    [S_TDATA_BITS-1:0]  s_axi4s_tdata;
    logic    [S_TSTRB_BITS-1:0]  s_axi4s_tstrb;
    logic    [S_TKEEP_BITS-1:0]  s_axi4s_tkeep;
    logic                        s_axi4s_tfirst;
    logic                        s_axi4s_tlast;
    logic    [S_TUSER_BITS-1:0]  s_axi4s_tuser;
    logic                        s_axi4s_tvalid;
    logic                        s_axi4s_tready;
    
    logic    [M_TDATA_BITS-1:0]  m_axi4s_tdata;
    logic    [M_TSTRB_BITS-1:0]  m_axi4s_tstrb;
    logic    [M_TKEEP_BITS-1:0]  m_axi4s_tkeep;
    logic                        m_axi4s_tfirst;
    logic                        m_axi4s_tlast;
    logic    [M_TUSER_BITS-1:0]  m_axi4s_tuser;
    logic                        m_axi4s_tvalid;
    logic                        m_axi4s_tready;


    jelly2_axi4s_width_convert
            #(
                .HAS_STRB           (HAS_STRB        ),
                .HAS_KEEP           (HAS_KEEP        ),
                .HAS_FIRST          (HAS_FIRST       ),
                .HAS_LAST           (HAS_LAST        ),
                .HAS_ALIGN_S        (HAS_ALIGN_S     ),
                .HAS_ALIGN_M        (HAS_ALIGN_M     ),
                .BYTE_WIDTH         (BYTE_WIDTH      ),
                .S_TDATA_WIDTH      (S_TDATA_WIDTH   ),
                .M_TDATA_WIDTH      (M_TDATA_WIDTH   ),
                .S_TUSER_WIDTH      (S_TUSER_WIDTH   ),
                .AUTO_FIRST         (AUTO_FIRST      ),
                .FIRST_OVERWRITE    (FIRST_OVERWRITE ),
                .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                .ALIGN_S_WIDTH      (ALIGN_S_WIDTH   ),
                .ALIGN_M_WIDTH      (ALIGN_M_WIDTH   ),
                .S_REGS             (S_REGS          )
            )
        i_axi4s_width_convert
            (
                .aresetn,
                .aclk,
                .aclken,

                .endian,

                .s_align_s,
                .s_align_m,
                .s_axi4s_tdata,
                .s_axi4s_tstrb,
                .s_axi4s_tkeep,
                .s_axi4s_tfirst,
                .s_axi4s_tlast,
                .s_axi4s_tuser,
                .s_axi4s_tvalid,
                .s_axi4s_tready,

                .m_axi4s_tdata,
                .m_axi4s_tstrb,
                .m_axi4s_tkeep,
                .m_axi4s_tfirst,
                .m_axi4s_tlast,
                .m_axi4s_tuser,
                .m_axi4s_tvalid,
                .m_axi4s_tready
            );
    

    logic   [6:0]   count;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            count          <= '0;
        end
        else if ( aclken ) begin
              if ( !s_axi4s_tvalid || s_axi4s_tready ) begin
                count <= count + 1;
              end
        end
    end

    assign s_align_s     = '0;
    assign s_align_m     = '0;
    assign s_axi4s_tstrb = '1;
    assign s_axi4s_tkeep = '0;
    assign s_axi4s_tuser = '0;

    always_comb begin
        s_axi4s_tfirst = 'x;
        s_axi4s_tlast  = 'x;
        s_axi4s_tdata  = 'x;
        s_axi4s_tvalid = count[6];
        if ( s_axi4s_tvalid ) begin
            s_axi4s_tfirst = (count[5:0] == 6'h00);
            s_axi4s_tlast  = (count[5:0] == 6'h3f);
            s_axi4s_tdata[8*0 +:8] = {count[5:0], 2'd0};
            s_axi4s_tdata[8*1 +:8] = {count[5:0], 2'd1};
            s_axi4s_tdata[8*2 +:8] = {count[5:0], 2'd2};
            s_axi4s_tdata[8*3 +:8] = {count[5:0], 2'd3};
        end
    end

    assign m_axi4s_tready = 1'b1;

endmodule


`default_nettype wire


// end of file
