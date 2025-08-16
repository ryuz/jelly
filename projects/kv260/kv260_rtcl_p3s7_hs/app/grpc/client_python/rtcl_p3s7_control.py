import grpc
from grpc.tools import protoc

protoc.main(
    (
        '',
        '-I../protos',
        '--python_out=.',
        '--grpc_python_out=.',
        'rtcl_p3s7_control.proto'
    )
)

import rtcl_p3s7_control_pb2
import rtcl_p3s7_control_pb2_grpc


import numpy as np
import cv2



CAMREG_CORE_ID              = 0x0000
CAMREG_CORE_VERSION         = 0x0001
CAMREG_RECV_RESET           = 0x0010
CAMREG_ALIGN_RESET          = 0x0020
CAMREG_ALIGN_PATTERN        = 0x0022
CAMREG_ALIGN_STATUS         = 0x0028
CAMREG_DPHY_CORE_RESET      = 0x0080
CAMREG_DPHY_SYS_RESET       = 0x0081
CAMREG_DPHY_INIT_DONE       = 0x0088

SYSREG_ID                   = 0x0000
SYSREG_DPHY_SW_RESET        = 0x0001
SYSREG_CAM_ENABLE           = 0x0002
SYSREG_CSI_DATA_TYPE        = 0x0003
SYSREG_DPHY_INIT_DONE       = 0x0004
SYSREG_FPS_COUNT            = 0x0006
SYSREG_FRAME_COUNT          = 0x0007
SYSREG_IMAGE_WIDTH          = 0x0008
SYSREG_IMAGE_HEIGHT         = 0x0009
SYSREG_BLres_WIDTH          = 0x000a
SYSREG_BLres_HEIGHT         = 0x000b

TIMGENREG_CORE_ID           = 0x0000
TIMGENREG_CORE_VERSION      = 0x0001
TIMGENREG_CTL_CONTROL       = 0x0004
TIMGENREG_CTL_STATUS        = 0x0005
TIMGENREG_CTL_TIMER         = 0x0008
TIMGENREG_PARAM_PERIOD      = 0x0010
TIMGENREG_PARAM_TRIG0_START = 0x0020
TIMGENREG_PARAM_TRIG0_END   = 0x0021
TIMGENREG_PARAM_TRIG0_POL   = 0x0022


channel = grpc.insecure_channel('10.72.141.82:50051')
stub = rtcl_p3s7_control_pb2_grpc.RtclP3s7ControlStub(channel)

def write_sys_reg(addr, data):
    stub.WriteSysReg(rtcl_p3s7_control_pb2.WriteRegRequest(addr=addr, data=data))

def read_sys_reg(addr):
    res = stub.ReadSysReg(rtcl_p3s7_control_pb2.ReadRegRequest(addr=addr))
    return res.data

def write_timgen_reg(addr, data):
    stub.WriteTimgenReg(rtcl_p3s7_control_pb2.WriteRegRequest(addr=addr, data=data))

def read_timgen_reg(addr):
    res = stub.ReadTimgenReg(rtcl_p3s7_control_pb2.ReadRegRequest(addr=addr))
    return res.data

def write_cam_reg(addr, data):
    stub.WriteCamReg(rtcl_p3s7_control_pb2.WriteRegRequest(addr=addr, data=data))

def read_cam_reg(addr):
    res = stub.ReadCamReg(rtcl_p3s7_control_pb2.ReadRegRequest(addr=addr))
    return res.data

def write_sensor_reg(addr, data):
    stub.WriteCamReg(rtcl_p3s7_control_pb2.WriteRegRequest(addr=addr, data=data))

def read_sensor_reg(addr):
    res = stub.ReadCamReg(rtcl_p3s7_control_pb2.ReadRegRequest(addr=addr))
    return res.data

def record_image(width, height, frames):
    stub.RecordImage(rtcl_p3s7_control_pb2.RecordImageRequest(width=width, height=height, frames=frames))

def read_image(addr, size):
    res = stub.ReadImage(rtcl_p3s7_control_pb2.ReadImageRequest(addr=addr, size=size))
    return res.image


import time

