import sys
import numpy as np
import cv2
import matplotlib.pyplot as plt
import filter2d

REG_CORE_ID        = 0x00
REG_CORE_VERSION   = 0x01
REG_CTL_CONTROL    = 0x04
REG_CTL_STATUS     = 0x05
REG_CTL_INDEX      = 0x07
REG_PARAM_MIN      = 0x08
REG_PARAM_MAX      = 0x09
REG_PARAM_COEFF    = 0x10


def run_filter2d(sim, img, kernel):
    sim.set_image_size(img.shape[1], img.shape[0])
    for c in range(3):
        for i in range(3):
            for j in range(3):
                sim.write_ireg(REG_PARAM_COEFF + (c*3+i)*3+j, int(kernel[c][i][j] * 0x10000), 0xf)
    sim.write_reg(REG_CTL_CONTROL, 0x3, 0xf);
    sim.wait_bus()
    sim.write_image(img)
    return sim.read_image()


kernel_bypss = [
    [
        [0, 0, 0],
        [0, 1, 0],
        [0, 0, 0],
    ],
    [
        [0, 0, 0],
        [0, 1, 0],
        [0, 0, 0],
    ],
    [
        [0, 0, 0],
        [0, 1, 0],
        [0, 0, 0],
    ],
]

kernel_gauss = [
    [
        [0.1, 0.1, 0.1],
        [0.1, 0.2, 0.1],
        [0.1, 0.1, 0.1],
    ],
    [
        [0.1, 0.1, 0.1],
        [0.1, 0.2, 0.1],
        [0.1, 0.1, 0.1],
    ],
    [
        [0.1, 0.1, 0.1],
        [0.1, 0.2, 0.1],
        [0.1, 0.1, 0.1],
    ],
]

kernel_laplacian = [
    [
        [0,  1,  0],
        [1, -4,  1],
        [0,  1,  0],
    ],
    [
        [0,  1,  0],
        [1, -4,  1],
        [0,  1,  0],
    ],
    [
        [0,  1,  0],
        [1, -4,  1],
        [0,  1,  0],
    ],
]

# create sim
sim = filter2d.Filter2d(0, 0)

# source image
src_img = cv2.imread("../Mandrill.bmp")

# filter
dst_img1 = run_filter2d(sim, src_img, kernel_bypss)
dst_img2 = run_filter2d(sim, src_img, kernel_gauss)
dst_img3 = run_filter2d(sim, src_img, kernel_laplacian)


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
