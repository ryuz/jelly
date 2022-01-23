

#include <ap_int.h>
#include <hls_stream.h>
#include <ap_axi_sdata.h>

using axi4s_t = ap_axis<24, 1, 1, 1>;
using width_t = ap_uint<16>;
using height_t = ap_uint<16>;

void video_filter(
        hls::stream<axi4s_t>& s_axi4s,
        hls::stream<axi4s_t>& m_axi4s,
        width_t width,
        height_t height,
        bool inverse);

