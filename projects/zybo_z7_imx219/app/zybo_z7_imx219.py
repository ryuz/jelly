import os
import sys
import time
import cv2
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

sys.path.append(os.path.join(Path().resolve(), '../../../python'))
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
reg_peri = jellypy.UioAccessor('uio_pl_peri', 0x00100000)
if not reg_peri.is_mapped():
    print('open error : uio_pl_peri')
    sys.exit(1)

reg_gid   = reg_peri.get_accessor(0x00000000)
reg_fmtr  = reg_peri.get_accessor(0x00010000)
reg_prmup = reg_peri.get_accessor(0x00011000)
reg_rgb   = reg_peri.get_accessor(0x00012000)
reg_wdma  = reg_peri.get_accessor(0x00021000)

print('\n<read core id>')
print('gid   : 0x%08x' % reg_gid.read_reg(0))
print('fmtr  : 0x%08x' % reg_fmtr.read_reg(0))
print('prmup : 0x%08x' % reg_prmup.read_reg(0))
print('rgb   : 0x%08x' % reg_rgb.read_reg(0))
print('wdma  : 0x%08x' % reg_wdma.read_reg(0))


# udmabuf
udmabuf  = jellypy.UdmabufAccessor('udmabuf0')
if not udmabuf.is_mapped():
    print('open error : udmabuf0')
    sys.exit(1)

dmabuf_mem_addr = udmabuf.get_phys_addr()
dmabuf_mem_size = udmabuf.get_size()
print('\n<udmabuf>')
print('mem_addr : 0x%08x' % dmabuf_mem_addr)
print('mem_size : 0x%08x' % dmabuf_mem_size)



# IMX219 I2C control

imx219 = jellypy.Imx219ControlI2c()
if not imx219.open('/dev/i2c-0', 0x10):
    print('I2C open error')
    sys.exit(1)
    
imx219.reset()

print('Model ID : %04x' % imx219.get_model_id())


pixel_clock = 91000000 # 139200000.0
binning     = True
width       = 640  #640
height      = 480  #132
aoi_x       = -1
aoi_y       = -1
flip_h      = False
flip_v      = False
frame_rate  = 60 # 1000
exposure    = 10
a_gain      = 20
d_gain      = 10
bayer_phase = 1
view_scale  = 1

# camera setting
imx219.set_pixel_clock(pixel_clock)
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
#reg_demos.write_reg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase)
#reg_demos.write_reg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3)  #update & enable

#capture_still_image(reg_wdma, reg_fmtr, dmabuf_mem_addr, width, height, 1)
#img = udmabuf.get_array_uint8((height, width, 4), 0)
#plt.imshow(img[:,:,::-1])
#plt.show()

while cv2.waitKey(10) != 0x1b:
    # cpture
    capture_still_image(reg_wdma, reg_fmtr, dmabuf_mem_addr, width, height, 1)
    #cv::Mat img(height*frame_num, width, CV_8UC4)
    #udmabuf_acc.MemCopyTo(img.data, 0, width * height * 4 * frame_num)
    img = udmabuf.get_array_uint8((height, width, 4), 0)

    #img_rgb = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
    #plt.figure(figsize=(12, 8))
    #plt.imshow(img_rgb[:,:,::-1])
    #plt.show()

    cv2.imshow('"img', img)

