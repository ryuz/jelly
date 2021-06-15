#include <memory>
#include <verilated.h>
#include <opencv2/opencv.hpp>
#include "Vtb_verilator.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/WishboneMasterNode.h"
#include "jelly/simulator/VerilatorNode.h"


namespace jsim = jelly::simulator;


#if VM_TRACE
#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h> 
#endif

// register address offset
const int ADR_CORE_ID          = 0x00;
const int ADR_CORE_VERSION     = 0x01;
const int ADR_CTL_CONTROL      = 0x04;
const int ADR_CTL_STATUS       = 0x05;
const int ADR_CTL_INDEX        = 0x06;
const int ADR_PARAM_ADDR       = 0x08;
const int ADR_PARAM_SIZE       = 0x09;
const int ADR_PARAM_AWLEN      = 0x10;
const int ADR_PARAM_WSTRB      = 0x11;
const int ADR_PARAM_WTIMEOUT   = 0x13;
const int ADR_PARAM_ARLEN      = 0x14;
const int ADR_PARAM_RTIMEOUT   = 0x17;
const int ADR_CURRENT_ADDR     = 0x28;
const int ADR_CURRENT_SIZE     = 0x29;
const int ADR_CURRENT_AWLEN    = 0x30;
const int ADR_CURRENT_WSTRB    = 0x31;
const int ADR_CURRENT_WTIMEOUT = 0x33;
const int ADR_CURRENT_ARLEN    = 0x34;
const int ADR_CURRENT_RTIMEOUT = 0x37;



int main(int argc, char** argv)
{
    auto contextp = std::make_shared<VerilatedContext>();
    contextp->debug(0);
    contextp->randReset(2);
    contextp->commandArgs(argc, argv);
    
    const auto top = std::make_shared<Vtb_verilator>(contextp.get(), "top");


    jsim::trace_ptr_t tfp = nullptr;
#if VM_TRACE
    contextp->traceEverOn(true);

    tfp = std::make_shared<jsim::trace_t>();
    top->trace(tfp.get(), 100);
    tfp->open("tb_verilator" TRACE_EXT);
#endif

    auto mng = jsim::Manager::Create();

    mng->AddNode(jsim::ClockNode_Create(&top->s_clk, 4.0));
    mng->AddNode(jsim::ResetNode_Create(&top->s_reset, 100));

    mng->AddNode(jsim::ClockNode_Create(&top->m_clk, 5.0));
    mng->AddNode(jsim::ResetNode_Create(&top->m_reset, 100));

    mng->AddNode(jsim::ClockNode_Create(&top->aclk, 3.3));
    mng->AddNode(jsim::ResetNode_Create(&top->aresetn, 100, false));

    mng->AddNode(jsim::ClockNode_Create(&top->wb_clk_i, 10.0));
    mng->AddNode(jsim::ResetNode_Create(&top->wb_rst_i, 100));

    jsim::WishboneMaster wishbone =
            {
                &top->wb_rst_i,
                &top->wb_clk_i,
                &top->s_wb_adr_i,
                &top->s_wb_dat_i,
                &top->s_wb_dat_o,
                &top->s_wb_we_i,
                &top->s_wb_sel_i,
                &top->s_wb_stb_i,
                &top->s_wb_ack_o
            };
    auto wb_master = jsim::WishboneMasterNode_Create(wishbone);
    mng->AddNode(wb_master);

    mng->AddNode(jsim::VerilatorNode_Create(top, tfp));

    wb_master->Wait(1000);
    
    wb_master->Read(ADR_CORE_ID);
    wb_master->Read(ADR_CORE_VERSION);
        
//        $display("set parameter");
    wb_master->Write(ADR_PARAM_ADDR,     0x00001000, 0xf);
    wb_master->Write(ADR_PARAM_SIZE,     0x00001000, 0xf);
    wb_master->Write(ADR_PARAM_AWLEN,    0x0000000f, 0xf);
    wb_master->Write(ADR_PARAM_WSTRB,    0xffffffff, 0xf);
    wb_master->Write(ADR_PARAM_WTIMEOUT, 0x0000000f, 0xf);
    wb_master->Write(ADR_PARAM_ARLEN,    0x0000000f, 0xf);
    wb_master->Write(ADR_PARAM_RTIMEOUT, 0x0000000f, 0xf);
    
//  $display("start");
    wb_master->Write(ADR_CTL_CONTROL,    0x00000003, 0xf);
    wb_master->Wait(10);


//    mng->SetThreadEnable(true);
//    mng->SetControlCvWindow("Simulation", 0x1b);

    mng->Run(1000000);
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
