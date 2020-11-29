// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuz
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include <opencv2/opencv.hpp>

#include "jelly/JellyRegs.h"
#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"

//using namespace jelly;


#define AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT    0x0000B070
#define V_BLEND_SET_GLOBAL_ALPHA_REG        0x0000A00C
#define AV_BUF_AUD_VID_CLK_SOURCE           0x0000B120

int main()
{
    std::cout << "--- Display Port ---" << std::endl;

    // mmap udmabuf
    std::cout << "\nudmabuf4 open" << std::endl;
    jelly::UdmabufAccessor udmabuf_acc("udmabuf4");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf4 mmap error" << std::endl;
        return 1;
    }
    auto dmabuf_addr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_size = udmabuf_acc.GetSize();

    std::cout << "udmabuf4 phys addr : 0x" << std::hex << dmabuf_addr << std::endl;
    std::cout << "udmabuf4 size      : 0x" << std::hex << dmabuf_size << std::endl;

    auto img = cv::imread("test.jpg");
    cv::Mat imgView;
    cv::resize(img, imgView, cv::Size(1920, 1080));
//  cv::cvtColor(img, imgView, cv::COLOR_BGR2RGB);
//  udmabuf_acc.MemCopyFrom(0, img.data, 1920*1080*3);
    for ( int i = 0; i < 1920*1080; ++i ) {
        udmabuf_acc.WriteMem8(3*i+2, imgView.data[3*i+0]);
        udmabuf_acc.WriteMem8(3*i+0, imgView.data[3*i+1]);
        udmabuf_acc.WriteMem8(3*i+1, imgView.data[3*i+2]);
    }
    
    // mmap uio
    std::cout << "\nuio open" << std::endl;
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto reg_vdmar = uio_acc.GetAccessor(0x00008000);
    auto reg_vsgen = uio_acc.GetAccessor(0x00010000);


    // DisplayPort 設定
    std::cout << "\nuio DP open" << std::endl;
    jelly::UioAccessor reg_dp("uio_dp", 0x000010000);
    if ( !reg_dp.IsMapped() ) {
        std::cout << "uio_dp mmap error" << std::endl;
        return 1;
    }
    std::cout << "AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT : 0x" << std::hex << reg_dp.ReadMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT) << std::endl;
    std::cout << "V_BLEND_SET_GLOBAL_ALPHA_REG     : 0x" << std::hex << reg_dp.ReadMem32(V_BLEND_SET_GLOBAL_ALPHA_REG) << std::endl;
    std::cout << "AV_BUF_AUD_VID_CLK_SOURCE        : 0x" << std::hex << reg_dp.ReadMem32(AV_BUF_AUD_VID_CLK_SOURCE) << std::endl;
//  auto old_dp_avclk = reg_dp.ReadMem32(AV_BUF_AUD_VID_CLK_SOURCE);
    auto old_dp_avsel = reg_dp.ReadMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT);
    auto old_dp_alpha = reg_dp.ReadMem32(V_BLEND_SET_GLOBAL_ALPHA_REG);
//   reg_dp.WriteMem32(AV_BUF_AUD_VID_CLK_SOURCE,        0x00);
    reg_dp.WriteMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT, 0x54);
    reg_dp.WriteMem32(V_BLEND_SET_GLOBAL_ALPHA_REG,     0xff);


    // レジスタ番号でアクセス
    std::cout << "\n<test RegRead>" << std::endl;
    std::cout << "vdmar_acc : " << std::hex << reg_vdmar.ReadReg(0) << std::endl;
    std::cout << "vsgen_acc : " << std::hex << reg_vsgen.ReadReg(0) << std::endl;

    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_CTL_CONTROL, 0);
    usleep(1000000);


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
    
    // VSync Start
    /*
    usleep(100000);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HTOTAL,      2200);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HDISP_START,    0);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HDISP_END,   1920);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_START, 2008);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_END,   2052);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VTOTAL,      1125);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VDISP_START,   0);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VDISP_END,   1080);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_START, 1084);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_END,   1089);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_CTL_CONTROL,          1);
    */

    int h_start = 131;
    int v_start = 35;
    cv::imshow("img", img);
    while ( cv::waitKey(10) != 0x1b ) {
        cv::createTrackbar("h", "img", &h_start, 200);
        cv::createTrackbar("v", "img", &v_start, 100);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSTART, h_start);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSTART, v_start);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_CTL_CONTROL, 3);
    }
    
    reg_vdmar.WriteReg(REG_VDMA_READ_CTL_CONTROL, 0x00);
    while ( reg_vdmar.ReadReg(REG_VDMA_READ_CTL_STATUS) != 0 ) {
        usleep(100);
    }    

    // 元に戻す
//    reg_dp.WriteMem32(AV_BUF_AUD_VID_CLK_SOURCE,        old_dp_avclk);
    reg_dp.WriteMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT, old_dp_avsel);
    reg_dp.WriteMem32(V_BLEND_SET_GLOBAL_ALPHA_REG,     old_dp_alpha);

    return 0;
}

// end of file
