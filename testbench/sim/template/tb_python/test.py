import sys
import numpy as np
import cv2
import matplotlib.pyplot as plt
import video_test

w = 128
h = 64

# create sim
sim = video_test.Axi4VideoTest(w, h)

sim.write_reg(0, 1, 0xf)
sim.write_reg(1, 2, 0xf)
sim.wait_bus()

src_img = np.ndarray((h, w), dtype=np.uint8)
for y in range(src_img.shape[0]):
    for x in range(src_img.shape[1]):
        src_img[y, x] = y + x

sim.write_image(src_img)
dst_img = sim.read_image()


plt.subplot(211)
plt.title('input')
plt.imshow(src_img, 'gray')
plt.subplot(212)
plt.title('output')
plt.imshow(dst_img, 'gray')
plt.tight_layout()
plt.show()
