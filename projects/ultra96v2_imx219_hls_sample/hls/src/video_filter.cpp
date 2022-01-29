
#include "video_filter.h"


void video_filter(
        hls::stream<axi4s_t>& s_axi4s,
        hls::stream<axi4s_t>& m_axi4s,
        width_t width,
        height_t height,
        bool inverse
    )
{
#pragma HLS INTERFACE axis port=s_axi4s
#pragma HLS INTERFACE axis port=m_axi4s

    axi4s_t axi4s;

    // wait for frame start
    do {
        s_axi4s >> axi4s;
    } while ( axi4s.user == 0 );

    // filter
    for ( height_t y = 0; y < height; ++y ) {
        for ( width_t x = 0; x < width; ++x ) {
            #pragma HLS pipeline II=1

            if ( inverse ) {
                axi4s.data = ~axi4s.data;
            }
            m_axi4s << axi4s;

//            x++;
//            if ( axi4s.last ) {
//                x = 0;
 //               y++;
 //           }

            s_axi4s >> axi4s;
        }
    }
}

