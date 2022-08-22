#![allow(dead_code)]

const CORE_ID_BUFFER_MANAGER: u32 = 0x527A0004;
const CORE_ID_BUFFER_ALLOCATOR: u32 = 0x527A0008;
const CORE_ID_DMA_STREAM_WRITE: u32 = 0x527A0110;
const CORE_ID_DMA_STREAM_READ: u32 = 0x527A0120;
const CORE_ID_DMA_FIFO: u32 = 0x527A0140;
const CORE_ID_VDMA_AXI4S_TO_AXI4: u32 = 0x527A1010;
const CORE_ID_VDMA_AXI4_TO_AXI4S: u32 = 0x527A1020;
const CORE_ID_VDMA_AXI4S_TO_AXI4S: u32 = 0x527A1040;

// DMA Stream write
const REG_DMA_WRITE_CORE_ID: usize = 0x00;
const REG_DMA_WRITE_CORE_VERSION: usize = 0x01;
const REG_DMA_WRITE_CORE_CONFIG: usize = 0x03;
const REG_DMA_WRITE_CTL_CONTROL: usize = 0x04;
const REG_DMA_WRITE_CTL_STATUS: usize = 0x05;
const REG_DMA_WRITE_CTL_INDEX: usize = 0x07;
const REG_DMA_WRITE_IRQ_ENABLE: usize = 0x08;
const REG_DMA_WRITE_IRQ_STATUS: usize = 0x09;
const REG_DMA_WRITE_IRQ_CLR: usize = 0x0a;
const REG_DMA_WRITE_IRQ_SET: usize = 0x0b;
const REG_DMA_WRITE_PARAM_AWADDR: usize = 0x10;
const REG_DMA_WRITE_PARAM_AWOFFSET: usize = 0x18;
const REG_DMA_WRITE_PARAM_AWLEN_MAX: usize = 0x1c;
const REG_DMA_WRITE_PARAM_AWLEN0: usize = 0x20;
const REG_DMA_WRITE_PARAM_AWLEN1: usize = 0x24;
const REG_DMA_WRITE_PARAM_AWSTEP1: usize = 0x25;
const REG_DMA_WRITE_PARAM_AWLEN2: usize = 0x28;
const REG_DMA_WRITE_PARAM_AWSTEP2: usize = 0x29;
const REG_DMA_WRITE_PARAM_AWLEN3: usize = 0x2c;
const REG_DMA_WRITE_PARAM_AWSTEP3: usize = 0x2d;
const REG_DMA_WRITE_PARAM_AWLEN4: usize = 0x30;
const REG_DMA_WRITE_PARAM_AWSTEP4: usize = 0x31;
const REG_DMA_WRITE_PARAM_AWLEN5: usize = 0x34;
const REG_DMA_WRITE_PARAM_AWSTEP5: usize = 0x35;
const REG_DMA_WRITE_PARAM_AWLEN6: usize = 0x38;
const REG_DMA_WRITE_PARAM_AWSTEP6: usize = 0x39;
const REG_DMA_WRITE_PARAM_AWLEN7: usize = 0x3c;
const REG_DMA_WRITE_PARAM_AWSTEP7: usize = 0x3d;
const REG_DMA_WRITE_PARAM_AWLEN8: usize = 0x30;
const REG_DMA_WRITE_PARAM_AWSTEP8: usize = 0x31;
const REG_DMA_WRITE_PARAM_AWLEN9: usize = 0x44;
const REG_DMA_WRITE_PARAM_AWSTEP9: usize = 0x45;
const REG_DMA_WRITE_WSKIP_EN: usize = 0x70;
const REG_DMA_WRITE_WDETECT_FIRST: usize = 0x72;
const REG_DMA_WRITE_WDETECT_LAST: usize = 0x73;
const REG_DMA_WRITE_WPADDING_EN: usize = 0x74;
const REG_DMA_WRITE_WPADDING_DATA: usize = 0x75;
const REG_DMA_WRITE_WPADDING_STRB: usize = 0x76;
const REG_DMA_WRITE_SHADOW_AWADDR: usize = 0x90;
const REG_DMA_WRITE_SHADOW_AWLEN_MAX: usize = 0x91;
const REG_DMA_WRITE_SHADOW_AWLEN0: usize = 0xa0;
const REG_DMA_WRITE_SHADOW_AWLEN1: usize = 0xa4;
const REG_DMA_WRITE_SHADOW_AWSTEP1: usize = 0xa5;
const REG_DMA_WRITE_SHADOW_AWLEN2: usize = 0xa8;
const REG_DMA_WRITE_SHADOW_AWSTEP2: usize = 0xa9;
const REG_DMA_WRITE_SHADOW_AWLEN3: usize = 0xac;
const REG_DMA_WRITE_SHADOW_AWSTEP3: usize = 0xad;
const REG_DMA_WRITE_SHADOW_AWLEN4: usize = 0xb0;
const REG_DMA_WRITE_SHADOW_AWSTEP4: usize = 0xb1;
const REG_DMA_WRITE_SHADOW_AWLEN5: usize = 0xb4;
const REG_DMA_WRITE_SHADOW_AWSTEP5: usize = 0xb5;
const REG_DMA_WRITE_SHADOW_AWLEN6: usize = 0xb8;
const REG_DMA_WRITE_SHADOW_AWSTEP6: usize = 0xb9;
const REG_DMA_WRITE_SHADOW_AWLEN7: usize = 0xbc;
const REG_DMA_WRITE_SHADOW_AWSTEP7: usize = 0xbd;
const REG_DMA_WRITE_SHADOW_AWLEN8: usize = 0xb0;
const REG_DMA_WRITE_SHADOW_AWSTEP8: usize = 0xb1;
const REG_DMA_WRITE_SHADOW_AWLEN9: usize = 0xc4;
const REG_DMA_WRITE_SHADOW_AWSTEP9: usize = 0xc5;

