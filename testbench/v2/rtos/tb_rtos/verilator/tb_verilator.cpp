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


const unsigned int  OPCODE_WIDTH       = 8;
const unsigned int  ID_WIDTH           = 8;
const unsigned int  DECODE_OPCODE_POS  = 0;
const unsigned int  DECODE_ID_POS      = DECODE_OPCODE_POS + OPCODE_WIDTH;

const unsigned int  OPCODE_REF_INF     = 0x00;
const unsigned int  OPCODE_CPU_STS     = 0x01;
const unsigned int  OPCODE_WUP_TSK     = 0x10;
const unsigned int  OPCODE_SLP_TSK     = 0x11;
const unsigned int  OPCODE_SIG_SEM     = 0x21;
const unsigned int  OPCODE_WAI_SEM     = 0x22;
const unsigned int  OPCODE_SET_FLG     = 0x31;
const unsigned int  OPCODE_CLR_FLG     = 0x32;
const unsigned int  OPCODE_WAI_FLG_AND = 0x33;
const unsigned int  OPCODE_WAI_FLG_OR  = 0x34;

const unsigned int  REF_INF_CORE_ID    = 0x0;
const unsigned int  REF_INF_VERSION    = 0x1;
const unsigned int  REF_INF_DATE       = 0x4;

const unsigned int  CPU_STS_TASKID     = 0x00;
const unsigned int  CPU_STS_VALID      = 0x01;


int make_addr(int opcode, int id) {
    return (opcode << DECODE_OPCODE_POS) | (id << DECODE_ID_POS); 
}

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


#if 0

    auto wb = jsim::WishboneMasterNode_Create(wishbone);
    mng->AddNode(wb);

    // WISHBONE 
    wb->Wait(100);

    wb->Display(" --- read test --- ");
    wb->Read (0x00000001);

    // Run
    mng->Run(10000);

#else

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
    
    // Run
    mng->Run();

    th.join();

#endif


#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    contextp->coveragep()->write("coverage.dat");
#endif

    return 0;
}


// end of file
