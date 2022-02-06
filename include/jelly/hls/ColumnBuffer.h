// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __JELLY__HLS__COLUMN_BUFFER__H__
#define __JELLY__HLS__COLUMN_BUFFER__H__


#include "jelly/hls/Matrix.h"


namespace jelly {


// 行バッファ(ラインバッファ)
template<typename T, int ROWS, int COLS>
class ColumnBuffer {
public:
    using Window = Matrix<T, ROWS, 1>;

    ColumnBuffer() {
        #pragma HLS dependence variable=m_buffer inter false
        #pragma HLS dependence variable=m_buffer intra false
        #pragma HLS RESOURCE variable=m_buffer core=RAM_S2P_BRAM
        #pragma HLS ARRAY_PARTITION variable=m_buffer complete dim=1
    }

    Window ShiftUp(int col, T new_val) {
        #pragma HLS inline
        Window window;
        for ( int i = 0; i < ROWS-1; ++i ) {
            #pragma HLS unroll
            window.val[i][0] = m_buffer[i][col];
        }
        window.val[ROWS-1][0] = new_val;

        for ( int i = 0; i < ROWS-2; ++i ) {
            #pragma HLS unroll
            m_buffer[i][col] = m_buffer[i+1][col];
        }
        m_buffer[ROWS-2][col] = new_val;
        
        return window;
    }

protected:
    T   m_buffer[ROWS-1][COLS];
};


}


#endif  // __JELLY__HLS__COLUMN_BUFFER__H__


// end of file
