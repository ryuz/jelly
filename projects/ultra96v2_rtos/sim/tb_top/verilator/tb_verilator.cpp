#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_sim_main.h"
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


#define RTOS_ID_WIDTH                   8
#define RTOS_OPCODE_WIDTH               8
#define RTOS_DECODE_ID_POS              0
#define RTOS_DECODE_OPCODE_POS          (DECODE_ID_POS + ID_WIDTH)

#define RTOS_OPCODE_REF_CFG             0x00
#define RTOS_OPCODE_CPU_CTL             0x01
#define RTOS_OPCODE_WUP_TSK             0x10
#define RTOS_OPCODE_SLP_TSK             0x11
#define RTOS_OPCODE_DLY_TSK             0x18
#define RTOS_OPCODE_SIG_SEM             0x21
#define RTOS_OPCODE_WAI_SEM             0x22
#define RTOS_OPCODE_SET_FLG             0x31
#define RTOS_OPCODE_CLR_FLG             0x32
#define RTOS_OPCODE_WAI_FLG_AND         0x33
#define RTOS_OPCODE_WAI_FLG_OR          0x34
#define RTOS_REF_CFG_CORE_ID            0x00
#define RTOS_REF_CFG_VERSION            0x01
#define RTOS_REF_CFG_DATE               0x04
#define RTOS_CPU_CTL_TOP_TSKID          0x00
#define RTOS_CPU_CTL_TOP_VALID          0x01
#define RTOS_CPU_CTL_RUN_TSKID          0x04
#define RTOS_CPU_CTL_RUN_VALID          0x05
#define RTOS_CPU_CTL_IRQ_EN             0x10
#define RTOS_CPU_CTL_IRQ_STS            0x11

#define RTOS_MAKE_ADDR(opcode, id)      (((opcode) << RTOS_DECODE_OPCODE_POS) | ((id) << RTOS_DECODE_ID_POS))


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
    
    mng->AddNode(jsim::ClockNode_Create(&top->clk, 5.0));
    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));

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
    /*
    // WISHBONE 
    auto wb = jsim::WishboneAccessNode_Create(wishbone);
    mng->AddNode(wb);

    std::thread th([wb]{
        wb->Wait(100);

        wb->Display(" --- start --- ");
        wb->Read (0);
        wb->Write(make_addr(OPCODE_CPU_STS, CPU_STS_TASKID), 1, 0xf);
        wb->Wait(10);
        wb->Write(make_addr(OPCODE_WUP_TSK, 1), 0, 0xf);
        wb->Write(make_addr(OPCODE_WUP_TSK, 0), 0, 0xf);
        wb->Write(make_addr(OPCODE_WUP_TSK, 3), 0, 0xf);
        wb->Wait(10);
        wb->Write(make_addr(OPCODE_WAI_FLG_AND, 0), 5, 0xf);
        wb->Wait(10);
        wb->Write(make_addr(OPCODE_SET_FLG, 0), 1, 0xf);
        wb->Wait(10);
        wb->Write(make_addr(OPCODE_SET_FLG, 0), 4, 0xf);
        wb->Wait(10);
        wb->Write(make_addr(OPCODE_CLR_FLG, 0), ~1, 0xf);
        wb->Wait(10);
        wb->Write(make_addr(OPCODE_CLR_FLG, 0), ~4, 0xf);

        wb->Write(make_addr(OPCODE_WAI_SEM, 1), 0, 0xf);
        wb->Wait(10);
        wb->Write(make_addr(OPCODE_SIG_SEM, 1), 0, 0xf);

        wb->Wait(10);
        wb->Write(make_addr(OPCODE_SLP_TSK, 0), 0, 0xf);
        wb->Write(make_addr(OPCODE_SLP_TSK, 1), 0, 0xf);
        
        wb->Wait(100);
        wb->Finish();
    });
    */

    // Run
    mng->Run();

//    th.join();


#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}


// end of file
