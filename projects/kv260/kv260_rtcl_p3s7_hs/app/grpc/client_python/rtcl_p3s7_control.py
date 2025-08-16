
import numpy as np
#import cv2

from rtcl_p3s7_client import *


def main():
    mng = RtclP3s7Client()

    print(f"SYSREG_ID     : {mng.read_sys_reg(SYSREG_ID):#04x}")
    print(f"CAMREG_CORE_ID     : {mng.read_cam_reg(CAMREG_CORE_ID):#04x}")
    print(f"CAMREG_CORE_VERSION: {mng.read_sys_reg(CAMREG_CORE_VERSION):#04x}")
    print(f"TIMGENREG_CORE_ID: {mng.read_timgen_reg(TIMGENREG_CORE_ID):#04x}")

    # 受信側 DPHY リセット
    mng.write_sys_reg(SYSREG_DPHY_SW_RESET, 1)

    # カメラ板初期化
    mng.write_sys_reg(SYSREG_CAM_ENABLE, 0)
    
    # センサー電源OFF
    mng.write_cam_reg(CAMREG_DPHY_CORE_RESET, 1) # 受信側 DPHY リセット
    mng.write_cam_reg(CAMREG_DPHY_SYS_RESET, 1)  # 受信側 DPHY リセット
    # 1ms 待機
    import time
    time.sleep(0.001)
    
    # 受信側 DPHY 解除 (必ずこちらを先に解除)
    mng.write_sys_reg(SYSREG_DPHY_SW_RESET, 0)

    # センサー電源ON
    mng.write_sys_reg(SYSREG_CAM_ENABLE, 1)
    time.sleep(0.001)

    # センサー基板 DPHY-TX リセット解除
    mng.write_cam_reg(CAMREG_DPHY_CORE_RESET, 0)
    mng.write_cam_reg(CAMREG_DPHY_SYS_RESET, 0)
    time.sleep(0.001)
    dphy_tx_init_done = mng.read_cam_reg(CAMREG_DPHY_INIT_DONE)
    if dphy_tx_init_done == 0:
        print("!!ERROR!! CAM DPHY TX init_done = 0")
        return

    # ここで RX 側も init_done が来る
    dphy_rx_init_done = mng.read_sys_reg(SYSREG_DPHY_INIT_DONE)
    if dphy_rx_init_done == 0:
        print("!!ERROR!! KV260 DPHY RX init_done = 0")
        return

    # イメージセンサー起動
    width = 256
    height = 256

    # set image size (UIO registers expect usize)
    mng.write_sys_reg(SYSREG_IMAGE_WIDTH, width)
    mng.write_sys_reg(SYSREG_IMAGE_HEIGHT, height)

    # センサー起動: use the Python300 SPI via the `cam` helper
    mng.write_sensor_reg( 16, 0x0003) # power_down  0:pwd_n, 1:PLL enable, 2: PLL Bypass
    mng.write_sensor_reg( 32, 0x0007) # config0 (10bit mode)
    mng.write_sensor_reg(  8, 0x0000) # pll_soft_reset, pll_lock_soft_reset
    mng.write_sensor_reg(  9, 0x0000) # cgen_soft_reset
    mng.write_sensor_reg( 34, 0x0001) # config0 Logic General Enable Configuration
    mng.write_sensor_reg( 40, 0x0007) # image_core_config0
    mng.write_sensor_reg( 48, 0x0001) # AFE Power down
    mng.write_sensor_reg( 64, 0x0001) # Bias Power Down Configuration
    mng.write_sensor_reg( 72, 0x2227) # Charge Pump
    mng.write_sensor_reg(112, 0x0007) # Serializers/LVDS/IO
    mng.write_sensor_reg( 10, 0x0000) # soft_reset_analog

    # ROI and address calculations (use signed ints for arithmetic)
    roi_x = ((672 -  width) // 2) & ~0x0f   # align to 16
    roi_y = ((512 - height) // 2) & ~0x01   # align to 2
    x_start = roi_x // 8
    x_end = x_start + width // 8 - 1
    y_start = roi_y
    y_end = y_start + height - 1
    mng.write_sensor_reg(256, ((x_end << 8) | (x_start & 0xff))) # x_end<<8 | x_start
    mng.write_sensor_reg(257, (y_start & 0xffff))         # y_start
    mng.write_sensor_reg(258, (y_end & 0xffff))           # y_end

    # ストップしてトレーニングへ
    mng.write_sensor_reg(192, 0x0) # stop / training pattern
    time.sleep(0.001)

    # reset/align on receiver side (Spartan-7 registers)
    mng.write_cam_reg(CAMREG_RECV_RESET, 1)
    mng.write_cam_reg(CAMREG_ALIGN_RESET, 1)
    time.sleep(0.001)
    mng.write_cam_reg(CAMREG_RECV_RESET, 0)
    time.sleep(0.001)
    mng.write_cam_reg(CAMREG_ALIGN_RESET, 0)
    time.sleep(0.001)

    cam_calib_status = mng.read_cam_reg(CAMREG_ALIGN_STATUS)
    if cam_calib_status != 0x01:
        print(f"!!ERROR!! CAM calibration is not done.  status = {cam_calib_status}");
        return

    # 動作開始
    mng.write_sensor_reg(192, 0x1)

    mng.record_image(width, height, 1)
    img = mng.read_image(0, width * height * 2)
    print(f"Image size: {len(img)} bytes")


if __name__ == "__main__":
    main()

