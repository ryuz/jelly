

#include <assert.h>
#include "video_filter.h"


ap_uint<PIXEL_BITS> make_pattern(int x, int y) {
    ap_uint<PIXEL_BITS> pix;
    pix.range( 7,  0) = x;
    pix.range(15,  8) = y;
    pix.range(23, 16) = x+y;
    return pix;
}

int main()
{
    hls::stream<axi4s_t> s_axi4s;
    hls::stream<axi4s_t> m_axi4s;

    width_t  width  = 16; // 200;
    height_t height = 8;  // 32;

    int pix = 0;
    for( int y = 0; y < height; ++y ) {
        for( int x = 0; x < width; ++x ){
            axi4s_t axi4s;
            axi4s.user = (x == 0 && y == 0) ? 1 : 0;
            axi4s.last = (x == (width-1));
            axi4s.data = make_pattern(x, y);
//          std::cout << std::hex << axi4s.data << std::endl;
            s_axi4s << axi4s;
        }
    }

    video_filter(s_axi4s, m_axi4s, width, height, false);

    pix = 0;
    for( int y = 0; y < height; ++y ) {
        for( int x = 0; x < width; ++x ){
            axi4s_t axi4s;
            m_axi4s >> axi4s;
//          std::cout << std::hex << axi4s.data  << "  exp:" << make_pattern(x, y) << std::endl;
            assert(axi4s.data == make_pattern(x, y));
            pix++;
        }
    }

    return 0;
}
