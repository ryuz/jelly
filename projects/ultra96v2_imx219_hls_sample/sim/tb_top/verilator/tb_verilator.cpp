#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_sim_main.h"
#include "Vtb_sim_main__Syms.h"
#include "Vtb_sim_main___024root.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/simulator/Axi4sImageLoadNode.h"
#include "jelly/simulator/Axi4sImageDumpNode.h"
#include "jelly/JellyRegs.h"


namespace jsim = jelly::simulator;


#if VM_TRACE
#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h> 
#endif


// 画像の前処理
cv::Mat PreProcImage(cv::Mat img, int frame_num)
{
    if ( img.empty() ) { return img; }

    // 回転
    auto center = cv::Point(img.cols/2, img.rows/2);
    auto trans  = cv::getRotationMatrix2D(center, frame_num*10, 1);
    cv::Mat img2;
    cv::warpAffine(img, img2, trans, img.size());
    return img2;
}


int main(int argc, char** argv)
{
    auto contextp = std::make_shared<VerilatedContext>();
    contextp->debug(0);
    contextp->randReset(2);
    contextp->commandArgs(argc, argv);
    
    const auto top = std::make_shared<Vtb_sim_main>(contextp.get(), "top");


    jsim::trace_ptr_t tfp = nullptr;
#if VM_TRACE
    contextp->traceEverOn(true);

    tfp = std::make_shared<jsim::trace_t>();
    top->trace(tfp.get(), 100);
    tfp->open("tb_verilator" TRACE_EXT);
#endif

    auto mng = jsim::Manager::Create();

    mng->AddNode(jsim::VerilatorNode_Create(top, tfp));

    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));
    mng->AddNode(jsim::ClockNode_Create(&top->clk, 1000.0/100.0));

    mng->AddNode(jsim::ResetNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__reset, 100));
    mng->AddNode(jsim::ClockNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__clk100, 1000.0/100.0));
    mng->AddNode(jsim::ClockNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__clk200, 1000.0/200.0));
    mng->AddNode(jsim::ClockNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__clk250, 1000.0/250.0));

    mng->AddNode(jsim::ResetNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_mipi_dphy_cam__DOT__reset,  100));
    mng->AddNode(jsim::ResetNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_mipi_dphy_cam__DOT__busy,  1000, false));
    mng->AddNode(jsim::ClockNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_mipi_dphy_cam__DOT__hs_clk, 8.768));

    /*
    jsim::Axi4sVideo axi4s_src =
            {
                &top->rootp->tb_sim_main__DOT__i_top__DOT__axi4s_cam_aresetn,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__axi4s_cam_aclk,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__axi4s2_csi2_tuser,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__axi4s2_csi2_tlast,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__axi4s2_csi2_tdata,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__axi4s2_csi2_tvalid,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__axi4s2_csi2_tready
            };
    auto image_src_load = jsim::Axi4sImageLoadNode_Create(axi4s_src, "../BOAT.bmp", jsim::fmt_gray);
    mng->AddNode(image_src_load);
    image_src_load->SetBlankX(64);
    image_src_load->SetBlankY((256 + 64) * 8);
    image_src_load->SetRandomWait(0.0);
    mng->AddNode(image_src_load);
    */

    jsim::WishboneMaster wishbone_signals =
            {
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__reset,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__clk100,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_adr_i,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_dat_o,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_dat_i,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_sel_i,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_we_i,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_stb_i,
                &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_ack_o
            };
    auto wb = jsim::WishboneMasterNode_Create(wishbone_signals);
    mng->AddNode(wb);
    
    const unsigned int ADR_FMTR    = (0x00100000 >> 3);  // ビデオサイズ正規化
    const unsigned int ADR_DEMOS   = (0x00200000 >> 3);  // デモザイク
    const unsigned int ADR_COLMAT  = (0x00210000 >> 3);  // カラーマトリックス
    const unsigned int ADR_GAMMA   = (0x00220000 >> 3);  // ガンマ補正
    const unsigned int ADR_GAUSS   = (0x00240000 >> 3);  // ガウシアンフィルタ
    const unsigned int ADR_CANNY   = (0x00250000 >> 3);  // Cannyフィルタ
    const unsigned int ADR_IMGDMA  = (0x00260000 >> 3);  // FIFO dma
    const unsigned int ADR_BINDIFF = (0x00270000 >> 3);  // 前画像との差分バイナライズ
    const unsigned int ADR_SEL     = (0x002f0000 >> 3);  // 出力切り替え
    const unsigned int ADR_BUFMNG  = (0x00300000 >> 3);  // Buffer manager
    const unsigned int ADR_BUFALC  = (0x00310000 >> 3);  // Buffer allocator
    const unsigned int ADR_VDMAW   = (0x00320000 >> 3);  // Write-DMA
    const unsigned int ADR_VDMAR   = (0x00340000 >> 3);  // Read-DMA
    const unsigned int ADR_VSGEN   = (0x00360000 >> 3);  // Video out sync generator
    const unsigned int ADR_HLS     = (0x00400000 >> 3);
    
    const unsigned int IMG_X_NUM = 1024;
    const unsigned int IMG_Y_NUM = 64;

    // WISHBONE 
    wb->Wait(200);    
    wb->Display("read id");
    wb->Read(0);

    wb->Display("set FMTR");
    wb->Read (ADR_FMTR + REG_VIDEO_FMTREG_CORE_ID);
    wb->Write(ADR_FMTR + REG_VIDEO_FMTREG_PARAM_WIDTH,  IMG_X_NUM, 0xff);
    wb->Write(ADR_FMTR + REG_VIDEO_FMTREG_PARAM_HEIGHT, IMG_Y_NUM, 0xff);
    wb->Write(ADR_FMTR + REG_VIDEO_FMTREG_CTL_CONTROL,        0x3, 0xff);

    wb->Display("set DEMOSIC");
    wb->Read (ADR_DEMOS + REG_IMG_DEMOSAIC_CORE_ID);
    wb->Write(ADR_DEMOS + REG_IMG_DEMOSAIC_PARAM_PHASE,    0, 0xff);
    wb->Write(ADR_DEMOS + REG_IMG_DEMOSAIC_CTL_CONTROL,  0x3, 0xff);

    wb->Display("set write DMA");
    wb->Read (ADR_VDMAW + REG_VDMA_WRITE_CORE_ID);
    wb->Write(ADR_VDMAW + REG_VDMA_WRITE_PARAM_ADDR,                    0x0000000, 0xff);
    wb->Write(ADR_VDMAW + REG_VDMA_WRITE_PARAM_LINE_STEP,             IMG_X_NUM*3, 0xff);
    wb->Write(ADR_VDMAW + REG_VDMA_WRITE_PARAM_H_SIZE,                IMG_X_NUM-1, 0xff);
    wb->Write(ADR_VDMAW + REG_VDMA_WRITE_PARAM_V_SIZE,                IMG_Y_NUM-1, 0xff);
    wb->Write(ADR_VDMAW + REG_VDMA_WRITE_PARAM_FRAME_STEP,  IMG_Y_NUM*IMG_X_NUM*3, 0xff);
    wb->Write(ADR_VDMAW + REG_VDMA_WRITE_PARAM_F_SIZE,                        1-1, 0xff);
    wb->Write(ADR_VDMAW + REG_VDMA_WRITE_CTL_CONTROL,                           3, 0xff);  // update & enable

    wb->Wait(100000);
    wb->Display("set HLS");
    wb->Write(ADR_HLS + 0x08, 1, 0xff);
    wb->Wait(100000);

    mng->Run(4000000);
//    mng->Run();

#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}


// end of file