// DMA Stream read
const REG_DMA_READ_CORE_ID: usize = 0x00;
const REG_DMA_READ_CORE_VERSION: usize = 0x01;
const REG_DMA_READ_CORE_CONFIG: usize = 0x03;
const REG_DMA_READ_CTL_CONTROL: usize = 0x04;
const REG_DMA_READ_CTL_STATUS: usize = 0x05;
const REG_DMA_READ_CTL_INDEX: usize = 0x07;
const REG_DMA_READ_IRQ_ENABLE: usize = 0x08;
const REG_DMA_READ_IRQ_STATUS: usize = 0x09;
const REG_DMA_READ_IRQ_CLR: usize = 0x0a;
const REG_DMA_READ_IRQ_SET: usize = 0x0b;
const REG_DMA_READ_PARAM_ARADDR: usize = 0x10;
const REG_DMA_READ_PARAM_AROFFSET: usize = 0x18;
const REG_DMA_READ_PARAM_ARLEN_MAX: usize = 0x1c;
const REG_DMA_READ_PARAM_ARLEN0: usize = 0x20;
const REG_DMA_READ_PARAM_ARLEN1: usize = 0x24;
const REG_DMA_READ_PARAM_ARSTEP1: usize = 0x25;
const REG_DMA_READ_PARAM_ARLEN2: usize = 0x28;
const REG_DMA_READ_PARAM_ARSTEP2: usize = 0x29;
const REG_DMA_READ_PARAM_ARLEN3: usize = 0x2c;
const REG_DMA_READ_PARAM_ARSTEP3: usize = 0x2d;
const REG_DMA_READ_PARAM_ARLEN4: usize = 0x30;
const REG_DMA_READ_PARAM_ARSTEP4: usize = 0x31;
const REG_DMA_READ_PARAM_ARLEN5: usize = 0x34;
const REG_DMA_READ_PARAM_ARSTEP5: usize = 0x35;
const REG_DMA_READ_PARAM_ARLEN6: usize = 0x38;
const REG_DMA_READ_PARAM_ARSTEP6: usize = 0x39;
const REG_DMA_READ_PARAM_ARLEN7: usize = 0x3c;
const REG_DMA_READ_PARAM_ARSTEP7: usize = 0x3d;
const REG_DMA_READ_PARAM_ARLEN8: usize = 0x30;
const REG_DMA_READ_PARAM_ARSTEP8: usize = 0x31;
const REG_DMA_READ_PARAM_ARLEN9: usize = 0x44;
const REG_DMA_READ_PARAM_ARSTEP9: usize = 0x45;
const REG_DMA_READ_SHADOW_ARADDR: usize = 0x90;
const REG_DMA_READ_SHADOW_ARLEN_MAX: usize = 0x91;
const REG_DMA_READ_SHADOW_ARLEN0: usize = 0xa0;
const REG_DMA_READ_SHADOW_ARLEN1: usize = 0xa4;
const REG_DMA_READ_SHADOW_ARSTEP1: usize = 0xa5;
const REG_DMA_READ_SHADOW_ARLEN2: usize = 0xa8;
const REG_DMA_READ_SHADOW_ARSTEP2: usize = 0xa9;
const REG_DMA_READ_SHADOW_ARLEN3: usize = 0xac;
const REG_DMA_READ_SHADOW_ARSTEP3: usize = 0xad;
const REG_DMA_READ_SHADOW_ARLEN4: usize = 0xb0;
const REG_DMA_READ_SHADOW_ARSTEP4: usize = 0xb1;
const REG_DMA_READ_SHADOW_ARLEN5: usize = 0xb4;
const REG_DMA_READ_SHADOW_ARSTEP5: usize = 0xb5;
const REG_DMA_READ_SHADOW_ARLEN6: usize = 0xb8;
const REG_DMA_READ_SHADOW_ARSTEP6: usize = 0xb9;
const REG_DMA_READ_SHADOW_ARLEN7: usize = 0xbc;
const REG_DMA_READ_SHADOW_ARSTEP7: usize = 0xbd;
const REG_DMA_READ_SHADOW_ARLEN8: usize = 0xb0;
const REG_DMA_READ_SHADOW_ARSTEP8: usize = 0xb1;
const REG_DMA_READ_SHADOW_ARLEN9: usize = 0xc4;
const REG_DMA_READ_SHADOW_ARSTEP9: usize = 0xc5;

