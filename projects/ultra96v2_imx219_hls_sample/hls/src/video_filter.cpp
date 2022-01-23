
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

    bool wait_frame_start = true;
    height_t y = 0;
    width_t  x = 0;
    axi4s_t axi4s;
    do { 
        #pragma HLS PIPELINE
        s_axi4s >> axi4s;
        if ( wait_frame_start && axi4s.user == 0 ) {
            continue;
        }
        wait_frame_start = false;

        if ( inverse ) {
            axi4s.data = ~axi4s.data;
        }
        m_axi4s << axi4s;

        x++;
        if ( axi4s.last ) {
            x = 0;
            y++;
        }
    } while ( y < height );
}

