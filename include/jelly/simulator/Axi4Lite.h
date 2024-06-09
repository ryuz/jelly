


#pragma once

namespace jelly {
namespace simulator {


template<
    typename Taresetn,
    typename Taclk   ,
    typename Tawaddr ,
    typename Tawprot ,
    typename Tawvalid,
    typename Tawready,
    typename Twdata  ,
    typename Twstrb  ,
    typename Twvalid ,
    typename Twready ,
    typename Tbresp  ,
    typename Tbvalid ,
    typename Tbready ,
    typename Taraddr ,
    typename Tarprot ,
    typename Tarvalid,
    typename Tarready,
    typename Trdata  ,
    typename Trresp  ,
    typename Trvalid ,
    typename Trready
>
struct Axi4Lite {
    Taresetn        *aresetn;
    Taclk           *aclk   ;
    Tawaddr         *awaddr ;
    Tawprot         *awprot ;
    Tawvalid        *awvalid;
    Tawready        *awready;
    Twdata          *wdata  ;
    Twstrb          *wstrb  ;
    Twvalid         *wvalid ;
    Twready         *wready ;
    Tbresp          *bresp  ;
    Tbvalid         *bvalid ;
    Tbready         *bready ;
    Taraddr         *araddr ;
    Tarprot         *arprot ;
    Tarvalid        *arvalid;
    Tarready        *arready;
    Trdata          *rdata  ;
    Trresp          *rresp  ;
    Trvalid         *rvalid ;
    Trready         *rready ;
    
    Axi4Lite(){}
    Axi4Lite(
            Taresetn        *aresetn_,
            Taclk           *aclk_   ,
            Tawaddr         *awaddr_ ,
            Tawprot         *awprot_ ,
            Tawvalid        *awvalid_,
            Tawready        *awready_,
            Twdata          *wdata_  ,
            Twstrb          *wstrb_  ,
            Twvalid         *wvalid_ ,
            Twready         *wready_ ,
            Tbresp          *bresp_  ,
            Tbvalid         *bvalid_ ,
            Tbready         *bready_ ,
            Taraddr         *araddr_ ,
            Tarprot         *arprot_ ,
            Tarvalid        *arvalid_,
            Tarready        *arready_,
            Trdata          *rdata_  ,
            Trresp          *rresp_  ,
            Trvalid         *rvalid_ ,
            Trready         *rready_
        )
    {
        aresetn = aresetn_;
        aclk    = aclk_   ;
        awaddr  = awaddr_ ;
        awprot  = awprot_ ;
        awvalid = awvalid_;
        awready = awready_;
        wdata   = wdata_  ;
        wstrb   = wstrb_  ;
        wvalid  = wvalid_ ;
        wready  = wready_ ;
        bresp   = bresp_  ;
        bvalid  = bvalid_ ;
        bready  = bready_ ;
        araddr  = araddr_ ;
        arprot  = arprot_ ;
        arvalid = arvalid_;
        arready = arready_;
        rdata   = rdata_  ;
        rresp   = rresp_  ;
        rvalid  = rvalid_ ;
        rready  = rready_ ;
    }
};


}
}


// end of file
