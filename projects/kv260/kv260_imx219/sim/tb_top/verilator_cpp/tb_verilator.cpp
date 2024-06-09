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

    mng->AddNode(jsim::ResetNode_Create(&top->reset, 100));
    mng->AddNode(jsim::ClockNode_Create(&top->clk100, 1000.0/100.0));
    mng->AddNode(jsim::ClockNode_Create(&top->clk200, 1000.0/200.0));
    mng->AddNode(jsim::ClockNode_Create(&top->clk250, 1000.0/250.0));

    jsim::WishboneMaster wishbone_signals =
            {
                &top->reset,
                &top->clk250,
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


    const int X_NUM = 640;
    const int Y_NUM = 480;
    
    const int reg_gid    = (0x00000000 >> 3);
    const int reg_fmtr   = (0x00100000 >> 3);
    const int reg_demos  = (0x00120000 >> 3);
    const int reg_colmat = (0x00120800 >> 3);
    const int reg_wdma   = (0x00210000 >> 3);
        
    wb->Wait(1000);
    wb->Display("start");
    
    wb->Wait(1000);
    wb->Display("read core ID");
    wb->ExecRead (reg_gid);     // gid
    wb->ExecRead (reg_fmtr);    // fmtr
    wb->ExecRead (reg_demos);   // demosaic
    wb->ExecRead (reg_colmat);  // col mat
    wb->ExecRead (reg_wdma);    // wdma

    wb->Display("set format regularizer");
    wb->ExecRead (reg_fmtr + REG_VIDEO_FMTREG_CORE_ID);                         // CORE ID
    wb->ExecWrite(reg_fmtr + REG_VIDEO_FMTREG_PARAM_WIDTH,      X_NUM, 0xf);    // width
    wb->ExecWrite(reg_fmtr + REG_VIDEO_FMTREG_PARAM_HEIGHT,     Y_NUM, 0xf);    // height
//  wb->ExecWrite(reg_fmtr + REG_VIDEO_FMTREG_PARAM_FILL,           0, 0xf);    // fill
//  wb->ExecWrite(reg_fmtr + REG_VIDEO_FMTREG_PARAM_TIMEOUT,     1024, 0xf);    // timeout
    wb->ExecWrite(reg_fmtr + REG_VIDEO_FMTREG_CTL_CONTROL,          3, 0xf);    // enable
    wb->ExecWait(1000);

    wb->Display("set DEMOSIC");
    wb->ExecRead (reg_demos + REG_IMG_DEMOSAIC_CORE_ID);
    wb->ExecWrite(reg_demos + REG_IMG_DEMOSAIC_PARAM_PHASE,    0x0, 0xf);
    wb->ExecWrite(reg_demos + REG_IMG_DEMOSAIC_CTL_CONTROL,    0x3, 0xf);

    wb->Display("set colmat");
    wb->ExecRead (reg_colmat + REG_IMG_COLMAT_CORE_ID);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX00, 0x00010000, 0xf); // 0x0003a83a
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX01, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX02, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX03, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX10, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX11, 0x00010000, 0xf); // 0x00030c30
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX12, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX13, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX20, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX21, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX22, 0x00010000, 0xf); // 0x000456c7
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX23, 0x00000000, 0xf);
    wb->ExecWrite(reg_colmat + REG_IMG_COLMAT_CTL_CONTROL, 3, 0xf);

    wb->ExecWait(10000);
    wb->Display("set write DMA");
    wb->ExecRead (reg_wdma + REG_VDMA_WRITE_CORE_ID);                               // CORE ID
    wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_PARAM_ADDR,          0x00000000, 0xf);  // address
    wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_PARAM_LINE_STEP,        X_NUM*4, 0xf);  // stride
    wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_PARAM_H_SIZE,           X_NUM-1, 0xf);  // width
    wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_PARAM_V_SIZE,           Y_NUM-1, 0xf);  // height
    wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_PARAM_F_SIZE,               1-1, 0xf);
    wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_PARAM_FRAME_STEP, X_NUM*Y_NUM*4, 0xff);
    wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_CTL_CONTROL,                  3, 0xf);  // update & enable
//  wb->ExecWrite(reg_wdma + REG_VDMA_WRITE_CTL_CONTROL,                  7, 0xf);  // update & enable & oneshot
    wb->ExecWait(1000);

    wb->Display("wait for DMA end");
//    wb->SetVerbose(false);
    while ( wb->ExecRead (reg_wdma + REG_VDMA_WRITE_CTL_STATUS) != 0 ) {
//      wb->ExecWait(10000);
        mng->Run(100000);
    }
    wb->Display("DMA end");

    mng->Run(10000);
    
//    mng->Run(1000000);
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
