#include <memory>
#include <verilated.h>
#include "Vtb_sim_main.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
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

    mng->AddNode(jsim::ClockNode_Create(&top->clk, 5.0));
    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));
    mng->AddNode(jsim::VerilatorNode_Create(top, tfp));

    jsim::WishboneMaster wishbone =
                {
                    &top->reset,
                    &top->clk,
                    &top->s_wb_adr_i,
                    &top->s_wb_dat_o,
                    &top->s_wb_dat_i,
                    &top->s_wb_sel_i,
                    &top->s_wb_we_i,
                    &top->s_wb_stb_i,
                    &top->s_wb_ack_o
                };

    
    // ----------------------------------
    //  Simulation
    // ----------------------------------
    
    // WISHBONE 
    auto wb = jsim::WishboneMasterNode_Create(wishbone);
    mng->AddNode(wb);

    wb->Wait(100);
    wb->Display(" --- start --- ");

    wb->Read (0x00000000 + 0);
    wb->Read (0x00000000 + 1);
    wb->Read (0x00000000 + 2);
    wb->Read (0x00000000 + 3);
    wb->Read (0x00000000 + 4);
    wb->Read (0x00000000 + 5);
    wb->Write(0x00000000 + 8, 1, 0xf);

    FILE* fp = fopen("../../../app/jfive/jfive_sample.bin", "rb");
    std::uint32_t instr;

    wb->SetVerbose(false);
    int i = 0;
    while ( fread(&instr, sizeof(instr), 1, fp) == 1 ) {
        wb->Write(0x00000000 + 0x8000 + i, instr, 0xf);
        i++;
    }
    wb->SetVerbose(true);
    fclose(fp);
    

    wb->Wait(100);
    wb->Write(0x00000000 + 8, 0, 0xf);
    

    mng->Run(100000);
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