def main():
    print(f"SYSREG_ID     : {read_sys_reg(SYSREG_ID):#04x}")
    print(f"CAMREG_CORE_ID     : {read_cam_reg(CAMREG_CORE_ID):#04x}")
    print(f"CAMREG_CORE_VERSION: {read_sys_reg(CAMREG_CORE_VERSION):#04x}")
    print(f"TIMGENREG_CORE_ID: {read_timgen_reg(TIMGENREG_CORE_ID):#04x}")

    # 受信側 DPHY リセット
    write_sys_reg(SYSREG_DPHY_SW_RESET, 1)

    # カメラ板初期化
    write_sys_reg(SYSREG_CAM_ENABLE, 0)
    
    # センサー電源OFF
    write_cam_reg(CAMREG_DPHY_CORE_RESET, 1) # 受信側 DPHY リセット
    write_cam_reg(CAMREG_DPHY_SYS_RESET, 1)  # 受信側 DPHY リセット
    # 1ms 待機
    time.sleep(0.001)
    
    # 受信側 DPHY 解除 (必ずこちらを先に解除)
    write_sys_reg(SYSREG_DPHY_SW_RESET, 0)

    # センサー電源ON
    write_sys_reg(SYSREG_CAM_ENABLE, 1)
    time.sleep(0.001)

    # センサー基板 DPHY-TX リセット解除
    write_cam_reg(CAMREG_DPHY_CORE_RESET, 0)
    write_cam_reg(CAMREG_DPHY_SYS_RESET, 0)
    time.sleep(0.001)
    dphy_tx_init_done = read_cam_reg(CAMREG_DPHY_INIT_DONE)
    if dphy_tx_init_done == 0:
        print("!!ERROR!! CAM DPHY TX init_done = 0")
        return

    # ここで RX 側も init_done が来る
    dphy_rx_init_done = read_sys_reg(SYSREG_DPHY_INIT_DONE)
    if dphy_rx_init_done == 0:
        print("!!ERROR!! KV260 DPHY RX init_done = 0")
        return

    # イメージセンサー起動
    width = 256
    height = 256

    # set image size (UIO registers expect usize)
    write_sys_reg(SYSREG_IMAGE_WIDTH, width)
    write_sys_reg(SYSREG_IMAGE_HEIGHT, height)

    # センサー起動: use the Python300 SPI via the `cam` helper
    write_sensor_reg( 16, 0x0003) # power_down  0:pwd_n, 1:PLL enable, 2: PLL Bypass
    write_sensor_reg( 32, 0x0007) # config0 (10bit mode)
    write_sensor_reg(  8, 0x0000) # pll_soft_reset, pll_lock_soft_reset
    write_sensor_reg(  9, 0x0000) # cgen_soft_reset
    write_sensor_reg( 34, 0x0001) # config0 Logic General Enable Configuration
    write_sensor_reg( 40, 0x0007) # image_core_config0
    write_sensor_reg( 48, 0x0001) # AFE Power down
    write_sensor_reg( 64, 0x0001) # Bias Power Down Configuration
    write_sensor_reg( 72, 0x2227) # Charge Pump
    write_sensor_reg(112, 0x0007) # Serializers/LVDS/IO
    write_sensor_reg( 10, 0x0000) # soft_reset_analog

    # ROI and address calculations (use signed ints for arithmetic)
    roi_x = ((672 -  width) // 2) & ~0x0f   # align to 16
    roi_y = ((512 - height) // 2) & ~0x01   # align to 2
    x_start = roi_x // 8
    x_end = x_start + width // 8 - 1
    y_start = roi_y
    y_end = y_start + height - 1
    write_sensor_reg(256, ((x_end << 8) | (x_start & 0xff))) # x_end<<8 | x_start
    write_sensor_reg(257, (y_start & 0xffff))         # y_start
    write_sensor_reg(258, (y_end & 0xffff))           # y_end

    # ストップしてトレーニングへ
    write_sensor_reg(192, 0x0) # stop / training pattern
    time.sleep(0.001)

    # reset/align on receiver side (Spartan-7 registers)
    write_cam_reg(CAMREG_RECV_RESET, 1)
    write_cam_reg(CAMREG_ALIGN_RESET, 1)
    time.sleep(0.001)
    write_cam_reg(CAMREG_RECV_RESET, 0)
    time.sleep(0.001)
    write_cam_reg(CAMREG_ALIGN_RESET, 0)
    time.sleep(0.001)

    cam_calib_status = read_cam_reg(CAMREG_ALIGN_STATUS)
    if cam_calib_status != 0x01:
        print(f"!!ERROR!! CAM calibration is not done.  status = {cam_calib_status}");
        return

    # 動作開始
    write_sensor_reg(192, 0x1)

    record_image(width, height, 1)
    img = read_image(0, width * height * 2)
    print(f"Image size: {len(img)} bytes")

    return


if __name__ == "__main__":
    main()

