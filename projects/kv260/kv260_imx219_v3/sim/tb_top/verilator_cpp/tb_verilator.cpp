#include <memory>
#include <verilated.h>
//#include <opencv2/opencv.hpp>
#include "Vtb_verilator.h"
#include "jelly/simulator/Manager.h"
#include "jelly/simulator/ResetNode.h"
#include "jelly/simulator/ClockNode.h"
#include "jelly/simulator/VerilatorNode.h"
#include "jelly/simulator/Axi4LiteMasterNode.h"
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
    
    const auto top = std::make_shared<Vtb_verilator>(contextp.get(), "top");


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

    jsim::Axi4Lite axi4lite_signals =
            {
                &top->s_axi4l_peri_aresetn   ,
                &top->s_axi4l_peri_aclk      ,
                &top->s_axi4l_peri_awaddr    ,
                &top->s_axi4l_peri_awprot    ,
                &top->s_axi4l_peri_awvalid   ,
                &top->s_axi4l_peri_awready   ,
                &top->s_axi4l_peri_wdata     ,
                &top->s_axi4l_peri_wstrb     ,
                &top->s_axi4l_peri_wvalid    ,
                &top->s_axi4l_peri_wready    ,
                &top->s_axi4l_peri_bresp     ,
                &top->s_axi4l_peri_bvalid    ,
                &top->s_axi4l_peri_bready    ,
                &top->s_axi4l_peri_araddr    ,
                &top->s_axi4l_peri_arprot    ,
                &top->s_axi4l_peri_arvalid   ,
                &top->s_axi4l_peri_arready   ,
                &top->s_axi4l_peri_rdata     ,
                &top->s_axi4l_peri_rresp     ,
                &top->s_axi4l_peri_rvalid    ,
                &top->s_axi4l_peri_rready    ,
            };
    auto axi4l = jsim::Axi4LiteMasterNode_Create(axi4lite_signals);
    mng->AddNode(axi4l);


    int X_NUM = top->img_width;
    int Y_NUM = top->img_height;

    const std::uint64_t bw = 8;

    const std::uint64_t reg_gpio   = 0xa0000000;
    const std::uint64_t reg_fmtr   = 0xa0100000;
    const std::uint64_t reg_wb     = 0xa0121000;
    const std::uint64_t reg_demos  = 0xa0122000;
    const std::uint64_t reg_colmat = 0xa0124000;
    const std::uint64_t reg_wdma   = 0xa0210000;
        
    axi4l->Wait(1000);
    axi4l->Display("start");
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_CORE_ID          );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_CORE_VERSION     );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_CONTROL      );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_STATUS       );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_INDEX        );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_SKIP         );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT  );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_PARAM_WIDTH      );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_PARAM_HEIGHT     );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_PARAM_FILL       );
    axi4l->ExecRead(reg_fmtr + bw * REG_VIDEO_FMTREG_PARAM_TIMEOUT    );

    int SIM_IMG_WIDTH  = top->img_width;  // 128;
    int SIM_IMG_HEIGHT = top->img_height; // 64;
    
    // 0 : RGGB
    // 1 : GRBG
    // 2 : GBRG
    // 3 : BGGR
    int bayer_phase = 0;


    axi4l->Display("cam enable");
    axi4l->ExecWrite(reg_gpio + 8 * 2     , 1 , 0xff);

    axi4l->Wait(1000);
    
    axi4l->Display("White Balance");
    // Black Level Correction
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_OFFSET0,    66, 0xff); // R 
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_OFFSET1,    66, 0xff); // G
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_OFFSET2,    66, 0xff); // G
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_OFFSET3,    66, 0xff); // B

    // White Balance
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_COEFF0 ,  4620, 0xff); // R
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_COEFF1 ,  4096, 0xff); // G
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_COEFF2 ,  4096, 0xff); // G
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_COEFF3 , 10428, 0xff); // B

    // enable
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_PARAM_PHASE  , bayer_phase, 0xff);
    axi4l->ExecWrite(reg_wb + bw * REG_IMG_BAYER_WB_CTL_CONTROL  ,     3, 0xff);


    axi4l->Display("demos");
    axi4l->ExecWrite(reg_demos + bw * REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase, 0xff);
    axi4l->ExecWrite(reg_demos + bw * REG_IMG_DEMOSAIC_CTL_CONTROL, 3, 0xff);
    

    axi4l->Wait(1000);
    axi4l->Display("enable");
    axi4l->ExecWrite(reg_fmtr + bw * REG_VIDEO_FMTREG_PARAM_WIDTH     , SIM_IMG_WIDTH , 0xff);
    axi4l->ExecWrite(reg_fmtr + bw * REG_VIDEO_FMTREG_PARAM_HEIGHT    , SIM_IMG_HEIGHT, 0xff);
