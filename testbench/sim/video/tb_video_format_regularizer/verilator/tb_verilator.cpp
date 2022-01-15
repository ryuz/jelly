#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_sim_main.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/simulator/Axi4sImageLoadNode.h"
#include "jelly/simulator/Axi4sImageDumpNode.h"


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
    mng->AddNode(jsim::ResetNode_Create(&top->aresetn, 100, false));
    mng->AddNode(jsim::ClockNode_Create(&top->aclk, 4.0));
    mng->AddNode(jsim::ResetNode_Create(&top->s_wb_rst_i, 100, true));
    mng->AddNode(jsim::ClockNode_Create(&top->s_wb_clk_i, 10.0));

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

    wb->Wait(200);
    wb->Display("start");
    wb->Read(0x00000000);
    wb->Read(0x00000004);
    wb->Read(0x00000008);
    wb->Read(0x0000000c);
    wb->Read(0x00000020);
    wb->Read(0x00000024);
    wb->Read(0x00000028);
    wb->Read(0x0000002c);
        
    wb->Wait(100);
    wb->Display("enable");
    wb->Write(0x00000000, 1, 0xf);
    wb->Read(0x00000000);
    wb->Read(0x00000004);
    
    wb->Wait(100000);
    wb->Display("disable");
    wb->Write(0x00000000, 0, 0xf);
    wb->Read(0x00000000);
    wb->Read(0x00000004);
    
    wb->Wait(200000);
    wb->Display("enable");
    wb->Write(0x00000000, 1, 0xf);
    wb->Read(0x00000000);
    wb->Read(0x00000004);
    
    // frame timeout
    wb->Wait(100000);
    wb->Display("frame timeout");
    wb->Write(0x00000014, 100000,   0xf);
    wb->Write(0x00000010, 1, 0xf);
    wb->Write(0x00000028, 0xff0000, 0xf);
    wb->Write(0x00000000, 3, 0xf);
    
    wb->Wait(1000);
    wb->Write(0x00000028, 0x0000ff,  0xf);
    wb->Write(0x00000000, 3,  0xf);

    mng->Run(10000000);
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
