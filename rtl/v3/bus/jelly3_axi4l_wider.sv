// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// AXI4-Lite width up-converter
//
// Converts narrow AXI4-Lite accesses on s_axi4l to a wider AXI4-Lite bus
// on m_axi4l by selecting one sub-word lane.
//
// Restrictions:
//   - m_axi4l.DATA_BITS >= s_axi4l.DATA_BITS
//   - (m_axi4l.STRB_BITS % s_axi4l.STRB_BITS) == 0
//   - One outstanding write and one outstanding read at a time.
//   - Write address/data are accepted only when AW and W are both valid.

module jelly3_axi4l_wider
        #(
            parameter           DEVICE     = "RTL"      ,
            parameter           SIMULATION = "false"    ,
            parameter           DEBUG      = "false"    
        )
        (
            jelly3_axi4l_if.s   s_axi4l ,
            jelly3_axi4l_if.m   m_axi4l 
        );

    wire    logic   reset = ~s_axi4l.aresetn ;
    wire    logic   clk   = s_axi4l.aclk      ;
    wire    logic   cke   = s_axi4l.aclken    ;

    localparam int  S_ADDR_BITS = s_axi4l.ADDR_BITS;
    localparam int  S_DATA_BITS = s_axi4l.DATA_BITS;
    localparam int  S_STRB_BITS = s_axi4l.STRB_BITS;
    localparam int  S_RESP_BITS = s_axi4l.RESP_BITS;

    localparam int  M_ADDR_BITS = m_axi4l.ADDR_BITS;
    localparam int  M_DATA_BITS = m_axi4l.DATA_BITS;
    localparam int  M_STRB_BITS = m_axi4l.STRB_BITS;
    localparam int  M_PROT_BITS = m_axi4l.PROT_BITS;

    localparam int  S_UNIT_BITS = $clog2(S_STRB_BITS);
    localparam int  M_UNIT_BITS = $clog2(M_STRB_BITS);
    localparam int  LANE_NUM    = M_STRB_BITS / S_STRB_BITS;
    localparam int  LANE_BITS   = (LANE_NUM <= 1) ? 1 : $clog2(LANE_NUM);

    localparam type s_addr_t = logic [S_ADDR_BITS-1:0];
    localparam type s_data_t = logic [S_DATA_BITS-1:0];
    localparam type s_resp_t = logic [S_RESP_BITS-1:0];

    localparam type m_addr_t = logic [M_ADDR_BITS-1:0];
    localparam type m_data_t = logic [M_DATA_BITS-1:0];
    localparam type m_strb_t = logic [M_STRB_BITS-1:0];
    localparam type m_prot_t = logic [M_PROT_BITS-1:0];

    localparam type lane_t   = logic [LANE_BITS-1:0];

    function automatic m_addr_t align_addr(input s_addr_t addr);
    begin
        align_addr = m_addr_t'(addr) & ~m_addr_t'(M_STRB_BITS-1);
    end
    endfunction

    function automatic lane_t addr_to_lane(input s_addr_t addr);
    begin
        if (LANE_NUM <= 1) begin
            addr_to_lane = '0;
        end
        else begin
            addr_to_lane = lane_t'((addr / s_addr_t'(S_STRB_BITS)) % LANE_NUM);
        end
    end
    endfunction


    // -------------------------------------------------------------------------
    //  Write path
    // -------------------------------------------------------------------------
    logic       w_busy;
    logic       w_awvalid;
    logic       w_wvalid;
    m_addr_t    w_addr;
    m_prot_t    w_prot;
    m_data_t    w_data;
    m_strb_t    w_strb;

    wire logic  s_w_accept = s_axi4l.awvalid && s_axi4l.wvalid && s_axi4l.awready && s_axi4l.wready;

    always_ff @(posedge clk) begin
        if (reset) begin
            w_busy    <= 1'b0;
            w_awvalid <= 1'b0;
            w_wvalid  <= 1'b0;
            w_addr    <= 'x;
            w_prot    <= 'x;
            w_data    <= 'x;
            w_strb    <= 'x;
        end
        else if (cke) begin
            if (w_awvalid && m_axi4l.awready) begin
                w_awvalid <= 1'b0;
            end

            if (w_wvalid && m_axi4l.wready) begin
                w_wvalid <= 1'b0;
            end

            if (w_busy && m_axi4l.bvalid && m_axi4l.bready) begin
                w_busy <= 1'b0;
            end

            if (s_w_accept) begin
                lane_t lane;
                lane = addr_to_lane(s_axi4l.awaddr);

                w_busy    <= 1'b1;
                w_awvalid <= 1'b1;
                w_wvalid  <= 1'b1;
                w_addr    <= align_addr(s_axi4l.awaddr);
                w_prot    <= m_prot_t'(s_axi4l.awprot);
                w_data    <= m_data_t'(s_axi4l.wdata) << (int'(lane) * S_DATA_BITS);
                w_strb    <= m_strb_t'(s_axi4l.wstrb) << (int'(lane) * S_STRB_BITS);
            end
        end
    end

    assign s_axi4l.awready = cke && !w_busy && s_axi4l.wvalid;
    assign s_axi4l.wready  = cke && !w_busy && s_axi4l.awvalid;
    assign s_axi4l.bvalid  = w_busy && m_axi4l.bvalid;
    assign s_axi4l.bresp   = s_resp_t'(m_axi4l.bresp);

    assign m_axi4l.awvalid = w_awvalid;
    assign m_axi4l.awaddr  = w_addr;
    assign m_axi4l.awprot  = w_prot;
    assign m_axi4l.wvalid  = w_wvalid;
    assign m_axi4l.wdata   = w_data;
    assign m_axi4l.wstrb   = w_strb;
    assign m_axi4l.bready  = cke && w_busy && s_axi4l.bready;


    // -------------------------------------------------------------------------
    //  Read path
    // -------------------------------------------------------------------------
    logic       r_busy;
    logic       r_arvalid;
    m_addr_t    r_addr;
    m_prot_t    r_prot;
    lane_t      r_lane;

    wire logic  s_r_accept = s_axi4l.arvalid && s_axi4l.arready;

    always_ff @(posedge clk) begin
        if (reset) begin
            r_busy    <= 1'b0;
            r_arvalid <= 1'b0;
            r_addr    <= 'x;
            r_prot    <= 'x;
            r_lane    <= 'x;
        end
        else if (cke) begin
            if (r_arvalid && m_axi4l.arready) begin
                r_arvalid <= 1'b0;
            end

            if (r_busy && m_axi4l.rvalid && m_axi4l.rready) begin
                r_busy <= 1'b0;
            end

            if (s_r_accept) begin
                r_busy    <= 1'b1;
                r_arvalid <= 1'b1;
                r_addr    <= align_addr(s_axi4l.araddr);
                r_prot    <= m_prot_t'(s_axi4l.arprot);
                r_lane    <= addr_to_lane(s_axi4l.araddr);
            end
        end
    end

    assign s_axi4l.arready = cke && !r_busy;
    assign s_axi4l.rvalid  = r_busy && m_axi4l.rvalid;
    assign s_axi4l.rresp   = s_resp_t'(m_axi4l.rresp);
    assign s_axi4l.rdata   = s_data_t'(m_axi4l.rdata >> (int'(r_lane) * S_DATA_BITS));

    assign m_axi4l.arvalid = r_arvalid;
    assign m_axi4l.araddr  = r_addr;
    assign m_axi4l.arprot  = r_prot;
    assign m_axi4l.rready  = cke && r_busy && s_axi4l.rready;


    // -------------------------------------------------------------------------
    //  Sanity checks
    // -------------------------------------------------------------------------
    initial begin
        if (S_ADDR_BITS != M_ADDR_BITS) begin
            $error("ERROR: ADDR_BITS of s_axi4l and m_axi4l must be same");
        end
        if (S_DATA_BITS > M_DATA_BITS) begin
            $error("ERROR: s_axi4l.DATA_BITS must be less than or equal to m_axi4l.DATA_BITS");
        end
        if ((M_STRB_BITS % S_STRB_BITS) != 0) begin
            $error("ERROR: m_axi4l.STRB_BITS must be multiple of s_axi4l.STRB_BITS");
        end
        if ((1 << S_UNIT_BITS) != S_STRB_BITS) begin
            $error("ERROR: s_axi4l.STRB_BITS must be power of two");
        end
        if ((1 << M_UNIT_BITS) != M_STRB_BITS) begin
            $error("ERROR: m_axi4l.STRB_BITS must be power of two");
        end
    end

    if (SIMULATION == "true") begin : blk_simulation
        always_comb begin
            sva_clk : assert (s_axi4l.aclk   === m_axi4l.aclk   );
            sva_cke : assert (s_axi4l.aclken === m_axi4l.aclken );
        end
    end

endmodule


`default_nettype wire


// end of file
