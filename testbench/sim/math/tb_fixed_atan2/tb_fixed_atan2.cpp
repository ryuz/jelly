#include <iostream>
#include <verilated.h>
#include <verilated_fst_c.h> 
#include "Vtb_fixed_atan2.h"


int time_counter = 0;
int time_rate = 5;

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);
    
    // Create
    Vtb_fixed_atan2 *top = new Vtb_fixed_atan2();
    
    // DUMP ON
    Verilated::traceEverOn(true);
    VerilatedFstC* tfp = new VerilatedFstC;
    
    top->trace(tfp, 100);
    tfp->open("tb_fixed_atan2.fst");
    
    // ‰Šú‰»
    top->tb_fixed_atan2__DOT__reset = 1;
    top->tb_fixed_atan2__DOT__clk   = 1;
    top->tb_fixed_atan2__DOT__cke   = 1;
    
    // ƒŠƒZƒbƒg
    while ( time_counter < 100 ) {
        top->eval();
        tfp->dump(time_counter * time_rate);
        time_counter++;
    }
    top->tb_fixed_atan2__DOT__reset = 0;
    
    
    while ( !Verilated::gotFinish() ) {

        top->tb_fixed_atan2__DOT__clk = !top->tb_fixed_atan2__DOT__clk;
        
        top->eval();
        tfp->dump(time_counter * time_rate);
        
        time_counter++;
    }
    
    top->final();
    tfp->close();
}


