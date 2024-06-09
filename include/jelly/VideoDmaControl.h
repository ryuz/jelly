// --------------------------------------------------------------------------
//  Jelly DMA control
//
//                                     Copyright (C) 2020 by Ryuji Fuchikami
// --------------------------------------------------------------------------


#ifndef __JELLY__VEDEO_DMA_CONTORL__H__
#define __JELLY__VEDEO_DMA_CONTORL__H__


#include <iostream>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <unistd.h>

#include "MemAccessor.h"
#include "JellyRegs.h"


namespace jelly {


class VideoDmaControl
{
protected:
    MemAccessor     m_acc;
    int             m_pixel_size;
    int             m_word_size;
    bool            m_auto_stop  = true;

    std::uintptr_t  m_core_id;
    bool            m_busy       = false;

    bool            m_auto_buf   = false;
    std::uintptr_t  m_buf_addr   = 0;
    int             m_width      = 0;
    int             m_height     = 0;
    int             m_frames     = 1; 
    int             m_line_step  = 0;
    int             m_frame_step = 0;
    int             m_offset_x   = 0;
    int             m_offset_y   = 0;
    int             m_len_max    = 15;

    void           WriteReg(int reg, std::uintptr_t data) { m_acc.WriteReg(reg, data); }
    std::uintptr_t ReadReg(int reg) { return m_acc.ReadReg(reg); }

public:
    VideoDmaControl(MemAccessor acc, int pixel_size, int word_size, bool auto_stop = true)
    {
        m_acc        = acc;
        m_pixel_size = pixel_size;
        m_word_size  = word_size;
        m_auto_stop  = auto_stop;
        m_core_id    = ReadReg(0);
        if ( m_core_id != CORE_ID_DMA_STREAM_WRITE
                && m_core_id != CORE_ID_DMA_STREAM_READ
                && m_core_id != CORE_ID_VDMA_AXI4S_TO_AXI4
                && m_core_id != CORE_ID_VDMA_AXI4_TO_AXI4S ) {
            std::cerr << "Unknown DMA core id : " << m_core_id << std::endl;
        }
    }

    ~VideoDmaControl()
    {
        if ( m_auto_stop ) {
            Stop();
        }
    }

    void SetAutoBuffer(bool enable)
    {
        m_auto_buf = enable;
    }
    
    void SetBufferAddr(std::uintptr_t buf_addr)
    {
        m_buf_addr = buf_addr;
    }

    void SetImageSize(int width, int height, int frames=1)
    {
        m_width  = width;
        m_height = height;
        m_frames = frames;
    }

    void SetOffset(int x, int y)
    {
        m_offset_x = x;
        m_offset_y = y;
    }

    void SetImageStep(int line_step, int frame_step=0)
    {
        m_line_step  = line_step;
        m_frame_step = frame_step;
    }

    bool Start(void)
    {
        Stop();
        return StartDma(m_buf_addr, m_width, m_height, m_frames, m_line_step, m_frame_step, m_offset_x, m_offset_y, false, m_auto_buf);
    }

    bool Stop(int timeout=1000)
    {
        StopDma();
        return WaitForStop(timeout);
    }

    bool Oneshot(std::uintptr_t addr, int width, int height, int frames=1, int line_step=0, int frame_step=0, int offset_x=0, int offset_y=0, int timeout=0)
    {
        // 一度止める
        auto old_busy = m_busy;
        Stop();

        // ワンショット転送
        StartDma(addr, width, height, frames, line_step, frame_step, offset_x, offset_y, true, false);
        
        // 完了待ち
        if ( timeout == 0 ) { timeout = 1000*frames; } 
        if ( !WaitForStop(timeout) ) {
            std::cerr << "DMA stop timeout" << std::endl;
            return false;
        }

        // 動いていたなら再開
        if ( old_busy) {
            Start();
        }
        
        return true;
    }

    bool StartOneshot(std::uintptr_t addr, int width, int height, int frames=1, int line_step=0, int frame_step=0, int offset_x=0, int offset_y=0)
    {
        // ワンショット開始
        Stop();
        return StartDma(addr, width, height, frames, line_step, frame_step, offset_x, offset_y, true, false);
    }

    bool WaitForStop(int timeout=-1)
    {
        int i = 0;
        while ( IsBusyDma() ) {
            if ( timeout >= 0 && i >= timeout ) {
                return false;   // timeout
            }
            usleep(1000);
            i++;
        }
        return true;
    }

protected:

    bool StartDma(std::uintptr_t addr, int width, int height, int frames=1, int line_step=0, int frame_step=0, int offset_x=0, int offset_y=0, bool oneshot=false, bool auto_buf=false)
    {
        if ( line_step <= 0 ) {
            line_step = width * m_pixel_size;
        }
        if ( frame_step <= 0 ) {
            frame_step = line_step * height;
        }
        
        std::uintptr_t offset = offset_y * line_step + offset_x * m_pixel_size;

        int control = 0x03;
        if ( oneshot )  { control |= 0x04; }
        if ( auto_buf ) { control |= 0x08; }

        switch ( m_core_id ) {
        case CORE_ID_DMA_STREAM_WRITE:      // Write DMA
            WriteReg(REG_VDMA_WRITE_PARAM_ADDR,       addr);
            WriteReg(REG_VDMA_WRITE_PARAM_OFFSET,     offset);
            WriteReg(REG_VDMA_WRITE_PARAM_AWLEN_MAX,  m_len_max);
            WriteReg(REG_VDMA_WRITE_PARAM_LINE_STEP,  line_step);
            WriteReg(REG_VDMA_WRITE_PARAM_H_SIZE,     (width*m_pixel_size/m_word_size)-1);
            WriteReg(REG_VDMA_WRITE_PARAM_V_SIZE,     height-1);
            WriteReg(REG_VDMA_WRITE_PARAM_FRAME_STEP, frame_step);
            WriteReg(REG_VDMA_WRITE_PARAM_F_SIZE,     frames-1);
            WriteReg(REG_VDMA_WRITE_CTL_CONTROL,      control);
            break;

        case CORE_ID_DMA_STREAM_READ:      // Read DMA
            WriteReg(REG_VDMA_READ_PARAM_ADDR,       addr);
            WriteReg(REG_VDMA_READ_PARAM_OFFSET,     offset);
            WriteReg(REG_VDMA_READ_PARAM_ARLEN_MAX,  m_len_max);
            WriteReg(REG_VDMA_READ_PARAM_LINE_STEP,  line_step);
            WriteReg(REG_VDMA_READ_PARAM_H_SIZE,     (width*m_pixel_size/m_word_size)-1);
            WriteReg(REG_VDMA_READ_PARAM_V_SIZE,     height-1);
            WriteReg(REG_VDMA_READ_PARAM_FRAME_STEP, frame_step);
            WriteReg(REG_VDMA_READ_PARAM_F_SIZE,     frames-1);
            WriteReg(REG_VDMA_READ_CTL_CONTROL,      control);
            break;
        
        case CORE_ID_VDMA_AXI4S_TO_AXI4:    // 旧Write DMA
            WriteReg(REG_VIDEO_WDMA_PARAM_ADDR,   addr + offset);
            WriteReg(REG_VIDEO_WDMA_PARAM_STRIDE, line_step);
            WriteReg(REG_VIDEO_WDMA_PARAM_WIDTH,  width);
            WriteReg(REG_VIDEO_WDMA_PARAM_HEIGHT, height);
            WriteReg(REG_VIDEO_WDMA_PARAM_SIZE,   width*height*frames);
            WriteReg(REG_VIDEO_WDMA_PARAM_AWLEN,  m_len_max);
            WriteReg(REG_VIDEO_WDMA_CTL_CONTROL,  control);
            break;

        case CORE_ID_VDMA_AXI4_TO_AXI4S:   // 旧Read DMA
            WriteReg(REG_VIDEO_RDMA_PARAM_ADDR,   addr + offset);
            WriteReg(REG_VIDEO_RDMA_PARAM_STRIDE, line_step);
            WriteReg(REG_VIDEO_RDMA_PARAM_WIDTH,  width);
            WriteReg(REG_VIDEO_RDMA_PARAM_HEIGHT, height);
            WriteReg(REG_VIDEO_RDMA_PARAM_SIZE,   width*height*frames);
            WriteReg(REG_VIDEO_RDMA_PARAM_ARLEN,  m_len_max);
            WriteReg(REG_VIDEO_RDMA_CTL_CONTROL,  control);
            break;

        default:
            std::cerr << "Unknown DMA core id : " << m_core_id << std::endl;
            return false;
        }

        m_busy = true;

        return true;
    }

    bool StopDma(void)
    {
        switch ( m_core_id ) {
        case CORE_ID_DMA_STREAM_WRITE:      // Write DMA
            WriteReg(REG_VDMA_WRITE_CTL_CONTROL, 0);
            break;

        case CORE_ID_DMA_STREAM_READ:      // Read DMA
            WriteReg(REG_VDMA_READ_CTL_CONTROL,  0);
            break;
        
        case CORE_ID_VDMA_AXI4S_TO_AXI4:    // 旧Write DMA
            WriteReg(REG_VIDEO_WDMA_CTL_CONTROL, 0);
            break;

        case CORE_ID_VDMA_AXI4_TO_AXI4S:   // 旧Read DMA
            WriteReg(REG_VIDEO_RDMA_CTL_CONTROL, 0);
            break;

        default:
            return false;
        }

        return true;
    }

    bool IsBusyDma(void)
    {
        switch ( m_core_id ) {
        case CORE_ID_DMA_STREAM_WRITE:      // Write DMA
            m_busy = (ReadReg(REG_VDMA_WRITE_CTL_STATUS) != 0);
            break;

        case CORE_ID_DMA_STREAM_READ:       // Read DMA
            m_busy = (ReadReg(REG_VDMA_READ_CTL_STATUS) != 0);
            break;

        case CORE_ID_VDMA_AXI4S_TO_AXI4:    // 旧Write DMA
            m_busy = (ReadReg(REG_VIDEO_WDMA_CTL_STATUS) != 0);
            break;

        case CORE_ID_VDMA_AXI4_TO_AXI4S:    // 旧Read DMA
            m_busy = (ReadReg(REG_VIDEO_RDMA_CTL_STATUS) != 0);
            break;

        default:
            return false;
        }

        return m_busy;
    }
};

}

#endif  // __JELLY__VEDEO_DMA_CONTORL__H__


// end of file
