#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_sim.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/Axi4sImageLoadNode.h"
#include "jelly/simulator/Axi4sImageDumpNode.h"


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
    
    const auto top = std::make_shared<Vtb_sim>(contextp.get(), "top");


    jsim::trace_ptr_t tfp = nullptr;
#if VM_TRACE
    contextp->traceEverOn(true);

    tfp = std::make_shared<jsim::trace_t>();
    top->trace(tfp.get(), 100);
    tfp->open("tb_verilator" TRACE_EXT);
#endif

    auto mng = jsim::Manager::Create();

    mng->AddNode(jsim::ClockNode_Create(&top->clk, 5.0));
    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));
    mng->AddNode(jsim::VerilatorNode_Create(top, tfp));

    mng->Run(1000000);
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