// DMA Video write
const REG_VDMA_WRITE_CORE_ID: usize = REG_DMA_WRITE_CORE_ID;
const REG_VDMA_WRITE_CORE_VERSION: usize = REG_DMA_WRITE_CORE_VERSION;
const REG_VDMA_WRITE_CORE_CONFIG: usize = REG_DMA_WRITE_CORE_CONFIG;
const REG_VDMA_WRITE_CTL_CONTROL: usize = REG_DMA_WRITE_CTL_CONTROL;
const REG_VDMA_WRITE_CTL_STATUS: usize = REG_DMA_WRITE_CTL_STATUS;
const REG_VDMA_WRITE_CTL_INDEX: usize = REG_DMA_WRITE_CTL_INDEX;
const REG_VDMA_WRITE_IRQ_ENABLE: usize = REG_DMA_WRITE_IRQ_ENABLE;
const REG_VDMA_WRITE_IRQ_STATUS: usize = REG_DMA_WRITE_IRQ_STATUS;
const REG_VDMA_WRITE_IRQ_CLR: usize = REG_DMA_WRITE_IRQ_CLR;
const REG_VDMA_WRITE_IRQ_SET: usize = REG_DMA_WRITE_IRQ_SET;
const REG_VDMA_WRITE_PARAM_ADDR: usize = REG_DMA_WRITE_PARAM_AWADDR;
const REG_VDMA_WRITE_PARAM_OFFSET: usize = REG_DMA_WRITE_PARAM_AWOFFSET;
const REG_VDMA_WRITE_PARAM_AWLEN_MAX: usize = REG_DMA_WRITE_PARAM_AWLEN_MAX;
const REG_VDMA_WRITE_PARAM_H_SIZE: usize = REG_DMA_WRITE_PARAM_AWLEN0;
const REG_VDMA_WRITE_PARAM_V_SIZE: usize = REG_DMA_WRITE_PARAM_AWLEN1;
const REG_VDMA_WRITE_PARAM_LINE_STEP: usize = REG_DMA_WRITE_PARAM_AWSTEP1;
const REG_VDMA_WRITE_PARAM_F_SIZE: usize = REG_DMA_WRITE_PARAM_AWLEN2;
const REG_VDMA_WRITE_PARAM_FRAME_STEP: usize = REG_DMA_WRITE_PARAM_AWSTEP2;
const REG_VDMA_WRITE_SKIP_EN: usize = REG_DMA_WRITE_WSKIP_EN;
const REG_VDMA_WRITE_DETECT_FIRST: usize = REG_DMA_WRITE_WDETECT_FIRST;
const REG_VDMA_WRITE_DETECT_LAST: usize = REG_DMA_WRITE_WDETECT_LAST;
const REG_VDMA_WRITE_PADDING_EN: usize = REG_DMA_WRITE_WPADDING_EN;
const REG_VDMA_WRITE_PADDING_DATA: usize = REG_DMA_WRITE_WPADDING_DATA;
const REG_VDMA_WRITE_PADDING_STRB: usize = REG_DMA_WRITE_WPADDING_STRB;
const REG_VDMA_WRITE_SHADOW_ADDR: usize = REG_DMA_WRITE_SHADOW_AWADDR;
const REG_VDMA_WRITE_SHADOW_AWLEN_MAX: usize = REG_DMA_WRITE_SHADOW_AWLEN_MAX;
const REG_VDMA_WRITE_SHADOW_H_SIZE: usize = REG_DMA_WRITE_SHADOW_AWLEN0;
const REG_VDMA_WRITE_SHADOW_V_SIZE: usize = REG_DMA_WRITE_SHADOW_AWLEN1;
const REG_VDMA_WRITE_SHADOW_LINE_STEP: usize = REG_DMA_WRITE_SHADOW_AWSTEP1;
const REG_VDMA_WRITE_SHADOW_F_SIZE: usize = REG_DMA_WRITE_SHADOW_AWLEN2;
const REG_VDMA_WRITE_SHADOW_FRAME_STEP: usize = REG_DMA_WRITE_SHADOW_AWSTEP2;

