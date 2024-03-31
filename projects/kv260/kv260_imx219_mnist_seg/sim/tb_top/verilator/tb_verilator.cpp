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


//    const int X_NUM = 640;
//    const int Y_NUM = 132;
    const int X_NUM = 320;
    const int Y_NUM = 240;
    
//   const int reg_gid    = (0x00000000 >> 3);
//   const int reg_fmtr   = (0x00100000 >> 3);
//   const int reg_wdma   = (0x00210000 >> 3);
//   const int reg_demos  = (0x00400000 >> 3);
//   const int reg_colmat = (0x00400800 >> 3);
//   const int reg_gauss  = (0x00402000 >> 3);
//   const int reg_bin    = (0x00403000 >> 3);
//   const int reg_select = (0x00407800 >> 3);
    
    const int   reg_gid     = (0x00000000 >> 3);
    const int   reg_fmtr    = (0x00100000 >> 3);  // ビデオサイズ正規化
    const int   reg_demos   = (0x00200000 >> 3);  // デモザイク
    const int   reg_colmat  = (0x00210000 >> 3);  // カラーマトリックス
    const int   reg_gamma   = (0x00220000 >> 3);  // ガンマ補正
    const int   reg_gauss   = (0x00240000 >> 3);  // ガウシアンフィルタ
    const int   reg_sel     = (0x002f0000 >> 3);  // 出力切り替え
    const int   reg_vdmaw   = (0x00320000 >> 3);  // Write-DMA
    const int   reg_vdmar   = (0x00340000 >> 3);  // Read-DMA
    const int   reg_vsgen   = (0x00360000 >> 3);  // Video out sync generator

    wb->Wait(1000);
    wb->Display("start");
    
    wb->Wait(1000);
    wb->Display("read core ID");
    wb->Read (reg_gid    );     // gid
    wb->Read (reg_fmtr   );
    wb->Read (reg_demos  );
    wb->Read (reg_colmat );
    wb->Read (reg_gamma  );
    wb->Read (reg_gauss  );
    wb->Read (reg_sel    );
    wb->Read (reg_vdmaw  );
    wb->Read (reg_vdmar  );
    wb->Read (reg_vsgen  );


    wb->Wait(1000);
    wb->Display("set selector");
    wb->Write(reg_sel + REG_IMG_SELECTOR_CTL_SELECT, 0, 0xf);

    wb->Display("set format regularizer");
    wb->Read (reg_fmtr + REG_VIDEO_FMTREG_CORE_ID);                         // CORE ID
    wb->Write(reg_fmtr + REG_VIDEO_FMTREG_PARAM_WIDTH,      X_NUM, 0xf);    // width
    wb->Write(reg_fmtr + REG_VIDEO_FMTREG_PARAM_HEIGHT,     Y_NUM, 0xf);    // height
    wb->Write(reg_fmtr + REG_VIDEO_FMTREG_PARAM_FILL,           0, 0xf);    // fill
    wb->Write(reg_fmtr + REG_VIDEO_FMTREG_PARAM_TIMEOUT,     1024, 0xf);    // timeout
    wb->Write(reg_fmtr + REG_VIDEO_FMTREG_CTL_CONTROL,          1, 0xf);    // enable
    wb->Wait(1000);

    wb->Display("set DEMOSIC");
    wb->Read (reg_demos + REG_IMG_DEMOSAIC_CORE_ID);
    wb->Write(reg_demos + REG_IMG_DEMOSAIC_PARAM_PHASE,    0x0, 0xf);
    wb->Write(reg_demos + REG_IMG_DEMOSAIC_CTL_CONTROL,    0x3, 0xf);

    wb->Display("set colmat");
    wb->Read (reg_colmat + REG_IMG_COLMAT_CORE_ID);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX00, 0x00010000, 0xf); // 0x0003a83a
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX01, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX02, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX03, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX10, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX11, 0x00010000, 0xf); // 0x00030c30
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX12, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX13, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX20, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX21, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX22, 0x00010000, 0xf); // 0x000456c7
    wb->Write(reg_colmat + REG_IMG_COLMAT_PARAM_MATRIX23, 0x00000000, 0xf);
    wb->Write(reg_colmat + REG_IMG_COLMAT_CTL_CONTROL, 3, 0xf);

    wb->Display("set gauss");
    wb->Read (reg_gauss + REG_IMG_GAUSS3X3_CORE_ID);
    wb->Write(reg_gauss + REG_IMG_GAUSS3X3_PARAM_ENABLE, 0x7, 0xf);
    wb->Write(reg_gauss + REG_IMG_GAUSS3X3_CTL_CONTROL,  0x3, 0xf);

    /*
    wb->Display("set bin");
    wb->Read (reg_bindiff + REG_IMG_BIN_CORE_ID);
    wb->Write(reg_bindiff + REG_IMG_BIN_PARAM_TH0(0),  700, 0xf);
    wb->Write(reg_bindiff + REG_IMG_BIN_PARAM_TH1(0),  800, 0xf);
    wb->Write(reg_bindiff + REG_IMG_BIN_PARAM_TH0(1),  200, 0xf);
    wb->Write(reg_bindiff + REG_IMG_BIN_PARAM_TH1(1), 1023, 0xf);
    wb->Write(reg_bindiff + REG_IMG_BIN_PARAM_TH0(2),   10, 0xf);
    wb->Write(reg_bindiff + REG_IMG_BIN_PARAM_TH1(2), 1023, 0xf);
//  wb->Write(reg_bindiff + REG_IMG_BIN_PARAM_VAL0(0), 0, 0xf);
//  wb->Write(reg_bindiff + REG_IMG_BIN_PARAM_VAL1(0), 1, 0xf);
    wb->Write(reg_bindiff + REG_IMG_BIN_CTL_CONTROL, 3, 0xf);
    */

    wb->Display("set write DMA");
    wb->Read (reg_vdmaw + REG_VDMA_WRITE_CORE_ID);                         // CORE ID
    wb->Write(reg_vdmaw + REG_VDMA_WRITE_PARAM_ADDR,          0x30000000, 0xf);  // address
    wb->Write(reg_vdmaw + REG_VDMA_WRITE_PARAM_LINE_STEP,        X_NUM*4, 0xf);  // stride
    wb->Write(reg_vdmaw + REG_VDMA_WRITE_PARAM_H_SIZE,           X_NUM-1, 0xf);   // width
    wb->Write(reg_vdmaw + REG_VDMA_WRITE_PARAM_V_SIZE,           Y_NUM-1, 0xf);  // height
    wb->Write(reg_vdmaw + REG_VDMA_WRITE_PARAM_F_SIZE,               1-1, 0xf);
    wb->Write(reg_vdmaw + REG_VDMA_WRITE_PARAM_FRAME_STEP, X_NUM*Y_NUM*4, 0xff);
    wb->Write(reg_vdmaw + REG_VDMA_WRITE_CTL_CONTROL,                  3, 0xf);  // update & enable
    wb->Wait(1000);
    wb->Read (reg_vdmaw + REG_VDMA_WRITE_CTL_STATUS);  // read status
    wb->Read (reg_vdmaw + REG_VDMA_WRITE_CTL_STATUS);  // read status
    wb->Read (reg_vdmaw + REG_VDMA_WRITE_CTL_STATUS);  // read status
    wb->Read (reg_vdmaw + REG_VDMA_WRITE_CTL_STATUS);  // read status
    
    mng->Run(2000000*2);
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
