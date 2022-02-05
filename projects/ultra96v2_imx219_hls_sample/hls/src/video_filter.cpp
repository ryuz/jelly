

#include "jelly/hls/WindowFilter.h"
#include "video_filter.h"


using pixel_t     = ap_uint<PIXEL_BITS>;
using VideoFilter = jelly::WindowFilter<pixel_t, 3, 3, 1, 1, 2048, 4096>;
using window_t    = VideoFilter::Window;


void video_filter_in(
        hls::stream<axi4s_t>&   s_axi4s,
        hls::stream<pixel_t>&   m_stream,
        width_t                 width,
        height_t                height)
{
    axi4s_t axi4s;

    // wait for frame start
    do {
        s_axi4s >> axi4s;
    } while ( axi4s.user == 0 );

    for ( height_t y = 0; y < height; ++y ) {
        for ( width_t x = 0; x < width; ++x ) {
            #pragma HLS pipeline II=1
            if ( !(x == 0 && y == 0) ) {
                s_axi4s >> axi4s;
            }
            m_stream << axi4s.data;
        }
    }
}


void video_filter_out(
        hls::stream<window_t>&  s_stream,
        hls::stream<axi4s_t>&   m_axi4s,
        width_t                 width,
        height_t                height,
        bool                    enable)
{
    for ( height_t y = 0; y < height; ++y ) {
        for ( width_t x = 0; x < width; ++x ) {
            #pragma HLS pipeline II=1

            window_t window;
            s_stream >> window;
            axi4s_t axi4s;
            axi4s.user = (x == 0 && y == 0);
            axi4s.last = (x == (width-1));
            if ( enable ) {
                for ( int c = 0; c < 3; ++c ) {
                    #pragma HLS unroll
                    int val = window.val[0][0].range(c*8+7, c*8+7)
                            + window.val[0][1].range(c*8+7, c*8+7)
                            + window.val[0][2].range(c*8+7, c*8+7)
                            + window.val[1][0].range(c*8+7, c*8+7)
                            + window.val[1][2].range(c*8+7, c*8+7)
                            + window.val[2][0].range(c*8+7, c*8+7)
                            + window.val[2][1].range(c*8+7, c*8+7)
                            + window.val[2][2].range(c*8+7, c*8+7);
                    axi4s.data.range(c*8+7, c*8+7) = (val >> 3);
                }
            }
            else {
                axi4s.data = window.val[1][1];
            }
            m_axi4s << axi4s;
        }
    }
}


void video_filter(
        hls::stream<axi4s_t>& s_axi4s,
        hls::stream<axi4s_t>& m_axi4s,
        width_t width,
        height_t height,
        bool enable
    )
{
    #pragma HLS INTERFACE axis port=s_axi4s
    #pragma HLS INTERFACE axis port=m_axi4s

    static hls::stream< pixel_t >   stream_in("stream_in");
    static hls::stream< window_t >  stream_out("stream_out");

    #pragma HLS dataflow
    video_filter_in(s_axi4s, stream_in, width, height);
    VideoFilter::Streaming(stream_in, stream_out, height, width);
    video_filter_out(stream_out, m_axi4s, width, height, enable);
}

