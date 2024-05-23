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
#include "jelly/VideoDmaControl.h"


#define DP_MAIN_STREAM_HTOTAL               0x00000180
#define DP_MAIN_STREAM_VTOTAL               0x00000184
#define DP_MAIN_STREAM_POLARITY             0x00000188
#define DP_MAIN_STREAM_HSWIDTH              0x0000018C
#define DP_MAIN_STREAM_VSWIDTH              0x00000190
#define DP_MAIN_STREAM_HRES                 0x00000194
#define DP_MAIN_STREAM_VRES                 0x00000198
#define DP_MAIN_STREAM_HSTART               0x0000019C
#define DP_MAIN_STREAM_VSTART               0x000001A0

#define V_BLEND_SET_GLOBAL_ALPHA_REG        0x0000A00C
#define AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT    0x0000B070
#define AV_BUF_AUD_VID_CLK_SOURCE           0x0000B120



int main(int argc, char *argv[])
{
    std::cout << "--- Display Port ---" << std::endl;

    // mmap udmabuf
    std::cout << "\nudmabuf open" << std::endl;
    jelly::UdmabufAccessor udmabuf_acc("udmabuf-jelly-vram0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf mmap error" << std::endl;
        return 1;
    }
    auto dmabuf_addr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_size = udmabuf_acc.GetSize();

    std::cout << "udmabuf phys addr : 0x" << std::hex << dmabuf_addr << std::endl;
    std::cout << "udmabuf size      : 0x" << std::hex << dmabuf_size << std::endl;

    cv::Mat img;
    if ( argc >= 2 ) {
        img = cv::imread(argv[1]);
    }

    if ( img.empty() ) {
        img = cv::Mat::zeros(360, 640, CV_8UC3);
        cv::rectangle(img, cv::Rect(0, 0, 640, 360), cv::Scalar(255, 255, 255), -1);
        cv::circle(img, cv::Point(320, 180), 80, cv::Scalar(0, 0, 255), -1);
        cv::putText(img, "Copyright (C) 2020 by Ryuji Fuchikami", cv::Point(0, 320), cv::FONT_HERSHEY_PLAIN, 2, cv::Scalar(0, 0, 0), 1, cv::LINE_AA);
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

    // DMA設定
    jelly::VideoDmaControl  vdmar(reg_vdmar, 3, 3, true);

    // DisplayPort 設定
    std::cout << "\nuio DP open" << std::endl;
    jelly::UioAccessor reg_dp("uio_dp", 0x000010000);
    if ( !reg_dp.IsMapped() ) {
        std::cout << "uio_dp mmap error" << std::endl;
        return 1;
    }
    auto old_dp_avsel = reg_dp.ReadMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT);
    auto old_dp_alpha = reg_dp.ReadMem32(V_BLEND_SET_GLOBAL_ALPHA_REG);
    reg_dp.WriteMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT, 0x54);
    reg_dp.WriteMem32(V_BLEND_SET_GLOBAL_ALPHA_REG,     0x101);

    int dp_polarity = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_POLARITY);
    int dp_hswidth  = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HSWIDTH);
    int dp_vswidth  = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VSWIDTH);
    int dp_hres     = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HRES);
    int dp_vres     = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VRES);
    int dp_hstart   = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HSTART);
    int dp_vstart   = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VSTART);

    int h_start = dp_hstart-dp_hswidth-17;
    int v_start = dp_vstart-dp_vswidth-1;

    // 画像書き込み
    cv::Mat imgView;
    cv::resize(img, imgView, cv::Size(dp_hres, dp_vres));
    udmabuf_acc.MemCopyFrom(0, imgView.data, dp_hres*dp_vres*3);


    // DMA start
    vdmar.SetBufferAddr(dmabuf_addr);
    vdmar.SetImageSize(dp_hres, dp_vres);
    vdmar.Start();

#if 1
    // VSync adjust de
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSIZE,  dp_hres-1);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSIZE,  dp_vres-1);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSTART, v_start);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSTART, dp_vstart-1);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HPOL,   (dp_polarity & 1) ? 1 : 0);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VPOL,   (dp_polarity & 2) ? 1 : 0);
#else
    // VSync Start
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
#endif


    cv::imshow("img", img);
    while ( cv::waitKey(10) != 0x1b ) {
        cv::createTrackbar("h", "img", &h_start, 200);
        cv::createTrackbar("v", "img", &v_start, 100);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSTART, h_start);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSTART, v_start);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_CTL_CONTROL, 3);
    }

    vdmar.Stop();
    
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_CTL_CONTROL, 2);

    // DisplayPortを元に戻す
    reg_dp.WriteMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT, old_dp_avsel);
    reg_dp.WriteMem32(V_BLEND_SET_GLOBAL_ALPHA_REG,     old_dp_alpha);

    return 0;
}


// end of file
