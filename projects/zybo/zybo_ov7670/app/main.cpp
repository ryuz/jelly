#include <iostream>
#include <iomanip>
#include <ios>
#include <cstdint>

#include <opencv2/opencv.hpp>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/JellyRegs.h"
#include "jelly/VideoDmaControl.h"


void capture_still_image(jelly::MemAccessor& reg_wdma, std::uintptr_t bufaddr, int width, int height, int frame_num);


int main(int argc, char *argv[])
{
    int width  = 640;
    int height = 480;


    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

//    auto reg_fmtr  = uio_acc.GetAccessor(0x00010000);
//    auto reg_prmup = uio_acc.GetAccessor(0x00011000);
//    auto reg_rgb   = uio_acc.GetAccessor(0x00012000);
    auto reg_wdma  = uio_acc.GetAccessor(0x00021000);

    
    // mmap udmabuf
    jelly::UdmabufAccessor udmabuf_acc("udmabuf4");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf4 mmap error" << std::endl;
        return 1;
    }

    auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_mem_size = udmabuf_acc.GetSize();
//  std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
//  std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;

    jelly::VideoDmaControl vdmaw(reg_wdma, 2, 2, true);


    int     rec_frame_num = std::min(100, (int)(dmabuf_mem_size / (width * height * 2)));
    int     frame_num     = 1;

    if ( rec_frame_num <= 0 ) {
        std::cout << "udmabuf size error" << std::endl;
    }

    int     key;
    while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
        // キャプチャ
        vdmaw.Oneshot(dmabuf_phys_adr, width, height, 1);
//      capture_still_image(reg_wdma, dmabuf_phys_adr, width, height, 1);
        cv::Mat img(height*frame_num, width, CV_16U);
        udmabuf_acc.MemCopyTo(img.data, 0, width * height * 2 * 1);
        
        // 表示
//        cv::Mat view_img;
//        cv::resize(img, view_img, cv::Size(), 0.5, 1.0/view_scale);

        cv::Mat view_img;
        cv::cvtColor(img, view_img, CV_RGB5652RGB);

        cv::imshow("img", view_img);
//        cv::createTrackbar("scale",    "img", &view_scale, 4);
//        cv::createTrackbar("fps",      "img", &frame_rate, 1000);
//        cv::createTrackbar("exposure", "img", &exposure, 1000);
//        cv::createTrackbar("a_gain",   "img", &a_gain, 20);
//        cv::createTrackbar("d_gain",   "img", &d_gain, 24);
//        cv::createTrackbar("bayer" ,   "img", &bayer_phase, 3);

        // ユーザー操作
        switch ( key ) {
        case 'd':   // image dump
            {
                cv::Mat imgRgb;
                cv::cvtColor(img, imgRgb, CV_BGRA2BGR);
                cv::imwrite("img_dump.png", imgRgb);
            }
            break;

        case 'r': // image record
            std::cout << "record" << std::endl;
            vdmaw.Oneshot(dmabuf_phys_adr, width, height, rec_frame_num);
//         capture_still_image(reg_wdma, dmabuf_phys_adr, width, height, rec_frame_num);
            int offset = 0;
            for ( int i = 0; i < rec_frame_num; i++ ) {
                char fname[64];
                sprintf(fname, "rec_%04d.png", i);
                cv::Mat imgRec(height, width, CV_8UC4);
                udmabuf_acc.MemCopyTo(imgRec.data, offset, width * height * 4);
                offset += width * height * 4;
                cv::Mat imgRgb;
                cv::cvtColor(imgRec, imgRgb, CV_BGRA2BGR);
                cv::imwrite(fname, imgRgb);
            }
            break;
        }
    }
    
    return 0;
}



// 静止画キャプチャ
void capture_still_image(jelly::MemAccessor& reg_wdma,
//jelly::MemAccessor& reg_fmtr,
std::uintptr_t bufaddr, int width, int height, int frame_num)
{
    // DMA start (one shot)
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_ADDR,   bufaddr);
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_STRIDE, width*4);
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_WIDTH,  width);
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_HEIGHT, height);
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_SIZE,   width*height*frame_num);
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_AWLEN,  31);
    reg_wdma.WriteReg(REG_VIDEO_WDMA_CTL_CONTROL,  0x07);
    
    /*
    // video format regularizer
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,        0x000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03);
    usleep(100000);
    */
    
    // 取り込み完了を待つ
    usleep(10000);
    while ( reg_wdma.ReadReg(REG_VIDEO_WDMA_CTL_STATUS) != 0 ) {
        usleep(10000);
    }
    
    // normalizer stop
//    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00);
//    usleep(1000);
//    while ( reg_wdma.ReadReg(REG_VIDEO_FMTREG_CTL_STATUS) != 0 ) {
//        usleep(1000);
//    }
}


// end of file