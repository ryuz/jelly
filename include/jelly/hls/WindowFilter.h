// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __JELLY__HLS__WINDOW_FILTER__H__
#define __JELLY__HLS__WINDOW_FILTER__H__

#include <hls_stream.h>

#include "jelly/hls/Matrix.h"
#include "jelly/hls/ColumnBuffer.h"
#include "jelly/hls/Border.h"


namespace jelly {


// ウィンドウィング
template<typename T, int WINDOW_ROWS, int WINDOW_COLS, int CENTER_ROW, int CENTER_COL, int MAX_ROWS=2048, int MAX_COLS=4096, bool BORDER=true>
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
            int                     cols,
            BordeType               border_type=BORDER_REFLECT_101,
            T                       border_value=0
        )
    {
        hls::stream<WindowRow>   stream_buf("stream_buf");

        #pragma HLS dataflow
        BufferingCol(in_stream, stream_buf, rows, cols, border_type, border_value);
        BufferingRow(stream_buf, out_stream, rows, cols, border_type, border_value);
    }

protected:
    // 垂直バッファリング
    static void BufferingCol(
            hls::stream<T>&         stream_in,
            hls::stream<WindowRow>& stream_out,
            int                     rows,
            int                     cols,
            BordeType               border_type=BORDER_REFLECT_101,
            T                       border_value=0
        )
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
                T val;
                if ( i < (rows - DELAY_V) ) {
                    val = stream_in.read();
                }
                auto window = buf.ShiftUp(j, val);

                // ボーダー処理
                if ( BORDER ) {
                    for ( int k = 0; k < WINDOW_ROWS; ++k ) {
                        #pragma HLS unroll
                        if ( Border::IsConstant(k, CENTER_ROW, i, rows, border_type) ) {
                            window.val[k][0] = border_value;
                        }
                        else {
                            int p = Border::CalcOffset(k, CENTER_ROW, i, rows, border_type);
                            window.val[k][0] = window.val[p][0];
                           }
                    }
                }

                stream_out.write(window);
            }
        }
    }

    // 水平バッファリング
    static void BufferingRow(
            hls::stream<WindowRow>& stream_in,
            hls::stream<Window>&    stream_out,
            int                     rows,
            int                     cols,
            BordeType               border_type=BORDER_REFLECT_101,
            T                       border_value=0
        )
    {

        // 全体処理
        for ( int i = 0; i < rows; ++i ) {
            Window      window;
            WindowRow   new_row;

            // 先に先行する列の分貯める
            for ( int j = 0; j < DELAY_H; ++j ) {
                #pragma HLS pipeline II=1
                new_row = stream_in.read();
                window.ShiftLeft(new_row);
            }

            for ( int j = 0; j < cols; ++j ) {
                #pragma HLS pipeline II=1
                
                if ( j < (cols - DELAY_H) ) {
                    new_row = stream_in.read();
                }
                window.ShiftLeft(new_row);

                // ボーダー処理
                if ( BORDER ) {
                    for ( int l = 0; l < WINDOW_COLS; ++l ) {
                        #pragma HLS unroll
                        if ( Border::IsConstant(l, CENTER_COL, j, cols, border_type) ) {
                            for ( int k = 0; k < WINDOW_ROWS; ++k ) {
                                #pragma HLS unroll
                                window.val[k][l] = border_value;
                            }
                        }
                        else {
                            int p = Border::CalcOffset(l, CENTER_COL, j, cols, border_type);
                            for ( int k = 0; k < WINDOW_ROWS; ++k ) {
                                #pragma HLS unroll
                                window.val[k][l] = window.val[k][p];
                            }
                        }
                    }
                }

                stream_out.write(window);
            }
        }
    }
};


}


#endif  // __JELLY__HLS__WINDOW_FILTER__H__


// end of file
