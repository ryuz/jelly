#include <memory>
#include <verilated.h>
//#include <opencv2/opencv.hpp>
#include "Vtb_main.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/Axi4LiteMasterNode.h"
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

    mng->AddNode(jsim::ResetNode_Create(&top->aresetn, 100, false));
    mng->AddNode(jsim::ClockNode_Create(&top->aclk,   1000.0/100.0));

    jsim::Axi4Lite axi4lite_signals =
            {
                &top->aresetn           ,
                &top->aclk              ,
                &top->s_axi4l_awaddr    ,
                &top->s_axi4l_awprot    ,
                &top->s_axi4l_awvalid   ,
                &top->s_axi4l_awready   ,
                &top->s_axi4l_wdata     ,
                &top->s_axi4l_wstrb     ,
                &top->s_axi4l_wvalid    ,
                &top->s_axi4l_wready    ,
                &top->s_axi4l_bresp     ,
                &top->s_axi4l_bvalid    ,
                &top->s_axi4l_bready    ,
                &top->s_axi4l_araddr    ,
                &top->s_axi4l_arprot    ,
                &top->s_axi4l_arvalid   ,
                &top->s_axi4l_arready   ,
                &top->s_axi4l_rdata     ,
                &top->s_axi4l_rresp     ,
                &top->s_axi4l_rvalid    ,
                &top->s_axi4l_rready    ,
            };
    auto axi4l = jsim::Axi4LiteMasterNode_Create(axi4lite_signals);
    mng->AddNode(axi4l);


        
    axi4l->Wait(100);
    axi4l->Display("start");    

    axi4l->ExecRead (0xa0000000);
    axi4l->ExecRead (0xa0000004);
    axi4l->ExecRead (0xa0000008);
    axi4l->ExecRead (0xa000000c);

    axi4l->ExecWrite(0xa0000000, 0x11111111, 0xf);
    axi4l->ExecWrite(0xa0000004, 0x22002200, 0xf);
    axi4l->ExecWrite(0xa0000008, 0x00000033, 0xf);
    axi4l->ExecWrite(0xa000000c, 0x00440000, 0xf);

    axi4l->ExecRead (0xa0000000);
    axi4l->ExecRead (0xa0000004);
    axi4l->ExecRead (0xa0000008);
    axi4l->ExecRead (0xa000000c);

    axi4l->ExecWrite(0xa0000000, 0xff000000, 0x8);
    axi4l->ExecWrite(0xa0000004, 0x00ee0000, 0x4);
    axi4l->ExecWrite(0xa0000008, 0x0000dd00, 0x2);
    axi4l->ExecWrite(0xa000000c, 0x001100cc, 0x1);

    axi4l->ExecRead (0xa0000000);
    axi4l->ExecRead (0xa0000004);
    axi4l->ExecRead (0xa0000008);
    axi4l->ExecRead (0xa000000c);

    axi4l->Display("end");

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