// DMA Video read
const REG_VDMA_READ_CORE_ID: usize = REG_DMA_READ_CORE_ID;
const REG_VDMA_READ_CORE_VERSION: usize = REG_DMA_READ_CORE_VERSION;
const REG_VDMA_READ_CORE_CONFIG: usize = REG_DMA_READ_CORE_CONFIG;
const REG_VDMA_READ_CTL_CONTROL: usize = REG_DMA_READ_CTL_CONTROL;
const REG_VDMA_READ_CTL_STATUS: usize = REG_DMA_READ_CTL_STATUS;
const REG_VDMA_READ_CTL_INDEX: usize = REG_DMA_READ_CTL_INDEX;
const REG_VDMA_READ_IRQ_ENABLE: usize = REG_DMA_READ_IRQ_ENABLE;
const REG_VDMA_READ_IRQ_STATUS: usize = REG_DMA_READ_IRQ_STATUS;
const REG_VDMA_READ_IRQ_CLR: usize = REG_DMA_READ_IRQ_CLR;
const REG_VDMA_READ_IRQ_SET: usize = REG_DMA_READ_IRQ_SET;
const REG_VDMA_READ_PARAM_ADDR: usize = REG_DMA_READ_PARAM_ARADDR;
const REG_VDMA_READ_PARAM_OFFSET: usize = REG_DMA_READ_PARAM_AROFFSET;
const REG_VDMA_READ_PARAM_ARLEN_MAX: usize = REG_DMA_READ_PARAM_ARLEN_MAX;
const REG_VDMA_READ_PARAM_H_SIZE: usize = REG_DMA_READ_PARAM_ARLEN0;
const REG_VDMA_READ_PARAM_V_SIZE: usize = REG_DMA_READ_PARAM_ARLEN1;
const REG_VDMA_READ_PARAM_LINE_STEP: usize = REG_DMA_READ_PARAM_ARSTEP1;
const REG_VDMA_READ_PARAM_F_SIZE: usize = REG_DMA_READ_PARAM_ARLEN2;
const REG_VDMA_READ_PARAM_FRAME_STEP: usize = REG_DMA_READ_PARAM_ARSTEP2;
const REG_VDMA_READ_SHADOW_ADDR: usize = REG_DMA_READ_SHADOW_ARADDR;
const REG_VDMA_READ_SHADOW_ARLEN_MAX: usize = REG_DMA_READ_SHADOW_ARLEN_MAX;
const REG_VDMA_READ_SHADOW_H_SIZE: usize = REG_DMA_READ_SHADOW_ARLEN0;
const REG_VDMA_READ_SHADOW_V_SIZE: usize = REG_DMA_READ_SHADOW_ARLEN1;
const REG_VDMA_READ_SHADOW_LINE_STEP: usize = REG_DMA_READ_SHADOW_ARSTEP1;
const REG_VDMA_READ_SHADOW_F_SIZE: usize = REG_DMA_READ_SHADOW_ARLEN2;
const REG_VDMA_READ_SHADOW_FRAME_STEP: usize = REG_DMA_READ_SHADOW_ARSTEP2;

