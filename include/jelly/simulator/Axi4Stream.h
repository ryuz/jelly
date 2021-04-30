


#pragma once

namespace jelly {
namespace simulator {


template<typename Tareset, typename Taclk, typename Ttuser, typename Ttlast, typename Ttdata, typename Ttvalid, typename Ttready>
struct Axi4sVideo {
    Tareset *aresetn;
    Taclk   *aclk;
    Ttuser  *tuser;
    Ttlast  *tlast;
    Ttdata  *tdata;
    Ttvalid *tvalid;
    Ttready *tready;

    Axi4sVideo(){}
    Axi4sVideo(
            Tareset *aresetn_,
            Taclk   *aclk_,
            Ttuser  *tuser_,
            Ttlast  *tlast_,
            Ttdata  *tdata_,
            Ttvalid *tvalid_,
            Ttready *tready_) {
        aresetn = aresetn_;
        aclk = aclk_;
        tuser = tuser_;
        tlast = tlast_;
        tdata = tdata_;
        tvalid = tvalid_;
        tready = tready_;
    }
};


}
}


// end of file
