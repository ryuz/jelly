#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_verilator.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/VerilatorNode.h"
//#include "jelly/simulator/Axi4sImageLoadNode.h"
//#include "jelly/simulator/Axi4sImageDumpNode.h"


namespace jsim = jelly::simulator;


#if VM_TRACE
#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h> 
#endif


int main(int argc, char** argv)
{
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

    mng->AddNode(jsim::ClockNode_Create(&top->clk, 0.5/2));
    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));
#if VM_TRACE
    mng->AddNode(jsim::VerilatorNode_Create(top, tfp));
#else
    mng->AddNode(jsim::VerilatorNode_Create(top, nullptr));
#endif

    mng->SetControlWindow("Simulation");
    mng->SetThreadEnable(true);

    mng->Run(200000);
    
#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}


// end of file