// Video Write-DMA (legacy)
const REG_VIDEO_WDMA_CORE_ID: usize = 0x00;
const REG_VIDEO_WDMA_VERSION: usize = 0x01;
const REG_VIDEO_WDMA_CTL_CONTROL: usize = 0x04;
const REG_VIDEO_WDMA_CTL_STATUS: usize = 0x05;
const REG_VIDEO_WDMA_CTL_INDEX: usize = 0x07;
const REG_VIDEO_WDMA_PARAM_ADDR: usize = 0x08;
const REG_VIDEO_WDMA_PARAM_STRIDE: usize = 0x09;
const REG_VIDEO_WDMA_PARAM_WIDTH: usize = 0x0a;
const REG_VIDEO_WDMA_PARAM_HEIGHT: usize = 0x0b;
const REG_VIDEO_WDMA_PARAM_SIZE: usize = 0x0c;
const REG_VIDEO_WDMA_PARAM_AWLEN: usize = 0x0f;
const REG_VIDEO_WDMA_MONITOR_ADDR: usize = 0x10;
const REG_VIDEO_WDMA_MONITOR_STRIDE: usize = 0x11;
const REG_VIDEO_WDMA_MONITOR_WIDTH: usize = 0x12;
const REG_VIDEO_WDMA_MONITOR_HEIGHT: usize = 0x13;
const REG_VIDEO_WDMA_MONITOR_SIZE: usize = 0x14;
const REG_VIDEO_WDMA_MONITOR_AWLEN: usize = 0x17;

