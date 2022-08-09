
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import numpy as np
import cv2

src_file = "color/Mandrill.bmp"
dst_path = "Mandrill_128x128_rotation"
size     = (128, 128)
center   = (63, 63)


def write_img(fname, img, type="P3"):
    with open(fname, "w") as f:
        f.write("{}\n".format(type))
        f.write("{} {}\n".format(img.shape[1], img.shape[0]))
        f.write("255\n")
        for v in img.flatten():
            f.write("{}\n".format(v))


src_img = cv2.imread("color/Mandrill.bmp")
src_img = cv2.resize(src_img, size)

os.makedirs(dst_path, exist_ok=True)
for i in range(10):
    trans = cv2.getRotationMatrix2D((64, 64), i*10, 1)
    dst_img = cv2.warpAffine(src_img, trans, size)
    fname = os.path.join(dst_path, "img_{:04d}.ppm".format(i))
    write_img(fname, dst_img[:,:,::-1])
