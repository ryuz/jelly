

#include <assert.h>
#include "video_filter.h"

int main()
{
    hls::stream<axi4s_t> s_axi4s;
    hls::stream<axi4s_t> m_axi4s;

    width_t  width  = 640;
    height_t height = 32;

    int pix = 0;
    for( int y = 0; y < height; ++y ) {
        for( int x = 0; x < width; ++x ){
            axi4s_t axi4s;
            axi4s.user = (x == 0 && y == 0) ? 1 : 0;
            axi4s.last = (x == (width-1));
            axi4s.data = pix++;
            s_axi4s << axi4s;
        }
    }

    video_filter(s_axi4s, m_axi4s, width, height, true);

    pix = 0;
    for( int y = 0; y < height; ++y ) {
        for( int x = 0; x < width; ++x ){
            axi4s_t axi4s;
            m_axi4s >> axi4s;
            assert( axi4s.data == ~pix );
            pix++;
        }
    }

    return 0;
}