// Video Read-DMA (legacy)
const REG_VIDEO_RDMA_CORE_ID: usize = 0x00;
const REG_VIDEO_RDMA_CORE_VERSION: usize = 0x01;
const REG_VIDEO_RDMA_CTL_CONTROL: usize = 0x04;
const REG_VIDEO_RDMA_CTL_STATUS: usize = 0x05;
const REG_VIDEO_RDMA_CTL_INDEX: usize = 0x06;
const REG_VIDEO_RDMA_PARAM_ADDR: usize = 0x08;
const REG_VIDEO_RDMA_PARAM_STRIDE: usize = 0x09;
const REG_VIDEO_RDMA_PARAM_WIDTH: usize = 0x0a;
const REG_VIDEO_RDMA_PARAM_HEIGHT: usize = 0x0b;
const REG_VIDEO_RDMA_PARAM_SIZE: usize = 0x0c;
const REG_VIDEO_RDMA_PARAM_ARLEN: usize = 0x0f;
const REG_VIDEO_RDMA_MONITOR_ADDR: usize = 0x10;
const REG_VIDEO_RDMA_MONITOR_STRIDE: usize = 0x11;
const REG_VIDEO_RDMA_MONITOR_WIDTH: usize = 0x12;
const REG_VIDEO_RDMA_MONITOR_HEIGHT: usize = 0x13;
const REG_VIDEO_RDMA_MONITOR_SIZE: usize = 0x14;
const REG_VIDEO_RDMA_MONITOR_ARLEN: usize = 0x17;

use jelly_mem_access::*;

pub struct VideoDmaControl<T: MemAccess> {
    acc: T,

    pixel_size: i32,
    word_size: i32,
    auto_stop: bool,
    core_id: u32,
    busy: bool,
    auto_buf: bool,
    buf_addr: usize,
    width: i32,
    height: i32,
    frames: i32,
    line_step: i32,
    frame_step: i32,
    offset_x: i32,
    offset_y: i32,
    len_max: i32,
}

impl<T: MemAccess> VideoDmaControl<T> {
    pub fn new(acc: T, pixel_size: i32, word_size: i32) -> Result<Self, ()> {
        let core_id = unsafe { acc.read_reg32(0) };
        if core_id != CORE_ID_DMA_STREAM_WRITE
            && core_id != CORE_ID_DMA_STREAM_READ
            && core_id != CORE_ID_VDMA_AXI4S_TO_AXI4
            && core_id != CORE_ID_VDMA_AXI4_TO_AXI4S
        {
            //                println!("Unknown DMA core id : {}", core_id);
            return Err(());
        }

        Ok(Self {
            acc: acc,
            pixel_size: pixel_size,
            word_size: word_size,
            auto_stop: true,
            core_id: core_id,
            busy: false,
            auto_buf: false,
            buf_addr: 0,
            width: 0,
            height: 0,
            frames: 1,
            line_step: 0,
            frame_step: 0,
            offset_x: 0,
            offset_y: 0,
            len_max: 15,
        })
    }

    fn write_reg(&mut self, reg: usize, data: usize) {
        unsafe {
            self.acc.write_reg(reg, data);
        }
    }

    fn read_reg(&mut self, reg: usize) -> usize {
        unsafe { self.acc.read_reg(reg) }
    }

    pub fn set_auto_buffer(&mut self, enable: bool) {
        self.auto_buf = enable;
    }

    pub fn set_buffer_addr(&mut self, buf_addr: usize) {
        self.buf_addr = buf_addr;
    }

    pub fn set_image_size(&mut self, width: i32, height: i32, frames: i32) {
        self.width = width;
        self.height = height;
        self.frames = frames;
    }

    pub fn set_offset(&mut self, x: i32, y: i32) {
        self.offset_x = x;
        self.offset_y = y;
    }

    pub fn set_image_step(&mut self, line_step: i32, frame_step: i32) {
        self.line_step = line_step;
        self.frame_step = frame_step;
    }

    pub fn start(&mut self) -> bool {
        self.stop();
        self.start_dma(
            self.buf_addr,
            self.width,
            self.height,
            self.frames,
            self.line_step,
            self.frame_step,
            self.offset_x,
            self.offset_y,
            false,
            self.auto_buf,
        )
    }

