

`timescale 1ns / 1ps
`default_nettype none


module video_argmax
        #(
            parameter   int     CLASS_NUM     = 11,
            parameter   int     CLASS_WIDTH   = 8,
            parameter   int     ARGMAX_WIDTH  = 8,
            parameter   int     TDATA_WIDTH   = 24,
            parameter   int     TUSER_WIDTH   = 1
        )
        (
            input   var logic                                       aresetn,
            input   var logic                                       aclk,

            input   var logic   [TUSER_WIDTH-1:0]                   s_axi4s_tuser,
            input   var logic                                       s_axi4s_tlast,
            input   var logic   [TDATA_WIDTH-1:0]                   s_axi4s_tdata,
            input   var logic   [CLASS_NUM-1:0][CLASS_WIDTH-1:0]    s_axi4s_tclass,
            input   var logic                                       s_axi4s_tvalid,
            output  var logic                                       s_axi4s_tready,
            
            output  var logic   [TUSER_WIDTH-1:0]                   m_axi4s_tuser,
            output  var logic                                       m_axi4s_tlast,
            output  var logic   [TDATA_WIDTH-1:0]                   m_axi4s_tdata,
            output  var logic   [ARGMAX_WIDTH-1:0]                  m_axi4s_targmax,
            output  var logic                                       m_axi4s_tvalid,
            input   var logic                                       m_axi4s_tready
        );

    localparam  INDEX_WIDTH = $clog2(CLASS_NUM);

    logic                               cke         ;
    assign cke = m_axi4s_tready || !m_axi4s_tvalid;

    assign s_axi4s_tready = cke;

    logic   [INDEX_WIDTH-1:0]  m_index;

    jelly_minmax
            #(
                .NUM                (CLASS_NUM      ),
                .INDEX_WIDTH        (INDEX_WIDTH    ),
                .COMMON_USER_WIDTH  (TUSER_WIDTH + 1 + TDATA_WIDTH),
                .USER_WIDTH         (0              ),
                .DATA_WIDTH         (CLASS_WIDTH    ),
                .DATA_SIGNED        (0              ),
                .CMP_MIN            (0              ),      // minかmaxか
                .CMP_EQ             (0              )       // 同値のとき data0 と data1 どちらを優先するか
            )
        u_minmax
            (
                .reset              (~aresetn       ),
                .clk                (aclk           ),
                .cke                (cke            ),

                .s_common_user      ({s_axi4s_tuser, s_axi4s_tlast, s_axi4s_tdata}),
                .s_user             ('0             ),
                .s_data             (s_axi4s_tclass ),
                .s_en               ('1             ),
                .s_valid            (s_axi4s_tvalid ),

                .m_common_user      ({m_axi4s_tuser, m_axi4s_tlast, m_axi4s_tdata}),
                .m_user             (               ),
                .m_data             (               ),
                .m_index            (m_index        ),
                .m_en               (               ),
                .m_valid            (m_axi4s_tvalid )
            );
    
    assign m_axi4s_targmax = ARGMAX_WIDTH'(m_index);

endmodule



`default_nettype wire



// end of file
