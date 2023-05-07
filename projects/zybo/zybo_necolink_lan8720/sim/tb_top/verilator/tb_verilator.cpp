#include <memory>
#include <verilated.h>
#include "Vtb_main.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/JellyRegs.h"


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

    mng->AddNode(jsim::ResetNode_Create(&top->reset,  100));
    mng->AddNode(jsim::ClockNode_Create(&top->clk50,  1000.0/50.0));
    mng->AddNode(jsim::ClockNode_Create(&top->clk100, 1000.0/100.0));
    mng->AddNode(jsim::ClockNode_Create(&top->clk125, 1000.0/125.0));
    mng->AddNode(jsim::ClockNode_Create(&top->clk200, 1000.0/200.0));
    mng->AddNode(jsim::ClockNode_Create(&top->clk250, 1000.0/250.0));

//  double dmy_rate = 1.001;
    double dmy_rate = 1.000 - 0.0001;
    mng->AddNode(jsim::ResetNode_Create(&top->dmy_reset,  50));
    mng->AddNode(jsim::ClockNode_Create(&top->dmy_clk50,  1000.0/50.0  * dmy_rate));
    mng->AddNode(jsim::ClockNode_Create(&top->dmy_clk100, 1000.0/100.0 * dmy_rate));
    mng->AddNode(jsim::ClockNode_Create(&top->dmy_clk125, 1000.0/125.0 * dmy_rate));
    mng->AddNode(jsim::ClockNode_Create(&top->dmy_clk200, 1000.0/200.0 * dmy_rate));
    mng->AddNode(jsim::ClockNode_Create(&top->dmy_clk250, 1000.0/250.0 * dmy_rate));

    jsim::WishboneMaster wishbone_signals =
            {
                &top->reset,
                &top->clk250,
                &top->s_wb_peri_adr_i,
                &top->s_wb_peri_dat_o,
                &top->s_wb_peri_dat_i,
                &top->s_wb_peri_sel_i,
                &top->s_wb_peri_we_i,
                &top->s_wb_peri_stb_i,
                &top->s_wb_peri_ack_o
            };
    auto wb = jsim::WishboneMasterNode_Create(wishbone_signals);
    mng->AddNode(wb);

//    wb->ExecWait(10000);
//    wb->Display("set write DMA");
//    wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_CTL_CONTROL,                  7, 0xf);  // update & enable & oneshot
//    wb->ExecWait(1000);


    mng->Run(20000000);
    
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
