#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_sim_main.h"
#include "Vtb_sim_main__Syms.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/simulator/WishboneAccessNode.h"


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
    
    mng->AddNode(jsim::ClockNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__clk, 5.0));
    mng->AddNode(jsim::ResetNode_Create(&top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__reset, 100));

    jsim::WishboneMaster wishbone =
                {
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__reset,
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__clk,
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_adr_i,
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_dat_o,
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_dat_i,
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_sel_i,
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_we_i,
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_stb_i,
                    &top->rootp->tb_sim_main__DOT__i_top__DOT__i_design_1__DOT__wb_ack_o
                };

    
    // ----------------------------------
    //  Simulation
    // ----------------------------------
    
    // WISHBONE 
    auto wb = jsim::WishboneAccessNode_Create(wishbone);
    mng->AddNode(wb);

    const int ADR_HLS = 0x00000000;
    const int ADR_LED = 0x00110000;

    const int REG_HLS_CORE_ID = 0;
    const int REG_HLS_CONTROL = 4;
    const int REG_HLS_STATUS  = 5;
    const int REG_HLS_A       = 8;
    const int REG_HLS_B       = 9;
    const int REG_HLS_C       = 10;

    std::thread th([wb]{
        wb->Wait(200);
        wb->Display(" --- HLS --- ");
        wb->Read(ADR_HLS+REG_HLS_CORE_ID);
        wb->Write(ADR_HLS+REG_HLS_A, 7777, 0xff);
        wb->Write(ADR_HLS+REG_HLS_B, 1111, 0xff);
        wb->Write(ADR_HLS+REG_HLS_CONTROL, 1, 0xff);
        wb->Wait(100);
        wb->Read(ADR_HLS+REG_HLS_A);
        wb->Read(ADR_HLS+REG_HLS_B);
        wb->Read(ADR_HLS+REG_HLS_C);

        wb->Wait(200);
        wb->Display(" --- LED --- ");
        wb->Write(ADR_LED, 0, 0xff);
        wb->Write(ADR_LED, 1, 0xff);
        wb->Write(ADR_LED, 0, 0xff);
        wb->Write(ADR_LED, 1, 0xff);

        wb->Wait(200);
        wb->Finish();
    });
    
    // Run
    mng->Run();

    th.join();


#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}


// end of file
