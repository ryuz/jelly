

#include <assert.h>
#include "laplacian_filter.h"


pixel_t make_pattern(int x, int y) {
    pixel_t pix;
    pix.range( 7,  0) = (x & 0xff);
    pix.range(15,  8) = (y & 0xff);
    pix.range(23, 16) = ((x+y) & 0xff);
    return pix;
}

int main()
{
    hls::stream<axi4s_t> s_axi4s;
    hls::stream<axi4s_t> m_axi4s;

    width_t  width  = 640;
    height_t height = 480;

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

    laplacian_filter(s_axi4s, m_axi4s, width, height, false);

    for( int y = 0; y < height; ++y ) {
        for( int x = 0; x < width; ++x ){
            axi4s_t axi4s;
            m_axi4s >> axi4s;
//          std::cout << std::dec << "(" << x << ", " << y << ") : " << std::hex << axi4s.data  << "  exp:" << make_pattern(x, y) << std::endl;
            assert(axi4s.data == make_pattern(x, y));
        }
    }

    return 0;
}
