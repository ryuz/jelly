#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_main.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/simulator/VerilatorNode.h"


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
    
    const auto top = std::make_shared<Vtb_main>(contextp.get(), "top");


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
    mng->AddNode(jsim::ClockNode_Create(&top->clk, 5.0));

    mng->AddNode(jsim::ResetNode_Create(&top->s_wb_rst_i, 100));
    mng->AddNode(jsim::ClockNode_Create(&top->s_wb_clk_i, 5.0));
    jsim::WishboneMaster wishbone_signals =
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
    auto wb = jsim::WishboneMasterNode_Create(wishbone_signals);
    mng->AddNode(wb);

    wb->Wait(1000);
    wb->Display("start");
    wb->Read (0x0100);
    wb->Write(0x0200, 0x12345678, 0x0f);
    wb->Display("End");

    mng->Run(100000);

#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}


// end of file