//  axi4l->ExecWrite(reg_fmtr + bw * REG_VIDEO_FMTREG_PARAM_TIMEOUT   , 1000          , 0xff);
//  axi4l->ExecWrite(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT , 100000        , 0xff);
    axi4l->ExecWrite(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1             , 0xff);
    axi4l->ExecWrite(reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_CONTROL     , 1             , 0xff);
    axi4l->ExecRead (reg_fmtr + bw * REG_VIDEO_FMTREG_CTL_STATUS     );

    
    axi4l->Display("set write DMA");
    axi4l->ExecRead (reg_wdma + bw * REG_VDMA_WRITE_CORE_ID         );
    axi4l->ExecWrite(reg_wdma + bw * REG_VDMA_WRITE_PARAM_ADDR      , 0x0000a00                     , 0xff);
    axi4l->ExecWrite(reg_wdma + bw * REG_VDMA_WRITE_PARAM_LINE_STEP , SIM_IMG_WIDTH*4               , 0xff);
    axi4l->ExecWrite(reg_wdma + bw * REG_VDMA_WRITE_PARAM_H_SIZE    , SIM_IMG_WIDTH-1               , 0xff);
    axi4l->ExecWrite(reg_wdma + bw * REG_VDMA_WRITE_PARAM_V_SIZE    , SIM_IMG_HEIGHT-1              , 0xff);
    axi4l->ExecWrite(reg_wdma + bw * REG_VDMA_WRITE_PARAM_FRAME_STEP, SIM_IMG_HEIGHT*SIM_IMG_WIDTH*4, 0xff);
    axi4l->ExecWrite(reg_wdma + bw * REG_VDMA_WRITE_PARAM_F_SIZE    , 1-1                           , 0xff);

    /*
    axi4l->Display("oneshot");
    axi4l->ExecWrite(reg_wdma + 8 * REG_VDMA_WRITE_CTL_CONTROL     , 7                             , 0xff);  // update & enable
    while (axi4l->ExecRead(reg_wdma + 8 * REG_VDMA_WRITE_CTL_STATUS) != 0x00000000) {
        axi4l->Wait(1000);
        mng->Run(1000);
    }
    axi4l->Wait(10000);
    
    axi4l->Display("oneshot");
    axi4l->ExecWrite(reg_wdma + 8 * REG_VDMA_WRITE_CTL_CONTROL     , 7                             , 0xff);  // update & enable
    while (axi4l->ExecRead(reg_wdma + 8 * REG_VDMA_WRITE_CTL_STATUS) != 0x00000000) {
        axi4l->Wait(1000);
        mng->Run(1000);
    }
    axi4l->Wait(10000);
    */

    axi4l->ExecWrite(reg_wdma + 8 * REG_VDMA_WRITE_CTL_CONTROL     , 3                             , 0xff);  // update & enable
    axi4l->Wait(100000);
//  axi4l->ExecWrite(reg_wdma + 8 * REG_VDMA_WRITE_CTL_CONTROL     , 0                             , 0xff);  // update & enable


    mng->Run(10000000);
    
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
