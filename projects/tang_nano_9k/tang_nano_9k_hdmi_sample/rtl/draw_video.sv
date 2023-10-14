


`timescale 1ns / 1ps
`default_nettype none


module draw_video
        #(
            parameter X_SIZE = 640,
            parameter Y_SIZE = 480,
            parameter BALL_R = 8,
            parameter BAR_W  = 64,
            parameter BAR_H  = 12,
            parameter X_WIDTH = $clog2(X_SIZE),
            parameter Y_WIDTH = $clog2(Y_SIZE)
        )
        (
            input   var logic                   reset,
            input   var logic                   clk,

            // control
            input   var logic                   push_sw,

            // input        
            input   var logic                   in_vsync,
            input   var logic                   in_hsync,
            input   var logic                   in_de,
            input   var logic   [X_WIDTH-1:0]   in_x,
            input   var logic   [Y_WIDTH-1:0]   in_y,
            
            // output
            output  var logic                   out_vsync,
            output  var logic                   out_hsync,
            output  var logic                   out_de,
            output  var logic   [2:0][7:0]      out_rgb,
            output  var logic                   out_fs,
            output  var logic                   out_le
        );

        localparam COORD_WIDTH = (X_WIDTH > Y_WIDTH ? X_WIDTH : Y_WIDTH) + 1;
        localparam type coord_t  = logic signed [COORD_WIDTH-1:0];
        localparam type coord2_t = logic signed [COORD_WIDTH*2:0];

        // detect frame start
        logic       prev_vsync;
        logic       frame_start;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                prev_vsync <= 1'b0;
                frame_start    <= 1'b0;
            end
            else begin
                prev_vsync  <= in_vsync;
                frame_start <= {prev_vsync, in_vsync} == 2'b10;
            end
        end


        coord_t bar_x;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                bar_x <= coord_t'(X_SIZE / 2);
            end
            else if ( frame_start ) begin
                if ( bar_x <= coord_t'(X_SIZE - BAR_W / 2) && push_sw ) begin
                    bar_x <= bar_x + 3;
                end
                if ( bar_x >= coord_t'(BAR_W / 2) && ~push_sw ) begin
                    bar_x <= bar_x - 3;
                end
            end
        end

        // ball position
        logic   ball_restart;
        logic   ball_dead;
        coord_t ball_dx;
        coord_t ball_dy;
        coord_t ball_x;
        coord_t ball_y;

        logic   ball_bar_hit;
        coord_t ball_bar_dx;
        always_ff @(posedge clk) begin
            ball_bar_dx  <= ball_x - bar_x;
            ball_bar_hit <= ball_bar_dx >= coord_t'(-BAR_W / 2)
                            && ball_bar_dx <= coord_t'(BAR_W / 2);
        end

        always_ff @(posedge clk) begin
            if ( reset || ball_restart ) begin
                ball_restart <= 1'b0;
                ball_dead    <= 1'b0;
                ball_dx      <= coord_t'(-2);
                ball_dy      <= coord_t'(-2);
                ball_x       <= coord_t'(X_SIZE / 2);
                ball_y       <= coord_t'(Y_SIZE / 2);
            end
            else if ( frame_start ) begin
                // ボールを移動させる
                ball_x <= ball_x + ball_dx;
                ball_y <= ball_y + ball_dy;
                

                // X方向の反射
                if ( (ball_x < coord_t'(BALL_R) && ball_dx < 0)
                     || (ball_x > coord_t'(X_SIZE - BALL_R) && ball_dx > 0) ) begin
                        ball_dx <= -ball_dx;                    
                end 

                // Y方向の反射
                if ( (ball_y <= coord_t'(BALL_R) && ball_dy < 0)
                     || (ball_y > coord_t'(Y_SIZE - BALL_R - BAR_H) && ball_dy > 0 && ball_bar_hit) ) begin
                        ball_dy <= -ball_dy;                    
                end 

                ball_dead <= (ball_y >= coord_t'(Y_SIZE - BALL_R));
                if ( ball_y > coord_t'(Y_SIZE) ) begin
                    ball_restart <= 1'b1;
                end
            end
        end


        localparam STAGES = 5;
        logic       st_vsync    [STAGES-1:0];
        logic       st_hsync    [STAGES-1:0];
        logic       st_de       [STAGES-1:0];
        coord_t     st_x        [STAGES-1:0];
        coord_t     st_y        [STAGES-1:0];
        always_ff @(posedge clk) begin
            if ( reset ) begin
                for ( int i = 0; i < STAGES; ++i ) begin
                    st_vsync[i] <= 1'b1;
                    st_hsync[i] <= 1'b1;
                    st_de   [i] <= 1'b0;
                    st_x    [i] <= 'x;
                    st_y    [i] <= 'x;
                end
            end
            else begin
                st_vsync[0] <= in_vsync;
                st_hsync[0] <= in_hsync;
                st_de   [0] <= in_de   ;
                st_x    [0] <= coord_t'({1'b0, in_x});
                st_y    [0] <= coord_t'({1'b0, in_y});
                for ( int i = 1; i < STAGES; ++i ) begin
                    st_vsync[i] <= st_vsync[i-1];
                    st_hsync[i] <= st_hsync[i-1];
                    st_de   [i] <= st_de   [i-1];
                    st_x    [i] <= st_x    [i-1];
                    st_y    [i] <= st_y    [i-1];
                end
            end
        end
        assign out_vsync = st_vsync[STAGES-1];
        assign out_hsync = st_hsync[STAGES-1];
        assign out_de    = st_de   [STAGES-1];
        assign out_fs    = st_x[STAGES-1] == '0 && st_y[STAGES-1] == '0;    // for axi4s tuser
        assign out_le    = st_x[STAGES-1] == coord_t'(X_SIZE-1);            // for axi4s tlast
        

        // draw
        coord_t             st1_ball_x  ;
        coord_t             st1_ball_y  ;

        coord2_t            st2_ball_x2 ;
        coord2_t            st2_ball_y2 ;

        coord2_t            st3_ball_r2 ;
        coord_t             st3_bar_dx  ;

        logic               st4_ball    ;
        logic               st4_bar     ;

        logic   [2:0][7:0]  st5_rgb   ;

        
        always_ff @(posedge clk) begin
            // stage 1
            st1_ball_x <= st_x[0] - ball_x;
            st1_ball_y <= st_y[0] - ball_y;

            // stage 2
            st2_ball_x2 <= coord2_t'(st1_ball_x) * coord2_t'(st1_ball_x);
            st2_ball_y2 <= coord2_t'(st1_ball_y) * coord2_t'(st1_ball_y);

            // stage 3
            st3_ball_r2 <= st2_ball_x2 + st2_ball_y2;
            st3_bar_dx  <= st_x[2] - bar_x;

            // stage 4
            st4_ball    <= (st3_ball_r2 <= coord2_t'(BALL_R * BALL_R));
            st4_bar     <= st_y[3] >= coord_t'(Y_SIZE - BAR_H)
                            && st3_bar_dx >= coord_t'(-BAR_W / 2)
                            && st3_bar_dx <= coord_t'(BAR_W / 2);

            // stage 5
            st5_rgb <= ball_dead ? 24'h2f0000 : 24'h00002f;   // BGC
            if (st_x[4][4:0] == '0 || st_y[4][4:0] == '0) begin
                st5_rgb <= ball_dead ? 24'hff0000 : 24'h0000ff;  // grid
            end
            if ( st4_bar ) begin
                st5_rgb <= 24'h7fff7f;  // bar
            end
            if ( st4_ball ) begin
                st5_rgb <= 24'hffffff;  // ball
            end
        end

        assign out_rgb = st5_rgb;
    

endmodule


`default_nettype wire


// end of file
