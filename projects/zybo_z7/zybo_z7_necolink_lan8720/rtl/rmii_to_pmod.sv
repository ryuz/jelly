

`timescale 1ns / 1ps
`default_nettype none

module rmii_to_pmod
        (
            output  wire    [3:0]       rmii_refclk,
            input   wire    [3:0]       rmii_txen,
            input   wire    [3:0][1:0]  rmii_tx,
            output  wire    [3:0][1:0]  rmii_rx,
            output  wire    [3:0]       rmii_crs,
            output  wire    [3:0]       rmii_mdc,
            input   wire    [3:0]       rmii_mdio_t,
            input   wire    [3:0]       rmii_mdio_o,
            output  wire    [3:0]       rmii_mdio_i,

            inout   wire    [7:0]       pmod_a,
            inout   wire    [7:0]       pmod_b,
            inout   wire    [7:0]       pmod_c,
            inout   wire    [7:0]       pmod_d,
            inout   wire    [7:0]       pmod_e
        );


    IOBUF   i_iobuf_pmod_a0 (.IO(pmod_a[0]), .I(rmii_tx    [0][0]), .O(),                  .T(1'b0));
    IOBUF   i_iobuf_pmod_a1 (.IO(pmod_a[1]), .I(1'b0),              .O(rmii_rx    [0][1]), .T(1'b1));
    IOBUF   i_iobuf_pmod_a2 (.IO(pmod_a[2]), .I(1'b0),              .O(rmii_crs   [0]  ),  .T(1'b1));
    IOBUF   i_iobuf_pmod_a3 (.IO(pmod_a[3]), .I(1'b1),              .O(rmii_mdc   [0]  ),  .T(1'b0));
    IOBUF   i_iobuf_pmod_a4 (.IO(pmod_a[4]), .I(rmii_txen  [0]),    .O(),                  .T(1'b0));
    IOBUF   i_iobuf_pmod_a5 (.IO(pmod_a[5]), .I(1'b0),              .O(rmii_rx    [0][0]), .T(1'b1));
    IOBUF   i_iobuf_pmod_a6 (.IO(pmod_a[6]), .I(1'b0),              .O(rmii_refclk[0]),    .T(1'b1));
    IOBUF   i_iobuf_pmod_a7 (.IO(pmod_a[7]), .I(rmii_mdio_o[0]),    .O(rmii_mdio_i[0]),    .T(rmii_mdio_t[0]));
    IOBUF   i_iobuf_pmod_c0 (.IO(pmod_c[0]), .I(rmii_tx    [0][1]), .O(),                  .T(1'b0));

    IOBUF   i_iobuf_pmod_b0 (.IO(pmod_b[0]), .I(rmii_tx    [1][0]), .O(),                  .T(1'b0));
    IOBUF   i_iobuf_pmod_b1 (.IO(pmod_b[1]), .I(1'b0),              .O(rmii_rx    [1][1]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b2 (.IO(pmod_b[2]), .I(1'b0),              .O(rmii_crs   [1]  ),  .T(1'b1));
    IOBUF   i_iobuf_pmod_b3 (.IO(pmod_b[3]), .I(1'b1),              .O(rmii_mdc   [1]  ),  .T(1'b0));
    IOBUF   i_iobuf_pmod_b4 (.IO(pmod_b[4]), .I(rmii_txen  [1]),    .O(),                  .T(1'b0));
    IOBUF   i_iobuf_pmod_b5 (.IO(pmod_b[5]), .I(1'b0),              .O(rmii_rx    [1][0]), .T(1'b1));
    IOBUF   i_iobuf_pmod_b6 (.IO(pmod_b[6]), .I(1'b0),              .O(rmii_refclk[1]),    .T(1'b1));
    IOBUF   i_iobuf_pmod_b7 (.IO(pmod_b[7]), .I(rmii_mdio_o[1]),    .O(rmii_mdio_i[1]),    .T(rmii_mdio_t[1]));
    IOBUF   i_iobuf_pmod_c1 (.IO(pmod_c[1]), .I(rmii_tx    [1][1]), .O(),                  .T(1'b0));

    IOBUF   i_iobuf_pmod_d0 (.IO(pmod_d[0]), .I(rmii_tx    [2][0]), .O(),                  .T(1'b0));
    IOBUF   i_iobuf_pmod_d1 (.IO(pmod_d[1]), .I(1'b0),              .O(rmii_rx    [2][1]), .T(1'b1));
    IOBUF   i_iobuf_pmod_d2 (.IO(pmod_d[2]), .I(1'b0),              .O(rmii_crs   [2]  ),  .T(1'b1));
    IOBUF   i_iobuf_pmod_d3 (.IO(pmod_d[3]), .I(1'b1),              .O(rmii_mdc   [2]  ),  .T(1'b0));
    IOBUF   i_iobuf_pmod_d4 (.IO(pmod_d[4]), .I(rmii_txen  [2]),    .O(),                  .T(1'b0));
    IOBUF   i_iobuf_pmod_d5 (.IO(pmod_d[5]), .I(1'b0),              .O(rmii_rx    [2][0]), .T(1'b1));
    IOBUF   i_iobuf_pmod_d6 (.IO(pmod_d[6]), .I(1'b0),              .O(rmii_refclk[2]),    .T(1'b1));
    IOBUF   i_iobuf_pmod_d7 (.IO(pmod_d[7]), .I(rmii_mdio_o[2]),    .O(rmii_mdio_i[2]),    .T(rmii_mdio_t[2]));
    IOBUF   i_iobuf_pmod_c2 (.IO(pmod_c[2]), .I(rmii_tx    [2][1]), .O(),                  .T(1'b0));

    IOBUF   i_iobuf_pmod_e0 (.IO(pmod_e[0]), .I(rmii_tx    [3][0]), .O(),                  .T(1'b0));
    IOBUF   i_iobuf_pmod_e1 (.IO(pmod_e[1]), .I(1'b0),              .O(rmii_rx    [3][1]), .T(1'b1));
    IOBUF   i_iobuf_pmod_e2 (.IO(pmod_e[2]), .I(1'b0),              .O(rmii_crs   [3]  ),  .T(1'b1));
    IOBUF   i_iobuf_pmod_e3 (.IO(pmod_e[3]), .I(1'b1),              .O(rmii_mdc   [3]  ),  .T(1'b0));
    IOBUF   i_iobuf_pmod_e4 (.IO(pmod_e[4]), .I(rmii_txen  [3]),    .O(),                  .T(1'b0));
    IOBUF   i_iobuf_pmod_e5 (.IO(pmod_e[5]), .I(1'b0),              .O(rmii_rx    [3][0]), .T(1'b1));
    IOBUF   i_iobuf_pmod_e6 (.IO(pmod_e[6]), .I(1'b0),              .O(rmii_refclk[3]),    .T(1'b1));
    IOBUF   i_iobuf_pmod_e7 (.IO(pmod_e[7]), .I(rmii_mdio_o[3]),    .O(rmii_mdio_i[3]),    .T(rmii_mdio_t[3]));
    IOBUF   i_iobuf_pmod_c3 (.IO(pmod_c[3]), .I(rmii_tx    [3][1]), .O(),                  .T(1'b0));

endmodule


`default_nettype wire

