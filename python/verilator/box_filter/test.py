import sys
import numpy as np
import cv2
import matplotlib.pyplot as plt
import box_filter

REG_CORE_ID        = 0x00
REG_CORE_VERSION   = 0x01
REG_CTL_CONTROL    = 0x04
REG_CTL_STATUS     = 0x05
REG_CTL_INDEX      = 0x07
REG_PARAM_MIN      = 0x08
REG_PARAM_MAX      = 0x09
REG_PARAM_COEFF    = 0x10


# source image
#src_img = np.zeros((128, 256, 3), dtype=np.uint8)
#src_img[32:64,64:128,0] = 127
src_img = cv2.imread("../Mandrill.bmp")

# simulation
sim = box_filter.BoxFilter(src_img.shape[1], src_img.shape[0])

for c in range(3):
    for i in range(3):
        for j in range(3):
            sim.write_reg(REG_PARAM_COEFF + (c*3+i)*3+j, 0x20, 0xf);
sim.write_reg(REG_CTL_CONTROL, 0x3, 0xf);
sim.wait_bus()

sim.write_image(src_img)

sim.run(1000000)
print(src_img.shape[1]*src_img.shape[0])
print(sim.read_que_size())

dst_img = sim.read_image()

# show output
plt.subplot(211)
plt.title('src')
plt.imshow(src_img[:,:,::-1])
plt.subplot(212)
plt.title('dst')
plt.imshow(dst_img[:,:,::-1])
plt.tight_layout()
plt.show()
