import os
import sys
import time
import cv2
import numpy as np
from pathlib import Path

sys.path.append(os.path.join(Path().resolve(), '../../../python'))
#from jellypy import jellypy
import jellypy


# Video Write-DMA
REG_VIDEO_WDMA_CORE_ID                 = 0x00
REG_VIDEO_WDMA_VERSION                 = 0x01
REG_VIDEO_WDMA_CTL_CONTROL             = 0x04
REG_VIDEO_WDMA_CTL_STATUS              = 0x05
REG_VIDEO_WDMA_CTL_INDEX               = 0x07
REG_VIDEO_WDMA_PARAM_ADDR              = 0x08
REG_VIDEO_WDMA_PARAM_STRIDE            = 0x09
REG_VIDEO_WDMA_PARAM_WIDTH             = 0x0a
REG_VIDEO_WDMA_PARAM_HEIGHT            = 0x0b
REG_VIDEO_WDMA_PARAM_SIZE              = 0x0c
REG_VIDEO_WDMA_PARAM_AWLEN             = 0x0f
REG_VIDEO_WDMA_MONITOR_ADDR            = 0x10
REG_VIDEO_WDMA_MONITOR_STRIDE          = 0x11
REG_VIDEO_WDMA_MONITOR_WIDTH           = 0x12
REG_VIDEO_WDMA_MONITOR_HEIGHT          = 0x13
REG_VIDEO_WDMA_MONITOR_SIZE            = 0x14
REG_VIDEO_WDMA_MONITOR_AWLEN           = 0x17

# Video format regularizer
REG_VIDEO_FMTREG_CORE_ID               = 0x00
REG_VIDEO_FMTREG_CORE_VERSION          = 0x01
REG_VIDEO_FMTREG_CTL_CONTROL           = 0x04
REG_VIDEO_FMTREG_CTL_STATUS            = 0x05
REG_VIDEO_FMTREG_CTL_INDEX             = 0x07
REG_VIDEO_FMTREG_CTL_SKIP              = 0x08
REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN      = 0x0a
REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT       = 0x0b
REG_VIDEO_FMTREG_PARAM_WIDTH           = 0x10
REG_VIDEO_FMTREG_PARAM_HEIGHT          = 0x11
REG_VIDEO_FMTREG_PARAM_FILL            = 0x12
REG_VIDEO_FMTREG_PARAM_TIMEOUT         = 0x13

# Demosaic
REG_IMG_DEMOSAIC_CORE_ID               = 0x00
REG_IMG_DEMOSAIC_CORE_VERSION          = 0x01
REG_IMG_DEMOSAIC_CTL_CONTROL           = 0x04
REG_IMG_DEMOSAIC_CTL_STATUS            = 0x05
REG_IMG_DEMOSAIC_CTL_INDEX             = 0x07
REG_IMG_DEMOSAIC_PARAM_PHASE           = 0x08
REG_IMG_DEMOSAIC_CURRENT_PHASE         = 0x18

# peri
reg_peri = jellypy.UioAccessor('uio_pl_peri', 0x10000000)

reg_gid    = reg_peri.get_accessor(0x00000000)
reg_fmtr   = reg_peri.get_accessor(0x00100000)
reg_prmup  = reg_peri.get_accessor(0x00011000)
reg_demos  = reg_peri.get_accessor(0x00120000)
reg_colmat = reg_peri.get_accessor(0x00120200)
reg_wdma   = reg_peri.get_accessor(0x00210000)

print(reg_gid.read_reg(0))
print(reg_fmtr.read_reg(0))
print(reg_prmup.read_reg(0))
print(reg_demos.read_reg(0))
print(reg_colmat.read_reg(0))
print(reg_wdma.read_reg(0))


# udmabuf
udmabuf  = jellypy.UdmabufAccessor('udmabuf0')
dmabuf_mem_addr = udmabuf.get_phys_addr()
dmabuf_mem_size = udmabuf.get_size()


# GPIO on
gpio = jellypy.GpioAccessor(36)
gpio.set_direction(True)
gpio.set_value(1)
time.sleep(0.2)

# IMX219 I2C control

imx219 = jellypy.Imx219ControlI2c()
if not imx219.open('/dev/i2c-4', 0x10):
    print('I2C open error')
    sys.exit(1)
    
imx219.reset()

print('Model ID : %04x' % imx219.get_model_id())


pixel_clock = 139200000.0
binning     = True
width       = 640
height      = 132
aoi_x       = -1
aoi_y       = -1
flip_h      = False
flip_v      = False
frame_rate  = 1000
exposure    = 10
a_gain      = 20
d_gain      = 10
bayer_phase = 1
view_scale  = 1

# camera setting
imx219.set_pixel_clock(139200000.0)
imx219.set_aoi(width, height, aoi_x, aoi_y, binning, binning)
imx219.start()


rec_frame_num = min(100, dmabuf_mem_size // (width * height * 4))
frame_num     = 1
print(dmabuf_mem_size)
print(rec_frame_num)


def capture_still_image(reg_wdma, reg_fmtr, bufaddr, width, height, frame_num):
    # DMA start (one shot)
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_ADDR,   bufaddr)
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_STRIDE, width*4)
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_WIDTH,  width)
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_HEIGHT, height)
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_SIZE,   width*height*frame_num)
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_AWLEN,  31)
    reg_wdma.write_reg(REG_VIDEO_WDMA_CTL_CONTROL,  0x07)
    
    # video format regularizer
    reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1)
    reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000)
    reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width)
    reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height)
    reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_FILL,        0x100)
    reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000)
    reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03)
    time.sleep(0.1)
    
    # wait
    time.sleep(0.1)
    while reg_wdma.read_reg(REG_VIDEO_WDMA_CTL_STATUS) != 0:
        time.sleep(0.1)
    
    # formatter stop
    reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00)
    time.sleep(0.1)
    while reg_wdma.read_reg(REG_VIDEO_FMTREG_CTL_STATUS) != 0:
        usleep(1000)



#
imx219.set_frame_rate(frame_rate)
imx219.set_exposure_time(exposure / 1000.0)
imx219.set_gain(a_gain)
imx219.set_digital_gain(d_gain)
imx219.set_flip(flip_h, flip_v)
reg_demos.write_reg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase)
reg_demos.write_reg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3)  #update & enable

# cpture
capture_still_image(reg_wdma, reg_fmtr, dmabuf_mem_addr, width, height, 1)
#cv::Mat img(height*frame_num, width, CV_8UC4)
#udmabuf_acc.MemCopyTo(img.data, 0, width * height * 4 * frame_num)
img = udmabuf.get_array_uint8((height, width, 4), 0)

cv2.imshow('"img', img)
cv2.waitKey()

