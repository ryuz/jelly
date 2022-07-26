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
            if i==1 and j==1:
                sim.write_reg(REG_PARAM_COEFF + (c*3+i)*3+j, 0x100, 0xf)
            else:
                sim.write_reg(REG_PARAM_COEFF + (c*3+i)*3+j, 0x000, 0xf)

sim.write_reg(REG_CTL_CONTROL, 0x3, 0xf);
sim.wait_bus()
sim.write_image(src_img)
dst_img1 = sim.read_image()


for c in range(3):
    for i in range(3):
        for j in range(3):
            if i==1 and j==1:
                sim.write_reg(REG_PARAM_COEFF + (c*3+i)*3+j, 0x020, 0xf)
            else:
                sim.write_reg(REG_PARAM_COEFF + (c*3+i)*3+j, 0x01c, 0xf)
sim.write_reg(REG_CTL_CONTROL, 0x3, 0xf);
sim.wait_bus()
sim.write_image(src_img)
dst_img2 = sim.read_image()


for c in range(3):
    for i in range(3):
        for j in range(3):
            if i==1 and j==1:
                sim.write_ireg(REG_PARAM_COEFF + (c*3+i)*3+j, -0x800, 0xf)
            else:
                sim.write_ireg(REG_PARAM_COEFF + (c*3+i)*3+j, 0x100, 0xf)
sim.write_reg(REG_CTL_CONTROL, 0x3, 0xf);
sim.wait_bus()
sim.write_image(src_img)
dst_img3 = sim.read_image()


#print(dst_img.dtype)

# show output
plt.figure(figsize=(6, 6))
plt.subplot(221)
plt.title('src')
plt.imshow(src_img[:,:,::-1])
plt.subplot(222)
plt.title('dst1(bypass)')
plt.imshow(dst_img1[:,:,::-1])
plt.subplot(223)
plt.title('dst2(gauss)')
plt.imshow(dst_img2[:,:,::-1])
plt.subplot(224)
plt.title('dst3(Laplacian)')
plt.imshow(dst_img3[:,:,::-1])
plt.tight_layout()
plt.show()
