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

    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));
    mng->AddNode(jsim::ClockNode_Create(&top->clk,   1000.0/100.0));

    jsim::WishboneMaster wishbone_signals =
            {
                &top->reset,
                &top->clk,
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

    // ベースアドレス
    const int   ADR_DMA0   = 0x00000 >> 3;
    const int   ADR_DMA1   = 0x00800 >> 3;
    const int   ADR_LED    = 0x08000 >> 3;
    const int   ADR_TIM    = 0x10000 >> 3;

    // レジスタアドレス
    const int   REG_DMA_STATUS  = 0;
    const int   REG_DMA_WSTART  = 1;
    const int   REG_DMA_RSTART  = 2;
    const int   REG_DMA_ADDR    = 3;
    const int   REG_DMA_WDATA0  = 4;
    const int   REG_DMA_WDATA1  = 5;
    const int   REG_DMA_RDATA0  = 6;
    const int   REG_DMA_RDATA1  = 7;
    const int   REG_DMA_CORE_ID = 8;
    const int   REG_TIM_CONTROL = 0;
    const int   REG_TIM_COMPARE = 1;
    const int   REG_TIM_COUNTER = 3;

    wb->Wait(1000);
    wb->Display("read DMA id");
    wb->ExecRead(ADR_DMA0 + REG_DMA_CORE_ID);
    wb->ExecRead(ADR_DMA1 + REG_DMA_CORE_ID);


    wb->Display("write with DMA0");
    wb->ExecWrite(ADR_DMA0 + REG_DMA_ADDR,   0x0000000000000000LL, 0xff);
    wb->ExecWrite(ADR_DMA0 + REG_DMA_WDATA0, 0xfedcba9876543210LL, 0xff);
    wb->ExecWrite(ADR_DMA0 + REG_DMA_WDATA1, 0x0123456789abcdefLL, 0xff);
    wb->ExecWrite(ADR_DMA0 + REG_DMA_WSTART, 1, 0xff);
    while ( wb->ExecRead(ADR_DMA0 + REG_DMA_STATUS) != 0 ) {
        wb->Wait(1000);
    }

    // DMA1で書き込み
    wb->Display("write with DMA1");
    wb->ExecWrite(ADR_DMA1 + REG_DMA_ADDR,   0x0000000000000100LL, 0xff);
    wb->ExecWrite(ADR_DMA1 + REG_DMA_WDATA0, 0x55aa55aa55aa55aaLL, 0xff);
    wb->ExecWrite(ADR_DMA1 + REG_DMA_WDATA1, 0xaa55aa55aa55aa55LL, 0xff);
    wb->ExecWrite(ADR_DMA1 + REG_DMA_WSTART, 1, 0xff);
    while ( wb->ExecRead(ADR_DMA1 + REG_DMA_STATUS) != 0 ) {
        wb->Wait(1000);
    }

    wb->Display("read with DMA0");
    wb->ExecWrite(ADR_DMA0 + REG_DMA_ADDR,   0x0000000000000000, 0xff);
    wb->ExecWrite(ADR_DMA0 + REG_DMA_RSTART, 1, 0xff);
    wb->ExecRead(ADR_DMA0 + REG_DMA_STATUS);
    while ( wb->ExecRead(ADR_DMA0 + REG_DMA_STATUS) != 0 ) {
        wb->Wait(1000);
    }
    wb->ExecRead(ADR_DMA0 + REG_DMA_RDATA0);
    wb->ExecRead(ADR_DMA0 + REG_DMA_RDATA1);

    wb->Display("read with DMA1");
    wb->ExecWrite(ADR_DMA1 + REG_DMA_ADDR,   0x00000000000000100, 0xff);
    wb->ExecWrite(ADR_DMA1 + REG_DMA_RSTART, 1, 0xff);
    while ( wb->ExecRead(ADR_DMA1 + REG_DMA_STATUS) != 0 ) {
        wb->Wait(1000);
    }
    wb->ExecRead(ADR_DMA1 + REG_DMA_RDATA0);
    wb->ExecRead(ADR_DMA1 + REG_DMA_RDATA1);

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