    pub fn stop(&mut self) -> bool {
        self.stop_dma();
        self.wait_for_stop()
    }

    pub fn oneshot(
        &mut self,
        addr: usize,
        width: i32,
        height: i32,
        frames: i32,
        line_step: i32,
        frame_step: i32,
        offset_x: i32,
        offset_y: i32,
    ) -> bool {
        // 一度止める
        let old_busy = self.busy;
        self.stop();

        // ワンショット転送
        self.start_dma(
            addr, width, height, frames, line_step, frame_step, offset_x, offset_y, true, false,
        );

        // 完了待ち
        self.wait_for_stop();

        // 動いていたなら再開
        if old_busy {
            self.start();
        }

        return true;
    }

    pub fn start_oneshot(
        &mut self,
        addr: usize,
        width: i32,
        height: i32,
        frames: i32,
        line_step: i32,
        frame_step: i32,
        offset_x: i32,
        offset_y: i32,
    ) -> bool {
        // ワンショット開始
        self.stop();
        self.start_dma(
            addr, width, height, frames, line_step, frame_step, offset_x, offset_y, true, false,
        )
    }

    pub fn wait_for_stop(&mut self) -> bool {
        while self.is_busy_dma() {}
        return true;
    }

    fn start_dma(
        &mut self,
        addr: usize,
        width: i32,
        height: i32,
        frames: i32,
        line_step: i32,
        frame_step: i32,
        offset_x: i32,
        offset_y: i32,
        oneshot: bool,
        auto_buf: bool,
    ) -> bool {
        let line_step = if line_step <= 0 {
            width * self.pixel_size
        } else {
            line_step
        };
        let frame_step = if frame_step <= 0 {
            line_step * height
        } else {
            frame_step
        };

        let offset = offset_y * line_step + offset_x * self.pixel_size;

        let mut control = 0x03;
        if oneshot {
            control |= 0x04;
        }
        if auto_buf {
            control |= 0x08;
        }

        match self.core_id {
            CORE_ID_DMA_STREAM_WRITE => {
                // Write DMA
                self.write_reg(REG_VDMA_WRITE_PARAM_ADDR, addr as usize);
                self.write_reg(REG_VDMA_WRITE_PARAM_OFFSET, offset as usize);
                self.write_reg(REG_VDMA_WRITE_PARAM_AWLEN_MAX, self.len_max as usize);
                self.write_reg(REG_VDMA_WRITE_PARAM_LINE_STEP, line_step as usize);
                self.write_reg(
                    REG_VDMA_WRITE_PARAM_H_SIZE,
                    ((width * self.pixel_size / self.word_size) - 1) as usize,
                );
                self.write_reg(REG_VDMA_WRITE_PARAM_V_SIZE, (height - 1) as usize);
                self.write_reg(REG_VDMA_WRITE_PARAM_FRAME_STEP, frame_step as usize);
                self.write_reg(REG_VDMA_WRITE_PARAM_F_SIZE, (frames - 1) as usize);
                self.write_reg(REG_VDMA_WRITE_CTL_CONTROL, control as usize);
            }

            CORE_ID_DMA_STREAM_READ => {
                // Read DMA
                self.write_reg(REG_VDMA_READ_PARAM_ADDR, addr as usize);
                self.write_reg(REG_VDMA_READ_PARAM_OFFSET, offset as usize);
                self.write_reg(REG_VDMA_READ_PARAM_ARLEN_MAX, self.len_max as usize);
                self.write_reg(REG_VDMA_READ_PARAM_LINE_STEP, line_step as usize);
                self.write_reg(
                    REG_VDMA_READ_PARAM_H_SIZE,
                    ((width * self.pixel_size / self.word_size) - 1) as usize,
                );
                self.write_reg(REG_VDMA_READ_PARAM_V_SIZE, (height - 1) as usize);
                self.write_reg(REG_VDMA_READ_PARAM_FRAME_STEP, frame_step as usize);
                self.write_reg(REG_VDMA_READ_PARAM_F_SIZE, (frames - 1) as usize);
                self.write_reg(REG_VDMA_READ_CTL_CONTROL, control as usize);
            }

            CORE_ID_VDMA_AXI4S_TO_AXI4 => {
                // 旧Write DMA
                self.write_reg(REG_VIDEO_WDMA_PARAM_ADDR, addr + offset as usize);
                self.write_reg(REG_VIDEO_WDMA_PARAM_STRIDE, line_step as usize);
                self.write_reg(REG_VIDEO_WDMA_PARAM_WIDTH, width as usize);
                self.write_reg(REG_VIDEO_WDMA_PARAM_HEIGHT, height as usize);
                self.write_reg(
                    REG_VIDEO_WDMA_PARAM_SIZE,
                    (width * height * frames) as usize,
                );
                self.write_reg(REG_VIDEO_WDMA_PARAM_AWLEN, self.len_max as usize);
                self.write_reg(REG_VIDEO_WDMA_CTL_CONTROL, control as usize);
            }

            CORE_ID_VDMA_AXI4_TO_AXI4S => {
                // 旧Read DMA
                self.write_reg(REG_VIDEO_RDMA_PARAM_ADDR, addr + offset as usize);
                self.write_reg(REG_VIDEO_RDMA_PARAM_STRIDE, line_step as usize);
                self.write_reg(REG_VIDEO_RDMA_PARAM_WIDTH, width as usize);
                self.write_reg(REG_VIDEO_RDMA_PARAM_HEIGHT, height as usize);
                self.write_reg(
                    REG_VIDEO_RDMA_PARAM_SIZE,
                    (width * height * frames) as usize,
                );
                self.write_reg(REG_VIDEO_RDMA_PARAM_ARLEN, self.len_max as usize);
                self.write_reg(REG_VIDEO_RDMA_CTL_CONTROL, control as usize);
            }

            _ => {
                //                println!("Unknown DMA core id : " << self.core_id);
            }
        }

        self.busy = true;

        return true;
    }

