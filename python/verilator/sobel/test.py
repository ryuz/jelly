import sys
import numpy as np
import cv2
import matplotlib.pyplot as plt
import sobel

# source image
src_img = np.zeros((128, 256, 1), dtype=np.uint8)
src_img[32:64,64:128,0] = 127
# img = cv2.imread("../Mandrill.bmp", 0)

# simulation
sim = sobel.Sobel(src_img.shape[1], src_img.shape[0])
sim.write_image(src_img)
dst_img = sim.read_image()

# show output
plt.subplot(311)
plt.title('src')
plt.imshow(src_img, 'gray')
plt.subplot(312)
plt.title('dx')
plt.imshow(dst_img[:,:,0])
plt.subplot(313)
plt.title('dy')
plt.imshow(dst_img[:,:,1])
plt.tight_layout()
plt.show()
