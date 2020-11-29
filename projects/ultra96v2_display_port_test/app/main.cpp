// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include "jelly/DevMemAccessor.h"
#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"

struct RegsInfo {
    const char*     name;
    std::uintptr_t  addr;
};

RegsInfo DpRegs[] = {
    {"DP_LINK_BW_SET",                       0x00000000},
    {"DP_LANE_COUNT_SET",                    0x00000004},
    {"DP_ENHANCED_FRAME_EN",                 0x00000008},
    {"DP_TRAINING_PATTERN_SET",              0x0000000C},
    {"DP_LINK_QUAL_PATTERN_SET",             0x00000010},
    {"DP_SCRAMBLING_DISABLE",                0x00000014},
    {"DP_DOWNSPREAD_CTRL",                   0x00000018},
    {"DP_SOFTWARE_RESET",                    0x0000001C},
    {"DP_COMP_PATTERN_80BIT_1",              0x00000020},
    {"DP_COMP_PATTERN_80BIT_2",              0x00000024},
    {"DP_COMP_PATTERN_80BIT_3",              0x00000028},
    {"DP_TRANSMITTER_ENABLE",                0x00000080},
    {"DP_MAIN_STREAM_ENABLE",                0x00000084},
    {"DP_FORCE_SCRAMBLER_RESET",             0x000000C0},
    {"DP_VERSION_REGISTER",                  0x000000F8},
    {"DP_CORE_ID",                           0x000000FC},
    {"DP_AUX_COMMAND_REGISTER",              0x00000100},
    {"DP_AUX_WRITE_FIFO",                    0x00000104},
    {"DP_AUX_ADDRESS",                       0x00000108},
    {"DP_AUX_CLOCK_DIVIDER",                 0x0000010C},
    {"DP_TX_USER_FIFO_OVERFLOW",             0x00000110},
    {"DP_INTERRUPT_SIGNAL_STATE",            0x00000130},
    {"DP_AUX_REPLY_DATA",                    0x00000134},
    {"DP_AUX_REPLY_CODE",                    0x00000138},
    {"DP_AUX_REPLY_COUNT",                   0x0000013C},
    {"DP_REPLY_DATA_COUNT",                  0x00000148},
    {"DP_REPLY_STATUS",                      0x0000014C},
    {"DP_HPD_DURATION",                      0x00000150},
    {"DP_MAIN_STREAM_HTOTAL",                0x00000180},
    {"DP_MAIN_STREAM_VTOTAL",                0x00000184},
    {"DP_MAIN_STREAM_POLARITY",              0x00000188},
    {"DP_MAIN_STREAM_HSWIDTH",               0x0000018C},
    {"DP_MAIN_STREAM_VSWIDTH",               0x00000190},
    {"DP_MAIN_STREAM_HRES",                  0x00000194},
    {"DP_MAIN_STREAM_VRES",                  0x00000198},
    {"DP_MAIN_STREAM_HSTART",                0x0000019C},
    {"DP_MAIN_STREAM_VSTART",                0x000001A0},
    {"DP_MAIN_STREAM_MISC0",                 0x000001A4},
    {"DP_MAIN_STREAM_MISC1",                 0x000001A8},
    {"DP_MAIN_STREAM_M_VID",                 0x000001AC},
    {"DP_MSA_TRANSFER_UNIT_SIZE",            0x000001B0},
    {"DP_MAIN_STREAM_N_VID",                 0x000001B4},
    {"DP_USER_PIX_WIDTH",                    0x000001B8},
    {"DP_USER_DATA_COUNT_PER_LANE",          0x000001BC},
    {"DP_MIN_BYTES_PER_TU",                  0x000001C4},
    {"DP_FRAC_BYTES_PER_TU",                 0x000001C8},
    {"DP_INIT_WAIT",                         0x000001CC},
    {"DP_PHY_RESET",                         0x00000200},
    {"DP_TRANSMIT_PRBS7",                    0x00000230},
    {"DP_PHY_CLOCK_SELECT",                  0x00000234},
    {"DP_TX_PHY_POWER_DOWN",                 0x00000238},
    {"DP_PHY_PRECURSOR_LANE_0",              0x0000024C},
    {"DP_PHY_PRECURSOR_LANE_1",              0x00000250},
    {"DP_PHY_STATUS",                        0x00000280},
    {"DP_TX_AUDIO_CONTROL",                  0x00000300},
    {"DP_TX_AUDIO_CHANNELS",                 0x00000304},
    {"DP_TX_AUDIO_INFO_DATA0",               0x00000308},
    {"DP_TX_AUDIO_INFO_DATA1",               0x0000030C},
    {"DP_TX_AUDIO_INFO_DATA2",               0x00000310},
    {"DP_TX_AUDIO_INFO_DATA3",               0x00000314},
    {"DP_TX_AUDIO_INFO_DATA4",               0x00000318},
    {"DP_TX_AUDIO_INFO_DATA5",               0x0000031C},
    {"DP_TX_AUDIO_INFO_DATA6",               0x00000320},
    {"DP_TX_AUDIO_INFO_DATA7",               0x00000324},
    {"DP_TX_M_AUD",                          0x00000328},
    {"DP_TX_N_AUD",                          0x0000032C},
    {"DP_TX_AUDIO_EXT_DATA0",                0x00000330},
    {"DP_TX_AUDIO_EXT_DATA1",                0x00000334},
    {"DP_TX_AUDIO_EXT_DATA2",                0x00000338},
    {"DP_TX_AUDIO_EXT_DATA3",                0x0000033C},
    {"DP_TX_AUDIO_EXT_DATA4",                0x00000340},
    {"DP_TX_AUDIO_EXT_DATA5",                0x00000344},
    {"DP_TX_AUDIO_EXT_DATA6",                0x00000348},
    {"DP_TX_AUDIO_EXT_DATA7",                0x0000034C},
    {"DP_TX_AUDIO_EXT_DATA8",                0x00000350},
    {"DP_INT_STATUS",                        0x000003A0},
    {"DP_INT_MASK",                          0x000003A4},
    {"DP_INT_EN",                            0x000003A8},
    {"DP_INT_DS",                            0x000003AC},
    {"V_BLEND_BG_CLR_0",                     0x0000A000},
    {"V_BLEND_BG_CLR_1",                     0x0000A004},
    {"V_BLEND_BG_CLR_2",                     0x0000A008},
    {"V_BLEND_SET_GLOBAL_ALPHA_REG",         0x0000A00C},
    {"V_BLEND_OUTPUT_VID_FORMAT",            0x0000A014},
    {"V_BLEND_LAYER0_CONTROL",               0x0000A018},
    {"V_BLEND_LAYER1_CONTROL",               0x0000A01C},
    {"V_BLEND_RGB2YCBCR_COEFF0",             0x0000A020},
    {"V_BLEND_RGB2YCBCR_COEFF1",             0x0000A024},
    {"V_BLEND_RGB2YCBCR_COEFF2",             0x0000A028},
    {"V_BLEND_RGB2YCBCR_COEFF3",             0x0000A02C},
    {"V_BLEND_RGB2YCBCR_COEFF4",             0x0000A030},
    {"V_BLEND_RGB2YCBCR_COEFF5",             0x0000A034},
    {"V_BLEND_RGB2YCBCR_COEFF6",             0x0000A038},
    {"V_BLEND_RGB2YCBCR_COEFF7",             0x0000A03C},
    {"V_BLEND_RGB2YCBCR_COEFF8",             0x0000A040},
    {"V_BLEND_IN1CSC_COEFF0",                0x0000A044},
    {"V_BLEND_IN1CSC_COEFF1",                0x0000A048},
    {"V_BLEND_IN1CSC_COEFF2",                0x0000A04C},
    {"V_BLEND_IN1CSC_COEFF3",                0x0000A050},
    {"V_BLEND_IN1CSC_COEFF4",                0x0000A054},
    {"V_BLEND_IN1CSC_COEFF5",                0x0000A058},
    {"V_BLEND_IN1CSC_COEFF6",                0x0000A05C},
    {"V_BLEND_IN1CSC_COEFF7",                0x0000A060},
    {"V_BLEND_IN1CSC_COEFF8",                0x0000A064},
    {"V_BLEND_LUMA_IN1CSC_OFFSET",           0x0000A068},
    {"V_BLEND_CR_IN1CSC_OFFSET",             0x0000A06C},
    {"V_BLEND_CB_IN1CSC_OFFSET",             0x0000A070},
    {"V_BLEND_LUMA_OUTCSC_OFFSET",           0x0000A074},
    {"V_BLEND_CR_OUTCSC_OFFSET",             0x0000A078},
    {"V_BLEND_CB_OUTCSC_OFFSET",             0x0000A07C},
    {"V_BLEND_IN2CSC_COEFF0",                0x0000A080},
    {"V_BLEND_IN2CSC_COEFF1",                0x0000A084},
    {"V_BLEND_IN2CSC_COEFF2",                0x0000A088},
    {"V_BLEND_IN2CSC_COEFF3",                0x0000A08C},
    {"V_BLEND_IN2CSC_COEFF4",                0x0000A090},
    {"V_BLEND_IN2CSC_COEFF5",                0x0000A094},
    {"V_BLEND_IN2CSC_COEFF6",                0x0000A098},
    {"V_BLEND_IN2CSC_COEFF7",                0x0000A09C},
    {"V_BLEND_IN2CSC_COEFF8",                0x0000A0A0},
    {"V_BLEND_LUMA_IN2CSC_OFFSET",           0x0000A0A4},
    {"V_BLEND_CR_IN2CSC_OFFSET",             0x0000A0A8},
    {"V_BLEND_CB_IN2CSC_OFFSET",             0x0000A0AC},
    {"V_BLEND_CHROMA_KEY_ENABLE",            0x0000A1D0},
    {"V_BLEND_CHROMA_KEY_COMP1",             0x0000A1D4},
    {"V_BLEND_CHROMA_KEY_COMP2",             0x0000A1D8},
    {"V_BLEND_CHROMA_KEY_COMP3",             0x0000A1DC},
    {"AV_BUF_FORMAT",                        0x0000B000},
    {"AV_BUF_NON_LIVE_LATENCY",              0x0000B008},
    {"AV_CHBUF0",                            0x0000B010},
    {"AV_CHBUF1",                            0x0000B014},
    {"AV_CHBUF2",                            0x0000B018},
    {"AV_CHBUF3",                            0x0000B01C},
    {"AV_CHBUF4",                            0x0000B020},
    {"AV_CHBUF5",                            0x0000B024},
    {"AV_BUF_STC_CONTROL",                   0x0000B02C},
    {"AV_BUF_STC_INIT_VALUE0",               0x0000B030},
    {"AV_BUF_STC_INIT_VALUE1",               0x0000B034},
    {"AV_BUF_STC_ADJ",                       0x0000B038},
    {"AV_BUF_STC_VIDEO_VSYNC_TS_REG0",       0x0000B03C},
    {"AV_BUF_STC_VIDEO_VSYNC_TS_REG1",       0x0000B040},
    {"AV_BUF_STC_EXT_VSYNC_TS_REG0",         0x0000B044},
    {"AV_BUF_STC_EXT_VSYNC_TS_REG1",         0x0000B048},
    {"AV_BUF_STC_CUSTOM_EVENT_TS_REG0",      0x0000B04C},
    {"AV_BUF_STC_CUSTOM_EVENT_TS_REG1",      0x0000B050},
    {"AV_BUF_STC_CUSTOM_EVENT2_TS_REG0",     0x0000B054},
    {"AV_BUF_STC_CUSTOM_EVENT2_TS_REG1",     0x0000B058},
//  {"AV_BUF_STC_SNAPSHOT0",                 0x0000B060},   // ← 触ると固まる模様？
//  {"AV_BUF_STC_SNAPSHOT1",                 0x0000B064},   // ← 触ると固まる模様？
    {"AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT",     0x0000B070},
    {"AV_BUF_HCOUNT_VCOUNT_INT0",            0x0000B074},
    {"AV_BUF_HCOUNT_VCOUNT_INT1",            0x0000B078},
    {"AV_BUF_DITHER_CONFIG",                 0x0000B07C},
    {"DITHER_CONFIG_SEED0",                  0x0000B080},
    {"DITHER_CONFIG_SEED1",                  0x0000B084},
    {"DITHER_CONFIG_SEED2",                  0x0000B088},
    {"DITHER_CONFIG_MAX",                    0x0000B08C},
    {"DITHER_CONFIG_MIN",                    0x0000B090},
    {"PATTERN_GEN_SELECT",                   0x0000B100},
    {"AUD_PATTERN_SELECT1",                  0x0000B104},
    {"AUD_PATTERN_SELECT2",                  0x0000B108},
    {"AV_BUF_AUD_VID_CLK_SOURCE",            0x0000B120},
    {"AV_BUF_SRST_REG",                      0x0000B124},
    {"AV_BUF_AUDIO_RDY_INTERVAL",            0x0000B128},
    {"AV_BUF_AUDIO_CH_CONFIG",               0x0000B12C},
    {"AV_BUF_GRAPHICS_COMP0_SCALE_FACTOR",   0x0000B200},
    {"AV_BUF_GRAPHICS_COMP1_SCALE_FACTOR",   0x0000B204},
    {"AV_BUF_GRAPHICS_COMP2_SCALE_FACTOR",   0x0000B208},
    {"AV_BUF_VIDEO_COMP0_SCALE_FACTOR",      0x0000B20C},
    {"AV_BUF_VIDEO_COMP1_SCALE_FACTOR",      0x0000B210},
    {"AV_BUF_VIDEO_COMP2_SCALE_FACTOR",      0x0000B214},
    {"AV_BUF_LIVE_VIDEO_COMP0_SF",           0x0000B218},
    {"AV_BUF_LIVE_VIDEO_COMP1_SF",           0x0000B21C},
    {"AV_BUF_LIVE_VIDEO_COMP2_SF",           0x0000B220},
    {"AV_BUF_LIVE_VID_CONFIG",               0x0000B224},
    {"AV_BUF_LIVE_GFX_COMP0_SF",             0x0000B228},
    {"AV_BUF_LIVE_GFX_COMP1_SF",             0x0000B22C},
    {"AV_BUF_LIVE_GFX_COMP2_SF",             0x0000B230},
    {"AV_BUF_LIVE_GFX_CONFIG",               0x0000B234},
    {"AUDIO_MIXER_VOLUME_CONTROL",           0x0000C000},
    {"AUDIO_MIXER_META_DATA",                0x0000C004},
    {"AUD_CH_STATUS_REG0",                   0x0000C008},
    {"AUD_CH_STATUS_REG1",                   0x0000C00C},
    {"AUD_CH_STATUS_REG2",                   0x0000C010},
    {"AUD_CH_STATUS_REG3",                   0x0000C014},
    {"AUD_CH_STATUS_REG4",                   0x0000C018},
    {"AUD_CH_STATUS_REG5",                   0x0000C01C},
    {"AUD_CH_A_DATA_REG0",                   0x0000C020},
    {"AUD_CH_A_DATA_REG1",                   0x0000C024},
    {"AUD_CH_A_DATA_REG2",                   0x0000C028},
    {"AUD_CH_A_DATA_REG3",                   0x0000C02C},
    {"AUD_CH_A_DATA_REG4",                   0x0000C030},
    {"AUD_CH_A_DATA_REG5",                   0x0000C034},
    {"AUD_CH_B_DATA_REG0",                   0x0000C038},
    {"AUD_CH_B_DATA_REG1",                   0x0000C03C},
    {"AUD_CH_B_DATA_REG2",                   0x0000C040},
    {"AUD_CH_B_DATA_REG3",                   0x0000C044},
    {"AUD_CH_B_DATA_REG4",                   0x0000C048},
    {"AUD_CH_B_DATA_REG5",                   0x0000C04C},
    {"AUDIO_SOFT_RESET",                     0x0000CC00},
    {"PATGEN_CRC_R",                         0x0000CC10},
    {"PATGEN_CRC_G",                         0x0000CC14},
    {"PATGEN_CRC_B",                         0x0000CC18},
};

const std::size_t DpRegsSize = sizeof(DpRegs) / sizeof(DpRegs[0]);

void PrintDpRegs(jelly::MemAccessor acc, std::ostream& of)
{
    for ( std::size_t i = 0; i < DpRegsSize; ++i ) {
        auto val = acc.ReadMem32(DpRegs[i].addr);
        char buf[128];
        sprintf(buf, "0x%08x %-40s : 0x%08x (%u)\n", DpRegs[i].addr+0xfd4a0000, DpRegs[i].name, val, val);
        of << buf;
    }
}

int main()
{
    std::cout << "--- DP regs ---" << std::endl;

#if 0
    // mmap uio
    std::cout << "\nuio open" << std::endl;
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }
#endif

    std::cout << "\nDP open" << std::endl;
//  jelly::UioAccessor    dp_acc("uio_dp", 0x00010000);
    jelly::DevMemAccessor dp_acc(0xfd4a0000, 0x00010000);
    if ( !dp_acc.IsMapped() ) {
        std::cout << "uio_acc mmap error" << std::endl;
        return 1;
    }

    PrintDpRegs(dp_acc, std::cout);

    return 0;
}

// end of file
