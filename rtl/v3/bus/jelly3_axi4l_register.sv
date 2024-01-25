


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_register
    #(
        parameter   int                             NUM   = 4,
        parameter   int                             WIDTH = 32,
        parameter   logic   [NUM-1:0][WIDTH-1:0]    INIT  = '0
    )
    (
        jelly3_axi4l_if.s                       s_axi4l,
        output  logic   [NUM-1:0][WIDTH-1:0]    value
    );

    localparam REG_ADDR_WIDTH = $clog2(NUM);
    localparam REG_DATA_WIDTH = WIDTH;
    localparam AXI_ADDR_WIDTH = s_axi4l.ADDR_WIDTH;
    localparam AXI_DATA_WIDTH = s_axi4l.DATA_WIDTH;

    typedef logic   [REG_ADDR_WIDTH-1:0]        reg_addr_t;
    typedef logic   [REG_DATA_WIDTH-1:0]        reg_data_t;
    typedef logic   [s_axi4l.DATA_WIDTH-1:0]    axi_data_t;

    reg_data_t  reg_data    [0:NUM-1];

    // write
    logic       bvalid;
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                reg_data[i] <= INIT[i];
            end
            bvalid <= 0;
        end
        else begin
            if ( s_axi4l.bready ) begin
                bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                reg_data[reg_addr_t'(s_axi4l.awaddr)] <= reg_data_t'(s_axi4l.wdata);
                bvalid <= 1'b1;
            end
        end
    end
    assign s_axi4l.awready = ~bvalid || s_axi4l.bready;
    assign s_axi4l.bresp   = '0;
    assign s_axi4l.bvalid  = bvalid;


    // read
    axi_data_t  rdata;
    logic       rvalid;
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            rdata  <= 'x;
            rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l.rready ) begin
                rdata  <= 'x;
                rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                rdata  <= reg_data[reg_addr_t'(s_axi4l.araddr)];
                rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.rdata  = rdata;
    assign s_axi4l.rresp  = '0;
    assign s_axi4l.rvalid = rvalid;

endmodule


`default_nettype wire


// end of file
