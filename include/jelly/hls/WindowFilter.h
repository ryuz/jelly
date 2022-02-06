// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __JELLY__HLS__WINDOW_FILTER__H__
#define __JELLY__HLS__WINDOW_FILTER__H__

#include <hls_stream.h>

#include "jelly/hls/Matrix.h"
#include "jelly/hls/ColumnBuffer.h"

#include "common/xf_common.h"
#include "common/xf_video_mem.h"

namespace jelly {


// ウィンドウィング
template<typename T, int WINDOW_ROWS, int WINDOW_COLS, int CENTER_ROW, int CENTER_COL, int MAX_ROWS=2048, int MAX_COLS=4096>
class WindowFilter {

protected:
    using ColBuf    = ColumnBuffer<T, WINDOW_ROWS, MAX_COLS>;
    using WindowRow = Matrix<T, WINDOW_ROWS, 1>;

    static const int  DELAY_V = WINDOW_ROWS - CENTER_ROW - 1;
    static const int  DELAY_H = WINDOW_COLS - CENTER_COL - 1;

public:
    using Window = Matrix<T, WINDOW_ROWS, WINDOW_COLS>;
    
    static void Streaming(
            hls::stream<T>&         in_stream,
            hls::stream<Window>&    out_stream,
            int                     rows,
            int                     cols)
    {
        hls::stream<WindowRow>   stream_buf("stream_buf");

        #pragma HLS dataflow
        BufferingCol(in_stream, stream_buf, rows, cols);
        BufferingRow(stream_buf, out_stream, rows, cols);
    }

protected:

#if 0
    // 垂直バッファリング
    static void BufferingCol(
            hls::stream<T>&             stream_in,
            hls::stream<WindowRow>&     stream_out,
            int                         rows,
            int                         cols)
    {
        ColBuf  buf;

        // 先に先行する行の分貯める
        for ( int i = 0; i < DELAY_V; ++i ) {
            for ( int j = 0; j < cols; ++j ) {
                #pragma HLS pipeline II=1
                T val = stream_in.read();
                buf.ShiftUp(j, val);
            }
        }

        // 全体処理
        for ( int i = 0; i < rows; ++i ) {
            for ( int j = 0; j < cols; ++j ) {
                #pragma HLS pipeline II=1
                T val = 0;
                if ( i < (rows - DELAY_V) ) {
                    val = stream_in.read();
                }
                auto window = buf.ShiftUp(j, val);
                stream_out.write(window);
            }
        }
    }

#else

    // 垂直バッファリング
    static void BufferingCol(
            hls::stream<T>&             stream_in,
            hls::stream<WindowRow>&     stream_out,
            int                         rows,
            int                         cols)
    {
        xf::LineBuffer<WINDOW_ROWS-1, MAX_COLS, T> linebuf;

        // 先に先行ライン分貯める
        for ( int i = 0; i < DELAY_V; ++i ) {
            for ( int x = 0; x < cols; ++x ) {
                #pragma HLS pipeline II=1
                T val = stream_in.read();
                linebuf.shift_pixels_up(x);
                linebuf.insert_bottom_row(val, x);
            }
        }

        // ライン処理
        for ( int y = 0; y < rows; ++y ) {
            for ( int x = 0; x < cols; ++x ) {
                #pragma HLS pipeline II=1
                T val;
                if ( y < (rows - DELAY_V) ) {
                    val = stream_in.read();
                }

                WindowRow window;
                for ( int i = 0; i < WINDOW_ROWS-1; ++i ) {
                    #pragma HLS unroll
                    window.val[i][0] = linebuf.getval(i, x);
                }
                window.val[WINDOW_ROWS-1][0] = val;

                linebuf.shift_pixels_up(x);
                linebuf.insert_bottom_row(val, x);
                stream_out << window;
            }
        }
    }
#endif

    // 水平バッファリング
    static void BufferingRow(
            hls::stream<WindowRow>&     stream_in,
            hls::stream<Window>&        stream_out,
            int                         rows,
            int                         cols)
    {

        // 全体処理
        for ( int i = 0; i < rows; ++i ) {
            Window  window;

            // 先に先行する列の分貯める
            for ( int j = 0; j < DELAY_H; ++j ) {
                #pragma HLS pipeline II=1
                window.ShiftLeft(stream_in.read());
            }

            for ( int j = 0; j < cols; ++j ) {
                #pragma HLS pipeline II=1
                WindowRow new_row;
                if ( j < (cols - DELAY_H) ) {
                    new_row = stream_in.read();
                }
                window.ShiftLeft(new_row);
                stream_out.write(window);
            }
        }
    }
};


}


#endif  // __JELLY__HLS__WINDOW_FILTER__H__


// end of file