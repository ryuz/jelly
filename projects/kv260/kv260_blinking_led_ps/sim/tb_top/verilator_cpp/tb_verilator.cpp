#include <memory>
#include <verilated.h>
#include "Vtb_main.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/Axi4LiteMasterNode.h"

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

    mng->AddNode(jsim::ResetNode_Create(&top->s_axi4l_aresetn, 100, false));
    mng->AddNode(jsim::ClockNode_Create(&top->s_axi4l_aclk, 1000.0/100.0));   // 100MHz

    jsim::Axi4Lite axi4lite_signals =
            {
                &top->s_axi4l_aresetn   ,
                &top->s_axi4l_aclk      ,
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

    // リセット解除待ち
    mng->Run(10000);

    for ( int i = 0; i < 10; i++ ) {
        // LED を ON
        axi4l->ExecWrite(0, 1, 0xff); // 1を書く
        axi4l->ExecRead(0);           // 読み出す
        mng->Run(10000);

        // LED を OFF
        axi4l->ExecWrite(0, 0, 0xff); // 0を書く
        axi4l->ExecRead(0);           // 読み出す
        mng->Run(10000);
    }


#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}


// end of file
