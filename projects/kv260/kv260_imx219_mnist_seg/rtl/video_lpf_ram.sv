

`timescale 1ns / 1ps
`default_nettype none


module video_lpf_ram
        #(
            parameter   int                         NUM              = 11 + 3,
            parameter   int                         DATA_WIDTH       = 8,
            parameter   int                         ADDR_WIDTH       = 17,
            parameter   int                         MEM_SIZE         = (1 << ADDR_WIDTH),
            parameter   int                         TUSER_WIDTH      = 1,
            parameter   int                         TDATA_WIDTH      = NUM * DATA_WIDTH,
            parameter   int                         WB_ADR_WIDTH     = 10,
            parameter   int                         WB_DAT_WIDTH     = 32,
            parameter   int                         WB_SEL_WIDTH     = (WB_DAT_WIDTH / 8),
            parameter   bit     [DATA_WIDTH:0]      INIT_PARAM_ALPHA = '0
        )
        (
            input   var logic                       aresetn,
            input   var logic                       aclk,

            input   var logic                       s_wb_rst_i,
            input   var logic                       s_wb_clk_i,
            input   var logic   [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   var logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  var logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   var logic                       s_wb_we_i,
            input   var logic   [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   var logic                       s_wb_stb_i,
            output  var logic                       s_wb_ack_o,

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
    
    // -------------------------------------
    //  registers domain
    // -------------------------------------
    
    // register address offset
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_ALPHA     = WB_ADR_WIDTH'('h08);

    // registers
    logic   [DATA_WIDTH:0]      reg_param_alpha;

    
    // shadow registers(core domain)
    logic   [DATA_WIDTH:0]      core_param_alpha;
    
    // write mask
    function [WB_DAT_WIDTH-1:0] write_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] wdat,
                                        input [WB_SEL_WIDTH-1:0] msk
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            write_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction
    

    // registers control
    always_ff @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
            reg_param_alpha   <= INIT_PARAM_ALPHA;
        end
        else begin
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_PARAM_ALPHA:    reg_param_alpha <= (DATA_WIDTH+1)'(write_mask(WB_DAT_WIDTH'(reg_param_alpha), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase
            end
        end
    end
    
    // read
    always_comb begin
        s_wb_dat_o = '0;
        case ( s_wb_adr_i )
        ADR_PARAM_ALPHA:        s_wb_dat_o = WB_DAT_WIDTH'(reg_param_alpha           );
        default: ;
        endcase
    end
    
    always_comb s_wb_ack_o = s_wb_stb_i;
    


    // -------------------------------------
    //  core domain
    // -------------------------------------

    always_ff @(posedge aclk) begin
        if ( !aresetn ) begin
            core_param_alpha <= INIT_PARAM_ALPHA;
        end
        else begin
            core_param_alpha <= reg_param_alpha;
        end
    end

    video_lpf_ram_core
            #(
                .NUM            (NUM            ),
                .DATA_WIDTH     (DATA_WIDTH     ),
                .ADDR_WIDTH     (ADDR_WIDTH     ),
                .MEM_SIZE       (MEM_SIZE       ),
                .TUSER_WIDTH    (TUSER_WIDTH    ),
                .TDATA_WIDTH    (TDATA_WIDTH    )
            )
        u_video_lpf_ram_core
            (
                .aresetn,
                .aclk,

                .param_alpha    (core_param_alpha),

                .s_axi4s_tuser,
                .s_axi4s_tlast,
                .s_axi4s_tdata,
                .s_axi4s_tvalid,
                .s_axi4s_tready,

                .m_axi4s_tuser,
                .m_axi4s_tlast,
                .m_axi4s_tdata,
                .m_axi4s_tvalid,
                .m_axi4s_tready
            );

endmodule



`default_nettype wire



// end of file
