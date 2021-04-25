#include <iostream>
#include <memory>
#include <verilated.h>
#include <verilated_fst_c.h> 
#include "Vtb_verilator.h"


int time_counter = 0;
int time_rate = 5;

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);
    
    // Create
//  Vsv_test *top = new Vsv_test();
    auto top = std::make_unique<Vtb_verilator>();
    
    // DUMP ON
    Verilated::traceEverOn(true);
//  VerilatedFstC* tfp = new VerilatedFstC;
    auto tfp = std::make_unique<VerilatedFstC>();
    
    top->trace(tfp.get(), 100);
    tfp->open("tb_verilator.fst");
    
    // 初期化
    top->reset = 1;
    top->clk   = 1;
    
    // リセット
    /*
    while ( time_counter < 100 ) {
        top->eval();
        tfp->dump(time_counter * time_rate);
        time_counter++;
    }
    top->reset = 0;
    */
    
    while ( !Verilated::gotFinish() ) {
//  while ( time_counter < 10000 ) {
        top->reset = (time_counter < 100);

        top->clk = !top->clk;
        top->eval();

        tfp->dump(time_counter * time_rate);
//        std::cout << "Hello" << (int)top->data[1][2] << std::endl;

        time_counter++;
    }
    
    top->final();
    tfp->close();
}


