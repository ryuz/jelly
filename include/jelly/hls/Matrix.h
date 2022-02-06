// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __JELLY__HLS__MATRIX__H__
#define __JELLY__HLS__MATRIX__H__


#include <assert.h>

namespace jelly {


template<typename T, int ROWS, int COLS>
class Matrix {
public:
    Matrix() {
        #pragma HLS array_partition variable=m_val complete dim=0
    }

    void ShiftLeft(Matrix<T, ROWS, 1> new_row)
    {
        #pragma HLS inline
        for ( int j = 0; j < COLS-1; ++j ) {
            #pragma HLS unroll
            for ( int i = 0; i < ROWS; ++i ) {
                #pragma HLS unroll
                m_val[i][j] = m_val[i][j+1];
            }
        }
        for ( int i = 0; i < ROWS; ++i ) {
            #pragma HLS unroll
            m_val[i][COLS-1] = new_row.at(i, 0);
        }
    }

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
    
private:
    T  m_val[ROWS][COLS];
};


}


#endif  // __JELLY__HLS__MATRIX__H__


// end of file
