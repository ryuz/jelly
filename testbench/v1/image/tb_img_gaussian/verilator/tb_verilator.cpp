#include <memory>
#include <verilated.h>
#include "Vtb_verilator.h"

#if VM_TRACE
#include <verilated_fst_c.h> 
#endif


int main(int argc, char** argv)
{
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->debug(0);
    contextp->randReset(2);
    contextp->commandArgs(argc, argv);
    
    const auto top = std::make_unique<Vtb_verilator>(contextp.get(), "top");

#if VM_TRACE
    contextp->traceEverOn(true);
    const auto tfp = std::make_unique<VerilatedFstC>();
    top->trace(tfp.get(), 100);
    tfp->open("tb_verilator.fst");
#endif

    // 初期化
    top->reset = 1;
    top->clk   = 1;
    
    // 実行
    while ( !contextp->gotFinish() ) {
        contextp->timeInc(5);
        top->clk = !top->clk;

        top->eval();
        
        if ( top->clk ) {
            if ( contextp->time() > 1 && contextp->time() < 1000 ) {
                top->reset = 1;
            } else {
                top->reset = 0;
            }
        }
        
        tfp->dump(contextp->time());
    }
    
    top->final();
#if VM_TRACE
    tfp->close();
#endif

#if VM_COVERAGE
    Verilated::mkdir("logs");
    contextp->coveragep()->write("logs/coverage.dat");
#endif
    
    return 0;
}

// end of file
