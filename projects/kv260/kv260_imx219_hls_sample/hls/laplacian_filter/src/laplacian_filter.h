


#include <ap_int.h>
#include <hls_stream.h>
#include <ap_axi_sdata.h>
//#include "common/xf_common.h"
//#include "common/xf_video_mem.h"


#define PIXEL_BITS      24

using pixel_t  = ap_int<PIXEL_BITS>;
using axi4s_t  = ap_axis<PIXEL_BITS, 1, 1, 1>;
using width_t  = ap_uint<16>;
using height_t = ap_uint<16>;

void laplacian_filter(
        hls::stream<axi4s_t>& s_axi4s,
        hls::stream<axi4s_t>& m_axi4s,
        width_t width,
        height_t height,
        bool inverse);

