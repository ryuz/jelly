// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __JELLY__HLS__BORDER__H__
#define __JELLY__HLS__BORDER__H__


namespace jelly {

enum BordeType {
    BORDER_CONSTANT = 0,
    BORDER_REPLICATE = 1,
    BORDER_REFLECT = 2,
//  BORDER_WRAP = 3,
    BORDER_REFLECT_101 = 4,
//  BORDER_TRANSPARENT = 5,
    BORDER_REFLECT101 = BORDER_REFLECT_101,
    BORDER_DEFAULT = BORDER_REFLECT_101,
//  BORDER_ISOLATED = 16,
};


class Border {
public:
    static int CalcOffset(int wnd_pos, int wnd_center, int pos, int size, BordeType type) {
        int new_pos = pos + (wnd_pos - wnd_center);
        switch ( type ) {
        case BORDER_REFLECT:
            if ( new_pos >= size ) { new_pos = size - (new_pos - (size-1)); }
            if ( new_pos  < 0 )    { new_pos = -new_pos - 1; }
            break;

        case BORDER_REFLECT_101:
            if ( new_pos >= size ) { new_pos = size - (new_pos - (size-2)); }
            if ( new_pos  < 0 )    { new_pos = -new_pos; }
            break;
        
        default:
            break;
        }

        // BORDER_REPLICATE
        if ( new_pos >= size ) { new_pos = size-1; }
        if ( new_pos  < 0 )    { new_pos = 0; }

        return wnd_center + (new_pos - pos);
    }

    static bool IsConstant(int wnd_pos, int wnd_center, int pos, int size, BordeType type) {
        int new_pos = pos + (wnd_pos - wnd_center);
        return (type == BORDER_CONSTANT) && (new_pos < 0 || new_pos >= size); 
    }
};

}

#endif // __JELLY__HLS__BORDER__H__


// end of file
