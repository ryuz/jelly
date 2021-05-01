


#pragma once

namespace jelly {
namespace simulator {


#include <opencv2/opencv.hpp>

inline const int fmt_8uc3  = CV_8UC3;
inline const int fmt_8uc1  = CV_8UC1;
inline const int fmt_gray  = CV_8UC1;
inline const int fmt_color = CV_8UC3;


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
