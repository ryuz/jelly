import sys
import numpy as np
import cv2
import matplotlib.pyplot as plt

sys.path.append('build')
import demosaic_acpi

#src_rgb   = cv2.imread("Mandrill.bmp").astype(np.uint16)*4  # 8bit -> 10bit
#src_bayer = np.ndarray((src_rgb.shape[0]*2, src_rgb.shape[1]*2, 1), dtype=np.uint16)
#src_bayer[0::2,0::2, 0] = src_rgb[:,:,2]
#src_bayer[0::2,1::2, 0] = src_rgb[:,:,1]
#src_bayer[1::2,0::2, 0] = src_rgb[:,:,1]
#src_bayer[1::2,1::2, 0] = src_rgb[:,:,0]

# src_bayer = cv2.imread("../dump_raw10.png", cv2.IMREAD_UNCHANGED)
# src_bayer = cv2.imread("../../../data/images/windowswallpaper/Chrysanthemum_320x240_bayer10.pgm", cv2.IMREAD_UNCHANGED)
src_bayer = cv2.imread("../../../data/images/windowswallpaper/Penguins_640x480_bayer10.pgm", cv2.IMREAD_UNCHANGED)

sim = demosaic_acpi.DemosaicAcpi(src_bayer.shape[1], src_bayer.shape[0])
sim.write_reg(8, 0, 0xf)
sim.write_reg(4, 3, 0xf)
sim.wait_bus()

sim.write_image(src_bayer)
dst_img = sim.read_image()

print(dst_img.shape)
print(np.max(dst_img))

plt.subplot(211)
plt.imshow(src_bayer, 'gray')
plt.subplot(212)
plt.imshow(dst_img//4) # 10bit -> 8bit
plt.show()
