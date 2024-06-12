// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __JELLY__HLS__MATRIX__H__
#define __JELLY__HLS__MATRIX__H__


#include <assert.h>

namespace jelly {


template<typename T, int ROWS, int COLS>
struct Matrix {
    Matrix() {
        #pragma HLS array_partition variable=val complete dim=0
    }

    void ShiftLeft(Matrix<T, ROWS, 1> new_row)
    {
        #pragma HLS inline
        for ( int j = 0; j < COLS-1; ++j ) {
            #pragma HLS unroll
            for ( int i = 0; i < ROWS; ++i ) {
                #pragma HLS unroll
                val[i][j] = val[i][j+1];
            }
        }
        for ( int i = 0; i < ROWS; ++i ) {
            #pragma HLS unroll
            val[i][COLS-1] = new_row.val[i][0];
        }
    }

    /*
    T& at(int i, int j)
    {
        #pragma HLS inline
        assert(i >= 0 && i < ROWS);
        assert(j >= 0 && j < COLS);
        return m_val[i][j];
    }

    const T& at(int i, int j) const
    {
        #pragma HLS inline
        assert(i >= 0 && i < ROWS);
        assert(j >= 0 && j < COLS);
        return m_val[i][j];
    }
    */
    
    T  val[ROWS][COLS];
};


}


#endif  // __JELLY__HLS__MATRIX__H__


// end of file
