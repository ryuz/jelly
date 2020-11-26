// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include <opencv2/opencv.hpp>

#include "jelly/JellyRegs.h"
#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"

using namespace jelly;


int main()
{
    std::cout << "--- udmabuf test ---" << std::endl;

    // mmap udmabuf
    std::cout << "\nudmabuf4 open" << std::endl;
    UdmabufAccessor udmabuf_acc("udmabuf4");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf4 mmap error" << std::endl;
        return 1;
    }
    auto dmabuf_addr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_size = udmabuf_acc.GetSize();

    std::cout << "udmabuf4 phys addr : 0x" << std::hex << dmabuf_addr << std::endl;
    std::cout << "udmabuf4 size      : 0x" << std::hex << dmabuf_size << std::endl;

    auto img = cv::imread("Penguins.jpg");
    cv::resize(img, img, cv::Size(1920, 1080));
    cv::Mat imgView;
    cv::cvtColor(img, imgView, cv::COLOR_BGR2RGB);
//  udmabuf_acc.MemCopyFrom(0, img.data, 1920*1080*3);
    for ( int i = 0; i < 1920*1080; ++i ) {
        udmabuf_acc.WriteMem8(3*i+2, img.data[3*i+0]);
        udmabuf_acc.WriteMem8(3*i+0, img.data[3*i+1]);
        udmabuf_acc.WriteMem8(3*i+1, img.data[3*i+2]);
    }

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto reg_vdmar = uio_acc.GetAccessor(0x00008000);
    auto reg_vsgen = uio_acc.GetAccessor(0x00010000);


    // レジスタ番号でアクセス
    std::cout << "\n<test RegRead>" << std::endl;
    std::cout << "vdmar_acc : " << std::hex << reg_vdmar.ReadReg(0) << std::endl;
    std::cout << "vsgen_acc : " << std::hex << reg_vsgen.ReadReg(0) << std::endl;
    
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_CTL_CONTROL, 0);
    usleep(1000000);

    // VSync Start
    /*
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HTOTAL,      1650);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HDISP_START,    0);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HDISP_END,   1280);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_START, 1390);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_END,   1430);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VTOTAL,       750);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VDISP_START,    0);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VDISP_END,    720);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_START,  725);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_END,    730);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_POL,      1);
    */

    // DMA start
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_ADDR,       dmabuf_addr);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_OFFSET,     0);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_LINE_STEP,  1920*3);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_H_SIZE,     1920-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_V_SIZE,     1080-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_FRAME_STEP, 1920*3*1080);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_F_SIZE,     1-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_ARLEN_MAX,  64-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_CTL_CONTROL,      0x03);

    usleep(100000);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_CTL_CONTROL, 1);

    cv::imshow("img", img);
    cv::waitKey();
    
    reg_vdmar.WriteReg(REG_VDMA_READ_CTL_CONTROL, 0x00);
    while ( reg_vdmar.ReadReg(REG_VDMA_READ_CTL_STATUS) != 0 ) {
        usleep(100);
    }    

    return 0;
}

// end of file
