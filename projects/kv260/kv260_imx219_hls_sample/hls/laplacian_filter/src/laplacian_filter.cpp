

#include "jelly/hls/WindowFilter.h"
#include "laplacian_filter.h"


using LaplacianFilter = jelly::WindowFilter<pixel_t, 3, 3, 1, 1, 2048, 4096>;
using window_t        = LaplacianFilter::Window;


struct rgb_t {
    ap_uint<8>  val[3];
};

rgb_t pixel_to_rgb(pixel_t pix)
{
    #pragma HLS inline
    rgb_t rgb;
    rgb.val[0] = pix.range(7, 0);
    rgb.val[1] = pix.range(15, 8);
    rgb.val[2] = pix.range(23, 16);
    return rgb;
}

pixel_t rgb_to_pixel(rgb_t rgb)
{
    #pragma HLS inline
    pixel_t pix;
    pix.range( 7,  0) = rgb.val[0];
    pix.range(15,  8) = rgb.val[1];
    pix.range(23, 16) = rgb.val[2];
    return pix;
}


void laplacian_filter_in(
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


void laplacian_filter_out(
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

            pixel_t pix;
            if ( enable ) {
                for ( int c = 0; c < 3; ++c ) {
                    #pragma HLS unroll
                    // Laplacian Filter
                    int val =   (int)window.val[0][0].range(8*c+7, 8*c)
                              + (int)window.val[0][1].range(8*c+7, 8*c)
                              + (int)window.val[0][2].range(8*c+7, 8*c)
                              + (int)window.val[1][0].range(8*c+7, 8*c)
                              + (int)window.val[1][2].range(8*c+7, 8*c)
                              + (int)window.val[2][0].range(8*c+7, 8*c)
                              + (int)window.val[2][1].range(8*c+7, 8*c)
                              + (int)window.val[2][2].range(8*c+7, 8*c)
                              - ((int)window.val[1][1].range(8*c+7, 8*c) << 3);
                    if ( val <   0 ) { val = 0; }
                    if ( val > 255 ) { val = 255; }
                    pix.range(8*c+7, 8*c) = val;
                }
            }
            else {
                // bypass
                pix = window.val[1][1];
            }
            
            axi4s_t axi4s;
            axi4s.data = pix;
            axi4s.user = (x == 0 && y == 0);
            axi4s.last = (x == (width-1));
            m_axi4s << axi4s;
        }
    }
}


void laplacian_filter(
        hls::stream<axi4s_t>& s_axi4s,
        hls::stream<axi4s_t>& m_axi4s,
        width_t width,
        height_t height,
        bool enable
    )
{
    #pragma HLS INTERFACE axis port=s_axi4s
    #pragma HLS INTERFACE axis port=m_axi4s

    static hls::stream<pixel_t>     stream_in("stream_in");
    static hls::stream<window_t>    stream_out("stream_out");

    #pragma HLS dataflow
    int tmp_width = width;
    int tmp_height = height;
    laplacian_filter_in(s_axi4s, stream_in, width, height);
    LaplacianFilter::Streaming(stream_in, stream_out, tmp_height, tmp_width); //, BORDER_REFLECT_101, rgb_t());
    laplacian_filter_out(stream_out, m_axi4s, width, height, enable);
}

