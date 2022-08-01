import sys
import numpy as np
import cv2
import matplotlib.pyplot as plt
import rgb2hsv

# source image
src_img, _ = np.meshgrid(range(256), range(128))
src_img = cv2.applyColorMap(src_img.astype(np.uint8), cv2.COLORMAP_HSV)
# src_img = cv2.imread("../Mandrill.bmp", 0)
src_img = src_img.astype(np.uint16) * 0x101 // 64

# simulation
sim = rgb2hsv.Rgb2Hsv(src_img.shape[1], src_img.shape[0])
sim.write_image(src_img[:,:,::-1])
dst_img = sim.read_image()

# show output
plt.subplot(411)
plt.title('src')
plt.imshow(src_img[:,:,::-1]//4, 'gray')
plt.subplot(412)
plt.title('dst_h')
plt.imshow(dst_img[:,:,0], 'gray')
plt.subplot(413)
plt.title('dst_s')
plt.imshow(dst_img[:,:,1], 'gray')
plt.subplot(414)
plt.title('dst_v')
plt.imshow(dst_img[:,:,2], 'gray')
plt.tight_layout()
plt.show()
