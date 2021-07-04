


#pragma once

namespace jelly {
namespace simulator {


template<typename Trst_i, typename Tclk_i, typename Tadr_o, typename Tdat_o, typename Tdat_i, typename Tsel_o, typename Twe_o, typename Tstb_o, typename Tack_i>
struct WishboneMaster {
    Trst_i *rst_i;
    Tclk_i *clk_i;
    Tadr_o *adr_o;
    Tdat_i *dat_i;
    Tdat_o *dat_o;
    Tsel_o *sel_o;
    Twe_o  *we_o;
    Tstb_o *stb_o;
    Tack_i *ack_i;

    WishboneMaster(){}
    WishboneMaster(
            Trst_i *rst_i_,
            Tclk_i *clk_i_,
            Tadr_o *adr_o_,
            Tdat_i *dat_i_,
            Tdat_o *dat_o_,
            Tsel_o *sel_o_,
            Twe_o  *we_o_,
            Tstb_o *stb_o_,
            Tack_i *ack_i_
        )
    {
        rst_i = rst_i_;
        clk_i = clk_i_;
        adr_o = adr_o_;
        dat_i = dat_i_;
        dat_o = dat_o_;
        sel_o = sel_o_;
        we_o  = we_o_;
        stb_o = stb_o_;
        ack_i = ack_i_;
    }
};


}
}


// end of file
