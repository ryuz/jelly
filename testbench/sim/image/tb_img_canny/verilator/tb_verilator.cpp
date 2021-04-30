#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_verilator.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/Axi4sImageLoadNode.h"


namespace jsim = jelly::simulator;


#if VM_TRACE
#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h> 
#endif


int main(int argc, char** argv)
{
    cv::Mat img;
    cv::waitKey();

    auto contextp = std::make_shared<VerilatedContext>();
    contextp->debug(0);
    contextp->randReset(2);
    contextp->commandArgs(argc, argv);
    
    const auto top = std::make_shared<Vtb_verilator>(contextp.get(), "top");


#if VM_TRACE
    contextp->traceEverOn(true);
#if VM_TRACE_FST
    auto tfp = std::make_shared<VerilatedFstC>();
    top->trace(tfp.get(), 100);
    tfp->open("tb_verilator.fst");
#else
    auto tfp = std::make_shared<VerilatedVcdC>();
    top->trace(tfp.get(), 100);
    tfp->open("tb_verilator.vcd");
#endif
#endif

    auto mng = jsim::Manager::Create();

#if 0
//  auto clk = jsim::ClockNode<CData>::Create(&top->clk, 5.0);
//  auto reset  = jsim::ResetNode<CData>::Create(&top->reset, 100);
//  auto module = jsim::VerilatorNode<Vtb_verilator>::Create(top, tfp);
    auto clk   = jsim::ClockNode_Create(&top->clk, 5.0);
    auto reset = jsim::ResetNode_Create(&top->reset, 100);
    auto module = jsim::VerilatorNode_Create(top, tfp);
    mng->AddNode(clk);
    mng->AddNode(reset);
    mng->AddNode(module);
#else
    mng->AddNode(jsim::ClockNode_Create(&top->clk, 5.0));
    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));
    mng->AddNode(jsim::VerilatorNode_Create(top, tfp));
#endif

    jsim::Axi4sVideo axi4s =
            {
                &top->s_axi4s_aresetn,
                &top->s_axi4s_aclk,
                &top->s_axi4s_tuser,
                &top->s_axi4s_tlast,
                &top->s_axi4s_tdata,
                &top->s_axi4s_tvalid,
                &top->s_axi4s_tready
            };

    std::string s;
    auto ax = jsim::Axi4sImageLoadNode_Create(axi4s, "../BOAT.pgm", 0, true);
    mng->AddNode(ax);

    mng->Run(1000000);

#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    Verilated::mkdir("logs");
    contextp->coveragep()->write("logs/coverage.dat");
#endif

    return 0;
}


// end of file
