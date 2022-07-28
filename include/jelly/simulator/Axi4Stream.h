


#pragma once

namespace jelly {
namespace simulator {

#include <cstdint>


struct Axi4StreamData {
    std::uint64_t   tid;
    std::uint64_t   tuser;
    std::uint8_t    tlast;
    std::uint64_t   tdata;
    std::uint8_t    tstrb;
    std::uint8_t    tkeep;
    std::uint64_t   tdest;
    std::uint8_t    tvalid;

    Axi4StreamData(){}
    Axi4StreamData(
                    std::uint64_t   tdata_,
                    std::uint8_t    tlast_=0,
                    std::uint64_t   tuser_=0,
                    std::uint8_t    tvalid_=1,
                    std::uint64_t   tid_=0,
                    std::uint8_t    tstrb_=0xff,
                    std::uint8_t    tkeep_=0xff,
                    std::uint64_t   tdest_=0
                )
    {
        tid    = tid_;
        tuser  = tuser_;
        tlast  = tlast_;
        tdata  = tdata_;
        tstrb  = tstrb_;
        tkeep  = tkeep_;
        tdest  = tdest_;
        tvalid = tvalid_;
    }
};

template<typename Tareset, typename Taclk, typename Ttid, typename Ttuser, typename Ttlast, typename Ttdata, typename Ttstrb, typename Ttkeep, typename Ttdest, typename Ttvalid, typename Ttready>
struct Axi4Stream {
    Tareset *aresetn;
    Taclk   *aclk;
    Ttid    *tid;
    Ttuser  *tuser;
    Ttlast  *tlast;
    Ttdata  *tdata;
    Ttstrb  *tstrb;
    Ttstrb  *tkeep;
    Ttdest  *tdest;
    Ttvalid *tvalid;
    Ttready *tready;

    Axi4Stream(){}
    Axi4Stream(
            Tareset *aresetn_,
            Taclk   *aclk_,
            Ttid    *tid_,
            Ttuser  *tuser_,
            Ttlast  *tlast_,
            Ttdata  *tdata_,
            Ttstrb  *tstrb_,
            Ttkeep  *tkeep_,
            Ttdest  *tdest_,
            Ttvalid *tvalid_,
            Ttready *tready_) {
        aresetn = aresetn_;
        aclk  = aclk_;
        tid   = tid_;
        tuser = tuser_;
        tlast = tlast_;
        tdata = tdata_;
        tstrb = tstrb_;
        tkeep = tkeep_;
        tdest = tdest_;
        tvalid = tvalid_;
        tready = tready_;
    }

    void Set(const Axi4StreamData& data) {
        if ( tid    ) { *tid    = (Ttid  )data.tid  ; }
        if ( tuser  ) { *tuser  = (Ttuser)data.tuser; }
        if ( tlast  ) { *tlast  = (Ttlast)data.tlast; }
        if ( tdata  ) { *tdata  = (Ttdata)data.tdata; }
        if ( tstrb  ) { *tstrb  = (Ttstrb)data.tstrb; }
        if ( tkeep  ) { *tkeep  = (Ttkeep)data.tkeep; }
        if ( tdest  ) { *tdest  = (Ttdest)data.tdest; }
        *tvalid = (Ttvalid)data.tvalid;
    }

    bool Get(Axi4StreamData& data) {
        if ( *tvalid == 0 ) { return false; }
        if ( tid    ) { data.tid   = (std::uint64_t)*tid  ; }
        if ( tuser  ) { data.tuser = (std::uint64_t)*tuser; }
        if ( tlast  ) { data.tlast = (std::uint8_t )*tlast; }
        if ( tdata  ) { data.tdata = (std::uint64_t)*tdata; }
        if ( tstrb  ) { data.tstrb = (std::uint8_t )*tstrb; }
        if ( tkeep  ) { data.tkeep = (std::uint8_t )*tkeep; }
        if ( tdest  ) { data.tdest = (std::uint64_t)*tdest; }
        data.tvalid = (std::uint8_t)*tvalid;
        return true;
    }
};


class Axi4StreamWrite : public Node {
public:
    virtual std::size_t GetSize(void) = 0;
    virtual void        Write(const Axi4StreamData& data) = 0;
};

class Axi4StreamRead : public Node {
public:
    virtual std::size_t GetSize(void) = 0;
    virtual bool        Read(Axi4StreamData& data) = 0;
};



}
}


// end of file
