#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_main.h"
//#include "Vtb_sim_main__Syms.h"
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


#define ID_WIDTH                   8
#define OPCODE_WIDTH               8
#define DECODE_ID_POS              0
#define DECODE_OPCODE_POS          (DECODE_ID_POS + ID_WIDTH)
#define OPCODE_SYS_CFG             0x00
#define OPCODE_CPU_CTL             0x01
#define OPCODE_WUP_TSK             0x10
#define OPCODE_SLP_TSK             0x11
#define OPCODE_DLY_TSK             0x18
#define OPCODE_SIG_SEM             0x21
#define OPCODE_WAI_SEM             0x22
#define OPCODE_SET_FLG             0x31
#define OPCODE_CLR_FLG             0x32
#define OPCODE_WAI_FLG_AND         0x33
#define OPCODE_WAI_FLG_OR          0x34

#define SYS_CFG_CORE_ID            0x00
#define SYS_CFG_VERSION            0x01
#define SYS_CFG_DATE               0x04
#define CPU_CTL_TOP_TSKID          0x00
#define CPU_CTL_TOP_VALID          0x01
#define CPU_CTL_RUN_TSKID          0x04
#define CPU_CTL_RUN_VALID          0x05
#define CPU_CTL_IRQ_EN             0x10
#define CPU_CTL_IRQ_STS            0x11

#define MAKE_ADDR(opcode, id)      (((opcode) << DECODE_OPCODE_POS) | ((id) << DECODE_ID_POS))


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
    
    mng->AddNode(jsim::ClockNode_Create(&top->clk, 4.0));
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
    
#define  ADR_RTOS                   0x00000000
#define  ADR_MOTOR                  0x00020000
#define  ADR_TIM                    0x00040000
#define  ADR_LED                    0x00080000

#define  REG_MOTOR_CORE_ID          0x000
#define  REG_MOTOR_CORE_VERSION     0x001
#define  REG_MOTOR_CORE_CONFIG      0x003
#define  REG_MOTOR_CTL_CONTROL      0x004
#define  REG_MOTOR_IRQ_ENABLE       0x008
#define  REG_MOTOR_IRQ_STATUS       0x009
#define  REG_MOTOR_IRQ_CLR          0x00a
#define  REG_MOTOR_IRQ_SET          0x00b
#define  REG_MOTOR_POSITION         0x010
#define  REG_MOTOR_STEP             0x012
#define  REG_MOTOR_PHASE            0x014

    // WISHBONE 
    auto wb = jsim::WishboneAccessNode_Create(wishbone);
    mng->AddNode(wb);

    std::thread th([wb]{
        wb->Wait(100);

        wb->Display(" --- start --- ");
        wb->Read (ADR_MOTOR + REG_MOTOR_CORE_ID);
        wb->Write(ADR_MOTOR + REG_MOTOR_POSITION,      1, 0xf);
        wb->Write(ADR_MOTOR + REG_MOTOR_STEP,        256, 0xf);
        wb->Write(ADR_MOTOR + REG_MOTOR_CTL_CONTROL,   1, 0xf);

        for ( int i = 0; i < 1000; ++i) {
            wb->Wait(256);
            wb->Write(ADR_MOTOR + REG_MOTOR_POSITION, i*256, 0xf);
        }

        /*
        wb->Read (0);
        wb->Wait(10);
        wb->Write(MAKE_ADDR(OPCODE_WUP_TSK, 1), 0, 0xf);
        wb->Write(MAKE_ADDR(OPCODE_WUP_TSK, 0), 0, 0xf);
        wb->Write(MAKE_ADDR(OPCODE_WUP_TSK, 3), 0, 0xf);
        wb->Wait(10);
        wb->Write(MAKE_ADDR(OPCODE_WAI_FLG_AND, 0), 5, 0xf);
        wb->Wait(10);
        wb->Write(MAKE_ADDR(OPCODE_SET_FLG, 0), 1, 0xf);
        wb->Wait(10);
        wb->Write(MAKE_ADDR(OPCODE_SET_FLG, 0), 4, 0xf);
        wb->Wait(10);
        wb->Write(MAKE_ADDR(OPCODE_CLR_FLG, 0), ~1, 0xf);
        wb->Wait(10);
        wb->Write(MAKE_ADDR(OPCODE_CLR_FLG, 0), ~4, 0xf);

        wb->Write(MAKE_ADDR(OPCODE_WAI_SEM, 1), 0, 0xf);
        wb->Wait(10);
        wb->Write(MAKE_ADDR(OPCODE_SIG_SEM, 1), 0, 0xf);

        wb->Wait(10);
        wb->Write(MAKE_ADDR(OPCODE_SLP_TSK, 0), 0, 0xf);
        wb->Write(MAKE_ADDR(OPCODE_SLP_TSK, 1), 0, 0xf);
        
        wb->Wait(100);
//      wb->Finish();
        */
    });
    
    // Run
    mng->Run(10000000);

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
