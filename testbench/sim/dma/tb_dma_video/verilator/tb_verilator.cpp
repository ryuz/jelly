#include <memory>
#include <verilated.h>
//#include <opencv2/opencv.hpp>
#include "Vtb_main.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
//#include "jelly/simulator/Axi4sImageLoadNode.h"
//#include "jelly/simulator/Axi4sImageDumpNode.h"
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

    mng->AddNode(jsim::ResetNode_Create(&top->s_wb_rst_i,  100));
    mng->AddNode(jsim::ResetNode_Create(&top->src_aresetn, 100, false));
    mng->AddNode(jsim::ResetNode_Create(&top->dst_aresetn, 100, false));
    mng->AddNode(jsim::ResetNode_Create(&top->mem_aresetn, 100, false));
    mng->AddNode(jsim::ClockNode_Create(&top->s_wb_clk_i, 1000.0/100.0));
    mng->AddNode(jsim::ClockNode_Create(&top->src_aclk,   1000.0/133.0));
    mng->AddNode(jsim::ClockNode_Create(&top->dst_aclk,   1000.0/150.0));
    mng->AddNode(jsim::ClockNode_Create(&top->mem_aclk,   1000.0/333.3));

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
    auto wb = jsim::WishboneMasterNode_Create(wishbone_signals, false);
    mng->AddNode(wb);

    const   int     ADR_BUFM = 0x0000;
    const   int     ADR_BUFA = 0x0100;
    const   int     ADR_DMAW = 0x0200;
    const   int     ADR_DMAR = 0x0300;

    wb->Display("set buffer manager");
    wb->Write(ADR_BUFM + REG_BUF_MANAGER_BUFFER0_ADDR, 0x00010000, 0xff);
    wb->Write(ADR_BUFM + REG_BUF_MANAGER_BUFFER1_ADDR, 0x00020000, 0xff);
    wb->Write(ADR_BUFM + REG_BUF_MANAGER_BUFFER2_ADDR, 0x00030000, 0xff);
    wb->Write(ADR_BUFM + REG_BUF_MANAGER_BUFFER3_ADDR, 0x00040000, 0xff);
        
    wb->Display("write start");
    wb->Write(ADR_DMAW + REG_VDMA_WRITE_PARAM_ADDR,  0x00000000, 0xff);
    wb->Write(ADR_DMAW + REG_VDMA_WRITE_CTL_CONTROL,        0x9, 0xff);
    wb->Wait(10000);
        
    wb->Display("read start");
    wb->Write(ADR_DMAR + REG_VDMA_READ_CTL_CONTROL,         0x9, 0xff);
    wb->Wait(10000);
    
    mng->Run(2000000);
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
