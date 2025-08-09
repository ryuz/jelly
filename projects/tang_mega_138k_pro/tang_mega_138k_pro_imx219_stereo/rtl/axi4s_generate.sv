
`default_nettype none

module axi4s_generate
        #(
            parameter   int     X_BITS    = 14                      ,
            parameter   type    x_t       = logic [X_BITS-1:0]      ,
            parameter   int     Y_BITS    = 14                      ,
            parameter   type    y_t       = logic [Y_BITS-1:0]      ,
            parameter   int     DATA_BITS = 24                      ,
            parameter   type    data_t    = logic [DATA_BITS-1:0]   
        )
        (
            input   var x_t     param_width ,
            input   var y_t     param_height,

            output  var logic   mem_en      ,
            output  var x_t     mem_addrx   ,
            output  var y_t     mem_addry   ,
            input   var data_t  mem_rdata   ,

            jelly3_axi4s_if.m   m_axi4s     
        );


    x_t     st0_x       ;
    y_t     st0_y       ;
    logic   st0_valid   ;

    logic   st1_tuser   ;
    logic   st1_tlast   ;
    logic   st1_valid   ;

    logic   st2_tuser   ;
    logic   st2_tlast   ;
    logic   st2_valid   ;

    always_ff @(posedge m_axi4s.aclk ) begin
        if ( ~m_axi4s.aresetn ) begin
            st0_x     <= '0;
            st0_y     <= '0;
            st0_valid <= 1'b0;

            st1_tuser <= 'x;
            st1_tlast <= 'x;
            st1_valid <= 1'b0;

            st2_tuser <= 'x;
            st2_tlast <= 'x;
            st2_valid <= 1'b0;
        end
        else if ( m_axi4s.tready ) begin
            // stage 0
            st0_x <= st0_x + 1;
            if ( st0_x == param_width - 1 ) begin
                st0_x <= '0;
                st0_y <= st0_y + 1;
                if ( st0_y == param_height - 1 ) begin
                    st0_y <= '0;
                end
            end
            st0_valid <= 1'b1;

            // stage 1
            st1_tuser <= (st0_x == '0) && (st0_y == '0);
            st1_tlast <= (st0_x == param_width - 1);
            st1_valid <= st0_valid;

            // stage 2
            st2_tuser <= st1_tuser;
            st2_tlast <= st1_tlast;
            st2_valid <= st1_valid;
        end
    end
    
    assign mem_en    = m_axi4s.tready   ;
    assign mem_addrx = st0_x            ;
    assign mem_addry = st0_y            ;

    assign m_axi4s.tuser  = st2_tuser   ;
    assign m_axi4s.tlast  = st2_tlast   ;
    assign m_axi4s.tdata  = mem_rdata   ;
    assign m_axi4s.tvalid = st2_valid   ;

endmodule


`default_nettype wire