    fn stop_dma(&mut self) -> bool {
        match self.core_id {
            CORE_ID_DMA_STREAM_WRITE => {
                // Write DMA
                self.write_reg(REG_VDMA_WRITE_CTL_CONTROL, 0);
            }

            CORE_ID_DMA_STREAM_READ => {
                // Read DMA
                self.write_reg(REG_VDMA_READ_CTL_CONTROL, 0);
            }

            CORE_ID_VDMA_AXI4S_TO_AXI4 => {
                // 旧Write DMA
                self.write_reg(REG_VIDEO_WDMA_CTL_CONTROL, 0);
            }

            CORE_ID_VDMA_AXI4_TO_AXI4S => {
                // 旧Read DMA
                self.write_reg(REG_VIDEO_RDMA_CTL_CONTROL, 0);
            }

            _ => {
                return false;
            }
        }

        return true;
    }

    fn is_busy_dma(&mut self) -> bool {
        match self.core_id {
            CORE_ID_DMA_STREAM_WRITE => {
                // Write DMA
                self.busy = self.read_reg(REG_VDMA_WRITE_CTL_STATUS) != 0;
            }

            CORE_ID_DMA_STREAM_READ => {
                // Read DMA
                self.busy = self.read_reg(REG_VDMA_READ_CTL_STATUS) != 0;
            }

            CORE_ID_VDMA_AXI4S_TO_AXI4 => {
                // 旧Write DMA
                self.busy = self.read_reg(REG_VIDEO_WDMA_CTL_STATUS) != 0;
            }

            CORE_ID_VDMA_AXI4_TO_AXI4S => {
                // 旧Read DMA
                self.busy = self.read_reg(REG_VIDEO_RDMA_CTL_STATUS) != 0;
            }

            _ => {
                return false;
            }
        }

        return self.busy;
    }
}
