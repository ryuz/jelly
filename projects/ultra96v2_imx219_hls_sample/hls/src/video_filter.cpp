

#include "jelly/hls/WindowFilter.h"
#include "video_filter.h"


struct rgb_t {
    ap_uint<8>  val[3];
};

using VideoFilter = jelly::WindowFilter<rgb_t, 3, 3, 1, 1, 2048, 4096>;
using window_t    = VideoFilter::Window;

rgb_t pixel_to_rgb(pixel_t pix)
{
    rgb_t rgb;
    rgb.val[0] = pix.range(7, 0);
    rgb.val[1] = pix.range(15, 8);
    rgb.val[2] = pix.range(23, 16);
    return rgb;
}

pixel_t rgb_to_pixel(rgb_t rgb)
{
    pixel_t pix;
    pix.range( 7,  0) = rgb.val[0];
    pix.range(15,  8) = rgb.val[1];
    pix.range(23, 16) = rgb.val[2];
    return pix;
}


void video_filter_in(
        hls::stream<axi4s_t>&   s_axi4s,
        hls::stream<rgb_t>&     m_stream,
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
            m_stream << pixel_to_rgb(axi4s.data);
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
            rgb_t rgb;
            if ( enable ) {
                for ( int c = 0; c < 3; ++c ) {
                    #pragma HLS unroll
                    rgb.val[c] = ((window.val[0][0].val[c]
                                    + window.val[0][1].val[c]
                                    + window.val[0][2].val[c]
                                    + window.val[1][0].val[c]
                                    + window.val[1][2].val[c]
                                    + window.val[2][0].val[c]
                                    + window.val[2][1].val[c]
                                    + window.val[2][2].val[c]) >> 3);
                }
            }
            else {
                rgb = window.val[1][1];
            }

            axi4s_t axi4s;
            axi4s.data = rgb_to_pixel(rgb);
            axi4s.user = (x == 0 && y == 0);
            axi4s.last = (x == (width-1));
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

    static hls::stream< rgb_t >     stream_in("stream_in");
    static hls::stream< window_t >  stream_out("stream_out");

    #pragma HLS dataflow
    int tmp_width = width;
    int tmp_height = height;
    video_filter_in(s_axi4s, stream_in, width, height);
    VideoFilter::Streaming(stream_in, stream_out, tmp_height, tmp_width);
    video_filter_out(stream_out, m_axi4s, width, height, enable);
}

