#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_sim_main.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/WishboneMasterNode.h"

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
    mng->AddNode(jsim::ClockNode_Create(&top->s_wb_clk_i, 5.0));
    mng->AddNode(jsim::ResetNode_Create(&top->s_wb_rst_i, 100));

    jsim::WishboneMaster wishbone =
                {
                    &top->s_wb_rst_i,
                    &top->s_wb_clk_i,
                    &top->s_wb_adr_i,
                    &top->s_wb_dat_o,
                    &top->s_wb_dat_i,
                    &top->s_wb_sel_i,
                    &top->s_wb_we_i,
                    &top->s_wb_stb_i,
                    &top->s_wb_ack_o
                };
    auto wb = jsim::WishboneMasterNode_Create(wishbone);
    mng->AddNode(wb);


    // WISHBONE 
    wb->Wait(100);

    wb->Display(" --- read test --- ");
    wb->Read (0x00000001);
    wb->Read (0x00000002);
    wb->Read (0x00000003);
    wb->Read (0x00000004);
    wb->Read (0x11111111);
    wb->Read (0x22222222);
    wb->Read (0x12345678);
        
    wb->Display(" --- write test --- ");
    wb->Write(0x00000001, 0x00000001, 0xf);
    wb->Write(0x00000002, 0xaaaaaaaa, 0x8);
    wb->Write(0x00000003, 0x55555555, 0xf);
    wb->Write(0x00000004, 0x12345678, 0x2);
    wb->Write(0x11111111, 0x87654321, 0x5);
    wb->Write(0x22222222, 0xaaaa5555, 0xa);
    wb->Write(0x12345678, 0x5555aaaa, 0xf);


    // Run
    mng->Run(10000);

#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}


// end of file
